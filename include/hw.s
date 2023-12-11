; register defs

; lcd y 
#define RLY 0xFF44 
#define RLCD 0xFF40

#define LCDCF_BGON 0b00000001
#define LCDCF_ON 0b10000000
#define LCDCF_OBJON 0b00000010

#define RBGP 0xFF47
#define ROBP0 0xFF48

; memory map 
.def int VRAM = 0x8000
.def int VRAM9000 = VRAM+0x1000
.def int SCRN0 = 0x9800
.def int SCRN1 = 0x9C00
.def int OAMRAM = 0xFE00
