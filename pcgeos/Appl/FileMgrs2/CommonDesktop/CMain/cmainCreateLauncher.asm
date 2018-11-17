COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Desktop
FILE:		Main

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	1/24/92		Initial version
	dlitwin 3/18/92		grabbed from CDManager, ported, modified

ROUTINES:
MakeDOSLauncher 		- calls other routines to manage creation
LoadLauncherDataFromUI		- loads LauncherData lmem heap from UI objects
LauncherGrabFlagsFromUI		- loads LauncherData flags from UI objects
LauncherGrabTokenFromUI		- loads idata's LauncherToken field from UI
LauncherReadEntryTables		- reads the header and entry tables of launcher
LauncherReadResources		- reads all the resources of the launcher
LauncherReadFileSectionIntoBlock- allocates a block and reads n bytes into it
LauncherModifyResources		- modifies the launcher's resources to customize
LauncherModifyLauncherStrings	- replace LauncherStrings with LauncherData
LauncherModifyMonikers		- modifies the icon moniker resources (new icon)
LauncherLockResource		- locks a resource and converts it to an lmem
LauncherUnlockResource		- unlocks a resource and converts it back
LauncherPrepForWriting		- opens a new file or resets the FilePos to 0
LauncherWriteFile		- calls other routines to manage writing of file
LauncherWriteResources		- writes out the resources
LauncherWriteBlockToFile	- writes a mem block to the file and frees it
DOSLauncherCancelEditBox	- frees launcherData, tokenList and closes file

STRUCTURE:
- MakeDOSLauncher 
	- LoadLauncherDataFromUI
		- LauncherGrabFlagsFromUI
		- LauncherGrabTokenFromUI
	- LauncherReadEntryTables
	- LauncherReadResources
		- LauncherReadFileSectionIntoBlock
		- LauncherModifyResources
		- LauncherModifyLauncherStrings
		- LauncherModifyMonikers
			- LauncherLockResource
			- LauncherUnlockResource
	- LauncherPrepForWriting
	- LauncherWriteFile
		- LauncherWriteResources
			- LauncherWriteBlockToFile
- DOSLauncherCancelEditBox	

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

	9.)	We put new token in header and write out all resources and	
		tables.

	10.)	Close up and quit.

	** The first half of this process (1-4) is handled in mainLauncher.asm,
	   and second half (5-10) is handled in mainCreateLauncher.asm

RCS STAMP:
	$Id: cmainCreateLauncher.asm,v 1.1 97/04/04 15:00:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GEOLAUNCHER

CreateLauncherCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeDOSLauncher 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Create a launcher using 
CALLED BY:	UI (OK button in Edit Launcher Box)

PASS:		*ds:si  = instance data
		es 	= segment of DesktopClass

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/4/92		rewrote (started from CDMCreateLauncher)
	dlitwin	6/30/92		minor mods to 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeDOSLauncher	method DesktopClass, MSG_MAKE_DOS_LAUNCHER
	.enter

	call	FileBatchChangeNotifications
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	;
	; if we haven't done proper setup, bail
	;
	tst	es:[launcherData]
	LONG jz	exit
	tst	es:[launcherFileHandle]
	LONG jz	exit

	call	LoadLauncherDataFromUI

	mov	al, FILE_POS_START
	mov	bx, es:[launcherFileHandle]	;restore file handle
	clr	cx				; beginning of file
	clr	dx
	call	FilePos

	call	LauncherReadEntryTables
	jc	closeLauncher			; exit if error
	call	LauncherReadResources
	jc	closeLauncher			; exit if error
	call	LauncherModifyResources
	jc	closeLauncher			; exit if error
	call	LauncherPrepForWriting
	jc	closeLauncher			; exit if error

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, handle EditLauncherBox
	mov	si, offset EditLauncherBox
	mov	di, mask MF_CALL
	call	ObjMessage			; close dialog

	call	LauncherWriteFile
	pushf
	jmp	closeFile

closeLauncher:
	pushf					; save error state
	jnc	closeFile
	cmp	ax, ERROR_FILE_EXISTS
	je	tryAgain			; let them try a new filename

closeFile:
	clr	bx
	xchg	bx, es:[launcherFileHandle]
	tst	bx
	jz	noFH
	push	ax				; save error code
	clr	ax
	call	FileClose			; close created file
	pop	ax				; restore error code
noFH:
;	jmp	freeOldMemoryBlocks
; must close dialog also as we closed the file.  The file is not re-opened
; unless we re-open the dialog - brianc 4/7/93
	jmp	closeAndFree

tryAgain:					; no created file to close
	call	GetDefaultLauncherName
	mov	al, FILE_ACCESS_R or FILE_DENY_W
	call	FileOpen			; open default file up again
	mov	bx, ax
	mov	es:[launcherFileHandle], ax	; save this handle
	mov	ax, ERROR_FILE_EXISTS		; restore error again
	jnc	freeOldMemoryBlocks
	mov	ax, bx				; ax = FileOpen Error code

closeAndFree:
	push	ax				; save error code
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, handle EditLauncherBox
	mov	si, offset EditLauncherBox
	mov	di, mask MF_CALL
	call	ObjMessage			; close dialog
	pop	ax				; restore error code

freeOldMemoryBlocks:
	call	LauncherFreeAllMem		; free all used memory blocks
	popf					; restore error state
	jnc	launcherMadeNoErrors		; continue if no errors

	call	DesktopOKError			; handle error that occured
	jmp	exit				; exit after error handled

launcherMadeNoErrors:
	clr	bx
	xchg	bx, es:[tokenList]
	tst	bx
	jz	noTL
	call	MemFree				; free list of tokens
noTL:
	clr	bx
	xchg	bx, es:[launcherData]
	tst	bx
	jz	noLD
	call	MemFree				; free up launcherData
noLD:

	tst	es:[creatingLauncher]
	jnz	updateCommon

	mov	bx, es:[launchFilePathHandle]
	call	MemLock
	push	bx
	mov	es, ax
	mov	cx, es:[GFP_disk]
	mov	bx, offset GFP_path
	mov	bx, es:[GFP_disk]
	segmov	ds, es, dx
	mov	dx, offset GFP_path
	call	FileSetCurrentPath		; set to current path
	pop	bx
	call	MemUnlock
	segmov	es, ss, di			; restore dgroup to es

	call	LauncherHandleRename
	jmp	updateCommon

updateCommon:
	clr	bx
	xchg	bx, es:[launchFilePathHandle]
	tst	bx
	jz	noFPH
	call	MemFree
noFPH:
	call	UpdateMarkedWindows

exit:
	call	FileFlushChangeNotifications

	.leave
	ret
MakeDOSLauncher	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherHandleRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This routine renames an edited file and informs the user if
		the new name is already taken.

CALLED BY:	MakeDOSLauncher

PASS:		es = dgroup

RETURN: 	nothing

DESTROYED:	???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/22/92		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherHandleRename	proc near
	.enter
