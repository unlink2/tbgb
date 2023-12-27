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
; 10 actors max.
#define ACTMAX 10

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
soamallocflags: .adv OBJSMAX ; 40 bytes indicating the current allocation status of soam

.def int OAMDMAFN = 0xFF80 

; player actor pointer
actpl: .adv 2

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

; 4 bytes of tmp storage 
; that can be used by sub routines as needed 
tmp: .adv 4


; 4 function parameters 
; that can be used when registers are not
; sufficient to pass to a function
p0: .adv 2
p1: .adv 2
p2: .adv 2
p3: .adv 2

mapbuf: .adv MAP_SIZE 
