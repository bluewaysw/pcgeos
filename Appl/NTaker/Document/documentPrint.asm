COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	NTaker
MODULE:		Document
FILE:		documentPrint.asm

AUTHOR:		Julie Tsai, Apr 27, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	julie	4/27/92		Initial revision

DESCRIPTION:
	This file contains the printing code for the NTaker app.

	$Id: documentPrint.asm,v 1.1 97/04/04 16:17:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
;	Max lengths for localized "Date:", "Keywords:", and "Title:"
;
DATE_CHARS_SIZE		equ	32
TITLE_CHARS_SIZE	equ	32
KEYWORDS_CHARS_SIZE	equ	32
DocumentPrintCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLineHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the height of a line

CALLED BY:	GLOBAL
PASS:		*ds:si - text object
RETURN:		ax - line height
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLineHeight	proc	near		uses	cx, dx, di
	params		local	VisTextGetLineInfoParameters
	lineInfo	local	LineInfo
	.enter	
	lea	di, lineInfo
	movdw	params.VTGLIP_buffer, ssdi
	mov	params.VTGLIP_bsize, size lineInfo
	clrdw	params.VTGLIP_line
	push	bp
	lea	bp, params
	mov	dx, ss
	mov	ax, MSG_VIS_TEXT_GET_LINE_INFO
	call	ObjCallInstanceNoLock
EC <	ERROR_C	LINE_DOES_NOT_EXIST					>
	pop	bp
	movwbf	axdl, lineInfo.LI_hgt
	rndwbf	axdl			;AX <- rounded height
	.leave
	ret
GetLineHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentPrintStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Message handler for MSG_PRINT_START_PRINTING
CALLED BY:	
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx:dx	= OD of the PrintControlClass object
		bp	= GState handle to print (draw) to

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/30/92   	Initial version
	JT	6/2/92		Modified to print to the real printer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentPrintStartPrinting	method dynamic NTakerDocumentClass, 
					MSG_PRINT_START_PRINTING


	push	bp
	mov	di, offset NTakerDocumentClass
	call	ObjCallSuperNoLock
	pop	bp

.warn -unref_local
	gState			local	hptr.GState	\
				push	bp
	numLines		local	word
	linesPrinted		local	word	
	noteHandle		local	dword
.warn @unref_local
	lineHeight		local	word
	localPageSizeReport	local	PageSizeReport
	dbFileHan		local	word
	docObj			local	optr
	inkObj			local	lptr
	textObj			local	lptr	;block handle for text object
	documentWidth		local	word
	documentHeight		local	word
	totalPageNum		local	word
	curPageNum		local	word
	printOption		local	word
	.enter
	clr	totalPageNum
	clr	curPageNum
	mov	bx, ds:[LMBH_handle]
	movdw	docObj, bxsi
	mov	di, ds:[si]
	add	di, ds:[di].GenDocument_offset
	mov	bx, ds:[di].GDI_fileHandle
	mov	dbFileHan, bx

	;Get the vis bounds of the ink object/ text object
	push	ds, si
	segmov	ds, ss
	lea	si, localPageSizeReport
	call	InkGetDocPageInfo
	pop	ds, si

	;check which print option gets selected - page, note or folder
	push	bp
	GetResourceHandleNS PrintPageRangeList, bx
	mov	si, offset PrintPageRangeList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;ax = selection
	pop	bp
	mov	printOption, ax

	;Print out notes in the folders: 
	;create both ink object and text object

	;Create the special Text object for printing
	call	PrintCreateTextObject
	mov	textObj, si

	mov	cx, localPageSizeReport.PSR_width.low
	mov	dx, localPageSizeReport.PSR_height.low
	sub	cx, localPageSizeReport.PSR_margins.PCMP_left
EC <	ERROR_C	INVALID_MARGINS						>
	sub	cx, localPageSizeReport.PSR_margins.PCMP_right
EC <	ERROR_C	INVALID_MARGINS						>
	sub	dx, localPageSizeReport.PSR_margins.PCMP_top
EC <	ERROR_C	INVALID_MARGINS						>
	sub	dx, localPageSizeReport.PSR_margins.PCMP_bottom
EC <	ERROR_C	INVALID_MARGINS						>
	mov	documentWidth, cx
	mov	documentHeight, dx

	mov	dx, MAX_COORD
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLockSaveBP

;	Make the object have invalid geometry, as the text object does
; 	something special when it gets valid geometry.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].VI_optFlags, not mask VOF_GEOMETRY_INVALID
	
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	ObjCallInstanceNoLockSaveBP

	call	GetLineHeight			;Returns AX <- line height
	mov	lineHeight, ax

	;Create the special Ink object for printing
	call	PrintCreateInkObject
	mov	inkObj, si

	mov	cx, documentWidth
	mov	dx, documentHeight
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLockSaveBP

	;set background for the ink object
	mov	bx, dbFileHan
	call	PrintSetBackground

	;set up the document size for PrintControl Object

	push	bp
	mov	cx, localPageSizeReport.PSR_width.low
	mov	dx, localPageSizeReport.PSR_height.low
	GetResourceHandleNS NTakerPrintControl, bx
	mov	si, offset NTakerPrintControl
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_SIZE
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	;send message to the print control class to set the document margin
	push	bp
	mov	dx, ss
	lea	bp, localPageSizeReport.PSR_margins
	GetResourceHandleNS NTakerPrintControl, bx
	mov	si, offset NTakerPrintControl
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_MARGINS
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	;now, check the print options and decide what to print

	mov	si, docObj.chunk		;*ds:si = NTakerDocumentClass
	mov	di, printOption
	shl	di
