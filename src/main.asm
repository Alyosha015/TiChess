Main:
    call ti.RunIndicOff
    di

    SetBpp ti.lcdBpp8

    call LCD_Clear

    ld ix, 0x0D00000
    set 0, (ix+ti.graphFlags) ;see moves.asm

    call Game

;reset everything for OS
    ResetBpp

    call ti.ClrLCDFull
    call ti.HomeUp
    call ti.DrawStatusBar

    ei
    ret

Game:
;Init
    call GameUiInit

    ld hl, StartPosFen
    call BoardLoad

    call PerftTemp

.gameLoop:
    call ConsoleTick

    call ti.GetCSC
    cp ti.skEnter
    jp nz, .gameLoop

    ret

StartPosFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0

PaletteStart:
    db 00000000b, 00000000b ;  0 - 0 0 0 (used as transparent color by some, so I need two blacks)
    db 00000000b, 00000000b ;  1 - 0 0 0
    db 11111110b, 11111111b ;  2 - 255 255 255
    db 00000000b, 11111000b ;  3 - 255 0 0
    db 11000000b, 00000111b ;  4 - 0 255 0
    db 00111110b, 00000000b ;  5 - 0 0 255
    db 11000000b, 11111111b ;  6 - 255 255 0
    db 00111110b, 11111000b ;  7 - 255 0 255
    db 11111110b, 00000111b ;  8 - 0 255 255
    db $FE, $41             ;  9 - light blue purple / board white
    db $F4, $20             ; 10 - dark blue purple / board black
PaletteEnd:
