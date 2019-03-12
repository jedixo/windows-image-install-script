@echo off
REM Jake's install tool for WIM / SWM / ESD images.
REM execute install.bat and select installation OR drag a custom wim onto install.bat to install it


cls
title Windows Setup - %firmware_type% - %PROCESSOR_ARCHITECTURE% - 
set imagefolder=%~dp0
set automated=0
set PartitionSchema=mbr
set WindowsVersion=1
if "%1"=="" goto windows_version
set automated=1
goto partition_schema_settings



:windows_version
cls
echo **************************************************************************************************
echo --------------------------------------------------------------------------------------------------
echo                    Windows Deployment Utility for Windows Images
echo                                        By: Jake DIxon
echo --------------------------------------------------------------------------------------------------
echo **************************************************************************************************
echo.
echo                        What version of windows do you want to install?
echo.
echo      Selection           Version                         Edition                 Rev     Arch 
echo     ----------- -------------------------- ------------------------------------ ------ -------
echo         1        Microsoft Windows 10       Enterprise                           1809   (x64) 
echo         2        Microsoft Windows 10       Professional                         1809   (x64) 
echo         3        Microsoft Windows 10       Enterprise LTSC                      2019   (x64) 
echo         4        Microsoft Windows Server   Datacenter Core                      2019   (X64) 
echo         5        Microsoft Windows Server   Datacenter With Desktop Experience   2019   (x64) 
echo         6        Microsoft Windows 7        Professional                         SP1    (x64) 
echo         7        Microsoft Windows 7        Enteprise                            SP1    (x64) 
echo         8        Microsoft Windows XP       Professional                         SP3    (x86)
if exist %SYSTEMDRIVE%\setup.exe (
echo         s        Launch Windows Setup
)
echo         x        Exit                                                                          
echo.
echo To install a custom wim, drag and drop it here or onto install.bat or type a path.
echo.
set /p WindowsVersion=Enter a selection/path: 
if "%windowsVersion%"=="" goto windows_version
if %WindowsVersion% EQU x goto exit
if exist %SYSTEMDRIVE%\setup.exe (
if %WindowsVersion% EQU s goto winsetup
)
if %WindowsVersion% EQU 8 goto setup
if %WindowsVersion% EQU 1 goto partition_schema_settings
if %WindowsVersion% EQU 2 goto partition_schema_settings
if %WindowsVersion% EQU 3 goto partition_schema_settings
if %WindowsVersion% EQU 4 goto partition_schema_settings
if %WindowsVersion% EQU 5 goto partition_schema_settings
if %WindowsVersion% EQU 6 goto partition_schema_settings
if %WindowsVersion% EQU 7 goto partition_schema_settings
echo %WindowsVersion%|find ".wim" >nul
if errorlevel 1 (echo.) else goto drag
echo %WindowsVersion%|find ".swm" >nul
if errorlevel 1 (echo.) else goto drag
echo %WindowsVersion%|find ".esd" >nul
if errorlevel 1 (echo.) else goto drag
cls
goto windows_version
:drag
set automated=2
:partition_schema_settings
cls
echo **************************************************************************************************
echo --------------------------------------------------------------------------------------------------
echo                    Windows Deployment Utility for Windows Images
echo                                        By: Jake DIxon
echo --------------------------------------------------------------------------------------------------
echo **************************************************************************************************
echo.
echo  Firmware check...
echo  %firmware_type%
echo.
echo.
if %firmware_type% EQU UEFI goto u
set PartitionSchema=mbr
goto setup
:u
set PartitionSchema=gpt
goto setup
:setup
if %automated% EQU 1 (
  set disk=0
  pause
  goto dpprocess
) 
	echo list disk	> "%~dp0list.txt"
	echo exit	>> "%~dp0list.txt"
	cls
	echo **************************************************************************************************
	echo --------------------------------------------------------------------------------------------------
	echo                    Windows Deployment Utility for Windows Images
	echo                                        By: Jake DIxon
	echo --------------------------------------------------------------------------------------------------
	echo **************************************************************************************************
	echo.
	diskpart /s "%~dp0list.txt"
	echo.
	echo.
	set /p disk=select disk to install to (eg: 0): 

