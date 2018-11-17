COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Convert
FILE:		convertText.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains utility stuff for converting from 1.X to 2.0

	$Id: convertGeoWrite.asm,v 1.1 97/04/04 17:52:45 newdeal Exp $

------------------------------------------------------------------------------@

ConvertText segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertOldGeoWriteDocument

DESCRIPTION:	Convert a 1.X GeoWrite document

CALLED BY:	INTERNAL

PASS:
	si - VM file handle
	cx - 1.2 map block
	ss:di - PageSetupInfo structure to fill in
	ss:bp - ConvertOldGWParams
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
	Tony	10/18/92		Initial version

------------------------------------------------------------------------------@
ConvertOldGeoWriteDocument	proc	far uses ax, bx, cx, dx, si, di, ds, es
fileHandle		local	hptr	push	si
gotHeaderFooterFlag	local	word
vmMemHandle		local	word
mapBlockMemHandle	local	word
	ForceRef fileHandle
	class	VisCompClass		;we must look at linkage
	.enter

	mov	gotHeaderFooterFlag, 0

	; lock the map block

	mov	bx, si
	mov_tr	ax, cx
	push	bp
	call	VMLock
	mov	ds, ax				;ds = map block
	mov_tr	ax, bp
	pop	bp
	mov	mapBlockMemHandle, ax
	mov	ss:[di].PSI_meta.VMCL_next, 0

	; ----------- get the page setup info ----------------

	; get the page size -- deal with the hack (there might be an
	; extended page size, there might not be one)

	mov	si, ds:[GW12_DOCUMENT_DATA_CHUNK]	;ds:si = data
	mov	cx, ds:[si].GW12_WDD_extendedPageSize.XYS_width
	mov	dx, ds:[si].GW12_WDD_extendedPageSize.XYS_height
	test	ds:[si].GW12_WDD_attrs, mask GW12_WDA_USES_EXTENDED_SIZE
	jnz	gotPageSize

	; old style page size

	mov	cx, ds:[si].GW12_WDD_pageSetup.GW12_PSA_oldPageSize
	clr	ax
	mov	al, cl				;al = width
	mov	bl, 9
	mul	bl				;ax = width
	push	ax				;save width

	clr	ax
	mov	al, ch				;al = height
	mul	bl				;ax = height
	mov	dx, ax				;dx = height
	pop	cx				;cx = width
gotPageSize:
	cmp	ds:[si].GW12_WDD_pageSetup.GW12_PSA_orientation,GW12_PO_PORTRAIT
	jz	notLandscape
	xchg	cx, dx
notLandscape:
	mov	ss:[di].PSI_pageSize.XYS_width, cx
	mov	ss:[di].PSI_pageSize.XYS_height, dx

	mov	ax, PT_PAPER or (PO_LANDSCAPE shl offset PLP_ORIENTATION)
	cmp	ds:[si].GW12_WDD_pageSetup.GW12_PSA_orientation,
							GW12_PO_LANDSCAPE
	jz	gotOrientation
	mov	ax, PT_PAPER or (PO_PORTRAIT shl offset PLP_ORIENTATION)
gotOrientation:
	mov	ss:[di].PSI_layout, ax

	clr	ax
	mov	al, ds:[si].GW12_WDD_pageSetup.GW12_PSA_numColumns
	mov	ss:[di].PSI_numColumns, ax

	mov	al, ds:[si].GW12_WDD_pageSetup.GW12_PSA_columnSpacing
	call	convertPointsByte
	mov	ss:[di].PSI_columnSpacing, ax

	mov	al, ds:[si].GW12_WDD_pageSetup.GW12_PSA_ruleWidth
	call	convertPointsByte
	mov	ss:[di].PSI_ruleWidth, ax

	mov	ax, ds:[si].GW12_WDD_pageSetup.GW12_PSA_margins.R_left
	call	convertPointsWord
	mov	ss:[di].PSI_leftMargin, ax

	mov	ax, ds:[si].GW12_WDD_pageSetup.GW12_PSA_margins.R_top
	call	convertPointsWord
	mov	ss:[di].PSI_topMargin, ax

	mov	ax, ds:[si].GW12_WDD_pageSetup.GW12_PSA_margins.R_right
	call	convertPointsWord
	mov	ss:[di].PSI_rightMargin, ax

	mov	ax, ds:[si].GW12_WDD_pageSetup.GW12_PSA_margins.R_bottom
	call	convertPointsWord
	mov	ss:[di].PSI_bottomMargin, ax

	; ------------- get the text --------------------

	; there is an array of pages using the 1.2 chunk array mechanism

	mov	si, ds:[GW12_PAGE_ARRAY_CHUNK]
	mov	cx, ds:[si].GW12_CAH_count
	add	si, offset GW12_CAH_firstElement

pageLoop:
	push	cx, si, ds
	mov	ax, ds:[si].GW12_PAE_vmBlock
	call	ourVMLockDS			;ds = page block
	mov	si, ds:[GW12_PageContent]	;ds:si = content object

	; luckily Vis and VisComp are the same in 1.X and 2.0

	add	si, ds:[si].Vis_offset
	mov	si, ds:[si].VCI_comp.CP_firstChild.offset	;*ds:si = hdr

	; if this is the first page then copy text from the header and footer

	tst	gotHeaderFooterFlag
	jnz	afterHeader
	mov	bx, ss:[bp]			;ss:bx = ConvertOldGWParams
	movdw	cxdx, ss:[bx].COGWP_headerObj
	mov	di, ss:[bx].COGWP_headerStyle
	push	bp
	mov	bp, fileHandle
	call	ConvertOldTextObject
	pop	bp
afterHeader:

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].VI_link.LP_next.offset	;*ds:si = footer
	tst	gotHeaderFooterFlag
	jnz	afterFooter
	mov	bx, ss:[bp]			;ss:bx = ConvertOldGWParams
	movdw	cxdx, ss:[bx].COGWP_footerObj
	mov	di, ss:[bx].COGWP_footerStyle
	push	bp
	mov	bp, fileHandle
	call	ConvertOldTextObject
	pop	bp
afterFooter:

	mov	gotHeaderFooterFlag, 1

	; get the main text

columnLoop:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	movdw	axsi, ds:[di].VI_link.LP_next
	call	ourVMUnlock			;unlock old
	test	si, LP_IS_PARENT
	jnz	nextPage
	call	RelocToVMBlock
	call	ourVMLockDS			;*ds:si = column

	mov	bx, ss:[bp]			;ss:bx = ConvertOldGWParams
	movdw	cxdx, ss:[bx].COGWP_mainObj
	mov	di, ss:[bx].COGWP_mainStyle
	push	bp
	mov	bp, fileHandle
	call	ConvertOldTextObject
	pop	bp
	jmp	columnLoop

nextPage:
	pop	cx, si, ds
	add	si, size GW12_PageArrayElement
	dec	cx
	LONG jnz pageLoop

	push	bp
	mov	bp, mapBlockMemHandle
	call	VMUnlock
	pop	bp

	.leave
	ret	@ArgSize

;---

convertPointsByte:
	clr	ah
convertPointsWord:
	shl	ax
	shl	ax
	shl	ax
	retn

;---

ourVMLockDS:
	mov	bx, fileHandle
	push	bp
	call	VMLock
	mov	ds, ax
	mov_tr	ax, bp
	pop	bp
	mov	vmMemHandle, ax
	retn

;---

ourVMUnlock:
	push	bp
	mov	bp, vmMemHandle
	call	VMUnlock
	pop	bp
	retn

ConvertOldGeoWriteDocument	endp

ConvertText ends
