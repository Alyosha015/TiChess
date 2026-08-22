;****************************************************************
; GameInit - Intilizing timers, ui, engine, etc.
;****************************************************************
GameInit:
    call Timer_Disable
    call Timer_Reset
    call Timer_Enable

;Ui
    call GFX_ColorInit
    call GFX_LoadLargeFont

;Chess Engine
    call Engine_Init
    ld ix, FEN_StartPosition
    call Engine_Load

;Game Logic
    call BUI_Reset

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
    
    call Keyboard_Poll
    ld a, (ti.kbdG6)
    bit ti.kbitClear, a
    call nz, GameExit

    call BUI_GameTick

    ret
