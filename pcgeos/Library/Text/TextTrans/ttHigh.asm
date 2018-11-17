COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextTrans
FILE:		ttHigh.asm

AUTHOR:		John Wedgwood, Oct 25, 1989

METHODS:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/25/89		Initial revision

DESCRIPTION:

	$Id: ttHigh.asm,v 1.1 97/04/07 11:19:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextTransfer segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextCut -- MSG_META_CLIPBOARD_CUT for VisTextClass

DESCRIPTION:	Cut the selected area to the clipboard

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
VisTextCut	proc	far		; MSG_META_CLIPBOARD_CUT
	call	CheckSelectionCrossSection
	jc	done

	mov	ax, offset CutString
	call	TU_StartChainIfUndoable

	mov	ax, MSG_META_CLIPBOARD_COPY
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_DELETE
	call	ObjCallInstanceNoLock

	GOTO	TU_EndChainIfUndoable

done:
	ret


VisTextCut	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextCopy -- MSG_META_CLIPBOARD_COPY for VisTextClass

DESCRIPTION:	Copy the selected area to the clipboard

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
VisTextCopy	proc	far		; MSG_META_CLIPBOARD_COPY
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	mov	ax, ATTR_VIS_TEXT_ALLOW_CROSS_SECTION_COPY
	call	ObjVarFindData
	jc	allowCrossSection

	call	CheckSelectionCrossSection
	jc	done

allowCrossSection:
	call	ClipboardGetClipboardFile		;bx = VM file
	tst	bx
	jz	done

	clr	ax				; generate me one, please
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; owner is ourself
	mov	di, -1				; standard name
	call	GenerateTransferItem		;ax = VM block, bx = VM file
	clr	bp				;not RAW, not QUICK
	call	ClipboardRegisterItem

done:
	pop	di
	call	ThreadReturnStackSpace
	ret

VisTextCopy	endp

;---

CheckSelectionCrossSection	proc	near

	; make sure that the current selection does not cross sections

	call	TSL_SelectGetSelection		;dxax = start, cxbx = end
	pushdw	cxbx				; Push the end
	pushdw	dxax				; Push the start
	mov	bp, sp				; ss:bp <- ptr to the range

	call	TR_CheckCrossSectionChange	; Carry set if cross section
	popdw	dxax
	popdw	cxbx
	ret

CheckSelectionCrossSection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEnoughDiskSpaceToAllocateItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the text selection is too large with respect to disk
		space. We want to prevent zero disk space situation when the
		clipbard file is written to disk.

CALLED BY:	INTERNAL
PASS:		bx	= clipboard file handle
		*ds:si	= VisTextClass instance data
RETURN:		carry set if not enough space,
		carry clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		To get available disk space:
			DiskGetVolumeFreeSpace(FileGetDiskHandle(fileHandle))

		We need to make sure:
		(disk space needed for selection +    <---------------(*)
		clipboard dirty size +
		MIN_DISK_SPACE_AFTER_TEXT_COPY) > current disk space

		(*) disk space needed == selection size * 1.25,
		    an estimation of course.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextPaste -- MSG_META_CLIPBOARD_PASTE for VisTextClass

DESCRIPTION:	Paste the selected from to the clipboard

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

RETURN:
	carry set if the paste was unsuccessful for any reason.

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
VisTextPaste	proc	far		; MSG_META_CLIPBOARD_PASTE
	class	VisTextClass

	test	ds:[di].VTI_state, mask VTS_EDITABLE
	stc
	jz	done

	mov_tr	ax, di
	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di
	mov_tr	di, ax

	; Set the adjust type to AT_PASTE sothat the selection is adjusted
	; properly

	mov	al, ds:[di].VTI_intFlags
	and	al, not mask VTIF_ADJUST_TYPE
	push	ax
	or	al, AT_PASTE shl offset VTIF_ADJUST_TYPE
	mov	ds:[di].VTI_intFlags, al

	mov	dx, VIS_TEXT_RANGE_SELECTION	;dxax, cxbx = range
	clr	di				;normal transfer
	clr	bp				;no stack frame
	call	PasteCommon			;carry <- error status.

	pop	ax
	pushf
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	and	ds:[di].VTI_intFlags, not mask VTIF_ADJUST_TYPE
	or	ds:[di].VTI_intFlags, al
	popf

	lahf
	pop	di
	call	ThreadReturnStackSpace
	sahf

