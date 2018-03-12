!addplugindir /x86-ansi ".\..\..\Plugins\x86-ansi"
!addplugindir /x86-unicode ".\..\..\Plugins\x86-unicode"
!addincludedir ".\..\..\Include"

!include UAC.nsh
!include NsisMultiUser.nsh
!include LogicLib.nsh
!include ".\..\Common\Utils.nsh"

!define PRODUCT_NAME "NsisMultiUser NSIS Full Demo" ; name of the application as displayed to the user
!define VERSION "1.0" ; main version of the application (may be 0.1, alpha, beta, etc.)
!define PROGEXE "calc.exe" ; main application filename
!define COMPANY_NAME "Alex Mitev" ; company, used for registry tree hierarchy
!define PLATFORM "Win64"
!define MIN_WIN_VER "XP"
!define SINGLE_INSTANCE_ID "${COMPANY_NAME} ${PRODUCT_NAME} Unique ID" ; do not change this between program versions!
!define LICENSE_FILE "License.txt" ; license file, optional

; NsisMultiUser optional defines
!define MULTIUSER_INSTALLMODE_ALLOW_BOTH_INSTALLATIONS 0
!define MULTIUSER_INSTALLMODE_ALLOW_ELEVATION 1
!define MULTIUSER_INSTALLMODE_ALLOW_ELEVATION_IF_SILENT 0
!define MULTIUSER_INSTALLMODE_DEFAULT_ALLUSERS 1
!if ${PLATFORM} == "Win64"
	!define MULTIUSER_INSTALLMODE_64_BIT 1
!endif
!define MULTIUSER_INSTALLMODE_DISPLAYNAME "${PRODUCT_NAME} ${VERSION} ${PLATFORM}"	

; Installer Attributes
Name "${PRODUCT_NAME} ${VERSION} ${PLATFORM}"
OutFile "Setup_NSIS_Full.exe"
BrandingText "�2017 ${COMPANY_NAME}"

AllowSkipFiles off
SetOverwrite on ; (default setting) set to on except for where it is manually switched off
ShowInstDetails show 
SetCompressor /SOLID lzma
XPStyle on

; Pages
!ifdef LICENSE_FILE	
	PageEx license 
		PageCallbacks PageWelcomeLicensePre EmptyCallback EmptyCallback
		LicenseData ".\..\..\${LICENSE_FILE}"
	PageExEnd	
!endif

PageEx license 
	PageCallbacks PageWelcomeLicensePre EmptyCallback EmptyCallback
	LicenseData "readme.txt"
PageExEnd	

!insertmacro MULTIUSER_PAGE_INSTALLMODE 

PageEx components
PageExEnd

PageEx directory
	PageCallbacks PageDirectoryPre PageDirectoryShow EmptyCallback
PageExEnd

PageEx instfiles
PageExEnd

!include Uninstall.nsh

InstType "Typical" 
InstType "Minimal" 
InstType "Full" 

Section "Core Files (required)" SectionCoreFiles
	SectionIn 1 2 3 RO
				
	; if there's an installed version, uninstall it first (I chose not to start the uninstaller silently, so that user sees what failed)
	; if both per-user and per-machine versions are installed, unistall the one that matches $MultiUser.InstallMode
	StrCpy $0 ""
	${if} $HasCurrentModeInstallation == 1
		StrCpy $0 "$MultiUser.InstallMode"
	${else}
		!if	${MULTIUSER_INSTALLMODE_ALLOW_BOTH_INSTALLATIONS} == 0
			${if}	$HasPerMachineInstallation == 1
				StrCpy $0 "AllUsers" ; if there's no per-user installation, but there's per-machine installation, uninstall it 
			${elseif}	$HasPerUserInstallation == 1
				StrCpy $0 "CurrentUser" ; if there's no per-machine installation, but there's per-user installation, uninstall it
			${endif}	
		!endif
	${endif}
		
	${if} "$0" != ""
		${if} $0 == "AllUsers"
			StrCpy $1 "$PerMachineUninstallString"
			StrCpy $3 "$PerMachineInstallationFolder"
		${else}
			StrCpy $1 "$PerUserUninstallString"
			StrCpy $3 "$PerUserInstallationFolder"
		${endif}
		${if} ${silent}
			StrCpy $2 "/S"
		${else}	
			StrCpy $2 ""
		${endif}	
		
		HideWindow
		ClearErrors
		StrCpy $0 0
		ExecWait '$1 /SS $2 _?=$3' $0 ; $1 is quoted in registry; the _? param stops the uninstaller from copying itself to the temporary directory, which is the only way for ExecWait to work
		
		${if} ${errors} ; stay in installer
			SetErrorLevel 2 ; Installation aborted by script
			BringToFront
			Abort "Error executing uninstaller."
		${else}	
			${Switch} $0
				${Case} 0 ; uninstaller completed successfully - continue with installation
					BringToFront 
					${Break}									
				${Case} 1 ; Installation aborted by user (cancel button)
				${Case} 2 ; Installation aborted by script
					SetErrorLevel $0
					Quit ; uninstaller was started, but completed with errors - Quit installer
				${Default} ; all other error codes - uninstaller could not start, elevate, etc. - Abort installer
					SetErrorLevel $0
					BringToFront
					Abort "Error executing uninstaller."
			${EndSwitch}				
		${endif}		
			
		Delete "$2\${UNINSTALL_FILENAME}"	; the uninstaller doesn't delete itself when not copied to the temp directory
		RMDir "$2"		
	${endif}	
		
	SetOutPath $INSTDIR
	; Write uninstaller and registry uninstall info as the first step,
	; so that the user has the option to run the uninstaller if sth. goes wrong 
	WriteUninstaller "${UNINSTALL_FILENAME}"			
	!insertmacro MULTIUSER_RegistryAddInstallInfo ; add registry keys		

	File "C:\Windows\System32\${PROGEXE}" 
	!ifdef LICENSE_FILE
		File ".\..\..\${LICENSE_FILE}"	
	!endif
