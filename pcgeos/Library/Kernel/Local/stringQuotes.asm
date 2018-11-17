COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		stringQuotes.asm

AUTHOR:		Roger Flores, Dec  12, 1990

ROUTINES:
	Name			Description
	----			-----------
	StringGetQuotes		return localized single and double quotes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	12/12/90	Initial revision

DESCRIPTION:
	return localized single and double quotes

	$Id: stringQuotes.asm,v 1.1 97/04/05 01:16:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringMod	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetQuotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Function to return localized single and double quotes

CALLED BY:	Utility
PASS:		nothing
RETURN:
		ax -	front single quote
		bx -	end single quote
		cx -	front double quote
		dx -	end double quote

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	12/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalGetQuotes		proc	far
	uses	si, ds
	.enter

	call	LockStringsDS

	mov	si, offset Quotes
	mov	si, ds:[si]			;ds:si <- ptr to resouce

if DBCS_PCGEOS
	; load the single quotes
	mov	ax, ds:[si]
	mov	bx, ds:[si]+2
	; load the double quotes
	mov	cx, ds:[si]+4
	mov	dx, ds:[si]+6
else
	; load the single quotes
	mov	ax, ds:[si]
	mov	bl, ah

	; load the double quotes
	inc	si
	inc	si
	mov	cx, ds:[si]
	mov	dl, ch

	clr	ah
	clr	bh
	clr	ch
	clr	dh
endif

	call	UnlockStrings

	.leave
	ret
LocalGetQuotes		endp

StringMod	ends

ObscureInitExit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalSetQuotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Function to set localized single and double quotes

CALLED BY:	Utility

PASS:		ax -	front single quote
		bx -	end single quote
		cx -	front double quote
		dx -	end double quote

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	12/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalSetQuotes		proc	far
	uses	ds, es, si, ds, di, cx, dx, ax, bx
	.enter

if not DBCS_PCGEOS
EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
EC <	tst	bh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
EC <	tst	ch							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
EC <	tst	dh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif

	call	LockStringsDS

	mov	si, offset Quotes

	; from ax, store the single quotes

if not DBCS_PCGEOS
	mov	ah, bl				;ax = both single quotes
	mov	ch, dl				;cx = both double quotes
endif

	mov	si, ds:[si]			;es:si <- ptr to resouce
	mov	di, si				;keep in es:di as well
if DBCS_PCGEOS
	mov	ds:[si], ax
	mov	ds:[si]+2, bx
	mov	ds:[si]+4, cx
	mov	ds:[si]+6, dx
else
	mov	ds:[si], ax

	; from bx, store the double quotes

	inc	si
	inc	si
	mov	ds:[si], cx
endif

	segmov	es, ds

	segmov	ds, cs				; ds:si - category
	mov	cx, ds				; cx:dx - key
	mov	dx, offset quotesKey

	mov	si, offset localizationCategory	; ds:si
	call	LocalWriteStringAsData		; destroys cx

	call	UnlockStrings

	.leave
	ret
LocalSetQuotes		endp

quotesKey	char	"quotes",0

ObscureInitExit	ends

;---

ObscureInitExit	segment


COMMENT @----------------------------------------------------------------------

ROUTINE:	InitQuotes

SYNOPSIS:	Initializes quotes stuff.

CALLED BY:	LocalInit

PASS:		nothing

RETURN:		nothing

DESTROYED:	something?

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/28/90	Initial version

------------------------------------------------------------------------------@

InitQuotes	proc	near	uses ds, es
	.enter
if	FULL_EXECUTE_IN_PLACE

;	The LocalStrings resource is supposed to be preloaded, but isn't on
;	full-XIP systems, so bring it into memory now (this is done because
;	LockStringsDS does a MemThreadGrab on the block, which fails if
;	the block is discarded).

	mov	bx, handle LocalStrings
	call	MemLock
	call	MemUnlock
endif
	call	LockStringsDS
	segmov	es, ds

	mov	cx, cs				; cx:dx - key
	mov	dx, offset quotesKey
	segmov	ds, cs
	mov	si, offset localizationCategory	; ds:si
	mov	di, offset Quotes		; get chunk handle
	mov	di, es:[di]			; deref; buffer now in es:di
	mov	bp, QUOTES_CHUNK_SIZE		; maximum size to read in
						;  (including null)
	call	LocalGetStringAsData		; destroys cx

	call	UnlockStrings			; unlock the block
	.leave
	ret
InitQuotes	endp


ObscureInitExit	ends
