
; 跳到其它逻辑段中的标签时需要 far ptr, 否则
; error A2107: cannot have implicit far jump or call to near label
;
; 这个程序从第 12 行第 10 列开始打印 5 个绿色字符 hello
; 没有使用栈, 所以 ss:bp 可以用来指向 data 段.

COLOR       = 00000010b
SCREEN_BASE = 0b800h
SCREEN_OFF  = (12 * 80 + 10) * 2

code1   segment

        jmp     far ptr other

code1   ends
code2   segment

return: mov     ax, 4c00h
        int     21h

other:  mov     ax, SCREEN_BASE
        mov     ds, ax

        mov     ax, data
        mov     ss, ax

        mov     di, SCREEN_OFF
        mov     bp, 0

        mov     cx, 5
write:  mov     ax, [bp]
        mov     [di], ax
        add     di, 2
        add     bp, 2
        loop    write

        jmp     return

code2   ends
data    segment

        byte    'h', COLOR, 'e', COLOR, 'l', COLOR, 'l', COLOR, 'o', COLOR

data    ends
        end
