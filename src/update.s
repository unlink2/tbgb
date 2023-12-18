
update:
  ; first free all soam entries 
  call soamfreeall
@update_act:
  ld bc, ACTSIZE
  ld hl, acttbl
  ld d, 0 ; loop counter 
@next:
  ld a, [hl]
  and a, ACT_FACTIVE
  jp z, @skip

    ; if found, store hl 
    ; bc and d for later 
    ; FIXME: surely we can do better here 
    push hl
    push bc
    push de
    
    ; pop hl into de because the actors expect
    ; the actor ptr to be in de initially
    push hl
    pop de

    ; jump to the function 
    ld bc, actfn 
    add hl, bc ; hl points to fn pointer now...
    call player_update
    ; FIXME: this calls weird locations sometimes...
    ; call callptr

    pop de
    pop bc
    pop hl
@skip:
  
  ; go to next actor
  add hl, bc
  ; inc loop counter 
  inc d 
  ld a, d
  cp a, ACTMAX
  jr nz, @next REL

  ret
