
; 汇编语言 2e.pdf
; 王爽
; p302, 杂项
; miscellaneous
;
; p302, 16.3 直接定址表
; 编写子程序, 以十六进制的形式在屏幕中间显示给定的字节型数据.
;
;  0 + 30h = '0'
;  1 + 30h = '1'
; ...
; 10 + 37h = 'A'
; 11 + 37h = 'B'
;
; 可见 0 ~ 9 和 A（10）- F（15）从数值到字符的对应关系并不一样. 想通过加上一个常量得到
; 对应的字符就需要某种形式的判断以区别对待. 所以搞一张表, 这比较简单.
;
; 这个和书上的写法区别在于打印到当前光标处而不是屏幕中间.

code    segment 'code'
start:
        mov     al, 3fh
        call    show_byte

        mov     ax, 4c00h
        int     21h

        ; 显示 al 中的一个字节
show_byte:
        jmp     show

table   byte    '0123456789abcdef'

show:   push    ax
        push    bx
        push    dx

        mov     ah, 2   ; dos int 21h 的 2 号功能
        mov     dh, al  ; int 21h 之后 al 居然被修改了！所以在这里保存它.

        mov     bx, 0
        mov     bl, dh  ; bl = hhhhllll
        shr     bl, 1   ; bl = 0hhhhlll
        shr     bl, 1
        shr     bl, 1
        shr     bl, 1   ; bl = 0000hhhh

        mov     dl, table[bx]
        int     21h

        mov     bl, dh          ; bl = hhhhllll
        and     bl, 00001111b   ; bl = 0000llll

        mov     dl, table[bx]
        int     21h

        pop     dx
        pop     bx
        pop     ax
        ret

code    ends
        end     start
