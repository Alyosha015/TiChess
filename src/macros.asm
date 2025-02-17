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
