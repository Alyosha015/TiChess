; What's a piecelist?
;
; to allow iterating over all of one type piece on the board faster,
; the piece list stores the positions of the pieces in an array indexed
; from 0-n.

;resets all 12 piece lists, since I never need to do it individually anyway.
;doesn't need to be fast.

PieceListResetAll:
    ;preserve registers
    push af
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
	pop af

    ret


;expects pieceList in IX, square to add in C
PieceListAdd:
    ;data[count]=square
    ;lookup[square]=count
    ;count=count+1

    ld b, 0
    ld d, 0

    ld e, (ix+DATA_SIZE)    ;load count
    inc (ix+DATA_SIZE)

    lea hl, ix
    add hl, de
    ld (hl), c              ;data[count]=square

    add ix, bc
    ld (ix+DATA_SIZE+1), e  ;lookup[square]=count

    ret


;expects pieceList in IX, square to remove in C
PieceListRemove:
    ;moves last element in piecelist to removed piece's location
    ;index=lookup[square]
    ;data[index]=data[--count]
    ;lookup[data[index]]=index

    ld b, 0
    ld d, 0

    dec (ix+DATA_SIZE)
    ld e, (ix+DATA_SIZE)    ;load count-1

    lea iy, ix

    add ix, bc
    ld bc, (ix+DATA_SIZE+1) ;index=lookup[square]

    lea hl, iy
    add hl, de
    ld e, (hl)              ;d=data[count-1]

    lea hl, iy
    add hl, bc
    ld (hl), e              ;data[index]=data[count-1]

    add iy, de
    ld (iy+DATA_SIZE+1), c  ;lookup[data[count-1]]=index

    ret


;expects pieceList in IX, start in C, end in E
PieceListMove:
    ;index=lookup[start]
    ;data[index]=end
    ;lookup[end]=index

    ld b, 0
    ld d, 0

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
    PIECE_LIST_RESERVE_BYTES_COUNT := 2 * 6 * (DATA_SIZE + 1 + 64) ;888 B

;allows accessing piece by type and quick iteration.
pieceLists: rb PIECE_LIST_RESERVE_BYTES_COUNT
