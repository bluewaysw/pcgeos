COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		pccomFSel.asm

AUTHOR:		Robert Greenwalt, May 12, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/12/95   	Initial revision


DESCRIPTION:
	stuff for PCComFileSelectorClass
		

	$Id: pccomFSel.asm,v 1.1 97/04/05 01:25:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCComFileSelector	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMFILEENUM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Act like a limited FileEnum, but fetch the data over
		the serial line.

CALLED BY:	GLOBAL
PASS:		on stack
			fptr to FileEnumParams
			fptr to hptr into which we'll stick the buffer
				created
			fptr to a word in which will stuff the number
				that didn't fit
RETURN:		We will fill in the return buffer and the numNoFit
			and put the number of files that fit in ax
		On Error returns -1 (use ThreadGetError to fetch a
			FileError)
DESTROYED:	nothing
SIDE EFFECTS:	

NOTE:  ** we only handle DOS FILENAMES! **  This superceeds the
standard FileEnum behavior (including wildcarded filespec). 

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMFILEENUM	proc	far	params:fptr.FileEnumParams,
				bufCreated:fptr.hptr, numNoFit:fptr.word
	uses si, di, ds, es
	.enter

		mov	dx, ds			;save real DS
	;
	; put parameters on the stack
	;
		lds	si, params
		segmov	es, ss
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		mov	cx, size FileEnumParams
		sub	sp, cx
		mov	di, sp
		push	si, di
		rep	movsb
		pop	si, di
	;
	; Now actually do the job
	;
		call	{far}PCComFileEnum	;pops off args
	;
	; Check for errors 
	;  ax=error code
	;  cx=numFit
	;  carry set on error
	;
		mov	ss:[TPD_error], 0
		xchg	ax, cx
		jnc	haveRetval
		mov	ss:[TPD_error], cx
		mov	ax, -1
haveRetval:
		lds	si, ss:[bufCreated]
		mov	ds:[si], bx

		mov	si, numNoFit.segment
		tst	si
		jz	noStoreNumNoFit
		lds	si, numNoFit
		mov	ds:[si], dx

noStoreNumNoFit:
		.leave
		ret
PCCOMFILEENUM	endp
	SetDefaultConvention



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Act like a limited FileEnum, but fetch the data over
		the serial line.

CALLED BY:	OLFSBuildFileList
PASS:		just like FileEnum
	FileEnumParams structure on stack:
	(note: ss:sp *must* be pointing to FileEnumParams)

	stack parameter passing example:

	sub	sp, size FileEnumParams
	mov	bp, sp
	mov	ss:[bp].FEP_*			; fill in params...
	...
	call	FileEnum
	jc	error				; handle error
	<use FileEnum results>			; success!!

RETURN:		just like FileEnum
	carry - set if error
	ax - error code (if an error)
	bx - handle of buffer created, if any. If no files found, or if
	     error occurred, no buffer is returned (bx is 0)
	cx - number of matching files returned in buffer
	dx - number of matching files that would not fit in buffer
		(given maximum of FEP_bufSize)
		(If FEP_bufSize is set to 0, this is a count of the matching
		 files in the directory)

	(in buffer) - structures (of type requested by FEP_returnAttrs) for
			files found (if filesystem is case-insensitive,
			native names returned in UPPER case)
	if FESF_REAL_SKIP bit set:
		di - updated real skip count (matching file or not)
	if FESF_REAL_SKIP bit clear:
		di - preserved
	FileEnumParams popped off the stack

DESTROYED:	nothing
SIDE EFFECTS:	

NOTE:  ** we only handle DOS FILENAMES! **  This superceeds the
standard FileEnum behavior (including wildcarded filespec). 

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnum	proc	far	params:FileEnumParams
locals		local	PFELocals
	uses	si, di, es, ds
	ForceRef locals
	ForceRef params
	.enter
		call	PCComFileEnumInit
		jc	memError

		call	PCComFileEnumFetchDir
		je	dirProblems
nextFile:
		call	PCComFileEnumNextFile
		jc	parseProblems
		jz	outOfFiles
	;
	; Allocate room in the retBuffer for the next entry - bail if
	; trouble
	;
		call	PCComFileEnumAllocSpace
		jc	outOfFiles
	;
	; Now, parse the various elements.  Note that PCComDir gives
	; things like: 
	;  NAME.000    1234 10-12-94  3:44p ------ data 0.0.0.0
	; so we have to parse Name, size, time/date, attributes in
	; that order.  We don't have to record them, but must read
	; through them. 
	; ds:si - directory buffer read through upto the current field
	; 	  (with optional preceeding spaces).
	; es:di - return buffer, beginning of current record
	; bx - handle of return buffer (for realloc purposes)
	; dx - size of return buffer
	;
		call	PCComFileEnumNameParse

		call	PCComFileEnumSizeParse

		call	PCComFileEnumDateTimeParse

		call	PCComFileEnumAttrParse

		call	PCComFileEnumCheckMatchAttrs
		mov	ah, 2				; for EnumNextFile

		jmp	nextFile

outOfFiles:
		clc
		mov	dx, ax

done:
		call	PCComFileEnumDeparturePrep
		.leave

		ret	@ArgSize

memError:
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	dirProblems

parseProblems:
	;
	; We saw stuff we didn't like while parsing
	;
		clr	ax
dirProblems:
		clr	cx,bx,dx
		stc
		jmp	done
PCComFileEnum	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchReturnAttrOffsetAndSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flip through FEAD table and find the offset of the
		attribute requested.

CALLED BY:	PCComFileEnum
PASS:		bx	- FileExtendedAttribute
RETURN:		bx	- offset or 0xFFFF if not found
		cx	- size, if found
		carry set if not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FetchReturnAttrOffsetAndSize	proc	near
	uses	ax, si, ds
	.enter	inherit PCComFileEnum
		movdw	dssi, ss:[params].FEP_returnAttrs
