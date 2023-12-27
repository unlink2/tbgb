; this file sets up the different game modes
; the init_mode functions will clear all memory and then 
; init the apropriate feature 
; the first mode that is normall loaded is title
; note: the lcd should be turned off before calling any init 
; becuase they will likely clear oam, soam and other related data

transition_clear:
  call oamclear
  call actfreeall
  call clearscrn0 
  ret

; call to transition mode
; waits for vblank
; disables lcd
; disable interrupts
; clears oam
; clear actors
; TODO: clears vram
; inputs:
;   hl: jp target for transition
transition:
  push hl

  call disableinterrutpts
  call vblankwait 
  call lcdoff

  call transition_clear  

  pop hl
  call callhl

  call lcdon
  call enableinterrupts 
  ret

init_mode_title:
  call title_cursor_init

  ; initial game mode
  ld a, MODE_TITLE 
  ld [game_mode], a

  ret

init_mode_editor:
  ; initial game mode
  ld a, MODE_EDITOR 
  ld [game_mode], a
  ret

init_mode_play:
  ; init player 
  call player_init

  ; initial game mode
  ld a, MODE_PLAY 
  ld [game_mode], a

  ; load a map
  ld de, testmap
  call mapload 

  ; draw map 
  call mapfulldraw

  ret
