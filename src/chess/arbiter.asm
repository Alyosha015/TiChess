    ARBITER_IN_PROGRESS := 0
    ARBITER_WHITE_NO_TIME := 1
    ARBITER_WHITE_MATED := 2
    ARBITER_BLACK_NO_TIME := 3
    ARBITER_BLACK_MATED := 4
    ARBITER_STALEMATE := 5
    ARBITER_DRAW_NO_MATERIAL := 6
    ARBITER_DRAW_BY_ARBITER := 7

;stores result of arbiter_JudgeMatch
arbiter_Result: db 0

arbiter_JudgeMatch:

    ret
