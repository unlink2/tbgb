; actor update functions:
;   all actor update functions expect the actor ptr to be located in 
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
  ; zero out the some common things
  ldhlm actvelxl 
  ld a, 0
  ld [hl], 0

  ldhlm actvelyl 
  ld a, 0
  ld [hl], 0
  
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
  ldhlto actpl

  push hl
  
  ; now init player data 
  
  ; type is player 
  ldhlm acttype 
  ld a, ACT_TPLAYER
  ld [hl], a

  ; ld fn pointer 
  ldhlm actfn 
  ldhlptr player_update 
  
  ; ignore unused byte for now...

  ; xl 
  ldhlm actxl 
  ld a, 0
  ld [hl], a
  
  ; yl
  ldhlm actyl 
  ld [hl], a

  ; TODO: set proper initial location
  ld a, 64
  ldhlm acty 
  ld [hl], a ; x pos 
  ldhlm actx 
  ld [hl], a ; y pos
  
  ; set up collision rectangle 

  ; col x/y 0,0
  ld a, 0
  ldhlm actcolx 
  ld [hl], a
  ldhlm actcoly 
  ld [hl], a
  
  ; col w/h 15,7
  ld a, 15
  ldhlm actcolw 
  ld [hl], a

  ld a, 7
  ldhlm actcolh 
  ld [hl], a

  pop hl
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

; read a value from the chr table 
; inputs:
;   hl: the table
;   a: offset (actor state)
;  returns:
;   a: the value 
readchrtbl:
  push de
  ld d, 0
  ld e, a
  add hl, de
  ld a, [hl]
  pop de
  ret

; set actor flags 
; inputs:
;   hl: actor base ptr 
;   a: flag value
; registers: hl is unchanged 
actsetflags:
  push hl
  ld [hl], a 
  pop hl
  ret 

; animation tables for player 
player_chr_left:
.db 2, 4, 10, 8
player_chr_right:
.db 4, 2, 8, 10
player_chrflags_left:
.db 0, OAM_FXFLIP, OAM_FXFLIP, 0
player_chrflags_right:
.db 0, OAM_FXFLIP, OAM_FXFLIP, 0

;
; update player function
; 
player_update:
  ; move actor ptr to hl
  push de
  pop hl
  push hl ; we need base hl again later  
  
  ; set default actor mode
  ldhlm actvelxl 
  ; check previous sign to decide if facing left or right
  ld a, [hl] 
  and a, 0b10000000 
  jp z, @nocarry
  scf
@nocarry:
  ld a, ACT_IDLE_LEFT
  adc a, 0
  ld [tmp], a

  ; set hl to actx ptr
  ldhlm actxl 

  ; read inputs, move and modify 
  ; tiles based on movement 
  ld a, [inputs]
  and a, BTNLEFT | BTNRIGHT
  jp nz, @xmovement
  
  ldhlm actvelxl
  ld a, [hl]
  ; clear all but sign because
  ; we use it to determine the facing direction
  and a, 0b10000000
  ld [hl], a
  jp @xmovement_done

@xmovement:
  ldhlm actvelxl
  ld a, [inputs]
  and a, BTNLEFT 
  jr z, @notleft REL
  ; left input hit
    ld a, 0b10000000 | PLAYER_VEL_MAX
    ld [hl], a
  
    ld a, ACT_MOVLEFT
    ld [tmp], a
@notleft:
   
  ; right input
  ldhlm actvelxl

  ld a, [inputs]
  and a, BTNRIGHT
  jr z, @notright REL
  ; right input hit

    ; position
    ld a, PLAYER_VEL_MAX
    ld [hl], a

    ld a, ACT_MOVRIGHT
    ld [tmp], a
@notright:

@xmovement_done:

  pop hl ; base pointer to act
  call actgravity 
  call actapplyvel

  ; load to soam
  ld de, player_chr_left
  ld bc, player_chrflags_left
  ld a, 0
  ; y 
  ld [p0], a
  ; x
  ld [p1], a
  ; actor state 
  ld a, [tmp]
  ld [p2], a
  call actdraw 


  ld de, player_chr_right
  ld bc, player_chrflags_right
  ; y 
  ld a, 0
  ld [p0], a
  ; x
  ld a, 8
  ld [p1], a
  call actdraw 

  ret

