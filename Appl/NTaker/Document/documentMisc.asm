COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	NTaker
MODULE:		Document
FILE:		documentMisc.asm

AUTHOR:		Andrew Wilson, Feb 12, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/92		Initial revision

DESCRIPTION:
	This file contains misc utility routines and method handlers for
	minor objects.	

	$Id: documentMisc.asm,v 1.1 97/04/04 16:17:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentCode	segment	resource

;------------------------------------------------------------------------------
;		Code for NTakerDisplayGroupClass
;-----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerInstallToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install tokens
CALLED BY:	MSG_GEN_PROCESS_INSTALL_TOKEN

PASS:		none
RETURN:		none
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NTakerInstallToken	method NTakerProcessClass, MSG_GEN_PROCESS_INSTALL_TOKEN
	;
	; Call our superclass to get the ball rolling...
	;
	mov	di, offset NTakerProcessClass
	call	ObjCallSuperNoLock

	; install datafile token

	mov	ax, ('n') or ('t' shl 8)	; ax:bx:si = token used for
	mov	bx, ('k') or ('r' shl 8)	;	datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	done				; yes, do nothing

	mov	cx, handle DatafileMonikerList	; cx:dx = OD of moniker list
	mov	dx, offset DatafileMonikerList
	clr	bp				; list in data resource, so
						;  no relocation
	call	TokenDefineToken		; add icon to token database
done:
	ret
NTakerInstallToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureNoteTypeKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures that there is a valid noteType key in the .ini file.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	si, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureNoteTypeKey	proc	near	uses	ax, cx, dx, bp, ds
	.enter
	segmov	ds, cs, cx
	mov	si, offset ntakerCategory
	mov	dx, offset noteTypeKey
	call	InitFileReadInteger
	jnc	exit

;	If there is no noteType key, just start up in text mode.

	call	SysGetPenMode
	mov	bp, NT_INK
	tst	ax
	jnz	10$
	mov	bp, NT_TEXT
10$:
	call	InitFileWriteInteger
exit:
	.leave
	ret
EnsureNoteTypeKey	endp

ntakerCategory	char	"notetaker",0
noteTypeKey	char	"cardType",0
viewTypeKey	char	"viewOnStartup",0




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetStartupViewMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current view mode when we are just starting up.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetStartupViewMode	proc	near	uses	ax, bx, cx, dx, ds, si
	.enter
	segmov	ds, cs, cx
	mov	si, offset ntakerCategory
	mov	dx, offset viewTypeKey
	call	InitFileReadInteger
	jc	setDefault
	cmp	ax, ViewType						
	jb	setViewType

setDefault:
	mov	ax, VT_CARD
setViewType:
	mov_tr	cx, ax			;CX <- view type to use
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx			
	GetResourceHandleNS	ViewTypeList, bx
	mov	si, offset ViewTypeList
	clr	di
	call	ObjMessage
	.leave
	ret
SetStartupViewMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Message handler for MSG_GEN_PROCESS_OPEN_APPLICATION
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerProcessClass object
		ds:di	= NTakerProcessClass instance data
		ds:bx	= NTakerProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerOpenApplication	method dynamic NTakerProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION

	call	EnsureNoteTypeKey
	test	cx, mask AAF_RESTORING_FROM_STATE
	jnz	noSetViewMode
	call	SetStartupViewMode
noSetViewMode:
	push	ax, cx, dx, bp

;	Get the current feature set

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	es:[features], ax

;	Add to the clipboard notification list, so we can enable/disable the
;	"Paste Background" trigger.

	call	SysGetPenMode
	tst	ax
	jz	noNotificationList

	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	call	ClipboardAddToNotificationList

noNotificationList:
; hide non-appropriate tool controls
	GetResourceHandleNS	InkMenu, bx
	call	SysGetPenMode
	tst	ax
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	si, offset NTakerToolControl
	jz	noPen
	mov	si, offset NTakerToolControlNoPen
noPen:
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

;	Set various pen-mode only controllers not-usable
	call	SysGetPenMode
	tst	ax
	mov	ax, MSG_GEN_SET_NOT_USABLE
	jz	setUsability
	mov	ax, MSG_GEN_SET_USABLE

setUsability:
	GetResourceHandleNS	InkMenu, bx
	push	ax
	mov	si, offset InkMenu
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	push	ax
	mov	si, offset PrintCurPage
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	push	ax
	mov	si, offset NTakerPageControl
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax				; ax = USABLE/NOT_USABLE

	push	ax
	mov	si, offset NewPageTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	push	ax
	mov	si, offset CardTypeGroup
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	call	UserGetInterfaceOptions
	test	ax, mask UIIO_OPTIONS_MENU
	mov	ax, MSG_GEN_SET_NOT_USABLE
	jz	doOptionsMenu
	mov	ax, MSG_GEN_SET_USABLE
