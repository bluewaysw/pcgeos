COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		fatbitsTool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	5/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the FatbitsToolClass

RCS STAMP:
$Id: fatbitsTool.asm,v 1.1 97/04/04 17:43:38 newdeal Exp $

------------------------------------------------------------------------------@
BitmapClassStructures	segment resource
	FatbitsToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FatbitsToolGetPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	FatbitsTool method for MSG_TOOL_GET_POINTER_IMAGE

Called by:	MSG_TOOL_GET_POINTER_IMAGE

Pass:		*ds:si = FatbitsTool object
		ds:di = FatbitsTool instance

Return:		ax =  mask MRF_SET_POINTER_IMAGE
		^lcx:dx - "cross hairs" image

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FatbitsToolGetPointerImage	method dynamic	FatbitsToolClass,
				MSG_TOOL_GET_POINTER_IMAGE
	.enter

	mov	ax, mask MRF_SET_POINTER_IMAGE
	mov	cx, handle magnifyingGlass
	mov	dx, offset magnifyingGlass

	.leave
	ret
FatbitsToolGetPointerImage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				FatbitsToolStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_START_* handler for FatbitsToolClass

CALLED BY:	UI

PASS:		*ds:si = Tool object
		ds:di = Tool instance
		cx, dx = mouse location
		bp high = UIFunctionsActive
		bp low = ButtonInfo
		
CHANGES:	

RETURN:		ax - mask MRF_PROCESSED

DESTROYED:	bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FatbitsStartSelect	method dynamic	FatbitsToolClass, MSG_META_START_SELECT

	.enter

	mov	bp, IBS_8
	mov	ax, MSG_VIS_BITMAP_INITIATE_FATBITS
	call	ToolCallBitmap

	mov	ax, mask MRF_PROCESSED
	.leave
	ret
FatbitsStartSelect	endm

BitmapToolCodeResource	ends			;end of tool code resource
