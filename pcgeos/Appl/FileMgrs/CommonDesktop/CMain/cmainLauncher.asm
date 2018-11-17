COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Main
FILE:		mainLauncher.asm

ROUTINES:

DOSLauncherFileSelected		- sets launcherData,pops up Edit Launcher dialog
LoadLauncherDataFromEditFile	- Sets up launcherData from the edited launcher
LoadLauncherDataFromDefaultFile	- loads launcherData from the default launcherq
LauncherSaveFileToExecute	- saves path and disk handle of executable
LoadLauncherDataFromFile	- loads launcherData from a launcher
LoadEditLauncherBoxFromLauncherData	- loads the UI from launcherData
LoadTokenIntoUI			- loads token's position (in token list) into UI
SearchTokenList			- searches the token list for a token
DOSLauncherHandleMonikerRequest	- serves the dynamic icon list a moniker
DOSLauncherArgsListChange	- enables/disables args TextEdit accordingly
DOSLauncherPopUpOptions		- sets Options UI from launcherData
DOSLauncherSetOptions		- sets launcherData from OK'd Options dialog
DOSLauncherFileCheck		- enables/disables the FileSelector "OK" button

STRUCTURE:

- DOSLauncherFileSelected
	- LoadLauncherDataFromEditFile
	- LoadLauncherDataFromDefaultFile
		- LoadLauncherDataFromFile
			- LauncherSaveFileToExecute
	- LoadEditLauncherBoxFromLauncherData
		- LoadTokenIntoUI
			- SearchTokenList
- DOSLauncherHandleMonikerRequest
- DOSLauncherArgsListChange
- DOSLauncherPopUpOptions
- DOSLauncherSetOptions
- DOSLauncherFileCheck

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/92		Initial version

DESCRIPTION:
	
	The basic launcher strategy is thus:

	1.)	User Selects Create or Edit launcher.

	2.)	From this selection we open default launcher
		or a selected existing launcher to edit.

	3.)	We load the UI dialog box with info from the 3rd resourse of
		this file.  This resource is fixed, and is the LauncherStrings
		resource (launcherData inside of GeoManager).

	4.)	User edits/changes this info and clicks "OK".

	5.)	The new state of the launcher is written into our
		"launcherData" block.

	6.)	We read in the Entry table, resources and resource table.

	7.)	Modify moniker resources, swap our launcherData lmem block with
		the third resource and then recalculate the resource table.

	8.)	If creating, we close the default launcher and open the new
		launcher in the DOS Room directory, if editing we leave the
		edited file open but reset to the beginning of the file.

	9.)	We put new token in header and write out all resources/tables.

	10.)	Close up and quit.

	** The first half of this process (1-4) is handled in mainLauncher.asm,
	   and second half (5-10) is handled in mainCreateLauncher.asm


	$Id: cmainLauncher.asm,v 1.1 97/04/04 15:00:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GEOLAUNCHER

LAUNCHER_PROTO_MAJOR	equ	2
LAUNCHER_PROTO_MINOR	equ	1

CreateLauncherCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLauncherFileSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called when the user has selected a file to be edited or
		to be made into a launcher.  It takes down the appropriate File
		Selector and builds the token list by calling TokenListTokens,
		then allocates the launcherData lmem block, fills it with the
		info from the template or edited file and then sets up the UI
		accordingly.

CALLED BY:	Get[Edit][Create]LauncherFileBoxSelectTrigger,
		FolderCreateEditDosLauncher

PASS:		ss	- dgroup
		ds:bx	- path of selected file
		ax	- diskhandle of selected file
		launcherGeosName - filename of selected file

RETURN:		carry	- set on error
			- clear if OK

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/11/92		Initial version
	dlitwin	6/23/92		reworked for new usability

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLauncherFileSelected	proc	far
	.enter


	push	bx, ax				; save path and diskhandle

	mov	bp, ax				; put diskhandle in bp
	mov	ax, size GenFilePath
	mov	cx, ALLOC_DYNAMIC_LOCK
	mov	si, bx				; ds:si points to path
	call	MemAlloc
	mov	es, ax
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	LONG	jc	error

	mov	ss:[launchFilePathHandle], bx	; save this handle
	clr	di
	mov	es:[di].GFP_disk, bp		; copy in diskhandle
	mov	di, offset GFP_path
	mov	cx, size PathName/2
	rep	movsw				; copy in path
	call	MemUnlock

	segmov	es, ss				; put dgroup in es

	; We want to present the "change moniker" option only when
	; editing, not creating.  (Set to "No" always.)
	;
	push	dx, si
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle EditLauncherChangeMonikerList
	mov	si, offset EditLauncherChangeMonikerList
	mov	cx, FALSE
	clr	dx
	call	ObjMessageCall

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	tst	es:[creatingLauncher]
	jz	setCML
	mov	ax, MSG_GEN_SET_NOT_USABLE
setCML:
	call	ObjMessageCall
	pop	dx, si

	pop	bx, ax				; restore path and diskhandle
	tst	es:[creatingLauncher]		; are we creating?
	jnz	itsCreate

	call	LoadLauncherDataFromEditFile
	jc	freeFirstError
	jmp	loadUIFromLauncherDataBlock

itsCreate:
	call	LoadLauncherDataFromDefaultFile
	jc	freeFirstError

loadUIFromLauncherDataBlock:
	segmov	es, ss				; put dgroup in es
	call	DOSLauncherSetUpIconList
	call	LoadEditLauncherBoxFromLauncherData

EC <	ECCheckDGroup	es						>
	mov	ax, MSG_GEN_SET_NOT_USABLE
	tst	es:[creatingLauncher]
	jz	gotMsg
	mov	ax, MSG_GEN_SET_USABLE
gotMsg:
	mov	dl, VUM_NOW
	mov	bx, handle EditLauncherDestinationList
	mov	si, offset EditLauncherDestinationList
	call	ObjMessageCall

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle EditLauncherBox
	mov	si, offset EditLauncherBox
	call	ObjMessageCall			; open dialog

	jmp	exit				; no errors, so just exit

freeFirstError:
	clr	bx
	xchg	bx, ss:[tokenList]
	tst	bx
	jz	error
	call	MemFree
error:
	call	DesktopOKError			; handle error that occured

exit:
	.leave
	ret
DOSLauncherFileSelected	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadLauncherDataFromEditFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called when the user is editing an existing launcher.
		We push the file-to-edit's name into LoadLauncherDataFromFile.

CALLED BY:	DOSLauncherFileSelected

