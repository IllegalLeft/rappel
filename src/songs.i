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
; $0X = octave X, $0-6
; $XY = note X for Y ticks
;       notes $1-$C, ticks $1-$F
; $EX = rest for X counts
; $FX = commands followed by operand byte(s)
;	$0 = tempo
;	$1 = loop, followed by addr to jump to
;	$2 = change instrument/voice
; $FF = end of song

; Music Commands
.DEFINE MUSCMD_OCTAVE   $00
.DEFINE MUSCMD_REST     $E0
.DEFINE MUSCMD_TEMPO    $F0
.DEFINE MUSCMD_LOOP     $F1
.DEFINE MUSCMD_VOICE    $F2
.DEFINE MUSCMD_END      $FF

; Note Definitions
.DEFINE C_      $1
.DEFINE C+      $2
.DEFINE Db      $2
.DEFINE D_      $3
.DEFINE D+      $4
.DEFINE Eb      $4
.DEFINE E_      $5
.DEFINE F_      $6
.DEFINE F+      $7
.DEFINE Gb      $7
.DEFINE G_      $8
.DEFINE G+      $9
.DEFINE Ab      $9
.DEFINE A_      $A
.DEFINE A+      $B
.DEFINE Bb      $B
.DEFINE B_      $C


; Music Macros
.MACRO octave
    .DB MUSCMD_OCTAVE | \1
.ENDM

.MACRO note ARGS PITCH, LENGTH
    .DB (PITCH << 4) | LENGTH
.ENDM

.MACRO rest
    .DB MUSCMD_REST | \1
.ENDM

.MACRO tempo
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
    octave 2
    note C_, 1
    note C_, 1
    note D+, 1
    note C+, 1
    note C_, 4
    note G_, 0
    note C+, 1
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
    octave 3
    note C_, 1
    note F_, 3
    note C_, 1
    note D+, 1
    octave 2
    note G_, 0
    note A+, 1
    octave 3
    note D_, 2
.ENDR
    note C_, 5
    note C_, 1
    note D+, 3
    octave 2
    note G+, 3
    loop Song_RapelReduxCh0
Song_RapelReduxCh1:
    songend
Song_RapelReduxCh2:
.REPEAT 3
    octave 2
    note C_, 1
    note C_, 1
    note D+, 1
    note C+, 1
    note C_, 4
    note G_, 0
    note C+, 1
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


Song_RapelDX:
    .DB $0C                     ; tempo
    .DB $00, $00, $01           ; voices
    .DW Song_RapelDXCh0         ; channel scores
    .DW Song_RapelDXCh1
    .DW Song_RapelDXCh2
    .DW Song_RapelDXCh3
Song_RapelDXCh0:
    octave 3
.REPEAT 3
    note C_, 1
    note F_, 3
    note C_, 1
    note D+, 1
    octave 2
    note G_, 0
    note A+, 1
    octave 3
    note D_, 2
.ENDR
    note C_, 5
    note C_, 1
    note D+, 3
    octave 2
    note G+, 3
    loop Song_RapelDXCh0
    songend
Song_RapelDXCh1:
    songend
Song_RapelDXCh2:
.REPEAT 3
    octave 2
    note C_, 1
    note C_, 1
    note D+, 1
    note C+, 1
    note C_, 4
    note G_, 0
    note C+, 1
.ENDR
    rest 8
    rest 8
    loop Song_RapelReduxCh2
    songend
    songend
Song_RapelDXCh3:
    .DB $01,$71,$01,$71
    .DB $02,$01,$02,$01
    .DB $01,$71,$01,$71
    .DB $02,$01,$02,$01
    loop Song_RapelReduxCh3
    songend

.ENDS

; vim: filetype=wla
