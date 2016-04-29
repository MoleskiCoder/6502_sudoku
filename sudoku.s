;
; From: https://see.stanford.edu/materials/icspacs106b/H19-RecBacktrackExamples.pdf
;
; A straightforward port from C to 6502 assembler
;
; http://www.telegraph.co.uk/news/science/science-news/9359579/Worlds-hardest-sudoku-can-you-crack-it.html

        .setcpu "6502"

        .segment "OS"

.include "maths.inc"
.include "stack.inc"

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

; A == move

	sta maths::numerator
	lda #BOARD_SIZE
	sta maths::denominator
	jsr maths::divmod
	tay
	ldx maths::quotient
	rts

; X == x grid
; Y == y grid

.endproc


.proc xy2move

; X == x grid
; Y == y grid

	sty maths::first
	lda #BOARD_SIZE
	sta maths::second
	jsr maths::multiply
	sta scratch
	txa
	clc
	adc scratch
	rts

; A == move

.endproc


; ** Row, column and box start positions

.proc move2row_start

; A == move

_n := scratch

	sta _n
	txa
	pha
	tya
	pha
	jsr move2xy
	sty maths::first
	lda #BOARD_SIZE
	sta maths::second
	jsr maths::multiply
	sta scratch
	pla
	tay
	pla
	tax
	lda _n
	rts

; A == row start offset

.endproc


.proc move2column_start

; A == number

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

; A == column start offset

.endproc


.proc box_side_start

; A == number

; 1 byte of scratch zone used

_n := scratch

	sta _n

	txa
	pha

	sta maths::numerator

	lda #BOX_SIZE
	sta maths::denominator
	jsr maths::divmod

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

; A == box side start offset

.endproc


.proc move2box_start

; A == move

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

; A == box start offset

.endproc


; Function: is_used_in_row
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified row matches the given number.

.proc is_used_in_row

; A == number
; Y == n

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

; A == zero, used
; A == non-zero, unused

.endproc


; Function: is_used_in_column
; ---------------------------
; Returns a boolean which indicates whether any assigned entry
; in the specified column matches the given number.

.proc is_used_in_column

; A == number
; Y == n

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

; A == zero, used
; A == non-zero, unused

.endproc


; Function: is_used_in_box
; ------------------------
; Returns a boolean which indicates whether any assigned entry
; within the specified 3x3 box matches the given number.

.proc is_used_in_box

; A == number
; Y == n

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

; A == zero, used
; A == non-zero, unused

.endproc

; Function: is_available
; ----------------------
; Returns a boolean which indicates whether it will be legal to assign
; number to the given row, column location.As assignment is legal if it that
; number is not already used in the row, column, or box.

.proc is_available

; A == number
; Y == n

_number := scratch
_n := _number + 1

	jsr is_used_in_row
	beq used

	jsr is_used_in_column
	beq used

	jsr is_used_in_box
	beq used

	; Not used, so return true
	lda #0
	rts

used:	; So return false
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

.proc solve

; top of stack == n

	jsr stack::popa
	cmp #CELL_COUNT
	beq success					; success

	tax
	lda puzzle,x
	cmp #UNASSIGNED
	beq unassigned
	inx
	jsr stack::pushx
	jsr solve					; if it's already assigned, skip
	rts

unassigned:
	ldy #BOARD_SIZE					; consider all digits
loop:
	tya
	pha	; save y

	pha	; hold for the register transfer

	txa
	tay	; move x to y
	pla	; pull y to a

	jsr is_available
	bne end_loop

	tax
	tya
	sta puzzle,x					; make tentative assignment

	inx
	jsr stack::pushx
	jsr solve
	beq success					; recur, if success, yay!

end_loop:
	pla
	tay	; restore y

	dey
	bne loop

	lda #UNASSIGNED
	sta puzzle,x					; failure, unmake and try again

	lda #1						; this triggers backtracking
success:
	rts
.endproc


reset:
	jsr stack::_init

	lda #0
	jsr stack::pusha
	jsr solve

loop:   jmp     loop


nmi:    jmp     nmi

irq_brk: 
        jmp     irq_brk         ;

        .segment "VECTORS"

        .word   nmi             ; NMI
        .word   reset           ; RESET
        .word   irq_brk         ; IRQ/BRK
