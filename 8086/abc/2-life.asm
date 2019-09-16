
; 如果是写个程序转为机器码后直接让 cpu 执行 (无配合), 那写法比较随意, 没有什么顾忌
; 如果是写个程序在操作系统中执行, 就得遵照操作系统的规定
;
; ====================
;
; https://en.wikipedia.org/wiki/Program_Segment_Prefix
;
; psp = Program Segment Prefix
; is a data structure used in DOS systems to store the state of a program.
; resembles the Zero Page in the CP/M operating system.
;
; on entry
; ds = es = seg psp
;
; other means to get psp
; int21h/ah51h or int21h/ah62h, result is in bx
;
; dos 1
; - 退出需要调用 int20h 或 int21h/ah0, 两者功能一样, 前者机器码较短
; - int20h 的参数是 cs, 要求 cs 指向 psp 所在的段 (seg psp)
; - psp 的前两个字节是 int20h
; - 程序开始时 ds = es = seg psp
; 所以退出的办法是开始时 push ds/push 0, 结束时 retf, push 0 可以是 xor ax, ax/push ax
; - com 在保证 cs = seg psp 时可以直接 int20h 或者 int21h/ah0
;
; dos 2+
; - 添加了退出方式 int21h/ah4ch, 该 api 不要求 cs = seg psp
;
; https://stackoverflow.com/questions/12591673/whats-the-difference-between-using-int-0x20-and-int-0x21-ah-0x4c-to-exit-a-16
; 这里说用 retn 结束时不需要 push 任何东西, 因为程序开始时的栈顶是 0
; 我也记得 com 文件初始 sp 是 fffe, 而 fffe 和 ffff 都是 0
; 因此, com 程序设计的退出办法应该是在 cs 未改变的前提下结束时直接 retn, 这导致 ip = *(word*)0xfffe
;
; http://www.tavi.co.uk/phobos/exeformat.html
; 非 dos 不一定有 psp
;
; 下面程序打印命令行参数, cp/m, dos 称作 command tail
; 修改了 psp 的一个字节, 改为 $
;
; ml -AT -Foout\ 8086/abc/2-life.asm -Feout\
;
; 命令尾如果全是空白字符则长度是 0, 否则长度包含空白
; out\2-life     ddd  --x
;      ddd  --x
;
; debug out\2-life.com
; 反汇编内存中 psp.com 程序 100h 开始的 20h 字节
; -u
;
; cv out\2-life.com
;
; ====================
;
; 启动
; dos 程序启动时, com 的 ip = 起始地址 = 100h; exe 的等于代码指定的起始地址
;
; http://www.fysnet.net/yourhelp.htm
; The following are the register values at DOS .COM file startup in the given DOS brands and versions
; ...
;
; http://www.tavi.co.uk/phobos/exeformat.html
; register contents at program entry:
;     Register    Contents
;     AX          If loading under DOS: AL contains the drive number for the first FCB 
;                 in the PSP, and AH contains the drive number for the second FCB.
;     BX          Undefined.
;     CX          Undefined.
;     DX          Undefined.
;     BP          Undefined.
;     SI          Undefined.
;     DI          Undefined.
;     IP          Initial value copied from .EXE file header.
;     SP          Initial value copied from .EXE file header.
;     CS          Initial value (relocated) from .EXE file header.
;     DS          If loading under DOS: segment for start of PSP.
;     ES          If loading under DOS: segment for start of PSP.
;     SS          Initial value (relocated) from .EXE file header.
;
; 退出
; dos 程序退出时要调用规定的 dos 函数; windows 程序退出时要调用 ExitProcess
;
; - int20h          dos 1+, int21h/ah0 的别名, 机器码更短, 用来放在 psp 的前两个字节
; - int21h/ah0      dos 1+, 参数 cs = seg psp
; - retn/retf       dos 1+, 意图是执行 psp 的前两个字节 (int20h)
; - int21h/ah4ch    dos 2+, 无参数
;
; ml -DcomRetn -Foout\ 8086/abc/2-life.asm -Feout\
;
; -DcomRetn     注意到初始 sp=fffe, fffe 和 ffff 处都是 0, 这时 retn 可以使用这两个字节当 ip,
;               若又有 cs = seg psp 则 retn 导致执行 psp 0000 处开始的机器码.
;               不知道这方法是否可靠, 即不知道栈是否总是保留两个字节的 0
; -DcomRetf     错误的写法, retf 使用栈上的 2 个 word 而栈上只有 1 个. 执行后 dosbox 不接受输入, 只能重启 dosbox
; -DexePushRetf 正常做法, 保存 seg psp 和 0, retn 总是能执行. 当然更正常的做法是 int21h/ah4ch

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
end start

注 1:
后来看到这帖子
https://stackoverflow.com/questions/25129743/confusing-brackets-in-masm32
masm 根据它的规则修改你的代码
- variable name               无论方括号, 一律认为是变量的值
- constant, const expr, imm   无论方括号, 一律认为是立即数
- register                    不修改方括号的意义
这个编译器会修改你的代码. 我能理解错不全在 masm, 你看它修改的大都是他自己规定的玩意儿: 变量, 常量,
常量表达式, 除了立即数. 因此要说代码被修改了你自己也有问题, 因为你用它提供的结构了; 我想很难反驳吧?

