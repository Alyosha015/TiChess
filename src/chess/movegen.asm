MG_KING_NONE := 255

C_CurrentKing: db 0     ;stores positions of kings
C_EnemyKing: db 0

C_InCheck: db 0
C_InDoubleCheck: db 0

C_CurrentPlPtr: dl 0    ;holds addresses to look up tables of current and enemy pieceslists
C_EnemyPlPtr: dl 0

C_EnemyQueenPl: dl 0
C_EnemyQueenCount: db 0
C_EnemyRookPl: dl 0
C_EnemyRookCount: db 0
C_EnemyBishopPl: dl 0
C_EnemyBishopCount: db 0

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
    ld (C_InDoubleCheck), a

    ld a, 1
    ld (C_InCheck), a

    ret

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; SECTION: ENEMY'S PERSEPECTIVE ATTACK/CHECK/PIN MAP GENERATION
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;****************************************************************
; MoveGen_GeneratePinMaps - (internal)
;****************************************************************
;
; Used to look at attacking pieces from the "persepective" of the
; king, to determine if there are any checks and pins from sliding
; pieces.
;
;****************************************************************
MoveGen_GeneratePinMaps:
    ld de, 0

    exx ;alt reg start
    ld bc, 0 * 256 + 8          ;initial value checks all directions

    ld ixl, 1                   ;initial isOrthogonal value, assumes rooks/queens exist

    ld a, (C_EnemyQueenCount)   ;if there are any queens, skip the below checks.
    or a
    jr nz, .hasQueens

    ld a, (C_EnemyRookCount)    ;if there are no rooks, don't check first 4 directions
    or a
    jr nz, .hasRooks
    ld b, 4
    dec ixl                     ;if there are no rooks, the first direction checked will be diagonal.
.hasRooks:

    ld a, (C_EnemyBishopCount)  ;if there are no bishops, don't check last 4 directions
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
    ;   DE
    ;   HL

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

    ld d, 8 ;square-to-edge = LUT_SquareToEdge[square * 8 + dirIndex]
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

    ld a, (C_CurrentKing)   ;load king position, used in both checkMap and pinMap case

    dec ixh                 ;sets 0 flag if isFriendlyPiece is 1
    jr z, .isPin
;( .isCheck ): ;foundFriendlyPiece = 0
    ;marks every square from king to current square on the current line on checkMap.

.checkMapLoop:
    add iyl

    ld hl, C_CheckMap
    ld e, a
    add hl, de
    ld (hl), 1

    cp iyh
    jr nz, .checkMapLoop

    call MoveGen_CountCheck

    jr .squareLoopBreak
.isPin: ;foundFriendlyPiece = 1
    ;marks every square from king to current square on the current line on pinMap.
.pinMapLoop:
    add iyl

    ld hl, C_PinMap
    ld e, a
    add hl, de
    ld (hl), 1

    cp iyh  ;loop until current target square is reached
    jr nz, .pinMapLoop

    jr .squareLoopBreak
.squareLoopContinue:
    dec b
    jp nz, .squareLoop
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
; INPUTS:
;   IX - selected piece list pointer.
;   A - number of pieces in piece list.
;   B - start direction (0-7)
;   C - end direction (1-8) (offset by 1, C=8 -> end at 7)
;
;   DE <= $00FFFF
;
; PRESERVES: NONE, DE will have upper 8 bits zeroed.
;
;****************************************************************
;
; Used to create fill attack map for sliding pieces, with controls
; for what directions to check to make it work for bishop/rook/queen
; movement.
;
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

    ld a, b ;skip loop if B = 0 (otherwise DJNZ decrements B and overflows to B = 255)
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
; MoveGen_GenerateEnemySlidingAttackMaps - (internal) calls
;   MoveGen_GenerateEnemySlidingAttackMap for the 3 types of
;   sliding pieces.
;
;****************************************************************
MoveGen_GenerateEnemySlidingAttackMaps:
    ld de, 0    ;needed for MoveGen_GenerateEnemySlidingAttackMap

    ;QUEEN
    ld ix, (C_EnemyQueenPl)
    ld a, (C_EnemyQueenCount)
    or a
    ld bc, 0 * 256 + 8
    call nz, MoveGen_GenerateEnemySlidingAttackMap

    ;ROOK
    ld ix, (C_EnemyRookPl)
    ld a, (C_EnemyRookCount)
    or a
    ld bc, 0 * 256 + 4
    call nz, MoveGen_GenerateEnemySlidingAttackMap

    ;BISHOP
    ld ix, (C_EnemyBishopPl)
    ld a, (C_EnemyBishopCount)
    or a
    ld bc, 4 * 256 + 8
    call nz, MoveGen_GenerateEnemySlidingAttackMap

    ret

