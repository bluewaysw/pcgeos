COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsLargeCreDest.asm

AUTHOR:		John Wedgwood, Nov 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/26/91	Initial revision

DESCRIPTION:
	Code for creating/destroying storage in a large text object.

	$Id: tsLargeCreDest.asm,v 1.1 97/04/07 11:22:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextStorageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeCreateTextStorage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a huge-array to hold text.

CALLED BY:	TS_DestroyTextStorage via CallStorageHandler
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_LargeCreateTextStorage	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, di, bp
	.enter
	;
	; Call the huge-array code to create the huge-array
	;
	call	TextStorage_DerefVis_DI		; ds:di <- instance ptr
	mov	bp, di				; ds:bp <- instance ptr

SBCS <	mov	cx, 1				; cx <- size of each element >
DBCS <	mov	cx, 2				; cx <- size of each element >
	clr	di				; No extra space in header
	call	T_GetVMFile			; bx = VM file
	call	HugeArrayCreate			; di <- new array handle
	mov	ds:[bp].VTI_text, di		; Save handle
	
	;
	; Append a NULL to the array.
	;
	push	si				; Save instance chunk
NOFXIP<	mov	bp, cs				; bp:si <- fptr to null	>
NOFXIP<	mov	si, offset cs:nullString				>
FXIP<	mov	cx, NULL						>
FXIP<	push	cx							>
FXIP<	mov	bp, ss							>
FXIP<	mov	si, sp							>
	mov	cx, 1				; Append 1 element
	call	HugeArrayAppend			; Append the null
FXIP<	pop	cx							>
	pop	si				; Restore instance chunk

	;
	; Dirty the object
	;
	call	ObjMarkDirty
	.leave
	ret

if not FULL_EXECUTE_IN_PLACE
SBCS <nullString	byte	0		; DBCS::		>
DBCS <nullString	wchar	0					>
endif

TS_LargeCreateTextStorage	endp

TextStorageCode	ends
