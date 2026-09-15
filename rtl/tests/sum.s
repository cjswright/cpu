    .text

    .global main

# Sums eight words with a load, an accumulate and a taken branch per
# iteration, then stores the total.
main:
    and $1, $0, $0
    and $2, $0, $0

loop:
    lw $3, data($1)
    add $2, $2, $3
    addi $1, $1, 1
    subi $4, $1, 8
    bnez $4, loop

    sw $2, 0xff($0)

    ori $15, $0, 0xdead
    sw $15, 0xfffff($0)
done:
    j done

data:
    .word 0x10000000
    .word 0x02000000
    .word 0x00300000
    .word 0x00040000
    .word 0x00005000
    .word 0x00000600
    .word 0x00000070
    .word 0x00000008
