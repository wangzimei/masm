
; 汇编语言 2e.pdf
; 王爽
; p202 - p203, 检测点 10.2
; check point
;
; p202, 10.3 依据位移进行转移的 call 指令
; cpu 执行 call 标号 时相当于进行
; push ip
; jmp near ptr 标号
;
; 应该是 push < call 指令 > 的下一条指令的地址吧?
;
; 检测点 10.2, 下面的程序执行后, ax 中的数值为多少?
; ax 的数值应该是 6, call 指令的下一条指令 inc ax 的地址.

code    segment
start:  mov     ax, 0       ; 1000:0 b8 00 00
        call    s           ; 1000:3 e8 01 00
        inc     ax          ; 1000:6 40

s:      pop     ax          ; 1000:7 58

        mov     ax, 4c00h
        int     21h
code    ends
end start