EC <	cmp	di, offset printRouts + size printRouts - size nptr	>
EC <	ERROR_A	-1							>
	call	cs:[printRouts][di]

	;Destroy the objects we created for printing

	mov	bx, docObj.handle
	call	MemDerefDS

	mov	si, inkObj
	call	DestroyObj

	mov	si, textObj
	call	DestroyObj

	GetResourceHandleNS NTakerPrintControl, bx
	mov	si, offset NTakerPrintControl
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
NTakerDocumentPrintStartPrinting	endm

printRouts	nptr	PrintCurrentPage,
			PrintCurrentCard,
			PrintCurrentTopic,
			PrintAllCards

PrintCurrentPage	proc	near
	.enter inherit NTakerDocumentPrintStartPrinting
	;print out the current page
	call	NTakerDocPrintGetCurNote	;*ds:si = NTakerDocumentClass
	movdw	noteHandle, axdi	
	call	NTakerDocPrintGetCurPage	;cx = current page number
	mov	curPageNum, cx
	mov	totalPageNum, 1
	call	NTakerDocumentPrintCard	
	.leave
	ret
PrintCurrentPage	endp

PrintCurrentTopic	proc	near
	.enter
	call	NTakerDocPrintGetFileHandle
	call	NTakerDocPrintGetCurFolder
	call	PrintCurrentFolderDepthFirstTraverse
	.leave
	ret
PrintCurrentTopic	endp

PrintAllCards	proc	near
	.enter
	call	NTakerDocPrintGetFileHandle
	call	InkDBGetHeadFolder	;ax:di <= folder at top of tree
	call	PrintCurrentFolderDepthFirstTraverse
	.leave
	ret
PrintAllCards	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintCreateInkObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Create a special ink object on the fly while printing
CALLED BY:	NTakerDocumentPrintStartPrinting
PASS:		nothing
RETURN:		^lbx:si - new ink object
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	6/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintCreateInkObject	proc	near	uses	bp
	.enter

	mov	bx, ds:[LMBH_handle]
	GetResourceSegmentNS	NTakerInkClass, es
	mov	di, offset NTakerInkClass
	call	ObjInstantiate		;bx:si = new object

	.leave
	ret
PrintCreateInkObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintCreateTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Create a special text object on the fly while printing
CALLED BY:	NTakerDocumentPrintStartPrinting
PASS:		nothing
RETURN:		^lbx:si - new text object
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	6/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintCreateTextObject	proc	near	uses	bp
	
	.enter

	mov	ax, segment VisTextClass
	mov	es, ax
	mov	di, offset VisTextClass
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate		;bx:si = new object

	sub	sp, size VisTextSetFontIDParams
	mov	bp, sp
	movdw	ss:[bp].VTSFIDP_range.VTR_start, 0
	movdw	ss:[bp].VTSFIDP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTSFIDP_fontID, NTAKER_DOCUMENT_PRINT_FONT_TYPE
	mov	ax, MSG_VIS_TEXT_SET_FONT_ID
	call	ObjCallInstanceNoLock
	add	sp, size VisTextSetFontIDParams

	sub	sp, size VisTextSetPointSizeParams
	mov	bp, sp
	movdw	ss:[bp].VTSPSP_range.VTR_start, 0
	movdw	ss:[bp].VTSPSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTSPSP_pointSize.WWF_int, NTAKER_DOCUMENT_PRINT_FONT_SIZE
	clr	ss:[bp].VTSPSP_pointSize.WWF_frac
	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	call	ObjCallInstanceNoLock
	add	sp, size VisTextSetPointSizeParams


;	Append a character, so the text object will create a LineInfo structure
;	so we can get the height of a line.

	mov	ax,  MSG_VIS_TEXT_APPEND
	mov	dx, cs
	mov	bp, offset hackChar
	mov	cx, length hackChar
	call	ObjCallInstanceNoLock
	.leave
	ret
PrintCreateTextObject	endp
hackChar	char	'A'

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Setup the background type for the ink object
CALLED BY:	NTakerDocumentPrintStartPrinting
PASS:		bx - database file handle
		*ds:si - ink object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	6/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintSetBackground	proc	near
	.enter

	call	InkGetDocGString	;ax = gstring of background type
	mov	cx, ax			;cx = gstring of backgroud type
	mov	ax, MSG_NTAKER_INK_SET_BACKGROUND
	call	ObjCallInstanceNoLockSaveBP

	.leave
	ret
PrintSetBackground	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Routine to call MSG_VIS_DESTROY
CALLED BY:	NTakerDocumentPrintStartPrinting
PASS:		*ds:si - optr of the object to be destroyed
RETURN:		nothing
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	6/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyObj	proc	near
	.enter

	mov	ax, MSG_VIS_DESTROY
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLockSaveBP

	.leave
	ret
DestroyObj	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBoxTopAndBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the top and bottom coords of the info box

