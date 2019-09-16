
; 汇编语言 2e.pdf
; 王爽
; p313, 杂项
; miscellaneous
;
; p311, 17.2 使用 int 16h 中断例程读取键盘缓冲区
; mov   ah, 0
; int   16h
; 结果：
; ah = 扫描码, al = ascii 码
;
; p313, 编程, 接收用户的键盘输入, 输入 r 设置屏幕前景为红色; 输入 g 设置屏幕前景为绿色;
; 输入 b 设置屏幕前景为蓝色.
;
; 王爽说这个程序的技巧之处在于 mov ah, 1 和两个 shl ah, 1.
;
; 在第 16 章中实现过一个函数 set_screen, 那里使用 dos 提供的 ah = 2, int 21h 获取输入.
; 本章中作者用 bios 提供的 ah = 0, int 16h 获取输入. int 16h 不带回显.
;
; set_screen 在 p306, 16.4 程序入口地址的直接定址表, 16m-3.asm, 文件名可能会变化.
;
; 一个字符两字节, 低字节是 ascii 高字节是属性, 下面是属性的定义
;  7    6 5 4   3   2 1 0
;  BL   R G B   I   R G B
; 闪烁   背景  高亮  前景

code    segment
start:
        mov     ah, 0
        int     16h

        mov     ah, 1 ; 本程序不使用 int 16h 得到的扫描码

        cmp     al, 'r'
        je      r
        cmp     al, 'g'
        je      g
        cmp     al, 'b'
        je      b
        jmp     z

r:      shl     ah, 1
g:      shl     ah, 1
b:      mov     di, 0b800h
        mov     ds, di
        mov     di, 1
        mov     cx, 2000
s:      and     [di], byte ptr 11111000b
        or      [di], ah
        add     di, 2
        loop    s

z:      mov     ax, 4c00h
        int     21h

code    ends
stack   segment stack

        word    32 dup (?)

stack   ends
        end     start