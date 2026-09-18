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
_BUI_SelectedSquare: db -1
_BUI_SelectedSquareMoveCount: db 0
_BUI_SelectedPromotionSquare: db 0  ;stores destination square of promoting pawn

_BUI_LegalMoves: dl 0       ;stores pointer to allocated move list
_BUI_LegalMovesCount: db 0  ;number of legal moves
_BUI_HasPromotionMove: db 0 ;true when selected piece can promote on it's move


;used as temporary storage to access individual bytes of a move instruction
_BUI_Move:                  ;this label is used to set the 3 bytes below
    _BUI_Move_Start: db 0   ;from a single register storing a move.
    _BUI_Move_End: db 0
    _BUI_Move_Flag: db 0


;****************************************************************
; BUI_Init - Call once on program start.
;****************************************************************
BUI_Init:
    call AllocMoves
    ld (_BUI_LegalMoves), ix

    ret

;****************************************************************
; BUI_Free - Call once on program exit.
;****************************************************************
BUI_Free:
    ld ix, (_BUI_LegalMoves)
    call FreeMoves

    ret

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

    call BUI_ClearSelectedSquare

    call BUI_DrawBoardForce

    ret

;****************************************************************
; BUI_GameTick - Game logic for board cursor. Only call if board
;   position is loaded.
;****************************************************************
BUI_GameTick:
    call BUI_UpdateCursor

    ld a, (_BUI_State)
    or a                    ;cp BUI_STATE_LOAD_LEGAL_MOVES (optimization)
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

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; SECTION: Game logic for human player making moves.
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;****************************************************************
; BUI_MakeCastleEpSquaresForRedraw - (internal) Covers the edge
;   case square redraw for en passant captures and castling,
;   where a piece moves or is removed on squares not on the end
;   square of the move.
;
; INPUT: Assume _BUI_Move is loaded with move to be played.
;
; DESTROYS: A, HL, DE
;****************************************************************
BUI_MakeCastleEpSquaresForRedraw:
    ld a, (_BUI_Move_Flag)  ;early return if move flag is 0
    or a
    ret z

    ld hl, BUI_DirtySquares
    ld de, 0

    cp MOVE_FLAG_EN_PASSANT
    jr nz, .notEnPassant
;( .enPassant: )
    ld a, (C_CurrentColor)  ;current color = 0 (B) | 8 (W)
    add a                   ;(-2*CurrentColor+8) = 8 (B) | -8 (W)
    neg
    add 8

    ld e, a
    ld a, (_BUI_Move_End)
    add e
    ld e, a

    add hl, de
    ld (hl), 1

    ret
.notEnPassant:

    cp MOVE_FLAG_CASTLE_KINGSIDE
    jr nz, .notCastleKingside
;( .castleKingside: )
    ld a, (_BUI_Move_End)   ;rook is one square to right of move end square
    inc a
    ld e, a
    add hl, de
    ld (hl), 1

    ret
.notCastleKingside:

    cp MOVE_FLAG_CASTLE_QUEENSIDE
    ret nz
;( .castleQueenside: )
    ld a, (_BUI_Move_End)   ;rook is two squares left of move end square
    dec a
    dec a
    ld e, a
    add hl, de
    ld (hl), 1

    ret

;****************************************************************
; BUI_ClearSelectedSquare - (internal) Clear all data about
;   currently selected square and it's legal moves. Also marks
;   selected/destination squares for redraw.
;
; DESTROYS: All
;****************************************************************
BUI_ClearSelectedSquare:
    ;before clearing arrays, mark square with move
    ;destination markers for redraw.
    ld a, (_BUI_SelectedSquare)
    ld hl, BUI_DirtySquares
    ld de, 0
    ld e, a
    add hl, de
    ld (hl), 1

    ld a, (_BUI_SelectedSquareMoveCount)
    or a
    jr z, .loopBreak        ;will happen when called on initilization
    ld ix, BUI_MovesForSelectedPiece
    ld b, a
