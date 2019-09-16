
; 汇编语言 2e.pdf
; 王爽
; p272, 实验 13 编写、应用中断例程
; experiment
;
; p272, 1. 编写并安装 int 7ch 中断例程, 功能为显示一个用 0 结束的字符串, 中断例程安装在 0:200 处.
; 参数：
;   dh - 行号
;   dl - 列号
;   cl - 颜色
;   ds:si - 字符串首地址
;
; 这个字符串很短, 一行内就能显示, 所以不需要改变行号. 如果比较长, 则需要在 inc dl 之后判断 dl 是否大于 80
; 如果大于 80 则 dl 置 0 并增加行号 dh.

           .model   tiny
           .code
            org     100h
start:      mov     ax, 0
            mov     ds, ax
            mov     ds:[7ch * 4], offset isr
            mov     ds:[7ch * 4 + 2], cs

            ; 使用
            mov     dh, 10
            mov     dl, 10
            mov     cl, 2

            mov     ax, cs
            mov     ds, ax
            mov     si, offset data

            int     7ch

            ; 把 7ch 号中断向量清零并退出, 清零当然也是不负责任的做法.
            mov     ax, 0
            mov     ds, ax
            mov     word ptr ds:[7ch * 4], 0
            mov     word ptr ds:[7ch * 4 + 2], 0

           .exit    0

isr:        push    ax
            push    bx
            push    cx
            push    dx
            push    si

            mov     bh, 0   ; 第 0 页
            mov     bl, cl  ; 颜色
            mov     cx, 1   ; 字符重复个数

isr_loop:   cmp     byte ptr [si], 0
            je      isr_done

            ; 设置光标位置
            mov     ah, 2
            int     10h

            ; 在光标位置显示字符
            mov     ah, 9
            mov     al, [si] ; 字符
            int     10h

            inc     si
            inc     dl
            jmp     isr_loop

isr_done:   pop     si
            pop     dx
            pop     cx
            pop     bx
            pop     ax
            iret

data        byte    'Welcome to masm!', 0
            end     start
