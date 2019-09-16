
; 汇编语言 2e.pdf
; 王爽
; p270, 杂项
; miscellaneous
;
; p269, 13.6 bios 中断例程应用
; p270, 再看一下 int 10h 中断例程的在光标位置显示字符功能.

        .model tiny
        .code
start:  mov     ah, 9       ; 在光标位置显示字符
        mov     al, 'a'     ; 字符
        mov     bl, 111b    ; 颜色属性
        mov     bh, 0       ; 第 0 页
        mov     cx, 3       ; 字符重复个数
        int     10h

        .exit   0
        end     start
