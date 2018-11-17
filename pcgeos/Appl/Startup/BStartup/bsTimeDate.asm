COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bsTimeDate.asm

AUTHOR:		Steve Yegge, Jul 15, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93		Initial revision

DESCRIPTION:
	

	$Id: bsTimeDate.asm,v 1.1 97/04/04 16:53:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PrefTDCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTDDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "OK" in "Time/Date" section.

CALLED BY:	MSG_TIME_DATE_APPLY
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of PrefTDDialogClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BSTimeDateDialogApply		method dynamic BSTimeDateDialogClass,
					MSG_GEN_APPLY

		mov	di, offset BSTimeDateDialogClass
		call	ObjCallSuperNoLock
		
	;
	;  Tell the primary we're done.
	;
		GetResourceHandleNS	MyBSPrimary, bx
		mov	si, offset	MyBSPrimary
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_BS_PRIMARY_DONE_DATE_TIME
		GOTO	ObjMessage

BSTimeDateDialogApply		endm


PrefTDCode	ends
