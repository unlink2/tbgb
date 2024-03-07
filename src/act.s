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

; determine the next actor
; to set active 
actnext:
  ret

; update the active actor
; this will ever only call update on a single actor 
; actors need to release their "lock" as active actor manually 
; by calling actnext when they are done updating 
actupdate:
  ld a, [actactive]
  ld l, a
  ld a, [actactive+1]
  ld h, a

  ; if active actor is not active, skip
  ld a, [hl]
  and a, ACT_FACTIVE
  jp z, @skip
  
  push hl

  ; load current actor state call 
  ldhlm actstatefn 

  ; de is current actor ptr 
  ; as expected by update call 
  pop de 
  call callptr
  ret 
@skip:
  ; if we skipped this actor skip to the next one 
  call actnext 
  ret

; draw all actors to soam
; this is not the actual vram draw call 
; and can safely be called at any point 
actdraw:
  ; first free all soam entries 
  call soamfreeall
@draw_act:
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
    ld bc, actdrawfn 
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

  ; save pointer to player 
  ; for later use 
  ld a, l
  ld [actactive], a
  ld a, h
  ld [actactive+1], a

  push hl
  
  ; now init player data 
  
  ; type is player 
  ldhlm acttype 
  ld a, ACT_TPLAYER
  ld [hl], a

  ; ld fn pointer 
  ldhlm actdrawfn 
  ldhlptr player_draw 
  
  ; ignore unused byte for now...

  ; TODO: set proper initial location
  ld a, 0x39
  ldhlm acty 
  ld [hl], a ; x pos 
  ldhlm actx 
  ld [hl], a ; y pos
  
  ; set default state 0
  ldhlm actstate0fn 
  ld de, player_state_input 
  ld a, e
  ld [hl+], a
  ld a, d
  ld [hl], a

  pop hl
  ; transition player to state 0
  call actstate_to_s0

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

; transition the actor back to its default state 
; inputs:
;   hl: actor ptr 
; registers:
;   hl remains unchanged 
actstate_to_s0:
  ; load default state into bc 
  push hl

  ldhlm actstate0fn
  ld a, [hl+]
  ld c, a
  ld a, [hl+]
  ld b, a 

  ; bc = state0
  pop hl
  call actstate_to 

  
  ret

; transition actor to any state
; inputs:
;   hl: actor ptr 
;   bc: next state 
;   de: state data (d -> actstate+0, e-> actstate+1)
actstate_to:
  push hl
  push de
  
  ld de, actstate 
  add hl, de ; hl = actstate+0
  pop de
  ld a, d
  ld [hl+], a
  ld a, e
  ld [hl], a
  

  ldhlm actstatefn 
  
  ld a, c
  ld [hl+], a

  ld a, b
  ld [hl], a
  pop hl
  ret 

; read player input
; and transition to input handling state 
; for the next frame
; transitions to:
;   act_state_move if dpad is pressed
; inputs:
;   de: actor ptr 
player_state_input:
  push de
  pop hl ; hl = act ptr 

  ld a, [inputs]
  ; up input
  and a, BTNUP 
  jr z, @notup REL
  
    ld e, ACT_DIRUP
    jr @movement REL
@notup:

  ld a, [inputs]
  and a, BTNDOWN 
  jr z, @notdown REL

    ld e, ACT_DIRDOWN 
    jr @movement REL
@notdown:
  
  ld a, [inputs]
  and a, BTNLEFT 
  jr z, @notleft REL
    
    ld e, ACT_DIRLEFT 
    jr @movement REL
@notleft:

  ld a, [inputs]
  and a, BTNRIGHT 
  jr z, @notright REL

    ld e, ACT_DIRRIGHT 
    jr @movement REL
@notright:

  ret 
@movement:
  ; transition to state 
  ; move for 8 pixels/frames 
  ; in a direction set in e  
  ld d, 8
  ld bc, act_state_move 
  call actstate_to
  ret 

; move the player in a specific direction 
; state vars:
;   actstate+0: how many frames to move for 
;   actstate+1: which direction to move in (see ACT_DIRECTION) 
; inputs:
;   de: actor ptr 
act_state_move:
  push de

  ld hl, actstate 
  add hl, de ; hl = actstate+0
  ld a, [hl]
  cp a, 0
  jp z, @todefault 
  dec a
  ld [hl+], a ; hl = actstate+1 
  
  ; TODO: handle collision here 
  ; if collision is detected do not move!

  ld a, [hl]
  cp a, ACT_DIRUP 
  jr nz, @notup REL
    
    ; move up 
    ldhlm acty 
    ld a, [hl]
    dec a
    ld [hl], a
    pop hl 
    jr @done REL
@notup:
  cp a, ACT_DIRDOWN 
  jr nz, @notdown REL

    pop hl
    ld de, acty 
    add hl, de
    ld a, [hl]
    inc a
    ld [hl], a 
    jr @done REL
@notdown:
  
  cp a, ACT_DIRLEFT 
  jr nz, @notleft REL
    
    pop hl
    ld de, actx
    add hl, de 

    ld a, [hl]
    dec a
    ld [hl], a
    jr @done REL
@notleft:
  
  cp a, ACT_DIRRIGHT 
  jr nz, @notright REL

    pop hl
    ld de, actx
    add hl, de

    ld a, [hl]
    inc a
    ld [hl], a
    jr @done REL
@notright: 
  pop hl ; fallback pop hl if no case was hit
@done: 
  ret 
@todefault: 
  pop hl
  call actstate_to_s0
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

  ldhlm acty 
  ld a, [hl+] ; y index 
  ld b, a
  ld a, [hl] ; x
  ld c, a

  ; 
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

  ; save pointer to player 
  ; for later use 
  ld a, l
  ld [actactive], a
  ld a, h
  ld [actactive+1], a

  push hl
  ; init cursor 
  
  ; type is player 
  pop hl
  push hl
  ld de, acttype
  add hl, de
  ld a, ACT_TTITLECURSOR
  ld [hl], a

  ; ld fn pointer 
  ldhlm actdrawfn 
  ldhlptr title_cursor_draw 

  ld a, 0
  ldhlm actx 
  ld [hl], a ; y pos
 

  ; set default state 0
  ldhlm actstate0fn 
  ld de, title_cursor_update 
  ld a, e
  ld [hl+], a
  ld a, d
  ld [hl], a

  pop hl
  ; transition player to state 0
  call actstate_to_s0

  ret 

; TODO: split title curosr into draw and update function
#define TITLE_CURSOR_DELAY 10 
#define TITLE_CURSOR_MAX 3
title_cursor_positions:
  .db 64, 64+8, 64+16
title_cursor_update:
  push de 
  pop hl
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
  ret

title_cursor_draw:
  ; top of stack: ptr to act 
  push de 
  ldhlm acty 

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
