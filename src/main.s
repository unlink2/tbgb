#include "hw.s"

.org 0x0
.fill 0, 0x100
#include "header.s"
 
entry:
wait_vblank:
  ld a, [RLY]
  cp a, 144
  jp c, wait_vblank

disable_lcd:
  ; lcd off 
  ld a, 0
  ld [RLCD], a

copy_tiles:
  ld de, tiles
  ld hl, 0x9000
  ld bc, tiles_end - tiles
@copy_tiles:
  ld a, [de]
  ld [hl+], a
  inc de
  dec bc
  ld a, b
  or a, c
  jp nz, @copy_tiles

copy_tilemap:
  ld de, tilemap
  ld hl, 0x9800
  ld bc, tilemap_end - tilemap
@copy_tilemap:
  ld a, [de]
  ld [hl+], a
  inc de
  dec bc
  ld a, b
  or a, c
  jp nz, @copy_tilemap 
 
enable_lcd:
  ld a, LCDCF_ON | LCDCF_BGON
  ld [RLCD], a
      
  ld a, 0b11100100
  ld [RBGP], a

forever:
  jp forever 

tiles:
.db 0xFF, 0xAA, 0xBB, 0xCC, 0xEE, 0x11, 0x22, 0x33
tiles_end:

tilemap:
.db 0x00
tilemap_end:


; fill bank
.fill 0, 0x7FFF - $
