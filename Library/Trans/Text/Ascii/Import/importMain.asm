COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Ascii Translation Library
FILE:		importMain.asm

AUTHOR:		Jenny Greenwood, 2 September 1992

ROUTINES:
	Name				Description
	----				-----------
    GLB TransImport		Import from Ascii file to transfer item

    GLB TransGetFormat		Determines if the file is in Ascii
				format.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/2/92		Initial version

DESCRIPTION:
	This file contains the main interface to the import side of the 
	library
		

	$Id: importMain.asm,v 1.2 98/01/23 22:10:17 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ImportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import from Ascii file to transfer item

CALLED BY:	GLOBAL
PASS:		ds:si	- ImportFrame on stack
RETURN:		ax	- TransError (0 = no error)
		bx	- memory handle of error text if ax = TE_CUSTOM
		dx:cx	- VM chain containing transfer item

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Save the source file handle.
	Set up clipboard object.
	Read in text from file.
	Get the transfer format.
	Append a block with the PageSetupInfo structure to the
	 transfer format.
	dx:cx <- VM chain containing transfer format.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jenny	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransImport	proc	far	uses	di, si, es
DBCS <	dosCodePage	local	DosCodePage	; for text xlate	>
textObj		local	optr
sourceFile	local	hptr
vmFile		local	hptr

		.enter
EC <		cmp	ds:[si].IF_formatNumber, IDSF__last		>
EC <		jae	badFormatNumber 				>

if DBCS_PCGEOS
		mov	cx, CODE_PAGE_SJIS
		cmp	ds:[si].IF_formatNumber, IDSF_ASCII
		je	setCodePage
		mov	cx, CODE_PAGE_JIS	; only have two formats
setCodePage:
		mov	ss:[dosCodePage], cx
endif
	;
	; Save the source file handle.
	;
		mov	ax, ds:[si].IF_sourceFile
		mov	ss:[sourceFile], ax
	;
	; Set up the clipboard object.
	;
		mov	bx, ds:[si].IF_transferVMFile
		mov	ss:[vmFile], bx
		clr	ax			; no regions, clear flags
		call	TextAllocClipboardObject
		movdw	textObj, bxsi
		call	InitializeClipboardObject
	;
	; Read in text from file.
	;
		call	ReadTextIntoClipboardObject
						; ax <- TransError or 0
		tst	ax
		jnz	error
	;
	; Get the transfer format.
	;
		mov	ax, TCO_RETURN_TRANSFER_FORMAT
		call	TextFinishWithClipboardObject
	;
	; Append a block with the PageSetupInfo structure to the
	; transfer format.
	;
		mov	bx, ss:[vmFile]
		call	AddPageSetupInfo
	;
	; dx:cx <- VM chain containing transfer format.
	;
		mov_tr	dx, ax
		clr	cx

		mov	ax, cx			; ax <- TE_NO_ERROR
done:		
		.leave
		ret

EC < badFormatNumber:							>
EC <		mov	ax, TE_INVALID_FORMAT				>
EC <		jmp	done						>

error:
		push	ax			; save TransError
		mov	ax, TCO_RETURN_NOTHING
		call	TextFinishWithClipboardObject
		pop	ax			; restore TransError
		jmp	done

