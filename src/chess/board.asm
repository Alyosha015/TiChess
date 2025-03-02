;handles board representation, loading, and make / unmake move functions

    EP_NONE := 15
    WHITE_KING_CASTLE := 0001b
    WHITE_QUEEN_CASTLE := 0010b
    BLACK_KING_CASTLE := 0100b
    BLACK_QUEEN_CASTLE := 1000b

    MASK_REMOVE_WHITE_CASTLE := 1100b
    MASK_REMOVE_BLACK_CASTLE := 0011b

_rank: db 0
_file: db 0

;******** Board State ********
whiteToMove: 
currentIndex: db 0
currentColor: db 0
enemyIndex: db 0
enemyColor: db 0
castleFlags: db 0
epFile: db 0
capturedPiece: db 0

;96 B - 32 entries max at 3B / entry
gameStateStack: rb 96
gameStateSp: db 0

;board representation
pieces: rb 64

;used by fen loader in BoardLoad
fenSections: rb 6
fenSectionsCount: db 0

BoardMakeMove:

    ret


BoardUnmakeMove:

    ret


;Expects pointer to fen string in HL
BoardLoad:
    push hl ;save str pointer

    call PieceListResetAll

    ld hl, pieces
    ld (hl), 0
    ld de, pieces+1
    ld bc, 63
    ldir

    ld a, EP_NONE
    ld (epFile), a
    xor a, a
    ld (castleFlags), a
    ld (capturedPiece), a
    ld (gameStateSp), a

    pop hl ;load fen string again, but keep it on the stack
    push hl

    ld iy, fenSections
    ld ix, fenSectionsCount

    ;find indicies of where each space-seperated section of a fen string ends.
    ld c, 0     ;index
    ld (ix), 0
.loop_0:
    ld a, (hl)  ;load next character

    ;skip adding section if ascii is greater than space character.
    ;this way a space and 0 will trigger adding the end of a section.
    cp ' '+1
    jp nc, .loop_continue_0

    ld (iy), c
    inc iy
    inc (ix)

    cp 0                ;exit if end of string is reached.
    jp z, .loop_exit_0

    ld a, (ix)          ;exit if already parsed 6 sections.
    cp 6
    jp z, .loop_exit_0
.loop_continue_0:
    inc hl
    inc c
    jp .loop_0
.loop_exit_0:

;********************************
;parses piece positions.
;a = character
;c = index
;iy = string pointer
;ix = address to length
    ld c, 0
    pop iy
    push iy
    ld ix, fenSections

    xor a, a
    ld (_file), a
    ld a, 7
    ld (_rank), a

.loop_1:
    ld a, (iy) ;current character

    cp '0'
    jp c, .parser_skip_number ;jp c -> less than comparison.
    cp '9'+1
    jp nc, .parser_skip_number ;jp nc -> greater than or equal comparison.
.parser_number:
    sub a, '0'
    ld hl, _file
    add a, (hl)
    ld (_file), a
    jp .loop_continue_1
.parser_skip_number:
    cp '/'
    jp nz, .parser_skip_slash
.parser_slash:
    xor a, a
    ld (_file), a
    ld hl, _rank
    dec (hl)
    jp .loop_continue_1
.parser_skip_slash:
.parser_piece:
    ;b stores the piece itself as it's parsed
    ld b, PIECE_WHITE

    cp 'a'
    jp c, .not_lowercase
    cp 'z'+1
    jp nc, .not_lowercase
.lowercase:
    ld b, PIECE_BLACK
    sub a, 32
.not_lowercase:
;calculate index (rank * 8 + file)
    ld d, a ;preserve character being parsed

    ld hl, _rank
    ld a, (hl)
    sla a
    sla a
    sla a
    ld hl, _file
    add a, (hl)
    inc (hl) ;otherwise _file would have to be incremented later

    ld e, a ;store index in e
    ld a, d ;restore character being parsed

    cp 'K'
    jp nz, .piece_not_king
    ld d, PIECE_KING
    jp .piece_exit
.piece_not_king:
    cp 'Q'
    jp nz, .piece_not_queen
    ld d, PIECE_QUEEN
    jp .piece_exit
.piece_not_queen:
    cp 'R'
    jp nz, .piece_not_rook
    ld d, PIECE_ROOK
    jp .piece_exit
.piece_not_rook:
    cp 'B'
    jp nz, .piece_not_bishop
    ld d, PIECE_BISHOP
    jp .piece_exit
.piece_not_bishop:
    cp 'N'
    jp nz, .piece_not_knight
    ld d, PIECE_KNIGHT
    jp .piece_exit
.piece_not_knight:
    cp 'P'
    jp nz, .piece_not_pawn
    ld d, PIECE_PAWN
.piece_not_pawn:
.piece_exit:
    ld a, b ;color
    add a, d ;type
    ld b, e
    ld de, 0
    ld e, b ;restore index
;store piece in both board representations

    pushall

    ld bc, 0
    ld c, e ;index
    ld hl, plTable
    ld e, a
    add a, a
    add a, e
    ld de, 0
    ld e, a
    add hl, de ;plTable + piece * 3

    ld ix, (hl)

    call PieceListAdd

    popall

    ld hl, pieces
    ld d, 0
    add hl, de
    ld (hl), a
.loop_continue_1:
    inc iy
    inc c
    ld a, c
    cp (ix)
    jp nz, .loop_1
.loop_exit_1:

;early return in case of incomplete fen string.
    ld a, (ix)
    cp 4 ;note: doesn't account for halfmove and fullmove clocks.
    ret c

;********************************
    ld iy, fenSections

