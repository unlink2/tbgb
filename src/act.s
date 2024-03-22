; actor update functions:
;   all actor update functions expect the actor ptr to be located in 
;   the de register initially

; actor state functions:
;   all actor state functions expect the actor ptr to be located in 
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


; loop all actors and update them
; if an actor is not marked as active it will 
; simply be skipped. Otherwise its current statefn is called 
actupdate:
  ; free all soam entries
  call soamfreeall

  ld bc, ACTSIZE
  ld hl, acttbl
  ld d, 0 ; loop counter 
@next:
  ld a, [hl]
  and a, ACT_FACTIVE
  jr z, @skip REL

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
    ld bc, actstatefn
    add hl, bc ; hl points to fn pointer now...
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


; dam shadow oam to oam
; registers:
;   hl, af, bc, de
; TODO: for now we just memcpy, but we should really dma soon
soamtooam:
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
  ; TODO handle global offset here
  ld a, 0
  ld [soamnext], a
  ret

actfreeall:
  ld a, 0
  ld hl, acttbl 
  ld bc, ACTMAX * ACTSIZE
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
;      and is returned if available. if preferred index is FF it is ignored 
; returns:
;   a: index to first free object or 0xFF if not found
; registers:
;   
soamalloc:
  cp a, 0xFF
  ret z

  ld a, [soamnext]
  cp a, OBJSMAX
  jr nz, @not_max REL

  ld a, 0xFF
  ret 
@not_max:
  
  inc a
  ld [soamnext], a
  dec a
  ret

; default init for all actors
; inputs:
;   hl: act ptr
act_init:
  push hl
  
  pop hl
  ret

; init player with the first free 
; actor found  
player_init:
  call act_alloc
  hl_null_panic
  
  call act_init

  push hl
  
  ; now init player data 
  
  ; type is player 
  pop hl
  push hl
  ld de, acttype 
  add hl, de

  ld a, ACT_TPLAYER
  ld [hl], a
  
  ; ignore unused byte for now...

  ; TODO: set proper initial location
  ld a, 0x39
  pop hl
  push hl
  ld de, acty
  add hl, de
  ld [hl], a ; x pos


  pop hl
  push hl
  ld de, actx
  add hl, de
  ld [hl], a ; y pos

  pop hl
  push hl
  ld bc, player_state_update
  ; transition player to state 0
  call actstate_to

  pop hl
  ld de, actcollision
  add hl, de
  ld bc, player_collision
  ld a, c
  ld [hl+], a
  ld a, b
  ld [hl], a

  ret

; allocate an oam object 
; and copy values into it 
; inputs:
;   a: prefered oam index. if index is FF it is ignored
;   b, c: y, x
;   d, e: tile, flags
soamsetto:
  push bc
  push de
  ; now move to oam
  ld a, 0
  call soamalloc 
  cp a, SOAM_EINVAL 
  jr z, @soaminval REL
  
  call soamaddr 

  pop de
  pop bc

  ld a, b
  ld [hl+], a ; x
  ld a, c 
  ld [hl+], a ; y
  ld a, d
  ld [hl+], a ; chr 
  ld a, e
  ld [hl+], a ; flags

  ret
@soaminval:
  pop de
  pop bc
  ret

; nop actor state 
actstate_nop:
  push de 
  pop hl 

  ret 


; transition actor to any state
; inputs:
;   hl: actor ptr 
;   bc: next state 
actstate_to:
  ld de, actstatefn 
  add hl, de
  
  ld a, c
  ld [hl+], a

  ld a, b
  ld [hl], a
  ret 


player_state_update:
  call player_substate_input
  ; call player_substate_gravity
  call player_act_substate_move
  call player_draw
  ret

