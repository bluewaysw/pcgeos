COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Hyperlink Library
FILE:		hyperlinkUtils.asm

AUTHOR:		Jenny Greenwood, May 23, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/23/94   	Initial revision


DESCRIPTION:
	Utilities for hyperlink controller.		
	CommonCode contains utilities used by Hyperlink and PageName
	controllers.

	$Id: hyperlinkUtils.asm,v 1.1 97/04/04 18:09:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


HyperlinkAndPageNameControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddFileNameLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to add a new file name

CALLED BY:	INTERNAL	HyperlinkContolSetdestAddFileName
				HyperlinkContolManageFilesAddFileName

PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		dx	= chunk of name

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddFileNameLow	proc	near
		class	HyperlinkControlClass
	;
	; Now add the name.
	;
		mov	di, dx			;di <- chunk of name
		mov	cx, VTNT_FILE or (VTCT_FILE shl 8)
		mov	dx, -1			;dx <- define file
		call	AddNameCommon
		ret
AddFileNameLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteFileNameLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to delete file name

CALLED BY:	INTERNAL	HyperlinkControlDeleteFileName

PASS:		*ds:si	= HyperlinkControlClass object
		ax	= file name index

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteFileNameLow	proc	near
	;
	; Say it's a file we're nuking and warn of woeful consequences.
	;
		mov	cl, VTNT_FILE		;cl <- VisTextNameType
		mov	dx, -1			;dx <- it's a file name
		mov	bp, HW_WILL_DELETE_ALL_HYPERLINKS_TO_FILE
		call	DeleteNameCommon
		ret
DeleteFileNameLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPageNameLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to add page name

CALLED BY:	INTERNAL	HyperlinkControlSetdestAddPageName
				HyperlinkControlManagedestAddPageName

PASS:		*ds:si	= HyperlinkControlClass object
		ds:di	= HyperlinkControlClass instance data
		dx	= chunk of file list in SetDest or ManageDest box
		cx	= chunk of name

RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddPageNameLow	proc	near
		class HyperlinkControlClass
	;
	; First get currently selected file from file list.
	;
		mov	di, dx			;di <- chunk of file list
		call	GetListSelection
		mov	dx, ax			;dx <- current file token
	;
	; Now add the name.
	;
		mov	di, cx			;di <- chunk of name
		mov	cx, VTNT_CONTEXT or (VTCT_TEXT shl 8)
		call	AddNameCommon
		ret

AddPageNameLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeletePageNameLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to delete page name

CALLED BY:	INTERNAL	HyperlinkControlDeletePageName

PASS:		*ds:si	= HyperlinkControlClass object
		ax	= page name index
		dx	= file name index

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeletePageNameLow	proc	near
	;
	; Say it's a page we're nuking and warn of woeful consequences.
	;
		mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
		mov	bp, HW_WILL_DELETE_ALL_HYPERLINKS_TO_PAGE
		call	DeleteNameCommon
		ret
DeletePageNameLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNameCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to define a new name

CALLED BY:	INTERNAL	AddFileNameLow
				AddPageNameLow

PASS:		*ds:si	= HyperlinkControlClass object
		di	= chunk of name field
		ax	= page name index
		dx	= file name index (-1 if file)
		cl	= VisTextNameType
		ch	= VisTextContextType

RETURN:		nothing
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddNameCommon	proc	near

		call	GetChildBlockAndFeatures
if ERROR_CHECK
		push	cx, dx, si, di
		mov	si, di
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		mov	di, mask MF_CALL
		call	ObjMessage
		tstdw	dxax
		ERROR_Z HYPERLINK_EMPTY_STRING_PASSED_TO_ADD_NAME_COMMON
		pop	cx, dx, si, di
endif
	;
	; Add the name.
	;
		sub	sp, (size VisTextNameCommonParams)
		mov	bp, sp				;ss:bp <- ptr to params
		movdw	ss:[bp].VTNCP_object, bxdi
		mov	ss:[bp].VTNCP_data.VTND_type, cl
		mov	ss:[bp].VTNCP_data.VTND_contextType, ch
		mov	ss:[bp].VTNCP_data.VTND_file, dx
		mov	ax, MSG_VIS_TEXT_DEFINE_NAME
		mov	dx, (size VisTextNameCommonParams)
		call	SendToOutputStack
		add	sp, dx
		ret
AddNameCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteNameCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to delete a name (context or file)

CALLED BY:	INTERNAL	HyperlinkControlDeletePageName
				HyperlinkControlDeleteFileName

PASS:		*ds:si	= controller
		cl	= VisTextNameType
		ax	= name index
		dx	= file name index (-1 if file)
		bp	= HyperlinkWarning
		
RETURN:		none
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteNameCommon		proc	near
		.enter
	;
	; Warn the user that all hyperlinks to this page or file will
	; be deleted so s/he can chicken out if desired.
	;
		push	ax			; save list index
		call	AchtungAchtung
		cmp	ax, IC_NO
		pop	ax			; restore list index
		je	farewellMyLovely
	;
	; Delete the name
	;
		sub	sp, (size VisTextNameCommonParams)
		mov	bp, sp			;ss:bp <- ptr to params
		mov	ss:[bp].VTNCP_data.VTND_type, cl
		mov	ss:[bp].VTNCP_data.VTND_file, dx
		mov	ss:[bp].VTNCP_index, ax
		mov	ax, MSG_VIS_TEXT_DELETE_NAME
		mov	dx, (size VisTextNameCommonParams)
		call	SendToOutputStack
		add	sp, dx
farewellMyLovely:
		.leave
		ret
DeleteNameCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AchtungAchtung
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up a warning dialog

CALLED BY:	INTERNAL	DeleteNameCommon

PASS:		bp	= HyperlinkWarning

RETURN:		ax	= InteractionCommand

