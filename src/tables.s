; this file contains various tables 

; item table 

; define item table entry 
; inputs:
;   $1: item type
;   $2: item quality
;   $3: item use function
;   $4: hp bonus
;   $5: mp bonus
;   $6: str bonus
;   $7: int bonus
;   $8: lck bonus
;   $9: dmg bonus
;   $10: item tile id
;   $11: item name (str)
#macro itmdef 
.db $1 ; type 
.db $2 ; quality

; use function
dw $3 

.db $4 ; hp 
.db $5 ; mp
.db $6 ; str
.db $7 ; int 
.db $8 ; lck
.db $9 ; dmg 
.db $10 ; tile 
; name 
dw $11 

#endmacro 

itmdef ITM_T_SHORT_SWORD, ITM_Q_TRASH, itm_use_nop, 0, 0, 0, 0, 0, 0, 1, s_short_sword
