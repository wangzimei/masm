
; 汇编语言 2e.pdf
; 王爽
; p229, 检测点 11.2
; check point
;
; p224, 11.2 PF 标志
; 如果 1 的个数是偶数, pf = 1；如果是奇数, pf = 0.
;
; http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/debug_r.mspx?mfr=true
;
; Flag name         Set             Clear
; Overflow          ov              nv
; Direction         dn (decrement)  up (increment)
; Interrupt         ei (enabled)    di (disabled)
; Sign              ng (negative)   pl (positive)
; Zero              zr              nz
; Auxiliary Carry   ac              na
; Parity            pe (even)       po (odd)
; Carry             cy              nc
;
; p244, 11.12 标志寄存器在 Debug 中的表示

code    segment 'code'
start:                      ; 8 bits al     CF  OF  SF  ZF  PF
        sub     al, al      ;         0     0   0   0   1   1

        mov     al, 10h     ; 0001 0000     unchanged
        add     al, 90h     ; 1010 0000     0   0   1   0   1

        mov     al, 80h     ; 1000 0000     unchanged
        add     al, 80h     ; 0000 0000     1   1   0   1   1

        mov     al, 0fch    ; 1111 1100     unchanged
        add     al, 5h      ; 0000 0001     1   0   0   0   0

        mov     al, 7dh     ; 0111 1101     unchanged
        add     al, 0bh     ; 1000 1000     0   1   1   0   1

        mov     ax, 4c00h
        int     21h
code    ends
        end     start
