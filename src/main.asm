Main:
    call ti.RunIndicOff
    di

    pushall

;
    SetBpp ti.lcdBpp8

    call LCD_EnableDoubleBuffering

    call LCD_Clear

; * * * *
    call App
; * * * *

;reset everything
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

App:
    ;call GameInit

    call UiInit

    call LCD_Clear
    ld bc, 0
    ld l, 0
    ld de, $001010
    ld h, COLOR_WHITE
    call DrawRect

    call LCD_Swap
    call LCD_Clear
    ld bc, $10
    ld l, 0
    ld de, $001010
    ld h, COLOR_WHITE
    call DrawRect

.gameLoop:
    ;call GameTick

    xor a
    ld (tempY), a
.textLoop:
    ld bc, 0
    ld a, (tempY)
    ld l, a

    ld de, (tempColor)
    inc de
    ld (tempColor), de
    ld ix, tempStr
    call DrawText

    ld a, (tempY)
    add 8
    ld (tempY), a
    cp 240
    jp nz, .textLoop

    call LCD_Swap

    ld a, (ti.kbdG6)
    bit ti.kbitClear, a
    call nz, Exit

    ld a, (RunGame)
    cp 1
    jp z, .gameLoop

    ret

tempY: db 0
tempColor: dl 0

tempStr: db "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTt", 0

RunGame: db 1
;call to stop gameloop
Exit:
    xor a
    ld (RunGame), a
    ret

StartPosFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0
