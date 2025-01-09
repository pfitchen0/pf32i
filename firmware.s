.equ GPIO_ADDR, 0x40000000

.section .text

.globl start

start:
    li gp, GPIO_ADDR
	li sp, 0x1800
.L0:
	li t0, 0
	sw t0, 0(gp)
	call wait
	li t0, 1
	sw t0, 0(gp)
	call wait
	j .L0

wait:
    li t0, 1
	slli t0, t0, 12
.L1:       
    addi t0, t0, -1
	bnez t0, .L1
	ret
