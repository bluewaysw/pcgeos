COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:    	Navigation Library	
MODULE:		Navigate controller 
FILE:		navcontrol.asm

AUTHOR:		Alvin Cham, Sep 27, 1994

ROUTINES:
	Name			Description
	----			-----------

    	class methods:
    	--------------

    	NCMetaAttach	    	- attaching the new controller, and
    	    	    	    	handle saved state

    	NCMetaDetach	    	- detaching the new controller

    	NCGenControlGetInfo 	- fill in the info for the 
    	    	    	    	NavigateControlClass

    	NCGenControlUpdateUI	- update the navigate controller UI

    	class procedures:
    	-----------------

    	NCUpdateNormalUI    	- update the UI

    	NCUpdatePrevNext    	- update the 'Prev' and 'Next' triggers

    	NCUpdatePrevNextLow 	- low level procedure for updating the
    	    	    	    	'Prev' and 'Next' triggers

    	NCSetStateLow	    	- low level of setting an UI object state

    	NCUpdateMainPageTrigger	- update the main page trigger

    	NCUpdateGoBackTriggers	- update the 'go back' trigger

    	NCUpdateForwardTriggers	- update the 'go forward' trigger

    	NCDuplicateStateBlock	- duplicate a state block

    	NCCopyNotificationDataToStack
    	    	    	    	- put notification data to the local stack

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/27/94   	Initial revision


DESCRIPTION:
	Code for the navigation controller

	$Id: navcontrol.asm,v 1.1 97/04/05 01:24:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NavigateControlCode	    segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCMetaAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle attaching of the new controller, including
    	    	handling saved state.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
    	    	cx  	= AppAttachFlags
    	    	dx  	= Handle of AppLaunchBlock, or 0 if none
    	    	bp  	= Handle of extra state block, or 0 if none

RETURN:	    	nothing		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCMetaAttach	method dynamic NavigateControlClass, 
					MSG_META_ATTACH
	uses	ax, cx, dx, bp, si, es
	.enter

    	; clear "detach received" vardata, if any

    	mov 	ax, TEMP_NAVIGATION_DETACH_RECEIVED
    	call	ObjVarFindData
    	jnc 	checkForState
    	call	ObjVarDeleteDataAt
    	mov 	ax, HINT_INITIATED
    	call	ObjVarDeleteData    	    ; remove hints

checkForState:
    	tst 	bp
    	jz  	noState

    	; copy the state block into a new object block
    	call	NCDuplicateStateBlock

noState:
    	; duplicate the history list template
    	mov 	bx, handle NavigateTemplate
    	clr 	ax, cx	    	    	    ; current thread, geode
    	call	ObjDuplicateResource	    ; bx = duplicated block

    	mov 	di, ds:[si]
    	add 	di, ds:[di].NavigateControl_offset

EC  <	tst 	ds:[di].NCI_historyBlock    	    	    	>
EC  <	ERROR_NZ    	-1  	    	    	    	    	>
    	mov 	ds:[di].NCI_historyBlock, bx

    	; set its output to be the NavigateControlClass object

    	mov 	cx, ds:[LMBH_handle]
    	mov 	dx, si
    	mov 	si, offset  NavigateHistoryGroup    ; ^lbx:si =
						    ; histroy obj
    	mov 	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
    	mov 	di, mask    MF_FIXUP_DS
    	call	ObjMessage

    	; add the interaction as the last child of the application,
	; and then set it usable
    	movdw	cxdx, bxsi  	    	    	    ; ^lcx:dx =
						    ; history obj
    	clr 	bx
    	call	GeodeGetAppObject   	    	    ; ^lbx:si = appObj
    	mov 	ax, MSG_GEN_ADD_CHILD
    	mov 	bp, CCO_LAST
    	mov 	di, mask MF_FIXUP_DS
    	call	ObjMessage

    	movdw	bxsi, cxdx
    	mov 	dl, VUM_DELAYED_VIA_UI_QUEUE
    	mov 	ax, MSG_GEN_SET_USABLE
    	mov 	di, mask MF_FIXUP_DS
    	call	ObjMessage

	.leave
    	; call	its superclass
    	mov 	di, offset  NavigateControlClass
    	call	ObjCallSuperNoLock

	ret
NCMetaAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the history interaction, add vardata type
    	    	TEMP_CONVIEW_DETACH_RECEIVED and callsuper

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCMetaDetach	method dynamic NavigateControlClass, 
					MSG_META_DETACH
	uses	ax, cx, dx, bp
	.enter

    	push	si
    	clr 	bx
    	xchg	bx, ds:[di].NCI_historyBlock
    	mov 	si, offset NavigateHistoryGroup
EC  <	call	ECCheckOD   	    	    	    	>

    	mov 	ax, MSG_GEN_DESTROY
    	clr 	bp
    	mov 	dl, VUM_NOW
    	clr 	di
    	call	ObjMessage
    	pop 	si

    	mov 	ax, TEMP_NAVIGATION_DETACH_RECEIVED
    	clr 	cx  	    	    	    ; cx = no extra data
    	call	ObjVarAddData	    	    	

    	.leave
    	mov 	di, offset  NavigateControlClass
    	call	ObjCallSuperNoLock

	ret
NCMetaDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGenControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the NavigationControlClass

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #

    	    	cx:dx	= GenControlBuildInfo structure to fill in
    	    	
RETURN:		cx:dx	= filled in
DESTROYED:	bx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGenControlGetInfo	method dynamic NavigateControlClass, 
					MSG_GEN_CONTROL_GET_INFO

    	mov 	si, offset  NC_dupInfo
    	mov 	es, cx
    	mov 	di, dx	    	    	    ; es:di = dest
    	segmov	ds, cs
    	mov 	cx, (size GenControlBuildInfo)/(size word)
    	rep 	movsw
CheckHack   <((size GenControlBuildInfo) and 1) eq 0>
    	ret
NCGenControlGetInfo	endm

;***************************************************************************
;   GenControlBuildInfo structure information
;***************************************************************************

NC_dupInfo  GenControlBuildInfo	    <
    	mask GCBF_SUSPEND_ON_APPLY,
;    	mask GCBF_ALWAYS_UPDATE or \
;	mask GCBF_ALWAYS_ON_GCN_LIST or \
;	mask GCBF_IS_ON_ACTIVE_LIST or \
;	mask GCBF_ALWAYS_INTERACTABLE,
					; GCBI_flags
	NC_InitFileKey,			; GCBI_initFileKey
	NC_gcnList,			; GCBI_gcnList
	length NC_gcnList,		; GCBI_gcnCount
	NC_notifyTypeList,		; GCBI_notificationList
	length NC_notifyTypeList,	; GCBI_notificationCount
	NavigateName,			; GCBI_controllerName

	NavigateUI,			; GCBI_dupBlock
	NC_childList,			; GCBI_childList
	length NC_childList,		; GCBI_childCount
	NC_featuresList,		; GCBI_featuresList
	length NC_featuresList,		; GCBI_featuresCount
	NC_DEFAULT_FEATURES,		; GCBI_features

	NavigateToolUI,			; GCBI_toolBlock
	NC_toolList,			; GCBI_toolList
	length NC_toolList,		; GCBI_toolCount
	NC_toolFeaturesList,		; GCBI_toolFeaturesList
	length NC_toolFeaturesList,	; GCBI_toolFeaturesCount
	NC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

NC_InitFileKey	char	"navigation", 0

NC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_NOTIFY_NAVIGATE_ENTRY_CHANGE>

NC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_NAVIGATE_ENTRY_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_NAVIGATE_DELETE_ENTRY>

NC_childList	GenControlChildInfo	\
	<offset NavigateGoBackHistTrigger,
		mask NCF_BACK,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset NavigateGoForwardHistTrigger,
		mask NCF_FORWARD,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset NavigateMainPageTrigger,
		mask NCF_MAIN_PAGE,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset NavigateHistoryTrigger,
		mask NCF_HISTORY,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset NavigatePageTurnGroup,
		mask NCF_PREV_NEXT,
    		mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