PASS:		es, ss	- dgroup
		ds:bx	- path of selected file
		ax	- diskhandle of selected file

RETURN: 	carry set on error, ax = error code (LauncherError)

DESTROYED:	all but ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/7/92		Initial version
	dlitwin	6/23/92		reworked for new usability

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadLauncherDataFromEditFile	proc	near
	uses	es, ds
	.enter
EC<	ECCheckDGroup	es						>
	push	ds, bx, ax
	mov	bp, cx				; save diskhandle in bp
	push	ds				; save path segment
	mov	cx, FILE_LONGNAME_LENGTH
	segmov	ds, es, di			; put dgroup in ds
	mov	si, offset launcherGeosName	; ds:si points to name buffer
	mov	di, offset oldLauncherName	; es:di points to old name buf
SBCS <	rep	movsb				; copy to oldLauncherName>
DBCS <	rep	movsw				; copy to oldLauncherName>
	pop	ds				; restore path segment

	mov	dx, bx				; ds:dx is tail
	mov	bx, ax				; bx is diskhandle
	call	FileSetCurrentPath
LONG_EC	jc	exit				; exit if error

	segmov	ds, es, dx			; put dgroup in ds
	mov	dx, offset launcherGeosName	; point ds:dx to editing name
	pop	es, di, cx			; put selected file in cx:es:di
	mov	al, FILE_ACCESS_RW or FILE_DENY_RW
	call	LoadLauncherDataFromFile
LONG_EC	jc	exit

	; Put launcherToken into the options UI.
	;
	segmov	es, ss, ax			; es <- dgroup (nasty!)
EC <	ECCheckDGroup	es						>
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, es
	mov	bp, offset launcherToken + offset GT_chars
	mov	cx, size TokenChars
	mov	bx, handle EditLauncherOptionTokenChars
	mov	si, offset EditLauncherOptionTokenChars
	call	ObjMessageCall

	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	cx, es:[launcherToken].GT_manufID
	push	cx
	clr	bp
EC <	cmp	bx, handle EditLauncherOptionTokenManufID		>
EC <	ERROR_NE ILLEGAL_VALUE						>
	mov	si, offset EditLauncherOptionTokenManufID
	call	ObjMessageCall
	pop	cx
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	push	cx
	clr	bp
EC <	cmp	bx, handle EditLauncherListOptionsManufacturerID	>
EC <	ERROR_NE ILLEGAL_VALUE						>
	mov	si, offset EditLauncherListOptionsManufacturerID
	call	ObjMessageCall
	pop	dx

	; Enable the token if the manuf ID is not DOS_LAUNCHER.
	;
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
EC <	cmp	bx, handle EditLauncherOptionTokenManual		>
EC <	ERROR_NE ILLEGAL_VALUE						>
	mov	si, offset EditLauncherOptionTokenManual
	mov	cx, FALSE
	cmp	dx, MANUFACTURER_ID_DOS_LAUNCHER
	je	sendSwitch
	mov	cx, TRUE
sendSwitch:
	clr	dx
	push	cx				; save setting
	call	ObjMessageCall
	pop	cx
	; Call ourselves to force update of entry boxes' enabled status
	mov	ax, MSG_DOS_LAUNCHER_TOKEN_OPTIONS_CHANGE
	call	GeodeGetProcessHandle
	call	ObjMessageForce			
	clc					; no err

exit:
	.leave
	ret
LoadLauncherDataFromEditFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadLauncherDataFromDefaultFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called when the user is creating a launcher.  We push
		the default launcher's name into LoadLauncherDataFromFile.

CALLED BY:	DOSLauncherFileSelected

PASS:		es, ss	- dgroup
		ds:bx	- path of selected file
		ax	- diskhandle of selected file

RETURN: 	carry on error, ax = error code (LauncherError)

DESTROYED:	all but ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/7/92		Initial version
	dlitwin	6/23/92		reworked for new usability

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadLauncherDataFromDefaultFile	proc	near
	uses	ds
	.enter
EC<	ECCheckDGroup	es						>
	push	ds, bx, ax
	mov	di, offset launcherGeosName
SBCS <	mov	al, '.'				; search for extension	>
DBCS <	mov	ax, '.'				; search for extension	>
	mov	cx, FILE_LONGNAME_LENGTH	; don't scan past here
SBCS <	repnz	scasb				; find extension	>
DBCS <	repnz	scasw				; find extension	>
	dec	di				; point to '.'
DBCS <	dec	di							>
SBCS <	mov	{byte} es:[di], 0		; cut off extension	>
DBCS <	mov	{wchar} es:[di], 0		; cut off extension	>
	segmov	ds, es, di			; put dgroup in ds
	mov	si, offset launcherGeosName
	clr	cx				; string is null terminated
	call	LocalDowncaseString		; lowercase the name

	call	GetDefaultLauncherName
	pop	es, di, cx			; selected file in cx,es:di
	jc	exit

	mov	al, FILE_ACCESS_R or FILE_DENY_W
	call	LoadLauncherDataFromFile
	jc	exit

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle EditLauncherOptionTokenManual
	mov	si, offset EditLauncherOptionTokenManual
	mov	cx, FALSE
	clr	dx
	push	cx				; save setting
	call	ObjMessageCall
	pop	cx
	; Call ourselves to force update of entry boxes' enabled status
	mov	ax, MSG_DOS_LAUNCHER_TOKEN_OPTIONS_CHANGE
	call	GeodeGetProcessHandle
	call	ObjMessageForce

	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
ifdef PRODUCT_NDO2000
	mov	cx, MANUFACTURER_ID_GEOWORKS
else
	mov	cx, MANUFACTURER_ID_DOS_LAUNCHER
endif
	clr	bp
	mov	bx, handle EditLauncherListOptionsManufacturerID
	mov	si, offset EditLauncherListOptionsManufacturerID
	call	ObjMessageCall

	clc					; no err

exit:
	.leave
	ret
LoadLauncherDataFromDefaultFile	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultLauncherName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the Default launcher name and puts it into
		ds:dx.  If we are running EC, it looks for an EC default name
		first, and if this fails it looks for the normal name.

CALLED BY:	LoadLauncherDataFromDefaultFile

PASS:		es	= dgroup

RETURN:		carry	= set on error
				ax = ERROR_MASTER_LAUNCHER_MISSING
			= clear if launcher exists
		ds:dx	= filename of launcher to read from (path is assumed
				 to be set to the current path)
		es	= dgroup
		

DESTROYED:	all but es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDefaultLauncherName	proc near
	.enter
