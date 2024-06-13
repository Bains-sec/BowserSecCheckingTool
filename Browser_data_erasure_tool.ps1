# 在脚本开始时创建输出文件名
$outputFileName = "output_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt"

# 重定向所有输出到文件
Start-Transcript -Path $outputFileName


# 第一部分：搜索网站在浏览器中的出现情况的功能
$websites = Get-Content -Path ".\websites.txt"
$searchingSites = $websites -join "、"
Write-Host "##################################################################"
Write-Host "正在搜索 $searchingSites"

$foundResults = @()
foreach ($website in $websites) {
    $found = $false
    $result = [PSCustomObject]@{ 
        Website = $website
        FoundInBrowsers = @()
    }
    $browsers = @(
        # 浏览器的配置信息
		@{
            Name = "Google Chrome"
            CookiePath = "$env:APPDATA\..\Local\Google\Chrome\User Data\Default\Cookies"
            PasswordPath = "$env:APPDATA\..\Local\Google\Chrome\User Data\Default\Login Data"
        },
        @{
            Name = "Mozilla Firefox"
			CookiePath = "$env:APPDATA\..\Roaming\Mozilla\Firefox\Profiles\myejyohz.default-release\cookies.sqlite"
			PasswordPath = "$env:APPDATA\..\Roaming\Mozilla\Firefox\Profiles\myejyohz.default-release\logins.json"
        },
        @{
            Name = "360se"
            CookiePath = "$env:LOCALAPPDATA\..\Local\360Browser\Browser\User Data\Default\Cookies"
            PasswordPath = "$env:LOCALAPPDATA\..\Local\360Browser\Browser\User Data\Default\Login Data"
        },
		@{
            Name = "Microsoft Edge"
            CookiePath = "$env:LOCALAPPDATA\..\Local\Microsoft\Edge\User Data\Default\Cookies"
            PasswordPath = "$env:LOCALAPPDATA\..\Local\Microsoft\Edge\User Data\Default\Login Data"
        },
		@{
            Name = "Safari"
            CookiePath = "$env:APPDATA\..\Roaming\Apple Computer\Safari\Cookies\Cookies.binarycookies"
            PasswordPath = "$env:APPDATA\..\Roaming\Apple Computer\Safari\Form Values\*.json"
        },
		@{
            Name = "Internet Explorer"
            CookiePath = "$env:LOCALAPPDATA\..\Local\Microsoft\Windows\INetCookies"
            PasswordPath = "$env:LOCALAPPDATA\..\Local\Microsoft\Windows\INetCache\*.dat"
        },
		@{
            Name = "2345Explorer"
            CookiePath = "$env:LOCALAPPDATA\..\Local\2345Explorer\Browser\User Data\Default\Cookies"
            PasswordPath = "$env:LOCALAPPDATA\..\Local\2345Explorer\Browser\User Data\Default\Login Data"
        },
		@{
            Name = "QQ Browser"
            CookiePath = "$env:LOCALAPPDATA\..\Local\Tencent\QQBrowser\User Data\Default\Cookies"
            PasswordPath = "$env:LOCALAPPDATA\..\Local\Tencent\QQBrowser\User Data\Default\Login Data"
        },
		@{
            Name = "UCBrowser"
            CookiePath = "$env:LOCALAPPDATA\..\Local\UCBrowser\User Data\Default\Cookies"
            PasswordPath = "$env:LOCALAPPDATA\..\Local\UCBrowser\User Data\Default\Login Data"
        },
		@{
            Name = "BrowserLianLuo"
            CookiePath = "C:\Users\$env:USERNAME\AppData\Local\BrowserLianLuo\User Data\Default\Cookies"
            PasswordPath = "C:\Users\$env:USERNAME\AppData\Local\BrowserLianLuo\User Data\Default\Login Data"
        },
        @{
            Name = "Quark"
            CookiePath = "C:\Users\$env:USERNAME\AppData\Local\Quark\User Data\Default\Cookies"
            PasswordPath = "C:\Users\$env:USERNAME\AppData\Local\Quark\User Data\Default\Login Data"
        }
      )

    foreach ($browser in $browsers) {
        $cookies = Get-Content $browser.CookiePath -ErrorAction SilentlyContinue
        $passwords = Get-Content $browser.PasswordPath -ErrorAction SilentlyContinue

        if ($cookies -match $website) {
            $result.FoundInBrowsers += "$($browser.Name) 的cookie"
            $found = $true
        }

        if ($passwords -match $website) {
            $result.FoundInBrowsers += "$($browser.Name) 保存的密码文件"
            $found = $true
        }
    }

    if (-not $found) {
        $result.FoundInBrowsers += "未在任何浏览器中找到"
    }
    $foundResults += $result
}

