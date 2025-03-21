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
    ld de, 3
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
    and 1000b
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
    and 0111b
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
;preserves ix
movegen_GenerateEnemySlidingAttack:
    push ix

    ld ixl, a

;registers:
;   B - target index
;   C - square counter
;   DE - temp
;   HL - temp
;   IYH - offset
;   IYL - squares to edge
;   IXH - 
;   IXL - start index
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

    ld c, 0 ;init square-loop counter

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

    ld a, ixl ;init start index
    ld b, a
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

    pop bc ;get rid of extra value on stack from above    
    pop ix ;restore ix
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
    and 0111b ;load pawn file
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
    push hl
    call movegen_GenerateEnemySlidingAttack
    pop hl

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
    push hl
    call movegen_GenerateEnemySlidingAttack
    pop hl

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
    push hl
    call movegen_GenerateEnemySlidingAttack
    pop hl

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

;expects start in E, end in D.
;doesn't preserve HL, DE, A
movegen_AddMove:
    xor a
;expects start in E, end in D, flag in A.
;doesn't preserve HL, DE, A
movegen_AddMoveFlags:
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
    ld (hl), de ;load move start/end (IX+2)=E, (IX+1)=D 
    ld (hl), a ;load move flags (IX+0)=A

    pop bc
    ret

;used to check if a pinned piece's movement is legal.
;expects target square in D and dirOffset in E.
;sets z flag if legal
movegen_MovingOnRay:
    ;LUT_SquareToSquareDir[63 + targetSquare - raySource]

    push de ;preserve dirOffset

    ld a, (currentKing)
    neg
    add 63
    add d

    ld de, 0
    ld e, a

    ld hl, LUT_SquareToSquareDir
    add hl, de
    ld a, (hl)

    pop de ;restore dirOffset

    cp e ;check if look-up table value == dirOffset
    ret z

    neg ;check if negative of look-up table value == dirOffset
        ;which is parallel to the direction vector.
    cp e
    ret

;expects castle type in DE
;doesn't preserve DE and HL
movegen_CanCastle:
    ld hl, LUT_CastleFlagToStartPos
    add hl, de
    ld a, (hl)

    ld de, 0
    ld e, a ;start
    add 2
    ld d, a ;end


    ld hl, attackMap



    ret

LUT_CastleFlagToStartPos:
    db 0, 4, 2, 0, 60, 0, 0, 0, 58

movegen_KingMoves:

    ret

;expects position index in A, start direction in C and end direction in B.
movegen_GenerateSlidingPieceMoves:
    
    ret

;basically the same as enemy version, differences is using currentPlPtr,
;and calling a different function in eah loop.
; 
;so I could probably combine the too if I wanted to save 100 bytes.
;
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
    push hl
    call movegen_GenerateSlidingMoves
    pop hl

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
    push hl
    call movegen_GenerateSlidingMoves
    pop hl

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
    push hl
    call movegen_GenerateSlidingMoves
    pop hl

    inc ix
    inc h
    ld a, h
    cp l
    jp nz, .bishopAttackLoop
.skipBishops:
    ret

movegen_GenerateKnightMoves:

    ret

movegen_GeneratePawnMoves:

    ret

movegen_Init:
    ld hl, movesPtr
    ld (hl), ix

    ld (ix-1), 0 ;reset move count

    ld hl, inCheck
    ld (hl), 0
    ld hl, inDoubleCheck
    ld (hl), 0

    ;en passant
    ld hl, epPossible
    ld (hl), 0
    ld a, (epFile)
    cp EP_NONE
    jp z, .epNotPossible

    ld (hl), 1
.epNotPossible:

    call BoardSetIndexVars ;currentColor/index, enemyColor/index

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
    ld hl, currentKing
    ld (hl), a
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
    ld hl, enemyKing
    ld (hl), a
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

    ret
