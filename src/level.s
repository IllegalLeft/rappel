;==============================================================================
; Level
;==============================================================================
.INCLUDE "header.i"

.SECTION "LevelRoutines" FREE

PlaceObstacle:
    ; Places a cliff in the map buffer at a certain x and y.
    ; a	    x ordinate
    ; b	    y ordinate

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

.DEFINE CLIFF_TL    $0D
.DEFINE CLIFF_TR    $0E
.DEFINE CLIFF_BL    $0F
.DEFINE CLIFF_BR    $10
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
    ; generates a level with some randomly placed clifs
    ld c, 50
-   call RandByte
    and %11111110		    ; cliff can only be on even numbered rows
    ld b, a
    call RandByte
    and %11111110		    ; cliff can only be even numbered columns
    push bc
    call PlaceObstacle
    pop bc
    dec c
    jr nz, -
    ret

.ENDS

; vim: filetype=wla
