
*April 13, 2021: Markdown files will now automatically generate a table of contents in the header when there are 2 or more headings.*<br>
https://github.blog/changelog/2021-04-13-table-of-contents-support-in-markdown-files/



## x86

初学 x86 汇编最大的难点是 intel 发明的大量杂乱无章的术语.

### mnemonic

汇编语言没有标准语法, 汇编器在 cpu 厂商提供的 mnemonic 语法基础上创造自己的语法.

```
            / masm directives   -   mnemonic, operands (see below), infos \
source code                                                                 obj file \
            \ mnemonic, operands     -   instruction    -    machine code /            executable
( from left to right -> )                                                   obj file /

   mnemonic = name of a group of opcodes                  opcode = operation code = cpu function index
   operands = arguments of mnemonic, may be implicit   <no name> = rest part of instruction
  statement = mnemonic + operands                    instruction = <see below>
source code = statements + compiler directives      machine code = instructions

https://wiki.osdev.org/X86-64_Instruction_Encoding  An x86-64 instruction may be at most 15
bytes in length. when either Displacement or Immediate is 8 bytes, another can not be encoded
Legacy prefixes         (1-4 bytes, optional)
Opcode with prefixes    (1-4 bytes, required)
ModR/M                  (1 byte, if required)
SIB                     (1 byte, if required)
Displacement            (1, 2, 4 or 8 bytes, if required)
Immediate               (1, 2, 4 or 8 bytes, if required)
```

mnemonic 描述一个抽象操作, 编译为数字; 如果操作接受参数, 参数就要编译为数字跟操作放一起; 如果接受好几种参数, 为了区分它们就要把参数类型编译为数字跟操作放一起. intel 把抽象操作 + 参数类型叫做 prefixes + opcode + modr/m + sib, 把参数叫做 displacement + immediate. 这是个混乱的对应关系, 如果指令进一步增加大家就能看到 intel 创造的新名词.

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

有
```
c6      opcode
06      modr/m
0002    displacement
03      immediate
c7      opcode
06      modr/m
0301    displacement
0300    immediate
```

为什么?

1. c6 ...

    - 从 http://ref.x86asm.net/coder32-abc.html 找指令 mov. `byte ptr [0200]` 是 8 位内存, 03 是立即数, 查看网站, 发觉 8 位内存应该对应 m8; 立即数自然也是 8 位, 应该对应 imm8. 于是找 move m8, imm8, 找到这条 `MOV r/m8 imm8 C6`. 或者
    - 从 http://ref.x86asm.net/coder32.html 找操作码 c6. 我不确定 c6 是操作码还是前缀, 但网页已经区分了它们. 找到 `MOV r/m8 imm8`

    所以 c6 = MOV r/m8 imm8. 为确定 r/m8 到底是哪个, 需要 modr/m 字节, 所以 c6 后面的 6 是 modr/m 字节.<br>
    https://stackoverflow.com/questions/8518917/x86-mov-opcode-disassembling

1. c6 06 ...

    http://ref.x86asm.net/coder32.html#modrm_byte_16 的表把 modr/m 字节分成 3 部分: 最上面的 reg/opcode 占 3 位, mod 列占 2 位, r/m 列占 3 位. 值 6 的周围如下:

    ```
                                    000
    Effective Address   Mod R/M     Value of ModR/M Byte (in Hex)
    disp16              00  110     06
    ```

    表把 6 = 0b00000110 分解成 3 部分 mod = 00, reg = 000, r/m = 110

    所以 6 是让 `mov r/m8 imm8` 把第 1 个参数视为 (指向 m8 的) disp16, 得到 c606 = mov m8 imm8, 从而从 000203c706030... 中取前 16 位, 即 0002, 作为常量偏移; 而由于是 imm8, 随后的一个字节 03 是第 2 个参数.

1. c6 06 0002 03 ...

几个等式
```
    c606000203
=   no-prefix opcode#c6 modr/m#6 no-sib 0002 03
=   function#c606(0x200, 3)
=   mov m8 imm8(0x200, 3)
=   mov byte [0x200], 3
```

`c70603010300 mov word ptr [0103], 0003`, 有 `C7 MOV r/m16/32 imm16/32`, 16 位代码排除 m32 和 imm32 得到 c7 = mov r/m16 imm16, 前面知道 6 是 disp16, 得到 c706 = mov m16 imm16. 所以 03010300 的第一个 16 位是数据的位置, 数据长度是 m16 = 16 位 = 2 字节; 第二个 16 位是 imm16.

可以看到
- 助记符往往不包括 opcode 需要的 prefix, modr/m, 但当无法确定操作数的长度时, 需要写比如 byte 或 byte ptr, 帮助生成 modr/m
- 助记符不需要知道寄存器和地址的长度, 它俩在执行时的 cpu 模式里有唯一长度

**byte code**

有些编译器把代码编译为字节码, 由该语言的虚拟机执行. 比如 java.

**microcode**

a.k.a. μcode<br>
https://en.wikipedia.org/wiki/Microcode

完全位于 isa (instruction set architecture) 的一侧, 汇编看不到. 不是每种 cpu 都有 microcode

以前的机器语言就是 cpu 执行的语句, 语句定义在 isa 里. 后来 (around 1950) 可能是指令复杂了, 或想兼容以前的代码 (从而不可移植的汇编也可移植了), 或任何原因, 机器语言要翻译为 microcode 让 cpu 执行, 这就把机器语言变成高级语言了. microcode 各方面都和汇编差不多.

**micro-operation**

a.k.a. micro-ops, μops, micro-actions<br>
https://en.wikipedia.org/wiki/Micro-operation

主要是 intel 用, 前面说的 microcode 有很多厂商都用. 一般看到莫名其妙的名词扎堆儿出现, 基本就是 intel.

### types of operands

**register**. r8, r16, r32, r64; sreg = segment register

**immediate**. imm8, imm16, imm32, imm64; 立即数即数值字面量 numeric literal, 是指令的一部分, 写入生成的二进制文件.

**offset**. 偏移. 16 位模式用 segment:offset 表示地址, segment 和 offset 单独都表示不了地址, 但 offset 经常**隐含**依赖一个 segment 以表示地址; 32 位和 64 位都只用 offset 表示地址, 不用 segment. 一般情况下偏移的基准点若是 0 就等于地址; 这里把偏移和地址区分开是因为这里的偏移都是相对于段而不是相对于 0. intel 把 segment 和 offset 叫逻辑地址, segment:offset 叫物理地址; 逻辑应该是指 intel 逻辑, 正常的逻辑不会把部分说成是整体.

**relative offset**. 相对于下一条语句的偏移; 用于 jmp, jcc, call, loop

- 只有 immediate 形式的 rel8, rel16, rel32, 大大降低了 relative offset 的实用程度
- rel8 有 `目标偏移 = byte(下一条语句的偏移 + val(rel8))`, rel16 有 `目标偏移 = word(...)`, rel32 是 `dword(...)`
- `100: jmp 104` 汇编为 `eb 02`, opcode eb 仅接受 rel8, 02 就视为 rel8; 语句位于 100, 2 字节, 下条语句在 102, 相对于 102 偏移 02 得 104
- 由编译器计算出来, 可能是因为 intel 没有提供类似 jmp-rel 的助记符. 由于 offset 已具有 "相对段的偏移" 和 "地址" 两个意思, 这里的偏移就不太好意思也叫 offset, 所以创造了个 relative offset, 而这马上就让人怀疑: 难道还有不 relative 的 offset? 那还算 offset 吗? 不过, 似乎听过 "absolute offset" 的说法

**effective address** = Base + Index * Scale + Displacement; 名字是地址, 其实是偏移<br>
https://stackoverflow.com/questions/36704481/what-is-an-effective-address

- **displacement**. immediate; disp8, disp16, disp32; 就是 instruction 里的 displacement
- 16 bit: base (base register) = bx, bp (base pointer); index = si (source index), di (destination index)<br>
    由于没有 sib = Scale Index Base, 16 位代码和使用 16 位寄存器的 32 位代码不能使用 scale
- 32, 64 bit: base = any register; index = any register except esp, rsp; scale = 1, 2, 4, 8

**memory** = effective address = offset
- memory 在代码里经常和方括号 square brackets 一同出现, 因为一个 mnemonic 对应一组接受不同参数的 opcode, 往往既接受 immediate 也接受 memory, 编译器无法区分, 需要程序员用方括号标出 memory
- 不重写时段寄存器 = ds; 重写时有些编译器可以省略方括号, debug.com 不行, 它有不同的写法
- **m8/16/32/64** = m8 or m16 or m32 or m64; 数字指 opcode 从偏移处读取的长度, m8 指向 byte, m32 指向 dword, 等
- **moffset (amd), moffs (intel)**. immediate, 没有 modr/m 的 memory; moffs8, moffs16, moffs32, moffs64; 仅用在几个 mov 里
- **m16&16, m16&32, m16&64, m32&32**. 指向的内存视为两部分, opcode 决定如何使用它
- **m16:16/32/64** = m16:16 or m16:32 or REX.W m16:64; 指向 far pointer, 这和 m16 不同, m16 不把指向的 word 限制为 offset
- memory 是偏移, 16 位下长度是 word, 32 位下长度是 dword; m 后面的数字指偏移处的内存的长度, 这和其它缩写里的数字包括 moffset 都不一样

**r/m16** = r16 or m16; 需要 modr/m; 按正常的理解 r/m16 = r or m16, 这里却不是; 猜测推导过程为 r/m16 = (r/m)16 = r16/m16 = r16 or m16; 这过程当然漏洞百出, 比如 r16/m16 = (r16/m)16 = r1616/m16 = (r1616/m)16 = r161616/m16 = ...; 不过或许压根儿没有推导过程, 而是一个规定, 那样的话就没有疑点了

**far pointer**. immediate, 没有 modr/m 的地址; 只有两种形式, ptr16:16/32, 16 位模式是 ptr16:16, 32 位模式是 ptr16:32.

- ptr16:16 在代码中写作 0xabcd:0x1234, 生成的指令中排列为 34 12 cd ab; ptr16:32 是 0xabcd:0x12345678 和 78 56 34 12 cd ab
- 仅用于跳转, 冒号前的数字给 cs, 冒号后的数字给 ip/eip
- 虽然地址在指令中是一个包含两个分段的立即数, 但见过的编译器都要求写冒号隔开的两个立即数. 可能的原因是, jump 还有个接受立即数的形式, 16 位模式下是 jmp rel8/16, 如果允许 pointer 写成 1 个立即数, 那遇到 jmp immediate 时无法确定是 jmp rel8/16 还是 jmp ptr16:16
- mnemonic 的参数是 ptr16:16/32, 生成的指令参数是 (不确定) "disp16/32 和 imm16"? 放入内存时参数的偏移是 m16:16/32
- 是分段地址, ptr16:16 用 2 个 16 位表示 20 位地址, ptr16:32 用 16 + 32 位, 但不清楚表示几位地址, 可能是 eip 里的 32 位因为 32 位模式不使用分段地址, cs 不参与地址计算. 分段模式下 far pointer 是真正的地址, offset 是地址的一部分; 不分段模式下 offset 是真正的地址, far pointer 是真正的地址 + 额外的值 (用来修改 cs). 因此在汇编里 "指针 (的值) 就是地址, 地址就是指针" 仍然成立; 内存是个数组, 指针 = 地址 = 序号.

```
literal 3 in 16 bit code    typeof operand 3    instruction     typeof 3 in instruction
     0: jmp 3               rel8                eb 01           imm8  , no modr/m
   100: jmp 3               rel16               e9 00 ff        imm16 , no modr/m
        jmp 0x100:3         a part of ptr16:16  ea 03 00 00 01  a part of imm32, no modr/m
        mov ax, 3           imm16               b8 03 00        imm16 , no modr/m
        mov [] 3, ax        moffs16             a3 03 00        imm16 , no modr/m
        mov [] 3, bx        m16,                89 1e 03 00     disp16, accroding to modr/m
        mov [] 3 bx, ax     a part of m16       89 47 03        disp8 , accroding to modr/m
```

*曾参照 ptr16:16 的写法把 m16:16 写为 [0x1234]:[0x5678], 怎么也编译不过. 后来才知道 m16:16 应看作 m(16:16) - m 代表这是个 memory, 所以写法是 [offset]; : 代表 implicit-segment:offset 指向 far pointer; 16 16 代表指向内存的长度是 16 + 16 = 32 位. 后来也知道了 ptr16:16 虽写作 0x123:0x456 但不应看作 ptr16:ptr16; far pointer 表示 segment:offset, 不存在单独的 ptr16; 冒号不能像斜杠那样展开.*

*在 http://ref.x86asm.net/ 上看到大量莫名其妙的缩写, 尤其是 m16:16 和 r/m16/32, 反复遇到, 每次都不理解. 于是决定弄清那些缩写的含义. 查了半天, 先理解了 rel16/32, 又在 https://www.scs.stanford.edu/05au-cs240c/lab/i386/s17_02.htm 17.2.2.2 Instruction 找到了 r/m16 的解释, 这才大致理解了 r/m16/32, 并通过 https://www.felixcloutier.com/x86/jmp 验证了我的理解; 经过反复试验和查看 https://stackoverflow.com/questions/51832437/encoding-jmp-far-and-call-far-in-x86-64 又理解了 m16:16. 这些学到的知识汇成了本节. 这些知识当然无法解决遇到其他缩写时的疑问, 因为那些缩写都是随意编出来的.*

*后来遇到了 m16&16, 到处找不到解释, 不得不看 intel 手册, 之前不看是因为那书太厚. 看了才发现本节内容完全包含在 Intel® 64 and IA-32 Architectures Developer's Manual: Vol. 2A, 3.1.1.3 Instruction Column in the Opcode Summary Table, 不过它没我说的清楚. 指向两段式内存的 offset, 如果两段内存当 far pointer 用, offset 是 m16:16, 否则是 m16&16.*

### 存储, 变量

cpu 的作用是修改一些数字, 这些数字保存在哪? 在 cpu 的知识里有 2 个地方: register 和 memory. 还有其他的存储, 但 cpu 对他们没有特别的知识, 使用这些存储的代码在 cpu 看来仍是在使用 register 和 memory. 两种存储, intel 就发明了两种表示法: 寄存器用名字, 内存用序号. 这么做的依据可能是寄存器和立即数一样是编译时就确定的常量, 而内存地址可以是运行的时候用立即数和寄存器计算出来的值.

\* *似乎数字总要保存在某个地方. 数字和保存数字的地方, 它俩是啥关系? 保存数字的地方能保存不同的数字, 当它不保存某个数字时那个数字在哪? 显然在另一个 "某个地方".*

