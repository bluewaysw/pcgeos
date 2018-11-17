COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	CSV
MODULE:		Import		
FILE:		importFile.asm

AUTHOR:		Ted H. Kim, 3/25/92

ROUTINES:
	Name			Description
	----			-----------
	TransGetFormat		Determines if the file is of CSV format.
	TransImport		Import the file
	ImportTransferFile	Import a comma separated file
	CheckForEndOfFile	Checks to see if the next character is EOF
	GetCSField		Read in a field from the source file 
	ResizeFieldBlock	Make field data block a little bigger
	HandleQuoteString	Handle fields with quotes
	AddFieldToArray		Add the field to the huge array
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
		
	Contains all of file import routines.

	$Id: importFile.asm,v 1.1 97/04/07 11:42:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Import	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the file is of CSV format.	

CALLED BY:	GLOBAL
PASS:		si	- file handle (open for read)	
RETURN:		ax	- TransError (0 = no error)
		cx	- format number if valid format
			  or NO_IDEA_FORMAT if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Level 1: verify we jsut have ASCII data
		Level 2: verify # of commas (separator character)
		         on each line (TBD)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/24/92		Initial version
	Don	2/22/99		Actually implemented this (sigh)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransGetFormat	proc	far
		uses	bx, dx, di, si, ds, es
		.enter
	;
	; Allocate a buffer for accessing data file
	;
		mov	ax, READ_WRITE_BLOCK_SIZE
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	done
		mov	ds, ax
		clr	dx			; dx:dx <- buffer
		push	bx			; save buffer handle
	;
	; Read in the first READ_WRITE_BLOCK_SIZE bytes into the buffer
	;
		mov	bx, si			; bx <- file handle
		mov	cx, READ_WRITE_BLOCK_SIZE
		clr	ax			; allow errors
		call	FileRead
		jnc	readOK
		cmp	ax, ERROR_SHORT_READ_WRITE
		stc				; if anything but short read
		jne	freeBuffer		; ...we abort this process
readOK:
		jcxz	freeBuffer
	;
	; Scan for non-ASCII data, and if found, return error. Otherwise,
	; we appear to have found an ASCII file. We are a bit sneaky in
	; doing this, but basically we look for values between 0x00 & 0x20
	; that don't correspond to normal ASCII characters in that range
	; (C_TAB, C_LINEFEED, C_ENTER).
	;
		clr	si
PZ   <		push	cx						>
		clr	ah
charLoop:
	;
	; We don't want to use LocalGetChar, since under DBCS that
	; will give us two bytes.  We want to check a byte at a time
	; so we'll use lodsb.  Japanese encoding methods (JIS & SJIS)
	; will never have 0x00 - 0x20 as the lower byte of a double
	; byte char, so if these are encountered they are SB chars.
	;
		lodsb				;al/ax <- character
		LocalCmpChar ax, 20h
		jae	nextChar
		LocalCmpChar ax, C_TAB
		je	nextChar
		LocalCmpChar ax, C_LINEFEED
		je	nextChar
		LocalCmpChar ax, C_ENTER
		je	nextChar
if PZ_PCGEOS
	;
	; The JIS encoding method uses escape sequences for switching
	; from SB to DB mode (and vice-versa).  So this is also a
	; legal DOS text character.
	;
		LocalCmpChar ax, C_ESC
		je	nextChar
endif
	;
	; We also allow C_CTRL_Z, which is a valid end-of-file marker
	; in DOS. To make our coding effort simpler, we allow either
	; the last character or the READ_WRITE_BLOCK_SIZE'th charcter
	; to match C_CTRL_Z. This seems like a very safe simplification
	;
		cmp	cx, 1			; only perform this check
		stc
		jne	freeBuffer		; ...on the last character
		LocalCmpChar ax, C_CTRL_Z
		stc
		jne	freeBuffer
nextChar:
		loop	charLoop
		clc				; success!!!
if PZ_PCGEOS
	;
	; Now that we have a DOS file, let's see if we can detect
	; if it's JIS or SJIS.  We'll just pass this same buffer:
	; in most cases, that should be enough to determine the 
	; format.
	;
		clr	si			; start from beginning
		pop	cx			; number of chars in buffer
		shl	cx, 1			; cx = # of bytes
		call	DetectJapaneseCode	; bx = DosCodePage

		mov	cx, bx			; return code in cx
		jmp	dontPopCX		; we already popped # chars
