;****************************************************************
;
; Used to handle drawing the board/pieces/piece animations.
;
;****************************************************************

; Some thoughts on rendering:
;
; While double-buffering is used, it's wouldn't be ideal to redraw the whole screen every frame.
; Instead, I want to use it assuming that most of the frame doesn't need to be redrawn. For example,
; when the time left gets updates, it's redrawn on the destination buffer and the buffers are swapped,
; but the board etc is assumed to have already been correctly drawn in that buffer.
;
; This will be annoying to handle cleanly, but should lead to little or no flickering on the screen.
;
; The hardest thing to handle will be animating piece movement. The current option I'm considering is
; switching briefly from double buffering to a form of blitting. I'd work using these steps:
;
; 1. Copy currently displayed frame to destination buffer
; 2. Draw moving piece sprite
; 3. Regular double-buffer drawing (update timer ui etc on destination buffer)
; 4. Wait to limit framerate
; 5. Swap and repeat
;
; This means parts of the board under the sprite don't need to be redrawn as the piece moves, since
; I'd always have a copy of it without the moving piece in the destination buffer.
;



;****************************************************************
;
; BUI_DrawTick - handles all drawing logic, main function
;
; Destroys: All
;
;****************************************************************
BUI_DrawTick:

    ret

;****************************************************************
;
; BUI_DrawBoardForce - redraw all 64 squares, clear dirty squares array
;
; Destroys: All
;
;****************************************************************
BUI_DrawBoardForce:
    ;clear dirty squares data
    ld hl, bui_DirtySquares
    ld (hl), 0
    inc hl
    ld de, bui_DirtySquares
    ld bc, 63
    ldir

    ld a, 0
.loop:
    push af

    call BUI_DrawSquare

    pop af
    inc a
    cp 64
    jr nz, .loop
    

    ret

;****************************************************************
;
; BUI_DrawBoard - redraws only squares marked dirty.
;
; DESTROYS: ALL
;
;****************************************************************
BUI_DrawBoard:

    
    ret

;temp variables for BUI_DrawSquare
;not all currently used
_bui_index: db 0    ;0-63 (file = index & 111b, rank = index >> 3)
_bui_rank: db 0     ;0-7 rows    (1-8)
_bui_file: db 0     ;0-7 columns (a-h)
_bui_square_x: db 0 ;top right corner coordinates for square currently being drawn 
_bui_square_y: db 0

;****************************************************************
;
; BUI_DrawBoard - redraws only squares marked dirty.
;
; INPUTS
;  A - board position (0-63)
;
; DESTROYS: ALL
;
;****************************************************************
BUI_DrawSquare:
    ;B - file (x)
    ;C - rank (y)
    ld c, a

    ld (_bui_index), a
    and 7   ;calculate file (index & 0000_0111b)
    ld b, a
    
    srl c   ;calculate rank (index >> 3)
    srl c
    srl c

    add c   ;A = B + C

    srl a   ;move lowest bit to carry flag
    jr c, .isOdd 
.isEven:
    ld a, COLOR_BOARD_BLACK
    jr .skipIsOdd
.isOdd:
    ld a, COLOR_BOARD_WHITE
.skipIsOdd:
    push bc ;preserve registers

    push af ;preserve color

    ld de, 30
    ld d, b
    mlt de

    ld a, 7
    sub c
    ld c, a

    ld b, 30
    mlt bc

    ;adjust coordinates if view is flipped. Both are recalculated as x = 240 - x.
    ld a, (bui_Perspective)
    or a
    jr nz, .boardPerspectiveWhite

    ld a, 240
    sub e
    ld e, a

    ld a, 240
    sub c
    ld c, a
.boardPerspectiveWhite:

    ld a, e
    ld (_bui_square_x), a
    ld a, c
    ld (_bui_square_y), a

    pop af ;restore color
    ld hl, 30 * 256 + 30
    call GFX_FillRectangle

    pop bc ;restore registers

    ret
