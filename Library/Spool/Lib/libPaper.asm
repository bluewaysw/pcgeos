COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Lib/Spool - PC/GEOS Spool Library
FILE:		libPaper.asm

AUTHOR:		Don Reeves, Jan 20, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB	SpoolGetNumPaperSizes	Get the number of defined paper sizes
    GLB	SpoolGetPaperString	Fill a buffer with the nth paper size string
    GLB	SpoolGetPaperSize	Return the dimensions of the nth paper size
    GLB	SpoolConvertPaperSize	Match a type, width & height with a defined size

    GLB SpoolGetPaperSizeOrder	Return the current order array
    GLB	SpoolSetPaperSizeOrder	Change the order paper sizes appear in lists
    GLB	SpoolCreatePaperSize	Create a new paper size
    GLB	SpoolDeletePaperSize	Delete a user-created paper size
    INT	DeletePaperSizeCallBack	Callback routine for deleting a paper size
	
    GLB	SpoolSetDefaultPageSizeInfo	Set the default page size information
    GLB SpoolGetDefaultPageSizeInfo	Get the default page size information

    INT	InitPaperResource	Initialize the PageSizeData resource
    INT	ConvertFromDefaultOrder	Convert a default order string to an order array
    INT	ConvertToDefaultOrder	Convert a default order array to an order string

    INT	CopyPaperSizeCategory	Copy the initial paper size category
    INT	GetPaperSizeInfo	Get information about a paper size
    INT	CopyPreDefinedString	- Copy a pre-defined string into a buffer
    INT	CopyUserDefinedString	- Copy a user-defined string into a buffer
    INT	GetPreDefinedSize	- Get dimensions of a pre-defined string
    INT	GetUserDefinedSize	- Get dimensions of a user-defined string
    INT	EnumPageSizeInfo	Enumerate through default PageSizeInfo
    INT	ReadPageSizeInfoValue	Read a single default PageSizeInfo value
    INT	WritePageSizeInfoValue	Write a single default PageSizeInfo value
    INT	InitFilePageSizeInfo	Read/Write default PageSizeInfo to/from initfile
    INT	AsciiToHexWord		Convert an ascii string to a word of hex
    INT	HexToThreeDigitAscii	Convert a hex byte to a 3-character ascii string
    INT	GetUserDefinedCount	Get count of user-defined paper sizes
    INT	GetUserDefinedNumber	Get paper number based on initfile number
    INT	LockStringsDS		Lock (& possibly update) the PageSizeData
    INT	UnlockStrings		Unlock the PageSizeData resource
    INT	InitFileAlterInteger	Alter (+/- value) an integer in the initfile
     EC	ECVerifyPageType	Verify the passed PageType

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/20/92		Initial revision

DESCRIPTION:
	Impelements the procedures that deal with paper size definitions
	for PC/GEOS	

	$Id: libPaper.asm,v 1.1 97/04/07 11:11:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolPaper segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AsciiToHexWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a three character ASCII string to a hexadecimal value. 

CALLED BY:	ConvertFromDefaultOrder

PASS:		DS:SI	= Character string
		CX	= # of digits to convert, or -1 for null-terminated

RETURN:		DS:SI	= Points past source
		AX	= Hexadecimal value

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AsciiToHexWord	proc	near
		uses	dx
		.enter
	
		; Perform the conversion, please
		;
		clr	dx			; partial result = 0
convertLoop:
		LocalGetChar ax, dssi
		LocalIsNull	ax		; NULL-terminator ??
		jz	done			; yes, so we're done
		sub	al, '0'			; convert to hex
SBCS <		clr	ah						>
		shl	dx, 1
		add	ax, dx
		shl	dx, 1
		shl	dx, 1
		add	dx, ax			; 10 * result + new => DX
		loop	convertLoop		
done:
		mov_tr	ax, dx			; result => AX

		.leave
		ret
AsciiToHexWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockStringsDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the PageSizeData resource

CALLED BY:	INTERNAL

PASS:		Nothing

RETURN:		DS	= PageSizeData segment
		BX	= PageSizeData handle

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockStringsDS	proc	near
		uses	ax, es
		.enter
	;
	; grab semaphore so someone else doesn't try to access our
	; PageSizeData while we're building it out
	;
		mov	bx, segment dgroup
		mov	es, bx
		PSem	es, pageSizeDataSem, TRASH_AX_BX
	;
	; If this is the first time through, must duplicate PageSizeData
	;
		mov	bx, es:[pageSizeDataHandle]
		tst	bx
		jz	duplicateIt
	;
	; lock our PageSizeData, but it may be discarded
	;
		call	MemLock
		jnc	haveMem			; not duplicated
	;
	; our PageSizeData was discarded, free current handle and duplicate
	; PageSizeData template
	;
		call	MemFree
duplicateIt:
		mov	bx, handle PageSizeData
		call	GeodeDuplicateResource	; bx = duplicate
		mov	ax, handle 0		; owned by spool, please
		call	HandleModifyOwner
		mov	es:[pageSizeDataHandle], bx
		call	MemLock			; ax = pageSizeDataHandle seg
		call	InitPaperResource	; ds = pageSizeDataHandle seg
						;	(updated)
		mov	ax, mask HF_DISCARDABLE
		call	MemModifyFlags		; after init, mark discardable
		mov	ax, ds			; ax = pageSizeDataHandle seg
haveMem:
		mov	ds, ax
		VSem	es, pageSizeDataSem, TRASH_AX

		.leave
		ret
LockStringsDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the PageSizeData resource

CALLED BY:	INTERNAL

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnlockStrings	proc	near
		uses	ds
		.enter
	
		mov	bx, segment dgroup
		mov	ds, bx
		mov	bx, ds:[pageSizeDataHandle]
		call	MemUnlock

		.leave
		ret
UnlockStrings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePageSizeInfoValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a value into the .INI file & the strings resource

CALLED BY:	EnumPageSizeInfo

PASS:		DS	= PageSizeData segment
		ES:DI	= Source word
		CS:BP	= PageSizeInfoEntry

