
xxx     segment

        ;org     100h
start:
        mov     ax, [bp][di]


; 如果 f 未用 far 修饰
        ;mov     ax, seg code2
        ;mov     es, ax
        ;call    es:f;

        call    f

; 远调用段内近过程
        call    cs:fn
        pop     ax

        mov     ax, 4c00h
        int     21h

fn      proc
        ret
fn      endp
xxx     ends

code2   segment "code"
f       proc    far

        ret
f       endp

f2      proc 

        call    f
        ret
f2      endp

f3:     ret
code2   ends

stack   segment stack
        db      16 dup (?)
stack   ends
        end     start
