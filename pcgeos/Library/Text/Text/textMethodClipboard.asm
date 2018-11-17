COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textMethodClipboard.asm

AUTHOR:		John Wedgwood, Dec 16, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/16/91	Initial revision

DESCRIPTION:
	Clipboard related methods

	$Id: textMethodClipboard.asm,v 1.1 97/04/07 11:17:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextInstance	segment	resource



COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextClipboardSelectAll -- MSG_CLIPBOARD_SELECT_ALL
						for VisTextClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 9/91		Initial version

------------------------------------------------------------------------------@
VisTextClipboardSelectAll	method dynamic	VisTextClass,
					MSG_META_SELECT_ALL

	sub	sp, size VisTextRange
	mov	bp, sp

	clr	ax
	clrdw	ss:[bp].VTRP_range.VTR_start
	movdw	ss:[bp].VTRP_range.VTR_end, TEXT_ADDRESS_PAST_END

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock		; Replace the text

	add	sp, size VisTextRange

	ret

VisTextClipboardSelectAll	endm

TextInstance	ends
