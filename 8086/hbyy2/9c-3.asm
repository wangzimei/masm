
; 汇编语言 2e.pdf
; 王爽
; p195, 检测点 9.3
; check point
;
; 补充注释标记的一句指令, 利用 loop 实现在内存 2000h 段中查找第一个值是 0 的字节,
; 找到后将它的偏移地址存储在 dx 中.
;
; p195, 9.8 - loop 指令
; 这里说 loop 指令是循环指令, 所有的循环指令都是短转移.
; 于是我在 loop 中插入了分配内存的语句 byte 128 dup (?) 得到如下错误
;  Assembling: c9-3.asm
; c9-3.asm(29): error A2075: jump destination too far : by 8 byte(s)
; 看来说 loop 是短转移所言非虚.
;
; p197, 9.10 - 编译器对转移位移超界的检测
; 这一节做了和上面一样的事情来证明短转移不能超出 [-128, 127]

assume  cs: code

code    segment
start:  mov     ax, 2000h
        mov     ds, ax
        mov     bx, 0

s:      mov     cl, [bx]
        mov     ch, 0
        inc     cx ; 补充这句指令
        inc     bx
        ; byte    128 dup (?)
        loop    s

ok:     dec     bx
        mov     dx, bx
        mov     ax, 4c00h
        int     21h
code    ends
end start
