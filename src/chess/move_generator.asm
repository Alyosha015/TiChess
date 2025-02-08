;something to think about: the max number of moves is 218, this comes out
;to 437 bytes per Moves struct on the stack. Usually this isn't a problem,
;but I only have a 4KB stack.

;Moves Struct:
; 0-435 = 218 2-byte moves
; 437   = move count

    MAX_MOVES := 218
    MOVES_STRUCT_SIZE := MAX_MOVES * 2 + 1

GenerateMoves:
    pop de ;return address
    pop iy ;struct pointer

    push de

    ;******** Move Gen Init ********

    ;testing stuff
    ;increment move count
    ld de, MOVES_STRUCT_SIZE-1
    add iy, de
    inc (iy)

    ret