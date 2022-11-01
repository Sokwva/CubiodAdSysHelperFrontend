@echo off
echo CubiodAdSys-Initializer
::%errorlevel% ����Ϊ0ʱ˵������֮�ϵ�����ִ��û����
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
    CALL:LogMe "[W] д��ִ���¼�����ļ�ʧ��"
    echo %logRaw% >> %LOGFILE%
)

@REM echo CubiodAdSys
if not exist %WORKDIR% (
    CALL:LogMe "[I] ��������Ŀ¼"
    md %WORKDIR%
)
if not exist %CORECOMPDIR% (
    CALL:LogMe "[I] ��������Ŀ¼Core"
    md %CORECOMPDIR%
)
@REM ���ӹ����洢
CALL:LogMe "[I] ���Ӵ洢����"
net use %COMMONSHAREDIR%
if %errorlevel% NEQ 0 (
    CALL:LogMe "[W] Ĭ�Ϸ�ʽ���Ӵ洢����ʧ�ܣ���Ҫ�л�����"
    net use %COMMONSHAREDIR% /user:app 1
)

::============ Main Function Area =============
if "%~1" NEQ "" (
    @REM CALL:MsgBox "neq empty"
    CALL:LogMe "[I] [ģ��ģʽ] ������ȡ %~1"
    copy /Y /BV %COMMONSHAREDIR%\%~1 %WORKDIR%
    EXIT
) else (
    CALL:LogMe "[I] [Ĭ��ģʽ] Start"
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

@REM Ask ѯ�����-����ֻ��������㷵�أ��ٴ�����ڽ���ᱻ���
:Ask
SETLOCAL
@REM param %~1 ����
@REM param %~2 ��Ϣ
@REM param %~3 ��ѡ-������
set Vbscript=Msgbox("%~2",1,%1)
for /f "Delims=" %%a in ('MsHta VBScript:Execute("CreateObject(""Scripting.Filesystemobject"").GetStandardStream(1).Write(%Vbscript:"=""%)"^)(Close^)') do Set "MsHtaReturnValue=%%a"
set ReturnValue1=ȷ��
set ReturnValue2=ȡ����رմ���
if %MsHtaReturnValue% == 1 (
    @REM 1
    CALL:LogMe "[I] [%~3] Title:%~1 Msg:%~2 �û���ȷ��"
    echo ������磡���ڵȵ��㡣
) else (
    @REM 2
    CALL:LogMe "[I] [%~3] Title:%~1 Msg:%~2 �û��Ѿܾ�"
    echo �ټ���
)
ENDLOCAL & SET _returnFuncAsk=%MsHtaReturnValue% & EXIT /B %EXITNUM%

@REM logEvent ��¼�¼�
:LogMe
SETLOCAL
@REM param %~1 ��Ϣ
for /f "delims=" %%i in ( 'date /t' ) do set logRaw=%%i
for /f "delims=" %%i in ( 'time /t' ) do set logRaw=%logRaw%%%i
echo [AdSys] %logRaw% : %~1
echo [AdSys] %logRaw% : %~1 >> %LOGFILE%
ENDLOCAL & EXIT /B %EXITNUM%

@REM function SimpleMsgBox
:SimpleMsg
SETLOCAL
@REM param %~1 ��Ϣ����
msg * %~1
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

@REM function Cubiod-Windows Helper
:fetchADHelperHelper
SETLOCAL
@REM param %~1 �������� Cubiod-Windows-HelperHelper
@REM param %~2 ��ȡ������������ AdHelperFronter.exe
CALL:LogMe "[I] [fetchADHelperHelper] [%~1] ������"
copy /Y /BV %COMMONSHAREDIR%\%~2 %CORECOMPDIR%
if %errorlevel%==0 (
    start %CORECOMPDIR%\%~2
    set _rtn=0
) else (
    CALL:LogMe "[E] [fetchADHelperHelper] [%~1] ���� %~2 ʱ��������"
    set _rtn=1
)
CALL:LogMe "[I] [fetchADHelperHelper] [%~1] �ɹ����"
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

@REM function fetch-lsrunase
:fetch-lsrunase
SETLOCAL
CALL:LogMe "[I] [fetch-lsrunase] ������"
copy /Y /BV %COMMONSHAREDIR%\lsrunase.exe %CORECOMPDIR%
if %errorlevel%==0 (
    set _rtn=0
) else (
    echo ִ�и��� fetch-lsrunase ʱ��������
    CALL:LogMe "[E] [fetch-lsrunase] ����ʱ��������"
    set _rtn=1
)
CALL:LogMe "[I] [fetch-lsrunase] �ɹ����"
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

@REM function ͨ�������ж��Ƿ���ڴ������������װ
:fetchPkgThenValidByProcName
SETLOCAL
@REM param %~1 ��������
@REM param %~2 ��װ����
@REM param %~3 ���Ŀ�������
tasklist /nh | findstr %~3
if %errorlevel%==0 (
    CALL:LogMe "[I] [fetchPkgThenValidByProcName] �ж�%~3���ڣ�%~1����Ҫִ�У�����"
    set _rtn=0
) else (
    CALL:LogMe "[I] [fetchPkgThenValidByProcName] %~3�����ڣ�%~1��Ҫִ��"
    copy /Y /BV %COMMONSHAREDIR%\%~2 %WORKDIR%
    CALL:LogMe "[I] [fetchPkgThenValidByProcName] %~3�����ڣ�����%~2"
    start %WORKDIR%\%~2
    set _rtn=1
)
CALL:LogMe "[I] [fetchPkgThenValidByProcName] %~1�ɹ����"
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

@REM function ͨ�������ж��Ƿ���ڴ�MSI�����������װ
:fetchMsiPkgThenValidByProcName
SETLOCAL
@REM param %~1 ��������
@REM param %~2 ��װ����
@REM param %~3 ���Ŀ�������
tasklist /nh | findstr %~3
if %errorlevel%==0 (
    CALL:LogMe "[I] [fetchMsiPkgThenValidByProcName] �ж�%~3���ڣ�%~1����Ҫִ�У�����"
    set _rtn=0
) else (
    CALL:LogMe "[I] [fetchMsiPkgThenValidByProcName] %~3�����ڣ���ȡ%~1��"
    copy /Y /BV %COMMONSHAREDIR%\%~2 %WORKDIR%
    CALL:LogMe "[I] [fetchMsiPkgThenValidByProcName] %~3�����ڣ�ִ�о�Ĭ��װ%~1"
    start %WORKDIR%\%~2 /quiet
    set _rtn=1
)
CALL:LogMe "[I] [fetchMsiPkgThenValidByProcName] %~1�ɹ����"
set EXITNUM=0
ENDLOCAL & SET _result=%_rtn% & EXIT /B %EXITNUM%

@REM function ͨ����ע����в����Ƿ��Ѱ�װ
:judgeInstallByRegName
SETLOCAL
@REM param %~1 ��������
@REM param %~2 ע����е�����
@REM param %~3 ����
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