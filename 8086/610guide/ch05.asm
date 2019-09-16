
; ml -Foout\ 8086/610guide/ch05.asm -Feout\

xxx segment

; p???/p86  Declaring and Referencing Arrays
;
; 定义变量和定义数组语法一样, 给一个值是变量, 给多个值是数组: 变量名 值的长度 值, 值, ...
; 值 = 数字, ?, 数字 dup (值, 值, ...)
;   数字 = 数字, 常量表达式, 字符串
;   ? = 不初始化
;   n dup () = 把括号里的列表重复 n 次
; 数组每个元素长度一样; 元素长度不一样的可能也叫数组, 但无法用这个语法去定义
;
; masm 把变量名叫做 data label, 不是 code label, 基本就是为了配合 lengthof, sizeof
; data label 虽然也标记一个偏移, 但取这个偏移需要用操作符 offset
; 用 code label 的话 abc word ? 可以这样写. masm 要求 abc: 和 word ? 之间有换行
; abc:
; word ?

; 变量
var1 word ?

; 数组
arr1 word 1, 2, 3, 4, 5
arr2 word 7 dup (1, 2, 3 dup (1, 2, 3, 2 dup (4)), 2 dup (?), 5, 6, ?, ? , 9)
arr3 byte 1, ?, "ab", lengthof var1, 3 dup ("you mean on master branch??", lengthof arr1, 8), ?, "abcddddd"

lenarr2 textequ %(lengthof arr2)
%echo lenarr2 ; 168

; 这个错误看起来还挺像回事
; error A2071: initializer magnitude too large for specified size
;arr4 word "abc"

; 一旦你习惯上面的编译错误, 到这里就栽跟头了
arr5 byte "abc"
; masm 把 byte 弄成了个特例, 因为用字符串初始化 byte 数组时没有歧义, 而初始化 word 数组时不知道该几个字符对应 1 个 word

; masm 里 arr2[17] 代表 arr2 + 17, c 里也是如此
; 不一样的地方在于 masm 里是 17 个字节, c 里是 17 个元素长度

; 数组初始化列表可以放在下一行, 此时上一行必须以逗号结尾
arr7    byte    1, 2, 3,
                4, 5

; 数组后可以放匿名内存, lengthof 正确的认为匿名内存不属于数组
arr8    byte    1, 2, 3
        byte    4, 5

lenarr7 textequ %(lengthof arr7)
lenarr8 textequ %(lengthof arr8)
%echo lengthof arr7 = lenarr7, lengthof arr8 = lenarr8 ; = 5, 3

; 单引号和双引号用于表示字符串字面量, 这字面量里唯一的转义字符是和外面的引号相同的两个引号, 表示一个引号
; 即, 2 个单引号在单引号括起来的字符串里表示 1 个单引号, 在双引号括起来的字符串里表示 2 个单引号
; 这一点都不好, 干嘛要转义呢? 如果用了这个转义, 字符串的内容就取决于引号的种类了, 简直垃圾

str1 db 'a''bc'
str2 db "a''bc"

if lengthof str1 eq lengthof str2
    echo same length
else
    echo different length
endif


; p???/p90  Processing Strings
; rep movs, xlat
;
; string = 串, character string = 字符串
; 串指令操作串, 串的元素可以是这 4 种: byte, word, dword, qword
;
; intel 设计的操作串的指令写法上有 2 个特点
; 1. 内存到内存; 尽管实际还是要用寄存器或缓存中转 - 这是个进步
; 2. 指令前加 rep 表示反复执行, rep op dst, src; 操作数长度还是原来那几种 - 这是原地踏步
;
; rep, repe = repz, repne = repnz
; movs, stos, cmps, lods, scas, ins, outs
; std -> df = 1; cld -> df = 0
;
; rep movsd 的大致过程是
; 1. [ rep ]    如果 cx = 0, 下一条指令
; 2. [ rep ]    service any pending interrupts
; 3. [movsd]    把 ds:si 的一个 dword 拷贝至 es:di
; 4. [movsd]    (si, di) += (df ? -1 : 1) * (4 = bytes of dword)
; -. [  -  ]    scas, cmps 根据对比结果设置 zf
; 5. [ rep ]    --cx, 不修改标志寄存器
; 6. [ rep ]    goto 1 *
;   * also checks zero flag for REPZ/REPNZ
;
; rep 专用于串, 后跟若干串指令之一, 隐含使用 cx; movs 隐含使用 direction flag (df)
; repz, repnz 是干嘛的? cmps, scas 执行时设置 zf 表示匹配, 但这些指令退不出 rep
; repz 除了 rep 的退出条件 (cx = 0) 还查看 zf, 如果 zf = 0 也退出; repnz 在 cx = 0 或 zf = 1 时退出
;
; movsb = movs byte ptr, movsd = movs dword ptr, ... 区别是 movs 需要写参数 dst 和 src,
; 可以重写 src 的段寄存器; movsb, movsw, movsd, movsq 不要参数, 隐含使用 ds:si 和 es:di
;
; cmps 把俩字符相减. 字符一样的话结果等于 0, zf = 1; 否则 zf = 0
;
; 为什么是 src = ds:si, dst = es:di; 而不是 src = ss:si, dst = ds:di? 下面是我猜的
; - ss 用来保存栈基址了, 想用的话得在 rep 之前保存栈基址, 之后恢复, 麻烦
; - movs dst, src 有 2 个内存操作数, 1 读 1 写; intel 想让读的那个用 ds, 他说: d 指 data 而不是 dst
; - intel 认为能让 src 用 si, dst 用 di, 已经是 "很用心了的在做了"
; 说真的, dst, src 能对上 ds, ss 确实是巧合, ds 的 d 和 ss 的 s 分别代表 data, stack
; 不过 di 的 d 和 si 的 s 确实分别代表 destination 和 source. i 代表啥? i 代表 index
;
; p???/p94  Searching Arrays
; 这里说 scas 比较 es:di 和 cx; 错误, 应该是比较 es:di 和 al/ax/eax; 给出的代码没错


