COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiControlCommon.asm

AUTHOR:		Jon Witort

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 feb 1992   	Initial version.

DESCRIPTION:
	Common routines for Ruler controllers

	$Id: uiControlCommon.asm,v 1.1 97/04/07 10:43:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerUICode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CopyDupInfoCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Copies GenControlBuildInfo frame from source to dest

Pass:		cs:si = source GenControlDupIndo frame
		cx:dx = dest

Return:		nothing

Destroyed:	cx, di, es, ds

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyDupInfoCommon	proc	near
	mov	es, cx
	mov	di, dx
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo / 2
	rep movsw
	if ((size GenControlBuildInfo AND 1) eq 1)
		movsb
	endif
	ret
CopyDupInfoCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			UpdateRulerUnits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Updates the units of the controller

Pass:		ss:bp = GenControlUpdateUIParams structure
		si = offset of ruler units list

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateRulerUnits	proc	near
	uses	ax, bx, cx, dx, bp, di, ds
	.enter
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	cl, ds:[RTNB_type]
	call	MemUnlock
	clr	ch
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di, dx
	call	ObjMessage
	.leave
	ret
UpdateRulerUnits	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the data block where the children live

CALLED BY:

PASS:		*ds:si - GenControl object

RETURN:		bx - child block

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/27/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildBlock	proc near	
	uses	ax
	.enter
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	bx, ds:[bx].TGCI_childBlock

	.leave
	ret
GetChildBlock	endp
RulerUICode	ends
