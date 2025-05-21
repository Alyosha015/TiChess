;Goal here is to have every page of the Ui be self-contained,
;and have game.asm be a glorified switch statement for running 
;the right one.
;
;General structure:
;
;xxxUiInit: - call to reset ui state to default.
;xxxUiTick: - used for logic and ui drawing. Runs as fast as possible.

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
    COLOR_BOARD_SELECTED := $16
    COLOR_BOARD_LEGAL_MOVE := $17 ;todo
    COLOR_BOARD_LAST_MOVE_SOURCE := $18 ;todo
    COLOR_BOARD_LAST_MOVE_DEST := $19 ;todo
    COLOR_BOARD_CHECK := $1A

    COLOR_SIDEBAR_OUTLINE := $1D
    COLOR_SIDEBAR_TEXT_ACTIVE := $1E
    COLOR_SIDEBAR_TEXT_INACTIVE := $1F

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
    COLOR555 31, 31,  0 ;16 - board selected
    COLOR555 31, 31,  8 ;17 - board legal move

    COLOR555  0,  0,  0 ;18 - board last source
    COLOR555  0,  0,  0 ;19 - board last destination
    COLOR555 31,  8,  8 ;1A - board check
    COLOR555  0,  0,  0 ;1B - 

    COLOR555  0,  0,  0 ;1C - 
    COLOR555 15, 15, 15 ;1D - sidebar outline
    COLOR555 31, 31, 31 ;1E - sidebar text active
    COLOR555 20, 20, 20 ;1F - sidebar text inactive
PaletteEnd:

UiInit:
    ld hl, PaletteStart
    ld bc, (PaletteEnd-PaletteStart)/2
    call LCD_LoadPalette

    call FontLoadLarge

    ret
