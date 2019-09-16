
; 汇编语言 2e.pdf
; 王爽
; p295, 实验 15 安装新的 int 9 中断例程
; experiment
;
; 安装一个新的 int 9 中断例程, 功能: 在 dos 下按 A 键后除非不再松开, 如果松开就显示满屏的 A;
; 其他键照常处理.
;
; 提示: 按下一个键产生的扫描码称为通码, 松开产生断码, 断码 = 通码 + 80h.
;
; p284, 表 15.1 键盘上部分键的扫描码
; A - 0x1e
;
; 和 p292, 15.5 的程序 (15m-2.asm) 一样一运行 ml.exe 就不响应键盘了.

code    segment
        push    ax
        push    bx
        push    cx
        push    ds

        in      al, 60h
        int     80h
        cmp     al, 1eh + 80h
        jne     @ne

        mov     ax, 0b800h
        mov     ds, ax
        mov     bx, 0
        mov     cx, 2000
s:      mov     [bx], byte ptr 'A'
        add     bx, 2
        loop    s

@ne:    pop     ds
        pop     cx
        pop     bx
        pop     ax
        iret

start:
        ; 0:24 -> 0:200, 4 字节
        ; ds:si - 源, es:di - 汇
        mov     ax, 0
        mov     ds, ax
        mov     es, ax
        mov     si, 24h
        mov     di, 200h
        movsw
        movsw

        ; isr -> 0:204        
        ; ds:si = cs:0, es:di = 0:204h
        mov     ax, cs
        mov     ds, ax
        mov     si, 0
        mov     di, 204h
        mov     cx, offset start
        cld
        rep     movsb

        ; 04 02 00 00 -> 0:24, 4 字节
        cli
        mov     es:[9 * 4], word ptr 204h
        mov     es:[9 * 4 + 2], word ptr 0
        sti

        mov     ax, 4c00h
        int     21h

code    ends
stack   segment stack

        word    32 dup (?)

stack   ends
        end     start
