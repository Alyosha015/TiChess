;variables
movesPtr: rb 3

    KING_NONE := 255

currentKing: db KING_NONE
enemyKing: db KING_NONE

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

;expects position-index in iyl, start direction in B and end direction in C.
;preserves ix
movegen_GenerateEnemySlidingAttack:
;registers:
;   B - direction index
;   C - end direction
;   DE - temp
;   HL - temp
;   IYH - offset
;   IYL - index
;alt registers
;
;
;

.loop:
    ld de, 0 ;load offset
    ld hl, LUT_DirOffset
    ld e, b
    add hl, de
    ld a, (hl)
    ld iyh, a

    ld hl, 0 ;(LUT_SquaresToEdge[index * 8 + dirIndex])
    ld a, iyl
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

    exx ;alt reg start
    exx ;alt reg end

.squareLoop:
    

.squareLoopBreak:
    inc b
    ld a, b
    cp c
    jp nz, .loop
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
    ld bc, 8 ;start 0, end 8
    push hl
    ld a, (ix)
    ld iyl, a
    call movegen_GenerateEnemySlidingAttack
    pop hl

    inc ix
    inc h
    ld a, h
    cp l
    jp nz, .queenAttackLoop
.skipQueens:


.skipRooks:


.skipBishops:



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
