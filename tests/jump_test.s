    .text

    .global main

# Jumps around the place like crazy.
main:
    j l4

l1: j l3

l2: j end

l3: j l2

l4: j l1

end:    
    ori $15, $0, 0xdead
    sw $15, 0xfffff($0)
done:
    j done