CALLED BY:	GLOBAL
PASS:		bx - # lines in box 
RETURN:		bx - top
		dx - bottom of box
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBoxTopAndBottom	proc	near	uses	si, ax
	.enter

	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics			;
	mov_tr	ax, dx				;AX <- height
	add	ax, NTAKER_DOCUMENT_PRINT_BOX_SPACE_BETWEEN_LINES
	mul	bl
	mov	bx, NTAKER_DOCUMENT_PRINT_BOX_TOP_BOTTOM_MARGIN

	mov	dx, bx
	add	dx, ax

	.leave
	ret
GetBoxTopAndBottom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateTextBelowInfoBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translates the text below the information box.

CALLED BY:	GLOBAL
PASS:		di - gstate
RETURN:		dx - amount translated
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateTextBelowInfoBox	proc	near	uses	ax, bx, cx
	.enter
	call	GetPrintingInfo		;Find out what we are printing
	clr	bx
	tst	ax			;If not printing anything, exit
	jz	exit
	shl	ax
	adc	bx, 0
	shl	ax
	adc	bx, 0
	shl	ax
	adc	bx, 0			;BX <- # lines of info being printed
	call	GetBoxTopAndBottom	;
	tst	dx
	jz	exit
	add	dx, NTAKER_DOCUMENT_SPACE_BELOW_BOX_TO_PRINT_TEXT
	mov	bx, dx
	clr	dx,cx,ax
	call	GrApplyTranslation
	mov	dx, bx
exit:
	.leave
	ret
TranslateTextBelowInfoBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentPrintCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prints out the passed page of the current card. If it spans 
		multiple pages on the output device, special stuff is done.

CALLED BY:	NTakerDocumentPrintStartPrinting
		PrintCurrentCard
		PrintFolderTraverseCallBack
PASS:		inherit local variables from routines that calls it
RETURN:		nothing
DESTROYED:	ax, cx, dx, ds, si
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentPrintCard	proc	far
	class	NTakerDocumentClass
	uses	bp,bx,di,ds
	.enter inherit NTakerDocumentPrintStartPrinting
	movdw	bxsi, docObj
	call	MemDerefDS		;*ds:si = NTakerDocumentClass

	movdw	axdi, noteHandle
	call	NTakerDocPrintGetFileHandle
	call	InkNoteGetNoteType
	clr	ch
	mov	di, cx
EC <	cmp	di, offset printPageRouts + size printPageRouts - size nptr>
EC <	ERROR_A	-1						>
	call	cs:printPageRouts[di]


	;check if it is the end of the note
	inc	curPageNum
	mov	ax, curPageNum	
	cmp	ax, totalPageNum
	clc
	jne	exit
	stc
exit:
	.leave
	ret
NTakerDocumentPrintCard	endp

printPageRouts	nptr	PrintInkPage, PrintTextCard



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintPageOfText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prints out a page worth of text

CALLED BY:	GLOBAL
PASS:		ax - height of text area to print
		bx - Y offset into document to print
		di - gstate to draw through (with translation already set up)
		ds - object block
RETURN:		ax - # lines printed
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintPageOfText	proc	near	uses	bx, cx, dx
	.enter inherit NTakerDocumentPrintStartPrinting
	
	clr	dx
	div	lineHeight		;AX <- # lines we'll print
	push	ax
	mul	lineHeight		;AX <- height of document in integral
					; # lines
	push	bx
	clr	bx
	mov_tr	dx, ax
	clr	ax
	mov	cx, documentWidth
	mov	si, PCT_INTERSECTION
	call	GrSetClipRect

	pop	bx			;BX <- Y offset into document to print
	clr	ax, cx, dx
	negwwf	bxax
	call	GrApplyTranslation

	push	bp			;save local variables
	mov	si, textObj
	mov	bp, di			;DI <- GState to draw through
	mov	ax, MSG_VIS_DRAW
	mov	cl, mask DF_PRINT
	call	ObjCallInstanceNoLock
	pop	bp

	pop	ax			;Return # lines printed

	.leave
	ret
PrintPageOfText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateToMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up a translation to the current margin

CALLED BY:	GLOBAL
PASS:		ss:bp - stack frame
		di - gstate
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateToMargins	proc	near	uses	ax, bx, cx, dx
	.enter inherit NTakerDocumentPrintStartPrinting
	mov	bx, localPageSizeReport.PSR_margins.PCMP_top
	mov	dx, localPageSizeReport.PSR_margins.PCMP_left
	clr	cx
	clr	ax
	call	GrApplyTranslation
	.leave
	ret
TranslateToMargins	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintTextCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prints out a text card

CALLED BY:	GLOBAL
PASS:		ss:bp - stack frame
		*ds:si - doc object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintTextCard	proc	near
	.enter inherit NTakerDocumentPrintStartPrinting

;	Print out the card information at the top of the screen.

	mov	di, gState
	call	GrSaveState
	call	TranslateToMargins
	call	PrintCardInfo

;	Load the text object with the note data

	movdw	axdi, noteHandle
	call	NTakerDocPrintGetFileHandle
	mov	cx, curPageNum
	mov	dx, ds:[LMBH_handle]
	mov	si, NT_TEXT
	push	bp
	mov	bp, textObj
	call	InkNoteLoadPage
	pop	bp

	
	mov	si, textObj
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
	mov	cx, documentWidth
	clr	dx				;Don't cache the width
	call	ObjCallInstanceNoLockSaveBP	;
	mov_tr	ax, dx				;AX <- height of text object
	clr	dx
	div	lineHeight			;AX <- # lines in text object
	mov	numLines, ax

	mov	di, gState
	call	TranslateTextBelowInfoBox	;DX <- offset into document
						; to print text.
	mov	ax, documentHeight
	sub	ax, dx				;AX <- height of text to
						; print.
	clr	linesPrinted
	clr	bx
