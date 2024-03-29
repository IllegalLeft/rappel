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
    jr nz, -
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
    jr nz, -
    ret

ReadInput:
    ld a, (joypadNew)   ; move old keypad state
    ld (joypadOld), a

    ld a, $20           ; select P14
    ld (_IO), a
    ld a, (_IO)         ; read pad
    ld a, (_IO)         ; a bunch of times
    cpl                 ; active low so flip 'er
    and $0f             ; only need last 4 bits
    swap a
    ld b, a
    ld a, $10
    ld (_IO), a         ; select P15
    ld a, (_IO)
    ld a, (_IO)
    cpl
    and $0F             ; only need last 4 bits
    or b                ; put a and b together
    ld (joypadNew), a   ; store into 0page for later

    ld b, a             ; find difference in two keystates
    ld a, (joypadOld)
    xor b
    ld b, a
    ld a, (joypadNew)
    and b
    ld (joypadDiff), a

    ld a, $30           ; reset joypad
    ld (_IO), a
    ret

RandByte:
    ; gives a random byte in a
    ld a, (seed)
    sla a
    jr nc, +
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
    ldh (<state), a     ; start the game
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
    ld hl, _WRAM
    ld bc, $2000-4
    call BlankData          ; blank WRAM
    ld hl, _VRAM
    ld bc, $2000
    call BlankData          ; blank VRAM
    ld hl, _HRAM
    ld bc, $FFFE-$FF80
    call BlankData          ; blank HRAM

    ; load palette
    ld a, %11100100         ; bg
    ldh (R_BGP), a
    ld a, %11100100         ; obj
    ldh (R_OBP0), a

    ; setup DMA routine
    ld hl, DMARoutineOriginal
    ld de, DMARoutine
    ld bc, _sizeof_DMARoutineOriginal
    call MoveData

    ; load font tiles
    ld hl, FontTiles
    ld de, _VRAM+$500
    ld bc, _sizeof_FontTiles
    call MoveData

    xor a
    ld hl, highscore        ; blank highscore
    ldi (hl), a
    ld (hl), a
    jr Title


SoftReset:
    xor a
    ldh (R_IE), a       ; no need for any interrupts
    ldh (R_NR52), a     ; no need for sound either
-   ld a, (LY)          ; wait vblank
    cp $91
    jr nz, -
    ldh a, (R_LCDC)
    res 7, a
    ldh (R_LCDC), a

    ; clear OAM
    xor a
    ld hl, OAM
    ld bc, 40*4
    call BlankData
    ; clear tilemap
    ld hl, _MAP0
    ld bc, $BFF
    call BlankData

Title:
    call TitleSetup

TitleLoop:
    halt
    nop
    call ReadInput
    call HandleTitleInput
    call UpdateMusic

    ldh a, (<ticks)
    and $07
    jr nz, +
    call MoveCloud
+
    ldh a, (<state)
    cp STATE_TITLE
    jr z, TitleLoop

    call SetupGame

MainGameLoop:
    ; score bar
    xor a               ; clear screen y for score bar
    ldh (R_SCY), a
    halt                ; wait for score bar to end
    nop

    ; main game view
    ld a, (depth)       ; low byte of depth is the screen y ordinate
    ldh (R_SCY), a
    ldh a, (R_LCDC)
    xor %00001000       ; switch map address
    ldh (R_LCDC), a

    call ReadInput
    call HandleGameInput

    call UpdateMusic

    ; Vertical Blank
    halt
    nop

    ldh a, (R_LCDC)
    xor %00001000       ; swap to scorebar map
    ldh (R_LCDC), a

    ldh a, (<state)
    cp STATE_PAUSE
    jp z, PauseSetup

GameLogic:
    ldh a, (<ticks)     ; only need to apply x vel every so many frames
    and $01
    jr nz, @noapplyvelx
    call ApplyVelX
@noapplyvelx:

    ldh a, (<ticks)     ; only need to slow player vel every so many frames
    and $03
    jr nz, @noslow
    call SlowPlayerVel
@noslow:

    call SetPlayerY
    call CheckCollision
    jp nc, GameoverSetup; gameover if side collision

    call MoveRope

    xor a               ; clear carry flag for when using daa with scorebar
    ; update scorebar
    ld a, (score+1)
    ld de, $9C0F
    call PrintInt
    ld a, (score)
    inc de
    call PrintInt

    jp MainGameLoop


PauseSetup:
    call StopMusic

    ; load pause tiles
    ld hl, OAM.33       ; starting OAM address
    ld de, Str_Paused   ; start of text
    ld b, $50           ; y ordinate
    ld c, $40           ; starting x ordinate

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
    inc hl              ; no flags
.ENDR

    ; blank out rope sprites by setting Y OAM byte to 0
    xor a
    ld hl, OAM.5
    ld bc, 4            ; 4 OAM entries * 4 bytes
    ld d, a
-   ldi (hl), a
    inc hl
    inc hl
    inc hl
    dec bc
    or c
    ld a, d
    jr nz, -


PauseLoop:
    ; score bar
    xor a               ; clear screen y for score bar
    ldh (R_SCY), a
    halt                ; wait for score bar to end
    nop

    ; main game view
    ld a, (depth)       ; low byte of depth is the screen y ordinate
    ldh (R_SCY), a
    ldh a, (R_LCDC)
    xor %00001000       ; switch map address
    ldh (R_LCDC), a

    call ReadInput

    ; Vertical blank
    halt
    nop

    ldh a, (R_LCDC)
    xor %00001000       ; swap to scorebar map
    ldh (R_LCDC), a

    ; check if unpaused
    ldh a, (<joypadDiff)
    and JOY_START
    jr z, PauseLoop     ; pause loop if not unpaused
    ld a, STATE_GAME    ; set state to playing
    ldh (<state), a

    xor a
    ld hl, OAM.33
    ld bc, 8*4          ; 8 OAM entries * 4 bytes
    call BlankData      ; remove sprites for paused text

    jp MainGameLoop     ; then resume main gameplay loop


GameoverSetup:
    ld a, STATE_GAMEOVER
    ldh (<state), a
    call UpdateHighscore

    call StopMusic

    ; load gameover tiles
    ld hl, OAM.33       ; starting OAM address
    ld de, Str_GameOver ; start of text
    ld b, $50           ; y ordinate
    ld c, $35           ; starting x ordinate

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
    inc hl              ; no flags
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
    inc hl              ; no flags
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
    inc hl              ; no flags
.ENDR

Gameover:
    ; score bar
    xor a               ; clear screen y for score bar
    ldh (R_SCY), a

    ; wait for score bar to end
    halt
    nop

    ; main game view
    ld a, (depth)       ; low byte of depth is the screen y ordinate
    ldh (R_SCY), a
    ldh a, (R_LCDC)
    xor %00001000       ; switch map address
    ldh (R_LCDC), a

    call ReadInput

    ldh a, (<joypadDiff)
    and JOY_START
    jp nz, SoftReset

    ; Vertical blank
    halt
    nop

    ldh a, (R_LCDC)
    xor %00001000       ; swap to scorebar map
    ldh (R_LCDC), a

    jr Gameover



;==============================================================================
; LOOKUP TABLES
;==============================================================================

.SECTION "Lookup Tables" FREE

ArcData:
.INCLUDE "arc.i"

.ENDS

; vim: filetype=wla
