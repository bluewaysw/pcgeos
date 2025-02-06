COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Spell
FILE:		ihcalls.asm

AUTHOR:		Ty Johnson, Oct 27, 1992

ROUTINES:
	Name			Description
	----			-----------
EXTERNAL:
	HyphenOpen		Initializes the H-M hyphenator
	Hypenate		Returns hyphenation points for given word
	HyphenClose		Closes the H-M hyphenator (frees mem, etc)

INTERNAL:
	HyphenateDoWork		Does the work of Hyphenate
	BitsToBytes		Converts a bitmask of hyphenation points
	DwordsToWords		Converts 2 dword bitmask to 4 word bitmask
	GetOneWord		Formats the input string to one word
	HyphenSetPath		Sets the hyphen database directory
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/27/92   	Initial revision


DESCRIPTION:
	
	$Id: ihCalls.asm,v 1.1 97/04/07 11:08:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HyphenCode segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyphenOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the hyphenator (grabs memory, opens db file,  etc)

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax = 0 if no error, nonzero if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/27/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyphenOpen	proc	far
	uses	bx,cx,dx,si,di,bp,ds,es
 	.enter

	call 	FILEPUSHDIR			; push the directory
	jmp	markStatusError
	
	call	HyphenSetPath			; set the directory

	;
	; Set up the parameters to call IHhyp()
	;
	; First create the IHBuff structure
	;
	mov	cx, segment udata
	mov	es, cx
	mov	ax, size IHBuff
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK)shl 8) \
			or mask HF_SWAPABLE or mask HF_SHARABLE
	mov	bx, handle 0		
	call	MemAllocSetOwner	; bx=block,ax=seg,cx destroyed	
	jc	markStatusError		; exit on error

	mov	es:[anIHBuffHandle], bx	; save the block handle
	mov	es, ax			; es:0 -> IHBuff


	segmov	ds, cs, cx
	mov	dx, offset langKey
	mov	si, offset hypCat
	call	InitFileReadInteger
	jc	loadDefault
	mov	es:[lang], al

	mov	dx, offset dictKey
if DBCS_PCGEOS
	clr	bp			; allocate buffer
	call	InitFileReadString
	jc	loadDefault		; not found
	;
	; convert DBCS filename to SBCS
	;	cx = # chars (excluding null)
	;	bx = mem handle
	;
	inc	cx			; include null
	push	ds, si
	call	MemLock
	mov	ds, ax			; ds:si = DBCS filename src.
	clr	si
	mov	di, offset tab_fn	; es:di = SBCS filename dest.
convLoop:
	lodsw
	stosb
	loop	convLoop
	call	MemFree
	pop	ds, si
	jmp	short openDict

else
	mov	di, offset tab_fn
	mov	bp, mask IFRF_SIZE or (size tab_fn-1)
	call	InitFileReadString
	jnc	openDict
endif

loadDefault:
	
;	We couldn't load the data from the .ini file, so just load the default
;	instead.

	;
	; Set the language 
	;
	mov	es:lang, SL_ENGLISH	

	;
	; Copy default filename to anIHBuff
	;

	push	es
	mov	di, offset tab_fn		;dest
	segmov	ds, cs
	mov	si, offset fileName		;source
charLoop:
	lodsb
	stosb
	tst	al
	jnz	charLoop
	pop	es				; es:di -> IHBuff filename

openDict:
	mov	es:task, INITIALIZE

	;
	; Push parameters to IHhyp (in reverse order)
	;
FXIP <	clr	di				; making null string	>
FXIP <	push	di							>
FXIP <	mov	di, sp							>
FXIP <	pushdw	ssdi				; ss:di = ptr to null	>
NOFXIP<	mov	di, offset nullString					>
NOFXIP<	pushdw	csdi			;push ptr -> null string	>
	
	clr	di
	pushdw	esdi				; push ptr -> anIHBuff on stack
	;call	IHhyp				; ax = non-zero if error
