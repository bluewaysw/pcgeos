COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		navigation controller
FILE:		conNav.asm

AUTHOR:		Jonathan Magasin, May  4, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT CNCUpdateNormalUI En/Disable the normal UI and update history list.

    INT CNCUpdateBookRelatedUI Customize tools and features for a new book

    INT CNCUpdateNavHistoryNormalTrigger 
				En/Disable the normal History trigger and close the history dialog is the
				new book does not have the history feature.

    INT CNCUpdatePrevNext Enables or disables the "Prev" and "Next"
				triggers, as specified.

    INT UpdatePrevNextLow Enable/Disable the prev/next tools or triggers

    INT SetStateLow Enable/Disable the prev/next tools or triggers

    INT CNCUpdateMainPageTrigger 
				Enables or disables the Main Page triggers, as specified.

    INT CNCUpdateGoBackTriggers Enables/disables the "Back" triggers as
				necessary.

    INT CNCCustomizeToolUI Adds/Removes tools as specified by
				CNCToolboxFeatures

    INT CNCDuplicateStateBlock Copies the state block and initializes
				CNCI_historyList to point to the copy.

    INT CopyNotificationDataToStack 
				Copy stuff out of notification data block to locals.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/ 4/94   	Initial revision
	lester	9/22/94  	modified so controller normal UI is
				just disabled, not removed

DESCRIPTION:
	Code for the content navigation controller.
		

	$Id: navcontrolControl.asm,v 1.1 97/04/04 17:49:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ContentNavControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCMetaAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle attaching of the nav controller, including
		handling saved state.
		
CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= ContentNavControlClass object
		ds:di	= ContentNavControlClass instance data
		es	= segment of ContentNavControlClass
		ax	= message #
	 	cx	- AppAttachFlags
		dx	- Handle of AppLaunchBlock, or 0 if none.
		bp	- Handle of extra state block, or 0 if none.

RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCMetaAttach	method dynamic ContentNavControlClass, 
					MSG_META_ATTACH
	uses	ax, cx, dx, bp, si, es
	.enter
	;
	; Clear "detach received" vardata, if any.
	;
	mov	ax, TEMP_CONVIEW_DETACH_RECEIVED
	call	ObjVarFindData			;ds:bx<-data
	jnc	checkForState
	call	ObjVarDeleteDataAt
	mov	ax, HINT_INITIATED
	call	ObjVarDeleteData	; remove hint
	
checkForState:
	tst	bp
	jz	noState
	;
	; Copy the state block into a new obj block.
	;
	call	CNCDuplicateStateBlock

noState:
	;
	; Duplicate the History list template 
	;
	mov	bx, handle ContentNavTemplate
	clr	ax, cx					;current thread, geode
	call	ObjDuplicateResource			;bx <- dup'ed block
	mov	di, ds:[si]		
	add	di, ds:[di].ContentNavControl_offset
EC <	tst	ds:[di].CNCI_historyBlock				>
EC <	ERROR_NZ	-1						>
	mov	ds:[di].CNCI_historyBlock, bx
	;
	; set its output to be the NavControl object
	;		
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	si, offset ContentNavHistoryGroup	;^lbx:si <- history obj
	mov	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage
	;
	; Add the interaction as the last child of the application,
	; then set it usable.
	;
	movdw	cxdx, bxsi				;^lcx:dx <- history obj
	clr	bx		
	call	GeodeGetAppObject			;^lbx:si <- application
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage

	movdw	bxsi, cxdx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage
		
	.leave
	;
	; Call the superclass.
	;
	mov	di, offset ContentNavControlClass
	call	ObjCallSuperNoLock
	ret
CNCMetaAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the History interaction, add vardata type
		TEMP_CONVIEW_DETACH_RECEIVED and callsuper.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= ContentNavControlClass object
		ds:di	= ContentNavControlClass instance data
		ds:bx	= ContentNavControlClass object (same as *ds:si)
		es	= segment of ContentNavControlClass
		ax	= message #
RETURN:		nothing (whatever superclass returns)
DESTROYED:	nothing (just like superclass)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	8/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCMetaDetach	method dynamic ContentNavControlClass, 
					MSG_META_DETACH
		uses	ax, cx, dx, bp, es
		.enter

		push	si
		clr	bx
		xchg	bx, ds:[di].CNCI_historyBlock
		mov	si, offset ContentNavHistoryGroup
