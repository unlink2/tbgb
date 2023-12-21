#include "hw.inc"
#include "macros.inc"
#include "act.inc"
#include "wram.inc"
#include "sram.inc"
#include "oam.inc"

.org 0x0
#include "jmp.inc"
.fill 0, 0x100 - $
#include "header.inc"
 
entry:
  call disableinterrutpts

  ; wait for first vblank
  call vblankwait
  
  ; initially disable lcd 
  call lcdoff
  
  call initmem 
  call inittiles

  call initwin

  call transition_clear
  call init_mode_title

  ; draw first frame
  call vblank 

  ; enable lcd
  call lcdon 
  call initdisplay
  
  call enableinterrupts

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
#include "mode.s"

#include "strs.inc"
#include "tiles.inc"
#include "tilemaps.inc"

; fill bank
.fill 0, 0x7FFF - $
