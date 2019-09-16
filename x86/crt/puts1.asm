
; ml -Foout/ x86/crt/puts1.asm -Feout/

includelib msvcrtd.lib

.model flat, c
.386

puts proto

.data
sz  byte 'hello', 0

.code
main proc
    push    offset sz
    call    puts
    add     esp, 4

    ; esp, ecx 现在也能用来寻址了
    add     eax, [esp]

    ; error A2031: must be index or base register
    ;add     ax, [sp]
    ;mov     ax, [cx]
    mov     bp, sp

    ; error A2155: cannot use 16-bit register with a 32-bit address
    ;add     ax, [bp]

    ; 0xC0000096: Privileged instruction
    ; 2019.7.1, masm 14.21.27702.2, win10 执行时没任何错误, 但估计指令也不会生效
    ;sti
    ;cli

    ret
main endp

end