;variables
movesPtr: rb 3

    KING_NONE := 255

currentKing: db KING_NONE
enemyKing: db KING_NONE

;attack map - squares currently attacked by the enemy, and
;   if a king is attacked by a slider the squares which are
;   are dangerous to the king, even if the sliding piece
;   technically doesn't attack them because the king blocks
;   them from moving there. Also includes squares even if it
;   has an enemy piece to stop the king attacking them for a
;   similar reason.
;check map - squares of pieces checking king and their path
;   towards the king for sliding pieces.
;pin map - squares along which pinned pieces can move.
;note: code expects these to be one after the other.
attackMap: rb 64
checkMap: rb 64
pinMap: rb 64

inCheck: db 0
inDoubleCheck: db 0

epPossible: db 0

canKingSideCastle: db 0
canQueenSideCastle: db 0

currentPlPtr: rb 3
enemyPlPtr: rb 3

;doesn't preserve a
movegen_IncCheckCount:
    push hl

    ld hl, inDoubleCheck
    ld a, (inCheck)
    ld (hl), a
    ld hl, inCheck
    ld (hl), 1

    pop hl

    ret

movegen_GenerateEnemyPinsAndChecks:
    ;registers:
    ; B - index
    ; C - piece
    ; DE - temp
    ; HL - temp
    ; IX - none
    ; IYH - offset
    ; IYL - squares
    ;shadow registers:
    ; B - dir
    ; C - dirEnd
    ; DE - temp outside of square loop
    ; D - square loop counter
    ; E - foundFriendlyPiece
    ; HL - temp

;optimization thing, don't search all directions if the enemy
;doesn't have sliding pieces to go in those directions

    exx ;alt reg start
    ld b, 0
    ld c, 8

    ld hl, (enemyPlPtr)
    ld de, PIECE_QUEEN * 3
    add hl, de
    ld iy, (hl)
    ld a, (iy+PL_DATA_SIZE)
    cp 0
    jp nz, .skipDirCheck ;a queen can move in all 8 so don't bother checking rooks/bishops

    ld de, 3
    add hl, de ;rooks
    ld iy, (hl)
    ld a, (iy+PL_DATA_SIZE)
    cp 0
    jp nz, .hasRooks
    ld b, 4
.hasRooks:
    add hl, de ;bishops
    ld iy, (hl)
    ld a, (iy+PL_DATA_SIZE)
    cp 0
    jp nz, .hasBishops
    ld c, 4
.hasBishops:
.skipDirCheck:
    ld a, b ;return if you don't have bishops/rooks (startDir 4 and endDir 4)
    cp c
    exx ;alt reg end
    ret z

.dirLoop:
    exx ;alt reg start

    ;load offset (LUT_DirOffset[dirIndex])
    ld de, 0
    ld hl, LUT_DirOffset
    ld e, b
    add hl, de
    ld a, (hl)
    ld iyh, a

    ;calculate number of square to search (LUT_SquaresToEdge[KingIndex * 8 + dirIndex])
    ld hl, $0800
    ld a, (currentKing) ;king * 8 in HL
    ld l, a
    mlt hl
    ld de, 0 ;add dirIndex
    ld e, b
    add hl, de
    ld de, LUT_SquaresToEdge ;add start address of LUT
    add hl, de
    ld a, (hl)
    ld iyl, a

    ld de, 0 ;init square counter and foundFriendlyPiece variable
    exx ;alt reg end

    ;load start index (where the king is)
    ld hl, currentKing
    ld b, (hl)

.squareLoop:
    ld a, b ;index += offset
    add iyh
    ld b, a

    ld hl, pieces ;get piece at current index
    ld de, 0
    ld e, b
    add hl, de
    ld c, (hl)

    ld a, c ;continue if there's nothing at this square
    cp PIECE_NONE
    jp z, .squareLoopContinue

    ld a, c ;check if enemy/friendly piece:
    and MASK_PIECE_COLOR
    ld hl, currentColor
    cp (hl)
    jp nz, .isEnemyColor
.isCurrentColor:
    exx ;alt reg start
    ld a, e
    cp 1
    jp z, .squareLoopBreakExx
    ld e, 1
    exx ;alt reg end
    jp .squareLoopContinue
.isEnemyColor:
    ;check if enemy piece is a slider which can attack in this direction, otherwise break out of square-loop.
    ld a, c
    and MASK_PIECE_TYPE
    cp PIECE_QUEEN
    jp z, .canBeAttackedToExx

;if it's not a queen check rook/bishop
    exx ;alt reg start

    bit 3, b
    jp nz, .checkBishop
.checkRook:
    cp PIECE_ROOK
    jp nz, .squareLoopBreakExx
    jp .canBeAttacked
.checkBishop:
    cp PIECE_BISHOP
    jp nz, .squareLoopBreakExx
    jp .canBeAttacked
