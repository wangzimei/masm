
; 汇编语言 2e.pdf
; 王爽
; p306, 杂项
; miscellaneous
;
; p306, 16.4 程序入口地址的直接定址表
; 实现一个子程序 set_screen, 为显示输出提供如下功能。
; (1) 清屏; 当前屏幕全填空格
; (2) 设置前景色; 设置当前屏幕奇地址字节的 0、1、2 位
; (3) 设置背景色; 设置当前屏幕奇地址字节的 4、5、6 位
; (4) 向上滚动一行。从第一行起用下一行覆盖本行, 最后一行置空
; 参数
; ah - 0, 清屏; 1, 设置前景色; 2, 设置背景色; 3, 向上滚动一行
; al - 1、2 号功能用来指定颜色值, 在 [0, 7] 之间
;
; 一个字符两字节, 低字节是 ascii 高字节是属性, 下面是属性的定义
;  7    6 5 4   3   2 1 0
;  BL   R G B   I   R G B
; 闪烁   背景  高亮  前景

code    segment 'code'

table   word    offset @1, offset @2, offset @3, offset @4, offset sub2

start:  call    @tip

        ; 读一个键盘输入
        mov     ah, 1
        int     21h

        ; 看是否大于函数指针表的行数, ja 判断的是无符号。
        sub     al, '1'
        cmp     al, 4 ; 共 1 ~ 5 项功能, 5 号用来测试书上的代码
        ja      @f

        ; 从函数指针表调用函数
        mov     bx, 0
        mov     bl, al
        shl     bx, 1
        call    table[bx]
        jmp     start

@@:     mov     ax, 4c00h
        int     21h

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 把光标放到第 0 页第 0 行第 0 列然后清屏

@1:     push    ax
        push    bx
        push    cx
        push    dx
        push    ds
        
        mov     ah, 2   ; 置光标
        mov     bh, 0   ; 第 0 页
        mov     dh, 0   ; dh 放行号, 第 0 行
        mov     dl, 0   ; dl 放列号, 第 0 列
        int     10h

        mov     ax, 0b800h
        mov     ds, ax
        mov     bx, 0
        mov     cx, 2000

@@:     mov     [bx], byte ptr ' '
        add     bx, 2
        loop    @b

        pop     ds
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 设置前景色, 需要进一步的输入

@2:     push    ax
        push    bx
        push    cx
        push    ds

        call    @get
        sub     al, '0'
        cmp     al, 7
        ja      @2z

        mov     bx, 0b800h
        mov     ds, bx
        mov     bx, 1
        mov     cx, 2000

@@:     and     [bx], byte ptr 11111000b
        or      [bx], al
        add     bx, 2
        loop    @b

@2z:    pop     ds
        pop     cx
        pop     bx
        pop     ax
        ret

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 设置背景色, 需要进一步的输入

@3:     push    ax
        push    bx
        push    cx
        push    ds

        call    @get
        sub     al, '0'
        cmp     al, 7
        ja      @3z

        mov     cx, 0b800h
        mov     ds, cx
        mov     cx, 4
        shl     al, cl
        mov     bx, 1
        mov     cx, 2000

@@:     and     [bx], byte ptr 10001111b
        or      [bx], al
        add     bx, 2
        loop    @b

@3z:    pop     ds
        pop     cx
        pop     bx
        pop     ax
        ret

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 行 1 -> 行 0, 行 2 -> 行 1, 。。。, 行 24 -> 行 23, 行 24 = 空格

@4:     push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    si
        push    ds
        push    es

        mov     ax, 0b800h
        mov     ds, ax
        mov     si, 80 * 2
        mov     es, ax
        mov     di, 0
        mov     cx, 80 * 24
        cld
        rep     movsw

        mov     cx, 80
@@:     mov     [di], byte ptr ' '
        add     di, 2
        loop    @b

        ; 取光标位置
        mov     bh, 0
        mov     ah, 3
        int     10h

        ; 光标向上一行
        dec     dh
        mov     ah, 2
        int     10h

        pop     es
        pop     ds
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 不做任何事

@5:     ret

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 取得从键盘输入的字符, 放到 al 里面

@get:   push    dx

        ; 输出 -
        mov     ah, 2
        mov     dl, ' '
        int     21h
        mov     dl, '-'
        int     21h
        mov     dl, ' '
        int     21h

        ; 读一个键盘输入
        mov     ah, 1
        int     21h

        pop     dx
        ret

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; 显示提示

data    byte    13, 10, 13, 10,
                '(1) clear screen', 13, 10,
                '(2) set foreground, color must in [0, 7]', 13, 10,
                '(3) set background, color must in [0, 7]', 13, 10,
                '(4) scroll up', 13, 10,
                '(5) test', 13, 10,
                'enter a digit: $'

@tip:   push    ax
        push    dx
        push    ds

        mov     ax, cs
        mov     ds, ax
        mov     dx, offset data

        mov     ah, 9
        int     21h

        pop     ds
        pop     dx
        pop     ax
        ret

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; sub 是书上的代码

sub1:   push    bx
        push    cx
        push    es

        mov     bx, 0b800h
        mov     es, bx
        mov     bx, 0
        mov     cx, 2000
sub1s:  mov     byte ptr es:[bx], ' '
        add     bx, 2
        loop    sub1s

        pop     es
        pop     cx
        pop     bx
        ret

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;
        ; sub 是书上的代码

sub2:   push    bx
        push    cx
        push    es

        mov     bx, 0b800h
        mov     es, bx
        mov     bx, 1
        mov     cx, 2000
sub2s:  and     byte ptr es:[bx], 11111000b
        or      es:[bx], al
        add     bx, 2
        loop    sub2s

        pop     es
        pop     cx
        pop     bx
        ret

code    ends
stack   segment stack

        word    32 dup (?)

stack   ends
        end     start
