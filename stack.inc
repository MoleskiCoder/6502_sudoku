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
	popa
	pusha
.endmacro

.macro over
	jsr stack::over
.endmacro

.macro dup
	pha
	top
	pusha
	pla
.endmacro

.macro swap
	jsr stack::swap
.endmacro

.macro drop
	pha
	popa
	pla
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
savex := stackp + 1


; Return the position of the stack in A
.proc position
	lda stackp
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

	pha

	lda #$ff
	sta stackp

	pla
	rts
.endproc


.proc pusha
	stx savex
	ldx stackp
	sta 0,x
	dex
	stx stackp
	ldx savex
	rts
.endproc


.proc popa
	stx savex
	ldx stackp
	inx
	stx stackp
	lda 0,x
	pha
	ldx savex
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
	top
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
