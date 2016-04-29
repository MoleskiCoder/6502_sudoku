;
; From: https://see.stanford.edu/materials/icspacs106b/H19-RecBacktrackExamples.pdf
;
; A straightforward port from C to 6502 assembler (although feeling like Forth!)
;

        .setcpu "6502"

        .segment "OS"

.include "stack.inc"
.include "maths.inc"
.include "io.inc"

; Scratchpad area.  Not sure how long this will be.  Aliased within "proc" scope.

scratch := 80

; Some useful constants

UNASSIGNED := 0
BOX_SIZE := 3
BOARD_SIZE := 9
CELL_COUNT := (BOARD_SIZE * BOARD_SIZE)

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

;
; ** Move and grid position translation methods
;

.proc move2xy ; ( n -- x y )
	pha
	lda #BOARD_SIZE
	pusha
	jsr maths::divmod
	pla
	rts
.endproc

.proc move2x ; ( n -- x )
	jsr move2xy
	drop
	rts
.endproc

.proc move2y ; ( n -- x )
	jsr move2xy
	swap
	drop
	rts
.endproc

.proc xy2move ; ( x y -- n )
	pha
	lda #BOARD_SIZE
	pusha
	jsr maths::multiply
	jsr maths::add
	pla
	rts
.endproc


; ** Row, column and box start positions

.proc move2row_start ; ( n -- n )
	jsr move2y
	lda #BOARD_SIZE
	pusha
	jsr maths::multiply
	rts
.endproc

.proc move2column_start ; ( n -- n )
	jsr move2x
	rts
.endproc

.proc box_side_start ; ( n -- n )
	pha
	dup
	lda #BOX_SIZE
	pusha
	jsr maths::mod
	jsr maths::subtract
	pla
	rts
.endproc

.proc move2box_start ; ( n -- n )
	jsr move2xy
	jsr box_side_start
	swap
	jsr box_side_start
	swap
	jsr xy2move
	rts
.endproc


; Function: is_used_in_row
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified row matches the given number.

.proc is_used_in_row ; ( number n -- f )

_number := scratch

	pha
	phx
	phy
	jsr move2row_start
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
	lda #1
	pusha
return:
	ply
	plx
	pla
	rts
success:
	lda #0
	pusha
	beq return;
.endproc


; Function: is_used_in_column
; ---------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified column matches the given number.

.proc is_used_in_column ; ( number n -- f )

_number := scratch

	pha
	phx
	phy
	jsr move2row_start
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
	lda #1
	pusha
return:
	ply
	plx
	pla
	rts
success:
	lda #0
	pusha
	beq return;
.endproc


; Function: is_used_in_box
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; within the specified 3x3 box matches the given number.

.proc is_used_in_box ; ( number n -- f )

_number := scratch

	pha
	phx
	phy
	jsr move2box_start
	popx
	popa
	sta _number
	ldy #0
loop:
	pushy
	lda #BOX_SIZE
	pusha
	jsr maths::divmod
	jsr xy2move
	popx
	lda puzzle,x
	cmp _number
	beq success
	iny
	cpy #BOARD_SIZE
	bne loop
fail:
	lda #1
	pusha
return:
	ply
	plx
	pla
	rts
success:
	lda #0
	pusha
	beq return;
.endproc


; Function: is_available
; ----------------------
; Returns a boolean which indicates whether it will be legal to assign
; number to the given row, column location.As assignment is legal if it that
; number is not already used in the row, column, or box.

.proc is_available ; ( number n -- f )

	pha

	two_dup
	jsr is_used_in_row
	beq used_drop
		
	two_dup
	jsr is_used_in_column
	beq used_drop

	jsr is_used_in_box
	beq used

	lda #0
	beq return

used_drop:
	two_drop
used:
	lda #1
return:
	pusha
	pla
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

.proc solve ; ( n -- f )

	pha
	phx

	dup
	popa
	cmp #CELL_COUNT
	beq success					; success!

	dup
	popx
	lda puzzle,x
	beq unassigned
	inx
	pushx
	jsr solve					; if it's already assigned, skip
	jmp return

unassigned:
	ldy #10						; consider all digits
loop:
	pushy
	pushx
	jsr is_available				; if looks promising
	popa
	bne continue

	tya
	sta puzzle,x					; make tentative assignment

	inx
	pushx
	jsr solve
	popa
	beq success					; recur, if success, yay!

continue:
	dey
	bne loop

	lda #UNASSIGNED
	sta puzzle,x					; failure, unmake & try again

	lda #1
	pusha
	jmp return					; this triggers backtracking

success:
	drop
	lda #0
	pusha

return:
	pla
	plx
	rts
.endproc


reset:
	jsr stack::init

	lda #0
	pusha
	jsr solve
	popa
	bne fail

pass:
	jsr io::outstr
 	.asciiz "pass"
	jmp loop

fail:
	jsr io::outstr
 	.asciiz "fail"
	jmp loop



loop:   jmp     loop


nmi:    jmp     nmi

irq_brk: 
        jmp     irq_brk         ;

        .segment "VECTORS"

        .word   nmi             ; NMI
        .word   reset           ; RESET
        .word   irq_brk         ; IRQ/BRK
