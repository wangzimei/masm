
; 汇编语言 2e.pdf
; 王爽
; p138，程序 6.3
; application
;
; 第 6.2 节: 在代码段中使用栈

assume cs: codesg

codesg  segment

dw      123h, 456h, 789h, 0abch, 9defh, 0fedh, 0cbah, 987h
dw      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; 16 个 word

start:
mov     ax, cs
mov     ss, ax
mov     sp, 30h ; 栈顶 ss:sp 指向 cs:30h

; 代码段 0 ~ 15 单元 (一单元是一字节) 中的 8 个 word 依次入栈

mov     bx, 0
mov     cx, 8

s:
push    cs:[bx]
add     bx, 2
loop    s

; 依次弹出 8 个 word 到代码段 0 ~ 15 单元中

mov     bx, 0
mov     cx, 8

s0:
pop     cs:[bx]
add     bx, 2
loop    s0

mov     ax, 4c00h
int     21h
codesg  ends
end start