loopTop:

;	BX <- Y offset of first line of text to print
;	AX <- Height of area of document we want to print

	call	PrintPageOfText			;Returns AX = # lines printed
	call	GrRestoreState
	push	ax
	mov	al, PEC_FORM_FEED
	call	GrNewPage
	pop	ax
	add	ax, linesPrinted
	cmp	ax, numLines
	jae	done
	mov	linesPrinted, ax
	
	mul	lineHeight			;BX <- offset to next line to
       	mov_tr	bx, ax
	mov	ax, documentHeight
	call	GrSaveState
	call	TranslateToMargins
	jmp	loopTop
done:
	 .leave
	ret
PrintTextCard	endp

ObjCallInstanceNoLockSaveBP	proc	near
	push	bp
	call	ObjCallInstanceNoLock
	pop	bp
	ret
ObjCallInstanceNoLockSaveBP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintInkPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print out a page of ink data.

CALLED BY:	GLOBAL
PASS:		ss:bp - stack frame
		*ds:si - doc object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintInkPage	proc	near
	.enter inherit NTakerDocumentPrintStartPrinting

;	Load up the ink print object with the ink data.

	movdw	axdi, noteHandle
	call	NTakerDocPrintGetFileHandle
	mov	cx, curPageNum
	mov	dx, ds:[LMBH_handle]
	mov	si, NT_INK
	push	bp
	mov	bp, inkObj
	call	InkNoteLoadPage
	pop	bp

;	Translate the ink data to start at the edge of the margins.

	mov	di, gState
	call	TranslateToMargins

	push	bp			;save local variables
	mov	si, inkObj
	mov	bp, di			;DI <- GState to draw through
	mov	ax, MSG_VIS_DRAW
	mov	cl, mask DF_PRINT
	call	ObjCallInstanceNoLock
	pop	bp

;	Print the information at the top of the page

	mov	si, docObj.chunk
	call	PrintCardInfo

;	Go to the next page (This nukes all GState settings)

	mov	di, gState
	mov	al, PEC_FORM_FEED
	call	GrNewPage
	.leave
	ret
PrintInkPage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintCurrentCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Print out pages in the current note
CALLED BY:	NTakerDocumentPrintStartPrinting
PASS:		local variables inherited from NTakerDocumentPrintStartPrinting
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintCurrentCard	proc	near
	class	NTakerDocumentClass
	uses	bp, bx, dx, ds, si, di
	.enter inherit NTakerDocumentPrintStartPrinting

	movdw	bxsi, docObj
	call	MemDerefDS			;*ds:si = NTakerDocumentClass

	call	NTakerDocPrintGetCurNote	;
	movdw	noteHandle, axdi
	call	NTakerDocPrintGetFileHandle
	call	InkNoteGetPages		;ax.di-group/item of DB item containing
					;chunk array of page info
	call	InkNoteGetNumPages	;cx = total number of pages in a note
	mov	totalPageNum, cx
	clr	curPageNum

	call	DBLockDSSI
	mov	bx, cs
	mov	di, offset NTakerDocumentPrintCard
	call	ChunkArrayEnum		;pass *ds:si -- array
					;bx:di -- offset of callback routine
					;destroyed -- bx
	mov	bx, dbFileHan
	call	DBUnlockDS
	.leave
	ret
PrintCurrentCard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintCurrentFolderDepthFirstTraverse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Depth first traverse through all the notes in the folers
		and its subfolders and print out pages of notes
CALLED BY:	NTakerDocumentPrintStartPrinting
PASS:		local variables inherited from NTakerDocumentPrintStartPrinting
		ax.di - folder to start printing at
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintCurrentFolderDepthFirstTraverse	proc	near
	class	NTakerDocumentClass
	uses	bp
	.enter inherit NTakerDocumentPrintStartPrinting

	push	ax, di
	movdw	bxsi, docObj
	call	MemDerefDS
	pop	ax, di
	call	NTakerDocPrintGetFileHandle	;*ds:si = NTakerDocumentClass



;PASS to InkFolderDepthFirstTraverse
;		AX.DI - folder at top of tree
;		BX - file handle
;		CX:DX - far ptr to callback routine
;		BP - extra data to pass to callback routine

	mov	cx, cs
	mov	dx, offset PrintFolderTraverseEachNoteCallBack
	call	InkFolderDepthFirstTraverse

	.leave
	ret
PrintCurrentFolderDepthFirstTraverse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintFolderTraverseEachNoteCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Callback routine for PrintCurrentFolderDepthFirstTraverse
		to traverse through each note in a folder
CALLED BY:	PrintCurrentFolderDepthFirstTraverse
PASS:		AX.DI - folder at top of tree
		bx - file handle
