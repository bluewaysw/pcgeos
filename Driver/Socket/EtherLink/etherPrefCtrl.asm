COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		etherPrefCtrl.asm

AUTHOR:		Todd Stumpf, June 28th, 1998

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	6/28/98   	Initial revision

DESCRIPTION:
	EtherPreferenceControlClass code.

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NO_PREFERENCES_APPLICATION
EtherClassStructures	segment resource

EtherPrefCtrlChildList	GenControlChildInfo	\
	< offset EtherPrefCtrlBox,
	  0,
 	  mask GCCF_IS_DIRECTLY_A_FEATURE or mask GCCF_ALWAYS_ADD>

EtherPrefCtrlFeaturesList GenControlFeaturesInfo	\
	< offset EtherPrefCtrlBox,
	  0,
	  1>

EtherClassStructures	ends

EtherCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPCGenControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns GenCtrl information for EtherPreferenceControlClass

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= EtherPreferenceControlClass object
		ds:di	= EtherPreferenceControlClass instance data
		ds:bx	= EtherPreferenceControlClass object
		es 	= segment of EtherPreferenceControlClass
		ax	= message #
		cx:dx	= Buffer for GenControlInfo
RETURN:		GenControlDupInfo field filled in
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	6/28/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPCGenControlGetInfo	method dynamic EtherPreferenceControlClass, 
					MSG_GEN_CONTROL_GET_INFO
		uses	cx
		.enter
	;
	; copy the data into the buffer
	;
		segmov	ds, cs				; ds:si = source
		mov	si, offset EtherPrefCtrlInfo
		mov	es, cx
		mov	di, dx				; es:di = dest
		mov	cx, size GenControlBuildInfo
		rep	movsb
		
		.leave
		ret
EPCGenControlGetInfo	endm

EtherPrefCtrlInfo	GenControlBuildInfo <
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ;GCBI_flags
	0,					; GCBI_initFileKey
	0,					; GCBI_gcnList
	0,					; GCBI_gcnCount
	0,					; GCBI_notificationList
	0,					; GCBI_notificationCount
	0,					; GCBI_controllerName

	handle EtherPrefCtrlBox,		; GCBI_dupBlock
	EtherPrefCtrlChildList,			; GCBI_childList
	length EtherPrefCtrlChildList,		; GCBI_childCount
	EtherPrefCtrlFeaturesList,		; GCBI_featuresList
	length EtherPrefCtrlFeaturesList,	; GCBI_featuresCount
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

EtherCode ends

endif