;parses side to move
    pop ix
    push ix
    inc iy
    ld bc, 0
    ld c, (iy)
    dec c
    add ix, bc

    ld hl, whiteToMove
    ld (hl), 1

    ld a, (ix)
    cp 'w'
    jp z, .blackToMove
    ld (hl), 0
.blackToMove:

;parses castling rights.
;IX = string ptr
    pop ix
    push ix
    ld bc, 0
    ld c, (iy)
    inc c
    add ix, bc
    inc iy

    ld hl, castleFlags
    ld (hl), 0
    ld bc, 0
.loop_castle_flags:
    ld a, (ix)
    inc ix
    cp ' '
    jp z, .loop_castle_flags_exit
    cp '-'
    jp z, .loop_castle_flags_exit

    cp 'K'
    jp nz, .cf_skip_K
    ld a, (hl)
    add a, WHITE_KING_CASTLE
    ld (hl), a
    jp .loop_castle_flags
.cf_skip_K:
    cp 'Q'
    jp nz, .cf_skip_Q
    ld a, (hl)
    add a, WHITE_QUEEN_CASTLE
    ld (hl), a
    jp .loop_castle_flags
.cf_skip_Q:
    cp 'k'
    jp nz, .cf_skip_k
    ld a, (hl)
    add a, BLACK_KING_CASTLE
    ld (hl), a
    jp .loop_castle_flags
.cf_skip_k:
    ld a, (hl)
    add a, BLACK_QUEEN_CASTLE
    ld (hl), a
    jp .loop_castle_flags
.loop_castle_flags_exit:

;parses ep passant target file
    pop ix
    ld bc, 0
    ld c, (iy)
    add ix, bc
    inc ix

    ld hl, epFile
    ld (hl), EP_NONE

    ld a, (ix)
    cp '-'
    jp z, .ep_file_parse_skip
    sub a, 'a'
    ld (hl), a
.ep_file_parse_skip:
;parsing the halfmove and fullmove clocks will happen after, but I don't think I'll need them.

    ret

;uses OS print functions etc, won't work in 8bpp mode and can be removed for release version.
BoardPrint:
    ld a, 7
    ld (_file), a
    ld (_rank), a

    setCursorPos 2, 0
    ld hl, BoardPrintBlankLine
    push hl
    call ti.os.PutStrFull
    pop hl

    setCursorPos 2, 9
    ld hl, BoardPrintBlankLine
    push hl
    call ti.os.PutStrFull
    pop hl

;print side to move
    setCursorPos 19, 0
    ld ix, BoardPrintSideToMove
    ld (ix+6), 'W'
    ld hl, whiteToMove
    ld a, (hl)
    cp 1
    jp z, .whiteToMove
    ld (ix+6), 'B'
.whiteToMove:
    ld hl, BoardPrintSideToMove
    push hl
    call ti.os.PutStrFull
    pop hl

;print ep file
    ld hl, epFile
    ld a, (hl)
    add a, 'a'
    cp EP_NONE+'a'
    jp nz, .hasEpFile
    ld a, '-'
.hasEpFile:
    ld ix, BoardPrintEpFile
    ld (ix+4), a
    setCursorPos 21, 1
    push ix
    call ti.os.PutStrFull
    pop hl

    setCursorPos 18, 3
    ld hl, BoardPrintCastleLabel
    push hl
    call ti.os.PutStrFull
    pop hl

;print castle flags
    ld ix, BoardPrintCastleFlags
    ld hl, castleFlags
    ld b, (hl)

    bit 0, b
    jp z, .skip_K
    ld (ix), 'K'
    inc ix
.skip_K:
    bit 1, b
    jp z, .skip_Q
    ld (ix), 'Q'
    inc ix
.skip_Q:
    bit 2, b
    jp z, .skip_k
    ld (ix), 'k'
    inc ix
.skip_k:
    bit 3, b
    jp z, .skip_q
    ld (ix), 'q'
    inc ix
.skip_q:
    ld (ix), 0

    setCursorPos 18, 4
    ld hl, BoardPrintCastleFlags
    push hl
    call ti.os.PutStrFull
    pop hl

;print board itself
.loop_rank:
    ld a, 7
    ld (_file), a

    ld de, 0
    push de
    ld hl, _rank
    ld a, 8
    sub a, (hl)
    ld de, 0
    ld e, a
    push de
    call ti.os.SetCursorPos
    pop de
    pop de

    ld hl, _rank
    ld a, (hl)
    add a, 49

    ld ix, BoardPrintPieceLine
    ld (ix), a
    push ix

    add a, -49
    sla a
    sla a
    sla a
    add a, 7
    ld bc, 0
    ld c, a

    ld iy, pieces
    add iy, bc

    ld de, 16
    add ix, de
    ld de, -2
    ld bc, 0
.loop_file:
    ld a, (iy)
    dec iy
    ld hl, PieceToAscii
    ld c, a
    add hl, bc
    ld a, (hl)
    ld (ix), a
    add ix, de

    ld hl, _file
    ld a, (hl)
    dec (hl)
    cp 0
    jp nz, .loop_file

    call ti.os.PutStrLine
    pop de

    ld hl, _rank
    ld a, (hl)
    dec (hl)
    cp 0
    jp nz, .loop_rank

    ret

;********************************************************************************
BoardPrintBlankLine: db "a b c d e f g h", 0
BoardPrintPieceLine: db "8 . . . . . . . .", 0
BoardPrintSideToMove: db "Move: !", 0
BoardPrintEpFile: db "EP: !", 0
BoardPrintCastleLabel: db "Castle:", 0
BoardPrintCastleFlags: db "!!!!", 0