DESTROYED:	es
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AchtungAchtung	proc	near
		uses	cx, dx, di
		.enter
	;
	; Lock down warning string and grab flags for UserStandardDialog
	;
		call	LockHyperlinkWarning		; es:di <- string
							; ax <- flags
	;
	; Put up the warning.
	;
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags, ax
		movdw	ss:[bp].SDP_customString, esdi
		clr	ss:[bp].SDP_helpContext.segment
		call	UserStandardDialog		; ax <-
							;  InteractionCommand
	;
	; Unlock the Strings resource, locked by LockHyperlinkWarning.
	;
		call	MemUnlock
		.leave
		ret
AchtungAchtung	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockHyperlinkWarning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down a warning string and get associated flags

CALLED BY:	INTERNAL	AchtungAchtung

PASS:		bp	= HyperlinkWarning

RETURN:		bx	= handle of Strings resource
		es:di	= string
		ax	= flags for UserStandardDialog
		
DESTROYED:	nothing
SIDE EFFECTS:
	Leaves Strings resource locked. Caller must unlock it after
	using string.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockHyperlinkWarning	proc	near

if ERROR_CHECK
		cmp	bp, HyperlinkWarning		; ensure valid error
		ERROR_AE HYPERLINK_ILLEGAL_WARNING_PASSED
		test	bp, 0x3				; we count by 4
		ERROR_NZ HYPERLINK_ILLEGAL_WARNING_PASSED
endif
	;
	; Lock down the resource.
	;
		mov	bx, handle Strings
		call	MemLock
		mov	es, ax
		assume	es:Strings
	;
	; Grab the data from our table. Note that bp, the passed
	; HyperlinkWarning, is an offset into this table. The table is
	; organized in pairs of values:
	;	* ptr to string
	;	* flags for UserStandardDialog
	;
		mov	di, es:[HyperlinkWarningTable]
		mov	ax, es:[di][bp+2]		; ax <- flags
		mov	di, es:[di][bp]
		mov	di, es:[di]			; es:di <- string
		ret
LockHyperlinkWarning	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeNameCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to change a page or file name

CALLED BY:	INTERNAL	HyperlinkControlChangePageName
				HyperlinkControlChangeFileName

PASS:		cl - VisTextNameType
		dx - file token
		ax - list entry #
		^lbx:di - chunk of text object
		*ds:si - controller

RETURN:		none
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeNameCommon		proc	far
		.enter
	;
	; Change the name
	;
		sub	sp, (size VisTextNameCommonParams)
		mov	bp, sp				;ss:bp <- ptr to params
		movdw	ss:[bp].VTNCP_object, bxdi
		mov	ss:[bp].VTNCP_data.VTND_type, cl
		mov	ss:[bp].VTNCP_data.VTND_file, dx
		mov	ss:[bp].VTNCP_index, ax
		mov	ax, MSG_VIS_TEXT_RENAME_NAME
		mov	dx, (size VisTextNameCommonParams)
		call	SendToOutputStack
		add	sp, dx

		.leave
		ret
ChangeNameCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTypeChangeData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the type data from the data block passed with
		GWNT_TEXT_TYPE_CHANGE

CALLED BY:	INTERNAL	UpdateForTypeChange

PASS:		ss:bp	= GenControlUpdateUIParams

RETURN:		ax	= page name of hyperlink destination
		cx	= file name of hyperlink destination
		di	= VisTextTypeDiffs (indicates whether multiple
			  hyperlinks selected)

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTypeChangeData	proc	near
		uses	ds
		.enter

		call	LockDataBlock		; es:0 <-
						;  VisTextNotifyTypeChange
						; bx <- handle
		mov	ax, es:[VTNTC_index].VTT_hyperlinkName
		mov	cx, es:[VTNTC_index].VTT_hyperlinkFile
		mov	di, es:[VTNTC_typeDiffs]
		call	MemUnlock
		.leave
		ret
GetTypeChangeData	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks data block passed in GenControlUpdateUIParams

CALLED BY:	INTERNAL	UpdateForNameChange
				UpdateForSelectionChange
				GetTypeChangeData
				PNCUpdateUI

PASS:		ss:bp	= GenControlUpdateUIParams

RETURN:		es	= segment of locked block
		bx	= block handle		

DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockDataBlock	proc	near
EC <		clr	ax						>
		mov	bx, ss:[bp].GCUUIP_dataBlock
		tst	bx
		jz	done
		call	MemLock
done:
		mov	es, ax
		ret
LockDataBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks data block passed in GenControlUpdateUIParams

CALLED BY:	INTERNAL
PASS:		ss:bp - GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockDataBlock		proc	near
		mov	bx, ss:[bp].GCUUIP_dataBlock
		tst	bx
		jz	exit
		call	MemUnlock
exit:
		ret
UnlockDataBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSetHyperlinkTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update Set Destination trigger when page selection has changed

CALLED BY:	INTERNAL	HyperlinkControlSetdestPageChanged
				UpdateSetDestPageGroupUI

PASS:		*ds:si	= controller instance data
		ax	= page selection
		bx	= controller's child block

RETURN:		nothing
DESTROYED:	ax, bx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSetHyperlinkTrigger	proc	near
		class	HyperlinkControlClass
		uses	cx, di
		.enter
	;
	; Get the hyperlinkability of the current text selection
	; before updating the trigger.
	;
		mov	di, ds:[si]
		add	di, ds:[di].HyperlinkControl_offset
		mov	cx, ds:[di].HCI_hyperlinkable
		call	UpdateSetHyperlinkTriggerLow
		.leave
		ret
UpdateSetHyperlinkTrigger	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSetHyperlinkTriggerLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable the Set Destination trigger

CALLED BY:	INTERNAL  	UpdateSetHyperlinkTrigger
			  	UpdateForHyperlinkabilityChange
			  	HyperlinkControlSetdestFileChanged