RETURN:		nothing
DESTROYED:	ds, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintFolderTraverseEachNoteCallBack	proc	far
	uses	ax,bx,cx,dx,di,bp
	.enter inherit NTakerDocumentPrintStartPrinting

	call	InkFolderGetContents
	movdw	axdi, dxcx		;AX.DI = group/item of chunk array of
					;notes
	call	DBLockDSSI
	mov	bx, cs
	mov	di, offset PrintPageTraverseCallBack
	call	ChunkArrayEnum		;pass: *ds:si -- array
	mov	bx, dbFileHan
	call	DBUnlockDS

	.leave
	ret
PrintFolderTraverseEachNoteCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintPageTraverseCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Callback for PrintFolderTraverseEachNoteCallBack
		to print out the note page by page
CALLED BY:	PrintFolderTraverseEachNoteCallBack
PASS:		*ds:si - array
		ds:di - a ptr to the handle of the current note in the array
RETURN:		carry set to end enumeration
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintPageTraverseCallBack	proc	far
	uses	bx,bp,ds,si,di
	.enter inherit NTakerDocumentPrintStartPrinting

	mov	bx, dbFileHan
	mov	ax, ds:[di].DBGI_group
	mov	di, ds:[di].DBGI_item
	movdw	noteHandle, axdi

	call	InkNoteGetPages		;ax.di-group/item of DB item containing
					;chunk array of page info
	call	InkNoteGetNumPages	;cx = total number of pages in a note
	mov	totalPageNum, cx
	clr	curPageNum

	call	DBLockDSSI
	mov	bx, cs
	mov	di, offset NTakerDocumentPrintCard
	call	ChunkArrayEnum		;pass *ds:si -- array
					;bx:di -- offset of callback routine
					;destroyed -- bx
	mov	bx, dbFileHan
	call	DBUnlockDS

	clc

	.leave
	ret
PrintPageTraverseCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitGStateForBoxInformation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Set the clip region of the text

CALLED BY:	PrintCardInfo
PASS:		di = GState
		cx = width of the paper
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitGStateForBoxInformation	proc	near	uses	ax, cx, dx
	.enter

;GrSetClipRect:
;PASS:		DI	= GState handle
;		SI	= PathCombineType
;			PCT_NULL, PCT_REPLACE, PCT_UNION, PCT_INTERSECTION
;		AX = Left, BX = Top, CX	= Right, DX = Bottom
;
;	clr	ax
;	clr	bx
;	mov	dx, MAX_COORD
;	mov	si, PCT_INTERSECTION
;	call	GrSetClipRect

	;set the font
	mov	cx, NTAKER_DOCUMENT_PRINT_FONT_TYPE
	mov	dx, NTAKER_DOCUMENT_PRINT_FONT_SIZE
	clr	ah
	call	GrSetFont

	mov	ah, CF_INDEX
	mov	al, C_WHITE
	call	GrSetAreaColor

	mov	ah, CF_INDEX
	mov	al, C_BLACK
	call	GrSetLineColor

	.leave
	ret
InitGStateForBoxInformation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintCardInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Find out which printing position is selected 
CALLED BY:	NTakerDocumentPrintStartPrinting
PASS:		di = GState
		*ds:si = NTakerDocumentClass
		ss:bp - stack frame
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintCardInfo	proc	near	uses	bp
	.enter	inherit NTakerDocumentPrintStartPrinting

	mov	cx, documentWidth
	call	InitGStateForBoxInformation

	call	GetPrintingInfo		;If no printing bits selected, exit
	tst	ax
	jz	done

	push	di, bp, cx, dx, si
	GetResourceHandleNS PrintPageInfoPositionList, bx
	mov	si, offset PrintPageInfoPositionList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;ax = selection
	pop	di, bp, cx, dx, si
	jc	done			;carry set : no selection


	push	ax
	movdw	axbp, noteHandle
	call	FindTextMaxWidth
	cmp	bx, cx			;If text is wider than the
	jb	normalLength		; paper, then use the width of
	mov	bx, cx			; the paper instead.
	sub	bx, NTAKER_DOCUMENT_PRINT_BOX_LEFT_RIGHT_MARGIN*2
normalLength:
	pop	dx
	call	DrawBox
	call	DrawInfo
done:
	.leave
	ret
PrintCardInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindTextMaxWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Find out the maximum text width and height among 
		creation date, title and keyword string
CALLED BY:	PrintCardInfo
PASS:		di = GState
		*ds:si = NTakerDocumentClass
		ax.bp = current note handle
		
RETURN:		bx - max text width

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

GrTextWidth:
PASS:		ds:si = ptr to the text.
		di = GState.
		cx = max number of characters to check.
RETURN:		dx.ah = width of the string (in points) (GrTextWidthWBFixed)
		dx    = width of the string (in points) (GrTextWidth)
		
GrFontMetrics:
PASS:		di - GState handle.
		si - information to return (GFM_info) -- GFMI_HEIGHT
