    .text

    .global main

# Each add reads a result that is still in flight in the ALU, covering the
# +1/+2 and rs/rt combinations of the forwarding paths.
main:
    addi $1, $0, 1
    addi $2, $0, 2
    addi $3, $0, 3

    add $4, $1, $3
    add $5, $2, $3
    add $6, $5, $1
    add $7, $5, $2
    add $8, $7, $6
    add $9, $7, $8

    ori $15, $0, 0xdead
    sw $15, 0xfffff($0)
done:
    j done
