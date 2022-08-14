
## asmcommunity-25659.asm

http://www.asmcommunity.net/forums/topic/?id=25659

文章给出的生成选项是 `ml /c /omf 16bit.asm`, `link 16.obj,,,,,`, 使用的是 16 位 link, link 后面那些逗号告诉连接器省略的参数用默认值. link 这种传参的方式叫跳过逗号, 不指定参数等于使用参数的默认 (缺省) 值. 如果全都用默认值而写了一堆逗号, 在 link 命令行可以用 1 个分号代替.

`ml -Foout\ dd.msm -Feout\`

```
.model tiny
.code

; 原文没有 org 100h, 那么做为 .model tiny, offset sHelloWorld = 源文件中看到的偏移,
; 比运行时 sHelloWorld 的偏移少 0x100, 结果是输出一堆乱码后跟 Hello, World :)
; 不用 org 100h 而写 lea dx, sHelloWorld 也不行, 因为虽然 lea 在运行时求地址但
; sHelloWorld 在编译时就替换成了 (错误的) 偏移
org 100h

start:

push cs ; 没必要
pop ds  ; 没必要

mov dx, offset sHelloWorld
mov ah, 9
int 21h

mov ax, 4c00h
int 21h

ret ; 没必要

sHelloWorld BYTE "Hello, World :)", 13, 10, '$'
end start
```

## hello world < 20 bytes

http://stackoverflow.com/questions/284797/hello-world-in-less-than-20-bytes

这里的 3 段代码是不是要用 masm 5 或者更早的版本编译? 用 6.11 编译时明显漏洞百出.

3 个都是 `ml -Foout\ dd.msm -Feout\`

执行输出一堆乱码并死机

- 没指出起始地址, 显然会把 db 当作指令执行
- int21h/ah9 的 dx 是通过 inc dh 设置的? 有啥玄机?

注释指出编译时用 /AT, 实际上有了 .model tiny 就不需要 /AT

```
; ML /AT HELLO.ASM

        .MODEL  TINY
        .CODE
CODE    SEGMENT BYTE PUBLIC 'CODE'
        ASSUME  CS:CODE,DS:CODE
        ORG     0100H
        DB  'HELLO WORLD$', 0
        INC DH
        MOV AH,9
        INT 21H
        RET

; 原文没有这句话, 结果是 fatal error a1010: unmatched block nesting: _TEXT
; 既然用了 .code 就不需要再定义 code segment, .code 定义一个叫 _text 的段
code    ends
end
```

下面是 BoltBait 给出的第二个代码, 执行时在一些乱码后跟 HELLO WORLD

这些人调用 int21h/ah9 都不设置 dx? 可能是为了短代码?

Jonas Gulle 在下面的回帖中给出了一段代码，并且说它 Not "well behaved", but better than BoltBaits which can randomly end prematurely if there is a '$' in the PSP. This program will output "Hello World" among with some junk characters. 不过 Jonas Gulle 的代码我看不懂

```
        .MODEL  TINY
        .CODE
CODE    SEGMENT BYTE PUBLIC 'CODE'
        ASSUME  CS:CODE,DS:CODE
        ORG     0100H
        MOV    AH,9
        INT    21H
        RET
        DB    'HELLO WORLD$'
CODE    ENDS
end
```

John T

终于有个正常运行的程序了, 但是个 exe, 560 字节

```
title Hello World
dosseg
.model small
.stack 100h
.data
hello_message db 'Hello World',0dh,0ah,'$'
.code
main  proc
    mov    ax,@data
    mov    ds,ax
    mov    ah,9
    mov    dx,offset hello_message
    int    21h
    mov    ax,4C00h
    int    21h
main  endp
end   main
```

小于 20 字节的难度我想主要在 hello, world! 已经占了 13 字节, 剩 6 字节的代码把它打印出来.

如果是正常的程序, 设置 dx 3 字节 ba0801, 设置 ah 2 字节 b409, int 21h 2 字节 cd21, int21h/ah9 需要串以 $ 结束, 1 字节, retn 1 字节 c3, 共需要 9 字节.

这如何做到? 网上看了一些例子, 基本是删除串的标点, 省出 2 字节, 得到 20 字节的程序, 那就仍然是正常程序, 但没有小于 20. 我感觉不正常的程序能小于 20. 下面依次是正常程序和网上的例子.

```
; ml -AT -Foout\ dd.msm -Feout\

