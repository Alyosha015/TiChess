;****************************************************************
;
; Central place for most global variables used by the game,
; the chess engine will have a similar file. Internal variables
; used by a single file are generally in that file. Note that
; some of these are memory mapped to src/memory.asm values.
;
;****************************************************************

; Game State
PLAYER_TYPE_HUMAN := 0
PLAYER_TYPE_COMPUTER := 1

Game_WhitePlayerType: db PLAYER_TYPE_HUMAN
Game_BlackPlayerType: db PLAYER_TYPE_HUMAN

; BoardUi 
PERSPECTIVE_WHITE := 1
PERSPECTIVE_BLACK := 0

BUI_Perspective: db PERSPECTIVE_WHITE

BUI_DirtySquares := MEM_BUI_DIRTY_SQUARES   ;64 B
;note this and the following must be one after the
;other for code which zeros them.
BUI_SquareToMove := MEM_BUI_SQUARE_TO_MOVE  ;192 B
BUI_MovesForSelectedPiece := MEM_BUI_MOVES_FOR_SELECTED_PIECE   ;192 B
