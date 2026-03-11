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

C_WhiteToMove: db 0
C_EpFile: db 0
C_CastleFlags: db 0



