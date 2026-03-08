;****************************************************************
;
; Central place for most of the variables used by the chess engine,
; note many of these are memory mapped to src/memory.asm values.
;
;****************************************************************

PL_Data := MEM_PL_DATA

PL_Table := MEM_PL_LUT
PL_Black := MEM_PL_LUT_BLACK
PL_White := MEM_PL_LUT_WHITE

;C_ for ChessEngine, since these are all globals I don't want to clutter too much.
C_Board := MEM_ENGINE_BOARD
C_AttackMap := MEM_ENGINE_ATTACK_MAP
C_CheckMap := MEM_ENGINE_CHECK_MAP
C_PinMap := MEM_ENGINE_PIN_MAP



