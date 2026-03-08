;assembler config
    include "include/assembler/commands.alm"
    include "include/assembler/ez80.alm"
    include "include/assembler/tiformat.inc"

    include "include/ti84pceg.inc"

    format ti executable "TICHESS"

;program
    include "macros.asm"

    ;main
    include "main.asm"
    include "memory.asm"

    ;core (generic graphics, timer, etc subroutines)
    include "graphics/color.asm"
    include "graphics/lcd.asm"
    include "graphics/raster.asm"
    include "graphics/sprite.asm"
    include "graphics/text.asm"

    include "util/math.asm"
    include "util/timer.asm"
    include "util/keyboard.asm"

    ;game logic and graphics
    include "game/variables.asm"
    include "game/game.asm"
    include "game/boardui.asm"

    ;chess engine
    include "chess/variables.asm"
    include "chess/move.asm"
    include "chess/piece.asm"

    include "chess/engine.asm"
    include "chess/piecelist.asm"
    include "chess/fen.asm"

;read only data
    include "data/font.asm"
    include "data/sprites.asm"
    include "data/chessLUTs.asm"
