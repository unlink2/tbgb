AS=ulas 
BIN=tb.gb
BDIR=bin/

all:
	mkdir -p $(BDIR)
	ulas -v -o $(BDIR)/$(BIN) -l bin/tb.lst -s bin/tb.mlb -S mlb -i ./src src/main.s 
