;****************************************************************
;
; Stores color definitions for the game.
;
; Also handles a special effect for when a player is choosing
; what piece to promote to. Instead of redrawing the whole board
; the color definition for piece/board color is changed to make
; most of it appear darker, while the promotion options are drawn
; normally.
;
;****************************************************************

;convert a RGB555 color into a two byte DB directive
    macro COLOR555 red, green, blue
        ;gggbbbbb 0rrrrrgg
        db (((green) shl 5) and 11100000b) + ((blue) and 00011111b), (((red) shl 2) and 01111100b) + (((green) shr 3) and 11b)
    end macro

;convert a RGB888 into a two byte RGB555 color as a DB directive
    macro COLOR888 r, g, b
        COLOR555 ((r)/8), ((g)/8), ((b)/8)
    end macro

;color palette
; 00-0F - Normal Colors
; 10-1F - Board Regular Colors
; 20-2F - Board Promotion Selection Colors
; 30-3F - Board Ui Other

    COLOR_TRANSPARENT := $00
    COLOR_BLACK := $01
    COLOR_DARK_GRAY := $02
    COLOR_GRAY := $03
    COLOR_LIGHT_GRAY := $04
    COLOR_WHITE := $05
    COLOR_RED := $06
    COLOR_GREEN := $07
    COLOR_BLUE := $08
    COLOR_YELLOW := $09
    COLOR_MAGENTA := $0A
    COLOR_CYAN := $0B


    COLOR_BOARD_BLACK := $10
    COLOR_BOARD_WHITE := $11
    COLOR_BOARD_PIECE_BLACK := $12
    COLOR_BOARD_PIECE_WHITE := $13
    COLOR_BOARD_SELECTED_BLACK := $14
    COLOR_BOARD_SELECTED_WHITE := $15
    COLOR_BOARD_LEGAL_MOVE_BLACK := $16
    COLOR_BOARD_LEGAL_MOVE_WHITE := $17


    COLOR_BOARD_P_BLACK := $20
    COLOR_BOARD_P_WHITE := $21
    COLOR_BOARD_P_PIECE_BLACK := $22
    COLOR_BOARD_P_PIECE_WHITE := $23
    COLOR_BOARD_P_SELECTED_BLACK := $26
    COLOR_BOARD_P_SELECTED_WHITE := $27
    COLOR_BOARD_P_LEGAL_MOVE_BLACK := $28
    COLOR_BOARD_P_LEGAL_MOVE_WHITE := $29


    COLOR_BOARD_CURSOR := $30

GFX_PaletteStandardStart:
;default colors
    COLOR555  0,  0,  0 ;00
    COLOR555  0,  0,  0 ;01
    COLOR555  7,  7,  7 ;02
    COLOR555 15, 15, 15 ;03
    COLOR555 23, 23, 23 ;04
    COLOR555 31, 31, 31 ;05
    COLOR555 31,  0,  0 ;06
    COLOR555  0, 31,  0 ;07
    COLOR555  0,  0, 31 ;08
    COLOR555 31, 31,  0 ;09
    COLOR555 31,  0, 31 ;0A
    COLOR555  0, 31, 31 ;0B
    COLOR555  0,  0,  0 ;0C
    COLOR555  0,  0,  0 ;0D
    COLOR555  0,  0,  0 ;0E
    COLOR555  0,  0,  0 ;0F
;board colors
    COLOR555  8,  8, 20 ;10 - board black
    COLOR555 16, 16, 31 ;11 - board white
    COLOR555  0,  0,  0 ;12 - piece black
    COLOR555 31, 31, 31 ;13 - piece white

    COLOR555  8, 18, 20 ;14 - board selected square black
    COLOR555 10, 22, 24 ;15 - board selected square white
    COLOR555  6,  6, 16 ;16 - board legal move marked black
    COLOR555 12, 12, 24 ;17 - board legal move marked white

    COLOR555  0,  0,  0 ;18 - 
    COLOR555  0,  0,  0 ;19 - 
    COLOR555  0,  0,  0 ;1A -
    COLOR555  0,  0,  8 ;1B -
    COLOR555  0,  0,  0 ;1C - 
    COLOR555  0,  0,  0 ;1D - 
    COLOR555  0,  0,  0 ;1E - 
    COLOR555  0,  0,  0 ;1F - 
