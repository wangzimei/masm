
; 汇编语言 2e.pdf
; 王爽
; p221 - p222, 课程设计 1
; curriculum design
;
; 整个课程中一共有两个课程设计, 编写两个比较综合的程序, 这是第一个.
;
; 任务: 将实验 7 中 Power idea 公司的数据按照图 10.2 所示的格式在屏幕上显示出来.
; 图 10.2 在书本 p221
;
; 注意事项:
;   1. 编写一个 dword 转化为字符串的程序
;   名称: dtoc
;   功能: 将 dword 转变为表示十进制数的字符串, 以 0 结尾.
;   参数:
;       ax - dword 型数据的低 16 位
;       dx - dword 型数据的高 16 位
;       ds:si - 字符串首地址
;   返回: 无
;   2. 注意除法溢出. 可以使用实验 10.2 中设计的 divdw 来解决.

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
        dword     16000,   24486,   50065,   97479,  140417
        dword    197514,  345980,  590827,  803530, 1183000
        dword   1843000, 2759000, 3753000, 4649000, 5937000

        ; 每年的雇员人数
        word    3, 7,     9,    13,    28,    38
        word     130,   220,   476,   778,  1001
        word    1442,  2258,  2793,  4037,  5635
        word    8226, 11542, 14430, 15257, 17800
data    ends

table   segment
        ; COUNT 行, 每行 35 个字符
        byte    COUNT dup (35 dup(' '))
        ;                   year total-inco employee averagepci
        ;                   01234567890123456789012345678901234
        ;                   0         1         2         3
table   ends

stack   segment stack
        word    16 dup (?)
stack   ends

code    segment 'code'
start:  mov     ax, data
        mov     es, ax

        mov     ax, table
        mov     ds, ax

        mov     bx, 0
        mov     si, 0
        mov     bp, ANCHOR2
        mov     cx, COUNT

fill:   ; year 年份
        mov     ax, es:[bx]
        mov     [si], ax
        mov     ax, es:[bx + 2]
        mov     [si + 2], ax

        ; total income 总收入, 低位放入 ax, 高位放入 dx
        push    si

        add     si, 5
        mov     ax, es:[bx + ANCHOR1]
        mov     dx, es:[bx + ANCHOR1 + 2]
        call    dtoc

        add     si, ax
        mov     [si], byte ptr ' ' ; 把结尾的 0 换成空格

        pop     si
        mov     ax, es:[bx + ANCHOR1] ; dtoc 在 ax 中返回字符串长度, 覆盖了 ax 传入的值

        ; Number of Employees 雇员人数
        push    ax
        push    dx
        push    si

        add     si, 16
        mov     ax, es:[bp]
        mov     dx, 0
        call    dtoc

        add     si, ax
        mov     [si], byte ptr ' ' ; 把结尾的 0 换成空格

        pop     si
        pop     dx
        pop     ax

        ; average per capita income 人均收入 = (ax, dx) / cx
        push    cx
        mov     cx, es:[bp] ; cx 保存雇员人数
        call    divdw

        add     si, 25
        call    dtoc

        sub     si, 25
        pop     cx

        add     bx, 4
        add     bp, 2
        add     si, 35
        loop    fill

        ; 在屏幕上打印表格
        mov     cx, COUNT
        mov     dh, 2
        mov     dl, 15
        mov     si, 0

print:  mov     ax, cx ; push cx
        mov     cx, 2
        call    show_str
        mov     cx, ax ; pop cx

        inc     dh
        add     si, 35
        loop    print

        mov     ax, 4c00h
        int     21h

        ; dtoc 把 dword 转化为十进制表示的字符串
        ; ax - 低 16 位
        ; dx - 高 16 位
        ; ds:si - 字符串首地址
        ; 在 ax 中返回字符串的长度
dtoc:   push    bx ; 在逐位除 10 时保存字符串的长度；后来代替 si 作为字符指针
        push    cx ; jcxz
        push    dx

        mov     cx, 10
        mov     bx, 0

