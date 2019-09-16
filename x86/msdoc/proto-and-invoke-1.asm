;
; https://support.microsoft.com/en-us/kb/73407
;
; ========== 原文
;
; proto 定义过程原型，和 c 的函数原型很像。语法，
; label PROTO [distance] [langtype] [,[parameter]:tag]
; 汇编程序用 proto 语句检查参数类型、数量，确定函数命名约定。指出函数参数的方式是列出类型，可带参数名，例子
; myfunc PROTO C arg1:SWORD, arg2:SBYTE
; 这表明 myfunc 函数接受两个参数，第一个是有符号 word，第二个是有符号 byte。用类型 VARARG 定义可变参数列表
;
; invoke 生成调用函数的代码，invoke 要求先用 proc、externdef、typedef、proto 语句之一定义函数，语法
; INVOKE expression [,arguments]
;
; 由于汇编程序知道期望什么样的参数和调用约定，它可以把参数按正确顺序压栈、生成正确的函数名、按调用约定清理栈
; 给 invoke 的参数如果比 proto 指定的宽度小，masm 加宽它，这种类型转换使用 (e)ax 和 (e)dx，留意这个情况
;
; ==========
;
; 原文说 invoke 要求那 4 个语句之一，我记得 invoke 要求 proto？
;
; 该页给了两个示例代码，第一个用 call，第二个用 invoke，下面是第一个示例代码，有几处修改
; - /MX 是 masm.exe 的命令行开关，区分 public 和 extern 名称的大小写，ml.exe 无此开关，程序也不需要此开关
; - 不想用 dosbox 之类的运行 16 位程序，为了编译为 win32，.MODEL small 改为 .MODEL flat
; - 注释了 _acrtused
; - win32 的 printf 的 %d 是 32 位的，所以用 cbw 扩展为 word 后还要用 cwde 扩展为 dword，然后 push eax
; - 为了保存 flat 下的 offset，mov ax, offset string_1 改为 mov eax, offset string_1
; - 既然一些 ax 改成了 eax，call 之前 push 了 5 次、前 2 次是 push word ptr，那么 call 之后的 add sp, 0ah 要改为 add sp, 10h
; - LNK2019 _mainCRTStartup - includelib msvcrt.lib - _mainCRTStartup 调用 main，所以不要在 end 后面跟标号
; - LNK2019 _printf - vs2015 修改了 c 运行时，一些函数放在了 legacy_stdio_definitions.lib 和 legacy_stdio_wide_specifiers.lib
;   http://stackoverflow.com/questions/33721059/call-c-standard-library-function-from-asm-in-visual-studio
; - 稍微调整了空白

; Assemble options needed: /MX

includelib msvcrt.lib
includelib legacy_stdio_definitions.lib

            .MODEL flat, c      ; The "c" langtype prepends
                                ; labels with an underscore.
    ;-----for OS/2-------
    ;INCLUDELIB OS2.LIB
    ;INCLUDE    OS2.INC
    ;--------------------

;EXTRN      _acrtused: NEAR
EXTRN       printf: NEAR

            .DATA
fmtlist     db      "%s, %d, %lu", 0Ah, 0
string_1    db      "signed byte and unsigned double word", 0
data_1      db      -2
data_2      dd      0FFFFFFFFh

            .CODE
main        PROC
            push    word ptr data_2 + 2     ; push the high word of data_2
            push    word ptr data_2         ; push the low word of data_2
            mov     al, data_1
            cbw                             ; converts data_1 to a word
            cwde
            push    eax
            mov     eax, offset string_1    ; load the address of string_1
            push    eax                     ; push the address on the stack
            lea     eax, fmtlist            ; load the address of fmtlist
            push    eax                     ; push the address on the stack
            call    printf                  ; call the C library function
            add     sp, 10h                 ; adjust the stackpointer
main        ENDP
            ret

            end