COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		loopbackAddrCtrl.asm

AUTHOR:		Steve Jang, Dec  5, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 5/94   	Initial revision


DESCRIPTION:
	LoopbackAddressControlClass code.

	$Id: loopbackAddrCtrl.asm,v 1.2 95/01/09 01:42:47 weber Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackClassStructures	segment resource

LoopbackAddrCtrlChildList	GenControlChildInfo	\
	< offset LoopbackAddrCtrlBox,
	  0,
 	  mask GCCF_IS_DIRECTLY_A_FEATURE or mask GCCF_ALWAYS_ADD>

LoopbackAddrCtrlFeaturesList GenControlFeaturesInfo	\
	< offset LoopbackAddrCtrlBox,
	  0,
	  1>

LoopbackClassStructures	ends

LoopbackCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LACGenControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns GenCtrl information for LoopbackAddressControlClass

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= LoopbackAddressControlClass object
		ds:di	= LoopbackAddressControlClass instance data
		ds:bx	= LoopbackAddressControlClass object (same as *ds:si)
		es 	= segment of LoopbackAddressControlClass
		ax	= message #
		cx:dx	= Buffer for GenControlInfo
RETURN:		GenControlDupInfo field filled in
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LACGenControlGetInfo	method dynamic LoopbackAddressControlClass, 
					MSG_GEN_CONTROL_GET_INFO
		uses	cx
		.enter
	;
	; copy the data into the buffer
	;
		segmov	ds, cs				; ds:si = source
		mov	si, offset LoopbackAddrCtrlInfo
		mov	es, cx
		mov	di, dx				; es:di = dest
		mov	cx, size GenControlBuildInfo
		rep	movsb
		
		.leave
		ret
LACGenControlGetInfo	endm

LoopbackAddrCtrlInfo	GenControlBuildInfo <
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ;GCBI_flags
	0,					; GCBI_initFileKey
	0,					; GCBI_gcnList
	0,					; GCBI_gcnCount
	0,					; GCBI_notificationList
	0,					; GCBI_notificationCount
	0,					; GCBI_controllerName

	handle LoopbackAddrCtrlBox,		; GCBI_dupBlock
	LoopbackAddrCtrlChildList,		; GCBI_childList
	length LoopbackAddrCtrlChildList,	; GCBI_childCount
	LoopbackAddrCtrlFeaturesList,		; GCBI_featuresList
	length LoopbackAddrCtrlFeaturesList,	; GCBI_featuresCount
	1,					; GCBI_features
	0,					; GCBI_toolBlock
	0,					; GCBI_toolList
	0,					; GCBI_toolCount
	0,					; GCBI_toolFeaturesList
	0,					; GCBI_toolFeaturesCount
	0,					; GCBI_toolFeatures
	0,					; GCBI_helpContext
	0					; GCBI_reserve
>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize instance data with our geode handle

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= LoopbackAddressControlClass object
		es 	= segment of LoopbackAddressControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	1/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackInitialize	method dynamic LoopbackAddressControlClass, 
					MSG_META_INITIALIZE
		mov	ds:[di].SACI_geode, handle 0
		mov	di, offset LoopbackAddressControlClass
		GOTO	ObjCallSuperNoLock
LoopbackInitialize	endm

LoopbackCode ends
