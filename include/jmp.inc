; RST $00
; panic exception handler 
rst_panic:
  di
@forever:
  call panic
  jp @forever
  

.fill 0, 0x40 - $ 

; interrupt vectors

;=============
; vblank 0x40
;=============
vec_vblank:
  push af
  push bc
  push de
  push hl

  call vblank

  pop hl
  pop de
  pop bc
  pop af

  reti
