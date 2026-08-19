;****************************************************************
;
; Used to handle drawing the board/pieces/piece animations.
;
;****************************************************************

;****************************************************************
; BUI_DrawTick - Handles all drawing logic.
;
; Destroys: All
;****************************************************************
BUI_DrawTick:

    ret

;****************************************************************
; BUI_DrawBoardForce - Redraw all 64 squares, clear dirty squares
;   markers.
;
; Destroys: All
;****************************************************************
BUI_DrawBoardForce:
    ;clear dirty squares data
    ld hl, bui_DirtySquares
    ld (hl), 0
    inc hl
    ld de, bui_DirtySquares
    ld bc, 63
    ldir

    xor a
.loop:
    push af

    call BUI_DrawSquare

    pop af
    inc a
    cp 64
    jr nz, .loop
    

    ret

;****************************************************************
; BUI_DrawBoard - Redraws only squares marked dirty.
;
; DESTROYS: All
;****************************************************************
BUI_DrawBoard:

    
    ret

;temporary variables for BUI_DrawSquare
;note that _bui_index and _bui_square_x/y are stored as 3 bytes so they can be accessed
;as LD BC, (_bui_square_x), so BC doesn't need to be cleared in a seperate step.
_bui_index: dl 0    ;0-63 (file = index & 111b, rank = index >> 3)
_bui_rank: db 0     ;0-7 rows    (1-8)
_bui_file: db 0     ;0-7 columns (a-h)
_bui_square_x: dl 0 ;top left corner coordinates for square currently being drawn.
_bui_square_y: dl 0
_bui_square_piece: db 0

;****************************************************************
; BUI_DrawSquare - Redraws provided square.
;
; INPUT:
;   A - board position (0-63)
;
; DESTROYS: All
;****************************************************************
BUI_DrawSquare:
    ;B - file (x)
    ;C - rank (y)
    ld c, a

    ld (_bui_index), a
    and 111b    ;calculate file (index & 0000_0111b)
    ld b, a
    
    srl c       ;calculate rank (index >> 3)
    srl c
    srl c

    add c       ;A = B + C

    srl a       ;move lowest bit to carry flag
    jr c, .isOdd 
.isEven:
    ld a, COLOR_BOARD_BLACK
    jr .skipIsOdd
.isOdd:
    ld a, COLOR_BOARD_WHITE
.skipIsOdd:
    push af ;preserve color

    ld a, 7
    sub c

    ld e, 30   ;calculate y
    ld d, a
    mlt de

    ld c, 30    ;calculate x
    mlt bc

    ;adjust coordinates if view is flipped. Both are recalculated as x = 240 - x.
    ld a, (bui_Perspective)
    or a
    jr nz, .boardPerspectiveWhite

    ld a, 210
    sub c
    ld c, a

    ld a, 210
    sub e
    ld e, a
.boardPerspectiveWhite:

    ld a, c
    ld (_bui_square_x), a
    ld a, e
    ld (_bui_square_y), a

;draw board square, note that DE/BC/A have the proper x/y/color arguments already
    pop af ;restore color
    ld hl, 30 * 256 + 30
    call GFX_FillRectangle

;draw chess piece
    ld hl, C_Board      ;load chess piece at square
    ld de, (_bui_index)
    add hl, de
    ld a, (hl)

    or a
    jr z, .skipDrawChessPiece

    ld (_bui_square_piece), a

    and MASK_PIECE_TYPE
    ld e, a             ;get sprite pointer
    ld d, 3
    mlt de
    ld hl, SPRITE_PIECE_TABLE
    add hl, de
    ld ix, (hl)

    ld bc, (_bui_square_x)
    ld de, (_bui_square_y)

    ld hl, COLOR_BOARD_PIECE_BLACK * 256 + COLOR_TRANSPARENT

    ld a, (_bui_square_piece)
    and MASK_PIECE_COLOR
    or a
    jr z, .pieceIsBlack
    ld h, COLOR_BOARD_PIECE_WHITE
.pieceIsBlack:

    call GFX_Sprite1Bpp

.skipDrawChessPiece:

    ret
