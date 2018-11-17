
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
		
	$Id: spreadsheetFormatInit.asm,v 1.1 97/04/07 11:13:27 newdeal Exp $

-------------------------------------------------------------------------------@

if 0
InitCode	segment resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatInit

DESCRIPTION:	Initialize a new format array.

CALLED BY:	INTERNAL (SpreadsheetNew)

PASS:		bx - VM file handle

RETURN:		ax - VM handle of format array

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatInit	proc	near	uses	bx,cx,dx,bp,es,di
	class	SpreadsheetClass
	.enter

	;
	; Allocate a block to use for the format array
	;
	clr	ax				; ax <- no user ID
	mov	cx, size FormatArrayHeader + size FormatEntry
						; saves a VMAttach later
	call	VMAlloc
	push	ax				;save VM handle

	;
	; Lock and initalize the block
	;
	call	VMLock				; ax <- seg addr of block
	mov	es, ax				; es <- seg addr of block

	;
	; initialize the format array header
	;
	mov	es:FAH_signature, FORMAT_ARRAY_HDR_SIG
	mov	es:FAH_numFormatEntries, 1
	mov	es:FAH_numUserDefEntries, 0
	mov	es:FAH_formatArrayEnd, cx

	;
	; initialize the the first format entry
	;
	mov	di, size FormatArrayHeader
	mov	es:[di].FE_used, 0		; indicate entry free
EC<	mov	es:[di].FE_sig, FORMAT_ENTRY_SIG >

	;
	; Mark the block as dirty and release it
	;
	call	VMDirty
	call	VMUnlock
	pop	ax				;ax <- VM handle of array

	.leave
	ret
FormatInit	endp

InitCode	ends
endif
