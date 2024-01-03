; actors falgs 
#define ACT_FACTIVE 0b00000001

; actor memory layout
.se 0
.de actflags, 1
.de acttype, 1

; actor function pointers
; draw, state0, and statefn layout is guaranteed
.de actdrawfn, 2
; state 0 is the default state 
; each actor can define a default state it wants to return to 
; if no other satate is required
.de actstate0fn, 2
; the actor state is the current state the actor is in
; a state may transition to any other state function 
; or it may return to the default statue function
; which is stored in actstate0
.de actstatefn, 2 

; 8 bytes for actor stats
; this includes 

; max/current hp
.de actstat_hpmax, 1
.de actstat_hpcur, 1

; max/current mp
.de actstat_mpmax, 1
.de actstat_mpcur, 1

.de actstat_str, 1
.de actstat_agi, 1
.de actstat_int, 1
.de actstat_lck, 1

; 2 bytes of user-specific memory
; can be used by each actor as needed
.de actusr, 2
; 2 bytes that can be used as paramters for 
; states. The documentation for what the bytes do should be part 
; of the state function
.de actstate, 2 
; actor positioning is only tacked on the pixel grid 
; because it is enough for simple 
; turn-based movement 
; y and x memory layout is guaranteed! 
.de acty, 1
.de actx, 1
.de ACTSIZE, 0


; actor types 
.se 1

; player type 
.de ACT_TPLAYER, 1

; cursor type: 
;  the cursor type handles location as follows:
;  the x location is used as-is to postiion it on screen 
;  the y position is the cursor location index
;  it can be used with the cursor index lut to trigger an action
;  to position the cursor use the cursor position lut
.de ACT_TTITLECURSOR, 1

; title cursor enum 
.se 0
.de TC_NEWGAME, 1
.de TC_MAPED, 1

; ACT_DIRECTION 
.se 0 
.de ACT_DIRLEFT, 1
.de ACT_DIRRIGHT, 1
.de ACT_DIRUP, 1
.de ACT_DIRDOWN, 1
