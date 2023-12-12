#include "hw.s"

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
  
  ; copy oam data 
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
  ; store old inputs 
  ld a, inputs 
  ld prev_inputs, a
  
  ld a, P1FDPAD   
  call @input_readhalf 
  ; store in b for now...
  ld b, a
    
  ld a, P1FBTN 
  call @input_readhalf
  sawp a ; move to lower 4 bits 
  
  ; release P1F
  ld a, P1FNONE 
  ldh [RP1], a

  xor a, b
  ld inputs, a 

; returns
;   a: A7-4 -> inputs
@input_readhalf:
  ld [RP1], a
  ; wait for values to become stable 
  call @wastecycles
  ldh a, [RP1]
  ldh a, [RP1]
  ldh a, [RP1] ; last read counts

  or a, 0xF0 ; A7-4 -> keys
  ret 
@wastecycles:
  ret

update:
  ld a, [OAMRAM + 1]
  inc a
  ld [OAMRAM + 1], a

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
  ld a, 0
  ld [hl+], a
  ld a, 0
  ld [hl], a
  ret

#include "tiles.s"
#include "tilemaps.s"

; fill bank
.fill 0, 0x7FFF - $
