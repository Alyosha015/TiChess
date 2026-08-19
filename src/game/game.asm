;****************************************************************
; GameInit - Intilizing ui, timers, engine, etc.
;****************************************************************
GameInit:
;Ui
    call GFX_ColorInit
    call GFX_LoadLargeFont

;Chess Engine
    call Engine_Init
    ld ix, FEN_StartPosition
    call Engine_Load

;Logic
    call TimerDisable
    call TimerReset
    call TimerEnable

;scratchpad
    ;ld a, PERSPECTIVE_BLACK
    ;ld (bui_Perspective), a

    ;call BUI_DrawBoardForce

    ld a, 4
    call Perft_RunTestSuite

    ld ix, PERFT_POSITION_012
    ld iy, PERFT_EXPECTED_012
    ld a, 3
    ;call Perft_RunTest

    ;call BUI_DrawBoardForce

    call LCD_Swap

    ret

;****************************************************************
; GameExit - Call to properly exit program.
;****************************************************************
GameExit:

    call Exit

    ret

;****************************************************************
; GameTick - All game logic and rendering.
;****************************************************************
GameTick:
    
    call WaitForKey
    ld a, (ti.kbdG6)
    bit ti.kbitClear, a
    call nz, GameExit

    ret

_temp_Moves: rb 1000
FEN_TEMP: db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1", 0
