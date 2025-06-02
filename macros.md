




<br><br><br><br><br><br><br><br><br><br><br><br><br>

# <center> a major rewrite is on its way</center>

<br><br><br><br><br><br><br><br><br><br><br><br><br>






## 宏, 文本替换, 展开, 预处理

masm 宏指文本替换; 由于经常是把名字 (较短) 替换成多条语句 (较长) 所以也叫展开. 这事儿在编译之前做, 编译之前还做些其他事儿, 合起来叫预处理. 名词宏和预处理可以混用.

`ml -EP dd.msm`<br>
-EP 往 stdout 输出预处理结果, 不生成 obj

`ml -Zs dd.msm`<br>
-Zs 预处理, 语法检查, 不生成 obj

`ml -Flout\ -Sa -Zs dd.msm`<br>
-Fl 生成清单文件, -Sa 最详细清单, -Sf 清单加入第 1 遍的结果. 难道还有第 2 遍? m510 的 .err2 可能与之有关

### 转义, 变量, 宏

转义序列用字符集里的字符序列代表字符集外的字符, 为了区分字符转义前和转义后的意思, 规定了一些字符作转义起始标记. 转义前和转义后是两种状态, 可以看出, 只要规定多种转义起始字符就可以拥有多种转义后的状态. 另外, 如果考虑 "转义结束标记" 就会想到引号和括号. 转义和括号是同义词, 引号是括号的一种.

在编程语言里所有字符都是转义字符, 所有词都不代表字面意思, 字符序列的字面值反倒要用引号括住以转义出来. 这种设定下变量名用起来就很方便, 变量名代表一个东西而不代表组成变量名的字符的字面值, 使用变量名的时候虽然每次都转义但从来不明显的把转义标记写出来.

masm 编程语言的宏分为关键字和自定义的名字 (a.k.a. 宏名, 变量名). 宏的作用是生成文本, 但宏和文本在写法上没有任何区别, 一个词究竟是宏关键字, 宏名还是普通文本需要查表才能确定. xxx 的类型取决于前面是否定义了 xxx; 一个词是否替换取决于其所在的位置. 这些问题固然不归 masm 独有, 但实际使用的体验是 masm 集中了所有问题, 基本都没有解决; 没有解决的, 多数又增加了新的问题; 少部分解决的, 解决方式也极其琐碎.



todo: 读懂这个 https://github.com/qwordAtGitHub/mreal-macros

### 数据类型

610guide, p16: In addition to constants, expressions can contain labels, types, registers, and their attributes.

(expression? token group?) | 类型 | 解释
-|-|-
10, 1b, 1y, 7o, 7q, 10d, 10t, 16h | integer literal | default radix is not hexadecimal 时可以用 1b, 10d
"abc", 'abc'                      | integer literal | 整数 ascii, "abc" = 979899
x operator y, operator x          | integer constexpr | x, y 是 token, option expr16/32 决定结果的长度
\<any chars>                    | text item | cv help/index/assembler/e/exitm/textitem
% constexpr                     | text item | text item = 文本项, 不能包含 \n
text-macro, macro-function()    | text item | 文本宏和宏函数有自己的类型, 不是文本项, 它俩的替换结果是文本项

q | a
-|-
text item 和 statement, token 是啥关系? | masm 没有解释
有没有 text 的概念, 有的话是啥? | masm 没有解释, 感觉就是源代码文本, 既可以是字符也可以是 token, token 组, 语句组
text 和 text item 有区别吗? | 估计 text item 指值是 text 的表达式. masm 没有 text expression 的说法
为什么要区分 text item 和 statement, token? | 一个文本宏的名字, 放在在尖括号里是 text, 不替换; 否则就替换

a.k.a.s in masm documents and help
- number = integer
- constant expression = constexpr = expression
- string = text
- string equate = text equate = text macro

名字 | -Fl 输出的类型 | defined by | 解释
-|-|-|-
tag = constexpr         | symbol, number    | equate | 按当前 radix 对常量表达式求值, 得到整数
tag = "abc"             | symbol, number    | equate | 值是 0x616263 under option expr32
tag equ constexpr       | symbol, number    | equ directive     | const, 但 -Fl 没有列出该属性
tag equ non-constexpr   | symbol, text      | equ directive     | 参数无法当作 constexpr 求值时视作文本
tag textequ text-item   | symbol, text      | text equate       | 文本宏, 替换为不含 \n 的文本
tag:                    | symbol, l near    | code label        | 可以用在 ifdef 里
tag size init           | symbol, size      | data label        | 可以用在 ifdef 里
... exitm arg           | macro, func       | macro function    | 宏函数, 替换为不含 \n 的文本
... exitm               | macro, proc       | macro procedure   | 宏过程, 替换为包含 \n 的文本
tag segment             | segment and group

```
; text 替换成值, number 不替换

                                ; ml -EP dd.msm
e1 = 4                          ; (same)
t1 textequ % e1 * 3             ; (same)

e2 = t1 + 3                     ; e2 = 12 + 3
t2 textequ % e2 shl (t1 / 10)   ; t2 textequ % e2 shl (12 / 10)

e3 = t2 mod 17 + e2             ; e3 = 30 mod 17 + e2
t3 textequ % e3                 ; (same)

e1 e2 e3                        ; error A2008. e1 e2 e3
t1 t2 t3                        ; error A2008. 12 30 28

; 当然在 masm 里就没有什么确定的东西, 比如
t4 textequ t1, % t1, t1         ; t4 textequ t1, % 12, t1
end
```

```
; 替换时只查找已知的宏

  te1 textequ <te2>
% echo te1

  te2 textequ <i am "te2">
% echo te1
end

ml -Zs dd.msm

te2
i am "te2"
```

```
; =, textequ, equ. ml -Zs dd.msm

te1 textequ  1      ; error A2051: text item required
te1 textequ <1>     ; type = text, value = 1, value != <1>
te1 textequ %  1
te1 textequ % <1>   ; error A2009: syntax error in expression. te1 = 0

te1 textequ   "3 * 4"   ; error A2051: text item required
te1 textequ % "3 * 4"   ; error A2084: constant value too large

te2 textequ te1     ; type = text, value = 0. 不替换 te1, te2 是 te1 的别名

int1 = te1
int1 =  1
int1 = <1>          ; error A2009: syntax error in expression
int1 =  3 * 4
int1 = "3 * 4"      ; error A2084: constant value too large
int1 = "3 *4"       ; value = 0x33202A34

int1 = 18, 2 + 7    ; error A2008: syntax error : ,
int1 = 1.4          ; error A2050: real or BCD number not allowed
int1 = 1.44         ; error A2009: syntax error in expression

int1 equ 4          ; error A2005: symbol redefinition : int1

equ1 equ % 3 * 4    ; type = text, value = % 3 * 4. equ 右边的 % 无特殊意义
equ1 equ   te1      ; type = text, value = te1. equ 不从右边找宏名, 除非 % 打头
equ1 equ  <te1>     ; type = text, value = te1
equ1 equ <<te1>>    ; type = text, value = <te1>
equ1 equ 4          ; type = text, value = 4

equ2 equ 1          ; type = number (int const), value = 1
equ2 equ 1
equ2 equ 2          ; error A2005: symbol redefinition : equ2

equ3 equ % 3 * 4
    te3  textequ % equ3     ; error A2009: syntax error in expression
%   te3  textequ   equ3     ; error A2008: syntax error : integer. 两边都展开了
%   te4  textequ   equ3     ; te4 = (text) 12. te4 是新定义的名字无法展开, 且 textequ 视右边的 % 为求值
%%% te5  textequ  <equ3>    ; te5 = (text) % 3 * 4, 尖括号内的 % 无效
end

-EP 表明
A2005, A2009, A2050, A2084 有时用原来的值设置变量, 不改变变量的值, 有时把变量改为 0
A2009, A2050 导致 -Fl 不在 Symbols 里列出变量, 但变量仍存在
A2051 不设置变量, 不改变变量的值
```

### 输入输出

输入

- 代码里定义的名字
- `include filename` 用文件 filename 的内容替换 include 语句, filename 包含 `\;<>'"` 时要用尖括号包起来
- 通过命令行 -D 定义的文本宏

