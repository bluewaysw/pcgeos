COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textCompatibility.asm

AUTHOR:		John Wedgwood, Nov 21, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/21/91	Initial revision

DESCRIPTION:
	Methods that exist for compatibility purposes only...

	$Id: textCompatibility.asm,v 1.1 97/04/07 11:17:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextInstance	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSelectRangeSmall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selected area.

CALLED BY:	HiliteAndShowSelection, PasteCommon, VisTextReplaceWithGraphic,
		VisTextStartSelect(2)

PASS:		*ds:si	= Instance ptr
		cx	= offset for start of selection.
		dx	= offset for end of selection.

		Offsets should be 0-TEXT_ADDRESS_PAST_END to position the cursor
		in the current object.
RETURN:		nothing
DESTROYED:	all (method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/22/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSelectRangeSmall	method	VisTextClass, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	;
	; For positions past the end of the object, use the max size of the
	; object.
	;
	mov	bx, dx				; Save end in bx
	call	TS_GetTextSize			; dx.ax <- max size

	cmp	cx, ax
	jbe	startOK
	mov	cx, ax
startOK:

	cmp	bx, ax
	jbe	endOK
	mov	bx, ax
endOK:

	;
	; Convert the selection offsets to 32 bit offsets on the stack
	;
	sub	sp, size VisTextRange		; Allocate stack frame
	mov	bp, sp				; ss:bp <- range
	
	mov	ss:[bp].VTR_start.low, cx	; Save 16 bit range
	mov	ss:[bp].VTR_start.high, 0

	mov	ss:[bp].VTR_end.low, bx
	mov	ss:[bp].VTR_end.high, 0

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock		; Set the new range
	
	add	sp, size VisTextRange		; Restore stack
	ret
VisTextSelectRangeSmall	endm

TextInstance	ends
