
@echo off

rem dosbox doesn't support these:
rem - :: as inline comment
rem - if /i
rem - (parentheses) , cmd.exe in winnt 4+
rem - else          , cmd.exe in winnt 4+
rem - :eof          , cmd.exe in winnt 4+

rem fails when %1 is ]=[, ]==[, ]=======[, ...

if [%1] == []   ml -nologo     -Foout\ dd.msm -Feout\ -link -nologo
if [%1] == [zi] ml -nologo -Zi -Foout\ dd.msm -Feout\ -link -nologo
if [%1] == [at] ml -nologo -Foout\ dd.msm -Feout\ -AT -link -nologo

if [%1] == [2]  ml -nologo -Foout\ dd.msm -Foout\ da.msm -Feout\ -link -nologo

rem console redirects in all 'if's or 'rem if's are executed regardless so use goto instead

if [%1] == [f]  goto f
if [%1] == [2f] goto 2f

:f
> out\fff ml -nologo -Foout\ dd.msm -Feout\ -link -nologo
goto eof

:2f
> out\fff ml -nologo -Foout\ dd.msm -Foout\ da.msm -Feout\ -link -nologo
goto eof

:eof
