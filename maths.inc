.scope maths


control := $20


.proc add ; ( first second -- result )

_scratch := control

	pha
	popa
	sta _scratch
	clc
	popa
	adc _scratch
	pusha
	pla
	rts
.endproc

.proc subtract ; ( first second -- result )

_scratch := control

	pha
	popa
	sta scratch
	popa
	clc
	sbc scratch
	pusha
	pla
	rts
.endproc


; http://6502org.wikidot.com/software-math-intdiv
; 8-bit / 8-bit = 8-bit quotient, 8-bit remainder (unsigned)
.proc divmod ; ( numerator denominator -- modulus quotient )

_numerator := control
_denominator := control + 1

_quotient := _numerator

	pha
	phx
	phy

	popa
	sta _denominator

	popa
	sta _numerator

	LDA #0
	LDX #8	; number of bits?
	ASL _numerator
L1:	ROL
	CMP _denominator
	BCC L2
	SBC _denominator
L2:	ROL _numerator
	DEX
	BNE L1

	pusha

	lda _quotient
	pusha

	ply
	plx
	pla

	RTS
.endproc

.proc div ; ( numerator denominator -- quotient )
	jsr divmod
	swap
	drop
	rts
.endproc

.proc mod ; ( numerator denominator -- modulus )
	jsr divmod
	drop
	rts
.endproc


; http://6502org.wikidot.com/software-math-intmul
; 8-bit * 8-bit = 8-bit product (signed or unsigned)

.proc multiply ; ( first second -- result )

first := control
second := control + 1

	pha
	phx

	popa
	sta second

	popa
	sta first

	LDX #8
L1:	ASL
	ASL first
	BCC L2
	CLC
	ADC second
L2:	DEX
	BNE L1
	pusha
	plx
	pla
	RTS
.endproc


.endscope	; maths
