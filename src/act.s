; actor update functions:
;   all actor update functions expect the actor ptr to be located in 
;   the de register initially

; actors and oam:
; actors keep all their data in the actor table 
; once a frame actors attempt to allocate 
; shadow oam objects for themselves 
; in a first come first serve principal 
; the only exception is that the player 
; will always be allocated first 
; and then all remaining actors can decide to allocate objs in their init
; code based on their needs, again first come first serve
; when using the allocated object, the global offset (soamgoffset) should 
; be taken into account to ensure sprite flickering is working as intended
; if an object cannot allocated enough objs it should fail to init and be 
; dropped

; attempts to allocate an actor 
; from the actor table 
; inputs:
;   none
; registers: hl, bc, d, a
; returns:
;   hl: pointer to allocated actor
;   hl: NULL if no actor is found 
act_alloc:
  ; point to the first free actor's flags
  ld hl, acttbl
  ld bc, ACTSIZE
  ld d, 0 ; loop counter 
@seeknext:
  ld a, [hl]
  ; if not active, set active and return
  and a, ACT_FACTIVE 
  jp z, @found
 
    ; go to next act 
    add hl, bc
    ; inc counter 
    inc d
    ld d, a
    ; are we at end?
    cp a, ACTMAX
    jp nz, @seeknext
    
    ; return NULL
    ld hl, NULL
    ret
@found:
  ld a, ACT_FACTIVE 
  ld [hl], a
  ret

; dam shadow oam to oam
; registers:
;   hl, af, bc, de
; TODO: for now we just memcpy, but we should really dma soon
soamtooam:
  ; FIXME: dma is broken rn 
  ld a, soam >> 8  
  ldh [DMA], a
  ld a, 40 ; 160-cycle wait 
@wait:
  dec a
  jr nz, @wait REL
  ret 
soamtooam_end:

; clear the soam arena 
; same as memset
soamfreeall:
  ld a, 0
  ld hl, soamallocflags
  ld bc, OBJSMAX
  jp memset 

; obtain the soam address from an offset.
; it also takes the global oam offset into account 
; inputs:
;   a: soam index
; returns:
;   hl: the resulting pointer to soam
; registers:
;   bc, hl, a
soamaddr:
  ;add a, soamgoffset 
  ;and a, 0b10111 ; this mask will limit it to 0-39

  ;set up dst
  ; a contains index to first free object 
  ; we need the address offset 
  ld hl, soamidxlut 
  ld b, 0
  ld c, a
  add hl, bc ; lut + offset = location in lut 
  ld a, [hl]

  ld hl, soam 
  ld b, 0
  ld c, a
  add hl, bc ; soam + offset = actual offset in hl now 
  ret

; allocate the next free object 
; inputs:
;   a: prefered index. this index is checked first 
;      and is returned if available
; returns:
;   a: index to first free object or 0xFF if not found
; registers:
;   
soamalloc:
  ; check requested index first 
  ld b, a
  ld c, 0
  ld d, a ; store requested index in d in case we find obj
  ld hl, soamallocflags 
  add hl, bc ; hl + bc = requested alloc flag 
  ld a, [hl]
  and a, SOAM_FACTIVE 
  jr z, @found REL 

  ; check all other objects now 
  ld hl, soamallocflags 
  ld d, 0 ; loop counter/obj index  
@next: 
    ; check if obj is free 
    ld a, [hl]
    and a, SOAM_FACTIVE 
    jr z, @found REL

    ; go to next 
    inc d
    inc hl
    ld a, d
    cp a, OBJSMAX ; check if all objecs have been used 
    
    jr nz, @next REL
  ld a, SOAM_EINVAL
  ret
@found:
  ld a, SOAM_FACTIVE
  ld [hl], a ; set active 
  ld a, d ; return index 
  ret

; init player with the first free 
; actor found  
player_init:
  call act_alloc
  hl_null_panic
  
  ; save pointer to player 
  ; for later use 
  ld a, l
  ld [actpl], a
  ld a, h
  ld [actpl+1], a
  
  ; now init player data 
  inc hl ; no need for flags 

  ; player object is always 0
  ld a, 0
  ld [hl+], a
  
  ; type is player 
  ld a, ACT_TPLAYER
  ld [hl+], a

  ; ld fn pointer 
  ldhlptr player_update 
  
  ; ignore unused byte for now...
  inc hl 

  ; xl 
  ld a, 0
  ld [hl+], a
  
  ; yl
  ld [hl+], a

  ; TODO: set proper initial location
  ld a, 64
  ld [hl+], a ; x pos 
  ld [hl+], a ; y pos
  
  ; TODO: set sprite 
  ld a, 1
  ld [hl+], a 
  
  ; oam flags
  ld a, 0
  ld [hl+], a

  ret

;
; update player function
; 
player_update:
  ; move actor ptr to hl
  push de 
  pop hl
  push hl ; we need base hl again later 
  
  ; set hl to actx ptr
  ld de, actx 
  add hl, de

  ; TODO: improve player handling
  ; by using hl as object ptr
  ld a, [inputs]
  and a, BTNLEFT 
  jr z, @notleft REL
  ; left input hit
    ld a, [hl] 
    dec a
    ld [hl], a
@notleft:
  
  ld a, [inputs]
  and a, BTNRIGHT
  jr z, @notright REL
  ; right input hit
    ld a, [hl]
    inc a
    ld [hl], a
@notright:
 
  ;set hl to acty ptr
  pop hl
  push hl
  ld de, acty 
  add hl, de

  ld a, [inputs]
  and a, BTNUP
  jr z, @notup REL
  ; up input hit 
    ld a, [hl]
    dec a
    ld [hl], a
@notup:
  
  ld a, [inputs]
  and a, BTNDOWN 
  jr z, @notdown REL
  ; down input hit 
    ld a, [hl]
    inc a
    ld [hl], a
@notdown:

  ; now move to oam
  ld a, 0
  call soamalloc 
  cp a, SOAM_EINVAL 
  jr z, @soaminval REL

  ; set up src
  pop de
  ld hl, acty 
  add hl, de
  push hl
  pop de

  call soamaddr 

  ; length 
  ld bc, SOAMSIZE 
  call memcpy

@soaminval:

  ret
