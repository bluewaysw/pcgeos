COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit	
FILE:		documentInitfile.asm

AUTHOR:		Cassie Hartzog, Aug 24, 1993

ROUTINES:
	Name			Description
	----			-----------
	REDPromptForSourceGeodeName	Get the name and relative path of the 
				source geode from the user. 
	ConstructRelativePath	Get the path of the selected file, relative to 
				the top-level source directory. 
	GetRelativePath		Get the relative path for the new geode from 
				the original geode and the top-level source 
				directory. 
	DocumentResetSourcePath	The source geode has moved; reset its path in 
				the translation file. 
	SetDirectoryFromInitFile	Change to the top-level directory set 
				in the init file. 
	ReadPathFromInitFile	Read the requested ResEdit path from the init 
				file. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	8/24/93		Initial revision


DESCRIPTION:
	Contains routines which manipulate the init file.

	$Id: documentInitfile.asm,v 1.1 97/04/04 17:14:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentInitfile	segment resource

; These should not be DBCS-ized
;
categoryString	char	"resedit", 0
destinationKey	char	"destinationDir", 0
sourceKey	char	"sourceDir", 0
LocalDefNLString	nullPath, < 0 >

DIF_ObjMessage_call		proc	near
	push	di
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di
	ret
DIF_ObjMessage_call		endp

;---



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDPromptForSourceGeodeName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name and relative path of the source geode from the
		user.

CALLED BY:	MSG_RESEDIT_DOCUMENT_PROMPT_FOR_SOURCE_GEODE_NAME

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #

RETURN:		if error, 
			carry set
			ax = ErrorValue
		else
			carry clear

DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDPromptForSourceGeodeName	method dynamic ResEditDocumentClass, 
			MSG_RESEDIT_DOCUMENT_PROMPT_FOR_SOURCE_GEODE_NAME
documentOffset	local	word		push	si	
filePath	local	PathName
		uses	cx, dx, bp
		.enter

		push	ds:[LMBH_handle]

getFile:

	; Get the source geode path from the .ini file

		segmov	es, ss, di
		lea	di, ss:[filePath]
		mov	dx, offset sourceKey
		call	ReadPathFromInitFile
		jc	putUpDialog		; skip PATH_SET if no path

	; Move the file selector to this path.

		push	bp
		mov	ax, MSG_GEN_PATH_SET
		mov	cx, ss
		lea	dx, ss:[filePath]
		clr	bp
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset NewFileSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS 
		call	ObjMessage
		pop	bp
		jc	error		

	; Put up the dialog.

putUpDialog:
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset NewFileInteraction
		push	ds:[LMBH_handle]
		call	UserDoDialog
		pop	bx
		call	MemDerefDS	; restore ds if it gets trashed
		cmp	ax, IC_DISMISS
		mov	ax, EV_NO_ERROR
		stc
		LONG	je	error

	; Lock the TransMapHeader.

		mov	si, ss:[documentOffset]
		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		movdw	esdi, cxdx

	; Determine relative path (in relation to top-level GEOS dir).

		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset NewFileSelector
		call	ConstructRelativePath
		jc	errorUnlockTMH

	; Copy the file name from the file selector to the TransMapHeader.
	
		push	bp, di
		mov	cx, es
		lea	dx, es:[di].TMH_sourceName
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset NewFileSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS 
		call	ObjMessage
		mov	dx, bp			; File type.
		pop	bp, di

	; Mark as dirty and unlock the TransMapHeader.

		call	DBDirty
		mov	si, ss:[documentOffset]
		call	DBUnlock

	; Make sure it is a file.

		andnf	dx, (mask GFSEF_TYPE)
		cmp	dx, (GFSET_FILE shl offset GFSEF_TYPE)
		je	done

	; Report error.

		mov	ax, MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE
		mov	cx, EV_NOT_A_FILE
		call	ObjCallInstanceNoLock
		jmp	getFile

done:
		clc
error:
		pop	bx
		call	MemDerefDS

		.leave
		ret

errorUnlockTMH:

	; Unlock the TransMapHeader.

		mov	si, ss:[documentOffset]
		call	DBUnlock
		jmp	error

