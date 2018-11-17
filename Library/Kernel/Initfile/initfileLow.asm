COMMENT @--------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Kernel/Initfile
FILE:		initfileLow.asm

AUTHOR:		Cheng, 11/89

ROUTINES:
	Name			Description
	----			-----------
Read:
    INT LoadVarSegDS_PInitFile

    INT VInitFile		Release the thread lock for the init file

    INT CorruptedIniFileError	Shuts down the system and whines about the
				corrupted .ini file

    INT EnterInitfile		Start access to Initfile code.

    INT ExitInitfile		Finish processing the initialization file

    INT ExitInitfileGet		Finish processing the initialization file

    INT EnterInitfileAndFindKey Call EnterInitfile, then find the given
				category and key in any .ini file along the
				path.

    INT FindCategory		Locates the given category.

    INT FindKey			Sets the file position at the first body
				position if the key exists.  Search halts
				when an EOF is encountered or when a new
				category is started.

    INT GetBodySize		Returns the size of the current body. The
				original buffer position is also returned
				in case the caller wishes to restore it.

    INT SkipWhiteSpace		Return the next relevant character. White
				space and carraige returns are skipped.

    INT SkipToEndOfLine		Skip to end of line.

    INT FindCharFar		Searches the file buffer for the given
				unescaped, uncommented character.

    INT FindChar		Searches the file buffer for the given
				unescaped, uncommented character.

    INT GetCharFar		Fetch the next character from the file
				buffer.

    INT GetChar			Fetch the next character from the file
				buffer.

    INT CmpString		Compares the given string with the string
				at the current init file buffer location.
				The comparison is case-insensitive and
				white space is ignored.

    INT LegalCmpChar		Sets the carry flag based on whether or not
				the given character can be used for
				comparison.  Since we are ignoring white
				space, the carry bit is set if the
				character is a space or tab. The routine
				has the side effect of transforming all
				alphabet chars into upper case since
				comparison is case-insensitive.

    INT GetStringLength		Return the length of the given string.

    INT AsciiToHex		Converts the ASCII number at the current
				init file buffer position to its binary
				equivalent.

    INT IsNumeric		Boolean routine that tells if argument is a
				numeric ASCII character.

    INT GetStringSectionByIndex Return ptr to and length of specified
				string section. String section is run of
				alpha numeric chars

    INT GetStringSectionPtr	Return ptr to string section. String
				section is next contiguous set of
				acceptable chars

    INT ScanStringForCharType	Scan a string until call back routine says
				to stop or end of string buffer has been
				reached

    INT IsPrintableAsciiChar?	Determines if character is acceptable in a
				printer name

    INT IsUnprintableAsciiChar? Determines if character is acceptable in a
				printer name

Write:
    INT ValidateIniFileFar	Scans the passed buffer for non-ascii
				characters.

    INT ValidateIniFile		Scans the passed buffer for non-ascii
				characters.

    INT DeleteEntry		Deletes the current entry by shifting the
				next entry over it.  Updates the internal
				size of the file.

    INT CreateCategory		Inserts the category into the init file
				buffer at the current location.

    INT MakeSpace		Extends the init file buffer to fit the
				string construction buffer.  Updates the
				internal size of the file.

    INT Hex16ToAscii		Converts a hex word to its ASCII
				representation without leading zeros.

    INT Hex8ToAscii		Converts a hex byte to its ASCII
				representation (two hex digits)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial revision

DESCRIPTION:
		
	$Id: initfileLow.asm,v 1.1 97/04/05 01:18:00 newdeal Exp $

----------------------------------------------------------------------------@

CATEGORY_NOT_CACHED	equ	0
CATEGORY_NOT_PRESENT	equ	-1

InitfileRead	segment	resource

LoadVarSegDS_PInitFile	proc	far
	uses	ax, bx
	.enter
	LoadVarSeg	ds, ax
	LockModule	ds:[currentThread], ds, [initFileSem], TRASH_AX_BX
	.leave
	ret
LoadVarSegDS_PInitFile	endp


VInitFile	proc	near
EC <	pushf								>
EC <	call	IFCheckDgroupDS						>
EC <	popf								>
	UnlockModule	ds:[currentThread], ds, [initFileSem]
	ret
VInitFile	endp

VInitFileWrite	proc	far
		call	VInitFile
		ret
VInitFileWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CorruptedIniFileError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shuts down the system and whines about the corrupted .ini file

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		doesn't return

DESTROYED:	
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CorruptedIniFileError	proc	far
	LoadVarSeg	ds
	call	VInitFile

if	ERROR_CHECK
	ERROR	CORRUPTED_INI_FILE					
else
ifdef GPC
	mov	al, KS_TE_SYSTEM_ERROR
	call	AddStringAtMessageBufferFar
	mov	al, KS_CORRUPTED_INI_BUFFER
	call	AddStringAtESDIFar
	mov	si, offset messageBuffer
	clr	di
else
	mov	bx, handle corruptedIniBufferStringOne
	call	MemLock
	mov	ds, ax
	assume	ds:segment corruptedIniBufferStringOne
	mov	si, ds:[corruptedIniBufferStringOne]
	mov	di, ds:[corruptedIniBufferStringTwo]
endif
	mov	ax, mask SNF_EXIT
	call	SysNotify
	mov	si, -1
	mov	ax, SST_DIRTY
	GOTO	SysShutdown
	assume	ds:dgroup

	.unreached
endif
CorruptedIniFileError	endp

if ERROR_CHECK and DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckASCIIString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the passed string is valid ASCII

CALLED BY:	EnterInitfile()
PASS:		ds:si - NULL-terminated ASCII string (SBCS)
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckASCIIString		proc	near
		uses	ax, cx, si
		.enter

		pushf

		clr	cx
charLoop:
		lodsb				;al <- character
		tst	al			;reached NULL?
		jz	doneChars		;branch if reached NULL
		cmp	al, 0x80		;too large for ASCII?
		jae	annoyMe			;branch if too large for ASCII
		inc	cx
		jmp	charLoop
doneChars:
		cmp	cx, 1			;long enough?
		ja	stringOK		;branch if so
annoyMe:
		WARNING	BAD_INI_STRING
stringOK:
		popf

		.leave
		ret
CheckASCIIString		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnterInitfile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start access to Initfile code.

CALLED BY:	EnterInitfileAndFindKey

PASS:		ds:si	- category ASCIIZ string
		cx:dx	- key ASCIIZ string
		es:di	- address of buffer/string
		bp	- InitFileReadFlags

RETURN:		all parameters stored away in variables
		initFileSem grabbed
		buffer locked with segment stored in initFileBufSegAddr
		es, bp - dgroup
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnterInitfile	proc	far	uses cx, di
		.enter

