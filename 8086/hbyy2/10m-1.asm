
; 汇编语言 2e.pdf
; 王爽
; p200, 杂项
; miscellaneous
;
; p200, 第 10 章 call 和 ret 指令
; p200, 10.1 ret 和 retf
;
; ret 相当于 pop ip, retf 相当于 pop ip 然后 pop cs
;
; 下面的程序中 ret 指令执行后 ip = 0, cs:ip 指向代码段的第一条指令

assume  cs: code

stack   segment
        byte    16 dup (0)
stack   ends

code    segment
        mov     ax, 4c00h
        int     21h

start:  mov     ax, stack
        mov     ss, ax
        mov     sp, 16
        mov     ax, 0
        push    ax
        mov     bx, 0
        ret
code    ends
end start
