COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsSmallAccess.asm

AUTHOR:		John Wedgwood, Nov 19, 1991

ROUTINES:
	Name			Description
	----			-----------
	SmallGetCharAtOffset	Get character at a given offset
	SmallGetTextSize	Get number of bytes of text
	SmallCheckLegalChange	Check that a change won't result in too many
					characters in the object.
	SmallLockTextPtr	Get a pointer to the text
	SmallUnlockTextPtr	Release a block of text
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/19/91	Initial revision

DESCRIPTION:
	Routines for accessing data in small objects.

	$Id: tsSmallAccess.asm,v 1.1 97/04/07 11:22:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallGetCharAtOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a character at a given offset

CALLED BY:	TS_GetCharAtOffset via CallStorageHandler
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset
RETURN:		ax	= Character at that offset
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallGetCharAtOffset	proc	near
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_text		; *ds:di <- text ptr
	mov	di, ds:[di]			; ds:di <- text ptr
DBCS <	add	di, ax							>
	add	di, ax				; ds:di <- ptr to character
	
SBCS <	mov	al, {byte} ds:[di]					>
SBCS <	clr	ah							>
DBCS <	mov	ax, {wchar} ds:[di]					>

	.leave
	ret
SmallGetCharAtOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallGetTextSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the amount of text in the text object.

CALLED BY:	TS_GetTextSize via CallStorageHandler
PASS:		*ds:si	= Text object instance
RETURN:		dx.ax	= Number of chars of text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallGetTextSize	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_text		; di <- chunk handle of text
	mov	di, ds:[di]			; ds:di <- ptr to text
	
	ChunkSizePtr	ds, di, ax		; ax <- # of bytes
DBCS <	shr	ax, 1				; ax <- # chars		>
	dec	ax				; Don't count NULL
	clr	dx				; dx.ax <- # of chars
	.leave
	ret
SmallGetTextSize	endp

TextFixed	ends

Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallCheckLegalChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that a change won't result in too many characters.

CALLED BY:	TS_CheckLegalChange via CallStorageHandler
PASS:		*ds:si	= Instance pointer
		ss:bp	= VisTextReplaceParameters
RETURN:		carry set if the change is a legal one
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallCheckLegalChange	proc	near
	class	VisTextClass
	uses	ax, dx, di
	.enter
	call	SmallGetTextSize		; dx.ax <- size of text
						; (dx is always zero)
	add	ax, ss:[bp].VTRP_insCount.low
	sub	ax, ss:[bp].VTRP_range.VTR_end.low
	add	ax, ss:[bp].VTRP_range.VTR_start.low
						; ax <- size after change

	call	Text_DerefVis_DI		; ds:di <- instance ptr
	
	sub	ax, ds:[di].VTI_maxLength	; ax <- excess chars
	jbe	sizeOK
	
	;
	; Truncate text to fit?
	;
	test	ss:[bp].VTRP_flags, mask VTRF_TRUNCATE
	jnz	doTruncate			; branch if truncating
						; carry cleared by test
quit:
	;
	; Carry: set,	if the change is legal
	; 	 clear, if the change is not legal
	;
	.leave
	ret

	;
	; Truncating the text to fit is desired -- adjust
	; the # of chars to be inserted.
	; ax	= # of chars execss
	;
doTruncate:
	sub	ss:[bp].VTRP_insCount.low, ax
sizeOK:
	stc					; Signal: change is ok
	jmp	quit
SmallCheckLegalChange	endp

Text	ends

TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLockTextPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to a text offset.

CALLED BY:	TS_LockTextPtr via CallStorageHandler
PASS:		*ds:si	= Text object instance
		dx.ax	= Offset into the text
RETURN:		ds:si	= Pointer to the text at that offset
		ax	= Number of valid characters after ds:si
		cx	= Number of valid characters before ds:si
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLockTextPtr	proc	near
	class	VisTextClass
	uses	di
	.enter
EC <	tst	dx				; Check for reasonable size >
EC <	ERROR_NZ OFFSET_FOR_SMALL_OBJECT_IS_TOO_LARGE			>

	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	mov	si, ds:[di].VTI_text		; si <- chunk handle of text
	mov	si, ds:[si]			; ds:si <- ptr to text start

	ChunkSizePtr	ds, si, cx		; cx <- # of bytes total
if DBCS_PCGEOS
	shr	cx, 1
EC <	ERROR_C	ODD_SIZE_FOR_DBCS_TEXT					>
endif
EC <	cmp	ax, cx							>
EC <	ERROR_A OFFSET_FOR_SMALL_OBJECT_IS_TOO_LARGE			>
	sub	cx, ax				; cx <- # after ptr
DBCS <	add	si, ax							>
	add	si, ax				; ds:si <- ptr to text at offset
	dec	cx				; Don't count NULL
	
	;
	; ds:si	= Pointer to the text
	; ax	= # of valid characters before pointer
	; cx	= # of valid characters after pointer
	;
	
	xchg	ax, cx				; Swap before returning
	inc	cx				;CX = # valid chars before
						; DS:SI, including char at
						; DS:SI
	.leave
	ret
SmallLockTextPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallUnlockTextPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release a block of text

CALLED BY:	TS_UnlockTextPtr via CallStorageHandler
PASS:		*ds:si	= Text object instance
		ax	= Segment containing the text
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallUnlockTextPtr	proc	near
	;
	; For small text object the segment of the text *must* be the
	; same as that of the object.
	;
EC <	push	bx							>
EC <	mov	bx, ds				; bx <- object segment	>
EC <	cmp	ax, bx				; Make sure they're the same >
EC <	ERROR_NZ UNLOCK_PASSED_WRONG_SEGMENT				>
EC <	pop	bx							>
	ret
SmallUnlockTextPtr	endp

TextFixed	ends