EC<	ECCheckDGroup	es						>
	mov	ax, SP_PRIVATE_DATA		; its located in private data
	call	FileSetStandardPath

	; In EC we first try the EC name (in code string), and if this fails
	; we try the normal name.
EC <	segmov	ds, cs, dx			; put code seg in ds	>
EC <	mov	dx, offset ECLauncherName	; point ds:dx to name	>
EC <	call	FileGetAttributes					>
EC <	jc	noECname			; if error, try regular name >

EC <	jmp	exit							>

EC <noECname:								>
	mov	bx, handle DeskStringsCommon	; standard, non EC name
	call	MemLock
	mov	ds, ax				; put DeskStrings seg in ds
assume ds:DeskStringsCommon
	mov	si, ds:[LauncherDefaultName]	; point ds:si to default name
assume ds:dgroup
	mov	di, offset oldLauncherName	; es:di points to old name buf	
	mov	cx, FILE_LONGNAME_LENGTH	;   which is not used because
SBCS <	rep	movsb				;   we are creating.	>
DBCS <	rep	movsw				;   we are creating.	>
	call	MemUnlock			; unlock DeskStrings
	segmov	ds, es
	mov	dx, offset oldLauncherName	;ds:dx <- ptr to filename

EC <exit:								>

	call	FileGetAttributes
	mov	ax, ERROR_MASTER_LAUNCHER_MISSING

	.leave
	ret
GetDefaultLauncherName	endp

SBCS <EC < ECLauncherName	byte	'EC Default DOS Launcher', 0 >>
DBCS <EC < ECLauncherName	wchar	'EC DOS Launcher', 0 >>




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadLauncherDataFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called when the user is editing an existing launcher.
		We stuff the launcher's info into the launcherData block.

CALLED BY:	LoadLauncherDataFrom[Default][Edit]File

PASS:		ds:dx	- filename of launcher to read from (path is assumed
				 to be set to the current path)
		ss	- dgroup
		es:di	- selected file's path
		cx	- selected file's diskhandle
		al	- FileAccessFlags for launcher

RETURN:		carry set on error, ax = error code (LauncherError)

DESTROYED:	all but es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadLauncherDataFromFile	proc	near
	uses	es
	.enter

	push	es, di, cx			; save selected file
	segmov	es, ss, di
	mov	di, offset fileOperationInfoEntryBuffer	+ FOIE_name
	mov	si, dx				; point ds:si to filename
	mov	cx, FILE_LONGNAME_LENGTH
SBCS <	rep	movsb				; copy name to fileOperat...>
DBCS <	rep	movsw				; copy name to fileOperat...>
	mov	ss:[fileOperationInfoEntryBuffer].FOIE_type, GFT_EXECUTABLE
	clr	ss:[fileOperationInfoEntryBuffer].FOIE_attrs

	call	FileOpen
	LONG	jc	exit			; exit on error

	mov	bx, ax				; put file handle in bx

	mov	ss:[launcherFileHandle], bx	; store file handle
	mov	si, dx				; put string in ds:si for error

	push	bx				; save file handle

	; Add a check for the launcher's protocol number.  We assume too
	; much about the launcher's layout to not make sure we are dealing
	; with the right one.
	mov	ax, FEA_PROTOCOL
	mov	cx, size ProtocolNumber
	sub	sp, cx
	mov	di, sp
	call	FileGetHandleExtAttributes	; get proto number
EC <	ERROR_C LAUNCHER_BAD_FILE_TYPE >
	cmp	es:[di].PN_major, LAUNCHER_PROTO_MAJOR
   LONG	jne	launcherBadProto
	cmp	es:[di].PN_minor, LAUNCHER_PROTO_MINOR
   LONG	jb	launcherBadProto
	add	sp, cx

	mov	ax, FEA_TOKEN
	mov	di, offset launcherToken	; es:di is launcherToken
	mov	cx, size GeodeToken
	call	FileGetHandleExtAttributes	; get token
EC <	ERROR_C LAUNCHER_BAD_FILE_TYPE >

	; Copy launcherToken to launcherMonikerToken.
	;
	push	es, di, ds, si
	segmov	ds, es, si
	mov	si, di
	mov	di, offset launcherMonikerToken
	mov	cx, size GeodeToken/2
	rep	movsw
	pop	es, di, ds, si

	pop	bx				; file handle

	mov	cx, LAUNCHERSTRINGS_RESID
	clr	dx				; start at begining
	call	GeodeFindResource
	mov	bp, ax				; save resource size

	mov	al, FILE_POS_START
	call	FilePos				; set file position

	mov	ax, bp				; restore resource size
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	mov	ds, ax				; put segment in ds
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jc	closeAndExit			; exit on error

	mov	ss:[launcherData], bx		; creating launcherData...

	mov	al, FILE_NO_ERRORS
	mov	bx, ss:[launcherFileHandle]
	mov	cx, bp				; put resource size in cx
	clr	dx				; start at 0
	call	FileRead			; read info into launcherData
	jc	closeUnlockAndExit

	mov	bx, ss:[launcherData]		; put launcherData handle in bx
	mov	ds:[LMBH_handle], bx		; point to its handle
	mov	ax, mask HF_LMEM		; only set LMEM
	call	MemModifyFlags			; make it a lmem heap

	tst	ss:[creatingLauncher]		; check: creating or editing?
	jz	unlockAndExit			; exit if editing

	pop	es, di, cx			; restore selected file
	call	LauncherSaveFileToExecute	; creating case
	sub	sp, 6				; fake three pushes
	segmov	es, ss
	call	LoadWorkingDirectory
	jmp	unlockAndExit

closeAndExit:
	clr	bx
	xchg	bx, ss:[launcherFileHandle]
	tst	bx
	jz	exit
	mov	al, FILE_NO_ERRORS
	call	FileClose
	jmp	exit
	
closeUnlockAndExit:
	clr	bx
	xchg	bx, ss:[launcherFileHandle]
	tst	bx
	jz	unlockAndExit
	mov	al, FILE_NO_ERRORS
	call	FileClose

unlockAndExit:
	mov	bx, ss:[launcherData]
	call	MemUnlock			; unlock launcherData

exit:
	pop	es, di, cx			;clear stack, SAVE CARRY

	.leave
	ret

launcherBadProto:
	add	sp, cx				; restore stack
	mov	al, 0
	pop	bx				; launcher file handle
	call	FileClose
	mov	ax, ERROR_MASTER_LAUNCHER_BAD	; some reasonable file error
	stc					; indicate error
	jmp	exit

LoadLauncherDataFromFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherSaveFileToExecute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called load the selected file's path and disk handle
		into the launcherData block, and set up the working directory
		default.

CALLED BY:	LoadLauncherFromDefaultFile

PASS:		ds	- locked down launcherData segment
		ss	- dgroup
		es:di	- selected file's path
		cx	- selected file's diskhandle

RETURN:		nothing

DESTROYED:	all but ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/7/92		Initial version
	dlitwin 6/23/92		updated for new usability

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherSaveFileToExecute	proc	near
	.enter

	mov	ss:[launchFileDiskHandle], cx	; save diskhandle
	push	es, di
	segmov	es, ss, di
	mov	di, offset launchFileName
	mov	cx, -1
	clr	ax
	LocalFindChar
	not	cx				; get filename length
	pop	es, di
	mov	dx, cx				; save in dx

	mov	bp, di
	clr	ax
	mov	cx, -1
	LocalFindChar
	not	cx				; get path's length into cx
	mov	bx, cx				; path length in bx, file in cx
	add	cx, dx				; add for total length
SBCS <	cmp	{byte} es:[di-2], C_BACKSLASH				>
DBCS <	cmp	{wchar} es:[di-4], C_BACKSLASH				>
	jne	gotLength			; convert first null to '\\'
	dec	cx				; paths null will be overwritten
DBCS <	dec	cx							>
gotLength:					
DBCS <	shl	cx, 1				; # chars -> # bytes	>
	mov	ax, ds:[LMBH_offset]
	add	ax, LDC_LAUNCH_FILE
	call	LMemReAlloc

	segxchg	es, ds
	mov	si, bp
	mov	di, es:[LMBH_offset]
	mov	di, es:[di][LDC_LAUNCH_FILE]
	mov	cx, bx				; pathlength into cx
	LocalCopyNString			; copy path into lmem
SBCS <	cmp	{byte} es:[di-2], C_BACKSLASH				>
DBCS <	cmp	{wchar} es:[di-4], C_BACKSLASH				>
	je	hasSlash
SBCS <	mov	{byte} es:[di-1], C_BACKSLASH	; convert null to '\\'	>
DBCS <	mov	{wchar} es:[di-2], C_BACKSLASH	; convert null to '\\'	>
	jmp	addFilename
hasSlash:
	LocalPrevChar esdi			; overwrite null
addFilename:
	segmov	ds, ss, si
	mov	si, offset launchFileName
	mov	cx, dx				; put filenamelength in cx
	LocalCopyNString
	segmov	ds, es, di			; restore lmem to ds

	mov	bx, ss:[launchFileDiskHandle]
	clr	cx				; this call gets size
	call	DiskSave

	mov	ax, ds:[LMBH_offset]
	add	ax, LDC_DISK_HANDLE		; put handle in ax
	call	LMemReAlloc			; realloc to fit

	segmov	es, ds, di			; es <- ds via di
	mov	di, ds:[LMBH_offset]		; put handle table into di
	mov	di, ds:[di][LDC_DISK_HANDLE]	; Disk Handle buffer in es:di
	call	DiskSave			; cx is size, bx is handle

	.leave
	ret
LauncherSaveFileToExecute	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadEditLauncherBoxFromLauncherData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called after the launcherData block has been filled with
		either default data (create) or data from an existing launcher
		(edit).  We take this data and set the UI accordingly.

CALLED BY:	DOSLauncherFileSelected

PASS:		es	- dgroup
		ds:bx	- path of selected file
		cx	- diskhandle of selected file

RETURN: 	nothing

DESTROYED:	all but es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadEditLauncherBoxFromLauncherData	proc near
	.enter
EC<	ECCheckDGroup	es						>
	mov	bx, es:[launcherData]
	call	MemLock
	mov	ds, ax				; lock down into ds

	call	LoadUIFlagsFromLauncherData

; load Geos name
	mov	dx, es				; put dgroup into dx
	mov	bp, offset launcherGeosName	; Geos Name buf in dx:bp
	clr	cx				; it is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle EditLauncherGeosName
	mov	si, offset EditLauncherGeosName
	mov	di, mask MF_CALL
	call	ObjMessage

; load token
	call	LoadTokenIntoUI			; no possible errors

; load working directory
	mov	dx, ds
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_WORKING_DIRECTORY] ; deref launcher flags
	clr	cx				; it is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle EditLauncherWorkingDirectory
	mov	si, offset EditLauncherWorkingDirectory
	mov	di, mask MF_CALL
	call	ObjMessage

; load check file 1
	mov	dx, ds
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_CHECKFILE1]	; deref launcher flags chunk
	clr	cx				; it is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle EditLauncherCheckFile1
	mov	si, offset EditLauncherCheckFile1
	mov	di, mask MF_CALL
	call	ObjMessage

; load check file 2
	mov	dx, ds
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_CHECKFILE2]	; deref launcher flags
	clr	cx				; it is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle EditLauncherCheckFile2
	mov	si, offset EditLauncherCheckFile2
	mov	di, mask MF_CALL
	call	ObjMessage

; load doc file
	mov	dx, ds
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_DOCFILE]	; deref launcher flags
	clr	cx				; it is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle EditLauncherDocFile
	mov	si, offset EditLauncherDocFile
	mov	di, mask MF_CALL
	call	ObjMessage

; load AppOrDoc dialog custom text
	mov	dx, ds
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_APPORDOCCUSTOMTEXT] ; deref string
	clr	cx				; it is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle EditLauncherOptionsAppOrDocCustomText
	mov	si, offset EditLauncherOptionsAppOrDocCustomText
	mov	di, mask MF_CALL
	call	ObjMessage

	pushf					; save carry in case of error
	mov	bx, es:[launcherData]
	call	MemUnlock			; unlock launcherData block
	popf					; restore carry state

	call	DOSLauncherArgsListChange

	.leave
	ret
LoadEditLauncherBoxFromLauncherData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadWorkingDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This loads launcherData's Working Directory chunk with the
		directory of the lauched file if we are creating

CALLED BY:	

PASS:		ds - locked down launcherData segment
		ss - dgroup

RETURN: 	nothing

DESTROYED:	all but ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadWorkingDirectory	proc near
	.enter

	mov	ax, ds:[LMBH_offset]
	add	ax, LDC_WORKING_DIRECTORY
	mov	cx, PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE
	call	LMemReAlloc			; make room for full path

			; construct a full path...
	mov	dx, -1				; as non-zero as it gets...
	mov	bx, ss:[launchFileDiskHandle]
	mov	si, ds:[LMBH_offset]
	mov	si, ds:[si][LDC_LAUNCH_FILE]	; point ds:si to launch file
	segmov	es, ds, di
	mov	di, ax				; put working dir handle in di
	mov	di, ds:[di]			; point es:di to buffer
	mov	bp, di				; point bp to buffer offset
	call	FileConstructFullPath

			; strip file name off end to get path
	LocalLoadChar ax, C_BACKSLASH
	std					; reverse direction of search
	mov	cx, PATH_LENGTH_ZT
	LocalFindChar				; search for '\\'
	cld					; clear direction flag
SBCS <	cmp	{byte} es:[di], ':'		; is this after drive specifier?>
DBCS <	cmp	{wchar} es:[di], ':'		; is this after drive specifier?>
	jne	notDrive
	LocalNextChar esdi			; leave '\\' on end after ':'
notDrive:
	LocalNextChar esdi			; go to next char
SBCS <	mov	{byte} es:[di], 0		; null terminate it	>
DBCS <	mov	{wchar} es:[di], 0		; null terminate it	>
	sub	di, bp				; get length of string
	LocalNextChar esdi			; add null
	mov	cx, di
	mov	ax, ds:[LMBH_offset]
	add	ax, LDC_WORKING_DIRECTORY
	call	LMemReAlloc			; shrink to fit

	.leave
	ret
LoadWorkingDirectory	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadUIFlagsFromLauncherData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called to set the UI lists from the flags portion
		of the launcherData lmem heap.

CALLED BY:	LoadEditLauncherBoxFromLauncherData

PASS:		ds - locked down launcherData segment
		es - dgroup

RETURN: 	nothing

DESTROYED:	all but ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadUIFlagsFromLauncherData	proc near
	.enter

	clr	cx				; make sure ch is 0
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	si, ds:[si][LDC_LAUNCHER_FLAGS]	; deref launcher flags chunk
	mov	cl, ds:[si]			; get flags into bx
	push	cx, cx, cx			; push three of these for later

; prompt user to return to geos after running?
	and	cx, mask LDF_PROMPT_USER
	clr	dx				; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle EditLauncherPromptReturnList
	mov	si, offset EditLauncherPromptReturnList
	mov	di, mask MF_CALL
	call	ObjMessage

; prompt user for file to place on end of arguments string?
	pop	cx				; restore flags (1)
	and	cx, mask LDF_PROMPT_FILE
	clr	dx				; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle EditLauncherPromptFileList
	mov	si, offset EditLauncherPromptFileList
	mov	di, mask MF_CALL
	call	ObjMessage

; prompt user to confirm expanded Command String (arguments) before running?
	pop	cx				; restore flags (2)
	and	cx, mask LDF_CONFIRM
	clr	dx				; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle EditLauncherConfirmList
	mov	si, offset EditLauncherConfirmList
	mov	di, mask MF_CALL
	call	ObjMessage

; does this launcher have arguments?
	pop	cx				; restore flags (3)
	and	cx, mask LDF_NO_ARGS or mask LDF_PROMPT_ARGS or \
					mask LDF_ARGS_SET
	clr	dx				; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle EditLauncherUserSuppliedArgsList
	mov	si, offset EditLauncherUserSuppliedArgsList
	mov	di, mask MF_CALL
	call	ObjMessage

; load Argument list
	mov	dx, ds
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_ARGUMENTS]	; deref launcher flags chunk
	clr	cx				; it is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle EditLauncherArgumentText
	mov	si, offset EditLauncherArgumentText
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
LoadUIFlagsFromLauncherData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadTokenIntoUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is routine gets the position of the file's token in the
		tokenList.  If it cannot be found, alternatives are chosen,
		in the order: Default DOS Launcher Token, DOS Executable Token,
		DOS Document Token.  If none of these are there (for some 
		unexplainable reason) we default to the first token in the
		list.

CALLED BY:	LoadEditLauncherBoxFromLauncherData

PASS:		es - dgroup
		ds - locked down launcherData block
		
RETURN: 	nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di (all but ds, es)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadTokenIntoUI	proc near
	uses	ds
	.enter
EC<	ECCheckDGroup	es						>
	; Check for token loaded in from file
	mov	ax, {word} es:[launcherMonikerToken]	; put chars 1&2 in ax
	mov	dx, {word} es:[launcherMonikerToken+2]	; put chars 3&4 in dx
	mov	bp, {word} es:[launcherMonikerToken+4]	; put manufID in bp
	call	SearchTokenList
	jnc	gotTokenPosition

	; FIX!!!   Later make first entry the launcher's token and grab
	 ;directly from the launcher file if its entry is not in the token.db

	; OK, if not there check for default launcher token
	mov	bx, handle DeskStringsCommon
	call	MemLock
	mov	ds, ax
	assume	ds:DeskStringsCommon
	mov	si, ds:[DefaultLauncherToken]
	mov	ax, ds:[si]			; put token chars 1 & 2 in ax
	inc	si
	inc	si
	mov	dx, ds:[si]			; put token chars 3 & 4 in dx
	mov	bp, MANUFACTURER_ID_GEOWORKS
	call	SearchTokenList
	jnc	gotTokenAlternate

	; No Default token?, try DOS executable
	mov	si, ds:[DOSExecToken]
	mov	ax, ds:[si]			; put token chars 1 & 2 in ax
	inc	si
	inc	si
	mov	dx, ds:[si]			; put token chars 3 & 4 in dx
	mov	bp, MANUFACTURER_ID_GEOWORKS
	call	SearchTokenList
	jnc	gotTokenAlternate

	; No DOSExec token?, try DOS document
	mov	si, ds:[DOSDocToken]
	mov	ax, ds:[si]			; put token chars 1 & 2 in ax
	inc	si
	inc	si
	mov	dx, ds:[si]			; put token chars 3 & 4 in dx
	mov	bp, MANUFACTURER_ID_GEOWORKS
	call	SearchTokenList
	jnc	gotTokenAlternate

	; None of these tokens exist? default to first in list
	clr	cx				; list starts from 0

gotTokenAlternate:
	assume ds:dgroup
	call	MemUnlock			; unlock Deskstrings

gotTokenPosition:
	clr	dx				; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle EditLauncherChooseIconList
	mov	si, offset EditLauncherChooseIconList
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
LoadTokenIntoUI	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchTokenList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is routine searches the tokenList for the passed in token
		and returns its position (0-n) in the list.  If the token is
		not in the list the routine returns carry set

