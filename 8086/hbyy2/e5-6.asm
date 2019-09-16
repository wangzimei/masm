
; 汇编语言 2e.pdf
; 王爽
; p146 - p147, 实验 5(6)
; experiment
;
; 填写从 start 开始到 code ends 处的代码, 用 push 将 a 段中前 8 个字逆序放入 b 段.

.8086

assume cs: code

a segment
dw 1, 2, 3, 4, 5, 6, 7, 8, 9, 0ah, 0bh, 0ch, 0dh, 0eh, 0fh, 0ffh
a ends

b segment
dw 0, 0, 0, 0, 0, 0, 0, 0
b ends

x segment para stack
x ends

code segment
start:

mov ax, a
mov ds, ax
mov bx, 0

mov ax, b
mov ss, ax
mov sp, 10h

mov cx, 8
push_them:

push    [bx]
add     bx, 2

loop push_them

mov     ah, 4ch
int     21h

code ends
end start
