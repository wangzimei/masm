
@echo off

rem dosbox doesn't support these:
rem - :: as inline comment
rem - if /i
rem - (parentheses) , cmd.exe in winnt 4+
rem - else          , cmd.exe in winnt 4+
rem - :eof          , cmd.exe in winnt 4+
rem
rem fails when %1 is ]=[, ]==[, ]=======[, ...



rem this command
rem     ml -nologo -Zi -Foout\ dd.msm -Feout\ -AT -link -nologo
rem will report
rem     CVPACK : Fatal error CK1003: cannot open file
rem and these 2
rem     ml -nologo -Zi -Foout\ dd.msm -Feout\ -c
rem     link out\dd.obj, out\dd.com /co /t /nologo;
rem will success, but (still) cannot find source file in code view
rem so if i want to see source code in code view i have to use exe

if [%1] == []   ml -nologo      -Foout\ dd.msm -Feout\ -AT  -link -nologo
if [%1] == [d]  ml -nologo -Zi  -Foout\ dd.msm -Feout\      -link -nologo

if [%1] == [zs] ml -nologo              -Zs dd.msm
if [%1] == [fl] ml -nologo -Flout\ -Sa  -Zs dd.msm

if [%1] == [2]  ml -nologo -Foout\ dd.msm -Foout\ da.msm -Feout\ -link -nologo

rem console redirects in all 'if's or 'rem if's are executed regardless so use goto instead

if [%1] == [f]  goto f
if [%1] == [f2] goto f2

if [%1] == [build4gw]   goto build4gw
if [%1] == [build32a]   goto build32a
if [%1] == [test32]     goto test32

goto eof

:f
> out\fff ml -nologo -Foout\ dd.msm -Feout\ -link -nologo
goto eof

:f2
> out\fff ml -nologo -Foout\ dd.msm -Foout\ da.msm -Feout\ -link -nologo
goto eof

:build4gw
ml -nologo -Foout\ dd.msm -c
wlink file out\dd format os2 le option quiet, osname=DOS/4G, stub=wstub.exe
goto eof

:build32a
wasm dd.msm -e -fo=out\ -zq
wlink file out\dd format os2 le option quiet, osname='DOS/32 Advanced DOS Extender (LE-style)', stub=stub32a.exe
goto eof

:test32
@echo on

out\dd

dos4gw out\dd
z:bin\dos4gw out\dd

dos32a out\dd
z:bin\dos32a out\dd

@echo off
goto eof






:eof
