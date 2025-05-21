;expects X in BC, Y in L, Width in D, Height in E, Color in H
;preserves IX
FillRect:
    push hl
    push de
    ld de, 0
    ld e, l
    CalcScreenIndex
    ld de, LCD_VRAM
    add hl, de ;vram index
    push hl
    pop iy

    pop de
    ld bc, 320
    ld a, c
    sub d
    ld c, a
    ld a, b
    sbc 0
    ld b, a
    push bc
    exx ;alt reg start
    pop de
    exx ;alt reg end

    pop hl

;registers:
;   IY - VRAM
;   D - width
;   E - height
;   B - x counter
;   C - y counter
;   H - color
;   L - none
;alt registers:
;   DE - IY offset for next row (320-width)
    ld c, 0
.drawRow:
    ld b, 0
.drawPixel:
    ld (iy), h
    inc iy

    inc b
    ld a, b
    cp d
    jp nz, .drawPixel

    exx ;alt reg begin
    add iy, de
    exx ;alt reg end

    inc c
    ld a, c
    cp e
    jp nz, .drawRow

    ret

;draws rectangle with thickness of 1 pixel.
;expects X in BC, Y in L, Width in D, Height in E, Color in H.
;preserves nothing (except shadow registers).
DrawRect:
    dec d
    dec e
    push de
    push hl
    ld de, 0
    ld e, l
    CalcScreenIndex
    ld de, LCD_VRAM
    add hl, de ;vram index
    push hl
    pop iy

    pop hl
    pop de

    push iy ;preserve IY

    ld bc, 0
    ld c, d
    lea ix, iy
    add ix, bc
    ld bc, 320
    ld l, 0
    dec e
.colLoop:
    add iy, bc
    add ix, bc

    ld (iy), h
    ld (ix), h

    inc l
    ld a, l
    cp e
    jp nz, .colLoop

    add iy, bc
    pop ix ;restore IY (into IX)
    ld l, 0
.rowLoop:
    ld (iy), h
    ld (ix), h

    inc iy
    inc ix

    inc l
    ld a, l
    cp d
    jp nz, .rowLoop

    ld (iy), h
    ld (ix), h

    ret