done:
	ret


VisTextPaste	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	PasteCommon

DESCRIPTION:	Paste in a range of text

CALLED BY:	VisTextPaste, VisTextEndMoveCopy

PASS:
	*ds:si - text object
	dx.ax - TextRangePart1
	cx.bx - TextRangePart2
	di - transfer flags (ClipboardItemFlags)
	ss:bp - inherited variables (for quick transfer)

RETURN:
	carry - set if error

DESTROYED:
	ax, cx, dx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

	.assert	RWGP_range eq CTP_range

PCP_union	union
    PCPU_text		CommonTransferParams
    PCPU_graphics	ReplaceWithGraphicParams
PCP_union	end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  If you change this following definition, make sure it is updated ;;;
;;;  in /Appl/TEdit/tedit.asm as well.			              ;;;
;;;  ptrinh 5/26/95		      				      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PasteCommonParams	struct
    PCP_data		PCP_union
    PCP_vmFile		word			;VM file
    PCP_header		word			;VM block of transfer header
    PCP_quickFlags	ClipboardQuickNotifyFlags

    PCP_flags		ClipboardItemFlags
    PCP_quickFrame	word
PasteCommonParams	ends

;-

PasteCommon	proc	near
	class	VisTextClass

	push	bp				;PCP_quickFrame
	push	di				;PCP_flags
	sub	sp, size PasteCommonParams - 4
	mov	bp, sp
	movdw	ss:[bp].PCP_data.PCPU_text.CTP_range.VTR_start, dxax
	movdw	ss:[bp].PCP_data.PCPU_text.CTP_range.VTR_end, cxbx

	push	bp
	mov	bp, di				;bp = flags
	call	ClipboardQueryItem		;bp = # formats, cx:dx = owner
						;bx = VM file, ax = VM block
	mov	di, bp				; di = # formats
	pop	bp

	mov	ss:[bp].PCP_header, ax
	mov	ss:[bp].PCP_vmFile, bx

	; does CIF_TEXT format exist ?

	tst	di
	stc
	LONG jz	done				;no formats -> error
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT
	call	ClipboardTestItemFormat
	jnc	foundText

	; how about CIF_GRAPHICS_STRING ?

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING		;format to search for
	call	ClipboardTestItemFormat
	jc	done

	; found graphics string -- can only use this if the object supports it
	;	dx = CIF_GRAPHICS_STRING

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_GRAPHICS
	stc
	jz	done

foundText:
	mov	ax, offset PasteString
	call	TU_StartChainIfUndoable
	push	bp
	push	dx				;save format
	mov	bx, ss:[bp].PCP_vmFile
	mov	ax, ss:[bp].PCP_header
	mov	bp, ss:[bp].PCP_flags
	mov	cx, MANUFACTURER_ID_GEOWORKS		;cx:dx = complete format
	call	ClipboardRequestItemFormat		;bx = VM file, ax = VM block
						;cx,dx = extra data
	pop	bp				;bp = format
	cmp	bp, CIF_TEXT
	pop	bp
	jz	text

	; pasting a graphic -- copy in the default graphic

	push	si, ds
	segmov	ds, cs
	mov	si, offset defaultGraphic	;ds:si = source
	lea	di, ss:[bp].PCP_data.PCPU_graphics.RWGP_graphic
	segmov	es, ss				;es:di = dest
	mov	cx, size VisTextGraphic
	rep	movsb
	pop	si, ds

	mov	ss:[bp].PCP_data.PCPU_graphics.RWGP_sourceFile, bx
	mov	ss:[bp].PCP_data.PCPU_graphics.RWGP_graphic.VTG_vmChain.high, ax

	call	FindDrawOffsetForGraphic

	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC
	jmp	common

text:

	; pasting text

	mov	cx, ss:[bp].PCP_vmFile
	mov	ss:[bp].PCP_data.PCPU_text.CTP_vmFile, cx
	mov	ss:[bp].PCP_data.PCPU_text.CTP_vmBlock, ax
	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
common:

	; Invoke some method (replace with graphic, replace with text) that
	; will let us know if there was an error.

	mov	ss:[bp].PCP_data.PCPU_text.CTP_pasteFrame, bp

	call	ObjCallInstanceNoLock
	call	TU_EndChainIfUndoable