endif
	;
	; Clean up. Carry status indicates success (clear) or failure (set)
	;
freeBuffer:
if PZ_PCGEOS
		pop	cx
		mov	cx, NO_IDEA_FORMAT	; failure
dontPopCX:
endif
		pop	bx
		pushf
		call	MemFree
		popf
PZ <		jmp	exit						>
done:
		mov	cx, NO_IDEA_FORMAT	; assume failure
		jc	exit
		clr	cx			; else return format #0
exit:
		clr	ax			; no error

		.leave
		ret
TransGetFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Library routine called by the Impex library.

CALLED BY:	Impex

PASS:           ds:si - ImportFrame

RETURN:         ax - TransError
		bx - handle of error msg if ax = TE_CUSTOM
			or clipboardFormat CIF_SPREADSHEET
		dx:cx - VM chain containing transfer format
		si - ManufacturerID
DESTROYED:	di, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransImport	proc	far
	TI_Local  local	ImpexStackFrame
	TI_SSMeta local	SSMetaStruc
	.enter

	; attach the source file for caching

	mov     bx, ds:[si].IF_sourceFile	; bx - handle of source file 
	call	InputCacheAttach		; create the input buffer
	mov	ax, TE_OUT_OF_MEMORY		; assume not enough memory
	jc	exit				; exit if memory alloc error
	mov	TI_Local.ISF_cacheBlock, bx	; save cache block handle 

	; save the map entry block handle

	mov	bx, ds:[si].IF_importOptions	; bx - map list block
	mov	TI_Local.ISF_mapBlock, bx	; save it

	; initialize the stack frame for file importing

	push	bp
	clr	ax				; ax:cx - source ID
	clr	cx
        mov     bx, ds:[si].IF_transferVMFile	; bx - handle of transfer file
	mov	dx, ss
	lea	bp, TI_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaInitForStorage		; set up SSMeta header block 	
	pop	bp

	; create a data block that will contain 
	; the biggest field size for a given column

	mov	ax, SIZE_FIELD_SIZE_BLOCK	; ax - # of bytes to allocate
	mov	TI_Local.ISF_sizeFieldSizeBlock, ax	; save size of block
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_NO_ERR) shl 8) or \
		    mask HF_SWAPABLE
	call	MemAlloc			; allocate a block
	mov	TI_Local.ISF_fieldSizeBlock, bx	; save the handle

	; create a list of column numbers that are not mapped

	;mov	bx, TI_Local.ISF_mapBlock
	;call	ImportCreateNotMappedColumnList
	;mov	TI_Local.ISF_notMappedList, bx	; save the handle

	; read in the source file and create meta file

	call	ImportTransferFile		; read in CSV file
	jc	error				; skip if error
	call	CreateFieldInfoBlock		; create field Info block

	; destroy the cached block
error:
	mov	bx, TI_Local.ISF_cacheBlock	; bx - cache block handle 
	call	InputCacheDestroy		; destroy the cache block

	; this carry is the result of "ImportTransferFile"

	jc	exit				; exit if there was an error

	; update SSMeta header block

	push	bp
	mov	ax, TI_Local.ISF_numRecords	; dx - number of records
	mov	cx, TI_Local.ISF_highestNumFields ; cx - number of fields
	mov	dx, ss
	lea	bp, TI_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaSetScrapSize
	pop	bp

	; return with VM chain and VM file handle

	mov     dx, TI_SSMeta.SSMDAS_hdrBlkVMHan	
	clr     cx				; dx:cx - VM chain
	mov     ax, TE_NO_ERROR                	; return with no error
	mov	bx, CIF_SPREADSHEET
	mov	si, MANUFACTURER_ID_GEOWORKS

	; clean up

	;mov     bx, TI_Local.ISF_notMappedList  ; handle of not-mapped block
	;tst     bx
	;je      exit				; exit if no map block
	;call	MemFree
exit:
	.leave
	ret
TransImport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportTransferFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Imports a data file that is in comma separated format.

CALLED BY:	FileImport

PASS:		ds - segment address of dgroup

RETURN:		carry set if error (ax = TransError)

