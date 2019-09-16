
; 汇编语言 2e.pdf
; 王爽
; p216 - p221, 实验 10 编写子程序
; experiment
;
; p216, 1. 显示字符串
; 填写 show_str: 到 ret 之间的内容.
;
; 名称：show_str
; 功能：在指定位置, 用指定颜色, 显式一个用 0 结束的字符串
; 参数：
;   dh - 行号, 取值 [0, 24]
;   dl - 列号, 取值 [0, 79]
;   cl - 颜色
;   ds:si - 字符串首地址
; 返回：无
; 应用举例：在屏幕的 8 行 3 列用绿色显示 data 段中的字符串.

        assume  cs: code

data    segment
        byte    'Welcome to masm!', 0
data    ends

code    segment
start:  mov     dh, 8
        mov     dl, 3
        mov     cl, 2

        mov     ax, data
        mov     ds, ax
        mov     si, 0

        call    show_str

        mov     ax, 4c00h
        int     21h

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
        jcxz    done

        mov     al, [si]
        mov     es:[di], al
        mov     es:[di + 1], bl

        inc     si
        add     di, 2
        jmp     write

done:   pop     es
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret

code    ends
        end     start
