COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Start up application
FILE:		rstartupProcess.asm

AUTHOR:		Jason Ho, Apr  3, 1995

METHODS:
	Name				Description
	----				-----------
	RSPGenProcessOpenApplication	Open application. Bring up language
					or country dialog.
	RSPGenProcessCloseApplication	Close the application.
	RSPGenProcessCreateNewStateFile	Make sure no state file is generated.
	RSPRstartupProcessShowLanguage	Show the language dialog.
	RSPRStartupProcesLanguageOK	Confirm language selection.
	RSPRstartupProcessShowHomeCountry
					Show the home country dialog.
	RSCLRstartCountryListQueryMoniker
					Query message to add the moniker of
					specified item to dynamic list.
	RSPRstartupProcessCountryOK	Do the country stuffs.
	RSPRstartupProcessShowDate	Set the date format, show date dialog.
	RSPRstartupProcessDateOK	Check if the date string is valid,
					set the date. 
	RSPRstartupProcessShowTime	Set the time format, show time dialog.
	RSPRstartupProcessTimeOK	Check if the time string is valid,
					set the time, and initiate the User
					data dialog.
	RSPRstartupProcessCheckSimCardInfo
					Send ECI message to check if
					SIM card is available..
	RSPRstartupProcessShowUinfoEditor
					Show the user data editor dialog
					after initialization
	RSPRstartupProcessUinfoOK	Save the record, and initiate
					the next dialog.
	RSPRstartupProcessMemoryChangeOk
	RSPRstartupProcessSimMemoryOk
	RSPRstartupProcessExitOK	Change [uifeatures] defaultLauncher
					to phone (or contact mgr for now),
					launch the app, and quit.
	RSCEContactEditInsertEmptyRecordInDB
					Code to insert an empty record in
					database.

ROUTINES:
	Name				Description
	----				-----------
INT	RStartupIniWriteLanguage	Write the language options to INI file
INT	RStartupClearLanguagePatches	Delete all extra language patches.
INT	RStartupDeleteOneLanguage	Delete one language from PRIVDATA.
INT	RStartupLanguageReboot		Reboot after language selection.
INT	RStartupCheckValidDate		Check if date is valid (cases like
					Apr 31 and Feb 29, 1991)

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		4/14/95   	Initial revision


DESCRIPTION:
	Code for Startup process class
		

	$Id: rstartupProcess.asm,v 1.1 97/04/04 16:52:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RStartupClassStructures	segment resource
	RStartupApplicationClass
	RStartupProcessClass      mask CLASSF_NEVER_SAVED
	RStartupCountryListClass
	RStartupContactEditClass
RStartupClassStructures	ends

if DO_ECI_SIM_CARD_CHECK	;-------------------------------------------
idata segment
	eciSentFlags		RStartupECIFlags
					; some bits will be set when ECI
					; messages are sent to VP already
idata ends
endif				;-------------------------------------------

CommonCode      segment resource

if RSTARTUP_DO_LANGUAGE		; ++++++++++++++++++++++++++++++++++++++++++
languageChosenCategory	char	'system', 0
languageChosenKey	char	'languageChosen', 0
endif				; ++++++++++++ RSTARTUP_DO_LANGUAGE ++++++++


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPGenProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open application. Depending on [system]languageChosen, bring
		up language dialog or country dialog.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
		cx	= AppAttachFlags
		dx	= Handle of AppLaunchBlock, or 0 if none.
		bp	= Handle of extra state block, 0 if none.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPGenProcessOpenApplication	method dynamic RStartupProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
		.enter
		mov	di, offset RStartupProcessClass
		call	ObjCallSuperNoLock

	;
	; if we have the app opened already (lazarus), don't
	; initialize RWT database..
	;
	; Ooooppss.. if RT things are not initialized it will die,
	; even in lazarus. Don't check.
	;
	;	call	RStartupCheckIfAppIsOpen	; carry set if yes
	;EC <		WARNING_C LAZARUS_RWTIME_LIBRARY_NOT_INITIALIZED>
	;	jc	noRWTIni
	;
	; Mark the app is open
	;
	;	call	RStartupMarkAppOpen
	;
if RSTARTUP_DO_LANGUAGE		;++++++++++++++++++++++++++++++++++++++++++
	;
	; check ini file to see if we have language chosen already
	;
		mov	cx, cs
		mov	ds, cx
		mov	si, offset languageChosenCategory
		mov	dx, offset languageChosenKey
		call	InitFileReadBoolean		; found: carry clear,
							; ax - TRUE/FALSE
							; not found: carry set
		mov_tr	cx, ax
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_LANGUAGE
		jc	showLanguage
		jcxz	showLanguage

endif				; ++++++++++++ RSTARTUP_DO_LANGUAGE ++++++++
	;
	; check ini file to see if we have keyboard type chosen already
	;
;noRWTIni:
		mov	cx, cs
		mov	ds, cx
		mov	si, offset keyboardCategory
		mov	dx, offset kbdTypeChosenKey
		call	InitFileReadBoolean		; found: carry clear,
							; ax - TRUE/FALSE
							; not found: carry set
	;
	; if not found or equal to false, we can assume that startup has
	; never been executed or keyboard type is not scandinavian, and we
	; show home country.
	;
		mov_tr	cx, ax
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_HOME_COUNTRY
		jc	showCountry
		jcxz	showCountry
	;
	; show time
	;
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_DATE
showLanguage::
showCountry::
		call	CallProcess			; ax, cx, dx, bp gone
		.leave
		ret
RSPGenProcessOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupCheckIfAppIsOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the varData ATTR_RSTARTUP_APP_OPEN exists in
		the app object. Mainly to deal with lazarus.

CALLED BY:	INTERNAL (RSPGenProcessOpenApplication)
PASS:		nothing
RETURN:		carry set if vardata found
		carry clear if not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/17/95    	Initial version (copied from
				SolitaireCheckIfGameIsOpen) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
RStartupCheckIfAppIsOpen -NOT USED-	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter

		sub	sp, size GetVarDataParams
		mov	bp, sp
		mov	ss:[bp].GVDP_dataType, ATTR_RSTARTUP_APP_OPEN
		mov	{word} ss:[bp].GVDP_bufferSize, 0
	;	clrdw	ss:[bp].GVDP_buffer
		mov	bx, handle RStartupApp
		mov	si, offset RStartupApp
		mov	ax, MSG_META_GET_VAR_DATA
		mov	dx, size GetVarDataParams
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage			; ax <- -1 if not
							; found,
							; cx, dx, bp destroyed
		add	sp, size GetVarDataParams
		cmp	ax, -1				; check if not found
		stc
		jne	varDataFound

		clc
varDataFound:
		.leave
		ret
RStartupCheckIfAppIsOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupMarkAppOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the varData ATTR_RSTARTUP_APP_OPEN in
		the app object. Mainly to deal with lazarus.

CALLED BY:	INTERNAL (RSPGenProcessOpenApplication)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	10/17/95    	Initial version (copied from
				SolitaireMarkGameOpen) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RStartupMarkAppOpen -NOT USED-	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter

		sub	sp, size AddVarDataParams
		mov	bp, sp
		mov	ss:[bp].AVDP_dataType, ATTR_RSTARTUP_APP_OPEN
		mov	{word} ss:[bp].AVDP_dataSize, size byte
		clrdw	ss:[bp].AVDP_data
		mov	bx, handle RStartupApp
		mov	si, offset RStartupApp
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	dx, size AddVarDataParams
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage
		add	sp, size AddVarDataParams

		.leave
		ret
RStartupMarkAppOpen	endp

endif 	; 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPGenProcessCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the application

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
RSPGenProcessCloseApplication -NOT-USED- method dynamic RStartupProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION
		uses	cx
		.enter
	;
	; Close the World time database
	;
		mov	cx, mask RPIF_COUNTRY or mask RPIF_CITY
		call	RWTDatabaseClose
EC <		ERROR_C	DATABASE_CLOSE_PROBLEM				>

		.leave

		mov	di, offset RStartupProcessClass
		GOTO	ObjCallSuperNoLock

RSPGenProcessCloseApplication	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPGenProcessCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure no state file is generated.

