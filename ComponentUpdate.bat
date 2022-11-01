@echo off
echo CubiodAdSys-Initializer
::%errorlevel% 当他为0时说明在他之上的任务执行没问题
@REM C:\log\test_%date:~10%%date:~4,2%%date:~7,2%-%time:~0,2%%time:~3,2%%time:~6,2%.log 2>&1
set WORKDIR=%temp%\CubiodAdSys
set CORECOMPDIR=%WORKDIR%\Core
set LOGFILE=%CORECOMPDIR%\Execute.log
set COMMONSHAREDIR=\\192.168.1.1\CommonShare

CALL:LogMe "[I] Inited"

for /f "delims=" %%i in ('date /t') do set logRaw=%%i
for /f "delims=" %%i in ( 'time /t' ) do set logRaw=%logRaw%%%i
echo %logRaw% > C:/CubiodAdSys.LastExec.log

if %errorlevel% NEQ 0 (
    CALL:LogMe "[W] 写入执行事件标记文件失败"
    echo %logRaw% >> %LOGFILE%
)

@REM echo CubiodAdSys
if not exist %WORKDIR% (
    CALL:LogMe "[I] 创建工作目录"
    md %WORKDIR%
)
if not exist %CORECOMPDIR% (
    CALL:LogMe "[I] 创建工作目录Core"
    md %CORECOMPDIR%
)
@REM 连接公共存储
CALL:LogMe "[I] 连接存储服务"
net use %COMMONSHAREDIR%
if %errorlevel% NEQ 0 (
    CALL:LogMe "[W] 默认方式连接存储服务失败，需要切换方案"
    net use %COMMONSHAREDIR% /user:app 1
)

::============ Main Function Area =============
if "%~1" NEQ "" (
    @REM CALL:MsgBox "neq empty"
    CALL:LogMe "[I] [模块模式] 正在拉取 %~1"
    copy /Y /BV %COMMONSHAREDIR%\%~1 %WORKDIR%
    EXIT
) else (
    CALL:LogMe "[I] [默认模式] Start"
    @REM CALL:MsgBox "eq empty"
    CALL:AutomateMain
)
pause
goto :EOF

::============ NoParm Main Function Area =============
@REM function Automate MainFunc
:AutomateMain
SETLOCAL
CALL:fetch-lsrunase
CALL:fetchADHelperHelper "Cubiod-Windows-HelperHelper" "AdHelperFronter.exe"
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

::============ Function Defind Area =============

@REM :myfunct3
@REM SETLOCAL
@REM SET _var1=%1
@REM SET _var2="%_var1%--%_var1%--%_var1%"
@REM ENDLOCAL & SET _result=%_var2% & EXIT /B

@REM Ask 询问意见-变量只能再最外层返回，再代码块内结果会被清空
:Ask
SETLOCAL
@REM param %~1 标题
@REM param %~2 消息
@REM param %~3 可选-过程名
set Vbscript=Msgbox("%~2",1,%1)
for /f "Delims=" %%a in ('MsHta VBScript:Execute("CreateObject(""Scripting.Filesystemobject"").GetStandardStream(1).Write(%Vbscript:"=""%)"^)(Close^)') do Set "MsHtaReturnValue=%%a"
set ReturnValue1=确定
set ReturnValue2=取消或关闭窗口
if %MsHtaReturnValue% == 1 (
    @REM 1
    CALL:LogMe "[I] [%~3] Title:%~1 Msg:%~2 用户已确认"
    echo 你好世界！终于等到你。
) else (
    @REM 2
    CALL:LogMe "[I] [%~3] Title:%~1 Msg:%~2 用户已拒绝"
    echo 再见。
)
ENDLOCAL & SET _returnFuncAsk=%MsHtaReturnValue% & EXIT /B %EXITNUM%

@REM logEvent 记录事件
:LogMe
SETLOCAL
@REM param %~1 消息
for /f "delims=" %%i in ( 'date /t' ) do set logRaw=%%i
for /f "delims=" %%i in ( 'time /t' ) do set logRaw=%logRaw%%%i
echo [AdSys] %logRaw% : %~1
echo [AdSys] %logRaw% : %~1 >> %LOGFILE%
ENDLOCAL & EXIT /B %EXITNUM%