REDPromptForSourceGeodeName	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConstructRelativePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the path of the selected file, relative to the
		top-level source directory.

CALLED BY:	GetFileName, DocumentResetSourcePath

PASS:		^lbx:si	- file selector
		es:di - TransMapHeader

RETURN:		carry set if error
			ax - ErrorValue

DESTROYED:	bx,cx,dx,si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConstructRelativePath		proc	far
partialPath	local	PathName
fullPath	local	PathName
		uses	bp,ds
		.enter

	; Get path and disk handle for the selected geode.
	
		push	bp
		lea	bp, ss:[partialPath]
		mov	dx, ss			;dx:bp <- pathname buffer
		mov	cx, size PathName
		mov	ax, MSG_GEN_PATH_GET
		call	DIF_ObjMessage_call	;^hcx <- disk handle
		mov	ax, EV_PATH_GET
		pop	bp
		jc	done

	; Translate into full path, with drive letter.

		push	es, di
		mov	bx, cx			; ^hbx <- disk handle
		segmov	ds, ss, ax
		lea	si, ss:[partialPath]	; ds:si <- tail of path
		mov	es, ax	
		lea	di, ss:[fullPath]	; es:di <- buffer
		mov	dx, -1			; add drive letter
		mov	cx, size PathName
		call	FileConstructFullPath	; es:di <- full path
		mov	ax, EV_PATH_GET
		jc	errorPopESDI

	; Get the top-level source path from the ini file
	
		lea	di, ss:[partialPath]	; es:di <- buffer for source
		mov	cx, cs
		mov	dx, offset sourceKey	; cx:dx <- key
		call	ReadPathFromInitFile
		mov	ax, EV_READ_FROM_INIT_FILE
		jc	getSourcePath

havePath:
		pop	es, di

	; Now partialPath = top-level source dir, and
	; fullPath contains the full path of the geode.
	; Pass: ss:dx <- source path
	;  	ss:si <- geode's full path
	; 	es:di <- TransMapHeader
	
		lea	dx, ss:[partialPath]	; ss:dx <- buffer for source
		lea	si, ss:[fullPath]	
		call	GetRelativePath

done:
		.leave
		ret

errorPopESDI:
		pop	es, di
		stc
		jmp	done

getSourcePath:

	; We were unsuccessful in reading the source path from the
	; ini file, most likely because one has not yet been set.  
	; We'll just have to pick something (SP_TOP) and use that
	; source path so that we can at least try to get the relative
	; path.
	
		mov	bx, SP_TOP
		mov	dx, 1			; add drive name
		segmov	ds, cs		
		mov	si, offset nullPath	; ds:si <- tail of path
		mov	cx, size PathName
		push	di
		call	FileConstructFullPath	; es:di <- source dir
		pop	di

		mov	cx, cs	
		mov	dx, offset sourceKey		; cx:dx <- key 
		mov	si, offset categoryString	; ds:si <- category
		call	InitFileWriteString		
		call	InitFileCommit			; write it to disk
		jmp	havePath	

ConstructRelativePath		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRelativePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the relative path for the new geode from the
		original geode and the top-level source directory.

CALLED BY:	ConstructRelativePath
PASS:		ss:dx	- top-level source directory
		ss:si	- path of selected geode
		es:di	- TransMapHeader
		
RETURN:		carry set if error 

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRelativePath		proc	near
	uses	bp,si,di,ds,es
	.enter

	push	di, es

	segmov	es, ss, ax
	mov	ds, ax
	mov	di, dx

	;
	; Now es:di = path of top-level source directory, and
	; ds:si = path of original geode.  Compare up to the
	; length of the top-level source directory.  If not equal,
	; there is a source-dir mismatch.  If equal, what remains of
	; the geode's full path is the relative path.
	;
	push	di
	mov	cx, -1				;look forever
	LocalClrChar	ax			;for a NULL
	LocalFindChar				;es:di <- pts to null
	not	cx				;cx <- string length
	pop	di				;es:di <- full path source dir

	dec	cx				;don't compare the null
	call	LocalCmpStringsNoCase			
	jnz	error

