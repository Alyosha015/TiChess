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
    ld ix, TEST_FEN
    call Engine_Load

;Game Logic
    call BUI_Init
    call BUI_Reset

    ret

;****************************************************************
; GameExit - Call to properly exit program.
;****************************************************************
GameExit:
    call BUI_Free

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
TEST_FEN: db "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - ", 0