EC <		call ECCheckOD					>

		mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	si

		mov	ax, TEMP_CONVIEW_DETACH_RECEIVED
		clr	cx				;cx <- no extra data
		call	ObjVarAddData

		.leave
		mov	di, offset ContentNavControlClass
		call	ObjCallSuperNoLock
		ret
CNCMetaDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentNavGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the ContentNavControlClass
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		ax - the message

		cx:dx - GenControlBuildInfo structure to fill in

RETURN:		cx:dx - filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentNavGetInfo	method dynamic ContentNavControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset CNC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, (size GenControlBuildInfo)/(size word)
	rep movsw
CheckHack <((size GenControlBuildInfo) and 1) eq 0>
	ret
ContentNavGetInfo	endm

CNC_dupInfo	GenControlBuildInfo	<
	mask GCBF_ALWAYS_UPDATE or \
	mask GCBF_ALWAYS_ON_GCN_LIST or \
	mask GCBF_IS_ON_ACTIVE_LIST or \
	mask GCBF_ALWAYS_INTERACTABLE,
					; GCBI_flags
	CNC_IniFileKey,			; GCBI_initFileKey
	CNC_gcnList,			; GCBI_gcnList
	length CNC_gcnList,		; GCBI_gcnCount
	CNC_notifyTypeList,		; GCBI_notificationList
	length CNC_notifyTypeList,	; GCBI_notificationCount
	ContentNavName,			; GCBI_controllerName

	ContentNavUI,			; GCBI_dupBlock
	CNC_childList,			; GCBI_childList
	length CNC_childList,		; GCBI_childCount
	CNC_featuresList,		; GCBI_featuresList
	length CNC_featuresList,	; GCBI_featuresCount
	CNC_DEFAULT_FEATURES,		; GCBI_features

	ContentNavToolUI,		; GCBI_toolBlock
	CNC_toolList,			; GCBI_toolList
	length CNC_toolList,		; GCBI_toolCount
	CNC_toolFeaturesList,		; GCBI_toolFeaturesList
	length CNC_toolFeaturesList,	; GCBI_toolFeaturesCount
	CNC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if 	_FXIP
ConviewControlInfoXIP	segment	resource
endif

CNC_IniFileKey	char	"content nav", 0

CNC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_NOTIFY_CONTENT_CONTEXT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_NOTIFY_CONTENT_BOOK_CHANGE>

CNC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_CONTENT_CONTEXT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_CONTENT_BOOK_CHANGE>

;---

CNC_childList	GenControlChildInfo	\
	<offset ContentNavGoBackLinkTrigger,
		mask CNCF_BACK,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ContentNavMainPageTrigger,
		mask CNCF_MAIN_PAGE,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ContentNavHistoryTrigger,
		mask CNCF_HISTORY,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ContentNavPageTurnGroup,
		mask CNCF_PREV_NEXT,
		mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

CNC_featuresList GenControlFeaturesInfo \
	<offset ContentNavGoBackLinkTrigger, 
		GoBackLinkTriggerName,
		0>,
	<offset ContentNavPageTurnGroup,
		NextPrevPageTriggerName,
		0>,
	<offset ContentNavHistoryTrigger,
		HistoryGroupName,
		0>,
	<offset ContentNavMainPageTrigger,
		MainPageTriggerName,
		0>


CNC_toolList	GenControlChildInfo	\
	<offset ContentNavToolGoBackLinkTrigger,
		mask CNCTF_BACK,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ContentNavToolMainPageTrigger,
		mask CNCTF_MAIN_PAGE,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ContentNavToolHistoryTrigger,
		mask CNCTF_HISTORY,
		mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ContentNavToolPageTurnGroup,
		mask CNCTF_PREV_NEXT,
		mask GCCF_IS_DIRECTLY_A_FEATURE>


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.
;
CNC_toolFeaturesList GenControlFeaturesInfo \
	<offset ContentNavToolGoBackLinkTrigger, 
		GoBackLinkTriggerName,
		0>,
	<offset ContentNavToolPageTurnGroup,
		NextPrevPageTriggerName,
		0>,
	<offset ContentNavToolHistoryTrigger,
		HistoryGroupName,
		0>,
	<offset ContentNavToolMainPageTrigger, 
		MainPageTriggerName,
		0>

