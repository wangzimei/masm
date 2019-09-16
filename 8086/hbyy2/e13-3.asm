
; 汇编语言 2e.pdf
; 王爽
; p272, 实验 13 编写, 应用中断例程
; experiment
;
; p273, 3. 下面的程序分别在屏幕的 2, 4, 6, 8 行显示 4 句英文诗, 补全程序.
;
; 由于课本把标号和分配语句放在同一行比如 s1: byte 'xxx', masm 6.1 语法不支持它, 所以使用了 m510 选项.
; 当然 option m510 也改变了许多其它的设置.
;
; Microsoft MASM 6.1 Programmer's Guide.pdf
; > APPENDIX A - Differences Between MASM 6.1 and 5.1
; > Compatibility Between MASM 5.1 and 6.1
; > Using the OPTION Directive
; > OPTION M510
; > Code Labels when Defining Data with OPTION M510
; 
; p387
; MASM 5.1 allows a code label definition in a data definition statement if that
; statement does not also define a data label. MASM 6.1 also allows such definitions
; if OPTION M510 is enabled; otherwise it is illegal.
;
; ; Legal only with OPTION M510
; MyCodeLabel: DW 0
;
; 这个程序在 mov bx, offset s 之后, 还没有读取 bx 之前就设置了 bh, 这把 bx 的高字节抹掉了,
; 这还怎么用 bx?
;
; 针对下面代码的 org 100h, 我可以在使用 bx 时给它加上 100h 以补上高字节, 使得可以正常显示 4 行诗句.
;
; 可以说这是个有 bug 的程序, 它依赖于 s 的偏移不会大于 100h, 即 mov bx, offset s 后 bh 是 0; 
; 也可以说它没有 bug, 因为这程序生成为 exe 时 s 的偏移确实跟 0xff 还差很远; 
; 应该说这是个有潜在 bug 的程序.
;
; 若试图纠正它的潜在 bug, 能否通过在使用 bx 时给 bh 赋值 offset s 的高字节来解决呢?
; 不行. 考察两种情况, 
; 1. offset s 高字节是 0 而低字节较大比如是 0xff, 这时 add bx, 2 导致高字节从 0 变成 1, 而 offset s 的
;   高字节是 0, 给 bh 赋值 0 不是希望的结果, 希望 bh 赋值 1;
; 2. 循环次数非常多, 反复执行 add bx, 2 致使假若不清空 bh 则 bx 能达到好几百. 显然 100h 需要设 bh = 1 而
;   200h 需要设 bh = 2.
; 以上两种情况都是在循环的不同时期需要不同的 bh, 从而无法用一个常量去补偿 bh.
;
; 其实这个程序用 di 代替 bx 去寻址, bx 只用它的 bh 指定页号, 就没有潜在的 bug 和麻烦事了; 代价当然是多使用
; 了一个寄存器...

       .model   tiny
        option  m510
       .code
        org     100h ; 这个 org 会影响到后来的 offset, 不用 org 则需要自己调整 offset 得到的值
start:
        mov     ax, cs
        mov     ds, ax
        mov     bx, offset s
        mov     si, offset row
        mov     cx, 4

        ; ah = 2, int 10h 是 bios 设置光标位置, dh 放行号
ok:     mov     bh, 0
        mov     dh, [si]        ; mov dh, ___
        mov     dl, 0
        mov     ah, 2
        int     10h
        
        ; ah = 9, int 21h 是 dos 显示字符串, ds:dx 指向要显示字符串的地址
        mov     dx, [bx + 100h] ; mov dx, ___
        mov     ah, 9
        int     21h

        add     bx, 2           ; ___
        inc     si              ; ___
        loop    ok

       .exit    0

s1:     byte    'Good, better, best,$'
s2:     byte    'Never let it rest,$'
s3:     byte    'Till good is better,$'
s4:     byte    'And better, best.$'
s:      word    offset s1, offset s2, offset s3, offset s4
row:    byte    2, 4, 6, 8
        end     start