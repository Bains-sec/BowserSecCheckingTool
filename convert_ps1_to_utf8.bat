@echo off
for %%i in (*.ps1) do (
    powershell -Command "& {(Get-Content -Path '%%i' -Encoding Default) | Set-Content -Path '%%i' -Encoding UTF8}"
)