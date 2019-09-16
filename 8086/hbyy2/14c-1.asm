
; 汇编语言 2e.pdf
; 王爽
; p277, 检测点 14.1
; check point
;
; (1) 编程, 读取 cmos ram 的 2 号单元的内容
; (2) 编程, 向 cmos ram 的 2 号单元写入 0

       .model   tiny
       .code
        org     100h
start:
        ; 读 cmos ram 的 2 号单元
        mov     al, 2
        out     70h, al

        in      al, 71h

        ; 向 cmos ram 的 2 号单元写入 0
        mov     al, 2
        out     70h, al

        mov     al, 0
        out     71h, al

       .exit    0
        end     start