CALLED BY:	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
PASS:		ds	= dgroup
		ax	= message #
		
RETURN:		ax	= 0
DESTROYED:	nothing
SIDE EFFECTS:	
		No state file will be created.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/ 1/95   	Initial version (copied from
				Appl/Startup/JStartup/jsProcess.asm)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPGenProcessCreateNewStateFile	method dynamic RStartupProcessClass, 
					MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		clr	ax
		ret
RSPGenProcessCreateNewStateFile	endm



if RSTARTUP_DO_LANGUAGE		;++++++++++++++++++++++++++++++++++++++++++

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessShowLanguage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the language dialog.

CALLED BY:	MSG_RSTARTUP_PROCESS_SHOW_LANGUAGE
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessShowLanguage	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_SHOW_LANGUAGE
	;
	; Build the language list
	;
		mov	bx, handle LanguageList
		mov	si, offset LanguageList
		mov	ax, MSG_RSLANG_DYNAMIC_LIST_BUILD_ARRAY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax, cx, dx, bp gone
	;
	; Initialize the dialog
	;
		mov	bx, handle LanguageDialog
		mov	si, offset LanguageDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone

		ret
RSPRstartupProcessShowLanguage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessLanguageOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS	User presses OK on Language dialog box. Should get
		confirmation with a dialog.

