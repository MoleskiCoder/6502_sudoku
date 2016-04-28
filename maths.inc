.scope maths


control := $20


; http://6502org.wikidot.com/software-math-intdiv

; 8-bit / 8-bit = 8-bit quotient, 8-bit remainder (unsigned)

; Inputs:
; maths::numerator = 8-bit numerator
; maths::denominator = 8-bit denominator
; Outputs:
; maths::quotient = 8-bit quotient of numerator / denominator
; A = remainder of numerator / denominator

numerator := control
denominator := control + 1

quotient := numerator

.proc divmod
	TXA
	PHA
	TYA
	PHA
	LDA #0
	LDX #8	; number of bits?
	ASL numerator
L1:	ROL
	CMP denominator
	BCC L2
	SBC denominator
L2:	ROL numerator
	DEX
	BNE L1
	STA numerator
	PLA
	TAY
	PLA
	TAX
	LDA numerator
	RTS
.endproc


; http://6502org.wikidot.com/software-math-intmul

; 8-bit * 8-bit = 8-bit product (signed or unsigned)

; Inputs:
; maths::first = 8-bit integer
; maths::second = 8-bit integer
; Output:
; A = product of first * second
; Note that it is not necessary to initialize the accumulator!

first := control
second := control + 1

.proc multiply
	TXA
	PHA
	LDX #8
L1:	ASL
	ASL first
	BCC L2
	CLC
	ADC second
L2:	DEX
	BNE L1
	STA first
	PLA
	TAX
	LDA first
	RTS
.endproc


.endscope	; maths
