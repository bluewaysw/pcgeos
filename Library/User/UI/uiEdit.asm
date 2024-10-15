COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiEdit.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenEditControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement GenEditControlClass

	$Id: uiEdit.asm,v 1.3 98/05/08 09:48:04 gene Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

UserClassStructures	segment resource

	GenEditControlClass		;declare the class record

UserClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS	;++++++++++++++++++++++++++++++++++++++++++++++++++++

ControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenEditControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GenEditControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GenEditControlClass

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
GenEditControlGetInfo	method dynamic	GenEditControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GEC_dupInfo
	FALL_THRU	CopyDupInfoCommon
GenEditControlGetInfo	endm

; Do *NOT* call this routine from another code resource,
; as you will not be happy with the results!
;
CopyDupInfoCommon	proc	far
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs

CheckHack <(((size GenControlBuildInfo)/2)*2) eq (size GenControlBuildInfo)>
	mov	cx, (size GenControlBuildInfo) / 2
	rep movsw
	ret
CopyDupInfoCommon	endp

GEC_dupInfo	GenControlBuildInfo	<
					; GCBI_flags
	mask GCBF_ALWAYS_UPDATE or mask GCBF_CUSTOM_ENABLE_DISABLE,
	GEC_IniFileKey,			; GCBI_initFileKey
	GEC_gcnList,			; GCBI_gcnList
	length GEC_gcnList,		; GCBI_gcnCount
	GEC_notifyTypeList,		; GCBI_notificationList
	length GEC_notifyTypeList,	; GCBI_notificationCount
	GECName,			; GCBI_controllerName

	handle GenEditControlUI,	; GCBI_dupBlock
	GEC_childList,			; GCBI_childList
	length GEC_childList,		; GCBI_childCount
	GEC_featuresList,		; GCBI_featuresList
	length GEC_featuresList,	; GCBI_featuresCount
	GEC_DEFAULT_FEATURES,		; GCBI_features

	handle GenEditControlToolboxUI,	; GCBI_toolBlock
	GEC_toolList,			; GCBI_toolList
	length GEC_toolList,		; GCBI_toolCount
	GEC_toolFeaturesList,		; GCBI_toolFeaturesList
	length GEC_toolFeaturesList,	; GCBI_toolFeaturesCount
	GEC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	segment	resource
endif

GEC_IniFileKey	char	"editControl", 0

GEC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE>, \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_EDIT_CONTROL_NOTIFY_UNDO_STATE_CHANGE>

GEC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SELECT_STATE_CHANGE>, \
	<MANUFACTURER_ID_GEOWORKS, GWNT_UNDO_STATE_CHANGE>

;---

GEC_childList	GenControlChildInfo	\
	<offset FirstEditGroup, mask GECF_UNDO or \
				 mask GECF_CUT or \
				 mask GECF_COPY or \
				 mask GECF_PASTE or \
				 mask GECF_DELETE, 0>,
	<offset SelectAllGroup, mask GECF_SELECT_ALL,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset CharMapGroup, mask GECF_CHAR_MAP,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ClipArtGroup, mask GECF_CLIP_ART,
					mask GCCF_IS_DIRECTLY_A_FEATURE>


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GEC_featuresList	GenControlFeaturesInfo	\
	<offset DeleteTrigger, DeleteName>,
	<offset SelectAllGroup, SelectAllName>,
	<offset PasteTrigger, PasteName>,
	<offset CopyTrigger, CopyName>,
	<offset CutTrigger, CutName>,
	<offset UndoTrigger, UndoName>,
	<offset CharMapTrigger, CharMapName>,
	<offset ClipArtTrigger, ClipArtName>

;---

GEC_toolList	GenControlChildInfo	\
	<offset UndoToolTrigger, mask GECTF_UNDO,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset CutToolTrigger, mask GECTF_CUT,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset CopyToolTrigger, mask GECTF_COPY,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PasteToolTrigger, mask GECTF_PASTE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SelectAllToolTrigger, mask GECTF_SELECT_ALL,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DeleteToolTrigger, mask GECTF_DELETE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GEC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset DeleteToolTrigger, DeleteName>,
	<offset SelectAllToolTrigger, SelectAllName>,
	<offset PasteToolTrigger, PasteName>,
	<offset CopyToolTrigger, CopyName>,
	<offset CutToolTrigger, CutName>,
	<offset UndoToolTrigger, UndoName>

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenEditControlGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI for
			GenEditControlClass