; process a single player input
; inputs:
;   f: zero or not zero for input
;   hl: pointing to velocity byte
;    b: bit mask to set or reset 
;       in [player_movement_dirs] 
;       if movement occurs 
; returns:
;   hl+1
player_substate_input_proc:
  jr z, @not REL

  ; load max velocity for now  
  ld a, 0xFF  
  ld [hl+], a ; hl = ys down

  ; set direction bit
  ld a, [player_movement_dirs]
  or a, b
  ld [player_movement_dirs], a
  jr @done REL
@not:
  ld a, 0
  ld [hl+], a ; hl = ys down

  ; clear direction bit
  ld a, b
  cpl 
  ld b, a
  ld a, [player_movement_dirs] 
  and a, b
  ld [player_movement_dirs], a
@done:
  ret 

player_substate_gravity:
  push de
  
  ; for now just use constat gravity
  ld a, 0x7F
  ld [player_velocity_ys_down], a

  pop de
  ret

; read player input
; and transition to input handling state 
; for the next frame
; transitions to:
;   act_state_move if dpad is pressed
; inputs:
;   de: actor ptr 
player_substate_input:
  push de
  
  ld hl, player_velocity_ys_up  ; hl now points at ys up 

  ; up input
  ld a, [inputs]
  and a, BTNUP
  ld b, DIR_UP
  call player_substate_input_proc 
  
  ; down input
  ld a, [inputs]
  and a, BTNDOWN
  ld b, DIR_DOWN
  call player_substate_input_proc

  ; left input
  ld a, [inputs]
  and a, BTNLEFT
  ld b, DIR_LEFT
  call player_substate_input_proc
  
  ; right input 
  ld a, [inputs]
  and a, BTNRIGHT
  ld b, DIR_RIGHT
  call player_substate_input_proc

  ; pop act address into de 
  pop de

  ret 

; move current actor in a specific direction
; by substracting 
; inputs:
;   hl: points to x or y of actor 
;   de: points to xs or ys of actor
;   a: velocity 
; returns:
;   hl is preserved 
player_substate_move_sub:
  push hl
  
  ld hl, 0 ; hl = xs or ys
  add hl, de
  ; y up movement
  ld b, a
  ld a, [hl]
  sub a, b
  ld [hl], a
  
  ; add carry at y position
  pop hl ; hl = x or y
  ld b, 0
  ld a, [hl]
  sbc a, b
  ld [hl], a

  ret 

; move current actor in a specific direction
; by addition
; inputs:
;   hl: points to x or y of actor
;   de: points to xs or ys of actor
;   a: velocity 
; returns:
player_substate_move_add:
  push hl
  
  ld hl, 0 ; hl = xs or ys
  add hl, de
  ; y up movement
  ld b, a
  ld a, [hl]
  add a, b
  ld [hl], a
  
  ; add carry at y position
  pop hl ; hl = x or y
  ld b, 0
  ld a, [hl]
  adc a, b
  ld [hl], a

  ret 

; restores y from scratch 
; input:
;   hl: actor ptr
;   sratch: previous y position
act_restore_y:
  ; if collision happened restore previous y 
  push hl
  ld de, acty
  add hl, de
  ld a, [scratch]
  ld [hl], a
  pop hl

  ret

; move the actor in a specific direction 
; state vars:
; inputs:
;   de: actor ptr
; registers changed:
;   de, hl
player_act_substate_move:
  push de ; stack now has actor ptr saved for later 

  ; y position
  
  ; up 
  push de ; push act ptr for use in collision check
  ld hl, acty
  add hl, de ; hl = y
  ld de, player_ys

  ld a, [hl] 
  ld [scratch], a ; scratch = previous y 
  ld a, [player_ys] 
  ld [scratch+1], a ; scratch+1 = previous ys

  ld a, [player_velocity_ys_up] ; a = velocity up 
  call player_substate_move_sub
  
  ; collision detection up
  pop hl ; hl = act ptr
  call act_substate_check_collision_top 
  cp a, 0
  jr z, @no_collision_up REL
  
  call act_restore_y
