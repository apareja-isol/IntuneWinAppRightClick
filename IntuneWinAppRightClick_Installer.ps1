# Install IntuneWinRightClick
$InstallPath = "C:\Program Files\IntuneWinAppUtil"

# Create Directory if doesn't exist
If (!(Test-Path $InstallPath)){
    New-Item -ItemType Directory -Path $InstallPath -Force| Out-Null
}

# Download Latest IntuneWinAppUtil
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/IntuneWinAppUtil.exe" -OutFile "$InstallPath\IntuneWinAppUtil.exe"

# Create IntuneWinAppUtil.ps1
# .exe/.msi full path will be passed as an argument to the script
# Path is extracted and Output folder is created on the Parent Directory (..\Output)
# A log file with a timestamp is created on the Output folder
# IntuneWinAppUtil.exe is called with the quite/force argument
# .intunewin application is created on Output folder
$IntuneWinAppUtil = "$InstallPath\IntuneWinAppUtil.ps1"
@'
$SetupFile = [System.IO.FileInfo]$args[0]
$SourceFolder = $SetupFile.DirectoryName
$TimeStamp = Get-Date -Format "yyyyMMddhhmm"
$LogName = "$($SetupFile.BaseName).$TimeStamp.log"
$OutputFolder = (([System.IO.DirectoryInfo]$SetupFile.DirectoryName).Parent).FullName + "\Output"
$SetupFile = [String]$SetupFile
If (!(Test-Path $OutputFolder)){
    New-Item -ItemType Directory -Path $OutputFolder -Force| Out-Null
}
Start-Process -FilePath "$PSScriptRoot\IntuneWinAppUtil.exe" -ArgumentList "-c ""$SourceFolder"" -s ""$SetupFile"" -o ""$OutputFolder"" -q" -NoNewWindow -RedirectStandardOutput "$OutputFolder\$LogName"
Start $OutputFolder
'@ | Out-File -FilePath $IntuneWinAppUtil


#Configure registry to add Right Click option to .EXE and .MSI
$powershell = "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -File ""$IntuneWinAppUtil"" ""%L"""
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
# .EXE
New-Item -Path "HKCR:\exefile\shell" -Name "IntuneWinApputil" | Out-Null
Set-Item -Path "HKCR:\exefile\shell\IntuneWinApputil" -Value "Create IntuneWinApp"
New-Item -Path "HKCR:\exefile\shell\IntuneWinApputil" -Name "command" | Out-Null
Set-Item -Path "HKCR:\exefile\shell\IntuneWinApputil\command" -Value $powershell
# .MSI
New-Item -Path "HKCR:\Msi.Package\shell" -Name "IntuneWinApputil" | Out-Null
Set-Item -Path "HKCR:\Msi.Package\shell\IntuneWinApputil" -Value "Create IntuneWinApp"
New-Item -Path "HKCR:\Msi.Package\shell\IntuneWinApputil" -Name "command" | Out-Null
Set-Item -Path "HKCR:\Msi.Package\shell\IntuneWinApputil\command" -Value $powershell
Remove-PSDrive -Name HKCR
