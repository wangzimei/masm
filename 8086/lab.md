
## stack

```
; 16 位程序栈的一个元素是两字节
; 这程序当时 (2013) 应该是用 cv 调试, visual studio 查看 16 进制的; 现在 (2019) 用 debug 和 powershell
;
; ==================== com
;
; com 执行时, 开始栈顶是 fffe, push 一个 16 位值后栈顶变为 fffc
; fffc, fffd, fffe, ffff 总共是 4 个字节但是只使用了两个字节
;
; ml -Dcom -Foout\ 8086/refs/stack.msm -Feout\
;
; debug out\stack.com
; r, 看到列出的寄存器里 sp = fffe
; d fff0, 看到 fffe 和 ffff 是 0 0
; t, 单步执行, 观察寄存器
;
; ==================== exe
;
; 在 exe 中自己设定栈指针时可以使用栈的第一个元素
; 用 77 填充 stack 段, 并
; - 用 stack 修饰 stack 段: 栈顶是 20h, 但 1e 和 1f 的值是 ff 而不是 77
;   用 visual sutdio 查看该文件生成的 exe 发现 stack 段的最后两个字节还是 77, 所以
;   1e 和 1f 应该是在运行的时候从 77 修改成 ff 的.
; - 不修饰 stack 段, 这需要自己调整 ss:sp: 此时 stack 段是 20h 个 77, 最后两字节未被修改
;
; ml -Foout\ 8086/refs/stack.msm -Feout\
;
; debug out\stack.exe
; r, 有 ss = 076f, sp = 0020
; d ss:0, 看到 0 ~ 1d 是 77, 1e 和 1f 是 ff ff
;
; format-hex out/stack.exe
; 最后 32 (20h) 字节是 77

ifdef com

       .model   tiny
       .code
start:  mov     ax, 4c00h
        push    ax
        push    ax

        pop     bx
        pop     bx
        pop     bx

        int     21h
else

; 相当于 .model small

code    segment 'code'
start:  mov     ax, 4c00h
        push    ax
        push    ax

        pop     bx
        pop     bx
        pop     bx

        int     21h
code    ends

stack   segment stack
        word    16 dup (7777h)
stack   ends

endif

        end     start


2019, 现在知道为啥 com 一开始栈顶是 0xfffe 且 [0xfffe] = word 0 了
因为 com 要支持 retn 结束程序. 见 abc/2-life.asm
```

## echo

```
; https://msdn.microsoft.com/en-us/library/2109att2.aspx
; echo, same as %out
;
; 输出分号? 注释在 echo 之前处理, echo 看不到, 也就不能输出注释
; 输出空格? echo 忽略其后的空格
;
; Microsoft MASM 6.1 Programmer's Guide.pdf
; p30 /p15  Predefined Symbols
; p256/p184 Expansion Operator as First Character on a Line
;
; 用了两次 %
; - 定义文本宏时 - 对常量表达式求值, 把得到的数字按当前的基数转为字符串
; - 放在 echo 之前时 - 展开本行的文本宏和宏函数
;
; ml -Zs 8086/610guide/echo.msm

%out @Cpu       ; % 是 %out 名字的一部分, 本行不以 % 打头, 输出文本 @Cpu
%%%%%echo @Cpu  ; 本行以 % 打头, 替换本行的文本宏和宏函数, 然后 echo. 其余的 % 忽略掉了?

echo ; 空行

; 把数字 @cpu 转换为文本, 赋值给文本宏 cpu
cpu textequ %@cpu

%echo   cpu ; 本行以 % 打头, 替换本行的文本宏和宏函数, 然后 echo. 忽略了 echo 和 cpu 之间的空白
%out    cpu ; 输出文本 cpu
%%out   cpu ; 本行以 % 打头, 替换本行的文本宏和宏函数, 然后 echo

echo

; 此句定义符号 @Model, @Interface
.model tiny, c

model textequ %@Model
%echo model

echo

interface textequ %@Interface
%echo interface

end
```