if 	_FXIP
ConviewControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCGenControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the nav controller's UI upon receiving
		notification of a context change or a book change.

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si	= ContentNavControlClass object
		ds:di	= ContentNavControlClass instance data
		ds:bx	= ContentNavControlClass object (same as *ds:si)
		ax	= message #
		ss:bp - GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
    If the update was sent as result of a new book bein loaded, we call
    CNCUpdateBookRelatedUI which add/removes the appropriate controller 
    toolbox UI. CNCUpdateBookRelatedUI also en/disables the History triggers.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCGenControlUpdateUI		method dynamic ContentNavControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI
	.enter
	;
	; See if we've already received a detach.
	;
	mov	ax, TEMP_CONVIEW_DETACH_RECEIVED
	call	ObjVarFindData
	jc	done

	mov	cx, ss:[bp].GCUUIP_changeType
	cmp	cx, GWNT_CONTENT_CONTEXT_CHANGE
	jne	checkBookChange

	call	CNCUpdateNormalUI
	jmp	done

checkBookChange:
	cmp	cx, GWNT_CONTENT_BOOK_CHANGE
	jne	done
	call	CNCUpdateBookRelatedUI
done:
	.leave
	ret
CNCGenControlUpdateUI		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCUpdateNormalUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	En/Disable the normal UI and update history list.

CALLED BY:	(INTERNAL) CNCGenControlUpdateUI
PASS:		*ds:si - ContentNavControl
		ss:bp - GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
    If the update was sent as result of a simple context change, we can
    update only features or tools, depending on which are interactible.

    GCUUIP_features		word	;from TEMP_GEN_CONTROL_INSTANCE,
					;but clear if GCIF_NORMAL_UI not set
					;in TEMP_GEN_CONTROL_INSTANCE
    GCUUIP_toolboxFeatures	word	;from TEMP_GEN_CONTROL_INSTANCE,
					;but clear if GCIF_TOOLBOX_UI not set
					;in TEMP_GEN_CONTROL_INSTANCE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/23/94    	Initial version
				Broke out of CNCGenControlUpdateUI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCUpdateNormalUI	proc	near
	uses	bp
CONTENT_NAV_LOCALS
	mov	bx, ss:[bp].GCUUIP_dataBlock	;Get handle
	.enter
	;
	; Is this a NULL notification?  We don't do anything here for null
	; notifications.  The null book notification takes care of resetting
	; the tools.
	;
	tst	bx
	jz	done
	;
	; Get the notifcation data and put it into locals
	;
	call	CopyNotificationDataToStack	;ax=NotifyNavContextChangeFlags
	;
	; Get controller attributes.
	;
	call	NCUGetToolBlockAndToolFeaturesLocals
	call	NCUGetChildBlockAndFeaturesLocals
	;
	; Now update the enabled state of "Prev" and "Next" triggers
	; and the main page trigger
	;
	call	CNCUpdatePrevNext
	call	CNCUpdateMainPageTrigger
	;
	; Add the page now being displayed to the history list, if necessary
	;
	test	ax, mask NNCCF_retnWithState	; restoring from state?
	jnz	redrawList			; redraw only
	test	ax, mask NNCCF_updateHistory	; need to update history?
	jz	redrawList			; no, just redraw it
	call	NCHUpdateHistoryForLink

redrawList:
	call	NCHRedrawHistoryList
	;
	; Update go back trigger *after* the history list has been udpated
	;
	call	CNCUpdateGoBackTriggers
	;
	; Notify myself which features and tools are being enabled/disabled
	;
	mov	cl, ss:enableFeatures
	mov	ch, ss:disableFeatures
	call	NotifyEnableDisable	
done:
	.leave
	ret
CNCUpdateNormalUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCUpdateBookRelatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Customize tools and features for a new book

CALLED BY:	(INTERNAL) CNCGenControlUpdateUI
PASS:		*ds:si - ContentNavControl
		ss:bp - GenControlUpdateUIParams
RETURN:		ss:bp - GenControlUpdateUIParams
DESTROYED:	ax,bx,cx,dx,es,di

