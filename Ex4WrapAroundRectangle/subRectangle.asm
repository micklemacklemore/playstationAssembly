;; subRectangle.asm
;; ------------------
;;
;; author: michael mason
;;
;; description:
;; ------------
;; subroutine to draw a rectangle.
;; using armips assembler
;;
.psx
.create "subRectangle.bin", 0x80010000

.org 0x80010000 ; Entry point for user code

main: 

;; code for setting up display and drawing area
;; --------------------------------------------

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

;li $t0, 0xE403BD3F      ; 0xE4
;sw $t0, 0x1810($s0)     ; Set Drawing Area Bottom Right X2=319, Y2=239

li $t0, 0xE401EC7F      ; 0xE4
sw $t0, 0x1810($s0)     ; Set Drawing Area Bottom Right X2=127, Y2=123

li $t0, 0xE5000000      ; 0xE5
sw $t0, 0x1810($s0)     ; Set Drawing Offset X=0, Y=0       ( useful especially if you want to draw from the center?? )

;; Question: what is the difference between the display range and the drawing area??

;; draw rectangle
;; --------------

;; clear display area
li $s0, 0x00A88B28
li $s1, 0
li $s2, 0
li $s3, 400
li $s4, 400
jal sub_drawRectangle
nop

li $s0, 0x00B06A74
li $s1, 50
li $s2, 5
li $s3, 10
li $s4, 5
jal sub_drawRectangle
nop

li $s0, 0x004538E8
li $s1, 10
li $s2, 10
li $s3, 50
li $s4, 40
jal sub_drawRectangle
nop

li $s0, 0x0030CEFF
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
;; $s3 = x-size (16-bit)  Xsiz
;; $s4 = y-size (16-bit)  Ysiz
sub_drawRectangle:
x_too_big:
    ;; if x-coord > 127
    li $t0, 127
    blt $s1, $t0, x_is_negative
    nop
    sub $s1, $s1, $t0

    ;; if x-coord <= 0
x_is_negative:
    bge $s1, $zero, y_too_big
    nop
    add $s1, $s1, $t0

    ;; if y-coord > 123
y_too_big:
    li $t0, 123
    blt $s2, $t0, y_is_negative
    nop
    sub $s2, $s2, $t0

    ;; if y coord <= 0
y_is_negative:
    bge $s2, $zero, sub_drawRectangle_start
    nop
    add $s2, $s2, $t0

sub_drawRectangle_start:
    li $t0, 0x1f800000
    ;; color == make sure the first byte is zero and draw rectangle command to the gpu
    li $t1, 0x00FFFFFF
    and $s0, $s0, $t1
    lui $t1, 0x6000
    or $t1, $t1, $s0     ; $t1 = command + color
    sw $t1, 0x1810($t0)  ; send to gpu

    ;; add x and y coords together into $t1 and send to gpu
    ;; vertex (0xYyyyXxxx)
    sll $t5, $s2, 16   ;; $s2 = 0xYyyy0000
    or $t1, $s1, $t5   ;; $t1 = 0xYyyyXxxx
    sw $t1, 0x1810($t0)  ; send to gpu 

    ;; add width + height and sent to gpu
    ;; width+height (0xYsizXsiz)
    add $t2, $s1, $s3  ;; $t2 = xxxx + xsiz
    addi $t2, $t2, -127 
    add $t3, $s2, $s4   ;; $t3 = Yyyy + Ysiz
    addi $t3, $t3, -123    
    sll $s4, $s4, 16    ;; $s4 = 0xYsiz0000
    or $t1, $s4, $s3    ;; $t1 = 0xYsizXsiz
    sw $t1, 0x1810($t0)  ; send to gpu 
xwrap:
    blt $t2, $zero, ywrap  ;; if (Xxxx + Xsiz) -127 < 0 then goto ywrap
    nop 
    ;; draw wrap rectangle x
    ;; color
    lui $t1, 0x6000
    or $t1, $t1, $s0     ; $t1 = command + color
    sw $t1, 0x1810($t0)  ; send to gpu
    ;; starting coords (Yyyy0000)
    sw $t5, 0x1810($t0)  ; send to gpu 
    ;; size
    or $t1, $s4, $t2
    sw $t1, 0x1810($t0)  ; send to gpu 
ywrap:
    blt $t3, $zero, sub_drawRectangle_ret
    nop
    ;; draw wrap rectangle y
    ;; color
    lui $t1, 0x6000
    or $t1, $t1, $s0     ; $t1 = command + color
    sw $t1, 0x1810($t0)  ; send to gpu
    ;; starting coords (0000Xxxx)
    sw $s1, 0x1810($t0)  ; send to gpu 
    ;; size
    sll $t3, $t3, 16     ; Ysiz0000
    or $t5, $t3, $s3     ; YsizXsiz
    sw $t5, 0x1810($t0)  ; send to gpu 
xywrap:
    ;; draw wrap rectangle xy
    ;; color
    lui $t1, 0x6000
    or $t1, $t1, $s0     ; $t1 = command + color
    sw $t1, 0x1810($t0)  ; send to gpu
    ;; starting coords (00000000)
    sw $zero, 0x1810($t0)  ; send to gpu 
    ;; size
    sw $t5, 0x1810($t0)  ; send to gpu 
sub_drawRectangle_ret:
    jr $ra
    nop

.close