COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		send controller
FILE:		sendcontrolControl.asm

AUTHOR:		Tom Lester, Aug 23, 1994

METHODS:
	Name			Description
	----			-----------
MSG_GEN_CONTROL_GET_INFO	Get GenControl info for the
				ContentSendControlClass

MSG_GEN_CONTROL_UPDATE_UI	Update the controller's UI upon receiving 
				notification of a new book.

MSG_META_ATTACH			Check if the sendDialog and printControl optrs
				are null. Only in EC version.

MSG_META_DETACH			Destroy the sendDialog and printControl and
				call superclass.

MSG_GEN_CONTROL_DESTROY_UI	nuke the sendDialog and printControl and call
				superclass

MSG_CSC_INIT_SEND_DIALOG	Update the text description in the send dialog
				depending on text selection state, then
				initiate it.

MSG_CSC_SEND_TEXT		Send a the selected text/page to either the 
				clipboard or the printer (via print controller).

MSG_CSC_PRINT_TEXT		Print the current text selection or page.

MSG_CSC_COPY_TEXT		Copy current text selection or page to 
				clipboard.

ROUTINES:
	Name			Description
	----			-----------
    INT CSCUpdateSendDialogDescription 
				Upon receiving notification of a text selection change, check if there is a
				selection and set our instance data.

    INT CSCUpdateControlUI Update the controller's UI upon receiving
				notification of a new book.

    INT CSCCustomizeUI Update the Features and Tools

    INT CSC_EnableOrDisable Update the Features and Tools

    INT CSC_EnableOrDisableLow Update the Features and Tools

    INT CSCCustomizeToolUI Adds/Removes tools as specified by
				CSCToolboxFeatures

    INT CSCCreateSendDialogAndPrintControl 
				Create and setup sendDialog and printControl objects.

    INT CSCDestroySendDialogAndPrintControl 
				Destroy the sendDialog and printControl objects and null the
				CSCI_sendDialog and CSCI_printControl
				optrs.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/23/94   	Initial revision

DESCRIPTION:
	Code for the content Send controller.	
		

	$Id: sendcontrolControl.asm,v 1.1 97/04/04 17:50:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentSendControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSendGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the ContentSendControlClass

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
ContentSendGetInfo	method dynamic ContentSendControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset CSC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, (size GenControlBuildInfo)/(size word)
	rep movsw
CheckHack <((size GenControlBuildInfo) and 1) eq 0>
	ret
ContentSendGetInfo	endm

CSC_dupInfo	GenControlBuildInfo	<
	mask GCBF_ALWAYS_UPDATE or \
	mask GCBF_ALWAYS_ON_GCN_LIST or \
	mask GCBF_IS_ON_ACTIVE_LIST or \
	mask GCBF_ALWAYS_INTERACTABLE or \
	mask GCBF_DO_NOT_DESTROY_CHILDREN_WHEN_CLOSED,
					; GCBI_flags
	CSC_IniFileKey,			; GCBI_initFileKey
	CSC_gcnList,			; GCBI_gcnList
	length CSC_gcnList,		; GCBI_gcnCount
	CSC_notifyTypeList,		; GCBI_notificationList
	length CSC_notifyTypeList,	; GCBI_notificationCount
	ContentSendName,		; GCBI_controllerName

	ContentSendUI,			; GCBI_dupBlock
	CSC_childList,			; GCBI_childList
	length CSC_childList,		; GCBI_childCount
	CSC_featuresList,		; GCBI_featuresList
	length CSC_featuresList,	; GCBI_featuresCount
	CSC_DEFAULT_FEATURES,		; GCBI_features

	ContentSendToolUI,		; GCBI_toolBlock
	CSC_toolList,			; GCBI_toolList
	length CSC_toolList,		; GCBI_toolCount
	CSC_toolFeaturesList,		; GCBI_toolFeaturesList
	length CSC_toolFeaturesList,	; GCBI_toolFeaturesCount
	CSC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if 	_FXIP
ConviewControlInfoXIP	segment	resource
endif

