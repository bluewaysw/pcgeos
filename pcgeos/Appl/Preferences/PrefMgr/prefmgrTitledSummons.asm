COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	Config
MODULE:		
FILE:		prefmgrTitledSummons.asm

AUTHOR:		Andrew Wilson, Dec  3, 1990

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/90	Initial revision

DESCRIPTION:

	$Id: prefmgrTitledSummons.asm,v 1.1 97/04/04 16:27:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


if not _SIMPLE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTitledTriggerSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We intercept SpecBuild and create a moniker for the glyph
		(a nifty one, with a title and *everything*).

CALLED BY:	GLOBAL

PASS:		*ds:si - PrefTitledTrigger object

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTitledTriggerSpecBuild	method dynamic PrefTitledTriggerClass, 
							MSG_SPEC_BUILD
	push	si
	mov	si, ds:[di].GI_visMoniker
	call	ConfigBuildTitledMoniker
	pop	si

	; Now, call superclass

	mov	di, offset PrefTitledTriggerClass
	GOTO	ObjCallSuperNoLock
PrefTitledTriggerSpecBuild	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTitledTriggerDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Ignore MSG_GEN_DESTROY, because this only comes when
		prefmgr is trying to nuke the installable module
		triggers, which we're not.

PASS:		*ds:si	- PrefTitledTriggerClass object
		ds:di	- PrefTitledTriggerClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTitledTriggerDestroy	method	dynamic	PrefTitledTriggerClass, 
					MSG_GEN_DESTROY
		ret
PrefTitledTriggerDestroy	endm

endif
