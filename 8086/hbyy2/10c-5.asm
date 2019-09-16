
; 汇编语言 2e.pdf
; 王爽
; p205, 检测点 10.5
; check point
;
; (1) 下面的程序执行后 ax 中的数值是多少？（注意：用 call 指令的原理来分析, 不要在 Debug 中单步跟踪来
; 验证你的结论. 对于此程序, 在 Debug 中单步跟踪的结果不能代表 cpu 的实际执行结果.）
;
; 解：
; 这道题目让从原理分析, 并在括号里指出实际结果和理论结果不一致! 我记得在书本刚讲到栈时提出了个问题, 问
; 为什么设置 sp 会改变作为栈的数据区的内容. 当时就没有给出解答, 而是说谁能答出来谁就对计算机有一定
; 的了解, 并说不知道也没关系, 在以后的学习中会学到这点. 直到现在, 这个问题再次出现了, 我还是没有搞明白
; 为什么设置 sp 会改变作为栈的数据区的内容.
;
; 书上没有说为什么实际结果会和理论结果不一致, 我只能假设设置 sp 没有改变代码中 stack 段的内容.
; 代码中的两处注释标明了两条指令的地址.
;
; http://www.myexception.cn/assembly-language/800842.html
; zara(Kyrie eleison)說的沒錯。
; 樓主，既然你在看王爽的書，如果這個地方現在實在弄不清楚。到後面的中斷的那一章你就會明白的！！
;
; 第一次执行 call 之前 stack 段中的内容是
; 00 02 04 06 08 0a 0c 0e 0f - 序号
; 00 00 00 00 00 00 00 00 00 - 内容
;
; 第一次执行 call 时, call 的下一条指令的地址入栈并跳到 [0eh] 指出的 word 处, stack 段中的内容是
; 00 02 04 06 08 0a 0c 0e 0f - 序号
; 00 00 00 00 00 00 00 11 00 - 内容
;
; 第二次执行 call 时跳到 [0eh] 指出的 word 处, 即 0011
; 然后 inc ax 三次, mov ax 一次, ax = 4c00h.

        assume  cs: code

stack   segment
        word    8 dup (0)
stack   ends

code    segment
start:  mov     ax, stack           ; 0605:0000
        mov     ss, ax
        mov     sp, 16

        mov     ds, ax
        mov     ax, 0
        call    word ptr ds:[0eh]

        inc     ax                  ; 0605:0011
        inc     ax
        inc     ax
        mov     ax, 4c00h
        int     21h
code    ends
        end     start
