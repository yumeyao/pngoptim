#PNGOptim
PNGOptim is a CMD Batch file([Why]()?) for optimizing PNG files, aiming at good quality(small size) with less effort.

It's inspired by similar projects such as [ImageOptim](http://imageoptim.com), [Trimage](http://trimage.org/), etc..
However, PNGOptim only uses [PNGOut](http://advsys.net/ken/utils.htm) and [Zopflipng](https://code.google.com/p/zopfli/)([Why](https://github.com/yumeyao/pngoptim/wiki/How-is-an-image-compressed-into-a-png%3F-How-to-choose-among-the-available-programs%3F)?), and is generally faster because it's SMART not BRUTE.

###FEATURE
Multi-CPU ready
Smart approach(not brute)
Multi-Files at one time
Safe for multiple instances

###Usage
1. Download the [batch file](https://raw.github.com/yumeyao/pngoptim/master/pngoptim.cmd)(you can right-click and choose save).
2. Ensure you have a copy of [PNGOut](http://advsys.net/ken/utils.htm), [Zopflipng](https://code.google.com/p/zopfli/) and [DeflOpt](http://www.walbeehm.com/download/) and they are accessable(you can just put the exe files to the same directory as the batch file)<br>
_As a respect of the authors, I DON'T contain the exe files in this project_
3. Now use it to optimize PNG files. They are optimized in-place.
 * Drag'n'Drop PNGs to the batch file.
 * Use the syntax "pngoptim pngfile1 pngfile2 pngfile3 pngfile4 ...".<br>

###Limit
1. On XP Home/2000, wmic is not present, assuming 2 logical CPUs.<br>
Search for "InitParallel 2" and replace 2 in case you want to change the numbers on such OSes.
2. Unicode paths that is not valid in current code page fails.
3. As the sychronization is file-based. There is an astronomically small chance the synchronation goes broken if you run multiple instances at the same time.<br>
However it's not recommended to run multiple instances and it's not needed, you doesn't benefit from doing so.

###TODO
1. The output is sometimes not optimal when the output is in patterned colorspace.<br>
This is because zopflipng don't change the color pattern <br>
It seems PNGOut uses a random pattern layout so it might make sense to do multiple tries in the first pass
2. Even if the output is not in patterned colorspace, the output is not smallest all the time(compared to brute).<br>
Because this script uses zopfli -q --filters=01234mepb as 1st pass to select best filter, and only use zopfli --filters=p in 2nd pass(that's why this script is faster).<br>
We should use --filters=xxxxx where xxxxx is all possible good filters.
3. Even we use --filters=01234mepb --iterations=500, there is a tiny chance the output is not smallest(compared to brute).<br>
Probably due to zopfli doesn't out-perform zlib all the time????
4. allow for specifying --iterations for zopflipng.