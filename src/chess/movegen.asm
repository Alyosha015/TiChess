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
    ; IX - moves struct
    ; IYH - offset
    ; IYL - squares
    ;shadow registers:
    ; B - dir
    ; C - dirEnd
    ; D - square counter
    ; E - foundFriendlyPiece (inSquareLoop)
    ; HL - 

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
    ld de, 0
    exx ;alt reg end
    ret z

.dirLoop:
    exx ;alt reg start
    ld hl, LUT_DirOffset
    ld e, b
    add hl, de
    ld a, (hl)
    ld iyh, a

    ld a, (currentKing)
    sla a
    sla a
    sla a
    add iyh

    ld de, 0
    ld e, a
    ld hl, LUT_SquaresToEdge
    add hl, de
    ld a, (hl)
    ld iyl, a

    ld e, 0 ;init foundFriendlyPiece
    exx ;alt reg end

    ld a, (currentKing)
    add iyh
    ld b, a ; piece + offset
.squareLoop:
    ld hl, pieces
    ld de, 0
    ld e, b
    add hl, de

    ld c, (hl)
    cp PIECE_NONE
    jp z, .squareLoopContinue

    ;check color
    ld a, c
    and 1000b
    ld hl, currentColor
    cp (hl)
    jp nz, .enemyColor
.currentColor:
    exx ;alt reg start
    ld a, e
    cp 1
    jp z, .squareLoopBreakExx
    ld e, 1
    exx ;alt reg end
.enemyColor:
    ;check if enemy piece is a slider which can attack in this direction, otherwise break out of square-loop.
    ld a, c
    and 0111b
    cp PIECE_QUEEN
    jp z, .canBeAttacked

;if it's not a queen check rook/bishop
    exx ;alt reg start
    bit 3, b
    jp z, .checkBishop
.checkRook:
    cp PIECE_ROOK
    jp nz, .squareLoopBreakExx
    jp .canBeAttacked
.checkBishop:
    cp PIECE_BISHOP
    jp nz, .squareLoopBreakExx
.canBeAttacked:
    ld a, e
    exx ;alt reg end

    ld de, 0
    ld hl, currentKing
    ld e, (hl)

    cp 0
    jp z, .isFriendly
;add to checkmap.
;   d - loop counter
;   e - loop limit
    ld hl, checkMap
    add hl, de
    exx ;alt reg start
    ld a, d
    exx ;alt reg end
    ld e, a
.checkMapLoop:
    push de
    ld de, 0
    ld e, iyh
    add hl, de
    pop de

    ld (hl), 1

    inc d
    ld a, d
    cp e
    jp nz, .checkMapLoop

    call movegen_IncCheckCount
    jp .squareLoopBreak
;add to pinmap
.isFriendly:
    ld hl, pinMap
    add hl, de
    exx ;alt reg start
    ld a, d
    exx ;alt reg end
    ld e, a
.pinMapLoop:
    push de
    ld de, 0
    ld e, iyl
    add hl, de
    pop de

    ld (hl), 1

    inc d
    ld a, d
    cp e
    jp nz, .pinMapLoop

.squareLoopContinue:
    exx ;alt reg start
    inc d
    cp iyl
    exx ;alt reg end
    jp nz, .squareLoop
    jp .squareLoopBreak
.squareLoopBreakExx:
    exx
.squareLoopBreak:

;handle direction loop
    exx ;alt reg start
    inc b
    ld a, b
    cp c
    exx ;alt reg end
    jp nz, .dirLoop
    
    ret

movegen_GenerateEnemyAttackMap:
    ld a, (currentKing)
    cp KING_NONE
    jp nz, .skipGenerateEnemyPinsAndChecks
    call movegen_GenerateEnemyPinsAndChecks
.skipGenerateEnemyPinsAndChecks:

    ret

movegen_GenerateSlidingMoves:

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
    ld iy, currentPlPtr

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

movegen_KingMoves:

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

    ret