;	jc	done				;quit if error.
done:
	pushf
	mov	ax, ss:[bp].PCP_header
	mov	bx, ss:[bp].PCP_vmFile
	call	ClipboardDoneWithItem
	popf

	lahf					;save flags around the 'add'
	add	sp, size PasteCommonParams - 2
	pop	bp
	sahf					;reset carry flag for return.
	ret

PasteCommon	endp

defaultGraphic	VisTextGraphic <
    <				;VTG_meta.
	<>,			;    REH_refCOunt
    >,
    0,				;VTG_vmChain
    <0, 0>,			;VTG_size
    VTGT_GSTRING,		;VTG_type
    <>,				;VTG_flags
    <>,				;VTG_reserved
    <VTGD_gstring <		;VTG_data
	<>
    >>
>

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindDrawOffsetForGraphic

DESCRIPTION:	Find the drawing offset for a gstring graphic

CALLED BY:	INTERNAL

PASS:
	ss:bp - PasteCommonParams

RETURN:
	none

DESTROYED:
	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/23/92		Initial version

------------------------------------------------------------------------------@
FindDrawOffsetForGraphic	proc	near	uses bx, si, di
	.enter

	; set a default size in case GrGetGStringBounds returns an error

	mov	ss:[bp].PCP_data.PCPU_graphics.RWGP_graphic.\
				VTG_size.XYS_width, 10
	mov	ss:[bp].PCP_data.PCPU_graphics.RWGP_graphic.\
				VTG_size.XYS_height, 10

	mov	bx, ss:[bp].PCP_vmFile
	mov	si, ss:[bp].PCP_data.PCPU_graphics.RWGP_graphic.VTG_vmChain.high
	mov	cx, GST_VMEM
	call	GrLoadGString			;si = gstring

	clr	di				; No gstate for this part
	clr	dx				; dx <- flags
	call	GrGetGStringBounds		; carry set on overflow
						; ax...dx <- bounds
	pushf
	push	dx
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	pop	dx
	popf

	jc	done				; Quit if error

	sub	cx, ax
	sub	dx, bx
	mov	ss:[bp].PCP_data.PCPU_graphics.RWGP_graphic.\
				VTG_size.XYS_width, cx
	mov	ss:[bp].PCP_data.PCPU_graphics.RWGP_graphic.\
				VTG_size.XYS_height, dx

	neg	ax
	neg	bx
	mov	ss:[bp].PCP_data.PCPU_graphics.RWGP_graphic.VTG_data.\
					VTGD_gstring.VTGG_drawOffset.XYO_x, ax
	mov	ss:[bp].PCP_data.PCPU_graphics.RWGP_graphic.VTG_data.\
					VTGD_gstring.VTGG_drawOffset.XYO_y, bx

done:
	.leave
	ret

FindDrawOffsetForGraphic	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenerateTransferItem

DESCRIPTION:	Generate a transfer item for the currently selected area

CALLED BY:	

PASS:
	*ds:si - VisTextInstance
	ax - if non-zero then ax is the transfer format to use
	bx - vm file
	cx:dx - optr to be the source and owner of the transfer (0 for self)
	es:di - name for transfer (di = -1 for default)

RETURN:
	ax - VM block of transfer item (in clipboard's VM file)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
GenerateTransferItem	proc	near	uses cx, dx, si, di, bp, ds, es
	class	VisLargeTextClass
	.enter

	sub	sp, size CommonTransferParams
	mov	bp, sp

	mov	ss:[bp].CTP_vmFile, bx

	; get the selected text into a block

	tst	ax
	jnz	haveFormat

	mov	ss:[bp].CTP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	mov	ax, MSG_VIS_TEXT_CREATE_TRANSFER_FORMAT
	pushdw	cxdx
	call	ObjCallInstanceNoLock			;ax <- vm block handle
	popdw	cxdx
haveFormat:
	push	di				;save name offset

	push	ax				;save format

	; put the size of the object in the extra data

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].VI_bounds.R_bottom
	sub	ax, ds:[di].VI_bounds.R_top
	cmp	ax, PIXELS_PER_INCH * 10
	jb	10$
	clr	ax
