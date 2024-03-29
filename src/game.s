;==============================================================================
; GAME ROUTINES
;==============================================================================

.INCLUDE "gb_hardware.i"
.INCLUDE "header.i"


.SECTION "Game Routines" FREE

SetupGame:
    call ScreenFadeOut
    ; turn off screen
    xor a
    ldh (R_LCDC), a

    ; halt music and load new music in
    call StopMusic
    ld hl, Song_Rapel
    call LoadMusic

    ; clear tilemaps
    ld a, $FF
    ld hl, _MAP0
    ld bc, $A33
    call BlankData
    ld a, $FF
    ld hl, _MAP1
    ld bc, $A33
    call BlankData


    ; load tiles
    ld hl, SpriteTiles
    ld de, _VRAM
    ld bc, (_sizeof_SpriteTiles+1)
    call MoveData

    ldh a, (R_DIV)      ; get a random seed from the DIV timer register
    ld (seed), a

    call InitMapBuffer
    call GenerateLevel

    ; load in visible map
    ld hl, mapbuffer
    ld de, _MAP0
    ld b, 25            ; lines to do
--  ld c, SCREEN_W/8    ; individual tiles on row
-   ldi a, (hl)
    ld (de), a
    inc de
    dec c
    jr nz, -
    ld a, $20-$14       ; offset to next row in map
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    dec b
    jr nz, --

    ; set up player
    xor a
    ld de, PlayerTileMap
    call ObjInit
    xor a
    ld b, 20
    ld c, 20
    call ObjMove

    ld a, (SCREEN_W/2)-8    ; place player in center
    ld (player.x), a
    call SetPlayerY

    ; set up rope sprites
    ld hl, OAM.5
.REPEAT 4
    ld a, 20
    ldi (hl), a
    ld a, (SCREEN_W/2)-4
    ldi (hl), a
    ld a, TILE_ROPE
    ldi (hl), a
    xor a
    ldi (hl), a
.ENDR

    call MoveRope

    xor a
    ld (player.velx), a ; blank velx
    ld hl, score        ; blank score
    ldi (hl), a
    ldi (hl), a
    ldi (hl), a         ; blank depth
    ld (hl), a


    ; setup scorebar
    ld hl, Str_Hi
    ld de, $9C01
    call PrintStr
    ld a, (highscore+1)
    ld de, $9C04
    call PrintInt
    ld a, (highscore)
    inc de
    call PrintInt
    ld hl, Str_Sc
    ld de, $9C0C
    call PrintStr


    ld a, %00000011     ; LCD STAT & VBlank interrupt
    ldh (R_IE), a
    ; setup scorebar interrupt
    ld a, %01000000     ; enable LYC=LY STAT interrupt
    ldh (R_STAT), a
    ld a, 8             ; set LYC
    ldh (R_LYC), a

    ; turn on sound
    ld a, %10000000     ; sound on
    ldh (R_NR52), a
    ld a, %01000100     ; volume
    ldh (R_NR50), a
    ld a, $FF           ; enable all channels to both L&R
    ldh (R_NR51), a

    ; turn on screen
    ld a, %10011011
    ldh (R_LCDC), a
    call ScreenFadeIn
    ret

HandleGameInput:
    ; Key Down
    ldh a, (<joypadDiff)
    ld b, a             ; store for later
    and JOY_START
    jr z, @checkright
    ; Start
    ld a, STATE_PAUSE
    ldh (<state), a
    ret                 ; no need to do anything else, game is paused
@checkright:
    ld a, b
    and JOY_RIGHT
    jr z, @checkleft
    ; Right
    ld a, (player.velx)
    add 2
    ld (player.velx), a
@checkleft:
    ld a, b
    and JOY_LEFT
    jr z, @checkdown
    ; Left
    ld a, (player.velx)
    sub 2
    ld (player.velx), a
@checkdown:
@checka:
@checkB:
    ld a, b
    and JOY_B
    jr z, @handledkeydowns
    ; B
    ld a, (player.velx)
    ld c, a
    cp 0            ; test if 0 already
    jr nz, +
    jr ++
+   bit 7, a
    jr z, +
    inc a           ; - velocities need to be increased
    jr ++
+   dec a           ; + velocities need to be decreased
++  ld (player.velx), a
@handledkeydowns:

    ; Key Held
    ldh a, (<joypadNew)
    ;ld b, a         ; store for later keypad checks
    and JOY_DOWN
    jr z, @handledkeyhelds
    ld a, (depth)
    ld b, a         ; store for later score increment check
    add 1
    ld c, a         ; store for later score increment check
    ld (depth), a
    jr nc, +
    ld a, (depth+1) ; increase high byte if carry
    inc a
    ld (depth+1), a