PASS:		*ds:si	= instance data
		bx	= controller's child block
		ax	= page selection in SetDest box
		cx	= hyperlinkability of text selection

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSetHyperlinkTriggerLow	proc	near
		uses	si
		.enter
	;
	; If there's no page selection or if the text selection isn't
	; hyperlinkable, disable the trigger.
	;
		cmp	ax, GIGS_NONE
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		je	doUpdate
		cmp	cx, BW_FALSE
		je	doUpdate
	;
	; If any text is entered in one of the SetDest box name
	; fields, disable the trigger.
	;
		mov	di, offset SetDestAddFileText
		call	GetNameFieldSize
		jnz	doUpdate
		mov	di, offset SetDestAddPageText
		call	GetNameFieldSize
		jnz	doUpdate
	;
	; We have a page selection, a hyperlinkable text selection,
	; and empty name fields, so we feel rather chipper.
	;
		mov	ax, MSG_GEN_SET_ENABLED
doUpdate:
	;
	; Enable/disable trigger.
	;
		mov	si, offset SetDestSetHyperlinkTrigger	; ^lbx:si <-
								;  trigger
		call	UpdateNow
		.leave
		ret

UpdateSetHyperlinkTriggerLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNameFieldSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the length of text in a name field.

CALLED BY:	INTERNAL	UpdateSetHyperlinkTrigger

PASS:		^lbx:di	= text field
RETURN:		zero flag set if text field empty
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNameFieldSize	proc	near
		uses	ax
		.enter
	;
	; The text size arrives in dx.ax but we care only about ax
	; because the maximum size of our text fields is small, so dx
	; will always be zero.
	;
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjMessageCall
		tst	ax
		.leave
		ret
GetNameFieldSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePageListUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for a page list

CALLED BY:	INTERNAL	UpdateSetDestPageGroupUI
				UpdateManageDestPageGroupUI

PASS:		*ds:si	= controller
		cl	= VisTextNameType
		dx	= list index of name
		di	= chunk of page list
		bp	= list index of file name if cl = VTNT_CONTEXT

RETURN:		ax	= list index of name
		dx	= list index of file name if cl = VTNT_CONTEXT
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdatePageListUI	proc	near
		uses	cx
		.enter
	;
	; If we're here because of adding or deleting a file name 
	; we won't select a page name. (Renaming a file can't get
	; us here.) Note that in this case, passed dx = file index.
	;
		mov	ax, GIGS_NONE
		cmp	cl, VTNT_FILE
		je	doUpdate
		mov	ax, dx			; ax <- selection
		mov	dx, bp			; dx <- file index
doUpdate:
		mov	cl, VTNT_CONTEXT
		call	UpdateListLower
		.leave
		ret
UpdatePageListUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePageDeleteAndRenameUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the ManageDest Page Delete and Rename UI

CALLED BY:	INTERNAL	HyperlinkControlManagefilesFileChanged
				HyperlinkControlManagedestPageChanged
				UpdateManageDestPageGroupUI

PASS:		*ds:si	= controller
		bx	= handle of controller's child block
		ax	= page index
		dx	= file index

RETURN:		nothing
DESTROYED:	bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePageDeleteAndRenameUI	proc	near
		uses	ax, cx
		.enter
	;
	; Only if something is selected do we set the Rename Page text.
	;
		cmp	ax, GIGS_NONE			; selection?
		je	doTriggers
		push	bx			; save child block			
		call	GetControllerOD		; ^lbx:di <- controller
		mov_tr	bp, ax			; bp <- selection
		mov	ax, MSG_HYPERLINK_CONTROL_SET_RENAME_PAGE_TEXT
		mov	cl, VTNT_CONTEXT
		clr	ch			; we want text moniker
		call	GetNameMonikerFrame
		mov_tr	ax, bp			; ax <- selection
		pop	bx			; bx <- child block
doTriggers:
		call	GetEDMessageBasedOnSelection	; ax <- message
		call	EnableDisablePageTriggers

		.leave
		ret
UpdatePageDeleteAndRenameUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableDisablePageTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/disable the Delete and Rename page triggers

CALLED BY:	INTERNAL	UpdatePageDeleteAndRenameUI
PASS:		ax	= enable/disable message
	
RETURN:		nothing
DESTROYED:	dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableDisablePageTriggers	proc	near
		uses	si
		.enter

		mov	si, offset ManageDestDeletePageTrigger
		call	UpdateNow
		mov	si, offset ManageDestRenamePageBox
		call	UpdateNow
		.leave
		ret
EnableDisablePageTriggers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFileDeleteAndRenameUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the ManageDest Page triggers according to the selection.

CALLED BY:	INTERNAL	HyperlinkControlManagefilesFileChanged
				HyperlinkControlManagedestPageChanged

PASS:		*ds:si	= controller
		ax	= selection

RETURN:		nothing
DESTROYED:	cx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateFileDeleteAndRenameUI	proc	near
		uses	ax
		.enter
	;
	; Only if something is selected do we set the Rename File text.
	;
		cmp	ax, GIGS_NONE			; selection?
		je	doTriggers
		push	bx			; save child block
		call	GetControllerOD		; ^lbx:di <- controller
		mov_tr	bp, ax			; bp <- selection
		mov	ax, MSG_HYPERLINK_CONTROL_SET_RENAME_FILE_TEXT
		mov	dx, -1			; this is a file name
		mov	cl, VTNT_FILE
		clr	ch			; we want text moniker
		call	GetNameMonikerFrame
		mov_tr	ax, bp			; ax <- selection
		pop	bx			; bx <- child block
	;
	; Decrement selection to make it GIGS_NONE if "current file" is
	; selected. Then use it to update the triggers.
	;
CheckHack <GIGS_NONE eq -1>
		dec	ax
doTriggers:
		call	GetEDMessageBasedOnSelection	; ax <- message
		call	EnableDisableFileTriggers
		.leave
		ret
UpdateFileDeleteAndRenameUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableDisableFileTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/disable Delete and Rename file triggers.