RETURN:		if GFM_ROUNDED set:
			dx - requested information (rounded)
		else:
			dx.ah - requested information (WBFixed)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindTextMaxWidth	proc	near
	uses	ax,cx,dx,si,di,bp,ds,es
	dateBuffer	local	DATE_TIME_BUFFER_SIZE + DATE_CHARS_SIZE dup (char)
	titleBuffer	local	INK_DB_MAX_TITLE_SIZE + TITLE_CHARS_SIZE	dup (char)
	keywordBuffer	local	INK_DB_MAX_NOTE_KEYWORDS_SIZE + KEYWORDS_CHARS_SIZE	dup (char)
	maxWidth	local	word
	gState		local	word
	noteHandle	local	dword
	.enter

	mov	noteHandle.high, ax
	mov	ax, ss:[bp]
	mov	noteHandle.low, ax

	mov	gState, di

	call	GetPrintingInfo			;ax = bit set

	test	ax, mask PI_DATE
	jz	titleBitSet

	push	ds, si, ax

	;get note creation date in *ds:si
	push	di
	segmov	es, ss
	lea	di, dateBuffer			;ES:DI <- ptr to dateBuffer
	pushdw	axbp
	movdw	axbp, noteHandle
	call	GetNoteCreationDate		;*es:di = text
	popdw	axbp

	segmov	ds, es
	mov	si, di				;ds:si = string to draw

	;find out the number of characters in the text string
	call	GetStringSizeDSSI
	pop	di

	call	GrTextWidth
	mov	maxWidth, dx
	
	pop	ds, si, ax

titleBitSet:
	test	ax, mask PI_TITLE
	jz	keywordBitSet
	push	ds, si, ax

	;get note title in *ds:si
	pushdw	diax
	movdw	axdi, noteHandle
	call	NTakerDocPrintGetFileHandle
	segmov	ds, ss
	lea	si, titleBuffer			;DS:SI <- ptr to titleBuffer

	;copy "Title:" to titleBuffer
	push	si
	call	CopyPrintTitleString
	call	InkGetTitle			;cx = length of name with null
	pop	si
	call	GetStringSizeDSSI
	mov	di, gState
	call	GrTextWidth
	cmp	dx, maxWidth
	jb	nextOne
	mov	maxWidth, dx

nextOne:
	popdw	diax

	pop	ds, si, ax

keywordBitSet:
	test	ax, mask PI_KEYWORDS
	push	ds, si, ax
	jz	common

	;get note keyword in *ds:si
	pushdw	diax
	movdw	axdi, noteHandle
	call	NTakerDocPrintGetFileHandle
	segmov	ds, ss
	lea	si, keywordBuffer		;DS:SI <- ptr to keywordBuffer

	;copy "Keyword:" to keywordBuffer
	push	si
	call	CopyPrintKeywordString
	call	InkNoteGetKeywords	
	pop	si
	call	GetStringSizeDSSI
	mov	di, gState
	call	GrTextWidth
	cmp	dx, maxWidth
	jb	nextNextOne
	mov	maxWidth, dx
nextNextOne:
	popdw	diax

common:
	pop	ds, si, ax

	mov	bx, maxWidth

	.leave
	ret
FindTextMaxWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPrintTitleString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Copy the string "Title: " into ds:si
CALLED BY:	
PASS:		*ds:si - destination of string copy
RETURN:		*ds:si - result string
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyPrintTitleString	proc	near	uses	ax,bx,es,di
	.enter

	segmov	es, ds
	mov	di, si

	mov	bx, handle PrintTitleString
	call	MemLock
	mov	ds, ax
	mov	si, offset PrintTitleString
	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx
	rep movsb
	call	MemUnlock

	segmov	ds, es
	mov	si, di
	dec	si

	.leave
	ret
CopyPrintTitleString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPrintKeywordString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Copy the string "Keyword: " into ds:si
CALLED BY:	
PASS:		*ds:si - destination of string copy
RETURN:		*ds:si - result string
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyPrintKeywordString	proc	near	uses	ax,bx,es,di
	.enter

	segmov	es, ds
	mov	di, si

	mov	bx, handle PrintKeywordString
	call	MemLock
	mov	ds, ax
	mov	si, offset PrintKeywordString
	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx
	rep movsb
	call	MemUnlock

	segmov	ds, es
	mov	si, di
	dec	si

	.leave
	ret
CopyPrintKeywordString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStringSizeDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the length of the string in es:di

CALLED BY:	GLOBAL
PASS:		DS:SI <- null term string
RETURN:		cx - length of string w/o null
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStringSizeDSSI	proc	near	uses	es, di, ax
	.enter
	segmov	es, ds
	mov	di, si
	mov	cx, -1
	clr	al
	repne	scasb
	not	cx
	dec	cx
	.leave
	ret
GetStringSizeDSSI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPrintingInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Print out the user inquired information onto the GState
		such as creation date, note title, and note keyword
CALLED BY:	Internal
PASS:		di = GState
		*ds:si = NTakerDocumentClass
		cx = width of the paper
		dx = height of the paper
RETURN:		ax = bit set in the record
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPrintingInfo	proc	near
	class	NTakerDocumentClass
	uses	bx,cx,dx,si,di,bp
	.enter

	GetResourceHandleNS PrintPageInfoList, bx
	mov	si, offset PrintPageInfoList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GetPrintingInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNoteCreationDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get the creation date of the note
CALLED BY:
PASS:		
		*ds:si = NTakerDocumentClass
		ax.bp = current note handle
		*es:di = creation date string