10$:
	push	ax				;save height

	push	cx, dx, bp
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	LONG jnz oneLineObject

	; if there are no regions for a large object then use 0

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	figureMargins

	clr	ax
	cmp	ds:[di].VLTI_regionArray, ax
	jz	common

figureMargins:
	movdw	dxax, ds:[di].VTI_selectStart
	sub	sp, size VisTextMaxParaAttr
	mov	bp, sp
	clr	cx				; cx <- region
	clr	bx				; bx <- Y position
	clr	di				; di <- height of line at <bx>
	call	TA_GetParaAttrForPosition	; Fill in attr structure
	mov	ax, ss:[bp].VTPA_rightMargin
	sub	ax, ss:[bp].VTPA_leftMargin
	add	sp, size VisTextMaxParaAttr	; Restore stack
common:
	pop	cx, dx, bp
	push	ax				;save width

	; allocate block for transfer structure

	push	cx
	mov	ax, size ClipboardItemHeader
	mov	cx,ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	ds, ax				;ds = transfer item
	pop	cx

	; set up header

	movdw	ds:[CIH_sourceID], cxdx
	movdw	ds:[CIH_owner], cxdx
	mov	ds:[CIH_formatCount], 1
	mov	ds:[CIH_formats][0].CIFI_format.CIFID_manufacturer, \
							MANUFACTURER_ID_GEOWORKS
	mov	ds:[CIH_formats][0].CIFI_format.CIFID_type, CIF_TEXT
	pop	ds:[CIH_formats][0].CIFI_extra1		;extra1 = width
	pop	ds:[CIH_formats][0].CIFI_extra2		;extra2 = height
	pop	ds:[CIH_formats][0].CIFI_vmChain.high
	clr	ds:[CIH_formats][0].CIFI_vmChain.low

	; copy name

	pop	si				; es:si <- name
	push	bx				;save mem handle
	clr	bx				;bx = handle to unlock
	segxchg	ds, es				;ds:si = name
	mov	di, offset CIH_name		;es:di = dest

	mov	cx, (length CIH_name) - 1
	cmp	si, -1
	jnz	namePassed
	mov	bx, handle textTransferItemName
	call	MemLock				;Lock the strings resource
	mov	ds, ax
	mov	si, ds:textTransferItemName
namePassed:
	LocalGetChar	ax, dssi
	LocalPutChar	esdi, ax
	LocalIsNull	ax
	loopne	namePassed
	clr	ax			; Always force a NULL..
	LocalPutChar	esdi, ax

	tst	bx
	jz	noUnlock
	call	MemUnlock			;Unlock the strings resource
noUnlock:

	pop	bx				;Restore mem handle
	call	MemUnlock

	mov	cx, bx				;cx = memory handle
	mov	bx, ss:[bp].CTP_vmFile		;bx = VM file
	clr	ax				;allocate new VM block
	call	VMAttach			;ax = VM block

	call	GenerateGStringFormatIfAppropriate

	add	sp, size CommonTransferParams

	.leave
	ret

	; Handle a one-line text object differently, as its right margin
	; is set to an enormous value
oneLineObject:
	clrdw	bxdi				; bx.di <- line to check
	movdw	dxax, -1			; Move to line end
	mov	bp, 0x7fff			; Find this position
	call	TL_LineTextPosition		; bx <- Offset from line-left
	mov_tr	ax, bx				
	jmp	common
GenerateTransferItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateGStringFormatIfAppropriate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the transfer item involves a single character covered
		by a gstring graphic run, then duplicate the gstring into
		a CIF_GSTRING transfer format also, to allow graphics
		within the text layer to be edited.

CALLED BY:	(INTERNAL) GenerateTransferItem
PASS:		^vbx:ax	= ClipboardItemHeader
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	CIH_numFormats may be upped and the graphics string duplicated

PSEUDO CODE/STRATEGY:
		See if only one character in transfer item.
		See if any graphic runs in transfer item.
		See if sole graphic in graphicElements array is for gstring
		If all of the above are true, draw the graphic into a new
			gstring and store that gstring as the second format
			(CIF_GRAPHICS_STRING)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateGStringFormatIfAppropriate proc	near
	uses	ax, cx, dx, si, di, bp, ds
	.enter
	push	ax
	call	VMLock
	mov	ds, ax
	mov	cx, ds:[CIH_formatCount]
	mov	si, offset CIH_formats
