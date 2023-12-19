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
  
  ; call scroll

  ; reset update flags
  ld a, 0
  ld [update_flags], a


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

draw:
  call OAMDMAFN

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

; initialize window registers 
initwin:
  ld a, 0
  ld [RWY], a

  ld a, 10
  ld [RWX], a
  ret

; scroll the screen 
scroll:
  ; hl = player actor 
  ldhlfrom actpl 
  push hl

  ld bc, acty
  add hl, bc
  
  ; y position 
  ld a, [hl]
  ld [RSCY], a
  
  pop hl
  ld bc, actx 
  add hl, bc

  ; x position 
  ld a, [hl]
  ld [RSCX], a

  ret 
