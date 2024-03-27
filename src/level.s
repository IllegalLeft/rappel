;==============================================================================
; Level
;==============================================================================
.INCLUDE "header.i"

.SECTION "LevelRoutines" FREE

PlaceObstacle:
    ; Places a cliff in the map buffer at a certain x and y.
    ; a     x ordinate
    ; b     y ordinate

    ld hl, mapbuffer
    ; add 20*y offset
    ld d, 0
    ld e, b
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

    ; add x offset
    ld c, a
    ld b, 0
    add hl, bc

.DEFINE CLIFF_TL    $0E
.DEFINE CLIFF_TR    $0F
.DEFINE CLIFF_BL    $10
.DEFINE CLIFF_BR    $11
    ; set tiles
    ld a, CLIFF_TL
    ldi (hl), a
    inc a
    ldd (hl), a
    ld bc, 20
    add hl, bc
    inc a
    ldi (hl), a
    inc a
    ld (hl), a
    ret


GenerateLevel:
    ; generates a level with some randomly placed cliffs
    ld c, 30
-   call RandByte           ; get a random y ordinate
    and %11111110           ; cliff can only be on even numbered rows
    ld b, a
    call RandByte           ; get a random x ordinate
    and %00011110           ; cliff can only be even numbered columns
    cp 20                   ; is it over 20? (mapbuff width)
    jr c, +
    jr -                    ; pick a new number
+
    push bc
    call PlaceObstacle
    pop bc
    dec c
    jr nz, -
    ret

.ENDS

; vim: filetype=wla
