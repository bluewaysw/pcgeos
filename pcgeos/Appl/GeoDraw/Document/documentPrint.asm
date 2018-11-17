COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	GeoDraw
MODULE:		Document
FILE:		documentPrint.asm

AUTHOR:		Steve Scholl, Aug 12, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	8/12/92		Initial revision


DESCRIPTION:
	
		

	$Id: documentPrint.asm,v 1.1 97/04/04 15:51:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentStartPrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the document

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DrawDocumentClass

		cx,dx - OD of DrawPrintControl
		bp - gstate

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentStartPrint	method dynamic DrawDocumentClass, 
						MSG_PRINT_START_PRINTING

gstate		local	word	push	bp
printControl	local	optr	push	cx, dx
docSizeInfo	local	PageSizeReport
	.enter

	;    Notify the print control of the size of the document
	;

	push	si					;doc chunk
	push	bp					;stack frame
	call	DrawDocumentGetDocumentDimensions	
	mov	di, bp
	pop	bp					;stack frame
	movdw	docSizeInfo.PSR_width,dxcx
	movdw	docSizeInfo.PSR_height,bxax
	mov	docSizeInfo.PSR_layout,di
	call	DrawDocumentGetDocumentMargins
	mov	docSizeInfo.PSR_margins.PCMP_left,ax
	mov	docSizeInfo.PSR_margins.PCMP_top,bx
	mov	docSizeInfo.PSR_margins.PCMP_right,cx
	mov	docSizeInfo.PSR_margins.PCMP_bottom,dx

	push	bp					;stack frame
	movdw	bxsi,printControl
	mov	dx,ss					
	lea	bp,docSizeInfo
	mov	di,mask MF_FIXUP_DS or mask MF_CALL	;because stuff on stack
	mov	ax,MSG_PRINT_CONTROL_SET_DOC_SIZE_INFO
	call	ObjMessage
	pop	bp					;stack frame
	pop	si					;doc chunk

	;     Draw that document
	;

	push	bp					;stack frame
	mov	bp,gstate	
	mov	cl,mask DF_PRINT
	mov	ax,MSG_VIS_DRAW
	call	ObjCallInstanceNoLock
	pop	bp					;stack frame

	;	Mark the end of the single page
	;

	mov	di,gstate
	mov	al,PEC_FORM_FEED
	call	GrNewPage

	;     Finish it
	;

	push	bp					;stack frame
	movdw	bxsi,printControl
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp					;stack frame


	.leave

	Destroy	ax,cx,dx,bp

	ret
DrawDocumentStartPrint		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentReportPageSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The page controller is telling us that the page size
		has changed

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DrawDocumentClass
		ss:bp - PageSizeReport


RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentReportPageSize	method dynamic DrawDocumentClass, 
						MSG_PRINT_REPORT_PAGE_SIZE
	.enter

	;    Invalidate before incase document shrinks
	;

	mov	ax,MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	mov	ax,ss:[bp].PSR_margins.PCMP_left
	mov	bx,ss:[bp].PSR_margins.PCMP_top
	mov	cx,ss:[bp].PSR_margins.PCMP_right
	mov	dx,ss:[bp].PSR_margins.PCMP_bottom
	call	DrawDocumentSetDocumentMargins
	movdw	dxcx,ss:[bp].PSR_width
	movdw	bxax,ss:[bp].PSR_height
	mov	bp,ss:[bp].PSR_layout
	call	DrawDocumentSetDocumentDimensions
	call	DrawDocumentSendDocumentSizeToView
	call	DrawDocumentSetGrObjBodyBounds

	;    Invalidate afterword incase document grows
	;

	mov	ax,MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	.leave

	Destroy	ax,cx,dx,bp

	ret
DrawDocumentReportPageSize		endm






DocumentCode	ends