RETURN:		DI	= DI + 2

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WritePageSizeInfoValue	proc	near
		.enter
	
		; Read the value from the chunk, converting from ASCII
		;
		mov	bx, -1			; perform a write
		mov	ax, es:[di]		; data => AX
		call	InitFilePageSizeInfo
		add	di, 2			; go to the next word

		; Skip the high word for PSR_width & PSR_height
		;
		cmp	bp, offset pageLayoutInfoTable
		jae	exit
		add	di, 2			; skip the high word
exit:
		.leave
		ret
WritePageSizeInfoValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadPageSizeInfoValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a value from the strings resource into the destination

CALLED BY:	EnumPageSizeInfo

PASS:		DS	= PageSizeData segment
		ES:DI	= Destination word
		CS:BP	= PageSizeInfoEntry

RETURN:		DI	= DI + 2

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We don't buffer the information in our own segment, so
		we go to the .INI file for every read.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadPageSizeInfoValue	proc	near
		uses	cx, si
		.enter
	
		; Read the value from the chunk, converting from ASCII
		;
		clr	bx			; perform a read
		call	InitFilePageSizeInfo	; read data from initfile
		jnc	done
		mov	si, cs:[bp].PSIE_chunkHandle
		mov	si, ds:[si]		; ascii string => DS:SI
		mov	cx, -1			; convert entire string
		call	AsciiToHexWord
done:
		stosw				; store the value away

		; Write zero for the high word of PSR_width & PSR_height
		;
		cmp	bp, offset pageLayoutInfoTable
		jae	exit
		clr	ax
		stosw
exit:
		.leave
		ret
ReadPageSizeInfoValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSetDefaultPageSizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default page information

CALLED BY:	GLOBAL

PASS:		DS:SI	= PageSizeReport structure

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSetDefaultPageSizeInfo	proc	far

if FULL_EXECUTE_IN_PLACE
EC<		push	bx					>
EC<		mov	bx, ds					>
EC<		call	ECAssertValidFarPointerXIP		>
EC<		pop	bx					>
endif

		push	di
		mov	di, offset WritePageSizeInfoValue
		call	EnumPageSizeInfo
		pop	di
		ret
SpoolSetDefaultPageSizeInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetDefaultPageSizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the default page information

CALLED BY:	GLOBAL

PASS:		DS:SI	= PageSizeReport buffer

RETURN:		DS:SI	= PageSizeReport filled

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolGetDefaultPageSizeInfo	proc	far
		push	di
		mov	di, offset ReadPageSizeInfoValue
		call	EnumPageSizeInfo
		pop	di
		ret
SpoolGetDefaultPageSizeInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFilePageSizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a value from the initfile, and store in a chunk

CALLED BY:	Read/WritePageSizeInfoValue

PASS:		CS:BP	= PageSizeInfoEntry
		BX	= 0 (read) or -1 (write)
		AX	= Data (for write)

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (error)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFilePageSizeInfo	proc	near
		uses	cx, dx, bp, si, ds
		.enter
	
		; Attempt to read in the string
		;
.assert (segment spoolCategoryString eq @CurSeg)

		segmov	ds, cs, cx
		mov	si, offset spoolCategoryString
		mov	dx, cs:[bp].PSIE_initFileKey
		tst	bx
		jnz	write
		call	InitFileReadInteger
done:
		.leave
		ret

		; Write out to the .INI file
write:
		mov_tr	bp, ax
		call	InitFileWriteInteger
		jmp	done
InitFilePageSizeInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumPageSizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the PageSizeInfo structure, either reading it in
		& storing its values in chunks, or writing to the structure
		the default values.

CALLED BY:	SpoolSet/GetDefaultPageSizeInfo

PASS:		DS:SI	= Data (passed to callback in ES:DI)
		DI	= Function to call for read/write
			function MUST be in the SpoolPaper resource

				Pass:	ES:DI	= Passed DS:SI
					DS	= PageSizeData resource
				May Destroy: AX, BX

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.assert (segment paperWidthKeyString eq @CurSeg)
.assert (segment paperHeightKeyString eq @CurSeg)
.assert (segment paperLayoutKeyString eq @CurSeg)
.assert (segment defaultMarginLeftKey eq @CurSeg)
.assert (segment defaultMarginTopKey eq @CurSeg)
.assert (segment defaultMarginRightKey eq @CurSeg)
.assert (segment defaultMarginBottomKey eq @CurSeg)

pageSizeInfoTable	PageSizeInfoEntry \
			<paperWidthKeyString, defaultWidthChunk>,
			<paperHeightKeyString, defaultHeightChunk>

pageLayoutInfoTable	PageSizeInfoEntry \
			<paperLayoutKeyString, defaultLayoutChunk>,
			<defaultMarginLeftKey, defaultMarginLeftChunk>,
			<defaultMarginTopKey, defaultMarginTopChunk>,
			<defaultMarginRightKey, defaultMarginRightChunk>,
			<defaultMarginBottomKey,defaultMarginBottomChunk>


EnumPageSizeInfo	proc	near
		uses	ax, bx, cx, bp, si, ds, es
		.enter
	
		; Some set-up work
		;
		segmov	es, ds
		xchg	di, si
		call	LockStringsDS
		
		; Now loop through all of the entries in the PageSizeInfo
		;
		mov	cx, 7			; seven word in PageSizeInfo
		mov	bp, offset pageSizeInfoTable
nextEntry:
		call	si			; perform the conversion
		add	bp, size PageSizeInfoEntry
		loop	nextEntry
		
		; Clean up
		;
		call	UnlockStrings

		.leave
		ret
EnumPageSizeInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Initfile Key Names
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; There are three possible type of cateogries, one each for the different
; type of pages that are present.
;
paperCategoryString	char	"paper", 0	; .INI file category
envelopeCategoryString	char	"envelope", 0	; .INI file category
labelCategoryString	char	"label", 0	; .INI file category
postcardCategoryString	char	"postcard", 0	; .INI file category

; Under each, the following keys are recognized
;
sizesKeyString		char	"newSizes", 0	; key for "blob" of new sizes
countKeyString		char	"count", 0	; key for number of new sizes
orderKeyString		char	"order", 0	; key for order array

