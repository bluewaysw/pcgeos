COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genToolControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenToolControlClass	Control object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version
TODO:

DESCRIPTION:
	This file contains routines to implement the Tool Controller object,
	which allows the user to customize their toolbar.

	See /s/p/M/UserInterface/Documentation/GenToolControl for API docs.

IMPLEMENTATION NOTES:
	GenToolControlClass is itself a UI Controller.  It places itself on
	the GAGCNLT_GEN_CONTROL_NOTIFY_STATUS_CHANGE GenApplication GCN List,
	to which all UI controllers send notification of changes in Feature/
	location, etc. status.  This list is unusual in that ALL controllers
	send notification to it, as there is no "target" controller.  As there
	is no "target" controller, the status of the "current" controller
	cannot be cached.  Instead controllers should be directly called for
	current info (not a problem, since they are running in the UI thread)

	$Id: uiTool.asm,v 1.1 97/04/07 11:47:05 newdeal Exp $

------------------------------------------------------------------------------@

UserClassStructures	segment resource

	GenToolControlClass

UserClassStructures	ends

MAX_TOOL_HOLDERS 	equ 	100
MAX_TOOLS_IN_HOLDER	equ	16

;---------------------------------------------------

if not NO_CONTROLLERS	;++++++++++++++++++++++++++++++++++++++++++++++++++++

ControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenToolControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GenToolControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GenToolControlClass

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
	Doug	12/91		Initial version

------------------------------------------------------------------------------@
GenToolControlGetInfo	method dynamic	GenToolControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GTC_dupInfo
	GOTO	CopyDupInfoCommon

GenToolControlGetInfo	endm

GTC_dupInfo	GenControlBuildInfo	<
	mask GCBF_IS_ON_START_LOAD_OPTIONS_LIST or \
		mask GCBF_CUSTOM_ENABLE_DISABLE, ; GCBI_flags
	GTC_IniFileKey,			; GCBI_initFileKey
	GTC_gcnList,			; GCBI_gcnList
	length GTC_gcnList,		; GCBI_gcnCount
	GTC_notifyTypeList,		; GCBI_notificationList
	length GTC_notifyTypeList,	; GCBI_notificationCount
	GTCName,			; GCBI_controllerName

	handle GenToolControlNormalUI,	; GCBI_dupBlock
	GTC_childList,			; GCBI_childList
	length GTC_childList,		; GCBI_childCount
	GTC_normalFeaturesList,		; GCBI_featuresList
	length GTC_normalFeaturesList,	; GCBI_featuresCount
	GTC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount

	GTC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	GTC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	segment	resource
endif

GTC_helpContext	char	"dbCustTool", 0


GTC_IniFileKey	char	"uiTools", 0

GTC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_GEN_CONTROL_NOTIFY_STATUS_CHANGE>

GTC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GEN_CONTROL_NOTIFY_STATUS_CHANGE>

;---

GTC_childList	GenControlChildInfo	\
	<offset ToolGroupList, mask GTCF_TOOL_DIALOG,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ToolsDialog, mask GTCF_TOOL_DIALOG,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset MoveDialog, mask GTCF_TOOL_DIALOG,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GTC_normalFeaturesList	GenControlFeaturesInfo \
	<offset ToolGroupList, ToolDialogName>

;---

if	(0)
; Put back in place of 0's in GTC_dupInfo above if we provide tools
; for GenToolControl objects.
;
;	handle ControlToolboxUI,	; GCBI_toolBlock
;	offset GTC_toolList,		; GCBI_toolList
;	length GTC_toolList,		; GCBI_toolCount
;	offset GTC_toolFeaturesList,	; GCBI_toolFeaturesList
;	length GTC_toolFeaturesList,	; GCBI_toolFeaturesCount
;
;
; & comment back in these tables:
;
;GTC_toolList	GenControlChildInfo	\
;	<offset ToolDialogTrigger, mask GTCTF_TOOL_DIALOG,
;					mask GCCF_IS_DIRECTLY_A_FEATURE>
;
; Careful, this table is in the *opposite* order as the record which
; it corresponds to.
;
;GTC_toolFeaturesList	GenControlFeaturesInfo	\
;        <offset ToolDialogTrigger, ToolDialogTriggerName>
;
endif

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenToolControlLoadOptions

DESCRIPTION:	Load state of the toolboxes in from the .ini file.

PASS:
	*ds:si - instance data
	es - segment of GenToolControlClass

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
	Doug	7/92		Initial version

------------------------------------------------------------------------------@
GenToolControlLoadOptions	method dynamic	GenToolControlClass,
							MSG_META_LOAD_OPTIONS
categoryBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
keyBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
dataBuffer	local	2*MAX_TOOL_HOLDERS dup (byte)
	ForceRef categoryBuffer
	ForceRef keyBuffer
	.enter

	push	bp
	mov	di, offset GenToolControlClass
	call	ObjCallSuperNoLock
	pop	bp

	push	ds:[LMBH_handle]
	push	si, bp
	call	GenToolControlIniPrepCommon
	mov	bp, size dataBuffer
	call	InitFileReadData		; Read in option data
	pop	si, bp
	pop	bx
	call	MemDerefDS
	jc	done			; if error, just bail  (refuse load)
	tst	cx
	jz	done			; if no data, done, no changes to make

	call	ToolGetNumberOfToolboxes
	clr	ax			; start w/toolbox #0
	lea	di, dataBuffer		; ss:di points to options data

toolboxLoop:
	push	ax, cx

	push	bx, si
	call	ToolGetToolboxByNumber
	mov	cx, bx
	mov	dx, si
	pop	bx, si

nextLetter:
	mov	al, {byte} ss:[di]	; get char &
	inc	di			; bump char ptr
	cmp	al, -1			; If signature -1, end of line for
	je	nextToolbox		; this toolbox -- on to next

	; Find tool holder, move it.
	;
	push	si
	push	ax
	clr	ah
	and	al, 7fh			; Clear high bit (indicates if USABLE)
	call	ToolGetToolGroupByNumber
	pop	ax
	tst	bx			; If non-existant, bail
	jz	afterReParent
	push	di, cx, dx, bp
	and	bp, CCO_LAST or mask CCF_MARK_DIRTY
	push	ax
	call	GenReParentObject
	pop	ax
	test	al, 80h			; test high bit -- USABLE?
	jz	afterUsable		; if not, leave NOT_USABLE.
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
afterUsable:
	pop	di, cx, dx, bp
afterReParent:
	pop	si
	jmp	short nextLetter

nextToolbox:
	pop	ax, cx
	inc	ax
	loop	toolboxLoop

done:
	.leave
	ret
GenToolControlLoadOptions	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenToolControlIniPrepCommon

DESCRIPTION:	Load registers, stack frame w/category, key, buffer pointers,
		to ready for call to ini function

CALLED BY:	INTERNAL
		GenToolControlLoadOptions
		GenToolControlSaveOptions

PASS:		*ds:si	- GenToolControl object
		ss:bp	- inherited vars, including "categoryBuffer" & 
			  "dataBuffer"

RETURN:		ds:si	- category, filled in
		es:di	- data buffer (unchanged)
		cx:dx	- key

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/92		Initial version
------------------------------------------------------------------------------@

toolControlDefaultKey	char	"toolLayout", 0

GenToolControlIniPrepCommon	proc	far
	.enter inherit GenToolControlLoadOptions

	; get the category string
	;
	mov	cx, ss
	lea	dx, categoryBuffer
	call	UserGetInitFileCategory

	; copy the key in

	segmov	ds, cs
	mov	si, offset toolControlDefaultKey
	segmov	es, ss
	lea	di, keyBuffer
	mov	cx, size toolControlDefaultKey
	rep	movsb

	segmov	ds, ss
	lea	si, categoryBuffer			;ds:si = category

	segmov	es, ss					;es:di = data buffer
	lea	di, dataBuffer

	mov	cx, ss
	lea	dx, keyBuffer				;cx:dx = key

	.leave
	ret
GenToolControlIniPrepCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlInitializeVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialized variable data component passed

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_INITIALIZE_VAR_DATA
		cx	- data type

RETURN:		ds:ax	- ptr to data entry
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenToolControlInitializeVarData	method GenToolControlClass,
					MSG_META_INITIALIZE_VAR_DATA
	cmp	cx, TEMP_GEN_TOOL_CONTROL_INSTANCE
	je	TempData

	mov	di, offset GenToolControlClass
	GOTO	ObjCallSuperNoLock