SectionEnd

Section "Documentation" SectionDocumentation	
	SectionIn 1 3
	
	SetOutPath $INSTDIR	
	File "readme.txt" 
	
SectionEnd

SectionGroup /e "Integration" SectionGroupIntegration

Section "Program Group" SectionProgramGroup
	SectionIn 1	3
	
	!insertmacro MULTIUSER_GetCurrentUserString 0
	CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}$0"
	CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}$0\${PRODUCT_NAME}.lnk" "$INSTDIR\${PROGEXE}"
		
	!ifdef LICENSE_FILE
		CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}$0\License Agreement.lnk" "$INSTDIR\${LICENSE_FILE}"	
	!endif
	${if} $MultiUser.InstallMode == "AllUsers" 
		CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}$0\Uninstall.lnk" "$INSTDIR\${UNINSTALL_FILENAME}" "/allusers"
	${else}
		CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}$0\Uninstall.lnk" "$INSTDIR\${UNINSTALL_FILENAME}" "/currentuser"
	${endif}
SectionEnd

Section "Dektop Icon" SectionDesktopIcon
	SectionIn 1 3

	!insertmacro MULTIUSER_GetCurrentUserString 0
	CreateShortCut "$DESKTOP\${PRODUCT_NAME}$0.lnk" "$INSTDIR\${PROGEXE}"	
SectionEnd

Section /o "Start Menu Icon" SectionStartMenuIcon
	SectionIn 3

	!insertmacro MULTIUSER_GetCurrentUserString 0
	CreateShortCut "$STARTMENU\${PRODUCT_NAME}$0.lnk" "$INSTDIR\${PROGEXE}"
SectionEnd

Section /o "Quick Launch" SectionQuickLaunchIcon
	SectionIn 3

	; The $QUICKLAUNCH folder is always only for the current user
	CreateShortCut "$QUICKLAUNCH\${PRODUCT_NAME}.lnk" "$INSTDIR\${PROGEXE}"
SectionEnd
SectionGroupEnd

Section "-Write Install Size" ; hidden section, write install size as the final step
	!insertmacro MULTIUSER_RegistryAddInstallSizeInfo
SectionEnd

; Callbacks 
Function .onInit
	!insertmacro CheckPlatform ${PLATFORM}
	!insertmacro CheckMinWinVer ${MIN_WIN_VER}
	${ifnot} ${UAC_IsInnerInstance}
		!insertmacro CheckSingleInstance "${SINGLE_INSTANCE_ID}"
	${endif}	

	!insertmacro MULTIUSER_INIT		
FunctionEnd

Function EmptyCallback
FunctionEnd

Function PageWelcomeLicensePre		
	${if} $InstallShowPagesBeforeComponents == 0
		Abort ; don't display the Welcome and License pages for the inner instance 
	${endif}	
FunctionEnd

Function PageDirectoryPre	
	GetDlgItem $0 $HWNDPARENT 1		
	${if} ${SectionIsSelected} ${SectionProgramGroup}		
		SendMessage $0 ${WM_SETTEXT} 0 "STR:$(^NextBtn)" ; this is not the last page before installing
	${else}
		SendMessage $0 ${WM_SETTEXT} 0 "STR:$(^InstallBtn)" ; this is the last page before installing
	${endif}		
FunctionEnd

Function PageDirectoryShow
	${if} $CmdLineDir != ""
		FindWindow $R1 "#32770" "" $HWNDPARENT
		
		GetDlgItem $0 $R1 1019 ; Directory edit
		SendMessage $0 ${EM_SETREADONLY} 1 0 ; read-only is better than disabled, as user can copy contents
		
		GetDlgItem $0 $R1 1001 ; Browse button
		EnableWindow $0 0	
	${endif}			
FunctionEnd

Function .onUserAbort
	MessageBox MB_YESNO|MB_ICONEXCLAMATION "Are you sure you want to quit $(^Name) Setup?" IDYES mui.quit

	Abort
	mui.quit:	
FunctionEnd

Function .onInstFailed
	MessageBox MB_ICONSTOP "${PRODUCT_NAME} ${VERSION} could not be fully installed.$\r$\nPlease, restart Windows and run the setup program again." /SD IDOK
FunctionEnd

