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
	txa
	pusha
.endmacro

.macro popx
	popa
	tax
.endmacro

.macro pushy
	tya
	pusha
.endmacro

.macro popy
	popa
	tay
.endmacro

; Finish of the handy macros!


control := $10

stackp := control

.ifp02
savex := stackp + 1
.endif


; Initialise the stack to an empty state
.proc init

	pha

	lda #$ff
	sta stackp

	pla
	rts
.endproc


.endscope	; stack