loopTop:
		mov	ax, ds:[si].FEAD_attr
		add	si, size FileExtAttrDesc
		cmp	ax, FEA_END_OF_LIST
		je	notFound
		cmp	ax, bx
		jne	loopTop
		sub	si, size FileExtAttrDesc
		mov	bx, ds:[si].FEAD_value.offset
		mov	cx, ds:[si].FEAD_size
		clc
done:
	.leave
	ret
notFound:
		stc
		mov	bx, 0xFFFF
		jmp done
FetchReturnAttrOffsetAndSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start off enumeration.

CALLED BY:	PCComFileEnum
PASS:		inherit the stack from PCComFileEnum
RETURN:		carry set on Error
DESTROYED:	ax, bx, cx, si, ds
SIDE EFFECTS:	buffers created
		locals filled in

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	8/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumInit	proc	near
	.enter	inherit PCComFileEnum
	;
	; Initialize locals
	;
		clr	ss:[locals].PFEL_retBuffer
		clr	ss:[locals].PFEL_dirBuffer
		clr	ss:[locals].PFEL_entriesCounted
	;
	; Check out the params - determine some offsets
	;
		mov	bx, FEA_DOS_NAME
		call	FetchReturnAttrOffsetAndSize	; bx = offset,
							; cx = size
		mov	ss:[locals].PFEL_dosNameOffset, bx
		mov	ss:[locals].PFEL_dosNameSize, cx
EC<		cmp	cx, DOS_DOT_FILE_NAME_SIZE			>
EC<		ERROR_B	MISC_ERROR					>

		mov	bx, FEA_NAME
		call	FetchReturnAttrOffsetAndSize
		mov	ss:[locals].PFEL_nameOffset, bx
		mov	ss:[locals].PFEL_nameSize, cx
	;
	; it needs to be DOS_DOT_FILE_NAME_SIZE or greater, else you
	; may leave parts of the name behind - it's a dos name anyway!
	;
EC<		cmp	cx, DOS_DOT_FILE_NAME_SIZE			>
EC<		ERROR_B MISC_ERROR					>

		mov	bx, FEA_SIZE
		call	FetchReturnAttrOffsetAndSize
		mov	ss:[locals].PFEL_sizeOffset, bx
		mov	ss:[locals].PFEL_sizeSize, cx
EC<		cmp	cx, size dword					>
EC<		ERROR_B	MISC_ERROR					>

		mov	bx, FEA_CREATION
		call	FetchReturnAttrOffsetAndSize
		mov	ss:[locals].PFEL_creationOffset, bx
		mov	ss:[locals].PFEL_creationSize, cx
EC<		cmp	cx, size FileDateAndTime			>
EC<		ERROR_B	MISC_ERROR					>

		mov	bx, FEA_MODIFICATION
		call	FetchReturnAttrOffsetAndSize
		mov	ss:[locals].PFEL_modificationOffset, bx
		mov	ss:[locals].PFEL_modificationSize, cx
EC<		cmp	cx, size FileDateAndTime			>
EC<		ERROR_B	MISC_ERROR					>

		mov	bx, FEA_FILE_ATTR
		call	FetchReturnAttrOffsetAndSize
		mov	ss:[locals].PFEL_fileAttrOffset, bx
		mov	ss:[locals].PFEL_fileAttrSize, cx
EC<		cmp	cx, size FileAttrs				>
EC<		ERROR_B	MISC_ERROR					>

	;
	; Initialize buffers
	;

		mov	ax, ss:[params].FEP_returnSize
		push	ax
		mov	cx, ALLOC_DYNAMIC
		call	MemAlloc
		pop	ax		;FEP_returnSize
		jc	done
		mov	ss:[locals].PFEL_dirBuffer, bx

		mov	cx, ALLOC_DYNAMIC or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		jc	done
		mov	ss:[locals].PFEL_retBuffer, bx
done:
	.leave
	ret
PCComFileEnumInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumFetchDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the directory listing from the remote

CALLED BY:	PCComFileEnum
PASS:		inherit stack from PCComFileEnum
RETURN:		ds:si - locked dirBuffer (filled)
		es:di - locked retBuffer (empty)
		bx - retBuffer handle
		ah - number of '\a' and '\d' to find before parsing
			first line (4)
		z-flag set on error
DESTROYED:	al, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	8/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumFetchDir	proc	near
	.enter	inherit	PCComFileEnum
	;
	; check for filename to match
	;
		clr	cx, bx
		test	ss:[params].FEP_searchFlags, mask FESF_CALLBACK
		jz	haveMatch
		cmp	ss:[params].FEP_callback.offset, FESC_WILDCARD
		jne	haveMatch
		movdw	cxbx, ss:[params].FEP_cbData1
haveMatch:
	;
	; Fetch the directory from the remote
	;
		push	ss:[locals].PFEL_dirBuffer
		mov	ax, PCCDDL_MID_DETAIL
		push	ax
		pushdw	cxbx	; pointer to filespec
		call	PCCOMDIR
		cmp	al, PCCRT_NO_ERROR
		jne	error
tryAnyway:
	;
	; OK, setup the buffers
	;  ds:si - dirBuffer
	;  es:di - retBuffer
	;  bx - retBuffer handle
	;  dx - retBuffer size
	;
		mov	ax, MGIT_SIZE
		mov	bx, ss:[locals].PFEL_dirBuffer
		call	MemGetInfo
		mov	ss:[locals].PFEL_dirSize, ax

		call	MemLock
		mov	ds, ax

		mov	bx, ss:[locals].PFEL_retBuffer
		call	MemLock
		mov	es, ax

		clr	dx, si, di
		mov	ah, 4		; the number of \a or \d to
					; find initially (see
					; PCComFileEnumNextFile) 
		cmp	ah, dl		; clr z
done:
		.leave
		ret

error:
		cmp	al, PCCRT_TOO_MUCH_OUTPUT
		je	tryAnyway
		cmp	al, PCCRT_MEMORY_ALLOC_ERROR
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		je	done
		clr	ax
		cmp	ax, ax		; set zero
		jmp	done
PCComFileEnumFetchDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumNextFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read through passed buffer until we detect another file