输出

- 替换后的文本. 仅在内存中, 不修改源文件; 可以替换为随意的文本, 但往往让它符合 masm 语法
-   - echo = %out 把参数输出到 stdout, 行首是 % 比如 % echo, % %out 时替换一次文本宏和宏函数
    - .erre, .errnz 把第 2 个参数视为 text item, 是文本宏或宏函数时忽略第 1 个 token 之后的内容

```
; ml -Zs dd.msm

abc equ <value is this>

   echo abc ; abc
 % echo abc ; value is this
%% echo abc ; value is this

.erre   0, abc ; error A2053: forced error : value equal to 0 : 0: value is this
.errnz  1, abc ; error A2054: forced error : value not equal to 0 : 1: value is this

; error A2053: forced error : value equal to 0 : 0: value is this
.erre   0, abc following chars are ignored

; % 只替换文本宏和宏函数, A2006 肯定是 .erre 替换 value 时报告的
; error A2006: undefined symbol : value
; % .erre  0, abc
; error A2006: undefined symbol : value
; % .errnz 1, abc
end
```

## 关键字

### 标点, 符号, 操作符

operator | ascii | https://docs.microsoft.com/en-us/cpp/assembler/masm/operators-reference
-|-|-
!   | 33 | 在尖括号里视下一字符为字面值, 在其他地方无特殊意义. 主要用来转义尖括号
%   | 37 | 行首时替换该行的文本宏和宏函数; 文本项里按当前 radix 对常量表达式求值后转为文本项
&   | 38 | substitution, 用于标记引号里的文本宏和宏函数
+, -, *, /, mod | 43, 45, 42, 47 | 中缀操作符接受左右两个操作数; 加减乘除, 取余数
;   | 59 | 注释. 宏定义里的 ;; 不随宏替换至源码
<>  | 60, 62 | 文本项, 常用在参数里比如 `.err`, `option nokeyword: <xxx>`
[]  | 91, 93 | expr1[expr2] = expr1 + expr2
and, or, xor, shl, shr |-| 位逻辑和按位左右移
not |-| not expr, 按位取反
eq, ne, ge, gt, le, lt |-| equal, not equal, greater or equal, greater than, less or equal, less than. 返回 -1 代表 true, 0 代表 false

显然 masm operator 参与的 token group 不等于 expression, 不一定有值

punctuation | ascii | msdn 不把这些叫 operator
-|-|-
()  | 40, 41 | 宏函数调用
=   | 61 | 定义整数变量, 简称为变量. 可以反复赋值
\   | 92 | 行尾时续行

```
; % statement, '&text-macro&'

                                ; type  value
    te1 textequ <abc>           ; text  abc
    te2 textequ  te1            ; text  abc
    te3 textequ <te1>           ; text  te1
%   te4 textequ <te1>           ; text  abc
%   echo 1 te1, te2, te3, te4

    te1 textequ <new>           ; text  new
%   echo 2 te1, te2, te3, te4

%   echo 3 <&te3> <&&te3&&> <&&&te3&&>
%   echo 4 '&te3' '&&te3&&' '&&&te3&&'
%%  echo 5 "&te3" "&&te3&&" "&&&te3&&"
%%% echo 6 '&te3' '&&te3&&' '&&&te3&&'
end

ml -Zs dd.msm

1 abc, abc, abc, abc
2 new, abc, new, abc
3 <new> <&new&> <&&new&>
4 'te1' '&te1&' '&&te1&'
5 "te1" "new" "&new"
6 'te1' 'new' '&new'
```

### 文本宏

`name equ expr` 在定义时确定类型, 之后类型不变; typeof expr == number 则类型是 number, 不能再次赋值; 否则是 text<br>
`name textequ text-item, text-item...`

610guide p???/p190 String Directives and Predefined Functions

- 指示的 return 有点不准确, 因为这 4 个指示取代了 textequ, =; catstr 和 textequ 是同义词
- 指示是关键字, 不区分大小写; 宏函数是名字, 区分大小写时 (`option casemap`, `-C[p|u|x]`) 必须匹配大小写
- instr 的第一个参数是可选参数, 若要不提供此参数, 指示是不写, 宏函数是空逗号
- string 下标从 1 开始
- 和其它宏函数一样, 这 4 个预定义宏函数不替换文本宏参数

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

### 条件编译

条件编译 | 解释
-|-
if* elseif* else endif  | 是否编译块里的内容
if/elseif constexpr     | 如果 constexpr 不等于 0
ife/elseife constexpr   | 如果 constexpr 等于 0
ifb/elseifb text-item   | 如果 text-item 空
ifnb/elseifnb text-item | 如果 text-item 不空
ifdef/elseifdef tag     | 如果定义了变量 tag
ifndef/elseifndef tag   | 如果没有定义变量 tag
ifidn/elseifidn text-item-1, text-item-2   | 如果 text-item-1 和 text-item-2 的值相同
ifidni/elseifidni text-item-1, text-item-2 | 如果 text-item-1 和 text-item-2 的值相同, 忽略大小写
ifdif/elseifdif text-item-1, text-item-2   | 如果 text-item-1 和 text-item-2 的值不同
ifdifi/elseifdifi text-item-1, text-item-2 | 如果 text-item-1 和 text-item-2 的值不同, 忽略大小写

```
; 分支和操作符

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

ml -Zs dd.msm

`if` casts condition to integer then eval, str2 > int1
content of str1 differs from str2
`ifidni` thinks str2 and str3 are different, but `if` thinks they equal
```

> 610guide p???/p187<br>
repeat(rept, masm 5.1-)/while/for(irp, masm 5.1-)/forc(irpc, masm 5.1-), exitm, endm

### 重复块

重复块把块内的语句就地重复指定次

- for 的第 2 个参数需要尖括号. 把第 2 个参数看成是以逗号分隔的参数列表, 遍历此列表<br>
forc 的第 2 个参数不需要尖括号. 遍历第 2 个参数的每个字符; 没有尖括号时使用第一个空格前的串, 忽略之后的串<br>
for 和 forc 尖括号里的规则就跟屎一样
    - 发生 2 次转义, 要让 for 的单个参数是 `a, b` 需要写 `<a!!, b>`, `a!, b` 要写 `<a!!!!!!, b>`
    - 吃掉 `%`; `\` 是参数最后一个非空字符时吃掉
    - 要求单引号, 双引号匹配; 后引号和后尖括号都可以在分号后面, 即注释里
    ```
    ; for/forc i, <text>
    ;     statements
    ; endm
    ;
    ; for i: req , <text>     i 是必填参数, 不能是空串否则报错
    ; for i: =<c>, <text>     i 是默认参数, 如果是空串则 i = c

    for i, <abcd!, 80 + 3>
        echo i
    endm

    forc i, 12,4a 786
        echo i
    endm
    end

    ml -EP dd.msm

        echo abcd
        echo 80 + 3

        echo 1
        echo 2
        echo ,
        echo 4
        echo a
    end
    ```
- repeat, 同样的语句重复指定次
    ```
    ; repeat constexpr
    ;     statements
    ; endm

    factorial2cnt = 6
    factorial2amt = 1

    repeat factorial2cnt
        factorial2amt = factorial2amt * factorial2cnt
        factorial2cnt = factorial2cnt - 1
    endm

    factorial2str textequ % factorial2amt
    % echo factorial2 factorial2str

    end

    ml -EP dd.msm

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
- while, 同样的语句重复若干次, 每次重复前都查看 expression, 不为 0 时才重复, 否则退出; 用 exitm 也能退出
    ```
    ; while expression
    ;     statements
    ; endm
    ;
    ; 610guide p???/p188 的示例, 这本书的示例一般都依赖汇编指令
    ; > out\fff ml -EP dd.msm

    xxx segment
    cubes   LABEL   BYTE            ;; Name the data generated
    root    = 1                     ;; Initialize root
    cube    = root * root * root    ;; Calculate first cube
    WHILE   cube LE 32767           ;; Repeat until result too large
        WORD    cube                ;; Allocate cube
        root    = root + 1          ;; Calculate next root and cube
        cube    = root * root * root
    ENDM
    xxx ends
    end
    ```

### 宏过程, 宏函数

