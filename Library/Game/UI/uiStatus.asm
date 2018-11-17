COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiStatus.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

DESCRIPTION:
	Code for the title controller

	$Id: uiStatus.asm,v 1.1 97/04/04 18:04:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @----------------------------------------------------------------------

MESSAGE:	GameStatusControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GameStatusControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GameStatusControlClass

	ax - The message

	cx:dx - GenControlDupInfo structure to fill in

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
GameStatusControlGetInfo	method dynamic	GameStatusControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GSC_dupInfo
	GOTO	CopyDupInfoCommon
GameStatusControlGetInfo	endm


GSC_dupInfo	GenControlBuildInfo	<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST,	; GCBI_flags
	GSC_IniFileKey,			; GCBI_initFileKey
	GSC_gcnList,			; GCBI_gcnList
	length GSC_gcnList,		; GCBI_gcnCount
	GSC_notifyGroupList,		; GCBI_notificationList
	length GSC_notifyGroupList,	; GCBI_notificationCount
	GSCName,			; GCBI_controllerName

	handle GameStatusControlUI,		; GCBI_dupBlock
	GSC_childList,			; GCBI_childList
	length GSC_childList,		; GCBI_childCount
	GSC_featuresList,		; GCBI_featuresList
	length GSC_featuresList,	; GCBI_featuresCount
	GSC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0				; GCBI_toolFeatures 
	>

; Menu isn't used in GCM

GSC_DEFAULT_FEATURES equ mask GSCF_START or mask GSCF_ABORT or \
			mask GSCF_PAUSE or mask GSCF_CONTINUE

GSC_IniFileKey	char	"gameControl", 0

GSC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_GAME_STATUS_CHANGE>

GSC_notifyGroupList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GAME_STATUS_CHANGE>

;---

GSC_childList	GenControlChildInfo	\
	<offset StartTrigger, mask GSCF_START,1>,
	<offset AbortTrigger, mask GSCF_ABORT,1>,
	<offset	PauseTrigger, mask GSCF_PAUSE,1>,
	<offset ContinueTrigger, mask GSCF_CONTINUE,1>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GSC_featuresList	GenControlFeaturesInfo	\
	<offset ContinueTrigger, 0, 0>,
	<offset PauseTrigger, 0, 0>,
	<offset AbortTrigger, 0, 0>,
	<offset StartTrigger, 0, 0>


COMMENT @----------------------------------------------------------------------

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GameStatusControlClass

	ax - The message
	dx - NotificationStandardNotificationGroup
	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED: ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/8/92		Initial version  

------------------------------------------------------------------------------@
GameStatusControlUpdateUI	method GameStatusControlClass,
				MSG_GEN_CONTROL_UPDATE_UI


	; get notification data


	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax
	mov	al, es:[GSNB_status]
	call	MemUnlock

	mov	bx, ss:[bp].GCUUIP_childBlock

	; enable/disable triggers based on game status


	cmp	al, GS_PAUSED
	mov	si, offset ContinueTrigger
	call	EnableOrDisableOnZFlag

	cmp	al, GS_RUNNING
	mov	si, offset PauseTrigger
	call	EnableOrDisableOnZFlag

	cmp	al, GS_RUNNING
	mov	si, offset AbortTrigger
	call	EnableOrDisableOnZFlag

	.leave
	ret
GameStatusControlUpdateUI	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableOrDisableOnZFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If Z flag is set, enable, otherwise disable

CALLED BY:	GameStatusControlUpdateUI

PASS:		^lbx:si - object to send mesage to
		Z Flag - set = enable, clear = disable

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Hang on to the Z flag for a while	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableOrDisableOnZFlag	proc near	
	uses	ax,di
	.enter
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_ENABLED
	jz	callIt
	mov	ax, MSG_GEN_SET_NOT_ENABLED
callIt:
	clr	di
	call	ObjMessage
	.leave
	ret
EnableOrDisableOnZFlag	endp