CSC_IniFileKey	char	"content send", 0

CSC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, 
			GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_NOTIFY_CONTENT_BOOK_CHANGE>

CSC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SELECT_STATE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_CONTENT_BOOK_CHANGE>

;---

CSC_childList	GenControlChildInfo	\
	<offset ContentSendControlMenu,
		mask CSCF_SEND,
		mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

CSC_featuresList GenControlFeaturesInfo \
	<offset ContentSendControlMenu,
		SendMenuName,
		0>

CSC_toolList	GenControlChildInfo	\
	<offset ContentSendToolSendTrigger,
		mask CSCTF_SEND,
		mask GCCF_IS_DIRECTLY_A_FEATURE>


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.
;
CSC_toolFeaturesList GenControlFeaturesInfo \
	<offset ContentSendToolSendTrigger, 
		SendToolTriggerName,
		0>

if 	_FXIP
ConviewControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCReceiveNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the controller's UI upon receiving notification
		of a new book or a text selection change.

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si	= ContentSendControlClass object
		ds:di	= ContentSendControlClass instance data
		ds:bx	= ContentSendControlClass object (same as *ds:si)
		ax	= message #
		ss:bp 	- GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CSCReceiveNotification	method dynamic ContentSendControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI

EC <	cmp	ss:[bp].GCUUIP_manufacturer, MANUFACTURER_ID_GEOWORKS	>
EC <	ERROR_NE CONTROLLER_UPDATE_UI_UNEXPECTED_NOTIFICATION_TYPE	>

	cmp	ss:[bp].GCUUIP_changeType, GWNT_SELECT_STATE_CHANGE
	jne	bookChange
	call	CSCUpdateSendDialogDescription
	jmp 	done

bookChange:
EC <	cmp	ss:[bp].GCUUIP_changeType, GWNT_CONTENT_BOOK_CHANGE	>
EC <	ERROR_NE CONTROLLER_UPDATE_UI_UNEXPECTED_NOTIFICATION_TYPE	>
	call	CSCUpdateControlUI
done:
	ret
CSCReceiveNotification	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCUpdateSendDialogDescription
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upon receiving notification of a text selection change,
		check if there is a selection and set our instance data.

CALLED BY:	(INTERNAL) CSCReceiveNotification
PASS:		*ds:si	= ContentSendControlClass object
		ss:bp 	- GenControlUpdateUIParams
			  GCUUIP_changeType = GWNT_TEXT_SELECTION_CHANGE
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di,bp
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Passed data block is NotifySelectStateChange.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CSCUpdateSendDialogDescription	proc	near
	class	ContentSendControlClass
	.enter
EC <	cmp	ss:[bp].GCUUIP_manufacturer, MANUFACTURER_ID_GEOWORKS	>
EC <	ERROR_NE CONTROLLER_UPDATE_UI_UNEXPECTED_NOTIFICATION_TYPE	>
EC <	cmp	ss:[bp].GCUUIP_changeType, GWNT_SELECT_STATE_CHANGE	>
EC <	ERROR_NE CONTROLLER_UPDATE_UI_UNEXPECTED_NOTIFICATION_TYPE	>
	;
	; Get data block.
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock	;Get handle of data block
	;
	; Is this a NULL notification?
	;
	tst	bx
	jz	done

	call	MemLock
	mov	es, ax
	;
	; Check if there is a selection.
	;
	mov	cx, CSDDT_PAGE
	cmp	es:[NSSC_clipboardableSelection], BB_TRUE
	jne	noSelection
	cmp	es:[NSSC_selectionType], SDT_TEXT
	jne	noSelection
	mov	cx, CSDDT_SELECTION
noSelection:
		; bx still data block handle
	call	MemUnlock

	mov	di, ds:[si]
	add	di, ds:[di].ContentSendControl_offset
	mov	ds:[di].CSCI_dialogDescription, cx
done:
	.leave
	ret
CSCUpdateSendDialogDescription	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCUpdateControlUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				
SYNOPSIS:	Update the controller's UI upon receiving notification 
		of a new book.

