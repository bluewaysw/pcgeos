COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		find controller
FILE:		findcontrolControl.asm

AUTHOR:		Tom Lester, Aug 23, 1994

METHODS:
Name				Description
----				-----------
MSG_GEN_CONTROL_GET_INFO	Get GenControl info for the 
				ContentFindControlClass

MSG_GEN_CONTROL_UPDATE_UI	Update the controller's UI upon receiving 
				notification of a new book.

MSG_META_ATTACH			Check if the SearchReplaceControl optr is
				null. Only in EC version.

MSG_META_DETACH			Destroy the SearchReplaceControl and call
				superclass.

MSG_GEN_CONTROL_DESTROY_UI	nuke the search controller and call superclass

MSG_CFC_INITIATE_SEARCH_CONTROL	Bring up the SearchReplaceControl object, 
				creating one if necessary.

ROUTINES:
	Name			Description
	----			-----------
    INT CFCCustomizeUI Update the Features and Tools

    INT CFC_EnableOrDisable Update the Features and Tools

    INT CFC_EnableOrDisableLow Update the Features and Tools

    INT CFCCustomizeToolUI Adds/Removes tools as specified by
				CFCToolboxFeatures

    INT CFCCreateSearchReplaceController 
				Setup SearchReplaceControl object and return it's OD

    INT CFCDestroySearchControl Destroy the SearchReplaceControl object and
				null the CFCI_searchController optr.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/23/94   	Initial revision

DESCRIPTION:
	Code for the content Find controller.	
		

	$Id: findcontrolControl.asm,v 1.1 97/04/04 17:50:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentFindControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentFindGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the ContentFindControlClass

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
	lester	8/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentFindGetInfo	method dynamic ContentFindControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset CFC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, (size GenControlBuildInfo)/(size word)
	rep movsw
CheckHack <((size GenControlBuildInfo) and 1) eq 0>
	ret
ContentFindGetInfo	endm

CFC_dupInfo	GenControlBuildInfo	<
	mask GCBF_ALWAYS_UPDATE or \
	mask GCBF_ALWAYS_ON_GCN_LIST or \
	mask GCBF_IS_ON_ACTIVE_LIST or \
	mask GCBF_ALWAYS_INTERACTABLE,
					; GCBI_flags
	CFC_IniFileKey,			; GCBI_initFileKey
	CFC_gcnList,			; GCBI_gcnList
	length CFC_gcnList,		; GCBI_gcnCount
	CFC_notifyTypeList,		; GCBI_notificationList
	length CFC_notifyTypeList,	; GCBI_notificationCount
	ContentFindName,		; GCBI_controllerName

	ContentFindUI,			; GCBI_dupBlock
	CFC_childList,			; GCBI_childList
	length CFC_childList,		; GCBI_childCount
	CFC_featuresList,		; GCBI_featuresList
	length CFC_featuresList,	; GCBI_featuresCount
	CFC_DEFAULT_FEATURES,		; GCBI_features

	ContentFindToolUI,		; GCBI_toolBlock
	CFC_toolList,			; GCBI_toolList
	length CFC_toolList,		; GCBI_toolCount
	CFC_toolFeaturesList,		; GCBI_toolFeaturesList
	length CFC_toolFeaturesList,	; GCBI_toolFeaturesCount
	CFC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures


if 	_FXIP
ConviewControlInfoXIP	segment	resource
endif

CFC_IniFileKey	char	"content find", 0

CFC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_NOTIFY_CONTENT_BOOK_CHANGE>

CFC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_CONTENT_BOOK_CHANGE>

;---

CFC_childList	GenControlChildInfo	\
	<offset ContentFindFindTrigger,
		mask CFCF_FIND,
		mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

CFC_featuresList GenControlFeaturesInfo \
	<offset ContentFindFindTrigger,
		FindTriggerName,
		0>

CFC_toolList	GenControlChildInfo	\
	<offset ContentFindToolFindTrigger,
		mask CFCTF_FIND,
		mask GCCF_IS_DIRECTLY_A_FEATURE>


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.
;
CFC_toolFeaturesList GenControlFeaturesInfo \
	<offset ContentFindToolFindTrigger, 
		FindToolTriggerName,
		0>