foreach ($result in $foundResults) {
    if ($result.FoundInBrowsers -notcontains "未在任何浏览器中找到") {
        Write-Host "[+]在 $($result.FoundInBrowsers -join '、') 中找到了 $($result.Website) 的信息"
    } else {
        Write-Host "未在任何浏览器中找到 $($result.Website) 的信息"
    }
}



# 第二部分：搜索浏览器并执行数据删除


# 函数：提示用户是否删除
function PromptForDeletion($item) {
    $response = Read-Host "是否要删除 $item？ (y/n)"
    if ($response -eq "y") {
        return $true
    } else {
        return $false
    }
}

# 函数：使用注册表检查浏览器是否已安装
function IsBrowserInstalledUsingRegistry($browserName) {
    $registryPaths = @{
        "Google Chrome" = @(
            "HKLM:\SOFTWARE\Google\Chrome",
            "HKLM:\SOFTWARE\Wow6432Node\Google\Chrome",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome",
            "HKLM:\SOFTWARE\Classes\Installer\Products\Google Chrome",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\Products\Google Chrome",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe"
        )
        "Mozilla Firefox" = @(
            "HKLM:\SOFTWARE\Mozilla\Mozilla Firefox",
            "HKLM:\SOFTWARE\Wow6432Node\Mozilla\Mozilla Firefox",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Mozilla Firefox",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Mozilla Firefox",
            "HKLM:\SOFTWARE\Classes\Installer\Products\Mozilla Firefox",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\Products\Mozilla Firefox",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe"
        )
        "Microsoft Edge" = @(
            "HKLM:\SOFTWARE\Microsoft\Edge",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Edge",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
        )
        "Internet Explorer" = @(
            "HKLM:\SOFTWARE\Microsoft\Internet Explorer",
            "HKCU:\Software\Microsoft\Internet Explorer"
        )
        "Safari" = @(
            "HKLM:\SOFTWARE\Apple Computer, Inc.\Safari",
            "HKCU:\Software\Apple Computer, Inc.\Safari"
        )
        "QQ Browser" = @(
            "HKLM:\SOFTWARE\Tencent\QQBrowser",
            "HKLM:\SOFTWARE\Wow6432Node\Tencent\QQBrowser",
            "HKCU:\Software\Tencent\QQBrowser"
        )
        "2345Explorer" = @(
            "HKLM:\SOFTWARE\2345\Explorer",
            "HKLM:\SOFTWARE\Wow6432Node\2345\Explorer",
            "HKCU:\Software\2345\Explorer"
        )
        "360se" = @(
            "HKLM:\SOFTWARE\360Browser",
            "HKLM:\SOFTWARE\Wow6432Node\360Browser",
            "HKCU:\Software\360Browser"
        )
        "UCBrowser" = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\UCBrowser",
            "HKLM:\SOFTWARE\UCBrowser",
            "HKCU:\Software\UCBrowser"
        )
		"BrowserLianLuo" = @(
            "HKLM:\SOFTWARE\BrowserLianLuo",
            "HKCU:\Software\BrowserLianLuo"
        )
        "Quark" = @(
            "HKLM:\SOFTWARE\Quark",
			"HKLM:\SOFTWARE\Wow6432Node\Quark",
            "HKCU:\Software\Quark"
        )
    }
    
    $browserPaths = $registryPaths[$browserName]
    foreach ($path in $browserPaths) {
        if (Test-Path $path) {
            return $true
        }
    }
    return $false
}


