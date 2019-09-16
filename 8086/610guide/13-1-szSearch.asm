
;* szSearch - An example of 32-bit assembly programming using MASM 6.1
;*
;* Purpose: Search a buffer (rgbSearch) of length cbSearch for the
;*          first occurrence of szTok (null terminated string).
;*
;* Method:  A variation of the Boyer-Moore method
;*          1. Determine length of szTok (n)
;*          2. Set array of flags (rgfInTok) to TRUE for each character
;*                  in szTok
;*          3. Set current position of search to rgbSearch (pbCur)
;*          4. Compare current position to szTok by searching backwards
;*                  from the nth position. When a comparison fails at
;*                  position (m), check to see if the current character
;*                  in rgbSearch is in szTok by using rgfInTok. If not,
;*                  set pbCur to pbCur+(m)+1 and restart compare. If
;*                  pbCur reached, increment pbCur and restart compare.
;*          5. Reset rgfInTok to all 0 for next instantiation of the
;*                  routine.

        .386
        .MODEL  flat, stdcall

FALSE   EQU     0
TRUE    EQU     NOT FALSE

        .DATA
; Flags buffer - data initialized to FALSE. We will
; set the appropriate flags to TRUE during initialization
; of szSearch and reset them to FALSE before exit.
rgfInTok    BYTE    256 DUP (FALSE);

        .CODE

PBYTE   TYPEDEF PTR BYTE

szSearch PROC PUBLIC USES esi edi,
        rgbSearch:PBYTE,
        cbSearch:DWORD,
        szTok:PBYTE

; Initialize flags buffer. This tells us if a character is in
; the search token - Note how we use EAX as an index
; register. This can be done with all extended registers.
        mov     esi, szTok
        xor     eax, eax
        .REPEAT
        lodsb
        mov     BYTE PTR rgfInTok[eax], TRUE
        .UNTIL  (!AL)

; Save count of szTok bytes in EDX
        mov     edx, esi
        sub     edx, szTok
        dec     edx

; ESI will always point to beginning of szTok
        mov     esi, szTok

; EDI will point to current search position
; and will also contain the return value
        mov     edi, rgbSearch

; Store pointer to end of rgbSearch in EBX
        mov     ebx, edi
        add     ebx, cbSearch
        sub     ebx, edx

; Initialize ECX with length of szTok
        mov     ecx, edx
        .WHILE  ( ecx != 0 )
        dec     ecx             ; Move index to current
        mov     al, [edi+ecx]   ; characters to compare

; If the current byte in the buffer doesn't exist in the
; search token, increment buffer pointer to current position
; +1 and start over. This can skip up to 'EDX'
; bytes and reduce search time.
        .IF     !(rgfInTok[eax])
        add     edi, ecx
        inc     edi             ; Initialize ECX with
        mov     ecx, edx        ; length of szTok
; Otherwise, if the characters match, continue on as if
; we have a matching token
        .ELSEIF (al == [esi+ecx])
        .CONTINUE
; Finally, if we have searched all szTok characters,
; and land here, we have a mismatch and we increment
; our pointer into rgbSearch by one and start over.
        .ELSEIF (!ecx)
        inc     edi
        mov     ecx, edx
        .ENDIF

; Verify that we haven't searched beyond the buffer.
        .IF     (edi > ebx)
        mov     edi, 0          ; Error value
        .BREAK
        .ENDIF
        .ENDW

; Restore flags in rgfInTok to 0 (for next time).
        mov     esi, szTok
        xor     eax, eax
        .REPEAT
        lodsb
        mov     BYTE PTR rgfInTok[eax], FALSE
        .UNTIL  !AL

; Put return value in eax
        mov     eax, edi
        ret
szSearch ENDP

end
