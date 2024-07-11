COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1997 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		servsys.asm

AUTHOR:		Gene Anderson, Sep 15, 1997

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/15/97   	Broke out of sysui.asm


DESCRIPTION:

	$Id: servsys.asm,v 1.1 98/03/11 04:30:09 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	ServSysClass
idata	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSSEntSetParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check for valid parent

CALLED BY:	MSG_ENT_SET_PARENT
PASS:		*ds:si	= GadgetSysServClass object
		ds:di	= GadgetSysServClass instance data
		ds:bx	= GadgetSysServClass object (same as *ds:si)
		es 	= segment of GadgetSysServClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GSSEntSetParent	method dynamic ServSysClass, 
					MSG_ENT_SET_PARENT

		.enter
	;
	; Make sure "app" is the requested parent.
	;
		mov	di, offset ServSysClass
		call	GadgetUtilCheckParentIsApp
		
		.leave
		ret
GSSEntSetParent	endm



SetDefaultConvention

gadgetSetDSToDGroup	proc	far
	mov	ax, ds		; return old DS in ax
	segmov	ds, dgroup, dx
	ret
gadgetSetDSToDGroup	endp
	public	gadgetSetDSToDGroup


gadgetRestoreDS	proc	far	oldDS:word
	.enter
	segmov	ds, oldDS, ax
	.leave
	ret
gadgetRestoreDS	endp
	public gadgetRestoreDS
