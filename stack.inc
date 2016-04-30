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


; Return the position of the stack in A
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
	plx
	pla
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
	pha
	ldy savey
	pla
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


.proc _tests

	ldx #0

push_pop_test:
	inx
	lda #$10
	pusha
	lda #$20
	popa
	cmp #$10
	beq top_test
	jmp fail

	nop
	nop

top_test:
	inx
	lda #$10
	pusha
	lda #$20
	jsr top
	cmp #$10
	beq top_test_continue
	jmp fail
top_test_continue:
	popa

	nop
	nop

swap_test:
	inx
	lda #$10
	pusha
	lda #$20
	pusha
	swap
	popa
	cmp #$10
	bne fail
	popa
	cmp #$20
	beq over_test
	jmp fail

	nop
	nop

over_test:
	inx
	lda #$10
	pusha
	lda #$20
	pusha
	over
	popa
	cmp #$10
	bne fail
	popa
	cmp #$20
	bne fail
	popa
	cmp #$10
	beq two_dup_test
	jmp fail

	nop
	nop

two_dup_test:
	inx

	lda #$10
	pusha
	lda #$20
	pusha

	two_dup

	popa
	cmp #$20
	beq two_dup_test_continue_1
	jmp fail

two_dup_test_continue_1:
	popa
	cmp #$10
	beq two_dup_test_continue_2
	jmp fail

two_dup_test_continue_2:
	popa
	cmp #$20
	beq two_dup_test_continue_3
	jmp fail

two_dup_test_continue_3:
	popa
	cmp #$10
	beq stack_depth_test
	jmp fail

stack_depth_test:
	jsr position
	cmp #$ff
	bne fail

success:
	ldx #0		; success marker!

fail:
	rts
.endproc

.endscope	; stack
