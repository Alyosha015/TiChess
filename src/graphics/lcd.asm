    LCD_VRAM := $D40000
    LCD_PALETTE := $E30200
    NUM_PIXELS := 320 * 240

;note: most of this code works on the assumption that 8 bpp indexed color is used.

LCD_Clear:
    xor a, a
;expects color index in a
LCD_ClearColor:
    ld hl, LCD_VRAM
    ld (hl), a
    ld de, LCD_VRAM+1
    ld bc, NUM_PIXELS-1
    ldir
    ret

;note: using a partially-unrolled ldi loop would be faster.
LCD_Blit:
    ld hl, LCD_VRAM+NUM_PIXELS
    ld de, LCD_VRAM
    ld bc, NUM_PIXELS
    ldir
    ret

;expects pointer to palette in HL, number of colors in BC.
LCD_LoadPalette:
    sla c ;multiply BC by 2
    rl b
    ld de, LCD_PALETTE
    ldir
    ret
