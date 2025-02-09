COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/User
FILE:		userC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the User routines

	$Id: userC.asm,v 1.1 97/04/07 11:45:55 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_User	segment	resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardRegisterItem

C DECLARATION:	extern Boolean
			_far _pascal ClipboardRegisterItem(
				TransferBlockID header,
				word flags);	/* ClipboardItemFlags */

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDREGISTERITEM	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx=file, ax=block, cx=flags

	push	bp
	mov	bp, cx			; bp = flags
	call	ClipboardRegisterItem
	pop	bp

	mov	ax, 0			; set Boolean return value
	jc	done			; (carry -> error -> FALSE)
	dec	ax
done:
	ret
CLIPBOARDREGISTERITEM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardUnregisterItem

C DECLARATION:	extern void
			_far _pascal ClipboardUnregisterItem(optr owner);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDUNREGISTERITEM	proc	far
	C_GetOneDWordArg	cx, dx,  ax, bx	;^lcx:dx = owner

	call	ClipboardUnregisterItem
	ret
CLIPBOARDUNREGISTERITEM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardQueryItem

C DECLARATION:	extern void				/* ClipboardItemFlags */
			_far _pascal ClipboardQueryItem(word flags,
				ClipboardQueryArgs _far *retValue);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
ClipboardQueryArgs	struct
	CQA_numFormats	word
	CQA_owner	optr
	CQA_header	dword
ClipboardQueryArgs	ends

CLIPBOARDQUERYITEM	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx=flags, ax=seg, cx=off

	uses	es, di, bp
	.enter

	mov	es, ax			; es:di = args
	mov	di, cx
	mov	bp, bx			; bp = flags
	call	ClipboardQueryItem
	mov	es:[di].CQA_numFormats, bp
	mov	es:[di].CQA_owner.handle, cx
	mov	es:[di].CQA_owner.handle, dx
	mov	es:[di].CQA_header.high, bx	; VM file handle
	mov	es:[di].CQA_header.low, ax	; VM block handle
	.leave
	ret
CLIPBOARDQUERYITEM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardTestItemFormat

C DECLARATION:	extern Boolean
			_far _pascal ClipboardTestItemFormat(
				TransferBlockID header,
				ClipboardItemFormatID format);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDTESTITEMFORMAT	proc	far	header:dword,
					format:dword

	.enter

	mov	bx, header.high
	mov	ax, header.low
	mov	cx, format.low		; cx <- manuf
	mov	dx, format.high		; dx <- type
	call	ClipboardTestItemFormat

	mov	ax, 0			; set Boolean return value
	jc	done			; (carry -> not supported -> FALSE)
	dec	ax
done:
	.leave
	ret
CLIPBOARDTESTITEMFORMAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardEnumItemFormats

C DECLARATION:	extern word
			_far _pascal ClipboardEnumItemFormats(
				TransferBlockID header,
				word maxNumFormats,
				ClipboardItemFormatID _far *buffer);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDENUMITEMFORMATS	proc	far	header:dword,
					maxNumFormats:word,
					buffer:dword

	uses	es, di
	.enter

	mov	bx, header.high
	mov	ax, header.low
	mov	cx, maxNumFormats
	mov	es, buffer.high
	mov	di, buffer.low
	call	ClipboardEnumItemFormats		; cx = formats return
	mov_tr	ax, cx
	.leave
	ret
CLIPBOARDENUMITEMFORMATS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardGetItemInfo

C DECLARATION:	extern dword
			_far _pascal ClipboardGetItemInfo(optr owner);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDGETITEMINFO	proc	far
	C_GetOneDWordArg	bx, ax,  cx, dx	;bx = VM file, ax = VM block

	call	ClipboardGetItemInfo		; cx:dx = source ID
	mov	ax, dx
	mov	dx, cx				; dx:ax = source ID
	ret
CLIPBOARDGETITEMINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardRequestItemFormat

C DECLARATION:	extern void
			_far _pascal ClipboardRequestItemFormat(
				ClipboardItemFormatID format,
				TransferBlockID header,
				CRequestArgs _far *retValue);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CRequestArgs	struct
	CRA_file		hptr
	CRA_data		dword
	CRA_extra1	word
	CRA_extra2	word
