;waits until keypress is detected.
WaitForKey:
    ld hl, ti.DI_Mode
    ld (hl), 2

    xor a
.wait:
    cp (hl)
    jp nz, .wait

    ret
