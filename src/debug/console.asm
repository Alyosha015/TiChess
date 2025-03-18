    LINE_SIZE := 40
    CONSOLE_DATA_SIZE := LINE_SIZE * 100
ConsoleData: rb CONSOLE_DATA_SIZE
DataPtr: dl ConsoleData ;where to write next line

ConsoleScroll: db 0 ;which line the console is at the bottom (from the top)

ConsoleReDraw: db 0

;expects string pointer in HL. lines can't exceed LINE_SIZE characters (counting 0 terminator).
ConsoleWriteLn:
    pushall

    ld ix, DataPtr ;copy string
    ld de, (ix)
    ld bc, LINE_SIZE
    ldir

    ld hl, (ix) ;update dataPtr
    ld de, LINE_SIZE
    add hl, de
    ld (ix), hl

    ld a, 1
    ld (ConsoleReDraw), a

    popall
    ret

ConsoleClear:
    pushall
    
    ld ix, DataPtr
    ld hl, ConsoleData
    ld (ix), hl

    ld hl, ConsoleData
    ld (hl), 0
    ld de, ConsoleData+1
    ld bc, CONSOLE_DATA_SIZE
    ldir

    xor a
    ld (ConsoleScroll), a

    popall
    ret

ConsoleTick:
    pushall


    ld a, (ConsoleReDraw)
    cp 0
    ret z

    xor a
    ld (ConsoleReDraw), a

    ld hl, DataPtr
    ld hl, (hl)

    ld de, LINE_SIZE
    ld a, (ConsoleScroll)
    ld d, a
    mlt de

    add hl, de

.drawLoop:


    popall
    ret