@no_collision_up:

   
  ; down
  pop hl
  push hl ; stack still has actor ptr 
  ld de, acty
  add hl, de ; hl = y
  ld de, player_ys
  
  ld a, [hl] 
  ld [scratch], a ; scratch = previous y 
  ld a, [player_ys] 
  ld [scratch+1], a ; scratch+1 = previous ys

  ld a, [player_velocity_ys_down]
  call player_substate_move_add
  
  ; detect collision bottom 
  pop hl ; hl = actor ptr
  call act_substate_check_collision_bottom
  cp a, 0 
  jr z, @no_collision_down REL
  
  call act_restore_y
@no_collision_down:

  ; x position
  
  ; left 
  push hl ; stack still has actor ptr 
  ld de, actx
  add hl, de ; hl = x
  ld de, player_xs
  ld a, [player_velocity_xs_left]
  call player_substate_move_sub

  ; right 
  pop hl
  push hl ; stack still has actor ptr 
  ld de, actx
  add hl, de ; hl = x
  ld de, player_xs
  ld a, [player_velocity_xs_right]
  call player_substate_move_add
  
  pop de
  ret 

; loads x/y coordinates from actor in hl into bc
#macro act_check_collision_xy_bc
  push hl
  ld de, acty
  add hl, de
  ld a, [hl+]
  ld b, a
  ld a, [hl]
  ld c, a ; bc is x/y coordinate 
  pop hl
#endmacro

; check bottom collision for current actor's 
; top left collision rect location
; inputs:
;   hl: actor ptr 
; returns:
;   a = 0 -> no collision
;   a > 0 -> collision
; registers:
;   preserves hl
;   preserves de
act_substate_check_collision_bottom:
  push hl
  push de
  
  act_check_collision_xy_bc
  
  ; adjust positon by collision rect as needed 
  ; by this routine
  ld de, actcollision 
  add hl, de ; hl = collision rect

  ld a, [hl+]
  ld e, a
  ld a, [hl]
  ld d, a
  ld hl, 0
  add hl, de ; hl = collision rectangle

  ld a, [hl+] ; a = y offset 
  add a, b ; y = top 
  ld b, a ; back to b

  ld a, [hl+] ; a = x offset 
  add a, c ; x + left 
  ld c, a ; back to c 
  
  ld a, [hl+] ; a = height 
  add a, b ; y + height 
  ld b, a
  
  push bc
  push hl
  ; call for bottom left corner
  call tileflagsat
  and a, TILE_COLLIDER
  pop hl ; hl = height 
  pop bc ; bc is now back to the previous y/x values 
  jr nz, @end REL
  
  ; call again for bottom right corner 
  ; simply add the width to the x value currently stored in c
  ld a, [hl] ; a = width 
  add a, c ; x + width 
  ld c, a
  call tileflagsat
  and a, TILE_COLLIDER
@end:
  pop de
  pop hl
  ret

; see collision_bottom
act_substate_check_collision_top:
  push hl
  push de
  
  act_check_collision_xy_bc
  
  ; adjust positon by collision rect as needed 
  ; by this routine
  ld de, actcollision 
  add hl, de ; hl = collision rect

  ld a, [hl+]
  ld e, a
  ld a, [hl]
  ld d, a
  ld hl, 0
  add hl, de ; hl = collision rectangle

  ld a, [hl+] ; a = y offset 
  add a, b ; y = top 
  ld b, a ; back to b

  ld a, [hl+] ; a = x offset 
  add a, c ; x + left 
  ld c, a ; back to c  
  inc hl ; hl = width  
  
  push bc
  push hl
  ; call for bottom left corner
  call tileflagsat
  and a, TILE_COLLIDER
  pop hl ; hl = height 
  pop bc ; bc is now back to the previous y/x values 
  jr nz, @end REL
  
  ; call again for bottom right corner 
  ; simply add the width to the x value currently stored in c
  ld a, [hl] ; a = width 
  add a, c ; x + width 
  ld c, a
  call tileflagsat
  and a, TILE_COLLIDER
