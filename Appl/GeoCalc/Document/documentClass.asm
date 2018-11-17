COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		documentClass.asm

AUTHOR:		Gene Anderson, Feb 12, 1991

ROUTINES:
	Name			Description
	----			-----------
GLB	GeoCalcDocumentClass	GeoCalc document

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/12/91		Initial revision

DESCRIPTION:
	This file contains routines to implement the GeoCalcDocument class

	$Id: documentClass.asm,v 1.1 97/04/04 15:48:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcClassStructures	segment	resource
	GeoCalcDocumentClass		;declare the class record
GeoCalcClassStructures	ends

Document	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToDocSpreadsheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a method to the associated spreadsheet object
CALLED BY:	UTILITY

PASS:		*ds:si - GeoCalcDocumentClass instance
		ax - method to send to Spreadsheet
		cx, dx, bp - data for method
		di - MessageFlags to use
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendFileToDocSpreadsheet	proc	far
	uses	dx
	class	GeoCalcDocumentClass
	.enter

	call	GetSpreadsheetFile		;
	mov	dx, bx				;dx <- file handle of ssheet

	call	SendToDocSpreadsheet
	.leave
	ret
SendFileToDocSpreadsheet	endp

SendToDocSpreadsheet	proc	far
	uses	ax, bx, cx, si
	class	GeoCalcDocumentClass
	.enter

	call	GetDocSpreadsheet		;^lbx:si <- OD of spreadsheet
	call	ObjMessage

	.leave
	ret
SendToDocSpreadsheet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDocSpreadsheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get OD of spreadsheet associated with a document

CALLED BY:	SendToDocSpreadsheet()
PASS:		*ds:si - GeoCalcDocument object
RETURN:		^lbx:si - OD of associated spreadsheet
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDocSpreadsheet		proc	far
	class	GeoCalcDocumentClass
	.enter

	Assert	objectPtr dssi GeoCalcDocumentClass
		
	mov	si, ds:[si]
	add	si, ds:[si].GeoCalcDocument_offset
	mov	bx, ds:[si].GCDI_spreadsheet	;bx <- handle of spreadsheet blk
	mov	si, offset ContentSpreadsheet	;^lbx:si <- OD of spreadsheet

	Assert	optr	bxsi

	.leave
	ret
GetDocSpreadsheet		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save file name for re-opening

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= GeoCalcDocumentClass object
		ds:di	= GeoCalcDocumentClass instance data
		ds:bx	= GeoCalcDocumentClass object (same as *ds:si)
		es 	= segment of GeoCalcDocumentClass
		ax	= message #
		cx, dx, bp = detach data
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _SAVE_TO_STATE
InitCode	segment	resource
GeoCalcDocumentDetach	method dynamic GeoCalcDocumentClass, 
					MSG_META_DETACH
	uses	ax, cx, dx, bp, es, ds, si
filePath	local	PathName
	.enter
	push	bp
	;
	; save path to .ini file
	;
	push	ds, si				; save doc obj
	push	bp				; save locals
	mov	dx, ss
	lea	bp, filePath
	mov	cx, size PathName		; in bytes!
	mov	ax, MSG_GEN_PATH_GET
	call	ObjCallInstanceNoLock		; cx = disk handle
	mov	bx, cx				; bx = disk handle
	segmov	es, ss
	lea	di, filePath			; pass fptr, will be unchanged
	mov	cx, 0				; just return size
	call	DiskSave			; cx = size
	sub	sp, cx				; make room for DiskSave
	mov	di, sp				; es:di = stack buffer
	call	DiskSave
	mov	bp, cx				; bp = save size
	mov	cx, cs
	mov	ds, cx
	mov	si, offset saveFileCategory
	mov	dx, offset saveFileDiskKey
	call	InitFileWriteData		; save disk handle
	add	sp, bp				; free stack buffer
	pop	bp				; bp = locals
	mov	dx, offset saveFilePathKey
	segmov	es, ss
	lea	di, filePath			; es:di = path
	LocalStrSize	includeNull
	lea	di, filePath
	mov	bp, cx
	mov	cx, cs
	call	InitFileWriteData
	pop	ds, si			; *ds:si = doc obj
	;
	; save filename to .ini file
	;	*ds:si = doc obj
	;
	segmov	es, ds
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	di, ds:[di].GDI_fileName	; es:di = filename
	push	di
	LocalStrSize	includeNull
	pop	di
	mov	bp, cx
	mov	cx, cs
	mov	ds, cx
	mov	si, offset saveFileCategory
	mov	dx, offset saveFileNameKey
	call	InitFileWriteData
	pop	bp
	;
	; call super for default handling
	;
	.leave
	mov	di, offset GeoCalcDocumentClass
	GOTO	ObjCallSuperNoLock
