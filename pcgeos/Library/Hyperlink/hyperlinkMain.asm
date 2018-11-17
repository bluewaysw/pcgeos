COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Hyperlink Library
FILE:		hyperlink.asm

AUTHOR:		Jenny Greenwood, Apr 29, 1994

ROUTINES:
	Name			Description
	----			-----------
MSG_GEN_CONTROL_GET_INFO	Get GenControlBuildInfo for controller
MSG_GEN_CONTROL_UPDATE_UI	Update UI for controller

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/20/92		Initial revision

DESCRIPTION:
	Main code for Hyperlink controller.

	$Id: hyperlinkMain.asm,v 1.1 97/04/04 18:09:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HyperlinkAndPageNameControlCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return GenControlBuildInfo for hyperlink controller
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si	= instance data
		ds:di	= *ds:si
		es	= seg addr of HyperlinkControlClass
		ax	= the method

		cx:dx	= GenControlBuildInfo structure

RETURN:		cx:dx	= GenControlBuildInfo structure filled

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlGetInfo	method dynamic HyperlinkControlClass, \
					MSG_GEN_CONTROL_GET_INFO

		segmov	ds, cs
		mov	si, offset HC_dupInfo		;ds:si <- source
		mov	es, cx
		mov	di, dx				;es:di <- dest
		mov	cx, size GenControlBuildInfo
		rep	movsb
		ret
HyperlinkControlGetInfo	endm

HC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	HC_initFileKey,			; GCBI_initFileKey
	HC_gcnList,			; GCBI_gcnList
	length HC_gcnList,		; GCBI_gcnCount
	HC_notifyTypeList,		; GCBI_notificationList
	length HC_notifyTypeList,	; GCBI_notificationCount
	HCName,				; GCBI_controllerName

	handle HyperlinkControlUI,	; GCBI_dupBlock
	HC_childList,			; GCBI_childList
	length HC_childList,		; GCBI_childCount
	HC_featuresList,		; GCBI_featuresList
	length HC_featuresList,		; GCBI_featuresCount
	HYPERLINK_CONTROL_DEFAULT_FEATURES,
					; GCBI_features
	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	HYPERLINK_CONTROL_DEFAULT_TOOLBOX_FEATURES,	
					; GCBI_toolFeatures
	0>				; GCBI_helpContext

HC_initFileKey	char	"Hyperlink", 0

HC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_TYPE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_HYPERLINKABILITY_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_PAGE_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_DOCUMENT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_HYPERLINK_STATUS_CHANGE>

;
; NOTE: If you change HC_notifyTypeList, be sure to update the updateTable
; used by HyperlinkControlUpdateUI.
;
HC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_TYPE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_HYPERLINKABILITY_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_PAGE_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_DOCUMENT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_HYPERLINK_STATUS_CHANGE>

;---

HC_childList	GenControlChildInfo	\
	<offset HyperlinkManageDestBox,	mask HCF_MANAGE_DESTINATIONS,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset HyperlinkSetDestBox, 	mask HCF_SET_DESTINATION,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset HyperlinkClearAllHyperlinksTrigger,
					mask HCF_CLEAR_ALL_HYPERLINKS,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset HyperlinkFollowHyperlinkTrigger,
					mask HCF_FOLLOW_HYPERLINK,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset HyperlinkOptionsList,	mask HCF_HYPERLINK_OPTIONS,
					mask GCCF_IS_DIRECTLY_A_FEATURE>
;
; Careful, this table is in the *opposite* order as the record which
; it corresponds to.
;
HC_featuresList	GenControlFeaturesInfo	\
	<offset HyperlinkManageDestBox, ManageDestinationsName, 0>,
	<offset HyperlinkSetDestBox, SetDestinationName, 0>,
	<offset HyperlinkClearAllHyperlinksTrigger, ClearHyperlinksName, 0>,
	<offset HyperlinkFollowHyperlinkTrigger, FollowHyperlinkName, 0>,
	<offset HyperlinkOptionsList, ShowHyperlinksName, 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for HyperlinkControlClass
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si	= instance data
		ds:di	= *ds:si
		es	= seg addr of HyperlinkControlClass
		ax	= the message

		ss:bp - GenControlUpdateUIParams

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlUpdateUI	method dynamic HyperlinkControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI
	;
	; Call the UI update routine corresponding to the passed
	; notification type
	;
		mov	bx, offset updateTable
		mov	ax, ss:[bp].GCUUIP_changeType
loopTop:
		cmp	cs:[bx].UTE_changeType, ax
		je	doUpdate
		add	bx, size UpdateTableEntry
if ERROR_CHECK
		cmp	bx, (offset updateTable) + (size updateTable)
		ERROR_E	HYPERLINK_CANNOT_HANDLE_NOTIFICATION_TYPE
endif
		jmp	loopTop
doUpdate:
		call	cs:[bx].UTE_routine
		ret
HyperlinkControlUpdateUI	endm