EC <	ECCheckDGroup	es						>
	clr	ax				; looking for null
	mov	cx, FILE_LONGNAME_LENGTH
	mov	di, offset launcherGeosName	; put new name in es:di
	mov	si, di				; put start of string in si
SBCS <	repnz	scasb				; getting length of string>
DBCS <	repnz	scasw				; getting length of string>
	sub	di, si				; size is difference
	mov	bx, di				; save in bx

	clr	ax				; looking for null
	mov	cx, FILE_LONGNAME_LENGTH
	mov	di, offset oldLauncherName
	mov	si, di				; put start of string in si
SBCS <	repnz	scasb				; getting length of string>
DBCS <	repnz	scasw				; getting length of string>
	sub	di, si				; size is difference
	mov	cx, di				; put default smaller in cx
	cmp	bx, di
	jg	diIsSmaller
	mov	cx, bx				; put smaller size in cx
diIsSmaller:
	segmov	ds, es, di			; put dgroup in ds
	mov	di, offset launcherGeosName	; put new name in es:di
	mov	si, offset oldLauncherName	; put current name in ds:si
	repz	cmpsb				; check for equality
	jz	exit				; exit if the names are same 

	mov	si, offset launcherGeosName	; point ds:si to geos name
	mov	di, offset fileOperationInfoEntryBuffer	+ FOIE_name
	mov	cx, FILE_LONGNAME_LENGTH
SBCS <	rep	movsb				; set up fileOperationInf...>
DBCS <	rep	movsw				; set up fileOperationInf...>
	mov	es:[fileOperationInfoEntryBuffer].FOIE_type, GFT_EXECUTABLE
	clr	es:[fileOperationInfoEntryBuffer].FOIE_attrs

	mov	dx, offset oldLauncherName	; current name in ds:dx
	mov	di, offset launcherGeosName	; new name in es:di
	call	FileRename
	jnc	exit				; exit if rename went OK

	cmp	ax, ERROR_ACCESS_DENIED
	jne	regularError

	mov	ax, ERROR_LAUNCHER_NAME_CONFLICT

regularError:
	call	DesktopOKError

exit:
	.leave
	ret
LauncherHandleRename	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadLauncherDataFromUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This routine fills the launcherData block with Info from the UI 

CALLED BY:	LoadLauncherDataFromUI

PASS:		es = dgroup

RETURN: 	nothing

DESTROYED:	all but es (remains dgroup)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/23/92		Initial Version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadLauncherDataFromUI	proc	near
	.enter
EC <	ECCheckDGroup	es						>
	mov	bx, es:[launcherData]
	call	MemLock
	mov	ds, ax				; lock down launcherData to ds

	call	LauncherGrabFlagsFromUI
	call	LauncherGrabTokenFromUI

; launch file is already in launcherData

; Geos Name
	mov	dx, es				; put dgroup in dx
	mov	bp, offset launcherGeosName	; put Geos Name in idata
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	bx, handle EditLauncherGeosName
	mov	si, offset EditLauncherGeosName
	mov	di, mask MF_CALL
	call	ObjMessage

; Arguments
; make sure this lmem chunk is large enough
	mov	ax, ds:[LMBH_offset]
	add	ax, LDC_ARGUMENTS
	mov	cx, PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE
	call	LMemReAlloc

	mov	dx, ds				; put launcherData block into dx
	mov	si, ds:[LMBH_offset]
	mov	bp, ds:[si][LDC_ARGUMENTS]	; put arguments chunk in dx:bp
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	bx, handle EditLauncherArgumentText
	mov	si, offset EditLauncherArgumentText
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bx, es:[launcherData]
	call	MemUnlock			; unlock launcherData

	.leave
	ret
LoadLauncherDataFromUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherGrabFlagsFromUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This routine looks at what list items are set in the UI and
		sets the launcherData flags accordingly

CALLED BY:	LoadLauncherDataFromUI

PASS:		ds = locked down launcherData block
		es = dgroup

RETURN: 	nothing

DESTROYED:	all but ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/23/92		Initial Version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherGrabFlagsFromUI	proc	near
	.enter
EC <	ECCheckDGroup	es						>
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle EditLauncherPromptReturnList
	mov	si, offset EditLauncherPromptReturnList
	mov	di, mask MF_CALL
	call	ObjMessage
	push	ax				; save prompt return flag

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle EditLauncherPromptFileList
	mov	si, offset EditLauncherPromptFileList
	mov	di, mask MF_CALL
	call	ObjMessage
	push	ax				; save prompt file flag

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle EditLauncherConfirmList
	mov	si, offset EditLauncherConfirmList
	mov	di, mask MF_CALL
	call	ObjMessage
	push	ax				; save confirm flag
	
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle EditLauncherUserSuppliedArgsList
	mov	si, offset EditLauncherUserSuppliedArgsList
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	bx				; restore confirm flag
	or	ax, bx				; combine with arg flag
	pop	bx				; restore prompt file flag
	or	ax, bx				; combine these flags
	pop	bx				; restore prompt return flag
	or	ax, bx				; combine these flags

	push	ax
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	bx, handle EditLauncherDocFile
	mov	si, offset EditLauncherDocFile
	clr	dx				; alloc a block
	mov	di, mask MF_CALL
	call	ObjMessage
	push	cx				; handle
	clr	bp				; use to hold flags
	tst	ax
	jz	noDocFile

	push	ds
	mov	bx, cx
	call	MemLock
	mov	ds, ax
	clr	si				; ds:si = text block
	call	FolderGetNonGEOSTokenOfCreator
	pop	ds
	jc	noDocFile			; no token => no doc file

	mov	di, ds:[LMBH_offset]
	mov	di, ds:[di][LDC_DOCREADERTOKEN]
	mov	{word}ds:[di].GT_chars, ax
	mov	{word}ds:[di].GT_chars+2, bx
	mov	ds:[di].GT_manufID, si

	mov	bp, mask LDF_PROMPT_DOC		; set DOC flag
noDocFile:
	pop	bx
	call	MemFree				; free up docfile string
	pop	ax
	or	ax, bp

	mov	si, ds:[LMBH_offset]
	mov	si, ds:[si][LDC_LAUNCHER_FLAGS]	; put flags chunk in ds:si
	mov	ds:[si], al			; set flags

	.leave
	ret
LauncherGrabFlagsFromUI	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherGrabTokenFromUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This routine copies the token chars into launcherData. 

CALLED BY:	LoadLauncherDataFromUI

PASS:		ds = locked down launcherData block
		es = dgroup

RETURN: 	nothing

DESTROYED:	all but es, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/23/92		Initial Version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherGrabTokenFromUI	proc	near
	.enter
EC <	ECCheckDGroup	es						>
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle EditLauncherChooseIconList
	mov	si, offset EditLauncherChooseIconList
	mov	di, mask MF_CALL
	call	ObjMessage

