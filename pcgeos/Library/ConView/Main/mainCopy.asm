COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer (library)
MODULE:		main - view and text
FILE:		mainCopy.asm

AUTHOR:		Jonathan Magasin, Jun 16, 1994

METHODS:
	Name			Description
	----			-----------
	MSG_CGV_CLIPBOARD_SEND	Copy the selected text to the clipboard.

	MSG_PRINT_GET_DOC_NAME	Tells print controller the name of the 
				document region to be printed.

	MSG_CT_PRINT_START_PRINTING
				Draw the whole or selected text to the
				passed gstate for the print controller.

	MSG_CT_PRINT_CONTENT_TEXT
				Draw the ContentText to the passed gstate
				for the print controller.

ROUTINES:
	Name			Description
	----			-----------
    INT MCGetTextSelected 	Checks if any text is selected and fills 
				in the range if there is a selection.

    INT MCCreateTransferItem 	Creates a transfer item for the text.

    INT MCCreateTempText 	Creates a temporary text object that will
				hold the selected text (which is now in a
				transfer item).

    INT MCCopyTransferItemToTempText 
				Copies transfer item (which holds selected
				text) to temp text and frees transfer item.

    INT CheckClippingTextAndSetPrintAreaBottom 
				Check if we will clip any text and set 
				printAreaBottom.

    INT GetLineHeight 		Returns the height of a text line.

    INT SetPageMarginsAndSize 	Set the page margins and printableSize and
				other things.

    INT ChangeTextWidth 	Change the width of the text object.

    INT CallPrintControl 	Call the Print-Control object.

    INT SetPageClipRect 	Clip all drawing to the current page.

    INT TranslateToPage 	Translate all drawing operations to be in
				the right place.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/16/94   	Initial revision
	lester	10/20/94  	added printing support

DESCRIPTION:
	Handlers for copying text to clipboard and printer.
		

	$Id: mainCopy.asm,v 1.1 97/04/04 17:49:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentLibraryCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVMetaStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable quick-copy if book send feature is not set.

CALLED BY:	MSG_META_START_MOVE_COPY
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #

		cx	- X position of mouse, in document coordinates of
			  receiving object
		dx	- X position of mouse, in document coordinates of
			  receiving object
		bp low  - ButtonInfo
		bp high - UIFunctionsActive
RETURN:		ax	- MouseReturnFlags
DESTROYED:	whatever superclass destroys

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVMetaStartMoveCopy	method dynamic ContentGenViewClass, 
					MSG_META_START_MOVE_COPY
	.enter
	;
	; Only allow quick-copy if the book has the Send feature set.
	;
	test	ds:[di].CGVI_bookFeatures, mask BFF_SEND	
	jnz	callSuper
	
	mov	ax, mask MRF_PROCESSED
	jmp	done

callSuper:
	mov	di, offset ContentGenViewClass 
	call	ObjCallSuperNoLock
done:
	.leave
	ret
CGVMetaStartMoveCopy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVClipboardSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the selected text to the clipboard.

CALLED BY:	MSG_CGV_CLIPBOARD_SEND
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bp, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVClipboardSend	method dynamic ContentGenViewClass, 
					MSG_CGV_CLIPBOARD_SEND

	clr	di			; get text object
	call	ContentGetText
	tst	bx
	jz	done

	mov	ax, MSG_META_CLIPBOARD_COPY
	clr	di
	call	ObjMessage
done:
	ret
CGVClipboardSend	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVPrintGetDocName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells print controller the name of the 
		document region to be printed.

CALLED BY:	MSG_PRINT_GET_DOC_NAME
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #

		cx:dx	= OD of the print control class instance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVPrintGetDocName	method dynamic ContentGenViewClass, 
					MSG_PRINT_GET_DOC_NAME
	.enter

;;; SHOULD THIS BE BOOKNAME, if it exists?
		
	mov	ax, CONTENT_FILENAME
	call	ObjVarFindData			;ds:bx = file name