UpdateTableEntry	struct
	UTE_changeType	GeoWorksNotificationType
	UTE_routine	nptr
UpdateTableEntry	ends

;
; NOTE: If you change HC_notifyList, be sure to update this table.
;
updateTable	UpdateTableEntry	\
	<GWNT_TEXT_NAME_CHANGE, UpdateForNameChange>,
	<GWNT_TEXT_TYPE_CHANGE, UpdateForTypeChange>,
	<GWNT_TEXT_HYPERLINKABILITY_CHANGE, UpdateForHyperlinkabilityChange>,
	<GWNT_PAGE_NAME_CHANGE, UpdateForPageNameChange>,
	<GWNT_DOCUMENT_CHANGE, UpdateForDocumentChange>,
	<GWNT_HYPERLINK_STATUS_CHANGE, UpdateForHyperlinkStatusChange>	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateForNameChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI when controller has received GWNT_TEXT_NAME_CHANGE.

CALLED BY:	INTERNAL	HyperlinkControlUpdateUI

PASS:		*ds:si	= instance data
		es	= seg addr of HyperlinkControlClass
		ss:bp	= GenControlUpdateUIParams

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateForNameChange	proc	near
	;
	; Find out what kind of name change got us here.
	;
		call	LockDataBlock	; es:0 <- VisTextNotifyNameChange
		mov	cl, es:[VTNNC_type]
		mov	ch, es:[VTNNC_changeType]
		mov	dx, es:[VTNNC_index]
		mov	di, es:[VTNNC_fileIndex]
		call	MemUnlock
	;
	; Now update stuff.
	;
		call	GetChildBlockAndFeaturesFromGCUUIP
		mov	bp, di			; bp <- file index (if any)
		push	cx			; save the change type
		call	ForceUpdateUI		; ax <- features
		pop	cx
	;
	; If this was not a null notification, update the SetDest lists
	; to reflect the name change.
	;
		call	ForceUpdateSetDestUI
		call	GenerateTypeChangeNotifications
done:
		ret
UpdateForNameChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateForTypeChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI when controller has received GWNT_TEXT_TYPE_CHANGE.

CALLED BY:	INTERNAL	HyperlinkControlUpdateUI

PASS:		*ds:si	= instance data
		ss:bp	= GenControlUpdateUIParams

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateForTypeChange	proc	near
		class	HyperlinkControlClass
	;
	; Get ax = page name index, cx = file name index, di = type diffs
	;
		call	GetTypeChangeData
	;
	; If the selection contains multiple hyperlinks, we pretend it
	; contains none.
	;
		test	di, mask VTTD_MULTIPLE_HYPERLINKS
		mov	di, ss:[bp].GCUUIP_features
		mov	bx, ss:[bp].GCUUIP_childBlock
		jz	singleOrNone
		mov	ax, GIGS_NONE
singleOrNone:
	;
	; Update the Clear Destination trigger - enable for single
	; hyperlink - disable for none.
	;
		push	si
		mov	si, offset SetDestClearHyperlinkTrigger
		call	EnableDisableBasedOnSelection
		pop	si
	;
	; If no hyperlink is selected, disable Follow Hyperlink and leave.
	;
		cmp	ax, GIGS_NONE
		je	doFollowED
	;
	; A single hyperlink is selected. Update our file and page
	; name lists to select the appropriate names.
	;
		call	UpdateListsForTypeChange
	;
	; Update the Set Destination trigger according to the
	; hyperlinkability of the selected hyperlink. (A text
	; hyperlink selected only by having the cursor placed on it is
	; not hyperlinkable.)
	;
		call	UpdateSetHyperlinkTrigger
	;
	; If file is other than current, we masquerade as having no
	; hyperlink selected so as to disable the Follow Hyperlink trigger.
	;
		mov	ax, GIGS_NONE		; assume file is not current
						;  ax <- do disable
		tst	cx
		jnz	doFollowED		; not current so disable
		clr	ax			; ax <- do enable
doFollowED:
	;
	; Make sure we have a Follow Hyperlink trigger before we fall
	; over our feet trying to update it.
	;
		test	di, mask HCF_FOLLOW_HYPERLINK
		jz	done
		mov	si, offset HyperlinkFollowHyperlinkTrigger
		call	EnableDisableBasedOnSelection
done:
		ret
UpdateForTypeChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateForHyperlinkabilityChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI when controller has received
		GWNT_TEXT_HYPERLINKABILITY_CHANGE.

CALLED BY:	INTERNAL	HyperlinkControlUpdateUI

