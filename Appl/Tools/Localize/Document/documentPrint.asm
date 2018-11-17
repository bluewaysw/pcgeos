COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit	
FILE:		documentPrint.asm

AUTHOR:		Cassie Hartzong, Aug 27, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	8/27/93		Initial revision


DESCRIPTION:
	Printing methods and routines.

	$Id: documentPrint.asm,v 1.1 97/04/04 17:14:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DocumentPrint	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditDocumentStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the document
CALLED BY:	MSG_PRINT_START_PRINTING

PASS:		*ds:si - instance data
		es - seg addr of ResEditDocumentClass (dgroup)
		ax - the method

		cx:dx - OD to sent MSG_PRINTING_COMPLETED to
		bp - handle of GString

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	A document is a collection of resources which contain
	these kinds of chunks:
		Text
		Text from a VisMoniker - can have a mnemonic
		GString from a VisMoniker
		GString
		Bitmap
		Object (keyboard shortcut)

	We will print only text unless instructed to print graphics
	as well.  Objects (shortcuts) are not printed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResEditPrintParams	struct
    REPP_vdp		VisDrawParams		; used for drawing 
    REPP_page		word			; Current page number
    REPP_pageRect	RectDWord		; Area of the printed page
    REPP_headerArea	RectDWord		; Area reserved for header
    REPP_footerArea	RectDWord		; Area reserved for footer
    REPP_bodyArea	RectDWord		; Area reserved for body
    REPP_yPos		word			; Y-position on page
    REPP_printFlags	PrintFlags		; PrintFlags
    REPP_filters	word			; ChunkState, ChunkType flags
    REPP_pc		optr			; OD of the PrintControl
    REPP_resource	word			; Current resource
    REPP_numResources 	word			; number of resources to print
    REPP_numChunks 	word			; # chunks in current resource
    REPP_chunkNameLength word			; length of chunk name w/o NULL
    REPP_resourceNameLength word		; length of res. name w/o NULL
    REPP_resourceTable  hptr			; handle of resource table
    REPP_colonWidth	word			; width of ColonString
SBCS <    REPP_resourceName 	char MAX_NAME_LEN dup (?)		>
DBCS <    REPP_resourceName 	wchar MAX_NAME_LEN dup (?)		>
SBCS <    REPP_buffer 	char 4 dup (?)					>
DBCS <    REPP_buffer 	wchar 4 dup (?)					>

	align	word
ResEditPrintParams	ends

ResEditDocumentStartPrinting	method dynamic ResEditDocumentClass,
						MSG_PRINT_START_PRINTING


	mov	di, bp				;di <- handle of GState

	;
	; Now the document size is set up correctly.
	; We can now start printing...
	;
	sub	sp, size ResEditPrintParams
	mov	bp, sp				;ss:bp <- frame ptr
	mov	bx, ds:[LMBH_handle]
	movdw	ss:[bp].REPP_vdp.VDP_document, bxsi

	;
	; At this point:
	;	ss:bp - ptr to ResEditPrintParams
	;	di - handle of GState to draw with
	;
	; Set REPP_printFlags, REPP_resourceTable, REPP_numResources
	;
	call	GetPrintOptions
	call	GetPrintRange		; Get the resources to print
	jc	afterPrint		; Branch if error

	call	InitPrintParameters	; Initialize the stack frame
	jc	afterPrint		; Branch if error
	
;	call	CalcNumberOfPages	; ax <- total # of pages

;	call	InitPrintParameters	; Reinitialize the stack frame

	call	PrintResources		; Print the resources
					; ax <- # of pages printed
	clc				; Signal: no error

afterPrint:
	pushf
	mov	bx, ss:[bp].REPP_resourceTable
	tst	bx
	jz	noFree
	call	MemFree
noFree:
	popf
	mov	bx, cx			; ^lbx:si <- PrintControl object
	mov	si, dx
	;
	; Carry set here on error.
	; Clean up stack while preserving carry
	;
	lea	sp, ss:[bp][(size ResEditPrintParams)]

	jc	errorPrinting		; Branch on error
	;
	; All done... Signal the SPC that we're finished.
	;
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
	mov	di, mask MF_CALL
	call	ObjMessage		; Tell PrintControl that we're done

quit:
	ret

errorPrinting:

	movdw	bxsi, ss:[bp].REPP_vdp.VDP_document
	call	MemDerefDS
	;
	; There was some sort of error. Tell the user.
	;
	push	cx
	mov	cx, ax			; cx <- ErrorValue
	mov	ax, MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE
	call	ObjCallInstanceNoLock
	pop	bx
	mov	si, dx			; ^lbx:si <- PrintControl
	;
	; And cancel the printing job.
	;
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	mov	di, mask MF_CALL
	call	ObjMessage		; Tell PrintControl that we're done
	jmp	quit

ResEditDocumentStartPrinting	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPrintParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the SpreadsheetDrawParams.

CALLED BY:	ResEditDocumentStartPrinting()
PASS:		^lcx:dx	= OD of PrintControl object
		di	= GState to draw with
		ss:bp	= Pointer to the ResEditPrintParams
		*ds:si	= document

RETURN:		carry clear if no error
			ss:bp - ResEditPrintParams filled in
		carry set on error 
			ax - ErrorValue

DESTROYED:	bx, si, ds, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 8/27/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitPrintParameters	proc	near
	uses	cx, dx, si, di, ds
	.enter

	movdw	ss:[bp].REPP_pc, cxdx		; save PrintControl OD
	mov	ss:[bp].REPP_vdp.VDP_gstate, di	; Save the gstate
	mov	ss:[bp].REPP_vdp.VDP_drawFlags, mask DF_EXPOSED or mask DF_PRINT
	mov	ss:[bp].REPP_page, 1

	call	SetPrintTextFont
	call	SetInstructionPrintTextFont

	;
	; Calculate the width of the ColonString, used when drawing ChunkNames
	;
	call	GetColonWidth
	mov	ss:[bp].REPP_colonWidth, dx

	;
	; store the current filters
	;
	DerefDoc
	mov	al, ds:[di].REDI_stateFilter
	mov	ah, ds:[di].REDI_typeFilter	
	mov	ss:[bp].REPP_filters, ax

	;
	; Get other fun stuff
	;
	call	GetFileHandle
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_file, bx

	;
	; Set REPP_pageRect 
	;
	call	GetDocDimensionsAndMargins
	call	SetPageRectAndMargin	

	;
	; Set REPP_headerArea, REPP_bodyArea, REPP_footerArea
	;
	call	FigureHeaderArea
	call	FigureFooterArea
	call	FigureBodyArea
	jc	done			; error in size of areas

	;
	; Set the width of the text area in SetDataParams
	;
	mov	ax, ss:[bp].REPP_bodyArea.RD_right.low 
	sub	ax, ss:[bp].REPP_bodyArea.RD_left.low 
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_width, ax
	sub	ss:[bp].REPP_vdp.VDP_data.SDP_width, CHUNK_TEXT_MARGIN

	;
	; Clear this field so no max length is set on PrintText
	;
	clr	ss:[bp].REPP_vdp.VDP_data.SDP_maxLength

done:

	.leave
	ret

