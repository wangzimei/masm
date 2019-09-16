
; http://stackoverflow.com/questions/284797/hello-world-in-less-than-20-bytes
; John T
;
; ml -Foout\ 8086/hello/lt20-3.asm -Feout\

title Hello World
dosseg
.model small
.stack 100h
.data
hello_message db 'Hello World',0dh,0ah,'$'
.code
main  proc
    mov    ax,@data
    mov    ds,ax
    mov    ah,9
    mov    dx,offset hello_message
    int    21h
    mov    ax,4C00h
    int    21h
main  endp
end   main
