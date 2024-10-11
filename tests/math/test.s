.equ SYS_WRITE, 64

.text
.align 2
.globl _start
_start:

    li x1, 0xbb
    li x2, 0x555
    li x3, 0x01

    li x5, 6
    li x4, 0xaaa
loop_back_x4:
    sll x4, x4, 10
    add x4, x4, 0x2aa
    add x5, x5, -1
    bnez x5, loop_back_x4

    sll x5, x4, 1

    mv x6, x5
    add x7, x4, x5
    add x8, x5, x6
    addw x9, x4, x5
    addw x10, x5, x6
    sub x7, x4, x5
    sub x8, x5, x6
    subw x9, x4, x5
    subw x10, x5, x6
    xor x7, x4, x5
    xor x8, x5, x6

    sll x7, x4, x5
    sll x8, x5, x6
    sllw x9, x4, x5
    sllw x10, x5, x6

    srl x7, x4, x5
    srl x8, x5, x6
    srlw x9, x4, x5
    srlw x10, x5, x6

    sra x7, x4, x5
    sra x8, x5, x6
    sraw x9, x4, x5
    sraw x10, x5, x6

    slli x9, x5, 0x1
    slli x9, x5, 0x2
    slli x9, x5, 0x4
    slli x9, x5, 0x8
    slli x9, x5, 0x10

    srli x9, x5, 0x1
    srli x9, x5, 0x2
    srli x9, x5, 0x4
    srli x9, x5, 0x8
    srli x9, x5, 0x10

    srai x9, x5, 0x1
    srai x9, x5, 0x2
    srai x9, x5, 0x4
    srai x9, x5, 0x8
    srai x9, x5, 0x10

    li x1, 0x5
    li x2, 0xa
    mul x10, x1, x2

pass:
    li t0, 1
    sd t0, tohost, t1
    ebreak
1:  j 1b

syscall:
    la t0, syscall_buffer
    sd a0, 0(t0)
    sd a1, 8(t0)
    sd a2, 16(t0)
    sd a3, 24(t0)
    sd a4, 32(t0)
    sd a5, 40(t0)
    sd a6, 48(t0)
    sd a7, 56(t0)

    la t1, tohost
    sd t0, (t1)

    la t1, fromhost
1:  ld t2, (t1)
    beqz t2, 1b
    sd zero, (t1)

    ld a0, (t0)
    ret

.data
msg: .string "hello\n"

.align 3
syscall_buffer: .skip 64

.align 4
const_buffer:
.dword 0xaaaaaaaaaaaaaaaa
.skip 64

.section .tohost,"aw",@progbits
.globl tohost
.globl fromhost
.align 3
tohost: .dword 0
fromhost: .dword 0
