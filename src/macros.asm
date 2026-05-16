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


    macro pushallexx
        pushall

        ex af, af'  ;alt a start
        push af
        ex af, af'  ;alt a end

        exx ;alt reg start
        push bc
        push de
        push hl
        exx ;alt reg end
    end macro

    macro popallexx
        exx ;alt reg start
        pop hl
        pop de
        pop bc
        exx ;alt reg end

        pop af
        ex af, af'  ;(popped) af to af'

        popall
    end macro