; There are three type of of user-defined paper categories, one each for
; the different types of pages that are present. These are all the same
; length for the programmer's convenience.
;
paperSizeCatString	char	"paper128",0	; base name for paper size
envelopeSizeCatString	char	"envel128",0	; base name for envelope size
labelSizeCatString	char	"label128",0	; base name for label size
postcardCatString	char	"postc128",0	; base name for postcard

PAPER_SIZE_CATEGORY_LENGTH	= 9		; includes NULL-termination
PAPER_SIZE_CATEGORY_BUFFER	= 10		; make it even, please
PAPER_SIZE_NUMERIC_FIRST	= 5		; first digit of unique ident
PAPER_SIZE_NUMERIC_LAST		= 7		; last digit of unique ident
PAPER_SIZE_NUMERIC_DIGITS	= 3		; three numeric digits

; Under each, the following keys are recognized
;
paperNameKeyString	char	"name", 0	; key for name of paper size
paperWidthKeyString	char	"width", 0	; key for integer width of size
paperHeightKeyString	char	"height", 0	; key for integer height of size
paperLayoutKeyString	char	"layout", 0	; key for integer layout of size

; Default page size keys
;
spoolCategoryString	char	"spool", 0	; category name for spooler
defaultWidthKey		equ	paperWidthKeyString
defaultHeightKey	equ	paperHeightKeyString
defaultLayoutKey	equ	paperLayoutKeyString
defaultMarginLeftKey	char	"marginLeft", 0
defaultMarginTopKey	char	"marginTop", 0
defaultMarginRightKey	char	"marginRight", 0
defaultMarginBottomKey	char	"marginBottom", 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Global routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetNumPaperSizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of page sizes that are defined

CALLED BY:	GLOBAL

PASS:		BP	= PageType

RETURN:		CX	= Number of paper sizes
		DX	= Default paper size
		
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolGetNumPaperSizes	proc	far
		uses	ax, bx, bp, ds
		.enter
	
		; Get the number of page sizes
		;
EC <		call	ECVerifyPageType				>
		call	LockStringsDS
		mov	bp, ds:[PSDLMBH_paperOrder][bp]
		ChunkSizeHandle	ds, bp, cx	; number of entries => CX
		clr	dx			; default size, for now
		call	UnlockStrings

		.leave
		ret
SpoolGetNumPaperSizes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPaperString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a buffer with the requested paper size string

CALLED BY:	GLOBAL

PASS:		AX	= Paper size #
		BP	= PageType
		ES:DI	= Buffer for string (of size MAX_PAPER_STRING_LENGTH)

RETURN:		CX	= Actual string length

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolGetPaperString	proc	far
		uses	ax, dx
		.enter
	
		; Go get the string
		;
EC <		call	ECVerifyPageType				>
		mov	cx, offset CopyPreDefinedString
		mov	dx, offset CopyUserDefinedString
		call	GetPaperSizeInfo	; fill buffer in ES:DI
						; string size => CX
		.leave
		ret
SpoolGetPaperString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPaperSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dimensions of the requested paper size

CALLED BY:	GLOBAL

PASS:		AX	= Paper size # (not a PaperSizes enumeration)
		BP	= PageType

RETURN:		CX	= Width of paper  (in points)
		DX	= Length of paper (in points)
		AX	= Default PageLayout

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolGetPaperSize	proc	far
		.enter
	
		; Go get the size
		;
EC <		call	ECVerifyPageType				>
		mov	cx, offset GetPreDefinedSize
		mov	dx, offset GetUserDefinedSize
		call	GetPaperSizeInfo	; dimensions => CX, DX
						; layout => AX
		.leave
		ret
SpoolGetPaperSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolConvertPaperSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a width & height back to a paper size #

CALLED BY:	GLOBAL

PASS:		CX	= Width
		DX	= Height
		BP	= PageType

RETURN:		AX	= Paper size # (not a PaperSizes enum)
			- or -
		AX	= -1 if no match

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		There are four possible matches, listed by desirability:
			1) Match
			2) Inverted match
			3) Custom string
			4) Nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolConvertPaperSize	proc	far
		uses	bx, cx, dx, di, si, ds
		.enter
	
		; Some set-up work first
		;
EC <		call	ECVerifyPageType				>
		call	LockStringsDS
		mov	si, ds:[PSDLMBH_paperOrder][bp]
		mov	si, ds:[si]		; order array => DS:SI
		mov	bx, cx
		mov	di, dx			; dimensions => BX, DI
		ChunkSizePtr	ds, si, cx	; # of entries => CX
		push	cx			; save # of entries
		mov	ax, -1			; initialize offsets

		; Loop until the size is found
		;	DS:SI	= order array entry
		;	CX	= # of entries left
		; 	BX	= desired width
		;	DI	= desired height
		;	AL	= inverse size offset (-1 = not found)
		;	AH	= custom-entry offset (-1 = not found)
sizeLoop:
		push	cx, ax			; save the current count
		lodsb				; paper byte => AL
		tst	al			; custom size
		jz	custom			; yes, so store it away
		test	al, USER_DEFINED_MASK	; user defined ??
		jnz	getUserSize
		call	GetPreDefinedSize	; size => CX, DX
compareSizes:		
		cmp	cx, bx			; compare widths
		je	checkHeightHeight	; if equal, checks heights
		cmp	cx, di			; compare width vs height
		je	checkHeightWidth
next:
		pop	cx, ax
		je	done			; sizes match, so we're done
loopNow:
		loop	sizeLoop		; else try again
		mov	cx, ax
		cmp	cl, -1			; found inverse ??
		jne	done2			; yes!
		mov	cl, ch
		cmp	cl, -1			; found custom ??
		jne	done2			; yes!
		pop	si			; else clean up stack, and
		jmp	exit			; return AX = -1 = not found

		; Clean up, and return the value
done2:
		clr	ch			; ensure the high byte is 0
done:
		pop	ax			; # of entries => CX
		sub	ax, cx			; subtract # of entries left,
						; so paper size # => AX
