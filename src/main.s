#include "hw.s"
#include "macros.s"

#include "wram.s"
#include "oam.s"

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
  ld de, acts0
  ld hl, VRAM
  ld bc, acts0_end - acts0 
  call memcpy

  ; copy tilemap 0
  ld de, tilemap0
  ld hl, SCRN0 
  ld bc, tilemap0_end - tilemap0
  call memcpy
  
  call soamfreeall
  call oamload_test 

  ; init player 
  call player_init

  ; draw first frame
  call vblank 

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

update:
  
@update_act:
  ld bc, ACTSIZE
  ld hl, acttbl
  ld d, 0 ; loop counter 
@next:
  ld a, [hl]
  and a, ACT_FACTIVE
  jp z, @skip

    ; if found, store hl 
    ; bc and d for later 
    ; FIXME: surely we can do better here 
    push hl
    push bc
    push de
    
    ; pop hl into de because the actors expect
    ; the actor ptr to be in de initially
    push hl
    pop de

    ; jump to the function 
    ld bc, actfn 
    add hl, bc ; hl points to fn pointer now...
    call callptr

    pop de
    pop bc
    pop hl
@skip:
  
  ; go to next actor
  add hl, bc
  ; inc loop counter 
  inc d 
  ld a, d
  cp a, ACTMAX
  jr nz, @next REL

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

  call soamtooam
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

; call address in hl
; inputs:
;   hl: pointing to function pointer we want to call
; registers:
;   hl, a, b
callptr:
  ; load pointer into hl
  ld a, [hl+]
  ld b, a
  ld a, [hl]
  ld h, a
  ld l, b
  jp hl

draw:
  ; TODO: improve copying to oam 
  ld a, [acttbl + actx]
  ld [OAMRAM + oamx], a

  ld a, [acttbl + acty]
  ld [OAMRAM + oamy], a

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
;   a, b, hl, de
memset:
  ld b, a
@next:
  ld a, b
  ld [hl+], a
  dec bc
  ld a, b
  or a, c
  jp nz, @next
  ret 
; actor update functions:
;   all actor update functions expect the actor ptr to be located in 
;   the de register initially

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

panic:
  ret

#include "act.s"

#include "tiles.s"
#include "tilemaps.s"

; lookup table for obj idex to oam address 
soamidxlut: 
.db 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56 
.db 60, 64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116 
.db 120, 124, 128, 132, 136, 140, 144, 148, 152, 156 

; fill bank
.fill 0, 0x7FFF - $