TempData:
	mov	ax, cx
	mov	cx, size TempGenToolControlInstance
	call	ObjVarAddData		; ds:bx = TempGenToolControlInstance
	mov	ax, bx			; return ptr to data entry
	ret

GenToolControlInitializeVarData	endm

ControlCommon ends

;---

GenToolControlCode segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenToolControlGenerateUI -- 
		MSG_GEN_CONTROL_GENERATE_UI for GenToolControlClass

DESCRIPTION:	Generates UI for the controller.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_CONTROL_GENERATE_UI

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/24/92		Initial Version

------------------------------------------------------------------------------@

GenToolControlGenerateUI	method dynamic	GenToolControlClass, \
				MSG_GEN_CONTROL_GENERATE_UI

	mov	di, offset GenToolControlClass
	call	ObjCallSuperNoLock

	; give ourself a hint we need...

	mov	ax, HINT_ORIENT_CHILDREN_HORIZONTALLY or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData

	;
	; Set the number of controllers and toolboxes in the appropriate 
	; dynamic lists.  Hopefully this is the correct place to do this.
	;
	call	SetNumToolboxItems
	call	ToolPurgeGroupList

	; An opportune time as well to initialize the exclusive for this list
	call	ToolEnsureCurController
	ret
GenToolControlGenerateUI	endm

;--------------------

SetNumToolboxItems	proc	near
	call	ToolGetNumberOfToolboxes	; cx = # of entries
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, offset ToolPlacementList
	call	ToolCallChildObject
	ret
SetNumToolboxItems	endp

COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolGetNumberOfControllers

DESCRIPTION:	Get number of controllers we're working with

CALLED BY:	INTERNAL
		GenToolControlGetNumberOfEntries
		ToolEnsureCurController
		ToolPurgeGroupList

PASS:		*ds:si	- GenToolControl object
RETURN:		cx - # of entries
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolGetNumberOfControllers	proc	far	uses	di
	.enter
	call	ToolGetPtrToToolGroupList
	tst	di
	jz	noList
	ChunkSizePtr	ds, di, cx		; get size of chunk
	shr	cx, 1				; divide by size ToolGroupInfo
	shr	cx, 1				;	= 4
done:
	.leave
	ret

noList:
	clr	cx
	jmp	short done
ToolGetNumberOfControllers	endp

;------------------------

ToolGetPtrToToolGroupList	proc	near
	class	GenToolControlClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GTCI_toolGroupList	; get chunk of toolbox list
	tst	di
	jz	done
	mov	di, ds:[di]
done:
	ret
ToolGetPtrToToolGroupList	endp



COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolGetToolGroupByNumber

DESCRIPTION:	Find GenToolGroup object, given position in holder list

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
		ax	- entry # (0 on up)
RETURN:		bx:si	- GenToolGroup object, or 0 if position
			  doesn't exist
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolGetToolGroupByNumber	proc	far	uses	ax, cx, di
	.enter
	call	ToolGetNumberOfControllers	; same as # of holders
	cmp	ax, cx
	jae	nonExistant

	call	ToolGetPtrToToolGroupList
	tst	di
	jz	nonExistant

	; fetch optr of GenControl object we'd like group moniker for
	;
	shl	ax, 1				; times size ToolGroupInfo
	shl	ax, 1				;	= 4
	add	di, ax
	mov	cx, ds:[di].TGI_object.handle
	mov	si, ds:[di].TGI_object.chunk
	mov	bx, ds:[LMBH_handle]
	mov     al, RELOC_HANDLE
	call    ObjDoRelocation
	mov	bx, cx
EC <	call	ECCheckLMemOD					>
done:
	.leave
	ret

nonExistant:
	clr	bx
	clr	si
	jmp	short done

ToolGetToolGroupByNumber	endp



COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolGetControllerByNumber

DESCRIPTION:	Find GenControl object, given position in
		GAGCNLT_GEN_CONTROL_OBJECTS list

CALLED BY:	INTERNAL
		GenToolControlRequestEntryMoniker
		GenToolControlInternalGroupList

PASS:		*ds:si	- GenToolControl object
		ax	- entry # (0 on up)
RETURN:		bx:si	- GenControl object, or 0 if position doesn't exist
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolGetControllerByNumber	proc	near	uses	ax, di
	class	GenToolGroupClass
	.enter
	call	ToolGetToolGroupByNumber
	tst	si
	jz	done

	call	ObjSwapLock			; lock tool holder
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
						; fetch optr of controller
	mov	ax, ds:[di].GTGI_controller.handle
	mov	si, ds:[di].GTGI_controller.chunk
	call	ObjSwapUnlock
	mov	bx, ax
EC <	call	ECCheckLMemOD					>
done:
	.leave
	ret
ToolGetControllerByNumber	endp


COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolGetToolGroupForController

DESCRIPTION:	Find tool holder for a given controller

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
		^lcx:dx	- controller whose holder we need
RETURN:		bx:si	- tool holder object, or 0 if position doesn't exist
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolGetToolGroupForController		proc	near	uses ax, cx, di
	.enter
EC <	xchg	bx, cx						>
EC <	xchg	si, dx						>
EC <	call	ECCheckLMemOD					>
EC <	xchg	bx, cx						>
EC <	xchg	si, dx						>
	tst	cx
	jz	notFound

	mov	di, cx
	call	ToolGetNumberOfControllers
	jcxz	notFound
	clr	ax
searchLoop:
	push	si
	call	ToolGetControllerByNumber
	cmp	bx, di
	jne	next
	cmp	si, dx
	je	found
next:
	pop	si
	inc	ax
	loop	searchLoop

notFound:
	clr	bx		; Not found, so return 0
	clr	si
done:
	.leave
	ret

found:
	pop	si
				; Return the tool holder requested
	call	ToolGetToolGroupByNumber
EC <	call	ECCheckLMemOD					>
	jmp	short done

ToolGetToolGroupForController		endp


COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolGetCurToolGroup

DESCRIPTION:	Find tool holder for a current controller

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
RETURN:		bx:si	- tool holder object, or 0 if doesn't exist
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolGetCurToolGroup	proc	near	uses	ax, cx, dx
	.enter
	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	cx, ds:[bx].TGTCI_curController.handle
	mov	dx, ds:[bx].TGTCI_curController.chunk
	call	ToolGetToolGroupForController	;get current holder object
	.leave
	ret
ToolGetCurToolGroup	endp

COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolGetToolboxByNumber

DESCRIPTION:	Find toolbox object, given position in holder list

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
		ax	- entry # (0 on up)
RETURN:		bx:si	- GenToolGroup object, or 0 if position
			  doesn't exist
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolGetToolboxByNumber	proc	far	uses	ax, cx, di
	.enter
	call	ToolGetNumberOfToolboxes
	cmp	ax, cx
	jae	nonExistant

	call	ToolGetPtrToToolboxList

	; fetch optr of toolbox 
	;
	shl	ax, 1				; times size ToolboxInfo
	shl	ax, 1				;	= 8
	shl	ax, 1
	add	di, ax
	mov	cx, ds:[di].TI_object.handle
	mov	si, ds:[di].TI_object.chunk
	mov	bx, ds:[LMBH_handle]
	mov     al, RELOC_HANDLE
	call    ObjDoRelocation
	mov	bx, cx
EC <	call	ECCheckLMemOD					>

done:
	.leave
	ret

nonExistant:
	clr	bx
	clr	si
	jmp	short done

ToolGetToolboxByNumber	endp

COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolGetToolboxNumber

DESCRIPTION:	Find number of toolbox from it's optr

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
		cx:dx	- optr of toolbox
RETURN:		ax	- # of toolbox, or -1 if not found
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolGetToolboxNumber	proc	near	uses	di, bx, cx
	.enter

EC <	xchg	bx, cx						>
EC <	xchg	si, dx						>
EC <	call	ECCheckLMemOD					>
EC <	xchg	bx, cx						>
EC <	xchg	si, dx						>

	mov	di, cx
	call	ToolGetNumberOfToolboxes

	clr	ax				; start at # 0
searchLoop:
	push	si
	call	ToolGetToolboxByNumber
	cmp	bx, di
	jne	next
	cmp	si, dx
	je	found
