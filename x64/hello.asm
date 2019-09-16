
; Introduction to x64 Assembly
; http://software.intel.com/en-us/articles/introduction-to-x64-assembly
;
; 打开 visual studio 命令提示，cd 到文件所在目录，输入下列命令，会在当前目录生成 <文件名>.exe 以及一些临时文件
; ml64 hello.asm /link /subsystem:windows /defaultlib:kernel32.lib /defaultlib:user32.lib /entry:Start
;
; 不指定 /subsystem 和 /entry 时连接器需要入口点
; 不指定 /subsystem 指定 /entry 时连接器无法推导出子系统
; 指定 /subsystem 不指定 /entry 时连接器寻找 WinMainCRTStartup

includelib kernel32.lib
includelib user32.lib

; Sample x64 Assembly Program
; Chris Lomont 2009 www.lomont.org
extrn ExitProcess: PROC   ; external functions in system libraries
extrn MessageBoxA: PROC
.data
caption db '64-bit hello!', 0
message db 'Hello World!', 0
.code
Start PROC
  sub    rsp,28h      ; shadow space, aligns stack
  mov    rcx, 0       ; hWnd = HWND_DESKTOP
  lea    rdx, message ; LPCSTR lpText
  lea    r8,  caption ; LPCSTR lpCaption
  mov    r9d, 0       ; uType = MB_OK
  call   MessageBoxA  ; call MessageBox API function
  mov    ecx, eax     ; uExitCode = MessageBox(...)
  call ExitProcess
Start ENDP
End