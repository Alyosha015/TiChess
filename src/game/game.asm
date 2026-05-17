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

    ; call BUI_DrawBoardForce

    ; call LCD_Clear
    ld ix, _temp_Moves
    call MoveGen_Generate
    call Debug_PrintBoardMaps

    ld a, (MG_MoveCount)
    call Debug_PrintRegA

    ; ld bc, 0
    ; ld de, 128
    ; ld hl, COLOR_WHITE * 256 + COLOR_TRANSPARENT
    ; ld iy, DEBUG_OUT_STR
    ; call GFX_DrawTextLarge

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

_temp_Moves: rb 1000