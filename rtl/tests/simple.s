    .text

    .global main

main:
    addui $1, $0, 1
    addui $1, $0, 2
    addui $1, $0, 3
    addui $1, $0, 4
    addui $1, $0, 5
    addui $1, $0, 6

    ori $15, $0, 0xdead
    sw $15, 0xfffff($0)
done:
    j done