EC <	ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM			>
	
	segmov	es, ds, ax
	mov_tr	di, bx
	mov_tr	ax, cx				;Save cx
	call	LocalStringSize			; string length w/
	inc	cx				; null
	mov	bp, cx				;Save length.

	sub	sp, cx
	mov_tr	si, di				;ds:si = src
	segmov	es, ss, bx
	mov	di, sp				;es:di = dest
	rep	movsb				;copy file name

	mov_tr	si, dx				;^lbx:si = print
	mov_tr	bx, ax				;     controller
	mov	cx, ss
	mov	dx, sp				;cx:dx = file name

	mov	ax, MSG_PRINT_CONTROL_SET_DOC_NAME
	mov	di, mask MF_CALL
	call	ObjMessage

	add	sp, bp

	.leave
	ret
CGVPrintGetDocName	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVPrintStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the ContentText object to deal with printing.

CALLED BY:	MSG_PRINT_START_PRINTING
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #

		cx:dx	= OD of the PrintControlClass object
		bp	= GState handle to print (draw) to
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	We can NOT call from the UI thread to the process thread or 
	deadlock will occur. The ContentGenView object is in the UI 
	thread and the ContentText object is in the process thread,
	so we need to have the ContentText object deal with the printing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/20/94   	Initial version
	lester	10/ 5/94  	changed to send MSG_CT_PRINT_START_PRINTING
				to the ContentText object

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVPrintStartPrinting	method dynamic ContentGenViewClass, 
					MSG_PRINT_START_PRINTING
	.enter

	clr	di			; get text object
	call	ContentGetText

	clr	di
	mov	ax, MSG_CT_PRINT_START_PRINTING
	call	ObjMessage
	
	.leave
	ret
CGVPrintStartPrinting	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTPrintStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the whole or selected text to the passed gstate
		for the print controller.

CALLED BY:	MSG_CT_PRINT_START_PRINTING
PASS:		*ds:si	= ContentTextClass object
		ds:di	= ContentTextClass instance data
		ds:bx	= ContentTextClass object (same as *ds:si)
		es 	= segment of ContentTextClass
		ax	= message #

		cx:dx	= OD of the PrintControlClass object
		bp	= GState handle to print (draw) to
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	If there is a text selection, copy that selection into a
	temporary ContentText object and then send(call) that object a 
	MSG_CT_PRINT_CONTENT_TEXT. And then destroy the temporary 
	ContentText object.

	Otherwise, just send(call) ourself a MSG_CT_PRINT_CONTENT_TEXT.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTPrintStartPrinting	method dynamic ContentTextClass, 
					MSG_CT_PRINT_START_PRINTING
gstate		local	hptr	push	bp	; bp needs to be first one
printControl	local	optr	push	cx, dx
transParams	local	CommonTransferParams

ForceRef	transParams
	.enter
	;
	; See if any text is selected.
	;
	call	MCGetTextSelected		; filled in transParams range
	jz	printEntireText

	;
	; Get the selected text into a transfer item.
	;
	call	MCCreateTransferItem		; fills in rest of transParams

	;
	; Get our width to use later in setting the temp ContentText width
	;
	push	bp
	mov	ax, MSG_VIS_GET_SIZE
	call	ObjCallInstanceNoLock		; cx <- width
	pop	bp
	push	cx

	;
	; Create a temp ContentText object.
	;
	call	MCCreateTempText	; ^lbx:si <- temp ContentText obj
			; The temp ContentText is instantiated in our
			; object block and ds is fixed up so:
			; ^lbx:si = *ds:si = temporary ContentText object

	;
	; Copy selection range to a temp ContentText object.
	;
	call	MCCopyTransferItemToTempText

	;
	; Set the width of the temp ContentText object.
	;   This also makes it calculate its correct height which we use
	;   while printing.
	;   NOTE: We need to set the temp ContentText width after we have
	;         copied the selection into it in order to get the corrent 
	;	  height.
	;
	pop	cx				; cx <- width
	call	ChangeTextWidth

	;
	; Tell the temp ContentText object to print itself
	;
	push	bp
	mov	ax, MSG_CT_PRINT_CONTENT_TEXT
	movdw	cxdx, printControl
	mov	bp, gstate
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; Destroy the temp ContentText object	
	;
	push	bp
	mov	ax, MSG_VIS_DESTROY
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock
	pop	bp
	jmp	done

