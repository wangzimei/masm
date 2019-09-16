
; 汇编语言 2e.pdf
; 王爽
; 重做 p146 的实验 5(5), 这次使用变量
; experiment
;
; 访问多个段时, 隐式或显式地使用寄存器重写.
;
; 使用多个段中的变量时需要用 assume 语句把变量访问同变量所在的段关联起来, 否则
; error A2074: cannot access label through segment registers
;
; 因为每次访问变量都需要关联其所在的段, 感觉不同段中可以有同名变量, 其实不是
; error A2005: symbol redefinition : <name>
;
; 汇编器知道 anchor2 属于段 b, 但它不会把段 b 关联到段寄存器. 想访问 anchor2 要么
; 用显式段寄存器重写, 要么用 assume 实施隐式段寄存器重写.
;
; assume 的一个作用是插入段寄存器重写, 比如 assume es: seg anchor2 之后, 出现的 add al, anchor2[bx]
; 会汇编成 add al, es:anchor2[bx]；但是 add al, [bx] 仍然使用 ds 作为段寄存器, 等价于（但不会汇编成）
; add al, ds:[bx]. 可以用 ds 显式重写, 这跟不重写一样, 不会生成显式重写的机器码；用其他段寄存器时则会.
;
; 必须自己调整段寄存器使它指向正确的段, assume 不管这个.
;
; 尝试使用 .model flat 时收到错误
; error A2085: instruction or register not accepted in current CPU mode
; 因为 FLAT keywords require .386 or above.
; http://msdn.microsoft.com/zh-cn/library/4603w9bd(v=vs.90).aspx
;
; 如果加上
; .386
; .model flat
; 则不再需要用 assume 关联变量和段, 不过这种 32 位平坦模式所有数据位于同一个段.
; 在 .model flat 中仍然可以使用 16 位段.
;
; 代码中写下的 segment 是所谓的逻辑段, 不同变量位于的内存块叫物理内存段, Intel 称作段落.
; 物理内存段和逻辑段的定义参见 Microsoft MASM 6.1 Programmer's Guide.pdf, p51
; CHAPTER 2 - Organizing Segments

option nokeyword: <c>
.8086

a segment
anchor1 db 1, 2, 3, 4, 5, 6, 7, 8
a ends

b segment
anchor2 db 1, 2, 3, 4, 5, 6, 7, 8
b ends

c segment
anchor3 db 0, 0, 0, 0, 0, 0, 0, 0
c ends

x segment para stack
x ends

code segment
start:

mov cx, 8
add_a_b_to_c:

mov     bx, cx
dec     bx

; 这里用的方法和 Second method 一样: 设置基地址, 然后用 assume 让汇编器插入段寄存器重写.
; First method 显式重写了段寄存器.
;
; assume  ds: a
; mov     dx, a
; mov     ds, dx
; mov     al, anchor1[bx]
;
; assume  ds: b
; mov     dx, b
; mov     ds, dx
; add     al, anchor2[bx]

; Microsoft MASM 6.1 Programmer's Guide.pdf, p78, First method
mov     dx, seg anchor1
mov     es, dx
mov     al, es:anchor1[bx]

; Microsoft MASM 6.1 Programmer's Guide.pdf, p79, Second method
mov     dx, seg anchor2
mov     es, dx
assume  es: seg anchor2
add     al, anchor2[bx]

assume  ds: c
mov     dx, c
mov     ds, dx
mov     anchor3[bx], al

loop    add_a_b_to_c

mov     ah, 4ch
int     21h

code ends
end start