DESTROYED:	ax, bx, cx, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportTransferFile	proc	near	uses	si, dx, bp
        ITF_Local	local	ImpexStackFrame
	ITF_SSMeta 	local	SSMetaStruc
	.enter	inherit near

	clr     ax
	mov	ITF_Local.ISF_numRecords, ax	; initialize number of records
	mov     ITF_SSMeta.SSMDAS_entryPos.high, ax
	mov     ITF_SSMeta.SSMDAS_entryPos.low, ax
	mov     ITF_Local.ISF_entryPos.high, ax
	mov     ITF_Local.ISF_entryPos.low, ax

	; allocate a block for storing field data

	mov	ax, FIELD_BLOCK_SIZE	; ax - size of block to allocate
	mov	ITF_Local.ISF_fieldBlockSize, ax ; save the size of field block
	mov     cx, (HAF_STANDARD_NO_ERR shl 8) or mask HF_SWAPABLE
	call	MemAlloc		; allocate a block
	mov	ITF_Local.ISF_fieldBlock, bx ; save the handle of this block 
	clr	ITF_Local.ISF_highestNumFields	; initialize number of fields
	jmp	skipCheck		; skip check for the 1st record
nextEntry:
	; save the entry position

	mov     ax, ITF_SSMeta.SSMDAS_entryPos.high
	mov     ITF_Local.ISF_entryPos.high, ax
	mov     ax, ITF_SSMeta.SSMDAS_entryPos.low
	mov     ITF_Local.ISF_entryPos.low, ax

	; all records must have identical number of fields

	mov	ax, ITF_Local.ISF_curNumFields
	cmp	ax, 1				; was there only one field? 
	jne	skipCheck				; if not, skip
SBCS <	cmp	ITF_Local.ISF_sizeFieldData, 1	; was it an empty field? >
DBCS <	cmp	ITF_Local.ISF_sizeFieldData, 2	; was it an empty field? >
	je	skipCheck			; skip if so
skipCheck:
	call	CheckForEndOfFile	; check to see if we are at EOF
	jc	fileErr			; skip if file error
	je	exit			; exit EOF
	clr	ITF_Local.ISF_curNumFields	; initialize number of fields
nextField:
	call	GetCSField		; get a field
	jc	error			; exit if error
	call	AddFieldToArray		; add this field to the huge array 

	inc	ITF_Local.ISF_curNumFields	; increment # of fields
	mov	ax, ITF_Local.ISF_curNumFields
	cmp	ax, ITF_Local.ISF_highestNumFields
	jle	notHighest
	inc	ITF_Local.ISF_highestNumFields	; increment # of fields
notHighest:
	cmp	ITF_Local.ISF_endOfLine, TRUE	; are we at end of a record?
	jne	nextField			; if not, get the next field
	inc	ITF_Local.ISF_numRecords	; increment # of records
	cmp	ITF_Local.ISF_endOfFile, TRUE	; are we at the end of file?
	jne	nextEntry			; if not, get the next record
exit:
	mov	bx, ITF_Local.ISF_fieldBlock	; bx - handle of field block 
	call	MemFree				; free this block
	clc					; exit with no error
	jmp	done
fileErr:
	mov	ax, TE_FILE_ERROR		; ax - TransError
	jmp	error
error:
	mov	bx, ITF_Local.ISF_fieldBlock	; bx - handle of field block 
	call	MemFree			; free this block
	stc				; set error flag
done:
	.leave
	ret
ImportTransferFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForEndOfFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look ahead to see if we are at the end of file.

CALLED BY:	ImportTransferFile

PASS:		nothing

RETURN:		zero flag set if EOF
		carry flag set if file error

DESTROYED:	es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForEndOfFile	proc	near	uses	ax
        CFEOF_Local	local	ImpexStackFrame
	CFEOF_SSMeta 	local	SSMetaStruc
	.enter	inherit near

	mov	bx, CFEOF_Local.ISF_cacheBlock	; bx - handle of cache block
        call	InputCacheGetChar       	; read in a char 
	jc	error				; exit if error

	LocalCmpChar	ax, EOF			; end of file character?
	je	quit				; if so, exit
	LocalCmpChar	ax, ENDFILE		; actual end of file char?
	je	quit				; if so, exit
        call	InputCacheUnGetChar		; unread this char 
	mov	ax, 1
	tst	ax				; clear zero flag
exit:
	clc					; no file error
	jmp	quit
error:
	LocalCmpChar	ax, EOF			; end of file character?
	je	exit				; if so, exit
	stc
quit:
	.leave
	ret
CheckForEndOfFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCSField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a field from a comma separated file 

CALLED BY:	ImportTransferFile