# 函数：在默认路径中搜索浏览器安装
function SearchForBrowserInstallationInDefaultPaths($browserNames) {
    $currentUser = $env:USERNAME
    $browserPaths = @{
        "Google Chrome" = @(
            "C:\Program Files\Google\Chrome\Application\chrome.exe",
            "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
            "C:\Users\$currentUser\AppData\Local\Google\Chrome\Application\chrome.exe"
        )
        "Mozilla Firefox" = @(
            "C:\Program Files\Mozilla Firefox\firefox.exe",
            "C:\Program Files (x86)\Mozilla Firefox\firefox.exe",
            "C:\Users\$currentUser\AppData\Local\Mozilla Firefox\firefox.exe"
        )
        "Microsoft Edge" = @(
            "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
            "C:\Users\$currentUser\AppData\Local\Microsoft\Edge\Application\msedge.exe"
        )
        "Internet Explorer" = @(
            "C:\Program Files\Internet Explorer\iexplore.exe"
        )
        "Safari" = @(
            "C:\Program Files\Safari\Safari.exe",
            "C:\Users\$currentUser\AppData\Local\Safari\Safari.exe"
        )
        "QQ Browser" = @(
            "C:\Program Files\Tencent\QQBrowser\QQBrowser.exe",
            "C:\Users\$currentUser\AppData\Local\Tencent\QQBrowser\QQBrowser.exe"
        )
        "2345Explorer" = @(
            "C:\Program Files\2345Explorer\2345Explorer.exe",
            "C:\Users\$currentUser\AppData\Local\2345Explorer\2345Explorer.exe"
        )
        "360se" = @(
            "C:\Program Files\360\360se6\Application\360se.exe",
            "C:\Users\$currentUser\AppData\Local\360\360se6\Application\360se.exe"
        )
		"UCBrowser" = @(
            "C:\Program Files\UCBrowser\UCBrowser.exe",
            "C:\Program Files (x86)\UCBrowser\UCBrowser.exe",
            "C:\Users\$currentUser\AppData\Local\UCBrowser\UCBrowser.exe"
        )
        "BrowserLianLuo" = @(
            "C:\Program Files\BrowserLianLuo\BrowserLianLuo.exe",
            "C:\Users\$currentUser\AppData\Local\BrowserLianLuo\BrowserLianLuo.exe"
        )
        "Quark" = @(
            "C:\Program Files\Quark\QuarkBrowser.exe",
            "C:\Users\$currentUser\AppData\Local\Quark\QuarkBrowser.exe"
        )		
    }

    $installedBrowsers = @()
    
    foreach ($browserName in $browserNames) {
        $found = $false
        foreach ($path in $browserPaths[$browserName]) {
            if (Test-Path $path) {
                $installedBrowsers += $browserName
                Write-Host "[+]已找到 $browserName 的安装路径: $path"
                $found = $true
                break
            }
        }
        if (-not $found) {
            Write-Host "未找到 $browserName 的安装路径"
        }
    }
    return $installedBrowsers
}


# 函数：全盘搜索，逻辑是从注册表获取所有安装软件，然后找出有哪些浏览器
function SearchForBrowserInstallationInAllDrives($browserName) {
    Write-Host "正在搜索 $browserName "
    $registryPaths = @(
        "HKEY_CLASSES_ROOT\Installer\Product",
        "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKEY_CURRENT_USER\Software",
		"HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\App Paths",
		"HKEY_CURRENT_USER\Software\Classes",
		"HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run",
		"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Products",
        "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData",
        "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths",
		"HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment",
		"HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall",
		"HKEY_LOCAL_MACHINE\Software\Wow6432Node",
		"HKEY_LOCAL_MACHINE\Software\Classes\Installer",
        "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Installer",
		"HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\App Paths",
		"HKEY_LOCAL_MACHINE\Software",
		"HKEY_LOCAL_MACHINE\Software\Classes",
		"HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run",
		"HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Installer\UserData",
		"HKEY_LOCAL_MACHINE\Software\Classes\Installer\Product",
		"HKEY_LOCAL_MACHINE\SOFTWARE\Quark",
		"HKEY_LOCAL_MACHINE\SOFTWARE"
    )

    # 并行处理注册表搜索
    $registryResults = @()
    foreach ($path in $registryPaths) {
    $result = Start-Job -ScriptBlock {
        param($browserName, $path)
        $subKeys = Get-ChildItem -Path "Registry::$path" -ErrorAction SilentlyContinue
        if ($subKeys -ne $null) {
            foreach ($subKey in $subKeys) {
                if ($subKey.Name -like "*$using:browserName*") {
                    return $true
                }
            }
        }
        return $false
    } -ArgumentList $browserName, $path
    $registryResults += $result
}

    # 等待所有注册表作业完成
    Wait-Job -Job $registryResults | Out-Null

    # 获取所有作业的结果
    $results = Receive-Job -Job $registryResults | Where-Object { $_ -eq $true }
    if ($results.Count -gt 0) {
        return $true
    }

    # 缓存已搜索的驱动器
    $cachedDrives = @()

    # 并行处理注册表搜索
    $registryResults = @()
    foreach ($path in $registryPaths) {
        # Write-Host "正在搜索注册表路径 $path"
        $result = Start-Job -ScriptBlock {
            param($browserName, $path)
            $subKeys = Get-ChildItem -Path "Registry::$path" -ErrorAction SilentlyContinue
            if ($subKeys -ne $null) {
                foreach ($subKey in $subKeys) {
                    # Write-Host "在注册表路径 $path 中找到子项: $($subKey.Name)"
                    if ($subKey.Name -like "*$using:browserName*") {
                        return $true
                    }
                }
            }
            return $false
        } -ArgumentList $browserName, $path
        $registryResults += $result
    }

    # 等待所有注册表作业完成
    Wait-Job -Job $registryResults | Out-Null

    # 获取所有作业的结果
    $results = Receive-Job -Job $registryResults | Where-Object { $_ -eq $true }
    if ($results.Count -gt 0) {
        return $true
    }

    return $false
}



