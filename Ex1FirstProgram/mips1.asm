.psx
.create "mips1.bin", 0x80010000

.org 0x80010000 ; Entry Point Of Code
	;; C code:
	;; f = (g+h) - (i+j)
	;;
	;; let f, g, h, i and j be $s0, $s1, $s2, $s3 and $s4 respectively
	;; $t0 and $t1 are temporary registers
	add $t0, $s1, $s2  ; register $t0 contains g+h
	add $t1, $s3, $s4  ; register $t1 contains i+j
	sub $s0, $t0, $t1  ; f gets $t0 - $t1 
end:
	j	end

 .close
