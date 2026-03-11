Main:
    call ti.RunIndicOff
    di

    pushall

;
    SetBpp ti.lcdBpp8

    call LCD_EnableDoubleBuffering

    call LCD_Clear

; * * * *
    call Program
; * * * *

    ;stop
    ResetBpp

    call LCD_DisableDoubleBuffering

    ld ix, 0x0D00000
    set 0, (ix+ti.graphFlags) ;see moves.asm

    popall

    call ti.ClrScrn
    call ti.HomeUp
    call ti.DrawStatusBar

    ei
    ret

Program:
    call GameInit

.mainLoop:
    call GameTick

    ld a, (RunGame)
    cp 1
    jp z, .mainLoop

    ret

RunGame: db 1
;call to stop gameloop
Exit:
    xor a
    ld (RunGame), a
    ret

