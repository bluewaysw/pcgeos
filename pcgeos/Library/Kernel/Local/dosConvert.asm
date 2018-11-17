COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosConvert.asm

AUTHOR:		Gene Anderson, Dec 12, 1990

ROUTINES:
	Name			Description
	----			-----------
EXT	LocalDosToGeos		Map text from current code page to GEOS
EXT	LocalGeosToDos		Map text from GEOS to current code page
EXT	LocalDosToGeosChar	Map character from current code page to GEOS
EXT	LocalGeosToDosChar	Map character from GEOS to current code page

EXT	LocalCodePageToGeos	Map text from arbitrary code page to GEOS
EXT	LocalGeosToCodePage	Map text from GEOS to abritrary code page
EXT	LocalCodePageToGeosChar	Map character from arbitrary code page to GEOS
EXT	LocalGeosToCodePageChar	Map character from GEOS to arbitrary code page

EXT	LocalIsDosChar		See if character is in DOS code page
EXT	LocalGetCodePage	Get value of current DOS code page

	GetCodePage		Get abitrary DOS code page
	GetCurrentCodePage	Get current code page from DOS
	ConvertBuffer		Convert an entire buffer of text
INIT	InitCodePage		Init routine for code pages

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	12/12/90	Initial revision

DESCRIPTION:
	Contains routines for mapping text to and from the IBM character
	set to the PC/GEOS character set, based on DOS's idea of the current
	code page.

	$Id: dosConvert.asm,v 1.1 97/04/05 01:16:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DOSConvert	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalDosToGeos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert DOS text to GEOS, using current code page
CALLED BY:	DR_LOCAL_DOS_TO_GEOS

PASS:		ds:si - ptr to text
		cx - max # of chars (0 for NULL-terminated)
		ax - default character
RETURN:		carry - set if the default character was used
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDosToGeos	proc	far
	
if	FULL_EXECUTE_IN_PLACE
EC <	push	bx						>
EC <	mov	bx, ds						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	pop	bx						>
endif

	push	ax, bx, di
	mov	bx, offset codePageUS		;bx <- offset to table
	GOTO	ConvertBuffer, di, bx, ax	;convert me
LocalDosToGeos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGeosToDos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert GEOS text to DOS, using current code page
CALLED BY:	DR_LOCAL_GEOS_TO_DOS

PASS:		ds:si - ptr to text
		cx - max # of chars (0 for NULL-terminated)
		ax - default character
RETURN:		carry - set if the default character was used
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalGeosToDos	proc	far

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx						>
EC <	mov	bx, ds						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	pop	bx						>
endif
	
	push	ax, bx, di
	mov	bx, offset toUSCodePage		;bx <- offset to table
	GOTO	ConvertBuffer, di, bx, ax	;convert me jesus
LocalGeosToDos	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsCodePageSupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed code page is a supported one.

CALLED BY:	GLOBAL
PASS:		ax - code page to check
RETURN:		Z flag clear if not supported (jnz notSupported)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalIsCodePageSupported	proc	far	
	uses	es, di, cx
	.enter
	segmov	es, cs
	mov	di, offset codePageList
	mov	cx, length codePageList
	repne	scasw
	.leave
	ret
LocalIsCodePageSupported	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCodePageToGeos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert text in abritrary code page to GEOS
CALLED BY:	DR_LOCAL_CODE_PAGE_TO_GEOS

PASS:		ds:si - ptr to text
		cx - max # of chars (0 for NULL-terminated)
		ax - default character
		bx - code page to use
RETURN:		carry - set if the default character was used
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalCodePageToGeos	proc	far

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx						>
EC <	mov	bx, ds						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	pop	bx						>
endif
	
	push	ax, bx, di
	mov	di, offset codePageUS		;di <- offset to table
	GOTO	ConvertBufferCP, di, bx, ax
LocalCodePageToGeos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGeosToCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert text in arbitrary code page to GEOS
CALLED BY:	DR_LOCAL_GEOS_TO_CODE_PAGE

PASS:		ds:si - ptr to text
		cx - max # of chars (0 for NULL-terminated)
		ax - default character
		bx - code page to use
RETURN:		carry - set if the default character was used
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalGeosToCodePage	proc	far
	
if	FULL_EXECUTE_IN_PLACE
EC <	push	bx						>
EC <	mov	bx, ds						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	pop	bx						>
endif

	push	ax, bx, di
	mov	di, offset toUSCodePage		;di <- offset to table
	FALL_THRU	ConvertBufferCP, di, bx, ax
LocalGeosToCodePage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a buffer of text to or from DOS/GEOS
CALLED BY:	Local{DOS,CP}ToGEOS(), LocalGEOSTo{DOS,CP}()

PASS:		bx - offset of table in resource (0 or 0x80)
		ds:si - ptr to text
		cx - max # of chars (0 for NULL-terminated)
		ax - default character
