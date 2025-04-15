;handle initilizing some things going to the correct ui screen's routines. GameTick is where all the game logic/rendering executes from.

PaletteStart:
    db 00000000b, 00000000b ;  0 - 0 0 0 (used as transparent color by some, so I need two blacks)
    db 00000000b, 00000000b ;  1 - 0 0 0
    db 11111111b, 11111111b ;  2 - 255 255 255
    db 00011000b, 01100011b ;  3 - lightish gray
    db 00000000b, 01111100b ;  4 - 255 0 0
    db 11100000b, 00000011b ;  5 - 0 255 0
    db 00011111b, 00000000b ;  6 - 0 0 255
    db 11100000b, 01111111b ;  7 - 255 255 0
    db 00011111b, 01111100b ;  8 - 255 0 255
    db 11111111b, 00000011b ;  9 - 0 255 255
    db $FE, $41             ; 10 - light blue purple / board white
    db $F4, $20             ; 11 - dark blue purple / board black
PaletteEnd:

GameInit:
;UI Init
    ld hl, PaletteStart
    ld bc, (PaletteEnd-PaletteStart)/2
    call LCD_LoadPalette
    call FontLoadLarge

;Game Init
;(mainly temp testing stuff at the moment)
    ld hl, StartPosFen
    call BoardLoad
    
    call boardui_DrawForce
    
    ret

    GAME_UI_TITLE := 0
    GAME_UI_MAIN := 1

game_ui_screen: db GAME_UI_MAIN

GameTick:

    ret
