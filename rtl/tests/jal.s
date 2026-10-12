    .text

    .global main

main:
    jal add5
    jal just_return
    jal add5

    ori $15, $0, 0xdead
    sw $15, 0xfffff($0)
done:
    j done

add5:
    addi $1, $1, 5
    jr $ra

just_return:
    jr $ra

data:
    .word 0
