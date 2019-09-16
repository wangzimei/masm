
; 汇编语言 2e.pdf
; 王爽
; p261, 实验 12 编写 0 号中断的处理程序
; experiment
;
; 编写 0 号中断的处理程序, 使得发生除法溢出时在屏幕中央显示字符串 "divide error!", 
; 然后返回到 dos.
;
; 中断处理程序, Interrupt Service Routine, isr
;
; 这个程序不把中断处理程序拷贝到某个地方, 而是就放在自己的代码段. 设置中断向量后引发一个除法错误, 
; 这会进入我们的 0 号中断处理程序, 该处理程序显示字符串并还原 0 号中断向量, 然后返回 dos.
;
; 书上给出的例子之所以把 isr 拷贝到一个固定位置是想展示 isr 和普通程序的区别, isr 在程序退出之后仍然有效.
;
; 这个程序没有在 isr 中调用原先的 isr, 一是不知道怎么调用, 二是原先的 isr 会导致 dosbox 死机.
; 有一点不明白就是发生中断时我的程序还在不在内存中, 或者说把 isr 放在程序中安全不安全.
;
; 这里引发除法错误的办法是设置会导致溢出的 ax 和 bh 然后 div bh, 还有一种办法是 int 0. 这两种办法有什么区别?
; 在 code view 里面单步跟踪时发现办法 1 会导致调试器进入 isr 并能继续单步执行, 办法 2 会直接结束程序.
; 但运行结果似乎一样, isr 都得到了执行.

code    segment 'code'
start:  mov     ax, 0
        mov     es, ax

        ; 保存 0 号中断向量
        mov     ax, es:[0]
        mov     data[0], ax

        mov     ax, es:[2]
        mov     data[2], ax

        ; 修改 0 号中断向量
        mov     word ptr es:[0], isr
        mov     word ptr es:[2], cs ; 把 cs 用 code 代替也行吧?

        ; 引发除法错误
        mov     ax, 1000h
        mov     bh, 1
        div     bh

        ; 下面的语句不执行, 而是进入 isr, 这证明发生了跳转（中断）
        mov     ax, 4c00h
        int     21h

isr:    ; 往屏幕上写字
        mov     ax, cs
        mov     ds, ax
        mov     si, offset string

        mov     ax, 0b800h
        mov     es, ax
        mov     di, (12 * 80 + 32) * 2

        mov     cx, lengthof string
s:      mov     al, [si]
        mov     ah, 01110000b ; 白底黑字, 参见实验 9
        mov     es:[di], ax
        inc     si
        add     di, 2
        loop    s

        ; 恢复 0 号中断向量
        mov     ax, 0
        mov     es, ax

        mov     ax, data[0]
        mov     es:[0], ax

        mov     ax, data[2]
        mov     es:[2], ax

        ; 返回 dos
        mov     ax, 4c00h
        int     21h

string  byte    ' divide error! '
data    word    2 dup (?)
code    ends

; 发生中断时需要用到我的栈
stack   segment stack
        word    8 dup (?)
stack   ends
        end     start
