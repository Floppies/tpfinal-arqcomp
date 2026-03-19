// Forwarding + load-use hazard test
// Expected final state after run:
// x1 = 5
// x2 = 7
// x3 = 12
// x4 = 17
// x5 = 17
// x6 = 24
// mem[0] = 17
// mem[1] = 24

addi x1, x0, 5
addi x2, x0, 7
add  x3, x1, x2
add  x4, x3, x1
sw   x4, 0(x0)
lw   x5, 0(x0)
add  x6, x5, x2
sw   x6, 1(x0)
halt
