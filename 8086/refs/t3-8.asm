
; 80x86汇编语言程序设计教程
; p102
; 程序名: T3-8.asm
; 功  能: ASCII 码转换为十六进制数

data    segment
xx      db ? ; 存放十六进制数
ascii   db 'a' ; 假设的 ASCII 码
data    ends

stack   segment para stack
stack   ends

code    segment
        assume cs: code, ds: data
start:
    mov ax, data
    mov ds, ax

    mov al, ascii

lab:
    cmp al, '0'
    jb  lab5 ; 小于 0 转范围外处理

    mov ah, al ; 设在 0 ~ 9 之间
    sub ah, '0'
    cmp al, '9'
    jbe lab6 ; 确实在 0 ~ 9 之间转到保存处

    cmp al, 'A'
    jb  lab5 ; 小于 A 转范围外处理

    mov ah, al ; 设在 A - F 之间
    sub ah, 'A' - 10
    cmp al, 'F'
    jbe lab6 ; 确实在 A - F 之间转到保存处

    cmp al, 'a'
    jb  lab5 ; 小于 a 转范围外处理

    mov ah, al ; 设在 a - f 之间
    sub ah, 'a' - 10
    cmp al, 'f'
    jbe lab6 ; 确实在 a - f 之间转到保存处

lab5:
    mov ah, -1 ; 范围外处理

lab6:
    mov xx, ah ; 保存转换结果

    mov ah, 4ch
    int 21h
code    ends
        end start
