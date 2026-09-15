    .text

    .global main

# Load immediately followed by a use of the loaded register.
main:
    lw $3, data($0)
    add $2, $0, $3

    ori $15, $0, 0xdead
    sw $15, 0xfffff($0)
done:
    j done

data:
    .word 1
