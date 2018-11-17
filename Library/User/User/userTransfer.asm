COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userTransfer.asm

ROUTINES:
	Name			Description
	----			-----------
GLB	ClipboardRegisterItem	Register a transfer item
GLB	ClipboardUnregisterItem	restore transfer item wiped out by last
					register
GLB	ClipboardQueryItem	Query about a transfer item
GLB	ClipboardTestItemFormat	Check if transfer item supports given format
GLB	ClipboardEnumItemFormats	Return list of all formats supported
GLB	ClipboardGetItemInfo	Get additional info about transfer item
GLB	ClipboardRequestItemFormat	Request a transfer item
GLB	ClipboardDoneWithItem	done with transfer operation
GLB	ClipboardGetNormalItemInfo
GLB	ClipboardGetQuickItemInfo
GLB	ClipboardGetUndoItemInfo
GLB	ClipboardGetClipboardFile
GLB	ClipboardAddToNotificationList
GLB	ClipboardRemoveFromNotificationList
GLB	ClipboardRemoteSend
GLB	ClipboardRemoteReceive

GLB	CLIPBOARDOPENCLIPBOARDFILE	open clipboard file
GLB	CLIPBOARDCLOSECLIPBOARDFILE	close clipboard file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

DESCRIPTION:
	This file contains the routines used to do data transfer (cut and
	paste) between objects/applications.
	
	$Id: userTransfer.asm,v 1.1 97/04/07 11:46:07 newdeal Exp $

-------------------------------------------------------------------------------@

TransferCommon segment resource

TransferCommon_VMLock_DS	proc	near
	call	VMLock
	mov	ds, ax
	ret
TransferCommon_VMLock_DS	endp

TransferCommon_VMUnlock	proc	near
	call	VMUnlock
	ret
TransferCommon_VMUnlock	endp

TransferCommon_DS_DGroup	proc	near
	push	ax
	mov	ax, segment dgroup
	mov	ds, ax
	pop	ax
	ret
TransferCommon_DS_DGroup	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		{P,V}Transfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	grap/release transfer semaphore

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		semaphore grabbed or released

DESTROYED:	nothing, VTransfer preserves flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PTransfer	proc	far
	push	ds, ax, bx
	call	TransferCommon_DS_DGroup		; ds = dgroup
	PSem	ds, transferSem, TRASH_AX_BX
	pop	ds, ax, bx
	ret
PTransfer	endp

VTransfer	proc	far
	push	ds, ax, bx
	pushf						; preserve flags
	call	TransferCommon_DS_DGroup		; ds = dgroup
	VSem	ds, transferSem, TRASH_AX_BX
	popf
	pop	ds, ax, bx
	ret
VTransfer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardGetClipboardFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return clipboard file

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ClipboardGetClipboardFile
			bx = UI's transfer VM file handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	WARNING: if PC/GEOS was run from a read-only file system, then
	there is no clipboard, so this routine will return 0.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;WARNING: if PC/GEOS was run from a read-only file system, then
;there is no clipboard, so this routine will return 0. EDS 10/17/92.

ClipboardGetClipboardFile	proc	far
	push	ds
	call	TransferCommon_DS_DGroup		; ds = dgroup
	mov	bx, ds:[uiTransferVMFile]
	pop	ds
	ret
ClipboardGetClipboardFile	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ClipboardQueryItem

DESCRIPTION:	Query the given transfer item

CALLED BY:	GLOBAL

PASS:
	bp - ClipboardItemFlags (for quick/normal)

RETURN:
	bp - number of formats available (0 if no transfer item)
	cx:dx - owner of transfer item
	bx:ax - (VM file handle):(VM block handle) to transfer item header
			(pass to ClipboardRequestItemFormat)

	AFTER CALLING THIS ROUTINE, ClipboardDoneWithItem must be called.

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

ClipboardQueryItem	proc	far
	uses	ds, si
	.enter

	call	PTransfer

EC <	test	bp, mask CIF_UNUSED1 or mask CIF_UNUSED2		>
EC <	ERROR_NZ	BAD_TRANSFER_FLAGS				>

	call	TransferCommon_DS_DGroup		; ds = dgroup
	test	bp, mask CIF_QUICK
	jnz	queryQuick
	mov	bx, ds:[normalTransferItem].TII_vmFile
	mov	ax, ds:[normalTransferItem].TII_vmBlock
	tst	ax
	jz	haveItem		; no item
	inc	ds:[normalTransferItem].TII_refCount
	jmp	short haveItem
queryQuick:
	mov	bx, ds:[quickTransferItem].TII_vmFile
	mov	ax, ds:[quickTransferItem].TII_vmBlock
	tst	ax
	jz	haveItem		; no item
	inc	ds:[quickTransferItem].TII_refCount
haveItem:
	push	bx, ax			; save transfer item header
	;
	; if no transfer item then return that
	;
	mov	bp, ax			; in case no item, count = 0
	tst	ax			; check VM block handle
	jz	UQT_done		; none, done
	;
	; copy transfer items
	;
EC <	call	CheckTransferItemNoOwner ; make sure it's valid		>
	call	TransferCommon_VMLock_DS	; ds = desired transfer item

	mov	cx, ds:[CIH_owner].handle	; return cx:dx = owner
	mov	dx, ds:[CIH_owner].chunk

	push	ds:[CIH_formatCount]	; save #
	call	TransferCommon_VMUnlock
	pop	bp			; bp = # formats

UQT_done:
	pop	bx, ax			; return transfer item header

	call	VTransfer

	.leave
	ret
ClipboardQueryItem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ClipboardTestItemFormat

DESCRIPTION:	Test if transfer item supports (contains) specified format

CALLED BY:	GLOBAL

PASS:
	bx:ax = transfer item header (returned by ClipboardQueryItem)
	cx:dx - format manufacturer:format type

RETURN:
	C clear if format supported
	C set if format not supported

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/91		Initial version for 2.0 quick-transfer

------------------------------------------------------------------------------@

ClipboardTestItemFormat	proc	far
	uses	ax, bx, cx, si, ds, bp
	.enter
	call	PTransfer
	;
	; if no transfer item then return error
	;
	tst	ax
	stc				; assume no item
	jz	done
	;
	; check for format
	;
EC <	call	CheckTransferItemNoOwner ; make sure it's valid		>
	call	TransferCommon_VMLock_DS	; lock transfer header block
					; ds = transfer item
	mov	ax, cx			; ax = format manufacturer
	mov	cx, ds:[CIH_formatCount]	; cx = format count
	jcxz	notSupported
	mov	si, offset CIH_formats	; ds:si = beginning for format info
checkLoop:
	cmp	ax, ds:[si].CIFI_format.CIFID_manufacturer
	jne	checkNext
	cmp	dx, ds:[si].CIFI_format.CIFID_type
	je	haveResult		; found format! (carry clear)
checkNext:
	add	si, size ClipboardItemFormatInfo
	loop	checkLoop
notSupported:
	stc				; return "not supported"
haveResult:
	call	TransferCommon_VMUnlock	; unlock transfer block (saves flags)
done:
	call	VTransfer		; (preserves flags)
	.leave
	ret
ClipboardTestItemFormat	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardDoneWithItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To be called by transfer-mechanism users when they are
		finished using the transfer item requested.

CALLED BY:	GLOBAL

PASS:		bx:ax - transfer item header done with
				(returned by ClipboardQueryItem)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardDoneWithItem	proc	far
	uses	ax, bx, cx, dx, si, di, bp, ds, es
	.enter

	call	PTransfer

	;
	; if no transfer item then done
	;
	tst	ax
	jz	doneJMP
	;
	; find transfer item
	;
	call	TransferCommon_DS_DGroup		; ds = dgroup
	cmp	bx, ds:[normalTransferItem].TII_vmFile
	jne	checkQuick
	cmp	ax, ds:[normalTransferItem].TII_vmBlock
	jne	checkQuick
EC <	cmp	ds:[normalTransferItem].TII_refCount, 0			>
EC <	ERROR_Z	TRANSFER_ITEM_DONE_REF_COUNT_IS_ZERO			>
	dec	ds:[normalTransferItem].TII_refCount
doneJMP:
	jmp	done

checkQuick:
	cmp	bx, ds:[quickTransferItem].TII_vmFile
	jne	checkUndo
	cmp	ax, ds:[quickTransferItem].TII_vmBlock
	jne	checkUndo
EC <	cmp	ds:[quickTransferItem].TII_refCount, 0			>
EC <	ERROR_Z	TRANSFER_ITEM_DONE_REF_COUNT_IS_ZERO			>
	dec	ds:[quickTransferItem].TII_refCount
	jmp	done

checkUndo:
	cmp	bx, ds:[undoTransferItem].TII_vmFile
	jne	checkFreeList
	cmp	ax, ds:[undoTransferItem].TII_vmBlock
	jne	checkFreeList
EC <	cmp	ds:[undoTransferItem].TII_refCount, 0			>
EC <	ERROR_Z	TRANSFER_ITEM_DONE_REF_COUNT_IS_ZERO			>
	dec	ds:[undoTransferItem].TII_refCount
	jmp	done

checkFreeList:
	mov	di, ds:[transferFreeListBufSize]
	push	bx, ax
	mov	bx, ds:[transferFreeListBuffer]
	call	MemLock
	mov	es, ax				; es:si = free list buffer
	clr	si
	pop	bx, ax
checkLoop:
	cmp	bx, es:[si].TII_vmFile
	jne	checkNext
	cmp	ax, es:[si].TII_vmBlock
	je	foundInFreeList
checkNext:
	add	si, size TransferItemInstance
	cmp	di, si				; end of free list
	jne	checkLoop
EC <	ERROR	TRANSFER_ITEM_DONE_NOT_FOUND				>

foundInFreeList:
	dec	es:[si].TII_refCount
	mov	dx, es:[si].TII_refCount	; dx = new ref. count
	tst	dx
	jnz	doneFreeList			; other references exists,
						;	don't delete
	mov	es:[si].TII_vmBlock, 0		; remove entry from free list
	call	FreeTransfer			; free item and notify
doneFreeList:
	mov	bx, ds:[transferFreeListBuffer]	; unlock transfer free list
	call	MemUnlock
done:

	call	VTransfer

	.leave
	ret
ClipboardDoneWithItem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ClipboardRegisterItem

DESCRIPTION:	Register the given transfer item

CALLED BY:	GLOBAL

PASS:
	ax - handle of VM block containing ClipboardItemHeader structure
	     or 0 to null the transfer item
	bx - VM file handle of VM file containing transfer item
		to be registered
	bp - ClipboardItemFlags (CIF_QUICK)

RETURN:
	if normal transfer item (not quick):
		carry clear if no error
		carry set if error (will be disk full error)

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