if DBCS_PCGEOS
EC <		call	CheckASCIIString				>
EC <		pushdw	dssi						>
EC <		movdw	dssi, cxdx
EC <		call	CheckASCIIString				>
EC <		popdw	dssi						>
endif
	;
	; Gain exclusive access to the file first.
	;
		push	ds
		call	LoadVarSegDS_PInitFile
	;
	; Now store the passed-in parameters in their respective variables.
	;
		mov	ds:[catStrAddr.offset], si
		pop	ds:[catStrAddr.segment]
		mov	ds:[keyStrAddr.offset], dx
		mov	ds:[keyStrAddr.segment], cx
		mov	ds:[bufAddr.offset], di
		mov	ds:[bufAddr.segment], es
		mov	ds:[bufFlag], bp
	;
	; Perform common processing on the given strings
	;
		les	di, ds:[catStrAddr]
		call	GetStringLength
EC <		cmp	cx, MAX_INITFILE_CATEGORY_LENGTH		>
EC <		ERROR_AE INIT_FILE_CATEGORY_STRING_TOO_LONG		>
		mov	ds:[catStrLen], cx
		
		les	di, ds:[keyStrAddr]
		call	GetStringLength
		mov	ds:[keyStrLen], cx
	;
	; Lock down the buffer and save its (new) segment.
	;
		mov	bx, ds:[loaderVars].KLV_initFileBufHan
		call	MemLock
		mov	ds:[initFileBufSegAddr], ax
if HASH_INIFILE
	;
	; Signal that we're starting with the first ini file.  This
	; is for the hash table.
	;
		clr	ds:[currentIniOffset]
endif		; HASH_INIFILE

if	ERROR_CHECK
		push	ds
		call	CheckNormalECEnabled
		jz	30$
		mov	cx, ds:[loaderVars].KLV_initFileSize
		dec	cx
		;Check out ini file buffer
		mov	ds, ax
		call	ValidateIniFile
		jnc	30$			;Branch if no error
 		GOTO	CorruptedIniFileError
30$:
		pop	ds
endif
	;
	; Recover ds in case caller needs it, but put dgroup into bp and es for
	; ease of use.
	;
		mov	bp, ds
		mov	es, bp
		mov	ds, ds:[catStrAddr.segment]
		.leave
		ret
EnterInitfile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitInitfile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish processing the initialization file

CALLED BY:	All access routines
PASS:		nothing
RETURN:		buffer unlocked
		initFileSem released
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExitInitfile	proc	far	uses bx, ds
		.enter
		pushf			; Save flags as well
	;
	; Release the buffer so it can move again.
	;
		segmov	ds,dgroup,bx
		mov	bx, ds:[loaderVars].KLV_initFileBufHan
		call	MemUnlock
EC <		mov	ds:[initFileBufSegAddr], 0xa000	; Point at video memory>
	;
	; Release exclusive access to file.
	;
		call	VInitFile
		popf
		.leave
		ret
ExitInitfile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitInitfileGet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish processing the initialization file

CALLED BY:	All access routines

PASS:		nothing

RETURN:		buffer unlocked
		initFileSem released

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExitInitfileGet	proc	near	uses bx, ds
		.enter
		pushf			; Save flags as well

		segmov	ds,dgroup,bx
	;
	; If there is more than one .ini file then clear curCatOffset
	; (cached offset to current category)
	;
		tst	ds:[loaderVars].KLV_initFileBufHan[2]
		jz	noClearCache
		mov	ds:[curCatOffset], CATEGORY_NOT_CACHED
noClearCache:
	;
	; Release the buffer so it can move again.
	;
		mov	bx, ds:[initFileHanLocked]
		tst	bx
		jz	noUnlock
		call	MemUnlock
noUnlock:
EC <		mov	ds:[initFileBufSegAddr], 0xa000	; Point at video memory>
	;
	; Release exclusive access to file.
	;
		call	VInitFile
		popf
		.leave
		ret
ExitInitfileGet	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	EnterInitfileAndFindKey

DESCRIPTION:	Call EnterInitfile, then find the given category and key in
		any .ini file along the path.

CALLED BY:	InitFileReadInteger, InitFileReadBoolean,
		InitFileReadString, InitFileRead

PASS:
	ds:si - category ASCIIZ string
	cx:dx - key ASCIIZ string
	bp - InitFileReadFlags

RETURN:
	carry - set if error (category or key not found)
	all parameters stored away in variables
	initFileSem grabbed
	es, bp - dgroup
	initFileHanLocked - handle of buffer locked (0 if error)
	if no error:
		buffer locked with segment stored in initFileBufSegAddr
		dgroup:[initFileBufPos] - offset from BufAddr to body

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

---------------------------------------------------------------------------@

EnterInitfileAndFindKey	proc	near	uses ax, bx
	.enter

	call	EnterInitfile		;locks first .ini file
	mov	es:[initFileHanLocked], 0
	mov	bx, offset loaderVars.KLV_initFileBufHan
searchLoop:
	call	FindCategory
	jc	notFound
	call	FindKey
	jnc	doneGood
notFound:
	;
	; category or key not found in .ini file, progress down the
	; path, unless the caller doesn't want us to.
	;
	push	bx
	mov	bx, es:[bx]
	call	MemUnlock			;unlock old buffer
	pop	bx

	test	es:[bufFlag], mask IFRF_FIRST_ONLY
	jnz	error

	; get handle of next .ini file in the path

	add	bx, size word
	
	cmp	bx, (offset loaderVars.KLV_initFileBufHan)+ \
						((size word)*MAX_INI_FILES)
	je	error
	cmp	{word} es:[bx], 0
	je	error

if HASH_INIFILE
	add	es:[currentIniOffset], size word	
endif		; HASH_INIFILE

	push	bx
	mov	bx, es:[bx]
	call	MemLock
	pop	bx
	mov	es:[initFileBufSegAddr], ax
	mov	es:[curCatOffset], CATEGORY_NOT_CACHED
	jmp	searchLoop

error:
	stc
	jmp	done

doneGood:
	cmp	bx, offset loaderVars.KLV_initFileBufHan
	je	10$
	mov	es:[curCatOffset], CATEGORY_NOT_CACHED
10$:
	mov	bx, es:[bx]
	mov	es:[initFileHanLocked], bx
done:
	.leave
	ret

EnterInitfileAndFindKey	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextInitFileAndFindKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock this init file, and lock the next one

CALLED BY:	InitFileReadAll

PASS:		es - dgroup
		ds:si - category string
		cx:dx - key string

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Unlock the current initfile buffer, find the next one, and
	lock it. Search for the passed category/key.  If it's not in
	that file, then go to the next one

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextInitFileAndFindKey	proc near

		uses	ax,bx,cx,dx,di,si,bp
		
		.enter

