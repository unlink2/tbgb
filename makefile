AS=ulas 
BIN=tb.gb
BDIR=bin/

all:
	mkdir -p $(BDIR)
	ulas -v -o $(BDIR)/$(BIN) -l bin/tb.lst -s bin/tb.mlb -S mlb -i ./src -i ./tiles src/main.s

.PHONY: tiles
tiles:
	./tools/png2chr.py assets/tiles0.png > tiles/tileset0.inc
	./tools/png2chr.py assets/tiles1.png > tiles/tileset1.inc
