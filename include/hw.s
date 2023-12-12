; register defs

; lcd y 
#define RLY 0xFF44 
#define RLCD 0xFF40

#define LCDCF_BGON 0b00000001
#define LCDCF_ON 0b10000000
#define LCDCF_OBJON 0b00000010

#define RBGP 0xFF47
#define ROBP0 0xFF48

; P1: joy pad register
#define RP1 0xFF00
#define P1F5 0x00100000 ; set to 0 to get buttons 
#define P1F4 0x00010000 ; set to 0 to get dpad

.def int P1FDPAD = P1F5
.def int P1FBTN = P1F4
.def int P1FNONE = P1F5 | P1F4

; memory map 
.def int VRAM = 0x8000
.def int VRAM9000 = VRAM+0x1000
.def int SCRN0 = 0x9800
.def int SCRN1 = 0x9C00
.def int OAMRAM = 0xFE00
