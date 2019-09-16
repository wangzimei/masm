
; 汇编语言 2e.pdf
; 王爽
; p194, 检测点 9.2
; check point
;
; 补全从 s 到 jmp short s 之间的四句话, 利用 jcxz 实现在内存 2000h 段中查找第一个值是 0 的字节,
; 找到后将它的偏移地址存储在 dx 中.
;
; 分析：找遍 64k 也没找到 0 的话, 四句话内怎么能跳出循环?
; 我没有把 cx 置零, 因为知道进入程序时 cx 是零, 并且不想在循环内反复置零.
;
; 观察汇编结果
;
; 0604:0000 b80020      mov     ax, 2000
; 0604:0003 8ed8        mov     ds, ax
; 0604:0005 bb0000      mov     bx, 0000
; 0604:0008 8a0f        mov     cl, byte ptr [bx]
; 0604:000a e303        jcxz    000f
; 0604:000c 43          inc     bx
; 0604:000d ebf9        jmp     0008
; 0604:000f 8bd3        mov     dx, bx
; 0604:0011 b8004c      mov     ax, 4c00
; 0604:0014 cd21        int     21
;
; 发现 jmp short s 对应的机器码是 eb f9, eb f9 的反汇编结果是 jmp 0008 而不是 jmp short 0008, 所以
; * short 是不是可有可无? 我从源代码中删除 short, 汇编得到的机器码没有变化.
; * 汇编器能够发现转移距离在 [-128, 127] 之间, 从而能够生成段内短转移的 eb nn 机器码?
; * jmp short 对应机器码 eb nn, 这个机器码由汇编器生成, 不需要我们指定?
; * jmp 绝对转和 jmp short 相对转毕竟不一样（虽然可以汇编出一样的结果）, 不能互换吧?
; * 如果转移符合短转移的距离则一定会汇编成短转移?

assume  cs: code

code    segment
start:  mov     ax, 2000h
        mov     ds, ax
        mov     bx, 0

s:      mov     cl, [bx]    ; 1
        jcxz    ok          ; 2
        inc     bx          ; 3
        jmp     short s

ok:     mov     dx, bx
        mov     ax, 4c00h
        int     21h
code    ends
end start
