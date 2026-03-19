// Branch taken / not-taken / flush test
// Expected final state after run:
// x1 = 3
// x2 = 3
// x3 = 1      (the addi x3,99 must be flushed)
// x4 = 2
// x5 = 0      (the addi x5,77 must be flushed)
// x6 = 3
// mem[0] = 3

addi x1, x0, 3
addi x2, x0, 3
beq  x1, x2, taken
addi x3, x0, 99

taken:
addi x3, x0, 1
bne  x1, x2, wrong
addi x4, x0, 2
beq  x1, x1, skip
addi x5, x0, 77

wrong:
nop

skip:
add  x6, x3, x4
sw   x6, 0(x0)
halt
