	COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Kernel/Initfile
FILE:		initfileHigh.asm

AUTHOR:		Cheng, 11/89

ROUTINES:
	Name			Description
	----			-----------
	InitFilePushPrimaryFile
	InitFilePopPrimaryFile

	InitFileReadData
	InitFileReadString
	InitFileReadBoolean
	InitFileReadInteger
	InitFileReadStringSection
	InitFileEnumStringSection
	InitFileRead
	InitFileGetTimeLastModified

	InitFileWriteData
	InitFileWriteString
	InitFileWriteInteger
	InitFileWriteBoolean
	InitFileWriteStringSection
	InitFileWrite

	InitFileDeleteStringSection
	InitFileDeleteEntry
	InitFileDeleteCategory

	InitFileSave
	InitFileRevert
	INITFILECOMMIT

    	InitFileSetPrimaryFile

	InitFileBackupLanguage	Backup the current .INI file to the
				appropriate language patch directory,
				so it could be restored later.
	InitFileSwitchLanguages	Delete the current .ini file buffer,
				and load a new buffer with the .ini
				file last used for the newly specified
				language.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial revision
	PJC	1/25/95		Added multi-language code.

DESCRIPTION:
	The init file is maintained as a text file for ease of
	support and modification.

	The init file manipulation code includes routines to read and write
	entries for future use. These entries are associated with 'keys'
	and these keys are organized under 'categories'. Ie.

		[category]
		key1 = key1 entry
		key2 = key2 entry
		...

 	For flexibility, entries may contain carraige returns. These entries
	are referred to as 'blobs'. Blobs are automatically enclosed
	within curly braces and require no effort on the caller's part.
	In the event that the blob itself contains a curly brace, the brace
	is escaped by a backslash character. This again does not require
	any effort on the user's part. An example of blob conversion is:

	InitFileWriteString called with:
	    category:
		cat
	    key:
		key
	    body:
		body of blob
		which may span several lines
		and may contain braces ({,}) and backslash (\) characters

	The conversion code will transform the input into:
		[cat]
		key = {body of blob
		which may span several lines
		and may contain braces (\{,\}) and backslash (\\) characters}

	Data may be read and written as binary data. The manipulation code
	converts this data into the ASCII decimal for storage and converts
	it back into binary during retrieval.

IMPLEMENTATION ISSUES:
	Only a single thread is allowed to access the init file at any
	one time.

REGISTER USAGE:
	bp - dgroup
	es - whenever necessary, dgroup
	bx - init file handle

TO DO:
	A routine can be added to facilitate addition of comments.

	$Id: initfileHigh.asm,v 1.1 97/04/05 01:18:05 newdeal Exp $

-------------------------------------------------------------------------------@

include file.def
include Internal/patch.def

InitfileRead	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFilePushPrimaryFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:

Pass:		nothing

Return:		carry set if error

Destroyed:	nothing

Comments:

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 14, 1993 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFilePushPrimaryFile	proc	far
	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

	;
	;  Clean up any changes that may have been made before we
	;  grab the ini file semaphore
	;

		call	InitFileCommit

	;
	;  Make sure no one uses the .ini file from now on
	;

		call	LoadVarSegDS_PInitFile

	;
	;  Look for a .ini file in the top path
	;

		sub	sp, size PathName
		mov	di, sp
		segmov	es, ss				;es:di <- buffer
		segmov	ds, cs
		mov	si, offset initFileName
		mov	bx, SP_TOP
		call	FileConstructActualPath
		LONG jc	freePathBufferAndError

	;
	;  Open (and read) the new .INI file
	;

		segmov	ds, es
		mov	dx, di				;ds:dx <- filename
		mov	ax, mask FOARF_ADD_CRLF or mask FOARF_ADD_EOF \
				or FILE_ACCESS_RW or FILE_DENY_RW
		call	FileOpenAndRead
		LONG jc	freePathBufferAndError

		add	sp, size PathName

	;
	; Make the kernel own both returned handles, and make the
	; memory handle sharable.
	;
		mov	di, cx			; size
		mov	cx, bx			; file handle
		mov_tr	dx, ax			; memory handle

		mov	ax, handle 0
		call	HandleModifyOwner

		mov	bx, dx
		mov	ax, handle 0
		call	HandleModifyOwner

		mov	ax, mask HF_SHARABLE
		call	MemModifyFlags

	;
	;  Close the old file
	;

		LoadVarSeg	ds, ax
		mov	bx, ds:[loaderVars].KLV_initFileHan
		mov	al, FILE_NO_ERRORS
		call	FileCloseFar

	;
	;  Shift the .ini files in the buffer down a spot
	;

		mov	si, size hptr * (MAX_INI_FILES - 2)
shiftLoop:
		mov	ax, ds:[loaderVars][si].KLV_initFileBufHan
		mov	ds:[loaderVars][si+(size hptr)].KLV_initFileBufHan, ax
		dec	si
		dec	si
		jns	shiftLoop

	;
	;  Record the new info and unlock the buffer
	;

		mov	ds:[loaderVars].KLV_initFileHan, cx
		mov	ds:[loaderVars].KLV_initFileBufHan, dx
		mov	ds:[loaderVars].KLV_initFileSize, di
		clc			; success!

releaseSemaphore:
		pushf
		call	VInitFile
		popf

		.leave
		ret

freePathBufferAndError:
		LoadVarSeg	ds		;so we can VInitFile
		add	sp, size PathName	;clean up stack
		stc
		jmp	releaseSemaphore

InitFilePushPrimaryFile	endp


NEC<LocalDefNLString initFileName <"geos.ini", 0>			>
EC <LocalDefNLString initFileName <"geosec.ini", 0>			>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFilePopPrimaryFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:

Pass:		nothing

Return:		carry set if error

Destroyed:	nothing

Comments:

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 14, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFilePopPrimaryFile	proc	far
	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

	;
	;  Clean up any changes that may have been made before we
	;  grab the ini file semaphore
	;

		call	InitFileCommit

	;
	;  Make sure no one uses the .ini file from now on
	;

		call	LoadVarSegDS_PInitFile

	;
	;  Look for a .ini file in the top path
	;

		sub	sp, size PathName
		mov	di, sp
		segmov	es, ss				;es:di <- buffer
		segmov	ds, cs
		mov	si, offset initFileName
		mov	bx, SP_TOP
		call	FileConstructActualPath
		jc	freePathBufferAndError

	;
	;  Open the new .ini file
	;

		segmov	ds, es
		mov	dx, di				;ds:dx <- filename
		mov	al, FILE_ACCESS_RW or FILE_DENY_RW
		call	FileOpen
		jc	freePathBufferAndError
		add	sp, size PathName

	;
	;  Figure out the size of the ini file using FileSize instead
	;  of MemGetInfo, which rounds to the nearest paragraph...
	;

		mov_tr	bx, ax				; bx = new file handle
		call	FileSize			; dx:ax <- file size
		tst	dx
		jnz	error
		inc	ax				;include ^Z at end
							;of the buffer
	;
	;  OK, there's no longer a possibility of error, so close the
	;  old file and roll the buffers to the right place
	;

		push	bx, ax				;save file, size

	;
	;  Close the old file
	;

		LoadVarSeg	ds, ax
		mov	bx, ds:[loaderVars].KLV_initFileHan
		mov	al, FILE_NO_ERRORS
		call	FileCloseFar

	;
	;  Free the block containing the recently closed .ini file
	;

		mov	bx, ds:[loaderVars].KLV_initFileBufHan
		call	MemFree

	;
	;  Shift the .ini files in the buffer up a spot
	;

		clr	si
shiftLoop:
		mov	ax, ds:[loaderVars][si+(size hptr)].KLV_initFileBufHan
		mov	ds:[loaderVars][si].KLV_initFileBufHan, ax
		inc	si
		inc	si
		cmp	si, size hptr * (MAX_INI_FILES - 1)
		jb	shiftLoop

	;
	;  Clear out the last buffer
	;

		clr	ax
		mov	ds:[loaderVars][si].KLV_initFileBufHan, ax

	;
	;  Record the file handle and size of the new file, and make
	;  it owned by the kernel.
	;

		pop	bx, ax			;bx <- file handle
						;ax <- file size
		mov	ds:[loaderVars].KLV_initFileHan, bx
		mov	ds:[loaderVars].KLV_initFileSize, ax

		mov	ax, handle 0		; ax = handle of kernel
		call	HandleModifyOwner	; modify handle bx

	;
	;  We assume that the first buffer is already a copy of the file
	;  (since we called InitFileCommit at the beginning of
	;  InitFilePushPrimaryFile), so no need to do stuff here...
	;

releaseSemaphore:
		pushf
		call	VInitFile
		popf

	.leave
	ret

freePathBufferAndError:
		add	sp, size PathName	;clean up stack
error:
		stc
		jmp	releaseSemaphore
InitFilePopPrimaryFile	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileReadData

DESCRIPTION:	Locates the given identifier in the geos.ini file
		and returns a pointer to the body of the associated string.

CALLED BY:	GLOBAL

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		bp - if zero then
			routine will allocate a buffer to place entry in
		     else
			bp - buffer size
			es:di - buffer to fill

RETURN:		carry clear if successful
		cx - number of bytes retrieved (excluding null terminator)
		if bp was passed as 0,
		     bx = mem handle to block containing entry
		else
		     es:di - buffer filled
		     bx destroyed


DESTROYED:	bx, if bp was passed 0

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

InitFileReadData	proc	far	uses bp
	.enter
		andnf	bp, not mask IFRF_CHAR_CONVERT	; make sure we won't be
							;  confused by being told to
							;  upcase or downcase things
		mov	bx, IFOT_DATA
		call	InitFileRead
		mov	bx, bp
	.leave
	ret
InitFileReadData	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileReadString

DESCRIPTION:	Locates the given identifier in the geos.ini file
		and returns a pointer to the body of the associated string.

CALLED BY:	GLOBAL

PASS:		ds:si	- category ASCIIZ string
		cx:dx	- key ASCIIZ string
		bp	- InitFileReadFlags
				If IFRF_SIZE = 0
					Buffer will be allocated for string
				Else
			    		es:di - buffer to fill

RETURN:		carry	- clear if successful
		cx 	- number of chars retrieved (excluding null terminator)
			  cx = 0 if category / key not found

		bx	- mem handle to block containing entry (IFRF_SIZE = 0)
				- or -
		es:di	- buffer filled (IFRF_SIZE != 0)

DESTROYED:	bx (if not returned)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

------------------------------------------------------------------------------@

InitFileReadString	proc	far
	uses 	bp
	.enter

	mov	bx, IFOT_STRING
	call	InitFileRead
	jc	notFound
DBCS <	shr	cx, 1						>
DBCS <	EC <ERROR_C	ILLEGAL_INIT_FILE_STRING		>> ;odd size
	dec	cx			;don't include NULL size (preserve CF)
	mov	bx, bp			;block handle => BX
done:
	.leave
	ret
notFound:
	mov	cx, 0			; don't trash carry
	jmp	done

InitFileReadString	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	InitFileReadBoolean

DESCRIPTION:	Locates the given category and key in the geos.ini file
		and returns a boolean flag.

CALLED BY:	GLOBAL

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string

RETURN:		if found:
			carry clear
			ax    - ffffh = TRUE
				0 = FALSE
		if category/key not found
			carry set
			ax - unchanged

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	If the key contains a garbage string (ie, not TRUE or FALSE),
	then AX is destroyed, and carry is set.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

InitFileReadBoolean	proc	far 	uses bx,si,ds,es,bp
	.enter

	clr	bp
	call	EnterInitfileAndFindKey	;es,bp <- dgroup
	jc	exit

	clr	bx				;assume false

	mov	ax, es:[initFileBufPos]		;save buffer position
	mov	ds, bp				;ds <- dgroup
	mov	si, offset dgroup:[falseStr]	;ds:si <- "false"
	call	CmpString			;match
	jnc	checkValid

	dec	bx				;signal true
	mov	es:[initFileBufPos], ax
	mov	si, offset dgroup:[trueStr]
	call	CmpString
	jc	exit

	; make sure the matched string is terminated properly (e.g. it's
	; not "falsely" or something like that)
checkValid:
	call	GetChar
	dec	es:[initFileBufPos]
	cmp	al, ' '
	je	ok				;carry = clear
	cmp	al, '\t'
	je	ok				;carry = clear
	cmp	al, '\r'
	je	ok				;carry = clear
	cmp	al, '\n'
	je	ok				;carry = clear
	cmp	al, INIT_FILE_COMMENT
	je	ok				;carry = clear
	stc					;not valid, so signal error
	jmp	exit
ok:
	mov_tr	ax, bx				;ax <- return value
exit:
	call	ExitInitfileGet
	.leave
	ret
InitFileReadBoolean	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileReadInteger

DESCRIPTION:	Locates the given identifier in the geos.ini file
		and returns a pointer to the body of the associated string.

CALLED BY:	GLOBAL

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string

RETURN:		carry clear if successful
		     ax - value
		else carry set
		     ax - unchanged

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

InitFileReadInteger	proc	far
		uses bx, dx,di,si,ds,es,bp
		.enter

		clr	bp			; no InitFileReadFlags
		call	EnterInitfileAndFindKey	; es,bp <- dgroup
		jc	exit

		call	AsciiToHex		; dx,al <- func(es,bp)
		mov_tr	ax, dx
exit:
		call	ExitInitfileGet

		.leave
		ret
InitFileReadInteger	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileReadAllInteger

DESCRIPTION:	Calls callback routine for integer in all .ini files.

CALLED BY:	GLOBAL

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		di:ax - Callback routine (fptr)
		es, bx - Data to pass to callback

RETURN:		es, bx - Data from callback
		carry - Set if callback returned carry set

		For callback routine (must be delcared as far):
			PASS:		ax - integer
					es, bx - Data

			RETURN:		es, bx - Data
					carry - Clear (continue enumeration)
					      - Set (stop enumeration)

			MAY DESTROY:	ax, cx, dx, di, si, bp, ds

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/3/94		Initial version

-------------------------------------------------------------------------------@

if DBCS_PCGEOS
InitFileReadAllInteger	proc	far
		uses ax, cx, dx,di,si,ds,es,bp
		.enter

		push	es
		mov	bp, mask IFRF_READ_ALL
		call	EnterInitfileAndFindKey	; es,bp <- dgroup
		jc	exit
startLoop:
		push	ax, dx			; save routine, key offsets
		call	AsciiToHex		; dx,al <- func(es,bp)
		mov	ss:[TPD_dataAX], dx	; pass integer in AX
		pop	ax, dx			; restore routine, key offsets
		jc	next

		mov	ss:[TPD_dataBX], bx	; pass to callback
		; passed ES on top of stack
		pop	es			; ES = passed ES
		push	es
		push	ax, cx, dx, di, bp, ds
		mov	bx, di			; routine segment
		call	ProcCallFixedOrMovable
		pop	ax, cx, dx, di, bp, ds
		; dgroup on top of stack
		pop	bp			; nuke old passed ES
		push	es			; save new passed ES
		LoadVarSeg	es, bp		; es = bp = dgroup

		jc	exit
