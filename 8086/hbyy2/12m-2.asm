
; 汇编语言 2e.pdf
; 王爽
; p251, 杂项
; miscellaneous
;
; p251, 12.7  编程处理 0 号中断
; p254, 12.8  安装
; p256, 12.9  do0
; p259, 12.10 设置中断向量
;
; p251, 12.7 编程处理 0 号中断
; 在屏幕中间显示 overflow! 后返回到操作系统
;
; 因为这里的中断处理程序返回到操作系统, 所以不需要 iret.
;
; 0000:0000 ~ 0000:03ff 大小为 1k 这段空间是系统用来存放中断处理程序入口地址的中断向量表, 共 256 个中断.
; 书上说其实中断向量表中很多单元都是空的, 所以决定用 0000:0200 ~ 0000:02ff 的 256 字节保存中断处理程序, 
; 5.7 节曾经用过这段空间.
;
; p254, 12.8 安装
; 使用 offset 和减号求代码的大小
;
; p256, 12.9 do0
; 要显示的字符串应该放在哪里
;
; 下面的代码综合了程序 12.1、12.2 和 12.3
; 我把中断处理程序中字符串 overflow! 的放置位置从开头挪到了末尾.
;
; 这个程序从 start 开始执行, 把 do0 开始至 do0end 结束的一段代码拷贝到从内存 0000:0200 开始的一块内存.
; do0 至 do0end 这段代码不在程序执行时执行, 而是在发生 0 号中断时执行.
;
; 0000:0000 + 4k 保存第 k 号中断处理程序的起始地址, 占四字节, 前两字节是中断处理程序的偏移地址, 后两字节是
; 段地址. 这里要修改第 0 号中断的处理程序, 所以修改 0000:0000 到 0000:0003 这四字节的内容. 前面把处理程序
; 拷贝到了 0000:0200, 所以
; mov word ptr 0000:0000, 200h
; mov word ptr 0000:0002, 0
;
; 几个问题
;
; 1. 至此书上分配空间时全部用的是匿名变量. 在本程序中我分配 string 时用了一个标签跟一个回车再跟一个分配语句,
;   这和直接写成命名变量没啥区别.
; 2. 程序只能安装中断处理程序, 却不能卸载这个中断处理程序.
; 3. 修改了中断向量表中相应的 4 字节以替换原来的处理程序, 而一般情况下应该在处理之后调用原先的处理程序.
; 4. 没有什么措施确保 do0 至 do0end 的这段代码长度小于 256 字节.

MYPOS   = 200h

code    segment 'code'
start:  mov     ax, cs
        mov     ds, ax
        mov     si, offset do0

        mov     ax, 0
        mov     es, ax
        mov     di, MYPOS

        mov     cx, offset do0end - offset do0
        cld
        rep     movsb

        ; p259, 12.10 设置中断向量
        mov     ax, 0
        mov     es, ax
        mov     word ptr es:[0], MYPOS
        mov     word ptr es:[2], 0

        mov     ax, 4c00h
        int     21h

do0:    mov     ax, cs
        mov     ds, ax
        mov     si, MYPOS + offset string - offset do0

        mov     ax, 0b800h
        mov     es, ax
        mov     di, (12 * 80 + 36) * 2

        mov     cx, 9
s:      mov     al, [si]
        mov     es:[di], al
        inc     si
        add     di, 2
        loop    s

        mov     ax, 4c00h
        int     21h

string:
        byte    'overflow!'
do0end: nop

code    ends
        end     start