GeoCalcDocumentDetach	endm
InitCode	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentCreateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create associated UI for new spreadsheet document
CALLED BY:	MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the method
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentCreateUI	method dynamic GeoCalcDocumentClass, \
					MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT

	mov	di, offset GeoCalcDocumentClass
	call	ObjCallSuperNoLock
	;
	; clear bits for unmanaged geometry
	;
	mov	bx, Vis_offset
	call	ObjInitializePart
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].VI_attrs, not (mask VA_MANAGED)
	andnf	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID \
				       or mask VOF_GEO_UPDATE_PATH)
	;
	; Duplicate block with spreadsheet object and ruler objects.
	;
	mov	bx, handle ContentSpreadsheet
	clr	ax				; have current geode own block
	mov	cx, -1				; copy running thread from
						;	template block
	call	ObjDuplicateResource
	;
	; Save the handle of the duplicated block
	;
	mov	di, ds:[si]
	add	di, ds:[di].GeoCalcDocument_offset
	mov	ds:[di].GCDI_spreadsheet, bx	;save handle of spreadsheet blk
	ret
GeoCalcDocumentCreateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentDestroyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy UI-related blocks for document
CALLED BY:	MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentDestroyUI	method dynamic GeoCalcDocumentClass, \
					MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	push	ax
	;
	; Free the spreadsheet block
	;
	mov	ax, MSG_META_BLOCK_FREE
	mov	di, mask MF_FORCE_QUEUE
	call	SendToDocSpreadsheet
	;
	; Let our superclass do its thing (last!)
	;
	pop	ax
	mov	di, offset GeoCalcDocumentClass
	call	ObjCallSuperNoLock
	ret
GeoCalcDocumentDestroyUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentAttachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach UI for new or existing spreadsheet document
CALLED BY:	MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentAttachUI	method dynamic GeoCalcDocumentClass, \
					MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	;
	; Let our superclass do its thing
	;
	mov	di, offset GeoCalcDocumentClass
	call	ObjCallSuperNoLock
	;
	; set bits for getting mouse events
	;
	mov	bx, Vis_offset
	call	ObjInitializePart
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL \
				 or mask VCNA_WINDOW_COORDINATE_MOUSE_EVENTS
if _CHARTS		
	;
	; Tell the spreadsheet to attach internal and external UI
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		;ds:si <- gen instance data
		
	;
	; Prepare a block with necessary setup data
	;
	mov	ax, (size SpreadsheetSetupData)	;ax <- size
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK	;cl,ch <- HeapAllocFlags
	call	MemAlloc
	mov	es, ax				;es <- seg addr of block
	mov	ax, ds:[di].GDI_display

	;	
	; Stick the chart/grobj body in the setup data
	;
	push	bx, si
	call	GetGrObjBodyOD
	movdw	es:[SSD_chartBody], bxsi
	pop	bx, si
	call	MemUnlock
	mov	cx, bx				;cx <- handle of setup block
	mov	dx, ds:[di].GDI_fileHandle	;dx <- VM file handle
	mov	ax, MSG_SPREADSHEET_ATTACH_UI
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	SendToDocSpreadsheet
endif
	;
	; Add the spreadsheet as our child
	;
	mov	di, ds:[si]
	add	di, ds:[di].GeoCalcDocument_offset
	mov	cx, ds:[di].GCDI_spreadsheet
	push	cx				;save ruler handle
	mov	dx, offset ContentSpreadsheet	;^lcx:dx <- OD of child
	clr	bp				;bp <- CompChildFlags
	mov	ax, MSG_VIS_ADD_CHILD
	call	ObjCallInstanceNoLock
	;
	; Send the spreadsheet block off to the display for attaching the UI
	;
	mov	di, ds:[si]
	add	di, ds:[di].GeoCalcDocument_offset
	mov	cx, ds:[di].GCDI_spreadsheet	; handle of spreadsheet blk
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		;ds:si <- gen instance data
	mov	bx, ds:[di].GDI_display		;bx <- handle of display
	push	si
	mov	si, offset DisplayDisplay
	mov	ax, MSG_DISPLAY_ATTACH_UI
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	;
	; Add graphic body to head and to document
	;
