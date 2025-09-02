
## 相关概念

`转义序列`用字符集里的字符序列代表字符集外的字符, 为此规定了一些字符作转义起始标记.

- 带长度信息的转义起始标记不需要结束标记
- 起始标记 = 结束标记: 引号
- 起始标记 ≠ 结束标记: 括号. 可以嵌套
- 多种起始标记, 一种结束标记: 可以嵌套
- 多种引号或括号: 可以嵌套和交叠

masm `宏`指`文本替换`. 由于经常是把较短的名字替换成较长的文本所以也叫`展开`. 这事在汇编之前做, 汇编之前还可能做其他事, 合起来叫`预处理`.

- `ml -Zs dd.msm`
    - -Zs 预处理, 语法检查, 不生成 obj
- `ml -Flout\ -Sa -Zs dd.msm`
    - -Fl 生成清单文件, -Sa 最详细清单. -Sf 清单加入第 1 遍的结果, 总共几遍?
- `ml -EP dd.msm`
    - -EP 输出预处理结果, 不生成 obj. 它的换行是 \n (10) 而不是 \r\n 所以在命令行显示不正常

不清楚 -Sa, -Sf, -EP 输出的都是啥, 只能看懂个大概.

## 形态

masm 的宏替换规则非常琐碎, bug 很多.

宏从源代码中提取 2 种数据类型, 整数和文本. 整数来自表达式文本, 表达式是整数和操作符的混合. 整数和文本都可以保存为宏替换阶段的变量, 宏替换只替换文本变量不替换整数变量, 文本变量替换出的文本如果包含文本变量就继续替换至不包含或达到规定的展开次数.

- 文本变量分行内文本和多行文本, 有不同的 masm 类型, 分别是 symbol/text, macro/proc, macro/func
- masm 的多行替换及多行注释作用于整行, 不能像 c++ 多行注释那样作用于开始行和结束行的一部分
- 整数和文本都不一定保存为变量, 比如字面量, 表达式字面量, 迭代块, 条件块
- 如果一个表达式里既有整数变量也有文本变量, 宏替换保留整数变量, 替换文本变量, 计算出结果. 这个细节不影响计算

一般的想法是给整数一个转义标记让它能从文本中区分出来, 但 masm 做的正相反: 它给文本一个特殊标记, 尖括号, 用来表示这里面是文本, 但好多时候又不需要用尖括号去表示文本. 尖括号里的各种转义也是左支右绌.

### echo

echo 别名 %out, 在宏替换阶段输出文本.

### 整数

- qh/assembly/directives/miscellaneous

两种定义方式:

- `name = expression` 定义或更改 name 的整数值
- `name EQU expression` 定义 name 的整数值, 不能更改用 = 和 equ 定义的整数

```
; ml -Zs dd.msm

n01 =   1
n01 equ 1

n01 =   2
n01 equ 2

n01 equ 1       ; symbol redefinition : n01
    end
```

```
; bug: 用 = 给 equ 定义的整数变量赋值导致 -Fl 影响 -Zs, 单独的 -Zs 错误地报错

n01 equ 1
n01 =   2
    end

ml -Zs dd.msm

dd.msm(3): error A2005: symbol redefinition : n01
dd.msm(2): error A2005: symbol redefinition : n01

ml -Flout\ -Sa -Zs dd.msm

dd.msm(3): error A2005: symbol redefinition : n01
```

#### 操作符

- qh/assembly/operators/macro

operator | ascii | https://docs.microsoft.com/en-us/cpp/assembler/masm/operators-reference
-|-|-
!   | 33 | 在尖括号里视下一字符为字面值, 在其他地方无特殊意义. 主要用来转义尖括号
%   | 37 | 行首时替换该行的文本宏和宏函数; 文本项里按当前 radix 对常量表达式求值后转为文本项
&   | 38 | substitution, 用于标记引号里的文本宏和宏函数
+-*/ mod | 43, 45, 42, 47 | 中缀操作符接受左右两个操作数; 加减乘除, 取余数
;   | 59 | 注释. 宏定义里的 ;; 不随宏替换至源码
<>  | 60, 62 | 文本项, 常用在参数里比如 `.err`, `option nokeyword: <xxx>`
[]  | 91, 93 | expr1[expr2] = expr1 + expr2
and, or, xor, shl, shr  || 位逻辑和按位左右移
not                     || not expr, 按位取反
eq, ne, ge, gt, le, lt  || equal, not equal, greater or equal, greater than, less or equal, less than. 返回 -1 代表 true, 0 代表 false

punctuation | ascii | msdn 不把这些叫 operator
-|-|-
()  | 40, 41 | 宏函数调用
=   | 61 | 定义整数变量, 可以反复赋值
\   | 92 | 行尾时续行

#### 表达式

多个地方会对表达式求值, 有 2 种时机, 定义整数变量时和用 % 计算并转为 text 时. 没找到明确的求值规则, 各个地方对表达式的定义稍有不同, 对求值失败的处理也不一样.

```
; 定义整数变量
; ml -Flout\ -Sa -Zs dd.msm

n01 =   (1 + 2)     ; Number    3
n02 =   [1 + 2]     ; Number    3
n03 =   1[2][3]     ; Number    6
n04 =   {1 + 2}     ; error A2009: syntax error in expression
n05 =   <1 + 2>     ; error A2009: syntax error in expression

n11 equ (1 + 2)     ; Number    3
n12 equ [1 + 2]     ; Number    3
n13 equ 1[2][3]     ; Number    6
n14 equ {1 + 2}     ; Text      {1 + 2}
n15 equ <1 + 2>     ; Text      1 + 2

    end
```

```
; 表达式求值时会执行宏替换
; ml -Flout\ -Sa -Zs dd.msm

a01 =   1                   ; Number    1
a02 equ <2>                 ; Text      2
a03 equ )                   ; Text      )

b01 =   (a01 + a02 a03      ; Number    3
b02 equ (a01 + a02 a03      ; Number    3
    end
```

masm 区分两种语法错误:

- error A2008: syntax error
- error A2009: syntax error in expression

#### = 的求值时机

= 右边有未知的变量名时无法求值, 此时不报错但该语句不定义变量, 在宏替换的一个较晚时刻再次执行此语句去定义变量, 如果还是无法求值才报错.

```
; ml -Flout\ -Sa -Zs dd.msm

defined macro arg
    ifdef arg
        echo arg is defined
    else
        echo arg is not defined
    endif
    endm

e01 =   e11 + 1         ; Number    0002h
e02 equ e11 + 1         ; Text      e11 + 1

    defined e01         ; e01 is not defined
    defined e02         ; e02 is defined

e11 = 1                 ; Number    0001h

    defined e11         ; e11 is defined

e03 =   e11 + 1         ; Number    0002h
e04 equ e11 + 1         ; Number    0002h

e05 =       t01 + 1     ; Number    0005h
t01 catstr  <4>         ; Text      4

    defined e05         ; e05 is not defined

e06 = t02               ; error A2006: undefined symbol : t02
    end
```

下面的示例表明:

- 立即执行 echo
- e01, e02 都无法求值, 不报错, ifdef 认为它们未定义, 宏替换结束仍无法求值才报错
- 第 1 个 e03 可以求值所以 ifdef 认为它定义了
- 第 2 个 e03 无法求值, 不报错, ifdef 认为它定义了, 可能是上一个 e03 还有效, 宏替换结束仍无法求值才报错
- 第 3 个 e03 立即报错. 我不知道为什么 ifdef 仍认为它定义了, 可能是成功的定义会一直生效
- t02 立即报错, 但文本变量在这种情况下仍会定义, 值是 0

```
defined macro arg
    ifdef arg
        echo arg is defined
    else
        echo arg is not defined
    endif
    endm

e01 = t01               ; line 10
    defined e01

e02 = 1.0               ; line 13
    defined e02

e03 = 1
    defined e03

e03 = 1.0               ; line 19
    defined e03

e03 = dx                ; line 22
    defined e03

t02 catstr  % e04       ; line 25
    defined t02
    end

ml -Zs dd.msm

e01 is not defined
e02 is not defined
e03 is defined
e03 is defined
dd.msm(22): error A2026: constant expected
e03 is defined
dd.msm(25): error A2006: undefined symbol : e04
t02 is defined
dd.msm(10): error A2006: undefined symbol : t01
dd.msm(13): error A2050: real or BCD number not allowed
dd.msm(19): error A2050: real or BCD number not allowed
```

### 行内文本

- qh/assembly/directives/miscellaneous

Text equates, 文本变量, 至多 255 个字符, 不能包含换行. 2 种方式定义或更改文本变量.