printEntireText:
	;
	; Tell ourself to print
	;
	push	bp
	mov	ax, MSG_CT_PRINT_CONTENT_TEXT
	movdw	cxdx, printControl
	mov	bp, gstate
	call	ObjCallInstanceNoLock
	pop	bp

done:
	.leave
	ret
CTPrintStartPrinting	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCGetTextSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if any text is selected and fills in the range
		if there is a selection.

CALLED BY:	(INTERNAL) CTPrintStartPrinting
PASS:		*ds:si	= ContentText Instance
		ss:bp	= Inheritable stack frame
RETURN:		transParams.CTP_range filled in
DESTROYED:	ax, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MCGetTextSelected	proc	near
	.enter inherit CTPrintStartPrinting

	push	bp
	mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
	mov	dx, ss
	lea	bp, ss:transParams.CTP_range
	call	ObjCallInstanceNoLock
	pop	bp
	cmpdw	ss:transParams.CTP_range.VTR_start, \
		ss:transParams.CTP_range.VTR_end, ax

	.leave
	ret
MCGetTextSelected	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCCreateTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a transfer item for the text.

CALLED BY:	(INTERNAL) CTPrintStartPrinting only
PASS:		*ds:si	= ContentText Instance
		ss:bp	= Inheritable stack frame
RETURN:		filled in:
		  transParams.CTP_vmFile
		  transParams.CTP_vmBlock
		  transParams.CTP_pasteFrame
DESTROYED:	ax,cx,dx

SIDE EFFECTS:	
	Uses clipboard VM file for the transfer.
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MCCreateTransferItem	proc	near
	.enter inherit CTPrintStartPrinting

	push	bx				;Save text block
	call	ClipboardGetClipboardFile 	;bx<-VM file handle
EC <	cmp	bx, 0					>
EC <	ERROR_Z	JM_SEE_BACKTRACE	;no clipboard	>
	mov	ss:transParams.CTP_vmFile, bx
	clr	ss:transParams.CTP_vmBlock
	clr	ss:transParams.CTP_pasteFrame
	mov	dx, (size CommonTransferParams)
	pop	bx				;Recall text block
	push	bp
	lea	bp, ss:transParams
	mov	ax, MSG_VIS_TEXT_CREATE_TRANSFER_FORMAT
	call	ObjCallInstanceNoLock		; ax <- new VM block handle
	pop	bp
	mov	ss:transParams.CTP_vmBlock, ax

	.leave
	ret
MCCreateTransferItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCCreateTempText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a temporary text object that will hold the 
		selected text (which is now in a transfer item).

CALLED BY:	(INTERNAL) CTPrintStartPrinting only
PASS:		*ds:si	= ContentText Instance
RETURN:		^lbx:si	- temp ContentText obj
DESTROYED:	ax,cx,dx,di,es

SIDE EFFECTS:	
	ds - updated to point at segment of same block as on entry

PSEUDO CODE/STRATEGY:
	Create a temporary ContentText object.
	Tell the temporary text to use the clipboard vm file.
	   The temp text needs a vm file so we can copy selected graphics 
	   into it.
	Set up the temp text storage.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/21/94    	Initial version
	lester	10/20/94  	complete rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MCCreateTempText	proc	near
	class	ContentTextClass
	uses	bp
	.enter 
EC <	call	AssertIsCText					>

	; Create temporary ContentText object

	mov	di, segment ContentTextClass
	mov	es, di
	mov	di, offset ContentTextClass
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate			; ^lbx:si = temp text

	; Set the vm file for temporary ContentText

	mov_tr	cx, bx				; save temp text handle
	call	ClipboardGetClipboardFile	; bx <- vm file handle
	xchg	cx, bx			; cx <- vm file, bx <- temp text handle

	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	; Set up temporary ContentText storage

	mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
	mov	cx, mask VTSF_MULTIPLE_CHAR_ATTRS or \
			mask VTSF_MULTIPLE_PARA_ATTRS or \
			mask VTSF_GRAPHICS or \
			mask VTSF_TYPES		;ch <- no regions
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	; Get ready to make temporary ContentText same width as ourself
	; HACK here.  Manually clear the geometry invalid bit.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	BitClr	ds:[di].VI_optFlags, VOF_GEOMETRY_INVALID

	.leave
	ret
