
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		formatUtils

AUTHOR:		Cheng, 4/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	4/92		Initial revision

DESCRIPTION:
		
	$Id: formatUtils.asm,v 1.1 97/04/05 01:23:37 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatUseFreeFormatEntry

DESCRIPTION:	Tries to locate a free FormatEntry.  If none is found,
		resize the format array to create one.

CALLED BY:	INTERNAL (FloatFormatAddEntry)

PASS:		es - segment of format array
		bx - handle of format array

RETURN:		carry clear if successful
		    es:di - format entry
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatUseFreeFormatEntry	proc	near	uses	cx,dx
	.enter

	mov	di, size FormatArrayHeader	; es:di <- first format entry
	mov	cx, size FormatEntry		; cx <- size of an entry
	mov	dx, es:FAH_formatArrayEnd	; dx <- end

searchLoop:
	cmp	es:[di].FE_used, 0	; free?
	je	done			; branch if so

EC<	call	ECCheckUsedEntry >
	add	di, cx			; di <- addr of next boolean
	cmp	di, dx			; past end?
	jb	searchLoop		; loop if not

	;
	; all entries taken, expansion needed
	;
	mov	ax, dx			; ax <- current size in bytes
	add	ax, cx			; inc ax by size of entry
	push	ax			; save end of array
	mov	ch, mask HAF_LOCK or mask HAF_ZERO_INIT
	call	MemReAlloc
	pop	di			; retrieve end of array
	jc	error

	mov	es, ax
	mov	es:FAH_formatArrayEnd, di
	inc	es:FAH_numFormatEntries
	sub	di, size FormatEntry	; di <- offset to empty entry

	mov	es:[di].FE_used, -1	; mark as used
EC<	mov	es:[di].FE_sig, FORMAT_ENTRY_SIG >	; stuff ec signature
done:
	mov	es:[di].FE_used, -1	; mark entry as used
	clc

exit:
	.leave
	ret
FloatFormatUseFreeFormatEntry	endp
