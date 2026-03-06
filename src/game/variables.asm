;****************************************************************
;
; Central place for most of the variables used by the game,
; *the chess engine will have a similar file. Note that some of
; these are memory mapped to src/memory.asm values.
;
;****************************************************************

; BoardUi 
PERSPECTIVE_WHITE := 1
PERSPECTIVE_BLACK := 0

bui_Perspective: db PERSPECTIVE_WHITE

bui_DirtySquares := MEM_BUI_DIRTY_SQUARES ;64 B
