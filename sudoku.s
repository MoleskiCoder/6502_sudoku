;
; From: https://see.stanford.edu/materials/icspacs106b/H19-RecBacktrackExamples.pdf
;
; A straightforward port from C to 6502 assembler (although feeling like Forth!)
;

; Clock cycles: 2,080,575,831	17 minutes 20 seconds @ 2Mhz
;		1,999,549,983
;		1,966,492,180
;		1,916,084,161
;		1,622,811,358	~13 minutes @ 2Mhz
;		1,447,350,749	~12 minutes @ 2Mhz
;		1,407,594,238
;		1,084,202,324	~9 minutes @ 2Mhz
;		969,892,885	~8 minutes @ 2Mhz
;		890,722,830	~7 minutes @ 2Mhz
;		764,797,601	6 minutes 22 seconds @ 2Mhz
;		742,956,409
;		727,512,717	6 minutes @ 2Mhz
;		718,335,675
;		589,461,254	5 minutes @ 2MHz
;		500,568,464	~4 minutes @ 2Mhz
;		443,786,346	3 minutes 41 seconds @ 2Mhz
;		438,652,298
; 65sc02	295,111,758	2 minutes 27 @ 2Mhz

        .setcpu "6502"

        .segment "OS"

start:
	jmp reset

; http://www.telegraph.co.uk/news/science/science-news/9359579/Worlds-hardest-sudoku-can-you-crack-it.html

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


; Scratchpad area.  Not sure how long this will be.  Aliased within "proc" scope.

scratch := $80

; Some useful constants

UNASSIGNED = 0
BOX_SIZE = 3
BOARD_SIZE = 9
CELL_COUNT = (BOARD_SIZE * BOARD_SIZE)


.include "stack.inc"
.include "maths.inc"
.include "io.inc"


;
; ** Move and grid position translation methods
;

table_move2x:
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8

table_move2y:
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 1, 1, 1, 1, 1, 1, 1, 1, 1
	.byte 2, 2, 2, 2, 2, 2, 2, 2, 2
	.byte 3, 3, 3, 3, 3, 3, 3, 3, 3
	.byte 4, 4, 4, 4, 4, 4, 4, 4, 4
	.byte 5, 5, 5, 5, 5, 5, 5, 5, 5
	.byte 6, 6, 6, 6, 6, 6, 6, 6, 6
	.byte 7, 7, 7, 7, 7, 7, 7, 7, 7
	.byte 8, 8, 8, 8, 8, 8, 8, 8, 8

table_y2row_start:
	.byte 0
	.byte 9
	.byte 18
	.byte 27
	.byte 36
	.byte 45
	.byte 54
	.byte 63
	.byte 72

; ** Row, column and box start positions

table_move2row_start:
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 9, 9, 9, 9, 9, 9, 9, 9, 9
	.byte 18, 18, 18, 18, 18, 18, 18, 18, 18
	.byte 27, 27, 27, 27, 27, 27, 27, 27, 27
	.byte 36, 36, 36, 36, 36, 36, 36, 36, 36
	.byte 45, 45, 45, 45, 45, 45, 45, 45, 45
	.byte 54, 54, 54, 54, 54, 54, 54, 54, 54
	.byte 63, 63, 63, 63, 63, 63, 63, 63, 63
	.byte 72, 72, 72, 72, 72, 72, 72, 72, 72

table_move2box_start:
	.byte 0,  0,  0,  3,  3,  3,  6,  6,  6
	.byte 0,  0,  0,  3,  3,  3,  6,  6,  6
	.byte 0,  0,  0,  3,  3,  3,  6,  6,  6
	.byte 27, 27, 27, 30, 30, 30, 33, 33, 33
	.byte 27, 27, 27, 30, 30, 30, 33, 33, 33
	.byte 27, 27, 27, 30, 30, 30, 33, 33, 33
	.byte 54, 54, 54, 57, 57, 57, 60, 60, 60
	.byte 54, 54, 54, 57, 57, 57, 60, 60, 60
	.byte 54, 54, 54, 57, 57, 57, 60, 60, 60

.macro move2box_start ; ( n -- n )
	popx
	lda table_move2box_start,x
	pusha
.endmacro

; Function: is_used_in_row
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified row matches the given number.