nextInitFile:
		clr	bx
		xchg	bx, es:[initFileHanLocked]
		call	MemUnlock
		mov_tr	ax, bx
		mov	bx, offset loaderVars.KLV_initFileBufHan

	;
	; Find the currently locked init file
	;
		
searchLoop:
		cmp	es:[bx], ax
		lea	bx, es:[bx][size word]
		jne	searchLoop
		
	;
	; Now, lock the next one if such there be
	;
		
		cmp	bx, (offset loaderVars.KLV_initFileBufHan)+ \
					((size word)*MAX_INI_FILES)
		jae	notFound
		
		mov	bx, es:[bx]
		tst	bx
		jz	notFound
if HASH_INIFILE
		add	es:[currentIniOffset], size word
endif ;
		
		call	MemLock

		mov	es:[initFileBufSegAddr], ax
		mov	es:[curCatOffset], CATEGORY_NOT_CACHED
		mov	es:[initFileHanLocked], bx

		mov	bp, es
		call	FindCategory
		jc	nextInitFile

		call	FindKey
		jc	nextInitFile
done:
		.leave
		ret

notFound:
		stc
		jmp	done
	
GetNextInitFileAndFindKey	endp




COMMENT @--------------------------------------------------------------------

FUNCTION:	FindCategory

DESCRIPTION:	Locates the given category.

CALLED BY:	INTERNAL (InitFileWrite, InitFileGet, InitFileReadInteger)

PASS:		es, bp - dgroup
		dgroup:[catStrAddr] - category ASCIIZ string
		dgroup:[catStrOffset]
		dgroup:[catStrLen]

RETURN:		IF CATEGORY FOUND:
			CARRY CLEAR
		    	dgroup:[initFileBufPos] - offset from
				BufAddr to character after ']'
		ELSE
			CARRY SET
			initFileBufPos - destroyed

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version
	CDB	4/29/92		added comments. Fixed a bug.
----------------------------------------------------------------------------@

FindCategory	proc	far


		
EC <	call	IFCheckDgroupRegs					>
	push	ax,bx,cx,si,di,ds
if HASH_INIFILE
	tst	es:[hashTableBlkHandle]
	jz	slowWay	
	call	HashFindCategory
	jmp	exit
slowWay:
endif	; HASH_INIFILE
	lds	si, es:[catStrAddr]

EC <	cmp	{char} ds:[si], 0					>
EC <	ERROR_Z	INIT_FILE_NULL_CATEGORY_PASSED				>

	; See if we're looking at the cached category.  If no category
	; cached, then cache the passed category.
	mov	ax, es:[curCatOffset]
.assert	CATEGORY_NOT_CACHED	eq	0
	tst	ax			; cmp ax, CATEGORY_NOT_CACHED
	jz	cachePassedCategory

	; Now, compare the passed category with the cached category.
	; If not the same, then cache the new one.

	push	si
	lea	di, curCategory		; es:di - cached category
	mov	cx, es:catStrLen
	inc	cx
	repe	cmpsb
	pop	si
	jne	cachePassedCategory

	; They're equal.  If the category isn't present, then set
	; carry and exit.

	cmp	ax, CATEGORY_NOT_PRESENT
	stc
	je	exit

	; if category IS present, then set buffer position

	mov	es:[initFileBufPos], ax
	clc
	jmp	exit

cachePassedCategory:
	push	si
	lea	di, curCategory
	mov	cx, es:catStrLen
	inc	cx
	rep	movsb
	pop	si
	mov	es:[initFileBufPos], 0
	clr	bx			; not starting inside blob

findLoop:
	;--------------------------------------------------------------------
	;skip to next category

	mov	al, '['
	call	FindChar
	jc	notFound

	call	CmpString
	jc	findLoop

	call	SkipWhiteSpace
	call	GetChar
	jc	error
	cmp	al, ']'
	jne	findLoop
	mov	ax, es:[initFileBufPos]
	mov	es:[curCatOffset], ax
	clc
exit:
	pop	ax,bx,cx,si,di,ds
	ret
error:
	GOTO	CorruptedIniFileError

notFound:
	; Carry flag is set.
	mov	es:[curCatOffset], CATEGORY_NOT_PRESENT
	jmp	exit

FindCategory	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	FindKey

DESCRIPTION:	Sets the file position at the first body position if the key
		exists.  Search halts when an EOF is encountered or when a
		new category is started.

CALLED BY:	INTERNAL (InitFileWrite)

PASS:		es, bp - dgroup
		dgroup:[ketStrAddr] - key ASCIIZ string

RETURN:		carry clear if successful
		dgroup:[initFileBufPos] - offset from BufAddr to body

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	done <- false
	repeat
	    skip white space
	    if first char = ';' then
		line <- line + 1
	    else if key found then
		done <- true
	    else
		locate '='
		skip white space
		if char <> '{' then
		    line <- line + 1
		else
		    skip blob
		endif
	    endif
	until done


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@

FindKey		proc	far
EC<	call	IFCheckDgroupRegs					>

	push	ax,bx,cx,si,ds
	clr	bx			; assume not starting inside blob
findLoop:
	call	SkipWhiteSpace
	jc	goToExit
	call	GetChar
	jc	goToExit

	cmp	al, INIT_FILE_COMMENT
	je	processComment

	dec	es:[initFileBufPos]	;unget char
	cmp	al, '['			;new category?
	jne	checkKey
	stc
goToExit:
	jmp	exit			;done if so

checkKey:
	lds	si, es:[keyStrAddr]

	;Make sure that we were not passed a null keyword. Otherwise,
	;we would search for it and fail, and then create a null keyword
	;in the file, corrupting it. -EDS 10/14/92

EC <	cmp	{char} ds:[si], 0					>
EC <	ERROR_Z INIT_FILE_NULL_KEYWORD_PASSED				>

	mov	ax, es:[initFileBufPos]
	mov	es:[curKeyOffset], ax
	call	CmpString
	jc	noMatch

	call	SkipWhiteSpace
	jc	error
	call	GetChar
	jc	error
	cmp	al, '='
	jne	noMatch
	jmp	short keyFound
noMatch:
	mov	al, '='
	call	FindChar
	jc	error
	call	SkipWhiteSpace
	jc	error

	call	GetChar
	jc	error
	cmp	al, '{'			;blob?
	je	blobFound
	call	SkipToEndOfLine
	jmp	short findLoop

blobFound:
	;--------------------------------------------------------------------
	;skip blob

	mov	bx, TRUE		;now processing blob
	mov	al, '}'
	call	FindChar
