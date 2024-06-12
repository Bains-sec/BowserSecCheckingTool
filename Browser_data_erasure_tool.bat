pushd %~dp0
powershell.exe -command ^
  "& {set-executionpolicy Remotesigned -Scope Process; .'.\Browser_data_erasure_tool.ps1' }"
popd
pause