DESCRIPTION:	Before building our UI, add ourselves to clipboard notification
		list so that we'll be able to set the state of that UI
		correctly.

PASS:
	*ds:si - instance data
	es - segment of GenEditControlClass

	ax - The message

	cx - ?
	dx - ?
	bp - ?

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/15/92		Initial version

------------------------------------------------------------------------------@
GenEditControlGenerateUI	method dynamic	GenEditControlClass,
						MSG_GEN_CONTROL_GENERATE_UI,
					MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI
	push	ax, cx, dx, bp
	mov	ax, TEMP_CLIPBOARD_NOTIFICATION_LIST_COUNT
	call	ObjVarFindData
	jc	found
	mov	cx, size word
	call	ObjVarAddData
	mov	{word} ds:[bx], 0
found:
	inc	{word} ds:[bx]
	cmp	{word} ds:[bx], 1
	jne	noAdd

;	Add the item to the notification list if the ref count is 1

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ClipboardAddToNotificationList
	;
	; if we add ourselves to the clipboard notification list, make sure
	; that we are on the active list, as that is the only way that we'll
	; get removed from the clipboard notification list.
	;
	sub	sp, size GCNListParams
	mov	bp, sp
	movdw	ss:[bp].GCNLP_optr, cxdx
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST or \
						mask GCNLTF_SAVE_TO_STATE
	mov	dx, size GCNListParams
	mov	ax, MSG_META_GCN_LIST_ADD
	call	GenCallApplication
	add	sp, size GCNListParams
noAdd:
	pop	ax, cx, dx, bp
	;
	; do the superclass thing
	;
	mov	di, offset GenEditControlClass
	call	ObjCallSuperNoLock
	;
	; if desired, set up the alternate shortcuts
	;
	call	SetupAlternateShortcuts
	ret
GenEditControlGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupAlternateShortcuts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up the alternate keyboard shortcuts if desired

CALLED BY:	GenEditControlGenerateUI()

PASS:		*ds:si - GenEditControl object
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/1/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

objList lptr \
	UndoTrigger,
	CutTrigger,
	CopyTrigger,
	PasteTrigger,
	SelectAllTrigger

idata	segment
	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
mainShortcutList KeyboardShortcut \
	<0, 0, 1, 0, 0, C_SMALL_Z>,		;<z> = undo
	<0, 0, 1, 0, 0, C_SMALL_X>,		;<x> = cut
	<0, 0, 1, 0, 0, C_SMALL_C>,		;<c> = copy
	<0, 0, 1, 0, 0, C_SMALL_V>,		;<p> = paste
	<0, 0, 1, 0, 0, C_SMALL_A>		;<a> = select all
idata	ends

idata	segment
altShortcutList KeyboardShortcut \
	<1, 1, 0, 0, CS_CONTROL and 0xf, VC_BACKSPACE>,	;<alt><bkspace> = undo
	<1, 0, 0, 1, CS_CONTROL and 0xf, VC_DEL>,	;<shift><delete> = cut
	<1, 0, 1, 0, CS_CONTROL and 0xf, VC_INS>,	;<ctrl><insert> = copy
	<1, 0, 0, 1, CS_CONTROL and 0xf, VC_INS>,	;<shift><insert> =paste
	<0, 0, 1, 0, 0, C_SLASH>			;<ctrl>-/ = select all
idata	ends

featureList word \
	mask GECF_UNDO,
	mask GECF_CUT,
	mask GECF_COPY,
	mask GECF_PASTE,
	mask GECF_SELECT_ALL


CheckHack <length mainShortcutList eq length objList>
CheckHack <length altShortcutList eq length objList>
CheckHack <length featureList eq length objList>


uiFeaturesCat		char "uiFeatures",0
useAltEditKeys		char "altEditKeys",0

