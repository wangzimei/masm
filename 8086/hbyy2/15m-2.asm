
; 汇编语言 2e.pdf
; 王爽
; p292, 杂项
; miscellaneous
;
; p292, 15.5 安装新的 int 9 中断例程
; 任务：安装一个新的 int 9 中断例程
; 功能：在 dos 下按 f1 后改变当前屏幕的显示颜色, 其他的键照常处理.
;
; 原来的 int 9 中断向量保存在 0:200, 新的 isr 保存在 0:204
;
; 这个程序在 hyper-v 中似乎运行正常, 在 dosbox 中运行的时候有若干毛病,
; 1. 只要再调用一次 ml, 比如编译程序或者 ml /? 就不再接受任何输入了, 只能重启 dosbox.
;   不知道调用别的程序会不会这样, debug, link 和 cv 没有这毛病;
; 2. 在滚屏的时候经常出现后一半变成默认的黑底白字.

code    segment
start:
        mov     ax, cs
        mov     ds, ax
        mov     ax, 0
        mov     es, ax

        ; 0:24 -> 0:200; 0:26 -> 0:202
        mov     ax, es:[9 * 4]
        mov     bx, es:[9 * 4 + 2]
        mov     es:[200h], ax
        mov     es:[202h], bx

        ; ds:si - 源, es:di - 汇
        mov     si, offset isr
        mov     di, 204h
        mov     cx, offset isr_z - offset isr
        cld
        rep     movsb

        ; 04 02 00 00 -> 0:24
        cli
        mov     word ptr es:[9 * 4], 204h
        mov     word ptr es:[9 * 4 + 2], 0
        sti

        mov     ax, 4c00h
        int     21h

isr:    push    ax
        push    bx
        push    cx
        push    ds

        in      al, 60h
        int     80h ; 原来的 9 号中断向量被挪到了 200h 处, 80h * 4 = 200h

        cmp     al, 3bh ; f1 = 3bh
        jne     isr_2

        mov     ax, 0b800h
        mov     ds, ax
        mov     bx, 1
        mov     cx, 2000
s:      inc     byte ptr [bx]
        add     bx, 2
        loop    s

isr_2:  pop     ds
        pop     cx
        pop     bx
        pop     ax
        iret
isr_z:  nop

code    ends
stack   segment stack

        word    32 dup (?)

stack   ends
        end     start
