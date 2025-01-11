.section .text

.globl start

start:
	li   sp, 0x1800
	call main
	ebreak