PSEUDO CODE/STRATEGY:
	This routine add/removes the controller toolbox UI based on the 
	toolbox features set for the book.
	
	En/Disable the normal NavHistoryList trigger because it only needs
	to be updated when a new book is loaded.

	We do not have to update the other normal controller UI (menu items) in
	this routine because they will get updated by the CONTEXT_CHANGE
	notification that is sent out when the main page of the book is 
	loaded.

	We also free the history list when appropriate.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 1/94		Initial version
	lester	9/22/94  	modified to use the alreadyretnWithState
				flag and just customize the toolbox UI.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCUpdateBookRelatedUI		proc	near
		.enter

		mov	bx, ss:[bp].GCUUIP_dataBlock

		mov	cx, mask CNCFeatures
		mov	dx, mask CNCToolboxFeatures
		tst	bx
		jz	resetBookUI	
		call	MemLock
		mov	es, ax		
		mov	ax, es:[NCBC_flags]
	;
	; Set the alreadyFreedHistoryList flag so the history list 
	; is only freed once per notification.
	; If features, for example, receive this later, we don't
	; want to free the history list again again.
	; This also will cause the ToolUI to be only updated once per 
	; notification, which is a good thing.
	;
		BitSet	es:[NCBC_flags], NCBCF_alreadyFreedHistoryList
	;
	; Convert BookFeatures into CNCToolboxFeatures, ignoring flags for
	; non-nav tools/features, and add/remove tools and features
	;
		mov	cx, es:[NCBC_features]
		mov	dx, es:[NCBC_tools]
resetBookUI:		
		andnf	cx, mask CNCFeatures
		andnf	dx, mask CNCToolboxFeatures

		test	ax, (mask NCBCF_alreadyFreedHistoryList)
		jnz	afterCustomizingUI
		test	ax, (mask NCBCF_retnWithState)
		jnz	afterCustomizingUI

		call	CNCCustomizeToolUI
	;
	; If we're not restoring from state and if we have not already 
	; freed the history list, reinitialize gobackIndex and 
	; wipe out the history array, since a new book was loaded.
	;
		push	bx
		call	CNCFreeHistoryList		;clear history
		pop	bx
		
afterCustomizingUI:
	;
	; Update the history list normal trigger.
	;
		call	CNCUpdateNavHistoryNormalTrigger
						; cx <- CNCFeaturesAndTools
	;
	; If there was no data block, this is a null status event and
	; we want to reset the UI so that all features are disabled.
	; Turn all bits on in ch and off in cl so everything is disabled
	; and nothing is enabled.
	;
		mov	ax, (mask CNCFeaturesAndTools shl 8)
		xchg	ax, cx			; preserve cx in ax
		tst	bx			; if resetting state, turn 
		jz	noUnlock		;  off all features 
		call	MemUnlock
		mov_tr	cx, ax			; restore features in cx
noUnlock:
	;
	; Set the enable/disable flag for the history feature
	;
		call	NotifyEnableDisable
		.leave
		ret
CNCUpdateBookRelatedUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCUpdateNavHistoryNormalTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	En/Disable the normal History trigger and close the history
		dialog if the new book does not have the history feature.

CALLED BY:	(INTERNAL) CNCUpdateBookRelatedUI
PASS:		*ds:si	- controller
		cx	- desired features (CNCFeatures)
		ss:bp 	- GenControlUpdateUIParam
UNCHANGED:	ss:bp
RETURN:		cx - CNCFeaturesAndTools, with CNCFAT_HISTORY set if
			history feature is on for this book
DESTROYED:	ax,cx,dx,di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCUpdateNavHistoryNormalTrigger	proc	near
		class	ContentNavControlClass
		uses	bx
		.enter

		test	ss:[bp].GCUUIP_features, mask CNCF_HISTORY
		jz	closeHistoryDialog
	;
	; Update history features
	;
		push	si
		mov	bx, ss:[bp].GCUUIP_childBlock
		mov	si, offset ContentNavHistoryTrigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		test	cx, mask CNCF_HISTORY
		jz	setFeature
		mov	ax, MSG_GEN_SET_ENABLED
setFeature:
		call	SetStateLow
		pop	si

closeHistoryDialog:
	;
	; Determine whether or not the history feature should be
	; enabled or disabled in this book.
	;
		mov	bl, mask CNCFAT_HISTORY
		clr	bh			; assume history is enabled
		test	cx, mask CNCF_HISTORY
		jnz	done
		xchg	bl, bh
	;
	; Close the history dialog if book does not have history feature
	;
		push	bx, si
		mov	di, ds:[si]		
		add	di, ds:[di].ContentNavControl_offset
		mov	bx, ds:[di].CNCI_historyBlock
