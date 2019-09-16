
; 汇编语言 2e.pdf
; 王爽
; p271, 杂项
; miscellaneous
;
; p271, 13.7 dos 中断例程应用
; p271, 编程：在屏幕的第 5 行 12 列显示字符串 Welcome to masm!.
;
; dos 提供了 21h 号中断, 以前我们一直使用它的 4ch 号子程序, 功能是程序返回, 可以在 al 中提供返回值.
;
; ah = 9 表示调用 21h 号中断例程的 9 号子程序, 功能是在光标位置显示字符串, 参数是
; ds:dx 指向要显示字符串的地址, 该字符串要以 $ 结尾.
;
; 因此下面的程序要使用 bios 提供的 10h 号中断设置光标位置, 然后使用 dos 提供的 21h 号中断显示字符串.
;
; .model tiny 生成 com 程序, 这种程序从 100h 而不是从 0 开始执行, 入口点后的所有语句都有 100h 的偏移,
; 所以如果不在 start 之前加上 org 100h 就要在取 offset 之后加上 100h.

       .model   tiny
       .code
start:
        mov     ah, 2   ; 置光标
        mov     bh, 0   ; 第 0 页
        mov     dh, 5   ; dh 放行号, 第  5 行
        mov     dl, 12  ; dl 放列号, 第 12 列
        int     10h

        mov     dx, cs
        mov     ds, dx
        mov     dx, offset data + 100h
        mov     ah, 9
        int     21h

       .exit    0

data    byte    'Welcome to masm!$'
        end     start
