
; 汇编语言 2e.pdf
; 王爽
; p169 - p170，问题 7.9
; problem
;
; 将 datasg 段中每个单词的前 4 个字母改为大写字母

datasg  segment
        byte '1. display      '
        byte '2. brows        '
        byte '3. replace      '
        byte '4. modify       '
datasg  ends

stacksg segment stack
        word 8 dup (0)
stacksg ends

codesg  segment
start:  mov     ax, datasg
        mov     ds, ax
        mov     bx, 0

        mov     cx, 4
outer:  push    cx
        mov     si, 0

        mov     cx, 4
inner:  mov     al, [bx + 3 + si]
        and     al, 11011111b
        mov     [bx + 3 + si], al
        inc     si
        loop    inner

        add     bx, 16
        pop     cx
        loop    outer

        mov     ax, 4c00h
        int     21h
codesg  ends
end start