RETURN:		carry - set if the default character was used
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertBufferCP	proc	far
	push	cx, si, es			;push for ConvertBufferInt()
	push	ax
	mov	ax, bx				;ax <- DosCodePage
	call	GetCodePage			;get code page
	pop	ax				;ah <- default character
	GOTO	ConvertBufferInt, es, si, cx
ConvertBufferCP	endp

ConvertBuffer	proc	far
	push	cx, si, es			;do not change order

	mov	di, bx				;di <- offset to table
	call	GetCurrentCodePage		;get current code page
	;
	; di - offset of table in resource
	; bx - handle of resource
	; es - seg addr of resource
	;
	; ax - default character (high byte = null for SBCS)
	; ds:si - ptr to text
	; cx - # of characters (0 for NULL-terminated)
	;

	FALL_THRU	ConvertBufferInt, es, si, cx
ConvertBuffer	endp

;---

ConvertBufferInt	proc	far
EC <	call	ECCheckBounds						>
	push	bx				;save handle of code page

EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>

	mov	ah, al				;ah <- default char

	clc					;assume no default mapping
	pushf

	lea	bx, [di-MIN_MAP_CHAR]		;es:bx <- ptr to table, offset
						; by minimum mappable char
charLoop:
	mov	al, ds:[si]			;al <- character from buffer
	tst	al
	jz	done				;stop on NULL
		CheckHack <MIN_MAP_CHAR gt 0x7f>
	jns	noMap				;branch if not mappable
	es:xlat					;al <- converted character
	tst	al				;character missing?
	jnz	isMapped			;branch if not missing
	mov	al, ah				;al <- default character
	popf					;set flag for default used
	stc
	pushf
isMapped:
	mov	ds:[si], al
noMap:
	inc	si
	loop	charLoop
done:
	popf					;recover return value
	pop	bx				;bx <- handle of code page
	call	MemUnlock			;unlock code page

	FALL_THRU_POP	es, si, cx

	FALL_THRU_POP	di, bx, ax
	ret
ConvertBufferInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCodePage, GetCurrentCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a DOS code page
CALLED BY:	LocalDOSToGEOS(), LocalGEOSToDOS(), LocalCompareStringDOSToGEOS

PASS:		ax - DOS code page to get (GetCodePage() only)
RETURN: 	bx - handle of code page resource
		es - seg addr of code page resource
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCurrentCodePage	proc	far
	uses	ax
	.enter

	mov	ax, segment idata
	mov	es, ax				;es <- seg addr of idata
	mov	bx, es:currentCodePageHandle	;bx <- current DosCodePage
	call	MemLock
	mov	es, ax				;es <- seg addr of table

	.leave
	ret
GetCurrentCodePage	endp

GetCodePage	proc	far
	uses	ax, cx, dx, di
	.enter

	mov	di, offset codePageList
	segmov	es, cs				;es:di <- ptr to table
	mov	cx, (size codePageList) / 2	;cx <- # of words to scan
	repne	scasw
	jne	noCodePage			;use default if not found
	sub	di, (offset codePageList) + 2	;convert to index
done:
	mov	bx, cs:codePageHandles[di]	;bx <- handle of resource
	call	MemLock
	mov	es, ax				;es <- seg addr of table

	.leave
	ret

noCodePage:
	mov	di, 0				;di <- index of default
	jmp	done
GetCodePage	endp

;
; List of supported code pages, and corresponding resource handles
;
codePageList	DosCodePage \
	CODE_PAGE_US,
	CODE_PAGE_MULTILINGUAL,
	CODE_PAGE_CANADIAN_FRENCH,
	CODE_PAGE_NORDIC,
	CODE_PAGE_PORTUGUESE,
	CODE_PAGE_LATIN_1

codePageHandles	hptr \
	USMap,					;default must be first
	MultiMap,
	FrenchMap,
	NordicMap,
	PortugueseMap,
	Latin1Map


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCodePageToGeosChar, LocalGeosToCodePageChar
		LocalDosToGeosChar, LocalGeosToDosChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a single character to and from an arbitrary code page
CALLED BY:	GLOBAL

PASS:		ax - character to map
		bx - default character
		cx - code page for mapping (DosCodePage)
			(LocalDosToGeosChar() and LocalGeosToDosChar() only)
RETURN:		ax - mapped character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalCodePageToGeosChar	proc	far
	push	dx
	mov	dx, offset codePageUS		;dx <- offset of resource
	GOTO_ECN	ConvertCharacterCPPopDX, dx
LocalCodePageToGeosChar	endp

LocalGeosToCodePageChar	proc	far
	push	dx
	mov	dx, offset toUSCodePage		;dx <- offset of resource
	GOTO_ECN	ConvertCharacterCPPopDX, dx
LocalGeosToCodePageChar	endp