if 	_FXIP
ConviewControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFCGenControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the controller's UI upon receiving notification
		of a new book.

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si	= ContentFindControlClass object
		ds:di	= ContentFindControlClass instance data
		ds:bx	= ContentFindControlClass object (same as *ds:si)
		ax	= message #

		ss:bp 	- GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	This method handles notifications with type GWNT_CONTENT_BOOK_CHANGE
	which have data NotifyContentBookChange.

 	Extract the data out of the given data block.
	Update the regular features (if necessary).
	Update the toolbox features (if necessary).

	If neither find feature or tool is desired, destroy the 
	searchController.

	NOTE: The actuall features/tools can not be found from 
	      GenControlUpdateUIParams because it does not have
	      the actuall features/tools unless the NORMAL_UI/TOOLBOX_UI
	      is set interactable in the TEMP_GEN_CONTROL_INSTANCE vardata.
	      We need to use MSG_GEN_CONTROL_GET_(NORMAL|TOOLBOX)_FEATURES
	      to find the current features.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFCGenControlUpdateUI	method dynamic ContentFindControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI
	.enter

EC <	cmp	ss:[bp].GCUUIP_changeType, GWNT_CONTENT_BOOK_CHANGE	>
EC <	ERROR_NE CONTROLLER_UPDATE_UI_UNEXPECTED_NOTIFICATION_TYPE	>
EC <	cmp	ss:[bp].GCUUIP_manufacturer, MANUFACTURER_ID_GEOWORKS	>
EC <	ERROR_NE CONTROLLER_UPDATE_UI_UNEXPECTED_NOTIFICATION_TYPE	>

	;
	; Get data block.
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock	;Get handle of data block
	;
	; Is this a NULL notification?
	;
	mov	cx, mask CFCFeatures
	mov	dx, mask CFCToolboxFeatures
	tst	bx
	jz	resetUI

	call	MemLock
	mov	es, ax

	;
	; Get desired Book features and convert to CFCFeatures
	;
	clr	cx
	mov	ax, es:[NCBC_features]		; Get desired book features
	test	ax, mask BFF_FIND
	jz	noFindFeatureFlag
	mov	cx, mask CFCF_FIND

noFindFeatureFlag:
	;
	; Get desired Book tools and convert to CFCToolboxFeatures
	;
	clr	dx
	mov	ax, es:[NCBC_tools]		; Get desired book tools
	test	ax, mask BFF_FIND
	jz	noFindToolFlag
	mov	dx, mask CFCTF_FIND

noFindToolFlag:

		; bx still data block handle
	call	MemUnlock

	;
	; Destroy search controller since we don't need it for this book.
	;
	tstdw	cxdx
	jnz	dontDestroySearchController
	call	CFCDestroySearchControl
dontDestroySearchController:
	
		; cx	- desired CFCFeatures record
		; dx	- desired CFCToolboxFeatures record
		; ss:bp - GenControlUpdateUIParams
resetUI:
	call	CFCCustomizeUI

	.leave
	ret
CFCGenControlUpdateUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFCCustomizeUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the Features and Tools

CALLED BY:	(INTERNAL) CFCGenControlUpdateUI
PASS:		cx	- desired CFCFeatures record
		dx	- desired CFCToolboxFeatures record
		ss:bp	- GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:
	Enable/Disable the normal UI.
	Add/Remove the tools.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/26/94		Initial version
	lester	9/19/94  	changed to enable/disable normal UI and
				add/remove toolbox UI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFCCustomizeUI		proc	near
		uses	ax, bp
		.enter

	; Do features first
		push	dx			; save CFCToolboxFeatures
		push	si			; save controler chunk handle

	; update the find normal ui

CheckHack < (mask CSCFeatures) le 00FFh	>	; so we can use byte regs below
		mov	ax, mask CFCF_FIND
		mov	dh, al
		andnf	dh, cl			; dh <- enable or disable
		mov	dl, VUM_NOW
		mov	si, offset ContentFindToolFindTrigger
		call	CFC_EnableOrDisable

	; Now do tools
		pop	si			; restore controler chunk handle
		pop	dx			; restore CFCToolboxFeatures
		call	CFCCustomizeToolUI
		
		.leave
		ret
CFCCustomizeUI		endp

;---

	; ax = bit to test to normal
	; dl = VisUpdateMode
	; dh = non-zero to enable, 0 to disable
	; si = offset for normal obj
	; ss:bp = GenControlUpdateUIParams
	; 	ax,bx,cx,dx,bp - destroyed

