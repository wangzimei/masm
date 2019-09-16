
; 汇编语言 2e.pdf
; 王爽
; p272, 实验 13 编写、应用中断例程
; experiment
;
; p272 - p273, 2. 编写并安装 int 7ch 中断例程, 完成 loop 指令的功能.
; 参数:
;   cx - 循环次数
;   bx - 位移
;
; 对程序进行单步跟踪, 注意观察 int、iret 执行前后 cs、ip 和栈中的状态.
; 在屏幕中间显示 80 个叹号.
;
; 这和 p266, 问题: 用 7ch 中断例程完成 loop 指令的功能 一样, 也就有同样的隐含前提, 要求 cx 至少是 1.
; 用法限制了 isr 的实现必须是先递减 cx 再判断是否是零.
; p266 的程序在 13m-3.asm, 文件名可能会改变.

       .model   tiny
       .code
        org     100h
start:
        ; 0:1f0 -> ax 和 dx
        mov     ax, 0
        mov     ds, ax
        mov     ax, ds:[7ch * 4]
        mov     dx, ds:[7ch * 4 + 2]

        ; ax 和 dx -> data
        mov     data[0], ax
        mov     data[2], dx

        ; isr 和 cs -> 0:1f0
        mov     ds:[7ch * 4], offset isr
        mov     ds:[7ch * 4 + 2], cs

        ; 使用
        mov     ax, 0b800h
        mov     es, ax
        mov     di, 160 * 12

        mov     bx, offset s - offset se
        mov     cx, 80

s:      mov     byte ptr es:[di], '!'
        add     di, 2
        int     7ch

se:     ; data -> ax 和 dx
        mov     ax, 0
        mov     ds, ax
        mov     ax, data[0]
        mov     dx, data[2]

        ; ax 和 dx -> 0:1f0
        mov     ds:[7ch * 4], ax
        mov     ds:[7ch * 4 + 2], dx

       .exit    0

isr:    push    bp
        mov     bp, sp
        dec     cx
        jcxz    isr_1
        add     [bp + 2], bx
isr_1:  pop     bp
        iret

data    word    2 dup (?)
        end     start
