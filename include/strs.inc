; map ascii values to the actual tileset here
.rep i, 10, 1, .scc i + '0' = i
.rep i, 26, 1, .scc i + 'a' = i + 10
.rep i, 26, 1, .scc i + 'A' = i + 10

SNEW_GAME:
.str "New Game"
SMAP_EDITOR:
.str "Map Editor"
