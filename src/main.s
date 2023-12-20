#include "hw.inc"
#include "macros.inc"

#include "wram.inc"
#include "sram.inc"
#include "oam.inc"

.org 0x0
#include "jmp.inc"
.fill 0, 0x100 - $
#include "header.inc"
 
entry:
  ; wait for first vblank
  call vblankwait
  
  ; initially disable lcd 
  call lcdoff
  
  call initmem 

  ; copy tiles 0
  ld de, tiles0
  ld hl, VRAM9000
  ld bc, tiles0_end - tiles0
  call memcpy
  
  ; copy oam tile data 
  ld de, acts0
  ld hl, VRAM
  ld bc, acts0_end - acts0 
  call memcpy

  ; copy tilemap 0
  ld de, tilemap0
  ld hl, SCRN0 
  ld bc, tilemap0_end - tilemap0
  call memcpy
  
  
  call initwin

  call soamfreeall
  
  call init_mode_play

  ; draw first frame
  call vblank 

  ; enable lcd
  call lcdon 

  ; init display regs
  ld a, 0b11100100
  ld [RBGP], a

  ld a, 0b11100100 
  ld [ROBP0], a

  ld a, 0b11011000
  ld [ROBP1], a

  call vblankwait

  ; enable interrupts 
  ld a, IVBLANK
  ld [IE], a
  ei  

  ; set flag for first frame to go ahead 
  ld a, 0
  ld [update_flags], a

main:
@forever:
  ld a, [update_flags]
  cp a, 0
  ; do not run the next update until the current vblank is cleared 
  jp nz, @forever 
  
  call update

  ; mark frame as finished 
  ld a, 1
  ld [update_flags], a
  jp @forever 

#include "update.s"

#include "video.s"
#include "sys.s"
#include "mem.s"

#include "act.s"

#include "tiles.inc"
#include "tilemaps.inc"
#include "mode.s"

; fill bank
.fill 0, 0x7FFF - $