next:
	inc	ax				; inc count
	pop	si
	loop	searchLoop

	mov	ax, -1				; not found
	jmp	short done

found:
	pop	si
done:
	.leave
	ret

ToolGetToolboxNumber	endp

COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolGetToolGroupNumber

DESCRIPTION:	Find number of toolholder from it's optr

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
		cx:dx	- optr of tool holder
RETURN:		ax	- # of tool holder, or -1 if not found
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolGetToolGroupNumber	proc	near	uses	di, bx, cx
	.enter
EC <	xchg	bx, cx						>
EC <	xchg	si, dx						>
EC <	call	ECCheckLMemOD					>
EC <	xchg	bx, cx						>
EC <	xchg	si, dx						>

	mov	di, cx
	call	ToolGetNumberOfControllers	; same as tool holders
	jcxz	notFound

	clr	ax				; start at # 0
searchLoop:
	push	si
	call	ToolGetToolGroupByNumber
	cmp	bx, di
	jne	next
	cmp	si, dx
	je	found
next:
	inc	ax				; inc count
	pop	si
	loop	searchLoop

notFound:
	mov	ax, -1				; if not found
	jmp	short done

found:
	pop	si
done:
	.leave
	ret

ToolGetToolGroupNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlInteractable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Intercept interactable notification, so that we can enter &
		leave "Tool Managing" mode, in which all tool groups are 
		highlighted to help user figure out what's going on.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_CONTROL_NOTIFY_INTERACTABLE

		cx	- GenControlInteractableFlags



ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	(0)
GenToolControlInteractable	method dynamic GenToolControlClass,
				MSG_GEN_CONTROL_NOTIFY_INTERACTABLE
	push	cx
	mov	di, offset GenToolControlClass
	call	ObjCallSuperNoLock
	pop	cx
	test	cx, mask GCIF_NORMAL_UI
	jz	done

	mov	cl, TGHT_INACTIVE_HIGHLIGHT
	call	ToolSetHighlightForAllToolGroups

	; Re-highlight any "active" object
	;
	mov	ax, TEMP_GEN_TOOL_CONTROL_HIGHLIGHTED_TOOL_GROUP
	call	ObjVarFindData
	jnc	done
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov	cl, TGHT_ACTIVE_HIGHLIGHT
	call	HighlightMessage
done:
	ret

GenToolControlInteractable	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlNotInteractable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Intercept interactable notification, so that we can 
		leave "Tool Managing" mode, in which all tool groups are 
		highlighted to help user figure out what's going on.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE

		cx	- GenControlInteractableFlags

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	(0)
GenToolControlNotInteractable	method dynamic GenToolControlClass,
				MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE
	push	cx
	mov	di, offset GenToolControlClass
	call	ObjCallSuperNoLock
	pop	cx
	test	cx, mask GCIF_NORMAL_UI
	jz	done
	mov	cl, TGHT_NO_HIGHLIGHT
	call	ToolSetHighlightForAllToolGroups
done:
	ret

GenToolControlNotInteractable	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlGroupListVisibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Intercept visibility notification, so that we can 
		leave "Tool Managing" mode, in which all tool groups are 
		highlighted to help user figure out what's going on.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_TOOL_CONTROL_INTERNAL_GROUP_LIST_VISIBILITY

		^lcx:dx	- Group List
		bp	- non-zero if visible

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolControlGroupListVisibility	method dynamic GenToolControlClass,
			MSG_GEN_TOOL_CONTROL_INTERNAL_GROUP_LIST_VISIBILITY
	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData

	tst	bp
	jz	notVisible

;visible:
	mov	ds:[bx].TGTCI_toolGroupVisible, -1	; set flag "visible"
	push	ds:[bx].TGTCI_curToolGroup.handle	; save cur tool, if any
	push	ds:[bx].TGTCI_curToolGroup.chunk

	mov	cl, TGHT_INACTIVE_HIGHLIGHT
	call	ToolSetHighlightForAllToolGroups

	; Re-highlight any "active" object
	;
	pop	si
	pop	bx
	tst	bx
	jz	done
	mov	cl, TGHT_ACTIVE_HIGHLIGHT
	call	HighlightMessage
	jmp	short done

notVisible:
	clr	ds:[bx].TGTCI_toolGroupVisible		; set flag "not visible"
	mov	cl, TGHT_NO_HIGHLIGHT
	call	ToolSetHighlightForAllToolGroups
done:
	ret

GenToolControlGroupListVisibility	endm


COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolSetHighlightForAllToolGroups

DESCRIPTION:	Set highlight color for ALL tool gorups

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
		cl	- Color, or -1 for none
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolSetHighlightForAllToolGroups	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	mov	dl, cl				; keep color in dl
	call	ToolGetNumberOfControllers	; same as tool holders
	jcxz	done

	clr	ax				; start at # 0
setLoop:
	push	ax, cx, dx, si
	call	ToolGetToolGroupByNumber
	mov	cl, dl
	call	HighlightMessage
	pop	ax, cx, dx, si
	inc	ax				; inc count
	loop	setLoop
done:
	.leave
	ret

ToolSetHighlightForAllToolGroups	endp


COMMENT @----------------------------------------------------------------------
FUNCTION:	SwitchActiveToolGroupHighlight

DESCRIPTION:	Turn off any existing "bright" highlight, & move it to new
		tool group

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
		ax	- # of new toolgroup to indicate active
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@
SwitchActiveToolGroupHighlight	proc	near	uses	ax, bx, cx, dx, bp, di
	.enter
	push	si
	call	ToolGetToolGroupByNumber
	mov	cx, bx			; ^hcx:dx = new tool group
	mov	dx, si
	pop	si
	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData
	tst	ds:[bx].TGTCI_toolGroupVisible
	jnz	visible

;notVisible:
	; If not visible, just store new cur tool group
	;
	mov	ds:[bx].TGTCI_curToolGroup.handle, cx
	mov	ds:[bx].TGTCI_curToolGroup.chunk, dx
	jmp	short done

visible:
	; Un-highlight old, store new
	;
	push	si
	mov	si, ds:[bx].TGTCI_curToolGroup.chunk
	mov	ax, ds:[bx].TGTCI_curToolGroup.handle
	mov	ds:[bx].TGTCI_curToolGroup.handle, cx
	mov	ds:[bx].TGTCI_curToolGroup.chunk, dx
	mov	bx, ax
	push	cx
	mov	cl, TGHT_INACTIVE_HIGHLIGHT
	call	HighlightMessage
	pop	cx
	pop	si

	; Highlight new.

	push	si
	mov	bx, cx
	mov	si, dx
	mov	ax, bp
	mov	cl, TGHT_ACTIVE_HIGHLIGHT
	call	HighlightMessage
	pop	si

done:
	.leave
	ret
SwitchActiveToolGroupHighlight	endp


HighlightMessage	proc	near	uses	ax, cx, dx, bp, di
	.enter
	mov	ax, MSG_GEN_TOOL_GROUP_SET_HIGHLIGHT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
HighlightMessage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlGroupListQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Respond to message coming from group dynamic list

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_TOOL_CONTROL_INTERNAL_GROUP_LIST_QUERY
		cx:dx	- optr of GenDynamicList
		bp	- entry # that moniker is needed for


RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolControlGroupListQuery	method dynamic GenToolControlClass,
				MSG_GEN_TOOL_CONTROL_INTERNAL_GROUP_LIST_QUERY
	mov	ax, bp
	call	ToolGetControllerByNumber	; get GenControl in bx:si
	tst	bx
	jz	done

	; Fetch controller name
	;
	push	cx, dx, bp
	sub	sp, size GenControlBuildInfo
	mov	cx, ss				; get cx:dx - ptr to struct
	mov	dx, sp
	mov	ax, MSG_GEN_CONTROL_GET_INFO
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	bp, sp
	mov	bx, ss:[bp].GCBI_controllerName.handle
	mov	si, ss:[bp].GCBI_controllerName.chunk
	add	sp, size GenControlBuildInfo	; fix stack
	pop	cx, dx, bp

SetTextFromOptr	label	far
	; bx:si is optr of chunk holding text string of controller
	;
	call	ObjSwapLock
	push	bx
	mov	di, ds:[si]			; deref to get ptr to string

	mov	bx, cx				; get optr of list
	mov	si, dx

	mov	cx, ds				; cx:dx <- text
	mov	dx, di
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx
	call	ObjSwapUnlock
