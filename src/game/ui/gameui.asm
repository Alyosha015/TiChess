    PLAYER_HUMAN := 0
    PLAYER_COMPUTER := 1
BlackPlayerType: db 0
WhitePlayerType: db 0

    PERSPECTIVE_WHITE := 0
    PERSPECTIVE_BLACK := 1
BoardPerspective: db 0

CurrentMoves: dl 0

GameUiInit:
    call AllocMoves
    ld (CurrentMoves), ix
    call GenerateMoves
    call BoardUi_DrawCheckMap

    call BoardUi_DrawForce

    ret

GameUiCleanup:
    ld ix, (CurrentMoves)
    call FreeMoves
    ret

;board cursor state
CursorPos: db 0
CursorHasSource: db 0 ;if the source square is selected
CursorStartSquare: db 0
CursorEndSquare: db 0


CursorEnterUp: db 1
CursorEnterReleased:
    ld a, 1
    ld (CursorEnterUp), a

    ret

CursorEnter:
    ld a, (CursorEnterUp)
    cp 1
    ret nz

    xor a
    ld (CursorEnterUp), a

    ld de, 0

    ld a, (CursorHasSource)
    cp 1
    jp z, .cursorHasSource
.cursorNoSource:
    ld a, (CursorPos)
    ld hl, pieces
    ld de, 0
    ld e, a
    add hl, de
    ld a, (hl)

    cp PIECE_NONE ;is friendly piece check
    jp z, BoardClearMove
    and MASK_PIECE_COLOR
    ld hl, currentColor
    cp (hl)
    jp nz, BoardClearMove

    ;check if it has valid moves and add to boardhighlight:
    ld ix, (CurrentMoves)

; ;temp
;     pushall
;     ;call Debug_PrintMoveGenMaps
;     ld ix, (CurrentMoves)

;     ; ld a, (ix-1)
;     ; ld (varA), a

;     ld de, 0
;     ld a, (varD)
;     ld e, a
;     push de
;     ld a, (varC)
;     ld e, a
;     push de
;     ld a, (varB)
;     ld e, a
;     push de
;     ld a, (varA)
;     ld e, a
;     push de
;     ld de, printf_format
;     push de
;     ld de, printf_target
;     push de
;     call ti.sprintf
;     pop de
;     pop de
;     pop de
;     pop de
;     pop de
;     pop de

;     ld bc, 239+2
;     ld l, 50
;     ld de, COLOR_WHITE * 256 + COLOR_BLACK
;     ld ix, printf_target
;     call DrawText

;     popall

    ld a, (CursorHasSource)
    cp 0
    jp z, .skipClearPreviousSelectedMoves
    call BoardClearMove
.skipClearPreviousSelectedMoves:

    ld b, (ix-1)
    ld c, 0
    ld a, (CursorPos)
    ld l, a
    ld h, 0 ;stores if legal moves were found.
    ld de, 3
.hasLegalMoveLoop:
    ld a, (ix)
    cp l
    jp nz, .hasLegalMoveLoopContinue

    ld h, 1

    ld e, (ix+1)

    ld iy, BoardHighlight
    add iy, de
    ld (iy), COLOR_BOARD_LEGAL_MOVE
    ld iy, RedrawFlags
    add iy, de
    ld (iy), 1

    ld de, 3
.hasLegalMoveLoopContinue:
    add ix, de

    inc c
    ld a, c
    cp b
    jp nz, .hasLegalMoveLoop

    ld a, h
    cp 0
    jp z, BoardClearMove

    ld a, (CursorStartSquare) ;incase there was a previously selected square.
    ld e, a
    ld hl, BoardHighlight
    add hl, de
    ld a, (hl)
    cp COLOR_BOARD_LEGAL_MOVE
    jp z, .skipClearSquare

    ld (hl), COLOR_TRANSPARENT
    ld hl, RedrawFlags
    add hl, de
    ld (hl), 1
