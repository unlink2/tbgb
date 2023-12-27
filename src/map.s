; load map into the map buffer
; and into 
; inputs:
;   de: map to load 
mapload:
  ; TODO: in the futue maps may be compressed
  ; for now we just memcpy 
  ld hl, mapbuf 
  ld bc, MAP_W * MAP_H
  call memcpy

  ret

; draw map row at index n 
; inputs:
;   $1: row to draw
#macro mapdrawrow
  ld bc, MAP_W
  ld hl, SCRN0 + ($1 + 2) * 32
  ld de, mapbuf + $1 * MAP_W
  call memcpy 
#endmacro 

; load the current map into vram
mapfulldraw:
  ; we need to copy row by row into vram 
  mapdrawrow 0
  mapdrawrow 1
  mapdrawrow 2
  mapdrawrow 3
  mapdrawrow 4
  mapdrawrow 5
  mapdrawrow 6
  mapdrawrow 7
  mapdrawrow 8
  mapdrawrow 9
  mapdrawrow 10
  mapdrawrow 11
  mapdrawrow 12
  mapdrawrow 13
  mapdrawrow 14
  mapdrawrow 15

  ret 

; this is a demo map 18x18 tiles 
testmap:

