
; 汇编语言 2e.pdf
; 王爽
; p244 - p245, 实验 11 编写子程序
; experiment
;
; 编写一个子程序, 将包含任意字符, 以 0 结尾的字符串中的小写字母转变成大写字母, 描述如下
;
; 名称：letterc
; 功能：将以 0 结尾的字符串中的小写字母转变成大写字母
; 参数：ds:si 指向字符串首地址
; 注意：需要转化的是字符串中的小写字母 a - z 而不是其他字符.
;
; 填写 letterc: 标签, 此标签下就是子程序.

datasg  segment
        byte    "Beginner's All-purpose Symbolic Instruction Code.", 0
datasg  ends

codesg  segment 'code'
begin:  mov     ax, datasg
        mov     ds, ax
        mov     si, 0
        call    letterc

        mov     ax, 4c00h
        int     21h

letterc:
        push    cx
        push    si
        mov     cx, 0

letterc_next:
        mov     cl, [si]
        jcxz    string_end

        cmp     cl, 'a'
        jb      not_low_letter
        cmp     cl, 'z'
        ja      not_low_letter

        and     cl, 11011111b
        mov     [si], cl

not_low_letter:
        inc     si
        jmp     letterc_next

string_end:
        pop     si
        pop     cx
        ret

codesg  ends
        end     begin
