
; 汇编语言 2e.pdf
; 王爽
; p216 - p221, 实验 10 编写子程序
; experiment
;
; p217, 2. 解决除法溢出的问题
;
; 这里说除法会溢出, 比如 ax = 1000, bh = 1, div bh 由于 al 中放不下 1000 而溢出.
; p179, 8.7 div 指令中讲到：除数是 8 位时 al 存储商、ah 存储余数, 所以商的位数和除数一样.
;
; 名称：divdw
; 功能：进行不会溢出的除法, 被除数是 dword, 除数是 word, 结果是 dword
;   * 书上没有说余数是什么类型, 不过既然放 cx 里面那就是 word 型. 余数不会大于除数.
; 参数：
;   ax - dword 被除数的低 16 位
;   dx - dword 被除数的高 16 位
;   cx - 除数
; 返回：
;   ax - 结果低 16 位
;   dx - 结果高 16 位
;   cx - 余数
;
; 返回值放在 ax、cx 和 dx 里面, 所以 divdw 不能保存和恢复这三个寄存器.
;
; 书中给出了一个公式
; X / N = int(H / N) * 65536 + [rem(H / N) * 65536 + L] / N
; 其中
; X：dividend, 被除数, [0,  0xffff ffff]
; L：X 的低 16 位
; H：X 的高 16 位
; N：divisor, 除数, [0, 0xffff]
; int()：quotient, 取商
; rem()：remainder, 取余数

stack   segment stack
        word    8 dup (?)
stack   ends

code    segment
        ; 应用举例：计算 100 0000 / 10（0xf 4240 / 0xa）
start:  mov     ax, 4240h
        mov     dx, 0fh
        mov     cx, 0ah
        call    divdw

        ; 结果：dx = 1, ax = 0x86a0, cx = 0

        mov     ax, 4c00h
        int     21h

divdw:  push    bx
        push    si

        mov     bx, ax  ; ax = L, bx = L, cx = N, dx = H
        mov     ax, dx  ; ax = H, bx = L, cx = N, dx = H
        mov     dx, 0   ; ax = H, bx = L, cx = N, dx = 0
        div     cx      ; ax = int(H / N), bx = L, cx = N, dx = rem(H / N)

        ; 如果这里使用 xchg ax, bx 则能省下 si 寄存器
        mov     si, ax  ; ax = int(H / N), bx = L, cx = N, dx = rem(H / N), si = int(H / N)
        mov     ax, bx  ; ax = L, bx = L, cx = N, dx = rem(H / N), si = int(H / N)
        div     cx      ; ax = int([rem(H / N) * 65536 + L] / N), bx = L, cx = N,
                        ; dx = rem([rem(H / N) * 65536 + L] / N), si = int(H / N)

        mov     cx, dx
        mov     dx, si
        
        pop     si
        pop     bx
        ret

code    ends
        end     start