exit:
		call	UnlockStrings

		.leave
		ret

		; Get user-defined page size dimensions
getUserSize:
		call	GetUserDefinedSize
		jmp	compareSizes

		; Remember where the custom page size occurred
custom:
		pop	cx, ax
		mov	ah, cl			; offset to custom => AH
		jmp	loopNow
		
		; Compare current height against desired height
checkHeightHeight:
		cmp	dx, di
		jmp	next			; if equal, we're done

		; Compare current height against desired width
checkHeightWidth:
		cmp	dx, bx
		jne	next
		pop	cx, ax
		mov	al, cl			; offset to inverse => AL
		jmp	loopNow
SpoolConvertPaperSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPaperSizeOrder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current paper size order array

CALLED BY:	GLOBAL

PASS:		BP	= PageType
		ES:DI	= Current order buffer (size MAX_PAPER_SIZES)
		DS:SI	= User-defined sizes (size MAX_PAPER_SIZES)

RETURN:		ES:DI	= Buffer filled with paper size array
		DS:SI	= Buffer filled with user-defined size array
		DX	= Number of unused sizes
		CX	= Number of ordered sizes

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		1) Copy the current order array
		2) Mark all pre-defined sizes as not-in-use
		3) Mark all user-defined sizes as not-in-use
		4) Mark all used sizes as in-use

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		In the order buffer:
			Each is a byte, signifying:
				0-127:	 a pre-defined paper size
				128-255: a user-defined paper size
		
		In the unused buffer:
			Each element is a byte, signifying
				0:	in-use (displayed to user)
				1:	unused (not displayed to user)

		Obviously, if a size is being displayed to the user,
		then it will be found in the order array. The two
		returned arrays should be sufficient for any application
		to allow manipulation of paper sizes.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

numPaperSizes	word	PaperSizes, EnvelopeSizes, LabelSizes

SpoolGetPaperSizeOrder	proc	far
		uses	ax, bx, di, si, ds, es
		.enter
	
		; Some set-up work
		;
EC <		call	ECVerifyPageType				>
		push	es, di
		push	si, si, ds, si
		call	LockStringsDS

		; 1) Copy the current order array
		;
		mov	si, ds:[PSDLMBH_paperOrder][bp]
		mov	si, ds:[si]		; derference the chunk handle
		ChunkSizePtr	ds, si, cx
		mov	dx, cx
		rep	movsb

		; 2) Mark all the pre-defined sizes as not-in-use
		;
		pop	es, di			; unused array => ES:DI
		mov	cx, MAX_PAPER_SIZES / 2
		clr	ax
		rep	stosw			; zero-init the unused array
		pop	di			; start of array => ES:DI
		mov	cx, cs:[numPaperSizes][bp]
		clr	ch
		mov	al, 1
		rep	stosb

		; 3) Mark all the user-defined sizes as not-in-use
		;
		call	GetUserDefinedCount	; # of user-defined sizes => AX
		mov	cx, ax			; count => CX
		pop	di			; start of array => ES:DI
		jcxz	step4
		clr	ax
findUserDefined:
		mov	bx, ax
		call	GetUserDefinedNumber	; paper size number => AL
		clr	ah			; clear high byte
		xchg	ax, bx
		mov	{byte} es:[di][bx], 1
		inc	ax			; go to next string section
		loop	findUserDefined

		; 4) Mark all used sizes as in-use
step4:
		mov	cx, dx			; members of order array =>  CX
		pop	ds, si			; order array => DS:SI
		clr	bh
findInUse:
		lodsb
		mov	bl, al
		mov	{byte} es:[di][bx], bh	; mark as in-use
		loop	findInUse			

		; Finally, clean up
		;
		call	UnlockStrings
		mov	cx, dx
		sub	dx, cs:[numPaperSizes][bp]
		call	GetUserDefinedCount
		sub	dx, ax
		neg	dx			; number unused sizes => DX

		.leave
		ret
SpoolGetPaperSizeOrder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSetPaperSizeOrder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a new paper size order to be displayed.

CALLED BY:	GLOBAL

PASS:		DS:SI	= Array of paper sizes
		BP	= PageType
		CX	= Number of entries in array

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Each paper size array element is a byte, signifying:
			0-127:	 a pre-defined paper size
			128-255: a user-defined paper size

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSetPaperSizeOrder	proc	far
		.enter

if FULL_EXECUTE_IN_PLACE
EC<		push	bx					>
EC<		mov	bx, ds					>
EC<		call	ECAssertValidFarPointerXIP		>
EC<		pop	bx					>
endif
	
		; Write the string to the .INI file
		;
EC <		call	ECVerifyPageType				>
		call	ConvertToDefaultOrder	; convert & store in .INI file

		.leave
		ret
SpoolSetPaperSizeOrder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCreatePaperSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new paper size, storing it in the .INI file

CALLED BY:	GLOBAL

PASS:		ES:DI	= Paper size string
		BP	= PageType
		CX	= Width
		DX	= Height
		AX	= Default PageLayout

RETURN:		AX	= Paper size number (as defined in the .INI file)
		Carry	= Clear (operation successful)
				- or -
			= Set   (operation failed)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCreatePaperSize	proc	far
		uses	bx, cx, dx, di, si, bp, ds, es
		.enter
	
		; First find a new paper size category name
		;
EC <		call	ECVerifyPageType				>
		push	ax
		call	GetUserDefinedCount	; user-defined count => AX
		cmp	ax, MAX_USER_DEFINED_PAPER_SIZES+1
		cmc				; invert the carry
		pop	ax
		LONG jc	exit			; if too many, jump
		sub	sp, PAPER_SIZE_CATEGORY_BUFFER
		mov	si, sp
		call	CopyPaperSizeCategory	; category string => DS:SI
		push	bp, bp			; PageType(2)
		push	ax, dx, cx		; layout, height, width
		mov	dx, offset paperWidthKeyString
findUnusedCategory:
		mov	cx, cs
		call	InitFileReadInteger
		jc	found
		mov	cx, PAPER_SIZE_NUMERIC_DIGITS
		mov	bp, PAPER_SIZE_NUMERIC_LAST