CRequestArgs	ends

CLIPBOARDREQUESTITEMFORMAT	proc	far	format:dword,
					header:dword,
					retValue:dword

	uses	es, di
	.enter

	mov	es, retValue.high	; es:di = args
	mov	di, retValue.low
	mov	cx, format.low		; cx = manuf ID
	mov	dx, format.high		; dx = format
	mov	bx, header.high		; bx = VM file
	mov	ax, header.low		; ax = VM block
	call	ClipboardRequestItemFormat
	mov	es:[di].CRA_file, bx
	movdw	es:[di].CRA_data, axbp
	mov	es:[di].CRA_extra1, cx
	mov	es:[di].CRA_extra2, dx
	.leave
	ret
CLIPBOARDREQUESTITEMFORMAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardDoneWithItem

C DECLARATION:	extern void
			_far _pascal ClipboardDoneWithItem(
						TransferBlockID header);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDDONEWITHITEM	proc	far
	C_GetOneDWordArg	bx, ax,  cx, dx	;bx = VM file, ax = VM block

	call	ClipboardDoneWithItem
	ret
CLIPBOARDDONEWITHITEM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardGetNormalItemInfo

C DECLARATION:	extern TransferBlockID
			_far _pascal ClipboardGetNormalItemInfo();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDGETNORMALITEMINFO	proc	far
	call	ClipboardGetNormalItemInfo	; bx:ax = VM file:VM block
	mov	dx, bx				; dx:ax = VM file:VM block
	ret
CLIPBOARDGETNORMALITEMINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardGetQuickItemInfo

C DECLARATION:	extern TransferBlockID
			_far _pascal ClipboardGetQuickItemInfo();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDGETQUICKITEMINFO	proc	far
	call	ClipboardGetQuickItemInfo	; bx:ax = VM file:VM block
	mov	dx, bx				; dx:ax = VM file:VM block
	ret
CLIPBOARDGETQUICKITEMINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardGetUndoItemInfo

C DECLARATION:	extern TransferBlockID
			_far _pascal ClipboardGetUndoItemInfo();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDGETUNDOITEMINFO	proc	far
	call	ClipboardGetUndoItemInfo		; bx:ax = VM file:VM block
	mov	dx, bx				; dx:ax = VM file:VM block
	ret
CLIPBOARDGETUNDOITEMINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardGetClipboardFile

C DECLARATION:	extern VMFileHandle
			_far _pascal ClipboardGetClipboardFile();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDGETCLIPBOARDFILE	proc	far
	call	ClipboardGetClipboardFile		; bx = VM file
	mov	ax, bx				; ax = VM file
	ret
CLIPBOARDGETCLIPBOARDFILE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardAddToNotificationList

C DECLARATION:	extern void
			_far _pascal ClipboardAddToNotificationList(optr notificationOD);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDADDTONOTIFICATIONLIST	proc	far
	C_GetOneDWordArg	cx, dx,  ax, bx	;^lcx:dx = optr

	call	ClipboardAddToNotificationList
	ret
CLIPBOARDADDTONOTIFICATIONLIST	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardRemoveFromNotificationList

C DECLARATION:	extern Boolean
			_far _pascal ClipboardRemoveFromNotificationList(
						optr notificationOD);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDREMOVEFROMNOTIFICATIONLIST	proc	far
	C_GetOneDWordArg	cx, dx,  ax, bx	;^lcx:dx = optr

	call	ClipboardRemoveFromNotificationList
	mov	ax, 0			; set Boolean return value
	jc	done			; (carry set -> not found -> FALSE)
	dec	ax
done:
	ret
CLIPBOARDREMOVEFROMNOTIFICATIONLIST	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardRemoteSend

C DECLARATION:	extern Boolean
			_far _pascal ClipboardRemoteSend();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	1/93		Initial version

