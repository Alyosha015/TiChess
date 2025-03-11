;expects X in BC, Y in L, Width in D, Height in E, Color in H
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
    ld (iy), H
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