InitPrintParameters	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextFontLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the font and point size for a printing text object.

CALLED BY:	ResEditDocumentStartPrinting
PASS:		ss:bp - ResEditPrintParams
		^lbx:si - text object
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTextFontLow		proc	near
	uses	di,bp
	.enter

	; get the printer mode and set the font
	;
	push	bx, si
	movdw	bxsi, ss:[bp].REPP_pc
	mov	ax, MSG_PRINT_CONTROL_GET_PRINT_MODE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, si

	mov	ax, BODY_TEXT_MODE_FONT		; assume text mode printing
	cmp	cl, PM_FIRST_TEXT_MODE
	jae	gotPrintMode
	mov	ax, BODY_GRAPHICS_MODE_FONT	; graphics mode printing

gotPrintMode:
	;
	; set the fontID for the big font
	;
	mov	dx, size VisTextSetFontIDParams	
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].VTSFIDP_fontID, ax
	clrdw	ss:[bp].VTSFIDP_range.VTR_start
	movdw	ss:[bp].VTSFIDP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ax, MSG_VIS_TEXT_SET_FONT_ID	
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size VisTextSetFontIDParams	

	;
	; set the point size for the font
	;
	mov	dx, size VisTextSetPointSizeParams
	sub	sp, dx
	mov	bp, sp

	mov	ss:[bp].VTSPSP_pointSize.WWF_int, BODY_PTSIZE
	clr	ss:[bp].VTSPSP_pointSize.WWF_frac
	clrdw	ss:[bp].VTSPSP_range.VTR_start
	movdw	ss:[bp].VTSPSP_range.VTR_end, TEXT_ADDRESS_PAST_END

	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage	
	add	sp, VisTextSetPointSizeParams

	.leave
	ret
SetTextFontLow		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetInstructionPrintTextFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the font and point size for InstructionPrintText.

CALLED BY:	
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetInstructionPrintTextFont		proc	near
	uses	si,bp,di
	.enter

	test	ss:[bp].REPP_printFlags, mask PF_INSTRUCTIONS
	jz	done

	GetResourceHandleNS	InstructionPrintText, bx
	mov	si, offset InstructionPrintText

	call	SetTextFontLow

	mov	dx, size VisTextSetTextStyleParams
	sub	sp, dx
	mov	bp, sp
	clr	ss:[bp].VTSTSP_extendedBitsToSet
	clr	ss:[bp].VTSTSP_extendedBitsToClear
	mov	ss:[bp].VTSTSP_styleBitsToSet, mask TS_ITALIC
	clr	ss:[bp].VTSTSP_styleBitsToClear
	clrdw	ss:[bp].VTSTSP_range.VTR_start
	movdw	ss:[bp].VTSTSP_range.VTR_end, TEXT_ADDRESS_PAST_END

	mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size VisTextSetTextStyleParams

done:
	.leave
	ret
SetInstructionPrintTextFont		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPrintTextFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set font and point size for PrintText.

CALLED BY:	InitPrintParameters
PASS:		ss:bp - REPP
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPrintTextFont		proc	near
	uses	si
	.enter

	GetResourceHandleNS	PrintText, bx
	mov	si, offset PrintText
	call	SetTextFontLow

	.leave
	ret
SetPrintTextFont		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetColonWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	InitPrintParameters

CALLED BY:	DrawChunkName
PASS:		di - gstate
RETURN:		dx - width of ColonString
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetColonWidth		proc	near
	uses	cx, si, ds
	.enter

	mov	cx, CHUNK_NAME_FONT		; cx <- font
	mov	dx, CHUNK_NAME_PTSIZE		; dx <- size
	clr	ah				; dx.ah <- point size
	call	GrSetFont

	segmov	ds, cs, cx
	mov	si, offset ColonString
	mov	cx, size ColonString
	call	GrTextWidth			; dx <- width of string

	.leave
	ret
GetColonWidth		endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcNumberOfPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the number of pages

CALLED BY:	ResEditDocumentStartPrinting()
PASS:		ss:bp	= Pointer to ResEditPrintParams
		^lcx:dx = PrintControl object
		di	= GState
RETURN:		ax	= # of pages
DESTROYED:	bx, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 9/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcNumberOfPages	proc	near
	uses	cx, dx, si, di, ds
	ForceRef CalcNumberOfPages
	.enter
	;
	; Set print flags so that we'll skip the drawing.
	;
	push	ss:[bp].REPP_vdp.VDP_gstate	; Save the gstate
	push	ss:[bp].REPP_printFlags		; Save old flags

	ornf	ss:[bp].REPP_printFlags, mask PF_SKIP_DRAW
	;
	; Now create a gstate with no window.
	;
	clr	di				; di <- Window handle (none)
	call	GrCreateState			; di <- gstate with no window
	mov	ss:[bp].REPP_vdp.VDP_gstate, di	; Save new gstate

	mov	ss:[bp].REPP_page, 1		; Initialize # of pages

	call	PrintResources			; ax <- # of pages printed
	mov	di, ss:[bp].REPP_vdp.VDP_gstate	; di <- gstate with no window
	call	GrDestroyState			; destroy it, we're done

	pop	ss:[bp].REPP_printFlags		; Restore old flags
	pop	ss:[bp].REPP_vdp.VDP_gstate	; Restore the gstate

	;
	; Now tell the PrintControl about it
	;
	push	ax, bp
	movdw	bxsi, cxdx
	mov	dx, ax				;dx <- # of pages
	mov	cx, 1				;cx <- start page
	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	mov	di, mask MF_CALL		;di <- MessageFlags
	call	ObjMessage
	pop	ax, bp

	.leave
	ret
CalcNumberOfPages	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPrintOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the options for printing

CALLED BY:	ResEditDocumentStartPrinting
PASS:		ss:bp - ptr to ResEditPrintParams
RETURN:		REPP_printFlags - ResEditPrintFlags
DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 8/27/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPrintOptions		proc	near
	uses	cx,dx,si,di
	.enter

	push	bp
	GetResourceHandleNS PrintOptionsGroup, bx
	mov	si, offset PrintOptionsGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	mov	ss:[bp].REPP_printFlags, ax

	.leave
	ret
GetPrintOptions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPrintRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the starting resource and number of resources to print

CALLED BY:	ResEditDocumentStartPrinting
PASS:		ss:bp	= Pointer to ResEditPrintParams
RETURN:		carry set if error
			ax - ErrorValue
		carry clear if ok, 
			ss:bp.REPP_resourceTable - set
			ss:bp.REPP_numResources - set
		
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 8/27/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPrintRange	proc	near
	uses	cx, dx, si, di, ds
	.enter

	clr	ss:[bp].REPP_resourceTable
	push	bp
	GetResourceHandleNS PrintResourcesList, bx
	mov	si, offset PrintResourcesList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp

	mov	ss:[bp].REPP_numResources, ax

	push	bx
	mov	cl, size word
	mul	cl
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	mov	ss:[bp].REPP_resourceTable, bx
	call	MemLock
	mov	ds, ax
	mov	cx, ax
	clr	dx			; cx:dx <- buffer to hold selections
	pop	bx

	push	bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	mov	bx, ss:[bp].REPP_resourceTable
	call 	MemUnlock
	
	clc					;signal no error

	.leave
	ret
GetPrintRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDocDimensionsAndMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dimensions and margins for the document, and
		set them in the print control object.

CALLED BY:	PrintStartPrinting
PASS:		ss:bp	= ResEditPrintParams
RETURN:		ax	= Left margin
		di	= Top margin
		cx	= Width of the printable area
		dx	= Height of the printable area
DESTROYED:	bx,si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 8/27/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDocDimensionsAndMargins	proc	near

	movdw	bxsi, ss:[bp].REPP_pc

	push	bp
	sub	sp, (size PageSizeReport)
	mov	dx, ss
	mov	bp, sp				; dx:bp = PageSizeReport
	mov	ax, MSG_PRINT_CONTROL_CALC_DOC_DIMENSIONS
	mov	di, mask MF_CALL
	call	ObjMessage			; dx:bp = filled PageSizeReport
	mov	ax, ss:[bp].PSR_margins.PCMP_left
	mov	di, ss:[bp].PSR_margins.PCMP_top
	mov	cx, ss:[bp].PSR_width.low
	mov	dx, ss:[bp].PSR_height.low
	add	sp, (size PageSizeReport)
	pop	bp

	mov	si, offset PageSizeMarginLeft
	call	GetMargin			; bx <- left margin
	add	ax, si				; ax <- page left
	sub	cx, si				; subtract margin from width

	mov	si, offset PageSizeMarginRight
	call	GetMargin			; bx <- right margin
	sub	cx, si				; cx <- page width

	mov	si, offset PageSizeMarginTop
	call	GetMargin			; bx <- top margin
	add	di, si				; di <- page top
	sub	dx, si				; subtract margin from height
	
	mov	si, offset PageSizeMarginBottom
	call	GetMargin			; bx <- bottom margin
	sub	dx, si				; dx <- page height

	ret
GetDocDimensionsAndMargins	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns value set in margin GenValue object.

CALLED BY:	GetDocDimensionsAndMargin
PASS:		^lbx:si - object from which to get margin value
RETURN:		si - margin
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMargin		proc	near
	uses	ax,cx,dx,di,bp
	.enter

	mov	ax, MSG_GEN_VALUE_GET_VALUE	;dx:cx - integer:fraction
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	si, dx

	.leave
	ret
GetMargin		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPageRectAndMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the REPP_pageRect field of the ResEditPrintParams

CALLED BY:	FigureAreas
PASS:		ss:bp	= ResEditPrintParams
		cx	= Page width
		dx	= Page height
		ax	= Left margin
		di	= Top margin
RETURN:		nothing
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPageRectAndMargin	proc	near

	mov	ss:[bp].REPP_pageRect.RD_bottom.low, dx
	mov	ss:[bp].REPP_pageRect.RD_right.low, cx
	mov	ss:[bp].REPP_pageRect.RD_top.low, di
	mov	ss:[bp].REPP_pageRect.RD_left.low, ax

	;
	; Zero out all the high words, etc
	;
	clr	cx
	mov	ss:[bp].REPP_pageRect.RD_top.high, cx
	mov	ss:[bp].REPP_pageRect.RD_left.high, cx
	mov	ss:[bp].REPP_pageRect.RD_bottom.high, cx
	mov	ss:[bp].REPP_pageRect.RD_right.high, cx
	
	ret
SetPageRectAndMargin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureHeaderArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the area we'll need for the header.

CALLED BY:	InitPrintParameters
PASS:		ss:bp	= Pointer to ResEditPrintParams
RETURN:		REPP_headerArea set
DESTROYED:	ax,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureHeaderArea	proc	near
	;
	; Assume there is no header. Create an empty area.
	;
	; Header occupies the top of the paper rectangle.
	;
	lea	si, ss:[bp].REPP_pageRect
	lea	di, ss:[bp].REPP_headerArea
	call	CopyDocRect
	
	call	GetHeaderHeight			; dx:ax <- header height
	;
	; dx:ax - height of the header.
	; bottom = top + header height
	;
	adddw	dxax, ss:[bp].REPP_headerArea.RD_top
	movdw	ss:[bp].REPP_headerArea.RD_bottom,  dxax

	ret
FigureHeaderArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureFooterArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the area needed by the footer.

CALLED BY:	InitPrintParameters
PASS:		ss:bp	= Pointer to ResEditPrintParams
RETURN:		REPP_footerArea set
DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureFooterArea	proc	near
	;
	; Assume there is no footer. Create an empty area.
	;
	; Footer occupies the bottom of the paper rectangle.
	;
	lea	si, ss:[bp].REPP_pageRect
	lea	di, ss:[bp].REPP_footerArea
	call	CopyDocRect
	
	call	GetFooterHeight			; dx:ax <- footer height
	;
	; dx:ax - height of the footer.
	; top = bottom - footer height
	;
	movdw	cxbx, ss:[bp].REPP_footerArea.RD_bottom
	subdw	cxbx, dxax			;cx:bx <- new top for header
	movdw	ss:[bp].REPP_footerArea.RD_top, cxbx

	ret
FigureFooterArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureBodyArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the area left for the body.

CALLED BY:	InitPrintParameters
PASS:		ss:bp	= Pointer to ResEditPrintParams
RETURN:		carry set if there's no room for the body
		REPP_bodyArea set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The body area is *always*:
	    body.left  = page.left
	    body.right = page.right
	    body.top   = header.bottom
	    body.bottom= footer.top

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureBodyArea	proc	near
	uses	ax, di, si
	.enter
	;
	; First copy the left/right edges
	;
	lea	si, ss:[bp].REPP_pageRect
	lea	di, ss:[bp].REPP_bodyArea
	call	CopyDocRect
	;
	; Now copy the top/bottom edges
	;
	mov	ax, ss:[bp].REPP_headerArea.RD_bottom.low
	mov	ss:[bp].REPP_bodyArea.RD_top.low, ax
	mov	ax, ss:[bp].REPP_headerArea.RD_bottom.high
	mov	ss:[bp].REPP_bodyArea.RD_top.high, ax

	mov	ax, ss:[bp].REPP_footerArea.RD_top.low
	mov	ss:[bp].REPP_bodyArea.RD_bottom.low, ax
	mov	ax, ss:[bp].REPP_footerArea.RD_top.high
	mov	ss:[bp].REPP_bodyArea.RD_bottom.high, ax
	
	;
	; Check for header bottom below footer top.
	;
	mov	ax, ss:[bp].REPP_headerArea.RD_bottom.high
	cmp	ax, ss:[bp].REPP_footerArea.RD_top.high
	ja	errorNoBody
	jb	quitNoError

	mov	ax, ss:[bp].REPP_headerArea.RD_bottom.low
	cmp	ax, ss:[bp].REPP_footerArea.RD_top.low
	jae	errorNoBody

	;
	; Check for left margin to the right of right margin
	;
	mov	ax, ss:[bp].REPP_bodyArea.RD_left.high
	cmp	ax, ss:[bp].REPP_bodyArea.RD_right.high
	ja	errorNoBody
	jb	quitNoError

	mov	ax, ss:[bp].REPP_bodyArea.RD_left.low
	cmp	ax, ss:[bp].REPP_bodyArea.RD_right.low
	jae	errorNoBody

