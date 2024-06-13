# 获取脚本所在路径
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# 创建输出文件名
$outputFileName = Join-Path -Path $scriptPath -ChildPath ("result\output_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

# 重定向所有输出到文件
Start-Transcript -Path $outputFileName

# 获取脚本所在路径下所有的记录txt文件
$scriptPath = $PSScriptRoot
$recordFiles = Get-ChildItem -Path $scriptPath -Filter "*.txt"

# 初始化存储信息的人和执行删除操作的人的数组
$peopleWithInfo = @()
$peopleWithoutInfo = @()
$peopleWithDeletion = @()
$peopleWithoutDeletion = @()

# 遍历每个记录文件进行分析
foreach ($file in $recordFiles) {
    $content = Get-Content $file.FullName

    # 判断是否在记录中找到了存储的信息
    $hasStoredInfo = $content -match "找到了 (.*?) 的信息"
    if ($hasStoredInfo) {
        $peopleWithInfo += $file.BaseName
    } else {
        $peopleWithoutInfo += $file.BaseName
    }

    # 判断是否执行了删除操作
    if ($content -match "已删除 (.*?) 的保存的账号密码文件") {
        $peopleWithDeletion += $file.BaseName
    } else {
        $peopleWithoutDeletion += $file.BaseName
    }
}

# 去除重复的人员，并输出分析结果
$peopleWithInfo = $peopleWithInfo | Sort-Object -Unique
$peopleWithoutInfo = $peopleWithoutInfo | Sort-Object -Unique
$peopleWithDeletion = $peopleWithDeletion | Sort-Object -Unique
$peopleWithoutDeletion = $peopleWithoutDeletion | Sort-Object -Unique

Write-Host "存储了信息的人：" $peopleWithInfo
Write-Host "没有存储信息的人：" ($peopleWithoutInfo | Where-Object {$_ -notin $peopleWithInfo})
Write-Host "存储了信息并执行了删除操作的人：" $peopleWithDeletion
Write-Host "存储了信息但没有执行删除操作的人：" ($peopleWithInfo | Where-Object {$_ -notin $peopleWithDeletion})

# 提示用户按任意键继续
Read-Host "按任意键继续..."

# 结束时停止输出重定向
Stop-Transcript
