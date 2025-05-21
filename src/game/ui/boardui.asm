LastMoveSource: db 0
LastMoveDest: db 0

    ANIM_FINISHED := 0
    ANIM_DELAY := 4 ;128/4=32 FPS
    ANIM_FRAMES := 10
AnimCounter: db ANIM_FINISHED
AnimTimer: dl 0 ;stores time at which to draw next frame.

AnimCurrentX: dl 0
AnimCurrentY: db 0

AnimBoundsXMax: db 0
AnimBoundsXMin: db 0
AnimBoundsYMax: db 0
AnimBoundsYMin: db 0

;expects X in IX, Y in IY
BoardUi_CalcRedrawFromBounds:
    ld a, (iy)
    add a
    add a
    add a
    add (ix)

    ld hl, RedrawFlags
    ld e, a
    add hl, de
    ld (hl), 1

    ret

BoardUi_InitAnimation:
    ld a, ANIM_FRAMES
    ld (AnimCounter), a

    GetTime hl
    ld de, ANIM_DELAY
    add hl, de
    ld (AnimTimer), hl

;calculate start X and Y coordinates
    ;C = file, B = rank
    ld a, (LastMoveSource)
    and 111b ;get file (square&7)
    ld (AnimBoundsXMin), a
    ld (AnimBoundsXMax), a
    ld c, a
    ld a, (LastMoveSource)
    sra a ;get rank (square>>3)
    sra a
    sra a
    neg
    add 7
    ld (AnimBoundsYMin), a
    ld (AnimBoundsYMax), a
    ld b, a

    ld de, $1E00
    ld e, c
    mlt de
    ld (AnimCurrentX), de

    ld de, $1E00
    ld e, b
    mlt de
    ld a, e
    ld (AnimCurrentY), a

    ret

;redraws only the squares which are marked for redraw.
BoardUi_Draw:

    ld c, 0
    ld hl, RedrawFlags
.drawLoop:
    ld a, (hl)
    cp 0
    jp z, .drawLoopContinue

    ld (hl), 0 ;reset redraw flag
    push hl
    call nz, BoardUi_DrawSquare
    pop hl

.drawLoopContinue:
    inc hl
    inc c
    ld a, c
    cp 64
    jp nz, .drawLoop

    ret

;redraws whole board.
BoardUi_DrawForce:
    ld c, 0
    ld hl, RedrawFlags
.drawLoop:
    ld (hl), 0

    push hl
    call BoardUi_DrawSquare
    pop hl

    inc hl
    inc c
    ld a, c
    cp 64
    jp nz, .drawLoop

    ret

;preserves BC. Expects square index in C.
BoardUi_DrawSquare:
    push bc

    ;steps?
    ;   Draw chess-square itself
    ;   Draw rank/file marker
    ;   Draw chess-piece
    ;   Draw cursor overlay
    ;   
    ;Some thoughts on animating moving pieces:
    ;
    ;

    ;registers:
    ;   B - square color (index for palette)
    ;   C - square index
    ;   DE - 
    ;   HL - 
    ;   IX - 
    ;   IXH - square rank *IX not followed after piece sprite drawing code
    ;   IXL - square file

    ld a, c
    and 111b ;get file (square&7)
    ld ixl, a
    ld a, c
    sra a ;get rank (square>>3)
    sra a
    sra a
    ld ixh, a

    ld b, COLOR_BOARD_BLACK
    add ixl
    and 1
    cp 0
    jp z, .drawBlack
    ld b, COLOR_BOARD_WHITE
.drawBlack:

;Draw Square
    ;expects X in BC, Y in L, Width in D, Height in E, Color in H
    ld de, $1E00
    ld a, ixh
    neg
    add 7
    ld e, a
    mlt de
    ld l, e
    ld h, b
    ld bc, $1E00
    ld c, ixl
    mlt bc
    ld (boardui_x), bc ;store x/y for later functions
    ld a, l
    ld (boardui_y), a
    ld de, $1E1E
    call FillRect

;Draw Rank/File:

    ld a, ixl ;file
    cp 0
    jp nz, .skipDrawRank
    push ix

    ld a, (boardui_y)
    inc a
    ld l, a
    ld bc, 1

    ld a, ixh
    add '1'
    ld ix, RankFileStr
    ld (ix), a

    ld de, COLOR_BOARD_RANK_FILE_LABEL * 256
    call DrawText

    pop ix
.skipDrawRank:

    ld a, ixh ;rank
    cp 0
    jp nz, .skipDrawFile
