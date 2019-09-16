
; 汇编语言 2e.pdf
; 王爽
; p146, 实验 5(5)
; experiment
;
; 填写从 start 开始到 code ends 处的代码, 将 a 段和 b 段中的数据依次相加存入 c 段.
;
; 这里我只使用了一个段寄存器, 在循环中不断修改 ds;
; 也可以使用 ds, es, ss 三个段寄存器, 寻址时加上寄存器重写.

option nokeyword: <c>
.8086

assume cs: code

a segment
db 1, 2, 3, 4, 5, 6, 7, 8
a ends

b segment
db 1, 2, 3, 4, 5, 6, 7, 8
b ends

c segment
db 0, 0, 0, 0, 0, 0, 0, 0
c ends

x segment para stack
x ends

code segment
start:

mov cx, 8
add_a_b_to_c:

mov     bx, cx
dec     bx

mov     dx, a
mov     ds, dx
mov     al, [bx]

mov     dx, b
mov     ds, dx
add     al, [bx]

mov     dx, c
mov     ds, dx
mov     [bx], al

loop    add_a_b_to_c

mov     ah, 4c
int     21h

code ends
end start
