COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		deskdisplayPathname.asm

AUTHOR:		Adam de Boor, Jan 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/30/92		Initial revision


DESCRIPTION:
	Implementation of PathnameStorageClass
		

	$Id: cdeskdisplayPathname.asm,v 1.1 97/04/04 15:02:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


FileOperation segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathnameStorageSetPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store pathname into instance data and send to parent
		GenTextDisplay to display

CALLED BY:	MSG_GEN_PATH_SET

PASS:		*ds:si	= generic object
		cx:dx	= null-terminated pathname
		bp	= disk handle of path, or StandardPath constant, or 0
RETURN:		carry set if path couldn't be set:
			ax = error code (FileError)
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PathnameStorageSetPathname	method	PathnameStorageClass,
						MSG_GEN_PATH_SET

if ERROR_CHECK
	;
	; Validate that the path is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, cx							>
FXIP<	mov	si, dx							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif
	;
	; Send it to our superclass to actually store the beast.
	; 
	mov	di, offset PathnameStorageClass
	call	ObjCallSuperNoLock
	jc	done

	;
	; Now construct a full path we can set as the text for this object.
	; 
	mov	cx, size PathName
	sub	sp, cx
	mov	di, sp
	segmov	es, ss
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	BuildDiskAndPathNameFromVarData

if GPC_FILE_OP_DIALOG_PATHNAME
	mov	di, sp		; es:di = path
	clr	bx		; path contains drive name
	call	FileParseStandardPath
	mov	cx, ax		; save SP constant

	GetResourceHandleNS	FileOpDialogStrings, bx
	call	MemLock
	push	ds		; save ds to be restored of ObjCallInstanceNoLock
	mov	ds, ax		; ds <- FileOpDialogString resource
	mov	ax, cx		; ax <- SP constant

	cmp	ax, SP_DOCUMENT
	jne	notDoc
	mov	bp, offset docDirText
	mov	bp, ds:[bp]
	call	getStrLen	; cx <- len (with slash)

spCommon:
	mov	dx, ds
	pop	ds		; restore ds for ObjCallInstanceNoLock
	push	es		; save tail segment
	push	di		; save tail offset
	cmp	{TCHAR}es:[di], 0
	jne	haveSlash
	dec	cx		; no tail, no slash
haveSlash:
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock
	pop	bp		
	pop	dx		; append tail, if any
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	jmp	short doText

notDoc:
	cmp	ax, SP_APPLICATION
	jne	notAppDoc
	mov	bp, offset appDirText
	mov	bp, ds:[bp]
	call	getStrLen	; cx <- len (with slash)
	jmp	short spCommon

notAppDoc:
	cmp	ax, SP_WASTE_BASKET
	jne	notAppDocWaste
	mov	bp, offset wasteDirText
	mov	bp, ds:[bp]
	call	getStrLen	; cx <- len (with slash)
	jmp	short spCommon

notAppDocWaste:
	cmp	ax, STANDARD_PATH_OF_DESKTOP_VOLUME
	jne	notAppDocWasteDesktop
	push	si
	mov	si, offset desktopPath
	mov	si, ds:[si]
	mov	bp, si
	call	getStrLen
	mov	bx, cx		; bx <- string count
	clr	cx
	call	LocalCmpStringsNoCase
	pop	si
	jne	notAppDocWasteDesktop
	cmp	{TCHAR}es:[di][bx], 0
	je	gotDesktop
	cmp	{TCHAR}es:[di][bx], '\\'
	jne	notAppDocWasteDesktop
	inc	di			; skip past "desktop\" in path
gotDesktop:
	add	di, bx			; skip past "desktop" in path
	mov	bp, offset desktopText
	mov	bp, ds:[bp]
	call	getStrLen		; cx <- strlen of desktop string
	jmp	short spCommon

notAppDocWasteDesktop:
	pop	ds		; restore ds for ObjCallInstanceNoLock
	movdw	dxbp, sssp
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
doText:
	clr	cx			; null-terminated
	call	ObjCallInstanceNoLock
	GetResourceHandleNS	FileOpDialogStrings, bx
	call	MemUnlock
else
	sub	di, sp		; figure length of result
DBCS <	shr	di, 1							>
	dec	di		; don't include null

	movdw	dxbp, sssp			;dxbp = text
	mov	cx, di				;cx = length
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock
endif

	add	sp, size PathName
done:
	ret

if GPC_FILE_OP_DIALOG_PATHNAME
getStrLen:
SBCS <	clr	al >
DBCS <	clr	ax >
	pushdw	esdi
	segmov	es, ds, cx
	mov	cx, -1
	mov	di, bp
SBCS <	repne	scasb >
DBCS <  repne	scasw >
	not	cx
	dec	cx
	popdw	esdi
	retn
endif
PathnameStorageSetPathname	endm



FileOperation ends

if GPC_FILE_OP_DIALOG_PATHNAME
FileOpDialogStrings	segment lmem LMEM_TYPE_GENERAL
docDirText	chunk
	TCHAR	"Documents\\", 0  
docDirText	endc

appDirText	chunk
ifdef GPC_ONLY
	TCHAR	"Programs\\", 0
else
	TCHAR	"World\\", 0
endif
appDirText	endc

wasteDirText	chunk
	TCHAR	"Wastebasket\\", 0
wasteDirText	endc

desktopText	chunk
	TCHAR	"Desktop\\", 0
desktopText	endc

desktopPath	chunk
	TCHAR	ND_DESKTOP_RELATIVE_PATH, 0
desktopPath	endc
FileOpDialogStrings	ends
endif

;----------------------------------------------------------------------------
