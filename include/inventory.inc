#define MAX_INV 32

; inventory table entry 
.se 0
; what item is referenced?
.de invitem, 1
; how many?
.de invcount, 1 
.de INVSIZE, 0

; item type enum 
.se 0
.de ITM_T_SHORT_SWORD, 1
.de ITM_T_HP_POT, 1
.de ITM_T_MP_POT, 1

; item quality levels
; used for consumables 
.se 0 
.de ITM_Q_SPOILED, 1
.de ITM_Q_MINOR, 1
.de ITM_Q_REGULAR, 1
.de ITM_Q_MAJOR, 1

; item qaulity synonyms
; used for equipment 
.se 0
.de ITM_Q_TRASH, 1
.de ITEM_Q_COMMON, 1
.de ITM_Q_UNCOMMON, 1
.de ITM_Q_RARE, 1 
.de ITM_Q_EPIC, 1
.de ITM_Q_LEG, 1
.de ITM_Q_UNIQUE, 1

; item table entry 
.se 0
; what kind of item it is 
.de itmtype, 1
; level of quality 
.de itmquality, 1
; function pointer to on use
; expects using actor in hl
.de itmusefn, 2 
; what the item provides when equiped 
; signed integer, stat removal as a disatvantage 
; is possible!
.de itmhp, 1
.de itmmp, 1
.de itmstr, 1
.de itmint, 1
.de itmlck, 1
.de itmdmg, 1
; meta data 
.de itmtile, 1
.de itmname, 8 
.de ITMSIZE, 0
