
; 汇编语言 2e.pdf
; 王爽
; p279, 检测点 14.2
; check point
;
; 编程, 用加法和移位指令计算 ax = ax * 10
; 提示, ax * 10 = ax * 2 + ax * 8 = (ax << 1) + (ax << 3)
;
; 8086 不支持 shr 一个不是 1 的立即数, 80186 及以上都行.
;
; 270 = 0x10e

       .model   tiny
       .code
start:
        mov     ax, 27 ; 任给一个值
        mov     bx, ax

        shl     ax, 1
        mov     cl, 3
        shl     bx, cl

        add     ax, bx

       .exit    0
        end     start