;expects x (0-319) in BC, y (0-239) in L, FG in D, BG in E, and string pointer in IX
    pop bc ;get bc
    push bc
    push ix ;preserve IX

    ld l, 231
    ld a, ixl
    add 'A'
    ld ix, RankFileStr
    ld (ix), a

    call TextRenderSize

    ld a, 28
    sub c

    ld bc, (boardui_x)
    add c ;offset to right side of square
    ld c, a
    ld a, b
    adc 0
    ld b, a

    ld de, COLOR_BOARD_RANK_FILE_LABEL * 256
    call DrawText

    pop ix ;restore IX
.skipDrawFile:

;draw chess piece
    ld hl, pieces
    ld de, 0
    pop bc
    push bc
    ld e, c
    add hl, de
    ld a, (hl)
    ld b, a
    cp PIECE_NONE
    jp z, .skipDrawPiece

    and MASK_PIECE_TYPE
    ld hl, SPRITE_PIECE_TABLE
    ld de, $0300
    ld e, a
    mlt de
    add hl, de
    ld ix, (hl)

    ld de, COLOR_BOARD_PIECE_WHITE * 256
    ld a, b
    and MASK_PIECE_COLOR
    cp PIECE_WHITE
    jp z, .pieceWhite
    ld de, COLOR_BOARD_PIECE_BLACK * 256
.pieceWhite:

    ld a, (LastMoveDest)
    cp c
    jp nz, .noAnim

    ld a, (AnimCounter)
    cp ANIM_FINISHED
    jp z, .noAnim
    cp 1
    jp z, .noAnim
.hasAnim:
    ;store sprite and color
    push de
    push ix

    ld de, 0

    ld hl, RedrawFlags ;reset own redraw flag
    ld e, c
    add hl, de
    ld (hl), 1

    GetTime hl
    ld de, (AnimTimer)
    sbc hl, de
    jp c, .animNoNewFrame

    ;calculate new coordinates
    ;(X, Y) = Current + (End - Current) / Remaining Animation Frames
    ;in practice I have to account for negative results of (End - Current)
    ;since the division function expects unsigned numbers.

;Calculate new X
    ld hl, (boardui_x)
    ld de, (AnimCurrentX)
    sbc hl, de
    ld iyl, 0
    ;check if HL is negative (technically checking the middle byte but it should still work)
    ;store if negative in IYL
    bit 7, h
    jp z, .XDiffIsPositive

    ld iyl, 1

    xor a ;negate HL
    sub l
    ld c, a
    sbc a, a
    sub h
    ld b, a
    push bc
    pop hl
.XDiffIsPositive:
    ld a, (AnimCounter)
    ld d, a
    dec d
    call Div24_8
    push hl
    pop de ;offset now in DE

    ld hl, (AnimCurrentX)
    ld a, iyl
    cp 0
    jp z, .AnimXOffsetPositive
.AnimXOffsetNegative:
    sbc hl, de
    jp .SkipAnimXOffsetPositive
.AnimXOffsetPositive:
    add hl, de
.SkipAnimXOffsetPositive:
    ld (AnimCurrentX), hl

;Calculate new Y
    ld a, (boardui_y)
    ld hl, AnimCurrentY
    sub (hl)
    ld iyl, 0
    jp nc, .yDiffIsPositive
    ld iyl, 1
    neg
.yDiffIsPositive:
    ld hl, 0
    ld l, a
    ld a, (AnimCounter)
    ld d, a
    dec d
    call Div24_8
    
    ld a, iyl
    cp 0
    ld a, l
    jp z, .AnimYOffsetPositive
.AnimYOffsetNegative:
    neg
.AnimYOffsetPositive:
    ld hl, AnimCurrentY
    add (hl)
    ld (AnimCurrentY), a

;update anim timer/counter
    ld a, (AnimCounter)
    dec a
    ld (AnimCounter), a

    GetTime hl
    ld de, ANIM_DELAY
    add hl, de
    ld (AnimTimer), hl

;set redraw flags for affected squares (from last bounds results)
    ld de, 0

    ld ix, AnimBoundsXMax
    ld iy, AnimBoundsYMax
    call BoardUi_CalcRedrawFromBounds
    ld iy, AnimBoundsYMin
    call BoardUi_CalcRedrawFromBounds
    ld ix, AnimBoundsXMin
    ld iy, AnimBoundsYMax
    call BoardUi_CalcRedrawFromBounds
    ld iy, AnimBoundsYMin
    call BoardUi_CalcRedrawFromBounds

