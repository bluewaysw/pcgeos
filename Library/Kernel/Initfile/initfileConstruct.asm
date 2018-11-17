COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Kernel/Initfile
FILE:		initfileConstruct.asm

AUTHOR:		Cheng, 11/89

ROUTINES:
	Name			Description
	----			-----------
    INT BuildEntryFromData	Converts the data in the data buffer into
				ASCII decimals for storage in the init
				file.

    INT BuildEntryFromString	Ensures that the body string given is
				legal, converting it to a blob if necessary
				and escaping any special characters.

    INT InitEntry		Allocates and initializes the string
				construction buffer.

    INT DoReconstruct		Calls the proper reconstruction routine
				based on flag.

    INT ReconstructData		Reconstruct the original data buffer by
				converting the ASCII numbers into binary
				data.

    INT ReconstructString	Reconstruct the original string entry by
				removing any enclosing braces and escape
				characters.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial revision

DESCRIPTION:
		
	$Id: initfileConstruct.asm,v 1.1 97/04/05 01:18:06 newdeal Exp $

-------------------------------------------------------------------------------@

InitfileWrite	segment	resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	BuildEntryFromData

DESCRIPTION:	Converts the data in the data buffer into ASCII decimals
		for storage in the init file.

CALLED BY:	INTERNAL (LibInitFileWriteData)

PASS:		es, bp - dgroup
		dgroup:[keyStrAddr] - key ASCIIZ string
		dgroup:[bufAddr] - source buffer
		dgroup:[bufFlag] -
			0 => word at bufAddr = number to convert
			non-zero => size of buffer

RETURN:		dgroup:[buildBufHan]
		dgroup:[buildBufAddr]
		dgroup:[buildBufSize]
		dgroup:[entrySize]

DESTROYED:	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	allocate a buffer in which to build out a legal string
	in the worst case, each byte in the source buffer can expand to 3 chars
		=> buffer needs to be at least 3x as large as source buffer
	add to that the spaces necessary to seperate the data
		=> buffer size needs to be 4x source buffer

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

BuildEntryFromData	proc	near
EC<	call	IFCheckDgroupRegs					>

	push	cx,dx,di,si,ds
	mov	cx, es:[bufFlag]
	tst	cx
	jne	bufferPassed

	;-----------------------------------------------------------------------
	;user wants to store a single word

	mov	ax, word ptr es:[bufAddr]	;get number to convert
	push	ax
	mov	cx, 8			;65536
	call	InitEntry		;es:di<-func(bp,cx), dest ax

	pop	ax			;ax <- number to convert
	push	ax
	call	Hex8ToAscii		;di <- func(al, es:di)
	pop	ax
	mov	al, ah
	call	Hex8ToAscii		;di <- func(al, es:di)
	jmp	short terminateStr

bufferPassed:
	;-----------------------------------------------------------------------
	;user wants to store all bytes in a buffer
	;es, bp - dgroup
	;cx - size of buffer

EC<	call	IFCheckDgroupRegs					>
	push	cx			;save size of buffer

	;-----------------------------------------------------------------------
	;compute size of string construction buffer
	;count space taken by line seperators

	mov	bx, DATA_ENTRY_NUMBERS_PER_LINE
	clr	dx
	mov	ax, cx
	div	bx			;ax <- number of lines required
	shl	ax, 1			;ax <- ax * 2 for CR, LF

	;-----------------------------------------------------------------------
	;count space taken by numbers

	shl	cx, 1
	push	cx			;save space taken by numbers

	;-----------------------------------------------------------------------
	;add space that a blob would take

	add	cx, 4			;CR, LF, CR, LF
	add	cx, ax			;add space for line seperators
	call	InitEntry		;es:di <- build buffer, destroys ax

	;-----------------------------------------------------------------------
	;es:di - current string construction buffer address
	;bx - blob indicator
	;dx - offset within line, used to tell when to start new line

	pop	cx			;retrieve space taken by numbers
	clr	bx			;init blob flag
	add	cx, di
	cmp	cx, DATA_ENTRY_LINE_SIZE	;overflows line?
	jle	blobNotNeeded
	dec	bx
