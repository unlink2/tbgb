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
  ld a, 0
  ld hl, soamallocflags
  ld bc, OBJSMAX
  jp memset 

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
;      and is returned if available
; returns:
;   a: index to first free object or 0xFF if not found
; registers:
;   
soamalloc:
  ; check requested index first 
  ld b, 0
  ld c, a
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
  ld de, actcollisin
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
;   a: prefered oam index
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
  call player_substate_gravity
  call player_act_substate_move
  call player_draw
  ret

; process a single player input
; inputs:
;   a: zero or not zero for input
;   hl: pointing to velocity byte  
; returns:
;   hl+1
player_substate_input_proc:
  jr z, @not REL

  ; load max velocity for now  
  ld a, 0xFF  
  ld [hl+], a ; hl = ys down
  jr @done REL
@not:
  ld a, 0
  ld [hl+], a ; hl = ys down 
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
  call player_substate_input_proc 
  
  ; down input
  ld a, [inputs]
  and a, BTNDOWN
  call player_substate_input_proc

  ; left input
  ld a, [inputs]
  and a, BTNLEFT
  call player_substate_input_proc
  
  ; right input 
  ld a, [inputs]
  and a, BTNRIGHT
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
  ld hl, acty
  add hl, de ; hl = y
  ld de, player_ys
  ld a, [player_velocity_ys_up] ; a = velocity up 
  call player_substate_move_sub
   
  ; down
  pop hl
  push hl ; stack still has actor ptr 
  ld de, acty
  add hl, de ; hl = y
  ld de, player_ys
  ld a, [player_velocity_ys_down]
  call player_substate_move_add

  ; x position
  
  ; left 
  pop hl
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

; check top left collision for current actor's 
; top left collision rect location
; inputs:
;   hl: pointing to collision rectangle information
;   b:  y coodinate
;   c:  x coordinate
; returns:
;   a = 0 -> no collision
;   a > 0 -> collision
; registers:
;   preserves hl
;   preserves de
act_substate_check_collision_bottom_left:
  push hl
  push de
  
  ld a, [hl+] ; a = left offset 
  add a, c ; x + left 
  ld c, a ; back to c 

  ld a, [hl] ; a = top offset 
  add a, b ; y = top 
  ld b, a ; back to b
  
  call tileflagsat
  and a, TILE_COLLIDER

  pop de
  pop hl
  ret

; player animation frames
player_frames:
.db 2, 3
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

  ld a, [hl] ; chr 
  ld d, a ; a + global anim = real tile
  ld a, 0 ; flag
  ld e, a
  ; prefer obj 0
  ld a, 0
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
  push af ; x coordinate 

  ld a, b
  push af ; y coordinate 


  ; TODO: bail if sprite is clearly out of bounds

  ; first load y coordinate 
  pop af

  ; - 16 for offscreen values and another -16 to make the sprite appear in the right spot
  sub a, 32 
  ld d, 0
  ld e, a ; de = offset for y
  ld hl, actpostotile 
  add hl, de
  ld a, [hl]
  ld e, a ; de = offset for y to map data 
  
  ; load low nibble of address into a 
  ld hl, acttiletomapl 
  add hl, de
  ld a, [hl]
  ld c, a ; store in c for now 

  ; load high nibble of address into a
  ld hl, acttiletomaph 
  add hl, de
  ld a, [hl]
  ld b, a ; store in b for now

  ; bc = y offset 
  
  ; then load x coordinate 
  pop af
  sub a, 8 ; -8 to adjust for offscreen values
  ld d, 0
  ld e, a ; de = offset for x
  ld hl, actpostotile
  add hl, de 
  ld a, [hl] ; a is now the x offset 

  ld h, 0
  ld l, a ; hl = x offset 

  push bc 
  pop de
  add hl, de
  
  ; success
  ld a, 0 

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

; lookup table for actor collision based on actor type
; e.g. ACT_TPLAYER
;   each entry is 4 bytes wide 
;   with the following values
;   0 -> left offset
;   1 -> top offset
;   2 -> width
;   3 -> height

player_collision:
; player 
.db 0x00 ; left offset 
.db 0x00 ; top offset 
.db 0x08 ; width
.db 0x08 ; height 
