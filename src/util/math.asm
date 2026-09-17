U_EQUALDEHL_DE: dl 0
U_EQUALDEHL_HL: dl 0

;****************************************************************
; Util_EqualDEHL - Check if 3-byte values in DE and HL are equal.
;
; INPUT: 
;   DE - value
;   HL - value
; 
; OUTPUT:
;   Set Z flag if equal, reset if not equal.
;
; DESTROYS: A
;****************************************************************
Util_EqualDEHL:
    push ix
    push iy

    ld (U_EQUALDEHL_DE), de
    ld (U_EQUALDEHL_HL), hl

    ld ix, U_EQUALDEHL_DE
    ld iy, U_EQUALDEHL_HL

    ld a, (ix)
    cp (iy)
    jr nz, .exit

    ld a, (ix+1)
    cp (iy+1)
    jr nz, .exit

    ld a, (ix+2)
    cp (iy+2)

.exit:
    pop iy
    pop ix

    ret



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