SetupAlternateShortcuts	proc	near
		uses	ax, bx, cx, dx, si, di, bp, es
		.enter
		segmov	es, dgroup, cx
	;
	; See if we want the alternates
	;
		push	ds, si
		segmov	ds, cs, cx
		mov	si, offset uiFeaturesCat
		mov	dx, offset useAltEditKeys
		call	InitFileReadBoolean
		pop	ds, si
		jc	noAlt				;branch if not there
		tst	ax
		jz	noAlt				;branch if false

	;
	;
	; Loop through the list and change the shortcuts
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData
		mov	ax, ds:[bx].TGCI_features	;ax <- features
		mov	bx, ds:[bx].TGCI_childBlock	;bx <- child block
		mov	cx, length mainShortcutList	;cx <- # shortcuts
		clr	di				;di <- table index
childLoop:
		test	ax, cs:featureList[di]		;feature exists?
		jz	skipObj				;branch if no feature
		push	ax, cx, di
		mov	si, cs:objList[di]		;^bx:si <- OD
		mov	cx, es:mainShortcutList[di]	;cx <- new shortcut
		push	es:altShortcutList[di]
		mov	di, mask MF_FIXUP_DS
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_SET_KBD_ACCELERATOR
		call	ObjMessage
		pop	dx
		tst	dx
		jz	noExtra
		call	ObjSwapLock
		push	bx
		mov	ax, ATTR_GEN_EXTRA_KBD_ACCELERATORS
		mov	cx, size KeyboardShortcut
		call	ObjVarAddData
		mov	ds:[bx], dx
		pop	bx
		call	ObjSwapUnlock
noExtra:
		pop	ax, cx, di
skipObj:
		add	di, (size lptr)
		loop	childLoop
noAlt:
		.leave
		ret
SetupAlternateShortcuts	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenEditControlAddAppUI -- MSG_GEN_CONTROL_ADD_APP_UI
						for GenEditControlClass

DESCRIPTION:	Add application UI

PASS:
	*ds:si - instance data
	es - segment of GenEditControlClass

	ax - The message

	cx:dx - object

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/24/92		Initial version

------------------------------------------------------------------------------@
GenEditControlAddAppUI	method dynamic	GenEditControlClass,
						MSG_GEN_CONTROL_ADD_APP_UI

	mov	bp, 1
	mov	ax, MSG_GEN_ADD_CHILD
	GOTO	ObjCallInstanceNoLock

GenEditControlAddAppUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenEditControlNotifyNormalTransferItemChanged --
		MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
							for GenEditControlClass

DESCRIPTION:	Cause target to update transfer stuff

PASS:
	*ds:si - instance data
	es - segment of GenEditControlClass

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
	Tony	12/10/91		Initial version

------------------------------------------------------------------------------@
GenEditControlNotifyNormalTransferItemChanged	method dynamic \
					GenEditControlClass,
			MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

	mov	ax, MSG_META_UI_FORCE_CONTROLLER_UPDATE
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_SELECT_STATE_CHANGE
	GOTO	OutputNoClass

GenEditControlNotifyNormalTransferItemChanged	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenEditControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GenEditControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of GenEditControlClass

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
	Tony	11/12/91		Initial version

------------------------------------------------------------------------------@
GenEditControlUpdateUI	method dynamic GenEditControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	tst	bx
	jnz	lockDataBlock
	segmov	es, cs
	mov	bx, offset nullNotification
	jmp	noLock
lockDataBlock:
	call	MemLock
	mov	es, ax
	clr	bx
noLock:
	cmp	ss:[bp].GCUUIP_changeType, GWNT_UNDO_STATE_CHANGE
	jz	doUndoChange


	; update the copy trigger

EC <	cmp	es:[bx].NSSC_selectionType, SelectionDataType		>
EC <	ERROR_AE	BAD_SELECTION_TYPE				>
	mov	ax, mask GECF_COPY
	mov	dx, mask GECTF_COPY
	mov	cl, es:[bx].NSSC_clipboardableSelection
	mov	ch, VUM_NOW
	mov	si, offset CopyTrigger
	mov	di, offset CopyToolTrigger
	call	GEC_EnableOrDisable

	; update the cut trigger

	mov	ax, mask GECF_CUT
	mov	dx, mask GECTF_CUT
	and	cl, es:[bx].NSSC_deleteableSelection
	mov	si, offset CutTrigger
	mov	di, offset CutToolTrigger
	call	GEC_EnableOrDisable

	; update the paste trigger

	mov	ax, mask GECF_PASTE
	mov	dx, mask GECTF_PASTE
	mov	cl, es:[bx].NSSC_pasteable
	mov	si, offset PasteTrigger
	mov	di, offset PasteToolTrigger
	call	GEC_EnableOrDisable

	; update the delete trigger

	mov	ax, mask GECF_DELETE
	mov	dx, mask GECTF_DELETE
	mov	cl, es:[bx].NSSC_deleteableSelection
	mov	si, offset DeleteTrigger
	mov	di, offset DeleteToolTrigger
	call	GEC_EnableOrDisable

	; update the select all trigger

	mov	ax, mask GECF_SELECT_ALL
	mov	dx, mask GECTF_SELECT_ALL
	mov	cl, es:[bx].NSSC_selectAllAvailable
	mov	si, offset SelectAllTrigger
	mov	di, offset SelectAllToolTrigger
	call	GEC_EnableOrDisable

