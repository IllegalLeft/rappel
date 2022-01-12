;==============================================================================
; STRINGS
;==============================================================================

.INCLUDE "header.i"


.ASCIITABLE
    MAP "A" to "Z" = $50
    MAP "a" to "z" = $50
    MAP "0" to "9" = $6B
    MAP " " = $6A
    MAP "@" = $00
.ENDA


.SECTION "Strings" FREE

; Title Screen
Str_Highscore:
.ASC "Highscore@"
Str_PressStart:
.ASC "Press  Start@"
Str_Author:
.ASC "By Samuel Volk@"
Str_Date:
.ASC "2021@"

;Gameplay
Str_Hi:
.ASC "HI@"
Str_Sc:
.ASC "SC@"
Str_GameOver:
.ASC "GAMEOVER@"
Str_Paused:
.ASC "PAUSED@"

.ENDS

; vim: filetype=wla