CALLED BY:	INTERNAL	UpdateFileDeleteAndRenameUI
PASS:		ax	= enable/disable message
RETURN:		nothing
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableDisableFileTriggers	proc	near
		uses	si
		.enter

		mov	si, offset ManageFilesDeleteFileTrigger
		call	UpdateNow
		mov	si, offset ManageFilesRenameFileBox
		call	UpdateNow
		.leave
		ret
EnableDisableFileTriggers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableDisableBasedOnSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/disable an object according to the selection.

CALLED BY:	INTERNAL	UpdateForTypeChange

PASS:		^lbx:si	= object to enable or disable
		ax	= selection

RETURN:		nothing
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableDisableBasedOnSelection	proc	near
		uses	ax
		.enter
	;
	; Disable object if selection is negative (i.e. GIGS_NONE). Else
	; enable it.
	;
		call	GetEDMessageBasedOnSelection
		call	UpdateNow
		.leave
		ret
EnableDisableBasedOnSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEDMessageBasedOnSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get enable or disable message according to passed selection.

CALLED BY:	INTERNAL	UpdatePageDeleteAndRenameUI
				UpdateFileDeleteAndRenameUI
				EnableDisableBasedOnSelection

PASS:		ax	= selection
RETURN:		ax	= MSG_GEN_SET_(_NOT_)ENABLED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetEDMessageBasedOnSelection	proc	near
	;
	; If we have a selection, we want to enable the object.
	; Otherwise not.
	;
		cmp	ax, GIGS_NONE
		mov	ax, MSG_GEN_SET_ENABLED
		jne	done
		mov	ax, MSG_GEN_SET_NOT_ENABLED
done:
		ret
GetEDMessageBasedOnSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the passed message to a UI object with VUM_NOW.

CALLED BY:	INTERNAL	
PASS:		^lbx:si	= object
		ax	= message
		cx, bp	= optional data
RETURN:		nothing
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateNow	proc	near

		mov	dl, VUM_NOW
		call	ObjMessageSend
		ret
UpdateNow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateListsForTypeChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show and select the passed names in all our lists.

CALLED BY:	INTERNAL	UpdateForTypeChange

PASS:		*ds:si	= instance data
		bx	= child block of controller
		ax	= index of page name
		cx	= index of file name
		di	= HyperlinkControlFlags

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Called when a hyperlink has been selected/deselected.

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateListsForTypeChange	proc	near
		uses	bp, di
		.enter
	;
	; First do the lists in the SetDest box, if we have one...
	;
		test	di, mask HCF_SET_DESTINATION
		jz	doManageDest
		push	di
		mov	di, offset SetDestFileList
		mov	bp, offset SetDestPageList
		call	UpdateListsForTypeChangeLow
		pop	di
doManageDest:
	;
	; Then those in the ManageDest box, if we have one...
	;
		test	di, mask HCF_MANAGE_DESTINATIONS
		jz	done
		mov	di, offset ManageDestCurrentFileList
		mov	bp, offset ManageDestPageList
		call	UpdateListsForTypeChangeLow
	;
	; Update the Delete and Rename stuff.
	;
		call	UpdatePageDeleteAndRenameUI
	;
	; We've got a ManageDest box, so we know we have a ManageFiles
	; box. Turn our loving attentions to its file list.
	;
		mov	di, offset ManageFilesFileList
		call	SetListSelectionNoIndeterminates
done:
		.leave
		ret
UpdateListsForTypeChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateListsForTypeChangeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In a file list and associated page list, show and select
		the passed names.

CALLED BY:	INTERNAL	UpdateListsForTypeChangeLow

PASS:		*ds:si	= instance data
		^lbx:di	= SetDest or ManageDest file list
		bp	= offset to SetDest or ManageDest page list
		ax	= index of page name
		cx	= index of file name

RETURN:		dx	= index of file name
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateListsForTypeChangeLow	proc	near
		uses	cx
		.enter
	;
	; Set the selection in the file list and then update the page list.
	;
		call	SetListSelectionNoIndeterminates
		mov	dx, cx			; dx <- file list index
		mov	di, bp			; di <- page list offset
		mov	cl, VTNT_CONTEXT
		call	UpdateListLower		
		.leave
		ret
UpdateListsForTypeChangeLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFileListLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to update a file list

CALLED BY:	INTERNAL	UpdateSetDestFileGroupUI
				UpdateManageDestFileListUI
				UpdateManageFilesFileBoxUI

PASS:		*ds:si	= HyperlinkControlClass object
		di	= chunk of file list
		ch	= VisTextNameChangeType
		cl	= VisTextNameType
		dx	= list index of name

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateFileListLow	proc	near
		uses	ax, dx
		.enter
	;
	; Do the update and selection-setting.
	;
		mov	ax, dx			; ax <- selection
		mov	dx, -1			; dx <- file name list
		call	UpdateListLower

		.leave
		ret
UpdateFileListLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateListLower
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine for updating page or file list UI

CALLED BY:	INTERNAL	UpdateFileListLow
				UpdatePageListUI
				HyperlinkControlSetdestFileChanged
				HyperlinkControlManagedestFileChanged

PASS:		*ds:si	= controller
		bx	= hptr of child block
		di	= chunk of list
		dx	= file index
		cl	= VisTextNameType
		ax	= selection to set after update

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateListLower	proc	near
		uses	cx, dx
		.enter
	;
	; Update the list.
	;
		call	UpdateListLowest
	;
	; Set the selection.
	;
		cmp	ax, GIGS_NONE
		je	done
		mov	cx, ax			;cx <- selection
		call	SetListSelectionNoIndeterminates
done:
		.leave
		ret
UpdateListLower	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateListLowest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Final list update routine.

CALLED BY:	INTERNAL	UpdateListLower

