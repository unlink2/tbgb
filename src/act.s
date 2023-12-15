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
  ret
