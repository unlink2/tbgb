; work ram
#define WRAM 0xC000
.org WRAM

; WRAM variables
; note: if a .se defintion is in memory
; *never* rely on the exact memory layout unless
; the data is specifically documented as an array
; e.g. when the size of the .de is > 1
; or if the layout is specifically documented
; in all other cases it is better to simply directly address
; [hl+offset] to avoid breaking code in the future

#define WRAMLEN 0xFFF

; max actors
#define ACTMAX 32

; game modes
.se 0
.de MODE_TITLE, 1
.de MODE_PLAY, 1
.de MODE_PAUSE, 1
.de MODE_EDITOR, 1


; actor shadow oam
; oam memory layout is guaranteed!
.se 0 
.de soamy, 1
.de soamx, 1
.de soamchr, 1
.de soamflags, 1
.de SOAMSIZE, 0

; shadow oam
; at the end of the update cycle, each active actor 
; may allocate an object from the shadow oam
; the data for x, y, char and flags are then copied over to the apropriate tile 
; the shadow oam is then dma'd to the real oam in vblank
soam: .adv OBJSMAX * SOAMSIZE
soamnext: .adv 2 ; index of next free soam object 

.def int OAMDMAFN = 0xFF80 

; actor memory 
acttbl: .adv ACTMAX * ACTSIZE

#define SOAM_FACTIVE 0b00000001
#define SOAM_EINVAL 0xFF

; global offset for soam to ensure object cycling is happening consistently
soamgoffset: .adv 1

inputs: .adv 1
prev_inputs: .adv 1

update_flags: .adv 1
frame: .adv 1
; either 0 or 1. may be used to animate 
; on global timer
global_anim_timer: .adv 1

scrolly: .adv 1
scrollx: .adv 1

game_mode: .adv 1

; some inputs mayb want to 
; use a delay timer
; this timer is always dec every frame 
; until it reaches 0
global_delay: .adv 1

; game flags
.def int GFDEAD = 1

game_flags: .adv 1

; =========================
; player specific variables 
; =========================

; actor velocity:
;   player velocity is an unsigned integer 
;   split into an x and y part
;   in either direction
;   velocity only operates on the sub-pixels of the game 
;   meaning the max velocity in either direction is 1 pixel per frame
;   memory layout of velocity is guaranteed!

; sub-pixel position 
; if this overflows the actual x and y position are incremented
; xs and ys memory layout is guaranteed!
player_ys: .adv 1
player_xs: .adv 1


; xs/ys velocity
player_velocity_ys_up: .adv 1
player_velocity_ys_down: .adv 1
player_velocity_xs_left: .adv 1
player_velocity_xs_right: .adv 1
player_hpmax: .adv 1

player_bullet_max: .adv 1
player_bullet_count: .adv 1
player_bullet_time: .adv 1
player_bullet_timeout: .adv 1

; bitfield of directions 
; see DIRECTION fields 
player_movement_dirs: .adv 1

; which direction is the player facing
player_facing_dir: .adv 1

; DIRECTION fields
.def int DIR_UP = 1
.def int DIR_DOWN = 2
.def int DIR_LEFT = 3
.def int DIR_RIGHT = 4
#define VALID_FACING_DIRS DIR_UP | DIR_DOWN

#define SCRATCH_MAX 8
; temporary memory that can be used 
; by routines as they see fit
scratch: .adv SCRATCH_MAX

; 2 bytes for debug inspection
; like a watch but in ram 
dbg: .adv 2

; ====================
; Map buffer
; ====================

mapbuf: .adv MAP_SIZE
; contains map flags, one byte per tile
mapflags: .adv MAP_SIZE

; the vram update stack is a simple 
; display list of vram update that can be 
; written to at any time to update any tile 
; on the screen.
; it is then read and drawn during vblank until the vram_update_ptr 
; reaches 0 or the max number allowed per frame is reached 

; max per frame
.def int VRAM_UPDATE_MAX  = 16  

#define VRAM_UPDATE_LEN 16

#define VRAM_UPDATE_ENTRY_LEN 3
.se 0
.de vram_update_addr, 2
.de vram_update_tile, 1

vram_update_idx: .adv 1
vram_update_buf: .adv VRAM_UPDATE_LEN * VRAM_UPDATE_ENTRY_LEN

; rectangle "struct" layout
.se 0
.de RY, 1
.de RX, 1
.de RW, 1
.de RH, 1

; rectangle params for collision check
r1: .adv 4
r2: .adv 4 
