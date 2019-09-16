
; 汇编语言 2e.pdf
; 王爽
; p131, 实验 4(2)
; experiment
;
; 目标：向内存 0:200 ~ 0:23f 依次传送数据 0 ~ 63（3fh）, 包括 mov ax, 4c00h 和 int 21h 在内只能使用 9 条指令
; 重点：理解并能灵活运用基地址 + 偏移量这种寻址方式
; 思路：伪指令不计入 9 条指令内。20h:3fh 填入 3fh, 20h:3eh 填入 3eh, 。。。, 20h:0 填入 0
;
; 从 visual studio 2010 开始不支持 .8086 了
;
; Answers.com > Wiki Answers > Categories > Technology > Computers > Computer Hardware
; > Microprocessors > Intel Microprocessors > Intel 8086 and 8088 > Difference between 80186 and 8086?
; http://wiki.answers.com/Q/Difference_between_80186_and_8086
;
; http://wiki.answers.com/Q/What_is_the_history_of_segments_registers
;
; masm 默认的处理器模式是 8086
; Microsoft MASM 6.1 Programmer's Guide.pdf, p58
; Specifying a Processor and Coprocessor
;
; masm 默认的内存模型是 small
; Microsoft MASM 6.1 Programmer's Guide.pdf, p36
; If you do not specify a memory model with .MODEL, the assembler assumes
; SMALL model (and therefore NEAR pointers).

.model tiny
.8086
.code

start:
mov     ax, 20h     ; 1. 设置 ds
mov     ds, ax      ; 2. 设置 ds
mov     cx, 3fh     ; 3. 循环计数供 loop 使用

transfer:
mov     bx, cx      ; 4. 循环计数刚好就是偏移量
mov     [bx], cl    ; 5. 往偏移量处拷贝循环计数。如果允许 [cx] 则能省一条指令
loop    transfer    ; 6. 结束。总共 6 + 2 = 8 条指令。

mov     ah, 4ch     ; 1. 倒数第二条指令
int     21h         ; 2. 最后一条指令
end start
