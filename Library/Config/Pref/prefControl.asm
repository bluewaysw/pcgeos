COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefControl.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/19/93   	Initial version.

DESCRIPTION:
	

	$Id: prefControl.asm,v 1.1 97/04/04 17:50:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefControlResolveVariant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefControlClass object
		ds:di	- PrefControlClass instance data
		es	- dgroup

RETURN:		cx:dx 	- fptr to variant superclass

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 2/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefControlResolveVariant method dynamic PrefControlClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
		cmp	cx, Pref_offset
		jne	gotoSuper

		mov	cx, segment GenControlClass
		mov	dx, offset GenControlClass
		ret

gotoSuper:
		mov	di, offset PrefControlClass
		GOTO	ObjCallSuperNoLock

PrefControlResolveVariant	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefControlReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Bypass GenControl's handling of MSG_GEN_RESET, as it
		doesn't do what we want.

PASS:		*ds:si	- PrefControlClass object
		ds:di	- PrefControlClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefControlReset	method	dynamic	PrefControlClass, 
					MSG_GEN_RESET
		segmov	es, <segment GenClass>, di
		mov	di, offset GenClass
		GOTO	ObjCallClassNoLock
PrefControlReset	endm