SBCS <	mov	ax, (VC_ENTER shl 8) or '{'				>
DBCS <	mov	ax, (C_ENTER shl 8) or '{'				>
	stosw
SBCS <	mov	al, VC_LF						>
DBCS <	mov	al, C_LINEFEED						>
	stosb

blobNotNeeded:
	pop	cx			;retrieve size of data buffer
	mov	ds, bp			;ds <- dgroup
	lds	si, ds:[bufAddr]	;ds:si <- data buffer

	clr	dx			;init line offset
convLoop:
	lodsb				;get byte from data buffer
	call	Hex8ToAscii		;func(al, es:di), destroys ax
	add	dx, DATA_ENTRY_NUMBER_SIZE	;add size of numeric entry
	cmp	dx, DATA_ENTRY_LINE_SIZE
	jne	checkDone

	;-----------------------------------------------------------------------
	;current line filled up, stick in CR,LF seperator

SBCS <	mov	ax, (VC_LF shl 8) or VC_ENTER				>
DBCS <	mov	ax, (C_LINEFEED shl 8) or C_ENTER			>
	stosw
	clr	dx			;reset line offset

checkDone:
	loop	convLoop

	tst	bx			;blob?
	je	terminateStr		;branch if not

	tst	dx			;else CR, LF already present?
	je	insertEndBrace		;branch if so

SBCS <	mov	ax, (VC_LF shl 8) or VC_ENTER				>
DBCS <	mov	ax, (C_LINEFEED shl 8) or C_ENTER			>
	stosw

insertEndBrace:
	mov	al, '}'
	stosb

terminateStr:
	;-----------------------------------------------------------------------
	;es:di = current pos in entry string

SBCS <	mov	ax, (VC_LF shl 8) or VC_ENTER				>
DBCS <	mov	ax, (C_LINEFEED shl 8) or C_ENTER			>
	stosw
	clr	al
	stosb

	mov	es, bp			;restore es
	dec	di
	mov	es:[entrySize], di

	pop	cx,dx,di,si,ds
	ret
BuildEntryFromData	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	BuildEntryFromString

DESCRIPTION:	Ensures that the body string given is legal, converting it to
		a blob if necessary and escaping any special characters.

CALLED BY:	INTERNAL (LibInitFileWriteString)

PASS:		es, bp - dgroup
		dgroup:[keyStrAddr]
		dgroup:[bodyStrAddr]

RETURN:		dgroup:[buildBufHan]
		dgroup:[buildBufAddr]
		dgroup:[buildBufSize]
		dgroup:[entrySize]

DESTROYED:	ax, bx

REGISTER/STACK USAGE:
	bx - blob flag (0=false)

PSEUDO CODE/STRATEGY:
	allocate a buffer in which to build out a legal string
	in the worst case, each character in the source string can be escaped
		=> buffer needs to be at least 2x as large as source string
	add to that the possibly of carriage returns or line feeds exist
		=> conversion to a blob is necessary
		=> add 2 to buffer size for braces

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

BuildEntryFromString	proc	near
	uses	cx, dx, di, si, ds
	.enter

	les	di, es:[bufAddr]
	mov	si, di			; es:si <- body string
	mov	cx, -1
	mov	bx, cx			; assumes a blob is needed
	clr	al
	repne	scasb
	not	cx
	dec	cx			; cx <- string length

	;-----------------------------------------------------------------------
	;is their any leading or trailing tab or space characters?
	;es:di - body string
	;cx - size of body

	mov	dx, cx
	jcxz	initEntry		;skip this test for NULL string
	mov	di, si
	add	di, cx
	dec	di			;es:di <- end of string

SBCS <	mov	al, VC_BLANK						>
DBCS <	mov	al, C_SPACE						>
	cmp	es:[di], al
	je	initEntry
	cmp	es:[si], al
	je	initEntry