LocalDosToGeosChar	proc	far
	push	dx
	mov	dx, offset codePageUS		;dx <- offset of resource
	GOTO_ECN	ConvertCharacter, dx
LocalDosToGeosChar	endp

LocalGeosToDosChar	proc	far
	push	dx
	mov	dx, offset toUSCodePage		;dx <- offset of resource
	FALL_THRU_ECN	ConvertCharacter, dx
LocalGeosToDosChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertCharacter, ConvertCharacterCPPopDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do conversion of a single character to or from GEOS
CALLED BY:	LocalGeosToCodePageChar(), LocalCodePageToGeosChar(),
		LocalGeosToDosChar(), LocalDosToGeosChar()

PASS:		ax - character to map
		bx - default character
		cx - code page (ConvertCharacterCPPopDX() only)
		dx - offset of resource
RETURN:		al - mapped character
		carry - set if default character is used
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertCharacter	proc	necjmp
	push	cx
	push	bx
	call	LocalGetCodePage		;bx
	mov	cx, bx
	pop	bx
	call	ConvertCharacterCP
	pop	cx
	FALL_THRU_POP	dx
	ret
ConvertCharacter	endp

ConvertCharacterCPPopDX	proc	necjmp
	call	ConvertCharacterCP
	FALL_THRU_POP	dx
	ret
ConvertCharacterCPPopDX	endp
;---

ConvertCharacterCP	proc	near 
	uses	es, di, bp, bx
	.enter

EC <	tst	bh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>

	mov	bp, bx				;bp <- default character
	mov	di, dx				;di <- offset of resource
	push	ax
	mov	ax, cx
	call	GetCodePage			;es <- seg addr of code page
	pop	ax

	push	bx				;save handle of code page
	lea	bx, [di-MIN_MAP_CHAR]		;es:bx <- ptr to table less
						; the smallest mappable
						; char (which is at offset 0
						; in the table)

	tst	al
	jns	done				;branch if not mappable
						;(with carry clear)
	es:xlat					;al <- converted character
	tst	al				;character missing?
	jz	missing				;branch if not missing
	clr	ah				;clears carry
done:
	pop	bx				;bx <- handle of code page
	call	MemUnlock			;unlock code page

	.leave
	ret

missing:
	mov	ax, bp				;ax <- default character
	stc					;indicate missing
	jmp	done
ConvertCharacterCP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current
CALLED BY:	DR_LOCAL_GET_CODE_PAGE

PASS:		none
RETURN:		bx - DosCodePage
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalGetCodePage	proc	far
	uses	ds
	.enter

	LoadVarSeg	ds
	mov	bx, ds:currentCodePage		;ax <- current code page

	.leave
	ret
LocalGetCodePage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsDosChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if character in the DOS character set.
CALLED BY:	DR_LOCAL_IS_DOS_CHAR

PASS:		ax - character to check
RETURN:		z flag - clear (nz) if valid DOS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: MIN_MAP_CHAR = 0x80
	ASSUMES: no mapped char maps (properly) to something < 0x80
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalIsDosChar	proc	far
	uses	ax, bx, es, di
	.enter

EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>

	mov	di, ax				;di <- character to check
	andnf	di, 0x00ff
	sub	di, MIN_MAP_CHAR		;mappable?
	jb	done				;branch (nz) if not mappable

	call	GetCurrentCodePage		;get current code page
	add	di, offset toUSCodePage		;for relocation
	mov	al, es:[di]			;al <- mapped character
	cmp	al, MIN_MAP_CHAR-1		;mapped?
	jbe	notDOSChar			;branch if not mappable
doUnlock:
	call	MemUnlock			;unlock code page resource
done:

	.leave
	ret

notDOSChar:
	clr	di				;set z flag
	jmp	doUnlock
LocalIsDosChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalSetCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the code page used by the system as the "DOS" code page.

CALLED BY:	RESTRICTED GLOBAL
		For use by primary IFS drivers only.
PASS:		ax	= code page number (DosCodePage)
RETURN:		carry set if code page not known
			bx	= untouched
		carry clear if code page set:
			bx	= hptr.LocalCodePage of selected page
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalSetCodePage proc	far
	uses	es, ds, di, cx
	.enter
	;
	; See if the code page is one we support
	;
	segmov	es, cs				;es <- seg addr of idata
	mov	di, offset codePageList
	mov	cx, length codePageList		;cx <- # of words to scan
	repne	scasw
	stc
	jne	done				;return error if not found

	LoadVarSeg	ds, bx
	sub	di, (offset codePageList) + 2	;convert to index
	mov	ds:currentCodePage, ax		;store code page #
	mov	bx, cs:codePageHandles[di]	;bx <- handle of resource
	mov	ds:currentCodePageHandle, bx	;store code page handle
	clc					;signal happiness
done:
	.leave
	ret
LocalSetCodePage endp

DOSConvert	ends
