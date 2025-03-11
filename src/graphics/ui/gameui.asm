gameui_DrawBoard:
;registers:
;   BC - x coord (could be done with one byte, but just in case I want the board on the right side I wont)
;   D - ?
;   E - y coord
;   H - x count
;   L - y count

    ld bc, 0
    push bc
    ld de, 0
    ld l, 0
.drawBoardRow:
    pop bc
    push bc
    ld h, 0
.drawBoardSquare:
    push bc
    push de
    push hl

    xor a, a
    add h
    add l
    bit 0, a
    jp nz, .odd
.even:
    ld h, 9
    jp .skipOdd
.odd:
    ld h, 10
.skipOdd:
    ld l, e
    ld d, 30
    ld e, 30
    call FillRect

    pop hl
    pop de
    pop bc

    ld a, c ;BC += 30
    add 30
    ld c, a
    ld a, b
    adc 0
    ld b, a

    inc h
    ld a, h
    cp 8
    jp nz, .drawBoardSquare

    ld a, e
    add 30
    ld e, a

    inc l
    ld a, l
    cp 8
    jp nz, .drawBoardRow

    pop bc ;end draw board

    ret

GameUiInit:
    ld hl, PaletteStart
    ld bc, (PaletteEnd-PaletteStart)/2
    call LCD_LoadPalette

    call FontLoadLarge

    call gameui_DrawBoard

    ld bc, 0
    ld l, 0
    ld d, 2
    ld e, 0
    ld ix, LText
    call DrawTextLarge

    ld bc, 0
    ld l, 20
    ld d, 2
    ld e, 0
    ld ix, SText
    call DrawText

    ret

GameUiTick:

    ret

LText: db "2x Scale Large Text!", 0
SText: db "Normal Scale Small Text!", 0
