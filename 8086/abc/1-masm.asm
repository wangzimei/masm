
; ml -Foout\ 8086/abc/1-masm.asm -Feout\

xxx segment stack
xxxs:
mov ax, 4c00h
int 21h
byte 11 dup (?)
xxx ends
end xxxs

汇编语言没有标准语法, 语法都是汇编器规定的

masm 要求源文件具备两个要素: end 和非空的 segment; 这俩东西对生成可执行文件毫无影响

1. 要有 end, 否则
error A2088: END directive required at end of file

end 结束源文件的功能完全没用

end 有个可选参数, 用以指出程序的起始地址, 这形成另一个怪异语法: 在源文件结束处用 end 指出起始地址
- 让我想到那著名的 "点击 '开始' 以关机"
- 我现在还解释不了微软这种奇怪的传承; 另一个传承是 msdn 那废话流文档, "extremely unhelpful"
- 说 "传承" 是因为我不大相信这些是同一个人所为. 也可能仅仅是巧合, 根本不存在传承

end 后跟起始地址的作用类似 link 开关 -entry, 确实是必要的功能, 只是语法奇葩.
- link 5.31.009 Jul 13 1992 没有 -entry 开关
- ml64 不允许 end 后跟起始地址, 但和 ml64 同时代的 link 有 -entry 开关

为了满足 masm 就写个 end, 此时程序是这样, 就一句话

end

2. 要有非空的段, 否则
LINK : error L4076: no segments defined
虽然有连接错误, 仍然生成了 exe, 不知道咋回事

不是 com 的话还想要栈, 否则警告
LINK : warning L4021: no stack segment

那只好定义一个非空的段, 可以把此段标记为 stack 以消除连接警告, 此时程序是这样
* segment 的语法是啥? 看 8086/610guide/ch02.asm

xxx segment stack
db 1
xxx ends
end

编译为 com 时警告
LINK : warning L4055: start address not equal to 0x100 for /TINY
编译为 exe 时警告
LINK : warning L4038: program has no starting address

com 这个警告是错的. 不指定起始地址等于指定第 1 条指令
com 文件前 100h 是 0, 运行时操作系统把前 100h 填入 psp; 所以在 com 中第 1 条指令就是 0x100
如果指定的起始地址不是程序第一条语句, 则警告说的没问题; 但此时也可以在起始地址前放 org 100h, 后果是
起始地址前面的东西在运行时被 psp 覆盖

因此要用 end 指定个标签. 把 db 1 改为正常的返回语句 *, 得到的完整程序就是文件一开始的程序
作为起始地址的标签定义到栈里面了; 一般不会往栈里放代码, 但也没啥问题, 想一想 com

* 根据 8086/hello/stack.asm 知道 exe 运行时栈顶的 word 被改为 ff ff; 为防止覆盖上面的指令, 弄点填充字节
    写填充字节时为了确定填几个, 试了几个数值, 发现至少得 4 字节程序才正常退出, 但在 debug 里执行不正常,
    用 debug 一看发现不仅是修改了最后两字节. debug out\1-masm.exe 时, 查看内存没啥问题; t 执行一句后再查看,
    前 10 字节内容都变了. 加大填充的长度发现最后 10 字节会被修改; 隐约记得以前见过这情况, 具体忘了
    因此要在 debug 里也能正常退出, 得填充 10 字节 - 那填充 4 字节算不算正确?
    mov ax, 4c00h/int 21h 是 5 字节, 为了对齐到 word, 填充了 11 字节, 否则起始 ip 是 1 而不是 0
    起始 ip 是 1 有啥问题? 不知道
    TODO: 探究这个修改最后 10 字节的问题

end 后面必须是标签不能是立即数 (字面量), 否则
error A2094: operand must be relocatable
把变量名放 end 后面得到
error A2095: constant or relocatable label expected






ptr - coercion

http://www.phatcode.net/res/223/files/html/Chapter_8/CH08-4.html
看完网页后想看看是啥书, 一看是 Randall Hyde 的. 我记得以前照该书写过一些练习代码, 现在找不到了
the art of assembly language programming