EC <	cmp	ax, es:[tokenListSize]					>
EC <	ERROR_GE	BOGUS_ICON_CHOSEN				>

	mov	cx, ax				; put item # in cx
	shl	cx				; double item #
	add	cx, ax				; triple item #
	shl	cx				; six times item #

	push	ds				; save launcherData block
	mov	bx, es:[tokenList]		; put list handle in bx
	call	MemLock				; lock it down
	mov	ds, ax				; put in ds

	mov	si, cx				; point ds:si to token
	mov	di, offset launcherMonikerToken	; point es:di to monikerToken
	movsw					; copy token chars 1 & 2
	movsw					; copy token chars 3 & 4
	movsw					; copy manufacturer's ID

	call	MemUnlock			; unlock tokenList

	; See if the option to override the token for the geode header
	; and file header is set to YES.
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle EditLauncherOptionTokenManual
	mov	si, offset EditLauncherOptionTokenManual
	call	ObjMessageCall
	tst	ax
	jz	copyToToken			; nope, use same token

	; Make sure we have 4 chars in the token chars field.
	;
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
EC <	cmp	bx, handle EditLauncherOptionTokenChars			>
EC <	ERROR_NE ILLEGAL_VALUE						>
	mov	si, offset EditLauncherOptionTokenChars
	clr	dx				; allocate block
	call	ObjMessageCall
	jcxz	copyToToken			; no block returned?
	cmp	ax, size TokenChars		; have 4 chars?
	mov	bx, cx				; handle to BX
	jne	freeBXCopyToken
	call	MemLock				; lock down the block
	mov	ds, ax				; ds:si = token field
	clr	si
	mov	di, offset launcherToken	; es:di = launcher token
	.assert (offset GT_chars) eq 0
	movsw
	movsw
	call	MemFree				; bye bye block
	push	di				; es:di points to manufID
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	bx, handle EditLauncherOptionTokenManufID
	mov	si, offset EditLauncherOptionTokenManufID
	call	ObjMessageCall			; get manufID
	pop	di				; es:di -> manufID
	mov	ax, dx
	stosw					; stuff It
	jmp	doneCopying

freeBXCopyToken:
	call	MemFree
copyToToken:
	segmov	ds, es, cx			; make tokens the same
	mov	si, offset launcherMonikerToken
	mov	di, offset launcherToken
	movsw
	movsw
	movsw

doneCopying:
	pop	ds				; restore launcherData block

	.leave
	ret
LauncherGrabTokenFromUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherReadEntryTables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Read the Imported Library Entries and Exported Routine Tables
CALLED BY:	MakeDOSLauncher

PASS:		es = dgroup

RETURN:		Nothing

DESTROYED:	all but es

PSEUDO CODE/STRATEGY:
	Figure out the size of the tables
		multiply the size of ILEs by their number
		multiply the size of ERTs by their numner
	read the tables from the master launcher
	write them to the new launcher

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	1/29/92		Initial version
	dlitwin	4/2/92		Split this up into this routine and new
				function LauncherWriteEntryTables.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherReadEntryTables	proc	near
	uses	ds
	.enter
EC <	ECCheckDGroup	es						>
	; lock out a block large enough for the info
		CheckHack <(offset GFH_coreBlock + size GFH_coreBlock) eq \
				size GeodeFileHeader>
	mov	ax, offset GFH_coreBlock.GH_geoHandle	; all core block
							;  vars from here on
							;  aren't in the file
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
					;allocate as HF_SWAPABLE and HAF_LOCK
	call	MemAlloc
	; FIX this error condition
	mov	es:[launcherHeaderHandle], bx		; save header handle

	; now read in the launcher info
	; bx = file handle, ds:dx = buffer, al = 0, cx = length
	mov	bx, es:[launcherFileHandle]	;restore file handle
	mov	ds, ax				;ds:dx = buffer
	clr	dx
	clr	al
	mov	cx, offset GFH_coreBlock.GH_geoHandle
	call	FileRead
	jc	exit

	; get the size of the imported library table
	mov	ax, ds:[GFH_execHeader.EFH_importLibraryCount]
	mov	dl, size ImportedLibraryEntry
	mul	dl
	mov	di, ax				;save size

	;get the size of the exported routine table
	mov	ax, ds:[GFH_execHeader.EFH_exportEntryCount]
	mov	dl, 4				;size of export Entry
	mul	dl
	add	di, ax				;we have the size

	mov	bx, es:[launcherHeaderHandle]	; restore header block handle
	call	MemUnlock

	;allocate a locked block large enough for the lib and routine tables
	mov	ax, di				;block size
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	; fix this error condition
	mov	es:[launcherEntryTable], bx	;save table handle

	;read the tables from the master launcher
	mov	bx, es:[launcherFileHandle]
	mov	ds, ax				; ds <= block
	clr	al				; no flags
	mov	cx, di				; bytes to read
	clr	dx
	call	FileRead
	jc	exit
	mov	es:[launcherEntryTableSize], cx	; save the size for writing

	mov	bx, es:[launcherEntryTable]	; restore handle
	call	MemUnlock

	clc					; no error
exit:

	.leave
	ret
LauncherReadEntryTables	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherReadResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Read the launcher resource table and resources
CALLED BY:	MakeDOSLauncher

PASS:		es = dgroup

RETURN:		Nothing

DESTROYED:	all but es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherReadResources	proc	near
	.enter
EC <	ECCheckDGroup	es						>
	;calc the size of the resource table
	mov	cx, LAUNCHER_RESOURCE_TABLE_SIZE

	;read in the resource table into bx and save the handle
	mov	dx, es:[launcherFileHandle]
	call	LauncherReadFileSectionIntoBlock
	LONG jc	exit

	mov	es:[resourceTableHandle], bx

	;use ds for the resource table
	call	MemLock
	mov	ds, ax


;Now loop through the resources, reading the resource into a block and then
;the reallocation info into another block.

;si is the index to the arrays.  Since the arrays are of words the
;index is points to every two bytes.  That is why we inc twice.

	;read from the master launcher file
	mov	dx, es:[launcherFileHandle]	;dx stays preserved

	;get the size of the resource block
	clr	si
nextResource:					;start of loop
	mov	cx, ds:[si]
	tst	cx
	jz	doneResource

	;
	; data resources are paragraph sized in the file
	;
	test	cx, 15
	jz	30$
	andnf	cx, not 15
	add	cx, 16
30$:

	;
	; verify file position for resource
	;
if ERROR_CHECK
	push	cx, dx				; save size, file handle
	mov	bx, dx				; bx = file handle
	mov	al, FILE_POS_RELATIVE
	clr	cx				; no movement, please
	clr	dx
	call	FilePos				; dx:ax = current position
	shl	si, 1				; TEMP convert to dword offset
	cmp	dx, ({dword} ds:[FILE_POS_INFO_OFFSET][si]).high
	ERROR_NE	DESKTOP_FATAL_ERROR
	cmp	ax, ({dword} ds:[FILE_POS_INFO_OFFSET][si]).low
	ERROR_NE	DESKTOP_FATAL_ERROR
	shr	si, 1				; TEMP convert back word offset
	pop	cx, dx				; restore size, file handle
