
; 汇编语言 2e.pdf
; 王爽
; p131 - p132, 实验 4(3)
; experiment
;
; 目标：补全程序, 将 mov ax, 4c00h 之前的指令复制到 0:200h 处。调试并跟踪结果。
;
; 这个我不会做
; 1. 不知道起始地址, 可能是 0 或者 100h？
; 2. 不知道长度。p101 说用 debug 装入程序后 cx 中存放程序的长度, 难道要利用这一点？
;   那不用 debug 加载时程序就不能正常运行了？再者怎么减去最后两条指令的长度？

assume cs: code

code    segment
    mov     mov ax, ___
    mov     ds, ax
    mov     ax, 20h
    mov     es, ax
    mov     bx, 0
    mov     mov cx, ___

s:
    mov     al, [bx]
    mov     es:[bx], al
    inc     bx
    loop    s

    mov     ax, 4c00h
    int     21h
code    ends
end
