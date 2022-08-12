
- [x86](#x86)
    - [mnemonic](#mnemonic)
    - [内存地址空间](#内存地址空间)
    - [run](#run)
    - [interrupt](#interrupt)
    - [x86 指令的等价表示](#x86-指令的等价表示)
- [dos](#dos)
    - [psp 和退出](#psp-和退出)
    - [dos api](#dos-api)
    - [omf, coff, mz, pe](#omf-coff-mz-pe)
    - [com 文件](#com-文件)
- [a 16 bit dos program in masm](#a-16-bit-dos-program-in-masm)
    - [end 的两个作用](#end-的两个作用)
    - [非空的段](#非空的段)
    - [the program](#the-program)
    - [起始地址](#起始地址)
- [masm 命令行](#masm-命令行)
    - [源文件编码](#源文件编码)
    - [命令行选项](#命令行选项)
- [masm 语法](#masm-语法)
    - [ptr - coercion](#ptr---coercion)
    - [ret, retn, retf](#ret-retn-retf)
    - [段](#段)
    - [assume](#assume)
    - [宏](#宏)
    - [% - expansion](#---expansion)
- [masm 编译错误](#masm-编译错误)
    - [A2076](#a2076)
    - [LNK1190](#lnk1190)
- [16 bit dos masm 程序示例](#16-bit-dos-masm-程序示例)
    - [从 psp 获取程序的命令行参数](#从-psp-获取程序的命令行参数)
    - [hello world](#hello-world)
    - [int 20h](#int-20h)
- [windows](#windows)
    - [crt](#crt)
    - [早期 crt 代码](#早期-crt-代码)

---

## x86

### mnemonic

汇编语言没有标准语法, 汇编器在 cpu 厂商提供的 mnemonic 语法基础上创造自己的语法.

```
            masm directives  - mnemonic + arguments (see below) and infos
            /                                                           \
source code                                                                 obj file
            \                                                           /           \
            mnemonic + arguments    -   opcode + arguments = machine code
                        \                           /                               executable
                    mnemonic + typeof arguments = opcode
                                                                                    /
                                                                            obj file
```
例子
```
debug
a
mov [200], byte ptr 3
mov [103], word ptr 3
u
    c606000203      mov byte ptr [0200], 03
    c70603010300    mov word ptr [0103], 0003
    ...
q
```

有 2 种方法理解 `c606000203 mov byte ptr [0200], 03`
1. 从 http://ref.x86asm.net/coder32-abc.html 找指令 mov.
`byte ptr [0200]` 是 8 位内存, 03 是立即数, 查看网站, 发觉 8 位内存应该对应 m8; 立即数自然也是 8 位, 应该对应 imm8. 于是找 move m8, imm8, 找到这条 `MOV r/m8 imm8 C6`
1. 从 http://ref.x86asm.net/coder32.html 找操作码 c6. 我不确定 c6 是操作码还是前缀, 但网页已经区分了它们. 找到 `MOV r/m8 imm8`

这就解释了反汇编的 c6. 表格有个列 o, mov 在该列中的数字是 0, 不知啥意思.

c6 后的 06 啥意思? 通过下面网页猜测应该是 modr/m 字节,<br>
https://stackoverflow.com/questions/8518917/x86-mov-opcode-disassembling<br>
于是回到 ref.x86asm.net 查看, 在 16-bit ModR/M Byte 节看到张表, 这表把 modr/m 字节分成 3 部分: 最上面的 reg/opcode 占 3 位, mod 列占 2 位, r/m 列占 3 位. 值 6 的周围如下:

```
                                000
Effective Address   Mod R/M     Value of ModR/M Byte (in Hex)
disp16              00  110     06
```

表把 06 = 00000110b 分解成 3 部分 mod = 00, reg = 000, r/m = 110

因此这个 06 作用是让 `mov r/m8 imm8` 把第 1 个参数视为指向 m8 的 disp16, 从而从 000203c706030... 中取前 16 位, 即 0002, 做为常量偏移; 而由于是 imm8, 随后的一个字节即 03 是第 2 个参数

按这些知识看 `c70603010300 mov word ptr [0103], 0003`. c7 查表得 `C7 MOV r/m16/32 imm16/32`. 既然用了 16-bit ModR/M Byte 的表, 可以排除 mov 的 32 位参数 m32 和 imm32, 得到 `mov r/m16 imm16`; 前面知道 6 是 disp16, 排除 mov 第一个参数里的 r, 得到 `mov m16 imm16`. 所以 03010300 的第一个 16 位是数据的地址, 数据长度是 m16 = 16 位 = 2 字节; 第二个 16 位是 imm16.

可以看到助记符需要知道内存和立即数的长度, 但不需要知道寄存器和地址的长度, 它俩在语境里有**隐含**的唯一长度.

**byte code**

有些编译器把代码编译为字节码, 由该语言的虚拟机执行. 比如 java.

**microcode**

a.k.a. μcode, 完全位于 isa (instruction set architecture) 的一侧, 汇编看不到<br>
https://en.wikipedia.org/wiki/Microcode

不是每种 cpu 都有 microcode

以前的机器语言就是 cpu 执行的语句, 语句定义在 isa 里. 后来 (around 1950) 可能是指令复杂了, 或想兼容以前的代码 (从而不可移植的汇编也可移植了), 或任何原因, 机器语言要翻译为 microcode 让 cpu 执行, 这就把机器语言变成高级语言了. microcode 各方面都和汇编差不多.

**micro-operation**

https://en.wikipedia.org/wiki/Micro-operation

a.k.a. micro-ops, μops, micro-actions

主要是 intel 用, 前面说的 microcode 有很多厂商都用

### 内存地址空间

感觉有两个联系紧密的概念: 寻址 (addressing) 空间指 cpu 能访问的内存范围; 地址 (address) 空间指对方提供的内存范围; cpu 能看到啥取决于对方提供啥. 但似乎又没必要区分它们.

8086 通过共用的 20 位地址总线和 16 位数据总线获取内存的数据, 总线提供啥它就看到啥. 当时 ibm pc 只有 64k 的内存, 据此设计了 1m 地址空间的 pc 规范, 给此空间的 3 个部分取了名字, 设想了用法. intel 和 ibm 都使用 1m 这个数字不大可能是巧合, 不知道是谁配合谁.

https://en.wikipedia.org/wiki/Conventional_memory<br>
https://en.wikipedia.org/wiki/High_memory_area

```
a       4g                                  -
 d
  d     1088k           -           extended memory
   r            high  memory area (HMA)
    e   1m              -                   -
     s          upper memory area (UMA)
s     s 640k            -                   -
 p
  a     64k             -           conventional memory area
   c            low memory area
    e   0               -                   -


prove   640k = 0xa0000
given   1024 = 1k
thus    0x10000 = 65536 = 64 * 1024 = 64 * 1k = 64k
thus    0xa0000 = 0xa * 0x10000 = 10 * 64k = 640k
```

更详细的讲解在 https://wiki.osdev.org/Memory_Map_(x86)

**内存地址映射**

640k ~ 1024k 这 384k 是 uma, 指向 rom 和 "外设的内存", 不指向内存. cpu 访问这些地址时读写都会映射过去, 写对 rom 无效. 这种把内存地址挪作他用的行为叫内存地址映射. 假设安装了大于 640k 的内存, 大于 640k 的那部分由于没有地址而没法访问; 大于 1m 的内存也没有地址, 没法访问. 如果寻址大于 1m, 则在想象中, 多于 640k 的那部分内存可以分配 1024k 之上的地址, 不会浪费内存. 但总的来说, 除非内存小于寻址能力, 否则就会浪费内存. 如果 cpu 看到的 1m 连续内存是不连续的两部分 [0, 640k] 和 [1024k, 1408k], 那第 2 段内存的地址还是不是 "真实地址"? 我感觉是, 因为虽然内存是连续的, 但给它分配什么样的地址是另一码事.

有些 (全部?) 非 ibm pc 也采用了类似的内存地址映射.

highlights of https://wiki.osdev.org/Detecting_Memory_(x86)
```
? How does the BIOS detect RAM
! by running relevant code from ROM
? reclaim the memory from 0xA0000 to 0xFFFFF
! almost impossible
? is there also memory hole just below 4GB
! sure
```

**80286**

1982 年的 80286 发明了第 2 种内存分段模式, 支持虚拟内存和内存保护. 这时 intel 把这种模式叫保护模式, 把 8086 用的模式叫实模式.

https://en.wikipedia.org/wiki/Expanded_memory<br>
https://en.wikipedia.org/wiki/Bank_switching

虽然 286 保护模式寻址 16m, 386 保护模式寻址 4g, 但一方面 286 不够方便, 另一方面 16 位实模式 dos 及软件用户众多, 所以 16 位 dos 仍然活跃了好几年. 这段时间 (around 1985) 出现了几种从 uma 区域增加可用内存的办法

- 通过软件或自定义的地址解码器, 让内存使用 vga, ega 的地址
- 想象: 往 vga 槽上插一块伪装成 vga 的内存行不行?
- 运行于 386 的内存管理器软件, 比如 QEMM, 或 DR-DOS 的 MEMMAX (+V)
- 其他自定义硬件
- 控制台重定向, 以释放 uma 里除最后一块 64k 之外的所有块

下面的 ems 和 xms 实际上增加了地址的宽度, 从而扩大可以访问的地址范围

- Expanded Memory Specification (EMS)
    - 4 * 16k pages = 64k window, located in the uma
    - **bank switching**: 在内存里划出个窗口, 此窗口的内容截取自另一块内存 - **expanded memory**, 通过开关控制截取的范围<br>
    - expanded memory 往往是前述的自定义硬件, 占用某块 64k uma 地址, 实际具有较大的内存
    - Expanded Memory Adapter (XMA) 是 ibm 的 expanded memory 规范
- eXtended Memory Specification (XMS)
    - copy extended memory to anywhere in conventional memory
    - 也使用 bank switching, 和 ems 的区别是
        1. 窗口放在 low memory area
        1. 窗口内容取自 286 或 386 的 extended memory
    - 加载 extended memory 时需要 cpu 切换至保护模式

bank switching 和 paging 的区别: 前者数据仍在原地, 只是不再对应 cpu 能访问的地址; 后者把数据挪走了, 比如内存里的数据交换至硬盘.

**high memory area (HMA)**

segment:offset 能表示的地址范围是 [0, 0x10,ffef]. 8086 20 位地址线至多能寻址 0xf,ffff, 多余部分会绕回到开头, 比如 ffff:10 = 10000:0 是 21 位, 20 位只能看作 0000:0; 而 286 24 位地址线, 就能访问 10000:0. 286 实模式用 segment:offset 能访问的内存比 8086 多出的 [0x10,0000, 0x10,ffef] 这 fff0 字节, 叫 high memory area.

在 286 上运行的 8086 程序如果依赖 20 位地址线造成的绕回就会出错, 286 就设计了一条指令控制第 21 条地址线 - a20 - 是否启用. 不启用时第 21 条线总是 0, 就有绕回的效果.

286 的 dos 把好多代码放在了 hma 以空出更多的常规内存给程序用, 这些代码专为 hma 设计, 理解 segment:offset 在 21 根地址线上的范围, 不会假设地址绕回.

**dos extender**

https://en.wikipedia.org/wiki/DOS_extender

在 32 位操作系统流行之前还出现了 dos extender (1980s), 基本就是个操作系统. 使用 386, 允许访问 16m 内存, 加载的程序运行于保护模式, 但可以调用 dos api. 主要用在游戏里.

**pci memory hole**

https://en.wikipedia.org/wiki/PCI_hole

只要使用内存映射就会占据内存地址. 16 位实模式 cpu 拥有 20 位地址线, 能访问 1m 内存地址, 384k 映射给了外设; 32 位保护模式 cpu 拥有 32 位地址线, 能访问 4g 内存地址, 0.5 ~ 1.5g 映射给了外设. 这次的不同之处是

- 映射的大小不固定了, 384k v.s. 0.5 ~ 1.5g
- 保护模式下的用户代码在 cpu 和操作系统的合作下变成了 "ring3" 等级, 不能访问硬件了, 自然就不再有自定义硬件
- 有些 bios 可以改变内存或硬件映射的地址范围

intel 拿出以前的解决方案, pentium pro 的 Physical Address Extension (PAE) 让 ring0 程序能访问 36 位地址, ring0 基本都是操作系统. 操作系统为了自己方便 (*) 完全控制硬件, 要求硬件厂商提供配套的驱动程序, 为了使用 intel 的 pae, 需要 x86 和 x64 之外的 pae 版本驱动程序. microsoft 怕麻烦干脆不再支持 pae.

\* 也有个较小的可能是 cpu 提供不了操作系统需要的特性

cpu 运行在 64 位模式时可以用 bios 改变硬件映射的地址或者把内存映射到被占据地址之后的地址. 不过意义何在? 64 位地址范围充足, 很难出现内存分配不到地址的情况.

**端口**

`in  port, data` 和 `out port, data`

端口指有些外设的寄存器, 端口地址是 16 位, 总共 64k = 65536 个. 端口和映射的内存一样用于访问外设, 不占用内存地址空间; 或者说端口的地址空间是 64k.

有说法是端口和内存复用地址空间, 因为访问端口和内存都通过地址数据总线, 由开关切换访问谁. 我认为这只是实现细节, 地址空间是两个, 不存在复用; 从代码上看内存和端口的区分很明显, 应该很难把两个地址空间搞混. 访问端口时, 用 in 串行读取单个地址, out 串行写入单个地址; 访问映射的内存时, 用 mov data, mem 依次 (也是串行) 读取一组地址, mov mem, data 依次写入一组地址.


```
; todo or delete? 代码示例
;
; 通过 bios 间接访问硬件
; 输入 - 访问 端口xxx?? 读取键盘
; 输出 - 访问映射到地址 xxx??? 的屏幕缓冲区
```

**内存 + 寄存器: 栈**

ss:sp 保存的内存地址称作栈顶. push arg 从 sp 减去 sizeof arg, 然后把 arg 写到栈顶

push, pop; call, retn, retf; int, iret **隐含**使用栈

### run

1. 查看 cs:ip 指向的内存处的字节
1. 根据那个字节确定指令长度, 设 = n
1. ip += n
1. 执行指令
1. loop

intel 不让直接修改 cs 和 ip, 只让通过 jmp, jcc; call, retn, retf; int, iret 间接修改

### interrupt

按设计, cpu 每执行一条或一组指令就查看是否有中断请求, 有的话就暂停当前执行的指令去执行请求指出的指令, 执行完可能会继续执行之前暂停的指令.

intel 为 interrupt 占用了一堆名词: hardware interrupts, software exceptions (faults, traps, aborts); arm 也划拉了一个: reset.

`cli` 让 cpu 此后不响应可屏蔽中断<br>
`mov ss, reg` 此指令的下一条指令无法中断, 用于在 mov ss 之后 mov sp

总共 256 种中断, 硬件中断由 8259 把 irq 映射到 int n, cpu 也能引发中断, int n(0 ~ 255) 指令也能引发中断; 所有 256 种中断都能用 int n 从代码里引发. cpu 决定处理中断时, 从内存地址 n * 4 处取 1 个 word 放入 ip, n * 4 + 2 处取 1 个 word 放入 cs, 跳过去, 因为按约定那里就是 n 号中断的处理程序.

https://wiki.osdev.org/Interrupt_Vector_Table
```
memory
-           1024 = 1k = 0x400
real mode Interrupt Vector Table (IVT)
-                   0
```

用 debug 把内存 0:0 开始的 1k 字节打印到文件
```
> fff debug

* 由于输出重定向到了文件, 下面输入导致的回显都不出现在屏幕上
* 按 q 回车退出后查看文件 fff

d 0:0 3ff
q
```

https://alex.dzyoba.com/blog/os-interrupts/<br>
Interrupt descriptor table (IDT) since 80286 protected mode

https://wiki.osdev.org/Interrupts<br>
LIDT 指令可以改变 ivt 的默认位置 0:0, 但很少用

### x86 指令的等价表示

由于 intel 的限制, 等号后的代码不一定能执行, 只起解释作用

intel 不允许 ip/eip/rip 做为指令的操作数, 指令寄存器通过 jmp, call, ret 间接修改, 下面有读取的例子<br>
\* *arm32 允许读写 ip, arm64 不允许*<br>
\* *8086, 8088 允许 pop cs, opcode 0xf = 15*

https://www.keycdn.com/support/http-equiv *wtf is this for?*<br>
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
                                push continue_there_address
jmp continue_there_address  =   ret
                                continue_there_address:

https://stackoverflow.com/questions/8333413/why-cant-you-set-the-instruction-pointer-directly

call get_eip
get_eip:
pop eax ; eax now contains the address of this instruction
```

## dos

dos 的单任务指所有程序依次执行. 启动 dos 后执行 command.com; 在 command.com 里启动程序后执行该程序; command.com 保留的内存, 硬盘等各种存储都还在, 但不再执行它的代码, 相当于暂停; 程序退出后继续执行 command.com.

多任务有多种可能. 可能是单个 cpu 把时间分成小段, 轮流执行每个段里不同程序的代码; 也可能是多个 cpu 把时间分成小段, 执行不同程序的代码; 也可能是多个 cpu 各自执行不同程序的代码. 不清楚细节.

为让 dos 正常运行, 程序要解决和操作系统 (dos 或者说 command.com) 的衔接问题. 启动时 dos 做一些准备工作之后从程序的入口开始执行, 进入程序时准备工作已经完成了, 程序不用帮忙. 退出时得有种办法继续执行 dos, 不应该每次退出程序都重新启动 dos, 本质就是跳到 dos 暂停时的代码处继续执行.

### psp 和退出

psp = Program Segment Prefix. dos 在执行 com 和 exe 时使用这个数据结构存储程序状态, 类似 CP/M 里的 Zero Page.

[示例: 从 psp 获取程序的命令行参数](#从-psp-获取程序的命令行参数)

dos 1

- 退出需要调用 int21h/ah0, 它**隐含**使用 cs, 要求 cs 指向 psp 所在的段 (seg psp)
- int20h 是 int21h/ah0 的别名, 机器码更短
- psp 的前两个字节是 int 20h
- 程序开始时 ds = es = seg psp

https://stackoverflow.com/questions/12591673/whats-the-difference-between-using-int-0x20-and-int-0x21-ah-0x4c-to-exit-a-16<br>
这里说用 retn 结束时不需要 push 任何东西, 因为程序开始时的栈顶是 0; 我也记得 com 文件初始 sp 是 fffe, 而 fffe 和 ffff 都是 0; 因此在 cs 未改变且栈空的前提下 retn 导致 `ip = *(word*)0xfffe`

综上, 要退出, 既可以在 cs = seg psp 时 int20h, 也可以用下面 3 种方法执行 psp 开始处的 int20h

1. cs = seg psp 时跳到 psp 的开头
    ```
    xor ax, ax
    jmp ax ; jump to seg-psp:0
    ```
1. cs = seg psp 时 `retn`, 因为程序开始时栈顶是 (word)0, 等于用 pop ip 实现 jmp 0
1. cs != seg psp 时需要设置 cs, 但改变 cs 会导致跳转, 接下去的语句就没法执行了, 所以必须跳到正确的位置. [kb72848](#hello-world) 指出可以用两个 push 配合 retf
    ```
    push ds ; 开始时 ds = es = seg psp
    xor ax, ax ; push 0 也可以挪到 retf 前面
    push ax

    ; ...

    retf ; 用 pop ip pop cs 实现 jmp seg-psp:0
    ```

[示例: int 20h](#int-20h)

dos 2 添加了退出方式 int21h/ah4ch

- 不使用 cs
- 可以往 al 放一个返回值

https://retrocomputing.stackexchange.com/questions/16891/difference-between-int-0x20-and-int-0x21-0x4c

非 dos 不一定有 psp http://www.tavi.co.uk/phobos/exeformat.html

win32 程序退出时要调用 ExitProcess

### dos api

下面网站有 dos 和 bios 的详细讲解, 是查阅 dos api 的首选网站<br>
http://www.techhelpmanual.com/2-main_menu.html

dos api 基本是 int 21h. 为啥用 int 不用 jmp, call 呢? 有几种说法
- int 指令更短. 没错, 但要额外做把字节通过 ivt 转换到实际地址的工作. 宁愿消耗运行时间也要缩短代码? 有可能
- 数字比地址灵活, 比如修改地址让它指向自己的代码. 说到底也没有灵活多少, 很容易用 jmp 实现
- 数字比地址容易记忆. 这一类解释让人哭笑不得的地方在, 一般情况下它没错, 但具体看它要解释的现象, 内存映射已经用了大量的地址, 从没见考虑过容易记忆的事
- int 已经做出来了, 所有资源已经占用了, 不用也浪费. 这条有道理

int 是 intel 发明的 software interrupt. intel 老早就喜欢把概念分出高低等级: supervisor; kernel, user; ring0, ring3; instructions, interrupts; general | special purpose register; ... 引入新机制, 划定等级, 确实是解决问题的一种手段, 当然也有自身的缺点.

- int20h
    - DOS 1+ - TERMINATE PROGRAM
    - Entry: CS = PSP segment
    - Return: Never

- int21h
    - ah0
        - http://www.ctyme.com/intr/rb-2551.htm
        - DOS 1+ - TERMINATE PROGRAM
        - Entry: CS = PSP segment
        - Notes: Microsoft recommends using INT 21/AH=4Ch for DOS 2+. This function sets the program's return code (ERRORLEVEL) to 00h. Execution continues at the address stored in INT 22 after DOS performs whatever cleanup it needs to do (restoring the INT 22,INT 23,INT 24 vectors from the PSP assumed to be located at offset 0000h in the segment indicated by the stack copy of CS, etc.). If the PSP is its own parent, the process's memory is not freed; if INT 22 additionally points into the terminating program, the process is effectively NOT terminated. Not supported by MS Windows 3.0 DOSX.EXE DOS extender

    - ah4ch
        - "EXIT" - TERMINATE WITH RETURN CODE
        - Entry: AL = return code
        - Return: never returns
        - Notes: unless the process is its own parent, all open files are closed and all memory belonging to the process is freed
        - int21h/ax4c00h 就是 return 0



### omf, coff, mz, pe

https://en.wikipedia.org/wiki/Comparison_of_executable_file_formats

omf

- https://en.wikipedia.org/wiki/Relocatable_Object_Module_Format
- Relocatable Object Module Format (OMF) 是对象文件的一种格式, 主要用于在 intel 80x86 上运行的软件
- 源于 intel 开发的(when?) Object Module Format, dos 的 .obj 文件就是此格式
- MS-DOS, 16-bit Windows, 16/32-bit OS/2 上最重要的对象文件格式
- masm 6.11 生成 obj 默认 omf, 可以用 -coff 选项生成 coff
- masm 不支持绝对 jmp far 比如 `jmp 0ffffh:0`, 需要 omf<br>
    https://stackoverflow.com/questions/32706833/how-to-code-a-far-absolute-jmp-call-instruction-in-masm

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

- https://en.wikipedia.org/wiki/Portable_Executable<br>
    Portable Executable (PE) 格式是 executables, object code, DLLs, FON Font 等文件的格式, 用于 32/64 位 windows
- 类比名字, pe 应该是 pef, 就像 omf, coff; 类比系统, elf in Linux and most other versions of Unix; Mach-O in macOS and iOS
- https://blog.kowalczyk.info/articles/pefileformat.html<br>
    为兼容 msdos 和旧版 windows, pe 保留 mz 头
- https://thestarman.pcministry.com/asm/debug/DOSstub.htm<br>
    pe 的 mz 头后面是个 16 位 dos 存根程序, 一般显示:
    ```
    (Borland tlink32)   This program must be run under Win32.
    (ms link?)          This program cannot be run in DOS mode.
    (???)               This program requires Microsoft Windows.
    ```

### com 文件

https://en.wikipedia.org/wiki/COM_file

演变

- Digital Equipment operating systems, 1970s: .COM was used as a filename extension for text files containing commands to be issued to the operating system (similar to a batch file)
- cp/m: executable
- dos: executable

特点

- max size = 65,280 (FF00h) bytes (256 bytes short of 64 KB)
- stores all its code and data in one segment
- entry point is fixed at 0100h

com 和 exe 在执行时可以通过动态链接等技术任意使用内存.

dos 和 cp/m 的 com 文件结构虽然一样但互不兼容. dos 文件包含的是 x86 指令和 dos 系统调用; cp/m 文件包含 8080 指令和 cp/m 系统调用, 特定于机器的程序可能还会有 8085, Z80 指令

fat binary

- https://en.wikipedia.org/wiki/Fat_binary
- 基本上是把多个功能一样的程序放到一个文件里, 开头的代码选择使用其中一个
- 开头的代码即入口代码, 是在几个系统中都有效但功能不同的指令, 在不同的系统中执行有不同的效果, 比如
    `C3h, 03h, 01h` 在 x86 上是 `ret`, 在 8080 上是 `JP 103h`

老的 bat 文件可能使用命令的全名, win nt 为兼容这些 bat, 下列 exe 文件仍以 .com 结尾:<br>
DISKCOMP, DISKCOPY, FORMAT, MODE, MORE, TREE<br>
作为 exe, 它们的文件开始俩字节是 MZ, 操作系统能认出来并按 exe 执行.

执行命令时如果省略扩展名, dos 先找 com 再找 exe, 比如 foo, 找 `foo.com` 或 `foo.exe`. win nt 环境变量 PATHEXT 可以指定扩展名顺序, 默认仍然是 com 先于 exe

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
```

/AT 和 .model tiny 的区别

> Microsoft MASM 6.1 Programmer's Guide.pdf，p56，Tiny Model<br>
/AT does not insert a .MODEL directive. It only verifies that there are no base or pointer fixups, and sends /TINY to the linker.

org n 的作用

- 给所有标签 +n 的偏移
- 把其后的语句放在可执行文件的代码部分的第 n 字节, 若造成该语句后移, 用 0 填充之间的部分
- 多个源文件, 或生成的不是 com 时 org 可能偏大 http://support.microsoft.com/kb/39441/en-us
- 生成 com 文件 && 使用了 org && 其后的语句被 end 标为起始地址 && 将生成 > 256 字节的可执行文件<br>
    则删除起始地址前面的内容, 参考 [起始地址](#起始地址)/com 文件的起始地址

## a 16 bit dos program in masm

masm 要求源文件具备两个要素: end 和非空的 segment; 这两样东西对生成可执行文件毫无贡献, 理由是:

- 如果程序啥都不做, 源代码应该啥都不需要写, 因此是个空文件, 而不是一个非空段 + end
- 非空段有意义的部分是使段非空的文本, 而不是段定义

masm 要求源代码从两个无用的结构开始, 预示了此后的 masm 编程道路上会遇到很多 masm 有意或无意制造的障碍.

新建一个空文件 dd.msm 用 masm 编译, 看看会发生什么.

`ml -Foout\ dd.msm -Feout\` 输出如下
```
error A2088: END directive required at end of file
```
\* *-Fo 指定 ml 生成的 obj 的路径, 可以是目录; -Fe 指定连接得到的文件的路径, 可以是目录. 开关和参数间可以有空格*

### end 的两个作用

- 结束源文件. 毫无意义的功能
- 后跟参数指示程序的入口, 即在源文件结束处用 end 指出起始地址. 让我想起那著名的 "点击 '开始' 以关机".

按照 masm 的要求给 dd.msm 加上 end

```
end
```

`ml -Foout\ dd.msm -Feout\` 输出如下
```
LINK : warning L4021: no stack segment
LINK : error L4076: no segments defined
```

`ml -AT -Foout\ dd.msm -Feout\` 输出如下
```
LINK : error L4076: no segments defined
```
\* *-AT 让 ml 给 link 传 /tiny, 从而生成 com 文件*<br>
\* *不想看版权信息可以 `ml -nologo -AT -Foout\ dd.msm -Feout\ -link /nologo`*

可以看到 link 报告了 1 个错误. 此处的亮点是尽管有连接错误, 仍然生成了可执行文件.

masm 认为程序应该有栈, 因此没有 -AT 时 link 还警告 L4021; -AT 没有此警告是因为 com 就 1 个段, 栈也使用此段.

错误说没定义段, 没说什么 "非空段" 所以下面代码似乎就够了?<br>
\* *segment 的语法在 8086/610guide/ch02.txt*

```
xxx segment
xxx ends
end
```

编译发现错误信息完全没变, 因此光有段不行, 很可能还得是非空段. 是否还记得一开始说的 "毫无贡献"?

### 非空的段

按照 masm 的要求定义一个非空的段, 像这样:

```
xxx segment
db 1
xxx ends
end
```

`ml -AT -Foout\ dd.msm -Feout\` 输出
```
LINK : warning L4055: start address not equal to 0x100 for /TINY
```

没有 /AT 时可以把此段标记为 stack 以消除 L4021

```
xxx segment stack
db 1
xxx ends
end
```

`ml -Foout\ dd.msm -Feout\` 输出
```
LINK : warning L4038: program has no starting address
```

L4038 很明确, L4055 很难理解, 它俩说的却是同一个意思: 需要指定[起始地址](#起始地址)或叫入口地址, 否则打印警告并把第 1 句当作入口.

因此要用 end 指定个标签. 把 db 1 改为正常的返回语句 (*), 缩进, 得到下面的完整程序.

\* 根据 8086/refs/stack.msm 知道 exe 运行时栈顶的 word 被改为 ff ff; 为防止覆盖那里的指令需要弄点填充字节. 写填充字节时为了确定填几个, 试了几个数值, 发现至少得 4 字节程序才正常退出, 但在 debug 里执行不正常; 用 debug 一看发现不仅是修改了最后两字节. debug out\dd.exe 时, 查看内存没啥问题; t 执行一句后再查看, 前 10 字节内容都变了. 加大填充的长度发现最后 10 字节会被修改; 隐约记得以前见过这情况. 因此要在 debug 里也能正常退出得填充 10 字节 (那填充 4 字节算不算正确?). mov ax, 4c00h int 21h 是 5 字节, 加上 10 个填充字节等于 15 字节. 为了对齐到 word 再加 1 字节, 填充了 11 字节, 否则起始 ip 是 1 而不是 0; 尽管我不知道起始 ip 是 1 有啥问题.
**todo** 探究这个修改最后 10 字节的问题

### the program

```
; com
; ml -AT -Foout\ dd.msm -Feout\

xxx     segment
s:      mov     ax, 4c00h
        int     21h
xxx     ends
        end     s
```

```
; exe
; 作为起始地址的标签定义到栈里面了. 一般不会往栈里放代码但只要注意填充字节就没啥问题, com 就只有 1 个段
; ml -Foout\ dd.msm -Feout\

xxx     segment stack
s:      mov     ax, 4c00h
        int     21h
        byte    11 dup (?)
xxx     ends
        end     s
```

\* *end 后面必须是标签不能是立即数 (字面量), 否则 error A2094: operand must be relocatable*<br>
\* *把变量名放 end 后面得到 error A2095: constant or relocatable label expected*

上面啥都不做的 masm 16 位 dos 程序包含 4 部分内容

- 为了正常编译, 写 masm 要求的 end begin
- 为了正常编译, 写 masm 要求的段
- 为了正常运行, 写 dos (?) 要求的填充字节. 不把代码放栈里时可忽略本条
- 为了正常退出, 写 dos 要求的返回语句

### 起始地址

**连接器如何确定起始地址**

ml 找源文件中用 end 指出的标签, 把它写到 obj<br>
\* *验证: 用 ml -c 编译两个 obj 文件, 一个指定起始地址一个不指定, 比较它们*<br>
link 从 obj 找出 ml 写入的起始标签, 把其地址做为起始地址<br>
\* *验证: 用 link out\dd.obj; 均不传 /tiny 参数, 分号表示省略 link 的其他参数, 分别连接两个 obj 文件*

ml64 不允许 end 后跟入口, 但和 ml64 配套的 link 有 /entry 开关<br>
\* *link 5.31.009 Jul 13 1992 没有 /entry 开关*<br>
\* *ml64 编译的代码一般不用自己写入口, 入口由使用的库定义, 就像 c 程序不定义入口, 而是写一个 crt 规定的回调函数 main*

用 ml64 编译的代码也可以用下面语法把入口写入 obj<br>
https://stackoverflow.com/questions/59006082/x64-doesnt-seem-to-accept-an-entry-point-in-the-end-directive-as-x86-does-was

```
_DRECTVE SEGMENT INFO ALIAS(".drectve")
    DB  " /ENTRY:main "
_DRECTVE ENDS
```

**com 文件的起始地址**

(dos 4+?) 有些 exe 文件会使用 com 扩展名, 加载程序会查看文件的前几个字节, 如果发现是 exe 就按 exe 执行, 否则才按 com 执行<br>
https://retrocomputing.stackexchange.com/questions/14520/how-did-large-com-files-work<br>
https://github.com/microsoft/MS-DOS/blob/master/v2.0/source/EXEC.ASM#L331<br>
but can a com file start with mz?

com 没有文件头. 情况复杂, 有时候忽略 end 指出的标签, 把第 1 句当起始地址; 看不出规律, 我列举两种

以下情况 link 不修改代码
```
xxx segment
db 16 dup (1)   ; 第一句
s:              ; 入口不是第一句
org 0e0h        ; 使用了 org. 如果由于 org 而增加了语句的地址, 中间部分填 0
db 32 dup (2)   ; 程序 < 257 字节
xxx ends
end s
```

以下情况 link 删除入口之前的代码, 这里是 `db 16 dup (1)`, 得到的 com 文件可能小于 256 字节
```
xxx segment
db 16 dup (1)   ; 第一句
s:              ; 入口不是第一句
org 0e0h        ; 使用了 org
db 33 dup (2)   ; 33 dup 使程序 > 256 字节
xxx ends
end s
```

好在上面两种情况都不是程序的正常写法.

**dos exe 文件的起始地址**

文件头记录连接器生成的入口地址

https://wiki.osdev.org/MZ


## masm 命令行

### 源文件编码

masm 的 source-charset 固定为 ascii; 串原样放入二进制, 相当于 execution-charset = source-charset; 无需转义字符, 因为指定字符时既可以用字面量也可以用数字, 字符字面量就是其 ascii 值.

### 命令行选项

ml 开关 (选项) 的起始字符是 - 或 /, 开关区分大小写; link 只能是 /, 不区分大小写.

*写这里时发现 dosbox 中命令超过一行而换行后, 没法把光标移回到上一行*

**对单个文件生效的开关必须规定个位置否则 file1 -xxx file2 不能确定 -xxx 作用于谁**

masm 规定

- 对单个文件生效的开关放文件前
- 命令行开关和文件名都可以用引号括起来
- 双引号内 "" 解释为 "
- 以 - 打头的 token 是命令行开关; 因此文件名如果类似 -coff, 编译时要写成类似 ml ./-coff

masm 命令行开关有 5 种作用范围
```
1. 其后的 1 个 token
-unrecognized switch    ml 6, 14; ml64 14

2. 其后的 1 个文件
-Fo         ml 6, 14; ml64 14
    ml -Foout\ cmdln/f1.asm -Foout\ cmdln/f2.asm -Foout\ cmdln/f3.asm -Feout\

3. 其后的所有文件
-coff       ml 6, 14. ml 14 default
-D          ml 6, 14; ml64 14.
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


**常用命令行选项**

```
ml /?
ml -?

/EP Output preprocessed listing to stdout
/Zs Perform syntax check only
/c  Assemble without linking

link /?
```



## masm 语法

masm 的关键字分两种
- cpu 规定的指令集的指令助记符
- masm 规定的指示, 符号, 操作符

### ptr - coercion

http://www.phatcode.net/res/223/files/html/Chapter_8/CH08-4.html<br>
看完网页后想看看是啥书, 一看是 Randall Hyde 的 the art of assembly language programming. 我记得以前照该书写过一些练习代码, 现在找不到了

ptr 究竟是 intel 还是 microsoft 发明的? 网上没找到答案, x86 指令集里没有但反汇编里有, 所以应该是 intel.

ptr 既然不是指令, 那就不知道咋称呼了. 它用来解决这种问题: `mov [bx], 5` 时不知道 bx 指出的是 byte, word 或者其它, 所以用额外的词 长度 + ptr 指出内存的长度: `mov word ptr [bx], 5`

mov 需要额外的标注, 那这个 mov 和那个 mov 就不是一回事, 就不需要让它们都用 mov 并且后面跟上限制条件. 这里明明需要一个类似 mov2 之类的助记符, intel 却选择 mov word ptr 这样的语法, 给读者带来理解上的困难. 下面的例子表明 mov word ptr 和 mov byte ptr 对应不同的 opcode; 或者说助记符由 3 个词组成, 不是 1 个词.

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
    ...
q
```

可以看到
- ptr 可以写在任意操作数前面, 最终总是放在内存前. 其实放谁前面都一样
- (16 位 cpu?) 只能 ptr 为 byte, word; dword, tbyte 变成 byte; qword 变成 word. 这个完全看不出规律
- 数字在内存中的字节顺序

masm 要求显式重写段寄存器, `mov [200], word ptr 3` 要写为 `mov ds:[200], word ptr 3`. 毫无用处: 访问内存默认的段寄存器是 ds, 不用 ds 时必须加前缀, 本来就没有歧义. masm 要求重写是因为他胡乱解释 `[200]`, 只有重写才能抑制该行为.

masm 的变量, 假设有 `I byte ?`

1. 原来需要 ptr 的指令现在不需要了, `mov [200], byte ptr 3` 要写为 `mov I, 3`
1. 原来毫无歧义的语句现在必须用 ptr 添加重复信息了, `mov ax, [200]` 要写为 `mov ax, word ptr I`

情况 1 省了个 ptr, 但要求变量定义, 这再次表明: 静态类型增加程序员负担

ptr 啥意思? pointer? 地址确实可以看作指针, 但对指针解除引用的操作是 [], ptr 的作用对象是解除引用后的数据, 因此 ptr 是个 coercion 或 cast, 但不知道为啥取名字叫 ptr.

可能是为了凑点关系, masm 决定搞一个指针类型, 也使用关键字 ptr - 给 ptr 添加一个和指针有关系的用法. 这样一来 ptr 就有两种不同的用法了: 一种是 word ptr, 另一种是 ptr word... 就问你佩不佩服?<br>
**todo** 待续

Randall Hyde 把这个操作叫 coercion; 后来有一天我搜索网页发现这种意见: 要么叫 conversion 要么叫 cast, 就是不叫 coercion. 我真的是觉得 c++ 有很多神棍.

check this out | https://stackoverflow.com/questions/8857763/what-is-the-difference-between-casting-and-coercing
---|---
conversion | implicitly/explicitly changing a value from one data type to another
coercion   | implicit conversion
cast       | explicit type conversion, may be a re-interpretation of a bit-pattern or a real conversion

### ret, retn, retf

不知道 ret 是不是 intel 助记符. 指令集里没有; debug 认识它; masm 在 proc 里使用以省去一个字符 (f 或 n), masm 查看 proc 的定义, 给 ret 加上 f 或 n (todo: verify this).

### 段

8086, 8088, 80186, 80188 是 16 位寄存器和 20 位地址线 https://en.wikipedia.org/wiki/RAM_limit, 每个 2 ** 16 = 65535 = 64k 是一个段; 用 16 位段寄存器和 16 位通用寄存器保存两个数 seg 和 offset, seg * 16 + offset = 20 位地址, 同一个地址能对应好多不同的 seg 和 offset 组.

intel 设计了 3 种段, 用不同的寄存器保存段里的地址, 好些指令**隐含**使用这些寄存器:
- 代码 cs:ip
- 栈 ss:sp
- 数据 ds:xxx. 又分为源数据 ds:si 和目的数据 es:di

masm 有关键字 segment (段). 前面演示了 masm 要求代码必须有段. 16 位程序里 segment 对应 16 位 cpu 的段; 32 位程序里 segment 对应可执行文件的节, 节对应内存的页; 节的一个作用是指出一段内存的读, 写, 执行属性.


**todo** diff on use32, flat<br>
https://stackoverflow.com/questions/45124341/effects-of-the-flat-operand-to-the-segment-directive

### assume

没啥意义的东西, masm 提供这个指示让用户克服 masm 制造的困难.

```
; ml -AT -Foout\ dd.msm -Feout\

xxx     segment
        assume  ds:xxx
; 1. 如果没有 assume, masm 会在 mov 的前面用 cs 重写段寄存器, 机器码 2e;
;   com 有 cs = ds = ss, 3 个段相同, 2e 是多余的前缀
; 2. i 是 db, masm 要求 word ptr; 而 mov ax 明确要求 word, 所以 intel 不需要 ptr; masm 生成的指令里没有 ptr
s:      mov     ax, word ptr i + 100h ; 没写 org 的 com 需要自己加偏移
        mov     ah, 4ch
        int     21h
i       db      ?
xxx     ends
        end     s
```


### 宏

/macros.md

### % - expansion

- 按当前的基数对常量表达式求值, 把得到的数字转为字符串
- 做为一行的首个非空白字符时, 展开该行的文本宏和宏函数; 用于 echo, title, subtitle, .erre 等把参数一律视为文本的指示. 一律 - 包括 %, 常量表达式 - 视为文本, 就没法在它们的参数里调用宏或对表达式求值; 但又有这种需求, 于是 masm 说, 既然宏展开符号 % 放 (比如 echo) 后面没戏, 那就放前面吧; 常量表达式的话你们就在外面赋值给文本宏, 别在里面求值了.masm 居然没有选择添加或规定转义字符, 真乃一大幸事.

masm 有个以 % 打头的指示, %out; 后来加了个 echo 用于取代其功能. %out 是个 4 字符的 token, % 是名字的一部分.


## masm 编译错误

### A2076 

error A2076: jump destination must specify a label.

A direct jump's destination must be relative to a code label.

near jump | x86 | masm
-|-|-
jmp immediate | x | x
jmp relative | o | x

masm 不允许 jmp 0 但允许 s: jmp s - 100h, 当 s 是 com 的起始地址时就相当于 jmp 0

```
debug
-a
xxxx:0100 jmp 0
xxxx:0103
-u
xxxx:0100 E9FDFE    JMP     0000
xxxx:0103 ...
...
-r
... IP=0100 ...
xxxx:0100 E9FDFE    JMP     0000
-t
... IP=0000 ...
xxxx:0000 CD20      INT     20
-q
```

1. 从 http://ref.x86asm.net/coder32.html 查知 e9 是 JMP rel16/32, fdfe 显然是 16 位参数
1. 考虑字节序, 参数是 0xfefd
1. 又知道 e9 的参数是补码, 作用是和 ip 相加
1. 执行 e9fdfe 前 ip = 0x100
1. 执行 e9fdfe 时 ip = 0x103
1. 执行 e9fdfe 后 ip = 0x103 + 0xfefd = 0x10000 -> to word = 0

### LNK1190

fatal error LNK1190: 找到无效的链接地址信息，请键入 0x0001

> http://masm32.com/board/index.php?topic=3114.0 wjr April 15, 2014, 07:06:37 AM<br>
If you use PEview to look into the OBJ file, and Type 0x0001 is referring to IMAGE_REL_I386_DIR16 (usually
should be 0x0006 IMAGE_REL_I386_DIR32), then you should be able to see at least one of these in the
IMAGE_RELOCATION records. The symbol name and RVA are also displayed which should help narrow things down.


## 16 bit dos masm 程序示例

### 从 psp 获取程序的命令行参数

https://en.wikipedia.org/wiki/Program_Segment_Prefix

psp 常用于获取程序的命令行参数, 或者叫 command-line tail. 程序开始执行时 ds = es = seg psp; int21h/ah51h 和 int21h/ah62h 也可以获取 psp 的段地址, 结果放在 bx.

INT 21,51 - Get Current Process ID (Undocumented DOS 2.x)<br>
https://stanislavs.org/helppc/int_21-51.html<br>
INT 21,62 - Get PSP address (DOS 3.x)<br>
https://stanislavs.org/helppc/int_21-62.html

```
; 打印命令行参数. 命令尾全是空白字符时长度是 0, 否则长度包含空白
; psp 80h       1 byte      Number of bytes of command-line tail
; psp 81h-FFh   127 bytes   Command-line tail (terminated by a 0Dh)
;
; bug
; 1. 修改了 psp 的一个字节, 改为 $
; 2. 若命令行参数包含 $ 则认为串结束, 以致打印不全
;
; ml -AT -Foout\ dd.msm -Feout\

xxx     segment
start:  xor     bx, bx
        ; mov   bl, [80h]   ; masm 认为 [80h] 是 80h (注)
        mov     bl, ds:80h  ; or ds:[80h]
        cmp     bl, 7eh     ; 命令行长度至多 0x7e = 126
        ja      exit        ; 如果 [0x80] > 126 就退出

; print the string
; INT 21h subfunction 9 requires '$' to terminate string
        mov     byte ptr [81h + bx], '$'
        mov     dx, 81h
        mov     ah, 9
        int     21h

exit:   mov     ax, 4c00h
        int     21h
xxx     ends
        end     start

执行下列命令后输出
> out\dd     ddd  --x
     ddd  --x

注: 后来看到这帖子
https://stackoverflow.com/questions/25129743/confusing-brackets-in-masm32
masm 根据它的规则修改你的代码
- variable name               无论方括号, 一律认为是变量的值
- constant, const expr, imm   无论方括号, 一律认为是立即数
- register                    不修改方括号的意义
这个编译器会修改你的代码. 我能理解错不全在 masm, 你看它修改的大都是他自己规定的玩意儿: 变量, 常量, 常量表达式, 除了立即数. 因此要说代码被修改了你自己也有问题, 因为你用它提供的结构了, 我想很难反驳吧?
```

上面代码为了用 int21h/ah9 打印串, 修改了 psp, 并仍无法正确打印包含 $ 的串. 下面的网页给出了 3 种办法<br>
https://stackoverflow.com/questions/481344/dollar-terminated-strings

- int21h/ah2
- int21h/ah40h, file handle = 1
- int29h, undocumented

masm 的 @@ 定义一个只能通过其上下的 @f (forward, 下一个 @@) 和 @b (back, 上一个 @@) 访问的标签

```
; ml -AT -Foout\ dd.msm -Feout\

xxx segment
    org 100h    ; 为了让 com 中的标签具有正确地址, 在这里统一 +0x100
s:  mov dx, msg ; int21h/ah9, show message, msg is defined at bottom
    mov ah, 9
    int 21h

    mov ah, 1   ; int21h/ah1, wait key stroke, return al = character read
    int 21h     ; 发现它回显字符一定输出至屏幕, 不考虑重定向, 显然和 debug 用的不是一个 api

    mov bl, al  ; save al, because next int21h call will override it

    mov dl, 10  ; int21h/ah2, output dl = 10 = \n, return al = last character output
    mov ah, 2
    int 21h

    xor cx, cx  ; save length of args to cl
    mov cl, ds:80h

    cmp cl, 0   ; print functions below use do while, so make sure cl > 0 here
    jne @f
    int 20h

@@: cmp cl, 7fh ; 命令行长度至多 0x7e = 126
    jb  @f
    mov cl, 7eh

; at this point bl = user input letter, cl = len of args, ds = seg psp

@@: cmp bl, 'a'
    je  a
    cmp bl, 'A'
    je  a

    cmp bl, 'b'
    je  b
    cmp bl, 'B'
    je  b

    call int29h
    int 20h

a:  call ah2
    int 20h

b:  call ah40h
    int 20h

; int21h/ah40h
; bx = file handle; 1 = the same device (such as the screen) as service ah=9
; cx = the number of bytes to be written
; ds:dx points to the data to be written
ah40h:
    mov bx, 1
    mov dx, 81h
    mov ah, 40h
    int 21h
    retn

; int21h/ah2
; dl = character to write
; return al = last character output
ah2:
    ; destroys ax, bx, cx, dx
    mov bx, 81h
    mov ah, 2
@@: mov dl, [bx]
    int 21h
    inc bx
    loop @b
    retn

; int29h 和 int21h/ah2 区别是 console redirect 对 int29h 无效
; al = character to output
int29h:
    ; destroys ax, bx, cx, dx
    mov bx, 81h     ; [dx] causes error a2031: must be index or base register
@@: mov al, [bx]    ; valid: [bx], [bp], [si], [di]
    int 29h
    inc bx
    loop @b
    retn

msg:
db  '      a - int21h/ah2',     13, 10,
    '      b - int21h/ah40h',   13, 10,
    '<other> - int29h',         13, 10,
    'please choose output method by entering a, b or any other letter: $'

xxx ends
    end s
```

### hello world

execute int 20h in exe by retf<br>
https://jeffpar.github.io/kbarchive/kb/072/Q72848/

```
; Assemble options needed: none

stack   SEGMENT para stack 'stack'

        DB 2048 dup(?)

stack   ENDS

data    SEGMENT word public 'data'

msg     DB "Hello, World", 0Dh, 0Ah, "$"

data    ENDS

text    SEGMENT word public 'code'

begin:  PUSH    es              ;ES = PSP at entry, so we'll save it
        MOV     ax, SEG data    ;Initialize DS to data segment
        MOV     ds, ax
        ASSUME  DS:data, CS:text, SS:stack

        MOV     ax, SEG msg
        MOV     ds, ax          ;Set DS:DX to the address of msg
        MOV     dx, OFFSET msg
        MOV     ah, 09h         ;Function 09h (Display String)
        INT     21h

        MOV     ax, 00h         ;Extra step for 8088/8086 chips
        PUSH    ax              ;PSP segment is already on the stack
        RETF

text    ENDS

        END     begin
```

### int 20h

```
; ml -DcomRetn -Foout\ dd.msm -Feout\
; -DcomRetn
;   注意到初始 sp=fffe, fffe 和 ffff 处都是 0, 这时 retn 可以使用这两个字节当 ip,
;   若又有 cs = seg psp 则 retn 导致执行 psp 0000 处开始的机器码.
;   不知道这方法是否可靠, 即不知道栈是否总是保留两个字节的 0
; -DcomRetf
;   错误的写法, retf 使用栈上的 2 个 word 而栈上只有 1 个. 执行后 dosbox 不接受输入, 只能重启 dosbox
; -DexePushRetf
;   正常做法, 保存 seg psp 和 0, retf 总是能执行. 当然更正常的做法是 int21h/ah4ch

ifdef comRetn

.model tiny
.code
org 100h
s: retn

elseifdef comRetf

.model tiny
.code
org 100h
s: retf

elseifdef exePushRetf

.model huge
.stack
.code
s:
push ds
xor ax, ax
push ax
retf

else

te textequ <please specify which code path you prefer when compile, e.g. ml -DexePushRetf...>
echo
%echo te

.model tiny
.data
% msg db 'te&$'
.code
s:
; mov dx, offset _data + ?
; mov dx, @data
mov dx, offset msg + 100h
mov ah, 9
int 21h
int 20h

endif
end s
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
- link 认识段名 _DATA, _DATA 和 link 不认识的段对应的节的属性是不可执行-读写
- editbin 可以修改节的属性

> http://masm32.com/board/index.php?topic=602.15 sinsi August 22, 2012, 06:36:17 PM<br>
.code expands to "_TEXT segment public"<br>
.data expands to "_DATA segment public"

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

早期的 crt/puts 代码使用简化段, 现在不喜欢 .code 那种写法了.

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










