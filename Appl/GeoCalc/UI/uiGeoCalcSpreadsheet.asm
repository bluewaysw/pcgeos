COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		uiSpreadsheet.asm

AUTHOR:		Gene Anderson, Mar 21, 1991

ROUTINES:
	Name			Description
	----			-----------
	MSG_SPREADSHEET_MAKE_FOCUS

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/21/91		Initial revision

DESCRIPTION:
	Methods for sub-class Spreadsheet object (for focus & target)

	$Id: uiGeoCalcSpreadsheet.asm,v 1.1 97/04/04 15:48:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcClassStructures	segment	resource
	GeoCalcSpreadsheetClass			;declare the class record
GeoCalcClassStructures	ends
;
; These are the definitions of the page/pages variables.
;
idata	segment
currentPage	word	0				; Current starting page
totalPageCount	word	DEFAULT_TOTAL_PAGE_COUNT	; Total page count
idata	ends




if _SPLIT_VIEWS
Document segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetIsActiveCellVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the active cell is on visible.

CALLED BY:	MSG_GEOCALC_SPREADSHEET_IS_ACTIVE_CELL_VISIBLE
PASS:		*ds:si	= GeoCalcSpreadsheetClass object
		ds:di	= GeoCalcSpreadsheetClass instance data
		es 	= segment of GeoCalcSpreadsheetClass
		ax	= message #
RETURN:		carry set if the active is visible; otherwise, carry clear.
DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetIsActiveCellVisible	method dynamic GeoCalcSpreadsheetClass,
				MSG_GEOCALC_SPREADSHEET_IS_ACTIVE_CELL_VISIBLE
		uses	cx
		.enter
		mov	ax, ds:[di].SSI_active.CR_row
		mov	cx, ds:[di].SSI_active.CR_column
		cmp	ax, ds:[di].SSI_visible.CR_start.CR_row
		jb	notVisible
		cmp	ax, ds:[di].SSI_visible.CR_end.CR_row
		ja	notVisible
		cmp	cx, ds:[di].SSI_visible.CR_start.CR_column
		jb	notVisible
		cmp	cx, ds:[di].SSI_visible.CR_end.CR_column
		ja	notVisible
		stc				;<- indicate visible
done:
		.leave
		ret
notVisible:
		clc				;<- indicate not visible
		jmp	done

GeoCalcSpreadsheetIsActiveCellVisible		endm
Document ends
endif


UITrans	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetMakeFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give the Spreadsheet the focus & target
CALLED BY:	MSG_SPREADSHEET_MAKE_FOCUS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcSpreadsheetMakeFocus	method dynamic GeoCalcSpreadsheetClass, \
						MSG_SPREADSHEET_MAKE_FOCUS

	mov	di, offset GeoCalcSpreadsheetClass
	call	ObjCallSuperNoLock

	;
	; Give the focus to the display area, so that when the display
	; group goes to grab it, the edit bar has already released it
	;

	mov	ax, MSG_GEN_MAKE_FOCUS
	GetResourceHandleNS GCDisplayArea, bx
	mov	si, offset GCDisplayArea	;^lbx:si <- OD of display ctrl
	call	callObjMessage

	;
	; Give the focus back to the target spreadsheet
	; by giving the focus back to the top of it's
	; local tree -- the DisplayGroup
	;
	GetResourceHandleNS GCDisplayGroup, bx
	mov	si, offset GCDisplayGroup
	mov	ax, MSG_GEN_MAKE_FOCUS
	call	callObjMessage

	mov	ax, MSG_GEN_MAKE_TARGET
	call	callObjMessage

	;
	; Tell the app obj we've got the target now
	;
	mov	cl, GCTL_SPREADSHEET
	mov	ax, MSG_GEOCALC_APPLICATION_SET_TARGET_LAYER
	call	UserCallApplication
	;
	; Make sure the current tool is the pointer
	;
if _CHARTS
	GetResourceHandleNS GCGrObjHead, bx
	mov	si, offset GCGrObjHead
	mov	cx, segment PointerClass
	mov	dx, offset PointerClass		;cx:dx <- ptr to class
	clr	bp				;bp <- initialization data
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	call	callObjMessage
endif		
	ret


callObjMessage:
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	retn
GeoCalcSpreadsheetMakeFocus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report an error to the user.
CALLED BY:	MSG_SPREADSHEET_ERROR

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the method
		dl - ParserScannerEvaluatorError
