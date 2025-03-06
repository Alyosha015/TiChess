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
;init:
    call GameUiInit

    ld hl, StartPosFen
    call BoardLoad

    call AllocMoves

;main loop
.gameLoop:
    call ti.GetCSC
    cp ti.skEnter
    jr nz, .gameLoop

    ret

StartPosFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0

PaletteStart:
    db 00000000b, 00000000b ; 0 - 0 0 0
    db 11111110b, 11111111b ; 1 - 255 255 255
    db 00000000b, 11111000b ; 2 - 255 0 0
    db 11000000b, 00000111b ; 3 - 0 255 0
    db 00111110b, 00000000b ; 4 - 0 0 255
    db 11000000b, 11111111b ; 5 - 255 255 0
    db 00111110b, 11111000b ; 6 - 255 0 255
    db 11111110b, 00000111b ; 7 - 0 255 255
    db $FE, $41             ; 8 - light blue purple / board white
    db $F4, $20             ; 9 - dark blue purple / board black
PaletteEnd: