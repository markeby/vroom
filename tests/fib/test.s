.equ SYS_WRITE, 64

.text
.align 2
.globl _start
_start:
    la sp, stack

    li a0, 0
    li a2, 1
    call fib

    li a1, 1
    bne a0, a1, fail

    li a0, 0
    li a2, 2
    call fib

    li a1, 2
    bne a0, a1, fail

    li a0, 0
    li a2, 3
    call fib

    li a1, 3
    bne a0, a1, fail

    li a0, 0
    li a2, 4
    call fib

    li a1, 5
    bne a0, a1, fail

    li a0, 0
    li a2, 5
    call fib

    li a1, 8
    bne a0, a1, fail

    li a0, 0
    li a2, 6
    call fib

    li a1, 13
    bne a0, a1, fail

pass:
    li t0, 1
    sd t0, tohost, t1
    ebreak
1:  j 1b

fail:
    la t0, fail_const
    ld t0, 0(t0)
    li t0, 1
    sd t0, tohost, t1
    ebreak;

fib:
    li a0, 1
    slti t0, a2, 2
    beqz t0, fib_ge_2
    ret

/*
    ; sp-8  = a2
    ; sp-16 = fib(n-1)
    ; sp-24 = fib(n-2)
    ; sp-32 = return PC
    */
fib_ge_2:
    add sp, sp, 32
    sd ra, -32(sp)
    sd a2, -8(sp)

    ld a2, -8(sp)
    add a2, a2, -1
    call fib
    sd a0, -16(sp)

    ld a2, -8(sp)
    add a2, a2, -2
    call fib
    sd a0, -24(sp)

    ld t0, -16(sp)
    ld t1, -24(sp)
    add a0, t0, t1

    ld ra, -32(sp)
    add sp, sp, -32
    ret

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

.align 4
fail_const:
.dword 0xdeadbeefdeadbeef

.align 4
stack:
.skip 4096

.section .tohost,"aw",@progbits
.globl tohost
.globl fromhost
.align 3
tohost: .dword 0
fromhost: .dword 0
