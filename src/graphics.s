;==============================================================================
; Graphics
;==============================================================================

.INCLUDE "gb_hardware.i"
.INCLUDE "header.i"

.DEFINE OAMBuffer   _WRAM


.RAMSECTION "GraphicsVars" BANK 0 SLOT 3
    PlayerFrame:            db
    PlayerFrameCounter:     db
.ENDS


.SECTION "GraphicsCode" FREE

DMARoutineOriginal:
    ld a, >OAMBuffer
    ldh (R_DMA), a
    ld a, $28       ; 5x40 cycles, approx. 200ms
-   dec a
    jr nz, -
    ret

PrintStr:
    ; Prints $00 terminated string to VRAM tilemap
    ; hl    source of string
    ; de    destination address
-   ldi a, (hl)
    cp 0
    ret z
    ld (de), a
    inc de
    jr -
    ret     ; just in case

.DEFINE numberOffset	    $6B
PrintInt:
    ; Prints 1 byte to VRAM tilemap three digits/tiles
    ; a	    number
    ; de    destination
    ld b, a
    daa
    and $F0
    swap a
    add numberOffset
    ld (de), a
    inc de
    ld a, b
    and $0F
    add numberOffset
    ld (de), a
    ret

LoadScreen:
    ; hl    map source
    ld de, _MAP0
    ld c, $12
--  ld b, $14
-   ldi a, (hl)
    ld (de), a
    inc de
    dec b
    jr nz, -
    ld a, 12
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    dec c
    jr nz, --
    ret

LoadPicture:
    ; loads picture into vram that is b by c
    ; b     width of picture
    ; c     height of picture
    ; hl    map source
    ; de    destination in VRAM

    ld a, b         ; store b for later
    ld (ldpicw), a
--  ld a, (ldpicw)
    ld b, a
-   ldi a, (hl)
    ld (de), a
    inc de
    dec b
    jr nz, -
    ld a, (ldpicw)  ; add (32-b) to destination for next line
    cpl
    inc a
    add 32
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    dec c
    jr nz, --
    ret

; tiles for empty space
.DEFINE EMPTY_TL    $10
.DEFINE EMPTY_TR    $11
.DEFINE EMPTY_BL    $12
.DEFINE EMPTY_BR    $13
InitMapBuffer:
    ; fills mapbuffer (WRAM) with empty tiles graphics
    ld c, 255
    ld hl, mapbuffer
--  ld b, 20
-   ld a, EMPTY_TL
    ldi (hl), a
    dec b
    ld a, EMPTY_TR
    ldi (hl), a
    dec b
    jr nz, -
    dec c
    ;ret z
    ld b, 20
-   ld a, EMPTY_BL
    ldi (hl), a
    dec b
    ld a, EMPTY_BR
    ldi (hl), a
    dec b
    jr nz, -
    dec c
    ld a, $FF
    cp c
    jr nz, --
    ret

ObjInit:
    ; zeros out an object x and y (hiding it) and sets it's tile id
    ; a     obj index num
    ; de    tile map
    ld c, 4         ; 4 tiles
    ld hl, OAM.1
    sla a
    sla a
    sla a
    sla a
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a         ; hl is OAM entry tile addr
-   xor a
    ldi (hl), a
    ldi (hl), a
    ld a, (de)      ; retrieve tile
    inc de
    ldi (hl), a
    xor a
    ldi (hl), a
    dec c
    jr nz, -
    ret

ObjMove:
    ; moves an object to a new position
    ; a	    obj index (0 - 9)
    ; b	    new x
    ; c	    new y
    ld hl, OAM.1.y
    sla a
    sla a
    sla a
    sla a
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a             ; hl is now the address of the tile

    ld a, 8             ; handle gameboy's sprite offsets
    add b
    ld b, a
    ld a, 16
    add c
    ld c, a

    ld a, c
    ldi (hl), a         ; top right tile, y
    ld a, b
    ldi (hl), a         ; top right tile x
    ld a, c
    inc hl
    inc hl
    ldi (hl), a         ; top left tile y
    ld a, 8
    add a, b
    ldi (hl), a         ; top left tile x
    inc hl
    inc hl
    ld a, 8
    add a, c
    ldi (hl), a         ; bottom right tile y
    ld a, b
    ldi (hl), a         ; bottom right tile x
    inc hl
    inc hl
    ld a, 8
    add a, c
    ldi (hl), a         ; bottom left tile y
    ld a, 8
    add a, b
    ldi (hl), a         ; bottom right tile x
    ret

ObjTile:
    ; changes an object to a new set of tiles that are one after the other
    ; a	    obj index
    ; b	    new tile id
    ld hl, OAM.1.tile
    sla a
    sla a
    sla a
    sla a
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a             ; hl is now the address of the tile
.REPEAT 4
    ld a, b
    ld (hl), a
    inc b
    ld a, 4
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
.ENDR
    ret

