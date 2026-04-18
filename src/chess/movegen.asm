MG_KING_NONE := 255

C_CurrentKing: db 0     ;stores positions of kings
C_EnemyKing: db 0

C_InCheck: db 0
C_InDoubleCheck: db 0

C_CurrentPlPtr: dl 0    ;holds addresses to look up tables of current and enemy pieceslists
C_EnemyPlPtr: dl 0

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

    ret

;****************************************************************
; MoveGen_GenerateEnemySlidingAttackMap - (internal) enemy moves
;   for queen / rook / bishop.
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
; Used to create fill attack map for sliding pieces, with controls
; for what directions to check to make it work for bishop/rook/queen
; movement.
;
;****************************************************************
MoveGen_GenerateEnemySlidingAttackMap:

    ret

;****************************************************************
; MoveGen_GenerateEnemySlidingAttackMaps - (internal) calls
;   MoveGen_GenerateEnemySlidingAttackMap for the 3 types of
;   sliding pieces.
;
;****************************************************************
MoveGen_GenerateEnemySlidingAttackMaps:
    ;QUEEN
    ld hl, (C_EnemyPlPtr)
    ld de, PIECE_QUEEN * 3
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)
    or a
    ld bc, 0 * 256 + 8
    call nz, MoveGen_GenerateEnemySlidingAttackMap

    ;ROOK
    ld hl, (C_EnemyPlPtr)
    ld de, PIECE_ROOK * 3
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)
    or a
    ld bc, 0 * 256 + 4
    call nz, MoveGen_GenerateEnemySlidingAttackMap

    ;BISHOP
    ld hl, (C_EnemyPlPtr)
    ld de, PIECE_BISHOP * 3
    add hl, de
    ld ix, (hl)
    ld a, (ix + PL_DATA_SIZE)
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