PASS:		*ds:si	= controller
		^lbx:di	= OD of list
		cl	= VisTextNameType
		dx	= file token (-1 if file name)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateListLowest	proc	near
		uses	ax, dx, bp
		.enter

		sub	sp, (size VisTextNameCommonParams)
		mov	bp, sp			;ss:bp <- ptr to params
		mov	ss:[bp].VTNCP_object.handle, bx
		mov	ss:[bp].VTNCP_object.chunk, di
		mov	ss:[bp].VTNCP_data.VTND_type, cl
		mov	ss:[bp].VTNCP_data.VTND_file, dx
		mov	dx, (size VisTextNameCommonParams)
		mov	ax, MSG_VIS_TEXT_UPDATE_NAME_LIST
		call	SendToOutputStack
		add	sp, (size VisTextNameCommonParams)

		.leave
		ret
UpdateListLowest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to set a hyperlink

CALLED BY:	INTERNAL	HyperlinkControlSetHyperlink
				HyperlinkControlClearHyperlink

PASS:		*ds:si	= HyperlinkControlClass object
		ax	= list index of page name for hyperlink
		cx	= list index of file for hyperlink
		di	= VTR_start.high of range to use:
				VIS_TEXT_RANGE_SELECTION to set hyperlink on
					selected range
				0 to set hyperlink on whole document
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetHyperlink	proc	near
	;
	; Set up flags to show whether we are currently showing hyperlinks.
	;
		call	GetShowHyperlinksFlagToPass	; bl <- flag
	;
	; Set a hyperlink.
	;
		mov	dx, (size VisTextSetHyperlinkParams)
		sub	sp, dx
		mov	bp, sp				; ss:bp <- params
		mov	ss:[bp].VTSHLP_range.VTR_start.high, di
		cmp	di, VIS_TEXT_RANGE_SELECTION
		je	gotRange
if ERROR_CHECK
		tst	di
		ERROR_NZ HYPERLINK_BAD_RANGE_START_PASSED_TO_SET_HYPERLINK
endif
		mov	ss:[bp].VTSHLP_range.VTR_start.low, di
		movdw	ss:[bp].VTSHLP_range.VTR_end, TEXT_ADDRESS_PAST_END
gotRange:
		mov	ss:[bp].VTSHLP_file, cx
		mov	ss:[bp].VTSHLP_context, ax
		mov	ss:[bp].VTSHLP_flags, bl
		mov	ax, MSG_META_TEXT_SET_HYPERLINK
		call	SendToAppTargetStack
		add	sp, dx
		ret
SetHyperlink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToAppTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message with data in registers to the application target

CALLED BY:	INTERNAL	(not presently called; provided in case of need)

PASS:		*ds:si	= HyperlinkControlClass object
		ax	= message
		cx	= data word 1
		dx	= data word 2
		bp	= data word 3
RETURN:		nothing
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToAppTarget	proc	near
ForceRef SendToAppTarget

		clr	di			;no MF_STACK flag
		GOTO	SendToAppTargetLow
SendToAppTarget	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToAppTargetStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message with data on the stack to the application target

CALLED BY:	INTERNAL	SetHyperlink
				something else

PASS:		*ds:si	= HyperlinkControlClass object
		ax	= message
		ss:bp	= data on stack
RETURN:		
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToAppTargetStack	proc	near
		mov	di, mask MF_STACK
		FALL_THRU SendToAppTargetLow
SendToAppTargetStack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToAppTargetLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record a MSG_META... event and send it to the app target

CALLED BY:	INTERNAL	SendToAppTarget
				SendToAppTargetStack

PASS:		*ds:si	= HyperlinkControlClass object
		ax	= MSG_META...
		di	= flags for ObjMessage (MF_STACK or 0)
		if di = MF_STACK
			ss:bp	= data on stack
		else
			cx, dx, bp = data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToAppTargetLow	proc	near
		uses dx
		.enter

		push	si
		clrdw	bxsi		; any class can handle a MetaMessage
		call	RecordEvent
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_APP_TARGET
		pop	si		; *ds:si <- HyperlinkControl
		call	ObjCallInstanceNoLock
		.leave
		ret
SendToAppTargetLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowHyperlinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to show or stop showing hyperlinks

CALLED BY:	INTERNAL	HyperlinkControlShowAllHyperlinks

PASS:		*ds:si	= HyperlinkControlClass object
		cl	= HyperlinkControlOptions
RETURN:		nothing
DESTROYED:	ax, dx, bp
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	StudioArticleSetHyperlinkTextStyle in Bindery intercepts 
	MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE and does some checking
	that depends on the VTSTSP_range being set from 0 to
	TEXT_ADDRESS_PAST_END by this procedure. So, if you modify this 
	procedure you should take a look at StudioArticleSetHyperlinkTextStyle.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowHyperlinks	proc	near
	;
	; We want to set the hyperlinks in the whole document to be
	; either boxed and unboxed. Start setting up the stack.
	;
		mov	dx, (size VisTextSetTextStyleParams)
		sub	sp, dx
		mov	bp, sp			;ss:bp <- params
		clr	ax
		mov	ss:[bp].VTSTSP_range.VTR_start.high, ax
		mov	ss:[bp].VTSTSP_range.VTR_start.low, ax
		movdw	ss:[bp].VTSTSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	;
	; Leave the TextStyle alone, whatever it may be. We're
	; interested in the extended style only.
	;
		mov	ss:[bp].VTSTSP_styleBitsToSet, ax
		mov	ss:[bp].VTSTSP_styleBitsToClear, ax
	;
	; Assume we're going to show the hyperlinks; then check if
	; that's true.
	;
		mov	ss:[bp].VTSTSP_extendedBitsToSet, mask VTES_BOXED 
		mov	ss:[bp].VTSTSP_extendedBitsToClear, ax
		test	cl, mask HCO_SHOW_HYPERLINKS
		jnz	showHyperlinks
		mov	ss:[bp].VTSTSP_extendedBitsToSet, ax
		mov	ss:[bp].VTSTSP_extendedBitsToClear, mask VTES_BOXED