.skipClearSquare:

    ld a, 1
    ld (CursorHasSource), a
    ld a, (CursorPos)
    ld (CursorStartSquare), a
    
    ld e, a
    ld hl, RedrawFlags
    add hl, de
    ld (hl), 1
    ld hl, BoardHighlight
    add hl, de
    ld (hl), COLOR_BOARD_SELECTED

    ret
.cursorHasSource:
    ld hl, BoardHighlight
    ld a, (CursorPos)
    ld e, a
    add hl, de
    ld a, (hl)
    cp COLOR_BOARD_LEGAL_MOVE
    jp nz, .cursorNoSource

    ld ix, (CurrentMoves)
    ld d, (ix-1)
    ld e, 0
    ld a, (CursorStartSquare)
    ld h, a
    ld a, (CursorPos)
    ld l, a
    ld bc, 3
.findMoveLoop:
    ld a, (ix)
    cp h
    jp nz, .findMoveLoopContinue
    ld a, (ix+1)
    cp l
    jp nz, .findMoveLoopContinue

    ld bc, (ix)

    jp .foundMove
.findMoveLoopContinue:
    add ix, bc
    inc e
    ld a, e
    cp d
    jp nz, .findMoveLoop
.foundMove:
    call board_MakeMove
    call BoardUi_InitAnimation
    ld ix, (CurrentMoves)
    call GenerateMoves
    call BoardClearMove
    call BoardUi_DrawCheckMap

    ret

;cleans up COLOR_BOARD_LEGAL_MOVE/COLOR_BOARD_SELECTED/COLOR_BOARD_CHECK
BoardClearMove:
    ld bc, 0
.loop:
    ld hl, BoardHighlight
    add hl, bc
    ld a, (hl)
    cp COLOR_BOARD_LEGAL_MOVE
    jp z, .resetColor
    cp COLOR_BOARD_SELECTED
    jp z, .resetColor
    cp COLOR_BOARD_CHECK
    jp z, .resetColor
    jp .loopContinue
.resetColor:
    ld (hl), COLOR_TRANSPARENT
    ld hl, RedrawFlags
    add hl, bc
    ld (hl), 1
.loopContinue:
    inc c
    ld a, c
    cp 64
    jp nz, .loop

    ret

;in 128ths of a second
    CURSOR_LIMIT := 10 ;how long button has to not be pressed to be considered released
    CURSOR_DELAY := 64 ;time from initial key press to repeat
    CURSOR_REPEAT := 20 ;time between repeated inputs

CursorLeftUp: db 1 ;true if the key has been up for CURSOR_LIMIT time
CursorLeftUpTimer: dl 0 ;control min interval between valid key presses
CursorLeftDelayTimer: dl 0 ;controls wait before repeat starts
CursorLeftRepeatTimer: dl 0 ;controls interval between repeats

CursorLeftReleased:
    GetTime hl
    ld de, (CursorLeftUpTimer)
    sbc hl, de
    ret c

    ld a, 1
    ld (CursorLeftUp), a

    ret

CursorLeft:
    ld a, (CursorLeftUp)
    cp 1
    jp z, .skipTimers

    GetTime hl
    ld de, (CursorLeftDelayTimer)
    sbc hl, de
    ret c

    GetTime hl
    ld de, (CursorLeftRepeatTimer)
    sbc hl, de
    jp nc, .repeatTimer

    ret

.skipTimers:
    GetTime hl
    ld de, CURSOR_DELAY
    add hl, de
    ld (CursorLeftDelayTimer), hl
