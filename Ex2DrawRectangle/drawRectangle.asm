;; drawRectangle.asm
;; ------------------
;;
;; author: michael mason
;;
;; description:
;; -----
;; MIPS assembly for playstation 1 to draw a rectangle. Using 
;; armips assembler. 
;;
.psx
.create "drawRectangle.bin", 0x80010000

.org 0x80010000 ; Entry point for playstation

main: 

;; code for setting up display and drawing area
;; --------------------------------------------

li $a0, 0x1f800000      ; base address for I/O mapped memory

; Set display settings (GP1 commands)

; reset gpu
sw $zero, 0x1814($a0)   ; send command 0x00000000 to reset GPU

; enable display
lui $t0, 0x0300         ; command 0x03000000 that enables display
sw $t0, 0x1814($a0)     ; send command to GP1

li $t0, 0x08000001      ; 0x08 | 0000 | 0001
sw $t0, 0x1814($a0)     ; set display mode: 320x240, 15BPP, NTSC

li $t0, 0x06C60260      ; 0x06 | C60 | 260   
sw $t0, 0x1814($a0)     ; set horizontal display range from 0x260 to 0xC60 (0x260 + 320*8)

li $t0, 0x07042018      ; 0x07 | 042 | 018
sw $t0, 0x1814($a0)     ; set vertical display range (0x18 (0x88-224/2) to 0x42(0x88+224/2))
                        ; 0x88 represents the middle scan line on NTSC TV's. if it was PAL, it would be `0xA3 +/- 264/2`

; Setup Drawing Area (GP0 rendering commands)

li $t0, 0xE1000508      ; 0xE1 
sw $t0, 0x1810($a0)     ; Drawing To Display Area Allowed Bit 10, Texture Page Colors = 15BPP Bit 7..8, Texture Page Y Base = 0 Bit 4, Texture Page X Base = 512 Bit 0..3

li $t0, 0xE3000000      ; 0xE3
sw $t0, 0x1810($a0)     ; Set Drawing Area Top Left X1=0, Y1=0

li $t0, 0xE403BD3F      ; 0xE4
sw $t0, 0x1810($a0)     ; Set Drawing Area Bottom Right X2=319, Y2=239

li $t0, 0xE5000000      ; 0xE5
sw $t0, 0x1810($a0)     ; Set Drawing Offset X=0, Y=0       ( useful especially if you want to draw from the center?? )

;; Question: what is the difference between the display range and the drawing area??

;; draw rectangle
;; --------------

;; load draw command and parameters to draw rectangle
li $s1, 0x6000FFFF  ; command for drawing blue rectangle
li $s2, 0x000400FA  ; width+height of rectangle (10 x 10)

sw $s1,   0x1810($a0)      ; 1. command + color
sw $zero, 0x1810($a0)      ; 2. coords of rectangle
sw $s2,   0x1810($a0)      ; 3. width + height of rectangle

.close