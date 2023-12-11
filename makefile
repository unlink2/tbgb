AS=ulas 
BIN=tb.gb
BDIR=bin/

all:
	mkdir -p $(BDIR)
	ulas -o $(BDIR)/$(BIN) -l - -i ./include src/main.s
