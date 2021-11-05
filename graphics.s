;==============================================================================
; Graphics
;==============================================================================

.INCLUDE "gb_hardware.i"
.INCLUDE "header.i"

.DEFINE OAMBuffer   $C100

.SECTION "GraphicsCode" FREE

DMARoutineOriginal:
    ld a, >OAMBuffer
    ldh (R_DMA), a
    ld a, $28			; 5x40 cycles, approx. 200ms
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
    ret				; just in case

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
    ld de, $9800
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

FillMap:
    ; fills tilemap with the empty tile for gameplay
    ld b, $20			; height of full tile map
    ld hl, $9800
    ld de, $000C		; added to hl to go to next line later on
    jr +			; skip some stuff for new set of tiles
--  add hl, de
+   ; first row
    ld c, $14			; width of 1 screen in tiles
-   ld a, $09
    ldi (hl), a
    inc a
    ldi (hl), a
    dec c
    dec c
    jr nz, -
    dec b
    ;ret z
    ; second row
    add hl, de			; go to next screen
    ld c, $14
-   ld a, $0B
    ldi (hl), a
    inc a
    ldi (hl), a
    dec c
    dec c
    jr nz, -
    ; repeat . . .
    dec b
    jr nz, --
    ret

ObjInit:
    ; zeros out an object x and y (hiding it) and sets it's tile id
    ; a	    obj index num
    ; b	    tile id
    ld c, 4			; 4 tiles
    ld hl, OAM.1
    sla a
    sla a
    sla a
    sla a
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a			; hl is the tile address
-   xor a
    ldi (hl), a
    ldi (hl), a
    ld a, b
    ldi (hl), a
    xor a
    ldi (hl), a
    inc b
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
    ld h, a			    ; hl is now the address of the tile
    
    ld a, 8			    ; handle gameboy's sprite offsets
    add b
    ld b, a
    ld a, 16
    add c
    ld c, a

    ld a, c
    ldi (hl), a			    ; top right tile, y
    ld a, b
    ldi (hl), a			    ; top right tile x
    ld a, c
    inc hl
    inc hl
    ldi (hl), a			    ; top left tile y
    ld a, 8
    add a, b
    ldi (hl), a			    ; top left tile x
    inc hl
    inc hl
    ld a, 8
    add a, c
    ldi (hl), a			    ; bottom right tile y
    ld a, b
    ldi (hl), a			    ; bottom right tile x
    inc hl
    inc hl
    ld a, 8
    add a, c
    ldi (hl), a			    ; bottom left tile y
    ld a, 8
    add a, b
    ldi (hl), a			    ; bottom right tile x
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
    ld h, a			    ; hl is now the address of the tile
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



PlaceCliff:
    ; places a cliff at a random x in the upcoming row of tiles
    ;
    ; get random tile spot
    call RandByte
    and $0F	    		    ; 10 tiles available so limit it to 0-9
    cp 10
    jr c, +
    sub 9
+   sla a
    ld b, a

    ; find tile address
    ldh a, (R_SCY)
    add 16+144			    ; find bottom of screen + a row
    and $F0			    ; a / 16
    swap a
    ld de, $9800		    ; base address for tiles
    cp 0
    jr z, +
    ld c, a
-   ld a, $40			    ; bytes to next row
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    dec c
    jr nz, -
+
    ld a, b			    ; add in random offset
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    ; place top left tile
    ld a, $0D
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
    sub $10			    ; should do the row above the current toprow
    and $F0			    ; a / 16
    swap a			    ; a/16
    ld hl, $9800		    ; base address for tilemap
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
    ld a, $0C			    ; move hl to next line
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
    ; a	    x
    ; b	    y
    ; Returns:
    ; hl    tile address

    ; figure out tile x and y
    srl a			    ; figure out x tile ordinate
    srl a
    srl a
    ld d, a
    ldh a, (R_SCY)		    ; figure out y tile ordinate
    add b
    srl a
    srl a
    srl a
    and $1F			    ; can only be tile 0-31
    
    ; find address
    ld hl, $9800		    ; base address of map
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
    ld a, d			    ; lets add the x offset now
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    ret