RETURN:		none
DESTROYED:	everything (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBCS< ERROR_BUFFER_SIZE	= 256					>
DBCS< ERROR_BUFFER_SIZE	= 256*(size wchar)			>

GeoCalcSpreadsheetError	method dynamic GeoCalcSpreadsheetClass, \
			MSG_SPREADSHEET_ERROR

	mov	al, dl			;al <- ParserScannerEvaluatorError

	sub	sp, ERROR_BUFFER_SIZE
	movdw	cxdx, sssp		;cx:dx <- buffer for error message

	call	GrabParserError		; Get the error message

	mov	bx, ds:[si]
	add	bx, ds:[bx].Spreadsheet_offset
	mov	bx, ds:[bx].SSI_cellParams.CFP_file

	mov	si, offset GenericMessage
	call	DocumentMessage

	add	sp, ERROR_BUFFER_SIZE

	ret
GeoCalcSpreadsheetError	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetHandleSpecialFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle one of the many special functions.

CALLED BY:	via MSG_SPREADSHEET_HANDLE_SPECIAL_FUNCTION
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		ax	= Method
		es	= Class segment
		cx	= Special function
			SF_FILENAME:
				ss:dx	= Pointer to buffer to fill.
RETURN:		SF_FILENAME:
			cx	= Length of the filename not counting the NULL
		SF_PAGE:
			cx	= Current page number
		SF_PAGES:
			cx	= Total number of pages
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetHandleSpecialFunction	method	GeoCalcSpreadsheetClass,
			MSG_SPREADSHEET_HANDLE_SPECIAL_FUNCTION
	mov	si, cx
	call	cs:specialFunctionHandlers[si]
	ret
GeoCalcSpreadsheetHandleSpecialFunction	endm

specialFunctionHandlers	nptr	offset cs:FilenameHandler,
				offset cs:PageHandler,
				offset cs:PagesHandler


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilenameHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the filename special function

CALLED BY:	GeoCalcSpreadsheetHandleSpecialFunction via
		specialFunctionHandlers
PASS:		ss:dx	= Pointer to the buffer to fill
		ds:di	= Instance ptr
RETURN:		cx	= Length of the file name (w/out NULL)
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine isn't called often, so DBCS uses library
		routine to find filename length.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version
	witt	11/11/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilenameHandler	proc	near
	class	GeoCalcSpreadsheetClass
	push	dx			; Save pointer to buffer
	
	;
	; First get the document object given the file handle.
	;
	mov	cx, ds:[di].SSI_cellParams.CFP_file

	GetResourceHandleNS	GCDocumentGroup, bx
	mov	si, offset GCDocumentGroup
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ^lcx:dx <- Document object

	mov	bx, cx			; ^lbx:si <- Document object
	mov	si, dx
	
	pop	dx			; Restore pointer to the buffer
	mov	cx, ss			; cx:dx <- ptr to the buffer
	
	;
	; Now get the longname from the document object. (Has NULL terminator)
	;
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; cx, dx, bp unchanged
	
	;
	; Now find the end of the filename.
	;	cx:dx = buffer
	;
if DBCS_PCGEOS
	movdw	esdi, cxdx
	call	LocalStringLength	; cx <- length w/out C_NULL
else
	clr	al			; Byte to find
	mov	es, cx			; es:di <- ptr to the buffer
	mov	di, dx
	
	mov	cx, -1			; Scan forever
	repne	scasb			; es:di <- ptr after the NULL
	sub	di, dx			; di <- length w/ NULL
	dec	di			; di <- length w/o NULL
	
	mov	cx, di			; Return length in cx
endif
	ret
FilenameHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the page special function

CALLED BY:	GeoCalcSpreadsheetHandleSpecialFunction via
		specialFunctionHandlers
PASS:		ds:di	= Instance ptr
RETURN:		cx	= Current page
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PageHandler	proc	near
	GetResourceSegmentNS	dgroup, ds
	mov	cx, ds:currentPage
	ret
PageHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PagesHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the pages special function

CALLED BY:	GeoCalcSpreadsheetHandleSpecialFunction via
		specialFunctionHandlers
PASS:		ds:di	= Instance ptr
RETURN:		cx	= Total number of pages
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PagesHandler	proc	near
	GetResourceSegmentNS	dgroup, ds
	mov	cx, ds:totalPageCount
	ret
PagesHandler	endp

if _CELL_NOTE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetDisplayNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force Note DB to be visible

CALLED BY:	MSG_SPREADSHEET_DISPLAY_NOTE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the message

		dl - SpreadsheetDoubleClickFlags
		dh - CellType (if cell exists)

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/10/92		Initial version
	CL	7/ 9/95		Added Jedi version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetDisplayNote		method dynamic GeoCalcSpreadsheetClass,
						MSG_SPREADSHEET_DISPLAY_NOTE
	test	dl, mask SDCF_NOTE_EXISTS
	jz	noNotes

	;
	; If cell has notes, bring the DB onscreen
	;
	GetResourceHandleNS	GCNoteControl, bx
	mov	si, offset GCNoteControl
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
noNotes:
	ret
GeoCalcSpreadsheetDisplayNote		endm
endif

if _CHARTS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetChartRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Chart a range of data

CALLED BY:	MSG_SPREADSHEET_CHART_RANGE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the message

		cl - ChartType
		ch - ChartVariation

RETURN:		none
DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetChartRange		method dynamic GeoCalcSpreadsheetClass,
						MSG_SPREADSHEET_CHART_RANGE
	;
	; Let our superclass (try to) create the chart
	;
	mov	di, offset GeoCalcSpreadsheetClass
	call	ObjCallSuperNoLock
	;
	; If we were successful, change the target layer to the grobj
	;
	cmp	al, CRT_OK			;chart created OK?
	jne	error

	mov	ax, MSG_GEOCALC_DOCUMENT_SET_TARGET
	mov	cl, GCTL_GROBJ			;cl <- GeoCalcTargetLayer
	call	VisCallParent
done:
	ret

error:
	call	GetFile				;bx <- file handle
	;
	; Tell the user of the sad state of affairs
	;
	cmp	al, CRT_OTHER_ERROR
	je	isSpreadsheetChartError

	clr	ah
	mov_tr	di, ax
	mov	si, cs:[chartErrorMessages][di]
messageCommon:
	clr	cx, dx
	call	DocumentMessage
	jmp	done

isSpreadsheetChartError:
	mov	al, ah			;al <- SpreadsheetChartReturnType
	clr	ah
	mov_tr	di, ax
	mov	si, cs:[spreadsheetChartErrorMessages][di]
	jmp	messageCommon

GeoCalcSpreadsheetChartRange		endm

chartErrorMessages	lptr	\
	0,
	noSeriesString,
	need2SeriesString,
	noCategoryString,
	tooManySeriesString,
	tooManyCategoriesString,
	0
CheckHack <(size chartErrorMessages) eq ChartReturnType>

spreadsheetChartErrorMessages	lptr \
	tooManyCharts,
	notEnoughMemoryToChart,
	noDataToChart
CheckHack <(size spreadsheetChartErrorMessages) eq SpreadsheetChartReturnType>

endif

GetFile	proc	near
	class	GeoCalcSpreadsheetClass
	mov	bx, ds:[si]
	add	bx, ds:[bx].Spreadsheet_offset
	mov	bx, ds:[bx].SSI_cellParams.CFP_file
	ret
GetFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetFillSeries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle Fill Series

CALLED BY:	MSG_SPREADSHEET_FILL_SERIES
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetFillSeries		method dynamic GeoCalcSpreadsheetClass,
						MSG_SPREADSHEET_FILL_SERIES
	mov	di, offset GeoCalcSpreadsheetClass
	call	ObjCallSuperNoLock
	;
	; An error occurred -- report an appropriate message
	;
	call	GetFile
	clr	ah
	mov	si, ax				;si <- index of error
	mov	si, cs:fillErrorMessages[si]	;si <- chunk of error
	tst	si
	jz	done
	call	DocumentMessage
done:
	ret

fillErrorMessages lptr \
	0,
	notDateNumberString,
	stepTooLargeString
GeoCalcSpreadsheetFillSeries		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetInsertSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_SPREADSHEET_INSERT_SPACE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the message
		cx - SpreadsheetInsertFlags
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetInsertSpace		method dynamic GeoCalcSpreadsheetClass,
						MSG_SPREADSHEET_INSERT_SPACE
	;
	; See if we can insert / delete OK
	;
	mov	ax, MSG_SPREADSHEET_CHECK_INSERT_SPACE
	mov	di, offset GeoCalcSpreadsheetClass
	call	ObjCallSuperNoLock
	cmp	al, SISE_TOO_MANY_ROWS
	je	returnError
	cmp	al, SISE_TOO_MANY_COLUMNS
	je	returnError
	;
	; No error (at least that we're concerned with) insert/delete away...
	;
	mov	ax, MSG_SPREADSHEET_INSERT_SPACE
	mov	di, offset GeoCalcSpreadsheetClass
	call	ObjCallSuperNoLock
done::
	ret


	;
	; An error occurred -- report an appropriate message
	;
returnError:
	call	GetFile
	mov	si, offset tooManyRowsColumnsForInsertString
	call	DocumentMessage
	ret
GeoCalcSpreadsheetInsertSpace		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetReplaceTextSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass replace text selection on to the GCEditBarControl.

CALLED BY:	MSG_SPREADSHEET_REPLACE_TEXT_SELECTION
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the message
		cx - length of text (0 for NULL-terminated)
		^hdx - handle of text
		bp.low - offset to new cursor position
			When the text is replaced, the cursor will be
		     positioned at the end of the new text, so the
		     offset will have to be 0 or less.
			A value > 0 means to select the new text.
		bp.high - UIFunctionsActive:
			UIFA_EXTEND - extend modifier down
			UIFA_ADJUST - adjust modifier down


RETURN:		handle freed
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetReplaceTextSelection	method dynamic GeoCalcSpreadsheetClass,
					MSG_SPREADSHEET_REPLACE_TEXT_SELECTION
	
	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl	;^lbx:si <- OD of display ctrl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

GeoCalcSpreadsheetReplaceTextSelection		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetCompleteRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- GeoCalcSpreadsheetClass object
		ds:di	- GeoCalcSpreadsheetClass instance data
		es	- segment of GeoCalcSpreadsheetClass

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/15/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _SPLIT_VIEWS

GeoCalcSpreadsheetCompleteRedraw method	dynamic	GeoCalcSpreadsheetClass, 
					MSG_SPREADSHEET_COMPLETE_REDRAW
		.enter

		mov	di, offset GeoCalcSpreadsheetClass
		call	ObjCallSuperNoLock

		mov	ax, MSG_GEOCALC_DOCUMENT_GET_FLAGS
		call	VisCallParent

		test	cl, mask GCDF_SPLIT
		jz	done

	;
	; Tell all the other contents to redraw too.
	;
		mov	si, offset MidLeftContent
		call	sendInvalMsg
		
		mov	si, offset MidRightContent
		call	sendInvalMsg

		mov	si, offset BottomLeftContent
		call	sendInvalMsg
done:
		.leave
		ret
sendInvalMsg:
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
		retn
GeoCalcSpreadsheetCompleteRedraw	endm

endif


UITrans	ends

UICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMouseCellRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a mouse event should do a cell reference

CALLED BY:	GeoCalcSpreadsheetStartSelect(), etc.
PASS:		*ds:si - GeoCalcSpreadsheet object
RETURN:		carry - set to do cell reference
DESTROYED:	di

PSEUDO CODE/STRATEGY:
	NOTE: this is one of the parts of this operation that crosses
	threads (from the document object (app thread) to the edit
	bar (ui thread)) -- be warned.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckMouseCellRef		proc	near
	class	GeoCalcSpreadsheetClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].GeoCalcSpreadsheet_offset
	;
	; If we have the focus, the edit bar doesn't, so don't do a ref
	;
	test	ds:[di].SSI_flags, mask SF_IS_SYS_FOCUS
	jnz	callSuper			;branch (carry clear)
	;
	; See if the document has the focus.  If so, the edit bar doesn't
	; so don't do a ref
	;
	push	ax, cx, di, si
	mov	ax, MSG_SSEBC_GET_FLAGS
	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl	;^lbx:si <- OD of display ctrl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	test	cl, mask SSEBCF_IS_FOCUS	;is edit bar focus?
	pop	ax, cx, di, si
	jz	callSuper			;branch if not focus (carry clr)
	stc					;carry <- do reference
callSuper:

	.leave
	ret
CheckMouseCellRef		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse click

CALLED BY:	MSG_META_LARGE_START_SELECT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the message

		ss:bp - LargeMouseData

RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetStartSelect		method dynamic GeoCalcSpreadsheetClass,
						MSG_META_LARGE_START_SELECT
	call	CheckMouseCellRef
	jnc	callSuper			;branch if not doing ref
	;
	; We don't have the focus -- do the cell reference thang
	;
	call	AddMouseCellRef
	call	VisGrabLargeMouse
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	ret

callSuper:
	mov	di, offset GeoCalcSpreadsheetClass
	GOTO	ObjCallSuperNoLock
GeoCalcSpreadsheetStartSelect		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse moving

CALLED BY:	MSG_META_LARGE_PTR
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the message

		ss:bp - LargeMouseData

RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetPtr		method dynamic GeoCalcSpreadsheetClass,
						MSG_META_LARGE_PTR
	call	CheckMouseCellRef
	jnc	callSuper			;branch if not doing ref
	;
	; We don't have the focus -- do the cell reference thang
	;
	mov	ax, TEMP_GC_MOUSE_CELL_REF
	call	ObjVarFindData
	jnc	noCell				;branch if not doing it...
	mov	ax, 1				;ax <- select text, please
	call	AddMouseRangeRef
noCell:
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	ret

callSuper:
	mov	di, offset GeoCalcSpreadsheetClass
	GOTO	ObjCallSuperNoLock
GeoCalcSpreadsheetPtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse release

CALLED BY:	MSG_META_LARGE_END_SELECT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the message

		ss:bp - LargeMouseData

RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetEndSelect		method dynamic GeoCalcSpreadsheetClass,
						MSG_META_LARGE_END_SELECT
	call	CheckMouseCellRef
	jnc	callSuper			;branch if not doing ref
	;
	; Set the text one last time
	;
	clr	ax				;ax <- don't select text
	call	AddMouseRangeRef
	;
	; Clean up after ourselves
	;
	mov	ax, TEMP_GC_MOUSE_CELL_REF
	call	ObjVarDeleteData
	jc	noCellRef			;branch if no such data
	call	VisReleaseMouse
noCellRef:
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	ret

callSuper:
	mov	di, offset GeoCalcSpreadsheetClass
	GOTO	ObjCallSuperNoLock
GeoCalcSpreadsheetEndSelect		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetNotifiedWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We sub-class this message merely to pass it on to the
		GeoCalcSSEditBarControl object which then passes it on to 
		an EBCEditBar object (a sub-class of GenText).  This
		message is sent to us by a PenInputController.

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK
PASS:		*ds:si	= GeoCalcSpreadsheetClass object
		ds:di	= GeoCalcSpreadsheetClass instance data
		ds:bx	= GeoCalcSpreadsheetClass object (same as *ds:si)
		es 	= segment of GeoCalcSpreadsheetClass
		ax	= message #
		cx:dx	= NotificationType
			cx - NT_manuf
			dx - NT_type
		^hbp	= SHARABLE data block having a "reference count" 
		       	  initialized via MemInitRefCount.

RETURN:		nothing

DESTROYED:	bx, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetNotifiedWithDataBlock	method dynamic GeoCalcSpreadsheetClass,
					MSG_META_NOTIFY_WITH_DATA_BLOCK

	;
	; We only want to pass this message on to our text object if it is
	; sent with the notification type, GWNT_TEXT_REPLACE_WITH_HWR.
	; Any other notification types should be passed on to our superclass.
	;
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_TEXT_REPLACE_WITH_HWR
	jne	callSuper

	;
	; cx, dx, bp are left intact...so all we have to do is load the OD
	; of the edit bar controller and resend the message.
	;
	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

callSuper:
	mov	di, offset GeoCalcSpreadsheetClass
	GOTO	ObjCallSuperNoLock

GeoCalcSpreadsheetNotifiedWithDataBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetContextNotif
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We sub-class this message merely to pass it on to the
		GeoCalcSSEditBarControl object which then passes it on to 
		an EBCEditBar object (a sub-class of GenText).  This
		message is sent to us by a PenInputController.

CALLED BY:	MSG_META_GENERATE_CONTEXT_NOTIFICATION
PASS:		*ds:si	= GeoCalcSpreadsheetClass object
		ds:di	= GeoCalcSpreadsheetClass instance data
		ds:bx	= GeoCalcSpreadsheetClass object (same as *ds:si)
		es 	= segment of GeoCalcSpreadsheetClass
		ax	= message #
		ss:bp	= GetContextParams (GCP_replyObj ignored)

RETURN:		nothing

DESTROYED:	bx, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	6/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetContextNotif	method dynamic GeoCalcSpreadsheetClass, 
					MSG_META_GENERATE_CONTEXT_NOTIFICATION

	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	GOTO	ObjMessage
GeoCalcSpreadsheetContextNotif	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We sub-class this message because whenever we gain the
		focus we need to send a MSG_META_GENERATE_CONTEXT_NOTIFICATION
		to the GeoCalcSSEditBarControl object which will then pass
		it on to an EBCEditBar object (a sub-class of GenText).

CALLED BY:	MSG_META_GAINED_FOCUS_EXCL
PASS:		*ds:si	= GeoCalcSpreadsheetClass object
		ds:di	= GeoCalcSpreadsheetClass instance data
		ds:bx	= GeoCalcSpreadsheetClass object (same as *ds:si)
		es 	= segment of GeoCalcSpreadsheetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	6/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAX_CONTEXT_CHARS	equ	500	; this constant pulled from
					; /s/p/Library/User/UI/uiPIClass.def
					; Huan 6/9/93

GeoCalcSpreadsheetGainedFocusExcl	method dynamic GeoCalcSpreadsheetClass,
					MSG_META_GAINED_FOCUS_EXCL

	;
	; Call our superclass so that a GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	; notification is sent out.
	;
	mov	di, offset GeoCalcSpreadsheetClass
	call	ObjCallSuperNoLock


	call	UserCheckIfContextUpdateDesired
	tst	ax
	jz	exit

	sub	sp, size GetContextParams
	mov	bp, sp
	mov	ss:[bp].GCP_numCharsToGet, MAX_CONTEXT_CHARS
	mov	ss:[bp].GCP_location, CL_CENTERED_AROUND_SELECTION_START
	movdw	ss:[bp].GCP_position, dxax
	mov	dx, size GetContextParams
	mov	ax, MSG_META_GENERATE_CONTEXT_NOTIFICATION
	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GetContextParams

exit:
	ret
GeoCalcSpreadsheetGainedFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetDeleteRangeOfChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We sub-class this message merely to pass it on to the
		GeoCalcSSEditBarControl object which then passes it on to 
		an EBCEditBar object (a sub-class of GenText).  This
		message is sent to us by a PenInputController.

CALLED BY:	MSG_META_DELETE_RANGE_OF_CHARS
PASS:		*ds:si	= GeoCalcSpreadsheetClass object
		ds:di	= GeoCalcSpreadsheetClass instance data
		ds:bx	= GeoCalcSpreadsheetClass object (same as *ds:si)
		es 	= segment of GeoCalcSpreadsheetClass
		ax	= message #
		ss:bp	= VisTextRange (range of chars to delete)

RETURN:		nothing

DESTROYED:	bx, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetDeleteRangeOfChars	method dynamic GeoCalcSpreadsheetClass,
					MSG_META_DELETE_RANGE_OF_CHARS

	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	GOTO	ObjMessage
GeoCalcSpreadsheetDeleteRangeOfChars	endm

UICode	ends

MouseEditBar	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcMouseCellRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a cell reference from a mouse position

CALLED BY:	GeoCalcSpreadsheetStartSelect()
PASS:		*ds:si - spreadsheet object
		ss:bp - ptr to LargeMouseData
RETURN:		(dx,cx) - (r,c) of cell reference
		carry - clear if same as previous
		ds - fixed up
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcMouseCellRef		proc	near
	uses	ax, di
	.enter

	;
	; Calculate the cell under the mouse
	;
	push	bp
	movdw	dxcx, ss:[bp].LMD_location.PDF_x.DWF_int
	mov	ax, MSG_SPREADSHEET_GET_COLUMN_AT_POSITION
	call	ObjCallInstanceNoLock
	pop	bp
	push	ax				;save column #
	push	bp
	movdw	dxcx, ss:[bp].LMD_location.PDF_y.DWF_int
	mov	ax, MSG_SPREADSHEET_GET_ROW_AT_POSITION
	call	ObjCallInstanceNoLock
	pop	bp
	mov	dx, ax				;dx <- row #
	pop	cx				;cx <- column #
	;
	; See if this is the same cell as before
	;
	mov	ax, TEMP_GC_MOUSE_CELL_REF
	call	ObjVarFindData
	jnc	differentRef			;branch if no previous
	cmp	ds:[bx].CR_start.CR_row, dx
	jne	differentRef
	cmp	ds:[bx].CR_start.CR_column, cx
	clc					;carry <- same reference
	je	done				;branch if same cell reference
differentRef:
	stc					;carry <- different reference
done:
	.leave
	ret
CalcMouseCellRef		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddMouseCellRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a cell reference to the edit bar

CALLED BY:	GeoCalcSpreadsheetStartSelect()
PASS:		*ds:si - spreadsheet object
		ss:bp - ptr to LargeMouseData
RETURN:		ds - fixed up
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddMouseCellRef		proc	far
	uses	bp
	.enter

	;
	; Figure out the cell the mouse is over
	;
	call	CalcMouseCellRef		;(dx,cx) <- CellReference
	jnc	noRef				;branch if same reference
	;
	; Save the cell reference in case the user drags over a range,
	; and also let us know if it changes so we can update the edit bar
	;
	push	cx
	mov	ax, TEMP_GC_MOUSE_CELL_REF
	mov	cx, (size CellRange)		;cx <- size of data
	call	ObjVarAddData
	pop	cx
	mov	ds:[bx].CR_start.CR_row, dx
	mov	ds:[bx].CR_start.CR_column, cx
	mov	ds:[bx].CR_end.CR_row, -1
	;
	; Format the cell reference
	;
	call	AllocCellText
	jc	noRef				;branch if error
	clr	di				;es:di <- ptr to buffer
	mov	ax, dx				;(ax,cx) <- (r,c) of cell
	call	ParserFormatCellReference
	call	MemUnlock
	;
	; Set the text!
	;
	mov	al, 1				;al <- select text, please
	call	SetCellText
noRef:

	.leave
	ret
AddMouseCellRef		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddMouseRangeRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a range reference to the edit bar

CALLED BY:	GeoCalcSpreadsheetPtr()
PASS:		*ds:si - spreadsheet object
		ss:bp - ptr to LargeMouseData
		al - >0 to select text, 0 to not select text;
RETURN:		ds - fixed up
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddMouseRangeRef		proc	far
	uses	bp, si
	.enter

	;
	; Figure out the cell the mouse is over
	;
	call	CalcMouseCellRef		;(dx,cx) <- CellReference
	;
	; Format the cell reference
	;
	call	AllocCellText
	LONG jc	noRef				;branch if error
	push	bx				;save text block
	push	ax				;save selection flag
	;
	; Use the start cell as the start of the range
	;
	mov	ax, TEMP_GC_MOUSE_CELL_REF
	call	ObjVarFindData
EC <	ERROR_NC -1				;>
	pop	si				;si.low <- selection flag
	mov	di, bx
	mov	ax, ds:[di].CR_start.CR_row
	mov	bx, ds:[di].CR_start.CR_column
	xchg	ax, dx				;(ax,cx),(dx,bx) <- range
	cmp	ax, dx				;range?
	jne	doRange
	cmp	cx, bx				;range?
	jne	doRange
	;
	; The start cell and end cell are the same -- format as a cell
	; unless we're over the same cell
	;
doCell:
	cmp	ds:[di].CR_end.CR_row, -1
	jne	formatCell			;branch if previously range
	cmp	ax, ds:[di].CR_start.CR_row
	jne	formatCell
	cmp	cx, ds:[di].CR_start.CR_column
	jne	formatCell
	;
	; The cells are the same.  Bail early, unless we're not selecting
	; the text (meaning we're on an end select), so the text becomes
	; not selected, so the next reference click does something useful.
	;
	test	si, 0x00ff			;selecting text?
	jnz	noRefExit			;branch if selecting text
formatCell:
	mov	ds:[di].CR_start.CR_row, ax
	mov	ds:[di].CR_start.CR_column, cx
	mov	ds:[di].CR_end.CR_row, -1
	clr	di				;es:di <- ptr to buffer
	call	ParserFormatCellReference
	jmp	gotText

	;
	; Format the range, unless the range remains the same...
	;
doRange:
	;
	; See if <Shift> is down -- if so, force this to become the
	; end cell in a range.
	;
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_EXTEND
	jnz	doCell				;branch if <Shift> down
	cmp	ds:[di].CR_end.CR_row, -1
	je	formatRange			;branch if previously cell
	cmp	dx, ds:[di].CR_start.CR_row
	jne	formatRange
	cmp	bx, ds:[di].CR_start.CR_column
	jne	formatRange
	cmp	ax, ds:[di].CR_end.CR_row
	jne	formatRange
	cmp	cx, ds:[di].CR_end.CR_column
	jne	formatRange
	;
	; The cells are the same.  Bail early, unless we're not selecting
	; the text (meaning we're on an end select), so the text becomes
	; not selected, so the next reference click does something useful.
	;
	test	si, 0x00ff			;selecting text?
	jnz	noRefExit			;branch if selecting text
formatRange:
	mov	ds:[di].CR_start.CR_row, dx
	mov	ds:[di].CR_start.CR_column, bx
	mov	ds:[di].CR_end.CR_row, ax
	mov	ds:[di].CR_end.CR_column, cx
	;
	; Make sure the range is sorted.  NOTE: we do this last
	; (ie. after saving the new range) so that the first
	; cell clicked on stays the same, behaving as the anchor.
	;
	cmp	ax, dx				;rows unordered?
	jbe	rowOK
	xchg	ax, dx
rowOK:
	cmp	cx, bx				;columns unordered?
	jbe	columnOK
	xchg	cx, bx
columnOK:
	clr	di				;es:di <- ptr to buffer
	call	ParserFormatRangeReference
gotText:
	mov	ax, si				;al <- selection flag
	pop	bx				;bx <- handle of text
	call	MemUnlock
	;
	; Set the text!
	;
	call	SetCellText
noRef:
	.leave
	ret

	;
	; Bail out early -- the text hasn't changed
	;
noRefExit:
	pop	bx
	call	MemFree
	jmp	noRef
AddMouseRangeRef		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocCellText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block for pasting a cell reference

CALLED BY:	AddMouseCellRef()
PASS:		none
RETURN:		^hbx - handle of text block
		es - seg addr of text block
		carry - set if error
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocCellText		proc	near
	uses	ax, cx
	.enter

	mov	ax, MAX_RANGE_REF_SIZE		;ax <- size
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc
	jc	allocError			;branch if error
	mov	es, ax				;es <- seg addr of text
allocError:

	.leave
	ret
AllocCellText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCellText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set text for cell or range reference

CALLED BY:	AddMouseCellRef(), AddMouseRangeRef()
PASS:		al - >0 to select text, 0 to not select text
		^hbx - handle of text
		cx - length of text
		ds - fixupable segment
		ss:bp - ptr to LargeMouseData
RETURN:		ds - fixed up
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
	NOTE: this is one of the parts of this operation that crosses
	threads (from the document object (app thread) to the edit
	bar (ui thread)) -- be warned.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCellText		proc	near
	uses	si
	.enter

	mov	ah, ss:[bp].LMD_uiFunctionsActive
	mov	dx, bx				;dx <- text block
	mov	bp, ax				;bp <- select new text
	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl
	mov	ax, MSG_SPREADSHEET_REPLACE_TEXT_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
SetCellText		endp

MouseEditBar	ends



UITrans	segment resource


if _SPLIT_VIEWS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetSetOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEOCALC_SPREADSHEET_SET_OFFSET
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the message
		ss:bp - PointDWord, new origin
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/13/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetSetOffset		method dynamic GeoCalcSpreadsheetClass,
					MSG_GEOCALC_SPREADSHEET_SET_OFFSET

		movdw	dxcx, ss:[bp].PD_x
		decdw	dxcx			; account for strangeness
		movdw	ds:[di].SSI_offset.PD_x, dxcx

		push	bp
		mov	ax, MSG_SPREADSHEET_GET_COLUMN_AT_POSITION
		call	ObjCallInstanceNoLock
		mov	ds:[di].SSI_visible.CR_start.CR_column, ax
		pop	bp
		
		movdw	dxcx, ss:[bp].PD_y
		decdw	dxcx			; account for strangeness
		movdw	ds:[di].SSI_offset.PD_y, dxcx

		mov	ax, MSG_SPREADSHEET_GET_ROW_AT_POSITION
		call	ObjCallInstanceNoLock
		mov	ds:[di].SSI_visible.CR_start.CR_row, ax

		ret
GeoCalcSpreadsheetSetOffset		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetLockedCellRecalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A locked cell has been recalc'ed.  Redraw it.

CALLED BY:	MSG_SPREADSHEET_LOCKED_CELL_RECALC
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSpreadsheetClass
		ax - the message
		dx, cx - the cell
RETURN:		dx, cx
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetLockedCellRecalc	method dynamic GeoCalcSpreadsheetClass,
					MSG_SPREADSHEET_LOCKED_CELL_RECALC
	;
	; Make sure we are in split mode...
	;
		push	dx, cx
		mov	ax, MSG_GEOCALC_DOCUMENT_GET_FLAGS
		call	VisCallParent
		test	cl, mask GCDF_SPLIT
		pop	dx, cx

EC <		ERROR_Z SPLIT_VIEW_LOGIC_ERROR				>
NEC <		jz	done						>
	;
	; Get the locked range
	;
		mov	ax, TEMP_SPREADSHEET_DOC_ORIGIN
		call	ObjVarFindData
EC <		ERROR_NC SPLIT_VIEW_LOGIC_ERROR				>
	;
	; Is the cell before or after the origin row?
	;
		cmp	dx, ds:[bx].SDO_rowCol.CR_row
		jae	afterOriginRow

	;
	; It's before the origin row, so is in either the MidLeft or
	; MidRight content.  If it is before the origin column, it is
	; in the MidLeftContent, else it is after the origin column and
	; therefore in the MidRightContent.
	;
		cmp	cx, ds:[bx].SDO_rowCol.CR_column
		mov	si, offset MidLeftContent
		jb	sendInvalMsg

		mov	si, offset MidRightContent
		jmp	sendInvalMsg

afterOriginRow:		
	;
	; The cell is after the origin row, and since it is locked,
	; it must be before the origin column, and hence in the
	; BottomLeftContent.  The EC code is here just to make sure...
	;
EC <		cmp	cx, ds:[bx].SDO_rowCol.CR_column		>
EC <		ERROR_A SPLIT_VIEW_LOGIC_ERROR				>
		mov	si, offset BottomLeftContent

sendInvalMsg:
		mov	ax, MSG_VIS_INVALIDATE
		GOTO	ObjCallInstanceNoLock

NEC < done:								>
NEC < 		ret							>
GeoCalcSpreadsheetLockedCellRecalc		endm

endif


if _PROTECT_CELL
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcSpreadsheetGetActiveCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the position of the active cell.

CALLED BY:	MSG_GEOCALC_SPREADSHEET_GET_ACTIVE_CELL
PASS:		*ds:si	= GeoCalcSpreadsheetClass object
		ds:di	= GeoCalcSpreadsheetClass instance data
		es 	= segment of GeoCalcSpreadsheetClass
		ax	= message #
RETURN:		(ax,cx)	= (r, c) of the active cell.
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcSpreadsheetGetActiveCell	method dynamic GeoCalcSpreadsheetClass, 
					MSG_GEOCALC_SPREADSHEET_GET_ACTIVE_CELL
		.enter
		mov	ax, ds:[di].SSI_active.CR_row
		mov	cx, ds:[di].SSI_active.CR_column
		.leave
		ret
GeoCalcSpreadsheetGetActiveCell		endm
endif	

UITrans	ends

