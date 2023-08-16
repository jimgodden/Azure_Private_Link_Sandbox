# ensures that Windows PowerShell is used
Write-Host "Run this script in Windows PowerShell or else it will fail!"

# npcap for using Wireshark for taking packet captures
Invoke-WebRequest -Uri "https://npcap.com/dist/npcap-1.75.exe" -OutFile "c:\npcap-1.75.exe"
c:\npcap-1.75.exe

# Package required for installing Windows Terminal
Invoke-WebRequest -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile "c:\Microsoft.VCLibs.x64.14.00.Desktop.appx"
Add-AppxPackage "c:\Microsoft.VCLibs.x64.14.00.Desktop.appx"

Invoke-WebRequest -Uri "https://github.com/microsoft/terminal/releases/download/v1.16.10261.0/Microsoft.WindowsTerminal_Win10_1.16.10261.0_8wekyb3d8bbwe.msixbundle" -OutFile "c:\Microsoft.WindowsTerminal_Win10_1.16.10261.0_8wekyb3d8bbwe.msixbundle"
Add-AppxPackage "c:\Microsoft.WindowsTerminal_Win10_1.16.10261.0_8wekyb3d8bbwe.msixbundle"

$DesktopFilePath = "C:\Users\$ENV:USERNAME\Desktop\"
Set-Shortcut -ApplicationFilePath "C:\Program Files\Wireshark\Wireshark.exe"  -DestinationFilePath "${DesktopFilePath}Wireshark.lnk"

