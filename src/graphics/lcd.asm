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
    LCD_RIS := $E30020 ;raw input status register
    LCD_ICR := $E30028 ;interrupt control register
    LCD_PALETTE := $E30200 ;color palette for indexed rendering

    ;expects ti.lcdBppXX (likely ti.lcdBpp8)
    ;destroys A
    macro SetBpp bpp
        ld a, bpp
        ld (LCD_CTRL), a
    end macro

    ;resets to default 16 bit color mode, destroys A
    macro ResetBpp
        SetBpp ti.lcdBpp16
    end macro

    ;assumes x coordinate is stored in BC, y in DE, and stores result in HL.
    ;calculates HL = DE * 320 + BC
    ;only HL, DE, and BC are effected.
    macro GFX_ScreenIndex
        ld hl, 64 * 256 ;ld h, 64
        ld l, e

        mlt hl      ;HL = [DE * 64]

        add hl, bc  ;hl = de * 64 + [BC]

        ld d, e     ;DE *= 256
        ld e, 0

        add hl, de  ;hl = de * 64 + [DE * 256] + bc
    end macro

;contains start address of buffer not currently being displayed
;(draw destination buffer) in the case of double buffering,
;or the start of vram if double buffering is disabled.
LCD_DrawBuffer: dl LCD_BUFFER_0

;contains start address of buffer currently being displayed
;in the case of double buffering, or start of vram if double
;buffering is disabled.
;
;NOTE: just a mapping to the LCD_DMA control register.
LCD_DisplayBuffer := LCD_DMA

;****************************************************************
; LCD_EnableDoubleBuffering - enables double buffering
;
; DESTROYS: A, HL, DE
;
;****************************************************************
LCD_EnableDoubleBuffering:
    ld de, LCD_BUFFER_1
    ld (LCD_DrawBuffer), de

    ld de, LCD_BUFFER_0
    ld (LCD_DMA), de

    ;set interrupt status for double buffering
    ld a, 4
    ld (LCD_ICR), a

    ret

;****************************************************************
; LCD_DisableDoubleBuffering - disables double buffering
;
; DESTROYS: A, HL, DE
;
;****************************************************************
LCD_DisableDoubleBuffering:
    ld de, LCD_BUFFER_0
    ld (LCD_DrawBuffer), de
    ld (LCD_DMA), de

    xor a
    ld (LCD_ICR), a

    ret

;****************************************************************
; LCD_Swap - For use with double buffering, swaps which buffer
; is being displayed and which is being written too. Updates LCD_DrawBuffer.
;
; Waits until VSYNC interrupt to prevent screen tearing.
;
; DESTROYS: HL, DE
;
;****************************************************************
LCD_Swap:
    ;do the swap
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
    jr z, .waitLoop

    ret

;****************************************************************
; LCD_Blit - Copies LCD_DrawBuffer to LCD_DisplayBuffer.
;
; DESTROYS: HL, DE, BC
;
;****************************************************************
LCD_Blit:
    ld hl, (LCD_DrawBuffer)
    ld de, (LCD_DisplayBuffer)
    ld bc, NUM_PIXELS

    ldir

    ret

;****************************************************************
; LCD_ReverseBlit - Copies LCD_DisplayBuffer to LCD_DrawBuffer.
;
; DESTROYS: HL, DE, BC
;
;****************************************************************
LCD_ReverseBlit:
    ld hl, (LCD_DisplayBuffer)
    ld de, (LCD_DrawBuffer)
    ld bc, NUM_PIXELS

    ldir

    ret

;****************************************************************
; LCD_Clear - Zeroes LCD_DrawBuffer. 
;
; DESTROYS: A, HL, DE, BC
;
;****************************************************************
LCD_Clear:
    xor a
;****************************************************************
; LCD_Clear - Sets LCD_DrawBuffer to value in A. 
;
; DESTROYS: HL, DE, BC
;
;****************************************************************
LCD_ClearColor:
    ld hl, (LCD_DrawBuffer)
    push hl
    pop de
    inc de
    ld (hl), a
    ld bc, NUM_PIXELS-1

    ldir

    ret