ObjTileMap:
    ; Changes an object to a new set of tiles that are in a tile map
    ; a     obj index
    ; de    tilemap address
    ld hl, OAM.1.tile
    sla a
    sla a
    sla a
    sla a
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a             ; hl is now the address of the tile
.REPEAT 4
    ld a, (de)
    ld (hl), a
    inc de
    ld a, 4
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
.ENDR
    ret


PlaceCliff:
    ; places a cliff at a random x in the upcoming row of tiles
    ;
    ; get random tile spot
    call RandByte
    and $0F             ; 10 tiles available so limit it to 0-9
    cp 10
    jr c, +
    sub 9
+   sla a
    ld b, a

    ; find tile address
    ldh a, (R_SCY)
    add 16+144          ; find bottom of screen + a row
    and $F0             ; a / 16
    swap a
    ld de, _MAP0        ; base address for tiles
    cp 0
    jr z, +
    ld c, a
-   ld a, $40           ; bytes to next row
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    dec c
    jr nz, -
+
    ld a, b             ; add in random offset
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    ; place top left tile
    ld a, $14
    ld (de), a
    ; place top right tile
    inc a
    inc de
    ld (de), a
    inc a
    ld b, a
    ld a, $20-1
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    ld a, b
    ; place bottom left tile
    ld (de), a
    inc a
    inc de
    ; place bottom right tile
    ld (de), a
    ret


ClearRow:
    ; fills a single row with empty map tiles
    ldh a, (R_SCY)
    sub $10             ; should do the row above the current toprow
    and $F0             ; a / 16
    swap a              ; a/16
    ld hl, _MAP0        ; base address for tilemap
    cp 0
    jr z, +
    ld c, a
-   ld a, $40
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    dec c
    jr nz, -
+
    ; now fill row with blank tiles
    ld c, $14
-   ld a, $09
    ldi (hl), a
    dec c
    inc a
    ldi (hl), a
    dec c
    jr nz, -
    ld a, $0C           ; move hl to next line
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    ld c, $14
-   ld a, $0B
    ldi (hl), a
    dec c
    inc a
    ldi (hl), a
    dec c
    jr nz, -
    ret


FindMapTile:
    ; Finds the map tile at a given x and y in VRAM
    ; a     x
    ; b     y
    ; Returns:
    ; hl    tile address

    ; figure out tile x and y
    srl a               ; figure out x tile ordinate
    srl a
    srl a
    ld d, a
    ldh a, (R_SCY)      ; figure out y tile ordinate
    add b
    srl a
    srl a
    srl a
    and $1F             ; can only be tile 0-31

    ; find address
    ld hl, _MAP0        ; base address of map
    ld c, a
    cp $00
    jr z, +
-   ld a, l
    add $20
    ld l, a
    ld a, 0
    adc h
    ld h, a
    dec c
    jr nz, -
+
    ld a, d             ; lets add the x offset now
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    ret

MapCoords:
    ; finds map coordinates for x and y
    ; a     point x
    ; b     point y
    ; returns:
    ; a     tile x
    ; y     tile y
    srl a
    srl a
    srl a
    ld c, a
    ldh a, (R_SCY)
    add b
    srl a
    srl a
    srl a
    and $1F             ; can only be tile 0-31
    ld b, a
    ld a, c
    ret

FindMapBuffTile:
    ; Finds the map tile at a given x and y
    ; a     x
    ; b     y
    ; Returns:
    ; hl    tile address

    ; figure out tile x and y
    srl a               ; figure out x tile ordinate
    srl a
    srl a
    ld c, a
    ld a, (depth+1)     ; figure out y tile ordinate
    ld d, a
    ld a, (depth)
    add b
    ld e, a
    ld a, 0
    adc d
    ld d, a
    ld a, e
.REPT 3
    srl d
    rra
.ENDR

    ; find address by starting with mapbuffer and adding 20*yord
    ld hl, mapbuffer
    ld d, 0
    ld e, a
    sla e
    rl d
    sla e
    rl d
    add hl, de
    sla e
    rl d
    sla e
    rl d
    add hl, de

    ld b, 0             ; c already is xord
    add hl, bc          ; add x offset
    ret

PrepareMapRow:
    ; prepares a new map row (below screen) to draw in the next vblank
    ; rowdrawsrc
    ld hl, mapbuffer
    ld a, (depth+1)
    ld b, a
    ld a, (depth)
.REPT 3
    srl b
    rra
.ENDR
    add 18
    cp 0
    jr z, +             ; if first row is 0 no need to add anything
    ld c, a
-   ld a, 20            ; mapbuffer row len
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    dec c
    jr nz, -
+
    ld a, l
    ld (rowdrawsrc), a
    ld a, h
    ld (rowdrawsrc+1), a

    ; rowdrawdst
    ; find screen row needing to be changed
    ldh a, (R_SCY)
    add 19*8
    srl a
    srl a
    srl a
    ld c, a
    ld hl, _MAP0
    cp 0
    jr z, +             ; if first row is 0, no need to add anything
-   ld a, $20           ; VRAM map row len
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    dec c
    jr nz, -