FXIP <	pop	di				; restore the stack	>

	;
	; Unlock the IHBuff block	
	;
	mov	cx, segment udata
	mov	es, cx
	mov	bx, es:[anIHBuffHandle]
	call	MemUnlock

	;
	; Mark that hyphen has been opened
	;
	mov	es:[hyphenOpened], 1

exit:
	mov	es:[hyphenStatus], ax		; save status of open

	call 	FILEPOPDIR			; restore the directory
	.leave
	ret
markStatusError:
	mov	ax, IHFAILURE
	jmp 	exit
HyphenOpen	endp
hypCat		char	"text",0
langKey		char	"hyphenationLanguage",0
dictKey		char	"hyphenationDictionary",0
SBCS <hyphenPathName	char	"dicts"					>
DBCS <hyphenPathName	wchar	"dicts"					>

ife FULL_EXECUTE_IN_PLACE
SBCS <nullString	char	0		; null for hyphenPathName>
DBCS <nullString	wchar	0		; null for hyphenPathName>
endif

fileName	char	"hecdp301.dat",0	; only used as SBCS string


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Hyphenate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes a null-term string and returns a byte array of 
		hyphenation points for the first word in the string. 

CALLED BY:	Library/Text/TextLine/tlHyphenation.asm
		ChooseHyphenationPosition (GLOBAL)

PASS:		args on stack (pascal convention)

RETURN:		^hax  = global memhandle to sorted array of hyphenation points 
			(short integers), null terminated.
			(0 if error)

DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/27/92    	Initial version


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
Hyphenate	proc	far		wordToHyphenate:fptr, wordLen:word
		uses	es, di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, wordToHyphenate				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	
	;
	; Allocate a block of memory for the string, because we can't pass
	; it on the stack - we'll have to just pass a block handle in a 
	; register, since we need to call ThreadBorrowStackSpace. 	
	;

	les	di, wordToHyphenate
	mov	ax, wordLen
	push	es,ds,si,di,bx,ax