showHyperlinks:
	;
	; Now we set the style.
	;
		mov	ax, MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE
		call	SendToOutputStack
		add	sp, dx
		ret
ShowHyperlinks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetShowHyperlinksFlagToPass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get flag to pass with MSG_VIS_TEXT_SET_HYPERLINK.

CALLED BY:	INTERNAL	SetHyperlink

PASS:		*ds:si	= HyperlinkControlClass object
RETURN:		bl	= VTCF_SHOWING_HYPERLINKS
			or 0
DESTROYED:	bx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetShowHyperlinksFlagToPass	proc	near
		uses	ax
		.enter

		call	GetHyperlinkOptions	; ax <- options
		clr	bl
		test	al, mask HCO_SHOW_HYPERLINKS
		jz	done
		mov	bl, mask VTCF_SHOWING_HYPERLINKS
done:
		.leave
		ret
GetShowHyperlinksFlagToPass	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHyperlinkOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current settings for the HyperlinkControlOptions.

CALLED BY:	INTERNAL	GetShowHyperlinksFlagToPass
				HyperlinkControlGetHyperlinkOptions

PASS:		*ds:si	= HyperlinkControlClass object
RETURN:		al	= HyperlinkControlOptions
DESTROYED:	bx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHyperlinkOptions	proc	near
		uses	cx, di, si, bp
		.enter
	;
	; Send off to get our HyperlinkControlOptions.
	;
		call	GetChildBlockAndFeatures
		mov	si, offset HyperlinkOptionsList
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
GetHyperlinkOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageListGetMonikerLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a moniker for a page list

CALLED BY:	INTERNAL	HyperlinkControlSetdestPageListGetMoniker
				HyperlinkControlManagedestPageListGetMoniker

PASS:		*ds:si	= HyperlinkControlClass object
		dx	= chunk of page list
		di	= chunk of file list
		bp	= position of item whose moniker is requested

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PageListGetMoniker	proc	near
	;
	; First get currently selected file from passed file list.
	;
		call	GetListSelection	; ax <- current file
						; bx <- child block handle

		mov	di, dx			;^lbx:di <- page list
						; wanting moniker
		mov	dx, ax			;dx <- current file
	;
	; Now get moniker.
	;
		mov	ch, mask VTNCF_COLOR_MONIKERS_FOR_UNSET_CONTEXTS
		FALL_THRU	PageListGetMonikerLow
PageListGetMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageListGetMonikerLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a moniker for a page list

CALLED BY:	INTERNAL	PageListGetMoniker
				PNCPageListGetMoniker

PASS:		*ds:si	= HyperlinkControlClass object
		ch	= VisTextNameCommonFlags
		dx	= selected file
		^lbx:di	= page list wanting moniker
		bp	= position of item whose moniker is requested

RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PageListGetMonikerLow	proc	near
	;
	; We want the passed page list updated. Page names not yet
	; associated with pages should be shown in green.
	;
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
		mov	cl, VTNT_CONTEXT	;cl <- VisTextNameType
		call	GetNameMonikerFrame
		ret
PageListGetMonikerLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearRenamePageField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the Rename Page text field

CALLED BY:	INTERNAL	UpdateManageDestPageGroupUI
				HyperlinkControlManagedestFileChanged

PASS:		bx	= controller's child block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearRenamePageField	proc	near
		mov	di, offset ManageDestRenamePageText
		call	ClearNameField
		ret
ClearRenamePageField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearNameField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear a name field
CALLED BY:	UTILITY

PASS:		bx	= handle of controller UI
		di	= chunk of edit field
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearNameField	proc	near
		uses	ax, cx, si, di, bp
		.enter

		mov	si, di
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		clr	di
		call	ObjMessage

		.leave
		ret
ClearNameField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetChildBlockNameFieldFromMonikerFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text in a name field in the child blockusing a
		moniker passed in a ReplaceItemMonikerFrame.

CALLED BY:	INTERNAL	HyperlinkControlSetRenameFileText
				HyperlinkControlSetRenamePageText
				PNCSetPageNameText

PASS:		*ds:si	= controller (Hyperlink or PageName)
		ss:bp	= ReplaceItemMonikerFrame
		di	= offset of text field to set
		cl	= SetNameFieldFlags

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetChildBlockNameFieldFromMonikerFrame	proc	near

		call	GetChildBlockAndFeatures
		FALL_THRU SetNameFieldFromMonikerFrame

SetChildBlockNameFieldFromMonikerFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNameFieldFromMonikerFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text in a name field using a moniker passed in
		a ReplaceItemMonikerFrame.

CALLED BY:	INTERNAL	SetChildBlockNameFieldFromMonikerFrame
				PNCSetPageStatusBarText

PASS:		*ds:si	= controller (Hyperlink or PageName)
		ss:bp	= ReplaceItemMonikerFrame
		^lbx:di	= offset of text field to set
		cl	= SetNameFieldFlags

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNameFieldFromMonikerFrame	proc	near

if ERROR_CHECK
		call	CheckMonikerType
endif
		movdw	dxbp, ss:[bp].RIMF_source
		FALL_THRU	SetNameField

SetNameFieldFromMonikerFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNameField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text in a name text entry field.

CALLED BY:	INTERNAL	SetNameFieldFromMonikerFrame

PASS:		*ds:si	= controller (Hyperlink or PageName)
		dx:bp	= null-terminated page name
		^lbx:di	= text field to set
		cl	= SetNameFieldFlags

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 6/94    	Initial version (broke out of PNCSetPageName)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNameField	proc	near
	;
	; Set the text in the passed text field.
	;
		push	cx
		clr	cx			; null-terminated text
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjMessageCall
		pop	cx
	;
	; Select the text if necessary.
	;
		test	cl, mask SNFF_SELECT
		jz	done
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		call	ObjMessageCall
done:
		ret
SetNameField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNameMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text moniker for an item in one of our lists.

CALLED BY:	INTERNAL	HyperlinkControlFileListGetMoniker

