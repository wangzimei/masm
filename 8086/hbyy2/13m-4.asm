
; 汇编语言 2e.pdf
; 王爽
; p269, 杂项
; miscellaneous
;
; p269, 13.6 bios 中断例程应用
; p269, 下面看一下 int 10h 中断例程的设置光标位置功能.
;
; ah = 2 表示调用第 10h 号中断例程的 2 号子程序, 功能为设置光标位置.
; bh = 0, dh = 5, dl = 12, 设置光标到第 0 页, 第 5 行, 第 12 列.
;
; ml -Foout\ 8086/hbyy2/13m-4.asm -Feout\

        .model tiny
        .code
start:  mov     ah, 2   ; 置光标
        mov     bh, 0   ; 第 0 页
        mov     dh, 5   ; dh 放行号
        mov     dl, 12  ; dl 放列号
        int     10h

        .exit   0
        end     start
