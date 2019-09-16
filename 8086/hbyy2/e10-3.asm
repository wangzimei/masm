
; 汇编语言 2e.pdf
; 王爽
; p216 - p221, 实验 10 编写子程序
; experiment
;
; p219, 3. 数值显示
; 把数值以十进制显示为字符串.
;
; 提示:
;   1. 十进制的 ascii 码 = 十进制值 + 30h
;   2. 为了得到每个十进制位的值, 用数值反复除以 10, 每次得到的余数是个位上的值.
;   3. 使用实验 10 (1) 的 show_str
;
; 名称: dtoc
; 功能: 将 word 转变为表示十进制的字符串, 字符串以 0 结尾
; 参数:
;   ax - word 型数据
;   ds:si - 字符串首地址
; 返回: 无
; 注意: 虽然被除数是 16 位的, 也还是要使用 16 位除法而不能使用 8 位除法.

data    segment
        byte    10 dup (0)
data    ends

stack   segment stack
        word    16 dup (?)
stack   ends

code    segment
start:  mov     ax, data
        mov     ds, ax
        mov     si, 0

        mov     ax, 12666
        call    dtoc

        mov     dh, 8
        mov     dl, 3
        mov     cl, 2
        call    show_str

        mov     ax, 4c00h
        int     21h

        ; 名称: dtoc
        ; 功能: 将 word 转变为表示十进制的字符串, 字符串以 0 结尾
        ; 参数:
        ;   ax - word 型数据
        ;   ds:si - 字符串首地址
        ; 返回: 无
        ; 注意: 虽然被除数是 16 位的, 也还是要使用 16 位除法而不能使用 8 位除法.
dtoc:   push    ax
        push    bx
        push    cx
        push    dx
        push    di ; 字符串的长度, 包含结尾 0

        mov     bx, 10
        mov     cx, 0
        mov     dx, 0
        mov     di, 0

divide: div     bx

        push    dx
        mov     dx, 0
        inc     di

        mov     cx, ax
        jcxz    end_divide
        jmp     divide

end_divide:
        mov     cx, di
        mov     di, si ; 不改动 si, 因此也不需要保存和恢复 si

transform:
        pop     ax
        add     ax, 30h
        mov     [di], al
        inc     di
        loop    transform

        mov     [di], byte ptr 0

        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
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
        pop     es
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret

code    ends
        end     start