.proc is_used_in_row ; ( number n -- A:f )
	popy
	ldx table_move2row_start,y
	popa
	ldy #BOARD_SIZE
loop:
	cmp puzzle,x
	beq success
	inx
	dey
	bne loop
	lda #1
success:
	rts
.endproc


; Function: is_used_in_column
; ---------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified column matches the given number.

.proc is_used_in_column ; ( number n -- A:f )

_number := scratch
	popy
	ldx table_move2x,y
	popa
	sta _number
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
fail:
	lda #1
success:
	rts
.endproc

table_is_used_in_box_x:
	.byte 0,  1,  2,  0,  1,  2,  0,  1,  2

table_is_used_in_box_y:
	.byte 0,  0,  0,  1,  1,  1,  2,  2,  2

; Function: is_used_in_box
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; within the specified 3x3 box matches the given number.

.proc is_used_in_box ; ( number n -- A:f )

_number := scratch

	move2box_start
	swap
	popa
	sta _number
	ldy #0
loop:
	dup

	clc
	lda table_is_used_in_box_x,y
	ldx table_is_used_in_box_y,y
	adc table_y2row_start,x

	sta maths::control
	popa
	adc maths::control

	tax

	lda puzzle,x
	cmp _number
	beq success
	iny
	cpy #BOARD_SIZE
	bne loop
fail:
	drop
	lda #1
	rts
success:
	drop
	lda #0
	rts
.endproc


; Function: is_available
; ----------------------
; Returns a boolean which indicates whether it will be legal to assign
; number to the given row, column location.As assignment is legal if it that
; number is not already used in the row, column, or box.

.proc is_available ; ( number n -- A:f )

; One temporary byte used in column + box checking
_x := scratch + 1
_y = _x + 1

	stx _x
	sty _y

	two_dup
	jsr is_used_in_row
	bne row_available
	jmp used_drop

row_available:
	two_dup
	jsr is_used_in_column
	bne column_available
	jmp used_drop

column_available:
	jsr is_used_in_box
	beq used

	ldx _x
	ldy _y
	lda #0
	rts

used_drop:
	two_drop
used:
	ldx _x
	ldy _y
	lda #1
	rts
.endproc


; Function: solve
; ---------------
; Takes a partially filled - in grid and attempts to assign values to all
; unassigned locations in such a way to meet the requirements for sudoku
; solution(non - duplication across rows, columns, and boxes).The function
; operates via recursive backtracking : it finds an unassigned location with
; the grid and then considers all digits from 1 to "board-size" in a loop.If a digit
; is found that has no existing conflicts, tentatively assign it and recur
; to attempt to fill in rest of grid.If this was successful, the puzzle is
; solved.If not, unmake that decision and try again.If all digits have
; been examined and none worked out, return false to backtrack to previous
; decision point.

.proc solve ; ( n -- A:f )

	phx

	popx
	cpx #CELL_COUNT
	bne _not_finished
	jmp _return_true

_not_finished:
	lda puzzle,x
	beq _begin_loop

	inx
	pushx
	jsr solve
	pusha
	plx
	popa
	rts

_begin_loop:
	ldy #1

_loop:
	pushy
	pushx
	jsr is_available
	bne _loop_continue

	tya
	sta puzzle,x

	pushy

	phx
	inx
	pushx
	plx

	jsr solve

	popy

	cmp #0
	beq _return_true

_loop_continue:
	iny
	cpy #BOARD_SIZE + 1
	bne _loop

.ifpsc02
	stz puzzle,x
.else
	lda #UNASSIGNED
	sta puzzle,x
.endif

_return_false:
	plx
	lda #1
	rts

_return_true:
	plx
	lda #0
	rts

.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset:
	jsr stack::init

	jsr io::outstr
 	.asciiz "Solving puzzle: "

	lda #0
	pusha
	jsr solve
	bne fail

	jsr io::outstr
 	.asciiz "pass"
	jmp end

fail:
	jsr io::outstr
 	.asciiz "fail"

end:
	jsr io::outstr
 	.byte $a, 0
	brk

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nmi:    jmp     nmi

irq_brk: 
        jmp     irq_brk         ;

        .segment "VECTORS"

        .word   nmi             ; NMI
        .word   reset           ; RESET
        .word   irq_brk         ; IRQ/BRK