宏 | 解释
-|-
macro

### 杂项关键字

杂项 | 解释
-|-
title, subtitle, page, page +   | used on assembly listings

## 替换或展开的时机

展开啥 |-
-|-
关键字 | if*, repeat, while, for, forc. 这些东西自己占一行, 要么展开要么编译错误
调用 | `文本宏`; `宏过程, arg, ...`; `宏函数(arg, ...)`. 宏过程如果不是一行的首个非空白则不视为调用
-| 没有能展开的字面量

文本宏和宏函数可以出现在一行里的好几种位置. 如果一行不以 % 打头则
- 不替换下列位置的文本宏和宏函数
    - 引号, 尖括号里
    - 分号后面, 即注释
    - 宏过程, echo, equ 的右边, name, title, for, forc, ... 的参数
- 不替换下列位置的文本宏
    - textequ 的左右两边

在剩余位置展开宏关键字, 文本宏, 宏函数; 如果得到文本宏或宏函数, 继续展开, 直到没有宏或者达到规定的展开次数

> cv help/index/assembler/m/macro directive<br>
macro procedures and macro functions can be nested up to 40 levels; text macro may be nested up to 20 levels

bug1: 此链最后一个调用必须返回文本宏否则报 A2039, 给人感觉调用结果没有结束符; 撮合无论成功与否 -EP 都能看到一堆乱码.
模式 2 撮合, 拼接都正常, -EP 也没有乱码. 我感觉模式 2 只管展开, 让下一遍去发现拼接结果, 但不知道是否立即撮合.
为什么怀疑模式 2 的立即撮合呢? 因为如果立即做, -EP 又不出乱码, 说明模式 1 和 2 各自有执行函数的代码, 显然不简练.

```
; nesting level 不能大于 20. ml -EP dd.msm
;
; error A2123: text macro nesting level too deep, 多 deep 算 too deep? 用下面代码试了试
; 展开出了 21 个 1$. 所以 A2123 的 too deep 指的应该是 > 20
; 这个 > 20 真熟悉, 我记得 windows api 的 winproc 也检测递归, 数量好像也是 20, 那还是我上 cn.fan 新闻组的时候

self_ref textequ <1$ self_ref>
self_ref
end
```

```
int1 = 3 - 5 / 4
te2 textequ % int1

mf3 macro
    exitm <3>
endm

 int1, te2, mf3()
'int1, te2, mf3()'
"int1, te2, mf3()"
<int1, te2, mf3()>
end

ml -EP dd.msm

int1 = 3 - 5 / 4
te2 textequ % int1


dd.msm(8): error A2008: syntax error : int1
 int1, 2, 3
dd.msm(9): error A2008: syntax error : int1, te2, mf3()
'int1, te2, mf3()'
dd.msm(10): error A2008: syntax error : int1, te2, mf3()
"int1, te2, mf3()"
dd.msm(11): error A2008: syntax error : int1, te2, mf3()
<int1, te2, mf3()>
end
```

一句话以 % 打头时. % 从更多的位置替换文本宏和宏函数

; 若展开出的串最后一个 token 是宏函数名, 往后查找圆括号以展开该函数 (bug1); 否则不和后面的文本拼接

- 不展开这句话里的下列位置
    - 块宏的参数
- 也展开这句话里的下列位置
    - 引号里带 & 的, 尖括号里的
    - echo, name, title, for, forc, ... 的参数
    - 文本项
    - 分号后面的串 (注释)
- nl 不能大于未知 (520+?) 所以可能是循环
- 如果宏名挨着 &, 展开时删掉 &; 引号外除非为了隔开两个名字 tok1&tok2 否则不需要 &
- 引号里的 token 必须挨着至少 1 个 & 才算宏名, 至多 2 个 = 两边各一个即 &tok& 或 &f()&
- 两个反斜杠变一个反斜杠; 一个反斜杠删掉
- 删掉行首的 1 个 %, 展开, 不检查语法. 完毕查看行首, 如果行首以 % 打头, 再来一遍; 否则以模式 1 再来一遍

肯定还有很多没有列出来的情况, 只能遇到了再添加

## bugs

### equ 后的文本接受语法检查

```
; bug: equ 不要求尖括号, 不使用尖括号时文本要接受语法检查
; ml -Zs dd.msm

% echo abc              ; abc
abc equ value is this   ; error A2034: must be in segment block
% echo abc              ; value is this
abc equ value is this1
% echo abc              ; value is this1
end
```


## 代码示例

### 实现 @sizestr

预定义的宏函数 @sizestr 计算参数的 ascii 字符个数, 不展开参数. 如何不展开参数? 若干想法

- 把宏放在单独的环境里执行, 此时由于没有定义宏所以也不发生展开. 依靠现在这些语法显然实现不了
- 模式 1 有过滤, 过滤区域的参数不展开. 计算字符个数要用循环, 正好模式 1 的 forc 不展开参数

```
; ml -Zs dd.msm

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

### 实现 @catstr, 失败

- @catstr 返回一个字符串值而不是字符串变量. 这个返回文本宏就行了
- 要接受参数, 只能是宏过程或宏函数. 宏过程没法返回值, 只能用宏函数. 参数数量不定, 只能用 vararg, 丢一层尖括号; 拼接字符串时问题不大, 要求调用处在必要时给文本加尖括号. vararg 里保存的是扒了一层尖括号并混入逗号的串, 这就是参数的最完整形式. 接下去既不能用 for 也不能调用函数, 因为会再丢一层尖括号. 那只剩 forc 能用了
- 引号和尖括号里的逗号不分开参数, 尖括号可以嵌套; 所以用 sq, dq 表示单, 双引号, 取值 0 或 1; 用 ab 表示尖括号的嵌套等级

在试了几个串后我写下了这个串 <!<!<!<!<!<ab, cd>, 34

vararg 拿到的是 `<<<<<ab, cd,34`, @catstr 输出 `<<<<<ab, cd34`, 问题来了: 该保留哪些逗号?

我刚才说 vararg 丢一层尖括号在拼接字符串时问题不大? 事实证明我错了, 丢尖括号问题太他妈大了!

仔细想想丢尖括号只是小问题, 根本问题在于 vararg 是 1 个参数, 不可能把它还原到调用时的状态, 它不是json 那样的转义字符串. 多个参数合并为 1 个 vararg 时丢失了参数个数这个信息, 相比之下丢一层尖括号根本不算事.

由于无法取得传入的参数, 无法实现 catstr.

### todo: toupper

难点: 怎么把一个小写字符的大写形式放入文本宏? 我不想查表. 话说回来, 宏里面怎么查表?

等价问题: x = "a" 让 x 保存字符 a 的 ascii 值; 现在有 ascii 值, 怎么得到字符?

```
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

### 非行首的重复块和宏过程

```
; ml -Zs dd.msm

; text macro 不能包含换行, 重复块只能生成行, 所以尝试续行符. 想用重复块生成下面定义 te1 的语句

te1 textequ % 1 * 2 * \
    3 * \
    3 * \
    3 * \
    1

% echo te1 ; 54

; repeat 看似在行首, 但其上一行对 repeat 报错说明续行符生效了, repeat 不在行首
; 这里失败的原因是 repeat 不在行首所以不能展开, 还是 textequ 不接受 repeat?

te2 textequ % 1 * 2 * \ ; error A2008: syntax error : repeat
repeat 3
    3 * \               ; error A2008: syntax error : integer
endm
    1                   ; error A2008: syntax error : integer

; 宏过程也不行

mpart macro
    repeat 3
        3 * \
    endm
endm

te3 textequ % 1 * \ ; error A2148: invalid symbol type in expression : mpart
    mpart
    1               ; error A2008: syntax error : integer

; mpart ; fatal error DX1020: unhandled exception: Page fault

abc = 1   mpart ; error A2206: missing operator in expression
abc = 1 + mpart ; error A2148: invalid symbol type in expression : mpart
end
```












## 致谢

🚧 *under construction*