CALLED BY:	(INTERNAL) CSCReceiveNotification
PASS:		*ds:si	= ContentSendControlClass object
		ss:bp 	- GenControlUpdateUIParams
			  GCUUIP_changeType = GWNT_CONTENT_BOOK_CHANGE
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
 	Extract the data out of the given data block.(NotifyContentBookChange)
	Update the regular features (if necessary).
	Update the toolbox features (if necessary).

	If neither send feature or tool is desired, destroy the 
	sendDialog and the PrintControl.

	NOTE: The actuall features/tools can not be found from 
	      GenControlUpdateUIParams because it does not have
	      the actuall features/tools unless the NORMAL_UI/TOOLBOX_UI
	      is set interactable in the TEMP_GEN_CONTROL_INSTANCE vardata.
	      We need to use MSG_GEN_CONTROL_GET_(NORMAL|TOOLBOX)_FEATURES
	      to send the current features.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CSCUpdateControlUI	proc	near
	class	ContentSendControlClass
	.enter
EC <	cmp	ss:[bp].GCUUIP_manufacturer, MANUFACTURER_ID_GEOWORKS	>
EC <	ERROR_NE CONTROLLER_UPDATE_UI_UNEXPECTED_NOTIFICATION_TYPE	>
EC <	cmp	ss:[bp].GCUUIP_changeType, GWNT_CONTENT_BOOK_CHANGE	>
EC <	ERROR_NE CONTROLLER_UPDATE_UI_UNEXPECTED_NOTIFICATION_TYPE	>
	;
	; Get data block.
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock	;Get handle of data block
	;
	; Is this a NULL notification?
	;
	mov	cx, mask CSCFeatures
	mov	dx, mask CSCToolboxFeatures
	tst	bx
	jz	resetUI

	call	MemLock
	mov	es, ax

	;
	; Get desired Book features and convert to CSCFeatures
	;
	clr	cx
	mov	ax, es:[NCBC_features]		; Get desired book features
	test	ax, mask BFF_SEND
	jz	noSendFeatureFlag
	mov	cx, mask CSCF_SEND

noSendFeatureFlag:
	;
	; Get desired Book tools and convert to CSCToolboxFeatures
	;
	clr	dx
	mov	ax, es:[NCBC_tools]		; Get desired book tools
	test	ax, mask BFF_SEND
	jz	noSendToolFlag
	mov	dx, mask CSCTF_SEND

noSendToolFlag:

		; bx still data block handle
	call	MemUnlock

	;
	; Destroy sendDialog and printControl since we don't 
	; need it for this book.
	;
	tstdw	cxdx
	jnz	dontDestroySendDialogAndPrintControl
	call	CSCDestroySendDialogAndPrintControl
dontDestroySendDialogAndPrintControl:
	
		; cx	- desired CSCFeatures record
		; dx	- desired CSCToolboxFeatures record
		; ss:bp - GenControlUpdateUIParams
resetUI:
	call	CSCCustomizeUI

	.leave
	ret
CSCUpdateControlUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCCustomizeUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the Features and Tools

CALLED BY:	(INTERNAL) CSCGenControlUpdateUI
PASS:		*ds:si	= ContentSendControlClass object
		cx	- desired CSCFeatures record
		dx	- desired CSCToolboxFeatures record
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
CSCCustomizeUI		proc	near
		uses	bp
		.enter

	; Do features first
		push	dx			; save CSCToolboxFeatures
		push	si			; save controler chunk handle

	; update the Send normal ui

CheckHack < (mask CSCFeatures) le 00FFh	>	; so we can use byte regs below
		mov	ax, mask CSCF_SEND
		mov	dh, al
		andnf	dh, cl			; dh <- enable or disable
		mov	dl, VUM_NOW
		mov	si, offset ContentSendControlMenu
		call	CSC_EnableOrDisable

	; Now do tools
		pop	si			; restore controler chunk handle
		pop	dx			; restore CSCToolboxFeatures
		call	CSCCustomizeToolUI
		
		.leave
		ret
