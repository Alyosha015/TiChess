@ECHO OFF
:BUILD

ECHO.

fasmg src\tichess.asm bin\tichess.8xp

SET INPUT="a"
SET /P INPUT="X to exit, any key to compile again: "

if /I NOT "%INPUT%" == "X" (
    GOTO BUILD
)