;****************************************************************
; MoveGen_GenerateEnemyKnightAttackMap - (internal) enemy knight
;   attack map / check map generation. Destroys all/alt registers
;****************************************************************
MoveGen_GenerateEnemyKnightAttackMap:
    ld hl, (C_EnemyPlPtr)       ;load knight piecelist
    ld de, PIECE_KNIGHT * 3
    add hl, de
    ld ix, (hl)

    ld a, (ix + PL_DATA_SIZE)   ;number of knights
    or a
    ret z                       ;early return if there are no knights
    ld c, a                     ;number of knights loop counter

    ex af, af'                  ;load current king position into shadow A register
    ld a, (C_CurrentKing)
    ex af, af'

.knightLoop:
    ld a, (ix)                  ;get knight square
    inc ix

    push ix                     ;preserve knight piecelist

    ld ix, LUT_KnightMoveCount  ;get number of valid knight moves for this square
    ld de, 0
    ld e, a
    add ix, de
    ld b, (ix)

    ld ix, LUT_KnightMovement   ;destination square = LUT_KnightMovement[square * 8 + index]
    ld d, 8
    ; ld e, a                   ;note that E = A from above code already
    mlt de
    add ix, de

    ld de, 0
.squareLoop:
    ld e, (ix)
    inc ix

    ld hl, C_AttackMap
    add hl, de
    ld (hl), 1
    
    ex af, af'                  ;swap to king position A register
    cp e                        ;if king position and knight attack position match,
    jr nz, .notInCheck          ;the king is now in check.

    ld hl, C_CheckMap           ;update checkmap / checkcount
    add hl, de                  ;note that DE has the knight attack square stored
    ld (hl), 1
    call MoveGen_CountCheck
.notInCheck:
    ex af, af'                  ;swap to knight position A register

    djnz .squareLoop

    pop ix                      ;restore knight piecelist

    dec c
    jr nz, .knightLoop

    ret

;****************************************************************
; MoveGen_GenerateEnemyPawnAttackMap - (internal) enemy pawn
;   attack map / check map generation. Destroys all/alt registers.
;
;   Note that this calculates the pawn attacks, so diagonal moves.
;****************************************************************
MoveGen_GenerateEnemyPawnAttackMap:
    ld hl, (C_EnemyPlPtr)       ;load pawn piecelist
    ld de, PIECE_PAWN * 3
    add hl, de
    ld ix, (hl)

    ld a, (ix + PL_DATA_SIZE)   ;get number of pawns and early return
    or a
    ret z

    exx ;alt reg start
    ld c, a                     ;pawn loop counter
    exx ;alt reg end

    ex af, af'                  ;load current king position into shadow A register
    ld a, (C_CurrentKing)
    ex af, af'

