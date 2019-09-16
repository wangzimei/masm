
; 汇编语言 2e.pdf
; 王爽
; p239 - p240, 检测点 11.3
; check point
;
; 题目中让统计 f000:0 处, 但是那里全是零, 好像也没法改, 所以我统计 data 段了.
; 因为没有用 end 指定入口点所以把 data 段放在了代码后面, data 段放在前面有两个后果
; 1. 会从 data 开始执行, 
; 2. code view 的显示源代码功能会失效, 只能显示反汇编.

code    segment 'code'

; p239, (1) 补全下面的程序, 统计 f000:0 处 32 个字节中大小在 [32, 128] 的数据个数.
_1:     mov     ax, data ; mov ax, 0f000h
        mov     ds, ax

        mov     bx, 0
        mov     dx, 0
        mov     cx, 32
s_1:    mov     al, [bx]
        cmp     al, 32
        jb      s0_1 ; ___
        cmp     al, 128
        ja      s0_1 ; ___
        inc     dx
s0_1:   inc     bx
        loop    s_1

; p240, (2) 补全下面的程序, 统计 f000:0 处 32 个字节中大小在 (32, 128) 的数据个数.
_2:     mov     ax, data ; mov ax, 0f000h
        mov     ds, ax

        mov     bx, 0
        mov     dx, 0
        mov     cx, 32
s_2:    mov     al, [bx]
        cmp     al, 32
        jna     s0_2 ; ___
        cmp     al, 128
        jnb     s0_2 ; ___
        inc     dx
s0_2:   inc     bx
        loop    s_2

; ==============================

        mov     ax, 4c00h
        int     21h
code    ends

data    segment
        byte    32, 33, 28 dup (?), 127, 128
data    ends
        end
