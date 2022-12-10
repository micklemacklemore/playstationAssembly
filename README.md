# playstationAssembly
A repository that contains various coding exercises for self-teaching MIPS assembly on the Sony Playstation 1! All work here is done in my own time,
on top of all the graduate school homework I have!!

# Table of Contents
  * [Little Demonstration ("Wow it works!")](#little-demonstration---wow-it-works---)
  * [Helpful resources](#helpful-resources)
    + [Playstation 1 Specific](#playstation-1-specific)
    + [MIPS / Computer Architecture specific](#mips---computer-architecture-specific)
- [Repo overview](#repo-overview)
  * [Ex 1: First Program](#ex-1--first-program)
  * [Ex 2: Draw Rectangle](#ex-2--draw-rectangle)
  * [Ex 3: Rectangle Subroutine<a name="Exercise-3"></a>](#ex-3--rectangle-subroutine-a-name--exercise-3----a-)
  * [Ex 4: Rectangle Wrap Around](#ex-4--rectangle-wrap-around)
  * [Ex 5: Pong (almost...)](#ex-5--pong--almost-)
      - [The code now runs in a loop!](#the-code-now-runs-in-a-loop-)
      - [I finally got around to using a stack!](#i-finally-got-around-to-using-a-stack-)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

    
## Little Demonstration ("Wow it works!")

https://user-images.githubusercontent.com/56715549/202925943-14e1d2e3-92c4-43d5-98b4-3df40628980b.mp4

## Helpful resources

### Playstation 1 Specific

* Very helpful overview of the Playstation 1 architecture and MIPS processor:
https://youtu.be/MPXpH2hxuNc

* Detailed documentation of the Playstation 1 memory map by nocash:
http://problemkaputt.de/psx-spx.htm

* A revised version of nocash's documentation by Nicolas Noble:
https://psx-spx.consoledev.net/

* Playstation 1 C Programming tutorial series by lameguy64:
http://lameguy64.net/tutorials/pstutorials/

* Amazing MIPS programming examples on the Playstation by Peter Lemon:
https://github.com/PeterLemon/PSX

### MIPS / Computer Architecture specific

LOOK AT ALL MY BOOKS!!

* Computer Organization and Design MIPS Edition: The Hardware/Software Interface 6th Ed by Patterson & Hennessy
* See MIPS Run 1st Ed by Sweetman
* MIPS Assembly Language Programming for Harvard CS50 by Daniel J. Ellard

![IMG_1842](https://user-images.githubusercontent.com/56715549/202926451-c568c68e-9181-4b08-a10b-68caa167810f.jpg)

# Repo overview

## Ex 1: First Program

**"OK, so how do I actually get any code to run on the Playstation 1?"**

This very simple exercise was answering that question. It's a simple MIPS program that adds two numbers together:

'pseudo' C code: 

```C
f = (g+h) - (i+j) ;
```

MIPS code:

```Assembly
.psx
.create "mips1.bin", 0x80010000

.org 0x80010000 ; Entry Point Of Code
	add $t0, $s1, $s2  ; register $t0 contains g+h
	add $t1, $s3, $s4  ; register $t1 contains i+j
	sub $s0, $t0, $t1  ; f gets $t0 - $t1 	

;; end the program by putting it into an infinite loop! No fancy operating system 
;; (only BIOS) so how else are you gonna 'end' the program??
end:
	j	end

 .close
```

As you can see, the entry point for a program on the playstation is at `0x80010000`. This is the beginning of CACHED user memory. Cached memory actually starts at `0x80000000` but sony uses the first 64k of memory to run the BIOS (stuff like run the PS1 logo, check the CD).

More information about memory available here: https://psx-spx.consoledev.net/memorymap/

Since we print nothing to the actual screen... I'm instead showing you a screenshot of my Playstation emulator's CPU debugger. Here is my program on the emulated Playstation's memory! There is some extra code there because I was playing around with things.. but you can see how it ends with the `j` instruction. The program 'stops' there.

![Ex1](https://user-images.githubusercontent.com/56715549/202927548-0098405d-69b7-4725-b777-a9640dd8c200.png)

## Ex 2: Draw Rectangle
This is a little more fun. I started looking at the Playstation's GPU. Through memory, you can send commands to the GPU to draw stuff. There is a specific command for drawing rectangles. I think usually this command is used for drawing sprites because there looks like there's some options for drawing the rectangle with an alpha texture...

This was quite difficult only because, before you can actually draw anything, you need some boiler plate code to set up the:

1. 'display settings' (i.e. settings for a person's television... are you using NTSC or PAL? What's you TV resolution? How fast does your TV scan pixels from left to right?)

```assembly
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
```

2. The 'drawing area'. The Playstation 1 has about 1 Megabyte of video memory. You can use up to a certain amount of that to that actually display on the TV. Here you can also set things like the color depth (up to 24 bit color?) and tell the GPU where you place your textures.

```assembly
li $t0, 0xE1000508      ; 0xE1 
sw $t0, 0x1810($a0)     ; Drawing To Display Area Allowed Bit 10, Texture Page Colors = 15BPP Bit 7..8, Texture Page Y Base = 0 Bit 4, Texture Page X Base = 512 Bit 0..3

li $t0, 0xE3000000      ; 0xE3
sw $t0, 0x1810($a0)     ; Set Drawing Area Top Left X1=0, Y1=0

li $t0, 0xE403BD3F      ; 0xE4
sw $t0, 0x1810($a0)     ; Set Drawing Area Bottom Right X2=319, Y2=239

li $t0, 0xE5000000      ; 0xE5
sw $t0, 0x1810($a0)     ; Set Drawing Offset X=0, Y=0       ( useful especially if you want to draw from the center?? Recall OpenGL! )
```

Then, drawing commands are actually pretty straight forward, as long as you know hex and binary, and where to put all the individual bits for the GPU command! AND... where to store it in memory!

```assembly
li $a0, 0x1f800000      ; base address for I/O mapped memory

;; draw yellow rectangle
;; load draw command and parameters to draw rectangle
li $s1, 0x6000FFFF  ; command for drawing yellow rectangle
li $s2, 0x00320064  ; width+height of rectangle
li $s3, 0x000A000A  ; coords at x = 10, y = 10

sw $s1,   0x1810($a0)      ; 1. command + color
sw $s3,   0x1810($a0)      ; 2. coords of rectangle
sw $s2,   0x1810($a0)      ; 3. width + height of rectangle
```

![Ex2DrawRectangle](https://user-images.githubusercontent.com/56715549/202927558-680d794b-9b86-4012-a5ca-3bb671dc5bee.png)


## Ex 3: Rectangle Subroutine<a name="Exercise-3"></a>
Here I'm just learning how subroutines (a.k.a. functions) are done in MIPS. So I can convieniently create a little function that draws simple rectangles pretty straightforwardly!

There's one weird quirk about 80s/90s MIPS CPU's... they have this thing called a 'delay slot'. In typical assembly, if you want to `goto` or `jump` to anywhere in code, theres a simple instruction for it... something like `jump <to label>` or something. On a MIPS R3000 chip, you need to be careful about what you put in the next line! Let me show you:

```assembly
;; draw a yellow rectangle
li $s0, 0x0000FFFF
li $s1, 120
li $s2, 100
li $s3, 27
li $s4, 10
jal sub_drawRectangle   ; <--- 'jump' to my function 'sub_drawRectangle'
nop                     ; <--- this line will still evaluate before you jump to 'sub_drawRectangle'!

end: 
    j end
    nop
```

You have to make sure that next line isn't going to affect anything in your function. So typically you might put in a 'no op' instruction like `nop`. It's like a 'nothing' instruction that isn't supposed to do anything. It's like `pass` keyword in python. 

TADAA, now we can draw more rectangles!

![Ex3SubRectangle](https://user-images.githubusercontent.com/56715549/202927563-c1391fce-45da-4066-9435-b6a31efc9c98.png)


## Ex 4: Rectangle Wrap Around

This is an extension of the last exercise. What if I want my rectangles to 'wraparound' the screen, like the spaceship Asteroids or Mario & Luigi in Mario Bros.?

More info on Wrap-around in video games: https://en.wikipedia.org/wiki/Wraparound_(video_games)

And so I extended by sub_drawRectangle subroutine to do that...

![Ex4WrapAroundRectangle](https://user-images.githubusercontent.com/56715549/202927567-5c02c0d7-251d-4b41-a093-a0113e8669f2.png)


## Ex 5: Pong (almost...)
How are controller peripherals managed through memory-mapped I/O? Knowing this, can we move some rectangles?

![record](https://user-images.githubusercontent.com/56715549/206827782-ebd05a1e-f15d-4804-992a-55c4a49cd958.gif)

This is about as far as I got! I can't say much about the code other than it's getting a bit hairy. 

Things of note:

#### The code now runs in a loop! 

+ Within the loop, it checks for player input, and if the player has pressed the up, down, left or right buttons, the x and y coordinates of the rectangle are updated accordingly. 
  + the x and y coordinates are stored in data memory! More specifically it's stored in the Playstation's "scratchpad", which is the machine's fastest cache memory. Not exactly sure how cached memory works but I guess it's the fastest *shrug*
  + the loop can only go as fast as the GPU: GPU must finish drawing to the video buffer / display first before we can continue the loop, otherwise we get weirdness and "flickering"
  
#### I finally got around to using a stack! 
+ MIPS chips by convention uses registers 29 & 30 as the stack pointer and the frame pointer!
+ the stack pointer is initialised by (playstation BIOS? the assembler?) BUT it's up to the programmer (me) to update the stack pointer if I need to push anything on the stack or pop it  
  
pseudo-code assembly below:

```asm
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

;; set 'x pos' and store in scratch pad
li $t0, 10
sw $t0, 16(s0)

;; set 'y pos' and store in scratch pad
li $t1, 100
sw $t1, 20(s0)

loop:
PRESSRIGHT:
  ; press right? update x pos =+ 1

PRESSLEFT:
  ; press right? update x pos =- 1

PRESSUP:
  ; press up? update y pos =+ 1

PRESSDOWN:
 ; press down? update y pos =- 1

draw: 
   ; finally draw the rectangle with updated 'y pos' and 'x pos'
   

Wait:                   ; Wait For Vertical Retrace Period & Store XOR Pad Data
   ; loop within loop that waits for the GPU to 
   ; finish drawing

j loop
nop
```