CFC_EnableOrDisable	proc	near
	.enter
	test	ax, ss:[bp].GCUUIP_features
	jz	noNormal
	mov	bx, ss:[bp].GCUUIP_childBlock
	call	CFC_EnableOrDisableLow
noNormal:
	.leave
	ret
CFC_EnableOrDisable	endp

;---

	;bx:si - obj
	;dl - VisUpdateMode
	;dh - state
	;	ax, cx, dx, bp - destroyed

CFC_EnableOrDisableLow	proc	near	uses di
	.enter
	mov	ax, MSG_GEN_SET_ENABLED
	tst	dh
	jnz	pasteCommon
	mov	ax, MSG_GEN_SET_NOT_ENABLED
pasteCommon:
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
CFC_EnableOrDisableLow	endp

;---



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFCCustomizeToolUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds/Removes tools as specified by CFCToolboxFeatures

CALLED BY:	(INTERNAL) CFCCustomizeUI
PASS:		*ds:si	- controller
		dx	- desired tools (CFCToolboxFeatures)
RETURN:		nothing
DESTROYED:	ax, dx, di, bp
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
CFCCustomizeToolUI	proc	near
	uses	bx, cx
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
CFCCustomizeToolUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFCGenControlDestroyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	nuke the search controller and call superclass

CALLED BY:	MSG_GEN_CONTROL_DESTROY_UI
PASS:		*ds:si	= ContentFindControlClass object
		ds:di	= ContentFindControlClass instance data
		ds:bx	= ContentFindControlClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	I am not sure that I need to subclass this message but is will not
	hurt.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFCGenControlDestroyUI	method dynamic ContentFindControlClass, 
					MSG_GEN_CONTROL_DESTROY_UI
	.enter
	call	CFCDestroySearchControl

	;
	; Call super class
	;
	mov	di, offset ContentFindControlClass
	call	ObjCallSuperNoLock
	
	.leave
	ret
CFCGenControlDestroyUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFCInitiateSearchControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the SearchReplaceControl object, creating one 
		if necessary.

CALLED BY:	MSG_CFC_INITIATE_SEARCH_CONTROL
PASS:		*ds:si	= ContentFindControlClass object
		ds:di	= ContentFindControlClass instance data
		ds:bx	= ContentFindControlClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFCInitiateSearchControl	method dynamic ContentFindControlClass, 
					MSG_CFC_INITIATE_SEARCH_CONTROL
	.enter
	
	;
	; Check if a SearchReplaceControl object exists
	;
	mov	bx, ds:[di].CFCI_searchController.handle
	tst	bx
	jnz	searchControllerExists

	; Create a SearchReplaceControl object
	call	CFCCreateSearchReplaceController
		; ^lcx:dx <- optr of SearchReplaceControl object
	movdw	bxsi, cxdx
	jmp	initiateController
	
searchControllerExists:
	mov	si, ds:[di].CFCI_searchController.offset

initiateController:
		; ^lbx:si <- SearchReplaceControl object

	;
	; Initiate the SearchReplaceControl object
	;
EC <	call	ECCheckOD						>
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di				; di <- MessageFlags
	call	ObjMessage

	.leave
	ret
CFCInitiateSearchControl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFCCreateSearchReplaceController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup SearchReplaceControl object and return it's OD

CALLED BY:	(INTERNAL) CFCGenControlGenerateUI
PASS:		*ds:si	= ContentFindControlClass object
RETURN:		^lcx:dx	= optr of SearchReplaceControl object
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Duplicate the object resource containing the SearchReplaceControl
	object.
	Save SearchReplaceControl optr in CFCI_searchController instance data.
	Add duplicated SearchReplaceControl object as a child of the 
	ContentFindControl.
	Set the block output of the new object block to be the same as
	the ContentFindControl's output.
	Add SearchReplaceControl to GAGCNLT_SELF_LOAD_OPTIONS list.
	Set SearchReplaceControl usable and enabled.
	Return SearchReplaceControl optr.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFCCreateSearchReplaceController	proc	near
	class	ContentFindControlClass
	uses	ax,bx,si,di,bp
	.enter

	;
	; Duplicate the SearchReplaceControl object block template
	;
	mov	bx, handle ContentFindSearchControlTemplate
	clr	ax, cx					;current thread, geode
	call	ObjDuplicateResource			;bx <- dup'ed block

	; Save the SearchReplaceControl optr to instance data
	mov	di, ds:[si]		
	add	di, ds:[di].ContentFindControl_offset
	mov	dx, offset ContentFindSearchControl	
	movdw	ds:[di].CFCI_searchController, bxdx
				; ^lbx:dx <- SearchReplaceControl object

	;
	; Add SearchReplaceControl object as a child of the 
	;  ContentFindControl object
	;
				; *ds:si <- ContentFindControl object
	mov	cx, bx		; ^lcx:dx <- SearchReplaceControl object
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
	call	ObjCallInstanceNoLock
	
	;
	; Set SearchReplaceControl block's output to the same 
	;  as FindController's output
	;		
	mov	di, ds:[si]		
	add	di, ds:[di].ContentFindControl_offset
	mov	si, dx		; ^lbx:si <- SearchReplaceControl object