CALLED BY:	INTERNAL	PCComFileEnum
PASS:		ds:si - buffer to check
		ah - number of \d and \a to find
RETURN:		carry clear if successful
			ds:si advanced to position of next file in buffer
			zero-flag set if at end of buffer
		carry set on error
DESTROYED:	ax, cx  (bx, dx also if zero-flag set)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	8/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumNextFile	proc	near
	.enter	inherit PCComFileEnum
	;
	; OK, now read the buffer til we get to the end of the line
	; (either \d\a or \a\d).
	;
		mov	cx, 0d0ah
lineEndSearch:
		cmp	si, ss:[locals].PFEL_dirSize
		jae	pastBufferEnd
		lodsb
		cmp	al, cl
		je	foundOne
		cmp	al, ch
		jne	lineEndSearch
foundOne:
		dec	ah
		jnz	lineEndSearch
	;
	; Check for end-of-buffer.  Either a null or a "C:DOS>" prompt
	;
		mov	ax, ds:[si]
		tst	al
		jz	outOfFiles
		cmp	ah, ':'
		jz	outOfFiles
	;
	; Check for funky dir entries (ie "." and "..")
	;
		cmp	al, '.'
		je	directoryFound
		clc
done:
	.leave
	ret

pastBufferEnd:
		stc
		jmp	done
outOfFiles:
	;
	; first we need to reallocate this block - the last entry may
	; have been backed out (it was a vol name or something) but
	; that just adjusted dx..  so we need to shrink the block to
	; the current dx size
	;
		call	PCComFileEnumAllocSpace
		Assert	carryClear
	;
	; unlock the return buffer and set up bx, dx, cx for return.
	; Set Z-flag, which indicates the end of listing.
	; Clear the carry, which it indicates we're still within the buffer.
	;
		clc
		and	bx, 0
		mov	dx, bx
		mov	cx, ss:[locals].PFEL_entriesCounted
		jcxz	done
		xchg	ss:[locals].PFEL_retBuffer, bx
		call	MemUnlock
		jmp	done	
	;
	; found a funky dir entry, so skip through it
	;
directoryFound:
		mov	ah, 2
		jmp	lineEndSearch
PCComFileEnumNextFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumAllocSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate room for the next entry - if trouble then we bail

CALLED BY:	PCComFileEnum
PASS:		inherit stack of PCComFileEnum
		dx - size of retBuffer
		bx - handle of retBuffer
		es:di - advanced to next record, Filename field
RETURN:		carry set on mem-error
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	8/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumAllocSpace	proc	near
	.enter	inherit PCComFileEnum
		mov	di, dx
		add	dx, ss:[params].FEP_returnSize
		jc	error
		mov	ax, dx
		mov	ch, mask HAF_ZERO_INIT
		call	MemReAlloc
		jc	error
		mov	es, ax
done:
	.leave
	ret
error:
	;
	; We treat this as an out-of-files condition
	;
		mov	bx, 0
		mov	dx, bx
		mov	cx, ss:[locals].PFEL_entriesCounted
		jcxz	done
		xchg	ss:[locals].PFEL_retBuffer, bx
		call	MemUnlock
		stc
		jmp	done
PCComFileEnumAllocSpace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumNameParse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy the filename out of one buffer into another, in CAPS

CALLED BY:	pccomFileEnum
PASS:		ds:si - input buffer
		es:di - return buffer (beginning of record)
RETURN:		input buffer advanced through name
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumNameParse	proc	near
	uses	bx, dx, cx
	.enter	inherit	PCComFileEnum

		call	SkipSpaces
		dec	si
		push	si		; in case we need to do this
					; twice
		clr	cx
	;
	; check for DOS_NAME request
	;
		mov	bx, ss:[locals].PFEL_dosNameOffset
		cmp	bx, 0xFFFF
		je	dosDone
		inc	cx
		mov	dl, CSTT_NO_TRANSLATION
		mov	ax, ss:[locals].PFEL_dosNameSize
		call	DoName
