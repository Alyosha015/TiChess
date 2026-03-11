;****************************************************************
; Engine_Init
;****************************************************************
Engine_Init:
    call PL_Init

    ld hl, C_Board
    ld (hl), 0
    ld de, C_Board + 1
    ld bc, 63
    ldir

    ret
