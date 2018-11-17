COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsSmallModify.asm

AUTHOR:		John Wedgwood, Nov 19, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/19/91	Initial revision

DESCRIPTION:
	Modification code for small text objects.

	$Id: tsSmallModify.asm,v 1.1 97/04/07 11:22:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallReplaceRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace a range in a small object.

CALLED BY:	TS_ReplaceRange via CallStorageHandler
PASS:		*ds:si	= Text object instance
		ss:bp	= VisTextReplaceParameters
RETURN:		ds	= Segment containing the text object (may have moved)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallReplaceRange	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, di, si, bp, es
	.enter
EC <	call	ECSmallCheckVisTextReplaceParameters		>
	;
	; Get the text chunk and position to insert/delete at
	;
	call	Text_DerefVis_DI		; ds:di <- text instance
	mov	ax, ds:[di].VTI_text		; ax <- chunk
	
	mov	bx, ss:[bp].VTRP_range.VTR_start.low
DBCS <	shl	bx, 1							>
						; bx <- place to insert/delete
	;
	; Figure out the difference between insCount and delCount so
	; that we can make the space adjustment in a single operation.
	;
	mov	cx, ss:[bp].VTRP_insCount.low	; cx <- # of chars to insert
	sub	cx, ss:[bp].VTRP_range.VTR_end.low
	add	cx, ss:[bp].VTRP_range.VTR_start.low
	
	;
	; ds	= Segment address of the heap
	; ax	= Text chunk
	; bx	= Offset to insert at
	; cx	= Number of characters to insert
	;

	js	deleteSpace			; Branch if negative
DBCS <	shl	cx, 1				; 2 bytes per char	>
	call	LMemInsertAt			; Make space for new text
	jmp	copyTextIn

deleteSpace:
	;
	; cx = -1 * number of characters to delete
	;
	neg	cx				; cx <- # of characters to nuke
DBCS <	shl	cx, 1				; 2 bytes per char	>
	call	LMemDeleteAt

copyTextIn:

;	Mark the text as dirty, since we are modifying it.
;	(This fixes the bug where we change the text without changing the
;	*size*, so LMemInsertAt above does not mark the text chunk dirty).

	xchg	si, ax			;*DS:SI <- text chunk, *DS:AX <- obj
	call	ObjMarkDirty
	xchg	si, ax			;Vice versa

	;
	; Copy the text into the buffer.
	; (*ds:ax) + bx = Pointer to the buffer to copy into
	;
	mov	cx, ss:[bp].VTRP_insCount.low	; cx <- # of bytes to insert
	jcxz	afterCopy			; Branch if nothing to insert

	mov	si, ax
	mov	di, ds:[si]			; ds:di <- ptr to text
	add	di, bx				; ds:di <- ptr to buffer
	segmov	es, ds, ax			; es:di <- ptr to buffer

	lea	bp, ss:[bp].VTRP_textReference	; ss:bp <- ptr to reference
	;
	; es:di	= Place to put the text
	; cx	= Number of chars of text to copy
	; ss:bp	= Pointer to the text reference
	;
	call	CopyTextReference		; Call the callback...

afterCopy:
	.leave
	ret
SmallReplaceRange	endp

Text	ends
