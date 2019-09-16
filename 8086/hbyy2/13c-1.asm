
; 汇编语言 2e.pdf
; 王爽
; p267, 检测点 13.1
; check point
;
; p267 - p268, (2) 用 7ch 中断例程完成 jump near ptr s 指令的功能, 用  bx 向中断例程传送转移位移.
; 应用举例：在屏幕的第 12 行显示 data 段中以 0 结尾的字符串.

data    segment

        byte    'conversation', 0

data    ends
stack   segment stack

        word    8 dup (?)

stack   ends
code    segment 'code'

start:  ; 安装 7ch 号中断处理程序就是把标号 isr 的偏移地址和段地址依次写入 0000:01f0
        mov     ax, 0
        mov     ds, ax
        mov     word ptr ds:[7ch * 4], isr
        mov     word ptr ds:[7ch * 4 + 2], cs

        ; 使用 isr
        mov     ax, data
        mov     ds, ax
        mov     si, 0

        mov     ax, 0b800h
        mov     es, ax
        mov     di, 12 * 160

s:      cmp     byte ptr [si], 0
        je      ok

        mov     al, [si]
        mov     ah, 01110000b ; 白底黑字, 参见实验 9
        mov     es:[di], ax

        inc     si
        add     di, 2

        mov     bx, offset s - offset ok
        int     7ch

ok:     call    zero_out_0000_01f0_irresponsible
        mov     ax, 4c00h
        int     21h

        ; 没有保护用到的寄存器, 所以 irresponsible
zero_out_0000_01f0_irresponsible:
        mov     ax, 0
        mov     ds, ax
        mov     word ptr ds:[7ch * 4], 0
        mov     word ptr ds:[7ch * 4 + 2], 0

        pop     ax ; 这两句相当于 ret
        jmp     ax

isr:    push    bp
        mov     bp, sp
        add     [bp + 2], bx
        pop     bp
        iret

code    ends
        end     start