CALLED BY:	LoadEditLauncherBoxFromLauncherData

PASS:		es - dgroup
		ax - token chars 1 & 2
		dx - token chars 3 & 4
		bp - manufacturers ID
		
RETURN: 	cx - position of token in list (0-n)
		carry set if token is not in list

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchTokenList	proc near
	uses	ds, si, di, bx
	.enter
EC<	ECCheckDGroup	es						>
	mov	bx, es:[tokenList]
	mov	cx, ax				; save token chars 1 & 2
	call	MemLock				; lock down tokenlist
	mov	ds, ax				; put tokenlist in ds
	mov	ax, cx				; restore token chars 1 & 2
	mov	cx, es:[tokenListSize]		; put # of tokens in cx
	clr	di				; point ds:di to tokenlist

tokenSearch:
	jcxz	noTokenFound
	dec	cx
	mov	si, di				; put start of token in si
	add	di, 6				; point di to next token
	cmp	ds:[si], ax			; check token chars 1 & 2
	jne	tokenSearch
	inc	si
	inc	si
	cmp	ds:[si], dx			; check token chars 3 & 4
	jne	tokenSearch
	inc	si
	inc	si
	cmp	ds:[si], bp			; check manufacturers ID
	jne	tokenSearch

		; if we get here we found the token
	call	MemUnlock			; unlock tokenList
	sub	cx, es:[tokenListSize]		; get negative difference
	not	cx				; negate for list number (0-n)
	clc					; no error
	jmp	done

noTokenFound:
	call	MemUnlock			; unlock tokenlist
	stc					; error
done:
	.leave
	ret
SearchTokenList	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLauncherSetUpIconList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called to correctly size the GenDynamicList of icons
		to display to the user.  The number of icons and the size
		of these icons is set.  It sets the size to be 7 icons 
		accross and one down.

CALLED BY:	DOSLauncherFileSelected

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	all but es, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLauncherSetUpIconList	proc near
	.enter

	;
	; give us Gstring monikers of chosen ManufacturerID
	;
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	bx, handle EditLauncherListOptionsManufacturerID
	mov	si, offset EditLauncherListOptionsManufacturerID
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	cx, dx
	mov	ax, mask TRF_ONLY_GSTRING or mask TRF_ONLY_PASSED_MANUFID
	clr	bx				; no header
	call	TokenListTokens			; list of the token.db's tokens

EC<	ECCheckDGroup	es						>
	mov	es:[tokenListSize], ax
	mov	es:[tokenList], bx

	mov	dx, size SetSizeArgs
	sub	sp, dx					; allocate stack frame
	mov	bp, sp					; point bp to stack
	mov	ss:[bp].SSA_width, \
	((ICONS_SHOWN_IN_LIST*(STANDARD_ICON_WIDTH+2)) shl offset SW_DATA)
	or	ss:[bp].SSA_width, (SST_PIXELS shl offset SW_TYPE)

	mov	ss:[bp].SSA_height, ((STANDARD_ICON_HEIGHT+2) shl offset SH_DATA)
		; defaulting to the NON-CGA height...

	cmp	es:[desktopDisplayType], CGA_DISPLAY_TYPE
	jne	gotHeight

	mov	ss:[bp].SSA_height, ((CGA_ICON_HEIGHT+2) shl offset SH_DATA)

gotHeight:
	or	ss:[bp].SSA_height, (SST_PIXELS shl offset SH_TYPE)

	mov	ss:[bp].SSA_count, ICONS_SHOWN_IN_LIST
	mov	ss:[bp].SSA_updateMode, VUM_NOW
	mov	ax, MSG_GEN_SET_FIXED_SIZE
	mov	bx, handle EditLauncherChooseIconList
	mov	si, offset EditLauncherChooseIconList
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size SetSizeArgs			; pop frame off stack

	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	cx, es:[tokenListSize]
	mov	bx, handle EditLauncherChooseIconList
	mov	si, offset EditLauncherChooseIconList
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
DOSLauncherSetUpIconList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLauncherRequestIconMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called when the dynamic GenList needs to show a 
		moniker on the screen. It sends us the number of the list
		item whose moniker it needs. We get it by looking in our
		local table of tokens and grabbing the moniker from the token.db

CALLED BY:	GenDynamicListClass

PASS:		cx:dx	- OD of the GenList
		bp	- entry # it needs the moniker for

RETURN:		nothing