.loop:
    push bc                 ;preserve loop counter
    ld bc, (ix)
    lea ix, ix+3
    
    ld hl, BUI_DirtySquares
    ld e, b                 ;move end square
    add hl, de
    ld (hl), 1

    pop bc                  ;restore loop counter
    djnz .loop
.loopBreak:
    ;clear legal moves lookup data (192*2 B)
    ld hl, BUI_SquareToMove
    ld (hl), 0
    ld de, BUI_SquareToMove+1
    ld bc, 383              ;64 * 6 - 1
    ldir

    ld a, -1
    ld (_BUI_SelectedSquare), a
    ld (_BUI_SelectedPromotionSquare), a

    xor a
    ld (_BUI_HasPromotionMove), a
    ld (_BUI_SelectedSquareMoveCount), a

    ret

;****************************************************************
; BUI_ClearPromotionSelectionSquares - (internal) Mark the
;   squares used for showing pieces promotion options to redraw.
;   Used when entering and exiting promotion selection state.
;
; DESTROYS: A, DE, BC, IX
;****************************************************************
BUI_ClearPromotionSelectionSquares:
    ld a, (_BUI_SelectedPromotionSquare)

    ld ix, BUI_DirtySquares
    ld de, 0
    ld e, a                 ;move end square
    add ix, de

    ld a, (C_CurrentColor)
    add a
    jr z, .colorIsBlack
    ld de, $FFFFFF          ;is white is promoting, the offset should be -8 so DE
.colorIsBlack:              ;needs to be all 1's. Otherwise it's already $0000XX

    neg
    add 8
    ld e, a

    ld b, 4
.loop:
    ld (ix), 1
    add ix, de

    djnz .loop

    ret

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

;****************************************************************
; BUI_LoadPieceMoves - (internal) Used to check if current cursor
;   square has moves, and to store them for quick access if so in
;   BUI_MovesForSelectedPiece and BUI_SquareToMove.
;
; OUTPUT:
;   Z - RESET if square has piece with moves, SET if no moves
;
; DESTROYS: All
;****************************************************************
BUI_LoadPieceMoves:
    ld a, (_BUI_LegalMovesCount)
    or a
    ret z                   ;return if there are no legal moves,
                            ;although this shouldn't happen
    ld ix, (_BUI_LegalMoves)
    ld iy, BUI_MovesForSelectedPiece

    ex af, af'              ;zero A', which stores if a legal move for the square was found.
    xor a
    ex af, af'

    ld b, a                 ;init loop counter with legal move count
.loop:
    push bc                 ;preserve loop counter
    ld de, (ix)
    lea ix, ix+3
    ld (_BUI_Move), de

    ld a, (_BUI_Move_Start)
    ld hl, _BUI_CursorPosition
    cp (hl)
    jr nz, .loopContinue

    ex af, af'              ;legal move was found!
    inc a
    ex af, af'

    ld (iy), de             ;store move in BUI_MovesForSelectedPiece
                            ;note DE still stores the move from above
    lea iy, iy+3

    ld hl, BUI_SquareToMove ;store move in BUI_SquareToMove
                            ;where BUI_SquareToMove[endSquareIndex * 3] = move
    ld b, 3
    ld a, (_BUI_Move_End)
    ld c, a
    mlt bc
    add hl, bc
    ld (hl), de             ;note DE still stores the move from above
    ;B doesn't need to be zeroed since the max value is 63*3 < 256

    ;mark destination square for redraw
    ld hl, BUI_DirtySquares
    ld de, 0
    ld e, a
    add hl, de
    ld (hl), 1

    ;note if move is a promotion
    ld a, (_BUI_Move_Flag)
    cp MOVE_FLAG_PROMOTE_QUEEN
    jr c, .notPromotionMove ;jump on less than
    cp MOVE_FLAG_PROMOTE_KNIGHT+1
    jr nc, .notPromotionMove;jump on greater than or equal to
    
