ca65 sudoku.s --listing sudoku.lst
ld65 sudoku.o -o ..\..\cpp\cpp_6502\sudoku.bin --config sudoku.cfg
ld65 sudoku.o -o sudoku.65b -vm --mapfile sudoku.map --config sudoku.cfg