; draw actor into soam based on its tate and a table
; inputs;
;   hl: actor 
;   de: chr table (actor state -> chr mapping)
;   bc: attr table (actor state -> tile flags)
;   p0: y offset
;   p1: x offset 
;   p2: actpr state
; registers:
;   all gp registers are unchanged
;   p0-p4 are unchanged
actdraw:
  push hl
  push de
  push bc
  push af
  
  push de
  ld de, acty
  add hl, de
  pop de
  
  push bc ; store bc here again because we need it for attr

  ; load data in order: y, x, chr, flag
  ld a, [hl+] ; y
  ld b, a
  ld a, [p0]
  add a, b
  ld b, a ; b now holds the correct coordinate  

  inc hl
  inc hl
  ld a, [hl] ; x
  ld c, a
  ld a, [p1]
  add a, c
  ld c, a ; c now holds the correct coordinate
  
  push de
  pop hl ; hl = chr table
  ld a, [p2] ; p2 = actor state
  ld d, 0
  ld e, a
  add hl, de ; hl+p2 points to chr

  ld a, [hl] ; chr
  ld d, a
  ld a, [global_anim_timer]
  add a, d
  ld d, a
  
  pop hl ; hl = attr table 
  push de
  ld a, [p2] ; p2 = actor state 
  ld d, 0
  ld e, a
  add hl, de ; hl+p2 points to attr 

  pop de 
  ld a, [hl] ; attr
  ld e, a

  ; prefer obj 0
  ld a, 0
  call soamsetto
  
  pop af
  pop bc
  pop de
  pop hl
  ret 

; apply gravity to the actor's y velocity 
; inputs:
;   hl: the actor 
; registers: hl is unchanged 
actgravity:
  push hl

  ; check bottom collision
  ldhlm acty 
  ld a, [hl]
  ld b, a

  ; y + col y 
  ldhlm actcoly 
  ld a, [hl]
  add a, b 

  ; y + col h
  ldhlm actcolh 
  ld a, [hl]
  add a, b
  ld b, a ; b = y + coly + colh

  ; x + colx 
  ldhlm actx 
  ld a, [hl]
  ld c, a
  
  ldhlm actcolx 
  ld a, [hl]
  add a, c
  ld c, a

  call mapflagsat
  and a, TILE_COLLIDER 
  jr nz, @collision REL
  
  ; make the same call again, but with the far end of the collision box 
  ; x + col x + col width 
  ldhlm actcolw 
  ld a, [hl]
  add a, c
  ld c, a

  call mapflagsat
  and a, TILE_COLLIDER 
  jr nz, @collision REL

@nocollider:
  ldhlm actvelyl 
  ld a, [hl]
  add a, GRAVITY_ACCEL 
  cp a, GRAVITY_MAX 
  jr c, @ok REL
  ld a, GRAVITY_MAX
@ok:
  ld [hl], a
  
  pop hl
  ret

@collision:
  ldhlm actvelyl 
  ld a, 0
  ld [hl], a

  pop hl
  ret 

; apply velocity to an axis
; inputs:
;   hl: points to velocity
; registers:
;   hl: changed
;   a: changed
actapplyvel_axis:
  ld a, [hl]
  and a, 0b01111111
  ld b, a
  ld a, [hl]
  
  cp a, 0
  jp z, @movedone
  and a, 0b10000000
  jp z, @actapplyvel_plus 

  ; velocity is < 0
  inc hl ; actxl 
  ld a, [hl] 
  sub a, b 
  ld [hl], a
  jp nc, @notfullmove_sub
    
    ; apply full move
    inc hl ; actx
    ld a, [hl]
    dec a
    ld [hl], a
@notfullmove_sub:

  jp @movedone
  
  ; velocity is > 0 
@actapplyvel_plus:
  ; position
  inc hl ; actxl
  ld a, [hl]
  add a, b
  ld [hl], a
  jp nc, @notfullmove_add 
      
    ; apply full move
    inc hl ; actx
    ld a, [hl]
    inc a
    ld [hl], a
    
@notfullmove_add:
@movedone:
  ret

; applyes velocity on the x and y axis
; inputs:
;   hl: the actor 
; registers: 
;   hl is unchanged
;   de is modified  
;   bc is modified 
actapplyvel:
  push hl

  ldhlm actvelxl 
  call actapplyvel_axis 
  
  ldhlm actvelyl 
  call actapplyvel_axis

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
  ldhlm acttype 
  ld a, ACT_TTITLECURSOR
  ld [hl], a

  ; ld fn pointer 
  ldhlm actfn 
  ldhlptr title_cursor_update 

  ld a, 0
  ldhlm actx 
  ld [hl], a ; y pos
  
  pop hl

  ret 

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
  ret

; converts actor position to tile position 
; inputs:
;   bc: y/x coordinates
; returns:
;   hl: ram offset
;   a: 0 on success, > 0 on error
actpostotilepos:
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
mapflagsat:
  push hl
  push bc 
  
  call actpostotilepos 
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