.isPromotionMove:
    ld a, 1
    ld (_BUI_HasPromotionMove), a
.notPromotionMove:

.loopContinue:
    pop bc                  ;restore loop counter
    djnz .loop

    ex af, af'              ;reset Z-flag if moves for square were found 
    ld (_BUI_SelectedSquareMoveCount), a
    or a

    ret

BUI_StateLoadLegalMoves:
    ld ix, (_BUI_LegalMoves)
    call MoveGen_Generate

    ld a, (MG_MoveCount)
    ld (_BUI_LegalMovesCount), a

    ld a, BUI_STATE_SELECT_PIECE
    ld (_BUI_State), a

    ret

BUI_StateSelectPiece:
    ;don't do anything until square selection is attempted
    ld hl, Cursor_EnterPressed
    ld a, (hl)
    or a
    ret z

    dec (hl)

    call BUI_LoadPieceMoves
    ret z                   ;early return if no moves are found
                            ;for selected square

    ;mark move start square for redraw
    ld hl, BUI_DirtySquares
    ld de, 0
    ld a, (_BUI_CursorPosition)
    ld e, a
    add hl, de
    ld (hl), 1

    ld (_BUI_SelectedSquare), a

    ld a, BUI_STATE_SELECT_DESTINATION
    ld (_BUI_State), a

    ret

BUI_StateSelectDestination:
    ;don't do anything until square selection is attempted
    ld hl, Cursor_EnterPressed
    ld a, (hl)
    or a
    ret z

    dec (hl)

    ld a, (_BUI_CursorPosition)
    ld d, 3
    ld e, a
    mlt de
    ld hl, BUI_SquareToMove
    add hl, de
    ld bc, (hl)
    ld (_BUI_Move), bc
    or a                    ;clear carry flag
    sbc hl, hl              ;clear hl
    sbc hl, bc              ;zero flag will be set if BC=0
    jp z, .noMoveAtSquare
.moveAtSquare:
    ld a, (_BUI_HasPromotionMove)
    or a
    jr nz, .promotionMove
.notPromotionMove:
    ;if it's not a promotion move, the move can be played now.

    call BUI_MakeCastleEpSquaresForRedraw
    call Engine_MakeMove    ;BC still has the move stored
    call BUI_ClearSelectedSquare

    ld a, BUI_STATE_LOAD_LEGAL_MOVES
    ld (_BUI_State), a

    ret
.promotionMove:
    ;in the case of a promotion the chessboard draws the new piece options like this:
    ;
    ; . . . Q . . . .
    ; . . . N . . . .
    ; . . . B . . . .
    ; . . . R . . . .
    ;

    ;zero BUI_SquareToMove. Can't use BUI_ClearSelectedSquare since that
    ;also clears BUI_MovesForSelectedPiece which is still needed.
    ld hl, BUI_SquareToMove
    ld (hl), 0
    ld de, BUI_SquareToMove+1
    ld bc, 191              ;64 * 3 - 1
    ldir

    ;promotion square offset. Note this will be used to go from the edge of the board
    ;where the pawn is promoting to towards the center.
    ld a, (C_CurrentColor)  ;current color = 0 (B) | 8 (W)
    add a                   ;(-2*CurrentColor+8) = 24 (B) | -24 (W)
    ld c, a                 ;C=A*2
    add a, a                ;A=A*4
    add c                   ;A=A*6 = 0 (B) | 48 (W)
    neg
    add 24

    exx ;alt reg start    
    ld bc, $FFFFFF          ;load square offset into BC'
    jp m, .offsetIsNegative
    ld bc, 0
.offsetIsNegative:
    
    ld c, a

    ld a, (_BUI_CursorPosition)
    ld (_BUI_SelectedPromotionSquare), a
    ld de, 0
    ld e, a                 ;DE = A * 3
    add a, a
    add e
    ld e, a

    ld hl, BUI_SquareToMove ;offset BUI_SquareToMove to move destination square
    add hl, de
    exx ;alt reg end

    ld ix, BUI_MovesForSelectedPiece
    ld a, (_BUI_SelectedSquareMoveCount)
    ld b, a
