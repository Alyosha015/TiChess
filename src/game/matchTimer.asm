;don't read these values directly, use MatchTimerGetTimeRemaining instead.
WhiteTimeLeft: dl 0
BlackTimeLeft: dl 0
TurnStartTime: dl 0

BlackUnlimitedTime: db 0 ;note: depend on white being 1 byte after black
WhiteUnlimitedTime: db 0

MatchTimerRun: db 0
MatchTimerWhiteMove: db 0

;make sure to set WhiteTimeLeft/BlackTimeLeft/WhiteUnlimitedTime/BlackUnlimitedTime.
MatchTimerStart:
    GetTime hl
    ld (TurnStartTime), hl

    ld a, 1
    ld (MatchTimerRun), a
    ld (MatchTimerWhiteMove), a
    ret

MatchTimerStop:
    xor a
    ld (MatchTimerRun), a
    ret

MatchTimerSwap:
    ld a, (MatchTimerWhiteMove)
    ld c, a
    xor 1
    ld (MatchTimerWhiteMove), a
    ld a, c

    cp 0 ;note it's swapped here
    jp nz, .blackMove
.whiteMove:
    call MatchTimerGetTimeRemaining
    ld de, WhiteTimeLeft
    sbc hl, de
    ld (WhiteTimeLeft), hl
    jp .skipBlackMove
.blackMove:
    call MatchTimerGetTimeRemaining
    ld de, WhiteTimeLeft
    sbc hl, de
    ld (BlackTimeLeft), hl
.skipBlackMove:

    GetTime hl
    ld (TurnStartTime), hl
    ret

;expects color in A (1=white, 0=black). Stores time left in HL (128ths of a second).
;Returns 0 if no time left, and 0xFFFFFF if unlimited time.
MatchTimerGetTimeRemaining:
    ld hl, $FFFFFF

    ld de, BlackUnlimitedTime ;return early if 
    cp 0
    jp z, .blackMove
    inc de
.blackMove:
    ld a, (de)
    cp 1
    ret z

    

    ret