quitNoError:
	clc				; signal: no error
quit:
	.leave
	ret

errorNoBody:
	stc				; signal: no space for the body
	mov	ax, EV_PRINT_NO_BODY
	jmp	quit
FigureBodyArea	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHeaderHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of the header

CALLED BY:	FigureHeaderArea
PASS:		ss:bp	= ResEditPrintParams
RETURN:		dx:ax	= Height of the header
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Header will be current Resource name?

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 9/04/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Number of points of padding to place between header and body.
;
HEADER_PADDING	=	10

GetHeaderHeight	proc	near
	.enter

	clr	ax, dx
	test	ss:[bp].REPP_printFlags, mask PF_RESOURCE_NAMES
	jz	skipDraw

	mov	ax, RESOURCE_NAME_PTSIZE
	add	ax, HEADER_PADDING

skipDraw:	
	.leave
	ret
GetHeaderHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFooterHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of the footer

CALLED BY:	FigureFooterArea
PASS:		ss:bp	= ResEditPrintParams
RETURN:		dx:ax	= Height of the footer
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Footer will be current page number?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 9/04/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Number of points of padding to place between footer and body.
;
FOOTER_PADDING	=	8

GetFooterHeight	proc	near

	clr	ax, dx
	test	ss:[bp].REPP_printFlags, mask PF_PAGE_NUMBER
	jz	skipDraw

	mov	ax, RESOURCE_NAME_PTSIZE	; use same font as for header
	add	ax, FOOTER_PADDING

skipDraw:
	ret
GetFooterHeight	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDocRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one document rectangle to another

CALLED BY:	Utility
PASS:		ss:si	= Source RectDWord
		ss:di	= Dest RectDWord
RETURN:		Dest <- Source
DESTROYED:	di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyDocRect	proc	near
	uses	cx, ds, es
	.enter
	segmov	es, ss, cx			; es:di <- dest
	mov	ds, cx				; ds:si <- source
	mov	cx, size RectDWord		; cx <- size
	rep	movsb				; Copy the rectangle
	.leave
	ret
CopyDocRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the resources

CALLED BY:	ResEditDocumentStartPrinting()
PASS:		di	= GState to draw with
		ss:bp	= Pointer to ResEditPrintParams
		*ds:si	= document
RETURN:		ax	= # of pages printed
DESTROYED:	es

PSEUDO CODE/STRATEGY:
	Put a page break between resources.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 8/27/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintResources	proc	near
	uses	cx, dx
	.enter

	; di	  = gstate to draw with
	; ss:bp	  = pointer to ResEditPrintParams
	;
	;
	; Loop and print each resource
	;
	mov	cx, ss:[bp].REPP_numResources
	mov	bx, ss:[bp].REPP_resourceTable
	call	MemLock
	mov	es, ax
	clr	bx			; es:bx <- first resource number

printLoop:
	mov	ax, es:[bx]
	mov	ss:[bp].REPP_resource, ax
	call	PrintNextResource	; Print another resource...
	add	bx, size word		; es:bx <- next resource to print
	loop	printLoop		; Loop to print another resource

	mov	ax, ss:[bp].REPP_page	; ax <- next page to print
	dec	ax			; Return # of pages printed

	mov	bx, ss:[bp].REPP_resourceTable
	call	MemUnlock

	.leave
	ret
PrintResources	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintNextResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the next resource

CALLED BY:	ResEditDocumentStartPrinting()
PASS:		ss:bp	= ResEditPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 8/27/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintNextResource	proc	near
	uses	ax, bx, cx, dx, di, es
	.enter

	; 
	; Update the resource info in REPP structure
	;
	call	GetResourceData
	tst	ss:[bp].REPP_numChunks
	jz	done

	;
	; Signal PrintController that we're printing a resource
	;
	call	PrintReportProgress
	;
	; ss:bp	  = ResEditPrintParams
	;
	call	PrintChunks		; print all the chunks

done:
	.leave
	ret
PrintNextResource	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetResourceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Going to the next resource, update info in REPP.

CALLED BY:	PrintNextResource
PASS:		ss:bp	- ResEditPrintParams
		*ds:si	- document
RETURN:		nothing
DESTROYED:	ax,bx,cx,es,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetResourceData		proc	near
	.enter

	;
	; Get the ResourceMapElement for this resource.
	;
	mov	bx, ss:[bp].REPP_vdp.VDP_data.SDP_file
	call	DBLockMap_DS
	mov	ax, ss:[bp].REPP_resource
	call	ChunkArrayElementToPtr		; ds:di <- ResourceMapElement
EC<	ERROR_C CHUNK_ARRAY_ELEMENT_NOT_FOUND				>

	;
	; Calculate the size of the resource name, which is not 
	; null-terminated.
	;
	sub	cx, size ResourceMapElement
DBCS <	shr	cx, 1				; convert size to length >
	mov	ss:[bp].REPP_resourceNameLength, cx

	;
	; Get the number of chunks in this resource
	;
	mov	dx, ss:[bp].REPP_filters
	call	ResMapGetArrayCount			;cx <- # chunks which
	mov	ss:[bp].REPP_numChunks, cx		; match current filters
	;
	; Get the DB group & item for its ResourceArray
	;
	mov	ax, ds:[di].RME_data.RMD_group
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_group, ax
	mov	ax, ds:[di].RME_data.RMD_item
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_item, ax

	;
	; Start with chunk 0.
	;
	clr	ss:[bp].REPP_vdp.VDP_curChunk

	;
	; Copy the resource's name to REPP_resourceName 
	;
	lea	si, ds:[di].RME_data.RMD_name
	segmov	es, ss, ax
	lea	di, ss:[bp].REPP_resourceName
	mov	cx, ss:[bp].REPP_resourceNameLength
	LocalCopyNString				;rep movs[bw]

	call	DBUnlock_DS
	movdw	bxsi, ss:[bp].REPP_vdp.VDP_document
	call	MemDerefDS

	.leave
	ret
GetResourceData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the notes associated with a document

CALLED BY:	ResEditDocumentStartPrinting()
PASS:		ss:bp	= ResEditPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 9/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintChunks	proc	near
	uses	ax, cx, dx, di
	.enter

	;
	; Initialize REPP_yPos for the first chunk.  Will force a new
	; page in the callback routine.
	;
	mov	ax, ss:[bp].REPP_bodyArea.RD_top.low
	mov	ss:[bp].REPP_yPos, ax
	
	;
	; Call the callback routine which really prints the chunks.
	;
	mov	bx, ss:[bp].REPP_vdp.VDP_data.SDP_file	
	mov	ax, ss:[bp].REPP_vdp.VDP_data.SDP_group
	mov	di, ss:[bp].REPP_vdp.VDP_data.SDP_item
	call	DBLock_DS			; *ds:si <- ResourceArray
	mov	bx, cs				; bx:di <- callback routine
	mov	di, offset cs:PrintChunksCallback
	call	ChunkArrayEnum
	call	DBUnlock_DS			; *ds:si <- ResourceArray

	;
	; See if we ended right on the end of a page.
	;
	mov	ax, ss:[bp].REPP_yPos
	cmp	ax, ss:[bp].REPP_bodyArea.RD_top.low
	je	quit				; Branch if we finished a page
	
	;
	; We didn't stop right at the end of a page. Draw the missing footer.
	;
	call	DrawFooter			; Otherwise draw the footer
	inc	ss:[bp].REPP_page		; Next page to draw