.promotionMoveLoop:
    ld de, (ix)             ;get next move
    lea ix, ix+3
    ld (_BUI_Move), de

    ld a, (_BUI_Move_End)   ;check that moves destination matches cursor position
    ld hl, _BUI_CursorPosition
    cp (hl)
    jr nz, .promotionMoveLoopContinue

    push de                 ;transfer move in DE to DE'
    exx ;alt reg start
    pop de
    ld (hl), de             ;store in BUI_SquareToMove
    add hl, bc              ;offset BUI_SquareToMove (-24 | 24)
    exx ;alt reg end

.promotionMoveLoopContinue:
    djnz .promotionMoveLoop

    call BUI_ClearPromotionSelectionSquares
    call GFX_LoadColorPalettePromotion

    ld a, BUI_STATE_SELECT_PROMOTION
    ld (_BUI_State), a

    ret
.noMoveAtSquare:

    ;add ENTER keypress into queue so that Select Piece state tries to
    ;select the current square without pressing twice. However, if the
    ;cursor is on the selected square don't incremented so that the
    ;piece doesn't get re-selected again.

    ld a, (_BUI_SelectedSquare)
    ld hl, _BUI_CursorPosition
    cp (hl)
    jr z, .pieceStartSquareClicked
    ld hl, Cursor_EnterPressed
    inc (hl)
.pieceStartSquareClicked:

    call BUI_ClearSelectedSquare

    ld a, BUI_STATE_SELECT_PIECE
    ld (_BUI_State), a

    ret

BUI_StateSelectPromotion:
    ;early return until enter keypress
    ld hl, Cursor_EnterPressed
    ld a, (hl)
    or a
    ret z

    dec (hl)                ;clear enter keypress

    ;can be loaded now since the palette returns to normal
    ;in both cases of either playing a promotion move or
    ;canceling the promotion move.
    call GFX_LoadColorPaletteNormal

    ;load move at cursor position
    ld a, (_BUI_CursorPosition)
    ld d, 3
    ld e, a
    mlt de
    ld hl, BUI_SquareToMove
    add hl, de
    ld bc, (hl)
    ld (_BUI_Move), bc

    ;check if move is zero
    or a                    ;clear carry flag
    sbc hl, hl              ;clear hl
    sbc hl, bc              ;zero flag will be set if BC=0
    jr z, .noMoveAtSquare

    ;play promotion move

    call Engine_MakeMove    ;BC still has the move stored
    call BUI_ClearPromotionSelectionSquares
    call BUI_ClearSelectedSquare

    ld a, BUI_STATE_LOAD_LEGAL_MOVES
    ld (_BUI_State), a

    ret
.noMoveAtSquare:            ;if no move, reset to selecting a piece
    ;cancel move
    
    call BUI_ClearPromotionSelectionSquares
    call BUI_ClearSelectedSquare

    ld a, BUI_STATE_SELECT_PIECE
    ld (_BUI_State), a

    ret

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; SECTION: Graphics drawing subroutines for board.
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

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
    ld de, BUI_DirtySquares+1
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
    call LCD_WaitForRefresh

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
_bui_square_color: db 0 ;WHITE=1 BLACK=0

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

    ld e, 1                 ;_bui_square_color
    srl a                   ;move lowest bit to carry flag
    ld a, COLOR_BOARD_WHITE
    jr c, .isOdd
.isEven:
    dec a                   ;COLOR_BOARD_BLACK is (COLOR_BOARD_WHITE - 1)
    dec e                   ;if black decrement to make E=0
