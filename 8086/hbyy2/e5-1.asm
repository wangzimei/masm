
; 汇编语言 2e.pdf
; 王爽
; p143 - p144, 实验 5(1)
; experiment
;
; 1. CPU 执行程序, 程序返回前, data 段中的数据是多少?
; 没变化
;
; 2. CPU 执行程序, 程序返回前, cs = __, ss = __, ds = __.
; cs = 0x0606, ss = 0x0605, ds = 0x0604
; ES 未在代码中赋值, = 第一个段（这里是 data） - 10h（基地址 10h = 256 字节） = 0x05f4
;
; 3. 设程序加载后 code 段的地址为 X, 则 data 段的地址为 __, stack 段的地址为 __.
; data = X - 20h, stack = X - 10h

assume cs: code, ds: data, ss: stack

data segment
dw 123h, 456h, 789h, 0abch, 0defh, 0fedh, 0cbah, 987h
data ends

stack segment
dw 0, 0, 0, 0, 0, 0, 0, 0
stack ends

code segment
start:
mov     ax, stack
mov     ss, ax
mov     sp, 16

mov     ax, data
mov     ds, ax

push    ds:[0]
push    ds:[2]
pop     ds:[2]
pop     ds:[0]

mov     ax, 4c00h
int     21h
code ends
end start
