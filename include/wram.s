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

; actor memory layout
.se 0
.de actflags, 1
.de actobj, 1
.de acttype, 1
.de actfn, 2
.de actunused, 1
.de actx, 1
.de acty, 1
.de acttile, 1
.de actoamflags, 1

; actors falgs 
#define ACT_FACTIVE 0b00000001

; actor types 
#define ACT_TPLAYER 0x01

; player actor pointer
actpl: .adv 2

; actor memory 
acttbl: .adv ACTMAX * ACTSIZE
