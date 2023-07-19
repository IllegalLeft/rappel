;==============================================================================
; Memory Map
;==============================================================================

.DEFINE _BANK       $4000
.DEFINE _VRAM       $8000
.DEFINE _MAP0       $9800
.DEFINE _MAP1       $9C00
.DEFINE _WRAM       $C000
.DEFINE _WRAMBANK   $D000
.DEFINE _OAM        $FE00
.DEFINE _IO         $FF00
.DEFINE _WAVERAM    $FF30
.DEFINE _HRAM       $FF80


;==============================================================================
; Registers
;==============================================================================

.DEFINE P1    $FF00
.DEFINE SB    $FF01
.DEFINE SC    $FF02
.DEFINE DIV   $FF04
.DEFINE TIMA  $FF05
.DEFINE TMA   $FF06
.DEFINE TAC   $FF07
.DEFINE IF    $FF0F
.DEFINE NR10  $FF10
.DEFINE NR11  $FF11
.DEFINE NR12  $FF12
.DEFINE NR13  $FF13
.DEFINE NR14  $FF14
.DEFINE NR21  $FF16
.DEFINE NR22  $FF17
.DEFINE NR23  $FF18
.DEFINE NR24  $FF19
.DEFINE NR30  $FF1A
.DEFINE NR31  $FF1B
.DEFINE NR32  $FF1C
.DEFINE NR33  $FF1D
.DEFINE NR34  $FF1E
.DEFINE NR42  $FF21
.DEFINE NR43  $FF22
.DEFINE NR44  $FF23
.DEFINE NR50  $FF24
.DEFINE NR51  $FF25
.DEFINE NR52  $FF26
.DEFINE LCDC  $FF40
.DEFINE STAT  $FF41
.DEFINE SCY   $FF42
.DEFINE SCX   $FF43
.DEFINE LY    $FF44
.DEFINE LYC   $FF45
.DEFINE DMA   $FF46
.DEFINE BGP   $FF47
.DEFINE OBP0  $FF48
.DEFINE OBP1  $FF49
.DEFINE WY    $FF4A
.DEFINE WX    $FF4B
.DEFINE IE    $FFFF

.DEFINE R_P1    $00
.DEFINE R_SB    $01
.DEFINE R_SC    $02
.DEFINE R_DIV   $04
.DEFINE R_TIMA  $05
.DEFINE R_TMA   $06
.DEFINE R_TAC   $07
.DEFINE R_IF    $0F
.DEFINE R_NR10  $10
.DEFINE R_NR11  $11
.DEFINE R_NR12  $12
.DEFINE R_NR13  $13
.DEFINE R_NR14  $14
.DEFINE R_NR21  $16
.DEFINE R_NR22  $17
.DEFINE R_NR23  $18
.DEFINE R_NR24  $19
.DEFINE R_NR30  $1A
.DEFINE R_NR31  $1B
.DEFINE R_NR32  $1C
.DEFINE R_NR33  $1D
.DEFINE R_NR34  $1E
.DEFINE R_NR42  $21
.DEFINE R_NR43  $22
.DEFINE R_NR44  $23
.DEFINE R_NR50  $24
.DEFINE R_NR51  $25
.DEFINE R_NR52  $26
.DEFINE R_LCDC  $40
.DEFINE R_STAT  $41
.DEFINE R_SCY   $42
.DEFINE R_SCX   $43
.DEFINE R_LY    $44
.DEFINE R_LYC   $45
.DEFINE R_DMA   $46
.DEFINE R_BGP   $47
.DEFINE R_OBP0  $48
.DEFINE R_OBP1  $49
.DEFINE R_WY    $4A
.DEFINE R_WX    $4B
.DEFINE R_IE    $FF


;==============================================================================
; Misc Defines
;==============================================================================

.DEFINE SCREEN_W   160
.DEFINE SCREEN_H   140


; vim: filetype=wla