+
    ld a, b
    xor c           ; only increment score if bit 4 changed
    and 16
    jr z, @noincscore
    ; increment score
    ld a, (score)
    add 1
    daa
    ld (score), a
    jr nc, +
    ld a, (score+1) ; handle carry
    add 1
    daa
    ld (score+1), a
+
    call PrepareMapRow
@noincscore:

@handledkeyhelds:
    ret


ApplyVelX:
    ld a, (player.velx)
    ld b, a
    bit 7, a        ; is it negative?
    jr z, @movingright
    ; moving left
    ld a, b         ; need to negate 2's compl velx
    cpl             ; it's negative and we don't need it like that
    inc a           ; to be subtracted from the x ord.
    ld b, a
    ld a, (player.x)
    sub b
    ld (player.x), a
    jr @applyvxend
@movingright:       ; or even stationary (vel = 0)
                    ; no need to negate 2's compl. velx here
    ld a, (player.x)
    add b
    ld (player.x), a
@applyvxend:
    ret


SlowPlayerVel:
    ld a, (player.x)
    cp (SCREEN_W/2)-8
    ret z
    jr c, @lefthalf
    ; right half, left vel
    ; right half, right vel
    ld a, (player.velx)
    dec a
    ld (player.velx), a
    ret
@lefthalf:
    ; left half, right vel
    ; left half, left vel
    ld a, (player.velx)
    inc a
    ld (player.velx), a
++

    ld a, (player.velx)
    ld (player.velx), a
    ret


SetPlayerY:
    ; set player's y based off of the arc data
    ld a, (player.x)
    ; check for out of bounds values
    cp 160
    jr c,+
    xor a
+   ld b, a
    ld hl, ArcData
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    ld a, (hl)
    ld c, a
    ld (player.y), a
    xor a
    call ObjMove
    ret


CheckCollision:
    ; returns c flag where nc is collision

    ; check side of screen collision
    ld a, (player.x)
    cp SCREEN_W-16+4
    jr c, +
    cp -4
    jr nc, +
    ccf
    ret     ; collision
+
    ; TODO: fix for 256 long mapbuffer
    ;ret    ; remove this when fixing

    ; check collision with tiles
    ld a, (player.y)
    add 2
    ld b, a
    ld a, (player.x)
    add 4
    call FindMapBuffTile

    ldi a, (hl)     ; top left tile
    cp $0E
    ret nc
    ld a, (hl)      ; top right tile
    cp $0E
    ret nc
    ld a, $14-1     ; bottom left tile is $14 to new line
    add l           ; then -1 to put it back one
    ld l, a
    ld a, 0
    adc h
    ld h, a

    ; is hl greater than map end?
    ld a, >((mapbuffer)+_sizeof_mapbuffer)
    cp h
    jr nc, +
    ; a < h	means hl > map
    jr @submaplen
+   jr z, +
    ; a > h	means hl < map
    jr @nosubmaplen
+   ; a = h	means we need to check lsb
    ld a, <((mapbuffer)+_sizeof_mapbuffer)
    cp l
    jr nc, +
    ; a < l	means hl > map
    jr @submaplen
+   jr z, +
    ; a > l	means hl < map
    jr @nosubmaplen
+   ; a = l	means something is BAD
@submaplen:
    ; subtract map length
    ld a, l
    ld l, <_sizeof_mapbuffer
    sub l
    ld l, a
    ld a, h
    ld h, >_sizeof_mapbuffer
    sbc h
    ld h, a
@nosubmaplen:
    ; otherwise, continue


    ld a, (hl)      ; bottom left tile
    cp $0E
    ret nc
    inc hl
    ld a, (hl)      ; bottom right tile
    cp $0E
    ret nc

    ; check collision with objects
    ; TODO

@nocollision:
    scf
    ret


UpdateHighscore:
    ; update highscore if score is greater than current highcore
    ld hl, highscore+1
    ld a, (score+1)
    cp (hl)             ; compare the upper byte first
    jr z, @hscorelower  ; if the upper byte is equal to...
    jr nc, @hscoreupdate; if upper byte is greater than...
    jr @nohscoreupdate  ; no need to check as upper byte is lower
@hscorelower:
    dec hl              ; check lower byte
    ld a, (score)
    cp (hl)
    jr c, @nohscoreupdate   ; if lower bute is less than

@hscoreupdate:          ; new highscore!
    ld hl, highscore
    ld a, (score)
    ldi (hl), a
    ld a, (score+1)
    ldi (hl), a
@nohscoreupdate:
    ret

.ENDS

; vim: filetype=wla
