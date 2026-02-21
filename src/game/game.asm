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
    call UiInit

;Logic
    ;timer
    call TimerDisable
    call TimerReset
    call TimerEnable

;scratchpad

    ld ix, SPRITE_QUEEN
    ld bc, 0
    ld de, 0
    ld hl, COLOR_RED * 256 + COLOR_GREEN
    call GFX_Sprite1Bpp

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

