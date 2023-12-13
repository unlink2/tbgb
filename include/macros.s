#macro dw 
.db $1 & 0xFF
.db ($1 >> 8) & 0xFF 
#endmacro

