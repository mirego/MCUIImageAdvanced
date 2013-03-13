# ShrinkPng

Shrinks an image to 50% by averaging the color (and alpha) of each 2x2 pixel block.

You use this to shrink Retina images (@2x) down to the lower resolution. The assumption here is that the source image is drawn on a 2x2 grid and that all line widths and so on are multiples of 2.

The output looks similar to bicubic scaling, but slightly sharper.

See also: http://www.hollance.com/2011/04/drawing-retina-graphics/

## Known Bugs:

If the image contains a color profile (as images saved from Gimp tend to) then the converted pixel values will be a little off. I have not found a way yet to load PNGs without the color profile, but you can strip these headers using pngcrush before running ShrinkPng:

    pngcrush -rem gAMA -rem cHRM -rem iCCP -rem sRGB in@2x.png out@2x.png