:dpprocess
echo select disk %disk% 					> "%~dp0part.txt"
echo clean 							>> "%~dp0part.txt"
echo convert %PartitionSchema%					>> "%~dp0part.txt"
IF %PartitionSchema% EQU gpt (
	echo create partition efi size^=100 			>> "%~dp0part.txt"
	echo format quick fs^=fat32 label^=^"System^"		>> "%~dp0part.txt"
	echo assign letter^=^"S^"				>> "%~dp0part.txt"
	echo create partition msr size^=16			>> "%~dp0part.txt"
) ELSE (
	IF %WindowsVersion% NEQ 8 (
		echo create partition primary size^=100			>> "%~dp0part.txt"
		echo format quick fs^=ntfs label^=^"System^"		>> "%~dp0part.txt"
		echo assign letter^=^"S^"				>> "%~dp0part.txt"
		echo active						>> "%~dp0part.txt"	
	)
)
echo create partition primary					>> "%~dp0part.txt"
echo shrink minimum^=500					>> "%~dp0part.txt"
echo format quick fs^=ntfs label^=^"Windows^"			>> "%~dp0part.txt"
if %WindowsVersion% EQU 8 (
	echo active						>> "%~dp0part.txt"
) 
echo assign letter^=^"W^"					>> "%~dp0part.txt"
if %WindowsVersion% NEQ 8 (
	echo create partition primary				>> "%~dp0part.txt"
	echo format quick fs^=ntfs label^=^"Recovery Tools^"	>> "%~dp0part.txt"
	echo assign letter^=^"R^"				>> "%~dp0part.txt"
	if %PartitionSchema% EQU gpt (
		echo set id^=^"de94bba4-06d1-4d40-a16a-bfd50179d6ac^"	>> "%~dp0part.txt"
		echo gpt attributes^=0x8000000000000001			>> "%~dp0part.txt"
	) else (
		echo set id=27						>> "%~dp0part.txt"
	)
)
echo list volume						>> "%~dp0part.txt"
echo exit							>> "%~dp0part.txt"
:setupf
if %automated% EQU 1 goto custom
title Windows Setup - %firmware_type% - %PROCESSOR_ARCHITECTURE% - %WindowsVersion%
cls
echo **************************************************************************************************
echo --------------------------------------------------------------------------------------------------
echo                    Windows Deployment Utility for Windows Images
echo                                        By: Jake DIxon
echo --------------------------------------------------------------------------------------------------
echo **************************************************************************************************
echo.
echo                 NOTE: This installer will overwrite disk %disk% and any
echo                 data on this disk. Do you want to continue with the setup?
echo.
echo.
set /p Confirmation=y/n: 
if %confirmation% EQU y goto yes
cls
if %confirmation% EQU n goto exit
goto setupf

:yes
if %automated% EQU 2 goto customdrag
cls
echo **************************************************************************************************
echo --------------------------------------------------------------------------------------------------
echo                    Windows Deployment Utility for Windows Images
echo                                        By: Jake DIxon
echo --------------------------------------------------------------------------------------------------
echo **************************************************************************************************
echo.
diskpart /s "%~dp0part.txt"
if %WindowsVersion% EQU 8 (
	dism /Apply-Image /ImageFile:"%imagefolder%xp.wim" /Index:1 /ApplyDir:w:\
) else (
	dism /Apply-Image /ImageFile:"%imagefolder%combined.swm" /SWMFile:"%imagefolder%combined*.swm" /Index:%WindowsVersion% /ApplyDir:W:\
	if %PartitionSchema% EQU gpt (
		%WINDIR%\System32\bcdboot W:\Windows /s S:
	) else (
		%WINDIR%\System32\bcdboot W:\Windows
	)
	md R:\Recovery\WindowsRE
	copy %imagefolder%winre.wim R:\Recovery\WindowsRE\winre.wim
	W:\Windows\System32\Reagentc /Setreimage /Path R:\Recovery\WindowsRE /Target W:\Windows
	W:\Windows\System32\Reagentc /Info /Target W:\Windows
)
goto exit
:customdrag
title Windows Setup - %firmware_type% - %PROCESSOR_ARCHITECTURE% - %WindowsVersion%
cls
echo **************************************************************************************************
echo --------------------------------------------------------------------------------------------------
echo                    Windows Deployment Utility for Windows Images
echo                                        By: Jake DIxon
echo --------------------------------------------------------------------------------------------------
echo **************************************************************************************************
echo.
diskpart /s "%~dp0part.txt"

