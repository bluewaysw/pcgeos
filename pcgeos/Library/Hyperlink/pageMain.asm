COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Hyperlink Library
FILE:		pageMain.asm

AUTHOR:		Cassie Hartzog, Jun 2, 1994

ROUTINES:
	Name			Description
	----			-----------
MSG_META_ATTACH			Cause the controller's UI to be generated
MSG_GEN_CONTROL_GET_INFO	Get GenControlBuildInfo for controller
MSG_GEN_CONTROL_UPDATE_UI	Update UI for controller
MSG_META_NOTIFY			Respond to a notification that the current
				column (hard-page) has changed

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/02/94		Initial revision
	jenny	8/31/94		Simplified UI and fixed stuff

DESCRIPTION:
	Main code for Page controller.

	$Id: pageMain.asm,v 1.1 97/04/04 18:09:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HyperlinkAndPageNameControlCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return GenControlBuildInfo for page controller
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si	= instance data
		ds:di	= *ds:si
		es	= seg addr of PageNameControlClass
		ax	= the method

		cx:dx	= GenControlBuildInfo structure

RETURN:		cx:dx	= GenControlBuildInfo structure filled

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/02/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNCGetInfo	method dynamic PageNameControlClass, \
						MSG_GEN_CONTROL_GET_INFO

		segmov	ds, cs
		mov	si, offset PNC_dupInfo		;ds:si <- source
		mov	es, cx
		mov	di, dx				;es:di <- dest
		mov	cx, size GenControlBuildInfo
		rep	movsb
		ret
PNCGetInfo	endm

PNC_dupInfo	GenControlBuildInfo	<
	PNC_BUILD_FLAGS,		; GCBI_flags
	PNC_initFileKey,		; GCBI_initFileKey
	PNC_gcnList,			; GCBI_gcnList
	length PNC_gcnList,		; GCBI_gcnCount
	PNC_notifyTypeList,		; GCBI_notificationList
	length PNC_notifyTypeList,	; GCBI_notificationCount
	PCName,				; GCBI_controllerName

	handle PageNameControlUI,	; GCBI_dupBlock
	PNC_childList,			; GCBI_childList
	length PNC_childList,		; GCBI_childCount
	PNC_featuresList,		; GCBI_featuresList
	length PNC_featuresList,		; GCBI_featuresCount
	PNC_DEFAULT_FEATURES,		; GCBI_features
	handle PageNameControlToolUI,	; GCBI_toolBlock
	PNC_toolList,			; GCBI_toolList
	length PNC_toolList,		; GCBI_toolCount
	PNC_toolFeaturesList,		; GCBI_toolFeaturesList
	length PNC_toolFeaturesList,	; GCBI_toolFeaturesCount
	PNC_DEFAULT_TOOLBOX_FEATURES,	
					; GCBI_toolFeatures
	0>				; GCBI_helpContext

;---

PNC_BUILD_FLAGS	equ	mask GCBF_SUSPEND_ON_APPLY 

PNC_initFileKey	char	"Page", 0

PNC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_DOCUMENT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_PAGE_NAME_CHANGE>

PNC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_DOCUMENT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_PAGE_NAME_CHANGE>

;---

PNC_childList	GenControlChildInfo	\
	<offset PageNameDialog,	mask PNCF_PAGE_DIALOG,
				mask GCCF_ALWAYS_ADD>,
	<offset PageClearTrigger,
				mask PNCF_CLEAR,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PageClearAllTrigger,
				mask PNCF_CLEAR_ALL,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

PNC_featuresList	GenControlFeaturesInfo	\
	<offset PageNameDialog, PCName, 0>,
	<offset PageClearTrigger, PageClearName, 0>,
	<offset PageClearAllTrigger, PageClearAllName, 0>
;---

PNC_toolList	GenControlChildInfo	\
	<offset PageStatusBarInteraction, mask PNCTF_STATUS_BAR, mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

