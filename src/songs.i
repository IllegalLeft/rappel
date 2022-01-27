.SECTION "Music" FREE

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

; Music format:
; $00 = end of song
; $YX = note Y in octave X
;	notes $1-C, octaves $0-$6
; $7X = pause for X counts
; $FX = commands followed by operand bytes
;	$0 = tempo
;	$1 = loop
;	$2 = change instrument/voice
Songs:

.ENDS

; vim: filetype=wla
