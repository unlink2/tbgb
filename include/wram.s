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
#define ACTSIZE 10

; TODO: refactor actors once struct syntax is supported
; for now we just use math to access members
; e.g. load actor offset into hl
; then do a relative read at ACTY to get y position
; actor offsets
; which oam object the actor uses
#define ACTFLAGS 0
#define ACTOBJ 1
#define ACTTYPE 2
; actor upadte function pointer (2 bytes)
#define ACTFN 3
#define ACTUNUSED 5
; oam mirrors 
#define ACTOX 6
#define ACTY 7
#define ACTTILE 8
#define ACTOAMFLAGS 9

; actors falgs 
#define ACT_FACTIVE 0b00000001

; actor types 
#define ACT_TPLAYER 0x01

; actor memory 
acttbl: .adv ACTMAX * ACTSIZE
acttbl_end:
