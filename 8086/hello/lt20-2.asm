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

Producing .com Files With MASM
http://support.microsoft.com/kb/24954/en-us

MASM version 6.0 is the first version of the assembler to support the tiny model.
Use the following steps the produce a .com file in MASM 6.0.

1. Use .model tiny. Declare logical segments using the simplified segment directives
or full segment declarations.

-or-

Do not use the .model directive and assemble with /AT. Use full segment declarations.

2. Make sure that the first statement in the the code segment is ORG 100h.
3. Build the .com file.

Compiling and linking in one step:
If .model tiny was used, no options are needed. The linker will automatically receive
the /TINY switch, the file extension on the file produced will be .com, and the
executable is indeed a .com file.

-or-

Performing a separate link: Specify the /TINY option on the link command line. The
linker will issue the following harmless warning
L4045: name of output file is 'filename'
where 'filename' will have a .com extension.

/AT 和 .model tiny 的区别
Microsoft MASM 6.1 Programmer's Guide.pdf，p56，Tiny Model
/AT does not insert a .MODEL directive. It only verifies that there are no base or
pointer fixups, and sends /TINY to the linker.