endif

	;read in the resource to bx and save the handle
	;if the resource size is zero then just skip it and the handle should
	;be null.
	call	LauncherReadFileSectionIntoBlock
	jc	exit

	mov	es:[resourceHandleList][si], bx

doneResource:

	;now read in the reallocation info
	;get the size of the resource block
	mov	cx, ds:[si][REALLOCATION_INFO_OFFSET]	;use realloc info array
	tst	cx
	jz	doneRealloc

	;read in the resource to bx and save the handle
	mov	dx, es:[launcherFileHandle]
	call	LauncherReadFileSectionIntoBlock
	jc	exit

	mov	es:[resourceReallocHandleList][si], bx

doneRealloc:

	;go to the next resource
	inc	si				;si is by words
	inc	si				;so inc twice
	cmp	si, LAUNCHER_RESOURCE_COUNT * 2
	jl	nextResource


	;now unlock the resource table block
	mov	bx, es:[resourceTableHandle]
	call	MemUnlock

exit:
	.leave
	ret
LauncherReadResources	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherReadFileSectionIntoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Read the next n bytes from a file and return a block handle
CALLED BY:	

PASS:		cx = bytes to read from file
		dx = file handle

RETURN:		bx = block handle
		carry = set if error, ax is error code (FileErrors)


DESTROYED:	ax
		ds unless ds is a fixed block


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	1/30/92		Initial version
	dlitwin 4/22/92		revised to not take block and free it before
				allocating a new block. Now we just allocate.
				Added memory error check.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherReadFileSectionIntoBlock	proc	near
	uses	dx, ds
	.enter

	mov	ax, cx
	push	ax				; save block size
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	ds, ax
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	pop	cx				; restore block size
	jc	exit

	push	bx				; save block handle

	;read the block from the passed file
	;al - flags, bx - file handle, cx - bytes, ds:dx - buffer
	clr	al				; no flags
	mov	bx, dx
	clr	dx				; start at byte pos 0
	call	FileRead			; (carry set if error)

	pop	bx				; restore handle
	call	MemUnlock			; unlock the block
						; (preserves flags)

exit:
	.leave
	ret
LauncherReadFileSectionIntoBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherModifyResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Modify the resources and recalc the resource table

CALLED BY:	MakeDOSCreateLauncher

PASS:		es = dgroup

RETURN:		???

DESTROYED:	???

PSEUDO CODE/STRATEGY:
	make all calls to modify resources

	recalculate the reallocation table

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	2/10/92		Initial version
	dlitwin	4/30/92		Changed modification of monikers to go
				through the moniker list.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherModifyResources	proc	near
	.enter
EC <	ECCheckDGroup	es						>
	segmov	ds, es, di			; put dgroup in ds
	mov	bx, es:[launcherHeaderHandle]
	mov	si, offset launcherToken
	call	MemLock
	mov	es, ax				; lock down header into es
	mov	di, offset GFH_coreBlock.GH_geodeToken
	movsw
	movsw					; copy token to header
	movsw
	call	MemUnlock
	segmov	es, ds, di			; restore dgroup to es

	call	LauncherModifyLauncherStrings

	; If we are editing a launcher, check to see if the user
	; really wants to modify the moniker already in the launcher.
	;
	tst	es:[creatingLauncher]
	jnz	modMonikers
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle EditLauncherChangeMonikerList
	mov	si, offset EditLauncherChangeMonikerList
	call	ObjMessageCall
	jc	modMonikers			; just in case none selected.
	tst	ax
	jz	skipMonikers
modMonikers:
	call	LauncherModifyMonikers
	jc	exit

skipMonikers:
	;lock the resource table into ds
	mov	bx, es:[resourceTableHandle]
	call	MemLock
	mov	ds, ax

	; we must fix up the resource table by recalculating the resources.

	; Loop through the resources, updating the sizes of the resources
	; and updating the file position

	; si is the index to the arrays.  Since the arrays are of words the
	; index is points to every two bytes.  That is why we inc twice.


	; we don't start at the first few resources becausethey aren't data
	mov	bp, FIRST_MODIFIABLE_RESOURCE * 2	;start of loop
nextResource:

	;get the size of the block point by the resource handle
	mov	bx, es:[resourceHandleList][bp]
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	mov	ds:[bp], ax			;update the size

	;now calculate the file position for the resource
	mov	bx, bp					;save index
	sub	bp, 2					;look back an entry
	mov	ax, ds:[bp]				;resource size

	;
	; data resources are paragraph sized in the file
	;
	test	ax, 15
	jz	30$
	andnf	ax, not 15
	add	ax, 16
30$:

	add	ax, ds:[bp][REALLOCATION_INFO_OFFSET]	;plus realloc size
	shl	bp, 1					;index by dwords
	add	ax, ds:[bp][FILE_POS_INFO_OFFSET]	;plus file position
	add	bp, 4					;inc one entry (dword)
	mov	ds:[bp][FILE_POS_INFO_OFFSET], ax	;makes new file position
	mov	bp, bx					;restore index to cur.

	;go to the next resource
	inc	bp				;bp is by words
	inc	bp				;bp is by words
	cmp	bp, LAUNCHER_RESOURCE_COUNT * 2
	jl	nextResource


	;now free the resource table block
	mov	bx, es:[resourceTableHandle]
	call	MemUnlock
	
exit:
	.leave
	ret
LauncherModifyResources	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherModifyLauncherStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Make the resource handle table point to us, and free the
		old LauncherStrings

CALLED BY:	LauncherModifyResources

PASS:		es = dgroup

RETURN:		nothing

DESTROYED:	all but es (remains dgroup)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	2/10/92		Initial version
	dlitwin	3/26/92		Modified to resize lmem chunk and write directly
				to them from launcherData fields, stored in the 
				LauncherInfoTable.
	dlitwin	4/2/92		changed to take existing lmem block and swap
				with the third resource instead of copying.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherModifyLauncherStrings	proc	near
	.enter
EC <	ECCheckDGroup	es						>
	;
	; free old LauncherStrings resource (launcherData resource)
	;
	mov	bx, es:[resourceHandleList+(2*LAUNCHERSTRINGS_RESID)]
	tst	bx
	jz	noOldLauncherStrings		; launcherData resource

	call	MemFree

	;
	; lock down launcherData into ds
	;
noOldLauncherStrings:				; launcherData resource
	mov	bx, es:[launcherData]
	call	MemLock
	mov	ds, ax

	;
	; restore resID	
	;
	mov	ds:[LMBH_handle], LAUNCHERSTRINGS_RESID

	;
	; point LauncherStrings resource handle to us
	;
	mov	es:[resourceHandleList+(2*LAUNCHERSTRINGS_RESID)], bx

	mov	ax, (mask HF_LMEM) shl 8	; clear only LMEM flag
	call	MemModifyFlags			; make it a resource again
	call	MemUnlock

	.leave
	ret