xxx segment
s:  mov dx, msg [100h]
    mov ah, 9
    int 21h
    retn
msg:
    db "hello world$"
xxx ends
    end s
```

https://www.gnostice.com/nl_article.asp?id=225&t=The_Smallest_Hello_World_Program_At_20_Bytes

和上面的程序一样, 但不用 masm 编译, 用 debug 生成 com.

```
A
MOV AH,9
MOV DX,108
INT 21
RET
DB 'HELLO WORLD$'

R CX
14
N MYHELLO.COM
W
Q
```

## fire by The Bitripper

https://thestarman.pcministry.com/asm/fire/Fire.html

原来的文件名叫 brancom9.asm, 忘了原因了.

`ml -Foout\ dd.msm -Feout\`

```
; Created by The Bitripper
; < bitripper (at-sign) enigma.demon.nl >

.MODEL TINY
.386
.CODE
ORG 100h
Main:

                mov     al,13h
                int     10h

                xor     ax,ax

                mov     di,offset flames
                mov     cx,(flh*flw)
                rep     stosw

                mov     dx,3c8h
                out     dx,al
                inc     dx

                dec     cl
Check_Red:
                cmp     bl,60
                jae     check_green
                add     bl,4
                jmp     check_number
Check_Green:
                cmp     bh,60
                jae     check_number
                add     bh,4
Check_Number:
                mov     al,bl
                out     dx,al
                mov     al,bh
                out     dx,al
                xor     al,al
                out     dx,al
                loop    check_red

Do_Fire:        mov     cl,spots
Put_Spots:

                add     [randseed],62e9h
                add     byte ptr [randseed],62h
                adc     [randseed+2],3619h

                mov     ax,[randseed+2]
                xor     dx,dx
                mov     bx,flw
                div     bx

                mov     si,dx
                dec     byte ptr [flames+((flh-1)*flw)+si]
                loop    put_spots


                mov     si,offset flames+1+flw
                mov     di,offset new_flames+1

                mov     cl,flh-2
Avg_Col:        mov     dx,flw-2
Avg_Row:
                mov     bl,[si-flw]

                mov     al,[si-1]
                add     bx,ax

                mov     al,[si+1]
                add     bx,ax

                mov     al,[si+flw]
                add     bx,ax

                shr     bx,2
                mov     [di],bl

                inc     si
                inc     di
                dec     dx
                jnz     avg_row

                inc     si
                inc     si
                inc     di
                inc     di
                loop    avg_col

                mov     si,offset new_flames+2
                mov     di,offset flames+2
                mov     cx,flw*flh/2-2
                push    cx
                push    di
                rep     movsw

                pop     si

                push    0a000h
                pop     es

                mov     di,(200-flh)*320+((320-flw)/2)+2
                pop     cx
                rep     movsw

                push    ds
                pop     es

                mov     ah,1
                int     16h
                jz      do_fire
Key_Pressed:
                mov     ax,3
                int     10h
                ret

FlH             =       100
FlW             =       320
Spots           =       200
RandSeed        dw      ?,?
Flames          db      (flw*flh) dup (?)
New_Flames      db      (flw*flh) dup (?)

END main
```

## eicar.com

https://thestarman.pcministry.com/asm/eicar/eicarcom.html

新建文本文件, 粘贴下一行文本, 另存为 com, 比如 eicar.com, 将导致杀毒软件报告病毒

X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*

## int 10h

https://stackoverflow.com/questions/47941699/using-32-bit-registers-in-masm-without-changing-the-default-segment-definition-s

下列程序把屏幕设置为粉红, 按 esc 退出. 他说 bug 是使用 .386 后在 dosbox 里死机. 我实验结果是:

```
    freeze           ok             ok
