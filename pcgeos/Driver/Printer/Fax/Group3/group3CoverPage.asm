COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		group3 printer driver
FILE:		group3CoverPage.asm

AUTHOR:		Andy Chiu, Oct  4, 1993

ROUTINES:
	Name			Description
	----			-----------
				
	CoverPageSenderInteractionVisClose
				When this dialog is closed we need to update 
				the information	in the summary text box.  
				So we send it a message to update itself.
				

	CoverPageCommentsInkControlGetInfo
				This message is subclassed so we don't
				have to have the controller in the
				self load options list.				


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 4/93   	Initial revision


DESCRIPTION:
	Changes to the GenText Object so we can make our own behavior.
		
	$Id: group3CoverPage.asm,v 1.1 97/04/18 11:52:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CoverPageSenderInteractionVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When this dialog is closed we need to update the information
		in the summary text box.  So we send it a message to 
		update itself.

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= CoverPageSenderInteractionClass object
		ds:di	= CoverPageSenderInteractionClass instance data
		ds:bx	= CoverPageSenderInteractionClass object (same as *ds:si)
		es 	= segment of CoverPageSenderInteractionClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CoverPageSenderInteractionVisClose	method dynamic CoverPageSenderInteractionClass, 
					MSG_VIS_CLOSE

senderName	local	FAXFILE_NAME_BUFFER_SIZE	dup (char)
		
		.enter
		
	;
	; Make sure the super class has been called
	;
		push	bp
		mov	di, offset CoverPageSenderInteractionClass
		call	ObjCallSuperNoLock
		pop	bp
if 0
	;
	; Send an update message to the text box that displays a summary of
	; the sender information
	;
		mov	ax, MSG_FROM_GLYPH_UPDATE_INFORMATION
		mov	si, offset Group3UI:CoverPageFromGlyph
		call	ObjCallInstanceNoLock
endif
	;
	; Find the sender name and put it in the local variable senderName.
	;
		push	bp			; save for locals

		mov	dx, ss
		lea	bp, ss:senderName	; dx:bp <- buffer
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	si, offset CoverPageFromText
		call	ObjCallInstanceNoLock
	;
	; Put the sender name in the from summary field in the cover page
	; information.
	;
		mov	si, offset CoverPageFromSummaryText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock
		
		mov	ax, MSG_VIS_TEXT_SELECT_START
		call	ObjCallInstanceNoLock

		pop	bp
		
		.leave		
		ret
CoverPageSenderInteractionVisClose	endm


if 0

changed because print spooler doesn't allow controllers.

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CoverPageCommentsInkControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is subclassed so we don't have to have the 
		controller in the self load options list.				

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= CoverPageCommentsInkControlClass object
		ds:di	= CoverPageCommentsInkControlClass instance data
		ds:bx	= CoverPageCommentsInkControlClass object (same as *ds:si)
		es 	= segment of CoverPageCommentsInkControlClass
		ax	= message #
		cx:dx	= GenControlDupInfo structure to fill in
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CoverPageCommentsInkControlGetInfo	method dynamic CoverPageCommentsInkControlClass, 
					MSG_GEN_CONTROL_GET_INFO
	uses	ax, bp
	.enter

	;
	; Call the super class to make sure all the fields are filled.
	;
		mov	di, offset CoverPageCommentsInkControlClass
		push	cx
		call	ObjCallSuperNoLock
		pop	cx
	;
	; Change the information so it doesn't have to be in the 
	; self load options list.
	;
		mov	ds, cx
		mov	si, dx
		or	ds:[si].GCBI_flags, \
			mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST

	.leave
	ret
CoverPageCommentsInkControlGetInfo	endm
endif


















