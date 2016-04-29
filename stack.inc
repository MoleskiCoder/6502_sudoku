.scope stack

; Handy macros, not obligatory!

.macro phx
	txa
	pha
.endmacro

.macro plx
	pla
	tax
.endmacro

.macro phy
	tya
	pha
.endmacro

.macro ply
	pla
	tay
.endmacro

.macro pusha
	jsr stack::pusha
.endmacro

.macro popa
	jsr stack::popa
.endmacro

.macro pushx
	jsr stack::pushx
.endmacro

.macro popx
	jsr stack::popx
.endmacro

.macro pushy
	jsr stack::pushy
.endmacro

.macro popy
	jsr stack::popy
.endmacro

.macro top
	jsr stack::top
.endmacro

.macro over
	jsr stack::over
.endmacro

.macro dup
	jsr stack::dup
.endmacro

.macro swap
	jsr stack::swap
.endmacro

.macro drop
	jsr stack::drop
.endmacro

.macro two_dup
	over
	over
.endmacro

.macro two_drop
	drop
	drop
.endmacro

; Finish of the handy macros!


control := $10

stackp := control
addrw := stackp + 1


.proc position
	lda stackp
	rts
.endproc


.proc top
	popa
	pusha
	rts
.endproc


.proc dup
	pha
	top
	pusha
	pla
	rts
.endproc


.proc drop
	pha
	popa
	pla
	rts
.endproc


.proc swap
	pha
	phx

	popx
	popa
	pushx
	pusha

	plx
	pla

	rts
.endproc


.proc over
	pha
	phx
	popa
	popx
	pushx
	pusha
	pushx
	phx
	pha
	rts
.endproc


; Initialise the stack to an empty state
.proc init

stackh = $02

addrl := addrw
addrh := addrl + 1

	pha

	lda #$ff
	sta stackp

	lda #stackh
	sta addrh

	lda #0
	sta addrl

	pla
	rts
.endproc


savey := addrw + 2

.proc pusha
	sty savey
	ldy stackp
	sta (addrw),y
	dey
	sty stackp
	ldy savey
	rts
.endproc


.proc popa
	sty savey
	ldy stackp
	iny
	sty stackp
	lda (addrw),y
	ldy savey
	rts
.endproc


.proc pushx
	pha
	txa
	pusha
	pla
	rts
.endproc


.proc popx
	pha
	popa
	tax
	pla
	rts
.endproc


.proc pushy
	pha
	tya
	pusha
	pla
	rts
.endproc


.proc popy
	pha
	popa
	tay
	pla
	rts
.endproc


.proc _test

	ldx #1
	jsr position
	cmp #$ff
	bne fail

	inx
	lda #$10
	pusha
	jsr position
	cmp #$fe
	bne fail
	lda #$20
	popa
	cmp #$10
	bne fail

	inx
	jsr position
	cmp #$ff
	bne fail
	lda #$10
	pusha
	lda #$20
	jsr top
	cmp #$10
	bne fail
	jsr position
	cmp #$fe
	bne fail
	jsr popa
	jsr position
	cmp #$ff
	bne fail

	ldx #0		; success marker!
fail:
	rts
.endproc

.endscope	; stack
