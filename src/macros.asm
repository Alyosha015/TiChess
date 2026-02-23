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
