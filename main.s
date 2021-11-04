;==============================================================================
;
; RAPPEL
;
; Samuel Volk, July 2021
;
; A Ludum Dare game I will port to GameBoy. Perhaps add more features?
;
;==============================================================================

.INCLUDE "gb_hardware.i"
.INCLUDE "header.i"
.INCLUDE "hram.i"
.INCLUDE "wram.i"

;==============================================================================
; SUBROUTINES
;==============================================================================
.BANK 0
.SECTION "Subroutines" FREE
; Init Subroutines
BlankData:
    ; a     value
    ; hl    destination
    ; bc    length/size
    ld d, a             ; will need later
-   ldi (hl), a
    dec bc
    ld a, b
    or c
    ld a, d
    jr nz, -
    ret

MoveData:
    ;hl  source
    ;de  destination
    ;bc  length/size
-   ldi a, (hl)
    ld (de), a
    inc de
    dec bc
    ld a, b
    or c
    jp nz, -
    ret

ScreenOn:
    ldh a, (R_LCDC)
    or %01000000
    ldh (R_LCDC), a
    ret

ScreenOff:
    ld a, 0
    ldh (R_LCDC), a
    ret

ReadInput:
    ld a, (joypadNew)	    ; move old keypad state
    ld (joypadOld), a

    ld a, $20		    ; select P14
    ld ($FF00), a
    ld a, ($FF00)	    ; read pad
    ld a, ($FF00)	    ; a bunch of times
    cpl			    ; active low so flip 'er 
    and $0f		    ; only need last 4 bits
    swap a
    ld b, a
    ld a, $10
    ld ($FF00), a	    ; select P15
    ld a, ($FF00)
    ld a, ($FF00)
    cpl
    and $0F		    ; only need last 4 bits
    or b		    ; put a and b together
    ld (joypadNew), a	    ; store into 0page for later

    ld b, a		    ; find difference in two keystates
    ld a, (joypadOld)
    xor b
    ld b, a
    ld a, (joypadNew)
    and b
    ld (joypadDiff), a

    ld a, $30		    ; reset joypad
    ld ($FF00), a
    ret

RandByte:
    ; gives a random byte in a
    ld a, (seed)
    sla a
    jp nc, +
    xor %00011101
+   ld (seed), a
    ret

.ENDS

.SECTION "Title Routines" FREE

HandleTitleInput:
    ldh a, (<joypadDiff) 
    and JOY_START
    jr z, @done
    ld a, 1
    ldh (<state), a	    ; start the game
@done:
    ret

.ENDS


;==============================================================================
; START
;==============================================================================
.BANK 0
.ORG $150
Start:
    di
    ld sp, $DFFF            ; setup stack in WRAM

-   ld a, (LY)              ; wait vblank
    cp $91
    jr nz, -
    xor a
    ldh (R_LCDC), a         ; turn off screen
    ldh (R_NR52), a         ; turn off sound

    ;xor a
    ld hl, $C000
    ld bc, $2000-4
    call BlankData          ; blank WRAM
    ld hl, $8000
    ld bc, $2000
    call BlankData          ; blank VRAM
    ld hl, $FF80
    ld bc, $FFFE-$FF80
    call BlankData	    ; blank HRAM

    ; load palette
    ld a, %11100100	    ; bg
    ldh (R_BGP), a
    ld a, %11100100	    ; obj
    ldh (R_OBP0), a

    ; setup DMA routine
    ld hl, DMARoutineOriginal
    ld de, DMARoutine
    ld bc, _sizeof_DMARoutineOriginal
    call MoveData

    ; load font tiles
    ld hl, tiles_font
    ld de, $8500
    ld bc, tiles_font_size
    call MoveData

    xor a
    ld hl, highscore	    ; blank highscore
    ldi (hl), a
    ld (hl), a
    jr TitleSetup


SoftReset:
    xor a
    ldh (R_IE), a	    ; no need for any interrupts
-   ld a, (LY)		    ; wait vblank
    cp $91
    jr nz, -
    ldh a, (R_LCDC)
    res 7, a
    ldh (R_LCDC), a

    ; clear OAM
    xor a
    ld hl, OAM
    ld bc, $100
    call BlankData

TitleSetup:
    ; load title tiles
    ld hl, title_tile_data
    ld de, $8000
    ld bc, title_tile_data_size
    call MoveData

    ; load title map data
    ld hl, title_map_data
    call LoadScreen

    ; print strings
    ld hl, Str_Highscore
    ld de, $9803
    call PrintStr
    ld a, (highscore+1)
    ld de, $980D
    call PrintInt
    ld a, (highscore)
    inc de
    call PrintInt
    ld hl, Str_PressStart
    ld de, $99A4
    call PrintStr
    ld hl, Str_Author
    ld de, $9A03
    call PrintStr
    ld hl, Str_Date
    ld de, $9A28
    call PrintStr

    xor a
    ldh (<state), a	    ; game state will be title
    ldh (R_SCY), a	    ; reset screen

    ld a, %10010011         ; setup screen
    ldh (R_LCDC), a

    ld a, $01
    ldh (R_IE), a           ; enable only vblank interrupt
    ei