dosDone:
	;
	; check for NAME request (which we answer with the dos name,
	;   because that's all we have!)
	;
		mov	bx, ss:[locals].PFEL_nameOffset
		cmp	bx, 0xFFFF
		pop	ax
		je	done
		inc	cx
		mov	si, ax
		mov	ax, ss:[locals].PFEL_nameSize
		mov	dx, CSTT_DOS_TO_GEOS
		call	DoName
done:
		jcxz	didNeither
reallyDone:
	.leave
	ret

didNeither:
		call	SkipNonSpaces
		jmp	reallyDone
PCComFileEnumNameParse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just copy the name over, upshifting as we go

CALLED BY:	PCComFileEnumParseName
PASS:		ds:si - input buffer
		bx - offset into record for this field
		es:di - return buffer (beginning of record)
		dl - CharSetTranslationType (either non or dos_to_geos)
		ax - size of space to store in
RETURN:		ds:si advanced through name
DESTROYED:	bx,ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoName	proc	near
	uses	cx,di
	.enter
	;
	; check for translation - code page or 0 will sit in DX
	;
		clr	cx
		cmp	dl, CSTT_DOS_TO_GEOS
		jne	haveCodePage
		push	ds
		LoadDGroup	ds
		mov	cx, ds:[remoteCodePage]
		pop	ds
haveCodePage:
		mov	dx, cx
	;
	; Read in the name - 8.3 (12 chars) upto a space
	;
		add	di, bx
		mov	cx, ax
		jcxz	done
		dec	cx
		jcxz	nullTerminate
		mov	bx, '-'
nameLoop:
		lodsb
		cmp	al, ' '			; is current char a space?
		je 	nullTerminate
		tst	dx			; do xlation?
		jz	storeNameChar
		xchg	dx, cx			; preserve char count
						; while putting code
						; page in cx
		call	LocalCodePageToGeosChar
		xchg	dx, cx			; restore codepage in
						; dx and charcount in cx
storeNameChar:
		stosb
		loop	nameLoop
	;
	; And null terminate it.
	;
nullTerminate:
		clr	al
		stosb
done:
	.leave
	ret
DoName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumSizeParse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the size of the file in the return buffer (if requested)

CALLED BY:	PCComFileEnum
PASS:		ds:si - input buffer (spaces optional)
		es:di - output buffer at beginning of record
RETURN:		ds:si advanced past file size
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumSizeParse	proc	near
	uses	bx,dx,di
	.enter	inherit PCComFileEnum
		call	SkipSpaces
		dec	si
	;
	; Check if we should even bother
	;
		mov	bx, ss:[locals].PFEL_sizeOffset
		cmp	bx, 0xFFFF
		je	done
		add	di, bx
		cmp	ss:[locals].PFEL_sizeSize, (size dword)	
						; filesizes are dwords!
		jb	done
	;
	; UtilAsciiToHex32 needs a null terminated number string, 
	; so place a null after the number but remember where we
	; put it so we can remove it when we're done.
	;
		mov	bx, si		; bx <- offset of start of number
		call	SkipNonSpaces	; si <- offset of char after the space
					;	after the number
		dec	si		; si <- offset of space after the number
		clr	{byte}ds:[si]	; null the space
		xchg	si, bx		; si <- offset of start of number
					; bx <- offset to null
	;
	; Parse size
	;
		call	UtilAsciiToHex32
		mov	{byte}ds:[bx], C_SPACE	; restore the space
		jnc	haveNumber
		clr	ax,dx
haveNumber:
	;
	; store results
	;
		movdw	es:[di], dxax
	;
	; and read until we find a space
	;
done:
		call	SkipNonSpaces
	.leave
	ret
PCComFileEnumSizeParse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipNonSpaces
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read through a bunch of non-spaces

CALLED BY:	internal
PASS:		ds:si - buffer to read from
RETURN:		al - first space
		ds:si advanced
DESTROYED:	ah
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipNonSpaces	proc	near
	.enter
		mov	ah, ' '
moreNonSpaces:
		lodsb
		cmp	al, ah
		jne	moreNonSpaces
	.leave
	ret
SkipNonSpaces	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipSpaces
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read through a bunch of spaces

CALLED BY:	internal
PASS:		ds:si - buffer to read from
RETURN:		al - first non-space char read
		ds:si advanced
DESTROYED:	ah
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipSpaces	proc	near
	.enter
		mov	ah, ' '
moreSpaces:
		lodsb
		cmp	al, ah
		je	moreSpaces	
	.leave
	ret
SkipSpaces	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumDateTimeParse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the Date and Time info from the buffer and store it.

CALLED BY:	PCComFileEnum
PASS:		ds:si - input buffer (spaces optional)
		es:di - output buffer at beginning of record
RETURN:		ds:si advanced past the date/time stuff
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumDateTimeParse	proc	near
	uses	bx,cx
	.enter	inherit PCComFileEnum
		call	SkipSpaces
		dec	si
		clr	cx		; flag indicating whether
					; DoDateTime is called
	;
	; Check if we should do anything
	;
		push	si		; start of input buffer
		mov	bx, ss:[locals].PFEL_creationOffset
		cmp	bx, 0xFFFF
		je	noCreation
		cmp	ss:[locals].PFEL_creationSize, size FileDateAndTime
		jb	noCreation
		call	DoDateTime	; cx <= TRUE
					; si <= advanced past date/time
noCreation:
		mov	bx, ss:[locals].PFEL_modificationOffset
		cmp	bx, 0xFFFF
		pop	ax		; start of input buffer
		je	done
		cmp	ss:[locals].PFEL_modificationSize, size FileDateAndTime
		jb	done
		mov	si, ax		; reset si to start of input buffer
		call	DoDateTime	; cx <= TRUE, 
					; si <= advanced past date/time

done:
		cmp	cx, TRUE
		jne	didNeither

reallyDone:
	.leave
	ret

didNeither:
	;
	; We didn't need either FEA_*, and so didn't read the input
	; buffer - do so now
	;
		call	SkipNonSpaces	; date
		call	SkipSpaces	; gap
		call	SkipNonSpaces	; time
		jmp	reallyDone

PCComFileEnumDateTimeParse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ugly - parse text into the silly FileDateAndTime format

CALLED BY:	PCComFileEnumDateTimeParse
PASS:		ds:si - input buffer (spaces optional)
		es:di - output buffer at beginning of record
		bx - offset into record to dump stuff

RETURN:		ds:si - advanced through date and time
		cx - TRUE

DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoDateTime	proc	near
	uses	dx,di
	.enter	inherit PCComFileEnum
		add	di, bx
		clr	dx, bx
	;
	; month
	;
		call	TwoDigitsToBinary
		mov	cl, offset FD_MONTH
		shl	ax, cl
		mov	dx, ax
	;
	; day
	;
		inc	si
		call	TwoDigitsToBinary
		mov	cl, offset FD_DAY
		shl	ax, cl
		or	dx, ax
	;
	; year
	;
		inc	si
		call	TwoDigitsToBinary
		mov	cl, offset FD_YEAR
		sub	ax, 80
		shl	ax, cl
		or	dx, ax
	;
	; hour
	;
		inc	si
		call	TwoDigitsToBinary
		mov	cl, offset FT_HOUR
		cmp	ax, 12
		jne	continue
		clr	ax
continue:
		shl	ax, cl
		mov	bx, ax
	;
	; minutes
	;
		inc	si
		call	TwoDigitsToBinary
		mov	cl, offset FT_MIN
		shl	ax, cl
		or	bx, ax
	;
	; a/p
	;
		lodsb
		cmp	al, 'p'
		jne	done
		add	bx, (12 shl (offset FT_HOUR))
		mov	es:[di].FDAT_date, dx
		mov	es:[di].FDAT_time, bx
done:
		mov	cx, TRUE
	.leave
	ret
DoDateTime	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TwoDigitsToBinary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read in two digits and atoi them

CALLED BY:	internal
PASS:		ds:si - input buffer
RETURN:		ax - value of two digits
		ds:si - advanced past two chars
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TwoDigitsToBinary	proc	near
	.enter
		lodsb
		sub	al, '0'
		mov	ah, 10
		mul	ah
		mov	ah, al
		lodsb
		add	al, ah
		sub	al, '0'
		clr	ah
	.leave
	ret
TwoDigitsToBinary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumAttrParse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the file attributes and write FileAttr out.

CALLED BY:	PCComFileEnum
PASS:		inherit stack from PCComFileEnum
		dx - size of return buffer (end of last record)
		es:di - return buffer at beginning of record
		ds:si - dir buffer after filename
RETURN:		ah - FileAttrs to be passed to PCComFileEnumCheckMatchAttrs
DESTROYED:	al
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	8/24/95    	Initial version
	jmagasin 11/14/95	Return FileAttrs, don't reject file.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumAttrParse	proc	near
	uses	cx, bx, di, dx
	.enter	inherit PCComFileEnum
		call	SkipSpaces
		dec	si
	;
	; Get offset at which to store the file attributes once
	; they're parsed.  If offset is -1, we don't store them.
	;
		mov	bx, ss:[locals].PFEL_fileAttrOffset
		add	di, bx
	;
	; set up to parse - we are going to construct it bitwise by
	; going down the string of attrs and comparing to '-' if attr
	; is set then we will get a letter instead of '-'.
	; ADVSHR
	;
		mov	cx, 6
		mov	ah, '-'
		clr	dx
attrCheck:
		lodsb
		cmp	ah, al
		rcl	dx
		loop	attrCheck

	;
	; Now see if we want to store the attrs in our return buffer.
	;
		cmp	bx, 0xFFFF			; Store file attr?
		je	done				; Nope.
	;
	; Verify that we have space to store a FileAttr
	;
		cmp	ss:[locals].PFEL_fileAttrSize, size FileAttrs
		jb	done

		mov	es:[di], dl			; Store attrs.
done:
		mov_tr	ah, dl				; Return attrs.
	.leave
	ret
PCComFileEnumAttrParse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumCheckMatchAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we've been given FEP_matchAttrs, check that the
		file under scrutiny matches.  If not, reject the
		file (as if it was never seen).

CALLED BY:	PCComFileEnum *immediately after PCCOmFileEnumAttrParse*
PASS:		inherit stack from PCComFileEnum
		ah - FileAttrs of file we'll check
		dx - size of return buffer (end of last record)
RETURN:		updated dx if we needed to back out the change (i.e.,
		 reject this file)
		PFEL_entriesCounted inc'd if we keep this file		
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 11/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumCheckMatchAttrs	proc	near
	uses	bx
	.enter	inherit PCComFileEnum

	;
	; OK, was it a Volume name?  We don't accept volume names!
	;
		test	ah, mask FA_VOLUME
		jnz	backOut

	;
	; Compare attrs for this file against passed match/don't match
	; attrs.  Since FileAttrs is byte-sized, match attrs are in
	; offset.low and don't match attrs are in offset.high.
	; Remember, PCComFileEnum parameters are on the stack.
	;
		tst	{word}ss:[params].FEP_matchAttrs.segment
		jz	keepThisFile			; Accept all files.

		push	ds,si
		lds	si, ss:[params].FEP_matchAttrs
		mov	bx, {word}ds:[si].FEAD_value.segment
		mov	al, bl				; stuff not to match
		mov	bx, {word}ds:[si].FEAD_value.offset
		mov	bh, al				; bl=match stuff
							; bh=no match stuff
		pop	ds,si

		mov	al, ah				; Keep ah as copy.
		and	al, bl				; 0 out don't cares.
		cmp	al, bl				; Check match attrs.
		jne	backOut				; Missin' stuff...

		and	ah, bh				; Check no matches.
		jnz	backOut				; Bad stuff set...

keepThisFile:
		inc	ss:[locals].PFEL_entriesCounted	; Keep this file.
done:
	.leave
	ret
backOut:
	;
	; This was a volume, or lacked some required attrs, or
	; had some unwanted attrs.
	;
		sub	dx, ss:[params].FEP_returnSize
		jmp	done
PCComFileEnumCheckMatchAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumDeparturePrep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	free up the buffers

CALLED BY:	PCComFileEnum
PASS:		inherit stack from PCComFileEnum
RETURN:		nothing
DESTROYED:	nothing (not even flags)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	8/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumDeparturePrep	proc	near
	.enter	inherit	PCComFileEnum
	;
	; ok, go home..  free up any left over buffers (note, this'll
	; kill a retBuffer if you haven't xchge'd it with 0 first).
	; We expect to find ax and then flags on the stack.
	;
		pushf
		push	bx
		mov	bx, ss:[locals].PFEL_retBuffer
		tst	bx
		jz	noRetBuffer
		call	MemFree
noRetBuffer:
		mov	bx, ss:[locals].PFEL_dirBuffer
		tst	bx
		jz	noDirBuffer
		call	MemFree
noDirBuffer:
		pop	bx
		popf
	.leave
	ret
PCComFileEnumDeparturePrep	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCFSGenFileSelectorGetFileEnumRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to return our enum-like routine

CALLED BY:	MSG_GEN_FILE_SELECTOR_GET_FILE_ENUM_ROUTINE
PASS:		nothing of import
RETURN:		cx:ax	= vfptr to FileEnum-like routine (cx = 0 => none)
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCCFSGenFileSelectorGetFileEnumRoutine	method dynamic PCComFileSelectorClass, 
					MSG_GEN_FILE_SELECTOR_GET_FILE_ENUM_ROUTINE
		.enter
	;
	; ok..  set up the routine
	;
		mov	cx, vseg @CurSeg
		mov	ax, offset PCComFileEnum

		.leave
		ret
PCCFSGenFileSelectorGetFileEnumRoutine	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileSelectorFakePathSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We are given a path to cd to.  Do it.

CALLED BY:	MSG_GEN_PATH_SET
PASS:		*ds:si	= PCComFileSelectorClass object
		cx:dx	= Null terminated path to cd to.
		bp	= disk handle or standard path - not really
				used..  zero should be fine
RETURN:		carry set if path couldn't be set
			ax - error code ERROR_PATH_NOT_FOUND
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileSelectorFakePathSet	method dynamic PCComFileSelectorClass, 
					MSG_GEN_PATH_SET
	uses	cx
	.enter
	;
	; Check if we are returning to the startup dir
	;
		push	es, bx
		mov	es, cx
		mov	bx, dx
		tst	{byte}es:[bx]
		pop	es, bx
		jnz	retry
	;
	; We are resseting - they asked us to change to NULL.
	; Something must have gone wrong and we're trying to get to a
	; happier place.  The cached path data is almost certainly wrong
	; so kill it.
	;
		call	DoTheZap
retry:
		pushdw	cxdx
		call	PCCOMCD

.assert	PCCRT_NO_ERROR eq 0
		tst	al
		jnz	error
	;
	; The CD was successful so our stored path is invalid.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		clr	{byte}ds:[di].PCFSI_currentRemotePath		
	;
	; Pass on the message if appropriate
	;
		mov	ax, MSG_GEN_PATH_SET
		call	GenCheckIfSpecGrown
		jnc	done
		mov	di, segment GenClass
		mov	es, di
		mov	di, offset GenClass
		call	ObjCallSuperNoLock
done:
	.leave
	ret
error:
	;
	; PCCOMCD couldn't cd to a dir we know exists..  report the
	; error
	;
		call	PCComFileSelectorHandlePathError
		jc	retry
		mov	ax, ERROR_PATH_NOT_FOUND
		stc
		jmp	done
PCComFileSelectorFakePathSet	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileSelectorFakePathGet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to know the remotes CWP - including Volume
		name!

CALLED BY:	MSG_GEN_FILE_SELECTOR_FAKE_PATH_GET
PASS:		*ds:si	= PCComFileSelectorClass object
		ds:di	= PCComFileSelectorClass instance data
		ds:bx	= PCComFileSelectorClass object (same as *ds:si)
		es 	= segment of PCComFileSelectorClass
		ax	= message #
		cx:dx	= PATH_BUFFER_SIZE buffer for full, null
				terminated path.
RETURN:		cx:dx	= pointing to the null at end
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/31/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileSelectorFakePathGet	method dynamic PCComFileSelectorClass, 
					MSG_GEN_FILE_SELECTOR_FAKE_PATH_GET
	uses	bp
	.enter
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	; see if the cached path is still good
	;
		tst	{byte}ds:[di].PCFSI_currentRemotePath
		LONG jnz	recoverStoredPath

	;
	; nope, get another one
	;
		push	cx, dx, si
		sub	sp, PATH_BUFFER_SIZE
		mov	bp, sp
		segmov	es, ss
		pushdw	esbp
		call	PCComPWD		; es:bp <- path w/ drive
		tst	al
		LONG	jnz	errorOne

	;
	; and get a volume name too
	;
		sub	sp, PATH_BUFFER_SIZE	; alloc buffer
		mov	bp, sp			; ss:bp <- start of buffer
		mov	dx, ss
		mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_VOLUME_NAME_GET
		clr	cx
		call	ObjCallInstanceNoLock


	;
	; Check for error
	;
		tst	ax
		jnz	errorTwo

	;
	; copy the drive letter and volume name into PCFSI_currentRemotePath
	;
		segmov	es, ds
		add	di, PCFSI_currentRemotePath
		mov	ds, dx
		mov	si, bp
volLoop:
		lodsb
		stosb
		tst	al		; Stop if we reach a null. This
					; should never happen but we don't 
					; want to trash memory if the
					; string doesn't contain a ']'
		jz	volLoopEnd
		cmp	al, ']'
		jnz	volLoop