SBCS <	mov	ax, MAX_WORD_LENGTH+1					>
DBCS <	mov	ax, (MAX_WORD_LENGTH+1)*(size wchar)			>
	mov	cx, mask HF_SWAPABLE or \
		(mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8
	mov	bx, handle 0
	call	MemAllocSetOwner	; bx=block,ax=seg,cx destroyed
	jc	allocError

	;
	; Copy the string to the block
	;
	call	LocalStringSize		; cx = size of string
SBCS <	cmp	cx, MAX_WORD_LENGTH					>
DBCS <	cmp	cx, (MAX_WORD_LENGTH)*(size wchar)			>
LONG	jg	tooLong			; if string too long, truncate and ret
lengthOK:
	lds	si, wordToHyphenate	; ds:si -> word
	segmov	es, ax			; es:di -> mem block
	clr	di
	rep	movsb			; copy string to mem block

	mov	cx, ax			; cx = mem block
	mov	dx, bx			; ^hdx = mem block
	pop	es,ds,si,bx,di,ax	; all other params unchanged

	;
	; Borrow space on the stack
	;
	push 	di
	mov	di, 1000
	call	ThreadBorrowStackSpace

	;
	; If hyphen hasn't been opened yet, do it now.
	;
	push	ax
	mov	ax, segment udata
	mov	es, ax
	pop	ax
	tst	es:[hyphenOpened]
	jnz	initialized
	push	ax
	call	HyphenOpen
	pop	ax

initialized:
	;
	; If the database wasn't opened successfully, don't hyphenate
	;
	tst	es:[hyphenStatus]
	jnz	noHyphenate
	call	HyphenateDoWork		; return values set

exit:
	;
	; Return our borrowed stack space
	;
	call	ThreadReturnStackSpace
	pop	di
	
	;
	; Free the word block
	;
	mov	bx, dx			; bx = handle to word mem block
	call	MemFree	

quickExit:
	.leave
	ret

tooLong:
SBCS <	mov 	cx, MAX_WORD_LENGTH	; set to max length		>
DBCS <	mov 	cx, (MAX_WORD_LENGTH)*(size wchar)			>
	jmp	lengthOK

allocError:
	pop	es,ds,si,di,bx,ax
	clr	ax
	jmp	quickExit

noHyphenate:
	clr	ax
	jmp	exit
Hyphenate	endp

SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyphenateDoWork
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


SYNOPSIS:	Takes a null-term string and returns a byte array of 
		hyphenation points for the first word in the string. 

CALLED BY:	Library/Text/TextLine/tlHyphenation.asm/...
		ChooseHyphenationPosition (GLOBAL)

PASS:		cx    = string block
		^hdx  = string block
		ax    = length of shortest word to hyphenate

RETURN:		^hax  = global memhandle to HyphenationPoints structure

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/27/92    	Initial version


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyphenateDoWork		proc	near
	uses	bx, cx, dx, bp, di, si, es, ds

	convertedWord		local	MAX_WORD_LENGTH dup(char)
	minWordLength		local	word
	wordLength		local	word

	.enter

	;
	; Set the semaphore
	;
	push	ax
	mov	ax, segment dgroup
	mov 	es, ax
	mov	bx, es:[hyphenSem]
	call	ThreadPSem
	pop	ax

	;
	; Make sure min word length is at least the minimum value 
	;
	cmp	ax, MIN_WORD_LENGTH
LONG	jl	setAXtoSmallestMinWordLength

minLengthSet:
	;
	; Store the min word length
	;
	mov	minWordLength, ax

	call	HyphenSetPath			; set the directory path

	;
	; Pre-process the string
	;
	call	GetOneWord			; bx= length
	mov	wordLength, bx

if DBCS_PCGEOS
	;
	; convert word to SBCS
	;
	push	cx, ds, es, si, di		; save segment
	mov	ds, cx				; ds = word segment
	mov	es, cx				; es = word segment
	clr	si, di
	mov	cx, bx				; cx = length
convLoop:
	lodsw
	stosb
	loop	convLoop
	pop	cx, ds, es, si, di
endif

	;
	; Don't bother hyphenating if string isn't long enough
	;
	cmp	bx, minWordLength	; if word too short, return 0 hypmap
LONG	jl	dontHyphenate

	;
	; Call SLcnv to convert word to DEC character set
	;
	push 	cx				; push ptr-> word
	push	dx

	inc	bx				; length w/null term
	push	bx				; length of word

	push	ss				; converted word buffer
	lea	ax, convertedWord
	push	ax
	
	mov	ax, PC_TO_DEC			; direction to convert
	push	ax

	;call	SLcnv

	;
	; Set up the parameters to call IHhyp() - lock the IHBuff
	;
	mov	ax, segment udata
	mov	es, ax
	mov	bx, es:[anIHBuffHandle]
	call	MemLock				; ax = IHBuff segment
	mov	es, ax				; es:0 -> IHBuff

	;
	; Push parameters to IHhyp (in reverse order)
	;
	push	ss				; push ptr-> converted word
	lea	ax, convertedWord
	push	ax

	mov	es:task, HYPHENATE
	push	es				; push ptr->anIHBuff
	clr	ax
	push	ax

	;call	IHhyp				; ax = success/fail
	tst	ax				;
	jnz	errorExit

	;
	; Allocate the hyphenation point array
	;
	mov	ax, MAX_HYPHENATION_POINTS + size HyphenationPoints
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK or mask HAF_NO_ERR) \
			shl 8) or mask HF_SWAPABLE
	mov	bx, handle 0
	call	MemAllocSetOwner	; bx=block,ax=seg,cx destroyed
	jc	dontHyphenate
	push	bx

	push	ds
	mov	ds, ax
	mov	cx, wordLength
	mov	ds:[HP_wordLen], cx
	pop	ds
	;
	; Now for every bit set in anIHBuff.hypmap, save its location in
	; the array we just created, and null terminate the array when done
	;
	mov	cx, es
	lea	dx, es:hypmap
	call	DwordsToWords		; set up the hypmap the way we want
	call	BitsToBytes	

	;
	; Unlock the array block, and restore the directory path
	;
	pop	bx
	call	MemUnlock
	mov_tr	ax, bx