SBCS <	mov	al, VC_TAB						>
DBCS <	mov	al, C_TAB						>
	cmp	es:[di], al
	je	initEntry
	cmp	es:[si], al
	je	initEntry

	;-----------------------------------------------------------------------
	;do any CR or LF characters appear?
	;es:si - body string
	;cx,dx - size of body

	mov	di, si
SBCS <	mov	al, VC_ENTER						>
DBCS <	mov	al, C_ENTER						>
	repne	scasb			;scan for CR
	jz	initEntry		;CR found, so use a blob	
	
	mov	di, si
	mov	cx, dx
SBCS <	mov	al, VC_LF						>
DBCS <	mov	al, C_LINEFEED						>
	repne	scasb			;scan for LF
	jz	initEntry		;LF found, so use a blob

	; any comment (semicolon) chars?
	mov	di, si
	mov	cx, dx
	mov	al, INIT_FILE_COMMENT
	repne	scasb			;scan for semi
	jz	initEntry		;semicolon found, so use a blob
	clr	bx			;no special chars, so no blob

initEntry:
	mov	di, si
	mov	cx, dx
	shl	cx, 1			;entry can be twice as large
	mov	es, bp			;es <- dgroup
	call	InitEntry		;alloc buffer and copy key string
					;es:di <- buildBuffer, destroys ax
	mov	cx, dx			;cx <- body string length
	mov	ds, bp			;ds <- dgroup
	lds	si, ds:[bufAddr]

	jcxz	nullString
	tst	bx
	je	setupEscape

	mov	al, '{'
	stosb
SBCS <	mov	ax, VC_ENTER or (VC_LF shl 8)				>
DBCS <	mov	ax, C_ENTER or (C_LINEFEED shl 8)			>
	stosw

	;-----------------------------------------------------------------------
	;loop for all chars in string
	;ds:si - body string
	;es:di - string construction buffer
	;cx - size of body string

setupEscape:
	mov	ah, '\\'
fetchChar:
	lodsb

	cmp	al, '['			;always escape '[' no matter where
					; it occurs and regardless of whether
					; this is a blob, else we're likely to
					; consider the thing a category later
					; on.
	je	storeEscaped
	cmp	al, '{'			;always escape '{' too, so we don't
					; think a '{' at the start of the
					; passed string means blob start when
					; in fact it doesn't.
	je	storeEscaped

	tst	bx			;blob?
	je	doStore			;branch if not

	cmp	al, '}'
	je	storeEscaped

	cmp	al, ah			;escape backslashes in blobs
	je	storeEscaped

notBrace:                               ;escape CR ONLY if not paired with LF
SBCS<   cmp     al, VC_ENTER                                            >
DBCS<   cmp     al, C_ENTER                                             >
        jne     notCR
        ; check if next char is LF
SBCS<   cmp     {char}ds:[si], VC_LF                                    >
DBCS<   cmp     {char}ds:[si], C_LINEFEED                               >
        jne     isOnlyCR
        ; store CR/LF unescaped
        stosb
        dec     cx
        lodsb
        jmp     short doStore

isOnlyCR:
        mov     al, 'r'
        jmp     short storeEscaped

notCR:                                  ;escape LF
SBCS<   cmp     al, VC_LF                                               >
DBCS<   cmp     al, C_LINEFEED                                          >
        jne     doStore
        mov     al, 'n'
        ; fall-thru to storeEscaped...

storeEscaped:
	xchg	al, ah			;al <- '\'
	stosb
	xchg	al, ah			;restore al

doStore:
	stosb
	loop	fetchChar

	;-----------------------------------------------------------------------
	;terminate if blob

	tst	bx
	je	terminate
SBCS <	mov	ax, (VC_LF shl 8) or VC_ENTER				>
DBCS <	mov	ax, (C_LINEFEED shl 8) or C_ENTER			>
	stosw
	mov	al, '}'
	stosb

terminate:
	;-----------------------------------------------------------------------
	;terminate

