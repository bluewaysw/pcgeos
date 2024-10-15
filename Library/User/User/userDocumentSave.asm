COMMENT @-----------------------------------------------------------------------

	Copyright (c) Globalpc 1988 -- All Rights Reserved

PROJECT:	Save most recently document names in a PRIVATE/ file.
MODULE:		
FILE:		genDocumentSave.asm

ROUTINES:
	Name			Description
	----			-----------
	GLB UserStoreDocFileName	Save file name, disk handle and
					path into a file in PRIVATE directory.
	GLB UserGetRecentDocFileName	Retrieve file information from the
					file in PRIVATE directory.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Edwin	11/9/98		Initial version

DESCRIPTION:

	$Id: $
	
-------------------------------------------------------------------------------@

;
;  DocumentEntry defines an array element about a file
;
DocumentEntry	struct
    DE_name		FileLongName	; file name
    DE_diskHandle	word		; disk handle
    DE_path		PathName	; path name
DocumentEntry	ends

;
;  DocumentArray is a type of an array of 10 DcoumentEntries
;
DocumentArray	type	 10 dup (DocumentEntry)
DocumentArrayLastElnt	type	 9 dup (DocumentEntry)

idata	segment
recntDocName		char	'recntDoc.vm',0	; file name that stores most
idata	ends					;  recently opened documents

UserSaveDocName	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	UserStoreDocFileName

DESCRIPTION:	Store the file name, disk handle, and path name into a 
		file in the PRIVATE directory.

CALLED BY:	EXTERNAL

PASS:		ss:bp - DocumentCommonParams

RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	11/98		Initial version
------------------------------------------------------------------------------@
UserStoreDocFileName	proc	far	uses bx, dx, ax, cx, ds
		.enter
	;
	; ss:bp - DocumentCommonParams
	;
	call	FilePushDir
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath

	segmov	ds, dgroup, dx
	mov	dx, offset recntDocName
	mov	al, FILE_ACCESS_RW or FILE_DENY_NONE
	call	FileOpen
	jnc	allocMem
	;
	;  To create a storage file.
	;
	mov	ax, FileAccessFlags <FE_NONE, FA_READ_WRITE> \
		    or (FILE_CREATE_TRUNCATE shl 8)
	mov	cx, FILE_ATTR_NORMAL
	call	FileCreate
	jc	done
	;
	;  adjust the file position to be at the beginning of the file.
	;	call	SetFileStartPos
allocMem:
	mov	dx, ax		; dx - file handle

	mov	ax, size DocumentArray
	inc	ax		; first byte is reserved for counter
	mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	jc	closeFile
	;
	; bx - handle of block allocated, ax - block address, dx - file handle
	; ss:bp - DocumentCommonParams
	;
	call	ReadFileIntoMem
	call	DeleteMatchedExistingEntry
	call	ReplaceEntryInMem
	jc	cantReplace
	call	WriteMemIntoFile
	call	MemFree
	jmp	closeFile
cantReplace:
	call	MemFree
	mov	bx, dx
	mov	al, FILE_NO_ERRORS
	call	FileClose
	mov	dx, offset recntDocName
	call	FileDelete
	jmp	done

closeFile:
	mov	bx, dx
	mov	al, FILE_NO_ERRORS
	call	FileClose
done:
	call	FilePopDir
		
		.leave
		ret
UserStoreDocFileName	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WriteMemIntoFile

DESCRIPTION:	Write the modified memory block into the file

CALLED BY:	INTERNAL

PASS:		ax - memory block address
		dx - file handle
RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	11/98		Initial version
------------------------------------------------------------------------------@
WriteMemIntoFile	proc	near	uses ax, bx, cx, dx, ds
	; ax - memory block address, dx - file handle
	.enter
	segmov	ds, ax			; ds:
	mov	bx, dx			; bx - file handle

	mov	al, FILE_POS_START
	clrdw	cxdx			; offset
	call	FilePos

	mov	cx, size DocumentArray
	inc	cx
	call	FileWrite		; ds:dx - buffer
	.leave
	ret
WriteMemIntoFile	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ReplaceEntryInMem

DESCRIPTION:	Write the DocumentEntry into the memory block, overwritting
		whatever was there.

CALLED BY:	INTERNAL

PASS:		ax - memory block address
		dx - file handle
		ss:bp - DocumentCommonParams
RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		The first byte of the file(or memory) is the index of element
		to be replaced.  The index is incremented after each of
		replacement procedure.  The index is reset to 0 when reaching
		10.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	11/98		Initial version
------------------------------------------------------------------------------@
ReplaceEntryInMem	proc	near	uses ax, bx, cx, dx, es, di, ds, si
	; ax - memory block address, dx - file handle
	; ss:bp - DocumentCommonParams
	.enter
	mov	es, ax
	clr	di
	mov	al, es:[di]	; First byte store the counter.
	cmp	al, 10		; The Counter is between 0 to 9, for 10 entries
	jae	error
	mov	dl, size DocumentEntry
	mul	dl
	cmp	ax, DocumentArrayLastElnt
	ja	error		; Can't be beyond the 10th starting position
	inc	ax		; Reserve the very first byte for the counter.
	mov	di, ax		; es:di - target address to store the info.
	;
	;  Erase the entry first
	;
	mov	cx, size DocumentEntry
	clr	bx

	mov	dx, size DocumentArray
	inc	dx
eraseEntry:
	jcxz	doneErase
	cmp	di, dx
EC <	ERROR_AE -1					>
	jae	error			; jump if out of bound!  Error!
	mov	es:[di], bl		; erase one char at a time
	inc	di
	dec	cx
	jmp	eraseEntry
doneErase:
	mov	di, ax		; es:di - target address to store the info.
	;
	;  Copy the FileLongName
	;
	segmov	ds, ss
	lea	si, ss:[bp].DCP_name	; ds:si - address of FileLongName
	call	GetStringLenInDSSI
	cmp	cx, size FileLongName
	jae	error
	rep	movsb
	;
	;  Copy the disk handle
	;
	lea	si, ss:[bp].DCP_diskHandle	; ds:si - address of diskHandle
	add	ax, size FileLongName		; jump to the disk handle field
	mov	di, ax				; es:di - targeted address
	mov	cx, size word
	rep	movsb
	;
	;  Copy the path name
	;
	lea	si, ss:[bp].DCP_path	; ds:si - address of path name
	add	ax, size word		; jump to the PathName field
	mov	di, ax			; es:di - targeted address
	call	GetStringLenInDSSI
	cmp	cx, size PathName
	jae	error
	rep	movsb
	;
	;  Increment the counter
	;
	mov	al, es:[0]	; First byte store the counter.
	inc	al
	cmp	al, 10
	ja	error
	jb	ok
	clr	al
ok:
	mov	es:[0], al
	clc
	jmp	done
error:
EC <	ERROR_AE -1					>
	stc
done:
	.leave
	ret
ReplaceEntryInMem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteMatchedExistingEntry

DESCRIPTION:	If the file that user wants to load already exists in the
		most-recently-opened-doc list, then delete it, and compact
		remaining DocumentEntries.

CALLED BY:	INTERNAL

PASS:		ax - memory block address
		dx - file handle
		ss:bp - DocumentCommonParams
RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	11/98		Initial version
------------------------------------------------------------------------------@
DeleteMatchedExistingEntry	proc	near	uses ax, bx, cx, dx, es, di, ds, si
	; ax - memory block address, dx - file handle
	; ss:bp - DocumentCommonParams
	.enter
	mov	es, ax
	clr	di
	;
	; es:di memory block
	clr	ax		; let ax be the index.
nxtloop:
	cmp	ax, 10		; The Counter is between 0 to 9, for 10 entries
	jae	done
	push	ax		; push index
	mov	dl, size DocumentEntry
	mul	dl
	mov	di, ax
	pop	ax		; pop index
	cmp	di, DocumentArrayLastElnt
	ja	done		; Can't be beyond the 10th starting position
	inc	di		; Remember, the first byte in the block is counter
	;
	;  Compare the strings between the passed param and in the memory.
	;
	segmov	ds, ss
	lea	si, ss:[bp].DCP_name	; ds:si - address of FileLongName
	mov	dx, di
	lea	di, es:[di].DE_name
	cmp	cx, size FileLongName
	call	LocalCmpStrings
	jz	same
	inc	ax		; Increment the index
	jmp	nxtloop
same:
	clr	bx
	mov	bl, es:[0]
	cmp	bx, ax
	je	done		; skip if overidden entry is same as duplicate entry
	segmov	ds, es		; Now we're moving entries around in memory
