MG_KING_NONE := 255

_MG_Moves: dl 0             ;stores pointer to move-list
_MG_MovesNext: dl 0         ;stores pointer to next empty 3 byte cell in move-list,
                            ;stored in MG_Moves. Simplifies adding next move.

MG_MoveCount: db 0          ;tracks number of moves added to move-list

;internal variables used by move generator

_MG_InDoubleCheck: db 0

_MG_CanCastleKingside: db 0 ;for king castle move generation
_MG_CanCastleQueenside: db 0

_MG_EpPossible: db 0        ;for pawn move generation
_MG_PawnDoubleAdvanceRank: db 0
_MG_PawnPromotionRank: db 0
_MG_PawnOffsetForward: db 0
_MG_PawnEpSquare: db 0

_MG_EnemyQueenPl: dl 0      ;for enemy attack/check/pin map generation
_MG_EnemyQueenCount: db 0
_MG_EnemyRookPl: dl 0
_MG_EnemyRookCount: db 0
_MG_EnemyBishopPl: dl 0
_MG_EnemyBishopCount: db 0

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; SECTION: UTILITY FUNCTIONS - helper subroutines, they are
;   the most generalized parts of the move generator.
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;****************************************************************
; MoveGen_CountCheck - (internal) increment inCheck / inDoubleCheck
;
; DESTROYS: A
;****************************************************************
MoveGen_CountCheck:
    ld a, (C_InCheck)
    ld (_MG_InDoubleCheck), a

    ld a, 1
    ld (C_InCheck), a

    ret

;****************************************************************
; MoveGen_AddMove - (internal) adds move to movelist.
;
; INPUT:
;   D - start square of move
;   E - end square of move
;
; DESTROYS: HL, A
;****************************************************************
MoveGen_AddMove:
    xor a
;****************************************************************
; MoveGen_AddMove - (internal) adds move to movelist with flag.
;
; INPUT:
;   A - flag
;   D - start square of move
;   E - end square of move
;
; DESTROYS: HL
;****************************************************************
MoveGen_AddMoveFlag:
    ld hl, MG_MoveCount
    inc (hl)

    ld hl, (_MG_MovesNext)
    ld (hl), d
    inc hl
    ld (hl), e
    inc hl
    ld (hl), a
    inc hl
    ld (_MG_MovesNext), hl

    ret

;****************************************************************
; MoveGen_MovingOnRay - (internal) used for checking if a square
;   and direction form a ray away from the current king's square.
;   This is generaly used to determine if a piece is moving along
;   a pin-ray during sliding move generation, and similary for
;   pawn captures.
;
; INPUT:
;   C - piece's square
;   B - dirOffset
;   DE - $0000XX
;
; OUTPUT:
;   Sets Z flag if true.
;
; DESTROYS: A, HL, DE=$0000XX
;****************************************************************
MoveGen_MovingOnRay:
    ld a, (C_CurrentKing)   ;LUT_SquareToSquareDir is indexed by [63 + square - raySource]
    neg                     ;raySource is the king's position.
    add 63
    add c

    ld hl, LUT_SquareToSquareDir
    ld e, a
    add hl, de

    ld a, (hl)              ;now, we check if the direction matches the moveOffset
    cp b                  ;(or it's negative, since that's parallel)
    ret z

    neg                     ;check negative
    cp b
    ret

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; SECTION: ENEMY'S PERSEPECTIVE ATTACK/CHECK/PIN MAP GENERATION
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;****************************************************************
; MoveGen_GeneratePinMaps - (internal) Used to look at attacking 
;   pieces from the "persepective" of the king, to determine if
;   there are any checks and pins from sliding pieces.
;
; DESTROYS: All
;****************************************************************
MoveGen_GeneratePinMaps:
    ld de, 0

    exx ;alt reg start
    ld bc, 0 * 256 + 8          ;initial value checks all directions

    ld ixl, 1                   ;initial isOrthogonal value, assumes rooks/queens exist

    ld a, (_MG_EnemyQueenCount)   ;if there are any queens, skip the below checks.
    or a
    jr nz, .hasQueens

    ld a, (_MG_EnemyRookCount)    ;if there are no rooks, don't check first 4 directions
    or a
    jr nz, .hasRooks
    ld b, 4
    dec ixl                     ;if there are no rooks, the first direction checked will be diagonal.
.hasRooks:

    ld a, (_MG_EnemyBishopCount)  ;if there are no bishops, don't check last 4 directions
    or a
    jr nz, .hasBishops
    ld c, 4