divide: call    divdw

        push    cx ; 这里入栈的是每次除 10 得到的余数
        inc     bx

        mov     cx, ax
        add     cx, dx ; 结果的高字 + 低字 = 0 说明结果是 0
        jcxz    end_divide
        mov     cx, 10
        jmp     divide

end_divide:
        mov     ax, bx ; 返回字符串的长度
        mov     cx, bx
        mov     bx, si ; 不改动 si, 因此也不需要保存和恢复 si

transform:
        pop     dx
        add     dx, 30h
        mov     [bx], dl
        inc     bx
        loop    transform

        mov     [bx], byte ptr 0

        pop     dx
        pop     cx
        pop     bx
        ret

        ; 从 实验 10, 1. 显示字符串 中拷贝来的代码
        ;
        ; 名称: show_str
        ; 功能: 在指定位置, 用指定颜色, 显式一个用 0 结束的字符串
        ; 参数:
        ;   dh - 行号, 取值 [0, 24]
        ;   dl - 列号, 取值 [0, 79]
        ;   cl - 颜色
        ;   ds:si - 字符串首地址
        ; 返回: 无
show_str:
        push    ax
        push    bx
        push    cx
        push    di
        push    es
        push    si

        ; 字符串在屏幕上的起始地址 = 0b800h + (line * 80 + column) * 2
        ; 用 bl 指定一个 8 位乘法. 乘法之后还要用到 dl, 而 16 位乘法会影响 dx 寄存器.
        mov     ah, 0
        mov     al, dh  ; x = line
        mov     bh, 0
        mov     bl, 80
        mul     bl      ; x = x * 80
        mov     bl, dl
        add     ax, bx  ; x += column
        shl     ax, 1   ; x *= 2

        ; es:di 指向屏幕缓冲区
        ; 参数 cl 指出了颜色, 循环中要使用 cx 所以把 cl 的内容放入 bl
        mov     di, ax
        mov     ax, 0b800h
        mov     es, ax
        mov     bl, cl
        mov     ch, 0

write:  mov     cl, [si]
        jcxz    show_str_epilog

        mov     al, [si]
        mov     es:[di], al
        mov     es:[di + 1], bl

        inc     si
        add     di, 2
        jmp     write

show_str_epilog:
        pop     si
        pop     es
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret

        ; 从 实验 10, 2. 解决除法溢出的问题 中拷贝来的代码
        ;
        ; 名称: divdw
        ; 功能: 进行不会溢出的除法, 被除数是 dword, 除数是 word, 结果是 dword
        ;   * 书上没有说余数是什么类型, 不过既然放 cx 里面那就是 word 型. 余数不会大于除数.
        ; 参数:
        ;   ax - dword 被除数的低 16 位
        ;   dx - dword 被除数的高 16 位
        ;   cx - 除数
        ; 返回:
        ;   ax - 结果低 16 位
        ;   dx - 结果高 16 位
        ;   cx - 余数
divdw:  push    bx
        push    si

        mov     bx, ax  ; ax = L, bx = L, cx = N, dx = H
        mov     ax, dx  ; ax = H, bx = L, cx = N, dx = H
        mov     dx, 0   ; ax = H, bx = L, cx = N, dx = 0
        div     cx      ; ax = int(H / N), bx = L, cx = N, dx = rem(H / N)

        ; 如果这里使用 xchg ax, bx 则能省下 si 寄存器
        mov     si, ax  ; ax = int(H / N), bx = L, cx = N, dx = rem(H / N), si = int(H / N)
        mov     ax, bx  ; ax = L, bx = L, cx = N, dx = rem(H / N), si = int(H / N)
        div     cx      ; ax = int([rem(H / N) * 65536 + L] / N), bx = L, cx = N,
                        ; dx = rem([rem(H / N) * 65536 + L] / N), si = int(H / N)

        mov     cx, dx
        mov     dx, si

        pop     si
        pop     bx
        ret

code    ends
        end     start
