;stores color definitions for the game.

;convert a RGB555 color into a two byte DB command
    macro COLOR555 red, green, blue
        ;gggbbbbb 0rrrrrgg
        db (((green) shl 5) and 11100000b) + ((blue) and 00011111b), (((red) shl 2) and 01111100b) + (((green) shr 3) and 11b)
    end macro

;convert a RGB888 into a two byte RGB555 color as a DB command
    macro COLOR888 r, g, b
        COLOR555 ((r)/8), ((g)/8), ((b)/8)
    end macro

;color palette
; 00-0F - Normal Colors
; 10-1F - Board / Sidebar theme

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

    COLOR_BOARD_WHITE := $10
    COLOR_BOARD_BLACK := $11
    COLOR_BOARD_PIECE_WHITE := $12
    COLOR_BOARD_PIECE_BLACK := $13
    COLOR_BOARD_RANK_FILE_LABEL := $14
    COLOR_BOARD_CURSOR := $15
    COLOR_BOARD_SELECTED_WHITE := $16
    COLOR_BOARD_SELECTED_BLACK := $17
    COLOR_BOARD_LEGAL_MOVE_WHITE := $18
    COLOR_BOARD_LEGAL_MOVE_BLACK := $19

PaletteStart:
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
    COLOR555 16, 16, 31 ;10 - board white
    COLOR555  8,  8, 20 ;11 - board black
    COLOR555 31, 31, 31 ;12 - piece white
    COLOR555  0,  0,  0 ;13 - piece black

    COLOR555 24, 24, 24 ;14 - board rank/file label
    COLOR555  8, 31,  8 ;15 - board cursor

    COLOR555 10, 22, 24 ;16 - board selected square white
    COLOR555  8, 18, 20 ;17 - board selected square black
    COLOR555 12, 12, 24 ;18 - board legal move marked white
    COLOR555  6,  6, 16 ;19 - board legal move marked black

    COLOR555  0,  0,  0 ;1A -
    COLOR555 31,  8,  8 ;1B -
    COLOR555  0,  0,  0 ;1C - 
PaletteEnd:

GFX_ColorInit:
    ld hl, PaletteStart
    ld de, LCD_PALETTE
    ld bc, PaletteEnd-PaletteStart
    
    ldir

    ret
