        .setcpu "6502"

        .segment "OS"

.include "library.inc"

scratch := 80

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

;int move2x(int n) {
;	return n % BOARD_SIZE;
;}

;int move2y(int n) {
;	return n / BOARD_SIZE;
;}

.proc move2xy
	sta library::maths::numerator
	lda #BOARD_SIZE
	sta library::maths::denominator
	jsr library::maths::divmod
	tay
	ldx library::maths::quotient
	rts
.endproc

;int xy2move(int x, int y) {
;	return y * BOARD_SIZE + x;
;}

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

;int move2row_start(int n) {
;	return move2y(n) * BOARD_SIZE;
;}

.proc move2row_start
	sta scratch
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
	lda scratch
	rts
.endproc

;int move2column_start(int n) {
;	return move2x(n);
;}

.proc move2column_start
	sta scratch
	txa
	pha
	tya
	pha
	jsr move2xy
	pla
	tay
	pla
	tax
	lda scratch
	rts
.endproc

;int box_side_start(int n) {
;	return n - (n % BOX_SIZE);
;}

;int move2box_start(int n) {
;	int x = move2x(n);
;	int xbox = box_side_start(x);
;	int y = move2y(n);
;	int ybox = box_side_start(y);
;	return xy2move(xbox, ybox);
;}

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
