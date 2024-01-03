; this file contains various tables 

; item table 
#macro itmdef 

.db $1 ; type 
.db $2 ; quality 

.db $3 & 0xFF ; usefn 
.db ($3 >> 8) & 0xFF ; usefn 

.db $4 ; hp 
.db $5 ; mp
.db $6 ; str
.db $7 ; int 
.db $8 ; lck
.db $9 ; dmg 
.db $10 ; tile 
; name 
.str $11 

#endmacro 

itmdef 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, "test"
