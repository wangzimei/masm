
; 汇编语言 2e.pdf
; 王爽
; p197 - p199, 实验 9 根据材料编程
; experiment
;
; 在屏幕中间分别显示绿色, 绿底红色, 白底蓝色的字符串 welcome to masm!.
; 编程所需的知识通过阅读分析提供的材料获得.
;
; 一屏是 80 列 x 25 行个字符, welcome to masm! 是 16 个字符, 想打印到中间应该从 (32, 12) 开始,
; 即第 1 行第 1 列起第 13 行的第 33 个字符.
;
; 一个字符两字节, 低字节是 ascii 高字节是属性, 下面是属性的定义
;  7    6 5 4   3   2 1 0
;  BL   R G B   I   R G B
; 闪烁   背景   高亮   前景
;
; 书上说闪烁的效果必须在全屏 dos 方式下才能看到, 我用 dosbox 运行在窗口中也能看到闪烁效果.
;
; 因此绿色是 00000010b, 绿底红色是 00100100b, 白底蓝色是 01110001b.
; 第一屏的起始地址是 b8000h, (32,  12) 是 b8000h + (12 * 80 + 32) * 2 = b8000h + 7c0h = b87c0h
;
; ss:bp - 数据区
; ds:di - 屏幕缓冲区
;
; ml -Foout\ 8086/hbyy2/e9.asm -Feout\

GREEN       = 00000010b
RED_GREEN   = 00100100b
BLUE_WHITE  = 01110001b
NORMAL      = 00000111b
SCREEN_BASE = 0b800h
SCREEN_OFF  = (12 * 80 + 32) * 2

data    segment

byte    'w', GREEN, 'e', GREEN, 'l', GREEN, 'c', GREEN, 'o', GREEN, 'm', GREEN, 'e', GREEN, ' ', NORMAL,
        't', RED_GREEN, 'o', RED_GREEN, ' ', NORMAL,
        'm', BLUE_WHITE, 'a', BLUE_WHITE, 's', BLUE_WHITE, 'm', BLUE_WHITE, '!', NORMAL

data    ends

stack   segment stack
stack   ends

code    segment
start:  mov     ax, SCREEN_BASE
        mov     ds, ax

        mov     ax, data
        mov     ss, ax

        mov     di, SCREEN_OFF
        mov     bp, 0
        mov     cx, 16

write:  mov     ax, [bp]
        mov     [di], ax
        add     di, 2
        add     bp, 2
        loop    write

        mov     ax, 4c00h
        int     21h
code    ends
end start