LauncherModifyLauncherStrings	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherModifyMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Go down the moniker list and replace each moniker with the
		new moniker.  We do this by calling TokenLoadMoniker and 
		having it give us a new chunk.  We then swap chunk pointers
		and free the old moniker.

CALLED BY:	LauncherModifyResources

PASS:		es = dgroup

RETURN:		nothing

DESTROYED:	all but es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/30/92		Initial Version
	JimG	9/15/99		Fixed up this mess.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherModifyMonikers	proc	near
	.enter
EC <	ECCheckDGroup	es						>
	mov	bx, LAUNCHER_APPUI_RESID
	call	LauncherLockResource

	call	getPtrToMonikerList		; ds:si = VisMonikerEntryList
						; ds:cx = end of table

replaceMonikerLoop:
	cmp	si, cx				; are we at the end of the list?
	jne	notDoneWithMonikerList
	jmp	doneWithMonikerList

notDoneWithMonikerList:
	mov	ax, ds:[si].VMLE_moniker.handle	; get the ObjRelocationID
	mov	bx, ax				; put in bx also
	and	ax, mask RID_SOURCE		; mask off all but RID_SOURCE
	xor	ax, (ORS_OWNING_GEODE shl offset RID_SOURCE)
	jz	notLocalMoniker			; not a local text moniker
	mov	bp, cx				; figure out what table entry
	sub	bp, si				;  we were at and save it
	push	bp				;  since we have to rederef
	call	LauncherModifyTextMoniker	; stuff launcher name into text
	; "rederef" our moniker list since it may have moved.
	call	getPtrToMonikerList		; ds:si = VisMonikerEntryList
	pop	bp
	mov	si, cx				; restore our position in
	sub	si, bp				; the list and continue
	jmp	nextListEntry

notLocalMoniker:
	mov	bp, ds:[si].VMLE_type		; put moniker type struct in bp
	test	bp, mask VMLET_GSTRING		; skip if this is not a gstring
   LONG	jz	nextListEntry

	and	bx, mask RID_INDEX		; mask off all but res. id
	push	ds				; save moniker list segment
	push	bx				; push resource id number
	call	LauncherLockResource
	
	mov	ax, bp				; copy moniker type to ax
	andnf	ax, mask VMLET_GS_ASPECT_RATIO	; mask off all but aspect ratio

	.assert (offset VMLET_GS_ASPECT_RATIO) eq (offset DT_DISP_ASPECT_RATIO)
	mov	dh, al				; use as DT_DISP_ASPECT_RATIO

	push	cx, si				; position in & end of table
	mov	ax, bp				; copy moniker type into ax
	and	ax, mask VMLET_GS_COLOR		; mask off all but display class

	.assert (offset VMLET_GS_COLOR) eq (offset DT_DISP_CLASS)
	or	dh, al				; put into dh

	push	bx				; save moniker rsrc handle

	mov	bx, bp				; bx = VMLET
	andnf	bp, mask VMLET_STYLE		; bp = VMStyle << VMLET_STYLE
if (offset VMLET_STYLE) gt (offset VMSF_STYLE)
	mov	cl, (offset VMLET_STYLE - offset VMSF_STYLE)
	shr	bp, cl
elseif (offset VMSF_STYLE) gt (offset VMLET_STYLE)
	mov	cl, (offset VMSF_STYLE - offset VMLET_STYLE)
	shl	bp, cl
endif
	test	bx, mask VMLET_GSTRING		; is it a gstring?
	jz	notGString			; no, don't search for gstring
	ornf	bp, mask VMSF_GSTRING		; else, search for gstring
notGString:

	pop	cx				; moniker rsrc (lmem) handle
	mov	ax, {word} es:[launcherMonikerToken]
	mov	bx, {word} es:[launcherMonikerToken+2] ; load token chars
	mov	si, {word} es:[launcherMonikerToken+4]
	clr	di				; di = 0 means alloc lmem chunk
	push	ds:[LMBH_handle]		; save lmem block handle
	push	bp				; pass VisMonikerSearchFlags
	push	di				; pass unused buffer size
	call	TokenLoadMoniker		; di = new chunk handle
	jc	tokenError
	pop	bx				; restore lmem block handle
	call	MemDerefDS

	push	di
	mov	di, ds:[di]			; ds:di = new vis moniker
	.assert (offset DT_DISP_ASPECT_RATIO) eq (offset VMT_GS_ASPECT_RATIO)
	.assert (offset DT_DISP_CLASS) eq (offset VMT_GS_COLOR)
	.assert (offset DT_DISP_CLASS) eq 0
	mov	al, ds:[di].VM_type
	andnf	al, mask VMT_GS_ASPECT_RATIO
	mov	ah, dh				; value passed to TokLoadMon
	andnf	ah, mask DT_DISP_ASPECT_RATIO
	cmp	al, ah
	jne	nukeThisMoniker			; must be same aspect ratio
	mov	al, ds:[di].VM_type
	andnf	al, mask VMT_GS_COLOR
	mov	ah, dh				; value passed to TokLoadMon
	andnf	ah, mask DT_DISP_CLASS
	.assert DC_TEXT lt DC_GRAY_1
	.assert DC_GRAY_1 lt DC_GRAY_8
	.assert DC_GRAY_8 lt DC_COLOR_2
	cmp	al, DC_TEXT
	je	nukeThisMoniker			; must not be text
	cmp	al, DC_GRAY_8
	ja	notGray
	cmp	ah, DC_GRAY_8
	ja	nukeThisMoniker			; not both gray
	jmp	monikerOK
notGray:
	cmp	ah, DC_GRAY_8
	jbe	nukeThisMoniker			; not both color
monikerOK:
	pop	di				; di = chunk of new moniker

	; swap chunk handle pointers so that new moniker is in old
	; chunk handle
	;
	mov	si, ds:[LMBH_offset]		; first handle (old moniker)
	mov	ax, ds:[si]			; put old in ax
	mov	bx, ds:[di]			; put new in bx
	mov	ds:[si], bx			; swap (new into old place)
	mov	ds:[di], ax			; swap (old into new place)

	; Free the old moniker.  This will get compacted when the block
	; is unlocked.
	;
	mov	ax, di
	call	LMemFree			; free old moniker
resumeMonikerChange:
	pop	cx, si				; position in & end of table

	pop	bx				; restore resource id number
	call	LauncherUnlockResource
	pop	ds				; restore moniker list segment

nextListEntry:
	add	si, size VisMonikerListEntry	; go to next moniker in list
	jmp	replaceMonikerLoop

tokenError:
	pop	bx				; pop off moniker handle
	pop	cx, si				; pop off position & end-o-table
	pop	bx				; pop off moniker handle (again)