EC <		call	ECCheckMemHandleNS			>
		mov	si, offset ContentNavHistoryGroup
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx, si
done:

		.leave
		ret
CNCUpdateNavHistoryNormalTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCUpdatePrevNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables or disables the "Prev" and 
		"Next" triggers, as specified.

CALLED BY:	(INTERNAL) CNCGenControlUpdateUI
PASS:		ss:bp	- inherited locals
			  childBlock
			  toolBlock
			  features
			  toolFeatures
		      	  bookFeatures
		ax	- NotifyNavContextChangeFlags
RETURN:		nothing
DESTROYED:	bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 1/94    	Initial version
	lester	9/22/94  	added check for bookFeature BFF_PREV_NEXT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCUpdatePrevNext		proc	near
CONTENT_NAV_LOCALS
		uses	ax, si
		.enter inherit
	;
	; Check if the prevNext feature is set for this book
	;
		mov	cx, ax
		test	ss:bookFeatures, (mask BFF_PREV_NEXT)
		jnz	updateFeature
		BitClr	cx, NNCCF_prevEnabled
		BitClr	cx, NNCCF_nextEnabled
updateFeature:
	;
	; Update next/prev for notification message
	;
		mov	al, mask CNCFAT_PREV		
		mov	dx, mask NNCCF_prevEnabled
		call	SetFlagsLow

		mov	al, mask CNCFAT_NEXT
		mov	dx, mask NNCCF_nextEnabled
		call	SetFlagsLow
		
		test	ss:features, mask CNCF_PREV_NEXT 
		jz	updateTool
	;
	; Update next/prev features
	;
		mov	bx, ss:childBlock
		mov	si, offset ContentNavPreviousPageTrigger
		mov	di, offset ContentNavNextPageTrigger
		call	UpdatePrevNextLow
updateTool:		
	;
	; Update next/prev tools, if the tool is present
	;
		test	ss:toolFeatures, mask CNCTF_PREV_NEXT 	
		jz	done

		mov	bx, ss:toolBlock
		mov	si, offset ContentNavToolPreviousPageTrigger
		mov	di, offset ContentNavToolNextPageTrigger
		call	UpdatePrevNextLow
done:
		.leave
		ret
CNCUpdatePrevNext		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePrevNextLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/Disable the prev/next tools or triggers

CALLED BY:	(INTERNAL) CNCUpdatePrevNext
PASS:		bx - child block
		cx - NotifyNavContextChangeFlags
		si - chunk handle of prev tool/trigger
		di - chunk handle of next tool/trigger
RETURN:		nothing
DESTROYED:	si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePrevNextLow		proc	near
		uses	ax, bp
		.enter

		tst	bx			; UI not built yet?
		jz	done			

		mov	ax, MSG_GEN_SET_ENABLED
		test	cx, mask NNCCF_prevEnabled
		jnz	setPrevState
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setPrevState:
		push	di
		call	SetStateLow
		pop	si
		
		mov	ax, MSG_GEN_SET_ENABLED
		test	cx, mask NNCCF_nextEnabled
		jnz	setNextState
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setNextState:
		call	SetStateLow
done:		
		.leave
		ret
UpdatePrevNextLow		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCUpdateMainPageTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables or disables the Main Page triggers, as specified.

CALLED BY:	(INTERNAL) CNCGenControlUpdateUI
PASS:		ss:bp	- inherited locals
			  childBlock
			  toolBlock
			  features
			  toolFeatures
			  bookFeatures
		ax	- NotifyNavContextChangeFlags
RETURN:		nothing
DESTROYED:	bx, cx, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 1/94    	Initial version
	lester	9/22/94  	added check for bookFeature BFF_MAIN_PAGE

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCUpdateMainPageTrigger		proc	near
		uses	ax, si
CONTENT_NAV_LOCALS
		.enter inherit
	;
	; Check if the MainPage feature is set for this book
	;
		mov	cx, ax
		test	ss:bookFeatures, (mask BFF_MAIN_PAGE)
		jnz	updateFeature
		BitSet	cx, NNCCF_displayMain
