;
; From: https://see.stanford.edu/materials/icspacs106b/H19-RecBacktrackExamples.pdf
;
; A straightforward port from C to 6502 assembler (although feeling like Forth!)
;

;
; Clock cycles: 2,080,575,831
;		1,999,549,983
;

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

UNASSIGNED := 0
BOX_SIZE := 3
BOARD_SIZE := 9
CELL_COUNT := (BOARD_SIZE * BOARD_SIZE)


.include "stack.inc"
.include "maths.inc"
.include "io.inc"

;
; ** Move and grid position translation methods
;

.macro move2xy ; ( n -- x y )
	lda #BOARD_SIZE
	pusha
	jsr maths::divmod
.endmacro

.macro move2x ; ( n -- x )
	move2xy
	drop
.endmacro

.macro move2y ; ( n -- x )
	move2xy
	swap
	drop
.endmacro

.macro xy2move ; ( x y -- n )
	lda #BOARD_SIZE
	pusha
	jsr maths::multiply
	jsr maths::add
.endmacro


; ** Row, column and box start positions

.macro move2row_start ; ( n -- n )
	move2y
	lda #BOARD_SIZE
	pusha
	jsr maths::multiply
.endmacro

.macro move2column_start ; ( n -- n )
	move2x
.endmacro

.macro box_side_start ; ( n -- n )
	dup
	lda #BOX_SIZE
	pusha
	mod
	jsr maths::subtract
.endmacro

.macro move2box_start ; ( n -- n )
	move2xy
	box_side_start
	swap
	box_side_start
	swap
	xy2move
.endmacro

; Function: is_used_in_row
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified row matches the given number.

.proc is_used_in_row ; ( number n -- A:f )

_number := scratch
_x = _number + 1
_y = _x + 1

	stx _x
	sty _y

	move2row_start
	popx
	popa
	sta _number
	ldy #BOARD_SIZE
loop:
	lda puzzle,x
	cmp _number
	beq success
	inx
	dey
	bne loop
fail:
	ldy _y
	ldx _x
	lda #1
	rts
success:
	ldy _y
	ldx _x
	lda #0
	rts
.endproc


; Function: is_used_in_column
; ---------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified column matches the given number.

.proc is_used_in_column ; ( number n -- A:f )

_number := scratch
_x = _number + 1
_y = _x + 1

	stx _x
	sty _y
	move2column_start
	popx
	popa
	sta _number
	ldy #BOARD_SIZE
loop:
	lda puzzle,x
	cmp _number
	beq success
	pushx
	lda #BOARD_SIZE
	pusha
	jsr maths::add
	popx
	dey
	bne loop
fail:
	ldy _y
	ldx _x
	lda #1
	rts
success:
	ldy _y
	ldx _x
	lda #0
	rts
.endproc


; Function: is_used_in_box
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; within the specified 3x3 box matches the given number.

.proc is_used_in_box ; ( number n -- A:f )

_number := scratch
_x = _number + 1
_y = _x + 1

	stx _x
	sty _y
	move2box_start
	swap
	popa
	sta _number
	ldy #0
loop:
	dup
	pushy
	lda #BOX_SIZE
	pusha
	jsr maths::divmod
	xy2move
	jsr maths::add
	popx
	lda puzzle,x
	cmp _number
	beq success
	iny
	cpy #BOARD_SIZE
	bne loop
fail:
	drop
	ldy _y
	ldx _x
	lda #1
	rts
success:
	drop
	ldy _y
	ldx _x
	lda #0
	rts
.endproc


; Function: is_available
; ----------------------
; Returns a boolean which indicates whether it will be legal to assign
; number to the given row, column location.As assignment is legal if it that
; number is not already used in the row, column, or box.

.proc is_available ; ( number n -- A:f )

	two_dup
	jsr is_used_in_row
	beq used_drop
		
	two_dup
	jsr is_used_in_column
	beq used_drop

	jsr is_used_in_box
	beq used

	lda #0
	rts

used_drop:
	two_drop
used:
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
	beq _return_true

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

	lda #UNASSIGNED
	sta puzzle,x

_return_false:
	plx
	lda #1
	rts

_return_true:
	plx
	lda #0
	rts

.endproc
;;

.macro verify_empty_stack
	jsr stack::position
	cmp #$ff
	bne fail
.endmacro

;;

.macro test_return
return:
	jsr io::outstr
 	.byte $a, 0
	rts
.endmacro

.macro test_pass
pass:
	jsr io::outstr
 	.asciiz "pass"
	jmp return
.endmacro

.macro test_fail
fail:
	jsr io::outstr
 	.asciiz "fail"
	jmp return
.endmacro

.macro test_epilogue
	jmp pass
test_return
test_pass
test_fail
.endmacro

;;