SBCS <	mov	ax, (VC_LF shl 8) or VC_ENTER				>
DBCS <	mov	ax, (C_LINEFEED shl 8) or C_ENTER			>
	stosw
	clr	al
	stosb

	mov	es, bp			;restore es
	dec	di
	mov	es:[entrySize], di

	.leave
	ret

nullString:
	;-----------------------------------------------------------------------
	;null string passed
	;indicate null string with an empty blob

	mov	ax, '{' or ('}' shl 8)
	stosw
	jmp	terminate
BuildEntryFromString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitEntry

DESCRIPTION:	Allocates and initializes the string construction buffer.

CALLED BY:	INTERNAL (BuildEntryFromData, BuildEntryFromString)

PASS:		cx - desired size of body
		es, bp - dgroup
		dgroup:[keyStrAddr] - key ASCIIZ string

RETURN:		es - seg addr of build buffer
		di - offset to first body location
		dgroup:[buildBufHan]
		dgroup:[buildBufAddr]
		dgroup:[buildBufSize]

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

InitEntry	proc	near
	uses	bx, cx, si, ds
	.enter

EC<	call	IFCheckDgroupRegs					>

	lds	si, es:[keyStrAddr]
	mov	di, es:[keyStrLen]
	push	di			;save size of key string

	;-----------------------------------------------------------------------
	;allocate build buffer

	add	cx, di			;cx <-  body size + key string length
	add	cx, 12			;' ', '=', ' ', '{', '}', CR, LF, 0
	mov	ax, cx
	mov	es:[buildBufSize], ax
	mov	cx, HAF_STANDARD_NO_ERR_LOCK shl 8 or mask HF_SWAPABLE
	call	MemAllocFar
	mov	es:[buildBufHan], bx
	mov	es:[buildBufAddr], ax
	mov	es, ax
	clr	di			;es:di <- build buffer

	;-----------------------------------------------------------------------
	;copy key string over
	;ds:si - key string
	;es:di - build buffer

	pop	cx			;retrieve size of key string
	rep	movsb

	;-----------------------------------------------------------------------
	;store ' = '

	mov	ax, ('=' shl 8) or ' '	;ax = '= '
	stosw
	stosb				;al already = ' '

	;-----------------------------------------------------------------------
	;di points at first body location

	.leave
	ret
InitEntry	endp

InitfileWrite	ends



InitfileRead	segment	resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoReconstruct

DESCRIPTION:	Calls the proper reconstruction routine based on flag.

CALLED BY:	INTERNAL (InitFileGet)

PASS:		bp - dgroup
		bx - operation (InitFileOperationType)
		see ReconstructData & ReconstructString

RETURN:		see ReconstructData & ReconstructString

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

DoReconstruct	proc	near
	cmp	bx, IFOT_DATA
	je	doData
		CheckHack <IFOT_DATA eq 0>
if DBCS_PCGEOS
	dec	cx
	dec	cx				;save room for the null
	call	ReconstructData
EC <	test	cx, 1							>
EC <	ERROR_NZ	ILLEGAL_INIT_FILE_STRING			>
	push	di				;save buffer pointer
	add	di, cx				;point past last char
	jcxz	nullTerm
	tst	{wchar}es:[di-2]
	jz	haveNull
nullTerm:
	and	{wchar}es:[di], 0		;NULL-terminate
	add	cx, 2
haveNull:
	pop	di				;restore buffer pointer
	ret
else
	GOTO	ReconstructString
endif
doData:
	FALL_THRU	ReconstructData
DoReconstruct	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReconstructData

DESCRIPTION:	Reconstruct the original data buffer by converting
		the ASCII numbers into binary data.

CALLED BY:	INTERNAL (LibInitFileGetData)

PASS:		bp - dgroup
		dgroup:[initFileBufPos] - offset from BufAddr to start of data
		es:di - buffer to place data in
		cx - size of buffer

RETURN:		es:di - buffer containing binary data
		cx - size of buffer used

DESTROYED:	ax, bx

REGISTER/STACK USAGE:
	while not eoln
		conv number
		store in buffer

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