TitleLoop:
    halt
    nop
    call DMARoutine
    call ReadInput
    call HandleTitleInput

    ldh a, (<state)
    cp 0
    jr z, TitleLoop


SetupGame:
    ; turn off screen
    xor a
    ldh (R_LCDC), a

    ; clear tilemap    
    xor a
    ld hl, $9800
    ld bc, $A33
    call BlankData

    ; clear map buffer
    ld hl, mapbuffer
    ld bc, 14*32
    call BlankData

    ; load tiles
    ld hl, Tiles
    ld de, $8000
    ld bc, (tiles_sprites_size+1)
    call MoveData
    
    ldh a, (R_DIV)	    ; get a random seed from the DIV timer register
    ld (seed), a

    call FillMap	    ; fill map with blank wall tiles

    ; set up player
    xor a
    ld b, 1
    call ObjInit
    xor a
    ld b, 20
    ld c, 20
    call ObjMove

    ld a, (160/2)-8	    ; place player in center
    ld (player.x), a
    call SetPlayerY

    xor a
    ld (player.velx), a	    ; blank velx
    ld hl, score	    ; blank score
    ldi (hl), a
    ldi (hl), a
    ;ld hl, depth	    ; blank depth
    ldi (hl), a
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

    ; setup scorebar interrupt
    ld a, $02		    ; enable STAT interrupt
    ldh (R_IE), a
    ld a, %01000000	    ; enable LYC=LY STAT interrupt
    ldh (R_STAT), a
    ld a, 8		    ; set LYC
    ldh (R_LYC), a

    ; turn on screen
    ld a, %10011011
    ldh (R_LCDC), a

MainGameLoop:
    ; score bar
    ld a, $02		    ; enable STAT interrupt
    ldh (R_IE), a
    ld a, (R_LCDC)
    xor %00001000
    ld a, 7
    ldh (R_LYC), a
    xor a		    ; clear screen y for score bar
    ldh (R_SCY), a

    ; wait for score bar to end
    halt
    nop

    ; main game view
    ld a, (depth)	    ; low byte of depth is the screen y ordinate
    ldh (R_SCY), a
    ldh a, (R_LCDC)
    xor %00001000	    ; switch map address
    ldh (R_LCDC), a

    ld a, $01
    ldh (R_IE), a	    ; enable VBlank interrupt

    call ReadInput
    call HandleGameInput

    ; Vertical Blank
    halt 
    nop

    ldh a, (R_LCDC)
    xor %00001000	    ; swap to scorebar map
    ldh (R_LCDC), a


GameLogic:
    call ApplyVelX
    call CheckWallCollision
    jr nc, GameoverSetup    ; gameover if side collision
    call SlowPlayerVel
    call SetPlayerY

    ; update scorebar
    ld a, (score+1)
    ld de, $9C0F
    call PrintInt
    ld a, (score)
    inc de
    call PrintInt

    jp MainGameLoop

GameoverSetup:
    ld a, $02		    ; game state is now 2 (gameover)
    ldh (<state), a
    
    ; update highscore if score is greater than current highcore
    ld hl, highscore+1
    ld a, (score+1)
    cp (hl)		    ; compare the upper byte first
    jr z, @hscorelower	    ; if the upper byte is equal to...
    jr nc, @hscoreupdate    ; if upper byte is greater than...
    jr @nohscoreupdate	    ; no need to check as upper byte is lower
@hscorelower:
    dec hl		    ; check lower byte
    ld a, (score)
    cp (hl)
    jr c, @nohscoreupdate   ; if lower bute is less than

@hscoreupdate:		    ; new highscore!
    ld hl, highscore
    ld a, (score)
    ldi (hl), a
    ld a, (score+1)
    ldi (hl), a
@nohscoreupdate:

Gameover:
    ; score bar
    ld a, $02		    ; enable STAT interrupt
    ldh (R_IE), a
    ld a, (R_LCDC)
    xor %00001000
    ld a, 7
    ldh (R_LYC), a
    xor a		    ; clear screen y for score bar
    ldh (R_SCY), a

    ; wait for score bar to end
    halt
    nop

    ; main game view
    ld a, (depth)	    ; low byte of depth is the screen y ordinate
    ldh (R_SCY), a
    ldh a, (R_LCDC)
    xor %00001000	    ; switch map address
    ldh (R_LCDC), a

    ld a, $01
    ldh (R_IE), a	    ; enable VBlank interrupt

    call ReadInput

    ldh a, (<joypadDiff)
    and JOY_START
    jp nz, SoftReset

    ; Vertical blank
    halt
    nop

    ldh a, (R_LCDC)
    xor %00001000	    ; swap to scorebar map
    ldh (R_LCDC), a

    jr Gameover



;==============================================================================
; LOOKUP TABLES
;==============================================================================

.SECTION "Lookup Tables" FREE
ArcData:
.INCLUDE "arc.i"

SinData:
.DBSIN 0, 180, 1, 160/2, 160/2
.ENDS

; vim: filetype=wla
