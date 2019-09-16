
; 汇编语言 2e.pdf
; 王爽
; p299, 检测点 16.1
; check point
;
; 下面的程序将 code 段中 a 处的 8 个数据累加, 结果存储到 b 处的双字中, 补全程序.

code    segment 'code'

a       word    1, 2, 3, 4, 5, 6, 7, 8
b       dword   0

start:
        mov     si, 0
        mov     cx, 8

s:      mov     ax, [a + si]        ; mov ax, ___
        add     word ptr [b], ax    ; add ___, ax
        adc     word ptr [b + 2], 0 ; adc ___, 0
        add     si, 2               ; add si, ___
        loop    s

        mov     ax, 4c00h
        int     21h

code    ends
        end     start
