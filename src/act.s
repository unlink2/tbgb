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

; init player with the first free 
; actor found  
player_init:
  call act_alloc
  hl_null_panic
  
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

;
; update player function
; 
player_update:
  ; move actor ptr to hl
  push de 
  pop hl
  push hl ; we need base hl again later 
  
  ; set hl to actx ptr
  ldhlm actx 
  
  ; set default tiles and flags
  ; for the idle animation
  ld a, 2
  ld [chrs], a

  ld a, 4
  ld [chrs+1], a

  ld a, 0
  ld [chrflags], a
  ld [chrflags+1], a
  
  ; read inputs, move and modify 
  ; tiles based on movement 
  ld a, [inputs]
  and a, BTNLEFT 
  jr z, @notleft REL
  ; left input hit
    ld a, [hl] 
    dec a
    ld [hl], a
@notleft:
  
  ld a, [inputs]
  and a, BTNRIGHT
  jr z, @notright REL
  ; right input hit
    ld a, [hl]
    inc a
    ld [hl], a
@notright:
 
  ;set hl to acty ptr
  ldhlm acty

  ld a, [inputs]
  and a, BTNUP
  jr z, @notup REL
  ; up input hit 
    ld a, [hl]
    dec a
    ld [hl], a
@notup:
  
  ld a, [inputs]
  and a, BTNDOWN 
  jr z, @notdown REL
  ; down input hit 
    ld a, [hl]
    inc a
    ld [hl], a
@notdown:
  ; load to oam

  ; left sprite
  pop hl ; base pointer to act
  ld de, acty
  add hl, de
  ; load data in order: y, x, chr, flag
  ld a, [hl+] ; y
  ld b, a
  ld a, [hl+] ; x
  ld c, a
  
  ld a, [chrs] ; chr 
  ld d, a
  ld a, [global_anim_timer]
  add a, d
  ld d, a
  
  ld a, [chrflags] ; flag
  ld e, a
  
  ; will need them again in a second 
  push bc

  ; prefer obj 0
  ld a, 0
  call soamsetto
  
  ; right sprite 
  pop bc
  ; move x position
  ld a, c
  add a, 8
  ld c, a
  
  ld a, [chrs+1] ; chr bottom
  ld d, a 
  ld a, [global_anim_timer]
  add a, d
  ld d, a

  ld a, [chrflags+1] ; f;ags 
  ld e, a 

  ; prefer obj 0
  ld a, 1
  call soamsetto 

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

#undefine TITLE_CURSOR_DELAY