done:
	ret
GenToolControlGroupListQuery	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlGroupPlacementQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Respond to message coming from placement dynamic list

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_TOOL_CONTROL_INTERNAL_PLACEMENT_LIST_QUERY
		cx:dx	- optr of GenDynamicList
		bp	- entry # that moniker is needed for


RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolControlGroupPlacementQuery	method dynamic GenToolControlClass,
			MSG_GEN_TOOL_CONTROL_INTERNAL_PLACEMENT_LIST_QUERY
	push	cx, dx
	call	ToolGetPtrToToolboxList		; get ds:di ptr to first info
	mov	cx, bp				; find needed entry
	jcxz	thisEntry
toolboxFindEntryLoop:
	add	di, size ToolboxInfo
	loop	toolboxFindEntryLoop
thisEntry:
	mov     bx, ds:[LMBH_handle]
	mov	cx, ds:[di].TI_name.handle
	mov     al, RELOC_HANDLE
	call    ObjDoRelocation
	mov	bx, cx
	mov	si, ds:[di].TI_name.chunk
EC <	;								>
EC <	; NOTE: do not call ECCheckLMemOD(), as it assumes the optr	>
EC <	; NOTE: is an object, and so chokes in CheckClass().		>
EC <	;								>
EC <	push	ax, ds, si			;>
EC <	call	ECCheckMemHandle		;>
EC <	call	MemLock				;>
EC <	mov	ds, ax				;*ds:si <- chunk>
EC <	mov	si, ds:[si]			;ds:si <- chunk>
EC <	call	ECCheckLMemChunk		;>
EC <	call	MemUnlock			;>
EC <	pop	ax, ds, si			;>
	pop	cx, dx
	GOTO	SetTextFromOptr

GenToolControlGroupPlacementQuery	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlInternalGroupList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Respond to events happening in Group list

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_TOOL_CONTROL_INTERNAL_GROUP_LIST

		cx	- Index of the entry sending the AD (the actual excl)
		bp	- # of selections

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolControlInternalGroupList	method dynamic GenToolControlClass,
				MSG_GEN_TOOL_CONTROL_INTERNAL_GROUP_LIST

	tst	bp
	jnz	setNewList			;there are items, branch

	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ds:[bx].TGTCI_curController.handle, 0
	mov	ds:[bx].TGTCI_curController.chunk, 0
	jmp	short redoDone

setNewList:
	mov	ax, cx
	call	SwitchActiveToolGroupHighlight	; highlight new tool group

	; OK, just gained actual exclusive.  cx = # of controller
	;
	push	si
	mov	ax, cx
	call	ToolGetControllerByNumber	; get bx:si = controller
	mov	di, si				; bx:di = controller
	pop	si
	tst	bx				; strange, but ok -- just
	jz	redoDone			; skip out if not real

	push	bx
	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData
	pop	ds:[bx].TGTCI_curController.handle
	mov	ds:[bx].TGTCI_curController.chunk, di

	; 1) Set Item's with monikers of accessible features (icon too!)
	;
	call	RedoFeatureListMonikers

redoDone:
	; 2) Get # of features, mask of features accessible by user,
	;   Reposition (hidden/active) each Item correctly & set USABLE
	;   correct # of Item's.  update location & position as well.
	;
	call	RedoFeatureListStatus
	call	RedoPlacementListStatus
	call	RedoPositionStatus
	ret
GenToolControlInternalGroupList	endm


;----

; Table of all the GenItems used to represent the features offered
; by current controller.  Feature0Item corresponds to the feature in bit
; position 0, Feature15Item the 15th bit.
;
FeatureItems	word \
	offset	Feature0Item,
	offset	Feature1Item,
	offset	Feature2Item,
	offset	Feature3Item,
	offset	Feature4Item,
	offset	Feature5Item,
	offset	Feature6Item,
	offset	Feature7Item,
	offset	Feature8Item,
	offset	Feature9Item,
	offset	Feature10Item,
	offset	Feature11Item,
	offset	Feature12Item,
	offset	Feature13Item,
	offset	Feature14Item,
	offset	Feature15Item


COMMENT @----------------------------------------------------------------------
FUNCTION:	RedoFeatureListMonikers
DESCRIPTION:	Sets VisualMonikers for all FeatureXXItem objects, based on
		GCBI_toolFeatureList table provided by the current controller
		object
CALLED BY:	INTERNAL
		GenToolControlInternalGroupList
PASS:		*ds:si - GenToolControl
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@
RedoFeatureListMonikers	proc	near	uses	ax, bx, cx, dx, bp, si, di, es
	.enter
	sub	sp, size GenControlBuildInfo

	; Get pointer to Tool Feature List, # of items
	;
	mov	ax, MSG_GEN_CONTROL_GET_INFO
	mov	cx, ss				; get cx:dx - ptr to struct
	mov	dx, sp
	call	ToolCallCurController
	jz	done				; quit if no current controller
	mov	bp, sp
	movdw	bxdi, ss:[bp].GCBI_toolFeaturesList
	mov	cx, ss:[bp].GCBI_toolFeaturesCount

	tst	cx				; if no Features, exit
	jz	done

	; ^hbx:di is Feature list, cx is count

	push	bx
	call	MemLockFixedOrMovable
	mov	es, ax				; es:di is ptr to tools Feature
						; list

	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	bx, ds:[bx].TGCI_childBlock	; fetch bx = block that list
						; entries are in
	mov	si, offset FeatureItems	; get offset to table of list
						; entry chunks

theLoop:
	push	bx, cx, di, si

	mov	cx, bx				; fetch cx:dx = optr of list
	mov	dx, cs:[si]			; entry we need to update

	mov	bx, es:[di].GCFI_name.handle
	mov	si, es:[di].GCFI_name.chunk

	; bx:si is optr of chunk holding text string of controller
	call	ObjSwapLock
	push	bx
	mov	di, ds:[si]			; deref to get ptr to string

	mov	bx, cx				; get bx:si = optr of list entry
	mov	si, dx

	mov	cx, ds
	mov	dx, di
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	bx
	call	ObjSwapUnlock

	pop	bx, cx, di, si
	add	di, size GenControlFeaturesInfo
	add	si, size word
	loop	theLoop

	pop	bx
	call	MemUnlockFixedOrMovable		; Unlock block of table

done:
	add	sp, size GenControlBuildInfo	; fix stack
	.leave
	ret
RedoFeatureListMonikers	endp

;---



COMMENT @----------------------------------------------------------------------
FUNCTION:	RedoFeatureListStatus
DESCRIPTION:	Fetches current status of various Features avalable from 
		current controller, stores that info locally, moves list entries
		that represent those Features between the hidden & active
		lists, & finally updates usability status for all list
		entries.
CALLED BY:	INTERNAL
		GenToolControlInternalGroupList
		GenToolControlUpdateUI
PASS:		*ds:si - GenToolControl
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@
RedoFeatureListStatus	proc	near	uses	ax, bx, cx, dx, si, di, bp
	.enter
	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGTCI_curController.handle
	tst	ax
	jz	readyToSetUsabilityStatus	; if no controller, set all 
						; entries NOT USABLE

	push	si
	mov	si, ds:[bx].TGTCI_curController.chunk
	mov	bx, ax
	mov	ax, MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	push	ax, cx, bp, si
	call	ToolGetCurToolGroup	; find current tool holder
	mov	ax, MSG_GEN_GET_USABLE	; USABLE?
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, cx, bp, si
	jc	afterUsableCheck
	clr	ax			; if not usable, no active features.
afterUsableCheck:

	push	ax
	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData
	pop	ax

	mov	ds:[bx].TGTCI_features, ax
	mov	ds:[bx].TGTCI_required, cx
	not	dx			; get not mask for prohibited
	and	bp, dx			; get Features available to user
	mov	ds:[bx].TGTCI_allowed, bp

	push	bp			; save new "allowed" mask

	; Reset active status of tools in list here
	; ax = Features currently active
	;
	call	SetFeatureListActiveStatus

	pop	ax			; get "allowed" mask

readyToSetUsabilityStatus:

	; ax = bitmask of Features to be USABLE
	;
	call	SetFeatureListUsabilityStatus	; set available entries USABLE,
						; others NOT USABLE.

	.leave
	ret
RedoFeatureListStatus	endp


;---

COMMENT @----------------------------------------------------------------------
FUNCTION:	SetFeatureListActiveStatus

