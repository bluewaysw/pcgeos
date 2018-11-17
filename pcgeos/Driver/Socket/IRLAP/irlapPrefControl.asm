COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		irlapPrefControl.asm

AUTHOR:		Steve Jang, Dec  8, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 8/94   	Initial revision


DESCRIPTION:
	Custom ui for IrLAP preference.

	$Id: irlapPrefControl.asm,v 1.1 97/04/18 11:57:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NO_PREFERENCES_APPLICATION

IrlapClassStructures	segment resource

IrlapPrefCtrlChildList GenControlChildInfo		\
	< offset IrlapPrefCtrlBox,
	  0,
 	  mask GCCF_IS_DIRECTLY_A_FEATURE or mask GCCF_ALWAYS_ADD>

IrlapPrefCtrlFeaturesList GenControlFeaturesInfo	\
	< offset IrlapPrefCtrlBox,
	  0,
	  1>

IrlapClassStructures	ends

IrlapCommonCode		segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGenControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns GenCtrl information for IrlapPreferenceControlClass

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= IrlapPreferenceControlClass object
		ds:di	= IrlapPreferenceControlClass instance data
		ds:bx	= IrlapPreferenceControlClass object
		es 	= segment of IrlapPreferenceControlClass
		ax	= message #
		cx:dx	= Buffer for GenControlInfo
RETURN:		GenControlDupInfo field filled in
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefGenControlGetInfo	method dynamic IrlapPreferenceControlClass, 
					MSG_GEN_CONTROL_GET_INFO
		uses	cx
		.enter
	;
	; copy the data into the buffer
	;
		segmov	ds, cs				; ds:si = source
		mov	si, offset IrlapPrefCtrlInfo
		mov	es, cx
		mov	di, dx				; es:di = dest
		mov	cx, size GenControlBuildInfo
		rep	movsb
		
		.leave
		ret
PrefGenControlGetInfo	endm

IrlapPrefCtrlInfo	GenControlBuildInfo <
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ;GCBI_flags
	0,					; GCBI_initFileKey
	0,					; GCBI_gcnList
	0,					; GCBI_gcnCount
	0,					; GCBI_notificationList
	0,					; GCBI_notificationCount
	0,					; GCBI_controllerName

	handle IrlapPrefCtrlBox,		; GCBI_dupBlock
	IrlapPrefCtrlChildList,		; GCBI_childList
	length IrlapPrefCtrlChildList,	; GCBI_childCount
	IrlapPrefCtrlFeaturesList,		; GCBI_featuresList
	length IrlapPrefCtrlFeaturesList,	; GCBI_featuresCount
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

IrlapCommonCode ends

endif	; !NO_PREFERENCES_APPLICATION
