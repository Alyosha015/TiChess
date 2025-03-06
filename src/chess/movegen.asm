;variables
moves: rb 3

attackMap: rb 64
checkMap: rb 64
pinMap: rb 64

inCheck: db 0
inDoubleCheck: db 0


movegen_GenerateEnemyAttackMap:
    
    ret

movegen_GenerateSlidingMoves:

    ret

;expects moves struct in IX
;TODO: setting to generate capture moves only, needed for Q-Search
GenerateMoves:
    ld hl, moves
    ld (hl), ix

;Init

;knight moves

;pawn moves

    ret