PASS:		*ds:di	= hyperlink controller instance data
		ds:di	= *ds:si
		ss:bp	= GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateForHyperlinkabilityChange	proc	near
		class	HyperlinkControlClass
	;
	; Make sure we have a SetDest box since that contains the only
	; thing we're interested in updating.
	;
		mov	ax, ss:[bp].GCUUIP_features
		test	ax, mask HCF_SET_DESTINATION
		jz	done
	;
	; Find out and record whether we have a hyperlinkable selection.
	;
		call	LockDataBlock	; es:0 <-
					;  VisTextNotifyHyperlinkabilityChange
					; bx <- handle
		mov	cx, es:[VTNHC_hyperlinkable]
		call	MemUnlock
		mov	ds:[di].HCI_hyperlinkable, cx
	;
	; Update the Set Destination trigger. If the selection isn't
	; hyperlinkable, the trigger will be disabled.
	;
		mov	bx, ss:[bp].GCUUIP_childBlock
	CheckHack <BW_FALSE eq 0>
		jcxz	doUpdate
		call	GetSetDestPageListSelection	; ax <- page
doUpdate:
		call	UpdateSetHyperlinkTriggerLow
done:
		ret
UpdateForHyperlinkabilityChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateForPageNameChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI when controller has received GWNT_PAGE_NAME_CHANGE.

CALLED BY:	INTERNAL	HyperlinkControlUpdateUI

PASS:		*ds:si	= instance data
		ss:bp	= GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateForPageNameChange	proc	near
	;
	; We don't care about the user moving to a new page
	;
		call	LockDataBlock	; es:0 <- NotifyDocumentChange
					; bx <- handle
		mov	cl, es:[NPNC_changeType]
		call	MemUnlock
		cmp	cl, PNCT_CHANGE_PAGE
		je	done
	;
	; Update SetDest page list if there's a file selected in
	; the file list.
	;
		mov	cl, VTNT_CONTEXT
		call	GetSetDestListSelections	; dx <- file
							; ax <- page
							; ^lbx:di <-
							;  page list
		cmp	dx, GIGS_NONE
		je	doManageDest
		call	UpdateListLower
doManageDest:
	;
	; Update ManageDest page list if there's a file selected in
	; the file list.
	;
		call	GetManageDestListSelections	; dx <- file
							; ax <- page
							; ^lbx:di <-
							;  page list
		cmp	dx, GIGS_NONE
		je	done
		call	UpdateListLower
done:
		ret
UpdateForPageNameChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateForDocumentChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI when controller has received
		GWNT_DOCUMENT_CHANGE.

CALLED BY:	INTERNAL	HyperlinkControlUpdateUI

PASS:		*ds:si	= instance data
		ss:bp	= GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateForDocumentChange	proc	near
		class	HyperlinkControlClass
if 0
	;
	; If we're closing the document, never mind.
	;
		call	LockDataBlock	; es:0 <- NotifyDocumentChange
					; bx <- handle
		mov	cx, es:[NDC_attrs]
		call	MemUnlock
		test	cx, mask GDA_CLOSING
		je	done
endif
	;
	; When the document changes, we'll get a name change
	; notification with VTNCT_NULL, which will cause us to update
	; all our lists (see ForceUpdateUI). So one might think that
	; we needn't update the lists here.
	;
	; Alas, if the hyperlink controller UI is not onscreen, the
	; name change notification gets stored to be sent when it
	; appears, and if the user then adds a name from the page name
	; controller while the hyperlink controller is still offscreen,
	; a second name change notification replaces the first.
	; In that case, the first never gets delivered, so we cannot rely
	; on it. Here we make sure to update all our lists:
	;
		call	LockDataBlock	; es:0 <- NotifyDocumentChange
					; bx <- handle
		mov	ax, es:[NDC_fileHandle]
		mov	cx, es:[NDC_attrs]
		call	MemUnlock

	; if going to a different document, we definitely want to update

		cmp	ax, ds:[di].HCI_currentDoc
		jne	forceUpdate

	; if this document is closing, we should update

		test	cx, mask GDA_CLOSING
		jz	done
		clr	ax
forceUpdate:
		mov	ds:[di].HCI_currentDoc, ax
	;
	; The call to ForceUpdateUI is going to wipe out the state of the
	; SetDestination DB which was set earlier by a type change 
	; notification sent when the document changed.  What we really need 
	; do here is generate a new type change notification...
	;
		call	GetChildBlockAndFeaturesFromGCUUIP
							;^lbx:di <- page list
		mov	ch, VTNCT_NULL
		call	ForceUpdateUI
		mov	ch, VTNCT_NULL
		mov	cl, VTNT_FILE
		call	ForceUpdateSetDestUI

		call	GenerateTypeChangeNotifications
done:
		ret
UpdateForDocumentChange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateTypeChangeNotifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Causes text object to send a null status type change
		notification, followed by a regular type change notification.

CALLED BY:	UpdateForDocumentChange.
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/12/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateTypeChangeNotifications		proc	near
		.enter
	
		mov	dx, size VisTextGenerateNotifyParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].VTGNP_notificationTypes, mask VTNF_TYPE
		mov	ss:[bp].VTGNP_sendFlags, 
			mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS or \
			mask VTNSF_NULL_STATUS or \
			mask VTNSF_SEND_AFTER_GENERATION
		clr	ss:[bp].VTGNP_notificationBlocks
		mov	ax, MSG_VIS_TEXT_GENERATE_NOTIFY
		call	SendToOutputStack
		
		mov	ss:[bp].VTGNP_sendFlags, 
			mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS or \
			mask VTNSF_SEND_AFTER_GENERATION
		call	SendToOutputStack
		add	sp, dx

		.leave
		ret
