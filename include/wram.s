; work ram
#define WRAM 0xC000
.org WRAM

#define WRAMLEN 0xFFF

inputs: .adv 1
prev_inputs: .adv 1

update_flags: .adv 1
frame: .adv 1

; max actors 
#define ACTMAX 16

; TODO: refactor actors once struct syntax is supported
; for now we just use math to access members
; e.g. load actor offset into hl
; then do a relative read at ACTY to get y position
; actor offsets
; bytes 0-3 are oam mirrors 
#define ACTX 0
#define ACTY 1
#define ACTTILE 2
#define ACTFLAGS 3

; which oam object the actor uses
#define ACTOBJ 0
#define ACTTYPE 1
; actor flags 
#define ACTFLAG 2
; index into the actor function table 
#define ACTFN 3

; oam shadow memory
actorsoam: .adv ACTMAX * 4
; actor specific flags 
actors: .adv ACTMAX * 4 