ClipboardRegisterItem	proc	far
	uses	ax, bx, cx, dx, ds, si, di
	.enter

EC <	tst	ax							>
EC <	jz	5$							>
EC <	call	ECCheckFileHandle					>
EC <5$:									>

	call	PTransfer

	call	FileBatchChangeNotifications

	tst	ax
	jnz	notClearing
	call	ClipboardGetClipboardFile	; transfer file handle => BX
notClearing:
	mov	di, bx				; transfer VM file => DI
	
	; test for bad parameters

EC <	test	bp,mask CIF_UNUSED1 or mask CIF_UNUSED2			>
EC <	ERROR_NZ	BAD_TRANSFER_FLAGS				>
EC <	tst	ax							>
EC <	jz	transferOK						>
EC <	call	CheckTransferItem					>
EC <transferOK:								>
	;
	; update clipboard file now that we have valid transfer item
	;
	tst	ax				; unless we're just clearing
	jz	noVMErr				;	the current clipboard
	test	bp, mask CIF_QUICK		; or unless we're register a
	jnz	noVMErr				;  quick-transfer item
						;  (it doesn't need to
						;   persist across shutdown)

	push	ax				; save VM block

	
	call	VMUpdate			; carry set if error
	
notEnoughSpace::
	pop	ax				; restore VM block
	jnc	noVMErr

	;
	; error updating file, do not register this item
	; as a matter of fact, free it.  For quick transfers this could cause
	; some odd behavior (destination doesn't accept stuff copied/moved from
	; source) but no death...
	;
	call	FreeTransfer			; free it!
	stc					; indicate error
	jmp	done				; that's all...

noVMErr:
	;
	; register correct transfer data
	;
	call	TransferCommon_DS_DGroup		; ds = dgroup
	test	bp, mask CIF_QUICK
	jnz	quick
	;
	; register normal transfer item
	;
	push	ax				; save new normal transfer
						;	item's VM block handle
EC <	tst	ax				; any thing there?	>
EC <	jz	35$				; nope, skip this check	>
EC <	cmp	di, ds:[normalTransferItem].TII_vmFile			>
EC <	jnz	35$							>
EC <	cmp	ax, ds:[normalTransferItem].TII_vmBlock			>
EC <	jnz	35$							>
EC <	ERROR	TRANSFER_ITEM_IS_ALREADY_ACTIVE				>
EC <35$:								>

;
; Don't bother saving to undoTransferItem.  ClipboardUnregisterItem,
; ClipboardGetUndoInfo effectively do nothing as undoTransferItem is
; always 0 - brianc 6/22/93
;
if 0	;--------------------------------------------------------------

	mov	ax, ds:[undoTransferItem].TII_vmBlock
	tst	ax				; ax = old undo item VM block
	jz	noOldUndo
	mov	bx, ds:[undoTransferItem].TII_vmFile	; bx:ax = old undo item
	mov	cx, ds:[undoTransferItem].TII_refCount	; any refs?
	jcxz	noRefsToUndo			; no, go ahead and free it
	call	StoreInFreeList			; else, store in free list
	jmp	short noOldUndo
noRefsToUndo:
	call	FreeTransfer			; free old undo item
noOldUndo:
	;
	; move old normal transfer item to undo item
	;
	mov	ax, ds:[normalTransferItem].TII_vmFile
	mov	ds:[undoTransferItem].TII_vmFile, ax
	mov	ax, ds:[normalTransferItem].TII_vmBlock
	mov	ds:[undoTransferItem].TII_vmBlock, ax
	mov	ax, ds:[normalTransferItem].TII_refCount
	mov	ds:[undoTransferItem].TII_refCount, ax

else	;--------------------------------------------------------------

	mov	ax, ds:[normalTransferItem].TII_vmBlock
	tst	ax				; ax = previous item VM block
	jz	noPreviousItem
	mov	bx, ds:[normalTransferItem].TII_vmFile	; bx:ax = previous item
	mov	cx, ds:[normalTransferItem].TII_refCount	; any refs?
	jcxz	noRefsToUndo			; no, go ahead and free it
	call	StoreInFreeList			; else, store in free list
	jmp	short noPreviousItem
noRefsToUndo:
	call	FreeTransfer			; free previous item
noPreviousItem:

endif	;--------------------------------------------------------------

	;
	; save new normal transfer item
	;
	mov	ds:[normalTransferItem].TII_vmFile, di
	pop	ds:[normalTransferItem].TII_vmBlock
	mov	ds:[normalTransferItem].TII_refCount, 0
	;
	; notify interested parties of the change
	;
	clr	cx
	clr	dx
	mov	ax, MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	call	SendToNotificationList
	jmp	short doneNoError		; indicate no error
	;
	; register quick transfer item
	;
quick:
EC <	tst	ax				; any thing there?	>
EC <	jz	55$				; nope, skip this check	>
EC <	cmp	di, ds:[quickTransferItem].TII_vmFile			>
EC <	jnz	55$							>
EC <	cmp	ax, ds:[quickTransferItem].TII_vmBlock			>
EC <	jnz	55$							>
EC <	ERROR	TRANSFER_ITEM_IS_ALREADY_ACTIVE				>
EC <55$:								>
	push	ax				; save new quick transfer
						;	item's VM block
	mov	ax, ds:[quickTransferItem].TII_vmBlock
	tst	ax				; ax = old quick transfer
	jz	noOldQuick
	mov	bx, ds:[quickTransferItem].TII_vmFile	; bx:ax = old quick item
	mov	cx, ds:[quickTransferItem].TII_refCount	; any refs?
	jcxz	noRefsToQuick

	call	StoreInFreeList			; else, store in free list
	jmp	short noOldQuick
noRefsToQuick:
	call	FreeTransfer			; free old quick transfer
noOldQuick:
	;
	; save new quick transfer item
	;
	mov	ds:[quickTransferItem].TII_vmFile, di
	pop	ds:[quickTransferItem].TII_vmBlock
	mov	ds:[quickTransferItem].TII_refCount, 0

doneNoError:
	clc					; indicate no error
done:

	call	FileFlushChangeNotifications	; preserves flags

	call	VTransfer			; preserves flags

	.leave
	ret
ClipboardRegisterItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareDiskSpaceWithFileDirtySize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	cmp	currentDiskSpace,
				(fileDirtySpace
				+MIN_DISK_SPACE_AFTER_CLIPBOARD_REGISTER)

CALLED BY:	INTERNAL
PASS:		bx	= file handle
RETURN:		flags changed according to "cmp"
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		To get available disk space:
			DiskGetVolumeFreeSpace(FileGetDiskHandle(fileHandle))

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardAddToNotificationList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add OD to transfer notify list

CALLED BY:	GLOBAL

PASS:		cx:dx - OD to add
		if cx is process handle dx MUST be 0

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardAddToNotificationList	proc	far
	uses	ax, bx, si, di
	.enter

EC <	xchgdw	bxsi, cxdx						>
EC <	tst	si							>
EC <	jz	testProcessHandle					>
EC <	call	ECCheckLMemOD						>
EC <	jmp	afterEC							>
EC <testProcessHandle:							>
EC <	call	ECCheckProcessHandle					>
EC <afterEC:								>
EC <	xchgdw	bxsi, cxdx						>

	;
	; add OD to GCNSLT_TRANSFER_NOTIFICATION system GCN list
	;
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSFER_NOTIFICATION
	call	GCNListAdd

	;
	; send an initial notification so that initial state of edit buttons
	; can be correct
	;
	mov	bx, cx				; bx:si = OD to notify
	mov	si, dx
	mov	ax, MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
ClipboardAddToNotificationList	endp


TransferCommon ends

;---

Transfer segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreInFreeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store transfer item in free list since there are still
		references to it

CALLED BY:	INTERNAL
			ClipboardRegisterItem

PASS:		bx:ax = (VM file handle):(VM block handle) of transfer item
		cx = reference count of item
		transfer semaphore down

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreInFreeList	proc	far
	uses	ax, bx, cx, dx, si, di, ds, es
	.enter
	call	Transfer_DS_DGroup		; ds = dgroup

	mov	di, ds:[transferFreeListBufSize]

	push	bx, ax
	mov	bx, ds:[transferFreeListBuffer]
	call	MemLock
	mov	es, ax				; es:si = free list buffer
	clr	si
	pop	bx, ax

EC <	push	si							>
EC <ecCheckLoop:							>
EC <	cmp	bx, es:[si].TII_vmFile					>
EC <	jne	ecCheckNext						>
EC <	cmp	ax, es:[si].TII_vmBlock					>
EC <	ERROR_Z	TRANSFER_ITEM_ALREADY_IN_FREE_LIST			>
EC <ecCheckNext:							>
EC <	add	si, size TransferItemInstance				>
EC <	cmp	di, si				; end of free list?	>
EC <	jne	ecCheckLoop						>
EC <	pop	si							>

freeLoop:
	cmp	es:[si].TII_vmBlock, 0		; is this entry free?
	je	foundFree			; yes
	add	si, size TransferItemInstance	; else, try next entry
	cmp	di, si				; end of free list?
	jne	freeLoop
	;
	; need to expand free list buffer
	;
	push	ax, bx, cx			; save item info
	mov	bx, ds:[transferFreeListBuffer]
	mov	ax, ds:[transferFreeListBufSize]	; current size
	push	ax				; save it
						; increase buffer size
	add	ax, (INC_TRANSFER_FREE_LIST_COUNT * size TransferItemInstance)
	mov	ds:[transferFreeListBufSize], ax	; save new size
	mov	ch, mask HAF_ZERO_INIT or mask HAF_NO_ERR ; no errors, please
	call	MemReAlloc
	mov	es, ax				; might have moved
	pop	si				; es:di = new entry
	pop	ax, bx, cx			; retrieve item info

foundFree:
	mov	es:[si].TII_vmFile, bx		; else, save item here
	mov	es:[si].TII_vmBlock, ax
	mov	es:[si].TII_refCount, cx

	mov	bx, ds:[transferFreeListBuffer]	; unlock transfer free list
	call	MemUnlock
	.leave
	ret
StoreInFreeList	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FreeTransfer

DESCRIPTION:	Free a transfer item

CALLED BY:	ClipboardRegisterItem

PASS:
	bx - VM file handle of item to free
	ax - VM block handle of item to free
	transfer semaphore down

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

FreeTransfer	proc	far
	uses	ax, bx, cx, dx, ds, bp
	.enter

	push	bx, ax			; save transfer item free

	call	FreeTransferLow

	;
	; notify interested parties
	;
	pop	cx, dx			; cx:dx = transfer item
	mov	ax, MSG_META_CLIPBOARD_NOTIFY_TRANSFER_ITEM_FREED
	call	SendToNotificationList

	.leave
	ret
