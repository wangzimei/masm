
; 16 位程序栈的一个元素是两字节
; 这程序当时 (2013) 应该是用 cv 调试, visual studio 查看 16 进制的; 现在 (2019) 用 debug 和 powershell
;
; ==================== com
;
; com 执行时, 开始栈顶是 fffe, push 一个 16 位值后栈顶变为 fffc
; fffc, fffd, fffe, ffff 总共是 4 个字节但是只使用了两个字节
;
; ml -Dcom -Foout\ 8086/hello/stack.asm -Feout\
;
; debug out\stack.com
; r, 看到列出的寄存器里 sp = fffe
; d fff0, 看到 fffe 和 ffff 是 0 0
; t, 单步执行, 观察寄存器
;
; ==================== exe
;
; exe 中, 自己设定栈指针时栈的第一个元素用到了
; 用 77 填充 stack 段, 并
; - 用 stack 修饰 stack 段: 栈顶是 20h, 但 1e 和 1f 的值是 ff 而不是 77
;   用 visual sutdio 查看该文件生成的 exe 发现 stack 段的最后两个字节还是 77, 所以
;   1e 和 1f 应该是在运行的时候从 77 修改成 ff 的.
; - 不修饰 stack 段, 这需要自己调整 ss:sp: 此时 stack 段是 20h 个 77, 最后两字节未被修改
;
; ml -Foout\ 8086/hello/stack.asm -Feout\
;
; debug out\stack.exe
; r, 有 ss = 076f, sp = 0020
; d ss:0, 看到 0 ~ 1d 是 77, 1e 和 1f 是 ff ff
;
; format-hex out/stack.exe
; 最后 32 (20h) 字节是 77

ifdef com

       .model   tiny
       .code
start:  mov     ax, 4c00h
        push    ax
        push    ax

        pop     bx
        pop     bx
        pop     bx

        int     21h
else

; 相当于 .model small

code    segment 'code'
start:  mov     ax, 4c00h
        push    ax
        push    ax

        pop     bx
        pop     bx
        pop     bx

        int     21h
code    ends

stack   segment stack
        word    16 dup (7777h)
stack   ends

endif

        end     start


2019, 现在知道为啥
- com 一开始栈顶是 fffe
- fffe, ffff 是 0 0 (这一条没见写, 不知道当时注意到没有)
了. 因为 com 要支持 retn 结束程序. 见 abc/2-life.asm

