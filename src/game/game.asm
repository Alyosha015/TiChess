;handle initilizing some things going to the correct ui screen's routines.
;GameTick is where all the game logic/rendering executes from.

GameInit:
;Ui
    call UiInit

;Logic
    ;timer
    call TimerDisable
    call TimerReset
    call TimerEnable

;(mainly temp testing stuff at the moment)
    ld hl, StartPosFen
    call BoardLoad

    call GameUiInit ;temp call

    ret

;handles exiting the program.
GameExit:
    call GameUiCleanup

    call Exit

    ret

    GAME_UI_TITLE := 0
    GAME_UI_MAIN := 1

game_state: db GAME_UI_MAIN

game_CallTable:

GameTick:
    call GameUiTick ;temp call until I get the call table working

    ; GetTime hl
    ; ld d, 128
    ; call Div24_8
    ; push hl
    ; ld de, printf_format
    ; push de
    ; ld de, printf_target
    ; push de
    ; call ti.sprintf
    ; pop de
    ; pop de
    ; pop de

    ; ld ix, printf_target
    ; call LargeTextRenderSize

    ; ld d, c
    ; ld e, 20
    ; ld bc, 239+2
    ; ld l, 0
    ; ld h, 1
    ; call FillRect

    ; ld bc, 239+2
    ; ld l, 0
    ; ld de, COLOR_WHITE * 256 + COLOR_BLACK
    ; ld ix, printf_target
    ; call DrawTextLarge

    ret

printf_format: db "%03d %03d %03d %03d", 0
printf_target: rb 16*4