next:
		call	GetNextInitFileAndFindKey
		jnc	startLoop
		clc				; indicate no more .ini files
exit:
		pop	es			; clean up stack
		call	ExitInitfileGet		; (preserves flags)

		.leave
		ret
InitFileReadAllInteger	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileReadStringSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locates the given category and key in the geos.ini file
		and returns a handle to a null-terminated copy of one
		of the string sections in the string body

CALLED BY:	GLOBAL

PASS:		DS:SI	= Category ASCIIZ string
		CX:DX	= Key ASCIIZ string
		AX	= 0-based integer signifying which string section
		BP	= InitFileReadFlags
				If IFRF_SIZE = 0
					Buffer will be allocated for string
				Else
			    		ES:DI	= Buffer to fill

RETURN:		Carry	= Clear if successful
		CX	= Number of bytes retrieved (excluding null terminator)
		BX	= Handle to block containing string (if IFRF_SIZE = 0)
				- or -
		ES:DI	= Buffer filled with string (IFRF_SIZE != 0)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		We're going to do this in stupid fashion:
			Get the entire string
			Find out part of the string
			Copy it to the desired buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The buffer that is allocated does not get resized downward
		from its original size (holding the entire string denoted
		by the category & key). Since the buffer shouldn't be around
		too long, I hope this isn't a problem.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 9/90	Initial version
	don	1/21/92		Optimized, I hope

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFileReadStringSection	proc	far
	uses	ax, dx, di, si, bp, ds, es
	.enter

	; Get entire string
	;
	push	bp				; save flags
	andnf	bp, not (mask IFRF_SIZE)	; always allocate
if INI_STRING_SECTION_TOMBSTONES
	call	InitFileReadMergedStringSection
else
	call	InitFileReadString
endif
	pop	bp				; restore flags
	jc	done				; if error, we're done

	; Get ptr to requested string section
	;
	mov_tr	dx, ax				; section index => DX
	call	MemLock				; lock the returned string
	mov	ds, ax				; string => DS:SI
	clr	si
	call	GetStringSectionByIndex
	jc	free

	; Determine whether a block was passed or one needs to be allocated.
	; If block was passed make sure it is big enough
	;
	and	bp, mask IFRF_SIZE		; size => BP
	jz	allocate			; if zero, then allocate
	cmp	bp, cx				; else compare the sizes
	jb	free				; carry is set, folks

	; Copy string section to destination block and null terminate it,
	; and unlock allocated block if it exists.
copyString:
	push	cx				; save the length
	Assert	okForRepMovsb
if DBCS_PCGEOS
	rep 	movsw				; copy the string
	clr	ax				; null terminate the sucker
	stosw
else
	rep 	movsb				; copy the string
	clr	al				; null terminate the sucker
	stosb
endif
	pop	cx				; restore the length
	call	MemUnlock			; unlock the buffer
	tst	bp				; did we need to allocate ??
	jz	done				; yes, so we're done
free:
	pushf					; save carry flag
	call	MemFree				; else free the buffer
	popf					; restore carry flag
done:
	.leave
	ret

	; If we're allocating, just copy the string to the top of the buffer
allocate:
	segmov	es, ds
	clr	di				; destination buffer => ES:DI
	jmp	copyString			; go copy the string
InitFileReadStringSection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileEnumStringSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate a string section, calling the passed function
		for every string found.

CALLED BY:	GLOBAL

PASS:		DS:SI	= Category ASCIIZ string
		CX:DX	= Key ASCIIZ string
		BP	= InitFileReadFlags (IFRF_SIZE is of no importance)
		DI:AX	= Callback routine (fptr)
		BX, ES	= Data to pass to callback

RETURN:		BX, ES	= Data from callback
		Carry	= Set if callback returned carry set

DESTROYED:	Nothing

		For callback routine (must be delcared as far):
			PASS:		DS:SI	= String section
						  (null-terminated)
					DX	= Section #
					CX	= Length of section
					ES, BX	= Data

			RETURN:		BX, ES	= Data
					Carry	= Clear (continue enumeration)
						= Set (stop enumeration)

			MAY DESTROY:	AX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFileEnumStringSection	proc	far
	uses	ax, cx, dx, di, si, bp, ds
	.enter

	; Get entire string
	;
	push	bx				; save passed data
	andnf	bp, not (mask IFRF_SIZE)	; always allocate
if INI_STRING_SECTION_TOMBSTONES
	call	InitFileReadMergedStringSection
else
	call	InitFileReadString
endif
	pop	dx				; data => DX
	cmc
	jnc	done				; if error, we're done
	push	bx				; save string handle
	mov	bp, ax				; callback => DI:BP
	call	MemLock				; lock the returned string
	mov	ds, ax				; string segment => DS
	mov	bx, dx

	; Now loop until we're done
	;
	mov_tr	ax, cx				; buffer size => AX
	clr	dx				; start with the first string
enumLoop:
	clr	si				; start of strings => DS:SI
	push	ax				; save number of characters
	mov_tr	cx, ax				; number of charcters => CX
	push	dx				; save index #
	call	GetStringSectionByIndex		; string => DS:SI
	pop	dx				; restore index #
	jc	cleanUpNoCarry			; if not found, we're done

	mov	ss:[TPD_dataBX], bx		; set for passing to callback
	mov	bx, cx
DBCS <	shl	bx, 1				; offset for NULL	>
SBCS <	clr	al							>
DBCS <	clr	ax							>
SBCS <	xchg	ds:[si][bx], al			; null-terminate and fetch EOS>
DBCS <	xchg	ds:[si][bx], ax			; null-terminate and fetch EOS>
SBCS <	push	ax, cx, dx, di, si, bp, ds				>
DBCS <	push	ax, bx, dx, di, si, bp, ds	; save byte offset	>
	mov_tr	ax, bp				; offset => AX
	mov	bx, di				; segment => BX
	call	ProcCallFixedOrMovable		; call the callback routine
	pop	ax, cx, dx, di, si, bp, ds
	xchg	bx, cx				; bx <- offset, cx <- caller
						;  data
SBCS <	mov	ds:[si][bx], al			; restore actual EOS character>
DBCS <	mov	ds:[si][bx], ax			; restore actual EOS character>
	mov	bx, cx				; restore caller data
	jc	cleanUp				; LEAVE CARRY SET SO CALLER
						;  KNOWS CALLBACK RETURNED IT
						;  SO
	pop	ax				; restore number of characters
	inc	dx				; go to the next string section
	jmp	enumLoop

	; Clean up things
cleanUpNoCarry:
	clc
cleanUp:
	pop	ax				; clean up the stack
	mov	dx, bx
	pop	bx
	lahf
	call	MemFree
	sahf
done:
	mov	bx, dx
	.leave
	ret
InitFileEnumStringSection	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	InitFileRead

DESCRIPTION:	Common routine for fetching data/strings

CALLED BY:	InitFileReadString, InitFileReadData

PASS:		bx 	- string/data specifier
				0  = data
		     		!0 = string
		ds:si	- category ASCIIZ string
		cx:dx	- key ASCIIZ string
		bp	- InitFileReadFlags
				if IFRF_SIZE != 0
					es:di - buffer to fill
				else
					allocate a buffer to place entry in

RETURN:		if error
			carry set
		else
			carry clear
			bp - buffer handle (if buffer allocated)
			cx - size of data read


DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

------------------------------------------------------------------------------@

InitFileRead	proc	near

	uses ax, bx, di, si, ds, es

	.enter

	test	bp, mask IFRF_READ_ALL
	jnz	readAll

	push	bx
	call	EnterInitfileAndFindKey
	jc	error

	;----------------------------------------------------------------------
	;does user want us to use passed buffer or does he want us
	; to allocate one?

	mov	cx, es:[bufFlag]
	and	cx, mask IFRF_SIZE	;isolate buffer size field
	je	provideBuf

	les	di, es:[bufAddr]
	pop	bx			;fetch operation specifier
	call	DoReconstruct
	clr	bp			;(clears carry)
	jmp	exit

error:
	pop	bx			;discard operation specifier
	jmp	exit

readAll:
	call	InitFileReadAll
	jmp	exit

provideBuf:
	;----------------------------------------------------------------------
	;user wants us to create buffer
	;initFileBufPos points to first char in body
	;find out size of body

	call	GetBodySize		;ax,cx <- func(es, bp)
	mov	es:[initFileBufPos], cx	;reset pos

	;----------------------------------------------------------------------
	;allocate buffer

	inc	ax			; one extra for null-terminator
DBCS <	inc	ax							>

	push	ax
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	pop	cx			;cx = size of buffer
	jc	error			;if cannot allocate buffer, return
					;that we didn't find entry

	mov	es, ax			;es:di <- buffer
	clr	di

	pop	ax			;fetch operation
	push	bx			;save handle
	xchg	ax, bx			;(1-byte inst)

	call	DoReconstruct
	pop	bx			;retrieve handle

	call	MemUnlock		;func(bx)

	push	cx
	mov_tr	ax, cx			;resize the buffer
	mov	ch, mask HAF_NO_ERR	;its getting smaller
	call	MemReAlloc
	pop	cx
	mov	bp, bx
	clc				;return no error
exit:
	call	ExitInitfileGet
	.leave
	ret

InitFileRead	endp

if INI_STRING_SECTION_TOMBSTONES

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileReadMergedStringSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read lower string-section data, remove disabled entries,
		and append primary local entries.

CALLED BY:	InitFileReadStringSection, InitFileEnumStringSection

PASS:		ds:si - category
		cx:dx - key
		bp - InitFileReadFlags

RETURN:		carry set on error
		else bx - block handle, cx - size including null

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileReadMergedStringSection	proc	far
	uses	ax, dx, di, si, ds, es
readFlags	local	InitFileReadFlags	push	bp
catString	local	fptr.char	push	ds, si
keyString	local	fptr.char	push	cx, dx
factoryHan	local	hptr
factorySize	local	word
localHan	local	hptr
localSize	local	word
disabledHan	local	hptr
disabledSize	local	word
sidecarCategory	local	MAX_INITFILE_CATEGORY_LENGTH dup (char)
sidecarKey	local	MAX_INITFILE_CATEGORY_LENGTH dup (char)
		.enter

		test	ss:[readFlags], mask IFRF_FIRST_ONLY
		LONG	jnz	readOne

		call	InitFileHaveLowerIniFile
		LONG	jnc	readOne

		push	ds, si, cx, dx
		segmov	es, ss
		lea	di, ss:[sidecarCategory]
		mov	bx, es
		lea	ax, ss:[sidecarKey]
		call	InitFileBuildDisabledKey
		pop	ds, si, cx, dx
		LONG	jc	readOne

		push	bp
		mov	bp, ss:[readFlags]
		andnf	bp, not (mask IFRF_SIZE)
		call	InitFileReadLowerString
		pop	bp
		jc	readOne
		tst	bx
		jz	readOne

		inc	cx			; count the terminating null
		mov	ss:[factoryHan], bx
		mov	ss:[factorySize], cx
		clr	ax
		mov	ss:[localHan], ax
		mov	ss:[localSize], ax
		mov	ss:[disabledHan], ax
		mov	ss:[disabledSize], ax

		segmov	ds, ss
		lea	si, ss:[sidecarCategory]
		mov	cx, ds
		lea	dx, ss:[sidecarKey]
		push	bp
		mov	bp, mask IFRF_FIRST_ONLY
		call	InitFileReadString
		pop	bp
		jc	noDisabled
		inc	cx
		mov	ss:[disabledHan], bx
		mov	ss:[disabledSize], cx
noDisabled:
		lds	si, ss:[catString]
		movdw	cxdx, ss:[keyString]
		push	bp
		mov	bp, mask IFRF_FIRST_ONLY
		call	InitFileReadString
		pop	bp
		jc	noLocal
		inc	cx
		mov	ss:[localHan], bx
		mov	ss:[localSize], cx
noLocal:
		mov	bx, ss:[factoryHan]
		mov	cx, ss:[factorySize]
		mov	ax, ss:[localHan]
		mov	dx, ss:[localSize]
		mov	si, ss:[disabledHan]
		mov	di, ss:[disabledSize]
		call	InitFileBuildMergedStringBlock
		jc	readOne

		dec	cx			; match InitFileReadString return value
		clc
done:
		.leave
		ret

readOne:
		push	bp
		mov	bp, ss:[readFlags]
		call	InitFileReadString
		pop	bp
		jmp	done
InitFileReadMergedStringSection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileHaveLowerIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether the active INI chain has a lower file.

RETURN:		carry set if there is a lower INI file

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileHaveLowerIniFile	proc	far
	uses	ax, ds
	.enter

	LoadVarSeg	ds, ax
	tst	ds:[loaderVars].KLV_initFileBufHan[2]
	jz	noLower
	stc
	jmp	done

noLower:
	clc
done:
	.leave
	ret
InitFileHaveLowerIniFile	endp

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileReadLowerString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a string from lower INI files only.

PASS:		ds:si - category
		cx:dx - key
		bp - InitFileReadFlags

RETURN:		carry set on error
		else bx - block handle, cx - size excluding null

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileReadLowerString	proc	far

	call	InitFileReadLowerAll
	pushf
	push	bx, cx
	call	ExitInitfileGet
	pop	bx, cx
	popf
	jc	notFound
	tst	bx
	jz	nullHandle
DBCS <	shr	cx, 1							>
DBCS <	EC <ERROR_C	ILLEGAL_INIT_FILE_STRING			>> ;odd size
	dec	cx			; don't include NULL size
	jmp	done

nullHandle:
	stc
notFound:
	mov	cx, 0			; don't trash carry
done:
	ret
InitFileReadLowerString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileEnterLowerAndFindKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a key starting at the first lower INI file.

PASS:		ds:si - category
		cx:dx - key
		bp - InitFileReadFlags

RETURN:		carry set if key was not found
		else es,bp - dgroup and current lower file locked

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileEnterLowerAndFindKey	proc	near
	uses	ax, bx
	.enter

	call	EnterInitfile		; locks primary .ini file
	mov	es:[initFileHanLocked], 0
	mov	bx, offset loaderVars.KLV_initFileBufHan
	push	bx
	mov	bx, es:[bx]
	call	MemUnlock
	pop	bx
	add	bx, size word

searchLoop:
	cmp	bx, (offset loaderVars.KLV_initFileBufHan)+ \
				((size word)*MAX_INI_FILES)
	je	error
	cmp	{word} es:[bx], 0
	je	error

if HASH_INIFILE
	mov	ax, bx
	sub	ax, offset loaderVars.KLV_initFileBufHan
	mov	es:[currentIniOffset], ax
