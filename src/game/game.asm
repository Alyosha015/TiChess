;****************************************************************
; GameInit - intilizing ui, timers, etc
;****************************************************************
GameInit:
;Ui
    call GFX_ColorInit
    call GFX_LoadLargeFont

;Chess Engine
    call Engine_Init
    ld ix, FEN_StartPosition
    call FEN_Load

;Logic
    call TimerDisable
    call TimerReset
    call TimerEnable

;scratchpad

    call BUI_DrawBoardForce

    call MoveGen_Generate

    ld a, (C_EnemyKing)
    ld (TestStr), a

    ld bc, 0
    ld de, 0
    ld hl, COLOR_WHITE * 256 + COLOR_TRANSPARENT
    ld iy, TestStr
    call GFX_DrawTextLarge

    call LCD_Swap

    ret

;****************************************************************
; GameExit - call to properly exit program
;****************************************************************
GameExit:

    call Exit

    ret

    GAME_UI_TITLE := 0
    GAME_UI_MAIN := 1

game_state: db GAME_UI_MAIN

game_CallTable:

;****************************************************************
; GameTick - all game logic and rendering happens from here
;****************************************************************
GameTick:
    
    call WaitForKey
    ld a, (ti.kbdG6)
    bit ti.kbitClear, a
    call nz, GameExit

    ret

TestStr:
    db ".",0