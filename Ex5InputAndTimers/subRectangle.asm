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

OutdatedPadInitAndStart: 
  li t1,0x15
  li a0,0x20000001
  li t2,0xB0
  li a1, 0x1f800000 ; Set Pad Buffer Address To Automatically Update Each Frame
  jalr t2 ; Jump To BIOS Routine OutdatedPadInitAndStart()
  nop ; Delay Slot

;; make room on stack for arguments
addi $sp, $sp, -20
li $s0, 0x1f800000

;; clear data at 'input' address
sw $zero, 8(s0) 
sw $zero, 12(s0) 

;; set 'x pos' and store in scratch pad
li $t0, 10
sw $t0, 16(s0)

;; set 'y pos' and store in scratch pad
li $t1, 100
sw $t1, 20(s0)

loop:
PRESSRIGHT:
    lw $t0, 8(s0)  ; Load Input Data Word
    nop 
    andi $t0, 0x2000  ; T0 = Input Status
    beqz $t0, PRESSLEFT
    nop 
    lw $t0, 16(s0)
    nop
    addi $t0, $t0, 2
    sw $t0, 16(s0)
    nop
 

PRESSLEFT:
    lw $t0, 8(s0)  ; Load Input Data Word
    nop 
    andi $t0, 0x8000  ; T0 = Input Status
    beqz $t0, PRESSUP
    nop 
    lw $t0, 16(s0)
    nop
    addi $t0, $t0, -2
    sw $t0, 16(s0)
    nop

PRESSUP:
    lw $t0, 8(s0)  ; Load Input Data Word
    nop 
    andi $t0, 0x1000  ; T0 = Input Status
    beqz $t0, PRESSDOWN
    nop 
    lw $t0, 20(s0)
    nop
    addi $t0, $t0, -2
    sw $t0, 20(s0)
    nop

PRESSDOWN:
    lw $t0, 8(s0)  ; Load Input Data Word
    nop 
    andi $t0, 0x4000  ; T0 = Input Status
    beqz $t0, draw
    nop 
    lw $t0, 20(s0)
    nop
    addi $t0, $t0, 2
    sw $t0, 20(s0)
    nop

draw:
    ;; clear display area
    lui $t0, 0x00A8
    ori $t0, 0x8B28
    and $t1, $t1, $zero
    and $t2, $t2, $zero
    ori $t3, $zero, 400
    ori $t4, $zero, 400
    sw $t4, 16($sp)
    sw $t3, 12($sp)
    sw $t2, 8($sp)
    sw $t1, 4($sp)
    sw $t0, 0($sp)
    jal sub_drawRectangle
    nop

    li $t0, 0x00B06A74
    addi $t1, $zero, 50
    li $t2, 5
    li $t3, 10
    li $t4, 5
    sw $t4, 16($sp)
    sw $t3, 12($sp)
    sw $t2, 8($sp)
    sw $t1, 4($sp)
    sw $t0, 0($sp)
    jal sub_drawRectangle
    nop

    li $t0, 0x004538E8
    li $t1, 10
    li $t2, 10
    li $t3, 50
    li $t4, 40
    sw $t4, 16($sp)
    sw $t3, 12($sp)
    sw $t2, 8($sp)
    sw $t1, 4($sp)
    sw $t0, 0($sp)
    jal sub_drawRectangle
    nop

    

    li $t0, 0x0030CEFF
    lw $t1, 16(s0)
    lw $t2, 20(s0)
    li $t3, 27
    li $t4, 10
    sw $t4, 16($sp)
    sw $t3, 12($sp)
    sw $t2, 8($sp)
    sw $t1, 4($sp)
    sw $t0, 0($sp)
    jal sub_drawRectangle
    nop

Wait:                   ; Wait For Vertical Retrace Period & Store XOR Pad Data
    lw $t0,0(s0)        ; Load Pad Buffer
    nop                 ; Delay Slot
    beqz $t0, Wait      ; IF (Pad Buffer == 0) Wait
    nor $t0, $zero      ; NOR Compliment Pad Data Bits (Delay Slot)
    sw $zero, 0(s0)     ; Store Zero To Pad Buffer
    sw t0, 8(s0)     ; Store Pad Data

j loop
nop

addi $sp, $sp, 20

;; sub_drawRectangle
;; -----------------
;; input
;; $a0 = color (24-bit)   00BbGgRr
;; $a1 = x-coord (16-bit) Xxxx
;; $a2 = y-coord (16-bit) Yyyy
;; $a3 = x-size (16-bit)  Xsiz
;; $a4 = y-size (16-bit)  Ysiz
sub_drawRectangle:
addi $fp, $sp, 0
addi $sp, $sp, -20   ; save registers $s0 to $s4 on the stack
sw $s0, 16($sp)
sw $s1, 12($sp)
sw $s2, 8($sp)
sw $s3, 4($sp)
sw $s4, 0($sp)

lw $s0, 0($fp)
lw $s1, 4($fp)
lw $s2, 8($fp)
lw $s3, 12($fp)
lw $s4, 16($fp)
nop

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
    lw $s4, 0($sp)
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    addi $sp, $sp, 16   ; pop saved registers $s0, 1, 2, 4 off the stack

    jr $ra
    nop

.close