quit:
	.leave
	ret
PrintChunks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintChunksCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for printing chunks

CALLED BY:	PrintChunks via ChunkArrayEnum
PASS:		ss:bp	= Pointer to ResEditPrintParams
		*ds:si	= ResourceArray
		ds:di	= ResourceArrayElement
		ax	= element size
RETURN:		carry set to abort enum
DESTROYED:	ax,cx,dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Print original, translation, both???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 9/04/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Number of points of padding to place between each chunk.
;
CHUNK_PADDING	=	4
;
; The chunks are inset on the page to allow room for the chunk name, like so:
; "ChunkX:
;		#####" 
;
CHUNK_TEXT_MARGIN	= 48

PrintChunksCallback	proc	far
	uses	bp
	.enter

	;
	; Calculate the length of the chunk name, which is not null-terminated.
	;
	sub	ax, size ResourceArrayElement
DBCS <	shr	ax, 1				; convert size to length >
	mov	ss:[bp].REPP_chunkNameLength, ax

	;
	; does this element meet the filter criteria?
	;
	mov	ax, ss:[bp].REPP_filters
	call	FilterElement
	LONG	jnc	quit

	;
	; save chunk, mnemonic info
	;
	mov	al, ds:[di].RAE_data.RAD_chunkType
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_chunkType, al
	mov	al, ds:[di].RAE_data.RAD_mnemonicType
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_mnemonicType, al
SBCS <	mov	al, ds:[di].RAE_data.RAD_mnemonicChar			>
DBCS <	mov	ax, ds:[di].RAE_data.RAD_mnemonicChar			>
SBCS <	mov	ss:[bp].REPP_vdp.VDP_data.SDP_mnemonicChar, al		>
DBCS <	mov	ss:[bp].REPP_vdp.VDP_data.SDP_mnemonicChar, ax		>

	;
	; Default is to draw the OrigItem.  If user wants to draw 
	; translation item, use TransItem instead, if it exists.
	;
	mov	ax, ds:[di].RAE_data.RAD_origItem
	test	ss:[bp].REPP_printFlags, mask PF_TRANSLATION
	jz	haveItem
	tst	ds:[di].RAE_data.RAD_transItem
	jz	haveItem
	mov	ax, ds:[di].RAE_data.RAD_transItem
haveItem:
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_item, ax

	;
	; Set the chunk printing margins.
	;
	clr	ss:[bp].REPP_vdp.VDP_data.SDP_border	; no border
	mov	ax, ss:[bp].REPP_bodyArea.RD_left.low
	add	ax, CHUNK_TEXT_MARGIN
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_left, ax
	mov	ax, ss:[bp].REPP_yPos
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_top, ax
	
	; 
	; Get the size of the chunk (its height, given the page width)
	;
	GetResourceHandleNS	MiscObjectUI, bx
	mov	si, offset PrintText
	call	GetChunkSize
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_height, dx

	;
	; Check for first chunk on the page (y pos = body-area top)
	;
	mov	dx, ss:[bp].REPP_yPos
	cmp	dx, ss:[bp].REPP_bodyArea.RD_top.low
	jne	notFirstChunk			; Branch if not at top

newPage:
	;
	; We're at the start of a new page...
	;
	cmp	ss:[bp].REPP_page, 1		; Check for first page
	je	skipNewPage			; Branch if first page

	test	ss:[bp].REPP_printFlags, mask PF_SKIP_DRAW
	jnz	skipNewPage

	push	di
	mov	di, ss:[bp].REPP_vdp.VDP_gstate	; di <- gstate handle
	mov	al, PEC_FORM_FEED
	call	GrNewPage			; Draw a new page
	pop	di

skipNewPage:
	call	DrawHeader			; Draw the header
						; dx <- new yPos
notFirstChunk:
	;
	; Not the first chunk, make sure it fits.
	;
	call	CheckChunkFits			; Check for chunk fitting
	jc	endOfPage			; Branch if it doesn't

	;
	; The chunk fits or is the first chunk on the page.
	;
	; dx = y position for this chunk
	;
	call	DrawChunkName			; Draw the chunk name
	call	DrawOneChunk			; Draw the chunk
	call	DrawInstruction			; Draw its instruction

	mov	ss:[bp].REPP_yPos, dx		; Set position for next chunk

quit:
	clc					; Process next chunk
	.leave
	ret

endOfPage:
	;
	; We've reached the last chunk that can fit on the page.
	;
	call	DrawFooter			; Draw the footer
	mov	dx, ss:[bp].REPP_bodyArea.RD_top.low
	mov	ss:[bp].REPP_yPos, dx		; Initialize the next chunk pos
	inc	ss:[bp].REPP_page		; go to next page
	jmp	newPage

PrintChunksCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOneChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the chunk.

CALLED BY:	PrintChunksCallback
PASS:		ss:bp	- REPP
		^lbx:si - text object to draw
		dx	- yPos for chunk
RETURN:		dx	- yPos updated for next chunk
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawOneChunk		proc	near
	uses	bp,si,di
	.enter

	;
	; Calculate next yPos
	;
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_top, dx
	add	dx, ss:[bp].REPP_vdp.VDP_data.SDP_height

	push	dx				;save yPos for next chunk

	test	ss:[bp].REPP_printFlags, mask PF_SKIP_DRAW
	jnz	done

	test 	ss:[bp].REPP_vdp.VDP_data.SDP_chunkType, mask CT_TEXT or mask CT_OBJECT
	jz	tryGraphics

	; 
	; Replace the text and set its size and position.
	;
	push	bp
	lea	bp, ss:[bp].REPP_vdp.VDP_data	;ss:bp <- SetDataParams
	mov	dx, size SetDataParams
	mov	ax, MSG_RESEDIT_TEXT_SET_TEXT
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	cmp 	ss:[bp].SDP_chunkType, CT_TEXT_MONIKER
	jne	notTextMoniker
	;
	; Change the text style to underline the mnemonic char.
	;
	mov	ax, MSG_RESEDIT_TEXT_SET_MNEMONIC_UNDERLINE
	mov	dx, size SetDataParams
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

notTextMoniker:
	;
	; Have to validate the geometry if text width changes
	;
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	;
	; Draw the darn thing
	;
	mov	cl, ss:[bp].REPP_vdp.VDP_drawFlags
	mov	bp, ss:[bp].REPP_vdp.VDP_gstate
	mov	ax, MSG_VIS_DRAW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

done:
	pop	dx	
	add	dx, CHUNK_PADDING

	.leave
	ret

tryGraphics:
EC<	test 	ss:[bp].REPP_vdp.VDP_data.SDP_chunkType, CT_GRAPHICS	>
EC<	ERROR_Z	BAD_CHUNK_TYPE						>
	call	DrawGraphics
	jmp	done

