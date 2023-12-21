; actors falgs 
#define ACT_FACTIVE 0b00000001

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
