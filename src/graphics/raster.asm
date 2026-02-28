;************************************************
; GFX_FillRectangle - Draw filled rectangle.
;   DON'T use with 0 for width / height.
;
; INPUTS:
;   BC  = X coordinate
;   DE  = Y coordinate
;   H   = Width
;   L   = Height
;   A   = Color
;
; PRESERVES:
;   A, B', HL'
;
;************************************************
GFX_FillRectangle:
    ;register data:
    ;   IXH - [width - 1]
    ;   IXL - n/a
    ;   IY - vram pointer
    ;   A - color
    ;   BC - used for ldir
    ;   DE - used for ldir
    ;   HL - used for ldir
    ;
    ;shadow registers:
    ;   B - never modified
    ;   C - row counter (rect height, counts to 0)
    ;   DE - const 320 for shifting vram pointer to next line.
    ;   HL - never modified

    push hl ;store width/height in IX so shadow registers can access it.
    pop ix

    exx ;alt reg start
    ld de, 320
    ld c, ixl   ;load number of rows to counter
    exx ;alt reg end

    GFX_ScreenIndex ;HL = 320 * DE + BC
    ld de, (LCD_DrawBuffer) ;add vram start offset
    add hl, de
    push hl
    pop iy

    dec ixh ;since the first byte is set manually,
            ;the number of bytes to load for LDIR is one less
            ;and this is adjusted here.
    jr z, .drawRowSingleWidth

.drawRow:
    push iy
    pop hl
    push iy
    pop de

    inc de
    ld bc, 0
    ld c, ixh
    ld (hl), a

    ldir

    exx ;alt reg start
    add iy, de  ;move vram pointer to first byte of next row
    dec c
    exx ;alt reg end
    jr nz, .drawRow

    ret

;special case where LDIR isn't needed.
.drawRowSingleWidth:
    ld (iy), a

    exx ;alt reg start
    add iy, de ;move vram pointer to first byte of next row
    dec c
    exx ;alt reg end
    jr nz, .drawRowSingleWidth

    ret

;************************************************
; GFX_DrawRectangle - Draw rectangle with 1 pixel
;   border
;
; INPUTS:
;   BC  = X coordinate
;   DE  = Y coordinate
;   H   = Width
;   L   = Height
;   A   = Color
;
; PRESERVES:
;   A, Shadow Registers
;
;************************************************
GFX_DrawRectangle:
    ;register data:
    ;   IXH - [width - 1]
    ;   IXL - n/a
    ;   IY - temp
    ;   A - color
    ;   BC - used for ldir
    ;   DE - used for ldir
    ;   HL - used for ldir

    push hl ;move width/height to ix
    pop ix

    dec ixh

    GFX_ScreenIndex ;HL = 320 * DE + BC
    ld de, (LCD_DrawBuffer) ;add vram start offset
    add hl, de

    push hl ;save vram start

;draw top row
    push hl
    pop de
    inc de
    ld bc, 0
    ld c, ixh
    ld (hl), a

    ldir

;draw columns
    pop hl  ;restore vram start (start of left column)
            ;note that de has the start of the right column
            ;after the ldir instruction

    dec de  ;move column start left 1 pixel
            ;(accounts for LDIR incrementing DE/HL an extra time)

    push de ;move right column vram location to iy
    pop iy

    ld bc, 320
.columnLoop:
    ld (hl), a  ;left
    ld (iy), a  ;right

    add hl, bc
    add iy, bc

    dec ixl
    jr nz, .columnLoop

;note that hl now has the pointer to the bottom of the left column
;which can be used to start drawing the bottom row.

    or a ;clear carry flag just in case while preserving A's value
    sbc hl, bc ;move pointer up 1 pixel

    push hl
    pop de
    inc de
    ld bc, 0
    ld c, ixh
    ld (hl), a

    ldir

    ret