if _CHARTS
	push	si
	call	GetGrObjBodyOD
	pop	si
	call	GeoCalcDocumentAddBodyToDocument
	;
	; Notify body that document is being opened, passing it head od
	;
	GetResourceHandleNS GCGrObjHead, cx
	mov	dx, offset GCGrObjHead		;cx:dx <- head OD
	mov	ax, MSG_GB_ATTACH_UI
	mov	di, mask MF_FIXUP_DS
	call	SendToGrObjBody
endif
	pop	cx			; cx - handle of content
					; (spreadsheet) block 

if _CHARTS
	;
	; Attach rulers to body
	;
	mov	dx, offset GCColumnRuler
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GB_ATTACH_RULER
	call	SendToGrObjBody
endif

if _SPLIT_VIEWS
	call	GeoCalcDocumentAttachSplitViews
endif
	;
	; Set the target based on the tool
	;
CHART<	mov	ax, MSG_GEOCALC_DOCUMENT_SET_TARGET_BASED_ON_TOOL	>
CHART<	GOTO	ObjCallInstanceNoLock					>
NOCHART<ret								>
GeoCalcDocumentAttachUI	endm


if _SPLIT_VIEWS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentAttachSplitViews
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach all the various views to their contents

CALLED BY:	GeoCalcDocumentAttachUI

PASS:		cx - handle of content block
		*ds:si - GeoCalcDocumentClass object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/24/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentAttachSplitViews	proc near
		uses	ax,bx,cx,dx,di,si,bp,es
		class	GeoCalcDocumentClass
		
		.enter

		mov	bx, cx			; content block

		mov	cx, ds:[LMBH_handle]
		mov	dx, si

		mov	si, offset MidLeftContent
		call	callSetMaster

		mov	si, offset MidRightContent
		call	callSetMaster

		mov	si, offset BottomLeftContent
		call	callSetMaster

		.leave
		ret

callSetMaster:
		mov	ax, MSG_GEOCALC_CONTENT_SET_MASTER
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		retn
		
GeoCalcDocumentAttachSplitViews	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentDetachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close document by sending message to body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GeoCalcDocumentClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentDetachUI	method dynamic GeoCalcDocumentClass, \
				MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	.enter

	;
	;    Have superclass do its thang
	;
	mov	di, offset GeoCalcDocumentClass	
	call	ObjCallSuperNoLock
	;
	;    Remove the spreadsheet as a child of the document and
	;    hence as part of the visual tree
	;
	mov	ax, MSG_VIS_REMOVE
	mov	dl, VUM_MANUAL			;dl <- VisUpdateMode
	mov	di, mask MF_FIXUP_DS
	call	SendToDocSpreadsheet
	;
	;    Remove body from and document
	;
if _CHARTS
	push	si
	call	GetGrObjBodyOD
	pop	si
	call	GeoCalcDocumentRemoveBodyFromDocument
endif

		
	.leave
	ret
GeoCalcDocumentDetachUI		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentReadCachedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force reading of cached data from file
CALLED BY:	MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentReadCachedData	method dynamic GeoCalcDocumentClass, \
				MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE
	mov	ax, MSG_SPREADSHEET_READ_CACHED_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	GetSpreadsheetMap		;dx <- VM handle of map
	call	SendFileToDocSpreadsheet
	;
	; In the event this is a revert, we force a redraw of the rulers
	; so things like column widths update correctly.
	;
	mov	ax, MSG_VIS_RULER_INVALIDATE_WITH_SLAVES
	call	GetDocSpreadsheet
	mov	si, offset GCColumnRuler	;^lbx:si <- OD of master ruler
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	GOTO	ObjMessage
GeoCalcDocumentReadCachedData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentWriteCachedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force writing of cached data to file
CALLED BY:	MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentWriteCachedData	method dynamic GeoCalcDocumentClass, \
				MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE
	mov	ax, MSG_SPREADSHEET_WRITE_CACHED_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	SendFileToDocSpreadsheet
	ret