.canBeAttackedToExx:
    exx ;alt reg start (doesn't always run)
.canBeAttacked:
    ld a, e
    exx ;alt reg end

    ld hl, currentKing ;load de with king index
    ld de, 0
    ld e, (hl)

    cp 1    ;check if friendly piece was found on this line before (meaning it's pinned),
            ;or not (meaning the attacking piece ic checking the king).
    jp z, .isFriendly

; add to checkmap:
    ld a, iyh ;used by offset setup

    ;setup start address / index
    ld ix, checkMap ;iy = checkMap + kingIndex
    add ix, de

    ;setup offset
    bit 7, a
    jp nz, .check_IsNegativeOffset
    ld de, 0
    jp .check_SkipNegativeOffset
.check_IsNegativeOffset:
    ld de, $FFFFFF
.check_SkipNegativeOffset:
    ld e, a

    ;load loop counter / limit
    ld h, 0 ;h = loop counter

    exx ;alt reg start
    ld a, d ;get loop limit (squares counter)
    exx ;alt reg end
    ld l, a ;l = loop limit

.checkMapLoop:
    add ix, de
    ld (ix), 1

    ld a, h
    inc h
    cp l
    jp nz, .checkMapLoop

    call movegen_IncCheckCount
    jp .squareLoopBreak

;add to pinmap:
.isFriendly:
    ld a, iyh ;used by offset setup

    ;setup start address / index
    ld ix, pinMap ;iy = pinMap + kingIndex
    add ix, de

    ;setup offset
    bit 7, a
    jp nz, .pin_IsNegativeOffset
    ld de, 0
    jp .pin_SkipNegativeOffset
.pin_IsNegativeOffset:
    ld de, $FFFFFF
.pin_SkipNegativeOffset:
    ld e, a

    ;load loop counter / limit
    ld h, 0 ;h = loop counter

    exx ;alt reg start
    ld a, d ;get loop limit (squares counter)
    exx ;alt reg end
    ld l, a ;l = loop limit

.pinMapLoop:
    add ix, de
    ld (ix), 1

    ld a, h
    inc h
    cp l
    jp nz, .pinMapLoop

.squareLoopContinue:
    exx ;alt reg start
    inc d ;counter
    ld a, d
    cp iyl
    exx ;alt reg end
    jp nz, .squareLoop
.squareLoopBreak:

;handle direction loop
    exx ;alt reg start
.squareLoopBreakExx:
    inc b
    ld a, b
    cp c
    exx ;alt reg end
    jp nz, .dirLoop

    ret

;expects position index in A, start direction in C and end direction in B.
;preserves IX and HL
movegen_GenerateEnemySlidingAttack:
    push hl
    push ix

    ld ixl, a

;registers:
;   B - target index
;   C - square counter
;   DE - temp
;   HL - temp
;   IXH - 
;   IXL - start index
;   IYH - offset
;   IYL - squares to edge
;alt registers
;   B - end direction
;   C - direction index
;

    push bc ;transfer BC to BC', and place an extra on stack for dirLoop
    push bc
    exx ;alt reg start
    pop bc
    exx ;alt reg end

.dirLoop:
    ld hl, $0800 ;load start index in HL
    ld a, ixl
    ld l, a

    mlt hl ;(LUT_SquaresToEdge[index * 8 + dirIndex])
    ;add dirIndex
    pop de ;get BC' from either above or from loop iteration part
    ld d, 0
    add hl, de
    push de ;preserve dirIndex
    ld de, LUT_SquaresToEdge ;add start address of LUT
    add hl, de
    pop de ;restore dirIndex
    ld a, (hl)
    cp 0 ;if 0 squares to edge don't loop
    jp z, .squareLoopBreak
    ld iyl, a

    ld hl, LUT_DirOffset ;get offset for dirIndex
    add hl, de           ;DE is still loaded with the dirIndex
    ld a, (hl)
    ld iyh, a

    ld b, ixl ;init target index
    ld c, 0 ;init square-loop counter
.squareLoop:
    ld a, b ;update target index
    add iyh
    ld b, a

    ld hl, attackMap
    ld de, 0
    ld e, b
    add hl, de
    ld (hl), 1

    ld a, (currentKing) ;if the king is in the way, continue marking attacked squares through him.
    cp b
    jp z, .squareLoopContinue

    ld hl, pieces ;if there's another piece in the way, break out of the loop.
    add hl, de
    ld a, (hl)
    cp PIECE_NONE
    jp nz, .squareLoopBreak

.squareLoopContinue:
    inc c
    ld a, c
    cp iyl
    jp nz, .squareLoop

.squareLoopBreak:
    exx ;alt reg start
    inc c
    push bc ;needed for start of loop
    ld a, c
    cp b
    exx ;alt reg end
    jp nz, .dirLoop

    pop bc ;get rid of extra value added to stack above
 
    pop ix ;restore ix
    pop hl ;restore hl
    ret

;expects nothing, preserves nothing
movegen_GenerateEnemyKnightAttackMap:
    ld hl, (enemyPlPtr)
    ld de, PIECE_KNIGHT * 3
    add hl, de
    ld ix, (hl)

    exx ;alt reg start
    ld b, (ix+PL_DATA_SIZE)
    ld c, 0 ;init knight loop counter too
    ld a, b
    exx ;alt reg end
    cp 0    ;early return if there are 0 enemy knights
    ret z

;registers:
;   B - number of squares
;   C - square counter
;   DE - temp
;   HL - attackMap
;   IX - piecelist ptr
;   IY - movement data ptr
;shadow registers:
;   B - number of knights
;   C - knight loop counter
;   D

.knightLoop:
    ld de, 0
    ld e, (ix) ;load knight position

    ld hl, LUT_KnightMoveCount ;load number of squares attacked
    add hl, de
    ld b, (hl)

    ;load pointer to knight attacked squares
    ;LUT_KnightMovement[square * 8]
    ld hl, $0800
    ld l, e
    mlt hl
    ld de, LUT_KnightMovement
    add hl, de
    push hl
    pop iy

    ld c, 0 ;init loop counter
    ld de, 0 ;used as offset into attackmap in loop below
.attackSquareLoop:
    ;de = attacked square
    ld e, (iy)

    ld hl, attackMap
    add hl, de
    ld (hl), 1

    ld a, (currentKing)
    cp e
    jp nz, .skipKingInCheck

    ld de, 64 ;checkMap is the 64 bytes after the attackMap in ram
    add hl, de
    ld (hl), 1
    call movegen_IncCheckCount
.skipKingInCheck:

    ;attack square loop control
    inc iy
    inc c
    ld a, c
    cp b
    jp nz, .attackSquareLoop

    ;knight loop control
    inc ix
    exx ;alt reg start
    inc c
    ld a, c
    cp b
    exx ;alt reg end
    jp nz, .knightLoop

    ret

movegen_GenerateEnemyPawnAttackMap:
    ld hl, (enemyPlPtr)
    ld de, PIECE_PAWN * 3
    add hl, de
    ld ix, (hl)
    exx ;alt reg start
    ld b, (ix+PL_DATA_SIZE) ;get length
    ld c, 0 ;init knight loop counter too
    ld a, b
    exx ;alt reg end
    cp 0    ;early return if there are 0 enemy pawns
    ret z

;registers:
;   B - pawn position
;   C - pawn file
;   DE - temp
;   HL - temp
;   IX - pawn piecelist ptr
;   IY - 
;shadow registers:
;   B - number of pawns
;   C - pawn loop counter
;
;not worrying about reseting DE to 0 since I never set to a value greater than 255 anyway
;
.pawnLoop:
    ld b, (ix) ;load position
    ld a, b
    and 111b ;load pawn file
    ld c, a ;store file for latter

;attacking right
    cp 6
    jp nc, .fileGreaterThan7

    ld a, (whiteToMove) ;calculate attack square
    cp 0
    jp z, .blackMove0
.whiteMove0:
    ld a, OFFSET_SE
    jp .skipBlackMove0
.blackMove0:
    ld a, OFFSET_NE
.skipBlackMove0:
    add b

    ld e, a
    ld hl, attackMap
    add hl, de
    ld (hl), 1

    ld a, (currentKing) ;is the king in check?
    cp e
    jp nz, .skipKingAttacked0

    ld de, 64 ;checkMap is 64 bytes ahead of attackMap
    add hl, de
    ld (hl), 1
    call movegen_IncCheckCount
.skipKingAttacked0:
.fileGreaterThan7:

;attacking left
    ld a, c
    cp 1
    jp c, .fileLessThan1

    ld a, (whiteToMove)
    cp 0
    jp z, .blackMove1
.whiteMove1:
    ld a, OFFSET_SW ;wrong vertical direction since they are the enemy pawns moving
    jp .skipBlackMove1
.blackMove1:
    ld a, OFFSET_NW
.skipBlackMove1:
    add b
    ld e, a
    ld hl, attackMap
    add hl, de
    ld (hl), 1

    ld a, (currentKing) ;is the king in check?
    cp e
    jp nz, .skipKingAttacked1

    ld de, 64 ;checkMap is 64 bytes ahead of attackMap
    add hl, de
    ld (hl), 1
    call movegen_IncCheckCount
.skipKingAttacked1:
.fileLessThan1:

    inc ix
    exx ;alt reg start
    inc c
    ld a, c
    cp b
    exx ;alt reg end
    jp nz, .pawnLoop

    ret

movegen_GenerateEnemySlidingAttacks:
    ld hl, (enemyPlPtr)
    ld de, PIECE_QUEEN * 3
    add hl, de
    ld ix, (hl)
    ld l, (ix+PL_DATA_SIZE) ;store length in L, (H is used as the loop counter)
    ld a, l
    cp 0
    jp z, .skipQueens

    ld h, 0
.queenAttackLoop:
    ld b, 8 ;end at dir 8
    ld c, 0 ;start at dir 0
    ld a, (ix)

    call movegen_GenerateEnemySlidingAttack

    inc ix
    inc h
    ld a, h
    cp l
    jp nz, .queenAttackLoop
.skipQueens:

    ld hl, (enemyPlPtr)
    ld de, PIECE_ROOK * 3
    add hl, de
    ld ix, (hl)
    ld l, (ix+PL_DATA_SIZE)
    ld a, l
    cp 0
    jp z, .skipRooks

    ld h, 0
.rookAttackLoop:
    ld b, 4 ;end dir
    ld c, 0 ;start dir
    ld a, (ix)

    call movegen_GenerateEnemySlidingAttack

    inc ix
    inc h
    ld a, h
    cp l
    jp nz, .rookAttackLoop
.skipRooks:

    ld hl, (enemyPlPtr)
    ld de, PIECE_BISHOP * 3
    add hl, de
    ld ix, (hl)
    ld l, (ix+PL_DATA_SIZE)
    ld a, l
    cp 0
    jp z, .skipBishops

    ld h, 0
.bishopAttackLoop:
    ld b, 8 ;end dir
    ld c, 4 ;start dir
    ld a, (ix)

    call movegen_GenerateEnemySlidingAttack

    inc ix
    inc h
    ld a, h
    cp l
    jp nz, .bishopAttackLoop
.skipBishops:
    ret

movegen_GenerateEnemyKingAttacks:
    ld a, (enemyKing)
    cp KING_NONE
    ret z

    ld hl, LUT_KingMoveCount
    ld de, 0
    ld e, a
    add hl, de

    ld b, (hl) ;load number of moves
    ld c, 0 ;counter

    ld hl, $0800 ;LUT_KingMovement[square * 8]
    ld l, a
    mlt hl
    ld de, LUT_KingMovement
    add hl, de
    push hl
    pop ix
    
    ld de, 0 ;d stays 0 for loop
.kingMoveLoop:
    ld hl, attackMap
    ld e, (ix)
    add hl, de
    ld (hl), 1

    inc ix
    inc c
    ld a, c
    cp b
    jp nz, .kingMoveLoop

    ret

movegen_GenerateEnemyAttackMap:
    ld a, (currentKing)
    cp KING_NONE
    jp z, .skipGenerateEnemyPinsAndChecks
    call movegen_GenerateEnemyPinsAndChecks
.skipGenerateEnemyPinsAndChecks:

    call movegen_GenerateEnemySlidingAttacks
    call movegen_GenerateEnemyKnightAttackMap
    call movegen_GenerateEnemyPawnAttackMap
    call movegen_GenerateEnemyKingAttacks

    ret

;^^^^ End of enemy-related movgen routines ^^^^

;expects start in D, end in E.
;doesn't preserve HL, DE, A
movegen_AddMove:
    xor a
;expects start in D, end in E, flag in A.
;doesn't preserve HL/A. Preserves DE
movegen_AddMoveFlag:
    push bc
    ld hl, movesPtr ;load moves struct pointer
    ld hl, (hl)

    dec hl ;access move counter

    ld bc, $0300 ;calculate offset to store next move (moveCount * 3)
    ld c, (hl)
    mlt bc

    inc (hl) ;increment move counter
    inc hl ;point to first move again

    add hl, bc ;add offset
    ld (hl), d ;load move start/end (HL+0)=D, (HL+1)=E 
    inc hl
    ld (hl), e
    inc hl
    ld (hl), a ;load move flags (HL+2)=A

    pop bc
    ret

;used to check if a pinned piece's movement is legal.
;expects target square in B and dirOffset in C.
;doesn't preserve HL/A, preserves BC
;sets z flag if legal
movegen_MovingOnRay:
    ;LUT_SquareToSquareDir[63 + targetSquare - raySource]

    push bc ;preserve dirOffset

    ld a, (currentKing)
    neg
    add 63
    add b

    ld bc, 0
    ld c, a

    ld hl, LUT_SquareToSquareDir
    add hl, bc
    ld a, (hl)

    pop bc ;restore dirOffset

    cp c ;check if look-up table value == dirOffset
    ret z

    neg ;check if negative of look-up table value == dirOffset
        ;which is parallel to the direction vector.
    cp c
    ret

;expects castle type in DE
;doesn't preserve DE and HL
;sets z flag if CANT castle.
movegen_CanCastle:
    ld hl, LUT_CastleFlagToStartPos
    add hl, de
    ld e, (hl)

    ld hl, attackMap
    add hl, de

    ld e, 0
.isSquareAttackedLoop:
    ld a, (hl) ;early return if square is attacked.
    cp 1
    ret z

    inc hl ;loop iteration
    inc e
    ld a, e
    cp 2
    jp nz, .isSquareAttackedLoop

    or a ;reset z flag

    ret

LUT_CastleFlagToStartPos:
    db 0, 4, 2, 0, 60, 0, 0, 0, 58

movegen_KingMoves:
    ld a, (currentKing)
    cp KING_NONE
    ret z ;early return if no king
 
    ;registers:
    ;   B - 
    ;   C - 
    ;   DE - temp
    ;   HL - temp
    ;   IXH - number of moves
    ;   IXL - move counter
    ;   IY - movement ptr

    ld de, 0
    ld e, a
    ld hl, LUT_KingMoveCount
    add hl, de
    ld a, (hl)
    ld ixh, a
    ld ixl, 0

    ld hl, $0800
    ld l, e
    mlt hl
    ld de, LUT_KingMovement
    add hl, de
    push hl
    pop iy

    ld de, 0
.moveLoop:
    ld e, (iy) ;target square
    ld hl, pieces
    add hl, de
    ld a, (hl) ;piece at position
    cp PIECE_NONE
    jp z, .skipIsEnemyCheck
    and MASK_PIECE_COLOR
    ld hl, enemyColor
    cp (hl)
    jp nz, .moveLoopContinue
.skipIsEnemyCheck:
    ;don't move to a square that's being attacked.
    ld hl, attackMap
    add hl, de
    ld a, (hl)
    cp 1
    jp z, .moveLoopContinue

    ld a, (currentKing)
    ld d, a ;start pos
    call movegen_AddMove
    ld de, 0
.moveLoopContinue:
    inc iy
    inc ixl
    ld a, ixl
    cp ixh
    jp nz, .moveLoop

;don't check for castling moves if in check
    ld a, (inCheck)
    cp 1
    ret z

    ld a, (canKingSideCastle)
    cp 0
    jp z, .skipKingSideCastle

    ;check if path is clear of other pieces
    ld c, 1
    ld hl, pieces
    ld de, 0
    ld a, (currentKing)
    ld e, a
    add hl, de
    ld de, OFFSET_E
.kingSideIsClearLoop:
    add hl, de
    ld a, (hl)
    cp PIECE_NONE
    jp nz, .skipKingSideCastle

    inc c
    ld a, c
    cp 3
    jp nz, .kingSideIsClearLoop

    ld de, WHITE_KING_CASTLE
    ld a, (currentIndex)
    cp 1
    jp z, .KC_isWhiteMove
    ld e, BLACK_KING_CASTLE ;E vs DE - yay 1 byte optimization!
.KC_isWhiteMove:

    ;checks if squares in path are attacked.
    call movegen_CanCastle
    jp z, .skipKingSideCastle

    ld a, (currentKing)
    ld d, a
    add 2
    ld e, a
    ld a, MOVE_FLAG_KINGSIDE_CASTLE

    call movegen_AddMoveFlag

.skipKingSideCastle:

    ld a, (canQueenSideCastle)
    cp 0
    jp z, .skipQueenSideCastle

    ld c, 1
    ld hl, pieces
    ld de, 0
    ld a, (currentKing)
    ld e, a
    add hl, de
    ld de, OFFSET_W
.queenSideIsClearLoop:
    add hl, de
    ld a, (hl)
    cp PIECE_NONE
    ret nz ;jp nz, .skipQueenSideCastle

    inc c
    ld a, c
    cp 4
    jp nz, .queenSideIsClearLoop

    ld de, WHITE_QUEEN_CASTLE
    ld a, (currentIndex)
    cp 1
    jp z, .QC_isWhiteMove
    ld e, BLACK_QUEEN_CASTLE
.QC_isWhiteMove:

    call movegen_CanCastle
    ret z ;jp z, .skipQueenSideCastle

    ld a, (currentKing)
    ld d, a
    add -2
    ld e, a
    ld a, MOVE_FLAG_QUEENSIDE_CASTLE

    call movegen_AddMoveFlag

.skipQueenSideCastle: ;unused

    ret

;expects position index in A, start direction in C and end direction in B.
;preserves IX and HL
movegen_GenerateSlidingPieceMoves:
    push hl
    push ix

    ld ixl, a

    ;load if piece is pinned.
    ld hl, pinMap
    ld de, 0
    ld e, a
    add hl, de
    ld a, (hl)
    ld ixh, a

;return early if pinned and in check.
    cp 0
    jp z, .skipEarlyReturn
    ld a, (inCheck)
    cp 1
    jp z, .return
.skipEarlyReturn:
    
    ;registers:
    ;   B - target index
    ;   C - squares counter
    ;   DE - temp
    ;   HL - temp
    ;   IXH - isPinned
    ;   IXL - start index
    ;   IYH - offset
    ;   IYL - squares to edge
    ;
    ;shadow registers:
    ;   B - end direction
    ;   C - direction index
    ;   DE - 
    ;   HL - 

    push bc ;transfer BC to BC' and place an extra copy on the stack which is then used at the beginning of dirLoop
    push bc
    exx ;alt reg start
    pop bc
    exx ;alt reg end

.dirLoop:
    pop de ;get BC' (either extra value pushed above or from loop iteration logic)
    ld d, 0
    ld hl, LUT_DirOffset
    add hl, de
    ld a, (hl)
    ld iyh, a

    ;continue if Pinned and not MovingOnRay
    ;note that I need to preserve the value of DE, but BC is unused.

    ld a, ixh ;skip MovingOnRay check if not pinned
    cp 0
    jp z, .skipDirLoopContinueCase
    ld b, ixl
    ld c, iyh
    call movegen_MovingOnRay
    jp nz, .dirLoopContinue
.skipDirLoopContinueCase:

    ;get squares to edge
    ld hl, $0800 ;load start index in HL
    ld a, ixl
    ld l, a

    mlt hl ;(index*8 part of LUT_SquaresToEdge[index * 8 + dirIndex])

    add hl, de ;add dirIndex loaded earlier
    ld de, LUT_SquaresToEdge
    add hl, de
    ld a, (hl)
    cp 0 ;if 0 squares to edge don't loop
    jp z, .squareLoopBreak
    ld iyl, a

    ld b, ixl ;init target index
    ld c, 0 ;init square-loop counter
.squareLoop:
    ld a, b ;update target index
    add iyh
    ld b, a

    ld de, 0
    ld e, b
    ld hl, pieces
    add hl, de
    ld a, (hl) ;load targetPiece
    ld e, a

    ;break if capture && targetPieceColor == currentColor
    cp PIECE_NONE
    jp z, .skipEarlyBreak
    and MASK_PIECE_COLOR
    ld hl, currentColor
    cp (hl)
    jp nz, .skipEarlyBreak
    jp .squareLoopBreak
.skipEarlyBreak:

    push de ;preserve targetPiece (in E)

    ;add move if not InCheck || SquareChecked
    ld a, (inCheck)
    cp 0
    jp z, .doAddMove
    ld hl, checkMap
    ld de, 0
    ld e, b
    add hl, de
    ld a, (hl)
    cp 1
    jp nz, .skipAddMove
.doAddMove:
    ld e, b
    ld d, ixl
    call movegen_AddMove
.skipAddMove:

    pop de ;restore targetPiece
    ld a, e
    cp PIECE_NONE
    jp z, .skipLateBreak
    jp .squareLoopBreak
.skipLateBreak:

    inc c
    ld a, c
    cp iyl
    jp nz, .squareLoop
.squareLoopBreak:
.dirLoopContinue:
    exx ;alt reg start
    inc c
    push bc ;needed for start of loop
    ld a, c
    cp b
    exx ;alt reg end
    jp nz, .dirLoop

    pop bc ;get rid of extra value added to stack above

;assumes BC' isn't on stack
.return:
    pop ix
    pop hl
    ret

;basically the same as enemy version, differences is using currentPlPtr,
;and calling a different function in each loop.
movegen_GenerateSlidingMoves:
    ld hl, (currentPlPtr)
    ld de, PIECE_QUEEN * 3
    add hl, de
    ld ix, (hl)
    ld l, (ix+PL_DATA_SIZE) ;store length in L, (H is used as the loop counter)
    ld a, l
    cp 0
    jp z, .skipQueens

    ld h, 0
.queenAttackLoop:
    ld b, 8 ;end at dir 8
    ld c, 0 ;start at dir 0
    ld a, (ix)

    call movegen_GenerateSlidingPieceMoves

    inc ix
    inc h
    ld a, h
    cp l
    jp nz, .queenAttackLoop
.skipQueens:

    ld hl, (currentPlPtr)
    ld de, PIECE_ROOK * 3
    add hl, de
    ld ix, (hl)
    ld l, (ix+PL_DATA_SIZE)
    ld a, l
    cp 0
    jp z, .skipRooks

    ld h, 0
.rookAttackLoop:
    ld b, 4 ;end dir
    ld c, 0 ;start dir
    ld a, (ix)

    call movegen_GenerateSlidingPieceMoves

    inc ix
    inc h
    ld a, h
    cp l
    jp nz, .rookAttackLoop
.skipRooks:

    ld hl, (currentPlPtr)
    ld de, PIECE_BISHOP * 3
    add hl, de
    ld ix, (hl)
    ld l, (ix+PL_DATA_SIZE)
    ld a, l
    cp 0
    jp z, .skipBishops

    ld h, 0
.bishopAttackLoop:
    ld b, 8 ;end dir
    ld c, 4 ;start dir
    ld a, (ix)

    call movegen_GenerateSlidingPieceMoves

    inc ix
    inc h
    ld a, h
    cp l
    jp nz, .bishopAttackLoop
.skipBishops:
    ret

movegen_GenerateKnightMoves:
    ld hl, (currentPlPtr) ;load piecelist
    ld de, PIECE_KNIGHT * 3
    add hl, de
    ld ix, (hl)

    ld b, (ix+PL_DATA_SIZE)
    ld a, b
    cp 0
    ret z ;early return if 0 knights
    
    ld c, 0

    ;registers:
    ;   B - number of knights
    ;   C - knight loop counter
    ;   DE - temp
    ;   HL - temp
    ;   IX - piecelist ptr
    ;   IY - movement ptr
    ;shadow registers:
    ;   B - number of possible moves from position
    ;   C - move counter
    ;   DE - target square
    ;   HL - temp

.knightLoop:
    ld de, 0
    ld e, (ix) ;knight position

    ld hl, pinMap ;no possible moves if pinned
    add hl, de
    ld a, (hl)
    cp 1
    jp z, .knightLoopContinue

    ld hl, LUT_KnightMoveCount
    add hl, de
    ld d, (hl) ;load number of possible moves
    push de
    exx ;alt reg start
    pop bc
    ld c, 0
    ld de, 0
    exx ;alt reg end

    ld hl, $0800
    ld l, e
    ld a, e ;save knight start pos
    mlt hl
    ld de, LUT_KnightMovement
    add hl, de
    push hl
    pop iy

    ld e, a ;restore knight start pos

    exx ;alt reg start
.moveLoop:
    ld e, (iy) ;target square. Note DE=0 initially.
    inc iy

    ld hl, pieces
    add hl, de
    ld a, (hl) ;target piece
    
;if not capture || targetPieceColor == enemyColor
    cp PIECE_NONE
    jp z, .skipIsEnemyCheck
    and 1000b
    ld hl, enemyColor
    cp (hl)
    jp nz, .moveLoopContinue
.skipIsEnemyCheck:
;if inCheck && !targetSquareChecked continue
    ld a, (inCheck)
    cp 0
    jp z, .doAddMove

    ld hl, checkMap
    add hl, de
    ld a, (hl)
    cp 0
    jp z, .moveLoopContinue
.doAddMove:
    exx ;alt reg end (D' <- E)
    ld a, e
    exx ;alt reg start
    ld d, a
    call movegen_AddMove
    ld de, 0

.moveLoopContinue:
    inc c
    ld a, c
    cp b
    jp nz, .moveLoop
    
    exx ;alt reg end

.knightLoopContinue:
    inc ix
    inc c
    ld a, c
    cp b
    jp nz, .knightLoop

    ret

;preserves BC
;expects upper bytes of DE to be 0
movegen_PawnNonCaptureMoves:
    ;can't move if piece in the way
    ld a, b
    add c
    ld e, a
    ld hl, pieces
    add hl, de
    ld a, (hl)
    cp PIECE_NONE
    ret nz

;for moving a single square
    ;incase pawn is pinned make sure it's moving along the pin line.
    ld hl, pinMap
    add hl, de
    ld a, (hl)
    cp 0
    jp z, .skipPinCheck

    push bc
    ld b, e
    call movegen_MovingOnRay
    pop bc
    
    ret nz
.skipPinCheck:

    ld a, (inCheck)
    cp 0
    jp z, .skipInCheckCheck

    ld hl, checkMap
    add hl, de
    ld a, (hl)
    cp 1
    jp z, .doubleAdvanceMoves
.skipInCheckCheck:

    ld d, b ;load move start square
    ld a, ixh
    cp 1
    jp z, .isPromotion

    call movegen_AddMove

    jp .skipIsPromotion
.isPromotion:
    ld a, MOVE_FLAG_PROMOTE_QUEEN
    call movegen_AddMoveFlag
    ld a, MOVE_FLAG_PROMOTE_KNIGHT
    call movegen_AddMoveFlag
    ld a, MOVE_FLAG_PROMOTE_ROOK
    call movegen_AddMoveFlag
    ld a, MOVE_FLAG_PROMOTE_BISHOP
    call movegen_AddMoveFlag

.skipIsPromotion:
    ld d, 0

;move two squares (note the pin check applies)
.doubleAdvanceMoves:

    ;check if pawn is in it's starting square
    ld a, (movegen_DoubleMoveRank)
    cp iyh
    ret nz

    ld a, e ;calculate new target square
    add c
    ld e, a
    ld hl, pieces
    add hl, de
    ld a, (hl)
    cp PIECE_NONE
    ret nz ;early return if target square isn't empty.

    ld a, (inCheck)
    cp 0
    jp z, .skipInCheckCheck2

    ld hl, checkMap
    add hl, de
    ld a, (hl)
    cp 0
    ret z ;early return if in check and checkmap square is 0

.skipInCheckCheck2:

    ld d, b
    ld a, MOVE_FLAG_DOUBLE_PAWN
    call movegen_AddMoveFlag

    ret

;expects start in B, destination in E
;sets z flag if legal.
;preserves BC, IX, IY, BC'
movegen_IsEpLegal:
    ;preserve registers
    push bc
    push ix
    push iy

    ;early return optimization: Check if king is on same horizontal line or on a diagonal line with the enemy pawn. If not a assumed sliding piece wouldn't have line of sight to it.

    ;C = enemy pawn rank
    ld a, (currentIndex) ;enemyPawnRank = white ? 4 : 3
    add 3
    ld c, a

    ld hl, (currentPlPtr)
    ld de, PIECE_KING * 3
    add hl, de
    ld hl, (hl)
    ld a, (hl)

    ;restore registers
    pop iy
    pop ix
    pop bc
    ret

;expects pawn square in B and upper bytes of DE to be 0'd
movegen_PawnCaptureMoves:
    ;registers:
    ;   DE / HL - temp
    ;   IXL - depends
    ;shadow registers:
    ;   D - dirMin (loop counter)
    ;   E - dirMax (loop limit)

    exx ;alt reg start
    ld de, $0002 ;start 0, end 2

    ld a, iyl
    cp 1
    jp nc, .fileGT0
    ld d, 1
    jp .fileLT7
.fileGT0:

    cp 7
    jp c, .fileLT7
    ld e, 1
.fileLT7:
    exx ;alt reg end

.dirLoop:
    ld a, (currentIndex)
    sla a
    exx ;alt reg start
    add d
    exx ;alt reg end
    ld e, a
    ld hl, LUT_PawnDirColorToOffset
    add hl, de
    ld a, (hl)

    ;registers:
    ;   E - target square
    ;   IXL - offset

    ld ixl, a
    add b
    ld e, a

    ;continue if pinned and not moving on pin ray.

    ld hl, pinMap
    add hl, de
    ld a, (hl)
    cp 0
    jp z, .skipPinCheck
    
    push bc
    ld b, e
    ld c, ixl
    call movegen_MovingOnRay
    pop bc
    
    jp .dirLoopContinue
.skipPinCheck:

    ld hl, pieces ;check if enemy piece is on target square
    add hl, de
    ld a, (hl)
    and MASK_PIECE_COLOR
    ld hl, enemyColor
    cp (hl)
    jp nz, .skipRegularCapture

    ld a, (inCheck)
    cp 0
    jp z, .skipInCheckCheck1

    ld hl, checkMap
    add hl, de
    ld a, (hl)
    cp 0
    jp nz, .dirLoopContinue
.skipInCheckCheck1:
    ;regular capture (not en passant)

    ld d, b ;load move start square
    ld a, ixh
    cp 1
    jp z, .isPromotion

    call movegen_AddMove

    jp .skipIsPromotion
.isPromotion:
    ld a, MOVE_FLAG_PROMOTE_QUEEN
    call movegen_AddMoveFlag
    ld a, MOVE_FLAG_PROMOTE_KNIGHT
    call movegen_AddMoveFlag
    ld a, MOVE_FLAG_PROMOTE_ROOK
    call movegen_AddMoveFlag
    ld a, MOVE_FLAG_PROMOTE_BISHOP
    call movegen_AddMoveFlag

.skipIsPromotion:
    ld d, 0

.skipRegularCapture:
    ;en passant capture
    ld a, (epPossible)
    cp 0
    jp z, .dirLoopContinue

    ld a, (movegen_EpSquare)
    cp e ;target square
    jp nz, .dirLoopContinue

    ld a, (inCheck)
    cp 0
    jp z, .skipInCheckCheck2

    ld hl, checkMap
    add hl, de
    ld a, (hl)
    cp 0
    jp z, .dirLoopContinue
.skipInCheckCheck2:
;edge case where a king could be exposed to attack by a sliding piece that was blocked by the pawn captured.
    call movegen_IsEpLegal
    jp nz, .dirLoopContinue

    ;ep capture move
    ld d, b
    ld a, MOVE_FLAG_EN_PASSANT
    call movegen_AddMoveFlag

.dirLoopContinue:
    exx ;alt reg start
    inc d
    ld a, d
    cp e
    exx ;alt reg end
    jp nz, .dirLoop

    ret

;[currentIndex*2 + dirLoopIndex]
LUT_PawnDirColorToOffset: db OFFSET_SW, OFFSET_SE, OFFSET_NW, OFFSET_NE

movegen_DoubleMoveRank: db 0
movegen_PromotionRank: db 0
movegen_PawnFwdOffset: db 0
movegen_EpSquare: db 0 ;RANK_FILE_TO_SQUARE(white ? 5 : 2, epFile)

movegen_GeneratePawnMoves:
    ld hl, (currentPlPtr)
    ld de, PIECE_PAWN * 3
    add hl, de
    ld ix, (hl)

    ld a, (ix+PL_DATA_SIZE)
    cp 0
    ret z ;early return if 0 pawns

    exx ;alt reg start
    ld b, a
    ld c, 0
    exx ;alt reg end

    ld a, (currentIndex)
    cp 0
    jp z, .blackMove

    ld a, 1
    ld (movegen_DoubleMoveRank), a
    ld a, 6
    ld (movegen_PromotionRank), a
    ld a, OFFSET_N
    ld (movegen_PawnFwdOffset), a
    ld a, (epFile)
    add 5*8
    ld (movegen_EpSquare), a

    jp .skipBlackMove
.blackMove:
    ld a, 6
    ld (movegen_DoubleMoveRank), a
    ld a, 1
    ld (movegen_PromotionRank), a
    ld a, OFFSET_S
    ld (movegen_PawnFwdOffset), a
    ld a, (epFile)
    add 2*8
    ld (movegen_EpSquare), a
.skipBlackMove:

    ;registers:
    ;   B - square
    ;   C - offset
    ;   DE - temp
    ;   HL - temp
    ;   IX - pawn data (outside main loop)
    ;   IXH - isPromotionRank
    ;   IXL - used by PawnCaptureMoves
    ;   IYH - rank
    ;   IYL - file
    ;shadow registers:
    ;   B - number of pawns
    ;   C - pawn counter
    ;   DE - ?
    ;   HL - ?

.pawnLoop:
    ld b, (ix) ;pawn position
    push ix

    ld a, b ;calculate rank and file
    and 111b
    ld iyl, a
    ld a, b
    sra a
    sra a
    sra a
    ld iyh, a

    ld a, (movegen_PawnFwdOffset)
    ld c, a

    ld ixh, 1
    ld a, (movegen_PromotionRank)
    cp iyh
    jp z, .isPromotion
    ld ixh, 0
.isPromotion:

    call movegen_PawnNonCaptureMoves

    call movegen_PawnCaptureMoves

    pop ix
    inc ix
    exx ;alt reg start
    inc c
    ld a, c
    cp b
    exx ;alt reg end
    jp nz, .pawnLoop

    ret

movegen_Init:
    ld hl, movesPtr
    ld (hl), ix

    ld (ix-1), 0 ;reset move count

    xor a
    ld (inCheck), a
    ld (inDoubleCheck), a
    ld (epPossible), a

    ;en passant
    ld a, (epFile)
    cp EP_NONE
    jp z, .epNotPossible
    ld a, 1
    ld (epPossible), a
.epNotPossible:

    call board_SetIndexVars ;currentColor/index, enemyColor/index

    ;set Piece-list tables
    ld bc, plTableWhite
    ld de, plTableBlack
    ld hl, currentPlPtr
    ld iy, enemyPlPtr

    ld a, (whiteToMove)
    cp 1
    jp z, .skipBlackMove

    ld de, plTableWhite
    ld bc, plTableBlack
.skipBlackMove:
    ld (hl), bc
    ld (iy), de

    ;castle possibility
    ld a, (whiteToMove)
    cp 1
    ld a, (castleFlags)
    jp z, .whiteMove

    sra a
    sra a
.whiteMove:
    ld hl, canKingSideCastle
    ld (hl), 0
    bit 0, a
    jp z, .noKingCastle
    ld (hl), 1
.noKingCastle:
    ld hl, canQueenSideCastle
    ld (hl), 0
    bit 1, a
    jp z, .noQueenCastle
    ld (hl), 1
.noQueenCastle:

;load each kings square (KING_NONE otherwise)
    ld hl, (currentPlPtr)
    ld de, PIECE_KING * 3
    add hl, de
    ld iy, (hl)
    ld a, (iy+PL_DATA_SIZE)
    cp 0
    jp z, .noCurrentKing
.hasCurrentKing:
    ld a, (iy)
    ld (currentKing), a
    jp .skipNoCurrentKing
.noCurrentKing:
    ld hl, currentKing
    ld (hl), KING_NONE
.skipNoCurrentKing:

    ld hl, (enemyPlPtr)
    ld de, PIECE_KING * 3
    add hl, de
    ld iy, (hl)
    ld a, (iy+PL_DATA_SIZE)
    cp 0
    jp z, .noEnemyKing
.hasEnemyKing:
    ld a, (iy)
    ld (enemyKing), a
    jp .skipNoEnemyKing
.noEnemyKing:
    ld hl, enemyKing
    ld (hl), KING_NONE
.skipNoEnemyKing:

    ;reset attack/check/pin maps
    ld hl, attackMap
    ld (hl), 0
    ld de, attackMap+1
    ld bc, 64 * 3 - 1
    ldir

    ret

;expects moves struct in IX
;TODO: setting to generate capture moves only, needed for Q-Search
GenerateMoves:
    call movegen_Init

    call movegen_GenerateEnemyAttackMap

    call movegen_KingMoves

    ;if in double check, only the king can move anyway.
    ld a, (inDoubleCheck)
    cp 1
    ret z

    call movegen_GenerateSlidingMoves
    call movegen_GenerateKnightMoves
    call movegen_GeneratePawnMoves

    pushall
    ld ix, movesPtr
    ld ix, (ix)

    ld a, (ix-1) ;movecount
    ld iy, varA
    ld (iy), a

    ; ld a, (ix+1) ;end 1
    ; ld (varB), a
    ; ld a, (ix+1+3) ;end 1
    ; ld (varC), a
    ; ld a, (ix+1+6) ;end 1
    ; ld (varD), a
    popall

    ret
