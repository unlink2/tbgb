#include "hw.s"
#include "macros.s"

#include "wram.s"

.org 0x0
.fill 0, 0x100
#include "header.s"
 
entry:
  ; wait for first vblank
  call vblankwait
  
  ; initially disable lcd 
  call lcdoff
  
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

main:
@forever:
  call vblankwait
  call input 
  call update

  jp @forever 

input:
  ld a, P1FDPAD
  call pollp1
  swap a
  ld b, a

  ld a, P1FBTN 
  call pollp1
  or a, b

  ld [inputs], a

  ; release P1F
  ld a, P1FNONE 
  ldh [RP1], a

; inputs:
;   a: P1 key matrix flag 
; returns
;   a: A7-4 -> inputs
pollp1:
  ld [RP1], a
  ; wait for values to become stable 
  call @wastecycles
  ldh a, [RP1]
  ldh a, [RP1]
  ldh a, [RP1] ; last read counts
  and a, 0x0F
  ret 
@wastecycles:
  ret

update:
  ld a, [inputs]
  and a, BTNLEFT 
  jp nz, @notleft
  ; left input hit
    ld a, [OAMRAM + 1]
    dec a
    ld [OAMRAM + 1], a
@notleft:
  
  ld a, [inputs]
  and a, BTNRIGHT
  jp nz, @notright
  ; right input hit
    ld a, [OAMRAM + 1]
    inc a
    ld [OAMRAM + 1], a
@notright:
  
  ld a, [inputs]
  and a, BTNUP
  jp nz, @notup
  ; up input hit 
    ld a, [OAMRAM]
    dec a
    ld [OAMRAM], a
@notup:
  
  ld a, [inputs]
  and a, BTNDOWN 
  jp nz, @notdown 
  ; down input hit 
    ld a, [OAMRAM]
    inc a
    ld [OAMRAM], a
@notdown:
  ret

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
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
  ld [RLCD], a
  
  ; init display regs
  ld a, 0b11100100
  ld [RBGP], a

  ld a, 0b11100100 
  ld [ROBP0], a
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

#include "tiles.s"
#include "tilemaps.s"

; fill bank
.fill 0, 0x7FFF - $
