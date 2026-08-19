;****************************************************************
;
; Test move generator by finding number of legal moves to a 
; certain depth for various test positions and comparing them
; with known values.
;
;****************************************************************

PERFT_STK_MOVES := 3
PERFT_STK_NEXT_MOVE := 6
PERFT_STK_MOVE := 9
PERFT_STK_MOVE_COUNT := 12
PERFT_STK_NODE_COUNT := 15
PERFT_STK_DEPTH := 18

_P_MaxDepth: db 0
_P_TestsPassed: db 0
_P_TestsFailed: db 0
_P_Errors: rb PERFT_TESTS_NUMBER

_P_RunTest_Failed: db 0

_P_DebugDepth: db 0
PERFT_DEBUG_PRINT_NODE_NOTATION_START: db "A1", 0
PERFT_DEBUG_PRINT_NODE_NOTATION_END: db "A1", 0
PERFT_DEBUG_PRINT_NODE_FORMAT: db "%s%s: %d (BC=%d)", 0

;****************************************************************
; Perft_Debug_SquareToNotation - (internal)
;
; INPUT:
;    A - square
;   IX - ptr to notation string
;
; DESTROYS: A
;****************************************************************
Perft_Debug_SquareToNotation:
    push af
    
    and 0111b
    add 'A'
    ld (ix), a

    pop af
    srl a
    srl a
    srl a
    add '1'
    ld (ix+1), a

    ret

Perft_Debug_PrintNode_Count: db 0

;****************************************************************
; Perft_Debug_PrintNode - (internal)
;
; INPUT:
;   BC - move
;   DE - node count
;
; DESTROYS: None
;****************************************************************
Perft_Debug_PrintNode:
    pushallexx

    ld hl, Perft_Debug_PrintNode_Count
    inc (hl)

    ld a, (hl)
    cp 24
    ;jr c, .exit ;less than

    ;note: C = move start, B = move end
    ld a, c
    ld ix, PERFT_DEBUG_PRINT_NODE_NOTATION_START
    call Perft_Debug_SquareToNotation

    ld a, b
    ld ix, PERFT_DEBUG_PRINT_NODE_NOTATION_END
    call Perft_Debug_SquareToNotation

    push bc                 ;move

    push de                 ;node count

    ld de, PERFT_DEBUG_PRINT_NODE_NOTATION_END
    push de

    ld de, PERFT_DEBUG_PRINT_NODE_NOTATION_START
    push de

    ld de, PERFT_DEBUG_PRINT_NODE_FORMAT
    push de
    ld de, DEBUG_OUT_STR
    push de
    call ti.sprintf
    pop de
    pop de
    pop de
    pop de
    pop de
    pop de

    call Debug_PrintLine

.exit:
    popallexx    
    ret

;****************************************************************
; Perft_Recursive - (internal)
;
; INPUT:
;   A - depth to search
;
; OUTPUT:
;   DE - number of moves found
;
; DESTROYS: All
;****************************************************************
Perft_Recursive:
    ld de, 1                ;base case on depth==0
    or a
    ret z

    ld iy, 0                ;allocate stack frame.
    add iy, sp
    lea iy, iy-18
    ld sp, iy
    lea iy, iy+18

    ld (iy-PERFT_STK_DEPTH), a

    call AllocMoves

    ld (iy-PERFT_STK_MOVES), ix
    ld (iy-PERFT_STK_NEXT_MOVE), ix
    
    ld hl, 0
    ld (iy-PERFT_STK_NODE_COUNT), hl

    push iy
    call MoveGen_Generate
    pop iy
    ld a, (MG_MoveCount)
    or a
    jp z, .exit
    ld (iy-PERFT_STK_MOVE_COUNT), a     ;note: decremented as loop variable

    ;bulk counting base case
;jr .skipBaseCase
    ld a, (iy-PERFT_STK_DEPTH)
    cp 1
    jr nz, .skipBaseCase

    ld a, (MG_MoveCount)
    ld (iy-PERFT_STK_NODE_COUNT), a

    jp .exit
.skipBaseCase:

