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
	inc stack::stackp
.endmacro

; Conceptually derived from "over over"
.macro two_dup
	pha
	phx

	ldx stack::stackp
	inx
	inx
	lda 0,x
	dex
	dex
	sta 0,x
	inx
	lda 0,x
	dex
	dex
	sta 0,x
	dex
	stx stack::stackp
	
	plx
	pla
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

.ifpsc02
	phy

	inc stack::stackp	; back to tos
	lda (stack::stackp)	
	tay			; load and place in y

	inc stack::stackp	; tos - 1
	lda (stack::stackp)
	tax			; load and place in x

	tya
	sta (stack::stackp)	; save tos -> tos - 1

	dec stack::stackp	; back to tos

	txa
	sta (stack::stackp)	; save tos - 1 -> tos

	dec stack::stackp	; leave stack pointer as we found it

	ply
.endif
.ifp02
	popx
	popa
	pushx
	pusha
.endif
	plx
	pla

	rts
.endproc


.macro over
	pha
.ifp02
	phx
.endif
	_over
.ifp02
	plx
.endif
	pla
.endmacro

.macro _over
.ifpsc02
	inc stack::stackp
	inc stack::stackp
	lda (stack::stackp)
	dec stack::stackp
	dec stack::stackp
	sta (stack::stackp)
	dec stack::stackp
.endif
.ifp02
	inc stack::stackp
	inc stack::stackp
	ldx stack::stackp
	lda 0,x
	dec stack::stackp
	dec stack::stackp
	ldx stack::stackp
	sta 0,x
	dec stack::stackp
.endif
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
