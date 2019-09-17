
; 文件名字不能是 com1.asm, com1 是 dos 保留字
; 生成 com 文件, 又没有在 start 前写 org 100h, 所以所有的偏移量都需要自己加上 100h
;
; ml -AT -Foout\ 8086/abc/com-1.asm -Feout\

xxx     segment

start:

; 下面两句使用了变量名, masm 认为使用变量名就是想使用其值, 所以改写为 [var]
; 加上方括号后, masm 一看这是要取内存的值, 再一看没有 assume ds:xxx, 就给下面两句加上 cs 重写
; 这 masm 还真是功能强大, 不由分说上来就是一套 combo, 看得我目瞪 go die
; 好在当我写 var 的时候确实是想使用 var 的值而不是地址, 否则 bug 就出现了
        mov     ax, var + 100h
        mov     bx, arr[100h]

; 下面这句使用代码标签, masm 不会给代码标签加方括号; 并且由于代码标签默认段是 cs, 所以 masm 也没有加寄存器重写
        mov     dx, data[100h]

        mov     ah, 9
        int     21h

        ret

data:
str1    db      "sample string$"
var     word    1
arr     word    1, 2

xxx     ends
        end start