PNC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset PageStatusBarInteraction, PCStatusBarName, 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for PageNameControlClass
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of PageNameControlClass
		ax - the message

		ss:bp - GenControlUpdateUIParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/18/94		Initial version
	jenny	8/29/94		Simplified

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNCUpdateUI	method dynamic PageNameControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI

 		call	LockDataBlock		; es:0 <- notification block
		mov	bx, ss:[bp].GCUUIP_childBlock

		cmp	ss:[bp].GCUUIP_changeType, GWNT_DOCUMENT_CHANGE
		je	updateForDocChange
		cmp	ss:[bp].GCUUIP_changeType, GWNT_PAGE_NAME_CHANGE
		je	updateForPageNameChange
EC <		cmp	ss:[bp].GCUUIP_changeType, GWNT_TEXT_NAME_CHANGE>
EC <		ERROR_NE	-1 					>

	;
	; update the PageName list
	;
		call	PageForceUpdateUI
done:
		call	UnlockDataBlock
		ret

updateForDocChange:
	;
	; If the current document has changed, clear the status bar.
	; When the text gains the target, it will send out a PAGE_NAME_CHANGE
	; notification, which will correctly update the status bar.
	;
		mov	ax, es:[NDC_fileHandle]
		cmp	ds:[di].PNCI_currentDoc, ax
		je	statusBarOK
		mov	ds:[di].PNCI_currentDoc, ax
		mov	ax, GIGS_NONE
		jmp	updateStatusBar

updateForPageNameChange:
	;
	; The current page has changed.  Save the new page number.
	;
		mov	ax, es:[NPNC_index]
		mov	ds:[di].PNCI_currentPage, ax

updateStatusBar:
	;
	; Update the status bar, if there is one.
	;
		tst	ss:[bp].GCUUIP_toolboxFeatures
		jz	statusBarOK
		call	PageChangeStatusBar

statusBarOK:
	;
	; If features aren't interactible, we won't update them now.
	;
		tst	ss:[bp].GCUUIP_features
		jz	done
	;
	; Update the dialog's list, text, and trigger.
	;
		mov	ax, GIGS_NONE		; ax <- don't set a selection
		call	UpdatePageNameDialogUI
		jmp	done

PNCUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageChangeStatusBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A page name change notification has been received.
		Update the status bar if necessary.

CALLED BY:	PNCUpdateUI
PASS:		*ds:si - controller
		ax - GIGS_NONE to clear status bar, or
		es:0 - NotifyPageNameChange

RETURN:		nothing
DESTROYED:	ax,cx,dx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PageChangeStatusBar		proc	near
		uses	bx, bp
		.enter

		push	ax
		call	GetToolBlockAndFeatures
		test	ax, mask PNCTF_STATUS_BAR		
		pop	ax
		jz	done

		cmp	ax, GIGS_NONE
		je	noName

		mov	dx, es
		lea	bp, es:[NPNC_name]
		mov	cx, es:[NPNC_length]
		mov	di, offset PageStatusBarText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjMessageCall
done:
		.leave
		ret

noName:
		mov	di, offset PageStatusBarText
		call	ClearNameField
		jmp	done	

PageChangeStatusBar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageForceUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for the PageController

CALLED BY:	PNCUpdateUI
PASS:		*ds:si - controller
		ds:di - *ds:si
		ax - features mask
		bx - hptr of child block
		es:0 - VisTextNotifyNameChange
