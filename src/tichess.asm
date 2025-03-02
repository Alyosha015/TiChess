    include "include/assembler/commands.alm"
    include "include/assembler/ez80.alm"
    include "include/assembler/tiformat.inc"

    include "include/ti84pceg.inc"

    include "macros.asm"

    format ti executable "TICHESS"

;code
    include "main.asm"

    include "chess/piece.asm"
    include "chess/board.asm"
    include "chess/movegen.asm"
    include "chess/piecelist.asm"
    include "chess/test/perft.asm"

    include "graphics/lcd.asm"
    include "graphics/raster.asm"
    include "graphics/sprite.asm"
    include "graphics/text.asm"

;data
    include "data/font.asm"
    include "data/sprites.asm"
    include "data/chessLUTs.asm"