afterHyphenate:
	;
	; Unlock the IHBuff block
	;
	push	bx
	mov	cx, segment udata
	mov	es, cx
	mov	bx, es:[anIHBuffHandle]
	call	MemUnlock
	pop	bx

exit:

	call	FILEPOPDIR		; restore the directory path

	;
	; Unset the semaphore
	;
	push	ax
	mov	ax, segment dgroup
	mov 	es, ax
	mov	bx, es:[hyphenSem]
	call	ThreadVSem
	pop	ax
	
	.leave
	ret

setAXtoSmallestMinWordLength:
	mov 	ax, MIN_WORD_LENGTH
	jmp	minLengthSet

dontHyphenate:
	clr	ax
	jmp	exit

errorExit:
	clr	ax
	jmp 	afterHyphenate
HyphenateDoWork		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyphenClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shuts down the hyphenator, frees up memory, etcetera.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax = 0 if successful, nonzero if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/27/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyphenClose	proc	far
	uses	bx,cx,dx,di,es
	
	.enter

	call	HyphenSetPath		; set the path

	;
	; If the database wasn't opened successfully, don't close it.
	;
	mov	ax, segment udata
	mov	es, ax
	tst	es:[hyphenStatus]
	jz	noClose
	;
	; If the database was never opened, don't close it
	;
	tst	es:[hyphenOpened]
	jz	noClose

	;
	; Lock the IHBuff block
	;
	mov	bx, es:[anIHBuffHandle]
	call	MemLock				; ax = IHBuff segment
	mov	es, ax				; es:0 -> IHBuff

	;
	; Call IHhyp to close the database
	;
FXIP <	clr	di				; making null string	>
FXIP <	push	di							>
FXIP <	mov	di, sp				; ss:di = ptr to null	>
FXIP <	pushdw	ssdi				; ptr to null		>
NOFXIP<	push	cs						>
NOFXIP<	mov	di, offset nullString				>
NOFXIP<	push	di						>

	mov	es:task, TERMINATE
	push	es
	clr	ax
	push	ax

	;call	IHhyp				; ax = success/fail indicator
FXIP <	pop	di						>
	;
	; Free the IHBuff block
	;
	mov	cx, segment udata
	mov	es, cx
	mov	bx, es:[anIHBuffHandle]
	call	MemFree

noClose:
	;
	; Mark that hyphenation is no longer opened.
	;
	mov	cx, segment udata
	mov	es, cx
	clr	es:[hyphenOpened]
	call 	FILEPOPDIR			; restore the directory path

	.leave
	ret
HyphenClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitsToBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes an 8 byte (64 bit) number and returns an array of 
		(byte) integers of the positions of each set bit. 

CALLED BY:	Hyphenate
PASS:		ax:0 = ptr to HyphenationPoints structure array 
				(64 words in size)
		cx:dx = 64 bit number
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/27/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitsToBytes	proc	near
	uses	ax,bx,cx,dx,si,di,bp,es,ds
	.enter

	;
	; Go through the bitmask word by word. Whenever a set bit is located,
	; add the position of the bit to the array.
	;
	mov	ds, ax			; ds:si -> array
	mov	si, offset HP_array
	segmov	es, cx, bx		; es:di -> 4-word bitmask
	mov	di, dx
	mov	cx, 4			; cx = number of words to check
	clr	dx			; dx = position of current bit
	mov	bp, 1			; bp = bitmask
