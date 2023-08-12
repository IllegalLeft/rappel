;==============================================================================
; MUSIC INCLUDES
;==============================================================================

; Channels
.ENUMID 0
.ENUMID CHAN_PULSE1
.ENUMID CHAN_PULSE2
.ENUMID CHAN_WAVE
.ENUMID CHAN_NOISE

;==============================================================================
; MUSIC DEFINITIONS
;==============================================================================
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
;

; Music Commands
.DEFINE MUSCMD_OCTAVE   $D0
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


;==============================================================================
; MUSIC MACROS
;==============================================================================
.MACRO octave
    .DB MUSCMD_OCTAVE | \1
.ENDM

.MACRO note ARGS PITCH, LENGTH
    .DB (PITCH << 4) | LENGTH
.ENDM

.MACRO sample ARGS ID
    .DB ID
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

; vim: filetype=wla
