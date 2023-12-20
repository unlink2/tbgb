; this file sets up the different game modes
; the init_mode functions will clear all memory and then 
; init the apropriate feature 
; the first mode that is normall loaded is title
; note: the lcd should be turned off before calling any init 
; becuase they will likely clear oam, soam and other related data

init_mode_title:
  call oamclear 
  call actfreeall
  
  call title_cursor_init

  ; initial game mode
  ld a, MODE_TITLE 
  ld [game_mode], a
  ret

init_mode_editor:
  call oamclear 
  call actfreeall

  ; initial game mode
  ld a, MODE_EDITOR 
  ld [game_mode], a
  ret

init_mode_play:
  call oamclear 
  call actfreeall
  
  ; init player 
  call player_init


  ; initial game mode
  ld a, MODE_PLAY 
  ld [game_mode], a
  ret
