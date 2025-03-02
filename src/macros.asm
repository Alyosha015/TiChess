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
    call ti.ClrScrnFull
end macro

;assumes x coordinate is stored in BC, y in DE, and stores result in HL.
;equivalent to HL = DE * 320 + BC
macro CalcVramIndex
    ld hl, 0
    add hl, de
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, bc
    ld d, e
    ld e, 0
    add hl, de
end macro