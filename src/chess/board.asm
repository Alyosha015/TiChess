;****************************************************************
;
; Subroutines for making and undoing moves on the engine's chess
; board and updating all required state variables.
;
;****************************************************************

BOARD_STATE_STACK_SIZE := 3 * 64

_B_StateStackPtr: dl 0

_B_Move:                    ;this label is used to set the 3 bytes below
    _B_Move_Start: db 0     ;from a single register storing a move.
    _B_Move_End: db 0       ;don't change their order.
    _B_Move_Flag: db 0

_B_MovingPiece: db 0
_B_MovingType: db 0

;note that _B_CapturedPiece is in variables.asm
_B_CapturedType: db 0


;****************************************************************
; Board_PushBoardState - (internal) Push current game state on stack.
;
; DESTROYS: HL, DE
;****************************************************************
Board_PushBoardState:
    ld de, (B_BoardState)   ;push value
    ld hl, (_B_StateStackPtr)
    ld (hl), de

    inc hl                  ;update stack pointer
    inc hl
    inc hl

    ld (_B_StateStackPtr), hl

    ret

;****************************************************************
; Board_PopBoardState - (internal) Pop current game state from stack.
;
; DESTROYS: HL
;****************************************************************
Board_PopBoardState:
    ld hl, (_B_StateStackPtr)
    dec hl                  ;update stack pointer
    dec hl
    dec hl
    ld (_B_StateStackPtr), hl

    ld hl, (hl)             ;pop value
    ld (B_BoardState), hl

    ret

;****************************************************************
; Board_RemoveRookCastlingRights - (internal) Used to update
;   C_CastleFlags.
;
; INPUT:
;   A - Rook's square index.
;
; DESTROYS: A, IXL
;****************************************************************
Board_RemoveRookCastlingRights:
    or a
    jr z, .rook0
    cp 7
    jr z, .rook7
    cp 56
    jr z, .rook56
    cp 63
    jr z, .rook63

    ret                     ;early return if rook isn't in other positions

.rook0:                     ;white queenside castle
    ld ixl, not CASTLE_FLAG_WHITE_QUEEN
    jr .finish
.rook7:                     ;white kingside castle
    ld ixl, not CASTLE_FLAG_WHITE_KING
    jr .finish
.rook56:                    ;black queenside castle
    ld ixl, not CASTLE_FLAG_BLACK_QUEEN
    jr .finish
.rook63:                    ;black kingside castle
    ld ixl, not CASTLE_FLAG_BLACK_KING
.finish:

    ld a, (C_CastleFlags)
    and ixl
    ld (C_CastleFlags), a

    ret

;****************************************************************
; Board_MakeMove - Make move on board. Note that this assumes
;   that the variables set by Engine_SetIndexVariables are
;   already set.
;
; INPUT:
;   BC - move
;
; DESTROYS: All
;****************************************************************
Board_MakeMove:
    ld (_B_Move), bc
    ld de, 0
    ld bc, 0

    ;registers:
    ;   BC - temp
    ;   DE - temp
    ;   HL - temp
    ;   IX - reserved for storing piecelists
    ;   IYL - move start
    ;   IYH - move end

    ld a, (_B_Move_Start)
    ld iyl, a
    ld a, (_B_Move_End)
    ld iyh, a

    ld hl, C_Board          ;load moving and captured pieces
    ld e, iyl
    add hl, de
    ld a, (hl)
    ld (_B_MovingPiece), a
    and MASK_PIECE_TYPE
    ld (_B_MovingType), a

    ld hl, C_Board
    ld e, iyh
    add hl, de
    ld a, (hl)
    ld (_B_CapturedPiece), a
    and MASK_PIECE_TYPE
    ld (_B_CapturedType), a

    call Board_PushBoardState
    ld de, 0

    ;update ep file
    ld a, (_B_Move_Flag)
    cp MOVE_FLAG_EN_PASSANT
    jr nz, .skipUpdateEpFile
;( .updateEpFile: )
    ld a, (_B_Move_Start)   ;get move file
    and 0111b
    ld (C_EpFile), a
    jr .skipRemoveCapturedPiece ;if it's an EP capture, removing the captured
.skipUpdateEpFile:              ;piece is a special case handled later.

    ld a, EN_PASSANT_NONE   ;clear ep file by default
    ld (C_EpFile), a

    ;remove captured piece if it exists
    ld a, (_B_CapturedPiece)
    or a
    jr z, .skipRemoveCapturedPiece