`name EQU text` text 不是 expression 时 equ 不视为错误并进入 [equ text](#equ-text) 模式去定义文本变量. 前面尝试对 text 求值时已经做了宏替换, 但在文本模式里它重新解析: 只要 text 不包含左尖括号就原样保留, bug 较少, 几近完美; 有左尖括号就各种 bug, 后面详述.

```
t01 textequ <5>
t0b equ     <>

t0a equ     t01
t0b equ     t01
    end

out\dd.lst by ml -Flout\ -Sa -Zs dd.msm

Symbols:
                N a m e             Type        Value   Attr

t01  . . . . . . . . . . . . . .    Text        5
t0a  . . . . . . . . . . . . . .    Number      0005h
t0b  . . . . . . . . . . . . . .    Text        t01
```

尖括号里分号是一般字符:

```
; ml -Flout\ -Sa -Zs dd.msm

e01 equ  ab;c           ; Text  ab
e02 equ <ab;c>          ; Text  ab;c
    end
```

`name textequ text-item, text-item, ...` text item is:

- any string of characters enclosed in angle brackets (<>)
- an expression preceded by the expression operator (%)
- symbol/text or macro/func call

```
; bug: text-item 是 text 时试图解释后面的尖括号而不是报告 text item required
; ml -Zs dd.msm

t01 textequ <a> b       ; error A2051: text item required
t02 textequ <a> b<      ; error A2045: missing angle bracket or brace in literal
t03 textequ <a> b>      ; error A2008: syntax error : >
t04 textequ <a> b<>     ; error A2051: text item required
t05 textequ <a> <       ; error A2045: missing angle bracket or brace in literal
t06 textequ <a> >       ; error A2008: syntax error : >
t07 textequ <a> <>      ; error A2051: text item required

e01 equ     <a> b       ; error A2008: syntax error : b
e02 equ     <a> b<      ; error A2045: missing angle bracket or brace in literal
e03 equ     <a> b>      ; error A2008: syntax error : b
e04 equ     <a> b<>     ; error A2008: syntax error : b
e05 equ     <a> <       ; error A2045: missing angle bracket or brace in literal
e06 equ     <a> >       ; error A2008: syntax error : >
e07 equ     <a> <>      ; error A2008: syntax error
    end
```

text-item 是 symbol/text 时会一直替换到没有 symbol/text 或 macro/func call, 除非看到引号; 是 macro/func call 时不继续替换返回值里的文本宏:

```
; ml -Flout\ -Sa -Zs dd.msm

t01 textequ <ab1>               ; ab1
t03 textequ <ab3>               ; ab3
t11 textequ <-t01-t02-t03->     ; -t01-t02-t03-

t12 textequ t11                 ; -ab1-t02-ab3-
t02 textequ <ab2>               ; ab2
t13 textequ t11                 ; -ab1-ab2-ab3-

t21 textequ <#t01 ' t02-t03->   ; #t01 ' t02-t03-
t22 textequ t21                 ; #ab1 ' t02-t03-

f01 macro
    exitm <-t01-t02-t03->
    endm

f02 macro
    exitm t11
    endm

t31 textequ t11, f01(), f02()   ; -ab1-ab2-ab3--t01-t02-t03--ab1-ab2-ab3-
t32 textequ <f01()>
t33 textequ t32, f01()          ; -ab1-ab2-ab3--t01-t02-t03-
    end
```

```
; bug: text-item 是行内文本宏时忽略其后的 token
; affects: textequ, catstr, .erre, .errnz, maybe more
; ml -Flout\ -Sa -Zs dd.msm

t01 textequ <a>             ; Text      a
t02 textequ <b>             ; Text      b

t03 textequ <c> t01 t02     ; error A2051: text item required
t04 textequ t01 <c> t02     ; Text      a
    end
```

示例:

```
; ml -Flout\ -Sa -Zs dd.msm

e01 equ       1 + 1                 ; Number    0002h
t01 textequ  <1 + 1>                ; Text      1 + 1
t02 textequ % 1 + 1                 ; Text      2

e02 equ     t01                     ; Number    0002h
t03 textequ t01                     ; Text      1 + 1

e03 equ      sometext               ; Text      sometext
e04 equ     <sometext>              ; Text      sometext
t04 textequ <sometext>              ; Text      sometext

e05 equ     % e01, <t01>, e03, t03  ; Text      % e01, <t01>, e03, t03
t05 textequ % e01, <t01>, e03, t03  ; Text      2t01sometext1 + 1

e06 equ     % 1 + 1, t02            ; Text      % 1 + 1, t02
t06 textequ % 1 + 1, t02            ; Text      22

e07 equ     t02   6, t02            ; Text      t02   6, t02
t07 textequ t02   6, t02            ; Text      22

e08 equ     6   t02, t02            ; Text      6   t02, t02
t08 textequ 6   t02, t02            ; error A2051: text item required
    end
```

替换时只查找已知的宏, .erre, .errnz, ... 在宏替换阶段的后期求值所以能看到后面定义的变量.

```
    .erre   n00, t01
    .erre   n01, t01
    .errnz  n00, t01
    .errnz  n01, t01

%   echo    t01

n00 =       0
n01 =       1
t01 textequ <random text>

%   echo    t01
    end

ml -Zs dd.msm

t01
random text
dd.msm(2): error A2053: forced error : value equal to 0 : 0: random text
dd.msm(5): error A2054: forced error : value not equal to 0 : 1: random text
```

textequ 的别名是 `catstr`, 和另外 3 个 directives 算一组, 分别是 `instr`, `sizestr`, `substr`; 这 4 个又分别对应预定义的 macro functions: `@catstr`, `@instr`, `@sizestr`, `@substr`. directive 和 macro function 的用法稍微不同:

- 指示是关键字, 不区分大小写; 宏函数是名字, `option casemap` 或 `-C[p|u|x]` 时必须匹配大小写
- instr 的第一个参数是可选参数, 若要省略此参数, 指示是不写, 宏函数是空逗号
- @instr, @sizestr 是宏函数, 必然返回文本
- string 下标从 1 开始

```
a01 catstr <ab>, % 34
   @catstr(a02 catstr , !<, ab, % 34, ???, !>)

b01     instr   3, <abcdabc>, <abc>
b02 =  @instr  (3, <abcdabc>, <abc>)
b03     instr      <abcdabc>, <abc>
b04 =  @instr   (, <abcdabc>, <abc>)

c01     sizestr <abcdefg>
c02 =  @sizestr(<abcdefg>)

d01         substr <abcdefg>, 3, 2
d02 catstr @substr(<abcdefg>, 3)

e01 equ     abcdabc
e02 instr   1, e01, <da>
    end

out\dd.lst by ml -Flout\ -Sa -Zs dd.msm

Symbols:
                N a m e             Type        Value   Attr

a01  . . . . . . . . . . . . . .    Text        ab34
a02  . . . . . . . . . . . . . .    Text        ab34???
b01  . . . . . . . . . . . . . .    Number      0005h
b02  . . . . . . . . . . . . . .    Number      0005h
b03  . . . . . . . . . . . . . .    Number      0001h
b04  . . . . . . . . . . . . . .    Number      0001h
c01  . . . . . . . . . . . . . .    Number      0007h
c02  . . . . . . . . . . . . . .    Number      0007h
d01  . . . . . . . . . . . . . .    Text        cd
d02  . . . . . . . . . . . . . .    Text        cdefg
e01  . . . . . . . . . . . . . .    Text        abcdabc
e02  . . . . . . . . . . . . . .    Number      0004h
```

instr 的参数和 catstr 一样是 text-item, 而 @instr 的参数和其他宏函数一样是一般参数.

```
; ml -Flout\ -Sa -Zs dd.msm

t01 catstr  < a !! b >          ; Text       a ! b

n01 instr          t01, <!!>    ; Number    4
n02 instr        % t01, <!!>    ; error A2008: syntax error : !
n03 instr   < a !! b >, <!!>    ; Number    4

n04 =   @instr(1,        t01, <!!>)     ; Number    0
n05 =   @instr(1,      % t01, <!!>)     ; Number    4
n06 =   @instr(1, < a !! b >, <!!>)     ; Number    4
    end
```

#### equ text

equ 把 text 当作 expression 求值失败后会把它当作一般的 text. 按说这很简单, 找换行就行了, 但 equ 非要把尖括号扯进来, 引出了一系列的问题. 实验表明 equ 根据 text 第一个字符是否是左尖括号执行两个分支:

- 分支 1, text 不以左尖括号打头
- 分支 2, text 以左尖括号打头

分支 1 bug 较少, 不改动 text.

```
; bug: equ 不要求尖括号, 不使用尖括号时文本要接受语法检查
; ml -Zs dd.msm

e01 equ value is this   ; error A2034: must be in segment block
e02 equ #               ; error A2044: invalid character in file
    end
```

分支 1 莫名其妙地要求尖括号配对儿. 由于此时 text 是原样文本没有转义的概念, 左尖括号就是左尖括号, 所以类似 `e01 equ a < b` 的语句必然被报错.

```
; bug: text 不以左尖括号打头时要求引号, 尖括号匹配
; ml -Zs dd.msm

e01 equ a'b     ; error A2046: missing single or double quotation mark in string
e02 equ a"b     ; error A2046: missing single or double quotation mark in string
e03 equ a<b     ; error A2045: missing angle bracket or brace in literal
    end
```

```
; bug: text 不以左尖括号打头时仍然认识尖括号里的转义字符 ! 但求值时正确地不解释它

e01 equ    <a!b>
e02 equ     a<b>
e03 equ     a<b         ; error A2045: missing angle bracket or brace in literal
e04 equ     a<b!>       ; error A2045: missing angle bracket or brace in literal
e05 equ     a!b
e06 equ     a!b<a!b>
    end

out\dd.lst by ml -Flout\ -Sa -Zs dd.msm

Symbols:
                N a m e             Type        Value   Attr

e01  . . . . . . . . . . . . . .    Text        ab
e02  . . . . . . . . . . . . . .    Text        a<b>
e03  . . . . . . . . . . . . . .    Text        a<b
e04  . . . . . . . . . . . . . .    Text        a<b!>
e05  . . . . . . . . . . . . . .    Text        a!b
e06  . . . . . . . . . . . . . .    Text        a!b<a!b>
```

分支 2 bug 较多, 改动 text. 实验表明其行为是:

- 2.1. 检查 text 周围的尖括号
    - 2.1.1. 缺少右尖括号. 吃掉下一行, 不递增行号; 下一行是空白时转到 2.2, 否则报告语法错误
    - 2.1.2. 完整的括号对儿之后还有文本. 报错
    - 2.1.3. 完整的括号对儿. 转到 2.2
- 2.2. 对 text 转义得到 escaped1, 检查其周围的尖括号
    - 2.2.1. 缺少右尖括号. 变量名 -> 变量值, 报告括号不匹配
    - 2.2.2. 完整的括号对儿之后还有文本. 丢弃这些文本, 转到 2.3
    - 2.2.3. 完整的括号对儿. 转到 2.3
- 2.3. 对 escaped1 转义得到 escaped2, 尖括号里的内容赋值给变量

```
; 2.1.1. text 以左尖括号打头, 没找到匹配的右尖括号
; bug: 不递增行号, 对下一行的任何非空白 token 报错, 是空白则可能错误地赋值

e01 equ <       ; line  4
    echo

e02 equ <       ; line  7
    end

e03 equ <       ; line 10
>

e04 equ <       ; line 13
; whitespace

e05 =   @line   ; line 16
    end

ml -Flout\ -Sa -Zs dd.msm

dd.msm(4): error A2008: syntax error : echo
dd.msm(6): error A2008: syntax error : end
dd.msm(8): error A2008: syntax error : >
dd.msm(10): error A2045: missing angle bracket or brace in literal

(out\dd.lst)

Symbols:
                N a m e             Type        Value   Attr

e04  . . . . . . . . . . . . . .    Text        e04
e05  . . . . . . . . . . . . . .    Number      000Ch
```

```
; 2.1.1. text 以左尖括号打头, 没找到匹配的右尖括号, 下一行是 invalid character 即 #^`~
; bug: 编造行号一直到报错 100 个后停止

e01 equ <
~
    end ; 写不写 end 都一样

ml -Zs dd.msm

...
dd.msm(51): error A2044: invalid character in file
dd.msm(51): error A2039: line too long
dd.msm(52): error A2044: invalid character in file
dd.msm(52): fatal error A1012: error count exceeds 100; stopping assembly
```

用续行符把 text 放到下一行时 2.1.1 不会从下一行的下一行找右尖括号:

```
e01 equ <
    end

e02 equ\
<
    end

ml -Flout\ -Sa -Zs dd.msm

dd.msm(2): error A2008: syntax error : end
dd.msm(4): error A2045: missing angle bracket or brace in literal

(out\dd.lst)

Symbols:
                N a m e             Type        Value   Attr

e02  . . . . . . . . . . . . . .    Text        e02
```

```
; 2.1.1. text 缺少右尖括号, 下一行是空白
; 2.2.1. escaped1 缺少右尖括号
; bug: 吃掉下一行, 变量名 -> 变量值, 报告括号不匹配

e01 equ <

e02 equ <<>

    end

ml -Flout\ -Sa -Zs dd.msm

dd.msm(7): error A2045: missing angle bracket or brace in literal
dd.msm(8): error A2045: missing angle bracket or brace in literal

(out\dd.lst)

Symbols:
                N a m e             Type        Value   Attr

e01  . . . . . . . . . . . . . .    Text        e01
e02  . . . . . . . . . . . . . .    Text        e02
```

```
; 2.1.1. text 缺少右尖括号, 下一行是空白
; 2.2.2. escaped1 是完整的括号对儿后跟文本
; 2.3. 对 escaped1 尖括号里的内容转义得到 escaped2, 赋值给变量
; bug: 丢弃 2.2.2 的后续文本而不报错

e01 equ <a!>b

e02 equ <a!><b>

e03 equ <a<!>!>b>

e04 equ <<a!>!>b>

e05 equ <<a!>!!!!!>b>

    end

out\dd.lst by ml -Flout\ -Sa -Zs dd.msm

Symbols:
                N a m e             Type        Value   Attr

e01  . . . . . . . . . . . . . .    Text        a
e02  . . . . . . . . . . . . . .    Text        a
e03  . . . . . . . . . . . . . .    Text        a<>
e04  . . . . . . . . . . . . . .    Text        <a>
e05  . . . . . . . . . . . . . .    Text        <a>!
```

分支 2 匹配外层尖括号后对余下的部分报错, 这时仍不忘匹配尖括号只是不会从下一行找:

```
; 2.1.2. text 以左尖括号打头, 匹配右尖括号后仍有文本
; bug: 错误的报告遇到的错误 (% -> !%)
; affects: equ, for
; ml -Zs dd.msm

e01 equ <a> b       ; error A2008: syntax error : b
e01 equ <a> %       ; error A2008: syntax error : !%

for i,  <arg1> %    ; error A2008: syntax error : !%

e02 equ <a> <       ; error A2045: missing angle bracket or brace in literal
    end
```

```
; 2.1.3. text 是完整的括号对儿
; 2.2.1. escaped1 缺少右尖括号
; bug: 变量名 -> 变量值, 报告括号不匹配

e01 equ <!<>
    end

ml -Flout\ -Sa -Zs dd.msm

dd.msm(6): error A2045: missing angle bracket or brace in literal

(out\dd.lst)

Symbols:
                N a m e             Type        Value   Attr

e01  . . . . . . . . . . . . . .    Text        e01
```

```
; 2.1.3. text 是完整的括号对儿
; 2.2.2. escaped1 完整的括号对儿之后还有文本
; 2.3. 对 escaped1 尖括号里的内容转义得到 escaped2, 赋值给变量
; bug: 丢弃 2.2.2 的后续文本而不报错

e01 equ <a!>b>
    end

out\dd.lst by ml -Flout\ -Sa -Zs dd.msm

Symbols:
                N a m e             Type        Value   Attr

e01  . . . . . . . . . . . . . .    Text        a
```

本节做了很多实验才确定 equ 文本模式的行为, 下面是其中的一些.

实验: 分支 1 不改动 text, 分支 2 丢弃尖括号后的内容.

```
; ml -Flout\ -Sa -Zs dd.msm

e01 equ f<a!> b>            ; f<a!> b>
e01 equ f<a!>!> b>          ; f<a!>!> b>
e01 equ f<a!>!>!> b>        ; f<a!>!>!> b>

e02 equ f<<a>!> b>          ; f<<a>!> b>
e02 equ f<<a>!>!> b>        ; f<<a>!>!> b>
e02 equ f<<a>!>!>!> b>      ; f<<a>!>!>!> b>

e11 equ <a!> b>             ; a
e11 equ <a!>!> b>           ; a
e11 equ <a!>!>!> b>         ; a

e12 equ <<a>!> b>           ; <a>
e12 equ <<a>!>!> b>         ; <a>
e12 equ <<a>!>!>!> b>       ; <a>
    end
```

实验: 分支 1 和分支 2 遇到不配对儿的尖括号时有不同的 bug. 分支 1 错误地报错但赋值正确; 分支 2 有时能正确地报错但仍然给变量赋值并且不递增行号:

```
; bug review

e01 equ a<b
e02 equ <b

e03 =   @line   ; line 5
    end

ml -Flout\ -Sa -Zs dd.msm

dd.msm(2): error A2045: missing angle bracket or brace in literal
dd.msm(3): error A2045: missing angle bracket or brace in literal

(out\dd.lst)

Symbols:
                N a m e             Type        Value   Attr

e01  . . . . . . . . . . . . . .    Text        a<b
e02  . . . . . . . . . . . . . .    Text        e02
e03  . . . . . . . . . . . . . .    Number      0004h
```

实验: textequ 和 equ 对 text 执行不同的代码.

```
; ml -Flout\ -Sa -Zs dd.msm

t01 textequ <a!> b>     ; Text  a> b
t01 textequ <a!>> b>    ; syntax error : >
t01 textequ <a!>>> b    ; syntax error : >

e01 equ     <a!> b>     ; Text  a
e01 equ     <a!>> b>    ; syntax error : b
e01 equ     <a!>>> b    ; syntax error : >

t01 textequ <a!!!> b>   ; Text  a!> b
e01 equ     <a!!!> b>   ; Text  a> b
    end
```

实验: 分支 2 尖括号里的 text 转义 2 次, 探究此情况.

- 有
    ```
    ; affects: equ, for
    ; ml -Flout\ -Sa -Zs dd.msm

    ;                      string escape 1      escape 2    result (error may occur earlier)
    e00 equ <a> b>              ; a> b          a> b        error A2008: syntax error : b
    e01 equ <a!> b>             ; a> b          a> b        a
    e02 equ <a!!> b>            ; a!> b         a> b        error A2008: syntax error : b
    e03 equ <a!!!> b>           ; a!> b         a> b        a> b
    e04 equ <a!!!!> b>          ; a!!> b        a!> b       error A2008: syntax error : b
    e05 equ <a!!!!!> b>         ; a!!> b        a!> b       a!
    e06 equ <a!!!!!!> b>        ; a!!!> b       a!> b       error A2008: syntax error : b
    e07 equ <a!!!!!!!> b>       ; a!!!> b       a!> b       a!> b
    e08 equ <a!!!!!!!!> b>      ; a!!!!> b      a!!> b      error A2008: syntax error : b
    e09 equ <a!!!!!!!!!> b>     ; a!!!!> b      a!!> b      a!!
    e10 equ <a!!!!!!!!!!> b>    ; a!!!!!> b     a!!> b      error A2008: syntax error : b
    e11 equ <a!!!!!!!!!!!> b>   ; a!!!!!> b     a!!> b      a!!> b
        end
    ```
- 转义前每行都不同, 感叹号每行 +1; 转义后每 2 行相同, 感叹号每 2 行 +1; 2 次转义后每 4 行相同, 感叹号每 4 行 +1. 每隔一行都报 A2008 显然这错误是针对转义前, 否则 escape 1, escape 2 相同的 text 不会有的报错有的不报. 删除报错的行得到
    ```
                        string escape 1    escape 2    result
    e01 equ <a!> b>             a> b        a> b        a
    e03 equ <a!!!> b>           a!> b       a> b        a> b
    e05 equ <a!!!!!> b>         a!!> b      a!> b       a!
    e07 equ <a!!!!!!!> b>       a!!!> b     a!> b       a!> b
    e09 equ <a!!!!!!!!!> b>     a!!!!> b    a!!> b      a!!
    e11 equ <a!!!!!!!!!!!> b>   a!!!!!> b   a!!> b      a!!> b
    ```
- 可以看到 escape 2 和 result 不同, 所以从 escape 1 得到 result 时还做了 escape 之外的事儿. 给 escape 1 加上尖括号, 删除 escape 2, 得到
    ```
                        string escape 1    <escape 1>      result
    e01 equ <a!> b>             a> b        <a> b>          a
    e03 equ <a!!!> b>           a!> b       <a!> b>         a> b
    e05 equ <a!!!!!> b>         a!!> b      <a!!> b>        a!
    e07 equ <a!!!!!!!> b>       a!!!> b     <a!!!> b>       a!> b
    e09 equ <a!!!!!!!!!> b>     a!!!!> b    <a!!!!> b>      a!!
    e11 equ <a!!!!!!!!!!!> b>   a!!!!!> b   <a!!!!!> b>     a!!> b
    ```
- 所以, 从 escape 1 到 result 的过程应该是: 套一层尖括号, 找匹配第 1 个左尖括号的未转义右尖括号, 取其中的内容给 result, 丢弃其余. 为验证此思路下面从 e03 构造一个 text 让 result 丢弃 escape 1 的后面部分. 为了能通过一开始的尖括号匹配需要转义 b 后面的 >
    ```
    ; ml -Flout\ -Sa -Zs dd.msm

    ;                      string <escape 1>    matching >  result
    e03 equ <a!!!> b>           ; <a!> b>       <a!> b>     a> b
    e13 equ <a!!!> b!> c>       ; <a!> b> c>    <a!> b>     a> b
        end
    ```

```
; random test 1

e01 equ <<a b>

e02 equ <a> b>

e03 equ <!<a b>
    echo

e04 equ <a!> b>

e05 equ <!!<a b>

e06 equ <a!!> b>

    end
```

```
; random test 2

e01 equ <<a> b>
e02 equ <<a!> b>

e03 equ <<<a!>!> b>

e04 equ <<a!!> b>

e05 equ <<a!!!> b>

e06 equ <<a!!!!> b>

    end
```

### 多行文本

#### 条件块

- qh/assembly/directives/conditional assembly

|||||
-|-|-|-
if      | elseif        | expression                | 如果 expression 不等于 0
ife     | elseife       | expression                | 如果 expression 等于 0
ifb     | elseifb       | text-item                 | 如果 text-item 空
ifnb    | elseifnb      | text-item                 | 如果 text-item 不空
ifdef   | elseifdef     | tag                       | 如果定义了变量 tag
ifndef  | elseifndef    | tag                       | 如果没有定义变量 tag
ifidn   | elseifidn     | text-item-1, text-item-2  | 如果 text-item-1 和 text-item-2 的值相同
ifidni  | elseifidni    | text-item-1, text-item-2  | 如果 text-item-1 和 text-item-2 的值相同, 忽略大小写
ifdif   | elseifdif     | text-item-1, text-item-2  | 如果 text-item-1 和 text-item-2 的值不同
ifdifi  | elseifdifi    | text-item-1, text-item-2  | 如果 text-item-1 和 text-item-2 的值不同, 忽略大小写
else
endif

```
n01 =       4
n02 =       0
t01 catstr  <abc>
t02 catstr  <4 + 1>
t03 catstr  % n01 + 1

    if n02
        echo n02 != 0
    elseife n01
        echo n02 != 0 && n01 == 0
    elseif t02 gt n01
        echo `gt` casts condition to integer then eval, t02 > n01
    endif

    ifb t01
        echo t01 is blank
    elseifdif t01, t02
        echo content of t01 differs from t02
    else
        echo this is else statement
    endif

    ifidni t02, t03
        echo not likely
    elseif t02 eq t03
        echo `ifidni` thinks t02 and t03 are different, but `eq` thinks they equal
    endif
    end

ml -Zs dd.msm

`gt` casts condition to integer then eval, t02 > n01
content of t01 differs from t02
`ifidni` thinks t02 and t03 are different, but `eq` thinks they equal
```

#### 迭代块

- qh/assembly/directives/macros and iterative blocks

用 endm 结束的块都可以用 exitm 提前退出.

repeat, rept. 迭代前查看 1 次 expression, 把指定的语句就地重复那么多次.

```
repeat expression
    statements
endm
```

```
factorial2cnt = 6
factorial2amt = 1

repeat factorial2cnt
    factorial2amt = factorial2amt * factorial2cnt
    factorial2cnt = factorial2cnt - 1
endm

factorial2str catstr % factorial2amt
%   echo factorial2 factorial2str
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

factorial2str catstr % factorial2amt
   echo factorial2 720
    end
```

while, 每次迭代前都查看 expression, 不为 0 时才迭代, 否则结束.

```
while expression
    statements
endm
```

```
cnt = 6
amt = 1

    while   cnt
amt = amt * cnt
cnt = cnt - 1
    endm

stg catstr  % amt
%   echo    factorial stg
    end

ml -EP dd.msm

cnt = 6
amt = 1

amt = amt * cnt
cnt = cnt - 1
amt = amt * cnt
cnt = cnt - 1
amt = amt * cnt
cnt = cnt - 1
amt = amt * cnt
cnt = cnt - 1
amt = amt * cnt
cnt = cnt - 1
amt = amt * cnt
cnt = cnt - 1

stg catstr  % amt
   echo    factorial 720
    end
```

```
; bug: while 不读取在它里面修改的文本变量
; ml -Zs dd.msm

n01 = 10

while n01
    n01 = n01 - 1
endm

t01 catstr  % n01
%   echo    t01                 ; 0

t01 catstr  <10>

while t01
    ife t01
        % echo t01, exiting     ; 0, exiting
        exitm
    endif

    t01 catstr % t01 - 1
endm

    end
```

```
; 610guide p???/p188

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

ml -EP dd.msm

xxx segment
cubes   LABEL   BYTE            ;; Name the data generated
root    = 1                     ;; Initialize root
cube    = root * root * root    ;; Calculate first cube
    WORD    cube
    root    = root + 1
    cube    = root * root * root
    ...
    WORD    cube
    root    = root + 1
    cube    = root * root * root
xxx ends
    end
```

for, irp. Repeats macro for each parameter given. for 的第 2 个参数需要尖括号, 把第 2 个参数看成以逗号分隔的参数列表, 遍历此列表.

```
for i, <arg1, arg2, ...>
    statements
endm
```

```
t01 catstr  <arg1, 1 + 1, % 1 + 1, ax, '33'>
t02 catstr  <arg1>, <1 + 1>, % 1 + 1, <ax>, <'33'>
t03 catstr  <>

    for i,  <arg1, 1 + 1, % 1 + 1, ax, '33'>
t03 catstr  t03, <i>
    endm

%   echo    t01
%   echo    t02
%   echo    t03
    end

ml -Zs dd.msm

arg1, 1 + 1, % 1 + 1, ax, '33'
arg11 + 12ax'33'
arg11 + 12ax'33'
```

for 的第 1 个参数可以应用 2 个修饰之一:

```
; for i: req , <text>   每个 i 都不能是空文本否则报错
; for i: =<c>, <text>   每个 i 如果是空文本则 = c

for i: req , <a,, c>
    echo i
endm
for i: =<c>, < ,, >
    echo i
endm
end

ml -EP dd.msm

    echo a
dd.msm(7): error A2125: missing macro argument
 MacroLoop(1): iteration 2: Macro Called From
  dd.msm(7): Main Line Code
    echo
    echo c

    echo c
    echo c
    echo c
end
```

`for arg1, <arg2>` 对 arg2 的处理见后面的 [参数](#行内文本---参数) 部分.

```
; 转义后按逗号拆开

for i, <1, 2>
    echo i
endm

for i, <1!, 2>
    echo i
endm

for i, <1!, !>2>
    echo i
endm

for i, <1!!, 2!!>
    echo i
endm

for i, <1!!, 2!!!!>
    echo i
endm
end

ml -EP dd.msm

    echo 1
    echo 2

    echo 1
    echo 2

    echo 1
dd.msm(13): warning A4010: expected '>' on text literal
 MacroLoop(2): iteration 1: Macro Called From
  dd.msm(13): Main Line Code
    echo >2

dd.msm(17): error A2038: missing operand for macro operator
 MacroLoop(1): iteration 0: Macro Called From
  dd.msm(17): Main Line Code
    echo 1, 2!


    echo 1, 2!
end
```

- qh/macro assembler/ml error messages/a2xxx macro assembler nonfatal errors/a2038
    > MASM error A2038<br>
    missing operand for macro operator<br>
    The assembler found the end of a macro's parameter list immediately after the ! or % operator.

```
; bug: for 的第 2 个参数丢失分号

for i, <;>
    echo i, <i>, <<i>>, "i"
endm
end

ml -EP dd.msm

    echo , <>, <<>>, "i"
end
```

```
; bug: for 的第 2 个参数要求引号匹配

for i, <'>
endm
for i, <">
endm
end

ml -EP dd.msm

dd.msm(3): error A2046: missing single or double quotation mark in string
 MacroLoop(1): iteration 0: Macro Called From
  dd.msm(3): Main Line Code

dd.msm(5): error A2046: missing single or double quotation mark in string
 MacroLoop(1): iteration 0: Macro Called From
  dd.msm(5): Main Line Code

end
```

forc, irpc. Repeats macro for each character given. forc 的第 2 个参数不需要尖括号, 遍历第 2 个参数的每个字符. 第 2 个参数以左尖括号打头时需要匹配括号并且不能后跟文本否则 error A2003: extra characters after statement; 否则使用第一个空白前的文本, 忽略后面.

```
forc i, text
    statements
endm
```

```
; ml -Zs dd.msm

t01 catstr  <>
t02 catstr  <>

    forc    i, a,2 c, d
t01 catstr  t01, <i>
    endm

    forc    i, <a,2 c, d>
t02 catstr  t02, <i>
    endm

%   echo    t01         ; a,2
%   echo    t02         ; a,2 c, d
    end
```

#### 宏过程

- qh/assembly/directives/macros and iterative blocks

定义宏过程 macro proc 之后, masm 把后续 `tag arg1, arg2, ...` 这样的一整行替换为 `statements`.

```
tag macro arg1, arg2, ...
    locals
    statements
    endm
```

宏过程的参数列表和 for 的参数 2 很像, 不同点是没有外层尖括号所以少一次转义:

```
e01 =       1
t01 catstr  <t01str>

m01 macro   arg1, arg2, arg3, arg4, arg5
    echo    arg1
    echo    arg2
    echo    arg3
    echo    arg4
    echo    arg5
    endm

    m01     % 1 + e01, e01 % e01, a !!% 1 + 1, b % b + 1, t01
    for i, <% 1 + e01, e01 % e01, a !!% 1 + 1, b % b + 1, t01>
    echo    i
    endm
    end

ml -EP dd.msm

dd.msm(12): error A2006: undefined symbol : b
 m01(1): Macro Called From
  dd.msm(12): Main Line Code
    echo    2
    echo    e01 1
    echo    a !2
    echo    b 0
    echo    t01

    echo    2
    echo    e01 1
    echo    a % 1 + 1
dd.msm(15): error A2006: undefined symbol : b
 MacroLoop(2): iteration 3: Macro Called From
  dd.msm(15): Main Line Code
    echo    b 0
    echo    t01
```

宏过程的参数可以应用 3 个修饰之一:

- `arg: req`    arg 不能是空串否则报错
- `arg: =<x>`   arg 如果是空串则 arg = x
- `arg: vararg` arg 保存从 arg 开始往后的所有参数, 以逗号隔开; 只能是参数列表里最后一个参数

req 和 =default-text 和在 for 里一样, 这里说 vararg.

- qh/assembly/directives/macros and iterative blocks/macro/using vararg in macros

vararg 必须是参数列表的最后 1 个参数, 把收到的所有参数用逗号连起来. 由于宏过程的参数都转义了 1 次所以 vararg 不是原始参数列表. 宏过程里用 for 去遍历 vararg.

```
; ml -Zs dd.msm

m01 macro args: vararg
    echo args
    endm

    m01     1, <2, 3>, 4
    end

expect:     1,<2, 3>,4
actual:     1,2, 3,4
```

local 如果出现必须是宏的第一句话, 让 masm 生成不重复的全局名字. 下面这些变量可以是 local:

- numeric equation
- symbol/text
- code label

```
; local. 未实现的阶乘

factorial1  macro n: =<3>
    local   x
x   catstr % n * (n - 1)    ;; 这里需要 n 个项, 或者计算 n 次
%   echo    factorial1 x
    endm

    factorial1
    end

ml -EP dd.msm

??0000   catstr % 3 * (3 - 1)
   echo    factorial1 6
    end
```

可以看到宏过程 factorial1 在使用处展开, 一行 `factorial1` 替换成了两行 `??0000 catstr % 3 * (3 - 1)` 和 `echo factorial1 6`.

```
; 使用宏过程和迭代块计算阶乘
;
; ml -Zs dd.msm

factorial2 macro n: =<6>
    local amt, cnt, str

    amt = 1
    cnt = n

    repeat cnt
        amt = amt * cnt
        cnt = cnt - 1
    endm

    str catstr % amt
    % echo factorial2 str
    endm

    factorial2          ; factorial2 720
    factorial2 13       ; wrong answer 1932053504, should be 6227020800
;   factorial2 "abc"    ; (after a while) fatal error A1004: out of memory
    end
```

### 宏函数

宏函数在使用处的前一行展开为多行文本, 执行, 然后用 exitm 后面的行内文本替换宏函数调用. 宏函数的 2 个要素:

- 定义时需要 exitm text-item
    - % exitm text-item 得到宏过程而非宏函数
    - exitm 后面的 text-item 是尖括号里的文本时不执行 ! 转义
- 使用时需要圆括号

```
tag macro arg1, arg2, ...
    locals
    statements
    exitm text-item
    endm
```

```
; ml -Zs dd.msm

t01 catstr  <1>

f01 macro
    t01 catstr <2>
    exitm <3>
    endm

%   echo    t01 f01() t01       ; 1 3 2
    end
```

```
; bug: if 0 里 exitm text-item 创建的宏函数, 用来给文本变量赋值时失败但不报错, 给整数变量赋值时报错

f01 macro
    exitm <1>
    endm

f02 macro
    if 0
        exitm <>
    endif
    endm

n01 =       f01()
t01 catstr  f01()
n02 =       f02()   ; error A2008: syntax error : in directive
t02 catstr  f02()
    end

out\dd.lst by ml -Flout\ -Sa -Zs dd.msm

Macros:
                N a m e             Type

f01  . . . . . . . . . . . . . .    Func
f02  . . . . . . . . . . . . . .    Func

Symbols:
                N a m e             Type        Value   Attr

n01  . . . . . . . . . . . . . .    Number      0001h
t01  . . . . . . . . . . . . . .    Text        1
```

### 行内文本 - 参数

调用 for, macro proc, macro func 时会传递参数. for 的参数在尖括号里所以转义一次, 其余的不在. 实验表明处理参数列表时先读 1 个字符, 然后...

- `!` 转义, 转义得到的字符算 1 个 token, 逗号不视作参数分隔符 
- `\` 续行
- `<` 往后找右尖括号, 之间的内容除去左右尖括号算 1 个 token
- `%` 往后找表达式结束符, 之间的内容算 1 个 token
- `'`, `"` 找匹配的引号, 之间的内容算 1 个 token
- `标识符字符` 找标识符, 如果是宏函数名, 找到后往后找圆括号对儿, 否则宏函数后的所有文本都算 1 个参数
- `,` 前面的文本去掉两边的空白, 算 1 个参数

```
; 由于 for 的参数在尖括号里所以多转义一次
; ml -Zs dd.msm

p01 macro   arg1, arg2
    echo    arg1 -- arg2
    endm

    p01     <a, b> !, c         ; a, b , c --

t01 catstr  <>
    for     i, <<a, b> !, c>    ; 转义 1 次不够
t01 catstr  t01, <i>, < -- >
    endm
%   echo    t01                 ; a, b -- c --

t01 catstr  <>
    for     i, <!<a, b!> !!, c>
t01 catstr  t01, <i>, < -- >
    endm
%   echo    t01                 ; a, b , c --

t01 catstr  <>
    for     i, <<a, b> !!, c>   ; 尖括号无需转义
t01 catstr  t01, <i>, < -- >
    endm
%   echo    t01                 ; a, b , c --

    end
```

```
; 参数会去除每一个尖括号对儿的外层尖括号
; ml -Zs dd.msm

m01 macro   arg
    echo    arg
    endm

t01 catstr <<1> <<2>> <<<3>>> <<<<4>>>>>

%   echo      t01                                   ; <1> <<2>> <<<3>>> <<<<4>>>>
    m01     % t01                                   ; <1> <<2>> <<<3>>> <<<<4>>>>

    m01       1     <2>     <<3>>     <<<4>>>       ; 1     2     <3>     <<4>>
    m01      <1>    <<2>>   <<<3>>>   <<<<4>>>>     ; 1    <2>   <<3>>   <<<4>>>
%   m01       t01                                   ; 1 <2> <<3>> <<<4>>>

    m01     <<1>> <<<2>>> <<<<3>>>> <<<<<4>>>>>     ; <1> <<2>> <<<3>>> <<<<4>>>>
    end
```

```
; 调用时不展开行内文本
; ml -Zs dd.msm

p01 macro   arg1, arg2
    echo    arg1 -- arg2
    endm

f01 macro
    exitm   <a, b>
    endm

t01 catstr  <a, b>

    p01     t01         ; t01 --        参数列表里不替换文本宏

    p01     a, b        ; a -- b        2 个参数
%   p01     t01         ; a -- b        2 个参数, 行首的 % 先转义行内文本
    p01   % t01         ; a, b --       1 个参数, 说明调用时未展开文本宏
    p01  !% t01         ; % t01 --      1 个参数, 不在尖括号里的文本也能转义

    p01     f01() bc    ; a, b bc --    1 个参数, 说明调用时未展开宏函数
    end
```

```
; 参数去掉两边的空白
; ml -Zs dd.msm

p01 macro   arg1, arg2
    echo    1&arg1&1, 1&arg2&1
    endm

f01 macro
    exitm   <a   >
    endm

f02 macro
    exitm   <   a   >
    endm

    p01     f01(),     b        ; 1a   1, 1b1
    p01     f02(),     b        ; 1   a   1, 1b1
    end
```

处理完毕得到若干未求值的参数, 按下面方式对这些参数求值后替换宏里使用参数的地方:

- 调用宏函数. 丢弃函数名和左圆括号间的文本
- % 替换. 表达式求值, 替换结束符前的行内文本
- 不解释参数末尾的 `\`, echo 也不显示它

```
; bug: 调用宏函数时丢弃函数名和左圆括号间的文本
; ml -Zs dd.msm

p01 macro   arg1, arg2, arg3, arg4, arg5
    echo    arg1 -- arg2 -- arg3 -- arg4 -- arg5
    endm

f01 macro
    exitm   <c>
    endm

    p01     a, b, f01 ,, (\             ; a -- b -- cd -- e --
)\
d, e

; bug: f01 -> 01                        ; error A2065: expected : )
;                                       ; a -- b --  01 --  -- (
    p01     a, b, f01 ,, (

; bug: all text, including comments, is counted as one argument
;                                       ; a -- b -- f01 ,, c, d
    p01     a, b, f01 ,, c, d           ; whatever
; in ml -EP: echo    a -- b -- f01 ,, c, d           ; whatever --  --

    for     i, <f01 ,,1,2,3,, () a, b>
    echo    i                           ; c a
;                                       ; b
    endm
    end
```

```
; 去除未求值的参数里的外层尖括号影响不到 % 替换
; ml -Zs dd.msm

m01 macro   arg1, arg2
    echo    arg1 -- arg2
    endm

    m01     1 !,  2, 3          ; 1 ,  2 -- 3
    m01     1 ',' 2, 3          ; 1 ',' 2 -- 3
    m01     1 <,> 2, 3          ; 1 , 2 -- 3

    for     i, <1 !!, 2, 3>
    echo    i                   ; 1 , 2
;                               ; 3
    endm

    for     i, <1 ',' 2, 3>
    echo    i                   ; 1 ',' 2
;                               ; 3
    endm

    for     i, <1 <,> 2, 3>
    echo    i                   ; 1 , 2
;                               ; 3
    endm

t01 catstr  <1 <,> 2, 3>

    m01     t01                 ; t01 --
    m01   % t01                 ; 1 <,> 2, 3 --
%   m01     t01                 ; 1 , 2 -- 3

    for     i,   <t01>
    echo    i                   ; t01
    endm

    for     i, <% t01>
    echo    i                   ; 1 <,> 2, 3
    endm

%   for     i,   <t01>
    echo    i                   ; 1 , 2
;                               ; 3
    endm
    end
```

```
; 有些符号能结束参数里 % 后的表达式, 不知道都是哪些, 这里随便试了几个
; ml -Zs dd.msm

p01 macro   args: vararg
    echo    args
    endm

t01 catstr  <>
    p01         a%1#b, a%1^b, a%1`b, a%1~b      ; a1#b,a1^b,a1`b,a1~b
    for     i, <a%1#b, a%1^b, a%1`b, a%1~b>
t01 catstr  t01, <i>, <,>
    endm
%   echo    t01                                 ; a1#b,a1^b,a1`b,a1~b,

t01 catstr  <>
    p01         a%1)b, a%1]b, a%1}b             ; a1)b,a1]b,a1}b
    for     i, <a%1)b, a%1]b, a%1}b>