;.MODEL SMALL   ;.MODEL SMALL   .MODEL SMALL
.386            ;.386           .386
```

答案 1 提到在段后加 use16, 难道是我用的 masm 6.11 默认 use16, 他用的编译器默认 use32?

答案 2 提到 .386 导致 type of (其后的 stack segment alignment) = DWORD, not WORD

`ml -Foout\ dd.msm -Feout\`

```
;.MODEL SMALL
;.386

theStack    SEGMENT STACK
        db      64 dup ('THESTACK')
theStack    ENDS

varData SEGMENT PUBLIC
        PUBLIC  fCntr
        fCntr   db 0    ; A frame counter used to delay animations.
varData ENDS

code    SEGMENT PUBLIC

assume  cs: code, ds: varData

main    PROC
        mov     ax, varData
        mov     ds, ax                  ; Load the variable segment into ds
        cld                             ; ensure that string ops auto-increment

        xor     ah, ah                  ; select set video mode function
        mov     al, 13h                 ; 320x200 256 colors
        int     10h                     ; video mode set

        mov     di, 0a000h
        mov     es, di
        xor     di, di                  ; es:di -> vga pixel buffer
        mov     ah, 64d
        mov     al, ah                  ; ah & al -> pink color index byte
        mov     cx, 32000d              ; writing 32,000 words
        rep     stosw                   ; fill the screen with pink pixels

ESC_LOOP:
        in      al, 60h
        cmp     al, 1
        jne     ESC_LOOP                ; delay till escape key is pressed

        mov     ax, 40h
        mov     es, ax                  ; access keyboard data area via segment 40h
        mov     WORD PTR es:[1ah], 1eh  ; set the kbd buff head to start of buff
        mov     WORD PTR es:[1ch], 1eh  ; set the kbd buff tail to same as buff head

; now the keyboard buffer is cleared.
        xor     ah, ah                  ; select video mode function
        mov     al, 3                   ; select 80x25 16 colors
        int     10h                     ; restore VIDEO back to text mode




        mov     ah, 4ch                 ; Terminate process DOS service
        xor     al, al                  ; Pass 0 to ERRORLEVEL
        int     21h                     ; Control returns to DOS

main    ENDP
code    ENDS
        END main
```

## stack

```
; 16 位程序栈的一个元素是两字节
; 这程序当时 (2013) 应该是用 cv 调试, visual studio 查看 16 进制的; 现在 (2019) 用 debug 和 powershell
;
; ==================== com
;
; com 执行时, 开始栈顶是 fffe, push 一个 16 位值后栈顶变为 fffc
; fffc, fffd, fffe, ffff 总共是 4 个字节但是只使用了两个字节
;
; ml -Dcom -Foout\ 8086/refs/stack.msm -Feout\
;
; debug out\stack.com
; r, 看到列出的寄存器里 sp = fffe
; d fff0, 看到 fffe 和 ffff 是 0 0
; t, 单步执行, 观察寄存器
;
; ==================== exe
;
; exe 中, 自己设定栈指针时栈的第一个元素用到了
; 用 77 填充 stack 段, 并
; - 用 stack 修饰 stack 段: 栈顶是 20h, 但 1e 和 1f 的值是 ff 而不是 77
;   用 visual sutdio 查看该文件生成的 exe 发现 stack 段的最后两个字节还是 77, 所以
;   1e 和 1f 应该是在运行的时候从 77 修改成 ff 的.
; - 不修饰 stack 段, 这需要自己调整 ss:sp: 此时 stack 段是 20h 个 77, 最后两字节未被修改
;
; ml -Foout\ 8086/refs/stack.msm -Feout\
;
; debug out\stack.exe
; r, 有 ss = 076f, sp = 0020
; d ss:0, 看到 0 ~ 1d 是 77, 1e 和 1f 是 ff ff
;
; format-hex out/stack.exe
; 最后 32 (20h) 字节是 77

ifdef com

       .model   tiny
       .code
start:  mov     ax, 4c00h
        push    ax
        push    ax

        pop     bx
        pop     bx
        pop     bx

        int     21h
else

; 相当于 .model small

code    segment 'code'
start:  mov     ax, 4c00h
        push    ax
        push    ax

        pop     bx
        pop     bx
        pop     bx

        int     21h
code    ends

stack   segment stack
        word    16 dup (7777h)
stack   ends

