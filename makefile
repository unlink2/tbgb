AS=ulas 
BIN=tb.gb
BDIR=bin/

all:
	mkdir -p $(BDIR)
	ulas -v -o $(BDIR)/$(BIN) -l - -s bin/syms.txt -i ./include src/main.s