exit:

	mov	bx, ss:[bp].GCUUIP_dataBlock
	tst	bx
	jz	noUnlock
	call	MemUnlock
noUnlock:
	ret

doUndoChange:
	; update the undo trigger

	push	si
	mov	ax, mask GECF_UNDO
	mov	dx, mask GECTF_UNDO
	mov	cx, es:[bx].NUSC_undoTitle.handle
	or	cl, ch
	mov	ch, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset UndoTrigger
	mov	di, offset UndoToolTrigger
	call	GEC_EnableOrDisable
	pop	si

	; update the moniker for the undo trigger (if needed)

	test	ss:[bp].GCUUIP_features, mask GECF_UNDO
	jz	exit

	mov	di, bx				;ES:DI <- NotifyUndoStateChange
	mov	ax, TEMP_UNDO_DESCRIPTION	;If there was already a 
	call	ObjVarFindData			; description, branch.
	jc	descFound

	; set undo trigger to passed string

	mov	ax, TEMP_UNDO_DESCRIPTION
	mov	cx, size NotifyUndoStateChange
	call	ObjVarAddData			;ds:bx = data
setDesc:
	movdw	ds:[bx].NUSC_undoTitle, es:[di].NUSC_undoTitle, ax
	mov	al, es:[di].NUSC_undoType
	mov	ds:[bx].NUSC_undoType, al

	; set the moniker

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset UndoTrigger
	call	GEC_SetUndoMoniker
	jmp	exit

	; found previous string -- compare them

descFound:

;	If this is now a redo, branch

	mov	al, es:[di].NUSC_undoType
	cmp	al, ds:[bx].NUSC_undoType
	jnz	setDesc

	cmpdw	es:[di].NUSC_undoTitle, ds:[bx].NUSC_undoTitle, ax
	jz	exit

	tst	es:[di].NUSC_undoTitle.handle	;New moniker is null, but old
	jz	setDesc				; is non-null, branch.

	tst	ds:[bx].NUSC_undoTitle.handle
					;If old moniker is null, but new is 
	jz	setDesc			; non-null, branch to set the
					; moniker
	
;	We have two non-null undo monikers - compare them.

	call	CompareUndoStrings	;If setting it to the same string,
	jnz	setDesc			; branch to exit.
	jmp	exit
GenEditControlUpdateUI	endm

nullNotification	NotifySelectStateChange	<0,0,0,0,0>

.assert size NotifyUndoStateChange le size NotifySelectStateChange
;---

	; ax = bit to test to normal
	; dx = bit to test for tool
	; cl = non-zero to enable, 0 to disable
	; ch = VisUpdateMode
	; si = offset for normal obj
	; di = offset for tool obj
	; ss:bp = GenControlUpdateUIParams

GEC_EnableOrDisable	proc	near		uses	bx, cx
	.enter
	test	ax, ss:[bp].GCUUIP_features
	jz	noNormal
	mov	bx, ss:[bp].GCUUIP_childBlock
	call	GEC_EnableOrDisableLow
noNormal:
	test	dx, ss:[bp].GCUUIP_toolboxFeatures
	jz	noToolBox
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, di
	call	GEC_EnableOrDisableLow
noToolBox:
	.leave
	ret

GEC_EnableOrDisable	endp

;---

	;bx:si - obj
	;cl - state
	;ch - VisUpdateMode

GEC_EnableOrDisableLow	proc	near	uses dx, di
	.enter

	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, ch
	tst	cl
	jnz	pasteCommon
	mov	ax, MSG_GEN_SET_NOT_ENABLED
