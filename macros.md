

## A crash course

- 确保已经安装了 masm, 在命令行输入 ml 回车以确认
- 在命令行 cd 到本项目目录, 比如 c:\code\masm
- 在此目录新建文件 dd.msm
- 把后面的代码粘贴到 dd.msm 里, 在命令行用 ml -Zs dd.msm 运行

**输出文本**

```
echo hello world
end
```

**输出变量**

```
int1 = 3
str1 textequ <some text>
str2 textequ % int1

% echo int1 = str2, str-1 = str1
end
```

**循环, 函数调用, 输出计算后的值**

```
fibonacci_cyc macro n: =<5>
    local n1, n2, n3, i

    i = 2
    n1 = 0
    n2 = 1

    ;; can be `repeat n - 2` thus eliminates `i`
    while i lt n
        n3 = n1 + n2
        n1 = n2
        n2 = n3
        i = i + 1
    endm

    exitm % n1 + n2
endm

% echo fibonacci_cyc(47)
; 47 (2971215073) is its limit
end
```

**分支, 递归函数**

```
fibonacci_rec macro n: =<5>
    if n lt 1
        exitm <0>
    elseif n eq 1
        exitm <1>
    else
        exitm % fibonacci_rec(% n - 1) + fibonacci_rec(% n - 2)
    endif
endm

% echo fibonacci_rec(20)
end
```

**计算字符串长度**

从命令行用 -D 传入字符串变量 s, 比如 `ml -D s="how would you count this?" -Zs dd.msm`

```
ifdef s
    len1 sizestr s
    len2 textequ % len1

    % echo s
    % echo has a length of len2
else
    echo variable s is not defined
endif
end
```

\* *试试 s="the name is s"*

**输出 masm 程序**

因为这次的宏用来产生源代码, 所以无需使用 -Zs. 用 `ml dd.msm` 生成 dd.exe, 然后 `dd` 运行它.

```
if @version lt 615

start   textequ <main>

xxx     segment stack
start:
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset s
        mov     ah, 9
        int     21h

        mov     ax, 4c00h
        int     21h

s       byte    "16 bit program compiled with masm < 615$", 16 dup (?)
xxx     ends

else

start   textequ <_main>
        
xxx     segment flat "code"
start:

includelib      kernel32.lib

GetStdHandle    proto near32 stdcall :dword
WriteConsoleA   proto near32 stdcall :dword, :dword, :dword, :dword, :dword

        push    -11 ; -11 = STD_OUTPUT_HANDLE
        call    GetStdHandle ; sets eax on return

; HANDLE hConsoleOutput, const VOID *lpBuffer, DWORD nNumberOfCharsToWrite, LPDWORD lpNumberOfCharsWritten, LPVOID lpReserved
; push backwards
        push    0
        push    offset dwd
        push    sizeof s - 1
        push    offset s
        push    eax
        call    WriteConsoleA

        ret
xxx     ends

data    segment flat
s       byte    "32 bit program compiled with masm 615+", 0
dwd     dword   ?
data    ends

endif
        end     start
```


## 目录

