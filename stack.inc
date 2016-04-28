.scope stack

control := $10

stackh = $02
stackp = control

addrl := stackp + 1
addrh := addrl + 1
addr := addrl

savey := addrh + 3


; Initialise the stack to an empty state

.proc _init
	pha
	lda #$ff
	sta stackp
	lda stackh
	sta addrh
	lda #0
	sta addrl
	pla
	rts
.endproc


.proc pusha
	sty savey
	ldy stackp
	sta (addr),y
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
	lda (addr),y
	ldy savey
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
