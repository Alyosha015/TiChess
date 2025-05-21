;note: uses the second hardware timer only.

    TIMER_COUNTER := $F20010
    TIMER_CONTROL := $F20030

;starts timer.
;doesn't preserve HL
TimerEnable:
    ld hl, TIMER_CONTROL
    res 5, (hl) ;disable generating interrupts
    set 4, (hl) ;use 32k clock
    set 3, (hl) ;enable timer
    inc hl
    set 2, (hl) ;count up
    ret

;stops timer.
;doesn't preserve HL
TimerDisable:
    ld hl, TIMER_CONTROL
    res 3, (hl)
    ret

;sets time to 0. Make sure timer is disabled beforehand.
;doesn't preserve HL
TimerReset:
    ld hl, 0
    ld (TIMER_COUNTER), hl
    ld (TIMER_COUNTER+1), hl
    ret

;gets upper 3 bytes of timer and loads into HL.
;note that this means its counting at 128 hz instead of 32768.
macro GetTime rr_
    ld rr_, (TIMER_COUNTER+1)
end macro
; GetTime:
;     ld hl, (TIMER_COUNTER+1)
;     ret