RETURN:		nothing
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/ 2/94		Initial version
	jenny	8/30/94		Simplified and fixed to update status bar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PageForceUpdateUI	proc	near
		uses	bx, bp
		class PageNameControlClass
		.enter
	;
	; We don't need to update the page list when we've
	; changed a file name, or a context defined in some other
	; file than the current file.
	; 
		cmp	es:[VTNNC_type], VTNT_FILE
		je	done
		cmp	es:[VTNNC_fileIndex], 0
		jne	done
	;
	; If this is a null notification, we don't need to update
	; (null notifications are sent by the text object when it
	; regains the target exclusive).
	;
		mov	cl, es:[VTNNC_changeType]
		cmp	cl, VTNCT_NULL
		je	done
	;
	; If the features are not interactable, we're done.
	;
		tst	ax			;any normal UI features on?
		jz	done			;no, don't update yet
	;
	; Update the dialog box and then see if we deleted a context
	; name. If so, we're done. Note that if we deleted the current
	; page's name, a GWNT_PAGE_NAME_CHANGE notification will cause us
	; to update the status bar elsewhere.
	;
		mov	ax, GIGS_NONE		; ax <- no selection
		call	UpdatePageNameDialogUI
		cmp	cl, VTNCT_REMOVE
		je	done
	;
	; Only if the name of the current page changed need we update
	; the status bar.
	;
		mov	cx, es:[VTNNC_index]
		cmp	cx, ds:[di].PNCI_currentPage
		jne	done
		mov	ax, MSG_PNC_SET_PAGE_STATUS_BAR_TEXT
		call	GetTextMonikerForPage
done:
		.leave
		ret

PageForceUpdateUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePageNameDialogUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI in the PageNameDialog.

CALLED BY:	INTERNAL	PNCUpdateUI
				PageForceUpdateUI

PASS:		*ds:si	= controller
		ax 	= list item to select
		bx	= hptr of child block

RETURN:		nothing
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/13/94		Initial version
	jenny	8/30/94		Changed name; now updates text and trigger

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePageNameDialogUI		proc	near
		uses	cx, di
		.enter		

		tst	bx
		jz	done
	;
	; First update the list.
	;
		mov	di, offset PageNameList
		mov	cl, VTNT_CONTEXT	;cl <- VisTextNameType
		clr	dx			;0 == same file list index
		call	UpdateListLower
	;
	; Update the text and trigger according to the selection.
	;
		mov_tr	cx, ax			; cx <- no selection
		call	UpdatePageNameTextAndTrigger
done:
		.leave
		ret
UpdatePageNameDialogUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePageSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the page list selection and UI that depends on it.

CALLED BY:	INTERNAL	PNCClearPageName
				PNCClearAllPages

PASS:		*ds:si	= controller
		ax	= page index

RETURN:		bx	= child block
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/ 2/94		Initial version
	jenny	9/ 5/94		Rewrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePageSelection		proc	near
		class	PageNameControlClass
		uses	ax
		.enter
	;
	; Select the correct page entry in the PageNameList.
	;
		mov_tr	cx, ax
		call	UpdatePageSelectionLow
	;
	; Update PageNameText and PageNameTrigger according to the selection.
	;
		call	UpdatePageNameTextAndTrigger
		.leave
		ret
UpdatePageSelection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePageSelectionLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the page list selection.

CALLED BY:	INTERNAL	UpdatePageSelection
				PNCTextUserModified

PASS:		*ds:si	= controller
RETURN:		bx	= child block
DESTROYED:	dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 5/94    	Broke out of UpdatePageSelection

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePageSelectionLow	proc	near
		uses	di
		.enter

		call	GetChildBlockAndFeatures
		mov	di, offset PageNameList
		call	SetListSelectionNoIndeterminates
		.leave
		ret
UpdatePageSelectionLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePageNameTextAndTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update PageNameText and PageNameTrigger according to
		passed PageNameList selection

CALLED BY:	INTERNAL	PNCPageListPageChanged
				UpdatePageNameDialogUI
				UpdatePageSelection

PASS:		*ds:si	= controller
		bx	= handle of child block
		cx	= page selected
