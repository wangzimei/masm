
; 汇编语言 2e.pdf
; 王爽
; p114, 程序 5.3
;
; 功能: 把 ffff:6（ffff * 10h + 6）的一个字节乘以 3
; 目的: 单步执行, 以观察寄存器变化和 loop 指令的细节
; 复习: CS:IP 指向程序的第一条指令; DS:0 指向程序的内存首地址, 这里有 256（100h）字节的 PSP
; 步骤: [ffff:6] 读到 ax 中, 把 ax 加到 dx 三次, 返回
;
; 在 *.com 中 psp 开始于 cs:0, 初始 cs = ds, ip = 100h; 在 *.exe psp 开始于 ds:0, 初始 ip = 0
; tiny 的意思就是只有一个段, 数据和代码共享该段
;
; p93: 书中使用的编译器是 masm 5.0, masm.exe
; p95: 书中使用的连接器是微软的 Overlay Linker 3.60, link.exe
; 我的编译器是 masm 6.11, ml.exe; 连接器是 link.exe
; Microsoft (R) Segmented Executable Linker  Version 5.31.009 Jul 13 1992
;
; ml -Foout\ 8086/hbyy2/5p-3.asm -Feout\
; LINK : warning L4021: no stack segment
; LINK : warning L4038: program has no starting address
;
; ml -AT -Foout\ 8086/hbyy2/5p-3.asm -Feout\
; LINK : warning L4055: start address not equal to 0x100 for /TINY

assume cs: code

code    segment
    mov ax, 0ffffh
    mov ds, ax
    mov bx, 6
    mov al, [bx]

    mov ah, 0
    mov dx, 0

    mov cx, 3
s:
    add dx, ax
    loop s

    mov ax, 4c00h
    int 21h
code    ends
end
