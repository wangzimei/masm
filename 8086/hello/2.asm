
; https://eli.thegreenplace.net/2009/12/21/creating-a-tiny-hello-world-executable-in-assembly
;
; 这个要用 nasm 编译
; nasm -f bin helloworld.asm -o helloworld.com
; 我用下面命令编译报一堆错
; ml -Foout\ 8086/hello/2.asm -Feout\

org 100h
mov dx,msg
mov ah,9
int 21h
mov ah,4Ch
int 21h
msg db 'Hello, World!',0Dh,0Ah,'$'
