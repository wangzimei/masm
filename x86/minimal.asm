;
; 如果没有给连接器指定 -subsystem, 连接器尝试推导它, 规则是
; _main 是 console, _WinMain@16 是 windows, 区分大小写; 否则报错
; LINK : fatal error LNK1221: 无法推导出子系统，必须定义它
; 汇编经常用 _start 作为入口函数, 由于连接器装作不认识所以无法推导, 需要指定 -subsystem 连接选项
;
; ml -Foout/ x86/minimal.asm -Feout/

.model flat
.code

_main:

end _main
