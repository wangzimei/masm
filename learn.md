
- [A masm 16 bit dos program](#a-masm-16-bit-dos-program)
    - [end 的两个作用](#end-的两个作用)
    - [非空的段](#非空的段)
- [masm 命令行](#masm-命令行)
    - [文件编码](#文件编码)
    - [命令行选项](#命令行选项)
- [masm 语法](#masm-语法)
    - [段](#段)
    - [宏](#宏)
    - [% - expansion](#---expansion)
    - [assume - assumption](#assume---assumption)
    - [ptr - coercion](#ptr---coercion)
- [masm 编译错误](#masm-编译错误)
    - [LNK1190](#lnk1190)
- [x86](#x86)
    - [mnemonic](#mnemonic)
    - [storage](#storage)
    - [addressing](#addressing)
    - [interrupt](#interrupt)
- [x86 指令的等价表示](#x86-指令的等价表示)
- [dos](#dos)
    - [psp](#psp)
    - [启动](#启动)
    - [退出](#退出)
    - [dos api](#dos-api)
- [windows](#windows)
    - [crt](#crt)
    - [早期 crt 代码](#早期-crt-代码)
- [out](#out)
    - [omf, coff, mz, pe](#omf-coff-mz-pe)
    - [com 文件](#com-文件)
    - [查看二进制](#查看二进制)

---

## A masm 16 bit dos program

**汇编语言没有标准语法, 语法都是汇编器规定的**

masm 要求源文件具备两个要素: end 和非空的 segment; 这两个东西对生成可执行文件毫无贡献, 理由是:

- 如果程序啥都不做, 源代码应该啥都不需要写, 因此是个空文件, 而不是一个非空段 + end
- 非空段有意义的部分是使段非空的文本, 而不是段定义

masm 要求源代码从两个无用的结构开始, 预示了此后的 masm 编程道路上会遇到很多 masm 有意或无意制造的障碍.

我们先新建一个空文件 dd.msm, 让 masm 编译它, 看看会发生什么.

`ml -Foout\ dd.msm -Feout\` 输出如下
```
error A2088: END directive required at end of file
```

\* *-Fo 指定 ml 生成的 obj 的路径, 可以是目录; -Fe 指定连接得到的文件的路径, 可以是目录*

### end 的两个作用

- 结束源文件. 毫无意义的功能
- 后跟参数表示程序的起始地址, 即在源文件结束处用 end 指出起始地址. 让我想起那著名的 "点击 '开始' 以关机". 其作用 = link -entry
    - link 5.31.009 Jul 13 1992 没有 -entry 开关
    - ml64 不允许 end 后跟起始地址, 但和 ml64 配套的 link 有 -entry 开关

按照 masm 的要求给 dd.msm 加上 end

```
end
```

`ml -Foout\ dd.msm -Feout\` 输出如下
```
LINK : warning L4021: no stack segment
LINK : error L4076: no segments defined
```

可以看到 link 生成了 1 个警告和 1 个错误. 此处的亮点是尽管有连接错误, 仍然生成了 exe.

masm 认为程序应该有栈, 因此除非编译为 com (`ml -AT -Foout\ dd.msm -Feout\`) 否则警告 L4021; com 不报是因为 com 一定有栈.

错误说没定义段, 没说什么 "非空段" 所以下面代码似乎就够了?

```
xxx segment
xxx ends
end
```

编译发现错误信息完全没变, 因此光有段不行, 段还得非空. 是否还记得一开始说的 "毫无贡献"?

### 非空的段

按照 masm 的要求定义一个非空的段, 可以把此段标记为 stack 以消除连接警告, 此时程序是这样:

```
xxx segment stack
db 1
xxx ends
end
```

\* *segment 的语法在 8086/610guide/ch02.txt*

`ml -AT -Foout\ dd.msm -Feout\` 输出如下
```
LINK : warning L4040: stack size ignored for /TINY
LINK : warning L4055: start address not equal to 0x100 for /TINY
```

`ml -Foout\ dd.msm -Feout\` 输出如下
```
LINK : warning L4038: program has no starting address
```

com 的 L4055 是错的. 不指定起始地址等于指定第 1 条指令, com 文件前 100h 是 0, 第一条指令放在 100h; 运行的时候操作系统把
psp 放到前 100h 并从 100h 开始执行, 所以在 com 中第 1 条指令就是 0x100. 此时此警告的真实意思是 link 没看到起始地址.
如果指定的起始地址不是程序第一条语句则警告说的没问题, 这时候可以在起始地址前放 org 100h, 后果是起始地址前面的东西在运行时被 psp 覆盖.

因此要用 end 指定个标签. 把 db 1 改为正常的返回语句 (note1), 缩进, 得到下面的完整程序. `ml -Foout\ dd.msm -Feout\` 编译为 exe.
作为起始地址的标签定义到栈里面了; 一般不会往栈里放代码但也没啥问题, 想一想 com. 如果想用 `ml -AT -Foout\ dd.msm -Feout\`
编译为 com, 需要删掉 segment 后面的 stack.

**note1** 根据 8086/refs/stack.msm 知道 exe 运行时栈顶的 word 被改为 ff ff; 为防止覆盖那里的指令需要弄点填充字节.
写填充字节时为了确定填几个, 试了几个数值, 发现至少得 4 字节程序才正常退出, 但在 debug 里执行不正常; 用 debug
一看发现不仅是修改了最后两字节. debug out\dd.exe 时, 查看内存没啥问题; t 执行一句后再查看, 前 10 字节内容都变了.
加大填充的长度发现最后 10 字节会被修改; 隐约记得以前见过这情况. 因此要在 debug 里也能正常退出得填充 10 字节
(那填充 4 字节算不算正确?). mov ax, 4c00h/int 21h 是 5 字节, 为了对齐到 word, 填充了 11 字节, 否则起始 ip 是 1 而不是 0;
尽管我不知道起始 ip 是 1 有啥问题.<br>
**todo** 探究这个修改最后 10 字节的问题

```
xxx     segment stack
s:      mov     ax, 4c00h
        int     21h
        byte    11 dup (?)
xxx     ends
        end     s
```

\* *end 后面必须是标签不能是立即数 (字面量), 否则 error A2094: operand must be relocatable*<br>
\* *把变量名放 end 后面得到 error A2095: constant or relocatable label expected*

上面那个啥都不做的 masm 16 位 dos 程序包含 4 部分内容

- 为了正常编译, 写 masm 要求的 end begin
- 为了正常编译, 写 masm 要求的段
- 为了正常运行, 写 dos (?) 要求的填充字节. 不把代码放栈里时可省略本条
- 为了正常退出, 写 dos 要求的返回语句 mov ax, 4c00h/int 21h



## masm 命令行

### 文件编码

masm 的 source-charset 固定为 ascii; 串原样放入二进制, 相当于 execution-charset = source-charset;
无需转义字符, 因为指定字符时既可以用字面量也可以用数字, 字符字面量就是其 ascii 值.

### 命令行选项

(写这里时发现 dosbox 中命令超过一行而换行后, 没法把光标移回到上一行)

**对单个文件生效的开关必须规定个位置否则 file1 -xxx file2 不确定 -xxx 作用于谁**

masm 规定

- 对单个文件生效的开关放文件前
- 命令行开关和文件名都可以用引号括起来
- 双引号内 "" = "
- 以 - 打头的 token 是命令行开关; 因此编译文件 -coff 要写成类似 ml ./-coff

masm 命令行开关有 5 种作用范围
```
1. 其后的 1 个 token
-unrecognized switch    ml 6, 14; ml64 14

2. 其后的 1 个文件
-Fo         ml 6, 14; ml64 14
    ml -Foout\ cmdln/f1.asm -Foout\ cmdln/f2.asm -Foout\ cmdln/f3.asm -Feout\

3. 其后的所有文件
-coff       ml 6, 14. ml 14 default
-EP         ml 6, 14?; ml64 14?. 和 -Zs 相似在也不生成 obj
-omf        ml 14. ml 6 imply
-Zs         ml 6, 14; ml64 14. absorbs -c

4. 所有文件
-AT         ml 6
-c          ml 6, 14; ml64 14
-Fe         ml 6, 14; ml64 14

5. -link    ml 6, 14; ml64 14
```

我如何确定 -omf 作用于其后的所有文件?

- 以前听说过 omf 比 coff 内容简单, 体积也小
- 已经隐约发现了 -coff 是 ml 14 默认值, 但不清楚作用范围是单个文件还是其后的所有文件
- f1.asm 稍复杂; f2.asm 和 f3.asm 内容一样, 只有一句 end

ml 14 每执行一句, powershell format-hex out/xxx.obj 查看, 比较 obj 的内容
```
ml -Foout/ cmdln/f1.asm -Foout/ cmdln/f2.asm -Foout/ cmdln/f3.asm -Feout/
ml -Foout/ cmdln/f1.asm -Foout/ cmdln/f2.asm -Foout/ -omf cmdln/f3.asm -Feout/
ml -Foout/ cmdln/f1.asm -omf -Foout/ cmdln/f2.asm -Foout/ cmdln/f3.asm -Feout/
ml -omf -Foout/ cmdln/f1.asm -Foout/ cmdln/f2.asm -Foout/ cmdln/f3.asm -Feout/
```


https://github.com/MicrosoftDocs/cpp-docs/issues/1305<br>
https://github.com/MicrosoftDocs/cpp-docs/issues/1525




## masm 语法

### 段

8086, 8088, 80186, 80188 是 16 位寄存器和 20 位地址线 <https://en.wikipedia.org/wiki/RAM_limit>.
它们用 16 位段寄存器和 16 位通用寄存器保存两个数 seg 和 offset, seg * 16 + offset = 20 位地址.

masm 有关键字 segment (段), 前面演示了 masm 要求代码必须有段. 16 位程序里 segment 对应 16 位 cpu 的段;
32 位程序里 segment 对应可执行文件的节, 节对应内存的页; 节的一个作用是指出一段内存的读, 写, 执行属性.



**todo** diff on use32, flat<br>
https://stackoverflow.com/questions/45124341/effects-of-the-flat-operand-to-the-segment-directive


### 宏

/macros.md

### % - expansion

- 按当前的基数对常量表达式求值, 把得到的数字转为字符串
- 做为一行的首个非空白字符时, 展开该行的文本宏和宏函数; 用于 echo, title, subtitle, .erre 等把参数一律视为文本的指示.
    一律 - 包括 %, 常量表达式 - 视为文本, 就没法在它们的参数里调用宏或对表达式求值; 但又有这种需求, 于是 masm 说,
    既然宏展开符号 % 放 (比如 echo) 后面没戏, 那就放前面吧; 常量表达式的话你们就在外面赋值给文本宏, 别在里面求值了.
    masm 居然没有选择添加或规定转义字符, 真乃一大幸事.

masm 有个以 % 打头的指示, %out; 后来加了个 echo 用于取代其功能, 但 %out 那独树一帜的名字始终盘旋于我脑海之中.
%out 是个 4 字符的 token, 它就是能把 % 用作自己名字的一部分. 这 microsoft 做事也是随心所欲, 佩服!

### assume - assumption

为什么 microsoft 会发明这个关键字? 大概是在用 x86 编程时看到了太多的假设, 隐含, 暗指<br>
**todo** 列出 intel 有哪些假设

没啥意义的东西, masm 提供这个指示用来克服自己制造的困难.

### ptr - coercion

http://www.phatcode.net/res/223/files/html/Chapter_8/CH08-4.html<br>
看完网页后想看看是啥书, 一看是 Randall Hyde 的. 我记得以前照该书写过一些练习代码, 现在找不到了<br>
the art of assembly language programming

ptr 究竟是 intel 还是 microsoft 发明的? 网上没找到答案, x86 指令集里没有但反汇编里有, 所以应该是 intel.

x86 指令 ptr 用来解决这种问题: `mov [bx], 5` 时不知道 bx 指出的是 byte, word 或者其它,
所以用额外的指令 ptr 指出内存的长度: `mov word ptr [bx], 5`<br>
注意这里 intel 又开始取名字了. 没必要, mov2 [bx], 5 就行了. 理由: 1. mov word ptr 不是 mov; 2. byte word dword 有完没完?

```
debug
a
mov [200], byte ptr 3
mov [103], word ptr 3
mov word ptr [200], 3
mov [200], dword ptr 3
mov [200], qword ptr 3
mov tbyte ptr [200], 3
u
    c606000203      mov byte ptr [0200], 03
    c70603010300    mov word ptr [0103], 0003
    c70600020300    mov word ptr [0200], 0003
    c606000203      mov byte ptr [0200], 03
    c70600020300    mov word ptr [0200], 0003
    c606000203      mov byte ptr [0200], 03
```

可以看到

- ptr 可以写在任意操作数前面, 实际总是作用于内存
- (16 位 cpu?) 只能 ptr 为 byte, word; dword, tbyte 变成 byte; qword 变成 word. 这个完全看不出规律
- 数字在内存中的字节顺序

masm 要求显式重写段寄存器, `mov [200], word ptr 3` 要写为 `mov ds:[200], word ptr 3`.
用处不大, 访问内存默认的段寄存器是 ds, 不用 ds 时必须加前缀所以没啥歧义; 显式写出可能更没歧义?

masm 的变量, 假设有 `I byte ?`

1. 原来需要 ptr 的指令现在不需要了, `mov [200], byte ptr 3` 要写为 `mov I, 3`
1. 原来毫无歧义的语句现在必须用 ptr 添加重复信息了, `mov ax, [200]` 要写为 `mov ax, word ptr I`

情况 1 省了个 ptr, 但要求变量定义, 这再次表明: 静态类型增加程序员负担

```
; 假设有 xxx segment, model = tiny; tiny 是 com, 有 cs = ds = ss
assume ds:xxx ; 如果没有这句, masm 会在下句的前面用 cs 重写段寄存器, 机器码 2e
mov ax, word ptr i
```

ptr 是啥意思? 指针 pointer? 上面的用法和指针有啥关系? `word ptr [addr]` 实在是看不出和指针有啥关系.
你说 addr 是个指针? 那在 ptr 作用于 addr 这个指针前也先对指针用 [] 解除了引用, ptr 并没有作用于指针啊?
如果是 [word ptr addr] 还像点样子.

可能是为了凑点关系, masm 决定搞一个指针类型, 也使用关键字 ptr - 给 ptr 添加一个和指针有关系的用法.
这样一来 ptr 就有两种不同的用法了: 一种是 word ptr, 另一种是 ptr word... 就问你佩不佩服?<br>
**todo** 待续

Randall Hyde 把这个操作叫 coercion; 后来有一天我搜索网页发现这种意见: 要么叫 conversion 要么叫 cast, 就是不叫 coercion.
不愧是 c++: 不断的制造惊喜, 不断的否定你过往的经验; 简而言之不断的恶心你.

奇文共赏 c++ | https://stackoverflow.com/questions/8857763/what-is-the-difference-between-casting-and-coercing
---|---
conversion | implicitly/explicitly changing a value from one data type to another
coercion   | implicit conversion
cast       | explicit type conversion, may be a re-interpretation of a bit-pattern or a real conversion


## masm 编译错误


## LNK1190


fatal error LNK1190: 找到无效的链接地址信息，请键入 0x0001

If you use PEview to look into the OBJ file, and Type 0x0001 is referring to IMAGE_REL_I386_DIR16 (usually
should be 0x0006 IMAGE_REL_I386_DIR32), then you should be able to see at least one of these in the
IMAGE_RELOCATION records. The symbol name and RVA are also displayed which should help narrow things down.
wjr April 15, 2014, 07:06:37 AM
http://masm32.com/board/index.php?topic=3114.0

## x86



### mnemonic


### storage

有时候我把存储叫做内存, 但在这里这么叫的话容易混淆

cpu 经常和 3 种存储打交道

- 寄存器
- 内存
- 寄存器 + 内存: 栈. ss:sp 保存一个内存地址, 称作栈顶, push, pop, call, retn, retf, int, iret 隐含使用栈


### addressing

mapped memory, pci memory hole

内存地址有一部分指向 rom 和外设的内存, 这部分地址对应的 ram 无法访问

in, out

外设的寄存器称作端口, 用 in 和 out 指令读写

显然内存映射和端口可以只保留一个; 由于端口数量很少, 要删最好把端口删了

要解决内存洞, 理论上别装满内存就行, 因为内存洞的原因是地址的一部分没给内存用; 实际上总是映射到固定地址导致不好避开


映射内存和端口不是 intel 决定的 (那是谁? ibm? pci 规范是谁整的?), intel 只是让 cpu 支持它们

```
; 代码示例
;
; 通过 bios 间接访问硬件
; 输入 - 访问 端口xxx?? 读取键盘
; 输出 - 访问映射到地址 xxx??? 的屏幕缓冲区
```



### interrupt

## x86 指令的等价表示

由于 intel 的限制, 等号后的代码不一定能执行, 只起解释作用

intel 不允许 ip/eip/rip 做为指令的操作数, 指令寄存器通过 jmp, call, ret 间接修改, 下面有读取的例子<br>
\* *arm32 允许读写 ip, arm64 不允许*<br>
\* *8086, 8088 允许 pop cs, opcode 0x0F*

https://www.keycdn.com/support/http-equiv<br>
HTTP response header equivalent, http-equiv = treat this meta as if it were in http response header

```
https://stackoverflow.com/questions/4292447/does-ret-instruction-cause-esp-register-added-by-4

retn = pop eip
retf = pop eip/pop cs

to avoid add esp, 4, you can use `mov eax, [esp]/jmp eax`

jmp rel_offet       = add eip, rel_offet
jmp absolute_offset = mov eip, absolute_offset

pop register = mov register, [esp]/add esp, 4

https://stackoverflow.com/questions/46714626/does-it-matter-where-the-ret-instruction-is-called-in-a-procedure-in-x86-assembl

; slow alternative to "jmp label"
jmp continue_there_address =
    push continue_there_address
    ret
    continue_there_address:

https://stackoverflow.com/questions/8333413/why-cant-you-set-the-instruction-pointer-directly

call get_eip
    get_eip:
pop eax ; eax now contains the address of this instruction
```

## dos

如果是写个程序转为机器码后直接让 cpu 执行 (无配合), 那写法比较随意, 没有什么顾忌;<br>
如果是写个程序在操作系统中执行, 那就至少得照顾操作系统的死活, 即遵守操作系统的规定.

### psp

https://en.wikipedia.org/wiki/Program_Segment_Prefix

psp = Program Segment Prefix, dos 使用这个数据结构存储程序状态, 类似 CP/M 里的 Zero Page.

com, exe 开始执行时 ds = es = seg psp. int21h/ah51h 和 int21h/ah62h 也可以获取 psp, 结果放在 bx.


dos 1

- 退出需要调用 int20h 或 int21h/ah0, 两者功能一样, 前者机器码较短
- int20h 的参数是 cs, 要求 cs 指向 psp 所在的段 (seg psp)
- psp 的前两个字节是 int20h
- 程序开始时 ds = es = seg psp

所以退出的办法是开始时 push ds/push 0, 结束时 retf, push 0 可以是 xor ax, ax/push ax<br>
com 在保证 cs = seg psp 时可以直接 int20h 或者 int21h/ah0

dos 2+

- 添加了退出方式 int21h/ah4ch, 该 api 不要求 cs = seg psp

https://stackoverflow.com/questions/12591673/whats-the-difference-between-using-int-0x20-and-int-0x21-ah-0x4c-to-exit-a-16<br>
这里说用 retn 结束时不需要 push 任何东西, 因为程序开始时的栈顶是 0<br>
我也记得 com 文件初始 sp 是 fffe, 而 fffe 和 ffff 都是 0<br>
因此, com 程序设计的退出办法应该是在 cs 未改变的前提下结束时直接 retn, 这导致 `ip = *(word*)0xfffe`

非 dos 不一定有 psp http://www.tavi.co.uk/phobos/exeformat.html

本节后面的程序打印命令行参数 - cp/m, dos 称作 command tail. 修改了 psp 的一个字节, 改为 $

`ml -AT -Foout\ dd.msm -Feout\`

命令尾如果全是空白字符则长度是 0, 否则长度包含空白

```
out\dd     ddd  --x
     ddd  --x
```

`debug out\dd.com` 反汇编内存中 psp.com 程序 100h 开始的 20h 字节: `-u`

`cv out\dd.com`

### 启动


dos 程序启动时, com 的 ip = 起始地址 = 100h; exe 的等于代码指定的起始地址
http://www.fysnet.net/yourhelp.htm
```
The following are the register values at DOS .COM file startup in the given DOS brands and versions
...
```

http://www.tavi.co.uk/phobos/exeformat.html
```
register contents at program entry:
    Register    Contents
    AX          If loading under DOS: AL contains the drive number for the first FCB 
                in the PSP, and AH contains the drive number for the second FCB.
    BX          Undefined.
    CX          Undefined.
    DX          Undefined.
    BP          Undefined.
    SI          Undefined.
    DI          Undefined.
    IP          Initial value copied from .EXE file header.
    SP          Initial value copied from .EXE file header.
    CS          Initial value (relocated) from .EXE file header.
    DS          If loading under DOS: segment for start of PSP.
    ES          If loading under DOS: segment for start of PSP.
    SS          Initial value (relocated) from .EXE file header.
```

### 退出

dos 程序退出时要调用规定的 dos 函数; windows 程序退出时要调用 ExitProcess

- int20h          dos 1+, int21h/ah0 的别名, 机器码更短, 用来放在 psp 的前两个字节
- int21h/ah0      dos 1+, 参数 cs = seg psp
- retn/retf       dos 1+, 意图是执行 psp 的前两个字节 (int20h)
- int21h/ah4ch    dos 2+, 无参数

```
ml -DcomRetn -Foout\ dd.msm -Feout\
-DcomRetn     注意到初始 sp=fffe, fffe 和 ffff 处都是 0, 这时 retn 可以使用这两个字节当 ip,
              若又有 cs = seg psp 则 retn 导致执行 psp 0000 处开始的机器码.
              不知道这方法是否可靠, 即不知道栈是否总是保留两个字节的 0
-DcomRetf     错误的写法, retf 使用栈上的 2 个 word 而栈上只有 1 个. 执行后 dosbox 不接受输入, 只能重启 dosbox
-DexePushRetf 正常做法, 保存 seg psp 和 0, retf 总是能执行. 当然更正常的做法是 int21h/ah4ch
```
```
ifdef comRetn
    .model tiny
    .code
    org 100h
    start:
    retn
elseifdef comRetf
    .model tiny
    .code
    org 100h
    start:
    retf
elseifdef exePushRetf
    .model huge
    .stack
    .code
    start:
    push ds
    xor ax, ax
    push ax
    retf
else

xxx     segment

        org     100h
start:
; psp 80h       1 byte      Number of bytes of command-line tail
; psp 81h-FFh   127 bytes   Command-line tail (terminated by a 0Dh)

; INT 21h subfunction 9 requires '$' to terminate string
        xor     bx, bx
        mov     bl, ds:[80h] ; masm 认为 [80h] 是 80h (注 1)
        cmp     bl, 7Eh
        ja      exit ; 命令行长度至多 7eh
        mov     [bx + 81h], byte ptr '$'

; print the string
        mov     dx, 81h
        mov     ah, 9
        int     21h

exit:
        mov     ax, 4C00h
        int     21h

xxx     ends

endif
        end     start

注 1: 后来看到这帖子
https://stackoverflow.com/questions/25129743/confusing-brackets-in-masm32
masm 根据它的规则修改你的代码
- variable name               无论方括号, 一律认为是变量的值
- constant, const expr, imm   无论方括号, 一律认为是立即数
- register                    不修改方括号的意义
这个编译器会修改你的代码. 我能理解错不全在 masm, 你看它修改的大都是他自己规定的玩意儿: 变量, 常量,
常量表达式, 除了立即数. 因此要说代码被修改了你自己也有问题, 因为你用它提供的结构了; 我想很难反驳吧?
```

### dos api

dos 的 api 调用就是 int

```
int20h - DOS 1+ - TERMINATE PROGRAM
http://www.ctyme.com/intr/rb-2471.htm
Entry: CS = PSP segment
Return: Never

in21h
http://spike.scu.edu.au/~barry/interrupts.html

int21h/ah0 - DOS 1+ - TERMINATE PROGRAM
http://www.ctyme.com/intr/rb-2551.htm
Entry: CS = PSP segment
Notes: Microsoft recommends using INT 21/AH=4Ch for DOS 2+. This function sets the program's
return code (ERRORLEVEL) to 00h. Execution continues at the address stored in INT 22 after
DOS performs whatever cleanup it needs to do (restoring the INT 22,INT 23,INT 24 vectors from the
PSP assumed to be located at offset 0000h in the segment indicated by the stack copy of CS, etc.).
If the PSP is its own parent, the process's memory is not freed; if INT 22 additionally points into
the terminating program, the process is effectively NOT terminated.
Not supported by MS Windows 3.0 DOSX.EXE DOS extender

int21h/ah2 - WRITE CHARACTER TO STANDARD OUTPUT
Entry: DL = character to write
Return: AL = last character output
Notes:
    ^C/^Break are checked
    the last character output will be the character in DL unless DL=09h on entry, in which case AL=20h
    as tabs are expanded to blanks if standard output is redirected to a file, no error checks
    (write- protected, full media, etc.) are performed

int21h/ah9
Entry: DS:DX -> '$'-terminated string
Return: AL = 24h

int21h/ah4ch - "EXIT" - TERMINATE WITH RETURN CODE
Entry: AL = return code
Return: never returns
Notes: unless the process is its own parent, all open files are closed and all memory belonging to
    the process is freed
mov ax, 4c00h/int 21h 就是 return 0
```

## windows

**入口**

coff 希望入口标签以下划线开头, warning A4023:with /coff switch, leading underscore required for start address

link 需要 -subsystem, 没有指定时尝试从入口标签推导它, 规则是

- _main 是 console, _WinMain@16 是 windows, 区分大小写; 16 位汇编常用的 start link 不认
- 入口不是上面的两个标签时报错 LINK : fatal error LNK1221: 无法推导出子系统，必须定义它

**段属性**

- 16 位程序所有内存都是可执行-读写; 32 位 pe 的段对应节 (section), 具有单独的执行, 读, 写属性
- 32 位程序的段需要标记为 flat

**节属性**

- link 认识段名 _TEXT 和具有 "code" 类的段, 对应的节的属性是可执行-只读
- link 认识段名 _DATA, _DATA 和 link 不认识的段对应的节的属性是不可执行-可写
- editbin 可以修改节的属性

> http://masm32.com/board/index.php?topic=602.15 sinsi August 22, 2012, 06:36:17 PM<br>
> .code expands to "_TEXT segment public"<br>
> .data expands to "_DATA segment public"<br>

**windows api** proto near32 stdcall

**退出** 有地方说要用 ExitProcess; 我用 ret 指令看似也正常, 但不知道想返回值的话该咋做

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
s       byte    "32 bit program compiled with masm <insert @version here>"
dwd     dword   ?
data    ends

        end     _main
```

### crt

windows crt 程序属于 win32 程序, crt 有额外要求

**入口**

- crt 连接 crt lib, 这里面有入口, 所以使用 crt 的程序 end 不能后跟标签
- crt 入口要以 cdecl 调用 _main, 所以要么在程序里定义 `main proc c`, 要么定义 public 标签 _main

**c 运行时函数** proto near32 c, 既然是 cdecl, 调用方要清理栈

```
; 从命令行编译时需要 includelib msvcrt.lib
; 从 visual studio 2019 编译时不需要 lib, 因为它给 link 传了一堆 lib
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

### 早期 crt 代码

早期的 crt/puts 代码使用简化段, 现在不使用简化段. 那种 .code 的写法看着就不舒服.

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







## out

### omf, coff, mz, pe

https://en.wikipedia.org/wiki/Comparison_of_executable_file_formats

omf

- https://en.wikipedia.org/wiki/Relocatable_Object_Module_Format
- Relocatable Object Module Format (OMF) 是对象文件的一种格式, 主要用于在 intel 80x86 上运行的软件
- 源于 intel 开发的\[when?] Object Module Format, dos 用户熟悉的 .obj 文件就是此格式
- MS-DOS, 16-bit Windows, 16/32-bit OS/2 上最重要的对象文件格式
- masm 6.11 生成 obj 默认 omf, 可以用 -coff 选项生成 coff

coff

- https://en.wikipedia.org/wiki/COFF
- Common Object File Format (COFF) 是 executable, object code, and shared library 的格式, 用于 Unix 系统
- 在 Unix System V 里取代了 a.out 格式
- base of XCOFF and ECOFF
- 很大程度上被 SVR4 的 ELF 取代
- coff 及其变种继续用在一些 Unix-like 系统, Microsoft Windows (PE Format), EFI 环境和一些嵌入式开发系统
- masm 14 生成 obj 默认 coff, -coff 和 -omf 选项生成对应格式的 obj

mz

- https://en.wikipedia.org/wiki/DOS_MZ_executable
- dos 的 exe 文件格式, 开头的两个字节是 4D 5A, ascii M Z
- 是 16 位 exe, 比 com 格式新

pe

- https://en.wikipedia.org/wiki/Portable_Executable
    Portable Executable (PE) 格式是 executables, object code, DLLs, FON Font 等文件的格式, 用于 32/64 位 windows
- https://blog.kowalczyk.info/articles/pefileformat.html
    为兼容 msdos 和旧版 windows, pe 保留 mz 头
- 类比名字, pe 应该是 pef, 就像 omf, coff; 类比系统, elf in Linux and most other versions of Unix; Mach-O in macOS and iOS

pe 的 mz 头后面是个 16 位 dos 存根程序, 一般显示:

```
(Borland tlink32)   This program must be run under Win32.
(ms link?)          This program cannot be run in DOS mode.
(???)               This program requires Microsoft Windows.
```

pe 的 dos 存根 https://thestarman.pcministry.com/asm/debug/DOSstub.htm

### com 文件

https://en.wikipedia.org/wiki/COM_file

演变

- Digital Equipment operating systems, 1970s: .COM was used as a filename extension for text
    files containing commands to be issued to the operating system (similar to a batch file)
- cp/m: executable
- dos: executable

特点

- max size = 65,280 (FF00h) bytes (256 bytes short of 64 KB)
- stores all its code and data in one segment
- entry point is fixed at 0100h

\* *com 和 exe 在执行时可以通过动态链接等技术任意使用内存.*

dos 和 cp/m 的 com 文件结构虽然一样但互不兼容. dos 文件包含的是 x86 指令和 dos 系统调用;
cp/m 文件包含 8080 指令和 cp/m 系统调用, 特定于机器的程序可能还会有 8085, Z80 指令

fat binary

- https://en.wikipedia.org/wiki/Fat_binary
- 基本上是把多个功能一样的程序放到一个文件里, 开头的代码选择使用其中一个
- 开头的代码即入口代码, 是在几个系统中都有效但功能不同的指令, 在不同的系统中执行有不同的效果, 比如
    `C3h, 03h, 01h` 在 x86 上是 `ret`, 在 8080 上是 `JP 103h`

bat 文件可能使用命令的全名, win nt 为兼容这些 bat, 下列 exe 文件仍以 .com 结尾:<br>
DISKCOMP, DISKCOPY, FORMAT, MODE, MORE, TREE<br>
作为 exe, 它们的文件开始俩字节是 MZ, 操作系统能认出来并按 exe 执行.

执行命令时如果省略扩展名, dos 先找 com 再找 exe, 比如 foo, 找 `foo.com` 或 `foo.exe`.
win nt 环境变量 PATHEXT 可以指定扩展名顺序, 默认仍然是 com 先于 exe

```
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
```

### 查看二进制

查看生成的 obj

```
# powershell
format-hex out/readme.obj

# macos 常用 hexdump, od, xxd
xxd out/readme.obj
```




