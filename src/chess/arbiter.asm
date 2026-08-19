;****************************************************************
;
; Determines when and why a match ended. See chess/definitions.asm
; for possible result conditions.
;
; In implementation this is called after every move to determine
; if anyone has won. Results include losing on time, the timer
; is checked independently and will call this function when a
; timer hits zero.
;
;****************************************************************

Arbiter_Result: db 0

Arbiter_JudgeMatch:

    ret
