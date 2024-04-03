rem Graphics
cd gfx
superfamiconv -M gb -RF -i title1.png -t title.tiles
superfamiconv -M gb -RF -i title1.png -m title.map
superfamiconv tiles -M gb -R -i cloud.png -d cloud.bin
superfamiconv tiles -M gb -R -i sprites.png -d sprites.bin
superfamiconv tiles -M gb -R -i tiles.png -d tiles.bin
superfamiconv -M gb -RF -i font.png -t font.bin
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
