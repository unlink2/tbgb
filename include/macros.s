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

