
; 汇编语言 2e.pdf
; 王爽
; p186, 问题 9.1
; problem
;
; 添加两条指令使该程序运行中把 s 处的一条指令复制到 s0

assume cs: codesg

codesg  segment
s:      mov ax, bx ; mov ax, bx 的机器码占两个字节
        mov si, offset s
        mov di, offset s0

        ; 添加两条指令
        mov ax, cs:[si]
        mov cs:[di], ax

s0:     nop ; nop 的机器码占一个字节
        nop

        mov ax, 4c00h
        int 21h
codesg  ends
end s
