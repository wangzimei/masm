
; 汇编语言 2e.pdf
; 王爽
; p214, 问题 10.2
; problem
;
; p214 给出的程序把 data 段中的几个以零结尾的字符串转换为大写, 问题在于子程序修改了 cx,
; 主程序又依赖 cx 控制循环. 因此 p215 中规定以后编写子程序的标准框架:
;
; 子程序开始:
;   子程序中使用的寄存器入栈
;   子程序内容
;   子程序中使用的寄存器出栈
;   返回 (ret, retf)
;
; 下面是根据这个标准框架修改的 p214 的程序.
; 如果有 jcxnz 指令则子程序可以省去一个转移.

        assume  cs: code

data    segment
        byte    'word', 0
        byte    'uinx', 0
        byte    'wind', 0
        byte    'good', 0
data    ends

code    segment
start:  mov     ax, data
        mov     ds, ax
        mov     bx, 0

        mov     cx, 4
s:      mov     si, bx
        call    capital
        add     bx, 5
        loop    s

        mov     ax, 4c00h
        int     21h

capital:
        push    cx
        push    si

change: mov     cl, [si]
        mov     ch, 0
        jcxz    ok
        and     byte ptr [si], 11011111b
        inc     si
        jmp     short change

ok:     pop     si
        pop     cx
        ret

code    ends
        end     start