.pawnLoop:
    ld a, (ix)                  ;get pawn position
    inc ix

    ld c, a                     ;copy pawn position
    and 0111b                   ;calculate pawn file (column)
    or a
    jr z, .fileIs0
    ;can go west (or left from white's perspective)

.fileIs0:

    cp 7                        ;note A still stores the pawn's file
    jr z, .fileIs7
    ;can go east (or right from white's perspective)

.fileIs7:

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

    ld de, 0
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
; The main purpose of this is for later allowing legal king
; movement.
;****************************************************************
MoveGen_GenerateAttackMaps:
    ld a, (C_CurrentKing)
    cp MG_KING_NONE
    call nz, MoveGen_GeneratePinMaps

    call MoveGen_GenerateEnemySlidingAttackMaps

    call MoveGen_GenerateEnemyKnightAttackMap
    call MoveGen_GenerateEnemyPawnAttackMap

    ld a, (C_EnemyKing)
    cp MG_KING_NONE
    call nz, MoveGen_GenerateEnemyKingAttackMap

    ret

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; SECTION: MOVE GENERATOR FROM CURRENT SIDE'S PERSPECTIVE - does
;   the "actual" move generation.
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;****************************************************************
; MoveGen_GenerateKingMoves - (internal) moves for current king.
;
; DESTROYS: All
;****************************************************************
MoveGen_GenerateKingMoves:

    ret

;****************************************************************
; MoveGen_GenerateSlidingMoves - (internal) moves for
;   queen / rook / bishop.
;
; INPUTS:
;   IX - selected piece list pointer.
;   B - start direction (0-7)
;   C - end direction (1-8) (offset by 1)
;
; DESTROYS: ALL
;
;****************************************************************
;
; Used to create moves for sliding pieces, with controls for what
; directions to check to make it work for bishop/rook/queen movement.
;
;****************************************************************
MoveGen_GenerateSlidingMoves:

    ret

;****************************************************************
; MoveGen_GenerateKnightMoves - (internal) moves for knight.
;
; DESTROYS: ALL
;****************************************************************
MoveGen_GenerateKnightMoves:

    ret

;****************************************************************
; MoveGen_GeneratePawnMoves - (internal) moves for pawns.
;
; DESTROYS: ALL
;****************************************************************
MoveGen_GeneratePawnMoves:

    ret

;****************************************************************
; MoveGen_SetPieceListVariables - (internal) sets C_CurrentPlPtr
;   and C_EnemyPlPtr based on C_WhiteToMove value. Used by
;   MoveGen_Init.
;
; DESTROYS: DE, AF
;****************************************************************
MoveGen_SetPieceListVariables:
    ld a, (C_WhiteToMove)
    or a
    jr z, .blackToMove
.whiteToMove:
    ld de, PL_White
    ld (C_CurrentPlPtr), de

    ld de, PL_Black
    ld (C_EnemyPlPtr), de

    ret
.blackToMove:
    ld de, PL_Black
    ld (C_CurrentPlPtr), de

    ld de, PL_White
    ld (C_EnemyPlPtr), de

    ret

;****************************************************************
; MoveGen_Init - (internal) Reset move generator variables.
;
; DESTROYS: All
;****************************************************************
MoveGen_Init:
    xor a
    ld (C_InCheck), a
    ld (C_InDoubleCheck), a

    call Engine_SetIndexVariables

    ;clear maps
    ld hl, C_AttackMap
    ld (hl), 0
    ld de, C_AttackMap + 1
    ld bc, 64 * 3 - 1
    ldir

    call MoveGen_SetPieceListVariables

    ;set currentKing and enemyKing variables
    ;current king
    ld a, MG_KING_NONE
    ld (C_CurrentKing), a

    ld hl, (C_CurrentPlPtr)     ;get number of kings by loading king piecelist in IX
    ld de, PIECE_KING * 3
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)   ;index number of pieces
    or a
    jr z, .noCurrentKing

    ld a, (ix)                  ;get first pieces position
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
    ld (C_EnemyQueenPl), ix
    ld a, (ix + PL_DATA_SIZE)
    ld (C_EnemyQueenCount), a

    ld de, PIECE_ROOK * 3 - PIECE_QUEEN * 3
    add hl, de
    ld ix, (hl)
    ld (C_EnemyRookPl), ix
    ld a, (ix + PL_DATA_SIZE)
    ld (C_EnemyRookCount), a

    ld de, PIECE_BISHOP * 3 - PIECE_ROOK * 3
    add hl, de
    ld ix, (hl)
    ld (C_EnemyBishopPl), ix
    ld a, (ix + PL_DATA_SIZE)
    ld (C_EnemyBishopCount), a

    ret

;****************************************************************
; MoveGen_Generate - Generates moves for current board state and
;   position. Uses 
;
; INPUT: IX - Movelist pointer
; OUTPUT: NONE
;
; DESTROYS: All
;****************************************************************
MoveGen_Generate:
    call MoveGen_Init

    call MoveGen_GenerateAttackMaps

    ld a, (C_CurrentKing)
    cp MG_KING_NONE
    call nz, MoveGen_GenerateKingMoves
    
    ; if the king is in double check (attacked by two pieces), the only way to
    ; break it would be to move the king, therfore we can exit early and skip
    ; generating moves logic for the other pieces since there are no moves anyway.
    ld a, (C_InDoubleCheck)
    dec a
    ret z

    

    ret
