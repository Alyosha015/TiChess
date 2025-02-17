    include "include/assembler/commands.alm"
    include "include/assembler/ez80.alm"
    include "include/assembler/tiformat.inc"

    include "include/ti84pceg.inc"

    include "macros.asm"

    format ti executable "TICHESS"

    include "main.asm"

    include "chess/piece.asm"
    include "chess/board.asm"
    include "chess/move_generator.asm"
    include "chess/piecelist.asm"
    include "chess/test/perft.asm"
