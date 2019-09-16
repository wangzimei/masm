
; 汇编语言 2e.pdf
; 王爽
; p264, 杂项
; miscellaneous
;
; p263, 13.2 编写供应用程序调用的中断例程
; p264, 问题二: 编写, 安装中断 7ch 的中断例程.
;
; 功能: 将一个全是字母, 以 0 结尾的字符串转化为大写
; 参数: ds:si 指向字符串首地址
; 应用举例: 将 data 段中的字符串转化为大写
;
; 问题 1. 在 isr 中使用 push 时 ss:sp 是啥?
;
; 问题 2. 因为修改了中断向量表又不恢复, 我说这是不负责任地退出. 可是在 code view (cv) 中查看时发现,
; 不关闭 cv 而重启程序, 内存地址 0000:01f0 (0x7c * 4 = 0x1f0) 之后的那些字节 (包括中断向量和 0:200 的 isr)
; 保持修改状态; 重启 cv 后 0000:01f0 之后的那些字节清零了.
; 问题 2.1: 这是单纯的清零, 还是恢复为之前的状态 (之前的状态是 0) ?
; 问题 2.2: 谁在清零或恢复? cv 吗?
;
; 为了搞清楚问题 2 我重启 dosbox, 此时中断向量表 ivt 是未修改状态, 0000:01f0 之后都是些 0.
; 2.1.1. cv 调试本程序, 0000:01f0 之后都是些 0, 执行本程序以修改 ivt
; 2.1.2. 在 cv 中重启程序, 0000:01f0 之后保持修改状态
; 2.1.3. 重启 cv 调试本程序, 0000:01f0 之后都是些 0
; 2.2.1. 退出 cv, 在 doxbox 中执行本程序
; 2.2.2. cv 调试本程序, 0000:01f0 之后是修改后的状态
;
; 因此猜测 cv 保存了 ivt 并在退出时恢复它. 所以 不负责任地退出 名副其实.

data    segment

        byte    'conversation', 0

data    ends
stack   segment stack

        word    8 dup (?)

stack   ends
code    segment 'code'

start:  ; 把 isr 拷贝到 0000:0200
        mov     ax, cs
        mov     ds, ax
        mov     si, offset capital

        mov     ax, 0
        mov     es, ax
        mov     di, 200h

        mov     cx, offset capital_end - offset capital
        cld
        rep     movsb

        ; 修改中断向量表的第 7ch 格
        mov     ax, 0
        mov     es, ax
        mov     word ptr es:[7ch * 4], 200h
        mov     word ptr es:[7ch * 4 + 2], 0

        ; 使用
        mov     ax, data
        mov     ds, ax
        mov     si, 0
        int     7ch        

        ; 不负责任地退出
        mov     ax, 4c00h
        int     21h

capital:
        push    si

capital_loop:
        cmp     byte ptr [si], 0
        je      capital_done

        and     byte ptr [si], 11011111b
        inc     si
        jmp     capital_loop

capital_done:
        pop     si
        iret

capital_end:
        nop

code    ends
        end     start