CSCCustomizeUI		endp

;---

	; ax = bit to test to normal
	; dl = VisUpdateMode
	; dh = non-zero to enable, 0 to disable
	; si = offset for normal obj
	; ss:bp = GenControlUpdateUIParams
	; 	ax,bx,cx,dx,bp - destroyed

CSC_EnableOrDisable	proc	near
	.enter
	test	ax, ss:[bp].GCUUIP_features
	jz	noNormal
	mov	bx, ss:[bp].GCUUIP_childBlock
	call	CSC_EnableOrDisableLow
noNormal:
	.leave
	ret
CSC_EnableOrDisable	endp

;---

	;bx:si - obj
	;dl - VisUpdateMode
	;dh - state
	;	ax, cx, dx, bp - destroyed

CSC_EnableOrDisableLow	proc	near	uses di
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
CSC_EnableOrDisableLow	endp

;---


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCCustomizeToolUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds/Removes tools as specified by CSCToolboxFeatures

CALLED BY:	(INTERNAL) CSCCustomizeUI
PASS:		*ds:si	- controller
		dx	- desired tools (CSCToolboxFeatures)
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
CSCCustomizeToolUI	proc	near
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
CSCCustomizeToolUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCGenControlDestroyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	nuke the sendDialog and printControl and call superclass

CALLED BY:	MSG_GEN_CONTROL_DESTROY_UI
PASS:		*ds:si	= ContentSendControlClass object
		ds:di	= ContentSendControlClass instance data
		ds:bx	= ContentSendControlClass object (same as *ds:si)
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
CSCGenControlDestroyUI	method dynamic ContentSendControlClass, 
					MSG_GEN_CONTROL_DESTROY_UI
	.enter
	call	CSCDestroySendDialogAndPrintControl

	;
	; Call super class
	;
	mov	di, offset ContentSendControlClass
	call	ObjCallSuperNoLock
	
	.leave
	ret
CSCGenControlDestroyUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCCreateSendDialogAndPrintControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and setup sendDialog and printControl objects.

CALLED BY:	CSCGenControlGenerateUI
PASS:		*ds:si	= ContentSendControlClass object
RETURN:		ds:di = ContentSendControl instance data
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Duplicate the object resource containing the sendDialog and 
	printControl objects.
	Save the sendDialog and printControl optrs in the instance data.
	Add duplicated sendDialog and printControl objects as children of
	ContentSendControl.
	Set the block output of the new object block to be the same as
	the ContentSendControl's output.
	Set the destination of the ContentSendDialogApplyTrigger to the 
	ContentSendControl object.
	Add printControl to GAGCNLT_SELF_LOAD_OPTIONS list.
	Set sendDialog and printControl usable and enabled.

	NOTES:
	The ContentSendDialogApplyTrigger needs it's destination set up 
	so it's action message is sent to the ContentSendControl object.
	The printControl needs it's printOutput and docNameOutput set up
	to point at the ContentGenView object in the application.

	The best way to get the printControl outputs set correctly,
	is to set things up like this.
		Have the ContentSendControl's output be set to the 
		ContentGenView object in the application .ui file.
		Then set the obj_block_output of the duplicated
		block the same as the ContentSendControl's output.
		In the .ui file with the resouce template, have the 
		printControl's outputs set to "TO_OBJ_BLOCK_OUTPUT".

	And we use MSG_GEN_TRIGGER_SET_DESTINATION to set the 
	ContentSendDialogApplyTrigger destination to the 
	ContentSendControl object.

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/01/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CSCCreateSendDialogAndPrintControl	proc	near
	class	ContentSendControlClass
	uses	bp
	.enter

	;
	; Duplicate the template with the print control
	;
	mov	bx, handle ContentPrintTemplate
	mov	dx, offset ContentSendPrintControl
	call	DuplicateAndAdd				;^lcx:dx <- PrintCtrl

	mov	di, ds:[si]		
	add	di, ds:[di].ContentSendControl_offset