.repeatTimer:
    GetTime hl ;reset timer for CursorLeftUp
    ld de, CURSOR_LIMIT
    add hl, de
    ld (CursorLeftUpTimer), hl
    xor a
    ld (CursorLeftUp), a

    ld de, 0

    ld a, (CursorPos)
    ld e, a

    ld hl, RedrawFlags
    add hl, de
    ld (hl), 1

    and 111000b
    ld b, a

    ld a, e
    dec a
    and 111b

    or b
    ld e, a

    ld (CursorPos), a

    ld hl, RedrawFlags
    add hl, de
    ld (hl), 1

    GetTime hl
    ld de, CURSOR_REPEAT
    add hl, de
    ld (CursorLeftRepeatTimer), hl

    ret

CursorRightUp: db 1
CursorRightUpTimer: dl 0
CursorRightDelayTimer: dl 0
CursorRightRepeatTimer: dl 0

CursorRightReleased:
    GetTime hl
    ld de, (CursorRightUpTimer)
    sbc hl, de
    ret c

    ld a, 1
    ld (CursorRightUp), a

    ret

CursorRight:
    ld a, (CursorRightUp)
    cp 1
    jp z, .skipTimers

    GetTime hl
    ld de, (CursorRightDelayTimer)
    sbc hl, de
    ret c

    GetTime hl
    ld de, (CursorRightRepeatTimer)
    sbc hl, de
    jp nc, .repeatTimer

    ret

.skipTimers:
    GetTime hl
    ld de, CURSOR_DELAY
    add hl, de
    ld (CursorRightDelayTimer), hl
.repeatTimer:
    GetTime hl ;reset timer for CursorRightUp
    ld de, CURSOR_LIMIT
    add hl, de
    ld (CursorRightUpTimer), hl
    xor a
    ld (CursorRightUp), a

    ld de, 0

    ld a, (CursorPos)
    ld e, a

    ld hl, RedrawFlags
    add hl, de
    ld (hl), 1

    and 111000b
    ld b, a

    ld a, e
    inc a
    and 111b

    or b
    ld e, a

    ld (CursorPos), a

    ld hl, RedrawFlags
    add hl, de
    ld (hl), 1

    GetTime hl
    ld de, CURSOR_REPEAT
    add hl, de
    ld (CursorRightRepeatTimer), hl

    ret

CursorUpUp: db 1
CursorUpUpTimer: dl 0
CursorUpDelayTimer: dl 0
CursorUpRepeatTimer: dl 0

CursorUpReleased:
    GetTime hl
    ld de, (CursorUpUpTimer)
    sbc hl, de
    ret c

    ld a, 1
    ld (CursorUpUp), a

    ret

CursorUp:
    ld a, (CursorUpUp)
    cp 1
    jp z, .skipTimers

    GetTime hl
    ld de, (CursorUpDelayTimer)
    sbc hl, de
    ret c

    GetTime hl
    ld de, (CursorUpRepeatTimer)
    sbc hl, de
    jp nc, .repeatTimer

    ret

.skipTimers:
    GetTime hl
    ld de, CURSOR_DELAY
    add hl, de
    ld (CursorUpDelayTimer), hl
.repeatTimer:
    GetTime hl ;reset timer for CursorUpUp
    ld de, CURSOR_LIMIT
    add hl, de
    ld (CursorUpUpTimer), hl
    xor a
    ld (CursorUpUp), a

    ld de, 0

    ld a, (CursorPos)
    ld e, a

    ld hl, RedrawFlags
    add hl, de
    ld (hl), 1

    and 000111b
    ld b, a

    ld a, e
    add 8
    and 111000b

    or b
    ld e, a

    ld (CursorPos), a

    ld hl, RedrawFlags
    add hl, de
    ld (hl), 1

    GetTime hl
    ld de, CURSOR_REPEAT
    add hl, de
    ld (CursorUpRepeatTimer), hl

    ret

CursorDownUp: db 1
CursorDownUpTimer: dl 0
CursorDownDelayTimer: dl 0
CursorDownRepeatTimer: dl 0

CursorDownReleased:
    GetTime hl
    ld de, (CursorDownUpTimer)
    sbc hl, de
    ret c

    ld a, 1
    ld (CursorDownUp), a

    ret

