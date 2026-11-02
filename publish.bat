@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

rem ============================================================
rem  吊销名单一键发布：导出 → 提交 → 推送（走 10090 加速器）
rem  用法：
rem    publish.bat            只同步当前吊销名单
rem    publish.bat <lid>      先吊销该 lid 再同步（可多个，空格分隔）
rem  说明：
rem    - 凭据已缓存（首次 OAuth 已完成），本脚本不再弹任何窗口
rem    - 加速器（127.0.0.1:10090）没开时自动回落直连（慢但能通）
rem ============================================================

set "PY=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if not exist "%PY%" set "PY=python"
set "TOOL_DIR=%~dp0.."
set "REPO_DIR=%~dp0"

rem ---- 可选：先吊销 ----
if "%~1"=="" goto :export
:revoke_loop
if "%~1"=="" goto :export
echo [publish] 吊销 %~1
pushd "%TOOL_DIR%"
"%PY%" sign_license.py --revoke %~1
popd
shift
goto :revoke_loop

:export
echo [publish] 导出吊销名单
pushd "%TOOL_DIR%"
"%PY%" sign_license.py --export-revocations "%REPO_DIR%revocations.json"
popd

rem ---- git 走加速器（本仓库级配置已固化；脚本再兜底一次） ----
pushd "%REPO_DIR%"
git config http.proxy http://127.0.0.1:10090
git config http.sslBackend openssl

git status --porcelain | findstr . >nul && (
  git add revocations.json README.md publish.bat
  git commit -m "revocations update %date% %time%"
)

echo [publish] 推送（走 10090 加速器）...
git push origin main 2>&1
if errorlevel 1 (
  echo [publish] 加速器通道失败，回落直连重试...
  git config --unset http.proxy
  git push origin main 2>&1
  git config http.proxy http://127.0.0.1:10090
)

echo [publish] 刷新 jsDelivr CDN 缓存...
curl -s -m 10 "https://purge.jsdelivr.net/gh/Furkedr/cfh-devkit-revocations@main/revocations.json" >nul 2>&1

popd
echo [publish] 完成。客户下次启动程序即生效。
endlocal