updateFeature:
	;
	; If the displayMain flag is set, we want to disable the
	; main page tool/feature.
	;
		lea	si, ss:disableFeatures
		test	cx, mask NNCCF_displayMain
		jnz	$10
		lea	si, ss:enableFeatures
$10:
		ornf	ss:[si], mask CNCFAT_MAIN_PAGE

		test	ss:features, mask CNCF_MAIN_PAGE
		jz	updateTool
	;
	; Update main page features
	;
		mov	bx, ss:childBlock
		mov	si, offset ContentNavMainPageTrigger
		mov	ax, MSG_GEN_SET_ENABLED
		test	cx, mask NNCCF_displayMain
		jz	setFeature
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setFeature:
		call	SetStateLow
updateTool:		
	;
	; Update tool if present
	;
		test	ss:toolFeatures, mask CNCTF_MAIN_PAGE
		jz	done
		mov	bx, ss:toolBlock
		mov	si, offset ContentNavToolMainPageTrigger
		mov	ax, MSG_GEN_SET_ENABLED
		test	cx, mask NNCCF_displayMain
		jz	setTool
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setTool:		
		call	SetStateLow
done:		
		.leave
		ret
CNCUpdateMainPageTrigger		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCUpdateGoBackTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables/disables the "Back" triggers
		as necessary.

CALLED BY:	(INTERNAL) CNCGenControlUpdateUI
PASS:		*ds:si	- nav controller
		ss:bp - childBlock
			features
			bookFeatures
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/24/94    	Initial version
	lester	9/22/94  	added check for bookFeature BFF_BACK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCUpdateGoBackTriggers	proc	near
CONTENT_NAV_LOCALS
		uses	si
		.enter inherit
EC <		call	AssertIsNavController			>
	;
	; Check if the BACK feature is set for this book
	;
		clr	cx
		test	ss:bookFeatures, (mask BFF_BACK)
		jz	haveIndex
	;
	; Now get CNCI_gobackIndex.
	;
		call	NCHGetGoBackIndex		;bx<-current index
		mov	cx, bx
		inc	cx				;if cx = -1, there are
		jcxz	haveIndex			; no entries yet
		dec	cx
haveIndex:
	;
	; if no feature, update tool
	;		
		test	ss:features, mask CNCF_BACK
		jz	updateTool
		mov	bx, ss:childBlock
		mov	si, offset ContentNavGoBackLinkTrigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		jcxz	setFeature
		mov	ax, MSG_GEN_SET_ENABLED
setFeature:
		call	SetStateLow
updateTool:
		test	ss:toolFeatures, mask CNCTF_BACK
		jz	done
		mov	bx, ss:toolBlock
		mov	si, offset ContentNavToolGoBackLinkTrigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		jcxz	setTool
		mov	ax, MSG_GEN_SET_ENABLED
setTool:
		call	SetStateLow
done:
		mov	al, mask CNCFAT_BACK 
		lea	si, ss:disableFeatures
		jcxz	setFlags
		lea	si, ss:enableFeatures
setFlags:
		ornf	ss:[si], al
		.leave
EC <		call	AssertIsNavController			>
		ret
CNCUpdateGoBackTriggers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCCustomizeToolUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds/Removes tools as specified by CNCToolboxFeatures

CALLED BY:	(INTERNAL) CNCUpdateBookRelatedUI
PASS:		*ds:si	- controller
		dx	- desired tools (CNCToolboxFeatures)
RETURN:		nothing
DESTROYED:	dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		Get the current tools.
		Add those tools that are desired but are not currently
		existing.
		Remove those tools that are not desired but are currently
		existing.
		
	NOTE:	Need to use MF_FORCE_QUEUE with the ADD and REMOVE
		messages.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCCustomizeToolUI	proc	near
	uses	ax, bx, cx, dx, bp
	.enter

	;
	; get the current toolbox feature set
	;
	push	dx		; save desired tools
	mov	ax, MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES
	call	ObjCallInstanceNoLock		
	mov	cx, ax		; cx <- current tool set
	pop	dx		; restore desired tools

	mov	bx, ds:[LMBH_handle]			;^lbx:si <- controller

	push	cx		; save current tools
	not	cx		; cx <- tools not existing
	and	cx, dx		; cx = tools to add
	jcxz	disable		; nothing to add?
	;
	; add desired tools which don't exist
	;
	push	dx		; save desired tools
	mov	ax, MSG_GEN_CONTROL_ADD_TOOLBOX_FEATURE
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx		; restore desired tools

