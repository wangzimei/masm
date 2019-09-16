;
; 执行输出一堆乱码
; - 没指出起始地址, 所以是从第一字节开始执行?
; - db 之后才写指令, 怎么避免执行 db 的那些字节?
; - int21h/ah9 的 dx 是通过 inc dh 设置的? 有啥玄机?
;
; ml 14.21.27702.2
; ml -? 没有 /AT 选项
; ml -Zs 8086/hello.asm -omf
;
; ml -Foout\ 8086/hello/lt20-1.asm -Feout\
; link: warning l4055: start address not equal to 0x100 for /TINY

; 下面的注释是原文, 实际上有了 .model tiny 后就不需要 /AT 了
; ML /AT HELLO.ASM

        .MODEL  TINY
        .CODE
CODE    SEGMENT BYTE PUBLIC 'CODE'
        ASSUME  CS:CODE,DS:CODE
        ORG     0100H
        DB  'HELLO WORLD$', 0
        INC DH
        MOV AH,9
        INT 21H
        RET

; 原文没有这句话, 结果是 fatal error a1010: unmatched block nesting: _TEXT
code    ends
end
