;****************************************************************
;
; Used to handle drawing the board/pieces/piece animations, and
; logic for cursor to select squares and promotions.
;
;****************************************************************

BUI_STATE_LOAD_LEGAL_MOVES := 0
BUI_STATE_SELECT_PIECE := 1
BUI_STATE_SELECT_DESTINATION := 2
BUI_STATE_SELECT_PROMOTION := 3

_BUI_State: db BUI_STATE_LOAD_LEGAL_MOVES
_BUI_CursorPosition: db 0
_BUI_StartSquare: db 0

;****************************************************************
; BUI_Reset - Reset ui state, call after loading new position.
;****************************************************************
BUI_Reset:
    xor a                   ;BUI_STATE_LOAD_LEGAL_MOVES
    ld (_BUI_State), a

    ;load cursor position with king position of side to move
    ld a, (C_CurrentColor)
    add PIECE_KING
    ld de, $0300
    ld e, a
    mlt de

    ld hl, PL_LUT
    add hl, de
    ld hl, (hl)             ;load king piecelist

    ld a, (hl)              ;load first position from king piecelist
    ld (_BUI_CursorPosition), a

    call BUI_DrawBoardForce

    ret

;****************************************************************
; BUI_GameTick - Game logic for board cursor. Only call if board
;   position is loaded.
;****************************************************************
BUI_GameTick:
    call BUI_UpdateCursor

    ld a, (_BUI_State)
    cp BUI_STATE_LOAD_LEGAL_MOVES
    call z, BUI_StateLoadLegalMoves

    ld a, (_BUI_State)
    cp BUI_STATE_SELECT_PIECE
    call z, BUI_StateSelectPiece

    ld a, (_BUI_State)
    cp BUI_STATE_SELECT_DESTINATION
    call z, BUI_StateSelectDestination

    ld a, (_BUI_State)
    cp BUI_STATE_SELECT_PROMOTION
    call z, BUI_StateSelectPromotion

    call BUI_DrawTick

    ret

;****************************************************************
; BUI_DrawTick - Handles all drawing logic.
;
; Destroys: All
;****************************************************************
BUI_DrawTick:

    call BUI_DrawBoard

    ret

;****************************************************************
; BUI_DrawBoardForce - Redraw all 64 squares, clear dirty squares
;   markers.
;
; Destroys: All
;****************************************************************
BUI_DrawBoardForce:
    ;clear dirty squares data
    ld hl, BUI_DirtySquares
    ld (hl), 0
    inc hl
    ld de, BUI_DirtySquares
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
; BUI_DrawBoard - Redraws only squares marked for redraw.
;
; DESTROYS: All
;****************************************************************
BUI_DrawBoard:
    ld hl, BUI_DirtySquares

    ld c, 0                 ;loop counter
.loop:
    ld a, (hl)
    or a
    jr z, .loopContinue

    ld (hl), 0
    push hl
    push bc
    ld a, c
    call BUI_DrawSquare
    pop bc
    pop hl
.loopContinue:
    inc hl
    inc c
    ld a, c
    cp 64
    jr nz, .loop

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
    and 111b                ;calculate file (index & 0000_0111b)
    ld (_bui_file), a
    ld b, a
    
    srl c                   ;calculate rank (index >> 3)
    srl c
    srl c

    ex af, af'              ;preserve A
    ld a, c
    ld (_bui_rank), a
    ex af, af'              ;restore A

    add c                   ;A = file + C (rank)

    srl a                   ;move lowest bit to carry flag
    ld a, COLOR_BOARD_WHITE
    jr c, .isOdd
.isEven:
    inc a                   ;COLOR_BOARD_BLACK is (COLOR_BOARD_WHITE + 1)