endif

	push	bx
	mov	bx, es:[bx]
	call	MemLock
	pop	bx
	mov	es:[initFileBufSegAddr], ax
	mov	es:[curCatOffset], CATEGORY_NOT_CACHED

	call	FindCategory
	jc	notFound
	call	FindKey
	jnc	doneGood
notFound:
	push	bx
	mov	bx, es:[bx]
	call	MemUnlock
	pop	bx
	add	bx, size word
	jmp	searchLoop

error:
	stc
	jmp	done

doneGood:
	mov	ax, es:[bx]
	mov	es:[initFileHanLocked], ax
	clc
done:
	.leave
	ret
InitFileEnterLowerAndFindKey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFilePendingRewriteIsLowerBlob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the pending rewrite target is a lower string section.

RETURN:		carry set if the lower key body starts with a blob

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFilePendingRewriteIsLowerBlob	proc	far
	uses	ax, bx, cx, dx, si, bp, ds, es
	.enter

	LoadVarSeg	ds, ax
	mov	si, offset dgroup:[rewriteCategory]
	mov	cx, ds
	mov	dx, offset dgroup:[rewriteKey]
	push	bp
	clr	bp
	call	InitFileEnterLowerAndFindKey
	pop	bp
	jnc	haveLowerKey
	call	ExitInitfileGet
	jmp	notBlob

haveLowerKey:
	clr	bx			; not starting in blob
	call	GetCharFar
	pushf
	call	ExitInitfileGet
	popf
	jc	notBlob
	cmp	al, '{'
	jne	notBlob
	stc
	jmp	done

notBlob:
	clc
done:
	.leave
	ret
InitFilePendingRewriteIsLowerBlob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileReadLowerAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read one or all matching lower INI entries.

PASS:		ds:si - category
		cx:dx - key
		bp - InitFileReadFlags

RETURN:		carry set on error
		else bp - buffer handle, cx - size including null

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileReadLowerAll	proc	near

	clr	ax

readFlags	local	InitFileReadFlags	push	bp
bufferHandle	local	hptr	push	ax
bufferSize	local	word	push	ax
bufferCurPtr	local	nptr.byte	push	ax
keyString	local	fptr.char	push	cx, dx

	.enter

	push	bp
	mov	bp, ss:[readFlags]
	andnf	bp, not mask IFRF_FIRST_ONLY
	call	InitFileEnterLowerAndFindKey
	pop	bp
	LONG jc	done

startLoop:
	push	bp
	mov	bp, es
	call	GetBodySize		; ax,cx <- func(es, bp)
	pop	bp
	mov	es:[initFileBufPos], cx	; reset pos
SBCS <	add	ax, 2			 > 	; make sure there's enough for
DBCS <	add	ax, 2*(size wchar)	 > 	; make sure there's enough for
						; a CR/LF pair
	add	ax, ss:[bufferSize]
	mov	ss:[bufferSize], ax
	mov	bx, ss:[bufferHandle]

	tst	bx
	jnz	reAlloc

	push	ax			; buffer size
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	pop	cx			; cx = size of buffer
	jc	done

	mov	ss:[bufferHandle], bx
	jmp	afterAlloc

reAlloc:
	clr	cx
	call	MemReAlloc
	jc	doneUnlock

afterAlloc:
	push	es
	mov	es, ax
	mov	di, ss:[bufferCurPtr]
	mov	bx, IFOT_STRING

	mov	cx, ss:[bufferSize]
	sub	cx, di
	push	bp
	mov	bp, segment dgroup
	call	DoReconstruct		; cx <- number of bytes used
	pop	bp

	clr	ax
	add	di, cx
DBCS <	shr	cx, 1							> ; # bytes -> # chars
DBCS <	EC <ERROR_C	ILLEGAL_INIT_FILE_STRING			>>
	LocalPrevChar	esdi		; es:di = end of string
	std
	LocalFindChar			; es:di = before null
DBCS <	shl	cx, 1							> ; # chars -> # bytes
	cld
	LocalNextChar	esdi		; es:di = null
SBCS <	mov	{word} es:[di], (C_LF shl 8) or C_CR			>
SBCS <	add	cx, 2							>
DBCS <	mov	{wchar} es:[di], C_CARRIAGE_RETURN			>
DBCS <	mov	{wchar} es:[di]+2, C_LINE_FEED				>
DBCS <	add	cx, 4							>

	pop	es
	add	ss:[bufferCurPtr], cx

	test	ss:[readFlags], mask IFRF_READ_ALL
	jz	finish

	movdw	cxdx, ss:[keyString]
	call	GetNextInitFileAndFindKey
	LONG jnc	startLoop
	clc

finish:
	mov	bx, ss:[bufferHandle]
	mov	es, es:[bx].HM_addr
	mov	di, ss:[bufferCurPtr]
SBCS <	mov	{byte} es:[di-2], 0			>
DBCS <	mov	{wchar} es:[di-4], 0			>

SBCS <	lea	cx, es:[di-1]				> ; include the null
DBCS <	lea	cx, es:[di-2]				> ; include the null

doneUnlock:
	call	MemUnlock

done:
	mov	bx, ss:[bufferHandle]
	.leave
	mov	bp, bx			; buffer handle
	ret
InitFileReadLowerAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileBuildMergedStringBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build factory-minus-disabled-plus-local string-section blob.

PASS:		bx - factory block handle
		cx - factory size including null
		ax - local block handle, or zero
		dx - local size including null
		si - disabled block handle, or zero
		di - disabled size including null

RETURN:		bx - merged block handle
		cx - merged size including null
		carry set if no factory block was passed

DESTROYED:	ax,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileBuildMergedStringBlock	proc	near
factoryHan	local	hptr
factorySize	local	word
localHan	local	hptr
localSize	local	word
disabledHan	local	hptr
disabledSize	local	word
disabledSeg	local	sptr
outputHan	local	hptr
writeOffset	local	word
	.enter

	mov	ss:[factoryHan], bx
	mov	ss:[factorySize], cx
	mov	ss:[localHan], ax
	mov	ss:[localSize], dx
	mov	ss:[disabledHan], si
	mov	ss:[disabledSize], di

	tst	bx
	LONG	jz	noFactory

	clr	ax
	mov	ss:[disabledSeg], ax
	mov	ss:[writeOffset], ax

	mov	ax, ss:[factorySize]
	add	ax, ss:[localSize]
	add	ax, 2
DBCS <	shl	ax, 1							>
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	LONG	jc	allocFailed

	mov	ss:[outputHan], bx
	mov	es, ax

	mov	bx, ss:[disabledHan]
	tst	bx
	jz	noDisabled
	call	MemLock
	mov	ss:[disabledSeg], ax
noDisabled:
	mov	bx, ss:[factoryHan]
	call	MemLock
	mov	ds, ax
	mov	cx, ss:[factorySize]
	clr	dx
	mov	bx, ss:[disabledSeg]
	mov	ax, ss:[disabledSize]
	call	InitFileAppendFilteredStringBlock
	mov	ss:[writeOffset], dx
	mov	bx, ss:[factoryHan]
	call	MemUnlock
	mov	bx, ss:[factoryHan]
	call	MemFree

	mov	bx, ss:[localHan]
	tst	bx
	jz	noLocal
	call	MemLock
	mov	ds, ax
	mov	cx, ss:[localSize]
	mov	dx, ss:[writeOffset]
	clr	bx
	clr	ax
	call	InitFileAppendFilteredStringBlock
	mov	ss:[writeOffset], dx
	mov	bx, ss:[localHan]
	call	MemUnlock
	mov	bx, ss:[localHan]
	call	MemFree
noLocal:
	mov	bx, ss:[disabledHan]
	tst	bx
	jz	noDisabledUnlock
	call	MemUnlock
	mov	bx, ss:[disabledHan]
	call	MemFree
noDisabledUnlock:
	mov	di, ss:[writeOffset]
SBCS <	clr	al							>
SBCS <	stosb								>
DBCS <	clr	ax							>
DBCS <	stosw								>
SBCS <	lea	cx, es:[di]						>
DBCS <	mov	cx, di							>
DBCS <	shr	cx, 1							>
	mov	bx, ss:[outputHan]
	call	MemUnlock
	mov	bx, ss:[outputHan]
	clc
	jmp	done

allocFailed:
	mov	bx, ss:[localHan]
	tst	bx
	jz	noLocalFree
	call	MemFree
noLocalFree:
	mov	bx, ss:[disabledHan]
	tst	bx
	jz	returnFactory
	call	MemFree
returnFactory:
	mov	bx, ss:[factoryHan]
	mov	cx, ss:[factorySize]
	clc
	jmp	done

noFactory:
	mov	bx, ss:[localHan]
	tst	bx
	jz	noFactoryLocal
	call	MemFree
noFactoryLocal:
	mov	bx, ss:[disabledHan]
	tst	bx
	jz	noFactoryDisabled
	call	MemFree
noFactoryDisabled:
	stc
done:
	.leave
	ret
InitFileBuildMergedStringBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileAppendFilteredStringBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append source entries that are not disabled or duplicates.

PASS:		ds:0 - source blob
		cx - source size including null
		es:0 - output blob
		dx - current output size
		bx - disabled blob segment, or zero
		ax - disabled blob size including null

RETURN:		dx - new output size

	DESTROYED:	ax,cx,dx,di,si,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileAppendFilteredStringBlock	proc	near
	sourceSize	local	word	push	cx
	disabledSeg	local	sptr	push	bx
	disabledSize	local	word	push	ax
	writeOffset	local	word
	entryStart	local	word
	entryEnd	local	word
	entryLength	local	word
	entryRemaining	local	word
	.enter

	clr	si			; read offset
	mov	ss:[writeOffset], dx

filterLoop:
	mov	cx, ss:[sourceSize]
	call	GetStringSectionPtr	; ax <- length, ds:si entry, ds:di next
	tst	ax
	jz	finish

	mov	ss:[entryStart], si
	mov	ss:[entryEnd], di
	mov	ss:[entryLength], ax
	mov	ss:[entryRemaining], cx

	tst	ss:[disabledSeg]
	jz	notDisabled
	mov	cx, ss:[entryLength]
	push	ds, es
	mov	es, ss:[disabledSeg]
	mov	dx, ss:[disabledSize]
	call	InitFileStringSectionAlreadyWritten
	lahf
	pop	ds, es
	sahf
	jc	skipEntry
notDisabled:

	mov	si, ss:[entryStart]
	mov	cx, ss:[entryLength]
	mov	dx, ss:[writeOffset]
DBCS <	shr	dx, 1							>
	push	ds, es
	call	InitFileStringSectionAlreadyWritten
	lahf
	pop	ds, es
	sahf
	jc	skipEntry

	mov	si, ss:[entryStart]
	mov	cx, ss:[entryLength]
	mov	di, ss:[writeOffset]
	tst	di
	jz	copyEntry
SBCS <	mov	{byte} es:[di], C_CR					>
SBCS <	inc	di							>
SBCS <	mov	{byte} es:[di], C_LF					>
SBCS <	inc	di							>
DBCS <	mov	{wchar} es:[di], C_CARRIAGE_RETURN			>
DBCS <	add	di, 2							>
DBCS <	mov	{wchar} es:[di], C_LINE_FEED				>
DBCS <	add	di, 2							>
copyEntry:
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	mov	ss:[writeOffset], di

skipEntry:
	mov	si, ss:[entryEnd]
	mov	cx, ss:[entryRemaining]
	mov	ss:[sourceSize], cx
	jmp	filterLoop

finish:
	mov	dx, ss:[writeOffset]
	.leave
	ret
InitFileAppendFilteredStringBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileStringSectionAlreadyWritten
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current entry already exists in the output blob.

PASS:		ds:si - entry
		cx - entry length in chars
		es:0 - output blob
		dx - current output size in chars

RETURN:		carry set if duplicate

DESTROYED:	ax,bx,cx,dx,di
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileStringSectionAlreadyWritten	proc	far
	uses	si
entrySeg	local	sptr	push	ds
entryPtr	local	word	push	si
entryLen	local	word	push	cx
outputSize	local	word	push	dx
	.enter

	segmov	ds, es
	clr	si
	mov	cx, ss:[outputSize]
	jcxz	notFound
dupLoop:
	call	GetStringSectionPtr
	tst	ax
	jz	notFound
	cmp	ax, ss:[entryLen]
	jne	nextDup
	push	cx, si, di, ds, es
	mov	di, ss:[entryPtr]
	mov	es, ss:[entrySeg]
	mov	cx, ax
SBCS <	repe	cmpsb							>
DBCS <	repe	cmpsw							>
	pop	cx, si, di, ds, es
	stc
	je	done
nextDup:
	mov	si, di
	jmp	dupLoop

notFound:
	clc
done:
	.leave
	ret
InitFileStringSectionAlreadyWritten	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileBuildDisabledKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build category and key.disabled in caller storage.

PASS:		ds:si - category
		cx:dx - key
		es:di - destination category
		bx:ax - destination disabled key

RETURN:		carry set if name is too long

DESTROYED:	ax,bx,cx,dx,di,si,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileBuildDisabledKey	proc	far
keyString	local	fptr.char	push	cx, dx
disabledCat	local	fptr.char	push	es, di
disabledKeyDest	local	fptr.char	push	bx, ax
	.enter

		les	di, ss:[disabledCat]
		mov	bx, di
		add	bx, MAX_INITFILE_CATEGORY_LENGTH - 1
copyCategory:
		lodsb
		tst	al
		jz	categoryDone
		cmp	di, bx
		jae	tooLong
		stosb
		jmp	copyCategory

categoryDone:
		stosb
		lds	si, ss:[keyString]
		les	di, ss:[disabledKeyDest]
		mov	bx, di
		add	bx, MAX_INITFILE_CATEGORY_LENGTH - \
			    INITFILE_DISABLED_SUFFIX_LENGTH - 1
copyKey:
		lodsb
		tst	al
		jz	keyDone
		cmp	di, bx
		jae	tooLong
		stosb
		jmp	copyKey

keyDone:
		LoadVarSeg	ds, ax
		mov	si, offset dgroup:[disabledSuffix]
copySuffix:
		lodsb
		stosb
		tst	al
		jnz	copySuffix
		clc
		jmp	done

tooLong:
		les	di, ss:[disabledCat]
		clr	{byte}es:[di]
		les	di, ss:[disabledKeyDest]
		clr	{byte}es:[di]
		stc
done:
	.leave
	ret
InitFileBuildDisabledKey	endp

endif	; INI_STRING_SECTION_TOMBSTONES

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileReadAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the strings for a given category/key from ALL the
		init files into a single string.

CALLED BY:	InitFileRead

PASS:		ds:si - category
		cx:dx - key
		bp - InitFileReadFlags

