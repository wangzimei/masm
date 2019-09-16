
; 汇编语言 2e.pdf
; 王爽
; p157 - p158, 问题 7.2
; problem
;
; 用 si 和 di 将字符串 "welcome to masm!" 复制到它后面的数据区中.
; 这里尝试一下在 tiny 程序里使用多个逻辑段. 
;
; p7-2.asm 把数据和代码都放到了代码段, 因为 com 文件从 0x100 开始执行所以数据放在了代码后面,
; 并使用了一个标号指出数据的开始地址. 由于想使用匿名数据, 所以给出标号的办法不太好.
;
; Microsoft MASM 6.1 Programmer's Guide.pdf, p67, Controlling the Segment Order
;
; You can usually ignore segment ordering. However, it is important whenever you
; want certain segments to appear at the beginning or end of a program or when you
; make assumptions about which segments are next to each other in memory. For
; tiny model (.COM) programs, code segments must appear first in the executable
; file, because execution must start at the address 100h.
;
; 上面说 tiny 总是从 0x100 开始执行, 没说的是, 似乎这内存中的 0x100 就是 tiny 文件源代码中的
; 第一条语句, 无论该语句是指令还是分配的空间. 因此如果还像以前那样安排代码,
; data segment
; ...
; data ends
;
; code segment
; ...
; code ends
; 那汇编之后的程序会把 data 段分配的字节也解释为指令. 由于 data 在文件的开头, 所以从 data 里
; 解释出的指令开始执行. 为了从 code 开始执行需要一个段重排, 要么通过同时指定数据段和代码段
; data segment 'data'
; code segment 'code'
; 要么使用 .data 和 .code
;
; 段重排的问题解决了, 现在可以在 com 源代码中任意放置逻辑段并保证执行时总是从代码段开始.
; 接下去的问题是如何使用数据段中的匿名内存.
;
; 虽然运行生成的程序发现数据紧挨在代码之后, 但不知道这种排列方式是否有保证. 另外由于数据在不同的段,
; tiny 又不能引用段名, 所以不知道如何定位其他逻辑段的地址.
;
; 下面的程序不正确, 因为首先 offset xx1 使用的是具名变量而不是匿名变量,
; 其次 offset xx1 得到的是 0 而不是运行时的真实地址.

.8086
.model tiny

data segment 'data'
xx1 db 'welcome to masm!'
xx2 db 16 dup ('.')
data ends

code segment 'code'
startup:
mov cx, 16
mov si, offset xx1
mov di, offset xx2
rep movsb

mov ax, 4c00h
int 21h
code ends
end startup
