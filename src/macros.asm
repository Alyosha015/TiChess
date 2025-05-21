;effects register DE
macro setCursorPos x, y
    ld de, x
    push de
    ld de, y
    push de
    call ti.os.SetCursorPos
    pop de
    pop de
end macro

macro print string, x, y
    setCursor x y

    ld hl, string
    push hl
    call ti.os.PutStrFull
    pop hl
end macro

macro txt string, x, y
    pushall
    ld ix, string
    ld d, 2
    ld e, 0
    ld l, y
    ld bc, x
    call DrawText
    popall
end macro

macro pushall
    push af
    push bc
    push de
    push hl
    push ix
    push iy
end macro

macro popall
    pop iy
    pop ix
    pop hl
    pop de
    pop bc
    pop af
end macro

macro SetBpp bpp
    ld a, bpp
    ld (ti.mpLcdCtrl), a
end macro

macro ResetBpp
    SetBpp ti.lcdBpp16
end macro

;assumes x coordinate is stored in BC, y in DE, and stores result in HL.
;equivalent to HL = DE * 320 + BC
macro CalcScreenIndex
    ld hl, 0
    ld h, 64
    ld l, e

    mlt hl

    add hl, bc

    ld d, e
    ld e, 0
    add hl, de
end macro

;convert a RGB555 color into a two byte DB command
macro COLOR555 red, green, blue
    ;gggbbbbb 0rrrrrgg
    db (((green) shl 5) and 11100000b) + ((blue) and 00011111b), (((red) shl 2) and 01111100b) + (((green) shr 3) and 11b)
end macro

;convert a RGB888 into a two byte RGB555 color as a DB command
macro COLOR888 r, g, b
    COLOR555 ((r)/8), ((g)/8), ((b)/8)
end macro