EC <	call	ECCheckOD						>
	movdw	cxdx, ds:[di].GCI_output
	mov	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	; Add to GAGCNLT_SELF_LOAD_OPTIONS 
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	dx, GAGCNLT_SELF_LOAD_OPTIONS
	call	MUAddOrRemoveGCNList
		
	; Set SearchReplaceControl usable
		; ^lbx:si should be SearchReplaceControl object
	mov   	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW			; dl <- VisUpdateMode
	mov	di, mask MF_CALL		; di <- MessageFlags
	call	ObjMessage

	; Set SearchReplaceControl enabled
		; ^lbx:si should be SearchReplaceControl object
	mov   	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW			; dl <- VisUpdateMode
	mov	di, mask MF_CALL		; di <- MessageFlags
	call	ObjMessage

	; return OD of SearchReplaceControl object
		; ^lbx:si should be SearchReplaceControl object
EC <	call	ECCheckOD						>
	movdw	cxdx, bxsi

	.leave
	ret
CFCCreateSearchReplaceController	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFCMetaAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the SearchReplaceControl optr is null.
		Only in EC version.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= ContentFindControlClass object
		ds:di	= ContentFindControlClass instance data
		ds:bx	= ContentFindControlClass object (same as *ds:si)
		ax	= message #
	 	cx	- AppAttachFlags
		dx	- Handle of AppLaunchBlock, or 0 if none.
		bp	- Handle of extra state block, or 0 if none.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK

CFCMetaAttach	method dynamic ContentFindControlClass, 
					MSG_META_ATTACH
	uses	ax, cx, dx, bp
	.enter

EC <	tstdw	ds:[di].CFCI_searchController				>
EC <	ERROR_NZ FINDCONTROL_ERROR_SEARCH_CONTROLLER_OPTR_NOT_NULL	>

	.leave
	;
	; Call the superclass.
	;
	mov	di, offset ContentFindControlClass
	call	ObjCallSuperNoLock

	ret
CFCMetaAttach	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFCMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the SearchReplaceControl and call superclass.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= ContentFindControlClass object
		ds:di	= ContentFindControlClass instance data
		ds:bx	= ContentFindControlClass object (same as *ds:si)
		ax	= message #
		cx 	- caller's ID
		dx:bp 	- ack OD
RETURN:		nothing (whatever superclass returns)
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFCMetaDetach	method dynamic ContentFindControlClass, 
					MSG_META_DETACH
	.enter

	call	CFCDestroySearchControl
		; no registers destroyed

	;
	; Call super class
	;
	mov	di, offset ContentFindControlClass
	call	ObjCallSuperNoLock
	
	.leave
	ret
CFCMetaDetach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFCDestroySearchControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the SearchReplaceControl object and null the 
		CFCI_searchController optr.

CALLED BY:	(INTERNAL) CFCMetaDetach, CFCGenControlDestroyUI, 
		CFCGenControlUpdateUI
PASS:		*ds:si	= ContentFindControlClass object
		ds:di	= ContentFindControlClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Since the SearchReplaceControl object is the only object in the 
	duplicated resource, we can free the whole object block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFCDestroySearchControl	proc	near
	class	ContentFindControlClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	movdw	cxdx, ds:[di].CFCI_searchController
	jcxz	nullHandle
	clrdw	ds:[di].CFCI_searchController

	movdw	bxsi, cxdx
EC <	call	ECCheckOD						>

	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	dx, GAGCNLT_SELF_LOAD_OPTIONS
	call	MUAddOrRemoveGCNList

	; destroy the SearchReplaceControl object
	;
	mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
	clr	di
	call	ObjMessage

nullHandle:
	.leave
	ret
CFCDestroySearchControl	endp


ContentFindControlCode ends
