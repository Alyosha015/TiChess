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
;I'm using an area with ~69k of memory usually used by the graphing
;screen store each move struct. See 'pixelShadow' in include\ti84pceg.inc
;I also need to set the graphDraw flag if I do this. (again see the file).

    MAX_MOVES := 218
    MOVES_STRUCT_SIZE := MAX_MOVES * 3 + 2

;stores pointer to moves struct in IX, 0 if none if found
;preserves registers
AllocMoves:
    push iy
    push bc
    push de

;registers:
;   IX - address of current struct
;   IY - address of current block in lookup
;   B  - number of structs to check
;   C  - counter
;   DE - constant offset for IX by struct size

    ld ix, heap_start
    ld iy, allocated_moves_structs

    ld de, MOVES_STRUCT_SIZE

    ld bc, 0
    ld b, MAX_MOVES_STRUCTS
.findFreeBlockLoop:
    ld a, (iy)
    cp 0
    jp z, .foundEmpty

    add ix, de

    inc iy

    inc c
    ld a, c
    cp b
    jp nz, .findFreeBlockLoop
    ;this part runs if no open space is found
    ld ix, 0
    jp .exit

.foundEmpty:
    ld (iy), 1

    inc ix
    inc ix

.exit:
    pop de
    pop bc
    pop iy

    ret

;expects pointer to moves struct in IX
;preserves registers
FreeMoves:
    push hl
    push de

    ld hl, allocated_moves_structs
    ld de, 0
    ld e, (ix-2)
    add hl, de
    ld (hl), 0

    pop de
    pop hl

    ret

;********************************

    HEAP_SIZE := 16384
    MAX_MOVES_STRUCTS := HEAP_SIZE / MOVES_STRUCT_SIZE

heap_start: dl ti.pixelShadow
allocated_moves_structs: rb MAX_MOVES_STRUCTS
