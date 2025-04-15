Main:
    di

    SetBpp ti.lcdBpp8

    call LCD_Clear

    call App

;reset everything for OS
    ResetBpp

    ld ix, 0x0D00000
    set 0, (ix+ti.graphFlags) ;see moves.asm

    call ti.ClrLCDFull
    call ti.HomeUp
    call ti.DrawStatusBar

    ei
    ret

App:
    call GameInit

.gameLoop:
    call GameTick

    ei ;note: need to enable interrupts
    call ti.os.GetCSC
    di

    cp ti.skEnter
    jp nz, .enterKeyNotPressed
    call Exit
.enterKeyNotPressed:

    ld a, (main_run)
    cp 1
    jp z, .gameLoop

    ret

;call to fully stop the game on next tick.
Exit:
    xor a
    ld (main_run), a
    ret

main_run: db 1

StartPosFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0