+
    ld a, l
    ld (rowdrawdst), a
    ld a, h
    ld (rowdrawdst+1), a

    ret

DrawMapRow:
    ; draws the next map row below the screen
    ; runs during vblank
    ld a, (rowdrawsrc)
    ld l, a
    ld a, (rowdrawsrc+1)
    ld h, a
    ld a, (rowdrawdst)
    ld e, a
    ld a, (rowdrawdst+1)
    ld d, a
    ld bc, 20
    call MoveData

    ; hl should be good
    ld a, 12
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    ld bc, 20
    call MoveData

    ; clear source and dest addr
    xor a
    ld hl, rowdrawsrc
    ldi (hl), a
    ldi (hl), a
    ldi (hl), a
    ldi (hl), a
    ret


MoveRope:
    ; moves the rope sprites to where they should connect to the player
    ; note: point where rope is "attatched" to is (80,-40)

    ; calculate slope
    ; start with x...
    ld a, (player.x)
    cp 72               ; are we swinging to the right or left?
    jr c, +

    ; swinging to the right
    sub 72
    srl a
    srl a
    srl a
    ld d, a
    jr ++
    ; swinging to the left
+   ld d, a
    ld a, 72
    sub d
    srl a
    srl a
    srl a
    ld d, a
++

    ; ...then the y
    ld a, (player.y)
    add 40              ; pretend player y is much lower for attatched point
    srl a
    srl a
    srl a
    ld e, a

    ld b, 76+8          ; for rope start pos. & oam x pos. offset
    ld c, -40+16        ; for rope start pos. & oam y pos. offset
    ld hl, OAM.5        ; first obj for rope

    ; skip through first 4 rope rungs as we only need the lower 4
    ld a, c
    add e
    add e
    add e
    add e
    ld c, a

    ld a, (player.x)
    cp 72               ; swinging to left or right?
    jr c, +
    ld a, b             ; swinging to right
    add d
    add d
    add d
    add d
    jr ++
+   ld a, b             ; swinging to left
    sub d
    sub d
    sub d
    sub d
++
    ld b, a

    ; setup 4 rope rung objects
.REPEAT 4
    ld a, c
    ldi (hl), a         ; set y pos
    add e
    ld c, a

    ld a, (player.x)
    cp 72               ; are we swinging to the left or right?
    jr c, +

    ld a, b
    ldi (hl), a         ; set x pos, (swinging right)
    add d
    ld b, a
    jr ++

+   ld a, b
    ldi (hl), a         ; set x pos, (swinging left)
    sub d
    ld b, a

++  inc hl              ; skip tile index
    inc hl              ; skip attr flags
.ENDR

    ret


MoveRopeDX:
    ld hl, OAM.9
    ld a, $18
    ldi (hl), a

    ld a, SCREEN_W/2+8
    ld b, a
    ld a, (player.x)
    sub b
    sra a
    add SCREEN_W/2+16
    ldi (hl), a
    
    ld a, $09
    ldi (hl), a
    ret


PlayerAnimate:
    ; Animate player sprite according to velocity
    ld a, (player.velx)
    bit 7, a
    jr z, +
    cpl a
    inc a               ; 2s compliment of velx
+
    sla a
    sla a
    sla a
    ld b, a
    ld a, (PlayerFrameCounter)
    add b
    ld (PlayerFrameCounter), a
    ret nc               ; did it overflow?
    ; change the player animation frame
    ld a, (PlayerFrame)
    xor 1
    ld (PlayerFrame), a
    sla a
    sla a
    ld de, PlayerTileMap
    add e               ; de + (a*4)
    ld e, a
    ld a, 0
    adc d
    ld d, a
    ld a, 0             ; OAM meta sprite 0
    call ObjTileMap
    ret

.ENDS


; Tile Definitions
.DEFINE TILE_ROPE       $08 EXPORT
.DEFINE TILE_CLIFFTL    $14 EXPORT
.DEFINE TILE_CLIFFTR    $15 EXPORT
.DEFINE TILE_CLIFFBL    $16 EXPORT
.DEFINE TILE_CLIFFBR    $17 EXPORT


.SECTION "GraphicsTiles" FREE

SpriteTiles:
.INCBIN "../gfx/sprites.bin"

PlayerTileMap:
.DB $00, $01, $02, $03
.DB $04, $05, $06, $07

MapTiles:
.INCBIN "../gfx/tiles.bin"

FontTiles:
.INCBIN "../gfx/font.bin"


TitleTiles:
.DEFINE title_tile_count  $4C
.EXPORT title_tile_count
.INCBIN "../gfx/title.tiles"

TitleTileMap:
.DEFINE title_tile_map_width  $14
.DEFINE title_tile_map_height  $12
.INCBIN "../gfx/title.map"


CloudTiles:
.INCBIN "../gfx/cloud.bin"

CloudTileMap:
.DB $80, $81, $84, $85
.DB $82, $83, $86, $87

.ENDS

; vim: filetype=wla