GenerateTypeChangeNotifications		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateForHyperlinkStatusChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI when controller has received
		GWNT_HYPERLINK_STATUS_CHANGE

CALLED BY:	INTERNAL	HyperlinkControlUpdateUI

PASS:		*ds:si	= instance data
		ss:bp	= GenControlUpdateUIParams

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Right now the only status change that we care about is the 
	ShowAllHyperlinks status.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateForHyperlinkStatusChange	proc	near
	;
	; Make sure we have an Options List since that contains the only
	; thing we're interested in updating.
	;
		mov	ax, ss:[bp].GCUUIP_features
		test	ax, mask HCF_HYPERLINK_OPTIONS
		jz	done
	;
	; Find out whether the hyperlinks are being shown or not.
	;
		call	LockDataBlock	; es:0 <- NotifyHyperlinkStatusChange
					; bx <- handle
		mov	cx, es:[NHSC_changeType]
		call	MemUnlock
	;
	; Update the Show All Hyperlinks boolean.
	;
		clr	dx			; assume not showing hyperlinks
		cmp	cx, HSCT_SHOW_HYPERLINKS_OFF
		je	showHyperlinksOff
		inc	dx			; woops, we guessed wrong
showHyperlinksOff:
		call	GetChildBlockAndFeatures
		mov	si, offset HyperlinkOptionsList
		mov	cx, mask HCO_SHOW_HYPERLINKS
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
	ret
UpdateForHyperlinkStatusChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for the HyperlinkController

CALLED BY:	HyperlinkControlUpdateUI
PASS:		*ds:si	= controller
		ax	= features mask
		bx	= hptr of child block
		cl	= VisTextNameType
		ch	= VisTextNameChangeType
		dx	= list index of name
		bp	= list index of file name if cl = VTNT_CONTEXT

RETURN:		nothing
DESTROYED:	cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceUpdateUI	proc	near
		class HyperlinkControlClass
		.enter
	;
	; On null name change, which occurs when the text object gains
	; the target exclusive, pretend that we have deleted a file name.
	; That way we'll update all our lists. 
	;
		cmp	ch, VTNCT_NULL
		jne	updateFileUI
		mov	cx, VTNT_FILE or (VTNCT_REMOVE shl 8)
updateFileUI:
	;
	; We don't need to update the file lists unless
	; we've done something with a file name.
	;
		cmp	cl, VTNT_FILE
		jne	updatePageUI
	;
	; If we've deleted a file name, select the current file in our
	; various file lists.
	;
		cmp	ch, VTNCT_REMOVE
		jne	gotIndex
		clr	dx			; dx <- current file index
gotIndex:
		call	UpdateManageFilesFileBoxUI	
		call	UpdateManageDestFileListUI
;;		call	UpdateSetDestFileGroupUI
	;
	; We can ignore the page lists if we got here by renaming a file.
	;
		cmp	ch, VTNCT_RENAME
		je	done
updatePageUI:
		call	UpdateManageDestPageGroupUI
;;		call	UpdateSetDestPageGroupUI
done:
		.leave
		ret
ForceUpdateUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceUpdateSetDestUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for the HyperlinkController

CALLED BY:	UpdateForNameChange
PASS:		*ds:si	= controller
		ax	= features mask
		bx	= hptr of child block
		cl	= VisTextNameType
		ch	= VisTextNameChangeType
		dx	= list index of name
		bp	= list index of file name if cl = VTNT_CONTEXT

RETURN:		nothing
DESTROYED:	cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceUpdateSetDestUI	proc	near
		class HyperlinkControlClass
		.enter
	;
	; We don't need to update the file list unless
	; we've done something with a file name.
	;
		cmp	cl, VTNT_FILE
		jne	updatePageUI
	;
	; If we've deleted a file name, select the current file in our
	; various file lists.
	;
		cmp	ch, VTNCT_REMOVE
		jne	gotIndex
		clr	dx			; dx <- current file index
gotIndex:
		call	UpdateSetDestFileGroupUI
	;
	; We can ignore the page list if we got here by renaming a file.
	;
		cmp	ch, VTNCT_RENAME
		je	done
updatePageUI:
		call	UpdateSetDestPageGroupUI
done:
		.leave
		ret
ForceUpdateSetDestUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSetDestFileGroupUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the file group UI for the SetDest box

CALLED BY:	INTERNAL	ForceUpdateUI

PASS:		*ds:si	= controller
		ax	= features mask
		bx	= hptr of child block
		ch	= VisTextNameChangeType
		cl	= VisTextNameType
		dx	= list index of name

RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSetDestFileGroupUI		proc	near
	;
	; Make sure we have a SetDest box.
	;
		test	ax, mask HCF_SET_DESTINATION
		jz	noSetDest
	;
	; Clear the new file name field.
	;
		mov	di, offset SetDestAddFileText
		call	ClearNameField
	;
	; Update the list of files.
	;
		mov	di, offset SetDestFileList
		call	UpdateFileListLow
noSetDest:
		ret
UpdateSetDestFileGroupUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSetDestPageGroupUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the page group UI for the SetDest box

CALLED BY:	INTERNAL	ForceUpdateUI
PASS:		*ds:si	= controller
		ax	= features mask
		bx	= hptr of child block
		cl	= VisTextNameType
		dx	= list index of name
		bp	= list index of file name if cl = VTNT_CONTEXT

RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSetDestPageGroupUI		proc	near
		class	HyperlinkControlClass
		uses	ax
		.enter
	;
	; Make sure we have a SetDest box.
	;
		test	ax, mask HCF_SET_DESTINATION
		jz	done
	;
	; Clear the Add Page text field.
	;
		mov	di, offset SetDestAddPageText
		call	ClearNameField
	;
	; Update the page list.
	;
		mov	di, offset SetDestPageList
		call	UpdatePageListUI	; ax <- index of selection
	;
	; Update the Set Destination trigger.
	;
		call	UpdateSetHyperlinkTrigger
done:
		.leave
		ret
UpdateSetDestPageGroupUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateManageDestFileListUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the file list UI for the ManageDest box

CALLED BY:	INTERNAL	ForceUpdateUI
PASS:		*ds:si	= controller
		ax	= features mask
		bx	= hptr of child block
		ch	= VisTextNameChangeType
		cl	= VisTextNameType
		dx	= list index of name

RETURN:		none
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateManageDestFileListUI		proc	near
		uses	ax
		.enter
	;
	; Make sure we have a ManageDest box.
	;
		test	ax, mask HCF_MANAGE_DESTINATIONS
		jz	noManageDest
	;
	; Update the list of files
	;
		mov	di, offset ManageDestCurrentFileList
		call	UpdateFileListLow
noManageDest:
		.leave
		ret
UpdateManageDestFileListUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateManageDestPageGroupUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the page list in the ManageDest box

CALLED BY:	INTERNAL	ForceUpdateUI
PASS:		*ds:si	= controller
		ax	= features mask
		bx	= hptr of child block
		cl	= VisTextNameType
		dx	= list index of name
		bp	= list index of file name if cl = VTNT_CONTEXT

RETURN:		none
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateManageDestPageGroupUI		proc	near
		class	HyperlinkControlClass
		uses	ax, dx, bp
		.enter
	;
	; Make sure we have a ManageDest box.
	;
		test	ax, mask HCF_MANAGE_DESTINATIONS
		jz	done
	;
	; Clear out the Add Page and Rename text fields.
	;
		mov	di, offset ManageDestAddPageText
		call	ClearNameField
		call	ClearRenamePageField
	;
	; Update the page list.
	;
		mov	di, offset ManageDestPageList
		call UpdatePageListUI		; ax <- page index
							; dx <- file index
	;
	; Update the Delete and Rename stuff.
	;
		call	UpdatePageDeleteAndRenameUI
done:
		.leave
		ret
UpdateManageDestPageGroupUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateManageFilesFileBoxUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the file list UI for the SetDest box

CALLED BY:	INTERNAL	ForceUpdateUI
PASS:		*ds:si	= controller
		ax	= features mask
		bx	= hptr of child block
		ch	= VisTextNameChangeType
		cl	= VisTextNameType
		dx	= list index of name

RETURN:		none
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateManageFilesFileBoxUI		proc	near
		uses	ax, dx, bp
		.enter
	;
	; If we have no ManageDest box, we have no ManageFiles box either.
	;
		test	ax, mask HCF_MANAGE_DESTINATIONS
		jz	noManageFiles
	;
	; Clear out the Add and Rename text fields.
	;
		mov	di, offset ManageFilesAddFileText
		call	ClearNameField
		mov	di, offset ManageFilesRenameFileText
		call	ClearNameField
	;
	; Update the list of files.
	;
		mov	di, offset ManageFilesFileList
		call	UpdateFileListLow
	;
	; Then update the Delete and Rename triggers.
	;
		mov_tr	ax, dx			; ax <- selection
		call	UpdateFileDeleteAndRenameUI
noManageFiles:
		.leave
		ret
UpdateManageFilesFileBoxUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlFileListGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a moniker for the file list in either the Set Destination
		or the Manage Files box

CALLED BY:	MSG_HYPERLINK_CONTROL_FILE_LIST_GET_MONIKER
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		^lcx:dx	= file list (in either SetDest or ManageFiles box)
		bp	= position of item whose moniker is requested

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlFileListGetMoniker	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_FILE_LIST_GET_MONIKER
	;
	; Get child block and tell GetNameMoniker what it needs to know.
	;
		call	GetChildBlockAndFeatures
		mov	di, dx				; ^lbx:di <- list
		mov	cl, VTNT_FILE			; cl <- VisTextNameType
		mov	dx, -1				; dx <- file token (none)
		mov_tr	ax, bp				; ax <- index
		call	GetNameMoniker
		ret
HyperlinkControlFileListGetMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlSetdestFileChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user changed the file in the Set Destination box

CALLED BY:	MSG_HYPERLINK_CONTROL_SETDEST_FILE_CHANGED
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		cx	= current file list selection

RETURN:		nothing
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlSetdestFileChanged	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_SETDEST_FILE_CHANGED
	;
	; Update the SetDest page list according to the file now selected.
	; Don't update the whole page group as that would clear the
	; Add Page field, which would be irritating if the user had
	; begun typing in a page name and then realized that it should
	; belong to a different file.
	;
		call	GetChildBlockAndFeatures
		mov	dx, cx				; dx <- file selection
		mov	di, offset SetDestPageList	; ^lbx:di <- page list
		mov	ax, GIGS_NONE			; no selection
		mov	cl, VTNT_CONTEXT		; cl <- VisTextNameType
		call	UpdateListLower
	;
	; Now update the Set Destination trigger. Since ax = GIGS_NONE,
	; the trigger will be disabled.
	;
		call	UpdateSetHyperlinkTriggerLow
		ret
HyperlinkControlSetdestFileChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlSetdestAddFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new file name from the Set Destination box

CALLED BY:	MSG_HYPERLINK_CONTROL_SETDEST_ADD_FILE_NAME
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

RETURN:		nothing	
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlSetdestAddFileName	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_SETDEST_ADD_FILE_NAME

		mov	dx, offset SetDestAddFileText
		call	AddFileNameLow
		ret
HyperlinkControlSetdestAddFileName	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlSetdestPageListGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a moniker for the page list in the Set Destination box

CALLED BY:	MSG_HYPERLINK_CONTROL_SETDEST_PAGE_LIST_GET_MONIKER
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		^lcx:dx	= page list in SetDest box
		bp	= position of item whose moniker is requested

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlSetdestPageListGetMoniker	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_SETDEST_PAGE_LIST_GET_MONIKER

		mov	di, offset SetDestFileList
		call	PageListGetMoniker
		ret
HyperlinkControlSetdestPageListGetMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlSetdestPageChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user changed the page in the Set Destination box

CALLED BY:	MSG_HYPERLINK_CONTROL_SETDEST_PAGE_CHANGED
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		cx	= current page list selection

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlSetdestPageChanged	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_SETDEST_PAGE_CHANGED
	;
	; Since the page has changed, we may need to change the
	; enabled/disabled status of the Set Destination trigger.
	;
		call	GetChildBlockAndFeatures	; bx <- child block
		mov_tr	ax, cx				; ax <- page selection
		call	UpdateSetHyperlinkTrigger
		ret
HyperlinkControlSetdestPageChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlSetdestAddPageName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new page name from the Set Destination box

CALLED BY:	MSG_HYPERLINK_CONTROL_SETDEST_ADD_PAGE_NAME
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlSetdestAddPageName	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_SETDEST_ADD_PAGE_NAME
	;
	; Pass relevant file list and page name to common routine.
	;
		mov	dx, offset SetDestFileList
		mov	cx, offset SetDestAddPageText
		call	AddPageNameLow
		ret
HyperlinkControlSetdestAddPageName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlSetHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selected hyperlink

CALLED BY:	MSG_HYPERLINK_CONTROL_SET_HYPERLINK
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlSetHyperlink	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_SET_HYPERLINK
	;
	; Get the currently selected file and page.
	;
		call	GetSetDestListSelections	; dx <- file
							; ax <- page
		mov	cx, dx
	;
	; Set the hyperlink and show it boxed if the Show Hyperlinks
	; boolean is selected.
	;
		mov	di, VIS_TEXT_RANGE_SELECTION
		call	SetHyperlink
		ret
HyperlinkControlSetHyperlink	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlClearHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the selected hyperlink.

CALLED BY:	MSG_HYPERLINK_CONTROL_CLEAR_HYPERLINK
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlClearHyperlink	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_CLEAR_HYPERLINK

		mov	cx, GIGS_NONE		;cx <- nil file 
		mov	ax, cx			;ax <- nil page
		mov	di, VIS_TEXT_RANGE_SELECTION
		call	SetHyperlink
		ret
HyperlinkControlClearHyperlink	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlManagedestPageListGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a moniker for the page list in the Manage Destinations box

CALLED BY:	MSG_HYPERLINK_CONTROL_MANAGEDEST_PAGE_LIST_GET_MONIKER
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		^lcx:dx	= page list in ManageDest box
		bp	= position of item whose moniker is requested

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlManagedestPageListGetMoniker	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_MANAGEDEST_PAGE_LIST_GET_MONIKER

		mov	di, offset ManageDestCurrentFileList
		call	PageListGetMoniker
		.leave
		ret
HyperlinkControlManagedestPageListGetMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlManagedestPageChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user changed the page in the Manage Destinations box

CALLED BY:	MSG_HYPERLINK_CONTROL_MANAGEDEST_PAGE_CHANGED
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		cx	= current selection in ManageDest page list
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlManagedestPageChanged	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_MANAGEDEST_PAGE_CHANGED
	;
	; Update the Delete and Rename stuff.
	;
		call	GetChildBlockAndFeatures
		call	GetManageDestFileListSelection	; dx <- file index
		mov_tr	ax, cx				; ax <- page index
		call	UpdatePageDeleteAndRenameUI
		ret
HyperlinkControlManagedestPageChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlManagedestAddPageName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new page name from the Manage Destinations box

CALLED BY:	MSG_HYPERLINK_CONTROL_MANAGEDEST_ADD_PAGE_NAME
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlManagedestAddPageName	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_MANAGEDEST_ADD_PAGE_NAME
	;
	; Pass relevant file list and page name to common routine.
	;
		mov	dx, offset ManageDestCurrentFileList
		mov	cx, offset ManageDestAddPageText
		call	AddPageNameLow
		ret
HyperlinkControlManagedestAddPageName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlDeletePageName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a page name

CALLED BY:	MSG_HYPERLINK_CONTROL_DELETE_PAGE_NAME
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlDeletePageName	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_DELETE_PAGE_NAME
	;
	; Get the page name to delete and the file to which it belongs.
	; Then delete it.
	;
		call	GetManageDestListSelections	; ax <- page
							; dx <- file
		call	DeletePageNameLow
		ret
HyperlinkControlDeletePageName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlChangePageName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename a page

CALLED BY:	MSG_HYPERLINK_CONTROL_CHANGE_PAGE_NAME
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlChangePageName	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_CHANGE_PAGE_NAME
	;
	; Get the page to rename and the file to which it belongs.
	;
		call	GetManageDestListSelections	; ax <- page
							; dx <- file
	;
	; Rename the page.
	; 
		mov	cl, VTNT_CONTEXT		; cl <- VisTextNameType
		mov	di, offset ManageDestRenamePageText
		GOTO	ChangeNameCommon
HyperlinkControlChangePageName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlManagedestFileChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user changed the file in the Manage Destinations box

CALLED BY:	MSG_HYPERLINK_CONTROL_MANAGEDEST_FILE_CHANGED
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		cx	= current file list selection

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlManagedestFileChanged	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_MANAGEDEST_FILE_CHANGED
	;
	; Update the ManageDest page list according to the file now selected.
	; Don't update the whole page group as that would clear the
	; Add Page field, which would be irritating if the user had begun
	; typing in a page name and then realized that it should
	; belong to a different file.
	;
		call	GetChildBlockAndFeatures
		mov	dx, cx				; dx <- file index
		mov	di, offset ManageDestPageList
		mov	ax, GIGS_NONE			; ax <- no selection
		mov	cl, VTNT_CONTEXT		; cl <- VisTextNameType
		call	UpdateListLower
	;
	; Update the page Delete and Rename stuff.
	;
		call	ClearRenamePageField
		call	UpdatePageDeleteAndRenameUI
		ret
HyperlinkControlManagedestFileChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlManagefilesFileChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user changed the file in the Manage Files box

CALLED BY:	MSG_HYPERLINK_CONTROL_MANAGEFILES_FILE_CHANGED
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		cx	= current file list selection

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlManagefilesFileChanged	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_MANAGEFILES_FILE_CHANGED
	;
	; Update the Delete and Rename triggers.
	;
		call	GetChildBlockAndFeatures
		mov_tr	ax, cx			; ax <- selection
		call	UpdateFileDeleteAndRenameUI
		ret
HyperlinkControlManagefilesFileChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlManagefilesAddFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new file name from the Manage Files box

CALLED BY:	MSG_HYPERLINK_CONTROL_MANAGEFILES_ADD_FILE_NAME
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

RETURN:		nothing	
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlManagefilesAddFileName	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_MANAGEFILES_ADD_FILE_NAME

		mov	dx, offset ManageFilesAddFileText
		call	AddFileNameLow
		ret
HyperlinkControlManagefilesAddFileName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlDeleteFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a file name

CALLED BY:	MSG_HYPERLINK_CONTROL_DELETE_FILE_NAME
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlDeleteFileName	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_DELETE_FILE_NAME
	;
	; Get the file name to delete and delete it.
	;
		call	GetManageFilesFileListSelection
		call	DeleteFileNameLow	; cx <- VisTextNameType
		ret
HyperlinkControlDeleteFileName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlChangeFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename a file

CALLED BY:	MSG_HYPERLINK_CONTROL_CHANGE_FILE_NAME

PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlChangeFileName	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_CHANGE_FILE_NAME
	;
	; Get the file to rename.
	;
		call	GetManageFilesFileListSelection	; ax <- file
	;
	; Rename it.
	;
		mov	cl, VTNT_FILE			; cl <- VisTextNameType
		mov	dx, -1				; dx <- file name list
		mov	di, offset ManageFilesRenameFileText
		GOTO	ChangeNameCommon
HyperlinkControlChangeFileName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlClearAllHyperlinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear all hyperlinks for the document.

CALLED BY:	MSG_HYPERLINK_CONTROL_CLEAR_ALL_HYPERLINKS
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlClearAllHyperlinks	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_CLEAR_ALL_HYPERLINKS
	;
	; Sound the alarm.
	;
		mov	bp, HW_WILL_DELETE_ALL_HYPERLINKS_IN_DOCUMENT
		call	AchtungAchtung
		cmp	ax, IC_NO
		je	done
	;
	; We delete all hyperlinks over the entire range of the text.
	;
		clr	di			; di <- start of whole text
		mov	ax, GIGS_NONE
		mov	cx, GIGS_NONE
		call	SetHyperlink
done:
		ret
HyperlinkControlClearAllHyperlinks	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlFollowHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Follow a hyperlink.

CALLED BY:	MSG_HYPERLINK_CONTROL_FOLLOW_HYPERLINK
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlFollowHyperlink	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_FOLLOW_HYPERLINK

		mov	dx, (size VisTextFollowHyperlinkParams)
		sub	sp, dx
		mov	bp, sp				;ss:bp <- ptr to params
		mov	ss:[bp].VTFHLP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
		mov	ax, MSG_META_TEXT_FOLLOW_HYPERLINK
		call	SendToAppTargetStack
		add	sp, dx
		ret
HyperlinkControlFollowHyperlink	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlOptionsChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update for a change in the controller's option settings.

CALLED BY:	MSG_HYPERLINK_CONTROL_OPTIONS_CHANGED
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		cl	= HyperlinkControlOptions

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlOptionsChanged	method dynamic HyperlinkControlClass, 
				MSG_HYPERLINK_CONTROL_OPTIONS_CHANGED
	; 
	; Currently the only option we have is Show Hyperlinks, so
	; just do that.
	;
		call	ShowHyperlinks
		ret
HyperlinkControlOptionsChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlSetRenamePageText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text in the Rename Page field.

CALLED BY:	MSG_HYPERLINK_CONTROL_SET_RENAME_PAGE_TEXT
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		ss:bp	= ReplaceItemMonikerFrame

RETURN:		nothing
DESTROYED:	cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlSetRenamePageText	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_SET_RENAME_PAGE_TEXT

		mov	di, offset ManageDestRenamePageText
		mov	cl, mask SNFF_SELECT
		call	SetChildBlockNameFieldFromMonikerFrame
		ret
HyperlinkControlSetRenamePageText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlSetRenameFileText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text in the Rename File field.

CALLED BY:	MSG_HYPERLINK_CONTROL_SET_RENAME_FILE_TEXT
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		ss:bp	= ReplaceItemMonikerFrame


RETURN:		nothing
DESTROYED:	cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlSetRenameFileText	method dynamic HyperlinkControlClass, 
					MSG_HYPERLINK_CONTROL_SET_RENAME_FILE_TEXT

		mov	di, offset ManageFilesRenameFileText
		mov	cl, mask SNFF_SELECT
		call	SetChildBlockNameFieldFromMonikerFrame
		ret
HyperlinkControlSetRenameFileText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyperlinkControlTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI when a text field becomes empty/non-empty

CALLED BY:	MSG_META_TEXT_EMPTY_STATUS_CHANGED
PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		ds:bx	= HyperlinkControlClass object (same as *ds:si)
		es 	= segment of HyperlinkControlClass
		ax	= message #

		cx:dx	= text object OD
		bp	= zero if text became empty

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HyperlinkControlTextEmptyStatusChanged	method dynamic HyperlinkControlClass, 
					MSG_META_TEXT_EMPTY_STATUS_CHANGED
	;
	; Make sure we have a SetDest box.
	;
		call	GetChildBlockAndFeatures	; bx <- block
							; ax <- features
		test	ax, mask HCF_SET_DESTINATION
		jz	done
	;
	; Make sure the text object in question is in the SetDest box.
	;
		cmp	bx, cx		
		jne	done
		cmp	dx, offset SetDestAddFileText
		je	getPageSelection
		cmp	dx, offset SetDestAddPageText
		jne	done
getPageSelection:
	;
	; If the text is non-empty, we disable the Set Destination
	; trigger by claiming to have no page selected in the SetDest
	; page list. Otherwise, we get the page selection and update
	; the trigger accordingly.
	;
		mov	ax, GIGS_NONE
		tst	bp				; text empty?
		jnz	doUpdate			; jump if not
		call	GetSetDestPageListSelection	; ax <- page
doUpdate:
		call	UpdateSetHyperlinkTrigger
done:
		ret
HyperlinkControlTextEmptyStatusChanged	endm

HyperlinkAndPageNameControlCode ends
