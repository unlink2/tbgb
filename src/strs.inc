; map ascii values to the actual tileset here
.rep i, 10, 1, .scc i + '0' = i
.rep i, 26, 1, .scc i + 'a' = i + 10
.rep i, 26, 1, .scc i + 'A' = i + 10

; map space to empty tile
.scc 0x20 = 0x30 

STITLE:
.str "tbgb"
.db 0

SNEW_GAME:
.str "New Game"
.db 0
SMAP_EDITOR:
.str "Map Editor"
.db 0