start:

; 根据命令行参数决定调用哪个函数, 这些函数都是书里的原文; 根据命令行选择调用哪个, 是自己写的
; xlat
;
; 提供命令尾 (命令参数) 时, psp:80h 为其长度, psp:81h 为其拷贝
; 初始时 ds = es = seg psp

; 从 psp:80h 处取命令尾长度
        xor     bx, bx
        mov     bl, ds:[80h] ; masm 认为 [80h] 是 80h

; 长度是 0 或者大于 7eh 时都不处理
        cmp     bl, 0
        jz      exit ; 未提供命令尾
        cmp     bl, 7eh
        ja      exit ; 命令尾长度大于 7eh, psp 保存不下

; 找命令尾的第一个非空格
        mov     cx, bx      ; 命令尾长度
        mov     di, 81h     ; 命令尾地址
        mov     al, " "     ; 找空格
        cld                 ; 顺着串的方向 (地址从低到高)
        repz    scasb       ; 只要是空格就继续

; 全空格的话结束时 zf = 1 (zr), 但全空格时命令尾长度算 0, 在前面就跳走了, 不会执行这里
;       jz      exit        ; 没找到非空格

; scas 找到时 di 指向匹配的下一个字符, 这里要让他指回匹配的字符
        dec     di

; 由于串指令修改 di 所以保存至 bx, 这就假设后面的代码不会修改 bx
; 函数调用里修改 bx 了, 但调完函数就退出了, 不再使用 bx
        mov     bx, di

; 把 cs 里定义的 function name 逐一和 es:di 比较, 其中 es = seg psp
; 正常情况下需要循环, 但那就要把函数地址放到一个表里面, 所以这里只是用一系列 if

; 先令 ds = cs, ds 在后面都不会修改; si 要修改以指向各个函数名
        mov     ax, cs
        mov     ds, ax

call1:  mov     si, offset fname1
        repz    cmpsb
        jnz     call2
        call    $xlat
        jmp     exit

call2:  mov     di, bx
        mov     si, offset fname2
        repz    cmpsb
        jnz     call3
        call    $fname2
        jmp     exit

call3:

; 两个 label 的差等于啥? echo 输出 43, 在 debug 里查看 call3 和 call2 之间代码的字节数 = e = 14
; 也不应该期望这个差值是字节数吧? 因为字节数编译之后才知道
; 在 p???/p187 Defining Repeat Blocks with Loop Directives 中, offset l1 - offset l2 称为 address span
diff2?3 textequ % call3 - call2
%echo "diff2?3" is diff2?3

        mov     ax, call3
        sub     ax, call2
        nop             ; 执行上面的代码, 结果也是 ax = 0xe = 14
        nop


exit:   mov     ax, 4c00h
        int     21h

fname1  byte    "xlat"
fname2  byte    "xxx"

; p???/p94  Translating Data in Byte Arrays
; xlat = xlatb, 隐含使用 al. 如果带参数, al = [参数 + al]; 否则 al = [ds:bx + al]

; Table of hexadecimal digits
hex     BYTE    "0123456789ABCDEF"
convert BYTE    "You pressed the key with ASCII code "
key     BYTE    ?, ?, "h", 13, 10, "$"

$xlat:  ; Get a key in AL
        mov     ah, 8
        int     21h

        mov     bx, OFFSET hex      ; Load table address
        mov     ah, al              ; Save a copy in high byte
        and     al, 00001111y       ; Mask out top character
        xlat

        mov     key[1], al          ; Store the character
        mov     cl, 12              ; Load shift count
        shr     ax, cl              ; Shift high char into position
        xlat

        mov     key, al             ; Store the character
        mov     dx, OFFSET convert  ; Load message
        mov     ah, 9               ; Display character
        int     21h                 ; Call DOS
        ret

$fname2:ret

xxx     ends

stack   segment stack
        db      16 dup (?)
stack   ends

        end     start



p???/p95    Structures and Unions
p???/p96    Declaring Structure and Union Types

name {STRUCT = STRUC | UNION} [[alignment]] [[,NONUNIQUE ]]
fielddeclarations
name ENDS

p???/p105   Declaring Record Types
就是 c 的位域, masm 里在全局定义, c 在结构里定义