DESCRIPTION:	Move GenItems that represent the Features of the
		current controller to the correct GenList, i.e. either the
		"Displayed" or "Hidden" Feature lists, based on the mask
		passed.

CALLED BY:	INTERNAL
		RedoFeatureListStatus
PASS:		*ds:si	- GenToolControl object
		ax	- bit mask of currently "displayed," or "active"
			  Features, i.e. those not hidden
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

REVISION HISTORY:	
		We can only guess who wrote it and when, but:
		chris	2/17/93		Rewritten to use GenItemGroups

------------------------------------------------------------------------------@

SetFeatureListActiveStatus   proc    near
	itemList	local	MAX_TOOLS_IN_HOLDER dup (word)
	.enter
	push	bp

	mov	cx, ax			; get new settings in cx
	clr	dx			; no set items yet
	mov	ax, 8000h		; start with high bit
	lea	di, itemList		; es:[di] <- item list
	push	di
	segmov	es, ss			

setItemsLoop:
	test	ax, cx			; see if bit is set in mask
	jz	10$			; no, branch
	stosw				; else store in our buffer
	inc	dx			; increment number of set items
10$:
	shr	ax, 1			; shift bits downward
	jnz	setItemsLoop		; jump if not all shifted out

	mov	cx, ss			; cx:bp <- selection buffer
	pop	bp			
	xchg	bp, dx			; now in cx:dx, bp is number of sels
	
	mov	di, offset ToolsList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS
	call	ToolCallChildObject
	pop	bp
	.leave
	ret
SetFeatureListActiveStatus   endp

;---

COMMENT @----------------------------------------------------------------------
FUNCTION:	GenReParentObject

DESCRIPTION:	Assembly language utility:
			Set object NOT_USABLE(VUM_DELAYED_VIA_UI_QUEUE),
			Remove it from current parent,
			Add it onto new parent.
			Note:  does not set USABLE again.

CALLED BY:	INTERNAL
		SetFeatureListActiveStatus

PASS:		bx:si	- object to move
		cx:dx	- desired new parent
		bp	- CompChildFlags to use for remove, add
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp
------------------------------------------------------------------------------@
GenReParentObject	proc	far	uses	bx, si
	.enter

	call	ObjSwapLock
	push	bx

; Can't do this, since we're often calling just to change position within
; parent composite.
;
;	; Test to see if already on correct parent
;	;
;	push	si
;	call	GenFindParent
;	cmp	bx, cx
;	jne	10$
;	cmp	si, dx
;10$:
;	pop	si
;	je	done

	push	cx, dx, bp	; save optr of new parent, add position

				; set NOT_USABLE before removing
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	push	bp
	call	ObjCallInstanceNoLock
	pop	bp


	mov	ax, MSG_GEN_REMOVE_CHILD
	mov	cx, ds:[LMBH_handle]	; remove self
	mov	dx, si
	and	bp, mask CCF_MARK_DIRTY
	call	GenCallParent

	mov	ax, MSG_GEN_ADD_CHILD
	mov	cx, ds:[LMBH_handle]	; add self
	mov	dx, si
	pop	bx, si, bp	; get optr of new parent
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	bx
	call	ObjSwapUnlock
	.leave
	ret
GenReParentObject	endp

;---

COMMENT @----------------------------------------------------------------------
FUNCTION:	SetFeatureListUsabilityStatus

DESCRIPTION:	Set Item representing Features of current Controller
		USABLE or NOT_USABLE based on bitmask passed

CALLED BY:	INTERNAL
		RedoFeatureListStatus

PASS:		*ds:si	- GenToolControl object
RETURN:		ax	- bit mask of Features
			  0 to set NOT_USABLE
			  1 to set USABLE
DESTROYED:	ax, bx, cx, dx, di, bp
------------------------------------------------------------------------------@
SetFeatureListUsabilityStatus	proc	near	uses	si
	.enter
					; Fetch block that lists are in
	push	ax
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	pop	ax
	mov	bx, ds:[bx].TGCI_childBlock
	mov	di, offset FeatureItems
	mov	cx, length FeatureItems	; # of list entries
notUsableLoop:
	push	cx, di
	shr	ax
	push	ax
	mov	ax, MSG_GEN_SET_NOT_USABLE
	jnc	10$
	mov	ax, MSG_GEN_SET_USABLE
10$:
	mov	si, cs:[di]		; fetch offset of list entry
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessage
	pop	ax
	pop	cx, di
	add	di, size word
	loop	notUsableLoop
	.leave
	ret
SetFeatureListUsabilityStatus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlInternalResetTools
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Implements "Reset" button for show/hide tools dialog

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_TOOL_CONTROL_INTERNAL_RESET_TOOLS

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenToolControlInternalResetTools method dynamic GenToolControlClass,
			MSG_GEN_TOOL_CONTROL_INTERNAL_RESET_TOOLS
	call	RedoFeatureListStatus
	ret
GenToolControlInternalResetTools endm


GenToolControlInternalResetPlacement method dynamic GenToolControlClass,
			MSG_GEN_TOOL_CONTROL_INTERNAL_RESET_PLACEMENT
	call	RedoPlacementListStatus
	ret
GenToolControlInternalResetPlacement endm

GenToolControlInternalResetPosition method dynamic GenToolControlClass,
			MSG_GEN_TOOL_CONTROL_INTERNAL_RESET_POSITION
	call	RedoPositionStatus
	ret
GenToolControlInternalResetPosition endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlInternalToolsList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Respond to apply of tools list

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_TOOL_CONTROL_INTERNAL_TOOLS_LIST

		cx	- Booleans currently selected
		dx	- indeterminate booleans
		bp	- modified booleans

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolControlInternalToolsList method dynamic GenToolControlClass,
			MSG_GEN_TOOL_CONTROL_INTERNAL_TOOLS_LIST

	mov	di, offset ToolsList
	call	GetSelectionMaskFromItemGroup	;cx <- selection mask

	mov	ax, MSG_GEN_SET_NOT_USABLE
	tst	cx
	jz	haveUsableState
	mov	ax, MSG_GEN_SET_USABLE
haveUsableState:

	; Set tool group usable if has active tools
	;
	push	cx, bx, si
	call	ToolGetCurToolGroup		; find current tool holder
	call	ObjSwapLock
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	call	ObjSwapUnlock
	pop	cx, bx, si
				; Display all tools appropriate
	mov	ax, MSG_GEN_CONTROL_ADD_TOOLBOX_FEATURE
	push	cx
	call	ToolCallCurController
	pop	cx
	not	cx		; Remove all tools that should be hidden
	mov	ax, MSG_GEN_CONTROL_REMOVE_TOOLBOX_FEATURE
	call	ToolCallCurController

	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	UserCallApplication

	ret

GenToolControlInternalToolsList endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetSelectionMaskFromItemGroup

SYNOPSIS:	Looks up multiple selections from an item group and creates
		a mask out of it.

CALLED BY:	GenToolControlInternalToolsList

PASS:		di -- handle of child item group to call

RETURN:		cx -- bitmask of selected item identifiers

DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/17/93       	Initial version

------------------------------------------------------------------------------@

GetSelectionMaskFromItemGroup	proc	near		uses	ds, si
	itemList	local	MAX_TOOLS_IN_HOLDER dup (word)
	.enter
	push	bp
	mov	cx, ss
	lea	dx, itemList			;cx:dx <- buffer to use
	mov	bp, MAX_TOOLS_IN_HOLDER		;max number of items
	mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
	call	ToolCallChildObject

	mov	cx, ax				;number of items
	segmov	ds, ss
	mov	si, dx				;ds:si <- start of buffer
	clr	dx				;place to keep result
	tst	cx
	jz	exit
orBits:
	lodsw					;get an item
	or	dx, ax				;or together with result
	loop	orBits				;not done, do some more.
exit:
	pop	bp				;restore stack frame
	mov	cx, dx				;return in cx
	.leave
	ret
GetSelectionMaskFromItemGroup	endp



COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolGetNumberOfToolboxes

DESCRIPTION:	Fetch # of toolboxes setup by application

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
RETURN:		cx	- number of toolboxes
		ds:di	- pointer to array of GenToolControlToolboxInfo's
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolGetNumberOfToolboxes	proc	far	uses	ax, di
	.enter
	call	ToolGetPtrToToolboxList