FreeTransfer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardFreeItemsNotInUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees normal or quick transfer item if nobody's using it, 
		nukes references to it, sends proper GCN messages out.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	NOTE: The user should *not* have called ClipboardRegisterItem
	      with this transfer item, as this routine just frees the
	      data without updating any references in the map block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	1/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardFreeItemsNotInUse	proc	far	

	uses ax,bx,ds
	.enter

	call	PTransfer
	;
	; Clear out references to the item, as per Brianc's instructions,
	; unless there are references to the clipboard item.
	;
	call	Transfer_DS_DGroup		; ds = dgroup
	tst	ds:[normalTransferItem].TII_refCount	
	jnz	10$
	clrdw	bxax
	xchg	bx, ds:[normalTransferItem].TII_vmFile
	xchg	ax, ds:[normalTransferItem].TII_vmBlock
	tst	ax
	jz	10$
	call	FreeTransfer
10$:
	call	Transfer_DS_DGroup		; ds = dgroup
	tst	ds:[quickTransferItem].TII_refCount	
	jnz	20$
	clrdw	bxax
	xchg	bx, ds:[quickTransferItem].TII_vmFile
	xchg	ax, ds:[quickTransferItem].TII_vmBlock
	tst	ax
	jz	20$	
	call	FreeTransfer
20$:
	call	Transfer_DS_DGroup		; ds = dgroup
	tst	ds:[undoTransferItem].TII_refCount	
	jnz	30$
	clrdw	bxax
	xchg	bx, ds:[undoTransferItem].TII_vmFile
	xchg	ax, ds:[undoTransferItem].TII_vmBlock
	tst	ax
	jz	30$	
	call	FreeTransfer
30$:
	call	VTransfer
	.leave	
	ret

ClipboardFreeItemsNotInUse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardFreeItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the passed transfer item.

CALLED BY:	GLOBAL
PASS:		bx - VM file handle of item to free
		ax - VM block handle of item to free
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	NOTE: The user should *not* have called ClipboardRegisterItem
	      with this transfer item, as this routine just frees the
	      data without updating any references in the map block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardFreeItem	proc	far
	.enter

	call	FreeTransferLow	

	.leave	
	ret
ClipboardFreeItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeTransferLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	free transfer item

CALLED BY:	INTERNAL
			FreeTransfer
			CLIPBOARDCLOSECLIPBOARDFILE

PASS:		ax - VM block handle of transfer item to free
		bx - VM file handle
		working with file owning AX
		transfer semaphore down

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/19/90	broken out to fix bug in CLIPBOARDCLOSECLIPBOARDFILE

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeTransferLow	proc	near
	uses	ax, cx, ds, si, di, bp
	.enter
	push	ax			; save passed VM block
EC <	call	CheckTransferItemNoOwner ; make sure it's valid		>
	call	Transfer_VMLock_DS	; bp = mem handle
					; ds = transfer item
	mov	si, offset CIH_formats	; ds:si = start of ClipboardItemFormatInfo
	mov	cx, ds:[CIH_formatCount]
	push	bp
FT_loop:
	movdw	axbp, ds:[si].CIFI_vmChain; ax.bp = trnsfr data block chain 
	call	VMFreeVMChain
	add	si, size ClipboardItemFormatInfo	; move to next format
	loop	FT_loop
	pop	bp

	call	Transfer_VMUnlock
	pop	ax			; ax = transfer header block
	call	VMFree			; free it

	
	call	VMUpdate		; update on disk (hopefully truncate
					;	as small as possible)
					; ignore error
skipUpdate::
	.leave
	ret
FreeTransferLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardUnregisterItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restore transfer clobbered by last normal transfer item
		registered

CALLED BY:	GLOBAL

PASS:		cx:dx - owner OD used when register last item

RETURN:		nothing done if cx:dx doesn't own current transfer item
			OR if no normal transfer item

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/07/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardUnregisterItem	proc	far
	uses	ax, bx, cx, dx, bp, ds
	.enter

	call	PTransfer

	call	Transfer_DS_DGroup		; ds = dgroup
	mov	bx,ds:[normalTransferItem].TII_vmFile	; bx:ax = normal item
	mov	ax,ds:[normalTransferItem].TII_vmBlock
	tst	ax				; no normal item
	jz	done

EC <	call	CheckTransferItemNoOwner	; make sure it's valid	>
	call	Transfer_VMLock_DS		; lock normal transfer item
						; ds=ax=segment, bp=mem handle
	;
	; make sure caller was the one who register the
	; current normal transfer item
	;
	cmp	cx, ds:[CIH_owner].handle
	jne	wrongOwner			; if not, do nothing
	cmp	dx, ds:[CIH_owner].chunk
	jne	wrongOwner			; if not, do nothing
	;
	; swap undo and normal transfer items
	;
	call	Transfer_DS_DGroup		; ds = dgroup
	mov	ax, ds:[normalTransferItem].TII_vmFile
	xchg	ax, ds:[undoTransferItem].TII_vmFile
	mov	ds:[normalTransferItem].TII_vmFile, ax
	mov	ax, ds:[normalTransferItem].TII_vmBlock
	xchg	ax, ds:[undoTransferItem].TII_vmBlock
	mov	ds:[normalTransferItem].TII_vmBlock, ax
	;
	; notify interested parties of the change
	;
	clr	cx
	clr	dx
	mov	ax, MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	call	SendToNotificationList
wrongOwner:
	call	Transfer_VMUnlock
done:
	call	VTransfer

	.leave
	ret
ClipboardUnregisterItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardEnumItemFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns list of all available formats (ClipboardItemFormatID
		structures)

CALLED BY:	GLOBAL

PASS:		bx:ax = transfer item header (returned by ClipboardQueryItem)
		cx - maximum number of formats to return
		es:di - buffer for formats (should be at least
				(cx * size ClipboardItemFormatID) bytes)

RETURN:		cx - number of formats returned
		buffer filled with cx ClipboardItemFormatID structures

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardEnumItemFormats	proc	far
	uses	ax, bx, dx, si, di, ds, bp
	.enter
	call	PTransfer
	;
	; if no transfer item then return error
	;
	tst	ax
	mov	dx, ax				; assume no item
	jz	done
	;
	; return formats
	;
EC <	call	CheckTransferItemNoOwner ; make sure it's valid		>
	call	Transfer_VMLock_DS	; lock transfer header block
					; ds = transfer item
	mov	ax, ds:[CIH_formatCount]	; ax = format count
	cmp	ax, cx			; less than requested?
	jae	haveCount		; no, use requested #
	mov	cx, ax			; else, use actual format count
haveCount:
	mov	dx, cx			; save count for return

	mov	si, offset CIH_formats	; ds:si = beginning of format info
copyLoop:
	mov	ax, ds:[si].CIFI_format.CIFID_manufacturer
CheckHack <offset CIFID_manufacturer eq 0>
	stosw				; copy over format manufacturer
	mov	ax, ds:[si].CIFI_format.CIFID_type
CheckHack <offset CIFID_type eq 2>
	stosw				; copy over format type
	add	si, size ClipboardItemFormatInfo
CheckHack <size ClipboardItemFormatID eq 4>
	loop	copyLoop
	call	Transfer_VMUnlock	; unlock transfer block (saves flags)
done:
	mov	cx, dx			; return count in cx
	call	VTransfer
	.leave
	ret
ClipboardEnumItemFormats	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ClipboardRequestItemFormat

DESCRIPTION:	Request the given transfer item

CALLED BY:	GLOBAL

PASS:
	cx:dx - format manufacturer:format type
	bx:ax = transfer item header (returned by ClipboardQueryItem)

RETURN:
	bx - file handle of transfer item
	ax:bp - VM chain (0 if none)
	cx - extra data word 1
	dx - extra data word 2

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

ClipboardRequestItemFormat	proc	far
	uses	si, ds, di
	.enter

	clr	bp
	call	PTransfer

	;
	; if no transfer item then return that
	;
	tst	ax
	jz	done
	;
	; find transfer item
	;
EC <	call	CheckTransferItemNoOwner ; make sure it's valid		>
	call	Transfer_VMLock_DS	; lock transfer header block
					; ds = transfer item
;no RAW for 2.0
;EC <	test	ds:[CIH_flags], mask TIF_RAW				>
;EC <	ERROR_NZ	BAD_TRANSFER_FLAGS				>
	mov	si, offset CIH_formats	; ds:si = ClipboardItemFormatInfo array
	mov	ax, cx			; ax = format manufacturer
	mov	cx, ds:[CIH_formatCount]	; cx = format count
	jcxz	notFound
findLoop:
	cmp	ax, ds:[si].CIFI_format.CIFID_manufacturer	; check format
	jne	checkNext
	cmp	dx, ds:[si].CIFI_format.CIFID_type
	je	found
checkNext:
	add	si, size ClipboardItemFormatInfo	; move to next format
	loop	findLoop
notFound:
	clrdw	axdi			; indicate not found
	jmp	short afterFind

found:
	movdw	axdi, ds:[si].CIFI_vmChain ; return VM block handle
	mov	cx, ds:[si].CIFI_extra1	; return extra words
	mov	dx, ds:[si].CIFI_extra2

afterFind:
	call	Transfer_VMUnlock	; unlock transfer block
	mov	bp, di
done:
	call	VTransfer

	.leave
	ret
ClipboardRequestItemFormat	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ClipboardGetItemInfo

DESCRIPTION:	Get  more info about the given transfer item

CALLED BY:	GLOBAL

PASS:
	bx:ax = transfer item header (returned by ClipboardQueryItem)

RETURN:
	^lcx:dx = sourceID field from transfer item header

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/91		Initial version for 2.0 quick-transfer

------------------------------------------------------------------------------@

ClipboardGetItemInfo	proc	far
	uses	ax, bx, si, di, es, bp
	.enter
	call	PTransfer
	;
	; if no transfer item then return that
	;
	tst	ax
	jz	done
	;
	; find transfer item
	;
EC <	call	CheckTransferItemNoOwner ; make sure it's valid		>
	call	Transfer_VMLock_ES	; lock transfer header block
					; es = transfer item
	mov	cx, es:[CIH_sourceID].handle	; return source ID
	mov	dx, es:[CIH_sourceID].chunk
	call	Transfer_VMUnlock	; unlock transfer block
done:
	call	VTransfer
	.leave
	ret
ClipboardGetItemInfo	endp

if	ERROR_CHECK


COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckTransferItem (EC only)

DESCRIPTION:	Check to make sure that a transfer item is legal

CALLED BY:	GLOBAL

PASS:
	ax - transfer item VM block handle
	bx - transfer item VM file handle
	transfer semaphore down

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

CheckTransferItem	proc	far
	uses	dx
	.enter
	mov	dx, 0			; check owner
	call	CheckItemLow
	.leave
	ret
CheckTransferItem	endp

CheckTransferItemNoOwner	proc	far
	uses	dx
	.enter
	mov	dx, -1			; don't check owner
	call	CheckItemLow
	.leave
	ret
CheckTransferItemNoOwner	endp

;
; pass:
;	dx  = 0 to check owner
;	dx != 0 to not check owner
;
CheckItemLow	proc	near
	uses	ax, bx, cx, si, ds, bp
	.enter
	pushf

	mov	cx, ax			; cx = VM block handle
	call	Transfer_VMLock_DS	; ax = segment, bp = mem handle
					; ds = transfer item
	push	bx			; save the VM file handle

	;
	; make sure it is the right size
	;
	mov	bx, bp			; bx = mem handle
	mov	ax, MGIT_SIZE
	call	MemGetInfo		; ax = header block size in bytes
	cmp	ax, size ClipboardItemHeader	; big enough?
	ERROR_C	BAD_TRANSFER_HEADER_SIZE	; too small!

	test	ds:[CIH_flags], mask CIF_UNUSED1 or mask CIF_UNUSED2
	ERROR_NZ	BAD_TRANSFER_FLAGS

	tst	dx			; no owner check?
	jnz	noOwner
	mov	bx, ds:[CIH_owner].handle
	tst	bx
	jz	noOwner
	call	ECCheckMemHandle
noOwner:

	pop	bx			; restore the VM file handle
	mov	cx, ds:[CIH_formatCount]
	cmp 	cx, CLIPBOARD_MAX_FORMATS
	ERROR_A	BAD_TRANSFER_FORMAT_COUNT
	tst	cx
	ERROR_Z	BAD_TRANSFER_FORMAT_COUNT
	;
	; cannot check format identifiers as anything goes
	;
;no RAW for 2.0
;	test	ds:[CIH_flags], mask TIF_RAW
;	jnz	CTI_checkRaw
	;
	; type is finished
	;
	mov	si, offset CIH_formats
CTI_loop:
	;
	; ensure VM block handle of data format is valid
	;
	push	di
	movdw	axdi, ds:[si].CIFI_vmChain
	tst	di
	jnz	isDBItem
	push	bp
	call	Transfer_VMLock		; will do some error-checking for us
	call	Transfer_VMUnlock
	pop	bp
	jmp	common
isDBItem:
	push	es
	call	DBLock
	call	DBUnlock
	pop	es
common:
	pop	di
	add	si, size ClipboardItemFormatInfo
	loop	CTI_loop
;no RAW for 2.0
;	jmp	CTI_common
;
;CTI_checkRaw:
;	mov	bx, ds:[TIR_OD].handle
;	call	ECCheckMemHandle
;
;CTI_common:

	call	Transfer_VMUnlock

	popf
	.leave
	ret
CheckItemLow	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardGetNormalTransferInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return normal transfer item info

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ClipboardGetNormalTransferInfo
			bx = transfer VM file handle
			ax = tranfer VM block handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardGetNormalItemInfo	proc	far
	push	si
	mov	si, offset normalTransferItem
	call	GetTransferInfoCommon
	pop	si
	ret
ClipboardGetNormalItemInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardGetQuickTransferInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return quick transfer item info

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ClipboardGetQuickTransferInfo
			bx = transfer VM file handle
			ax = tranfer VM block handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardGetQuickItemInfo	proc	far
	push	si
	mov	si, offset quickTransferItem
	call	GetTransferInfoCommon
	pop	si
	ret
ClipboardGetQuickItemInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardGetUndoTransferInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return undo transfer item info

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ClipboardGetUndoTransferInfo
			bx = transfer VM file handle
			ax = tranfer VM block handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardGetUndoItemInfo	proc	far
	push	si
	mov	si, offset undoTransferItem
	call	GetTransferInfoCommon
	pop	si
	ret
ClipboardGetUndoItemInfo	endp

GetTransferInfoCommon	proc	near
	call	PTransfer
	push	ds
	call	Transfer_DS_DGroup		; ds = dgroup
	mov	bx, ds:[si].TII_vmFile
	mov	ax, ds:[si].TII_vmBlock
	pop	ds
	call	VTransfer
	ret
GetTransferInfoCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardRemoveFromNotificationList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	remove OD to transfer notify list

CALLED BY:	GLOBAL

PASS:		cx:dx - OD to remove
		if cx is process handle dx MUST be 0

RETURN:		carry clear if successfully removed
		carry set if not found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardRemoveFromNotificationList	proc	far
	uses	ax, bx, si
	.enter

EC <	xchgdw	bxsi, cxdx						>
EC <	tst	si							>
EC <	jz	testProcessHandle					>
EC <	call	ECCheckLMemOD						>
EC <	jmp	afterEC							>
EC <testProcessHandle:							>
EC <	call	ECCheckProcessHandle					>
EC <afterEC:								>
EC <	xchgdw	bxsi, cxdx						>

	;
	; remove OD from GCNSLT_TRANSFER_NOTIFICATION system GCN list
	;
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSFER_NOTIFICATION
	call	GCNListRemove			; carry SET if removed
	cmc					; return carry CLEAR if removed

	.leave
	ret
ClipboardRemoveFromNotificationList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToNotificationList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send method to all ODs in transfer notification list

CALLED BY:	INTERNAL

PASS:		ax - method to send
		cx, dx, bp - data to send
		transfer semaphore down

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToNotificationList	proc	far
	uses	ax, bx, cx, dx, si, di, bp
	.enter

	;
	; send to GCNSLT_TRANSFER_NOTIFICATION system GCN list
	;
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	si, GCNSLT_TRANSFER_NOTIFICATION
	;
	; must FORCE_QUEUE as we don't want notification to be handled
	; synchronously as the notification handler is likely to call
	; clipboard routines, routines which grab the transferSem, which
	; we may have grabbed ourselves
	;
	mov	di, mask GCNLSF_FORCE_QUEUE	; GCNListSendFlags
	call	GCNListRecordAndSend

	.leave
	ret
SendToNotificationList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CLIPBOARDOPENCLIPBOARDFILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open/create clipboard file, truncating if told to

CALLED BY:	GLOBAL

PASS:		cx = IC_NO to truncate clipboard
			anything else to reopen or create it

RETURN:		carry clear if successful:
			ax	= 0
		carry set if error:
			ax	= VMStatus error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/01/90	Initial version
	jenny	4/15/93		Made UserOpenTransferFile global, changed name

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CLIPBOARDOPENCLIPBOARDFILE	proc	far
	uses	bx, cx, dx, bp, es, di, ds
	.enter

	call	PTransfer
	call	Transfer_DS_DGroup		;ds = dgroup

	call	FilePushDir
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath

	mov	ah, VMO_CREATE			;Assume !IC_NO, so want to
						; open existing file, or
						; create new one
	cmp	cx, IC_NO
	jne	openClipboard			;not IC_NO, open existing

truncateClipboard:
	;If we crashed, or the file is invalid, truncate the clipboard.
	mov	ah, VMO_CREATE_TRUNCATE
	
openClipboard:
	mov	al, mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	push	ax
	mov	ds:[normalTransferItem].TII_vmBlock, 0	; just in case
	mov	ds:[normalTransferItem].TII_vmFile, 0
	mov	bx, handle transferItemFilename
	call	MemLock		;Lock the strings resource
	mov	ds, ax				;
	pop	ax
assume ds:Strings
	mov	dx, ds:[transferItemFilename]	;DS:DX <- file longname
assume ds:dgroup
	clr	cx				; default compression threshold
	call	VMOpen				;Open the clipboard file

	;unlock the strings resource (whether we got an error back or not)

	push	bx				;Save the file handle
	mov	bx, handle transferItemFilename	;
	call	MemUnlock			;Unlock the strings resource
	pop	bx
	call	Transfer_DS_DGroup		; ds = dgroup
	jnc	openDone			;skip if no error...
;-----
	;there was an error opening the file

	clr	bx				;VM file handle = null
	mov	ds:[uiTransferVMFile], bx	;save VM file handle

	cmp	ax, VM_SHARING_DENIED
	je	clipboardGood			;if was a read-only file, then
						;skip to end with BX=0...

	cmp	ax, VM_FILE_FORMAT_MISMATCH
	je	truncateClipboard		;file format outdated?
						; yes -- try again and truncate
						;  the file
;-----
	cmp	ax, VM_OPEN_INVALID_VM_FILE	;bad VM file?
	je	truncateClipboard		; yes -- try again and truncate
						; the file
	stc
	jmp	done				; otherwise, return error

openDone:
if 0
;
;	We *really* want this to be asynchronous update - we don't care if
;	the clipboard file gets trashed in a crash, as it is deleted when we
;	start up after a crash...
;
	mov	ax, mask VMA_SYNC_UPDATE
	call	VMSetAttributes			; use synchronous update
endif
	mov	ds:[uiTransferVMFile], bx	; save VM file handle

	call	VMGetMapBlock			; ax = map block
	tst	ax				; any map block?
	jnz	haveMapBlock			; yes, use it
	;
	; create new map block
	;
	mov	cx, size TransferFileHeader
	call	VMAlloc
	call	VMSetMapBlock
	call	Transfer_VMLock_ES
	mov	es:[TFH_normalItem], 0
	clc					; indicate success
	jmp	short checkDone			; go unlock the new block

haveMapBlock:
	call	SaveAndVMInfoAndRestore
	jc	afterMapBlock			; branch with error
	call	Transfer_VMLock_ES		; ax = segment, bp = mem handle
						; es = TransferFileHeader

	mov	ds:[normalTransferItem].TII_vmFile, bx
	mov	ax, es:[TFH_normalItem]		; save normal transfer item
	mov	ds:[normalTransferItem].TII_vmBlock, ax
	tst	ax
	jz	noItem				; (carry clear)
	call	ValidateTransferItem
	jc	checkDone				; branch if error
noItem:
	mov	ax, ds:[normalTransferItem].TII_vmBlock
checkDone:
	call	Transfer_VMUnlock		; unlock map block
afterMapBlock:
	jnc	clipboardGood			; clipboard file is valid
	;
	; bad transfer item, delete clipboard
	;
	mov	al, FILE_NO_ERRORS
	call	VMClose				; close it before deleting
	jmp	truncateClipboard

