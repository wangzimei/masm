;
; http://www.asmcommunity.net/forums/topic/?id=25659
;
; 原名 asmcommunity-25659.asm 但在 dos 里只能用 asmcom~1.asm 引用它, 遂改名
; masm 14, /omf prevent link like /c
; ml /c /omf masm/8086/asmcommunity-25659.asm
; link 16.obj,,,,,
; link 后面那些逗号告诉连接器用默认值, 他这个 link 是 16 位的
;
; masm 6.11
; warning a4017: invalid command-line option: -omf
; ml -Foout\ 8086/train/ac25659.asm -Feout\

.model tiny
.code

; 原文没有这句, 导致输出一堆乱码后跟 Hello, World :)
; 因为 com 执行时 cs, ds 一样都指向程序开始处, 而这开始处的 100h 是程序 psp
; 执行时初始 ip 确实是 100h 但编译时 ml 没这么智能, 无法通过 .model 或命令行开关断定起始地址
; org 100h 用来给 offset 的值加上 100h
org 100h

; 如果没有 start: 和 end start
; link: warning l4055: start address not equal to 0x100 for /TINY
start:

; 原文的这两句没必要
; push cs
; pop ds

mov dx, offset sHelloWorld
mov ah, 9
int 21h

mov ax, 4c00h
int 21h

ret

sHelloWorld BYTE "Hello, World :)", 13, 10, '$'

end start