NC_featuresList GenControlFeaturesInfo \
	<offset NavigateGoForwardHistTrigger, 
		GoForwardHistTriggerName,
		0>,
	<offset NavigateGoBackHistTrigger, 
		GoBackHistTriggerName,
		0>,
	<offset NavigateHistoryTrigger,
		HistoryGroupName,
		0>,
	<offset NavigatePageTurnGroup,
		NextPrevPageTriggerName,
		0>,
	<offset NavigateMainPageTrigger,
		MainPageTriggerName,
		0>

NC_toolList	GenControlChildInfo	\
	<offset NavigateToolGoBackHistTrigger,
		mask NCTBF_BACK,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset NavigateToolGoForwardHistTrigger,
		mask NCTBF_FORWARD,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset NavigateToolMainPageTrigger,
		mask NCTBF_MAIN_PAGE,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset NavigateToolHistoryTrigger,
		mask NCTBF_HISTORY,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset NavigateToolPageTurnGroup,
		mask NCTBF_PREV_NEXT,
		mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.
;
NC_toolFeaturesList GenControlFeaturesInfo \
	<offset NavigateToolGoForwardHistTrigger, 
		GoForwardHistTriggerName,
		0>,
	<offset NavigateToolGoBackHistTrigger, 
		GoBackHistTriggerName,
		0>,
	<offset NavigateToolHistoryTrigger,
		HistoryGroupName,
		0>,
	<offset NavigateToolPageTurnGroup,
		NextPrevPageTriggerName,
		0>,
	<offset NavigateToolMainPageTrigger,
		MainPageTriggerName,
		0>

;*********************************************************************
;   	End of GenControlBuildInfo structures infomation
;*********************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGenControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the navigation controller's UI components via a
    	    	notification structure.

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
    	    	ss:bp	= GenControlUpdateUIParams

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGenControlUpdateUI	method dynamic NavigateControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI
    	.enter

    	; see if we've already received a detach
    	mov 	ax, TEMP_NAVIGATION_DETACH_RECEIVED
    	call	ObjVarFindData
    	jc  	done

    	mov 	cx, ss:[bp].GCUUIP_changeType
    	cmp 	cx, GWNT_NAVIGATE_ENTRY_CHANGE
    	jne 	done

    	call	NCUpdateNormalUI    	
done:
    	.leave
	ret
NCGenControlUpdateUI	endm

;--------------------------------------------------------------------------
;   Class procedures
;--------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUpdateNormalUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	En/Disable the normal UI and update history list

CALLED BY:	INTERNAL    NCGenControlUpdateUI
PASS:		*ds:si	= a NavigateControlClass object
    	    	ss:bp	= GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
    If the update is sent as a result of a simple context change, we
    can update only features or tools, depending on which are
    interactible.

    GCUUIP_features 	    word    ; from TEMP_GEN_CONTROL_INSTANCE
    	    	    	    	    ; but clear if GCIF_NORMAL_UI not
    	    	    	    	    ; set in TEMP_GEN_CONTROL_INSTANCE
    
    GCUUIP_toolboxFeatures  word    ; from TEMP_GEN_CONTROL_INSTANCE
    	    	    	    	    ; but clear if GCIF_TOOLBOX_UI not
    	    	    	    	    ; set in TEMP_GEN_CONTROL_INSTANCE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUpdateNormalUI	proc	near
	uses	bp
NAVIGATION_LOCALS
    	mov 	bx, ss:[bp].GCUUIP_dataBlock	    ; get handle
	.enter

    	; Is this a NULL notification?  We don't do anything here for
	; NULL notification.
    	tst 	bx
    	jz  	done

    	; get notification data and put it into locals
    	call	NCCopyNotificationDataToStack	
    	; ax = NotifyNavContextChangeFlags

    	; get controller attributes
    	call	NCGetToolBlockAndToolFeaturesLocals
    	call	NCGetChildBlockAndFeaturesLocals

    	; now, update the enabled state of "Prev" and "Next" triggers
	; and the main page trigger
    	call	NCUpdatePrevNext
    	call	NCUpdateMainPageTrigger

    	; add the page now being displayed to the history list, if
	; necessary 
    	test	ax, mask NNCCF_retnWithState	; restoring from state
    	jnz 	reDrawList  	    	    	; reDraw only
    	test	ax, mask NNCCF_updateHistory	; need to update?
    	jz  	reDrawList
    	call	NCUpdateHistoryForLink
    