intel syntax    | thoughts
-|-
ax, bx          | 显然 r 1, r4 更好. intel 把 ax, cx, dx, bx, sp, bp, si, di 编号为 0 ~ 7
[1], [26490]    | 显然 m1, m 26490 更好
[bx], [dx]      | 这种要读寄存器, 编译时不知道值是啥, 可以写为 mr4, mr3 以避免方括号
[bx + di - 57]  | 显然地址要经过计算, 结果要么保存在某个地方要么是某组电路的输出, intel 隐藏了这个地方.<br>更清晰的写法类似 r2 = r4 + r8 - 57 (cpu 显然有做这个运算的电路, lea 就专门使用该电路), 然后使用 mr2

术语 | 含义
-|-
变量 | 具有名字的存储位置叫做变量, 变量是存储位置的别名; 一般只存放某种类型的 1 个数据<br>虽代表地址但编译器知道这是变量并且刻意的要从用法上把变量和地址区分开, 所以用的时候不带标记地址的符号比如方括号
变量的地址 | 变量代表的存储的地址; 寄存器的名字对应寄存器地址, 但代码不能使用它
变量的值 | 变量代表的存储当前存放的数据
变量的类型 | 变量代表的存储的大小; 或语言规定的类型
变量的值的类型 | 变量的类型

### 段寄存器

8086, 8088, 80186, 80188 是 16 位寄存器和 20 位地址线 https://en.wikipedia.org/wiki/RAM_limit

寄存器的存储容量不够用, 更多的容量由内存提供. cpu 有很多处理内存地址的指令, 经常用寄存器保存地址. cpu 能寻址 20 位, 16 位寄存器表示不了 20 位地址, intel 就规定用两个 16 位寄存器, 段寄存器和偏移寄存器, 保存一个 20 位地址, 写作 segment:offset, segment * 16 + offset = 20 位地址. 我既不清楚为什么把乘以 16 的那个部分叫 segment, 也不清楚为什么做成把一个 16 位值乘以 16. 由公式可知

- 段地址不连续, 每个段的地址都是 16 的整数倍; 偏移地址连续
- offset 的大小决定段的大小, 是 2 ** 16 = 65536 = 64k
- 2 个 16 位寄存器共 32 位表示 20 位地址, 其余的 12 位造成很多重复的地址
- 两个段的重叠部分至多 64k - 16 - 16 = 65504; 不重叠的话 640k = 10 个段, 1024k = 16 个段

有 4 个段寄存器 cs, ds, es, ss, cpu 占用 2 个. 386 加了 fs, gs 段寄存器和 lfs, lgs, lss 指令. 386 通用寄存器是 32 位, 保护模式下寻址也是 32 位, 不需要段寄存器, 段寄存器用来保存别的数据.

代码 cs:ip

- a.k.a. program counter (pc), instruction pointer (ip), instruction address register (iar), instruction counter
- 修改 cs 和 ip 必须一次性完成, 专有数据类型 far pointer (ptr16:16/32)

栈 ss:sp

- 就是数据结构里的栈, 专有指令 push, pop
- ss:sp 保存的内存地址叫栈顶. push arg 从 sp 减去 sizeof arg, 然后把 arg 写到栈顶
- sp 保存 offset 但不能用于寻址, 要修改栈顶只能先 mov bp, sp 然后修改 [bp], bp 默认段 ss, 可以省一个段寄存器重写
- 修改 ss 和 sp 不需要一次性完成. 但如果两条修改指令之间发生了中断而进入中断服务例程, 就会使用栈, 这时的栈只修改了一半, 就会出错. 所以 286+ 的 mov ss, r/m16 的下一条指令无法中断以便放置 mov sp, xxx, 就可以省去 cli 指令 (cli 屏蔽 "可屏蔽中断", 听名字就是个残废)

除 cs:ip 和 ss:sp 外的都是数据, 比如 cs:di, ds:bp, es:123, ss:bx. 代码里往往需要标记地址但有不同的写法, 可能是 cs:[di], ds:[bp], es:123, ss:[bx]

- 可以用来寻址的寄存器是 bp/bx/si/di; 省略段寄存器时 [bp] 默认 ss, 其余都默认 ds; [imm] 默认 ds
- 源数据 ds:si 和目的数据 es:di 是两个常见的说法
- `lds/les r16/32, m16:16/32`, `lfs/lgs/lss r16/32/64, m16:16/32/64` 用 `jmp m16:16` 修改 cs:ip 的方式修改 ds/es/fs/gs/ss:reg, 没有 lcs. 这些指令只是增加 m16:16/32/64 的利用率; 修改数据地址无须一次性完成, 可以用两条指令依次修改. intel 说参数类型是 m16:16, 其实也可以说是 m16&16

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

名字 | 行为
-|-
bank switching  | 数据仍在原地. 通过专用语句的切换, 同一地址对应到存储的不同区域; 相当于增加地址宽度
paging          | 数据转移至其他存储, 比如内存到硬盘. 寄存器到缓存又到内存算 paging 吗?

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

`in port (al/ax/eax), imm8/dx` 和 `out imm8/dx, port (al/ax/eax)`

端口指有些外设的寄存器, 端口地址是 16 位, 总共 64k = 65536 个. 端口和映射的内存一样用于访问外设, 不占用内存地址空间; 或者说端口的地址空间是 64k. 有说法是端口和内存复用地址空间, 因为访问端口和内存都通过地址数据总线, 由开关切换访问谁. 我认为这只是实现细节, 地址空间是两个, 不存在复用; 从代码上看内存和端口的区分很明显, 应该很难把两个地址空间搞混. 访问端口时, 用 in 串行读取单个地址上的 1 字节, out 串行写入单个地址上的 1 字节; 访问映射的内存时, 用 mov data, mem 依次 (也是串行) 读取一组地址, 每次 sizeof data 字节, mov mem, data 依次写入一组地址.

```
; todo or delete? 代码示例
;
; 通过 bios 间接访问硬件
; 输入 - 访问 端口xxx?? 读取键盘
; 输出 - 访问映射到地址 xxx??? 的屏幕缓冲区
```

### interrupt

按设计, cpu 每执行一条或一组指令就查看是否有中断请求, 有的话就暂停当前执行的指令去执行请求指出的指令, 执行完可能会继续执行之前暂停的指令. 用途: cpu 访问有些硬件速度很慢, 但又需要它的数据; 与其每次执行很慢的查询, 不如开放一个 cpu 接口, 硬件有需要就告诉接口; cpu 查询接口很快, 发现硬件通过接口传递了信号后再执行较慢的查询过程去弄清楚细节; 这个信号就叫中断请求. intel interrupts 占用下列名词; arm 还占用 reset.

- exceptions. generated by cpu
    - faults. return address = the instruction that generated the exception
    - traps
    - aborts
- Interrupt Request (IRQ) or Hardware Interrupt
    - IRQ Lines, or Pin-based IRQs
    - Message Signaled Interrupts
- Software Interrupt. generated by int n instruction

`cli` 让 cpu 此后不响应可屏蔽中断; 286+ 上 `mov ss, reg` 的下一条指令无法中断, 用于在 mov ss 之后 mov sp.