.hasBishops:
.hasQueens:
    exx ;alt reg end

    ;registers:
    ;   B - squares-to-edge squareLoop counter (decrements)
    ;   C - targetPiece
    ;   HL - temp
    ;   DE - temp
    ;   IXL - isOrthogonal (dir < 4)
    ;   IXH - foundFriendlyPiece
    ;   IYL - direction offset
    ;   IYH - target square
    ;shadow registers:
    ;   B - direction start (increments)
    ;   C - direction end + 1 (similar to DE' in MoveGen_GenerateEnemySlidingAttackMap)
    ;   DE - temp
    ;   HL - temp

.dirLoop:
    ld a, (C_CurrentKing)
    ld iyh, a

    ld hl, LUT_DirOffset    ;load dirOffset from dirIndex
    exx ;alt reg start
    ld a, b ;get dirIndex
    exx ;alt reg end
    ld e, a
    add hl, de
    ld a, (hl)
    ld iyl, a

    ld d, 8 ;square-to-edge = LUT_SquaresToEdge[square * 8 + dirIndex]
    ld e, iyh
    mlt de
    ld a, e ;add dirIndex
    exx ;alt reg start
    add b
    exx ;alt reg end
    ld e, a
    ld hl, LUT_SquaresToEdge
    add hl, de
    ld b, (hl)

    ld d, 0 ;partially clear DE after using mlt de, which can affect D

    ld a, b ;skip squareLoop if B = 0
    or a
    jr z, .squareLoopBreak

    ld ixh, 0       ;reset foundFriendlyPiece
.squareLoop:
    ld a, iyh       ;update target square
    add iyl
    ld iyh, a

    ld hl, C_Board  ;get target piece
    ld e, iyh
    add hl, de
    ld c, (hl)
    ld a, c
    or a        ;continue to next square in direction if square is empty (PIECE_NONE = 0)
    jr z, .squareLoopContinue

;friendly color tracking.
;if a friendly piece is found on the line twice, we know there can't be a pin.
;this is also used to trigger an early squareLoop break.
    and MASK_PIECE_COLOR
    ld hl, C_CurrentColor
    cp (hl)
    jr nz, .isEnemyPiece
;( .isFriendlyPiece: )
    ld a, ixh
    or a
    jr nz, .squareLoopBreak ;if foundFriendlyPiece was already 1, we can
                            ;stop looping in this direction early.

    inc ixh                 ;runs if foundFriendlyPiece = 0, setting it to 1.

    jr .squareLoopContinue
.isEnemyPiece:
    ;enemy piece case.
    ;if the enemy piece is a slider and can attack in the direction of this line,
    ;(not a rook on a diagonal direction from th eking for example), then we need to mark
    ;the line on the check/pin map. If there was a friendly piece found blocking it's only
    ;a pin, otherwise it's a check. Note that it the sliding piece can't attack or it's
    ;another type of piece then we can break since it would block any further sliding
    ;pieces with a chance of attacking.

    ld a, c
    and MASK_PIECE_TYPE
    cp PIECE_QUEEN
    jr z, .sliderCanAttack

    cp PIECE_ROOK
    jr nz, .notRook
    dec ixl ;if isOrthogonal was 1, then this would set the zero flag
    jr z, .sliderCanAttack
    inc ixl ;if the above failed, isOrthogonal is now 255, so reset back to 0.
            ;otherwise the check for isBishop could have IXL = 255 | 0 | 1
.notRook:

    dec ixl ;if isOrthogonal is 1, this would set the zero flag
    jr z, .squareLoopBreak  ;break since this only checks for diagonal sliders (bishops)

    cp PIECE_BISHOP         ;this check is only reached if the line is diagonal, so if it's
                            ;a bishop then it can definitely attack in the king's direction.
    jr z, .sliderCanAttack

    jr .squareLoopBreak     ;break if not a bishop
.sliderCanAttack:

    ;put offset DE into IYL, so HL holding map can be stepped through directly.
    ;since the offset can be a negative number, DE will be converted to this by
    ;setting the upper bits to all 1's, making it the equivalent negative number
    ;when IYL is copied in E.
    ld a, iyl
    and 1000_0000b  ;check for sign bit
    jr z, .directionOffsetIsPositive
;( .directionOffsetIsNegative: )
    ld de, $FFFFFF
.directionOffsetIsPositive:
    ld e, iyl

    ld a, (C_CurrentKing)   ;load king position, used in both checkMap and pinMap case
    ld c, a                 ;preserve king position for when MoveGen_CountCheck runs.

    ld hl, C_PinMap

    dec ixh                 ;sets Z flag if isFriendlyPiece is 1
    jr z, .isPin
;( .isCheck ):  ;foundFriendlyPiece was 0
    ld hl, C_CheckMap
    call MoveGen_CountCheck ;(note: destroys A)
.isPin:         ;foundFriendlyPiece was 1
    ld b, 0     ;offset HL to king's position. Note that BC can be overwritten since
                ;the squareLoop breaks right after this check/pinmap is marked.
    ld a, c     ;restore king position to A.
    add hl, bc

    ;marks every square from king to current square on the current line on selected map.
.mapLoop:
    add iyl ;A tracks target square for the mapLoop, loaded with king position above

    add hl, de
    ld (hl), 1

    cp iyh  ;loop until current target square (found in squareLoop) is reached
    jr nz, .mapLoop

    ld de, 0                ;reset DE fully incase the top byte was $FF

    jr .squareLoopBreak
.squareLoopContinue:
    dec b
    jr nz, .squareLoop
.squareLoopBreak:

    exx ;alt reg start
    inc b
    ld a, b

    ld ixl, 0
    cp 4    ;calculate isOrthogonal while dirIndex is in A
    jr nc, .dirIndexGTE4
    inc ixl ;runs when dirIndex is less than 4, so it's othogonal
            ;(note ixl = 0 above, so we can increment here)
.dirIndexGTE4:

    cp c
    exx ;alt reg end
    jp nz, .dirLoop

    ret

;****************************************************************
; MoveGen_GenerateEnemySlidingAttackMap - (internal) enemy moves
;   for queen / rook / bishop.
;
; INPUT:
;   IX - selected piece list pointer.
;   A - number of pieces in piece list.
;   B - start direction (0-7)
;   C - end direction (1-8) (offset by 1, C=8 -> end at 7)
;
;   DE = $0000XX
;
; DESTROYS: All, DE = $0000XX
;****************************************************************
MoveGen_GenerateEnemySlidingAttackMap:
    push bc ;preserve start / end direction
    exx ;alt reg start
    ld c, a ;init pieceLoop counter
    pop de  ;restore start / end direction
    exx ;alt reg end

.pieceLoop:
    exx ;alt reg start
    push de ;preserve start / end direction
    ld a, d
    exx ;alt reg end

;registers:
;   A - temp
;   B - squares-to-edge squareLoop counter (decrements)
;   C - target square (in squareLoop)
;   HL - temp
;   DE - temp
;   IX - piecelist pointer
;   IYL - direction offset
;   IYH - current dirIndex (copy of D')
;shadow registers:
;   B - 
;   C - piece loop counter (decrements)
;   D - current direction (increments)
;   E - max direction

;loops through every possible direction of current sliding piece
.dirLoop:
    ;note: register A used to transfer D' (current direction) to E
    ;A is assumed to have the current direction already stored.
    ld e, a
    ld iyh, a

    ;get direction offset
    ld hl, LUT_DirOffset
    add hl, de
    ld e, (hl)
    ld iyl, e

    ld c, (ix)  ;current piece position (target square)

    ;calculate squares to edge: LUT_SquaresToEdge[square * 8 + dirIndex]
    ld d, 8
    ld e, c
    mlt de  ;DE = square * 8

    ld a, e ;E = E + dirIndex
    add iyh
    ld e, a

    ld hl, LUT_SquaresToEdge
    add hl, de
    ld b, (hl)

    ld d, 0 ;prepare for using DE as an offset in the loop
            ;(MLT DE instruction would have effected it above)
            ;also needed for the outer loops to work with DE properly.

    ld a, b ;skip loop if B=0 (otherwise DJNZ decrements B and overflows to B=255)
    or a
    jr z, .squareLoopBreak

.squareLoop:
    ld a, c ;calculate next target square (square += dirOffset), load to DE
    add iyl
    ld c, a
    ld e, a

    ld hl, C_AttackMap  ;mark square on attack map
    add hl, de
    ld (hl), 1

    ;early return from loop if there's a target piece in the way and it's not the king.
    ld hl, C_CurrentKing    ;check if A (has target square from above code) matches the
    cp (hl)                 ;current king's position, in which case continue looping.
    jr z, .squareLoopContinue

    ;if this king isn't there, check if another piece is in the way
    ld hl, C_Board          ;get target piece
    add hl, de
    ld a, (hl)
    or a                    ;since PIECE_NONE = 0
    jr nz, .squareLoopBreak
.squareLoopContinue:
    djnz .squareLoop
.squareLoopBreak:

    exx ;alt reg start
    inc d
    ld a, d ;doubles as loading A = dirIndex for next loop
    cp e
    exx ;alt reg end
    jr nz, .dirLoop

    inc ix  ;increment pointer to next piece in PL
    exx ;alt reg start
    pop de  ;restore start / end direction (if loop exits stack will be clear aswell)
    dec c
    exx ;alt reg end
    jr nz, .pieceLoop

    ret

;****************************************************************
; MoveGen_GenerateEnemySlidingAttackMaps - (internal) uses
;   MoveGen_GenerateEnemySlidingAttackMap to create attack maps
;   for the 3 types of sliding pieces.
;
; DESTROYS: All
;****************************************************************
MoveGen_GenerateEnemySlidingAttackMaps:
    ld de, 0    ;needed for MoveGen_GenerateEnemySlidingAttackMap

    ld ix, (_MG_EnemyQueenPl)
    ld a, (_MG_EnemyQueenCount)
    or a
    ld bc, 0 * 256 + 8
    call nz, MoveGen_GenerateEnemySlidingAttackMap

    ld ix, (_MG_EnemyRookPl)
    ld a, (_MG_EnemyRookCount)
    or a
    ld bc, 0 * 256 + 4
    call nz, MoveGen_GenerateEnemySlidingAttackMap

    ld ix, (_MG_EnemyBishopPl)
    ld a, (_MG_EnemyBishopCount)
    or a
    ld bc, 4 * 256 + 8
    call nz, MoveGen_GenerateEnemySlidingAttackMap

    ret

;****************************************************************
; MoveGen_GenerateEnemyKnightAttackMap - (internal) enemy knight
;   attack map / check map generation.
;
; DESTROYS: All
;****************************************************************
MoveGen_GenerateEnemyKnightAttackMap:
    ld hl, (C_EnemyPlPtr)       ;load knight piecelist
    ld de, PIECE_KNIGHT * 3     ;note that DE=$0000XX after this
    add hl, de
    ld ix, (hl)

    ld a, (ix + PL_DATA_SIZE)   ;number of knights
    or a
    ret z                       ;early return if there are no knights
    ld c, a                     ;number of knights loop counter

    ld a, (C_CurrentKing)       ;load current king position into IYL
    ld iyl, a

.knightLoop:
    ld a, (ix)                  ;get knight square
    ld iyh, a
    inc ix

    push ix                     ;preserve knight piecelist

    ld ix, LUT_KnightMoveCount  ;get number of valid knight moves for this square
    ld e, iyh
    add ix, de
    ld b, (ix)

    ld ix, LUT_KnightMovement   ;destination square = LUT_KnightMovement[square * 8 + index]
    ld d, 8
    ; ld e, iyh                 ;note that E = IYH from above code already
    mlt de
    add ix, de
    ld d, 0                     ;reset so DE=$0000XX after MLT instruction

.moveLoop:
    ld e, (ix)
    inc ix

    ld hl, C_AttackMap
    add hl, de
    ld (hl), 1
    
    ld a, iyl                   ;if king position and knight attack position match,
    cp e                        ;the king is now in check.
    jr nz, .notInCheck

    ld hl, C_CheckMap           ;update checkmap / checkcount
    ld e, iyh
    add hl, de
    ld (hl), 1
    call MoveGen_CountCheck
.notInCheck:
    djnz .moveLoop

    pop ix                      ;restore knight piecelist

    dec c
    jr nz, .knightLoop

    ret

;****************************************************************
; MoveGen_GenerateEnemyPawnAttackInDirection - (internal) called
;   from MoveGen_GenerateEnemyPawnAttackMap, handles AttackMap
;   and CheckMap handling given a pawn position and attack direction.
;
; INPUT:
;   C - pawn position
;   IYH - attack direction offset
;
;   DE = $0000XX
;
; DESTROYS: A, B, HL, DE
;****************************************************************
MoveGen_GenerateEnemyPawnAttackInDirection:
    ld a, c                     ;calculate target square
    add iyh
    ld b, a

    ld hl, C_AttackMap
    ld e, b
    add hl, de
    ld (hl), 1

    ld a, (C_CurrentKing)       ;if king is attacked by this move,
    cp b                        ;update checkmap and check count.
    ret nz                      ;otherwise early return.

    ld hl, C_CheckMap
    ld e, c
    add hl, de
    ld (hl), 1

    call MoveGen_CountCheck

    ret

;****************************************************************
; MoveGen_GenerateEnemyPawnAttackMap - (internal) enemy pawn
;   attack map / check map generation. Destroys all/alt registers.
;
;   Note that this calculates the pawn attacks, so diagonal moves.
;****************************************************************
MoveGen_GenerateEnemyPawnAttackMap:
    ld hl, (C_EnemyPlPtr)       ;load pawn piecelist
    ld de, PIECE_PAWN * 3       ;DE = $0000XX
    add hl, de
    ld ix, (hl)

    ld a, (ix + PL_DATA_SIZE)   ;get number of pawns and early return if 0
    or a
    ret z

    exx ;alt reg start
    ld c, a                     ;pawn loop counter
    exx ;alt reg end

    ;registers:
    ;   B - target square
    ;   C - pawn square
    ;   HL - temp
    ;   DE - temp
    ;   IX - pawn piecelist
    ;   IYL - pawn file
    ;   IYH - pawn attack direction offset
    ;shadow registers:
    ;   C - pawn loop counter (decrements)

    ;calculate pawn attack direction offset for west direction.
    ;by adding 2 it can become the east attack direction, while
    ;still preserving if it's north or south.
    ld iyh, OFFSET_NW
    ld a, (C_EnemyColor)
    or a
    jr nz, .isWhite
;( .isBlack: )
    ld iyh, OFFSET_SW
.isWhite:

.pawnLoop:
    ld a, (ix)                  ;get pawn position
    inc ix

    ld c, a                     ;copy pawn position
    and 0111b                   ;calculate pawn file (column)
    ld iyl, a                   ;save file to IYL
    or a
    jr z, .pawnFileIs0
    ;can go west (or left from white's perspective)

    call MoveGen_GenerateEnemyPawnAttackInDirection

.pawnFileIs0:
    inc iyh                     ;convert to east attack direction
    inc iyh

    ld a, iyl                   ;get file
    cp 7
    jr z, .fileIs7
    ;can go east (or right from white's perspective)

    call MoveGen_GenerateEnemyPawnAttackInDirection

.fileIs7:
    dec iyh                     ;convert to west attack direction
    dec iyh

    exx ;alt reg start
    dec c
    exx ;alt reg end
    jr nz, .pawnLoop

    ret

;****************************************************************
; MoveGen_GenerateEnemyKingAttackMap - (internal) enemy king
;   attack map generation. Destroys all registers.
;****************************************************************
MoveGen_GenerateEnemyKingAttackMap:
    ld hl, LUT_KingMoveCount    ;get number of valid moves into register B (loop counter)
    ld de, 0
    ld e, a
    add hl, de
    ld b, (hl)

    ld ix, LUT_KingMovement
    ld d, 8
    ; ld e, a                   ;note that E = A from above code already
    mlt de
    add ix, de
    ld d, 0                     ;clear so DE=$0000XX after MLT instruction

.kingMoveLoop:
    ld e, (ix)
    inc ix

    ld hl, C_AttackMap
    add hl, de
    ld (hl), 1

    djnz .kingMoveLoop

    ret

;****************************************************************
; MoveGen_GenerateAttackMaps - (internal) creates attack/check/
;   pin maps.
;
; DESTROYS: All
;****************************************************************
MoveGen_GenerateAttackMaps:
    ld a, (C_EnemyKing)
    cp MG_KING_NONE
    call nz, MoveGen_GenerateEnemyKingAttackMap

    ld a, (C_CurrentKing)
    cp MG_KING_NONE
    call nz, MoveGen_GeneratePinMaps

    call MoveGen_GenerateEnemySlidingAttackMaps

    call MoveGen_GenerateEnemyKnightAttackMap
    call MoveGen_GenerateEnemyPawnAttackMap

    ret

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; SECTION: MOVE GENERATOR FROM CURRENT SIDE'S PERSPECTIVE - does
;   the "actual" move generation.
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;****************************************************************
; MoveGen_GenerateKingMoves - (internal) moves for current king.
;
; INPUT:
;   A - king's position
;
; DESTROYS: All
;****************************************************************
MoveGen_GenerateKingMoves:
    ld c, a

    ;registers:
    ;   B - king move count
    ;   C - king position
    ;   DE - temp
    ;   HL - temp
    ;   IX - n/a
    ;   IY - king moves LUT

    ld hl, LUT_KingMoveCount    ;get number of valid moves into register B (loop counter)
    ld de, 0
    ld e, a
    add hl, de
    ld b, (hl)

    ;load IY
    ld d, 8 ;note that e already has king position from accessing LUT_KingMoveCount
    mlt de
    ld iy, LUT_KingMovement
    add iy, de
    ld d, 0 ;clear DE since the multiply instruction can affect D.

.kingMoveLoop:
    ld e, (iy) ;load E with move destination
    inc iy

    ld hl, C_AttackMap ;king can't move to attacked square
    add hl, de
    ld a, (hl)
    or a
    jr nz, .kingMoveLoopContinue

    ld hl, C_Board ;check for friendly piece on square
    add hl, de
    ld a, (hl)
    or a
    jr z, .targetSquareEmpty
    and MASK_PIECE_COLOR
    ld hl, C_CurrentColor
    cp (hl)
    jr z, .kingMoveLoopContinue

.targetSquareEmpty:
    ld d, c
    call MoveGen_AddMove ;note that E already has the target square loaded
    ld d, 0 ;reset DE to be $0000XX

.kingMoveLoopContinue:
    djnz .kingMoveLoop

    ;note that king position is still in C

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;   Castling move generation section
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

    ld a, (C_InCheck)   ;chess rule: can't castle while in check
    or a
    ret nz

    ;* * * * * * * * Kingside Castling * * * * * * * *

    ld a, (_MG_CanCastleKingside)    ;check if castle flag is set
    or a
    jr z, .skipKingsideCastle

    ;check if path for kingside castling is clear:
    ;consists of the 2 squares to the right of the king.
    ;checks that there are no pieces in the way and that
    ;the squares are not being attacked.

    ld hl, C_Board      ;init board and attack map pointers to king's position
    ld e, c
    add hl, de

    ld ix, C_AttackMap
    add ix, de

    ld b, 2             ;loop 2 times (checks the 2 squares to the right
                        ;of the king's position)
.kingsideLoop:
    inc hl              ;increment first, so the first square checked
    ld a, (hl)          ;is to the right of the king's position.
    or a
    jr nz, .skipKingsideCastle  ;can't castle if path is blocked by piece

    inc ix
    ld a, (ix)
    or a
    jr nz, .skipKingsideCastle  ;can't castle if path is attacked

    djnz .kingsideLoop

    ld d, c             ;start of move (king position)
    ld e, c             ;target of move (king position + 2)
    inc e
    inc e
    ld a, MOVE_FLAG_CASTLE_KINGSIDE
    call MoveGen_AddMoveFlag
    ld d, 0

.skipKingsideCastle:

    ;* * * * * * * * Queenside Castling * * * * * * * *

    ld a, (_MG_CanCastleQueenside)
    or a
    jr z, .skipQueensideCastle

    ld hl, C_Board
    ld e, c
    add hl, de

    ld ix, C_AttackMap
    add ix, de

    ld b, 3             ;this loop needs to check that the 3 square
                        ;between the king and rook are clear of pieces,
                        ;but only if the 2 square to the left aren't
                        ;being attacked. To still do this in one loop the
                        ;attack map will be offset by 1 and also check the
                        ;king's current square, which is technically a
                        ;redundant check for the king being in check.

.queensideLoop:
    dec hl
    ld a, (hl)
    or a
    jr nz, .skipQueensideCastle

    ld a, (ix)
    dec ix
    or a
    jr nz, .skipQueensideCastle

    djnz .queensideLoop

    ld d, c             ;start of move (king position)
    ld e, c             ;target of move (king position + 2)
    dec e
    dec e
    ld a, MOVE_FLAG_CASTLE_QUEENSIDE
    call MoveGen_AddMoveFlag
    ld d, 0

.skipQueensideCastle:

    ret

;****************************************************************
; MoveGen_GenerateSlidingMoves - (internal) Used to create moves
;   for sliding pieces, with input for range of directions to check
;   to make it work for bishop/rook/queen movement.
;
; INPUT:
;   IX - selected piecelist pointer.
;   A - number of pieces in piecelist.
;   B - start direction (0-7)
;   C - end direction (1-8) (offset by 1, C=8 -> end at 7)
;
;   DE = $0000XX
;
; DESTROYS: All
;****************************************************************
MoveGen_GenerateSlidingMoves:
    push bc ;preserve start / end direction
    exx ;alt reg start
    ld c, a ;init pieceLoop counter
    pop de  ;restore start / end direction
    lea hl, ix
    exx ;alt reg end

    ;registers:
    ;   B - squares-to-edge (squareLoop, decrement)
    ;   C - target piece (squareLoop)
    ;   DE - temp
    ;   HL - temp
    ;   IXL - piece target position in squareLoop
    ;   IXH - pin-ray direction (pinned if != 0, since it can't have a pin direction of 0)
    ;   IYL - dirOffset
    ;   IYH - square (piece position)
    ;shadow registers:
    ;   B - 
    ;   C - piece loop counter (decrements)
    ;   D - current direction (increments)
    ;   E - max direction
    ;   HL - piecelist pointer

.pieceLoop:
    exx ;alt reg start
    push de ;preserve start / end direction
    ld a, (hl)  ;get piece position
    inc hl
    exx ;alt reg end
    ld iyh, a   ;save piece position

    ;if the king is in check and this piece is pinned, it can be skipped.
    ld ixh, 0 ;init isPinned

    ld e, a
    ld hl, C_PinMap
    add hl, de
    ld a, (hl)
    or a
    jr z, .pieceSquareNotPinned

    ld a, (C_InCheck)   ;this only runs if pinned, so if the king is in check we know
    or a                ;this piece doesn't have any legal moves since moving it to
                        ;block the check would open another attack line on the king.
    jp nz, .pieceLoopContinue

    ;this will be needed later to determine if the sliding piece's direction matches the direction
    ;of the pin-ray it is on with the king, which would limit it's legal moves.
    ld a, (C_CurrentKing)   ;LUT_SquareToSquareDir is indexed by [63 + square - raySource]
    neg                     ;raySource is the king's position.
    add 63
    add iyh

    ld hl, LUT_SquareToSquareDir
    ld e, a
    add hl, de
    ld a, (hl)
    ld ixh, a           ;set pin-ray direction
.pieceSquareNotPinned:

    exx ;alt reg start
    ld a, d     ;load current direction index
    exx ;alt reg end
.dirLoop:       ;note: expects current dirIndex in A
    ;lookup dirOffset
    ld e, a
    ld b, a     ;save dirIndex to temp B variable for now

    ;registers:
    ;   B - dirIndex

    ld hl, LUT_DirOffset
    add hl, de
    ld a, (hl)
    ld iyl, a

    ;if this square is pinned and not moving along the pin-ray's direction,
    ;then we can skip checking this direction.
    ld a, ixh
    or a
    jr z, .squareNotPinned

    ;we check the negative dirOffset as well, since those are parallel
    ;to each other (one could be a rook moving away from a king, and
    ;the negative a rook moving toward a king)
    cp iyl
    jr z, .dirOnPinRay

    neg
    cp iyl
    jr z, .dirOnPinRay
    jr .dirLoopContinue
.dirOnPinRay:
.squareNotPinned:

    ;lookup squares-to-edge
    ld hl, LUT_SquaresToEdge
    ld d, 8
    ld e, iyh
    mlt de
    ld a, e
    add b       ;dirIndex (saved to B at start of dirLoop)
    ld e, a
    add hl, de
    ld b, (hl)  ;squareLoop decrement variable
    ld d, 0     ;reset DE to be a $0000XX value

    ld a, b     ;skip squareLoop if B=0, otherwise when decrementing DJNZ would overflow to B=255
    or a
    jr z, .squareLoopBreak

    ld a, iyh   ;init destination square to IXL (starts from piece location,
    ld ixl, a   ;with offset added in loop)
.squareLoop:
    ld a, ixl
    add iyl
    ld ixl, a

    ld hl, C_Board  ;load target piece
    ld e, ixl
    add hl, de
    ld c, (hl)

    ;break squareLoop if target piece is friendly
    ld a, c
    or a
    jr z, .targetSquareEmpty    ;(PIECE_NONE = 0)
    and MASK_PIECE_COLOR
    ld hl, C_CurrentColor
    cp (hl)
    jr z, .squareLoopBreak
.targetSquareEmpty:

    ld a, (C_InCheck)   ;only add the piece after passing a check test 
                        ;(if inCheck the target square is marked on the check map)
    or a
    jr z, .skipCheckTest

    ld hl, C_CheckMap
    add hl, de  ;note that DE still have target square as the offset 
                ;from accessing C_Board.
    ld a, (hl)
    or a
    jr z, .checkTestFail
.skipCheckTest:
;( .checkTestPass: )

    ld d, iyh
    call MoveGen_AddMove    ;note that E already has the target square
    ld d, 0
.checkTestFail:

    ;break if this was a capture move, since that limits how
    ;many squares the sliding piece can move in this direction.
    ld a, c
    or a
    jr nz, .squareLoopBreak

    djnz .squareLoop
.squareLoopBreak:

.dirLoopContinue:
    exx ;alt reg start
    inc d
    ld a, d ;also acts as loading A = dirIndex for next loop
    cp e
    exx ;alt reg end
    jr nz, .dirLoop
.dirLoopBreak:

.pieceLoopContinue:
    exx ;alt reg start
    pop de  ;restore start / end direction (if loop exits stack will be clear aswell)
    dec c
    exx ;alt reg end
    jp nz, .pieceLoop    

    ret

;****************************************************************
; MoveGen_GenerateAllSlidingMoves - (internal) generates moves
;   for all sliding-type pieces.
;
; DESTROYS: All
;****************************************************************
MoveGen_GenerateAllSlidingMoves:
    ld hl, (C_CurrentPlPtr)
    ld de, PIECE_QUEEN * 3
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)
    or a
    ld bc, 0 * 256 + 8
    call nz, MoveGen_GenerateSlidingMoves

    ld hl, (C_CurrentPlPtr)
    ld de, PIECE_ROOK * 3
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)
    or a
    ld bc, 0 * 256 + 4
    call nz, MoveGen_GenerateSlidingMoves

    ld hl, (C_CurrentPlPtr)
    ld de, PIECE_BISHOP * 3
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)
    or a
    ld bc, 4 * 256 + 8
    call nz, MoveGen_GenerateSlidingMoves

    ret

;****************************************************************
; MoveGen_GenerateKnightMoves - (internal) moves for knight.
;
; DESTROYS: All
;****************************************************************
MoveGen_GenerateKnightMoves:
    ld hl, (C_CurrentPlPtr)
    ld de, PIECE_KNIGHT * 3
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)
    or a
    ret z       ;early return if there are 0 knights

    exx ;alt reg start
    ld b, a ;load knight loop counter
    exx ;alt reg end

    ;registers:
    ;   B - knight move count (moveLoop counter, decrements)
    ;   C - knight position
    ;   DE - temp
    ;   HL - temp
    ;   IX - knight piece list
    ;   IY - knight moves LUT
    ;shadow registers:
    ;   B - number of knights (knightLoop counter, decrements)
    ;   C - n/a

.knightLoop:
    ld c, (ix)      ;load next knight
    inc ix

    ld hl, C_PinMap ;if the knight's position is marked on the pinmap,
    ld e, c         ;it doesn't have legal moves and can be skipped.
    add hl, de
    ld a, (hl)
    or a
    jr nz, .knightLoopContinue

    ;lookup number of moves
    ld hl, LUT_KnightMoveCount
    add hl, de
    ld b, (hl)

    ;first index of move LUT to IY
    ld d, 8 ;note that e already has knight position from accessing LUT_KnightMoveCount
    mlt de
    ld iy, LUT_KnightMovement
    add iy, de

    ld d, 0 ;clear DE since the multiply instruction can affect D.

.moveLoop:
    ld e, (iy)      ;load move destination square
    inc iy

    ld hl, C_Board  ;note destination square is already in DE
    add hl, de
    ld a, (hl)      ;target piece

    or a                    ;can proceed if square is empty (PIECE_NONE = 0)
    jr z, .addMoveCheckTest

    and MASK_PIECE_COLOR    ;can proceed if square has enemy piece
    ld hl, C_EnemyColor
    cp (hl)
    jr nz, .moveLoopContinue
.addMoveCheckTest:
    ;continue if the king is in check and the dest. square isn't marked on the check map
    ;this means that moving there won't eliminate the check, so it's an illegal move.

    ld a, (C_InCheck)
    or a
    jr z, .skipCheckTest

    ld hl, C_CheckMap
    add hl, de
    ld a, (hl)
    or a
    jr z, .moveLoopContinue
.skipCheckTest:

    ld d, c
    call MoveGen_AddMove
    ld d, 0 ;reset to use DE for indexing on subsequent loops.

.moveLoopContinue:
    djnz .moveLoop

.knightLoopContinue:
    exx ;alt reg start
    dec b
    exx ;alt reg end
    jr nz, .knightLoop

    ret

;****************************************************************
; MoveGen_ValidateEnPassantCapture - (internal) called from
;   MoveGen_GeneratePawnCaptureInDirection, checks that the capture
;   is legal. Since an ep capture is the only chess move where
;   the capturing piece lands on a different square than the
;   piece it captured, it can cause an edge case where the captured
;   piece can expose a sliding piece attack on a king, making
;   the move illegal.
;
; INPUT:
;   C - pawn square
;   DE = $0000XX
;
; OUTPUT:
;   Sets Z flag if legal.
;
; DESTROYS: All except BC, C', DE=$0000XX
;****************************************************************
MoveGen_ValidateEnPassantCapture:
    ;calculate enemy pawn square
    ld a, (C_CurrentIndex)  ;since target rank is 4 if white to move
    add 3                   ;or 3 if black to move, simply add 3 to
                            ;the current index.

    ld ixl, a               ;save enemy pawn rank

    ld e, a                 ;multiply rank by 8
    sla e
    sla e
    sla e

    ld a, (C_EpFile)        ;add ep file to get enemy pawn square.
    add e
    ld ixh, a

    ;registers:
    ;   B - target square
    ;   C - pawn square
    ;   DE - temp
    ;   HL - temp
    ;   IXH - enemy pawn square
    ;   IXL - enemy pawn rank
    ;   IYH - 
    ;   IYL -
    
    ;early return: if the king and enemy pawn don't share
    ;the same rank or a diagonal, the special case can't happen.

    ;to check if there's a diagonal, the difference between the
    ;king's and pawn's file and rank must match. Since we don't
    ;know which are negative, we test FileDiff==RankDiff and
    ;FileDiff==-RankDiff, which covers all cases.

    ld a, (C_CurrentKing)
    srl a
    srl a
    srl a

    sub ixl                 ;rank difference.
    ld e, a

    ld a, (C_CurrentKing)   ;get king file
    and 0111b
    ld hl, C_EpFile         ;calculate file difference
    sub (hl)
    ld d, a

    cp e
    jr z, .skipEarlyReturn  ;if rank and file difference match

    neg
    cp e
    jr z, .skipEarlyReturn  ;if rank and file differnce match (negative cases)

    ld a, e                 ;if rank difference is 0 skip early return.
    or a
    jr z, .skipEarlyReturn

    xor a                   ;early return with zero flag set.
    ret
.skipEarlyReturn:

    ;note that E holds the rank difference and D holds the file differnce

    ;since there is a diagonal or orthogonal line, now the direction from
    ;the king to the ep square has to be determined. Eventually a search
    ;will be done to see if an enemy slider piece exists along this line
    ;which threatens the king if the capture is made.

    ;registers:
    ;   IYH - is orthogonal direction (diagonal otherwise)
    ;   IYL - direction offset index

    ld iyh, 0

    ld a, e                 ;check if rank difference is 0, meaning an
    or a                    ;orthogonal slider could threaten the king.
    jr nz, .rankDiffNEQ0

    inc iyh                 ;since it was set to 0 by default.
    ld iyl, OFFSET_E_INDEX

    ld a, d                 ;determine if direction is east or west
    or a                    ;from file difference.
    jp m, .endCalculateDirIndex ;.fileDiffNegativeOrthogonal ;(optimization)
    ld iyl, OFFSET_W_INDEX
;.fileDiffNegativeOrthogonal:
    jr .endCalculateDirIndex
.rankDiffNEQ0:
    ;calculate direction index if diagonal
    ld a, d
    or a
    jp m, .fileDiffNegative
;( .fileDiffPositive: )     ;western direction
    ld iyl, OFFSET_NW_INDEX
    ld a, e
    or a
    jp m, .endCalculateDirIndex ;.rankDiffNegativeFileDiffPositive ;(optimization)
;( .rankDiffPositiveFileDiffPositive: )
    ld iyl, OFFSET_SW_INDEX
    jr .endCalculateDirIndex
;.rankDiffNegativeFileDiffPositive:
.fileDiffNegative:          ;eastern direction
    ld iyl, OFFSET_NE_INDEX
    ld a, e
    or a
    jp m, .endCalculateDirIndex ;.rankDiffNegativeFileDiffNegative ;(optimization)
;( .rankDiffPositiveFileDiffNegative: )
    ld iyl, OFFSET_SE_INDEX
;.rankDiffNegativeFileDiffNegative
.skipRankDiffNEQ0:
.endCalculateDirIndex:

    ;registers:
    ;   B - target square
    ;   C - pawn square
    ;   IYL - offset direction index
    ;   IYH - is orthogonal
    ;   IXL - is legal
    ;   IXH - enemy pawn square

    ld ixl, 1               ;assumed legal by default

    ld d, 0                 ;D/E isn't needed anymore, reset so DE=$0000XX

    ;remove friendly and enemy pawn from board to simulate capture.
    ld hl, C_Board
    ld e, c
    add hl, de
    ld (hl), PIECE_NONE

    ld hl, C_Board
    ld e, ixh
    add hl, de
    ld (hl), PIECE_NONE

    push bc                 ;preserve BC

    ;note that squares to edge is always greater than zero since
    ;in the EP legality check to take place the enemy pawn needs to
    ;be on a line away from the king (meaning at least one square),
    ;so the B=0 check to prevent DJNZ from overflowing isn't needed.
    ld hl, LUT_SquaresToEdge
    ld d, 8
    ld a, (C_CurrentKing)
    ld e, a
    mlt de
    ld a, e
    add iyl
    ld e, a
    add hl, de
    ld b, (hl)              ;store loop counter in B
    ld d, 0                 ;DE=$0000XX

    ld hl, LUT_DirOffset    ;store direction offset in IYL
    ld e, iyl
    add hl, de
    ld a, (hl)
    ld iyl, a

    ;registers:
    ;   IYL - direction offset

    ld a, (C_CurrentKing)
    ld e, a

.squareLoop:
    ld a, e                 ;update target square
    add iyl
    ld e, a

    ld hl, C_Board          ;loop until a piece is found
    add hl, de
    ld a, (hl)
    or a
    jr z, .squareLoopContinue
;( .foundPiece: )

    ld c, a                 ;save copy of piece

    ld hl, C_CurrentColor   ;stop if not friendly piece
    and MASK_PIECE_COLOR
    cp (hl)
    jr z, .endLegalityCheck

    ld a, c                 ;load piece type
    and MASK_PIECE_TYPE
    cp PIECE_QUEEN          ;check for queen before orthogonal/diagonal check
    jr z, .pieceCanAttack

    dec iyh                 ;sets zero flag if IYH (IsOrthogonal) was 1
    jr z, .isOrthogonal
;( .isDiagonal: )
    cp PIECE_BISHOP
    jr z, .pieceCanAttack
    jr .endLegalityCheck
.isOrthogonal:
    cp PIECE_ROOK
    jr z, .pieceCanAttack
    jr .endLegalityCheck

.pieceCanAttack:
    dec ixl                 ;set IXL to 0 (it was initialized to 1)
    jr .endLegalityCheck

.squareLoopContinue:
    djnz .squareLoop
;( .squareLoopBreak: )
.endLegalityCheck:

    pop bc                  ;restore bc

    ld hl, C_Board          ;restore friendly and enemy pawn board positions
    ld e, c
    add hl, de
    ld a, (C_CurrentColor)
    add PIECE_PAWN
    ld (hl), a

    ld hl, C_Board
    ld e, ixh
    add hl, de
    ld a, (C_EnemyColor)
    add PIECE_PAWN
    ld (hl), a

    dec ixl                 ;if IXL was 0 (illegal), with will make IXL=255
                            ;and reset the zero flag. If IXL was 1 (legal),
                            ;this will make IXL=0 and set the zero flag.
    ret

;****************************************************************
; MoveGen_GeneratePawnCaptureInDirection - (internal) called by
;   MoveGen_GeeratePawnCaptureMoves, handles all move generation
;   cases for moving a provided pawn in the provided diagonal
;   direction.
;
; INPUT:
;   C - pawn square
;   IYL - direction offset
;   IXL - is promotion rank
;   DE - $0000XX
;
; DESTROYS: All except C', C, IYL, IYH, IXL
;****************************************************************
MoveGen_GeneratePawnCaptureInDirection:
    ld a, c                 ;calculate target square, store in B 
    add iyl
    ld b, a

    ld hl, C_PinMap         ;early return if pawn is pinned and
    ld e, c                 ;diagonal move is not along pin-ray
    add hl, de
    ld a, (hl)
    or a
    jr z, .skipPinCheck

    push bc ;preserve BC
    ld b, iyl
    call MoveGen_MovingOnRay
    pop bc ;restore BC
    ret nz                  ;return if not on pin-ray
.skipPinCheck:

    ld hl, C_Board          ;get piece at target square
    ld e, b
    add hl, de
    ld a, (hl)
    or a
    jr z, .targetSquareEmpty

    and MASK_PIECE_COLOR    ;early return if piece is friendly
    ld hl, C_EnemyColor
    cp (hl)
    ret nz

    ld a, (C_InCheck)       ;check test for target square
    or a                    ;with early return on fail.
    jr z, .skipCheckTest
    
    ld hl, C_CheckMap
    ld e, b
    add hl, de
    ld a, (hl)
    or a
    ret z
.skipCheckTest:
    ;now the moves have been validated as legal, the only case
    ;left is if it's a normal capture is a promotion.
    ld d, c                 ;load start and end squares for
    ld e, b                 ;MoveGen_AddMove parameters.

    ld a, ixl
    or a
    jr nz, .isPromotion
    call MoveGen_AddMove
    ld d, 0                 ;reset D so DE=$0000XX
    ret                     ;early return now that move was added

.isPromotion:
    ld a, 1                 ;1..4 are promotion move flags
.promotionMoveLoop:
    call MoveGen_AddMoveFlag

    inc a
    cp 5
    jr nz, .promotionMoveLoop

    ld d, 0                 ;reset D so DE=$0000XX

    ret                     ;don't check for En Passant captures
                            ;since the target square has a piece,
                            ;so we can return early.

;( .checkForEpCapture: )
.targetSquareEmpty:         ;if the target square is empty an
                            ;En Passant capture is still possible.
    ld a, (_MG_EpPossible)
    or a
    ret z                   ;early return if there's no EP possible this move.
                            ;"possible" meaning that an enemy pawn double advanced
                            ;last move which caused a C_EpFile to be stored in the
                            ;state.

    ld a, (_MG_PawnEpSquare);early return if the target square isn't the Ep Square
    cp b
    ret nz

    ld a, (C_InCheck)       ;check test with early return on fail.
    or a
    jr z, .skipCheckTestEp

    ld hl, C_CheckMap       ;checkmap uses index (target + (isWhite ? -8 : 8))
                            ;to see if the pawn that can be EP captured is
                            ;checking the king.

    ld a, (C_CurrentColor)  ;current color = 0 | 8
    add a                   ;(-CurrentColor*2 + 8) = 8 (B) | -8 (W)
    neg
    add 8
    add b

    ld e, a
    add hl, de
    ld a, (hl)
    or a
    ret z                   ;early return since target isn't on checkMap.
.skipCheckTestEp:

    push ix                 ;preserve IX/IY
    push iy
    call MoveGen_ValidateEnPassantCapture
    pop iy                  ;restore IX/IY
    pop ix
    ret nz                  ;early return if en passant isn't a legal move

    ld d, c
    ld e, b
    ld a, MOVE_FLAG_EN_PASSANT
    call MoveGen_AddMoveFlag
    ld d, 0                 ;reset D so DE=$0000XX

    ret

;****************************************************************
; MoveGen_GeneratePawnCaptureMoves - (internal) called from
;   MoveGen_GeneratePawnMoves, generate diagonal capture moves
;   and handles E.P. capturing and promotions for the provided
;   pawn.
;
; INPUT:
;   C - pawn square
;   IYH - pawn file
;   IXL - is promotion rank
;   DE - $0000XX
;
; DESTROYS: All except C', C, IX, IYH, DE=$0000XX
;****************************************************************
MoveGen_GeneratePawnCaptureMoves:
    ld iyl, OFFSET_NW       ;get west diagonal attack offset
    ld a, (C_CurrentColor)
    or a
    jr nz, .whiteToMove
    ld iyl, OFFSET_SW
.whiteToMove:

    ;WEST DIAGONAL ATTACK
    ld a, iyh
    or a
    jr z, .pawnFileIs0

    call MoveGen_GeneratePawnCaptureInDirection

    ;EAST DIAGONAL ATTACK

    ld a, iyh
    cp 7
    ret z                   ;early return since it would jump to a ret anyway
;    jr z, .pawnFileIs7
.pawnFileIs0:               ;skip the above check if we know the file is 0

    ld a, iyl               ;calculate the east offset by just adding 2 to
    add 2                   ;the west offset.
    ld iyl, a

    call MoveGen_GeneratePawnCaptureInDirection
;.pawnFileIs7:

    ret

;****************************************************************
; MoveGen_GeneratePawnNonCaptureMoves - (internal) called from
;   MoveGen_GeneratePawnMoves, only generates non-capture moves
;   (foward and double advance) for a single provided pawn.
;
; INPUT:
;   C - pawn square
;   IXH - is double advance rank
;   IXL - is promotion rank
;   DE - $0000XX
;
; DESTROYS: All except C, A', C', IX, IY
;****************************************************************
MoveGen_GeneratePawnNonCaptureMoves:
    ld a, (_MG_PawnOffsetForward)    ;calculate target square
    add c
    ld b, a                 ;target square stored in B

    ld hl, C_Board          ;early return if target square isn't empty
    ld e, b
    add hl, de
    ld a, (hl)
    or a
    ret nz

    ld hl, C_PinMap         ;early return if there's a pin and move isn't
    ld e, c                 ;on the pin-ray. Note that this doesn't have to
    add hl, de              ;be tested again for a double-advance since they              
    ld a, (hl)              ;are along the same ray, unlike the inCheck test.
    or a
    jr z, .skipPinCheck

    ld a, (_MG_PawnOffsetForward)
    push bc                 ;preserve B
    ld b, a
    call MoveGen_MovingOnRay
    pop bc
    ret nz
.skipPinCheck:
    ;single advance move case

    ld a, (C_InCheck)
    or a
    jr z, .skipSingleAdvanceInCheckTest

    ld hl, C_CheckMap
    ld e, b
    add hl, de
    ld a, (hl)
    or a
    jr z, .skipSingleAdvanceCase
.skipSingleAdvanceInCheckTest:

    ;prepare D/E for MoveGen_AddMove function
    ld d, c                 ;starting square
    ld e, b                 ;target square

    ld a, ixl               ;regular move or promotion moves check
    or a
    jr nz, .pawnPromotionMoves
;( .pawnRegularAdvance: )
    call MoveGen_AddMove
    jr .skipSingleAdvanceCase
.pawnPromotionMoves:

    ld a, 1                 ;1..4 are promotion move flags
.promotionMoveLoop:
    call MoveGen_AddMoveFlag

    inc a
    cp 5
    jr nz, .promotionMoveLoop
.skipSingleAdvanceCase:
    ld d, 0                 ;reset D=$0000XX after use in MoveGen_AddMove

    ;double advance move case
    ;note that a lot of early returns are used here since this is
    ;the end of the subroutine.

    ld a, ixh
    or a
    ret z                   ;early return if not in double advance rank

    ld a, (_MG_PawnOffsetForward)    ;calculate new target square
    add b
    ld b, a

    ld hl, C_Board          ;early return if target square isn't empty 
    ld e, b
    add hl, de
    ld a, (hl)
    or a
    ret nz

    ld a, (C_InCheck)       ;check test with early return on fail
    or a
    jp z, .skipDoubleAdvanceCheckTest

    ld hl, C_CheckMap
    add hl, de
    ld a, (hl)
    or a
    ret z
.skipDoubleAdvanceCheckTest:
    ld a, MOVE_FLAG_DOUBLE_PAWN
    ld d, c
    ld e, b
    call MoveGen_AddMoveFlag
    ld d, 0

    ret

;****************************************************************
; MoveGen_GeneratePawnMoves - (internal) moves for pawns.
;
; DESTROYS: All
;****************************************************************
MoveGen_GeneratePawnMoves:
    ld hl, (C_CurrentPlPtr)
    ld de, PIECE_PAWN * 3   ;note that we can assume DE=$0000XX afterwards
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)
    or a
    ret z                   ;early return if there are 0 pawns

    exx ;alt reg start
    ld c, a                 ;init number of pawns counter
    exx ;alt reg end

    ld a, (C_EpFile)        ;save current ep file to b
    ld b, a

    ;init constants
    ld a, (C_CurrentColor)
    or a
    jr z, .blackToMove
;( .whiteToMove: )
    ld a, 1
    ld (_MG_PawnDoubleAdvanceRank), a
    ld a, 6
    ld (_MG_PawnPromotionRank), a
    ld a, OFFSET_N
    ld (_MG_PawnOffsetForward), a
    ld a, 5*8               ;EpSquare Rank*8

    jr .skipBlackToMove
.blackToMove:
    ld a, 6
    ld (_MG_PawnDoubleAdvanceRank), a
    ld a, 1
    ld (_MG_PawnPromotionRank), a
    ld a, OFFSET_S
    ld (_MG_PawnOffsetForward), a
    ld a, 2*8
.skipBlackToMove:
    add b                   ;finish setting up EpSquare with saved
    ld (_MG_PawnEpSquare), a ;C_EpFile value. Note the rank*8 information
                            ;gets loaded in by both cases at the end.

.pawnLoop:
    ld c, (ix)              ;load next pawn square
    inc ix
    push ix                 ;preserve piece-list

    ;* * * * * * * * Non-Capture Pawn Moves * * * * * * * *
    ;registers:
    ;   B - temp
    ;   C - pawn square
    ;   HL - temp
    ;   DE - temp
    ;   IXH - isDoubleAdvanceRank
    ;   IXL - isPromotionRank
    ;   IYH - temp
    ;   IYL - temp
    ;shadow register:
    ;   B - reserved: pawn loop counter (decrements)
    ;

    ld b, c                 ;load rank
    srl b
    srl b
    srl b

    ld ix, 0                ;reset IXH and IXL

    ld a, (_MG_PawnDoubleAdvanceRank)
    cp b                    ;note that rank is still loaded into B
    jr nz, .notDoubleAdvanceRank
    inc ixh                 ;now IXH=1
    jr .notPromotionRank    ;if this pawn can double advance, we know it can't promote.
.notDoubleAdvanceRank:

    ld a, (_MG_PawnPromotionRank)
    cp b
    jr nz, .notPromotionRank
    inc ixl
.notPromotionRank:

    call MoveGen_GeneratePawnNonCaptureMoves

    ;registers:
    ;IYH - pawn file

    ld a, c                 ;calculate pawn file
    and 0111b
    ld iyh, a

    call MoveGen_GeneratePawnCaptureMoves

.pawnLoopContinue:
    pop ix                  ;restore piece-list
    exx ;alt reg start
    dec c
    exx ;alt reg end
    jr nz, .pawnLoop

    ret

;****************************************************************
; MoveGen_Init - (internal) Reset move generator variables.
;
; DESTROYS: All
;****************************************************************
MoveGen_Init:
    xor a
    ld (C_InCheck), a
    ld (_MG_InDoubleCheck), a
    ld (MG_MoveCount), a
    ld (_MG_EpPossible), a
    ld (_MG_CanCastleKingside), a
    ld (_MG_CanCastleQueenside), a

    call Engine_SetIndexVariables
    call Engine_SetPieceListVariables

    ;set if En Passant capture is possible
    ld a, (C_EpFile)
    cp EN_PASSANT_NONE
    jr z, .enPassantNotPossible

    ld a, 1
    ld (_MG_EpPossible), a
.enPassantNotPossible:

    ;clear maps
    ld hl, C_AttackMap
    ld (hl), 0
    ld de, C_AttackMap + 1
    ld bc, 64 * 3 - 1
    ldir

    ;set currentKing and enemyKing variables
    ;current king
    ld a, MG_KING_NONE
    ld (C_CurrentKing), a

    ld hl, (C_CurrentPlPtr)         ;get number of kings by loading king piecelist in IX
    ld de, PIECE_KING * 3
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)       ;index number of pieces
    or a
    jr z, .noCurrentKing

    ld a, (ix)                      ;get first pieces position
    ld (C_CurrentKing), a
