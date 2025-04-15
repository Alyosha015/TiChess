;creates sprite definitions and fills lookup table for font at
;2x scale, doing it at runtime this way to keep the program size down.
;uses memory starting from ti.pixelShadow.
;doesn't preserve registers
FontLoadLarge:
    ;IX - sprite source
    ;IY - destination

    ld hl, font_tbl_ptr
    ld de, FONT_LARGE_TABLE
    ld (hl), de

    ld iy, ti.pixelShadow
    ld ix, FONT_CHAR_32

    ;registers:
    ;   C - counter
    ld c, 0
.spriteLoadLoop:
    push bc

    call FontLoadLarge_LdSprite

    pop bc
    inc c
    ld a, c
    cp 95
    jp nz, .spriteLoadLoop

    ret

font_tbl_ptr: rb 3

;expects IX and IY filled
FontLoadLarge_LdSprite:
    ;registers:
    ;   B - source width
    ;   C - source height
    ;   IX - sprite source
    ;   IY - destination
;add jumptable entry
    ld hl, (font_tbl_ptr)
    ld (hl), iy
    ld de, 3
    add hl, de
    ld (font_tbl_ptr), hl

;load width / height
    ld b, (ix) ;w
    ld c, (ix+1) ;h

    ld d, b
    sla d
    ld (iy), d

    ld d, c
    sla d
    ld (iy+1), d

;load offsets
    push bc ;store w/h

    ld bc, 0
    ld de, 0

    ld c, (ix+2) ;x
    sla c
    ld (iy+2), c

    ld e, (ix+3) ;y
    sla e
    ld (iy+3), e

    CalcScreenIndex

    ld (iy+4), hl

    ld de, 7
    add ix, de
    add iy, de

    pop bc ;restore w/h

    ld a, c
    cp 0
    ret z

;load sprite bitmap
    ;registers:
    ;   B - temp data
    ;   C - width
    ;   D - width counter
    ;   E - current byte being drawn
    ;   H - number of bits to draw
    ;   L - bit drawn counter
    ;   IX - sprite source
    ;   IY - destination
    ;
    ;shadow registers:
    ;   B - source height
    ;   C - height counter
    ;   DE - ?
    ;   HL - ?
    push bc
    exx ;alt start
    pop bc
    ld b, c
    ld c, 0
    exx ;alt end

    ld c, b
    ld de, 0
.loadRow:
    ld d, c
.loadByte:
    ld (iy), 0 ;just in case
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
.loadPixel:
;destination byte has to be incremented halfway through.
    ld a, l
    cp 4
    jp z, .incDstAddr
    jp .skipIncDstAddr
.incDstAddr:
    inc iy
    ld (iy), 0
.skipIncDstAddr:
    bit 7, e
    jp nz, .is1
    jp .skipIs1
.is1:
    push hl
    exx ;alt reg start
    pop hl
    ld de, 0
    ld e, l
    ld hl, FONT2X_COPY_LUT
    add hl, de
    ld a, (hl)
    exx ;alt reg end

    ld b, a
    ld a, (iy)
    or b
    ld (iy), a
.skipIs1:
    sla e

    inc l
    ld a, l
    cp h
    jp nz, .loadPixel

    inc iy
    ld a, d
    cp 0
    jp nz, .loadByte

    ld a, c ;get number of bytes in row
    add 3
    srl a
    srl a

    exx ;alt reg start

    push bc

    ld bc, 0
    ld c, a

    lea hl, iy ;source
    xor a
    sbc hl, bc
    
    lea de, iy ;dest

    add iy, bc

    ldir

    pop bc

    inc c
    ld a, c
    cp b
    exx ;alt reg end
    jp nz, .loadRow

    ret

;filled 2x scale pixels, indexed by current bit being read.
FONT2X_COPY_LUT:
    db 11000000b, 00110000b, 00001100b, 00000011b
    db 11000000b, 00110000b, 00001100b, 00000011b

;get width of text string in pixels using 2X font.
;result stored in BC. Preserves all registers except BC.
LargeTextRenderSize:
    call TextRenderSize

    push hl
    push bc
    pop hl
    add hl, hl
    push hl
    pop bc
    pop hl

    ret

;get width of text string in pixels.
;result stored in BC. Preserves all registers except BC.
TextRenderSize:
    push ix
    push de
    push hl

;registers:
;   BC - size
;   DE - temp
;   HL - temp
;   IX - str pointer
    
    ld de, 0
    ld bc, 0
.textLoop:
    ld a, (ix)
    sub 32
    
    ld d, 3
    ld e, a
    ld hl, FONT_TABLE
    mlt de
    add hl, de

    ld hl, (hl) ;now has sprite data ptr

    ld a, (hl) ;add sprite width

    add c
    ld c, a
    ld a, b
    adc 0
    ld b, a

    inc ix
    ld a, (ix)
    cp 0
    jp nz, .textLoop

    ld hl, -1 ;decrement by 1 since the last character doesn't need a empty line after it.
    add hl, bc
    push hl
    pop bc

    pop hl
    pop de
    pop ix

    ret

;expects x (0-319) in BC, y (0-239) in L, FG in D, BG in E, and string pointer in IX
DrawTextLarge:
    push hl
    push de

    ld hl, selected_font_table
    ld de, FONT_LARGE_TABLE
    ld (hl), de

    ld hl, selected_font_spacing
    ld (hl), 2

    pop de
    pop hl

    jp DrawTextSkipLoad

;expects x (0-319) in BC, y (0-239) in L, FG in D, BG in E, and string pointer in IX
DrawText:
    push hl
    push de

    ld hl, selected_font_table
    ld de, FONT_TABLE
    ld (hl), de

    ld hl, selected_font_spacing
    ld (hl), 1

    pop de
    pop hl
;(don't use this)
DrawTextSkipLoad:
.drawTextLoop:
    push ix ;preserve str ptr
    push bc ;x
    push hl ;y
    push de ;bg/fg

    ld a, (ix)
    sub 32
    ld hl, 0
    ld l, a
    ld h, 3
    mlt hl
    ld de, (selected_font_table)
    add hl, de
    ld ix, (hl) ;get address to sprite

    pop de
    pop hl
    push hl
    push de

    push ix

    call DrawSprite1bpp

    pop iy ;sprite data pointer

    pop de
    pop hl
    pop bc

    ;add sprite width + (selected_font_spacing) to x
    ld ix, 0
    add ix, bc
    ld bc, 0
    ld a, (selected_font_spacing)
    add (iy)
    ld c, a
    add ix, bc
    push ix
    pop bc

    pop ix

    inc ix
    ld a, (ix)
    cp 0
    jp nz, .drawTextLoop

    ret

selected_font_table: rb 3
selected_font_spacing: db 0