RETURN:		if error
			carry set
		else
			carry clear
			bp - handle of buffer containing all the data
			cx - size of data read (including final null)

DESTROYED:	ax,bx,cx,dx,di,si

PSEUDO CODE/STRATEGY:
	Read each blob, and then terminate it with a CR/LF pair, so
	that the caller will see one huge blob.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileReadAll	proc near

	clr	ax

readFlags	local	InitFileReadFlags	push	bp
bufferHandle	local	hptr	push	ax
bufferSize	local	word	push	ax
bufferCurPtr	local	nptr.byte	push	ax
keyString	local	fptr.char	push	cx, dx

	.enter

	;
	; Clear the FIRST_ONLY flag, in case the caller was foolish
	; enough to pass it in (should probably fatal error in this
	; case?)
	;

	push	bp
	mov	bp, ss:[readFlags]
	andnf	bp, not mask IFRF_FIRST_ONLY
	call	EnterInitfileAndFindKey
	pop	bp
	LONG jc	done

startLoop:
	push	bp
	mov	bp, es
	call	GetBodySize		;ax,cx <- func(es, bp)
	pop	bp
	mov	es:[initFileBufPos], cx	;reset pos
SBCS <	add	ax, 2			; make sure there's enough for >
DBCS <	add	ax, 2*(size wchar)	; make sure there's enough for >
					; a CR/LF pair
	add	ax, ss:[bufferSize]
	mov	ss:[bufferSize], ax
	mov	bx, ss:[bufferHandle]

	tst	bx
	jnz	reAlloc
	;
	;allocate buffer
	;

	push	ax			; buffer size
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	pop	cx			;cx = size of buffer
	jc	done			;if cannot allocate buffer, return
					;that we didn't find entry

	mov	ss:[bufferHandle], bx
	jmp	afterAlloc

reAlloc:
	clr	cx
	call	MemReAlloc
	jc	doneUnlock		;branch if error to unlock

afterAlloc:
	push	es
	mov	es, ax
	mov	di, ss:[bufferCurPtr]
	mov	bx, IFOT_STRING

	;
	; DoReconstruct will probably use up less bytes than the
	; original, so make sure we update the CurPtr field correctly
	; afterwards.
	;

	mov	cx, ss:[bufferSize]
	sub	cx, di
	push	bp
	mov	bp, segment dgroup
	call	DoReconstruct		; #cx -  of bytes used.
	pop	bp
afterReconstruct::
	;
	; Back up to the NULL, and replace it with a CR/LF
	;
	clr	ax
	add	di, cx
DBCS <	shr	cx, 1							> ; # bytes -> # chars
DBCS <	EC <ERROR_C	ILLEGAL_INIT_FILE_STRING			>>
	LocalPrevChar	esdi		; es:di = end of string
	std
	LocalFindChar			; es:di = before null
DBCS <	shl	cx, 1							> ; # chars -> # bytes
	cld
	LocalNextChar	esdi		; es:di = null
SBCS <	mov	{word} es:[di], (C_LF shl 8) or C_CR			>
SBCS <	add	cx, 2							>
DBCS <	mov	{wchar} es:[di], C_CARRIAGE_RETURN			>
DBCS <	mov	{wchar} es:[di]+2, C_LINE_FEED				>
DBCS <	add	cx, 4							>

	pop	es
	add	ss:[bufferCurPtr], cx

	;
	; Now, move on to the next initfile
	;
	movdw	cxdx, ss:[keyString]
	call	GetNextInitFileAndFindKey
	LONG jnc	startLoop
	clc

	;
	; Well, no more strings -- nuke the last CR/LF we stored
	;

	mov	bx, ss:[bufferHandle]
	mov	es, es:[bx].HM_addr
	mov	di, ss:[bufferCurPtr]
SBCS <	mov	{byte} es:[di-2], 0					>
DBCS <	mov	{wchar} es:[di-4], 0					>

SBCS <	lea	cx, es:[di-1]						> ; include the null
DBCS <	lea	cx, es:[di-2]						> ; include the null

	;
	; Finally (and very importantly), unlock the block...
	;
doneUnlock:
	call	MemUnlock

done:
	.leave
	mov	bp, bx			; buffer handle
	ret
InitFileReadAll	endp




InitfileRead	ends



InitfileWrite	segment	resource

fileTerminationChar	char	C_CTRL_Z


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileGetTimeLastModified

DESCRIPTION:	Returns the time of the last write to the initfile.

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		cx:dx - system counter when initfile was last written to

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

InitFileGetTimeLastModified	proc	far	uses	ds
	.enter
	LoadVarSeg	ds, cx
	mov	cx, ds:[initfileLastModified].high
	mov	dx, ds:[initfileLastModified].low
	.leave
	ret
InitFileGetTimeLastModified	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileWriteData

DESCRIPTION:	Writes a string out to the geos.ini file.
		The string should be of the form
			[category]
			key = body of string
		The routine InitFileReadData can then be called with the
		category and key to locate the body of the string.

CALLED BY:	GLOBAL

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		es:di - buffer containing data
		bp - size of buffer

RETURN:		nothing

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

InitFileWriteData	proc	far	uses bx
	.enter
	mov	bx, IFOT_DATA
	call	InitFileWrite
	.leave
	ret
InitFileWriteData	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileWriteString

DESCRIPTION:	Writes a string out to the geos.ini file.
		The string should be of the form
			[category]
			key = body of string
		The routine InitFileReadString can then be called with the
		category and key to locate the body of the string.

CALLED BY:	GLOBAL

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		es:di - body ASCIIZ string

RETURN:		nothing

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

InitFileWriteString	proc	far	uses bx
	.enter
DBCS <	push	bp							>
if DBCS_PCGEOS
	push	cx
	call	LocalStringLength		; cx = num chars w/o null
	inc	cx				; cx = num char w/null
	shl	cx, 1				; cx = # bytes
	mov	bp, cx				; bp = # bytes
	pop	cx
else
	mov	bx, IFOT_STRING
endif
	call	InitFileWrite
DBCS <	pop	bp							>
	.leave
	ret
InitFileWriteString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileWriteInteger

DESCRIPTION:	Locates the given identifier in the geos.ini file
		and writes out the value.

CALLED BY:	GLOBAL

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		bp - value

RETURN:		carry clear if successful
		else carry set

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

InitFileWriteInteger	proc	far	uses ax,bx,di,es
	.enter
	LoadVarSeg	es, di
	mov	di, offset dgroup:[writeIntBuf]
	mov	ax, bp
	push	cx,di
	call	Hex16ToAscii		;es:di <- ASCIIZ string
	clr	al
	stosb
	pop	cx,di

	mov	bx, IFOT_STRING
	call	InitFileWrite
	.leave
	ret
InitFileWriteInteger	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileWriteBoolean

DESCRIPTION:	Writes a boolean out to the geos.ini file.
		The category and the key should be supplied.
			[category]
			key = boolean
		The routine InitFileReadBoolean can then be called with the
		category and key to locate the body of the string.

CALLED BY:	GLOBAL

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		ax    - non-0 = TRUE
			0 = FALSE

RETURN:		nothing

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

InitFileWriteBoolean	proc	far	uses bx, di, es
	.enter

	LoadVarSeg	es, di
	mov	di, offset dgroup:[trueStr]
	tst	ax
	jne	doWrite
	mov	di, offset dgroup:[falseStr]
doWrite:
	mov	bx, IFOT_STRING
	call	InitFileWrite

	.leave
	ret
InitFileWriteBoolean	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileWriteStringSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends a string onto the end of the "blob" denoted by
		the passed category & key names.

CALLED BY:	GLOBAL

PASS:		DS:SI	= Category ASCIIZ string
		CX:DX	= Key ASCIIZ string
		ES:DI	= NULL-terminated string to store

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		We're going to be stupid about this, and do it the
		slow way.
			Get existing string
			Copy onto end of string (after appending CR/LF)
			Write the resulting string

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFileWriteStringSection	proc	far

		call	PushAllFar

if INI_STRING_SECTION_TOMBSTONES
		call	InitFilePrepareStringSectionWrite
		jnc	writeLocalNow
		call	PopAllFar
		ret
	writeLocalNow:
endif
		call	InitFileWriteStringSectionRaw
		call	PopAllFar

		ret
InitFileWriteStringSection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileWriteStringSectionRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append a string section without sidecar hooks.

PASS:		ds:si - category
		cx:dx - key
		es:di - null-terminated string section

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileWriteStringSectionRaw	proc	near

	;
	; First determine the length of the new string section
	;

	push	ds, si, cx, dx
	push	es, di
	push	cx
	call	LocalStringLength		; cx = length w/o null
	inc	cx				; cx = length w/null
	mov	ax, cx				; string length (w/NULL) => AX
	pop	cx

	;
	; Obtain the existing string from the LOCAL init file, if any
	;
	mov	bp, mask IFRF_FIRST_ONLY	; allocate for us, please
	call	InitFileReadString		; memory handle => BX
	jc	noStringsNoMem
	jcxz	noStrings
	pop	ds, si				; string to add => DS:SI
	mov_tr	dx, ax				; new string length => DX
DBCS <	call	MemLock							>
DBCS <	mov	es, ax				; es:di = existing string>
DBCS <	clr	di							>
DBCS <	call	LocalStringLength		; cx = length w/o null	>
	mov_tr	ax, cx				; existing length => AX
	push	ax
	add	ax, dx				; add in new string length
	add	ax, 2				; add in CR/LF length
DBCS <	shl	ax, 1				; # chars -> # bytes	>
SBCS <	mov	ch, mask HAF_LOCK		; HeapAllocFlags => CH	>
DBCS <	mov	ch, 0				; DBCS: already locked	>
	call	MemReAlloc			; reallocate block & lock it
	mov	es, ax
	pop	di				; end of buffer => ES:DI
DBCS <	shl	di, 1				; char offset -> byte offset>
if DBCS_PCGEOS
	mov	ax, C_CARRIAGE_RETURN
	stosw
	mov	ax, C_LINE_FEED
	stosw
	mov	cx, dx				; cx = # chars
EC <	ERROR_C	ILLEGAL_INIT_FILE_STRING				>
	rep	movsw
else
	mov	ax, C_CR or (C_LF shl 8)
	stosw
	mov	cx, dx
	rep	movsb
endif
	clr	di

	; Now store the string back in the .INI file
	;
writeString:
	pop	cx, dx				; key name => CX:DX
	pop	ds, si				; category name => DS:SI
	call	InitFileWriteString
	tst	bx				; any allocate buffer ??
	jz	done
	call	MemFree				; else free allocate buffer
done:
	ret

	; Category/key wasn't found, so we must be the first string
	;
noStringsNoMem:
	clr	bx				; no memory to free
noStrings:
	pop	es, di				; string buffer => ES:DI
	jmp	writeString			; now write the string
InitFileWriteStringSectionRaw	endp

if INI_STRING_SECTION_TOMBSTONES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFilePrepareStringSectionWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle sidecar-list state before appending a string section.

PASS:		ds:si - category
		cx:dx - key
		es:di - string section being written

RETURN:		carry set to skip the local write

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFilePrepareStringSectionWrite	proc	near
		uses	ax, bx, cx, dx, di, si, bp, ds, es
sidecarCategory	local	MAX_INITFILE_CATEGORY_LENGTH dup (char)
sidecarKey	local	MAX_INITFILE_CATEGORY_LENGTH dup (char)
		.enter

	call	InitFileHaveLowerIniFile
	jc	haveLowerIni
	call	InitFileFreeRewriteSnapshot
	jmp	writeLocal

haveLowerIni:
	push	ds, si, cx, dx, es, di
	segmov	es, ss
	lea	di, ss:[sidecarCategory]
	mov	bx, es
	lea	ax, ss:[sidecarKey]
	call	InitFileBuildDisabledKey
	pop	ds, si, cx, dx, es, di
	jnc	haveDisabledKey
	jmp	writeLocal

haveDisabledKey:

	push	ds, si, cx, dx, es, di
	push	bp
	segmov	es, ss
	lea	di, ss:[sidecarCategory]
	mov	bx, es
	lea	ax, ss:[sidecarKey]
	call	InitFileMaybeTombstoneRewrite
	pop	bp
	pop	ds, si, cx, dx, es, di

	push	ds, si, cx, dx, es, di
	push	bp
	segmov	ds, ss
	lea	si, ss:[sidecarCategory]
	mov	cx, ds
	lea	dx, ss:[sidecarKey]
	call	InitFileMaybeSkipRewriteSnapshotEntry
	pop	bp
	pop	ds, si, cx, dx, es, di
	jnc	checkDisabledSidecar
	jmp	skipWrite

checkDisabledSidecar:
	push	ds, si, es, di
	segmov	ds, es
	mov	si, di
	call	LocalStringLength		; cx <- length
	mov	bx, cx
	pop	ds, si, es, di
	segmov	ds, ss
	lea	si, ss:[sidecarCategory]
	mov	cx, ds
	lea	dx, ss:[sidecarKey]
	push	bp
	mov	bp, bx
	call	InitFileRemoveStringSectionEntryRaw
	pop	bp
	jnc	writeLocal
	jmp	skipWrite

skipWrite:
	stc
	jmp	done

writeLocal:
	clc

done:
	.leave
	ret
InitFilePrepareStringSectionWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileMaybeTombstoneRewrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this key was just deleted for a rewrite, disable the
		current factory entries and retain a snapshot for matching.

PASS:		ds:si - category
		cx:dx - key
		es:di - disabled sidecar category
		bx:ax - disabled sidecar key

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		InitFileMaybeTombstoneRewrite	proc	near
catString	local	fptr.char	push	ds, si
keyString	local	fptr.char	push	cx, dx
sidecarCategory	local	fptr.char	push	es, di
sidecarKey	local	fptr.char	push	bx, ax
			.enter

			LoadVarSeg	es, ax
		tst	es:[rewriteStringSection]
		jnz	checkPending
		tst	es:[rewriteSnapshotHan]
		jnz	checkSnapshotKey
		jmp	done

checkSnapshotKey:
				lds	si, ss:[sidecarCategory]
				movdw	cxdx, ss:[sidecarKey]
				call	InitFileDisabledKeyMatchesRewrite
				jnc	done
				call	InitFileRewriteDisabledSidecarFromSnapshot
				call	InitFileFreeRewriteSnapshot
				jmp	done

			checkPending:
			lds	si, ss:[sidecarCategory]
			movdw	cxdx, ss:[sidecarKey]
			call	InitFileDisabledKeyMatchesRewrite
			jc	noMatch

		clr	es:[rewriteStringSection]
	;
	; The primary key was deleted before the rewrite was marked, so the
	; normal read path now resolves to the lower factory entry.
		;
			push	bp
			clr	bp
			lds	si, ss:[catString]
			movdw	cxdx, ss:[keyString]
			call	InitFileReadString
			pop	bp
			jnc	gotLower
		jmp	done