- [A crash course](#a-crash-course)
- [目录](#目录)
- [概述](#概述)
    - [hello world](#hello-world)
- [宏程序](#宏程序)
    - [常量表达式](#常量表达式)
    - [变量](#变量)
    - [常见操作符](#常见操作符)
    - [分支](#分支)
    - [循环和跳转](#循环和跳转)
    - [重复块](#重复块)
        - [repeat](#repeat)
        - [while](#while)
        - [for, forc](#for-forc)
        - [非行首的重复块](#非行首的重复块)
    - [用于处理字符串的指示和预定义函数](#用于处理字符串的指示和预定义函数)
    - [输入输出](#输入输出)
        - [包含](#包含)
    - [展开](#展开)
    - [文本宏](#文本宏)
    - [宏过程](#宏过程)
    - [宏函数](#宏函数)
        - [bug: 莫名其妙的调用](#bug-莫名其妙的调用)
    - [两种查找文本宏和宏函数的模式](#两种查找文本宏和宏函数的模式)
        - [模式 1](#模式-1)
        - [模式 2](#模式-2)
        - [示例: 宏名](#示例-宏名)
        - [撮合](#撮合)
        - [一些性质](#一些性质)
    - [opattr, @cpu, pushcontext, popcontext](#opattr-cpu-pushcontext-popcontext)
    - [常见编译错误](#常见编译错误)
    - [调试?](#调试)
- [代码演示](#代码演示)
    - [-EP 的错误输出? 执行结果正确](#-ep-的错误输出-执行结果正确)
    - [前序遍历, 以及 masm 令人着急的处理能力](#前序遍历-以及-masm-令人着急的处理能力)
    - [返回函数](#返回函数)
    - [展开指定的次数](#展开指定的次数)
- [610guide 和 masm 的 bug](#610guide-和-masm-的-bug)
    - [闪现](#闪现)
    - [name TEXTEQU macroId?](#name-textequ-macroId)
    - [masm 忽略句子中自己看不懂的部分](#masm-忽略句子中自己看不懂的部分)
    - [masm 忽略错误](#masm-忽略错误)
    - [fatal error DX1020](#fatal-error-dx1020)
    - [vararg](#vararg)
- [早期代码](#早期代码)
    - [发现有 % 和无 % 的不同; 以及其它](#发现有--和无--的不同-以及其它)
    - [宏函数的各种失败展开](#宏函数的各种失败展开)
- [致谢](#致谢)


## 概述

宏是一门编程语言, **宏程序**用来把一些字符串替换成另外的字符串; 替换宏就是执行宏程序. masm 和 c 都有宏, 都没有独立的宏编译/解释/执行器;
它们的编译器带有解释宏的模块, 编译源文件前会先用该模块执行宏程序以修改源文件, 称为**预处理**; 所以大家可能意识不到自己编写并执行了宏程序.

尽管 masm 的宏只能用 masm 执行, 宏的目的也确实是帮助生成 masm 以及汇编语句, 但请记住**宏只认识宏语法, 不认识 masm 及汇编语法**; 学习宏不要求汇编语言的知识.

masm 从上往下读取行, 从左往右处理行里的文本, 行尾的 `\` 视为续行.

### hello world

下面的宏程序在编译时打印 hello world. 将代码保存为 dd.msm, 执行命令 `ml -Zs dd.msm`. -Zs 告诉编译器只检查语法, 不生成 obj

```
echo hello world

end
```

\* *masm 要求源文件必须有 end, 忽略 end 之后的内容*<br>
\* *从这个例子可以确定宏程序由编译器在语法检查阶段执行*<br>
\* *这个例子没有使用宏替换*

`ml -EP dd.msm`<br>
-EP 在屏幕上打印预处理结果, 不生成 obj<br>
`ml -Flout\ -Sa -Zs dd.msm`<br>
-Fl 生成清单文件, -Sa 最详细清单, -Sf 清单加入第 1 遍的结果. 难道还有第 2 遍? m510 的 .err2 可能与之有关

## 宏程序

源文件里的所有语句都是字面量; 解析之后得到 token; 然后得到关键字, 操作符, 名字, 值. 宏程序使用其中的一部分.

\* *引号括起来的字面量的类型不是字符串 (msdn 文档说是); 在预处理里不知道算啥类型; 在汇编里类型是整数列表, 整数是字符的 ascii 值. 比如 "abc" = "a", "b", "c" = 97, 98, 99*

### 常量表达式

masm 说的 constexpr 包括整数字面量和整数表达式字面量, 即整数和加减乘除符号的组合. 常量表达式的值总是整数, 长度由 `option expr16/expr32` 决定.

```
; 常量表达式是整数和整数表达式
; ml -Zs dd.msm

a1 = 3
a2 = 5 * 2 + 1

; error A2008: syntax error : ,
;a3 = 18 - 2, 2 + 7

; error A2050: real or BCD number not allowed
;a4 = 1.4

; error A2009: syntax error in expression
;a5 = 1.44

; echo 不能输出整数; 只能先把整数保存为文本宏, 然后用 % echo 输出
s1 textequ % a1
s2 textequ % a2
% echo s1 s2 ; 3 11

end
```

\* *从这个例子可以看出 echo 无法输出分号之后的内容, 分号之后是 masm 注释*

参考: [%](#percent-sign), [=](#equal-sign), [文本宏和 textequ](#文本宏)

### 变量

预处理阶段的变量是汇编阶段的常量

类型 | 例子 | 解释
---|---|---
integer || 有 2 种形式
|| 123 | 整数字面量
|| <span id=equal-sign></span>tag = constexpr | 整数变量. 按当前 radix 对表达式求值, 得到整数
string || 字符串, 或者叫文本. 有 3 种形式
|| <> | 字符串字面量, 用尖括号包起来
|| args as `% arg` of... | catstr/exitm/macro-function/macro-procedure/textequ
|| args as `f(arg)`, `f(<arg>)` | [宏函数](#宏函数) f 把前述参数视为字符串
code label |tag: | 标签是常量
data label | tag byte/word/... init | 标签是常量
text macro || 字符串变量. [文本宏](#文本宏)
macro procedure || [宏过程](#宏过程)
macro function || [宏函数](#宏函数)

equ 是 masm 5 就有的关键字, 试了试可以当 textequ 和 = 使, 具体啥区别我没有找到答案. 能确定的是, 如果 equ 定义了整数则该整数不能再次赋值

### 常见操作符

char | ascii | 解释
---|---|---
!   | 33 | 在尖括号里视下一字符为字面值, 主要用来转义尖括号; 在其他地方无特殊意义
%   | 37 | <span id=percent-sign></span>行首时[展开](#展开)该行的[文本宏](#文本宏)和[宏函数](#宏函数); [文本项](#text-item)里视后面的字符串为表达式, 求值后转为字符串
&   | 38 | 文档里叫 substitution, 在[模式 2](#模式-2) 中用于标记宏
;   | 59 | 注释
;;  | 59 | 注释, 仅出现在宏定义里, 不随宏展开至源码
<>  | 60 | 包围串字面量
\\  | 92 | 行尾时续行, **反斜杠不是操作符**

操作符的完整列表 <https://docs.microsoft.com/en-us/cpp/assembler/masm/operators-reference?view=vs-2019>

有 4 个地方经常使用尖括号:

- [宏过程](#宏过程), [宏函数](#宏函数)的参数. 假设调用处写的是 before, 宏里面看到的是 after, 有

    . | text
    ---|---
    before | `<abc>   8<*H<(*&>h>c      <((*((_)(^!%, $!%#!@#$%>`
    after  | `abc   8*H<(*&>hc      ((*((_)(^%, $%#@#$`

    可以看到 masm 删掉了嵌套等级 = 1 的尖括号, 简直奇葩. 删掉尖括号导致 [vararg](#vararg) 区分不了传入了几个参数. **为了使用宏参数, 必须牢记这奇葩的处理方式**
- [文本项](#text-item)里用尖括号表示字符串
- [for, forc](#for-forc) 的第二个参数
- 莫名其妙的地方: `option nokeyword: <xxx>`

### 分支

```
if    , ife    , ifb    , ifnb    , ifdef    , ifndef    , ifidn    , ifidni    , ifdif    , ifdifi
elseif, elseife, elseifb, elseifnb, elseifdef, elseifndef, elseifidn, elseifidni, elseifdif, elseifdifi
else
endif
```

这些分支语句的条件有的是整数有的是字符串, 整数可以用**操作符**连接形成常量表达式

**隐式转换** if 视条件里的串为常量表达式

operator | 解释
---|---
+, -, *, /, mod | 中缀操作符接受左右两个操作数; 加减乘除, 取余数
[]  | expr1 \[expr2] = expr1 + expr2
and, or, xor, shl, shr | 位逻辑和按位左右移
not | not expr, 按位取反
eq, ne, ge, gt, le, lt | equal, not equal, greater or equal, greater than, less or equal, less than. 返回 -1 代表 true, 0 代表 false

keyword | 解释
---|---
if  expr | 如果 expr 不等于 0
ife expr | 如果 expr 等于 0
ifb  text-item | 如果 [text-item](#text-item) 空
ifnb text-item | 如果 text-item 不空
ifdef  tag | 如果定义了变量 tag
ifndef tag | 如果没有定义变量 tag
ifidn  text-item-1, text-item-2 | 如果 text-item-1 和 text-item-2 的值相同
ifidni text-item-1, text-item-2 | 如果 text-item-1 和 text-item-2 的值相同, 忽略大小写
ifdif  text-item-1, text-item-2 | 如果 text-item-1 和 text-item-2 的值不同
ifdifi text-item-1, text-item-2 | 如果 text-item-1 和 text-item-2 的值不同, 忽略大小写

```
; 分支和操作符
; ml -Zs dd.msm

int1 = 4
int2 = 0
str1 textequ <abc>
str2 textequ <4 + 1>
str3 textequ % int1 + 1

if int2
    echo int2 != 0
elseife int1
    echo int2 != 0 && int1 == 0
elseif str2 gt int1
    echo `if` casts condition to integer then eval, str2 > int1
endif

ifb str1
    echo str1 is blank
elseifdif str1, str2
    echo content of str1 differs from str2
else
    echo this is else statement
endif

ifidni str2, str3
    echo not likely
elseif str2 eq str3
    echo `ifidni` thinks str2 and str3 are different, but `if` thinks they equal
endif

end

输出
`if` casts condition to integer then eval, str2 > int1
content of str1 differs from str2
`ifidni` thinks str2 and str3 are different, but `if` thinks they equal
```

参考: [textequ](#文本宏)

### 循环和跳转

**没有循环和跳转语句**. for, while 等关键字用于定义**重复块**, 把块里的内容重复多次; 递归调用[宏函数](#宏函数)是把宏函数[展开](#展开)若干次.

### 重复块

把块内的语句就地展开指定次. 只能重复添加行, 不能往一行里重复添加片段

\* *610guide p???/p187 repeat(rept, masm 5.1-)/while/for(irp, masm 5.1-)/forc(irpc, masm 5.1-), exitm, endm*

#### repeat

```
repeat constexpr
    statements
endm
```
```
; repeat 示例 - 阶乘. ml -Zs dd.msm

factorial2cnt = 6
factorial2amt = 1

repeat factorial2cnt
    factorial2amt = factorial2amt * factorial2cnt
    factorial2cnt = factorial2cnt - 1
endm

factorial2str textequ % factorial2amt
% echo factorial2 factorial2str

end
```

`ml -EP dd.msm` 显示如下[展开](#展开)结果

```
factorial2cnt = 6
factorial2amt = 1

    factorial2amt = factorial2amt * factorial2cnt
    factorial2cnt = factorial2cnt - 1
    factorial2amt = factorial2amt * factorial2cnt
    factorial2cnt = factorial2cnt - 1
    factorial2amt = factorial2amt * factorial2cnt
    factorial2cnt = factorial2cnt - 1
    factorial2amt = factorial2amt * factorial2cnt
    factorial2cnt = factorial2cnt - 1
    factorial2amt = factorial2amt * factorial2cnt
    factorial2cnt = factorial2cnt - 1
    factorial2amt = factorial2amt * factorial2cnt
    factorial2cnt = factorial2cnt - 1

factorial2str textequ % factorial2amt
 echo factorial2 720

end
```

#### while

```
while expression
    statements
endm
```

while 展开若干次, 每次展开前都查看 expression, 不为 0 时才展开, 否则退出; 用 exitm 也能退出重复块.

```
; while 示例. ml -EP dd.msm
; 610guide p???/p188 的示例, 这本书的示例一般都依赖汇编指令

cubes   LABEL   BYTE            ;; Name the data generated
root    = 1                     ;; Initialize root
cube    = root * root * root    ;; Calculate first cube
WHILE   cube LE 32767           ;; Repeat until result too large
    WORD    cube                ;; Allocate cube
    root    = root + 1          ;; Calculate next root and cube
    cube    = root * root * root
ENDM

end
```

#### for, forc

```
for i, <text>
    statements
endm

forc i, <text>
    statements
endm

for i: req , <text>     必填参数, i 不能是空串否则报错
for i: =<c>, <text>     默认参数, i 如果是空串则 i = c
```

keyword | 第 2 个参数的尖括号 | 解释
---|---|---
for  | 需要 | 把第 2 个参数看成是以逗号分隔的参数列表, 遍历此列表
forc | 不需要 | 遍历第 2 个参数的每个字符; 没有尖括号时使用第一个空格前的串, 忽略之后的串

```
; for, forc 示例. ml -Zs dd.msm

for i, <abcd, 80 + 3>
    echo i
endm

forc i, 12,4a 786
    echo i
endm

end

输出
abcd
80 + 3
1
2
,
4
a
```

有必要看一下预处理的结果是啥样. `ml -EP dd.msm` 显示:

```
    echo abcd
    echo 80 + 3

    echo 1
    echo 2
    echo ,
    echo 4
    echo a

end
```

可以看到参数 i 直接替换成了实际的值

```
; todo: toupper
; ml -D s="a E" -EP dd.msm

ifnb s
    temp textequ <>

    % forc i, <s>
        if "&i" ge "a" and "&i" le "z"
            echo i
            temp textequ temp, ??? (i - "a" ?)
        endif
    endm

% echo s
endif

end
```

#### 非行首的重复块

```
; ml -EP dd.msm

; error A2008: syntax error : repeat
; 省略另外两个 A2008. 把 textequ % 换成 =, 错误一样
repeat_line_part textequ % 1 * \
    2 * \
    repeat 3
    3 * \
    endm
    1
% echo repeat_line_part

; 这个既然报 invalid symbol type 说明并没有当成字符串, 可能是想当行内宏处理发现不行, 就模糊的透露了名词 symbol type
repeat_line_part_macro macro
    repeat 3
        3 * \
    endm
endm
; error A2148: invalid symbol type in expression : repeat_line_part_macro
repeat_line_part2 textequ % 1 * \
    repeat_line_part_macro
    1
```

### 用于处理字符串的指示和预定义函数

\* *610guide p???/p190 String Directives and Predefined Functions*

- 指示的 return 有点不准确, 因为这 4 个指示取代了 textequ, =; catstr 和 textequ 是同义词
- 指示是关键字, 不区分大小写; [宏函数](#宏函数)是名字, 区分大小写时 (`option casemap`, `-C[p|u|x]`) 必须匹配大小写
- instr 的第一个参数是可选参数, 若要不提供此参数, 指示是不写, 宏函数是空逗号
- string 下标从 1 开始
- 宏函数版本不展开参数

directive | macro function | return | usage | echo
---|---|---|---|---
catstr ||       string | `string catstr <ab>, % 34`             | ab34
|| @catstr  |   string | `% echo @catstr(<ab>, % 34, <???>)`    | ab34???
instr ||        number | `number instr 3, <abcdabc>, <abc>`     | 5
|| @instr   |   string | `% echo @instr(, <abcdabc>, <abc>)`    | 01
sizestr ||      number | `number sizestr <abcdefg>`             | 7
|| @sizestr |   string | `% echo @sizestr(<abcdefg>)`           | 07
substr ||       string | `string substr <abcdefg>, 3, 2`        | cd
|| @substr  |   string | `% echo @substr(<abcdefg>, 3)`         | cdefg

```
; 610guide p???/p192, catstr, substr
;
; SaveRegs - Macro to generate a push instruction for each
; register in argument list. Saves each register name in the
; regpushed text macro.
regpushed TEXTEQU <>                    ;; Initialize empty string

SaveRegs MACRO regs:VARARG
    LOCAL reg
    FOR reg, <regs>                     ;; Push each register
        push reg                        ;; and add it to the list
        regpushed CATSTR <reg>, <,>, regpushed
    ENDM                                ;; Strip off last comma
    regpushed CATSTR <!<>, regpushed    ;; Mark start of list with <
    regpushed SUBSTR regpushed, 1, @SizeStr( regpushed )
    regpushed CATSTR regpushed, <!>>    ;; Mark end with >
ENDM

; RestoreRegs - Macro to generate a pop instruction for registers
; saved by the SaveRegs macro. Restores one group of registers.
RestoreRegs MACRO
    LOCAL reg
    %FOR reg, regpushed                 ;; Pop each register
        pop reg
    ENDM
ENDM

end
```

参考: [宏过程](#宏过程)

```
; 实现 @sizestr. ml -Zs dd.msm
;
; 预定义的宏函数 @sizestr 计算参数的 ascii 字符个数, 不展开参数. 如何不展开参数? 若干想法
; - 把宏放在单独的环境里执行, 此时由于没有定义宏所以也不发生展开. 依靠现在这些语法显然实现不了
; - 模式 1 有过滤, 过滤区域的参数不展开. 计算字符个数要用循环, 正好模式 1 的 forc 不展开参数

$sizestr macro a
    local cnt
    cnt = 0
    forc i, <a>
        cnt = cnt + 1
    endm
    exitm % cnt
endm

abc textequ <this is a long string and will surely fail both sizestr macro functions>

% echo $sizestr(a<!bc><de>)     ; 5
% echo @sizestr(a<!bc><de>)     ; 05
% echo $sizestr(abc)            ; 3
% echo @sizestr(abc)            ; 03
% echo $sizestr(abc de)         ; 6
% echo @sizestr(abc de)         ; 06

; 如果要计算展开后的参数有几个 ascii 字符呢? 需要在宏内展开参数

$$strlen macro a
    local cnt
    cnt = 0
    % forc i, <a>
        cnt = cnt + 1
    endm
    exitm % cnt
endm

% echo $$strlen(abc) ; 71
end
```

参考: [模式 1](#模式-1), [宏函数](#宏函数)

```
; todo: 实现 @catstr
; 难点在于 @catstr 返回一个字符串值而不是字符串变量

end
```

### 输入输出

输入
- 写在源文件里的字面量
- **包含**的文件
- 通过命令行 -D 定义的文本宏
- **无法**在运行时实时获取用户输入

输出
- 展开后的文本; 仅在内存中, 不修改源文件. 对宏来说可以展开为随意的文本, 但对 masm 来说文本必须符合 masm 语法
- echo 在编译时往命令行输出文本

#### 包含

`include filename`

用文件 filename 的内容替换上面那句话. 如果 filename 包含 `\;<>'"`, 需要用尖括号包起来.

### 展开

替换宏可能得到其他宏, 继续替换得到的宏直至没有宏, 这个反复替换的过程叫展开; 不严格区分时这俩词通用.
展开宏就是构造一棵树, masm 称这个树的高度为 nesting level (nl), nl 超过规定值会停止处理该行并报错 A2123.

宏程序执行的结果是宏消失, 源代码改变. 公元 2000 年之后的源码级调试里可能看到的是展开前的代码, 宏函数看起来就像一般函数;
记住这只是有益的假象, 用来保持源代码的行号. 宏在编译前展开, 消失.

前面已经学习了展开重复块, 下面要说展开 3 种具名宏: 文本宏, 宏过程, 宏函数.

### 文本宏

文本宏即字符串变量, 在使用之前需要先定义. 关键字 `textequ` 定义文本宏, 语法如下:

`tag textequ text-item`

成分 | 解释
---|---
tag | 宏名
textequ | 和关键字 catstr 是同义词
text-item | 文本项, 在下面解释

<span id=text-item>文本项</span> | 简称 | 解释
---|---|---
\<text> | 尖括号 | text 是字符串字面量, 不能包含 \n; 转义字符: ! 转义下一个字符, \ 续行
% constexpr | 百分号 | 按当前 radix 对常量表达式求值, 转为字符串
macrofunction() | 圆括号 | 调用[宏函数](#宏函数) macrofunction 并使用其返回值
textmacro | 没符号 | tag 是文本宏 textmacro 的值的**别名**

展开文本宏就是把文本宏的名字替换为文本宏的值

```
; textequ. ml -EP dd.msm

;                         pp = preprocess
str1  textequ <abc>     ; pp: str1 textequ <abc>, str1 赋值
str2  textequ str1      ; str2 的值是 str1 的值
;                         如果 str1 未定义, error A2006: undefined symbol : str1
;                         如果 str1 不是文本宏, error A2051: text item required
;                         如果 str1 是宏函数但用的是 str1 而不是 str1(), error A2051: text item required
str1  textequ <new>     ; str1 的值变了, str2 的值没变
%str3 textequ  str2     ; pp: str3 textequ abc, 行首 % 导致展开本行的宏名
;                         想创建 abc 的别名但 abc 未定义, error A2006: undefined symbol : abc
str4  textequ <str2>    ; pp: str4 textequ <str2>, str4 的值是字符串 str2
%str5 textequ <str2>    ; pp: str5 textequ <abc>, 行首 % 导致展开本行的宏名
num = 4                 ; 变量 num 的类型是整数, 值是 4
val textequ % 3 + num   ; 变量 val 的类型是字符串, textequ 右边的 % 把其后的字符串作为表达式求值并转为字符串, val = 7
```

```
; 展开时只查找已知的宏. ml -EP dd.msm

earlier textequ <later>                             ; earlier textequ <later>
%echo earlier                                       ; echo later
later textequ <i am "later">                        ; later textequ <i am "later">
%echo earlier                                       ; echo i am "later"
use_later1 textequ <"later" = insert later here>    ; use_later1 textequ <"later" = insert later here>
%echo use_later1                                    ; echo "later" = insert i am "later" here
%use_later2 textequ <"later" = insert later here>   ; use_later2 textequ <"later" = insert i am "later" here>
%echo use_later2                                    ; echo "later" = insert i am "later" here
```

### 宏过程

宏过程把 `名字 arg1, arg2, ...` 这样的行替换为好几行文本, 使用前需要先定义

```
tag macro arg1, arg2, ...
    local tag1
    statements
endm

tag macro arg: req      arg 不能是空串否则报错
tag macro arg: =<x>     arg 如果是空串则 arg = x
tag macro arg: vararg   arg 保存从 arg 开始往后的所有参数, 以逗号隔开; 只能是参数列表里最后一个参数
```

**local** 如果出现, 必须是宏的第一句话; 让编译器生成不重复的全局名字, 生成语句时按[模式 2](#模式-2) 确定变量名然后替换为生成的全局名字, 这些名字做返回值时外面可以正常使用.
比如 local t; 编译器令 t = ??0000, 生成语句时把 t, &t, t&, &t&, 替换为 ??0000. local 可以修饰这些变量: numeric equation, text macro, code label.

定义宏过程之后, 如果 masm 看到了语句 `tag arg1, arg2`, 就会把这一整行替换为 `statements`. 宏过程的名字若不是一行的第一个名字则视为普通字符串

```
; 宏过程示例 - 未实现的阶乘

factorial1 macro n: =<3>
    local x
    x textequ % n * (n - 1) ;; 这里需要 n 个项, 或者计算 n 次
    %echo factorial1 x
endm

factorial1
end
```

`ml -EP dd.msm` 显示预处理结果

```
    ??0000 textequ % 3 * (3 - 1) 
echo factorial1 6
end
```

可以看到宏过程 factorial1 在使用处展开, 一行 `factorial1` 替换成了两行 `??0000 textequ % 3 * (3 - 1)` 和 `echo factorial1 6`

```
; 宏过程示例 - 阶乘. 使用了重复块

factorial2 macro n: =<6>
    local amt, cnt, str
    amt = 1
    cnt = n
    repeat cnt
        amt = amt * cnt
        cnt = cnt - 1
    endm
    str textequ % amt
    % echo factorial2 str
endm

; use it here
factorial2

end

fatal error A1004: out of memory
factorial2 "abc"

610guide p???/p193 Returning Values with EXITM
在这里看到了 factorial, 顿时觉得以后不该再写 factorial, 应该写 fibonacci 或更不常见的
```

`ml -EP dd.msm` 输出如下

```
; use it here
    ??0000 = 1
    ??0001 = 6
        ??0000 = ??0000 * ??0001
        ??0001 = ??0001 - 1
        ??0000 = ??0000 * ??0001
        ??0001 = ??0001 - 1
        ??0000 = ??0000 * ??0001
        ??0001 = ??0001 - 1
        ??0000 = ??0000 * ??0001
        ??0001 = ??0001 - 1
        ??0000 = ??0000 * ??0001
        ??0001 = ??0001 - 1
        ??0000 = ??0000 * ??0001
        ??0001 = ??0001 - 1
    ??0002 textequ % ??0000
 echo factorial2 720

end
```

可以看到,
- 宏过程 factorial2 在使用处 (注释 `use it here` 的下一行) 展开, 一行 `factorial2` 展开成好几行
- end 之后的内容在预处理之后就没有了

### 宏函数

masm 看到 `名字 (arg1, arg2, ...)` 这样不含 \n 的串后, 在这个串的前一行展开函数体, 然后把串替换为 exitm 指出的, 不含 \n 的串.
使用前需要先定义, 使用宏函数时若不跟圆括号则视为普通字符串.

```
tag macro arg1, arg2, ...
    local tag1
    statements
    exitm text-item
endm
```

masm 看到 `% var textequ <mf1() mf2()>` 后先在这行前面展开 mf1, 用返回值替换 mf1(), 然后展开 mf2, 用返回值替换 mf2()

\* *610guide p???/p193 Returning Values with Macro Functions*

- 如果宏过程有用于退出的 exitm text-item 语句, 可以是在 if 0 里面 (bug), 宏过程变成宏函数<br>
    bug: 由 if 0 里的 exitm text-item 创建的宏函数, 用来给文本宏赋值时会失败, 但不报错
- exitm, %exitm text-item, 不会把宏过程变成宏函数
- exitm 后跟文本项; exitm <> 返回空字符串
- 调用时不带圆括号是语法错误
- 对于宏过程 f, f(3) 是一个参数 (3); f(1, dd) 是俩参数 (1 和 dd); 逗号分隔参数, 圆括号无特殊意义
- 参数不产生名字, 生成语句时按模式 2 确定参数名然后替换为传入的值, 没用上的参数是空串

```
; defined(x) - if x is a defined symbol, return -1, else return 0
; 610guide p???/p193. ml -Zs dd.msm

DEFINED MACRO symbol:REQ
    IFDEF symbol
        EXITM <-1>  ;; True
    ELSE
        EXITM <0>   ;; False
    ENDIF
ENDM

abc = 1

if defined (haynes)
    echo haynes is defined
elseif defined (abc)
    echo abc is defined, but haynes is not
endif

end
```

#### bug: 莫名其妙的调用

```
; ml -Zs dd.msm

f macro
    exitm <>
endm

mp macro a: vararg
endm

mp f, (876)

end

warning A4006: to many arguments in macro call
f(1): macro called from mp(1): macro called from dd.msm(9): main line code

满足下面两个条件导致 mp f, (876) 生成 f (876)
- 876 两边有圆括号
- f 是之前定义的宏函数; 宏过程没问题, 因为根本不会展开非行首的宏过程

如何避免这莫名其妙的调用, 下面方法任选
- f 两边加尖括号 <f>
- f 前加 !

基于下面代码做进一步试验

mp macro a
    "in mp &a"
endm
f macro a, b
    "in f  &a &b"
    exitm <4>
endm
mp f,,,,d,, (15, 876)ddd

发现 masm 看到宏过程 mp 的参数有宏函数 - 这里是 f - 时, 从 f 开始找后圆括号, 找到后往前找前圆括号;
如果在 f 后面找出了一对圆括号, 圆括号里的就是 f 的参数, 忽略 f 和前圆括号之间的字符; 调用 f, 结果作
为 mp 的参数. 上面代码 -EP 报的错是
error A2008: syntax error : in f  15 876
error A2008: syntax error : in mp 4ddd
```

我把宏参数和命令行参数放一块比了比. 命令行是程序自己处理原始命令行, masm 是 masm 处理完给你, 你没有机会拿到原始字符串,而这个处理过程有 bug:

- 移除了第 1 层尖括号<br>
- 莫名其妙的调用

```
        delimiter   delimiter in arg    quote in arg    vararg                  substitution
cmd     space       " "                 "\""            raw string              no
masm    ,           <,>                 <!<>            cooked string (buggy)   yes
```

### 两种查找文本宏和宏函数的模式

masm 视一行是否以 % 打头, 采取两种确定文本宏和宏函数的办法

- 查找模式仅适用于文本宏和宏函数; 宏过程只有一种查找模式, % 影响的是它的参数; 宏过程的名字也不靠 & 确定
- **死区** 模式 1 和 2 都不从这些地方查找宏名: 宏函数参数的尖括号, 没符号

#### 模式 1

- 如果一句话不以 % 打头, 以此模式确定该句的文本宏和宏函数
- 边展开, 边检查语法. nl 不能大于 20 所以可能是递归调用
- **过滤** 不从下列地方查找宏名<br>
    引号, 尖括号; 块宏, echo, name, title, ... 的参数; for, forc 的参数; 文本项的尖括号, 没符号
- **撮合** 若展开出的串最后一个 token 是宏函数名, 往后查找圆括号以展开该函数 (**bug1**); 否则
- **不拼接原则** 不和后面的串拼接. **撮合是拼接的一种**

#### 模式 2

- 如果一句话以 % 打头, 以此模式确定该句的文本宏和宏函数
- nl 不能大于未知 (520+?) 所以可能是循环
- 如果宏名挨着 &, 展开时删掉 &; 引号外除非为了隔开两个名字 tok1&tok2 否则不需要 &
- 两个反斜杠变一个反斜杠; 一个反斜杠删掉
- 也展开这些宏: 引号里带 & 的; 尖括号里的; echo, name, title, for, forc, ... 的参数; 文本项
- **惰性环境** 引号里的 token 必须挨着至少 1 个 & 才算宏名, 至多 2 个 = 两边各一个即 &tok& 或 &f()&
- 删掉行首的 1 个 %, 展开, 不检查语法. 完毕查看行首, 如果行首以 % 打头, 再来一遍; 否则以模式 1 再来一遍

**bug1**: 此链最后一个调用必须返回文本宏否则报 A2039, 给人感觉调用结果没有结束符; 撮合无论成功与否 -EP 都能看到一堆乱码.
    模式 2 撮合, 拼接都正常, -EP 也没有乱码. 我感觉模式 2 只管展开, 让下一遍去发现拼接结果, 但不知道是否立即撮合.
    为什么怀疑模式 2 的立即撮合呢? 因为如果立即做, -EP 又不出乱码, 说明模式 1 和 2 各自有执行函数的代码, 显然不简练

**note1**: 肯定还有很多没有列出来的情况, 只能遇到了再添加

#### 示例: 宏名

```
hello my name is bob! 9s 2 mee til
    这是模式 1
    模式 1 会产生这些 token: hello, my, name, is, bob, !, 9s, 2, mee, til
    token 中的名字: hello, my, name, is, bob, mee, til

echo hello my name is bob!
    这是模式 1
    首先看到了 echo, 模式 1 下看到 echo, name, title 之类的关键字后就不再往后找宏

tok1&tok2 &number& "tok1&tok2 tok1&&tok2 tok1&tok2& &tok1&tok2"
    这是模式 1, 会产生这些 token:
    tok1, &, tok2, &, number, &, "*ignored*"
    token 中的名字: tok1, tok2, number

% tok1&tok2 &number& "tok1&tok2 tok1&&tok2 tok1&tok2& &tok1&tok2"
    这是模式 2, 会产生这些 token:
    tok1&, tok2, &number&, ", tok1&, tok2, tok1&, &tok2, tok1&, tok2&, &tok1&, tok2, "
    如果 token 间没有空格则展开后也没有空格
    token 中的名字: tok1&, tok2, &number&, tok1&, tok2, tok1&, &tok2, tok1&, tok2&, &tok1&, tok2

% tok1&&&&&&tok2 &f ()&
    这是模式 2, 会产生这些 token: tok1&, &, &, &, &, &tok2, &f, (, ), &
    若 f 是宏函数, f 和左圆括号之间不能有 & 否则不是函数调用
```

#### 撮合

                 \
                node1
       /     /    |    \     \
    done  node2  ( )   raw   raw
           /
        node3
         /
        mf

展开得到宏函数 mf 但没有圆括号时, 开始撮合. 顺着 mf 往上找此路径的右兄弟, 这时右边的节点都还未展开, 这个右兄弟节点必须是 () 否则撮合失败,
error A2008: syntax error : mf. 撮合与在宏过程的参数里调用宏函数不一样, 由于 masm 伟大的逻辑, 作为宏过程参数的宏函数调用,
函数名和圆括号之间可以有任意字符; 而撮合要求看到的第一个非空白字符是左圆括号.

展开方式是从左到右, 所以撮合往往是下边的宏函数找上边的圆括号, 宏函数最高和圆括号在同一层.

你要问我撮合比直接展开出带括号的函数有啥高明之处? 我也不知道.

#### 一些性质

```
; 模式 1 下何时展开文本项里的宏. ml -Zs dd.msm

f macro
    echo f called
    exitm <+>
endm

g macro
    exitm % 1 f() 2
endm

d textequ <*>

a1 textequ <f()>        ; 没反应
a2 textequ f()          ; f called
a3 textequ % 3 f() 4    ; f called
a4 textequ % 5 d 5

% echo a2, a3, a4       ; +, 7, 25
% "&g()"                ; f called ; error A2008: syntax error : 3
end

尖括号, 不调用宏函数
圆括号, 调用宏函数
百分号, 调用宏函数, 展开文本宏
没符号, 无法调用宏函数
```

```
; 模式 1 的 nesting level 不能大于 20. ml -EP dd.msm

; error A2123: text macro nesting level too deep, 多 deep 算 too deep? 用下面代码试了试
; 展开出了 21 个 1$. 所以 A2123 的 too deep 指的应该是 > 20
; 这个 > 20 真 tm 熟悉, 我记得 windows api 的 winproc 也检测递归, 数量好像也是 20, 那还是我上 cn.fan 新闻组的时候

self_ref textequ <1$ self_ref>
self_ref
```

```
; 模式 1 在递归时的一些观察. ml -EP dd.msm

; 把 1$ 换成...
; 1 个字符. 输出往往后跟一堆乱码, 换成 # 更是导致 dosbox 循环输出乱码
; #$. error A2044: invalid character in file
; 2 ~ 242 个 d. A2123 nl too deep; 即使看输出不够 21 次也报此错
; 243 ~ 246 个 d. A2042 statement too complex; 但 self_ref textequ <ddd self_ref> 至多 6 个 token, 一堆 d 不会拆成若干 dd
; 247+ 个 d. A2041 string too long; 247 + 空格 + self_ref = 256

self_ref textequ <1$ self_ref>
self_ref
```

```
; 模式 1 在调用处会展开哪些宏参数. ml -EP dd.msm

; 宏参数是文本项, 文本项在模式 1 下展开宏函数 (圆括号), 不展开文本宏 (没符号)
; 宏对待没符号的方式和 textequ 不一样. 宏认为没符号是字符串, 会在两边加尖括号; textequ 认为是文本宏名

te textequ <ddff>

f macro
    exitm <this is f>
endm

mp macro a
    <a>
endm

mf macro a
    exitm <<a>>
endm

mp te       ; <te>
mf(te)      ; <te>

mp f()      ; <this is f>
mf(f())     ; <this is f>

end
```

```
; 模式 1 展开

; tm = text macro, mf = macro function
; te1 -> f1 ()
; tm     mf ()
; 这种可以正常执行
f1 macro
    echo f1 called
    exitm <>
endm
te1 textequ <f1 ()>
te1

; te2 -> tef2 () -> f2 ()
; tm     tm         mf ()
; f2 是第 2 遍得到的, 得到的这个串里面没有圆括号因此需要从后面的串里找
; 撮合. masm 要求撮合的调用最终返回文本宏否则报 error A2039: line too long
f2 macro
    echo f2 called
    exitm <>
endm
te2 textequ <tef2 ()>
tef2 textequ <f2>
te2

; te3 -> te3a te3b -> f3 te3b *A2008* -> f3 ()
; tm     tm   tm      mf tm
; 撮合失败. 得到函数名 f3 后发现后面不是圆括号而是文本宏 te3b, 报 error A2008: syntax error : f3
; 虽然会继续把第 2 个文本宏展开为 () 得到 f3 () 但由于上面的错误, 不会调用 f3
f3 macro
    echo f3 called
    exitm <>
endm
te3 textequ <te3a te3b>
te3a textequ <f3>
te3b textequ <()>
te3

; A2008 究竟是何时触发的? 用下面代码做实验, ml -EP dd.msm 输出如下, 略去文本宏定义
;     echo 2
; dd.msm(9): error A2008: syntax error : a2008f
; a2008f (1)
; 看着顺序像 展开完毕 -> A2008 -> 打印展开结果
;
; ml -Zs dd.msm 输出如下
; 2
; dd.msm(9): error A2008: syntax error : a2008f
; 看着顺序像 展开完毕 -> A2008
;
; 所以 A2008 应该是展开时就发现, 但展开后才报的? 如果展开后再去发现就发现不了了, 因为展开后语法是正确的
a2008f macro a
    echo a
    exitm <>
endm
a2008t textequ <a2008l a2008r a2008f(2)>
a2008l textequ <a2008f>
a2008r textequ <(1)>
a2008t

; 换个形式
f4 macro a
    echo f4 called with a
    exitm <z>
endm
te41 textequ <te4a>
te42 textequ <te4a te4b>
te4a textequ <f4>
te4b textequ <()>
z textequ <>

; te41 (xxx) -> te4a (xxx) -> f4 (xxx)
; tm   (xxx)    tm   (xxx)    mf (xxx)
; 和 te2 一样, masm 要求撮合调用最终返回文本宏否则 A2039
te41 (xxx)

; te42 (xxx) -> te4a te4b (xxx) -> f4 te4b (xxx) *A2008* -> f4 () (xxx)
; tm   (xxx)    tm   tm   (xxx)    mf tm   (xxx)
; 和 te3 一样, 得到 f4 时没在后面找到圆括号, A2008
te42 (xxx)

; 无法拼接宏名, error A2008: syntax error : left, 用 -EP 发现得到了 leftright
te6a macro
    exitm <left>
endm
te6b textequ <right>
leftright textequ <this is me>
te6 textequ <te6a()te6b>
te6

end
```

```
; 宏过程以模式 2 确定并替换参数, 宏函数一样. ml -EP dd.msm

f macro a1, a2          ; after preprocess, f <<<4 + 8>>>, sss turns to
    t1 textequ a1       ; t1 textequ <<4 + 8>>
    t2 textequ t1       ; t2 textequ t1
    %t3 textequ t2      ; t3 textequ <4 + 8>
    echo a1 t1 t2 t3    ; echo <<4 + 8>> t1 t2 t3
    %echo a1 t1 t2 t3   ; echo <<4 + 8>> <4 + 8> <4 + 8> 4 + 8
    <n a2>              ; <n sss>
%   <n a2>              ; <ddd sss>
    "&n &a2"            ; "&n sss"
%   "&n &a2"            ; "ddd sss"
endm

n textequ <ddd>

f <<<4 + 8>>>, sss

end
```

```
; 多个 % 导致多次执行模式 2. ml -Zs dd.msm

fc macro a
    echo a
    exitm <f>
endm

fz macro
    echo z
    exitm <>
endm

%   fz() fc(1)z()
%%  fz() fc(1)z() fc(2)c(2)z()
%%% fz() fc(1)z() fc(2)c(2)z() fc(3)c(3)c(3)z()

end

%   fc(1)z() fz()
%%  fc(1)c(1)z() fc(2)z() fz()
%%% fc(1)c(1)c(1)z() fc(2)c(2)z() fc(3)z() fz()
```

```
todo: 模式 2 的撮合函数是在模式 2 还是模式 1 调用的? 继续研究下面这种

te1 textequ <&f>
te2 textequ <te1>
f macro
    echo f called
    exitm <>
endm

% te1& ()

end
```

```
todo: 感觉模式 2 只看初始内容里的 &, 不管展开出的 &. 证明它

end
```

### opattr, @cpu, pushcontext, popcontext

\* *610guide p???/p196*

opattr 返回 16 位整数, 0 ~ 10 位有意义; .type 返回 opattr 的前 8 位即低字节. 不返回宏程序变量的信息因此没啥用.

```
f macro a
    t textequ % opattr a
    % echo t
endm

f ax

.radix 2
cpu textequ % @cpu
.radix 10

% echo cpu

IF cpu AND 00000010y
    echo 80186 or higher
ELSE
    echo 8088/8086
endif

end
```

610guide p???/p198 在宏里可以用 pushcontext, popcontext 保存, 恢复下列设置

Option | Description
---|---
ASSUMES | Saves segment register information
RADIX | Saves current default radix
LISTING | Saves listing and CREF information
CPU | Saves current CPU and processor
ALL | All of the above

### 常见编译错误

- A1007<br>
    fatal error A1007: nesting level too deep<br>
    经实验递归展开宏函数而不报错的次数, % 打头是 19, 否则是 18
- A2039<br>
    error A2039: line too long<br>
    经实验一行有 513+ 字符时报 A2039<br>
    [Q155047: PRB: A2041 Initializing a Large STRUCT](https://jeffpar.github.io/kbarchive/kb/155/Q155047/)
- A2041<br>
    error A2041: string or text literal too long<br>
    经实验 echo 后放 256 字节也报 A2041, 不仅是下面说的宏参数<br>
    [Q137174: DOCERR: A2041 Error When Macro Parameter Length > 255 bytes](https://jeffpar.github.io/kbarchive/kb/137/Q137174/)
- A2042<br>
    error A2042: statement too complex<br>
    经实验 token 很少的时候也会报 A2042<br>
    masm 6.x 一行中的 token 有 99+ 时报 A2042<br>
    [Q85228: BUG: Causes of A2042 During Data Initialization](https://jeffpar.github.io/kbarchive/kb/085/Q85228/)
- A2123<br>
    error A2123: text macro nesting level too deep<br>
    经实验没有 % 打头时在展开了 21 次后报 A2123<br>
    % 打头时展开了 500+ 次仍没停止, 报错行长度超过 512 才停, 仍没报 A2123; 其它实验表明 % 打头确实能触发 A2123

\* *A2042 在 masm 5.1 中是另外的错误 Q40852: FIX: A2042 May Be Caused By Using LOW and OFFSET In MASM 5.1*

```
; 示例: A1007 (nl 19+/%20+). ml -Zs dd.msm

cnt = 19

f macro
    if cnt gt 0
        cnt = cnt - 1
        f()
    endif
    exitm <>
endm

f()

end
```

```
; 示例: A2041 (256+ bytes), A2042 (99+ tokens). ml -Zs dd.msm

echo \
12345678901234567890123456789012345678901234567890\
12345678901234567890123456789012345678901234567890\
12345678901234567890123456789012345678901234567890\
12345678901234567890123456789012345678901234567890\
12345678901234567890123456789012345678901234567890\
123456

1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 \
1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 \
1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 \
1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 \
1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9

end
```

### 调试?

masm 不支持调试宏程序, 没有断点和单步执行. echo, -EP, 错误信息是常用的调试手段.

## 代码演示

### -EP 的错误输出? 执行结果正确

ml -EP dd.msm

```
; 发现: 第 4 行是啥 bug 玩意儿?

mPer textequ <%>
mDol textequ <$>
mTxt textequ <abcdefg>
m001 textequ <mTxt long-string>
m002 textequ <mPer mTxt long-string>
mDol <mTxt>                             ; $ <mTxt>
mPer <mTxt>                             ; % <abcdefg>
m001                                    ; abcdefg long-string
m002                                    ; % mTxt long-string abcdefg long-string

; 再次遇到
···
tl textequ <!<>
tr textequ <!>>
ta textequ <a>
tb textequ <b>
ab textequ <the_name_is_ab>
%% tl&&ta&&tb&&tr                       ; % <ab> <the_name_is_ab>

于是开始专门的试验. 初步的想法是既然执行结果正确那错误输出可以忍受
继续试验, 猛然发觉这不是 bug 输出, 这是正确的输出 + 不好看的格式; 句子前面有几个 %, -EP 就会追加几段, 这几段之间没有分
隔符, 每一段都代表一个 % 的处理结果, 比如

mPer textequ <%>
mTxt textequ <echo>
te00 textequ <textmacro>
m002 textequ <mPer mTxt te00>

% % % % m002

ml -EP dd.msm 输出如下, 两边的引号是我加的
" % % % % echo textmacro % % % echo textmacro  % % echo textmacro   % echo textmacro    echo textmacro    "

上面的输出是好几段, 我根据 (合理的?) 猜测给它加上换行
"% % % % m002"                  <- 这是要处理的行
" % % % m002"                   <- 拿走行首 %
" % % % mPer mTxt te00"         <- 展开宏 m002
" % % % % echo textmacro"       <- 展开其余宏
" % % % % echo textmacro"       <- output: 所有宏展开完毕, 这是第 1 遍展开的结果; 查看结果发现行首是 %, 再来一遍
"  % % % echo textmacro"        <- 拿走行首 %, 扫描本行发现没有宏, 结束; 查看结果发现行首是 %, 再来一遍
" % % % echo textmacro"         <- output: 第 2 遍展开的结果, 不知为啥删掉了一个行首空格
"  % % echo textmacro"          <- output: 第 3 遍展开的结果
"   % echo textmacro"           <- output: 第 4 遍展开的结果
"    echo textmacro"            <- output: 第 5 遍展开的结果, 行首已经没有 %, 用模式 1 再来一遍
"    "                          <- output: 我不知道这个空行啥意思
```

### 前序遍历, 以及 masm 令人着急的处理能力

ml -Zs dd.msm

```
; 如果 depth < height, 返回 3 个对自身的调用; 否则视 depth 和 height 的差值逐渐减少调用次数至 0
;
; f 不是递归函数, 它里面没有函数调用. f 返回调用自身的字符串, 由展开宏的 masm 去执行
; 观察输出可以确定 masm 以前序遍历的方式展开宏; 为了构造树, 前序遍历也是唯一可行的方式
;
; 输出比较多, dosbox 又没有滚动条所以应该把输出重定向到文件 > fff ml -Zs dd.msm
; 可以看到 f(4) 导致 148 次调用; 这不是 4 层 3 叉树的递归次数, 因为 f 多加了两层调用
;
; https://en.wikipedia.org/wiki/Tree_(data_structure)
; root      depth = height = 0
; level     1 + the number of edges between a node and the root, i.e. (Depth + 1)
;
; masm 说的 nesting level, nl, 究竟是等于树节点的 depth 还是 level, 我不想探究了

f macro height, depth: =<0>, nodetype: =<root>
    local dep1

    dep1 textequ % depth + 1

    % echo nl depth, nodetype

    if dep1 lt height
        exitm <f(height, dep1, branch1) f(height, dep1, branch2) f(height, dep1, branch3)>
    elseif dep1 eq height
        exitm <f(height, dep1, branch4) f(height, dep1, branch5)>
    elseif dep1 - height eq 1
        exitm <f(height, dep1, leaf)>
    else
        exitm <>
    endif
endm

f(2)

end

bug
- 如果把 f 的名字换成很长的串, 能看到 error A2041: string or text literal too long; 意料之中, 不是 bug
- 想象中如果 height 大于 18 能看到 error A1007: nesting level too deep, 实际上 masm 在 height = 5 时就出错了
    用 f(19) 还能看到 error A2123: text macro nesting level too deep; nl 确实超了, 但 text macro 是哪来的?
    是不是说, A1007 是递归调用宏函数才会出的错? A2123 是展开文本宏和宏函数都会出的错?
- 多试几个数你能看到好几种编译错误 - 全是 masm 自己造成的

思考
上面用的是宏函数. 能不能控制文本宏的递归次数, 或者组合多个其它文本宏? 如果接受参数可能能, 但它不接受参数所以可能不能
todo: 证明它能或不能. 可能作为论据的事实
- no  每次都是常量替换
- no  既然不接受参数, 则每次替换/调用/展开都得到相同结果
- yes 隐含的参数? 有没有? 如何实现?
```

### 返回函数

ml -Zs dd.msm

```
f macro a
    ifb <a>
        exitm <f>
    else
        exitm <a>
    endif
endm

f1 macro
    exitm <textmacro>
endm

f2 macro
    exitm <f1>
endm

fa2039 macro
    exitm <echo fa2039 called>
endm

textmacro textequ <echo finally>

f()()()()()()()()(f1)()
f()()()()()()()()()()()()()()()()()()(f2)()()
fa2039()

f(fa2039)()
f()1()

cat macro a
    exitm <f&a>
endm

cat(1)()
cat(2)()()

end

; f(fa2039)() is not ended with text macro so error A2039: line too long    - 模式 1 撮合 bug1
; f()1() triggers error A2008: syntax error : f, then expands to f1()       - 模式 1 不拼接原则
```

### 展开指定的次数

```
; %exitm. ml -EP dd.msm
;
; 在尝试按指定次数展开时我写出了如下代码, 发现不对头:
; - 宏的第一句展开成了 echo arg = (tok
; - 错误的行号是 if count 那句, error A2208: missing left parenthesis in expression
; tok 前面怎么多了个左圆括号? masm 为啥报错说 if count 那句缺少左圆括号? 你能解释原因吗?

expand macro token, count
    echo arg = token

    if count
        % exitm expand(@catstr("&&token"), % count - 1)
    else
        % exitm <"&token">
    endif
endm

expand (<tok>, 1)
end
```

```
; error 100+. ml -Zs dd.msm
;
; fatal error A1012: error count exceeds 100; stopping assembly

expand macro token
    echo arg = token
    s textequ <"&">, <token>, <">
    exitm s
endm

% "&expand (<tok>)"
end

; masm 正确认出了定义 s 时 <"&"> 多了个后面的引号, 但反复报这个错导致错误数量超过 100
```

展开模式 1 下的名字 n 次. 没啥实际意义, 因为展开后的 token 可能包含多个 token, 而它只能展开第 1 个 (假如第 1 个确实是 token 的话);
但是很好的练习材料, 用来检验前面学到的知识.

- 难点 1, 展开 1 次<br>
    要避免展开到死, 只能用引号创造的惰性环境在模式 2 里展开
- 难点 2, 循环<br>
    采用 % tag textequ <> 的形式时要知道 % 会把 textequ 的两边都展开, 这意味着左边的符号只能用 1 次, 赋值之后再用就变成了
    `值 textequ 值`, 导致语法错误, 因此需要多个变量. 该怎么写不定数量变量的 local 语句? 用宏函数生成? 即使能用宏函数生成
    (我怀疑不能, 因为 local 必须是宏里第一句话) 我也不想用, 因为它不是这里的重点, 所以采用递归调用
- 难点 3, 返回<br>
    基于下面两点, 不返回值而是打印值; 为了防止在 echo 里展开, 打印结果带了引号, 显然算不了正确的输出<br>
    1\. 不知道如何返回变量的值. 即使返回了值, 使用的地方还得留意不让值里的宏展开<br>
    2\. 返回变量名的话使用前需要展开一次, 更麻烦, 类似 `%% "&&f(tok)"`
- 难点 4, 变量<br>
    没办法取变量的值, 计算出来的值总是由某个变量指代: 字面量不是变量, 但其值只能在程序运行前指定; 百分号计算整数表达式;
    尖括号把变量名变成字符串, 反倒又加一层间接; 没符号没贡献; 圆括号是调用宏函数, 可这被调用的宏函数面临同样的问题

ml -Zs dd.msm

```
expand_1st_token_n_times macro token, n: =<1>
    local len, s1, s2

    % s1 textequ <"&&token">
    len sizestr s1
    s1 substr s1, 2, len - 2

    if n gt 1
        %% s2 textequ <"&&&s1">
        len sizestr s2
        s2 substr s2, 2, len - 2
        exitm expand_1st_token_n_times(s2, n - 1)
    else
        % echo "&&s1"
        exitm <>
    endif
endm

te1 textequ <te2 ()>
te2 textequ <mf1>
mf1 macro
    exitm <return value of mf1>
endm

expand_1st_token_n_times(te1, 1) ; "te2 ()"
expand_1st_token_n_times(te1, 2) ; "mf1 ()"
expand_1st_token_n_times(te1, 3) ; "return value of mf1"
expand_1st_token_n_times(te1, 4) ; "&return value of mf1"

end
```

## 610guide 和 masm 的 bug

### 闪现

这些现象我观察到过, 目前无法重现, 我会留意它们

- 宏函数的参数不要求尖括号; 没有尖括号时, 如果在找到某个参数后的逗号前先找到了空格, 则忽略后续逗号, 整个后续参数列表删除首尾空格, 作为一个参数
- 看到过宏参数也替换成和 local 变量一样的 ??00nn 名字
- 没给参数加尖括号时看到宏给参数前面加了 ! 符号

### name TEXTEQU macroId?

```
; 610guide p???/p177, name TEXTEQU macroId | textmacro

; name TEXTEQU macroId? 错误. textequ 右边只能放宏函数的调用结果即 macroId(), 不能放宏函数名
; 宏函数的调用结果是 text item, 宏函数不是
; ml -Zs dd.msm

msg macro
    exitm <>
endm

; error A2051: text item required
string TEXTEQU msg
end
```

### masm 忽略句子中自己看不懂的部分

```
; ml -EP dd.msm

f1 textequ <ddd>
f2 textequ <cc>
fx textequ f1<xx>f2

fx ; fx 包含字符串 ddd, 没有编译警告或错误
end
```

### masm 忽略错误

```
; ml -Zs dd.msm

; if 0 里的 exitm text-item 也能把宏过程变成宏函数
f macro
if 0
    exitm <abc>
endif
endm

; 假设此前未定义 tab. 下面这句话由于出错所以也不会定义 tab, 但 masm 没有报错
tab textequ f()

; 输出 not defined
ifdef tab
    echo defined
else
    echo not defined
endif

end

曾经在宏函数里用了 elif, 执行当然不正确, 找了好半天才发现应该用 elseif. masm 没有对 elif 报错
```

### fatal error DX1020

```
; exitm 后跟 db, dd, ret, mov 这些 x86 指令都是这结果
;
; DOSXNT : fatal error DX1020: unhandled exception: Page fault;
; contact Microsoft Support Services
; ProcessId=3694 ThreadId=3695
; User Registers:
; EAX=00000000h EBX=00449D00h ECX=00000000h EDX=0005F000h
; ESI=0004EDDBh EDI=0000101Ch EBP=0044A8D8h ErrorCode = 00000004h
; DS=0017h ES=0017h FS=005Fh GS=0017h FLG=00003246h
; CS:EIP=000Fh:00433C75h SS:ESP=0017h:0004EDD4h

f macro
    exitm dd
endm

f()

end

不确定这是否是 dosbox 的毛病, 但只要是 x86 指令就这样, 否则不这样, 很可能是 masm 的毛病
我看下面的 cause 里少了一句: or a normal masm instance running it's daily job

https://jeffpar.github.io/kbarchive/kb/111/Q111263/

CAUSE
=====
Unhandled exception errors can be caused by a system configuration problem such
as an ill-behaved device driver, a terminate-and-stay-resident (TSR) program, or
a memory manager that is not configured correctly for the hardware in a
particular machine.
```

### vararg

```
; vararg 没法用来计算参数个数
;
; p???/p194 Using Macro Functions with Variable-Length Parameter Lists
; 这里计算参数个数的 @ArgCount 宏不对
; - @ArgCount(1, <2, 3>, 4) 是 3 个参数, 它返回 4
; - @ArgCount(<1, 2, 3, 4>) 是 1 个参数, 它返回 4
;
; 问题在于 vararg 参数里保存的是处理后的参数列表, 换句话说用的时候就是错的. 具名参数处理一下没啥问题, 还是能分给正确的
; 具名参数, 变参就没法区分了

@ArgCount MACRO arglist:VARARG
    LOCAL count
    count = 0
    FOR arg, <arglist>
        count = count + 1 ;; Count the arguments
    ENDM
    EXITM %count
ENDM

; vararg 没法用来查找第 i 个参数
;
; p???/p194, @ArgI
; @ArgI 和 @ArgCount 一样的毛病; 这是 vararg 的毛病, 不知道咋解决
; %echo @ArgI(2, dd, <<2, 3, 4>>, xf) 输出 2, 3, 4, 错误, 应该输出 <2, 3, 4>
; %echo @ArgI(2, dd, <!<>, xf) 应该输出 <, 它报错
;
; 原文前两行注释 - count 和 retstr - 写反了, 已更正

@ArgI MACRO index:REQ, arglist:VARARG
    LOCAL count, retstr
    retstr TEXTEQU <>               ;; Initialize return string
    count = 0                       ;; Initialize count
    FOR arg, <arglist>
        count = count + 1
        IF count EQ index           ;; Item is found
            retstr TEXTEQU <arg>    ;; Set return string
        EXITM                       ;; and exit IF
        ENDIF
    ENDM
    EXITM retstr                    ;; Exit function
ENDM

end
```

## 早期代码

### 发现有 % 和无 % 的不同; 以及其它

```
; ml -EP dd.msm

; 同样的递归展开自己, 错误应该也一样; 但看下面, 使用的地方不同错误就不同
self_ref textequ <this is self_ref>

self_ref            error A2123: text macro nesting level too deep
%echo self_ref      error A2039: line too long
                    error A2041: string or text literal too long

; 说明啥? 展开宏和用 % 展开后续宏, 算两个不同操作? 执行下列代码发现真的是两个不同操作
f textequ <d f>

f       error A2123: text macro nesting level too deep
%f      error A2039: line too long
        error A2042: statement too complex

; 增大 self_ref 文本的长度, 这回报错一样了, 只是顺序不一样
self_ref textequ <this is self_ref it is a recursive definition echo of t>

self_ref    error A2123: text macro nesting level too deep
            error A2039: line too long
%self_ref   error A2039: line too long
            error A2123: text macro nesting level too deep

; 下面这个展开为 echo is self_ref_2 就结束了
self_ref_2 textequ <echo is self_ref_2>
self_ref_2

; 下面的 echo 输出 'this is self_ref_in_lazy', 引号阻止了后续的展开
; todo: 怎么去掉字符串两边的引号
self_ref_in_lazy textequ <this is self_ref_in_lazy>
%echo '&self_ref_in_lazy'

; 给文本宏的值里自己名字的部分前面加 &, 又无限递归了
self_ref_aggressive_in_lazy textequ <this is &self_ref_aggressive_in_lazy>
; error A2039: line too long
; error A2041: string or text literal too long
;%echo '&self_ref_aggressive_in_lazy'
```

### 宏函数的各种失败展开

```
; 有下列定义

f_blank macro
    exitm <>
endm

f_text_macro macro
    exitm <text_macro>
endm

f_f_blank macro
    exitm <f_blank>
endm

f_f_text_macro macro
    exitm <f_text_macro>
endm

f_text_m macro
    exitm <text_m>
endm

f_f_text_m macro
    exitm <f_text_m>
endm

text_macro textequ <echo ok>

; statement             expected after -EP                          reality after -EP
text_macro              echo ok                                     same
f_blank()                                                           same
f_text_macro()          text_macro -> echo ok                       same
f_f_blank()()           f_blank() ->                                error A2039: line too long
f_f_text_macro()()      f_text_macro() -> text_macro -> echo ok     same
f_text_m()acro          text_macro ->  echo ok                      error A2008: syntax error : text_m
f_f_text_m()acro()      f_text_macro() -> text_macro -> echo ok     error A2008: syntax error : f_text_m

end

上面出错的语句毫无道理. 虽然前面加上 % 就能正确执行了, 可是干嘛要多写个 %? 前面已经知道有和没有 % 是有好多差别的, 不是
什么 "magical fix". 无论如何还是总结一下, 经实验要在不加前导 % 的时候调用返回的宏函数需满足下列条件
- 最后一个宏函数必须返回文本宏
- 宏名不能是拼接出来的
```

## 致谢

2019.9.14 下午, 和[俞悦](https://github.com/josephyu19850119)讨论后做出下列修改, 并从 txt 改为 md

- (太费解) 删除令人费解的名词比如把 token 翻译为信物; 用 A.D. 表示公元后; css 术语 inline, block, inline-block
- (太吓人) 删除对续行的描述
- (太抽象) 重新把示例代码混入介绍, 早先是把这俩分开了; 在靠前位置添加 hello world; 考虑本条目的做法之后, 在开头添加速成课
- (太分神) 进一步减少对 610guide (Microsoft MASM 6.1 Programmer's Guide) 的引用


