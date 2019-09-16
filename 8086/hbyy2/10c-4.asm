
; 汇编语言 2e.pdf
; 王爽
; p204, 检测点 10.4
; check point
;
; p204, 10.5 转移地址在寄存器中的 call 指令
;
; 检测点 10.4, 下面的程序执行后, ax 中的数值为多少?
;
; ax = 11 = 0bh
; ax 赋值为 6, 跳转后下一条指令的地址 5 压栈, 让 bp 指向栈顶的 5, 此时 ax = 6, [bp] = 5,
; 相加后 ax = 11.

code    segment
start:  mov     ax, 6   ; 1000:0 b8 06 00
        call    ax      ; 1000:3 ff d0
        inc     ax      ; 1000:5 40
        mov     bp, sp  ; 1000:6
        add     ax, [bp]

        mov     ax, 4c00h
        int     21h
code    ends
end start
