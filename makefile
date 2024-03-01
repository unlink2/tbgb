AS=ulas 
BIN=tb.gb
BDIR=bin/

all:
	mkdir -p $(BDIR)
	ulas -v -o $(BDIR)/$(BIN) -l bin/lst.txt -s bin/syms.txt -i ./src src/main.s 