@end:
  pop de
  pop hl
  ret

act_substate_check_collision_left:
  ret 

; player animation frames
player_frames:
.db 2, 3
player_flame_frames: 
.db 18, 19
;
; update player function
;
player_draw:
  ; move actor ptr to hl
  push de

  pop hl
  push hl
  ld de, acty 
  add hl, de

  ld a, [hl+] ; y index 
  ld b, a
  ld a, [hl] ; x
  ld c, a

  ld hl, player_frames
  ld a, [global_anim_timer]
  ld d, 0
  ld e, a
  add hl, de
  
  ; player main sprite 
  ld a, [hl] ; chr 
  ld d, a ; a + global anim = real tile
  ld a, 0 ; flag
  ld e, a
  ; prefer obj 0
  call soamsetto
  
  ; only draw flame if velocity is not 0
  ld a, [player_velocity_ys_down]
  and a, a
  jr nz, @flame_draw REL
  ld a, [player_velocity_ys_up]
  and a, a 
  jr nz, @flame_draw REL
  ld a, [player_velocity_xs_left]
  and a, a
  jr nz, @flame_draw REL
  ld a, [player_velocity_xs_right]
  and a, a
  jr z, @no_flame_draw REL

@flame_draw:
  ; move flame 1 tile down
  ld a, 8
  add a, b
  ld b, a

  ; same flags but use differnet spirte 
  ld hl, player_flame_frames
  ld a, [global_anim_timer]
  ld d, 0
  ld e, a
  add hl, de

  ld a, [hl]
  ld d, a
  ld e, 0
  call soamsetto
  
  ; pop hl one more time 
  pop hl

  ret 

@no_flame_draw:
  xor a, a
  ld d, a
  ld e, a
  call soamsetto 

  ; pop hl one more time 
  pop hl

  ret


; create a title cursor 
; there should only ever 
; one cursor per scene because
; they maniulate global state 
title_cursor_init:
  call act_alloc
  hl_null_panic

  push hl
  ; init cursor 
  
  ; type is player 
  pop hl
  push hl
  ld de, acttype
  add hl, de
  ld a, ACT_TTITLECURSOR
  ld [hl], a

  ld a, 0
  pop hl
  push hl
  ld de, actx 
  add hl, de
  ld [hl], a ; y pos
 

  pop hl
  ld bc, title_cursor_update
  ; transition player to state 0
  call actstate_to

  ret 

; TODO: split title curosr into draw and update function
#define TITLE_CURSOR_DELAY 10 
#define TITLE_CURSOR_MAX 3
title_cursor_positions:
  .db 64, 64+8, 64+16
title_cursor_update:
  push de 
  pop hl
  push hl ; this push is for draw call later
  ; hl now points to acty 
  ; which is the cursor selection index
  ld de, acty
  add hl, de

  ; inputs 
  ld a, [global_delay]
  cp a, 0
  jp nz, @no_inputs
  
  ; start button -> run action at index 
  ld a, [inputs]
  and a, BTNSTART 
  jp z, @notstart
  
  ld a, [hl]
  ld hl, init_mode_play 

  cp a, TC_NEWGAME 
  jr nz, @notnewgame REL
  ld hl, init_mode_play 
  
@notnewgame:
  cp a, TC_MAPED 
  jr nz, @notmaped REL
  ld hl, init_mode_editor
@notmaped:
@transition:
  pop de ; pop draw call push in this case
  call transition
  ret
@notstart:
  
  ; down -> move cursor 
  ld a, [inputs]
  and a, BTNDOWN
  jp z, @notdown

  ; delay next input 
  ld a, TITLE_CURSOR_DELAY
  call setdelay
  ld a, [hl]
  inc a
  cp a, TITLE_CURSOR_MAX 
  jp nz, @notmaxdown
  ld a, 0
@notmaxdown:
  ld [hl], a