GeoCalcDocumentWriteCachedData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentSaveAsCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle end of "save as": file handle changes
CALLED BY:	MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentSaveAsCompleted	method dynamic GeoCalcDocumentClass, \
					MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED
	mov	ax, MSG_SPREADSHEET_ATTACH_FILE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	GetSpreadsheetMap		;dx <- VM handle of map
	call	SendFileToDocSpreadsheet
	;
	; In the event any display formulas include =FILENAME(),
	; force a redraw so they update correctly.
	;
	mov	ax, MSG_SPREADSHEET_COMPLETE_REDRAW
	call	SendToDocSpreadsheet
	ret
GeoCalcDocumentSaveAsCompleted	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentUpdateCompatibleDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a compatible document

CALLED BY:	MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message

RETURN:		carry - set for error

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentUpdateCompatibleDocument	method dynamic GeoCalcDocumentClass,
			MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT
	mov	ax, -1				;ax <- OK to up protocol
	clc					;carry <- no error
	ret
GeoCalcDocumentUpdateCompatibleDocument		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentUpdateIncompatibleDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update an incompatible document

CALLED BY:	MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message

RETURN:		carry - set for error
		ax - non-zero to update documents protocol

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentUpdateIncompatibleDocument method dynamic GeoCalcDocumentClass,
			MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

		clr	ax			;ax <- do not up protocol
		stc				;carry <- error
		ret

GeoCalcDocumentUpdateIncompatibleDocument		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Determine where to send this event

PASS:		*ds:si	= GeoCalcDocumentClass object
		ds:di	= GeoCalcDocumentClass instance data
		es	= Segment of GeoCalcDocumentClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/26/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentSendClassedEvent	method	dynamic	GeoCalcDocumentClass, 
					MSG_META_SEND_CLASSED_EVENT
	;
	; Get the class of the destination
	;

	push	ax, cx, si
	mov	bx, cx
	call	ObjGetMessageInfo
	movdw	bxdi, cxsi			;bxdi <- class ptr
	;
	; check specially for PASTE
	;
	cmp	ax, MSG_META_CLIPBOARD_PASTE
	pop	ax, cx, si
	jne	checkCharts
	
	push	cx				;preserve event handle
	call	DocumentDoPaste			;branch if paste
	pop	bx				;restore event handle

	;
	; Free the event handle (bx).
	;
	call	ObjFreeMessage
	ret

checkCharts:
	;
	; See if this message should go to the GrObjHead
	;
if _CHARTS
	cmp	bx, segment GrObjHeadClass
	jne	notHead
	cmp	di, offset GrObjHeadClass
	jne	notHead

	GetResourceHandleNS	GCGrObjHead, bx
	mov	si, offset GCGrObjHead
	clr	di
	GOTO	ObjMessage
endif

notHead::
	;
	; Destined for the VisRuler?
	;
	cmp	bx, segment VisRulerClass
	jne	notRuler
	cmp	di, offset VisRulerClass
	jne	notRuler
	;
	; this message is destined for the VisRuler
	;
	mov	si, ds:[si]
	add	si, ds:[si].GeoCalcDocument_offset
	mov	bx, ds:[si].GCDI_spreadsheet	;bx <- handle of
						;spreadsheet block
	mov	si, offset GCColumnRuler
	clr	di
	GOTO	ObjMessage

notRuler:

	; check for the attribute manager
if _CHARTS
	cmp	bx, segment GrObjAttributeManagerClass
	jne	notAttrMgr
	cmp	di, offset GrObjAttributeManagerClass
	jne	notAttrMgr

	; this message is destined for the attribute manager

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	clr	di
	call	SendToOAM
	ret
endif

notAttrMgr::

	; check for grobj class. let the body handle 'em if so
	;
if _CHARTS
	cmp	bx, segment GrObjClass
	jne	checkBody
	cmp	di, offset GrObjClass
	je	toBody

checkBody:
	cmp	bx, segment GrObjBodyClass
	jne	notBody
	cmp	di, offset GrObjBodyClass
	jne	notBody

	; this message is destined for the body -- find it

toBody:
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	clr	di	
	call	SendToGrObjBody
	ret
