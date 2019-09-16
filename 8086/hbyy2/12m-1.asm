
; 汇编语言 2e.pdf
; 王爽
; p250, 杂项
; miscellaneous
;
; p250, 12.6 除法错误中断的处理
;
; 下面的程序引发 0 号中断, 即除法错误.
; 书上的 0 号中断处理程序是显示 Divide overflow 之后返回到操作系统, 我的 dosbox 直接卡死.

code    segment 'code'

        mov     ax, 1000h
        mov     bh, 1
        div     bh

code    ends
        end