.isOdd:
    ex af, af'              ;preserve color

    ld a, 7
    sub c

    ld e, 30                ;calculate y
    ld d, a
    mlt de

    ld c, 30                ;calculate x
    mlt bc

    ;adjust coordinates if view is flipped. Both are recalculated as x = 240 - x.
    ld a, (BUI_Perspective)
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
    ex af, af'              ;restore color
    ld hl, 30 * 256 + 30
    call GFX_FillRectangle

    ;draw chess piece
    ld hl, C_Board          ;load chess piece at square
    ld de, (_bui_index)
    add hl, de
    ld a, (hl)

    or a
    jr z, .skipDrawChessPiece

    ld (_bui_square_piece), a

    and MASK_PIECE_TYPE
    ld e, a                 ;get sprite pointer
    ld d, 3
    mlt de
    ld hl, SPRITE_PIECE_TABLE
    add hl, de
    ld ix, (hl)

    ld bc, (_bui_square_x)
    ld de, (_bui_square_y)

    ld hl, COLOR_BOARD_PIECE_WHITE * 256 + COLOR_TRANSPARENT

    ld a, (_bui_square_piece)
    and MASK_PIECE_COLOR
    or a
    jr nz, .pieceIsWhite
    inc h                   ;COLOR_BOARD_PIECE_BLACK is (COLOR_BOARD_PIECE_WHITE + 1)
.pieceIsWhite:

    call GFX_Sprite1Bpp

.skipDrawChessPiece:

    ;draw cursor
    ld a, (_bui_index)
    ld hl, _BUI_CursorPosition
    cp (hl)
    jr nz, .skipDrawCursor

    ld ix, SPRITE_CURSOR
    ld bc, (_bui_square_x)
    ld de, (_bui_square_y)
    ld hl, COLOR_BOARD_CURSOR * 256 + COLOR_TRANSPARENT
    call GFX_Sprite1Bpp
.skipDrawCursor:

    ret

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; Internal subroutines of boardui.asm
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;****************************************************************
; BUI_UpdateCursor - (internal) Use keyboard input to move
;   board cursor.
;
; DESTROYS: All
;****************************************************************
BUI_UpdateCursor:
    call Cursor_GameTick

    ld de, 0                ;reset DE upper bytes for indexing 

    ;IXL/IXH is used as an offset to update the cursor square
    ld ix, 0                ;IXL = horizontal offset
                            ;IYL = vertical offset

    ld hl, Cursor_LeftPresses
    ld a, (hl)
    or a
    jr z, .noLeftKeyPress
    dec (hl)
    dec ixl
.noLeftKeyPress:

    ld hl, Cursor_RightPresses
    ld a, (hl)
    or a
    jr z, .noRightKeyPress
    dec (hl)
    inc ixl
.noRightKeyPress:

    ld hl, Cursor_UpPresses
    ld a, (hl)
    or a
    jr z, .noUpKeyPress
    dec (hl)
    ld ixh, 8
.noUpKeyPress:

    ld hl, Cursor_DownPresses
    ld a, (hl)
    or a
    jr z, .noDownKeyPress
    dec (hl)
    ld a, ixh
    sub 8
    ld ixh, a
.noDownKeyPress:

    ld a, ixl               ;early return if offsets are 0
    add ixh
    ret z
.doMovement:
    ld a, (_BUI_CursorPosition)
    ld e, a                 ;save copy of square index

    ld hl, BUI_DirtySquares ;redraw old cursor square
    add hl, de
    ld (hl), 1

    ;apply horizontal offset
    and 111000b             ;mask away file
    ld b, a                 ;save rank only index in B
    ld a, e                 ;get copy of square index
    add ixl                 ;adjust by horizontal offset
    and 000111b             ;mask away rank (also makes going left/right wrap-around)
    or b                    ;add old rank
    ;apply vertical offset
    ld e, a                 ;save copy of square index
    and 000111b             ;mask away rank
    ld b, a                 ;save file only index in B
    ld a, e
    add ixh
    and 111000b             ;mask away file
    or b                    ;add old file

    ld (_BUI_CursorPosition), a

    ld hl, BUI_DirtySquares ;redraw new cursor square
    ld e, a
    add hl, de
    ld (hl), 1

    ret

BUI_StateLoadLegalMoves:

    ret

BUI_StateSelectPiece:

    ret

BUI_StateSelectDestination:

    ret

BUI_StateSelectPromotion:

    ret