MCCreateTempText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCCopyTransferItemToTempText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies transfer item (which holds selected text)
		to temp text and frees transfer item.

CALLED BY:	(INTERNAL) CTPrintStartPrinting
PASS:		*ds:si	= ContentText Instance
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	ax, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MCCopyTransferItemToTempText	proc	near
	.enter inherit CTPrintStartPrinting

	push	bp
	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
	mov	dx, (size CommonTransferParams)
	clrdw	ss:transParams.CTP_range.VTR_start
	clrdw	ss:transParams.CTP_range.VTR_end
	lea	bp, ss:transParams
	call	ObjCallInstanceNoLock
	pop	bp

	push	bx
	mov	bx, ss:transParams.CTP_vmFile
	mov	ax, ss:transParams.CTP_vmBlock
	call	VMFree			;Get rid of xfer item
	pop	bx

	.leave
	ret
MCCopyTransferItemToTempText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTPrintContentText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the ContentText to the passed gstate for the print
		controller.

CALLED BY:	MSG_CT_PRINT_CONTENT_TEXT
PASS:		*ds:si	= ContentTextClass object
		ds:di	= CpontentTextClass instance data
		ds:bx	= ContentTextClass object (same as *ds:si)
		es 	= segment of ContentTextClass
		ax	= message #

		cx:dx	= OD of the PrintControlClass object
		bp	= GState handle to print (draw) to
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	In the print loop, we check if we are clipping any text and adjust
	the printable area so the cliped text will be printed on the next 
	page.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTPrintContentText	method dynamic ContentTextClass, 
					MSG_CT_PRINT_CONTENT_TEXT

gstate		local	hptr	push	bp	; bp needs to be first one
	;
	; Handle of gstate to draw to.
	;

printControl	local	optr	push	cx, dx
	;
	; Print control object to send messages to.
	;

printableSize	local	XYSize
	;
	; Size of the printable area on the paper.
	;

printAreaTop	local	word
	;
	; Top Y coordinate of page currently being printed.
	;			

printAreaBottom	local	word
	;
	; Bottom Y coordinate of page currently being printed.
	;
		
textHeight	local	word
	;
	; Height of text object being printed.
	;

pageCount	local	word
	;
	; The number of pages needed to print the TextObject.
	;

pageMargins	local	Rectangle
	;
	; Margins.
	;

oldTextSize	local	XYSize
	;
	; Old size of the text object. Used when we change the width of the 
	;  text object to match the printer margins.
	;

textResized	local	BooleanByte
	;
	; Flag indicating if the text object was resized to fit the
	;  printer margins.	
	;

ForceRef	printControl
ForceRef	printableSize
ForceRef	pageMargins
	.enter

	;
	; Fill in the printableSize and pageMargins local variables.
	;
	call	SetPageMarginsAndSize

	; Set up for the print loop

	mov	di, gstate
	clr	pageCount			; first page is 0
	mov	printAreaBottom, -1
		
;-----------------------------------------------------------------------------
;			      Print Loop
;-----------------------------------------------------------------------------
	;
	; di	= GState to print with
	;
	; The following local variables set:
	;	textHeight	- Height of text object (after changing
	;						 the width)
	;	printAreaBottom	- Y coordinate of the bottom of the 
	; 			   area currently being printed.
	;			  At the start of the loop printAreaBottom is
	;			   set to the bottom of the last page printed.
	;	pageCount	- Count of pages printed so far (0 based)
	;	pageMargins	- Offset to page in drawing area
	;	printableSize	- Printable size of the paper we are
	;			    printing to
