;==============================================================================
; HRAM
;==============================================================================


.ENUM $FF80 EXPORT
    DMARoutine      DSB 10	; DMA Routine
    ticks	    DB
    state	    DB		; 0 - title
				; 1 - game
				; 2 - game over
				; 3 - pause
    joypadNew       DB
    joypadOld       DB
    joypadDiff      DB
.ENDE


.DEFINE JOY_A	    1 << 0
.DEFINE JOY_B	    1 << 1
.DEFINE JOY_SELECT  1 << 2
.DEFINE JOY_START   1 << 3
.DEFINE JOY_RIGHT   1 << 4
.DEFINE JOY_LEFT    1 << 5
.DEFINE JOY_UP	    1 << 6
.DEFINE JOY_DOWN    1 << 7
.EXPORT JOY_A, JOY_B, JOY_SELECT, JOY_START
.EXPORT JOY_LEFT, JOY_RIGHT, JOY_UP, JOY_DOWN


; vim: filetype=wla
