#include <assert.h>
#include <stdio.h>
#include <fstream>
#include <vector>

void PrintUsage() {
	static const char HelpText[] = ""
		"CgBIHelper\n"
		"Usage: CgBIHelper -check CgBI.png\n"
		"       CgBIHelper CgBI.png CgBIChunk.bin Temp.png\n"
		"       CgBIHelper Temp.png CgBIChunk.bin CgBI.png\n";
	fwrite(HelpText, 1, sizeof(HelpText)-1, stdout);
}

unsigned long __cdecl _byteswap_ulong(unsigned long);
#pragma intrinsic(_byteswap_ulong)

#define MKFOURCC(a,b,c,d) ((unsigned long)d<<24 | a | b<<8 | c<<16)

int scanchunks(std::vector<unsigned char> &in, int size, unsigned long &chunkCgBI) {
	int offset = 8;
	int IDATcount = 0;
	while(offset < size - 12) {
		unsigned long chunksize = _byteswap_ulong(*(unsigned long *)&in[offset]);
		unsigned long chunkname = *(unsigned long *)&in[offset+4];
		offset += chunksize + 12;
		if (chunkname == MKFOURCC('I','D','A','T'))
			IDATcount += 1;
		else if (chunkname == MKFOURCC('C','g','B','I'))
			chunkCgBI = chunksize + 12;
		else if (chunkname == MKFOURCC('I','E','N','D'))
			break;
	}
	assert(offset == size);
	return IDATcount;
}

int main(int argc, char **argv) {
	if (argc<3) {
		PrintUsage();
		return 255;
	}
	bool checkonly = !strcmp("-check", argv[1]);

	std::ifstream src(checkonly ? argv[2] : argv[1], std::ios::in|std::ios::binary|std::ios::ate);
	std::streamsize size = 0;
	if(src.seekg(0, std::ios::end).good()) size = src.tellg();
	if(src.seekg(0, std::ios::beg).good()) size -= src.tellg();

	std::vector<unsigned char> in(size);
	if (size>0)
		src.read((char *)(&in[0]), size);
	src.close();

	if(*(unsigned long *)&in[0] != MKFOURCC(137, 80, 78, 71)
	   || *(unsigned long *)&in[4] != MKFOURCC(13, 10, 26, 10))
	   return 255;

	unsigned long chunkCgBI = 0;
	int IDATcount = scanchunks(in, size, chunkCgBI);
	if(checkonly) {
		fwrite(chunkCgBI ? "CgBI" : "Std ", 1, 4, stdout);
		return 0;
	}

	std::ofstream dst(argv[3], std::ios::out|std::ios::binary|std::ios::trunc);
	dst.write("\x89PNG\x0D\x0A\x1A\x0A", 8);

	int outsize;
	if (chunkCgBI) {
		outsize = size - chunkCgBI + 6;
	} else {
		outsize = size - 6;
		std::ifstream cgbi(argv[2], std::ios::in|std::ios::binary|std::ios::ate);
		std::streamsize cgbisize = 0;
		if(cgbi.seekg(0, std::ios::end).good()) cgbisize = cgbi.tellg();
		if(cgbi.seekg(0, std::ios::beg).good()) cgbisize -= cgbi.tellg();
		if (cgbisize > 0) {
			std::vector<unsigned char> cgbibuf(cgbisize);
			cgbi.read((char *)(&cgbibuf[0]), cgbisize);
			dst.write((char *)(&cgbibuf[0]), cgbisize);
		}
		cgbi.close();
	}

	std::vector<unsigned char> out(outsize - 8);
	//*(unsigned long *)&out[0] = MKFOURCC(137, 80, 78, 71);
	//*(unsigned long *)&out[4] = MKFOURCC(13, 10, 26, 10);

	int offset = 8;
	int written = 0;
	int IDATn = 0;
	while(offset <= size - 12) {
		unsigned long chunksize = _byteswap_ulong(*(unsigned long *)&in[offset]);
		unsigned long chunkname = *(unsigned long *)&in[offset+4];
		if (chunkname == MKFOURCC('I','D','A','T')) {
			++IDATn;

			union {
				unsigned long ul;
				unsigned char uc[4];
			} newchunksize;
			newchunksize.ul = chunksize;
			if (IDATn == 1)	newchunksize.ul += chunkCgBI ? 2 : -2;
			if (IDATn == IDATcount) newchunksize.ul += chunkCgBI ? 4 : -4;
			out[written++] = newchunksize.uc[3];
			out[written++] = newchunksize.uc[2];
			out[written++] = newchunksize.uc[1];
			out[written++] = newchunksize.uc[0];
			out[written++] = 'I';
			out[written++] = 'D';
			out[written++] = 'A';
			out[written++] = 'T';
			if (IDATn == 1) {
				if (chunkCgBI) {
					out[written++] = 0x78; //zlib header
					out[written++] = 0xDA; //zlib header Best Compression
				} else offset += 2;
			}
			offset += 8;
			memcpy(&out[written], &in[offset], chunksize+4); //tricky.. zlib CRC or png chunk CRC doesn't matter here

			offset += chunksize + 4;
			written += chunksize + 4;
			if (IDATn == IDATcount) {
				if (chunkCgBI)
					written += 4;
				else
					offset += 4;
			}
		} else if (chunkname == MKFOURCC('C','g','B','I')) {
			if (chunkCgBI) {
				std::ofstream cgbi(argv[2], std::ios::out|std::ios::binary|std::ios::trunc);
				cgbi.write((char *)&in[offset], chunksize+12);
				cgbi.close();
			}
			offset += chunksize + 12;
		} else {
			memcpy(&out[written], &in[offset], chunksize+12);
			offset += chunksize + 12;
			written += chunksize + 12;
	printf("%c%c%c%c chunk written\n", ((char*)(&chunkname))[0], ((char*)(&chunkname))[1], ((char*)(&chunkname))[2], ((char*)(&chunkname))[3]);
			if (chunkname == MKFOURCC('I','E','N','D'))
				break;
		}
	}
	dst.write((char *)&out[0], written);
	dst.close();

	return 0;
}