endif

        end     start


2019, 现在知道为啥
- com 一开始栈顶是 fffe
- fffe, ffff 是 0 0 (这一条没见写, 不知道当时注意到没有)
了. 因为 com 要支持 retn 结束程序. 见 abc/2-life.asm
```

## 80x86汇编语言程序设计教程 t3-8

```
; 80x86汇编语言程序设计教程
; p102
; 程序名: T3-8.asm
; 功  能: ASCII 码转换为十六进制数

data    segment
xx      db ? ; 存放十六进制数
ascii   db 'a' ; 假设的 ASCII 码
data    ends

stack   segment para stack
stack   ends

code    segment
        assume cs: code, ds: data
start:
    mov ax, data
    mov ds, ax

    mov al, ascii

lab:
    cmp al, '0'
    jb  lab5 ; 小于 0 转范围外处理

    mov ah, al ; 设在 0 ~ 9 之间
    sub ah, '0'
    cmp al, '9'
    jbe lab6 ; 确实在 0 ~ 9 之间转到保存处

    cmp al, 'A'
    jb  lab5 ; 小于 A 转范围外处理

    mov ah, al ; 设在 A - F 之间
    sub ah, 'A' - 10
    cmp al, 'F'
    jbe lab6 ; 确实在 A - F 之间转到保存处

    cmp al, 'a'
    jb  lab5 ; 小于 a 转范围外处理

    mov ah, al ; 设在 a - f 之间
    sub ah, 'a' - 10
    cmp al, 'f'
    jbe lab6 ; 确实在 a - f 之间转到保存处

lab5:
    mov ah, -1 ; 范围外处理

lab6:
    mov xx, ah ; 保存转换结果

    mov ah, 4ch
    int 21h
code    ends
        end start
```

## ONEOF.ASM

```
    .NOLIST
; This source file contains a C-callable routine designed to generate 
; unsigned pseudo-random numbers between 0 and any number up to 65,535 
; (up to 16 bits long).  It takes an argument specifying the upper end 
; of the desired range.  The rest of the file contains code used to 
; test the routine by writing its output to the standard output device. 
    .LIST

    PAGE	55,132
    TITLE	Random number routine: OneOf( range ), with test code
    .MODEL	small, c
    .DOSSEG
    .186

OneOf	PROTO	range:WORD
seedr	PROTO
atoui	PROTO
uitoa	PROTO

    .STACK

    .DATA

rndPrev	dw	0		; Holds the previous value in the series

banr	BYTE	13, 10, 13, 10,
        "Random Number Generator Sample Program"
lbanr	EQU	SIZEOF banr

banr2	BYTE	13, 10,
        "   (80 numbers in each series)"
lbanr2	EQU	SIZEOF banr2

prompt	BYTE	13, 10, 13, 10,
        "Please enter a range (0 - 65,535): "
lprompt	EQU	SIZEOF prompt

isrng	BYTE	13, 10,
        "Is:12345678 the correct range? If so, press 'Y': "
lisrng	EQU	SIZEOF isrng

again	BYTE	13, 10,
        "Press 'Esc' to quit, any other key to continue ", 13, 10
lagain	EQU	SIZEOF again

    ALIGN  2
lnBuf	BYTE	82 dup (0)

    .CODE

; c-callable pseudo-random number generator routine
;
;	unsigned int OneOf(unsigned int range)
;	---------------------------------------------------
;	Routine uses a linear congruential method to calculate
;	a pseudo-random number, treates the number as a fraction
;	between 0 and 1, multiplies it times the range,
;	truncates the result to an integer, and return it.
;
; Algorithm:
;   a[i] = ((a[i - 1] * b) + 1) mod m
;   where b = 4961 and m = 2 ^ 16

OneOf	proc near c public uses bx dx, range: word
    mov ax, 4961
    mul rndPrev
    inc ax
    mov rndPrev, ax

    mov bx, range
    mul bx
    mov ax, dx
    ret
OneOf	endp


    .STARTUP

; Seed the random number generator with a "random" value
    call	seedr