## 610guide, p???/p94, Searching Arrays

这里说 scas 比较 es:di 和 cx; 错误, 应该是比较 es:di 和 al/ax/eax; 给出的代码没错

```
; ml -Foout\ dd.msm -Feout\

xxx segment

start:

; 根据命令行参数决定调用哪个函数
; 这些函数都是书里的原文; 我写的代码是 "根据命令行选择调用哪个"
; 只接受两种参数: xlat 和 xxx, xxx 还是空函数
;
; 提供命令尾 (命令参数) 时, psp:80h 为其长度, psp:81h 为其拷贝
; 初始时 ds = es = seg psp

; 从 psp:80h 处取命令尾长度
        xor     bx, bx
        mov     bl, ds:[80h] ; masm 认为 [80h] 是 80h

; 长度是 0 或者大于 7eh 时都不处理
        cmp     bl, 0
        jz      exit ; 未提供命令尾
        cmp     bl, 7eh
        ja      exit ; 命令尾长度大于 7eh, psp 保存不下

; 找命令尾的第一个非空格
        mov     cx, bx      ; 命令尾长度
        mov     di, 81h     ; 命令尾地址
        mov     al, " "     ; 找空格
        cld                 ; 顺着串的方向 (地址从低到高)
        repz    scasb       ; 只要是空格就继续

; 全空格的话结束时 zf = 1 (zr), 但全空格时命令尾长度算 0, 在前面就跳走了, 不会执行这里
;       jz      exit        ; 没找到非空格

; scas 找到时 di 指向匹配的下一个字符, 这里要让他指回匹配的字符
        dec     di

; 由于串指令修改 di 所以保存至 bx, 这就假设后面的代码不会修改 bx
; 函数调用里修改 bx 了, 但调完函数就退出了, 不再使用 bx
        mov     bx, di

; 把 cs 里定义的 function name 逐一和 es:di 比较, 其中 es = seg psp
; 正常情况下需要循环, 但那就要把函数地址放到一个表里面, 所以这里只是用一系列 if

; 先令 ds = cs, ds 在后面都不会修改; si 要修改以指向各个函数名
        mov     ax, cs
        mov     ds, ax

call1:  mov     si, offset fname1
        repz    cmpsb
        jnz     call2
        call    $xlat
        jmp     exit

call2:  mov     di, bx
        mov     si, offset fname2
        repz    cmpsb
        jnz     call3
        call    $fname2
        jmp     exit

call3:

; 两个 label 的差等于啥? echo 输出 43, 在 debug 里查看 call3 和 call2 之间代码的字节数 = e = 14
; 也不应该期望这个差值是字节数吧? 因为字节数编译之后才知道
; 在 p???/p187 Defining Repeat Blocks with Loop Directives 中, offset l1 - offset l2 称为 address span
diff2?3 textequ % call3 - call2
%echo "diff2?3" is diff2?3

        mov     ax, call3
        sub     ax, call2
        nop             ; 执行上面的代码, 结果也是 ax = 0xe = 14
        nop


exit:   mov     ax, 4c00h
        int     21h

fname1  byte    "xlat"
fname2  byte    "xxx"

; p???/p94  Translating Data in Byte Arrays
; xlat = xlatb, 隐含使用 al. 如果带参数, al = [参数 + al]; 否则 al = [ds:bx + al]

; Table of hexadecimal digits
hex     BYTE    "0123456789ABCDEF"
convert BYTE    "You pressed the key with ASCII code "
key     BYTE    ?, ?, "h", 13, 10, "$"

$xlat:  ; Get a key in AL
        mov     ah, 8
        int     21h

        mov     bx, OFFSET hex      ; Load table address
        mov     ah, al              ; Save a copy in high byte
        and     al, 00001111y       ; Mask out top character
        xlat

        mov     key[1], al          ; Store the character
        mov     cl, 12              ; Load shift count
        shr     ax, cl              ; Shift high char into position
        xlat

        mov     key, al             ; Store the character
        mov     dx, OFFSET convert  ; Load message
        mov     ah, 9               ; Display character
        int     21h                 ; Call DOS
        ret

$fname2:ret

xxx     ends

stack   segment stack
        db      16 dup (?)
stack   ends

        end     start
```