2019.9.14 下午, 和[俞悦](https://github.com/josephyu19850119)讨论后做出下列修改, 并从 txt 改为 md

- (太费解) 删除令人费解的名词比如把 token 翻译为信物; 用 A.D. 表示公元后; css 术语 inline, block, inline-block
- (太吓人) 删除对续行的描述
- (太抽象) 重新把示例代码混入介绍, 早先是把这俩分开了; 建议是开头添加 hello world, 考虑之后在开头添加速成课
- (太误导) 明确对 610guide (Microsoft MASM 6.1 Programmer's Guide) 的引用: 用 "610guide" 代替 "本书"

2022.9.14 major rewrite in the hope of making a way better readability














<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>

## 预处理 111111111111111


### 展开

替换宏可能得到其他宏, 继续替换得到的宏直至没有宏, 这个反复替换的过程叫展开; 不严格区分时这俩词通用.
展开宏就是构造一棵树, masm 称这个树的高度为 **nesting level (nl)**, nl 超过规定值会停止处理该行并报错 A2123.

宏程序执行的结果是宏消失, 源代码改变. 公元 2000 年之后的源码级调试里可能看到的是展开前的代码, 宏函数看起来就像一般函数;
记住这只是有益的假象, 用来保持源代码的行号. 宏在编译前展开, 消失.

前面已经学习了展开重复块, 下面要说展开 3 种具名宏: 文本宏, 宏过程, 宏函数.

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
- exitm 后跟文本项, 不能像 catstr/textequ 那样拼接字符串; exitm <> 返回空字符串
- exitm, %exitm text-item, 不会把宏过程变成宏函数
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

### 参数

参数包括宏的参数和 for, forc 的参数

- 确定参数: 查找语句里的 &arg&, &arg, arg&, arg
- 替换参数: 删除参数第 1 层尖括号, 替换参数名

```
mp macro a, b, c, d
    echo &a& &a a& a a&&    ; 这 4 种都是参数名: &arg&, &arg, arg&, arg
    echo b  ; 删除第 1 层尖括号
    echo c  ; 1. 删除第 1 层尖括号, 2. % 求值, 3. ! 转义 4. 保留空格
    echo d  ; 引号里的不动. ; 后的没输出是 echo 的问题

    echo lb&&a&68   ; 拼接
    echo a&b a&&b   ; & 仅用于隔开参数; 除非在引号里 (惰性环境) 否则两个 & 没必要

    for i, b                ; for 的第 2 个参数必须有尖括号
        echo &a& &a a& a    ; 这 4 种都是参数名: &arg&, &arg, arg&, arg
        echo &i& &i i& i    ; 删除 <this> 的第 1 层尖括号
        exitm
    endm

    forc i, c               ; forc 的第 2 个参数不需要尖括号, 没有尖括号时忽略空格之后的内容
        echo i              ; 打印两行分别是 a, b; 删除 a<b> 的第 1 层尖括号
    endm
endm

mp `xt`, <<<this>, is>>, a<b>    <<<<c>>>> ^<d<&(!*&% 1 + 2>%!>$>[, "^<d<&(!*&% 1 + 2>%!;>$>["
end

输出 Assembling: dd.msm
`xt` `xt` `xt` `xt` `xt`&
<<this>, is>
ab    <<<c>>> ^d<&(*&3>>$[
"^<d<&(!*&% 1 + 2>%!
lb&`xt`68
`xt`<<this>, is> `xt`<<this>, is>
`xt` `xt` `xt` `xt`
this this this this
a
b
```

我把宏参数和命令行参数放一块比了比. 命令行是程序自己处理原始命令行, masm 是 masm 处理完给你, 你没有机会拿到原始字符串,而这个处理过程有 bug:

- 移除了第 1 层尖括号
- 宏函数作参数时的 bug

```
        delimiter   delimiter in arg    quote in arg    vararg                  substitution
cmd     space       " "                 "\""            raw string              no
masm    ,           <,>                 <!<>            cooked string (buggy)   yes
```

[宏函数作参数时的 bug](#宏函数作参数时的-bug)

### 两种查找文本宏和宏函数的模式

masm 视一行是否以 % 打头, 采取两种确定文本宏和宏函数的办法

- 查找模式仅适用于文本宏和宏函数; 宏过程只有一种查找模式, % 影响的是它的参数; 宏过程的名字也不靠 & 确定
- **文本宏死区** 模式 1 和 2 都不从这些地方查找文本宏: 宏函数参数的字符串 (尖括号), 文本宏 (没符号)

#### 模式 1

- 如果一句话不以 % 打头, 以此模式确定该句的文本宏和宏函数
- 边展开, 边检查语法. [nl](#展开) 不能大于 20 所以可能是递归调用
- **过滤** 不从下列地方查找宏名<br>
    引号, 尖括号; 块宏, echo, name, title, ... 的参数; for, forc 的参数; 左值; 文本项的字符串, 文本宏
- **撮合** 若展开出的串最后一个 token 是宏函数名, 往后查找圆括号以展开该函数 (**bug1**); 否则
- **不拼接** 不和后面的串拼接. 撮合是**拼接**的一种

#### 模式 2

- 如果一句话以 % 打头, 以此模式确定该句的文本宏和宏函数
- nl 不能大于未知 (520+?) 所以可能是循环
- 如果宏名挨着 &, 展开时删掉 &; 引号外除非为了隔开两个名字 tok1&tok2 否则不需要 &
- 两个反斜杠变一个反斜杠; 一个反斜杠删掉
- 也展开分号后面的串 (注释)
- 也展开这些宏: 引号里带 & 的; 尖括号里的; echo, name, title, for, forc, ... 的参数; 文本项
- **惰性环境** 引号里的 token 必须挨着至少 1 个 & 才算宏名, 至多 2 个 = 两边各一个即 &tok& 或 &f()&
- 删掉行首的 1 个 %, 展开, 不检查语法. 完毕查看行首, 如果行首以 % 打头, 再来一遍; 否则以模式 1 再来一遍

**bug1**: 此链最后一个调用必须返回文本宏否则报 A2039, 给人感觉调用结果没有结束符; 撮合无论成功与否 -EP 都能看到一堆乱码.
    模式 2 撮合, 拼接都正常, -EP 也没有乱码. 我感觉模式 2 只管展开, 让下一遍去发现拼接结果, 但不知道是否立即撮合.
    为什么怀疑模式 2 的立即撮合呢? 因为如果立即做, -EP 又不出乱码, 说明模式 1 和 2 各自有执行函数的代码, 显然不简练.
    参考: [模式 2 不撮合](#模式-2-不撮合)

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

<字符串>, 不展开
宏函数(), 调用
% 表达式, 调用宏函数, 展开文本宏
文本宏  , 不展开
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

; 宏参数在模式 1 下展开宏函数, 不展开文本宏. 对比 catstr/exitm/textequ, 它们展开参数里的文本宏

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

> 610guide p???/p198<br>
在宏里可以用 pushcontext, popcontext 保存, 恢复下列设置

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

## masm 和 c 的预处理

```
macro of masm                   c
if, elseif, else, endif         #if, #elif, #else, #endif
ifdef , elseifdef               #ifdef , #if  defined, #elif  defined
ifndef, elseifndef              #ifndef, #if !defined, #elif !defined
ife, elseife                    <none>
textequ, macro *                #define
<none>                          #undef
.err                            #error
.erre, .errnz                   <none>
.errdef, .errndef               <none>
*   c 的宏一行就够了, 因为可以用分号创建许多逻辑行; masm 的行是硬行, 创建单行宏和多行宏语法不同
    c 的宏只展开一次; masm 的宏一直展开到没有宏为止

within macro definitions        c
ifb, elseifb                    <none>
ifnb, elseifnb
ifidn, elseifidn                <none>
ifidni, elseifidni
ifdif, elseifdif                <none>
ifdifi, elseifdifi
rest: vararg                    ..., __VA_ARGS__
.errb, .errnb                   <none>
.erridn, .erridni               <none>
.errdif, .errdifi               <none>
<none 1>                        defined
<none 2>                        #s
<none 3>                        s1##s2
1 可以用宏函数实现
2 % expr 随处可用, 不限于宏定义里
3 s1&&s2 随处可用, 不限于宏定义里

Both /Zm and OPTION M510 imply SETIF2:TRUE. with OPTION SETIF2:TRUE
.err1, .err2

miscellaneous directives        c
echo, %out                      #pragma message
include                         #include
includelib                      #pragma comment(lib)
<todo: find out>                vc++ __pragma
```

## 观察与思考

### 退化

```
tag macro a: req, b: =<t>, c: vararg        tag       a       b    t   c    abc tag(arg1, arg2, arg3)
    local x, y, z                                     x  y  z
    make-use-of a, b                            make-use-of a  b                make-use-of arg1, arg2
    make-use-of c, x                            make-use-of c  x                make-use-of arg3, ??0x
    make-use-of y, z                            make-use-of y  z                make-use-of ??0y, ??0z
    exitm <whatever>                                  <whatever>                    abc <whatever>
endm

___ macro _: req, _: =<_>, _: vararg                    ^                   ^   ^   ^
    local _, _, _                                       |                   |   |   | 这是调用处的展开结果
    ________________                                这是用户填入的内容
    ________________                                                        |   | 这是调用处所在行前面的展开结果
    ________________                        <- 这是 masm 提供的结构
    exitm __________                                                        | 这是调用时的代码
endm
```

masm 提供一个多行且复杂的结构用来定义宏函数, 用户在里面填入内容; 定义的宏函数是个单行且简单的结构 名字 (参数, 参数, ...),
调用结果是个单行串. 退化体现在哪些地方?

- 定义出来的都是名字, 名字只能用名字允许的那些字符
- 关键字两边都是参数而名字只有右边是参数; 无法定义类似 `macro` 的 tag: left `tag` right
- 参数是处理过的, 拿不到原始串
- 多行变单行了, 无法定义起始/结束括号: `tag` ... `end tag`/`endtag`
- ```
    below is keyword                below is user defined name (udn)
    ccc begin-keyword ccc           ccc begin-name ccc end-name ccc
    ccc
    end-keyword x
    * c = character, x = no c allowed
    ```

keyword `macro` 定义了这些符号 `: req = vararg local exitm endm`, udn `tag` 可以定义自己的

退化的后果是无法用它提供的语法创造同样的语法, 更不用说新的语法. 当然这本来也不是 masm 的目标, 只是我自己的一个想法.

**进化?** 显然进化就等于自己写编译器了, 应该不是啥好事, 除非语法简单有效.

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

f 内拼接字符串时 dep1 是 local 变量名而不是值, 所以 echo 前面加了 %; 要传值可以这么写

f macro height, depth: =<0>, nodetype: =<root>
    local dep1, s

    dep1 textequ % depth + 1
    s textequ <>

    echo nl depth, nodetype

    if dep1 lt height
        s textequ <f(height, >, dep1, <, branch1) f(height, >, dep1, <, branch2) f(height, >, dep1, <, branch3)>
    elseif dep1 eq height
        s textequ <f(height, >, dep1, <, branch4) f(height, >, dep1, <, branch5)>
    elseif dep1 - height eq 1
        s textequ <f(height, >, dep1, <, leaf)>
    endif

    exitm s
endm

思考
上面用的是宏函数. 能不能控制文本宏的递归次数, 或者组合多个其它文本宏? 如果接受参数可能能, 但它不接受参数所以可能不能
todo: 证明它能或不能. 可能作为论据的事实
- no  每次都是常量替换
- no  既然不接受参数, 则每次替换/调用/展开都得到相同结果
- yes 隐含的参数? 有没有? 如何实现?
```

### 模式 2 不撮合

ml -Zs dd.msm

```
arg textequ <1234567890>
te  textequ <f>
z   textequ <>

f macro a
    echo f called with a
    exitm <z>
endm

; 模式 1 撮合, 输出 f called with arg
te(arg)

; 输出 f called with 1234567890
% te(arg)
end

模式 2 如果撮合, 输出会和模式 1 一样; 但实际输出表明调用 f 时 arg 已经展开了. 按从左到右的顺序, 模式 2 下 masm
先看到函数名 f 和圆括号, 然后看到 arg; arg 既然展开了, 说明这函数调用没有发生. 模式 2 之后还有模式 1, f 只能是
在模式 1 中调用的.

如果抛开 masm 的从左到右, %, 文本宏死区, ... 去解释输出, 当然能列出很多种可能; 但在 masm 里, 上面的分析是唯一的可能.
```

## 代码演示

### 返回函数名

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
; f()1() triggers error A2008: syntax error : f, then expands to f1()       - 模式 1 不拼接
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
    没办法取变量的值, 计算出来的值总是由某个变量指代: 字面量不是变量, 但其值只能在程序运行前指定; `%` 计算整数表达式;
    `<变量名>` 是字符串, 反倒又加一层间接; `文本宏`没贡献; `宏函数()` 面临同样的问题

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

### 展开本来不展开的文本宏

#### 作为宏函数参数时, 文本宏不展开

宏函数参数不展开文本宏, 展开宏函数; 所以要展开宏函数的文本宏参数, 需要拼接出一个宏函数调用的串然后执行该串.

为什么不能让宏函数在自己的函数体里展开参数? 自己定义的宏函数当然没问题, 但那 4 个预定义宏函数你没法改它们的代码.

假设想调用 `@sizestr(s1)`, 如果把这个串原样写出来就会调用 @sizestr, s1 当作字面量, 没有宏替换. 这让我想到 html 的
script 标签里要避免字面量 `</script>`, 往往是字符串里可能有这东西, 解决方法是分开写, 比如 `"<" + "/scirpt>"`.
`@sizestr(s1)` 的思路是一样的.

```
call_@sizestr_with_arg_expanded macro s
    local x
    ifdef s
        x textequ <@sizestr(>, s, <)>
    else
        x textequ <@sizestr(s)>
    endif
    exitm x
endm

% echo call_@sizestr_with_arg_expanded(s1)  ; 02
s1 textequ <this is abc>
% echo @sizestr(s1)                         ; 02
% echo call_@sizestr_with_arg_expanded(s1)  ; 011

; 看看它返回的啥
% echo "&call_@sizestr_with_arg_expanded(s1)"
; 输出 "011", 说明函数调用发生在 exitm 处而不是返回之后; 它返回一个值而不是变量名, 非常好
end
```

\* *ifdef 判断名字是否定义了. 定义的名字不一定是文本项但该函数只能处理文本项否则报错. 我觉得可以接受.*

当然也有其他的想法, 比如先阻止函数调用, 替换参数后再形成函数调用:

```
te textequ <@sizestr>
arg textequ <1234567890>

; te(arg) ; 撮合, 由于 @sizestr 不返回文本宏所以 A2039

; % echo te(arg)
; 输出 @sizestr(1234567890)
; 原因: % 导致展开 echo 后面的文本宏和宏函数; te 是文本宏, 展开得到 @sizestr, 这是个函数名, 圆括号位于其后的节点,
; 要发生调用需要撮合, 而模式 2 不撮合

%% echo te(arg)
end
```

热身运动 (?!?! 💀 Here Be Dragons): <span id=拼接字符串>拼接字符串</span>

```
x textequ <a>
x textequ x, <b>
x textequ x, <c>

% echo x ; abc
end
```

下面实现任意数量参数的调用.

```
call_with_args_expanded macro f: req, rest: vararg
    local x, len

    ;; 不能写 x textequ <f(>, rest, <)>
    ;; - 没传参数时 rest 是空串, 得到 x textequ <f(>, , <)>, 语法错误
    ;; - rest 里有未定义的名字时, 语法错误
    ;; x textequ <f(>, <rest>, <)> = <f(rest)>, rest = arg2, arg3, ..., 参数均未展开, 也不行
    ;; 因此需要在 for 里判断每个参数, 反复拼接

    x textequ <>

    for i, <rest>
        ifdef i
            x textequ x, <, >, i
        else
            x textequ x, <, i>
        endif
    endm

    ifb x
        x textequ <f()>
    else
        ;; 删除开头的逗号
        len sizestr x
        x substr x, 2, len - 1
        x textequ <f(>, x, <)>
    endif

    exitm x
endm

f macro a, b, c
    echo f_a = a, f_b = b, f_c = c
    exitm <>
endm

call_with_args_expanded(f)
call_with_args_expanded(<f>, s1)
s1 textequ <this is abc, second, <h, there>>
second textequ <2ndargreplaced>
call_with_args_expanded(<f>, s1)

end

输出
f_a = , f_b = , f_c =
f_a = s1, f_b = , f_c =
f_a = this is abc, f_b = 2ndargreplaced, f_c = h, there

注意尖括号. 以前说过 masm 在传参数时删除嵌套等级 = 1 的尖括号. 在这里函数调用扒一层, for 扒一层. 无论是否有 for,
函数体内没法判断参数在传入时是啥样. 如果想调用 @sizestr 得套 3 层尖括号否则 @sizestr 报参数太多

% echo @sizestr(s1)
% echo call_with_args_expanded(<@sizestr>, <<<s1>>>)
```

\* *[No Old Maps Actually Say 'Here Be Dragons'](https://www.theatlantic.com/technology/archive/2013/12/no-old-maps-actually-say-here-be-dragons/282267/)*

#### 作为左值, 比如放 textequ 左边时文本宏不展开

拼接字符串时想到个问题: 想从变量拼接名字, 又不想展开右边, 该怎么做?

```
f macro outPrefix, rest: vararg
    ;;    ??0000     ??0001 ??0002  ??0003
    local activator, c,     middle, prefix

    c textequ <0>
    outPrefix textequ <prefix>

    for i, <rest>
        ;; 我想拼接左边, 不展开右边, i.e. ??0003$0 textequ abc, how?
        ;; % prefix&$&&c textequ i       ; fail: ??0003$0 textequ ddd, 两边都展开了
        @catstr(prefix, $, c) textequ i ;; fail: ??0003$??0001 textequ abc, c 没有展开

        ;; 这时想起了拼接函数调用字符串
        middle textequ <@catstr(prefix&$, >, c, <)>
        ;; 虽然 middle 的值是 @catstr(??0003$, 0), 但下面只是替换了参数, 并没有调用它
        middle textequ i ; fail: ??0002 textequ abc
        ;; 可以一次拼出来 @catstr(??0003$0), 进而发现 @catstr 仅仅是为了函数调用
        ;; middle textequ <@catstr(prefix&$>, c, <)>

        ;; middle() 明显不对, 但意外发现展开成了 ??0003$0()
        middle textequ <@catstr(prefix&$, >, c, <)>
        ;; middle() textequ i ; fail: ??0003$0() textequ abc

        ;; 是圆括号激发了展开吗? 比如 ??0002() 由于后跟圆括号所以导致调用函数?
        ;; 但 middle 即 ??0002 的值是 @catstr(??0003$, 0), 没法后跟圆括号了. 放函数里试试?
        activator macro
            local t
            t textequ <@catstr(prefix&$, >, c, <)>
            exitm t ; eval
        endm

        ; succeed: ??0003$0 textequ abc
        activator() textequ i

        c textequ % c + 1
    endm
endm

abc textequ <ddd>
f prefix, abc
%  echo prefix      ; ??0003
%% echo prefix&$0   ; ddd

; error A2051: text item required
; f prefix, 10, 23, 32
; %% echo prefix&$0 prefix&$1 prefix&$2 prefix&$3
end
```

textequ 左右两边都是参数.

模式 1 textequ 不展开左边的文本宏, 展开宏函数, 所以用宏函数调用取代文本宏; @catstr 在这里没必要:

```
f macro outPrefix, rest: vararg
    local c, f, prefix

    c textequ <0>
    outPrefix textequ <prefix>

    for i, <rest>
        f macro
            local t
            t textequ <prefix&$>, c
            exitm t
        endm

        f() textequ <i>
        c textequ % c + 1
    endm
endm

abc textequ <ddd>
f prefix, abc
%  echo prefix          ; ??0002
%% echo prefix&$0       ; ddd
%% echo "&&prefix&$0"   ; "abc"

f prefix, 10, 23, 32
%% echo prefix&$0 prefix&$1 prefix&$2 prefix&$3 ; 10 23 32 ??0006$3
end
```

### Douglas Crockford: Memoization

douglas-crockford/javascript-the-good-parts/4.15-memoization

```
var memoizer = function (memo, fundamental) {
    var shell = function (n) {
        var result = memo[n];
        if (typeof result !== 'number') {
            result = fundamental(shell, n);
            memo[n] = result;
        }
        return result;
    };
    return shell;
};

// 斐波那契数列 f(n) = f(n - 1) + f(n - 2)
var fibonacci = memoizer([0, 1], function (shell, n) {
    return shell(n - 1) + shell(n - 2);
});

// 阶乘 f(n) = n * f(n - 1)
var factorial = memoizer([1, 1], function (shell, n) {
    return n * shell(n - 1);
});

fibonacci(10)
factorial(10)
```

函数 memoizer(arr, f) 返回函数 shell(n), 让 shell 捕获自己的两个参数. 参数 1 是整数区间 [a, b], n 在这个区间时 shell
返回 `arr[n]`, 这个值是调用 memoizer 前就知道并传给 memoizer 的; n 不在这个区间时 shell 用 memoizer 的第 2 个参数
f(shell, n) 求 `arr[n]`; f 要想递归必须调用 shell 以使用 shell 里的查 arr 以终止递归的逻辑, 不能直接调用自身.
memoizer, shell, f 这 3 个函数紧密耦合, 必须把它们放在一块理解, 没有哪个函数能独立出来.

memoizer 有任何用武之地吗? 斐波那契, 阶乘应该不会用它, 非常的绕; 我估计凡是递推公式都不会用它, 递推公式的两种计算方法,
循环和递归, 哪一个都比它好. 除开递推公式我也想不出有啥地方需要它.

那为什么写这种东西? 我只能翻开电子书再看一遍.

javascript the good parts, 4.15 记忆

fibonacci 递归

```
var fibonacci = function (n) {
    return n < 2 ? n : fibonacci(n - 1) + fibonacci(n - 2);
};

for (var i = 0; i <= 10; i += 1) {
    document.writeln('// ' + i + ': ' + fibonacci(i));
}
```

可以看到每次调用 fibonacci(n) 都会把 1 ~ n 计算一遍. 为避免递归中的重复计算, 他打算让函数捕获一个数组用于缓存计算结果.

- 为什么要捕获, 函数局部变量不行吗?
    - 因为想递归调用函数, 递归里的所有调用都想使用这个数组. 多个函数调用共享一个数组
- 那为啥不把数组作为递归时的参数传给函数, 而非得捕获呢?
    - 可能是不想多这一个参数

好, 既然是捕获就需要把函数套在函数里, 这个套子存在的唯一意义是提供被捕获的变量, 所以把套子弄成一个立即调用的匿名函数,
寄希望于可以让它不是那么显眼.

```
// 立即调用的匿名函数只是个套子 (shell)
var fibonacci = function (  ) {
    var memo = [0, 1];
    var fib = function (n) {
        var result = memo[n];
        if (typeof result !== 'number') {
            result = fib(n - 1) + fib(n - 2);
            memo[n] = result;
        }
        return result;
    };
    return fib;
}(  );
```

观察上面的代码, 做一些变换

```
// 代码符合如下模式...                            "两个尖括号可以是变量?", 于是...            "但 f 还想重用 shell 的 if 和 arr!", 于是...
var fibo = function (  ) {                      var shell = function (arr, f) {         ...
    var arr = <some initial array>;                 <deleted since redundant>
    var calc = function (n) {                       ...                                     ...
        var result = arr[n];                            ...                                     ...
        if (typeof result !== 'number') {               ...                                     ...
            result = <mess with n, calc(n)>;                result = f(n);                          result = f(n, shell);
            arr[n] = result;                                ...                                     ...
        }                                               ...                                     ...
        return result;                                  ...                                     ...
    };                                              ...                                     ...
    return calc;                                    ...                                     ...
}(  );                                          };                                      ...

// 于是, 这是经过前面 3 步形成的函数 shell...       这是本节一开始给出的书里的代码...
var shell = function (arr, f) {                 var memoizer = function (memo, fundamental) {
    var calc = function (n) {                       var shell = function (n) {
        var result = arr[n];                            var result = memo[n];
        if (typeof result !== 'number') {               if (typeof result !== 'number') {
            result = f(n, shell);                           result = fundamental(shell, n);
            arr[n] = result;                                memo[n] = result;
        }                                               }
        return result;                                  return result;
    };                                              };
    return calc;                                    return shell;
};                                              };
```

你能找出上面左右两段代码的不同吗?

重读 js good parts 后我再次理解 (首次记起) 了 memoizer, 它就是为了给递归调用提供一个共享数组 - 以一种别扭的方式.
换我来写, 用当时的语法和思路, 能写的更好吗?

但修改 memoizer 的事现在不做, 现在要做的是用 masm 的宏实现 crockford 的 memoizer.

热身运动: <span id=数组>数组</span>

masm 的宏里面只有两种值类型: 整数, 字符串; 没有数组. 所以思路是把 `a[n]` 替换成 `a(n)`, 用宏函数调用表示数组取值.
数组的元素保存在哪呢? 下面是几个思考

- 保存为字符串 a, b, c, d, ...: 每次都要从逗号解析, 效率低, 如何处理值里有逗号的情况?
- 保存为字符串 000a000b000c...: 固定长度, 不需要找逗号; 几乎仅适合元素是整数的情况, 短串浪费容量, 长串保存不下 *
- 从 local 符号拼接名字 ??0005&3: 最好的办法

\* *记录长度 (不是这里的定长) 是保存字符串的有效方法 - 界外 out of bounds; 特殊字符, 转义字符则非常不靠谱 - 界内 in bounds*

```
newArray macro arr, rest: vararg
    local prefix, c

    c textequ <0>

    for i, <rest>
        % prefix&&&c = i
        c textequ % c + 1
    endm

    arr macro i, val
        ifnb <val>
            prefix&&i = val
            exitm <>
        elseifdef prefix&&i
            exitm % prefix&&i
        else
            exitm <>
        endif
    endm
endm

somenumber = 3
newArray arr1, 1, somenumber

arr1(4, 34)
%echo arr1(0) arr1(1) arr1(2) arr1(3) arr1(4)   ; 1 3   34
end
```

**注意** 1. 函数 arr 没有确保 i 是整数; 2. newArray 说是数组, 实际上是个映射

为什么不把 newArray 定义为宏函数, 然后写 arr1 textequ newArray(12, 5, -8) 呢? 因为

- 那样 arr1 就是个字符串, arr1(53) 是撮合, 为避免 A2039, 要么返回文本宏要么进模式 2, 麻烦
- 由于模式 2 不撮合, % echo arr1(5) 得到 echo ??00nn(5), 想打印值得 %% echo arr1(5), 还是麻烦

返回字符串麻烦, 那为什么不能让 newArray 返回宏函数然后写 arr1 = newArray() 然后 arr1(6) 呢?

- [宏函数](#宏函数)只能返回文本

memoizer 就没那么多顾忌了, 反正也不会用它, 仅拿来练习, 所以让他返回函数名.

```
; ml -D n=10 -Zs dd.msm

; 在此处粘贴 newArray 的定义

memoizer macro memo, f
    local shell

    shell macro n
        local result

        result textequ memo(n)

        ifb result
            result textequ f(<shell>, n)
            memo(n, result)
        endif

        exitm result
    endm

    exitm <shell>
endm

newArray arrFib, 0, 1
newArray arrFac, 1, 1
cbFib macro shell, n
    exitm % shell(% n - 1) + shell(% n - 2)
endm
cbFac macro shell, n
    exitm % n * shell(% n - 1)
endm

fibonacci textequ memoizer(<arrFib>, <cbFib>)
factorial textequ memoizer(<arrFac>, <cbFac>)

ifdef n
    %% echo fibonacci (n) factorial (n)
else
    %% echo fibonacci(19) factorial(12)
endif
end
```

**注意** 函数 cbFib, cbFac 没有确保 n 在正确的区间, crockford 的原文也没有确保这点.

本节宏的内容已经展示完毕, 现在看看 crockford 的 memoizer.

```
var memoizer = function (memo, fundamental) {
    var shell = function (n) {
        var result = memo[n];
        if (typeof result !== 'number') {
            result = fundamental(shell, n);
            memo[n] = result;
        }
        return result;
    };
    return shell;
};

// remove useless shell                             按正常的方式写函数, 改掉莫名其妙的名字
var shell = function (n, memo, fundamental) {       function f(n, arr, cb) {
    var result = memo[n];                               var result = arr[n];
    if (typeof result !== 'number') {                   if (typeof result !== 'number') {
        result = fundamental(shell, n);                     result = cb(f, n);
        memo[n] = result;                                   arr[n] = result;
    }                                                   }
    return result;                                      return result;
};                                                  }

// 观察 f 和 cb 的参数列表
// cb 里面要调用 f; f 需要 (n, arr, cb) 但 f 调用 cb 时只传了 (f, n), cb 只知道 (cb, f, n)
// 为什么以前不需要传 arr?
// - 因为以前 arr 是捕获的变量, 每个 (arr, cb) 对应一个 f; 现在删了套子把 arr 放参数里了, 只有一个 f
// cb 就是需要这么多参数, 捕获可以减少参数但增加了闭包对象; f 需要这么多参数是因为 f 是从 cb 中硬拆出来的
// 补全并重排参数
function f(n, arr, cb) {
    var result = arr[n];
    if (typeof result !== 'number') {
        result = cb(n, arr, f);
        arr[n] = result;
    }
    return result;
}
function cbFib(n, arr, f) {
    return f(n - 1, arr, cbFib) + f(n - 2, arr, cbFib);
}
function cbFac(n, arr, f) {
    return n * f(n - 1, arr, cbFac);
}

var arrFib = [0, 1], arrFac = [1, 1];

console.log(
    f(20, arrFib, cbFib),
    f(10, arrFac, cbFac),
    f(13, arrFib, cbFib));
```

这就不妙了: cb 作为被频繁调用的递归函数现在多了两个没用的参数, 每次调用栈上就多放俩重复的参数,
随便调几次占用的空间就比 f 省下的那点多了.

看来, 如果非要把 1 个递归函数拆成 2 个递归函数, 为了共享变量, 还只能用 crockford 这种捕获变量的闭包.
前面问我写的话能写的更好吗? 答案是不能.

## 610guide 和 masm 的 bug

### 闪现

这些现象我观察到过, 目前无法重现, 我会留意它们

- 看到过宏参数也替换成和 local 变量一样的 ??00nn 名字
- 没给参数加尖括号时看到宏给参数前面加了 ! 符号
- 宏函数的参数不要求尖括号; 没有尖括号时,
    如果在找到某个参数后的逗号前先找到了空格, 则忽略后续逗号, 整个后续参数列表删除首尾空格, 作为一个参数.

### name TEXTEQU macroId?

> 610guide p???/p177<br>
name TEXTEQU macroId | textmacro<br>
macroId is a previously defined macro function, textmacro is a previously defined text macro

```
; name TEXTEQU macroId? 错误! textequ 右边只能放宏函数的调用结果即 macroId(), 不能放宏函数名
; 宏函数的调用结果是 text item, 宏函数不是. ml -Zs dd.msm

msg macro
    exitm <>
endm

; error A2051: text item required
string TEXTEQU msg
end
```

估计是笔误, 原意要么是 macroId 是文本宏名, 要么是 macroId().

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

问题在于 vararg 是多个参数删除第 1 层尖括号后加逗号合并成的 1 个参数, 换句话说用的时候就是错的.
具名参数去尖括号没啥问题, 还是能分给正确的参数; 合并之后就没法区分了.

### 宏函数作参数时的 bug

**bug1**: 宏函数 f 作参数, 后面有圆括号时, 会忽略 f 和 () 之间的字符调用 f().

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

mp 是宏函数时行为一样.
```

**bug2**: 宏函数 f 作参数, 后面没有圆括号时不发生调用, 但会把 f 后面的所有字符合成一个参数.

```
mp macro  a, b, c, d, e, f, g
    echo [mp] a
    echo [mp] b
    echo [mp] c
endm

mf macro a, b, c, d, e, f, g
    echo [mf] a
    echo [mf] b
    echo [mf] c
    exitm <>
endm

mp a,  mf , slkdjfoiu, 097-98yph&nj)
mp a, <mf>, slkdjfoiu, 097-98yph&nj)
echo
mf(a,  mf , slkdjfoiu, 097-98yph&nj)
mf(a, <mf>, slkdjfoiu, 097-98yph&nj)
echo
mf a, (mf , slkdjfoiu, 097-98yph&nj)
end

输出
[mp] a
[mp] mf , slkdjfoiu, 097-98yph&nj)
[mp]
[mp] a
[mp] mf
[mp] slkdjfoiu

[mf] a
[mf] mf , slkdjfoiu, 097-98yph&nj
[mf]
[mf] a
[mf] mf
[mf] slkdjfoiu

dd.msm(21): error A2048: nondigit in number
mf a, (mf , slkdjfoiu, 097-98yph&nj) 引发上述错误. todo: 调查它
```

### 预定义的字符串函数参数可以是文本宏?

> 610guide p???/p191<br>
Each string directive and predefined function acts on a string, which can be any
textItem. The textItem can be ... the name of a text macro, ...

```
; 610guide p???/p192, catstr, substr, @SizeStr 使用示例
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

上面的 SaveRegs 注释掉 push 用 -EP 编译可以看到 @SizeStr( regpushed ) 返回的是 9, 字符串 `regpushed` 的长度.
这种说得跟真的一样, 其实跟真的不一样的现象让我搞不清究竟是文档的 bug 还是 masm 的 bug. 仔细看的话发现
`regpushed SUBSTR regpushed, 1, @SizeStr( regpushed )` 这句话就跟开玩笑一样, 意义在哪? 暴露 bug?

### hoisting

js 有 hoisting, masm 也有 hoisting? masm 有, visual c++ 也有; 坏消息是, 它们皆是作为 bug 而存在.

```
f macro a
    x = a

    ifdef x
        echo x is defined
    else
        echo x is not defined
    endif
endm

f tt

tt = 3
end
```

`ml -Zs dd.msm` 输出
```
x is not defined
```

这个情况似乎就属于前面说过的 [masm 忽略错误](#masm-忽略错误); 可删掉 end 前的 tt = 3, `ml -Zs dd.msm` 输出
```
x is not defined
dd.msm(14): error A2006: undefined symbol : tt
 f(1): Macro Called From
  dd.msm(14): Main Line Code
```

显然 A2006 和 if 对 `defined` 有不同看法.

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





## to be deleted

to be deleted | 例子 | 解释
-|-|-
string |
|| args as `% arg` of... | catstr/exitm/macro-function/macro-procedure/textequ
|| args as `f(arg)`, `f(<arg>)` | [宏函数](#宏函数) f 把前述参数视为字符串
|| arguments of macro function
text macro || text macro 和 string 的区别是啥??? 字符串变量 ([文本宏](#文本宏))

- 合集: 热身运动, 💀 HBD & hold your breath
    - [拼接字符串](#拼接字符串)
    - [数组](#数组)


### 常见宏代码

- 确保已经安装了 masm, 在命令行输入 ml 回车以确认
- 在命令行 cd 到本项目目录, 比如 c:\code\masm. dosbox 无需此步骤
- 在此目录新建文件 dd.msm
- 把下面的代码粘贴到 dd.msm 里, 在命令行用 ml -Zs dd.msm 运行

*readme 里讲了 dosbox 的使用方法. 选项 -Zs 说只做语法检查*

**用关键词 echo, 在编译时输出文本**

```
echo hello world
end
```

**用关键词 echo, 在编译时输出使用宏定义的变量**

```
int1 = 3
str1 textequ <some text>
str2 textequ % int1

% echo int1 = str2, str-1 = str1
end
```

**循环, 函数调用, 在编译时输出计算后的值**

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
; it can accurately calculate up to 47 (2971215073)
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

**在编译时输出字符串长度**

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

用 `ml dd.msm` 生成 dd.exe, 然后 `dd` 运行它.

*当 masm 版本大于 6.11 时下面代码生成 windows 程序; 否则生成 dos 程序*

```
if @version le 611

start   textequ <abc>

xxx     segment stack
start:
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset s
        mov     ah, 9
        int     21h

        mov     ax, 4c00h
        int     21h

s       byte    "16 bit program compiled with masm 611-$", 16 dup (?)
xxx     ends

else

start   textequ <_main>

_TEXT   segment flat
start:

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
s       byte    "32 bit program compiled with masm > 611"
dwd     dword   ?
data    ends

endif
        end     start
```







### 目录

- [常见宏代码](#常见宏代码)
- 目录
- [预处理](#预处理)
    - [常量表达式](#常量表达式)
    - [变量](#变量)
    - [常见操作符](#常见操作符)
    - [分支](#分支)
    - [重复块](#重复块)
    - [输入输出](#输入输出)
        - [包含](#包含)
    - [展开](#展开)
    - [文本宏](#文本宏)
    - [宏过程](#宏过程)
    - [宏函数](#宏函数)
    - [参数](#参数)
    - [两种查找文本宏和宏函数的模式](#两种查找文本宏和宏函数的模式)
        - [模式 1](#模式-1)
        - [模式 2](#模式-2)
        - [示例: 宏名](#示例-宏名)
        - [撮合](#撮合)
        - [一些性质](#一些性质)
    - [用于处理字符串的指示和预定义函数](#用于处理字符串的指示和预定义函数)
    - [opattr, @cpu, pushcontext, popcontext](#opattr-cpu-pushcontext-popcontext)
    - [常见编译错误](#常见编译错误)
    - [调试?](#调试)
- [masm 和 c 的对比](#masm-和-c-的对比)
- [观察与思考](#观察与思考)
    - [退化](#退化)
    - [-EP 的错误输出? 执行结果正确](#-ep-的错误输出-执行结果正确)
    - [前序遍历, 以及 masm 令人着急的处理能力](#前序遍历-以及-masm-令人着急的处理能力)
    - [模式 2 不撮合](#模式-2-不撮合)
- [代码演示](#代码演示)
    - [返回函数名](#返回函数名)
    - [展开指定的次数](#展开指定的次数)
    - [展开本来不展开的文本宏](#展开本来不展开的文本宏)
    - [Douglas Crockford: Memoization](#douglas-crockford-memoization)
- [610guide 和 masm 的 bug](#610guide-和-masm-的-bug)
    - [闪现](#闪现)
    - [name TEXTEQU macroId?](#name-textequ-macroId)
    - [masm 忽略句子中自己看不懂的部分](#masm-忽略句子中自己看不懂的部分)
    - [masm 忽略错误](#masm-忽略错误)
    - [fatal error DX1020](#fatal-error-dx1020)
    - [vararg](#vararg)
    - [宏函数作参数时的 bug](#宏函数作参数时的-bug)
    - [预定义的字符串函数参数可以是文本宏?](#预定义的字符串函数参数可以是文本宏)
    - [hoisting](#hoisting)
- [早期代码](#早期代码)
    - [发现有 % 和无 % 的不同; 以及其它](#发现有--和无--的不同-以及其它)
    - [宏函数的各种失败展开](#宏函数的各种失败展开)
- [致谢](#致谢)






newArray macro arr, rest: vararg
    local prefix, c

    c textequ <0>

    for i, <rest>
        % prefix&&&c = i
        c textequ % c + 1
    endm

    arr macro i, val
        ifnb <val>
            prefix&&i = val
            exitm <>
        elseifdef prefix&&i
            exitm % prefix&&i
        else
            exitm <>
        endif
    endm
endm

memoizer macro memo, f
    local shell

    shell macro n
        local result

        result textequ memo(n)

        ifb result
            result textequ f(<shell>, n)
            memo(n, result)
        endif

        exitm result
    endm

    exitm <shell>
endm

newArray arrFib, 0, 1
newArray arrFac, 1, 1
cbFib macro shell, n
    exitm % shell(% n - 1) + shell(% n - 2)
endm
cbFac macro shell, n
    exitm % n * shell(% n - 1)
endm

fibonacci textequ memoizer(<arrFib>, <cbFib>)
factorial textequ memoizer(<arrFac>, <cbFac>)

ifdef n
    %% echo fibonacci (n) factorial (n)
else
    %% echo fibonacci(19) factorial(12)
endif
end