ptr 究竟是 intel 还是 microsoft 发明的? 网上没找到答案, x86 指令集里没有但反汇编里有, 所以应该是 intel

x86 (伪?)指令 ptr 用来解决这种问题: mov [bx], 5 时不知道 bx 指出的是 byte, word 或者其它
所以用额外的指令 ptr 指出内存的长度: mov word ptr [bx], 5
- 注意这里 intel 又开始取名字了. 没必要, mov2 [bx], 5 就行了. 理由:
    1. mov word ptr 不是 mov; 2. byte word dword 有完没完?

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
可以看到
- ptr 可以写在任意操作数前面, 实际总是作用于内存
- (16 位 cpu?) 只能 ptr 为 byte, word; dword, tbyte 变成 byte; qword 变成 word. 这个完全看不出规律
- 数字在内存中的字节顺序

masm 要求显式重写段寄存器, mov [200], word ptr 3 -> mov ds:[200], word ptr 3
用处不大, 访问内存默认的段寄存器是 ds, 不用 ds 时必须加前缀所以没啥歧义; 显式写出可能更没歧义?

masm 的变量, 假设有 I byte ?
- 原来需要 ptr 的指令现在不需要了, mov [200], byte ptr 3 -> mov I, 3
- 原来毫无歧义的语句现在必须用 ptr 添加重复信息了, mov ax, [200] -> mov ax, word ptr I
情况 1 省了个 ptr, 但要求变量定义, 这再次表明: 静态类型增加程序员负担

; 假设有 xxx segment, model = tiny; tiny 是 com, 有 cs = ds = ss
assume ds:xxx ; 如果没有这句, masm 会在下句的前面用 cs 重写段寄存器, 机器码 2e
mov ax, word ptr i

ptr 是啥意思? 指针 pointer? 上面的用法和指针有啥关系? word ptr [addr] 实在是看不出和指针有啥关系
你说 addr 是个指针? 那在 ptr 作用于 addr 这个指针前也先对指针用 [] 解除了引用啊, ptr 并没有作用于指针
如果是 [word ptr addr] 还像点样子

可能是为了凑点关系, masm 决定搞一个指针类型, 也使用关键字 ptr - 给 ptr 添加一个和指针有关系的用法
这样一来 ptr 就有两种不同的用法了: 一种是 word ptr, 另一种是 ptr word... 就问你佩不佩服?
TODO: 待续

Randall Hyde 把这个操作叫 coercion; 后来有一天我搜索发现这种意见: 要么叫 conversion 要么叫 cast, 就是不叫 coercion
不愧是 c++: 不断的制造惊喜, 不断的否定你过往的经验
https://stackoverflow.com/questions/8857763/what-is-the-difference-between-casting-and-coercing
conversion  implicitly/explicitly changing a value from one data type to another
coercion    implicit conversion
cast        explicit type conversion, may be a re-interpretation of a bit-pattern or a real conversion


% - expansion

- 按当前的基数对常量表达式求值, 把得到的数字转为字符串
- 做为一行的首个非空白字符时, 展开该行的文本宏和宏函数; 用于 echo, title, subtitle, .erre 等把参数一律视为文本的指示.
    一律 - 包括 %, 常量表达式 - 视为文本, 就没法在它们的参数里调用宏或对表达式求值; 但又有这种需求, 于是 masm 说,
    既然宏展开符号 % 放 (比如 echo) 后面没戏, 那就放前面吧; 常量表达式的话你们就在外面赋值给文本宏, 别在里面求值了
    masm 居然没有选择添加或规定转义字符, 真乃一大幸事

masm 有个以 % 打头的指示, %out; 后来加了个 echo 用于取代其功能, 但 %out 那独树一帜的名字始终盘旋于我脑海之中
%out 是个 4 字符的信物, 它就是能把 % 用作自己名字的一部分. 这 microsoft 做事也是随心所欲, 佩服!


assume - assumption

为什么 microsoft 会发明这个关键字? 大概是在用 x86 编程时看到了太多的假设, 隐含, 暗指
TODO: 列出 intel 有哪些假设

没啥意义的东西, masm 提供这个指示用来克服 masm 自己制造的困难







