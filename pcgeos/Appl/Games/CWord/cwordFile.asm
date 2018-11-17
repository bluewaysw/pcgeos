COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		File
FILE:		cwordFile.asm

AUTHOR:		Jennifer Lew, May  6, 1994

ROUTINES:
	Name			Description
	----			-----------
*PROCEDURES
	FileReadPuzzleSelectionToBuffer	
	FileCopyBufferToInstanceDataSourceFile	
	FileGetSourceFilePathToInstanceData	
	FileCheckIfSamePuzzleOpened	
	FileLoadPuzzle	
	FileGetCompressedFileBytes	
	FileOpenSourceDocument	
	FileParseHeader	
	FileChangeIntroText	
	FileDisplayIntro	
	FileDismissIntro	
	FileReadSourceDocument	
	FileUncompressAndReadToESBX	
	FileGetNumberClueBytes	
	FileWriteUserDocument	
	FileWriteActualUserData	
	FileWriteSelectedClueData	
	FileWriteSelectedWordCellClueDataDefault	
	FileWriteSelectedWordAndCellData	
	FileMoveElementToFront	
	FileSetNewPathInFirstElement	
	FileCreateNewPuzzleData	
	FileDeleteLastPuzzleIfTooManyPuzzles	
	FileCopyPuzzleNameToNewElement	
	FileSetPathInNewElement	
	FileFindPuzzleCallback	
	FileOpenUserDocument	
	FileInitializeMapBlock	
	FileReadUserDocument	
	FileGetUserDocPuzzleBlockHandle	
	FileGiveDataToEngine	
	FileGetBlockHandleOfFirstPuzzle	
	FileGetNameAndPathOfFirstPuzzle	
	FileFindPuzzleInMapBlock	
	StringAsciiConvertToInteger	translates an ascii number to an
					actual number

*METHODS
	CFBOpenApplication
	CFBFileSelected
	CFBOk
	CFBSaveButton
	CFBSave
	CFBClose
	CFBPuzzles
	CFBLoadLastPuzzlePlayed
	CFBGetSourceFilePath
	CFBNotifyError
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/ 6/94   	Initial revision

DESCRIPTION:
	This file contains code for the File Module.
		
	$Id: cwordFile.asm,v 1.1 97/04/04 15:14:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CwordFileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called when the Cword application starts up.
		The "Crossword Puzzles" directory needs to be created if
		it does not already exist.

		jfh 12/18/03 - We'll change this a bit.  Instead we'll just try
		to open in the proper folder and if that isn't there we'll open
		in DOCUMENT.  I've made the path, document & drive buttons
		usable in the ui file and eliminated the virtual root.

CALLED BY:	MSG_CFB_OPEN_APPLICATION
PASS:		*ds:si	= CwordFileBoxClass object
		ds:di	= CwordFileBoxClass instance data
		ds:bx	= CwordFileBoxClass object (same as *ds:si)
		es 	= segment of CwordFileBoxClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBOpenApplication	method dynamic CwordFileBoxClass, 
					MSG_CFB_OPEN_APPLICATION
	uses	ax, dx
	.enter

; jfh 12/18/03 - set the default path here

	mov	bx, handle CwordStrings
	call	MemLock
	mov	es, ax
	mov	di, offset CwordSourceDirectory
	mov	cx, es
	mov	dx, es:[di]			; cx:dx <- default path
	push	bx 					; save the memhandle for unlock
	mov	bp, SP_DOCUMENT
	mov	ax, MSG_GEN_PATH_SET
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	CFBMessageToCwordSelector
	; carry set if path invalid
	jnc	goodSet

   ; otherwise set the path to Document
	mov	di, offset nullPath
	mov	cx, es
	mov	dx, es:[di]			; cx:dx <- null path
	mov	ax, MSG_GEN_PATH_SET
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	CFBMessageToCwordSelector

goodSet:
	pop	bx
	call	MemUnlock

	.leave
	ret

; end of jfh code

;	call	FilePushDir
;if _NDO2000 or _BBXENSEM
;	mov	ax, SP_DOCUMENT
;else
;	mov	ax, SP_USER_DATA
;endif
;	call	FileSetStandardPath
;
;	mov	bx, handle CwordStrings
;	call	MemLock				; ax - segment
;	mov	ds, ax
;	mov	di, offset CwordSourceDirectory
;	mov	dx, ds:[di]
;	call	FileCreateDir
;	jc	createErr
;done:
;	call	FilePopDir
;
;	.leave
;	ret
;createErr:
;	; If the error occurred because the directory already exists,
;	; that is ok.
;	cmp	ax, ERROR_FILE_EXISTS
;	je	done
;
;	; Otherwise put up a warning to the user
;	mov	di, SOURCE_DIR_ERR
;	mov	dx, WARN_N_CONT
;	call	CwordPopUpDialogBox
;	jmp	done


CFBOpenApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBFileSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the double click of a puzzle from the puzzle
		selector dialog box.

CALLED BY:	MSG_CFB_FILE_SELECTED
PASS:		*ds:si	= CwordFileBoxClass object
		ds:di	= CwordFileBoxClass instance data
		ds:bx	= CwordFileBoxClass object (same as *ds:si)
		es 	= segment of CwordFileBoxClass
		ax	= message #

					 cx      = entry # of selection made
					 bp      = GenFileSelectorEntryFlags

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
PSEUDO CODE/STRATEGY:
	If a directory was chosen, just disable the Ok button.
	If a file was chosen and the selection was a SINGLE click,
		enable the Ok button.
	If it is a DOUBLE click on a file, this action is exactly like
		pushing the Ok trigger, so just send the Ok button a
		MSG_GEN_TRIGGER_SEND_ACTION.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBFileSelected	method dynamic CwordFileBoxClass,
					MSG_CFB_FILE_SELECTED
	uses	ax,cx
	.enter

	; See if a directory was opened

	test	bp, GFSET_SUBDIR shl offset GFSEF_TYPE
	jnz	dirChosen

	; Check whether the click was a single or double click

	test	bp, mask GFSEF_OPEN
	jz	selectionMade

	; File selection was opened (double-click)

	clr	cl			; trigger should do regular action
	mov	ax, MSG_GEN_TRIGGER_SEND_ACTION
	mov	bx, handle Ok		; single-launchable
	mov	si, offset Ok
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	finish

dirChosen:
	; Directory was selected, so disable the Ok button

	mov	ax,MSG_GEN_SET_NOT_ENABLED
	GetResourceHandleNS 	Ok, bx
	mov	si,offset Ok
	mov	dl,VUM_NOW
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
finish:
	.leave
	ret

selectionMade:

	; File was selected, so enable the Ok button

	mov	ax,MSG_GEN_SET_ENABLED
	GetResourceHandleNS 	Ok, bx
	mov	si,offset Ok
	mov	dl,VUM_NOW
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	jmp	finish

CFBFileSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBOk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the new puzzle is different from the current puzzle:
			Read in the source file of the new puzzle.
			Read in the user document of the new puzzle.
			Tell the Board module to initialize itself.

CALLED BY:	MSG_CFB_OK
PASS:		*ds:si	= CwordFileBoxClass object
		ds:di	= CwordFileBoxClass instance data
		ds:bx	= CwordFileBoxClass object (same as *ds:si)
		es 	= segment of CwordFileBoxClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBOk	method dynamic CwordFileBoxClass, 
					MSG_CFB_OK
buffer		local	FileLongName
	uses	ax,cx,dx
	.enter

	mov	ax, MSG_CFB_SAVE_BUTTON
	call	ObjCallInstanceNoLock

	; Make cx:dx the address to copy the puzzle selection to
	; and fill the buffer with the name of the newly selected
	; puzzle.
	mov	cx, ss
	lea	dx, ss:[buffer]
	call	FileReadPuzzleSelectionToBuffer	; ds - updated
	jc	finish
	
	; See if a puzzle is currently open
	cmp	ds:[di].CFBI_puzzleIsOpen, FALSE
	je	noOpenPuzzle
	
	; If the puzzle that is currently being played is the same
	; as the newly selected puzzle, do nothing else.
	call	FileCheckIfSamePuzzleOpened
	jc	finish

	; Tell the Board Module that its Engine Token is now invalid
	; since a new puzzle is about to be opened.
	push	si				; object handle
	mov	bx, handle Board		; single-launchable
	mov	si, offset Board
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_BOARD_CLEAN_UP
	call	ObjMessage
	pop	si				; object handle

noOpenPuzzle:

	; Copy the puzzle name in the buffer to the instance data
	; since the new puzzle will be opened.

	call	FileCopyBufferToInstanceDataSourceFile
	jc	finish
	call	FileGetSourceFilePathToInstanceData
	jc	finish

	call	CFBRemoveFromCompletedArray

	; Do all necessary work to Read in the new puzzle in
	; CFBI_sourceFile:	Give the source file and user document
	; 			information to the Engine and notify
	; 			the other modules to initialize
	; 			themselves.

	call	FileLoadPuzzle		; CF set if error
finish:
	.leave
	ret
CFBOk	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBRemoveFromCompletedArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the file in CFBI_sourceFile is in the completed
		array then remove it.

CALLED BY:	CFBOk

PASS:		*ds:si - CwordFileBoxClass

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBRemoveFromCompletedArray		proc	near
	uses	ax,bx,cx,di,es,ds,si,bp
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass

	;    Don't waste time searching the chunk array for every opened
	;    puzzle. Just search for ones opened when the selector
	;    is in completed mode.
	;

	mov	ax,MSG_CFFS_GET_MODE
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	CFBMessageToCwordSelector
	cmp	cl,CFFST_COMPLETED
	je	itsCompleted

done:
	.leave
	ret

itsCompleted:
	call	FileOpenUserDocument
	jc	done
	call	FileFindCompletedPuzzleInMapBlock
EC <	tst	cx				
EC <	ERROR_Z	CWORD_COMPLETED_PUZZLE_NOT_IN_COMPLETED_ARRAY >
NEC <	jcxz	closeUser				;bail if not found

	call	FileLockMapBlockAndCompletedArray
	call	FileDeleteCompletedPuzzleFromCompletedArray
	call	VMUnlock
NEC < closeUser:
	call	VMClose
	jmp	done

CFBRemoveFromCompletedArray		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReadPuzzleSelectionToBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the puzzle name from the CwordFileSelector object
		into the buffer provided.

CALLED BY:	CFBOk
PASS:		cx:dx	= buffer to fill

RETURN:		filled buffer
		ds	- possibly updated
		CF	- set if error occured in reading selection

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileReadPuzzleSelectionToBuffer	proc	near
	uses	ax,bx,di,si,bp
	.enter	

	; get the file name selected when ok was clicked

	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	CFBMessageToCwordSelector
					; cx:dx - filled buffer
					; ax - entry # of selection
					; bp - GenFileSelectorEntryFlags
	test	bp, mask GFSEF_NO_ENTRIES
	jnz	readError
	clc
finish:
	.leave
	ret
readError:
	mov	di, FILE_ERR
	call	CwordHandleError
	jmp	finish

FileReadPuzzleSelectionToBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyBufferToInstanceDataSourceFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the filename in the buffer to the instance data
		of the CwordFileBox object.

CALLED BY:	CFBOk
PASS:		cx:dx	- buffer to read from
		*ds:si	= CwordFileBoxClass object		

RETURN:		nothing	
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCopyBufferToInstanceDataSourceFile	proc	near
	class	CwordFileBoxClass
	uses	cx,si,di,ds,es
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass

	; Set up the registers to be:
	;	ds:si = puzzle name, es:di = place to copy to

	mov	di, ds:[si]			; instance data ptr
	segmov	es, ds
	lea	di, ds:[di].CFBI_sourceFile

	mov	ds, cx
	mov	si, dx

EC <	tst	{word}ds:[si]				 
EC <	ERROR_Z CWORD_MISSING_SOURCE_PUZZLE_NAME

	mov	cx, FILE_LONGNAME_BUFFER_SIZE
	shr	cx
	jnc	evenNum
	movsb
evenNum:
	rep	movsw

	.leave
	ret
FileCopyBufferToInstanceDataSourceFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetSourceFilePathToInstanceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the path of the source file into the instance data
		of the CwordFileBox object.

CALLED BY:	CFBOk
PASS:		*ds:si	= CwordFileBoxClass object
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Ask the File Selector object for its path.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetSourceFilePathToInstanceData	proc	near
	class	CwordFileBoxClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass
	mov	di, ds:[si]		; instance ptr

	; dx:bp - where to store path
	mov	dx, ds
	lea	bp, ds:[di].CFBI_filePath.GFP_path
	mov	cx, PATH_BUFFER_SIZE

	push	si				; object handle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_PATH_GET
	call	CFBMessageToCwordSelector
EC <	ERROR_C	FILE_PATH_WONT_FIT				>
	pop	si				; object handle

	mov	di, ds:[si]			; instance ptr
	mov	ds:[di].CFBI_filePath.GFP_disk, cx

	.leave
	ret
