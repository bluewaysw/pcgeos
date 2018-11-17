COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Appl/GeoWrite
FILE:		uiPrint.asm

AUTHOR:		Don Reeves, May  2, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 2/95		Initial revision

DESCRIPTION:
	Implements the DWPPrintControlClass

	$Id: uiPrint.asm,v 1.1 97/04/04 15:55:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoWriteClassStructures	segment	resource
	WritePrintCtrlClass
GeoWriteClassStructures	ends

DocPrint	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePrintCtrlInitiateOutputUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate the print or fax dialog box

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_INITIATE_OUTPUT_UI)

PASS:		ES	= Segment of WritePrintCtrlClass
		*DS:SI	= WritePrintCtrlClass object
		DS:DI	= WritePrintCtrlClassInstance
		CL	= PrinterDriverType

RETURN:		see documentation for MSG_PRINT_CONTROL_INITIATE_OUTPUT_UI

DESTROYED:	see documentation for MSG_PRINT_CONTROL_INITIATE_OUTPUT_UI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/ 2/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WritePrintCtrlInitiateOutputUI	method dynamic	WritePrintCtrlClass,
				MSG_PRINT_CONTROL_INITIATE_OUTPUT_UI
	;
	; If we are faxing, then don't display any merge options.
	; Otherwise, display them.
	;
		push	cx, dx, bp, si
		mov	ax, MSG_GEN_SET_NOT_USABLE
		cmp	cl, PDT_FACSIMILE
		je	sendMessage
		mov	ax, MSG_GEN_SET_USABLE
sendMessage:
		GetResourceHandleNS	PrintUI, bx
		mov	si, offset PrintUI:InnerPrintGroup
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; If we are faxing, always turn the merge option off
	;
		cmp	cl, PDT_FACSIMILE
		jne	callSuper
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, MT_NONE		; turn off merging
		clr	dx			; determinate		
		mov	si, offset PrintUI:MergeList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Call our superclass to do the real work
	;
callSuper:
		pop	cx, dx, bp, si
		mov	ax, MSG_PRINT_CONTROL_INITIATE_OUTPUT_UI
		mov	di, offset WritePrintCtrlClass
		GOTO	ObjCallSuperNoLock
WritePrintCtrlInitiateOutputUI	endm

DocPrint	ends
