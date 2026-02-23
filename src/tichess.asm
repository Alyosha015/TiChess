;assembler config
    include "include/assembler/commands.alm"
    include "include/assembler/ez80.alm"
    include "include/assembler/tiformat.inc"

    include "include/ti84pceg.inc"

    format ti executable "TICHESS"

;program
    include "macros.asm"

    include "main.asm"

    include "game/game.asm"

    include "graphics/color.asm"
    include "graphics/lcd.asm"
    include "graphics/raster.asm"
    include "graphics/sprite.asm"
    include "graphics/text.asm"

    ;misc other subroutines
    include "util/math.asm"
    include "util/timer.asm"
    include "util/keyboard.asm"
    ;include "util/file.asm"

;rom-data
    include "data/font.asm"
    include "data/sprites.asm"
    include "data/chessLUTs.asm"

    ; ;debugging
    ; include "debug/console.asm"