; Display 1st Banner line
    mov	ah, 040h	; DOS function: Write to file or device
    mov	bx, 1		; Handle = Standard Output
    mov	cx, lbanr	; Number of bytes to write
    mov	dx, OFFSET banr ; 
    int	021h		; issue DOS function interrupt

; Display 2nd Banner line
    mov	ah, 040h	; DOS function: Write to file or device
    mov	cx, lbanr2
    mov	dx, OFFSET banr2
    int	021h

; Display prompt line
shwpr:	mov	ah, 040h	; DOS function: Write to file or device
    mov	cx, lprompt
    mov	dx, OFFSET prompt
    int	021h

; Read in a range value from the keyboard
    mov	ah, 03Fh	; DOS function: Read device
    sub	bx, bx		; Handle = standard input device
    mov	cx, 10		; Don't read more than 10 keystrokes
    mov	dx, OFFSET lnBuf
    int	021h

; Convert the range value to binary and save it in SI
    push	dx	; DX still points to lnBuf
    call	atoui	; This routine returns the number in AX
    add	sp,2	; In C, the calling routine adjusts SP
    mov	si, ax	; Store the returned value in SI

; Reformat the range value within the confirmation string
    push	OFFSET isrng + 12	; In C, remember that arguments
    push	ax	; are pushed in REVERSE order (last one
    call	uitoa	; first). Also note that this particular
    add	sp, 4	; routine formats from right to left.

; Ask for confirmation of the entered range
    mov	ah, 040h	; DOS function: Write to file or device
    mov	bx,1
    mov	cx, lisrng
    mov	dx, OFFSET isrng
    int	021h

; Read in a character from the keyboard
    mov	ah, 1		; DOS function: Read character with echo
    int	021h		; issue DOS function interrupt
    cmp	al, 27		; Is this an 'Esc' keystroke?
    jz	quit		;  - if so, quit
    and	al, 0DFh	; Change lower-case character to upper
    cmp	al, 'Y'		; Is it a 'Y' or 'y'?
    jnz	shwpr		;  - if not, prompt for another range
    mov	dx, OFFSET lnBuf ; Point DX to lnBuf again
    mov	di, dx		; and DI as well
    mov	BYTE PTR [di], 13 ; Put a CR/LF pair at the 
    inc	di		; start of lnBuf
    mov	BYTE PTR [di], 10
    mov	bh, 10		; Display 10 lines with BH counter      
prtLn:  mov	bl, 8		; Display 8 numbers per line
    mov	di, OFFSET lnBuf + 9	; Starting position of 1st number

prtNum: push	si		; Use the OneOf routine to generate a
    call	OneOf		; number in the range saved in SI
    add	sp,2		; and adjust the stack pointer.
    push	di		; Push the 2nd argument 1st (if you
    push	ax		; use INVOKE, you don't have to worry
    call	uitoa		; about these argument passing
    add	sp, 4		; conventions or stack cleanup!). 
    add	di, 8		; Move over to the next number position
    dec	bl		; Decrement the number counter
    jnz	prtNum		; and go on until finished.

    push	bx		; If it's time to print a line, save BX
    mov	ah, 040h	; DOS function: Write to file or device
    mov	bx, 1
    mov	cx, 66
    int	021h
    pop	bx

    dec	bh		; Decrement the line counter
    jnz	prtLn		; and go on unless the last one is done

; Display continuation line
    mov	ah, 040h	; DOS function: Write to file or device
    mov	bx, 1
    mov	cx, lagain
    mov	dx, OFFSET again
    int	021h

; Read in a character from the keyboard
    mov	ah, 1		; DOS function: Read character with echo
    int	021h
    cmp	al, 27		; Is this an "Esc" keystroke?
    jnz	shwpr		;  - if not, prompt for a range.
quit:	.EXIT			; If it IS an Esc key, exit!

;	void seedr ( )
;	----------------------------------------------------------------
;	Uses the system clock to seed the random number generator.
;
seedr	PROC NEAR
    enter	0, 0		; The "enter" and "pusha" instructions are
    pusha			; only available on INTEL 80186 and higher
    mov	ah, 02Ch	; This is the DOS "Get System Time" function
    int	021h
    mov	al, dh		; Make 1/100ths of a second most significant
    mov	ah, dl		; and seconds less significant
    shl	ax, 1		; Multiply AX by 2
    mov	rndPrev, ax	; and save it
    popa			; Restores the registers (use with pusha)
    leave			; Restores the stack frame (use with enter)
    ret