PASS:		nothing

RETURN:		carry set if error (ax = TransError) 

DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/18/91		Initial version
	mevissen 3/99		Import number fields as numbers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCSField	proc	near		
        GCSF_Local  	local	ImpexStackFrame
	GCSF_SSMeta	local	SSMetaStruc
	.enter	inherit near

	; initialize some variables

	mov	GCSF_Local.ISF_endOfFile, FALSE	; set end of file flag
	mov	GCSF_Local.ISF_endOfLine, FALSE	; set end of line flag

	mov	bx, GCSF_Local.ISF_fieldBlock ; bx - handle of field data block
	call	MemLock			; lock this block
	mov	es, ax
	clr	di			; es:di - destination block

	; initialize CellCommon 
	
	mov	al, 0
	mov	cx, size CellCommon	; cx - number of bytes to initialize
	rep	stosb			; clear the header
	clr	di			; restore the pointer
	
	mov	es:[di].CC_type, CT_TEXT; this is a text field 
	add	di, size CellCommon	; es:di - place to store the string
	clr	dx			; dx - # of quotation marks
	mov	bx, GCSF_Local.ISF_cacheBlock	; bx - handle of cache block
next:
	call	InputCacheGetChar	; read in a char from source file
	jc	checkEOF		; skip if carry set

	LocalIsNull	ax		; null character?
	je	error1			; exit with error flag	

	LocalCmpChar	ax, '"'		; quotation mark?
	je	handleQ			; if so, skip to handle

	LocalCmpChar	ax, ','			; comma?
	je	done			; if so, exit

	LocalCmpChar	ax, CR		; carriage return?
	je	handleCR		; if so, skip

	LocalCmpChar	ax, ENDFILE	; end Of File character?
	je	handleEOF		; if so, skip to handle it

	LocalCmpChar	ax, EOF		; End Of File character?
	je	handleEOF		; if so, skip to handle it

	LocalPutChar	esdi, ax	; copy the character into field block
	cmp	di, MAX_TEXT_FIELD_LENGTH	; field to big?
	je	error1				; if so, exit with error flag
	cmp	di, GCSF_Local.ISF_fieldBlockSize	; field block full?
	jne	next			; if not, read in the next character
	call	ResizeFieldBlock	; make the field block bigger
	jnc	next			; read in the next character
	mov	ax, TE_OUT_OF_MEMORY	; ax - TransError
	jmp	error2			; exit if error
handleQ:
	inc	dx			; increment quotation mark counter
	call	HandleQuoteString	; handle this special case
	jc	error2			; skip if error
	jmp	done			; and exit
handleCR:
	mov	GCSF_Local.ISF_endOfLine, TRUE	; set end of line flag
	call	InputCacheGetChar	; read in LF from source string
	jc	checkEOF		; exit if error

	; make sure it is a line feed character

	LocalCmpChar	ax, LF
	je	done
	call	InputCacheUnGetChar	; if not LF, then unget the character
	jmp	done
handleEOF:
	mov	GCSF_Local.ISF_endOfLine, TRUE	; set end of line flag
	mov	GCSF_Local.ISF_endOfFile, TRUE	; set end of file flag
done:
	LocalClrChar	ax
	LocalPutChar	esdi, ax	; null terminate the data block
	sub	di, size CellCommon	; es:di - place to store the string
	mov	GCSF_Local.ISF_sizeFieldData, di ; save the size of cell data 

	; Finished reading the field.  If it seems to be a number field,
	; set the appropriate field type.	mevissen, 3/99

	call	CheckForNumberField

	mov	bx, GCSF_Local.ISF_fieldBlock ; bx - handle of field data block
	call	MemUnlock
	clc				; return with no error	
	jmp	exit
checkEOF:
	LocalCmpChar	ax, EOF		; End Of File character?
	je	handleEOF		; if so, skip to handle it

	mov	ax, TE_FILE_ERROR	; ax - TransError
	jmp	error2
error1:
	mov	ax, TE_INVALID_FORMAT	; ax - TransError
error2:
	mov	bx, GCSF_Local.ISF_fieldBlock ; bx - handle of field data block
	call	MemUnlock
	stc				; error found
exit:
	.leave
	ret
GetCSField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForNumberField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether passed cell should be called a number, not text.
		Update flag and convert the ascii if so.


CALLED BY:	GetCSField
PASS:		es	= sptr to cell data
		bp	= inherited stack frame

