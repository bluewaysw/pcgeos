COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiPage.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenPageControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement GenPageControlClass

	$Id: uiPage.asm,v 1.1 97/04/07 11:47:06 newdeal Exp $

------------------------------------------------------------------------------@

;---------------------------------------------------

UserClassStructures	segment resource

	GenPageControlClass		;declare the class record

UserClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS	;++++++++++++++++++++++++++++++++++++++++++++++++++++

ControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenPageControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GenPageControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GenPageControlClass

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
GenPageControlGetInfo	method dynamic	GenPageControlClass,
					MSG_GEN_CONTROL_GET_INFO

		mov	si, offset GPC_dupInfo
		GOTO	CopyDupInfoCommon

GenPageControlGetInfo	endm

GPC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	GPC_IniFileKey,			; GCBI_initFileKey
	GPC_gcnList,			; GCBI_gcnList
	length GPC_gcnList,		; GCBI_gcnCount
	GPC_notifyTypeList,		; GCBI_notificationList
	length GPC_notifyTypeList,	; GCBI_notificationCount
	GPCName,			; GCBI_controllerName

	handle GenPageControlUI,	; GCBI_dupBlock
	GPC_childList,			; GCBI_childList
	length GPC_childList,		; GCBI_childCount
	GPC_featuresList,		; GCBI_featuresList
	length GPC_featuresList,	; GCBI_featuresCount
	GPC_DEFAULT_FEATURES,		; GCBI_features

	handle GenPageControlToolboxUI,	; GCBI_toolBlock
	GPC_toolList,			; GCBI_toolList
	length GPC_toolList,		; GCBI_toolCount
	GPC_toolFeaturesList,		; GCBI_toolFeaturesList
	length GPC_toolFeaturesList,	; GCBI_toolFeaturesCount
	GPC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	segment	resource
endif

GPC_IniFileKey	char	"pageControl", 0

GPC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_PAGE_STATE_CHANGE>

GPC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_PAGE_STATE_CHANGE>

;---

GPC_childList	GenControlChildInfo	\
	<offset GotoPageDialog, mask GPCF_GOTO_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset NextPageTrigger, mask GPCF_NEXT_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PreviousPageTrigger, mask GPCF_PREVIOUS_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset FirstPageTrigger, mask GPCF_FIRST_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset LastPageTrigger, mask GPCF_LAST_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GPC_featuresList	GenControlFeaturesInfo	\
	<offset PreviousPageTrigger, PreviousPageName>,
	<offset NextPageTrigger, NextPageName>,
	<offset GotoPageDialog, GotoPageName>,
	<offset LastPageTrigger, LastPageName>,
	<offset FirstPageTrigger, FirstPageName>

;---

GPC_toolList	GenControlChildInfo	\
	<offset FirstPageToolTrigger, mask GPCTF_FIRST_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PreviousPageToolTrigger, mask GPCTF_PREVIOUS_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GotoPageToolRange, mask GPCTF_GOTO_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset NextPageToolTrigger, mask GPCTF_NEXT_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset LastPageToolTrigger, mask GPCTF_LAST_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GPC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset NextPageToolTrigger, NextPageName>,
	<offset GotoPageToolRange, GotoPageName>,
	<offset PreviousPageToolTrigger, PreviousPageName>,
	<offset LastPageToolTrigger, LastPageName>,
	<offset FirstPageToolTrigger, FirstPageName>

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenPageControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GenPageControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of GenPageControlClass

	ax - The message

	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91	Initial version
	sean	3/15/99		Disabled the "Go to Page" dialog if there
				is only 1 page for the document.

------------------------------------------------------------------------------@

DISABLE_PAGE_TOOLS_TO_SHOW_STATE	=	TRUE



GenPageControlUpdateUI	method dynamic GenPageControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	; save the data in vardata

	mov	ax, TEMP_GEN_PAGE_CONTROL_PAGE_STATE
	mov	cx, size NotifyPageStateChange
	call	ObjVarAddData
	segxchg	ds, es
	clr	si					;ds:si = source
	mov	di, bx					;es:di = dest
	.Assert (((size NotifyPageStateChange) and 1) eq 0)
	shr	cx, 1					;copy words
	rep	movsw
	segxchg	ds, es

	; update the next page trigger

	clr	cx
	mov	ax, es:[NPSC_currentPage]
	cmp	ax, es:[NPSC_lastPage]
	jz	10$
	inc	cx
10$:

if DISABLE_PAGE_TOOLS_TO_SHOW_STATE
	mov	dx, mask GPCTF_NEXT_PAGE
	mov	di, offset NextPageToolTrigger
else
	clr	dx
endif
	mov	ax, mask GPCF_NEXT_PAGE
	mov	si, offset NextPageTrigger
	mov	ch, VUM_DELAYED_VIA_UI_QUEUE
	call	GEC_EnableOrDisable

	; last page trigger follows next page trigger state