t01 catstr  t01, <i>, <,>
    endm
%   echo    t01                                 ; a1)b,a1]b,a1}b,

t01 catstr  <>
    p01         a%1b, a%1!b,  a%1!b             ; a1,a1b,a1b
    for     i, <a%1b, a%1!!b, a%1!b>
t01 catstr  t01, <i>, <,>
    endm
%   echo    t01                                 ; a1,a1b,a1,

t01 catstr  <a>
    p01     % 1 + 1 % t01                       ; 2 a
    end
```

```
; bug: % 求值时错误解释左圆括号后的内容
; ml -Zs dd.msm

p01 macro   arg
    endm

    p01     a    b\c
    p01     a %  b\c        ; error A2006: undefined symbol : b
    p01     a % (b\c)       ; error A2109: only white space or comment can follow backslash
;   ~~~     ~~~~~~~~~       ; error A2081: missing operand after unary operator
    end
```

无法结束表达式的符号导致求值失败并报错:

- error A2016: expression expected
- error A2081: missing operand after unary operator
- error A2167: unexpected literal found in expression
- error A2207: missing right parenthesis in expression
- error A2208: missing left parenthesis in expression

```
; 参数替换作用到尖括号里, echo 后面
; ml -Flout\ -Sa -Zs dd.msm