RETURN:		nothing (cell data updated)
DESTROYED:	nothing

SIDE EFFECTS:	cell data updated if numerical data in text field.

PSEUDO CODE/STRATEGY:

	Jeez, this is hideous.

	But I couldn't find a canned routine to say "this looks like a
	number."  And FloatAsciiToFloat has a tendency to stop converting
	when it hits a bogus character, and return the value 0 (or whatever
	was read so far) with no errors.


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	mevissen	3/15/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForNumberField	proc	near

	.enter	inherit GetCSField



	; short-circuit test for blank field (only null terminator)

SBCS <	cmp	GCSF_Local.ISF_sizeFieldData, 1				>
DBCS <	cmp	GCSF_Local.ISF_sizeFieldData, 2				>
	jne	a10$

realDone:
	.leave
	ret

done:
	pop	ax, bx, cx, dx, si, di, ds
	jmp	realDone


a10$:
	push	ax, bx, cx, dx, si, di, ds

	segmov	ds, es				; ds:si = field start
	mov	si, size CellCommon

	call	LocalGetNumericFormat		; al - NumberFormatFlags
					; ah - decimal digits
					; bx - thousands separator  (i.e. ',')
					; cx - decimal separator    (i.e. '.')
					; dx - list separator	  (i.e. ';')

	; If there's a leading '$', we still might call this a number.
	; skip past it, then call that the start of the number string.

	; skip whitespace

	call	SkipWhitespace

	; skip leading $

	LocalGetChar	ax, dssi
	LocalCmpChar	ax, '$'
	je	numberStart

	LocalPrevChar	dssi			; not a '$'

numberStart:
	mov	di, si				; ds:di = number start
	clr	dx				; dh = 1 => have seen a digit
						; dl = 1 => have seen '.'
						;    = 2 => have seen 'E'
checkSign:
	; check for [+-]

	LocalGetChar	ax, dssi
	LocalCmpChar	ax, '+'
	je	checkDigits
	LocalCmpChar	ax, '-'
	je	checkDigits

	LocalPrevChar	dssi			; not a sign char
	jmp	checkDigits

	; allow only digits, whitespace, period, comma
	; require at least one digit

foundDigit:
	mov	dh, 1

checkDigits:
	call	SkipWhitespace

	LocalGetChar	ax, dssi
DBCS <	tst	ah				>
DBCS <	jnz	done				> ; not a number string
SBCS <	clr	ah				> ; for LocalIsDigit call

	LocalIsNull	ax
	je	isGood
	call	LocalIsDigit
	jnz	foundDigit			; valid digit

	cmp	dl, 1				; seen 'e' already?
	ja	done				; yes, this char invalid now

DBCS <	cmp	ax, bx				>
SBCS <	cmp	al, bl				>
	je	checkDigits			; valid thousands separator

	LocalCmpChar	ax, 'E'
	je	intoExponent
	LocalCmpChar	ax, 'e'
	je	intoExponent

	cmp	dl, 0				; seen decimal already?
	ja	done				; yes, this char invalid now

DBCS <	cmp	ax, cx				; decimal point >
SBCS <	cmp	al, cl				; decimal point >
	jne	done				; not a valid number-string char

	inc	dl				; dl = 1
	jmp	checkDigits

intoExponent:
	tst	dh
	jz	done				; invalid; no digit seen yet
	clr	dh				; force another digit to appear
	mov	dl, 2
	call	SkipWhitespace
	jmp	checkSign

isGood:
	; good number, assuming we've seen a digit

	tst	dh
	jz	done

	; convert the ascii string to float number

	mov	si, di				; ds:si - ptr to string
	mov	di, size CellCommon
	mov	cx, GCSF_Local.ISF_sizeFieldData ; cx - size of ascii string
	add	cx, si
	sub	cx, di				; subtract leading chars
	mov	al, mask FAF_STORE_NUMBER	; al - FloatAsciiToFloatFlags
	call	FloatAsciiToFloat		; es:di <- FloatNum

	jc	toDone				; conversion error

	; change the cell type to be a number

	mov	es:[CC_type], CT_CONSTANT
	mov	GCSF_Local.ISF_sizeFieldData, size FloatNum ; save size  

toDone:
	jmp	done

CheckForNumberField	endp

SkipWhitespace	proc	near

top:
	LocalGetChar	ax, dssi

	; LocalIsSpace can't deal with a non-zero high byte:

