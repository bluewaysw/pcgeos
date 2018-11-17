COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpName.asm

AUTHOR:		Gene Anderson, Oct 25, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/25/92	Initial revision


DESCRIPTION:
	Routines for dealing with names in the help object

	$Id: helpName.asm,v 1.1 97/04/07 11:47:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HNFindNameForContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the name entry for a given context

CALLED BY:	
PASS:		*ds:si - HelpControl object
		ss:bp - inherited locals
			context - name to find
RETURN:		ss:bp - inherited locals
			nameData - data for name entry
			context - updated if CUI-specific context found
		carry - set if error (context does not exist)
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Note that if we find a CUI-specific context, we'll
		update the context name. That means that if we
		use "Go Back" or "History" to revisit this context
		we'll try to apply another "CUI" onto the end. That
		context should not be found, but then the "original"
		context name will be tried and found.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version
	Don	1/28/00		Added CUI-specific help
	Don	2/4/00		Fixed to modify context name so
				that "Info" can be accurately reported

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HNFindNameForContext		proc	near
	uses	di, si, ds, es
HELP_LOCALS
	.enter	inherit

	;
	; Create the CUI-specific context name here because it is convenient
	;
	segmov	es, ss, ax
	sub	sp, size ContextName
	mov	dx, sp				;ss:ax <- CUI buffer
	push	ds, si				;save HelpControl
	lea	di, ss:context			;es:di <- original context str
	call	LocalStringSize			;cx <- length
	cmp	cx, MAX_CONTEXT_NAME_LENGTH - 3
	jle	copyString
	mov	cx, MAX_CONTEXT_NAME_LENGTH - 3
copyString:
	mov	ds, ax
	mov	si, di				;ds:si <- original context
	mov	di, dx				;es:di <- CUI buffer
	rep	movsb				;copy the string
	mov	ax, 'C' or 'U' shl 8		;write CUI and NULL-terminate
	stosw
	mov	ax, 'I'
	stosw				
	pop	ds, si				;restore HelpControl

	;
	; Lock the name array
	;
	call	HNLockNameArray

	;
	; Get the data for the name. Note that if we are in the CUI
	; (introductory level) we look first for a CUI-specific name
	;
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	checkRealContext
	mov	di, dx				;es:di <- CUI name to find
	mov	dx, ss
	lea	ax, ss:nameData			;dx:ax <- data buffer
	clr	cx				;cx <- NULL terminated
	call	NameArrayFind
	jc	foundCUI
checkRealContext:
	mov	dx, ss
	lea	ax, ss:nameData			;dx:ax <- data buffer
	lea	di, ss:context			;es:di <- name to find
	clr	cx				;cx <- NULL terminated
	call	NameArrayFind

	;
	; Unlock the name array & set the carry flag correctly
	;
unlock:
	cmc					;carry <- set if not found
	call	HNUnlockNameArray
	lahf
	add	sp, size ContextName
	sahf

	.leave
	ret

	;
	; Found CUI context, so copy actual context name into local var
	;
foundCUI:
	push	ds, si
	segmov	ds, ss
	mov	si, di				;ds:si <- source (CUI name)
	lea	di, ss:context			;es:di <- dest (local var)
	mov	cx, size context
	rep	movsb
	pop	ds, si
	stc
	jmp	unlock
HNFindNameForContext		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HNGetTypeForContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the type of a context

CALLED BY:	HTGetTypeForHistory()
PASS:		*ds:si - controller
		ax - context token
RETURN:		dl - VisTextContextType
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HNGetTypeForContext		proc	near
	uses	ds, cx, si, di
	.enter

	call	HNLockNameArray			;*ds:si <- name array
	call	ChunkArrayElementToPtr
	mov	dl, ds:[di].VTNAE_data.VTND_contextType
	call	HNUnlockNameArray

	.leave
	ret
HNGetTypeForContext		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HNLockNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the name array

CALLED BY:	HNFindNameForContext()
PASS:		*ds:si - controller
RETURN:		*ds:si - name array
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HNLockNameArray		proc	near
	uses	ax, bx, bp
	.enter

	call	HFGetFile			;bx <- handle of help file
	call	HNGetNameArray			;ax <- VM handle of names
	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK	;*ds:si <- name array

	.leave
	ret
HNLockNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HNUnlockNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the name array

CALLED BY:	HNFindNameForContext()
PASS:		ds - seg addr of name array
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HNUnlockNameArray		proc	near
	uses	bp
	.enter

	mov	bp, ds:LMBH_handle		;bp <- memory handle of names
	call	VMUnlock

	.leave
	ret
HNUnlockNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HNGetNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name array for the current file

CALLED BY:	UTILITY
PASS:		*ds:si <- controller
RETURN:		ax - VM handle of name array
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HNGetNameArray		proc	near
	uses	di
	class	HelpControlClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset
	mov	ax, ds:[di].HCI_nameArrayVM	;ax <- VM handle of name array

	.leave
	ret
HNGetNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HNSetNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the VM handle of the name array

CALLED BY:	UTILITY
PASS:		*ds:si - controller
		ax - VM handle of name array
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HNSetNameArray		proc	near
	uses	di
	class	HelpControlClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset
	mov	ds:[di].HCI_nameArrayVM, ax	;save VM handle of name array

	.leave
	ret
HNSetNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HNGetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the Nth name

CALLED BY:	UTILITY
PASS:		*ds:si - name array
		es:di - ptr to buffer for name
		ax - # of name to get
RETURN:		es:di - filled in
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HNGetName		proc	near
	uses	cx, dx, ds, si, bp, di
	.enter

	;
	; We round the size (up) to a word size to keep swat happy
	;
	sub	sp, (((size NameArrayMaxElement)+1) and 0xfffe)
	;
	; Get the name & data
	;
	mov	dx, sp
	mov	cx, ss				;cx:dx <- ptr to buffer
	call	ChunkArrayGetElement
EC <	cmp	ax, (size RefElementHeader)	;>
EC <	ERROR_E HELP_LINK_TO_NO_WHERE		;>
	;
	; Copy the name
	;
	mov	si, ds:[si]			;ds:si <- ptr to array header
	mov	cx, ds:[si].NAH_dataSize	;cx <- size of our data
	add	cx, (size NameArrayElement)	;cx <- + size of name element
	mov	si, dx
	add	si, cx
	segmov	ds, ss				;ds:si <- ptr to name
	xchg	cx, ax				;cx <- size of element
	sub	cx, ax				;cx <- size of name
if DBCS_PCGEOS
EC <	cmp	cx, MAX_CONTEXT_NAME_LENGTH*2	;			>
		CheckHack <MAX_CONTEXT_NAME_LENGTH ge FILE_LONGNAME_LENGTH>
else
EC <	cmp	cx, FILE_LONGNAME_LENGTH	;			>
		CheckHack <FILE_LONGNAME_LENGTH ge MAX_CONTEXT_NAME_LENGTH>
endif
EC <	ERROR_A HELP_NAME_TOO_LONG		;>
	rep	movsb				;copy me jesus
	;
	; NULL-terminate the name
	;
	clr	ax				;ax <- NULL
	LocalPutChar	esdi, ax		;NULL-terminate

	add	sp, (((size NameArrayMaxElement)+1) and 0xfffe)

	.leave
	ret
HNGetName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HNGetStandardName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a standard name for the help controller

CALLED BY:	UTILITY
PASS:		*ds:si - controller
		ss:bp - inherited locals
		di - chunk of standard name
RETURN:		ss:bp - inherited locals
			context - standard name requested
DESTROYED:	ax, bx, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HNGetStandardName		proc	near
	uses	ds, si, es
HELP_LOCALS
	.enter	inherit

	lea	bx, ss:context			;ss:bx <- ptr to buffer
	call	HNGetStandardNameCommon

	.leave
	ret
HNGetStandardName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HNGetStandardNameCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a standard name for the help controller, version 2

CALLED BY:	UTILITY
PASS:		*ds:si - controller
		ss:bp - inherited locals
		di - chunk of standard name
		ss:bx - buffer to place name
RETURN:		ss:bp - inherited locals
DESTROYED:	ax, bx, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HNGetStandardNameCommon		proc	near
	uses	ds, si, es
HELP_LOCALS
	.enter	inherit

	push	bx
	mov	bx, handle HelpControlStrings
	call	MemLock
	mov	ds, ax

	mov	si, ds:[di]			;ds:si <- ptr to name
	pop	di
	;
	; NOTE: the name is in a chunk, so we can safely (and more
	; quickly) get the chunk size and use rep movsb.
	;
	ChunkSizePtr	ds, si, cx		;cx <- size of name
	segmov	es, ss				;es:di <- ptr to dest
	rep	movsb				;copy me jesus

	call	MemUnlock

	.leave
	ret
HNGetStandardNameCommon		endp

HelpControlCode ends
