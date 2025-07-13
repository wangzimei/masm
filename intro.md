
*April 13, 2021: Markdown files will now automatically generate a table of contents in the header when there are 2 or more headings.*<br>
https://github.blog/changelog/2021-04-13-table-of-contents-support-in-markdown-files/

## getting started

### 开发环境

/ 表示本仓库, 和 .gitignore 的写法一致.

使用 dos 里的 debug.com<br>
/readme/online emulators, 无需本地虚拟机.

masm macro programs<br>
macro programs run at assembly time, you can assemble them using newer versions of ml.exe, thus avoiding dos and dosbox altogether.

build masm 6.x code and run it on dos 5+<br>
没找到安装了 masm 6.11 的 online dos, 必须在本地安装 dos 虚拟机, 然后安装 masm 6.11. 我使用 dosbox-x, 它是 dosbox 的一个经常维护的分叉.

dosbox 既不精确模拟硬件也不精确模拟 dos, 为什么用它?

- 目录映射为磁盘, 非必需但很方便
- 硬件和 dos 模拟
- x87
- voodoo. 代码源自 mame, pcem 和 86box 能完整模拟, bochs, virtualbox 都不支持

按 readme 的相关节安装并配置 dosbox-x, 打开后它会把 /dos 目录映射为 c:. 在 dosbox-x 里把 masm 6.11 安装至根目录 c:.

/readme/install dosbox-x on macos<br>
/readme/dosbox config<br>
/readme/masm 6.11

新建文件 /dos/dd.msm, 以后将使用此文件做源文件.

### minimal runnable

dos 下有两种常见的可执行文件, com 和 exe. 下面分别列举这两种文件的源代码, 首先是 com.

```
xxx segment
s:
    int 20h
xxx ends
    end s
```

将上述代码粘贴至 dd.msm 保存, 然后打开 dosbox-x, 在 dos 命令行执行 `ml -Foout\ dd.msm -Feout\ -AT`, 会生成 /dos/out/dd.com. 此程序只是用 `int 20h` dos 调用返回 dos, 不做其他事情. `segment` 是 masm 要求的程序要素, `end s` 告诉 masm 程序从标签 s 处开始执行. 命令行选项 `-Foout\` 让 ml 把 obj 文件放入 out 目录, `-Feout\` 让 ml 把可执行文件放入 out 目录, `-AT` 让 ml 通知 link 生成 com 文件.

然后是 exe.

```
xxx segment
s:
    mov ax, 0
    mov ah, 4ch
    int 21h
xxx ends
s01 segment stack
    word 64 dup (?)
s01 ends
    end s
```

将上述代码粘贴至 dd.msm 保存, 执行 dos 命令 `ml -Foout\ dd.msm -Feout\`, 会生成 /dos/out/dd.exe. 此程序仍然仅返回到 dos, 但不是通过 int 20h 而是通过 `mov ah, 4ch` 和 `int 21h`, 因为 com 和 exe 加载后寄存器的值不一样, exe 的寄存器初始值不适合用 int 20h 退出; 要坚持使用 int 20h 必须先修改 cs 寄存器, int21h/ah4ch 则无需操心 cs. int21h/ah4ch 还会把 al 寄存器的值作为程序的返回值, 上面的代码由于执行了 `mov ax, 0` 所以 al 是 0. 代码增加了一个叫 s01 的 segment, 这是因为如果 link 没看到程序定义栈段就会发警告. 段的名字不重要, segment 后面的 `stack` 指出了该段是栈段. 程序一般都要使用栈, 没有定义栈段的源代码生成的 exe 需要在执行时自己为栈寻找空间并修改 ss:sp. `word 64 dup (?)` 为栈段保留了 64 = 0x40 个未赋初值的 word, 即 0x80 个字节, 所以进入 exe 后 sp = 0x80. ml 的命令行没有 -AT 选项时 link 会生成 exe. 也可以把 xxx segment 标记为 stack 从而让代码只有一个 segment, 此时要留足栈空间, 避免使用栈时覆盖了程序代码.

### hello, world

```
; ml -Foout\ dd.msm -Feout\ -AT

xxx segment
    org 256
s:
    mov dx, offset msg
    mov ah, 9
    int 21h
    int 20h

msg byte "hello, world$"
xxx ends
    end s
```

上面是 com 文件. com 文件加载后第一句话放在 0x100 而不是 0, `org 256` 告诉 masm 此后的语句地址从 256 = 0x100 开始算, 这样代码在汇编之后标签的值才能匹配它在运行时的值. 代码里有两个标签, s 和 msg. s 不需要 org 语句因为只有 end 使用它, 而 end 不需要考虑标签加载后的值; msg 被其他代码使用, 必须用 org 修正它的值. 可以看到 s 和 msg 定义的方式不一样, msg 这种方式定义了数据标签, 或叫变量. 变量在 masm 代码里表示以变量地址开始的一段内存里保存的值, 要获得变量的标签值或者说变量的地址或者说变量的偏移需要在前面写 offset, 后面会看到地址由 segment 和 offset 组成, `offset msg` 在汇编时替换为 msg 的偏移. 这里用 `int21h/ah9` dos 函数打印字符串, 该函数打印从 ds:dx 开始的串, ds 是 segment, dx 是 offset, 在遇到第一个 `$` 时结束打印. msg 放在 com 文件唯一的段里, 段地址是 `seg msg`, com 文件执行时 ds 等于该段所以无需修改 ds.

```
; ml -Foout\ dd.msm -Feout\

xxx segment
s:
    mov dx, seg msg
    mov ds, dx
    mov dx, offset msg
    mov ah, 9
    int 21h

    mov ax, 4c00h
    int 21h
xxx ends

d01 segment
msg byte "hello, world$"
d01 ends

s01 segment stack
    word 16 dup (?)
s01 ends

    end s
```

exe 代码定义了一个 `d01` 段用来保存数据 msg. 把 msg 放在 xxx 里也没问题. exe 加载后 ds 的值不指向保存数据的段, masm 没有像栈段那样的语法去指出数据段, exe 文件也不保存数据段的信息, 要自己在代码里修改 ds 让其指向自己定义的数据段. 8086 的段寄存器只接受通用寄存器的赋值, 所以代码里先把 seg msg 给 dx, 再用 dx 给 ds 赋值. 段名 d01 的值就是段地址, 也是其中所有变量的段地址比如 seg msg.

## 8086 cpu

8086 和 8088 指令集相同, 有小的硬件差异比如 8086 是 16 位外部数据总线, 8088 是 8 位, 成本较低, 性能稍逊, 广泛用于 ibm pc.

做好准备, 下面将出现大量杂乱无章的术语.

### mnemonic

汇编语言没有标准语法, 汇编器在 cpu 厂商提供的 mnemonic 语法基础上创造自己的语法.

```
            / masm directives   -   mnemonic, operands (see below), infos \
source code                                                                 obj file \
            \ mnemonic, operands     -   instruction    -    machine code /            executable
( from left to right -> )                                                   obj file /

mnemonic = name of a group of opcodes                cpu function index = operation code = opcode
operands = argument1, argument2, argument3                   rest part of instruction = (no name)
statement = label: mnemonic operands                                    (see below) = instruction
source code = statements + assembler directives                       instructions = machine code

https://wiki.osdev.org/X86-64_Instruction_Encoding  An x86-64 instruction may be at most 15 bytes
in length. when either Displacement or Immediate is 8 bytes, another can not be encoded
Legacy prefixes         (1-4 bytes, optional)
Opcode with prefixes    (1-4 bytes, required)
ModR/M                  (1 byte, if required)
SIB                     (1 byte, if required)
Displacement            (1, 2, 4 or 8 bytes, if required)
Immediate               (1, 2, 4 or 8 bytes, if required)
```

intel 把指令中的操作 + 参数类型叫做 prefixes + opcode + modr/m + sib, 把参数叫做 displacement + immediate. displacement 也是 immediate, modr/m, sib, displacement 都用来计算有效地址, 后面会解释有效地址. mnemonic 和 opcode 的参数都叫 operand. 这是个混乱的对应关系.

一个 mnemonic 往往对应好几个 opcodes, 往往不包括 opcode 需要的 prefix 和 modr/m. 乍一看这能少写点代码, 实际上要多写其它的代码:

- 假设对应同一个 mnemonic 的两个 opcodes 都接受数字做操作数, 但一个解释为数量一个解释为地址, 那就无法分辨源代码里的 mnemonic n 对应哪个 opcode, 也就无法汇编. 不同的 opcodes 对应同样的 mnemonic 时为区分操作数类型 intel 定义了修饰操作数的语法, 当数字用作地址时写为 [n]. 假设 intel 为读内存专门设置了助记符 read-mem, 则 read-mem ax, 3 毫无歧义地表达从地址 3 处取值放入 ax. 当地址进一步复杂比如 [si + 2] 时就没有歧义了, 因为 intel 不允许 mov ax, si + 2, 只允许 mov ax, [si + 2]. 按理说既然这时只能是地址, 就不存在 "区分" 这回事儿, 也就不需要方括号, 但实际上仍要写
- 无法确定操作数的长度时要写 size 或 size ptr 以帮助生成 modr/m, 如 mov [200], byte ptr 3, 相当于假想的语法 write-mem-byte 200, 3
- *read-mem ax, 3 也可以写成 read-mem-ax 3 或 read-mem-ax-3 或 fill ax with bytes starting from memory location 3. 写法不同但给出的信息都一样*
- 寄存器和地址在执行时的 cpu 模式里有唯一长度, 不能用 size 之类的辅助代码修改. mnemonic 知道这长度
- 后面还能看到其他的辅助代码
- ret 没法汇编. intel 没有发明辅助代码, 汇编器发明了 retn, ret near, retf, ret far 这些东西 (directive, pseudo-instruction, pseudo-opcode 不知道该叫啥)

下面是源代码转换到机器码的示例, 后面的节列举了 debug.com 的大致用法.

```
debug
a
mov [200], byte 3
mov [103], word 3
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

    所以 c6 = MOV r/m8 imm8. r/m8 需要 modr/m, 所以 c6 后面的 06 是 modr/m 字节.<br>
    https://stackoverflow.com/questions/8518917/x86-mov-opcode-disassembling

1. c6 06 ...

    http://ref.x86asm.net/coder32.html#modrm_byte_16 的表把 modr/m 字节分成 3 部分: 最上面的 reg/opcode 占 3 位, mod 列占 2 位, r/m 列占 3 位. 值 06 的周围如下:

    ```
                                    000
    Effective Address   Mod R/M     Value of ModR/M Byte (in Hex)
    disp16              00  110     06
    ```

    整张表都是计算有效地址的各种方式, 06 对应 disp16. disp16 是 16 位的 displacement, 单独的 disp16 说明用下 2 个字节共 16 位计算出地址, 不涉及 bx, di 等寄存器. 因此 `mov r/m8 imm8` 对应机器码 `c6 06 hhhh hh`. 从机器码里依次取 2 字节和 1 字节, 得到

1. c6 06 0002 03 ...

有

```
    c606000203
=   no-prefix opcode#c6 modr/m#6 no-sib 0002 03
=   function#c606(0x200, 3)
=   mov m8 imm8(0x200, 3)
=   mov byte [0x200], 3
```

`c70603010300 mov word ptr [0103], 0003`, 有 `C7 MOV r/m16/32 imm16/32`, 16 位代码排除 m32 和 imm32 得到 c7 = mov r/m16 imm16, 前面知道 06 是 disp16, 所以 c7 06 = mov m16 (由 disp16 指定) imm16, 从 c7 06 往后取 2 个 16 位, 分别是 disp16 = 0301, imm16 = 0300.

**byte code**

有些编译器把代码编译为字节码, 由该语言的虚拟机执行. 比如 java.

**microcode**

a.k.a. μcode https://en.wikipedia.org/wiki/Microcode

完全位于 isa (instruction set architecture) 的一侧, 汇编看不到. 各方面都和汇编差不多, 不是每种 cpu 都有.

以前的机器语言就是 cpu 执行的语句, 语句由 isa 定义. 后来 (around 1950) 可能是指令复杂了, 或想兼容以前的代码 (从而不可移植的汇编也可移植了), 或任何原因, 机器语言要翻译为 microcode 让 cpu 执行, 这就把机器语言变成高级语言了.

**micro-operation**

a.k.a. micro-ops, μops, micro-actions https://en.wikipedia.org/wiki/Micro-operation

主要是 intel 用, 前面说的 microcode 有很多厂商都用. 一般看到莫名其妙的术语扎堆儿出现, 基本就是 intel.

### operands

opcode 的 operand 有 2 种: displacement 和 immediate. mnemonic 的 operand 有 3 种:

1. 立即数. a.k.a. 数值字面量 numeric literal
1. 寄存器. 一些预定义的单词
1. 内存. 写做 `[有效地址]`, 有效地址是立即数和寄存器的组合

这 3 种操作数在不同的助记符后面有不同的意义, intel 给这些意义取了名字. 下面列举这些名字, 以及一些常见术语.

**imm8, imm16, imm32, imm64**

immediate. 写入生成的二进制文件作为指令的一部分.

imm8 是 8 位立即数, 其余分别是 16, 32, 64 位立即数. 源代码里写下来的都是 immediate, 无法区分 8, 16 等长度, 汇编器从上下文推导长度. 比如 `mov ax, 3` 知道 ax 长度是 16 位, 所以 3 是 imm16; 而像 `mov [200], 3` 这种语句不提供长度信息, 无法汇编, 必须塞进去个长度信息, 类似 `mov (BYTE!!!1) [200], 3`.

**r8, r16, r32, r64**

8, 16, 32, 64 位的通用寄存器. 这些寄存器都有确定的名字如 ah, bx, ecx, rdx, 名字绑定长度, 无需额外指出.

intel 把 ax, cx, dx, bx, sp, bp, si, di 编号为 0 ~ 7, 文档里偶尔会用到这编号.

mm = mm0 ~ mm7, xmm = xmm0 ~ xmm7, sreg = segment register.

**offset**

实模式用 segment:offset 表示地址, 偏移是相对于段的偏移. segment 和 offset 单独都表示不了地址, offset 经常隐含依赖一个 segment 以表示地址. intel 把 segment 和 offset 叫逻辑地址, segment:offset 叫物理地址; 逻辑应该是指发明 “逻辑地址” 这个词的人的逻辑, 正常的逻辑不会把部分说成是整体.

前面说 offset 经常隐含依赖一个 segment, 它俩共同计算出地址. intel 提供了显式指定段寄存器的语法, 叫段寄存器重写.

**rel8, rel16, rel32**

relative offset, 相对于下一条语句的偏移, 只有 immediate 形式, 用于 jmp, jcc, call, loop.

relative offset 不会出现在 mnemonic 后面, debug.com 和 masm 里都写为 jmp offset, 也就是助记符后跟偏移; 也不会出现在 opcode 后面, 因为 opcode 后面只能是 displacement 和 immediate; 它只出现在文档中, 只有指令文档里写 jmp rel; 估计 relative offset 算一种 displacement. 比如 `100: jmp 104` 里的 104 是偏移, 不是相对偏移. 汇编器根据当前语句的位置, 当前语句的长度以及目的地 104 计算出相对偏移, 汇编为 `eb 02`. 把 jmp immediate 汇编为 jmp relative-offset 的过程大致是: rel8 是有符号整数, 能表达的最大数是 0x7f; 语句位于 100, 2 字节的 jmp rel8 最多能往后跳到 100 + 2 + 0x7f = 229, 能够表达 jmp 104, 因此选定 2 字节的 jmp rel8, opcode 是 eb; 104 - 100 - 2 = 2; 因此汇编为 eb 02.

**effective address**

专指用 Base + Index * Scale + Displacement 计算出的 offset. 它是 offset, 即便名字叫 effective address. 其中<br>
https://stackoverflow.com/questions/36704481/what-is-an-effective-address

. | 16-bit | 32, 64-bit
-|-|-
base    | bx, bp (base pointer)                     | any register
index   | si (source index), di (destination index) | any register except esp, rsp
scale   | n/a, see below                            | 1, 2, 4, 8

16 位代码和使用 16 位寄存器的 32 位代码没有 sib = Scale Index Base, 不能使用 scale. displacement 是 opcode 的 immediate 操作数, 有 **disp8, disp16, disp32**.

**memory**

[effective address] = memory. 默认的段寄存器是 ds, 重写时有些汇编器可以省略方括号, debug.com 不行, 并且它写法不同, es: 不是写在 memory 前而是写在整个语句前. memory operand 需要先计算 effective address, 结果要么保存在某个位置要么是某组电路的输出, intel 隐藏了这个位置. lea 指令 load effective address 就使用了该位置.

- **m8/16/32/64 = m8 or m16 or m32 or m64**<br>
    数字指 opcode 从偏移处读取的长度, m8 是 byte, m32 是 dword, 等
- **m16&16, m16&32, m16&64, m32&32**<br>
    内存视为两部分, 长度分别是 16 + 16, 16 + 32, 16 + 64, 32 + 32
- **m16:16/32/64 = m16:16 or m16:32 or REX.W m16:64**<br>
    内存被用作 far pointer. 和 m16&16 那一组可以说是完全重复
- 上面那些数字说的都是内存的长度, 而 effective address 或者说 offset 是固定长度. 即使给出不同的长度也会在使用时扩展或截断

**moffset (amd), moffs (intel) = moffs8, moffs16, moffs32, moffs64**

immediate 形式的 offset, 仅用在几个 mov 里.

**r/m16 = r16 or m16**

需要 modr/m. 按正常的理解 r/m16 = r or m16, 这里却不是. 猜测推导过程为 r/m16 = (r/m)16 = r16/m16 = r16 or m16. 这推导当然漏洞百出, 比如 r16/m16 = (r16/m)16 = r1616/m16 = (r1616/m)16 = r161616/m16 = ... 不过或许压根儿没有推导过程, 而是一个规定, 那样的话就没有疑点了.

**ptr16:16/32 = ptr16:16 or ptr16:32**

immediate 形式的 far pointer, 没有 modr/m 的地址. 仅用于跳转, 冒号前的数字给 cs, 冒号后的数字给 ip/eip.

只有两种形式. 16 位模式是 ptr16:16, 代码中写作 0xabcd:0x1234, 生成的指令中排列为 34 12 cd ab; 32 位模式是 ptr16:32, 代码和指令分别是 0xabcd:0x12345678 和 78 56 34 12 cd ab; 没有 64 位模式的立即数 far pointer. 操作数类型是 ptr16:16/32; 生成的指令操作数类型是 disp16/32 和 imm16? 不确定; 在内存中其起始地址的 memory 类型是 m16:16/32.

前面说过无法区分 mnemonic 对应哪个 opcode 时 intel 创造新的语法去修饰 operand. 这里, 两个立即数中间的冒号就是创造的新语法. 由于 jmp 还有个接受立即数的形式, 16 位模式下是 jmp rel8/16, 如果把 far pointer 写成一个立即数, 就无法从代码里区分 jmp immediate 是 jmp rel8/16 还是 jmp far-pointer.

ptr16:16 用 2 个 16 位表示 20 位地址, ptr16:32 用 16 + 32 位, 但不清楚表示几位地址, 可能是 eip 里的 32 位因为 32 位模式不使用分段地址, cs 不参与地址计算. 分段模式下 far pointer 是真正的地址, offset 是地址的一部分; 不分段模式下 offset 是真正的地址, far pointer 是真正的地址 + 额外的值 (用来修改 cs).

```
literal 3 in 16-bit code    typeof operand 3    instruction     typeof 3 in instruction
     0: jmp 3               imm8  (*1)          eb 01           imm8  , no modr/m, not 3 (*2)
 0x100: jmp 3               imm16 (*1)          e9 00 ff        imm16 , no modr/m, not 3 (*2)
        jmp 0x100:3         a part of ptr16:16  ea 03 00 00 01  imm16 , no modr/m (*2)
        mov ax, 3           imm16               b8 03 00        imm16 , no modr/m (*2)
        mov [] 3, ax        moffs16             a3 03 00        imm16 , no modr/m (*2)
        mov [] 3, bx        m16                 89 1e 03 00     disp16, accroding to modr/m
        mov [] 3 bx, ax     a part of m16       89 47 03        disp8 , accroding to modr/m

*1. or rel8/16? it's really an immediate, relative to nothing
*2. it's immediate since it has no modr/m
```

**offset, address, memory, pointer**

- 8086 用 2 个 16 位寄存器寻址 20 位, 写作 segment:offset. offset 就是这里的段内偏移
- logical   address = segment, offset, far pointer (intel sdm, vol. 1, 4.3 pointer data types)
- physical  address = segment:offset
- effective address = base + index * scale + displacement = offset
- linear    address = real mode segment:offset, protected mode base + offset
- virtual   address = linear address in protected mode with paging
- memory = [effective address]
- near pointer = effective address
- far pointer = 16-bit segment + 16/32/64-bit offset

far pointers in source code | type, inferred from context | type a.k.a.
-|-|-
imm:imm                     | ptr16:16  | dword
(same as above)             | ptr16:32  | fword
[effective address]         | m16:16    | dword
(same as above)             | m16:32    | fword
(same as above)             | m16:64    | (same as above)

*曾参照 ptr16:16 的写法把 m16:16 写为 [0x1234]:[0x5678], 怎么汇编也不过. 后来才知道 m16:16 应看作 m(16:16) - m 代表这是个 memory, 所以写法是 [offset]; : 代表 implicit-segment:offset 指向 far pointer; 16 16 代表指向内存的长度是 16 + 16 = 32 位. 后来也知道了 ptr16:16 虽写作 0x123:0x456 但不应看作 ptr16:ptr16; far pointer 表示 segment:offset, 不存在单独的 ptr16; 冒号不能像斜杠那样展开.*

*在 http://ref.x86asm.net/ 上看到大量莫名其妙的缩写, 尤其是 m16:16 和 r/m16/32, 反复遇到, 每次都不理解. 于是决定弄清那些缩写的含义. 查了半天, 先理解了 rel16/32, 又在 https://www.scs.stanford.edu/05au-cs240c/lab/i386/s17_02.htm 17.2.2.2 Instruction 找到了 r/m16 的解释, 这才大致理解了 r/m16/32, 并通过 https://www.felixcloutier.com/x86/jmp 验证了我的理解; 经过反复试验和查看 https://stackoverflow.com/questions/51832437/encoding-jmp-far-and-call-far-in-x86-64 又理解了 m16:16. 这些学到的知识汇成了本节. 这些知识当然无法解决遇到其他缩写时的疑问, 因为那些缩写都是随意编出来的.*

*后来遇到了 m16&16, 到处找不到解释, 不得不看 intel 手册, 之前不看是因为那书太厚. 看了才发现本节内容完全包含在 Intel® 64 and IA-32 Architectures Developer's Manual: Vol. 2A, 3.1.1.3 Instruction Column in the Opcode Summary Table, 不过它没我说的清楚. 指向两段式内存的 offset, 如果两段内存当 far pointer 用, [offset] 是 m16:16, 否则是 m16&16.*

### 存储, 变量

cpu 的作用是修改一些数字, 这些数字保存在哪? 在 cpu 的知识里有 2 个位置: register, memory. cpu 依赖寄存器和内存, 寄存器内置于 cpu 中, 内存是相对于 cpu 的外部设备. 还有其他的存储但 cpu 对他们没有特别的知识, 使用这些存储的代码在 cpu 看来仍是在使用 register, memory. intel 用名字表示大部分寄存器, 序号表示内存和 msr 寄存器. 这么做的依据可能是寄存器很少而内存位置很多. 名字和序号都能在汇编前确定, 序号也可以在运行时确定.

以下是一部分寄存器, 可以看出只要涉及到数量, 用名字就只是浪费精力.

- intel sdm, vol. 3, Figure 2-6. Memory Management Registers

name (x86/x64)  | in code       | count | bits  | notes
-|-|-|-|-
general purpose | rax-r15       | 8/16  | 32/64 | 整数, 地址等
flags           |               | 1     | 32/64 | 算术, 控制状态
segment         | cs-gs, ss     | 6     | 16    | 段地址, 描述符选择
x87             | st(0)-st(7)   | 8     | 80    | 扩展精度浮点运算
mmx             | mm0-mm7       | 8     | 64    | 整数 simd. same register file as above
control, status, tag word      || 3     | 16    | fpu
sse             | xmm0-xmm15    | 8/16  | 128   | simd
avx, avx2       | ymm0-ymm15    | 8/16  | 256   | simd. same register file as above
avx-512         | zmm0-zmm31    | 0/32  | 512   | simd. same register file as above
mxcsr           |               | 1     | 32    | simd vector status
opmask          | k0-k7         | 8     | 16    | avx-512 conditional vector processing
control         | cr0-cr15      | 4     | 32/64 | cr1, cr5-cr15 未使用
xcr0            |               | 1     | 64    | extended control
debug           | dr0-dr7       | 8     | 64    | 调试
gdtr, idtr      |               | 2     | 48/80 | 全局, 中断描述符表. 这 2 个和下 2 个是 memory management
ldtr, tr        |               | 2     | 16    | 局部描述符表, 任务寄存器. 有 48/80 + ? 的影子寄存器
msr             | (by index)    | many  | vary  | 模型特定寄存器

intel cpu 还能访问第 3 种存储, port. port 是其他设备的 register, 理论上也可以对应其他设备的 memory (通过内存地址映射, memory 也可以对应其他设备的 register 和 memory). 因此前面只把 register 和 memory 算作存储, 没算入 port. register 和 memory 的区别也只在容量和速度.

指代存储位置的名字叫变量. 很多汇编器支持用 label 给内存位置取名, 这 label 就是变量. 变量在其有效期内始终指代某个位置. 使用变量是两步操作, 读的时候先读位置再读数据, 写的时候先读位置再写数据.

术语 | 含义
-|-
变量 | 具有名字的存储位置叫变量, 变量是存储位置的别名
变量的地址 | 变量代表的存储的地址; 寄存器的名字对应寄存器地址, 但代码不能使用该地址
变量的值 | 变量代表的存储当前存放的数据
变量的类型 | 变量代表的存储的大小; 或语言规定的类型
变量的值的类型 | 变量的类型; 或语言规定的类型, 比如 c++ 指向派生类的基类指针

### 段寄存器

8086, 8088, 80186, 80188 是 16 位寄存器和 20 位地址线 https://en.wikipedia.org/wiki/RAM_limit

段寄存器用来确定内存地址. 8086 能寻址 20 位, 16 位寄存器容纳不下 20 位地址, intel 就规定用两个 16 位值, 段和偏移, 表示一个 20 位地址, 写作 segment:offset, segment * 16 + offset = 20 位地址. 段和偏移分别保存在段寄存器和有效地址里, 有效地址只能用通用寄存器和立即数算出, 也就是说, 不能用两个通用寄存器或两个段寄存器合起来表示地址. 我既不清楚为什么把乘以 16 的那个部分叫 segment, 也不清楚为什么做成把一个 16 位值乘以 16. 由公式可知,

- 段地址不连续, 每个段的地址都是 16 的整数倍; 偏移地址连续
- offset 的大小决定段的大小, 是 2 ** 16 = 65536 = 64k
- 2 个 16 位寄存器共 32 位表示 20 位地址, 多出来的 12 位造成很多重复的地址
- 两个段的重叠部分至多 64k - 16 - 16 = 65504; 不重叠的话 640k = 10 个段, 1024k = 16 个段
- 20 位最大值是 0xfffff, segment:offset 最大值是 0xffff << 4 + 0xffff = 0x10ffef, 多出来 0xfff0

有 4 个段寄存器 cs, ds, es, ss, cpu 占用 cs 和 ss 这 2 个. 386 加了 fs, gs 段寄存器和 lfs, lgs, lss 指令.

- 代码 cs:ip
    - a.k.a. program counter (pc), instruction pointer (ip), instruction address register (iar), instruction counter
    - 修改 cs 和 ip 必须一次性完成, 专有数据类型 far pointer (ptr16:16/32)
- 栈 ss:sp
    - 就是数据结构里的栈, 专有指令 push, pop
    - ss:sp 保存的内存地址叫栈顶. push arg 从 sp 减去 sizeof arg, 然后把 arg 写到栈顶
    - sp 保存 offset 但不能用于寻址, 要修改栈顶只能先 mov bp, sp 然后修改 [bp]. 之所以用 bp 是因为 bp 默认段 ss, 可以省一个段寄存器重写
    - 修改 ss 和 sp 不需要一次性完成. 但如果两条修改指令之间发生了中断而进入中断服务例程就会使用栈, 这时的栈只修改了一半, 就会出错. 所以 286+ 的 mov ss, r/m16 的下一条指令无法中断以便放置 mov sp, xxx, 就可以省去 cli 指令 (cli 屏蔽 "可屏蔽中断", 听名字就是个残废)