EC < 	tst	di						>
EC <	ERROR_Z	GEN_TOOL_CONTROL_REQUIRES_AT_LEAST_ONE_TOOLBOX_TO_BE_SPECIFIED >

	ChunkSizePtr	ds, di, ax		; get size of chunk
	mov	cl, size ToolboxInfo
	div	cl
EC <	tst	ah				; check for remainder	>
EC <	ERROR_NZ GEN_TOOL_CONTROL_BAD_TOOLBOX_LIST			>
	mov	cx, ax
;haveAppAdded:
EC < 	tst	cx						>
EC <	ERROR_Z	GEN_TOOL_CONTROL_REQUIRES_AT_LEAST_ONE_TOOLBOX_TO_BE_SPECIFIED >
	.leave
	ret
ToolGetNumberOfToolboxes	endp

;---

ToolGetPtrToToolboxList	proc	near
	class	GenToolControlClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GTCI_toolboxList	; get chunk of toolbox list
	tst	di
	jz	done
	mov	di, ds:[di]
done:
	ret
ToolGetPtrToToolboxList	endp



COMMENT @----------------------------------------------------------------------
FUNCTION:	RedoPlacementListStatus
DESCRIPTION:	Set state, i.e. current exlusive, of Group Placement list,
		based on current controller.
CALLED BY:	INTERNAL
		GenToolControlInternalGroupList
PASS:		*ds:si - GenToolControl
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@
RedoPlacementListStatus	proc	near	uses	ax, bx, cx, dx, si, di, bp
	.enter
	mov	di, offset ToolPlacementList

	push	bx, si
	call	ToolGetCurToolGroup		; find current tool holder
	tst	bx
	jz	noBlock
	call	ObjSwapLock
	push	bx
	call	GenFindParent			; find tool area it's in
	mov	cx, bx
	mov	dx, si
	pop	bx
	call	ObjSwapUnlock
noBlock:
	tst	bx
	pop	bx, si
	jz	done
	call	ToolGetToolboxNumber
	mov	cx, ax
	clr	dx				;no indeterminates
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ToolCallChildObject
done:

	.leave
	ret
RedoPlacementListStatus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlInternalLocateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Respond to events happening in Group placement list

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_TOOL_CONTROL_INTERNAL_PLACEMENT_LIST

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolControlInternalLocateCommon	method dynamic GenToolControlClass,
				MSG_GEN_TOOL_CONTROL_INTERNAL_PLACEMENT_LIST

	mov	bp, CCO_LAST
	call	ReLocateToolGroup
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	UserCallApplication
	ret
GenToolControlInternalLocateCommon	endm



ReLocateToolGroup	proc	near
	class	GenToolControlClass
	push	bp				; save position to use

	mov	di, offset ToolPlacementList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ToolCallChildObject		; get toolbox to use in ax

	; Find new toolbox to use
	;
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	si, ds:[di].GTCI_toolboxList
	mov	si, ds:[si]			; dereference the chunk handle
	shl	ax				; change to index
	shl	ax
	shl	ax
	add	si, ax	
	movdw	cxdx, ds:[si].TI_object		; cx:dx = new toolbox to use
	mov	bx, ds:[LMBH_handle]
	mov     al, RELOC_HANDLE
	call    ObjDoRelocation
	pop	si

	pop	bp				; get position in bp

	push	si
	call	ToolGetCurToolGroup		; fetch current tool holder
	tst	bx
	jz	afterMoved

						; move it, to new obj & position
	or	bp, mask CCF_MARK_DIRTY
	call	GenReParentObject

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

afterMoved:
	pop	si
	call	RedoPositionStatus
	ret
ReLocateToolGroup	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCorrespondingChildNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the child number corresponding to the passed "visible"
		child number.

CALLED BY:	GLOBAL
PASS:		ax - running count of children
		bp - visible child
RETURN:		carry set to abort
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCorrespondingChildNumber	proc	far
	.enter
EC <	tst	bp							>
EC <	ERROR_S	-1							>
	inc	ax
	call	CheckIfVisibleChild
	jnc	exit			;Exit if child not visible
	dec	bp
EC <	ERROR_NC	-1						>
	js	exit			;
	clc
exit:
	.leave
	ret
FindCorrespondingChildNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVisibleChildNumberToActualChildNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the passed "visible tool" number to the actual
		gen child it would represent.

CALLED BY:	GLOBAL
PASS:		*ds:si - tool control
		bp - child number of current tool box
RETURN:		bp - gen child #
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertVisibleChildNumberToActualChildNumber	proc	near
	uses	ax, bx, cx, dx, di, si
	class	GenClass
	.enter
	push	bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, offset ToolPlacementList
	call	ToolCallChildObject		; get toolbox # to use in ax
	pop	bp

	call	ToolGetToolboxByNumber
EC <	tst	bx							>
EC <	ERROR_Z	TOOL_CONTROL_ERROR					>

	call	ObjSwapLock
	push	bx
	clr	ax
	push	ax			;Start at first child
	push	ax
	mov	bx, offset GI_link
	push	bx
NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx, offset FindCorrespondingChildNumber
	push	bx
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	mov	ax, -1
	call	ObjCompProcessChildren
EC <	ERROR_NC	TOOL_CONTROL_ERROR				>
	mov_tr	bp, ax
	pop	bx
	call	ObjSwapUnlock
	.leave
	ret
ConvertVisibleChildNumberToActualChildNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlInternalNudgeBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Respond to events happening in Group placement list

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_TOOL_CONTROL_INTERNAL_NUDGE_BACK

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolControlInternalNudgeBack	method dynamic GenToolControlClass,
				MSG_GEN_TOOL_CONTROL_INTERNAL_NUDGE_BACK
	call	GetCurrentPosition
	tst	dx
	jz	done
	tst	bp			;If we are already the first child,
	jz	done			; just exit
	dec	bp
	call	ConvertVisibleChildNumberToActualChildNumber
	call	ReLocateToolGroup
done:
	ret
GenToolControlInternalNudgeBack	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolControlInternalNudgeForward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Respond to events happening in Group placement list

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_TOOL_CONTROL_INTERNAL_NUDGE_FORWARD

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolControlInternalNudgeForward	method dynamic GenToolControlClass,
				MSG_GEN_TOOL_CONTROL_INTERNAL_NUDGE_FORWARD
	call	GetCurrentPosition
	tst	dx
	jz	done
	inc	bp
	cmp	bp, dx			;If already at end, exit
	jae	done

	call	ConvertVisibleChildNumberToActualChildNumber
	call	ReLocateToolGroup
done:
	ret
GenToolControlInternalNudgeForward	endm



COMMENT @----------------------------------------------------------------------
FUNCTION:	RedoPositionStatus
DESCRIPTION:	Set state, i.e. current exlusive, of Group Position value,
		based on current controller.
CALLED BY:	INTERNAL
PASS:		*ds:si - GenToolControl
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@
RedoPositionStatus	proc	near	uses	ax, bx, cx, dx, si, di, bp
	.enter
	call	GetCurrentPosition
	tst	dx
	jz	disableBoth

	; Set "Nudge backward" button enabled if object isn't first child.
	;
	push	dx, bp
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	tst	bp
	jz	haveBackwardStatus
	mov	ax, MSG_GEN_SET_ENABLED
haveBackwardStatus:
	mov	dl, VUM_NOW
	mov	di, offset ToolNudgeBackward
	call	ToolCallChildObject
	pop	dx, bp

	inc	bp
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	cmp	dx, bp
	jz	haveForwardStatus
	mov	ax, MSG_GEN_SET_ENABLED
haveForwardStatus:
	mov	dl, VUM_NOW
	mov	di, offset ToolNudgeForward
	call	ToolCallChildObject

done:
	.leave
	ret

disableBoth:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	mov	di, offset ToolNudgeBackward
	call	ToolCallChildObject

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	mov	di, offset ToolNudgeForward
	call	ToolCallChildObject
	jmp	short done

RedoPositionStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfVisibleChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry set if the passed object is "visible" (if it 
		is usable and has children)

CALLED BY:	GLOBAL
PASS:		*ds:si - obj
RETURN:		carry set if visible
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfVisibleChild	proc	near	uses	ax, cx, dx, bp
	.enter
	mov	ax, MSG_GEN_GET_USABLE
	call	ObjCallInstanceNoLock
	jnc	notUsable

	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjCallInstanceNoLock
	tst	dx
	jz	notUsable
	stc
