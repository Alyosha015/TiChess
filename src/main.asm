Main:
    call ti.RunIndicOff
    di

    pushall ;not sure why, but the program seems to crash sometimes without this?

    SetBpp ti.lcdBpp8

    ld ix, 0x0D00000
    set 0, (ix+ti.graphFlags) ;see moves.asm

    call LCD_Clear

    call App

;reset everything for OS
    ResetBpp

    popall

    call ti.ClrScrn
    call ti.HomeUp
    call ti.DrawStatusBar

    ei
    ret

App:
    call GameInit

.gameLoop:
    call GameTick

    call WaitForKey
    ld a, (ti.kbdG6)
    bit ti.kbitClear, a
    call nz, Exit

    ld a, (main_run)
    cp 1
    jp z, .gameLoop

    ret

main_run: db 1
;call to stop gameloop
Exit:
    xor a
    ld (main_run), a
    ret

;waits until keypress is detected.
WaitForKey:
    ld hl, ti.DI_Mode
    ld (hl), 2

    xor a
.wait:
    cp (hl)
    jp nz, .wait

    ret

StartPosFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0
