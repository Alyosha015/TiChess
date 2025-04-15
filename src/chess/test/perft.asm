RunPerftTestSuite:

    ret

TestFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0

PerftTemp:
    ;or use StartPosFen
    ld hl, TestFen
    call BoardLoad

    call AllocMoves
    call GenerateMoves

    ld hl, DBG_PB_YOFFSET
    ld (hl), 5

    ld hl, DBG_PB_XOFFSET
    ld (hl), 0
    ld iy, pinMap
    call Debug_PrintBoard

    ld hl, DBG_PB_XOFFSET
    ld (hl), 8 * 9
    ld iy, checkMap
    call Debug_PrintBoard

    ld hl, DBG_PB_XOFFSET
    ld (hl), 16 * 9
    ld iy, attackMap
    call Debug_PrintBoard

    ld bc, 1
    ld l, 1
    ld d, 2
    ld e, 0
    ld ix, MovgenMapLabel
    call DrawText

    ld de, 0
    ld a, (varD)
    ld e, a
    push de
    ld a, (varC)
    ld e, a
    push de
    ld a, (varB)
    ld e, a
    push de
    ld a, (varA)
    ld e, a
    push de
    ld de, FormatInt
    push de
    ld de, ResultStr
    push de
    call ti.sprintf
    pop de
    pop de
    pop de
    pop de
    pop de
    pop de

    ld bc, 1
    ld l, 82
    ld d, 2
    ld e, 0
    ld ix, ResultStr
    call DrawTextLarge

    ret

MovgenMapLabel: db "Pin         Check      Attack", 0

varA: db 0
varB: db 0
varC: db 0
varD: db 0

FormatInt: db "%d %d %d %d",0
ResultStr: rb 128

;expects thing to print in iy
Debug_PrintBoard:
    pushall
;registers:
;   iy - thing to print
;   l - row counter * 8 (y)
;   c - square counter * 8 (x)
    ld bc, 0
    ld l, 64
.rowLoop:
    ld c, 0
.squareLoop:
    ld a, (iy)
    cp 0
    jp nz, .is1
.is0:
    ld ix, DBG_PB_0
    jp .skipIs1
.is1:
    ld ix, DBG_PB_1
.skipIs1:
    pushall
    ld a, (DBG_PB_YOFFSET) ;y offset
    ld de, 0
    ld e, a
    add hl, de

    push hl

    ld hl, DBG_PB_XOFFSET ;x offset
    ld de, (hl)

    ld a, c
    add e
    ld c, a
    ld a, b
    adc d
    ld b, a

    pop hl

    ld d, 2
    ld e, 0
    call DrawText
    popall

    inc iy

    ld a, c
    add 8
    ld c, a
    cp 64
    jp nz, .squareLoop

    ld a, l
    sub 8
    ld l, a
    cp 0
    jp nz, .rowLoop

    popall
    ret

DBG_PB_1: db "*", 0
DBG_PB_0: db ".", 0

DBG_PB_XOFFSET: rb 3
DBG_PB_YOFFSET: db 0