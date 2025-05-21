;divides HL by D.
;doesn't preserve HL, D, A, B
Div24_8:
    xor a
    ld b, 24
.loop:
    add hl, hl
    rl a
    cp d
    jr c, .noSub
    sub d
    inc l
.noSub:
    djnz .loop
    ret
