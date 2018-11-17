COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991, 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap
FILE:		bitmapUI.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/91		Initial Version

DESCRIPTION:
	This file contains routines related to UI (controllers)
	for VisBitmapClass

RCS STAMP:

	$Id: bitmapUI.asm,v 1.1 97/04/04 17:43:09 newdeal Exp $
------------------------------------------------------------------------------@
BitmapBasicCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapNotifyCurrentToolChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out a GWNT_BITMAP_CURRENT_TOOL_CHANGE type notification
		with the current tool's class

PASS:		*ds:si - VisBitmap object

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	4 jun 92	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapNotifyCurrentToolChange	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_NOTIFY_CURRENT_TOOL_CHANGE
	uses	cx, dx
	.enter

	mov	bx, ds:[di].VBI_tool.handle
	tst	bx
	jz	sendNotification
	mov	si, ds:[di].VBI_tool.chunk
	mov	ax, MSG_META_GET_CLASS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	push	cx					;save class segment
	mov	ax, size VisBitmapNotifyCurrentTool
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8
	call	MemAlloc
	jc	done
	mov	es, ax
	mov	ax, 1
	call	MemInitRefCount
	pop	es:[VBNCT_toolClass].segment
	mov	es:[VBNCT_toolClass].offset, dx
	call	MemUnlock

sendNotification:
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_TOOL_CHANGE
	mov	dx, GWNT_BITMAP_CURRENT_TOOL_CHANGE
	call	VisBitmapUpdateControllerLow

done:
	.leave
	ret
VisBitmapNotifyCurrentToolChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapNotifyFormatChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out a GWNT_BITMAP_CURRENT_FORMAT_CHANGE type notification

PASS:		*ds:si - VisBitmap object

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	4 jun 92	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapNotifyCurrentFormatChange	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_NOTIFY_CURRENT_FORMAT_CHANGE
	uses	cx, dx, bp
	.enter

	mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_POINTS
	call	ObjCallInstanceNoLock

	tst	dx
	jz	sendNullNotification

	mov	di, cx					;di <- width
	mov	ax, size VisBitmapNotifyCurrentFormat
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8
	call	MemAlloc
	jc	done
	mov	es, ax
	mov	ax, 1
	call	MemInitRefCount
	mov	es:[VBNCF_width], di
	mov	es:[VBNCF_height], dx
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	al, ds:[di].VBI_bmFormat
	mov	es:[VBNCF_format], al
	mov	ax, ds:[di].VBI_xResolution
	mov	es:[VBNCF_xdpi], ax
	mov	ax, ds:[di].VBI_yResolution
	mov	es:[VBNCF_ydpi], ax
	call	MemUnlock

sendNotification:
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_FORMAT_CHANGE
	mov	dx, GWNT_BITMAP_CURRENT_FORMAT_CHANGE
	call	VisBitmapUpdateControllerLow

done:
	.leave
	ret

sendNullNotification:
	clr	bx
	jmp	sendNotification
VisBitmapNotifyCurrentFormatChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapNotifySelectStateChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out a GWNT_SELECT_STATE_CHANGE type notification
		with the proper info

PASS:		*ds:si - VisBitmap object

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	4 jun 92	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapNotifySelectStateChange	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_NOTIFY_SELECT_STATE_CHANGE
	uses	cx, dx, bp
	.enter

	;
	;  Check the bitmap's gstate for a path
	;
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock

	clr	bx					;assume NULL
	tst	bp
	jz	sendNotification

	mov	ax, size NotifySelectStateChange
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8
	call	MemAlloc
	jc	done
	push	bx					;save mem handle
	mov	es, ax
	mov	ax, 1
	call	MemInitRefCount
	
	;
	;  No ants, not clipboardable
	;
	mov	ax, ds:[di].VBI_antTimer
	tst	ax
	jz	setClipboardable

	mov	di, bp					; di <- gstate
	mov	ax, GPT_CURRENT				; want current path
	call	GrTestPath				; carry set if no path

	mov	al, 0					;assume not clipbrdable
	jc	setClipboardable
	dec	al
setClipboardable:
	mov	es:[NSSC_selectionType], SDT_GRAPHICS
	mov	es:[NSSC_selectAllAvailable], BB_TRUE
	mov	es:[NSSC_clipboardableSelection], al
	mov	es:[NSSC_deleteableSelection], al
	clr	al					;assume not pasteable
	clr	bp					;not Quick
	call	ClipboardQueryItem
	push	bx,ax					;header
	tst	bp
	jz	setPasteable

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardTestItemFormat
	jc	setPasteable
	dec	al					;it is pasteable
setPasteable:
	mov	es:[NSSC_pasteable], al
	pop	bx,ax					;header
	call	ClipboardDoneWithItem
	pop	bx					;bx <- mem handle
	call	MemUnlock

sendNotification:
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	mov	dx, GWNT_SELECT_STATE_CHANGE
	call	VisBitmapUpdateControllerLow

done:
	.leave
	ret
VisBitmapNotifySelectStateChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapUpdateControllerLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine to update a UI controller

CALLED BY:

PASS:		bx - Data block to send to controller, or 0 to send
		null data (on LOST_SELECTION) 
		cx - GenAppGCNListType
		dx - NotifyStandardNotificationTypes

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/30/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapUpdateControllerLow	proc far
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	; create the event

	call	MemIncRefCount			;one more reference
	push	bx, cx, si
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	bp, bx				; data block
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bx, cx, si

	; Create messageParams structure on stack

	mov	dx, size GCNListMessageParams	; create stack frame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, cx
	push	bx				; data block
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	
	; If data block is null, then set the IGNORE flag, otherwise
	; just set the SET_STATUS_EVENT flag

	mov	ax,  mask GCNLSF_SET_STATUS
	tst	bx
	jnz	gotFlags
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
gotFlags:
	mov	ss:[bp].GCNLMP_flags, ax
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	mov	bx, ds:[LMBH_handle]
	call	MemOwner			; bx <- owner
	clr	si

	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx				; data block
	
	add	sp, size GCNListMessageParams	; fix stack
	call	MemDecRefCount			; we're done with it 
	.leave
	ret
VisBitmapUpdateControllerLow	endp

BitmapBasicCode	ends
