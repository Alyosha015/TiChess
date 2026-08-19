DEBUG_OUT_STR: rb 256



DEBUG_PRINTREGA_Y: dl 0 ;80
DEBUG_PRINTREGA_C: db 0
DEBUG_PRINTREGA_STOP: db 0
DEBUG_PRINTREGA_FORMAT: db "A: %d", 0

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

    call Debug_PrintLine

    popallexx
    ret


Debug_Reset:
    pushall
    
    ld de, 0
    ld hl, DEBUG_PRINTREGA_Y
    ld (hl), de

    xor a
    ld (DEBUG_PRINTREGA_C), a
    ld (DEBUG_PRINTREGA_STOP), a

    popall
    ret


Debug_PrintLine:
    ld a, (DEBUG_PRINTREGA_STOP)
    or a
    jr nz, .return

    ld a, (DEBUG_PRINTREGA_C)
    inc a
    ld (DEBUG_PRINTREGA_C), a
    cp 26
    jr nz, .skip
    ld a, 1
    ld (DEBUG_PRINTREGA_STOP), a
.skip:

    ld bc, 0
    ld de, (DEBUG_PRINTREGA_Y)
    ld hl, COLOR_WHITE * 256 + COLOR_TRANSPARENT
    ld iy, DEBUG_OUT_STR
    call GFX_DrawText

    ld hl, (DEBUG_PRINTREGA_Y)  ;increment Y coord to draw on
    ld de, 9
    add hl, de
    ld (DEBUG_PRINTREGA_Y), hl
.return:

    ret


DEBUG_OUT_A_FORMAT: db "%s%d", 0

;****************************************************************
    macro DEBUG_OUT_A _msg

    local msg_start, msg_stop, skip, return

    pushallexx

    jr msg_stop
msg_start:
    db _msg, 0
msg_stop:

    ld de, 0
    ld e, a
    push de
    ld de, msg_start
    push de
    ld de, DEBUG_OUT_A_FORMAT
    push de
    ld de, DEBUG_OUT_STR
    push de
    call ti.sprintf
    pop de
    pop de
    pop de
    pop de

    call Debug_PrintLine

    popallexx

    end macro

;****************************************************************
macro DEBUG_OUT_DE _msg

    local msg_start, msg_stop, skip, return

    pushallexx

    jr msg_stop
msg_start:
    db _msg, 0
msg_stop:

    push de
    ld de, msg_start
    push de
    ld de, DEBUG_OUT_A_FORMAT
    push de
    ld de, DEBUG_OUT_STR
    push de
    call ti.sprintf
    pop de
    pop de
    pop de
    pop de

    call Debug_PrintLine

    popallexx

    end macro