.noCurrentKing:

    ;enemy king
    ld a, MG_KING_NONE
    ld (C_EnemyKing), a

    ld hl, (C_EnemyPlPtr)
    ld de, PIECE_KING * 3
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)
    or a
    jr z, .noEnemyKing

    ld a, (ix)
    ld (C_EnemyKing), a
.noEnemyKing:

    ;load piecelists and number of pieces for enemy queens/rooks/bishops.
    ;used in attack/check/pin map generation multiple times.

    ld hl, (C_EnemyPlPtr)
    ld de, PIECE_QUEEN * 3
    add hl, de
    ld ix, (hl)
    ld (_MG_EnemyQueenPl), ix
    ld a, (ix + PL_DATA_SIZE)
    ld (_MG_EnemyQueenCount), a

    ld de, PIECE_ROOK * 3 - PIECE_QUEEN * 3
    add hl, de
    ld ix, (hl)
    ld (_MG_EnemyRookPl), ix
    ld a, (ix + PL_DATA_SIZE)
    ld (_MG_EnemyRookCount), a

    ld de, PIECE_BISHOP * 3 - PIECE_ROOK * 3
    add hl, de
    ld ix, (hl)
    ld (_MG_EnemyBishopPl), ix
    ld a, (ix + PL_DATA_SIZE)
    ld (_MG_EnemyBishopCount), a