RETURN:		*es:di = creation date string
DESTROYED:	ax,bx,cx,dx,bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNoteCreationDate	proc	near	uses	bx, di, si
	class	NTakerDocumentClass
	noteHandle	local	dword
	.enter

	mov	noteHandle.high, ax
	mov	ax, ss:[bp]
	mov	noteHandle.low, ax

	
	;copy "Date:" to the creation date text buffer
	push	ds, si
	mov	bx, handle PrintDateString
	call	MemLock
	mov	ds, ax
	mov	si, offset PrintDateString
	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx
	rep movsb
	call	MemUnlock
	pop	ds, si

	push	di
	movdw	axdi, noteHandle
	call	NTakerDocPrintGetFileHandle
	call	InkNoteGetCreationDate		;cx = date, dx = time
	pop	di
	dec	di				;ES:DI <- ptr to dest for date
	movdw	axbx, cxdx		
	mov	si, DTF_LONG_NO_WEEKDAY
	call	LocalFormatDateTime

	.leave
	ret
GetNoteCreationDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw a border box around texts at the top of the page
CALLED BY:	PrintCardInfo
PASS:		di = GState
		*ds:si = NTakerDocumentClass
		bx = max width of the text
		cx = width of the paper
		dx - PageInfoPosition
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawBox	proc	near	uses	ax,bx,cx,dx
	position	local	PageInfoPosition	\
			push	dx
	count		local	word
	textWidth	local	word
	paperWidth	local	word
	.enter

	clr	count
	mov	textWidth, bx
	mov	paperWidth, cx

	call	GetPrintingInfo			;ax = bit set

	shl	ax
	adc	count, 0
	shl	ax
	adc	count, 0
	shl	ax
	adc	count, 0
	mov	ax, textWidth
	mov	cx, paperWidth
	mov	bx, position
EC <	cmp	bx, length posRouts					>
EC <	ERROR_AE	-1						>
	shl	bx
	call	cs:[posRouts][bx]
	mov	bx, count
	call	GetBoxTopAndBottom
	call	GrFillRect
	call	GrDrawRect

	.leave
	ret
DrawBox	endp

posRouts	nptr	FindBoxPositionAtTopCenter, 
			FindBoxPositionAtUL, 
			FindBoxPositionAtUR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Print out the note information at the top of the page
CALLED BY:	PrintCardInfo
PASS:		di = GState
		*ds:si = NTakerDocumentClass
		ax.bp = current note handle
		bx = max width of the text
		cx = width of the paper
		dx - PageInfoPosition
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawInfo	proc	near	uses	di
	position	local	PageInfoPosition	\
			push	dx
	textWidth	local	word			\
			push	bx	
	paperWidth	local	word			\
			push	cx
	gstate		local	hptr			\
			push	di
	dateBuffer	local	DATE_TIME_BUFFER_SIZE + DATE_CHARS_SIZE dup (char)
	titleBuffer	local	INK_DB_MAX_TITLE_SIZE + TITLE_CHARS_SIZE	dup (char)
	keywordBuffer	local	INK_DB_MAX_NOTE_KEYWORDS_SIZE + KEYWORDS_CHARS_SIZE	dup (char)
	count		local	word
	
	noteHandle	local	dword
	.enter

	mov	noteHandle.high, ax
	mov	ax, ss:[bp]
	mov	noteHandle.low, ax

	call	GetPrintingInfo			;ax = bit set

	clr	count
	test	ax, mask PI_TITLE
	jz	keywordBitSet
	inc	count

	;get note title in *ds:si
	push	ds, si

	push	ax
	movdw	axdi, noteHandle
	call	NTakerDocPrintGetFileHandle
	segmov	ds, ss
	lea	si, titleBuffer		;DS:SI <- ptr to titleBuffer

	;copy "Title:" to titleBuffer
	call	CopyPrintTitleString
	call	InkGetTitle		;cx = length of name with null
	pop	ax

	lea	si, titleBuffer
	call	DrawTextInfo
	pop	ds, si

keywordBitSet:
	test	ax, mask PI_KEYWORDS
	jz	dateBitSet
	push	ds, si
	inc	count

	;get note keyword in *ds:si
	push	ax
	movdw	axdi, noteHandle
	call	NTakerDocPrintGetFileHandle
	segmov	ds, ss
	lea	si, keywordBuffer		;DS:SI <- ptr to keywordBuffer

	;copy "Keyword:" to keywordBuffer
	call	CopyPrintKeywordString
	call	InkNoteGetKeywords
	pop	ax

	lea	si, keywordBuffer
	call	DrawTextInfo
	pop	ds, si
dateBitSet:
	test	ax, mask PI_DATE
	jz	done
	inc	count

	;get note creation date in ds:si

	segmov	es, ss
	lea	di, dateBuffer		;ES:DI <- ptr to dateBuffer

	push	ax, bp
	movdw	axbp, noteHandle
	call	GetNoteCreationDate		;*es:di = text
	pop	ax, bp

	push	ds, si
	segmov	ds, ss
	lea	si, dateBuffer
	call	DrawTextInfo
	pop	ds, si
done:
	.leave
	ret

DrawTextInfo:
	mov	di, gstate
	push	ax
	mov	ax, textWidth		;
	mov	cx, paperWidth		;
	mov	bx, position
	shl	bx
	call	cs:[posRouts][bx]	;AX <- X position of left edge of box
					;CX <- X position of right edge of box
	add	ax, NTAKER_DOCUMENT_PRINT_BOX_LEFT_RIGHT_TEXT_MARGIN
	sub	cx, NTAKER_DOCUMENT_PRINT_BOX_LEFT_RIGHT_TEXT_MARGIN
	call	GrSaveState