nextNameLoop:
		inc	{char} ds:[si][bp]
		cmp	{char} ds:[si][bp], '9'
		jle	findUnusedCategory
		mov	{char} ds:[si][bp], '0'
		dec	bp			; back up one character position
		loop	nextNameLoop		; loop 'til no more digits

		; We found the category. Store the information away
found:
		pop	bp			; paper width => BP
		call	InitFileWriteInteger
		pop	bp			; paper length => BP
		mov	dx, offset paperHeightKeyString
		call	InitFileWriteInteger
		pop	bp			; default layout => BP
		mov	dx, offset paperLayoutKeyString
		call	InitFileWriteInteger
		mov	dx, offset paperNameKeyString
		call	InitFileWriteString
if not DBCS_PCGEOS
		segmov	es, ds
		mov	di, si			; category name => ES:DI
endif

		; First append name to the blob
		;
		pop	bp			; PageType => BP
if DBCS_PCGEOS
		;
		; convert SBCS category name to DBCS string section
		;
		sub	sp, PAPER_SIZE_CATEGORY_LENGTH*(size wchar)
		mov	di, sp
		segmov	es, ss
		push	di
		LocalCopySBCSToDBCS
		pop	di
endif
		mov	ds, cx
		mov	si, cs:[pageTypeCategories][bp]
		mov	dx, offset sizesKeyString
		call	InitFileWriteStringSection
if DBCS_PCGEOS
		add	sp, PAPER_SIZE_CATEGORY_LENGTH*(size wchar)
endif

		; Now increment the paper size count
		;
		mov	dx, offset countKeyString
		mov	bp, 1			; increment count by one
		call	InitFileAlterInteger	; adjust count
		pop	bp			; PageType => BP
		jc	done			; if error, we're done		
		call	GetUserDefinedNumber	; number => AL
done:
		lahf
		add	sp, PAPER_SIZE_CATEGORY_BUFFER
		sahf
		mov	ah, 0			; clear AH
exit:
		.leave
		ret
SpoolCreatePaperSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolDeletePaperSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a paper size string.

CALLED BY:	GLOBAL

PASS:		BP	= PageType
		AX	= Paper size #

RETURN:		Carry	= Clear (successful deletion)
			= Set   (if error)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolDeletePaperSize	proc	far
		uses	ax, bx, cx, dx, di, si, bp, ds, es
		.enter
	
		; Enumerate through the sizes, finding the one we want to nuke
		;
EC <		call	ECVerifyPageType				>
EC <		cmp	ah, 0xff					>
EC <		ERROR_NE SPOOL_MUST_PASS_ACTUAL_PAPER_SIZE_NUMBER	>
		mov	bx, ax			; paper size number => BX
		segmov	ds, cs, cx
		mov	si, cs:[pageTypeCategories][bp]
		mov	dx, offset sizesKeyString
		clr	bp			; InitFileReadFlags => BP
		mov	di, cx
		mov	ax, offset DeletePaperSizeCallBack
		call	InitFileEnumStringSection
		tst	bh			; did we find the paper size ??
		stc				; assume the worst
		jne	done			; if not found, done
		
		; Now delete the size from the list of new sizes, and
		; decrement the size count.
		;
		mov	ax, bx
		call	InitFileDeleteStringSection		
		mov	dx, offset countKeyString
		mov	bp, -1			; decrement count
		call	InitFileAlterInteger
done:
		.leave
		ret
SpoolDeletePaperSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeletePaperSizeCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for InitFileEnumStringSection()

CALLED BY:	InitFileEnumStringSection() (via SpoolDeletePaperSize)

PASS:		DS:SI	= String section
		DX	= Section number
		BH	= 0xff
		BL	= Paper size #

RETURN:		Carry	= Clear to continue enumeration
				- or -
		Carry	= Set to end enumeration
		BX	= Section number

DESTROYED:	AX, CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeletePaperSizeCallBack	proc	far
		.enter
	
		; First, see what paper size # this is
		;
		push	si			; save start of section
		add	si, PAPER_SIZE_NUMERIC_FIRST*(size TCHAR)
		mov	cx, 3			; convert three digits
		call	AsciiToHexWord		; this paper size # => AL
		pop	si			; restore start of section
		cmp	al, bl			; paper sizes equal ??
		clc				; assume we'll continue
		jne	done			; not equal, so continue

		; We have a match! Delete the category
		;
if DBCS_PCGEOS
		;
		; convert DBCS string section to SBCS category
		;
		push	es, di, ds, si
		sub	sp, PAPER_SIZE_CATEGORY_BUFFER
		mov	di, sp
		segmov	es, ss
		mov	cx, PAPER_SIZE_CATEGORY_LENGTH-1
convLoop:
		lodsw
		stosb
		loop	convLoop
		clr	al
		stosb				; null terminate
		segmov	ds, ss			; ds:si = category
		mov	si, sp
		call	InitFileDeleteCategory
		add	sp, PAPER_SIZE_CATEGORY_BUFFER
		pop	es, di, ds, si
else
		clr	al			; we need a NULL terminator
		xchg	ds:[si+PAPER_SIZE_CATEGORY_LENGTH-1], al
		call	InitFileDeleteCategory	; nuke the paper size
		mov	ds:[si+PAPER_SIZE_CATEGORY_LENGTH-1], al
endif
		mov	bx, dx			; section # => BX
		stc				; end enumeration
done:
		.leave
		ret
DeletePaperSizeCallBack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** PageSizeData initialization routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPaperResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the paper size order structures

CALLED BY:	LockStringsDS

PASS:		AX	= PageSizeData segment