clipboardGood:
	;
	; Make sure that the file is owned by the ui, and that the VMHandle
	; is run by the UI thread -- this will prevent death
	; if the thread who called us exits without closing the clipboard first.
	;	dloft & eds 4/21/93
	;

	mov	bx, ds:[uiTransferVMFile]	;bx = HandleFile for VM file
	mov	ax, handle 0
	call	HandleModifyOwner

	mov	ax, ds:[uiThread]
	call	VMSetExecThread

	;
	; create transfer free list buffer
	;
	mov	ax, INIT_TRANSFER_FREE_LIST_COUNT * size TransferItemInstance
	mov	ds:[transferFreeListBufSize], ax	; save size
	mov	cx, ALLOC_DYNAMIC_NO_ERR or \
			mask HAF_ZERO_INIT shl 8 or mask HF_SHARABLE
	mov	bx, handle 0		
	call	MemAllocSetOwner

	mov	ds:[transferFreeListBuffer], bx	; save handle

	clr	ax				; indicate no error
						;  (clears carry too)
done:
	call	FilePopDir

	call	VTransfer

	.leave
	ret
CLIPBOARDOPENCLIPBOARDFILE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValidateTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make sure transfer item recovered from clipboard file
		is valid

CALLED BY:	CLIPBOARDOPENCLIPBOARDFILE

PASS:		ax - transfer item VM block handle
		bx - transfer item VM file handle
		transfer semaphore down

RETURN:		carry set if invalid

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		could also go into text transfer item gstrings

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValidateTransferItem	proc	near
	uses	ax, bx, cx, si, ds, bp
	.enter
	call	SaveAndVMInfoAndRestore	; valid?
	jc	errorNoLock		; nope, bail out
	call	Transfer_VMLock_DS	; ax = segment, bp = mem handle
					; ds = transfer item

	tst	ds:[CIH_owner].handle	; if owner wasn't zero on exit,
					;	we probably have bogus item
	jnz	error
	tst	ds:[CIH_owner].chunk
	jnz	error
	test	ds:[CIH_flags], mask CIF_UNUSED1 or mask CIF_UNUSED2
	jnz	error
	mov	cx, ds:[CIH_formatCount]
	jcxz	error
	cmp 	cx, CLIPBOARD_MAX_FORMATS
	ja	error

;no RAW for 2.0
;	test	ds:[CIH_flags], mask TIF_RAW
;	jnz	error			; cannot restore RAW item
	;
	; type is finished
	;
	mov	si, offset CIH_formats
itemLoop:
	;
	; ensure VM block handle
	;
	push	ax, di
	movdw	axdi, ds:[si].CIFI_vmChain
	tst_clc	di
	jnz	isDBItem
	call	SaveAndVMInfoAndRestore
isDBItem:
	pop	ax, di
	jc	error
	add	si, size ClipboardItemFormatInfo
	loop	itemLoop
	clc
	jmp	short done

errorNoLock:
	stc
	jmp	short exit

error:
	stc
done:
	call	Transfer_VMUnlock
exit:
	.leave
	ret
ValidateTransferItem	endp

SaveAndVMInfoAndRestore	proc	near
	push	ax, cx, di
	call	VMInfo
	pop	ax, cx, di
	ret
SaveAndVMInfoAndRestore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CLIPBOARDCLOSECLIPBOARDFILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close clipboard file

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/01/90	Initial version
	jenny	4/15/93		Made UserCloseTransferFile global, changed name

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CLIPBOARDCLOSECLIPBOARDFILE	proc	far
	uses	ax, bx, ds, es, si, bp
	.enter

	call	PTransfer

	call	Transfer_DS_DGroup		; ds = dgroup
	mov	bx, ds:[uiTransferVMFile]
;-----
	;if there is no clipboard VM file, exit

	tst	bx
	LONG jz	done
;-----
	;
	; ensure that all non-UI transfer items are gone
	;
EC <	mov	ax, ds:[uiTransferVMFile]				>
EC <	cmp	ds:[normalTransferItem].TII_vmBlock, 0			>
EC <	je	10$			; no item			>
EC <	cmp	ax, ds:[normalTransferItem].TII_vmFile			>
EC <	ERROR_NZ	NON_UI_TRANSFER_ITEM_EXISTS			>
EC <10$:								>
EC <	cmp	ds:[quickTransferItem].TII_vmBlock, 0			>
EC <	je	20$			; no item			>
EC <	cmp	ax, ds:[quickTransferItem].TII_vmFile			>
EC <	ERROR_NZ	NON_UI_TRANSFER_ITEM_EXISTS			>
EC <20$:								>
EC <	cmp	ds:[undoTransferItem].TII_vmBlock, 0			>
EC <	je	30$			; no item			>
EC <	cmp	ax, ds:[undoTransferItem].TII_vmFile			>
EC <	ERROR_NZ	NON_UI_TRANSFER_ITEM_EXISTS			>
EC <30$:								>

	;
	; delete quick transfer and undo transfer items
	;
EC <	tst	ds:[quickTransferItem].TII_refCount	;>
EC <	jz	quickRefOK				;>
EC <	WARNING QUICK_TRANSFER_ITEM_STILL_HAS_REFERENCES >
EC <quickRefOK:						;>
	mov	ax, ds:[quickTransferItem].TII_vmBlock
	tst	ax
	jz	40$
	call	FreeTransferLow
40$:
EC <	tst	ds:[undoTransferItem].TII_refCount	;>
EC <	jz	undoRefOK				;>
EC <	WARNING UNDO_TRANSFER_ITEM_STILL_HAS_REFERENCES >
EC <undoRefOK:						;>
	mov	ax, ds:[undoTransferItem].TII_vmBlock
	tst	ax
	jz	50$
	call	FreeTransferLow
50$:

	;
	; clear owner of normal transfer item
	;
EC <	tst	ds:[normalTransferItem].TII_refCount	;>
EC <	jz	normalRefOK				;>
EC <	WARNING NORMAL_TRANSFER_ITEM_STILL_HAS_REFERENCES >
EC <normalRefOK:				   	;>
	mov	ax, ds:[normalTransferItem].TII_vmBlock
	tst	ax
	jz	noNormalItem
	call	Transfer_VMLock_ES
	call	VMDirty
	clr	ax
	mov	es:[CIH_owner].handle, ax
	mov	es:[CIH_owner].chunk, ax
	;
	; also clear source ID -- means that clipboard items across shutdowns
	; may be identified as from a "different document"
	;
	mov	es:[CIH_sourceID].handle, ax
	mov	es:[CIH_sourceID].chunk, ax
	call	Transfer_VMUnlock

noNormalItem:

	;
	; save normal transfer item
	;
	call	VMGetMapBlock		; ax = map block
	call	Transfer_VMLock_ES
	call	VMDirty
	mov	ax, ds:[normalTransferItem].TII_vmBlock	; zero OK
	mov	es:[TFH_normalItem], ax
	call	Transfer_VMUnlock

	;
	; ensure that transfer free list buffer is empty
	;
EC <	push	bx							>
EC <	mov	bp, ds:[transferFreeListBufSize]			>
EC <	mov	bx, ds:[transferFreeListBuffer]				>
EC <	call	MemLock							>
EC <	mov	es, ax			; es:si = free list buffer	>
EC <	clr	si							>
EC <ecCheckLoop:							>
EC <	cmp	es:[si].TII_vmBlock, 0					>
EC <	ERROR_NZ	TRANSFER_FREE_LIST_NOT_EMPTY			>
EC <	add	si, size TransferItemInstance				>
EC <	cmp	bp, si				; end of free list?	>
EC <	jne	ecCheckLoop						>
EC <	call	MemUnlock						>
EC <	pop	bx							>

	;
	; close transfer VM file (saving normalTransferItem)
	;
	mov	al, FILE_NO_ERRORS
	call	VMClose

	;
	; free transfer free list buffer
	;
	mov	bx, ds:[transferFreeListBuffer]
	call	MemFree

if ERROR_CHECK
	call	FilePushDir
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath
	mov	bx, handle transferItemFilename
	call	MemLock
	mov	ds, ax
assume ds:Strings
	mov	dx, ds:[transferItemFilename]	;DS:DX <- file longname
