!insertmacro DeleteRetryAbortFunc "un."

Section "un.Program Files" SectionUninstallProgram
	SectionIn RO

	; Try to delete the EXE as the first step - if it's in use, don't remove anything else
	!insertmacro un.DeleteRetryAbort "$INSTDIR\${PROGEXE}"
	!ifdef LICENSE_FILE
		!insertmacro un.DeleteRetryAbort "$INSTDIR\${LICENSE_FILE}"
	!endif

	; Clean up "Documentation"
	!insertmacro un.DeleteRetryAbort "$INSTDIR\readme.txt"

	; Clean up "Program Group" - we check that we created Start menu folder, if $StartMenuFolder is empty, the whole $SMPROGRAMS directory will be removed!
	${if} "$StartMenuFolder" != ""
		RMDir /r "$SMPROGRAMS\$StartMenuFolder"
	${endif}

	; Clean up "Dektop Icon"
	!insertmacro MULTIUSER_GetCurrentUserString $0
	!insertmacro un.DeleteRetryAbort "$DESKTOP\${PRODUCT_NAME}$0.lnk"

	; Clean up "Start Menu Icon"
	!insertmacro MULTIUSER_GetCurrentUserString $0
	!insertmacro un.DeleteRetryAbort "$STARTMENU\${PRODUCT_NAME}$0.lnk"

	; Clean up "Quick Launch Icon"
	!insertmacro un.DeleteRetryAbort "$QUICKLAUNCH\${PRODUCT_NAME}.lnk"
SectionEnd

Section /o "un.Program Settings" SectionRemoveSettings
	; this section is executed only explicitly and shouldn't be placed in SectionUninstallProgram
	DeleteRegKey HKCU "Software\${PRODUCT_NAME}"
SectionEnd

Section "-Uninstall" ; hidden section, must always be the last one!
	!insertmacro un.DeleteRetryAbort "$INSTDIR\${UNINSTALL_FILENAME}"
	; remove the directory only if it is empty - the user might have saved some files in it
	RMDir "$INSTDIR"
	
	; Remove the uninstaller from registry as the very last step - if sth. goes wrong, let the user run it again
	!insertmacro MULTIUSER_RegistryRemoveInstallInfo ; Remove registry keys	
SectionEnd

; Modern install component descriptions
!insertmacro MUI_UNFUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${SectionUninstallProgram} "Uninstall ${PRODUCT_NAME} files."
	!insertmacro MUI_DESCRIPTION_TEXT ${SectionRemoveSettings} "Remove ${PRODUCT_NAME} program settings. Select only if you don't plan to use the program in the future."
!insertmacro MUI_UNFUNCTION_DESCRIPTION_END

; Callbacks
Function un.onInit
	${GetParameters} $R0

	${GetOptions} $R0 "/uninstall" $R1
	${ifnot} ${errors}
		StrCpy $RunningFromInstaller 1
	${else}
		StrCpy $RunningFromInstaller 0
	${endif}

	${GetOptions} $R0 "/SS" $R1
	${ifnot} ${errors}
		StrCpy $SemiSilentMode 1
		SetAutoClose true ; auto close (if no errors) if we are called from the installer; if there are errors, will be automatically set to false
	${else}
		StrCpy $SemiSilentMode 0
	${endif}

	${ifnot} ${UAC_IsInnerInstance}
		${andif} $RunningFromInstaller$SemiSilentMode == "00"
		!insertmacro CheckSingleInstance "${SINGLE_INSTANCE_ID}"
	${endif}

	!insertmacro MULTIUSER_UNINIT

	!insertmacro MUI_UNGETLANGUAGE ; we always get the language, since the outer and inner instance might have different language
FunctionEnd

Function un.PageInstallModeChangeMode
	!insertmacro MUI_STARTMENU_GETFOLDER "" $StartMenuFolder
FunctionEnd

Function un.PageComponentsPre
	${if} $SemiSilentMode == 1
		Abort ; if user is installing, no use to remove program settings anyway (should be compatible with all versions)
	${endif}
FunctionEnd

Function un.PageComponentsShow
	; Show/hide the Back button
	GetDlgItem $0 $HWNDPARENT 3
	ShowWindow $0 $UninstallShowBackButton
FunctionEnd

Function un.onUninstFailed
	${if} $SemiSilentMode == 0
		MessageBox MB_ICONSTOP "${PRODUCT_NAME} ${VERSION} could not be fully uninstalled.$\r$\nPlease, restart Windows and run the uninstaller again." /SD IDOK
	${else}
		MessageBox MB_ICONSTOP "${PRODUCT_NAME} could not be fully installed.$\r$\nPlease, restart Windows and run the setup program again." /SD IDOK
	${endif}
FunctionEnd