printLoop:
	;
	; Set the printAreaTop 
	;
	mov	ax, printAreaBottom
	inc	ax				; don't repeat bottom line
	mov	printAreaTop, ax

	;
	; Check if we are clipping any text at the bottom of the page and
	;  set printAreaBottom
	;
	call	CheckClippingTextAndSetPrintAreaBottom

	;
	; Want to make the page self-describing.  This should force that
	; notion...
	;
	call	GrSaveState

	;
	; Set the clip rectangle so that we only draw this page.
	;
	call	SetPageClipRect			; Clip to page only

	;
	; Compute the position of the current page and translate there.
	; Account for margins too.
	;
	call	TranslateToPage			; Put drawing in right place

	;
	; Draw the text.
	;
	push	bp
	mov	bp, di				; bp <- gstate
	mov	cl, mask DF_PRINT		; cl <- DrawFlags
	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; Before finishing, restore the state of things
	;
	call	GrRestoreState

	;
	; Move down a page
	;
	mov	al, PEC_FORM_FEED
	call	GrNewPage

	;
	; Move to do next page
	;
endPrintLoop::
	; printAreaBottom is the bottom of the page we just printed
	mov	ax, printAreaBottom
	cmp	ax, textHeight			; all done?
	jae	outOfPrintLoop
	inc	pageCount			; keep track of how many pages

	jmp	printLoop			; Loop to do next page

outOfPrintLoop:

	;
	; Tell print controller the page range
	;  pageCount is based on firstPage being numbered 0
	;
	push	bp
	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	clr	cx				; first page
	mov	dx, pageCount			; last page
	call	CallPrintControl
	pop	bp

	;	
	; tell print controller that we are done
	;
	push	bp
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
	call	CallPrintControl
	pop	bp

	;
	; Restore the text size if we changed it.	
	;
	tst	textResized
	jz	afterRestoreSize	

	mov	cx, oldTextSize.XYS_width
	call	ChangeTextWidth
afterRestoreSize:

	.leave
	ret
CTPrintContentText	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckClippingTextAndSetPrintAreaBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if we will clip any text and set printAreaBottom.

CALLED BY:	(INTERNAL) CTPrintContentText
PASS:		*ds:si	= Content Text Instance
		ss:bp	= Inheritable stack frame
RETURN:		Set:
			printAreaBottom
DESTROYED:	ax,cx,dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Check if any text will be clipped by the bottom of the page.
	If so, print down to the top of the line so the clipped text 
	will be printed on the next page.

	Also check if the text line is too big to fit on a page, in which
	case it needs to be clipped somewhere, so here is a good spot.

	The same logic and code applies to graphics because they are 
	just characters.
	
	NOTE: Blank lines of text are treated just like any other lines
	      of text which might not be exactly what you want if the
	      blank lines are in a large point size and they fall on the
	      page boundary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckClippingTextAndSetPrintAreaBottom	proc	near
	uses	di
	.enter	inherit	CTPrintContentText
EC <	call	AssertIsCText				>	

	; Assume printing the full page

	mov	ax, printAreaTop
	add	ax, printableSize.XYS_height
	mov	printAreaBottom, ax

	;
	; Get the nearest character position to the bottom of the page
	;
	push	bp
	sub	sp, size PointDWFixed
	mov	bp, sp

	; ax = printAreaBottom
	clr	dx, cx
	movdw	ss:[bp].PDF_y.DWF_int, dxax
	mov	ss:[bp].PDF_y.DWF_frac, dx
	movdw	ss:[bp].PDF_x.DWF_int, dxcx
	mov	ss:[bp].PDF_x.DWF_frac, dx

	mov	ax, MSG_VIS_TEXT_GET_TEXT_POSITION_FROM_COORD
	call	ObjCallInstanceNoLock
			; ss:bp - nearest valid X and Y positions
			; dx:ax - nearest character position

	; The nearest valid XY position is the top left of the character
	movdw	dicx, ss:[bp].PDF_y.DWF_int

	add	sp, size PointDWFixed
	pop	bp

	push	cx			; save Y position of top of line

	;
	; Get the line from the character position
	;
	push	bp
	mov	cx, dx
	mov	dx, ax				; cx:dx - offset 
	mov	ax, MSG_VIS_TEXT_GET_LINE_FROM_OFFSET
	call	ObjCallInstanceNoLock
			; dx:ax - line number
			; cx:bp - offset of start of line
	pop	bp

	;
	; Get line height
	;
	call	GetLineHeight			; ax <- line height

	pop	dx			; dx <- Y position of top of line

	;
	; Check if line height is larger that the printable page height
	;	
	cmp	ax, printableSize.XYS_height
	ja	done				; line height > page height

	;
	; Check if bottom of text line is on this page
	;
	add	ax, dx				; ax <- bottom of line
	mov	cx, printAreaBottom
	cmp	ax, cx
	jbe	done			; bottom of line <= bottom of page
					;  So line is completely on 
					;  this page.
	;
	; Check if top of line is on next page
	;
	; NOTE: This does not ever seem to happe. I think this check could
	; 	be taken out.
	;
	cmp	dx, cx
	ja	done				; top of line > bottom of page
						;  So line is completely on 
						;  the next page
	;
	; Adjust printAreaBottom so text line is printed on next page
	;
	mov	printAreaBottom, dx

