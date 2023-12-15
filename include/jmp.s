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
  call vblank 
  reti
