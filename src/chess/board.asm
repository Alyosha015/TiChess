;handles board representation and make / unmake move functions

    EP_NONE := 15

;Expects pointer to fen string on stack.
BoardLoad:
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

    ;load fen string
    pop de ;return address
    pop hl ;load pointer to string
    push de
    push hl ;copy of pointer for later

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
    jp nc, .loop_skip_0

    ld (iy), c
    inc iy
    inc (ix)

    cp 0
    jp z, .loop_exit_0  ;exit if end of string is reached

    ld a, (ix)          ;exit if already parsed 6 sections.
    cp 6
    jp z, .loop_exit_0
.loop_skip_0:
    inc hl
    inc c
    jp .loop_0
.loop_exit_0:
    ;********************************
    ;testing thingy, prints out all 6 indicies
    ld ix, fenSections

    ;********************************
    ;parse piece position.
    ld bc, 0            ;index (only c is used)
    pop hl              ;load string pointer

;debug thingy, print section indices. Assumes c=0 and b=<number of sections>
    ld ix, fenSections
.DEBUG_print_sections:
    ld de, 0
    push de ;x

    inc bc
    push bc ;y
    dec bc

    call ti.os.SetCursorPos
    pop de
    pop de

    push bc ;preserve bc because of sprintf

    ld de, 0
    ld e, (ix)
    push de
    ld hl, PrintSectionsFormat
    push hl
    ld hl, PrintSectionsBuff
    push hl
    call ti.sprintf
    pop de
    pop de
    pop de
    ; ld hl, 9 ;3 cycles faster for popping 3 values off the stack.
    ; add hl, sp
    ; ld sp, hl

    pop bc

    ld hl, PrintSectionsBuff
    push hl
    call ti.os.PutStrFull
    pop hl

    inc ix
    inc c
    ld a, c
    ld hl, fenSectionsCount
    cp a, (hl)
    jp nz, .DEBUG_print_sections

.loop_1:
    ; ld a, (hl)          ;load character



    ; inc hl
    ; inc c
    ; ld a, c
    ; cp e
    ; jp nz, .loop_1


    ; ;early return in case of incomplete fen string.
    ; ld a, e
    ; cp 2
    ; ret c

    ret

BoardMakeMove:

    ret


BoardUnmakeMove:

    ret

;********************************************************************************

PrintSectionsBuff: rb 10
PrintSectionsFormat: db "%d", 0

_rank: db 0
_file: db 0

;******** Board State ********
whiteToMove: db 0

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

;******** Board Piece Representation ********

;allows accessing piece by square
pieces: rb 64

;****************
;used by fen loader in BoardLoad

fenSections: rb 6

fenSectionsCount: db 0
