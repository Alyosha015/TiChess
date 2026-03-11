;****************************************************************
;
; Central place to keep track of free memory areas of the calculator
; which are being reserved for storing large arrays mostly.
;
; https://wikiti.brandonw.net/index.php?title=Category:84PCE:RAM:By_Address
;
; D031F6h: pixelShadow      -  8400 bytes
; D052C6h: pixelShadow2     -  8400 bytes
; D07396h: cmdPixelShadow   -  8400 bytes
; D09466h: plotSScreen      - 21945 bytes
; D0EA1Fh: saveSScreen      - 21945 bytes

MEM_PS := ti.pixelShadow
MEM_PS2 := ti.pixelShadow2
MEM_CPS := ti.cmdPixelShadow

;pixelShadow - used for large font
MEM_FONT_TABLE_LARGE := MEM_PS
MEM_LARGE_FONT := MEM_FONT_TABLE_LARGE + 3 * 95

;pixelShadow2 - used by game logic
MEM_BUI_DIRTY_SQUARES := MEM_PS2    ;64 B


;cmdPixelShadow - used by chess engine
MEM_PL_DATA := MEM_CPS
MEM_PL_LUT := MEM_PL_DATA + PL_RESERVE_TOTAL_BYTE_COUNT   ;see chess/piecelist.asm
MEM_PL_LUT_BLACK := MEM_PL_LUT
MEM_PL_LUT_WHITE := MEM_PL_LUT + PL_LUT_BLACK_SIZE

    ;next 4 are all 64 bytes each.
MEM_ENGINE_BOARD := MEM_PL_LUT + PL_LUT_BLACK_SIZE + PL_LUT_WHITE_SIZE ;64 byte board representation
MEM_ENGINE_ATTACK_MAP := MEM_ENGINE_BOARD + 64
MEM_ENGINE_CHECK_MAP := MEM_ENGINE_ATTACK_MAP + 64
MEM_ENGINE_PIN_MAP := MEM_ENGINE_CHECK_MAP + 64


;plotSScreen - used for moves heap
MEM_MOVES_HEAP := ti.plotSScreen


;saveSScreen
