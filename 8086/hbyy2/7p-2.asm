
; 汇编语言 2e.pdf
; 王爽
; p157 - p158, 问题 7.2
; problem
;
; 用 si 和 di 将字符串 "welcome to masm!" 复制到它后面的数据区中.
;
; 问题：
;
; 使用 .model tiny 的时候标号的偏移量都少了 100h, 比如 startup 是程序的开始, 位于 100h,
; lea ax, startup 之后 ax 中是 0 而不是 100h. 在下面的代码中我给 data 加上了 100h 的偏移
; 使得程序能取得正确结果, 问题是这种写法很无厘头啊, 为啥加上 100h 而不是 58h, 3321h?
;
; 如果在 startup: 的前面一行加上 org 100h 则 lea ax, startup 后 ax = 0x100
;
; org 有时候不会成功, 见
; The ORG Directive and Actual Offsets
; http://support.microsoft.com/kb/39441/en-us
; The ORG directive in MASM does not necessarily produce an actual offset that matches
; the offset specified by "ORG XXX".
; 简而言之, 如果只有一个源文件用于生成 com 则 org 总会成功；如果有多个源文件, 或者生成的不是 .com
; 则 org 不一定生效, 实际偏移可能会偏大.
;
; Microsoft MASM 6.1 Programmer's Guide.pdf, p67, Controlling the Segment Order
; For tiny model (.COM) programs, code segments must appear first in the executable
; file, because execution must start at the address 100h.

.8086
.model tiny

code segment
startup:
mov cx, 16
mov si, data[100h]
mov di, data[110h]
rep movsb

mov ax, 4c00h
int 21h

data:
db 'welcome to masm!'
db 16 dup ('.')

code ends
end startup
