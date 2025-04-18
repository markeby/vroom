.equ SYS_WRITE, 64

.text
.align 2
.globl _start
_start:
    la sp, stack
    la x1, data_buffer
    ld t0, 0(x1)

    li a0, 100
 loop_back:

    sd t0,  0(x1)
    sd t0,  8(x1)
    sd t0, 16(x1)
    sd t0, 24(x1)
    sd t0, 32(x1)
    sd t0, 40(x1)
    sd t0, 48(x1)
    sd t0, 56(x1)

    add a0, a0, -1
    bnez a0, loop_back

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
data_buffer:
.dword 0xa5a5a5a5a5a5a5a5
.dword 0x1111111111111111
.dword 0x2222222222222222
.dword 0x3333333333333333
.dword 0x4444444444444444
.dword 0x5555555555555555
.dword 0x6666666666666666
.dword 0x7777777777777777
.dword 0x8888888888888888
.dword 0x9999999999999999
.dword 0xaaaaaaaaaaaaaaaa
.dword 0xbbbbbbbbbbbbbbbb
.dword 0xcccccccccccccccc
.dword 0xdddddddddddddddd
.dword 0xeeeeeeeeeeeeeeee
.dword 0xffffffffffffffff
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
