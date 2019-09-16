
; 汇编语言 2e.pdf
; 王爽
; p193, 检测点 9.1
; check point
;
; 虽然检测点也能翻译为 Detection point, 不过我觉得这里的检测偏重检查.

; (1) 若要使程序 jmp 之后 cs:ip 指向第一条指令则 data 段中应定义那些数据?
; 因为是个段内转移, 我定义了个双字, 用零初始化. 当汇编成 com 时肯定会出错, 怎么办?
; 不过按照这个程序的写法汇编出来的 com 也没法正常运行.

assume  cs: code

data    segment
        dword   0
data    ends

code    segment
start:  mov     ax, data
        mov     ds, ax
        mov     bx, 0
        jmp     word ptr [bx + 1]

code    ends
end start