TransImport		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeClipboardObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine initializes the clipboard object (sets up any
		necessary margins, etc.

CALLED BY:	GLOBAL
PASS:		^lbx:si - clipboard object
RETURN:		nada
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/19/92		Initial version (in MSMFile library)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeClipboardObject	proc	near	uses	di, bp
		.enter
	;
	; Set the font to be monospaced.
	;
		mov	dx, size VisTextSetFontIDParams
		sub	sp, dx
		mov	bp, sp
		movdw	ss:[bp].VTSFIDP_range.VTR_start, TEXT_ADDRESS_PAST_END
		movdw	ss:[bp].VTSFIDP_range.VTR_end, TEXT_ADDRESS_PAST_END
		mov	ss:[bp].VTSFIDP_fontID, FID_DTC_URW_MONO
		mov	ax, MSG_VIS_TEXT_SET_FONT_ID
		mov	di, mask MF_STACK
		call	ObjMessage
		add	sp, dx
	;
	; Set the point size of the font to be 10 CPI
	;
		mov	dx, size VisTextSetPointSizeParams
		sub	sp, dx
		mov	bp, sp
		movdw	ss:[bp].VTSPSP_range.VTR_start, TEXT_ADDRESS_PAST_END
		movdw	ss:[bp].VTSPSP_range.VTR_end, TEXT_ADDRESS_PAST_END
		mov	ss:[bp].VTSPSP_pointSize.WWF_frac, 0
		mov	ss:[bp].VTSPSP_pointSize.WWF_int, 12
		mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
		mov	di, mask MF_STACK
		call	ObjMessage
		add	sp, dx

		.leave
		ret
InitializeClipboardObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadTextIntoClipboardObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the source file text into the clipboard object.

CALLED BY:	TransImport
PASS:		nothing
RETURN:		ax	- TransError (0 = no error)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jenny	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadTextIntoClipboardObject	proc	near	uses bx, si, ds

		.enter	inherit	TransImport
	;
	; Allocate an intermediate buffer to read into so we can
	; convert the text to the GEOS character set before importing
	; it. 
	;
		mov	ax, READ_WRITE_BLOCK_SIZE
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	error
		mov	ds, ax			; ds <- buffer segment
		push	bx			; save buffer handle
		clr	di
readLoop:
	;
	; Read the data from the document into the buffer and convert
	; the buffer.
	;
		mov	bx, ss:[sourceFile]
SBCS <		clr	dx						>
SBCS <		mov	cx, READ_WRITE_BLOCK_SIZE			>
DBCS <		mov	dx, READ_WRITE_BLOCK_SIZE/2			>
DBCS <		mov	cx, dx			; cx <- # of bytes to read >
		clr	ax			; allow errors
		call	FileRead
		jnc	readOK
		cmp	ax, ERROR_SHORT_READ_WRITE
		mov	ax, TE_FILE_READ	; quit on any error
		jnz	freeBuffer		;  other than short read
		clr	ax			; ax <- TE_NO_ERROR
readOK:
		jcxz	freeBuffer

DBCS <		mov	ax, ss:[dosCodePage]	; char set for xlate	>
		call	ConvertBufferToGeos	; cx <- buffer length
		jc	convertError		; invalid character?
DBCS <		mov	ss:[dosCodePage], ax	; may have changed	>
		jcxz	readLoop
	;
	; Append the data to the text object.
	;
		mov	ax, MSG_VIS_TEXT_APPEND_BLOCK
		pop	dx			; dx <- buffer handle
		push	dx
		movdw	bxsi, ss:[textObj]
		clr	di
		call	ObjMessage

		jmp	readLoop
freeBuffer:
		pop	bx
		call	MemFree
done:
		.leave
		ret
error:
		mov	ax, TE_OUT_OF_MEMORY
		jmp	done
convertError:
		mov	ax, TE_IMPORT_ERROR
		jmp	freeBuffer

ReadTextIntoClipboardObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertBufferToGeos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a buffer from DOS to GEOS

CALLED BY:	ReadTextIntoClipboardObject
PASS:		ds:0	- buffer
		cx	- size
		di	- 0
	DBCS:
		bx	- handle of file
		ax	- DosCodePage
RETURN:		carry 	- set on error (DTGSS_INVALID_CHARACTER)
		cx	- new length
		ax	- DosCodePage (may have changed)
DESTROYED:	cx, dx, si, di, es
SIDE EFFECTS:	

	File position may retract a few bytes if buffer ends on an
incomplete character or incomplete ESC sequence.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	10/19/92	Initial version
	grisco	04/20/94	Handle JIS incomplete characters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertBufferToGeos	proc	near
DBCS <		clr	di						>
DBCS <		segmov	es, ds			;es:di <- dest ptr	>
	;
	; Convert to the GEOS character set, replacing all unknown characters
	; with C_CTRL_A
	;
DBCS <		push	bx			;save file handle	>
SBCS <		clr	si						>
DBCS <		mov	si, READ_WRITE_BLOCK_SIZE/2			>
DBCS <		mov	bx, ax			;bx <- DosCodePage	>
		mov	ax, C_CTRL_A		;replacement character
DBCS <		clr	dx			;dx <- disk handle	>
		call	LocalDosToGeos
DBCS <		mov	dx, bx			;dx <- new DosCodePage	>
DBCS <		pop	bx						>
	;
	; If invalid DOS characters exist in the file (or if the user
	; tried to read in a file consisting of a format other than
	; the selected format) stop importing and return an error.
	;
if DBCS_PCGEOS
		cmp	al, DTGSS_INVALID_CHARACTER
		je	error

		push	dx			;save DosCodePage

	;
	; In multi-byte versions of DOS, it is possible we split the
	; last character.  If so, adjust the file pointer back 
	; so we re-read the char.  Not particularly efficient,
	; but easier than adjusting ptrs, buffer sizes, etc. here.
	;
		cmp	al, DTGSS_CHARACTER_INCOMPLETE	;split character?
		jne	noAdjust		;branch if not
		push	cx			;save # of chars

		clrdw	cxdx
		mov	dl, ah
		negdw	cxdx			; # of bytes to backup

		mov	al, FILE_POS_RELATIVE	;al <- FilePosMode
		call	FilePos
		pop	cx			;cx <- # of chars
noAdjust:

		pop	dx			;DosCodePage
		clr	si			;ds:si <- source ptr
else	; SBCS
		jc 	error			; => unsupported char
		segmov	es, ds			;es:di <- dest ptr
endif
fooLoop:
		LocalGetChar ax, dssi		;ax <- character

		LocalCmpChar ax, C_TAB
		jz	store
		LocalCmpChar ax, C_CR
		jz	store	
		LocalCmpChar ax, C_PAGE_BREAK
		jz	store
		LocalCmpChar ax, ' '
		jb	skip
store:
		LocalPutChar esdi, ax		;else store character
skip:
		loop	fooLoop			;loop while more bytes

		mov	cx, di			;return new size
DBCS <		mov_tr	ax, dx			;return new DosCodePage	>
DBCS <		shr	cx, 1			;cx <- new length	>
	;
	; 1/23/98: There was previously no clc here, resulting in the
	; carry flag being in an unpredictable state -- eca
	;
		clc				;carry <- no error
		ret
error:
		stc				;carry <- error invalid char
		ret
ConvertBufferToGeos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPageSetupInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine adds page setup information to the passed
		TextTransferBlockHeader vm block.

CALLED BY:	TransImport
PASS:		ax	- handle of VM block containing TextTransferBlockHeader
		bx	- handle of VM file
RETURN:		nada
DESTROYED:	bx, cx, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jenny	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddPageSetupInfo	proc	near	uses	ax
		.enter
	;
	; Allocate a vm block to hold the PageSetupInfo structure.
	;
		push	ax
		clr	ax
		mov	cx, size PageSetupInfo
		call	VMAlloc
		mov_tr	cx, ax		; CX <- handle of block to contain
					;	PageSetupInfo
		pop	ax		; AX <- handle of
					;	TextTransferBlockHeader block
	;
	; Stuff the handle of the pageSetup block in the
	; TextTransferBlockHeader.
	;
		push	bp		; save bp

		call	VMLock		; Lock the block
		mov	es, ax
		mov	es:[TTBH_pageSetup].high, cx
		clr	es:[TTBH_pageSetup].low
		call	VMDirty
		call	VMUnlock
	;
	; Fill in the PageSetupInfo structure.
	;
		mov_tr	ax, cx
		call	VMLock
		mov	es, ax
		call	VMDirty
		clr	ax

		mov	es:[PSI_meta].VMCL_next, ax

		mov	es:[PSI_numColumns], 1
		mov	es:[PSI_columnSpacing], ax
		mov	es:[PSI_ruleWidth], ax

		mov	es:[PSI_pageSize].XYS_width, DEFAULT_PAGE_WIDTH
		mov	es:[PSI_pageSize].XYS_height, DEFAULT_PAGE_HEIGHT

		mov	es:[PSI_leftMargin], DEFAULT_LEFT_MARGIN shl 3
		mov	es:[PSI_rightMargin], DEFAULT_RIGHT_MARGIN shl 3
		mov	es:[PSI_topMargin], DEFAULT_TOP_MARGIN shl 3
		mov	es:[PSI_bottomMargin], DEFAULT_BOTTOM_MARGIN shl 3

		mov	es:[PSI_layout], ax

		call	VMUnlock

		pop	bp		; restore bp

		.leave
		ret

AddPageSetupInfo	endp



if PZ_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DetectJapaneseCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detects the DOS format (JIS/SJIS) of the buffer. 

CALLED BY:	TransGetFormat()
PASS:		ds:si - pointer to text buffer
		cx    - buffer size
RETURN:		bx    - ImpexDataSpecificFormat format number
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

	We're just going to search for the JIS open escape sequence.  If 
such an escape sequence is found then chances are it is JIS, otherwise 
we'll assume that it's SJIS.

	It is likely that the buffer passed to this routine is not the
entire ASCII file.  Rather, the buffer consists of the first cx chars
of the file.  This routine can be called several times to check the
entire file for JIS escape sequences (until one is found or end-of-file),
or the caller can assume that the first cx chars is enough to determine
the format (so checking large SJIS files won't take forever).

	Right now, if the first one or two characters of the ESC
sequence are the last characters in the buffer, they are ignored.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	11/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DetectJapaneseCode	proc	near
	uses	ax,cx,si
	.enter

	mov	bx, IDSF_ASCII
	jcxz	allDone				; no more chars to look at?
	clr	ah				; assume byte-size JIS chars
topOfLoop:
	lodsb					; get the next char
	LocalCmpChar	ax, C_ESC		; is it an ESC?
	jne	notEscapeSequence

	jcxz	allDone				; ESC seq on the border?
	dec	cx
	lodsb					; get another character
	LocalCmpChar	ax, C_DOLLAR_SIGN	; is it '$'
	jne	notEscapeSequence

	jcxz	allDone				; ESC seq on the border?
	dec	cx
	lodsb
	LocalCmpChar	ax, C_LATIN_CAPITAL_LETTER_B
	jne	notEscapeSequence

	mov	bx, IDSF_JIS			; recognized "ESC $ B"
	jmp	allDone
notEscapeSequence:	
	loop	topOfLoop

	mov	bx, IDSF_ASCII			; It's not JIS, assume SJIS
allDone:

	.leave
	ret
DetectJapaneseCode	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the file is in Ascii format.	

CALLED BY:	GLOBAL
PASS:		si	- file handle (open for read)	
RETURN:		ax	- TransError (0 = no error)
		cx	- format number if valid format
			  or NO_IDEA_FORMAT if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/24/92		Initial version
	don	6/21/94		Wrote actual format-checking code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

excludedFormats	word \
		offset rtfIdentifier1,
		length rtfIdentifier1,
		offset rtfIdentifier2,
		length rtfIdentifier2,
		0,
		0

rtfIdentifier1	char	"{\\rtf"
rtfIdentifier2	char	"{\\RTF"

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
		clc				; no characters = success!
		jcxz	freeBuffer
	;
	; Check for excluded formats first by scanning for text at
	; the beginning of the file that identifies the format. If
	; we something matches, we're done (and assume that another
	; translation library will handle the file).
	;
		mov	di, offset excludedFormats
		segmov	es, cs, ax
		mov	dx, cx			; size of file read => DX
exclusionLoop:
		push	di
		mov	cx, es:[di+2]
		mov	di, es:[di]
		jcxz	doneExclusions
		cmp	cx, dx
		ja	nextExclusion
		clr	si
		repe	cmpsb
		jne	nextExclusion
	;
	; We matched an exclusion, so we're outta here
	;
		pop	di
		stc				; indicate failure
		jmp	freeBuffer
nextExclusion:
		pop	di
		add	di, 4
		jmp	exclusionLoop
doneExclusions:
		pop	di
		mov	cx, dx
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

ImportCode	ends