------------------------------------------------------------------------------@
CLIPBOARDREMOTESEND	proc	far
	clr	ax
	call	ClipboardRemoteSend
	jnc	exit
	dec	ax
exit:
	ret
CLIPBOARDREMOTESEND	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardRemoteReceive

C DECLARATION:	extern Boolean
			_far _pascal ClipboardRemoteReceive();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	1/93		Initial version

------------------------------------------------------------------------------@
CLIPBOARDREMOTERECEIVE	proc	far
	clr	ax
	call	ClipboardRemoteReceive
	jnc	exit
	dec	ax
exit:
	ret
CLIPBOARDREMOTERECEIVE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardStartQuickTransfer

C DECLARATION:	extern Boolean
			_far _pascal ClipboardStartQuickTransfer(
				ClipboardQuickTransferFlags flags,
				ClipboardQuickTransferFeedback initialCursor,
				word mouseXPos, word mouseYPos,
				ClipboardQuickTransferRegionInfo _far *regionParams,
				optr notificationOD);
			Note: "regionParams" and its fields *cannot* be
				pointing into the XIP movable code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDSTARTQUICKTRANSFER	proc	far	flags:word,
					initialCursor:word,
					mouseXPos:word, mouseYPos:word,
					regionParams:dword,
					notificationOD:dword

	uses	ds, si, es, di
	.enter
if      FULL_EXECUTE_IN_PLACE
        ;
        ; Make sure the fptr passed in is valid
        ;
EC <    pushdw  bxsi                                            >
EC <    movdw   bxsi, regionParams                                      >
EC <    call    ECAssertValidFarPointerXIP                      >
EC <    popdw   bxsi                                            >
endif

	sub	sp, size ClipboardQuickTransferRegionInfo
	tst	regionParams.high
	jz	noRegionParams
	mov	ds, regionParams.high
	mov	si, regionParams.low
	segmov	es, ss
	mov	di, sp
	mov	cx, size ClipboardQuickTransferRegionInfo
	rep movsb
noRegionParams:
	mov	si, flags
	mov	ax, initialCursor
	mov	cx, mouseXPos
	mov	dx, mouseYPos
	mov	bx, notificationOD.high
	mov	di, notificationOD.low
	call	ClipboardStartQuickTransfer
	mov	ax, 0			; set Boolean return value
	jc	done			; (carry set -> error -> FALSE)
	dec	ax
done:
	add	sp, size ClipboardQuickTransferRegionInfo
	.leave
	ret
CLIPBOARDSTARTQUICKTRANSFER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardGetQuickTransferStatus

C DECLARATION:	extern Boolean
			_far _pascal ClipboardGetQuickTransferStatus();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDGETQUICKTRANSFERSTATUS	proc	far
	call	ClipboardGetQuickTransferStatus
	mov	ax, 0			; set Boolean return value
	jz	done			; not in progress
	dec	ax			; else, in progress
done:
	ret
CLIPBOARDGETQUICKTRANSFERSTATUS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardSetQuickTransferFeedback

