
oamclear:
  ld a, 0
  ld b, 160
  ld hl, OAMRAM
@loop:
  ld [hl+], a
  dec b
  jp nz, @loop
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
  ld d, a
@next:
  ld a, d
  ld [hl+], a
  dec bc
  ld a, b
  or a, c
  jp nz, @next
  ret 