gotLower:
			LoadVarSeg	es, ax
			inc	cx
			mov	es:[rewriteSnapshotHan], bx
			mov	es:[rewriteSnapshotSize], cx
		jmp	done

			noMatch:
				call	InitFileStartPendingRewrite
				call	InitFileRewriteDisabledSidecarFromSnapshot
				call	InitFileFreeRewriteSnapshot
			done:
			.leave
			ret
InitFileMaybeTombstoneRewrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileMaybeSkipRewriteSnapshotEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a rewrite entry matches a factory snapshot entry.

PASS:		ds:si - disabled sidecar category
		cx:dx - disabled sidecar key
		es:di - string section entry being written

RETURN:		carry set if caller should skip the local write

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileMaybeSkipRewriteSnapshotEntry	proc	near
		uses	ax, bx, cx, dx, di, si, ds, es
sidecarCategory	local	fptr.char	push	ds, si
sidecarKey	local	fptr.char	push	cx, dx
writtenSeg	local	sptr	push	es
writtenPtr	local	word	push	di
writtenLen	local	word
snapshotHan	local	hptr
snapshotSeg	local	sptr
snapshotSize	local	word
entryStart	local	word
entryLength	local	word
entryRemaining	local	word
entryIndex	local	word
	.enter

	LoadVarSeg	ds, ax
	mov	bx, ds:[rewriteSnapshotHan]
	tst	bx
	LONG	jz	notFound
	mov	ss:[snapshotHan], bx
	mov	ax, ds:[rewriteSnapshotSize]
	mov	ss:[snapshotSize], ax
	lds	si, ss:[sidecarCategory]
	movdw	cxdx, ss:[sidecarKey]
	call	InitFileDisabledKeyMatchesRewrite
	LONG	jc	notFound

	push	ds
	mov	ds, ss:[writtenSeg]
	mov	si, ss:[writtenPtr]
	call	LocalStringLength
	mov	ss:[writtenLen], cx
	pop	ds

	mov	bx, ss:[snapshotHan]
	call	MemLock
	mov	ss:[snapshotSeg], ax
	mov	ds, ax
	clr	ss:[entryIndex]

scanLoop:
	mov	ds, ss:[snapshotSeg]
	clr	si
	mov	cx, ss:[snapshotSize]
	dec	cx
	mov	dx, ss:[entryIndex]
	call	GetStringSectionByIndex
	jc	unlockNotFound
	mov	ss:[entryStart], si
	mov	ss:[entryLength], cx
	mov	ss:[entryRemaining], ax

	mov	cx, ss:[entryLength]
	mov	dx, ss:[writtenLen]
	mov	es, ss:[writtenSeg]
	mov	di, ss:[writtenPtr]
	mov	si, ss:[entryStart]
	call	InitFileLexCompareStringSectionEntries
	jc	nextEntry

	mov	es, ss:[snapshotSeg]
	mov	ds, ss:[snapshotSeg]
	mov	di, ss:[entryStart]
	mov	si, di
	mov	cx, ss:[entryLength]
SBCS <	add	si, cx						>
DBCS <	shl	cx, 1						>
DBCS <	add	si, cx						>
	mov	cx, ss:[entryRemaining]
	jcxz	removeAtEnd
SBCS <	add	si, 2						>
DBCS <	add	si, 4						>
	sub	cx, 2
DBCS <	jc	forceTerminate					>
SBCS <	rep	movsb						>
DBCS <	rep	movsw						>
	jmp	terminateEntry

DBCS <forceTerminate:						>
DBCS <	xor	cx, cx						>
DBCS <	jmp	terminateEntry					>

removeAtEnd:
	tst	di
	jz	terminateEntry
SBCS <	sub	di, 2						>
DBCS <	sub	di, 4						>

terminateEntry:
SBCS <	mov	es:[di], cl					>
DBCS <	mov	es:[di], cx					>
	mov	ax, di
DBCS <	shr	ax, 1						>
	inc	ax
	LoadVarSeg	ds, bx
	mov	ds:[rewriteSnapshotSize], ax
	mov	ss:[snapshotSize], ax
	mov	bx, ss:[snapshotHan]
	call	MemUnlock
	stc
	jmp	done

nextEntry:
	inc	ss:[entryIndex]
	jmp	scanLoop

unlockNotFound:
	mov	bx, ss:[snapshotHan]
	call	MemUnlock
notFound:
	clc
done:
	.leave
	ret
InitFileMaybeSkipRewriteSnapshotEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileDisabledKeyMatchesRewrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare a disabled sidecar key with rewriteDisabledKey.

PASS:		ds:si - disabled sidecar category
		cx:dx - disabled sidecar key

RETURN:		carry clear if the names match

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileDisabledKeyMatchesRewrite	proc	near
		uses	ax, di, si, ds, es
sidecarCategory	local	fptr.char	push	ds, si
sidecarKey	local	fptr.char	push	cx, dx

	.enter

	LoadVarSeg	es, ax
	tst	{byte}es:[rewriteDisabledKey]
	jz	noMatch
	lds	si, ss:[sidecarCategory]
	mov	di, offset dgroup:[rewriteCategory]
compareCategoryLoop:
	lodsb
	scasb
	jne	noMatch
	tst	al
	jnz	compareCategoryLoop
	lds	si, ss:[sidecarKey]
	LoadVarSeg	es, ax
	mov	di, offset dgroup:[rewriteDisabledKey]
compareLoop:
	lodsb
	scasb
	jne	noMatch
	tst	al
	jnz	compareLoop
	clc
	jmp	done

noMatch:
	stc
done:
	.leave
	ret
InitFileDisabledKeyMatchesRewrite	endp

	
	COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			InitFileFreeRewriteSnapshot
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free any pending rewrite snapshot and clear rewrite state.

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileFreeRewriteSnapshot	proc	near
	uses	ax, bx, ds
	.enter

	LoadVarSeg	ds, ax
	mov	bx, ds:[rewriteSnapshotHan]
	clr	ds:[rewriteSnapshotHan]
	clr	ds:[rewriteSnapshotSize]
	clr	ds:[rewriteStringSection]
	clr	{byte}ds:[rewriteCategory]
	clr	{byte}ds:[rewriteKey]
	clr	{byte}ds:[rewriteDisabledKey]
	tst	bx
	jz	done
	call	MemFree
done:
	.leave
	ret
InitFileFreeRewriteSnapshot	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileStartPendingRewrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Capture lower entries for a pending rewrite snapshot.

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileStartPendingRewrite	proc	near
	uses	ax, bx, cx, dx, di, si, bp, ds, es
	.enter

		LoadVarSeg	ds, ax
		tst	ds:[rewriteStringSection]
		jnz	checkRewriteKey
		jmp	done

checkRewriteKey:
		tst	{byte}ds:[rewriteKey]
		jnz	checkLower
		jmp	clearState

checkLower:
		call	InitFilePendingRewriteIsLowerBlob
		jc	isLowerBlob
		jmp	clearState

isLowerBlob:
		LoadVarSeg	ds, ax

		mov	si, offset dgroup:[rewriteCategory]
		mov	cx, ds
		mov	dx, offset dgroup:[rewriteKey]
	;
	; The primary key was deleted before the rewrite was marked, so the
	; normal read path now resolves to the lower factory entry.
	;
		push	bp
		clr	bp
		call	InitFileReadString
		pop	bp
		jnc	gotLower
		jmp	clearState

gotLower:
		LoadVarSeg	es, ax
		inc	cx
		mov	es:[rewriteSnapshotHan], bx
		mov	es:[rewriteSnapshotSize], cx
		clr	es:[rewriteStringSection]
		jmp	done

clearState:
		call	InitFileFreeRewriteSnapshot
done:
	.leave
	ret
InitFileStartPendingRewrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileFlushPendingRewrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Commit pending rewrite snapshot to the disabled sidecar.

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileFlushPendingRewrite	proc	near
	.enter

	call	InitFileStartPendingRewrite
	call	InitFileRewriteDisabledSidecarFromSnapshot
	call	InitFileFreeRewriteSnapshot

	.leave
	ret
InitFileFlushPendingRewrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileRewriteDisabledSidecarFromSnapshot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the disabled sidecar with the current snapshot.

DESTROYED:	ax,bx,cx,dx,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileRewriteDisabledSidecarFromSnapshot	proc	near
	uses	ax, bx, cx, dx, si, bp, ds, es
	.enter

		LoadVarSeg	ds, ax
		mov	bx, ds:[rewriteSnapshotHan]
		tst	bx
		jz	done
		tst	{byte}ds:[rewriteDisabledKey]
		jz	done

		LoadVarSeg	ds, ax
		mov	ax, ds:[rewriteSnapshotSize]
		cmp	ax, 1
		ja	writeSnapshot
		mov	si, offset dgroup:[rewriteCategory]
		mov	cx, ds
		mov	dx, offset dgroup:[rewriteDisabledKey]
		call	InitFileDeleteEntryRaw
		jmp	done

writeSnapshot:
		LoadVarSeg	ds, ax
		mov	bx, ds:[rewriteSnapshotHan]
		push	bx
		call	MemLock
		mov	es, ax
		clr	di
		LoadVarSeg	ds, ax
		mov	si, offset dgroup:[rewriteCategory]
		mov	cx, ds
		mov	dx, offset dgroup:[rewriteDisabledKey]
		call	InitFileWriteString
		pop	bx
		call	MemUnlock

done:
	.leave
	ret
InitFileRewriteDisabledSidecarFromSnapshot	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	InitFileAppendStringSectionEntryRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append a raw entry to the disabled sidecar without hooks.

PASS:		ds:si - target category
		cx:dx - target key
		es:di - entry
		bp - entry length

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileAppendStringSectionEntryRaw	proc	near
	catString	local	fptr.char	push	ds, si
	keyString	local	fptr.char	push	cx, dx
	entrySeg	local	sptr	push	es
	entryPtr	local	word	push	di
	entryLen	local	word	push	bp
	tempHan	local	hptr
	tempSeg	local	sptr

	.enter

	tst	ss:[entryLen]
	jnz	haveEntry
	jmp	done

haveEntry:
	mov	ax, ss:[entryLen]
	inc	ax
DBCS <	shl	ax, 1							>
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	jnc	haveTemp
	jmp	done

haveTemp:
	mov	ss:[tempHan], bx
	mov	ss:[tempSeg], ax

	mov	es, ax
	clr	di
	mov	ds, ss:[entrySeg]
	mov	si, ss:[entryPtr]
	mov	cx, ss:[entryLen]
	cld
SBCS <	rep	movsb						>
DBCS <	rep	movsw						>
SBCS <	clr	al						>
SBCS <	stosb							>
DBCS <	clr	ax						>
DBCS <	stosw							>

	lds	si, ss:[catString]
	movdw	cxdx, ss:[keyString]
	mov	es, ss:[tempSeg]
	clr	di
	push	bp
	mov	bp, ss:[entryLen]
	call	InitFileRemoveStringSectionEntryRaw
	pop	bp

	lds	si, ss:[catString]
	movdw	cxdx, ss:[keyString]
	mov	es, ss:[tempSeg]
	clr	di
	push	bp
	call	InitFileWriteStringSectionRaw
	pop	bp

	mov	bx, ss:[tempHan]
	call	MemFree
done:
	.leave
	ret
InitFileAppendStringSectionEntryRaw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileRemoveStringSectionEntryRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a raw entry from a string-section key without hooks.

PASS:		ds:si - category
		cx:dx - key
		es:di - entry
		bp - entry length

RETURN:		carry set if an entry was removed

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileRemoveStringSectionEntryRaw	proc	near
catString	local	fptr.char	push	ds, si
keyString	local	fptr.char	push	cx, dx
entrySeg	local	sptr	push	es
entryPtr	local	word	push	di
entryLen	local	word	push	bp
blobHan	local	hptr
blobSeg	local	sptr
blobSize	local	word
entryStart	local	word
entryLength	local	word
entryRemaining	local	word
entryIndex	local	word
	.enter

	push	bp
	mov	bp, mask IFRF_FIRST_ONLY
	call	InitFileReadString
	pop	bp
	LONG	jc	notRemoved
	mov	ss:[blobHan], bx
	LONG	jcxz	freeNotRemoved
	mov	ss:[blobSize], cx
	call	MemLock
	mov	ss:[blobSeg], ax
	mov	ds, ax
	clr	ss:[entryIndex]

scanLoop:
	mov	ds, ss:[blobSeg]
	clr	si
	mov	cx, ss:[blobSize]
	mov	dx, ss:[entryIndex]
	call	GetStringSectionByIndex
	jc	freeNotRemoved
	mov	ss:[entryStart], si
	mov	ss:[entryLength], cx
	mov	ss:[entryRemaining], ax
	cmp	cx, ss:[entryLen]
	jne	nextEntry

	push	cx, si, di, ds, es
	mov	es, ss:[entrySeg]
	mov	di, ss:[entryPtr]
SBCS <	repe	cmpsb							>
DBCS <	repe	cmpsw							>
	pop	cx, si, di, ds, es
	je	removeEntry

nextEntry:
	inc	ss:[entryIndex]
	jmp	scanLoop

removeEntry:
	mov	es, ss:[blobSeg]
	mov	ds, ss:[blobSeg]
	mov	di, ss:[entryStart]
	mov	si, di
	mov	cx, ss:[entryLength]
SBCS <	add	si, cx							>
DBCS <	shl	cx, 1							>
DBCS <	add	si, cx							>
	mov	cx, ss:[entryRemaining]
	jcxz	atEnd
SBCS <	add	si, 2				; jump past CR/LF separator>
DBCS <	add	si, 4				; jump past CR/LF separator>
	sub	cx, 2				; move two fewer chars
DBCS <	jc	forceTerminate					>
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	jmp	terminate

DBCS <forceTerminate:							>
DBCS <	xor	cx, cx							>
DBCS <	jmp	terminate						>

atEnd:
	tst	di
	jz	terminate
SBCS <	sub	di, 2							>
DBCS <	sub	di, 4							>

terminate:
SBCS <	mov	es:[di], cl						>
DBCS <	mov	es:[di], cx						>

	lds	si, ss:[catString]
	movdw	cxdx, ss:[keyString]
	tst	di
	jz	deleteEntry
	clr	di
	call	InitFileWriteString
	jmp	freeRemoved

deleteEntry:
	lds	si, ss:[catString]
	movdw	cxdx, ss:[keyString]
	call	InitFileDeleteEntryRaw

freeRemoved:
	mov	bx, ss:[blobHan]
	call	MemFree
	stc
	jmp	done

freeNotRemoved:
	mov	bx, ss:[blobHan]
	call	MemFree
notRemoved:
	clc
done:
	.leave
	ret
InitFileRemoveStringSectionEntryRaw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileEntryIsActiveFactory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if an entry exists in lower INI data and is not disabled.