endif

notBody::

	;
	; We don't know where this message is going -- just send it to
	; our superclass.
	;

	mov	di, offset GeoCalcDocumentClass
	GOTO	ObjCallSuperNoLock
GeoCalcDocumentSendClassedEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentDoPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a paste...

CALLED BY:	MSG_META_CLIPBOARD_
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentDoPaste		proc	far
	;
	; See if transfer contains spreadsheet data
	;
	clr	bp				;bp <- ClipboardItemFlags
	call	ClipboardQueryItem
	tst	bp				;any items available?
	jz	sendToSpreadsheet		;branch if none (why?)
	;
	; does CIF_SPREADSHEET format exist ?
	;
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_SPREADSHEET		;cx:dx <- format to check
	call	ClipboardTestItemFormat
	jc	sendToEditBarOrGrObj		;branch if no spreadsheet data
	;
	; Spreadsheet data exists -- pass off to the spreadsheet
	; unless the grobj is the target, in which case we guess...
	;
	call	getTargetLayer			;grobj target?
	jne	sendToSpreadsheet		;branch if spreadsheet target
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT
	call	ClipboardTestItemFormat
	jnc	sendToGrObj			;branch if text data
sendToSpreadsheet:
	call	ClipboardDoneWithItem
	call	GetDocSpreadsheet		;^lbx:si <- OD of spreadsheet
	mov	cl, GCTL_SPREADSHEET
	jmp	sendToLayer

	;
	; There is no spreadsheet transfer available.  See if we
	; should send it to the grobj or the edit bar.
	;
sendToEditBarOrGrObj:
	call	getTargetLayer
	je	sendToGrObj			;branch if grobj is target
	;
	; If text exists, send to the edit bar
	;
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT			;cx:dx <- format to check
	call	ClipboardTestItemFormat
	jnc	sendToEditBar			;branch if text exists
	;
	; If grobj data exists, send it to the grobj
	;
	clr	bp				;bp <- not CIF_QUICK
CHART<	call	GrObjTestSupportedTransferFormats			>
CHART<	jc	sendToGrObj			;branch if grobj data	>
	;
	; Wheee....grobj data doesn't exist.  Spreadsheet data doesn't
	; exist.  Send it to the edit bar and pray.
	;
sendToEditBar:
	call	ClipboardDoneWithItem
	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl	;^lbx:si <- OD of edit bar
	jmp	sendPaste

	;
	; Send the marines to the grobj and switch the target
	;
sendToGrObj:
	call	ClipboardDoneWithItem
CHART<	call	GetGrObjBodyOD		;^lbx:si <- OD of grobj layer	>
CHART<	mov	cl, GCTL_GROBJ						>

	;
	; Send to one layer or the other and make sure the target
	; is appropriate...
	;
sendToLayer:
	call	SetTargetLayerOpt
sendPaste:
	mov	ax, MSG_META_CLIPBOARD_PASTE
	mov	di, mask MF_CALL
	GOTO	ObjMessage

getTargetLayer:
	push	ax
	mov	ax, MSG_GEOCALC_APPLICATION_GET_TARGET_LAYER
	call	UserCallApplication
	pop	ax
	cmp	cl, GCTL_GROBJ			;grobj target?
	retn
DocumentDoPaste		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageToRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the ruler

CALLED BY:	GeoCalcDocumentSendClassedEvent()
PASS:		*ds:si - document object
		ax, cx, dx, bp - message data
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageToRuler		proc	near
	class	GeoCalcDocumentClass
	uses	bx, si, di, es
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].GeoCalcDocument_offset
	mov	bx, ds:[si].GCDI_spreadsheet
	mov	si, offset GCColumnRuler
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
MessageToRuler		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle GeoCalc document gaining target

CALLED BY:	MSG_META_GAINED_TARGET_EXCL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentGainedTargetExcl		method dynamic GeoCalcDocumentClass,
						MSG_META_GAINED_TARGET_EXCL
	mov	di, offset GeoCalcDocumentClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_RULER_GAINED_SELECTION
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, MSG_VIS_INVALIDATE
	call	MessageToRuler

	call	UpdateDocumentState

	;
	; Make sure the right layer has the target.
	;
	mov	ax, MSG_GEOCALC_APPLICATION_GET_TARGET_LAYER
	call	UserCallApplication
	cmp	cl, GCTL_SPREADSHEET		;spreadsheet target?
	je	doSpreadsheet			;branch if so
