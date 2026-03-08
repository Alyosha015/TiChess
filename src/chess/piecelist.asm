;****************************************************************
; What's a piecelist?
;
; To allow iterating over all of one type piece on the board faster,
; the piece list stores the positions of the pieces in an array indexed
; from 0-n.
;
; To be able to add and remove pieces from the array, each piecelist
; also has a lookup table to convert from board index to array index.
;
;****************************************************************
;
; Note that these functions don't have any checks for moving/removing
; pieces which don't exist.
;
;****************************************************************

;Piece List memory usage:
;9 bytes for data (starting queen + 8 possible promotions)
;1 byte for piece count
;64 bytes for lookup

PL_DATA_SIZE := 9                                           ;limit for number of pieces that can be stored
PL_RESERVE_BYTE_COUNT := PL_DATA_SIZE + 1 + 64              ;size of single piecelist
PL_RESERVE_TOTAL_BYTE_COUNT := PL_RESERVE_BYTE_COUNT * 12   ;size of all piecelists

;Size of lookup table which can be indexed by (piece) * 3 or (color * 8 + pieceType) * 3
;Essentially like this:
; plTable:
; plTableBlack:
;     dl 0    ;color 0, type 0
;     dl pl_king
;     dl pl_queen
;     dl pl_rook
;     dl pl_bishop
;     dl pl_knight
;     dl pl_pawn
;     dl 0    ;color 0, type 7
; plTableWhite:
;     dl 0    ;color 1, type 0
;     dl pl_King
;     dl pl_Queen
;     dl pl_Rook
;     dl pl_Bishop
;     dl pl_Knight
;     dl pl_Pawn

PL_LUT_BLACK_SIZE := 3 + 3*6 + 3
PL_LUT_WHITE_SIZE := 3 + 3*6

;****************************************************************
; PL_Init - Creates LUT table for piecelists.
;****************************************************************
PL_Init:
    ld ix, PL_Table
    ld iy, PL_Black + 3 ;account for 3 bytes of 0 padding
    call _PL_InitSideLUT

    ld ix, PL_Table + PL_RESERVE_BYTE_COUNT * 6    ;accounts for black piecelists
    ld iy, PL_White + 3
    call _PL_InitSideLUT

    ret

;****************************************************************
; _PL_InitSideLUT - used to create piecelist lut for one color of
;   pieces.
;
; INPUTS:
;   IX - piecelist data start address
;   IY - LUT first entry start address
;
; DESTROYS:
;   IX, IY, A
;
;****************************************************************
_PL_InitSideLUT:
    ld de, PL_RESERVE_BYTE_COUNT
    ld bc, 3

    ld a, 6
.loop:
    ld (iy), ix

    add ix, de  ; IX += PL_RESERVE_BYTES_COUNT
    add iy, bc  ; IY += 3

    dec a
    jr nz, .loop

    ret

;****************************************************************
; PL_ResetAll - Zeros all 12 pieclists.
;
; INPUTS: NONE
;
; DESTROYS: NONE
;
;****************************************************************
PL_ResetAll:
    push bc ;preserve registers
    push de
    push hl

    ld hl, PL_Data
    ld (hl), 0
    ld de, PL_Data + 1
    ld bc, PL_RESERVE_TOTAL_BYTE_COUNT - 1
    ldir

    pop hl  ;restore registers
    pop de
    pop bc

    ret

;****************************************************************
; PL_Add - Add piece to selected square of piecelist.
;
; INPUTS:
;   IX - piecelist
;   DE - board index for piece
;
; DESTROYS:
;   IX, HL, DE, BC
;
;****************************************************************
PL_Add:
    ; data[count] = square
    ; lookup[square] = count
    ; count = count + 1

    ld bc, 0

    ld c, (ix + PL_DATA_SIZE)
    inc (ix + PL_DATA_SIZE)     ;count++

    lea hl, ix                  ;data[count] = square
    add hl, bc
    ld (hl), e

    add ix, de                  ;lookup[square] = count
    ld (ix + PL_DATA_SIZE + 1), c

    ret

;****************************************************************
; PL_Remove - Remove piece at selected square of piecelist.
;
; INPUTS:
;   IX - piecelist
;   DE - board index to remove
;
; DESTROYS:
;   IX, IY, HL, DE, BC
;
;****************************************************************
PL_Remove:
    ; index = lookup[square]
    ; data[index] = data[--count]   //move last piece added to entry to be removed (keeps list continious)
    ; lookup[data[index]] = index   //update lookup for last piece added

    dec (ix + PL_DATA_SIZE)     ;decrement count

    ld bc, 0                    ;load (count - 1)
    ld c, (ix + PL_DATA_SIZE)

    lea hl, ix                  ;copy piecelist pointer

    add hl, bc                  ;load data[count - 1]
    ld c, (hl)

    lea iy, ix                  ;copy piecelist pointer
    lea hl, ix

    add ix, de                  ;load index = lookup[square]
    ld e, (ix + PL_DATA_SIZE + 1)

    add hl, de                  ;data[index] = data[count - 1]
    ld (hl), c

    add iy, bc                  ;calculate lookup[data[index]]
    ld (iy + PL_DATA_SIZE + 1), e

    ret

;****************************************************************
; PL_Move - Updates position of piece.
;
; INPUTS:
;   IX - piecelist
;   DE - position
;   BC - new position
;
; DESTROYS:
;   IX, IY, HL, DE, BC
;
;****************************************************************
PL_Move:
    ; index = lookup[start]
    ; data[index] = end
    ; lookup[end] = index

    lea iy, ix                  ;copy

    add iy, de                  ;index = lookup[position]
    ld e, (iy + PL_DATA_SIZE + 1)

    lea hl, ix                  ;data[index] = end
    add hl, de
    ld (hl), c

    add ix, bc                  ;lookup[end] = index
    ld (ix + PL_DATA_SIZE + 1), e

    ret