;( .removeCapturedPiece: )
    ld d, 3                 ;piecelist LUT is indexed with (piece)*3
    ld e, a
    mlt de
    ld hl, PL_LUT
    add hl, de
    ld ix, (hl)             ;piecelist is now in IX

    ld e, iyh               ;square to remove in DE
    push iy                 ;preserve IY
    call PL_Remove
    pop iy                  ;restore IY

    ;if a rook is captured, those castling rights have to be removed
    and MASK_PIECE_TYPE     ;note that _B_CapturedPiece is still in A
    cp PIECE_ROOK
    jr nz, .skipRemoveCapturedPiece
;( .capturedRookCase: )
    ld a, iyh
    call Board_RemoveRookCastlingRights
.skipRemoveCapturedPiece:

    ;update moving piece on C_Board
    ld hl, C_Board
    ld e, iyl
    add hl, de
    ld a, (hl)              ;copy of moving piece in A
    ld (hl), PIECE_NONE

    ld hl, C_Board          ;copy moving piece to target square
    ld e, iyh
    add hl, de
    ld (hl), a
    
    ;update moving piece on PieceList
    ld a, (_B_MovingPiece)
    ld e, a
    ld d, 3
    mlt de

    ld hl, PL_LUT
    add hl, de
    ld ix, (hl)

    ld e, iyl               ;current square
    ld c, iyh               ;destination square
    push iy                 ;preserve IY
    call PL_Move
    pop iy                  ;restore IY

    ;if king moves update castle flags
    ld a, (_B_MovingType)
    cp PIECE_KING
    jr nz, .notKingMove
;( .kingMove: )
    ld c, not MASK_CASTLE_BLACK
    ld a, (C_CurrentColor)
    or a
    jr z, .removeBlackCastleFlags
;( .removeWhiteCastleFlags: )
    ld c, not MASK_CASTLE_WHITE
.removeBlackCastleFlags:
    ld a, (C_CastleFlags)
    and c
    ld (C_CastleFlags), a
.notKingMove:

    ;if rook moves update castle flags
    ld a, (_B_MovingType)
    cp PIECE_ROOK
    jr nz, .notRookMove
;( .rookMove: )
    ld a, iyl
    call Board_RemoveRookCastlingRights
.notRookMove:

    ;move flag special cases.
    ld a, (_B_Move_Flag)
    or a
    jp z, .moveFlagBreak

    ;note JP is used instead of JR because the largers jumps are out
    ;of range, so all were replaced with JP for consistency.
    cp MOVE_FLAG_DOUBLE_PAWN
    jp z, .moveFlagDoublePawn
    cp MOVE_FLAG_EN_PASSANT
    jp z, .moveFlagEnPassant
    cp MOVE_FLAG_CASTLE_KINGSIDE
    jp z, .moveFlagCastleKingside
    cp MOVE_FLAG_CASTLE_QUEENSIDE
    jp z, .moveFlagCastleQueenside
.moveFlagPromotion:         ;remaining move flags are promotions
    ;note that move_flag+1 gives the piece type of the promotion.

    ld a, (_B_MovingPiece)
    ld e, a
    ld d, 3
    mlt de

    ld hl, PL_LUT
    add hl, de
    ld ix, (hl)

    ld e, iyh               ;remove pawn from destination square since the
                            ;generalized MakeMove code will move it there.

    push iy                 ;preserve IY
    call PL_Remove
    pop iy                  ;restore IY

    ld a, (_B_Move_Flag)    ;get piece type
    inc a
    ld e, a
    ld a, (C_CurrentColor)  ;combine with current color to get piece
    add e

    ld hl, C_Board          ;update C_Board
    ld e, iyh
    add hl, de
    ld (hl), a

    ld c, a                 ;get PL_LUT index
    add a
    add c
    ld c, a

    ld hl, PL_LUT           ;load piecelist for promoted piece
    add hl, bc
    ld ix, (hl)

    push iy                 ;preserve IY
    call PL_Add             ;note that DE is still set from when
                            ;C_Board was updated
    pop iy                  ;restore IY

    jp .moveFlagBreak
.moveFlagDoublePawn:        ;update ep file with moved pawns file
    ld a, iyl
    and 0111b
    ld (C_EpFile), a
    jp .moveFlagBreak
.moveFlagEnPassant:         ;removes captured pawn
    ;enemy pawn is at square index (end + (whiteMoving ? -8 : 8))

    ld a, (C_CurrentColor)  ;current color = 0 (B) | 8 (W)
    add a                   ;(-2*CurrentColor+8) = 8 (B) | -8 (W)
    neg
    add 8

    add iyh                 ;offset move end square copy in E
    ld e, a

    ld hl, C_Board
    add hl, de
    ld c, (hl)              ;load enemy pawn to use as index to piecelist LUT
    ld (hl), PIECE_NONE

    ld b, 3                 ;load enemy pawn piecelist
    mlt bc
    ld hl, PL_LUT
    add hl, bc
    ld ix, (hl)

    push iy                 ;preserve IY
    call PL_Remove          ;note square index to pawn is still in DE
    pop iy                  ;restore IY

    jp .moveFlagBreak
