Main:
    call ti.RunIndicOff
    di

    call ti.HomeUp
    call ti.ClrScrnFull

    ld hl, StartPosFen
    push hl
    call BoardLoad

    call BoardPrint

.waitUntilEnterKey:
    call ti.GetCSC
    cp a, ti.skEnter
    jr nz, .waitUntilEnterKey

    ;reset for OS
    ld a, ti.lcdBpp16
    ld (ti.mpLcdCtrl), a
    call ti.ClrScrnFull
    ei

    ret

StartPosFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0