findTextFormatLoop:
	cmp	ds:[si].CIFI_format.CIFID_manufacturer, MANUFACTURER_ID_GEOWORKS
	jne	nextFormat
	cmp	ds:[si].CIFI_format.CIFID_type, CIF_TEXT
	je	foundIt
nextFormat:
	add	si, size ClipboardItemFormatInfo
	loop	findTextFormatLoop
	jmp	doNothing

foundIt:
	mov	ax, ds:[CIH_formats][0].CIFI_vmChain.high
	call	VMUnlock
	call	VMLock
	mov	ds, ax		; ds <- TextTransferBlockHeader
	;
	; Find amount of text in transfer. If not 2 characters (C_GRAPHIC +
	; NULL), it's not something we need worry about.
	; 
	mov	di, ds:[TTBH_text].high
	call	HugeArrayGetCount
	tst	dx
	jnz	doNothing
	cmp	ax, 2
	jne	doNothing
	
	;
	; Only one character (plus null) in the array. See if any graphic runs.
	; 
	mov	di, ds:[TTBH_graphicRuns].high
	tst	di 
	jz	doNothing		; => no graphics
	call	HugeArrayGetCount
	cmp	ax, 2
	jne	doNothing		; => no runs (always an ending run)

	;
	; See if the graphic in question is a gstring graphic.
	; 
	mov	ax, ds:[TTBH_graphicElements].high
	call	VMUnlock
	call	VMLock
	mov	ds, ax
	push	si
	mov	si, ds:[LMBH_offset]	; si <- first chunk
	clr	ax
	call	ChunkArrayElementToPtr
	pop	si
	cmp	ds:[di].VTG_type, VTGT_GSTRING
	jne	doNothing
	tstdw	ds:[di].VTG_vmChain
	jne	createFormat
doNothing:
	call	VMUnlock		; we've got *something* locked when
					;  we get here
	pop	ax			; clear header block from stack
	jmp	done

createFormat:
	push	si			; save offset of CIF_TEXT format
					;  for later biffing.
	;
	; It is! Wheee. First create a graphics string to which we can copy
	; the graphic in all its glory.
	; 
	push	di			; save array element addr
	mov	cl, GST_VMEM
	call	GrCreateGString
	pop	ax

	push	si			; save vm block handle
	push	bx			; save VM file handle

	mov_tr	bx, ax			; ds:bx <- VisTextGraphic

	;
	; Apply the requisite transformation for drawing the thing.
	; 
	lea	si, ds:[bx].VTG_data.VTGD_gstring.VTGG_tmatrix
	call	GrApplyTransform
	
	;
	; Move to the proper drawing location.
	; 
	push	bx
	mov	dx, ds:[bx].VTG_data.VTGD_gstring.VTGG_drawOffset.XYO_x
	clr	cx
	mov	bx, ds:[bx].VTG_data.VTGD_gstring.VTGG_drawOffset.XYO_y
	clr	ax
	call	GrRelMoveTo
	pop	bx
	
	;
	; Load up the gstring in question.
	; 
	mov	si, ds:[bx].VTG_vmChain.high
EC <	tst	ds:[bx].VTG_vmChain.low					>
EC <	ERROR_NZ	GRAPHIC_IN_TRANSFER_ITEM_NOT_VM_BASED_GSTRING	>
	pop	bx		; ^vbx:si <- source gstring
	push	bx
	mov	cx, GST_VMEM
	call	GrLoadGString		; si <- source gstring
	;
	; Draw that string to the destination one.
	; 
	clr	dx
	call	GrDrawGStringAtCP
	;
	; Free the structures for the source string.
	; 
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString

	call	VMUnlock		; unlock the graphicElements block
	
	call	GrEndGString
	cmp	ax, GSET_NO_ERROR
	jne	messedUp
	
	;
	; Rewind the new gstring and figure its bounds so we can set the
	; CIFI_extra words appropriately.
	;
	mov	si, di
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos
	
	clr	di, dx			; no associated state, go to end
	call	GrGetGStringBounds
	jc	messedUpHaveSI
	
	sub	dx, bx			; dx <- height
	sub	cx, ax			; cx <- width
	
	;
	; Nuke the attendant structures, leaving the raw VM data around.
	; 
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString

	pop	bx			; bx <- VM file
	pop	si			; si <- VM block handle of string
	pop	di			; di <- offset of CIFI to nuke
	pop	ax			; ax <- header
	
	;
	; Now replace the text format with this one.
	; 
	call	VMLock
	mov	ds, ax			; ds <- ClipboardItemHeader

	push	bp			; free all the blocks that make up
	movdw	axbp, ds:[di].CIFI_vmChain	; the text format
	call	VMFreeVMChain
	pop	bp

	mov	ds:[di].CIFI_extra1, cx
	mov	ds:[di].CIFI_extra2, dx
	mov	ds:[di].CIFI_vmChain.high, si
	mov	ds:[di].CIFI_vmChain.low, 0
	mov	ds:[di].CIFI_format.CIFID_manufacturer, MANUFACTURER_ID_GEOWORKS
	mov	ds:[di].CIFI_format.CIFID_type, CIF_GRAPHICS_STRING
	mov	ds:[di].CIFI_renderer.GT_chars[0], 0
	mov	ds:[di].CIFI_renderer.GT_manufID, 0
	
	call	VMDirty
	call	VMUnlock
