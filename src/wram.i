;==============================================================================
; WRAM
;==============================================================================


; OAM Buffer
.STRUCT OAMentry
    y       DB
    x       DB
    tile    DB
    attr    DB
.ENDST

.DEFINE OAMbuffer   $C000 EXPORT


; Structures
.STRUCT plyr
    x	    db
    y	    db
    velx    db              ; absolute value
.ENDST

.RAMSECTION "Misc Vars" BANK 0 SLOT 2
    OAM		INSTANCEOF OAMentry 40
    seed	DB
    highscore	DW		    ; single highest score
    score	DW		    ; current game score
    depth	DW
    player      INSTANCEOF plyr
    screeny	DB		    ; for score bar
    mapbuffer	DS 20*256           ; 20 x 256 tiles
    rowdrawsrc	DW		    ; source address for row to draw
    rowdrawdst	DW		    ; dest. address for row to draw
.ENDS


; vim: filetype=wla