volLoopEnd:
		add	sp, PATH_BUFFER_SIZE
		mov	si, sp
	;
	; copy the path into PCFSI_currentRemotePath after the volume name
	;
		add	si, 2		; this skips over the drive
					; letter and the colon, but
					; gives us the first '\\'
pathLoop:
		lodsb
		stosb
		tst	al		; found the null?
		jne	pathLoop
		Assert_fptr	esdi
		Assert_fptr	dssi

		add	sp, PATH_BUFFER_SIZE
		segmov	ds, es
		pop	cx, dx, si

	;
	; OK.  The stored path is good.  fetch it.
	;
recoverStoredPath:
		mov	si, ds:[si]
		add	si, ds:[si].Gen_offset 
		add	si, PCFSI_currentRemotePath
		movdw	esdi, cxdx
		mov	cx, PATH_BUFFER_SIZE
		rep	movsb
		mov	di, dx
		mov	cx, PATH_BUFFER_SIZE
		clr	ax
		repne	scasb
		dec	di
		movdw	cxdx, esdi
	
done:
	.leave
	ret

errorTwo:
		add	sp, PATH_BUFFER_SIZE
errorOne:
		add	sp, PATH_BUFFER_SIZE
		pop	cx, dx, si
		mov	es, cx
		mov	di, dx
		mov	{word}es:[di], '\\'
		jmp	done