RETURN:		nothing
DESTROYED:	ax, dx, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePageNameTextAndTrigger	proc	near
		uses	si
		class	PageNameControlClass
		.enter
	;
	; We're scrapping any changes the user may have made to the
	; text field.
	;
		mov	di, ds:[si]
		add	di, ds:[di].PageNameControl_offset
		mov	ds:[di].PNCI_nameUserModified, FALSE
	;
	; Arrange to set the page name text field with the moniker of
	; the passed selection.
	;
		cmp	cx, GIGS_NONE
		je	clearText
		mov	ax, MSG_PNC_SET_PAGE_NAME_TEXT
		call	GetTextMonikerForPage
updateTrigger:
	;
	; Enable/disable the trigger.
	;
		call	UpdatePageTrigger
		.leave
		ret

clearText:
		mov	di, offset PageNameText
		call	ClearNameField
		jmp	updateTrigger

UpdatePageNameTextAndTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextMonikerForPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Arrange to get the text moniker for a page.

CALLED BY:	INTERNAL	PageForceUpdateUI
				UpdatePageNameTextAndTrigger

PASS:		ax	= message to send ourselves
		cx	= index of page

RETURN:		nothing
DESTROYED:	ax, dx, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextMonikerForPage	proc	near
		uses	bx, cx, bp
		.enter
	;
	; Specify what moniker we want and that we want it sent to us.
	;
		call	GetControllerOD		; ^lbx:di <- controller
		mov	bp, cx			; bp <- selection
		mov	cl, VTNT_CONTEXT	; cl <- VisTextNameType
		clr	ch			; want text moniker
		clr	dx			; current file
		call	GetNameMonikerFrame
		.leave
		ret
GetTextMonikerForPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePageTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/disable the PageNameTrigger according to the selection.

CALLED BY:	INTERNAL	UpdatePageNameTextAndTrigger

PASS:		bx	= handle of child block
		cx	= selection
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePageTrigger	proc	near
		uses	si
		.enter

		mov_tr	ax, cx			; ax <- selection
		mov	si, offset PageNameTrigger
		call	EnableDisableBasedOnSelection
		.leave
		ret
UpdatePageTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNCPageListGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a moniker for the page list

CALLED BY:	MSG_PNC_PAGE_LIST_GET_MONIKER
PASS:		*ds:si	= PageNameControlClass object
		ds:di	= PageNameControlClass instance data
		ds:bx	= PageNameControlClass object (same as *ds:si)
		es 	= segment of PageNameControlClass
		ax	= message #

		^lcx:dx	= file list 
		bp	= position of item whose moniker is requested

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/29/94   	Initial version
	jenny	8/16/94		Changed to use common routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNCPageListGetMoniker	method dynamic PageNameControlClass, 
					MSG_PNC_PAGE_LIST_GET_MONIKER
	;
	; tell GetNameMonikerFrame what it needs to know.
	;
		movdw	bxdi, cxdx		;^lbx:di <- list
		clr	dx			;0 == same file index
		mov	ch, mask VTNCF_COLOR_MONIKERS_FOR_UNSET_CONTEXTS
		call	PageListGetMonikerLow
		ret
PNCPageListGetMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNCApplyPageName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new page name.

CALLED BY:	MSG_PNC_ADD_PAGE_NAME
PASS:		*ds:si	= PageNameControlClass object
		ds:di	= PageNameControlClass instance data
		ds:bx	= PageNameControlClass object (same as *ds:si)
		es 	= segment of PageNameControlClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp
SIDE EFFECTS:	
	Causes a notification of type GWNT_TEXT_NAME_CHANGE to be sent.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/6/94   	Initial version
	jenny	8/30/94		Rewrote to do both name & rename and
				 to redirect hyperlinks

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNCApplyPageName	method dynamic PageNameControlClass, 
					MSG_PNC_APPLY_PAGE_NAME
	;
	; Get the OD of the PageNameText object.
	;
		mov	bp, di			; ds:bp <- instance data
		call	GetChildBlockAndFeatures
		mov	di, offset PageNameText	; ^lbx:di <- PageNameText
	;
	; Find out if the current page already has a name.
	; If so, we do a rename; if not, we simply set the name.
	;
		clr	cl			; cl <- VisTextSetContextFlags
		cmp	ds:[bp].PNCI_currentPage, GIGS_NONE
		jne	doRename
