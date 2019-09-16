
; 汇编语言 2e.pdf
; 王爽
; p182 - p183, 实验 7
; experiment
;
; 第 8 章 数据处理的两个基本问题
; p171
;
; 8.1 bx、si、di 和 bp
; 8.2 机器指令处理的数据在什么地方
; 8.3 汇编语言中数据位置的表达
; 8.4 寻址方式
; 8.5 指令要处理的数据有多长
; 8.6 寻址方式的综合应用
; 8.7 div 指令
; 8.8 伪指令 dd
; 8.9 dup
;
; 实验 7 - 寻址方式在结构化数据访问中的应用
;
; 将 data 段中的数据按如下格式写入 table 段中, 并计算 21 年中的人均收入（取整）
; 年份 4 字节 - 空格 - 收入 4 字节 - 空格 - 雇员数 2 字节 - 空格 - 人均收入 2 字节 - 空格
;
; table:0       1975   16  3 ?
; table:10h     1976   22  7 ?
; table:20h     1977  382  9 ?
; table:30h     1978 1356 13 ?
; table:40h     1979 2390 28 ?
; table:50h     1980 8000 38 ?
; ...
; table:140h    1995 593x 1x ?
;
; 分析：最终得到的表里面每行都是字符和数字的混杂。
; ds:bx 指向 data 的年份和总收入, ds:si 指向 data 的雇员人数, ss:bp 指向 table
;
; ax - 中间结果, 被除数的低字, 商
; bx - data 段中年份的偏移地址, 总收入在 bx 的基础上偏移一个常量 ANCHOR1
; cx - 循环计数
; dx - 被除数的高字
; di - 作为除数的雇员人数
; si - data 段中雇员人数的偏移地址
; bp - table 段当前数据的偏移地址
; sp - 未使用
; cs - 指令指针
; ds - data 段的基址
; es - 未使用
; ss - table 段的基址
; ip - 指令指针
;
; 如果以 cx 的值为基础（21 - cx 或者 cx - 1）计算每个字段（年份、总收入、人数、平均收入、table 内的偏移）
; 的偏移, 可能会省下几个寄存器。本程序中计算偏移比较简单, 要么乘以 2 要么乘以 4, 都可以用移位代替。

COUNT = 21
ANCHOR1 = COUNT * 4
ANCHOR2 = COUNT * 8

data    segment

        ; 年份

        byte    '1975'
        byte    '1976', '1977', '1978', '1979', '1980'
        byte    '1981', '1982', '1983', '1984', '1985'
        byte    '1986', '1987', '1988', '1989', '1990'
        byte    '1991', '1992', '1993', '1994', '1995'

        ; 每年的总收入

        dword   16,  22,     382,    1356,    2390,    8000
        dword      1600,   24486,   50065,   97479,  140417
        dword    197514,  345980,  590827,  803530, 1183000
        dword   1843000, 2759000, 3753000, 4649000, 5937000

        ; 每年的雇员人数

        word    3, 7,     9,    13,    28,    38
        word     130,   220,   476,   778,  1001
        word    1442,  2258,  2793,  4037,  5635
        word    8226, 11542, 14430, 15257, 17800

data    ends

table   segment

        ; COUNT 行, 每行 16 个字符

        byte    COUNT dup ('year summ ne ?? ')

table   ends

stack   segment stack
stack   ends

code    segment
start:  mov     ax, data
        mov     ds, ax

        mov     ax, table
        mov     ss, ax

        mov     bx, 0
        mov     bp, 0
        mov     si, ANCHOR2
        mov     cx, COUNT

fill:   ; 年份
        mov     ax, [bx]
        mov     [bp], ax
        mov     ax, [bx + 2]
        mov     [bp + 2], ax

        ; 总收入, 低位放入 ax, 高位放入 dx
        mov     ax, [bx + ANCHOR1]
        mov     dx, [bx + ANCHOR1 + 2]
        mov     [bp + 5], ax
        mov     [bp + 7], dx

        ; 雇员人数, 放入 di
        mov     di, [si]
        mov     [bp + 10], di

        ; 人均收入 = (ax, dx) / di
        div     di
        mov     [bp + 13], ax

        add     bx, 4
        add     si, 2
        add     bp, 16
        loop    fill

        mov     ax, 4c00h
        int     21h
code    ends
end start
