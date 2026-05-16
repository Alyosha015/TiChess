;****************************************************************
; Debug_PrintRegA - print register A to screen, on next call will
;   print again but lower.
;
; DESTROYS: NONE
;****************************************************************
Debug_PrintRegA:
    pushallexx

    ld de, 0
    ld e, a
    push de
    ld de, DEBUG_PRINTREGA_FORMAT
    push de
    ld de, DEBUG_OUT_STR
    push de
    call ti.sprintf
    pop de
    pop de
    pop de

    ld a, (DEBUG_PRINTREGA_STOP)
    or a
    jr nz, .return

    ld a, (DEBUG_PRINTREGA_C)
    inc a
    ld (DEBUG_PRINTREGA_C), a
    cp 15
    jr nz, .skip
    ld a, 1
    ld (DEBUG_PRINTREGA_STOP), a
.skip:

    ld hl, (DEBUG_PRINTREGA_Y)  ;increment Y coord to draw on
    ld de, 10
    add hl, de
    ld (DEBUG_PRINTREGA_Y), hl

    ld bc, 0
    ld de, (DEBUG_PRINTREGA_Y)
    ld hl, COLOR_WHITE * 256 + COLOR_TRANSPARENT
    ld iy, DEBUG_OUT_STR
    call GFX_DrawText

.return:
    popallexx
    ret

DEBUG_PRINTREGA_Y: dl 80

DEBUG_PRINTREGA_C: db 0
DEBUG_PRINTREGA_STOP: db 0

DEBUG_PRINTREGA_FORMAT: db "A: %d", 0

DEBUG_OUT_STR: rb 256
