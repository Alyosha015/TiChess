;Moves Struct:
; -2    = allocation index
; -1    = move count
; 0-653 = 218 3-byte moves
;
;Move format (could be done in 2 bytes, but for speed I'll use 3):
; 0 - move start square
; 1 - move end square
; 2 - special move flag
;
;Memory Note:
;I'm using an area with ~44k of memory usually used by the graphing
;screen (I think) to store each move struct. See 'plotSScreen' in include\ti84pceg.inc
;I also need to set the graphDraw flag if I do this. (again see the file).

    MAX_MOVES := 218
    MOVES_STRUCT_SIZE := MAX_MOVES * 3 + 2

    HEAP_START := ti.plotSScreen

;stores pointer to moves struct in IX, 0 if none if found
;note that the move count / data won't be 0'd.
;preserves registers
AllocMoves:
    push af
    push iy
    push bc
    push de

;registers:
;   IX - address of current struct
;   IY - address of current block in lookup
;   B  - ?
;   C  - counter
;   DE - constant offset for IX by struct size

    ld ix, HEAP_START
    ld iy, heap_allocTable

    ld de, MOVES_STRUCT_SIZE

    ld c, 0
.findFreeBlockLoop:
    ld a, (iy)
    cp 0
    jp z, .foundEmpty

    add ix, de

    inc iy

    inc c
    ld a, c
    cp MAX_MOVES_STRUCTS
    jp nz, .findFreeBlockLoop
    ;this part runs if no open space is found
    ld ix, 0
    jp .exit

.foundEmpty:
    ld (iy), 1
    ld (ix), c
    inc ix
    inc ix

.exit:
    pop de
    pop bc
    pop iy
    pop af

    ret

;expects pointer to moves struct in IX
;preserves registers
FreeMoves:
    push af
    push hl
    push de

    ld hl, heap_allocTable
    ld de, 0
    ld e, (ix-2)
    add hl, de
    ld (hl), 0

    pop de
    pop hl
    pop af

    ret

;********************************

    HEAP_SIZE := 16384
    MAX_MOVES_STRUCTS := HEAP_SIZE / MOVES_STRUCT_SIZE

heap_allocTable: rb MAX_MOVES_STRUCTS
