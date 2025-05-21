;assembler config
    include "include/assembler/commands.alm"
    include "include/assembler/ez80.alm"
    include "include/assembler/tiformat.inc"

    include "include/ti84pceg.inc"

    include "macros.asm"

    format ti executable "TICHESS"

;code
    include "main.asm"

    ;chess engine core
    include "chess/piece.asm"
    include "chess/piecelist.asm"
    include "chess/board.asm"
    include "chess/move.asm"
    include "chess/moves.asm"
    include "chess/movegen.asm"

    ;chess engine test
    include "chess/test/perft.asm"

    ;chess ai opponent
    include "computer/computer.asm"
    include "computer/eval.asm"

    ;game logic
    include "game/game.asm"
    include "game/matchTimer.asm"
    include "game/ui/ui.asm" ;common things for ui code
    include "game/ui/titleui.asm"
    include "game/ui/gameui.asm" ;split game code into two files, boardui.asm is for rendering ONLY the chess board.
    include "game/ui/boardui.asm"

    ;graphics subroutines
    include "graphics/lcd.asm"
    include "graphics/raster.asm"
    include "graphics/sprite.asm"
    include "graphics/text.asm"

    ;misc other subroutines
    include "util/math.asm"
    include "util/timer.asm"
    include "util/keyboard.asm"
    ;include "util/file.asm"

;ro-data
    include "data/font.asm"
    include "data/sprites.asm"
    include "data/chessLUTs.asm"

;debugging
;    include "debug/console.asm"