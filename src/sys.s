nohandler:
  ret

panic:
  ret

enableinterrupts:
  ; enable interrupts 
  ld a, IVBLANK
  ld [IE], a
  ei 
  ret

disableinterrutpts:
  ld a, 0
  ld [IE], a
  di
  ret 

; call address in hl
; inputs:
;   hl: pointing to function pointer we want to call
; registers:
;   hl, a, b
callptr:
  ; load pointer into hl
  ld a, [hl+]
  ld b, a
  ld a, [hl]
  ld h, a
  ld l, b
  jp hl

; calls hl directly 
; inputs:
;   hl: the address to "call"
callhl:
  jp hl

; poll inputs
; returns:
;   new inputs in [input]
;   previous inputs in [prev_inputs]
; registers:
;   a, b, c, d
input:
  ld a, [inputs]
  ld [prev_inputs], a

  ld a, P1FDPAD
  call pollp1
  swap a
  ld b, a
  
  ld a, P1FBTN 
  call pollp1 
  or a, b
   
  
  ld [inputs], a
  ld a, b

  ret 

; sets the global delay timer 
; inputs:
;   a: delay timer to set to 
setdelay:
  ld [global_delay], a
  ret
  


; poll p1 
; inputs:
;   a: P1 key matrix flag 
; returns
;   a: A0-3 -> inputs
; registers:
;   a, d
pollp1:
  ld [RP1], a
  ; wait for values to become stable 
  ldh a, [RP1]
  ldh a, [RP1]
  ldh a, [RP1]
  ldh a, [RP1]
  ldh a, [RP1]
  ldh a, [RP1] ; last read counts
  xor a, 0x0F
  and a, 0x0F

  ld d, a
  ; reset P1F
  ld a, P1FNONE 
  ldh [RP1], a
  ld a, d

  ret 
  

; actor update functions:
;   all actor update functions expect the actor ptr to be located in 
;   the de register initially


; lookup table for obj idex to oam address 
soamidxlut: 
.db 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56 
.db 60, 64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116 
.db 120, 124, 128, 132, 136, 140, 144, 148, 152, 156 
