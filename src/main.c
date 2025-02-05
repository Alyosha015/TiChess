#include <ti/screen.h>
#include <ti/getcsc.h>

#include <stdio.h>

#include "func.h"

int main(void) {
    os_ClrHome();

    os_PutStrFull("This is a test!");
    os_SetCursorPos(1, 0);

    uint24_t value = 6502;

    char buffer[32];
    sprintf(buffer, "%d + 1 = %d!", value, asmIncrementTest(value));
    os_PutStrFull(buffer);

    while(!os_GetCSC());

    return 0;
}
