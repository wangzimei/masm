
; 汇编语言 2e.pdf
; 王爽
; p279, 杂项
; miscellaneous
;
; p279, 14.4 cmos ram 中存储的时间信息
; 编程, 在屏幕中间显示当前的月份.
;
; 如果使用 xchg 或者 rol, ror 会省几条指令
;
; ml -Foout\ 8086/hbyy2/14m-1.asm -Feout\

       .model   tiny
       .code
start:
        ; 从 cmos ram 的 8 号单元读出当前月份的 bcd 码
        mov     al, 8
        out     70h, al
        in      al, 71h

        ; int 21h 的 2 号功能输出 dl 表示的字符, 所以要在 dl 中存放月份的十位, dh 中放个位
        mov     dl, al      ; dx = 0000 0000 hhhh llll
        mov     dh, al      ; dx = hhhh llll hhhh llll
        mov     cl, 4
        shr     dl, cl      ; dx = hhhh llll 0000 hhhh
        shl     dh, cl      ; dx = llll 0000 0000 hhhh
        shr     dh, cl      ; dx = 0000 llll 0000 hhhh

        ; dl 和 dh 都加上 '0'
        add     dx, 3030h   ; dx = 0000 LLLL 0000 HHHH

        mov     ah, 2
        int     21h         ; 显示月份的十位
        mov     dl, dh      ; dx = 0000 LLLL 0000 LLLL
        int     21h         ; 显示月份的个位

       .exit    0
        end     start
