;****************************************************************
;
; Used to handle the cursor key inputs, notably the feature of
; the key repeating like on a standard keyboard when held down.
;
;****************************************************************

;Settings, note these times are in 128ths of a second.
CURSOR_DELAY := 48          ;time between initial key press to first repeat
CURSOR_REPEAT := 12         ;time between repeat key presses

;Instead of running game logic directly if a keypress is detected,
;these counters are incremented instead. It's up to the game logic
;elsewhere (for example moving the cursor across the board in
;boardui) to then read these and reset them to 0.
;
;Note that every direction needs the 4 variables in the order
;Cursor_XXXXPresses, _Cur_XXXXPressed, _Cur_XXXXDelayTimer, _Cur_XXXXRepeatTimer
;for Cursor_ProcessInput to work.
;
;Each direction's variables also has to follow the other with no other variables
;in-between.
Cursor_LeftPresses: db 0
_Cur_LeftPressed: db 0
_Cur_LeftDelayTimer: dl 0
_Cur_LeftRepeatTimer: dl 0


Cursor_RightPresses: db 0
_Cur_RightPressed: db 0
_Cur_RightDelayTimer: dl 0
_Cur_RightRepeatTimer: dl 0


Cursor_UpPresses: db 0
_Cur_UpPressed: db 0
_Cur_UpDelayTimer: dl 0
_Cur_UpRepeatTimer: dl 0


Cursor_DownPresses: db 0
_Cur_DownPressed: db 0
_Cur_DownDelayTimer: dl 0
_Cur_DownRepeatTimer: dl 0



;****************************************************************
; Cursor_ProcessInput - (internal) Handles logic for keypress
;   states.
;
; INPUT:
;   IX - Cursor_XXXXPresses address
;   Z Flag - Bit test for keyboard result.
;
; DESTROYS: A, HL, DE, BC
;****************************************************************
Cursor_ProcessInput:
    jr nz, .keyPressed
.keyReleased:

    xor a
    ld (ix+1), a            ;_Cur_XXXXPressed

    ret                     ;return after running .keyReleased logic

.keyPressed:
    ld a, (ix+1)            ;_Cur_XXXXPressed
    or a
    jr nz, .skipOnPress
.onPress:
    inc (ix+1)              ;_Cur_XXXXPressed update to true

    Timer_Read hl
    ld de, CURSOR_DELAY
    add hl, de
    ld (ix+2), hl           ;_Cur_XXXXDelayTimer

    Timer_Read hl
    ld de, CURSOR_REPEAT
    add hl, de
    ld (ix+5), hl           ;_Cur_XXXXRepeatTimer

    inc (ix)
    
    ret                     ;early return to skip repeating key logic
.skipOnPress:

    Timer_Read hl           ;early return if delay period hasn't passed
    ld de, (ix+2)           ;_Cur_XXXXDelayTimer
    sbc hl, de
    ret c

    ;key repeat logic:
    ;
    ;note: for this to work properly the repeat interval must be faster
    ;than the delay time. Since both timers get reset on the initial
    ;keypress, when the delay timer elapses the first repeat will also
    ;elapse at that moment only if it's time was less than or equal to it.

    Timer_Read hl           ;early return if repeat period hasn't passed
    ld de, (ix+5)           ;_Cur_XXXXRepeatTimer
    sbc hl, de
    ret c

    ;store keypress and reset repeat timer
    inc (ix)

    Timer_Read hl
    ld de, CURSOR_REPEAT
    add hl, de
    ld (ix+5), hl           ;_Cur_XXXXRepeatTimer

    ret

Cursor_GameTick:
    call Keyboard_Poll

    ld a, (ti.kbdG7)
    bit ti.kbitLeft, a
    ld ix, Cursor_LeftPresses
    call Cursor_ProcessInput

    ld a, (ti.kbdG7)
    bit ti.kbitRight, a
    ld ix, Cursor_RightPresses
    call Cursor_ProcessInput

    ld a, (ti.kbdG7)
    bit ti.kbitUp, a
    ld ix, Cursor_UpPresses
    call Cursor_ProcessInput

    ld a, (ti.kbdG7)
    bit ti.kbitDown, a
    ld ix, Cursor_DownPresses
    call Cursor_ProcessInput

    ret