pasteCommon:
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

GEC_EnableOrDisableLow	endp

;---

OutputNoClass	proc	far
	clr	bx			;any class -- this is a meta message
	clr	di
	call	GenControlOutputActionRegs
	ret

OutputNoClass	endp

ControlCommon ends

;---

ControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenEditControlDestroyUI -- MSG_GEN_CONTROL_DESTROY_UI for
			GenEditControlClass

DESCRIPTION:	Remove ourselves from clipboard notification list

PASS:
	*ds:si - instance data
	es - segment of GenEditControlClass

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
	brianc	7/15/92		Initial version

------------------------------------------------------------------------------@
GenEditControlDestroyUI	method dynamic	GenEditControlClass,
					MSG_GEN_CONTROL_DESTROY_UI,
					MSG_GEN_CONTROL_DESTROY_TOOLBOX_UI,
					MSG_META_DETACH

	push	ax
	mov	di, offset GenEditControlClass
	call	ObjCallSuperNoLock
	pop	ax
	cmp	ax, MSG_META_DETACH
	jz	forceRemove

;	Only remove the object from the notification list when the ref count
;	is zero

	mov	ax, TEMP_CLIPBOARD_NOTIFICATION_LIST_COUNT
	call	ObjVarFindData
EC <	ERROR_NC	GEN_CONTROL_INTERNAL_ERROR			>
	dec	{word} ds:[bx]
EC <	ERROR_S		GEN_CONTROL_INTERNAL_ERROR			>
	jnz	noRemove
forceRemove:
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ClipboardRemoveFromNotificationList
noRemove:	
	ret

GenEditControlDestroyUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenEditControlClipboardUndo -- MSG_UNDO for GenEditControlClass

DESCRIPTION:	Handle "undo" (and others)

PASS:
	*ds:si - instance data
	es - segment of GenEditControlClass

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
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
GenEditControlClipboardUndo	method GenEditControlClass,
						MSG_META_UNDO
	mov	ax, MSG_GEN_PROCESS_UNDO_PLAYBACK_CHAIN
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage
GenEditControlClipboardUndo	endm

;---

GenEditControlClipboardCut	method	GenEditControlClass,
					MSG_META_CLIPBOARD_CUT,
					MSG_META_CLIPBOARD_COPY,
					MSG_META_CLIPBOARD_PASTE

EC <	mov	cx, 0xcccc						>
EC <	mov	dx, 0xcccc						>
EC <	mov	bp, 0xcccc						>

	push	ax
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication
	pop	ax

	call	OutputNoClass

	push	si
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	pop	si
	clr	dx
	mov	ax, MSG_META_DISPATCH_EVENT
	call	OutputNoClass
	ret

GenEditControlClipboardCut	endm

;---

GenEditControlClipboardSelectAll	method	GenEditControlClass,
					MSG_META_SELECT_ALL,
					MSG_META_DELETE

EC <	mov	cx, 0xcccc						>
EC <	mov	dx, 0xcccc						>
EC <	mov	bp, 0xcccc						>

	call	OutputNoClass
	ret

GenEditControlClipboardSelectAll	endm

;---

serverAppToken	GeodeToken	<"Scrp",MANUFACTURER_ID_GEOWORKS>

GenEditControlClipArt		method	GenEditControlClass,
					MSG_GEC_LAUNCH_CLIP_ART

	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	mov	cx, 0xcccc						>
EC <	mov	dx, 0xcccc						>
EC <	mov	bp, 0xcccc						>

	;
	; Create a launch block to pass to IACPConnect
	;
	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock ; dx = handle to AppLaunchBlock
	;
	; Clear launch flags 
	;
	mov	bx, dx			; bx <- handle of AppLaunchBlock
	call	MemLock			; ax = AppLaunchBlock segment
	mov	es, ax
	mov	es:[ALB_launchFlags], mask ALF_OVERRIDE_MULTIPLE_INSTANCE
	push	bx
	lea	di, es:[ALB_dataFile]
	mov	{byte}es:[di], 0              ; leave the first byte empty
	inc	di
	mov	ax, GGIT_PERM_NAME_AND_EXT
	clr	bx
	call	GeodeGetInfo		; es:di = GeodeToken
	pop	bx
	call	MemUnlock
	;
	; Connect to the desired server
	;
	mov	di, offset cs:[serverAppToken]
	segmov	es, cs, dx			; es:di points to GeodeToken
	mov	ax, mask IACPCF_FIRST_ONLY	; ax <- connect flag
	call	IACPConnect			; bp = IACPConnection
	jc	done
	;
	; Shut down connection
	;
	clr	cx, dx
	call	IACPShutdown