- 除 cs:ip 和 ss:sp 外的都是数据, 比如 cs:di, ds:bp, es:123, ss:bx
    - 代码里往往需要标记地址但有不同的写法, 可能是 cs:[di], ds:[bp], es:123, ss:[bx]
    - 可以用来寻址的寄存器是 bp, bx, si, di; 省略段寄存器时 [bp] 默认 ss, 其余默认 ds; [immediate] 默认 ds
    - 源数据 ds:si 和目的数据 es:di 是两个常见的说法
    - `lds/les r16/32, m16:16/32`, `lfs/lgs/lss r16/32/64, m16:16/32/64` 用 `jmp m16:16` 修改 cs:ip 的方式修改 ds/es/fs/gs/ss:reg, 没有 lcs. 这些指令只是增加 m16:16/32/64 的利用率; 修改数据地址无须一次性完成, 可以用两条指令依次修改. 这里的 m16:16 就是 m16&16
- 386 通用寄存器是 32 位, 保护模式下寻址也是 32 位, 但仍使用段寄存器, 用 16 + 32 位表示 32 位地址, 并且更加复杂, 需要查表
- 长模式的 fs, gs 从 msr 取 base, 其余 segment 不参与地址计算

### 标志寄存器

bit | flag | meaning | 0 | 1
-|-|-|-|-
0  | cf | carry              | nc | cy
2  | pf | parity             | po | pe
4  | af | auxiliary carry    | na | ac
6  | zf | zero               | nz | zr
7  | sf | sign               | pl | ng
8  | tf | trap (single step)
9  | if | interrupt enable   | ei | di
10 | df | direction          | up | dn
11 | of | overflow           | nv | ov

### jmp short, near, far, long

- intel 不允许 ip/eip/rip 当操作数, 指令寄存器通过 jmp (call, ret, ...) 修改
- 8086, 8088 有 pop cs, opcode 0xf 和 mov cs, reg/mem, opcode 8e xxx. 8086 online 模拟器 https://idrist11.github.io/8086-Online-IDE/app.html
- arm32 允许读写 ip, arm64 不允许

jump 有两种形式, jump to constant, jump to variable. 常量在汇编时确定, 变量在运行时确定. jump 的目的地可以是:

- relative to 0, 远指针
- relative to segment, 近指针
- relative to ip, 相对于下一条指令的位置的偏移

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

一些示例,