assume ds:dgroup
	mov	ax, (VMO_OPEN shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx
	call	VMOpen
	push	bx
	mov	bx, handle transferItemFilename
	call	MemUnlock
	pop	bx
	ERROR_C	BAD_TRANSFER_FILE_CLOSE_MISSING
	call	VMGetMapBlock			; ax = map block
	tst	ax				; any map block?
	ERROR_Z	BAD_TRANSFER_FILE_CLOSE_NO_MAP
	call	Transfer_VMLock_ES		; ax = segment, bp = mem handle
						; es = TransferFileHeader
	mov	ax, es:[TFH_normalItem]		; get normal transfer item
	tst	ax
	jz	EC10
	call	CheckTransferItem
EC10:
	call	Transfer_VMUnlock		; unlock map block
	mov	al, FILE_NO_ERRORS
	call	VMClose
	call	FilePopDir
endif

done:
	call	VTransfer

	.leave
	ret
CLIPBOARDCLOSECLIPBOARDFILE	endp

;
; misc byte-saving routines
;
; this saves 2 bytes per call and costs 9 cycles per call, but these are
; already slow and called relatively infrequently
;
Transfer_VMLock	proc	near
	call	VMLock
	ret
Transfer_VMLock	endp

Transfer_VMLock_DS	proc	near
	call	Transfer_VMLock
	mov	ds, ax
	ret
Transfer_VMLock_DS	endp

Transfer_VMLock_ES	proc	near
	call	Transfer_VMLock
	mov	es, ax
	ret
Transfer_VMLock_ES	endp

Transfer_VMUnlock	proc	near
	call	VMUnlock
	ret
Transfer_VMUnlock	endp

Transfer_DS_DGroup	proc	near
	push	ax
	mov	ax, segment dgroup
	mov	ds, ax
	pop	ax
	ret
Transfer_DS_DGroup	endp

Transfer ends


TransferRemote	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardTransferDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up a modal dialog box

CALLED BY:	GLOBAL
PASS:		bx - flags
		ax - chunk handle of string
RETURN:		nada
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

				;  to be bound to net.geo...

ClipboardTransferDialog	proc	near	uses	bp
	.enter
	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, bx
	mov	ss:[bp].SDOP_customString.handle, handle Strings
	mov	ss:[bp].SDOP_customString.chunk, ax
	clr	ax
	mov	ss:[bp].SDOP_stringArg1.handle,ax
	mov	ss:[bp].SDOP_stringArg2.handle,ax
	mov	ss:[bp].SDOP_customTriggers.handle,ax
	mov	ss:[bp].SDOP_helpContext.segment, ax
	call	UserStandardDialogOptr
	.leave
	ret
ClipboardTransferDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallNetLibraryNear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the net library

CALLED BY:	GLOBAL
PASS:		bx - net library handle
		ax - net library entry point to call
		other data set appropriately for call
RETURN:		whatever from library
DESTROYED:	whatever library trashes, except BP,DI are preserved
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallNetLibraryNear	proc	near	uses	bp, di
	.enter
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	.leave
	ret
CallNetLibraryNear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BringUpRemoteTransferStatusBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the RemoteTransferStatus box

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		^lBX:SI - OD of box
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/13/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

				;  to be bound to net.geo...

BringUpRemoteTransferStatusBox	proc	near	uses	ax, cx, dx, bp, di
	.enter

	mov	bx, handle RemoteTransferStatusBox
	mov	si, offset RemoteTransferStatusBox
	call	UserCreateDialog

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage

;	If we are being called from the UI thread, or the app is not multi-
;	threaded, the box won't draw unless we force an expose.

	call	ForceDialogRedraw

	.leave
	ret
BringUpRemoteTransferStatusBox	endp

ForceDialogRedraw	proc	near	uses	ax, cx, dx, bp
	.enter
	mov	ax, MSG_VIS_QUERY_WINDOW
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_META_EXPOSED
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
ForceDialogRedraw	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		P/VRemoteTransferSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ps and Vs the remoteTransferSem semaphore, to ensure
		only one app is trying to connect with the library at
		a time.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ds - dgroup
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/13/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

				;  to be bound to net.geo...

PRemoteTransferSem	proc	near	uses	ax, bx
	.enter
	segmov	ds, dgroup, ax
	PSem	ds, remoteTransferSem, TRASH_AX_BX
	.leave
	ret
PRemoteTransferSem	endp
VRemoteTransferSem	proc	near	uses	ax, bx
	.enter
	segmov	ds, dgroup, ax
	VSem	ds, remoteTransferSem, TRASH_AX_BX
	.leave
	ret
VRemoteTransferSem	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardRemoteSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send clipboard to remotely connected machine

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry if fail
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Open Connection
	Send ClipboardItemHeader (with all the FormatInfo's)
	Send VM chains in order (using NetMsgSendBuffer)
	Close Connection

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	1/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

				;  to be bound to net.geo...

NUM_RETRIES	equ	3
; The # times we'll try to send the initial packet
ClipboardRemoteSend	proc	far
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	netLib	local	hptr
	port	local	word
	socket	local	word
	; Tokens of port and socket of connection we are using

	clipboardFile	local	hptr
	clipboardItem	local	word

	clipboardHandle	local	hptr
	;Mem handle of ClipboardItemHeader

	errMsg		local	lptr.char
	;ChunkHandle of error message to display

	dialog		local	optr	

	.enter

;	Only one app can send or receive at a time

	call	PRemoteTransferSem

	clr	netLib

;	Bring up the status box, to let the user know what is going on

	call	BringUpRemoteTransferStatusBox
	movdw	dialog, bxsi

;	NOTE: As soon as we do a ClipboardQueryItem, the UI thread could
;	block trying to access the clipboard item, so we cannot do any calls
;	to the UI thread (like trying to put up an error dialog) until
;	we've called ClipboardDoneWithItem.

	push	bp
	clr	bp
	call 	ClipboardQueryItem  		;bx:ax - ClipboardItemHeader
	tst	bp
	pop	bp
	mov	errMsg, offset NoClipboardToRemoteCopyError
	mov	clipboardFile, bx
	mov	clipboardItem, ax
	stc
LONG	jz	cleanup				;Branch if no data to copy


	clr	di

	call	InitializeConnection

	mov	errMsg, ax
LONG	jc	cleanup
	mov	netLib, bx

;	Send the ClipboardItemHeader to the remote machine

	mov	port, si
	mov	socket, di

;	Lock down the ClipboardItemHeader, so we can send it to the remote
;	machine, and so we can get the data from it.

	push	bp
	mov	ax, clipboardItem
	mov	bx, clipboardFile
	call	VMLock
	mov	ds, ax	
	mov	si, bp
	pop	bp
	mov	clipboardHandle, si
	clr	si				; ds:si - ClipboardItemHeader

	mov	errMsg, offset NoConnectionError

;	Try sending the ClipboardItemHeader to the remote machine - we try
;	a few times, to give the user time to get the remote machine ready
	
	mov	di, NUM_RETRIES+1
tryAgain:
	dec	di
	stc
	LONG jz	cleanup
	mov	bx, netLib
	mov	ax, port
	mov	ss:[TPD_dataBX], ax		;Pass port token in BX
	mov	dx, socket			;Pass socket token in DX
	mov	cx, size ClipboardItemHeader	; CX <- # bytes to send

;	If the user starts a transfer, aborts it, then starts a new one,
;	horrible death can ensue. To avoid this, we always send the first
;	packet with a special token denoting that it is the first packet
;	in a clipboard transfer. If the first packet received by the remote
;	machine is not START_PACKET, it aborts. If any packet after that has
;	the START_PACKET denotation, it aborts.

	push	bp
	mov	bp, START_PACKET
	CallNetLibrary	NetMsgSendBuffer
	pop	bp
	jnc	sent
	cmp	ax, NET_ERR_REPLY_ERROR
	jne	tryAgain

;	If we get a NET_ERR_REPLY_ERROR error, that means that the other
;	machine is listening, but that no socket is listening for us on
;	the other side, so sleep for a few seconds to let the user get his
;	act together.

	mov	ax, 2 * 60		;Sleep for 2 seconds
	call	TimerSleep
	jmp	tryAgain

sent:
	tst_clc	ds:[CIH_formatCount]	;If no formats to send, exit with
	jz	cleanup			; carry clear and no error

;	Change the status box to say "Sending..."

	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	bx, dialog.handle
	mov	si, offset RemoteTransferStatusGlyph
	mov	cx, offset SendingGlyph
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	movdw	bxsi, dialog
	call	ForceDialogRedraw

;	Copy each vm chain over

	mov	errMsg, offset TimeoutError ;Setup error message, if error
	mov	si, offset CIH_formats	;DS:SI <- ClipboardItemFormatInfo
	mov	bx, clipboardFile	;BX <- file handle
	mov	cx, ds:[CIH_formatCount]
doloop:
	push	bp, cx
	mov	dx, socket
	mov	cx, netLib
	mov	di, port
	movdw	axbp, ds:[si].CIFI_vmChain
	call	CopyVMChainRemote
	pop	bp, cx
	jc	cleanup
	add	si, size ClipboardItemFormatInfo
	loop	doloop
EC <	ERROR_C	-1							>

cleanup:

;
;	Carry set (if error)
;
	pushf

;	Unlock the ClipboardItemHeader we sent, and close the connection.
;	We don't have to close the connection or unlock the ClipboardItemHeader
;	if we never made a connection.

	tst	netLib
	jz	doneWithItem

	push	bp
	mov	bp, clipboardHandle
	call	VMUnlock			;Unlock the ClipboardItemHeader
	pop	bp

	mov	bx, netLib
	mov	si, port
	mov	di, socket
	call	CloseOpenConnection

doneWithItem:

	mov	bx, clipboardFile
	mov	ax, clipboardItem
	call	ClipboardDoneWithItem

;	Nuke the status box

	movdw	bxsi, dialog
	call	UserDestroyDialog

	popf					;If error, put up a dialog
	jc	displayErrorBox			; before exiting

if 0

;	If the transfer was successful, put up a dialog denoting that fact.

	mov	ax, offset ClipboardSendComplete
	mov	bx, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	ClipboardTransferDialog
	clc
endif
exit:
	call	VRemoteTransferSem
	.leave
	ret

displayErrorBox:
	mov	ax, errMsg
	mov	bx, (CDT_ERROR shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	ClipboardTransferDialog
	stc
	jmp	exit
ClipboardRemoteSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyVMChainRemote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send VM Chain to remote machine

CALLED BY:	ClipboardRemoteSend
PASS:		bx - VM file handle
		cx - net library handle
		ax:bp - VM chain
		di - port token
		dx - socket token
RETURN:		carry set if error
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

code stolen from VMCopyVMChain

if VM is not a Tree, and it's a Chain, then we copy the UID over (it might
be a HugeArray structure)
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	2/ 2/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyVMChainRemote	proc	near
	uses	bx, cx,ds,si

	dbItem	local	word	\
		push	bp
	vmFile	local	hptr	\
		push	bx

	vmHan	local	word	\
		push	ax	
	netLib	local	hptr	\
		push	cx
	vmBlock	local	hptr
	.enter
	tst	dbItem			; 0 if VM , else DB item
	LONG jnz	copydb


;	Lock down the VM Chain, and copy all the blocks over.

	push	bp
	call	VMLock
	mov	ds, ax
	mov	si, bp
	pop	bp
	mov	vmBlock, si

	clr	si			;ds:si - VM BLOCK
	mov	ax, vmHan		;AX <- VM handle of VM chain


	push	di	
	mov	ss:[TPD_dataBX], di
	call	VMInfo			;cx - size of block, di - UID
	mov_tr	ax, di
	pop	di

	mov	bx, ds:[VMCL_next]	;next handle
	push	bx
	call	PTransfer

;	For the huge array stuff, we want to preserve the user ID of the
;	block. If this is a VM Tree, we do nothing.
;	Else, if we store the user id of the block as the VMCL_next field,
;		*except* for the last block in the chain, for which we store
;		ZERO_UID.

	cmp	bx, VM_CHAIN_TREE	;If this is a tree, continue
	je	nstuff
	tst	bx			;If not last block in chain, store
	jnz	stuff			; userID
	mov	ax, ZERO_UID
stuff:
	mov	ds:[VMCL_next], ax	;

nstuff:
	mov	bx, netLib
	push	bp
	mov	bp, DATA_PACKET
	CallNetLibrary	 NetMsgSendBuffer
	pop	bp
	pop	ax
	mov	ds:[VMCL_next], ax	;Restore "next ptr"	
	call	VTransfer
	LONG jc	unlockExit
	cmp	ax, VM_CHAIN_TREE
	jz	copyTree

	push	bp
	mov	bp, vmBlock
	call	VMUnlock
	pop	bp

	tst_clc	ax			;At end of chain?
	jz	exit			;

	; call ourself recursively to copy the rest of the chain
	push	bp
	mov	bx, vmFile
	mov	cx, netLib
	clr	bp
	call	CopyVMChainRemote		;ax = destination block
	pop	bp
exit:	
	.leave
	ret

	; Copy a DB item
copydb:
EC<	WARNING	WARNING_DB_ITEM_ENCOUNTERED	>
	push	es
	push	di

	mov	di, ss:[dbItem]		;AX:DI <- DB Item			
	call	DBLock			;Lock the source db item
	segmov	ds, es
	mov	si, ds:[di]		;DS:SI - ptr to data to send
	ChunkSizePtr ds, si, cx		;CX <- size of data to send

	pop	di			;Restore port token
	mov	ss:[TPD_dataBX], di
	mov	bx, ss:[netLib]
	push	bp
	mov	bp, DATA_PACKET
	CallNetLibrary	NetMsgSendBuffer
	pop	bp
	call 	DBUnlock
	pop	es
	jmp	exit

	; Copy a VM tree
copyTree:
	mov	si, ds:[VMCT_offset]
	mov	cx, ds:[VMCT_count]

doloop:
	tstdw	ds:[si]			;Skip null VM Chains
	jz	next

	push	bp, cx
	mov	cx, netLib
	mov	bx, vmFile
	movdw	axbp, ds:[si]
	call	CopyVMChainRemote
	pop	bp, cx
	jc	unlockExit
next:
	add	si, size dword		;Clears carry
	loop	doloop
			
unlockExit:	
	push	bp
	mov	bp, vmBlock
	call	VMUnlock
	pop	bp
	jmp	exit

	
CopyVMChainRemote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBlockFromQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a block from the input queue

CALLED BY:	GLOBAL
PASS:		cx - # ticks to wait for data until timeout 
		ds - dgroup
RETURN:		carry set if timeout, ax not changed
		carry clear if got block:
			ax - datablock
			cx - # bytes in block
DESTROYED:	cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBlockFromQueue	proc	near	uses	bx, dx, bp, si
	.enter

EC <	push	ax, bx							>
EC <	mov	bx, ds							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
EC <	pop	ax, bx							>

waitForData:
	clr	ds:[receivedData]
	push	ax, bx
	PTimedSem ds, remoteTransferTimeoutSem, cx, TRASH_AX_BX_CX
	pop	ax, bx
	jc	timeout

	tst	ds:[abortClipboardTransfer]
	jnz	abort

	mov	bx, ds:[remoteTransferQueue]
	call	QueueGetMessage
	mov_tr	bx, ax			;BX <- message

	mov	ax, SEGMENT_CS
	push	ax
	mov	ax, offset getMessageRegs
	push	ax
	clr	si			; si <- nuke event, please
	call	MessageProcess		; ax <- data block, dx <- size
	mov	cx, dx
	clc
exit:
	.leave
	ret

getMessageRegs:
	; do-nothing "routine" for MessageProcess so we get all the registers
	; from the message
	retf

abort:
	; put the count back on the scheduling semaphore so when the thing
	; cleans up, it doesn't block forever, due to the current mismatch
	; between the semaphore and the queue -- ardeb 1/13/95
	VSem	ds, remoteTransferTimeoutSem
	stc
	jmp	exit

timeout:

;	If the connection is still open (we've received some data since the
;	last call to GetBlockFromQueue) then keep waiting. It could be that
;	the port is busy sending to another socket, or that a huge buffer
;	is being transferred.

	
	tst	ds:[receivedData]
	jnz	waitForData
	stc
	jmp	exit
GetBlockFromQueue	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardRemoteReceive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive clipboard from remotely connected machine

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set on error, carry clear if successful
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	1/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ClipboardRemoteReceive	proc	far
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	dialog	local	optr
	port	local	word
	socket	local	word
	netLib	local	word
	vmBlock		local	hptr
	vmHandle	local	word
	.enter

;	Only one app can send or receive at a time

	call	PRemoteTransferSem		; ds <- dgroup
	clr	netLib

;	Allocate the queue that will hold the data for the app

	call	GeodeAllocQueue
	mov	ds:[remoteTransferQueue], bx
	clr	ds:[receivedData]
	clr	ds:[abortClipboardTransfer]
	mov	ds:[waitingForClipboardItemHeader], TRUE

	call	BringUpRemoteTransferStatusBox
	movdw	dialog, bxsi

	mov	di,1

	call	InitializeConnection

LONG	jc	putupErrorBox

	mov	netLib, bx
	mov	port, si
	mov	socket, di

;	Sit here until we receive the ClipboardItemHeader, or until we time out

	segmov	ds, dgroup, ax
	mov	cx, ds:[timeOutValue]
	call	GetBlockFromQueue	;AX <- handle of block of data
					;cx <- block size
LONG	jc	error
	push	ax			;Save data block

;	Change the status box to say "Receiving data..."

	mov	bx, dialog.handle
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	si, offset RemoteTransferStatusGlyph
	mov	cx, offset ReceivingGlyph
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage
	
	movdw	bxsi, dialog
	call	ForceDialogRedraw
	pop	cx			;CX <- data block

; cx holds the memory handle of incoming buffer (ClipboardItemHeader)
; attach it to our clipboard file and lock it

	call	ClipboardGetClipboardFile
	clr	ax
	call	VMAttach
	mov	vmHandle, ax

	push	bp
	call	VMLock
	call	VMDirty
	mov	ds,ax
	mov	si, bp
	pop	bp
	mov	vmBlock, si


; we've locked the ClipboardItemHeader, so modify fields as necessary and
; receive all the formats in order.
; to receive formats:
; 	create new block
;	fix handle entry in ClipboardFormatInfo to new block
;	call GetVMChains to attach VM_Chain recursively to new block

	clr	ds:[CIH_flags]
	clrdw	ds:[CIH_owner]
	clrdw	ds:[CIH_sourceID]
	mov	dx, ds:[CIH_formatCount]
	tst	dx
	jz	afterCopyingFormats
	mov	si, offset CIH_formats
doloop:
	clr	cx		;Alloc a VM block w/no memory
	tst	ds:[si].CIFI_vmChain.offset
	jnz	dodb
	call	VMAlloc
	clr	di
	jmp	common
dodb:
	mov	ax, DB_UNGROUPED
	call	DBAlloc
	mov	ds:[si].CIFI_vmChain.offset, di
common:
	mov	ds:[si].CIFI_vmChain.segment, ax
	call	GetVMChains	; preserve bx,cx,dx,ds,si,bp
	LONG jc	errorReceiving
	add	si, size ClipboardItemFormatInfo
	dec	dx
	jnz	doloop

afterCopyingFormats:
	call	VMUpdate

;	Unlock the ClipboardItemHeader and register the item

	push	bp
	mov	ax, vmHandle
	mov	bp, vmBlock
	call	VMUnlock

	clr	bp
	call	ClipboardRegisterItem
	pop	bp

if 0
	mov	ax, offset ClipboardReceiveComplete
	mov	bx, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	ClipboardTransferDialog
endif


	mov	bx, netLib
	mov	si, port
	mov	di, socket
	call	CloseOpenConnection

	movdw	bxsi, dialog	
	call	UserDestroyDialog
	clc

cleanupQueue:
	pushf

;
;	We may have timed out, and ClipboardReceiveCallback may have added
;	more blocks to the queue. Free them up here before nuking the queue.
;
	segmov	ds, dgroup, bx
flushQueue:
	mov	bx, ds:[remoteTransferQueue]
	call	GeodeInfoQueue
	tst	ax
	jz	noMoreEvents
	PSem	ds, remoteTransferTimeoutSem
	call	QueueGetMessage
	mov_tr	bx, ax			;BX <- message handle

	call	ObjGetMessageInfo	;AX <- handle of data block
	call	ObjFreeMessage		;Free up the message...
	mov_tr	bx, ax
	call	MemFree			;...and the datablock too
	jmp	flushQueue
noMoreEvents:
	call	GeodeFreeQueue
	popf

	call	VRemoteTransferSem
	.leave
	ret

errorReceiving:
;
;	Free up any other chains we have received, and put up an error dialog
;
;	DX - # VM Chains left to copy
;	BX - VM file
;
;	If DI=0, AX = handle of VM Block to free
;	Else, AX.DI = DBItem to free
;
	
freeNextFormat:

;	Sit in a loop and free up all the VMChains that we've already
;	read in...

	cmp	dx, ds:[CIH_formatCount]
EC <	ERROR_A	CLIPBOARD_TRANSFER_INTERNAL_ERROR			>
	je	freeHeader
	sub	si, size ClipboardItemFormatInfo
	push	bp
	movdw	axbp, ds:[si].CIFI_vmChain
	call	VMFreeVMChain
	pop	bp
	inc	dx
	jmp	freeNextFormat

freeHeader:

;
;	Free up the ClipboardItemHeader
;
	mov	ax, vmHandle
	call	VMFree
	mov	ax, offset TimeoutError
	jmp	closeConnectionAndDisplayError

error:
	mov	ax, offset NoConnectionError

closeConnectionAndDisplayError:

	mov	bx, netLib
	mov	si, port
	mov	di, socket
	call	CloseOpenConnection

putupErrorBox:
	movdw	bxsi, dialog
	call	UserDestroyDialog

	mov	bx, (CDT_ERROR shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	ClipboardTransferDialog
	stc
	jmp	cleanupQueue
	
ClipboardRemoteReceive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetVMChains
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get next block in VM Chain/Tree and attach it.

CALLED BY:	ClipboardRemoteReceive (recursive func)
PASS:		ax - new VM Block (or db group)
		bx - VM file handle
		di - 	0 - VM
			else DB item
RETURN:		carry set if error
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	2/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetVMChains	proc	near
	uses	ax,bx,cx,dx,di,si,bp,ds
	.enter
	push	ax,bx,di
; first we receive the buffer 
	segmov	ds, dgroup, ax
	mov	cx, CLIPBOARD_XFER_TIME_OUT
	call	GetBlockFromQueue
	mov_tr	si, ax			; si <- mem block with data
	pop	ax,bx,di
LONG	jc	error

; si holds the memory handle of incoming buffer
; cx holds the size of the incoming buffer  
	tst	di
	jz	vmcode

; DB item to be copied here, not VM	
; first, let's re-alloc the DB item to the correct size
	call	DBReAlloc
; now lock both blocks and do a copy
	push	es
	call	DBLock
	call	DBDirty
	mov	di, es:[di]
	mov	bx, si
	call	MemLock
	mov	ds, ax
	clr	si
	shr	cx, 1
	rep	movsw	
	jnc	5$
	movsb
5$:
	call	DBUnlock
	pop	es
	call	MemFree
	jmp	exitWithNoError

;attach it to our block 
vmcode:
	mov	cx, si				; cx <- mem handle
	call	VMAttach
	push	ax				; save the VM Block
	call	VMLock
	call	VMDirty
	mov	ds,ax
	mov	cx, ds:[VMCL_next]		; cx <- possible UID
	cmp	cx, VM_CHAIN_TREE
	jz	copyTree

; this is not a tree -- use the standard procedure, and make sure we check
; to see if it's a HugeArray structure
	cmp	cx, ZERO_UID
	jne	nozero
	clr	ds:[VMCL_next]
	call	VMUnlock
	jmp	atEnd
nozero:
	pop	ax				; get the block handle
	push	ax
	call	VMModifyUserID
	; call ourself recursively to copy the rest of the chain
	clr	cx				;Just alloc a VM block with
	clr	ax				; no memory
	call	VMAlloc
	mov	ds:[VMCL_next],ax		; create link
	call	VMUnlock			; don't need the thing locked
						;  anymore...
	clr	di
	call	GetVMChains			; ax = destination block
	jc	popError
atEnd:
; here, we have gotten the entire chain.  Now we check to see if our block
; happens to be a HugeArrayDirectory block.
	pop	ax				; block
	push	ax
	call	VMInfo
	pop	ax
	cmp	di, SVMID_HA_DIR_ID
	jne	exitWithNoError
	call	FixupHugeArrayChain
exitWithNoError:
	clc
done:
	.leave
	ret

; error received here, delete our block and propagate error

popError:
	pop	ax				; VM block or DBItem.group
error:
	tst	di
	jnz	freeDB
	call	VMFree
	jmp	signalError
freeDB:
	call	DBFree
signalError:
	stc
	jmp	done

; got a tree block, so recursively fetch all the branches
copyTree:
	mov	si, ds:[VMCT_offset]
	mov	dx, ds:[VMCT_count]
	tst	dx
	jz	treeDone
	clr	cx			; cx <- 0 for the duration (for
					;  DBAlloc and VMAlloc)
doloop:
	movdw	axdi, ds:[si]		; axdi <- next branch (we use it to
					;  know what type of thing to expect)
	tst	di
	jnz	dodb			; => DB item
	tst	ax
	jz	nextBranch		; => pointer is zero, so nothing
					;  coming for it
	call	VMAlloc			; ax <- block for recursion to use

treeCommon:
	movdw	ds:[si], axdi		; save branch head in tree
	call	VMDirty
	call	VMUnlock		; release it while we're recursing, to
					;  allow heap to shuffle
	
	call	GetVMChains
	jc	treeError		; => go free our block and chains
					;  we've already gotten
	
	pop	ax			; ax <- tree block
	push	ax
	call	VMLock
	mov	ds, ax

nextBranch:
	add	si, size dword
	dec	dx
	jnz	doloop

treeDone:
	call	VMUnlock
	pop	ax
	jmp	exitWithNoError

dodb:
	call	DBAlloc
	jmp	treeCommon

treeError:
	;
	; Got an error receiving the thing, so we need to nuke all the
	; branches we've already received. Easiest is to just zero the remaining
	; pointers and call VMFreeVMChain on our block. We start zeroing at
	; our current location, as our recursive self will have freed the
	; chain we were trying to fetch.
	;
	pop	ax
	push	ax, es
	call	VMLock
	mov	es, ax
	clr	ax
	mov	cx, dx
	mov	di, si
	shl	cx			; vmchains are dwords...
	rep	stosw
	call	VMDirty
	call	VMUnlock

	pop	ax, es
	clr	bp			; axbp <- VMChain
	call	VMFreeVMChain
	jmp	signalError

GetVMChains	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialized a connection to a remote machine

CALLED BY:	ClipboardRemoteSend, ClipboardRemoteReceive
PASS:		di - 0 if send, 1 if receive
RETURN:		if error 
			carry set
			ax - chunk handle of error msg in Strings resource
		else
			carry clear
			si - port token
			di - socket token
			bx - net library
DESTROYED:	cx,dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	1/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

				;  to be bound to net.geo...

EC < netLibname char "netec.geo",0 >
NEC< netLibname char "net.geo",0 >
initCategory	char "ui",0
initKeyBaud	char "remoteBaudRate",0
initKeyPort	char "remoteClipPort",0
initKeyTimeOut	char "timeOut",0

InitializeConnection	proc	near

	uses	ds,bp
	netLib	local	hptr
	; Handle of the net library

	portInfo	local	SerialPortInfo

	port		local	word
	.enter

	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath

	segmov	ds, cs
	mov	si, offset netLibname	
	clr	ax
	clr	bx
	call	GeodeUseLibrary
	call	FilePopDir
	mov	ax, offset NoNetLibraryError
	LONG jc	displayError
	mov	netLib, bx			;BP <- net library handle

	mov	si, offset initCategory
	mov	cx, cs
	mov	dx, offset initKeyPort
	call	InitFileReadInteger		;
	LONG jc	iniError

	mov	bx, ax				;BX <- port	
	mov	dx, offset initKeyBaud
	call	InitFileReadInteger		; ax - baud rate
	LONG jc	iniError

	push	ax
	mov	dx, offset initKeyTimeOut
	call	InitFileReadInteger		; ax - time out value
	mov_tr	si,ax
	jnc	timed
	mov	si, STANDARD_INITIAL_TIMEOUT
timed:
	pop	ax				;AX <- baud rate
						;SI <- timeout value
	segmov	ds, dgroup, cx
	mov	ds:[timeOutValue], si
	mov	portInfo.SPI_portNumber, bx
	mov	portInfo.SPI_baudRate, ax

; call init procedures, first open the port

	mov	cx, size SerialPortInfo
	segmov	ds, ss, cx
	lea	si, portInfo
	mov	bx, netLib
	CallNetLibrary	NetMsgOpenPort
	jc	portError

	mov	port, bx
	mov	cx, SID_CLIPBOARD_SEND		;CX <- our ID
	mov	ax, SID_CLIPBOARD_RECEIVE	;AX <- socket ID to connect to
	tst	di
	jz	sending
	xchg	cx, ax
sending:

; when we supply the callback address, we use a virtual segment so that
; the code doesn't have to reside in fixed memory

	mov	dx, vseg ClipboardReceiveCallback
	mov	ds, dx
	mov	dx, offset cs:ClipboardReceiveCallback
	mov	si,di				;SI <- 0 if send, 1 if receive
	mov	ss:[TPD_dataBX], bx
	mov	bx, netLib
	push	bp
	mov_tr	bp, ax				;BP <- socket ID to connect to
	CallNetLibrary	NetMsgCreateSocket
	pop	bp
	jc	socketError
	mov_tr	di,ax				;DI <- socket token
	mov	si, port			;SI <- port token
	mov	bx, netLib			;BX <- handle of net library
exit:
	.leave
	ret

portError:
	mov_tr	bx, ax				;BX <- error number

	mov	ax, offset NetDriverNotFoundError
	cmp	bx, NET_ERROR_DRIVER_NOT_FOUND
	je	freeLibError
	mov	ax, offset NetDriverPortInUseError
	cmp	bx, NET_ERR_PORT_IN_USE
	je	freeLibError
	mov	ax, offset CreatePortError
	jmp	freeLibError

socketError:
	mov	bx, port
	mov	ss:[TPD_dataBX],bx		;Pass port handle
	mov	bx, netLib
	CallNetLibrary	NetMsgClosePort
	mov	ax, offset CreateSocketError
	jmp	freeLibError

iniError:
	mov	ax, offset BadRemoteIniSettingsError
freeLibError:
	mov	bx, netLib
	call	GeodeFreeLibrary
displayError:
	stc
	jmp	exit
InitializeConnection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseOpenConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close the connection when things are done 

CALLED BY:	ClipboardRemoteSend, ClipboardRemoteReceive
PASS:		bx - handle of net library
		si - port token 
		di - socket token
RETURN:		nothing
DESTROYED:	bx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	1/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

				;  to be bound to net.geo...

CloseOpenConnection	proc	near	uses	ax, bp
	.enter

	push	bx
	mov	ss:[TPD_dataBX], si
	mov	dx, di
	CallNetLibrary	 NetMsgDestroySocket
	pop	bx
EC  <	ERROR_C	CANNOT_DESTROY_SOCKET				>

	push	bx
	mov	ss:[TPD_dataBX], si
	CallNetLibrary	 NetMsgClosePort
	pop	bx
EC  <	ERROR_C	CANNOT_CLOSE_PORT				>
	call	GeodeFreeLibrary
	.leave
	ret
CloseOpenConnection	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardReceiveCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback which is called by the Communication Server when
		a message from remote machine is passed to us (during
		Clipboard transfer)

CALLED BY:	NET LIBRARY (when a message is sent to us)
PASS:		ds:si - buffer
		cx - size (0 if exiting, -1 if just a notification that we
			   are receiving data)
		dx - packet ID (passed by remote caller)	   
		di - 0 if we are sender , 1 otherwise
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	1/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

				;  to be bound to net.geo...

ClipboardReceiveCallback	proc	far
	uses	ds,es
	.enter
	segmov	es, dgroup, ax
.assert	SOCKET_DESTROYED	eq	0
	jcxz	toExit
	tst	es:[abortClipboardTransfer]
	jz	noAbort
toExit:
	jmp	exit
noAbort:
	cmp	cx, SOCKET_HEARTBEAT
	LONG je	isHeartbeat

	tst	di							
EC <	ERROR_Z	CLIPBOARD_SEND_SOCKET_RECEIVED_DATA			>
NEC <	jz	exit							>
EC <	WARNING RECEIVED_TRANSFER_PACKET				>

	cmp	dx, START_PACKET
	jne	midPacket
	tst	es:[waitingForClipboardItemHeader]
	jnz	haveData
	jmp	abort
midPacket:
EC <	cmp	dx, DATA_PACKET						>
EC <	ERROR_NZ	CLIPBOARD_TRANSFER_INTERNAL_ERROR		>
	tst	es:[waitingForClipboardItemHeader]
	jz	haveData
abort:

;
;	Either we were waiting for a START_PACKET, and got a DATA_PACKET, or
;	vice-versa, so set the flag to abort the clipboard transfer - all
;	data collected on this socket will be ignored.
;
EC <	WARNING	ABORTING_CLIPBOARD_TRANSFER				>
	mov	es:[abortClipboardTransfer], TRUE

haveData:
	clr	es:[waitingForClipboardItemHeader]

; we create a buffer, copy everything to it, unlock it, 
; then V on the waiting semaphore

	mov	dx,cx
	mov_tr	ax,cx
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	mov	bx, handle 0
	call	MemAllocSetOwner
	mov	es,ax
	clr	di				; es:di - dest
	mov	cx,dx				; size
	shr	cx,1
	jnc	5$
	movsb
5$:	
	rep	movsw				; strncpy
EC <	push	ds, si							>
EC <	dec	si							>
EC <	call	ECCheckBounds						>
EC <	segmov	ds, es							>
EC <	mov	si, di							>
EC <	dec	si							>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>
	call	MemUnlock

; here, we've copied everything to the new buffer and unlocked it (bx)
;
;	Add the mem handle to the queue via ObjMessage. It will be retrieved
;	by the calling thread.
;

	segmov	ds, dgroup, ax
	mov_tr	ax, bx					;AX <- mem handle
							;dx = data size
	mov	bx, ds:[remoteTransferQueue]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	VSem	ds, remoteTransferTimeoutSem, TRASH_AX_BX
exit:	
	.leave
	ret
isHeartbeat:
	mov	es:[receivedData], TRUE
	jmp	exit
	
ClipboardReceiveCallback	endp


TransferRemote	ends
