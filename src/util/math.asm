;divides HL by D.
;doesn't preserve HL, A, B
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

;computes HL % D, expects unsigned numbers.
;doesn't preserve HL, BC, D
Mod24_8:
;X % Y -> X - ((X / Y) * Y)
    push hl ;preserve HL
    call Div24_8
    push hl ;HL -> BC
    pop bc
    ld hl, 0

.loop: ;dumb multiplication algorithm in the meantime
    add hl, bc
    dec d
    ld a, d
    cp 0
    jp nz, .loop

    push hl ;HL -> BC
    pop bc

    pop hl

    sbc hl, bc

    ret
