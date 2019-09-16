
; 汇编语言 2e.pdf
; 王爽
; p124, 程序 6.1
; application
;
; 程序当然应该是 program, 不过其缩写和问题 problem 混淆, 所以程序一律称为 application
;
; 这个程序展示了在程序段中分配空间用来存储数据
;
; 这个程序编译之后, 运行时 cs:ip 指向 code segment 的第一句话, 而本程序的前 16 字节是作为数据用的,
; 不希望当作命令执行. 这时书中给出指定程序入口的办法: end 后跟标号, 则标号指出程序的入口地址.
; 在本程序中就是在 dw ... 和 mov bx, 0 之间定义一个标号比如 start, 然后把最后的 end 写为 end start
;
; 按照这种思路可以这样安排程序的框架 (p137):
;
; assume cs: code
;
; code segment
;   ...
;   数据
;   ...
; start:
;   ...
;   代码
;   ...
; code ends
; end start
;
; 注意! 下面没有写 start 和 end start, 所以运行的时候结果不正确.

assume cs: code

code    segment
dw      123h, 456h, 789h, 0abch, 0defh, 0fedh, 0cbah, 987h

mov     bx, 0
mov     ax, 0

mov     cx, 8
s:
add     ax, cs:[bx]
add     bx, 2
loop    s

mov     ax, 4c00h
int     21h
code    ends
end