operand type | debug | masm | meaning
-|-|-|-
rel16       | jmp 7             | [error A2076](#error-a2076-jump-destination-must-specify-a-label)
r16         | jmp bx            | jmp bx                    | load  word t from register bx, near jump to t; bx = value of t
m16         | jmp [bx]          | jmp  word ptr [bx]        | load  word t from memory ds:bx, near jump to t; bx = offset of t
m16:16      | jmp far [bp si 3] | jmp dword ptr 3[bp + si]  | load dword t from memory ds:(bp + si + 3), far jump to t
seg:r16     | es: jmp bx        | error A2032               | = jmp bx, es is not used
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
1. 考虑字节序, 操作数是 0xfefd
1. 执行 e9fdfe 前 ip = 0x100
1. 执行 e9fdfe 时 ip = 0x103
1. 执行 e9fdfe 后 ip = 0x103 + 0xfefd = 0x10000 -> to word = 0

32 位下 m16 是指向 16 位内存的 32 位 offset, jmp m16 要对 m16 指向的内存进行 `zero extend`, 如果 m16 保存在 16 位寄存器里就会发生 2 次 zero extend. 打开 https://carlosrafaelgn.com.br/Asm86/ 输入下列代码; 点右上角的 windows, registers; 用左上角的 step 观察,

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

near jump [r16, r32, m16, m32], far jump

```
operand     godbolt.org (nasm)              32-bit                  16-bit              debug.com
r16         jmp ax                       66 ff e0 (*1)              ff e0
r32         jmp eax                         ff e0
m16         jmp word [di]             66 67 ff 25                   ff 25               jmp [di]
m32         jmp [di]                     67 ff 25
m32         jmp [edi]                       ff 27
m16         jmp word [word 0x1234]    66 67 ff 26 34 12 (*2)        ff 26 34 12 (*3)    jmp [1234]
m16         jmp word [0x1234]            66 ff 25 34 12 00 00
m32         jmp [0x12345678]                ff 25 78 56 34 12 (*4)
m32         jmp [cs:0x12345678]          2e ff 25 78 56 34 12       <- cs segment override
m32         jmp [es:0x12345678]          26 ff 25 78 56 34 12       <- es segment override
m32         jmp [ss:0x12345678]          36 ff 25 78 56 34 12       <- ss segment override
m32         call [0x12345678]               ff 15 78 56 34 12
ptr16:32    jmp 0xaabb:0x1122               ea 22 11 00 00 bb aa    ea 22 11 bb aa      ptr16:16
m16:32      jmp far [0x100]                 ff 2d 00 01 00 00       ff 2e 00 01         m16:16
m16:32      jmp far [ds:0x100]           3e ff 2d 00 01 00 00    3e ff 2e 00 01         m16:16
m16:32      jmp far [di]                 67 ff 2d                   ff 2d               m16:16
m16:32      jmp far [edi]                   ff 2f

*1. 32-bit ModR/M Byte 已经没有位置表示 op 是 m16 了, 所以额外用一整个前缀字节 66 表示
    66 = Operand-size override prefix, 67 = Address-size override prefix
*2. 不明白这为啥是 26
*3. opcode extension = 4, 从 http://ref.x86asm.net/coder32.html#modrm_byte_16
    找 (In decimal) /digit (Opcode) = 4 的列, 然后找 disp16 的行, 交点是 26
*4. http://ref.x86asm.net/coder32.html#modrm_byte_32 列 4 和行 disp32 的交点是 25

* 开始误以为 m16:16 语法类似 [0x1234]:[0x5678], 汇编不过 (必然的), 于是打算凑个 16 位机器码看反汇编成啥
opcode extension 5 要求使用 ModR/M Byte, 但 modr/m 里没有 disp16:disp16, 用 disp16 凑了个 2e, 进而凑出个
ff 2e 34 12, 在 debug.com 里用 e 写入, 反汇编得到 jmp far [1234]. 用 32 位汇编 jmp far [0x1234] 得到
ff 2d 34 12 00 00   jmp FWORD PTR ds:0x1234. 还凑出了
ff 2f               jmp FWORD PTR [edi]
ff 2e               jmp FWORD PTR [esi]
```

- 16 位模式, debug 用 jmp far, masm 用 jmp dword ptr. dword ptr 无法区分 m32 和 m16:16, 但没有同时接受 m32 和 m16:16 的 jump
- `far` 和 `[]`, `size`, `:` 一样用于帮助汇编器选择合适的 opcode
- godbolt.org 用 -felf64 汇编 `jmp far [rdi]` 得到 `48 ff 2f rex.W jmp fword ptr [rdi]`. m16:64 对应 rex.W fword ptr? fword 就是 far word, far 表示此值总是带着一个 16 位值, word 表示它不是 word, 32 位模式下 fword 是 32 + 16 位, 64 位模式下是 64 + 16 位
- ptr16:32 和 m16:32 也能用 word 之类的修改长度, 但不知道会执行成啥样, 没试. 应该是扩展或截断或报错

godbolt.org 32 位的一些汇编结果
```
jmp far   [di]       67 ff 2d       jmp FWORD PTR [di]
jmp dword [di]       67 ff 25       jmp DWORD PTR [di]
jmp word  [di]    66 67 ff 25       jmp WORD  PTR [di]

jmp far   [edi]         ff 2f       jmp FWORD PTR [edi]
jmp dword [edi]         ff 27       jmp DWORD PTR [edi]
jmp word  [edi]      66 ff 27       jmp WORD  PTR [edi]

jmp fword [di]          <Compilation failed>
jmp fword [edi]         <Compilation failed>
```

示例: m16:16 的第 1 个 2 字节给 ip, 第 2 个 2 字节给 cs, 和 far call, far return 时栈里的 cs 和 ip 顺序一致.
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

示例: 用内存中 jmp ptr16:16 指令操作数的偏移当 jmp m16:16 的操作数

- `jmp ptr16:16` 指令是 `ea xx xx xx xx`, 5 字节, 从第 2 字节开始的 4 字节是 offset 和 segment
- 这个示例里 `jmp m16:16` 的 m16:16 指向 ds:(`jmp ptr16:16` 的位置 + 1 字节)
- 没法用 jmp m16 实现 jmp m16:16. jmp m16 是个 near jump, 不修改 cs

程序设计 | 注释
-|-
cs:100 jmp far [10b]    | 0x10b = 0x10a + 1. 0x10a 是下面的 jmp ptr16:16 指令的偏移, 代码里可以用标签获得指令的偏移
cs:104 db 1 2 3 4 5 6   | 随意的填充字节, 目的是隔开两个 jump. 不填充也行
cs:10a jmp 1337:0       | 这个 5 字节指令的后 4 位内存的偏移被第一个 jump 视作 m16:16
1337:0 int 3            | 纯粹是好玩儿, 我想让 debug 中断到这里. 有没有这句都不影响本示例

ptr16:16 是两个汇编时就确定的立即数, 写代码的时候就得知道要跳到哪. 我想往它指向的内存写 int 3, 如果覆盖了其他程序, 就很可能要重启 dos 虚拟机. 如何确保 ptr16:16 指向空闲内存? 我不确定, 可能的办法是:
- 代码里定义一个大变量, 当空闲内存
- 运行时: 整个 cs 段应该都能用, 当然得避免覆盖自己的代码
- 运行时: dos 2 的 int21h/ah48h 可能能用来确定空闲内存
- 运行时才获知空闲内存的地址, 那时已经没法汇编了, 只能从地址凑 jmp ptr16:16 的 5 字节指令, 写入内存去执行

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

### port

`in al/ax/eax, imm8/dx (port address)` 和 `out imm8/dx (port address), al/ax/eax`

端口指有些设备的寄存器. 端口地址是 16 位, 总共 2 ^ 16 = 65536 = 64k 个. 访问端口时用 in 读取单个端口地址上的 1, 2, 4 字节, out 写入; 内存地址映射是用 mov data, mem 读取从 mem 开始的 bytesof data 字节, mov mem, data 写入. 端口和内存地址映射的功能重复, 之所以发明它可能是当时的内存地址太少所以开辟了另外一种地址. 理论上设备的寄存器既可以通过端口也可以通过内存地址映射访问. 端口的地址线可以有两种实现,

- 复用地址线, 并增加一个 cpu 引脚指明是否为端口访问
- 使用单独的一套引脚

### interrupt

按设计, cpu 每执行一条或一组指令就查看是否有中断请求, 有的话就暂停当前执行的指令去执行请求指出的指令, 执行完可能会继续执行之前暂停的指令.

已知 cpu 通过内存地址映射或端口去通知其他硬件, 那其他硬件如何通知 cpu 呢? 不让 cpu 去频繁查询内存或端口来获取硬件的通知, 因为频繁查询的效率低, 访问端口的速度慢. 其他硬件通知 cpu 的办法是生成一个中断. intel interrupts 占用下列术语; arm 还占用 reset.

- exceptions. generated by cpu
    - faults. return address = the instruction that generated the exception
    - traps
    - aborts
- Interrupt Request (IRQ) or Hardware Interrupt
    - IRQ Lines, or Pin-based IRQs
    - Message Signaled Interrupts
- Software Interrupt. generated by int n instruction

`cli` 让 cpu 此后不响应可屏蔽中断; 286+ 上 `mov ss, reg` 的下一条指令无法中断, 用于在 mov ss 之后 mov sp.

总共 256 种中断, 硬件中断由 8259 把 irq 映射到 int n, cpu 也能引发中断, int n(0 ~ 255) 指令也能引发中断; 所有 256 种中断都能用 int n 从代码里引发; int 指令引发的中断和 fault 引发的中断在进入中断服务例程时栈上的返回地址不一样, int 是下一句, fault 是当前句, [示例](#bound-80188-m1616-int-5). 内存地址 0 ~ 1024 的 256 个 m16:16 是中断服务例程的地址, cpu 决定处理中断 n 时跳到内存地址 n * 4 处的值, 设 es = 0 有 debug `es: jmp far [] n * 4` 或 masm `jmp dword ptr es:(n * 4)`.

- https://wiki.osdev.org/Interrupt_Vector_Table

```
memory
1024 = 1k = 0x400       -
        real mode Interrupt Vector Table (IVT)
0                       -
```

用 debug 把内存 0:0 开始的 1k 字节打印到文件. 由于输出重定向到了文件, 输入导致的回显都不出现在屏幕上, 按 q 回车退出后查看文件 fff,

```
> out\fff debug
d 0:0 3ff
q
```

- Interrupt descriptor table (IDT) since 80286 protected mode https://alex.dzyoba.com/blog/os-interrupts/
- LIDT 指令可以改变 ivt 的默认位置 0:0, 但很少用 https://wiki.osdev.org/Interrupt_Vector_Table

.       | machine code  | debug.com | masm
-|-|-|-
int3    | 0xcc          | 0xcc      | error A2008: syntax error : int3
int 3   | 0xcd 3        | 0xcc      | 0xcc

### n-in-1 instructions

advantage of 1 instruction: it is atomic.

n | 1 | comments about the 1
-|-|-
(compare and jump)                      | bound                 | exception, slow
(see below)                             | call, ret; int, iret
(see below)                             | ret imm16
push ebp; mov ebp, esp; sub esp, m      | enter m, 0            | slow
(load segment and offset separately)    | lds/les/lfs/lgs/lss
mov esp, ebp; pop ebp                   | leave                 | 2+ μops vs. (leave) 3 μops
dec reg; jnz                            | loop                  | slow

call, ret; int, iret 这些 jump 读取和修改栈.

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
            add sp, 2               add sp, 4               add sp, 4
                                                            popf
            jmp [sp - 2]            jmp far [sp - 4]        jmp far [sp - 6]

    ret 3                   ret far 3
            add sp, 5               add sp, 7
            jmp [sp - 5]            jmp far [sp - 7]

* 2 + 3 = 5, 4 + 3 = 7
* note sp cannot be used for addressing
```

示例: ret n 导致 sp += 2 + n. ret e 导致 sp = sp + 2 + 0xe = 0xffec + 0x10 = 0xfffc

```
debug
-a
1337:0100 mov   ax, 123
1337:0103 push  ax
1337:0104 ret   e
1337:0107
-r
AX=0000 SP=FFEE IP=0100
1337:0100 B82301        MOV AX,0123
-t
AX=0123 SP=FFEE IP=0103
1337:0103 50            PUSH AX
-t
AX=0123 SP=FFEC IP=0104
1337:0104 C20E00        RET 000E
-t
AX=0123 SP=FFFC IP=0123
1337:0123 2A00          SUB AL,[BX+SI]
-q
```

示例: 在 0xf0 处写入 0x123, 修改 sp 令指向 0xf0, 执行 ret 3 导致跳到 0x123, 且 sp = sp + 2 + 3

```
debug
-e f0 23 01
-r sp
SP 00FD
:f0
-a
1337:0100 ret 3
1337:0103
-d f0 l10
1337:00F0  23 01 00 00 00 00 00 00-00 00 00 00 00 00 00 AA
-r
SP=00F0  IP=0100
1337:0100 C20300        RET 0003
-t
SP=00F5  IP=0123
1337:0123 0000          ADD [BX+SI],AL
-q
```

- http://www.phatcode.net/res/223/files/html/Chapter_12/CH12-3.html#HEADING3-73
- http://www.posix.nl/linuxassembly/nasmdochtml/nasmdoca.html#section-A.27
- todo: `leave` = `mov esp, ebp` + `pop ebp`

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

- https://reverseengineering.stackexchange.com/questions/20838/how-the-cmp-instruction-uses-condition-flags

cmp dst, src | cf | zf
-|-|-
dst = src | 0 | 1
dst < src | 1 | 0
dst > src | 0 | 0

### mnemonic a.k.a.s

.|.|.|.
-|-|-|-
fwait, wait     | (xchg ax, ax), nop
sete, setz      | setne, setnz
shl, sal
jae, jnb, jnc   | jnae, jb, jc  | jna, jbe
je, jz          | jne, jnz      | jp, jpe   | jnp, jpo
jge, jnl        | jnge, jl      | jg, jnle  | jle, jng

## x87 and simd

- https://en.wikipedia.org/wiki/X86_instruction_listings

`Pentium+` CPUID

- code path 1. base code path for compatibility with older processors (from either vendor)
- code path 2. optimized Intel code path exploiting SSE4 or AVX
- code path 3. optimized AMD code path exploiting SSE5

```
对并行计算机的分类, 1966, Flynn 分类法
SISD =  Single  Instruction stream  Single  Data stream, 单指令流单数据流
SIMD =  Single  Instruction stream Multiple Data stream, 单指令流多数据流
MISD = Multiple Instruction stream  Single  Data stream, 多指令流单数据流
MIMD = Multiple Instruction stream Multiple Data stream, 多指令流多数据流
```

早期 1 个寄存器保存 1 个整数, 后来有个做法是把多个相同宽度的数合起来放 1 个寄存器里, 1 条指令对它们同时施加操作, 比如 1 个 4 字节寄存器保存 4 个 1 字节整数. 为了区分寄存器里保存的是 1 个还是 4 个整数, 把前者叫 `标量` 后者叫 `向量`. intel 把 simd 说的多数据流实现为向量里的多个分量. 标量和向量的 1 个区别是进位借位, 标量只要 1 个进位向量需要多个进位.

intel cpu 单线程执行效率高, 数据全在缓存里时 intel simd 速度一流; 但它线程少, 内存访问慢, 使用 cpu 的指令流因而有流水线内存锁分支预测等问题, 所以适用范围很窄. intel simd 有 mmx, sse, avx, 后面替代前面, 学 avx 就行了. avx512 始于 2016, 2019 还没有完全支持它的 cpu.

mimd - Intel Xeon Phi<br>
SIMT: Single Instruction, Multiple Threads. gpu 使用 simt.

```
avx512 使用宽度更小的寄存器的方式
- avx2 没有 ymm16, sse 没有 xmm16, 这些名字只在 avx512 里有效
- avx512 的 evex 编码让 avx, avx2 可以使用 ymm16 ~ ymm31, sse 可以使用 xmm16 ~ xmm31

x64 使用宽度更小的寄存器的方式
- rex 前缀启用 sil, dil, bpl, spl, 仅在 x64 有效
- 无 rex 前缀时可使用 ah, bh, ch, dh

zmm0  - ymm0  - xmm0            rax - eax - ax  - al
zmm31 - ymm31 - xmm31           rsi - esi - si  - sil
                                r8  - r8d - r8w - r8b
```

### x87

- https://en.wikipedia.org/wiki/Intel_8087
- http://www.website.masmforum.com/tutorials/fptute/index.html
- masm610guide, Chapter 6 Using Floating-Point and Binary Coded Decimal Numbers
- intel sdm, vol. 1, Chapter 8 Programming with the x87 FPU

1977, Bruce Ravenel 和 John Palmer 设计了栈架构 cpu 和栈寄存器. 8087, 80287, 80387 是浮点协处理器, 80187 推出较晚 (80c187), 本质是 387, 80486dx 内置了浮点处理器, 不再需要协处理器. cpu 读取指令流, 驱动浮点处理器, 浮点处理器执行该指令时 cpu 并行执行其他指令.

x87 mnemonics,

- start with the letter F
- can never have immediate operands
- cannot have processor registers as operands, with the exception of FSTSW

本想写个程序打印内存中的浮点数, 看了 (didn't read it, glanced at it) 这个帖子 https://f.osdev.org/viewtopic.php?t=31357 后彻底不想写了, 还是在调试器里查看浮点数吧. 从 masm610guide Chapter 6 的 Classical-Stack Format 节抄了几句话组成一个程序. 先看如何用 cv 显示浮点数.

```
xxx segment
    assume  ds: xxx ; so masm generates t, not cs: t
    org     256     ; org is necessary whenever you use labels in com file
s:
    fild    t       ; st = [5]. load integer and convert to real10
    fldpi           ; st = [pi, 5]. load pi
    fadd            ; st = [pi + 5]. debug and masm code this as faddp st(1), st(0)
    fstp    t       ; st = []. suffix p means pop
    int     3       ; during this break, check t in cv.exe
    int     20h     ; exit to dos
t   qword   5       ; room for a double precision floating point
xxx ends
    end s

ml -Foout\ dd.msm -Feout\ -AT
cv -cg out\dd.com   调试执行 dd.com. 这会中断在 int 3 处, 看到变量 t 位于 0x113
在命令窗口执行
@                   重绘 code view 屏幕以更新源代码窗口 cs:0x113 处的值
mdrl 0x113 l1       显示变量 t 保存的值 pi + 5. rl = real long = 8 bytes
q                   退出 code view

  File  Edit  Search  Run  Data  Options  Calls  Windows  Help
┌─[3]───────────────────── source1 CS:IP ─────────────────────────┐┌─[7]reg ───┐
│0CAC:0100 9B             WAIT                                    ││ AX = 0000 │
│0CAC:0101 DF2E1301       FILD      QWORD PTR [0113]              ││ BX = 0000 │
│0CAC:0105 9B             WAIT                                    ││ CX = 0000 │
│0CAC:0106 D9EB           FLDPI                                   ││ DX = 0000 │
│0CAC:0108 9B             WAIT                                    ││ SP = FFFE │
│0CAC:0109 DEC1           FADDP     ST(1),ST                      ││ BP = 0000 │
│0CAC:010B 9B             WAIT                                    ││ SI = 0000 │
│0CAC:010C DD1E1301       FSTP      QWORD PTR [0113]              ││ DI = 0000 │
│0CAC:0110 CC             INT       3                             ││ DS = 0CAC │
│0CAC:0111 CD20           INT       20                            ││ ES = 0CAC │
│0CAC:0113 46             INC       SI                            ││ SS = 0CAC │
│0CAC:0116 D57E           AAD       ???                           ││ CS = 0CAC │
│0CAC:0118 48             DEC       AX                            ││ IP = 0110 │
│0CAC:011A 40             INC       AX                            ││ FL = 0202 │
└─────────────────────────────────────────────────────────────────┘│           │
■═[9]════════════════════════ command ═══════════════════════════↓↑│NV UP EI PL│
│Break caused by INT3 in code                                     ↑│NZ NA PO NC│
│>@                                                               ░│           │
│>mdrl 0x113 l1                                                   ░│           │
│0CAC:0113  +8.141592653589793E+000                                │           │
│>q                                                               ↓│           │
└← ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░→╝└───────────┘
 <F8=Trace> <F10=Step> <F5=Go> <F3=S1 Fmt>                               DEC
```

在我运行的 dosbox-x 里 cv 无法显示浮点寄存器, 报告 floating point not loaded. 我就查看了 dosbox-x 的配置文件发现它能禁用 fpu 模拟, 于是禁用. 禁用后没发现 cv 有任何变化, 仍能执行浮点指令, 仍报告 floating point not loaded. 这可能是因为 dosbox 对 x87 的模拟不完整. 禁用 fpu 模拟能影响 debug.

1. 确保 dosbox-x.conf 里是如下设置以启用 fpu 模拟
    ```
    [cpu]
    fpu     = auto
    cputype = auto
    ```
1. 打开 dosbox-x, 执行 debug, 复制下列语句
    ```
    a
    fld1
    fldpi
    fadd
    fstp qword [10b]
    int3


    e 10b 1 2 3 4 5 6 7 8
    g
    d 10b l8
    q

    ```
1. 点击 dosbox-x 的菜单 main > shared clipboard functions > pasting from the clipboard
1. `d 10b l8` 输出如下
    ```
    -d 10b l8
    0DC6:0100                                   8C 16 22 AA FD
    0DC6:0110  90 10 40
    ```
1. 把小端序转为大端序得到数字 `401090fdaa22168c`, 打开 https://gregstoll.com/~gregstoll/floattohex/
1. 把数字粘贴至 Double-precision floating point 的 Hex value, 点 Convert to double, 下方的 Double value 显示 `4.141592653589793`
1. 关闭 dosbox-x
1. 确保 dosbox-x.conf 里是如下设置以禁用 dosbox-x 的 fpu 模拟
    ```
    [cpu]
    fpu = false
    ```
1. 打开 dosbox-x, 执行 debug, 通过 dosbox-x 的菜单粘贴前述 debug 命令
1. `d 10b l8` 输出如下, 表明通过 `e 10b` 写入的内存没有被 fstp 指令修改, 也就很可能未执行 x87 指令
    ```
    -d 10b l8
    0DC6:0100                                   01 02 03 04 05
    0DC6:0110  06 07 08
    ```
1. 关闭 dosbox-x
1. 在 dosbox-x.conf 里启用 fpu 模拟

用 debug 和 cv 调试同一个文件结果也一样: debug 在禁用 fpu 模拟时不修改内存; cv 总是用计算结果修改内存, 也不知道它是怎么算的. 我估计禁用 fpu 模拟时如果程序不在 cv 的调试下运行就不会执行 x87 指令.

根据 wikipedia 8087 的页面, 8087 程序需要在每条指令前插入 wait , 后续的 x87 不需要. 可以看到 debug 不插入 wait 而 masm 遵循前述原则, 在 masm 中,

- cpu 默认值是 `.8086`, x87 默认值是 `.8087`
- 8087 协处理器只能配合 8086 和 80186, masm 遵循这一点, 比如它忽略 `.286` 后面的 `.8087` 并为 `.287` 生成代码<br>
    https://stackoverflow.com/questions/65418457/masm-doesnt-insert-x87-wait-prefixes-with-some-combinations-of-cpu-and-fpu-dire<br>
    预定义符号 `@cpu` 表示代码里定义的 cpu 和 x87 类型, masm 虽然把 287 后面的 8087 当 287, 它的 @cpu 仍会显示代码里定义了 8087 但未定义 287
- 另一个例子. 使用默认的 cpu 并指定 `.287`, masm 插入 wait; 使用 `.286` 并使用默认的 x87, masm 不插入 wait<br>
    masm610guide: if you use the .286 or .386 directive, the compiler assumes that the coprocessor instructions are for the 80287 or 80387 and does not insert the WAIT instruction<br>
- masm 没有与 80187 对应的 x87 类型
- `.386` 放在 `.model` 前面时后续生成 32 位代码, 为生成 16 位代码可以交换次序, 或者指明 `xxx segment use16`
- 总之, 没发现那组 `.8087`, `.287`, `.387`, `.no87` 有任何作用

### simd-mmx

- https://en.wikipedia.org/wiki/MMX_(instruction_set)
- https://www.intel.com/content/dam/www/public/us/en/documents/research/1997-vol01-iss-3-intel-technology-journal.pdf

intel 把无意义单词 mmx 注册了商标. 首字母缩写词不能注册商标 [citation needed], amd 为了捣乱, 把 mmx 解释为 Matrix Math Extensions [citation needed]. 1995, intel 起诉 amd 和 cyrix corp. 误用它的 mmx 商标. amd 和 intel 以如下条件达成和解: amd 承认 mmx 是 intel 的商标; intel 授予 amd 将 mmx 商标用作技术名, 但不能用作处理器名的权利.

疑问:

- intel 啥时候注册的商标? 该网页开头说 mmx 是 intel 1997 随 P5-based Pentium 引入的
- Extensions 缩写为 x 时, 还属于首字母缩写吗?

mmx 寄存器是 x87 寄存器的别名, 它俩共享 8 个寄存器.

- `3DNow!` amd. adding 32-bit floating-point support to SIMD
- `3DNow!+` amd

### simd-sse

https://en.wikipedia.org/wiki/SSE2

- 实现了大部分 mmx 的整数向量操作; mm 寄存器 64 位, xmm 寄存器 128 位
- xmm 是独立寄存器, mm 是 st 的别名
- sse 支持单精度浮点, sse2 支持双精度浮点
- 缓存控制指令, 用来减少处理无限信息流时的缓存污染
- amd 增加 xmm8 ~ xmm15, 仅在 64 位模式下可用, intel 于 2004 也增加了这 8 个
- x87 精度较高, 80 位, 一次处理一个标量; sse2 精度 32/64 位, 一次处理有多个分量的矢量
- 由于兼容, 有可能将现存的 mmx 代码转换为 sse2
- 希望要访问的内存对齐到 16 位
- 使用 mmx 时可能会用到 x87 指令比如 c 函数 pow, 如果没有用 emms 切换状态, 就会损坏寄存器数据; sse2 无此隐患

https://en.wikipedia.org/wiki/SSE3

- work horizontally in a register
- 添加指令 LDDQU 用于减少访问未对齐内存的开销, 并从整体上改善了未对齐加载的性能

https://en.wikipedia.org/wiki/SSSE3

- 添加 14 个助记符表示的 16 条指令, 可用于 64 位 mm 和 128 位 xmm 寄存器, intel 因此说是 32 条指令.

https://en.wikipedia.org/wiki/SSE4

- 54 instructions sse4 = 47 instructions sse4.1 + 7 instructions sse4.2
- `sse4a` amd, 4 sse4 instructions + 4 new sse instructions, intel 不支持.

https://en.wikipedia.org/wiki/SSE5

- amd, competitor to SSE4, replaced by XOP, F16C, FMA3, FMA4

### simd-avx

- https://en.wikipedia.org/wiki/Advanced_Vector_Extensions
- https://en.wikipedia.org/wiki/AVX-512
- https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/x64-architecture

proposed by Intel in March 2008. first supported by Intel Sandy Bridge, Q1 2011; later on by AMD Bulldozer, Q3 2011. new features, new instructions and a new coding scheme.

- 使用 ymm 寄存器时, 传统的 a = a + b 变成了 c = a + b, 两个操作数的值都不会改变
- 不再严格要求对齐
- 支持 128-bit and 256-bit SIMD

## api

### bios

bios, dos 的 api 调用都通过软中断 int, 这是件很扯的事儿. 用户执行 int, 自动保存一些用不上的寄存器, 跳到一个根据中断号算出来的汇编时常量. 用 int 当 api 我能想到的唯一解释是 intel cpu 内生的要占据 1k 内存当跳转表, 这 1k 中的几百字节不用也浪费. 但用 int 也降低了每次 api 调用的速度.

- http://www.techhelpmanual.com/2-main_menu.html
- An Introduction to the PC’s BIOS and into UEFI https://thestarman.pcministry.com/asm/bios/index.html
- https://github.com/philspil66/IBM-PC-BIOS
- Down to the TLP: How PCI express devices talk (Part I) https://xillybus.com/tutorials/pci-express-tlp-pcie-primer-tutorial-guide-1

#### 内存

- https://wiki.osdev.org/Memory_Map_(x86)
- What every programmer should know about memory https://lwn.net/Articles/250967/
- io 设备直接访问内存, 无需执行 cpu 代码 https://stackoverflow.com/questions/3851677/what-is-the-difference-between-dma-and-memory-mapped-io

cpu 可以访问的内存地址范围叫内存地址空间, 空间的大小可以用地址宽度衡量. 实际不一定能访问那么大范围, 比如 8086 segment:offset 能表示的最大地址是 0xffff * 16 + 0xffff = 0x10ffef, 20 位地址线至多能寻址 0xfffff, 又如 x64 的 52 位地址线. cpu 的地址线和数据线也可以连到内存之外的硬件或内存控制器, 如果某个地址连接到只读内存则写操作显然不会生效. 8086 通过共用的 20 位地址总线和 16 位数据总线获取内存的数据, 总线提供啥它就看到啥. 当时 ibm pc 只有 64k 的内存, 据此设计了 1m 地址空间的 pc 规范, 给此空间的 3 个部分取了名字, 设想了用法. intel 和 ibm 都使用 1m 这个数字不大可能是巧合, 不知道是谁配合谁.

```
a    segment:offset        4g       --------------------------------------------------------
 d         hex
  d     ffff:ffff       1088k - 17  ----------------         extended memory
   r                                high  memory area (hma)
    e   ffff:000f  (1m) 1024k -  1  ------------------------------------------------
     s                              upper memory area (uma)                              386
s     s 9000:ffff        640k -  1  ----------------------------------------
 p                                                                              8086
  a     0000:ffff         64k -  1  ----------------     conventional memory
   c                                low   memory area
    e   0000:0000          0        --------------------------------------------------------

0x10000 = 65536 = 64 * 1024 = 64 * 1k = 64k
0xa0000 = 0xa * 0x10000 = 10 * 64k = 640k
0xffff:0xffff = 0xffff0 + 0xffff = (64k - 1) * 17 = 1088k - 17
```

**upper memory area**

640k ~ 1024k 这 384k 是 uma, 指向 rom 和设备的内存, 不指向内存, cpu 访问这些地址时读写都会映射过去, 写对 rom 无效. 这种把内存地址挪作他用的行为叫内存地址映射. 有些非 ibm pc 也采用了类似的内存地址映射, 有些早期 (1950 ~ 1970) 处理器的寄存器也能映射到内存地址. 假设安装了大于 640k 的内存, 大于 640k 的那些由于没有地址而没法访问. 如果寻址大于 1m, 多于 640k 的那部分内存可以分配 1024k 之上的地址, 不会浪费内存, 但总的来说除非内存小于寻址能力否则就会浪费.

ibm 建议 isa 设备映射到下列地址 (以及未列出的 port, irq, dma), 但这全靠自觉, isa 设备可以占用任意的资源 (the full 1m address space). 毫无疑问这会造成资源的冲突和浪费, 后来的即插即用就是要解决这问题.

```
    hex
f0000–fffff     64kb    system rom-bios and rom-basic
e0000–effff     64kb    other use (pcjr cartridges, lim ems)
c8000–dffff     96kb    other use (pcjr cartridges, lim ems)
c0000–c7fff     32kb    video bios rom
b8000–bffff     32kb    video ram. cga, ega, vga text mode; cga low-res
b0000–b7fff     32kb    video ram. mda text mode; cga hi-res
a0000–affff     64kb    video ram. graphics modes
```

- https://wiki.osdev.org/ISA
- https://retrocomputing.stackexchange.com/questions/2979/how-did-the-ibm-pc-handle-multiple-physical-devices-serving-memory-at-the-same-p
- https://retrocomputing.stackexchange.com/questions/3061/who-decides-what-is-the-memory-address-that-the-cga-video-buffer-will-be-mapped
- https://retrocomputing.stackexchange.com/questions/4929/does-an-isa-card-have-a-fixed-memory-address

假设安装了 1m 内存, uma 里没被 isa 映射的地址能访问内存, 被映射的地址无法访问内存, 叫 memory hole.

highlights of https://wiki.osdev.org/Detecting_Memory_(x86)

- How does the BIOS detect RAM?<br>
    by running relevant code from ROM
- reclaim the memory from 0xA0000 to 0xFFFFF?<br>
    almost impossible
- is there also memory hole just below 4GB?<br>
    sure

**high memory area**

segment:offset 能表示的地址范围是 [0, 0x10,ffef]. 8086 的 20 位地址线至多能寻址 0xf,ffff, 多余部分会绕回到开头, 比如 0xffff:0x10 = 0x10000:0 是 21 位, 20 位地址线只能看到 0:0. 1982 年的 80286 有 24 位地址线, 发明了第 2 种内存分段模式, 支持虚拟内存和内存保护, 这时 intel 把这种模式叫保护模式, 把 8086 用的模式叫实模式. 286 在实模式下用 segment:offset 能访问的比 8086 多出的 [0x10,0000, 0x10,ffef] 这 0xfff0 = 65520 字节内存叫 high memory area.

在 286 上运行的 8086 程序如果依赖 20 位地址线造成的绕回就会出错. 286 设计了一条指令控制第 21 条地址线 - a20 - 是否启用, 不启用时第 21 条线总是 0, 就有绕回的效果.

**pci memory hole**

- https://en.wikipedia.org/wiki/PCI_hole

只要使用内存映射就会占据内存地址. 16 位实模式 cpu 拥有 20 位地址线, 能访问 1m 内存地址, 384k 映射给了外设; 32 位保护模式 cpu 拥有 32 位地址线, 能访问 4g 内存地址, 0.5 ~ 1.5g 映射给了外设. 这次的不同之处是,

- 映射的大小不固定了, 384k v.s. 0.5 ~ 1.5g
- 有些 bios 可以改变内存或硬件映射的地址范围

intel 拿出以前的解决方案, pentium pro 的 Physical Address Extension (PAE) 让 ring0 (cpl0) 程序能访问 36 位地址, ring0 基本都是操作系统. 操作系统为了自己方便 (也可能是 cpu 提供不了操作系统需要的特性) 完全控制硬件, 要求硬件厂商提供配套的驱动程序, 为使用 intel 的 pae 需要 x86 和 x64 之外的 pae 版本驱动程序. microsoft 怕麻烦干脆不再支持 pae.

cpu 运行在 64 位模式时可以用 bios 改变硬件映射的地址或者把内存映射到被占据地址之后的地址. 不过意义何在? 64 位地址范围充足, 很难出现内存分配不到地址的情况.

#### 显卡

显示适配器, 图形适配器, 显卡, gpu 基本指同一样东西. 稍微具体一点, gpu 是显卡的主要部分. 列几个显卡常见词汇, 有些是标准有些是显卡型号,

- 早期的显示技术没有统一标准
- 2d 图形显示标准: mda, cga - 1981, ega (video bios) - 1984, vga - 1987, svga, xga - 1990
- Meet the "Super CGA" Cards https://www.youtube.com/watch?v=xNsK_F4JlG4
- TMS34010. Texas Instruments, 1986, the first programmable graphics processor integrated circuit
- 3d 图形处理, 图像渲染, 并行计算: 3dfx voodoo - 1996, nvidia riva 128 - 1997, nvidia geforce 256 (gpu) - 1999
- Testing the 3dfx Voodoo5 9000 https://www.youtube.com/watch?v=_3iHV0NvLPI

`int10h/ah1bh` Get VGA Functionality and State Info http://www.techhelpmanual.com/178-int_10h_1bh__get_vga_functionality_and_state_info.html 该页面有个错误, "Expects: AX 1bH" 里的 ax 应该是 ah. 下面程序用 f 填充了一些 0, 就是因为之前用 ax (al) = 1bh 发现 int 10h 没有写入 es:di.

```
debug
-a
0DC6:0100 xor bx, bx
0DC6:0102 mov di, 120
0DC6:0105 mov ax, 1b00
0DC6:0108 int 10
0DC6:010A int 3
0DC6:010B
-f 120 l10 0
-g

AX=1B1B  BX=0000  CX=0000  DX=0000  SP=FFEE  BP=0000  SI=0000  DI=0120
DS=0DC6  ES=0DC6  SS=0DC6  CS=0DC6  IP=010A   NV UP EI PL ZR NA PE NC
0DC6:010A CC            INT     3
-d 120 l10
0DC6:0120  5A 2A 00 C0 03 50 00 00-10 00 00 00 18 00 00 00   Z*...P..........
-d c000:2a5a l10
C000:2A50                                FF FF 0F 00 00 00             ......
C000:2A60  00 07 04 02 FF 0E 00 00-00 00                     ..........
-q
```

*这时发现 /dos/masm611/binr/debug.exe 用 a 写入 int 20 然后 g 会让 dosbox-x 失去响应. dosbox-x 自带的 z:\dos\debug.exe 没这问题.*

示例

- [bios vga fill](#bios-vga-fill)

#### 集成显卡

- 集成在主板上
- 集成在 cpu 里: amd apu, intel 核芯显卡
- system on chip: apple m, nvidia tegra

从编程的角度独立显卡和集成显卡没有区别.

#### 声卡, 网卡

电脑的声音和图像都是现实的一个窗口, 但和显卡相比声卡要处理的数据少得多, 声卡早已集成在主板上了, 2023 年依然如此. 声卡主要工作是播放声音, 而显卡要生成图像, 图像的分辨率和帧率一直在提高, 还计算物理效果, 现在还用于高性能计算.

### dos

dos 是单任务操作系统, 单任务指所有程序依次执行. 启动 dos 后执行 command.com; 在 command.com 里启动程序后执行该程序; command.com 保留的内存, 硬盘等各种存储都还在, 但不再执行它的代码, 相当于暂停; 程序退出后继续执行 command.com. 多任务有多种可能. 可能是单个 cpu 把时间分成小段, 轮流执行每个段里不同程序的代码; 也可能是多个 cpu 把时间分成小段, 执行不同程序的代码; 也可能是多个 cpu 各自执行不同程序的代码. 不清楚细节.

为维持 dos 正常运行, 程序要解决和它的衔接问题. 连接器确保代码生成的程序能正常启动, 退出时程序要通知 dos 让其继续执行.

#### program

称呼 | 意思
-|-
executable  | 可执行文件. 显然里面存放了 cpu 指令. 往往在操作系统里执行
process     | 进程. 放到到内存打算执行的 executable, 往往有操作系统为其做准备工作; 放到内存但不打算执行则不是 process
program     | 程序. executable or process

dos 在执行 program 时用数据结构 Program Segment Prefix 存储程序状态, psp 类似 CP/M 里的 Zero Page https://en.wikipedia.org/wiki/Program_Segment_Prefix , 非 dos 不一定有 psp http://www.tavi.co.uk/phobos/exeformat.html . 如果可执行文件不大于 (段 - psp - word 0) = 64k - 0x100 - 2 = 65278, 载入内存时放在一个段里就行, com 文件就是这样, 前 0x100 是 psp 后面是可执行文件, 从 0x100 开始执行. 如果文件 > 65278 一个段就放不下了, dos 发明了 mz exe, 这种文件把代码分成好多不大于 64k 的块; 加载时 psp 单独放在第一个段, 其余每个块对应一个段.

program 启动时代码, 栈, 数据段是下列值, 其中 1. seg psp 2. from file header 3. from file header, relocated

-| cs | ds | es | ss | ip | sp | 通用寄存器
-|-|-|-|-|-|-|-
com | 1. | 1. | 1. | 1. | 0x100 | 0xfffe | http://www.fysnet.net/yourhelp.htm
exe | 3. | 1. | 1. | 3. | 2. | 2. | http://www.tavi.co.uk/phobos/exeformat.html

psp 常用于获取程序的命令行参数, 或者叫 command-line tail. 程序开始执行时 ds = es = seg psp, 也有 dos api 用于获取 psp.

```
; 参数会去掉末尾的空白
; psp 0x80        1 byte    number of bytes of command-line tail
; psp 0x81~0xff 127 bytes   command-line tail, terminated by a 0xd
;
; 用 debug 加载文件, 打印其命令行参数
;
; debug 可以加载一个文件并后跟参数, 叫 testfile-parameters. 如下命令
; debug dd.msm -abc -args
; 对 debug 来说参数是 dd.msm -abc -args, 但对 dd.msm 来说参数不包括自己的名字
; debug 启动后把 dd.msm 后面的串拷贝到 0x81 覆盖原来的参数, 拷贝后 0x80 包含正确的值, 参数仍以 0xd 结尾
; 显然新的参数短于老的参数, 所以能看到内存里留存的老参数
; debug 加载文件后把文件大小放在 dx:cx, 若要使用这俩寄存器注意初始值
;
; 将使用 bios 中断打印字符, bios 中断一般都依赖电脑型号
;
; int10h/ax1301h: Display String and Update Cursor (AT/EGA/VGA)
; http://www.techhelpmanual.com/133-int_10h_1301h__display_string_and_update_cursor.html
; AX    1301H
; BH    video page. int10h/ah0fh 可获取, 这里用 0
; BL    video attribute. 不清楚这玩意儿有没有统一的设置, 这里用 7, 可能会跟其他部分的字符不一致
; CX    length of string. byte [psp:0x80]
; DH,DL row,column to start writing. int10h/ah3 获取 Cursor Position, 也可以读取 40:50 或 0:450
; ES:BP address of start of text to write. psp:0x81. 程序启动后 es = psp, 所以无需改动 es

debug dd.msm -args
-d 80 l10
1337:0080  06 20 2D 61 72 67 73 0D-20 2D 61 72 67 73 0D 00   . -args. -args..
-a
1337:0100 mov ax, 1301
1337:0103 mov bx, 7
1337:0106 xor cx, cx
1337:0108 mov cl, [80]
1337:010C mov bp, 40
1337:010F mov ds, bp
1337:0111 mov dx, [50]
1337:0115 mov bp, 81
1337:0118 int 10
1337:011A int 3
1337:011B
-g
 -args
AX=1301  BX=0007  CX=0006  DX=1800  SP=FFEE  BP=0081  SI=0000  DI=0000
DS=0040  ES=1337  SS=1337  CS=1337  IP=011A   NV UP EI PL ZR NA PE NC
1337:011A CC            INT     3
-q
```

dos 提供两个用于退出的函数,

- `dos 1` int21h/ah0, 别名 int20h, 机器码更短. 要求 cs 保存 psp 的段地址
- `dos 2` int21h/ah4ch. 不使用 cs, al 代表返回值
- https://retrocomputing.stackexchange.com/questions/16891/difference-between-int-0x20-and-int-0x21-0x4c
- https://stackoverflow.com/questions/12591673/whats-the-difference-between-using-int-0x20-and-int-0x21-ah-0x4c-to-exit-a-16
- `win32` this is not dos. _ExitProcess@4

示例

- [从 psp 获取程序的命令行参数](#从-psp-获取程序的命令行参数)
- [int 20h](#int-20h)

#### omf, coff, mz, pe

- https://en.wikipedia.org/wiki/Comparison_of_executable_file_formats
- https://en.wikipedia.org/wiki/Relocatable_Object_Module_Format
- https://en.wikipedia.org/wiki/COFF
- https://en.wikipedia.org/wiki/DOS_MZ_executable
- https://en.wikipedia.org/wiki/Portable_Executable

`omf` Relocatable Object Module Format 是对象文件的一种格式, 主要用于在 intel 80x86 上运行的软件, 源于 intel 开发的(when?) Object Module Format, 是 MS-DOS, 16-bit Windows, 16/32-bit OS/2 上最重要的对象文件格式. masm 6.11 生成的 obj 默认 omf, 可以用 -coff 选项生成 coff. masm 不支持 jmp far-pointer 比如 jmp 0ffffh:0, 需要 omf https://stackoverflow.com/questions/32706833/how-to-code-a-far-absolute-jmp-call-instruction-in-masm

`coff` Common Object File Format 是 executable, object code, shared library 的格式, 用于 Unix 系统, 在 Unix System V 里取代了 a.out 格式. 它是 XCOFF and ECOFF 的基础, 很大程度上被 SVR4 的 ELF 取代. coff 及其变种继续用在一些 Unix-like 系统, Microsoft Windows (PE Format), EFI 环境和一些嵌入式开发系统. masm 14 生成 obj 默认 coff, -coff 和 -omf 选项生成对应格式的 obj.

`mz` dos 的 exe 文件格式, 开头的两个字节是 4D 5A, ascii M Z, 是 16 位 exe, 比 com 格式新.

`pe` Portable Executable 格式是 executables, object code, DLLs, FON Font 等文件的格式, 用于 32/64 位 windows. 可以类比 elf in Linux and most other versions of Unix 和 Mach-O in macOS and iOS. 为兼容 msdos 和旧版 windows, pe 保留 mz 头 https://blog.kowalczyk.info/articles/pefileformat.html . https://thestarman.pcministry.com/asm/debug/DOSstub.htm pe 的 mz 头后面是个 16 位 dos 存根程序, 一般显示:

```
(Borland tlink32)   This program must be run under Win32.
(ms link?)          This program cannot be run in DOS mode.
(???)               This program requires Microsoft Windows.
```

#### com 文件

- https://en.wikipedia.org/wiki/COM_file

演变

- Digital Equipment operating systems, 1970s: .COM was used as a filename extension for text files containing commands to be issued to the operating system (similar to a batch file)
- cp/m: executable
- dos: executable

特点

- max size = 65,280 (FF00h) bytes (256 bytes short of 64 KB)
- stores all its code and data in one segment
- entry point is fixed at 0100h

dos 和 cp/m 的 com 文件结构虽然一样但互不兼容. dos 文件包含的是 x86 指令和 dos 系统调用; cp/m 文件包含 8080 指令和 cp/m 系统调用, 特定于机器的程序可能还会有 8085, Z80 指令.

fat binary

- https://en.wikipedia.org/wiki/Fat_binary
- 基本上是把多个功能一样的程序放到一个文件里, 开头的代码选择使用其中一个
- 开头的代码, 即入口代码, 是在几个系统中都有效但功能不同的指令, 比如 `c3 3 1` 在 8080 上是 `JP 103h`, `c3` 在 x86 上是 `ret`

有些 exe 文件会使用 com 扩展名 (dos 4+?). 加载程序查看文件的前几个字节, 如果发现是 exe 就按 exe 执行, 否则才按 com 执行,

- https://retrocomputing.stackexchange.com/questions/14520/how-did-large-com-files-work
- https://github.com/microsoft/MS-DOS/blob/master/v2.0/source/EXEC.ASM#L331

DISKCOMP, DISKCOPY, FORMAT, MODE, MORE, TREE 是以 .com 结尾的 exe, 因为老的 bat 文件可能使用命令的全名, win nt 为兼容这些 bat 就保留了前述 exe 的原名. 执行命令时如果省略扩展名, dos 先找 com 再找 exe, 比如 foo 依次找 `foo`, `foo.com`, `foo.exe`. win nt 环境变量 PATHEXT 可以指定扩展名顺序, 默认仍然是 com 先于 exe.

#### expanded memory

1978 | 1982  | 1985  | 1987    | 1988       | 1989     | 1991       |  1993
-|-|-|-|-|-|-|-
8086 | 80286 | 80386 | ems 4.0 | ms-dos 4.0 | 80376    | xms 3.0    |   pentium
||||                           | emm386.sys | 80486    | ms-dos 5.0
|||||                                       | dpmi 0.9 | emm386.exe

- https://en.wikipedia.org/wiki/Conventional_memory

实模式 640k 内存不够用, 所以出现了几种修改 uma 区域的内存地址映射以增加内存的办法,

.|.|.|.
-|-|-|-
8086 |      real mode | hardware | isa 扩展内存卡占用一块地址
8086 |      real mode | hardware | custom address decoder
8086 |      real mode | hardware | 控制台重定向以释放 uma 里除最后一块 64k 之外的所有块, 使用其地址
286  |      real mode | hardware | 主板芯片组自定义地址解码, 把访问映射到 extended memory
386  | protected mode | software | virtual 8086 mode 里 mmu 把访问映射到 extended memory

384k 的 uma 只能占用一部分, 显然太小于是使用了 `bank switching`. 实现 bank switching 的设备有较大内存, 这些内存不在 cpu 地址空间内; 设备占用地址空间里的一个范围, 叫窗口, 窗口映射到设备的内存; 设备还占用一些端口作控制信号. 用控制信号通知设备调整窗口对应的设备内存就可以通过有限的地址访问较大的设备内存. 比如 8 位地址线总共区分 2 ** 8 = 256 个地址, bank switching 中假设 6 个地址作控制其余 250 个作窗口, 则总共映射 250 * 6 = 1500 个地址.

- http://www.phatcode.net/articles.php?sub=memory
- http://www.phatcode.net/res/218/files/limems40.txt

expanded memory 指通过 lim-ems 接口访问的的内存, 适用于 8086, 8088, 实模式 80286, 4.0 支持至多 32m. 相关名词:

- `lim-ems` lotus/intel/microsoft expanded memory specification
- `emm` expanded memory manager, 实现 ems 定义的 expanded memory 接口的设备驱动
- `ltemm.exe` lo-tech 的 emm

lim-ems 的程序模型是: 任何能映射内存地址的设备从 0xc0000-0xeffff 里取 1 个 0x10000 字节的区域划分成 4 张 16k 大小的物理页, 设备的内存划分成多张 16k 大小的逻辑页. 程序通过 emm 把某个逻辑页对应到物理页, 就可以通过物理页的地址访问逻辑页. 显然同一时间最多 4 张逻辑页对应 4 张物理页.

lim 4.0, chapter 2, WHAT EVERY PROGRAM MUST DO<br>
In order to use expanded memory, applications must perform these steps in the following order:

1. Determine if EMM is installed.
2. Determine if enough expanded memory pages exist for your application. (Function 3)
3. Allocate expanded memory pages. (Function 4 or 18)
4. Get the page frame base address. (Function 2)
5. Map in expanded memory pages. (Function 5 or 17)
6. Read/write/execute data in expanded memory, just as if it were conventional memory.
7. Return expanded memory pages to expanded memory pool before exiting. (Function 6 or 18)

```
; code fragment

; 1. Determine if EMM is installed.
;
; lim 4.0, APPENDIX B
; TESTING FOR THE PRESENCE OF THE EXPANDED MEMORY MANAGER

; THE "OPEN HANDLE" TECHNIQUE
; 这里面的 first_test_for_EMM_err_exit 不知道是不是 first_test_for_EMM_error_exit 的笔误, 我改成后者了

bullet1 proc

; DOS Fn 3dH: Open a File via Handle                Compatibility: 2.0+
; Expects:  AH      3dH
;           AL      Access Mode (0=read, 1=write, 2=both, etc.)
;           DS:DX   address of an ASCIIZ string of a filespec
; Returns:  AX      error code if CF is set to CY, file handle if no error

    mov ax, 3d00h
    mov dx, cs
    mov ds, dx
    mov dx, offset szEmm
    int 21h
    jc  err

; DOS Fn 4400H: IOCTL Query Device/File Flags       Compatibility: 2.0+
; Expects:  AX  4400H
;           BX  file handle  (device or disk file)
; Returns:  AX  error code  if CF is set to CY
;           DX  IOCTL device info (if no error)
; Info: Checks to see if a handle represents a device or a disk file and...

    mov bx, ax          ; file handle returned by int21h/ah3dh
    mov ax, 4400h
    int 21h
    jc  err
    test dx, 10000000b  ; bit 7 set = handle is a device
    jz  err

; DOS Fn 4407H: IOCTL Query Handle Output Status    Compatibility: 2.0+
; Expects:  AX  4407H
;           BX  file handle  (device or disk file)
; Returns:  AX  error code if CF is set to CY
;           AL  output status code (if no error)
;               00H: not ready
;               ffH: ready
; Info: checks to see if a device is ready to receive output.

    mov ax, 4407h
    int 21h
    jc  err
    cmp al, 0ffh
    jne err

; DOS Fn 3eH: Close a File Handle                   Compatibility: 2.0+
; Expects:  AH  3eH
;           BX  file handle
; Returns:  AX  error code if CF is set to CY

    mov ah, 3eh
    int 21h

    stc     ; EMM is present in the system
    ret

err:
    clc
    ret

szEmm   byte 'emmxxxx0', 0
bullet1 endp

; THE "GET INTERRUPT VECTOR" TECHNIQUE
;
; Be sure to use this technique (and not the "open handle technique) if
; your program is a device driver or if it interrupts DOS during file
; system operations.
;
; 1. 用 int21h/ah35h 获取 interrupt vector #67h (地址 hex 0:19c-0:19f, 类型 m16:16)
;   isr 地址保存在 es:bx
;
; 2. 用 es:0xa 开始的 8 字节忽略大小写对比 'emmxxxx0', 如果相同则 memory manager driver 存在
;
;   Since the memory manager is implemented as a character device
;   driver, its program origin is 0000h.  Device drivers are required
;   to have a "device header" located at the program origin.  Within
;   the "device header" is an 8 byte "device name field."  For a
;   character mode device driver this name field is always located at
;   offset 000Ah within the device header.  The device name field
;   contains the name of the device which DOS uses when it references
;   the device.
;
;   If the result of the "string compare" in this technique is
;   positive, the memory manager driver is present.

debug
-a
0DC7:0100 mov ax, 3567
0DC7:0103 int 21
0DC7:0105
-g 105

AX=3567  BX=0004  CX=0000  DX=0000  SP=FFEE  BP=0000  SI=0000  DI=0000
DS=0DC7  ES=C401  SS=0DC7  CS=0DC7  IP=0105   NV UP EI PL NZ NA PO NC
0DC7:0105 0000          ADD     [BX+SI],AL                         DS:0004=00
-d es:a l8
C401:0000                                45 4D 4D 58 58 58             EMMXXX
C401:0010  58 30                                             X0
-q
```

老实说, 看到为使用 lim-ems 而必须打出的 7 连击里第 1 击就如此繁琐我已经不想继续了. 不过... 下面实现步骤 1 ~ 7.

```
; ml -Foout\ dd.msm -Feout\ -AT

NUMBER_OF_PAGES         equ 7
PHYSICAL_PAGE_NUMBER    equ 3

xxx segment
    assume ds: xxx
    org 256
s:

; 1. Determine if EMM is installed.
;
; STANCE 1      THE PROUD DRAGON REPENTS / 亢龍有悔
; of EIGHTEEN DRAGON-SUBDUING PALMS / 降龍十八掌

    call stance1

    mov e1, 1
    jnc fail

    mov dx, offset s11
    mov ah, 9
    int 21h

; 2. Determine if enough expanded memory pages exist for your application. (Function 3)
;
; FUNCTION 3    GET UNALLOCATED PAGE COUNT
; CALLING PARAMETERS
;   AH = 42h
; RESULTS
;   BX = unallocated pages
;   DX = total pages
; STATUS
;   AH = 0 success, otherwise fail

    mov ax, 4200h
    int 67h

    mov e1, 2
    test ah, ah
    jnz fail

    mov ax, bx
    mov si, offset s22 - 3
    call itoa

    mov ax, dx
    mov si, offset s31 - 4
    call itoa

    mov dx, offset s21
    mov ah, 9
    int 21h

; 3. Allocate expanded memory pages. (Function 4 or 18)
;
; FUNCTION 4    ALLOCATE PAGES
; CALLING PARAMETERS
;   AH = 43h
;   BX = num_of_pages_to_alloc
; RESULTS
;   DX = handle, up to 255
; STATUS
;   AH = 0 success, otherwise fail
; FUNCTION 18   REALLOCATE PAGES

    mov ax, 4300h
    mov bx, NUMBER_OF_PAGES
    int 67h

    mov e1, 3
    test ah, ah
    jnz fail

    mov h1, dx  ; save handle

    mov ax, dx
    mov si, offset s41 - 4
    call itoa

    mov dx, offset s31
    mov ah, 9
    int 21h

; 4. Get the page frame base address. (Function 2)
;
; FUNCTION 2    GET PAGE FRAME ADDRESS
; CALLING PARAMETERS
;   AH = 41h
; RESULTS
;   BX = page frame segment address
; STATUS
;   AH = 0 success, otherwise fail

    mov ax, 4100h
    int 67h

    mov e1, 4
    test ah, ah
    jnz fail

    mov b1, bx  ; save seg

    mov ax, bx
    mov si, offset s51 - 4
    call itoa

    mov dx, offset s41
    mov ah, 9
    int 21h

; 5. Map in expanded memory pages. (Function 5 or 17)
;
; FUNCTION 5    MAP/UNMAP HANDLE PAGES
; CALLING PARAMETERS
;   AH = 44h
;   AL = physical_page_number, 0 ~ 3
;   BX =  logical_page_number, 0 ~ NUMBER_OF_PAGES - 1, 0xffff = unmap
;   DX = emm_handle
; STATUS
;   AH = 0 success, otherwise fail

    mov ah, 44h
    mov al, PHYSICAL_PAGE_NUMBER
    mov bx, NUMBER_OF_PAGES - 1
    mov dx, h1
    int 67h

    mov e1, 5
    test ah, ah
    jnz fail

    xor ah, ah
    mov si, offset s52 - 3
    call itoa

    mov ax, bx
    mov si, offset s61 - 4
    call itoa

    mov dx, offset s51
    mov ah, 9
    int 21h

; 6. Read/write/execute data in expanded memory, just as if it were conventional memory.
;
; segment = b1, offset = 16k * PHYSICAL_PAGE_NUMBER

    mov dx, ds  ; save ds
    mov ds, b1
    mov word ptr ds: (4000h * PHYSICAL_PAGE_NUMBER), 0edfeh
    mov ds, dx  ; restore ds

    mov dx, offset s61
    mov ah, 9
    int 21h

; 7. Return expanded memory pages to expanded memory pool before exiting. (Function 6 or 18)
;
; FUNCTION 6    DEALLOCATE PAGES
; Note
; A program must perform this function before it exits to DOS. If it
; doesn't, no other programs can use these pages or the EMM handle.
; This means that a program using expanded memory should trap critical
; errors and control-break if there is a chance that the program will
; have allocated pages when either of these events occur.
; Calling Parameters
;   AH = 45h
;   DX = handle
; STATUS
;   AH = 0 success, otherwise fail

    mov ax, 4500h
    mov dx, h1
    int 67h

    mov h1, 0   ; clear handle even if int67h/ah45h fails
    mov e1, 7
    test ah, ah
    jnz fail

    mov ax, dx
    mov si, offset s71 + lengthof s71 - 2
    call itoa

    mov dx, offset s71
    mov ah, 9
    int 21h

exit:
    int 20h

fail:
    mov dx, h1
    test dx, dx
    jz @f

    mov ax, 4500h
    int 67h
@@:
    mov ax, e1
    mov si, offset s1 + lengthof s1 - 2
    call itoa

    mov dx, offset s1
    mov ah, 9
    int 21h
    jmp exit

b1  word ?
h1  word 0
e1  word 0
s1  byte 'failed at stance  $'
s11 byte 'stance 1         expanded memory ready', 13, 10, '$'
s21 byte 'stance 2       unallocated pages      ', 13, 10
s22 byte '                     total pages      ', 13, 10, '$'
s31 byte 'stance 3                  handle      ', 13, 10, '$'
s41 byte 'stance 4      page frame segment      ', 13, 10, '$'
s51 byte 'stance 5    physical page number      ', 13, 10
s52 byte '             logical page number      ', 13, 10, '$'
s61 byte 'stance 6         using expanded memory', 13, 10, '$'
s71 byte 'stance 7      deallocated handle      $'

stance1 proc
; int21h/ah3dh, get file handle from string of a filespec
    mov ax, 3d00h
    mov dx, cs
    mov ds, dx
    mov dx, offset szEmm
    int 21h
    jc  @f

; int21h/ax4400h, checks to see if a handle represents a device or a disk file
    mov bx, ax          ; file handle returned by int21h/ah3dh
    mov ax, 4400h
    int 21h
    jc  @f
    test dx, 10000000b  ; bit 7 set = handle is a device
    jz  @f

; int21h/ax4407h, checks to see if a device is ready to receive output
    mov ax, 4407h
    int 21h
    jc  @f
    cmp al, 0ffh
    jne @f

; int21h/ah3eh, close a file handle
    mov ah, 3eh
    int 21h

    stc     ; EMM is present in the system
    ret
@@:
    clc
    ret

szEmm   byte 'emmxxxx0', 0
stance1 endp

itoa    proc
; integer to ascii
; ax = integer
; "xxxx strings _____ other strings"
;                si ^
; https://treeniks.github.io/x86-64-simplified/instructions/binary-arithmetic-instructions/div.html

    push bx
    push dx
    mov bx, 10      ; divisor
@@:
    xor dx, dx      ; dx:ax = dividend
    div bx          ; ax = quotient, dx = remainder
    add dl, '0'
    mov [si], dl    ; save to string
    dec si
    test ax, ax
    jnz @b          ; loop if quotient

    pop dx
    pop bx
    ret
itoa    endp

xxx ends
    end s
```

上面程序往 expanded memory 窗口第 3 (从 0 开始) 页写入 0xfe 0xed 并且退出时没有 unmap. 已知 emm 存在; 根据上面程序运行结果知道窗口起始地址是 0xe0000; 每页 16k 则第 3 页起始偏移是 0x4000 * 3 = 0xc000. 下面验证上面的程序是否成功写入.

```
debug
-d e000:c000 l10
E000:C000  FF FF FF FF FF FF FF FF-FF FF FF FF FF FF FF FF
-q

out\dd.com
...
stance 4      page frame segment 57344
...

debug
-d e000:c000 l10
E000:C000  FE ED 00 00 00 00 00 00-00 00 00 00 00 00 00 00
-q
```

这说明程序确实写入了 0xe000:0xc000. 下面验证 em 的逻辑页可以用不同的物理页访问. 先把逻辑页映射到 0xe000:0 即物理页 0, 写入不同于 0xfe 0xed 的 2 个字节, 然后把逻辑页映射到 0xe000:0xc000 即物理页 3, 如果那里的 0xfe 0xed 变成了逻辑页的前 2 字节就说明逻辑页的访问地址变了. 重启 dosbox-x, 执行上面的程序然后进入 debug,

```
> nul out\dd.com

debug
-a
0DC7:0100 mov ax, 4300          ; allocate 1 logical page
0DC7:0103 mov bx, 1
0DC7:0106 int 67
0DC7:0108 mov ax, 4400          ; physical 0 -> logical 0
0DC7:010B mov bx, 0
0DC7:010E int 67
0DC7:0110 mov ax, e000          ; write 12 34 to logical 0
0DC7:0113 mov ds, ax
0DC7:0115 mov [0], word 3412
0DC7:011B mov ax, 4400          ; unmap physical 0
0DC7:011E mov bx, ffff
0DC7:0121 int 67
0DC7:0123 mov ax, 4403          ; physical 3 -> logical 0
0DC7:0126 mov bx, 0
0DC7:0129 int 67
0DC7:012B mov ax, 4500          ; always deallocate when done
0DC7:012E int 67
0DC7:0130 int 3
0DC7:0131
-g 11b

-d e000:0    l4
E000:0000  12 34 00 00
-d e000:c000 l4
E000:C000  FE ED 00 00
-xs
Handle 0000 has 0018 pages allocated
Handle 0001 has 0001 pages allocated

Physical page 00 = Frame segment E000
Physical page 01 = Frame segment E400
Physical page 02 = Frame segment E800
Physical page 03 = Frame segment EC00

   0 of a total  3A3 EMS pages have been allocated
   2 of a total   C8 EMS handles have been allocated
-g 123

-d e000:0    l4
E000:0000  FF FF FF FF
-d e000:c000 l4
E000:C000  FE ED 00 00
-g 12b

-d e000:0    l4
E000:0000  FF FF FF FF
-d e000:c000 l4
E000:C000  12 34 00 00
-g
-xs
Handle 0000 has 0018 pages allocated

Physical page 00 = Frame segment E000
Physical page 01 = Frame segment E400
Physical page 02 = Frame segment E800
Physical page 03 = Frame segment EC00

   0 of a total  3A4 EMS pages have been allocated
   1 of a total   C8 EMS handles have been allocated
-q
```

expanded memory 也可以存放代码, 类似 overlay. 把 obj 或 com 文件读取到或者用 int21h/ax4b03h 把 exe 加载到 expanded memory 然后 far call/jump 过去.

下面查看 int 67h 如何同扩展内存卡交互. 直接跳到 isr #67h 就能看到, 但最好带上真实的参数,

```
debug
-a
0DC7:0100 mov ax, 4300
0DC7:0103 mov bx, 1
0DC7:0106 int 67
0DC7:0108 mov ax, 4500
0DC7:010B int 67
0DC7:010D int 3
0DC7:010E
-t 3
0DC7:0103 BB0100        MOV     BX,0001
0DC7:0106 CD67          INT     67
C401:0004 FE38          ???     [BX+SI]
-u c401:4 l8
C401:0004 FE38          ???     [BX+SI]
C401:0006 45            INC     BP
C401:0007 00CF          ADD     BH,CL
C401:0009 00454D        ADD     [DI+4D],AL
-t
C401:0008 CF            IRET
-t
0DC7:0108 B80045        MOV     AX,4500
-g
-q
```

isr #67h 的第 1 句是 ??? [bx+si], 不知道啥意思. 用 t 执行后应该停在下一句即 6: inc bp 但却停在了 8: iret. 根据 u 显示的反汇编 8 是 7: add bh,cl 的中间, 这啥道理, 0xfe 0x38 干啥的?

```
debug
-e 100 fe 38 11 22 33 44 55 66
-u 100 l8
0DC7:0100 FE38          ???     [BX+SI]
0DC7:0102 1122          ADC     [BP+SI],SP
0DC7:0104 334455        XOR     AX,[SI+55]
0DC7:0107 66            DB      66
-t
IP=0104
0DC7:0104 334455        XOR     AX,[SI+55]
-q
```

执行 0x100: ??? [bx+si] 后 ip = 0x104, 说明 0xfe 0x38 xx xx 是个 4 字节指令? 我怀疑是 dosbox-x 没有模拟扩展内存卡, 对 int 67h 调用直接返回了内部处理结果. 为验证这个想法下面在更精确的模拟器里查看 emm 和扩展内存卡的交互.

#### lim 4.0 on 86box

- 按 /readme/msdos 5.0 on ibmxt on 86box 创建虚拟机
- 从 https://www.lo-tech.co.uk/wiki/LTEMM.EXE 下载 ltemm.zip 解压缩把里面的 ltemm.exe 拷贝到 86box dos 里, 假设是 c:\programs
- 86box dos 的 config.sys 里添加 `device = c:\programs\ltemm.exe`
- 86box settings 里修改下列设置
    ```
    other peripherals
        isa memory expansion
            card 1
                lo-tech ems board
                configure
                    memory size = 512
                    (address = 260h         default)
                    (frame address = e000h  default)
    ```
- 点 ok 关闭 settings, 这会重启 dos

在 dos 里从 int21h/ax3567h 得知 isr #67h 的起始地址是 0xfee:0x49c, 从其代码得知到 iret 长度是 0x43 字节, 用 debug 的 `u fee:49c l43` 得到:

```
0FEE:049C FA            CLI
...
0FEE:04AD 80FC40        CMP AH,40
0FEE:04B0 7235          JB  04E7
0FEE:04B2 80FC5E        CMP AH,5E
0FEE:04B5 7330          JNB 04E7
...
0FEE:04CD FF263000      JMP [0030]
...
0FEE:04DE CF            IRET
```

显然 isr 要求 0x39 < ah < 0x5e, 其余代码只有 1 个 jump 即 jmp [0x30], 那里代码很长. ltemm.zip 里面有源代码以后再看.

#### int 2fh

- INT 2fH: Multiplex Interrupt http://www.techhelpmanual.com/681-int_2fh__multiplex_interrupt.html

`dos 3.0+` 中断 #0x2f 位于 0:0xbc, 也叫 mux interrupt, 是一些 dos 服务. ah 的值叫 mux number, dos 保留 0-0xbf.

有种做法是注册 int 2fh 回调函数, 方式为:

- 用 int21h/ah35h 获取 isr #0x2f, 保存下来
- 用 int21h/ah25h 把 isr #0x2f 替换成你的
- 为你的 isr 选一个 mux number, 在 isr 中,
    - 检查 mux number 即 ah, 若匹配则响应
    - 若不匹配则 far jump 到保存的 isr #0x2f

显然这是个跳转链, 链上陆续判断 ah, 最终执行相应的函数即某个旧 isr #0x2f. 这套流程比挂接其他 isr 多出个选择 mux number. 为不和他人冲突, 执行下列步骤:

- 用 ah = 0xff-0xc0 逐一调用 int 2fh 找出空闲值, 假设是 n
- n 没地方保存, 所以 isr 要对 ah = n, al = 0 返回 al = 0xff 并且设置某个自己定义的标记帮助后续判断
- 调用自己的 isr 时用 ah = 0xff-0xc0 逐一调用 int 2fh 并检查自己定义的标记, 如果匹配则找出了 n

但我不明白这套复杂操作的用意, 因为,

- dos 的 ivt 可以任意修改, 挂接到任意的 int # 都没区别. 你的 isr 反正不是固定地址, 根本没人在意你挂哪
- 既然保留了原来的 isr #0x2f, 那还费事儿找可用的 mux number 干啥? 任选一个, 处理完跳到原来的 isr 不就行了
- 有些中断要求快速处理, 那种 isr 就不适合挂接
- 那套复杂操作显然想实现一种自适应的共存方式, 在不能替换 isr 的场合下应该有用

#### xms

- Overview of Memory-Management Functionality in MS-DOS https://jeffpar.github.io/kbarchive/kb/095/Q95555/
- https://www.phatcode.net/res/219/files/xms30.txt
- `xms` `286` `dos 3.00` eXtended Memory Specification
- `xmm` extended memory manager, 实现 xms 的设备驱动
- `himem.sys` `286` switch between real mode and protected mode. ms-dos 的 xmm, without the optional umb
- `emm386.exe` `386` requires himem.sys. into protected mode. umb and ems emulation in virtual 8086 mode

himem.sys 和 emm386.exe 的很多功能通过在 config.sys 里指定参数来调用,

file | line | means
-|-|-
config.sys      | dos = low     | = no `dos=`. loads dos low. then processes `device[high]=`, `install[high]=`
|| dos = high   | seeks xmm from `device[high]=`, if found && hma is available, loads dos into hma
|| dos = umb    | asks ms-dos to manage umbs. e.g. `dos = high, umb`
|| device =     | loads a driver into conventional memory
|| device = himem.sys /int15=xx | allocates extended memory start from xx
|| device = emm386.exe          | https://techshelps.github.io/MSDN/DNWIN95/HTML/S6827.HTM
|| device = emm386.exe ram=m-n  | seg m - seg n to be used for umbs and ems
|| device = emm386.exe noems    | prevents access to expanded memory
|| devicehigh =                 | loads a device driver into umbs, into conventional on failure and no error is displayed
|| install =                    | loads a tsr into conventional memory
|| installhigh =                | attempts to load a tsr into umbs
autoexec.bat | loadhigh or lh   | loads a program into umbs

himem.sys 挂接 int 2fh 响应 ah 0x43xx, 实现除 umb 外的 xms 功能. emm386.exe 实现 umb 功能即 0x10~0x12. 如果 config.sys 里有 dos=umb 则 emm386.exe 会在 dos 命令提示报告 0 (zero) umbs are available, 此时程序应该通过 dos api 使用 umb. 不清楚 emm386.exe 是否挂接了 int 2fh, 它的功能补充到了 xms api 函数 (称作 control function) 里, 看起来和 int 2fh 无关.

xmm | ah | xms api
-|-|-
himem.sys   | 0                 | Get XMS Version Number
|           | 1/2               | Request/Release High Memory Area
|           | 3/4               | Global enable/disable A20
|           | 5/6               | Local enable/disable A20
|           | 7                 | Query A20
|           | 8(0x88)           | Query Free Extended Memory
|           | 9(0x89)/0xa/0xb/0xf(0x8f) | Allocate/Free/Move/Reallocate Extended Memory Block
|           | 0xc/0xd           | Lock/Unlock Extended Memory Block
|           | 0xe(0x8e)         | Get (Extended) Handle Information
emm386.exe  | 0x10/0x11/0x12    | Request/Release/Realloc Upper Memory Block

xms api 的调用流程是: 确认 xms driver 已安装; 获取 api 地址; 调用 api. 下列代码抄自 xms spec 3.0.

```
debug
-a
0DC7:0100 mov ax, 4300          ; Is an XMS driver installed?
0DC7:0103 int 2f
0DC7:0105 cmp al, 80
0DC7:0107 jne 100               ; fix later
0DC7:0109 mov ax, 4310          ; Get the address of the driver's control function
0DC7:010C int 2f
0DC7:010E mov word [100], bx    ; XMSControl is a far pointer
0DC7:0112 mov word [102], es
0DC7:0116 mov ah, 0             ; Get the XMS driver's version number
0DC7:0118 call far [100]
0DC7:011C int 3 ; ax = xms ver, bx = driver internal rev, dx = 1 hma exists, 0 otherwise
0DC7:011D
-a 107
0DC7:0107 jne 11c               ; fixed
0DC7:0109
-g

AX=0300  BX=0301  CX=0000  DX=0001
DS=0DC7  ES=C3FF  SS=0DC7  CS=0DC7  IP=011C
0DC7:011C CC            INT     3
-q
```

xms 的程序模型是: 不清楚. 可能是读写 hma 以及把内存在 conventional 和 extended 的 4 种组合之间搬运. only 1 program can use hma as 1 block at a time.

todo

first thing first wtf is umb? could be some randomly sized blocks that rely on the address mapping capabilities of the virtual 8086 mode mmu?

- http://www.techhelpmanual.com/826-accessing_upper_memory.html

访问 Upper Memory Blocks (UMBs) 需要下列条件,

- DOS 5.0+
- 386+
- have installed HIMEM.SYS and EMM386.EXE device drivers
- have used DOS=UMB in CONFIG.SYS

`286` `real mode` 主板芯片组自定义地址解码提供 shadow ram, umbpci 内置了很多主板驱动将 shadow ram 用作 umb.

#### dos extender

https://en.wikipedia.org/wiki/DOS_extender 在 32 位操作系统流行前还出现了 dos extender, 基本就是个操作系统, 使用 386, 可以访问 16m 内存, 加载的程序运行于保护模式且可以调用 dos api. 主要用在游戏里.

dos extender 的程序模型是: 程序员编写 32 位代码, 告诉连接器要生成使用 dos extender 的程序并连接 32 位 obj 和 dos extender 提供的 16 位存根程序. 生成的程序开始时执行 16 位存根代码, 代码找到并执行 dos extender, dos extender 初始化保护模式, 接管 32 位程序里的指针和中断, 执行程序的 32 位代码.

有好几种 dos extender, 后面编写使用 glide api 的程序时要用到 dos4gw 所以这里主要介绍它. dos4gw 是收费的 dos4g 为 watcom 定制的免费版, 有功能限制. rational systems 于 1991.7 发布 dos/4g. 一般用 watcom sdk 编写 dos4gw 程序, 下载地址:

- https://openwatcom.org/ftp/install/ open-watcom-c-dos-1.9.exe, 完整安装
- https://github.com/open-watcom/open-watcom-v2/releases/tag/Current-build open-watcom-2_0-c-dos.exe, 完整安装
- https://github.com/open-watcom/open-watcom-1.9/releases<br>
    11.0c, show all 76 assets, core_binw.zip. 这页面把安装包分成了好多部分但分的不对, 有些文件重复有些文件缺失, 到处都找不到 wstub.exe
- https://cmeerw.org/prog/owtools/ wlink.exe, pe 版 exe 不能在 dos 里执行, 没有 wstub.exe

1.9 安装包 84m, 在 dos 里安装后是 200m, 安装后的文件大部分都用不到, 我把它移到 /dos 外面了, 以后用 (watcom) 指代该目录. 使用 dos4gw 的 dos 程序在 (watcom)/docs/lguide.pdf 的 9 The OS/2 Executable and DLL File Formats 里称为 OS/2 32-bit linear executable file format, 缩写是 le. 适用于 dos 的程序在 (watcom)/binw. 简单的程序只需要两个 masm 之外的 dos 文件, open watcom linker wlink.exe 和 dos4gw stub wstub.exe. 新建目录 /dos/watcom, 把 (watcom)/binw 里的 wlink.exe, wstub.exe 拷贝过来. 我拷贝了下列文件,

in binw     | group     | .
-|-|-
wasm.exe    |           | 部分兼容 masm 语法. 生成帮助文件: `> out\wasm wasm -?`
wdis.exe    |           | 反汇编 obj
wdump.exe   |           | 查看 exe
wlink.exe   |           | 启动时读取环境变量 path 里的 wlink.lnk, 没有就不读
|           | dos/32a
dos32a.exe  |           | extender
sb.exe      |           | https://www.javiergutierrezchamorro.com/wp-content/uploads/2013/07/dos32a/html/util/1.html
stub32a.exe |           | stub
|           | dos/4gw   | quiet: 1.97- `set dos4g=quiet`, 2.0x `set dos4g=startupbanner:0`
dos4gw.exe  |           | extender. https://flaterco.com/kb/ow.html section "DOS/4GW replacement"
wstub.exe   |           | stub

关闭 dosbox, 如下修改其配置文件中环境变量的 path, 打开 dosbox,

```
[autoexec]
set path=c:\watcom;c:\masm611\bin;c:\masm611\binr;%path%
```

如果 /dos/watcom 放了 dos4gw.exe, 根据环境变量的 path, dos4gw 程序会使用这个 dos4gw 而不是 dosbox 自带的那个.

wlink 连接的 obj 要求源代码有下列写法,

- `xxx segment 'code'`. 不写 'code' 导致用 dos32a 执行时关闭 dosbox
- `s01 segment 'stack'`. wlink 不把 `s01 segment stack` 当作栈段
- `mov edx, offset msg`. offset is 32-bit, `mov dx, offset msg` gives a wrong pointer

(watcom)/docs/pguide.pdf 的要点,

- 指针

    > 14.3 Addressing<br>
    3a. Converting between pointers and linear addresses.<br>
    Because DOS/4GW uses a zero-based flat memory model, converting between pointers and linear addresses is trivial. A pointer value is always relative to the current segment (the value in CS for a code pointer, or in DS or SS for a data pointer). The segment bases for the default DS, SS, and CS are all zero. Hence a near pointer is exactly the same thing as a linear address: a null pointer points to linear address 0, and a pointer with value 0x10000 points to linear address 0x10000.

- 中断

    > 10 Interrupt 21H Functions<br>
    DOS/4GW uses the following rules to manage registers:

    - 16 位 reg 参数变成相应的 32 位扩展寄存器, 比如 ax -> eax, 返回值放在相应的扩展寄存器
    - segment:16-bit-general 指针参数变成 segment:32-bit-general. dos/4gw 负责拷贝数据和翻译指针, dos 最终收到 segment:16-bit-general
    - dos 返回的 segment:16-bit-general 指针由 dos/4gw 翻译为 selector:32-bit-general 指向原来的位置
    - dos function 如果设置 carry 标志, dos/4gw 把 ax 填零扩展到 eax, 不修改其他寄存器
    - 返回值是 8 位寄存器时 dos/4gw 不碰 32 位寄存器的高 16 位

    > 11 Interrupt 31H DPMI Functions<br>
    dos/4gw 程序运行在 dpmi host 比如 windows 3.1 in enhanced mode, os/2 virtual dos machine, 386max (with debug=dpmixcopy), qemm/qdpmi (with extchkoff) 里时由 dpmi host 而不是 dos/4gw 提供 dpmi 服务.<br>
    用 interrupt 31h 访问 dpmi 服务.<br>
    下面描述的是没有 dpmi host 时由 dos/4gw 和 dos/4gw professional 提供的服务.<br><br>
    11.1 Using Interrupt 31H Function Calls<br>
    只有保护模式的 programs 能用 dpmi function int 31h.

- 存根

    > 7.1.1 The Stub Program

    或者 (watcom)/src/wstub.c

    假设 target.exe 包含 stub, 执行 `target.exe -arg1 arg2` 时会执行 stub 代码, 它从环境变量里的 path 搜索相应的 extender, 找到后用进程 `extender target.exe -arg1 arg2` 替换当前进程

- DOS/4GW fatal error (1012): OUT\DD.EXE is not a WATCOM program

    > 6 The Tenberry Software DOS/4GW DOS Extender<br>
    DOS/4GW is a subset of Tenberry Software’s DOS/4G product. DOS/4GW is customized for use with the Watcom C/C++ package. Key differences are:<br>
    DOS/4GW will only execute programs built with a Watcom 32-bit compiler such as Watcom C/C++ and linked with its run-time libraries.<br><br>
    13.2 DOS/4G Errors<br>
    1012 "\<filename> is not a WATCOM program"<br>
    This message does not occur in DOS/4G, only DOS/4GW and DOS/4GW Professional. Those extenders only support WATCOM 32-bit compilers.

    可能是 dos4gw 检测文件的某个标志, 如果不符合就不执行, 而 ml, wasm, wlink 没有设置这个标志. dosbox 自带的 dos4gw, dos32a, watcom 自带的 dos32a 都能正常执行它. 连接 dos32a stub 也可以正常执行, 命令是 `wlink file out\dd format os2 le option quiet, osname='DOS/32 Advanced DOS Extender (LE-style)', stub=stub32a.exe`, osname 抄自 (watcom)/binw/wlsystem.lnk. dos32a 可以内嵌在程序里从而省略存根直接执行, 方法是在 wlink 的命令里把 `stub=stub32a.exe` 改为 `stub=dos32a.exe`, 显然这样得到的程序会更大

下面是简单的 dos4gw 程序.

```
; 没看出以下两条汇编的 obj 有啥区别 (未对比二进制)
; ml -nologo -Foout\ dd.msm -c
; wasm dd.msm -e -fo=out\ -zq
;
; wlink file out\dd format os2 le option quiet, osname=look/here
;              out\dd   This is a look/here executable
;       dos4gw out\dd   DOS/4GW fatal error (1012): OUT\DD.EXE is not a WATCOM program
; z:bin\dos4gw out\dd   hello, world
;
; wlink file out\dd format os2 le option quiet, osname=DOS/4G, stub=wstub.exe
;              out\dd   DOS/4GW fatal error (1012): C:\OUT\DD.EXE is not a WATCOM program
; z:bin\dos4gw out\dd   hello, world

.386

xxx segment 'code'
s:
; ds already holds the appropriate value
    mov edx, offset msg
    mov ah, 9
    int 21h

    mov ax, 4c00h
    int 21h

msg byte 'hello, world', 13, 10, '$'
xxx ends

s01 segment 'stack'
    dword   64 dup (?)
s01 ends
    end s
```

(watcom)/docs/pguide.pdf 里 "The segment bases for the default DS, SS, and CS are all zero" 说的是 cs, ds, ss 保存的 selector 对应的 descriptor 里的段基址是 0. cs, ds, ss 保存的不是 0 而是 selector.

- `segment selector` selects a segment descriptor from segment descriptor table
- `segment descriptor` describes the address, size, some other messy stuff of a segment
- `gdt`, `ldt` table (array) of segment descriptors
- `gdtr` a register holding the address and size of the gdt
- `ldtr` a register holding a segment selector that points to the ldt descriptor in the gdt

```
; 16-bit segment selector
; 0~ 1  requested privilege level (rpl)
;    2  0 = gdt, 1 = ldt
; 3~15  index. index * 8 + base from gdtr or gdt = descriptor in gdt or ldt
;
; ml -Foout\ dd.msm -c
; wlink file out\dd format os2 le option quiet, stub=wstub.exe

.386

LOG_SEG macro arg1
    mov     eax, arg1
    mov     esi, offset arg1&1 + lengthof cs1 - 3
    call    itoa
endm

xxx segment 'code'
s:
    LOG_SEG cs
    LOG_SEG ds
    LOG_SEG es
    LOG_SEG fs
    LOG_SEG gs
    LOG_SEG ss

    mov edx, offset cs1
    mov ah, 9
    int 21h

    mov ax, 4c00h
    int 21h

cs1 byte 'cs      ', 13, 10
ds1 byte 'ds      ', 13, 10
es1 byte 'es      ', 13, 10
fs1 byte 'fs      ', 13, 10
gs1 byte 'gs      ', 13, 10
ss1 byte 'ss      ', 13, 10
    byte '$'

itoa    proc
; integer to ascii
; eax = integer
; "xxxx strings _____ other strings"
;               esi ^

    push ebx
    push edx
    mov ebx, 10     ; divisor
@@:
    xor edx, edx    ; edx:eax = dividend
    div ebx         ; eax = quotient, edx = remainder
    add dl, '0'
    mov [esi], dl   ; save to string
    dec esi
    test eax, eax
    jnz @b          ; loop if quotient

    pop edx
    pop ebx
    ret
itoa    endp
xxx ends

s01 segment 'stack'
    dword   64 dup (?)
s01 ends
    end s

C:\>dos32a out\dd
DOS/32A -- Protected Mode Run-time  Version 7.2
Copyright (C) Supernar Systems, Ltd. 1996-2002
cs  2104
ds  2096
es   104
fs  2112
gs     0
ss  2096

C:\>z:bin\dos4gw out\dd
DOS/4G Protected Mode Run-time  Version 2.01a
Copyright (c) Tenberry Software, Inc. 1996
cs   416
ds   424
es    40
fs     0
gs    32
ss   424
```

这才注意到 dos/4g, dos/32a 把 selectors 放在 gdt 而不是 ldt.

调试 dos/4g 程序需要 watcom 的 wd.exe. 拷贝到 /dos/watcom 启动时发现它依赖一些文件, 首次运行提示 "missing debugging information processor files", 这是调试信息文件, 在 (watcom)/binw 很快发现 codeview.dip, dwarf.dip, watcom.dip. dip 应该就是 debugging information processor. 我用默认的 dwarf 类型所以只拷贝 dwarf.dip. 再执行 wd 就会报告缺少的文件, 依次是 madx86.mad, cpp.prs, wd.dbg, setup.dbg, colour.dbg, default.dbg, wdkeys.dbg, owvkeys.dbg, vikeys.dbg, nwvkeys.dbg, cvkeys.dbg. prs = expression syntax file, dbg 是文本格式的配置文件. 从 (watcom)/binw 拷贝上述文件到 /dos/watcom. 打开 wd 有对话框报错 cannot load expression language, 但不知道原因比如是否缺文件, 关闭对话框也能继续. wd 的内置帮助依赖 wd.ihp, 内容和 (watcom)/docs/wd.pdf 一样.

wd 必须从菜单选择保存配置才会保存. 我没有保存到新文件而是直接修改了 cvkeys.dbg, default.dbg 的相应部分, 如下

- cvkeys.dbg
    ```
    set macro all F3 {
        if ( dbg$src ) {
            display assembly;
            display source      /close
        } else {
            display assembly    /close;
            display source
        }
    }
    ```
- default.dbg
    ```
    display assembly    /close  0,0,10000,4992
    display source      /open   0,0,10000,4992
    display register    /open   0,4992,10000,2496
    display fpu         /close  0,4992,10000,4160
    display memory      /open   0,7488,10000,2496

    rem display all         /close
    rem (and rem/delete all other display statments)

    hook sourceinfo {
        rem display locals; display source
    }
    hook assemblyinfo {
        rem display register; display assembly
    }
    ```

(watcom)/docs/wd.pdf,

> 2 Preparing a Program to be Debugged<br>
    To produce an executable that has debugging information, you need to:<br>
    1. specify the correct compiler options when you compile, and<br>
    2. specify the correct linker options when you link.

> 12.1.2 Debugging DOS/4G(W) 32-bit DOS Extender Applications

- dos4gw.exe or dos4g.exe, in dos path environment variable
- rsi.trp, rsihelp.exp in dos path environment variable or specify full path
- wd /trap=rsi
- example: `wd /trap=rsi hello` or
    ```
    set wd=/trap#rsi
    wd hello
    ```

所以在拷贝 rsi.trp, rsihelp.exp 之后可以用 wd 调试 dos/4g 程序. std.trp 用于调试一般程序.

```
; ml -Zi -Foout\ dd.msm -c
; -or-
; wasm dd.msm -d2 -e -foout\ -zq
;
; wlink debug all file out\dd format os2 le option quiet, stub=wstub.exe
; wd -trap=rsi out\dd

.386

xxx segment 'code'
s:

; 31~24: 0            15: P flag
; 19~16: undefined     14~13: DPL
;  7~ 0: 0               12: S flag
;                          11~8: segment type
; 0000 0000 ???? uuuu ???? ???? 0000 0000
;              20: software-available bit in the descriptor
;             21: L flag
;            22: D/B flag
;           23: G flag

    mov eax, cs     ; 0x1a8
    lar eax, eax    ; 0xcf9a00  = 0000 0000 1100 1111 1001 1010 0000 0000
    mov eax, ds     ; 0x1b0
    lar eax, eax    ; 0xcf9200  = 0000 0000 1100 1111 1001 0010 0000 0000
    mov eax, es     ; 0x28
    lar eax, eax    ; 0x9200    = 0000 0000 0000 0000 1001 0010 0000 0000
    nop

; http://www.techhelpmanual.com/777-int_2fh_1686h__detect_int_31h_dpmi_services.html
;
; INT 2fH 1686H: Detect INT 31h DPMI Services       Compatibility: Win 3.x
; Expects:  AX 1686H
; Returns:  AX 0000h = INT 31H (DPMI) services are available
;              else  = not available
;    Note:  The DPMI spec describes this fn differently.  It says INT 2fH
;           AX=1686H is a way to determine the current CPU operating mode.
;           If AX=0000H on return, then you can assume protected mode.
;           Otherwise, the CPU is in either Real Mode or Virtual 86 Mode.
;
;           I'm not sure who wins the INT 2fH API war.

    mov ax, 1686h
    int 2fh
    nop         ; ax = 0x1686 wtf? not in Win 3.x? it's surely in protected mode here

; INT 31H 0400H: Query DPMI Version                 Compatibility: DPMI 0.9+
; Expects:  AX  0400H
; Returns:
;   CF  NC (this fn always succeeds)
;   AH  DPMI major version
;   AL  DPMI minor version; e.g AX=030aH means version 3.10
;   BX  info flags, see below
;       bit  mask
;         0  0001H 1=host is 32-bit implementation
;                  0=host is 16-bit
;         1  0002H 1=returns to real mode for ints
;                  0=returns to Virtual 86 mode for ints
;         2  0004H 1=virtual memory supported; 0=not
;   CL  processor type:
;       02H = 80286
;       03H = 80386
;       04H = 80486
;       05H = Pentium
;       >5  = reserved for future Intel CPUs
;   DH  current value of virtual master PIC base interrupt
;   DL  current value of virtual slave PIC base interrupt

    mov ax, 400h
    int 31h
    nop

; EAX:0000005A EBX:00000003 ECX:00000004 EDX:00000870 C:  0
; ah = 0, al = 0x5a = 90. dpmi version = 0.90
; bx = 0b11. virtual memory not supported, returns to real mode for ints, host is 32-bit
; cl = 4. 80486
; dh = 8, dl = 0x70

; INT 31H 0500H: Query Free Memory Information      Compatibility: DPMI 0.9+
; Expects:  AX      0500H
;           ES:DI   (or ES:EDI) sel:off of 48-byte buffer to receive info
; Returns:  CF      NC (this fn always succeeds)
;           ES:DI   buffer contains returned info
; DPMI 1.0 users should use INT 31H 050bH instead.

memInfo_t struct
    lAvailBytes     dword        ?  ;  +0    4  largest free block, in bytes
    lUnlockedPgs    dword        ?  ;  +4    4  pages available if left unlocked
    lLockedPgs      dword        ?  ;  +8    4  pages available if locked
    lTotLinPgs      dword        ?  ; +0cH   4  linear address space size, in pages
    lTotUnlkPgs     dword        ?  ; +10H   4  number of unlocked pages
    lTotFreePgs     dword        ?  ; +14H   4  number of free pages
    lTotPhysPgs     dword        ?  ; +18H   4  number of physical pages
    lFreeLinPgs     dword        ?  ; +1cH   4  free linear address space, in pages
    lTotSwapPgs     dword        ?  ; +20H   4  size of page swapping file, in pages
    res             dword 3 dup (?) ; +24H  12  (reserved)
memInfo_t ends                      ;       48  size of this structure

    mov sel0, es
    mov ax, cs
    mov es, ax
    mov edi, offset memInfo
    mov ax, 500h
    int 31h
    mov es, sel0

; 0x004C503E: 00 80 B3 00 38 0B 00 00 38 0B 00 00 90 0E 00 00
; 0x004C504E: 38 0B 00 00 3B 0B 00 00 90 0E 00 00 3B 0B 00 00
; 0x004C505E: FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF

    mov ax, 4c00h
    int 21h

sel0    word        ?
memInfo memInfo_t   <>
xxx ends

s01 segment 'stack'
    dword   64 dup (?)
s01 ends
    end s
```

下面验证 dos4gw 程序的 cs 段基址确实是 0.

```
; ml -Zi -Foout\ dd.msm -c
; wlink debug all file out\dd format os2 le option quiet, stub=wstub.exe
; wd -trap=rsi out\dd

.386

xxx segment 'code'
s:
    mov     eax, cs             ; this is in fact movzx
    call    selectorToDescriptorAddr
    call    baseFromDescriptorAddr

; in debugger
; ebx holds the segment base from the selector's descriptor
; which is indeed 0

    call    loadSegmentLimit    ; fill ebx
    lsl     ecx, eax            ; ebx = ecx is expected in debugger

    mov     ax, 4c00h
    int     21h

selectorToDescriptorAddr proc
; in    eax = selector
; out   edx = address of descriptor
;
; gdtr = 32-bit base + 16-bit limit (in 64-bit mode base = 64 bits)
; but when saved to memory it becomes 16-bit limit + 32-bit base
;
; selector = 13-bit index + 1-bit ti + 2-bit rpl

    sub     esp, 8          ; padding: 2-byte, gdtr: 2-byte limit + 4-byte base
    sgdt    [esp + 2]
    test    eax, 4
    jnz     use_ldt

; use gdt

    mov     edx, eax
    and     edx, 0fff8h     ; clear the upper 16 and lower 3 bits
    add     edx, [esp + 4]  ; edx points to descriptor in gdt
    jmp     done

use_ldt:
; when ti of selector = 1
; 1. get index from   ldtr  , find    ldt     from gdt
; 2. get index from selector, find descriptor from ldt

    xor     edx, edx
    sldt    dx
    and     dx, 65528       ; clear the lower 3 bits
    add     edx, [esp + 4]  ; edx points to ldt descriptor in gdt

    push    ebx
    call    baseFromDescriptorAddr  ; ebx holds segment base from ldt descriptor
    mov     edx, eax
    and     edx, 0fff8h
    add     edx, ebx        ; edx points to selector's descriptor in ldt
    pop     ebx

done:
    add     esp, 8
    ret
selectorToDescriptorAddr endp

baseFromDescriptorAddr:
; in    edx = address of descriptor
; out   ebx = segment base from descriptor
;
; 8-byte descriptor in 32-bit mode
; byte      bits    meaning
; 0, 1      0~15    limit    0~15
; 2, 3      0~15    base     0~15
; 4         0~7     base    16~23
; 5         0~7     type, s, dpl, p
; 6         0~3     limit   16~19
; 6         4~7     avl, l, d/b, g
; 7         0~7     base    24~31

    push    ecx
    movzx   ebx, word ptr [edx + 2] ; ebx = base 15~ 0

    movzx   ecx, byte ptr [edx + 4] ; ecx = base 23~16
    shl     ecx, 16
    add     ebx, ecx                ; ebx = base 23~ 0

    movzx   ecx, byte ptr [edx + 7] ; ecx = base 31~24
    shl     ecx, 24
    add     ebx, ecx                ; ebx = base 31~ 0

    pop     ecx
    ret

limitFromDescriptorAddr proc
; in    edx = address of descriptor
; out   ebx = segment limit from descriptor

    push    ecx
    movzx   ebx, word ptr [edx + 0] ; ebx = limit 15~0
    movzx   ecx, byte ptr [edx + 6] ; ecx = xxxx + limit 19~16
    shl     cl, 4                   ; ecx = limit 19~16 + 0000
    shl     ecx, 12
    add     ebx, ecx                ; ebx = limit 19~0

    test    byte ptr [edx + 6], 80h ; g d 0 avl limit19~16
    jz      @f                      ; g = 0, limit is in bytes

    shl     ebx, 12 ; g = 1, limit is in 4kb pages: (limit << 12) | 0xfff
    add     ebx, 0fffh
@@:
    pop     ecx
    ret
limitFromDescriptorAddr endp

loadSegmentLimit:
; in    eax = selector
; out   ebx = segment limit from descriptor
; same as lsl

    call    selectorToDescriptorAddr
    call    limitFromDescriptorAddr
    ret
xxx ends

s01 segment 'stack'
    dword   64 dup (?)
s01 ends
    end s
```

ml 用的 dos extender 是 dosxnt.exe, 网上找不到资料.

#### dpmi

- ROLL YOUR OWN DOS EXTENDER
    - PART I  https://jacobfilipp.com/DrDobbs/articles/DDJ/1990/9010/9010a/9010a.htm
    - PART II https://jacobfilipp.com/DrDobbs/articles/DDJ/1990/9011/9011f/9011f.htm
- https://www.bttr-software.de/forum/board_entry.php?id=16594
- https://komh.github.io/os2books/gg243731/, DOS Protected Mode Interface
- https://www.phatcode.net/res/262/files/dpmi09.html
- `funny` https://virtuallyfun.com/2011/08/02/some-history-on-dpmi/

在 dos extenders 几年后出现了 2 个 dos extender 接口规范, vcpi 和 dpmi. dpmi 较常用, 它把提供接口的程序叫 host, 使用接口的程序叫 client, 把 dos extender 算作 client. dpmi 认为程序既可以直接调用 dpmi 接口也可以通过 dos extender 使用 dpmi 功能, 并且 dos extender 要在 host 缺失时充当 host.

dos/4g, dos/32a 是程序执行时才启动, 程序退出时随之退出. dosbox-x 的 z:\bin\cwsdpmi.exe 可以驻留内存, 这就可以在 debug 里调用唯一的实模式 dpmi service.

https://github.com/TritonDataCenter/sdcboot/blob/master/freedos/doc/cwsdpmi/cwsdpmi.doc

- `cwsdpmi` terminate and stay resident FOR A SINGLE DPMI PROCESS
- `cwsdpmi -p` terminate and stay resident until you remove it. can be loaded into UMBs with LH
- `cwsdpmi -u` unload the TSR
- `cwsdpmi -sc:\cwsdpmi.swp` virtual memory swap file using full disk/directory syntax
- `cwsdpmi -s-` disable virtual memory. must be the last option on the command line since all characters after -s will be treated as the swap file name

```
rem INT 2fH 1687H: Get Real-to-Protected Mode Switch Address
rem Returns: AX 0000h = successful
rem             else  = no DPMI host present

C:\>debug
-a
0DC7:0100 mov ax, 1687
0DC7:0103 int 2f
0DC7:0105
-g 105

AX=1687  BX=0000  CX=0000  DX=0000  SI=0000  DI=0000
DS=0DC7  ES=0DC7  SS=0DC7  CS=0DC7  IP=0105
0DC7:0105 0000          ADD     [BX+SI],AL
-q

C:\>cwsdpmi

C:\>debug
-a
1899:0100 mov ax, 1687
1899:0103 int 2f
1899:0105
-g 105

AX=0000  BX=0001  CX=0004  DX=005A  SI=0006  DI=117C
DS=1899  ES=082A  SS=1899  CS=1899  IP=0105
1899:0105 A5            MOVSW
-q

rem ax = 0, success
rem bx bit 0 = 1, 32-bit programs are supported
rem cl = 4, 486
rem dx = 0x5a, dpmi version 0.90
rem si = 6, 6 of 16-byte paragraphs = 0x60 needed for dpmi host private
rem es:di entry address to call to enter protected mode

C:\>cwsdpmi -u
CWSDPMI V0.90+ (r7) Copyright (C) 2010 CW Sandmann  ABSOLUTELY NO WARRANTY
```

dpmi 的程序模型是: 调用从 dpmi host 获取的切换到保护模式的函数, 创建指向 32 位代码段描述符的 selector, far jump 到 32 位代码以更新 selector.

- int2fh/ax1687h 返回的函数做这些事儿: 把 cs, ds, es, ss 替换为 selector, 段基址是实模式下相应地址的线性地址, 即段左移 4 位和偏移相加 (段的偏移是 0), cs 是 16 位代码, ds, es, ss 是 32 位数据, fs, gs 替换为 0
- int31h/ah0 创建 descriptor 及相应的 selector
- lar 获取 cs 保存的 selector 的 access rights, 将其高字节从 0 起第 6 位改为 1, int31h/ah9 把改动保存到 descriptor
- selector 对应的基址在满足 base + offset = linear address of start of 32-bit code 的前提下可以任选, offset 就是跳转后第 1 条指令的偏移

从 debug 里调用 int2fh/ax1687h 返回的函数会让 dos 类似死机, 应该是不能从 debug 里切换到保护模式, 所以只能从程序里调用. 一开始想生成 16 位 com, 给 fn 的 ax 传 0 表示要执行 16 位代码, 执行发现 cwsdpmi 报告 `16-bit DPMI unsupported.` 那只能混合 16 和 32 位代码. 我怀疑 wlink 能干这事儿, 但现在就想用 masm 的 link 生成 com.

- 不明白什么叫 "16-bit DPMI unsupported". 进入 16 位保护模式后可以调用一些 dpmi 函数, 算 supported 还是 unsupported?
- 代码要分别定义 16 和 32 位段不能合并, 否则 `fatal error L1123: XXX : segment defined both 16- and 32-bit`
- 从 16 位段跳到 32 位段是 `intersegment jump` 即 far jump, `error A2107: cannot have implicit far jump or call to near label`, 那只能 jmp far m16:32. 只要线性地址正确也可以 jmp far m16:16, cpu 用 0 填充 offset 的高 word
- 代码可以定义多个段, 这些段里标签的偏移都相对于所在的段. 但 com 文件只生成 1 个段, 代码使用其他段的标签需要它的段和偏移, 段的值取不到: `fatal error L1127: far segment references not allowed with /TINY`, 所以从 16 位段跳到 32 位段时要根据段的结尾计算下一个段的起始地址
- 16 位段可以用 32 位寄存器, 因为是 32 位 cpu 在执行 16 位代码

wd 可以调试保护模式程序, 可能能调试 cwsdpmi 程序, 而我想用 dosbox-x debugger. 查看 /readme/dosbox-x debugger 以了解如何使用. 调试器的 gdt 命令打印类似下面的内容:

```
GDT Base:0000D3EE Limit:00000087
0000: b:00000000 type: 00 parbg
      l:00000000 dpl : 0  00000
```

知道 0000 = selector index, b = base, l = limit. type 和 parbg 是啥? 根据 https://dosbox-x.com/doxygen/html/debug_8cpp_source.html line 371, 没看明白. 那里使用了 desc.saved.seg.(p, avl, r, big, g), 分别是啥? desc.saved.seg 的类型 S_Descriptor 定义在 https://dosbox-x.com/doxygen/html/cpu_8h_source.html line 261, 没有注释.

- type 有 9, b, 12, 1a 等, 不明白啥意思. 0x12 和 0x1a 是 5 位数字, intel 的 type 是 4 位
- ldt 命令列出的条目第 1 项居然不是 0 而是 4. 多次调用 ldt 列出的内容也不一致
- selinfo 命令列出的内容经常出错
- intel sdm, vol.3, Figure 3-8. Segment Descriptor 有部分解释,
    ```
    p       segment present
    avl     available for use by system software
    r       readable?
    big     d/b. 很麻烦, 基本上 0 = 16-bit segment, 1 = 32-bit
    g       granularity
    type    segment type
    ```

用 cwsdpmi 进入保护模式后 int21h/ah9 输出大块错误内容, 试了几种改动都解决不了, 网上搜了好几天才找到 2 条可能相关的语句. 我仍不知道 cwsdpmi 能否能正常调用 int21h/ah9, 完全有可能是我的调用方式或前置条件不对.

- https://www.japheth.de/ > downloads > dos tools > file > hxrt > hxrt216.zip > hxrt.txt
    ```
                DOS API        alloc linear
    host     translation   memory at 0x400000   comment
    -------------------------------------------------------------------
    CWSDPMI    No             No                v5
    ```
- https://github.com/brltty/locktones/blob/master/djgpp/dpmi/cwsdpmi.doc
    > "Interrupt 0x??"<br>
    Your application tried to call an interrupt from protected mode which normally shouldn't be called (something like a data pointer).
- `quick look` https://www.delorie.com/djgpp/v2faq/faq18_13.html

下面的示例用命令行参数决定使用 0 或 "32 位代码起始位置的线性地址" 做基址, 参数见代码或后面的执行示例.

```
; ml -Foout\ dd.msm -Feout\ -AT

.386

s16 segment use16
    assume  ds: s16
    org 256
s:
    mov ax, 1687h
    int 2fh
    test ax, ax
    jnz failDpmiHost

; seek the first non-space char in command line args

    cmp byte ptr ds:80h, 0  ; has arg?
    je  execArgsTaken

    mov si, 81h     ; ds:si points to char
@@:
    lodsb           ; [si++] -> al
    cmp al, ' '
    je  @b

    sub al, '0'
    mov execArg, al

execArgsTaken:

; prototype of fn:
; ax    0000h = you'll be running as a 16-bit application
;       0001h = you'll be running as a 32-bit application
; es    the segment of the memory you're be supplying to dpmi host
;       if si was 0 after int 2fh 1687h, then es is ignored.
; return:
; cf set (cy) if switch to protected mode failed, and ax is a dpmi error code
; cs = selector for your code  segment (64k limit)
; ss = selector for your stack segment (64k limit)
; ds = selector for your data  segment (64k limit)
; es = selector for your program's psp (256-byte limit)
; fs = 0 (on 80386+ cpus)
; gs = 0 (on 80386+ cpus)
; psp:002e points to your copy of the dos environment
; to exit from protected mode, call int21h/ah4ch

    mov fn + 0, di
    mov fn + 2, es

; linear address of next segment = mix(this seg, this size, alignment)
; the segment alignment in this sample code is para = 16 bytes

    xor ebx, ebx
    mov bx, s16end
    add bx, 15
    shr bx, 4       ; bx now holds seg next-segment without relocation
    mov ax, cs      ; cs = seg this-segment, relocated
    add bx, ax      ; bx now holds seg next-segment, relocated
    shl ebx, 4
    mov s32start, ebx

; dpmi host needs some 16-byte blocks. i've heard to shrink memory before
; allocating, but also heard that shrinking then allocating is usually done
; in tsrs. ultimately, i'm not sure whether to shrink then allocate in a
; com program. com takes all memory and sets ss:sp = cs:0xfffe, so i reserve
; cs + 0x1000 (seg value) for dpmi host.

    mov ax, cs
    add ax, 1000h
    jc  failHostMem
    mov bx, ax      ; is ax + si < 0xffff?
    add bx, si      ; this is just a rough estimate
    jc  failHostMem
    mov es, ax

; cwsdpmi says: 16-bit DPMI unsupported.
; so this program was written with 32-bit dpmi in mind.

    mov ax, 1       ; 32-bit dpmi
    call dword ptr fn

; on success, protected mode with 16-bit code segment starts here

; in dosbox-x debugger, selinfo es shows
; ES: b:00012EC0 type:12 parbg
;     l:0000FFFF dpl : 3 10000
; clearly it has a limit of 0xffff = 64k, not 256

    jc failPm

; int31h/ax0: allocate ldt descriptors
; last time i tried, int31h/ax2 returns a selector whose access rights cannot be set to code type

    mov cx, 1

    mov ax, 0
    int 31h
    mov csel, ax

    mov ax, 0
    int 31h
    mov dsel, ax

    mov ax, 0
    int 31h         ; base of 0, in order to visit the gdt
    mov fs, ax      ; save to fs

    jc  failInPm

; int31h/ax9: set descriptor access rights
; load access rights from cs, ds then set d/b bit to 1
; do this first, then let int31h/ax8 handle the other bits

    mov ax, 9

    mov cx, cs
    lar cx, cx
    shr cx, 8
    or  ch, 1000000b
    mov bx, csel
    int 31h

    mov cx, ds
    lar cx, cx
    shr cx, 8
    or  ch, 1000000b
    mov bx, dsel
    int 31h

    mov bx, fs
    int 31h

; int31h/ax7: set segment base address

    mov ax, 7

    xor cx, cx
    xor dx, dx
    mov bx, fs
    int 31h

    cmp execArg, 0
    je  @f

    mov ecx, s32start
    shr ecx, 16
    mov dx, word ptr s32start
@@:
    mov bx, csel
    int 31h
    mov bx, dsel
    int 31h

; int31h/ax8: set segment limit
; if the requested size is > 1MB, then it must be page-aligned

    mov ax, 8
    mov cx, 0ffffh
    mov dx, cx

    mov bx, csel
    int 31h
    mov bx, dsel
    int 31h
    mov bx, fs
    int 31h

; csel -> cs, s32start -> eip

    xor edx, edx                ; dsel -> dx
    mov dx, dsel
    push 0                      ; align esp to dword

    cmp execArg, 0
    je  @f

    mov edi, 0                  ; offset (0) -> edi
    mov s32start, 0             ; jmp far csel:0
    jmp dword ptr s32start + 2  ; m16:16. can also use m16:32
@@:
    mov edi, s32start           ; offset -> edi
    jmp fword ptr s32start      ; m16:32. the offset in m16:16 is often insufficient

failDpmiHost:
    mov dx, offset sFailDpmiHost
    jmp talk16

failPm:
    mov dx, offset sFailPm
    jmp talk16

failHostMem:
    mov dx, offset sFailHostMem
    jmp talk16

talk16:
    mov ah, 9
    int 21h
    int 20h

failInPm:
; it seems that int21h/ah9 is not working properly in cwsdpmi 16-bit protected mode
    mov ax, 4c00h
    int 21h

execArg         byte    0
sFailDpmiHost   byte    'no dpmi host', 13, 10, '$'
sFailPm         byte    'failed to enter protect mode', 13, 10, '$'
sFailHostMem    byte    'no memory for dpmi host', 13, 10, '$'
fn              word    ?, ?
s32start       dword    ?
csel            word    ?
dsel            word    ?
s16end:
s16 ends

s32 segment
    mov     ds, dx              ; dx = dsel
;   mov     ss, dx              ; not sure whether or how to do this
; edi = offset of this segment
;  fs = a selector with a base of 0 and a limit of 4g

    mov     eax, cs
    call    selectorToDescriptorAddr
    call    baseFromDescriptorAddr  ; ebx holds segment base from selector's descriptor

    call    loadSegmentLimit        ; fill ebx
    lsl     ecx, eax                ; ebx = ecx is expected in debugger

    mov     eax, ds
    call    selectorToDescriptorAddr
    call    baseFromDescriptorAddr  ; ebx holds segment base from selector's descriptor

    call    loadSegmentLimit        ; fill ebx
    lsl     ecx, eax                ; ebx = ecx is expected in debugger

; call some dpmi functions

    mov     eax, 400h
    int     31h
    jc      fail32

    test    ebx, 100b
    jz      noVmem

    mov     esi, offset szYesVmem   ; offset within this segment
    add     esi, edi                ; + offset of this segment
    call    print

exit32:
    mov     ax, 4c00h
    int     21h

fail32:
    mov     esi, offset szFail32
    add     esi, edi
    call    print
    jmp     exit32

noVmem:
    mov     esi, offset szNoVmem
    add     esi, edi
    call    print
    jmp     exit32

szFail32    byte    'call failed in protected mode', 13, 10, 0
szYesVmem   byte    'virtual memory supported', 13, 10, 0
szNoVmem    byte    'virtual memory not supported', 13, 10, 0

print   proc
; in    esi = start of sz

    push    eax
    push    edx
    mov     ah, 2
    cld
@@:
    lodsb
    cmp     al, 0
    je      done

    mov     dl, al
    int     21h
    jmp     @b

done:
    pop     edx
    pop     eax
    ret
print   endp

; the following 4 functions are copied from another sample

selectorToDescriptorAddr proc
    sub     esp, 8
    sgdt    [esp + 2]
    test    eax, 4
    jnz     use_ldt
    mov     edx, eax
    and     edx, 0fff8h
    add     edx, [esp + 4]
    jmp     @f

use_ldt:
    xor     edx, edx
    sldt    dx
    and     dx, 65528
    add     edx, [esp + 4]
    push    ebx
    call    baseFromDescriptorAddr
    mov     edx, eax
    and     edx, 0fff8h
    add     edx, ebx
    pop     ebx
@@:
    add     esp, 8
    ret
selectorToDescriptorAddr endp

baseFromDescriptorAddr:
    push    ecx
    movzx   ebx, word ptr fs:[edx + 2]
    movzx   ecx, byte ptr fs:[edx + 4]
    shl     ecx, 16
    add     ebx, ecx
    movzx   ecx, byte ptr fs:[edx + 7]
    shl     ecx, 24
    add     ebx, ecx
    pop     ecx
    ret

limitFromDescriptorAddr proc
    push    ecx
    movzx   ebx, word ptr fs:[edx + 0]
    movzx   ecx, byte ptr fs:[edx + 6]
    shl     cl, 4
    shl     ecx, 12
    add     ebx, ecx
    test    byte ptr fs:[edx + 6], 80h
    jz      @f
    shl     ebx, 12
    add     ebx, 0fffh
@@:
    pop     ecx
    ret
limitFromDescriptorAddr endp

loadSegmentLimit:
    call    selectorToDescriptorAddr
    call    limitFromDescriptorAddr
    ret
s32 ends
    end s
```

执行结果:

```
C:\>cwsdpmi

C:\>out\dd 2
virtual memory supported

C:\>cwsdpmi

C:\>out\dd
virtual memory supported

C:\>cwsdpmi -s-
CWSDPMI V0.90+ (r7) Copyright (C) 2010 CW Sandmann  ABSOLUTELY NO WARRANTY

C:\>out\dd
virtual memory not supported
```

### 3d 图形

Year | 3D API           | Target Platforms             | Abstraction Level    | Ease of Use
-|-|-|-|-
1992 | OpenGL 1.0       | Linux, macOS, Windows        | High                 | Moderate
1996 | Direct3D         | Windows                      | Medium               | Complex
1996 | Glide            | 3dfx Voodoo cards            | Low                  | Easy
2014 | Metal            | iOS, macOS                   | Medium to Low        | Moderate
2016 | Vulkan 1.0       | Android, Linux, Windows      | Low                  | Complex
2022 | WebGPU           | Linux, macOS, Web, Windows   | Low                  | Moderate to Easy

显卡不走 cpu 的 isa 路线, 各个显卡的指令集都不相同. 显卡编程几乎都是对显卡技术标准编程, 没有 gpu 指令. 早期显示技术没有统一标准时可能是直接读写显卡, 也不知道那时有没有显卡, 不清楚具体做法. 后来一般是写入显卡映射的内存区域. 2d 显卡时写入的内容都是数据, 没有指令, 显卡做一些固定工作比如把字符数据转换为图像; 3d 显卡有了 gpu 但写入的似乎也不是 gpu 实际执行的指令而是些抽象指令, 就像 api 调用. 理论上可以通过端口和显卡交换数据不过我没有验证. 显然显卡 bios 和显卡驱动直接与显卡交换数据, 这部分内容以后再研究.

#### glide

1996 年之前的 opengl 主要是用 cpu 指令生成图像即软件渲染, 支持它的显卡不多, 集中在 sgi 自己的工作站显卡. 1996 年 3dfx interactive 公司发布了 voodoo 3d 加速卡和配套的编程接口 glide, 用显卡硬件生成图像所以性能很高, 但支持的运算种类没有 opengl 丰富. voodoo 3d 加速卡不是独立显卡, 2d 的主显卡输出到 voodoo, voodoo 用计算出的 3d 画面覆盖主显卡的画面传给显示器. 后来的 voodoo banshee 是独立显卡.

要在 dosbox 上编写使用 glide 的程序首先得确保 dosbox 能运行 glide 程序, dosbox 声称支持 voodoo 所以这一步应该很简单. 那么先下载几个小型 glide 程序, 最好是测试程序. https://3dfxarchive.com/reference.htm 提供了 3dfx voodoo programming 的资料, 下载第一项 3dfx glide2 sdk for dos/win32 v2.11. 这个 zip 文件解压缩后得到一个 exe, 在 macos 上解压缩这个 exe 得到一个目录 glide211. 把此目录放到 /dos 里以通过 dosbox 访问, 目录结构如下,

```
/dos/glide211/
    docs/
        (.doc files, cannot be opened with pages on macos)
    dos/
        bin/
            test01.exe
            test44.exe
            (other files)
        diags/
            (.exe files)
        include/
            (.h files)
        lib/
            watreg/
                glide.lib
                sst1init.lib    (sst1 = voodoo1, sst96 = voodoo2)
                texus.lib
            watregdb/
                (the same file names as in watreg)
            watstk/
                (the same file names as in watreg)
            watstkdb/
                (the same file names as in watreg)
    src/tests/
    win32/
    (other files)
```

- Glide 2.2 Reference Manual https://www.gamers.org/dEngine/xf3D/glide/glideref.htm

显然 bin 里的 testnn.exe 和 diags 里的 exe 都能拿来测试, 先试试 diags/fxremap.exe

```
C:\>glide211\dos\diags\fxremap
DOS/4G Protected Mode Run-time  Version 2.01a
Copyright (c) Tenberry Software, Inc. 1996
Warning S3 968/868 was not found
This program was only meant to be used with the 3dfx Voodoo chipset
and the S3 968/868 chipset to correct S3's memory addressing bug
No 968/868 or Voodoo chipset was detected
```

fxremap.exe 要求显卡型号是 s3 968/868, 这需要修改 dosbox 配置. 配置文件里用 `machine` 指代显卡型号, 有很多值供选择, 默认是 svga_s3. 首先要明确 glide 程序不要求显卡型号, 只是 fxremap.exe 有这要求. 想执行 fxremap.exe 要按下面修改 dosbox-x.conf,

```
[dosbox]
machine = svga_s3vision868
```

修改后成功执行了 fxremap, 也不知道它干了啥, 输出两行字就退出了. 执行 bin 里的 testnn.exe 试试, 这些程序都不要求显卡型号. 执行 `glide211\dos\bin\test02`, 按任意键后 dos 屏幕冻结了. 只能先检查 dosbox-x 的 voodoo 模拟. https://dosbox-x.com/wiki/Guide%3ASetting-up-3dfx-Voodoo-in-DOSBox%E2%80%90X 说 voodoo 模拟分低层 voodoo 卡硬件模拟和高层 glide api 穿透至主机系统这两种, 低层模拟的配置项是 `voodoo_card`, 使用内置算法或 opengl 模拟 glide, 高层模拟的配置项是 `glide`, 调用主机系统的 glide api. 我的主机系统没有 glide api 或 glide wrapper, 只能用低层模拟, 低层模拟的默认值 `voodoo_card = auto` 会首先尝试 opengl 然后是 software. 既然 auto 导致 dos 屏幕冻结那可能是 opengl 的毛病, 所以指定 `voodoo_card = software` 试试,

```
[voodoo]
voodoo_card = software
```

保存修改后的配置文件, 关闭 dosbox-x 再次打开, 执行 `glide211\dos\bin\test02`, 看起来成功了. 它先打印简介, 提示你按任意键, 按完显示 3dfx splash screen, 然后在右上角画一组白线, 按任意键结束. 执行之前请确保配置文件里 cpu 100%, 类似 `cycles = auto` 而不是类似 `cycles = fixed 3000`, 否则执行速度极慢.

macos 从 2018 开始弃用 opengl 转向 metal 不知是否和这现象有关, 相关问题 https://github.com/joncampbell123/dosbox-x/issues/5657 DOSBox-X SDL2 freezes with some apps with the default OpenGL output (macOS host, Win95 guest).

至此, 确定 dosbox-x 在相应配置下足以执行使用 glide api 的程序. 要生成这种程序需要连接到 glide 静态库, lib 目录有 4 个子目录也不知道使用哪个, 就先用下列命令查看了其中一个 lib 的全局符号,

```
lib glide211\dos\lib\watreg\glide.lib, out\glide.txt;
```

/dos/out/glide.txt 里有几组特征明显的符号, 比如 `FreeStringInDosMemory_`, `_PCI_BASE_ADDRESS_4`, `_grAlphaCombine@20`. 后两个应该分别是常量和 stdcall 函数, 前一个是啥? 问了 chatgpt 它说可能是 watcom register calling convention 的函数. 那么 lib 文件的符号基本明了了, 只需关注调用约定是 stdcall 的函数, 这些函数应该就是 api, 常量和 watcom register 调用约定的函数不用管, 应该是 lib 内部使用的. 通过 chatgpt 还明确了 4 个目录分别是两种 watcom 调用约定和调试发行版. 由于只使用 stdcall 的 api 所以 reg 或 stk 目录里的 lib 可以任选一个, 这里选 reg. 从 test02.c 里找了两个简单的 glide 函数 grGlideInit 和 grGlideShutdown, 这俩函数就在 glide.lib 里, 分别叫 _grGlideInit@0 和 _grGlideShutdown@0, 先调用这两个函数试试.

```
.386

extern _grGlideInit@0: proc, _grGlideShutdown@0: proc

xxx segment 'code'
s:
    call    _grGlideInit@0
    call    _grGlideShutdown@0
    mov     ax, 4c00h
    int     21h
xxx ends

s01 segment 'stack'
    dword   64 dup (?)
s01 ends
    end s
```

```
ml -Foout\ dd.msm -c
wlink file out\dd format os2 le library glide211\dos\lib\watreg\glide.lib option quiet, osname=DOS/4G, stub=wstub.exe
```

wlink 报错,

```
Stub exec failed:
c:\watcom\dos4gw.exe
Arg list too big
```

试了试用 dos32a 加载 wlink, 虽然不再因参数太长而拒绝执行但执行时先报错 Error: could not open message resource file. 然后输出一堆空行, 看起来是没能加载保存消息的资源文件 (代码段? 我没从 watcom 里拷贝什么消息文件到 /dos/watcom, wlink 也一直正常显示消息) 所以消息显示不出来. 虽然还能顺着这条路往前走但这里还是回到正常的路线, 使用 wlink 的 directive 文件, 类似 msbuild 响应文件. 新建文件 /dos/out/glide211.lnk 粘贴以下内容,

```
file    out\dd
format  os2 le
library glide211\dos\lib\watreg\glide.lib
option  quiet, osname=DOS/4G, stub=wstub.exe
```

`wlink @out\glide211`. 好多错误, 一屏显示不下, 所以把输出重定向到文件, `> out\glide211 wlink @out\glide211`. /dos/out/glide211 有 99 行抱怨类似,

```
Warning! W1008: cannot open math387r.lib : file not found
Warning! W1008: cannot open noemu387.lib : file not found
Error! E2028: __8087 is an undefined reference
...
file glide211\dos\lib\watreg\glide.lib(D:\TDFX\devel\sst1\init\gdebug.c): undefined symbol sscanf_
...
```

前两行虽然是警告但还是解决一下吧; 后面的 `__8087` 等符号不熟悉, 先等等; `sscanf_` 显然是 c 标准库函数, 后缀下划线说明是 watcom register call. 于是从 (watcom)/lib386 里找到 math387r.lib, noemu387.lib, dos/clib3r.lib, 把这 3 个文件拷贝到 /dos/watcom, 按下面修改 /dos/out/glide211.lnk,

```
file    out\dd
format  os2 le
libpath glide211\dos\lib\watreg;watcom
library glide, math387r, noemu387, clib3r
option  quiet, osname=DOS/4G, stub=wstub.exe
```

`> out\glide211 wlink @out\glide211`, /dos/out/glide211 这次只有 1 个错误 Error! E2030: file clib3r.lib(cstart): multiple starting addresses found. 这提醒,

- 连接标准 c 库时不能定义入口而要定义公共符号 main, 标准 c 库会调用这个 main
- 既然是 clib3r 那应该会按 watcom register call 的方式调用, 所以 main 应该有后缀下划线
- watcom register call 是 callee clean-up, 但 argc 和 argv 都能通过寄存器传递, main 无需清理栈
- watcom register call 32-bit 下返回值放 al/ax/eax/edx:eax/(ss:)esi
- 退出时应该用 ret 而不再用 int21h/ah4ch. .386 w/o .model = .model flat, ret 汇编为 retn

```
; ml -Foout\ dd.msm -c
; wlink @out\glide211
;
; # out\glide211.lnk
; file    out\dd
; format  os2 le
; libpath watcom
; library clib3r, math387r, noemu387
; library glide211\dos\lib\watreg\glide
; option  quiet, stub=wstub.exe

.386

extern _grGlideInit@0: proc, _grGlideShutdown@0: proc
public main_

xxx segment 'code'
main_:

    call    _grGlideInit@0
    call    _grGlideShutdown@0

    xor     eax, eax
    ret
xxx ends

s01 segment 'stack'
    dword   64 dup (?)
s01 ends
    end
```

前面下载的 glide2 sdk v2.11 显然是 c 语言 sdk, 包含 test 程序的源代码. 目前具备的这些条件足以编写使用 glide 的程序:

- 抄袭目标. /dos/glide211/src/tests/test02.c
- 常量. 从 /dos/glide211/dos/include 的头文件里提取
- api 签名. 从头文件里获知
- api 实现. /dos/glide211/dos/lib/watreg
- 代码. 386 32 位汇编, 使用 wlink 连接为使用 dos4gw 或 dos32a 的程序
- 连接 glide 静态库
- wd 调试不了 glide 程序, 因为不显示 wd 的内容, 可能是 glide 程序独占屏幕. 只好凑合用 int3 + dos32a + dosbox-x debugger

```
; test02.c 从命令行参数确定分辨率和绘制的帧数
; 在 640x480 的假想框里绘制一些直线, 假想框的大小和屏幕分辨率不一定一致所以需要缩放
; 在一个循环里更新屏幕, 有按键就退出; 如果用命令行参数 -n 传递了帧数, 在循环到这个帧数时也退出
;
; 本程序不读命令行, 分辨率固定为 640x480, 绘制后按任意键退出
;
; ml -Foout\ dd.msm -c
; wlink @out\glide211
;
; # out\glide211.lnk
; file    out\dd
; format  os2 le
; libpath watcom
; library clib3r, math387r, noemu387
; library glide211\dos\lib\watreg\glide
; option  quiet, stub=wstub.exe

; translate test02.c to masm
; test02.c is protected by copyright so maybe this is illegal
;
; /dos/glide211/src/tests/test02.c
; Copyright (c) 1995, 3Dfx Interactive, Inc.
; All Rights Reserved.
;
; test results of these resolutions:
;
; 320x200
; 320x240
; 400x256
; gd error (glide): grSstOpen:  Video Timing initialization failed!
; grSstOpen:  Video Timing initialization failed!
;
; 640x200
; 640x350
; gd error (glide): grSstOpen:  unknown resolution specified
;
; 512x384
; flicker, wrong coordinate
;
; 640x400
; 800x600
; 960x720
; wrong coordinate
;
; 640x480
; looks good

m$int typedef dword

;
; 3dfx.h

; typedef int FxBool;

FxBool typedef m$int

;
; glidesys.h

; #define GLIDE_NUM_TMU 2

GLIDE_NUM_TMU equ 2

;
; sst1vid.h

; #define GR_REFRESH_60Hz   0x0
; #define GR_RESOLUTION_640x480   0x7

GR_REFRESH_60Hz         equ 0
GR_RESOLUTION_640x480   equ 7

;
; glide.h

; #define MAX_NUM_SST 4
; #define GR_WDEPTHVALUE_FARTHEST 0xFFFF
; #define GR_COLORCOMBINE_CCRGB 0x1
; #define GR_COLORFORMAT_ABGR     0x1
; #define GR_ORIGIN_LOWER_LEFT    0x1
; #define GR_SMOOTHING_ENABLE     0x1

MAX_NUM_SST             equ 4
GR_WDEPTHVALUE_FARTHEST equ 0ffffh
GR_COLORCOMBINE_CCRGB   equ 1
GR_COLORFORMAT_ABGR     equ 1
GR_ORIGIN_LOWER_LEFT    equ 1
GR_SMOOTHING_ENABLE     equ 1

; typedef int GrSstType;

GrSstType typedef m$int

; typedef struct GrTMUConfig_St {
;     int tmuRev;     /* Rev of Texelfx chip */
;     int tmuRam;     /* 1, 2, or 4 MB */
; } GrTMUConfig_t;

GrTMUConfig_t struct
    tmuRev  m$int ?
    tmuRam  m$int ?
GrTMUConfig_t ends

; typedef struct GrVoodooConfig_St {
;     int             fbRam;                      /* 1, 2, or 4 MB */
;     int             fbiRev;                     /* Rev of Pixelfx chip */
;     int             nTexelfx;                   /* How many texelFX chips are there? */
;     FxBool          sliDetect;                  /* Is it a scan-line interleaved board? */
;     GrTMUConfig_t   tmuConfig[GLIDE_NUM_TMU];   /* Configuration of the Texelfx chips */
; } GrVoodooConfig_t;

GrVoodooConfig_t struct
    fbRam       m$int   ?
    fbiRev      m$int   ?
    nTexelfx    m$int   ?
    sliDetect   FxBool  ?
    tmuConfig   GrTMUConfig_t GLIDE_NUM_TMU dup (<>)
GrVoodooConfig_t ends

; typedef struct GrSst96Config_St {
;     int             fbRam;          /* How much? */
;     int             nTexelfx;
;     GrTMUConfig_t   tmuConfig;
; } GrSst96Config_t;

GrSst96Config_t struct
    fbRam       m$int           ?
    nTexelfx    m$int           ?
    tmuConfig   GrTMUConfig_t   <>
GrSst96Config_t ends

; typedef struct GrAT3DConfig_St {
;     int rev;
; } GrAT3DConfig_t;

GrAT3DConfig_t struct
    rev m$int ?
GrAT3DConfig_t ends

; typedef struct {
;     int num_sst;            /* # of HW units in the system */
;     struct {
;         GrSstType type;     /* Which hardware is it? */
;         union SstBoard_u {
;             GrVoodooConfig_t    VoodooConfig;
;             GrSst96Config_t     SST96Config;
;             GrAT3DConfig_t      AT3DConfig;
;         } sstBoard;
;     } SSTs[MAX_NUM_SST];    /* configuration for each board */
; } GrHwConfiguration;

m$SstBoard_u union
    VoodooConfig    GrVoodooConfig_t    <>
    SST96Config     GrSst96Config_t     <>
    AT3DConfig      GrAT3DConfig_t      <>
m$SstBoard_u ends

m$GrHwConfigurationS1 struct
    m$type      GrSstType       ?
    sstBoard    m$SstBoard_u    <>
m$GrHwConfigurationS1 ends

GrHwConfiguration struct
    num_sst m$int ?
    SSTs    m$GrHwConfigurationS1 MAX_NUM_SST dup (<>)
GrHwConfiguration ends

; typedef struct {
;   float  sow;                   /* s texture ordinate (s over w) */
;   float  tow;                   /* t texture ordinate (t over w) */  
;   float  oow;                   /* 1/w (used mipmapping - really 0xfff/w) */
; }  GrTmuVertex;

GrTmuVertex struct
    sow dword   ?
    tow dword   ?
    oow dword   ?
GrTmuVertex ends

; typedef struct
; {
;   float x, y, z;                /* X, Y, and Z of scrn space -- Z is ignored */
;   float r, g, b;                /* R, G, B, ([0..255.0]) */
;   float ooz;                    /* 65535/Z (used for Z-buffering) */
;   float a;                      /* Alpha [0..255.0] */
;   float oow;                    /* 1/W (used for W-buffering, texturing) */
;   GrTmuVertex  tmuvtx[GLIDE_NUM_TMU];
; } GrVertex;

GrVertex struct
    x   dword   ?
    y   dword   ?
    z   dword   ?
    r   dword   ?
    g   dword   ?
    b   dword   ?
    ooz dword   ?
    a   dword   ?
    oow dword   ?
    tmuvtx GrTmuVertex GLIDE_NUM_TMU dup (<>)
GrVertex ends

;
; test02.c

; #define WINSCALEX(x) ((x/WREFWIDTH) * wWidth)
; #define WINSCALEY(y) ((y/WREFHEIGHT) * wHeight)
;
; 首先展开式应该是 ((x) / WREFWIDTH * wWidth)
;
; wWidth 是变量所以 WINSCALEX 需要运行时计算, 下列宏
; WINSCALEX macro x
;     exitm <(x / WREFWIDTH * wWidth)>
; endm
; 对 WINSCALEX(123) 生成 (123 / WREFWIDTH * wWidth), 不是合法的汇编语句

winScaleX   macro arg
    fld     wWidth
    fld     arg
    fld     f640    ; st = [f640, arg, wWidth]
    fdiv    ; st = [arg / f640,  wWidth]. = fdivp st(1), st(0)
    fmul    ; st = [arg / f640 * wWidth]. = fmulp st(1), st(0)
    fstp    arg
endm

winScaleY   macro arg
    fld     wHeight
    fld     arg
    fld     f480
    fdiv
    fmul
    fstp    arg
endm

.386

; glide.h
extern   _grGlideInit@0: proc, _grGlideShutdown@0: proc, _grSstSelect@4: proc,
  _grSstQueryHardware@4: proc,    _grBufferSwap@4: proc,
_grConstantColorValue@4: proc,      _grDrawLine@8: proc,
          _grSstOpen@24: proc,  _grBufferClear@12: proc

; glideutl.h
extern _guColorCombineFunction@4: proc

extern getch_: proc, puts_: proc

public main_

xxx segment 'code'
    assume  ds: d01

main_:
    mov     eax, offset szIntro
    call    puts_
    call    getch_
    call    _grGlideInit@0

; stdcall: push args right-to-left, returns in eax, callee cleans up

    push    offset hwconfig
    call    _grSstQueryHardware@4

    test    eax, eax
    jz      failqh

    push    0
    call    _grSstSelect@4

    push    2
    push    GR_SMOOTHING_ENABLE
    push    GR_ORIGIN_LOWER_LEFT
    push    GR_COLORFORMAT_ABGR
    push    GR_REFRESH_60Hz
    push    GR_RESOLUTION_640x480
    call    _grSstOpen@24

    test    eax, eax
    jz      failopen

    push    GR_COLORCOMBINE_CCRGB
    call    _guColorCombineFunction@4

    push    -1
    call    _grConstantColorValue@4

; "while ( 1 )". no while loop here, single frame only

    push    GR_WDEPTHVALUE_FARTHEST
    push    0
    push    0
    call    _grBufferClear@12

    mov     vtx1.y, 479     ; ^ -- vtx1 (fixed y) --
    fild    vtx1.y          ; |                     |
    fstp    vtx1.y          ; |                     |
    mov     vtx2.x, 639     ; y              vtx2 (fixed x)
    fild    vtx2.x          ; |                     |
    fstp    vtx2.x          ; 0 -------------- x --->

    winScaleY   vtx1.y
    winScaleX   vtx2.x

    xor     eax, eax
    mov     step, eax
@@:
    mov     vtx1.x, eax
    fild    vtx1.x
    fstp    vtx1.x

    mov     vtx2.y, 640
    sub     vtx2.y, eax
    fild    vtx2.y
    mov     vtx2.y, 640
    fidiv   vtx2.y
    mov     vtx2.y, 480
    fimul   vtx2.y
    fstp    vtx2.y

    winScaleX   vtx1.x
    winScaleY   vtx2.y

    push    offset vtx2
    push    offset vtx1
    call    _grDrawLine@8   ; destroy some registers

    add     step, 12
    mov     eax, step
    cmp     eax, 640
    jb      @b

    push    1
    call    _grBufferSwap@4
    call    getch_

exit:
    call    _grGlideShutdown@0
    xor     eax, eax
    ret

failqh:
    mov     eax, offset szFailqh
    call    puts_
    jmp     exit

failopen:
    mov     eax, offset szFailopen
    call    puts_
    jmp     exit
xxx ends

d01 segment
; GrHwConfiguration hwconfig;

hwconfig    GrHwConfiguration <>

vtx1        GrVertex    <>
vtx2        GrVertex    <>

; #define WREFWIDTH  640.f
; #define WREFHEIGHT 480.f

f480        dword   480.
f640        dword   640.

; float wWidth = 640.f;
; float wHeight = 480.f;
; these 2 are intended to be specified on the command line

wWidth      dword   640.
wHeight     dword   480.

step        dword   ?
szIntro     byte    10, 'TEST02:', 10
            byte    'this test should draw a parabolic envelope of lines', 10
            byte    'press a key to begin', 0
szFailqh    byte    'grSstQueryHardware failed!', 0
szFailopen  byte    'grSstOpen failed!', 0
d01 ends

s01 segment 'stack'
    dword   64 dup (?)
s01 ends
    end
```

想访问 dos4g 程序的命令行发现做不到. watcom register call 用 eax, edx 分别传递 argc, argv, 从调试器看启动代码也确实往这两个寄存器赋值了, 但在 main 里看到这两个寄存器都是 0, 不知哪里出了问题.

```
; ml -Foout\ dd.msm -c
; wlink file out\dd format os2 le library watcom\clib3r option quiet, stub=wstub.exe

.386

extern printf_: proc
public main_

xxx segment 'code'
main_:
; eax = argc, edx = argv. or is it?

    mov     ebp, esp
    push    [ebp + 4]
    push    [ebp]
    push    edx
    push    eax
    push    offset sz
    call    printf_     ; varargs use the stack calling convention
    mov     esp, ebp    ; the caller cleans up

    xor     eax, eax
    ret

sz  byte 'eax = 0x%x, edx = 0x%x, [esp] = 0x%x, [esp + 4] = 0x%x', 10, 0
xxx ends
s01 segment 'stack'
    dword   64 dup (?)
s01 ends
    end
```

运行 `out\dd -arg1 -arg2` 输出 `eax = 0x0, edx = 0x0, [esp] = 0x1a4cd4, [esp + 4] = 0x0`.

#### watcom register call

watcom 的 register call 和 stack call 属于背景知识. glide api 使用的是 stdcall.

用 lib.exe 生成 lib 文件的全局符号后我还问了 chatgpt: "glide211/dos/lib 下有 4 个子目录 watreg, watregdb, watstk, watstkdb, 这些目录里的文件名都一样, 是一些 .lib 文件. 你如何理解这些目录?" chatgpt 的回答直接闪瞎我的眼,

```
你提到的路径 glide211/dos/lib 下有四个子目录：
- watreg
- watregdb
- watstk
- watstkdb
且这些目录里的文件名都一样，都是一些 .lib 文件。

我对这些目录的理解和推测：
1. 相同文件名但不同目录，说明它们是同一套库的不同版本或不同配置
2. 目录名称分析：
- watreg 和 watregdb：
    - wat 很可能指的是 Watcom 编译器系列（比如 Open Watcom），这是一个较常见的 DOS 下的 C/C++ 编译器。
    - reg 可能代表 register calling convention（寄存器调用约定），表示这些库使用寄存器调用约定编译生成。
    - db 很可能是 debug 的缩写，表示带调试信息的版本。
- watstk 和 watstkdb：
    - stk 很可能代表 stack calling convention（堆栈调用约定），表示使用堆栈调用约定编译。
    - 同样，db 依然是调试版本。
3. 总结：
目录         调用约定       版本类型
watreg      寄存器调用约定  Release（非调试）
watregdb    寄存器调用约定  Debug（调试）
watstk      堆栈调用约定    Release（非调试）
watstkdb    堆栈调用约定    Debug（调试）
4. 用途：
- 这样做是为了给开发者提供不同的链接选项，方便选择合适的调用约定和调试版本。
- 不同调用约定对函数参数传递、性能和二进制兼容性会有影响。
- 调试版本通常带有符号和额外检查，方便排查问题。

总结
你看到的这四个目录，实际上是同一套库的不同编译版本，主要区别在于调用约定（寄存器 vs 堆栈）和是否带调试信息。用户根据自己程序的编译选项和调试需求选择相应的 .lib 文件进行链接。
```

这就知道该用 reg 或 stk 版本的 lib, 不需要 db 版. 但 reg 和 stk 调用约定具体是啥? 这种问题问 gpt 肯定是浪费时间, 于是搜索了一会, 在 https://en.wikipedia.org/wiki/X86_calling_conventions 的 Callee clean-up > Watcom register 看到,

> 参数从左至右至多使用 4 个寄存器, 依次是 EAX, EDX, EBX, ECX. 如果任何参数无法放入寄存器, 比如太大, 该参数及后续所有参数从右至左放到栈上. 名称修饰为添加一个后缀下划线. 变参函数回退至使用 watcom 基于栈的调用约定.

那什么是 "watcom 基于栈的调用约定" 呢? 查阅 https://open-watcom.github.io/open-watcom-v2-wikidocs/cguide.html (also (watcom)/docs/cguide.pdf) 后感觉问题不简单, 需要先搞清基于寄存器的调用约定, 前面 wikipedia 说得不详细. 页面说 watcom 在编译 16 位程序时若看到 `fpc` 编译选项就认为是非 80x87 程序, 这种程序中基于寄存器的调用约定传递参数的方式是, 从左往右看参数,

1. 参数大小
    - 1 字节, 符号扩展为 2 字节
    - 2 字节, 4 字节, double, 不变
    - 其它类型, 准备入栈
    - 没有参数, 从右往左把准备入栈的参数入栈, 对齐到 2 字节, 结束
1. 前一个参数是否准备入栈
    - 是, 准备入栈
    - 否
        - 2 字节, 检查 [ax, dx, bx, cx] 是否还有元素
            - 有, 放入相应寄存器, 把该寄存器从可用列表里移除
            - 无, 准备入栈
        - 4 字节, 检查 [ax:dx, bx:cx] 是否还有元素 (*)
            - 有, 小端序放入相应寄存器对, 把该寄存器对从可用列表里移除
            - 无, 准备入栈
        - double, 检查 ax, bx, cx, dx 是否全部空闲
            - 是, 小端序放入这 4 个寄存器, 清空寄存器可用列表
            - 否, 准备入栈
1. 处理下一个参数

(*) 假设 ax 已占用, 其余空闲, 4 字节参数肯定放 bx:cx, 那剩下空闲的 dx 还放不放参数?

基本搞清楚了 watcom 16 位非 80x87 程序基于寄存器的调用约定中传递参数的方式后想搞清 watcom 16 位非 80x87 程序基于栈的调用约定, 没找到, 找到了 32 位的, (watcom)/docs/cguide.pdf, 10.4.6 Using Stack-Based Calling Conventions,

> When using the stack-based calling conventions, no registers are used to pass arguments. Instead, all arguments are passed on the stack.

watcom 16 位 80x87 程序指编译时使用了 `fpi` 或 `fpi87` 选项. 这种程序的调用约定是,

- 浮点数参数准备入栈
- 其他参数按非 80x87 程序的方式处理

(watcom)/docs/cguide.pdf 里的相关信息:

- `返回值` 7.4.7 Returning Values from Functions
- `32-bit` 10.4 Calling Conventions for Non-80x87 Applications

至此基本搞清楚了 watcom 程序基于寄存器和基于栈的调用约定.

## 386 protected mode

286 发明了 protected mode 即受保护模式, 中文译为保护模式. 受保护的是内存, 保护方式有 2:

1. 必选的分段. 给线性地址附加一个 descriptor 描述线性地址的起始 (base), 大小 (limit), 是否支持读写执行, 权限水平 (dpl), 数据长度 (16 位还是 32 位) 等乱七八糟的属性. 附加了 descriptor 的线性地址叫段. 段寄存器保存 selector 指向 descriptor, selector 有 rpl, cs selector 的 rpl 叫 cpl. cpl = 3 的程序启动时获得几个 selector, 所有线性地址访问只能通过这些 selector. 访问线性地址比如在代码里读取内存时 cpu 要确认 max(cpl, rpl) < dpl + 1 否则 #gp (general protection fault)
1. 可选的分页. 启用时线性地址叫虚拟地址, 要经分页模块转换为物理地址. 页也有一些属性用于保护内存

通过把 cr0 的 msw (machine status word) 的 pe 位置 1 进入保护模式, 也通过该位判断 cpu 是处于实模式还是保护模式.

intel sdm, vol. 1,

- 3.3 memory organization
    > 处理器从它总线寻址的内存叫物理内存. 物理内存组织为 1 个 8-bit bytes 序列, 每字节有唯一地址叫物理地址. 不支持 intel 64 架构的处理器物理地址空间范围是 0 ~ 2 ** 36 - 1 = 64g bytes.
- 3.3.3 Memory Organization in 64-Bit Mode
    > intel 64 架构支持大于 64g 字节的物理地址空间. ia-32 处理器的实际物理地址尺寸特定于实现. ... pae paging 机制把线性地址空间映射进处理器的物理地址空间.

提醒:

- pae paging 属于 paging, 把 cpu 的 4g 线性地址空间对应到到 36 根地址线可以访问的 64g 物理地址空间
- cpu 通过总线发出对物理内存地址的访问请求不一定落到物理内存, 回忆前面见过的内存地址映射

### segmentation

dos extender 节已经接触过分段了. 这里不使用 api, 用 cpu 指令进入保护模式然后回到实模式. 先回顾一下 16-bit 和 32-bit 代码里的 jump m16:16/32.

- std.trp 用于调试一般程序, 确保 (watcom)/binw/std.trp 拷贝到了 /dos/watcom

16-bit code on 32-bit cpu. modr/m 用于计算有效地址, 16-bit 代码使用 16-bit modr/m, 带 0x67 address-size override prefix 时使用 32-bit modr/m.

```
; ml -Foout\ dd.msm -Feout\ -AT
; wd out\dd

.386

xxx segment use16
s:
    jmp dword ptr cs:[ebx]  ;    67 2E FF 2B
    jmp fword ptr cs:[ebx]  ; 67 66 2E FF 2B
    jmp dword ptr cs:[bx]   ;       2E FF 2F
    jmp fword ptr cs:[bx]   ;    66 2E FF 2F
    jmp dword ptr cs:s + 2  ;       2E FF 2E 02 00
    jmp fword ptr cs:s      ;    66 2E FF 2E 00 00
xxx ends
    end s
```

32-bit.

```
; ml -Foout\ dd.msm -c
; wlink file out\dd format os2 le option quiet, stub=wstub.exe
; wd -trap=rsi out\dd

.386

xxx segment 'code'
s:
    jmp dword ptr cs:[ebx]  ;    2E FF 23               <- o = 4, jump
    jmp fword ptr cs:[ebx]  ;    2E FF 2B               <- o = 5, far jump
    jmp dword ptr cs:[bx]   ; 67 2E FF 27               <- o = 4
    jmp fword ptr cs:[bx]   ; 67 2E FF 2F               <- o = 5
    jmp dword ptr cs:s + 2  ;    2E FF 25 02 50 4C 00   <- o = 4
    jmp fword ptr cs:s      ;    2E FF 2D 00 50 4C 00   <- o = 5
xxx ends
s01 segment 'stack'
    dword 32 dup (?)
s01 ends
    end s
```

从实模式进入保护模式很麻烦, 反过来更麻烦. intel sdm, vol. 3, 11.9 mode switching 详细列举了步骤, 下面摘取将用到的那些. cli 屏蔽可屏蔽中断, 外部电路可以屏蔽 nmi, 代码不要抛异常或执行软中断:

real mode -> protected mode

1. cli
1. lgdt
1. set cr0.pe by mov cr0
1. (immediately follow) load cs by a far jump
1. lldt if necessary
1. load ds, es, fs, gs, ss with selectors, could be null
1. sti

protected mode -> real mode

1. cli
1. far jump to a readable segment with a 0xffff limit
1. load ds, es, fs, gs, ss with a non-null selector for a descriptor that
    - limit = 64 kbytes (0ffffh)
    - byte granular (g = 0)
    - expand up (e = 0)
    - writable (w = 1)
    - present (p = 1)
    - base = any value<br>
    note that if the segment registers are not reloaded, execution continues using the descriptor attributes loaded during protected mode
1. reset cr0.pe by mov cr0
1. far jump to real mode code segment
1. load ds, es, fs, gs, ss, could be 0
1. sti

```
; ml -Foout\ dd.msm -Feout\ -AT

SEL_CODE        equ  8  ; selector#1 of gdt, code
SEL_DATA        equ 16  ; selector#2 of gdt, data
SEL_EXIT_CODE   equ 24  ; code selector for exiting protected mode
SEL_EXIT_DATA   equ 32  ; data selector for exiting protected mode

.386p

s16 segment use16
    assume  ds: s16
    org 256
s:
; a20 is enabled in dosbox-x. https://wiki.osdev.org/A20_Line

; linear address of this segment -> ecx

    xor ecx, ecx
    mov cx, cs
    shl ecx, 4

; linear address of next segment

    xor eax, eax
    mov ax, s16end
    add eax, 15
    shr eax, 4
    shl eax, 4      ; linear address of next segment without relocation
    add eax, ecx    ; linear address of next segment relocated
    mov dword ptr s32start, eax

; lgdt requires the linear address of gdt

    mov eax, ecx
    add eax, gdt
    mov dword ptr gdtr + 2, eax

; linear address of this segment -> base of SEL_EXIT_CODE

    mov eax, ecx
    mov word ptr gdt + SEL_EXIT_CODE + 2, ax    ; base  low, bits  0~15
    shr eax, 16
    mov byte ptr gdt + SEL_EXIT_CODE + 4, al    ; base  mid, bits 16~23
    shr eax, 8
    mov byte ptr gdt + SEL_EXIT_CODE + 7, al    ; base high, bits 24~31

; linear address of infos -> ebx

    mov ebx, ecx
    add ebx, infos

; record some information for later use

    mov word ptr oldsp, sp
    mov word ptr real2addr + 2, cs
    mov word ptr infos, real1

    push 0          ; align esp to dword
    mov eax, ecx
    add eax, esp
    mov dword ptr infos + 6, eax    ; linear address of sp

; load gdt, then load cs via far jump

    cli
    lgdt fword ptr gdtr ; this requires .386p
    mov eax, cr0
    or  al, 1           ; set cr0.pe to enter protected mode
    mov cr0, eax

; protected mode with 16-bit code segment starts here

    jmp fword ptr s32start

real1:
    mov ax, SEL_EXIT_DATA
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov eax, cr0
    and al, 0feh        ; clear cr0.pe
    mov cr0, eax

; real mode starts here

    jmp dword ptr cs:real2addr

real2:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    xor esp, esp
    mov ss, ax
    mov sp, word ptr oldsp
    sti

    mov di, 0b800h
    mov es, di
    cld

    mov di, 640h
    mov cx, 80 * 5
    mov ax, 2020h  ; space character with green background
    rep stosw

    mov di, 820h
    mov cx, 80 * 3
    mov ax, 1820h  ; space character with blue background
    rep stosw

    mov dx, offset msg
    mov ah, 9
    int 21h
    int 20h

align 4

gdt:
   qword 0              ; null descriptor

    word 0ffffh         ; limit low = 0xffff
    word 0              ; base  low = 0
    byte 0              ; base  mid = 0
    byte 10011010b      ; access: present, dpl = 0, s = 1, executable, readable
    byte 11001111b      ; flags: page granularity, 32bit, limit high = 0xf
    byte 0              ; base high = 0

    word 0ffffh         ; limit low = 0xffff
    word 0              ; base  low = 0
    byte 0              ; base  mid = 0
    byte 10010010b      ; access: present, dpl = 0, s = 1, writable
    byte 11001111b      ; flags: page granularity, 32bit, limit high = 0xf
    byte 0              ; base high = 0

    word 0ffffh         ; limit low = 0xffff
    word 0              ; base  low = 0
    byte 0              ; base  mid = 0
    byte 10011010b      ; access: present, dpl = 0, s = 1, executable, readable
    byte 00000000b      ; flags: byte granularity, 16bit, limit high = 0
    byte 0              ; base high = 0

    word 0ffffh         ; limit low = 0xffff
    word 0              ; base  low = 0
    byte 0              ; base  mid = 0
    byte 10010010b      ; access: present, dpl = 0, s = 1, writable, expand up
    byte 00000000b      ; flags: byte granularity, 16bit, limit high = 0
    byte 0              ; base high = 0

gdtr:
    word gdtr - gdt - 1 ; limit
   dword ?              ; base

oldsp:
    word ?

s32start:
   dword ?
    word SEL_CODE

real2addr:
    word real2
    word ?              ; real mode cs

infos:
   dword ?              ; low word = offset of real1, high word = 0
    word SEL_EXIT_CODE
   dword ?              ; new sp

msg:
    byte 'good bye', 13, 10, '$'

s16end:
s16 ends
s32 segment
    mov ax, SEL_DATA
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, [ebx + 6]
    sti

; draw some rows
; 0xb8000   80 words * 25 lines
; 0xb80a0
; ...
; 0xb8fa0   end of screen

    mov edi, 0b8320h
    mov ecx, 40 * 15
    mov eax, 60206020h  ; space character with brown background
    cld
    rep stosd

; dosbox-x debugger reports E_Exit: Illegal descriptor type 11 for int D
; when executing 'rep stosd', then closes the dosbox-x window

; back to real mode

    cli
    jmp fword ptr [ebx] ; retf adds 8 to esp
s32 ends
    end s
```

上面代码 s32 的注释里提到在用 dosbox-x debugger 调试时会打印错误并关闭 dosbox-x, 删掉 stosd 就可以调试至正常结束. 不在调试器里运行时看起来正常. 我不知道是否是代码的问题就在 86box 里试了试, 看起来也正常. 按 /readme/acc386 on 86box 创建虚拟机, 从光驱载入目录 /dos, 在虚拟机里执行 `d:out\dd`.



todo: ### paging

*i'd like to save it for another day.*

## masm 语法

.|.
-|-
reserved words              | cpu 厂商规定的指令助记符<br>masm 规定的指示 directives, 属性 attributes, 操作符 operators, 预定义符号 predefined symbols
identifier                  | at most 247 chars, 248+ error A2043: identifier too long<br>first char: $?@_a-z<br>rest chars: first char plus 0-9<br>after `option dotname`, first char can be .<br>masm keywords can use % as first char
line                        | at most 512 chars, 513+ error A2039: line too long
integer constants           | 9, 1b, 1y, 7o, 7q, 9d, 9t, 0fh<br>字面量基数不是 16 时可以用 b, d 后缀; `.radix constexpr` 改变此后字面量的基数; 不能以 16 进制的字母打头, 需要前缀 0<br>"abc", 'abc': 串里字符的 ascii, "abc" = 979899, 唯一的转义是两个引号表示一个引号
floating-point constants    | 2.523E1, -3.6e-2, 5.<br>always evaluates digits of real numbers as base 10<br>can also specify the encoded format with hexadecimal digits, end with r, cannot be signed: 3F800000r
text constants              | < some text >
constant expressions        | constexpr. integer constants and optionally operators
expressions                 | constant expressions, labels, types, registers, and their attributes

intel 在有效地址里使用了表达式, 其在运行时求值因此不是常量表达式.

### constexpr

operators

结构名似乎也是 constant, 因为定义变量时 dup 前面可以放结构名.

### 宏

see /macros.md

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
align       |                       | 此对齐把源代码的而不是程序在内存中的起始位置看作 0, 所以第 1 个段符合任意对齐
|           | BYTE, WORD, DWORD     | 1, 2, 4 bytes
|           | PARA                  | default. para = paragraph, 1 paragraph = 16 bytes
|           | PAGE                  | 256 bytes. 程序加载后第一句话肯定不是 0 所以在内存中 page 往往不对齐到 256 边界
readonly    | readonly              | 静态检查, 写入该段引发汇编错误
combine     |                       | 是否和其他文件的同名段组合. 文件内的同名段一定组合
|           | PRIVATE               | default. 不组合
|           | PUBLIC, MEMORY        | 组合
|           | STACK                 | 组合为栈
|           | COMMON                | 叠放, 大小 = 参与组合中最大的大小
|           | AT address            | 段内只能放类型定义, 不能放数据, 用于按结构访问已知的内存; 保护模式不能用
use         | USE16, USE32, FLAT    | 386+
'class'     |                       | link 把类名相同的段按看到的顺序放一起

combine 作用于多个文件里的同名段, 文档说同名不同类名的段不组合, 指的应该是不同文件里的段:

> Setting Segment Order with Class Type<br>Two segments with the same name are not combined if their class is different.

用 `ml -Fl` 实验发现 3 种排列方式, 实验并不全面:

- "收集", 名字是我起的, masm 没提到这种行为. 同 1 文件里的同名段要么收集为 1 个段要么汇编错误, 最终段的类型是
    - align = 首先遇到的 align, 此后的同名段不能指定不同的 align. 都不指定时使用默认值, 同名段之间没有 align
    - class = 最后 1 个段的 class
    - combine 很乱无法理解, 比如前面的段有 align 没有 at, 后面的段没有 align 有 at, 就报 A2015: 后面段的 alignment can not change
    - readonly = 任何遇到的 readonly
    - use = 第 1 个段的 use 或第 1 个段的默认值
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
; 1. 没有 assume 时 masm 在 mov 的前面加 cs:, 机器码 2e; 但 com 的 cs = ds = es = ss, 2e 是多余的前缀
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

- size ptr 可以写在立即数或内存前, 实际会放在内存前
- debug 不认识 dword, qword, tbyte, 并且 16 位模式也不支持 mov 这种长度

这种 ptr, x86 指令集里没有, 各种反汇编里经常见, 用 debug 写汇编时可以省略, debug 的反汇编也使用它.

谁发明的? 网上没找到答案.

干嘛使? `mov size memory, immediate` 解决这个问题: 汇编器看到 `mov memory, immediate` 时不知道 memory 指出的是 byte, word 或其他, 也就不知道该汇编成哪个 opcode, 所以需要额外的词 - size - 去说明: `mov word ptr [bx], 5`, debug 里可写为 `mov word [] bx, 5` 或 `mov [] word bx, 5`. mov byte, move word 是不同的指令. 能从操作数确定长度比如 mov bx, 3 时无需说明长度, 汇编器会生成正确的 opcode, 无法确定时才需要说明.

要点是 size ptr 或 size 用来限定地址指向的内存的长度. size ptr memory 或 size memory 把 memory 限定为 m8/16/32/64. intel 把 offset 叫 memory, 把 segment:offset 叫 far pointer; 但有些人把 offset 也叫 pointer, 所以 memory 或 m8/16/32/64 也叫 pointer, ptr 用来限定 memory 的长度, 也可以叫 pointer.

http://www.phatcode.net/res/223/files/html/Chapter_8/CH08-4.html 看完网页后想看看是啥书, 一看是 Randall Hyde 的 the art of assembly language programming. 记得以前照该书写过一些练习代码, 现在找不到了. Randall Hyde 把限定长度的操作叫 coercion. 后来有一天看到 https://stackoverflow.com/questions/8857763/what-is-the-difference-between-casting-and-coercing, accepted answer 说 word ptr 这样的操作叫 conversion 或 cast, 就是不叫 coercion, coercion 是 implicit conversion. 再看其他答案是各有说法. 看来 coercion 在不同人那里有不同定义.

### 标签

写代码时经常需要 jump 到某条语句. 假设跳到第 42 句, 这位置 42 很可能在写代码时多次变动, 就要不断修改代码里的 42; 42 是 1 个位置, 代码里往往用到多个位置, 每个位置都需要此过程. 这纯粹是不必要的麻烦, 程序员希望用占位符表示位置, 由程序做符号到位置的转换工作. 最好是 cpu 能理解符号以完成转换, 但 intel cpu 不理解, 那就只能靠汇编器. masm 支持汇编里已有的标签概念, 可以用符号标记位置, 汇编时用符号处的位置替换符号以组成 cpu 指令.

masm 的 @@ 定义一个只能通过其上下的 @f (forward, 下一个 @@) 和 @b (back, 上一个 @@) 访问的标签

写代码时还经常需要保留一些内存位置往里面放计算结果. intel 没有这种语法, 只能用指令占据内存位置, 并安排代码不执行这块占据的内存; 用指令占据的内存值只能是指令, 即没办法初始化以这种方式保留的内存. masm 的 data allocation 语法 `type initializer [, initializer]...` 用 db, dw, dd 等保留一些可以初始化的内存. 要引用保留的内存可以往它前面放一个标签, masm 规定标签和 data allocation 不能在同一行, 例子

```
someWords:
    word 3 dup (21) ; 用 21 初始化 word, 重复 3 次. 假设 (1, 2, 3), 就是把 1, 2, 3 重复 3 次得到 9 个 word
```

标签和保留内存都是很实用的功能, 不是 masm 的发明但 masm 支持它们, 至此可以说很完美. 但 masm 可能是想在汇编的基础上创造一种静态强类型的语言, 可能还试图兼顾同其它 microsoft 语言的 "互操作性", 即在这个语言里调用那个语言定义的函数, 于是在标签和保留内存的基础上做了大量狗尾续貂的工作, 得到了既难以理解又难以使用的变量和静态类型. 作为发明变量和静态类型之前的热身工作, masm 首先给标签添加了很多限制.

label, assemblies to `immediate`, syntax:

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
- 远调用 段内 近过程? masm 把 `call cs:pn` 汇编为 `push cs; call rel16`, 把 `call ds/es/ss:pn` 汇编为 `call ptr16:16`
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

标签代表的位置汇编时就确定了, 代码假设了运行时的地址, 非常死板. 汇编得到的可执行文件只能加载到固定地址, 如果希望的内存位置已经存放了别的东西就无法加载. 解决办法有 2 个部分

- 段. 汇编时不固定段地址, 在文件头里保存段的信息, 加载器填充这些信息所以程序运行时能知道实际的段地址
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

org n 的作用

- 把其后的语句放在可执行文件的代码部分的第 n 字节; 若造成该语句后移, 用 0 填充之间的部分; 相应调整标签的值
- 多个源文件, 或生成的不是 com 时 org 可能偏大 http://support.microsoft.com/kb/39441/en-us
- 生成 com 文件 && 使用了 org && 其后的语句被 end 标为起始地址 && 将生成 > 256 字节的可执行文件<br>
    则删除起始地址前面的内容, 参考 [起始地址](#起始地址)/com 文件的起始地址

### 变量, 静态类型

标签是代表地址的符号, 汇编时替换成 offset, offset 是数字而不是名字, 要使用 offset 处的值而不是 offset 就得用方括号标记标签, masm 不支持这种写法. 如果把标签替换成 [offset], 那从代码的角度看标签就是变量了. masm 就这样定义了变量, 并趁机把变量叫 data label, 标签改叫 code label. masm 尽量把 code label 汇编为没有方括号的 offset (但当做不到的时候, 它给你胡乱生成一条语句), data label 汇编为方括号括起来的 offset. 因此 masm 标签基本不需要写方括号, 写了也基本没用, 这就是前面说 masm 不支持 [代码标签] 这种写法的原因. `seg lb` 和 `offset lb` 用于获取数据标签的地址, 没有获取代码标签处值的语法. code label 的汇编结果是,

```
; ml -Foout\ dd.msm -Feout\ -AT

xxx segment
    assume ds: xxx
s:
    mov ax, s             ; MOV AX,0000
    mov ax, [s]           ; MOV AX,0000
    mov ax, 1[s]          ; MOV AX,0001
    mov ax, [s + 1]       ; MOV AX,0001
    mov ax, [s + bx + 1]  ; MOV AX,[BX+0001]    <- this is  somewhat  absurd
    mov ax, [s + dx + 1]  ; MOV DI,[BX+SI+0001] <- this is absolutely absurd
xxx ends
end s
```

data label, a.k.a. variable, assemblies to `[immediate]`, syntax:

- `[name] type initializer [, initializer]...`
- `name label qualifiedtype`

首先注意到两个意料之外的东西: `label` 和 `qualifiedtype`, 待会儿再说, 先说第 1 种定义方法. 假设有 `i byte ?`, masm 说变量 i 具有类型 byte, 结果是

- `mov ds:200, byte ptr 3`, 200 换成 i 后可以写 `mov i, 3` 或 `mov i, byte ptr 3`
- `mov ds:200, word ptr 3`, 200 换成 i 后必须把 cast 放 i 前面, 不能写 `mov i, word ptr 3`
- `mov ax, ds:200` 毫无歧义, 但 200 换成 i 后要写 `mov ax, word ptr i`

定义变量时使用了 type, 使用变量时 masm 查看代码是否写了 cast, 写的话就保留, 不写的话加上 type ptr, 得到 type ptr [offset], 可以看到 masm 记录了变量的长度和偏移. 它的目的不是长度匹配时省一个 `长度 ptr`, 而是长度不匹配时产生汇编错误. 这纯粹是制造困难, 但该困难顶了个迷惑性的名字让人捉摸不透, 不敢妄下定论: 静态类型. 拥护静态类型的人很多.

既然数据标签 name 表示符号形式的地址 name 指向的值, 那么 [name] 就表示 name 指向的值指向的值, 即先取 name 处的值作地址, 再取该地址处的值; 和寄存器用法一致. 但在 masm 中 [name] 和 name 一模一样都是 [offset], 可能是因为 masm 考虑了 intel 的 "一句话只有一次内存访问", 没办法在一句话里先取 name 处内存的值, 再取该值处内存的值, 所以 name = [name] = [[[[name]]]], [ax] = [[[[[[[[[[[ax]]]]]]]]]]]; 而 ax 是寄存器地址, 不读内存, [ax] 先读寄存器再读内存, 所以 ax != [ax]. 这给程序员带来极大困扰, 无论能否意识到, 它都会在每次遇到时实实在在消耗一部分脑力:

- 有时需要方括号有时不需要; 带方括号时可能没用上, 没带时可能用上了
- 一个强调静态类型, 动不动汇编错误的语言, 在方括号上这么随意?

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

masm 说 xxx typedef ptr 定义的新类型 xxx 是 ptr void; masm 用 void 或 ptr void 表示自己可以和其它 microsoft 语言交互; 纯粹的累赘概念, 看看就行. intel 说 m16 保存 word, m16:16 保存 ptr16:16 而不仅仅是 dword, 这种不对称的定义也造成了混乱. masm near ptr 的 offset 就是 m16, far ptr 的 offset 是 m16:16; near ptr byte/word/... 和 far ptr byte/word/... 的 offset 没有相应的 intel 操作数类型. masm 不根据 ptr 类型产生汇编错误, 所以任何地方都不需要 ptr; word 和 dword 分别对应 near 和 far ptr 就行, 这一点做得对.

`npt typedef near ptr byte; t1 npt 1111h`, 设 t1 的地址是 ds:10, 有

- 变量 t1 = 偏移 10; 10 在 16 位模式里是 imm16 和 m16
- masm 认为 0x1111 是 near ptr, 即 offset; offset 是 word 所以 t1 汇编为 word ptr [10]; intel 认为 m16 指向的 0x1111 是 word
- masm 认为 0x1111 指向 byte, intel 没有这想法

`fpt typedef far ptr byte; t2 fpt 2222bbbbh`, 设 t2 的地址是 ds:20, 有

- 变量 t2 = 偏移 20; 20 在 16 位模式里是 imm16 和 m16:16
- masm 认为 0x2222bbbb 是 far ptr; far ptr 是 dword 所以 t2 汇编为 dword ptr [20]; intel 认为 m16:16 指向 far pointer
- masm 认为 0x2222bbbb 指向 byte, intel 没有这想法
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

masm expression     | `qh sizeof`
-|-
lengthof variable   | array.length
sizeof   variable   | lengthof array * sizeof element
sizeof   type       | bytes of type
length   expression | `deprecated` value of the dup operator in first initializer, 1 if first initializer doesn't use dup
size     expression | `deprecated` (length array) * sizeof type

```
xxx segment
ar1 word 3 dup (?), ?, 2 dup (?),
?
ar2 word ?, ?, 3 dup (?)

lo1 textequ % lengthof  ar1
so1 textequ % sizeof    ar1
l1  textequ % length    ar1
s1  textequ % size      ar1

lo2 textequ % lengthof  ar2
so2 textequ % sizeof    ar2
l2  textequ % length    ar2
s2  textequ % size      ar2

echo .    lengthof     sizeof    length       size
% echo ar1         lo1         so1         l1          s1
% echo ar2         lo2         so2         l2          s2
xxx ends
end

ml -Zs dd.msm

.    lengthof     sizeof    length       size
ar1         7         14         3          6
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

定义符号的文件里写 `public 符号`, 表示该符号可以在其他文件里使用; 使用符号的文件里写 `extern 符号:类型`, 表示该符号一部分 (类型部分) 在本文件里定义以帮助汇编器生成指令, 另一部分在将其声明为 public 的文件里定义.

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

显然代码里写 ret 时汇编器无法确定是 near 还是 far, 于是 masm 定了 2 个规矩

1. 修改 ret. `pn proc near` 里, ret = retn (c2 or c3); `pf proc far` 里 ret = retf (ca or cb); proc 外看 memory model.
1. 不修改 retn, retf. 程序员用 retn, retf 明确指出需要 near 或 far return

### option

#### language

```
; option language
;   默认值是 none, 但不能指定 none, 不知道如何重置为 none
;   syscall 没有名字装饰
;
; 没有通过 option 或 proc 指定 language 时不能指定 proc 的参数列表
;
; lib.exe 自动补上文件的 .lib 和 .obj 扩展名. 下面两句一样
;   lib out\dd.lib /nologo +out\dd.obj, out\dd.lst;
;   lib out\dd     /nologo +out\dd,     out\dd.lst;
;
; ml -nologo -Foout\ dd.msm -c
; lib out\dd /nologo +out\dd, out\dd.txt;

xxx segment
s:

namec1      proc c          ; _namec1
namec1      endp

_namec2     proc c          ; __namec2
_namec2     endp

_namec3     proc            ; _namec3
_namec3     endp

names1      proc stdcall    ; _names1@0
names1      endp

_names2@4   proc stdcall    ; __names2@4@0
_names2@4   endp

_names3@4   proc            ; _names3@4
_names3@4   endp

xxx ends
    end s
```

### assembler hints

前面多次看到为帮助汇编器生成正确的 opcode 需要程序员写额外的词, 这里总结见过的词.

intel

- [] 表示其后或其中的内容是 offset
- size ptr 或 size 表示其后的用 [] 修饰的 offset 指向的内存长度是 size; 放在不是 offset 前也不一定报错. 汇编器能确定 size 时, 或不是内存时也都可以指定, 汇编器忽略匹配的指定, 对不匹配的报错. `mov ax, word 3` 可以, `mov ax, byte 3` 不行
- far 修饰前面的 mnemonic 而不是后面的 operand, 表示选择 jmp, call 的 m16:16/32 版本, `les far ax, [100]`, `les ax, far [100]` 都是语法错误
- imm:imm 表示 far pointer

masm

- assume 其中一个作用是减少 masm 生成的段寄存器重写

## tools

### 常用命令

`dosbox-x` copy & paste by dosbox-x menu<br>
main > shared clipboard functions > copy all text on the dos screen<br>
main > shared clipboard functions > pasting from the clipboard

`dos` redirect ml outputs to file out\fff<br>
`> out\fff ml -Zs dd.msm`

`macos` view binary. hexdump, od, xxd<br>
`xxd out/dd.obj`

`windows powershell` view binary<br>
`format-hex out/dd.obj`

### 管道, 重定向, 参数, 返回值

管道和重定向是标准输入输出 stdin 和 stdout 的特性. stdin 和 stdout 的默认值在命令行中是 con, 代表键盘和屏幕. 在命令行中把 command 的 stdio 从默认值修改为文件时要使用重定向语法, 下列特殊文件名代表的不是文件而是硬件设备,

file    | meaning                               | .
-|-|-
con     | console                               | echo hello > con
prn     | printer, usually map to lpt1          | type file.txt > prn
aux     | auxiliary serial device, usually com1 | copy con aux
nul     | null device                           | echo text > nul
lpt1    | parallel port 1                       | also lpt2, lpt3
com1    | serial port 1                         | also com2, com3, com4

在命令行中把 cmd1 的输出从默认值修改为 cmd2 的输入时要使用管道语法即 `cmd1 | cmd2`. 管道从左往右单向传递文本.

可以看到重定向和管道非常相似, 重定向把 stdio 改为 file, 管道改为 command. 如果能定义一个特殊文件名代表 command 或命令代表 file 则两种语法可以合并, 从而把占用的 3 个符号 `<>|` 缩减为 1 个. 比如假想的语法 `command | tocommand file`, tocommand 是把文件视作命令的命令, 把接收到的文本保存至文件; 或 `cmd1 > tofile cmd2`, tofile 是特殊文件名, 把其后的 command 作为文件串接到 stdio. file 和 command 的一个区别是 file 不产生输出所以无法继续串连. 多任务系统下管道的各个 command 可能同时运行.

程序的参数指命令行参数. 参数和返回值是另一种形式的输入输出, 不涉及 stdio 因而不能参与到管道中.

### debug.com

`real mode debugger` `8086`

`debug /?` 打印 debug 的命令行参数帮助; 在 debug 里执行 `?` 打印 debug 命令帮助.

.|.|.
-|-|-
arguments   | number        | 输入输出的数字都是 16 进制, 不带前后缀, 忽略 h 后缀
|           | address       | `112233` or `2244:112233` or `ds:123`
|           | addresses     | `address address ...`
|           | list          | `11 22 33 ...` or `'abc...'` or `"abc..."`
|           | range         | `address1 address2` or `address l n`; n = 0 means 0x1,0000 = 64k
`a` command |               | 不认识 8086 之外的指令和数据类型如 dword, fword, qword, tbyte
|           |               | `dd`, `dw`, `;`
|           |               | 重写段寄存器时必须段名紧跟冒号放语句前,  `es: mov ax, [] 100`
hotkeys     | Cntl-NumLock  | 暂停, 比如打印一大块内存时暂停; 对 g 无效
|           | Cntl-Break    | 停止并返回 debug; 对 g 无效

a (assemble) 的方括号语法明显指出了 (左) 方括号只是用来标记操作数的类型, 单个符号就能起到此作用, 不需要引号或括号.

```
inputs                                              outputs
bx si [] 3                                          [3]
3 bx [] si                                          [si + 3]
bx [] si [] 1 [] 2 [] 3; bx [si] [] [] [] 1 2 3 []  [si + 6]
[] bx si 3; [] bx + si + 3; 3 [] bx si; 3 [sibx     [bx + si + 3]
```

尝试发现算法可能如下,

1. 找左方括号, 沿途累加遇到的数字, 检查语法
1. 找到左方括号, 继续走到行尾, 沿途累加遇到的数字, 记下 bp, bx, di, si, 检查语法
1. 记下来的数字和寄存器排序, 用加号连接, 外面套上方括号, 替换原语句

samples

- `g =100 102 105` 从 cs:0x100 开始执行, 在 0x102, 0x105 处放置断点; 断点至多 10 个, 任一断点命中都清除所有断点, 不命中不清除. 开始和断点位置都要写对, 如果指向指令的中间就要么执行错误的指令要么命中不了断点
- `g =132 132` 暂停在 cs:0x132, 经常用来跳过代码里的 int 3. 只有 g 能设置断点, 也就只有 g 能停到某条语句, p 和 t 都不能
- `t =120 5` 从 cs:0x120 开始执行 5 条指令后暂停
- `n file` then `l` 加载文件, 也可以用命令行 `debug file`, 加载后 (bx << 16) + cx = 程序长度/要写入的文件的字节数, both 0 if no file. 用 debug 执行的程序结束后想再次执行需要 reload, 即再次执行 l

### ml.exe

#### 源文件编码

masm 的 source-charset 固定为 ascii; 串原样放入二进制, 相当于 execution-charset = source-charset; 无需转义字符, 因为指定字符时既可以用字面量也可以用数字, 字符字面量就是其 ascii 值.

#### 所有命令行选项

ml 开关 (选项, 参数), 包括 ml -link 后的参数, 起始字符是 - 或 /, 开关区分大小写; link 只能是 /, 不区分大小写.

*写这里时发现 dosbox 中命令超过一行而换行后, 没法把光标移回到上一行*

**对单个文件生效的开关必须规定个位置否则 file1 -xxx file2 不能确定 -xxx 作用于谁**

masm 规定

- 对单个文件生效的开关放文件前
- 命令行开关和文件名都可以用引号括起来
- 双引号内 "" 解释为 "
- 以 - 打头的 token 是命令行开关; 因此文件名如果类似 -coff, 汇编时要写成类似 ml ./-coff

masm 命令行开关有 5 种作用范围, 有些开关自己就具有 2 种范围

范围 | 开关 | masm 版本 | 解释
-|-|-|-
1 following token           | -unrecognized switch | ml 6, 14; ml64 14
all following tokens        | -link     | ml 6, 14; ml64 14
1 following file            | -Fo       | ml 6, 14; ml64 14
all following files         | -coff     | ml 6, 14; ml64 14 | ml 14 default
|                           | -D        | ml 6, 14; ml64 14
|                           | -EP       | ml 6, ?           | 比 -Zs 做的事更少, 不生成 obj
|                           | -omf      | ml 14             | ml 6 imply. prevents link like -c
|                           | -Zi       | ml 6, ?
|                           | -Zs       | ml 6, 14; ml64 14 | absorbs -c, 不生成 obj
all  or 1 following files   | -nologo   | ml 6, 14; ml64 14 | or before first file. 不确定, 因为 ml 的 logo 只显示 1 次
all and 1 following files   | -Fl       | ml 6, ?           | 其后所有文件都生成 .lst 文件, 指定的路径只对其后 1 个文件有效
all files                   | -AT       | ml 6
|                           | -c        | ml 6, 14; ml64 14
|                           | -Fe       | ml 6, 14; ml64 14

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

#### 单个命令行选项

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

/AT 和 .model tiny 的区别

> Microsoft MASM 6.1 Programmer's Guide.pdf，p56，Tiny Model<br>
/AT does not insert a .MODEL directive. It only verifies that there are no base or pointer fixups, and sends /TINY to the linker.

#### 汇编和连接错误

masm611/errmsg.txt 解释了部分汇编错误.

#### error A2076: jump destination must specify a label

A direct jump's destination must be relative to a code label. masm 不汇编 jmp immediate, 只汇编 jmp label, 但汇编结果还是 jmp immediate.

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

### cv, lib, pwb, qh

`cv.exe` `real mode debugger` code view, 调试器.

key      | f4                    | f5 | f6                       | f7           | f8    | f9          | f10
-|-|-|-|-|-|-|-
function | view output (hide cv) | go | move focus among windows | go to cursor | trace | break point | step

调试时要看源代码而不是反汇编需确保两点,

- ml 参数 -Zi
- 代码段用 code 类, 比如 xxx segment 'code'

`lib.exe` 估计用来生成静态库, 不清楚. `lib xxx, xxxpubs;` 把静态库的全局符号输出到文本文件, xxx 默认扩展名 lib. dos 没有 dumpbin.

`pwb.exe` programmer's workbench, ide. 可以创建项目, 它调用 nmake 生成项目文件. 只接受 .asm 不接受 .msm 所以不用它.

`qh.exe` quick help.

key         | arrow     | backspace | i         | t                 | x
-|-|-|-|-|-
function    | scroll    | back      | history   | table of contents | exit

### wlink.exe

生成 wlink 的帮助文件: `echo g | wlink ? > out\wlink`. 之所以用管道是因为 wlink 即使在输出重定向时仍需要按一下键.

wlink 调用 dos4gw, dos4gw 的命令行只接受很少的字符, 参数随便长一点儿就报错. 要用 dos4gw 加载 wlink 就必须把参数放 directive 文件里 - 它把参数或选项或开关叫 directive. 管道 `echo args | wlink` 能传递更多字符但受命令行长度限制. directive 里,

- `#` 开始单行注释
- 值可以使用环境变量. 假设有 set libdir=\test, 则 library %libdir%\mylib = library \test\mylib
- 值可以用逗号隔开也可以在花括号里用空格隔开, 即 file first,second,third,fourth = file {first second third fourth}

根据 (watcom)/docs/lguide.pdf, wlink 启动时先从环境变量的 `path` 里找一个特殊的 directive 文件, 处理完该文件后才处理其他输入. 这个文件的名字由环境变量 `wlink_lnk` 指定, 如果不存在就使用 `wlink.lnk`, 如果不存在就结束查找. directive 文件默认扩展名 `lnk`.

wlink 要求代码段和栈段具有相应的类, 即 `ccc segment 'code'` 和 `sss segment 'stack'`.

### wd.exe

要使用鼠标需要 dosbox 捕获鼠标, 鼠标点击很迟钝没必要用. 很多加速键和 cv 一样, 因为加载了 cvkeys.dbg.

key      | alt-space                | ctrl-tab      | . or alt-f10  | f3
-|-|-|-
function | menu of current window   | switch window | context menu  | assembly/source

action item in the main menu is identical to the context menu.

```
wd 配置文件里, 窗口的高度 1 行 = 416, 数字是 x, y, width, height
display watch   /close 0,0,5000,4160

(watcom)/docs/wd.pdf
    4.1 Debugger Windows
    4.5.1 Default Accelerators
```

## dos apps

### 16-bit dos app in masm

masm 要求源文件具备两个要素: end 和非空的 segment; 这两样东西对生成可执行文件毫无贡献, 理由是:

- 如果程序啥都不做, 源代码应该啥都不需要写, 因此是个空文件, 而不是一个非空段 + end
- 非空段有意义的部分是使段非空的文本, 而不是段定义

masm 要求源代码从两个无用的结构开始, 预示了此后的编程中会遇到很多 masm 有意或无意制造的障碍.

新建一个空文件 dd.msm 用 masm 汇编看看会发生什么.

`ml -Foout\ dd.msm -Feout\` 输出
```
error A2088: END directive required at end of file
```
\* *-Fo 指定 ml 生成的 obj 的路径, 可以是目录; -Fe 指定连接得到的文件的路径, 可以是目录. 开关和参数间可以有空格*

#### end 的两个作用

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

- -AT 让 ml 给 link 传 /tiny, 从而生成 com 文件
- 不想看版权消息可以 `ml -nologo -Foout\ dd.msm -Feout\ -AT -link -nologo`

可以看到 link 报告了 1 个错误. 此处的亮点是尽管有连接错误, 仍生成了可执行文件.

masm 认为程序应该有栈, 因此没有 -AT 时 link 还警告 L4021; -AT 没有此警告是因为 com 就 1 个段, 栈也使用此段. 错误说没定义段, 没说什么 "非空段" 所以下面代码似乎就够了?

```
xxx segment
xxx ends
end
```

汇编发现错误消息完全没变, 因此光有段不行, 很可能还得是非空段. 是否还记得一开始说的 "毫无贡献"?

#### 非空的段

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

#### the program

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
- 根据 8086/lab.md/stack 知道 exe 运行时栈顶的 word 被改为 ff ff; 让 exe 代码和栈共用一个段时为防止覆盖那里的指令需要弄点填充字节. 写填充字节时为了确定填几个, 试了几个数值, 发现至少得 4 字节程序才正常退出, 但在 debug 里执行不正常; 用 debug 一看发现不仅是修改了最后两字节. debug out\dd.exe 时, 查看内存没啥问题; t 执行一句后再查看, 前 10 字节内容都变了. 加大填充的长度发现最后 10 字节会被修改; 隐约记得以前见过这情况. 因此要在 debug 里也能正常退出得填充 10 字节 (那填充 4 字节算不算正确?). mov ax, 4c00h int 21h 是 5 字节, 加上 10 个填充字节等于 15 字节. 为了对齐到 word 再加 1 字节, 填充了 11 字节, 否则起始 ip 是 1 而不是 0; 尽管我不知道起始 ip 是 1 有啥问题. [栈的后 10 字节](#调试器修改栈的后-10-字节)

上面啥都不做的 masm 16 位 dos 程序包含 4 或 5 个要点

- 为正常汇编, 写 masm 要求的 end
- 为正常连接, 写 link 要求的 none empty segment
- 为正常连接, 写 link 需要的 end begin, 不写的话是警告而不是错误
- 为正常运行, 写 dos (?) 要求的填充字节. 不把代码放栈里时可忽略本条
- 为正常退出, 写 dos 要求的返回语句

#### 起始地址

起始地址决定程序开始时 cs 和 ip 的值.

**连接器如何确定起始地址**

ml 找源文件中用 end 指出的标签, 把它写到 obj<br>
\* *验证: 用 ml -c 汇编两个 obj 文件, 一个指定起始地址一个不指定, 比较它们*<br>
link 从 obj 找出 ml 写入的起始标签作起始地址. 起始地址写入 exe 文件头的 cs 和 ip; com 没有文件头, 连接器检查起始标签是不是第一句, 不是的话警告 l4055<br>
\* *验证: 用 link out\dd.obj; 均不传 /tiny 参数, 分号表示省略 link 的其他参数, 分别连接两个 obj 文件*

ml64 不允许 end 后跟入口, 但和 ml64 配套的 link 有 /entry 开关<br>
\* *link 5.31.009 Jul 13 1992 没有 /entry 开关*<br>
\* *ml64 汇编的代码一般不用自己写入口, 入口由使用的库定义, 就像 c 程序不定义入口, 而是写一个 crt 规定的回调函数 main*

用 ml64 汇编的代码也可以用下面语法把入口写入 obj<br>
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

### 从 psp 获取程序的命令行参数

```
; int21h/ah51h 和 int21h/ah62h 也可以获取 psp, 结果放在 bx
; int21h/ah51h - Get Current Process ID (Undocumented DOS 2.x) https://stanislavs.org/helppc/int_21-51.html
; int21h/ah62h - Get PSP address (DOS 3.x) https://stanislavs.org/helppc/int_21-62.html
;
; 将使用 dos api 打印字符. dos api 集中在 int 21h, DOS Fn 09H 指 int21h/ah9
;
; int21h/ah9 遇到 $ 就结束打印所以不能用它, https://stackoverflow.com/questions/481344/dollar-terminated-strings 指出
; int21h/ah2
; int21h/ah40h, file handle = 1
; int29h, undocumented
;
; int21h/ah40h
; AH    40H
; BX    file handle. 1 = Standard Output Device
; CX    number of bytes to write (Note: 0 means truncate the file)
; DS:DX address of a buffer containing the data to write
; Returns:
; AX    number of bytes actually written, error code if CF is set to CY
;
; 这里使用了标签, 汇编为 .com, 没有使用 org 256. 程序正常运行, 为什么?
; 因为标签仅用在 jne 里, jmp immediate 汇编为 jmp rel, relative offset 和起始地址无关
;
; ml -Foout\ dd.msm -Feout\ -AT
;
; 测试
; out\dd     ddd  --x
;     ddd  --x

xxx segment
s:
    mov ah, 40h
    mov bx, 1
    xor cx, cx      ; debug.com puts app length to dx:cx on start. only matters when using debug
    mov cl, ds:80h  ; or ds:[80h]. masm 认为 [80h] 是 80h (注), 而 ds:80h 是 [80h]
    mov dx, 81h
    int 21h

    ; always compare the return value of AX (number of bytes written) to CX (requested write size)
    cmp ax, cx
    mov ax, 4c00h
    jne bx_set      ; at this point bx = 1
    mov bx, 0

bx_set:
    or  ax, bx
    int 21h
xxx ends
    end s

注: 后来看到这帖子
https://stackoverflow.com/questions/25129743/confusing-brackets-in-masm32
masm 根据它的规则修改你的代码
- variable name               去除所有方括号, 替换为 [offsetof var], 认为是变量的值
- constant, const expr, imm   去除所有方括号, 认为是立即数
- register                    不修改方括号
某个角度看也合理, 比如 t1 = 1 和 t2 dw 2, t1 在代码中替换成 1, t2 在代码中替换成偏移比如 27,
由于使用 t1 和 t2 时都想使用他们的值, 所以 t1 应该生成 1, t2 应该生成 [27]. 当然不合理的地方多了,
比如 [t1] 应该是 [1] 而不是仍然生成 1
```

下面分别用 int21h/ah2, int21h/ah9, int21h/ah40h, int29h 打印命令行参数.

```
; 程序开始时打印提示消息, 然后用 int21h/ah1 接收一个用户输入,
; 如果认识该输入, 调用相应的输出方法; 否则调用默认的输出方法
;
; ml -Foout\ dd.msm -Feout\ -AT

xxx segment
    org 256     ; 为了让 com 中的标签具有正确偏移, 在这里统一 +0x100
s:
; int21h/ah9
; AH    09H
; DS:DX address of a string terminated with a '$' (ASCII 24H)
; Returns: none
    mov ah, 9
    mov dx, msg ; msg is defined at bottom
    int 21h

    mov ah, 1   ; int21h/ah1, wait key stroke, return al = character read
    int 21h     ; 它回显字符一定输出至屏幕, 不考虑重定向, 显然和 debug 用的不是一个 api

    mov ah, 2   ; int21h/ah2, output dl, returns none
    mov dl, 13  ; 13 = \r
    int 21h
    mov dl, 10  ; 10 = \n
    int 21h

    xor cx, cx  ; save length of args to cl
    mov cl, ds:80h

    cmp cl, 0   ; the following do-while loops rely on cl > 0
    jne @f

exit:
    int 20h

@@: cmp cl, 7fh ; 参数长度至多 0x7e = 126, 由于要用 jb 所以和 127 比较
    jb  @f
    mov cl, 7eh

; at this point al = user input letter, cl = len of args, ds = seg psp

@@: cmp al, 'a'
    je  a
    cmp al, 'A'
    je  a

    cmp al, 'b'
    je  b
    cmp al, 'B'
    je  b

    call int29h
    jmp exit

a:  call ah2
    jmp exit

b:  call ah40h
    jmp exit

; int21h/ah2
; dl = character to write
; returns none
ah2:
    ; destroys ax, bx, cx, dx
    mov ah, 2
    mov bx, 81h
@@: mov dl, [bx]
    int 21h
    inc bx
    loop @b
    retn

; int21h/ah40h
; bx = file handle; 1 = the same device (such as the screen) as service ah=9
; cx = the number of bytes to be written
; ds:dx points to the data to be written
ah40h:
    mov ah, 40h
    mov bx, 1
    mov dx, 81h
    int 21h
    retn

; int29h 和 int21h/ah2 区别是 console redirect 对 int29h 无效
; al = character to output
int29h:
    ; destroys ax, bx, cx
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

### kb-q72848

https://jeffpar.github.io/kbarchive/kb/072/Q72848/ execute int 20h from exe by far return

该程序用 retf 跳至 psp:0, retf 会设置 cs, 然后执行 psp:0 的 int 20h

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
; 执行 psp 前两字节, 即 int 20h 的几种方式
; 执行 psp 前两字节意味着 cs = seg psp, 满足 int 20h 对 cs 的要求
; 需要在汇编时用 -D 定义宏用于代码里的条件汇编, 宏名的作用见注释
; 生成后在调试器里执行, 查看执行结果

    ifdef   comJmp0
    ; ml -DcomJmp0 -Foout\ dd.msm -Feout\
    ; psp 开始处的 1 个 word 是 int 20h, 跳到 psp:0 执行它

    .model  tiny
    .code
l0: org     256
s:  jmp     l0      ; masm 不支持 jmp immediate

    elseifdef comRetn
    ; ml -DcomRetn -Foout\ dd.msm -Feout\
    ; 程序进入时 sp 开始处的 1 个 word 是 0, retn 会跳到 psp:0
    ; 这导致 sp 不等于进入时的 sp

    .model  tiny
    .code
s:  retn

    elseifdef wrongComRetf
    ; ml -DwrongComRetf -Foout\ dd.msm -Feout\
    ; 错误的写法. retf 使用栈上的 2 个 word 而栈上只有 1 个是正确值

    .model  tiny
    .code
s:  retf

    elseifdef exePushPushRetf
    ; ml -DexePushPushRetf -Foout\ dd.msm -Feout\
    ; kb-q72848, 保存 seg psp 和 0, 然后 far return
    ; 注意, 这个生成的是 exe

    .model  huge
    .stack
    .code
s:  push    ds      ; 开始时 ds = es = seg psp
    xor     ax, ax
    push    ax
    ; ...           ; some codes
    retf            ; 用 pop ip pop cs 实现 jmp psp:0

    elseifdef exeJmpFar
    ; ml -DexeJmpFar -Foout\ dd.msm -Feout\
    ; 跳到 psp:0. psp 是运行时得到的值所以不能 jmp ptr16:16 只能 jmp m16:16, 这个 memory 使用栈
    ; 和 exePushPushRetf 基本一样除了 1. 也可以不用栈, 2. 如果用栈则导致 sp 不等于进入时的 sp

    .model  large
    .stack
    .code
s:  push    ds
    xor     ax, ax
    push    ax
    mov     bp, sp
    jmp dword ptr [bp]

    else
    ; ml -Foout\ dd.msm -Feout\
    ; 这个分支生成的程序只是打印提示, 让重新编译

te  textequ <please specify the code path when compiling, e.g. ml -DexePushPushRetf...>
    echo
%   echo    te

    .model  tiny
    .data
%s1 byte    'te&$'
    .code
    org     256     ; .data 放到了 .code 后面所以里面的变量仍然有正确的偏移
s:  mov     dx, offset s1
    mov     ah, 9
    int     21h
    int     20h

    endif
    end s
```

### mz com ?

MZ = 4d 5a = dec bp pop dx, 很正常的指令. 如果 com 文件以这两条指令开始会有啥后果? 下面程序生成后运行正常. 可是给 msg 加几个字符后就啥都不打印了. 试了一会发现只有 msg 长度小于 11 才会打印. 不明白.

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

Bound Range Exceeded, 5, Fault, #BR. fault 的 return address 是产生 fault 的语句的地址. fault 没有固定处理方式. cpu 的本意是让纠正产生 fault 的语句后重试; 其它常用方式是如果代码提供了异常处理程序则调用它, 否则结束程序. 由于我不知道如何修改产生 fault 的语句, 并且似乎默默地纠正 #br 不算好做法, 所以采用异常处理程序.

- https://stackoverflow.com/questions/71070990/x86-division-exception-return-address
- https://stackoverflow.com/questions/33029457/what-to-do-in-interrupt-handler-for-divide-by-zero

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

### 调试器修改栈的后 10 字节

应该是调试器修改了栈的后 10 字节. 本节程序运行时, 除了 com 修改的最后 2 字节外栈保持原样; 在调试器里一次执行完, 输出也正常; 单步执行能看到栈被修改了, 并且程序设置栈的后 10 字节也不生效, 看调试器修改栈的规律似乎是把设置的位置改到其他位置了, 后 10 字节保存了那个位置的偏移. 实验表明程序启动时栈有下列规律

```
                com             exe with stack size 0x20
normal          ... 00 00       ... a9 01 ...
in debugger     ... 00 00       ... ff ff ...
                    ^                     ^
sp              0xfffe                  0x20
```

因为要测试 com 和 exe, 就想能不能写一个既能生成 com 又能生成 exe 的代码. 这种代码用处不大, 因为受 com 的限制代码不能使用段名, 浪费了 exe 使用段的能力. 已知

- masm 标签的值在汇编时确定, org 256 只在生成 com 时有用, 编写和汇编时不知道生成 com 还是 exe, 全靠假定
- com 起始 cs = ds, 运行时所有标签的偏移 + 256
- 段的地址在加载时确定, 是正确的值, 但 com 不能使用段名, error A2118: cannot have segment address references with TINY model, 所以既不能用段名也不能把标签放另一个段里 jump 过去

com 修改了代码的偏移, 从段地址入手给 ds + 16 只能解决一部分问题

code | solved | why
-|-|-
`[label]`   | yes | label 是 m16, (ds + 16):offset 是正确的地址
`jmp label` | yes | label 汇编为 rel16, 不参考起始地址
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
    je exe

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
    jne @f ; ax = 0 is exe
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
    je @f

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

### bios vga fill

- https://stackoverflow.com/questions/47941699/using-32-bit-registers-in-masm-without-changing-the-default-segment-definition-s

这个程序改变 video mode. cv out\dd.com 调试时会提醒没加 -s 参数, 不加此参数后续的显示会不正常.

```
; 用 vga 调色盘 64 号填充 320x200 256-color vga 屏幕, 按任意键退出
;
; ml -Foout\ dd.msm -Feout\ -AT

xxx segment
s:
    mov ax, 0f00h   ; int10h/ahfh query current video info
    int 10h         ; al = current video mode, bh = current active video page (0-based)
    mov bl, al      ; save to bl

    mov ax, 13h     ; int10h/ah0 set video mode
    int 10h         ; al = 13h, graphic 320x200 256-color vga

    mov di, 0a000h
    mov es, di
    xor di, di      ; es:di -> vga pixel buffer

    mov ah, 64      ; vga palette index 64
    mov al, ah      ; will use stosw
    mov cx, 32000   ; 320x200 pixels = 320x100x2 bytes = 320x100 words
    cld             ; ensure that string ops auto-increment
    rep stosw       ; fill the screen

    xor ax, ax      ; int16h/ah0 read (wait for) next keystroke
    int 16h

    xor ax, ax      ; int10h/ah0 set video mode
    mov al, bl      ; al = previously saved
    int 10h

    int 20h
xxx ends
    end s
```

### struct, local, assume bp: ptr records

- 32 位代码碎片 https://stackoverflow.com/questions/56506869/how-to-initialize-a-local-struct-in-masm-assembly

```
Records     STRUCT
data1       DWORD   ?
data2       DWORD   ?
data3       DWORD   ?
data4       DWORD   ?
Records     ENDS

p1  PROC
    ; allocate space on the stack for a variable called rec1
    LOCAL rec1: Records

    ; initialize the structure fields with the values 1,2,3,4
    mov rec1.data1, 1
    mov rec1.data2, 2
    mov rec1.data3, 3
    mov rec1.data4, 4

    ret
p1  ENDP

p2  PROC
    LOCAL rec1: Records

    ; use LEA to get the effective address of the variable on the stack
    lea eax, [rec1]

    ; use ASSUME to apply a pointer to a structure type to eax
    ASSUME eax: ptr Records

    mov [eax].data1, 1
    mov [eax].data2, 2
    mov [eax].data3, 3
    mov [eax].data4, 4

    ret
p2  ENDP

p3  PROC
    ; create an array of 4 Records
    LOCAL rec1[4]: Records

    ; Compute address of third Record structure in array
    lea eax, [rec1]
    ASSUME eax: ptr Records
    add eax, 2 * (SIZEOF Records)

    ; can also be
    ; lea eax, [rec1 + 2 * (SIZEOF Records)]
    ; ASSUME eax: ptr Records

    ; Initialize the the third Record structure
    mov [eax].data1, 1
    mov [eax].data2, 2
    mov [eax].data3, 3
    mov [eax].data4, 4

    ret
p3  ENDP

; Structures at Global Scope
; declare and initialize them this way
;
; .DATA
; rec2 Records <1,2,3,4>
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
