assume adl = 1
section .text

    public _asmIncrementTest
_asmIncrementTest:
    ;return address
    pop de

    ;note: C expects a uint24_t return type to be stored in HL
    pop hl
    inc hl

    ; ????
    ; despite using the HL register to store the return value,
    ; the stack pointer has to be perserved after a C function
    ; call for some reason, so I'm pushing a dummy value here.
    ;
    ; source: https://ce-programming.github.io/toolchain/static/asm.html#preserve
    push hl

    ;return address
    push de

    ret