moveNextEntry:
	;
	; ax-duplicated entry index. es:[0]-index for the overwriting entry.
	;
	tst	ax
	jz	goTenth
	mov	si, ax
	dec	si			; si - previous entry's index
	jmp	gotIndices
goTenth:
	mov	si, 9			; si - otherwise, get 10th entry's index
gotIndices:
	mov	bx, si
	mov	dl, size DocumentEntry
	mul	dl	
	inc	ax
	mov	di, ax			; di - address of erased entry.
	mov	ax, si
	mul	dl
	inc	ax
	mov	si, ax			; si - address of previous entry.
	;
	;  Move the si entry to the di entry.
	;
	mov	cx, size DocumentEntry
	rep	movsb
	clr	ax
	mov	al, es:[0]
	cmp	bx, ax			; stop when we reach the starting point
	je	done
	mov	ax, bx
	jmp	moveNextEntry
done:
	.leave
	ret
DeleteMatchedExistingEntry	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ReadFileIntoMem

DESCRIPTION:	Read the most-recently-opened document into a memory block

CALLED BY:	INTERNAL

PASS:		ax - block address
		dx - file handle
RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	11/98		Initial version
------------------------------------------------------------------------------@
ReadFileIntoMem	proc	near	uses ax, bx, cx, dx, ds, bp
	; ax - block address, dx - file handle
	.enter
	mov	cx, size DocumentArray
	inc	cx		; The first byte is used to store counter.
	mov	bx, dx		; bx - file handle
	segmov	ds, ax
	clr	dx		; ds:dx - buffer
	clr	ax
	mov	bp, cx		; bp - number of bytes to be read	
readMore:
	call	FileRead
	; cx - number of bytes read
	add	dx, cx
	clr	ax
	jcxz	done
	cmp	dx, bp
	jae	done
	mov	cx, bp
	sub	cx, dx
	jmp	readMore
done:
	.leave
	ret
ReadFileIntoMem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetStringLenInDSSI

DESCRIPTION:	Get string length in ds:si

CALLED BY:	INTERNAL

PASS:		none

RETURN:		cx - length

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	11/98		Initial version
------------------------------------------------------------------------------@
GetStringLenInDSSI	proc	near	uses ax, es, di
	; ds:si - string
	.enter
	segmov	es, ds
	mov	di, si
	LocalStrLength includeNull
	.leave
	ret
GetStringLenInDSSI	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	SetFileStartPos

DESCRIPTION:	Set File Pos

CALLED BY:	INTERNAL

PASS:		none

RETURN:		none

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	11/98		Initial version
------------------------------------------------------------------------------@
SetFileStartPos	proc	near	uses ax, cx, dx 
	; ax - file handle
	.enter
	mov	bx, ax
	mov	al, FILE_POS_START
	clrdw	cxdx
	call	FilePos
	.leave
	ret
SetFileStartPos	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserGetRecentDocFileName

DESCRIPTION:	Open the most-recently-opened-doc file, read its content into
		memory block and return the block handle and locked address.

CALLED BY:	INTERNAL

PASS:		none

RETURN:		bp   - memory block handle
		esdi - locked block address
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	11/98		Initial version
------------------------------------------------------------------------------@
UserGetRecentDocFileName	proc	far	uses ax, bx, cx, dx, ds, si
	; RETURN:  bp   - memory block handle
	;          esdi - locked block address
	.enter
	call	FilePushDir
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath

	segmov	es, ds		; now es:si - buffer to store the fileName
	segmov	ds, dgroup, dx
	mov	dx, offset recntDocName
	mov	al, FILE_ACCESS_R or FILE_DENY_W
	call	FileOpen
	pushf
	clr	bp
	segmov	es, 0, di
	clr	di
	popf
	jc	done
	;
	;  To create a storage memory.
	;
	call	SetFileStartPos
	mov	dx, ax		; dx - file handle

	mov	ax, size DocumentArray
	inc	ax		; extra byte for the counter
	mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8) or mask HF_SHARABLE
	call	MemAlloc
	mov	bp, bx
	jc	closeFile
	;
	; bx - handle of block allocated, ax - block address, dx - file handle
	;
	call	ReadFileIntoMem
	mov	es, ax
	clr	di		; es:di - buffer to return
closeFile:
	mov	bx, dx
	mov	al, FILE_NO_ERRORS
	call	FileClose
done:
	call	FilePopDir
	.leave
	ret
UserGetRecentDocFileName	endp


UserSaveDocName	ends
