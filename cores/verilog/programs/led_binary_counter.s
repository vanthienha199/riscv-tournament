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
	li x7, 0x20000000   /* LED MMIO */
	li x8, 0x10000000   /* data RAM */
	li x6, 0            /* counter */

loop:
	/* R-type */
	add  t0, x6, x6
	sub  t1, t0, x6
	and  t2, t0, t1
	or   t3, t0, t1
	xor  t4, t0, t1
	sll  t5, t0, x6
	srl  t6, t0, x6
	sra  a0, t0, x6
	slt  a1, x6, t0
	sltu a2, x6, t0

	/* I-type immediate */
	addi a3, x6, 3
	andi a4, a3, 0xff
	ori  a5, a3, 0x01
	xori a6, a3, 0xff
	slli a7, a3, 1
	srli s0, a3, 1
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

	/* Fold every result into the LED value so -Os cannot drop instruction paths */
	add  x6, x6, t0
	add  x6, x6, t1
	add  x6, x6, t2
	add  x6, x6, t3
	add  x6, x6, t4
	add  x6, x6, t5
	add  x6, x6, t6
	add  x6, x6, a0
	add  x6, x6, a1
	add  x6, x6, a2
	add  x6, x6, a3
	add  x6, x6, a4
	add  x6, x6, a5
	add  x6, x6, a6
	add  x6, x6, a7
	add  x6, x6, s0
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
	addi x6, x6, 1
	andi x6, x6, 0xff
	sw   x6, 0(x7)

	j loop
