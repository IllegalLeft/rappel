;==============================================================================
; WRAM
;==============================================================================


; Structures
.STRUCT plyr
    x	    db
    y	    db
    velx    db              ; absolute value
.ENDST

.RAMSECTION "Misc Vars" BANK 0 SLOT 2
    seed	DB
    highscore	DW		    ; single highest score
    score	DW		    ; current game score
    depth	DW
    player      INSTANCEOF plyr
    screeny	DB		    ; for score bar
    currentmap	DW		    ; pointer to current map
.ENDS


; OAM Buffer
.STRUCT OAMentry
    y       DB
    x       DB
    tile    DB
    attr    DB
.ENDST

.DEFINE OAMbuffer   $C100 EXPORT

.ENUM OAMbuffer EXPORT
    OAM    INSTANCEOF OAMentry 40
.ENDE


; vim: filetype=wla
