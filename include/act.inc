; actors falgs 
#define ACT_FACTIVE 0b00000001

; actor memory layout
.se 0
.de actflags, 1
.de acttype, 1
.de actfn, 2
; 2 bytes of user-specific memory
; can be used by each actor as needed
.de actusr, 2
; actor velocity
; signed integer 
.de actvelxl, 1
.de actvelyl, 1
; postions are x.xl and y.yl 
; fixed point integers
; this memory layout of yl, xl, y, x is
; guarnateed
; meaning that yl+2 will always be y
; and xl+2 will always be x
.de actyl, 1 
.de actxl, 1
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

; actor animation state enum 
.se 0
.de ACT_IDLE_LEFT, 1
.de ACT_IDLE_RIGHT, 1
.de ACT_MOVLEFT, 1
.de ACT_MOVRIGHT, 1

#define PLAYER_VEL_MAX 127

; player specific flags 
.se 1
.de PLAYER_FIDLE_LEFT, 1

; player struct
; actusr: player specific flags