EC<	ERROR_C	INIT_FILE_BAD_BLOB					>
EC<	tst	bx			;assert no longer in blob	>
EC<	ERROR_NZ INIT_FILE_BAD_BLOB					>
	jnc	findLoop						
error:
	GOTO	CorruptedIniFileError

processComment:
	call	SkipToEndOfLine
	jmp	findLoop

keyFound:
	call	SkipWhiteSpace
	clc
exit:
	pop	ax,bx,cx,si,ds
	ret
FindKey		endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	GetBodySize

DESCRIPTION:	Returns the size of the current body.
		The original buffer position is also returned in case
		the caller wishes to restore it.

CALLED BY:	INTERNAL (InitFileGet, DeleteEntry)

PASS:		es, bp - dgroup
		dgroup:[initFileBufPos] - offset to first char in body

RETURN:		ax - size of body
		cx - dgroup:[initFileBufPos] on entry
		dgroup:[initFileBufPos] - offset to char past entry terminator

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@

GetBodySize	proc	far	uses dx
	.enter
EC<	call	IFCheckDgroupRegs					>

	mov	cx, es:[initFileBufPos]

	call	GetChar
	jc	done
	cmp	al, '{'
	je	locateBlobEnd
	;
	; We allow whitespace in the entry, but we need to ignore comments
	; and trim off any trailing whitespace.
	;
	clr	dx		; no whitespace seen yet.
scanLoop:
	; comment? done if so
	cmp	al, INIT_FILE_COMMENT
	je	nonBlobComplete
	; whitespace? record pos if so
	cmp	al, ' '
	je	nonBlobWS
	cmp	al, C_TAB	; tab
	je	nonBlobWS
	; end-of-line? done if so
	cmp	al, '\r'
	je	nonBlobComplete
	cmp	al, '\n'
	je	nonBlobComplete
	clr	dx		; non-whitespace => no whitespace at end yet
next:
	call	GetChar
	jnc	scanLoop
nonBlobComplete:
	tst	dx		; trailing whitespace?
	jz	done		; nope
	clr	al		; signal not at EOF
	mov	es:[initFileBufPos], dx	; Backup to start of end
	jmp	done
nonBlobWS:
	tst	dx
	jne	next
	mov	dx, es:[initFileBufPos]	; record current position -- dec
					; in nonBlobComplete handles backing
					; up to actual position of char.
	jmp	next
locateBlobEnd:
	push	bx
	mov	bx, TRUE		;now processing blob
	mov	al, '}'			;look for matching curly-brace
	call	FindChar
	pop	bx
	jc	closeNotFound
	mov	ax, es:[initFileBufPos]
	sub	ax, cx			;size from '{' to '}', inclusive
	sub	ax, 2			;don't count '{' and '}'
	jmp	short exit

closeNotFound:
	GOTO	CorruptedIniFileError

