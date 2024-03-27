rem Graphics
cd gfx
superfamiconv -B 2 -i cloud.png -t cloud.bin
superfamiconv -B 2 -i sprites.png -t sprites.bin
superfamiconv -B 2 -i tiles.png -t tiles.bin -R
superfamiconv -B 2 -i font.png -t font.bin -R
cd ..

rem Source
cd src
wla-gb main.s
wla-gb game.s
wla-gb graphics.s
wla-gb interrupts.s
wla-gb level.s
wla-gb music.s
wla-gb songs.s
wla-gb strings.s
wla-gb title.s
wlalink -S ..\linkfile rappel.gb
move rappel.gb ..
move rappel.sym ..
