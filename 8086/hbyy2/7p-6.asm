
; 汇编语言 2e.pdf
; 王爽
; p162，问题 7.6
; problem
;
; 将 datasg 段中每个单词的头一个字母改为大写字母

datasg  segment
db '1. file         '
db '2. edit         '
db '3. search       '
db '4. view         '
db '5. options      '
db '6. help         '
datasg  ends

codesg  segment
start:
mov     ax, datasg
mov     ds, ax
mov     bx, 0

mov     cx, 6
line_wise:
mov     al, [bx + 3]
and     al, 11011111b
mov     3[bx], al
add     bx, 16
loop    line_wise

mov     ax, 4c00h
int     21h
codesg  ends
end start
