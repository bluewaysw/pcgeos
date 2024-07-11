COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		entapp.asm

AUTHOR:		Ronald Braunstein, Jun 17, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	6/17/96   	Initial revision


DESCRIPTION:
	Code for EntApp class
		
	$Id: entApp.asm,v 1.1 98/03/06 17:54:52 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;
; Create MyGenApplication class so we can intercept MSG_META_INITIALIZE and
; set defaults as the normal handler in Gen doesn't do everything correctly
; and it doesn't get the static defaults because there is another master level
; above it.

MyGenApplicationClass class	GenApplicationClass
MyGenApplicationClass endc
idata segment
	MyGenApplicationClass
idata ends
include	Legos/basrun.def
include Legos/runheap.def
include Internal/heapInt.def
include Internal/threadIn.def



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntAppMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add GenApplication to our class tree.

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= EntAppClass object
		ds:di	= EntAppClass instance data
		ds:bx	= EntAppClass object (same as *ds:si)
		es 	= segment of EntAppClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntAppMetaResolveVariantSuperclass	method dynamic EntAppClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

		compResolveSuperclass EntApp, MyGenApplication

EntAppMetaResolveVariantSuperclass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyGenApplicationMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default values that the superclass fails to do.

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= MyGenApplicationClass object
		ds:di	= MyGenApplicationClass instance data
		ds:bx	= MyGenApplicationClass object (same as *ds:si)
		es 	= segment of MyGenApplicationClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyGenApplicationMetaInitialize	method dynamic MyGenApplicationClass, 
					MSG_META_INITIALIZE
		.enter
		mov	di, offset MyGenApplicationClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].MyGenApplication_offset

		mov	ds:[di].GAI_states, mask AS_FOCUSABLE or mask AS_MODELABLE
		mov	ds:[di].GAI_appLevel, UIIL_ADVANCED
		.leave
		ret
MyGenApplicationMetaInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntAppEntGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return string for our class: "app"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= EntAppClass object
		ds:di	= EntAppClass instance data
		ds:bx	= EntAppClass object (same as *ds:si)
		es 	= segment of EntAppClass
		ax	= message #
RETURN:		^fcx:dx	= string

DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
appClassString TCHAR 'app', C_NULL
EntAppEntGetClass	method dynamic EntAppClass, 
					MSG_ENT_GET_CLASS
		.enter
		mov	cx, cs
		mov	dx, offset appClassString
		.leave
		ret
EntAppEntGetClass	endm


		
if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntAppEntValidateChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow all children in app

CALLED BY:	MSG_ENT_VALIDATE_CHILD
PASS:		*ds:si	= EntAppClass object
		ds:di	= EntAppClass instance data
		ds:bx	= EntAppClass object (same as *ds:si)
		es 	= segment of EntAppClass
		ax	= message #
RETURN:		ax	= 0, if accept child,
			= 1, if deny

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This is only needed because we don't get META_INITIALIZE of
		ENT_INITIALIZE so we can't set EF_ALLOWS_CHILDREN.

		Perhaps this should be changed to only accept non-visible
		things or things that are windows.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntAppEntValidateChild	method dynamic EntAppClass, 
					MSG_ENT_VALIDATE_CHILD
		.enter
		clr	ax
		.leave
		ret
EntAppEntValidateChild	endm
endif