; There ain't nuthin to unlock!  jfh 7/23/02
;	pushf					; save flags
;	call	MemUnlock			; unlock it
;	popf					; restore flags
	pop	ds				; pop moniker list segment

doneWithMonikerList:
	pushf					; save flags
	mov	bx, LAUNCHER_APPUI_RESID
	call	LauncherUnlockResource
	popf					; restore flags
	mov	ax, ERROR_LAUNCHER_FAILED	; if an error did occur...

	.leave
	ret

nukeThisMoniker:
	; We want to effectively get rid of this moniker.. so nuke the
	; new one returned by TokenLoadMoniker and made the old one
	; simply a null gstring and resize it.
	;
	pop	ax				; ax = chunk of new moniker
	call	LMemFree			; kill new moniker
	mov	si, ds:[LMBH_offset]		; first chunk (old moniker)
	mov	di, ds:[si]			; ds:di -> VisMoniker (gstring)
	add	di, size VisMoniker + size VisMonikerGString
	mov	{byte}ds:[di], GR_END_GSTRING
	mov	ax, si
	mov	cx, size VisMoniker + size VisMonikerGString + 1
	call	LMemReAlloc
	jmp	resumeMonikerChange


	; Broke this out since we have to do it at least twice.
	; Pass:		ds - app block
	; Return:	ds:si - VisMonikerListEntry table
	;		ds:cx - end of said table
getPtrToMonikerList:
	mov	si, ds:[LMBH_offset]
	add	si, MONIKER_LIST_HANDLE_POS * 2	; * 2 because handles are words
	ChunkSizeHandle	ds, si, cx		; get table size into cx
	mov	si, ds:[si]			; dereference moniker list
	add	cx, si				; have cx point to end of table
	retn
LauncherModifyMonikers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherModifyTextMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Stuff the launcher's name into the text moniker of the launcher

CALLED BY:	LauncherModifyMonikers

PASS:		ds:si	- VisMonikerListEntry of the text Moniker
		es	- dgroup
		bx	- ObjRelocationID (ds:[si].VMLE_moniker.handle)

RETURN:		ds	- fixed up

DESTROYED:	si, ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		May move block pointed to by ds.  ds will be fixed up.
		Caller needs to rederefernce chunk pointer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/6/92		Initial Version
	JimG	9/15/99		Fixed up this mess.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherModifyTextMoniker	proc near
	uses	es, di, cx, bx
	.enter
EC <	ECCheckDGroup	es						>
	mov	ax, bx				; put ObjRelocationID in ax
	xor	ax, (ORS_CURRENT_BLOCK shl offset RID_SOURCE)
	jnz	exit				; exit if resource not in block

	mov	ax, ds:[si].VMLE_moniker.chunk	; Get moniker chunk
	mov	cx, FILE_LONGNAME_BUFFER_SIZE + size VisMoniker + \
			size VisMonikerText
	call	LMemReAlloc

	; WARNING: ds most likely moved.  si may also be invalid.
	; We can no longer refer to the VisMonikerListEntry from
	; this point forward.
	;		-- JimG 9/15/99

	mov	si, ds
	mov	di, es				; swap so chunk is destination
	mov	ds, di
	mov	es, si				; this swaps ds, es via si, di

	mov	di, ax				; put moniker chunk handle in di
	mov	di, es:[di]			; dereference into es:di
	add	di, size VisMoniker + size VisMonikerText  ; point to string!

	mov	si, offset launcherGeosName	; put launcherGeosName in ds:si

	mov	cx, FILE_LONGNAME_BUFFER_SIZE/2	; divide length by 2 (words)
	rep	movsw

	mov	si, ds
	mov	di, es				; swap back
	mov	ds, di
	mov	es, si				; this swaps ds, es via si, di

exit:
	.leave
	ret
LauncherModifyTextMoniker	endp
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherLockResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Lock the resource and declare it an LMem.

CALLED BY:	LauncherModifyMonikers

PASS:		bx = resource id
		es = dgroup

RETURN:		ds = resource segment as LMemBlock
		bx = resource handle

NOTE! The resource id must be written back to the first word of the block
when finished.

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	3/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherLockResource	proc	near
	.enter
EC <	ECCheckDGroup	es						>
	;lock the resource to a block
	shl	bx, 1				;by words
	mov	bx, es:[resourceHandleList][bx]	;get resource handle
	call	MemLock
	mov	ds, ax

	;change the block to a LMemBlock so we can rearrange the contents
	;and rely on the abilities of LMems to organize the chunks.
	mov	ds:[LMBH_handle], bx		;set handle to itself
	mov	ax, mask HF_LMEM		;only set LMEM
	call	MemModifyFlags

	.leave
	ret
LauncherLockResource	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherUnlockResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Restore a resource block and unlock it.
CALLED BY:	

PASS:		ds = resource segment made into an LMem Heap
		bx = resource id
		
RETURN:		nothing

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	3/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherUnlockResource	proc	near
	.enter

	mov	bp, bx				; put res id in bp
	;some callers do some funky LMem juggling so its safest to 
	;recompact the lmem heap
	call	LMemContract

	mov	bx, ds:[LMBH_handle]		;set handle
	mov	ax, (mask HF_LMEM) shl 8	;only clear LMEM
	call	MemModifyFlags

	mov	ds:[LMBH_handle], bp		;restore resource id

	call	MemUnlock

	.leave
	ret
LauncherUnlockResource	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherPrepForWriting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If we are creating, close the default launcher file and open
		the new file in the DOS Room  or World directory, if we are
		editing we keep the same file open, but reset the file
		position to zero so we will overwrite the new data.
		
		(Truncate the old file, however, in case it shrinks.
		 --JimG 9/16/99)

CALLED BY:	MakeDOSLauncher

PASS:		es = dgroup

RETURN: 	carry flag - set if error

DESTROYED:	all but es (remains dgroup)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherPrepForWriting	proc	near
	.enter
EC <	ECCheckDGroup	es						>
	mov	bx, es:[launcherFileHandle]	; put file handle in bx
	tst	es:[creatingLauncher]
	jz	editingLauncher

	clr	al				; no flags
	call	FileClose			; close default launcher
	clr	es:[launcherFileHandle]

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle EditLauncherDestinationList
	mov	si, offset EditLauncherDestinationList
	call	ObjMessageCall			; gets item's identifer into ax
						; identifiers for this list
						; are SP_APPLICATION,SP_DOS_ROOM
	call	FileSetStandardPath

	segmov	ds, es, dx			; put dgroup in ds
	mov	si, offset launcherGeosName	; point ds:si to geos name
	mov	di, offset fileOperationInfoEntryBuffer	+ FOIE_name
	mov	cx, FILE_LONGNAME_LENGTH
