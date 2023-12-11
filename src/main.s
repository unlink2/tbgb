#include "hw.s"

.org 0x0
.fill 0, 0x100
#include "header.s"
 
entry:
  ; wait for first vblank
  call vblankwait
  
  ; initially disable lcd 
  call lcdoff

  ; copy tiles 0
  ld de, tiles0
  ld hl, 0x9000
  ld bc, tiles0_end - tiles0
  call memcpy

  ; copy tilemap 0
  ld de, tilemap0
  ld hl, 0x9800
  ld bc, tilemap0_end - tilemap0
  call memcpy

  ; enable lcd
  call lcdon 

forever:
  jp forever 


; memcpy:
; parameters: 
;   hl: src
;   de: dst
;   bc: len
memcpy:
@next:
  ld a, [de]
  ld [hl+], a
  inc de
  dec bc
  ld a, b
  or a, c
  jp nz, @next
  ret

vblankwait:
  ld a, [RLY]
  cp a, 144
  jp c, vblankwait 
  ret

lcdon:
  ld a, LCDCF_ON | LCDCF_BGON
  ld [RLCD], a
      
  ld a, 0b11100100
  ld [RBGP], a
  ret

lcdoff:
  ld a, 0
  ld [RLCD], a
  ret

#include "tiles.s"
#include "tilemaps.s"

; fill bank
.fill 0, 0x7FFF - $