.moveFlagCastleKingside:
    ld a, (C_CurrentColor)  ;load rook piecelist
    add PIECE_ROOK
    ld c, a
    add a                   ;A = 2A
    add c                   ;A = 2A + A = 3A
    ld e, a

    ld hl, PL_LUT
    add hl, de
    ld ix, (hl)

    ld a, (_B_Move_Start)   ;load rook position
    add 3
    ld e, a                 ;PL_Move source square

    ld hl, C_Board          ;move rook on C_Board (note C has the rook
                            ;number/color type saved from above)
    add hl, de
    ld (hl), 0              ;clear rook's start square
    dec hl                  ;move 2 square left and add rook
    dec hl
    ld (hl), c

    sub 2                   ;destination square (2 squares left)
    ld c, a                 ;PL_Move destination square parameter

    push iy                 ;preserve IY
    call PL_Move
    pop iy                  ;restore IY

    jp .moveFlagBreak
.moveFlagCastleQueenside:
    ld a, (C_CurrentColor)  ;load rook piecelist
    add PIECE_ROOK
    ld c, a
    add a                   ;A = 2A
    add c                   ;A = 2A + A = 3A
    ld e, a

    ld hl, PL_LUT
    add hl, de
    ld ix, (hl)

    ld a, (_B_Move_Start)   ;load rook position
    sub 4
    ld e, a                 ;PL_Move source square

    ld hl, C_Board          ;move rook on C_Board (note C has the rook
                            ;number/color type saved from above)
    add hl, de
    ld (hl), 0
    inc hl
    inc hl
    inc hl
    ld (hl), c

    add 3                   ;destination square (move rook 3 squares right)
    ld c, a                 ;PL_Move destination square parameter

    push iy                 ;preserve IY
    call PL_Move
    pop iy                  ;restore IY

    ;no break needed
.moveFlagBreak:

    ld a, (C_WhiteToMove)   ;swap side to move
    xor 1
    ld (C_WhiteToMove), a

    ret

;****************************************************************
; Board_UnmakeMove - Undo just played move on board.
;
; INPUT:
;   BC - move
;
; DESTROYS: All
;****************************************************************
Board_UnmakeMove:
    ld (_B_Move), bc
    ld de, 0
    ld bc, 0

    call Board_PopBoardState

    ;swap side to move, unlike Board_MakeMove this is done at the
    ;beginning so that the index variables aren't backwards.
    ld a, (C_WhiteToMove)
    xor 1
    ld (C_WhiteToMove), a

    call Engine_SetIndexVariables

    ;registers:
    ;   BC - temp
    ;   DE - temp
    ;   HL - temp
    ;   IX - reserved for storing piecelists
    ;   IYL - move start
    ;   IYH - move end

    ld a, (_B_Move_Start)
    ld iyl, a
    ld a, (_B_Move_End)
    ld iyh, a

    ld hl, C_Board          ;get moving piece
    ld e, iyh
    add hl, de
    ld a, (hl)
    ld (_B_MovingPiece), a
    and MASK_PIECE_TYPE
    ld (_B_MovingType), a

    ld a, (_B_CapturedPiece)
    and MASK_PIECE_TYPE
    ld (_B_CapturedType), a

    ;revert moving piece position on C_Board
    ld hl, C_Board          ;place moving piece to start square
    ld e, iyl
    add hl, de
    ld a, (_B_MovingPiece)
    ld (hl), a

    ;restore captured piece on C_Board and PieceList
    ld hl, C_Board          ;place captured piece (usually PIECE_NONE) on end square
    ld e, iyh
    add hl, de
    ld a, (_B_CapturedPiece)
    ld (hl), a

    or a                    ;_B_CapturedPiece, this skips if it equals PIECE_NONE
    jr z, .skipAddCapturedPieceToPieceList

    ld a, (_B_Move_Flag)
    cp MOVE_FLAG_EN_PASSANT
    jr z, .skipAddCapturedPieceToPieceList

    ld a, (_B_CapturedPiece);get PieceList using PL_LUT[piece * 3]
    ld e, a
    ld d, 3
    mlt de

    ld hl, PL_LUT
    add hl, de
    ld ix, (hl)

    ld e, iyh               ;PL_Add parameter
    push iy                 ;preserve IY
    call PL_Add
    pop iy                  ;restore IY
