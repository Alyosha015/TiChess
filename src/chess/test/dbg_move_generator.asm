DEBUG_PRINT_MAP_LABEL: db 'Attack Map, Check Map, Pin Map', 0
DEBUG_PRINT_MAP_CHAR_1: db '*', 0
DEBUG_PRINT_MAP_CHAR_0: db '.', 0

;****************************************************************
; Debug_PrintBoardMaps - display attack / check / pin maps.
;
; DESTROYS: NONE
;****************************************************************
Debug_PrintBoardMaps:
    pushall

    ld iy, DEBUG_PRINT_MAP_LABEL
    ld bc, 8
    ld de, 8
    ld hl, COLOR_WHITE * 256 + COLOR_TRANSPARENT
    call GFX_DrawText

    ld ix, C_AttackMap
    ld bc, 24 * 320 + 8 ; (8, 24)
    call Debug_PrintMap

    ld ix, C_CheckMap
    ld bc, 24 * 320 + 8 + 80
    call Debug_PrintMap
    
    ld ix, C_PinMap
    ld bc, 24 * 320 + 8 + 80 * 2
    call Debug_PrintMap

    popall
    ret

DEBUG_PRINT_MAP_VRAM: dl 0
DEBUG_PRINT_ROW_COUNTER: db 0
DEBUG_PRINT_SQUARE_COUNTER: db 0

;****************************************************************
; Debug_PrintMap - (internal) draws 64 byte move generator map,
;   used by Debug_PrintBoardMaps.
;
; INPUTS:
;   IX - map pointer
;   BC - top left corner vram coordinates. 
;
; DESTROYS: ALL
;****************************************************************
Debug_PrintMap:
    ld (DEBUG_PRINT_MAP_VRAM), bc

    ld de, 56
    add ix, de  ;load pointer to top left corner 

    ld a, 8
    ld (DEBUG_PRINT_ROW_COUNTER), a
.rowLoop:       ;loops over 8 rows
    ld a, 8
    ld (DEBUG_PRINT_SQUARE_COUNTER), a
.squareLoop:    ;loops over 8 squares in row
    ld a, (ix)  ;get next datapoint
    inc ix

    ld iy, DEBUG_PRINT_MAP_CHAR_1
    dec a
    jr z, .squareIs1
.squareIs0:
    ld iy, DEBUG_PRINT_MAP_CHAR_0
.squareIs1:

    ld bc, (DEBUG_PRINT_MAP_VRAM)
    ld hl, COLOR_LIGHT_GRAY * 256 + COLOR_TRANSPARENT
    ld de, 0
    call GFX_DrawText

    ld hl, (DEBUG_PRINT_MAP_VRAM)
    ld de, 8
    add hl, de
    ld (DEBUG_PRINT_MAP_VRAM), hl

    ld hl, DEBUG_PRINT_SQUARE_COUNTER
    dec (hl)
    jr nz, .squareLoop

    ld de, -16
    add ix, de

    ld hl, (DEBUG_PRINT_MAP_VRAM)
    ld de, 320 * 8 - 8 * 8          ;moves vram location down 8 pixels and left 64
                                    ;to calculate newline position.
    add hl, de
    ld (DEBUG_PRINT_MAP_VRAM), hl

    ld hl, DEBUG_PRINT_ROW_COUNTER
    dec (hl)
    jr nz, .rowLoop

    ret
