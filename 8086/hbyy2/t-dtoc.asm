
; test


stack   segment stack

        word    16 dup (?)
stack   ends

code    segment 'code'

        byte    16 dup (?)

start:  mov     ax, code
        mov     ds, ax
        mov     si, 0
        mov     ax, 7cc7h
        mov     dx, 1
        call    dtoc

        mov     ax, 4c00h
        int     21h



        

        ; dtoc 把 dword 转化为十进制表示的字符串
        ; ax - 低 16 位
        ; dx - 高 16 位
        ; ds:si - 字符串首地址
        ; 在 ax 中返回字符串的长度
dtoc:   push    cx ; jcxz
        push    dx
        push    di ; 在逐位除 10 时保存字符串的长度；后来代替 si 作为字符指针

        mov     cx, 10
        mov     di, 0

divide: call    divdw

        push    cx
        inc     di

        mov     cx, ax
        add     cx, dx ; 结果的高位 + 低位 = 0 说明结果是 0
        jcxz    end_divide
        mov     cx, 10
        jmp     divide

end_divide:
        mov     dx, di ; 保存字符串长度
        mov     cx, di
        mov     di, si ; 不改动 si, 因此也不需要保存和恢复 si

transform:
        pop     ax
        add     ax, 30h
        mov     [di], al
        inc     di
        loop    transform

        mov     [di], byte ptr 0
        mov     ax, dx ; 返回字符串的长度

        pop     di
        pop     dx
        pop     cx
        ret

        ; 从 实验 10, 2. 解决除法溢出的问题 中拷贝来的代码
        ;
        ; 名称: divdw
        ; 功能: 进行不会溢出的除法, 被除数是 dword, 除数是 word, 结果是 dword
        ;   * 书上没有说余数是什么类型, 不过既然放 cx 里面那就是 word 型. 余数不会大于除数.
        ; 参数:
        ;   ax - dword 被除数的低 16 位
        ;   dx - dword 被除数的高 16 位
        ;   cx - 除数
        ; 返回:
        ;   ax - 结果低 16 位
        ;   dx - 结果高 16 位
        ;   cx - 余数
divdw:  push    bx
        push    si

        mov     bx, ax  ; ax = L, bx = L, cx = N, dx = H
        mov     ax, dx  ; ax = H, bx = L, cx = N, dx = H
        mov     dx, 0   ; ax = H, bx = L, cx = N, dx = 0
        div     cx      ; ax = int(H / N), bx = L, cx = N, dx = rem(H / N)

        ; 如果这里使用 xchg ax, bx 则能省下 si 寄存器
        mov     si, ax  ; ax = int(H / N), bx = L, cx = N, dx = rem(H / N), si = int(H / N)
        mov     ax, bx  ; ax = L, bx = L, cx = N, dx = rem(H / N), si = int(H / N)
        div     cx      ; ax = int([rem(H / N) * 65536 + L] / N), bx = L, cx = N,
                        ; dx = rem([rem(H / N) * 65536 + L] / N), si = int(H / N)

        mov     cx, dx
        mov     dx, si

        pop     si
        pop     bx
        ret

code    ends
        end     start