PASS:		*ds:si	= controller
		^lbx:di	= object that wants name
		cl	= VisTextNameType
		dx	= file token (-1 if file name)
		ax	= physical list index
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNameMoniker	proc	near

		sub	sp, (size VisTextNameCommonParams)
		mov	bp, sp
		mov	ss:[bp].VTNCP_index, ax
		movdw	ss:[bp].VTNCP_object, bxdi
		mov	ss:[bp].VTNCP_data.VTND_type, cl
		mov	ss:[bp].VTNCP_data.VTND_file, dx
		mov	dx, (size VisTextNameCommonParams)
		mov	ax, MSG_VIS_TEXT_GET_NAME_LIST_MONIKER
		call	SendToOutputStack
		add	sp, (size VisTextNameCommonParams)
		ret
GetNameMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNameMonikerFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the moniker for an item in one of our lists in
		a ReplaceItemMonikerFrame.

CALLED BY:	INTERNAL	UpdatePageDeleteAndRenameUI
				UpdateFileDeleteAndRenameUI
				PageListGetMonikerLow

PASS:		*ds:si	= controller
		^lbx:di	= object that wants name
		ax	= message to send to object
		ch	= VisTextNameCommonFlags
		cl	= VisTextNameType
		dx	= file token (-1 if file name)
		bp	= physical list index

RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNameMonikerFrame	proc	near
passedBP	local	word	push bp
params		local	VisTextNameCommonParams
		.enter

		mov	ss:[params].VTNCP_message, ax
		mov	ax, ss:[passedBP]
		mov	ss:[params].VTNCP_index, ax
		movdw	ss:[params].VTNCP_object, bxdi
		mov	ss:[params].VTNCP_flags, ch
		mov	ss:[params].VTNCP_data.VTND_type, cl
		mov	ss:[params].VTNCP_data.VTND_file, dx
		mov	dx, (size VisTextNameCommonParams)
		mov	ax, MSG_VIS_TEXT_GET_NAME_LIST_MONIKER_FRAME
		push	bp
		lea	bp, ss:[params]
		call	SendToOutputStack
		pop	bp
		
		.leave
		ret
GetNameMonikerFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMonikerType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC-only. Ensures moniker source is a fptr to a text string.

CALLED BY:	INTERNAL	HyperlinkControlSetRenameFileText
				HyperlinkControlSetRenamePageText
				PNCSetPageName
PASS:		ss:bp	= ReplaceItemMonikerFrame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
CheckMonikerType	proc	near
		cmp	ss:[bp].RIMF_dataType, VMDT_TEXT
		ERROR_NE HYPERLINK_BAD_NAME_LIST_MONIKER_TYPE
		cmp	ss:[bp].RIMF_sourceType, VMST_FPTR
		ERROR_NE HYPERLINK_BAD_NAME_LIST_MONIKER_TYPE
		ret
CheckMonikerType	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSetDestListSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selections in the SetDest file and page name lists.

CALLED BY:	INTERNAL	HyperlinkControlSetHyperlink
				UpdateForPageNameChange
PASS:		nothing
RETURN:		bx	= child block
		ax	= page selected in SetDestPageList
		dx	= file selected in SetDestFileList
		di	= chunk of SetDestPageList
		
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSetDestListSelections	proc	near

		mov	di, offset SetDestFileList
		call	GetListSelection
		mov	dx, ax				; dx <- file
		call	GetSetDestPageListSelection	; ax <- page
		ret
GetSetDestListSelections	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSetDestPageListSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selections in the SetDest page name list.

CALLED BY:	INTERNAL	UpdateForHyperlinkabilityChange
				GetSetDestListSelections
PASS:		nothing
RETURN:		ax	= page selected in SetDestPageList
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSetDestPageListSelection	proc	near
		mov	di, offset SetDestPageList
		call	GetListSelection		; ax <- page
		ret
GetSetDestPageListSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetManageDestListSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selections in the ManageDest file and page name lists.

CALLED BY:	INTERNAL	HyperlinkControlDeletePageName
				HyperlinkControlChangePageName
				UpdateForPageNameChange
PASS:		nothing
RETURN:		bx	= child block
		ax	= page selected in ManageDestPageList
		dx	= file selected in ManageDestFileList
		di	= chunk of ManageDestPageList
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetManageDestListSelections	proc	near

		call	GetManageDestFileListSelection	; dx <- file
		mov	di, offset ManageDestPageList
		call	GetListSelection		; ax <- page
		ret
GetManageDestListSelections	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetManageDestFileListSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selections in the ManageDest file list.

CALLED BY:	INTERNAL	HyperlinkControlManagedestPageChanged
				GetManageDestListSelections
PASS:		nothing
RETURN:		bx	= child block
		dx	= file selected in ManageDestFileList
		di	= chunk of ManageDestFileList
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetManageDestFileListSelection	proc	near

		mov	di, offset ManageDestCurrentFileList
		call	GetListSelection		; ax <- file
		mov_tr	dx, ax
		ret
GetManageDestFileListSelection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetManageFilesFileListSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selections in the ManageFiles file list.

CALLED BY:	INTERNAL	HyperlinkControlDeleteFileName
				HyperlinkControlChangeFileName
PASS:		nothing
RETURN:		bx	= child block
		ax	= file selected in ManageFilesFileList
		di	= chunk of ManageFilesFileList
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetManageFilesFileListSelection	proc	near

		mov	di, offset ManageFilesFileList
		call	GetListSelection		; ax <- file
		ret
GetManageFilesFileListSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetListSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current selection of a list

CALLED BY:	UTILITY
PASS:		*ds:si	= controller
		di	= chunk of list
		
RETURN:		ax	= list entry # of selection or GIGS_NONE for none
		bx	= hptr of child block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetListSelection		proc	near
		uses	di, cx, dx, bp, si
		.enter

		call	GetChildBlockAndFeatures
		mov	si, di			;^lbx:si <- OD of list
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
GetListSelection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetListSelectionNoIndeterminates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set selection in one of our lists (no indeterminates)

