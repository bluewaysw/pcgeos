COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiRulerShowControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	RulerShowControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement RulerShowControlClass

	$Id: uiRulerShow.asm,v 1.1 97/04/07 10:42:35 newdeal Exp $

------------------------------------------------------------------------------@

;---------------------------------------------------

RulerClassStructures	segment resource

	RulerShowControlClass		;declare the class record

RulerClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS	;++++++++++++++++++++++++++++++++++++++++++++++++++++

RulerUICommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerShowControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for RulerShowControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of RulerShowControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

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
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
RulerShowControlGetInfo	method dynamic	RulerShowControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset RSCC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret

RulerShowControlGetInfo	endm

RSCC_dupInfo	GenControlBuildInfo	<
	mask GCBF_IS_ON_ACTIVE_LIST,	; GCBI_flags
	RSCC_IniFileKey,		; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	RSCCName,			; GCBI_controllerName

	handle RulerShowControlUI,	; GCBI_dupBlock
	RSCC_childList,			; GCBI_childList
	length RSCC_childList,		; GCBI_childCount
	RSCC_featuresList,		; GCBI_featuresList
	length RSCC_featuresList,	; GCBI_featuresCount
	RSCC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	RSCC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	RSCC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
RulerControlInfoXIP	segment resource
endif

RSCC_helpContext	char	"dbRulerShow", 0

RSCC_IniFileKey	char	"rulerOptions", 0

;---

RSCC_childList	GenControlChildInfo	\
	<offset RulerAttrList, mask RSCCF_SHOW_VERTICAL or \
				mask RSCCF_SHOW_HORIZONTAL or \
				mask RSCCF_SHOW_RULERS, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

RSCC_featuresList	GenControlFeaturesInfo	\
	<offset ShowBothEntry, BothName, 0>,
	<offset ShowHorizontalEntry, HorizontalName, 0>,
	<offset ShowVerticalEntry, VerticalName, 0>

if FULL_EXECUTE_IN_PLACE
RulerControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerShowControlLoadOptions -- MSG_META_LOAD_OPTIONS for
			RulerShowControlClass

DESCRIPTION:	Load options from .ini file

PASS:
	*ds:si - instance data
	es - segment of RulerShowControlClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 3/92		Initial version

------------------------------------------------------------------------------@
RulerShowControlLoadOptions	method dynamic	RulerShowControlClass,
							MSG_META_LOAD_OPTIONS

	sub	sp, INI_CATEGORY_BUFFER_SIZE
	mov	bp, sp

	push	ax
	push	ds:[LMBH_handle], es, si
	call	PrepForOptions
	call	InitFileReadInteger
	pop	bx, es, si
	call	MemDerefDS
	jc	noData
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].RSCI_attrs, ax
noData:
	pop	ax

	add	sp, INI_CATEGORY_BUFFER_SIZE

	mov	di, offset RulerShowControlClass
	GOTO	ObjCallSuperNoLock

RulerShowControlLoadOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerShowControlSaveOptions -- MSG_META_SAVE_OPTIONS for
			RulerShowControlClass

DESCRIPTION:	Save options from .ini file

PASS:
	*ds:si - instance data
	es - segment of RulerShowControlClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 3/92		Initial version

------------------------------------------------------------------------------@
RulerShowControlSaveOptions	method dynamic	RulerShowControlClass,
							MSG_META_SAVE_OPTIONS

	sub	sp, INI_CATEGORY_BUFFER_SIZE
	mov	bp, sp

	push	ax, ds:[LMBH_handle], es, si
	push	ds:[di].RSCI_attrs
	call	PrepForOptions
	pop	bp
	call	InitFileWriteInteger
	pop	ax, bx, es, si
	call	MemDerefDS

	add	sp, INI_CATEGORY_BUFFER_SIZE

	mov	di, offset RulerShowControlClass
	GOTO	ObjCallSuperNoLock

RulerShowControlSaveOptions	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	PrepForOptions

DESCRIPTION:	Prepare for load/save options

CALLED BY:	INTERNAL

PASS:	*ds:si - object
	ss:bp - buffer for category

RETURN:
	category - loaded
	ds:si - pointing at category
	cx:dx - pointing at key

DESTROYED:
	ax, bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/92		Initial version

------------------------------------------------------------------------------@
PrepForOptions	proc	near
	mov	cx, ss
	mov	dx, bp
	call	UserGetInitFileCategory
	mov	ds, cx
	mov	si, dx

	mov	cx, cs
	mov	dx, offset rulerShowControlKey	;cx:dx = key
	ret

PrepForOptions	endp

rulerShowControlKey	char	"rulerShowAttrs", 0

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerShowControlAttach -- MSG_META_ATTACH
						for RulerShowControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of RulerShowControlClass

	ax - The message

	cx, dx, bp - attach data

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/92		Initial version

------------------------------------------------------------------------------@
RulerShowControlAttach	method dynamic	RulerShowControlClass, MSG_META_ATTACH

	mov	di, offset RulerShowControlClass
	call	ObjCallSuperNoLock

	call	UpdateAllRulers

	ret

RulerShowControlAttach	endm

;---

UpdateAllRulers	proc	far
	class	RulerShowControlClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].RSCI_attrs
	mov	ax, ds:[di].RSCI_message
	pushdw	ds:[di].RSCI_gcnList

	push	si
	clrdw	bxsi
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	popdw	cxdx

	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, dx
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, cx
	mov	ss:[bp].GCNLMP_block, 0
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS

	clr	bx
	call	GeodeGetAppObject
	mov	dx, size GCNListMessageParams
	mov	ax, MSG_META_GCN_LIST_SEND
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GCNListMessageParams

	ret

UpdateAllRulers	endp

RulerUICommon ends

;---

RulerUICode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerShowControlSetState -- MSG_RSCC_CHANGE_STATE
						for RulerShowControlClass

DESCRIPTION:	Handle change in the ruler state

PASS:
	*ds:si - instance data
	es - segment of RulerShowControlClass

	ax - The message

	cx - selected booleans
	bp - changed booleans

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version
	sean	3/15/99		Only change options if we're changing state is
				different than current state.

------------------------------------------------------------------------------@
RulerShowControlSetState	method dynamic RulerShowControlClass,
						MSG_RSCC_CHANGE_STATE

	mov	ds:[di].RSCI_attrs, cx
	call	UpdateAllRulers

	; Don't call "Options Changed" if our state is set because we're
	; attaching.  Sean 3/15/99.
	;
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	UserCallApplication		; ax = ApplicationStates	
	test	ax, mask AS_ATTACHING		; Attaching ?
	jnz	finished			; yes--don't mark options changed
		
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	UserCallApplication

finished:
	ret

RulerShowControlSetState	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerShowControlTweakDuplicatedUI

DESCRIPTION:	Tweak the UI for the text ruler control

PASS:
	*ds:si - instance data
	es - segment of RulerShowControlClass

	ax - The message
	cx - block
	dx - features

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/21/92		Initial version
	Doug	1/93		Changed to use TWEAK message

------------------------------------------------------------------------------@
RulerShowControlTweakDuplicatedUI	method dynamic	RulerShowControlClass,
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI

	test	dx, mask RSCCF_SHOW_VERTICAL or \
					mask RSCCF_SHOW_HORIZONTAL or \
					mask RSCCF_SHOW_RULERS
	jz	done
	mov	bx, cx
	mov	cx, ds:[di].RSCI_attrs
	mov	si, offset RulerAttrList
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage
done:
	ret

RulerShowControlTweakDuplicatedUI	endm

RulerUICode ends

endif			; NO_CONTROLLERS ++++++++++++++++++++++++++++++++++++

