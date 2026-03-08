;****************************************************************
; GameInit - intilizing ui, timers, etc
;****************************************************************
GameInit:
;Ui
    call GFX_ColorInit
    call GFX_LoadLargeFont

;Chess Engine
    call Engine_Init

;Logic
    call TimerDisable
    call TimerReset
    call TimerEnable

;scratchpad

    ld ix, SPRITE_QUEEN
    ld de, 0
    ld bc, 0
    ld hl, COLOR_WHITE * 256
    ; call GFX_Sprite1Bpp

    call BUI_DrawBoardForce

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

