;==============================================================================
; Title
;==============================================================================

.INCLUDE "gb_hardware.i"
.INCLUDE "header.i"


.DEFINE CLOUD_X     -32
.DEFINE CLOUD_Y     20
.DEFINE CLOUD_VELX  1


.STRUCT cld
    x       DB
    y       DB
    velx    DB
.ENDST

.RAMSECTION "TitleVars" BANK 0 SLOT 3   ; Internal WRAM
    cloud INSTANCEOF cld
.ENDS


.SECTION "Title"

TitleSetup:
    ; load title tiles
    ld hl, title_tile_data
    ld de, _VRAM
    ld bc, title_tile_data_size
    call MoveData

    ; load cloud tiles
    ld hl, tiles_cloud
    ld de, $8800
    ld bc, tiles_cloud_size
    call MoveData

    ; cloud WRAM init
    ld a, CLOUD_X
    ld (cloud.x), a
    ld a, CLOUD_Y
    ld (cloud.y), a
    ld a, 1
    ld (cloud.velx), a

    ; cloud OAM init
    ld a, 0
    ld de, tilemap_cloud
    call ObjInit

    ld a, 1
    ld de, tilemap_cloud+4
    call ObjInit

    ; draw title mountain
    ld b, 20
    ld c, 8
    ld de, _MAP0
    ld hl, title_map_data
    call LoadPicture

    ld a, STATE_TITLE
    ldh (<state), a
    ld a, 128
    ldh (R_SCY), a          ; reset screen for scroll

    ld a, %10010011         ; setup screen
    ldh (R_LCDC), a

    ld a, %10000000         ; sound on
    ldh (R_NR52), a
    ld a, %01000100         ; volume
    ldh (R_NR50), a
    ld a, $FF               ; enable all channels to both L&R
    ldh (R_NR51), a

    ld a, $01
    ldh (R_IE), a           ; enable only vblank interrupt
    ei

    ; Title Animation
-   ld a, 2
    call WaitFrames
    call ReadInput          ; check if player hit joypad for skip
    ldh a, (<joypadDiff)
    and $FF
    jr nz, @skipanimation
    ldh a, (R_SCY)
    inc a
    inc a
    ldh (R_SCY), a
    jr nz, -
@skipanimation
    xor a
    ldh (R_SCY), a
    ld a, 20
    call WaitFrames

    ; draw title font
    ld b, 20
    ld c, 8
    ld de, _MAP0+(8*32)
    ld hl, title_map_data+(20*8)
    call LoadPicture

    ; wait a lil bit
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

    ld hl, Song_RapelRedux
    call LoadMusic
    ld hl, Wave_Tri
    call LoadWaveform
    ret


MoveCloud:
    ; move cloud x
    ld a, (cloud.x)
    ld b, a
    ld a, (cloud.velx)
    add b
    ld (cloud.x), a
    ld b, a
    ld a, (cloud.y)
    ld c, a
    xor a
    push bc                 ; save sprite x, y
    call ObjMove            ; first 2x2 sprite
    pop bc
    ld a, b
    add 16                  ; next sprite is 16px to right
    ld b, a
    ld a, 1
    call ObjMove
    ret

.ENDS

; vim: filetype=wla