.perftMoveLoop:
    ld hl, (iy-PERFT_STK_NEXT_MOVE)     ;get next move
    ld bc, (hl)
    ld (iy-PERFT_STK_MOVE), bc
    ld de, 3
    add hl, de
    ld (iy-PERFT_STK_NEXT_MOVE), hl

    push iy
    call Board_MakeMove
    pop iy

    ld a, (iy-PERFT_STK_DEPTH)          ;load depth - 1
    dec a
    push iy
    call Perft_Recursive
    pop iy

    ld hl, (iy-PERFT_STK_NODE_COUNT)    ;update node count
    add hl, de
    ld (iy-PERFT_STK_NODE_COUNT), hl

    ld bc, (iy-PERFT_STK_MOVE)

    ;debug: print number of nodes for every move at high depth.
jr .notAtDebugDepth
    ld a, (iy-PERFT_STK_DEPTH)
    ld hl, _P_DebugDepth
    cp (hl)
    jp nz, .notAtDebugDepth

    call Perft_Debug_PrintNode          ;expects BC=move, DE=node count
.notAtDebugDepth:

    push iy
    call Board_UnmakeMove
    pop iy

    ld a, (iy-PERFT_STK_MOVE_COUNT)     ;decrement loop variable
    dec a
    ld (iy-PERFT_STK_MOVE_COUNT), a
    jp nz, .perftMoveLoop
.exit:
    ;reset things
    ld ix, (iy-PERFT_STK_MOVES)
    call FreeMoves

    ld de, (iy-PERFT_STK_NODE_COUNT)

    ld sp, iy               ;remove stack frame
    ret

PERFT_RUNTEST_PROGRESS_FORMAT: db "Tests Passed/Total: (%d/%d)", 0
PERFT_RUNTEST_START_FORMAT: db "Test Suite Position #%d", 0
PERFT_RUNTEST_DEPTH_RESULT_FORMAT: db "(%s) Depth: %d Found: %d/%d", 0
PERFT_RUNTEST_STR_PASS: db "PASS", 0
PERFT_RUNTEST_STR_FAIL: db "FAIL", 0

;****************************************************************
; Perft_RunTest - (internal) 
;
; INPUT:
;   IX - position fen string
;   IY - expected node count array
;   A - max depth
;   C - test position number (for printout)
;
; OUTPUT:
;   Set Z flag if test passed, reset if failed.
;
; DESTROYS: All
;****************************************************************
Perft_RunTest:
    pushallexx
    push bc                 ;preserve BC

    ld de, 0                ;total number of tests
    ld e, c
    dec e                   ;don't count the current one
    push de
    
    ld a, (_P_TestsPassed)  ;number of tests passed
    ld e, a
    push de
    
    ld de, PERFT_RUNTEST_PROGRESS_FORMAT
    push de
    ld de, DEBUG_OUT_STR
    push de
    call ti.sprintf
    pop de
    pop de
    pop de
    pop de

    call Debug_Reset
    call LCD_Clear
    call Debug_PrintLine

    pop bc                  ;restore BC

    ld de, 0
    ld e, c
    push de
    ld de, PERFT_RUNTEST_START_FORMAT
    push de
    ld de, DEBUG_OUT_STR
    push de
    call ti.sprintf
    pop de
    pop de
    pop de
    call Debug_PrintLine
    
    popallexx

    push af                 ;load position into chess engine
    push iy
    call Engine_Load
    pop iy
    pop af

    macro MakeMove move
    ld bc, move
    dec a
    pushallexx
    call Board_MakeMove
    popallexx
    end macro

    ;MakeMove 3847
    ;MakeMove 3903

    ld c, a                 ;max depth
    ld (_P_DebugDepth), a
    ld b, 0                 ;start depth - 1

    xor a
    ld (_P_RunTest_Failed), a

.testLoop:
    push iy                 ;preserve expected pointer
    ld hl, (iy)             ;get next expected count
    push bc                 ;preserve loop counter

    ;if the expected count is zero break, on a few test cases
    ;the node count by depth 5 overflows the 24 bit limit so those
    ;are marked with a 0 to signal stopping at an earlier depth.
    ld a, l
    or a                    
    jr nz, .expectedCountNotZero
    ld a, h
    or a
    jr nz, .expectedCountNotZero
    
    pop bc
    pop iy
    jp .testLoopBreak