CALLED BY:	UTILITY
PASS:		^lbx:di	= OD of list
		*ds:si	= controller object
		cx	= list entry #
RETURN:		none
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetListSelectionNoIndeterminates	proc	near
		clr	dx			;dx <- not indeterminate
		call	SetListSelection
		ret
SetListSelectionNoIndeterminates		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetListSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set selection in one of our lists

CALLED BY:	INTERNAL	SetListSelectionNoIndeterminates
PASS:		^lbx:di - OD of list
		*ds:si - controller object
		cx - list entry #
		dx - non-zero for indeterminates

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetListSelection		proc	near
		uses	ax, di, si
		.enter

		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	SendEventViaOutput

		.leave
		ret
SetListSelection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildBlockAndFeatures
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
	jenny	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildBlockAndFeatures	proc	near
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData
		mov	ax, ds:[bx].TGCI_features
		mov	bx, ds:[bx].TGCI_childBlock
		ret
GetChildBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildBlockAndFeaturesFromGCUUIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get controller's child block and features.

CALLED BY:	INTERNAL	UpdateForNameChange

PASS:		ss:bp	= GenControlUpdateUIParams
RETURN:		ax	= features
		bx	= child block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildBlockAndFeaturesFromGCUUIP	proc	near
		mov	ax, ss:[bp].GCUUIP_features
		mov	bx, ss:[bp].GCUUIP_childBlock
		ret
GetChildBlockAndFeaturesFromGCUUIP	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendOurselvesEventViaOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the controller via its output

CALLED BY:	INTERNAL	PageForceUpdateUI

PASS:		*ds:si	= controller
		ax	= message to send

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Assures that the passed message is handled after any
		other messages previously sent via the output. Used
		when the actions to be performed by the message
		handler depend on those earlier messages having been
		handled.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendOurselvesEventViaOutput	proc	near
		uses	bx, di
		.enter
	;
	; Get the OD of our controller and send it the event
	;
		call	GetControllerOD
		call	SendEventViaOutput
		.leave
		ret
SendOurselvesEventViaOutput	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetControllerOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the OD for the passed controller

CALLED BY:	INTERNAL	UpdateFileDeleteAndRenameUI
				UpdatePageDeleteAndRenameUI
				SendOurselvesEventViaOutput

PASS:		*ds:si	= controller instance data
RETURN:		^bx:di	= controller OD
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetControllerOD	proc	near
		mov	bx, ds:[LMBH_handle]
		mov	di, si
		ret
GetControllerOD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendEventViaOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an event via the hyperlink controller's output

CALLED BY:	INTERNAL	UpdatePageListUI
				SetListSelection
PASS:		^lbx:di	= OD of object to send event to
		*ds:si	= controller object
		ax	= message
		cx, dx, bp = data for message

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Makes sure that a message gets processed after other
		messages on whose results it depends have made it to
		the controller output and been processed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendEventViaOutput	proc	near
		uses	cx, dx, si, di, bp
		.enter
	;
	; We need to mess around a bit here so things stay synchronized.
	; We record the passed message with the desired recipient as its
	; destination. Then we send off MSG_META_DISPATCH_EVENT to the
	; output (usually the target text object), which will
	; cooperate by dispatching our recorded event.
	;
		push	si
		mov	si, di			; ^lbx:si <- OD of list
		clr	di			; di <- flags for ObjMessage
		call	RecordEvent
		mov	ax, MSG_META_DISPATCH_EVENT
		clr	dx			; dx <- MessageFlags
						;  for event
		pop	si			; *ds:si <- controller
		call	SendToOutput

		.leave
		ret
SendEventViaOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record an event

CALLED BY:	INTERNAL	SendEventViaOutput
				SendEventToAppTarget

PASS:		^lbx:si	= OD of object to receive event
		ax	= message

		di	= flags for ObjMessage (MF_STACK or 0)
			if di = MF_STACK
				ss:bp	= data on stack
			else
				cx, dx, bp = data

RETURN:		cx	= event handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	6/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordEvent	proc	near
		or	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di				;cx <- recorded message
		ret
RecordEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the output of the hyperlink
		controller, with data passed in registers.

CALLED BY:	INTERNAL
PASS:		*ds:si	= controller
		ax	= message
		cx, dx, bp = data
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	
	Assumes message must be handled by a VisText object.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToOutput	proc	near
		uses	bx, dx, di
		.enter

		mov	bx, segment VisTextClass
		mov	di, offset VisTextClass		;bx:di <- class ptr
		call	GenControlSendToOutputRegs

		.leave
		ret
SendToOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToOutputStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the output of the hyperlink
		controller, with data passed on the stack.

CALLED BY:	INTERNAL
PASS:		*ds:si	= controller
		ax	= message
		ss:bp	= data
		dx	= data size		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToOutputStack	proc	near
		uses	bx, dx, di
		.enter

		mov	bx, segment VisTextClass
		mov	di, offset VisTextClass		;bx:di <- class ptr
		call	GenControlSendToOutputStack

		.leave
		ret
SendToOutputStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessageSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call ObjMessage with just MF_FIXUP_DS

CALLED BY:	INTERNAL
PASS:		^lbx:si	= object
		ax	= message
		cx, dx, bp = optional data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMessageSend	proc	near
		uses	ax, cx, dx, bp, di
		.enter

		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
ObjMessageSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessageCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call ObjMessage with just MF_FIXUP_DS and MF_CALL

CALLED BY:	INTERNAL
PASS:		^lbx:di	= object
		ax	= message
		cx, dx, bp = optional data
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	ds may be fixed up

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMessageCall	proc	near
		uses	si, di, bp
		.enter

		mov	si, di
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage

		.leave
		ret
ObjMessageCall	endp

HyperlinkAndPageNameControlCode ends
