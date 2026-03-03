;****************************************************************
; GFX_LoadLargeFont -   creates sprite definitions / ascii lookup table
;                       for font at 2x scale. The sprite definitions are
;                       stored in the ti.pixelShadow free memory area.
;
; INPUTS / PRESERVES: NONE
;
;****************************************************************
GFX_LoadLargeFont:
    ;registers:
    ;   C - sprite load loop counter

    ld hl, MEM_FONT_TABLE_LARGE
    ld (GFX_LLF_TABLE_PTR), hl
    ld hl, MEM_LARGE_FONT
    ld (GFX_LLF_DATA_PTR), hl

    ld hl, FONT_TABLE
    ld c, 95
.fontLoadLoop:
    ld ix, (hl) ;load next pointer to sprite data
    inc hl
    inc hl
    inc hl

    push hl ;preserve font table pointer / loop counter
    push bc
    call _GFX_LoadLargeFont_Sprite
    pop bc ;restore font table pointer / loop counter
    pop hl

    dec c
    jr nz, .fontLoadLoop

    ret

;variables used by LoadLargeFont subroutines:
GFX_LLF_TABLE_PTR: rb 3 ;tracks where to write next table entry
GFX_LLF_DATA_PTR: rb 3  ;tracks where to write next sprite data entry
GFX_LLF_ROW_SIZE_BYTES: db 0    ;2x scale sprite's row size in bytes

;indexed by current bit from the left, returns that bit in 2x size form.
GFX_LLF_LUT_PIXELS:
    db 11000000b, 00110000b, 00001100b, 00000011b
    db 11000000b, 00110000b, 00001100b, 00000011b

