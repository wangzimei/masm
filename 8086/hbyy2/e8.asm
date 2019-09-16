
; 汇编语言 2e.pdf
; 王爽
; p197, 实验 8 分析一个奇怪的程序
; experiment
;
; 运行前思考：这个程序可以正确返回吗?
; 运行后再思考：为什么是这种结果?
;
; 写在运行之前：
; 可以正确返回吧. 把 s2 处的机器码拷贝到 s 处, s2 的短转移生成相对转移位移, 这个相对位移
; 以 s 为基点正好指向代码段的最开始, 这会执行 mov ax, 4c00h 和 int 21h.
;
; 运行后的思考：
; 和我想的一样.

assume  cs: codesg

codesg  segment

        mov     ax, 4c00h
        int     21h

start:  mov     ax, 0
s:      nop
        nop

        mov     di, offset s
        mov     si, offset s2
        mov     ax, cs:[si]
        mov     cs:[di], ax

s0:     jmp     short s

s1:     mov     ax, 0
        int     21h
        mov     ax, 0

s2:     jmp     short s1
        nop

codesg  ends
end start
