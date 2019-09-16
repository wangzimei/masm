
; ml -Zs 8086/610guide/ch01.asm

; p???/p14  ch1/Language Components of MASM/Identifiers
; 247- chars
; first char @_$?A-Za-z, others plus 0-9
; masm plus %., option dotname
;
; line          至多 512 字符, 513+ error A2039: line too long
; identifier    至多 247 字符, 248+ error A2043: identifier too long
;
; p30 /p??? ch1/Language Components of MASM/Predefined Symbols
;
; p31 /p??? 基数后缀
; binary        y, b (if the default radix is not hexadecimal)
; octal         o, q
; decimal       t, d (if the default radix is not hexadecimal)
; hexadecimal   h
;
; .RADIX 指定没有后缀的数字字面量使用的基数, 范围 [2, 16], 基数默认 10
; - 有没有重置 radix 为默认值的语句?

.radix 7

num1 = 6
num2 = 10
num3 = 10d

s1r07 textequ % num1
s2r07 textequ % num2
s3r07 textequ % num3

.radix 10

s1r10 textequ % num1
s2r10 textequ % num2
s3r10 textequ % num3

%echo s1r07 s2r07 s3r07 ; 6 10 13
%echo s1r10 s2r10 s3r10 ; 6 7 10

; p32 /p??? ch1/Language Components of MASM/Integer Constants and Constant Expressions/Symbolic Integer Constants
;
; 这 1 节放在第 1 章毫无意义, 读者根本不知道宏, 这里就开始用 =, equ 了, 用的时候还讲不明白
;
; <symbol> equ <expression>     - symbol 不能重新赋值
; <symbol>  =  <expression>     - symbol 能够重新赋值

; in MASM 6.1, Size of Constants = 32
; OPTION EXPR16 or OPTION M510 set it to 16
; 要么是 EXPR16 要么是 EXPR32, 可以重复多次, 为的是可以在多个包含文件中写 option exprxxx
; USE32 or FLAT 时不能写 option expr16, error A2197:expression size must be 32 bits

option expr32
option expr32
option expr32

; p35 /p??? ch1/Language Components of MASM/Data Types
; masm 6.0 之前区分类型和初始化器, 比如 byte 是类型, db 是相应的初始化器. masm 6.1+ 不区分两者, 类型可以当初始化器
; 1. masm 6.0 啥行为?
; 2. 6.1+ 反过来如何, 即初始化器可以当类型吗?
;
; masm 没有数组和串类型
; 类型可具有诸如 langtype, distance (near, far) 的特性
; 自定义类型 struct, union, record
; 新类型 <typename> typedef <qualifiedtype>. 可以用 <qualifiedtype> 定义过程原型

; p45 /p??? ch1/The Assembly Process/Using the OPTION Directive
; option 覆盖相应的命令行选项

; p48 /p??? ch1/The Assembly Process/Conditional Directives

end



; done: *尝试* 用 echo 在汇编时打印数字
; 目前是调用 c 库函数 printf, 32 位代码
;
; ml -Foout/ 8086/610guide/ch01.asm -Feout/

includelib msvcrt.lib
includelib legacy_stdio_definitions.lib

.model flat, c

printf proto

.data
fmt byte '%d %d %d', 10, 0

.code
main proc

; printf("%d %d %d\n", 6r7, 10r7, 10); // 6 7 10
;  6 (radix 7) = 6 (radix 10)
; 10 (radix 7) = 7 (radix 10)

.radix 7
    mov     eax, 10d
    push    eax
    mov     eax, 10
    push    eax
    mov     eax, 6
    push    eax

    push    offset fmt
    call    printf

.radix 10
    ; printf 是 cdecl, 调用者清理栈上的参数, 3 个 eax 和 1 个 offset 共 16 字节
    add     esp, 16
    ret
main endp
end
