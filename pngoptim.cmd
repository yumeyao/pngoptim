@echo off
if "spawn::"a==%1a goto:spawn_process
if "func::compress"a==%1a goto:func_compress

:EntryPoint
setlocal enableextensions enabledelayedexpansion
call:find_path pngout %0
call:find_path zopflipng %0
call:find_path deflopt %0
if defined pngout if defined zopflipng if defined deflopt goto:Main
endlocal & goto:eof

:Main
if ""=="%1" goto:Usage
set ParallelCmd=%0
call:InitSessionID pngoptim
echo Session ID: %sessionid%
echo Session ID: %sessionid%>%sessionid%.log
echo.>>%sessionid%.log
echo Log File: %__cd__%%sessionid%.log
call:InitParallel 2

set pngcount=0

for /f "delims=" %%i in ('dir /b/s %1') do (
set /a pngcount=!pngcount!+1
call:StartProcess cmd /c %0 "func::compress" "%%i"
)

call:WaitForAllProcess

del /q /s /f "%sessiontmpdir%" >nul 2>nul
endlocal & goto:eof

:Usage:
echo>&2 Usage: %0 pngfiles
endlocal & goto:eof

:optimize_and_show_pass_info
for /f %%f in ("%sessiontmpdir%\p%pngcount%p%1.png") do set p%1sizeb4=%%~zf
%deflopt% /b /a "%sessiontmpdir%\p%pngcount%p%1.png" >nul 2>nul
for /f %%f in ("%sessiontmpdir%\p%pngcount%p%1.png") do set p%1size=%%~zf
setlocal
for /f "tokens=1,2,3 delims= " %%i in ('^^%pngout% -l "%sessiontmpdir%\p%pngcount%p%1.png"') do (
	set para1= %%i %%j
	set para2=
	if %%i==/c3 set para2= %%k
	if %%i==/c0 set para2= %%k
)
echo Pass %1: %p3sizeb4% -^> %p3size%%para1%%para2%
endlocal
goto:eof

:func_compress
setlocal enableextensions enabledelayedexpansion
shift
:Pass1_pngout
set filter=-f5
for /f "tokens=1,2,3 delims= " %%i in ('^^%pngout% -l %1') do (
	set para2=
	if %%i==/c3 set para2= %%k
	if %%i==/c0 set para2= %%k
	if "/f5"=="%%j" set filter=-f6
	echo Processing File %1:
	echo Source: %~z1 %%i %%j!para2!
	set p0size=%~z1
)
%pngout% -force -s2 %filter% %1 "%sessiontmpdir%\p%pngcount%p1.png" >nul 2>nul
:Pass2_zopflipng_q
%zopflipng% --always_zopflify -q --filters=01234mepb --splitting=3 "%sessiontmpdir%\p%pngcount%p1.png" "%sessiontmpdir%\p%pngcount%p2.png"
:Pass3_zopflipng
%zopflipng% --iterations=20 --filters=p --splitting=3 "%sessiontmpdir%\p%pngcount%p2.png" "%sessiontmpdir%\p%pngcount%p3.png"
call:optimize_and_show_pass_info 3
:Pass4_pngout
%pngout% -force -f6 "%sessiontmpdir%\p%pngcount%p3.png" "%sessiontmpdir%\p%pngcount%p4.png" >nul 2>nul
call:optimize_and_show_pass_info 4

set output=0
set outputsize=%p0size%
for %%i in (3 4) do if !p%%isize! lss !outputsize! (
	set output=%%i
	set outputsize=!p%%isize!
)
if not %output%==0 copy "%sessiontmpdir%\p%pngcount%p%output%.png" %1 >nul 2>nul

endlocal & goto:eof


::############################################################
::Helper
::############################################################
:sleep
setlocal
set /a pingcount=%1+1
if %pingcount% gtr 1 ping -n %pingcount% 127.0.0.1 >nul
endlocal
goto:eof

:find_path
::syntax: call:find_path exename path_to_self
set %1="%~dp2%1"
!%1! >nul 2>nul
if %errorlevel%==9009 set %1=%1
%1 >nul 2>nul
if %errorlevel%==9009 (
	echo>&2 %1 is not present in the same directory as this script, or in your working directory and %%PATH%%.
	set %1=
)
goto:eof

:GetRandomStr
setlocal
set ret=
for /l %%i in (1 1 %2) do call:AppendRandomChar ret
(endlocal
set %1=%ret%
)
goto:eof

:AppendRandomChar
setlocal enableextensions enabledelayedexpansion
set chars=abcdefghijklmnopqrstuvwxyz0123456789
set charcount=36
::A test of 'set /a var=%random%+%random%' gives odd numbers too, so %random% is re-generated for each reference
set /a charindex=((%random% ^%% 100) * (%random% ^%% 100) + %random%) ^%% 36
set ret=!%1!!chars:~%charindex%,1!
(endlocal
set %1=%ret%
)
goto:eof


::############################################################
::Parallel Helper
::############################################################
:spawn_process
setlocal enableextensions enabledelayedexpansion
shift
set donefile=%1
shift
set cmdline=%1
shift
:parsecmdline
if "%~1" neq "" (
  set cmdline=%cmdline% %1
  shift
  goto :parsecmdline
)
start /b /wait %cmdline%
set /p cmdline=<nul>%donefile%
endlocal
goto:eof

:StartProcess
if %pavailable% gtr 0 (
	set /a pavailable+=-1 >nul
	set /a pcount+=1 >nul
	start /b cmd.exe /c %ParallelCmd% "spawn::" "%sessiontmpdir%\p!pcount!done.txt" %*>"%sessiontmpdir%\p!pcount!out.txt" 2>&1
	for /l %%i in (1,1,%ptotal%) do if !p%%iused!==0 (
		set p%%iused=!pcount!
		goto:eof
	)
)
call:sleep 2
call:CheckProcess
goto:StartProcess

:CheckProcess
for /l %%i in (1,1,%ptotal%) do (
	if exist "%sessiontmpdir%\p!p%%iused!done.txt" (
		set /a pavailable+=1 >nul
		::del "%sessiontmpdir%\p!p%%iused!done.txt"
		type "%sessiontmpdir%\p!p%%iused!out.txt"
		type "%sessiontmpdir%\p!p%%iused!out.txt">>%sessionid%.log
		del "%sessiontmpdir%\p!p%%iused!out.txt"
		set p%%iused=0
	)
)
goto:eof

:WaitForAllProcess
call:CheckProcess
if %pavailable% equ %ptotal% goto:eof
call:sleep 1
goto:WaitForAllProcess

:InitParallel
set ptotal=0
wmic cpu get NumberOfLogicalProcessors >nul 2>nul
if not %errorlevel%==9009 for /f %%i in ('wmic cpu get NumberOfLogicalProcessors') do (
	REM a check in case %%i is not a number(the caption line).
	REM note that 'set /a value=string+value' == 'set /a value=%string%+%value%'
	if "9" geq "%%i" set /a ptotal=%%i+!ptotal!
)
if %ptotal%==0 set ptotal=%1
set pavailable=%ptotal%
set pcount=0
for /l %%i in (1,1,%1) do set p%%iused=0
goto:eof

:InitSessionID
call:GetRandomStr sessionid 8
set sessiontmpdir=%temp%\%1\%sessionid%
del /q /s /f "%sessiontmpdir%\*.*" >nul 2>nul
mkdir "%sessiontmpdir%" >nul 2>nul
goto:eof