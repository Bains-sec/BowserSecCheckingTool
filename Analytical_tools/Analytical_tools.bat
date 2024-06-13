pushd %~dp0
powershell.exe -command ^
  "& {set-executionpolicy Remotesigned -Scope Process; .'.\Analytical_tools.ps1' }"
popd
pause