.proc move_trans_tests

	jsr io::outstr
 	.asciiz "Move translation tests: "

	lda #19
	pusha
	move2xy
	popy
	cpy #2
	beq _move2xy_pass
	jmp fail
_move2xy_pass:
	popx
	cpx #1
	bne fail
	verify_empty_stack

	lda #19
	pusha
	move2x
	popx
	cpx #1
	bne fail
	verify_empty_stack

	lda #19
	pusha
	move2y
	popy
	cpy #2
	bne fail
	verify_empty_stack

	ldx #1
	pushx
	ldy #2
	pushy
	xy2move
	popa
	cmp #19
	bne fail
	verify_empty_stack

test_epilogue

.endproc


.proc start_position_tests

	jsr io::outstr
 	.asciiz "Start position tests: "

	lda #7
	pusha
	box_side_start
	popa
	cmp #6
	beq _move2row_start_test
	jmp fail

_move2row_start_test:
	lda #19
	pusha
	move2row_start
	popa
	cmp #18
	beq _move2column_start_test
	jmp fail

_move2column_start_test:
	lda #19
	pusha
	move2column_start
	popa
	cmp #1
	beq _move2box_start_test_2
	jmp fail

_move2box_start_test_1:
	lda #19
	pusha
	move2box_start
	popa
	cmp #0
	beq _move2box_start_test_2
	jmp fail

_move2box_start_test_2:
	lda #36
	pusha
	move2box_start
	popa
	cmp #27
	bne fail

	lda #80
	pusha
	move2box_start
	popa
	cmp #60
	bne fail
	verify_empty_stack

test_epilogue

.endproc


.proc used_in_row_tests

	jsr io::outstr
 	.asciiz "Used in row tests: "

	lda #7
	pusha
	lda #18
	pusha
	jsr is_used_in_row
	popa
	bne fail

	lda #9
	pusha
	lda #18
	pusha
	jsr is_used_in_row
	popa
	bne fail

	lda #2
	pusha
	lda #18
	pusha
	jsr is_used_in_row
	popa
	bne fail

	lda #1
	pusha
	lda #18
	pusha
	jsr is_used_in_row
	popa
	beq fail

	verify_empty_stack

test_epilogue

.endproc


.proc used_in_column_tests

	jsr io::outstr
 	.asciiz "Used in column tests: "

	lda #7
	pusha
	lda #5
	pusha
	jsr is_used_in_column
	popa
	bne fail

	lda #5
	pusha
	lda #5
	pusha
	jsr is_used_in_column
	popa
	bne fail

	lda #9
	pusha
	lda #5
	pusha
	jsr is_used_in_column
	popa
	beq fail

	verify_empty_stack

test_epilogue

.endproc


.proc used_in_box_tests

	jsr io::outstr
 	.asciiz "Used in box tests: "

	lda #6
	pusha
	lda #80
	pusha
	jsr is_used_in_box
	popa
	bne fail

	lda #6
	pusha
	lda #12
	pusha
	jsr is_used_in_box
	popa
	bne fail

	lda #9
	pusha
	lda #12
	pusha
	jsr is_used_in_box
	popa
	bne fail

	lda #3
	pusha
	lda #12
	pusha
	jsr is_used_in_box
	popa
	beq fail

	verify_empty_stack

test_epilogue

.endproc


.proc is_available_tests

	jsr io::outstr
 	.asciiz "Is available tests: "

	lda #7
	pusha
	lda #0
	pusha
	jsr is_available
	popa
	beq fail

	lda #7
	pusha
	lda #1
	pusha
	jsr is_available
	popa
	beq fail

	lda #6
	pusha
	lda #80
	pusha
	jsr is_available
	popa
	beq fail

	lda #1
	pusha
	lda #80
	pusha
	jsr is_available
	popa
	beq fail

	lda #4
	pusha
	lda #80
	pusha
	jsr is_available
	popa
	beq fail

	lda #5
	pusha
	lda #80
	pusha
	jsr is_available
	popa
	bne fail

	verify_empty_stack

test_epilogue

.endproc


.proc game

	jsr io::outstr
 	.asciiz "Solving puzzle: "

	lda #0
	pusha
	jsr solve
	bne fail

test_epilogue

.endproc

reset:
	jsr stack::init

	;jsr maths::_tests
	;jsr stack::_tests
	;jsr move_trans_tests
	;jsr start_position_tests
	;jsr used_in_row_tests
	;jsr used_in_column_tests
	;jsr used_in_box_tests
	;jsr is_available_tests
	jsr game

loop:   jmp     loop


nmi:    jmp     nmi

irq_brk: 
        jmp     irq_brk         ;

        .segment "VECTORS"

        .word   nmi             ; NMI
        .word   reset           ; RESET
        .word   irq_brk         ; IRQ/BRK