;check if castle flags are set
    ld a, (C_CurrentColor)
    or a                            ;note that the jump uses this flag result
    ld a, (C_CastleFlags)
    jr nz, .whiteToMove
;( .blackToMove: )
    srl a                           ;prepare flags for current side by moving them
    srl a                           ;into the bits of white castle flags.
.whiteToMove:

    bit 0, a                        ;location of CASTLE_FLAG_WHITE_KING bit
    jr z, .cantCastleKingside
;( .canCastleKingside: )
    ld (_MG_CanCastleKingside), a    ;A != 0 if this runs, and since I check for
.cantCastleKingside:                ;0 (false) instead of 1 for booleans whatever
                                    ;the flags variable (A) holds is good enough

    bit 1, a                        ;location of CASTLE_FLAG_WHITE_QUEEN bit
    jr z, .cantCastleQueenside
;( .canCastleQueenside: )
    ld (_MG_CanCastleQueenside), a
.cantCastleQueenside:

    ret

;****************************************************************
; MoveGen_Generate - Generates moves for current board state and
;   position.
;
; INPUT: IX - Movelist pointer
; OUTPUT: NONE
;
; DESTROYS: All
;****************************************************************
MoveGen_Generate:
    ld (_MG_Moves), ix
    ld (_MG_MovesNext), ix

    call MoveGen_Init

    call MoveGen_GenerateAttackMaps

    ld a, (C_CurrentKing)
    cp MG_KING_NONE
    call nz, MoveGen_GenerateKingMoves
    
    ; if the king is in double check (attacked by two pieces), the only way to
    ; break it would be to move the king, therfore we can exit early and skip
    ; move generation logic for the other pieces since there are no moves anyway.
    ld a, (_MG_InDoubleCheck)
    dec a
    ret z

    call MoveGen_GenerateAllSlidingMoves

    call MoveGen_GenerateKnightMoves

    call MoveGen_GeneratePawnMoves

    ret
