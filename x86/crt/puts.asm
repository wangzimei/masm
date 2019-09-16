
; ml -Foout/ x86/crt/puts.asm -Feout/

includelib msvcrt.lib
includelib legacy_stdio_definitions.lib

.386
.model flat, c

puts proto

.data
sz  byte 'hello', 0

.code
main proc
    push    offset sz
    call    puts
    add     esp, 4
    ret
main endp

end
