
; 汇编语言 2e.pdf
; 王爽
; p314, 杂项
; miscellaneous
;
; p314, 17.3 字符串的输入
; 实现程序具备下面的功能:
; (1) 回显
; (2) 回车结束程序
; (3) 可以退格
;
; 这个程序和书上的程序不一样. 书上是在指定的行列显示输入的字符串, 用写入 0xb800:xxx 的方式；
; 我在当前光标处显示, 这需要获取和设置光标位置.
;
; 我猜测程序的隐含要求是只使用 int 16h 这一个中断, 但我需要 bios int 10h 的三个功能:
; ah =  2 - 设置光标
; ah =  3 - 获取光标
; ah = 10 - 显示字符
;
; bios 的 int 10h 有打印字符并移动光标的功能 (ah = 0xe), 但我不使用它而是自己调整光标位置.
; 16m-3.asm 用到了光标；13m-5.asm 在光标处显示字符.
;
; 这个程序看似简单实则相当麻烦, 难点有三:
; 1. 换行
; 2. 卷屏
; 3. 超过一屏后, 屏幕外的字符如何处理
;
; 书上给出的是个子程序, 它用栈保存输入的字符, 但这个栈的大小应该是多少却没有提. 书上的方式轻松避开了
; 如何保存多于一屏信息的问题, 而存在的问题是字符多时比较慢.

COLS    = 80
ROWS    = 25

code    segment 'code'
start:  mov     ah, 0
        int     16h

        call    printable
        jnc     @f
        call    append
        jmp     start

@@:     cmp     ah, 0eh ; 若 ah 包含 backspace 的扫描码
        jne     @f
        call    remove
        jmp     start

@@:     cmp     ah, 1ch ; enter
        jne     start
        mov     ax, 4c00h
        int     21h

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 在光标位置打印字符, 后移光标
        ;
        ; 人为限制:
        ;   如果将把字符打印在第 25 行之外则把光标位置设置在屏幕右下角, 不卷屏. 卷屏的话
        ;   卷出去的那行不容易保存, 将来一直删除到想把卷出去的内容再卷回来时就很麻烦.
        ;
        ; al - 要打印的字符

append: push    ax
        push    bx
        push    cx
        push    dx

        mov     ah, 3 ; 取光标位置, 结果 dh - 行, dl - 列
        mov     bh, 0 ; 第 0 页
        int     10h

        ; 这里假设光标的行数总是 < ROWS, 列数总是 < COLS
        cmp     dh, ROWS - 1
        jb      @f
        cmp     dl, COLS - 1
        jnb     @z ; 行数不小于 ROWS - 1 列数又不小于 COLS - 1 时啥都别干

        ; 执行到这里说明光标在右下角之前
@@:     mov     ah, 10 ; 在光标位置显示字符
        mov     cx, 1
        int     10h

        inc     dl
        cmp     dl, COLS
        jb      @f
        mov     dl, 0
        inc     dh
@@:     mov     ah, 2 ; 设置光标位置
        int     10h

@z:     pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 前移光标, 在光标位置写空格

remove: push    ax
        push    bx
        push    cx
        push    dx

        mov     ah, 3
        mov     bh, 0 ; 第 0 页
        int     10h

        dec     dl
        jns     @f

        ; 如果把列号减成负数了, 设置光标为上一行的最后一列.
        mov     dl, COLS - 1
        dec     dh
        jns     @f

        ; 如果把列号减成负数了, 设置光标在左上角.
        mov     dl, 0
        mov     dh, 0
@@:     mov     ah, 2
        int     10h
        
        ; 在光标位置显示空格
        mov     al, ' '
        mov     ah, 10
        mov     cx, 1
        int     10h

        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
        
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; al 给的 ascii 是不是可打印字符
        ;
        ; [32, 126] 号是可打印字符.
        ; http://zh.wikipedia.org/wiki/ASCII
        ;
        ; 参数
        ;   al - 字符的 ascii 码
        ; 返回
        ;   cf = 1, cy - 是可显示字符
        ;   cf = 0, nc - 不是
        ;
        ; 下面的函数只使用了依赖 cf 的指令, 没有使用依赖 zf 的指令（ja、jbe 等）

        printable equ printable_3

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 思路
        ;   我想让 [0, 255] 中的 [32, 126] 对应 cf = 1, 其余对应 cf = 0
        ;   1. 减去 32, 借位的数 < 32
        ;   2. 加上 255 - 126 + 32, 进位的数 > 126
        ;   3. 现在符合条件的 cf = 0, 不符合的 cf = 1, 翻转 cf
        ;
        ; 如果不需要保护 ax 那么该函数还是挺爽的（去掉 push 和 pop）.

printable_1:
        push    ax

        sub     al, 32
        jc      @f
        add     al, 255 - 126 + 32
@@:     cmc

        pop     ax
        ret
        
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 思路
        ;   1. 减  32 而 cf = 1 的这部分数字不符合, 翻转 cf 然后返回, 其余进行下一步；
        ;   2. 减 127 而 cf = 1 的这部分数字符合, 其余 cf = 0 且不符合, 返回.
        ; 这个函数有两个 ret

printable_2:
        cmp     al, 32
        jb      @f
        cmp     al, 126 + 1
        ret
@@:     cmc
        ret

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 思路
        ;   把 printable_2 修改为单出口

printable_3:
        cmp     al, 126 + 1
        jnb     @f
        cmp     al, 32
        cmc
@@:     ret

code    ends
stack   segment stack

        word    32 dup (?)

stack   ends
        end     start