
; 汇编语言 2e.pdf
; 王爽
; p203, 检测点 10.3
; check point
;
; p203, 10.4 转移的目的地址在指令中的 call 指令
;
; call far ptr 标号 实现的是段间转移, 相当于
; push  cs
; push  ip
; jmp   far ptr 标号
;
; * 其中压栈的 ip 应该是指向 call 指令的下一条指令.
;
; 检测点 10.3, 下面的程序执行后, ax 中的数值为多少?
;
; ax = 1010h
; call 之后栈顶是 8, 栈顶下一个元素是 1000; 转到 s, pop ax 后 ax = 8, 8 + 8 = 10h;
; pop bx 后 bx = 1000h; 相加得到 1010h.

code    segment
start:  mov     ax, 0       ; 1000:0 b8 00 00
        call    far ptr s   ; 1000:3 9a 09 00 00 10
        inc     ax          ; 1000:8 40

s:      pop     ax          ; 1000:9 58

        add     ax, ax
        pop     bx
        add     ax, bx

        mov     ax, 4c00h
        int     21h
code    ends
end start