notUsable:
	.leave
	ret
CheckIfVisibleChild	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindVisibleChildrenCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the passed child.

CALLED BY:	GLOBAL
PASS:		AX - # visible children found so far
		CX:DX - OD of child to find
RETURN:		ax - updated
		BP updated to be current child number if CX:DX = current child
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindVisibleChildrenCallBack	proc	far
	.enter
	cmp	dx, si
	jne	notCurrent
	cmp	cx, ds:[LMBH_handle]
	jne	notCurrent
EC <	cmp	bp, -1							>
EC <	ERROR_NZ	TOOL_FOUND_TWICE				>
	mov	bp, ax			;BP <- child number
notCurrent:

;	We increment the count in AX if the current child is "visible" - if it
;	is usable, and if it has children.

	call	CheckIfVisibleChild	;Carry set if child visible
	adc	ax, 0			;Increment AX if carry set

;	Carry should be clear here to avoid aborting enum
EC <	ERROR_C	TOOL_CONTROL_ERROR					>
	.leave
	ret
FindVisibleChildrenCallBack	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetCurrentPosition

DESCRIPTION:	Find position of current ToolGroup within its toolbox

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl

RETURN:		dx	- # of visible children (tool groups with tools) 
			  within toolbox, or 0 if not found, or toolgroup
			  not found.
		bp	- position of toolgroup among visible items
DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/92		Initial version
------------------------------------------------------------------------------@
GetCurrentPosition	proc	near	uses ax, bx, cx, di, si
	class	GenClass
	.enter
	push	bx, si
	call	ToolGetCurToolGroup		; find current tool holder
	movdw	cxdx, bxsi
	pop	bx, si
	tst	cx
	jz	notFound

;	Find out what tool box the tool group is under.

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, offset ToolPlacementList
	push	cx, dx
	call	ToolCallChildObject		; get toolbox # to use in ax
	pop	cx, dx

	call	ToolGetToolboxByNumber		
	tst	bx
	jz	notFound

;	Get the "visible" position of the toolgroup

	call	ObjSwapLock
	push	bx

EC <	mov	bp, -1							>
	clr	ax
	push	ax			;Start at first child
	push	ax
	mov	bx, offset GI_link
	push	bx
NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx, offset FindVisibleChildrenCallBack
	push	bx
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren

;	Returns BP = child number
;	Returns AX = # visible children

	mov_tr	dx, ax
	cmp	bp, -1
	jnz	unlock
	clr	dx			;If child not found, just branch
unlock:

	pop	bx
	call	ObjSwapUnlock
done:
	.leave
	ret


notFound:
	clr	bp				; if toolgroup not found in
	clr	dx				; toolbox, return 0 children
	jmp	short done

GetCurrentPosition	endp



COMMENT @----------------------------------------------------------------------

MESSAGE:	GenToolControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GenToolControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of GenToolControlClass

	ax - The message

	ss:bp - GenControlUpdateUIParams
    		GCUUIP_manufacturer         ManufacturerID
    		GCUUIP_changeType           word
    		GCUUIP_dataBlock            hptr
    		GCUUIP_features             word 
    		GCUUIP_toolboxFeatures      word
    		GCUUIP_childBlock           hptr
    		GCUUIP_toolBlock	    optr


	dataBlock has format NotifyGenControlStatusChange:
		NGCS_meta		NotificationDataBlockHeader
		NGCS_controller		optr
		NGCS_statusChange	GenControlStatusChange

	GenControlStatusChange flags:
        	GCSF_TOOLBOX_PLACEMENT_CHANGED:1
		GCSF_ATTACHED:1
        	GCSF_DETACHED:1
        	GCSF_HIGHLIGHTED_TOOLGROUP_SELECTED:1
        	GCSF_TOOLBOX_FEATURES_CHANGED:1
        	GCSF_NORMAL_FEATURES_CHANGED:1

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version

------------------------------------------------------------------------------@
GenToolControlUpdateUI	method dynamic GenToolControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; If not updating tool dialog, nothing to do -- exit.
	;
	test	ss:[bp].GCUUIP_features, mask GTCF_TOOL_DIALOG
	jz	exit

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	push	bx
	call	MemLock
	mov	es, ax

	cmp	ss:[bp].GCUUIP_manufacturer, MANUFACTURER_ID_GEOWORKS
	jne	done
	cmp	ss:[bp].GCUUIP_changeType, GWNT_GEN_CONTROL_NOTIFY_STATUS_CHANGE
	jne	done

	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData
				; fetch optr of controller sending update
	mov	cx, es:[NGCS_controller].handle
	mov	dx, es:[NGCS_controller].chunk

if	(0)
	test	es:[NGCS_statusChange], mask GCSF_ATTACHED
	jnz	redoGroupList
	test	es:[NGCS_statusChange], mask GCSF_DETACHED
	jnz	controllerDead
endif
	test	es:[NGCS_statusChange], mask GCSF_TOOLBOX_FEATURES_CHANGED
	jnz	featuresChanged
	test	es:[NGCS_statusChange], mask GCSF_HIGHLIGHTED_TOOLGROUP_SELECTED
	jnz	toolgroupSelected
done:
	pop	bx
	call	MemUnlock
exit:
	ret

if	(0)
controllerDead:
	; See if controller of group we're currently showing properties of
	;
	call	TestCompareAgainstCurController
	jne	redoGroupList		; if not, just redraw group list

	; If so, nuke reference to that controller, pick new one & redraw
	;
	mov	ds:[bx].TGTCI_curController.handle, 0
	mov	ds:[bx].TGTCI_curController.chunk, 0
	call	RedoFeatureListStatus	; ALWAYS redo Features, placement,
	call	RedoPlacementListStatus ; since may be going empty
	call	RedoPositionStatus
redoGroupList:
	call	ToolPurgeGroupList	; purge group list, so will be redrawn
	call	ToolEnsureCurController	; ensure one selected
	jmp	short done
endif

featuresChanged:
	; See if controller of group we're currently showing properties of
	;
	call	TestCompareAgainstCurController
	jne	done

	; If so, redraw Feature lists
	;
	call	RedoFeatureListStatus
	jmp	short done

toolgroupSelected:
	push	si
	call	ToolGetToolGroupForController	; Get ToolGroup OD
	mov	cx, bx
	mov	dx, si
	pop	si
	call	ToolGetToolGroupNumber		; Get # of toolgroup
	mov	cx, ax				; Change "Manage Tools" dialog
						; to indicate that group
	push	cx
	call	GroupListSetSingleSelection
	pop	cx
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	mov	di, offset ToolGroupList
	call	ToolCallChildObject
	jmp	short done

GenToolControlUpdateUI	endm


COMMENT @----------------------------------------------------------------------
FUNCTION:	TestCompareAgainstCurController

DESCRIPTION:	Test to see if optr passed is the controller whose tool group
		is currently selected in the Tool Layout dialog box

CALLED BY:	INTERNAL
		GenToolControlUpdateUI

PASS:		*ds:si	- GenToolControl object
		cx:dx	- optr of GenController to test
RETURN:		zero flag	- set if match
		ds:bx	- ptr to TempGenToolControlInstance
DESTROYED:	nothing
------------------------------------------------------------------------------@
TestCompareAgainstCurController	proc	near	uses	ax
	.enter
	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData
	cmp	cx, ds:[bx].TGTCI_curController.handle
	jne	done
	cmp	dx, ds:[bx].TGTCI_curController.chunk
done:
	.leave
	ret
TestCompareAgainstCurController	endp

COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolCallCurController

DESCRIPTION:	Call current controller w/message & data passed

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
		ax, cx, dx, bp - message, data to call with