disable:
	pop	cx		; cx <- current tools
	not	dx		; dx <- tools we want off
	and	cx, dx		; cx = tools to remove
	jcxz	done
	;
	; remove existing tools which aren't desired
	;
	mov	ax, MSG_GEN_CONTROL_REMOVE_TOOLBOX_FEATURE
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
CNCCustomizeToolUI	endp



if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CNCCustomizeUILow is good for adding/removing both normal ui and tools but
since now we are just enable/disableing the normal controller ui, this
routine is overkill. It has been replaced with CSCCustomizeToolUI.

I am leaving this code in there because it is neat and might me useful for
something else.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustomizeUILow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables/disables tools and features as specified by
		the CNCToolboxFeatures record argument.

		NOTE:  We force the tools and features to be the same.

CALLED BY:	ContentNavReceiveNotification
PASS:		*ds:si	- nav controller
		bp	- 0 for features, 1 for tools
		dx	- desired features or tools
			(CNCFeatures or CNCToolboxFeatures, which
			are identical except in name)
RETURN:		nothing
DESTROYED:	ax, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get the current tools/features.
		Enable those tools/features that should be
		 enabled but currently aren't.
		Disable those tools/features that should be
		 disabled but currently aren't.
		
	Note:	We use MF_FORCE_QUEUE (as opposed to 
		ObjCallInstanceNoLock) to avoid receiving a
		GEN_CONTROL_UPDATE_UI (for the *other* stuff -
		tools or features) before we finish this
		routine.  If we allow ourself to be interrupted
		and handle the other UPDATE_UI, we will not have
		yet finished the first one, so the history and
		goback arrays will not be set up yet.

;	Note2:  Things seem to be working alright without the 
;		MF_FORCE_QUEUE.  Problem went away after I made sure
;		NCCCustomizeUI only gets called once per notification
;		even though UpdateUI could get called more than once.
;		See the "jz afterCustomizingUI" in
;		CNCGenControlUpdateUI.
	Note3:  NCCCustomizeUI *does* get interrupted with UpdateUI
		in Peter's version of the viewer, even though his
		version is very similar to this one.  Just to be safe,
		let's keep the MF_FORCE_QUEUE.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CustomizeMessagesStruct	struct
    CMS_getFeatures	word
    CMS_addFeatures	word
    CMS_removeFeatures	word
CustomizeMessagesStruct	ends

customizeMsgTable	CustomizeMessagesStruct \
	<MSG_GEN_CONTROL_GET_NORMAL_FEATURES,\
	 MSG_GEN_CONTROL_ADD_FEATURE,\
	 MSG_GEN_CONTROL_REMOVE_FEATURE>,
	<MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES,\
	 MSG_GEN_CONTROL_ADD_TOOLBOX_FEATURE,\
	 MSG_GEN_CONTROL_REMOVE_TOOLBOX_FEATURE>


CustomizeUILow	proc	near
	uses	bx, cx
	.enter
EC <	call	AssertIsNavController			>

	mov	bx, ds:[LMBH_handle]			;^lbx:si <- controller

	mov	ax, size CustomizeMessagesStruct
	mov	cx, bp
	mul	cl
	mov	bp, ax
	add	bp, offset customizeMsgTable		;cs:bp <- CustMsgStruct
	;
	; get the currently enabled features/tools
	;
	push	dx, bp
	mov	ax, cs:[bp].CMS_getFeatures
	call	ObjCallInstanceNoLock			;ax <- current tools/
	mov	cx, ax					; features
	pop	dx, bp

	push	cx					;save current features
	not	cx					;cx <- features not on
	and	cx, dx					;cx = stuff to enable
	jcxz	disable					;nothing to enable?
	;
	; add desired features/tools which don't exist
	;
	push	dx, bp
	mov	ax, cs:[bp].CMS_addFeatures
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx, bp

