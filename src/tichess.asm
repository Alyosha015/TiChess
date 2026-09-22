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
    include "game/cursor.asm"
    include "game/boardui.asm"
    include "game/sidebarui.asm"

    ;chess engine
    include "chess/variables.asm"
    include "chess/definitions.asm"

    include "chess/piecelist.asm"
    include "chess/fen.asm"
    include "chess/moves.asm"

    include "chess/engine.asm"
    include "chess/board.asm"
    include "chess/movegen.asm"

    ;debug and testing
    ;include "chess/test/dbg_move_generator.asm"
    ;include "chess/test/perft.asm"
    ;include "chess/test/perft_data.asm"

    include "debug/dbg_vars.asm"

;read only data
    include "data/font.asm"
    include "data/sprites.asm"
    include "data/chessLUTs.asm"
