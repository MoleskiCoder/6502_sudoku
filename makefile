%.o : %.s
	ca65 $< -g --listing $(*F).lst

%.65b : %.o
	ld65 $< -o $@ --config $(*F).cfg --dbgfile $(*F).dbg

all: sudoku.65b

.PHONY : clean

clean :
	rm -fv *.o *.65b *.map *.lst