disable:
	pop	cx					;cx <- current features
	not	dx					;dx <- stuff want off
	and	cx, dx					;cx = stuff to disable
	jcxz	done
	;
	; remove existant features/tools which aren't desired
	;
	mov	ax, cs:[bp].CMS_removeFeatures
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
CustomizeUILow	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCDuplicateStateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the state block and initializes CNCI_historyList
		to point to the copy.

CALLED BY:	CNCMetaAttach
PASS:		*ds:si	= nav controller
		bp	= handle of state block,
			  which is an object block
			  containing the history list
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,es
		DS possibly fixed up
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCDuplicateStateBlock	proc	near
	class	ContentNavControlClass
	.enter

	push	ds:[LMBH_handle], si
	;
	; Allocate a new block.
	;
	mov	bx, bp
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK 
	mov	ax, MGIT_SIZE
	call	MemGetInfo			;ax=bytes in block
	mov	dx, ax				;(save for copying)
	call	MemAlloc			;bx=handle new block
	mov	es, ax				;ax=segment new block
EC <	ERROR_C	JM_SEE_BACKTRACE					>
	;
	; Lock the state block.
	;
	push	bx
	mov	bx, bp
	call	MemLock
	mov	ds, ax				;ds = segment of source
	clr	di, si
	;
	; Now copy the state block to the new block.
	;
	mov_tr	cx, dx				;cx=bytes in block
	rep	movsb

	call	MemUnlock			;unlock state block

	pop	bx
	mov	cx, bx
	mov	es:[LMBH_handle], bx		;Identical objet blocks
						;  EXCEPT for handle.
	call	MemUnlock			;unlock copy

	pop	bx, si
	call	MemDerefDS

	mov	di, ds:[si]
	add	di, ds:[di].ContentNavControl_offset
	mov	ds:[di].CNCI_historyList, cx	;save handle of history array

	.leave
	ret
CNCDuplicateStateBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNotificationDataToStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy stuff out of notification data block to locals.

CALLED BY:	(INTERNAL) CNCUpdateNormalUI
PASS:		^hbx - notification data block
RETURN:		ax - NotifyNavContextChangeFlags
DESTROYED:	es, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/26/94		Initial version
	lester	9/22/94  	added code to get bookFeatures

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNotificationDataToStack		proc	near
	uses	si,ds
	.enter inherit CNCUpdateNormalUI

		clr	al
		mov	ss:enableFeatures, al
		mov	ss:disableFeatures, al
		
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
	; Get the book Features 
	;
		mov	si, ds:[NNCC_bookFeatures]
		mov	ss:bookFeatures, si
	;
	; If we're not updating history, we don't need the names
	;
		test	ax, mask NNCCF_updateHistory	;Only need update
		jz	updatePrevNext			; prev/next?

		mov	si, offset NNCC_filename	;Get filename into
		segmov	es,ss,cx			;local.
		lea	di, ss:filename
		call	NCUStringCopy

		mov	si, offset NNCC_context		;Get context into
		lea	di, ss:context			;local.
		call	NCUStringCopy

updatePrevNext:
		call	MemUnlock
		.leave
		ret
CopyNotificationDataToStack		endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify ourself of tools/features that need to be
		enabled or disabled.

CALLED BY:	
PASS:		cl - CNCFeaturesAndTools to be enabled
		ch - CNCFeaturesAndTools to be disabled
RETURN:		nothing	
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyEnableDisable		proc	near
		.enter inherit

		jcxz	done
		push	bp
		mov	ax, MSG_CNC_ENABLE_DISABLE_FEATURES_AND_TOOLS
		call	ObjCallInstanceNoLock
		pop	bp
done:
		.leave
		ret
NotifyEnableDisable 		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFlagsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set flags in enableFeatures, disableFeatures

CALLED BY:	
PASS:		al - CNCFeaturesAndTools to set
		cx - NotifyNavContextChangeFlags
	 	dx - NNCCF flag to check for in cx
		   if it is set, set al in enableFeatures
		   if not set, set al in disableFeatures
RETURN:		nothing
DESTROYED:	si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFlagsLow		proc	near
CONTENT_NAV_LOCALS
		.enter inherit
		lea	si, ss:enableFeatures
		test	cx, dx
		jnz	$10
		lea	si, ss:disableFeatures
$10:
		ornf	ss:[si], al
		.leave
		ret
SetFlagsLow		endp

;------

SetStateLow	proc	near
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
SetStateLow	endp
		
ContentNavControlCode ends
