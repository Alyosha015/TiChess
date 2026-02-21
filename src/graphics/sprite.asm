;Sprite Data format:
; 0: Width
; 1: Height
; 2: XOffset
; 3: YOffset
; 4-6: YOffset * 320 + XOffset
; 7-n: Image data, either 1bbp or 8bpp (type not stored).
;
;Types of sprites:
;
; 1. 1 bpp - mainly text. Only has a fg and bg color.
; 2. 8 bpp - fastest to draw, essentially a memory copy.

;expects X in BC, Y in DE, FG in H, BG in L, and sprite pointer in IX.
;if one of the colors is 0 it's drawn transparently.
;LD DE, COLOR_FG * 256 + COLOR_BG
;no registers are preserved.
GFX_Sprite1Bpp:
    ;register data:
    ;   IX - sprite data
    ;   IY - vram pointer
    ;   B - number of col (sprite width)
    ;   C - col counter (counts to 0, unlike row counter)
    ;   D - FG Color
    ;   E - BG Color
    ;   H - number of bits to draw (1-8)
    ;   L - byte to draw
    ;
    ;shadow registers:
    ;   B - number of rows (sprite height)
    ;   C - row counter (from 0)
    ;   DE - constant [320-WIDTH] (used to move vram pointer to next row)
    ;   H - n/a
    ;   L - n/a

    ld a, (ix+1) ;early return if 0 height (such as the space character)
    cp 0
    ret z

    push hl ;preserve color

    GFX_ScreenIndex ;HL = 320 * DE + BC
    ld de, (ix+4) ;add sprite offset
    add hl, de
    ld de, (LCD_DrawBuffer) ;add vram start offset
    add hl, de

    push hl
    pop iy

    exx ;alt reg start
    ld bc, 0 ;calculate DE = 320 - (IX), where (IX) is sprite width.
    ld c, (ix)
    xor a
    ld hl, 320
    sbc hl, bc
    ex de, hl

    ld b, (ix+1) ;load number of rows / init row counter
    ld c, 0
    exx ;alt reg end

    ld b, (ix) ;load sprite width

    ld de, 7 ;shift sprite pointer so (ix) is now the start of data section
    add ix, de

    pop de ;restore color data

.drawRow:
    ld c, b ;reset x remaining counter
            ;note that it will count from the width towards 0.
            ;this makes it easier to determine if a full byte
            ;of data still has to be drawn, or a partial one.
.drawCol: ;loop back here for every byte to draw
    ld h, 8 ;reset bits to draw counter

    ld l, (ix) ;get byte to draw
    inc ix

    ld a, c
    cp 8
    jp nc, .skipPartialByte ;not less than
    ld h, c ;set bits to draw to smaller number.
.skipPartialByte:
    ld a, c ;update pixels left to draw counter
    sub h
    ld c, a

.drawBit:
    bit 7, l ;left-most bit. z set to 1 if 0
    jp z, .setBg
.setFg:
    ld a, d ;fg color
    jp .finishSetColor
.setBg:
    ld a, e ;bg color
.finishSetColor:
    cp 0    ;color 0 is considered transparent
    jp z, .skipDrawPixel

    ld (iy), a
.skipDrawPixel:
    inc iy

    sla l ;shift data to draw byte to next pixel is in the upper bit.

    dec h
    ld a, h
    cp 0
    jp nz, .drawBit

    ld a, c
    cp 0
    jp nz, .drawCol

    exx ;alt reg start
    add iy, de ;move vram pointer to first byte of next row

    inc c
    ld a, c
    cp b
    exx ;alt reg end
    jp nz, .drawRow

    ret

;x in bc, y in l, fg in d, bg in e, sprite pointer ix.
DrawSprite1bpp:
    ;old code in scratchpad/
ret