;****************************************************************
; _GFX_LoadLargeFont_Sprite - Used to create 2x scale sprite definition.
;
; INPUTS:
;   IX - sprite data pointer
;
; PRESERVES:
;   NONE
;
;****************************************************************
_GFX_LoadLargeFont_Sprite:
    ;registers:
    ;   IX - sprite data pointer (source, to copy)
    ;   IY - sprite data pointer (destination)

    ;add next sprite to font table and update for next entry.
    ld hl, (GFX_LLF_TABLE_PTR)
    ld iy, (GFX_LLF_DATA_PTR)
    ld (hl), iy
    inc hl
    inc hl
    inc hl
    ld (GFX_LLF_TABLE_PTR), hl

    ;calculate new width / height, and row size in bytes
    ld a, (ix)      ;width
    add a
    ld (iy), a

    add 7           ;calc row size in bytes (size = (bits + 7) / 8)
    srl a
    srl a
    srl a
    ld (GFX_LLF_ROW_SIZE_BYTES), a

    ld a, (ix+1)    ;height
    add a
    ld (iy+1), a

    ;calculate new offset
    ld bc, 0
    ld c, (ix+2)    ;x offset
    sla c
    ld (iy+2), c

    ld de, 0
    ld e, (ix+3)    ;y offset
    sla e
    ld (iy+3), e

    GFX_ScreenIndex ;new vram offset
    ld (iy+4), hl

    ;sprite bitmap section

    ld a, (ix+1)    ;load height

    lea ix, ix+7 ;make ix/iy point to the start of bitmap data
    lea iy, iy+7

    ld (GFX_LLF_DATA_PTR), iy

    or a
    ret z ;early return if sprite has 0 height.

    ;registers
    ;   A - temp
    ;   B - width (of original sprite's row)
    ;   C - pixels left to convert (counts to 0)
    ;   D - height (counts to 0)
    ;   E - byte to convert
    ;   H - bits remaining
    ;   L - bits drawn counter
    ;
    ;   IX - source data
    ;   IY - destination data
    ;
    ;alt registers:
    ;   BC/DE/HL - temp for LDIR
    ;

    ld b, (ix-7) ;load original width
    ld d, (ix-6) ;load original height

.loadRow:
    push iy     ;preserve start of row location
    ld c, b
.loadByte:
    ld (iy), 0  ;prepare destination

    ld e, (ix)  ;get next byte to convert
    inc ix

    ld hl, 8 * 256 + 0  ;resets counter (L) as well
    ld a, c
    cp 8
    jr nc, .skipPartialByte
    ld h, c
.skipPartialByte:
    ld a, c
    sub h
    ld c, a

.loadBit:
    ;since 1 byte of data turns into 2 in the new sprite,
    ;destination address is incremented half-way through
    ;a byte being loaded.
    ld a, l
    cp 4
    jr nz, .skipDestByteIncrement
.doDestByteIncrement:
    inc iy
    ld (iy), 0
.skipDestByteIncrement:
    bit 7, e
    jr nz, .is1
    jr .skipIs1
.is1:
    push bc
    push hl

    ld bc, 0
    ld c, l
    ld hl, GFX_LLF_LUT_PIXELS
    add hl, bc

    ld a, (iy)
    or (hl)
    ld (iy), a
    
    pop hl
    pop bc
.skipIs1:
    sla e   ;shift next bit to check into 7th bit.

    inc l   ;load bit loop
    ld a, l
    cp h
    jr nz, .loadBit

    inc iy  ;move destination byte ptr
    ld a, c ;load byte loop
    or a
    jr nz, .loadByte

    ;since each pixel becomes a 2x2 block every row of data
    ;needs to be repeated, which is done here using LDIR to
    ;copy the row after it's done loading.
    exx ;alt reg start

    pop hl      ;restore start of row location (load source)
    lea de, iy  ;load destination

    ld bc, 0    ;load size
    ld a, (GFX_LLF_ROW_SIZE_BYTES)
    ld c, a

    add iy, bc  ;update destination pointer to skip row

    ldir

    exx ;alt reg end

    dec d   ;load row loop
    jr nz, .loadRow

    ld (GFX_LLF_DATA_PTR), iy

    ret

;****************************************************************
; GFX_TextLargeRenderSize - Calculates length of provided text in
;                           pixels if it was rendered in the 2x font.
;
; INPUTS:
;   IY  = String Pointer (null terminated)
;
; OUTPUTS:
;   BC  = Text size in pixels.
;
; PRESERVES:
;   All
;
;****************************************************************
GFX_TextLargeRenderSize:
    call GFX_TextRenderSize

    sla c ;multiply BC by 2
    rl b

    ret

;****************************************************************
; GFX_TextRenderSize - Calculates length of provided text in
;                      pixels if it was rendered.
;
; INPUTS:
;   IY  = String Pointer (null terminated)
;
; OUTPUTS:
;   DE  = Text size in pixels.
;
; PRESERVES:
;   All
;
;****************************************************************
GFX_TextRenderSize:
    push af
    push ix
    push iy
    push hl

    ld hl, 0

.textLoop:
    ld a, (iy)
    or a
    jr z, .nullChar

    sub 32

    ld de, 3
    ld d, a
    mlt de      ;DE = (a - 32) * 3

    ld ix, FONT_TABLE
    add ix, de
    ld ix, (ix) ;load sprite data pointer

    ld d, 0
    ld e, (ix)  ;load sprite width
    add hl, de  ;add sprite width to total text width
    inc hl      ;increment to account for spacing between letters

    jr .textLoop

.nullChar:

    dec hl      ;undo extra increment on last loop, since there's no following character.

    push hl     ;transfer result to DE
    pop de

    pop hl
    pop iy
    pop ix
    pop af
    ret

GFX_FONT_TABLE: rb 3 ;stores pointer to ascii -> sprite lookup table
GFX_FONT_SPACING: db 0 ;spacing between characters

;GFX_DrawText variables
GFX_DRAW_TEXT_VRAM: rb 3 ;used to store vram location

;****************************************************************
; GFX_DrawTextLarge - Draws text at XY coordinates at 2x scale.
;
; INPUTS:
;   IY  = String Pointer (null terminated)
;   BC  = X coordinate
;   DE  = Y coordinate
;   H   = Foreground Color
;   L   = Background Color
;
; PRESERVES:
;   NONE
;
;****************************************************************
GFX_DrawTextLarge:
    push hl ;preserve color
    
    ld hl, FONT_TABLE_LARGE
    ld (GFX_FONT_TABLE), hl  
    ld a, 2
    ld (GFX_FONT_SPACING), a

    jr __GFX_DrawTest_SkipRegularFontLoad

;****************************************************************
; GFX_DrawText - Draws text at XY coordinates.
;
; INPUTS:
;   IY  = String Pointer (null terminated)
;   BC  = X coordinate
;   DE  = Y coordinate
;   H   = Foreground Color
;   L   = Background Color
;
; PRESERVES:
;   NONE
;
;****************************************************************
GFX_DrawText:
    push hl ;preserve color
    
    ld hl, FONT_TABLE
    ld (GFX_FONT_TABLE), hl  
    ld a, 1
    ld (GFX_FONT_SPACING), a

__GFX_DrawTest_SkipRegularFontLoad:

    ;register data:
    ;   IX - font char sprite pointer
    ;   IY - string pointer
    ;

    GFX_ScreenIndex ;HL = 320 * DE + BC
    ld (GFX_DRAW_TEXT_VRAM), hl

.drawTextLoop:
    ld a, (iy)
    inc iy

    or a
    jr z, .nullCharacter

    sub 32  ;DE = (a - 32) * 3
    ld de, 3 * 256
    ld e, a
    mlt de

    ld hl, (GFX_FONT_TABLE)

    add hl, de

    ld ix, (hl)

    ;the next vram location is calculated before the sprite is drawn,
    ;so it has to be preserved on the stack.
    ;
    ;calculated by adding the sprite width and sprite spacing to the VRAM value.
    ld hl, (GFX_DRAW_TEXT_VRAM)
    push hl ;preserve VRAM location

    ld d, 0     ;can only reset D instead of UDE since the last result
                ;was from the DE = (a - 32) * 3 calculation
    ld e, (ix)  ;load sprite width
    add hl, de

    ld a, (GFX_FONT_SPACING)
    ld e, a
    add hl, de

    ld (GFX_DRAW_TEXT_VRAM), hl

    pop hl ;restore VRAM location

    pop de ;peek color from stack
    push de

    push iy ;preserve str ptr
    call GFX_Sprite1BppFast
    pop iy  ;restore str ptr

    jr .drawTextLoop

.nullCharacter:
    pop hl  ;get color off the stack

    ret