done:
	.leave
	ret

GenEditControlClipArt		endm

;---

server2AppToken	GeodeToken	<"CHRm",16426>	; BREAK_BOX_MANUFACTURE_ID

GenEditControlCharMap		method	GenEditControlClass,
					MSG_GEC_LAUNCH_CHAR_MAP

	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	mov	cx, 0xcccc						>
EC <	mov	dx, 0xcccc						>
EC <	mov	bp, 0xcccc						>

	;
	; Create a launch block to pass to IACPConnect
	;
	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock ; dx = handle to AppLaunchBlock
	;
	; Clear launch flags 
	;
	mov	bx, dx			; bx <- handle of AppLaunchBlock
	call	MemLock			; ax = AppLaunchBlock segment
	mov	es, ax
	mov	es:[ALB_launchFlags], mask ALF_OVERRIDE_MULTIPLE_INSTANCE
	push	bx
	lea	di, es:[ALB_dataFile]
	mov	{byte}es:[di], 0              ; leave the first byte empty
	inc	di
	mov	ax, GGIT_PERM_NAME_AND_EXT
	clr	bx
	call	GeodeGetInfo		; es:di = GeodeToken
	pop	bx
	call	MemUnlock
	;
	; Connect to the desired server
	;
	mov	di, offset cs:[server2AppToken]
	segmov	es, cs, dx			; es:di points to GeodeToken
	mov	ax, mask IACPCF_FIRST_ONLY	; ax <- connect flag
	call	IACPConnect			; bp = IACPConnection
	jc	done
	;
	; Shut down connection
	;
	clr	cx, dx
	call	IACPShutdown

done:
	.leave
	ret

GenEditControlCharMap		endm

;---




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareUndoStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares the passed undo strings

CALLED BY:	GLOBAL
PASS:		es:di - ptr to optr of one null terminated string
		ds:bx - ptr to optr of the other null terminated string
		(es:di and ds:bx *cannot* be pointing into the movable XIP code
			resource.)
RETURN:		zero flag set if match (jz if match)
DESTROYED:	ax, cx, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareUndoStrings	proc	far	uses	es, ds, di, si, bx, bp
	destHan		local	hptr	\
			push	ds:[bx].handle

	sourceHan	local	hptr
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		mov	si, bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	si, ds:[bx].chunk

	mov	bx, es:[di].NUSC_undoTitle.handle
	mov	sourceHan, bx
	mov	di, es:[di].NUSC_undoTitle.chunk
	call	MemLock
	mov	es, ax
	mov	di, es:[di]

	mov	bx, destHan
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]

	ChunkSizePtr	es, di, cx			;CX <- size of source
							; chunk
	ChunkSizePtr	ds, si, ax			;AX <- size of dest
	cmp	ax, cx					;If size are not equal,
	jnz	doUnlock				; exit

	repe	cmpsb					;Compare the strings
doUnlock:
	mov	bx, sourceHan
	call	MemUnlock
	mov	bx, destHan
	call	MemUnlock
	.leave
	ret
CompareUndoStrings	endp


;---



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyUndoMonikerString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates an undo moniker string by prepending a prefix string
		to the passed app-supplied string, then appends a suffix.

CALLED BY:	GLOBAL
PASS:		^lcx:dx - optr of app-supplied title string
		al - undo type
		es:di - place to store string
RETURN:		es:di - end of string (points at null terminator)
DESTROYED:	ax, cx, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyUndoMonikerString	proc	uses	bx, si
	.enter
	push	ax
	pushdw	cxdx
	mov	si, offset UndoTriggerMonikerPrefix
	tst	al
	jz	undoPrefix
	mov	si, offset RedoTriggerMonikerPrefix	
undoPrefix:
	call	GEC_CopyFromControlStrings

