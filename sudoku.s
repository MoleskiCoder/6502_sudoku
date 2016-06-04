;
; From: https://see.stanford.edu/materials/icspacs106b/H19-RecBacktrackExamples.pdf
;
; A straightforward port from C to 6502 assembler (although feeling like Forth!)
;

; Clock cycles:
;
; 65sc02	109,643,329	55 seconds @ 2Mhz
; 6502		114,831,159	57 seconds @ 2Mhz

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
BOARD_SIZE = 9
CELL_COUNT = (BOARD_SIZE * BOARD_SIZE)


.include "stack.inc"
.include "maths.inc"
.include "io.inc"


.proc print_board_element
	lda #' '
	jsr io::outchr
	popx
	lda puzzle,x
	beq unassigned
	adc #'0'
	jsr io::outchr
	jmp finish
unassigned:
	lda #'-'
	jsr io::outchr
finish:
	lda #' '
	jsr io::outchr
	rts
.endproc

.proc print_box_break_vertical
	lda #'|'
	jsr io::outchr
	rts
.endproc

.proc print_box_break_horizontal
	jsr io::outstr
	.asciiz " --------+---------+--------"
	rts
.endproc

.proc print_newline

CR = $d
LF = $a

	lda #CR
	jsr io::outchr
	lda #LF
	jsr io::outchr

	rts
.endproc

.proc print_board

	jsr print_newline
	jsr print_newline

	jsr print_box_break_horizontal
	jsr print_newline

	ldy #0
loop:
	pushy
	jsr print_board_element

	iny

	; horizontal box break
	lda table_move2box_y,y
	bne boxh_continue
	lda table_move2x,y
	bne boxh_continue
	jsr print_newline
	jsr print_box_break_horizontal

boxh_continue:
	; newline only
	lda table_move2x,y
	bne newl_continue
	jsr print_newline
	jmp continue

newl_continue:
	; vertical box break
	lda table_move2box_x,y
	bne boxv_continue
	jsr print_box_break_vertical
	jmp continue

boxv_continue:

continue:
	cpy #CELL_COUNT
	bne loop
	rts

.endproc

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

table_move2box_x:
	.byte 0, 1, 2, 0, 1, 2, 0, 1, 2
	.byte 0, 1, 2, 0, 1, 2, 0, 1, 2
	.byte 0, 1, 2, 0, 1, 2, 0, 1, 2
	.byte 0, 1, 2, 0, 1, 2, 0, 1, 2
	.byte 0, 1, 2, 0, 1, 2, 0, 1, 2
	.byte 0, 1, 2, 0, 1, 2, 0, 1, 2
	.byte 0, 1, 2, 0, 1, 2, 0, 1, 2
	.byte 0, 1, 2, 0, 1, 2, 0, 1, 2
	.byte 0, 1, 2, 0, 1, 2, 0, 1, 2

table_move2box_y:
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 1, 1, 1, 1, 1, 1, 1, 1, 1
	.byte 2, 2, 2, 2, 2, 2, 2, 2, 2
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 1, 1, 1, 1, 1, 1, 1, 1, 1
	.byte 2, 2, 2, 2, 2, 2, 2, 2, 2
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 1, 1, 1, 1, 1, 1, 1, 1, 1
	.byte 2, 2, 2, 2, 2, 2, 2, 2, 2

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

; "is_used_in_" arguments

_number := scratch
_n := _number + 1

; Function: is_used_in_row
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified row matches the given number.

.proc is_used_in_row ; ( _number _n -- A:f )
	ldy _n
	ldx table_move2row_start,y
	lda _number
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

.proc is_used_in_column ; ( _number _n -- A:f )

	ldy _n
	ldx table_move2x,y
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

table_count2boxoffset:
	.byte 0 	; one byte table pad, since we're counting down.
	.byte 0, 1, 2, 9, 10, 11, 18, 19, 20

box_offset_hold:
	.byte 0

; Function: is_used_in_box
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; within the specified 3x3 box matches the given number.

.proc is_used_in_box ; ( _number _n -- A:f )

	ldx _n
	lda table_move2box_start,x
	sta box_offset_hold

	ldy #BOARD_SIZE
loop:
	lda box_offset_hold

	clc
	adc table_count2boxoffset,y
	
	tax

	lda puzzle,x
	cmp _number
	beq success
	dey
	bne loop
fail:
	lda #1
	rts
success:
	lda #0
	rts
.endproc


; Function: is_available
; ----------------------
; Returns a boolean which indicates whether it will be legal to assign
; number to the given row, column location.As assignment is legal if it that
; number is not already used in the row, column, or box.

.proc is_available ; ( _number _n -- A:f )

; One temporary byte used in column + box checking
_x := _n + 1
_y := _x + 1

	stx _x
	sty _y

	jsr is_used_in_row
	beq used

	jsr is_used_in_column
	beq used

	jsr is_used_in_box
	beq used

	ldx _x
	ldy _y
	lda #0
	rts

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
	sty _number
	stx _n
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

	jsr print_board

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