PASS:		ds:si - category
		cx:dx - key
		es:di - entry
		bp - entry length

RETURN:		carry set if the entry is active factory data

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileEntryIsActiveFactory	proc	near
entrySeg	local	sptr	push	es
entryPtr	local	word	push	di
entryLen	local	word	push	bp
factoryHan	local	hptr
factorySize	local	word
factorySeg	local	sptr
disabledHan	local	hptr
disabledSize	local	word
disabledSeg	local	sptr
entryStart	local	word
entryLength	local	word
entryRemaining	local	word
entryIndex	local	word
sidecarCategory	local	MAX_INITFILE_CATEGORY_LENGTH dup (char)
sidecarKey	local	MAX_INITFILE_CATEGORY_LENGTH dup (char)
	.enter

	clr	ax
	mov	ss:[disabledHan], ax
	mov	ss:[disabledSize], ax
	mov	ss:[disabledSeg], ax

	push	ds, si, cx, dx, es, di
	segmov	es, ss
	lea	di, ss:[sidecarCategory]
	mov	bx, es
	lea	ax, ss:[sidecarKey]
	call	InitFileBuildDisabledKey
	pop	ds, si, cx, dx, es, di
	LONG	jc	notFactory

	push	bp
	clr	bp
	call	InitFileReadLowerString
	pop	bp
	LONG	jc	notFactory
	mov	ss:[factoryHan], bx
	mov	ss:[factorySize], cx

	segmov	ds, ss
	lea	si, ss:[sidecarCategory]
	mov	cx, ds
	lea	dx, ss:[sidecarKey]
	push	bp
	mov	bp, mask IFRF_FIRST_ONLY
	call	InitFileReadString
	pop	bp
	jc	noDisabled
	mov	ss:[disabledHan], bx
	mov	ss:[disabledSize], cx
	call	MemLock
	mov	ss:[disabledSeg], ax
noDisabled:
	mov	bx, ss:[factoryHan]
	call	MemLock
	mov	ss:[factorySeg], ax
	mov	ds, ax
	clr	ss:[entryIndex]

scanLoop:
	mov	ds, ss:[factorySeg]
	clr	si
	mov	cx, ss:[factorySize]
	mov	dx, ss:[entryIndex]
	call	GetStringSectionByIndex
	jc	unlockNotFactory
	mov	ss:[entryStart], si
	mov	ss:[entryLength], cx
	mov	ss:[entryRemaining], ax
	cmp	cx, ss:[entryLen]
	jne	nextEntry

	push	cx, si, di, ds, es
	mov	es, ss:[entrySeg]
	mov	di, ss:[entryPtr]
SBCS <	repe	cmpsb						>
DBCS <	repe	cmpsw						>
	pop	cx, si, di, ds, es
	jne	nextEntry

	tst	ss:[disabledSeg]
	jz	unlockFactory
	mov	ds, ss:[factorySeg]
	mov	si, ss:[entryStart]
	mov	cx, ss:[entryLength]
	mov	es, ss:[disabledSeg]
	mov	dx, ss:[disabledSize]
	call	InitFileStringSectionAlreadyWritten
	jc	nextEntry
	jmp	unlockFactory

nextEntry:
	inc	ss:[entryIndex]
	jmp	scanLoop

unlockFactory:
	mov	bx, ss:[factoryHan]
	call	MemFree
	mov	bx, ss:[disabledHan]
	tst	bx
	jz	factoryDone
	call	MemFree
factoryDone:
	stc
	jmp	done

unlockNotFactory:
	mov	bx, ss:[factoryHan]
	call	MemFree
	mov	bx, ss:[disabledHan]
	tst	bx
	jz	notFactory
	call	MemFree
notFactory:
	clc
done:
	.leave
	ret
InitFileEntryIsActiveFactory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileDeleteMergedStringSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a string-section entry from the merged effective list.

PASS:		ds:si - category
		cx:dx - key
		ax - merged index

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileDeleteMergedStringSection	proc	near
catString	local	fptr.char	push	ds, si
keyString	local	fptr.char	push	cx, dx
entryIndex	local	word	push	ax
mergedHan	local	hptr
mergedSeg	local	sptr
mergedSize	local	word
entryPtr	local	word
entryLen	local	word
sidecarCategory	local	MAX_INITFILE_CATEGORY_LENGTH dup (char)
sidecarKey	local	MAX_INITFILE_CATEGORY_LENGTH dup (char)
	.enter

	push	ds, si, cx, dx
	segmov	es, ss
	lea	di, ss:[sidecarCategory]
	mov	bx, es
	lea	ax, ss:[sidecarKey]
	call	InitFileBuildDisabledKey
	pop	ds, si, cx, dx
	jc	done

	push	bp
	clr	bp
	call	InitFileReadMergedStringSection
	pop	bp
	jc	done
	mov	ss:[mergedHan], bx
	mov	ss:[mergedSize], cx
	call	MemLock
	mov	ss:[mergedSeg], ax
	mov	ds, ax
	clr	si
	mov	cx, ss:[mergedSize]
	mov	dx, ss:[entryIndex]
	call	GetStringSectionByIndex
	jc	free
	mov	ss:[entryPtr], si
	mov	ss:[entryLen], cx

	mov	es, ss:[mergedSeg]
	mov	di, ss:[entryPtr]
	lds	si, ss:[catString]
	movdw	cxdx, ss:[keyString]
	push	bp
	mov	bp, ss:[entryLen]
	call	InitFileEntryIsActiveFactory
	pop	bp
	mov	es, ss:[mergedSeg]
	mov	di, ss:[entryPtr]
	lds	si, ss:[catString]
	jc	disableFactory

	movdw	cxdx, ss:[keyString]
	push	bp
	mov	bp, ss:[entryLen]
	call	InitFileRemoveStringSectionEntryRaw
	pop	bp
	jmp	free

disableFactory:
	segmov	ds, ss
	lea	si, ss:[sidecarCategory]
	mov	cx, ds
	lea	dx, ss:[sidecarKey]
	push	bp
	mov	bp, ss:[entryLen]
	call	InitFileAppendStringSectionEntryRaw
	pop	bp

free:
	mov	bx, ss:[mergedHan]
	call	MemFree
done:
	.leave
	ret
InitFileDeleteMergedStringSection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileLexCompareStringSectionEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare string-section entries as generic token streams.

PASS:		ds:si - first entry
		cx - first entry length
		es:di - second entry
		dx - second entry length

RETURN:		carry clear if entries match lexically

DESTROYED:	ax,bx,cx,dx,di,si,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileLexCompareStringSectionEntries	proc	near
leftSeg		local	sptr	push	ds
leftPtr		local	word	push	si
leftLen		local	word	push	cx
rightSeg	local	sptr	push	es
rightPtr	local	word	push	di
rightLen	local	word	push	dx
prevDelimiter	local	byte
quoteState	local	byte
leftChar	local	word
	.enter

	mov	ss:[prevDelimiter], TRUE
	clr	ss:[quoteState]

compareLoop:
	mov	ds, ss:[leftSeg]
	mov	si, ss:[leftPtr]
	mov	cx, ss:[leftLen]
	mov	bl, ss:[prevDelimiter]
	mov	bh, ss:[quoteState]
	call	InitFileLexGetChar
	mov	ss:[leftPtr], si
	mov	ss:[leftLen], cx
	mov	ss:[leftChar], ax

	mov	ds, ss:[rightSeg]
	mov	si, ss:[rightPtr]
	mov	cx, ss:[rightLen]
	mov	bl, ss:[prevDelimiter]
	mov	bh, ss:[quoteState]
	call	InitFileLexGetChar
	mov	ss:[rightPtr], si
	mov	ss:[rightLen], cx

	cmp	ax, ss:[leftChar]
	jne	noMatch
	mov	ax, ss:[leftChar]
	tst	ax
	jz	match

	cmp	ax, C_QUOTE
	jne	notQuote
	tst	ss:[quoteState]
	jz	enterQuote
	clr	ss:[quoteState]
	jmp	clearPrevDelimiter

enterQuote:
	mov	ss:[quoteState], TRUE
	jmp	clearPrevDelimiter

notQuote:
	tst	ss:[quoteState]
	jnz	clearPrevDelimiter
	call	InitFileLexIsDelimiterChar
	jc	setPrevDelimiter

clearPrevDelimiter:
	clr	ss:[prevDelimiter]
	jmp	compareLoop

setPrevDelimiter:
	mov	ss:[prevDelimiter], TRUE
	jmp	compareLoop

match:
	clc
	jmp	done

noMatch:
	stc
done:
	.leave
	ret
InitFileLexCompareStringSectionEntries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileLexGetChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch next significant character for lexical comparison.

PASS:		ds:si - string
		cx - remaining length
		bl - nonzero if previous significant char was delimiter
		bh - nonzero if currently inside quotes

RETURN:		ax - next char, or 0 at logical end
		ds:si - advanced
		cx - remaining length

DESTROYED:	dx,di
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileLexGetChar	proc	near
	.enter

getLoop:
	jcxz	atEnd
	LocalGetChar ax, dssi, NO_ADVANCE
SBCS <	clr	ah							>
	tst	bh
	jnz	takeChar
	call	InitFileLexIsSpaceChar
	jc	whiteSpace

takeChar:
	LocalNextChar dssi
	dec	cx
	jmp	done

whiteSpace:
	tst	bl
	jnz	skipWhiteSpace
	mov	di, si
	mov	dx, cx
lookAhead:
	LocalGetChar ax, dsdi, NO_ADVANCE
SBCS <	clr	ah							>
	call	InitFileLexIsSpaceChar
	jnc	foundNext
	LocalNextChar dsdi
	dec	dx
	jnz	lookAhead
	jmp	skipWhiteSpace

foundNext:
	call	InitFileLexIsDelimiterChar
	jc	skipWhiteSpace
	LocalGetChar ax, dssi, NO_ADVANCE
SBCS <	clr	ah							>
	LocalNextChar dssi
	dec	cx
	jmp	done

skipWhiteSpace:
	jcxz	getLoop
	LocalGetChar ax, dssi, NO_ADVANCE
SBCS <	clr	ah							>
	call	InitFileLexIsSpaceChar
	jnc	getLoop
	LocalNextChar dssi
	dec	cx
	jmp	skipWhiteSpace

atEnd:
	clr	ax
done:
	.leave
	ret
InitFileLexGetChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileLexIsSpaceChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for lexical whitespace.

PASS:		ax - character

RETURN:		carry set if space or tab

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileLexIsSpaceChar	proc	near
SBCS <	cmp	al, C_SPACE						>
DBCS <	cmp	ax, C_SPACE						>
	je	isSpace
SBCS <	cmp	al, C_TAB						>
DBCS <	cmp	ax, C_TAB						>
	je	isSpace
	clc
	ret
isSpace:
	stc
	ret
InitFileLexIsSpaceChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileLexIsDelimiterChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for generic delimiter punctuation.

PASS:		ax - character

RETURN:		carry set if delimiter punctuation

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileLexIsDelimiterChar	proc	near
SBCS <	cmp	al, C_QUOTE						>
DBCS <	cmp	ax, C_QUOTE						>
	je	notDelimiter
SBCS <	cmp	al, C_SPACE						>
DBCS <	cmp	ax, C_SPACE						>
	jbe	notDelimiter
SBCS <	cmp	al, '0'							>
DBCS <	cmp	ax, '0'							>
	jb	checkWordChars
SBCS <	cmp	al, '9'							>
DBCS <	cmp	ax, '9'							>
	jbe	notDelimiter
SBCS <	cmp	al, 'A'							>
DBCS <	cmp	ax, 'A'							>
	jb	checkWordChars
SBCS <	cmp	al, 'Z'							>
DBCS <	cmp	ax, 'Z'							>
	jbe	notDelimiter
SBCS <	cmp	al, 'a'							>
DBCS <	cmp	ax, 'a'							>
	jb	checkWordChars
SBCS <	cmp	al, 'z'							>
DBCS <	cmp	ax, 'z'							>
	jbe	notDelimiter

checkWordChars:
SBCS <	cmp	al, '.'							>
DBCS <	cmp	ax, '.'							>
	je	notDelimiter
SBCS <	cmp	al, '*'							>
DBCS <	cmp	ax, '*'							>
	je	notDelimiter
SBCS <	cmp	al, '?'							>
DBCS <	cmp	ax, '?'							>
	je	notDelimiter
SBCS <	cmp	al, C_BACKSLASH						>
DBCS <	cmp	ax, C_BACKSLASH						>
	je	notDelimiter
SBCS <	cmp	al, '/'							>
DBCS <	cmp	ax, '/'							>
	je	notDelimiter
SBCS <	cmp	al, ':'							>
DBCS <	cmp	ax, ':'							>
	je	notDelimiter
SBCS <	cmp	al, '_'							>
DBCS <	cmp	ax, '_'							>
	je	notDelimiter
SBCS <	cmp	al, '-'							>
DBCS <	cmp	ax, '-'							>
	je	notDelimiter
SBCS <	cmp	al, '+'							>
DBCS <	cmp	ax, '+'							>
	je	notDelimiter
	stc
	ret

notDelimiter:
	clc
	ret
InitFileLexIsDelimiterChar	endp

endif	; INI_STRING_SECTION_TOMBSTONES

	
COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileWrite

DESCRIPTION:	Common code for modifying the init file

CALLED BY:	INTERNAL

PASS:		bx - mode
			0 for data op, -1 for string op
		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		if bx = 0
		     es:di - buffer containing data
		     bp - size of buffer
		else
		     es:di - body ASCIIZ string

RETURN:

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

InitFileWrite	proc	near
	uses	ax, bx, cx, di, si, bp, ds, es
	.enter

	push	bx
	call	EnterInitfile		;es, bp <- dgroup, destroys ax, bx
	pop	bx

	mov	es:[buildBufHan], 0

	cmp	bx, IFOT_STRING
	mov	bx, offset BuildEntryFromString	; Assume string operation
	je	doWrite
	mov	bx, offset BuildEntryFromData	; Nope. data.


doWrite:
	call	bx			;destroys ax, bx

	;-----------------------------------------------------------------------
	;does category exist

	call	FindCategory		;carry <- func(ds:dx)
	jnc	categoryExists

	call	CreateCategory		;func(es, ds:dx), destroys ax
	jmp	short insertBody

categoryExists:
	;-----------------------------------------------------------------------
	;category exists
	;does key exist

	call	FindKey			;carry <- func(es,ds:si)
	jc	createEntry

	;-----------------------------------------------------------------------
	;key exists
	;replace current entry

	call	DeleteEntry
;	jmp	short insertBody

createEntry:
	;body insertion pos = next category

;	call	GetChar
;	cmp	al, '['			;halted at new category?
;	jne	insertBody
;	dec	es:[initFileBufPos]

