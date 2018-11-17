COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		utilsStrings.asm

AUTHOR:		John Wedgwood, Nov  6, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/ 6/91	Initial revision

DESCRIPTION:
	String related utilities.

	$Id: utilsStrings.asm,v 1.1 97/04/04 17:47:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCopyStringResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string resource chunk into a buffer

CALLED BY:	Utility
PASS:		ax	= Chunk handle of the string
		es:di	= Destination
RETURN:		cx	= # of bytes written (not counting NULL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The whole string, including NULL char, is copied over.
		Returns length of string w/out NULL.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version
	witt	11/12/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCopyStringResource	proc	far
	uses	ax, bx, di, si, ds
	.enter
	mov	si, ax			; si <- chunk handle

	mov	bx, handle StringUI
	call	MemLock			; ax <- seg addr of resource
	mov	ds, ax			; *ds:si <- string
	
	mov	si, ds:[si]		; ds:si <- string pointer
	ChunkSizePtr	ds, si, cx	; cx <- size of the string
	
	push	cx			; Save length of chunk
	rep	movsb			; Copy the string
	pop	cx			; Restore length of chunk
	LocalPrevChar	escx		; Don't count the NULL
	
	call	MemUnlock		; Release the string resource
	.leave
	ret
UtilCopyStringResource	endp


ChartCompCode	ends
