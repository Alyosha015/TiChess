; What's a piecelist?
;
; to allow iterating over all of one type piece on the board faster,
; the piece list stores the positions of the pieces in an array indexed
; from 0-n.

;note that these functions might be called while using the shadow register set.

;resets all 12 piece lists, since I never need to do it individually anyway.
;doesn't need to be fast.
PieceListResetAll:
    ;preserve registers
    push bc
    push de
    push hl

    ld hl, pieceLists
    ld (hl), 0
    ld de, pieceLists + 1
    ld bc, PIECE_LIST_RESERVE_BYTES_COUNT - 1
    ldir

    ;restore registers
    pop hl
    pop de
    pop bc

    ret


;expects pieceList in IX, square index to add in BC
PieceListAdd:
    ;data[count]=square
    ;lookup[square]=count
    ;count=count+1

    ld de, 0

    ld e, (ix+DATA_SIZE)    ;load count
    inc (ix+DATA_SIZE)

    push ix
    pop hl
    ;lea hl, ix
    add hl, de
    ld (hl), c              ;data[count]=square

    add ix, bc
    ld (ix+DATA_SIZE+1), e  ;lookup[square]=count

    ret


;expects pieceList in IX, square to remove in BC
PieceListRemove:
    ;moves last element in piecelist to removed piece's location
    ;index=lookup[square]
    ;data[index]=data[--count]
    ;lookup[data[index]]=index

    ld de, 0

    dec (ix+DATA_SIZE)
    ld e, (ix+DATA_SIZE)    ;load count-1

    lea iy, ix

    add ix, bc
    ld c, (ix+DATA_SIZE+1) ;index=lookup[square]

    lea hl, iy
    add hl, de
    ld e, (hl)              ;d=data[count-1]

    lea hl, iy
    add hl, bc
    ld (hl), e              ;data[index]=data[count-1]

    add iy, de
    ld (iy+DATA_SIZE+1), c  ;lookup[data[count-1]]=index

    ret


;expects pieceList in IX, start in BC, end in DE
PieceListMove:
    ;index=lookup[start]
    ;data[index]=end
    ;lookup[end]=index

    lea iy, ix

    add ix, bc
    ld bc, (ix+DATA_SIZE+1) ;index=lookup[square]

    lea hl, iy
    add hl, bc
    ld (hl), e              ;data[index]=end

    add iy, de
    ld (iy+DATA_SIZE+1), c  ;lookup[end]=index

    ret

;********************************************************************************

;Piece List memory usage:
;9 bytes for data (starting queen + 8 possible promotions)
;1 byte for piece count
;64 bytes for lookup

    DATA_SIZE := 9
    PIECE_LIST_RESERVE_BYTES_COUNT := DATA_SIZE + 1 + 64

pieceLists:
pl_black:
pl_k: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_q: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_r: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_b: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_n: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_p: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_white:
pl_K: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_Q: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_R: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_B: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_N: rb PIECE_LIST_RESERVE_BYTES_COUNT
pl_P: rb PIECE_LIST_RESERVE_BYTES_COUNT

;stores address to each piecelist.
;Index with '(color * 8 + type) * 3' or just '(piece) * 3'
plTable:
plTableBlack:
    dl 0    ;color 0, type 0
    dl pl_k
    dl pl_q
    dl pl_r
    dl pl_b
    dl pl_n
    dl pl_p
    dl 0    ;color 0, type 7
plTableWhite:
    dl 0    ;color 1, type 0
    dl pl_K
    dl pl_Q
    dl pl_R
    dl pl_B
    dl pl_N
    dl pl_P
