;variables
movesPtr: rb 3

    KING_NONE := 255

currentKing: db KING_NONE
enemyKing: db KING_NONE

;attack map - squares currently attacked by the enemy, and
;   if a king is attacked by a slider the squares which are
;   are dangerous to the king, even if the sliding piece
;   technically doesn't attack them because the king blocks
;   them from moving there.
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
    ld hl, 0
    ld a, (currentKing) ;king * 8 in HL
    ld l, a
    add hl, hl
    add hl, hl
    add hl, hl
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
    and 8
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
    and 7
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
    ld hl, 0 ;load start index in HL
    ld a, ixl
    ld l, a

    ld c, 0 ;init square-loop counter

    add hl, hl ;(LUT_SquaresToEdge[index * 8 + dirIndex])
    add hl, hl
    add hl, hl
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

movegen_GenerateEnemyKnightAttackMap:

    ret

movegen_GenerateEnemyPawnAttackMap:

    ret

movegen_GenerateEnemyAttackMap:
    ld a, (currentKing)
    cp KING_NONE
    jp z, .skipGenerateEnemyPinsAndChecks
    call movegen_GenerateEnemyPinsAndChecks
.skipGenerateEnemyPinsAndChecks:

;generate attack maps for sliding pieces
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

    ;knight / pawn attack maps
    call movegen_GenerateEnemyKnightAttackMap
    call movegen_GenerateEnemyPawnAttackMap

    ;generate enemy king attack map

    ret

movegen_GenerateSlidingMoves:

    ret

movegen_KingMoves:

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

    push ix

    call movegen_GenerateEnemyAttackMap

    pop ix

    call movegen_KingMoves

    ;if in double check, only the king can move anyway.
    ld a, (inDoubleCheck)
    cp 1
    ret z

    ret
