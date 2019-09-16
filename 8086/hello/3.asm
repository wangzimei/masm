
; https://helloacm.com/dosbox-hello-world/
;
; 还是报一堆错, masm 非要看到一堆 seg 定义
;
; ml -Foout\ 8086/hello/3.asm -Feout\

mov dx, offset msg
mov ah, 09H
int 21h
int 20h
msg db "Hello, World$"
