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
    mapy	DB		    ; measured from top edge of screen, 0-256
    mapypix	DB		    ; pixel offset for mapy
    currentmap	DW		    ; pointer to current map
    mapbuffer	DS 20*256
    rowdrawsrc	DW		    ; source address for row to draw
    rowdrawdst	DW		    ; dest. address for row to draw
.ENDS


; vim: filetype=wla