RETURN:		zero flag - zero if no current controller, non-zero if
			    one exists & was called
		ax, cx, dx, bp - data returned per above message
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolCallCurController	proc	near	uses	bx, si, di
	.enter
	push	ax
	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData
	pop	ax
	mov	si, ds:[bx].TGTCI_curController.chunk
	tst	si
	jz	done
	mov	bx, ds:[bx].TGTCI_curController.handle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; We need to set the zero flag to non-zero status *and*
	; preserve the state of the carry from the message call.
	; Since bx is non-zero and not -1, doing an 'inc bx'
	; is the best way I can think of to accomplish this.
	; The new way is OK because bx isn't a return value,
	; and after the above ObjMessage is a handle, and therefore
	; not -1, the only value that this -- um -- hack would have
	; a problem with.
	; It is smaller and faster than the old way of:
	;					;bytes/cycles
	;	push	ax			;1/15
	;	lahf				;1/4
	;	and	ah (not mask CPU_ZERO)	;3/4
	;	sahf				;1/4
	;	pop	ax			;1/12
	;					;total=7/39
	; versus:
	;	inc	bx			;total=1/2
	; Not to mention which the version before that was ugly
	; and had a nasty bug because it did:
	;	or	ah, 04h
	; which at the very least should have been:
	;	and	ah, (not 40h)
	;
EC <	pushf					;preserve flags>
EC <	cmp	bx, -1				;a problematic value?>
EC <	ERROR_E	GEN_TOOL_CONTROL_INTERNAL_ERROR	;>
EC <	popf					;restore flags>
	inc	bx				;set non-zero status
done:
	.leave
	ret
ToolCallCurController	endp


COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolEnsureCurController

DESCRIPTION:	Check to see whether there is a currently selected
		controller or not -- if not, & there is at least one
		active controller, select it, by giving the Item
		that represents it the exclusive within the list.
		This will result in the status of its Features being
		displayed, & options presented for what the user can
		do with them.

CALLED BY:	INTERNAL
		GenToolControlGetNumberOfEntries
		GenToolControlUpdateUI

PASS:		*ds:si	- GenToolControl object
RETURN:		
DESTROYED:	ax, bx, cx, dx, di, bp
------------------------------------------------------------------------------@
ToolEnsureCurController	proc	near	uses	si
	.enter
	mov	ax, TEMP_GEN_TOOL_CONTROL_INSTANCE
	call	ObjVarDerefData
	tst	ds:[bx].TGTCI_curController.handle
	jnz	done

	call	ToolGetNumberOfControllers	; cx = # of entries
	jcxz	done

	clr	cx				; give exclusive to first entry
	call	GroupListSetSingleSelection
done:
	.leave
	ret
ToolEnsureCurController	endp

GroupListSetSingleSelection	proc	near
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				; no indeterminates
	mov	di, offset ToolGroupList
;	push	cx
	call	ToolCallChildObject
;	pop	cx

;	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
;	call	ToolCallChildObject

	; Force list to send out new status, so we'll update the other lists.
	;
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	mov	di, offset ToolGroupList
	call	ToolCallChildObject
	ret
GroupListSetSingleSelection	endp


COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolPurgeGroupList

DESCRIPTION:	Force group list to redraw the list of controllers, presumably
		because they've changed.

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
RETURN:		nothing
DESTROYED:	ax, cx, dx, di
------------------------------------------------------------------------------@
ToolPurgeGroupList	proc	near
addParams	local AddVarDataParams
addData		local optr
	.enter
	call	ToolGetNumberOfControllers	; cx = # of entries
	; cx = # of entries in list
	;
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, offset ToolGroupList
	push	bp
	call	ToolCallChildObject
	pop	bp

	; Make sure this object is set up as destination of the visibility
	; notification mechanism.
	;
	mov	bx, ds:[LMBH_handle]
	mov	addData.handle, bx
	mov	addData.chunk, si
	mov	ax, ss
	mov	addParams.AVDP_data.segment, ax
	lea	ax, addData
	mov	addParams.AVDP_data.offset, ax
	mov	addParams.AVDP_dataSize, size optr
	mov	addParams.AVDP_dataType, ATTR_GEN_VISIBILITY_DESTINATION

	mov	dx, size AddVarDataParams
	push	bp
	lea	bp, addParams
	mov	ax, MSG_META_ADD_VAR_DATA
	call	ToolCallChildObject
	pop	bp
	.leave
	ret
ToolPurgeGroupList	endp


COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolGetChildBlock

DESCRIPTION:	Fetch handle of block that holds all the objects that
		make up the "Manage Tools" dialog box.

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
RETURN:		bx	- handle of child block
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolGetChildBlock	proc	near	uses	ax
	.enter
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	bx, ds:[bx].TGCI_childBlock
	.leave
	ret
ToolGetChildBlock	endp

COMMENT @----------------------------------------------------------------------
FUNCTION:	ToolCallChildObject

DESCRIPTION:	Call one of the objects that make up the "Manage Tools"
		dialog box.

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenToolControl object
		ax, cx, dx, bp - message, data to call with
RETURN:		ax, cx, dx, bp - per message above
DESTROYED:	nothing
------------------------------------------------------------------------------@
ToolCallChildObject	proc	near	uses	bx, si, di
	; di - offset of object to call
	;
	.enter
	call	ToolGetChildBlock
	mov	si, di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
ToolCallChildObject	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenToolControlSaveOptions

DESCRIPTION:	Save the state of the toolboxes in the .ini file.  We write
		out an ASCII string which looks like:

		BACE0DFG0

		Each A-Z character indicates a tool holder, A=#0, Z=#25 in the
		list of tool holders.  The first group before the "0" is the
		ordering of holders within toolbox #0, the second for 
		toolbox #1, & so on.  The string is ASCIIZ.

PASS:
	*ds:si - instance data
	es - segment of GenToolControlClass

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
	Doug	7/92		Initial version

------------------------------------------------------------------------------@
GenToolControlSaveOptions	method dynamic	GenToolControlClass,
							MSG_META_SAVE_OPTIONS
categoryBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
keyBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
dataBuffer	local	2*MAX_TOOL_HOLDERS dup (byte)
toolControl	local	optr
	ForceRef categoryBuffer
	ForceRef keyBuffer
	.enter

	push	bp
	mov	di, offset GenToolControlClass
	call	ObjCallSuperNoLock
	pop	bp

	; Save optr of this tool control object where it can be accessed later
	;
	mov	ax, ds:[LMBH_handle]
	mov	toolControl.handle, ax
	mov	toolControl.chunk, si

	; We need to walk through all of the toolbox areas, & save off the
	; list of tool holders found in each.

	call	ToolGetNumberOfToolboxes
	clr	ax			; start w/toolbox #0
	lea	dx, dataBuffer		; where to start putting data
toolboxLoop:
	push	ax, cx, si
	call	ToolGetToolboxByNumber
	call	ObjSwapLock
	push	bx

	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset GI_link	; Pass offset to LinkPart
	push	bx
NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx, offset GenToolControlSaveOptionsCallBack
	push	bx
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
	pop	bx
	call	ObjSwapUnlock

	mov	di, dx
	mov	{byte} ss:[di], -1	; mark end of toolbox group
	inc	dx
	pop	ax, cx, si
	inc	ax
	loop	toolboxLoop

	push	bp
	lea	ax, dataBuffer
	sub	dx, ax			; dx = size of buffer
	push	dx
	call	GenToolControlIniPrepCommon
	pop	bp
	call	InitFileWriteData		; Write 'er out.
	pop	bp

	; NOTE:  DS is trashed here, curtesy of GenToolControlIniPrepCommon.

	.leave
	ret

GenToolControlSaveOptions	endm


GenToolControlSaveOptionsCallBack	proc	far
	.enter inherit GenToolControlSaveOptions

	; ss:bp = local data
	; ss:dx = offset to write option data to

	push	dx

	push	bp
	mov	ax, MSG_GEN_GET_USABLE	; USABLE?
	call	ObjCallInstanceNoLock
	pop	bp

	pushf				; Save carry flag - set if USABLE
	mov	cx, ds:[LMBH_handle]	; figure out which holder this is
	mov	dx, si
	push	si
	mov	bx, toolControl.handle	; switch back to tool control to make
	mov	si, toolControl.chunk	; lookup request
	call	ObjSwapLock
	call	ToolGetToolGroupNumber
	call	ObjSwapUnlock
	pop	si
	popf				; get carry flag - set if USABLE
	jnc	haveUsable
	or	al, 80h			; Set high bit if USABLE.  (YES, limits
					; # of tool groups to 127)
haveUsable:
	pop	dx
	cmp	ax, -1
	je	done
	mov	di, dx
	mov	ss:[di], al
	inc	dx			; bump pointer
done:
	clc				; continue, i.e. call all children.
	.leave
	ret
GenToolControlSaveOptionsCallBack	endp

GenToolControlCode ends

endif			; NO_CONTROLLERS ++++++++++++++++++++++++++++++++++++