finalFlags:
	;
	; If the user has typed in the name to PageNameText, make sure
	; that it won't be used if it's already been applied to a page.
	; (If the name has come from a list selection, on the other
	; hand, we know it hasn't been used yet, since used names are
	; disabled.)
	;
	; XXX:	The above comment would again apply and these lines
	; 	could be re-added if
	; 	VTNCF_DISABLE_MONIKERS_FOR_SET_CONTEXTS were again
	;	passed from PNCPageListGetMoniker to PageListGetMonikerLow.
	;	Perhaps the application should be able to specify
	;	whether it wants used names disabled. -jenny, 11/23/94
	;
;		cmp	ds:[bp].PNCI_nameUserModified, TRUE
;		jne	setName
;		or	cl, mask VTCF_ENSURE_CONTEXT_NOT_ALREADY_SET
;setName:
	;
	; Set the context.
	;
		mov     dx, (size VisTextSetContextParams)
		sub     sp, dx
		mov     bp, sp			; ss:bp <- params
		movdw	ss:[bp].VTSCXP_object, bxdi
		mov     ss:[bp].VTSCXP_range.VTR_start.high, \
				VIS_TEXT_RANGE_SELECTION
		mov     ss:[bp].VTSCXP_flags, cl
		mov	ax, MSG_VIS_TEXT_SET_CONTEXT_GIVEN_NAME_TEXT
		call    SendToOutputStack
		add     sp, dx
done:
		ret
doRename:
	;
	; Ask user what to do with any hyperlinks set to the old name.
	;
		call	DoRenamePageDialog
		cmp	ax, IC_DISMISS
		je	done
	;
	; Should the hyperlinks be moved to point to the new name?
	;
		cmp	ax, IC_YES
		jne	finalFlags
		or	cl, mask VTCF_REDIRECT_HYPERLINKS
		jmp	finalFlags

PNCApplyPageName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNCClearPageName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Warn the user, clear the selected context, and update
		the selection.

CALLED BY:	MSG_PNC_CLEAR_PAGE_NAME
PASS:		*ds:si	= PageNameControlClass object
		ds:di	= PageNameControlClass instance data
		ds:bx	= PageNameControlClass object (same as *ds:si)
		es 	= segment of PageNameControlClass
		ax	= message #
		cl	= ClearPageNameFlag
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/28/94   	Initial version
	jenny	8/22/94		Simplified

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNCClearPageName		method dynamic PageNameControlClass, 
					MSG_PNC_CLEAR_PAGE_NAME
	;
	; Put up a warning dialog
	;
		mov	bp, HW_WILL_DELETE_THIS_PAGES_NAME
		call	AchtungAchtung
		cmp	ax, IC_NO
		je	done
	;
	; Clear the name and update the list.
	;
		mov	ax, GIGS_NONE
		mov	ds:[di].PNCI_currentPage, ax
		call	ApplyPageNameLow
		call	UpdatePageSelection
done:		
		ret
PNCClearPageName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNCClearAllPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear all pages for the document.