DrawOneChunk		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawInstruction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Chunk name and chunk have been drawn, now draw the
		instruction if that option has been set, and if there
		is an instruction.

CALLED BY:	PrintChunksCallback
PASS:		ss:bp	- ResEditPrintParams
		ds:di	- ResourceArrayElement
		dx - y Position

RETURN:		dx - new y Position
		REPP_page updated

DESTROYED:	ax, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Number of additional points of padding to place between the
; instruction and the next chunk.
;
INSTRUCTION_PADDING	= 2

DrawInstruction		proc	near
	.enter

	test	ss:[bp].REPP_printFlags, mask PF_INSTRUCTIONS
	jz	done

	tst	ds:[di].RAE_data.RAD_instItem
	jz	done

	; 
	; So that we can use the same routines as for real chunks,
	; put the appropriate info in SDP.
	;
	mov	ax, ds:[di].RAE_data.RAD_instItem
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_item, ax
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_chunkType, CT_INSTRUCTION
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_mnemonicType, VMO_NO_MNEMONIC

	add	dx, INSTRUCTION_PADDING
	mov	ax, dx

	GetResourceHandleNS	InstructionPrintText, bx
	mov	si, offset InstructionPrintText	

	call	GetChunkSize
	mov	ss:[bp].REPP_vdp.VDP_data.SDP_height, dx
	xchg	dx, ax				; dx <- yPos
	add	ax, dx				; ax <- yPos + Instr. height
	cmp	ax, ss:[bp].REPP_bodyArea.RD_bottom.low
	jbe	doesFit

	;
	; This instruction won't fit on this page, so go to next one.
	;
	call	DrawFooter			; Draw the footer
	mov	dx, ss:[bp].REPP_bodyArea.RD_top.low	; dx <- new yPos
	mov	ss:[bp].REPP_yPos, dx
	
	test	ss:[bp].REPP_printFlags, mask PF_SKIP_DRAW
	jnz	skipDraw

	mov	di, ss:[bp].REPP_vdp.VDP_gstate	; di <- gstate handle
	mov	al, PEC_FORM_FEED
	call	GrNewPage			; Draw a new page

skipDraw:
	inc	ss:[bp].REPP_page
	call	DrawHeader

doesFit:	
	;
	; pass dx = y position for the instruction
	;
	call	DrawOneChunk			; dx <- updated yPos

done:
	.leave
	ret
DrawInstruction		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the resource name at the top of the page.

CALLED BY:	PrintNextResource
PASS:		ss:bp	= ResEditPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 8/27/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawHeader	proc	near

	test	ss:[bp].REPP_printFlags, mask PF_SKIP_DRAW
	jnz	skipDraw
	test	ss:[bp].REPP_printFlags, mask PF_RESOURCE_NAMES
	jz	skipDraw

	call	DrawResourceName	

skipDraw:
	ret
DrawHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFooter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the footer...

CALLED BY:	PrintNextPage
PASS:		ss:bp	= ResEditPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 9/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFooter	proc	near
	uses	ax,bx,cx,dx,si,di,ds,es
	.enter

	test	ss:[bp].REPP_printFlags, mask PF_SKIP_DRAW
	jnz	skipDraw
	test	ss:[bp].REPP_printFlags, mask PF_PAGE_NUMBER
	jz	skipDraw

SBCS <	sub	sp, 6							>
DBCS <	sub	sp, 12							>
	segmov	es, ss, ax
	mov	di, sp				; es:di <- place to put text
	clr	cx				; no fraction
	clr	ax
	mov	dx, ss:[bp].REPP_page		; dx:ax <- number to convert
	call	LocalFixedToAscii
	
	segmov	ds, ss, ax
	mov	si, di

	mov	di, ss:[bp].REPP_vdp.VDP_gstate	; di <- gstate handle
	mov	cx, RESOURCE_NAME_FONT		; cx <- font
	mov	dx, RESOURCE_NAME_PTSIZE	; dx <- size
	clr	ah				; dx.ah <- point size
	call	GrSetFont

	mov	al, mask TS_BOLD		; Set bold
	mov	ah, TextStyle			; Clear everything else
	call	GrSetTextStyle

	;
	; center the page number horizontally
	;
	mov	cx, 6
	call	GrTextWidth			; dx <- width of string
	shr	dx				; dx <- width/2

	mov	ax, ss:[bp].REPP_footerArea.RD_right.low
	sub	ax, ss:[bp].REPP_footerArea.RD_left.low	;ax <- printing width
	shr	ax					;ax <- print width/2
	add	ax, ss:[bp].REPP_footerArea.RD_left.low	;ax <- center of page
	sub	ax, dx					;ax <- left pos for p.#
	mov	bx, ss:[bp].REPP_footerArea.RD_top.low
	add	bx, FOOTER_PADDING

	call	GrDrawText

SBCS <	add	sp, 6							>
DBCS <	add	sp, 12							>
skipDraw:
	.leave
	ret
DrawFooter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChunkSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the height of a chunk.

CALLED BY:	PrintChunksCallback
PASS:		ss:bp	- ResEditPrintParameters
		^lbx:si - text object to use for getting size
RETURN:		dx	- height of chunk
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChunkSize		proc	near
	uses ax,bx,si,di,bp
	.enter

	mov	al, ss:[bp].REPP_vdp.VDP_data.SDP_chunkType
	test	al, mask CT_TEXT or mask CT_OBJECT
	jz	tryGraphics

	mov	ax, MSG_RESEDIT_TEXT_RECALC_HEIGHT
	jmp	recalc

tryGraphics:
	clr	dx		
	test	al, CT_GRAPHICS
	jz	unknown
	mov	si, offset HeightGlyph
	mov	ax, MSG_RESEDIT_GLYPH_RECALC_HEIGHT

recalc:
	lea	bp, ss:[bp].REPP_vdp.VDP_data
	mov	dx, size SetDataParams
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage

unknown:
	.leave
	ret
GetChunkSize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckChunkFits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a chunk (and its name) 
		will fit between the yPos and the bottom of the body area.

CALLED BY:	PrintChunksCallback
PASS:		ss:bp	= ResEditPrintParams
		dx = yPos
RETURN:		carry set if the note doesn't fit
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 9/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Height of chunk name plus a little padding.
;
CHUNK_NAME_SIZE		= CHUNK_NAME_PTSIZE + 2

CheckChunkFits		proc	near
	uses	dx
	.enter

	add	dx, ss:[bp].REPP_vdp.VDP_data.SDP_height
	test	ss:[bp].REPP_printFlags, mask PF_CHUNK_NAMES
	jz	noName
	add	dx, CHUNK_NAME_SIZE		; dx <- height of chunk & name

noName:	
	cmp	dx, ss:[bp].REPP_bodyArea.RD_bottom.low
	ja	doesNotFit
	clc					; Signal: note fits
quit:
	.leave
	ret

doesNotFit:
	stc					; Signal: doesn't fit
	jmp	quit
CheckChunkFits	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawChunkName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a chunk name.

CALLED BY:	PrintChunksCallback
PASS:		ss:bp	= ResEditPrintParams
		ds:di	= ResourceArrayElement
		dx = REPP_yPos	= y position
RETURN:		dx	= updated yPos
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	 9/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString	ColonString, <': '>