总共 256 种中断, 硬件中断由 8259 把 irq 映射到 int n, cpu 也能引发中断, int n(0 ~ 255) 指令也能引发中断; 所有 256 种中断都能用 int n 从代码里引发; 要注意一点, int 指令引发的中断和 fault 引发的中断在进入中断服务例程时栈上的返回地址不一样, [例子](#bound-80188-m1616-int-5). 内存地址 0 ~ 1024 是 256 个 m16:16, m16:16 指向的 ptr16:16 是中断服务例程的地址. cpu 决定处理中断 n 时跳到内存地址 n * 4 处的值, 设 es = 0 有 debug `es: jmp far [] n * 4` 或 masm `jmp dword ptr es:(n * 4)`.

https://wiki.osdev.org/Interrupt_Vector_Table
```
memory
1024 = 1k = 0x400       -
        real mode Interrupt Vector Table (IVT)
0                       -
```

用 debug 把内存 0:0 开始的 1k 字节打印到文件
```
> fff debug

* 由于输出重定向到了文件, 下面输入导致的回显都不出现在屏幕上
* 按 q 回车退出后查看文件 fff

d 0:0 3ff
q
```

https://alex.dzyoba.com/blog/os-interrupts/ Interrupt descriptor table (IDT) since 80286 protected mode

https://wiki.osdev.org/Interrupts LIDT 指令可以改变 ivt 的默认位置 0:0, 但很少用

### jmp short, near, far, long

a.k.a. | opcode | - | operand type | 8086 | x86 | x64
-|-|-|-|-|-|-
short       | eb       | cb | rel8     | yes   | sign extended | sign extended
near        | e9       | cw | rel16    | yes   | yes           | no
|           | e9       | cd | rel32    | no    | yes           | sign extended
|           | ff       | /4 | r/m16    | yes   | zero extended | no
|           | ff       | /4 | r/m32    | no    | yes           | no
|           | ff       | /4 | r/m64    | no    | no            | yes
far, long   | ea       | cd | ptr16:16 | yes   | no            | no
|           | ea       | cp | ptr16:32 | no    | yes           | no
|           | ff       | /5 | m16:16   | yes   | no            | no
|           | ff       | /5 | m16:32   | no    | yes           | no
|           | REX.W ff | /5 | m16:64   | no    | no            | yes

\* ignoring long mode (64-bit mode, compatibility mode), protected mode, real mode, unreal mode, ...

operand type | debug | masm | meaning
-|-|-|-
rel16       | jmp 7             | [error A2076](#error-a2076-jump-destination-must-specify-a-label)
r16         | jmp bx            | jmp bx                    | load  word t from register bx, near jump to t; bx = value of t
m16         | jmp [bx]          | jmp  word ptr [bx]        | load  word t from memory ds:bx, near jump to t; bx = offset of t
m16:16      | jmp far [bp si 3] | jmp dword ptr 3[bp + si]  | load dword t from memory ds:(bp + si + 3), far jump to t
seg:r16     | es: jmp bx        | not allowed               | = jmp bx, es is not used
seg:m16     | es: jmp [bx]      | jmp  word ptr es:[bx]     | load word t from memory es:bx, near jump to t
seg:(m16:16)| es: jmp far [bx]  | jmp dword ptr es:[bx]     | load dword t from memory es:bx, far jump to t
ptr16:16    | jmp 0:0           | error A2076               | far jump to an immediate value

示例: near jump rel16
```
debug
-a
1337:0100 jmp 0
1337:0103
-u 100 l3
1337:0100 E9FDFE        JMP 0000
-r
AX=0000  BX=0000  CX=0000  DX=0000  SP=00FD  BP=0000  SI=0000  DI=0000
DS=1337  ES=1337  SS=1337  CS=1337  IP=0100   NV UP EI PL NZ NA PO NC
1337:0100 E9FDFE        JMP 0000
-t
... IP=0000
1337:0000 CD20          INT 20
-q
```

1. e9 = jmp rel16
1. 考虑字节序, 参数是 0xfefd
1. 执行 e9fdfe 前 ip = 0x100
1. 执行 e9fdfe 时 ip = 0x103
1. 执行 e9fdfe 后 ip = 0x103 + 0xfefd = 0x10000 -> to word = 0

near jump [r16, r32, m16, m32], far jump
```
operand                                 32 bit                      16 bit
r16         jmp ax                   66 ff e0                       ff e0
r32         jmp eax                     ff e0
m16         jmp [di]                 67 ff 25                       ff 25
m16         jmp word ptr ds:0x1234   66 ff 25 34 12 00 00 (*3)      ff 26 34 12 (*1)    jmp [0x1234]
m32         jmp [0x12345678]            ff 25 78 56 34 12 (*2)

*1. opcode extension = 4, 从 http://ref.x86asm.net/coder32.html#modrm_byte_16
找 (In decimal) /digit (Opcode) = 4 的列, 然后找 disp16 的行, 交点是 26

*2. http://ref.x86asm.net/coder32.html#modrm_byte_32 列 4 和行 disp32 的交点是 25

*3. 32-bit ModR/M Byte 已经没有位置表示 op 是 m16 了, 所以额外用一整个前缀字节 66 表示
前缀字节的选择很有限, 不能和已有的 opcode 重复. 可以看到前缀 66 修饰的指令尽管用了较短的操作数但长度没变

m32         jmp cs:0x12345678        2e ff 25 78 56 34 12           <- cs segment override
m32         jmp es:0x12345678        26 ff 25 78 56 34 12           <- es segment override
m32         jmp ss:0x12345678        36 ff 25 78 56 34 12           <- ss segment override
m32         call [0x12345678]           ff 15 78 56 34 12

ptr16:32    jmp 0xaabb:0x1122           ea 22 11 00 00 bb aa        ea 22 11 bb aa      ptr16:16

* 此时误以为 m16:16 语法类似 [0x1234]:[0x5678], 编译不过 (必然的), 于是打算凑个 16 位机器码看反汇编成啥
opcode extension 5 要求使用 ModR/M Byte, 但 modr/m 里没有 disp16:disp16, 用 disp16 凑了个 2e, 进而凑出个
ff 2e 34 12, 反汇编得到 jmp far [0x1234]. what the "far" is this? 用 32 位编译 jmp far [0x1234] 得到
ff 2d 34 12 00 00   jmp FWORD PTR ds:0x1234 - 原来 far 是 fword, oooooright. 还凑出了
ff 2f               jmp FWORD PTR [edi]
ff 2e               jmp FWORD PTR [esi]. 理解 m16:16 之后有了下面代码

m16:32      jmp far [0x100]             ff 2d 00 01 00 00           ff 2e 00 01         m16:16
m16:32      jmp far [ds:0x100]       3e ff 2d 00 01 00 00        3e ff 2e 00 01         m16:16
m16:32      jmp far [di]             67 ff 2d                       ff 2d               m16:16
m16:32      jmp far [edi]               ff 2f
```

- 16 位模式, debug 用 jmp far, masm 用 jmp dword ptr; godbolt.org 接受前者, 输出后者, 奇葩
- dword ptr 无法用来区分 m32 和 m16:16, 但没有同时接受 m32 和 m16:16 的 jump
- far 应该是和 [] 和 ptr 一样用于提示编译器选择合适的 opcode
- godbolt.org 用 -felf64 编译 `jmp far [rdi]` 得到 `48 ff 2f rex.W jmp fword ptr [rdi]`. m16:64 对应 rex.W fword ptr?

godbolt.org 32 位的一些编译结果
```
jmp far   [di]       67 ff 2d       jmp FWORD PTR [di]
jmp dword [di]       67 ff 25       jmp DWORD PTR [di]
jmp word  [di]    66 67 ff 25       jmp WORD  PTR [di]

jmp far   [edi]         ff 2f       jmp FWORD PTR [edi]
jmp dword [edi]         ff 27       jmp DWORD PTR [edi]
jmp word  [edi]      66 ff 27       jmp WORD  PTR [edi]

jmp fword [di]      <Compilation failed>
jmp fword [edi]     <Compilation failed>
```

32 位下 m16 是指向 16 位内存的 32 位 offset, jmp m16 要对 m16 指向的内存进行 zero extend, 如果 m16 保存在 16 位寄存器里就会发生 2 次 zero extend. 打开 https://carlosrafaelgn.com.br/Asm86/ 输入下列代码; 点右上角的 windows, registers; 用左上角的 step 观察

```
    mov  eax, dest      ; EAX = 0x00020410
    push eax            ; ESP = 0x000203FC

    ; godbolt.org says [sp] is invalid effective address, so use [di] instead
    mov  edi, esp
    jmp  jumps

dest:
    nop

jumps:
;   jmp             di  ; jmp r16           EIP = 0x000003FC
;   jmp            [di] ; jmp m32 by r16    Invalid reading address: 0x000003FC
;   jmp  word ptr  [di] ; jmp m16 by r16    Invalid reading address: 0x000003FC
;   jmp dword ptr  [di] ; jmp m32 by r16    Invalid reading address: 0x000003FC

;   jmp            edi  ; jmp r32  EIP = 0x000203FC
;   jmp           [edi] ; jmp m32  Invalid reading size: 0 // bug? this is same as jmp dword ptr [edi]
;   jmp  word ptr [edi] ; jmp m16  EIP = 0x00000410
    jmp dword ptr [edi] ; jmp m32  EIP = 0x00020410
```

示例: m16:16 的第 1 个 2 字节给 ip, 第 2 个 2 字节给 cs; 这和 far call, far return 时栈里的 cs 和 ip 顺序一致.
```
debug
-a
1337:0100 db 11 22 33 44
1337:0104 jmp far [] 100
1337:0108
-d 100 l8
1337:0100  11 22 33 44 FF 2E 00 01                           ."3D....
-t =104
AX=0000  BX=0000  CX=0000  DX=0000  SP=00FD  BP=0000  SI=0000  DI=0000
DS=1337  ES=1337  SS=1337  CS=4433  IP=2211   NV UP EI PL NZ NA PO NC
4433:2211 0000          ADD [BX+SI],AL                         DS:0000=CD
-q
```

示例: 用内存中 jmp ptr16:16 指令操作数的偏移当 jmp m16:16 的参数

- `jmp ptr16:16` 指令是 `ea xx xx xx xx`, 5 字节, 从第 2 字节开始的 4 字节是 offset 和 segment
- 这个例子里 `jmp m16:16` 的 m16:16 指向 ds:(`jmp ptr16:16` 的位置 + 1 字节)
- 没法用 jmp m16 实现 jmp m16:16. jmp m16 是个 near jump, 不修改 cs

程序设计 | 注释
-|-
cs:100 jmp far [10b]    | 0x10b = (下面的 jmp ptr16:16 指令的偏移) 0x10a + 1. 代码里可以用标签获得指令的偏移
cs:104 db 1 2 3 4 5 6   | 随意的填充字节, 目的是隔开两个 jump. 不填充也行
cs:10a jmp 1337:0       | 这个 5 字节指令的后 4 位内存的偏移被第一个 jump 视作 m16:16
1337:0 int 3            | 纯粹是好玩儿, 我想让 debug 中断到这里. 有没有这句都不影响本示例

ptr16:16 是两个编译时就确定的立即数, 写代码的时候就得知道要跳到哪. 我想往它指向的内存写 int 3, 如果覆盖了其他程序, 就很可能要重启 dos 虚拟机. 如何确保 ptr16:16 指向空闲内存? 我不确定, 可能的办法是:
- 代码里定义一个大变量, 当空闲内存
- 运行时: 整个 cs 段应该都能用, 当然得避免覆盖自己的代码
- 运行时: dos 2 的 int21h/ah48h 可能能用来确定空闲内存
- 运行时才获知空闲内存的地址, 那时已经没法编译了, 只能从地址凑 jmp ptr16:16 的 5 字节指令, 写入内存去执行

```
debug
-a
1425:0100 jmp far [] 10b
1425:0104 db 1 2 3 4 5 6
1425:010A jmp 1337:0
1425:010F
-a 1337:0
1337:0000 int 3
1337:0001
-d 100 lf
1425:0100  FF 2E 0B 01 01 02 03 04-05 06 EA 00 00 37 13
-g

AX=0000  BX=0000  CX=0000  DX=0000  SP=00FD  BP=0000  SI=0000  DI=0000
DS=1425  ES=1425  SS=1425  CS=1337  IP=0000   NV UP EI PL NZ NA PO NC
1337:0000 CC            INT 3
-q
```

### n-in-1 instructions

n | 1 | comments
-|-|-
(compare and jump)                      | bound                 | exception, slow
(see below)                             | call, ret; int, iret
push ebp; mov ebp, esp; sub esp, m      | enter m, 0            | slow
(load segment and offset separately)    | lds/les/lfs/lgs/lss
mov esp, ebp; pop ebp                   | leave                 | 3 μops vs. 2+ μops
dec reg; jnz                            | loop                  | slow

call, ret; int, iret 这些 jump 读取和修改栈

- intel 不允许 ip/eip/rip 当操作数, 指令寄存器通过 jmp, call, ret 间接修改
- 8086, 8088 有 pop cs, opcode 0xf = 15 和 mov cs, reg. 8086 online 模拟器 https://idrist11.github.io/8086-Online-IDE/app.html
- arm32 允许读写 ip, arm64 不允许

```
    call f                  call far f              int n
                                                            pushf
                                    push cs                 push cs
            push next               push next               push next
            jmp f                   jmp far seg-f:f         jmp far [0:n * 4]
        next:
------------------------- pseudo ------------- codes -------------------------
f:
    ret                     ret far                 iret
            add sp, 2                add sp, 4              add sp, 4
                                                            popf
            jmp [sp - 2]             jmp far [sp - 4]       jmp far [sp - 6]
```

http://www.phatcode.net/res/223/files/html/Chapter_12/CH12-3.html#HEADING3-73<br>
http://www.posix.nl/linuxassembly/nasmdochtml/nasmdoca.html#section-A.27

```
; ENTER Locals, LexLevel

                push    bp              ;Save dynamic link.
                mov     tempreg, sp     ;Save for later.
                cmp     LexLevel, 0     ;Done if this is lex level zero.
                je      Lex0
lp:             dec     LexLevel
                jz      Done            ;Quit if at last lex level.
                sub     bp, 2           ;Index into display in prev act rec
                push    [bp]            ; and push each element there.
                jmp     lp              ;Repeat for each entry.

Done:           push    tempreg         ;Add entry for current lex level.
Lex0:           mov     bp, tempreg     ;Ptr to current act rec.
                sub     sp, Locals      ;Allocate local storage
```

### 1/n instructions

1 | steps | 1/n
-|-|-
sub dst, src | dst -= src           | -
|| affect af, cf, pf, sf, zf        | cmp
and dst, src | dst &= src           | -
|| cf = of = 0; affect pf, sf, zf   | test

https://reverseengineering.stackexchange.com/questions/20838/how-the-cmp-instruction-uses-condition-flags

cmp dst, src | cf | zf
-|-|-
dst = src | 0 | 1
dst < src | 1 | 0
dst > src | 0 | 0

### mnemonic a.k.a.s

mnemonic | a.k.a.
-|-
jz  | je
jnz | jne

## dos

dos 的单任务指所有程序依次执行. 启动 dos 后执行 command.com; 在 command.com 里启动程序后执行该程序; command.com 保留的内存, 硬盘等各种存储都还在, 但不再执行它的代码, 相当于暂停; 程序退出后继续执行 command.com.

多任务有多种可能. 可能是单个 cpu 把时间分成小段, 轮流执行每个段里不同程序的代码; 也可能是多个 cpu 把时间分成小段, 执行不同程序的代码; 也可能是多个 cpu 各自执行不同程序的代码. 不清楚细节.

为让 dos 正常运行, 程序要解决和操作系统 (dos 或者说 command.com) 的衔接问题. 启动时 dos 做一些准备工作之后从程序的入口开始执行, 进入程序时准备工作已经完成了, 程序不用帮忙. 退出时得有种办法继续执行 dos, 不应该每次退出程序都重新启动 dos, 本质就是跳到 dos 暂停时的代码处继续执行.

### program

称呼 | 意思
-|-
executable  | 可执行文件. 显然里面存放了 cpu 指令. 往往在操作系统里执行
process     | 进程. 放到到内存打算执行的 executable, 往往有操作系统为其做准备工作; 放到内存但不打算执行则不是 process
program     | 程序. executable or process

dos 在执行 com 和 exe 时用数据结构 psp = Program Segment Prefix 存储程序状态, psp 类似 CP/M 里的 Zero Page.

[示例: 从 psp 获取程序的命令行参数](#从-psp-获取程序的命令行参数)

如果可执行文件不大于 段 - psp - word 0 = 64k - 0x100 - 2 = 65278, 载入内存执行时放在一个段里就行, com 文件就是这样. 但如果文件 > 65278 一个段就放不下了. dos 发明了 mz exe, 这种文件把代码分成好多不大于 64k 的块; 加载时 psp 单独放在第一个段, 其余每个块对应一个段.

program 启动时代码, 栈, 数据段是下列值:

-| cs | ds | es | ss | ip | sp | 通用寄存器
-|-|-|-|-|-|-|-
com | 1. | 1. | 1. | 1. | 0x100 | 0xfffe | http://www.fysnet.net/yourhelp.htm
exe | 3. | 1. | 1. | 3. | 2. | 2. | http://www.tavi.co.uk/phobos/exeformat.html

- 1 . seg psp
- 2 . from file header
- 3 . from file header, relocated

program 退出时需要调用 dos 提供的函数.

dos 1

- 退出需要调用 int21h/ah0, 它**隐含**使用 cs, 要求 cs 指向 psp 所在的段 (seg psp)
- int20h 是 int21h/ah0 的别名, 机器码更短
- psp 的前两个字节是 int 20h

https://stackoverflow.com/questions/12591673/whats-the-difference-between-using-int-0x20-and-int-0x21-ah-0x4c-to-exit-a-16 说用 retn 结束时不需要 push 任何东西, 因为程序开始时的栈顶是 0; 我也记得 com 文件初始 sp 是 0xfffe, 而 0xfffe 和 0xffff 都是 0; 因此在 cs 未改变且栈空的前提下 retn 导致 `ip = word [] 0xfffe`

综上, 要退出, 既可以在 cs = seg psp 时 int20h, 也可以用下面 3 种方法执行 psp 开始处的 int20h

1. cs = seg psp 时跳到 psp 的开头
    ```
    xor ax, ax
    jmp ax ; jump to seg-psp:0
    ```
1. cs = seg psp 时 `retn`, 因为程序开始时栈顶是 word 0, 等于用 pop ip 实现 jmp 0
1. cs != seg psp 时需要设置 cs, 但改变 cs 会导致跳转, 接下去的语句就没法执行了, 所以必须跳到正确的位置. [kb72848](#hello-world) 指出可以用两个 push 配合 far return
    ```
    push ds ; 开始时 ds = es = seg psp
    xor ax, ax
    push ax ; push 0 也可以挪到 far return 前面

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

dos 和 bios api 详解 http://www.techhelpmanual.com/2-main_menu.html

dos api 基本是 int 21h. 为啥用 int 不用 jmp, call 呢? 有几种说法
- int 指令更短 - 没错, 但要额外做把字节通过 ivt 转换到实际地址的工作. 宁愿消耗运行时间也要缩短代码? 有可能
- 数字比地址灵活, 修改 ivt 中和数字对应的地址较容易 - 灵活不了多少
- 数字比地址容易记忆 - 这类解释让人哭笑不得的地方在, 一般情况下它没错, 但具体看它要解释的现象, 内存映射已经用了大量的地址, 从没见考虑过容易记忆的事; 它要解释的现象明显违背了一般规律, 却仍试图用一般规律去解释那现象. 这样的解释, 用苏格拉底的话叫 "为了说话而说话", 我非常确定这是个普遍现象: 语言反过来控制了思维
- int 已经做出来了, 所有资源已经占用了, 不用也浪费 - 这条有道理. 不过这条好像是我自己编的

int 是 intel 发明的 software interrupt. intel 老早就喜欢把概念分出高低等级: supervisor; kernel, user; ring0, ring3; instructions, interrupts; general/special purpose register; ... 引入新机制, 划定等级确实是解决问题的一种手段, 但滥用的话就是形式控制了内容, 坏处可能会超过好处.

dos api 文档示例

- int21h/ah0 http://www.ctyme.com/intr/rb-2551.htm
    - DOS 1+ - TERMINATE PROGRAM
    - Entry: CS = PSP segment
    - Notes: Microsoft recommends using INT 21/AH=4Ch for DOS 2+. This function sets the program's return code (ERRORLEVEL) to 00h. Execution continues at the address stored in INT 22 after DOS performs whatever cleanup it needs to do (restoring the INT 22,INT 23,INT 24 vectors from the PSP assumed to be located at offset 0000h in the segment indicated by the stack copy of CS, etc.). If the PSP is its own parent, the process's memory is not freed; if INT 22 additionally points into the terminating program, the process is effectively NOT terminated. Not supported by MS Windows 3.0 DOSX.EXE DOS extender
- int21h/ah4ch
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

- https://en.wikipedia.org/wiki/Portable_Executable Portable Executable (PE) 格式是 executables, object code, DLLs, FON Font 等文件的格式, 用于 32/64 位 windows
- 类比名字, pe 应该是 pef, 就像 omf, coff; 类比系统, elf in Linux and most other versions of Unix; Mach-O in macOS and iOS
- https://blog.kowalczyk.info/articles/pefileformat.html 为兼容 msdos 和旧版 windows, pe 保留 mz 头
- https://thestarman.pcministry.com/asm/debug/DOSstub.htm pe 的 mz 头后面是个 16 位 dos 存根程序, 一般显示:
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

dos 和 cp/m 的 com 文件结构虽然一样但互不兼容. dos 文件包含的是 x86 指令和 dos 系统调用; cp/m 文件包含 8080 指令和 cp/m 系统调用, 特定于机器的程序可能还会有 8085, Z80 指令

fat binary

- https://en.wikipedia.org/wiki/Fat_binary
- 基本上是把多个功能一样的程序放到一个文件里, 开头的代码选择使用其中一个
- 开头的代码即入口代码, 是在几个系统中都有效但功能不同的指令, 在不同的系统中执行有不同的效果, 比如
    `C3h, 03h, 01h` 在 x86 上是 `ret`, 在 8080 上是 `JP 103h`

(dos 4+?) 有些 exe 文件会使用 com 扩展名. 加载程序查看文件的前几个字节, 如果发现是 exe 就按 exe 执行, 否则才按 com 执行<br>
https://retrocomputing.stackexchange.com/questions/14520/how-did-large-com-files-work<br>
https://github.com/microsoft/MS-DOS/blob/master/v2.0/source/EXEC.ASM#L331

DISKCOMP, DISKCOPY, FORMAT, MODE, MORE, TREE 是以 .com 结尾的 exe, 因为老的 bat 文件可能使用命令的全名, win nt 为兼容这些 bat 就保留了前述 exe 的原名.

执行命令时如果省略扩展名, dos 先找 com 再找 exe, 比如 foo 依次找 `foo`, `foo.com`, `foo.exe`. win nt 环境变量 PATHEXT 可以指定扩展名顺序, 默认仍然是 com 先于 exe

/AT 和 .model tiny 的区别

> Microsoft MASM 6.1 Programmer's Guide.pdf，p56，Tiny Model<br>
/AT does not insert a .MODEL directive. It only verifies that there are no base or pointer fixups, and sends /TINY to the linker.

org n 的作用

- 把其后的语句放在可执行文件的代码部分的第 n 字节; 若造成该语句后移, 用 0 填充之间的部分; 相应调整标签的值
- 多个源文件, 或生成的不是 com 时 org 可能偏大 http://support.microsoft.com/kb/39441/en-us
- 生成 com 文件 && 使用了 org && 其后的语句被 end 标为起始地址 && 将生成 > 256 字节的可执行文件<br>
    则删除起始地址前面的内容, 参考 [起始地址](#起始地址)/com 文件的起始地址

### debug.com

程序员写代码, 编译器把代码变成保存指令的可执行文件, 操作系统把可执行文件加载进内存, cpu 执行指令.

dos 程序 debug.com 可以汇编, 反汇编, 调试和执行 8086 指令, 查看和修改寄存器和内存, 等等, 非常强大; 又非常简洁; 是学习 8086 的好帮手, 一定要掌握它. 它不认识 8086 之外的指令和数据类型如 dword fword qword tbyte.

本文的 debug 示例都能在 (/readme 里列出的) online emulator 里的 debug 里执行, 无需本地虚拟机

command | https://kb.iu.edu/d/afhs
-|-
?                           | Displays a list of debug commands
A [address]                 | Assembles 8086/8087/8088 mnemonics
C range address             | Compares two portions of memory
D [range]                   | dump. Displays the contents of a portion of memory
E address [list]            | Enters data into memory starting at a specified address
F range list                | Fills a range of memory with specified values
G [=address] [addresses]    | go. Runs the executable file that is in memory
H value1 value2             | hex. Performs hexadecimal arithmetic
I port                      | input. Displays one byte value from a specified port
L [address] [drive] [firstsector] [number] | Loads the contents of a file or disk sectors into memory
M range address             | move. Copies the contents of a block of memory
N [pathname] [arglist]      | name. Specifies a file for an l or w command, or specifies the parameters for the file you are testing
O port byte                 | output. Sends a single byte value to an output port
P [=address] [number]       | proceed. Executes a loop, a repeated string instruction, a software interrupt, or a subroutine
Q                           | quit. Stops the Debug session
R [register]                | register. Displays or alters the contents of one or more registers
S range list                | Searches a portion of memory for a specified pattern of one or more byte values
T [=address] [value]        | trace. Executes one instruction and then displays the contents of all registers, the status of all flags, and the decoded form of the instruction that Debug will execute next
U [range]                   | unassemble. Disassembles bytes and displays the corresponding source statements
W [address] [drive] [firstsector] [number] | Writes the file being tested to a disk
XA [#pages]                 | allocate expanded memory
XD [handle]                 | deallocate expanded memory
XM [Lpage] [Ppage] [handle] | map expanded memory pages
XS                          | display expanded memory status

args | meaning
-|-
number      | 输入输出的数字都是 16 进制, 不带前后缀, 忽略 h 后缀
address     | 112233 or 2244:112233 or ds:123
addresses   | address address ...
list        | 11 22 33 ... or 'abc...' or "abc..."
range       | address1 address2 or address l n or addressln; n = 0 means 0x1,0000 = 64k

hotkeys | meaning
-|-
Cntl-Break      | 停止并返回 debug; 对 g 无效
Cntl-NumLock    | 暂停, 比如打印一大块内存时暂停; 对 g 无效

samples | meaning
-|-
g =100 102 105  | 从 cs:0x100 开始执行, 在 0x102, 0x105 处放置断点; 断点至多 10 个, 任一断点命中都清除所有断点, 不命中则不清除<br>开始和断点位置都要写对, 如果指向指令的中间就要么执行错误的指令要么命中不了断点
g =132 132      | 暂停在 cs:0x132, 经常用来跳过代码里的 int 3. 只有 g 能设置断点, 也就只有 g 能停到某条语句, p 和 t 都不能
t =120 5        | 从 cs:0x120 开始执行 5 条指令后暂停
n file<br>l     | 加载文件, 也可以用命令行 `debug file`, 加载后 (bx << 16) + cx = 程序长度/要写入的文件的字节数, both 0 if no file<br>用 debug 执行的程序结束后想再次执行需要 reload, 即再次执行 l

a (assemble) 的语法是啥? 这语法非常精确, 没见过比它更精确的语法了

- 最精确的是方括号. 不开玩笑. 下面的写法看似随意, 实则最贴合指令对内存地点 (memory location) 的定义:
    ```
    inputs                                              outputs
    bx si [] 3                                          [3]
    3 bx [] si                                          [si + 3]
    bx [] si [] 1 [] 2 [] 3; bx [si] [] [] [] 1 2 3 []  [si + 6]
    [] bx si 3; [] bx + si + 3; 3 [] bx si; 3 [sibx     [bx + si + 3]
    ```
    尝试发现算法可能如下
    1. 找左方括号, 沿途累加遇到的数字, 检查语法
    1. 找到左方括号, 继续走到行尾, 沿途累加遇到的数字, 记下 bp, bx, di, si, 检查语法
    1. 记下来的数字和寄存器排序, 用加号连接, 外面套上方括号, 替换原语句

    意义: 明显指出了 (左) 方括号只是用来标记操作数的类型, 单个符号就能起到此作用, 不一定非要引号或括号

- 重写段寄存器时段名和冒号必须放语句前, mov ax, es:100 必须写为 es: mov ax, [] 100<br>
首先这体现了指令里的寄存器重写前缀; 其次可以写 (没啥用的) es: mov ax, 100, 用左边的写法就做不到

- 额外语法
    - ; 单行注释
    - db 往内存放入一组字节

### cv.exe, pwb.exe

cv = code view, 调试器

f4 = view output (hide cv), f6 = move focus among windows<br>
f5 = go, f7 = go to cursor, f8 = trace, f9 = break point, f10 = step

调试时要看源代码而不是反汇编需确保两点

- 编译参数 -Zi dd.msm
- 代码段用 'code' 类

pwb = programmer's workbench, ide

可以创建项目, 它调用 nmake 编译项目文件. 只接受 .asm 不接受 .msm 所以不用它

## a 16 bit dos program in masm

masm 要求源文件具备两个要素: end 和非空的 segment; 这两样东西对生成可执行文件毫无贡献, 理由是:

- 如果程序啥都不做, 源代码应该啥都不需要写, 因此是个空文件, 而不是一个非空段 + end
- 非空段有意义的部分是使段非空的文本, 而不是段定义

masm 要求源代码从两个无用的结构开始, 预示了此后的编程中会遇到很多 masm 有意或无意制造的障碍.

新建一个空文件 dd.msm 用 masm 编译看看会发生什么.

`ml -Foout\ dd.msm -Feout\` 输出
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

`ml -Foout\ dd.msm -Feout\` 输出
```
LINK : warning L4021: no stack segment
LINK : error L4076: no segments defined
```

`ml -Foout\ dd.msm -Feout\ -AT` 输出
```
LINK : error L4076: no segments defined
```
\* *-AT 让 ml 给 link 传 /tiny, 从而生成 com 文件*<br>
\* *不想看版权信息可以 `ml -nologo -Foout\ dd.msm -Feout\ -AT -link -nologo`*

可以看到 link 报告了 1 个错误. 此处的亮点是尽管有连接错误, 仍生成了可执行文件.

masm 认为程序应该有栈, 因此没有 -AT 时 link 还警告 L4021; -AT 没有此警告是因为 com 就 1 个段, 栈也使用此段. 错误说没定义段, 没说什么 "非空段" 所以下面代码似乎就够了?

```
xxx segment
xxx ends
end
```

编译发现错误信息完全没变, 因此光有段不行, 很可能还得是非空段. 是否还记得一开始说的 "毫无贡献"?

### 非空的段

定义一个非空的段试试:

```
xxx segment
db 1
xxx ends
end
```

`ml -Foout\ dd.msm -Feout\ -AT` 输出
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

L4038 很明确, L4055 很难理解, 它俩说的却是同一个意思: 需要指定[起始地址](#起始地址)或叫入口地址, 否则打印警告并把第 1 句当作入口. 因此要用 end 指定个标签. 把 db 1 改为正常的返回语句, 缩进, 得到下面的完整程序.

### the program

```
; com
; ml -Foout\ dd.msm -Feout\ -AT

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

- end 后面必须是标签不能是立即数 (字面量), 否则 error A2094: operand must be relocatable
- 把变量名放 end 后面得到 error A2095: constant or relocatable label expected
- 根据 8086/lab/stack 知道 exe 运行时栈顶的 word 被改为 ff ff; 让 exe 代码和栈共用一个段时为防止覆盖那里的指令需要弄点填充字节. 写填充字节时为了确定填几个, 试了几个数值, 发现至少得 4 字节程序才正常退出, 但在 debug 里执行不正常; 用 debug 一看发现不仅是修改了最后两字节. debug out\dd.exe 时, 查看内存没啥问题; t 执行一句后再查看, 前 10 字节内容都变了. 加大填充的长度发现最后 10 字节会被修改; 隐约记得以前见过这情况. 因此要在 debug 里也能正常退出得填充 10 字节 (那填充 4 字节算不算正确?). mov ax, 4c00h int 21h 是 5 字节, 加上 10 个填充字节等于 15 字节. 为了对齐到 word 再加 1 字节, 填充了 11 字节, 否则起始 ip 是 1 而不是 0; 尽管我不知道起始 ip 是 1 有啥问题. [栈的后 10 字节](#打印栈的后-10-字节)

上面啥都不做的 masm 16 位 dos 程序包含 4 或 5 个要点

- 为正常编译, 写 masm 要求的 end
- 为正常连接, 写 link 要求的 none empty segment
- 为正常连接, 写 link 需要的 end begin, 不写的话是警告而不是错误
- 为正常运行, 写 dos (?) 要求的填充字节. 不把代码放栈里时可忽略本条
- 为正常退出, 写 dos 要求的返回语句

### 起始地址

起始地址决定程序开始时 cs 和 ip 的值.

**连接器如何确定起始地址**

ml 找源文件中用 end 指出的标签, 把它写到 obj<br>
\* *验证: 用 ml -c 编译两个 obj 文件, 一个指定起始地址一个不指定, 比较它们*<br>
link 从 obj 找出 ml 写入的起始标签作起始地址. 起始地址写入 exe 文件头的 cs 和 ip; com 没有文件头, 连接器检查起始标签是不是第一句, 不是的话警告 l4055<br>
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

com 没有文件头. 情况复杂, 有时候忽略 end 指出的标签, 看不出规律, 我列举两种

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

文件头记录连接器生成的入口地址. https://wiki.osdev.org/MZ

## masm 命令行

### 源文件编码

masm 的 source-charset 固定为 ascii; 串原样放入二进制, 相当于 execution-charset = source-charset; 无需转义字符, 因为指定字符时既可以用字面量也可以用数字, 字符字面量就是其 ascii 值.

### 所有命令行选项

ml 开关 (选项, 参数), 包括 ml -link 后的参数, 起始字符是 - 或 /, 开关区分大小写; link 只能是 /, 不区分大小写.

*写这里时发现 dosbox 中命令超过一行而换行后, 没法把光标移回到上一行*

**对单个文件生效的开关必须规定个位置否则 file1 -xxx file2 不能确定 -xxx 作用于谁**

masm 规定

- 对单个文件生效的开关放文件前
- 命令行开关和文件名都可以用引号括起来
- 双引号内 "" 解释为 "
- 以 - 打头的 token 是命令行开关; 因此文件名如果类似 -coff, 编译时要写成类似 ml ./-coff

masm 命令行开关有 5 种作用范围, 有些开关自己就具有 2 种范围

范围 | 开关 | masm 版本 | 解释
-|-|-|-
1 following token       | -unrecognized switch | ml 6, 14; ml64 14
all following tokens    | -link     | ml 6, 14; ml64 14
1 following file        | -Fo       | ml 6, 14; ml64 14
all following files     | -coff     | ml 6, 14; ml64 14 | ml 14 default
|                       | -D        | ml 6, 14; ml64 14
|                       | -EP       | ml 6, ?           | 比 -Zs 做的事更少, 不生成 obj
|                       | -omf      | ml 14             | ml 6 imply. prevents link like -c
|                       | -Zi       | ml 6, ?
|                       | -Zs       | ml 6, 14; ml64 14 | absorbs -c, 不生成 obj
all  or 1 following files | -nologo | ml 6, 14; ml64 14 | or before first file. 不确定, 因为 ml 的 logo 只显示 1 次
all and 1 following files | -Fl     | ml 6, ?           | 其后所有文件都生成 .lst 文件, 指定的路径只对其后 1 个文件有效
all files               | -AT       | ml 6
|                       | -c        | ml 6, 14; ml64 14
|                       | -Fe       | ml 6, 14; ml64 14

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

写在源代码里的命令行选项

https://www.keycdn.com/support/http-equiv HTTP response header equivalent, http-equiv = treat this meta as if it were in http response header

source | command line | command line | command line
-|-|-|-
includelib graphics | ml draw.asm graphics.lib | ml draw.asm /link graphics | ml /c draw.asm<br>link draw,,,graphics

### 单个命令行选项

```
ml /?
ml -?

-EP Output preprocessed listing to stdout
-Zs Perform syntax check only
-c  Assemble without linking

todo
-Fl
https://stackoverflow.com/questions/29488745/masm-assembly-listing-file-interpretation
masm 6.1 programmer's guide Appendix C Generating and Reading Assembly Listings


link /?
```

### 编译错误

masm611/errmsg.txt 解释了部分编译错误.

#### error A2076: jump destination must specify a label

A direct jump's destination must be relative to a code label.  masm 不编译 jmp immediate, 只编译 jmp label, 但编译结果还是 jmp immediate.

```
; ml -Foout\ dd.msm -Feout\
; debug out\dd.exe
; u 0 l37
; q

cs1 segment
    assume ds: cs1
s:
    mov cx, cs
    mov ds, cx

    jmp word ptr ds:0   ; m16       jmp [0000] ; in masm ds:0 = ds:[0]
    jmp dw2             ; m16       jmp [0037] ; dw2 is variable so no cast and [] needed

    mov bx, dw2         ; m16       mov bx, [0037]
    jmp bx              ; r16       same as jmp dw2

    mov bx, offset dw2
    jmp word ptr [bx]   ; m16       same as jmp dw2

    jmp dword ptr ds:0  ; m16:16    jmp far [0000]
    jmp dd3             ; m16:16    jmp far [0039] ; variable dd3 doesn't need cast and []

    ; masm doesn't allow jmp immediate, must use labels instead

    jmp     cs1label1   ; rel16     jmp 0037
    jmp cs1:cs1label1   ; rel16     jmp 0037
    jmp cs2:cs1label1   ; ptr16:16  jmp 1000:0037 ; i don't know how to explain this
    jmp  es:cs1label1   ; ptr16:16  jmp 1000:0037

;   jmp cs1:cs2label4   ; error A2074: cannot access label through segment registers
    jmp cs2:cs2label4   ; ptr16:16  jmp 1004:0000
    jmp  ss:cs2label4   ; ptr16:16  jmp 1004:0000

cs1label1:
dw2 dw 1
dd3 dd 2
cs1 ends
cs2 segment
cs2label4:
cs2 ends
; LINK : warning L4021: no stack segment
    end s
```

#### fatal error LNK1190: 找到无效的链接地址信息，请键入 0x0001

> http://masm32.com/board/index.php?topic=3114.0 wjr April 15, 2014, 07:06:37 AM<br>
If you use PEview to look into the OBJ file, and Type 0x0001 is referring to IMAGE_REL_I386_DIR16 (usually
should be 0x0006 IMAGE_REL_I386_DIR32), then you should be able to see at least one of these in the
IMAGE_RELOCATION records. The symbol name and RVA are also displayed which should help narrow things down.

## masm 语法

masm 的关键字分两种
- cpu 厂商规定的指令助记符
- masm 规定的指示, 符号, 操作符

### 宏

see /macros.md

% - expansion

- 按当前的基数对常量表达式求值, 把得到的数字转为字符串
- 作为一行的首个非空白字符时, 展开该行的文本宏和宏函数; 用于 echo, title, subtitle, .erre 等把参数一律视为文本的指示. 一律 - 包括 %, 常量表达式 - 视为文本, 就没法在它们的参数里调用宏或对表达式求值; 但又有这种需求, 于是 masm 说, 既然宏展开符号 % 放 (比如 echo) 后面没戏, 那就放前面吧; 常量表达式的话你们就在外面赋值给文本宏, 别在里面求值了.masm 居然没有选择添加或规定转义字符, 真乃一大幸事.

masm 有个以 % 打头的指示, %out; 后来加了个 echo 取代其功能. %out 是个 4 字符的 token, % 是名字的一部分. %out 作为名字已经够搞笑了, 更搞笑的是它用 % 打头却没有 % 打头语句的作用, %out 完全等于 echo; 要展开 echo 后面的宏需要写 %echo, 或者 %%out; 或者清晰一些, % echo 和 % %out.

### 完全段

在 8086 上必须用段寄存器 + 通用寄存器表示地址, 意味着如果程序 > 64k 就一定有调整段寄存器的操作. masm 把程序设计为好几个不大于 64k 的块, 称作段或逻辑段. 段名保存段地址, 程序运行时可以给段寄存器设置不同的段地址以访问所有段里的内容. 具体实现却混乱繁琐, 文档也含糊不清. masm 段的一个功能是设置 3 个段寄存器中的 1 到 2 个: 依赖一堆设定的简化段用 .startup 设置 ss:sp 和 ds; 完全段栈段的地址是 ss:sp. 可能是对自己设计的段相当满意, masm 要求代码必须写段. 文档 Chapter 2 Organizing Segments 提到了定义段的 2 种方式, 简化段和完全段, 可以混用. 文档 = masm 6.1 programmer's guide. 下面介绍这两种写法, 它俩包含的大多特性都不常用.

```
name SEGMENT [[align]] [[READONLY]] [[combine]] [[use]] [['class']]
statements
name ENDS

段可以嵌套; SEGMENT 后面是 type, 顺序任意; 同名段可以在一个文件内多次出现, 除类名外都不能变, 会合成一个
```

type | value | explanation
-|-|-
align || 此对齐把源代码的而不是程序在内存中的起始位置看作 0, 所以第 1 个段符合任意对齐
|| BYTE, WORD, DWORD | 1, 2, 4 bytes
|| PARA | default. para = paragraph, 1 paragraph = 16 bytes
|| PAGE | 256 bytes. 程序加载后第一句话肯定不是 0 所以在内存中 page 往往不对齐到 256 边界
readonly | readonly | 静态检查, 写入该段引发编译错误
combine || 是否和其他文件的同名段组合. 文件内的同名段一定组合
|| PRIVATE          | default. 不组合
|| PUBLIC, MEMORY   | 组合
|| STACK            | 组合为栈
|| COMMON           | 叠放, 大小 = 参与组合中最大的大小
|| AT address       | 段内只能放类型定义, 不能放数据, 用于按结构访问已知的内存; 保护模式不能用
use | USE16, USE32, FLAT | 386+
'class' || link 把类名相同的段按看到的顺序放一起

combine 作用于多个文件里的段, 文档说同名不同类名的段不组合, 指的应该是不同文件里的段

> Setting Segment Order with Class Type<br>Two segments with the same name are not combined if their class is different.

实验发现 3 种排列方式, 实验并不全面, 但估计涵盖了所有排列方式:

- "收集", 名字是我起的, masm 没提到这种行为. 同一个文件里的同名段要么收集为 1 个段, 要么编译错误. 每次都收集相邻的两个同名段, 最终段的类型是
    - align = 首先遇到的 align, 此后的同名段不能指定不同的 align, 都不指定时使用默认值, 同名段之间没有 align
    - readonly, 未实验
    - combine 很乱无法理解, 比如前面的段有 align 没有 at, 后面的段没有 align 有 at, 就报 A2015: 后面段的 alignment can not change
    - use, 未实验
    - class = 收集前的 2 个段第 2 个段的 class
- 挨着放. 单个文件里 name 不同 class 相同的段挨着放, 挨着放的两个段之间有 align, 不知和组合有啥区别
- combine, 组合. 这里写组合是因为文档这么称呼, 我没看出和挨着放的区别是啥. 设 file1 (cs1, cs2), file2 (cs1)
    - 两个 cs1 都是 public, class 相同. 组合, 段之间有 align, 2 个文件 cs1 的值一样, 第 1 句话的偏移不一样
    - 不都是 public 不组合. 不组合时 2 个文件 cs1 的值不一样, 第一句偏移都是 0
    - class 不同不组合
    - 记得有种情况 file2 cs1 第 1 句的偏移是 aligns + len(cs2), 是记错了吗?

directive | obj 里段的顺序 - 摘抄, 我不知道用法
-|-
.SEQ    | default. 按源文件中声明的顺序
.ALPHA  | 按字母序, 用于兼容老的 ibm 汇编器; 如果运行老的汇编书里的代码有问题, 使用这个
.DOSSEG | code segments<br>data segments not in class BSS or STACK<br>data segments class BSS<br>data segments class STACK

收集, 挨着放, 类, 组合, 这些放置规则已经够乱了, masm 又规定了一种: group. 文档 Defining Segment Groups 说

- `name GROUP segment [[, segment]]...`
- group 语句可以追加段, 所以无需用 1 个 group 语句包含组里的所有段
- 段可以定义在 group 语句之后
- 一个段只能在一个组里
- 组不能同时包含 16 位和 32 位段

稍作实验发现 group 里的段会由于 align 产生间隔. group 和 class 有啥不同? 我能想到的有

- group 定义了个名字, 可以视为 1 个段; class 是挨着放的多个段, 虽不定义名字但显然能用 class 里第一个段的名字
- group 不能大于 64k, class 无此限制是因为 class 没有把段组合
- group 有没有 align 类型? 有的话, 可能就是组里第一个段的 align

at 示例

```
; ml -Foout\ dd.msm -Feout\ -AT

xxx segment
s:
    call at0:lab ; call 0:0
    jmp   es:lab ; jmp  0:0
xxx ends
at0 segment at 0
lab:
at0 ends
end s
```

https://stackoverflow.com/questions/45124341/effects-of-the-flat-operand-to-the-segment-directive

### 简化段, memory model, dgroup, assume

- .model: `.MODEL memorymodel [[, modeloptions ]]`, 其余简化段指示依赖此指示<br>
    定义组 dgroup, 一部分没有指定组的简化段会放到 dgroup 组
- .startup: 添加 @Startup:, 生成语句把 ds, ss 设置为 dgroup 的段地址; 把 end 替换为 end @Startup
- .exit n: mov al, n int21h/ah4ch
- .code, .const, .data, .data?, .fardata, .fardata?, .stack: .stack 不关闭前面的简化段. 会生成诸如 fn_text (far code) or _text (near code) segment word, fn = @filename, 是 8.3 文件名的左边 8 个字符; const segment word; _data segment word; _bss segment word; far_data segment para; far_bss segment para; 和一些 assume 语句. 详细定义在文档 Appendix E Default Segment Names, 依然是残缺不全的信息
- 预定义符号 @curseg 保存当前的段名, `% echo @curseg` 打印段名, `@CurSeg ends` 关闭当前段

.model 的 memorymodel 定义了几种安排段的方式, masm 根据 memory model 修改简化段生成的代码, 以控制段的组合, 给段寄存器设置相应的值. wikipedia 把它称为 intel memory model.

memorymodel | @model | @codesize | @datasize | more nonsenses
-|-|-|-|-
tiny    | 1 | 0 | 0 | com 文件; 1 segment
small   | 2 | 0 | 0 | "supports 1 code segment, 1 data segment"
medium  | 3 | 1 | 0 | "supports n code segment, 1 data segment"
compact | 4 | 0 | 1 | "supports 1 code segment, n data segment"
large   | 5 | 1 | 1 | "supports n code segment, n data segment"
huge    | 6 | 1 | 2 | "essentially the same as large"
flat    | 7 | 0 | 0 | 不是 mz, 32 位保护模式 win nt exe, 32 位地址, 不用段寄存器

- all defaults can be overridden
- huge implies that individual data items are larger than a single segment, but the implementation of huge data items must be coded by the programmer
- const, _bss, far_data, far_bss 总是产生段, tiny 下这些段放在那个唯一的段里
- 什么叫 supports 1 code segment, 1 data segment? 应该指多个源文件时生成的段, 大致像这里讲的, 文档 Far Code Segments
    > In the larger memory models, the assembler creates a different code segment for each module. If you use multiple code segments in the small, compact, or tiny model, the linker combines the .CODE segments for all modules into one segment.

    文档这部分充斥着错误, 随便做个实验都能得出不同结论. 比如文档说 large model .code first 生成 first_text, 实际生成 first; 说 large model 每个代码段是单独的段, 实际只有用 .startup 才导致两个段, 等等. 完全看不下去

modeloptions | value | explanation
-|-|-
language || @interface<br>sets calling and naming conventions for procedures and public symbols<br>proc, invoke, public, extern use naming convention<br>no language type in .model, option, extern, proc, invoke, proto causes error
|| basic, fortran, pascal
|| c, syscall   | same calling convention, different naming convention
|| stdcall      | used by windows api
stack distance || @stack
|| nearstack    | default. stack and data in 1 physical segment (dgroup)<br>.startup sets ss = ds; if not use .startup you must set it
|| farstack     | used by tsr, dll<br>stack does not grouped with dgroup, thus ss != ds

.startup 和 .exit

```
- do not use them in flat
- .startup causes end to ingore it's arg. 指示可以修改任意代码, 不像宏仅限于自己那一块

.startup
    ; nearstack, .8086/.186     ; nearstack, .286+              ; farstack
    @Startup:                   @Startup:                       @Startup:
        mov dx, DGROUP              mov dx, DGROUP                  mov dx, DGROUP
        mov ds, dx                  mov ds, dx                      mov ds, dx
        mov bx, ss                  mov bx, ss
        sub bx, dx                  sub bx, dx
        shl bx, 1                   shl bx, 4
        shl bx, 1
        shl bx, 1
        shl bx, 1               ; 286+ 的 mov ss, pop ss
        cli                     ; 导致下一条指令忽略中断
        mov ss, dx                  mov ss, dx
        add sp, bx                  add sp, bx
        sti
        ; ...                   ; ...                           ; ...
    END @Startup                END @Startup                    END @Startup

.exit value             .exit
    mov al, value
    mov ah, 4Ch             mov ah, 4Ch
    int 21h                 int 21h
```

assume 示例

```
; ml -Foout\ dd.msm -Feout\ -AT

xxx     segment
        assume  ds: xxx
; 1. 没有 assume 时 masm 在 mov 的前面加 cs:, 机器码 2e; com 有 cs = ds = es = ss, 2e 是多余的前缀
; 2. 如果使用简化段 .code 则无需 assume ds: xxx, 因为 .code 会生成 assume 语句
; 3. i 是 db, masm 要求 word ptr; 而 mov ax 明确要求 word, 所以指令不需要 word ptr, masm 生成的指令里也没有
; 4. com 文件没写 org, 就需要自己给标签 +0x100 的偏移
s:      mov     ax, word ptr i + 100h
        mov     ah, 4ch
        int     21h
i       db      ?
xxx     ends
        end     s
```

### ptr, coercion

masm 关键字 ptr 是 pointer 的缩写, 有两种意义, 一种在 masm 外也常见, 这里说这种; 另一种是 masm 发明的, 在 "变量" 里说.

```
debug
-a
1337:0100 mov           [200] , byte        3
1337:0105 mov           [103] , word ptr    3
1337:010B mov word      [200] ,             3
1337:0111 mov           [200] , dword ptr   3
1337:0116 mov           [200] , qword       3
1337:011C mov tbyte ptr [200] ,             3
1337:0121
-u
1337:0100 C606000203    MOV     BYTE PTR [0200],03
1337:0105 C70603010300  MOV     WORD PTR [0103],0003
1337:010B C70600020300  MOV     WORD PTR [0200],0003
1337:0111 C606000203    MOV     BYTE PTR [0200],03
1337:0116 C70600020300  MOV     WORD PTR [0200],0003
1337:011C C606000203    MOV     BYTE PTR [0200],03
-q
```

- size ptr 可以写在任意操作数前面, 最终总是放在内存前
- debug 不认识 dword, qword, tbyte, 并且 16 位模式也不支持 mov 这种长度

这种 ptr, x86 指令集里没有, 各种反汇编里经常见, 用 debug 写汇编时可以省略, debug 的反汇编也使用它.

谁发明的? 网上没找到答案.

干嘛使? `mov size memory, immediate` 解决这个问题: 汇编器看到 `mov memory, immediate` 时不知道 memory 指出的是 byte, word 或其他, 也就不知道该汇编成哪个 opcode, 所以需要额外的词 - size - 去说明: `mov word ptr [bx], 5`, debug 里可写为 `mov word [] bx, 5` 或 `mov [] word bx, 5`. mov byte, move word 是不同的指令. 能从操作数确定长度比如 mov bx, 3 时无需说明长度, 汇编器会生成正确的 opcode, 无法确定时才需要说明.

要点是 size ptr 或 size 用来限定地址指向的内存的长度. size ptr memory 或 size memory 把 memory 限定为 m8/16/32/64. intel 把 offset 叫 memory, 把 segment:offset 叫 far pointer; 但有些人把 offset 也叫 pointer, 所以 memory 或 m8/16/32/64 也叫 pointer, ptr 用来限定 memory 的长度, 也可以叫 pointer.

http://www.phatcode.net/res/223/files/html/Chapter_8/CH08-4.html 看完网页后想看看是啥书, 一看是 Randall Hyde 的 the art of assembly language programming. 记得以前照该书写过一些练习代码, 现在找不到了. Randall Hyde 把限定长度的操作叫 coercion. 后来有一天看到 https://stackoverflow.com/questions/8857763/what-is-the-difference-between-casting-and-coercing, accepted answer 说 word ptr 这样的操作叫 conversion 或 cast, 就是不叫 coercion, coercion 是 implicit conversion. 再看其他答案是各有说法. 看来 coercion 在不同人那里有不同定义.

### 标签

写代码时经常需要 jump 到某条语句. 假设跳到第 42 句, 这位置 42 很可能在写代码时多次变动, 就要不断修改代码里的 42; 42 是 1 个位置, 代码里往往用到多个位置, 每个位置都需要此过程. 这纯粹是不必要的麻烦, 程序员希望用占位符表示位置, 由程序做符号到位置的转换工作. 最好是 cpu 能理解符号以完成转换, 但 intel cpu 不理解, 那就只能靠编译器. masm 支持汇编里已有的标签概念, 可以用符号标记位置, 编译时用符号处的位置替换符号以组成 cpu 指令.

写代码时还经常需要保留一些内存位置往里面放计算结果. intel 没有这种语法, 只能用指令占据内存位置, 并安排代码不执行这块占据的内存; 用指令占据的内存值只能是指令, 即没办法初始化以这种方式保留的内存. masm 的 data allocation 语法 `type initializer [, initializer]...` 用 db, dw, dd 等保留一些可以初始化的内存. 要引用保留的内存可以往它前面放一个标签, masm 规定标签和 data allocation 不能在同一行, 例子

```
someWords:
    word 3 dup (21) ; 用 21 初始化 word, 重复 3 次. 假设 (1, 2, 3), 就是把 1, 2, 3 重复 3 次得到 9 个 word
```

标签和保留内存都是很实用的功能, 不是 masm 的发明但 masm 支持它们, 至此可以说很完美. 但 masm 可能是想在汇编的基础上创造一种静态强类型的语言, 可能还试图兼顾同其它 microsoft 语言的 "互操作性", 即在这个语言里调用那个语言定义的函数, 于是在标签和保留内存的基础上做了大量狗尾续貂的工作, 得到了既难以理解又难以使用的变量和静态类型. 作为发明变量和静态类型之前的热身工作, masm 首先给标签添加了很多限制.

label, compiles to `immediate`, syntax:

- `lb1:`
    - under `option noscoped` (default), lb1 is visible within file (module)
    - under `option scoped`, lb1 is visible inside a proc block, can not be public; visible within file elsewhere
- `lb2::` lb2 can be declared public; visible within file

冒号定义的 label 虽有段地址但 masm 说它是 near label, 要使用段外标签得写 `(段寄存器 or 段名):标签名`; 段寄存器的名字和值都不重要, masm 知道标签的地址, 不会读取段寄存器; 段名要匹配; masm 要看到这种写法才会生成 jmp ptr16:16. 有段地址的 near label 用起来很方便, 但专用于过程的标签 proc 却很不方便. 判断一个过程是远还是近被 intel 和 masm 做成了垃圾

- 最省事的做法是匹配的 call 和 ret. 这就不需要知道距离了, 但 intel 的 call 和 ret 做不到, 自定义代码效率低, 可以做到
- 其次可以根据调用方的位置确定 call 和 ret. masm 没这么做, 可能是怕调用处的代码导致修改返回语句, 而 masm 不知如何解决
- 其次可以根据 retn 和 retf 决定过程的距离. masm 也没这么做, 可能是想逼人使用自己发明的各种声明
- masm 做成了: 在定义里自述. 既不能根据调用方的位置调整远近, 也保证不了 far 和 retf, near 和 retn 的对应关系

于是造成很多无用的场景

- 近调用 段内 近过程? ok
- 近调用 段内 远过程? 实现不了, masm 总是对远过程生成远调用
- 远调用 段内 近过程? masm 把 `call cs:pn` 编译为 `push cs; call rel16`, 把 `call ds/es/ss:pn` 编译为 `call ptr16:16`
- 远调用 段内 远过程? ok
- 近调用 段外 近过程? 近调用不修改 cs, 无法调用段外过程
- 近调用 段外 远过程? 同上
- 远调用 段外 近过程? 近过程使用 retn, 返回时不修改 cs 所以会返回到错误的地址
- 远调用 段外 远过程? ok

```
; ml -Foout\ dd.msm -Feout\

cs1 segment
s:
    ; error A2107: cannot have implicit far jump or call to near label
    ; the error is reasonable because a near proc is likely using near return
    ; call cs2label
    ; call cs2proc

    call cs2pf ; ok, call a far proc

    ; any segment override is ok, masm don't even read the segment register
    call ds:cs2label
    call ss:cs2proc

    ; segment name must match
    call cs2:cs2proc

    ; the program will not get to here because of far call to near label, so no int33/ah4ch needed
cs1 ends
cs2 segment

cs2label:
    retn

cs2proc proc
    retn
cs2proc endp

cs2pf   proc far
    retf
cs2pf   endp

cs2 ends
ss1 segment stack
    dw 16 dup (3333h)
ss1 ends
    end s
```

### relocation

标签代表的位置编译时就确定了, 代码假设了运行时的地址, 非常死板. 编译得到的可执行文件只能加载到固定地址, 如果希望的内存位置已经存放了别的东西就无法加载. 解决办法有 2 个部分

- 段. 编译时不固定段地址, 在文件头里保存段的信息, 加载器填充这些信息所以程序运行时能知道实际的段地址
    - masm 的 com 不能用段名, 可能是因为 com 没有文件头没法保存段名
- 偏移.
    - com 运行时偏移是 256, 针对的解决办法是 org 100h, 只能对付写代码时就知道运行偏移是 256 的情况. 不是解决办法
    - intel 的相对偏移 rel16/32/64 是个好思路, 但只能是 immediate, 把标签的值保存在比如寄存器里就不再是 rel 了. 不是解决办法
    - 解决办法是 position independent code, https://stackoverflow.com/questions/599968/reading-program-counter-directly
        ```
            call _here
        _here:
            pop eax ; eax now holds the PC.
        ```
        on newer cpus call rel32 (0) 不影响 return-address predictor stack, http://blog.stuffedcow.net/2018/04/ras-microbenchmarks/#call0

### 变量, 静态类型

标签是代表地址的符号, 编译时替换成 offset, offset 是数字而不是名字, 要使用 offset 处的值而不是 offset 就得用方括号标记标签, masm 不支持这种写法. 如果把标签替换成 [offset], 那从代码的角度看标签就是变量了. masm 就这样定义了变量, 并趁机把变量叫 data label, 标签改叫 code label. masm 确保 code label 编译为没有方括号的 offset, data label 编译为方括号括起来的 offset. 因此 masm 标签永远不需要方括号, 这就是前面说 masm 不支持 [代码标签] 这种写法的原因. `seg lb` 和 `offset lb` 用于获取数据标签的地址.

data label, a.k.a. variable, compiles to `[immediate]`, syntax:

- `[name] type initializer [, initializer]...`
- `name label qualifiedtype`

首先注意到两个意料之外的东西: `label` 和 `qualifiedtype`, 待会儿再说, 先说第 1 种定义方法. 假设有 `i byte ?`, masm 说变量 i 具有类型 byte, 结果是

- `mov ds:200, byte ptr 3`, 200 换成 i 后可以写 `mov i, 3` 或 `mov i, byte ptr 3`
- `mov ds:200, word ptr 3`, 200 换成 i 后必须把 cast 放 i 前面, 不能写 `mov i, word ptr 3`
- `mov ax, ds:200` 毫无歧义, 但 200 换成 i 后要写 `mov ax, word ptr i`

定义变量时使用了 type, 使用变量时 masm 查看代码是否写了 cast, 写的话就保留, 不写的话加上 type ptr, 得到 type ptr [offset], 可以看到 masm 记录了变量的长度和偏移. 它的目的不是长度匹配时省一个 `长度 ptr`, 而是长度不匹配时产生编译错误. 这纯粹是制造困难, 但该困难顶了个迷惑性的名字让人捉摸不透, 不敢妄下定论: 静态类型. 拥护静态类型的人很多.

既然数据标签 name 表示符号形式的地址 name 指向的值, 那么 [name] 就表示 name 指向的值指向的值, 即先取 name 处的值作地址, 再取该地址处的值; 和寄存器用法一致. 但在 masm 中 [name] 和 name 一模一样都是 [offset], 可能是因为 masm 考虑了 intel 的 "一句话只有一次内存访问", 没办法在一句话里先取 name 处内存的值, 再取该值处内存的值, 所以 name = [name] = [[[[name]]]], [ax] = [[[[[[[[[[[ax]]]]]]]]]]]; 而 ax 是寄存器地址, 不读内存, [ax] 先读寄存器再读内存, 所以 ax != [ax]. 这给程序员带来极大困扰, 无论能否意识, 它都会在每次遇到时实实在在消耗一部分脑力:

- 有时需要方括号有时不需要; 带方括号时可能没用上, 没带时可能用上了
- 一个强调静态类型, 动不动编译错误的语言, 在方括号上这么随意?

masm 随意修改方括号的行为还染指了立即数, 把 `mov [200], word ptr 3` 解释为 `mov 200, word ptr 3`, 然后报告 error A2001: immediate operand not allowed. 为纠正这 masm 造成的错误, 必须把 [200] 写为 ds:[200] 或 ds:200, 例如 `mov ds:200, word ptr 3`.

第 2 种定义数据标签的方法是 `label`, 需要先了解 qualified type.

microsoft code view 4.01 help/contents/assembly/directives/typedef/qualified type

```
name typedef qualifiedtype
name typedef proto prototypelist
```

- qualified type: structures, unions, records, any intrinsic type, [distance] ptr [qualifiedtype], types defined by typedef<br>
- distance: optional. defaults to data pointer or code pointer of current memory model, .model defaults to small, small is near ptr

use | example
-|-
in procedure arguments                          | proc1 proc pMsg: ptr byte
in prototype arguments                          | proc2 proto pMsg: far ptr word
with local variables declared inside procedures | local pMsg: ptr
with the label directive                        | tempMsg label word
with the extern and externdef directives        | extern pMsg: far ptr ptr byte
with the typedef directive                      | ppbyte typedef ptr pbyte
with the assume directive (added by me)         | assume bp: ptr some-struct-instance

看例子恨不得每个都是 ptr 就能猜到创造 qualified type 就是为了塞进 ptr, 但这个对 masm 如此重要的 ptr 却不能放在正常的数据定义语法里定义数据, 只能通过 typedef 定义某个 ptr type, 然后使用这个特定 type 的 ptr. 那么多 masm 发明的犄角旮旯里都能用 ptr, 只有那唯一常用的语法里不能... 不过, 我完全不想了解这种设计的原因.

http://www.phatcode.net/res/223/files/html/Chapter_5/CH05-1.html#HEADING1-197 说 `typename typedef near ptr basetype` 或 `typename typedef far ptr basetype`, basetype 可以省略, 仅供 cv.exe 使用, 按 basetype 显示 typename 变量指向的值. 这说法和文档以及 cv help/contents/assembly/operators/miscellaneous/ptr 一致, 但我调整了 cv 的 source1 窗口设置后仍找不到哪里能看这个按 basetype 显示的值.

> 文档 Chapter 3 Using Addresses and Pointers<br>
A pointer is a variable that contains an address as its value.

masm 说 xxx typedef ptr 定义的新类型 xxx 是 ptr void; masm 用 void 或 ptr void 表示自己可以和其它 microsoft 语言交互; 纯粹的累赘概念, 看看就行. intel 说 m16 指向 word, m16:16 指向 ptr16:16 而不仅仅是 dword, 这种不对称的定义也造成了混乱. masm 不根据 ptr 类型产生编译错误, 所以任何地方都不需要 ptr; word 和 dword 分别对应 near 和 far ptr 就行, 这一点 masm 做得对.

intel m16 | masm near ptr | \| | intel m16:16 | masm far ptr
-|-|-|-|-
[imm16] | np (typeof np = near ptr)         | \| | [imm16] | fp  (typeof fp = far ptr)
-| np (typeof np = near ptr byte/word/...)  | \| | -       | fp  (typeof fp = far ptr byte/word/...)
[reg] | - | \| | [reg] | -

`npt typedef near ptr byte; t1 npt 1111h`, 设 t1 的地址是 ds:10, 有

- 变量 t1 = 偏移 10; 10 在 16 位模式里是 imm16 和 m16
- masm 认为 0x1111 是 near ptr, 即 offset; offset 是 word 所以 t1 编译为 word ptr [10]; intel 认为 m16 指向的 0x1111 是 word
- masm 认为 0x1111 指向 byte, intel 没有这想法

`fpt typedef far ptr byte; t2 fpt 5555bbbbh`, 设 t2 的地址是 ds:20, 有

- 变量 t2 = 偏移 20; 20 在 16 位模式里是 imm16 和 m16:16
- masm 认为 0x5555bbbb 是 far ptr; far ptr 是 dword 所以 t2 编译为 dword ptr [20]; intel 认为 m16:16 指向 far pointer
- masm 认为 0x5555bbbb 指向 byte, intel 没有这想法
- far ptr 提示 masm 生成 far jump 之类的指令

```
npt1 typedef near ptr word
npt2 typedef ptr word
npt3 typedef ptr

fpt4 typedef far ptr word
fpt5 typedef far ptr

xxx segment
org 100h
s:  jmp ds:p5 ; explicit ds: to suppress cs:

p1 npt1 1111h
p2 npt2 2222h
p3 npt3 3333h

p4 fpt4 4444aaaah
p5 fpt5 5555bbbbh
xxx ends
end s

ml -Foout\ dd.msm -Feout\ -AT

debug out\dd.com
-d 100 l20
1337:0100  FF 2E 0E 01 11 11 22 22-33 33 AA AA 44 44 BB BB   ......""33..DD..
1337:0110  55 55 08 B8 04 00 50 0E-E8 65 0A B8 1C 27 50 FF   UU....P..e...'P.
-r
AX=FFFF  BX=0000  CX=0012  DX=0000  SP=FFFE  BP=0000  SI=0000  DI=0000
DS=1337  ES=1337  SS=1337  CS=1337  IP=0100   NV UP EI PL NZ NA PO NC
1337:0100 FF2E0E01      JMP FAR [010E]                         DS:010E=BBBB
-t
AX=FFFF  BX=0000  CX=0012  DX=0000  SP=FFFE  BP=0000  SI=0000  DI=0000
DS=1337  ES=1337  SS=1337  CS=5555  IP=BBBB   NV UP EI PL NZ NA PO NC
5555:BBBB 0000          ADD [BX+SI],AL                         DS:0000=CD
-q
```

了解完 qualified type 后我完全不想再去了解 `label` 指示了, 基本上它能定义远数据标签.

一些零碎知识

- `:macrolabel` 仅用于 `macro`, `for`, `forc`, `repeat`, `while` 块里的 `goto` 指示
- `$` = `this near`, current value of location counter. within structure, m510 = offset of structure; non m510 = offset of current field in structure
- `tag1 equ this byte` = `tag1 label byte`

operators ||
-|-
addr            | only available in `invoke`. offset of a global or local variable
offset          | offset of a global variable
seg expression  | expression = label, variable, group name, memory operand; cannot be a constant
imagerel    | available only with COFF object emission
sectionrel  | available only with COFF object emission
lroffset    | Same as offset, but it generates a loader resolved offset, which allows Windows to relocate code segments
todo        | elaborate imagerel, sectionrel, lroffset

### length, size, type

- length(of) variable; size(of) variable or type
- variable = single element array
- size of type: byte = 1, word = 2...

masm expression     | value https://stackoverflow.com/questions/26864213/get-structure-size-within-masm
-|-
lengthof    array   | number of elements in array
sizeof      array   | (lengthof array) * size of type
length      array   | **legacy**, **limited** value of the dup operator in first initializer, 1 if first initializer doesn't use dup
size        array   | **legacy**, **limited** (length array) * size of type

```
xxx segment
ar1 word 5 dup (?), 6,
7
ar2 word 1, 2, 3 dup (?)

lo1 textequ % lengthof  ar1
so1 textequ % sizeof    ar1
l1  textequ % length    ar1
s1  textequ % size      ar1

lo2 textequ % lengthof  ar2
so2 textequ % sizeof    ar2
l2  textequ % length    ar2
s2  textequ % size      ar2

echo .    lengthof     sizeof    length       size
% echo ar1         lo1         so1         l1         s1
% echo ar2         lo2         so2         l2          s2
xxx ends
end

ml -Zs dd.msm

.    lengthof     sizeof    length       size
ar1         7         14         5         10
ar2         5         10         1          2
```

masm expression | masm 5.1 | masm 6
-|-|-
length  recordName      | bits in a record definition | error A2143
sizeof  recordName      | (don't know) | bits in a record definition
length  near-code-label | 1 | 1
length  far-code-label  | 1 | 1
length  string          | 1 | 1
size    string          | 1 | 1
lengthof code-label     | (don't know) | error A2143: expected data label

code label  | m510 near | m510 far  | short  | near16 | near32 | far16  | far32
-|-|-|-|-|-|-|-
size        | 0xffff    | 0xfffe    | 0xff01 | 0xff02 | 0xff04 | 0xff05 | 0xff06

```
cs1 segment

cl1:
s3  db "abcdeoru"

cs1 ends
cs2 segment

cl2:
.radix 16
ln1 textequ % length   cl1
ln2 textequ % length   cl2
ln3 textequ % length   s3
sz1 textequ % size     cl1
sz2 textequ % size     cl2
sz3 textequ % size     s3

lb4 label   far
pf5 proc    far
pf5 endp

sz4 textequ % size lb4
sz5 textequ % size pf5

% echo ln1 ln2 ln3 sz1 sz2 sz3 sz4 sz5

cs2 ends
ss1 segment stack
    db 32 dup (?)
ss1 ends
end

ml -Zs dd.msm

1 1 1 FF02 FF02 1 FF05 FF05
```

cv help 说 type 返回的 attribute 能修饰一些类型如 ptr, 不知道该咋写

```
xxx segment

v01 fword 1

st2 struct
    word d1
    byte d3
st2 ends

abc:

.radix 16
ty1 textequ % type v01
ty2 textequ % type st2
ty3 textequ % type 3
ty4 textequ % type abc
ty5 textequ % type cx

% echo ty1, ty2, ty3, ty4, ty5
xxx ends
end

ml -Zs dd.msm

6, 3, 0, FF02, 2
```

### public, extern, externdef, proto, comm

我不喜欢静态类型, 认为它主要的作用是拼写检查, 带来的麻烦远多于益处. 这其中类型, 类型匹配, 静态语法检查还算好, 声明则是纯粹的垃圾

- declaration, 声明: 几乎是重复在定义处写过的文字, 程序员必须保持两者一致, 是无妄之灾
- 头文件: 声明的集合, 偶尔也包含些其他东西. 头文件的效果是用头文件的内容替换引用头文件的语句, 是个有用的技术, 但用于放置声明时就是垃圾

定义符号的文件里写 `public 符号`, 表示该符号可以在其他文件里使用; 使用符号的文件里写 `extern 符号:类型`, 表示该符号一部分 (类型部分) 在本文件里定义以帮助编译器生成指令, 另一部分在将其声明为 public 的文件里定义.

```
file1               file2                   file 3, ...
public symbol       extern symbol:type      extern symbol:type
define symbol       use symbol              use symbol
```

- `public [langtype] name [, ...]`
- `extern|extrn [langtype] name[(altID)]:abs|qualifiedtype [, ...]`, abs (absolute) = external numeric constants<br>
masm 5.1 必须把 extrn 放在定义所在的段里, 如果定义在其他文件就必须在使用的文件里定义相同的段以放置 extrn, 这导致组合两个文件里的相同段; masm 6.1 无此限制. abs 把 identifier 导入为 relocatable unsized constant, 没有定义时导致 link error
- `externdef [langtype] name:qualifiedtype [, ...]`<br>
externdef 在定义符号的文件里视作 public, 使用符号的文件里视作 extern, 既不定义又不使用的文件里视作废话. 目的是使用同样的语句, 以便把这语句放到头文件里
- `label proto [distance] [langtype] [, [parameter]:tag]...`, tag = qualified type or vararg<br>
proto 是专用于 proc 的 externdef, 1 次只能声明 1 个. proc 默认 public, 如果定义为 private 则 proto 不把过程名声明为 public. proto 的用意是给 proc 名字绑定距离, 类型, 参数供 masm 给 invoke 做语法检查
- `comm [langtype] [near|far] label:type[:count] [, ...]`<br>
tiny, small, compact, flat defaults to near; medium, large, huge defaults to far. must specify near or far if no .model memory-model.<br>
comm declares a data variable external and instructs the linker to allocate the variable if it has not been explicitly defined in a module. The memory space for communal variables may not be assigned until load time, so using communal variables may reduce the size of your executable file. allocated by the linker, cannot be initialized, primarily for compatibility with communal variables in Microsoft C, not used in any other Microsoft language, not compatible with C++ and some other languages.

调用段外标签的写法根据标签是否定义在本文件里而不同. 定义在本文件里时, 没有把标签声明为 far 的语法, 这么写

```
cs1 segment
s:
    call cs2:proc2
    call  ds:proc2
cs1 ends
cs2 segment
proc2:
    retf
cs2 ends
; LINK : warning L4021: no stack segment
end s
```

masm 不允许声明段名, error A2014: cannot define as public or external : cs2. 要调用的标签定义在其他文件里时必须声明为 far, 使用 far 标签不需要写段寄存器, 这么写

```
; ml -Foout\ dd.msm -Foout\ da.msm -Feout\

; dd.msm

extern proc2 : far

cs1 segment
s:
    ; extern proc2 : near   - error L2002: fixup overflow at 1 in segment CS1
    ; extern proc2 : far    - ok
    call proc2

    ; error A2006: undefined symbol : cs2
    ; call cs2:proc2

    ; extern proc2 : near   - error A2074: cannot access label through segment registers
    ; extern proc2 : far    - ok, same as call proc2
    call es:proc2
cs1 ends

; 如果为了使用 cs2 而在这里写个空定义, 则 call cs2:proc2 = call es:proc2
;cs2 segment
;cs2 ends

; LINK : warning L4021: no stack segment
end s

; da.msm

public proc2

cs2 segment
proc2:
    retf
cs2 ends
end
```

### ret, retn, retf

intel 助记符是 ret | opcode | meaning
-|-|-
ret imm16   | c2 | near return, pop imm16 bytes
ret         | c3 | near return
ret imm16   | ca | far  return, pop imm16 bytes
ret         | cb | far  return

不知谁发明的 retn 和 retf, debug 和 masm 都认识它们. 这种命名方式和 far 不一样, 按 far 的命名方式 retn 应该叫 ret, retf 应该叫 ret far.

显然代码里写 ret 时编译器无法确定是 near 还是 far, 于是 masm 定了 2 个规矩

1. 修改 ret. `pn proc near` 里, ret = retn (c2 or c3); `pf proc far` 里 ret = retf (ca or cb); proc 外看 memory model.
1. 不修改 retn, retf. 程序员用 retn, retf 明确指出需要 near 或 far return

### compiler hints

前面多次看到为帮助编译器生成正确的 opcode 需要程序员写额外的词, 这里总结见过的词.

- [] 表示其后或其中的内容是 offset
- size ptr 或 size 表示其后的用 [] 修饰的 offset 指向的内存长度是 size; 放在不是 offset 前也不一定报错. 编译器能确定 size 时, 或不是内存时也都可以指定, 编译器忽略匹配的指定, 对不匹配的报错. `mov ax, word 3` 可以, `mov ax, byte 3` 不行
- far 修饰前面的 mnemonic 而不是后面的 operand, 表示选择 jmp, call 的 m16:16/32 版本, `les far ax, [100]`, `les ax, far [100]` 都是语法错误
- assume 其中一个作用是减少 masm 生成的段寄存器重写

## 16 bit dos masm 程序示例

### 从 psp 获取程序的命令行参数

https://en.wikipedia.org/wiki/Program_Segment_Prefix

psp 常用于获取程序的命令行参数, 或者叫 command-line tail. 程序开始执行时 ds = es = seg psp; int21h/ah51h 和 int21h/ah62h 也可以获取 psp, 结果放在 bx.

INT 21,51 - Get Current Process ID (Undocumented DOS 2.x) https://stanislavs.org/helppc/int_21-51.html<br>
INT 21,62 - Get PSP address (DOS 3.x) https://stanislavs.org/helppc/int_21-62.html

```
; 打印命令行参数. 命令尾全是空白字符时长度是 0, 否则长度包含空白
; psp 80h       1 byte      Number of bytes of command-line tail
; psp 81h-FFh   127 bytes   Command-line tail (terminated by a 0Dh)
;
; bug
; 1. 修改了 psp 的一个字节, 改为 $
; 2. 若命令行参数包含 $ 则认为串结束, 以致打印不全

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

ml -Foout\ dd.msm -Feout\ -AT
out\dd     ddd  --x

     ddd  --x

注: 后来看到这帖子
https://stackoverflow.com/questions/25129743/confusing-brackets-in-masm32
masm 根据它的规则修改你的代码
- variable name               无论方括号, 一律认为是变量的值
- constant, const expr, imm   无论方括号, 一律认为是立即数
- register                    不修改方括号的意义
这个编译器会修改你的代码. 我能理解错不全在 masm, 你看它修改的都是他自己规定的玩意儿: 变量, 常量,
常量表达式; 可以说只影响了立即数. 因此要说代码被修改了你自己也有责任, 因为你用它提供的结构了, 我想
很难反驳吧? 根据中国的古老智慧, masm 编译器如何对待 masm 代码是 masm 的内政, 其他语法无权干涉.
```

上面代码为了用 int21h/ah9 打印串, 修改了 psp, 并仍无法正确打印包含 $ 的串. https://stackoverflow.com/questions/481344/dollar-terminated-strings 给出了 3 种办法

- int21h/ah2
- int21h/ah40h, file handle = 1
- int29h, undocumented

masm 的 @@ 定义一个只能通过其上下的 @f (forward, 下一个 @@) 和 @b (back, 上一个 @@) 访问的标签

```
; ml -Foout\ dd.msm -Feout\ -AT

xxx segment
    org 100h    ; 为了让 com 中的标签具有正确偏移, 在这里统一 +0x100
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

execute int 20h from exe by far return https://jeffpar.github.io/kbarchive/kb/072/Q72848/

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
;   注意到初始 sp = 0xfffe, word [0xfffe] = 0, retn 可以使用这两个字节当 ip,
;   若又有 cs = seg psp 则 retn 导致执行 psp 0000 处开始的机器码.
;   不知道这方法是否可靠, 即不知道栈是否总是保留两个字节的 0 - 可靠
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
% echo te

.model tiny
.data
% msg db 'te&$'
.code
s:
; mov dx, offset _data + ???
; mov dx, @data ???
mov dx, offset msg + 100h
mov ah, 9
int 21h
int 20h

endif
end s
```

### mz com ?

MZ = 4d 5a = dec bp pop dx, 很正常的指令. 如果 com 文件以这两条指令开始会有啥后果? 下面程序编译后运行正常. 可是给 msg 加几个字符后就啥都不打印了. 试了一会发现只有 msg 长度小于 11 才会打印. 不明白.

```
; ml -Foout\ dd.msm -Feout\ -AT

xxx segment
    org 100h
s:
    dec bp
    pop dx
    push dx

    mov bx, 1
    mov cx, lengthof msg
    mov dx, offset msg
    mov ah, 40h
    int 33
    retn

msg db 'MZ = 4d 5a'
xxx ends
    end s
```

### bound (80188+), m16&16, int 5

`bound r16, m16&16` 视 m16&16 的第 1 个 word 为 lower boundary, 第 2 个 word 为 upper boundary. 该指令很少用到, 因为

- 处理异常很麻烦, int 5 又已被滥用为 dos 截屏, 服务例程不能准确判断 int 5 发生的原因
- 执行速度还不如两个比较指令加跳转指令. 一般通过把 m16&16 放在数组开头, 让它们都能载入缓存, 来提高 m16&16 的读取速度

Bound Range Exceeded, 5, Fault, #BR. fault 的 return address 是产生 fault 的语句的地址. fault 没有固定处理方式. cpu 的本意是让纠正产生 fault 的语句后重试; 其它常用方式是如果代码提供了异常处理程序则调用它, 否则结束程序. 由于我不知道如何修改产生 fault 的语句, 并且似乎默默地纠正 #br 不算好做法, 所以采用异常处理程序.<br>
https://stackoverflow.com/questions/71070990/x86-division-exception-return-address<br>
https://stackoverflow.com/questions/33029457/what-to-do-in-interrupt-handler-for-divide-by-zero

```
; ml -Foout\ dd.msm -Feout\

.186
.model tiny

.code
    org 100h
s:
    mov ax, 8       ; won't throw
    bound ax, mem

    call setIv5

    int 5 ; return address = next instruction of int 5

    push @f         ; exception handler jumps to @f when done
    push catch      ; exception handler
    mov ax, 3       ; will throw
    bound ax, mem   ; return address = this instruction
    add sp, 4       ; if no exception

@@:
    push @f
    push catch
    mov ax, 8       ; won't throw
    bound ax, mem
    add sp, 4

@@:
    push @f
    push catch
    mov ax, 3       ; will throw
    bound ax, mem
    add sp, 4

@@:
    push @f
    push catch
    mov ax, 3       ; will throw
    bound ax, mem
    add sp, 4

@@:
    call restoreIv5
    int 20h

catch:
    ; stack = catch, @f
    mov bx, 1
    mov cx, lengthof msg
    mov dx, offset msg
    mov ah, 40h
    int 21h
    add sp, 2
    retn

setIv5:
    mov dx, 0
    mov es, dx

    cli ; save interrupt vector #5
    mov dx, es:(5 * 4)
    mov iv5, dx
    mov dx, es:(5 * 4 + 2)
    mov iv5 + 2, dx
    sti

    cli ; set iv #5
    mov es:(5 * 4), isr5
    mov es:[5 * 4 + 2], cs
    sti
    retn

restoreIv5:
    mov dx, iv5
    cli ; relies on es = 0
    mov es:(5 * 4), dx
    mov dx, iv5 + 2
    mov es:(5 * 4 + 2), dx
    sti
    retn

; iret jumps to segment:offset. only offset part of catch was pushed,
; this limits catch clause and bound instruction into same segment
isr5:
    push bp
    mov bp, sp ; stack = former-bp, bound-offset, bound-segment, flags, catch
    push bx

    ; just iret if caused by int 5. in reality calling original isr5 may be needed
    mov bx, [bp + 2]            ; bx = bound-offset or next instruction of int 5
    cmp word ptr [bx - 2], 5cdh ; cd 05 = int 5, len (cd 05) = 2
    je @f

    ; otherwise jump to catch clause
    mov bx, [bp + 8]
    mov [bp + 2], bx

@@:
    pop bx
    pop bp
    iret

iv5 word 0, 0
mem word 5, 10
msg byte 'in catch clause (exception handler), called by isr5', 13, 10
end s
```

我曾认为既然程序只是执行然后退出, 那么要处理异常应该是调用 dos api 注册一个处理函数而不是自己修改中断向量, 这样更容易和其它程序共存. dos 确实有 int21h/ah25h 和 int21h/ah35h 来设置和获取中断向量, 但实现极其简单, 跟自己修改中断向量没啥区别. 后来我的认识是, 既然 dos 里全都是独占程序, 那么执行时就无需和其它程序比如 tsr 配合, 退出时恢复到进入前的状态就行了, tsr 如何和其它程序共存由它自己想办法.

### 打印栈的后 10 字节

应该是调试器修改了栈的后 10 字节. 本节程序运行时, 除了 com 修改的最后 2 字节外栈保持原样; 在调试器里一次执行完, 输出也正常; 单步执行能看到栈被修改了, 并且程序设置栈的后 10 字节也不生效, 看调试器修改栈的规律似乎是把设置的位置改到其他地方了, 后 10 字节保存了那个地方的偏移. 实验表明程序启动时栈有下列规律

```
                com             exe with stack size 0x20
normal          ... 00 00       ... a9 01 ...
in debugger     ... 00 00       ... ff ff ...
                    ^                     ^
sp              0xfffe                  0x20
```

因为要测试 com 和 exe, 就想能不能写一个既能编译为 com 又能编译为 exe 的代码. 这种代码用处不大, 因为受 com 的限制代码不能使用段名, 浪费了 exe 使用段的能力. 已知

- masm 标签的值在编译时确定, org 100h 只在生成 com 时有用, 编写和编译时不知道生成 com 还是 exe, 全靠假定
- com 起始 cs = ds, 运行时所有标签的偏移 + 256
- 段的地址在加载时确定, 是正确的值, 但 com 不能使用段名, error A2118: cannot have segment address references with TINY model, 所以既不能用段名也不能把标签放另一个段里 jump 过去

com 修改了代码的偏移, 从段地址入手给 ds + 16 只能解决一部分问题

code | solved | why
-|-|-
`[label]`   | yes | label 是 m16, (ds + 16):offset 是正确的地址
`jmp label` | yes | label 编译为 rel16, 不参考起始地址
`mov ax, label`<br>`jmp ax` | no | near jump 不使用段, 所以必须使用正确的 offset<br>让 di = 256 然后 `lea ax, label[di]` 的话会占用一个寄存器 di

不想在运行时判断如果是 com 就用 256 做偏移, 因为这仍很死板 (也可能不死板, 毕竟代码只针对 com 和 exe, 无论如何先不考虑); 就只能用 [relocation](#relocation) 描述的 position independent code 计算代码的偏移, 保存到变量 initOffset; 每次使用 dx 保存的返回偏移时加上 initOffset. 适用于加载到随机偏移的程序, 但实际只存在 0 和 256 这 2 种偏移, 代码又比较繁琐, 所以不实用, 放这里只是展示这种可能性.

```
; ml -Foout\ dd.msm -Feout\[ -AT]

exeStackBytes = 32

cs1 segment
    assume ds: cs1

s:  call @f ; 使用了栈, 下面会用 0xee 填充栈
@@: pop ax
    sub ax, @b
    test ax, ax
    jz exe

    mov dx, ds
    add dx, 16 ; 'add' affects zf
    mov ds, dx ; (offset += 256 or 0x100) == (segment += 16 or 0x10)

    ; com 启动时 sp = 0xfffe, 栈上已有一个 word 0. 如果认为 0xfffe 是栈顶则 last10 应该是 0xfff4
    mov ssLast10, 0fff6h ; 不过这里忽略此 word

    jmp @f ; skip exe initialization

exe:
    ; at exe begin ds = seg psp, useless in any case. let ds = cs here because data resides in cs
    mov cx, cs
    mov ds, cx

    mov ssLast10, exeStackBytes - 10

@@: mov initOffset, ax ; use variable after ds is set, otherwise wrong address

    ; com 不把 xxx segment stack 当栈, 那里的 db n dup (x) 初始化的不是栈而是普通段
    ; 所以在这里而不是在 xxx segment stack 里设置栈的值
    mov bp, ssLast10

    ; com 设置 8 bytes, 保留 [sp] = [0xfffe] = word 0
    mov word ptr [bp + 0], 0eeeeh
    mov word ptr [bp + 2], 0eeeeh
    mov word ptr [bp + 4], 0eeeeh
    mov word ptr [bp + 6], 0eeeeh

    test ax, ax
    jnz @f ; ax = 0 is exe
    mov word ptr [bp + 8], 0eeeeh ; exe 设置 10 bytes

@@: mov si, 0 ; index of stash
    mov dx, @f
    jmp save10

@@: sub sp, 2
    mov dx, @f
    jmp save10

@@: push ax
    mov dx, @f
    jmp save10

@@: add sp, 2
    mov dx, @f
    jmp save10

@@: pop ax ; mismatch with push by intention
    mov dx, @f
    jmp save10

    ; int21h/ah40h print string, bx = 1 print to stdout
@@: mov bx, 1
    mov cx, lengthof stash
    mov dx, offset stash
    mov ah, 40h
    int 21h

    mov ah, 4ch
    int 33

stash       byte (3 * 10 + 1) * 6 dup ('=')
table       byte '0123456789abcdef'
initOffset  word 0
ssLast10    word 0

; 打印栈时不想让栈上有数据, 所以最好不调用函数而是用宏或不把返回地址放栈上的 jump, 这里用 dx 放返回地址
; reads
;   dx - jump to dx + initOffset when done
;   initOffset, ssLast10, table
; writes
;   ax - al, temp
;   bx - bl, byte to convert
;   cx - loop count
;   bp - points to stack elements
;   si - converted hex char was put in stash[si]
;   stash
save10:
    mov bx, 0   ; use bl twice to convert one byte to 2 hex digits
    mov cx, 10  ; converts 10 bytes in total
    mov bp, ssLast10 ; points to bytes to convert

@@: mov bl, [bp]    ; hhhhllll
    shr bl, 1       ; 0hhhhlll
    shr bl, 1
    shr bl, 1
    shr bl, 1       ; 0000hhhh
    mov al, table[bx]
    mov stash[si], al
    inc si

    mov bl, [bp]        ; hhhhllll
    and bl, 00001111b   ; 0000llll
    mov al, table[bx]
    mov stash[si], al
    inc si

    mov stash[si], ' '
    inc si

    inc bp
    loop @b

    ; replace last space to crlf
    inc si
    mov stash[si - 2], 13
    mov stash[si - 1], 10

    add dx, initOffset
    jmp dx
cs1 ends

ss1 segment stack
    db exeStackBytes dup (?)
ss1 ends
    end s
```

不用栈就没法用 call 0, 就不知道如何读 ip, 但仍能判断是否是 com, 类似

```
a   segment
s:
    mov cx, cs
    mov dx, ds
    cmp cx, dx
    jz @f

    ; this is exe
    int 3

@@:
    ; cs == ds is com
    int 3
a   ends
end s
```

类似下面的 exe 至少需要填充 4 字节才能正常退出又是为啥? 我不想再试了, 猜一下:

- 运行时 exe 栈的最后 2 字节可能改成了 a9 01, 但栈顶没变, 所以这 2 字节应该没啥用
- int 33 返回时要往栈上放 6 字节, 显然覆盖了程序, 程序前两句是 4 字节
- 4 + 填充的 4 = 8, 又大于了 int 33 push 的 6 字节, 不明白

```
xxx segment stack
s:
    mov ah, 4ch
    int 33
db 4 dup (0)
xxx ends
end s
```

### struct, local, assume bp: ptr records

32 位代码碎片 https://stackoverflow.com/questions/56506869/how-to-initialize-a-local-struct-in-masm-assembly

```
Records         STRUCT
data1           DWORD   ?
data2           DWORD   ?
data3           DWORD   ?
data4           DWORD   ?
Records         ENDS

main PROC
    LOCAL rec1: Records
    lea eax, [rec1]
    ASSUME eax: ptr Records
    mov [eax].data1, 1
    mov [eax].data2, 2
    mov [eax].data3, 3
    mov [eax].data4, 4
    ret
main ENDP

main PROC
    LOCAL rec1[4]: Records
    ; Compute address of third Record structure in array
    lea eax, [rec1]
    ASSUME eax: ptr Records
    add eax, 2*(SIZEOF Records)
    ; Initialize the the third Record structure
    mov [eax].data1, 1
    mov [eax].data2, 2
    mov [eax].data3, 3
    mov [eax].data4, 4
    ret
main ENDP

rec2 Records <1,2,3,4>
```

assume bp: ptr records 示例

```
; ml -Foout\ dd.msm -Feout\
; debug out\dd.exe
; g
; d ss:1c l20
; q

records struct
data1   word    ?
data2   word    ?
data3   word    ?
data4   word    ?
records ends

cs1 segment
s:
    call p1
    mov ah, 4ch
    int 33

p1  proc
    local rec[4]: records

    ; stack = records * 4, former-bp, return-offset
    ;         ^ sp         ^ bp

    ; method 1: set 4th rec in array, use bp

    assume bp: ptr records
    mov [bp - sizeof records].data1, 1
    mov [bp - sizeof records].data2, 1
    mov [bp - sizeof records].data3, 1
    mov [bp - sizeof records].data4, 1

    ; method 2: set 3rd rec in array, use sp through bp

    push bp ; save bp, sp -= 2
    mov bp, sp
    add bp, 2 + sizeof records * 2

    assume bp: ptr records
    mov [bp].data1, 2
    mov [bp].data2, 2
    mov [bp].data3, 2
    mov [bp].data4, 2

    pop bp ; restore bp

    ; method 3: set 2nd rec in array, use variable name through bp

    mov ax, bp ; save bp
    lea bp, rec[sizeof records]

    assume bp: ptr records
    mov [bp].data1, 3
    mov [bp].data2, 3
    mov [bp].data3, 3
    mov [bp].data4, 3

    mov bp, ax

    ; method 4: set 1st rec in array, use variable name through bx/di/si
    ; these registers use ds by default hence the override

    lea si, rec

    assume si: ptr records
    mov ss:[si].data1, 4
    mov ss:[si].data2, 4
    mov ss:[si].data3, 4
    mov ss:[si].data4, 4

    ; method 5: set 3rd rec in array, use variable name

    mov rec[sizeof records * 2].data2, 5

    int 3
    ; check memory ss:sp ~ ss:(sp + 32) in debugger, suppose sp = 0x1c
    ; cv: d ss:0x1c l0x20 or d ss:28 l32; debug: d ss:1c l20

    retn
p1  endp
cs1 ends
ss1 segment stack
    db 64 dup (0)
ss1 ends
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
; 从命令行编译时需要 includelib msvcrt.lib, 从 visual studio 2019 编译时不需要,
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

### 早期 crt 代码

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

