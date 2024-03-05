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

; pop hl and push it again!
; add offset to hl
; registers:
;   hl: modified
;   sp: pop hl and push hl
;   de: used to add to hl
; inputs: 
;   $1: the offset into hl
#macro ldhlm
  pop hl
  push hl
  ld de, $1
  add hl, de
#endmacro

; relative jump: jr <label> RELB 
#define REL - $ - 2 & 0xFF 
