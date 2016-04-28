//
// From: https://see.stanford.edu/materials/icspacs106b/H19-RecBacktrackExamples.pdf
//
// A straightforward port from C to 6502 assembler
//
// http://www.telegraph.co.uk/news/science/science-news/9359579/Worlds-hardest-sudoku-can-you-crack-it.html

        .setcpu "6502"

        .segment "OS"

.include "library.inc"

; Scratchpad area.  Not sure how long this will be.  Aliased within "proc" scope.

scratch := 80

; Some useful constants

UNASSIGNED := 0
BOX_SIZE := 3
BOARD_SIZE := 9
CELL_COUNT := (BOARD_SIZE * BOARD_SIZE)

puzzle:
	.byte 8, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 3, 6, 0, 0, 0, 0, 0
	.byte 0, 7, 0, 0, 9, 0, 2, 0, 0
	.byte 0, 5, 0, 0, 0, 7, 0, 0, 0
	.byte 0, 0, 0, 0, 4, 5, 7, 0, 0
	.byte 0, 0, 0, 1, 0, 0, 0, 3, 0
	.byte 0, 0, 1, 0, 0, 0, 0, 6, 8
	.byte 0, 0, 8, 5, 0, 0, 0, 1, 0
	.byte 0, 9, 0, 0, 0, 0, 4, 0, 0

;
; ** Move and grid position translation methods
;

.proc move2xy
	sta library::maths::numerator
	lda #BOARD_SIZE
	sta library::maths::denominator
	jsr library::maths::divmod
	tay
	ldx library::maths::quotient
	rts
.endproc


.proc xy2move
	sty library::maths::first
	lda #BOARD_SIZE
	sta library::maths::second
	jsr library::maths::multiply
	sta scratch
	txa
	clc
	adc scratch
	rts
.endproc


; ** Row, column and box start positions

.proc move2row_start

_n := scratch

	sta _n
	txa
	pha
	tya
	pha
	jsr move2xy
	sty library::maths::first
	lda #BOARD_SIZE
	sta library::maths::second
	jsr library::maths::multiply
	sta scratch
	pla
	tay
	pla
	tax
	lda _n
	rts
.endproc


.proc move2column_start

_n := scratch

	sta _n
	txa
	pha
	tya
	pha
	jsr move2xy
	pla
	tay
	pla
	tax
	lda _n
	rts
.endproc


.proc box_side_start

_n := scratch

	sta _n

	txa
	pha

	sta library::maths::numerator

	lda #BOX_SIZE
	sta library::maths::denominator
	jsr library::maths::divmod

	tax
	lda scratch
	stx scratch

	clc
	sbc scratch
	sta scratch

	pla
	tax

	lda scratch

	rts
.endproc


.proc move2box_start

_x := scratch
_y := _x + 1
_xbox := _y + 1
_ybox := _xbox + 1
_n := _ybox + 1

	sta _n

	txa
	pha

	tya
	pha

	jsr move2xy
	stx _x
	sty _y

	txa
	jsr box_side_start
	sta _xbox

	tya
	jsr box_side_start
	sta _ybox

	ldx _xbox
	ldy _ybox
	jsr xy2move
	sta _n

	pla
	tay

	pla
	tax

	lda _n

	rts
.endproc


; Function: is_used_in_row
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified row matches the given number.

.proc is_used_in_row

_number := scratch
_n := _number + 1
_savex := _n + 1

_offset := _savex + 1

	sta _number
	sty _n
	stx _savex
	tya
	jsr move2row_start
	sta _offset
	ldx _offset
	ldy #BOARD_SIZE
loop:
	lda puzzle,x
	cmp _number
	beq success
	inx
	dey
	bne loop
	lda #1		; failure, zero cleared
	pha
	jmp continue
success:
	lda #0		; success, zero flag
	pha
continue:
	ldx _savex
	pla
	rts
.endproc


; Function: is_used_in_column
; ---------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified column matches the given number.

.proc is_used_in_column

_number := scratch
_n := _number + 1
_savex := _n + 1

_offset := _savex + 1

	sta _number
	sty _n
	stx _savex
	tya
	jsr move2column_start
	sta _offset
	ldx _offset
	ldy #BOARD_SIZE
loop:
	lda puzzle,x
	cmp _number
	beq success

	txa
	clc
	adc #BOARD_SIZE
	tax

	dey
	bne loop
	lda #1		; failure, zero cleared
	pha
	jmp continue
success:
	lda #0		; success, zero flag
	pha
continue:
	ldx _savex
	pla
	rts
.endproc


; Function: is_used_in_box
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; within the specified 3x3 box matches the given number.

.proc is_used_in_box

_box_start := scratch
_x_box := _box_start + 1
_y_box := _x_box + 1
_offset := _y_box + 1

_number := _offset +1
_n := _number + 1

_savex := _n + 1

	sta _number
	sty _n
	stx _savex
	tya
	jsr move2box_start
	sta _box_start

	ldy #BOARD_SIZE
loop:
	tya
	pha

	sty maths::numerator
	lda #BOX_SIZE
	sta maths::denominator
	jsr maths::divmod

	jsr xy2move
	clc
	adc _box_start
	tax

	lda puzzle,x
	cmp _number
	beq success

	pla
	tay

	dey
	beq loop

	lda #1		; failure, zero cleared
	pha
	jmp continue
success:
	pla		; the dangling y push
	lda #0		; success, zero flag
	pha
continue:
	ldx _savex
	pla
	rts
.endproc


reset:
	jsr library::io::outstr
	.asciiz "Hello world,"

	jsr library::io::outstr
	.asciiz "Goodbye world"

	lda #80
	sta library::maths::numerator
	lda #9
	sta library::maths::denominator
	jsr library::maths::divmod

	ldx library::maths::quotient
	tay			; modulus


loop:   jmp     loop


nmi:    jmp     nmi

irq_brk: 
        jmp     irq_brk         ;

        .segment "VECTORS"

        .word   nmi             ; NMI
        .word   reset           ; RESET
        .word   irq_brk         ; IRQ/BRK