done:
	;
	; If al is ^Z here, it means we hit the end of the file w/o hitting
	; a return or linefeed, so we need to include all the chars up to
	; initFileBufPos (which won't advance beyond the ^Z). In the normal
	; case (a blob or a return-terminated string), we want to not include
	; the final character.
	; 
	cmp	al, MSDOS_TEXT_FILE_EOF
	je	figureSize		; (carry clear)
ignoreChar::
	stc				; perform extra decrement to ignore
					;  char before initFileBufPos
figureSize:
	mov	ax, es:[initFileBufPos]
	sbb	ax, cx			;ax <- size of body
exit:
	.leave
	ret
GetBodySize	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	SkipWhiteSpace

DESCRIPTION:	Return the next relevant character. White space and
		carraige returns are skipped.

CALLED BY:	INTERNAL (FindKey)

PASS:		es, bp - dgroup

RETURN:		dgroup:[initFileBufPos] updated, next call to GetChar
			will retrieve non white space character

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@

SkipWhiteSpace	proc	near	uses	si, ds
	.enter
EC<	call	IFCheckDgroupRegs					>

	lds	si, es:[initFileBufPos]		;get current pos in ds:si

skipLoop:
	lodsb
SBCS <	cmp	al, VC_BLANK						>
DBCS <	cmp	al, C_SPACE						>
	je	skipLoop		;next if blank
SBCS <	cmp	al, VC_TAB						>
DBCS <	cmp	al, C_TAB						>
	je	skipLoop		;next if tab
SBCS <	cmp	al, VC_ENTER						>
DBCS <	cmp	al, C_ENTER						>
	je	skipLoop		;next if carraige return
SBCS <	cmp	al, VC_LF						>
DBCS <	cmp	al, C_LINEFEED						>
	je	skipLoop		;next if line feed
	dec	si			; unget char
	cmp	al, MSDOS_TEXT_FILE_EOF	;Clears carry if they are equal
	stc
	jz	exit
	clc				;Clear the carry...
exit:
	mov	es:[initFileBufPos], si		; store back new position
	.leave
	ret

SkipWhiteSpace	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	SkipToEndOfLine

DESCRIPTION:	Skip to end of line.

CALLED BY:	INTERNAL (FindKey)

PASS:		es, bp - dgroup

RETURN:		carry clear if ok

DESTROYED:	al

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@

SkipToEndOfLine	proc	near
EC<	call	IFCheckDgroupRegs					>

	mov	al, '\n'		;locate a carraige return
	call	FindChar
	ret
SkipToEndOfLine	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	FindChar

DESCRIPTION:	Searches the file buffer for the given unescaped,
		uncommented character.

CALLED BY:	INTERNAL (SkipToNextCategory, FindKey, SkipBlob,
			  SkipToEndOfLine)

PASS:		es, bp - dgroup
		al - character to locate
		     NOTE:  MUST MATCH STORED CHARACTER EXACTLY.
		     This routine no longer upcases/downcases chars before doing
		     comparison.  This should be OK as this routine is only
		     be called for the chars '[', '=', '}' and EOLN. -- Doug
		bx - flag indicating if [initFileBufPos] is pointing to a blob
		     (any char immediately following '{', or prior to or at '}')

RETURN:		carry clear if found
		dgroup:[initFileBufPos] updated to byte past char
		ie. a call to GetChar will fetch the next char
		bx - blob flag updated to reflect new position

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	unfortunately, the speed of the 8086 scas instructions cannot 
	be taken advantage of

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version
	Doug	8/90		Optimized for speed
	dhunter	6/6/2000	Added special non-blob escape handling

----------------------------------------------------------------------------@

FindCharFar	proc	far
	call	FindChar
	ret
FindCharFar	endp

FindChar	proc	near	uses	ax, si, ds
	.enter
EC<	call	IFCheckDgroupRegs					>

	mov	ah, al
	lds	si, es:[initFileBufPos]		;get cur pos in ds:si

findCharLoop:
	lodsb
	cmp	al, MSDOS_TEXT_FILE_EOF
	je	eof
checkEscaped:
	cmp	al, '\\'
	je	escapedChar
notEscaped:
	cmp	al, INIT_FILE_COMMENT
	je	commentChar
	cmp	al, '{'				;found start of blob?
	je	blobStart
	cmp	al, '}'				;found blob terminator?
	je	blobEnd
afterComment:
	cmp	ah, al
	jne	findCharLoop

	clc
exit:
	mov	es:[initFileBufPos], si		; store new offset back to var
	.leave
	ret

eof:
	dec	si				; back up to point at EOF
	stc					; return EOF found
	jmp	short exit

escapedChar:					; Escaped char hit...
	lodsb					; read in escaped char

	cmp	al, MSDOS_TEXT_FILE_EOF
	je	eof

	tst	bx				; Reading in blob?
	jnz	findCharLoop			; nope, continue w/NEXT char
;
;	Only certain chars are escaped outside of a blob, and the backslash
;	is not one of them.  If we don't find one of those chars, that
;	means the '\\' was not really an escape and we should not skip the
;	next char. -dhunter 6/6/2000
;
	cmp	al, '{'				; '{' is always escaped
	je	findCharLoop			; found, goto next
	cmp	al, '['				; '[' is always escaped
	je	findCharLoop			; found, goto next
	jmp	short checkEscaped		; otherwise, it was just '\\'

commentChar:					; Comment char hit...
	lodsb					; read through EOLN,
	cmp	al, MSDOS_TEXT_FILE_EOF
	je	eof
	cmp	al, '\n'
	jne	commentChar
	jmp	short afterComment		; continue with EOLN itself

blobStart:
	mov	bx, TRUE			;now in blob.
	jmp	short afterComment
blobEnd:
	clr	bx				;no longer in blob.
	jmp	short afterComment

FindChar	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	GetChar

DESCRIPTION:	Fetch the next character from the file buffer.

CALLED BY:	INTERNAL (SkipBlob, SkipWhiteSpace)

PASS:		es, bp - dgroup

RETURN:		carry clear if successful
		    al - next character
		    dgroup:[initFileBufPos] updated
		carry set if end of file encountered
		    al - EOF 

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	buffer position is post incremented, ie. current value is offset
	to the next character

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version
	Cheng	4/90		Upcased all lowercase characters

----------------------------------------------------------------------------@

GetCharFar	proc	far
	call	GetChar
	ret
GetCharFar	endp

GetChar	proc	near
	uses	si
	.enter
EC<	call	IFCheckDgroupRegs					>

	les	si, es:[initFileBufPos]		;get cur pos
			;This can be done because the initFileBufSegAddr
			; directly follows initFileBufPos. These should
			; actually be one variable, but, hell, I didn't
			; write this stuff.		

	lodsb	es:				;fetch character
	mov	es, bp				;es <- dgroup

	cmp	al, MSDOS_TEXT_FILE_EOF
	stc
	je	exit

	mov	es:[initFileBufPos], si

	CheckHack <(IFCC_INTACT shl offset IFRF_CHAR_CONVERT) eq 0>
	CheckHack <(IFCC_UPCASE shl offset IFRF_CHAR_CONVERT) eq 0x4000>
	CheckHack <(IFCC_DOWNCASE shl offset IFRF_CHAR_CONVERT) eq 0x8000>

	test	es:[bufFlag], mask IFRF_CHAR_CONVERT
	jz	exit				; => IFCC_INTACT
	js	downcase			; => IFCC_DOWNCASE
;upcase:
	cmp	al, 'a'
	jb	ok
	cmp	al, 'z'
	ja	exit
	sub	al, 'a' - 'A'			;upcase all lowercase chars
	jmp	exit				; (subtraction cannot cause
						; borrow, since al is between
						; 'a' and 'z', so carry is clr)
ok:
	clc
	jmp	exit

downcase:
	cmp	al, 'A'
	jb	ok
	cmp	al, 'Z'
	ja	exit
	add	al, 'a' - 'A'			;upcase all lowercase chars
						; (addition cannot cause carry,
						;  so carry is clear)
exit:
	.leave
	ret
GetChar	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	CmpString

DESCRIPTION:	Compares the given string with the string at the
		current init file buffer location. The comparison is
		case-insensitive and white space is ignored.
		

CALLED BY:	INTERNAL ()

PASS:		ds:si - ASCIIZ string
		dgroup:[initFileBufPos] - current buffer position
		es, bp - dgroup

RETURN:		carry clear if strings 'match'
		initFileBufPos - positioned at next char after matched string

		set otherwise
		initFileBufPos - unchanged
DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

----------------------------------------------------------------------------@

CmpString	proc	near	uses ax, bx, si
	.enter
EC<	call	IFCheckDgroupRegs					>

;
;	The behavior here is a little tricky - we want to preserve the current
;	ini-file position if no match is found.
;

	mov	bx, es:[initFileBufPos]
fetchStr1:
	lodsb
	tst_clc	al
	je	exit		; carry cleared by "or" in tst

	call	LegalCmpChar	;can this char be used for comparison?
	jc	fetchStr1	;loop if not
	mov	ah, al		;save it in ah
fetchStr2:
	call	GetChar
	jc	noMatch
	call	LegalCmpChar	;can this char be used for comparison?
	jc	fetchStr2

	cmp	ah, al
	je	fetchStr1
noMatch:
	mov	es:[initFileBufPos],bx	;Restore initFile position
	stc			;signal chokage
exit:
	.leave
	ret
CmpString	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	LegalCmpChar

DESCRIPTION:	Sets the carry flag based on whether or not the given
		character can be used for comparison.  Since we are
		ignoring white space, the carry bit is set if the
		character is a space or tab. The routine has the side
		effect of transforming all alphabet chars into upper case
		since comparison is case-insensitive.

CALLED BY:	INTERNAL (CmpString)

PASS:		al - char

RETURN:		carry clear if character is cmp-able
			al - made uppercase if passed al was a lowercase letter
		carry set if character is white space

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

----------------------------------------------------------------------------@

LegalCmpChar	proc	near
	cmp	al, 'z'
	ja	legal

SBCS <	cmp	al, VC_BLANK						>
DBCS <	cmp	al, C_SPACE						>
	je	illegal

SBCS <	cmp	al, VC_TAB						>
DBCS <	cmp	al, C_TAB						>
	je	illegal
	
	cmp	al, 'a'
	jb	legal


	sub	al, 'a'-'A'
legal:
	clc
	ret
illegal:
	stc
	ret
LegalCmpChar	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	GetStringLength

DESCRIPTION:	Return the length of the given string.

CALLED BY:	INTERNAL (BuildEntryFromString)

PASS:		es:di - ASCIIZ string

RETURN:		cx - number of bytes in string (excluding null terminator)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@

GetStringLength	proc	near
	uses	di
	.enter

	mov	cx, -1
	clr	al
	repne	scasb
	not	cx
	dec	cx

	.leave
	ret
GetStringLength	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	AsciiToHex

DESCRIPTION:	Converts the ASCII number at the current init file buffer
		position to its binary equivalent.

CALLED BY:	INTERNAL (ReconstructData, InitFileReadInteger)

PASS:		es	- dgroup
		dgroup:[initFileBufPos] - offset to numeric entry

RETURN:		carry - set if no number parsed
		dx - binary equivalent
		al - terminating char

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	ASCII number must be less than 65536

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@

AsciiToHex	proc	near
	uses	bx, cx
	.enter

	mov	bx, 10
	clr	cx
	clr	dx			;found digit flag

convLoop:
	call	GetChar
	call	IsNumeric
	jc	done

	clr	ah
	sub	ax, '0'		;convert to digit
	xchg	ax, cx
	mul	bx		;dx:ax <- digit * 10
	add	ax, cx
	mov	cx, ax
	inc	dx
	jmp	short convLoop	;loop till done
done:
	tst	dx		;clears carry
	jnz	99$
	stc
99$:
	mov	dx, cx

	.leave
	ret
AsciiToHex	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	IsNumeric

DESCRIPTION:	Boolean routine that tells if argument is a numeric
		ASCII character.

CALLED BY:	INTERNAL (AsciiToHex)

PASS:		al - ASCII char

RETURN:		carry clear if numeric
		set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version
	Don	1/92		Optimized, I hope

----------------------------------------------------------------------------@

IsNumeric	proc	near
	cmp	al, '0'				; carry is already set correctly
	jb	done	
	cmp	al, '9'+ 1			; carry is clear fort above/eq
	cmc					; invert it, please
done:
	ret
IsNumeric	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStringSectionByIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return ptr to and length of specified string section.
		String section is run of alpha numeric chars

CALLED BY:	InitFileReadStringSection

PASS: 		ds:si	- ptr to begining of string
		dx	- 0 based string section number
		cx	- number of bytes in string

RETURN:		clc	- section found
		ds:si	- ptr to begining of string section
		cx	- number of chars in string section
		ax	- number of chars left in string
				- or -
		stc - error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 9/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetStringSectionByIndex		proc	far
	uses	bx, dx, di
	.enter

	; Loop until we're done
	;
next:
	call	GetStringSectionPtr
	tst	ax				;any string?
	stc					;assume the worst
	jz	done
	tst	dx				;section index
	jz	found				;carry is clear already
	stc					;assume the worst
	jcxz	done				;remaining chars
	dec	dx
	mov	si, di
	jmp	next
found:
	xchg	cx, ax				;string length => CX
done:						;remaining characters => AX
EC <	pushf							>
EC <	cmp	ax, 2048					>
EC <	ERROR_AE -1						>
EC <	popf							>

	.leave
	ret
GetStringSectionByIndex		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStringSectionPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return ptr to string section.
		String section is next contiguous set of acceptable chars

CALLED BY:	GetStringSectionByIndex

PASS:		
		ds:si - ptr into string buffer
		cx - remaining chars in string buffer including ds:si char
RETURN:		
		ax - length
		ds:si - ptr to first char of section
		ds:di - ptr to byte after last char of section
		cx - remaining chars in string buffer including ds:di char
		
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 9/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetStringSectionPtr		proc	near
	uses	dx
	.enter

	; Scan for first acceptable char
	;
	mov	bx, offset IsPrintableAsciiChar?
	call	ScanStringForCharType

	; Scan for first unacceptable char after acceptable char
	;
	mov	si, di				
	mov	bx, offset IsUnprintableAsciiChar?
	call	ScanStringForCharType

	.leave
	ret
GetStringSectionPtr		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanStringForCharType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan a string until call back routine says to stop
		or end of string buffer has been reached

CALLED BY:	InitFileGetStringSectionLengthPtr

PASS:		DS:SI	= Ptr into string buffer
		CX	= Remaining chars in string including current char
		BX	= Callback routine (near, of course)

RETURN:		DS:DI	= First rejected char or byte after end of buffer
		AX	= Length of accepted string
		CX	= Eemaining chars in string including current char

DESTROYED:	BX

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 9/90	Initial version
	don	 1/30/92	Used near callback routines, now

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanStringForCharType		proc	near
	uses	bp, si
	.enter

	mov	di, si
	jcxz	noChars
nextChar:
	LocalGetChar ax, dssi
	call	bx				; call callback routine
	jnc	stop
	loop	nextChar
	LocalNextChar dssi			; make up for dec si below
stop:
	LocalPrevChar dssi			; back to reject char

noChars:
	; Calc number of remaining chars and length
	;
	mov	ax, si
	sub	ax, di				; length
DBCS <	shr	ax, 1				; ax <- length		>
	mov	di, si

	.leave
	ret
ScanStringForCharType		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsPrintableAsciiChar?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if character is acceptable in a printer name

CALLED BY:	ScanStringForCharType()

PASS: 		al - char

RETURN:		clc - yes
		stc - no

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 9/90	Initial version
	don	1/21/92		Optimized, I hope

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsPrintableAsciiChar?		proc	near
SBCS <	cmp	al,C_SPACE			; sets the carry as desired >
DBCS <	cmp	ax,C_SPACE			; sets the carry as desired >
	ret
IsPrintableAsciiChar?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsUnprintableAsciiChar?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if character is acceptable in a printer name

CALLED BY:	ScanStringForCharType()

PASS: 		al - char

RETURN: 	clc - it is not a printer char
		stc - it is a printer char

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 9/90	Initial version
	don	1/21/92		Optimized, I hope

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsUnprintableAsciiChar?		proc	near
SBCS <	cmp	al,C_SPACE		; sets carry opposite of desire>
DBCS <	cmp	ax,C_SPACE		; sets carry opposite of desire>
	cmc
	ret
IsUnprintableAsciiChar?		endp

InitfileRead	ends



InitfileWrite	segment	resource


COMMENT @--------------------------------------------------------------------

FUNCTION:	DeleteEntry

DESCRIPTION:	Deletes the current entry by shifting the next entry
		over it.  Updates the internal size of the file.

CALLED BY:	INTERNAL (InitFileWrite)

PASS:		es, bp - dgroup
		dgroup:[initFileBufPos]
		dgroup:[initFileBufSegAddr]
		dgroup:[curKeyOffset]
		dgroup:[loaderVars].KLV_initFileSize

RETURN:		dgroup:[initFileBufPos] - offset to where key was
		dgroup:[loaderVars].KLV_initFileSize - reduced by size of entry

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@

DeleteEntry	proc	near
EC <	call	IFCheckDgroupRegs					>
	push	cx,di,si,ds
	call	GetBodySize		;ax,cx <- func(es,bp)
					;initFileBufPos points 1 past terminator
	lds	si, es:[initFileBufPos]
EC <	call	ECCheckBounds						>
	cmp	byte ptr ds:[si], '\r'
	jne	checkLF
	inc	si
checkLF:
	cmp	byte ptr ds:[si], '\n'
	jne	doDel
	inc	si
doDel:

	mov	di, es:[curKeyOffset]
	push	di

	mov	ax, si
	sub	ax, di			;ax <- size of entry

	mov	cx, es:[loaderVars].KLV_initFileSize
	sub	cx, si
	push	ds
	pop	es
	rep	movsb

	mov	es, bp			;es <- dgroup
	pop	es:[initFileBufPos]
	sub	es:[loaderVars].KLV_initFileSize, ax

if HASH_INIFILE
	mov	cx, ax
	neg	cx	
	call	HashUpdateHashTable
endif		; HASH_INIFILE
		
	pop	cx,di,si,ds
	ret
DeleteEntry	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	CreateCategory

DESCRIPTION:	Inserts the category into the init file buffer at the current
		location.

CALLED BY:	INTERNAL (InitFileWrite)

PASS:		es, bp - dgroup
		dgroup:[catStrAddr] - category ASCIIZ string
		dgroup:[initFileBufPos] - offset from buffer to insertion loc
			(new data will start at this location)

RETURN:		dgroup:[initFileBufSegAddr] - possibly changed
		dgroup:[loaderVars].KLV_initFileSize -
					increased by size of category + 2
		dgroup:[initFileBufPos] - 1 after terminating ']'

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	tack new category on to end of file
	body insertion pos = eof

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@

CreateCategory	proc	near
	uses	cx, di, si, ds
	.enter

if HASH_INIFILE
	;
	; Jump to the end of the file
	;
	mov	ax, es:[loaderVars].KLV_initFileSize	; size including EOF
	dec	ax					; offset of EOF
	mov	es:[initFileBufPos], ax
endif		;HASH_INIFILE

	; First make space for the new category name
	;
EC <	call	IFCheckDgroupRegs		>
	mov	cx, es:[catStrLen]
	push	cx
	add	cx, 4				; '[', ']', CR, LF
	call	MakeSpace			; func(es, cx), destroys ax, di
	pop	cx

	; Store the new category, and associate formatting bytes
	;
	lds	si, es:[catStrAddr]
	mov	di, es:[initFileBufPos]
	mov	es, es:[initFileBufSegAddr]	; destination -> es:di
	mov	al, '['
	stosb					; now write the open bracket

if HASH_INIFILE
	push	di				; remember this position
endif				; HASH_INIFILE

	rep	movsb				; now write the category name
	mov	al, ']'	
	stosb					; write the close bracket
SBCS <	mov	ax, (VC_LF shl 8) or VC_ENTER				>
DBCS <	mov	ax, (C_LINEFEED shl 8) or C_ENTER			>
	stosw					; finally, go to the next line

	; Store the current file position, and cache the category position
	;
	mov	es, bp
	mov	es:[initFileBufPos], di
	mov	es:[curCatOffset], di

if HASH_INIFILE
	pop	cx				; pointer to category name
	call	HashAddPrimaryEntry
endif			;HASH_INIFILE
		
	.leave
	ret
CreateCategory	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	MakeSpace

DESCRIPTION:	Extends the init file buffer to fit the string construction
		buffer.  Updates the internal size of the file.

CALLED BY:	INTERNAL (CreateCategory, InitFileWrite)

PASS:		es, bp - dgroup
		dgroup:[initFileBufPos] - offset from buffer to insertion loc
			(new data will start at this location)
		cx - size of entry

RETURN:		dgroup:[initFileBufSegAddr]
		dgroup:[loaderVars].KLV_initFileSize

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	get a bigger buffer
	shift tail portion down

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@

MakeSpace	proc	near
EC<	call	IFCheckDgroupRegs					>

	push	bx,cx,di,si,ds

	mov	ax, es:[loaderVars].KLV_initFileSize
	mov	si, ax			;si <- old buffer size
	add	ax, cx
	mov	di, ax			;di <- new buffer size

	mov	bx, es:[loaderVars].KLV_initFileBufHan
	mov	ch, mask HAF_ZERO_INIT or mask HAF_NO_ERR
	call	MemReAlloc

	;--------------------------------------------------------------------
	;es = dgroup
	;si = old init file buffer size
	;di = new size

	mov	es:[initFileBufSegAddr], ax
	mov	es:[loaderVars].KLV_initFileSize, di

	mov	cx, si
	sub	cx, es:[initFileBufPos]	;cx <- num bytes to relocate
	dec	di			;point di at last dest byte
	dec	si			;point si at last source byte

	mov	ds, ax			;ds <- buffer addr
	mov	es, ax			;es <- buffer addr

	std				;get mov to decrement di and si
	rep	movsb
	cld

	mov	es, bp
	pop	bx,cx,di,si,ds

if HASH_INIFILE
	call	HashUpdateHashTable
endif			; HASH_INIFILE
	ret
MakeSpace	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	Hex16ToAscii

DESCRIPTION:	Converts a hex word to its ASCII representation
		without leading zeros.

CALLED BY:	INTERNAL (InitFileWriteInteger)

PASS:		ax - number to convert
		es:di - location to place ASCII string
			(not null terminated)

RETURN:		di - offset to one char past last char stored

DESTROYED:	ax, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		The number is converted to decimal as it's easily user-editable
		and is used in keys where the user could well want to edit
		things (namely integers).

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@

Hex16ToAscii	proc	near
	push	bx,dx

	mov	bx, 10
	clr	cx		;cx = count for number of digits
convLoop:
	clr	dx
	div	bx
	push	dx		;save remainder
	inc	cx		;inc digit count
	tst	ax		;done?
	jne	convLoop	;loop if not

storeLoop:
	pop	ax
	add	al, '0'
	stosb
	loop	storeLoop

	pop	bx,dx
	ret
Hex16ToAscii	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	Hex8ToAscii

DESCRIPTION:	Converts a hex byte to its ASCII representation (two hex
		digits)

CALLED BY:	INTERNAL (BuildEntryFromData)

PASS:		al - number to convert
		es:di - location to place ASCII string
			(not null terminated)

RETURN:		di - offset to one char past last char stored

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

----------------------------------------------------------------------------@


nibbles		db	"0123456789ABCDEF"
Hex8ToAscii	proc	near
		uses	bx
		.enter
		push	ax
		mov	bx, offset nibbles
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		and	al, 0fh
		xlatb	cs:
		stosb
		pop	ax
		and	al, 0fh
		xlatb	cs:
		stosb
		.leave
		ret
Hex8ToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileHex8ToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a byte to its 2-hex-digit ASCII representation

CALLED BY:	EXTERNAL
PASS:		al	= number to convert
		es:di	= place to store result (won't be null-terminated)
RETURN:		es:di	= points after last char stored
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not DBCS_PCGEOS
InitFileHex8ToAscii	proc	far
		.enter
		call	Hex8ToAscii
		.leave
		ret
InitFileHex8ToAscii	endp
endif

InitfileWrite	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		We want the validate routine to reside in the Read resource
		for the EC kernel, and the Write resource in the non-EC
		kernel, to avoid ugly deadlock situations.

		Thanks for letting us know what those ugly deadlock situations
		were, Cheng.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EC  <	InitfileRead	segment	resource				>
NEC <	InitfileWrite	segment	resource				>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValidateIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scans the passed buffer for non-ascii characters.

CALLED BY:	INTERNAL
PASS:		ds - segment of ini file
		cx - # chars in .ini file
RETURN:		carry set if file is trashed (has non-ascii chars)
DESTROYED:	nothing but flags
 
PSEUDO CODE/STRATEGY:

	1) If any non-ascii characters are found, return TRASHED

	2) for each line:
	  A) if the line begins with C_CR -> ignore rest of line
	  B) else if the line begings with '[', it must end with ']'
	  C) else the line must contain a '='
	    1) if the first non-whitespace character is a '{', skip to the
	       matching '}'

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VIF_State	etype	byte
VIF_START_OF_LINE		enum	VIF_State	;Looking for any string
VIF_CATEGORY_LINE_NO_END_BRACKET enum	VIF_State	;Line starts with [
VIF_COMMENT			enum	VIF_State	;Line starts with ;
VIF_LOOKING_FOR_EQUAL		enum	VIF_State	;Looking for '=' in line
VIF_IN_BRACE			enum	VIF_State	;Parse '{', looking '}'
VIF_EXPECT_EOL			enum	VIF_State	;Looking for CR or LF

if	ERROR_CHECK or BACKUP_AND_RESTORE_INI_FILE
ValidateIniFileFar	proc	far
	call	ValidateIniFile
	ret
ValidateIniFileFar	endp
endif

ValidateIniFile	proc	near
	uses	ax, cx, dx, si
	.enter

	clr	si			;ds:si <- pointer to text
charLoopStartLine:
	mov	dl, VIF_START_OF_LINE		;starting state

charLoop:
EC <	tst	cx							>
EC <	ERROR_S	INI_FILE_VERIFICATION_ERROR				>
	jcxz	toEndOfBuffer
	lodsb
	dec	cx				;decrement count
	cmp	al, C_CTRL_Z			;If at EOF, this is the end of
	jz	toEndOfBuffer			; the buffer.
	cmp	al, C_CR
	jz	handleCR
	cmp	al, C_TAB
	jz	charLoop
	cmp	al, ' '
	jz	charLoop
	cmp	al, 0x20
	jae	charOK
toError:
	jmp	error
toEndOfBuffer:
	jmp	endOfBuffer
charOK:

	; if comment then slip

	cmp	dl, VIF_COMMENT
	jz	charLoop

	; if first char on line...

	cmp	dl, VIF_START_OF_LINE
	jnz	notStartOfLine

	mov	dl, VIF_CATEGORY_LINE_NO_END_BRACKET	;assume '['
	cmp	al, '['
	jz	charLoop

	mov	dl, VIF_COMMENT			;assume comment
	cmp	al, INIT_FILE_COMMENT
	jz	charLoop

	mov	dl, VIF_LOOKING_FOR_EQUAL
	jmp	charLoop

notStartOfLine:
	cmp	dl, VIF_LOOKING_FOR_EQUAL
	jnz	notLookingForEqual

	cmp	al, '='
	jnz	charLoop

	; char is '=', look for '['

skipWhite:
	lodsb				;get next char
	dec	cx
	jcxz	toError
	cmp	al, C_TAB
	jz	skipWhite
	cmp	al, ' '
	jb	toError			;if control char then error (CR is error
					;also)
	jz	skipWhite
	mov	dl, VIF_IN_BRACE
	cmp	al, '{'			;if '{' then scan for '}'
	jz	charLoop		;   (skip to end of line)
	mov	dl, VIF_COMMENT
	jmp	charLoop

notLookingForEqual:
	cmp	dl, VIF_CATEGORY_LINE_NO_END_BRACKET
	jnz	notLookingForEndBracket

	; looking for ']'

	cmp	al, ']'
	jnz	charLoop
	mov	dl, VIF_EXPECT_EOL
	jmp	charLoop

notLookingForEndBracket:
	cmp	dl, VIF_EXPECT_EOL
	jz	error
EC <	cmp	dl, VIF_IN_BRACE					>
EC <	ERROR_NZ	INI_FILE_VERIFICATION_ERROR			>
	cmp	al, '}'
	jnz	toCharLoop
	mov	dl, VIF_EXPECT_EOL
toCharLoop:
	jmp	charLoop

handleCR:

	; end of line

	cmp	dl, VIF_COMMENT
	jz	lookForLF
	cmp	dl, VIF_EXPECT_EOL
	jz	lookForLF
	cmp	dl, VIF_IN_BRACE
	jz	lookForLF
	cmp	dl, VIF_CATEGORY_LINE_NO_END_BRACKET
	jz	error
	cmp	dl, VIF_LOOKING_FOR_EQUAL
	jz	error
EC <	cmp	dl, VIF_START_OF_LINE					>
EC <	ERROR_NZ	INI_FILE_VERIFICATION_ERROR			>
lookForLF:
	jcxz	error
	lodsb
	dec	cx
	cmp	al, C_LF
	jnz	error
	cmp	dl, VIF_IN_BRACE
	jz	toCharLoop
	jmp	charLoopStartLine

endOfBuffer:
	cmp	dl, VIF_IN_BRACE
	jz	error
	cmp	dl, VIF_CATEGORY_LINE_NO_END_BRACKET
	jz	error
	cmp	dl, VIF_LOOKING_FOR_EQUAL
	jz	error

	; allow VIF_EXPECT_EOL and VIF_START_OF_LINE and VIF_COMMENT

	clc
	jmp	common

error:
	stc
common:
	.leave
	ret
ValidateIniFile	endp

EC  <	InitfileRead	ends						>
NEC <	InitfileWrite	ends						>
