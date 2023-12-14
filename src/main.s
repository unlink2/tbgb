#include "hw.s"
#include "macros.s"

#include "wram.s"

.org 0x0
#include "jmp.s"
.fill 0, 0x100 - $
#include "header.s"
 
entry:
  ; wait for first vblank
  call vblankwait
  
  ; initially disable lcd 
  call lcdoff

  ; clear wram
  ld a, 0
  ld hl, WRAM
  ld bc, WRAMLEN
  call memset 

  ; clear oam 
  call oamclear

  ; copy tiles 0
  ld de, tiles0
  ld hl, VRAM9000
  ld bc, tiles0_end - tiles0
  call memcpy
  
  ; copy oam tile data 
  ld de, tiles0
  ld hl, VRAM
  ld bc, tiles0_end - tiles0
  call memcpy

  ; copy tilemap 0
  ld de, tilemap0
  ld hl, SCRN0 
  ld bc, tilemap0_end - tilemap0
  call memcpy

  call oamload_test 

  ; enable lcd
  call lcdon 

  ; init display regs
  ld a, 0b11100100
  ld [RBGP], a

  ld a, 0b11100100 
  ld [ROBP0], a

  call vblankwait

  ; enable interrupts 
  ld a, IVBLANK
  ld [IE], a
  ei 
  
  ; clear first frame
  ld a, 0
  ld [update_flags], a

main:
@forever:
  ld a, [update_flags]
  ; do not run the next update until the current vblank is cleared 
  jp nz, @forever 
  
  call update

  ; mark frame as finished 
  ld a, 1
  ld [update_flags], a
  jp @forever 

update:
  ret

vblank:
  ld hl, frame
  inc [hl]

  ; skip the frame if the previous
  ; frame did not finish 
  ld a, [update_flags]
  and a, 1
  ret z

  call input 
  call draw

  ; reset update flags
  ld a, 0
  ld [update_flags], a
  ret

; poll inputs
; returns:
;   new inputs in [input]
;   previous inputs in [prev_inputs]
; registers:
;   a, b, c, d
input:
  ld a, [inputs]
  ld [prev_inputs], a

  ld a, P1FDPAD
  call pollp1
  swap a
  ld b, a
  
  ld a, P1FBTN 
  call pollp1 
  or a, b
   
  
  ld [inputs], a
  ld a, b

  ret 
; poll p1 
; inputs:
;   a: P1 key matrix flag 
; returns
;   a: A0-3 -> inputs
; registers:
;   a, d
pollp1:
  ld [RP1], a
  ; wait for values to become stable 
  ldh a, [RP1]
  ldh a, [RP1]
  ldh a, [RP1]
  ldh a, [RP1]
  ldh a, [RP1]
  ldh a, [RP1] ; last read counts
  xor a, 0x0F
  and a, 0x0F

  ld d, a
  ; reset P1F
  ld a, P1FNONE 
  ldh [RP1], a
  ld a, d

  ret 

draw:
  ld a, [inputs]
  and a, BTNLEFT 
  jp z, @notleft
  ; left input hit
    ld a, [OAMRAM + 1]
    dec a
    ld [OAMRAM + 1], a
@notleft:
  
  ld a, [inputs]
  and a, BTNRIGHT
  jp z, @notright
  ; right input hit
    ld a, [OAMRAM + 1]
    inc a
    ld [OAMRAM + 1], a
@notright:
  
  ld a, [inputs]
  and a, BTNUP
  jp z, @notup
  ; up input hit 
    ld a, [OAMRAM]
    dec a
    ld [OAMRAM], a
@notup:
  
  ld a, [inputs]
  and a, BTNDOWN 
  jp z, @notdown 
  ; down input hit 
    ld a, [OAMRAM]
    inc a
    ld [OAMRAM], a
@notdown:

  ; draw current frame to top left corner
  ld a, [frame]
  ld hl, SCRN0
  call dbghex 
  
  ; draw inputs 
  ld a, [inputs]
  ld hl, SCRN0+3
  call dbghex

  ret

; draw a hex number to screen 
; inputs:
;   a: the number 
;   hl: screen address
; registers: a, b, hl
dbghex:
  ld b, a

  ld a, b
  swap a
  and a, 0x0F
  ld [hl+], a
  
  ld a, b
  and a, 0x0F 
  ld [hl+], a

  ret
  

; memcpy:
; inputs: 
;   hl: dst
;   de: src
;   bc: len
; registers:
;   a, bc, hl, de
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

; memset
; inputs:
;  a:  value
;  hl: dst 
;  bc: length
; registers:
;   a, hl, de
memset:
@next:
  ld [hl+], a
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
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
  ld [RLCD], a 
  ret

lcdoff:
  ld a, 0
  ld [RLCD], a
  ret

oamclear:
  ld a, 0
  ld b, 160
  ld hl, OAMRAM
@loop:
  ld [hl+], a
  dec b
  jp nz, @loop
  ret

oamload_test:
  ld hl, OAMRAM
  ld a, 100 + 16
  ld [hl+], a
  ld a, 10 + 8
  ld [hl+], a
  ld a, 1
  ld [hl+], a
  ld a, 0
  ld [hl], a
  ret

nohandler:
  ret

#include "act.s"

#include "tiles.s"
#include "tilemaps.s"

; fill bank
.fill 0, 0x7FFF - $