done:
	.leave
	ret

messedUp:
	mov	si, di			; si <- gstring handle
	clr	di
messedUpHaveSI:
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString
	pop	bx			; bx <- vm file
	pop	si			; clear dead string's block handle
	pop	ax			; discard CIFI offset
	pop	ax			; clear header handle
	jmp	done
GenerateGStringFormatIfAppropriate endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextAllocClipboardObject

DESCRIPTION:	Allocate am temporary object associated with the clipboard
		file for purposes of producing a transfer item.

CALLED BY:	GLOBAL

PASS:
	al - VisTextStorageFlags for object
	ah - non-zero to create regions for object
	bx - file to associate ovbject with or 0 for clipboard file

RETURN:
	^lbx:si - object

DESTROYED:
	none (See NOTE below)

	*NOTE*
	
	If DS is pointing at object block before passing to this
	routine, it may NOT point at the same object block upon
	return. 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/24/92		Initial version

------------------------------------------------------------------------------@
TextAllocClipboardObject	proc	far	uses ax, cx, di, es
	.enter

	push	ax
	push	bx

	; allocate object in a new block

	mov	ax, TGIT_THREAD_HANDLE
	clr	bx
	call	ThreadGetInfo			;ax = current thread
	mov_tr	bx, ax
	call	UserAllocObjBlock		;bx = block

	mov	di, segment VisLargeTextClass
	mov	es, di
	mov	di, offset VisLargeTextClass
	call	ObjInstantiate			;bx:si = object

	; associate the object with the passed file or clipboard file

	pop	cx				;cx = file passed
	tst	cx
	jnz	gotFile
	push	bx
	call	ClipboardGetClipboardFile
	mov	cx, bx
	pop	bx
gotFile:
	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	clr	di
	call	ObjMessage

	; convert to a large text object

	mov	ax, MSG_VIS_LARGE_TEXT_CREATE_DATA_STRUCTURES
	clr	di
	call	ObjMessage

	; make appropriate structures

	pop	cx
	mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
	clr	di
	call	ObjMessage

	; its ready to go -- return it

	.leave
	ret

TextAllocClipboardObject	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextFinishWithClipboardObject

DESCRIPTION:	Finish with an object created by TextAllocClipboardObject

CALLED BY:	INTERNAL

PASS:
	^lbx:si - object
	ax - TextClipboardOption
	cx:dx - owner for clipboard item
	es:di - name for clipboard item (di = -1 for default)

RETURN:
	ax - transfer item handle (if ax passed non-zero)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/24/92		Initial version

------------------------------------------------------------------------------@
TextFinishWithClipboardObject	proc	far uses bx, cx, dx, si, di, bp, ds, es
clipowner	local	optr	\
		push	cx, dx
clipname	local	fptr	\
		push	es, di
	class	VisTextClass
	.enter

if ERROR_CHECK
	;
	; Validate that the name passed is *not* in a movable code segment
	;
