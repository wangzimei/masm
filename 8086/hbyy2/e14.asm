
; 汇编语言 2e.pdf
; 王爽
; p281, 实验 14 访问 cmos ram
; experiment
;
; 编程, 以 年/月/日 时:分:秒 的格式显示当前日期、时间。
;
; p279, 14.4 cmos ram 中存储的时间信息
; 在 cmos ram 中存放着当前的时间, 每条信息的长度都是一字节, 存放单元为:
; 0         2       4       7       8       9
; second    minute  hour    day     month   year
; 这些数据以 bcd 码的方式存放。
;
; 往字符缓冲区放的时候注意字节序

       .model   tiny
       .code
        org     100h
start:
        mov     ax, cs
        mov     ds, ax
        mov     di, offset output
        mov     si, offset scale

        mov     cx, 6
s:      mov     al, [si]
        out     70h, al
        in      al, 71h

        mov     dx, cx
        mov     cl, 4           ; ax = xxxx xxxx hhhh llll
        mov     ah, al          ; ax = hhhh llll hhhh llll
        shr     al, cl          ; ax = hhhh llll 0000 hhhh
        and     ah, 00001111b   ; ax = 0000 llll 0000 hhhh
        add     ax, 3030h
        mov     [di], ax
        mov     cx, dx

        inc     si
        add     di, 3
        loop    s

        ; 显示加工后的字符串
        mov     dx, offset output
        mov     ah, 9
        int     21h
       .exit    0

scale   byte    9, 8, 7, 4, 2, 0
output  byte    '--/--/-- --:--:--$'
        end     start
