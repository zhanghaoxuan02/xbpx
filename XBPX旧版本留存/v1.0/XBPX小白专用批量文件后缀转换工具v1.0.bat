@echo off
:: ==========================================
:: 小白专用批量后缀修改工具 v1.0
:: 作者: zhanghaoxuan
:: ==========================================

:: 1. 初始化
setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%config_path.ini"
set "LOG_FILE=%SCRIPT_DIR%debug_log.txt"

:: 清空旧日志
echo ========================================== > "%LOG_FILE%"
echo 日志开始时间: %date% %time% >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"

:: 2. 自动提权
net session >nul 2>&1
if %errorlevel% neq 0 (
echo 正在请求管理员权限...
>"%temp%\getadmin.vbs" (
echo Set UAC = CreateObject^("Shell.Application"^)
echo UAC.ShellExecute "%~s0", "", "", "runas", 1
)
"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs" >nul 2>&1
exit /b
)

:: 3. 读取配置文件
call :LOG "开始读取配置文件"
set "WORK_DIR=未设置"

if exist "%CONFIG_FILE%" (
:: 使用 type 读取，防止 BOM 干扰
for /f "usebackq delims=" %%i in (`type "%CONFIG_FILE%"`) do set "WORK_DIR=%%i"

:: 检查路径有效性
if exist "!WORK_DIR!\" (
call :LOG "路径验证通过: !WORK_DIR!"
) else (
call :LOG "路径无效，重置变量"
set "WORK_DIR=未设置"
)
) else (
call :LOG "配置文件不存在"
)

:: 4. 主菜单
:MAIN_MENU
cls
title XBPX小白专用批量后缀修改工具 v1.0-zhanghaoxuan
color 0A

echo ========================================
echo XBPX小白专用批量后缀修改工具 v1.0
echo Powered by zhanghaoxuan
echo 欢迎使用本程序！请输入你想进行的操作
echo 输入示例：1+[回车]（其中[回车]代表您的操作）
echo ========================================
echo.
echo 当前目录: !WORK_DIR!
echo.
echo ========================================
echo [1] 开始批量重命名
echo [2] 设置工作目录
echo [3] 查看日志
echo [4] 退出
echo ========================================
echo.

set "choice="
set /p "choice=请选择 [1-4]: "

if "!choice!"=="1" goto :RENAME
if "!choice!"=="2" goto :SET_PATH
if "!choice!"=="3" goto :VIEW_LOG
if "!choice!"=="4" goto :EXIT

echo 输入错误，请重新选择
pause
goto :MAIN_MENU

:: ==========================================
:: 功能：设置工作目录
:: ==========================================
:SET_PATH
cls
echo ========================================
echo 设置工作目录
echo ========================================
echo.
echo 当前目录: !WORK_DIR!
echo.
set "NEW_PATH="
set /p "NEW_PATH=请输入完整路径: "

if "!NEW_PATH!"=="" (
echo 路径不能为空
pause
goto :SET_PATH
)

:: 去除首尾引号
for /f "delims=" %%i in ('echo !NEW_PATH!') do set "NEW_PATH=%%i"

:: 去除末尾反斜杠
if "!NEW_PATH:~-1!"=="\" set "NEW_PATH=!NEW_PATH:~0,-1%"

:: 验证路径
if not exist "!NEW_PATH!\" (
echo 错误：路径不存在
echo.
set /p "CREATE=是否创建此目录?;
if /i "!CREATE!"=="Y" (
mkdir "!NEW_PATH!" >nul 2>&1
if errorlevel 1 (
echo 创建目录失败
pause
goto :SET_PATH
)
) else (
goto :SET_PATH
)
)

:: [核心修复] 使用 set/p 写入法，彻底解决空格路径写入兼容性问题
(set /p "DUMMY=!NEW_PATH!" <nul) > "%CONFIG_FILE%"

set "WORK_DIR=!NEW_PATH!"
call :LOG "工作目录已设置: !WORK_DIR!"

echo.
echo [成功] 工作目录已设置为: !WORK_DIR!
pause
goto :MAIN_MENU

:: ==========================================
:: 功能：批量重命名
:: ==========================================
:RENAME
cls
echo ========================================
echo 批量重命名
echo ========================================
echo.

if "!WORK_DIR!"=="未设置" (
echo 错误：请先设置工作目录
pause
goto :MAIN_MENU
)

if not exist "!WORK_DIR!\" (
echo 错误：工作目录不存在
pause
goto :MAIN_MENU
)

echo 工作目录: !WORK_DIR!
echo.

:INPUT_EXT
set "NEW_EXT="
set /p "NEW_EXT=请输入新后缀名 (如 txt): "

if "!NEW_EXT!"=="" (
echo 后缀不能为空
goto :INPUT_EXT
)

:: 移除可能输入的点
if "!NEW_EXT:~0,1!"=="." set "NEW_EXT=!NEW_EXT:~1!"

:: 确认操作
echo.
echo ========================================
echo 将修改 !WORK_DIR! 中所有文件的后缀为 .!NEW_EXT!
echo ========================================
echo.
set /p "CONFIRM=确定继续?（输入Y+[回车]确定）;

if /i not "!CONFIRM!"=="Y" (
echo 操作取消
pause
goto :MAIN_MENU
)

:: 执行重命名
call :LOG "开始批量重命名，后缀: .!NEW_EXT!"
echo.
echo 正在处理...

set "COUNT=0"
set "target_dir=!WORK_DIR!"
if "!target_dir:~-1!"=="\" set "target_dir=!target_dir:~0,-1%"

for %%F in ("!target_dir!\*.*") do (
set "FILE=%%F"
set "NAME=%%~nxF"
set "BASE=%%~nF"

:: 跳过配置文件和目录
if /i not "!NAME!"=="config_path.ini" (
if not exist "!FILE!\" (
set "NEW_NAME=!BASE!.!NEW_EXT!"
ren "!FILE!" "!NEW_NAME!" >nul 2>&1
if !errorlevel! equ 0 (
echo [OK] !NAME! -^> !NEW_NAME!
set /a COUNT+=1
) else (
echo [FAIL] !NAME!
)
)
)
)

call :LOG "重命名完成，共处理 !COUNT! 个文件"
echo.
echo ========================================
echo 处理完成！共修改 !COUNT! 个文件
echo ========================================
echo.
pause
goto :MAIN_MENU

:: ==========================================
:: 功能：查看日志
:: ==========================================
:VIEW_LOG
cls
echo ========================================
echo 日志查看
echo ========================================
echo.
if exist "%LOG_FILE%" (
type "%LOG_FILE%"
) else (
echo 日志文件不存在
)
echo.
pause
goto :MAIN_MENU

:: ==========================================
:: 功能：退出
:: ==========================================
:EXIT
call :LOG "程序退出"
endlocal
exit /b 0

:: ==========================================
:: 子程序：日志记录
:: ==========================================
:LOG
set "MSG=%~1"
echo [!time!] !MSG! >> "%LOG_FILE%"
goto :EOF