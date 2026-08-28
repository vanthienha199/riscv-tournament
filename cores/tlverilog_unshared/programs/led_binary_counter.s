.globl _start

.section .data
.align 4
scratch:
	.word 0x12345678
	.word 0x87654321
	.half 0xabcd
	.byte 0x5a

.section .text
_start:
	li x7, 0x20000000   /* LED MMIO (x7 / t2 — do not use as temp) */
	li x8, 0x10000000   /* data RAM (x8 / s0 — do not use as temp) */
	li x6, 0            /* ISA-exercise scratch */
	li x27, 0           /* LED counter in s11 (bit 0..; visible on GPIO [27:20]) */

loop:
	/* R-type (x9–x15: avoid t1/t2/s0 aliases on x6/x7/x8) */
	add  x9, x6, x6
	sub  x10, x9, x6
	and  x11, x9, x10
	or   x12, x9, x10
	xor  x13, x9, x10
	sll  x14, x9, x6
	srl  x15, x9, x6
	sra  a0, x9, x6
	slt  a1, x6, x9
	sltu a2, x6, x9

	/* I-type immediate */
	addi a3, x6, 3
	andi a4, a3, 0xff
	ori  a5, a3, 0x01
	xori a6, a3, 0xff
	slli a7, a3, 1
	srli x18, a3, 1
	srai s1, a3, 1
	slti s2, a3, 100
	sltiu s3, a3, 100

	/* Load/store (all widths) */
	lw   s4, 0(x8)
	lh   s5, 0(x8)
	lhu  s6, 0(x8)
	lb   s7, 0(x8)
	lbu  s8, 0(x8)
	sw   x6, 4(x8)
	sh   x6, 8(x8)
	sb   x6, 12(x8)

	/* U-type */
	lui  s9, 0x12345
	auipc s10, 0

	/* Branches (all six) */
	beq  x6, x6, 1f
	nop
1:	bne  x6, a3, 2f
	nop
2:	blt  x6, a3, 3f
	nop
3:	bge  a3, x6, 4f
	nop
4:	bltu x6, a3, 5f
	nop
5:	bgeu a3, x6, 6f
	nop
6:

	/* J-type and I-type jump */
	jal  ra, 7f
	nop
7:	jalr ra, ra, 0

	/* Fence (executes as no-op on this core) */
	fence

	/* Touch results so -Os cannot drop instruction paths. */
	add  x6, x6, x9
	add  x6, x6, x10
	add  x6, x6, x11
	add  x6, x6, x12
	add  x6, x6, x13
	add  x6, x6, x14
	add  x6, x6, x15
	add  x6, x6, a0
	add  x6, x6, a1
	add  x6, x6, a2
	add  x6, x6, a3
	add  x6, x6, a4
	add  x6, x6, a5
	add  x6, x6, a6
	add  x6, x6, a7
	add  x6, x6, x18
	add  x6, x6, s1
	add  x6, x6, s2
	add  x6, x6, s3
	add  x6, x6, s4
	add  x6, x6, s5
	add  x6, x6, s6
	add  x6, x6, s7
	add  x6, x6, s8
	add  x6, x6, s9
	add  x6, x6, s10

	/* One loop iteration per ISA pass; carries into bit 20+ are slow at ~6 MHz. */
	addi x27, x27, 1
	sw   x27, 0(x7)

	j loop
