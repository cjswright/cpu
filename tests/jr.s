    .text

    .global main

main:
    la $2, trampoline
loop:
    addi $2, $2, 1
    jr $2

finished:
    ori $15, $0, 0xdead
    sw $15, 0xfffff($0)
done:
    j done

trampoline:
    j fail
    j loop
    j loop
    j loop
    j loop
    j loop
    j finished

fail:
    ori $15, $0, 0x1
    sw $15, 0xfffff($0)
    j done

data:
    .word 0