DrawChunkName	proc	near
	uses	bx, cx, di, si, ds

	.enter

	test	ss:[bp].REPP_printFlags, mask PF_CHUNK_NAMES
	LONG	jz	noName			; branch no names printed

	push	dx				; save yPos

	test	ss:[bp].REPP_printFlags, mask PF_SKIP_DRAW 
	LONG	jnz	done			; branch if calculating

	;
	; Now draw the chunk name
	;
	lea	si, ds:[di].RAE_data.RAD_name	; ds:si <- chunk name
	mov	di, ss:[bp].REPP_vdp.VDP_gstate	; di <- gstate handle
	mov	cx, CHUNK_NAME_FONT		; cx <- font
	mov	dx, CHUNK_NAME_PTSIZE		; dx <- size
	clr	ah				; dx.ah <- point size
	call	GrSetFont

	mov	cx, ss:[bp].REPP_chunkNameLength
	mov	ax, ss:[bp].REPP_bodyArea.RD_left.low
	mov	bx, ss:[bp].REPP_yPos
	call	GrDrawText

	test	ss:[bp].REPP_printFlags, mask PF_CHUNK_TYPE
	LONG	jz	done

	call	GrTextWidth			; dx <- width of string
	add	dx, ss:[bp].REPP_bodyArea.RD_left.low
	mov	ax, dx
	mov	bx, ss:[bp].REPP_yPos
	
	;
	; And then draw a colon and space
	;
	segmov	ds, cs, cx
	mov	si, offset ColonString
	mov	cx, (length ColonString)
	call	GrDrawText

	add	ax, ss:[bp].REPP_colonWidth	; ax <- new left position

	;
	; Get the offset to the proper ChunkType string
	;
	mov	cl, ss:[bp].REPP_vdp.VDP_data.SDP_chunkType
	mov	si, offset TypeUnparseable
	test	cl, mask CT_NOT_EDITABLE
	jnz	drawIt

	test	cl, mask CT_MONIKER
	jz	checkText
	test	cl, mask CT_TEXT
	jz	GStringMoniker
	mov	si, offset TypeTextMoniker
	jmp	drawIt

GStringMoniker:
	mov	si, offset TypeGStringMoniker
EC<	test	cl, mask CT_GSTRING				>
EC<	ERROR_Z	BAD_CHUNK_TYPE				>
	jmp	drawIt

checkText:
	mov	si, offset TypeText
	test	cl, mask CT_TEXT
	jz	checkGString
	jmp	drawIt

checkGString:
	mov	si, offset TypeGString
	test	cl, mask CT_GSTRING
	jz	checkBitmap
	jmp	drawIt

checkBitmap:
	mov	si, offset TypeBitmap
	test	cl, mask CT_BITMAP
	jz	checkObject
	jmp	drawIt

checkObject:
	mov	si, offset TypeObject
EC<	test	cl, mask CT_OBJECT				>
EC<	ERROR_Z	BAD_CHUNK_TYPE					>

drawIt:
	;
	; Finally, draw the chunk type
	;
	GetResourceHandleNS	StringsUI, bx
	push	bx
	push	ax
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]			; ds:si <- chunk type string
	pop	ax				; ax <- left pos
	mov	bx, ss:[bp].REPP_yPos		; bx <- top pos
	clr	cx				; text is NULL terminated
	call	GrDrawText
	pop	bx
	call	MemUnlock			; unlock StringsUI resource

done:
	;
	; Update yPos to account for height of the chunk name.
	;
	pop	dx
	add	dx, CHUNK_NAME_SIZE

noName:
	.leave
	ret
DrawChunkName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawResourceName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a resource name

CALLED BY:	DrawHeader
PASS:		ss:bp	= ResEditPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	XXX: underline, or center resource name? 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawResourceName	proc	near
	uses	bx, cx, dx, di, si, ds
	.enter

	mov	di, ss:[bp].REPP_vdp.VDP_gstate	; di <- gstate handle
	mov	cx, RESOURCE_NAME_FONT		; cx <- font
	mov	dx, RESOURCE_NAME_PTSIZE	; dx <- size
	clr	ah				; dx.ah <- point size
	call	GrSetFont

	mov	al, mask TS_BOLD		; Set bold
	mov	ah, TextStyle			; Clear everything else
	call	GrSetTextStyle

	segmov	ds, ss, ax
	lea	si, ss:[bp].REPP_resourceName
	mov	cx, ss:[bp].REPP_resourceNameLength
	mov	ax, ss:[bp].REPP_headerArea.RD_left.low
	mov	bx, ss:[bp].REPP_headerArea.RD_top.low
	call	GrDrawText

	mov	ah, mask TS_BOLD		; Clear bold
	mov	al, 0				; Set nothing
	call	GrSetTextStyle

	.leave
	ret
DrawResourceName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintReportProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the PrintController to display progress of printing.

CALLED BY:	ResEditDocumentStartPrinting
PASS:		*ds:si	- document
		ss:bp	- ResEditPrintParameters
RETURN:		ax - TRUE to continue printing
		   - FALSE to abort printing
DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString	ProgressText, <'Processing Resource '>
PrintReportProgress		proc	near
	uses	bx, cx, dx, si, di, bp
	.enter

	test	ss:[bp].REPP_printFlags, mask PF_SKIP_DRAW
	jnz	skipDraw			; branch if calculating

SBCS <	sub	sp, MAX_NAME_LEN + 30					>
DBCS <	sub	sp, 2*(MAX_NAME_LEN + 30)				>
	mov	di, sp
	mov	dx, ss	
	mov	es, dx				; es:di <- destination buffer

	push	di
	segmov	ds, cs, ax
	mov	si, offset ProgressText
	mov	cx, (length ProgressText)
	LocalCopyNString			; rep movs[bw]

	segmov	ds, ss, ax
	lea	si, ss:[bp].REPP_resourceName
	mov	cx, ss:[bp].REPP_resourceNameLength
	LocalCopyNString			; rep movs[bw]
SBCS <	mov	{byte}es:[di], 0		; add a NULL		>
DBCS <	mov	{word}es:[di], 0		; add a NULL		>

	movdw	bxsi, ss:[bp].REPP_pc
	pop	bp				; dx:bp <- text to print

	mov	ax, MSG_PRINT_CONTROL_REPORT_PROGRESS
	mov	cx, PCPT_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

SBCS <	add	sp, MAX_NAME_LEN + 30					>
DBCS <	add	sp, 2*(MAX_NAME_LEN + 30)				>

skipDraw:
	.leave
	ret
PrintReportProgress		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditDocumentUpdatePrintUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print dialog is opening or closing.  Update its UI
		appropriately.

CALLED BY:	MSG_RESEDIT_DOCUMENT_UPDATE_PRINT_UI
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		^lcx:dx - object which has opened/closed (PrintResources)
		bp - non-zero if open, 0 if close

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditDocumentUpdatePrintUI		method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_UPDATE_PRINT_UI

	tst	bp
	jnz	updateUI
	mov	ax, TEMP_RESEDIT_DOCUMENT_PRINT_CONTROL_CHILD_BLOCK
	call	ObjVarDeleteData
	ret

