COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefmousTrigger.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/94   	Initial version.

DESCRIPTION:
	

	$Id: prefmousTrigger.asm,v 1.1 97/04/05 01:38:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @--------------------------------------------------------

FUNCTION:	PrefMgrTriggerStartSelect

DESCRIPTION:	Sounds a beep when a double click is detected.

CALLED BY:	INTERNAL (MSG_META_START_SELECT)

PASS:		nothing

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		---------------
	Cheng	2/90		Initial version

-------------------------------------------------------------------@

PrefMousTriggerStartSelect	method	PrefMousTriggerClass,
					MSG_META_START_SELECT
	tst	ds:[di].PMTI_doubleClickOnly
	jz	gotoSuper

	test	bp, mask BI_DOUBLE_PRESS
	jnz	beep
	ret
beep:
	push	ax
	mov	ax, SST_WARNING		;Just a general beep
	call    UserStandardSound	;destroys ax,bx
	pop	ax

gotoSuper:
	
	mov	di, offset PrefMousTriggerClass
	GOTO	ObjCallSuperNoLock

PrefMousTriggerStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousTriggerKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Ignore space / carriage return

PASS:		*ds:si	- PrefMousTriggerClass object
		ds:di	- PrefMousTriggerClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousTriggerKbdChar	method	dynamic	PrefMousTriggerClass, 
					MSG_META_KBD_CHAR

		cmp	cx, ' '
		je	fupIt
SBCS <		cmp	cx, (CS_CONTROL shl 8) or VC_CTRL_M		>
DBCS <		cmp	cx, C_CARRIAGE_RETURN				>
		jne	gotoSuper
fupIt:
		mov	ax, MSG_META_FUP_KBD_CHAR
		GOTO	VisCallParent

gotoSuper:
		mov	di, offset PrefMousTriggerClass
		GOTO	ObjCallSuperNoLock
PrefMousTriggerKbdChar	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousTriggerActivate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Do nothing -- the only way this trigger can get
		activated is by clicking on it

PASS:		*ds:si	- PrefMousTriggerClassClass object
		ds:di	- PrefMousTriggerClassClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousTriggerActivate	method	dynamic	PrefMousTriggerClass, 
					MSG_GEN_ACTIVATE
		ret
PrefMousTriggerActivate	endm