CursorDown:
    ld a, (CursorDownUp)
    cp 1
    jp z, .skipTimers

    GetTime hl
    ld de, (CursorDownDelayTimer)
    sbc hl, de
    ret c

    GetTime hl
    ld de, (CursorDownRepeatTimer)
    sbc hl, de
    jp nc, .repeatTimer

    ret

.skipTimers:
    GetTime hl
    ld de, CURSOR_DELAY
    add hl, de
    ld (CursorDownDelayTimer), hl
.repeatTimer:
    GetTime hl ;reset timer for CursorDownUp
    ld de, CURSOR_LIMIT
    add hl, de
    ld (CursorDownUpTimer), hl
    xor a
    ld (CursorDownUp), a

    ld de, 0

    ld a, (CursorPos)
    ld e, a

    ld hl, RedrawFlags
    add hl, de
    ld (hl), 1

    and 000111b
    ld b, a

    ld a, e
    sub 8
    and 111000b

    or b
    ld e, a

    ld (CursorPos), a

    ld hl, RedrawFlags
    add hl, de
    ld (hl), 1

    GetTime hl
    ld de, CURSOR_REPEAT
    add hl, de
    ld (CursorDownRepeatTimer), hl

    ret

;use 00:00 format when over 9.59.9 remaining, 0:00.0 when under 10:00 remaining
Label_TimeRemaining: db "XX:XX.X", 0

gameui_TimerFormatLarge: db "%d02:%d02", 0
gameui_TimerFormatNear: db "%d:%d02.%d", 0
gameui_TimerWhiteLast: dl 0
gameui_TimerBlackLast: dl 0

gameui_HandleTimers:
    ld a, (whiteToMove)
    call MatchTimerGetTimeRemaining

    add hl, hl ;*2 multiply by 10 then divide by 128 get deci-seconds left
    push hl
    add hl, hl ;*4
    add hl, hl ;*8
    pop de
    add hl, de ;8x + 2x = 10x
    ld d, 128
    call Div24_8
    
    ld bc, 239 + 2
    ld hl, COLOR_SIDEBAR_OUTLINE * 256 + 1
    ld de, $4E14
    call DrawRect

    ld ix, Label_TimeRemaining
    ld bc, 239 + 4
    ld l, 3
    ld de, COLOR_SIDEBAR_TEXT_ACTIVE * 256
    call DrawTextLarge

    ret

GameUiTick:
;handle input

    call WaitForKey

;cursor keys
    ld a, (ti.kbdG7)
    bit ti.kbitLeft, a
    call z, CursorLeftReleased
    ld a, (ti.kbdG7)
    bit ti.kbitLeft, a
    call nz, CursorLeft

    ld a, (ti.kbdG7)
    bit ti.kbitRight, a
    call z, CursorRightReleased
    ld a, (ti.kbdG7)
    bit ti.kbitRight, a
    call nz, CursorRight

    ld a, (ti.kbdG7)
    bit ti.kbitUp, a
    call z, CursorUpReleased
    ld a, (ti.kbdG7)
    bit ti.kbitUp, a
    call nz, CursorUp

    ld a, (ti.kbdG7)
    bit ti.kbitDown, a
    call z, CursorDownReleased
    ld a, (ti.kbdG7)
    bit ti.kbitDown, a
    call nz, CursorDown
;select
    ld a, (ti.kbdG6)
    bit ti.kbitEnter, a
    call z, CursorEnterReleased
    ld a, (ti.kbdG6)
    bit ti.kbitEnter, a
    call nz, CursorEnter
;temp exit
    ld a, (ti.kbdG6)
    bit ti.kbitClear, a
    call nz, GameExit

    call BoardUi_Draw

;**** sidebar ****
    call gameui_HandleTimers

    ret

Label_PlayerHuman: db "Human", 0
Label_PlayerComputer: db "Computer", 0