CHART<	call	GetGrObjBodyOD						>
setTarget:
	stc					;carry <- no optimization
	call	SetTargetLayer
	ret

doSpreadsheet:
	call	GetDocSpreadsheet
	jmp	setTarget
GeoCalcDocumentGainedTargetExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle GeoCalc document losing target

CALLED BY:	MSG_META_LOST_TARGET_EXCL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentLostTargetExcl	method dynamic	GeoCalcDocumentClass,
						MSG_META_LOST_TARGET_EXCL
	mov	ax, MSG_VIS_RULER_LOST_SELECTION
	call	MessageToRuler


	mov	ax, MSG_META_LOST_TARGET_EXCL
	mov	di, offset GeoCalcDocumentClass
	GOTO	ObjCallSuperNoLock

GeoCalcDocumentLostTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentVupCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle creating a GState and initialize it to our liking

CALLED BY:	MSG_VIS_VUP_CREATE_GSTATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message
RETURN:		bp - handle of GState
		carry - set for success
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentVupCreateGState		method dynamic GeoCalcDocumentClass,
						MSG_VIS_VUP_CREATE_GSTATE

	;
	; Call our superclass to create the GState
	;
		mov	di, offset GeoCalcDocumentClass
		call	ObjCallSuperNoLock
		
	;
	; Initialize the GState to our liking
	;
		mov	di, bp				;di <- GState handle
		mov	al, ColorMapMode <0, CMT_DITHER>
		call	GrSetTextColorMap
		stc					;carry <- success
		ret
GeoCalcDocumentVupCreateGState		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentSaveAs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the document to be dirty so our last-revision
		timestamp gets updated.

CALLED BY:	MSG_GEN_DOCUMENT_SAVE_AS, MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE
PASS:		*ds:si	= GeoCalcDocument object
		ds:di	= GeoCalcDocumentInstance
RETURN:		what those messages return
DESTROYED:	what those messages destroy
SIDE EFFECTS:	the document is marked dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/15/93	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentSaveAs method dynamic GeoCalcDocumentClass,
				MSG_GEN_DOCUMENT_SAVE_AS,
		    		MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE

if	_SUPER_IMPEX
	cmp	ax, MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE
	je	callSuper

	;
	; See what kind of document they want to save it as.
	;
	call	GetSelectedFileType		; cx = file type
	cmp	cx, GCDFT_CALC
	je	callSuper

	;
	; If not a native file, do the export
	;
	call	ExportDocTransparently
	; clears GDA_CLOSING
	mov	ax, MSG_GEN_DOCUMENT_GROUP_SAVE_AS_CANCELLED
	call	GenCallParent
	ret

callSuper:
endif
	mov	di, offset GeoCalcDocumentClass
	GOTO	ObjCallSuperNoLock

GeoCalcDocumentSaveAs endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentPhysicalOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invokes Impex converter for non-GeoGeoCalc files.

CALLED BY:	MSG_GEN_DOCUMENT_PHYSICAL_OPEN

PASS:		*ds:si	= GeoCalcDocumentClass object
		ds:di	= GeoCalcDocumentClass instance data
		ds:bx	= GeoCalcDocumentClass object (same as *ds:si)
		es 	= segment of GeoCalcDocumentClass
		ss:bp	= DocumentCommonParams

RETURN:		carry set on error, else clear
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	10/30/98   	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_SUPER_IMPEX
GeoCalcDocumentOpen	method dynamic GeoCalcDocumentClass, 
					MSG_GEN_DOCUMENT_OPEN
	;
	; See if it's one of our known DOS file types. If not,
	; just let the superclass do its job.
	;
		call	CheckIfNativeFile
		jc	dosFile
	;
	; OK, complete the opening of the file
	;
		mov	ax, MSG_GEN_DOCUMENT_OPEN
		mov	di, offset GeoCalcDocumentClass
		GOTO	ObjCallSuperNoLock
	;
	; For DOS files, we flag the document type in instance data.
	; We also remember the file name so when we save, we export
	; the file back to the original name.
	;