PCComFileSelectorFakePathGet	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileSelectorFakeVolumeNameGet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to get the volume name for a specific drive.

CALLED BY:	MSG_GEN_FILE_SELECTOR_FAKE_VOLUME_NAME_GET
PASS:		*ds:si	= PCComFileSelectorClass object
		ds:di	= PCComFileSelectorClass instance data
		ds:bx	= PCComFileSelectorClass object (same as *ds:si)
		es 	= segment of PCComFileSelectorClass
		ax	= message #
		cx	= drive # to get (0 for current)
		dx:bp	= buffer to dump to (FILE_LONGNAME_BUFFER_SIZE long)
RETURN:		ax	= non-zero on error

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	NEVER EVER return a volume name with a \ termination..  AGHH

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCComFileSelectorFakeVolumeNameGet	method dynamic PCComFileSelectorClass, 
					MSG_GEN_FILE_SELECTOR_FAKE_VOLUME_NAME_GET



	uses	cx, dx, bp
	.enter
	;
	; first determine if our cached stuff is valid
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset

		mov	bx, ds:[di].PCFSI_driveListing
		tst	bx
		LONG	jnz	cacheValid
	;
	; it's invalid - check again
	;
		push	cx
		mov	ax, 16
		mov	cx, ALLOC_DYNAMIC
		call	MemAlloc
		mov	al, 1
		pop	cx
		LONG	jc	done
		mov	ds:[di].PCFSI_driveListing, bx

		push	bx
		call	PCComListDrives
		tst	al
		jnz	freeAndLeave

		call	MemLock
		mov	es, ax

	;
	; now set up the current volume name
	;
		push	ds
		sub	sp, PATH_BUFFER_SIZE
		mov	di, sp
		pushdw	ssdi
		segmov	ds, ss
		call	PCComPWD
		mov	ah, ds:[di]		; grab the drive letter.
		add	sp, PATH_BUFFER_SIZE
		pop	ds
		tst	al
		jz	continue
