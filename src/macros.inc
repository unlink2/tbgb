#define NULL 0

#macro dw 
.db $1 & 0xFF
.db ($1 >> 8) & 0xFF 
#endmacro

; panic if the hl register is NULL (0)
#macro hl_null_panic 
  ld a, h
  or a, l
  cp a, NULL
  jp z, rst_panic
#endmacro

; store pointer at hl and hl+1
; inputs:
;   $1 = pointer address
; registers:
;   a is overwritten
;   hl is overwritten
#macro ldhlptr
  ld a, $1 & 0xFF
  ld [hl+], a
  ld a, ($1 >> 8) & 0xFF
  ld [hl+], a
#endmacro 

; relative jump: jr <label> RELB 
#define REL - $ - 2 & 0xFF 