t01 catstr  <a>                 ; Text      a
t02 catstr   t01                ; Text      a
t03 catstr  <t01>               ; Text      t01

m01 macro   i
    echo    i, <i>, <<i>>
    endm

    m01     a                   ; echo    a, <a>, <<a>>

    for     i, <a>
    echo    i, <i>, <<i>>       ; echo    a, <a>, <<a>>
    endm
    end
```

也从使用处的 `&` 两边找参数. & 可以拼接, 比如 arg&1 把 arg 的值和 1 拼到一起. 默认不替换下列地方的参数, 加上 & 就会替换, 此时每个参数都需要 1 个 &:

- 引号里
- 尖括号里 ! 后面

```
m01 macro   arg1, arg2
    echo    arg1 arg2, arg1arg2, arg1&arg2, <arg1&arg2>, 'arg1&arg2&'
    endm

    m01     1, 2
    end

ml -Zs dd.msm

1 2, arg1arg2, 12, <12>, '12'
```

展开参数里文本宏的其他方式: 拼一个使用参数的文本宏.

```
; ml -Zs dd.msm

t01 catstr  <abc>

p01 macro   arg
    echo    arg
    endm

    p01     t01             ; t01
    p01     % t01           ; abc

t02 catstr  <p01 >, t01
    t02                     ; abc
    end
