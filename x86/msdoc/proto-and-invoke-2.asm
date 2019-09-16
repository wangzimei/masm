;
; https://support.microsoft.com/en-us/kb/73407
;
; 这是该页的第 2 个例子，详细解释见 proto-and-invoke-1，修改之处
; - .MODEL small 改为 .MODEL flat
; - LNK2019 _mainCRTStartup - includelib msvcrt.lib - _mainCRTStartup 调用 main，所以不要在 end 后面跟标号
; - LNK2019 _printf - vs2015 修改了 c 运行时，一些函数放在了 legacy_stdio_definitions.lib 和 legacy_stdio_wide_specifiers.lib
; - 稍微调整了空白

; Assemble options needed: none

includelib msvcrt.lib
includelib legacy_stdio_definitions.lib

            .MODEL flat, c

    ;-----for OS/2--------|
    ;.MODEL small,c,os_os2|
    ;INCLUDELIB OS2.LIB   <---Not needed if "os_os2" indicated. The
    ;INCLUDE    OS2.INC   |   assembler knows to look for os2.lib
    ;---------------------|   in the path set by the lib environment
    ;                     |   variable.

EXTERNDEF _acrtused:WORD

printf      PROTO arg1: Ptr Byte, printlist: VARARG

;The first argument is a pointer to a string. The second is a keyword
; that permits a variable number of arguments.

            .STACK 100h
            .DATA
fmtlist     BYTE    "%s, %d, %lu", 0Ah, 0
string_1    BYTE    "signed byte and unsigned double word", 0
data_1      SBYTE   -2
data_2      DWORD   0FFFFFFFFh

            .CODE
main        PROC
INVOKE      printf, ADDR fmtlist, ADDR string_1, data_1, data_2
main        ENDP
            ret

            end