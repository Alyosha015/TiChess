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
;indexed by [SquareIndex * 3]. SquareIndex is the move's end destination, and
;the lookup will contain the 3-byte move struct for a move that leads to that
;square.
;Promotion is a special case since multiple moves have the same destination.
;This is handled by changing the array to have the chess pieces drawn on as
;option to promote too (queen/knight/bishop/rook) point to their respective
;promotion moves. 
BUI_SquareToMove := MEM_BUI_SQUARE_TO_MOVE  ;192 B
;sequential list of all legal moves for a selected piece.
BUI_MovesForSelectedPiece := MEM_BUI_MOVES_FOR_SELECTED_PIECE   ;192 B