wordLoop:
	mov	bx, es:[di]		; bx = next word
bitLoop:
	ror	bp, 1			; rotate the set bit one to the right
	cmp	bp, 1			; when it's back to 1, done with word
	je	endBitLoop
	inc	dx
	push	bx
	and	bx, bp			; bx=0 unless same bit as in bp is set
	tst	bx			; test the next bit (moving right)
	pop	bx
	jz	bitLoop			; if nonzero, go to next
	mov	ds:[si], dl		; else put the position in next cell
	inc	si
	jmp 	bitLoop
endBitLoop:	
	add	di, 2			; to get next word at es:di
	dec	cx
	jnz	wordLoop
	.leave
	ret
BitsToBytes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DwordToWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Splits two dword values into correctly-ordered bytes.

CALLED BY:	BitsToBytes
PASS:		cx:dx -> two dword bitmap
RETURN:		cx:dx -> 4 ordered word bitmap
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/ 3/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DwordsToWords	proc	near
	uses	es,di,ax,bx
	.enter
	mov	es, cx			; es:di -> 2 dword bitmap
	mov	di, dx
	mov	bx, es:[di]		; bx = high word of first dword
	mov	ax, es:[di+2]		; ax = low word of first dword
	mov	es:[di], ax		; first word gets low word
	mov	es:[di+2], bx		; second word gets high word
	mov	bx, es:[di+4]		; bx = high word of second dword
	mov	ax, es:[di+6]		; ax = low word of second dword
	mov	es:[di+4],ax		; third word gets low word
	mov	es:[di+6],bx		; fourth word gets high word
	.leave
	ret
DwordsToWords	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOneWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes any leading delimiters (spaces, etc) and null 
		terminates the string at the first delimiter past the 
		first word.

CALLED BY:	Hyphenate
PASS:		cx = ptr to block of text
RETURN:		cx:dx = fptr to word (cx unchanged)
		bx = length of the word (not including terminator)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/ 6/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetOneWord	proc	near
	uses	ax,di,es
	.enter

	;
	; Get text length
	;
	mov	es, cx			; es:di -> string
	clr	di
SBCS <	call	LocalStringSize		; cx = length of string		>
DBCS <	call	LocalStringLength	; cx = length of string		>
	LocalPrevChar	esdi		; es:di -> one char before string

	;
	; Loop until non alpha character is found (or end of string)
	;
SBCS <	clr	ah							>
endWordLoop:
	LocalNextChar	esdi		; es:di -> next char
	jcxz	endWordLoopEnd		; if end of text, exit
	dec	cx
SBCS <	mov	al, es:[di]						>
DBCS <	mov	ax, es:[di]						>
	call 	LocalIsAlpha
	jnz	endWordLoop		; loop again if was alpha char
endWordLoopEnd:

	;
	; es:di -> one past last char in word. Change to null terminator.
	;
	clr	ax
SBCS <	mov	es:[di], al						>
DBCS <	mov	es:[di], ax						>

	;
	; Now get the length of the string, set return values
	;
	clr	di			; es:di -> string
SBCS <	call	LocalStringSize		; cx = size			>
DBCS <	call	LocalStringLength	; cx = size			>
	mov	bx, cx			; bx = size to return
	mov	cx, es			; cx = unchanged return
	clr	dx			; cx:dx -> string

	.leave
	ret
GetOneWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyphenSetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the directory for the hyphenation database

CALLED BY:	local
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/10/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyphenSetPath	proc	near
	uses	ax, bx, ds, dx
	.enter
	;
	; Set the directory path to find the db file, FILENAME in pubdata
	;
	call	FILEPUSHDIR
	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs, dx
	mov	dx, offset hyphenPathName
	call	FileSetCurrentPath	

	.leave
	ret
HyphenSetPath	endp


HyphenCode ends









