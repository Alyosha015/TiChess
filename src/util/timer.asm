;****************************************************************
; Utility functions for hardware timer. All use the 2nd one only.
;****************************************************************

    TIMER_COUNTER := $F20010
    TIMER_CONTROL := $F20030

;****************************************************************
; Timer_Enable - Starts timer. Doesn't reset to 0.
;
; DESTROYS: HL
;****************************************************************
Timer_Enable:
    ld hl, TIMER_CONTROL
    res 5, (hl) ;disable generating interrupts
    set 4, (hl) ;use 32k clock
    set 3, (hl) ;enable timer
    inc hl
    set 2, (hl) ;count up
    ret

;****************************************************************
; Timer_Disable - Stops timer.
;
; DESTROYS: HL
;****************************************************************
Timer_Disable:
    ld hl, TIMER_CONTROL
    res 3, (hl)
    ret

;****************************************************************
; Timer_Reset - Reset timer to 0.
;
; DESTROYS: HL
;****************************************************************
Timer_Reset:
    ld hl, 0
    ld (TIMER_COUNTER), hl
    ld (TIMER_COUNTER+1), hl
    ret

;****************************************************************
; Timer_Read rr - Loads the upper 3 bytes of the timer's count
;   into provided register. Note that this value will increment
;   at 128 Hz Instead of 32768 Hz.
;****************************************************************
macro Timer_Read rr_
    ld rr_, (TIMER_COUNTER+1)
end macro
