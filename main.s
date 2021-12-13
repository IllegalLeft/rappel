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

ScreenFadeOut:
.REPEAT 4
    ldh a, (R_BGP)
    sla a
    sla a
    ldh (R_BGP), a
    ldh (R_OBP0), a
    halt
    nop
    halt
    nop
.ENDR
    ret
ScreenFadeIn:
    ld a, %01000000
    ldh (R_BGP), a
    ldh (R_OBP0), a
    halt
    nop
    halt
    nop
    ld a, %10010000
    ldh (R_BGP), a
    ldh (R_OBP0), a
    halt
    nop
    halt
    nop
    ld a, %11100100
    ldh (R_BGP), a
    ldh (R_OBP0), a
    halt
    nop
    halt
    nop
    ret

WaitFrames:
    ; waits n frames
    ; a	    number of frames to wait
    cp 0		    ; check it's not 0 first
    ret z
-   halt
    nop
    dec a
    jp nz, -
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
    ld a, STATE_GAME
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
    ; clear tilemap
    ld hl, $9800
    ld bc, $BFF
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

    ld a, STATE_TITLE
    ldh (<state), a
    ld a, $60
    ldh (R_SCY), a	    ; reset screen for scroll

    ld a, %10010011         ; setup screen
    ldh (R_LCDC), a

    ld a, $01
    ldh (R_IE), a           ; enable only vblank interrupt
    ei

    ; Title Animation
-   ld a, 3
    call WaitFrames
    call ReadInput	    ; check if we need to skip it.
    ldh a, (<joypadDiff)
    and $FF
    jr nz, @skipanimation
    ldh a, (R_SCY)
    dec a
    ldh (R_SCY), a
    jr nz, -
@skipanimation
    xor a
    ldh (R_SCY), a
    ld a, 20
    call WaitFrames

    ; print strings
    ld hl, Str_Author
    ld de, $9A03
    call PrintStr
    ld hl, Str_Date
    ld de, $9A28
    call PrintStr
    halt
    nop
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

TitleLoop:
    halt
    nop
    call ReadInput
    call HandleTitleInput

    ldh a, (<state)
    cp STATE_TITLE
    jr z, TitleLoop


SetupGame:
    call ScreenFadeOut
    ; turn off screen
    xor a
    ldh (R_LCDC), a

    ; clear tilemap    
    xor a
    ld hl, $9800
    ld bc, $A33
    call BlankData

    ; load tiles
    ld hl, Tiles
    ld de, $8000
    ld bc, (tiles_sprites_size+1)
    call MoveData
    
    ldh a, (R_DIV)	    ; get a random seed from the DIV timer register
    ld (seed), a

    ; load in map
    ld hl, TestMap
    ld a, l		    ; store into currentmap pointer
    ld (currentmap), a
    ld a, h
    ld (currentmap+1), a
    ld de, $9800
    ld b, 32		    ; lines to do
--  ld c, 160/8		    ; individual tiles on row
-   ldi a, (hl)
    ld (de), a
    inc de
    dec c
    jr nz, -
    ld a, $20-$14	    ; offset to next row in map
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    dec b
    jr nz, --

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
    call ScreenFadeIn

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

    ldh a, (<state)
    cp STATE_PAUSE
    jp z, PauseSetup

GameLogic:
    call ApplyVelX
    call SlowPlayerVel
    call SetPlayerY
    call CheckCollision
    jp nc, GameoverSetup    ; gameover if side collision

    ccf			    ; to fix when using daa with scorebar
    ; update scorebar
    ld a, (score+1)
    ld de, $9C0F
    call PrintInt
    ld a, (score)
    inc de
    call PrintInt

    jp MainGameLoop


PauseSetup:
    ; load pause tiles
    ld hl, OAM.33	    ; starting OAM address
    ld de, Str_Paused	    ; start of text
    ld b, $50		    ; y ordinate
    ld c, $40		    ; starting x ordinate

.REPEAT 6
    ld a, b
    ldi (hl), a
    ld a, c
    ldi (hl), a
    add a, 8
    ld c, a
    ld a, (de)
    ldi (hl), a
    inc de
    inc hl		    ; no flags
.ENDR

PauseLoop:
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

    ; Vertical blank
    halt
    nop

    ldh a, (R_LCDC)
    xor %00001000	    ; swap to scorebar map
    ldh (R_LCDC), a

    ; check if unpaused
    ldh a, (<joypadDiff)
    and JOY_START
    jr z, PauseLoop	    ; pause loop if not unpaused
    ld a, STATE_GAME	    ; set state to playing
    ldh (<state), a

    xor a
    ld hl, OAM.33
    ld bc, 8*4		    ; 8 OAM entries * 4 bytes
    call BlankData	    ; remove sprites for paused text

    jp MainGameLoop	    ; then resume main gameplay loop


GameoverSetup:
    ld a, STATE_GAMEOVER
    ldh (<state), a
    call UpdateHighscore

    ; load gameover tiles
    ld hl, OAM.33	    ; starting OAM address
    ld de, Str_GameOver	    ; start of text
    ld b, $50		    ; y ordinate
    ld c, $35		    ; starting x ordinate

.REPEAT 3
    ld a, b
    ldi (hl), a
    ld a, c
    ldi (hl), a
    add a, 8
    ld c, a
    ld a, (de)
    ldi (hl), a
    inc de
    inc hl		    ; no flags
.ENDR
    ld a, b
    ldi (hl), a
    ld a, c
    ldi (hl), a
    add a, 16
    ld c, a
    ld a, (de)
    ldi (hl), a
    inc de
    inc hl		    ; no flags
.REPEAT 4
    ld a, b
    ldi (hl), a
    ld a, c
    ldi (hl), a
    add a, 8
    ld c, a
    ld a, (de)
    ldi (hl), a
    inc de
    inc hl		    ; no flags
.ENDR

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

;==============================================================================
; MAPS
;==============================================================================

.SECTION "Maps" FREE

.DEFINE TestMap_Len $14*$20	    ; $14 columns, $20 rows
.EXPORT TestMap_Len

TestMap:
.DB $0D, $0E, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0F, $10, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0D, $0E, $09, $0A, $09, $0A, $09, $0A, $0D, $0E
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0F, $10, $0B, $0C, $0B, $0C, $0B, $0C, $0F, $10
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $09, $0A, $09, $0A, $09, $0A, $09, $0A, $09, $0A
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
.DB $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C
TestMapEnd:

.ENDS


; vim: filetype=wla
