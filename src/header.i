;==============================================================================
; Header
;==============================================================================

.GBHEADER
    NAME "RAPPEL"
    CARTRIDGETYPE $00       ; RAM only
    RAMSIZE $00             ; 32KByte, no banks
    COUNTRYCODE $01         ; outside Japan
    NINTENDOLOGO
    LICENSEECODENEW "SV"
    ROMDMG                  ; DMG rom
.ENDGB


.MEMORYMAP
    DEFAULTSLOT 0
    SLOT 0 START $0000 SIZE $4000 NAME "ROM-0"
    SLOT 1 START $4000 SIZE $4000 NAME "ROM-1+"
    SLOT 2 START $8000 SIZE $2000 NAME "VRAM"
    SLOT 3 START $C000 SIZE $2000 NAME "WRAM"
.ENDME

.ROMBANKSIZE $4000
.ROMBANKS 2

; vim: filetype=wla