SBCS <	rep	movsb				; set up fileOperationInf...>
DBCS <	rep	movsw				; set up fileOperationInf...>
	mov	es:[fileOperationInfoEntryBuffer].FOIE_type, GFT_EXECUTABLE
	clr	es:[fileOperationInfoEntryBuffer].FOIE_attrs
	
	mov	al, FILE_DENY_RW or FILE_ACCESS_RW
	mov	ah, FILE_CREATE_ONLY shl offset FCF_MODE
	mov	cx, FILE_ATTR_NORMAL
	mov	dx, offset launcherGeosName	; point ds:dx to Geos Name
	call	FileCreate
	jc	exit				; exit on error

	mov	bx, ax				; put file handle in bx
	mov	es:[launcherFileHandle], bx	; store new file handle
	
editingLauncher:				; bx is set to new file's handle
	mov	al, FILE_POS_START
	clr	cx				; beginning of file
	clr	dx
	call	FilePos				; returns dx:ax, should be 0
EC <	tst	dx							>
EC <	ERROR_NZ ILLEGAL_VALUE						>
EC <	tst	ax							>
EC <	ERROR_NZ ILLEGAL_VALUE						>
	mov	al, FILE_NO_ERRORS
	call	FileTruncate			; nuke the file, cx:dx=0 len
	clc					; no error

exit:
	.leave
	ret
LauncherPrepForWriting	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherWriteFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Write the launcher's Entry tables, resources and token.

CALLED BY:	MakeDOSLauncher

PASS:		es = dgroup

RETURN:		nothing

DESTROYED:	everyting but es (remains dgroup)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherWriteFile	proc	near
	.enter
EC <	ECCheckDGroup	es						>
		; write the Entry tables to the new launcher

	mov	bx, es:[launcherHeaderHandle]	; restore header block handle
	call	MemLock
	mov	ds, ax				; lock into ds
	clr	dx				; ds:dx points to buffer
	mov	bx, es:[launcherFileHandle]

		CheckHack <(offset GFH_coreBlock + size GFH_coreBlock) eq \
				size GeodeFileHeader>
	mov	cx, offset GFH_coreBlock.GH_geoHandle	; all core block
							;  vars from here on
							;  aren't in the file
	clr	al				; no flags
	call	FileWrite
	mov	bx, es:[launcherHeaderHandle]
	call	MemUnlock			; flags reserved
	jnc	fileWriteNoError
	jmp	exit				; exit on error

fileWriteNoError:
	mov	bx, es:[launcherEntryTable]
	mov	bp, bx				; save this block handle
	call	MemLock
	mov	ds, ax				; point ds to entry table block
	clr	dx				; ds:dx is start of table block
	clr	al				; no flags
	mov	cx, es:[launcherEntryTableSize]
	mov	bx, es:[launcherFileHandle]
	call	FileWrite
	jnc	fileWriteNoError2
	jmp	exit				; exit on error

fileWriteNoError2:
	mov	bx, bp
	call	MemUnlock			; unlock Entry Table block

		; write resources

	call	LauncherWriteResources
   LONG	jc	exit

	; Write protocol number to file header - read from geode header
	mov	cx, size ProtocolNumber
	sub	sp, cx
	mov	di, sp
	mov	bx, es:[launcherHeaderHandle]
	call	MemLock
	mov	ds, ax
	mov	si, offset GFH_coreBlock.GH_geodeProtocol
	movsw
	movsw
	call	MemUnlock
	mov	bx, es:[launcherFileHandle]	; file handle in bx
	mov	ax, FEA_PROTOCOL
	mov	di, sp
	call	FileSetHandleExtAttributes
	mov_tr	di, ax				; save error code
	lahf					; save flags
	add	sp, cx				; restore stack
	sahf					; restore flags
	mov_tr	di, ax				; restore error code
	jc	exit

		; write tokens

	mov	ax, FEA_TOKEN
	mov	di, offset launcherToken	; es:di is launcherToken
	mov	cx, size GeodeToken
	call	FileSetHandleExtAttributes	; set token
	jc	exit

	mov	bx, handle DeskStringsCommon
	call	MemLock				; lock down DeskStrings
	mov	ds, ax				; put DeskStrings in ds
assume ds:DeskStringsCommon
	mov	si, ds:[DefaultLauncherToken]	; point ds:si to default token
assume ds:dgroup
	mov	bp, es				; put dgroup temporarily in bp
	mov	ax, MANUFACTURER_ID_GEOWORKS
	push	ax
	push	{word} ds:[si+2]
	push	{word} ds:[si]			; push token on stack
	call	MemUnlock
	mov	ds, bp				; put dgroup in ds for now
	segmov	es, ss, di			; make es point to stack
	mov	di, sp				; point es:di to stack
	mov	bx, ds:[launcherFileHandle]	; file handle in bx
	mov	ax, FEA_CREATOR			; setting Creator token
	mov	cx, size GeodeToken
	call	FileSetHandleExtAttributes
	pop	ax, ax, ax			; pop token off stack
	mov	es, bp				; restore dgroup
	jc	exit

	mov	bx, es:[launcherFileHandle]
	mov	ax, FEA_FILE_TYPE
	mov	cx, GFT_EXECUTABLE
	push	cx				; put this constant in mem
	mov	cx, size GeosFileType
	mov	bp, es				; save dgroup in bp
	segmov	es, ss, di			; put stack seg in es
	mov	di, sp				; point es:di to stack
	call	FileSetHandleExtAttributes
	mov	es, bp				; restore dgroup to es
	pop	ax				; pop constant off stack

exit:

	.leave
	ret
LauncherWriteFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherWriteResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Write the launcher resource table and resources
		It is assumed that the resource table is up to date.

CALLED BY:	LauncherWriteFile

PASS:		es = dgroup

RETURN:		???

DESTROYED:	???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherWriteResources	proc	near
	.enter
EC <	ECCheckDGroup	es						>
	;lock the resource table into ds
	mov	bx, es:[resourceTableHandle]
	call	MemLock
	mov	ds, ax

	;write the block to the passed file
	;al - flags, bx - file handle, cx - bytes, ds:dx - buffer
	clr	al				;no flags
	mov	bx, es:[launcherFileHandle]
	mov	cx, LAUNCHER_RESOURCE_TABLE_SIZE
	clr	dx				;start at byte pos 0
	call	FileWrite
	jc	error

;Now loop through the resources, write the resource and then the 
;reallocation info, freeing both.

;si is the index to the arrays.  Since the arrays are of words the
;index is points to every two bytes.  That is why why inc twice.

	;write to the new launcher file
	mov	dx, es:[launcherFileHandle]	;dx stays preserved

	;get the size of the resource block
	clr	si
nextResource:					;start of loop

	;write the resource at bx and free
	mov	cx, ds:[si]
	tst	cx
	jz	doneResource

	;
	; data resources are paragraph sized in the file
	;
	test	cx, 15
	jz	30$
	andnf	cx, not 15
	add	cx, 16
30$:

	;
	; verify file position for resource
	;