;calculate squares that need to be redrawn
    pop ix ;restore sprite ptr

    ld hl, (AnimCurrentX)
    ld de, 0
    ld e, (ix+2)
    dec e
    add hl, de
    ld d, 30
    call Div24_8
    ld a, l
    ld (AnimBoundsXMin), a

    ld hl, (AnimCurrentX)
    ld de, 0
    ld a, -1 ;X = Offset + Width - 1
    add (ix+0)
    add (ix+2)
    ld e, a
    add hl, de
    ld d, 30
    call Div24_8
    ld a, l
    ld (AnimBoundsXMax), a

    ld a, (AnimCurrentY)
    dec a
    add (ix+3)
    ld l, a
    ld d, 30
    call Div24_8
    ld a, l
    sub 7
    neg
    ld (AnimBoundsYMax), a

    ld a, (AnimCurrentY)
    dec a
    add (ix+1)
    add (ix+3)
    ld l, a
    ld d, 30
    call Div24_8
    ld a, l
    sub 7
    neg
    ld (AnimBoundsYMin), a

    push ix

.animNoNewFrame:
;draw sprite
    pop ix ;restore sprite pointer
    pop de ;restore color
    ld bc, (AnimCurrentX)
    ld a, (AnimCurrentY)
    ld l, a
    jp .skipNoAnim
.noAnim:
    ld bc, (boardui_x)
    ld a, (boardui_y)
    ld l, a
.skipNoAnim:
    call DrawSprite1bpp
.skipDrawPiece:

;draw highlights
    pop bc ;get bc
    push bc
    ld de, 0
    ld e, c

    ld a, (inCheck)
    cp 0
    jp z, .skipInCheckCheck
    ld hl, BoardHighlight
    add hl, de
    ld a, (hl)
    cp COLOR_TRANSPARENT
    jp nz, .skipInCheckCheck

    ld hl, checkMap
    add hl, de
    ld a, (hl)
    ld hl, BoardHighlight
    add hl, de
    cp 0
    jp z, .notInCheck
    ld (hl), COLOR_BOARD_CHECK
.notInCheck:
    ld a, (currentKing)
    cp c
    jp nz, .skipInCheckCheck
    ld (hl), COLOR_BOARD_CHECK
.skipInCheckCheck:
    ld hl, BoardHighlight
    add hl, de
    ld a, (hl)
    cp COLOR_TRANSPARENT
    jp z, .skipDrawBoardHighlight
    ld (BoardUi_DrawHighlightColor), a
    call BoardUi_DrawHighlight
.skipDrawBoardHighlight:

;draw cursor
    ld a, (CursorPos) ;check if cursor is on this square
    pop bc ;get bc
    push bc
    cp c
    jp nz, .skipDrawCursor

    ld hl, BlackPlayerType
    ld a, (whiteToMove) ;check if AI turn (don't draw cursor)
    cp 0
    jp z, .blackToMove
    inc hl ;BlackPlayerType + 1 = WhitePlayerType
.blackToMove:
    ld a, (hl)
    cp PLAYER_COMPUTER
    jp z, .skipDrawCursor

    ld bc, (boardui_x)
    ld a, (boardui_y)
    ld l, a
    ld de, COLOR_BOARD_CURSOR * 256
    ld ix, SPRITE_CURSOR
    call DrawSprite1bpp
.skipDrawCursor:

    pop bc

    ret

BoardUi_DrawHighlightColor: db 0

;expects color in h. preserves BC, uses boardui_x and boardui_y
BoardUi_DrawHighlight:
    ld bc, (boardui_x)
    ld a, (boardui_y)
    ld l, a
    ld de, $1E1E
    ld a, (BoardUi_DrawHighlightColor)
    ld h, a
    call DrawRect

    ld bc, (boardui_x)
    inc bc
    ld a, (boardui_y)
    inc a
    ld l, a
    ld de, $1C1C
    ld a, (BoardUi_DrawHighlightColor)
    ld h, a
    call DrawRect

    ; ld bc, (boardui_x)
    ; inc bc
    ; inc bc
    ; ld a, (boardui_y)
    ; add 2
    ; ld l, a
    ; ld de, $1A1A
    ; ld a, (BoardUi_DrawHighlightColor)
    ; ld h, a
    ; call DrawRect

    ret

BoardUi_DrawCheckMap:
    ld a, (inCheck)
    cp 0
    ret z

    ld de, 0
    ld a, (currentKing)
    ld e, a
    ld ix, RedrawFlags
    add ix, de
    ld (ix), 1

    ld c, 0
    ld hl, checkMap
    ld ix, RedrawFlags
.loop:
    ld a, (hl)
    cp 0
    jp z, .loopContinue
    ld (ix), 1
.loopContinue:
    inc hl
    inc ix
    inc c
    ld a, c
    cp 64
    jp nz, .loop

    ret

;stores coordinates of top left corner of current square being drawn (24 bit for X, 8 bit for Y)
boardui_x: dl 0
boardui_y: db 0

RedrawFlags: rb 64
RankFileStr: db "x", 0

;note: also used to store what legal moves a piece has when it's selected
BoardHighlight: rb 64