reDrawList:
    	call	NCRedrawHistoryList

    	; update the go back/go forward trigger AFTER the history list
	; has been updated 
    	call	NCUpdateGoBackTriggers
    	call	NCUpdateGoForwardTriggers   

done:
	.leave
	ret
NCUpdateNormalUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUpdatePrevNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables or disables the "Prev" and "Next" triggers, as
    	    	specified. 

CALLED BY:	
PASS:		ss:bp	= inherited locals
    	    	    	    childBlock
    	    	    	    toolBlock
    	    	    	    features/tools
    	    	ax  	= NotifyNavContextChangeFlags
RETURN:		nothing
DESTROYED:	bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUpdatePrevNext	proc	near
	uses	si
NAVIGATION_LOCALS
	.enter inherit

	test	ss:features, mask NCTBF_PREV_NEXT 
	jz	updateTool

	;
	; Update next/prev features
	;
	mov	bx, ss:childBlock
	mov	si, offset NavigatePreviousPageTrigger
	mov	di, offset NavigateNextPageTrigger
	call	NCUpdatePrevNextLow

updateTool:		

	;
	; Update next/prev tools, if the tool is present
	;
	test	ss:toolFeatures, mask NCTBF_PREV_NEXT 	
	jz	done
	mov	bx, ss:toolBlock
	mov	si, offset NavigateToolPreviousPageTrigger
	mov	di, offset NavigateToolNextPageTrigger
	call	NCUpdatePrevNextLow

done:
	.leave
	ret
NCUpdatePrevNext		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUpdatePrevNextLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level procedure for enabling/disabling the prev/next
    	    	tools or triggers 

CALLED BY:	NCUpdatePrevNext
PASS:		ax - NotifyNavContextChangeFlags
		bx - child block
		si - chunk handle of prev tool/trigger
		di - chunk handle of next tool/trigger
RETURN:		nothing
DESTROYED:	cx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUpdatePrevNextLow		proc	near
	uses	ax, bp
	.enter

	tst	bx			; UI not built yet?
	jz	done			

    	test	ax, mask NNCCF_pageTriggerStateChanged	; is there a
							; state changed?
    	jz  	done

	mov	cx, ax
	test	cx, mask NNCCF_prevEnabled
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	setPrevState
	mov	ax, MSG_GEN_SET_NOT_ENABLED

setPrevState:
	push	di
	call	NCSetStateLow
	pop	si
		
	mov	ax, MSG_GEN_SET_ENABLED
	test	cx, mask NNCCF_nextEnabled
	jnz	setNextState
	mov	ax, MSG_GEN_SET_NOT_ENABLED

setNextState:
	call	NCSetStateLow
done:		
	.leave
	ret
NCUpdatePrevNextLow		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCSetStateLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level of setting (enabling/disabling) an UI object
    	    	state

CALLED BY:	UTILITY
PASS:		ax  	= message (enabling or disabling)
    	    	bx  	= Handle of child block
		si - chunk handle of trigger
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCSetStateLow	proc	near

	tst	bx
	jz	done
EC <	call	ECCheckMemHandleNS			>
	push	cx, bp
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage
	pop	cx, bp
done:
		ret
NCSetStateLow	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUpdateMainPageTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables or disables the "Main Page" trigger, as
    	    	specified. 

CALLED BY:	
PASS:		ss:bp	- inherited locals
			  childBlock
			  toolBlock
			  features/tools
		ax	- NotifyNavContextChangeFlags
RETURN:		nothing
DESTROYED:	bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We or the tool/feature flags into cx so that we'll know
	whether there are prev/next tools or features (or both).

	Then we enable/disable as specified by the flags in al.
	The only messiness is that we need to check that each
	trigger is an included tool/feature before we send it
	a message.  The "CheckAnd" routines are only useful if
	an object hasn't yet been built.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUpdateMainPageTrigger		proc	near
	uses	ax, si