updateUI:
	push	cx, dx
	mov	ax, TEMP_RESEDIT_DOCUMENT_PRINT_CONTROL_CHILD_BLOCK
	mov	cx, size hptr
	call	ObjVarAddData
	pop	cx, dx
	mov	ds:[bx], cx

	DerefDoc
	call	SetCurrentFiltersText

	push	di
	mov	bx, cx
	mov	si, offset PrintResourcesList
	mov	cx, ds:[di].REDI_mapResources
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	si, offset PrintResourcesDialog
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di

	mov	ax, ds:[di].REDI_mapResources
	mov	bp, ax
	mov	cl, size word
	mul	cl

	sub	sp, ax
	mov	di, sp
	mov	dx, di
	push	ax

	mov	cx, bp
	clr	ax
stuffLoop:
	mov	ss:[di], ax
	inc	ax
	add	di, size word
	loop	stuffLoop
	
	mov	cx, ss
	mov	si, offset PrintResourcesList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	ax
	add	sp, ax
	ret

ResEditDocumentUpdatePrintUI		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurrentFiltersText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compose the moniker for CurrentFilters according to 
		what filters are currently set, and replace it.

CALLED BY:	ResEditDocumentUpdatePrintUI
PASS:		*ds:si - document
		ds:di	- document
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <TEXT_BUFFER_SIZE = 100						>
DBCS <TEXT_BUFFER_SIZE = 200						>

SetCurrentFiltersText		proc	near
	uses	cx, dx
	.enter

	;
	; Get the current filters
	;
	mov	dl, ds:[di].REDI_stateFilter
	mov	dh, ds:[di].REDI_typeFilter	

	push	ds:[LMBH_handle], si		; save document's OD

	;
	; Use some stack space for a buffer in which to compose the moniker
	;
	sub	sp, TEXT_BUFFER_SIZE
	mov	di, sp
	segmov	es, ss, cx			; es:di <- moniker buffer
	push	di				; save the buffer's offset

	;
	; Lock down the StringsUI resource
	;
	mov	bx, handle StringsUI
	call	MemLock
	mov	ds, ax				; ds <- segment of StringsUI

	mov	si, offset NoneString		; assume no filters
	tst	dx				; no filters?
	jz	copyString			; then copy NoneString
	clr	ax				; ax = 0 ==> don't need comma
	tst	dl				; any state filters?
	jz	noStateFilter			; 

	;
	; Copy the chunk state string to the buffer
	; 
	mov	si, offset NewChunksString
	test	dl, mask CS_ADDED
	jnz	copyString
	mov	si, offset ChangedChunksString
	test	dl, mask CS_CHANGED
	jnz	copyString
	mov	si, offset DeletedChunksString

copyString:
	mov	si, ds:[si]
	LocalCopyString
	LocalPrevChar	esdi
	inc	ax				; ax != 0 ==> add comma
	tst	dx				; no filters?
	LONG	jz	replaceText		; we're ready to replace text

noStateFilter:
	;
	; If no chunk type filter, we're done
	;
	tst	dh
	LONG	jz	replaceText

	test	dh, mask CT_MONIKER
	jz	monikerOK
	mov	si, offset TypeTextMoniker
	call	PutString

	mov	si, offset TypeGStringMoniker
	call	PutString

monikerOK:
	test	dh, mask CT_TEXT
	jz	textOK
	mov	si, offset TypeText
	call	PutString
	dec	di				; don't want the 's'

	test	dh, mask CT_MONIKER
	jnz	textOK
	mov	si, offset TypeTextMoniker
	call	PutString

textOK:
	test	dh, mask CT_GSTRING
	jz	gstringOK
	mov	si, offset TypeGString
	call	PutString

	test	dh, mask CT_MONIKER
	jnz	gstringOK
	mov	si, offset TypeGStringMoniker
	call	PutString

gstringOK:
	test	dh, mask CT_BITMAP
	jz	bitmapOK
	mov	si, offset TypeBitmap
	call	PutString

bitmapOK:
	test	dh, mask CT_OBJECT
	jz	replaceText
	mov	si, offset TypeObject
	call	PutString

replaceText:
	LocalLoadChar	ax, C_SPACE
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_NULL		; finally, null-terminate it
	LocalPutChar	esdi, ax

	pop	bp
	mov	dx, ss				; dx:bp <- text
	clr	cx				; text is null-terminated
	GetResourceHandleNS	CurrentFilters, bx
	mov	si, offset CurrentFilters	
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, TEXT_BUFFER_SIZE

	mov	si, offset PrintResourcesDialog
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_NOW
	mov	ax, MSG_VIS_MARK_INVALID
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, handle StringsUI
	call	MemUnlock

	pop	bx, si
	call	MemDerefDS
	DerefDoc

	.leave
	ret

SetCurrentFiltersText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutNoText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write "no " to text buffer

CALLED BY:	SetCurrentFiltersText
PASS:		es:di - text buffer
RETURN:		es:di - points to char after 'no'
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutNoText		proc	near
	push	si
	mov	si, offset NoTextString
	mov	si, ds:[si]
	LocalCopyString
	pop	si
	LocalPrevChar	esdi
	ret
PutNoText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutCommaSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write ", " to text buffer
PASS:		es:di - text buffer
RETURN:		es:di - pts to char after space
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutCommaSpace		proc	near
	LocalLoadChar	ax, ','
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, ' '
	LocalPutChar	esdi, ax
	ret
PutCommaSpace		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes ", no <string>s" to text buffer
CALLED BY:	SetCurrentFiltersText
PASS:		si - offset of string in StringsUI to print
		ax - if 0,  need comma
		     else don't add comma and space
RETURN:		ax - nonzero
DESTROYED:	si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutString		proc	near

	tst	ax
	jz	noComma
	call	PutCommaSpace
noComma:
	call	PutNoText
	mov	si, ds:[si]
	LocalCopyString
	LocalPrevChar	esdi
	LocalLoadChar	ax, 's'
	LocalPutChar	esdi, ax
	
	ret
PutString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSavePrintOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User wants to save current print options.

CALLED BY:	MSG_RESEDIT_DOCUMENT_SAVE_PRINT_OPTIONS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSavePrintOptions		method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_SAVE_PRINT_OPTIONS

	mov	ax, MSG_META_SAVE_OPTIONS
	call	SaveLoadPrintOptions

	; Finally, commit all of the changes
	;
	call	InitFileCommit			; update the file to disk
	ret

DocumentSavePrintOptions		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveLoadPrintOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the event and pass it on to the application.

CALLED BY:	DocumentSavePrintOptions, DocumentUpdatePrintUI
PASS:		*ds:si	- document
		ax - message to send to PrintControl
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveLoadPrintOptions		proc	far

	push	ax
	mov	ax, TEMP_RESEDIT_DOCUMENT_PRINT_CONTROL_CHILD_BLOCK
	call	ObjVarFindData
EC <	ERROR_NC RESEDIT_INTERNAL_LOGIC_ERROR			>
	pop	ax

	mov	bx, ds:[bx]
	mov	si, offset ResEditPrintUI
	clr	di
	call	ObjMessage
	
	ret
SaveLoadPrintOptions		endp

DocumentPrint	ends

