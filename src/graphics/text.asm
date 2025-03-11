;expects x (0-319) in BC, y (0-239) in L, FG in D, BG in E, and string pointer in IX
DrawTextLarge:
    push hl
    push de

    ld hl, selected_font_table
    ld de, FONT_LARGE_TABLE
    ld (hl), de

    ld hl, selected_font_spacing
    ld (hl), 2

    pop de
    pop hl

    jp DrawTextSkipLoad

;expects x (0-319) in BC, y (0-239) in L, FG in D, BG in E, and string pointer in IX
DrawText:
    push hl
    push de

    ld hl, selected_font_table
    ld de, FONT_TABLE
    ld (hl), de

    ld hl, selected_font_spacing
    ld (hl), 1

    pop de
    pop hl
DrawTextSkipLoad:
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
    ld de, (selected_font_table)
    add hl, de
    ld ix, (hl) ;store address to sprite

    pop de
    pop hl
    push hl
    push de

    push ix

    call DrawSprite1bpp

    pop iy ;sprite data pointer

    pop de
    pop hl
    pop bc

    ;add sprite width + (selected_font_spacing) to x
    ld ix, 0
    add ix, bc
    ld bc, 0
    ld a, (selected_font_spacing)
    add (iy)
    ld c, a
    add ix, bc
    push ix
    pop bc

    pop ix

    inc ix
    ld a, (ix)
    cp 0
    jp nz, .drawTextLoop

    ret

selected_font_table: rb 3
selected_font_spacing: db 0