DBCS <	tst	ah							>
DBCS <	jnz	done							>
SBCS <	clr	ah							>

	call	LocalIsSpace
	jnz	top

done::
	LocalPrevChar	dssi
	ret

SkipWhitespace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeFieldBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the field data block 1K larger.

CALLED BY:	GetCSField, HandleQuoteString

PASS:		es:di - ptr to the end of current field block

RETURN:		es:di - ptr to field block that is made bigger
		carry set if not enough memory

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeFieldBlock	proc	near	uses 	ax, bx, cx, dx
        RFB_Local	local	ImpexStackFrame
	RFB_SSMeta	local	SSMetaStruc
	.enter	inherit near

	mov	bx, RFB_Local.ISF_fieldBlock	; bx - handle of field block
	mov	ax, RFB_Local.ISF_fieldBlockSize; ax - size of field block

	add	ax, FIELD_BLOCK_SIZE	; make the block 1K larger
	mov	RFB_Local.ISF_fieldBlockSize, ax; update the variable
	mov	ch, mask HAF_LOCK	; HeapAllocFlags
	call	MemReAlloc		; resize the field block
	mov	es, ax			; es:di - ptr into field block

	.leave
	ret
ResizeFieldBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleQuoteString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the field that has quotes.

CALLED BY:	GetCSField

PASS:		es:di - pointer into field data block  
		bx - handle of cache block
		dx - number of quote characters

RETURN:		bx - handle of cache block
		carry set if error (ax = TransError)

DESTROYED:	dx

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleQuoteString	proc	near
        HQS_Local	local	ImpexStackFrame
	HQS_SSMeta	local	SSMetaStruc
	.enter	inherit near

	; ignore the 1st and the last quote mark
nextChar:
	call	InputCacheGetChar	; read in a char from source string
	LONG 	jc	error		; exit if error
	LocalCmpChar	ax, ','		; comma?
	jne	checkEOF		; if not, check for EOF

        test    dx, 1                   ; odd number of quotation marks?
	jne	putChar			; if odd, part of field data	
	jmp	exit			; if even, field delimiter
checkEOF:
	LocalCmpChar	ax, EOF		; end of file character?
	jne	checkCR			; if not, skip
handleEOF:
	mov	HQS_Local.ISF_endOfFile, TRUE	; set end of file flag
	jmp	exit			; jump to exit
checkCR:
	;
	; If a carriage return occurs within a quoted string, it is
	; part of the field data. A line feed may or may not follow a
    	; carriage return in this position; if it's there, we filter
	; it out.
	;
	LocalCmpChar	ax, C_CR	; carriage return?
	jne	checkQuote		; if not, check for quote
	call	InputCacheGetChar	; read in LF from source string
	jc	error			; exit if error
	LocalCmpChar	ax, LF			
	je	putCR
	call	InputCacheUnGetChar	; if not LF, then unget the character
putCR:
	LocalLoadChar	ax, C_CR
	jmp	putChar
checkQuote:

	LocalCmpChar	ax, '"'		; quotation mark?
	jne	putChar			; if not, not an escape character

        inc     dx                      ; increment quotation mark counter

	; '"' may be used as an escape character for '"'
	; Check whether the next character is '"'

	call	InputCacheGetChar	; read in a char from source string
	jc	error			; exit if error
	LocalCmpChar	ax, '"'		; is the next char a quotation mark?
	je	incDX			; if so, '"' is part of field data 

	; if the next character is not '"', then it is probably
	; one of: EOF, ',', CR

	LocalCmpChar	ax, ','			; comma?
	je	exit			; if so, exit

	LocalCmpChar	ax, EOF		; end of file character?
	jne	checkCR2		; if not, skip

	mov	HQS_Local.ISF_endOfFile, TRUE	; set end of file flag
	jmp	exit			; jump to exit
checkCR2:
	LocalCmpChar	ax, CR	
	je	carriageReturn

	; if not, then this must be a variation on CSV format
	; where all the field data are started and ended with '"'

	call	InputCacheUnGetChar	; unget this character
	jc	error			; exit if error
	LocalLoadChar	ax, '"'		; write out '"'
	jmp	putChar
carriageReturn:
	mov	HQS_Local.ISF_endOfLine, TRUE	; set end of line flag
	call	InputCacheGetChar	; read in LF from source string
	jc	error			; exit if error
	jmp	exit
