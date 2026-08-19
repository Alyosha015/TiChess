;****************************************************************
;
; Central place for global variables used by the chess engine, note
; arrays are memory mapped to locations defined in src/memory.asm.
;
;****************************************************************

PL_Data := MEM_PL_DATA

PL_LUT := MEM_PL_LUT
PL_Black := MEM_PL_LUT_BLACK
PL_White := MEM_PL_LUT_WHITE

;C_ for ChessEngine, since these are all globals I don't want to clutter too much.
C_Board := MEM_ENGINE_BOARD
C_AttackMap := MEM_ENGINE_ATTACK_MAP
C_CheckMap := MEM_ENGINE_CHECK_MAP
C_PinMap := MEM_ENGINE_PIN_MAP

C_BoardStateStack := MEM_ENGINE_BOARD_STATE_STACK

C_WhiteToMove: db 0

B_BoardState:           ;these 3 variables are saved on the board state stack with
    C_CastleFlags: db 0 ;the B_BoardState label, so don't change the order etc. 
    C_EpFile: db 0
    _B_CapturedPiece: db 0

;if white is to move, current index would be 1, current color 8, enemy index 0, enemy color 0
C_CurrentIndex: db 0
C_CurrentColor: db 0
C_EnemyIndex: db 0
C_EnemyColor: db 0

C_CurrentPlPtr: dl 0    ;holds addresses to look up tables of current and enemy pieceslists
C_EnemyPlPtr: dl 0

;following variables are updated by the move generator:
C_InCheck: db 0
C_CurrentKing: db 0     ;stores positions of kings (MG_KING_NONE if there's no king)
C_EnemyKing: db 0