# 函数：清理浏览器数据
function CleanBrowserData($browserName, $path) {
    # 关闭浏览器进程
    Write-Host "[+]关闭所有 $browserName 进程"
    Get-Process | Where-Object {$_.MainWindowTitle -match $browserName} | Stop-Process -Force

    if (Test-Path $path) {
        Write-Host "[+]已找到 $path"
        if (PromptForDeletion "Cookies 和保存的账号密码") {
            if (Test-Path "$path\Cookies") {
                Remove-Item "$path\Cookies" -Force
                Write-Host "[+]已删除 $browserName 的 Cookies"
            } else {
                Write-Host "未找到 $browserName 的 Cookies"
            }
            if (Test-Path "$path\Login Data") {
                Remove-Item "$path\Login Data" -Force
                Write-Host "[+]已删除 $browserName 的保存的账号密码文件"
            } else {
                Write-Host "未找到 $browserName 的保存的账号密码文件"
            }
        } else {
            Write-Host "跳过删除 $browserName 的 Cookies 和保存的账号密码"
        }
    } else {
        Write-Host "未找到 $path"
    }

}


# 主程序
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

do {
    # 选择搜索浏览器安装的方法
    do {
        Write-Host "##################################################################"
        $searchMethod = Read-Host "选择搜索浏览器是否安装的方法:
1. 默认路径
2. 注册表
3. 全盘搜索
##################################################################
请输入选择 (1, 2, 或 3)"
        Write-Host "##################################################################"

        # 根据所选的搜索方法检查已安装的浏览器
        $installedBrowsers = @()
        if ($searchMethod -eq "1") {
            $defaultPathsBrowsers = @("Google Chrome", "Mozilla Firefox", "Microsoft Edge", "Internet Explorer", "Safari", "QQ Browser", "2345Explorer", "360se", "UCBrowser", "BrowserLianLuo", "Quark")
            foreach ($browser in $defaultPathsBrowsers) {
                if (SearchForBrowserInstallationInDefaultPaths $browser) {
                    $installedBrowsers += $browser
                }
            }
        } elseif ($searchMethod -eq "2") {
            $registryBrowsers = @("Google Chrome", "Mozilla Firefox", "Microsoft Edge", "Internet Explorer", "Safari", "QQ Browser", "2345Explorer", "360se", "UCBrowser", "BrowserLianLuo", "Quark")
            foreach ($browser in $registryBrowsers) {
                if (IsBrowserInstalledUsingRegistry $browser) {
                    $installedBrowsers += $browser
                }
            }
        } elseif ($searchMethod -eq "3") {
           $allDrivesBrowsers = @("Google Chrome", "Mozilla Firefox", "Microsoft Edge", "Internet Explorer", "Safari", "QQ Browser", "2345Explorer", "360se", "UCBrowser", "BrowserLianLuo", "Quark")
           foreach ($browser in $allDrivesBrowsers) {
               if (SearchForBrowserInstallationInAllDrives $browser) {
                   $installedBrowsers += $browser
               }
           }
       }
		
        # 输出已安装的浏览器
        if ($installedBrowsers.Count -gt 0) {
            Write-Host "已安装的浏览器:"
            $browserMenu = @{
                "Google Chrome" = 1
                "Mozilla Firefox" = 2
                "Microsoft Edge" = 3
                "Internet Explorer" = 4
                "Safari" = 5
                "QQ Browser" = 6
                "2345Explorer" = 7
                "360se" = 8
				"UCBrowser" = 9
				"BrowserLianLuo" = 10
				"Quark" = 11
            }
    
            foreach ($browser in $installedBrowsers) {
                $menuNumber = $browserMenu[$browser]
                Write-Host "$menuNumber. $browser"
            }
            Write-Host "##################################################################"
        } else {
            Write-Host "未找到任何浏览器，请尝试不同的搜索方法。"
            continue
        }

        # 选择要清理的浏览器
        do {
            Write-Host "选择要清理数据的浏览器:"
            # 显示浏览器选择菜单
            Write-Host "1. Google Chrome"
            Write-Host "2. Mozilla Firefox"
            Write-Host "3. Microsoft Edge"
            Write-Host "4. Internet Explorer"
            Write-Host "5. Safari"
            Write-Host "6. QQ Browser"
            Write-Host "7. 2345Explorer"
            Write-Host "8. 360se"
			Write-Host "9. UCBrowser"
			Write-Host "10. BrowserLianLuo"
            Write-Host "11. Quark"
            Write-Host "12. 返回上一步(请按N)"
			Write-Host "13. 退出程序"
            $choice = Read-Host "请选择"

            # 处理用户选择
            $choices = $choice -split ','
            switch ($choice) {
                "1" {
                    # 处理 Google Chrome 数据清理
                    $google_path = "C:\Users\$env:USERNAME\AppData\Local\Google\Chrome\User Data\Default"
                    CleanBrowserData "Google Chrome" $google_path
                }
                "2" {
                    # 处理 Mozilla Firefox 数据清理
					$firefox_path = "C:\Users\$env:USERNAME\AppData\Roaming\Mozilla\Firefox\Profiles\myejyohz.default-release"
                    CleanBrowserData "Mozilla Firefox" $firefox_path
                }
                "3" {
                    # 处理 Microsoft Edge 数据清理
                    $edge_path = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Edge\User Data\Default"
                    CleanBrowserData "Microsoft Edge" $edge_path
                }
                "4" {
                    # 处理 Internet Explorer 数据清理
                    $ie_path = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Windows\INetCache"
                    CleanBrowserData "Internet Explorer" $ie_path
                }
                "5" {
                    # 处理 Safari 数据清理
                    $safari_path = "C:\Users\$env:USERNAME\AppData\Local\Safari"
                    CleanBrowserData "Apple Safari" $safari_path
                }
                "6" {
                    # 处理 QQBrowser 数据清理
                    $qq_path = "C:\Users\$env:USERNAME\AppData\Roaming\Tencent\QQBrowser\User Data\Default"
                    CleanBrowserData "QQ Browser" $qq_path
                }
                "7" {
                    # 处理 2345Explorer 数据清理
                    $explorer2345_path = "C:\Users\$env:USERNAME\AppData\Local\2345Explorer\User Data\Default"
                    CleanBrowserData "2345Explorer" $explorer2345_path
                }
                "8" {
                    # 处理 360se 数据清理
                    $browser360_path = "C:\Users\$env:USERNAME\AppData\Local\360Chrome\Chrome\User Data\Default"
                    CleanBrowserData "360se" $browser360_path
                }
				"9" {
                    # 处理 UC Browser 数据清理
                    $ucBrowser_Path = "C:\Users\$env:USERNAME\AppData\Local\UCBrowser\User Data\Default"
                    CleanBrowserData "UCBrowser" $ucBrowser_Path
                }
				"10" {
                    # 处理 BrowserLianLuo 数据清理
                    $browserLianLuo_path = "C:\Users\$env:USERNAME\AppData\Local\BrowserLianLuo\User Data\Default"
                    CleanBrowserData "BrowserLianLuo" $browserLianLuo_path
                }
                "11" {
                    # 处理 QuarkBrowser 数据清理
                    $quarkBrowser_path = "C:\Users\$env:USERNAME\AppData\Local\Quark\User Data\Default"
                    CleanBrowserData "Quark" $quarkBrowser_path
                }
                "12" {
                    break  # 返回到外部循环
                }
				"13" {
                    # 返回上一步
                    exit
                }
                default {
                    Write-Host "无效的选择或浏览器未安装"
                }
            }

            $continue = Read-Host "是否要清理另一个浏览器的数据？ (y/n)"
            Write-Host "##################################################################"
        } while ($continue -eq "y")
    } while ($continue -eq "y")
} while ($true)


# 结束时停止输出重定向
Stop-Transcript