FileGetSourceFilePathToInstanceData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBLoadPuzzleFromAppLaunchBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFileBoxClass

		dx - handle of AppLaunchBlock
RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 5/94   	Initial version
	Don	 3/30/00	Added handling for downloading files
				  from the Internt via our browser

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBLoadPuzzleFromLaunchBlockCopy	method dynamic CwordFileBoxClass,
				MSG_CFB_LOAD_PUZZLE_FROM_LAUNCH_BLOCK_COPY
	push	dx
	mov	ax, MSG_CFB_LOAD_PUZZLE_FROM_APP_LAUNCH_BLOCK
	call	ObjCallInstanceNoLock
	pop	bx
	call	MemFree
	ret
CFBLoadPuzzleFromLaunchBlockCopy	endm

CFBLoadPuzzleFromAppLaunchBlock	method dynamic CwordFileBoxClass, 
				MSG_CFB_LOAD_PUZZLE_FROM_APP_LAUNCH_BLOCK
srcPath		local	PathName
srcDisk		local	hptr
destPath	local	PathName
appendOffset	local	word
	.enter

	Assert	handle dx

	;
	; A little set-up work
	;
	segmov	es,ds				;object segment
	mov	bx,dx				;AppLaunchBlock
	call	MemLock
	mov	ds,ax

	;
	; A little hack here to handle downloading puzzles from
	; the Internet. If the file is located in PRIVDATA\IMPDOC,
	; then we need to copy the file into the correct location.
	;
	push	bx, di, si, ds, es
	mov	bx, ds:[ALB_diskHandle]
	mov	si, offset ALB_path
	clr	dx				;don't add drive name
	segmov	es, ss
	lea	di, ss:[srcPath]		;buffer => ES:DI
	mov	cx, size srcPath
	call	FileConstructActualPath		;actual path => ES:DI
	mov	ss:[srcDisk], bx
	push	bx

	mov	si, offset CwordStrings:InternetSourceDirectory
	call	lockString
	mov	bx, SP_PRIVATE_DATA
	clr	dx				;don't add drive name
	lea	di, ss:[destPath]
	mov	cx, size destPath
	call	FileConstructActualPath
	segmov	ds, ss
	mov	si, di				;doc path => DS:SI (path #1)
	mov	cx, bx				;doc disk handle => CX	
	call	unlockString

	lea	di, ss:[srcPath]		;src path => ES:DI (path #2)
	pop	dx				;src disk handle => DX
	call	FileComparePaths		;is path #2 equal to #1
	pop	bx, di, si, ds, es
	cmp	al, PCT_EQUAL
	jne	storePathInfo			;no, so do nothing special

	;
	; OK - we need to copy the file.
	;
	push	bx, di, si, es
	segmov	es, ss
	lea	di, ss:[srcPath]	
	mov	si, offset ALB_dataFile
	call	appendFilename

	push	ds
	mov	si, offset CwordStrings:CwordSourceDirectory
	call	lockString
	mov	bx, SP_USER_DATA
	clr	dx				;don't add drive name
	lea	di, ss:[destPath]
	mov	cx, size destPath
	call	FileConstructActualPath
	mov	dx, bx				;dest disk handle => DX
	call	unlockString
	pop	ds
	mov	si, offset ALB_dataFile
	call	appendFilename
	call	stripCWD

	push	ds
	segmov	ds, ss, ax
	lea	si, ss:[srcPath]
	mov	cx, ss:[srcDisk]
	call	FileCopy
	pop	ds
	pop	bx, di, si, es
	jnc	updatePathInfo

	;
	; Copy the path over
	;
storePathInfo:
	mov	ax,ds:[ALB_diskHandle]
	mov	es:[di].CFBI_filePath.GFP_disk,ax
	push	si				;object chunk
	add	di,offset CFBI_filePath + offset GFP_path
	mov	si,offset ALB_path
	mov	cx,size PathName/2
	rep	movsw
	pop	si				;object chunk

	;
	; Now copy the filename
	;
	mov	cx,ds				;ALB segment
	mov	dx,offset ALB_dataFile
copyFilename:
	segmov	ds,es				;object segment
	call	FileCopyBufferToInstanceDataSourceFile

	;
	; Clean up and actually load the puzzle
	;
	call	MemUnlock			;ALB
	call	FileLoadPuzzle

	.leave
	ret

	;
	; If the copy was successful we need to copy the new file
	; & path information into the instance data. Sigh.
	;
updatePathInfo:
	call	deleteSourceFile
	push	si
	mov	es:[di].CFBI_filePath.GFP_disk, dx
	add	di, offset CFBI_filePath + offset GFP_path
	segmov	ds, ss, ax
	lea	si, ss:[destPath]
	mov	cx, ss:[appendOffset]
	sub	cx, si
	dec	cx
	rep	movsb				; copy the path
	clr	al
	stosb					; NULL-terminate it
	inc	si
	mov	cx, ds
	mov	dx, si				; filename => CX:DX
	pop	si
	jmp	copyFilename

	;
	; Lock a string down in the CwordStrings resource
	; Pass:
	;	SI	= chunk handle of string
	;
lockString:
	mov	bx, handle CwordStrings
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	retn

	;
	; Lock a string down in the CwordStrings resource
	; Pass:
	;	Nothing
	;
unlockString:
	mov	bx, handle CwordStrings
	call	MemUnlock
	retn

	;
	; Append one NULL-terminate strings onto another, ensuring
	; that a backslash is added as appropriate.
	; Pass:
	;	ES:DI	= destination
	;	DS:SI	= source
	;
appendFilename:
	push	ax, cx, di, si
	mov	cx, size PathName
	clr	al
	repne	scasb
	dec	di
	mov	al, '\\'
	cmp	es:[di-1], al
	je	appendNow
	stosb
appendNow:
	mov	ss:[appendOffset], di	
appendLoop:
	lodsb
	stosb
	tst	al
	jnz	appendLoop
	pop	ax, cx, di, si
	retn

	;
	; Strip the trailing .CWD from the destination filename
	; Pass:
	;	ES:DI	= destination filename/path
	;
stripCWD:
	push	ax, cx, di
	mov	cx, size PathName
	clr	al
	repne	scasb
	dec	di
	cmp	{byte}es:[di-4], '.'
	jne	doneStrip
	cmp	{byte}es:[di-3], 'C'
	jne	doneStrip
	cmp	{byte}es:[di-2], 'W'
	jne	doneStrip
	cmp	{byte}es:[di-1], 'D'
	jne	doneStrip
	clr	{byte}es:[di-4]
doneStrip:
	pop	ax, cx, di
	retn

	;
	; Delete the source file. Note that we ignore all errors
	; because there isn't much we can do about them, and it
	; is not a fatal situation for the user (if they download
	; the same puzzle multiple times unique names will be created
	; so the user will have multiple copies of the same puzzle -
	;  - not great, but not fatal).
	; Pass:
	;	DS:0	= AppLaunchBlock containing the source file
	;
deleteSourceFile:
	push	ax, bx, dx
	call	FilePushDir
	mov	bx, ds:[ALB_diskHandle]
	mov	dx, offset ALB_path
	call	FileSetCurrentPath
	jc	doneDelete
	mov	dx, offset ALB_dataFile
	call	FileDelete
doneDelete:
	pop	ax, bx, dx
	retn
CFBLoadPuzzleFromAppLaunchBlock		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBSaveButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The Save Trigger was pushed or the application is
		acting like it was pushed.  Display a dialog that
		tells that the puzzle is being saved and save the
		current puzzle.

CALLED BY:	MSG_CFB_SAVE_BUTTON
PASS:		*ds:si	= CwordFileBoxClass object
		ds:di	= CwordFileBoxClass instance data
		ds:bx	= CwordFileBoxClass object (same as *ds:si)
		es 	= segment of CwordFileBoxClass
		ax	= message #

RETURN:		CF	= set if error, clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBSaveButton	method dynamic CwordFileBoxClass, 
					MSG_CFB_SAVE_BUTTON
	uses	ax, cx, dx, bp
	.enter

	cmp	ds:[di].CFBI_puzzleIsOpen, FALSE
	je	done

	; Put the Saving Dialog Box to the screen

	push	si				; object handle
	mov	bx, handle SavingInteraction	; single-launchable
	mov	si, offset SavingInteraction
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage
	pop	si				; object handle

	; Save the current puzzle's solution to the user document

	mov	ax, MSG_CFB_SAVE
	call	ObjCallInstanceNoLock
	jc	errOccurred

	;    Make sure user has a chance to read the message

	mov	ax, SAVING_PUZZLE_DELAY
	call	TimerSleep

errOccurred:
	; Dismiss the Saving Dialog Box from the screen
	pushf
	mov	bx, handle SavingInteraction	; single-launchable
	mov	si, offset SavingInteraction
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjMessage
	popf
done:
	.leave
	ret
CFBSaveButton	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the user's solution of the current puzzle to
		the user document.

CALLED BY:	MSG_CFB_SAVE
PASS:		*ds:si	= CwordFileBoxClass object
		ds:di	= CwordFileBoxClass instance data
		ds:bx	= CwordFileBoxClass object (same as *ds:si)
		es 	= segment of CwordFileBoxClass
		ax	= message #

RETURN:		CF	- set if error occurred
		ds	- updated
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBSave	method dynamic CwordFileBoxClass, 
					MSG_CFB_SAVE
	.enter

	cmp	ds:[di].CFBI_puzzleIsOpen, FALSE
	je	noPuzzleOpen

	call	FileWriteUserDocument	; sets CF
finish:
	.leave
	ret
noPuzzleOpen:
	clc
	jmp	finish

CFBSave	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCheckIfSamePuzzleOpened
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares the filename in the buffer to the filename
		in the instance data of the CwordFileBox object.

CALLED BY:	CFBOk
PASS:		cx:dx	- buffer
		*ds:si	= CwordFileBoxClass object

RETURN:		CF	- set if same puzzle is opened
				(ie. the two filnames are the same)
			  clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCheckIfSamePuzzleOpened	proc	near
	class CwordFileBoxClass
	uses	cx,si,di,es
	.enter
	
	Assert	objectPtr	dssi, CwordFileBoxClass

	mov	di, ds:[si]		; instance data pointer

	; Make ds:si be the name of the puzzle already open
	lea	si, ds:[di].CFBI_sourceFile

	; es:di	- puzzle name selected
	mov	es, cx
	mov	di, dx
	
	clr	cx			; compare till NULL terminated
	call	LocalCmpStrings
	jz	found
	clc
finish:
	.leave
	ret
found:
	stc
	jmp	finish
FileCheckIfSamePuzzleOpened	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBPuzzlesCheckDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message defintion

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFileBoxClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBPuzzlesCheckDone	method dynamic CwordFileBoxClass, 
						MSG_CFB_PUZZLES_CHECK_DONE
	uses	cx
	.enter
	
	push	si
	mov	bx,handle Board
	mov	si,offset Board
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_CWORD_BOARD_CHECK_PUZZLE_COMPLETION_STATUS
	call	ObjMessage
	pop	si

	cmp	cx, PCS_EMPTY
	je	emptyPuzzle

	cmp	cx,PCS_CORRECT
	je	doneQuery

	;    I figure that some people will fill in an entire puzzle but
	;    never Check to see if it is done or even bother to change
	;    the wrong letters to correct ones. So ask them if they
	;    are done if the whole puzzle is filled in
	;

	cmp	cx,PCS_FILLED
	je	doneQuery

initiatePuzzles:
	mov	ax,MSG_CFB_PUZZLES_SAVE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

emptyPuzzle:
	;   Nuke empty puzzles so that they don't show up as In Progress
	;
	call	CFBDisposeOfPuzzle
	jmp	initiatePuzzles

doneQuery:
	mov	bx,handle MightBeCompletedInteraction
	mov	si,offset MightBeCompletedInteraction
	mov	ax,MSG_GEN_INTERACTION_INITIATE
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	jmp	done

CFBPuzzlesCheckDone		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBPuzzlesSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the user's current puzzle solution.  Display the 
		puzzle selector box.

PASS:		*ds:si	= CwordFileBoxClass object
		ds:di	= CwordFileBoxClass instance data
		ds:bx	= CwordFileBoxClass object (same as *ds:si)
		es 	= segment of CwordFileBoxClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBPuzzlesSave	method dynamic CwordFileBoxClass, 
					MSG_CFB_PUZZLES_SAVE
	uses	ax, cx, dx, bp
	.enter

	mov	ax,MSG_CFB_PUZZLES
	call	ObjCallInstanceNoLock

	.leave
	ret
CFBPuzzlesSave	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBPuzzles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the puzzle selector box.

CALLED BY:	MSG_CFB_PUZZLES
PASS:		*ds:si	= CwordFileBoxClass object
		ds:di	= CwordFileBoxClass instance data
		ds:bx	= CwordFileBoxClass object (same as *ds:si)
		es 	= segment of CwordFileBoxClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBPuzzles	method dynamic CwordFileBoxClass, 
					MSG_CFB_PUZZLES
	uses	ax, cx, dx, bp
	.enter

	mov	ax,MSG_CFFS_SET_DEFAULT_MODE
	mov	di,mask MF_FIXUP_DS
	call	CFBMessageToCwordSelector
	mov	ax,MSG_GEN_INTERACTION_INITIATE
	call	CFBMessageToSelectorInteraction


	.leave
	ret
CFBPuzzles	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFileBoxClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBDelete	method dynamic CwordFileBoxClass, 
						MSG_CFB_DELETE
	uses	dx,cx
	.enter

	cmp	ds:[di].CFBI_puzzleIsOpen, FALSE
	je	puzzlesBox

	lea	dx,ds:[di].CFBI_sourceFile
	call	FileGetAttributes
	jc	deleteError
	BitClr	cl,FA_RDONLY
	call	FileSetAttributes
	jc	deleteError
	call	FileDelete
	jc	deleteError

	call	CFBDisposeOfPuzzle

puzzlesBox:

	mov	ax,MSG_CFB_PUZZLES
	call	ObjCallInstanceNoLock

	.leave
	ret

deleteError:
	;    If we can't delete it at least mark it as completed so the
	;    user won't have to confront it in their puzzle selection box.
	;    This is especially important for puzzles in rom, which are
	;    by definition undeletable
	;

EC <	cmp	ax,ERROR_FILE_NOT_FOUND	
EC <	ERROR_E	CWORD_COULDNT_FIND_SOURCE_FILE_TO_DELETE
EC <	cmp	ax,ERROR_FILE_IN_USE
EC <	ERROR_E	CWORD_COULDNT_DELETE_SOURCE_FILE_BECAUSE_IN_USE

	mov	ax,MSG_CFB_MARK_COMPLETED
	call	ObjCallInstanceNoLock
	jmp	puzzlesBox

CFBDelete		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBMarkCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message defintion

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFileBoxClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBMarkCompleted	method dynamic CwordFileBoxClass, 
						MSG_CFB_MARK_COMPLETED
	.enter

	cmp	ds:[di].CFBI_puzzleIsOpen, FALSE
	je	puzzlesBox

	call	FileAddCompletedPuzzle
	call	CFBDisposeOfPuzzle
puzzlesBox:

	mov	ax,MSG_CFB_PUZZLES
	call	ObjCallInstanceNoLock

	.leave
	ret
CFBMarkCompleted		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBDisposeOfPuzzle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the puzzle name in CFBI_sourceName from the
		UserDoc and clean up engine

CALLED BY:	CFBDelete
		CFBMarkComplete

PASS:		*ds:si - CwordFileBox

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBDisposeOfPuzzle			proc	near
	class	CwordFileBoxClass
	uses	ax,bx,di,si
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass

	mov	di,ds:[si]
	cmp	ds:[di].CFBI_puzzleIsOpen, FALSE
	je	done
	mov	ds:[di].CFBI_puzzleIsOpen,FALSE

	call	CFBRemovePuzzleFromMainArray

	; tell the Board Module that its Engine Token is now invalid

	mov	bx, handle Board	
	mov	si, offset Board
	mov	di,  mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_BOARD_CLEAN_UP
	call	ObjMessage

done:
	.leave
	ret
CFBDisposeOfPuzzle		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBRemovePuzzleFromMainArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove puzzle name in CFBI_sourceFile from main array
		in map block of user doc

CALLED BY:	CFBDisposeOfPuzzle

PASS:		
		*ds:si - CwordFileBox

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBRemovePuzzleFromMainArray		proc	near
	uses	ax,bx,bp,ds,si,es
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass


	call	FileOpenUserDocument
	jc	done

	call	FileFindPuzzleInMapBlock
EC <	tst	cx					>
EC <	ERROR_Z	CWORD_OPEN_PUZZLE_NOT_IN_USER_DOC
NEC <	jcxz	closeUserDoc				>

	call	FileLockMapBlockAndMainArray
	call	FileDeletePuzzleFromMainArray
	call	VMUnlock

NEC < closeUserDoc:
	call	VMClose

done:
	.leave
	ret
CFBRemovePuzzleFromMainArray		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBMessageToSelectorInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a message to SelectorInteraction

CALLED BY:	UTILITY

PASS:		
		ax - message
		di - MessageFlags
		cx,dx,bp - message data
RETURN:		
		depends on MessageFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBMessageToSelectorInteraction		proc	near
	uses	bx,si,di
	.enter

	mov	bx, handle SelectorInteraction	; single-launchable
	mov	si, offset SelectorInteraction
	call	ObjMessage

	.leave
	ret
CFBMessageToSelectorInteraction		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBMessageToCwordSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a message to CwordSelector

CALLED BY:	UTILITY

PASS:		
		ax - message
		di - MessageFlags
		cx,dx,bp - message data
RETURN:		
		depends on MessageFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBMessageToCwordSelector		proc	near
	uses	bx,si,di
	.enter

	mov	bx, handle CwordSelector	; single-launchable
	mov	si, offset CwordSelector
	call	ObjMessage

	.leave
	ret
CFBMessageToCwordSelector		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLoadPuzzle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Manage reading the puzzle's source and user solution
		documents into the Engine Module and notifing the
		other modules about the new puzzle.

CALLED BY:	FILE MODULE INTERNAL  (CFBOk, CFBLoadLastPuzzlePlayed)
PASS:		*ds:si	= CwordFileBoxClass object

RETURN:		CF	- set if error, clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileLoadPuzzle	proc	near
	class CwordFileBoxClass
bufferHandle	local	word
protocolNum	local	ProtocolNumber
	uses	ax,bx,cx,dx,di,si,bp,es
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass

	call	FileOpenSourceDocument		; ax - file handle
	LONG jc	finish

	mov	di, ds:[si]			; instance data ptr
	mov	ds:[di].CFBI_fileHandle, ax

	; See if the puzzle selected has a valid protocol number

	mov	bx, ax				; file handle
	mov	ax, FEA_PROTOCOL
	segmov	es, ss
	lea	di, ss:[protocolNum]
	mov	cx, size ProtocolNumber
	call	FileGetHandleExtAttributes
	LONG jc	badProtAttrs

	cmp	ss:[protocolNum].PN_major, SOURCE_PROTOCOL_MAJOR
	LONG jne	badProtAttrs

	cmp	ss:[protocolNum].PN_minor, SOURCE_PROTOCOL_MINOR
	LONG jne	badProtAttrs

	call	FileGetCompressedFileBytes	; ax = compressed bytes
						; cx = offset into file
						;   after initial number
						;   of compressed bytes
	LONG jc	errAndClose
	call	FileUncompressAndReadToESBX
			; es:bx - buffer containing containing file 
			; 	contents, beginning with number of header
			; 	bytes
			; cx	- handle of buffer containing file data
	LONG jc	errAndClose

	mov	ss:[bufferHandle], cx

	call	FileParseHeader			; ah = rows, al = columns
						; bx = updated offset
	jc	initErrNoIntro

	;    User don't like having this box come up, but it may be
	;    required for our licensing agreement. So it is commented
	;    out for now. ???

;	call	FileDisplayIntro

	call	FileReadSourceDocument		; dx - engine token
	jc	initErr
	call	FileReadUserDocument
	jc	initErr

	; Free the buffer containing the source file data
	mov	bx, ss:[bufferHandle]
	Assert	handle	bx
	call	MemFree

	mov	di, ds:[si]		; new instance data pointer
	mov	ax, ds:[di].CFBI_engine		; old engine token

	; initialize the new puzzle information that needs to be kept
	mov	ds:[di].CFBI_puzzleIsOpen, TRUE
	mov	ds:[di].CFBI_engine, dx
	
	; clean up the old engine data, pass EngineCleanUp the old
	; engine token so it knows what to clean up
	mov	dx, ax				; old engine token
	call	EngineCleanUp

	; close the source file for the puzzle
	clr	al				; error flags
	Assert	fileHandle	ds:[di].CFBI_fileHandle
	mov	bx, ds:[di].CFBI_fileHandle
	call	FileClose
	jc	fileErr

	call	FileSetPuzzleNameInPrimary
	clc
finish:
	.leave
	ret
badProtAttrs:
	mov	di, PROT_ERR
	call	CwordHandleError
	jmp	errAndClose
initErr:
;	call	FileDismissIntro
initErrNoIntro:
	; Free the buffer containing the file data
	mov	bx, ss:[bufferHandle]
	Assert	handle	bx
	call	MemFree
errAndClose:
	; close the file
	clr	al
	mov	di, ds:[si]			; instance data ptr
	Assert	fileHandle	ds:[di].CFBI_fileHandle
	mov	bx, ds:[di].CFBI_fileHandle
	call	FileClose
	stc
	jmp	finish
fileErr:
	; Free the buffer containing the file data
	mov	bx, ss:[bufferHandle]
	call	MemFree

;	call	FileDismissIntro
	mov	di, FILE_ERR
	call	CwordHandleError
	jmp	finish

FileLoadPuzzle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSetPuzzleNameInPrimary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the name of the puzzle to the primary's long term
		moniker.

CALLED BY:	FileLoadPuzzle

PASS:		*ds:si - CwordFileBoxClass
			CFBI_sourceFile is filled in

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSetPuzzleNameInPrimary		proc	near
	class	CwordFileBoxClass
	uses	ax,bx,cx,si,di,dx,bp
	.enter

	Assert	objectPtr	dssi,CwordFileBoxClass

	mov	dx,size ReplaceVisMonikerFrame
	sub	sp,dx
	mov	bp,sp

	mov	ax, ds
	mov	ss:[bp].RVMF_source.segment,ax
	mov	ax, ds:[si]			; instance data ptr
	add	ax, offset CFBI_sourceFile
	mov	ss:[bp].RVMF_source.offset, ax

	mov	ss:[bp].RVMF_sourceType, VMST_FPTR
	mov	ss:[bp].RVMF_dataType,VMDT_TEXT
	clr	ss:[bp].RVMF_length			;null terminated
	mov	ss:[bp].RVMF_updateMode, VUM_NOW	;no particular reason

	;    Use MF_CALL so that the object and its instance data
	;    don't move before the name is copied out
	;

	mov	bx, handle CwordPrimary
	mov	si, offset CwordPrimary
	mov	di, mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	ax, MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER
	call	ObjMessage
	add	sp, size ReplaceVisMonikerFrame

	.leave
	ret
FileSetPuzzleNameInPrimary		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetCompressedFileBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the number of compressed bytes in the file that
		does not include the alternate clues.

CALLED BY:	FILE MODULE INTERNAL	(FileLoadPuzzle)
PASS:		*ds:si	- CwordFileBox object

RETURN:		ax 	- number of compressed bytes
		cx	- offset into file after initial number of
				compressed bytes
		CF	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	offset into file after initial number of compressed bytes =
		(updated offset) - (original offset) + 1 
	The addition of 1 is for the C_LINEFEED at the end of the line.

	The +3 in the size of the buffer is to account for the
		C_ENTER and C_LINEFEED at the end of a line, that
		makes two more, the one extra is to see if the
		number has more than the allowed DIGITS_IN_BYTES.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetCompressedFileBytes	proc	near
	class	CwordFileBoxClass
buffer	local	(DIGITS_IN_BYTES+3)	dup (char)
	uses	bx,dx,si,di,bp,ds,es
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass
	mov	di, ds:[si]		; instance data pointer

	Assert	fileHandle	ds:[di].CFBI_fileHandle
	mov	bx, ds:[di].CFBI_fileHandle

	; set the file position to the beginning so that we 
	; can read the entire file
	mov	al, FILE_POS_START
	clr	cx, dx
	call	FilePos

	clr	al
	mov	cx, DIGITS_IN_BYTES+3
	segmov	ds, ss, di
	lea	dx, ss:[buffer]			; ds:dx = buffer
	call	FileRead			; ds:dx = filled buffer	
						; ax destroyed
	jc	fileError

	; es:bx will point to the local variable buffer
	segmov	es, ds, ax
	mov	bx, dx
	mov	dh, C_ENTER
	call	StringAsciiConvertToInteger	; ax - num of
						;   compressed bytes
						; bx - updated offset
	jc	finish

	; See if the number of bytes is zero
	tst	ax
	jz	sourceErr

	lea	dx, ss:[buffer]
	sub	bx, dx		; updated - original offset
	inc	bx		; updated - original offset + 1
	mov	cx, bx		; offset into file after initial
				;    number of compressed bytes

	cmp	cx, DIGITS_IN_BYTES+2
	jg	tooManyDigits

	clc
finish:
	.leave
	ret
fileError:
	mov	di, FILE_ERR
errOccured:
	call	CwordHandleError
	jmp	finish
tooManyDigits:
	mov	di, BYTES_TOO_LARGE_ERR
	jmp	errOccured
sourceErr:
	mov	di, SOURCE_ERR
	jmp	errOccured
FileGetCompressedFileBytes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBLoadLastPuzzlePlayed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the last puzzle that was played on the screen.
		This is used when a state file exists when the Cword
		application starts up.

CALLED BY:	MSG_CFB_LOAD_LAST_PUZZLE_PLAYED
PASS:		*ds:si	= CwordFileBoxClass object
		ds:di	= CwordFileBoxClass instance data
		ds:bx	= CwordFileBoxClass object (same as *ds:si)
		es 	= segment of CwordFileBoxClass
		ax	= message #

RETURN:		CF	- set if error occured, clear otherwise
DESTROYED:	
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBLoadLastPuzzlePlayed	method dynamic CwordFileBoxClass, 
					MSG_CFB_LOAD_LAST_PUZZLE_PLAYED
	uses	ax,cx,dx
	.enter

	call	FileOpenUserDocument		; bx - VM file handle
	jc	finish

	; Copy the name of the first puzzle to the Selector Box's
	; instance data.

	; cx:dx - address to copy filename to
	mov	cx, ds
	lea	dx, ds:[di].CFBI_sourceFile
	segmov	es, ds
	lea	di, ds:[di].CFBI_filePath
	call	FileGetNameAndPathOfFirstPuzzle	; cx:dx - filename
	jc	closeAndInitiatePuzzles

	clr	al
	call	VMClose
	jc	vmErr

	; Load the puzzle in CFBI_sourceFile
	call	FileLoadPuzzle
finish:
	pushf
	GetResourceHandleNS	LetsPlayButton, bx
	mov	si, offset LetsPlayButton
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage

	GetResourceHandleNS	OKTipsButton, bx
	mov	si, offset OKTipsButton
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage
	popf
	.leave
	ret
vmErr:
	mov	di, VM_ERR
	call	CwordHandleError
	jmp	finish


closeAndInitiatePuzzles:
	clr	al
	call	VMClose
	mov	ax,MSG_CFB_PUZZLES
	call	ObjCallInstanceNoLock
	jmp	finish

CFBLoadLastPuzzlePlayed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpenSourceDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the source document for the puzzle named in
		the instance data: CFBI_sourceFile with path in
		CFBI_filePath.

CALLED BY:	FILE MODULE INTERNAL	(FileLoadPuzzle)
PASS:		*ds:si	= CwordFileBoxClass object

RETURN:		ax	- file handle of source file
		CF	- set if file error occurred
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpenSourceDocument	proc	near
	class CwordFileBoxClass
	uses	bx,cx,dx,di,si
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass
	mov	di, ds:[si]			; instance ptr

	mov	bx, ds:[di].CFBI_filePath.GFP_disk

	; ds:dx - path specification
	lea	dx, ds:[di].CFBI_filePath.GFP_path
	call	FileSetCurrentPath
	jc	pathErr

	; Set up flags for opening the source file.
	clr	al
	mov	al, FE_DENY_WRITE shl offset FAF_EXCLUDE
	or	al, FA_READ_ONLY shl offset FAF_MODE

	; Set ds:dx to the filename (from the file selector)
	lea	dx, ds:[di].CFBI_sourceFile

	call	FileOpen		; ax - file handle if successful,
					; 	FileError if unsuccessful
	jc	fileErr
	clc
finish:
	.leave
	ret
fileErr:
	mov	di, FILE_ERR
	jmp	errOccurred
pathErr:
	mov	di, PATH_ERR
errOccurred:
	call	CwordHandleError
	jmp	finish

FileOpenSourceDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileParseHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the information in the header and set the
		text in the introduction dialog box.

CALLED BY:	FILE MODULE INTERNAL	(FileLoadPuzzle)
PASS:		*ds:si	- CwordFileBox object
		es:bx	- buffer containing header

RETURN:		ah	- rows
		al	- columns
		bx	- updated buffer offset
		ds	- possiby updated object segment
		CF	- set if error, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileParseHeader	proc	near
	uses	cx,dx,si,bp
	.enter

	mov	dh, C_ENTER
	call	StringAsciiConvertToInteger	; ax - num of header bytes
						; bx - new offset
	jc	finish
	inc	bx			; take care of C_LINEFEED

	; dx:bp - pointer to the text string to display
	mov	dx, es
	mov	bp, bx
	mov	cx, ax				; total header length

	; fix up offset pointer to point to after the header
	add	bx, ax			; new offset after the header 
					; info 
	push	bx			; new buffer offset


	mov	bx, handle CopyrightText
	mov	si, offset CopyrightText
	call	FileChangeIntroText
	jc	popOneErr

	mov	bx, handle TitleText
	mov	si, offset TitleText
	call	FileChangeIntroText
	jc	popOneErr

	mov	bx, handle AuthorText
	mov	si, offset AuthorText
	call	FileChangeIntroText
	jc	popOneErr

	mov	bx, handle SourceText
	mov	si, offset SourceText
	call	FileChangeIntroText
	jc	popOneErr

	mov	bx, handle RatingText
	mov	si, offset RatingText
	call	FileChangeIntroText
	jc	popOneErr

	push	cx, dx			; total header bytes, buffer segment

	; Get the number of rows and columns for the return value

	mov	bx, bp			; buffer offset to beginning
					; of grid size

	mov	dh, C_SMALL_X
	call	StringAsciiConvertToInteger	; ax - rows
	jc	popTwoErr
	push	ax				; rows
	mov	dh, C_ENTER
	call	StringAsciiConvertToInteger	; ax - columns
	pop	cx				; rows
	jc	popTwoErr

	mov	ah, cl				; ah - rows, al - columns
	
	pop	cx, dx			; total header bytes, buffer segment

	mov	bx, handle SizeText
	mov	si, offset SizeText
	call	FileChangeIntroText
	jc	popOneErr

	pop	bx				; new buffer offset
	clc
finish:
	.leave
	ret
popTwoErr:
	pop	cx, dx
	jmp	finish
popOneErr:
	pop	bx
	jmp	finish
FileParseHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileChangeIntroText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the text of a certain category within the
		Introduction Dialog box.

CALLED BY:	FILE MODULE INTERNAL	(FileParseHeader)
PASS:		ds	- CwordFileBox segment
		bx	- handle of text object
		si	- offset of text object
		dx:bp	- string to display
		cx	- total header length

RETURN:		bp	- offset into string, pointing at beginning of
				next string
		ds	- possibly updated object segment
		CF	- set if error, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Count the number of characters in the string that's currently 
	pointed at.  Replace the text of the given object until a
	C_ENTER is reached.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileChangeIntroText	proc	near
	uses	ax,cx,di,es
	.enter

	; count how many bytes in copyright string
	; es:di - the string
	mov	al, C_ENTER
	mov	es, dx
	mov	di, bp
	repne	scasb			
		; es:di - buffer pointing to char after C_ENTER
	jnz	sourceErr

	push	dx, di			; end of displayed string

	sub	di, bp			; di - number of bytes to display
	mov	cx, di			; number of bytes to display
	dec	cx			; subtract one byte for the C_ENTER
	jcxz	afterText		; if no text, do nothing!

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		
afterText:
	pop	dx, bp			; end of displayed string
	inc	bp			; point to after the C_LINEFEED
					; ie. the beginning of next string
	clc
finish:
	.leave
	ret
sourceErr:
	mov	di, SOURCE_ERR
	call	CwordHandleError
	jmp	finish
FileChangeIntroText	endp


if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDisplayIntro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the IntroInteraction dialog box that has the
		puzzle header information.

CALLED BY:	FILE MODULE INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDisplayIntro	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	bx, handle IntroInteraction	; single-launchable
	mov	si, offset IntroInteraction
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	.leave
	ret
FileDisplayIntro	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDismissIntro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dismiss the IntroInteraction dialog box that has the
		puzzle header information.

CALLED BY:	FILE MODULE INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDismissIntro	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	bx, handle IntroInteraction	; single-launchable
	mov	si, offset IntroInteraction
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjMessage

	.leave
	ret
FileDismissIntro	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReadSourceDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Manage the reading in of the source document and
		handing pieces of data to the Engine for initialization.

CALLED BY:	FILE MODULE INTERNAL	(FileLoadPuzzle)
PASS:		es:bx	- buffer to read from
		ah	- rows
		al	- columns

RETURN:		bx 	- updated offset
		dx	- engine token
		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Read the entire file into one buffer and pass appropriate
	pointers into the buffer for initialization to the Engine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileReadSourceDocument	proc	near
	uses	ax,bx,cx,di,ds,es
	.enter

EC <	; initialize some dgroup EC global vars				>
EC <	push	es							>
EC <	push	ax							>
EC <	LoadVarSeg	es, ax			; single-launchable	>
EC <	pop	ax							>
EC <	mov	es:[ECnumCol], al					>
EC <	mov	es:[ECnumRow], ah					>
EC <	pop	es							>

	call	EngineCreateEngineToken		; dx = engine token

	jc	errOccurred

	push	dx				; engine token
	mov	dh, C_ENTER
	call	StringAsciiConvertToInteger	; ax = soln letter bytes
						; bx = new buffer offset
	jc	errOccurred
	inc	bx				; get rid of C_LINEFEED
	pop	dx				; engine token

	call	EngineSetSolutionLetters	; bx = new buffer offset
	jc	errOccurred

	call	EngineNotificationCluesToFollow	
	jc	errOccurred

	call	FileGetNumberClueBytes		; ax = bytes,
						; bx = new buffer offset
	jc	errOccurred
	call	EngineSetAcrossClues		; bx = new buffer offset
	jc	errOccurred

	call	FileGetNumberClueBytes		; ax = bytes, 
						; bx = new buffer offset
	jc	errOccurred
	call	EngineSetDownClues		; bx = new buffer offset
	jc	errOccurred

EC <	call	ECSetClueCountsInDgroup					>
	call	EngineNotificationCluesDone
	clc
finish:
	.leave
	ret
errOccurred:
	stc
	jmp	finish

FileReadSourceDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileUncompressAndReadToESBX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a buffer and read the entire file into it.
		The file is specified by the file handle passed in.

CALLED BY:	FILE MODULE INTERNAL	(FileLoadPuzzle)

PASS:		*ds:si	- CwordFileBox object
		ax	- number of compressed bytes
		cx	- offset into file after initial number of
				compressed bytes.		

RETURN:		es:bx	- filled buffer
		cx	- buffer handle
		CF	- set if error, clear otherwise

DESTROYED:	bx used for return value
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileUncompressAndReadToESBX	proc	near
fileOffset		local	word	push	cx
bytesToRead		local	word
bufferHandle		local	word
destBufferSegment	local	word
sizeDecompBuffer	local	word
	class	CwordFileBoxClass
	uses	ax,dx,si,di,ds
	.enter	

	Assert	objectPtr	dssi, CwordFileBoxClass

	; Read the compressed bytes to a buffer so that the
	; uncompress code will only uncompress the data that I 
	; want it to.
	
	mov	ss:[bytesToRead], ax
	mov	di, ds:[si]		; instance data pointer

	Assert	fileHandle	ds:[di].CFBI_fileHandle
	mov	bx, ds:[di].CFBI_fileHandle

 	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			; bx = handle to block
						; ax = address of block
						; carry set if error
	LONG jc	memError

	mov	ss:[bufferHandle], bx		; save block handle
	mov	bx, ds:[di].CFBI_fileHandle

	mov	ds, ax				; ds = address of
						; buffer's block

	; set the file position relative to the beginning 
	mov	al, FILE_POS_START
	mov	dx, ss:[fileOffset]		; offset to read from
	clr	cx
	call	FilePos

	; Read the file's content into the buffer allocated.

	clr	al
	mov	cx, ss:[bytesToRead]
	clr	dx				; ds:dx = buffer
	call	FileRead			; ds:dx = filled buffer	
	jc	fileError

	; Decompress the contents of the first buffer into a second 
	; buffer.
	mov	ax, cx				; number compressed bytes
	shl	ax				; number compressed
	add	ax, cx				; 	bytes * 3
	mov	ss:[sizeDecompBuffer], ax
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			; bx = handle to dest
						; 	block
						; ax = address of block
	jc	memError2

	mov	ss:[destBufferSegment], ax
	mov	cx, CL_DECOMP_BUFFER_TO_BUFFER
	push	cx
	push	ds:[di].CFBI_fileHandle
	push	ds, dx				; source buffer
	push	ss:[bytesToRead]
	clr	cx				; dest file handle
	push	cx
	push	ax, cx				; dest buffer address
	call	CompressDecompress	

EC <	cmp	ax, ss:[sizeDecompBuffer]				>
EC <	ERROR_GE	FILE_DECOMPRESS_BUFFER_TOO_SMALL	>
	
	mov	cx, bx				; decompressed block
						; handle

	; Free the block containing the compressed data
	mov	bx, ss:[bufferHandle]		; compressed block handle
	call	MemFree
	
	; Set es:bx = buffer
	mov	ax, ss:[destBufferSegment]
	mov	es, ax
	clr	bx

	clc
finish:
	.leave
	ret
memError2:
	mov	bx, ss:[bufferHandle]
	Assert	handle	bx
	call	MemFree
memError:
	mov	di, MEM_ERR
errorOccurred:
	call	CwordHandleError
	jmp	finish
fileError:
	mov	di, FILE_ERR
	mov	bx, ss:[bufferHandle]
	Assert	handle	bx
	call	MemFree
	jmp	errorOccurred

FileUncompressAndReadToESBX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetNumberClueBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a string of characters, pull out and translate
		the ascii number on the first line to a number.

CALLED BY:	FileReadSourceDocument
PASS:		es:bx	- points to the place in the buffer where to
			  start reading the ascii numbers from.  For 
			  the entire format of the source file, see
			  the Technical Specification.

RETURN:		ax	- number of clue bytes
		bx	- updated offset into buffer to point to byte
			  following the line with the number of clue
			  bytes is reached.
		CF	- set if error, clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetNumberClueBytes	proc	near
	uses	dx
	.enter

	mov	dh, C_ENTER
	call	StringAsciiConvertToInteger
	jc	finish

	; fix up di to point to beginning of new line, one byte past
	; the C_LINEFEED
	inc	bx
	clc
finish:
	.leave
	ret
FileGetNumberClueBytes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWriteUserDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the user solution of the current puzzle
		to the VM user solution document.

CALLED BY:	
PASS:		*ds:si	= CwordFileBoxClass object

RETURN:		CF	- set if error, clear otherwise
		ds	- updated

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileWriteUserDocument	proc	near
	class CwordFileBoxClass
	uses	ax,bx,cx,dx,si,di
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass

	; There must be a puzzle currently in play in order
	; to save it to the user document.
	Assert	e	ds:[di].CFBI_puzzleIsOpen, TRUE

	call	FileOpenUserDocument	; bx - VM file handle
	jc	finish

	; the currently opened puzzle is the first element in the
	; map block of the VM file because when the puzzle was 
	; first read in, the element for the puzzle was either moved
	; to the front or created and put in the front.

	call	FileGetBlockHandleOfFirstPuzzle	; ax - puzzle handle

	mov	di, ds:[si]			; instance pointer
	mov	dx, ds:[di].CFBI_engine
	mov	cx, USED_PUZZLE
	call	FileWriteActualUserData		; ds - updated
	jc	errOccurred

	clr	al
	call	VMClose
	jc	vmErr
	clc
finish:	
	.leave 
	ret

errOccurred:
	clr	al
	call	VMClose
	jc	vmErr
	stc
	jmp	finish
vmErr:
	mov	di, VM_ERR
	call	CwordHandleError
	jmp	finish
FileWriteUserDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWriteActualUserData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the puzzle is USED, actually call to the different
		modules and get the user solution data in the VM
		block. If the puzzle is NEW, write default data to
		the VM block.

CALLED BY:	FILE MODULE INTERNAL
		(FileWriteUserDocument and FileCreateNewPuzzleData)

PASS:		ax	- VM block handle for puzzle
		bx	- VM file handle
		cx	- NEW_PUZZLE, if this is the initial saving of
					the user data
			  USED_PUZZLE, if this puzzle has been played on
		dx	- engine token
		ds	- map block ordered puzzle data segmento

RETURN:		CF	- set if error, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Lock the VM block.
	Pass the pointer into the block to the engine so that it can
	   write the cell data in the format:
	   <solution letter> <cell flags> <solution letter> <cell flags>
	   etc.
	Write the selected word data to the VM block:
		<direction of selected word>
		<number of first cell in selected word>
	Write the offset of the selected cell within the selected word
		to the user document.  (offset starts at 0)
	Write the number of the selected across clue to the user
		document.
	Write the number of the selected down clue to the user
		document.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileWriteActualUserData	proc	near
	uses	ax,bp,es
	.enter

	call	VMLock			; ax - segment, bp - memory handle
	push	bp			; memory handle

	mov	es, ax			; segment
	clr	bp
	
	; the Engine will be able to write directly to the VM 
	; block in es:bp
	
	call	EngineWriteCellData

	; if NEW_PUZZLE, just write the defaults as the selected
	; word and cell, otherwise get the real data.

	cmp	cx, NEW_PUZZLE
	je	newPuzzle

	call	FileWriteSelectedWordAndCellData

	; Now write the number of the selected across and 
	; down clues to the user document.
	
	call	FileWriteSelectedClueData
	jmp	selectedDone

newPuzzle:
	call	FileWriteSelectedWordCellClueDataDefault

selectedDone:
	pop	bp			; memory handle
	call	VMDirty
	call	VMUpdate		; save changes
	jc	vmErr

	call	VMUnlock
	clc
finish:
	.leave
	ret
vmErr:
	call	VMUnlock
	mov	di, VM_ERR
	call	CwordHandleError
	jmp	finish
FileWriteActualUserData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWriteSelectedClueData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the selected clue data to the user document.

CALLED BY:	FileWriteActualUserData
PASS:		es:bp	- VM user document block pointer
		dx	- engine token
		ds	- map block ordered puzzle data segment

RETURN:		bp	- new pointer offset
		ds	- possibly updated
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Ask the Board Module for the across selected clue token.
		Get the number for this clue and write that number to
		the user document.
	Do the same for the down selected clue.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileWriteSelectedClueData	proc	near
	uses	ax,bx,si,di
	.enter

	; Get the selected across clue token

	mov	bx, handle Board		; single-launchable
	mov	si, offset Board
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_BOARD_GET_SELECTED_ACROSS_CLUE_TOKEN
	call	ObjMessage			; ax - clue token

	; Find the number of that clue.
	
	mov	bx, ACROSS
	call	EngineMapClueTokenToClueNumber	; al - clue number
	mov	{byte}es:[bp], al
	inc	bp

	; Get the selected down clue token

	mov	bx, handle Board		; single-launchable
	mov	si, offset Board
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_BOARD_GET_SELECTED_DOWN_CLUE_TOKEN
	call	ObjMessage			; ax - clue token

	; Find the number of that clue.

	mov	bx, DOWN
	call	EngineMapClueTokenToClueNumber	; al - clue number
	mov	{byte}es:[bp], al
	inc	bp

	.leave
	ret
FileWriteSelectedClueData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWriteSelectedWordCellClueDataDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the default values for selected word, cell, and
		clues into the vm user doc.

CALLED BY:	FileWriteActualUserData
PASS:		es:bp	- buffer to write selections in
		dx	- engine token

RETURN:		bp	- new buffer offset
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Defaults:	The selected word's direction will be across.
			The number of the first cell in the selected
				word will be the number of the first
				existent non-hole cell.
			The selected cell will be the first existent
				non-hole cell.
			The offset of the selected cell within the 
				selected word will be zero.
			The number of the selected clues will be the 
				same as the selected cell.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileWriteSelectedWordCellClueDataDefault	proc	near
	uses	ax,cx
	.enter

	; Put the default direction into the user doc
	;
	mov	{byte} es:[bp], ACROSS
	inc	bp

	push	bp			; VM file buffer offset

	; Find the number of the first existing non-hole cell and
	; use that number for the number of the first cell in the
	; selected word.
	;
	call	EngineGetFirstExistentNonHoleCell	; bp - cell token
	mov	ax, bp					; cell token
	call	EngineGetCellNumberFAR			; cl - number

	Assert	ne	cl, ENGINE_NO_NUMBER

	pop	bp			; VM file buffer offset	
	mov	{byte} es:[bp], cl	; number in first cell of
					; selected word
	inc	bp
	clr	{byte}es:[bp]		; offset of selected cell
	inc	bp

	; Write the numbers of the selected clues.
	;
	mov	{byte} es:[bp], cl	; number of selected across clue
	inc	bp
	mov	{byte} es:[bp], cl	; number of selected down clue
	inc	bp

	.leave
	ret
FileWriteSelectedWordCellClueDataDefault	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWriteSelectedWordAndCellData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the selected word and cell data to the VM user
		document in this format: 
		word:	current direction, number in first cell
		cell:	offset of square in selected word - starting
			at zero.

CALLED BY:	FileWriteActualUserData

PASS:		dx	- engine token
		es:bp	- VM file buffer to write to.
		ds	- CwordFileBox segment

RETURN:		bp	- new offset to buffer, points to next empty
			  byte after the last byte that was written in.
		ds	- possibly updated

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileWriteSelectedWordAndCellData	proc	near
	uses	ax,bx,cx,si,di
	.enter

	push	dx				; engine token
	mov	bx, handle Board		; single-launchable
	mov	si, offset Board
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_BOARD_GET_SELECTED_WORD
	call	ObjMessage	
		; ax - selected cell token, dx - direction

	Assert	e	dh, 0
	mov	{byte} es:[bp], dl	; save the direction to userdoc
	inc	bp
	
	mov	cx, dx				; direction
	pop	dx				; engine token
	push	cx				; direction

	; Get the number in the first cell of the selected word.
	; First get the first cell and then ask for the number.
	;
	call	EngineGetFirstAndLastCellsInWordFAR	; ax - first
							; bx - last
	call	EngineGetCellNumberFAR			; cl - number

	Assert	ne	cl, ENGINE_NO_NUMBER	; cell should have a number
	mov	{byte}es:[bp], cl	; save number in first cell
					; of selected word to userdoc
	inc	bp				; new buffer offset

	pop	cx				; direction
	
	; Now store data about the selected cell.  Since the selected
	; cell is within the selected word, store the offset of the
	; selected cell in the selected word starting at 0.
	;
	call	EngineGetOffsetOfSelectedCellInSelectedWord	; al - offset
	mov	{byte} es:[bp], al		; offset of selected
						; cell token within
						; selected word
	inc	bp

	.leave
	ret
FileWriteSelectedWordAndCellData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMoveElementToFront
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the Given element in the chunk array to the
		front.

CALLED BY:	FileWriteUserDocument
PASS:		*ds:si	- map block array
		ax	- element number to move to front

RETURN:		ax	- VM block handle for puzzle data
		ds	- segment pointer for chunk array (might have
				 been updated by ChunkArrayInsertAt)
		CF 	- set if error occured, clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Copy the element to the puzzleBuffer.
	Delete the element withing the map block's chunk array.
	Insert a new element to the front of the chunk array.
	Copy the puzzleBuffer to the new element.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileMoveElementToFront	proc	near
puzzleBuffer	local	PuzzleData
	uses	bx,cx,dx,di,si,es
	.enter

EC <	call	ECCheckChunkArray					>

	; If the element number is 0, no need to move it - just retrieve
	; its VM block handle 
	tst	ax
	jz	firstElem

	; copy the contents of the puzzle data to the buffer
	push	ax				; element number
	; cx:dx = buffer for element
	mov	cx, ss
	lea	dx, ss:[puzzleBuffer]
	call	ChunkArrayGetElement		; ax - element size

	; delete the original element in the pointer
	pop	ax				; element number
	call	ChunkArrayElementToPtr		; ds:di	- element
	call	ChunkArrayDelete

	; insert the PuzzleData buffer to the front of the chunk array
	clr	ax
	call	ChunkArrayElementToPtr		; ds:di - element to
						; 	insert before
	call	ChunkArrayInsertAt		; ds:di - new element
	jc	memErr

	; initialize the PuzzleData in the chunk array with the
	; buffer information.

	; copy the puzzle name to the new element
	; set up arguments for movs{b,w}
	; ds:si = puzzle name, es:di = place in new element to copy to

	push	di, ds

	segmov	es, ds, cx
	segmov	ds, ss, cx
	lea	si, ds:[puzzleBuffer].PD_puzzleName
	lea	di, es:[di].PD_puzzleName
	
	mov	cx, FILE_LONGNAME_BUFFER_SIZE
	shr	cx
	jnc	evenNum
	movsb
evenNum:
	rep	movsw

	pop	di, ds

	mov	ax, ss:[puzzleBuffer].PD_puzzleHandle
	mov	ds:[di].PD_puzzleHandle, ax

; If the New path will ALWAYS be set right after this call,
; the path can be left unset for now.

	clc
finish:	
	.leave
	ret

firstElem:
	call	ChunkArrayElementToPtr		; ds:di - element
	mov	ax, ds:[di].PD_puzzleHandle
	clc
	jmp	finish
memErr:
	mov	di, MEM_ERR
	call	CwordHandleError
	jmp	finish

FileMoveElementToFront	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSetNewPathInFirstElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current path of the source file selected into
		the new puzzle data element.

CALLED BY:	FileWriteUserDocument
PASS:		*ds:si	- map block array

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	The puzzle's source file may have changed paths, but we
	assume that source filename's are unique.  So just update
	the path to be the current one.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSetNewPathInFirstElement	proc	near
	uses	ax,bx,dx,si,di,bp
	.enter

EC <	call	ECCheckChunkArray				>

	clr	ax				; first element
	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	mov	dx, ds
	lea	bp, ds:[di].PD_filePath

	mov	bx, handle SelectorBox		; single-launchable
	mov	si, offset SelectorBox
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CFB_GET_SOURCE_FILE_PATH
	call	ObjMessage

	.leave
	ret
FileSetNewPathInFirstElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCreateNewPuzzleData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new PuzzleData element in the front of the
		chunk array and initialize its data.

CALLED BY:	FileGetUserDocPuzzleBlockHandle

PASS:		*ds:si	- array
		bx	- vm file handle
		dx	- engine token
		*es:di 	- CwordFileBox object
		
RETURN:		ax	- VM block handle for puzzle
		ds	- segment pointer (might have been updated by
				ChunkArrayInsertAt)
		CF 	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCreateNewPuzzleData	proc	near
	class	CwordFileBoxClass
	uses	cx,di,si
	.enter	

EC <	call	ECCheckChunkArray					>

	mov	cx, di			; CwordFileBox chunk handle
	call	FileDeleteLastPuzzleIfTooManyPuzzles

	; insert an empty PuzzleData buffer to the front of 
	; the chunk array
	;
	clr	ax
	call	ChunkArrayElementToPtr		; ds:di - element to
						; 	insert before
	call	ChunkArrayInsertAt		; ds:di - new element
	jc	memErr

	mov	si, cx				; CwordFileBox chunk handle
	call	FileSetPathInNewElement
	call	FileCopyPuzzleNameToNewElement

	; allocate a new block for the puzzle and record its block
	; handle in the new element.

	clr	ax
	mov	cx, VM_BLOCK_SIZE
	call	VMAlloc				; ax - VM block handle

	mov	ds:[di].PD_puzzleHandle, ax
	mov	cx, NEW_PUZZLE
	call	FileWriteActualUserData		; sets the CF if error
finish:
	.leave
	ret
memErr:
	mov	di, MEM_ERR
	call	CwordHandleError
	jmp	finish

FileCreateNewPuzzleData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDeleteLastPuzzleIfTooManyPuzzles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A new PuzzleData is about to be added to the ordered
		puzzle data chunk array within the map block.  If
		there are more than MAX_NUM_SAVED_PUZZLES in the
		array, then the puzzle solution of the least recently
		played puzzle is deleted without any warning to the
		user.

CALLED BY:	FileCreateNewPuzzleData

PASS:		*ds:si	- array
		bx	- vm file handle

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	The least recently played puzzle is the last element in the
	chunk array since everytime a puzzle is played, it's position
	in the ordered puzzle chunk array moves to the front.  So this
	procedure just deletes the last PuzzleData element if there 
	are too many of them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDeleteLastPuzzleIfTooManyPuzzles	proc	near
	uses	ax,cx,di
	.enter

EC <	call	ECCheckChunkArray					>

	call	ChunkArrayGetCount		; cx - number of elements
	cmp	cx, MAX_NUM_SAVED_PUZZLES
	jl	countOk
	
	; There are MAX_NUM_SAVED_PUZZLES puzzles in the VM user
	; document, remove any puzzles after and including element
	; MAX_NUM_SAVED_PUZZLES
	
EC <	Assert	e	cx, MAX_NUM_SAVED_PUZZLES			>
	mov	ax, MAX_NUM_SAVED_PUZZLES
	dec	ax		; remove element starting at
				; the MAX_NUM_SAVED_PUZZLES element
				; which has en element number of 
				; MAX_NUM_SAVED_PUZZLES-1
	call	FileDeletePuzzleFromMainArray

countOk:
	.leave
	ret
FileDeleteLastPuzzleIfTooManyPuzzles	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDeletePuzzleFromMainArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the chunk array element and vm block associated
		with the passed element

CALLED BY:	FileDeleteLastPuzzleIfTooManyPuzzles
		CFBRemovePuzzleFromMainArray
	
PASS:		
		*ds:si - main chunk array
		ax - element number
		bx - VM file handle

RETURN:		

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDeletePuzzleFromMainArray		proc	near
	uses	ax,di
	.enter

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS
	mov	ax, ds:[di].PD_puzzleHandle
	call	VMFree
	call	ChunkArrayDelete
	call	VMUpdate

	.leave
	ret
FileDeletePuzzleFromMainArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyPuzzleNameToNewElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the source file name in the CwordFileBox instance
		data to the new PuzzleData element.

CALLED BY:	FileCreateNewPuzzleData
PASS:		ds:di	- new PuzzleData element
		*es:si	- CwordFileBox object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCopyPuzzleNameToNewElement	proc	near
	class	CwordFileBoxClass
	uses	cx,si,di,ds,es
	.enter	

	; copy the puzzle name to the new element
	; set up arguments for movs{b,w}
	; ds:si = puzzle name, es:di = place in new element to copy to
	; 

	segxchg	ds, es, cx
		; ds - CwordFileBox segment, es - map block segment
	lea	di, es:[di].PD_puzzleName

	mov	si, ds:[si]			; instance ptr
	lea	si, ds:[si].CFBI_sourceFile
	
	mov	cx, FILE_LONGNAME_BUFFER_SIZE
	shr	cx
	jnc	evenNum
	movsb
evenNum:
	rep	movsw

	.leave
	ret
FileCopyPuzzleNameToNewElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSetPathInNewElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the path of the selected file in the PuzzleData
		element and set the current path to the same path.

CALLED BY:	FileCreateNewPuzzleData
PASS:		ds:di	- new PuzzleData element
		*es:si	- CwordFileBox object
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSetPathInNewElement	proc	near
	uses	ax,dx,ds,es,bp
	.enter

	Assert	objectPtr	essi, CwordFileBoxClass

	; Setup es:di to be the puzzle data path
	segxchg	es, ds
		; es - puzzle data segment
		; ds - CwordFileBox segment

	mov	dx, es
	lea	bp, es:[di].PD_filePath
	mov	ax, MSG_CFB_GET_SOURCE_FILE_PATH
	call	ObjCallInstanceNoLock

	.leave
	ret
FileSetPathInNewElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBGetSourceFilePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the file path from the instance data to the 
		buffer provided.

CALLED BY:	MSG_CFB_GET_SOURCE_FILE_PATH
PASS:		*ds:si	= CwordFileBoxClass object
		ds:di	= CwordFileBoxClass instance data
		ds:bx	= CwordFileBoxClass object (same as *ds:si)
		es 	= segment of CwordFileBoxClass
		ax	= message #
		dx:bp	- buffer of GenFilePath to fill

RETURN:		filled buffer
DESTROYED:	
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBGetSourceFilePath	method dynamic CwordFileBoxClass, 
					MSG_CFB_GET_SOURCE_FILE_PATH
	uses	ax, cx, es
	.enter

	mov	es, dx				; buffer segment
	mov	ax, ds:[di].CFBI_filePath.GFP_disk
	mov	es:[bp].GFP_disk, ax

	; ds:si - path to copy from instance data
	lea	si, ds:[di].CFBI_filePath.GFP_path

	; es:di - path buffer to fill
	lea 	di, es:[bp].GFP_path

	mov	cx, PATH_BUFFER_SIZE
	shr	cx
	jnc	evenNum
	movsb
evenNum:
	rep	movsw

	.leave
	ret
CFBGetSourceFilePath	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileFindPuzzleCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the puzzle block handle matching the puzzle
		file name given.

CALLED BY:	ChunkArrayEnum from FileWriteUserDocument

PASS:		es:dx	- puzzle name to look for
		*ds:si	- array
		ds:di	- array element being enumerated

RETURN:		CF	- set if puzzle found, clear otherwise.
		cx	- TRUE if puzzle match found,
			  FALSE otherwise.
		ax	- element number of found puzzle name
			  if CX = TRUE.  Otherwise ax is meaningless.

DESTROYED:	ax is trashed if and only if cx == FALSE.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	procedure is a far because it is a callback.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileFindPuzzleCallback	proc	far
	.enter

EC <	call	ECCheckChunkArray					>

	push	si, di			; array pointer, element pointer

	; ds:si	- puzzle name for this array element
	;
	lea	si, ds:[di].PD_puzzleName

	; es:di - puzzle name (file name) to look for
	;
	mov	di, dx			; es:di - puzzle name to look for
	clr	cx			; compare till NULL terminated
	call	LocalCmpStrings
	jz	found
	; puzzle names don't match
	pop	si, di			; array pointer, element pointer
	mov	cx, FALSE
	clc
finish:
	.leave
	ret
found:
	pop	si, di			; array pointer, element pointer
EC <	call	ECCheckChunkArray					>
	call	ChunkArrayPtrToElement		; ax - element
	mov	cx, TRUE
	stc
	jmp	finish
FileFindPuzzleCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpenUserDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the user solution VM file.  If it does not exist,
		create the file and initialize the map block with
		ordered puzzle data.

CALLED BY:	FILE MODULE INTERNAL (FileReadUserDocument)
PASS:		none
RETURN:		bx	- VM file handle
		CF	- set if error, clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpenUserDocument	proc	near
protocolNum	local	ProtocolNumber
	uses	ax,cx,dx,di,ds,es
	.enter

	call	FilePushDir
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath

	;
	; make ds:dx the file name to open
	; First try to open the existing file, if it does not exist,
	; then create and initialize it properly.
	;
	mov	bx, handle CwordStrings		; single-launchable
	call	MemLock				; ax - segment
	mov	ds, ax
	mov	dx, ds:[USER_DOC_NAME]
	mov	ah, VMO_OPEN
	mov	al, mask VMAF_FORCE_READ_WRITE
	clr	cx
	call	VMOpen				; bx - file handle
						; ax - VMStatus
	jnc	success

	; an error occurred.  If file does not already exist, it
	; will be created and its map block initialized.
	
	cmp	ax, VM_FILE_NOT_FOUND
	jne	fileErr

createUserDoc:
	mov	ah, VMO_CREATE_ONLY
	mov	al, mask VMAF_FORCE_READ_WRITE
	call	VMOpen				; bx - VM file handle

	jc	fileErr

	cmp	ax, VM_CREATE_OK
	jne	fileErr

	; The file is successfully created.  A VM block must be
	; allocated for the MapBlock and must be initialized with
	; puzzle information.
	
	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, size VMUserBlockHeader
	call	VMAllocLMem		; ax - VM block handle
					; lmem heap space - 64 bytes
	call	FileInitializeMapBlock
	jc	finish
	call	VMSetMapBlock

	; Set the Protocol number for this newly created user document

	mov	ss:[protocolNum].PN_major, USER_DOC_PROTOCOL_MAJOR
	mov	ss:[protocolNum].PN_minor, USER_DOC_PROTOCOL_MINOR
	mov	ax, FEA_PROTOCOL
	segmov	es, ss
	lea	di, ss:[protocolNum]
	mov	cx, size ProtocolNumber
	call	FileSetHandleExtAttributes
EC <	ERROR_C	FILE_CANNOT_SET_USER_PROTOCOL		>
	jmp	finish

success:
	; Get the protocol number of this user document and
	; check to see if it is valid.  
	; + If the doc's numbers are greater than the protocol
	;	 of this application, exit
	; + If the doc's numbers are lower than the protocol of
	; 	 this application, delete the user doc and
	; 	 make a new one.

	mov	ax, FEA_PROTOCOL
	segmov	es, ss
	lea	di, ss:[protocolNum]
	mov	cx, size ProtocolNumber
	call	FileGetHandleExtAttributes
	jc	badProtAttrs

	cmp	ss:[protocolNum].PN_major, USER_DOC_PROTOCOL_MAJOR
	jg	exitErr
	jl	badProtAttrs

	cmp	ss:[protocolNum].PN_minor, USER_DOC_PROTOCOL_MINOR
	jg	exitErr
	jl	badProtAttrs

	clc
finish:
	pushf
	call	FilePopDir
	popf

	.leave
	ret
fileErr:
	; couldn't create user document
	mov	di, CREATE_VM_ERR
	call	CwordHandleError
	jmp	finish

badProtAttrs:
		; ds:dx = filename
	clr	al
	call	VMClose
EC <	ERROR_C	FILE_CANNOT_CLOSE_USER_DOC			>
	call	FileDelete
EC <	ERROR_C	FILE_CANNOT_DELETE_USER_DOC			>
	mov	di, USER_PROT_ERR
	push	dx				; filename offset
	mov	dx, WARN_N_CONT
	call	CwordPopUpDialogBox
	pop	dx				; filename offset
	jmp	createUserDoc
exitErr:
	clr	al
	call	VMClose
EC <	ERROR_C	FILE_CANNOT_CLOSE_USER_DOC			>
	mov	di, UPGRADE_ERR
	mov	dx, WARN_N_CONT
	call	CwordPopUpDialogBox
	call	CwordExit
	stc
	jmp	finish
FileOpenUserDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileInitializeMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a chunk array of PuzzleData in the map block.

CALLED BY:	FileOpenUserDocument
PASS:		ax	- VM block handle
		bx	- VM file handle
RETURN:		CF	- set if error, clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the *VM* LMem block, moving
		  it on the heap and invalidating stored segment
		  pointers and current register or stored offsets to it.

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileInitializeMapBlock	proc	near
	uses	ax,bx,cx,si,bp,ds
	.enter

	call	VMLock		; ax - segment of locked VM block
				; bp - memory handle of locked VM block

	; Create the Chunk Array in the map block which will store the
	; information about puzzles in the VM file.

	mov	ds, ax			; segment of VM block
	mov	bx, size PuzzleData	; element size
	clr	cx, si
	clr	al
	call	ChunkArrayCreate	; *ds:si = array (block
					; 	possible moved)
	jc	chunkErrorDialog

	mov	ds:[VMUBH_orderedPuzzleChunkHandle], si
			; bp - memory handle of locked VM block

	; Create variable sized element array for holding names of
	; completed but not deleted puzzles

	clr	al
	clr	bx,si,cx
	call	ChunkArrayCreate
	mov	ds:[VMUBH_completedPuzzleChunkHandle], si

	call	VMDirty
	call	VMUnlock
	clc	
finish:
	.leave
	ret

chunkErrorDialog:
		; bp - memory handle of locked VM block
	call	VMUnlock
	mov	di, CHUNK_ARRAY_ERR
	call	CwordHandleError
	jmp	finish

FileInitializeMapBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReadUserDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the User document for the file named in
		CFBI_sourceFile.  Initialize the Engine and Board
		with the new data.

CALLED BY:	FILE MODULE INTERNAL	(FileLoadPuzzle)
PASS:		*ds:si	- CwordFileBoxClass object
		dx	- engine token

RETURN:		ds	- possibly updated CwordFileBox segment
		CF	- set if error, clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	If the user document for the puzzle named in the
		instance data CFBI_sourceFile exists, then 
		read in its data,
	else create new default data for it and write that
		to the user document.
	Give the Engine module the user data. 
	Tell the Board module to initialize itself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileReadUserDocument	proc	near
memHandle		local	word
vmFileHandle		local	word
boardInitData		local	BoardInitializeData
	class CwordFileBoxClass
	uses	ax,bx,dx,si,di
	.enter
	
	ForceRef	memHandle
	Assert	objectPtr	dssi, CwordFileBoxClass

	; Place the engine token within the boardInitData
	mov	ax, dx
	mov	ss:[boardInitData].BID_engine, ax

	call	FileOpenUserDocument		; bx - VM file handle
	LONG jc	finish
	mov	ss:[vmFileHandle], bx

	call	FileGetUserDocPuzzleBlockHandle	; ax - puzzle block handle
	jc	errOccurred

	call	FileGiveDataToEngine

	clr	al
	call	VMClose
	jc	vmErr

	; Tell the Board Module to initialize itself
	push	bp				; locals pointer
	lea	bp, ss:[boardInitData]
	mov	dx, size BoardInitializeData
	mov	bx, handle Board		; single-launchable
	mov	si, offset Board
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	mov	ax, MSG_CWORD_BOARD_INITIALIZE_BOARD
	call	ObjMessage
	pop	bp				; locals pointer
	cmp	ax, IRV_FAILURE
	je	initFailed

	clc
finish:
	.leave
	ret

errOccurred:
	clr	al
	call	VMClose
	jnc	setCarry
vmErr:
	mov	di, VM_ERR
	call	CwordHandleError
	jmp	finish

initFailed:
	mov	di, CWORD_INIT_FAILED_ERR
	call	CwordHandleError
setCarry:
	stc
	jmp	finish

FileReadUserDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetUserDocPuzzleBlockHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the block handle of the puzzle's user document
		within the user document VM file.

CALLED BY:	FILE MODULE INTERNAL	(FileReadUserDocument)
PASS:		*ds:si	- CwordFileBoxClass object
		bx	- VM file handle
		dx	- engine token

RETURN:		ax	- puzzle block handle
		CF	- set if error, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	If the puzzle has a user document in the VM file, move its
		PuzzleData to the front of the map block.
	Else create new default data in the user document for the
		never-previously-played puzzle and write it to the
		front of the map block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetUserDocPuzzleBlockHandle	proc	near
vmFileHandle		local	word	push	bx
objectChunkHandle	local	word	push	si
mapBlockMemoryHandle	local	hptr
	uses	cx,si,di,bp,ds,es
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass

	push	bp				; locals pointer
	call	FileFindPuzzleInMapBlock
	call	FileLockMapBlockAndMainArray

		; cx 	- TRUE or FALSE if match was found.
		; ax 	- element of puzzle in map block IF found,
		;		trashed otherwise
		;*ds:si - map block ordered puzzle array
		; es 	- CwordFileBox segment
		; bp - map block memory handle


	mov	bx, bp				; map block memory handle
	pop	bp				; locals pointer
	mov	ss:[mapBlockMemoryHandle], bx
	mov	bx, ss:[vmFileHandle]		; restore bx to VM file handle

	cmp	cx, TRUE
	jne	notFound

	call	FileMoveElementToFront		; ax - puzzle block handle
						; ds - possibly updated
						;      segment pointer to
						;      the map block
						; CF set if error
	call	FileSetNewPathInFirstElement
	jmp	done
notFound:
	mov	di, ss:[objectChunkHandle]
	call	FileCreateNewPuzzleData		; ax - puzzle block handle
						; ds - possibly updated
						;      segment pointer to
						;      the map block
						; CF set if error
done:
	pushf
	push	bp				; locals pointer
	mov	bp, ss:[mapBlockMemoryHandle]
	call	VMDirty
	push	ax				; puzzle block handle
	call	VMUpdate			; ax - error code
	pop	ax				; puzzle block handle
	jc	vmErr

	call	VMUnlock
	segmov	ds, es				; CwordFileBox segment
finish:
	pop	bp				; locals pointer
	popf

	.leave
	ret
vmErr:
	clr	ax				; bad puzzle handle
	mov	di, VM_ERR
	call	CwordHandleError
	jmp	finish
FileGetUserDocPuzzleBlockHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGiveDataToEngine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give the user's data to the Engine Module.

CALLED BY:	FileReadUserDocument
PASS:		ax	- puzzle block handle
		bx	- VM file handle
		dx	- engine token
		bp	- stack frame locals pointer

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGiveDataToEngine	proc	near
	uses	ax,cx,si,es
	.enter	inherit	FileReadUserDocument 	

	push	bp			; locals pointer
	call	VMLock		; ax - segment, bp - memory handle
	mov	es, ax			; puzzle segment
	mov	ax, bp			; memory handle
	pop	bp			; locals pointer
	mov	ss:[memHandle], ax	; memory handle

	push	bp			; locals pointer
	clr	bp
	
	; the Engine can read directly from the VM block in es:bp
	
	call	EngineReadCellData

	; GET THE DIRECTION
	mov	bl, {byte}es:[bp]		; direction
	inc	bp

	; GET THE SELECTED CELL by looking at the number of the
	; first cell in the selected word and the offset of the
	; selected cell within the word.

	mov	al, {byte}es:[bp]		; number in first cell
						; of selected word
	inc	bp
	call	EngineMapCellNumberToCellToken	; ax - cell token
	mov	cx, bp				; buffer offset
	pop	bp				; locals pointer
;HACK
	clr	bh
	mov	ss:[boardInitData].BID_direction, bx

	push	bp			; locals pointer
	mov	bp, cx			; buffer offset

	mov	cl, {byte}es:[bp]		; offset of cell in word
	inc	bp
	call	EngineGetCellTokenGivenOffsetAndDirection	; ax -
								; cell token
	mov	cx, bp				; buffer offset
	pop	bp				; locals pointer
	mov	ss:[boardInitData].BID_cell, ax
	push	bp				; locals pointer
	mov	bp, cx				; buffer offset

	; GET THE ACROSS SELECTED CLUE
	mov	al, {byte}es:[bp]		; across clue number
	inc	bp
	mov	cx, ACROSS
	call	EngineMapClueNumberToClueToken	; cx - clue token
	mov	si, cx				; clue token

	; GET THE DOWN SELECTED CLUES
	mov	al, {byte}es:[bp]		; down clue number
	inc	bp
	mov	cx, DOWN
	call	EngineMapClueNumberToClueToken	; cx - clue token

	pop	bp				; locals pointer
	mov	ss:[boardInitData].BID_acrossClue, si
	mov	ss:[boardInitData].BID_downClue, cx

	push	bp				; locals pointer
	mov	bx, ss:[vmFileHandle]
	mov	bp, ss:[memHandle]
	call	VMUnlock
	pop	bp				; locals pointer

	.leave
	ret
FileGiveDataToEngine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetBlockHandleOfFirstPuzzle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the block handle of the first puzzle in the
		map block of the VM file.

CALLED BY:	FileWriteUserDocument
PASS:		bx	- VM file handle
		*ds:si	- CwordFileBox object

RETURN:		ax	- VM block handle for puzzle data

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetBlockHandleOfFirstPuzzle	proc	near
	class CwordFileBoxClass
	uses	bx,dx,di,si,bp,ds,es
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass

	; Get the MapBlock, then look at the first element of the
	; chunk array within it.

	segmov	es,ds			; object segment
	mov	di,si			; object chunk handle
	call	FileLockMapBlockAndMainArray

	mov	di, es:[di]			; instance data ptr
	mov	dx, es:[di].CFBI_engine

getFirst:
	clr	ax
	call	ChunkArrayElementToPtr		; ds:di - element
	jnc	puzzleFound
	
	; The user document was probably deleted and recreated for
	; some reason, so the first element in the ordered puzzles
	; chunk array is no longer our puzzle solution element.
	; Re-create it.

	call	FileCreateNewPuzzleData	
	jmp	getFirst

puzzleFound:
	mov	ax, ds:[di].PD_puzzleHandle
	
	push	ax				; puzzle handle
	call	VMUpdate			; save and unlock the
						; 	mapblock
	jc	vmErr
	
	call	VMUnlock	

	pop	ax				; puzzle handle
	clc
finish:
	.leave
	ret
vmErr:
	pop	ax				; puzzle handle
	clr	ax				; bad puzzle handle
	mov	di, VM_ERR
	call	CwordHandleError
	jmp	finish
FileGetBlockHandleOfFirstPuzzle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetNameAndPathOfFirstPuzzle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the puzzle name of the first puzzle in the
		map block of the VM file.

CALLED BY:	CFBLoadLastPuzzlePlayed
PASS:		bx	- VM file handle
		*ds:si	- CwordFileBox object
		cx:dx	- buffer of length FILE_LONGNAME_BUFFER_SIZE
				for filename
		es:di	- buffer of GenFilePath

RETURN:		clc
			filled buffers
		stc
			no first puzzle

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetNameAndPathOfFirstPuzzle	proc	near
	class CwordFileBoxClass
filePathSegment		local	word	push	es
filePathoffset		local	word	push	di
mapBlockMemHandle	local	word
elementSegment		local	word
elementOffset		local	word
	uses	ax,cx,di,si,ds,es
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass

	segmov	es,ds			;object segment
	push	bp			;locals
	call	FileLockMapBlockAndMainArray
	mov	di,bp			;vm mem lock handle
	pop	bp			;locals
	mov	mapBlockMemHandle,di

	clr	ax
	call	ChunkArrayElementToPtr		; ds:di - element
	LONG	jc noElements

	mov	ss:[elementSegment], ds
	mov	ss:[elementOffset], di

	; copy the puzzle name to the new element
	; set up arguments for movs{b,w}
	; ds:si = puzzle name, es:di = place to copy to

	lea	si, ds:[di].PD_puzzleName
	mov	es, cx
	mov	di, dx

	mov	cx, FILE_LONGNAME_BUFFER_SIZE
	shr	cx
	jnc	evenNum
	movsb
evenNum:
	rep	movsw

	; copy the disk handle and the path from the element to
	; the GenFilePath  buffer

	mov	ds, ss:[elementSegment]
	mov	si, ss:[elementOffset]

	mov	es, ss:[filePathSegment]
	mov	di, ss:[filePathoffset]
	
	mov	ax, ds:[si].PD_filePath.GFP_disk
	mov	es:[di].GFP_disk, ax

	; copy the path to the new element
	; set up arguments for movs{b,w}
	; ds:si = path, es:di = place to copy to

	lea	si, ds:[si].PD_filePath.GFP_path
	lea	di, es:[di].GFP_path
	
	mov	cx, PATH_BUFFER_SIZE
	shr	cx
	jnc	evenNumPath
	movsb
evenNumPath:
	rep	movsw

	call	VMUpdate			; save and unlock the
						; 	mapblock
	jc	vmErr
	push	bp				; locals
	mov	bp, ss:[mapBlockMemHandle]
	call	VMUnlock
	pop	bp				; locals
	clc
finish:
	.leave
	ret
vmErr:
	pop	ax				; puzzle handle
	clr	ax				; bad puzzle handle
	mov	di, VM_ERR
	call	CwordHandleError
	jmp	finish

noElements:
	push	bp				; locals
	mov	bp, ss:[mapBlockMemHandle]
	call	VMUnlock
	pop	bp				; locals
	stc
	jmp	finish

FileGetNameAndPathOfFirstPuzzle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileFindPuzzleInMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the puzzle specified in CFBI_sourceFile of the
		CwordFileBox instance data in the map block of the VM
		user document file.

CALLED BY:	FileGetUserDocPuzzleBlockHandle
PASS:		bx	- VM file handle
		*ds:si	- CwordFileBoxClass object

RETURN:		cx	- TRUE or FALSE whether a matching puzzle was
				found
		ax	- element number of found puzzle if CX = TRUE.
				Otherwise ax is meaningless.
		es	- CwordFileBox segment

DESTROYED:	ax if CX = FALSE, used as return value otherwise
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Assume that no two files have the same source filename.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileFindPuzzleInMapBlock	proc	near
	class CwordFileBoxClass
	uses	dx,di,bp
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass

	segmov	es,ds
	mov	di, es:[si]		; instance pointer
	lea	dx, es:[di].CFBI_sourceFile
	call	FileFindPuzzleInMapBlockLow

	.leave
	ret
FileFindPuzzleInMapBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileFindPuzzleInMapBlockLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the puzzle specified in the map block of the VM
		user document file.

CALLED BY:	FileFindPuzzleInMapBlock
PASS:		bx	- VM file handle
		es:dx	- null terminated puzzle name

RETURN:		cx	- TRUE or FALSE whether a matching puzzle was
				found
		ax	- element number of found puzzle if CX = TRUE.
				Otherwise ax is meaningless.

DESTROYED:	ax if CX = FALSE, used as return value otherwise
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Assume that no two files have the same source filename.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileFindPuzzleInMapBlockLow	proc	near
	class CwordFileBoxClass
	uses	bx,dx,di,bp,ds,si
	.enter

	call	FileLockMapBlockAndMainArray

	mov	cx, FALSE		; initially, puzzle is not found
	mov	bx, cs
	mov	di, offset FileFindPuzzleCallback
	call	ChunkArrayEnum

	call	VMUnlock		; map block

	.leave
	ret
FileFindPuzzleInMapBlockLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLockMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	lock the map and return cool info

CALLED BY:	UTILITY

PASS:		
		bx - vm file handle

RETURN:		
		ds	- segment of map block
		bp 	- mem handle of map block

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileLockMapBlock		proc	near
	uses	ax
	.enter

	call	VMGetMapBlock		; ax - block handle
	Assert	ne	ax, 0		; map block should exist

	call	VMLock			; ax - segment
					; bp - memory handle of block
	mov	ds, ax			; map block segment

	.leave
	ret
FileLockMapBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLockMapBlockAndMainArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	lock the map and return cool info

CALLED BY:	UTILITY

PASS:		
		bx - vm file handle

RETURN:		
		*ds:si	- map block ordered puzzle array
		bp 	- mem handle of map block

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileLockMapBlockAndMainArray		proc	near
	uses	ax
	.enter

	call	FileLockMapBlock
	mov	si, ds:[VMUBH_orderedPuzzleChunkHandle]

EC <	call	ECCheckChunkArray					>

	.leave
	ret
FileLockMapBlockAndMainArray		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLockMapBlockAndCompletedArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	lock the map and return cool info

CALLED BY:	UTILITY

PASS:		
		bx - vm file handle

RETURN:		
		*ds:si	- map block ordered puzzle array
		bp 	- mem handle of map block

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileLockMapBlockAndCompletedArray		proc	near
	uses	ax
	.enter

	call	FileLockMapBlock
	mov	si, ds:[VMUBH_completedPuzzleChunkHandle]

EC <	call	ECCheckChunkArray					>

	.leave
	ret
FileLockMapBlockAndCompletedArray		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAddCompletedPuzzle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the file name in CFBI_sourceFile to the completed
		puzzle array

CALLED BY:	CFBMarkComplete

PASS:		
		*ds:si - CwordFileBox

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileAddCompletedPuzzle		proc	near
	class	CwordFileBoxClass
	uses	ax,bx,cx,ds,si,es,di,bp
	.enter

	Assert	objectPtr dssi, CwordFileBoxClass
	
	segmov	es,ds				;object segment
	mov	di,si				;object chunk

	;   Open the user document and lock down the block with
	;   the chunk array of completed puzzle names
	;

	call	FileOpenUserDocument
	jc	done
	push	bx				;vm file handle
	call	FileLockMapBlockAndCompletedArray

	;    Calculate the length of the file name and create an
	;    element of that size
	;

	push	di				;object chunk
	mov	di,es:[di]
	add	di,offset CFBI_sourceFile
	mov	bx,di				;offset to string
	call	LocalStringLength
	mov	ax,cx				;string length
	inc	ax				;+ null terminator
	call	ChunkArrayAppend
	pop	si				;object chunk
	jc	unlockMap

	;     Copy string from CFBI_sourcFile into element
	;

	segxchg	es,ds				;element segment, string segment
	mov	si,ds:[si]
	add	si,offset CFBI_sourceFile
	LocalCopyString

unlockMap:
	pop	bx				;vm file handle
	call	VMUnlock			;map block
	call	VMUpdate
	call	VMClose

done:
	.leave
	ret
FileAddCompletedPuzzle		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileFindCompletedPuzzleInMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the puzzle specified in CFBI_sourceFile of the
		CwordFileBox instance data in the completed array of the
		map block of the VM user document file.

CALLED BY:	CFBRemoveFromCompletedArray

PASS:		bx	- VM file handle
		*ds:si	- CwordFileBoxClass object

RETURN:		cx	- TRUE or FALSE whether a matching puzzle was
				found
		ax	- element number of found puzzle if CX = TRUE.
				Otherwise ax is meaningless.
		es	- CwordFileBox segment

DESTROYED:	ax if CX = FALSE, used as return value otherwise
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Assume that no two files have the same source filename.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileFindCompletedPuzzleInMapBlock	proc	near
	class CwordFileBoxClass
	uses	dx,di,bp
	.enter

	Assert	objectPtr	dssi, CwordFileBoxClass

	segmov	es,ds
	mov	di, es:[si]		; instance pointer
	lea	dx, es:[di].CFBI_sourceFile
	call	FileFindCompletedPuzzleInMapBlockLow

	.leave
	ret
FileFindCompletedPuzzleInMapBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileFindCompletedPuzzleInMapBlockLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the puzzle specified in the completed chunk array in 
		the map block of the VM user document file.

CALLED BY:	
PASS:		bx	- VM file handle
		es:dx	- null terminated puzzle name

RETURN:		cx	- TRUE or FALSE whether a matching puzzle was
				found
		ax	- element number of found puzzle if CX = TRUE.
				Otherwise ax is meaningless.

DESTROYED:	ax if CX = FALSE, used as return value otherwise
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Assume that no two files have the same source filename.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileFindCompletedPuzzleInMapBlockLow	proc	near
	class CwordFileBoxClass
	uses	bx,dx,di,bp,ds,si
	.enter

	call	FileLockMapBlockAndCompletedArray

	mov	cx, FALSE		; initially, puzzle is not found
	mov	bx, cs
	mov	di, offset FileFindCompletedPuzzleCallback
	call	ChunkArrayEnum

	call	VMUnlock		; map block

	.leave
	ret
FileFindCompletedPuzzleInMapBlockLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileFindCompletedPuzzleCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the puzzle block handle matching the puzzle
		file name given.

CALLED BY:	ChunkArrayEnum

PASS:		es:dx	- puzzle name to look for
		*ds:si	- completd chunk array
		ds:di	- array element being enumerated

RETURN:		CF	- set if puzzle found, clear otherwise.
		cx	- TRUE if puzzle match found,
			  FALSE otherwise.
		ax	- element number of found puzzle name
			  if CX = TRUE.  Otherwise ax is meaningless.

DESTROYED:	ax is trashed if and only if cx == FALSE.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	procedure is a far because it is a callback.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileFindCompletedPuzzleCallback	proc	far
	.enter

EC <	call	ECCheckChunkArray					>

	push	si, di			; array pointer, element pointer

	mov	si, di			; offset to puzzle name

	; es:di - puzzle name (file name) to look for
	;
	mov	di, dx			; es:di - puzzle name to look for
	clr	cx			; compare till NULL terminated
	call	LocalCmpStrings
	jz	found
	; puzzle names don't match
	pop	si, di			; array pointer, element pointer
	mov	cx, FALSE
	clc
finish:
	.leave
	ret
found:
	pop	si, di			; array pointer, element pointer
EC <	call	ECCheckChunkArray					>
	call	ChunkArrayPtrToElement		; ax - element
	mov	cx, TRUE
	stc
	jmp	finish
FileFindCompletedPuzzleCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDeleteCompletedPuzzleFromCompletedArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the chunk array element 

CALLED BY:	CFBRemoveFromCompletedArray
		
	
PASS:		
		*ds:si - Completed chunk array
		ax - element number
		bx - VM file handle

RETURN:		

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDeleteCompletedPuzzleFromCompletedArray		proc	near
	uses	ax,di
	.enter

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS
	call	ChunkArrayDelete
	call	VMUpdate

	.leave
	ret
FileDeleteCompletedPuzzleFromCompletedArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringAsciiConvertToInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an ascii string, translate it to its actual
		number.  The number ends when the delimiter is reached.

CALLED BY:	general
PASS:		es:bx 	- buffer
		dh	- delimiter

RETURN:		ax	- Integer
		bx	- updated offset into buffer to point to byte
			  after the delimiter is reached.
		CF	- set if error occurred, clear otherwise
	
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Assume that integer fits in a word.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringAsciiConvertToInteger	proc	near
	uses	cx,dx,si,bp
	.enter

	mov	cl, dh			; cl = delimiter
	mov	si, bx			; si = buffer offset
	clr	bx
	clr	ax			; al = sum so far
	mov	bp, 10			; for multiplying ax by
sum:	
	mov	bl, es:[si]		; bl = ascii number
	cmp	bl, C_ZERO
	jl	sourceErr
	cmp	bl, C_NINE
	jg	sourceErr

	sub	bl, C_ZERO		; bl = number
	mul	bp			; sum so far * 10
	add	ax, bx			; (sum so far * 10) + number
	inc 	si			; increment buffer pointer
	
	cmp	es:[si], cl		; check for delimiter
 	jne	sum

	inc	si			; point to character after
					; delimiter
	mov	cx, dx			; cxax = Integer
EC <	tst	cx							>
EC <	ERROR_NZ	ASCII_TO_INTEGER_IS_LARGER_THAN_WORD		>
	mov	bx, si			; new buffer offset
	clc
finish:
	.leave
	ret

sourceErr:
	mov	di, SOURCE_ERR
	call	CwordHandleError
	jmp	finish
StringAsciiConvertToInteger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFBNotifyError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the File Module that an error has occurred in
		the crossword application. 

CALLED BY:	MSG_CFB_NOTIFY_ERROR
PASS:		*ds:si	= CwordFileBoxClass object
		ds:di	= CwordFileBoxClass instance data
		ds:bx	= CwordFileBoxClass object (same as *ds:si)
		es 	= segment of CwordFileBoxClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
PSEUDO CODE/STRATEGY:
	Set CFBI_puzzleIsOpen to FALSE.
	Tell the Engine and Board Modules to clean up.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFBNotifyError	method dynamic CwordFileBoxClass, 
					MSG_CFB_NOTIFY_ERROR
	uses	ax, cx, dx, bp
	.enter

	cmp	ds:[di].CFBI_puzzleIsOpen, FALSE
	je	noOpenPuzzle

	mov	ds:[di].CFBI_puzzleIsOpen, FALSE
	
	; Tell the Board Module that its Engine Token is now invalid
	; since a new puzzle is about to be opened.
	push	si				; object handle
	mov	bx, handle Board		; single-launchable
	mov	si, offset Board
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_BOARD_CLEAN_UP
	call	ObjMessage
	pop	si				; object handle

noOpenPuzzle:
	.leave
	ret
CFBNotifyError	endm





CwordFileCode	ends
