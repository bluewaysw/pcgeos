COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsSmallCreate.asm

AUTHOR:		John Wedgwood, Nov 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/26/91	Initial revision

DESCRIPTION:
	Create/Destroy text storage in small text objects

	$Id: tsSmallCreDest.asm,v 1.1 97/04/07 11:22:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallCreateTextStorage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create storage for a small text object.

CALLED BY:	TS_CreateTextStorage via CallStorageHandler

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
TS_SmallCreateTextStorage	proc	far
	class	VisTextClass
	uses	ax, cx, di
	.enter
	mov	ax, si
	call	ObjGetFlags			; al <- text-object flags.
	and	al, mask OCF_IGNORE_DIRTY

	mov	cx, TEXT_INIT_STREAM
	or	al,mask OCF_DIRTY
	call	LMemAlloc			; Allocate a dirty chunk

	mov	di, ax				; di <- new text chunk
	mov	di, ds:[di]			; ds:di <- ptr to stream.
					; DBCS::
SBCS <	mov	{byte} ds:[di], 0		; make it an empty string.>
DBCS <	mov	{wchar} ds:[di], 0		; make it an empty string.>

	call	Text_DerefVis_DI		; ds:di <- instance ptr
	mov	ds:[di].VTI_text, ax		; save stream handle.
	.leave
	ret
TS_SmallCreateTextStorage	endp

Text ends