;	Copy app-supplied string

	popdw	bxsi
	call	GEC_CopyFromChunk

	pop	ax
	mov	si, offset UndoTriggerMonikerSuffix
	tst	al
	jz	undoSuffix
	mov	si, offset RedoTriggerMonikerSuffix
undoSuffix:
	call	GEC_CopyFromControlStrings
SBCS <	mov	{char} es:[di], 0					>
DBCS <	mov	{wchar} es:[di], 0					>
	.leave
	ret
CopyUndoMonikerString	endp

	; es:[di].NUSC_undoTitle = optr of name
	; bx:si = undo trigger

SBCS <MAX_UNDO_MONIKER_LENGTH		=	128			>
DBCS <MAX_UNDO_MONIKER_LENGTH		=	256			>

GEC_SetUndoMoniker	proc	far	uses	bp
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	mov_tr	ax, di
	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di
	mov_tr	di, ax

	movdw	cxdx, es:[di].NUSC_undoTitle
	mov	al, es:[di].NUSC_undoType
	cmp	al, UD_NOT_UNDOABLE
	jz	setCannotUndoMoniker

	tst	cx			;Can't do jcxz - it's too far.
	jz	setNullMoniker


	sub	sp, MAX_UNDO_MONIKER_LENGTH + size VisMoniker + size VisMonikerText
	mov	di, sp
	segmov	es, ss					;ES:DI <- dest for
							; moniker
	
	mov	es:[di].VM_type, DAR_NORMAL shl offset VMT_GS_ASPECT_RATIO or DC_TEXT shl offset VMT_GS_COLOR
	clr	es:[di].VM_width
	clr	es:[di].VM_data.VMT_mnemonicOffset
	add	di, offset VM_data.VMT_text
;
;	Create the moniker string for the undo/redo trigger
;
;	^lcx:dx - title string for current undo chain
;	al - non-zero if we are doing a redo, else an undo
;	^lbx:si - undo trigger
;	ES:DI <- ptr to store the undo moniker string
;

	call	CopyUndoMonikerString

	mov	cx, di
	inc	cx					;+1 for NULL
DBCS <	inc	cx							>
	sub	cx, sp					;CX <- # bytes
	mov	di, sp

;	Set the vis moniker for the undo trigger

	mov	dx, size ReplaceVisMonikerFrame
	sub	sp, dx
	mov	bp, sp
	movdw	ss:[bp].RVMF_source, esdi
	mov	ss:[bp].RVMF_sourceType, VMST_FPTR
	mov	ss:[bp].RVMF_dataType, VMDT_VIS_MONIKER
	mov	ss:[bp].RVMF_length, cx
	clr	ss:[bp].RVMF_width
	clr	ss:[bp].RVMF_height
	mov	ss:[bp].RVMF_updateMode, VUM_DELAYED_VIA_UI_QUEUE
 	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size ReplaceVisMonikerFrame + MAX_UNDO_MONIKER_LENGTH + size VisMoniker + size VisMonikerText
exit:

	mov_tr	ax, di
	pop	di
	call	ThreadReturnStackSpace
	mov_tr	di, ax

	.leave
	ret

setCannotUndoMoniker:
EC <	tst	cx							>
EC <	ERROR_NZ	NON_ZERO_TITLE_PASSED_WITH_UD_NOT_UNDOABLE	>
	mov	dx, offset CannotUndoMoniker
	jmp	setMonikerCommon
setNullMoniker:
	mov	dx, offset NoUndoMoniker
setMonikerCommon:
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	cx, handle ControlStrings
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	exit
GEC_SetUndoMoniker	endp

;---

	; ^lbx:si = source
	; ss:di = dest

GEC_CopyFromControlStrings	proc	near
	mov	bx, handle ControlStrings
	FALL_THRU	GEC_CopyFromChunk
GEC_CopyFromControlStrings	endp

;-

GEC_CopyFromChunk	proc	near	uses ds, es
	.enter

	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]		;ds:si = source
	ChunkSizePtr	ds, si, cx	;cx = length
DBCS <	shr	cx, 1							>
	dec	cx			;Don't copy the null
	segmov	es, ss			;es:di = dest
SBCS <	rep movsb							>
DBCS <	rep movsw							>

	call	MemUnlock
	.leave
	ret
GEC_CopyFromChunk	endp

ControlCode ends

endif			; NO_CONTROLLERS ++++++++++++++++++++++++++++++++++++

