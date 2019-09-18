
- [intel 的毛病](#intel-的毛病)
- [masm 的毛病](#masm-的毛病)
- [masm 命令行 - 观察双引号导致的一些结果](#masm-命令行---观察双引号导致的一些结果)




## intel 的毛病

### 错误的名称

mov 其实是 copy/set

### 多余的逗号

mov a, b 里面那个逗号是干嘛使的?

- 为了支持 mov a, offset b? 那 mov a offset b 有歧义吗?
- 为了支持 mov a, max b, c? 那 mov a max b  c 有歧义吗?
- max 参数个数不固定? 那有没有逗号有区别吗?

### 寄存器

说起来容易做起来难: 寄存器就不该存在

以我的理解 von Neumann 1946 说的计算机的的存储部分就是内存, 包括寄存器, 缓存, 内存, 磁盘等; 按数组使用.
    intel 的寄存器是内存, 但从命名到操作都不像数组, 各种专用寄存器. 这里肯定有 "硬件限制" 的因素, 比如
- 地址线决定地址空间容纳不下那么多外设
- 地址映射需要执行时间 - 其实还是有地址翻译
- 不想添加指令转换模块 - 后来还是有了微指令; 我能理解 "后来毕竟是后来, 发展有过程"

1. 用 ax, bx, cx 而不用 reg1, r2, r3
1. 指令隐含使用寄存器. 可能因为, 比如 loop, 硬件少, 提供不了专用寄存器, 又不想加一条指定使用哪个通用寄存器的语句
    不过到底啥是隐含使用我现在有点动摇了. 说 loop 隐含使用是因为那行语句里看不到 cx, 但类似 jz 这种, 算隐含使用 zf 吗?
    只要把操作数放到那行语句里, 不管是放名字里还是放参数里, 都不是隐含使用吗?
1. x87, 扩展指令, 几乎就是独立的 cpu, "胶水双核" 在那个年代就开始搞了; 每个扩展都多出一套专用寄存器
1. 从 x87 开始有从名字转向数字的趋势, st0 ~ st7; 从 avx512 开始有合并寄存器的趋势, simd 也可以操作通用寄存器

### 对齐

这东西也不是经常遇到; 但最好是别露出来, 让人根本遇不到


## masm 的毛病

### 虎头蛇尾的 comment 语句

本来自定义括号是非常好的功能, 想想 c++ 原始串字面量和 form data multipart delimiter,
结果它给做成只能是一个字符. 我这决不是以现在的眼光看古人, 这当时就应该做到, 他也算不上古人.
comment 开始和结束所在的整行都算注释, 这也体现了 masm 的一个特点: 处理单元是行.

### 怎么 echo 分号?

### vararg

宏的变参 vararg 保存的是处理过的参数, 意味着 <1, 2, 3> 用具名参数接收时是 1 个参数, 用 vararg 参数接收时是 3 个


## masm 命令行 - 观察双引号导致的一些结果

```
下面既有从本目录编译的, 也有从 cmdln 目录编译的; 由于比较长所以单独放一节

编译时 ml 6 打印下列错误信息; ml 14 类似, ml 6 的 A4017 = ml 14 的 A4018; 可以看到
- 如果 /Zs 没有完全匹配, 则开始尝试, 原则是单独字母 (Z) + 其它字母
- s 首先被忽略了; 这算啥逻辑? 是不是把单个字母后面的 1 个字母视作空白给忽略掉?
- 尝试时不是 1 次减 1 个字母, cmd, off 等类似 "关键词", 一次减掉
- 这种减法也是奇怪, 如果我弄个以 s 结尾的文件名, 是不是最终它能匹配上 Zs? 没试

ml "-Zs" "cmdln/abc"
 Assembling: cmdln/abc

ml "-Zs " "cmdln/abc"
warning A4017: invalid command-line option : /Z
 Assembling: cmdln/abc

ml "-Zs   " "cmdln/abc"
warning A4017: invalid command-line option : /Z
warning A4017: invalid command-line option : /Z
warning A4017: invalid command-line option : /Z
 Assembling: cmdln/abc

ml "-Zs "abc"
warning A4017: invalid command-line option : /Z abc
warning A4017: invalid command-line option : /Zabc
warning A4017: invalid command-line option : /Zbc
warning A4017: invalid command-line option : /Zc
fatal error A1017: missing source filename

ml "-Zs "coff"
warning A4017: invalid command-line option : /Z coff
warning A4017: invalid command-line option : /Zcoff
warning A4017: invalid command-line option : /Zoff
fatal error A1017: missing source filename

ml "-Zs ""abc"
warning A4017: invalid command-line option : /Z "abc
warning A4017: invalid command-line option : /Z"abc
warning A4017: invalid command-line option : /Zabc
warning A4017: invalid command-line option : /Zbc
warning A4017: invalid command-line option : /Zc
fatal error A1017: missing source filename

ml "-Zs ""coff"
warning A4017: invalid command-line option : /Z "coff
warning A4017: invalid command-line option : /Z"coff
warning A4017: invalid command-line option : /Zcoff
warning A4017: invalid command-line option : /Zoff
fatal error A1017: missing source filename

ml "-Zs "cmdln/abc"
warning A4017: invalid command-line option : /Z cmdln/abc
warning A4017: invalid command-line option : /Zcmdln/abc
warning A4017: invalid command-line option : /Zln/abc
warning A4017: invalid command-line option : /Zn/abc
warning A4017: invalid command-line option : /Z/abc
warning A4017: invalid command-line option : /Zabc
warning A4017: invalid command-line option : /Zbc
warning A4017: invalid command-line option : /Zc
fatal error A1017: missing source filename

ml "-Zs "cmdln/coff"
warning A4017: invalid command-line option : /Z cmdln/coff
warning A4017: invalid command-line option : /Zcmdln/coff
warning A4017: invalid command-line option : /Zln/coff
warning A4017: invalid command-line option : /Zn/coff
warning A4017: invalid command-line option : /Z/coff
warning A4017: invalid command-line option : /Zcoff
warning A4017: invalid command-line option : /Zoff
fatal error A1017: missing source filename
```




