;PIECE FORMAT:
; C T T T
; 3 2 1 0
;
; C = color (1 = white)
; T = piece type

    PIECE_NONE := 0

    PIECE_KING := 1
    PIECE_QUEEN := 2
    PIECE_ROOK := 3
    PIECE_BISHOP := 4
    PIECE_KNIGHT := 5
    PIECE_PAWN := 6

    PIECE_WHITE := 8
    PIECE_BLACK := 0

    PIECE_MASK_TYPE := 0111b
    PIECE_MASK_COLOR := 1000b

PieceToAscii:
    db ".","kqrbnp",0,0,"KQRBNP"
