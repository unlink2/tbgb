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

; store pointer
; inputs:
;   $1 = pointer address
#macro ldhlptr
  ld a, $1 & 0xFF
  ld [hl+], a
  ld a, ($1 >> 8) & 0xFF
  ld [hl+], a
#endmacro 

; load ptr into hl  from $1
#macro ldhlfrom
  ld a, [$1]
  ld l, a
  ld a, [$1+1]
  ld h, a
#endmacro 

; store ptr from hl at $1
#macro ldhlto
  ld a, l
  ld [actpl], a
  ld a, h
  ld [actpl+1], a
#endmacro

; relative jump: jr <label> RELB 
#define REL - $ - 2 & 0xFF 
