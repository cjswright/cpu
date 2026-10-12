    .text

    .global main

main:
    addui $2, $0, 1
    addui $2, $2, 2
    addui $2, $2, 3
    addui $2, $2, 4
    addui $2, $2, 5
    addui $2, $2, 6

    subui $1, $2, 21
    bnez $1, fail

    ori $15, $0, 0xdead
    sw $15, 0xfffff($0)
done:
    j done

fail:
    ori $15, $0, 1
    sw $15, 0xfffff($0)
