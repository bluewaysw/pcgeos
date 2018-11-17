COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefTrigger.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/14/92   	Initial version.

DESCRIPTION:
	

	$Id: prefTrigger.asm,v 1.1 97/04/04 17:50:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTriggerSendAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefTriggerClass object
		ds:di	= PrefTriggerClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTriggerSendAction	method	dynamic	PrefTriggerClass, 
					MSG_GEN_TRIGGER_SEND_ACTION
	.enter
	mov	di, offset PrefTriggerClass
	call	ObjCallSuperNoLock

	mov	ax, length prefTriggerVarDataHandlers
	segmov	es, cs
	mov	di, offset prefTriggerVarDataHandlers
	call	ObjVarScanData
	
	.leave
	ret
PrefTriggerSendAction	endm

prefTriggerVarDataHandlers	VarDataHandler	\
	<ATTR_PREF_TRIGGER_ACTION, PrefTriggerHandleExtraAction>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTriggerHandleExtraAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send out the message contained in the
		PrefTriggerAction data

CALLED BY:	PrefTriggerSendAction via ObjVarScanData

PASS:		ds:bx - PrefTriggerAction data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTriggerHandleExtraAction	proc far
	.enter
	mov	ax, ds:[bx].PTA_message
	mov	si, ds:[bx].PTA_dest.offset
	mov	bx, ds:[bx].PTA_dest.handle
	clr	di
	call	ObjMessage
	.leave
	ret
PrefTriggerHandleExtraAction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTriggerMetaKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle carriage return by activating self 

PASS:		*ds:si	- PrefTriggerClass object
		ds:di	- PrefTriggerClass instance data
		es	- segment of PrefTriggerClass

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 2/95   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTriggerMetaKbdChar	method	dynamic	PrefTriggerClass, 
					MSG_META_KBD_CHAR
		
SBCS <		cmp	cx, (CS_CONTROL shl 8) or VC_CTRL_M		>
DBCS <		cmp	cx, C_CR					>
		jne	callSuper
		;
		; Test CharFlags to decide whether to activate the
		; application or not.
		;
		test 	dl, mask CF_FIRST_PRESS
		jz	callSuper

		mov	ax, MSG_GEN_ACTIVATE
		GOTO	ObjCallInstanceNoLock 

callSuper:
		mov	di, offset PrefTriggerClass
		GOTO	ObjCallSuperNoLock
		
PrefTriggerMetaKbdChar	endm
