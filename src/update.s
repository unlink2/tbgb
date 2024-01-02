update:
  ; frame timing stuff
  ld hl, frame
  inc [hl]

  ; set animation timer 
  ld a, [frame]
  and a, 32
  jr z, @anim_zero REL
  ld a, 1
  jr @anim_done REL
@anim_zero:
  ld a, 0
@anim_done:
  ld [global_anim_timer], a

  ; delay timer 
  ld a, [global_delay]
  cp a, 0
  jr z, @no_global_delay_dec REL
  dec a
  ld [global_delay], a
@no_global_delay_dec:

  ; shadow oam offset
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
  
  ; update the active actor only 
  call actupdate
  call actdraw 

  ret

update_mode_title:
  ret

update_mode_play:
  ret

update_mode_pause:
  ret

update_mode_editor:
  ret