EC <	tst	ds:[di].CSCI_printController.handle			>
EC <	ERROR_NZ SENDCONTROL_ERROR_OPTR_NOT_NULL			>
	movdw	ds:[di].CSCI_printController, cxdx    ; save printControl optr

	;
	; Duplicate the template with the send dialog
	;
	mov	bx, handle ContentSendTemplate
	mov	dx, offset ContentSendDialog
	call	DuplicateAndAdd				;^lcx:dx <-sendDialog
	mov	di, ds:[si]		
	add	di, ds:[di].ContentSendControl_offset
EC <	tst	ds:[di].CSCI_sendDialog.handle				>
EC <	ERROR_NZ SENDCONTROL_ERROR_OPTR_NOT_NULL			>
	movdw	ds:[di].CSCI_sendDialog, cxdx	      ; save sendDialog optr

	;
	; Set destination of ContentSendDialogApplyTrigger to be the
	;  ContentSendControl object.
	;
	push	si
	mov	bx, cx				;^hbx <- sendDialog block
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; ^lcx:dx <- SendControl object
	mov	si, offset ContentSendDialogApplyTrigger
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	;
	; Add printControl to GAGCNLT_SELF_LOAD_OPTIONS 
	;
	mov	di, ds:[si]		
	add	di, ds:[di].ContentSendControl_offset
	movdw	cxdx, ds:[di].CSCI_printController

	push	si
	movdw	bxsi, cxdx
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	dx, GAGCNLT_SELF_LOAD_OPTIONS
	call	MUAddOrRemoveGCNList
	pop	si
		
	call	setUsable			; set print control usable

	movdw	cxdx, ds:[di].CSCI_sendDialog
	call	setUsable			; set send dialog usable
	.leave
	ret

setUsable:
	;
	; ^lcx:dx - object to set usable and enabled
	;
	push	si
	movdw	bxsi, cxdx
EC <	call	ECCheckOD					>
	mov   	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov   	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si
	mov	di, ds:[si]		
	add	di, ds:[di].ContentSendControl_offset
	retn
		
CSCCreateSendDialogAndPrintControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DuplicateAndAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate a template resource and add an object tree
		to the ContentSendControl.

CALLED BY:	CSCCreateSendDialogAndPrintControl
PASS:		*ds:si - ContentSendControl
		^hbx - resource to duplicate
		dx - chunk handle of object to add

RETURN:		^hcx:dx - duplicated object tree
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/21/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DuplicateAndAdd		proc	near
		uses	bp
		class   ContentSendControlClass
		.enter
		
		clr	ax, cx				;current thread, geode
		call	ObjDuplicateResource		;bx <- dup'ed block
	
	;
	; Set duplicated block's output to the same as 
	;  ContentSendControl's output
	;		
		push	bx, dx, si		; save sendControl object lptr
		mov	di, ds:[si]		
		add	di, ds:[di].ContentSendControl_offset
		mov	si, dx			; ^lbx:si <- new object
EC <		call	ECCheckOD					>

		movdw	cxdx, ds:[di].GCI_output
		mov	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx, dx, si
	;
	; Add new object as child of ContentSendControl
	;
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
		call	ObjCallInstanceNoLock
		
		.leave
		ret
DuplicateAndAdd		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCMetaAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the sendDialog and printControl optrs are null.
		Only in EC version.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= ContentSendControlClass object
		ds:di	= ContentSendControlClass instance data
		ds:bx	= ContentSendControlClass object (same as *ds:si)
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

CSCMetaAttach	method dynamic ContentSendControlClass, 
					MSG_META_ATTACH
	uses	ax, cx, dx, bp
	.enter

	; check sendDialog optr 
	;
EC <	tstdw	ds:[di].CSCI_sendDialog					>
EC <	ERROR_NZ SENDCONTROL_ERROR_OPTR_NOT_NULL			>
		
	; check printControl optr
	;
EC <	tstdw	ds:[di].CSCI_printController				>
EC <	ERROR_NZ SENDCONTROL_ERROR_OPTR_NOT_NULL			>

	.leave
	;
	; Call the superclass.
	;
	mov	di, offset ContentSendControlClass
	call	ObjCallSuperNoLock

	ret