seedr	ENDP

;	unsigned int atoui ( char *buf )
;	----------------------------------------------------------------
;	This routine converts a character string, pointed to by buf,
;	into an unsigned int, returned in AX.
;
;	- Processes all ASCII decimal digits in the string (0123456789)
;	  and ignores all other characters.
;	- The string can be terminated by a NULL (0), by a carriage
;	  return (13), or by a line feed (10).
;
atoui	PROC NEAR PUBLIC
    enter	0, 0		; This entry code is only compatible
    push	bx		; with 80186 processors and higher
    push	cx		; because it uses the "enter"
    push	dx		; instruction (and "leave" at the
    push	si		; end).

    sub	ax, ax		; Zero AX,
    mov	bx, ax		; and BX too.
    mov	cx, 10		; CX will hold the radix (base 10)
    mov	si, [bp+4]	; DS:SI will point to the buffer
    jmp	at_lod		; OK, let's go!

at_num: sub	bl, '0'		; Convert the digit from ASCII
    jb	at_chk		; - if it was < '0', check it
    cmp	bl, 9		;   but if it was greater than
    ja	at_nxt		;   '9', ignore it
    mul	cx		; - otherwise, it's a digit, so
    add	ax, bx		;   add it to (10 x prior value)

at_nxt: inc	si		; Move on the next digit
at_lod: mov	bl, [si]	; Load the next digit into BL
    or	bl, bl		; - if BL is 0 (NULL), then this
    jnz	at_num		;   is the end; otherwise, process it.

at_end: pop	si		; Restore the registers used
    pop	dx
    pop	cx
    pop	bx
    leave
    ret

at_chk: cmp	bl, 221		; Check whether it WAS a CR (13)
    jz	at_end		; - if so, quit.
    cmp	bl, 218		; Check whether it WAS a LF (10)
    jz	at_end		; - if so, quit 
    jmp	at_nxt		;   but if not, just ignore it
atoui	ENDP

;	void uitoa ( unsigned int num, char *buf )
;	----------------------------------------------------------------
;	This routine converts an unsigned int, num, into a formatted,
;	RIGHT-justified string 8 characters long, the LAST DIGIT of
;	which (the farthest to the right) will be placed in the byte
;	pointed to by buf.
;
;	- If there are 4 or more digits in the formatted number, a 
;	  comma will precede the last three.
;	- All eight positions will be filled (unused ones with a space).
;	- The string will not be null-terminated.
;
uitoa	PROC NEAR
    enter	0, 0		; These instructions are not available
    pusha			; on 8086 or 8088 processors.

    mov	ax, [bp+4]	; Load the number to be formatted to AX
    mov	bl, 8		; BL holds the number of spaces to fill
    mov	cx, 10		; CX holds the radix (base 10)
    mov	di, [bp+6]	; DI points to the end of the string

ui_num: sub	dx, dx		; Zero DX preparatory to dividing
    div	cx		; Divide AX by 10, remainder to DX
    add	dl, '0'		; Change DL into an ASCII digit
    mov	[di], dl	; and place it in the buffer.
    dec	di		; Move the pointer back one space,
    dec	bl		; and count down the remaining spaces.
    jz	ui_end		; [this is really an unnecessary test]
    or	ax, ax		; Is AX equal to zero yet?
    jz	ui_fil		; - if so, fill the remaining spaces
    cmp	bl, 5		; - if not, is this the comma position?
    jnz	ui_num		;   if not, go on to another digit.

    mov	BYTE PTR [di], ',' ; Since this is the comma
    dec	di		; position, insert a comma, then move
    dec	bl		; the pointer and reduce the space-counter.
    jmp	ui_num		; Go on to the next digit.

ui_fil: mov	BYTE PTR [di], ' '
    dec	di		; Fill all the remaining spaces with
    dec	bl		; space characters, then return.
    jnz	ui_fil

ui_end: popa
    leave
    ret
uitoa	ENDP
    END
```



