
; 汇编语言 2e.pdf
; 王爽
; p266, 杂项
; miscellaneous
;
; p266, 13.3 对 int, iret 和栈的深入理解
; p266, 问题: 用 7ch 中断例程完成 loop 指令的功能
;
; 分析: 为了模拟 loop 指令 7ch 中断例程应具备下面的功能.
; (1) dec cx;
; (2) 如果 cx != 0, 转到标号 s 处执行, 否则向下执行.
;
; 转到标号 s 显然应该设 cs = s 的段地址, ip = s 的偏移地址.
; int 7ch 引发中断过程后进入 7ch 中断例程, 在中断过程中当前标志寄存器, cs 和 ip 都要压栈, 此时压入的
; cs 和 ip 中的内容分别是调用程序的段地址 (可以认为是标号 s 的段地址) 和 int 7ch 后一条指令的偏移
; 地址 (即标号 se 的偏移地址).
;
; 可见在中断例程中, 可以从栈里取得标号 s 的段地址和标号 se 的偏移地址, 而用标号 se 的偏移地址加上 bx
; 中存放的转移位移就可以得到标号 s 的偏移地址.
;
; 现在知道可以从栈中直接和间接地得到标号 s 的段地址和偏移地址, 那么如何用它们设置 cs:ip 呢?
;
; 可以利用 iret 指令, 我们将栈中的 se 的偏移地址加上 bx 中的转移位移, 则栈中 se 的偏移地址就变为了 s
; 的偏移地址. 再使用 iret 指令用栈中的内容设置 cs, ip, 从而实现转移到标号 s 处.
;
; 要点
; 通过修改 int 时自动入栈, 作为 iret 返回目的地的 cs:ip 达到改变转移目的地的目的.
;
; 问题
; - lp 先 dec cx 再 jcxz, 如果调用 int 7ch 时给 cx 传零则程序会输入一大堆叹号. 这算不算 bug?
; - 可能不算 lp 的 bug, 但是算程序本身的 bug. 程序先输出一个叹号再调用 int 7ch 判断是否该循环,
;   这逻辑就不对, 这种使用 int 7ch 的方法暗示了 cx 至少是 1.

data    segment

        ; 虽然请求了 2 个字, 但运行的时候还是为此段分配了 8 个字 = 0x10 字节 = 16 字节
        word    2 dup (?)

data    ends
stack   segment stack

        word    8 dup (?)

stack   ends
code    segment 'code'

start:  ; 保存 7ch 号中断向量, 0000:01f0 -> data
        mov     ax, 0
        mov     ds, ax
        mov     si, 7ch * 4

        mov     ax, data
        mov     es, ax
        mov     di, 0

        mov     cx, 2
        cld
        rep     movsw ; 8086 没有 movsd

        ; 修改 7ch 号中断向量
        mov     word ptr ds:[7ch * 4], lp
        mov     word ptr ds:[7ch * 4 + 2], cs

        ; 往屏幕上写叹号
        mov     ax, 0b800h
        mov     es, ax
        mov     di, 160 * 12

        mov     bx, offset s - offset se
        mov     cx, 80
s:      mov     byte ptr es:[di], '!'
        add     di, 2
        int     7ch
se:     nop

        ; 恢复 7ch 号中断向量, data -> 0000:01f0. 下面这种写法比 rep movsw 还省一条指令.
        mov     ax, 0
        mov     es, ax
        mov     ax, data
        mov     ds, ax

        mov     ax, ds:[0]
        mov     es:[7ch * 4], ax

        mov     ax, ds:[2]
        mov     es:[7ch * 4 + 2], ax

        ; 退出
        mov     ax, 4c00h
        int     21h

lp:     push    bp
        mov     bp, sp ; 注 1
        dec     cx
        jcxz    lpret
        add     [bp + 2], bx
lpret:  pop     bp
        iret

code    ends
        end     start

; 注 1：此时栈顶若干元素是
;
; high address
;
;      |
;      |        |     |
;      |         -----
;      |        |     |   <- 标志寄存器
;      |         -----
;      |        |     |   <- s 和 se 的段地址
;      |         -----
;      |        |     |   <- se 的偏移地址
;      |         -----
;      |        |     |   <- bp 原来的值, 栈顶 sp
;      |         -----
;     \|/
;
; low  address, 栈基址
; 
; bp 现在保存着栈顶的偏移地址, 所以 ss * 16 + bp + 2 处是 se 的偏移地址, 这个值加上 bx 就是 s 的偏移地址.
; 注意调用 7ch 中断时给 bx 传入的是 offset s - offset se, 这是个负值.
