cd src
wla-gb main.s
wla-gb game.s
wla-gb graphics.s
wla-gb interrupts.s
wla-gb level.s
wla-gb music.s
wla-gb strings.s
wlalink -S ..\linkfile rappel.gb
move rappel.gb ..
move rappel.sym ..
pause
