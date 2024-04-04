; actors falgs 
#define ACT_FACTIVE 0b00000001

; actor memory layout
; actor layour is guaranteed!
.se 0
.de actflags, 1
.de acttype, 1

; the actor state is the current state the actor is in
; a state may transition to any other state function 
; or it may return to the default statue function
; which is stored in actstate0
.de actstatefn, 2 

; pointer to collision offsets
.de actunused, 2

; user-specific memory
; can be used by each actor as needed
.de actusr, 2

; actor movement 

; actor's real x and y location 
; y and x memory layout is guaranteed! 
.de acty, 1
.de actx, 1

.de ACTSIZE, 0

; actor types 
.se 1

; player type 
.de ACT_TPLAYER, 1
.de ACT_BULLET, 1
.de ACT_ENEMY_BASIC, 1

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