done:
	.leave
	ret
CheckClippingTextAndSetPrintAreaBottom	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLineHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the height of a text line.

CALLED BY:	(INTERNAL) CheckClippingTextAndSetPrintAreaBottom
PASS:		*ds:si	= Content Text Instance
		dx:ax  - line number
RETURN:		ax - line height (ceiling of WBFixed)
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/16/92	Initial version
	lester	10/20/94  	added line number as an argument

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLineHeight	proc	near		
	uses	cx, dx, di, bp

	params		local	VisTextGetLineInfoParameters
	lineInfo	local	LineInfo
	.enter	
EC <	call	AssertIsCText				>	

	lea	di, lineInfo
	movdw	params.VTGLIP_buffer, ssdi
	mov	params.VTGLIP_bsize, size lineInfo
	movdw	params.VTGLIP_line, dxax
	push	bp
	lea	bp, params
	mov	dx, ss
	mov	ax, MSG_VIS_TEXT_GET_LINE_INFO
	call	ObjCallInstanceNoLock
EC <	ERROR_C	LINE_DOES_NOT_EXIST					>
	pop	bp

	movwbf	axcl, lineInfo.LI_hgt
	ceilwbf	axcl, ax			; ax <- ceiling of height

	.leave
	ret
GetLineHeight	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPageMarginsAndSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the page margins and printableSize and other things.

CALLED BY:	(INTERNAL) CTPrintContentText
PASS:		*ds:si	= Content Text Instance
		ss:bp	= Inheritable stack frame
RETURN:		Set:
			pageMargins
			printableSize
			textResized
			oldTextSize
			textHeight
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Get printable area.
	Set document size.
	Set document margins.
	Change the width of the text object if it is wider than the
	printable width.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPageMarginsAndSize	proc	near
	uses	ax,cx,dx,di
	.enter	inherit	CTPrintContentText
EC <	call	AssertIsCText					>

	; set the doc size

	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_PAPER_SIZE
	call	CallPrintControl		; paper dimmensions -> cx, dx
	pop	bp
	push	bp
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_SIZE
	call	CallPrintControl
	pop	bp

	mov	printableSize.XYS_width, cx		; incorrect size
	mov	printableSize.XYS_height, dx		; incorrect size

	; Get the printer margins. Also set the document margins.

	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_PRINTER_MARGINS
	mov	dx, TRUE			; do set the doc margins
	call	CallPrintControl		;CKS margins => AX, CX, DX, BP
	mov	di, bp
	pop	bp

	; Store the margins in a local variable.

	mov	pageMargins.R_left, ax
	mov	pageMargins.R_top, cx
	mov	pageMargins.R_right, dx
	mov	pageMargins.R_bottom, di

	; Set the printable size.

	add	cx, di
	sub	printableSize.XYS_height, cx

	add	ax, dx
	mov	di, printableSize.XYS_width
	sub	di, ax
	mov	printableSize.XYS_width, di

	; Get text object width and height.

	push	bp
	mov	ax, MSG_VIS_GET_SIZE
	call	ObjCallInstanceNoLock		; cx <- width, dx <- height
	pop	bp

	; Check if text is wider than the printableSize
	;  di still printable width

	mov	textResized, BB_FALSE		; assume text width is OK
	mov	textHeight, dx			; assume text width is OK

	cmp	cx, di				; need to change width?
	jbe	textOkWidth

	; Save old text size

	mov	textResized, BB_TRUE
	mov	oldTextSize.XYS_width, cx
	mov	oldTextSize.XYS_height, dx

	; Change text width

	mov	cx, di
	call	ChangeTextWidth			; dx <- new height
	mov	textHeight, dx