incDX:
        inc     dx                      ; increment quotation mark counter
putChar:
	LocalPutChar	esdi, ax	; copy the character into field block
	cmp	di, HQS_Local.ISF_fieldBlockSize	; field block full?
	LONG	jne	nextChar	; if not, get the next char
	call	ResizeFieldBlock	; make the field block bigger
	LONG	jnc	nextChar	; get the next char
	mov	ax, TE_OUT_OF_MEMORY	; ax - TransError
	stc				; return with carry set
	jmp	quit
error:
	LocalCmpChar	ax, EOF		; end of file character?
	je	handleEOF		; if so, skip

	mov	ax, TE_FILE_ERROR	; ax - TransError
	stc				; return with carry set
	jmp	quit
exit:
	clc				; return with no error
quit:
	.leave
	ret
HandleQuoteString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddFieldToArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new field to the huge array.

CALLED BY:	ImportTransferFile

PASS:		nothing 

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddFieldToArray		proc	near	uses	ds, bp
        AFTA_Local  	local	ImpexStackFrame
	AFTA_SSMeta 	local	SSMetaStruc
	.enter	inherit near

SBCS <	cmp	AFTA_Local.ISF_sizeFieldData, 1	; was it an empty field? >
DBCS <	cmp	AFTA_Local.ISF_sizeFieldData, 2	; was it an empty field? >
	je      exit                            ; exit if so

	mov	ax, AFTA_Local.ISF_curNumFields ; ax - column number
	mov	bx, AFTA_Local.ISF_mapBlock	; bx - handle of map block
        mov     cl, mask IF_IMPORT		; do import
	call	GetMappedRowAndColNumber	; returns ax = mapped col num
	jnc	exit				; exit if not mapped

	; stuff stack frame with the new coordinate and array type

        ;mov     bx, AFTA_Local.ISF_notMappedList
	;call	ImportGetActualColumnNumber
	mov	AFTA_SSMeta.SSMDAS_col, ax	; ax - final column number
	mov	cx, AFTA_Local.ISF_numRecords
	mov	AFTA_SSMeta.SSMDAS_row, cx	; cx - row number

	call	UpdateFieldSizeBlock		; update field size block

	mov	AFTA_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL
	mov	bx, AFTA_Local.ISF_fieldBlock	; bx - handle of field block
	call	MemLock
	segmov	ds, ax				; ds:si - ptr to data
	clr	si
	mov	cx, AFTA_Local.ISF_sizeFieldData; cx - size of cell data
	add	cx, size CellCommon		; adjust size of cell data

	mov	al, SSMETA_ADD_TO_END		; al - SSMetaAddEntryFlags
	tst	AFTA_Local.ISF_mapBlock		; does the map block exist?
	je	noMap				; skip if no map block

	; if map block exists, just add the entry to its correct position

	mov     ax, AFTA_Local.ISF_entryPos.high
	mov     AFTA_SSMeta.SSMDAS_entryPos.high, ax
	mov     ax, AFTA_Local.ISF_entryPos.low
	mov     AFTA_SSMeta.SSMDAS_entryPos.low, ax
	mov	al, SSMAEF_ENTRY_POS_PASSED	; al - SSMetaAddEntryFlags
noMap:
	push	bp
	mov	dx, ss
	lea	bp, AFTA_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayAddEntry		; add the new entry
	pop	bp
	mov	bx, AFTA_Local.ISF_fieldBlock	; bx - handle of field block
	call	MemUnlock			; free it!
exit:
	.leave
	ret
AddFieldToArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFieldSizeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the field size block chunk array.

CALLED BY:	(GLOBAL)

PASS:		ax - column number

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di 	

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	11/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateFieldSizeBlock		proc	far	uses	ds
	UFSB_Local	local	ImpexStackFrame
	UFSB_SSMeta 	local	SSMetaStruc
	.enter	inherit	near

	; check too see if we need to reallocate the field size block

	push	ax
	mov	dx, UFSB_Local.ISF_sizeFieldSizeBlock	; dx - current size
	shr	dx, 1			
	dec	dx		; dx - number of fields that can be handled 

	; is this column number too high?

	cmp	ax, dx
	jle	okay		; if not, no need to reallocate

	; reallocate the field size block

	sub	ax, dx
	shl	ax
	add	ax, UFSB_Local.ISF_sizeFieldSizeBlock	; ax - new block size
	mov	UFSB_Local.ISF_sizeFieldSizeBlock, ax	; update stack frame
	mov	ch, mask HAF_ZERO_INIT or mask HAF_NO_ERR ; HeapAllocFlags
	mov	bx, UFSB_Local.ISF_fieldSizeBlock	;bx - block handle
	call	MemReAlloc
