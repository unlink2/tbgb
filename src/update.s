update:
  ld hl, soamgoffset 
  inc [hl]
  
  ; general game update
  ; FIXME: make a jump talbe out of this 
  ld a, [game_mode]
  cp a, MODE_TITLE 
  call z, update_mode_title 
  
  cp a, MODE_PLAY 
  call z, update_mode_play 
  
  cp a, MODE_PAUSE
  call z, update_mode_pause 

  cp a, MODE_EDITOR 
  call z, update_mode_editor
  

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
    ;call player_update
    call callptr

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

update_mode_title:
  ret

update_mode_play:
  ret

update_mode_pause:
  ret

update_mode_editor:
  ret