;	Set up a clip rectangle so the text can be drawn to the screen
;	without overlapping the edge of the box

	push	dx, si
	mov	si, PCT_INTERSECTION
	clr	bx
	mov	dx, MAX_COORD
	call	GrSetClipRect
	pop	dx, si

;	Get the Y position to draw

	mov	bx, count
	call	GetYPositionForText

	clr	cx
	call	GrDrawText
	call	GrRestoreState
	pop	ax
	retn
DrawInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetYPositionForText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Find out the position of the text on a page
CALLED BY:	
PASS:		di = GState
		bx = current line being drawn (1-3)
RETURN:		bx - y position to draw
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetYPositionForText	proc	near	uses	dx
	.enter
	dec	bx
	call	GetBoxTopAndBottom
	mov	bx, dx
	add	bx, NTAKER_DOCUMENT_PRINT_BOX_SPACE_BETWEEN_LINES/2
	.leave
	ret
GetYPositionForText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindBoxPositionAtTopCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Find out the position of the box to draw around the text
CALLED BY:	
PASS: 		ax = max width of the text
		cx = right bound of the Vis Object
RETURN:		ax = left bound of the Box to be drawn on the screen
		cx = right bound of the Box
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindBoxPositionAtTopCenter	proc	near
	.enter


	add	ax, NTAKER_DOCUMENT_PRINT_BOX_LEFT_RIGHT_TEXT_MARGIN*2
	shr	ax, 1			;AX <- 1/2 width of box

	shr	cx, 1			;CX <- center of document
	mov	dx, cx
	add	cx, ax			;CX <- right edge of box
	sub	dx, ax			;DX <- left edge of box
	mov_tr	ax, dx
	.leave
	ret
FindBoxPositionAtTopCenter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindBoxPositionAtUR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Find out the position of the box to draw around the text
CALLED BY:	
PASS: 		ax = max width of the text
		cx = right bound of the Vis Object
RETURN:		ax = left bound of the Box to be drawn on the screen
		cx = right bound of the Box

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindBoxPositionAtUR	proc	near	
	.enter


	sub	cx, NTAKER_DOCUMENT_PRINT_BOX_LEFT_RIGHT_MARGIN
				;CX <- right edge of text
	push	cx
	sub	cx, ax
	mov_tr	ax, cx
	sub	ax, NTAKER_DOCUMENT_PRINT_BOX_LEFT_RIGHT_TEXT_MARGIN * 2
	pop	cx

	

	.leave
	ret
FindBoxPositionAtUR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindBoxPositionAtUL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Find out the position of the box to draw around the text

CALLED BY:	
PASS:		ax = max width of the text
		cx = right bound of the Vis Object
RETURN:		
		ax = left bound of the Box to be drawn on the screen
		cx = right bound of the Box

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindBoxPositionAtUL	proc	near
	.enter

	mov_tr	cx, ax		;CX <- width of text
	mov	ax, NTAKER_DOCUMENT_PRINT_BOX_LEFT_RIGHT_MARGIN
	add	cx, NTAKER_DOCUMENT_PRINT_BOX_LEFT_RIGHT_TEXT_MARGIN*2
	.leave
	ret
FindBoxPositionAtUL	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	Utilities

------------------------------------------------------------------------------@
DBLockDSSI	proc	near	uses di, es
	.enter
	call	DBLock
	segmov	ds, es
	mov	si, di
	.leave
	ret
DBLockDSSI	endp

;---

DBUnlockDS	proc	near
	segxchg	ds, es
	call	DBUnlock
	segxchg	ds, es
	ret
DBUnlockDS	endp

;---

NTakerDocPrintDeref_DSDI	proc	near
EC <	push	es							>
EC <	GetResourceSegmentNS	NTakerDocumentClass, es			>

EC <	mov	di, offset NTakerDocumentClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	ILLEGAL_OBJECT_PASSED_TO_NTAKER_DOC_ROUTINE	>
EC <	pop	es							>

	mov	di, ds:[si]
	add	di, ds:[di].GenDocument_offset
	ret
NTakerDocPrintDeref_DSDI	endp

;---

NTakerDocPrintGetFileHandle	proc	near	uses di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocPrintDeref_DSDI
	mov	bx, ds:[di].GDI_fileHandle
	.leave
	ret
NTakerDocPrintGetFileHandle	endp

;---

NTakerDocPrintGetCurFolder	proc	near
	class	NTakerDocumentClass
	.enter
	call	NTakerDocPrintDeref_DSDI
	mov	ax, ds:[di].NDOCI_curFolder.high
	mov	di, ds:[di].NDOCI_curFolder.low
	tstdw	axdi
	.leave
	ret
NTakerDocPrintGetCurFolder	endp

;---

NTakerDocPrintGetCurNote	proc	near
	class	NTakerDocumentClass
	.enter
	call	NTakerDocPrintDeref_DSDI
	movdw	axdi, ds:[di].NDOCI_curNote
	tstdw	axdi
	.leave
	ret
NTakerDocPrintGetCurNote	endp

;---

NTakerDocPrintGetCurPage	proc	near	uses di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocPrintDeref_DSDI
	mov	cx, ds:[di].NDOCI_curPage
	.leave
	ret
NTakerDocPrintGetCurPage	endp

;---

DocumentPrintCode	ends	;end of DocumentPrintCode resource
