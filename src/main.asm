Main:
    call ti.RunIndicOff
    di

    SetBpp ti.lcdBpp8

    call LCD_Clear

    ld ix, 0x0D00000
    set 0, (ix+ti.graphFlags) ;see moves.asm

    call App

;reset everything for OS
    ResetBpp

    call ti.ClrLCDFull
    call ti.HomeUp
    call ti.DrawStatusBar

    ei
    ret

App:
    call GameInit

    ld hl, StartPosFen
    call BoardLoad

    ;call PerftTemp

.gameLoop:
    call GameTick

    call ti.GetCSC
    cp ti.skEnter
    jp nz, .gameLoop

    ret

Exit:

    ret

StartPosFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0
