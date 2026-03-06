;****************************************************************
;
; Central place to keep track of free memory areas of the calculator.
;
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

;pixelShadow
MEM_FONT_TABLE_LARGE := MEM_PS
MEM_LARGE_FONT := MEM_FONT_TABLE_LARGE + 3 * 95

;pixelShadow2
MEM_BUI_DIRTY_SQUARES := MEM_PS2    ;64 B


;cmdPixelShadow


;plotSScreen
MEM_MOVES_HEAP := ti.plotSScreen


;saveSScreen
