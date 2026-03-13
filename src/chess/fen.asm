;****************************************************************
;
; https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation
;
;****************************************************************

FEN_StartPosition:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0


;if optimizing for size was needed I could fit the "_fen_xxxx" variables in the unused parts
;of this lookup table and merge it with FEN_LUT_Ascii_to_castle_flags, but that seems excessive.
FEN_LUT_Ascii_to_piece_type:    ;inde with ASCII MOD 32
    db 0, 0, PIECE_BISHOP, 0, 0, 0, 0, 0, 0, 0, 0, PIECE_KING, 0, 0, PIECE_KNIGHT, 0, PIECE_PAWN, PIECE_QUEEN, PIECE_ROOK

FEN_LUT_Ascii_to_castle_flags:  ;index with ASCII - 75 ('K')
    db CASTLE_FLAG_WHITE_KING, 0, 0, 0, 0, 0, CASTLE_FLAG_WHITE_QUEEN, 0, 0, 0, 0, 0, 0, 0, 0, 0 ;Z
    db 0, 0, 0, 0, 0, 0 ;characters between 'Z' and 'a'
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, CASTLE_FLAG_BLACK_KING, 0, 0, 0, 0, 0, CASTLE_FLAG_BLACK_QUEEN ;a-q

_fen_string_ptr: dl 0
_fen_sections: rb 5             ;used to store where to split fen string. See comment in subroutine below.
_fen_count: db 0
_fen_board_index: db 0

;****************************************************************
;
; FEN_Load - Load engine/game chess board with provided FEN position.
;
; INPUTS:
;   IX - FEN string pointer.
;
; DESTROYS:
;   ALL
;
;****************************************************************
FEN_Load:
    xor a
    ld (_fen_count), a

    lea hl, ix
    ld (_fen_string_ptr), hl

    ld ix, _fen_sections
    ld iy, _fen_count

    ld c, 0 ;index counter
.stringSplitLoop:
    ld a, (hl)                  ;load next character
    inc hl
    inc c                       ;incremented before the comparisons etc, means that the index
                                ;in _fen_sections points to the character after the space:
                                ;
                                ;rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
                                ;                                            ^ ^    ^ ^ ^
                                ;                                            0 1    2 3 4
    or a
    jr z, .stringSplitLoopBreak
    cp ' '
    jr nz, .notDelimiter

    ld (ix), c                  ;add next _fen_sections entry
    inc ix

    inc (iy)                    ;increment _fen_counter

    ld a, (iy)
    cp 6
    jr z, .stringSplitLoopBreak ;in case the string is invalid and has too many spaces
                                ;stop the _fen_sections buffer from overflowing
.notDelimiter:
    jr .stringSplitLoop
.stringSplitLoopBreak:

;load piece positions
    ld a, 56
    ld (_fen_board_index), a

    ld hl, _fen_sections        ;load number of characters in 1st section of string.
    ld c, (hl)
    dec c                       ;adjust counter so the space character isn't parsed.

    ld ix, (_fen_string_ptr)

.pieceParseLoop:
    ld a, (ix)
    inc ix

    cp '/'                      ;handle rank seperator
    jr nz, .notRankSeperator

    ld a, (_fen_board_index)    ;set file to 0, decrement rank
    sub 9
    and $F8                     ;0b1111_1000
    ld (_fen_board_index), a

    jr .pieceParseLoopContinue
.notRankSeperator:

    cp '1'                      ;check if between 1 and 9
    jr c, .notNumber            ;less than
    cp '9' + 1
    jr nc, .notNumber           ;greater than or equal to

    sub '0'                     ;file += char - '0'
    ld hl, _fen_board_index
    add (hl)
    ld (_fen_board_index), a

    jr .pieceParseLoopContinue
.notNumber:

    ld b, PIECE_WHITE

    cp 'a'
    jr c, .notLowercase
    sub 32                      ;convert lowercase piece type to uppercase

    ld b, PIECE_BLACK
.notLowercase:

    ld de, 0

    ld hl, FEN_LUT_Ascii_to_piece_type ;get piece type from ascii value
    and $1F                     ;0001_1111b
    ld e, a
    add hl, de
    ld a, (hl)

    or b                        ;adds piece color to type and store in B
    ld b, a

    ld a, (_fen_board_index)    ;write piece to board and increment board_index
    ld e, a
    inc a
    ld (_fen_board_index), a
    ld hl, C_Board
    add hl, de
    ld (hl), b

    push ix                     ;add to piece list
    push bc

    ld hl, PL_LUT
    ld d, b
    ld e, 3
    mlt de
    add hl, de
    ld ix, (hl)
    ld a, (_fen_board_index)
    dec a                       ;account for index being incremented earlier
    ld e, a
    call PL_Add

    pop bc
    pop ix

.pieceParseLoopContinue:
    dec c
    jr nz, .pieceParseLoop

    ld de, 0
    ld bc, 0

;load turn to move
    ld hl, _fen_sections
    ld e, (hl)

    ld hl, (_fen_string_ptr)
    add hl, de
    ld a, (hl)
    cp 'w'
    ld a, 1                     ;load A with 1 or 0 depending on side to move
    jr z, .skipBlackToMove
    xor a
.skipBlackToMove:
    ld (C_WhiteToMove), a

;load castle flags (KQkq etc)

    xor a
    ld (C_CastleFlags), a

    ld hl, _fen_sections + 1    ;start of castle flags string
    ld e, (hl)
    ld ix, (_fen_string_ptr)
    add ix, de

.casteFlagsParseLoop:
    ld a, (ix)                  ;load character
    inc ix

    cp ' '
    jr z, .castleFlagParseLoopBreak
    cp '-'                      ;if there aren't any castle flags '-' is used by the notation
    jr z, .castleFlagParseLoopBreak

    sub 'K'
    ld hl, FEN_LUT_Ascii_to_castle_flags
    ld e, a
    add hl, de

    ld a, (C_CastleFlags)
    or (hl)
    ld (C_CastleFlags), a

    jr .casteFlagsParseLoop
.castleFlagParseLoopBreak:

;load ep file
    ld a, EN_PASSANT_NONE
    ld (C_EpFile), a
    
    ld hl, _fen_sections + 2
    ld e, (hl)
    ld hl, (_fen_string_ptr)
    add hl, de

    ld a, (hl)
    cp '-'
    jr z, .skipEpFileParse

    sub 'a'
    ld (C_EpFile), a
.skipEpFileParse:

;half-move clock

;full move clock

    ret