CALLED BY:	MSG_PNC_CLEAR_ALL_PAGES
PASS:		*ds:si	= PageNameControlClass object
		ds:di	= PageNameControlClass instance data
		ds:bx	= PageNameControlClass object (same as *ds:si)
		es 	= segment of PageNameControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNCClearAllPages	method dynamic PageNameControlClass, 
					MSG_PNC_CLEAR_ALL_PAGES
	;
	; Put up a warning dialog
	;
		mov	bp, HW_WILL_DELETE_ALL_PAGE_NAMES
		call	AchtungAchtung
		cmp	ax, IC_NO
		je	done
	;
	; We unset all contexts over the entire range of the text.
	;
		mov	dx, (size VisTextSetContextParams)
		sub	sp, dx
		mov	bp, sp				;ss:bp <- params
		movdw	ss:[bp].VTSCXP_range.VTR_start, 0
		movdw	ss:[bp].VTSCXP_range.VTR_end, TEXT_ADDRESS_PAST_END
		mov	ax, MSG_VIS_TEXT_UNSET_ALL_CONTEXTS
		call	SendToOutputStack
		add	sp, dx

		mov	ax, GIGS_NONE
		mov	ds:[di].PNCI_currentPage, ax
		call	UpdatePageSelection
done:
		ret
PNCClearAllPages	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNCPageListPageChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI when page list selection changes.

CALLED BY:	MSG_PNC_PAGE_LIST_PAGE_CHANGED

PASS:		*ds:si	= PageNameControlClass object
		ds:di	= PageNameControlClass instance data
		ds:bx	= PageNameControlClass object (same as *ds:si)
		es 	= segment of PageNameControlClass
		ax	= message #

		cx	= current page list selection

RETURN:		nothing
DESTROYED:	ax, bx, dx, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNCPageListPageChanged	method dynamic PageNameControlClass, 
					MSG_PNC_PAGE_LIST_PAGE_CHANGED

		call	GetChildBlockAndFeatures
		call	UpdatePageNameTextAndTrigger
		ret
PNCPageListPageChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNCSetPageNameText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The currently selected page has changed.  Update the
		text field to display the new name.

CALLED BY:	MSG_PNC_SET_PAGE_NAME_TEXT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of PageNameControlClass
		ax - the message

		ss:bp	= ReplaceItemMonikerFrame

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/17/94		Initial version
	jenny	7/ 6/94    	Broke out SetNameField
	jenny	8/28/94		Revised

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNCSetPageNameText	method dynamic PageNameControlClass,
						MSG_PNC_SET_PAGE_NAME_TEXT
	;	
	; Replace and select the text in PageNameText.
	;
		mov	di, offset PageNameText
		mov	cl, mask SNFF_SELECT
		call	SetChildBlockNameFieldFromMonikerFrame
		ret
PNCSetPageNameText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNCSetPageStatusBarText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text in PageStatusBarText.

CALLED BY:	MSG_PNC_SET_PAGE_STATUS_BAR_TEXT
PASS:		*ds:si	= PageNameControlClass object
		ds:di	= PageNameControlClass instance data
		ds:bx	= PageNameControlClass object (same as *ds:si)
		es 	= segment of PageNameControlClass
		ax	= message #

		ss:bp	= ReplaceItemMonikerFrame

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNCSetPageStatusBarText	method dynamic PageNameControlClass, 
					MSG_PNC_SET_PAGE_STATUS_BAR_TEXT
	;
	; Replace the text in PageStatusBarText.
	;
		call	GetToolBlockAndFeatures
		mov	di, offset PageStatusBarText
		clr	cl			; don't select text
		call	SetNameFieldFromMonikerFrame
		ret
PNCSetPageStatusBarText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PNCTextUserModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the page list selection when the user changes
		the text in PageNameText.

CALLED BY:	MSG_META_TEXT_USER_MODIFIED
PASS:		*ds:si	= PageNameControlClass object
		ds:di	= PageNameControlClass instance data
		ds:bx	= PageNameControlClass object (same as *ds:si)
		es 	= segment of PageNameControlClass
		ax	= message #

		cx:dx	= text object OD

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PNCTextUserModified	method dynamic PageNameControlClass, 
					MSG_META_TEXT_USER_MODIFIED
	;
	; Make sure the text object in question is PageNameText.
	;
		call	GetChildBlockAndFeatures	; bx <- block
		cmp	bx, cx		
		jne	done
		cmp	dx, offset PageNameText
		jne	done
	;
	; Record that the user entered the page name now in the field.
	;
		mov	ds:[di].PNCI_nameUserModified, TRUE
	;
	; Clear the page list selection.
	;
		mov	ax, GIGS_NONE
		call	UpdatePageSelectionLow
