;==============================================================================
; WRAM
;==============================================================================


; Structures
.STRUCT plyr
    x	    db
    y	    db
    velx    db              ; absolute value
.ENDST

.STRUCT OAMentry
    y       DB
    x       DB
    tile    DB
    attr    DB
.ENDST


.RAMSECTION "Misc Vars" BANK 0 SLOT 2
    seed	DB
    highscore	DW		    ; single highest score
    score	DW		    ; current game score
    depth	DW
    player      INSTANCEOF plyr
    screeny	DB		    ; for score bar
    pendingdraw DB		    ; pending draw for
				    ; 0 - none, 1 - clear row, 2+ - cliff
    mapbuffer	DSB 14*32
.ENDS

; OAM Buffer
.DEFINE OAMbuffer   $C100 EXPORT
.ENUM OAMbuffer EXPORT
    OAM    INSTANCEOF OAMentry 40
.ENDE


; vim: filetype=wla
