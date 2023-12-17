; work ram
#define WRAM 0xC000
.org WRAM

#define WRAMLEN 0xFFF

; max actors
; 10 actors max.
#define ACTMAX 10

; actor memory layout
.se 0
.de actflags, 1
.de actunused1, 1
.de acttype, 1
.de actfn, 2
.de actrunused2, 1
; postions are x.xl and y.yl 
; fixed point integers 
.de actyl, 1 
.de actxl, 1
.de acty, 1
.de actx, 1
.de actchr, 1
.de actoamflags, 1
.de ACTSIZE, 0

; actor shadow oam 
.se 0 
.de soamy, 1
.de soamx, 1
.de soamchr, 1
.de soamflags, 1
.de SOAMSIZE , 0

; shadow oam
; at the end of the update cycle, each active actor 
; may allocate an object from the shadow oam
; the data for x, y, char and flags are then copied over to the apropriate tile 
; the shadow oam is then dma'd to the real oam in vblank
soam: .adv OBJSMAX * SOAMSIZE
soamallocflags: .adv OBJSMAX ; 40 bytes indicating the current allocation status of soam

.def int OAMDMAFN = 0xFF80 

; actors falgs 
#define ACT_FACTIVE 0b00000001

; actor types 
#define ACT_TPLAYER 0x01

; player actor pointer
actpl: .adv 2

; actor memory 
acttbl: .adv ACTMAX * ACTSIZE

#define SOAM_FACTIVE 0b00000001
#define SOAM_EINVAL 0xFF

; global offset for soam to ensure object cycling is happening consistently
soamgoffset: .adv 1

.def int DMAFN = 0xFF80 


inputs: .adv 1
prev_inputs: .adv 1

update_flags: .adv 1
frame: .adv 1