if ERROR_CHECK
	push	cx, dx				; save size, file handle
	mov	bx, dx				; bx = file handle
	mov	al, FILE_POS_RELATIVE
	clr	cx				; no movement, please
	clr	dx
	call	FilePos				; dx:ax = current position
	shl	si, 1				; TEMP convert to dword offset
	cmp	dx, ({dword} ds:[FILE_POS_INFO_OFFSET][si]).high
	ERROR_NE	DESKTOP_FATAL_ERROR
	cmp	ax, ({dword} ds:[FILE_POS_INFO_OFFSET][si]).low
	ERROR_NE	DESKTOP_FATAL_ERROR
	shr	si, 1				; TEMP convert back word offset
	pop	cx, dx				; restore size, file handle
endif

	mov	bx, es:[resourceHandleList][si]
	call	LauncherWriteBlockToFile
	jc	error
doneResource:

	;now read in the reallocation info
	;get the size of the resource block
	mov	cx, ds:[si][REALLOCATION_INFO_OFFSET]	;use realloc info array
	tst	cx
	jz	doneRealloc

	;read in the resource to bx and save the handle
	mov	bx, es:[resourceReallocHandleList][si]
	call	LauncherWriteBlockToFile
	jc	error

doneRealloc:

	;go to the next resource
	inc	si				;si is by words
	inc	si				;so inc twice
	cmp	si, LAUNCHER_RESOURCE_COUNT * 2
	jl	nextResource


	;now unlock the resource table block
	mov	bx, es:[resourceTableHandle]
	call	MemUnlock
	clc					;no error

error:
	.leave
	ret
LauncherWriteResources	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherWriteBlockToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Write n bytes from a block to a file and free the block.
CALLED BY:	

PASS:		bx = block handle (to be freed if not null)
		cx = bytes to write to the file
		dx = file handle

RETURN: 	carry = set if error


DESTROYED:	ax
		ds unless ds is a fixed block


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherWriteBlockToFile	proc	near
	uses	dx, ds
	.enter

	push	bx				; save block handle

	;lock the block
	call	MemLock
	mov	ds, ax

	;write the block to the passed file
	;al - flags, bx - file handle, cx - bytes, ds:dx - buffer
	clr	al				;no flags
	mov	bx, dx
	clr	dx				;start at byte pos 0
	call	FileWrite

	;free the block
	pop	bx				;restore block handle
	pushf					; save flags
	call	MemUnlock
	popf					; restore flags

	.leave
	ret
LauncherWriteBlockToFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherFreeAllMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This routine free's up all the memory blocks used in creating
		the launcher.

CALLED BY:	MakeDOSLauncher

PASS:		es = dgroup

RETURN: 	ax same as passed

DESTROYED:	???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/22/92		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherFreeAllMem	proc	near
	uses	ax
	.enter
EC <	ECCheckDGroup	es						>
	clr	bx
	xchg	bx, es:[launcherHeaderHandle]
	tst	bx				; don't free it if null
	jz	doneFreeingHeader

	call	MemFree				; free header

doneFreeingHeader:
	clr	bx
	xchg	bx, es:[launcherEntryTable]
	tst	bx				; don't free it if null
	jz	doneFreeingEntryTable

	call	MemFree				; free Entry Table

doneFreeingEntryTable:
	clr	bx
	xchg	bx, es:[resourceTableHandle]
	tst	bx				; don't free it if null
	jz	doneFreeingResourceTable

	call	MemFree

doneFreeingResourceTable:
	mov	bx, es:[launcherData]
	call	MemLock
	mov	ds, ax
	mov	ds:[LMBH_handle], bx		; make an lmem heap again
	mov	ax, mask HF_LMEM		;only set LMEM
	call	MemModifyFlags
	call	MemUnlock
	mov	di, offset resourceHandleList	; set to beginning of table
	mov	si, di				; si will point to end of table
	add	si, LAUNCHER_RESOURCE_COUNT * 4	; word size table (both)
	dec	di
	dec	di				; prep for initial increments

resourceAndReallocLoop:
	inc	di				; go to next table entry
	inc	di
	cmp	di, si				; are we at end of table?
	je	doneFreeingResources		; if so, exit loop
	mov	bx, es:[di]
	tst	bx
	jz	resourceAndReallocLoop		; if handle doesn't exist
	cmp	bx, es:[launcherData]		; if this the the replaced 
	je	resourceAndReallocLoop		;   LauncherStrings resource,
						;   don't free it
	call	MemFree
	mov	{word} es:[di], 0		; mark as freed
	jmp	resourceAndReallocLoop

doneFreeingResources:
	.leave
	ret
LauncherFreeAllMem	endp



if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherChangeIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine sets the current picture glyph to have the same
		moniker as the currently selected moniker in the OK box.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 9/90		Initial version
	dlitwin	5/4/92		revised to work with new lists and GeoManager

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherChangeIcon	method	DesktopClass, MSG_WELCOME_DOS_CHANGE_PICTURE
	.enter

	mov	ax, MSG_GEN_APPLY		;Apply user changes
	mov	bx, handle ChoosePictureList
	mov	si, offset ChoosePictureList
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	;Get entry with current
	mov	bx, handle ChoosePictureList	; exclusive.
	mov	si, offset ChoosePictureList
	mov	di,mask MF_CALL
	call	ObjMessage			; Returns current item in ax
	mov	dx, ax				; put item # in dx

	mov	ax, MSG_WGLYPH_DISPLAY_SET_PICTURE
	mov	bx, handle CurrentPictureGlyph	; bx:si is glyph to display 
	mov	si, offset CurrentPictureGlyph	; current picture
	mov	di, mask MF_FORCE_QUEUE 
	call	ObjMessage

	.leave
	ret
LauncherChangeIcon	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLauncherCancelEditBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called when the user is done with the edit DOS Launcher
		dialog box and the user hits cancel.  We free the token list,
		launcherData and close the opened file.

CALLED BY:	UI (EditLauncherCancel)

PASS:		ds:si	- handle of DesktopClass object
		es	= segment of DesktopClass

RETURN:		none

DESTROYED:	lots of stuff (but it doesn't matter)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/14/92		Initial version
	dlitwin	6/1/92		fixed to close the open file (oops!)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLauncherCancelEditBox	method DesktopClass,
					MSG_DOS_LAUNCHER_CANCEL_EDIT_BOX
	.enter

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	clr	bx
	xchg	bx, es:[launcherData]
	tst	bx
	jz	noLD
	call	MemFree
noLD:

	clr	bx
	xchg	bx, es:[launchFilePathHandle]
	tst	bx
	jz	noFPH
	call	MemFree
noFPH:

	clr	bx
	xchg	bx, es:[tokenList]		; put list handle in bx
	tst	bx
	jz	noTL
	call	MemFree				; free it
noTL:

	clr	bx
	xchg	bx, es:[launcherFileHandle]
	tst	bx
	jz	noFile
	clr	ax
	call	FileClose			; close the opened file
noFile:

	.leave
	ret
DOSLauncherCancelEditBox	endm

CreateLauncherCode	ends


endif				; ifndef GEOLAUNCHER