echo %WindowsVersion%|find ".swm" >nul
if errorlevel 1 (goto cwim) else CALL :cswm %WindowsVersion%
:cwim
dism /Apply-Image /ImageFile:%WindowsVersion% /Index:1 /ApplyDir:W:\
if %PartitionSchema% EQU gpt (
	%WINDIR%\System32\bcdboot W:\Windows /s S:
) else (
	%WINDIR%\System32\bcdboot W:\Windows
)
md R:\Recovery\WindowsRE
copy %imagefolder%winre.wim R:\Recovery\WindowsRE\winre.wim
W:\Windows\System32\Reagentc /Setreimage /Path R:\Recovery\WindowsRE /Target W:\Windows
W:\Windows\System32\Reagentc /Info /Target W:\Windows
goto exit

:cswm
dism /Apply-Image /ImageFile:%1 /SWMfile:%~dpn1*.swm /Index:1 /ApplyDir:W:\
if %PartitionSchema% EQU gpt (
	%WINDIR%\System32\bcdboot W:\Windows /s S:
) else (
	%WINDIR%\System32\bcdboot W:\Windows
)
md R:\Recovery\WindowsRE
copy %imagefolder%winre.wim R:\Recovery\WindowsRE\winre.wim
W:\Windows\System32\Reagentc /Setreimage /Path R:\Recovery\WindowsRE /Target W:\Windows
W:\Windows\System32\Reagentc /Info /Target W:\Windows
goto exit

:custom
title Windows Setup - %firmware_type% - %PROCESSOR_ARCHITECTURE% - %1
cls
echo **************************************************************************************************
echo --------------------------------------------------------------------------------------------------
echo                    Windows Deployment Utility for Windows Images
echo                                        By: Jake DIxon
echo --------------------------------------------------------------------------------------------------
echo **************************************************************************************************
echo.
diskpart /s "%~dp0part.txt"

echo %1|find ".swm" >nul
if errorlevel 1 (goto awim) else goto aswm

:awim
dism /Apply-Image /ImageFile:%1 /Index:1 /ApplyDir:W:\
if %PartitionSchema% EQU gpt (
    %WINDIR%\System32\bcdboot W:\Windows /s S:
) else (
    %WINDIR%\System32\bcdboot W:\Windows
)
md R:\Recovery\WindowsRE
copy %imagefolder%winre.wim R:\Recovery\WindowsRE\winre.wim
W:\Windows\System32\Reagentc /Setreimage /Path R:\Recovery\WindowsRE /Target W:\Windows
W:\Windows\System32\Reagentc /Info /Target W:\Windows
goto exit

:aswm
dism /Apply-Image /ImageFile:%1 /SWMfile:%~dpn1*.swm /Index:1 /ApplyDir:W:\
if %PartitionSchema% EQU gpt (
	%WINDIR%\System32\bcdboot W:\Windows /s S:
) else (
	%WINDIR%\System32\bcdboot W:\Windows
)
md R:\Recovery\WindowsRE
copy %imagefolder%winre.wim R:\Recovery\WindowsRE\winre.wim
W:\Windows\System32\Reagentc /Setreimage /Path R:\Recovery\WindowsRE /Target W:\Windows
W:\Windows\System32\Reagentc /Info /Target W:\Windows
goto exit

:winsetup
%SYSTEMDRIVE%\setup.exe
goto exit

:exit
echo **************************************************************************************************
echo --------------------------------------------------------------------------------------------------
echo                    Windows Deployment Utility for Windows Images
echo                                        By: Jake DIxon
echo --------------------------------------------------------------------------------------------------
echo **************************************************************************************************
echo.
echo          The Installer Has Finished, please reboot the computer
echo.
echo.
pause
del "%~dp0part.txt"
del "%~dp0list.txt"
exit
