;handle initilizing some things going to the correct ui screen's routines.
;GameTick is where all the game logic/rendering executes from.

TEST_STR:
    db "Test String!", 0

GameInit:
;Ui
    call GFX_ColorInit
    call GFX_LoadLargeFont

;Logic
    ;timer
    call TimerDisable
    call TimerReset
    call TimerEnable

;scratchpad

    ; ld ix, SPRITE_KING
    ; ld bc, 0
    ; ld de, 0
    ; ld hl, COLOR_BOARD_PIECE_WHITE * 256 + COLOR_TRANSPARENT
    ; call GFX_Sprite1Bpp

    ld iy, TEST_STR
    ld bc, 0
    ld de, 0
    ld hl, COLOR_GREEN * 256
    call GFX_DrawTextLarge

    ld iy, TEST_STR
    ld bc, 0
    ld de, 18
    ld hl, COLOR_GREEN * 256
    call GFX_DrawText

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