```

### 行首的 %

% 有 3 种位置: text-item 前, 参数前, 行前, 在 3 个位置的作用各不相同.

行首的 % 替换该行的行内文本变量即文本宏和宏函数. 因为好多地方不执行宏替换所以发明了这玩意儿, 这些地方是:

- 不替换文本宏和宏函数
    - 分号后, 即注释
    - 引号, 尖括号内
    - echo, name, title, ... 的参数
    - for, forc, 宏过程, 宏函数的参数
    - equ text 的 text
- 不替换文本宏
    - 定义变量时的变量名

有行首 % 时替换上面那些地方的文本宏和宏函数, 引号里的文本宏和宏函数必须至少紧挨着 1 个 & 才替换, 至多紧挨着 2 个即左右各 1 个.

```
; 引号, 尖括号内; echo, name, title, ... 的参数
; ml -EP dd.msm

t01 catstr  <1>

p01 macro
    exitm   <2>
    endm

    't01'  'p01()'          ; 't01'  'p01()'        syntax error
    <t01>  <p01()>          ; <t01>  <p01()>        syntax error

    echo    t01 p01()       ; echo    t01 p01()
    name    t01 p01()       ; name    t01 p01()
    title   t01 p01()       ; title   t01 p01()

%   't01'  'p01()'          ; 't01'  'p01()'        syntax error
%   't01&' 'p01()&'         ; '1' '2'               syntax error
%   <t01>  <p01()>          ; <1>  <2>              syntax error

%   echo    t01 p01()       ; echo    1 2
%   name    t01 p01()       ; name    1 2
%   title   t01 p01()       ; title   1 2
    end
```

行首的 % 导致 & 作用于文本宏和宏函数:

```
; ml -Flout\ -Sa -Zs dd.msm

a01 catstr  <1>
a02 catstr  <2>

f01 macro
    exitm   <3>
    endm

    a01&a02     ; 1&2   error A2008: syntax error : integer
%   a01&a02     ; 12    error A2008: syntax error : integer

 b1 catstr   a01&a02    ; error A2008: syntax error : &
 b2 catstr  <a01&a02>   ; Text        a01&a02
%b3 catstr  <a01&a02>   ; Text        12

    f01()&      ; 3&    error A2008: syntax error : integer
%   f01()&      ; 3     error A2008: syntax error : integer

 c1 catstr   f01()&     ; error A2008: syntax error : &
 c2 catstr  <f01()&>    ; Text        f01()&
%c3 catstr  <f01()&>    ; Text        3
    end
```

参数列表里不替换文本宏, 所以是否有行首 % 可能导致宏过程看到不同数量的参数.

```
; ml -Zs dd.msm

p01 macro   arg1, arg2
    echo    arg1, arg2
    endm

t01 catstr  <a, b>

    p01     t01             ; t01,
%   p01     t01             ; a, b
    end
```

行首的 % 可以替换宏过程的参数, 但无法替换宏函数的参数因为会先调用宏函数. 替换宏函数的参数需要参数前的 %.

```
; ml -Zs dd.msm

f01 macro   arg
    echo    arg
    exitm   <>
    endm

p01 macro   arg
    echo    arg
    endm

t01 catstr  <a>

    p01 t01         ; t01
%   p01 t01         ; a

    f01(t01)        ; t01
%   f01(t01)        ; t01
    f01(% t01)      ; a
    end
```

下面的示例中参数列表里有宏函数调用. 正常情况下参数列表里的宏函数调用会走 bug 分支丢弃函数和括号之间的字符即 `t01 xxx`. 在行首放置 % 导致替换该行的宏函数和文本宏, 此分支的宏函数没有参数列表的 bug, 宏函数不挨括号就不调用, 只会替换文本宏 `t01`, 留下 `p01 f01 () xxx ()`, `f01 ()` 在 p01 解析参数时执行.

```
; ml -Zs dd.msm

p01 macro   args: vararg
    echo    args
    endm

f01 macro
    exitm   <ret>
    endm

t01 catstr  <()>

    p01 f01 t01 xxx ()      ; ret
%   p01 f01 t01 xxx ()      ; ret xxx ()
    end
```

### bug 调用

替换文本宏或宏函数调用得到宏函数时 masm 往后找满足函数调用的圆括号否则报错. 说 bug 是因为宏函数由当前 token 替换得到, 单独的函数名无法调用, 因此应该结束此 token 的处理然后去处理下一 token, 下一 token 即使是圆括号也不该和上次替换得到的函数名组成调用. bug 调用不仅立即使用后面的圆括号, 还可能继续使用更后面的圆括号. 发生 bug 调用的行必须后续执行一次正常的行内文本替换否则报错 A2039.

```
; ml -Zs dd.msm

c01 catstr  <f01>
c02 catstr  <f02>
c03 catstr  <f03>
c04 catstr  <f04>

t01 catstr  <>

f01 macro
    exitm   <>
    endm

f02 macro
    exitm   <t01>
    endm

f03 macro
    exitm   <f01>
    endm

f04 macro
    exitm   <f01()>
    endm

f05 macro
    exitm   <f02>
    endm

    c01()           ; error A2039: line too long
    c02()           ; ok. return t01 = symbol/text
    c03()()         ; error A2039: line too long
    c04()           ; ok. return f01() = macro func call

    f03()()         ; error A2039: line too long
    f05()()         ; ok. return f02, f02 () = bug call, returns t01 = symbol/text

    c01() t01       ; ok. normal substitution follows
    end
```

使用后面圆括号的效果不累积, 无论使用了几对, 1 个文本宏或宏函数替换就能回归正常.

```
; ml -Zs dd.msm

t01 catstr  <>

f01 macro
    exitm   <t01>
    endm

f02 macro
    exitm   <f01>
    endm

f03 macro
    exitm   <f02>
    endm

f04 macro
    exitm   <f03>
    endm

    f01()
    f02()()
    f03()()()
    f04()()()()
    end
```

用 `ml -EP` 可以看到报告 line too long 时 masm 生成了大量垃圾字符:

```
; ml -EP dd.msm

t01 catstr  <f01>

f01 macro
    exitm   <>
    endm

    t01     ()
    end
