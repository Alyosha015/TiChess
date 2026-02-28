;handle initilizing some things going to the correct ui screen's routines.
;GameTick is where all the game logic/rendering executes from.

TEST_SPRITE:
    db 11, 1, 0, 0, 0, 0, 0
    db 11110000b, 11000000b
    
    db 11110000b, 11110000b, 11110000b, 11110000b
    db 11001100b, 00110011b, 11001100b, 00110011b
    db 10101010b, 01010101b, 10101010b, 01010101b

GameInit:
;Ui
    call GFX_ColorInit

;Logic
    ;timer
    call TimerDisable
    call TimerReset
    call TimerEnable

;scratchpad

    ld ix, SPRITE_KING
    ld bc, 0
    ld de, 0
    ld hl, COLOR_BOARD_PIECE_WHITE * 256 + COLOR_TRANSPARENT
    call GFX_Sprite1Bpp

    ld bc, 100
    ld de, 10
    ld hl, 20 * 256 + 10
    ld a, COLOR_BLUE
    call GFX_FillRectangle

    ld bc, 0
    ld de, 0
    ld hl, 5 * 256 + 5
    ld a, COLOR_YELLOW
    call GFX_DrawRectangle


    ;call GFX_DrawText

    call LCD_Swap

    ret

;handles exiting the program.
GameExit:

    call Exit

    ret

    GAME_UI_TITLE := 0
    GAME_UI_MAIN := 1

game_state: db GAME_UI_MAIN

game_CallTable:

GameTick:
    
    call WaitForKey
    ld a, (ti.kbdG6)
    bit ti.kbitClear, a
    call nz, GameExit

    ret