freeAndLeave:
		clr	bx
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		xchg	bx, ds:[di].PCFSI_driveListing
		call	MemFree
		Assert	ne ax 0			; check that we're
						; returning (ax != 0)
						; indicating an error
		jmp	done
continue:
		clr	di
		mov	al, ' '
nextEntry:
		cmp	ah, es:[di]
		je	foundIt
nextChar:
		scasb
		je	nextEntry
		tst	{byte}es:[di]		; bail out if we don't find 
						; the drive letter before 
						; reaching the end of the string
		jz	freeAndLeave
		jmp	nextChar
foundIt:
	;
	; current volume name is at es:di - copy it to
	; PCFSI_currentVolume
	;
		push	si
		mov	si, ds:[si]
		add	si, ds:[si].Gen_offset
		add	si, PCFSI_currentVolume
		segxchg	ds, es
		xchg	si, di
		mov	ah, ']'

copyChar:
		lodsb
		stosb
		cmp	al, ah		; looking for a terminating ']'
		jne	copyChar
		clr	ax
		stosb
		

		call	MemUnlock

		segxchg	ds,es
		pop	si
cacheValid:
	;
	; count through the listed volumes til we either hit the end,
	; or find the entry we want
	;
	; cx	= number of drive to fetch
	; ds:si	= obj inst
	;
		mov	si, ds:[si]
		add	si, ds:[si].Gen_offset
		jcxz	getCurrent				
		mov	bx, ds:[si].PCFSI_driveListing
		call	MemLock
		mov	ds, ax
		clr	si

		mov	es, dx
		mov	di, bp

		dec	cx
		mov	ah, 1
		jcxz	foundVolume
VolumeLoop:
		lodsb
		tst	al
		jz	unlockDone
		cmp	al, ' '
		jne	VolumeLoop
		loop	VolumeLoop
foundVolume:
		clr	ax
volumeCopy:
		lodsb
		cmp	al, ' '
		je	foundEnd
		stosb
		tst	al
		jz	unlockDone
		jmp	volumeCopy
foundEnd:
		clr	al
		stosb
unlockDone:
		call	MemUnlock
done:
	.leave
	ret

	;
	; we want the current volume, which is stored separately
	;
getCurrent:
		add	si, PCFSI_currentVolume
		mov	es, dx
		mov	di, bp
copyCurrent:
		lodsb
		stosb
		tst	al
		jnz	copyCurrent
		clr	ax
		jmp	done


PCComFileSelectorFakeVolumeNameGet	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCFSGenFileSelectorFakeAssertHaveVolumeData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to check to see if we have volume data..  We
		don't want to get into a long loop looking for volume
		names if we can't get volume data for some reason
		(connection problems, etc)

CALLED BY:	MSG_GEN_FILE_SELECTOR_FAKE_ASSERT_HAVE_VOLUME_DATA
PASS:		*ds:si	= PCComFileSelectorClass object
		ds:di	= PCComFileSelectorClass instance data
		ds:bx	= PCComFileSelectorClass object (same as *ds:si)
		es 	= segment of PCComFileSelectorClass
		ax	= message #
RETURN:		ax	= 0 if have volume data
DESTROYED:
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCCFSGenFileSelectorFakeAssertHaveVolumeData	method dynamic PCComFileSelectorClass, 
					MSG_GEN_FILE_SELECTOR_FAKE_ASSERT_HAVE_VOLUME_DATA
	uses	cx, dx, bp
	.enter

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset

		mov	bx, ds:[di].PCFSI_driveListing
		tst	bx
		jnz	okDone

		sub	sp, FILE_LONGNAME_BUFFER_SIZE
		mov	bp, sp
		mov	dx, ss
		clr	cx
		mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_VOLUME_NAME_GET
		call	ObjCallInstanceNoLock
		add	sp, FILE_LONGNAME_BUFFER_SIZE

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		tst	ds:[di].PCFSI_driveListing
		jz	done			; no listing means we
						; couldn't possibly
						; have found it, and ax!=0
okDone:
		clr	ax
done:
	.leave
	ret

PCCFSGenFileSelectorFakeAssertHaveVolumeData	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileSelectorFakeDriveChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Really only fetching a drive letter and invalidating
		the stored volume names

