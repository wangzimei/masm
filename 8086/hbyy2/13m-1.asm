
; 汇编语言 2e.pdf
; 王爽
; p263, 杂项
; miscellaneous
;
; p263, 13.2 编写供应用程序调用的中断例程
; 问题一：编写、安装中断 7ch 的中断例程.
;
; 功能：求一 word 型数据的平方
; 参数：ax - 要计算的数据
; 返回值：dx - 结果高 16 位, ax - 结果低 16 位
; 应用举例：求 2 * 3456 ^ 2, 结果 ax = 0x8000, dx = 0x16c
;
; 至此书上的 isr 一直放在中断向量表中, 从 0000:0200 开始, 也不卸载.

code    segment 'code'
start:  ; 把 isr 拷贝到从 0000:0200 开始的内存
        mov     ax, cs
        mov     ds, ax
        mov     si, offset sqr
     
        mov     ax, 0
        mov     es, ax
        mov     di, 200h
     
        mov     cx, offset sqrend - offset sqr
        cld
        rep     movsb

        ; 修改中断向量表的第 7ch 格
        mov     ax, 0
        mov     es, ax
        mov     word ptr es:[7ch * 4], 200h
        mov     word ptr es:[7ch * 4 + 2], 0

        ; 用 7ch isr 求 3456 的平方
        mov     ax, 3456
        int     7ch

        ; 结果乘以 2
        add     ax, ax
        adc     dx, dx

        ; 不负责任地退出
        mov     ax, 4c00h
        int     21h

sqr:    mul     ax
        iret
sqrend: nop

code    ends
        end     start
