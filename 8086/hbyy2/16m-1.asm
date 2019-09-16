
; 汇编语言 2e.pdf
; 王爽
; p299, 杂项
; miscellaneous
;
; p299, 16.2 在其他段中使用数据标号
; 下面的程序将 data 段中 a 标号处的 8 个数据累加, 结果存储到 b 标号处的字中.
;
; 这和 p299 检测点 16.1, 16c-1.asm 的程序很像, 不同点在于
; 1. 结果保存在 word 而不是 dword 里面
; 2. 数据没有定义在代码段

data    segment

a       byte    1, 2, 3, 4, 5, 6, 7, 8
b       word    0

data    ends
code    segment
start:
        mov     ax, data
        mov     ds, ax
        mov     si, 0
        assume  ds: data

        mov     cx, 8
s:      mov     al, a[si]
        mov     ah, 0
        add     b, ax
        inc     si
        loop    s

        mov     ax, 4c00h
        int     21h

code    ends
        end     start
