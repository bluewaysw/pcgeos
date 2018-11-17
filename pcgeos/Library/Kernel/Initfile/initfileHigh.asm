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
DBCS <	shr	cx, 1							>
DBCS <	EC <ERROR_C	ILLEGAL_INIT_FILE_STRING	;odd size	>>
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
	call	InitFileReadString
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
	call	InitFileReadString
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
DBCS <	shr	cx, 1			; # bytes -> # chars		>
DBCS <	EC <ERROR_C	ILLEGAL_INIT_FILE_STRING			>>
	LocalPrevChar	esdi		; es:di = end of string
	std
	LocalFindChar			; es:di = before null
DBCS <	shl	cx, 1			; # chars -> # bytes		>
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

SBCS <	lea	cx, es:[di-1]	; include the null			>
DBCS <	lea	cx, es:[di-2]	; include the null			>

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
	call	PopAllFar
	ret

	; Category/key wasn't found, so we must be the first string
	;
noStringsNoMem:
	clr	bx				; no memory to free
noStrings:
	pop	es, di				; string buffer => ES:DI
	jmp	writeString			; now write the string
InitFileWriteStringSection	endp


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
	.enter
	
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
DBCS <	shl	cx, 1				; # chars -> # bytes	>
	add	si, cx				; go to end of section
	mov	cx, ax				; # of chars left => CX
	jcxz	atEnd
SBCS <	add	si, 2				; jump past CR/LF separator>
DBCS <	add	si, 4				; jump past CR/LF separator>
	sub	cx, 2				; move two fewer chars
DBCS <	jc	forceTerminate			; only one char, must be NULL>
SBCS <	rep	movsb				; move the chars	>
DBCS <	rep	movsw				; move the chars	>
	jmp	terminate			; go terminate the string

DBCS <forceTerminate:							>
DBCS <	xor	cx, cx				; clear cx and carry	>
DBCS <	jmp	terminate						>

	; We're at the end. Either back up two character for the destination
	; or we have no more strings left
atEnd:
	tst	di
	jz	terminate
SBCS <	sub	di, 2							>
DBCS <	sub	di, 4							>

	; We're done. Write the string back to .INI file
terminate:
SBCS <	mov	es:[di], cl			; store the NULL terminator>
DBCS <	mov	es:[di], cx			; store the NULL terminator>
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

	call	EnterInitfile	;es,bp <- dgroup
	call	FindCategory
	jc	exit
	call	FindKey		;initFileBufPos = body, curKeyOffset
	jc	exit

	;-----------------------------------------------------------------------
	;locate end of body

	clr	bx			;not starting in blob
	call	GetCharFar
	jc	exit

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
exit:
	call	ExitInitfile

	.leave
	ret
InitFileDeleteEntry	endp


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
;	mov	ax, ds:[initFileBackupSize]
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
EC < 	call	ValidateIniFileFar	; Check to see if buffer was trashed >
NEC < 	call	ValidateIniFile		; Check to see if buffer was trashed >
LONG	jc	error			; branch if so...

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
	mov	es:[trashedIniBuffer], TRUE	;Set flag saying the .ini buffer
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