DBCS <	shl	cx, 1				;convert to offset	>
	add	si, cx				;ds:si <- relative path	
	LocalIsNull	ds:[si]			;are we at end of path string?
	jz	endOfPath
	LocalCmpChar	ds:[si], C_BACKSLASH	;is next char a path separator?
	jne	error
	LocalNextChar	dssi			;skip the path separator

endOfPath:
	; Now that we have the relative path, find out how long it is.
	;
	mov	di, si				;es:di <- relative path
	mov	cx, -1				;look forever
	LocalClrChar	ax			;for a NULL
	LocalFindChar				;es:di <- pts to null
	not	cx				;cx <- string length

	; Copy it to the TransMapHeader
	;
	pop	di, es
	mov	es:[di].TMH_pathLength, cx
	lea	di, es:[di].TMH_relativePath	; es:di <- destination
	LocalCopyNString			; rep movs[bw]
	clc
done:
	.leave
	ret

error:
	mov	ax, EV_WRONG_PATH
	add	sp, 4				; clear the stack
	stc
	jmp	done
GetRelativePath		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentResetSourcePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The source geode has moved; reset its path in the 
		translation file.

CALLED BY:	MSG_RESEDIT_DOCUMENT_RESET_SOURCE_PATH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentResetSourcePath		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_RESET_SOURCE_PATH

fileName	local	FileLongName
	.enter

	push	ds:[LMBH_handle], si		;save Document optr
	call	GetFileHandle
	call	DBLockMap
	mov	di, es:[di]			;es:di <- TransMapHeader

	push	bp
	GetResourceHandleNS	ProjectMenuUI, bx
	mov	si, offset ResetSourcePathSelector
	lea	dx, ss:[fileName]
	mov	cx, ss				;cx:dx <- buffer for selection
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION 
	call	DIF_ObjMessage_call		;bp <- GFSEF
	andnf	bp, mask GFSEF_TYPE
	mov	ax, EV_NOT_A_FILE
	cmp	bp, GFSET_FILE shl offset GFSEF_TYPE
	pop	bp
	jne	error

	segmov 	ds, ss, ax
	call	ConstructRelativePath
	jc	error

	call	DBDirty
done:
	call	DBUnlock

	; Need to update the UI to reflect our new name & relative path

	pop	bx, si				;restore Document opr
	call	MemDerefDS
	push	bp
	call	SetResetSourcePathInteraction
	pop	bp

	.leave
	ret

error:
	mov	cx, ax
	call	DocumentDisplayMessage
	jmp	done
DocumentResetSourcePath		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDirectoryFromInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to the top-level directory set in the init file.

CALLED BY:	CopySourceInfo, OpenSourceFile, 
		REDCreateNullExecutable, OpenBuildFiles
PASS:		dx  - offset of key string
RETURN:		carry set on error
			ax - ErrorValue
			
DESTROYED:	ax,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDirectoryFromInitFile	proc	far
pathBuffer	local	PathName
		uses	bx,di,ds,es
		.enter

	; Get the path from init file.

		segmov	es, ss, ax
		lea	di, ss:[pathBuffer]	; es:di <- destination buffer
		call	ReadPathFromInitFile
		jc	done

	; Set the path.

		clr	bx			; path is relative
		segmov	ds, es, ax
		mov	dx, di			; ds:dx <- path name
		call	FileSetCurrentPath
		mov	ax, EV_INVALID_PATH

done:
		.leave
		ret
SetDirectoryFromInitFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadPathFromInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the requested ResEdit path from the init file.

CALLED BY:	SetDirectoryFromInitFile
PASS:		es:di	- buffer to fill
		dx	- offset of key string

RETURN:		carry set if error
			ax - error value
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadPathFromInitFile	proc	far
		uses	si,bp,ds,cx
		.enter

		mov	cx, cs				; cx:dx <- key
		mov	ds, cx
		mov	si, offset categoryString	; ds:si <- category
		mov	bp, PATH_BUFFER_SIZE
		call	InitFileReadString
		mov	ax, EV_READ_FROM_INIT_FILE

		.leave
		ret
ReadPathFromInitFile	endp


DocumentInitfile	ends

