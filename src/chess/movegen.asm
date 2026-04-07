MG_KING_NONE := 255

C_CurrentKing: db 0     ;stores positions of kings
C_EnemyKing: db 0

C_InCheck: db 0
C_InDoubleCheck: db 0

C_CurrentPlPtr: dl 0    ;holds addresses to look up tables of current and enemy pieceslists
C_EnemyPlPtr: dl 0

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

;****************************************************************
; MoveGen_SetPieceListVariables - (internal) sets C_CurrentPlPtr
;   and C_EnemyPlPtr based on C_WhiteToMove value.
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

MoveGen_GenerateEnemyKnightAttackMap:

    ret

MoveGen_GenerateEnemyPawnAttackMap:

    ret

MoveGen_GenerateEnemyKingAttackMap:

    ret

;****************************************************************
; MoveGen_GenerateAttackMaps - (internal) creates pin/check/attack
;   maps.
;
; DESTROYS: All
;****************************************************************
;
;****************************************************************
MoveGen_GenerateAttackMaps:
    ld a, (C_CurrentKing)
    cp MG_KING_NONE
    call nz, MoveGen_GeneratePinMaps

    ;sliding piece attack maps
    ;QUEEN
    ld ix, (C_EnemyPlPtr)
    ld de, PIECE_QUEEN * 3
    add ix, de
    ld a, (ix + PL_DATA_SIZE)
    or a
    ;ld bc, 8
    call nz, MoveGen_GenerateEnemySlidingAttackMap

    ;ROOK

    ;BISHOP

    call MoveGen_GenerateEnemyKnightAttackMap
    call MoveGen_GenerateEnemyPawnAttackMap

    call MoveGen_GenerateEnemyKingAttackMap

    ret

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
