COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Globalpc 1999 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		prefpntc.asm

AUTHOR:		Edwin, July 27, 1999

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Edwin	7/27/99		Initial revision
   jfh	6/5/02		added IM & FTP

DESCRIPTION:
		

	$Id: $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;	Common GEODE stuff
;-----------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	graphics.def
include gstring.def
include library.def


;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib  Objects/vTextC.def
UseLib	config.def
UseLib  parentc.def

include prefpntc.def
include	prefpntc.rdef

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------

idata	segment

	PrefPntCDialogClass
	PntCtrlItemGroupClass
	PCPrefInteractionClass
	PCSettingPrefInteractionClass

idata	ends


PrefPntCtrlCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		nothing 

RETURN:		dx:ax - OD of root of tree

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	7/25/99		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompGetPrefUITree	proc far
	mov	dx, handle PrefPntCtrlRoot
	mov	ax, offset PrefPntCtrlRoot
	ret
PrefCompGetPrefUITree	endp
public	PrefCompGetPrefUITree




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr

PASS:		ds:si - PrefModuleInfo structure to be filled in

RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	7/25/99		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_HARDWARE
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle  CompMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset  CompMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('P' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'G' or ('D' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	.leave
	ret
PrefCompGetModuleInfo	endp
public	PrefCompGetModuleInfo



COMMENT @--------------------------------------------------------------------

METHOD:		MSG_GEN_DESTROY_AND_FREE_BLOCK
					for PrefPntCDialogClass

DESCRIPTION:	Close all subordinate dialogs first.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- mssage
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
	brianc	2/10/00		Initial Version

----------------------------------------------------------------------------@
PrefPntCDialogDestroyAndFreeBlock	method dynamic PrefPntCDialogClass,
					MSG_GEN_DESTROY_AND_FREE_BLOCK
	;
	; close child dialogs
	;
	push	ax, si
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	si, offset ChangeAccessLevel
	call	ObjCallInstanceNoLock
	pop	ax, si
	;
	; do the thang
	;
	mov	di, offset PrefPntCDialogClass
	call	ObjCallSuperNoLock
	ret
PrefPntCDialogDestroyAndFreeBlock	endm



COMMENT @--------------------------------------------------------------------

METHOD:		MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
					for PntCtrlItemGroupClass

DESCRIPTION:	Handles selection of parental control on/off.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- mssage
		cx	- identifier of the item to select
		dx	- non-zero if indeterminate
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
	edwin	7/25/99		Initial Version

----------------------------------------------------------------------------@
PntCtrlSetSelection method dynamic PntCtrlItemGroupClass,
					MSG_PREF_CONTROL_SET_SELECTION
	.enter

	mov	bx, ds:[LMBH_handle]
	push	bx, si, ax, cx, di
	; cx - PC_ON or PC_OFF
	mov	si, offset ParentControlPasswordRoot
	mov	di, mask MF_CALL
	mov	ax, MSG_PC_BRING_UP_PASSWORD_DB
	call	ObjMessage
	cmp	ax, IC_OK
	pop	bx, si, ax, cx, di
	je	apply
	;
	;  User decide to abandon the change.
	;  Set the selection back
	;
	cmp	cx, PC_ON
	je	turnBackOff
	mov	cx, PC_ON
	jmp	turnBackOn
turnBackOff:
	mov	cx, PC_OFF
turnBackOn:
	call	MemDerefDS
	mov	di, offset PntCtrlItemGroupClass
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjCallSuperNoLock

	jmp	cont

apply:
	call	MemDerefDS
	mov	di, offset PntCtrlItemGroupClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, PC_ON
	je	setTrig
	;
	;  Turn all the internet areas permissible, i.e. all green
	;
	clr	ax
	call	ParentalControlSetAccessInfo

	mov	si, offset LevelGroup
	mov	ax, MSG_PI_REFRESH_SETTING
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	; edwdig was here
	mov	si, offset ChangeAccessLevelButton
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage
	jmp	cont
	; edwdig done
		
setTrig:
	mov	si, offset ChangeAccessLevelButton
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage

	; edwdig was here
	; Pop up the set access levels dialog. No need to ask for password
	; since the user just set it.
	mov	si, offset ChangeAccessLevel
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage
	; edwdig finished here

cont:
	.leave
	ret
PntCtrlSetSelection	endm



COMMENT @--------------------------------------------------------------------

METHOD:		MSG_VIS_OPEN for PntCtrlItemGroupClass

DESCRIPTION:	Check PCtrl flag in the ini file.  If set, then turn on the
		item group.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- mssage

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
	edwin	8/12/99		Initial Version

----------------------------------------------------------------------------@
PntCtrlVisOpen method dynamic PntCtrlItemGroupClass,
					MSG_VIS_OPEN
	.enter

	mov	di, offset PntCtrlItemGroupClass
	call	ObjCallSuperNoLock

	call	ParentalControlGetAccessInfo	; ax = access flags
	test	ax, mask AF_PCON
	jz	ctrlNotSet

	mov	bx, ds:[LMBH_handle]
	mov	si, offset OnOffSwitchGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	cx, PC_ON
	mov	di, mask MF_CALL
	call	ObjMessage

ctrlNotSet:
	.leave
	ret
PntCtrlVisOpen	endm




COMMENT @---------------------------------------------------------------------

METHOD:		MSG_VIS_OPEN for PCPrefInteractionClass

DESCRIPTION:	Handles selection of parental control on/off.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- mssage
		cx	- identifier of the item to select
		dx	- non-zero if indeterminate
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
	edwin	7/25/99		Initial Version
	Don	9/22/00		Optimized incredible ugly code
	jfh	6/5/02		added IM & FTP
-----------------------------------------------------------------------------@
PCPrefInteractionOpen method dynamic PCPrefInteractionClass,
					MSG_VIS_OPEN,
					MSG_PI_REFRESH_SETTING
	.enter

	mov	di, offset PCPrefInteractionClass
	call	ObjCallSuperNoLock

	call	ParentalControlGetAccessInfo

	;
	;  Master Parental Control setting - On/Off
	;
	push	ax
	test	ax, mask AF_PCON
	mov	ax, MSG_GEN_SET_ENABLED		; assume ON
	jnz	pc
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; nope, it is OFF
pc:
	mov	bx, ds:[LMBH_handle]
	mov	si, offset ChangeAccessLevelButton
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	;
	;  WWW Browser setting - Full/Limited/None
	;		
	mov	dx, offset greenMoniker		; assume Full
	mov	di, offset fullMoniker
	test	ax, mask AF_WWWBROWSING
	jz	www
	mov	dx, offset yellowMoniker	; now assume Limited
	mov	di, offset limitedMoniker
	test	ax, mask AF_WWWLIMITED
	jnz	www
	mov	dx, offset redMoniker		; nope, it is None
	mov	di, offset noneMoniker
www:
	mov	si, offset RItemWWW
	mov	bp, offset LItemWWW
	call	setColorAndText

	;
	;  Email setting - Full/None
	;
	mov	dx, offset greenMoniker		; assume Full
	mov	di, offset fullMoniker
	test	ax, mask AF_EMAIL
	jz	email
	mov	dx, offset redMoniker		; nope, it is None
	mov	di, offset noneMoniker
email:
	mov	si, offset RItemEmail
	mov	bp, offset LItemEmail
	call	setColorAndText

	;
	;  Newsgroup setting - Full/None
	;
	mov	dx, offset greenMoniker		; assume Full
	mov	di, offset fullMoniker
	test	ax, mask AF_NEWSGROUP
	jz	newsgroup
	mov	dx, offset redMoniker		; nope, it is None
	mov	di, offset noneMoniker
newsgroup:
	mov	si, offset RItemNewsgroup
	mov	bp, offset LItemNewsgroup
	call	setColorAndText

	;
	;  Chat setting - Full/None
	;
	mov	dx, offset greenMoniker		; assume Full
	mov	di, offset fullMoniker
	test	ax, mask AF_CHATROOM
	jz	chat
	mov	dx, offset redMoniker		; nope, it is None
	mov	di, offset noneMoniker
chat:
	mov	si, offset RItemChat
	mov	bp, offset LItemChat
	call	setColorAndText

	;
	;  IM setting - Full/None
	;
	mov	dx, offset greenMoniker		; assume Full
	mov	di, offset fullMoniker
	test	ax, mask AF_IM
	jz	IMsg
	mov	dx, offset redMoniker		; nope, it is None
	mov	di, offset noneMoniker
IMsg:
	mov	si, offset RItemIM
	mov	bp, offset LItemIM
	call	setColorAndText

	;
	;  FTP setting - Full/None
	;
	mov	dx, offset greenMoniker		; assume Full
	mov	di, offset fullMoniker
	test	ax, mask AF_FTP
	jz	ftp
	mov	dx, offset redMoniker		; nope, it is None
	mov	di, offset noneMoniker
ftp:
	mov	si, offset RItemFTP
	mov	bp, offset LItemFTP
	call	setColorAndText

	.leave
	ret

	;
	; Internal sub-routine to set a couple of monikers
	; Pass:
	;	^lbx:si = "right" GenGlyph
	;	^lbx:bp = "left" GenGlyph
	;	dx      = chunk handle in MonikerResource for "right"
	;	di      = chunk handle in Strings for "left"
	;
	; Note that only AX is preserved, and that DS is updated!
	;
setColorAndText:
	push	ax
	push	bp
	push	di
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	cx, handle MonikerResource
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	dx, handle Strings ;  ^ldx:bp - source chunk
	pop	bp
	clr	cx
	pop	si
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax
	retn
PCPrefInteractionOpen	endm



COMMENT @---------------------------------------------------------------------

METHOD:		MSG_VIS_OPEN for PCPrefInteractionClass

DESCRIPTION:	Handles selection of parental control on/off.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- mssage
		cx	- identifier of the item to select
		dx	- non-zero if indeterminate
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
	edwin	7/25/99		Initial Version
	jfh	6/5/02		added IM & FTP
-----------------------------------------------------------------------------@
PCSettingPrefInteractionOpen method dynamic PCSettingPrefInteractionClass,
					MSG_VIS_OPEN
	.enter

	mov	di, offset PCSettingPrefInteractionClass
	call	ObjCallSuperNoLock

	call	ParentalControlGetAccessInfo
	;
	;  WWW browsing
	test	ax, mask AF_WWWBROWSING
	jz	setWWWfull
	test	ax, mask AF_WWWLIMITED
	jz	setWWWnone
	mov	cx, PC_LIMITED
	jmp	www
setWWWnone:
	mov	cx, PC_OFF
	jmp	www
setWWWfull:
	mov	cx, PC_ON
www:
	mov	bx, ds:[LMBH_handle]
	mov	si, offset LItemOneII
	push	ax
	push	cx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	clr	dx
	call	ObjMessage
	pop	cx
	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, PC_LIMITED
	je	haveListState
	mov	ax, MSG_GEN_SET_NOT_ENABLED
haveListState:
	mov	si, offset EditTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	ax
	;
	;  Email
	test	ax, mask AF_EMAIL
	jz	setEmailfull
	mov	cx, PC_OFF
	jmp	email
setEmailfull:
	mov	cx, PC_ON
email:
	mov	si, offset LItemTwoII
	push	ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	clr	dx
	call	ObjMessage
	pop	ax
	;
	;  Newsgroup
	test	ax, mask AF_NEWSGROUP
	jz	setNewsfull
	mov	cx, PC_OFF
	jmp	newsgroup
setNewsfull:
	mov	cx, PC_ON
newsgroup:
	mov	si, offset LItemThreeII
	push	ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	clr	dx
	call	ObjMessage
	pop	ax
	;
	;  Chat
	test	ax, mask AF_CHATROOM
	jz	setChatfull
	mov	cx, PC_OFF
	jmp	chat
setChatfull:
	mov	cx, PC_ON
chat:
	mov	si, offset LItemFourII
	push	ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	clr	dx
	call	ObjMessage
	pop	ax
	;
	;  IM
	test	ax, mask AF_IM
	jz	setIMfull
	mov	cx, PC_OFF
	jmp	im
setIMfull:
	mov	cx, PC_ON
im:
	mov	si, offset LItemFiveII
	push	ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	clr	dx
	call	ObjMessage
	pop	ax
	;
	;  FTP
	test	ax, mask AF_FTP
	jz	setFTPfull
	mov	cx, PC_OFF
	jmp	ftp
setFTPfull:
	mov	cx, PC_ON
ftp:
	mov	si, offset LItemSixII
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	clr	dx
	call	ObjMessage

	.leave
	ret
PCSettingPrefInteractionOpen	endm



COMMENT @--------------------------------------------------------------------

METHOD:		MSG_PARENT_CONTROL_SETTINGS_SET for
					PCSettingPrefInteractionClass

DESCRIPTION:	Read the control settings from the ui and write to the ini 
		file via the parentc library.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- mssage
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
	edwin	8/2/99		Initial Version
	jfh	6/5/02		added IM & FTP

----------------------------------------------------------------------------@
PCPrefInteractionSetCtrl method dynamic PCSettingPrefInteractionClass,
				MSG_PARENT_CONTROL_SETTINGS_SET
	.enter

	clr	cx
	push	cx
	;
	;  WWWBrowser
	;
	mov	bx, ds:[LMBH_handle]
	mov	si, offset LItemOneII
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx
	cmp	ax, PC_ON
	je	testEmail
	or	cx, mask AF_WWWBROWSING
	cmp	ax, PC_LIMITED
	jne	testEmail
	or	cx, mask AF_WWWLIMITED

testEmail:
	push	cx
	;
	;  Email
	;
	mov	si, offset LItemTwoII
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx
	cmp	ax, PC_ON
	je	testNewsgroup
	or	cx, mask AF_EMAIL

testNewsgroup:
	push	cx
	;
	;  Newsgroup
	;
	mov	si, offset LItemThreeII
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx
	cmp	ax, PC_ON
	je	testChatroom
	or	cx, mask AF_NEWSGROUP

testChatroom:
	push	cx
	;
	;  Chatoom
	;
	mov	si, offset LItemFourII
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx
	cmp	ax, PC_ON
	je	testIM
	or	cx, mask AF_CHATROOM

testIM:
	push	cx
	;
	;  IM
	;
	mov	si, offset LItemFiveII
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx
	cmp	ax, PC_ON
	je	testFTP
	or	cx, mask AF_IM

testFTP:
	push	cx
	;
	;  FTP
	;
	mov	si, offset LItemSixII
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx
	cmp	ax, PC_ON
	je	setNow
	or	cx, mask AF_FTP

setNow:
	mov	ax, cx
	call	ParentalControlSetAccessInfo

	mov	si, offset LevelGroup
	mov	ax, MSG_PI_REFRESH_SETTING
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
PCPrefInteractionSetCtrl	endm



COMMENT @--------------------------------------------------------------------

METHOD:		MSG_PARENT_CONTROL_CHANGE_LEVEL for
					PCSettingPrefInteractionClass

DESCRIPTION:	Verify user's password then bring up the dialog box
		for changing the access level.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- mssage
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
	edwin	9/6/99		Initial Version

----------------------------------------------------------------------------@
PCPrefInteractionChangeLevel method dynamic PCSettingPrefInteractionClass,
				MSG_PARENT_CONTROL_CHANGE_LEVEL
	.enter

	mov	bx, ds:[LMBH_handle]
	mov	cx, PC_OFF
	mov	si, offset ParentControlPasswordRoot
	mov	cl, PC_PARENTAL_CONTROL
	mov	di, mask MF_CALL
	mov	ax, MSG_PC_CHECK_PASSWORD_DB
	call	ObjMessage

	cmp	ax, IC_OK
	jne	quit

	mov	si, offset ChangeAccessLevel
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage
quit:
	.leave
	ret
PCPrefInteractionChangeLevel	endm


COMMENT @--------------------------------------------------------------------

METHOD:		MSG_PARENT_CONTROL_{BROWSER,CHAT}_ACCESS_STATUS for
					PCSettingPrefInteractionClass

DESCRIPTION:	Access level status change.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- mssage
		cx	- current selection
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
	brianc	5/11/00		Initial Version

----------------------------------------------------------------------------@
PCPrefInteractionAccessStatus method dynamic PCSettingPrefInteractionClass,
				MSG_PARENT_CONTROL_BROWSER_ACCESS_STATUS,
				MSG_PARENT_CONTROL_CHAT_ACCESS_STATUS
	.enter
	;
	; update Edit List... state
	;
	cmp	ax, MSG_PARENT_CONTROL_BROWSER_ACCESS_STATUS
	jne	doneEdit
	push	ax, cx
	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, PC_LIMITED
	je	haveEditState
	mov	ax, MSG_GEN_SET_NOT_ENABLED
haveEditState:
	mov	dl, VUM_NOW
	mov	si, offset EditTrigger
	call	ObjCallInstanceNoLock
	pop	ax, cx
doneEdit:
	;
	; only in CUI
	;
	push	ax
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	pop	ax
	jne	done
	cmp	ax, MSG_PARENT_CONTROL_CHAT_ACCESS_STATUS
	je	chat
browser::
	;
	; turning browser off -> warn, then turn off chat
	;
	cmp	cx, PC_OFF
	jne	done
	; check if chat is already off
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset LItemFourII
	call	ObjCallInstanceNoLock
	cmp	ax, PC_OFF
	je	done				; already off
	mov	ax, offset BrowserStatusOffWarning
	call	callDialog
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, PC_OFF
	clr	dx
	mov	si, offset LItemFourII
	call	ObjCallInstanceNoLock
	jmp	done

chat:
	;
	; turning chat on -> warning that browser should be on or limited
	;
	cmp	cx, PC_ON
	jne	done
	; check if browser is already on or limited
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset LItemOneII
	call	ObjCallInstanceNoLock
	cmp	ax, PC_OFF
	jne	done				; already on or limited
	mov	ax, offset ChatStatusOnWarning
	call	callDialog
done:
	.leave
	ret

callDialog	label	near
	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags,
		CustomDialogBoxFlags<0, CDT_WARNING, GIT_NOTIFICATION, 0>
	mov	ss:[bp].SDP_customString.handle, handle Strings
	mov	ss:[bp].SDP_customString.offset, ax
	clrdw	ss:[bp].SDP_stringArg1
	clrdw	ss:[bp].SDP_stringArg2
	clrdw	ss:[bp].SDP_customTriggers
	clrdw	ss:[bp].SDP_helpContext
EC <	mov	bx, ds:[LMBH_handle]					>
	call	UserStandardDialogOptr		; trashes DS with ECF_SEGMENT
EC <	call	MemDerefDS						>
	retn
PCPrefInteractionAccessStatus	endm
		
PrefPntCtrlCode	ends

