;****************************************************************
; Engine_Init - Should only be called once. Not the reset subroutine.
;
; DESTROYS: All
;****************************************************************
Engine_Init:
    call PL_Init

    call Engine_Reset

    ret

;****************************************************************
; Engine_Reset - Used to reset all chess engine variables.
;
; DESTROYS: All
;****************************************************************
Engine_Reset:
    ld hl, C_Board      ;clear board representation array / piecelists
    ld (hl), 0
    ld de, C_Board + 1
    ld bc, 63
    ldir

    call PL_ResetAll

    ret

;****************************************************************
; Engine_SetIndexVariables - Sets current/enemy index and color
; variables based on value of C_WhiteToMove.
;
; DESTROYS: AF
;****************************************************************
Engine_SetIndexVariables:
    ld a, (C_WhiteToMove)
    or a
    jr z, .blackToMove
.whiteToMove:
    ld (C_CurrentIndex), a  ;since A = (C_WhiteToMove) = 1 here
    ld a, 8
    ld (C_CurrentColor), a

    xor a
    ld (C_EnemyIndex), a
    ld (C_EnemyColor), a

    ret
.blackToMove:
    ld (C_CurrentIndex), a  ;since A = (C_WhiteToMove) = 0 here
    ld (C_CurrentColor), a

    ld a, 1
    ld (C_EnemyIndex), a
    ld a, 8
    ld (C_EnemyColor), a

    ret