```

下面的调用我不确定是否属于 bug 调用. 它也使用后面的括号组成调用, 但

- 替换出的宏函数必须接受参数
- 替换出的宏函数调用后不产生垃圾字符
- 调用语句前加 % 导致语法错误

```
; ml -Zs dd.msm

c01 catstr  <f01(>

f01 macro   arg
    exitm   <>
    endm

    c01)
; % c01)        error A2065: expected : )
    end
```

参数不执行 bug 调用.

```
; ml -Zs dd.msm

f01 macro
    exitm   <f03>
    endm

f02 macro
    exitm   <()>
    endm

f03 macro
    echo    called
    exitm   <t01>
    endm

t01 catstr  <>

p01 macro   arg1, arg2
    echo    arg1, arg2
    endm

    f01()()                 ; called

    p01     f01()  ()       ; f03  (),
    p01     f01()  f02()    ; f03  (),
    p01     f01(), f02()    ; f03, ()
    end
```

行首 % 替换时不执行 bug 调用.

```
; ml -Zs dd.msm

f01 macro
    echo    f-01
    exitm   <>
    endm

f02 macro
    echo    f-02
    exitm   <>
    endm

c01 catstr  <f01>
c02 catstr  <f02>

    c01() f02()     ; f-01
;                   ; f-02

%   c01() f02()     ; f-02
;                   ; f-01
    end
```

行首 % 替换时不执行 bug 调用, 示例 2. 下面示例中 `% c01(t01)` 替换 c01 得到 f01 后如果执行 bug 调用会输出 t01, 但输出了 a, 说明 % 替换时没有调用 f01(t01) 而是生成了 f01(a).

```
; ml -Zs dd.msm

c01 catstr  <f01>
t01 catstr  <a>
t02 catstr  <>

f01 macro   arg
    echo    arg
    exitm   <t02>
    endm

    f01(t01)            ; t01
    c01(t01)            ; t01
%   c01(t01)            ; a
    end
```

行首 % 替换时虽不执行但有时会影响 bug 调用, 不清楚具体的触发条件. 先看不影响的情况. `% c03 f02()` 在 % 看到 c03 时它还未定义, 执行 f02() 后才定义, 所以 % 得到 `c03 ()`, 这句话在一般上下文中替换, 所以和前面 `c01()` 的报错一样.

```
; ml -Zs dd.msm

c01 catstr  <f01>
c02 catstr  <()>

f01 macro
    exitm <>
    endm

f02 macro
c03 catstr  <f01>
    exitm   <()>
    endm

    c01()
%   c01()
%   c03 f02()
    end

dd.msm(14): error A2039: line too long
dd.msm(16): error A2039: line too long
```

然后是行首 % 替换时虽不执行但却影响 bug 调用的情况:

- 只要不返回空文本就正常
- 如果返回空文本, 只生成 1 个而不是 1 堆垃圾字符

```
; ml -Zs dd.msm

f01 macro
    exitm   <>
    endm

f02 macro
    exitm   < >
    endm

f11 macro
    exitm   <f01>
    endm

f12 macro
    exitm   <f02>
    endm

c01 catstr  <f01>
c02 catstr  <f02>
c11 catstr  <f11>
c12 catstr  <f12>

    c01()       ; error A2039: line too long
    c02()       ; error A2039: line too long

; error A2044: invalid character in file
%   c11()()

%   c12()()
    end
```

有 2 种方法解决行首 % bug 调用并返回空文本时生成的垃圾字符, 奇葩得很:

- 语句后加注释, 这会让垃圾字符生成到注释里
- 行首再加个 %

```
; ml -Zs dd.msm

c02 catstr  <f02>

f01 macro
    exitm   <>
    endm

f02 macro
    exitm   <f01>
    endm

%   c02()()     ;
%%  c02()()
    end
```

无论使用了几个圆括号上面两种解决方法都不变, 即, 只需要 1 个注释或 1 个额外的 %.

```
; ml -Zs dd.msm

c01 catstr  <f01>
c02 catstr  <f02>
c03 catstr  <f03>
c04 catstr  <f04>

f01 macro
    exitm   <>
    endm

f02 macro
    exitm   <f01>
    endm

f03 macro
    exitm   <f02>
    endm

f04 macro
    exitm   <f03>
    endm

%   c01()

%   c02()()     ;
%%  c02()()

%   c03()()()   ;
%%  c03()()()

%   c04()()()() ;
%%  c04()()()()

    end
```

### bug 拼接

行首 % 替换得到文本宏时 masm 把它和后面的 token 拼到一起, 尝试继续替换.

```
; ml -EP dd.msm

f0a macro
    exitm   <a>
    endm

t0b catstr  <b>
ab  catstr  <splice>

t01 catstr  <f0a()t0b>
t02 catstr  <f0a() t0b>
t03 catstr  <f0a()b>

    t01         ; ab    error A2008: syntax error : a
%   ; t01       ; at0b

    t02         ; a b   error A2008: syntax error : a
%   ; t02       ; a b

    t03         ; ab    error A2008: syntax error : a
%   ; t03       ; splice
    end
```

## 验证

### nesting level

- qh/assembly/directives/macros and iterative blocks/macro

macro procedures and macro functions can be nested up to 40 levels; text macro may be nested up to 20 levels.

```
; bug: macro procedures 只能递归 19 次
; ml -Zs dd.msm

p   macro   cnt
    if      cnt gt 0
    p       % cnt - 1
    endif
    endm

    p       19
    p       20  ; fatal error A1007: nesting level too deep
    end
```

```
; bug: macro functions 只能递归 18 次
; ml -Zs dd.msm

f   macro   cnt
    if  cnt gt 0
    f(% cnt - 1)
    endif

    exitm <>
    endm

    f(18)
%   f(19)

;   f(19)   ; fatal error A1007: nesting level too deep
%   f(20)   ; fatal error A1007: nesting level too deep
    end
```

```
; text macro may be nested up to 20 levels
; 21 个 1$

self_ref catstr <1$ self_ref>
self_ref
end

ml -EP dd.msm

dd.msm(6): error A2123: text macro nesting level too deep
1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ 1$ self_ref
```

如果把上面示例里的 1$ 换成下面这些会看到不同的结果:

- 1 个字符. 输出往往后跟一堆乱码, 换成 # 更是导致 dosbox 循环输出乱码
- #$. error A2044: invalid character in file
- 2 ~ 242 个 d. error A2123. 即使看输出不够 21 次也报此错
- 243 ~ 246 个 d. error A2042. 但 `self_ref catstr <ddd self_ref>` 至多 6 个 token, 一堆 d 不会拆成若干 dd
- 247+ 个 d. error A2041. 247 + 空格 + self_ref = 256

其中,

- fatal error A1007: nesting level too deep
    - 经实验递归展开宏函数而不报错的次数, % 打头是 19, 否则是 18
- error A2039: line too long
    - 经实验一行有 513+ 字符时报 A2039
    - [Q155047: PRB: A2041 Initializing a Large STRUCT](https://jeffpar.github.io/kbarchive/kb/155/Q155047/)
- error A2041: string or text literal too long
    - 经实验 echo 后放 256 字节也报 A2041, 不仅是下面说的宏参数
    - [Q137174: DOCERR: A2041 Error When Macro Parameter Length > 255 bytes](https://jeffpar.github.io/kbarchive/kb/137/Q137174/)
- error A2042: statement too complex
    - 经实验 token 很少的时候也会报 A2042
    - masm 6.x 一行中的 token 有 99+ 时报 A2042
    - [Q85228: BUG: Causes of A2042 During Data Initialization](https://jeffpar.github.io/kbarchive/kb/085/Q85228/)
    - A2042 在 masm 5.1 中是另外的错误 Q40852: FIX: A2042 May Be Caused By Using LOW and OFFSET In MASM 5.1
- error A2123: text macro nesting level too deep
    - 经实验没有 % 打头时在展开了 21 次后报 A2123
    - % 打头时展开了 500+ 次仍没停止, 报错行长度超过 512 才停, 仍没报 A2123; 其它实验表明 % 打头确实能触发 A2123

```
; A2041 (256+ bytes), A2042 (99+ tokens)
;
; ml -Zs dd.msm

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

也不知道什么是 nesting level, 是递归的深度吗? 如果是一个宏指向另一个宏则超过 21 个也没关系.

```
; ml -Zs dd.msm

t01 catstr <>
t02 catstr <t01>
t03 catstr <t02>
t04 catstr <t03>
t05 catstr <t04>
t06 catstr <t05>
t07 catstr <t06>
t08 catstr <t07>
t09 catstr <t08>
t10 catstr <t09>
t11 catstr <t10>
t12 catstr <t11>
t13 catstr <t12>
t14 catstr <t13>
t15 catstr <t14>
t16 catstr <t15>
t17 catstr <t16>
t18 catstr <t17>
t19 catstr <t18>
t20 catstr <t19>
t21 catstr <t20>
t22 catstr <t21>
t23 catstr <t22>
t24 catstr <t23>
t25 catstr <t24>
t26 catstr <t25>
t27 catstr <t26>
t28 catstr <t27>
t29 catstr <t28>
t30 catstr <t29>

%   echo    t30
    end
```

### 整数后缀

实验表明有 12 种整数后缀, 其中 a, c, e, f 显然是 bug.

```
; bug: 整数的 a, c, e, f 后缀
; ml -Flout\ -Sa -Zs dd.msm

t01 catstr  % 1a    ; 20
t02 catstr  % 1b    ; 1
t03 catstr  % 1c    ; 22
t04 catstr  % 1d    ; 1
t05 catstr  % 1e    ; 24
t06 catstr  % 1f    ; 25
t07 catstr  % 1h    ; 1
t08 catstr  % 1o    ; 1
t09 catstr  % 1q    ; 1
t10 catstr  % 1r    ; 92
t11 catstr  % 1t    ; 1
t12 catstr  % 1y    ; 1
    end
```

### 展开是前序遍历

- 深度优先
    - 前序遍历 f(node) = use(node), f(node.left), f(node.right)
    - 中序遍历 f(n) = f(l), u(n), f(r)
    - 后序遍历 f(n) = f(l), f(r), u(n)

masm 只能按前序遍历的方式展开行内文本, 因为只有展开当前节点才能得到子节点. 下面不预先构造行内文本树, 而是在展开时用宏函数调用再生成宏函数调用. curLevel 离 maxLevel 还远时每个节点生成 3 个子节点, 最后 3 个 level 分别生成 2, 1, 0 个子节点.

```
; https://www.geeksforgeeks.org/dsa/introduction-to-tree-data-structure/
; node type : root, internal, leaf or external
; level     : root = 0
;
; ml -Zs dd.msm

f01 macro   maxLevel, curLevel: =<0>, path: =<root>
    local   t01

%   echo    level curLevel, path
t01 catstr  % curLevel + 1

    if      t01 gt maxLevel
        exitm   <>
    elseif  t01 eq maxLevel
        exitm   <f01(maxLevel, t01, leaf)>
    elseif  t01 eq maxLevel - 1
        exitm   <f01(maxLevel, t01, internal-2-1) f01(maxLevel, t01, internal-2-2)>
    else
        exitm   <f01(maxLevel, t01, internal-3-1) f01(maxLevel, t01, internal-3-2) f01(maxLevel, t01, internal-3-3)>
    endif
    endm

    f01(3)      ; max = 4
    end
```

下面打印节点路径:

```
; 节点编号规则如下:
;        0
;    0       1
;  0   1   2   3
; 0 1 2 3 4 5 6 7
;
; ml -Zs dd.msm

masmLimit   catstr  <4>

f01 macro   c, i, s
    local   a, b, sa, sb

    echo    s

    if      c
a       catstr  % i * 2
b       catstr  % a + 1

sa      catstr  <00>, a
sb      catstr  <00>, b
sa      substr  sa, @sizestr(% sa) - 1
sb      substr  sb, @sizestr(% sb) - 1
sa      catstr  <s->, sa
sb      catstr  <s->, sb

        exitm   <f01(c - 1, a, % sa) f01(c - 1, b, % sb)>
    else
        exitm   <>
    endif
    endm

f02 macro   cnt
    local   c

c   catstr  <cnt>

    if      c gt masmLimit
%       echo    count = c > masmLimit, set to masmLimit
c       catstr  masmLimit
    elseif  c lt 0
        exitm   <>
    endif

    f01     (c, 0, <00>)
    endm

    f02     (10)
    end
```