NAVIGATION_LOCALS
	.enter inherit

	mov	cx, ax

    	; if index == -1, then we have no entry, then we don't want to
	; enable this trigger
    	call	NCGetIndex  	    	    	; bx = index
    	inc 	bx  	    	    ; if bx == -1, then we have no index
    	tst 	bx  	    	    
    	jnz 	notEmpty
    	
    	; no history entry, so we can just set the flag NNCCF_displayMain
	; to disable it here.
    	BitSet	cx, NNCCF_displayMain

notEmpty:
	test	ss:features, mask NCF_MAIN_PAGE
	jz	updateTool

	; Update main page features
	mov	bx, ss:childBlock
	mov	si, offset NavigateMainPageTrigger
	mov	ax, MSG_GEN_SET_ENABLED
	test	cx, mask NNCCF_displayMain
	jz	setFeature
	mov	ax, MSG_GEN_SET_NOT_ENABLED

setFeature:
	call	NCSetStateLow
updateTool:		

	; Update next/prev tools, if the tool is present
	test	ss:toolFeatures, mask NCTBF_MAIN_PAGE
	jz	done
	mov	bx, ss:toolBlock
	mov	si, offset NavigateToolMainPageTrigger
	mov	ax, MSG_GEN_SET_ENABLED
	test	cx, mask NNCCF_displayMain
	jz	setTool
	mov	ax, MSG_GEN_SET_NOT_ENABLED

setTool:		
	call	NCSetStateLow
done:		
	.leave
	ret
NCUpdateMainPageTrigger		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCUpdateGoBackTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables/disables the "Back" trigger as necessary.

CALLED BY:  	NCUpdateNormalUI	
PASS:		*ds:si	- nav controller
		ss:bp - childBlock
			features
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUpdateGoBackTriggers	proc	near
NAVIGATION_LOCALS
	uses	si
	.enter inherit
EC <	call	AssertIsNavController			>

	; Now get NCI_index.
	call	NCGetIndex		;bx<-current index
	mov	cx, bx
	inc	cx				;if cx = -1, there are
	jcxz	haveIndex			; no entries yet
	dec	cx

haveIndex:

	; if no feature, update tool
	test	ss:features, mask NCF_BACK
	jz	updateTool
	mov	bx, ss:childBlock
	mov	si, offset NavigateGoBackHistTrigger
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	setFeature
	mov	ax, MSG_GEN_SET_ENABLED

setFeature:
	call	NCSetStateLow

updateTool:
	test	ss:toolFeatures, mask NCTBF_BACK
	jz	done
	mov	bx, ss:toolBlock
	mov	si, offset NavigateToolGoBackHistTrigger
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	setTool
	mov	ax, MSG_GEN_SET_ENABLED
setTool:
	call	NCSetStateLow
done:
	.leave
EC <	call	AssertIsNavController			>
	ret
NCUpdateGoBackTriggers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUpdateGoForwardTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables/disables the "Forward" triggers
		as necessary.

CALLED BY:	NCUpdateNormalUI
PASS:		*ds:si	- nav controller
		ss:bp - childBlock
			features
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUpdateGoForwardTriggers	proc	near
NAVIGATION_LOCALS
	uses	si
	.enter inherit

	; Now get NCI_index.
	call	NCGetIndex		;bx<-current index

    	push	ds
    	call	NCLockHistoryArray    	; *ds:si = array
    	call	ChunkArrayGetCount  	; cx = # of elements
    	pop 	ds

    	inc 	bx
    	cmp 	bx, cx

    	; we want the forward trigger to be turned off when the index
	; actually becomes equal to the # of elements, after adding
	; one. (keep in mind that we start the index at 0, and the #
	; of elements in chunk array at 1)  Also, if # of element = 0
	; initially, then we know it should be off, too!
    	jl 	haveIndex
    	clr 	cx  	    	    	; not enable flag    

