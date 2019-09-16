
; 汇编语言 2e.pdf
; 王爽
; p270, 杂项
; miscellaneous
;
; p269, 13.6 bios 中断例程应用
; p270, 编程：在屏幕的第 5 行 12 列显示 3 个红底高亮闪烁绿色的 a.
;
; 这就是把前两个练习综合起来, 先设置光标再显示字符.

       .model   tiny
       .code
start:
        mov     ah, 2           ; 置光标
        mov     bh, 0           ; 第 0 页
        mov     dh, 5           ; dh 放行号, 第  5 行
        mov     dl, 12          ; dl 放列号, 第 12 列
        int     10h

        mov     ah, 9           ; 在光标位置显示字符
        mov     al, 'a'         ; 字符
        mov     bl, 11001010b   ; 红底高亮闪烁绿色
        mov     bh, 0           ; 第 0 页
        mov     cx, 3           ; 字符重复个数
        int     10h

       .exit    0
        end     start
