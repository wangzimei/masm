
; test
;
; 用几种不同的方式去调用中断例程
;
; p185, 第  9 章 转移指令的原理
; p200, 第 10 章 call 和 ret 指令
; p223, 第 11 章 标志寄存器
; p246, 第 12 章 内中断
;
; p190,  9. 4 转移的目的地址在指令中的 jmp 指令
; p192,  9. 6 转移地址在内存中的 jmp 指令
; p200, 10. 1 ret 和 retf
; p203, 10. 4 转移的目的地址在指令中的 call 指令
; p204, 10. 6 转移地址在内存中的 call 指令
; p243, 11.11 pushf 和 popf
; p248, 12. 4 中断过程
; p249, 12. 5 中断处理程序和 iret 指令
; p259, 12.11 单步中断
;
; 我用以下代码
; ; 清除第 8 位 tf 和第 9 位 if, 参见 p248, 12. 4 中断过程
; pushf
; pop     bx
; and     bx, 11111110011111111b
; ;           fedcba09876543210
; push    bx
; popf
;
; 不过不写上面的代码似乎也没看出来有啥问题? 所以上面的代码并没有放到程序代码中.
;
; 下面之所以将标志寄存器, cs, ip 压栈是因为假设中断例程是用 iret 返回的, 这也是正常的假设.
; 三个压栈对应 iret 的三个出栈, 后两个出栈实际上是设置 cs:ip.
;
; 当使用 Microsoft CodeView 4.01 调试程序时发现:
; 使用 int 调用 isr 时按 f8 (trace) 没法进入 isr 的代码;
; 使用 call 时源代码模式不能, 汇编模式能转到 isr 但是会在第一句卡住;
; 使用 jmp 时按 f8 或 f10 (step) 会转到 isr, 不过也是在第一句卡住.
;
; 0000:0084 是 21h 号中断向量, 这里的四字节是 5f 06 49 04, 按照先 ip 后 cs 同时注意字节序,
; 这个向量指向 0449:065f. 跟踪程序发现确实跳到了 0449:065f (如果不是就奇怪了).
;
; 0449:065f 9c          pushf
; 0449:0660 55          push    bp
; 0449:0661 8bec        mov     bp, sp
; 0449:0663 50          push    ax
; 0449:0664 8cc8        mov     ax, cs
; 0449:0666 394606      cmp     word ptr [bp + 06], ax
; 0449:0669 58          pop     ax
; 0449:066a 5d          pop     bp
; 0449:066b 7312        jnb     067f
;
; 进入 isr 后停在第一句, 按 f8 或者 f10 就卡住; 把光标移到第三句然后按 f7 会执行到第三句, 
; 然后就能单步了. 可能和调试器使用的 tf 标志有关系, 具体也没搞懂.
;
; p288, 2. 调用 bios 的 int 9 中断例程
; 这里面讲述的过程和我实现的基本一样, 区别是他用 and ah 清除 tf 和 if, 我用的是 and bx.
;
; p292, 检测点 15.1,  (1) 仔细分析上面的 int 9 中断例程看是否可以精简.
; 这里面说进入中断例程后 if 和 tf 都已经置零所以没必要再设置.
; 因为他是在中断例程中调用别的中断例程所以不需要调整 if, tf.

code    segment 'code'
start:
        ; 设置好 ds:dx 和 es, ah 后就不修改 ax, dx, es, ds 了, 省得麻烦.
        mov     dx, cs
        mov     ds, dx
        mov     dx, offset data

        mov     ax, 0
        mov     es, ax
        mov     ah, 9

        ; (+3). 通过 int 指令调用中断例程
        int     21h

        ; (+2). 通过远调用, 为了模拟 int 需要将标志寄存器压栈
        pushf
        call    dword ptr es:[21h * 4]

        ; ( 0). 通过远转移, 为了模拟 int 需要将标志寄存器, cs, ip 压栈
        pushf
        push    cs
        mov     bx, @f
        push    bx

        jmp     dword ptr es:[21h * 4]

@@:     ; (-2). 通过远返回 retf 使用远转移
        pushf
        push    cs
        mov     bx, @f
        push    bx

        mov     bx, es:[21h * 4 + 2]
        push    bx
        mov     bx, es:[21h * 4]
        push    bx
        retf

        ; (-3). 通过中断返回 iret 使用远转移
        ;
        ; 略

@@:     mov     ax, 4c00h
        int     21h

data    byte    'hello world', 13, 10, '$'

code    ends
stack   segment stack

        word    8 dup (?)

stack   ends
        end     start