textOkWidth:

	.leave
	ret
SetPageMarginsAndSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeTextWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the width of the text object.

CALLED BY:	(INTERNAL) SetPageMarginsAndSize, CTPrintContentText, 
		CTPrintStartPrinting
PASS:		*ds:si  - Content Text Instance
		cx	- desired text width
RETURN:		dx	- new text height
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeTextWidth	proc	near
	uses	ax,cx,bp
	.enter
EC <	call	AssertIsCText					>

	; Compute the height for the new width

	push	cx
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
	clr	dx				; dx must be 0
	; cx is new width
	call	ObjCallInstanceNoLock		; dx <- calculated height
	pop	cx
	push	dx				; save new height

	; Set the new real size

	mov	ax, MSG_VIS_SET_SIZE
	; cx = new width 
	; dx = new height
	call	ObjCallInstanceNoLock

	; Tell object that geometry has changed

	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	ObjCallInstanceNoLock

	pop	dx				; return new height

	.leave
	ret
ChangeTextWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallPrintControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the Print-Control object.

CALLED BY:	(INTERNAL) CTPrintContentText, SetPageMarginsAndSize
PASS:		ss:bp	= Inheritable stack frame
		<arguments for the message>
RETURN:		<return values from message>
DESTROYED:	<destroyed values from message>

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/26/92	Initial version
	lester	10/17/94  	added MF_FIXUP_DS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallPrintControl	proc	near
	.enter	inherit	CTPrintContentText
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
;;; callSendCommon	label	near
	push	bx, si
	movdw	bxsi, printControl
	call	ObjMessage
	pop	bx, si
	pop	di
	.leave
	ret
CallPrintControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPageClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clip all drawing to the current page.

CALLED BY:	(INTERNAL) CTPrintContentText
PASS:		di	= GState to clip in
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		NOTE: We set the clip rectangle *before* any translations
		      are applied, so the clip area is always on the part
		      of the page that is being printed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/18/94  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPageClipRect	proc	near
	uses	si
	.enter	inherit	CTPrintContentText

	;
	; Set the clip-rectangle
	;
	mov	ax, pageMargins.R_left
	mov	bx, pageMargins.R_top
	mov	cx, ax
	add	cx, printableSize.XYS_width

	mov	dx, printAreaBottom
	sub	dx, printAreaTop		; calculate printArea height
	add	dx, bx				; add in the top margin

	mov	si, PCT_REPLACE			; Replace old clip-rect
	call	GrSetClipRect			; Clip to page
	
	.leave
	ret
SetPageClipRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateToPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate all drawing operations to be in the right place

CALLED BY:	(INTERNAL) CTPrintContentText
PASS:		ss:bp	= Inheritable stack frame
		di	= GState to translate in
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/19/94  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateToPage	proc	near
	.enter	inherit	CTPrintContentText
	;
	; Calculate Y translation
	;
	clr	bx
	mov	ax, printAreaTop		; bx.ax = y pos of top of page
	
	clr	dx
	mov	cx, pageMargins.R_top
	subdw	bxax, dxcx			; account for top margin
						; bx.ax <- Y translation

	negdw	bxax				; negate to translate the
						;  text up to the clipping rect

	;
	; Calculate X translation
	;
	clr	dx
	mov	cx, pageMargins.R_left		; dx.cx <- X translation

	; Do the translation

	call	GrApplyTranslationDWord		; Translate to the right spot

	.leave
	ret
TranslateToPage	endp


ContentLibraryCode	ends



