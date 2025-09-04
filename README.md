> # Status (2025): Obsolete
> **Historical reference only.** Use **[ECT](https://github.com/fhanau/Efficient-Compression-Tool)** for a one-shot ultimate solution.
>
> **Why obsolete?** PNGOptim orchestrates PNGOUT/Zopfli in heuristic passes; **ECT** uses Zopfli with the **BT match finder from 7-Zip's Deflate**, effectively closing the gap where Zopfli underperformed.
>
> However PNGOptim can still possibly speed up the process by only selecting proper zopfli `--filters` but that's usually not a great advance given our PCs are much faster than before.
>
> **References**
> - Rationale and internals: **[DEFLATE.md](https://github.com/yumeyao/7zDeflate/blob/master/DEFLATE.md)**  
> - Quick comparison of ECT: https://github.com/yumeyao/7zDeflate
> - Legacy notes still valid for background: **[project WIKIs](https://github.com/yumeyao/pngoptim/wiki)**
>
> **Note on `CgBIHelper`** (previously undocumented): Converts between standard PNGs and iOS **CgBI** PNGs. CgBI adds a private `CgBI` chunk, stores **raw DEFLATE** in `IDAT` (no zlib wrapper), and uses **BGRA** + **premultiplied alpha**. To **optimize**, **re-wrap IDAT in zlib** and leave pixels unchanged to get a valid (if visually wrong) PNG that standard tools can recompress.

# PNGOptim
PNGOptim is a CMD Batch file ([Why?](https://github.com/yumeyao/pngoptim/wiki/Why-using-CMD-Batch%3F)) for optimizing PNG files, aiming at good quality(small file size) with less effort(less tries hence runs faster).

It's **inspired** by similar projects such as [ImageOptim](http://imageoptim.com), [Trimage](http://trimage.org/), etc..
However, PNGOptim doesn't follow all other projects' brute way, instead it only uses [PNGOut](http://advsys.net/ken/utils.htm) and [Zopflipng](https://code.google.com/p/zopfli/) ([Why?](https://github.com/yumeyao/pngoptim/wiki/How-is-an-image-compressed-into-a-png%3F-How-to-choose-among-the-available-programs%3F)) in a smart way.

PNGOptim runs generally faster and the output is generally smaller because it's SMART not BRUTE.

### FEATURE
* Multi-CPU ready
* Smart approach(not brute)
* Multi-Files at one time
* Safe for multiple instances

### Usage
1. Download the [batch file](https://raw.github.com/yumeyao/pngoptim/master/pngoptim.cmd) (you can right-click and choose save).
1. Ensure you have a copy of [PNGOut](http://advsys.net/ken/utils.htm), [Zopflipng](https://raw.github.com/yumeyao/pngoptim/master/zopflipng.exe) and [DeflOpt](http://web.archive.org/web/20140117044314/http://www.walbeehm.com/download/) and they are accessable(you can just put the exe files to the same directory as the batch file)<br>
_As a respect of the authors, I DON'T contain the exe files in this project_
1. Now use it to optimize PNG files. They are optimized in-place.
 * Drag'n'Drop PNGs to the batch file or d'n'd folders.
 * Use the syntax "pngoptim pngfile1 pngfile2 pngfile3 pngfile4 ...".
 * Just run the command to see more syntax.

### Limit
1. On XP Home/2000, wmic is not present, assuming 2 logical CPUs.
   * Search for "InitParallel 2" and replace 2 in case you want to change the numbers on such OSes.
1. Unicode paths that is not valid in current code page fails.
1. As the sychronization is file-based. There is an astronomically small chance the synchronation goes broken if you run multiple instances at the same time.<br>
However it's not recommended to run multiple instances and it's not needed, you doesn't benefit from doing so.

### TODO
1. log in verbose mode.