FXIP<	cmp	di, -1							>
FXIP<	jz	nameNotPassed						>
FXIP<	push	bx, si							>
FXIP<	movdw	bxsi, esdi						>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
FXIP<nameNotPassed:							>
endif
	mov	cx, ax				;cx = TextClipboardOption

	push	bx
	call	ObjLockObjBlock
	mov	ds, ax				;*ds:si = object

	; first we need to create a transfer format...

	push	cx				;push TextClipboardOption
	call	T_GetVMFile			; bx = VM file
	call	CreateTransferFormatHeader	;ax = header
	push	ax, bp
	call	VMLock
	mov	es, ax

	; *** text ***

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].VTI_text
	mov	es:TTBH_text.high, ax

	mov	cl, ds:[di].VTI_storageFlags

	; *** char attr ***

	test	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	jz	noCharAttr
	mov	ax, ds:[di].VTI_charAttrRuns
	mov	es:TTBH_charAttrRuns.high, ax
	call	getElementBlock			;ax = vm element block
	mov	es:TTBH_charAttrElements.high, ax
noCharAttr:

	; *** para attr ***

	test	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	jz	noParaAttr2
	mov	ax, ds:[di].VTI_paraAttrRuns
	mov	es:TTBH_paraAttrRuns.high, ax
	call	getElementBlock			;ax = vm element block
	mov	es:TTBH_paraAttrElements.high, ax
noParaAttr2:

	; *** types ***

	test	cl, mask VTSF_TYPES
	jz	noTypes
	mov	ax, ATTR_VIS_TEXT_TYPE_RUNS
	call	getVarData
	mov	es:TTBH_typeRuns.high, ax
	call	getElementBlock			;ax = vm element block
	mov	es:TTBH_typeElements.high, ax
	mov	ax, ATTR_VIS_TEXT_NAME_ARRAY
	call	getVarData
	mov	es:TTBH_names.high, ax
noTypes:

	; *** graphics ***

	test	cl, mask VTSF_GRAPHICS
	jz	noGraphics
	mov	ax, ATTR_VIS_TEXT_GRAPHIC_RUNS
	call	getVarData
	mov	es:TTBH_graphicRuns.high, ax
	call	getElementBlock			;ax = vm element block
	mov	es:TTBH_graphicElements.high, ax
noGraphics:

	; *** styles ***

	test	cl, mask VTSF_STYLES
	jz	noStyles
	mov	ax, ATTR_VIS_TEXT_STYLE_ARRAY
	call	getVarData
	mov	es:TTBH_styles.high, ax
noStyles:
	call	MakeTransferFormatNotLMem

	call	VMUnlock

	pop	ax, bp				;ax = format block
	pop	cx				;cx = TextClipboardOption

	cmp	cx, TCO_RETURN_NOTHING
	jnz	noFree
	push	bp
	clr	bp
	call	VMFreeVMChain
	pop	bp
EC <	mov	ax, 0xcccc						>
noFree:

	cmp	cx, TCO_RETURN_NOTHING
	jz	haveReturnValue

	cmp	cx, TCO_RETURN_TRANSFER_FORMAT
	jz	haveReturnValue

	push	cx
	;
	; TCO_COPY/TCO_RETURN_TRANSFER_ITEM. Force the entire text to be
	; selected so it all goes to the clipboard. Do not use SELECT_ALL
	; message, as that insists on coping with regions, of which we have
	; none.
	; 
	; ^vbx:ax = transfer format
	; 
	push	ax
	call	TS_GetTextSize
	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	movdw	ds:[di].VTI_selectEnd, dxax
	clrdw	ds:[di].VTI_selectStart
	pop	ax

	movdw	cxdx, clipowner
	les	di, clipname
	call	GenerateTransferItem		;ax = item
	pop	cx
	cmp	cx, TCO_RETURN_TRANSFER_ITEM
	jz	haveReturnValue

	push	bp
	clr	bp
	call	ClipboardRegisterItem
	pop	bp
EC <	mov	ax, 0xcccc						>
haveReturnValue:

	; free the block with the object

	pop	bx
	call	MemFree

	.leave
	ret

;---

getVarData:
	push	bx
	call	ObjVarFindData
	mov	ax, ds:[bx]
	pop	bx				;recover file handle
	retn

;---

	; ax = run block, get elements

getElementBlock:
	push	bp, ds
	call	VMLock		
	mov	ds, ax			; ds -> TextLargeRunArrayHeader
	mov	ax, ds:[TLRAH_elementVMBlock]	; get handle
	call	VMUnlock		; release block
	pop	bp, ds
	retn

TextFinishWithClipboardObject	endp

TextTransfer ends