dosFile:
		mov	di, ds:[si]				
		add	di, ds:[di].Gen_offset
		lea	di, ds:[di].GCDI_dosFileName
		segmov	es, ds, ax		; es:di = buffer
		push	ds, si
		mov	cx, ss
		lea	dx, ss:[bp].DCP_name
		movdw	dssi, cxdx		; ds:si = filename
		mov	cx, size FileLongName
		rep	movsb			; copy me Jesus
		pop	ds, si
	;
	; Set up the Impex control to do the work (behind the scenes).
	; Also tell the DocumentControl to just hang around for a bit
	; and wait for either an import to be completed or else an
	; error to be displayed.
	;
		push	bp, si
		mov	ax, MSG_GEOCALC_DOC_CTRL_IMPORT_IN_PROGRESS
		GetResourceHandleNS	GCDocumentControl, bx
		mov	si, offset GCDocumentControl
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	bp, si
		call	ImportDocTransparently

		stc				; return error so we don't
						; open *another* document
		ret
GeoCalcDocumentOpen	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfNativeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if this is a native Writer file

CALLED BY:	GeoCalcDocumentOpen()

PASS:		ss:bp	= DocumentCommonParams

RETURN:		carry	= clear if it is a native GeoCalc file
			- or -
		carry	= set if it is not (i.e. a DOS file)

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		stevey 	10/29/98    	Initial version
		Don	2/21/99		Re-wrote
		Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_SUPER_IMPEX
CheckIfNativeFile	proc	near
		uses	ax, bx, cx, dx, bp, si, di, es, ds
		.enter
	;
	; Construct the complete path (sigh)
	;
		segmov	ds, ss, ax
		mov	es, ax
		mov	cx, PATH_BUFFER_SIZE + (size GeosFileType)
		sub	sp, cx
		mov	dx, sp
		mov	di, sp			; buffer => ES:DI
		mov	bx, ss:[bp].DCP_diskHandle
		lea	si, ss:[bp].DCP_path
		push	dx
		mov	dx, 1
		call	FileConstructFullPath
		pop	dx
		cmc				; invert carry
		jnc	done			; if error, assume native file
	;
	; Append the filename onto the path. Ensure that a BACKSLASH
	; separates the path from the filename.
	;
		mov	ax, C_BACKSLASH		
SBCS <		cmp	{byte} es:[di-1], al				>
DBCS <		cmp	{word} es:[di-2], ax				>
		je	copyString
		LocalPutChar	esdi, ax
copyString:
		lea	si, ss:[bp].DCP_name
		LocalCopyString
	;
	; OK...now see if this is a GEOS file or not. If we get
	; ERROR_ATTR_NOT_FOUND, then we don't have a GEOS file.
	;
		mov	ax, FEA_FILE_TYPE
		mov	di, dx
		add	di, PATH_BUFFER_SIZE
		mov	cx, size GeosFileType
		call	FileGetPathExtAttributes
		jnc	checkType
		cmp	ax, ERROR_ATTR_NOT_FOUND
		je	dosFile
		clc				; some other error...assume
		jmp	done			; native file and we're done
checkType:
		cmp	{word} es:[di], GFT_NOT_GEOS_FILE
		clc				; assume native file
		jne	done
dosFile:
		stc				; DOS file!!!
done:
		lahf
		add	sp, PATH_BUFFER_SIZE + (size GeosFileType)
		sahf

		.leave
		ret
CheckIfNativeFile	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportDocTransparently
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invokes ImportControl to import the document.

