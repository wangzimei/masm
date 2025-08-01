
@echo off

rem dosbox doesn't support these:
rem - :: as inline comment
rem - if /i
rem - (parentheses) , cmd.exe in winnt 4+
rem - else          , cmd.exe in winnt 4+
rem - :eof          , cmd.exe in winnt 4+
rem
rem fails when %1 is ]=[, ]==[, ]=======[, ...

rem link.exe outputs something even with -link -nologo
rem qh link claims "This option has no effect if it is not the first option specified
rem on the command line or in the LINK environment variable." but that isn't accurate
rem if [%1] == [] ml -nologo -Foout\ dd.msm -Feout\ -AT -link -nologo

if [%1] == [] goto com

goto %1

:com
ml -nologo -Foout\ dd.msm -c

rem if errorlevel 1                     echo at least 1
rem if not errorlevel 2                 echo less than 2
rem if errorlevel 1 if not errorlevel 2 echo equal to 1

if errorlevel 1 goto eof

rem link requires .com extension otherwise warning L4045: name of output file is 'out\dd.com'

link /nologo /tiny out\dd, out\dd.com;
goto eof

:d
rem this command
rem     ml -nologo -Zi -Foout\ dd.msm -Feout\ -AT -link -nologo
rem will report
rem     CVPACK : Fatal error CK1003: cannot open file
rem and these 2
rem     ml -nologo -Zi -Foout\ dd.msm -c
rem     link /co /nol /t out\dd, out\dd.com;
rem will success but still cannot find source file in code view
rem so if i want to see source code in code view i have to use exe

ml -nologo -Zi -Foout\ dd.msm -c
if errorlevel 1 goto eof
link /codeview /nologo out\dd, out\dd;
goto eof

:zs
ml -nologo -Zs dd.msm
goto eof

:fl
ml -nologo -Flout\ -Sa -Zs dd.msm
goto eof

:2
ml -nologo -Foout\ da.msm -Foout\ dd.msm -c
link /nologo out\da out\dd, out\dd;
goto eof

:f
rem console redirects in all 'if's or 'rem if's are executed regardless so use goto instead

> out\fff ml -nologo -Foout\ dd.msm -Feout\ -link -nologo
goto eof

:f2
> out\fff ml -nologo -Foout\ da.msm -Foout\ dd.msm -Feout\ -link -nologo
goto eof

:dos4gw
rem ml -nologo -Foout\ dd.msm -Bl wlink
rem Error! E3033: directive error near '/r'

ml -nologo -Foout\ dd.msm -c
if errorlevel 1 goto eof

wlink file out\dd format os2 le option quiet, osname=DOS/4G, stub=wstub.exe
goto eof

:dos4gwd
ml -nologo -Zi -Foout\ dd.msm -c
if errorlevel 1 goto eof

wlink debug all file out\dd format os2 le option quiet, osname=DOS/4G, stub=wstub.exe
if errorlevel 1 goto eof

wd -trap=rsi out\dd
goto eof

:dos32a
wasm dd.msm -e -foout\ -zq
if errorlevel 1 goto eof

wlink file out\dd format os2 le option quiet, osname='DOS/32 Advanced DOS Extender (LE-style)', stub=stub32a.exe
goto eof

:test32
@echo on
             out\dd.exe
      dos4gw out\dd
z:bin\dos4gw out\dd
      dos32a out\dd
z:bin\dos32a out\dd
@echo off
goto eof

:cwsdpmid
ml -nologo -Foout\ dd.msm -c
if errorlevel 1 goto eof

link /nologo /tiny out\dd, out\dd.com;
if errorlevel 1 goto eof

rem cwsdpmi -sc:\out\cwsdpmi.swp
cwsdpmi -s-

debugbox out\dd 1
goto eof

:cwsdpmiexed
ml -nologo -Foout\ dd.msm -c
if errorlevel 1 goto eof

link /nologo out\dd, out\dd;
if errorlevel 1 goto eof

cwsdpmi -s-
debugbox out\dd.exe
goto eof

:glide211
ml -nologo -Foout\ dd.msm -c
if errorlevel 1 goto eof

wlink @out\glide211
goto eof

:glide211d
ml -nologo -Zi -Foout\ dd.msm -c
if errorlevel 1 goto eof

wlink debug all @out\glide211
if errorlevel 1 goto eof

wd -trap=rsi out\dd
goto eof




:eof