CSCMetaAttach	endm

endif ; ERROR_CHECK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the sendDialog and printControl and call superclass.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= ContentSendControlClass object
		ds:di	= ContentSendControlClass instance data
		ds:bx	= ContentSendControlClass object (same as *ds:si)
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
CSCMetaDetach	method dynamic ContentSendControlClass, 
					MSG_META_DETACH
	.enter

	call	CSCDestroySendDialogAndPrintControl
	;
	; Call super class
	;
	mov	di, offset ContentSendControlClass
	call	ObjCallSuperNoLock
	
	.leave
	ret
CSCMetaDetach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCDestroySendDialogAndPrintControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the sendDialog and printControl objects and null 
		the CSCI_sendDialog and CSCI_printControl optrs.

CALLED BY:	(INTERNAL) CSCMetaDetach, CSCGenControlDestroyUI, 
		CSCGenControlUpdateUI
PASS:		*ds:si	= ContentSendControlClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This code uses the face that the sendDialog and printControl are
	always created and destroyed together. Thus, if we find that the 
	sendDialog exists, we are sure that the printControl also exits.
	The same reasoning holds in the other case, if we find the
	sendDialog does not exist, we are sure that the printControl also
	does not exits.

	Since we are destroying all the objects in the duplicated resource
	we can free the whole object block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CSCDestroySendDialogAndPrintControl	proc	near
	class	ContentSendControlClass
	uses	ax,bx,cx,dx,bp,si
	.enter

	;
	; check if the sendDialog exists
	;
	push	si		
	mov	di, ds:[si]
	add	di, ds:[di].ContentSendControl_offset

	movdw	bxsi, ds:[di].CSCI_sendDialog	
	tst	bx
	jz	noSendDialog
	clrdw	ds:[di].CSCI_sendDialog		; set instance data null
	;
	; destroy the sendDialog
	;
EC <	call	ECCheckOD						>
	mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
	clr	di
	call	ObjMessage

noSendDialog:
	pop	si				;*ds:si <- ContentSendControl
	mov	di, ds:[si]
	add	di, ds:[di].ContentSendControl_offset

	movdw	cxdx, ds:[di].CSCI_printController
	jcxz	noPrintControl
	clrdw	ds:[di].CSCI_printController	;set instance data to null

	movdw	bxsi, cxdx
	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	dx, GAGCNLT_SELF_LOAD_OPTIONS
	call	MUAddOrRemoveGCNList
	;
	; destroy the printControl
	;
EC <	call	ECCheckOD						>
	mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
	clr	di
	call	ObjMessage

noPrintControl:

	.leave
	ret
CSCDestroySendDialogAndPrintControl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCInitSendDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the text description in the send dialog
		depending on text selection state, then initiate it.

CALLED BY:	MSG_CSC_INIT_SEND_DIALOG
PASS:		*ds:si	= ContentSendControlClass object
		ds:di	= ContentSendControlClass instance data
		ds:bx	= ContentSendControlClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp, bx, si, di, ds, es (method handler)
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Create sendDialog and PrintController if not already existing.
	Update description in the send dialog.
	Initiate the sendDialog

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/18/94		Initial version
	lester	9/ 1/94   	moved from app to send controller

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CSCInitSendDialog	method dynamic ContentSendControlClass, 
					MSG_CSC_INIT_SEND_DIALOG
	.enter
EC <	cmp	ds:[di].CSCI_dialogDescription,ContentSendDialogDescripionType>
EC <	ERROR_AE SENDCONTROL_INVALID_DIALOG_DESCRIPTION_TYPE		>
	;
	; Check if a sendDialog exists and create one is needed
	;
	tst	ds:[di].CSCI_sendDialog.handle
	jnz	sendDialogExists
	call	CSCCreateSendDialogAndPrintControl	; Create a sendDialog

