COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Convert
FILE:		convertScrapbook.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains utility stuff for converting from 1.X to 2.0

	$Id: convertScrapbook.asm,v 1.1 97/04/04 17:52:47 newdeal Exp $

------------------------------------------------------------------------------@

ConvertScrapbook segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertOldScrapbookDocument

DESCRIPTION:	Convert a 1.X Scrapbook document

CALLED BY:	INTERNAL

PASS:
	bp - VM file handle
RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/28/92	Initial version

------------------------------------------------------------------------------@
ConvertOldScrapbookDocument	proc	far

	uses ax, bx, cx, dx, si, di, ds, es, bp

	.enter

	mov	bx, bp				; bx = file handle

	; lock the map block

	call	VMGetMapBlock			; ax = map block
	call	VMLock
	call	VMDirty				; make sure we dirty the map
						;	block
	push	bp
	mov	ds, ax				; ds = map block
	mov	cx, ds:[SBIH_numScraps]		; cx = number of scraps
	tst	cx
	LONG jz	done

	; convert each scrap

	mov	si, size SBIH_numScraps
convertScrapLoop:
	push	cx				; save entry count

	pushdw	dssi				; save index entry
	mov	ax, ds:[si]			; ax = VM block of transfer
						;	item header
	;
	; create a new ClipboardItemHeader to hold the OldClipboardItemHeader
	; contents
	;	bx = VM file
	;	ax = VM block handle of OldClipboardItemHeader
	;
	call	VMLock
	push	bp
	mov	ds, ax				; ds = OldClipboardItemHeader

	mov	cx, size ClipboardItemHeader
	call	VMAlloc				; ax = new ClipboardItemHeader
	push	ax
	call	VMLock
	push	bp
	mov	es, ax				; es = ClipboardItemHeader

	clrdw	es:[CIH_owner]
	clrdw	es:[CIH_sourceID]
	clrdw	es:[CIH_reserved]

	mov	ax, ds:[OCIH_flags]
	mov	es:[CIH_flags], ax

	mov	si, offset OCIH_name
	mov	di, offset CIH_name
	mov	cx, size CIH_name
	rep movsb

	mov	cx, ds:[OCIH_formatCount]
	mov	es:[CIH_formatCount], cx

	mov	si, offset OCIH_formats
	mov	bp, offset OCIH_handles
	mov	di, offset CIH_formats
convertFormatLoop:
	mov	ax, ds:[si]			; ax = old format
	mov	es:[di].CIFI_format.CIFID_type, ax
	mov	es:[di].CIFI_format.CIFID_manufacturer, MANUFACTURER_ID_GEOWORKS
	mov	ax, ds:[bp].OCIH_vmBlock
	mov	es:[di].CIFI_vmChain.high, ax
	mov	es:[di].CIFI_vmChain.low, 0
	mov	ax, ds:[bp].OCIH_extra1
	mov	es:[di].CIFI_extra1, ax
	mov	ax, ds:[bp].OCIH_extra2
	mov	es:[di].CIFI_extra2, ax
	movdw	es:[di].CIFI_renderer.GT_chars, 0
	mov	es:[di].CIFI_renderer.GT_manufID, 0
	cmp	es:[di].CIFI_format.CIFID_type, CIF_GRAPHICS_STRING
	je	convertGString
	cmp	es:[di].CIFI_format.CIFID_type, CIF_TEXT
	je	convertText
	;
	; unrecognized format, just clear the format
	;
clearFormat:
	clr	ax
	xchg	es:[di].CIFI_vmChain.high, ax	; ax = old VM block
	push	bp
	clr	bp
	call	VMFreeVMChain
	pop	bp
	jmp	short convertNextFormat

convertText:
	push	si, cx
	mov	si, bx				; si = VM file
	mov	cx, es:[di].CIFI_vmChain.high	; cx = old text transfer format
	mov	dx, -1				; free old format
	call	ConvertOldTextTransfer		; ax = new text transfer format
	pop	si, cx
	mov	es:[di].CIFI_vmChain.high, ax	; save new transfer format
	jmp	short convertNextFormat

convertGString:
	push	di, si, cx, bx
	mov	cx, bx				; cx = old VM file
	mov	di, es:[di].CIFI_vmChain.high	; di = old VM block
	mov	dx, bx				; dx = new VM file
	mov	si, mask GSCO_FREE_ORIG_GSTRING
	call	ConvertGString
	mov	ax, di				; ax = new VM block
	pop	di, si, cx, bx
	jc	clearFormat			; error, just clear format
	mov	es:[di].CIFI_vmChain.high, ax	; save new chain

convertNextFormat:
	add	si, size ClipboardItemFormat
	add	bp, size OldClipboardItemHandle
	add	di, size ClipboardItemFormatInfo
	dec	cx
	LONG jnz	convertFormatLoop

	;
	; move to next scrap
	;
	pop	bp
	call	VMUnlock			; unlock ClipboardItemHeader

	pop	cx				; cx = ClipboardItemHeader block

	pop	bp
	call	VMUnlock			; unlock OldClipboardItemHeader
	popdw	dssi				; restore index entry

	mov	ax, ds:[si]			; ax = OldClipboardItemHeader
	call	VMFree

	mov	ds:[si], cx			; store new ClipboardItemHeader

	pop	cx				; restore entry count
	add	si, size ScrapBookIndexEntry
	dec	cx
	LONG jnz	convertScrapLoop

done:
	pop	bp
	call	VMUnlock			; unlock updated map block

	.leave
	ret

ConvertOldScrapbookDocument	endp

ConvertScrapbook ends