done:
		ret
PNCTextUserModified	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ApplyPageNameLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply a name to the current page

CALLED BY:	INTERNAL	PNCApplyPageName
				ClearPageName

PASS:		*ds:si - controller
		ax - list index of name to use
RETURN:		nothing
DESTROYED:	
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ApplyPageNameLow		proc	near
		uses	ax,dx,bp
		.enter
       ;
       ;  add a page name at the current text selection
       ;
		mov     dx, (size VisTextSetContextParams)
		sub     sp, dx
		mov     bp, sp                          ;ss:bp <- params
		mov     ss:[bp].VTSCXP_context, ax 
		clr     ss:[bp].VTSCXP_flags
		mov     ss:[bp].VTSCXP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
		mov	ax, MSG_VIS_TEXT_SET_CONTEXT
		call    SendToOutputStack
		add     sp, dx

		.leave
		ret
ApplyPageNameLow		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoRenamePageDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask user what to do with hyperlinks to page when renaming it

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ax - InteractionCommand
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoRenamePageDialog		proc	near
		uses	di,bp
		.enter

		sub	sp, size StandardDialogResponseTriggerTable + \
			3*StandardDialogResponseTriggerEntry
		mov	di, sp
		mov	ss:[di].SDRTT_numTriggers, 3

		lea	di, ss:[di].SDRTT_triggers
		mov	ss:[di].SDRTE_moniker.handle, \
			handle NewNameTriggerString
		mov	ss:[di].SDRTE_moniker.chunk, \
			offset NewNameTriggerString
		mov	ss:[di].SDRTE_responseValue, IC_YES

		add	di, size StandardDialogResponseTriggerEntry
		mov	ss:[di].SDRTE_moniker.handle, \
			handle OldNameTriggerString
		mov	ss:[di].SDRTE_moniker.chunk, \
			offset OldNameTriggerString
		mov	ss:[di].SDRTE_responseValue, IC_NO

		add	di, size StandardDialogResponseTriggerEntry
		mov	ss:[di].SDRTE_moniker.handle, \
			handle CancelTriggerString
		mov	ss:[di].SDRTE_moniker.chunk, \
			offset CancelTriggerString
		mov	ss:[di].SDRTE_responseValue, IC_DISMISS
		mov	di, sp
		
		sub	sp, size StandardDialogOptrParams
		mov	bp, sp
		mov	ss:[bp].SDOP_customFlags, \
			CustomDialogBoxFlags <0, CDT_QUESTION, GIT_MULTIPLE_RESPONSE, 0>
		mov	ss:[bp].SDOP_customString.handle, \
			handle RenamePageString
		mov	ss:[bp].SDOP_customString.chunk, \
			offset RenamePageString
		clr	ss:[bp].SDOP_stringArg1.handle
		clr	ss:[bp].SDOP_stringArg2.handle
		movdw	ss:[bp].SDOP_customTriggers, ssdi
		clr	ss:[bp].SDOP_helpContext.segment

		call	UserStandardDialogOptr	;ax <- response

		add	sp, size StandardDialogResponseTriggerTable + \
			3 * (size StandardDialogResponseTriggerEntry) 
		
		.leave
		ret
DoRenamePageDialog		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetToolBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the child block and features of the hyperlink controller

CALLED BY:	INTERNAL
PASS:		*ds:si	= GenControlClass object
RETURN:		ax	= features
		bx	= block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetToolBlockAndFeatures	proc	near
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData
		mov	ax, ds:[bx].TGCI_toolboxFeatures
		mov	bx, ds:[bx].TGCI_toolBlock
		ret
GetToolBlockAndFeatures	endp

HyperlinkAndPageNameControlCode ends