FindMapBuffTile:
    ; Finds the map tile at a given x and y
    ; a	    x
    ; b	    y
    ; Returns:
    ; hl    tile address

    ; figure out tile x and y
    srl a			    ; figure out x tile ordinate
    srl a
    srl a
    ld d, a
    ldh a, (R_SCY)		    ; figure out y tile ordinate
    add b
    srl a
    srl a
    srl a
    and $1F			    ;	can only be tile 0-31
    ld e, a

    ; find address
    ld a, (currentmap)
    ld l, a
    ld a, (currentmap+1)
    ld h, a
    ld a, e
    ld c, a
    cp $00
    jr z, +
-   ld a, l
    add $14
    ld l, a
    ld a, 0
    adc h
    ld h, a
    dec c
    jr nz, -
+
    ld a, d			    ; add the x offset now
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    ret


.ENDS


.SECTION "Tiles" FREE

Tiles:
.DB $00,$00,$00,$00,$00,$00,$00,$00
.DB $00,$00,$00,$00,$00,$00,$00,$00

; player sprites
.DEFINE tiles_sprites_size  17 * 16
.EXPORT tiles_sprites_size
.DB $07,$07,$08,$0F,$0B,$0C,$0E,$0F,$1A,$1D,$27,$3C,$2B,$3E,$33,$3E
.DB $00,$00,$80,$80,$80,$80,$00,$00,$80,$80,$C0,$40,$E0,$60,$B0,$70
.DB $27,$3E,$18,$1F,$1F,$2F,$1F,$2E,$17,$14,$04,$07,$04,$07,$03,$03
.DB $F0,$F0,$40,$F0,$F0,$38,$F0,$88,$F8,$C8,$C8,$F8,$C8,$F8,$B8,$B8
.DB $00,$00,$00,$00,$00,$00,$00,$00,$0E,$0F,$1F,$14,$3F,$28,$50,$7F
.DB $00,$00,$00,$00,$00,$00,$00,$00,$30,$F0,$D8,$28,$EC,$14,$06,$FE
.DB $2F,$34,$17,$1A,$0B,$0E,$05,$07,$03,$03,$00,$01,$00,$00,$00,$00
.DB $F4,$2C,$E8,$58,$D0,$70,$A0,$E0,$C0,$C0,$80,$80,$00,$00,$00,$00
.DB $80,$00,$82,$00,$08,$00,$00,$00,$00,$00,$00,$00,$22,$00,$02,$00
.DB $20,$00,$20,$00,$60,$00,$21,$00,$20,$00,$24,$00,$10,$00,$10,$00
.DB $81,$00,$91,$00,$80,$00,$80,$00,$12,$00,$42,$00,$C0,$00,$80,$00
.DB $04,$00,$00,$00,$01,$00,$20,$00,$00,$00,$10,$00,$00,$00,$00,$00
.DB $CC,$08,$98,$18,$38,$20,$5F,$60,$C7,$F8,$FE,$FF,$65,$7F,$30,$3F
.DB $08,$08,$04,$00,$0C,$04,$2E,$06,$DA,$06,$76,$8E,$FC,$FC,$38,$F8
.DB $1F,$38,$0F,$1E,$4A,$0D,$43,$04,$47,$04,$47,$04,$E1,$00,$31,$00
.DB $48,$B8,$E8,$18,$E0,$90,$B0,$50,$F1,$10,$C1,$00,$43,$00,$27,$00