@REM function SimpleMsgBox
:SimpleMsg
SETLOCAL
@REM param %~1 消息盒子
msg * %~1
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

@REM function Cubiod-Windows Helper
:fetchADHelperHelper
SETLOCAL
@REM param %~1 过程描述 Cubiod-Windows-HelperHelper
@REM param %~2 拉取的主程序名称 AdHelperFronter.exe
CALL:LogMe "[I] [fetchADHelperHelper] [%~1] 进行中"
copy /Y /BV %COMMONSHAREDIR%\%~2 %CORECOMPDIR%
if %errorlevel%==0 (
    start %CORECOMPDIR%\%~2
    set _rtn=0
) else (
    CALL:LogMe "[E] [fetchADHelperHelper] [%~1] 复制 %~2 时遇到错误"
    set _rtn=1
)
CALL:LogMe "[I] [fetchADHelperHelper] [%~1] 成功完成"
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

@REM function fetch-lsrunase
:fetch-lsrunase
SETLOCAL
CALL:LogMe "[I] [fetch-lsrunase] 进行中"
copy /Y /BV %COMMONSHAREDIR%\lsrunase.exe %CORECOMPDIR%
if %errorlevel%==0 (
    set _rtn=0
) else (
    echo 执行复制 fetch-lsrunase 时遇到错误
    CALL:LogMe "[E] [fetch-lsrunase] 复制时遇到错误"
    set _rtn=1
)
CALL:LogMe "[I] [fetch-lsrunase] 成功完成"
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

@REM function 通过进程判断是否存在此软件不存在则安装
:fetchPkgThenValidByProcName
SETLOCAL
@REM param %~1 过程描述
@REM param %~2 安装包名
@REM param %~3 检测目标进程名
tasklist /nh | findstr %~3
if %errorlevel%==0 (
    CALL:LogMe "[I] [fetchPkgThenValidByProcName] 判断%~3存在，%~1不需要执行，跳过"
    set _rtn=0
) else (
    CALL:LogMe "[I] [fetchPkgThenValidByProcName] %~3不存在，%~1需要执行"
    copy /Y /BV %COMMONSHAREDIR%\%~2 %WORKDIR%
    CALL:LogMe "[I] [fetchPkgThenValidByProcName] %~3不存在，启动%~2"
    start %WORKDIR%\%~2
    set _rtn=1
)
CALL:LogMe "[I] [fetchPkgThenValidByProcName] %~1成功完成"
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

@REM function 通过进程判断是否存在此MSI软件不存在则安装
:fetchMsiPkgThenValidByProcName
SETLOCAL
@REM param %~1 过程描述
@REM param %~2 安装包名
@REM param %~3 检测目标进程名
tasklist /nh | findstr %~3
if %errorlevel%==0 (
    CALL:LogMe "[I] [fetchMsiPkgThenValidByProcName] 判断%~3存在，%~1不需要执行，跳过"
    set _rtn=0
) else (
    CALL:LogMe "[I] [fetchMsiPkgThenValidByProcName] %~3不存在，拉取%~1中"
    copy /Y /BV %COMMONSHAREDIR%\%~2 %WORKDIR%
    CALL:LogMe "[I] [fetchMsiPkgThenValidByProcName] %~3不存在，执行静默安装%~1"
    start %WORKDIR%\%~2 /quiet
    set _rtn=1
)
CALL:LogMe "[I] [fetchMsiPkgThenValidByProcName] %~1成功完成"
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

@REM function 通过在注册表中查找是否已安装
:judgeInstallByRegName
SETLOCAL
@REM param %~1 过程描述
@REM param %~2 注册表中的名称
@REM param %~3 包名
set EXITNUM=0
reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | findstr %~2 >nul
if %errorlevel%==0 (
    color 47
    echo %~1
    set EXITNUM=1
) else (
    wmic product get name | findstr %~3
    if %errorlevel%==0 (
        echo %~1 
        wmic product where name=%~3 call uninstall
    )
)
set _result=%EXITNUM%
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%