insertBody:
EC<	call	IFCheckDgroupRegs					>

	mov	cx, es:[entrySize]
	call	MakeSpace		;func(es,cx), destroys ax, di

EC<	call	IFCheckDgroupRegs					>
	mov	ds, es:[buildBufAddr]
	clr	si
	les	di, es:[initFileBufPos]	;es:di <- space
	rep	movsb
	mov	es, bp

	;-----------------------------------------------------------------------
	;store time

	call	TimerGetCount	;bx:ax <- system timer count
	mov	word ptr es:[initfileLastModified+2], bx
	mov	word ptr es:[initfileLastModified], ax

	mov	bx, es:[buildBufHan]
	tst	bx
	je	done
	call	MemFree

done:
	;check the .ini file, in case it was corrupted by something
	;that we just wrote out to it.

if ERROR_CHECK
	call	CheckNormalECEnabled	; only check if ECF_NORMAL set
	jz	afterCheck
	push	ax, cx, ds

	call	IFCheckDgroupRegs	;assert es = dgroup (kdata)
	mov	ax, es:[initFileBufSegAddr]
	mov	ds, ax

	mov	cx, es:[loaderVars].KLV_initFileSize
	dec	cx

	call	ValidateIniFileFar	;saves all regs that it trashes
	ERROR_C	CORRUPTED_INI_FILE
	pop	ax, cx, ds
afterCheck:
endif
if HASH_INIFILE
	call	HashUpdateHashTable
endif
	call	ExitInitfile
	clc				;return no errors

	.leave
	ret
InitFileWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileDeleteStringSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the specific string from the "blob" denoted by
		the category and key names.

CALLED BY:	GLOBAL

PASS:		DS:SI	= Category ASCIIZ string
		CX:DX	= Key ASCIIZ string
		AX	= 0-based string number to remove

RETURN:		Carry	= Clear if successful
			= Set if error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		We're going to be stupid about this, and do it the
		slow way.
			Get existing string
			Remove the desired string
			Write the resulting string
		If this is the last section in the key (i.e. deleting it
		would make the key empty), we just delete the key, rather
		than writing an empty blob out.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFileDeleteStringSection	proc	far
		uses	ax, bx, di, bp, es
if INI_STRING_SECTION_TOMBSTONES
sidecarCategory	local	MAX_INITFILE_CATEGORY_LENGTH dup (char)
sidecarKey	local	MAX_INITFILE_CATEGORY_LENGTH dup (char)
endif
		.enter

if INI_STRING_SECTION_TOMBSTONES
		push	ax, ds, si, cx, dx
		call	InitFileHaveLowerIniFile
		jnc	legacyDelete
		segmov	es, ss
		lea	di, ss:[sidecarCategory]
		mov	bx, es
		lea	ax, ss:[sidecarKey]
		call	InitFileBuildDisabledKey
		jc	legacyDelete
		pop	ax, ds, si, cx, dx
		call	InitFileDeleteMergedStringSection
		jmp	exit
legacyDelete:
		pop	ax, ds, si, cx, dx
endif

	;
	; First get the blob
	;
		push	cx
		clr	bp				; allocate memory for us
		call	InitFileReadString		; memory handle => BX
		mov	bp, cx				; size of original string => BP
		pop	cx
		jc	exit				; if error, we abort

	; Now we find the string section we want
	;
		push	ds, si, cx, dx
		mov_tr	dx, ax				; string number => DX
		mov	cx, bp				; string size => CX
		call	MemLock
		mov	ds, ax				; start of string => DS:SI
		mov	es, ax
		clr	si
		call	GetStringSectionByIndex		; get start of section to nuke
		jc	done				; if error, abort

	; Now determine how much we need to delete. We are always going
	; to assume that there is a CR/LF pair separating each section,
	; to make things a lot easier.
	;
		mov	di, si				; destination => ES:DI
DBCS <		shl	cx, 1				; # chars -> # bytes	>
		add	si, cx				; go to end of section
		mov	cx, ax				; # of chars left => CX
		jcxz	atEnd
SBCS <		add	si, 2				; jump past CR/LF separator>
DBCS <		add	si, 4				; jump past CR/LF separator>
		sub	cx, 2				; move two fewer chars
DBCS <		jc	forceTerminate			; only one char, must be NULL>
SBCS <		rep	movsb				; move the chars	>
DBCS <		rep	movsw				; move the chars	>
		jmp	terminate			; go terminate the string

DBCS <forceTerminate:							>
DBCS <		xor	cx, cx				; clear cx and carry	>
DBCS <		jmp	terminate						>

	; We're at the end. Either back up two character for the destination
	; or we have no more strings left
atEnd:
		tst	di
		jz	terminate
SBCS <		sub	di, 2							>
DBCS <		sub	di, 4							>

	; We're done. Write the string back to .INI file
terminate:
SBCS <		mov	es:[di], cl			; store the NULL terminator>
DBCS <		mov	es:[di], cx			; store the NULL terminator>
done:
		pop	ds, si, cx, dx			; restore category & key names
		jc	free				; if error, free memory only

		tst	di				; anything left?
		jz	deleteEntry			; no -- nuke it

		clr	di				; string => ES:DI
		call	InitFileWriteString		; write the resulting string

	; Now free the buffer, and we're done
free:
		pushf					; save carry flag
		call	MemFree				; free buffer used earlier
		popf					; restore carry flag
exit:
		.leave
		ret

deleteEntry:
		call	InitFileDeleteEntry
		jmp	free

InitFileDeleteStringSection	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileDeleteEntry

DESCRIPTION:	Deletes a key entry from a category

CALLED BY:	GLOBAL

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string

RETURN:		nothing

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

InitFileDeleteEntry	proc	far
	uses	ax, bx, cx, di, si, bp, ds, es
	.enter

if INI_STRING_SECTION_TOMBSTONES
		push	ds, si, cx, dx
		push	bp
		call	InitFileFlushPendingRewrite
		pop	bp
		pop	ds, si, cx, dx
endif
		call	EnterInitfile	;es,bp <- dgroup
if INI_STRING_SECTION_TOMBSTONES
		call	InitFileMarkStringSectionRewrite
endif
		call	InitFileDeleteEntryLow
		call	ExitInitfile
if INI_STRING_SECTION_TOMBSTONES
		call	InitFileStartPendingRewrite
endif

	.leave

	ret
InitFileDeleteEntry	endp

if INI_STRING_SECTION_TOMBSTONES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileDeleteEntryRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a key entry without string-section sidecar hooks.

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string

DESTROYED:	none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileDeleteEntryRaw	proc	near
	uses	ax, bx, cx, di, si, bp, ds, es
	.enter

		call	EnterInitfile	;es,bp <- dgroup
		call	InitFileDeleteEntryLow
		call	ExitInitfile

	.leave

	ret
InitFileDeleteEntryRaw	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileDeleteEntryLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a key entry from an entered initfile.

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		es,bp - dgroup

DESTROYED:	ax,bx,cx,di,si,ds,es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileDeleteEntryLow	proc	near
	call	FindCategory
	jc	done
	call	FindKey		;initFileBufPos = body, curKeyOffset
	jc	done

	;-----------------------------------------------------------------------
	;locate end of body

	clr	bx			;not starting in blob
	call	GetCharFar
	jc	done

	cmp	al, '{'			;blob?
	jne	doDelete

	mov	bx, TRUE		;now processing blob
	mov	al, '}'
	call	FindCharFar		;pos = pos past char
EC<	ERROR_C	INIT_FILE_BAD_BLOB					>


doDelete:
	;-----------------------------------------------------------------------
	;delete key + body

	mov	al, '\n'		;locate a carraige return
	call	FindCharFar		;pos = pos past LF

	mov	si, es:[initFileBufPos]
	mov	ax, si

	mov	di, es:[curKeyOffset]
if HASH_INIFILE
	push	di
endif		; HASH_INIFILE
	sub	ax, di			;ax <- num chars to delete

	mov	cx, es:[loaderVars].KLV_initFileSize
	push	cx
	sub	cx, si
	inc	cx

	mov	bx, es:[initFileBufSegAddr]	;ds <- dgroup
	mov	ds, bx
	mov	es, bx
	rep	movsb

	pop	cx
	sub	cx, ax			;cx <- num chars left
	mov	es, bp			;es <- dgroup
	mov	es:[loaderVars].KLV_initFileSize, cx

if HASH_INIFILE
	pop	di
	mov	cx, ax
	neg	cx
	call	HashUpdateHashTable
endif
done:
	ret
InitFileDeleteEntryLow	endp

if INI_STRING_SECTION_TOMBSTONES

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileMarkStringSectionRewrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remember the just-deleted key as a possible string-section
		rewrite target.

PASS:		es, bp - dgroup

DESTROYED:	nothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileMarkStringSectionRewrite	proc	near
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter

		call	InitFileHaveLowerIniFile
		jc	haveLowerForMark
		jmp	done

haveLowerForMark:
		mov	ds, bp
		movdw	cxdx, ds:[keyStrAddr]
		lds	si, ds:[catStrAddr]

		push	ds, si, cx, dx
		call	InitFileFreeRewriteSnapshot
		pop	ds, si, cx, dx
		push	ds, si, cx, dx
		LoadVarSeg	es, ax
		mov	di, offset dgroup:[rewriteCategory]
		mov	bx, es
		mov	ax, offset dgroup:[rewriteDisabledKey]
		call	InitFileBuildDisabledKey
		pop	ds, si, cx, dx
		jnc	haveMarkDisabledKey
		jmp	done

haveMarkDisabledKey:
		push	ds
		mov	bx, cx
		mov	si, dx
		LoadVarSeg	ds, ax
		mov	di, offset dgroup:[rewriteKey]
		segmov	es, ds
		mov	ds, bx
copyRewriteKey:
		lodsb
		stosb
		tst	al
		jnz	copyRewriteKey
		pop	ds

		LoadVarSeg	ds, ax
		mov	ds:[rewriteStringSection], TRUE

done:
	.leave

	ret
InitFileMarkStringSectionRewrite	endp

endif	; INI_STRING_SECTION_TOMBSTONES

	
COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileDeleteCategory

DESCRIPTION:	Deletes an entire category of data from the initfile

CALLED BY:	GLOBAL

PASS:		ds:si - category ASCIIZ string

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

InitFileDeleteCategory	proc	far
	uses	ax, bx, cx, dx, di, si, bp, ds, es
   	.enter

	; There *must* be a valid pointer in CX:DX, as EnterInitfile
	; always expects a key to be passed. So, put something valid in CX:DX
	;
	mov	cx, ds
	mov	dx, si

	; Find the starting & ending bytes of the requested category.
	; Note that the category's starting position is actually the byte
	; after the ']' character
	;
	call	EnterInitfile		;es,bp <- dgroup
	call	FindCategory
	jc	exit
	mov	al, '['
	clr	bx			;not starting in blob
	call	FindCharFar		;pos = pos past char
	jc	doDelete		;if c set, pos = eof
	dec	es:[initFileBufPos]

	; Now delete the category
doDelete:
	mov	si, es:[initFileBufPos]
	mov	di, es:[curCatOffset]
	mov	dx, es:[loaderVars].KLV_initFileSize
	push	dx
	mov	ax, es:[initFileBufSegAddr]
	mov	ds, ax			;ds <- initfile buffer
	mov	es, ax			;es <- initfile buffer

	; Find the actual first character of the category, by
	; scanning in reverse for a '[' character
	;
	std				;scan in reverse
	mov	cx, dx			;it's got to be there, sp use file size
	mov	al, '['			;al <- character to scan for
	repne	scasb
EC <	ERROR_NZ INIT_FILE_START_OF_CATEGORY_NOT_FOUND			>
	cld
	inc	di			;es:di <- start of category


	; Now perform the actual category removal
	;
	mov	ax, si
	sub	ax, di			;ax <- num chars to delete
if HASH_INIFILE
	;
	; Remove the cateogry from the hash table
	;
	push	es
	mov	es, bp		;es - dgroup
	mov	cx, ax
	neg	cx
	call	HashUpdateHashTable
	call	HashRemoveCategory
	pop	es
endif
	mov	cx, dx			;cx <- initfile size
	sub	cx, si
	inc	cx			;cx <- bytes to move

	rep	movsb

	; Clean up some cached values
	;
	pop	cx
	sub	cx, ax			;cx <- num chars left
	mov	es, bp			;es <- dgroup
	mov	es:[loaderVars].KLV_initFileSize, cx
	; clear the cache!
	mov	es:[curCatOffset], CATEGORY_NOT_CACHED

exit:
	call	ExitInitfile

	.leave
	ret
InitFileDeleteCategory	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileSave

DESCRIPTION:	Saves the initfile

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry	- clear if successful
			- set otherwise

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

InitFileSave	proc	far
	uses	ax, bx, cx, dx, ds
	.enter

	; Change to correct directory
	;
	call	FilePushDir
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath

	; lock buffer after grabbing semaphore
	;
	call	LoadVarSegDS_PInitFile
	mov	bx, ds:[loaderVars].KLV_initFileBufHan
	push	bx
	call	MemLock
	mov	ds:[initFileBufSegAddr], ax

	mov	ax, (FILE_ACCESS_RW or FILE_DENY_RW) or \
		    ((mask FCF_NATIVE or FILE_CREATE_TRUNCATE) shl 8)
	mov	cx, FILE_ATTR_NORMAL		;file attributes
	mov	dx, offset initfileBackupName
	call	FileCreate
	jc	done
	mov	bx, ax				;bx <- file handle

	push	ds
	mov	al, FILE_NO_ERRORS
	mov	cx, ds:[loaderVars].KLV_initFileSize
	mov	ds, ds:[initFileBufSegAddr]
	clr	dx
	call	FileWriteFar
	pop	ds
;	mov	ds:[initFileBackupSize], cx

	mov	al, FILE_NO_ERRORS
	call	FileCloseFar
	clc					;clear carry to indicate success
done:
	pop	bx				;retrieve mem handle
	call	MemUnlock			;release buffer
	call	VInitFileWrite			;release semaphore
	call	FilePopDir

	.leave
	ret
InitFileSave	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFileRevert

DESCRIPTION:	Restores the backed-up initfile

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry	- clear clear if successful
			- set otherwise

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

InitFileRevert	proc	far
	uses	ax, bx, cx, dx, ds
	.enter

	; Change to the correct directory
	;
		call	FilePushDir
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath

	; Lock buffer after grabbing semaphore
	;
		call	LoadVarSegDS_PInitFile
if INI_STRING_SECTION_TOMBSTONES
		call	InitFileFreeRewriteSnapshot
endif
		mov	bx, ds:[loaderVars].KLV_initFileBufHan
		mov	al, FILE_ACCESS_R or FILE_DENY_RW
		mov	dx, offset initfileBackupName
		call	FileOpen
		jc	done
		push	bx
		mov	bx, ax				;bx <- file handle

		call	FileSize			;AX = file size

	; realloc initfile buffer
	;
		push	bx				;save file handle
