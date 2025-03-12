RunPerftTestSuite:

    ret

PerftTemp:
    call AllocMoves
    call GenerateMoves

    ld de, 0
    ld e, (ix-1)
    push de
    ld de, FormatInt
    push de
    ld de, ResultStr
    push de
    call ti.sprintf
    pop de
    pop de
    pop de

    ld bc, 1
    ld l, 1
    ld d, 2
    ld e, 0
    ld ix, ResultStr
    call DrawText

    ret

FormatInt: db "%d!",0
ResultStr: rb 128

Debug_PrintBitBoard:

    ret