CALLED BY:	MSG_RSTARTUP_PROCESS_LANGUAGE_OK
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Grab the selection from LanguageList
		Get the language name from LanguageList
		Display warning and get confirmation
		If "OK" {
			save language option to ini file
			Write [system]languageChosen: TRUE
			/* so that next time rstartup will not show language
			dialog box */
			confirm restart
			restart
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessLanguageOK	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_LANGUAGE_OK
language	local	MAX_STRING_SIZE	dup (TCHAR)
languageNum	local	word
		
		.enter
	;
	; Get the selection from LanguageList
	;
		push	bp, bp, bp
		mov	bx, handle LanguageList
		mov	si, offset LanguageList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax - selection,
							; GIGS_NONE and clear
							; set if none. 
							; cx, dx, bp gone
EC <		Assert	ne, ax, GIGS_NONE				>
		pop	bp
		mov	ss:[languageNum], ax
	;
	; Find the language name from LanguageList instance variable
	; (nameArray)
	;
		mov	cx, ss				; cx:dx - string buffer
		lea	dx, ss:[language]
		mov_tr	bp, ax
		mov	ax, MSG_RSLANG_GET_LANGUAGE_NAME
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; string filled, ax,
							; cx destroyed. 
		pop	bp
	;
	; Display warning and get confirmation
	;
		sub	sp, size FoamStandardDialogOptrParams
		mov	di, sp
		mov	cx, handle DialogWarningBitmap
		mov	dx, offset DialogWarningBitmap
		movdw	ss:[di].FSDOP_titleIconBitmap, cxdx
		mov	cx, handle LanguageWarningTitle
		mov	dx, offset LanguageWarningTitle
		movdw	ss:[di].FSDOP_titleText, cxdx
		mov	cx, handle LanguageWarningText
		mov	dx, offset LanguageWarningText
		movdw	ss:[di].FSDOP_bodyText, cxdx
		mov	ss:[di].FSDOP_customFlags, \
		CustomDialogBoxFlags <1, CDT_QUESTION, GIT_PROPERTIES, 0>
		mov	ss:[di].FSDOP_stringArg1.segment, ss
		lea	cx, ss:[language]
		mov	ss:[di].FSDOP_stringArg1.offset, cx
		mov	ss:[di].FSDOP_stringArg2.segment, ss
		mov	ss:[di].FSDOP_stringArg2.offset, cx
		clr	ax
		mov	ss:[di].FSDOP_triggerTopText.handle, ax
		mov	ss:[di].FSDOP_triggerBottomText.handle, ax
		mov	ss:[di].FSDOP_acceptTriggerDestination.handle, ax
		mov	ss:[di].FSDOP_acceptTriggerMessage, ax
		mov	ss:[di].FSDOP_rejectTriggerDestination.handle, ax
		mov	ss:[di].FSDOP_rejectTriggerMessage, ax
		mov	ss:[di].FSDOP_layerPriority, al
		mov	ss:[di].FSDOP_helpContext.segment, ax
		mov	ss:[di].FSDOP_helpFile.segment, 0
		mov	bp, sp				; bp is destroyed!
		call	FoamStandardDialogOptr		; ax <- response:
							; IC_APPLY / IC_DISMISS
		pop	bp
		cmp	ax, IC_APPLY
		jne	quit
	;
	; write the option to init file
	;
		call	RStartupIniWriteLanguage	; ax, bx, cx, dx, ds,
							; si, di gone.
	;
	; clear extra language patch files
	;
		mov	ax, ss:[languageNum]
		call	RStartupClearLanguagePatches
	;
	; display reboot warning
	;
		mov	cx, handle LanguageRebootWarning
		mov	dx, offset LanguageRebootWarning
		call	FoamDisplayNote
	;
	; reboot
	;
		push	bp
		call	RStartupLanguageReboot		; ax, bx, cx, dx, ds,
							; si, bp destroyed
		pop	bp
quit:
		.leave
		ret
RSPRstartupProcessLanguageOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupIniWriteLanguage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write language option to init file.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, ds, si, di (but NOT bp!)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RStartupIniWriteLanguage	proc	near
		uses	bp
		.enter
	;
	; Save the language option to ini file
	;
		mov	ax, MSG_META_SAVE_OPTIONS
		mov	bx, handle LanguageList
		mov	si, offset LanguageList
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
	;
	; Write [system]languageChosen = TRUE
	;
		mov	cx, cs
		mov	ds, cx
		mov	si, offset languageChosenCategory
		mov	dx, offset languageChosenKey
		mov	ax, TRUE
		call	InitFileWriteBoolean

		.leave
		ret
RStartupIniWriteLanguage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupClearLanguagePatches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all language patches except those of chosen language.

CALLED BY:	INTERNAL
PASS:		ax	= chosen language number (0 based)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The location of patches:
		PRIVDATA/LANGUAGE/<language name>/*
		e.g. PRIVDATA/LANGUAGE/Deutsch/*

		Pseudo code:

		(ax = chosen language)
		cd PRIVDATA/LANGUAGE
		cx = LanguageList.MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
		for (i = 0; i < cx; i++) {
			if (i == chosen language) brk
			cd languageName[i]
			rm -rf *
			cd ..
			rmdir languageName[i]
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
languageDirName	char	"LANGUAGE", 0

RStartupClearLanguagePatches	proc	near
		uses	ax, bx, ds, si, di, bp
		.enter
		mov	cx, ax				; cx <- selection
	;
	; cd PRIVDATA/LANGUAGE
	;
		mov	bx, SP_PRIVATE_DATA
		segmov	ds, cs
		mov	dx, offset languageDirName
		call	FileSetCurrentPath		; carry set if error.
		jc	quit
	;
	; Get number of languages in the list
	;
		push	cx				; preserve lang #
		mov	bx, handle LanguageList
		mov	si, offset LanguageList
		mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
		mov	di, mask MF_CALL 
		call	ObjMessage			; cx <- #items
							; ax, dx, bp destroyed
EC <		Assert	g, cx, 0					>

		pop	dx				; language #.
deleteOne:
		mov	ax, cx
		dec	ax
		cmp	ax, dx
		je	endLoop
		call	RStartupDeleteOneLanguage	; all destroyed
							; except cx, dx
endLoop:
		loop	deleteOne
quit:
		.leave
		ret
RStartupClearLanguagePatches	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupDeleteOneLanguage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete (ax)th language from system. 

CALLED BY:	INTERNAL
PASS:		ax	= Language number (0 based)
		Thread current path = PRIVDATA/LANGUAGE
RETURN:		nothing
DESTROYED:	everything except cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		cd languageName[i]
		rm -rf *
		cd ..
		rmdir languageName[i]		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RStartupDeleteOneLanguage	proc	near
language	local	MAX_STRING_SIZE	dup (TCHAR)
		uses	cx, dx
		.enter
	;
	; retain current directory
	;
		call	FilePushDir
	;
	; Get language name
	;
		push	bp
		mov	bx, handle LanguageList
		mov	si, offset LanguageList
		mov	cx, ss				; cx:dx - string buffer
		lea	dx, ss:[language]
		mov_tr	bp, ax
		mov	ax, MSG_RSLANG_GET_LANGUAGE_NAME
		mov	di, mask MF_CALL
		call	ObjMessage			; string filled, ax,
							; cx destroyed
		pop	bp
	;
	; cd 'languageName'
	;
		segmov	ds, ss, bx			; ds:dx - path
		lea	dx, ss:[language]
		clr	bx				; path relative to
							; current path
		call	FileSetCurrentPath		; carry set if error
		jc	error
	;
	; rm -rf *
	;
		call	RecursiveDeleteNear		; nothing destroyed
	;
	; cd ..
	;
		call	FilePopDir
	;
	; rmdir 'languageName'
	;
		call	FileDeleteDir			; carry set if error
quit:
		.leave
		ret
error:
		call	FilePopDir
		jmp	quit
RStartupDeleteOneLanguage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupLanguageReboot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reboot after the language selection.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		does not return
DESTROYED:	ax, bx, cx, dx, ds, si, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We need to make sure that state files and Table of
		Content file will be deleted next time we restart.
		That is done by two ini file flags.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/17/95    	Initial version (mostly from
				Library/Pref/Preflang/preflang.asm) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
deleteStateFilesCategory	char	'ui',0
deleteStateFilesKey		char	'forceDeleteStateFilesOnceOnly',0
deleteTocFileCategory		char	'pref',0
deleteTocFileKey		char	'forceDeleteTocOnceOnly',0

RStartupLanguageReboot	proc	near
		.enter
	;
	; Make sure the state files will be deleted.
	;
		mov	cx, cs
		mov	ds, cx
		mov	si, offset deleteStateFilesCategory
		mov	dx, offset deleteStateFilesKey
		mov	ax, TRUE
		call	InitFileWriteBoolean
	;
	; Make sure Table Of Content (TOC) file will be deleted.
	;
		mov	si, offset deleteTocFileCategory
		mov	dx, offset deleteTocFileKey
		mov	ax, TRUE
		call	InitFileWriteBoolean
	;
	; Restart system
	;
		mov	ax, SST_RESTART
		call	SysShutdown			; does not return
		.leave
		ret
RStartupLanguageReboot	endp

endif				; ++++++++++++ RSTARTUP_DO_LANGUAGE ++++++++


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessShowHomeCountry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the home country dialog.

CALLED BY:	MSG_RSTARTUP_PROCESS_SHOW_HOME_COUNTRY
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessShowHomeCountry	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_SHOW_HOME_COUNTRY
	;
	; Initialize the RWT database
	;
		mov	cx, mask RPIF_COUNTRY or mask RPIF_CITY
		call	RWTDatabaseInit
		jnc	normal
	;
	; Let's not do restore, but rather just copy backup file to
	; save time.
	;
	;	call	RStartupRestoreFiles
	;	jnc	normal
		call	RWTDatabaseCopyBackupFiles	; cx <- RWTimeInitFlags
		call	RWTDatabaseInit
EC <		ERROR_C	-1				; why?		>

normal:
		call	RWTDatabaseSetAllViewpt
EC <		ERROR_C	DATABASE_SET_ALL_VIEWPT_PROBLEM			>
		call	RWTDatabaseCountrySetAllViewpt
	;
	; Find how many countries there are in database
	;
		call	RWTDatabaseCountryGetViewptRecordCount
							; cx <- count
EC <		ERROR_C	COUNTRY_GET_VIEWPT_RECORD_COUNT_PROBLEM		>
	;
	; Initialize the list
	;
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	bx, handle HomeCountryDynamicList
		mov	si, offset HomeCountryDynamicList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax, cx, dx, bp gone
	;
	; Go back to top of list
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	cx, dx
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax, cx, dx, bp gone
	;
	; Initialize the dialog
	;
		mov	bx, handle HomeCountryDialog
		mov	si, offset HomeCountryDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone

		ret
RSPRstartupProcessShowHomeCountry	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSCLRstartCountryListQueryMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query message to add the moniker of specified item to
		dynamic list.

CALLED BY:	MSG_RSTART_COUNTRY_QUERY_ITEM_MONIKER
PASS:		*ds:si	= RStartupCountryListClass object
		ds:di	= RStartupCountryListClass instance data
		es 	= segment of RStartupCountryListClass
		ax	= message #
		^lcx:dx = the dynamic list requesting the moniker (object)
		bp	= item #

RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSCLRstartCountryListQueryMoniker method dynamic RStartupCountryListClass, 
					MSG_RSTART_COUNTRY_QUERY_ITEM_MONIKER
rwRecord	local	RWTDatabaseCountryRecord
numItem		local	word

		mov	cx, bp

		.enter
		mov	ss:[numItem], cx
		call	RWTDatabaseCountryGetAbsoluteRecordNumber
							; cx <- record #
EC <		ERROR_C	DATABASE_GET_ABSOLUTE_RECORD_NUMBER_PROBLEM	>
		segmov	es, ss
		lea	di, ss:[rwRecord]
		call	RWTDatabaseCountryReadRecord
EC <		ERROR_C	DATABASE_COUNTRY_READ_RECORD_PROBLEM		>
	;
	; Put the right text on the dynamic list.
	;
		push	bp
		lea	dx, ss:[rwRecord].RWTDCR_country
		mov	bp, ss:[numItem]
		mov	cx, ss				; cx:dx - string
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjCallInstanceNoLock
		pop	bp
		.leave
		ret
RSCLRstartCountryListQueryMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSCLMetaFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable the user to search with the keypress of the first
		letter of the selection.

CALLED BY:	MSG_META_FUP_KBD_CHAR
PASS:		*ds:si	= RStartupCountryListClass object
		ds:di	= RStartupCountryListClass instance data
		es 	= segment of RStartupCountryListClass
		cx 	= charValue
		dl 	= CharFlags
				CF_RELEASE - set if release
				CF_STATE - set if shift, ctrl, etc.
				CF_TEMP_ACCENT - set if accented char pending
		dh 	= ShiftState (SS_RALT + SS_RCTRL pressed)
		bp low	= ToggleState
		bp high = scan code
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	if  'A' <= cx <= 'Z', superclass will not be called.

PSEUDO CODE/STRATEGY:
		Make sure the key that was pressed was a letter by
		compare the ascii value of the character that is
		passed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	7/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSCLMetaFupKbdChar	method dynamic RStartupCountryListClass, 
					MSG_META_FUP_KBD_CHAR
passedBP	local	word push bp	
searchString	local	2 dup (TCHAR)

		.enter
	;
	; See if ESCAPE is pressed.
	;
SBCS <		cmp	cl, C_ESCAPE					>
DBCS <		cmp	cx, C_ESCAPE					>
		jne	notEscape
	;
	; Notify app obj that we should accept hard icon now,
	; otherwise phone app will not be launched.
	;
		mov	ax, MSG_RSTARTUP_APP_SET_APP_FLAGS
		mov	cl, mask RSAF_ACCEPT_HARD_ICON
		call	UserCallApplication
	;
	; Quit
	;
		push	bp
		mov	ax, MSG_META_QUIT
		call	UserCallApplication
		pop	bp
	;
	; Launch Contact Manager
	;
		mov	cx, FA_PHONE_APP
		call	FoamLaunchApplication
		jmp	quit
notEscape:
	;
	; Convert to Upper Case if required.
	;
SBCS <		cmp	cx, C_SMALL_A					>
DBCS <		cmp	cx, C_LATIN_SMALL_LETTER_A			>
		jl	upperCase
SBCS <		cmp	cx, C_SMALL_Z					>
DBCS <		cmp	cx, C_LATIN_SMALL_LETTER_Z			>
		LONG jg	callSuper				; not A-Z/a-z
	;
	; change to uppercase
	;
SBCS <		sub	cx, C_SMALL_A - C_CAP_A				>
DBCS <		sub	cx, C_LATIN_SMALL_LETTER_A - C_LATIN_CAPITAL_LETTER_A>

upperCase:
	;
	; Make sure it is a valid character
	;
SBCS <		cmp	cx, C_CAP_A					>
DBCS <		cmp	cx, C_LATIN_CAPITAL_LETTER_A			>
		LONG jl	callSuper
SBCS <		cmp	cx, C_CAP_Z					>
DBCS <		cmp	cx, C_LATIN_CAPITAL_LETTER_Z			>
		LONG jg	callSuper
	;
	; Make sure it is the first press
	;
		test	dl, mask CF_FIRST_PRESS
		LONG jz	quit
	;
	; Do the search!
	;
		segmov	es, ss
		lea	di, ss:[searchString]
		LocalPutChar	esdi, cx
		mov	ax, C_NULL
		LocalPutChar	esdi, ax
		lea	di, ss:[searchString]
		call	RWTDatabaseCountryFindRecord	; cx has selection #
		cmp	cx, RWTIME_RECORD_NOT_FOUND
		je	quit
	;
	; Set the selection.
	;
		push	bp
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock		; ax, cx, dx, bp gone
		mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
		call	ObjCallInstanceNoLock		; ax, cx, dx, bp gone
		pop	bp
quit:
		.leave
		ret
callSuper:
	;
	; Call superclass
	;
		push	bp
		mov	bp, ss:[passedBP]
	;
	; why?
	;	GetResourceSegmentNS	RStartupClassStructures, es
		mov	di, offset RStartupCountryListClass
		call	ObjCallSuperNoLock
		pop	bp
		jmp	quit
RSCLMetaFupKbdChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupRecoverFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy over the backup files if the db files are corrupted

CALLED BY:	FCPOpenApplication
PASS:		cx	= RWTimeInitFlags
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:	Copy the backup files over based on the passed in 
	flags, and then open the files that were copied.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AW	6/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0		; ------------ functions provided by rwtime ---- not used
CityBackup	char	"clock\\rwtime.bak",0
CityDB		char	"clock\\rwtime.wdb",0
CountryBackup	char	"clock\\rwcount.bak",0
CountryDB	char	"clock\\rwcount.wdb",0

RStartupRecoverFiles	---NOT_USED--- proc	near
	passFlags	local	word
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Database corrupted, copy backup files over over
	;
		clr	passFlags
		mov	bx, cx
		push	ds, si
		mov	cx, handle AlarmDBCorruptedText
		mov	dx, offset AlarmDBCorruptedText
		call	FoamDisplayWarning
	; set the path
		mov	ax, SP_USER_DATA
		call	IsMultiLanguageModeOn
		jc	notOn
		call	GeodeSetLanguageStandardPath
		jmp	continue
notOn:
		call	FileSetStandardPath
continue:
		segmov	ds, cs
		segmov	es, cs
		test	bx, mask RIF_CITY_CORRUPTED
		jz	cityNormal
	;
	; Remove existing city database if it is there
	;
		call	FileDelete
		mov	dx, offset CityDB
	;
	; Check to see if there is enough room to copy the city database
	;
		call	FoamGetFreeDiskSpace
		cmp	ax, RSTARTUP_CITY_SPACE_SIZE
		jg	copyCity
		call	RStartupRecoverError
		stc
		jmp	exit
	;
	; Copy the city database
	;
copyCity:
		mov	si, offset CityBackup
		clr	cx, dx
		mov	di, offset CityDB		
		call	FileCopy
		or	passFlags, mask RPIF_CITY
cityNormal:
		test	bx, mask RIF_COUNTRY_CORRUPTED
		jz	done
	;
	; Remove existing country database if it is there
	;
		call	FileDelete
		mov	dx, offset CountryDB
	;
	; Check to see if there is enough room to copy the country database
	;
		call	FoamGetFreeDiskSpace
		cmp	ax, RSTARTUP_COUNTRY_SPACE_SIZE
		jg	copyCountry
		call	RStartupRecoverError
		stc
		jmp	exit
	;
	; Copy the country database
	;
copyCountry:
		clr	cx, dx
		mov	si, offset CountryBackup
		mov	di, offset CountryDB
		call	FileCopy
		or	passFlags, mask RPIF_COUNTRY
done:
		pop	ds, si
		clc
		mov	cx, passFlags
		call	RWTDatabaseInit
exit:
	.leave
	ret
RStartupRecoverFiles	endp

RStartupRecoverError	--not-used -- proc	near
		mov	cx, handle NotEnoughSpaceForBackup
		mov	dx, offset NotEnoughSpaceForBackup
		call	FoamDisplayError
	ret
RStartupRecoverError	endp

endif		; 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupRestoreFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the In Use condition of the database files

CALLED BY:	RSPGenProcessOpenApplication
PASS:		cx	= RWTimeInitFlags
RETURN:		carry set if error, and also cx (RWTimeInitFlags) if error.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:	Put up a note that says the db is rebuilding, and then
	rebuild the correct db files based on the flags passed in.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AW	6/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
RStartupRestoreFiles	proc	near
	passedFlags	local	word	push cx
	uses	ax,bx,dx,si,di,bp
	.enter
	;
	; Get the UI thread handle
	;
		mov	ax, SGIT_UI_PROCESS
		call	SysGetInfo			; ax = ui thread handle
							; dx destroyed
		mov_tr	bx, ax
	;
	; Show the flashing note
	;
		mov	cx, handle RStartupRebuildDatabase
		mov	dx, offset RStartupRebuildDatabase
		call	PutUpDialogViaUIThread		; di, ax destroyed
		push	cx
		mov	cx, passedFlags
		call	RWTDatabaseRestore		; cx <- return val
		mov	ax, cx
		pop	cx
		pushf
		push	ax
		call	TakeDownDialogViaUIThread	; di, ax destroyed
		pop	cx
		popf
	.leave
	ret
RStartupRestoreFiles	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessCountryOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User presses OK on Home Country dialog box. Get the country
		selection, find the capital and set it to be the home city.

CALLED BY:	MSG_RSTARTUP_PROCESS_COUNTRY_OK
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessCountryOK	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_COUNTRY_OK
rwRecord	local	RWTDatabaseCountryRecord
		.enter
		
	;
	; Grab the selection from country list
	;
		push	bp
		mov	bx, handle HomeCountryDynamicList
		mov	si, offset HomeCountryDynamicList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax - selection,
							; GIGS_NONE and clear
							; set if none. 
							; cx, dx, bp gone
EC <		Assert	ne, ax, GIGS_NONE				>
		pop	bp
	;
	; Find the record, hence get the string of capital city
	;
		mov_tr	cx, ax
		call	RWTDatabaseCountryGetAbsoluteRecordNumber
							; cx <- record #
EC <		ERROR_C	DATABASE_GET_ABSOLUTE_RECORD_NUMBER_PROBLEM	>
		segmov	es, ss
		lea	di, ss:[rwRecord]
		call	RWTDatabaseCountryReadRecord
EC <		ERROR_C	DATABASE_COUNTRY_READ_RECORD_PROBLEM		>
	;
	; Find the city from the string
	;
		segmov	es, ss
		lea	di, ss:[rwRecord].RWTDCR_capital
		call	RWTDatabaseFindRecord		; cx <- entry number
							; carry set if error
EC <		ERROR_C	DATABASE_CAPITAL_CITY_SEARCH_ERROR		>
	;
	; Set it as home city
	;	
		call	RWTDatabaseGetAbsoluteRecordNumber
							; cx <- absolute #
EC <		ERROR_C	DATABASE_GET_ABSOLUTE_RECORD_NUMBER_PROBLEM	>
		call	RWTDatabaseSetHomeCity		; carry set if error
EC <		ERROR_C	DATABASE_SET_HOME_CITY_ERROR			>
	;
	; Close the World time database
	;
		mov	cx, mask RPIF_COUNTRY or mask RPIF_CITY
		call	RWTDatabaseClose
EC <		ERROR_C	DATABASE_CLOSE_PROBLEM				>
	;
	; Prepare to initiate keyboard dialog
	;
		push	bp
	;	mov	ax, MSG_RSTARTUP_PROCESS_SHOW_DATE
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_KEYBOARD
		call	CallProcess			; ax, cx, dx, bp gone
		pop	bp
		
		.leave
		ret
RSPRstartupProcessCountryOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessShowKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the Keyboard type dialog box if the keyboard type
		is scandinavian.

CALLED BY:	MSG_RSTARTUP_PROCESS_SHOW_KEYBOARD
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Read from ini file: [keyboard]scandinavian to see if
		we have scandinavian keyboard.
		If so, see if [keyboard]keyboardTypeChosen is TRUE or
		FALSE.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

keyboardCategory	char	'keyboard', 0
scandinavianKey		char	'scandinavian', 0
kbdTypeChosenKey	char	'kbdTypeChosen', 0

RSPRstartupProcessShowKeyboard	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_SHOW_KEYBOARD
		.enter
	;
	; check ini file to see if we have scandinavian keyboard
	;
		clr	ax				; default: not
							; scandinavian kbd
		mov	cx, cs
		mov	ds, cx
		mov	si, offset keyboardCategory
		mov	dx, offset scandinavianKey
		call	InitFileReadBoolean		; found: carry clear,
							; ax - TRUE/FALSE
							; not found: carry set
		tst	ax
		jz	doTime
	;
	; check ini file to see if we have keyboard type chosen already
	;
		clr	ax				; default: not found
		mov	dx, offset kbdTypeChosenKey
		call	InitFileReadBoolean		; found: carry clear,
							; ax - TRUE/FALSE
							; not found: carry set
		tst	ax
		jnz	doTime
	;
	; Initialize the dialog
	;
		mov	bx, handle KeyboardDialog
		mov	si, offset KeyboardDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
quit:
		.leave
		ret
doTime:
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_DATE
		call	CallProcess			; ax, cx, dx, bp gone
		jmp	quit
		
RSPRstartupProcessShowKeyboard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessKeyboardOk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User presses OK on Keyboard dialog box.

CALLED BY:	MSG_RSTARTUP_PROCESS_KEYBOARD_OK
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Display warning with the keyboard name.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessKeyboardOk	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_KEYBOARD_OK
		.enter
	;
	; Get the selection from KeyboardChoices
	;
		mov	bx, handle KeyboardChoices
		mov	si, offset KeyboardChoices
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax - selection,
							; GIGS_NONE and clear
							; set if none. 
							; cx, dx, bp gone
EC <		Assert	ne, ax, GIGS_NONE				>
EC <		Assert	etype, ax, RespKeyboardType			>
		mov_tr	si, ax				; si <- selection
	;
	; Find the keyboard name
	;
		mov	bx, handle StringsResource
		call	MemLock				; ax <- segment
		mov_tr	es, ax				; es:?? - string
	;
	; Get the string we want
	;
		mov	di, cs:[keyboardNameStringTable][si]
		mov	ax, es:[di]			; es:ax - fptr.string
	;
	; Display warning and get confirmation
	;
		sub	sp, size FoamStandardDialogOptrParams
		mov	di, sp
		mov	cx, handle KeyboardWarningText
		mov	dx, offset KeyboardWarningText
		movdw	ss:[di].FSDOP_bodyText, cxdx
		mov	ss:[di].FSDOP_customFlags, \
		CustomDialogBoxFlags <1, CDT_QUESTION, GIT_PROPERTIES, 0>
		movdw	ss:[di].FSDOP_stringArg1, esax
		clr	ax
		movdw	ss:[di].FSDOP_titleText, axax
		movdw	ss:[di].FSDOP_titleIconBitmap, axax
		mov	ss:[di].FSDOP_stringArg2.segment, ax
		mov	ss:[di].FSDOP_triggerTopText.handle, ax
		mov	ss:[di].FSDOP_acceptTriggerDestination.handle, ax
		mov	ss:[di].FSDOP_acceptTriggerMessage, ax
		mov	ss:[di].FSDOP_rejectTriggerDestination.handle, ax
		mov	ss:[di].FSDOP_rejectTriggerMessage, ax
		mov	ss:[di].FSDOP_layerPriority, \
					RSTARTUP_POPUP_LAYER_PRIORITY
		mov	ss:[di].FSDOP_helpContext.segment, ax
		mov	ss:[di].FSDOP_helpFile.segment, ax
		mov	bp, sp				; bp is destroyed!
		call	FoamStandardDialogOptr		; ax <- response:
							; IC_APPLY / IC_DISMISS
	;
	; Unlock block
	;
		call	MemUnlock
	;
	; If OK, change keyboard file, otherwise quit
	;
		cmp	ax, IC_APPLY
		jne	quit
	;
	; Rename keymap.fin OR keymap.den to keymap.dat
	;
EC <		Assert	etype, si, RespKeyboardType			>
		call	KeyboardFileRename		; everything except
							; ds destroyed
	;
	; Record that the keyboard type is changed, so we will reboot later. 
	;
	; no need.. we reboot right away
	;
	;	mov	ax, MSG_RSTARTUP_APP_SET_APP_FLAGS
	;	mov	cl, mask RSAF_KBD_TYPE_CHANGED
	;	call	UserCallApplication
	;
	;
	; display reboot note
	;
		mov	cx, handle KeyboardRebootWarning
		mov	dx, offset KeyboardRebootWarning
		mov	ax, FoamCustomDialogBoxFlags <1, CDT_NOTIFICATION, \
					  GIT_NOTIFICATION, 0>
		call	RStartupDisplayWithHighPriority
	;
	; Reboot
	;
		mov	ax, SST_RESTART			; SST_REBOOT
		call	SysShutdown			; does not return
quit:
		.leave
		ret
RSPRstartupProcessKeyboardOk	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardFileRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename keymap.fin or keymap.den to keymap.dat in
		PRIVDATA\KBD.

CALLED BY:	INT (RSPRstartupProcessKeyboardOK)
PASS:		si	= RespKeyboardType
RETURN:		nothing
DESTROYED:	everything except ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Rename selected file to keymap.dat in PRIVDATA\KBD.
		Write [keyboard]kbdTypeChosen = TRUE so that even if
		user reboots in startup, and startup loads again,
		keyboard type dialog won't show up.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
keyboardDirName	char	"KBD", 0
newFileName	char	"kbd\\keymap.dat", 0
finlandKbdFile	char	"kbd\\keymap.fs", 0
denmarkKbdFile	char	"kbd\\keymap.dn", 0

keyboardFileNameTable word \
	offset	finlandKbdFile,
	offset	denmarkKbdFile

EC< PRIVDATA_KBD_NOT_FOUND_KBD_TYPE_NOT_CHANGED	enum	Warnings>
EC< FILE_ERROR_KBD_TYPE_NOT_CHANGED 		enum	Warnings>
KeyboardFileRename	proc	near
		uses	ds
		.enter
EC <		Assert	etype, si, RespKeyboardType			>
	;
	; cd SP_PRIVATE_DATA
	;
		call	FilePushDir
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
	;
	; mkdir [privdata]/KBD
	;
		segmov	ds, cs, cx
		mov	dx, offset keyboardDirName
		call	FileCreateDir		; carry set if error.
						; ax destroyed
	;
	; Let's copy file instead of renaming file.
	; Find the current file name
	;
		mov	si, cs:[keyboardFileNameTable][si]
	;
	; Get the new file name
	;
		mov	es, cx				; es := cs
		mov	di, offset newFileName
	;
	; No disk handle provided
	;
		clr	cx, dx
	;
	; copy
	;
		call	FileCopyLocal			; carry set if error,
							; ax - error code
EC <		WARNING_C	FILE_ERROR_KBD_TYPE_NOT_CHANGED		>

		call	FilePopDir
	;
	; write [keyboard]kbdTypeChosen true
	;
		mov	cx, ds
		mov	si, offset keyboardCategory
		mov	dx, offset kbdTypeChosenKey
		mov	ax, TRUE
		call	InitFileWriteBoolean
		call	InitFileCommit
		
		.leave
		ret
KeyboardFileRename	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessShowDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the date format, and show date dialog.

CALLED BY:	MSG_RSTARTUP_PROCESS_SHOW_DATE
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The current date format will be used to parse the text, so we
		need to set it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessShowDate	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_SHOW_DATE
		.enter
	;
	; Set the date format
	;
	; Get the format string and call LocalSetDateTimeFormat
	; to set date format. The strings are in the StringsResource. Have to
	; lock the block and get the segment.
	;
		mov	bx, handle StringsResource
		call	MemLock				; ax <- segment
		mov_tr	es, ax				; es:di - string
		mov	di, offset DefaultDateFormatString
		mov	di, es:[di]
		mov	si, DTF_ZERO_PADDED_SHORT	; set DATE
		call	LocalSetDateTimeFormat	
		call	MemUnlock
	;
	; Write to ini file. Why not?
	;
	; actually, why?
	;
	;	call	InitFileCommit
	;
	; Set max length on date string -- done in UI file
	;
	;	mov	bx, handle DateText
	;	mov	si, offset DateText
	;	mov	cx, DATE_TEXT_MAX_LENGTH	; = 8
	;	mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
	;	mov	di, mask MF_CALL
	;	call	ObjMessage			; ax, cx, dx, bp gone

	;
	; Load the sample string
	;
		mov	cx, handle DateText
		mov	dx, offset DateText
		mov	si, DTF_ZERO_PADDED_SHORT
		call	RStartupReplaceDateTimeString
	;
	; Initialize the dialog
	;
		mov	bx, handle DateDialog
		mov	si, offset DateDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone

		.leave
		ret
RSPRstartupProcessShowDate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupReplaceDateTimeString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Using current time, format a localized string according to
		caller, and set it on the text object specified.

CALLED BY:	INTERNAL
PASS:		^lcx:dx	= text object
		si	= DateTimeFormat
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	The text object is changed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RStartupReplaceDateTimeString	proc	near
		uses	ax, bx, cx, dx, ds, si, es, di
buffer		local	SMALL_STRING_SIZE	dup (TCHAR)
		.enter
		Assert	optr, cxdx
		Assert	etype, si, DateTimeFormat
	;
	; Preserve optr
	;
		push	cx, dx				; optr
	;
	; Find current date/time
	;
		call	TimerGetDateAndTime		; ax - year
							; bl - month
							; bh - day 
							; cl - weekday
							; ch - hours 
							; dl - minutes
							; dh - seconds
	;
	; Format buffer
	;
		segmov	es, ss, di
		lea	di, ss:[buffer]
		call	LocalFormatDateTime		; buffer filled, 
							; cx <- #char
		Assert	le, cx, SMALL_STRING_SIZE
	;
	; Replace the text of text object
	;
		pop	bx, si				; ^lbx:si - object
		push	bp
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	dx, ss
		mov	bp, di				; dx:bp - text
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp
		
		.leave
		ret
RStartupReplaceDateTimeString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessDateOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User presses OK on Date box. Check if the date string is
		valid, set the date, and initiate the Time dialog.

CALLED BY:	MSG_RSTARTUP_PROCESS_DATE_OK
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessDateOK	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_DATE_OK
buffer		local	SMALL_STRING_SIZE	dup (TCHAR)
		.enter
		push	bp
	;
	; fetch the date text entered by user
	;
		mov	bx, handle DateText
		mov	si, offset DateText
		mov	dx, ss				; dx:bp - string
		lea	bp, ss:[buffer]
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; cx <- string length
							; buffer filled,
							; ax, di destroyed
	;
	; see if it is a valid date
	;
		mov	es, dx				; es:di - string
		mov	di, bp
		mov	si, DTF_ZERO_PADDED_SHORT
		call	LocalParseDateTime		; carry set if valid:
							; ax - year,
							; bl - month,
							; bh - day,
							; cx, dx <- -1
	;
	; if carry not set, give invalid date mesg and leave
	;
		jnc	error
	;
	; the date is not error-free yet: year might be too big/small, day
	; might be too big (e.g. April 31)
	; check
	;
		call	RStartupCheckValidDate		; carry set if valid
		jnc	error
	;
	; so everything is fine. Set the date
	;
		mov	cl, mask SDTP_SET_DATE
		call	TimerSetDateAndTime		; ax, bx, cx, dx gone
	;
	; Initiate Time dialog
	;
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_TIME
		call	CallProcess			; ax, cx, dx, bp gone
		jmp	quit
error:
	;
	; Show error mesg
	;
		mov	cx, handle InvalidDateMsg
		mov	dx, offset InvalidDateMsg
		mov	ax, FoamCustomDialogBoxFlags <1, CDT_ERROR, \
				         GIT_NOTIFICATION, 0>
		call	RStartupDisplayWithHighPriority
	;
	; Reload the sample string
	;
		mov	cx, handle DateText
		mov	dx, offset DateText
		mov	si, DTF_ZERO_PADDED_SHORT
		call	RStartupReplaceDateTimeString
	;
	; Get cursor back to beginning of the field
	;
	;	mov	ax, MSG_VIS_TEXT_SELECT_START
	;	mov	di, mask MF_CALL
	;	call	ObjMessage
quit:
		pop	bp
		.leave
		ret
RSPRstartupProcessDateOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RStartupCheckValidDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see that the passed date is valid.

CALLED BY:	INTERNAL
PASS:		ax	= year
		bl	= month
		bh	= day
RETURN:		carry set if valid
		carry cleared otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We can be sure that: ax is 4-digit number, 1 <= bl <= 12,
		1 <= bh <= 31.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RStartupCheckValidDate	proc	near
		uses	cx
		.enter
EC <		Assert	urange ax, 1, 9999				>
EC <		Assert	urange bl, 1, 12				>
EC <		Assert	urange bh, 1, 31				>
	;
	; check year:    1980 <= ax <= 2099
	;
		cmp	ax, 1980
		jb	error
		cmp	ax, 2099
		ja	error
	;
	; find what is the biggest day we could have in this year, this
	; month...
	;
		call	LocalCalcDaysInMonth		; ch <- days in month
		cmp	bh, ch
		jg	error
	;
	; ok: legal date
	;
		stc
quit:
		.leave
		ret
error:
		clc
		jmp	quit
RStartupCheckValidDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessShowTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the time format, and show time dialog.

CALLED BY:	MSG_RSTARTUP_PROCESS_SHOW_TIME
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The current time format will be used to parse the text, so we
		need to set it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessShowTime	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_SHOW_TIME
	;
	; Set the time format
	;
	; Get the format string and call LocalSetDateTimeFormat
	; to set time format. The strings are in the StringsResource. Have to
	; lock the block and get the segment.
	;
		mov	bx, handle StringsResource
		call	MemLock				; ax <- segment
		mov_tr	es, ax				; es:di - string
		mov	di, offset DefaultTimeFormatString
		mov	di, es:[di]
		mov	si, DTF_HM			; set TIME
		call	LocalSetDateTimeFormat	
		call	MemUnlock
	;
	; Write to ini file. Why not?
	; or why?
	;
	;	call	InitFileCommit
	;
	; Set max length on time string -- done in UI file
	;
	;	mov	bx, handle TimeText
	;	mov	si, offset TimeText
	;	mov	cx, TIME_TEXT_MAX_LENGTH	; = 5
	;	mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
	;	mov	di, mask MF_CALL
	;	call	ObjMessage			; ax, cx, dx, bp gone

	;
	; Load the sample string
	;
		mov	cx, handle TimeText
		mov	dx, offset TimeText
		mov	si, DTF_HM
		call	RStartupReplaceDateTimeString
	;
	; Initialize the dialog
	;
		mov	bx, handle TimeDialog
		mov	si, offset TimeDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone

		ret
RSPRstartupProcessShowTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessTimeOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User presses OK on Time box. Check if the time string is
		valid, set the time, and initiate the User data dialog.

CALLED BY:	MSG_RSTARTUP_PROCESS_TIME_OK
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessTimeOK	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_TIME_OK
buffer		local	SMALL_STRING_SIZE	dup (TCHAR)
		.enter
		push	bp
	;
	; fetch the time text entered by user
	;
		mov	bx, handle TimeText
		mov	si, offset TimeText
		mov	dx, ss				; dx:bp - string
		lea	bp, ss:[buffer]
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; cx <- string length
							; buffer filled,
							; ax, di destroyed
	;
	; see if it is a valid time
	;
		mov	es, dx				; es:di - string
		mov	di, bp
		mov	si, DTF_HM
		call	LocalParseDateTime		; carry set if valid:
							; ch - hours (0-23)
							; dl - minutes (0-59)
							; ax, bx, dh <- -1
	;
	; if carry not set, give invalid time mesg and leave
	;
		jnc	error
	;
	; so everything is fine. Set the time
	;
		clr	dh				; second <- 0
		mov	cl, mask SDTP_SET_TIME
		call	TimerSetDateAndTime		; ax, bx, cx, dx gone
	;
	; Initiate UserDataDialog1
	;
		mov	bx, handle UserDataIntroDialog
		mov	si, offset UserDataIntroDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
		jmp	quit
error:
	;
	; Show error mesg 
	;
		mov	cx, handle InvalidTimeMsg
		mov	dx, offset InvalidTimeMsg
		mov	ax, FoamCustomDialogBoxFlags <1, CDT_ERROR, \
				         GIT_NOTIFICATION, 0>
		call	RStartupDisplayWithHighPriority
	;
	; Reload the sample string
	;
		mov	cx, handle TimeText
		mov	dx, offset TimeText
		mov	si, DTF_HM
		call	RStartupReplaceDateTimeString
	;
	; Get cursor back to beginning of the field
	;
	;	mov	ax, MSG_VIS_TEXT_SELECT_START
	;	mov	di, mask MF_CALL
	;	call	ObjMessage
quit:
		pop	bp
		.leave
		ret
RSPRstartupProcessTimeOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessCheckSimCardInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send ECI message to check if SIM card is available,
		VP mesg handler will add owner info to contdb and
		initialize the dialog. 

CALLED BY:	MSG_RSTARTUP_PROCESS_CHECK_SIM_CARD_INFO
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Test if the ECI message has been sent. If so, quit
		First we register ourselves to be a client in VP library.
		Then we send ECI message.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	6/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DO_ECI_SIM_CARD_CHECK	;-------------------------------------------

RSPRstartupProcessCheckSimCardInfo	method dynamic RStartupProcessClass, 
				MSG_RSTARTUP_PROCESS_CHECK_SIM_CARD_INFO
		.enter

		call	DerefDgroupES			; es <- dgroup
EC <		Assert	dgroup, es					>
	;
	; if the eci has been sent already, let's not send it again
	; if not, mark that it has been sent.
	;
		test	es:[eciSentFlags], mask RSEF_SIM_INFO_STATUS_SENT
EC <		WARNING_NZ ECI_SIM_INFO_STATUS_NOT_SENT_MULTIPLE_TIMES	>
		jnz	quit
		BitSet	es:[eciSentFlags], RSEF_SIM_INFO_STATUS_SENT
	;
	; register ourselves to VP library
	;
		sub	sp, size VpInstallClientParams
		mov	bp, sp
		CheckHack < size TokenChars eq 4 >
		mov	{word} ss:[bp].VICP_geodeToken.GT_chars, 'ST'
		mov	{word} ss:[bp].VICP_geodeToken.GT_chars+2, 'AU'
		mov	{word} ss:[bp].VICP_geodeToken.GT_manufID, \
				MANUFACTURER_ID_GEOWORKS
if	_FXIP
		push	ds, si						
		segmov	ds, cs
		mov	si, offset messageIDTable
		mov	cx, size messageIDTable
		call	SysCopyToStackDSSI
		movdw	ss:[bp].VICP_eciMessageIdArray, dssi
		pop	ds, si

else
		mov	ss:[bp].VICP_eciMessageIdArray.segment, \
				cs
		mov	ss:[bp].VICP_eciMessageIdArray.offset, \
				offset messageIDTable
endif
		mov	ss:[bp].VICP_numberOfEciMessages, 
				(size messageIDTable ) / 2

		call	VpInstallClient		; ax <-	VpInstallClientResult 
						; bx, cx, dx, es destroyed
		add	sp, size VpInstallClientParams
	;
	; if there is any error when trying to register as a client, don't
	; send any ECI message
	;
		cmp	ax, VPIC_OK
EC <		WARNING_NE INSTALL_VP_CLIENT_FAILURE_NO_ECI_SENT	>
		jne	sendNoECI
	;
	; send ECI message
	;
		sub	sp, size VpSendEciMessageParams
		mov	bp, sp
		mov	ss:[bp].VSEMP_eciMessageID, ECI_SIM_INFO_GET
		clrdw	ss:[bp].VSEMP_eciStruct
		call	VpSendEciMessage
EC <		cmp	ax, VPSE_UNKNOWN_ECI_ID				>
EC <		ERROR_NC SEND_ECI_ERROR					>
		add	sp, size VpSendEciMessageParams

quit:
		.leave
		ret
sendNoECI:
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_UINFO_EDITOR
		call	CallProcess
		jmp	quit
RSPRstartupProcessCheckSimCardInfo	endm

messageIDTable	word	\
	ECI_SIM_INFO_STATUS

endif				;-------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessShowUinfoEditor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the user data editor dialog after initialization

CALLED BY:	MSG_RSTARTUP_PROCESS_SHOW_UINFO_EDITOR
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		write [security]showUserDataWhenSIMChange FALSE so that when
		SIM contacts are added to contdb, security library will not
		ask user to review UserData.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SecurityCategory char "security", C_NULL
ShowUserDataKey	char "showUserDataWhenSIMChanges", C_NULL

RSPRstartupProcessShowUinfoEditor	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_SHOW_UINFO_EDITOR
		uses	bp
		.enter
	;
	; Get the Contact DB handle
	;
		call	ContactGetDBHandle		; bx <- db handle
	;
	; Get the secret user data card record ID
	;
		call	ContactGetUserDataID		; dx.ax <- record id
	;
	; With the record ID, get the record from Contact DB
	;
		call	FoamDBGetRecordFromID		; ax <- block handle
							; 0 if deleted
							; inUseCount
							; incremented in FoamDB
	;
	; Release DB handle
	;
		call	ContactReleaseDBHandle
		mov_tr	cx, ax
	;
	; if record is deleted, ax (& cx) is zero which should not
	; happen
	;
EC <		tst	cx						>
EC <		ERROR_Z	USER_INFO_SECRET_RECORD_DELETED			>
		
		mov	ax, MSG_CONTACT_EDIT_DISPLAY_RECORD
		mov	bx, handle UserDataContactEditor
		mov	si, offset UserDataContactEditor
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax, cx, dx, bp
							; destroyed 
	;
	; make the Name field in focus
	;
		mov	ax, MSG_CONTACT_EDIT_FIELD_HAS_FOCUS
		mov	cx, CFT_NAME
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax, cx, dx, bp
							; destroyed
	;
	; Initialize the dialog
	;
		mov	bx, handle UserDataEditDialog
		mov	si, offset UserDataEditDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
	;
	; Check if security has already written out
	; [security]showUserDataWhenSIMChanges 
	;
		segmov	ds, cs, cx
		mov	si, offset SecurityCategory
		mov	dx, offset ShowUserDataKey
		call	InitFileReadBoolean	; carry -> clear if present
		jnc	done			; already there?
						; YES, skip overwriting
	;
	; Write the flag [security]showUserDataWhenSIMChange FALSE
	;
		mov	ax, FALSE
		call	InitFileWriteBoolean
		call	InitFileCommit
done:
		.leave
		ret
RSPRstartupProcessShowUinfoEditor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessUinfoOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User presses OK on User data dialog box. Save the record, and
		initiate the next dialog.

CALLED BY:	MSG_RSTARTUP_PROCESS_UINFO_OK
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessUinfoOK	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_UINFO_OK
	;
	; Save the User data info card
	;
	;	mov	ax, MSG_CONTACT_EDIT_SAVE_RECORD_DATA
	;	mov	bx, handle UserDataContactEditor
	;	mov	si, offset UserDataContactEditor
	;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	;	call	ObjMessage			; ax, cx, dx,
							; bp destroyed
	;
	; check how many contacts there are in SIM card (if present)
	;
if 0
		
		sub	sp, size VpSendEciMessageParams
		mov	bp, sp
		mov	ss:[bp].VSEMP_eciMessageID, \
				ECI_SIM_MEM_LOC_COUNT_STATUS
		clrdw	ss:[bp].VSEMP_eciStruct
		call	VpSendEciMessage
EC <		cmp	ax, VPSE_UNKNOWN_ECI_ID				>
EC <		ERROR_NC SEND_ECI_ERROR					>
		add	sp, size VpSendEciMessageParams
endif
	;
	; Close the uinfo dialog (UserDataEditDialog) (so that
	; indicator can come up -- the dialog is sysModal and full screen.
	;
		mov	bx, handle UserDataEditDialog
		mov	si, offset UserDataEditDialog
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	cx, IC_DISMISS
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
	;
	; show the Exit Dialog
	;
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_EXIT
		call	CallProcess
		
		ret
RSPRstartupProcessUinfoOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessShowExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the Exit dialog box after changing the text, if
		necessary.

CALLED BY:	MSG_RSTARTUP_PROCESS_SHOW_EXIT
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	9/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessShowExit	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_SHOW_EXIT
		.enter
if 0
	;
	; No need.. reboot occurs right after keyboard selection.
	;
	; Check to see if keyboard type is changed. If so, change the dialog
	; text. 
	;
		mov	ax, MSG_RSTARTUP_APP_IS_KBD_TYPE_CHANGED
		call	UserCallApplication		; cx <- TRUE or FALSE
		jcxz	proceed
	;
	; Change the dialog text
	;
		mov	bx, handle ExitText1
		mov	si, offset ExitText1
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		mov	dx, handle StringsResource	; ^ldx:bp <- *string
		mov	bp, offset KbdRebootString
		clr	cx				; null terminated
		mov	di, mask MF_CALL
		call	ObjMessage
endif	
proceed::
		mov	bx, handle ExitDialog
		mov	si, offset ExitDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone

		.leave
		ret
RSPRstartupProcessShowExit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessExitOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User presses OK on "Ready-to-go" dialog box. 
		Change [ui features]defaultLauncher to phone (or contact mgr
		for now), launch the app, and quit.

CALLED BY:	MSG_RSTARTUP_PROCESS_EXIT_OK
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		These things are not stored into CLOSE_APPLICATION in case
		the user turns off the thing before completing everything.

		Change default launcher to "Phone app"
		Tell the app object to accept application keys.
		Launch "Phone app"
		Quit myself

		>>> Before Phone app is ready, we are using Contact
		Manager. <<<

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessExitOK	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_EXIT_OK
		.enter
	;
	; Change default launcher to be Phone app.
	;
		push	ds
		mov	cx, cs
		mov	ds, cx
		mov	es, cx
		mov	si, offset uiFeaturesString
		mov	dx, offset defaultLauncherString
		mov	di, offset phoneAppString
		call	InitFileWriteString
		call	InitFileCommit
		pop	ds
	;
	; Check to see if keyboard type is changed. If so, reboot
	;
	;	mov	ax, MSG_RSTARTUP_APP_IS_KBD_TYPE_CHANGED
	;	call	UserCallApplication		; cx <- TRUE or FALSE
	;	jcxz	launchApp
	;
	; Reboot!
	; -- Reboot is now down right after keyboard type is chosen.
	;
	;	mov	ax, SST_RESTART
	;	call	SysShutdown			; does not return

	;
	; Notify app obj that we should accept application keys now
	;
		mov	ax, MSG_RSTARTUP_APP_SET_APP_FLAGS
		mov	cl, mask RSAF_ACCEPT_HARD_ICON
		call	UserCallApplication
	;
	; Quit
	;
		mov	ax, MSG_META_QUIT
		call	UserCallApplication
	;
	; Launch Contact Manager
	;
		mov	cx, FA_PHONE_APP
		call	FoamLaunchApplication

		.leave
		ret
		
uiFeaturesString 	char "uiFeatures", C_NULL
defaultLauncherString	char "defaultLauncher", C_NULL
EC <	phoneAppString	char "EC Phone", C_NULL			>
NEC <	phoneAppString	char "Phone", C_NULL			>

RSPRstartupProcessExitOK	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSCEContactEditInsertEmptyRecordInDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Messages the ContactEdit object uses to insert (empty)
		records in the database. These should also close the
		dialog box, unless there was an error or something
		when saving the data out.

CALLED BY:	MSG_CONTACT_EDIT_INSERT_EMPTY_RECORD_IN_DB
PASS:		*ds:si	= RStartupContactEditClass object
		ds:di	= RStartupContactEditClass instance data
		es 	= segment of RStartupContactEditClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We intercept this message because we cannot delete
		this secret record even if this is empty. The default
		action of this MSG is that if the record is empty,
		warn the user and discard it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
; NO MORE this message
RSCEContactEditInsertEmptyRecordInDB method dynamic \
				RStartupContactEditClass, 
				MSG_CONTACT_EDIT_INSERT_EMPTY_RECORD_IN_DB
	;
	; call another message
	;
		mov	ax, MSG_CONTACT_EDIT_INSERT_RECORD_IN_DB
		GOTO	ObjCallInstanceNoLock
RSCEContactEditInsertEmptyRecordInDB	endm
endif

CommonCode	ends


if 0	; ------------- OLD CODE NO LONGER USED

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessMemoryChangeOk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User presses OK on Memory Change dialog box. Do something,
		(?) and	initiate the next dialog.
		The Memory Change dialog is shown when there is no SIM card
		present or if the SIM card has no valid contacts inside.

CALLED BY:	MSG_RSTARTUP_PROCESS_MEMORY_CHANGE_OK
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DO_MEMORY_CHANGE		;++++++++++++++++++++++++++++++++++++++++++
RSPRstartupProcessMemoryChangeOk OLD	method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_MEMORY_CHANGE_OK
	;
	; Initialize the next dialog
	;
		mov	bx, handle ExitDialog
		mov	si, offset ExitDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone

		ret
RSPRstartupProcessMemoryChangeOk	endm
endif				;++++++++++++ DO_MEMORY_CHANGE ++++++++++++


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessShowSimMemory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the SimMemoryDialog.

CALLED BY:	MSG_RSTARTUP_PROCESS_SHOW_SIM_MEMORY
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	9/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessShowSimMemory	OLD method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_SHOW_SIM_MEMORY
		.enter
	;
	; show SimMemoryDialog
	;
		mov	bx, handle SIMMemoryDialog
		mov	si, offset SIMMemoryDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
		
		.leave
		ret
RSPRstartupProcessShowSimMemory	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessSimMemoryOk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User presses OK on SIM Memory dialog box. Do something (?)
		and initiate the next dialog.
		The SIMMemoryDialog is shown when there is SIM card present
		with valid contacts inside.

CALLED BY:	MSG_RSTARTUP_PROCESS_SIM_MEMORY_OK
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessSimMemoryOk	OLD method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_SIM_MEMORY_OK
	;
	; put up "Copying" dialog
	;
		mov	bx, handle SIMMemoryCopyingDialog
		mov	si, offset SIMMemoryCopyingDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
	;
	; read the first location in SIM
	;
		mov	cx, 1
		call	RequestSIMReadLocation
		
		ret
RSPRstartupProcessSimMemoryOk	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSPRstartupProcessStopCopying
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_RSTARTUP_PROCESS_STOP_COPYING
PASS:		*ds:si	= RStartupProcessClass object
		ds:di	= RStartupProcessClass instance data
		es 	= segment of RStartupProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	9/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSPRstartupProcessStopCopying	OLD method dynamic RStartupProcessClass, 
					MSG_RSTARTUP_PROCESS_STOP_COPYING
		.enter
	;
	; dismiss copying... dialog
	;
		mov	bx, handle SIMMemoryCopyingDialog
		mov	si, offset SIMMemoryCopyingDialog
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
	;
	; exit!
	;
		mov	ax, MSG_RSTARTUP_PROCESS_SHOW_EXIT
		call	CallProcess
		.leave
		ret
RSPRstartupProcessStopCopying	endm

endif	; 0
