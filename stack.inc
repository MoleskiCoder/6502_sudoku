.scope stack

control := $10

stackh = $02
stackp = control

addrl := stackp + 1
addrh := addrl + 1
addr := addrl

savex := addrh + 3


; Initialise the stack to an empty state

.proc _init
	pha
	lda #$ff
	sta stackp
	lda stackh
	sta addrh
	lda #0
	sta stackl
	pla
	rts
.endproc


.proc pusha
	stx savex
	ldx stackp
	sta (addr),x
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
	lda (addr),x
	ldx savex
	rts
.endproc


.proc pushx
	pha
	txa
	jsr pusha
	pla
	rts
.endproc


.proc popx
	pha
	jsr popa
	tax
	pla
	rts
.endproc


.proc pushy
	pha
	tya
	jsr pusha
	pla
	rts
.endproc


.proc popy
	pha
	jsr popa
	tay
	pla
	rts
.endproc


.endscope	; stack
