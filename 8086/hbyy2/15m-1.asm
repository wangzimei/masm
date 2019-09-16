
; 汇编语言 2e.pdf
; 王爽
; p286, 杂项
; miscellaneous
;
; p286, 15.4 编写 int 9 中断例程
; 编程, 在屏幕中间依次显示 a - z, 并可以让人看清. 显示过程中按 esc 后改变显示的颜色.
;
; 为了延时书中采用了 busy wait loop, 用 dx 和 ax 做计数器, 书上循环了 1000 0000h 次.
; 我使用的 dosbox 把 cpu 速度固定在了 3000 个时钟周期所以不需要很大的循环次数.
; 刚开始没注意到固定的时钟周期时吓了一跳, 心说王爽使的啥 cpu 比我的 i7 还快?
;
; p292, 检测点 15.1, (2) 仔细分析上面程序中的主程序看看有什么潜在的问题.
; 如果执行设置 int 9 中断例程的段地址和偏移地址之间发生了键盘中断则 cpu 将转去一个错误的地址.
; 找出这样的程序段, 改写它们, 注意 sti 和 cli 的用法.
;
; 2013.11.22
; 昨晚上 Xeon 没带家里钥匙来我这里了, 晚上我没睡一直在看这个程序. 这个程序运行不正常, 按 esc 不会变色.
; 以为是 dosbox 的毛病, 正好以前下载过一个 msdos 7.1 的 vhd, 就决定在 hyper-v 中运行 ms-dos.
;
; http://www.appassure.com/support/KB/adding-vhd-files-to-the-hyper-v-virtual-machine/
; http://virtualisedreality.com/2009/08/03/installing-dos-6-22-in-a-vm/
; http://www.virtuatopia.com/index.php/Creating_and_Configuring_Hyper-V_Virtual_Hard_Disks_%28VHDs%29
;
; 排除各种困难, 在 config.sys 里注释掉 emm386.exe 之后终于运行了 ms-dos 7.10, 发现程序照样不正常. 就在怀疑
; 是不是 hyper-v 不能正确模拟 dos 时, 这时候快早上 8 点了, 我看着程序里的 sti 和 cli 想, google 一下它们是
; 什么意思. 一搜索发现我用反了! cli 是关中断, sti 是开中断. 我说怎么按键没反应呢! 修改之后可以变色了.
;
; 教训: 书上说了注意 sti 和 cli 的用法, 可看了那句话之后我反而更不注意它们的用法了.
;
; 修改之后在 dosbox 上一切正常, 在 hyper-v 的 msdos 7.10 上可以正常变色但结束不了,
; 即使就剩 mov ax, 4c00h 和 int 21h 这两句都不行.
;
; 新建一个简单的程序逐步往里面添加语句, 我发现加上 seg2 segment stack 这个段之后得到的程序无法返回了.
; 在这个段里面我分配了 16 个字, 改为 64 个字后程序正常. 17 不行, 24 可以. 所以以后就用 32 吧.
;
; 在怀疑栈之前我还在 f3 返回前插入过一句输出语句, 发现能正常返回; 然后注释掉输出语句发现也能正常返回!
; 那时候栈还没有改变, 只有 16 个 word. 不知道咋回事.

seg1    segment 'code'
@1:
        ;call    f1
        ;call    f2
        call    f3

        mov     ax, 4c00h
        int     21h

data    word    2 dup (?)

        ; 不合格: 太快
f1:     mov     ax, 0b800h
        mov     es, ax
        mov     ah, 'a'
f1_s:   mov     es:[160 * 12 + 40 * 2], ah
        inc     ah
        cmp     ah, 'z'
        jna     f1_s
        ret

        ; 不合格: 速度合适但不响应 esc
f2:     mov     ax, 0b800h
        mov     es, ax
        mov     ah, 'a'
f2_s1:  mov     es:[160 * 12 + 40 * 2], ah

        ; busy wait loop
        push    ax
        push    dx
        mov     dx, 5;01000h
        mov     ax, 0
f2_s2:  sub     ax, 1
        sbb     dx, 0
        cmp     ax, 0
        jne     f2_s2
        cmp     dx, 0
        jne     f2_s2
        pop     dx
        pop     ax

        inc     ah
        cmp     ah, 'z'
        jna     f2_s1
        ret

f3:     ; 保存 9 号中断向量
        mov     ax, 0
        mov     ds, ax
        mov     ax, ds:[9 * 4]
        mov     bx, ds:[9 * 4 + 2]
        mov     data[0], ax
        mov     data[2], bx

        ; 设置 9 号中断向量
        cli
        mov     ds:[9 * 4], offset isr
        mov     ds:[9 * 4 + 2], cs
        sti

        call    f2

        ; 恢复 9 号中断向量
        mov     ax, data[0]
        mov     bx, data[2]

        cli
        mov     ds:[9 * 4], ax
        mov     ds:[9 * 4 + 2], bx
        sti
        ret

isr:    push    ax
        push    bx
        push    ds

        in      al, 60h

        pushf

        ; 因为自己就是 isr 所以 if 和 tf 已经清空, 不需要再次清空. 下面的代码仅用来演示如何清空.
        pushf
        pop     bx
        and     bh, 11111100b
        push    bx
        popf

        call    dword ptr data

        cmp     al, 1
        jne     isr_2

        mov     ax, 0b800h
        mov     ds, ax
        inc     byte ptr ds:[160 * 12 + 40 * 2 + 1]

isr_2:  pop     ds
        pop     bx
        pop     ax
        iret

seg1    ends
seg2    segment stack

        word    32 dup (?)

seg2    ends
        end     @1
