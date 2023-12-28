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
  ld a, [game_mode]
  cp a, MODE_TITLE 
  call z, draw_mode_title
  cp a, MODE_PLAY
  call z, draw_mode_play
  cp a, MODE_PAUSE
  call z, draw_mode_pause 
  cp a, MODE_EDITOR 
  call z, draw_mode_editor

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
  
  ; draw tile offset for player 
  ldhlfrom actpl
  push hl
  ldhlm acty 
  ld a, [hl]
  ld b, a
  ldhlm actx 
  ld a, [hl]
  ld c, a
  pop hl
  call actpostotilepos

  push hl ; need again in a bit
  ld a, h
  ld hl, SCRN0+6 
  call dbghex

  pop hl
  ld a, l
  ld hl, SCRN0+8
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

