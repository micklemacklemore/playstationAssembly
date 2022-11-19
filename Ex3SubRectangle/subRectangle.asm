;; subRectangle.asm
;; ------------------
;;
;; author: michael mason
;;
;; description:
;; -----
;; subroutine to draw a rectangle.
;; using armips assembler
;;
.psx
.create "subRectangle.bin", 0x80010000

.org 0x80010000 ; Entry point for user code

main: 

;; code for setting up display and drawing area. this stuff is boiler plate
;; -------------------------------------------------------------------------

li $s0, 0x1f800000      ; $s0 = base address for I/O mapped memory

; Set display settings (GP1 commands)

; reset gpu
sw $zero, 0x1814($s0)   ; send command 0x00000000 to reset GPU

; enable display
lui $t0, 0x0300         ; command 0x03000000 that enables display
sw $t0, 0x1814($s0)     ; send command to GP1

li $t0, 0x08000001      ; 0x08 | 0000 | 0001
sw $t0, 0x1814($s0)     ; set display mode: 320x240, 15BPP, NTSC

li $t0, 0x06C60260      ; 0x06 | C60 | 260   
sw $t0, 0x1814($s0)     ; set horizontal display range from 0x260 to 0xC60 (0x260 + 320*8)

li $t0, 0x07042018      ; 0x07 | 042 | 018
sw $t0, 0x1814($s0)     ; set vertical display range (0x18 (0x88-224/2) to 0x42(0x88+224/2))
                        ; 0x88 represents the middle scan line on NTSC TV's. if it was PAL, it would be `0xA3 +/- 264/2`

; Setup Drawing Area (GP0 rendering commands)

li $t0, 0xE1000508      ; 0xE1 
sw $t0, 0x1810($s0)     ; Drawing To Display Area Allowed Bit 10, Texture Page Colors = 15BPP Bit 7..8, Texture Page Y Base = 0 Bit 4, Texture Page X Base = 512 Bit 0..3

li $t0, 0xE3000000      ; 0xE3
sw $t0, 0x1810($s0)     ; Set Drawing Area Top Left X1=0, Y1=0

li $t0, 0xE403BD3F      ; 0xE4
sw $t0, 0x1810($s0)     ; Set Drawing Area Bottom Right X2=319, Y2=239

li $t0, 0xE5000000      ; 0xE5
sw $t0, 0x1810($s0)     ; Set Drawing Offset X=0, Y=0       ( useful especially if you want to draw from the center?? )

;; Question: what is the difference between the display range and the drawing area??

;; draw rectangles!!
;; -----------------

;; clear display area
li $s0, 0x00000000
li $s1, 0
li $s2, 0
li $s3, 400
li $s4, 400
jal sub_drawRectangle
nop                    ; have to write a nop after every branch instruction.. as MIPS has something called a "delay slot".. mips runs instructions in parallel(?)

;; draw red rectangle
li $s0, 0x000000FF
li $s1, 50
li $s2, 5
li $s3, 10
li $s4, 5
jal sub_drawRectangle
nop

;; draw green rectangle
li $s0, 0x0000FF00
li $s1, 10
li $s2, 10
li $s3, 50
li $s4, 40
jal sub_drawRectangle
nop

;; draw yellow rectangle
li $s0, 0x0000FFFF
li $s1, 120
li $s2, 100
li $s3, 27
li $s4, 10
jal sub_drawRectangle
nop

end: 
    j end
    nop

;; sub_drawRectangle
;; -----------------
;; input
;; $s0 = color (24-bit)   00BbGgRr
;; $s1 = x-coord (16-bit) Xxxx
;; $s2 = y-coord (16-bit) Yyyy
;; $s3 = x-size (16-bit)   Xsiz
;; $s4 = y-size (16-bit)  Ysiz
sub_drawRectangle:
    li $t0, 0x1f800000

    ;; color == make sure the first byte is zero and draw rectangle command to the gpu
    li $t1, 0x00FFFFFF
    and $s0, $s0, $t1
    lui $t1, 0x6000
    or $t1, $t1, $s0     ; $t1 = command + color
    sw $t1, 0x1810($t0)  ; send to gpu

    ;; add x and y coords together into $t1 and send to gpu
    ;; vertex (0xYyyyXxxx)
    sll $s2, $s2, 16   ;; $s2 = 0xYyyy0000
    or $t1, $s1, $s2   ;; $t1 = 0xYyyyXxxx
    sw $t1, 0x1810($t0)  ; send to gpu 

    ;; add width + height and sent to gpu
    ;; width+height (0xYsizXsiz)
    sll $s4, $s4, 16   ;; $s2 = 0xYsiz0000
    or $t1, $s4, $s3   ;; $t1 = 0xYsizXsiz
    sw $t1, 0x1810($t0)  ; send to gpu 

    jr $ra
    nop

.close
