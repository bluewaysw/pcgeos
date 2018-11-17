COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefmousPortList.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/21/93   	Initial version.

DESCRIPTION:
	

	$Id: prefmousPortList.asm,v 1.1 97/04/05 01:38:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousPortListUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If not enabled, use the "not needed" string.

PASS:		*ds:si	- PrefMousPortListClass object
		ds:di	- PrefMousPortListClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousPortListUpdateText	method	dynamic	PrefMousPortListClass, 
					MSG_PREF_ITEM_GROUP_UPDATE_TEXT
		.enter
		
		push	ax, cx
		mov	ax, MSG_GEN_GET_ENABLED
		call	ObjCallInstanceNoLock
		pop	ax, cx
		jnc	notEnabled

		mov	di, offset PrefMousPortListClass
		call	ObjCallSuperNoLock
		jmp	done

notEnabled:
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		mov	dx, handle nonSerialMouseString
		mov	bp, offset nonSerialMouseString
		mov	si, cx
		clr	cx
		call	ObjCallInstanceNoLock 
done:
		.leave
		ret
PrefMousPortListUpdateText	endm