doOptionsMenu:
	mov	si, offset OptionsMenu
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	ax, cx, dx, bp
	mov	di, offset NTakerProcessClass
	GOTO	ObjCallSuperNoLock
NTakerOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Message handler for MSG_GEN_PROCESS_CLOSE_APPLICATION
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerProcessClass object
		ds:di	= NTakerProcessClass instance data
		ds:bx	= NTakerProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		cx	= 0 (no extra data block for state file)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerCloseApplication	method dynamic NTakerProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION
	push	ax, dx, bp
	call	SysGetPenMode
	tst	ax
	jz	notInk
	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	call	ClipboardRemoveFromNotificationList

notInk:
	pop	ax, dx, bp
	clr	cx			;No extra data block
	mov	di, offset NTakerProcessClass
	GOTO	ObjCallSuperNoLock
NTakerCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerMetaClipboardNotifyNormalTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Message handler for MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_
		ITEM_CHANGED
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerProcessClass object
		ds:di	= NTakerProcessClass instance data
		ds:bx	= NTakerProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:	
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerMetaClipboardNotifyNormalTransferItemChanged	method dynamic \
NTakerProcessClass, MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	uses	ax, cx, dx, bp
	.enter

	clr	bp
	call	ClipboardQueryItem
	push	ax, bx
	tst	bp
	jz	noTransfer

;	ClipboardTestItemFormat:
;	PASS:
;	bx:ax = transfer item header (returned by ClipboardQueryItem)
;	cx:dx - format manufacturer:format type
;	RETURN:
;	C clear if format supported
;	C set if format not supported

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardTestItemFormat
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jc	noTransfer
	mov	ax, MSG_GEN_SET_ENABLED

noTransfer:
	;disable the NTakerBackgroundPasteTrigger
	mov	dl, VUM_NOW
	GetResourceHandleNS NTakerBackgroundPasteTrigger, bx
	mov	si, offset NTakerBackgroundPasteTrigger
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	ax, bx
	call	ClipboardDoneWithItem

	.leave
	ret
NTakerMetaClipboardNotifyNormalTransferItemChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerSetViewType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the view type for all open documents.

CALLED BY:	GLOBAL
PASS:		cx - ViewType
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerSetViewType	method	NTakerProcessClass, MSG_NTAKER_SET_VIEW_TYPE

;	Send a message off to all currently opened displays, to have them
;	change their configuration.

	mov	ax, MSG_NTAKER_DOC_SET_VIEW_TYPE
	FALL_THRU	SendMessageToAllDocuments

NTakerSetViewType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMessageToAllDocuments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the passed documents.

CALLED BY:	GLOBAL
PASS:		ax - message to send
		cx, dx, bp - params
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendMessageToAllDocuments	proc	far
	mov	bx, es
	mov	si, offset NTakerDocumentClass	;BX:SI <- ptr to class of dest
						; object
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				;CX <- ClassedEvent

	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	GetResourceHandleNS	NTakerDocumentGroup, bx
	mov	si, offset NTakerDocumentGroup
	clr	di
	GOTO	ObjMessage
SendMessageToAllDocuments	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerChangeOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes UI based on passed options.

CALLED BY:	GLOBAL
PASS:		cx - NTakerOptions
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerChangeOptions	method	NTakerProcessClass, MSG_NTAKER_CHANGE_OPTIONS

	mov	ax, MSG_NTAKER_DISPLAY_CHANGE_OPTIONS
	FALL_THRU	SendMessageToAllDisplays
NTakerChangeOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMessageToAllDisplays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the passed displays.

CALLED BY:	GLOBAL
PASS:		ax - message to send
		cx, dx, bp - params
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendMessageToAllDisplays	proc	far
	mov	bx, es
	mov	si, offset NTakerDisplayClass	;BX:SI <- ptr to class of dest
						; object
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				;CX <- ClassedEvent

	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	GetResourceHandleNS	NTakerDispGroup, bx
	mov	si, offset NTakerDispGroup
	clr	di
	GOTO	ObjMessage
SendMessageToAllDisplays	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerNotifyOptionsChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the application object of a user-option change

CALLED BY:	Various

PASS:		Nothing

RETURN:		Nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/7/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NTakerNotifyOptionsChange	proc	far
	uses	ax, bx, di, si
	.enter

	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	GetResourceHandleNS NTakerApp, bx
	mov	si, offset NTakerApp
	clr	di
	call	ObjMessage

	.leave
	ret
NTakerNotifyOptionsChange	endp

DocumentCode	ends