.expectedCountNotZero:

    ld a, b
    inc a
    push hl                 ;preserve/restore expected node count
    call Perft_Recursive
    pop hl

    call Util_EqualDEHL
    jr z, .testPassed
    ld a, (_P_RunTest_Failed)
    inc a
    ld (_P_RunTest_Failed), a
.testPassed:

    pop bc                  ;load loop counter
    push bc

    pushallexx              ;draw result string
    
    push hl                 ;expected node count

    push de                 ;node count

    ld de, 0                ;current depth
    ld e, b
    inc e
    push de
    
    ld de, PERFT_RUNTEST_STR_PASS
    ld a, (_P_RunTest_Failed);pass/fail string
    or a
    jr z, .printTestStringPass
    ld de, PERFT_RUNTEST_STR_FAIL
.printTestStringPass:
    push de

    ld de, PERFT_RUNTEST_DEPTH_RESULT_FORMAT
    push de
    ld de, DEBUG_OUT_STR
    push de
    call ti.sprintf
    pop de
    pop de
    pop de
    pop de
    pop de
    pop de

    call Debug_PrintLine

    popallexx

    pop bc
    pop iy                  ;restore expected pointer
    lea iy, iy+3
    
    inc b


    ld a, b
    cp c
    jp c, .testLoop
.testLoopBreak:

    ;call LCD_Clear
    ;call Debug_PrintBoardMaps

    ld a, (_P_RunTest_Failed)
    or a

    ret

;****************************************************************
; Perft_RunTestSuite - Run all positions to provided depth, noting
;   any errors.
;
; INPUT:
;   A - max depth (use 5 for full testing)
;
; DESTROYS: All
;****************************************************************
Perft_RunTestSuite:
    ld (_P_MaxDepth), a

    xor a
    ld (_P_TestsPassed), a
    ld (_P_TestsFailed), a

    ld hl, _P_Errors
    ld (hl), 0
    ld de, _P_Errors + 1
    ld bc, PERFT_TESTS_NUMBER
    ldir

    ld ix, PERFT_POSITIONS_TABLE
    ld iy, PERFT_EXPECTED_TABLE

    ld b, PERFT_TESTS_NUMBER

    ld c, 1

    ld hl, _P_Errors
.testLoop:
    push bc
    push ix
    push iy
    push hl

    ld ix, (ix)
    ld iy, (iy)
    ld a, (_P_MaxDepth)

    call Perft_RunTest

    pop hl
    jr z, .testPassed
;( .testFailed: )
    ld (hl), 1
    push hl
    ld hl, _P_TestsFailed
    inc (hl)
    pop hl
    jr .testPassedSkip
.testPassed:
    push hl
    ld hl, _P_TestsPassed
    inc (hl)
    pop hl
.testPassedSkip:
    inc hl

    pop iy
    pop ix

    lea ix, ix+3
    lea iy, iy+3

    pop bc
    inc c
    djnz .testLoop

    ;print final passed/failed tally
    ld de, 0                ;total number of tests
    ld e, c
    dec e
    push de
    
    ld a, (_P_TestsPassed)  ;number of tests passed
    ld e, a
    push de
    
    ld de, PERFT_RUNTEST_PROGRESS_FORMAT
    push de
    ld de, DEBUG_OUT_STR
    push de
    call ti.sprintf
    pop de
    pop de
    pop de
    pop de

    call Debug_Reset
    call LCD_Clear
    call Debug_PrintLine

    ;print list of failed tests
    ld c, 1
    ld b, PERFT_TESTS_NUMBER
    ld hl, _P_Errors
.printFailedTests:
    ld a, (hl)
    inc hl
    or a
    jr z, .printFailedTestsContinue

    ld a, c
    DEBUG_OUT_A "FAIL: Test #"

.printFailedTestsContinue:
    inc c
    ld a, c
    cp b
    jr c, .printFailedTests

    ret
