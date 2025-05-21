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

    ld a, (RunGame)
    cp 1
    jp z, .gameLoop

    ret

RunGame: db 1
;call to stop gameloop
Exit:
    xor a
    ld (RunGame), a
    ret

StartPosFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0
