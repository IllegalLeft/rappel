.SECTION "Instruments & Samples" FREE

NoiseSamples:
Kick:		; 1
.DB $81, $56
Snare:		; 2
.DB $82, $51
HiHat2:		; 3
.DB $81, $00
HiHat2Open:	; 4
.DB $82, $00
HiHat:		; 5
.DB $42, $14

Instruments:
Inst1:
.DB $84, $F2
Inst2:
.DB $07, $40
Inst3:
.DB $27, $F2


Waves:
WaveSquare:
.DS 8 $FF
.DS 8 $00
Wave_Ramp:
.DB $00,$11,$22,$33,$44,$55,$66,$77
.DB $88,$99,$AA,$BB,$CC,$DD,$EE,$FF
Wave_Tri:
.DB $01,$23,$45,$67,$89,$AB,$CD,$EF
.DB $FE,$DC,$BA,$98,$76,$54,$32,$10
Wave_SoftSqr:
.DB $EE,$EE,$CD,$AC,$35,$23,$11,$11
.DB $11,$11,$32,$53,$CA,$DC,$EE,$EE
Wave_SoftRamp:
.DB $11,$12,$22,$33,$34,$45,$57,$79
.DB $9A,$BC,$DE,$FC,$86,$55,$44,$21

.ENDS


.SECTION "Music"
; Music format:
; $00 = end of song
; $XY = note Y in octave X
;	notes $1-C, octaves $0-$6
; $7X = rest for X counts
; $FX = commands followed by operand byte(s)
;	$0 = tempo
;	$1 = loop
;	$2 = change instrument/voice

; Music Commands
.DEFINE MUSCMD_END      $00
.DEFINE MUSCMD_TEMPO    $F0
.DEFINE MUSCMD_LOOP     $F1
.DEFINE MUSCMD_VOICE    $F2

; Note Definitions
.DEFINE C_      $01
.DEFINE C+      $02
.DEFINE Db      $02
.DEFINE D_      $03
.DEFINE D+      $04
.DEFINE Eb      $04
.DEFINE E_      $05
.DEFINE F_      $06
.DEFINE F+      $07
.DEFINE Gb      $07
.DEFINE G_      $08
.DEFINE G+      $09
.DEFINE Ab      $09
.DEFINE A_      $0A
.DEFINE A+      $0B
.DEFINE Bb      $0B
.DEFINE B_      $0C


; Music Macros
.MACRO note ARGS PITCH, OCTAVE
    .DB (OCTAVE << 4) | PITCH
.ENDM

.MACRO rest ARGS COUNT
    .DB $70 | COUNT
.ENDM

.MACRO tempo NARGS 1
    .DB MUSCMD_TEMPO, \1
.ENDM

.MACRO loop ARGS ADDR
    .DB MUSCMD_LOOP
    .DW ADDR
.ENDM

.MACRO changevoice ARGS VOICE
    .DB MUSCMD_VOICE, VOICE
.ENDM

.MACRO songend
    .DB MUSCMD_END
.ENDM


Song_Rapel:
    .DB $0C             ; tempo
    .DB $00, $00, $01   ; voices
    .DW Song_RapelCh0   ; channel scores
    .DW Song_RapelCh1
    .DW Song_RapelCh2
    .DW Song_RapelCh3
Song_RapelCh0:
Song_RapelCh1:
    songend
Song_RapelCh2:
    note C_, 2
    rest 1
    note C_, 2
    rest 1
    note D+, 2
    rest 1
    note C+, 2
    rest 1
    note C_, 2
    rest 4
    note G_, 2
    note C+, 2
    rest 1
    loop Song_RapelCh2
    songend
Song_RapelCh3:
    .DB $01,$71,$01,$71
    .DB $02,$01,$02,$01
    .DB $01,$71,$01,$71
    .DB $02,$01,$02,$01
    loop Song_RapelCh3
    songend

Song_RapelRedux:
    .DB $0C                     ; tempo
    .DB $00, $00, $01           ; voices
    .DW Song_RapelReduxCh0      ; channel scores
    .DW Song_RapelReduxCh1
    .DW Song_RapelReduxCh2
    .DW Song_RapelReduxCh3
Song_RapelReduxCh0:
.REPEAT 3
    note C_, 3
    rest 1
    note F_, 3
    rest 3
    note C_, 3
    rest 1
    note D+, 3
    rest 1
    note G_, 2
    note A+, 2
    rest 1
    note D_, 3
    rest 2
.ENDR
    note C_, 3
    rest 5
    note C_, 3
    rest 1
    note D+, 3
    rest 3
    note G+, 2
    rest 3
    loop Song_RapelReduxCh0
Song_RapelReduxCh1:
    songend
Song_RapelReduxCh2:
.REPEAT 3
    note C_, 2
    rest 1
    note C_, 2
    rest 1
    note D+, 2
    rest 1
    note C+, 2
    rest 1
    note C_, 2
    rest 4
    note G_, 2
    note C+, 2
    rest 1
.ENDR
    rest 8
    rest 8
    loop Song_RapelReduxCh2
    songend
Song_RapelReduxCh3:
    .DB $01,$71,$01,$71
    .DB $02,$01,$02,$01
    .DB $01,$71,$01,$71
    .DB $02,$01,$02,$01
    loop Song_RapelReduxCh3
    songend

.ENDS

; vim: filetype=wla
