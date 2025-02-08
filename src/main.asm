Main:
    call ti.RunIndicOff
    di

    call ti.HomeUp
    call ti.ClrScrnFull

    print TestMsg, 0, 0

    ld hl, StartPosFen
    push hl
    call BoardLoad

.waitUntilEnterKey:
    call ti.GetCSC
    cp a, ti.skEnter
    jr nz, .waitUntilEnterKey

    ;reset for OS
    ld a, ti.lcdBpp16
    ld (ti.mpLcdCtrl), a

    call ti.ClrScrnFull
    ei

    ret

TestMsg:
    db "Chess Thingy:", 0

StartPosFen:
    db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0

;     .assume ADL=1
;     .org userMem-2
; PROGRAM_START:
; PROGRAM_CODE_START:
;     .db tExtTok,tAsm84CeCmp
; Main:
;     call _homeup
;     call _ClrScrnFull

;     ; print(5, 1, Text)

;     ld hl, StartPosFen
;     push hl
;     call BoardLoad

;     call _GetKey
;     call _ClrScrnFull
;     res donePrgm, (iy + doneFlags)

;     ret

; #include "src/chess/board.asm"

; PROGRAM_CODE_END:

; PROGRAM_DATA_START:
; StartPosFen:
;     .db "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0



; ; Text:
; ;     .db "This is a test!", 0
; PROGRAM_DATA_END:
; PROGRAM_END:

; .echo "Total Size:\t", PROGRAM_END-PROGRAM_START, " B"
; .echo "Code Size:\t", PROGRAM_CODE_END-PROGRAM_CODE_START, " B"
; .echo "Data Size:\t", PROGRAM_DATA_END-PROGRAM_DATA_START, " B"