if DISABLE_PAGE_TOOLS_TO_SHOW_STATE
	mov	dx, mask GPCTF_LAST_PAGE
	mov	di, offset LastPageToolTrigger
else
	clr	dx
endif
	mov	ax, mask GPCF_LAST_PAGE
	mov	si, offset LastPageTrigger
	mov	ch, VUM_DELAYED_VIA_UI_QUEUE
	call	GEC_EnableOrDisable

	; update the previous page trigger

	clr	cx
	mov	ax, es:[NPSC_currentPage]
	cmp	ax, es:[NPSC_firstPage]
	jz	20$
	inc	cx
20$:

if DISABLE_PAGE_TOOLS_TO_SHOW_STATE
	mov	dx, mask GPCTF_PREVIOUS_PAGE
	mov	di, offset PreviousPageToolTrigger
else
	clr	dx
endif
	mov	ax, mask GPCF_PREVIOUS_PAGE
	mov	si, offset PreviousPageTrigger
	mov	ch, VUM_DELAYED_VIA_UI_QUEUE
	call	GEC_EnableOrDisable

	; first page trigger follows previous page trigger state

if DISABLE_PAGE_TOOLS_TO_SHOW_STATE
	mov	dx, mask GPCTF_FIRST_PAGE
	mov	di, offset FirstPageToolTrigger
else
	clr	dx
endif
	mov	ax, mask GPCF_FIRST_PAGE
	mov	si, offset FirstPageTrigger
	mov	ch, VUM_DELAYED_VIA_UI_QUEUE
	call	GEC_EnableOrDisable

	; If there is only 1 page for this document, let's disable the
	; "Go to Page" dialog.  Sean 3/15/99.
	;
	mov	cx, es:[NPSC_lastPage]		; cx = number of pages
	dec	cx				; 0 = only 1 page -> disable
	clr	dx				; Don't test tool
	mov	ax, mask GPCF_GOTO_PAGE
	mov	si, offset GotoPageDialog
	mov	ch, VUM_DELAYED_VIA_UI_QUEUE
	call	GEC_EnableOrDisable
		
	; update the goto page dialog box

	test	ss:[bp].GCUUIP_features, mask GPCF_GOTO_PAGE
	jz	noGotoPage
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset GotoPageRange
	call	UpdateRange
noGotoPage:

	test	ss:[bp].GCUUIP_toolboxFeatures, mask GPCTF_GOTO_PAGE
	jz	noGotoTool
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, offset GotoPageToolRange
	call	UpdateRange
noGotoTool:

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

	ret

GenPageControlUpdateUI	endm

;---

UpdateRange	proc	near
	uses	bp
	.enter

	mov	dx, es:[NPSC_firstPage]
	clr	cx
	mov	ax, MSG_GEN_VALUE_SET_MINIMUM
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	dx, es:[NPSC_lastPage]
	clr	cx
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx, es:[NPSC_currentPage]
	clr	bp				;bp <- not indeterminate
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

UpdateRange	endp

ControlCommon ends

;---

ControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenPageControlNextPage -- MSG_PC_NEXT_PAGE
						for GenPageControlClass

DESCRIPTION:	Handle user request to go to the next page

PASS:
	*ds:si - instance data
	es - segment of GenPageControlClass

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
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
GenPageControlNextPage	method dynamic	GenPageControlClass, MSG_PC_NEXT_PAGE
	mov	ax, MSG_META_PAGED_OBJECT_NEXT_PAGE
	call	OutputNoClass
	ret

GenPageControlNextPage	endm

GenPageControlPreviousPage	method dynamic	GenPageControlClass,
						MSG_PC_PREVIOUS_PAGE
	mov	ax, MSG_META_PAGED_OBJECT_PREVIOUS_PAGE
	call	OutputNoClass
	ret

GenPageControlPreviousPage	endm

GenPageControlGotoPage	method dynamic	GenPageControlClass,
						MSG_PC_GOTO_PAGE
	mov	cx, dx
	mov	ax, MSG_META_PAGED_OBJECT_GOTO_PAGE
	call	OutputNoClass
	ret

GenPageControlGotoPage	endm

GenPageControlFirstPage	method dynamic	GenPageControlClass,
						MSG_PC_FIRST_PAGE
	mov	di, offset NPSC_firstPage
	GOTO FirstLastPageCommon

GenPageControlFirstPage	endm

GenPageControlLastPage	method dynamic	GenPageControlClass,
						MSG_PC_LAST_PAGE
	mov	di, offset NPSC_lastPage
	FALL_THRU FirstLastPageCommon

GenPageControlLastPage	endm

FirstLastPageCommon	proc far
	mov	ax, TEMP_GEN_PAGE_CONTROL_PAGE_STATE
	call	ObjVarFindData
	jnc	notFound

	mov	cx, ds:[bx][di]
	mov	ax, MSG_META_PAGED_OBJECT_GOTO_PAGE
	call	OutputNoClass
notFound:
	ret
FirstLastPageCommon	endp

ControlCode ends

endif			; NO_CONTROLLERS ++++++++++++++++++++++++++++++++++++