随着 masmLimit 的增大能看到下列错误:

- error A2006: undefined symbol : ??00D0
- error A2039: line too long
- error A2044: invalid character in file
- error A2081: missing operand after unary operator
- error A2123: text macro nesting level too deep
- error A2157: missing right parenthesis
- runtime error R6018 - unexpected heap error

思考: 能否控制文本宏的递归次数, 或者组合多个其它文本宏? 这就像控制不使用参数的函数的递归次数, 或许做不到.

## 杂项

### 预定义符号

```
; ml -Zs dd.msm

p01 macro   file, line, arg
    echo    file(line) arg
    endm

    p01     % @filecur, % @line, @environ(comspec)
    end
```

### opattr, @cpu, pushcontext, popcontext

- 610guide p???/p196

opattr 返回 16 位整数, 0 ~ 10 位有意义; .type 返回 opattr 的前 8 位即低字节. 不返回宏程序变量的信息因此没啥用.

```
f macro a
    t catstr % opattr a
    % echo t
endm

f ax

.radix 2
cpu catstr % @cpu
.radix 10

% echo cpu

IF cpu AND 00000010y
    echo 80186 or higher
ELSE
    echo 8088/8086
endif

end
```

- 610guide p???/p198 在宏里可以用 pushcontext, popcontext 保存, 恢复下列设置

Option  | Description
-|-
ASSUMES | Saves segment register information
RADIX   | Saves current default radix
LISTING | Saves listing and CREF information
CPU     | Saves current CPU and processor
ALL     | All of the above

### masm 和 c 的预处理

masm | c
-|-
创建单行宏和多行宏语法不同  | 只有单行宏但足够了, 因为可以用分号创建许多逻辑行
一直展开到没有宏为止       | 只展开一次

```
                masm                                        c
------------------------------------        -------------------------------------

if , elseif, else, endif                    #if, #elif, #else, #endif
ife, elseife
ifdef , elseifdef                           #ifdef , #if  defined, #elif  defined
ifndef, elseifndef                          #ifndef, #if !defined, #elif !defined
ifb, elseifb, ifnb, elseifnb
ifidn, elseifidn, ifidni, elseifidni
ifdif, elseifdif, ifdifi, elseifdifi
=, equ, textequ, macro                      #define
                                            #undef
purge
                                            defined
rest: vararg                                ..., __VA_ARGS__
% expr                                      #s
s1&s2                                       s1##s2
echo, %out                                  #pragma message
.err                                        #error
.err1  , .err2 (*)
.erre  , .errnz
.errdef, .errndef
.errb  , .errnb
.erridn, .erridni
.errdif, .errdifi
include                                     #include
includelib                                  #pragma comment(lib)
                                            vc++ __pragma

(*) Both /Zm and OPTION M510 imply SETIF2:TRUE. with OPTION SETIF2:TRUE
```

### 语法

不对 x01 报错却对其后的 ax 报错, 难道是假设 directive 前面可以是类似变量名之类的 token, 但 ax 不是 directive? 对 x02 报错难道是因为查看发现后面是文本, 所以拐回来确定 x02 未果?

```
x01  ax, 1, t01     ; error A2008: syntax error : ax
x02 <ax, 1, t01>    ; error A2008: syntax error : x02
end
```

### 退化

masm 提供一个多行的复杂结构去定义宏函数, 用户在里面填入内容; 定义的宏函数是个单行的简单结构 名字 (参数, 参数, ...), 调用结果是行内文本.

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

退化体现在哪些地方?

- 定义出来的都是名字, 名字只能用名字允许的那些字符
- 关键字两边都是参数而名字只有右边是参数; 无法定义类似 `macro` 的 tag: left `tag` right
- 参数是处理过的, 拿不到原始文本
- 多行变单行了, 无法定义起始/结束括号: `tag` ... `end tag`/`endtag`

退化的后果是无法用它提供的语法创造同样的语法, 更不用说新的语法. 当然这本来也不是 masm 的目标, 只是我自己的一个想法.

### read later (maybe)

floating-point

- https://github.com/qwordAtGitHub/mreal-macros

## bugs

观察到过但目前无法重现的现象:

- 看到过宏参数也替换成和 local 变量一样的 ??00nn 名字
- 没给参数加尖括号时看到宏给参数前面加了 ! 符号
- 宏函数的参数不要求尖括号; 没有尖括号时, 如果在找到某个参数后的逗号前先找到了空格, 则忽略后续逗号, 整个后续参数列表删除首尾空格, 作为一个参数
- 存疑, 因为可能是 if 0 导致未汇编 elif: 曾经在宏函数里用了 elif, 执行当然不正确, 找了好半天才发现应该用 elseif. masm 没有对 elif 报错

### name TEXTEQU macroId?

> 610guide p???/p177<br>
name TEXTEQU macroId | textmacro<br>
macroId is a previously defined macro function, textmacro is a previously defined text macro

```
; ml -Zs dd.msm

msg macro
    exitm <>
endm

; error A2051: text item required
string TEXTEQU msg
end
```

文档和实际行为不一致. macroId 是宏函数时必须调用它.

### 预定义的字符串函数不替换文本宏参数

```
; 610guide p???/p191
; Each string directive and predefined function acts on a string, which can be
; any textItem. The textItem can be ... the name of a text macro, ...

regpushed TEXTEQU <>                    ;; Initialize empty string

; SaveRegs - Macro to generate a push instruction for each
; register in argument list. Saves each register name in the
; regpushed text macro.
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

文档和实际行为不一致. 预定义函数 @SizeStr 和其他宏函数一样, 调用时不替换文本宏参数.

- bug: @SizeStr( regpushed ) 返回文本 regpushed 的长度
- fix: 改为 @SizeStr(% regpushed) - 1
- test: 注释掉 SaveRegs 里的 push

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
```

不确定这是否是 dosbox 的毛病, 但只要是 x86 指令就这样, 否则不这样, 很可能是 masm 的毛病.

- https://jeffpar.github.io/kbarchive/kb/111/Q111263/
    ```
    CAUSE
    =====
    Unhandled exception errors can be caused by a system configuration problem such
    as an ill-behaved device driver, a terminate-and-stay-resident (TSR) program, or
    a memory manager that is not configured correctly for the hardware in a
    particular machine.
    ```

### 生成垃圾

```
; ml -EP dd.msm

f01 macro   arg
    echo    arg
s   catstr  <"&">, <arg>, <">
    exitm   s
    endm

%   "&f01 (<tok>)"
    end
```

## 代码示例

### ml -D

masm 命令行选项 -D 用 = 号定义文本宏, 它无法定义整数变量.

```
; ml -D s="how would you count this?" -Zs dd.msm

ifdef s
    len1 sizestr s
    len2 catstr % len1

    % echo s
    % echo has a length of len2
else
    echo variable s is not defined
endif
end

ml -D s="the name is s" -Zs dd.msm

dd.msm(3): error A2039: line too long
dd.msm(6): error A2039: line too long
dd.msm(6): error A2041: string or text literal too long
has a length of 254
```

### 计算斐波那契数

```
cyc macro n: =<5>
    local n1, n2, n3, i

    n1  = 0
    n2  = 1
    i   = 2

;; can be `repeat n - 2` thus eliminates `i`

    while i lt n
        n3  = n1 + n2
        n1  = n2
        n2  = n3
        i   = i + 1
    endm

    exitm % n1 + n2
    endm

rec macro n: =<5>
    if n lt 1
        exitm <0>
    elseif n eq 1
        exitm <1>
    else
        exitm % rec(% n - 1) + rec(% n - 2)
    endif
    endm

; it can accurately calculate up to 47 (2971215073)
%   echo cyc(47)

; slow
%   echo rec(20)
    end
```

### 条件块

masm 版本大于 6.11 时生成 windows console 程序, 否则生成 dos 程序.

```
; ml -Foout\ dd.msm -Feout\

if @version le 611

start   catstr  <abc>

xxx     segment stack
start:
        mov     ax, cs
        mov     ds, ax
        mov     dx, offset s
        mov     ah, 9
        int     21h

        mov     ax, 4c00h
        int     21h

s       byte    "16 bit program compiled with masm 611-$", 32 dup (?)
xxx     ends

else

start   catstr  <_main>

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

### defined

用 ifdef 实现宏函数 defined.

```
; 610guide p???/p193
; defined(x) - if x is a defined symbol, return -1, else return 0
;
; ml -Zs dd.msm

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

### 失败: @catstr

`@catstr(<a, b>, c)` 返回 `a, bc`, 不知道如何实现. @catstr 接受的参数个数可变, 只能用 vararg; 假设 f 使用 vararg, `f(<a, b>, c)` 的 vararg 是 `a, b,c`, 无法区分哪些逗号是 vararg 添加的.

```
; ml -Zs dd.msm

f01 macro   args: vararg
    echo    args
    endm

f02 macro   arg1, arg2
    echo    arg1 -- arg2
    endm

    f01     <a, b>, c           ; a, b,c
    f02     <a, b>, c           ; a, b -- c

%   echo    @catstr(<a, b>, c)  ; a, bc
    end
```

### toupper

toupper 把 text 的每一个字符转换为相应的字符, 首先想到 forc.

```
; ml -Zs dd.msm

l01 catstr  <abcdefghijklmnopqrstuvwxyz>
u01 catstr  <ABCDEFGHIJKLMNOPQRSTUVWXYZ>
t01 catstr  <>

    forc    i, <change this to <upper> case!!>
        ifidn       <!&i>, <!!>
t01         catstr  t01  , <!!>
        elseifidn   <!&i>, <!<>
t01         catstr  t01  , <!<>
        elseifidn   <!&i>, <!>>
t01         catstr  t01  , <!>>
        else
n01         instr   l01  , <i>

            if  n01
t01             catstr  t01, @substr(% u01, n01, 1)
            else
t01             catstr  t01, <i>
            endif
        endif
    endm

%   echo t01
    end
```

如果写成宏函数或宏过程, 要转换的文本就需要是参数. 参数是转义过的文本, 放到尖括号里就会再转义一次, 丢失一层叹号. 添加叹号太麻烦这里只处理末尾的叹号. 并且像 `t01 catstr t01, <i>` 这种语句要防止右边的 t01 被多次替换, 这里让 t01 以引号打头以阻止它.

```
; 本代码包含 bug: 丢失叹号
; ml -D s="some text" -Zs dd.msm

    ifndef  s
s       catstr  <the <quick> 'brown" % 'fox" jumps over the % lazy dog!!>
        echo    no ml -D switch specified, using default
    endif

toupper macro   arg
        local   index, ret, str

index   sizestr arg

        ife index
            exitm   <>
        endif

lower   catstr  <abcdefghijklmnopqrstuvwxyz>
upper   catstr  <ABCDEFGHIJKLMNOPQRSTUVWXYZ>
ret     catstr  <'>

        ifidn   @substr(% arg, index, 1), <!!>
str         catstr  arg, <!!>
        else
str         catstr  arg
        endif

%       forc    i, <str>
            ifidn       <!&i>, <!!>
ret             catstr  ret  , <!!>
            elseifidn   <!&i>, <!<>
ret             catstr  ret  , <!<>
            elseifidn   <!&i>, <!>>
ret             catstr  ret  , <!>>
            else
index           instr   lower, <i>

                if  index
ret                 catstr  ret, @substr(% upper, index, 1)
                else
ret                 catstr  ret, <i>
                endif
            endif
        endm

        exitm   @substr(% ret, 2)
    endm

%   echo    toupper(s)
%   echo    toupper(<s>)
    end
```