DESTROYED:	lots of stuff (but it doesn't matter)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLauncherRequestIconMoniker	method DesktopClass,
					MSG_LAUNCHER_REQUEST_ICON_MONIKER
	.enter
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	tst	es:[tokenList]		; bail if no token list
	LONG	jz	exit

	push	cx, dx				; save GenList's OD

	mov	dh, es:[desktopDisplayType]
	;
	; keep to DS_STANDARD or smaller (i.e. convert DS_HUGE and DS_LARGE
	; into DS_STANDARD)
	;
	mov	bl, dh
	andnf	bl, mask DT_DISP_SIZE		; bl = DisplaySize
	.assert DS_STANDARD gt DS_TINY
	.assert DS_LARGE gt DS_STANDARD
	.assert DS_HUGE gt DS_LARGE
	cmp	bl, DS_STANDARD shl offset DT_DISP_SIZE
	jbe	10$
	andnf	dh, not mask DT_DISP_SIZE	; clear current size
						; set DS_STANDARD
	ornf	dh, DS_STANDARD shl offset DT_DISP_SIZE
10$:

	mov	di, bp				; put entry in di
	shl	di				; double entry
	add	di, bp				; triple entry
	shl	di				; X6 (six byte tokens)
	mov	bx, es:[tokenList]		; put tokenList handle in bx
	push	es				; save dgroup
	call	MemLock				; lock it down
	mov	es, ax				; put in es:00
	mov	ax, es:[di]			; tokenchars 1 & 2
	inc	di
	inc	di
	mov	cx, es:[di]			; tokenchars 3 & 4 (cx for now)
	inc	di
	inc	di
	mov	si, es:[di]			; manufacturer's ID
	call	MemUnlock			; release block
	pop	es				; es <= dgroup
	mov	bx, cx				; now put chars 3 & 4 in bx

	push	bp				; save entry number on stack
	mov	bp, (VMS_ICON shl offset VMSF_STYLE) or mask VMSF_GSTRING
	clr	cx				; pass back as mem block handle
	push	bp				; save VisMonikerSearchFlags
	push	cx				; pass unused buffer size
	call	TokenLoadMoniker		; grab moniker from token.db
						; returns cx = moniker size
						; di = moniker handle
	pop	ax				; restore entry number to ax
	pop	bx, si				; restore Dynam.List into bx:si

	push	di				; save this handle
	mov	dx, size ReplaceItemMonikerFrame ; size of stack frame
	sub	sp, dx				; allocate struct on stack
	mov	bp, sp				; make bp frame pointer
	mov	ss:[bp].RIMF_source.handle, di	; put handle into
	clr	ss:[bp].RIMF_source.offset	;   structure dword
	mov	ss:[bp].RIMF_item, ax		; put entry number in struct
	mov	ss:[bp].RIMF_sourceType, VMST_HPTR
	mov	ss:[bp].RIMF_dataType, VMDT_VIS_MONIKER
	mov	ss:[bp].RIMF_length, cx
	mov	ss:[bp].RIMF_width, STANDARD_ICON_WIDTH

	mov	ss:[bp].RIMF_height, STANDARD_ICON_HEIGHT ; default to non-CGA
	cmp	es:[desktopDisplayType], CGA_DISPLAY_TYPE
	jne	gotIconHeight

	mov	ss:[bp].RIMF_height, CGA_ICON_HEIGHT

gotIconHeight:
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage

	add	sp, size ReplaceItemMonikerFrame	; deallocate from stack
	pop	bx				; restore handle
	call	MemFree

exit:
	.leave
	ret
DOSLauncherRequestIconMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLauncherArgsListChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine sets the Arguments text edit object usable/not 
		usable according to the state of the UserSuppliedArgsList
		list entry.

CALLED BY:	UI
PASS:		nada
RETURN:		nada
DESTROYED:	
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/12/92		Copied from WelcomeTrans

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLauncherArgsListChange	method	DesktopClass,
					MSG_DOS_LAUNCHER_ARGS_LIST_CHANGE
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle EditLauncherUserSuppliedArgsList
	mov	si, offset EditLauncherUserSuppliedArgsList
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bx, ax				; put result in bx
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; default to disable
	cmp	bx, mask LDF_NO_ARGS		; disable if NoArgs chosen...
	je	messageSet

	mov	ax, MSG_GEN_SET_ENABLED		; ... else enable

messageSet:
	mov	dl, VUM_NOW
	mov	bx, handle EditLauncherArgumentText
	mov	si, offset EditLauncherArgumentText
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
DOSLauncherArgsListChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosLauncherTokenOptionChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/Disable the token option entry group.

CALLED BY:	MSG_DOS_LAUNCHER_TOKEN_OPTIONS_CHANGE

PASS:		*ds:si	= DesktopClass object
		ds:di	= DesktopClass instance data
		ds:bx	= DesktopClass object (same as *ds:si)
		es 	= segment of DesktopClass
		ax	= message #
		cx	= current selection
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp (allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/16/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosLauncherTokenOptionChange	method dynamic DesktopClass, 
					MSG_DOS_LAUNCHER_TOKEN_OPTIONS_CHANGE
	.enter

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	sendIt
	mov	ax, MSG_GEN_SET_ENABLED
sendIt:
	mov	bx, handle EditLauncherOptionTokenEntry
	mov	si, offset EditLauncherOptionTokenEntry
	mov	dl, VUM_NOW
	call	ObjMessageCall
	.leave
	ret
DosLauncherTokenOptionChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLauncherPopUpOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called when the user has opened up the 'Options'
		dialog of the Edit launcher box.  We need to load in the 
		text for Working directory and Checkfiles from the launcherData
		block.

CALLED BY:	UI (EditLauncherOptionsTrigger)

PASS:		es	= segment of DesktopClass

RETURN:		nothing
DESTROYED:	???
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLauncherPopUpOptions	method	DesktopClass, MSG_DOS_LAUNCHER_POP_UP_OPTIONS
	.enter
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	mov	bx, es:[launcherData]
	call	MemLock
	push	bx				; save handle for later

	mov	ds, ax				; put launcherData in ds
	mov	dx, ax				; put launcherData in dx
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_WORKING_DIRECTORY]	; deref launcher flags
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				; null terminated
	mov	bx, handle EditLauncherWorkingDirectory
	mov	si, offset EditLauncherWorkingDirectory
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	dx, ds				; put launcherData seg in dx
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_CHECKFILE1]	; deref launcher flags chunk
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				; null terminated
	mov	bx, handle EditLauncherCheckFile1
	mov	si, offset EditLauncherCheckFile1
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	dx, ds				; restore launcherData segment
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_CHECKFILE2]	; deref launcher flags chunk
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				; null terminated
	mov	bx, handle EditLauncherCheckFile2
	mov	si, offset EditLauncherCheckFile2
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	dx, ds				; restore launcherData segment
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_DOCFILE]	; deref launcher flags chunk
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				; null terminated
	mov	bx, handle EditLauncherDocFile
	mov	si, offset EditLauncherDocFile
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	dx, ds				; restore launcherData segment
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_APPORDOCCUSTOMTEXT] ; deref string
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				; null terminated
	mov	bx, handle EditLauncherOptionsAppOrDocCustomText
	mov	si, offset EditLauncherOptionsAppOrDocCustomText
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	bx				; unlock launcherData
	call	MemUnlock

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle EditLauncherOptionsBox
	mov	si, offset EditLauncherOptionsBox
	mov	di, mask MF_CALL
	call	ObjMessage			; close dialog

	.leave
	ret
DOSLauncherPopUpOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLauncherSetOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called when the user has opened up the 'Options'
		dialog of the Edit launcher box and clicked 'OK'.  It puts
		the strings the the user changed (or left alone) in the 
		launcherData segment.

CALLED BY:	UI (EditLauncherOptionsOK)

PASS:		es - segment of DesktopClass

RETURN:		nada
DESTROYED:	Nothing that matters
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLauncherSetOptions	method	DesktopClass, MSG_DOS_LAUNCHER_SET_OPTIONS
	.enter
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	mov	bx, es:[launcherData]
	call	MemLock
	mov	ds, ax				; put launcherData into ds
	push	bx				; save handle for later

; make sure this lmem chunk is large enough
	mov	ax, ds:[LMBH_offset]
	add	ax, LDC_WORKING_DIRECTORY
	mov	cx, PATH_BUFFER_SIZE
	call	LMemReAlloc

	mov	dx, ds				; put launcherData seg in dx
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_WORKING_DIRECTORY]	; deref working Dir
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	bx, handle EditLauncherWorkingDirectory
	mov	si, offset EditLauncherWorkingDirectory
	mov	di, mask MF_CALL
	call	ObjMessage

