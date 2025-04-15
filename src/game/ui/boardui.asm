UI_NULL := 255

CursorX: db 0
CursorY: db 0
LastMoveSource: db UI_NULL
LastMoveDest: db UI_NULL

AnimCounter: db UI_NULL

;redraws only the squares which are marked for redraw, and handles animation of a moving piece.
boardui_Draw:

    ld bc, 0
.drawLoop:
    ld hl, RedrawFlags
    add hl, bc
    ld a, (hl)
    cp 0
    jp nz, .drawLoopContinue

    call boardui_DrawSquare

.drawLoopContinue:
    inc c
    ld a, c
    cp 64
    jp nz, .drawLoop

    ret

;redraws whole board.
boardui_DrawForce:
    ld c, 0
.drawLoop:

    call boardui_DrawSquare

    inc c
    ld a, c
    cp 64
    jp nz, .drawLoop

    ret

;preserves BC. Expects square index in C.
boardui_DrawSquare:
    push bc

    ;steps?
    ;   Draw chess-square itself
    ;   Draw rank/file marker
    ;   Draw chess-piece
    ;   Draw cursor overlay
    ;   
    ;Some thoughts on animating moving pieces:
    ;
    ;

    ;registers:
    ;   B - square color (index for palette)
    ;   C - square index
    ;   DE - 
    ;   HL - 
    ;   IX - 
    ;   IXH - square rank
    ;   IXL - square file

    ld a, c
    and 111b
    ld ixl, a
    ld a, c
    sra a
    sra a
    sra a
    ld ixh, a

    ld b, 10
    add ixl
    and 1
    cp 0
    jp nz, .drawBlack
    ld b, 11
.drawBlack:

;Draw Square
    push bc ;preserve BC
    ;expects X in BC, Y in L, Width in D, Height in E, Color in H
    ld de, $1E00
    ld a, ixh
    neg
    add 7
    ld e, a
    mlt de
    ld l, e
    ld h, b
    ld bc, $1E00
    ld c, ixl
    mlt bc
    ld (boardui_x), bc ;store x/y for later functions
    ld a, l
    ld (boardui_y), a
    ld de, $1E1E
    call FillRect
    pop bc ;restore BC

;Draw Rank/File:

    ld a, ixl ;file
    cp 0
    jp nz, .skipDrawRank
    push bc
    push ix

    ld a, (boardui_y)
    inc a
    ld l, a
    ld bc, 1

    ld a, ixh
    add '1'
    ld ix, RankFileStr
    ld (ix), a

    ld de, $0300
    call DrawText

    pop ix
    pop bc
.skipDrawRank:

    ld a, ixh ;rank
    cp 0
    jp nz, .skipDrawFile
;expects x (0-319) in BC, y (0-239) in L, FG in D, BG in E, and string pointer in IX
    push bc ;preserve BC / IX
    push ix

    ld l, 231
    ld a, ixl
    add 'A'
    ld ix, RankFileStr
    ld (ix), a

    call TextRenderSize

    ld a, 28
    sub c

    ld bc, (boardui_x)
    add c ;offset to right side of square
    ld c, a
    ld a, b
    adc 0
    ld b, a

    ld de, $0300
    call DrawText

    pop ix ;restore BC / IX
    pop bc
.skipDrawFile:

;draw chess piece
    ld hl, pieces
    ld de, 0
    ld e, c
    add hl, de
    ld a, (hl)
    cp PIECE_NONE
    jp z, .skipDrawPiece

    push bc ;preserve bc

    ld b, a

    ld hl, SPRITE_PIECE_TABLE
    ld de, $0300
    and MASK_PIECE_TYPE
    ld e, a
    mlt de
    add hl, de
    ld ix, (hl)

    ld de, $0200 ;white
    ld a, b
    and MASK_PIECE_COLOR
    cp PIECE_WHITE
    jp z, .pieceWhite
    ld de, $0100 ;black
.pieceWhite:

    ld bc, (boardui_x)
    ld a, c
    add 1
    ld c, a
    ld a, b
    adc 0
    ld b, a
    ld a, (boardui_y)
    inc a
    ld l, a
    call DrawSprite1bpp
    
    pop bc ;restore bc

.skipDrawPiece:

    pop bc
    ret

;stores coordinates of top left corner pf current square being drawn (24 bit for X, 8 bit for Y)
boardui_x: dl 0
boardui_y: db 0

RedrawFlags: rb 64
RankFileStr: db "x", 0
