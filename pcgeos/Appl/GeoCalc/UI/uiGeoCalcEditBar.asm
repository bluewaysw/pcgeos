COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		GeoCalc
FILE:		uiEditBar.asm

AUTHOR:		Gene Anderson, Aug 21, 1991

ROUTINES:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/21/91		Initial revision

DESCRIPTION:
	Routines and handlers for GeoCalcSSEditBarControlClass

	$Id: uiGeoCalcEditBar.asm,v 1.1 97/04/04 15:48:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GeoCalcClassStructures	segment	resource
	GeoCalcSSEditBarControlClass
GeoCalcClassStructures	ends


UICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCSSEBCPassKeypress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle keypress from edit bar that completes editing
CALLED BY:	MSG_SSEBC_PASS_KEYPRESS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcSSEditBarControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GCSSEBCPassKeypress	method dynamic GeoCalcSSEditBarControlClass, \
						MSG_SSEBC_ENTER_DATA,
						MSG_SSEBC_GOTO_CELL,
						MSG_SSEBC_GOTO_CELL_DB,
						MSG_GEN_RESET
	push	ax, cx, dx, bp, si
	;
	; Give the focus to the display area, so that when the display
	; group goes to grab it, the edit bar has already released it
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	GetResourceHandleNS GCDisplayArea, bx
	mov	si, offset GCDisplayArea	;^lbx:si <- OD of display ctrl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; Give the focus back to the spreadsheet.  We do this by
	; giving the focus to the display control, which is the top
	; of the tree which the spreadsheet sits in.
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	GetResourceHandleNS GCDisplayGroup, bx
	mov	si, offset GCDisplayGroup	;^lbx:si <- OD of display ctrl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	ax, cx, dx, bp, si
	;
	; Let our superclass do the right thing
	;
	mov	di, offset GeoCalcSSEditBarControlClass
	GOTO	ObjCallSuperNoLock

GCSSEBCPassKeypress	endm

UICode	ends