;board promotion mode colors. Should
;be a copy of the above definitions.
    COLOR555  8,  8, 20 ;20 - board black p
    COLOR555 16, 16, 31 ;21 - board white p
    COLOR555  0,  0,  0 ;22 - piece black p
    COLOR555 31, 31, 31 ;23 - piece white p

    COLOR555  8, 18, 20 ;24 - board selected square black p
    COLOR555 10, 22, 24 ;25 - board selected square white p
    COLOR555  6,  6, 16 ;26 - board legal move marked black p
    COLOR555 12, 12, 24 ;27 - board legal move marked white p

    COLOR555  0,  0,  0 ;28 - 
    COLOR555  0,  0,  0 ;29 - 
    COLOR555  0,  0,  0 ;2A -
    COLOR555  0,  0,  8 ;2B -
    COLOR555  0,  0,  0 ;2C - 
    COLOR555  0,  0,  0 ;2D - 
    COLOR555  0,  0,  0 ;2E - 
    COLOR555  0,  0,  0 ;2F - 
;board ui other colors
    COLOR555  8, 31,  8 ;30 - board cursor

;note that this only stores a subset of the color palette
GFX_PaletteStandardEnd:


;promotion mode palette
GFX_PalettePromotionStart:
    COLOR555  4,  4, 10 ;10 - board black
    COLOR555  8,  8, 16 ;11 - board white
    COLOR555  0,  0,  0 ;12 - piece black
    COLOR555 16, 16, 16 ;13 - piece white

    ;set to board white/black respective values,
    ;so if drawn they will be invisible.
    COLOR555  4,  4, 10 ;14 - board selected square black
    COLOR555  8,  8, 16 ;15 - board selected square white
    COLOR555  4,  4, 10 ;16 - board legal move marked black
    COLOR555  8,  8, 16 ;17 - board legal move marked white

    COLOR555  0,  0,  0 ;18 - 
    COLOR555  0,  0,  0 ;19 - 
    COLOR555  0,  0,  0 ;1A -
    COLOR555  0,  0,  8 ;1B -
    COLOR555  0,  0,  0 ;1C - 
    COLOR555  0,  0,  0 ;1D - 
    COLOR555  0,  0,  0 ;1E - 
    COLOR555  0,  0,  0 ;1F - 
GFX_PalettePromotionEnd:

;****************************************************************
; GFX_InitColorPalette - Load whole color palette.
;
; Destroys: HL, DE, BC
;****************************************************************
GFX_InitColorPalette:
    ld hl, GFX_PaletteStandardStart
    ld de, LCD_PALETTE
    ld bc, GFX_PaletteStandardEnd-GFX_PaletteStandardStart
    
    ldir

    ret

;****************************************************************
; GFX_LoadColorPalettePromotion - Load color palette for
;   promotion mode. Only loads definitions 10-1F.
;
; Destroys: HL, DE, BC
;****************************************************************
GFX_LoadColorPalettePromotion:
    ld hl, GFX_PalettePromotionStart
    ld de, LCD_PALETTE + 32 ;32 bytes = skip 00-0F color definitions (2 bytes each)
    ld bc, 32
    
    ldir

    ret

;****************************************************************
; GFX_LoadColorPaletteNormal - Return color palette to normal
;   after promotion mode. Only changes definitions 10-1F.
;
; Destroys: HL, DE, BC
;****************************************************************
GFX_LoadColorPaletteNormal:
    ld hl, GFX_PaletteStandardStart + 64 ;offste to copy from 20-2F definitions.
    ld de, LCD_PALETTE + 32 ;32 bytes = skip 00-0F color definitions (2 bytes each)
    ld bc, 32

    ldir

    ret
