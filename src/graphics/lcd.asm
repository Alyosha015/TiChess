; Control for LCD
; Handles double buffering, bliting, 
; clearing buffers, and loading color palettes.
;
; Useful documentation:
; https://wikiti.brandonw.net/index.php?title=84PCE:Ports:4000
;

    LCD_VRAM := $D40000
    NUM_PIXELS := 320 * 240

    LCD_BUFFER_0 := LCD_VRAM
    LCD_BUFFER_1 := LCD_VRAM + NUM_PIXELS

    ;LCD_PORTS := $E30000
    LCD_DMA := $E30010 ;stores vram start address for lcd controller
    LCD_CTRL := $E30018 ;color palettes etc
    LCD_RIS := $E300020 ;raw input status register
    LCD_ICR := $E30028 ;interrupt control register
    LCD_PALETTE := $E30200 ;color palette for indexed rendering

    ;expects ti.lcdBppXX (likely ti.lcdBpp8)
    macro SetBpp bpp
        ld a, bpp
        ld (LCD_CTRL), a
    end macro

    ;resets to default 16 bit color mode
    macro ResetBpp
        SetBpp ti.lcdBpp16
    end macro

;Contains start address of buffer you should draw to.
LCD_DrawBuffer: dl LCD_BUFFER_0

LCD_EnableDoubleBuffering:
    ld hl, LCD_DrawBuffer
    ld de, LCD_BUFFER_1
    ld (hl), de

    ld hl, LCD_DMA
    ld de, LCD_BUFFER_0
    ld (hl), de

    ;set interrupt status for double buffering
    ld l, LCD_ICR and $FF ;reuse $E300xx part of address from LCD_DMA.
    ld (hl), 4

    ret


LCD_DisableDoubleBuffering:
    ld hl, LCD_DMA
    ld de, LCD_BUFFER_0
    ld (hl), de

    ld l, LCD_ICR and $FF
    ld (hl), 0

    ld hl, LCD_DrawBuffer
    ld (hl), de

    ret


;Swaps which buffer the LCD is drawing, and sets
;LCD_DrawBuffer to the new unused one for rendering
;the next frame. Waits until VSYNC interrupt to prevent
;screen tearing.
LCD_Swap:
    ;do the actual swap
    ld hl, (LCD_DrawBuffer)
    ld de, (LCD_DMA)
    ld (LCD_DrawBuffer), de
    ld (LCD_DMA), hl

    ;wait until lcd draw (prevent tearing)
    ld hl, LCD_ICR
    set 2, (hl)
    ld l, LCD_RIS and $FF
.waitLoop:
    bit 2, (hl)
    jp z, .waitLoop

    ret


;Copies LCD_BUFFER_1 into LCD_BUFFER_0
;Doesn't preserve HL, DE, BC.
LCD_Blit:
    ld hl, LCD_BUFFER_1
    ld de, LCD_BUFFER_0
    ld bc, NUM_PIXELS

    ldir

    ret


LCD_Clear:
    xor a, a
;Expects color palette index in A.
;Doesn't preserve HL, DE, BC.
LCD_ClearColor:
    ld hl, (LCD_DrawBuffer)
    push hl
    pop de
    inc de
    ld (hl), a
    ld bc, NUM_PIXELS-1

    ldir

    ret


;Expects pointer to palette in HL, number of colors in BC.
LCD_LoadPalette:
    sla c ;multiply BC by 2 since colors are 2 bytes each.
    rl b

    ld de, LCD_PALETTE

    ldir

    ret