@notdown:

  ; up -> move cursor
  ld a, [inputs]
  and a, BTNUP
  jp z, @notup
  
  ; delay next input
  ld a, TITLE_CURSOR_DELAY 
  call setdelay

  ld a, [hl]
  dec a
  
  cp a, 0xFF
  jp nz, @notmindown
  ld a, TITLE_CURSOR_MAX - 1
@notmindown:
  ld [hl], a
@notup:

@no_inputs:
  pop de ; de points to act again
  call title_cursor_draw
  ret

title_cursor_draw:
  ; top of stack: ptr to act 
  push de 
  pop hl
  push hl
  ld de, acty 
  add hl, de

  ; set up oam 
  ld a, [hl+] ; y index 
  ld e, a
  ld d, 0
  ld hl, title_cursor_positions 
  add hl, de
  ld a, [hl] ; load y position from hl + de
  ld b, a

  ld a, 64 ; x
  ld c, a
  ld a, 7 ; chr 
  ld d, a
  ld a, 0 ; flag
  ld e, a
  ; prefer obj 0
  ld a, 0
  call soamsetto

  pop hl
  ret

; converts actor position to tile position 
; inputs:
;   bc: y/x coordinates
; returns:
;   hl: ram offset
;   a: 0 on success, > 0 on error
postotile:
  ld a, c
  sub a, 8 ; -8 to adjust for offscreen values
  ld c, a

  srl c ; x / 2
  srl c ; x / 4
  srl c ; x / 8
  

  ; - 16 for offscreen values and another -16 to make the sprite appear in the right spot
  ld a, b
  sub a, 32 
  ld b, a 

  srl b ; y / 2
  srl b ; y / 4
  srl b ; y / 8

  ; load offset address from lut 
  ld hl, acttiletomapl ; low  
  ld d, 0
  ld e, b ; de = tile y offset 
  add hl, de
  ld a, [hl]

  ; we don't store result in e yet because we still need
  ; de but we don't need a again just yet 

  ld hl, acttiletomaph ; high
  ld d, 0
  ld e, b ; de = tile y offset
  add hl, de

  ; we now dont need de anymore 
  ld e, a ; store result from previous operation 

  ld a, [hl]
  ld d, a ; de = y offset 
  
  ld h, 0
  ld l, c
  add hl, de

  xor a, a ; a = 0 == success
  ret 


#undefine TITLE_CURSOR_DELAY

; get map flags for position
; inputs:
;   b/c: y/x coordinates 
; returns:
;   a: tile flags
; registers:
;   bc is preserved 
;   hl is preserved 
tileflagsat:
  push hl
  push bc 
  
  call postotile
  ; TODO: mapbuf should be a room pointer
  ld de, mapbuf
  add hl, de

  ; a = tile index 
  ld a, [hl]

  ld h, 0
  ld l, a ; hl = tile flag offset 
  ld de, tileflags ; de = tile flags lut
  add hl, de
  ld a, [hl] ; a = tile flag 

  pop hl
  pop bc 
  ret

; coordinate lookup tables 
; use like this:
; - convert x/y coordinates to tile 
; - convert y tile coordinate to map data offset using lo and hi 
; - add x coordinate to the result -> this is the map data location of 
;   the current tile
; - add the resulting value to the base address of the 
;   tile data to obtain the tile at the specified location

; look up tables pixel position -> tile position 
actpostotile:
.rep i, 256, 1, .db i / 8
; look up table tile y coordinate -> row
acttiletomapl: ; low nibble
.rep i, 20, 1, .db (i * 20) 
acttiletomaph: ; hi nibble
.rep i, 20, 1, .db ((i * 20) >> 8)

; actor collision rectangle  
;   each entry is 4 bytes wide 
;   with the following values
;   0 -> y offset
;   1 -> x offset
;   2 -> height
;   3 -> width

player_collision:
; player 
.db 0x00 ; y offset 
.db 0x00 ; x offset 
.db 0x07 ; height
.db 0x07 ; width 