.skipAddCapturedPieceToPieceList:

    ;revert moving piece on piecelist
    ld a, (_B_MovingPiece)
    ld e, a
    ld d, 3
    mlt de

    ld hl, PL_LUT
    add hl, de
    ld ix, (hl)

    ld e, iyh               ;piece source square
    ld c, iyl               ;piece destination square
    push iy                 ;preserve IY
    call PL_Move
    pop iy                  ;restore IY

    ;move flag special cases.
    ld a, (_B_Move_Flag)
    or a
    ret z                   ;early return since there's no code after
                            ;the flag-specific logic.

    ;note JP is used instead of JR because the largers jumps are out
    ;of range, so all were replaced with JP for consistency.
    cp MOVE_FLAG_EN_PASSANT
    jp z, .moveFlagEnPassant
    cp MOVE_FLAG_CASTLE_KINGSIDE
    jp z, .moveFlagCastleKingside
    cp MOVE_FLAG_CASTLE_QUEENSIDE
    jp z, .moveFlagCastleQueenside
.moveFlagPromotion:         ;remaining move flags are promotions
    ;add pawn back to board
    ld a, (C_CurrentColor)  ;_B_MovingPiece doesn't work here since it would 
    add PIECE_PAWN          ;store the piece the pawn promoted into.
    ld e, a
    ld d, 3
    mlt de

    ld hl, PL_LUT
    add hl, de
    ld ix, (hl)

    ld e, iyl

    ld hl, C_Board          ;add pawn on C_Board. Note that A has the moving piece definition.
    add hl, de
    ld (hl), a

    push iy                 ;preserve IY
    call PL_Add
    pop iy                  ;restore IY

    ;remove promoted piece from piecelist
    ld a, (_B_Move_Flag)    ;move_flag + 1 = piece type
    inc a
    ld e, a
    ld a, (C_CurrentColor)
    add e

    ld e, a
    ld d, 3
    mlt de

    ld hl, PL_LUT
    add hl, de
    ld ix, (hl)

    ld e, iyh
    push iy                 ;preserve IY
    call PL_Remove
    pop iy                  ;restore IY

    jp .moveFlagBreak
.moveFlagEnPassant:
    ;calculate square of captured pawn. ( MoveEndSquare + (CurrentColorIsWhite ? -8 : 8) )

    ld a, (C_CurrentColor)  ;results in -8 if C_CurrentColor was 8, 8 if C_CurrentColor was 0
    add a
    neg
    add 8

    add iyh
    ld e, a                 ;DE = enemy pawn square

    ld a, (C_EnemyColor)    ;load captured pawn type
    add PIECE_PAWN

    ld hl, C_Board          ;update C_Board
    add hl, de
    ld (hl), a

    ld c, a                 ;get piecelist
    ld b, 3
    mlt bc
    ld hl, PL_LUT
    add hl, bc
    ld ix, (hl)

    push iy                 ;preserve IY
    call PL_Add             ;note that the pawn's square index is still in DE
    pop iy                  ;restore IY

    jp .moveFlagBreak
.moveFlagCastleKingside:
    ld a, (C_CurrentColor)  ;load rook piecelist
    add PIECE_ROOK
    ld e, a
    add a                   ;A = 2A
    add e                   ;A = 2A + A = 3A
    ld c, a

    ld hl, PL_LUT
    add hl, bc
    ld ix, (hl)

    ld a, (_B_Move_Start)
    add 3
    ld c, a                 ;PL_Move destination square

    ld hl, C_Board          ;move rook on C_Board (note E has the rook
                            ;number/color type saved from above)
    add hl, bc
    ld (hl), e
    dec hl
    dec hl
    ld (hl), 0

    sub 2                   ;source square
    ld e, a                 ;PL_Move source square parameter

    push iy                 ;preserve IY
    call PL_Move
    pop iy                  ;restore IY

    jp .moveFlagBreak
.moveFlagCastleQueenside:
    ld a, (C_CurrentColor)  ;load rook piecelist
    add PIECE_ROOK
    ld e, a
    add a                   ;A = 2A
    add e                   ;A = 2A + A = 3A
    ld c, a

    ld hl, PL_LUT
    add hl, bc
    ld ix, (hl)

    ld a, (_B_Move_Start)
    sub 4
    ld c, a                 ;PL_Move destination square

    ld hl, C_Board          ;move rook on C_Board (note E has the rook
                            ;number/color type saved from above)
    add hl, bc
    ld (hl), e
    inc hl
    inc hl
    inc hl
    ld (hl), 0

    add 3                   ;source square
    ld e, a                 ;PL_Move source square parameter

    push iy                 ;preserve IY
    call PL_Move
    pop iy                  ;restore IY
.moveFlagBreak:

    ret
