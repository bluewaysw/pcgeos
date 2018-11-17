COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ResEdit
FILE:		documentPath.asm

AUTHOR:		Paul Canavese, Jul 27, 1995

ROUTINES:
	Name			Description
	----			-----------
	REDGetFullPath		Fill the passed buffer with the top-level path 
				specified by the indicated .ini key and the 
				geode's relative path. 
	REDGetFullSourcePath	Copy the source path (both top level and 
				relative) into a buffer. 
	REDGetFullDestinationPath	Copy the destination path (both top 
				level and relative) into a buffer. 
	REDChangeToFullPath	Change to the the top-level path specified by 
				the indicated .ini key and the geode's relative 
				path. 
	REDChangeToFullSourcePath	Change to the full source path 
				(including geode's relative path). 
	REDChangeToFullDestinationPath	Change to the full destination path 
				(including geode's relative path). 
	CreateSubdirs		Create all levels of sub-directories under the 
				current directory. 
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/27/95   	Initial revision


DESCRIPTION:
	Methods and routines for handling the source and destination paths.
		

	$Id: documentPath.asm,v 1.1 97/04/04 17:14:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocOpenClose segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDGetFullPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill the passed buffer with the top-level path specified 
		by the indicated .ini key and the geode's relative path.

CALLED BY:	MSG_RESEDIT_DOCUMENT_GET_FULL_PATH

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
		cx:dx	= buffer
		bp	= offset of ini key for top-level path

RETURN:		cx:dx 	= buffer filled with path
DESTROYED:	ax
SIDE EFFECTS:	Locks and unlocks TransMapHeader.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDGetFullPath	method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_GET_FULL_PATH
		uses	cx,dx,ds,es
		.enter

	; Read the top level path from the .ini file.

		mov	es, cx
		mov	di, dx
		mov	dx, bp
		call	ReadPathFromInitFile
		jc	noSourceDir

	; Append a path separator.

		mov	cx, -1			; Look forever
		LocalClrChar	ax		; ...for a NULL
		LocalFindChar			; es:di <- pts after null
		LocalPrevChar	esdi

noSourceDir:

	; Lock the TransMapHeader.

		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		push	ds, si
		movdw	dssi, cxdx		; ds:si <- TransMapHeader

	; Append the relative path.

		mov	cx, ds:[si].TMH_pathLength	; Includes null?
		dec	cx
		jcxz	appendNull
		inc	cx
		LocalLoadChar	ax, C_BACKSLASH
		LocalPutChar	esdi, ax		; stos[bw]
		lea	si, ds:[si].TMH_relativePath
		LocalCopyNString			; rep movs[bw]

	; Append a null character.

appendNull:
		LocalLoadChar	ax, C_NULL
		LocalPutChar	esdi, ax

	; Unlock TransMapHeader.

		call	DBUnlock_DS
		pop	ds, si
	
		.leave
		ret
REDGetFullPath	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDGetFullSourcePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the source path (both top level and relative) into a
		buffer.

CALLED BY:	MSG_RESEDIT_DOCUMENT_GET_FULL_SOURCE_PATH

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
		cx:dx	= buffer

RETURN:		cx:dx	= buffer filled with path
DESTROYED:	ax
SIDE EFFECTS:	Locks and unlocks TransMapHeader.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDGetFullSourcePath	method dynamic ResEditDocumentClass, 
				MSG_RESEDIT_DOCUMENT_GET_FULL_SOURCE_PATH
		uses	bp
		.enter

		mov	ax, MSG_RESEDIT_DOCUMENT_GET_FULL_PATH
		mov	bp, offset sourceKey
		call	ObjCallInstanceNoLock

		.leave
		ret
REDGetFullSourcePath	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDGetFullDestinationPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the destination path (both top level and relative) into
		a buffer.

CALLED BY:	MSG_RESEDIT_DOCUMENT_GET_FULL_DESTINATION_PATH

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
		cx:dx	= buffer

RETURN:		cx:dx	= buffer filled with path
DESTROYED:	ax
SIDE EFFECTS:	Locks and unlocks TransMapHeader.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDGetFullDestinationPath	method dynamic ResEditDocumentClass, 
			MSG_RESEDIT_DOCUMENT_GET_FULL_DESTINATION_PATH
		uses	bp
		.enter

		mov	ax, MSG_RESEDIT_DOCUMENT_GET_FULL_PATH
		mov	bp, offset destinationKey
		call	ObjCallInstanceNoLock

		.leave
		ret
REDGetFullDestinationPath	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDChangeToFullPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to the the top-level path specified by the indicated
		.ini key and the geode's relative path.

CALLED BY:	MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_PATH

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
		bp	= offset of ini key for top-level path

RETURN:		if error, 
			carry set
			ax	 = ErrorValue
		else
			carry clear

DESTROYED:	ax (if no error)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDChangeToFullPath	method dynamic ResEditDocumentClass, 
				MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_PATH
pushedBP	local	word	push bp
filePath	local	PathName
		uses	dx
		.enter

	; Get path.

		push	bp
		mov	ax, MSG_RESEDIT_DOCUMENT_GET_FULL_PATH
		mov	cx, ss
		lea	dx, ss:[filePath]
		mov	bp, ss:[pushedBP]
		call	ObjCallInstanceNoLock
		pop	bp	

	; Set path.

		push	ds
		clr	bx
		mov	ds, cx
		call	FileSetCurrentPath	
		pop	ds
		jnc	noError

		mov	ax, EV_INVALID_PATH		
		stc

noError:
		.leave
		ret

REDChangeToFullPath	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDChangeToFullSourcePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to the full source path (including geode's relative
		path).

CALLED BY:	MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_SOURCE_PATH

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
			ax destroyed

DESTROYED:	ax (if no error)

SIDE EFFECTS:	Locks and unlocks document's TransMapHeader.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDChangeToFullSourcePath	method dynamic ResEditDocumentClass, 
			MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_SOURCE_PATH
		uses	bp
		.enter

		mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_PATH
		mov	bp, offset sourceKey
		call	ObjCallInstanceNoLock

		.leave
		ret
REDChangeToFullSourcePath	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDChangeToFullDestinationPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to the full destination path (including geode's
		relative path).

CALLED BY:	MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_DESTINATION_PATH

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #

RETURN:		if error, 
			carry set
			ax = EV_NO_ERROR (we put up error dialog).
		else
			carry clear
			ax destroyed

DESTROYED:	ax (if no error)

SIDE EFFECTS:	Locks and unlocks document's TransMapHeader.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDChangeToFullDestinationPath	method dynamic ResEditDocumentClass, 
			MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_DESTINATION_PATH
		uses	cx, dx, di
filePath	local	PathName
		.enter

	; Attempt to change to destination path.

		push	bp
		mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_PATH
		mov	bp, offset destinationKey
		call	ObjCallInstanceNoLock
		pop	bp
		jnc	done

	; We need to create the path.  Get it first.

		push	bp
		mov	ax, MSG_RESEDIT_DOCUMENT_GET_FULL_PATH
		mov	cx, ss
		lea	dx, ss:[filePath]
		mov	bp, offset destinationKey
		call	ObjCallInstanceNoLock
		pop	bp

	; Create the path.

		push	ds
		segmov	ds, ss, di
		lea	di, ss:[filePath]
		call	CreateSubdirs
		pop	ds

done:
		.leave
		ret
REDChangeToFullDestinationPath	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateSubdirs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create all levels of sub-directories under the current
		directory.

CALLED BY:	REDChangeToFullDestinationPath

PASS:		ds:di	= the multi-level path name that a subdir is to be
			  created accordingly (buffer must be writable)
		current directory set to where subdir is to be created.

RETURN:		CF clear if no error
			current dir changed to bottom level of subdir created
		CF set if error
			ax	= FileError
			string in ds:di might be changed

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/31/94    	Initial version
	jdashe	11/16/94	Snarfed for Tiramisu
	pjc	8/10/95		Snarfed for ResEdit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateSubdirs	proc	near
		uses	bx, cx, dx, ds, es
		.enter

	; Check if path starts with drive letter.

		mov	dx, di
		LocalNextChar	dsdi		; Skip possible drive letter.
		LocalCmpChar	ds:[di], C_COLON
		jne	noLeadingDriveLetter

	; Advance to just past backslash.

		LocalNextChar	dsdi	
		LocalNextChar	dsdi	

	; Replace first character after backslash with a null.
	
		LocalGetChar	cx, ds:[di], NO_ADVANCE	; Remember to restore.
		LocalClrChar 	ds:[di]			; replace with null

	; Set the drive.

		clr	bx
		call	FileSetCurrentPath
		jc	done

	; Restore the character that we nulled out.

		LocalPutChar	dsdi, cx

noLeadingDriveLetter:

	; Back up one character.

		LocalPrevChar	dsdi

	; If there's a leading backslash, skip it.

		LocalCmpChar	ds:[di], C_BACKSLASH
		jne	getLen
		LocalNextChar	ds:[di]	; skip leading backslash (if any)

getLen:
		segmov	es, ds, cx		; ds/es = subject block

nextLevel:
	
	; Anything else?
	
		call	LocalStringLength	; cx = length excl. null
		jcxz	bottomReached
		
	; Find next backslash in path

		mov	dx, di		; ds:dx = current component in path
		mov	ax, C_BACKSLASH	; '\'
		LocalFindChar		; es:di = char after '\'

		mov	cx, 0		; preserve the carry
		jne	createDir	; jump if no more backslash found
		LocalClrChar <ds:[di - size TCHAR]>	; replace '\' with null
		mov	cx, C_BACKSLASH		; character to restore later.
		
createDir:
		call	FileCreateDir	; CF set on error, ax = FileError
		jnc	cdDown
		cmp	ax, ERROR_FILE_EXISTS	; OK if dir already exists
		stc				; assume an error
		jne	done

cdDown:
	
	; Chdir down one level.

		clr	bx			; relative to current path
		call	FileSetCurrentPath	
					; CF set on error, ax = FileError
		jc	done		; something's wrong (VERY unlikely),
					;  return CF set.

		LocalIsNull cx		; If there's nothing else to see, bail.
		jz	bottomReached
SBCS <		mov	{TCHAR} ds:[di - size TCHAR], cl		>
DBCS <		mov	{TCHAR} ds:[di - size TCHAR], cx		>
		jmp	nextLevel

bottomReached:
		clc
done:
		.leave
		ret
CreateSubdirs	endp


DocOpenClose ends