RETURN:		DS	= PageSizeData segment

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitPaperResource	proc	near
		uses	ax, bx, cx, dx, di, si, bp, es
		.enter
	
		; A little set-up work, here
		;
		mov	es, ax
		segmov	ds, cs

		; Initialize the three order strings
		;
		mov	si, offset paperCategoryString
		mov	di, offset DefaultPaperOrder
		mov	bp, offset PSDLMBH_paperOrder
		call	ConvertFromDefaultOrder

		mov	si, offset envelopeCategoryString
		mov	di, offset DefaultEnvelopeOrder
		mov	bp, offset PSDLMBH_envelopeOrder
		call	ConvertFromDefaultOrder

		mov	si, offset labelCategoryString
		mov	di, offset DefaultLabelOrder
		mov	bp, offset PSDLMBH_labelOrder
		call	ConvertFromDefaultOrder

		mov	si, offset postcardCategoryString
		mov	di, offset DefaultPostcardOrder
		mov	bp, offset PSDLMBH_postcardOrder
		call	ConvertFromDefaultOrder
		
		segmov	ds, es

		.leave
		ret
InitPaperResource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertFromDefaultOrder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a default order string (an array of DefaultOrderEntry's)
		from either the spool library itself or from the .INI file
		to an array of "size" bytes.
		
CALLED BY:	InitPaperResource()

PASS:		ES	= PageSizeData segment
		DS:SI	= Category name
		DI	= Offset to default order string
		BP	= Offset into PageSizeDataLMemBlockHeader

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAX_ORDER_ARRAY_SIZE	= 256

ConvertFromDefaultOrder	proc	near
		uses	ds
		.enter
	
		; Get the size of the default order array, either from
		; the .INI file, or from the default chunk in the spooler.
		;
		mov	cx, cs
		mov	dx, offset orderKeyString
		push	bp			; save order chunk offset
		clr	bp			; allocate a buffer
		call	InitFileReadString	; buffer => BX, size => CX
		pop	bp			; restore order chunk offset
		segmov	ds, es		
		jnc	allocate		; if no error, we're happy
		ChunkSizeHandle	es, di, cx	; size of default string => CX
		clr	bx			; no buffer to lock or free

		; Allocate an LMem chunk for  the order information
if DBCS_PCGEOS
		shr	cx, 1
EC <		ERROR_C	SPOOL_ILLEGAL_DEFAULT_ORDER_ARRAY		>
endif
allocate:
		shr	cx, 1			; divide by two
EC <		ERROR_C	SPOOL_ILLEGAL_DEFAULT_ORDER_ARRAY		>
		shr	cx, 1
EC <		ERROR_C	SPOOL_ILLEGAL_DEFAULT_ORDER_ARRAY		>
			CheckHack <(size DefaultOrderEntry) eq 4*(size TCHAR)>
		mov	al, mask OCF_IGNORE_DIRTY
		call	LMemAlloc		; handle => AX; fixup DS & ES
		mov	es:[bp], ax		; store the handle away
		mov	si, ax
		mov	si, es:[si]		; destination => ES:SI
		mov	di, es:[di]		; source => DS:DI
		xchg	di, si			; there, that's better...

		; Use either the initfile or original mem chunk as
		; the source for our copying
		;
		tst	bx			; any initfile buffer ?
		jz	createOrder		; nope, so use default order
		call	MemLock			; else lock buffer
		mov	ds, ax
		clr	si			; source => DS:SI

		; Copy/create the order chunk
createOrder:
		push	cx
		mov	cx, 3			; 3 digits long
		call	AsciiToHexWord		; hexadecimal value => AL
		inc	si			; step over separator
DBCS <		inc	si						>
		stosb				; store the value
		pop	cx
		loop	createOrder		; loop until done
		tst	bx			; free initfile buffer ??
		jz	done
		call	MemFree
done:
		.leave
		ret
ConvertFromDefaultOrder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToDefaultOrder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an order array to a default order string

CALLED BY:	DS:SI	= Order array
		BP	= PageType
		CX	= Number of entries in array

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

pageTypeCategories	nptr	paperCategoryString, \
				envelopeCategoryString, \
				labelCategoryString, \
				postcardCategoryString

CheckHack <(length pageTypeCategories)*2 eq PaperType>

ConvertToDefaultOrder	proc	near
		uses	ax, bx, cx, dx, di, si, bp, ds, es		
		.enter
	
		; First allocate a buffer to hold the default order string
		;
EC <		call	ECVerifyPageType				>
		push	cx			; save count
		mov_tr	ax, cx
		shl	ax, 1
		shl	ax, 1
DBCS <		shl	ax, 1						>
		inc	ax			; add byte for NULL terminator
DBCS <		inc	ax						>
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		mov	es, ax
		clr	di
		pop	cx			; restore count

		; Now create the order array
createDefOrder:
		lodsb				; get order value
if DBCS_PCGEOS
		call	HexToThreeDigitAsciiDBCS ; write the hex value
else
		call	HexToThreeDigitAscii	; write the hex value
endif
		LocalLoadChar	ax, PAPER_ORDER_SEPARATOR
		LocalPutChar	esdi, ax
		loop	createDefOrder
		LocalClrChar	ax
		LocalPutChar	esdi, ax	; write the NULL-terminator
	
		; Now write this into the .INI file
		;
		clr	di			; default order string => ES:DI
		segmov	ds, cs, cx
		mov	si, cs:[pageTypeCategories][bp]
		mov	dx, offset orderKeyString
		call	InitFileWriteString
		call	MemFree			; free default order buffer

		.leave
		ret
ConvertToDefaultOrder	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utility routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPaperSizeCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the initial paper size category string into the buffer

CALLED BY:	INTERNAL

PASS:		SS:SI	= Buffer (of size PAPER_SIZE_CATEGORY_BUFFER)
		BP	= PageType

RETURN:		DS:SI	= Initial category string

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

defaultPaperCategories	word	offset paperSizeCatString, \
				offset envelopeSizeCatString, \
				offset labelSizeCatString, \
				offset postcardCatString
CheckHack <(length defaultPaperCategories)*2 eq PaperType>

CopyPaperSizeCategory	proc	near
		uses	cx, dx, di, si, es
		.enter
	
		; Copy the string into the buffer
		;
EC <		call	ECVerifyPageType				>
		segmov	es, ss, dx
		mov	di, si			; buffer => ES:DI, SS => DX
		segmov	ds, cs
		mov	si, cs:[defaultPaperCategories][bp]
		mov	cx, PAPER_SIZE_CATEGORY_LENGTH
		rep	movsb
		mov	ds, dx

		.leave
		ret
CopyPaperSizeCategory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPaperSizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get specific information about a paper size

CALLED BY:	SpoolGetPaperString(), SpoolGetPaperSize()

PASS:		AX	= Paper size #
		CX	= Routine to call for pre-defined sizes
		DX	= Routine to call for user-defined sizes
		BP	= Paper
		ES, DI	= Data

RETURN:		AX, CX, DX
		Carry	= Clear (operation successful)
			= Set   (operation failed)

DESTROYED:	AX, CX, DX, if not returned

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetPaperSizeInfo	proc	near
		uses	bx, si, bp, ds
		.enter

		; See if this is a normal or user-created paper size
		;
EC <		call	ECVerifyPageType				>
		call	LockStringsDS
		cmp	ah, 0xff		; actual paper size ??
		je	haveNumber		; yes, so don't dereference
		mov	bx, ds:[PSDLMBH_paperOrder][bp]
		mov	bx, ds:[bx]		; order array => DS:BX
		xlatb				; paper, envelope, label => AL
haveNumber:
		test	al, USER_DEFINED_MASK	; user defined ??
		jnz	getInfo
		mov	dx, cx			; routine offset => DX
getInfo:
		call	dx			; call the proper procedure
		call	UnlockStrings

		.leave
		ret
GetPaperSizeInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPreDefinedString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a pre-defined string into the passed buffer

CALLED BY:	GetPaperSizeInfo()

PASS:		DS	= PageSizeData segment
		ES:DI	= Buffer to fill
		BP	= PageType
			  	PT_PAPER
					AL = PaperSizes
				PT_ENVELOPE
					AL = EnvelopeSizes
				PT_LABEL
					AL = LabelSizes

RETURN:		CX	= Size of string

DESTROYED:	AX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

firstPageString	nptr	\
	String_PS_CUSTOM,
	String_ES_CUSTOM,
	String_LSS_CUSTOM,
	String_PCS_CUSTOM
CheckHack <(length firstPageString)*2 eq PageType>

CopyPreDefinedString	proc	near
		uses	di
		.enter
	
		mov	si, cs:[firstPageString][bp]
		clr	ah
		shl	ax, 1			; want a word offset => AX
		add	si, ax			; string chunk => *DS:SI
		mov	si, ds:[si]		; string => DS:SI
		ChunkSizePtr	ds, si, cx	; string size => CX
DBCS <		shr	cx, 1						>
		mov	ax, cx
		dec	ax			; ignore NULL
SBCS <		rep	movsb			; copy the string => ES:DI >
DBCS <		rep	movsw			; copy the string => ES:DI >
		mov_tr	cx, ax			; string size => CX

		.leave
		ret
CopyPreDefinedString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyUserDefinedString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a user-defined string into the passed buffer

CALLED BY:	GetPaperSizeInfo()

PASS: 		ES:DI	= Buffer to fill (of size MAX_PAPER_STRING_LENGTH)
		BP	= PageType
		AL	= User-defined paper #

RETURN:		CX	= Size of string

DESTROYED:	AX, DX, BP, SI, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyUserDefinedString	proc	near
		.enter
	
		; We have a user-defined paper size
		;
		sub	sp, PAPER_SIZE_CATEGORY_BUFFER
		mov	si, sp
		call	CopyPaperSizeCategory	; real category name => DS:SI
		push	es, di			; save destination buffer
		segmov	es, ds
		mov	di, si
		add	di, PAPER_SIZE_NUMERIC_FIRST
		call	HexToThreeDigitAscii	; stuff in the ASCII value
		pop	es, di			; restore buffer => ES:DI
		mov	cx, cs
		mov	dx, offset paperNameKeyString
		mov	bp, MAX_PAPER_STRING_LENGTH
		call	InitFileReadString	; copy the string => ES:DI
		add	sp, PAPER_SIZE_CATEGORY_BUFFER

		.leave
		ret
CopyUserDefinedString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPreDefinedSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dimensions of a pre-defined paper size

CALLED BY:	GetPaperSizeInfo()

PASS:		AX	= Paper size # (not a PaperSizes enumeration)
		BP	= PageType
			  	PT_PAPER
					AL = PaperSizes
				PT_ENVELOPE
					AL = EnvelopeSizes
				PT_LABEL
					AL = LabelSizes

RETURN: 	CX	= Width  (in points)
		DX	= Length (in points)
		AX	= PageLayout (default)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

widthTables	nptr	\
	paperWidths,
	envelopeWidths,
	labelWidths,
	postcardWidths

heightTables	nptr	\
	paperHeights,
	envelopeHeights,
	labelHeights,
	postcardHeights

layoutTables	nptr	\
	paperLayouts,
	envelopeLayouts,
	labelLayouts,
	postcardLayouts

CheckHack <(length widthTables) eq (length heightTables)>
CheckHack <(length widthTables) eq (length layoutTables)>
CheckHack <(length widthTables)*2 eq (PageType)>

GetPreDefinedSize	proc	near
		uses	bx, si
		.enter
	
		clr	ah
		shl	ax, 1			; want a word offset => AX
		mov_tr	bx, ax
		mov	si, cs:[widthTables][bp]
		mov	cx, cs:[si][bx]		; width => CX
		mov	si, cs:[heightTables][bp]
		mov	dx, cs:[si][bx]		; height => DX
		mov	si, cs:[layoutTables][bp]
		mov	ax, cs:[si][bx]		; layout => AX

		.leave
		ret
GetPreDefinedSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetUserDefinedSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dimensions of a user-defined paper size

CALLED BY:	GetPaperSizeInfo()

PASS:		BP	= PageType
			  	PT_PAPER
					AL = PaperSizes
				PT_ENVELOPE
					AL = EnvelopeSizes
				PT_LABEL
					AL = LabelSizes
				PT_POSTCARD
					AL = PostcardSizes

RETURN:		CX	= Width  (in points)
		DX	= Length (in points)
		AX	= PageLayout (default)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		If not found, returns U.S. Letter, portrait

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetUserDefinedSize	proc	near
		uses	di, si, ds, es
		.enter
	
		; Get the length & width of a user-defined paper size
		;
		sub	sp, PAPER_SIZE_CATEGORY_BUFFER
		mov	si, sp
		call	CopyPaperSizeCategory	; real category name => DS:SI
		segmov	es, ds
		mov	di, si
		add	di, PAPER_SIZE_NUMERIC_FIRST
		call	HexToThreeDigitAscii	; stuff in the ASCII value

		mov	ax, 612			; U.S. Letter width
		mov	cx, cs
		mov	dx, offset paperWidthKeyString
		call	InitFileReadInteger
		push	ax			; save the width

		mov	ax, 792			; U.S. Letter height
		mov	dx, offset paperHeightKeyString
		call	InitFileReadInteger
		push	ax			; save the height

		mov	ax, bp			; PageLayout => AX (PageType)
		mov	dx, offset paperLayoutKeyString
		call	InitFileReadInteger	; layout => AX

		; Return all of the values
		;
		pop	dx			; height => DX		
		pop	cx			; width => CX
		add	sp, PAPER_SIZE_CATEGORY_BUFFER

		.leave
		ret
GetUserDefinedSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HexToThreeDigitAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a hexadecimal digit to a three-digit ASCII number.

CALLED BY:	INTERNAL

PASS:		ES:DI	= Buffer
		AL	= Value

RETURN:		ES:DI	= Points past buffer

DESTROYED:	AH

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HexToThreeDigitAscii	proc	near
		uses	bx, bp
		.enter
	
		; Perform a straight conversion
		;
		mov	bl, 10
		mov	bp, PAPER_SIZE_NUMERIC_DIGITS 
anotherDigit:
		clr	ah			; value => AX
		div	bl			; divide by 10
		add	ah, '0'			; convert to ASCII character
		dec	bp			; decrement character offset
		mov	es:[di][bp], ah		; store digit
		jnz	anotherDigit		; loop until done
		add	di, 3			; advance over digits
		
		.leave
		ret
HexToThreeDigitAscii	endp

if DBCS_PCGEOS
HexToThreeDigitAsciiDBCS	proc	near
		uses	bx, bp
		.enter
	
		; Perform a straight conversion
		;
		mov	bl, 10
		mov	bp, PAPER_SIZE_NUMERIC_DIGITS*(size wchar)
anotherDigit:
		clr	ah			; value => AX
		div	bl			; divide by 10
		add	ah, '0'			; convert to ASCII character
		dec	bp			; decrement character offset
		mov	{byte} es:[di][bp], 0	; (high byte of wchar)
		dec	bp
		mov	es:[di][bp], ah		; store digit (lobyte of wchar)
		jnz	anotherDigit		; loop until done
		add	di, 6			; advance over digits
		
		.leave
		ret
HexToThreeDigitAsciiDBCS	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetUserDefinedCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of user-defined paper sizes for the
		passed PageType

CALLED BY:	INTERNAL

PASS:		BP	= PageType

RETURN:		AX	= Count

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetUserDefinedCount	proc	near
		uses	cx, dx, si, ds
		.enter
	
		; Get an integer from the .INI file
		;
EC <		call	ECVerifyPageType				>
		segmov	ds, cs, cx
		mov	si, cs:[pageTypeCategories][bp]
		mov	dx, offset countKeyString
		call	InitFileReadInteger
		jnc	done
		clr	ax
done:
		.leave
		ret
GetUserDefinedCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetUserDefinedNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the paper size number of the user-defined size,
		defined by its occurrence in the newSizes string section.
		
CALLED BY:	INTERNAL

PASS:		BP	= PageType
		AX	= String section # (0-based)

RETURN:		AL	= Number (128 -> 255)
		Carry	= Set if error

DESTROYED:	AH

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetUserDefinedNumber	proc	near
		uses	bx, cx, dx, di, si, bp, ds, es
		.enter
	
		; Get an integer from the .INI file
		;
EC <		call	ECVerifyPageType				>
		segmov	ds, cs, cx
		mov	si, cs:[pageTypeCategories][bp]
		mov	dx, offset sizesKeyString
		segmov	es, ss
		mov	bp, MAX_PAPER_STRING_LENGTH*(size TCHAR)
		sub	sp, bp
		mov	di, sp			; buffer => ES:DI
CheckHack <INITFILE_INTACT_CHARS eq 0>
;;;		ornf	bp, INITFILE_INTACT_CHARS
		call	InitFileReadStringSection
		jc	done			; if error, we're done
		segmov	ds, es
		mov	si, di			; string => DS:SI
		add	si, PAPER_SIZE_NUMERIC_FIRST*(size TCHAR)
		mov	cx, 3			; convert three digits
		call	AsciiToHexWord
		clc
done:
		lahf
		add	sp, MAX_PAPER_STRING_LENGTH*(size TCHAR)
		sahf

		.leave
		ret
GetUserDefinedNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileAlterInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter an integer initfile integer

CALLED BY:	INTERNAL

PASS:		DS:SI	= Category string
		CX:DX	= Key string
		BP	= Alter value

RETURN:		Nothing

DESTROYED:	AX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFileAlterInteger	proc	near
		.enter
	
		call	InitFileReadInteger	; integer value => AX
		jnc	alter
		clr	ax
alter:
		add	bp, ax			; new value => BP
EC <		ERROR_S	SPOOL_INITFILE_ALTER_INTEGER_OVERFLOW		>
		call	InitFileWriteInteger

		.leave
		ret
InitFileAlterInteger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyPageType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that a valid PageType is in BP

CALLED BY:	INTERNAL

PASS:		BP	= PageType

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK
ECVerifyPageType	proc	near
		cmp	bp, PageType		; valid type
		ERROR_AE SPOOL_ILLEGAL_PAGE_TYPE
		test	bp, 0x1			; must be even
		ERROR_NZ SPOOL_ILLEGAL_PAGE_TYPE
		ret
ECVerifyPageType	endp
endif

SpoolPaper ends

