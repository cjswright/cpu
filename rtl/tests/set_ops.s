    .text

    .global main

main:
    addi $2, $0, 0
    addi $3, $0, 1
    addi $4, $0, -1
    addi $5, $0, -2

    slt $1, $2, $2 // 0 < 0
    bnez $1, fail
    slt $1, $2, $3 // 0 < 1
    beqz $1, fail
    slt $1, $2, $4 // 0 < -1
    bnez $1, fail
    slt $1, $2, $5 // 0 < -2
    bnez $1, fail
    slt $1, $3, $2 // 1 < 0
    bnez $1, fail
    slt $1, $3, $3 // 1 < 1
    bnez $1, fail
    slt $1, $3, $4 // 1 < -1
    bnez $1, fail
    slt $1, $3, $5 // 1 < -2
    bnez $1, fail
    slt $1, $4, $2 // -1 < 0
    beqz $1, fail
    slt $1, $4, $3 // -1 < 1
    beqz $1, fail
    slt $1, $4, $4 // -1 < -1
    bnez $1, fail
    slt $1, $4, $5 // -1 < -2
    bnez $1, fail
    slt $1, $5, $2 // -2 < 0
    beqz $1, fail
    slt $1, $5, $3 // -2 < 1
    beqz $1, fail
    slt $1, $5, $4 // -2 < -1
    beqz $1, fail
    slt $1, $5, $5 // -2 < -2
    bnez $1, fail

    sltu $1, $2, $2 // 0 < 0
    bnez $1, fail
    sltu $1, $2, $3 // 0 < 1
    beqz $1, fail
    sltu $1, $2, $4 // 0 < 0xffff
    beqz $1, fail
    sltu $1, $2, $5 // 0 < 0xfffe
    beqz $1, fail
    sltu $1, $3, $2 // 1 < 0
    bnez $1, fail
    sltu $1, $3, $3 // 1 < 1
    bnez $1, fail
    sltu $1, $3, $4 // 1 < 0xffff
    beqz $1, fail
    sltu $1, $3, $5 // 1 < 0xfffe
    beqz $1, fail
    sltu $1, $4, $2 // 0xffff < 0
    bnez $1, fail
    sltu $1, $4, $3 // 0xffff < 1
    bnez $1, fail
    sltu $1, $4, $4 // 0xffff < 0xffff
    bnez $1, fail
    sltu $1, $4, $5 // 0xffff < 0xfffe
    bnez $1, fail
    sltu $1, $5, $2 // 0xfffe < 0
    bnez $1, fail
    sltu $1, $5, $3 // 0xfffe < 1
    bnez $1, fail
    sltu $1, $5, $4 // 0xfffe < 0xffff
    beqz $1, fail
    sltu $1, $5, $5 // 0xfffe < 0xfffe
    bnez $1, fail

    sgt $1, $2, $2 // 0 > 0
    bnez $1, fail
    sgt $1, $2, $3 // 0 > 1
    bnez $1, fail
    sgt $1, $2, $4 // 0 > -1
    beqz $1, fail
    sgt $1, $2, $5 // 0 > -2
    beqz $1, fail
    sgt $1, $3, $2 // 1 > 0
    beqz $1, fail
    sgt $1, $3, $3 // 1 > 1
    bnez $1, fail
    sgt $1, $3, $4 // 1 > -1
    beqz $1, fail
    sgt $1, $3, $5 // 1 > -2
    beqz $1, fail
    sgt $1, $4, $2 // -1 > 0
    bnez $1, fail
    sgt $1, $4, $3 // -1 > 1
    bnez $1, fail
    sgt $1, $4, $4 // -1 > -1
    bnez $1, fail
    sgt $1, $4, $5 // -1 > -2
    beqz $1, fail
    sgt $1, $5, $2 // -2 > 0
    bnez $1, fail
    sgt $1, $5, $3 // -2 > 1
    bnez $1, fail
    sgt $1, $5, $4 // -2 > -1
    bnez $1, fail
    sgt $1, $5, $5 // -2 > -2
    bnez $1, fail

    sgtu $1, $2, $2 // 0 > 0
    bnez $1, fail
    sgtu $1, $2, $3 // 0 > 1
    bnez $1, fail
    sgtu $1, $2, $4 // 0 > 0xffff
    bnez $1, fail
    sgtu $1, $2, $5 // 0 > 0xfffe
    bnez $1, fail
    sgtu $1, $3, $2 // 1 > 0
    beqz $1, fail
    sgtu $1, $3, $3 // 1 > 1
    bnez $1, fail
    sgtu $1, $3, $4 // 1 > 0xffff
    bnez $1, fail
    sgtu $1, $3, $5 // 1 > 0xfffe
    bnez $1, fail
    sgtu $1, $4, $2 // 0xffff > 0
    beqz $1, fail
    sgtu $1, $4, $3 // 0xffff > 1
    beqz $1, fail
    sgtu $1, $4, $4 // 0xffff > 0xffff
    bnez $1, fail
    sgtu $1, $4, $5 // 0xffff > 0xfffe
    beqz $1, fail
    sgtu $1, $5, $2 // 0xfffe > 0
    beqz $1, fail
    sgtu $1, $5, $3 // 0xfffe > 1
    beqz $1, fail
    sgtu $1, $5, $4 // 0xfffe > 0xffff
    bnez $1, fail
    sgtu $1, $5, $5 // 0xfffe > 0xfffe
    bnez $1, fail

    sle $1, $2, $2 // 0 <= 0
    beqz $1, fail
    sle $1, $2, $3 // 0 <= 1
    beqz $1, fail
    sle $1, $2, $4 // 0 <= -1
    bnez $1, fail
    sle $1, $2, $5 // 0 <= -2
    bnez $1, fail
    sle $1, $3, $2 // 1 <= 0
    bnez $1, fail
    sle $1, $3, $3 // 1 <= 1
    beqz $1, fail
    sle $1, $3, $4 // 1 <= -1
    bnez $1, fail
    sle $1, $3, $5 // 1 <= -2
    bnez $1, fail
    sle $1, $4, $2 // -1 <= 0
    beqz $1, fail
    sle $1, $4, $3 // -1 <= 1
    beqz $1, fail
    sle $1, $4, $4 // -1 <= -1
    beqz $1, fail
    sle $1, $4, $5 // -1 <= -2
    bnez $1, fail
    sle $1, $5, $2 // -2 <= 0
    beqz $1, fail
    sle $1, $5, $3 // -2 <= 1
    beqz $1, fail
    sle $1, $5, $4 // -2 <= -1
    beqz $1, fail
    sle $1, $5, $5 // -2 <= -2
    beqz $1, fail

    sleu $1, $2, $2 // 0 <= 0
    beqz $1, fail
    sleu $1, $2, $3 // 0 <= 1
    beqz $1, fail
    sleu $1, $2, $4 // 0 <= 0xffff
    beqz $1, fail
    sleu $1, $2, $5 // 0 <= 0xfffe
    beqz $1, fail
    sleu $1, $3, $2 // 1 <= 0
    bnez $1, fail
    sleu $1, $3, $3 // 1 <= 1
    beqz $1, fail
    sleu $1, $3, $4 // 1 <= 0xffff
    beqz $1, fail
    sleu $1, $3, $5 // 1 <= 0xfffe
    beqz $1, fail
    sleu $1, $4, $2 // 0xffff <= 0
    bnez $1, fail
    sleu $1, $4, $3 // 0xffff <= 1
    bnez $1, fail
    sleu $1, $4, $4 // 0xffff <= 0xffff
    beqz $1, fail
    sleu $1, $4, $5 // 0xffff <= 0xfffe
    bnez $1, fail
    sleu $1, $5, $2 // 0xfffe <= 0
    bnez $1, fail
    sleu $1, $5, $3 // 0xfffe <= 1
    bnez $1, fail
    sleu $1, $5, $4 // 0xfffe <= 0xffff
    beqz $1, fail
    sleu $1, $5, $5 // 0xfffe <= 0xfffe
    beqz $1, fail

    sge $1, $2, $2 // 0 >= 0
    beqz $1, fail
    sge $1, $2, $3 // 0 >= 1
    bnez $1, fail
    sge $1, $2, $4 // 0 >= -1
    beqz $1, fail
    sge $1, $2, $5 // 0 >= -2
    beqz $1, fail
    sge $1, $3, $2 // 1 >= 0
    beqz $1, fail
    sge $1, $3, $3 // 1 >= 1
    beqz $1, fail
    sge $1, $3, $4 // 1 >= -1
    beqz $1, fail
    sge $1, $3, $5 // 1 >= -2
    beqz $1, fail
    sge $1, $4, $2 // -1 >= 0
    bnez $1, fail
    sge $1, $4, $3 // -1 >= 1
    bnez $1, fail
    sge $1, $4, $4 // -1 >= -1
    beqz $1, fail
    sge $1, $4, $5 // -1 >= -2
    beqz $1, fail
    sge $1, $5, $2 // -2 >= 0
    bnez $1, fail
    sge $1, $5, $3 // -2 >= 1
    bnez $1, fail
    sge $1, $5, $4 // -2 >= -1
    bnez $1, fail
    sge $1, $5, $5 // -2 >= -2
    beqz $1, fail

    sgeu $1, $2, $2 // 0 >= 0
    beqz $1, fail
    sgeu $1, $2, $3 // 0 >= 1
    bnez $1, fail
    sgeu $1, $2, $4 // 0 >= 0xffff
    bnez $1, fail
    sgeu $1, $2, $5 // 0 >= 0xfffe
    bnez $1, fail
    sgeu $1, $3, $2 // 1 >= 0
    beqz $1, fail
    sgeu $1, $3, $3 // 1 >= 1
    beqz $1, fail
    sgeu $1, $3, $4 // 1 >= 0xffff
    bnez $1, fail
    sgeu $1, $3, $5 // 1 >= 0xfffe
    bnez $1, fail
    sgeu $1, $4, $2 // 0xffff >= 0
    beqz $1, fail
    sgeu $1, $4, $3 // 0xffff >= 1
    beqz $1, fail
    sgeu $1, $4, $4 // 0xffff >= 0xffff
    beqz $1, fail
    sgeu $1, $4, $5 // 0xffff >= 0xfffe
    beqz $1, fail
    sgeu $1, $5, $2 // 0xfffe >= 0
    beqz $1, fail
    sgeu $1, $5, $3 // 0xfffe >= 1
    beqz $1, fail
    sgeu $1, $5, $4 // 0xfffe >= 0xffff
    bnez $1, fail
    sgeu $1, $5, $5 // 0xfffe >= 0xfffe
    beqz $1, fail

    sne $1, $2, $2 // 0 != 0
    bnez $1, fail
    sne $1, $2, $3 // 0 != 1
    beqz $1, fail
    sne $1, $2, $4 // 0 != -1
    beqz $1, fail
    sne $1, $2, $5 // 0 != -2
    beqz $1, fail
    sne $1, $3, $2 // 1 != 0
    beqz $1, fail
    sne $1, $3, $3 // 1 != 1
    bnez $1, fail
    sne $1, $3, $4 // 1 != -1
    beqz $1, fail
    sne $1, $3, $5 // 1 != -2
    beqz $1, fail
    sne $1, $4, $2 // -1 != 0
    beqz $1, fail
    sne $1, $4, $3 // -1 != 1
    beqz $1, fail
    sne $1, $4, $4 // -1 != -1
    bnez $1, fail
    sne $1, $4, $5 // -1 != -2
    beqz $1, fail
    sne $1, $5, $2 // -2 != 0
    beqz $1, fail
    sne $1, $5, $3 // -2 != 1
    beqz $1, fail
    sne $1, $5, $4 // -2 != -1
    beqz $1, fail
    sne $1, $5, $5 // -2 != -2
    bnez $1, fail

    sneu $1, $2, $2 // 0 != 0
    bnez $1, fail
    sneu $1, $2, $3 // 0 != 1
    beqz $1, fail
    sneu $1, $2, $4 // 0 != 0xffff
    beqz $1, fail
    sneu $1, $2, $5 // 0 != 0xfffe
    beqz $1, fail
    sneu $1, $3, $2 // 1 != 0
    beqz $1, fail
    sneu $1, $3, $3 // 1 != 1
    bnez $1, fail
    sneu $1, $3, $4 // 1 != 0xffff
    beqz $1, fail
    sneu $1, $3, $5 // 1 != 0xfffe
    beqz $1, fail
    sneu $1, $4, $2 // 0xffff != 0
    beqz $1, fail
    sneu $1, $4, $3 // 0xffff != 1
    beqz $1, fail
    sneu $1, $4, $4 // 0xffff != 0xffff
    bnez $1, fail
    sneu $1, $4, $5 // 0xffff != 0xfffe
    beqz $1, fail
    sneu $1, $5, $2 // 0xfffe != 0
    beqz $1, fail
    sneu $1, $5, $3 // 0xfffe != 1
    beqz $1, fail
    sneu $1, $5, $4 // 0xfffe != 0xffff
    beqz $1, fail
    sneu $1, $5, $5 // 0xfffe != 0xfffe
    bnez $1, fail

    seq $1, $2, $2 // 0 == 0
    beqz $1, fail
    seq $1, $2, $3 // 0 == 1
    bnez $1, fail
    seq $1, $2, $4 // 0 == -1
    bnez $1, fail
    seq $1, $2, $5 // 0 == -2
    bnez $1, fail
    seq $1, $3, $2 // 1 == 0
    bnez $1, fail
    seq $1, $3, $3 // 1 == 1
    beqz $1, fail
    seq $1, $3, $4 // 1 == -1
    bnez $1, fail
    seq $1, $3, $5 // 1 == -2
    bnez $1, fail
    seq $1, $4, $2 // -1 == 0
    bnez $1, fail
    seq $1, $4, $3 // -1 == 1
    bnez $1, fail
    seq $1, $4, $4 // -1 == -1
    beqz $1, fail
    seq $1, $4, $5 // -1 == -2
    bnez $1, fail
    seq $1, $5, $2 // -2 == 0
    bnez $1, fail
    seq $1, $5, $3 // -2 == 1
    bnez $1, fail
    seq $1, $5, $4 // -2 == -1
    bnez $1, fail
    seq $1, $5, $5 // -2 == -2
    beqz $1, fail

    sequ $1, $2, $2 // 0 == 0
    beqz $1, fail
    sequ $1, $2, $3 // 0 == 1
    bnez $1, fail
    sequ $1, $2, $4 // 0 == 0xffff
    bnez $1, fail
    sequ $1, $2, $5 // 0 == 0xfffe
    bnez $1, fail
    sequ $1, $3, $2 // 1 == 0
    bnez $1, fail
    sequ $1, $3, $3 // 1 == 1
    beqz $1, fail
    sequ $1, $3, $4 // 1 == 0xffff
    bnez $1, fail
    sequ $1, $3, $5 // 1 == 0xfffe
    bnez $1, fail
    sequ $1, $4, $2 // 0xffff == 0
    bnez $1, fail
    sequ $1, $4, $3 // 0xffff == 1
    bnez $1, fail
    sequ $1, $4, $4 // 0xffff == 0xffff
    beqz $1, fail
    sequ $1, $4, $5 // 0xffff == 0xfffe
    bnez $1, fail
    sequ $1, $5, $2 // 0xfffe == 0
    bnez $1, fail
    sequ $1, $5, $3 // 0xfffe == 1
    bnez $1, fail
    sequ $1, $5, $4 // 0xfffe == 0xffff
    bnez $1, fail
    sequ $1, $5, $5 // 0xfffe == 0xfffe
    beqz $1, fail

    ori $15, $0, 0xdead
    sw $15, 0xfffff($0)
done:
    j done

fail:
    ori $15, $0, 0x1
    sw $15, 0xfffff($0)
    j done
    
data:
    .word 0
