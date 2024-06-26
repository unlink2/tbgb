; set up wram and sram
; and clear all values that need clearing
initmem:
  ; init sram 
  ld a, 0x0A
  ld [SRAM_ENABLE], a

  ; clear wram
  ld a, 0
  ld hl, WRAM
  ld bc, WRAMLEN
  call memset

  ; clear oam 
  call oamclear

  ; memcpy oam dma fn 
  ld de, soamtooam 
  ld hl, OAMDMAFN
  ld bc, soamtooam_end - soamtooam
  call memcpy
  call soamfreeall
  ret

clearscrn0:
  ld a, EMPTY_TILE
  ld hl, SCRN0 
  ld bc, 1024 
  call memset
  ret

oamclear:
  ; clear oam
  ld a, 0
  ld bc, 160
  ld hl, OAMRAM
  call memset

  ; same for soam 
  ld a, 0
  ld bc, 160
  ld hl, soam 
  call memset
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

; clear soam in an unrolled loop
; inputs:
;  hl: dst 
;  bc: length
; registers:
;   a, b, hl, de
soam_memclear:
  xor a, a
  ld hl, soam 

.rep i, OBJSMAX * 4, 1, ld [hl+], a 

  ret