CALLED BY:	MSG_GEN_FILE_SELECTOR_FAKE_DRIVE_CHANGE
PASS:		*ds:si	= PCComFileSelectorClass object
		ds:di	= PCComFileSelectorClass instance data
		ds:bx	= PCComFileSelectorClass object (same as *ds:si)
		es 	= segment of PCComFileSelectorClass
		ax	= message #
		cx	= drive #
		bp:dx	= fptr to dump to on stack (PATH_BUFFER_SIZE,
				though you shouldn't need all of that..)
RETURN:		ax	= 0 if all ok
DESTROYED:	nothing
SIDE EFFECTS:	


PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileSelectorFakeDriveChange	method dynamic PCComFileSelectorClass, 
					MSG_GEN_FILE_SELECTOR_FAKE_DRIVE_CHANGE
	uses	cx, dx, bp
	.enter
		clr	ch
		mov	bp, dx
		mov	dx, ss
		mov	ax, MSG_GEN_FILE_SELECTOR_FAKE_VOLUME_NAME_GET
		call	ObjCallInstanceNoLock
		tst	ax
		jnz	done

		mov	es, dx
		clr	{byte}es:[bp].2
;		mov	{word}es:[bp].2, '\\'

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		clr	bx
		xchg	bx, ds:[di].PCFSI_driveListing
		tst	bx
		jz	done
		call	MemFree
done:
	.leave
	ret
PCComFileSelectorFakeDriveChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileSelectorDummyIntercept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swallow some pesky notifications

CALLED BY:	MSG_META_REMOVING_DISK,
		MSG_NOTIFY_DRIVE_CHANGE
PASS:		*ds:si	= PCComFileSelectorClass object
		ds:di	= PCComFileSelectorClass instance data
		ds:bx	= PCComFileSelectorClass object (same as *ds:si)
		es 	= segment of PCComFileSelectorClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The PCComFileSelector object does not need to respond to these
	notifications since they relate to the GEOS file system.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileSelectorDummyIntercept	method dynamic PCComFileSelectorClass, 
					MSG_META_REMOVING_DISK,
					MSG_NOTIFY_DRIVE_CHANGE
	ret
PCComFileSelectorDummyIntercept	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCFSNotifyFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swallow file change notifications.

CALLED BY:	MSG_NOTIFY_FILE_CHANGE
PASS:		*ds:si	= PCComFileSelectorClass object
		ds:di	= PCComFileSelectorClass instance data
		ds:bx	= PCComFileSelectorClass object (same as *ds:si)
		es 	= segment of PCComFileSelectorClass
		ax	= message #
		bp	= FileChangeNotificationData block handle
 		dx	= FileChangeNotificationType
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The PCComFileSelector object does not need to respond to these
	notifications since they relate to the GEOS file system.

	We must pass MSG_NOTIFY_FILE_CHANGE onto the MetaClass handler so
	the data block reference count will be decremented and the data
	block eventually freed. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	1/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCCFSNotifyFileChange	method dynamic PCComFileSelectorClass, 
					MSG_NOTIFY_FILE_CHANGE
	.enter
	;
	; Pass the MSG_NOTIFY_FILE_CHANGE onto the MetaClass handler.
	;
		segmov	es, <segment MetaClass>, di
		mov	di, offset MetaClass
		call	ObjCallClassNoLock
	.leave
	ret
PCCFSNotifyFileChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCFSGenFileSelectorFakeFlushCaches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump our cached data in the file selector.

CALLED BY:	MSG_GEN_FILE_SELECTOR_FAKE_FLUSH_CACHES
PASS:		*ds:si	= PCComFileSelectorClass object
		ds:di	= PCComFileSelectorClass instance data
		ds:bx	= PCComFileSelectorClass object (same as *ds:si)
		es 	= segment of PCComFileSelectorClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	8/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileSelectorFakeFlushCaches	method dynamic PCComFileSelectorClass, 
					MSG_GEN_FILE_SELECTOR_FAKE_FLUSH_CACHES
	.enter
		call	DoTheZap
	.leave
	ret
PCComFileSelectorFakeFlushCaches	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoTheZap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Zap our cached data

CALLED BY:	PCCFSGenFileSelectorFakeFlushCaches, PCCFSReloc
PASS:		*ds:si	= PCComFileSelectorClass object
RETURN:		nothing
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoTheZap	proc	near
	class	PCComFileSelectorClass
	uses	bx
	.enter
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		clr	bx

	;
	; Zap the path cache
	;
		mov	{word}ds:[di].PCFSI_currentRemotePath, bx

	;
	; and free up the drivelist
	;
		xchg	bx, ds:[di].PCFSI_driveListing
		tst	bx
		jz	done
		call	MemFree
done:
	.leave
	ret
DoTheZap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCFSReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the Cache handle

PASS:		*ds:si	= object
		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE
		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper
RETURN:		carry - set if error
		bp - unchanged

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rjg	10/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCCFSReloc	method dynamic PCComFileSelectorClass, reloc
	.enter

		cmp	ax, MSG_META_UNRELOCATE
		jne	done				; not unrelocating

		call	DoTheZap
done:
	.leave
	mov	di, offset PCComFileSelectorClass
	call	ObjRelocOrUnRelocSuper
	ret
PCCFSReloc		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileSelectorHandlePathError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We tried to cd, but got an error.  Handle it

CALLED BY:	PCComFileSelectorFakePathSet
PASS:		*ds:si	= PCComFileSelectorClass object
		ax - PCComReturnType
RETURN:		carry set to retry
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	1/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileSelectorHandlePathError	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
		cmp	al, PCCRT_NOT_INITIALIZED
		je	done		; no retry
		clr	ax
		push	ax, ax		; don't care about SDOP_helpContext
		push	ax, ax		; don't care about SDOP_customTriggers
		push	ax, ax		; don't care about SDOP_stringArg2
		push	ax, ax		; don't care about SDOP_stringArg1
		mov	bx, handle Strings
		mov	dx, offset remotePathTroubleRetryQuestion
		push	bx, dx
		mov	ax, CustomDialogBoxFlags <1,
						CDT_QUESTION, GIT_AFFIRMATION,0>
		push	ax
		call	UserStandardDialogOptr

		cmp	ax, IC_NO	; retry?
		je	wipeOut
		stc
done:
	.leave
	ret
wipeOut:
	;
	; They accepted the error.  Clear out the FS so that if they
	; try anything funny they won't hurt themself.
	;
		call	DoTheZap	; nuke instance data
		mov	ax, MSG_GEN_FILE_SELECTOR_RESCAN
		call	ObjCallInstanceNoLock
		clc
		jmp	done
PCComFileSelectorHandlePathError	endp

PCComFileSelector	ends