okay:
	; lock the field size block

	mov	bx, UFSB_Local.ISF_fieldSizeBlock	
	call	MemLock
	mov	ds, ax

	; update the field size info if necessary

	pop	di
	shl	di, 1					; ds:di - field size
	mov	cx, UFSB_Local.ISF_sizeFieldData	; cx - new field size
	cmp	cx, ds:[di]			
	jle	unlock
	mov	ds:[di], cx				; update it
unlock:
	call	MemUnlock				; unlock the block

	.leave
	ret
UpdateFieldSizeBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateFieldInfoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a FieldInfoBlock and write it out to ssmeta file.

CALLED BY:	(INTERNAL) TransImport

PASS:		nothing

RETURN:		carry is cleared always

DESTROYED:	ax, bx, cx, dx, si, di, es

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	11/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateFieldInfoBlock	proc	near
	CFIB_Local	local	ImpexStackFrame
	CFIB_SSMeta 	local	SSMetaStruc
	.enter	inherit	near

	clr	dx				; dx - column number

	; allocate a FieldInfoBlock

	mov	ax, size FieldInfoBlock		; ax - # of bytes to allocate
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_NO_ERR) shl 8) or \
		    mask HF_SWAPABLE
	call	MemAlloc			; allocate a block

	push	bx				; save the handle
	call	MemLock
	mov	es, ax
	mov	es:[FIB_fieldType], FDT_GENERAL_TEXT	; text field
mainLoop:
	cmp	dx, CFIB_Local.ISF_highestNumFields	; are we done?
	je	exit
	; lock the field info block

	push	ds, dx				; ds - dgroup

	; get the mapped column number

	mov	ax, dx				; ax - column number
	mov	bx, CFIB_Local.ISF_mapBlock	; bx - handle of map block
        mov	cl, mask IF_IMPORT		; do import
	call	GetMappedRowAndColNumber	; returns ax = mapped col num
	jnc	next				; skip if not mapped

        ;mov     bx, CFIB_Local.ISF_notMappedList
	;call	ImportGetActualColumnNumber
	mov	dx, ax				; ax - true column number

	; get the field size from field size block

	mov	bx, CFIB_Local.ISF_fieldSizeBlock	
	call	MemLock				; lock field size block
	mov	ds, ax
	mov	di, dx
	shl	di, 1				; word size data
	mov	cx, ds:[di]			; cx - field data size
	call	MemUnlock
	mov	es:[FIB_fieldSize], cx		; save it to FieldInfoBlock

	; write out the default field name to FieldInfoBlock 

	mov	di, offset FIB_fieldName	; es:di - field name
	mov	cx, MAX_FIELD_NAME_LENGTH	; maximun field name length 
	call	GetDefaultFieldName		

	; initialize ssmeta stack frame

	mov	CFIB_SSMeta.SSMDAS_dataArraySpecifier, DAS_FIELD
	mov	CFIB_SSMeta.SSMDAS_row, 0
	mov	CFIB_SSMeta.SSMDAS_col, dx	; dx - column number

	; add this entry to DAS_FIELD data array

	mov	al, SSMAEF_ADD_IN_ROW_ORDER	; al - SSMetaAddEntryFlags
	tst	CFIB_Local.ISF_mapBlock		; does map block exist?
	jne	mapExist			; if so, skip

	; if no map block, add the entry to the end

	mov	al, SSMETA_ADD_TO_END		; al - SSMetaAddEntryFlags
mapExist:
	push	bp
	mov	cx, size FieldInfoBlock		; cx - # of bytes in the entry
	segmov	ds, es				; ds:si - string to copy
	clr	si				
	mov	dx, ss				; dx:bp - SSMetaStruc
	lea	bp, CFIB_SSMeta 
	call	SSMetaDataArrayAddEntry		; add the new element
	pop	bp
next:
	pop	ds, dx				; ds - dgroup
	inc	dx
	jmp	mainLoop			; loop, continue
exit:
	pop	bx
	call	MemFree				; free the field info block
	clc

	.leave
	ret
CreateFieldInfoBlock		endp

Import	ends
