// JAL + JR/JALR test for word-addressed PC design
// Expected final state after run:
// x1 = 2    (set inside subroutine)
// x2 = 5    (written after return)
// x3 = 7    (x1 + x2)
// x4 = 6    (jal stores return address in words, expected PC index after jal)
// mem[0] = 7
//
// The instruction after jal must be skipped until the subroutine returns.

addi x1, x0, 0
addi x2, x0, 0
jal  x4, func
addi x2, x0, 5
add  x3, x1, x2
sw   x3, 0(x0)
halt

func:
addi x1, x0, 2
nop
nop
nop
jr   x4