;		mov	ax, ds:[initFileBackupSize]
		push	ax				;save size
		mov	bx, ds:[loaderVars].KLV_initFileBufHan
		mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK or mask HAF_NO_ERR
		call	MemReAlloc
		mov	ds:[initFileBufSegAddr], ax	;update seg addr
		pop	cx
		mov	ds:[loaderVars].KLV_initFileSize, cx		;change size
		pop	bx				;retrieve file handle

	; read file in
	; ax = seg addr of buffer
	; cx = size
	;
		push	ds
		mov	ds, ax
		clr	dx				;ds:dx <- initfile buffer
		mov	al, FILE_NO_ERRORS
		call	FileReadFar			;cx <- # bytes
		mov	al, FILE_NO_ERRORS
		call	FileCloseFar
		pop	ds
		clc					;indicate success
		pop	bx				;retrieve mem handle
		call	MemUnlock			;release buffer
done:
		call	VInitFileWrite			;release semaphore
		call	FilePopDir

		.leave

		ret
InitFileRevert	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	INITFILECOMMIT

DESCRIPTION:	Commits the initfile to the disk

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

INITFILECOMMIT	proc	far
	uses	ax, bx, cx, dx, di, ds, es
	.enter

	; Some set-up work first
	;
if INI_STRING_SECTION_TOMBSTONES
		call	InitFileFlushPendingRewrite
		call	InitFileFreeRewriteSnapshot
endif
		call	LoadVarSegDS_PInitFile
		LoadVarSeg	es
		tst	es:[trashedIniBuffer]	;If the .ini buffer is trashed, just
		jnz	exit			; exit.
		mov	bx, es:[loaderVars].KLV_initFileBufHan	;lock the buffer
		push	bx
		call	MemLock
		mov	ds, ax
		mov	bx, es:[loaderVars].KLV_initFileHan

	; To ensure we have sufficient disk space, we first expand the
	; current file to the size of the new .INI file. We do this by
	; writing out a number of bytes equal to the difference between
	; the old & new file sizes. The first character will always be
	; EOF (CTRL-Z), to ensure that the file continues to be valid.
	;
		mov	al, FILE_POS_END
		clr	cx, dx
		call	FilePosFar		; file size => AX (smaller than 64K)
		mov	cx, es:[loaderVars].KLV_initFileSize
		dec	cx			; match logic below
		sub	cx, ax
		ja	ensureRoom

	; Rewind the sucker first...
validate:
		clr	cx
		mov	dx, cx
		mov	al, FILE_POS_START
		call	FilePosFar
		mov	al, FILE_NO_ERRORS
		mov	cx, es:[loaderVars].KLV_initFileSize
		dec	cx			; Don't write EOF
EC < 		call	ValidateIniFileFar	; Check to see if buffer was trashed >
NEC < 		call	ValidateIniFile		; Check to see if buffer was trashed >
LONG		jc	error			; branch if so...

	; the .ini file could have been opened read-only.
	; We find out it that was the case if our first call to
	; FileWrite returns ax=ERROR_ACCESS_DENIED.  If that's the
	; case, return.  If error is something else, then panic.
	;
		clr	al			;clear FILE_NO_ERRORS flag
		call	FileWriteFar
		jnc	fileWriteOK

		cmp	ax, ERROR_SHARING_VIOLATION	;for baseband nets
		jz	hack10
		cmp	ax, ERROR_ACCESS_DENIED
		jne	writeError
hack10:

	; .ini file was opened read-only
		pop	bx
		call	MemUnlock
		jmp	exit

fileWriteOK:
		mov	al, FILE_NO_ERRORS	;reset the FILE_NO_ERRORS_FLAG

	; Truncate the file at the current position (using # bytes written
	; as the position value), and then commit the file
	;
		mov	dx, cx
		clr	cx
		call	FileTruncate
		mov	al, FILE_NO_ERRORS
		call	FileCommit
done:
		pop	bx
		call	MemUnlock		; unlock the buffer
		segmov	ds, es			; dgroup -> ds
		call	VInitFileWrite
exit:
		.leave

		ret

	; Ensure sufficient space is present in the file by writing to it
ensureRoom:
		push	ds, ax			; save the old file size
		mov	al, dl			; return errors (DX was 0 from above)
		segmov	ds, cs, dx
		mov	dx, offset fileTerminationChar
		call	FileWriteFar
		pop	ds, dx			; old file size => DX
		jnc	validate
		cmp	ax, ERROR_SHORT_READ_WRITE
		jne	validate

	; Truncate .INI file (size to truncate to is in DX), and display
	; the short-write error
	;
		clr	al
		clr	cx
		call	FileTruncate		; truncate file to prior size
		jmp	shortWrite

writeError:
		cmp	ax, ERROR_SHORT_READ_WRITE
		jne	error

	; a short-write we can allow. we just want to make sure the user is
	; aware of the problem.
shortWrite:
		mov	bx, handle noSpaceForIniString1
		call	MemLock
		mov	ds, ax
		assume 	ds:segment noSpaceForIniString1
		mov	si, ds:[noSpaceForIniString1]
		mov	di, ds:[noSpaceForIniString2]
		mov	ax, mask SNF_CONTINUE
		call	SysNotify
		call	MemUnlock
		jmp	done
		assume	ds:dgroup

	; There is something wrong with the .INI file, so DON'T write it out
error:
		mov	es:[trashedIniBuffer], TRUE	; Set flag saying the .ini buffer
							; has been trashed, so we don't
							; want to write it out.
		call	ExitInitfile
if 0	; Code redundancy
if ERROR_CHECK
		ERROR	CORRUPTED_INI_FILE
else
		mov	bx, handle corruptedIniBufferStringOne
		call	MemLock
		mov	ds, ax
		assume	ds:segment corruptedIniBufferStringOne
		mov	ax, mask SNF_EXIT
		mov	si, ds:[corruptedIniBufferStringOne]
		mov	di, ds:[corruptedIniBufferStringTwo]
		call	SysNotify
		mov	si, -1
		mov	ax, SST_DIRTY
		GOTO	SysShutdown
		assume	ds:dgroup
endif
else
		call	CorruptedIniFileError		; never returns
	.unreached
endif

INITFILECOMMIT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab exclusive access on the initfile routines, and
		use the passed buffer as a temporary init file.

CALLED BY:	GLOBAL

PASS:		ax - handle of memory block that will be used for init
			file reads/writes
		bx - file handle
		cx - size of file

RETURN:		if error
			carry set
			init file contains non-ascii characters, or is
			not in a valid init file format.
		else
			carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileGrab	proc far

	uses	ax, bx, cx, ds
	.enter

		call	LoadVarSegDS_PInitFile

	;
	; Save the current init file handle and buffer handle
	;

		xchg	ax, ds:[loaderVars].KLV_initFileBufHan
		mov	ds:[savedInitFileBuffer], ax

		xchg	bx, ds:[loaderVars].KLV_initFileHan
		mov	ds:[savedInitFileHandle], bx

		xchg	cx, ds:[loaderVars].KLV_initFileSize
		mov	ds:[savedInitFileSize], cx

if ERROR_CHECK
	;
	; Make sure we were passed a valid file
	;

		mov_tr	bx, ax				; buffer handle
		call	MemLock
		mov	ds, ax
		call	ValidateIniFileFar
		call	MemUnlock
endif

	.leave
	ret
InitFileGrab	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileRelease
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the temporary init file to disk, restore the
		original init file, and release the init file semaphore.

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
INITFILERELEASE	proc far
		uses	ax, ds
		.enter

		call	InitFileCommit

		LoadVarSeg	ds
		mov	ax, ds:[savedInitFileBuffer]
		mov	ds:[loaderVars].KLV_initFileBufHan, ax

		mov	ax, ds:[savedInitFileHandle]
		mov	ds:[loaderVars].KLV_initFileHan, ax

		mov	ax, ds:[savedInitFileSize]
		mov	ds:[loaderVars].KLV_initFileSize, ax


		call	VInitFileWrite


		.leave
		ret
INITFILERELEASE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileMakeCanonicKeyCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts an SBCS/DBCS (depending on GEOS version)
		string to one which is suitable for use as an initfile
		key/category.  Namely, it will be SBCS, and contain only
		printible ASCII characters, minus any special INI file
		characters.


CALLED BY:	GLOBAL
PASS:		ds:si	= TCHAR ASCIIZ string
		es:di	= Buffer for resulting Canonicalized string.
			  SBCS: Buffer must be twice as large as
			        source string (including NULL).
			  DBCS: Buffer must be as large as source buffer
				(including NULL)

RETURN:		es:di	= Buffer filled with SBCS ASCIIZ result.
			  Result is guaranteed never to be larger than
			  the above sizes.

DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

		The following conversions will be applied to each
		character in the source (<nil> means omitted)

		printable ASCII		-> Equivalent ASCII
		C_SPACE			-> C_SPACE
		{}=;\[]			-> Ascii Hex
		other			-> Ascii Hex

REVISION HISTORY:
	Name	Date		Description

	----	----		-----------
	CT	8/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Table of boundaries between alternating ranges of characters which
; do/don't need conversion to ASCII hex (each entry is the last character
; in a range).  Some of the conversion ranges include more characters
; than we really need to, but it doesn't matter, as long as the result
; doesn't contain any illegal chars.  And being over-general lets us
; specify fewer ranges, reducing the size of the table.
;

cvtRanges	label TCHAR	; Chars converted

	TCHAR C_SPACE-1		; Control chars (0-31)
	TCHAR ';'-1, '>'	;  ; < = >  ('>' not necessary, but included
	TCHAR '['-1, ']'	; [ \ ]		for consistency with '<')
	TCHAR '{'-1, -1		; { | } ~ DEL -> last-possible-char

InitFileMakeCanonicKeyCategory	proc	far
	uses	ax,si,di,bp
	.enter

cvtChar:
	;
	; Load next source char
	;

EC <		call	ECCheckBounds					>
EC <		segxchg	ds, es						>
EC <		xchg	si, di						>
EC <		call	ECCheckBounds					>
EC <		segxchg	ds, es						>
EC <		xchg	si, di						>

SBCS <		lodsb							>
SBCS <		tst	al						>

DBCS <		lodsw							>
DBCS <		tst	ax						>

		jz	endCvt
		mov	bp, -(size TCHAR)
tryRange:
	;
	; figure out whether the character falls within a converion
	; range or not.
	;
DBCS <		inc	bp						>
		inc	bp
SBCS <		cmp	al, cs:cvtRanges[bp]				>
DBCS <		cmp	ax, cs:cvtRanges[bp]				>
		ja	tryRange
SBCS <		test	bp, 01b			; bp = odd or even entry? >
DBCS <		test	bp, 10b						 >
		jz	hexify			; if even, convert
store::						;    odd, copy
	;
	; Char is acceptable ASCII, so just store the byte in the output
	;
		stosb
		jmp	cvtChar
hexify:
	;
	; Convert ax (byte/word) to ASCII Hex in output
	;
DBCS <		push	ax						>
DBCS <		call	Hex8ToAscii					>
DBCS <		mov	al, ah						>
DBCS <		pop	ax						>
		call	Hex8ToAscii		; di updated

		jmp	cvtChar
endCvt:
		stosb
	.leave
	ret
InitFileMakeCanonicKeyCategory	endp

InitfileWrite	ends

Patching	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileBackupLanguage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Backup the current .INI file to the appropriate
		language patch directory, so it could be restored
		later.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if MULTI_LANGUAGE
EC	< initECInitFileName	char	"geosec.ini",0			>
NEC	< initInitFileName		char	"geos.ini",0			>
endif

InitFileBackupLanguage	proc	far
if MULTI_LANGUAGE
		uses	ax,bx,cx,dx,si,di,ds,es
		.enter

	; Save the initfile to disk (before the language change).

		call	InitFileCommit

	; Go to old language patch directory.

		call	GeodeSetLanguagePatchPath
		jnc	pathSet			; Successfully set path.

	; Path did not exist.  Create it and change to it.

		call	CreateLanguagePatchDir
		call	FilePopDir
		call	GeodeSetLanguagePatchPath
		jc	done			; Still got error: abort.

pathSet:

	; Set es:di to name of .ini file.

		segmov	es, cs, di
EC <		mov	di, offset initECInitFileName			>
NEC <		mov	di, offset initInitFileName				>

	; Copy the name to the stack if running under XIP.

FXIP <		segmov	ds, es, dx					>
FXIP <		call	SysCopyToStackDSSIFar				>
FXIP <		segmov	es, ds, dx					>

	; Copy old language's initfile so we can restore it if we ever
	; use this this language again.

		LoadVarSeg ds
		mov	si, ds:[loaderVars].KLV_initFileHan
		clr	dx		; Use current path as destination.
		mov	ds, dx		; Use file handle for source.
		mov	cx, SP_TOP
		call	FileCopy

	; Restore the stack if necessary.

FXIP <		call	SysRemoveFromStackFar				>

done:	; Reset original directory.

		call	FilePopDir


		.leave
endif ; (MULTI-LANGUAGE)
		ret

InitFileBackupLanguage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileSwitchLanguages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the current .ini file buffer, and load a new
		buffer with the .ini file last used for the newly
		specified language.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileSwitchLanguages	proc	far
if MULTI_LANGUAGE
		uses	ax,bx,cx,dx,ds
		.enter

	; Load the new .ini file into a buffer.

		call	GeodeSetLanguagePatchPath
		jc	done			; Error on setting path.
		mov	ax, mask FOARF_ADD_EOF \
				or FILE_DENY_W or FILE_ACCESS_R
		segmov	ds, cs, dx
EC <		mov	dx, offset initECInitFileName			>
NEC <		mov	dx, offset initInitFileName				>
		call	FileOpenAndRead
			; ax = handle of new .ini buffer.
		jc	done			; Reading new .ini file.

	; Lock the .ini file.

		call	LoadVarSegDS_PInitFile

	; Get the old .ini buffer handle from kdata.

		mov	bx, ds:[loaderVars].KLV_initFileBufHan
		push	bx		; Old buffer handle.

	; Save the new .ini buffer handle to kdata.

		mov	ds:[loaderVars].KLV_initFileBufHan, ax

	; Set the owner of the new block to the owner of the old block
	; (the kernel).

		call	MemOwnerFar
			; bx = owner of old block
		xchg	ax, bx
			; ax = owner of old block
			; bx = handle of new .ini buffer
		call	HandleModifyOwner

	; Free the old buffer.

		pop	bx		; Old buffer handle.
		call	MemFree

	; Unlock the .ini file.

		call	VInitFileWrite

done:	; Restore original path.

		call	FilePopDir

		.leave
endif ; (MULTI-LANGUAGE)
		ret

InitFileSwitchLanguages	endp


Patching ends

