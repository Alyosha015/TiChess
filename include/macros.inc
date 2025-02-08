macro print? string, x, y
    ld bc, x
    push bc
    ld bc, y
    push bc
    call ti.os.SetCursorPos
    pop bc
    pop bc

    ld hl, string
    push hl
    call ti.os.PutStrFull
    pop hl
end macro
