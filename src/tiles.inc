; set up tiles in vram
inittiles:
  ; copy tiles 0
  ld de, tileset1 
  ld hl, VRAM9000
  ld bc, tileset1_end - tileset1
  call memcpy
  
  ; copy oam tile data 
  ld de, tileset0
  ld hl, VRAM
  ld bc, tileset0_end - tileset0 
  call memcpy

  ; copy tilemap 0
  ;ld de, tilemap0
  ;ld hl, SCRN0 
  ;ld bc, tilemap0_end - tilemap0
  ;call memcpy

  ret

tileset0:
#include "tileset0.inc"
tileset0_end:

tileset1:
#include "tileset1.inc"
tileset1_end:

; tile map 
.se 0x30
.de EMPTY_TILE, 1
.de BG1, 1 ; background 1
.de FL1, 1 ; floor 1
.de HP_ICON, 1 ; health icon 
.de HP_BAR_LEFT, 1
.de HP_BAR_MIDDLE, 1
.de HP_BAR_RIGHT, 1

; tile map flags
.se 1
.de TILE_COLLIDER, 1
.de TILE_KILL, 2
