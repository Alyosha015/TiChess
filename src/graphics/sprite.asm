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

;************************************************
; GFX_Sprite1BppFast - GFX_Sprite1Bpp but without XY coordinate -> VRAM calculation.
;
; INPUTS:
;   IX  = Sprite Data Pointer
;   BC  = n/a
;   D   = Foreground Color
;   E   = Background Color
;   HL  = VRAM Offset (320 * x + y)
;
; PRESERVES:
;   NONE
;
;************************************************
GFX_Sprite1BppFast:
    ld a, (ix+1) ;early return if 0 height (such as the space character)
    or a
    ret z

    push de ;preserve color

    jr __GFX_Sprite1Bpp_PostScreenIndexCalc

;************************************************
; GFX_Sprite1Bpp - Draw sprite in 1bbp format.
;
; INPUTS:
;   IX  = Sprite Data Pointer
;   BC  = X coordinate
;   DE  = Y coordinate
;   H   = Foreground Color
;   L   = Background Color
;
; PRESERVES:
;   NONE
;
;************************************************
GFX_Sprite1Bpp:
    ;register data:
    ;   IX - sprite data
    ;   IY - vram pointer
    ;   B - number of columns (sprite width)
    ;   C - column counter (counts to 0)
    ;   D - FG Color
    ;   E - BG Color
    ;   H - number of bits to draw (1-8)
    ;   L - byte to draw
    ;
    ;shadow registers:
    ;   B - temp
    ;   C - row counter (sprite height, counts to 0)
    ;   DE - constant [320-WIDTH] (used to move vram pointer to next row)
    ;   HL - temp

    ld a, (ix+1) ;early return if 0 height (such as the space character)
    or a
    ret z

    push hl ;preserve color

    GFX_ScreenIndex ;HL = 320 * DE + BC
__GFX_Sprite1Bpp_PostScreenIndexCalc:
    ld de, (ix+4) ;add sprite offset
    add hl, de
    ld de, (LCD_DrawBuffer) ;add vram start offset
    add hl, de

    push hl
    pop iy

    exx ;alt reg start
    ld bc, 0        ;calculate DE = 320 - (IX), where (IX) is sprite width.
    ld c, (ix)
    xor a
    ld hl, 320
    sbc hl, bc
    ex de, hl

    ld c, (ix+1)    ;load number of rows
    exx ;alt reg end

    ld b, (ix) ;load sprite width

    lea ix, ix+7 ;shift sprite pointer so (ix) is now the start of data section

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
    jr nc, .skipPartialByte ;not less than
    ld h, c ;set bits to draw to smaller number.
.skipPartialByte:
    ld a, c ;update pixels left to draw counter
    sub h
    ld c, a

.drawBit:
    bit 7, l ;left-most bit. z set to 1 if 0
    jr z, .setBg
.setFg:
    ld a, d ;fg color
    jr .finishSetColor
.setBg:
    ld a, e ;bg color
.finishSetColor:
    or a    ;color 0 is considered transparent
    jr z, .skipDrawPixel

    ld (iy), a
.skipDrawPixel:
    inc iy

    sla l ;shift next bit to draw into 7th bit.

    dec h
    ld a, h
    or a
    jr nz, .drawBit

    ld a, c
    or a
    jr nz, .drawCol

    exx ;alt reg start
    add iy, de ;move vram pointer to first byte of next row

    dec c
    exx ;alt reg end
    jr nz, .drawRow

    ret