sendDialogExists:
	mov	bx, handle ContentSendStrings
	call	MemLock
	mov	es, ax
	mov	cx, ax

	mov	bx, offset SendPageString	;*cx:bx <- moniker text
	cmp	ds:[di].CSCI_dialogDescription, CSDDT_PAGE
	je	haveMoniker
	mov	bx, offset SendSelectionString
		
haveMoniker:
	mov	dx, es:[bx]			;cx:dx <- moniker text

	mov	bx, ds:[di].CSCI_sendDialog.handle
	mov	si, offset ContentSendDialogMessage
				; ^lbx:si <- ContentSendDialogMessage
EC <	call	ECCheckOD						>
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage

	push	bx		
	mov	bx, handle ContentSendStrings
	call	MemUnlock
	pop	bx
	;
	; Initiate the send dialog
	;	
	mov	si, offset ContentSendDialog
EC <	call	ECCheckOD						>
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage

	.leave
	ret
CSCInitSendDialog	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCSendText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a the selected text/page to either the clipboard or
		the printer (via print controller).

CALLED BY:	MSG_CSC_SEND_TEXT
PASS:		*ds:si	= ContentSendControlClass object
		ds:di	= ContentSendControlClass instance data
		ds:bx	= ContentSendControlClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Determine which item was selected: clipboard or
		printer.
		If clipboard, send message to test object to copy text to
		clipboard (we bypass the GenEditControl object).
		If printer, initate ContentSendPrinter.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CSCSendText	method dynamic ContentSendControlClass, 
					MSG_CSC_SEND_TEXT

	;
	; Get the GenItemGroup into ^lbx:si.
	;
		push	si
		mov	bx, ds:[di].CSCI_sendDialog.handle
		mov	si, offset ContentSendDialogOptionList
	;
	; Get its selection.
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage			;ax=selection
		mov	cx, ax
		pop	si			
	;
	; Determine user selection.
	;
		mov	ax, MSG_CSC_COPY_TEXT
		cmp	cx, CSOIT_CLIPBOARD
		je	send
		mov	ax, MSG_CSC_PRINT_TEXT

send::
		GOTO	ObjCallInstanceNoLock
CSCSendText	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCCopyText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy current text selection or page to clipboard.

CALLED BY:	MSG_CSC_COPY_TEXT
PASS:		*ds:si	= ContentSendControlClass object
		ds:di	= ContentSendControlClass instance data
		ds:bx	= ContentSendControlClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp, bx, si, di, ds, es (method handler)
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	If you modify this, be carefull to avoid deadlock. Don't use a 
	call to an object on the process thread.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/04/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CSCCopyText	method dynamic ContentSendControlClass, 
					MSG_CSC_COPY_TEXT

	mov	ax, MSG_CGV_GET_TEXT_OD
	movdw	bxsi, ds:[di].GCI_output	; ^lbx:si <- ContentGenView object
	mov	di, mask MF_CALL
	call	ObjMessage			
	jc	noTextObject
	movdw	bxsi, cxdx			; ^lbx:si <- ContentText object

	mov	ax, MSG_META_CLIPBOARD_COPY
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
noTextObject:
	ret
CSCCopyText	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CSCPrintText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the current text selection or page.

CALLED BY:	MSG_CSC_PRINT_TEXT
PASS:		*ds:si	= ContentSendControlClass object
		ds:di	= ContentSendControlClass instance data
		ds:bx	= ContentSendControlClass object (same as *ds:si)
		ax	= message #
RETURN:		
DESTROYED:	ax,cx,dx,bp, bx, si, di, ds, es (method handler)
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CSCPrintText	method dynamic ContentSendControlClass, 
					MSG_CSC_PRINT_TEXT
	;
	; Check if a printControl exists and create one is needed
	;
	tst	ds:[di].CSCI_printController.handle
	jnz	printControlExists

	call	CSCCreateSendDialogAndPrintControl

printControlExists:
	movdw	bxsi, ds:[di].CSCI_printController
	mov	ax, MSG_PRINT_CONTROL_INITIATE_PRINT
	clr	di
	GOTO	ObjMessage
CSCPrintText	endm


ContentSendControlCode ends

