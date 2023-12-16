; actor update functions:
;   all actor update functions expect the actor ptr to be located in 
;   the de register initially


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

; allocate shadow oam
; and copies data to soam
; registers:
;   hl, af, bc, de
acttosoam:
  ld hl, acttbl 
  ld bc, ACTSIZE 
  ld d, ACTMAX 
  ld e, OBJSMAX
  
@next:
    ; read flags 
    ld a, acttbl 
    ; if not active, leave it be 
    and a, ACT_FACTIVE 
    jr z, @skip REL

    
@skip:
    add hl, bc
    dec d
    jr nz, @next REL

  ret 

; dam shadow oam to oam
; registers:
;   hl, af, bc, de
; TODO: for now we just memcpy, but we should really dma soon
soamtooam:
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
  ret
