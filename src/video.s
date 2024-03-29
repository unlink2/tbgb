vblank:  
  ; skip the frame if the previous
  ; frame did not finish 
  ld a, [update_flags]
  and a, 1
  ret z

  call input

  call draw
  call applyscroll

  ; reset update flags
  ld a, 0
  ld [update_flags], a

  ret

; initialize display registers such
; as palettes 
initdisplay:
  ; init display regs
  ld a, 0b11100100
  ld [RBGP], a

  ld a, 0b11100100 
  ld [ROBP0], a

  ld a, 0b11011000
  ld [ROBP1], a
  ret

vblankwait:
  ld a, [RLY]
  cp a, 144
  jp c, vblankwait 
  ret

lcdon:
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON ; | LCDF_WINDOWON
  ld [RLCD], a 
  ret

lcdoff:
  ld a, 0
  ld [RLCD], a
  ret

draw:
  call OAMDMAFN
  
  ; game mode specific draws 
  ; FIXME: make a jump talbe out of this 
  ld a, [game_mode]
  cp a, MODE_TITLE 
  call z, draw_mode_title
  cp a, MODE_PLAY
  call z, draw_mode_play
  cp a, MODE_PAUSE
  call z, draw_mode_pause 
  cp a, MODE_EDITOR 
  call z, draw_mode_editor

  ; now clear shadow oam
  call soam_memclear

  ret

draw_mode_play:
  ; draw current frame to top left corner
  ld a, [frame]
  ld hl, SCRN0
  call dbghex 
  
  ; draw inputs 
  ld a, [inputs]
  ld hl, SCRN0+3
  call dbghex

  ; draw tile index for actor 0
  ld hl, acttbl 
  ld bc, acty 
  add hl, bc 
  ld a, [hl+]
  ld b, a
  ld a, [hl]
  ld c, a
  call tileflagsat 
  ld hl, SCRN0+6
  call dbghex 

  ret 

draw_mode_title:

  ; draw test tile 
  ld a, [inputs]
  ld hl, SCRN0 + 192
  call dbghex

  ret

draw_mode_pause:
  ret

draw_mode_editor:
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

; prints a 0-terminated string to the screen
; inputs:
;   bc: screen address
;   de: string ptr 
puts:
@putchr:
  ld hl, 0
  add hl, de
  ld a, [hl]

  ; is null terminaor?
  cp a, 0
  jr z, @end REL
  
  ld hl, 0
  add hl, bc
  
  ld [hl], a

  ; next addresses 
  inc de
  inc bc 

  jr @putchr REL

@end:
  ret

; initialize window registers 
initwin:
  ld a, 144 - 8
  ld [RWY], a

  ld a, 8
  ld [RWX], a
  ret

; scroll the screen 
applyscroll:
  ; y position 
  ld a, [scrolly]
  ldh [RSCY], a

  ; x position 
  ld a, [scrollx]
  ldh [RSCX], a

  ret 

; pushes a new instruction to 
; the draw stack 
; inputs:
;   bc: vram address
;   a:  tile value
draw_update_buf_push:
  push af
  ld hl, vram_update_buf
  ld d, 0
  ld a, [vram_update_idx]
  ld e, a
  add hl, de ; hl = current buf offset 
  pop af
  


  ret

; draw changes from the update stack 
; directly to vram
draw_update_buf:
  ; draw until a == vram_update_idx 
  
@done:
  ; lastly clear draw stack 
  xor a, a
  ld [vram_update_idx], a
  ret