## windows

**入口**

coff 希望入口标签以下划线开头, warning A4023:with /coff switch, leading underscore required for start address

link 需要 -subsystem, 没有指定时尝试从入口标签推导它, 规则是

- _main 是 console, _WinMain@16 是 windows, 区分大小写; link 不认 16 位汇编常用的 start
- 入口不是上面的两个标签时报错 LINK : fatal error LNK1221: 无法推导出子系统，必须定义它

**段属性**

- 16 位程序所有内存都是可执行-读写; 32 位 pe 的段对应节 (section), 具有单独的执行, 读, 写属性
- 32 位程序的段需要标记为 flat

**节属性**

- link 认识段名 _TEXT 和具有 "code" 类的段, 对应的节的属性是可执行-只读
- link 认识段名 _DATA, _DATA 和 link 不认识的段对应的节的属性是不可执行-读写
- editbin 可以修改节的属性

> http://masm32.com/board/index.php?topic=602.15 sinsi August 22, 2012, 06:36:17 PM<br>
.code expands to "_TEXT segment public"<br>
.data expands to "_DATA segment public"

**windows api**

proto near32 stdcall

**退出**

必须调用 ExitProcess, ret 只结束当前线程. 返回值放 eax.<br>
https://stackoverflow.com/questions/39904632/why-is-exitprocess-necessary-under-win32-when-you-can-use-a-ret

```
; ml -Foout/ dd.masm -Feout/

_TEXT   segment flat
_main:

        includelib kernel32.lib
GetStdHandle    proto near32 stdcall :dword
WriteConsoleA   proto near32 stdcall :dword, :dword, :dword, :dword, :dword

        push    -11 ; -11 = STD_OUTPUT_HANDLE
        call    GetStdHandle ; sets eax on return

; HANDLE hConsoleOutput, const VOID *lpBuffer, DWORD nNumberOfCharsToWrite,
; LPDWORD lpNumberOfCharsWritten, LPVOID lpReserved. push backwards
        push    0
        push    offset dwd
        push    sizeof s
        push    offset s
        push    eax
        call    WriteConsoleA

        ret
_TEXT   ends

data    segment flat
s       byte    "32-bit program compiled with masm <insert @version here>"
dwd     dword   ?
data    ends

        end     _main
```

## crt

windows crt 程序属于 win32 程序, crt 有额外要求

**入口**

- crt 连接 crt lib, 这里面有入口, 所以使用 crt 的程序 end 不能后跟标签
- crt 入口要以 cdecl 调用 _main, 所以要么在程序里定义 `main proc c`, 要么定义 public 标签 _main

**c 运行时函数** proto near32 c, 既然是 cdecl, 调用方要清理栈

```
; 从命令行生成时需要 includelib msvcrt.lib, 从 visual studio 2019 生成时不需要,
; 因为 vs 给 link 传的一堆 lib 里已经包含了
; includelib legacy_stdio_definitions.lib 可能是以前版本的 vs 或 ml 需要
;
; ml -Foout/ dd.masm -Feout/

_TEXT   segment flat

        includelib msvcrt.lib
puts    proto   near32 c

main    proc    c
        push    offset sz
        call    puts
        add     esp, 4
        ret
main    endp
_TEXT   ends

data    segment flat
sz      byte    "hello", 0
data    ends

        end
```

## 早期 crt 代码

早期的 crt/puts 代码使用简化段, 现在看 .686p, .code 等实在是莫名其妙, 所以不再使用

```
; ml -Foout/ dd.masm -Feout/

includelib msvcrt.lib

.386
.model  flat, c

.data
sz      byte    'hello', 0

.code

puts    proto

main    proc
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
main    endp

        end
```




