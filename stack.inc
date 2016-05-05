.scope stack

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
	stx stack::savex
	ldx stack::stackp
	sta 0,x
	dex
	stx stack::stackp
	ldx stack::savex
.endmacro

.macro popa
	stx stack::savex
	ldx stack::stackp
	inx
	stx stack::stackp
	lda 0,x
	pha
	ldx stack::savex
	pla
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


.endscope	; stack
