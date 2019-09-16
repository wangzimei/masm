
; 汇编语言 2e.pdf
; 王爽
; p164 - p168, 问题 7.7 和问题 7.8
; problem
;
; 将 datasg 段中每个单词改为大写字母
;
; 因为这个程序需要嵌套的循环, 在使用 cx 时会有麻烦. 外层循环开始前需要设置 cx, 内层循环开始前也需要设置 cx.
; 可以在数据段开辟一个字保存外层的循环计数, 但当需要多个循环计数时该方法就不实用了.
; 书中给出的方法是使用栈.
;
; segment 后跟 stack 指明该段是栈, 就不会再有连接器警告 L4021: 没有栈; 并且进入程序前已经正确设置了 ss:sp

datasg  segment
        db 'ibm             '
        db 'dec             '
        db 'dos             '
        db 'vax             '
datasg  ends

stacksg segment stack
        dw 8 dup (0)
stacksg ends

codesg  segment
start:  mov     ax, datasg
        mov     ds, ax
        mov     bx, 0

        mov     cx, 4
outer:  push    cx
        mov     si, 0

        mov     cx, 3
inner:  mov     al, [bx + si]
        and     al, 11011111b
        mov     [bx + si], al
        inc     si
        loop    inner

        add     bx, 16
        pop     cx
        loop    outer

        mov     ax, 4c00h
        int     21h
codesg  ends
end start