.isOdd:
    ex af, af'              ;preserve color

    ;if square is selected use selected square color
    ld a, (_bui_index)
    ld hl, _BUI_SelectedSquare
    cp (hl)
    jr nz, .notSelectedSquare
    ex af, af'
    add COLOR_BOARD_SELECTED_WHITE-COLOR_BOARD_WHITE
    ex af, af'
.notSelectedSquare:

    ld a, e
    ld (_bui_square_color), a

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

    ld hl, C_Board          ;load chess piece at square for later
    ld de, (_bui_index)
    add hl, de
    ld a, (hl)
    ld (_bui_square_piece), a

    ;draw move destination markers / piece selection for promotion mode.
    ;if in promotion mode, MOVE_FLAG + 1 gives the piece type to draw 
    ld hl, BUI_SquareToMove
    ld de, (_bui_index)
    ld d, 3
    mlt de
    add hl, de
    ld bc, (hl)
    or a                    ;clear carry flag
    sbc hl, hl              ;clear hl
    sbc hl, bc              ;zero flag will be set if BC=0
    jr z, .skipDrawMoveDestinationMarker

    ld a, (_BUI_State)
    cp BUI_STATE_SELECT_PROMOTION
    jr nz, .skipPromotionMode
;( .promotionMode: )

    call BUI_DrawSquarePromotion    ;note move for this square is in BC.

    jr .skipDrawChessPiece  ;skip drawing marker and normal piece
.skipPromotionMode:
    ld ix, SPRITE_MOVE_DESTINATION_MARKER_SMALL
    ld a, (_bui_square_piece)
    or a
    jr z, .hasNoChessPiece
    ld ix, SPRITE_MOVE_DESTINATION_MARKER_LARGE
.hasNoChessPiece:
    ld bc, (_bui_square_x)
    ld de, (_bui_square_y)
    ld hl, COLOR_BOARD_LEGAL_MOVE_WHITE * 256 + COLOR_TRANSPARENT
    ld a, (_bui_square_color)
    add COLOR_BOARD_LEGAL_MOVE_BLACK
    ld h, a

    call GFX_Sprite1Bpp
.skipDrawMoveDestinationMarker:

    ;draw chess piece
    ld a, (_bui_square_piece)
    or a
    jr z, .skipDrawChessPiece

    and MASK_PIECE_TYPE
    ld e, a                 ;get sprite pointer
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
    inc h                   ;COLOR_BOARD_PIECE_WHITE is (COLOR_BOARD_PIECE_BLACK + 1)
.pieceIsBlack:

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

;****************************************************************
; BUI_DrawSquarePromotion - Called from BUI_DrawSquare, used when
;   in promotion mode to draw squares with the piece selection. 
;
; INPUT:
;   BC - Move at square (from BUI_SquareToMove)
;
; DESTROYS: All
;****************************************************************
BUI_DrawSquarePromotion:
    ;cursor is still drawn later by BUI_DrawSquare after this function returns,
    ;so this function only needs to handle drawing the square itself, piece,
    ;and any rank/file labels if those are added later.

    ld (_BUI_Move), bc      ;get piece type
    ld a, (_BUI_Move_Flag)
    inc a
    ex af, af'

    ld a, (_bui_square_color)
    add COLOR_BOARD_P_BLACK
    
    ld bc, (_bui_square_x)
    ld de, (_bui_square_y)
    ld hl, 30 * 256 + 30
    call GFX_FillRectangle

    ex af, af'              ;restore piece type (GFX_FillRectangle preserves A')
    
    ld e, a                 ;get sprite pointer
    ld d, 3
    mlt de
    ld hl, SPRITE_PIECE_TABLE
    add hl, de
    ld ix, (hl)

    ld bc, (_bui_square_x)
    ld de, (_bui_square_y)

    ld hl, COLOR_BOARD_PIECE_BLACK * 256 + COLOR_TRANSPARENT

    ld a, (C_CurrentIndex)
    add COLOR_BOARD_P_PIECE_BLACK
    ld h, a

    call GFX_Sprite1Bpp

    ret
