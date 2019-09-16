
; 汇编语言 2e.pdf
; 王爽
; p211, 杂项
; miscellaneous
;
; 计算 data 段中第一组数据的三次方, 结果保存在第二组数据中

        assume      cs: code

data    segment
        word    1, 2, 3, 4, 5, 6, 7, 8
        dword   8 dup (0)
data    ends

code    segment
start:  mov     ax, data
        mov     ds, ax

        mov     si, 0   ; ds:si 指向第一组的 word
        mov     di, 16  ; ds:di 指向第二组的 dword

        mov     cx, 8
s:      mov     bx, [si]
        call    cube
        mov     [di], ax
        mov     [di + 2], dx
        add     si, 2
        add     di, 4
        loop    s

        mov     ax, 4c00h
        int     21h

cube:   mov     ax, bx
        mul     bx
        mul     bx
        ret

code    ends
        end     start