C DECLARATION:	extern void
			_far _pascal ClipboardSetQuickTransferFeedback(
						ClipboardQuickTransferFeedback cursor,
						word buttonFlags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDSETQUICKTRANSFERFEEDBACK	proc	far
	C_GetTwoWordArgs	ax, bx,  cx, dx	;ax = cursor, bx = flags

	push	bp
	mov	bh, bl		; We need flags in high byte
	clr	bl
	mov	bp, bx		; bp = button flags (UIFA_*) << 8
	call	ClipboardSetQuickTransferFeedback
	pop	bp
	ret
CLIPBOARDSETQUICKTRANSFERFEEDBACK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardEndQuickTransfer

C DECLARATION:	extern void
			_far _pascal ClipboardEndQuickTransfer(
						ClipboardQuickNotifyFlags flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDENDQUICKTRANSFER	proc	far
	C_GetOneWordArg	bx,  cx, dx		;bx = flags

	push	bp
	mov	bp, bx				; bp = ClipboardQuickNotifyFlags
	call	ClipboardEndQuickTransfer
	pop	bp
	ret
CLIPBOARDENDQUICKTRANSFER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardAbortQuickTransfer

C DECLARATION:	extern void
			_far _pascal ClipboardAbortQuickTransfer();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDABORTQUICKTRANSFER	proc	far
	call	ClipboardAbortQuickTransfer
	ret
CLIPBOARDABORTQUICKTRANSFER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardClearQuickTransferNotification

C DECLARATION:	extern void
			_far _pascal ClipboardClearQuickTransferNotification(
						optr notificationOD);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDCLEARQUICKTRANSFERNOTIFICATION	proc	far
	C_GetOneDWordArg	bx, dx,  ax, cx	;^lbx:dx = optr

	push	di
	mov	di, dx				; ^lbx:di = optr
	call	ClipboardClearQuickTransferNotification
	pop	di
	ret
CLIPBOARDCLEARQUICKTRANSFERNOTIFICATION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ClipboardHandleEndMoveCopy

C DECLARATION:	extern dword
			_far _pascal ClipboardHandleEndMoveCopy(word activeGrab,
						word uifa,
						Boolean checkQTInProgress);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
CLIPBOARDHANDLEENDMOVECOPY	proc	far
	C_GetThreeWordArgs	bx, dx, ax,  cx	; bx = activeGrab
						; dx = uifa
						; ax = checkQTInProgress

	mov	bp, dx			; bp = UIFunctionsActive flags
	tst	ax
	jz	haveBoolean		; carry clear if FALSE
	stc				; else, carry clear (TRUE)
haveBoolean:
	call	ClipboardHandleEndMoveCopy	; ax = MSG_META_END_MOVE_COPY or
					;	MSG_META_END_OTHER
	mov	dx, bp			; dx = UIFunctionsActive flags
	ret
CLIPBOARDHANDLEENDMOVECOPY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	UserDoDialog

C DECLARATION:	extern word
			_far _pascal UserDoDialog(optr dialogBox);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	9/91		Initial version

------------------------------------------------------------------------------@
USERDODIALOG	proc	far
	C_GetOneDWordArg	bx, ax,  cx, dx	;^lbx:ax = optr

	push	si
	mov_trash	si, ax
	call	UserDoDialog
	pop	si
	ret

USERDODIALOG	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	UserCreateDialog

C DECLARATION:	extern optr
			_far _pascal UserCreateDialog(optr dialogBox);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	9/92		Initial version

------------------------------------------------------------------------------@
USERCREATEDIALOG	proc	far
	C_GetOneDWordArg	bx, ax,  cx, dx	;^lbx:ax = optr

	push	si
	mov_trash	si, ax
	call	UserCreateDialog
	mov_trash	dx, bx
	mov_trash	ax, si
	pop	si
	ret

USERCREATEDIALOG	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	UserDestroyDialog

C DECLARATION:	extern void
			_far _pascal UserDestroyDialog(optr dialogBox);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	9/92		Initial version

------------------------------------------------------------------------------@
USERDESTROYDIALOG	proc	far
	C_GetOneDWordArg	bx, ax,  cx, dx	;^lbx:ax = optr

	push	si
	mov_trash	si, ax
	call	UserDestroyDialog
	pop	si
	ret

USERDESTROYDIALOG	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	UserDiskRestore

C DECLARATION:	extern word
			_pascal UserDiskRestore(void *savedDiskData,
					word *diskHandlePtr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/92		Initial version

------------------------------------------------------------------------------@
USERDISKRESTORE	proc	far	savedData:fptr,
				diskHandlePtr:fptr.word
	uses	ds, si
	.enter
	lds	si, ss:[savedData]		; ds:si <- data
	call	UserDiskRestore
	lds	si, ss:[diskHandlePtr]
	mov	ds:[si], ax			; store disk handle/error
	jc	done				; if error, return error code
						;  as value of function
	clr	ax				; else return 0, to signal
						;  restore ok.
done:
	.leave
	ret
USERDISKRESTORE	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	FlowAlterHierarchicalGrab

C DECLARATION:	extern Segment
    		FlowAlterHierarchicalGrab(optr objectOptr,
			     	      Message gainedMessage,
				      word offsetToMasterInstance,
				      word offsetToHierarchicalGrab,
				      optr objectToBeGivenExclusive,
				      HierarchicalFlags flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	5/8/92		Initial version

------------------------------------------------------------------------------@
FLOWALTERHIERARCHICALGRAB	proc	far	objectOptr:optr,
					gainedMessage:word,
					offsetToMasterInstance:word,
					offsetToHierarchicalGrab:word,
					objectToBeGivenExclusive:dword,
					flags:word
	uses ds, si, di
	.enter
	movdw	bxsi, objectOptr
	call	MemDerefDS
	mov	ax, gainedMessage
	mov	bx, offsetToMasterInstance
	mov	di, offsetToHierarchicalGrab
	mov	cx, objectToBeGivenExclusive.high
	mov	dx, objectToBeGivenExclusive.low

	mov	bp, flags
	call	FlowAlterHierarchicalGrab
	mov	ax, ds			; updated segment
	.leave
	ret

FLOWALTERHIERARCHICALGRAB	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FlowUpdateHierarchicalGrab

C DECLARATION:	extern Segment
    		FlowUpdateHierarchicalGrab(optr objectOptr,
			      Message gainedMessage,
			      word offsetToMasterInstance,
			      word offsetToHierarchicalGrab,
			      Message updateMessage);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	5/8/92		Initial version
	doug	8/92		Modified for API change

------------------------------------------------------------------------------@
FLOWUPDATEHIERARCHICALGRAB	proc	far	objectOptr:dword,
					gainedMessage:word,
					offsetToMasterInstance:word,
					offsetToHierarchicalGrab:word,
					updateMessage:word
	uses ds, si, di, bp
	.enter
	movdw	bxsi, objectOptr
	call	MemDerefDS		; *ds:si = instance data

	mov	ax, updateMessage
	mov	bx, offsetToMasterInstance
	mov	di, offsetToHierarchicalGrab
	mov	bp, gainedMessage

	call	FlowUpdateHierarchicalGrab
	mov	ax, ds			; updated segment
	.leave
	ret

FLOWUPDATEHIERARCHICALGRAB	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FlowDispatchSendOnOrDestroyClassedEvent

C DECLARATION:
	extern Boolean /* XXX */
    		FlowDispatchSendOnOrDestroyClassedEvent(
			    MessageReturnValues *retvals,
			    optr objectOptr,
			    Message messageToSend,
			    EventHandle classedEvent,
			    word otherData,
			    optr objectToSendTo,
			    MessageFlags flags);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	5/8/92		Initial version

------------------------------------------------------------------------------@
FLOWDISPATCHSENDONORDESTROYCLASSEDEVENT	proc	far	retvals:fptr,
						objectOptr:optr,
						messageToSend:word,
						classedEvent:word,
						otherData:word,
						objectToSendTo:optr,
						flags:word
	uses ds, si, di, es
	.enter
	movdw	bxsi, objectOptr
	call	MemDerefDS

	mov	ax, messageToSend
	mov	cx, classedEvent
	mov	dx, otherData
	mov	di, flags

	mov	bx, objectToSendTo.high
	mov	bp, objectToSendTo.low

	call	FlowDispatchSendOnOrDestroyClassedEvent
	jnc 	noDestination

	cmp	di, mask MF_CALL	; see if return values should
					; be stuffed
	jne	destinationFound

	les	di, retvals		; stuff return values
	stosw
	mov_tr	ax, bp
	stosw
	mov_tr  ax, cx
	stosw
	mov_tr	ax, dx
	stosw

destinationFound:
	mov	ax, -1
	jmp	done
noDestination:
	mov	ax, 0
done:
	.leave
	ret

FLOWDISPATCHSENDONORDESTROYCLASSEDEVENT	endp


if FULL_EXECUTE_IN_PLACE
C_User  ends
UserCStubXIP    segment resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FlowCheckKbdShortcut

  		This version of FlowCheckKbdShortcut() returns a -1 if
		the key was not found in the table, or the offset into
		the table if it was found.

C DECLARATION:	extern word
    		FlowCheckKbdShortcut(KeyboardShortcut *shortcutTable,
				     word numEntriesInTable,
				     word character,
				     word flags,
				     word state)
		Note: "shortuctTable" *can* be pointing to the movable XIP
			code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	2/20/93		Initial version

------------------------------------------------------------------------------@
FLOWCHECKKBDSHORTCUT	proc	far	shortcutTable:fptr,
					numEntriesInTable:word,
					character:word,
					flags:word,
					state:word
	uses ds, si, di, bp
	.enter

	lds	si, shortcutTable	; ds:si <- pointer to a
					; shortcut table

	mov	ax, numEntriesInTable
	mov	cx, character
	mov	dx, flags
	mov	bp, state

	call	FlowCheckKbdShortcut
	mov	ax, si			; assume the key was found
	jc	done			; jump if it was found.

	mov	ax, -1			; signal: the key was not
					; found in the table.
done:
	.leave
	ret

FLOWCHECKKBDSHORTCUT	endp

if FULL_EXECUTE_IN_PLACE
UserCStubXIP    ends
C_User  segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERREGISTERFORTEXTCONTEXT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION 	void _pascal VisTextRegisterForContext(optr obj);

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global USERREGISTERFORTEXTCONTEXT:far
USERREGISTERFORTEXTCONTEXT	proc	far
	C_GetTwoWordArgs	cx, dx,		ax, bx
	call	UserRegisterForTextContext
	ret
USERREGISTERFORTEXTCONTEXT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERUNREGISTERFORTEXTCONTEXT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION 	void _pascal VisTextRegisterForContext(optr obj);

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global USERUNREGISTERFORTEXTCONTEXT:far
USERUNREGISTERFORTEXTCONTEXT	proc	far
	C_GetTwoWordArgs	cx, dx,		ax, bx
	call	UserUnregisterForTextContext
	ret
USERUNREGISTERFORTEXTCONTEXT	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERCREATEINKDESTINATIONINFO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION: extern MemHandle _pascal UserCreateInkDestinationInfo(
		optr dest, GState gs, word brushSize, void *gestureCallback);

 		Note: "gestureCallback" must be vfptr for XIP.
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global USERCREATEINKDESTINATIONINFO:far
USERCREATEINKDESTINATIONINFO	proc	far	destOD:optr,
						gstate:hptr,
						brushSize:word,
						callback:fptr
	uses	di, bp
	.enter
	movdw	cxdx, destOD
	mov	ax, brushSize
	movdw	bxdi, callback
	mov	bp, gstate
	call	UserCreateInkDestinationInfo
	mov_tr	ax, bp			;AX <- InkDestinationInfo structure
	.leave
	ret
USERCREATEINKDESTINATIONINFO	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERGETINITFILECATEGORY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION 	void _pascal VisTextRegisterForContext(optr obj);

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global USERGETINITFILECATEGORY:far
USERGETINITFILECATEGORY	proc	far
	C_GetOneDWordArg	ax, bx,		cx, dx
	push	ds, si
	mov	ds, ax
	mov	si, bx
	call	UserGetInitFileCategory
	pop	ds, si
	ret
USERGETINITFILECATEGORY	endp


if FULL_EXECUTE_IN_PLACE
C_User  ends
UserCStubXIP    segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERLOADAPPLICATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:
	extern GeodeHandle _pascal UserLoadApplication(
			AppLaunchFlags alf,
			Message attachMethod,
			MemHandle appLaunchBlock,
			char *filename,
			StandardPath sp,
			GeodeLoadError *err);
		Note: "filename" *can* be pointing to the movable XIP
			code resource.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global USERLOADAPPLICATION:far
USERLOADAPPLICATION	proc	far		alf:word,
						attachMethod:word,
						appLaunchBlock:hptr,
						filename:fptr,
						sPath:word,
						err:fptr
	uses	bx, cx, dx, ds, si
	.enter
	mov	cx, alf
	mov	ah, cl
	mov	cx, attachMethod
	mov	dx, appLaunchBlock
	lds	si, filename
	mov	bx, sPath
	call	UserLoadApplication
	jc	error
	mov	ax, bx
exit:
	.leave
	ret
error:
	lds	si, err
	mov	ds:[si], ax
	mov	ax, -1
	jmp	exit
USERLOADAPPLICATION	endp

if FULL_EXECUTE_IN_PLACE
UserCStubXIP    ends
C_User  segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERALLOCOBJBLOCK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate an object block.

CALLED BY:	Global.

PASS:		ThreadHandle	handle	= Handle of thread to run block
					  (0 for current thread).

RETURN:		MemHandle = Handle of created object block.

DESTROYED:	BX.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Pass all of the work off on UserAllocObjBlock.

KNOWN DEFECTS/CAVEATS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.04.13	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	USERALLOCOBJBLOCK:far
USERALLOCOBJBLOCK	proc	far	threadHandle:word
	.enter

	; Make UserAllocObjBlock do all of the real work.
	mov	bx, threadHandle
	call	UserAllocObjBlock	; BX == new block handle.
	mov_trash	ax, bx		; AX = new block handle.

	.leave
	ret
USERALLOCOBJBLOCK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERENCRYPTPASSWORD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:
	extern Boolean _pascal UserEncryptPassword(const char *string,
						   char *dest);
	Note: The fptr *cannot* be pointing to the movable XIP code
		resource.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	4/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global USERENCRYPTPASSWORD:far
USERENCRYPTPASSWORD	proc	far	source:fptr.char, dest:fptr.char
					uses si, di, ds, es
	.enter

	lds	si, source
	les	di, dest
	clr	ax
	call	UserEncryptPassword
	jnc	done
	dec	ax
done:

	.leave
	ret

USERENCRYPTPASSWORD	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	UserGetRecentDocFileName()

		Open the most-recently-opened-doc file, read its content into
		memory block and return the block handle, locked address of
		the DocumentArray, and the index of first element.
		It's a circular array.

C DECLARATION:	extern void
			_far _pascal ();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	11/98		Initial version

------------------------------------------------------------------------------@
global USERGETRECENTDOCFILENAME:far
USERGETRECENTDOCFILENAME	proc	far	mh:fptr.word,
						start:fptr.word,
						buffer:fptr.char
	uses ax, cx, ds, di, es, si
	.enter
	push	bp
	call	UserGetRecentDocFileName
	mov	ax, bp
	pop	bp
	; bp = memory handle
	; es:di = memory address
	;
	lds	si, mh
	mov	ds:[si], ax		; memory block handle
	lds	si, start
	clr	ax
	mov	al, es:[di]
	mov	ds:[si], ax		; counter
	lds	si, buffer
	inc	di			; skip the first byte of counter
	movdw	ds:[si], esdi		; address of DocumentArray
	.leave
	ret
USERGETRECENTDOCFILENAME	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		USERCREATEICONTEXTMONIKER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern optr
		    _pascal UserCreateIconTextMoniker(optr textMoniker,
				      optr iconMoniker,
				      Handle destinationBlock,
				      word spacing,
				      CreateIconTextMonikerFlags flags);

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	3/12/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global USERCREATEICONTEXTMONIKER:far
USERCREATEICONTEXTMONIKER	proc	far	params:CreateIconTextMonikerParams
	ForceRef params

	; lock icon moniker lmem block, as UserCreateIconTextMoniker expects one
	mov 	cx, bp
	mov 	bp, sp
	mov 	bx, ss: [bp+4].CITMP_iconMoniker.handle
	mov 	bp, cx
	call	ObjLockObjBlock 	; *ds:si icon moniker
	mov	ds, ax

	popdw	bxcx			; copy return address from stack to bx:cx, save it there for later
	call	UserCreateIconTextMoniker
	pushdw	bxcx			; restore return address

	; unlock icon moniker lmem block
	mov	bx, ds: [LMBH_handle]
	call	MemUnlock
	ret	@ArgSize

USERCREATEICONTEXTMONIKER	endp

C_User	ends

	SetDefaultConvention