CALLED BY:	GeoCalcDocumentOpen
PASS:		*ds:si	= GeoCalcDocument object
		ss:bp	= DocumentCommonParams

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey  11/06/98    	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_SUPER_IMPEX
ImportDocTransparently	proc	near
		class	GeoCalcDocumentClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Bring up the dialog (because otherwise it's Unhappy) in the
	; background.
	;
		push	bp
		mov	ax, MSG_GEN_INTERACTION_INITIATE_NO_DISTURB
		GetResourceHandleNS GCImportControl, bx
		mov	si, offset GCImportControl
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ^lcx:dx = file selector
		Assert	optr, cxdx
		movdw	bxsi, cxdx		; ^lbx:si = file selector
		pop	bp 			; DocumentCommonParams => SS:BP
	;
	; Set the path and then the file.
	;
		push	bp
		mov	ax, MSG_GEN_PATH_SET
		mov	cx, ss
		lea	dx, ss:[bp].DCP_path
		mov	bp, ss:[bp].DCP_diskHandle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		pop	bp
		mov	cx, ss
		lea	dx, ss:[bp].DCP_name
		mov	ax, MSG_GEN_FILE_SELECTOR_SET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Tell it to do the import now (assuming auto-detect will do
	; the right thing)
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		GetResourceHandleNS GCImportControl, bx
		mov	si, offset GCImportControl
		mov	cx, IC_DISMISS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_IMPORT_CONTROL_IMPORT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		
		.leave
		ret
ImportDocTransparently	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectedFileType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieves the selection from the "save-as" file selector.

CALLED BY:	GeoCalcDocumentSave
PASS:		nothing
RETURN:		cx = GeoCalcDocumentFileType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey  11/12/98    	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_SUPER_IMPEX
GetSelectedFileType	proc	near
		uses	ax,bx,dx,si,di,bp
		.enter

		GetResourceHandleNS	GCDocumentControl, bx
		mov	si, offset GCDocumentControl
		mov	ax, MSG_GEOCALC_DOC_CTRL_GET_SELECTED_FILE_TYPE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
GetSelectedFileType	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportDocTransparently
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invokes the ExportCtrl to export the document.

CALLED BY:	GeoCalcDocumentSaveAs
PASS:		cx = GeoCalcDocumentFileType
		ss:bp = DocumentCommonParams
RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	exports the document

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	11/12/98    	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_SUPER_IMPEX

include	timer.def

ExportDocTransparently	proc	near
		class	GeoCalcDocumentClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter	inherit GeoCalcDocumentSaveAs
	;
	; Bring up the dialog (because otherwise it's Unhappy) in the
	; background.
	;
		push	cx			; save file type
		push	bp			; stack frame
		mov	ax, MSG_GEN_INTERACTION_INITIATE_NO_DISTURB
		GetResourceHandleNS GCExportControl, bx
		mov	si, offset GCExportControl
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp			; stack frame
	;
	; Get the format-type selector (a GenDynamicList).
	;
		push	bp
		GetResourceHandleNS GCExportControl, bx
		mov	si, offset GCExportControl
		mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ^lcx:dx = format list
		pop	bp
	;
	; Set the output format (hack, hack, hack)
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	bx, cx
		mov	si, dx			; GenItemGroup => BX:SI
		pop	cx			; GeoCalcDocumentFileType => CX
		cmp	cx, GCDFT_CSV
		mov	cx, 0			; "CSV" is listed first
		je	setSelection
		mov	cx, 1			; "Lotus 123" is second
setSelection:
		push	bp
		clr	dx
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		mov	cx, 1			; pretend user clicked on entry
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp

		mov	ax, 10			; !!!hack!!!
		call	TimerSleep		; sleep for a bit to make sure
						; the Import DB finishes with
						; setting the default file name
	;
	; Set the output path to whatever the user selected in the
	; "save-as" dialog (it's in DocumentCommonParams).
	;
		GetResourceHandleNS GCExportControl, bx
		mov	si, offset GCExportControl
		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_SELECTOR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		movdw	bxsi, cxdx		; ^lbx:si = file selector

		push	bp
		mov	ax, MSG_GEN_PATH_SET
		mov	cx, ss
		lea	dx, ss:[bp].DCP_path
		mov	bp, ss:[bp].DCP_diskHandle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
	;
	; Set the output filename to whatever the user had in the
	; "save-as" dialog (it's in DocumentCommonParams).
	;
		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_NAME_FIELD
		GetResourceHandleNS GCExportControl, bx
		mov	si, offset GCExportControl
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ^lcx:dx = optr
		Assert	optr, cxdx
		movdw	bxsi, cxdx

		mov	dx, ss
		lea	bp, ss:[bp].DCP_name	; ss:bp = filename
		clr	cx			; null-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Tell it to do the export now.
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		GetResourceHandleNS GCExportControl, bx
		mov	si, offset GCExportControl
		mov	cx, IC_DISMISS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_EXPORT_CONTROL_EXPORT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
ExportDocTransparently	endp
endif

Document ends


