
; 汇编语言 2e.pdf
; 王爽
; p201 - p202, 检测点 10.1
; check point
;
; 补全程序实现从内存 1000:0000 处开始执行指令.

assume  cs: code

stack   segment stack
        byte    16 dup (0)
stack   ends

code    segment
start:  mov     ax, 1000h   ; mov ax, ___
        push    ax
        mov     ax, 0       ; mov ax, ___
        push    ax
        retf
code    ends
end start