既然 forc 的尖括号只能处理文本字面量不能处理参数, 那只能用预定义的文本函数.

```
; ml -D s="some text" -Zs dd.msm

ifndef s
    s catstr <the <quick> 'brown" % 'fox" jumps !! over the % lazy dog!!>
    echo no ml -D switch specified, using default
endif

toupper macro arg
    local i, j, lenp1, ret

    lenp1 = @sizestr(% arg) + 1

    if lenp1 eq 1
        exitm <>
    endif

    lower catstr <abcdefghijklmnopqrstuvwxyz>
    upper catstr <ABCDEFGHIJKLMNOPQRSTUVWXYZ>
    ret   catstr <'>
    i = 1

    while i lt lenp1
        j instr lower, @substr(% arg, i, 1)

        if j
            ret catstr ret, @substr(% upper, j, 1)
        else
            ret catstr ret, @substr(% arg, i, 1)
        endif

        i = i + 1
    endm

    exitm @substr(% ret, 2)
    endm

%   echo    toupper(s)
%   echo    toupper(<s>)
    end
```

```
; earlier failed attempt
; x = "a" 让 x 保存字符 a 的 ascii 值; 现在有 ascii 值, 怎么得到字符?
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

### 非行首的迭代块和宏过程

```
; ml -Zs dd.msm

; symbol/text 不能包含换行, 迭代块只能生成行, 所以尝试续行符. 想用迭代块生成下面定义 te1 的语句

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

### 失败: 展开指定的次数

```
; % exitm 不生成宏函数
;
; ml -EP dd.msm

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

下面是把文本宏展开指定次数的尝试, 要点是:

- 把文本宏放引号里, 用 & 控制展开次数. 后果是无法处理包含引号的 text
- % tag catstr <> 也展开 tag, 意味着 tag 只能用一次, 那就得创造不定数量的 tags. 用递归函数避开这问题
- 宏函数里的 % s1 catstr <"&&arg"> 首先把引号里的 &arg 替换为传入的参数, 不消耗 %, 然后展开 1 次
- %% s2 catstr <"&&&s1"> 先把引号里的 &s1 替换为 ??000x, 不消耗 %, 然后展开 ??000x 2 次

bug 是:

- 使用了尖括号, 会转义一次从而丢失一次叹号
- 展开后可能包含多个 token, 而它只能展开第 1 个
- 每展开一次都需要一个 &, 如果没能展开就留下 &
- 不知道如何返回展开后的值所以不返回, 而是用 echo 打印

masm 区分展开后的 tokens 但无法获取这个 token 列表, 否则可以用 ifdef 判断 token 是否是 symbol/text 或 macro/func, 不过也没办法区分两者.

```
; ml -Zs dd.msm

expand_1st_token_n_times macro token, n: =<1>
    local len, s1, s2

    % s1 catstr <"&&token">
    len sizestr s1
    s1 substr s1, 2, len - 2

    if n gt 1
        %% s2 catstr <"&&&s1">
        len sizestr s2
        s2 substr s2, 2, len - 2
        exitm expand_1st_token_n_times(s2, n - 1)
    else
        % echo "&&s1"
        exitm <>
    endif
endm

te1 catstr  <te2 ()>
te2 catstr  <mf1>
mf1 macro
    exitm <return value of mf1>
endm

expand_1st_token_n_times(te1, 1) ; "te2 ()"
expand_1st_token_n_times(te1, 2) ; "mf1 ()"
expand_1st_token_n_times(te1, 3) ; "return value of mf1"
expand_1st_token_n_times(te1, 4) ; "&return value of mf1"

end
```

也可以拼凑相应数量的 &. 和前面代码有同样的 bug.

```
; ml -Zs dd.msm

f01 macro arg, n: =<1>
    local ampersands, len, s1, s2

    if n lt 1
        exitm <>
    endif

    ampersands catstr <'&>

    repeat n - 1
        ampersands catstr ampersands, <&>
    endm

    s1 catstr ampersands, <arg>, <'>
    % s2 catstr <s1>
    len sizestr s2

    exitm @substr(% s2, 2, len - 2)
    endm

te1 catstr  <te2 ()>
te2 catstr  <mf1>
mf1 macro
    exitm <return value of mf1>
    endm

%   echo    "&f01(te1, 1)" ; "te2 ()"
%   echo    "&f01(te1, 2)" ; "mf1 ()"
%   echo    "&f01(te1, 3)" ; "return value of mf1"
%   echo    "&f01(te1, 4)" ; "&return value of mf1"
    end
```

### 拼接文本

没用的 callf(f, arg1, arg2, ...), 想用展开的 args 调用 f, 类似 f(% arg1, % arg2, ...), 但有 bug 会错误的转义.

- 拼 f 的参数列表时不能写 `x catstr <f(>, rest, <)>`
    - 没传参数时 rest 是空串, 得到 `x catstr <f(>, , <)>`, 语法错误
    - rest 里有未定义的名字时, 语法错误
- `x catstr <f(>, <rest>, <)>` = `<f(rest)>`, rest = arg1, arg2, ..., 参数均未展开, 也不行

因此需要在 for 里判断每个参数, 反复拼接.

```
; 本代码包含 bug: 错误的转义
; ml -Zs dd.msm

callf   macro f: req, rest: vararg
        local x, len

        x catstr <>

        for i, <rest>
            ifdef i
                x catstr x, <, >, i
            else
                x catstr x, <, i>
            endif
        endm

        ifb x
            x catstr <f()>
        else
            len sizestr x
            x substr x, 2, len - 1      ;; remove comma
            x catstr <f(>, x, <)>
        endif

        exitm x
    endm

f   macro a, b, c
        echo a -- b -- c
        exitm <>
    endm

    callf   (f)             ; --  --
    callf   (<f>, s1)       ; s1 --  --

s1  catstr  <this is abc, s2, <h, there>>
s2  catstr  <2ndargreplaced>
    callf   (<f>, s1)       ; this is abc -- 2ndargreplaced -- h, there

%   echo    @sizestr(s1)                    ; 02
%   echo    callf(<@sizestr>, <<<s1>>>)     ; 039
    end
```

[No Old Maps Actually Say 'Here Be Dragons'](https://www.theatlantic.com/technology/archive/2013/12/no-old-maps-actually-say-here-be-dragons/282267/)

下面用宏函数返回变量名的方式拼接出一组变量名. f01 把第 1 个参数的值改成变量名组的前缀, 变量名组里的名字类似 prefix$0, prefix$1, ... prefix 是个变量, 使用时需要展开; `$` 是个视觉上的分隔, 没有语法作用. f01 里定义了 local 变量 f01, 它真实名字不是 f01, 这样就不会覆盖外层 f01 的定义; 也可以用 `@catstr(prefix&$, % c) catstr <i>` 代替内层 f01 调用.

```
; ml -Zs dd.msm

f01 macro outPrefix, rest: vararg
    local c, f01, prefix

    c catstr <0>
    outPrefix catstr <prefix>

    f01 macro
        local t
        t catstr <prefix&$>, c
        exitm t
    endm

    for i, <rest>
        f01() catstr <i>
        c catstr % c + 1
    endm
endm

abc catstr <ddd>

    f01     prefix, abc
%   echo    prefix              ; ??0002
%%  echo    prefix&$0           ; ddd
%%  echo    "&&prefix&$0"       ; "abc"

    f01     prefix, 10, 23, 32
%   echo    prefix              ; ??0006
%%  echo    prefix&$0 prefix&$1 prefix&$2 prefix&$3 ; 10 23 32 ??0006$3
    end
```

masm 的宏只有整数和文本, 没有数组. 类似 prefix$0, prefix$1, ... 的名字和数组一样都用序号指定变量, 但 prefix 是个变量使用时需要展开, 基本上没法用, 所以打算用宏函数模仿数组的 api, 用 `a(n)` 表示 `a[n]`.

- 宏过程 newArray 把它的参数定义为宏函数, 这是唯一的办法, 其他办法比如宏函数, 只能返回文本不能返回宏函数
- newArray 定义的 arr 实际上是映射而不是数组, arr 没有确保 i 是正整数
- 没有 length, resize 等方法

```
; ml -Zs dd.msm

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

%   echo    arr1(0) -- arr1(1) -- arr1(2) -- arr1(3) -- arr1(4)   ; 1 -- 3 --  --  -- 34
    end
```

### Douglas Crockford: Memoization

- douglas crockford/javascript the good parts/4.15 memoization

```
// javascript

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

memoizer 接受 2 个参数 arr 和 r (recurrence formula), 返回 1 个闭包 a. a 接受 1 个参数 n 并捕获 arr 和 r, 返回数列的第 n 个元素, 计算方式是检查 n 是否位于 arr 中, 是就返回 `arr[n]`, 否则调用 r(a, n), 把返回值保存到 arr 然后返回它. 递推公式 r 只有 2 个参数 a 和 n 可用, 不能访问 memoizer 的局部变量, 所以只能在 a 和 n 上做文章, 能计算诸如 a(n + 1) = 2 * a(n) + 7 之类的递推关系.

这个复杂做法的意图是缓存之前的计算结果. javascript the good parts, 4.15 记忆, 展示了一般的 fibonacci 递归, 可以看到每次调用 fibonacci 函数都要重新计算数列的各项因而有很多重复计算:

```
// javascript

var fibonacci = function (n) {
    return n < 2 ? n : fibonacci(n - 1) + fibonacci(n - 2);
};

for (var i = 0; i <= 10; i += 1) {
    document.writeln('// ' + i + ': ' + fibonacci(i));
}
```

把 memoizer 写成容易理解的形式, 比如下面:

```
// javascript

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

可以看到 cb 用了 4 个变量, arr, cb, f, n; 3 个由参数传递, 1 个是自己. arr 和 cb 不是自己用而是传给 f 让它用, 这就有点浪费空间和分散注意力, 不如 memoizer 的闭包捕获.

下面用 masm 的宏实现 js memoizer, 要点:

- 无法返回函数, 所以用 memoizer 的第 1 个参数做输出参数, 把原本的返回值赋值给第 1 个参数
- 不返回函数名, 因为返回的函数名只能执行 bug 调用; 参数可以是函数名因为参数替换是单独的过程
- 在参数中传递函数名需要转义, 比如放进尖括号
- 函数 cbFib, cbFac 没有确保 n 在正确的区间, crockford 的原文也没有确保这点

```
; ml -D n=10 -Zs dd.msm

memoizer macro shell, memo, fundamental
    shell macro n
        local result

        result textequ memo(n)

        ifb result
            result textequ fundamental(<shell>, n)
            memo(n, result)
        endif

        exitm result
    endm
endm

cbFib macro shell, n
    exitm % shell(% n - 1) + shell(% n - 2)
endm

cbFac macro shell, n
    exitm % n * shell(% n - 1)
endm

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

newArray arrFib, 0, 1
newArray arrFac, 1, 1
memoizer fibonacci, <arrFib>, <cbFib>
memoizer factorial, <arrFac>, <cbFac>

ifdef n
    % echo fibonacci (n) factorial (n)
else
    % echo fibonacci(19) factorial(12)
endif
end
```

## milestones

2019.9.14 下午, 和[俞悦](https://github.com/josephyu19850119)讨论后做出下列修改, 并从 txt 改为 md

- (太费解) 删除令人费解的名词比如把 token 翻译为信物; 用 A.D. 表示公元后; css 术语 inline, block, inline-block
- (太吓人) 删除对续行的描述
- (太抽象) 重新把示例代码混入介绍, 早先是把这俩分开了; 建议是开头添加 hello world, 考虑之后在开头添加速成课
- (太误导) 明确对 610guide (Microsoft MASM 6.1 Programmer's Guide) 的引用: 用 "610guide" 代替 "本书"

2022.9.14 major rewrite in the hope of making a way better readability

2025.7.15 major rewrite
