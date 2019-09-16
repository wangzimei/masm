
; 汇编语言 2e.pdf
; 王爽
; p201, 杂项
; miscellaneous
;
; p200, 10.1 ret 和 retf
; ret 相当于 pop ip, retf 相当于 pop ip 然后 pop cs
;
; 下面的程序中 retf 指令执行后 cs:ip 指向代码段的第一条指令.

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
        push    cs
        push    ax
        mov     bx, 0
        retf
code    ends
end start
