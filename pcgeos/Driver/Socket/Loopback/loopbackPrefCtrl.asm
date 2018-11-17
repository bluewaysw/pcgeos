COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		loopbackPrefCtrl.asm

AUTHOR:		Steve Jang, Dec  5, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 5/94   	Initial revision


DESCRIPTION:
	LoopbackPreferenceControlClass code.

	$Id: loopbackPrefCtrl.asm,v 1.1 97/04/18 11:57:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NO_PREFERENCES_APPLICATION
LoopbackClassStructures	segment resource

LoopbackPrefCtrlChildList	GenControlChildInfo	\
	< offset LoopbackPrefCtrlBox,
	  0,
 	  mask GCCF_IS_DIRECTLY_A_FEATURE or mask GCCF_ALWAYS_ADD>

LoopbackPrefCtrlFeaturesList GenControlFeaturesInfo	\
	< offset LoopbackPrefCtrlBox,
	  0,
	  1>

LoopbackClassStructures	ends

LoopbackCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LPCGenControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns GenCtrl information for LoopbackPreferenceControlClass

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= LoopbackPreferenceControlClass object
		ds:di	= LoopbackPreferenceControlClass instance data
		ds:bx	= LoopbackPreferenceControlClass object
		es 	= segment of LoopbackPreferenceControlClass
		ax	= message #
		cx:dx	= Buffer for GenControlInfo
RETURN:		GenControlDupInfo field filled in
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LPCGenControlGetInfo	method dynamic LoopbackPreferenceControlClass, 
					MSG_GEN_CONTROL_GET_INFO
		uses	cx
		.enter
	;
	; copy the data into the buffer
	;
		segmov	ds, cs				; ds:si = source
		mov	si, offset LoopbackPrefCtrlInfo
		mov	es, cx
		mov	di, dx				; es:di = dest
		mov	cx, size GenControlBuildInfo
		rep	movsb
		
		.leave
		ret
LPCGenControlGetInfo	endm

LoopbackPrefCtrlInfo	GenControlBuildInfo <
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ;GCBI_flags
	0,					; GCBI_initFileKey
	0,					; GCBI_gcnList
	0,					; GCBI_gcnCount
	0,					; GCBI_notificationList
	0,					; GCBI_notificationCount
	0,					; GCBI_controllerName

	handle LoopbackPrefCtrlBox,		; GCBI_dupBlock
	LoopbackPrefCtrlChildList,		; GCBI_childList
	length LoopbackPrefCtrlChildList,	; GCBI_childCount
	LoopbackPrefCtrlFeaturesList,		; GCBI_featuresList
	length LoopbackPrefCtrlFeaturesList,	; GCBI_featuresCount
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

LoopbackCode ends

endif
