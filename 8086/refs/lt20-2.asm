;
; 一些乱码后跟 HELLO WORLD
;
; 这些人调用 int21h/ah9 都不设置 dx? 可能是为了短代码
;
; http://stackoverflow.com/questions/284797/hello-world-in-less-than-20-bytes
; 这是 BoltBait 给出的第二个代码。第一个代码在 dosbox 里面运行不正常。
;
; Jonas Gulle 在下面的回帖中给出了一段代码，并且说该代码
; Not "well behaved", but better than BoltBaits which can randomly end prematurely if there
; is a '$' in the PSP. This program will output "Hello World" among with some junk characters.
; 不过 Jonas Gulle 的代码我看不懂
;
; ml -Foout\ 8086/hello/lt20-2.asm -Feout\
; link: warning l4055: start address not equal to 0x100 for /TINY

        .MODEL  TINY
        .CODE
CODE    SEGMENT BYTE PUBLIC 'CODE'
        ASSUME  CS:CODE,DS:CODE
        ORG     0100H
        MOV    AH,9
        INT    21H
        RET
        DB    'HELLO WORLD$'
CODE    ENDS
end
