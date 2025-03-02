Main:
    call ti.RunIndicOff
    di

    SetBpp ti.lcdBpp8
    
    call LCD_Clear

    ld hl, PaletteStart
    ld bc, (PaletteEnd-PaletteStart)/2
    call LCD_LoadPalette

    ld hl, StartPosFen
    call BoardLoad

;registers:
;   BC - x coord (could be done with one byte, but just in case I want the board on the right side)
;   D - ?
;   E - y coord
;   H - x count
;   L - y count

    ld bc, 0
    push bc
    ld de, 0
    ld l, 0
.drawBoardRow:
    pop bc
    push bc
    ld h, 0
.drawBoardSquare:
    push bc
    push de
    push hl

    xor a, a
    add h
    add l
    bit 0, a
    jp nz, .odd
.even:
    ld h, 8
    jp .skipOdd
.odd:
    ld h, 9
.skipOdd:
    ld l, e
    ld d, 30
    ld e, 30
    call FillRect

    pop hl
    pop de
    pop bc

    ld a, c ;BC += 30
    add 30
    ld c, a
    ld a, b
    adc 0
    ld b, a

    inc h
    ld a, h
    cp 8
    jp nz, .drawBoardSquare

    ld a, e
    add 30
    ld e, a

    inc l
    ld a, l
    cp 8
    jp nz, .drawBoardRow

    pop bc ;end draw board

    ld c, 0
;c = loop counter / y coordinate
.drawLoop:
    push bc

    ld l, c
    ld bc, 0
    ld de, 1
    ld ix, TestStr
    call DrawText

    pop bc
    ld a, c
    add a, 9
    ld c, a
    cp a, 26*9
    jp nz, .drawLoop

.waitUntilEnterKey:
    call ti.GetCSC
    cp a, ti.skEnter
    jr nz, .waitUntilEnterKey

;reset everything for OS
    ResetBpp

    call ti.ClrScrn
    call ti.HomeUp
    call ti.DrawStatusBar

    ei
    ret

TestStr:
    db "This is a test to see how fast I can draw text!", 0
    ;db "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuV", 0

StartPosFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0

PaletteStart:
    db 00000000b, 00000000b ; 0 - 0 0 0
    db 11111110b, 11111111b ; 1 - 255 255 255
    db 00000000b, 11111000b ; 2 - 255 0 0
    db 11000000b, 00000111b ; 3 - 0 255 0
    db 00111110b, 00000000b ; 4 - 0 0 255
    db 11000000b, 11111111b ; 5 - 255 255 0
    db 00111110b, 11111000b ; 6 - 255 0 255
    db 11111110b, 00000111b ; 7 - 0 255 255
    db $FE, $41             ; 8 - light blue purple / board white
    db $F4, $20             ; 9 - dark blue purple / board black
PaletteEnd: