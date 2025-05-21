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

;expects X in BC, Y in L, FG in D, BG in E, and sprite pointer in IX.
;if color is 0 it's drawn transparently.
DrawSprite1bpp:
    ld a, (ix+1) ;don't draw if height is 0
    cp 0
    ret z

    ;load alternate register data
    push de
    exx ;alt reg start
    pop hl
    ld bc, 0
    ld b, (ix+1)
    exx ;alt reg end

    ld de, 0
    ld e, l
    CalcScreenIndex ;expects x in BC and y in DE. Stores in HL.
    ld de, LCD_VRAM
    add hl, de
    ld de, (ix+4) ;add sprite position offset
    add hl, de
    push hl
    pop iy ;vram address

    ld bc, 0
    ld c, (ix)
    ld de, 320
    ld a, e
    sub c
    ld e, a
    ld a, d
    sbc b
    ld d, a
    push de
    exx ;alt reg begin
    pop de
    exx ;alt reg end

    ld de, 7
    add ix, de
    ld de, 0

    ;registers:
    ;   IX = sprite-data pointer
    ;   IY = vram pointer
    ;   B = ?
    ;   C = width
    ;   D = width counter
    ;   E = current byte being drawn
    ;   H = number of bits to draw
    ;   L = bit drawn counter
    ;
    ;shadow registers:
    ;   B = height
    ;   C = height counter
    ;   DE = IY adjust const (320-width)
    ;   H = FG color
    ;   L = BG color

.drawRow:
    ld d, c
.drawByte:
    ld l, 0
    ld e, (ix)
    inc ix
    ld a, d
    cp 8
    jp c, .lessThan8px
    ld h, 8
    ld a, d
    sub 8
    ld d, a
    jp .skipLessThan8px
.lessThan8px:
    ld h, d
    ld d, 0
.skipLessThan8px:
.drawPixel:
    bit 7, e
    exx ;alt reg start
    jp z, .isBG
    ld a, h
    jp .draw
.isBG:
    ld a, l
.draw:
    exx ;alt reg end
    cp 0
    jp z, .skipDraw
    ld (iy), a
.skipDraw:
    inc iy

    sla e
    inc l
    ld a, l
    cp h
    jp nz, .drawPixel

    ld a, d
    cp 0
    jp nz, .drawByte

    exx ;alt reg start
    add iy, de

    inc c
    ld a, c
    cp b
    exx ;alt reg end
    jp nz, .drawRow

    ret

; ;expects X in BC, Y in L, FG in D, BG in E, and sprite pointer in IX.
; ;if color is 0 it's drawn transparently.
; DrawSprite8bpp:
;     ld a, (ix+1) ;don't draw if height is 0
;     cp 0
;     ret z

;     ld de, 0
;     ld e, l
;     CalcScreenIndex ;expects x in BC and y in DE. Stores in HL.
;     ld de, LCD_VRAM
;     add hl, de
;     ld de, (ix+4) ;add sprite position offset
;     add hl, de
;     push hl
;     pop iy ;vram address
    
; .drawRow:

;     exx ;alt reg start

;     exx ;alt reg end

;     ret
