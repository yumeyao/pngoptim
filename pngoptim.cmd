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
echo ************************************************************
echo   pngoptim 1.0.1 - by yumeyao
echo ************************************************************
if a==%1a goto:Usage
set ParallelCmd=%0
call:InitSessionID pngoptim
echo Session ID: %sessionid%
echo Session ID: %sessionid%>%sessionid%.log
echo(>>%sessionid%.log
echo Log File: %__cd__%%sessionid%.log
echo(
call:InitParallel 2

set zopfliiterations=
set pngouttryouts=20
set recursive=

set filelist=
set argvn=%1
:CheckArgs
if "!argvn:~0,1!" neq "-" if "!argvn:~0,1!" neq "/" (
	set filelist=!filelist! !argvn!
	goto:CheckNextArg
)
if /i "!argvn:~1,1!" equ "s" (set recursive=s&goto:CheckNextArg)
if /i "!argvn:~1,1!" equ "r" (set recursive=r&goto:CheckNextArg)
set argvnparameter=!argvn:~2!
if /i "!argvn:~1,1!" equ "z" (
	set /a zopfliiterations=argvnparameter+0
	if !zopfliiterations! neq 0 (set zopfliiterations="--iterations=!zopfliiterations!") else set zopfliiterations=
	goto:CheckNextArg
)
if /i "!argvn:~1,1!" equ "y" (
	set /a pngouttryouts=argvnparameter+0
	if !pngouttryouts! equ 0 set pngouttryouts=20
	goto:CheckNextArg
)
:CheckNextArg
shift
set argvn=%1
if defined argvn goto:CheckArgs

set pngcount=0
if defined filelist call:ProcessFiles %filelist%

rd /q /s "%sessiontmpdir%" >nul 2>nul
endlocal & goto:eof

:ProcessFiles
if !recursive! equ r (set usedir=true) else (
	set usedir=false
	(echo %1 | findstr [?*] >nul 2>nul) && (if defined recursive set usedir=true)
)
if !usedir!==true (set forpart1=/f "delims=" &set "forpart2='2^>nul dir /b/s %1'")
if !usedir!==false (set forpart2=%1 &set forpart1=)

set fileattr=%~a1
if "!fileattr:~0,1!" equ "d" (
	set forpart1=/f "delims=" 
	set "forpart2='2^>nul dir /b/s %1\*.png'"
)

for %forpart1%%%i in (%forpart2%) do if exist %%i (
	set /a pngcount=!pngcount!+1
	call:StartProcess cmd /c %ParallelCmd% "func::compress" "%%i"
) else if !usedir==false! (
	echo File %i doesn't exist.
	echo File %i doesn't exist.>>%sessionid%.log
	echo(
	echo(>>%sessionid%.log
)

shift
if not a==a%1 goto:ProcessFiles

call:WaitForAllProcess
goto:eof

:Usage:
echo>&2 Usage: %~n0 pngfiles [options ^| pngfiles]
echo>&2(
echo>&2 Options:
echo>&2  /z[num]  Set --iterations=num for zopflipng (default not specified)
echo>&2  /y[num]  Set how many times to try pngout (default = 20)
echo>&2  /s       subdirs
echo>&2  /r       recursive
echo>&2           %~n0 [/s^|/r] a.png b*.png
echo>&2           a.png  b1.png  subdir\a.png  subdir\b1.png
echo>&2       /s   Yes    Yes                     Yes
echo>&2       /r   Yes    Yes        Yes          Yes
echo>&2(
echo>&2 Suggested Presets:
echo>&2  FAST     without /z /y specified
echo>&2  NORMAL   /z20 /y50
echo>&2  SLOW     /z100 /y500
echo>&2  INSANE   /z500 /y1500
echo>&2(
endlocal & goto:eof

:zopflipng_parse
set filtertypes=
for /f "skip=1 tokens=1,2 delims=:" %%i in ('^^%zopflipng% --always_zopflify -y %*') do (
	set str1=%%i
	set str2=%%j
	if "!str1:~0,16!"=="Filter strategy " (
		set /a %varprefix%!str1:~16,2!=!str2:~1,-6!
		set filtertypes=!filtertypes! !str1:~16,2!
	)
)
goto:eof

:zopflipng_postprocess
for %%i in (%filtertypes1:~0,3%) do (
	set smallestsize=!sizet1%%i!
	set t1ftype=%%i
)
for %%i in (%filtertypes1%) do if !sizet1%%i! lss !smallestsize! (
	set smallestsize=!sizet1%%i!
	set t1ftype=%%i
)
if %p1color%==/c3 (
	set samepalette=same
	for %%i in (%filtertypes2:~0,3%) do (
		set t2smallestsize=!sizet2%%i!
		set t2ftype=%%i
	)
	for %%i in (%filtertypes2%) do (
		REM Because predefined filter preserves colorspace too, so the size is likely different.
		if not %%i==pr if !sizet1%%i! neq !sizet2%%i! set samepalette=
		if !sizet2%%i! lss !smallestsize! set smallestsize=!sizet2%%i!
		if !sizet2%%i! lss !t2smallestsize! (
			set t2smallestsize=!sizet2%%i!
			set t2ftype=%%i
		)
	)
	set p1color=/c3!samepalette!
)
goto:eof

:func_compress
setlocal enableextensions enabledelayedexpansion
shift

set p0size=%~z1
echo Processing File %1:

::Pass1_pngout - In case the source file has wrong CRC checksum.
set filter=-f5
for /f "tokens=1,2,3 delims= " %%i in ('^^%pngout% -l %1') do (
	set para2=%%i
	if not "!para2:~0,2!"=="/c" (
		echo %1 is not a valid png file.
		goto:eof
	)
	set para2=
	if %%i==/c3 set para2= %%k
	if %%i==/c0 set para2= %%k
	if "/f5"=="%%j" set filter=-f6
	echo Source: %~z1 %%i %%j!para2!
	set p0color=%%i
)
%pngout% -force -y -s2 %filter% %1 "%sessiontmpdir%\p%pngcount%p1t1.png" >nul 2>nul
for /f "tokens=1,2,3 delims= " %%i in ('^^%pngout% -l "%sessiontmpdir%\p%pngcount%p1t1.png"') do (
	set p1color=%%i
)
if %p1color%==/c3 %pngout% -force -y -c6 -s2 -f6 "%sessiontmpdir%\p%pngcount%p1t1.png" "%sessiontmpdir%\p%pngcount%p1t2.png" >nul 2>nul
echo Pass 1: %p1color%

::Pass2_zopflipng_q - Find good filters (and good? palette)
set varprefix=sizet1
call:zopflipng_parse -q "--filters=01234mepb" "--splitting=3" "%sessiontmpdir%\p%pngcount%p1t1.png" "%sessiontmpdir%\p%pngcount%p2t1.png"
set varprefix=sizet2
if %p1color%==/c3 call:zopflipng_parse -q "--filters=01234mepb" "--splitting=3" "%sessiontmpdir%\p%pngcount%p1t2.png" "%sessiontmpdir%\p%pngcount%p2t2.png"
set filtertypes1=ze on tw th fo mi en pr br
set filtertypes2=ze on tw th fo mi en pr br
call:zopflipng_postprocess
if defined samepalette echo Pass 2: Palettes seem to be same.
set /a sizethreshold=!smallestsize! * 102 / 100
set t1filters=
set t2filters=
set filterswitchze=0
set filterswitchon=1
set filterswitchtw=2
set filterswitchth=3
set filterswitchfo=4
set filterswitchmi=m
set filterswitchen=e
set filterswitchpr=p
set filterswitchbr=b
set prneeded=yes
if not %filter%==-f6 if not %p1color%==/c3 set prneeded=
if %p1color%==/c3 (set forloop=1 2) else set forloop=1
for %%f in (%forloop%) do for %%i in (%filtertypes%) do if !sizet%%f%%i! leq !sizethreshold! (
	if %%i==pr (if defined prneeded set t%%ffilters=!t%%ffilters!p) else set t%%ffilters=!t%%ffilters!!filterswitch%%i!
)
echo Pass 2: %sizet1ze% %sizet1on% %sizet1tw% %sizet1th% %sizet1fo% %sizet1mi% %sizet1en% %sizet1pr% %sizet1br%
if defined t1filters echo         use --filters=%t1filters% for next pass
if %p1color%==/c3 (
	echo Pass 2: %sizet2ze% %sizet2on% %sizet2tw% %sizet2th% %sizet2fo% %sizet2mi% %sizet2en% %sizet2pr% %sizet2br%
	if defined t2filters echo         use --filters=%t2filters% for next pass
)

::Pass3_zopflipng - Now compress using zopflipng
set varprefix=sizet1
set filtertypes1=
set p3t1size=
if defined t1filters (
	call:zopflipng_parse %zopfliiterations% "--filters=%t1filters%" "--splitting=3" "%sessiontmpdir%\p%pngcount%p1t1.png" "%sessiontmpdir%\p%pngcount%p3t1.png"
	set filtertypes1=!filtertypes!
	%deflopt% /b /a "%sessiontmpdir%\p%pngcount%p3t1.png" >nul 2>nul
	for /f %%f in ("%sessiontmpdir%\p%pngcount%p3t1.png") do set p3t1size=%%~zf
)
set varprefix=sizet2
set filtertypes2=
set p3t2size=
if defined t2filters (
	call:zopflipng_parse %zopfliiterations% "--filters=%t2filters%" "--splitting=3" "%sessiontmpdir%\p%pngcount%p1t2.png" "%sessiontmpdir%\p%pngcount%p3t2.png"
	set filtertypes2=!filtertypes!
	%deflopt% /b /a "%sessiontmpdir%\p%pngcount%p3t2.png" >nul 2>nul
	for /f %%f in ("%sessiontmpdir%\p%pngcount%p3t2.png") do set p3t2size=%%~zf
)
set choosewhich=
if not defined p3t1size set choosewhich=2
if not defined p3t2size set choosewhich=1
if not defined choosewhich (
	set choosewhich=2
	if !p3t1size! lss !p3t2size! set choosewhich=1
)
ren "%sessiontmpdir%\p%pngcount%p3t%choosewhich%.png" p%pngcount%p3.png
del /q/f/a "%sessiontmpdir%\p%pngcount%p3t*.png" >nul 2>nul
for /f "tokens=1,2,3 delims= " %%i in ('^^%pngout% -l "%sessiontmpdir%\p%pngcount%p3.png"') do (
	set para1= %%i 
	set para2=
	if %%i==/c3 set para2= %%k
	if %%i==/c0 set para2= %%k
)
call:zopflipng_postprocess
set bestfilter=!t%choosewhich%ftype!
set p3size=!p3t%choosewhich%size!
echo Pass 3: %p3size%%para1%/f!filterswitch%bestfilter%!%para2%

::Pass4_pngout - Now recompress use pngout with -r
pushd %sessiontmpdir%
%pngout% -force -y -ks -f6 p%pngcount%p3.png p%pngcount%p4t1.png >nul 2>nul
%deflopt% /b /a p%pngcount%p4t1.png >nul 2>nul
for /l %%i in (2,1,%pngouttryouts%) do (
	%pngout% -force -y -r -ks -f6 p%pngcount%p3.png p%pngcount%p4t%%i.png >nul 2>nul
	%deflopt% /b /a p%pngcount%p4t%%i.png >nul 2>nul
	for /f "skip=1 delims=" %%j in ('dir /b/os "%sessiontmpdir%\p%pngcount%p4t*.png"') do del /q/f/a "%%j" >nul 2>nul
)
for /f "delims=" %%i in ('dir /b/os "%sessiontmpdir%\p%pngcount%p4t*.png"') do (
	set p4filename=%%~ni
	set besttry=!p4filename:p%pngcount%p4t=!
	set p4size=%%~zi
	ren "%sessiontmpdir%\!p4filename!.png" p%pngcount%p4.png
)
popd
echo Pass 4: %p4size% Tryout number: %besttry% out of %pngouttryouts%

set output=0
set outputsize=%p0size%
for %%i in (3 4) do if !p%%isize! lss !outputsize! (
	set output=%%i
	set outputsize=!p%%isize!
)
if not %output%==0 (
	set /a sizepercentleft=outputsize*100/p0size
	set /a sizepercentright=(outputsize*100-sizepercentleft*p0size)*100/p0size
	if !sizepercentright! lss 10 set sizepercentright=0!sizepercentright!
	echo Optimized: %p0size% -^> %outputsize%, size decreased to !sizepercentleft!.!sizepercentright!%%
	copy "%sessiontmpdir%\p%pngcount%p%output%.png" %1 >nul 2>nul
) else (
	echo Cannot optimize the file for a smaller size within this try.
)

echo.
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
if not a==%1a (
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
for /l %%i in (1,1,%ptotal%) do set p%%iused=0
goto:eof

:InitSessionID
call:GetRandomStr sessionid 8
set sessiontmpdir=%temp%\%1\%sessionid%
del /q /s /f "%sessiontmpdir%\*.*" >nul 2>nul
mkdir "%sessiontmpdir%" >nul 2>nul
goto:eof