; font
.DEFINE tiles_font_size	    37 * 16
.EXPORT tiles_font_size
tiles_font:
.DB $00,$00,$18,$18,$3C,$3C,$66,$66,$7E,$7E,$66,$66,$66,$66,$00,$00
.DB $00,$00,$7C,$7C,$66,$66,$7C,$7C,$66,$66,$66,$66,$7C,$7C,$00,$00
.DB $00,$00,$3C,$3C,$66,$66,$60,$60,$60,$60,$66,$66,$3C,$3C,$00,$00
.DB $00,$00,$7C,$7C,$66,$66,$66,$66,$66,$66,$66,$66,$7C,$7C,$00,$00
.DB $00,$00,$7C,$7C,$60,$60,$78,$78,$60,$60,$60,$60,$7C,$7C,$00,$00
.DB $00,$00,$7C,$7C,$60,$60,$78,$78,$60,$60,$60,$60,$60,$60,$00,$00
.DB $00,$00,$3C,$3C,$66,$66,$60,$60,$6E,$6E,$66,$66,$3C,$3C,$00,$00
.DB $00,$00,$66,$66,$66,$66,$7E,$7E,$66,$66,$66,$66,$66,$66,$00,$00
.DB $00,$00,$3C,$3C,$18,$18,$18,$18,$18,$18,$18,$18,$3C,$3C,$00,$00
.DB $00,$00,$06,$06,$06,$06,$06,$06,$06,$06,$66,$66,$3C,$3C,$00,$00
.DB $00,$00,$66,$66,$66,$66,$6C,$6C,$78,$78,$6C,$6C,$66,$66,$00,$00
.DB $00,$00,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$7E,$7E,$00,$00
.DB $00,$00,$63,$63,$77,$77,$7F,$7F,$6B,$6B,$63,$63,$63,$63,$00,$00
.DB $00,$00,$66,$66,$76,$76,$7E,$7E,$6E,$6E,$66,$66,$66,$66,$00,$00
.DB $00,$00,$3C,$3C,$66,$66,$66,$66,$66,$66,$66,$66,$3C,$3C,$00,$00
.DB $00,$00,$7C,$7C,$66,$66,$66,$66,$7C,$7C,$60,$60,$60,$60,$00,$00
.DB $00,$00,$3C,$3C,$66,$66,$66,$66,$6E,$6E,$6E,$6E,$3E,$3E,$00,$00
.DB $00,$00,$7C,$7C,$66,$66,$66,$66,$7C,$7C,$66,$66,$66,$66,$00,$00
.DB $00,$00,$3E,$3E,$60,$60,$78,$78,$1E,$1E,$06,$06,$7C,$7C,$00,$00
.DB $00,$00,$7E,$7E,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$00,$00
.DB $00,$00,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$3C,$3C,$00,$00
.DB $00,$00,$66,$66,$66,$66,$66,$66,$66,$66,$3C,$3C,$18,$18,$00,$00
.DB $00,$00,$63,$63,$63,$63,$6B,$6B,$6B,$6B,$3E,$3E,$36,$36,$00,$00
.DB $00,$00,$66,$66,$3C,$3C,$18,$18,$18,$18,$3C,$3C,$66,$66,$00,$00
.DB $00,$00,$66,$66,$66,$66,$3C,$3C,$18,$18,$18,$18,$18,$18,$00,$00
.DB $00,$00,$7E,$7E,$0E,$0E,$1C,$1C,$38,$38,$70,$70,$7E,$7E,$00,$00
.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.DB $00,$00,$3C,$3C,$66,$66,$76,$76,$6E,$6E,$66,$66,$3C,$3C,$00,$00
.DB $00,$00,$18,$18,$38,$38,$18,$18,$18,$18,$18,$18,$3C,$3C,$00,$00
.DB $00,$00,$3C,$3C,$66,$66,$0E,$0E,$1C,$1C,$38,$38,$7E,$7E,$00,$00
.DB $00,$00,$3C,$3C,$66,$66,$1E,$1E,$06,$06,$66,$66,$3C,$3C,$00,$00
.DB $00,$00,$1C,$1C,$3C,$3C,$6C,$6C,$7C,$7C,$0C,$0C,$0C,$0C,$00,$00
.DB $00,$00,$7E,$7E,$60,$60,$7C,$7C,$06,$06,$66,$66,$3C,$3C,$00,$00
.DB $00,$00,$3C,$3C,$60,$60,$7C,$7C,$66,$66,$66,$66,$3C,$3C,$00,$00
.DB $00,$00,$7E,$7E,$06,$06,$0C,$0C,$18,$18,$30,$30,$30,$30,$00,$00
.DB $00,$00,$3C,$3C,$66,$66,$3C,$3C,$66,$66,$66,$66,$3C,$3C,$00,$00
.DB $00,$00,$3C,$3C,$66,$66,$66,$66,$3E,$3E,$06,$06,$3C,$3C,$00,$00

.INCLUDE "title.i"

.ENDS

; vim: filetype=wla
