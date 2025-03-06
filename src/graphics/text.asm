;expects x (0-319) in BC, y (0-239) in L, FG in D, BG in E, and string pointer in IX
DrawText:
.drawTextLoop:
    push ix ;preserve str ptr
    push bc ;x
    push hl ;y
    push de ;bg/fg

    ld a, (ix)
    sub 32
    ld hl, 0
    ld l, a
    ld h, 3
    mlt hl
    ld de, FONT_TABLE
    add hl, de
    ld ix, (hl) ;store address to sprite

    pop de
    pop hl
    push hl
    push de

    push ix

    call DrawSprite1bpp

    pop iy

    pop de
    pop hl
    pop bc

    ld ix, 0
    add ix, bc
    ld bc, 0
    ld c, (iy)
    inc c
    add ix, bc
    push ix
    pop bc

    pop ix

    inc ix
    ld a, (ix)
    cp 0
    jp nz, .drawTextLoop

    ret
