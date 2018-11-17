COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsLargeAccess.asm

AUTHOR:		John Wedgwood, Nov 19, 1991

ROUTINES:
	Name			Description
	----			-----------
	LargeGetCharAtOffset	Get character at a given offset
	LargeGetTextSize	Get number of bytes of text
	LargeCheckLegalChange	Check that a change won't result in too much 
					text.
	LargeLockTextPtr	Get a pointer to the text
	LargeUnlockTextPtr	Release a block of text
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/19/91	Initial revision

DESCRIPTION:
	

	$Id: tsLargeAccess.asm,v 1.1 97/04/07 11:22:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeGetCharAtOffset
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
LargeGetCharAtOffset	proc	near
	class	VisTextClass
	uses	cx, dx
	.enter
	push	ds, si				; Save instance seg/chunk
	call	LargeLockTextPtr		; ds:si <- ptr to text
						; ax <- # after ds:si
						; cx <- # before ds:si
	
					; DBCS::
SBCS <	mov	dl, ds:[si]			; dx <- character	>
SBCS <	clr	dh							>
DBCS <	mov	dx, ds:[si]			; dx <- character	>

	mov	ax, ds				; ax <- segment of text block
	pop	ds, si				; Restore instance seg/chunk
	call	LargeUnlockTextPtr		; Release the text block
	
	mov	ax, dx				; ax <- character
	.leave
	ret
LargeGetCharAtOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeGetTextSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the amount of text in the text object.

CALLED BY:	TS_GetTextSize via CallStorageHandler
PASS:		*ds:si	= Text object instance
RETURN:		dx.ax	= Number of bytes of text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeGetTextSize	proc	far
	class	VisTextClass
	uses	bx, di
	.enter
	
	;
	; Get the array handle and use it to get the size
	;
	call	T_GetVMFile			;bx = file
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_text		; di <- vm handle of array
	call	HugeArrayGetCount		; dx.ax <- # of characters
	decdw	dxax				; Don't count the NULL
	.leave
	ret
LargeGetTextSize	endp

TextFixed	ends

Text	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeCheckLegalChange
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
LargeCheckLegalChange	proc	near
	stc			; Any change is legal in this object
	ret
LargeCheckLegalChange	endp


Text	ends

TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLockTextPtr
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
LargeLockTextPtr	proc	near
	class	VisTextClass
	uses	bx, dx, di
	.enter
	;
	; Get the array handle and lock the text down.
	;
	call	T_GetVMFile			;bx = file
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_text		; di <- vm handle of array
if DBCS_PCGEOS
PrintMessage <need to change offsets and/or char counts?>
endif
	call	HugeArrayLock			; ds:si <- ptr to element
EC <	tst	ax							>
EC <	ERROR_Z	PASSED_OFFSET_DOES_NOT_EXIST_IN_HUGE_ARRAY		>
						; ax <- # after ptr
						; cx <- # before ptr
						; dx <- element size (1)
	.leave
	ret
LargeLockTextPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeUnlockTextPtr
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
LargeUnlockTextPtr	proc	near
	uses	ds
	.enter
	mov	ds, ax				; ds <- segment of block
	call	HugeArrayUnlock			; Release the block
	.leave
	ret
LargeUnlockTextPtr	endp

TextFixed	ends
