.scope stack

.ifp02

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

.endif

.macro pusha
.ifpsc02
	sta (stack::stackp)
	dec stack::stackp
.endif
.ifp02
	stx stack::savex
	ldx stack::stackp
	sta 0,x
	dex
	stx stack::stackp
	ldx stack::savex
.endif
.endmacro

.macro popa
.ifpsc02
	inc stack::stackp
	lda (stack::stackp)
.endif
.ifp02
	stx stack::savex
	ldx stack::stackp
	inx
	stx stack::stackp
	lda 0,x
	pha
	ldx stack::savex
	pla
.endif
.endmacro

.macro pushx
	pha
	txa
	pusha
	pla
.endmacro

.macro popx
	pha
	popa
	tax
	pla
.endmacro

.macro pushy
	pha
	tya
	pusha
	pla
.endmacro

.macro popy
	pha
	popa
	tay
	pla
.endmacro

.macro top
	popa
	pusha
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

.ifp02
savex := stackp + 1
.endif

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


.macro over
	pha
	phx
	popa
	popx
	pushx
	pusha
	pushx
	plx
	pla
.endmacro


; Initialise the stack to an empty state
.proc init

	pha

	lda #$ff
	sta stackp

	pla
	rts
.endproc


.endscope	; stack
