
; 汇编语言 第二版
; 王爽
;
; ml -Foout\ 8086/hbyy2/4a-1.asm -Feout\
; LINK : warning L4021: no stack segment
; LINK : warning L4038: program has no starting address

assume cs: codesg

codesg  segment
    mov ax, 0123h
    mov bx, 0456h
    add ax, bx
    add ax, ax

    mov ax, 4c00h
    int 21h
codesg  ends
end