; make sure this lmem chunk is large enough
	mov	ax, ds:[LMBH_offset]
	add	ax, LDC_CHECKFILE1
	mov	cx, PATH_BUFFER_SIZE
	call	LMemReAlloc

	mov	dx, ds				; put launcherData seg in dx
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_CHECKFILE1]	; deref launcher flags chunk
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	bx, handle EditLauncherCheckFile1
	mov	si, offset EditLauncherCheckFile1
	mov	di, mask MF_CALL
	call	ObjMessage
if PZ_PCGEOS
	call	ConvertYenToSlashInString
endif

; make sure this lmem chunk is large enough
	mov	ax, ds:[LMBH_offset]
	add	ax, LDC_CHECKFILE2
	mov	cx, PATH_BUFFER_SIZE
	call	LMemReAlloc

	mov	dx, ds				; put launcherData seg in dx
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_CHECKFILE2]	; deref launcher flags chunk
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	bx, handle EditLauncherCheckFile2
	mov	si, offset EditLauncherCheckFile2
	mov	di, mask MF_CALL
	call	ObjMessage
if PZ_PCGEOS
	call	ConvertYenToSlashInString
endif

; make sure this lmem chunk is large enough
	mov	ax, ds:[LMBH_offset]
	add	ax, LDC_DOCFILE
	mov	cx, PATH_BUFFER_SIZE
	call	LMemReAlloc

	mov	dx, ds				; put launcherData seg in dx
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_DOCFILE]	; deref launcher flags chunk
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	bx, handle EditLauncherDocFile
	mov	si, offset EditLauncherDocFile
	mov	di, mask MF_CALL
	call	ObjMessage
	; Convert string to upper case as some things can't handle lower
	; case.
	mov	si, bp				; ds:si = string
	call	LocalUpcaseString		; cx = len from MSG_VIS_TEXT..
if PZ_PCGEOS
	call	ConvertYenToSlashInString
endif

; make sure this lmem chunk is large enough
	push	ds				; save ds
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	bx, handle EditLauncherOptionsAppOrDocCustomText
	mov	si, offset EditLauncherOptionsAppOrDocCustomText
	mov	di, mask MF_CALL
	call	ObjMessage			; ax = size in chars
	inc	ax				; ax = size in chars + null
DBCS <	shl	ax, 1				; ax = size in bytes 	>
	mov	cx, ax				; cx = size in bytes
	pop	ds				; restore ds
	mov	ax, ds:[LMBH_offset]
	add	ax, LDC_APPORDOCCUSTOMTEXT
	call	LMemReAlloc

	mov	dx, ds				; put launcherData seg in dx
	mov	si, ds:[LMBH_offset]		; go to handle table
	mov	bp, ds:[si][LDC_APPORDOCCUSTOMTEXT] ; deref string
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	bx, handle EditLauncherOptionsAppOrDocCustomText
	mov	si, offset EditLauncherOptionsAppOrDocCustomText
	mov	di, mask MF_CALL
	call	ObjMessage
if PZ_PCGEOS
	call	ConvertYenToSlashInString
endif

	pop	bx				; unlock launcherData
	call	MemUnlock

	.leave
	ret
DOSLauncherSetOptions	endm

if PZ_PCGEOS
ConvertYenToSlashInString	proc	near
	uses	ds, si
	.enter
	jcxz	done
	mov	ds, dx				; ds:si = string
	mov	si, bp
convLoop:
	lodsw
	cmp	ax, C_YEN_SIGN
	jne	notYen
	mov	{wchar} ds:[si]-2, C_BACKSLASH
notYen:
	loop	convLoop
done:
	.leave
	ret
ConvertYenToSlashInString	endp	
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLauncherFileCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the current selection is a directory
		a normal file and enables or disables the "OK"
		button accordingly.  Also edits or creates double-clicked file.

CALLED BY:	GLOBAL
PASS:	 	cx:dx - OD of GenFileSelector (will be needed later when
				default-action support is added)
		bp - 	GenFileSelectorEntryFlagsh       record

RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/11/92		Stole from wTrans

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLauncherFileCheck	method DesktopClass, MSG_DOS_LAUNCHER_EDIT_FILE_CHECK,
					MSG_DOS_LAUNCHER_CREATE_FILE_CHECK
	.enter

	mov	bx, handle GetCreateLauncherFileBoxSelectTrigger
	mov	si, offset GetCreateLauncherFileBoxSelectTrigger

	cmp	ax, MSG_DOS_LAUNCHER_CREATE_FILE_CHECK
	je	objectSet

	mov	bx, handle GetEditLauncherFileBoxSelectTrigger
	mov	si, offset GetEditLauncherFileBoxSelectTrigger

objectSet:
	mov	ax, MSG_GEN_SET_NOT_ENABLED	;Assume its NOT a normal file
	push	bp
	test	bp, mask GFSEF_NO_ENTRIES	;If nothing selected, treat
	jne	common				; like directory
	and	bp, mask GFSEF_TYPE 
	cmp	bp, GFSET_FILE shl offset GFSEF_TYPE
	jne	common				;Branch if not a file
	mov	ax, MSG_GEN_SET_ENABLED	;Not a dir, so is a normal file
common:
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage
	pop	bp
	cmp	ax, MSG_GEN_SET_ENABLED
	jne	exit
	test	bp, mask GFSEF_OPEN		;If double click, activate 
	je	exit				; default button
	mov	ax, MSG_GEN_ACTIVATE
	mov	di, mask MF_CALL
	call	ObjMessage
exit:
	.leave
	ret
DOSLauncherFileCheck	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLauncherSetListOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reloads the launcher icon list with tokens with the
		Manufacturer ID specified in the list options dialog.

CALLED BY:	UI (EditLauncherListOptionsOk)
PASS:	 	ds - dgroup
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	4/19/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLauncherSetListOptions	method DesktopClass,
					MSG_DOS_LAUNCHER_SET_LIST_OPTIONS
	.enter

	;
	; Free the existing token list.
	;
	mov	bx, ds:[tokenList]
	call	MemFree

	;
	; Load up the new token list.
	;
	segmov	es, ds, ax
	call	DOSLauncherSetUpIconList

	.leave
	ret

DOSLauncherSetListOptions	endm


CreateLauncherCode ends


endif				; ifndef GEOLAUNCHER