haveIndex:
	; if no feature, update tool
	test	ss:features, mask NCF_FORWARD
	jz	updateTool
	mov	bx, ss:childBlock
	mov	si, offset NavigateGoForwardHistTrigger
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	setFeature
	mov	ax, MSG_GEN_SET_ENABLED

setFeature:
	call	NCSetStateLow

updateTool:
	test	ss:toolFeatures, mask NCTBF_FORWARD
	jz	done
	mov	bx, ss:toolBlock
	mov	si, offset NavigateToolGoForwardHistTrigger
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	setTool
	mov	ax, MSG_GEN_SET_ENABLED
setTool:
	call	NCSetStateLow
done:
	.leave
EC <	call	AssertIsNavController			>
	ret
NCUpdateGoForwardTriggers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCDuplicateStateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the state block and initializes NCI_historyList
    	    	to point to the copy

CALLED BY:	NCMetaAttach
PASS:		*ds:si	= a NavigateControlClass object
    	    	bp  	= handle of state block (object block w/
    	    	    	    containing history list)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, es
    	    	ds possibly fixed up
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCDuplicateStateBlock	proc	near
class	NavigateControlClass
	.enter

    	push	ds:[LMBH_handle], si

    	; allocate a new block
    	mov 	bx, bp
    	mov 	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
    	mov 	ax, MGIT_SIZE
    	call	MemGetInfo  	    	    ; ax = bytes in block
    	mov 	dx, ax	    	    	    ; dx = bytes in block
    	call	MemAlloc    	    	    ; bx = handle of new block
EC  <	ERROR_C	NAV_CONTROL_CANNOT_ALLOCATE_BLOCK   	    >

    	mov 	es, ax	    	    	    ; segment new block

    	; lock the state block
    	push	bx  	    	    	    ; handle of new block
    	mov 	bx, bp	    	    	    ; handle of state block
    	call	MemLock
    	mov 	ds, ax	    	    	    ; ds = segment of source
    	clr 	di, si

    	; now, copy the state block to the new block
    	mov_tr	cx, dx	    	    	    ; cx = bytes in block
    	rep 	movsb

    	call	MemUnlock   	    	    ; unlock state block
    	
    	pop 	bx  	    	    	    ; handle of new block
    	mov 	cx, bx
    	mov 	es:[LMBH_handle], bx	    ; identical object blocks
					    ; EXCEPT for handle

    	call	MemUnlock   	    	    ; unlock copy (new block)

    	pop 	bx, si
    	call	MemDerefDS

    	mov 	di, ds:[si]
    	add 	di, ds:[di].NavigateControl_offset
    	mov 	ds:[di].NCI_historyList, cx ; save handle of history
					    ; array

	.leave
	ret
NCDuplicateStateBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCCopyNotificationDataToStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy stuff out of notification data block to locals.

CALLED BY:	NCUpdateNormalUI
PASS:		^hbx - notification data block
RETURN:		ax - NotifyNavContextChangeFlags
DESTROYED:	es, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCCopyNotificationDataToStack		proc	near
	uses	si,ds
	.enter inherit NCUpdateNormalUI

		call	MemLock
		mov	ds, ax
	;
	; Only update history chunk array once per notification.
	; If features, for example, receive this later, we don't
	; want to update the history chunk array again.
	;
		mov	ax, ds:[NNCC_flags]
		mov	si, ax
		and	ax, not (mask NNCCF_updateHistory)
		mov	ds:[NNCC_flags], ax		
		mov	ax, si
	;
	; If we're not updating history, we don't need the names
	;
		test	ax, mask NNCCF_updateHistory	;Only need update
		jz	updatePrevNext			; prev/next?

		segmov	es,ss,cx			;local.
		mov	si, offset NNCC_moniker		;Get context into
		lea	di, ss:moniker			;local.
		call	NCStringCopy

    	    	mov 	cx, ds:[NNCC_selector] 	    	; Get selector
							; into local
    	    	mov 	ss:selector, cx
updatePrevNext:
		call	MemUnlock
		.leave
		ret
NCCopyNotificationDataToStack		endp

NavigateControlCode	    ends
















