; maps are 20 tiles wide and 16 high
; the top 2 rows of tiles are reserved for a simple UI
; the map itself consists of 2 arrays of 20*16
; the first array is the tile array 
; which is directly drawn to the screen 
; the tile array also indicates (hard coded) which tiles have collisin
; the second array is a list of tile flags
; actors may write their tile index to a tile to indicate it is occupied by them 


#define MAP_W 20
#define MAP_H 16

; menu height 
#define MENU_H 16 

#define MAP_SIZE MAP_W * MAP_H