;FALL THROUGH FROM ABOVE

ReconstructData	proc	near
	push	dx,si,ds,es,di
	push	cx

	;
	; Are these lines necessary?  bufAddr seems to be set in EnterInitFile.
	; -cbh 1/ 4/91
	;
	mov	ax, es			;sav seg addr of buffer
	mov	es, bp			;es <- dgroup
	
	mov	es:[bufAddr].offset, di	
	mov	es:[bufAddr].segment, ax

	call	SkipWhiteSpace
	call	GetChar
	push	ax
	call	SkipWhiteSpace
	pop	ax
	clr	bx
	cmp	al, '{'
	jne	notBlob
	dec	bx
	jmp	short convLoop
notBlob:
	dec	es:[initFileBufPos]	;unget char
convLoop:
	call	GetChar			; get next char
	jc	done			; => EOF
	cmp	al, '}'			; end of blob?
	je	done			; yes (no need to check if in blob
					;  as this shouldn't be here if
					;  we're not :)
	cmp	al, '\r'		; return?
	je	checkIgnoreCRLF		; yes -- terminate if not blob
	cmp	al, '\n'		; newline?
	je	checkIgnoreCRLF		; yes -- terminate if not blob

	call	convertNibble		; convert high nibble to binary
	jc	done			; => not hex digit
	cbw				; clear AH (1-byte inst)
	ror	ax			; shift high nibble into high nibble
	ror	ax			;  of AH
	ror	ax
	ror	ax
	call	GetChar			; al <- low nibble in ascii
	call	convertNibble
	jc	done			; => not hex digit
	or	al, ah			; merge the nibbles
	mov	es, es:[bufAddr].segment; es:di <- storage point
	stosb
	mov	es, bp			; es <- dgroup again
	loop	convLoop

	; ran out of room
done:
	mov_tr	ax, cx			; ax <- bytes left
	pop	cx			; cx <- bytes there were
	sub	cx, ax
	mov	es:[bufAddr].offset, di	; in case caller needs this
	pop	dx,si,ds,es,di
	ret

checkIgnoreCRLF:
	tst	bx			; blob?
	jnz	convLoop		; yup -- just ignore this char
	jmp	done			; nope -- done converting

	;
	; Internal routine to convert a hex digit in ASCII to its binary
	; equivalent while ensuring the digit itself is a valid hex digit.
	;
	; Pass:		al	= ASCII hex digit
	; Return:	carry set if digit invalid
	; 		carry clear if digit is fine:
	; 			al	= 0-15
convertNibble:
	sub	al, '0'
	jb	cNDone			; => below '0', so err
	cmp	al, 9
	jbe	cNDoneOK		; => must be '0'-'9'

	sub	al, 'A'-'0'		; convert 'A'-'F' to 0-5
	jb	cNDone			; => between '9' and 'A', so err
	cmp	al, 5			; 'A'-'F' ?
	jbe	cNDoneAdd10		; yes -- happiness

	sub	al, 'a'-'A'		; assume lower-case 'a'-'f'
	jb	cNDone			; between 'F' and 'a', so err
	cmp	al, 6			; 'a'-'f'?
	cmc				; invert sense so carry set if not
	jb	cNDone			; not
cNDoneAdd10:
	add	al, 10			; convert 0-5 to 10-15
cNDoneOK:
	clc
cNDone:
	retn
ReconstructData	endp

if not DBCS_PCGEOS

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReconstructString

DESCRIPTION:	Reconstruct the original string entry by removing any
		enclosing braces and escape characters.

CALLED BY:	INTERNAL (LibInitFileGetString)

PASS:		bp - dgroup
		dgroup:[initFileBufPos] - offset from BufAddr to start of data
		es:di - buffer to place data in
		cx - # of chars in buffer

RETURN:		es:di - buffer containing string
		cx - size of buffer used (# chars *2)

DESTROYED:	ax, bx

REGISTER/STACK USAGE:
	ds:si - buffer
	bp - blob flag (0 = false)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

ReconstructString	proc	near
	push	di,es
	push	cx			;save size of buffer

	;
	; Are these lines necessary?  bufAddr seems to be set in EnterInitFile.
	; -cbh 1/ 4/91
	;
	mov	ax, es			;sav seg addr of buffer
	mov	es, bp			;es <- dgroup
	
	mov	es:[bufAddr].offset, di	
	mov	es:[bufAddr].segment, ax

	call	SkipWhiteSpace		;func(es)

	call	GetChar
	clr	bx
	cmp	al, '{'			;blob?
	jne	charGotten
blob::

	dec	bx			;bx <- -1 => blob

	;-----------------------------------------------------------------------
	;ignore blob initiation chars - ie. CR, LF

	call	GetChar
	cmp	al, VC_ENTER
	jne	charGotten

	call	GetChar
	cmp	al, VC_LF
	jne	charGotten
	
copyLoop:
	mov	es, bp
	call	GetChar			;fetch char
charGotten:
	mov	es, es:[bufAddr].segment

	cmp	al, '\\'		;escape char?
	je	checkEscape		;branch if so

	tst	bx			;processing blob?
	jne	processingBlob		;branch if so

	cmp	al, VC_ENTER		;else CR?
	je	copyDone		;done if so
	cmp	al, VC_LF		;LF?
	je	copyDone		;done if so
	cmp	al, MSDOS_TEXT_FILE_EOF	;EOF?
	je	copyDone		;done if so

doStore:
EC <	push	ds, si							>
EC <	segmov	ds, es							>
EC <	mov	si, di							>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>
	stosb				;store char in buffer
	loop	copyLoop		;loop if space still exists

	dec	di			;make space for null terminator
	inc	cx
	jmp	short copyDone		;go store terminator

processingBlob:
	;not '\'
	cmp	al,'}'			;blob terminator?
	jne	doStore

	;-----------------------------------------------------------------------
	;unescaped blob terminator found, ignore trailing CR, LF if they exist

	mov	bx, es
	mov	es, bp
	mov	ax, es:[bufAddr].offset
	mov	es, bx
	sub	ax, di
	cmp	ax, -2			;more than two bytes stored?
	jg	copyDone		;no -- can't be trailing CR, LF to strip

	cmp	{char}es:[di-2], VC_ENTER
	jne	copyDone

	sub	di, 2
	add	cx, 2			;reduce byte count by CR, LF
	jmp	copyDone

checkEscape:
	;'\'
	mov	es, bp
	call	GetChar			;fetch char
EC<	ERROR_C	INIT_FILE_BAD_BLOB					>
	cmp	al, '{'			;escaping blob start?
	je	setESDoStore		;branch if so

	cmp	al, '['			;escaping category-start?
	je	setESDoStore		;branch if so

	tst	bx			;processing blob?
	jz	unget			;no: those were the only escapable
					; chars, so unget and store normal

	cmp	al, '}'			;escaping blob terminator?
	je	setESDoStore		;branch if so

	cmp	al, '\\'		;escaping backslash?
	je	setESDoStore		;branch if so

        cmp     al, 'n'                 ;escaping VC_LF?
        jne     notLF                   ;branch if not
        mov     al, VC_LF               ;make the substitution
        jmp     short setESDoStore      ;and store it

notLF:
        cmp     al, 'r'                 ;escaping VC_ENTER?
        jne     unget                   ;branch if not
        mov     al, VC_ENTER            ;make the substitution
        jmp     short setESDoStore      ;and store it

unget:
	dec	es:[initFileBufPos]	;else unget char
	mov	al, '\\'		;store '\'
setESDoStore:
	mov	es, es:[bufAddr].segment
	jmp	short doStore

copyDone:
	clr	ax
	stosb				;store char in buffer
	dec	cx			;One more char in buffer
	mov	es, bp
	mov	es:[bufAddr].offset, di
	pop	ax			;retrieve size of buffer
	sub	ax, cx
	mov	cx, ax
	pop	di,es
	ret
ReconstructString	endp

endif

InitfileRead	ends
