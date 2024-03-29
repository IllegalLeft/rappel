; ///////////////////////
; //                   //
; //  File Attributes  //
; //                   //
; ///////////////////////

; Filename: title.png
; Pixel Width: 160px
; Pixel Height: 144px

; /////////////////
; //             //
; //  Constants  //
; //             //
; /////////////////

.DEFINE title_tile_map_size  $0168
.DEFINE title_tile_map_width  $14
.DEFINE title_tile_map_height  $12

.DEFINE title_tile_data_size  $04C0
.DEFINE title_tile_count  $4C
.EXPORT title_tile_data_size, title_tile_count

; ////////////////
; //            //
; //  Map Data  //
; //            //
; ////////////////

title_map_data:
.INCBIN "../gfx/title.map"

; /////////////////
; //             //
; //  Tile Data  //
; //             //
; /////////////////

title_tile_data:
.INCBIN "../gfx/title.tiles"

;set ft=wla
