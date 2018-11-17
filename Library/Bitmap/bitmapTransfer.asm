COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991, 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap
FILE:		bitmapTransfer.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	2 jun 92	Initial Version

DESCRIPTION:
	This file contains the routines related to bitmap cut/copy/paste

RCS STAMP:

	$Id: bitmapTransfer.asm,v 1.1 97/04/04 17:43:16 newdeal Exp $
------------------------------------------------------------------------------@
BitmapSelectionCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_META_CLIPBOARD_CUT

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCut	method dynamic	VisBitmapClass, MSG_META_CLIPBOARD_CUT

	.enter

	mov	cx, handle BitmapUndoStrings
	mov	dx, offset undoCutString
	call	BitmapStartUndoChain

	mov	ax, MSG_META_CLIPBOARD_COPY
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_DELETE
	call	ObjCallInstanceNoLock

	call	BitmapEndUndoChain

	.leave
	ret
VisBitmapCut	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_META_DELETE

Called by:	MSG_META_DELETE

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax,cx,dx,bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapDelete	method dynamic	VisBitmapClass, MSG_META_DELETE
	uses	cx,dx,bp
	.enter

	;
	;  See if there's a transfer gstring
	;

	clr	cx
	xchg	cx, ds:[di].VBI_transferGString
	jcxz	afterGString

	push	si
	mov	si, cx
	mov	di, si
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString
	pop	si


afterGString:

	;
	;  If we have a transfer bitmap, then we want to fill in 
	;

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	cx
	xchg	cx, ds:[di].VBI_transferBitmap
	jcxz	afterVMFile

	call	ClipboardGetClipboardFile		;bx <- VM file
	mov	dx, bx

afterVMFile:

if 1
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock

	mov	di, bp
	mov	ax, GPT_CURRENT
	call	GrTestPath
	pushf

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	popf
	jc	afterHack

	BitSet	ds:[di].VBI_undoFlags, VBUF_HAD_SELECTION_BEFORE_LAST_ACTION

afterHack:
else
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
endif

	mov	ax, ds:[di].VBI_transferBitmapPos.P_x
	mov	bx, ds:[di].VBI_transferBitmapPos.P_y


	mov	di, offset DeleteSelectionCB
	segmov	es, SEGMENT_CS, bp		; es <- vseg if XIP'ed
	mov	bp, offset undoDeleteString
	call	VisBitmapEditSelfInvalAll
	jcxz	update

	mov	bx, dx
	mov_tr	ax, cx
	clr	bp
	call	VMFreeVMChain

update:
	mov	ax, MSG_VIS_BITMAP_INVALIDATE_IF_TRANSPARENT
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_BITMAP_NOTIFY_SELECT_STATE_CHANGE
	call	ObjCallInstanceNoLock

if 1
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	BitClr	ds:[di].VBI_undoFlags, VBUF_HAD_SELECTION_BEFORE_LAST_ACTION
endif

	.leave
	ret
VisBitmapDelete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteSelectionCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		di - gstate with a path

		dx - vm file handle of save under bitmap	
		cx - vm block handle of save under bitmap (0 for none)

		ax, bx - location of save under region (if any)

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteSelectionCB	proc	far
	.enter

	push	ax, cx			;save loc, vm block

	;
	;  Save stuff
	;
	call	GrSaveState

	;
	;  Fill the path with white
	;
	mov	ax, C_WHITE
	call	GrSetAreaColor
	call	GrSetLineColor
	mov	al, SDM_100
	call	GrSetAreaMask
	mov	al, MM_COPY
	call	GrSetMixMode
	mov	cl, BITMAP_SELECTION_REGION_FILL_RULE
	call	GrFillPath
	mov	al, MM_NOP
	call	GrSetMixMode
	call	GrFillPath
	call	GrRestoreState

	pop	ax, cx			;save loc, vm block
	jcxz	done

	call	GrSaveState
	push	ax			;save x loc
	mov	al, SDM_100
	call	GrSetAreaMask
	mov_tr	ax, cx			;ax <- vm block
	pop	cx			;cx <- x 
	xchg	bx, dx			;bx <- vm file, dx <- y loc
	call	VisBitmapScaleGStateByResolution
	mov_tr	cx, ax			;cx <- vm block
	mov_tr	dx, bx			;dx <- vm file
	clr	ax, bx
	call	GrDrawHugeBitmap
	call	GrRestoreState
done:
	.leave
	ret
DeleteSelectionCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapSelectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_META_SELECT_ALL

Called by:	MSG_META_SELECT_ALL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax, cx, dx, bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSelectAll	method dynamic	VisBitmapClass, MSG_META_SELECT_ALL
	.enter

	mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_PIXELS
	call	ObjCallInstanceNoLock

	segmov	es, SEGMENT_CS, di		; es <- vseg if XIP'ed
	mov	di, offset SelectAllCB
	mov	ax, INVALIDATE_ENTIRE_FATBITS_WINDOW
	mov	bp, offset undoSelectionString
	call	VisBitmapEditSelf

if 0
	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	call	ObjCallInstanceNoLock
endif

	mov	ax, MSG_VIS_BITMAP_SPAWN_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_BITMAP_NOTIFY_SELECT_STATE_CHANGE
	call	ObjCallInstanceNoLock

	.leave
	ret
VisBitmapSelectAll	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectAllCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets the path = the passed rect (= the whole 9 yards)

Pass:		di - gstate
		cx, dx - width, height of bitmap

Return:		nothing

Destroyed:	everything (VisBitmapeditBitmap callback)

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectAllCB	proc	far
	.enter

	mov_tr	ax, cx				;save width
	mov	cx, PCT_REPLACE
	call	GrBeginPath

	mov_tr	cx, ax				;cx <- width
	clr	ax, bx
if 0
	dec	cx
	dec	dx
endif
	call	GrDrawRect
	call	GrEndPath

	.leave
	ret
SelectAllCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_META_CLIPBOARD_COPY

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCopy	method dynamic	VisBitmapClass, MSG_META_CLIPBOARD_COPY

	uses	ax, bp

	.enter

	call	VisBitmapMarkBusy

	call	ClipboardGetClipboardFile		;bx <- VM file
	clr	cx, dx				;center the selection
	call	VisBitmapGenerateTransferItem	;ax <- VM block
	jnc	markNotBusy
	clr	bp				;not RAW, not QUICK
	call	ClipboardRegisterItem
markNotBusy:
	call	VisBitmapMarkNotBusy

	mov	ax, MSG_VIS_BITMAP_NOTIFY_SELECT_STATE_CHANGE
	call	ObjCallInstanceNoLock

	.leave
	ret
VisBitmapCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_META_CLIPBOARD_PASTE

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax, cx, dx, bp

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapPaste	method dynamic	VisBitmapClass, MSG_META_CLIPBOARD_PASTE

	.enter

	mov	cx, handle BitmapUndoStrings
	mov	dx, offset undoPasteString
	call	BitmapStartUndoChain

	clr	ax				;not quick
	mov	cx, CENTER_SELECTION
	mov	dx, cx
	call	VisBitmapPasteCommon

	call	BitmapEndUndoChain

	.leave
	ret
VisBitmapPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapPasteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisBitmap
		ax - ClipboardItemFlags (CIF_QUICK)

		cx,dx - location to paste

Return:		carry set if pasted
		carry clear if no formats supported

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun 14, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapPasteCommon	proc	near

	uses	ax, cx, dx, bp

	.enter

	call	VisBitmapMarkBusy

	push	bp
	mov_tr	bp, ax
	push	cx, dx
	call	ClipboardQueryItem
	pop	cx, dx	
	tst_clc	bp
	pop	bp
	jz	markNotBusy			;if no formats, done

	push	bx, ax				;save header

	;
	;	Check for CIF_GRAPHICS_STRING format
	;
	push	cx, dx				;save coords
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardRequestItemFormat
	pop	cx, dx				;cx,dx <- coords
	tst_clc	ax
	jz	pop2MarkNotBusy

	;
	; Set the transfer gstring
	;

	sub	sp, size VisBitmapSetTransferGStringParams
	mov	bp, sp
	mov	ss:[bp].VBSTGSP_vmFile, bx
	mov	ss:[bp].VBSTGSP_vmBlock, ax
	mov	ss:[bp].VBSTGSP_location.P_x, cx
	mov	ss:[bp].VBSTGSP_location.P_y, dx
	mov	ax, MSG_VIS_BITMAP_SET_TRANSFER_GSTRING
	call	ObjCallInstanceNoLock
	add	sp, size VisBitmapSetTransferGStringParams

	pop	bx, ax				;bx:ax <- header
	stc					;pasted

markNotBusy:
	pushf
	call	ClipboardDoneWithItem
	call	VisBitmapMarkNotBusy
	popf

	.leave
	ret

pop2MarkNotBusy:
	pop	bx, ax				;header
	jmp	markNotBusy
VisBitmapPasteCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a quick move/copy operation.

CALLED BY:	via MSG_META_LARGE_START_MOVE_COPY, VisTextStartMoveCopy
PASS:		*ds:si	= Instance
		cx,dx - location

RETURN:		ax	= MouseReturnFlags

DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapStartMoveCopy		method dynamic	VisBitmapClass,
				MSG_META_START_MOVE_COPY
	.enter

	;
	; See if the event is in our selected path
	;	

	call	ConvertVisToBitmapCoords

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp
	tst	di
	jz	handledDone

	mov_tr	ax, cx
	mov	bx, dx
	mov	cl, BITMAP_SELECTION_REGION_FILL_RULE

	call	GrTestPointInPath
	jnc	replay

if 1
	;
	; Start the UI part of the quick move
	;
	mov_tr	cx, ax				;cx <- x
	push	si				;save instance chunk handle.
	mov	bx, ds:[LMBH_handle]
	mov	di, si
	mov	si, mask CQTF_NOTIFICATION
	mov	ax, CQTF_MOVE
	test	bp, mask UIFA_COPY shl 8
	jz	startQuick
	mov	ax, CQTF_COPY
startQuick:
	call	ClipboardStartQuickTransfer
	pop	si				;restore instance chunk handle.
	jc	handledDone			; quick-transfer already in
						;	progress, can't start
						;	another

else
	;
	; Start the UI part of the quick move
	;
	mov_tr	cx, ax				;cx <- x
	mov	ax, CQTF_MOVE
	test	bp, mask UIFA_COPY shl 8
	jz	gotCursor
	mov	ax, CQTF_COPY

gotCursor:

	;
	;  Calculate the region for this pup
	;
	push	cx, dx				;mouse loc.
	push	ax				;save CQTF
	pushdw	dssi				;save VisBitmap

	;
	;  We need to get the fptr to the video driver if we want
	;
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, VUQ_VIDEO_DRIVER
	call	ObjCallInstanceNoLock
	mov	dx, mask CQTF_NOTIFICATION	;assume no path
	jnc	afterRegion

	mov_tr	bx, ax				; bx <- driver handle
	call	GeodeInfoDriver			; ds:[si] = DriverInfoStruct
	movdw	dxax, ds:[si].DIS_strategy

	;
	;  Get our lil' region
	;
	mov	cl, BITMAP_SELECTION_REGION_FILL_RULE
	call	GrGetPathRegion
	jc	afterRegion

	;
	;  Lock the region so that it's in memory for
	;  ClipboardStartQuickTransfer
	;
	push	ax				;save strategy
	call	MemLock
	pop	ax				;dxax <- driver strategy

	popdw	dssi				;*ds:si <- VisBitmap
	pop	cx				;cx <- CQTF

	sub	sp, size ClipboardQuickTransferRegionInfo
	mov	bp, sp
	movdw	ss:[bp].CQTRI_strategy,dxax
	mov	ss:[bp].CQTRI_region.handle, bx
	clr	ss:[bp].CQTRI_region.offset
	movdw	ss:[bp].CQTRI_regionPos,
		ss:[bp][(size ClipboardQuickTransferRegionInfo)], ax
	mov	dx, mask CQTF_NOTIFICATION or mask CQTF_USE_REGION
	jmp	startQuick

afterRegion:
	popdw	dssi				;*ds:si <- VisBitmap
	pop	cx, bx, di			;cx <- cursor, bx,di <- mouse

startQuick:

	mov	bx, ds:[LMBH_handle]		;^lbx:di <- VisBitmap
	mov	di, si
	mov_tr	ax, cx				;ax <- cursor
	mov	si, dx				;si <- flags
	clr	cx, dx
	call	ClipboardStartQuickTransfer

	lahf					;save return flags

	test	si, mask CQTF_USE_REGION
	jz	afterRegionCleanup

	;
	;  Free the region we allocated

if 0		;maybe not, as this caused hideous death

	mov	bx, ss:[bp].CQTRI_region.handle
	call	MemFree

endif

	add	sp, size ClipboardQuickTransferRegionInfo 

afterRegionCleanup:
	sahf					;restore flags
	mov	si, di				;*ds:si <- VisBitmap

	jc	handledDone			; quick-transfer already in
						;	progress, can't start
						;	another

endif

	;
	; Register the transfer item
	;
	call	ClipboardGetClipboardFile		;bx = VM file
	call	VisBitmapGenerateTransferItem	;ax = VM block
	mov	bp, mask CIF_QUICK		;not RAW, QUICK
	call	ClipboardRegisterItem
	jc	handledDone

	;
	; Prepare to use the mouse
	; (will be released when mouse leaves visible bounds -- on a
	;  MSG_VIS_LOST_GADGET_EXCL or MSG_META_VIS_LEAVE)
	;
	call	VisTakeGadgetExclAndGrab

	;
	; sucessfully started UI part of quick-transfer and sucessfully
	; registered item, now allow pointer to roam around globally for
	; feedback
	;
	mov	ax, MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER
	call	ObjCallInstanceNoLock

	mov	cx, handle BitmapUndoStrings
	mov	dx, offset undoTransferString
	call	BitmapStartUndoChain		;will be closed on notify

handledDone:

	mov	ax, mask MRF_PROCESSED
done:
	.leave
	ret

replay:
	mov	ax, mask MRF_REPLAY
	jmp	done
VisBitmapStartMoveCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish a quick move/copy operation.

CALLED BY:	via MSG_META_LARGE_END_MOVE_COPY, VisTextEndMoveCopy
PASS:		*ds:si	= Instance
		cx,dx - location
		bp high - UIFA

RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapEndMoveCopy	method dynamic	VisBitmapClass,
			MSG_META_END_MOVE_COPY
	.enter

	call	ConvertVisToBitmapCoords

	push	cx, dx				;save coords

	;
	; if we were doing feedback, stop it now
	;
	call	VisReleaseMouse			; Release mouse

	;
	; Find the generic window group that this object is in, and bring
	; the window to the top.
	;
	push	ds:[LMBH_handle], si		; Save object OD
	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	bx, segment GenClass
	mov	si, offset GenClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; Create ClassedEvent
	mov	cx, di				; cx <- handle to ClassedEvent
	pop	bx, si				; Restore object OD
	clr	di
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP	; Send the message upward
	call	ObjMessage

	;
	; Bring app itself to top of heap
	;
	push	bp				;save UIFA
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	GenCallApplication

	;
	;	Make sure we can paste the transfer item
	;
	mov	bp, mask CIF_QUICK
	call	VisBitmapTestSupportedTransferFormats
	mov	bx, cx
	pop	cx				;cx <- UIFA
	mov	bp, mask CQNF_NO_OPERATION	;assume no op
	jnc	endQuick
	xchg	cx, bp				;cx <- no op,
						;bp <- UIFA
	tst	bx
	jz	doPaste

	;
	;	Source is pasteable, so send it
	;	a MSG_META_DELETE to clear its selection
	;	if we're doing a move (instead of a copy)
	;

	mov	cx, mask CQNF_MOVE or mask CQNF_SOURCE_EQUAL_DEST
	cmp	dx, si
	jne	different
	cmp	bx, ds:[LMBH_handle]
	je	checkOverride
different:
	mov	cx, mask CQNF_COPY
checkOverride:
	test	bp, mask UIFA_MOVE shl 8
	jz	checkCopyOverride

	BitClr	cx, CQNF_COPY
	BitSet	cx, CQNF_MOVE
checkCopyOverride:

	test	bp, mask UIFA_COPY shl 8
	jz	afterCopyOverride

	BitClr	cx, CQNF_MOVE
	BitSet	cx, CQNF_COPY

afterCopyOverride:
	test	cx, mask CQNF_MOVE
	jz	doPaste

	xchg	si, dx
	mov	ax, MSG_META_DELETE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, dx
doPaste:
	;
	;  Paste it! ss:bp <- location
	;
	mov	ax, mask CIF_QUICK
	mov	bp, cx				;bp <- ClipboardQuickNotifyFlags
	pop	cx, dx				;cx,dx <- coords
	push	cx, dx
	call	VisBitmapPasteCommon
	
endQuick:
	pop	cx, dx
	;
	; stop UI part of quick-transfer (will clear default quick-transfer
	; cursor, etc.)
	; (this is done regardless of whether we accepted an item or not)
	;
	call	ClipboardEndQuickTransfer		; Finish up
	mov	ax, mask MRF_PROCESSED		; Signal: handled the event

	.leave
	ret
VisBitmapEndMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapNotifyQuickTransferConcluded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminates the undo chain that was begun on the start	
		move copy.

PASS:		bp - ClipboardQuickNotifyFlags

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10 dec 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapNotifyQuickTransferConcluded	method dynamic	VisBitmapClass,
			MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED
	.enter

	call	BitmapEndUndoChain

	call	VisReleaseMouse

if 0
	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	call	ObjCallInstanceNoLock
endif

	.leave
	ret
VisBitmapNotifyQuickTransferConcluded	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapTestSupportedTransferFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Tests for "pasteable" formats on the clipboard

Pass:		bp - ClipboardItemFlags (CIF_QUICK)

Return:		carry set if pasteable format exists
			^lcx:dx - owner
		carry clear if no pasteable format exists
			cx,dx - trashed

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapTestSupportedTransferFormats	proc	far
	uses	ax, bx, bp
	.enter

	call	ClipboardQueryItem
	tst_clc	bp
	jz	doneWithTransfer

	push	cx, dx				;save owner OD
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardTestItemFormat
	cmc
	pop	cx, dx				;^lcx:dx <- owner

doneWithTransfer:
	pushf
	call	ClipboardDoneWithItem
	popf

	.leave
	ret
VisBitmapTestSupportedTransferFormats	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapCreateGStringTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for
		MSG_VIS_BITMAP_CREATE_GSTRING_TRANSFER_FORMAT

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		bp - vm file handle
		cx,dx - origin
		
Return:		carry set if successful
			ax - vm block handle of transfer item
			cx,dx - wdith, height of transfer

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  4, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCreateGStringTransferFormat	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_CREATE_GSTRING_TRANSFER_FORMAT

vmFile		local	hptr	push	bp
originX		local	word	push	cx
originY		local	word	push	dx
visBitmapChunk	local	word	push	si
bitmapGState	local	hptr
subBitmapFile	local	hptr
subBitmapBlock	local	word
pathLeft	local	word
pathTop		local	word

	.enter

	;    Create gstring in vm file
	;

	mov	bx, ss:[vmFile]				;bx <- file handle
	mov_tr	ax,si					;body chunk
	mov	cl, GST_VMEM
	call	GrCreateGString
	push	si					;vm block handle
	mov_tr	si,ax					;body chunk

	mov	bx, ds:[si]
	add	bx, ds:[bx].VisBitmap_offset
	tst	ds:[bx].VBI_transferGString
	jz	createNew

	;
	;	The VisBitmap already has a transfer gstring, so we'll
	;	use it.
	;
	mov	si, ds:[bx].VBI_transferGString

	;
	;  The caller wants the transfer item centered about the origin,
	;  and we're sitting with a gstring centered around a different
	;  origin, so spew the old into the new at the appropriate offset
	;
	mov	ax, ds:[bx].VBI_transferGStringPos.P_x
	sub	ax, ss:[originX]
	mov	bx, ds:[bx].VBI_transferGStringPos.P_y
	sub	bx, ss:[originY]
	clr	dx
	call	GrDrawGString
	call	GrEndGString

	call	GrGetGStringBounds
	sub	cx, ax					;cx <- width
	sub	dx, bx					;dx <- height
	jmp	popBlockSuccess

createNew:
	;
	;  Set the gstring's clip path to our clip path
	;
	push	di					;save gstring

	push	bp					;save locals

	mov	ax, MSG_VIS_BITMAP_MAKE_SURE_NO_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp
	pop	bp					;ss:[bp] <- locals
	mov	ss:[bitmapGState], di

	mov	ax, GPT_CURRENT
	call	GrGetPathBounds
	LONG	jc	pop2Error

	;
	;  Create a "sub" bitmap so that the transfer item doesn't
	;  store the whole thing
	;
	mov	ss:[pathLeft], ax
	mov	ss:[pathTop], bx
	sub	cx, ax				;cx <- width
	sub	dx, bx				;dx <- height

	inc	cx				;another "what the hell"
	inc	dx				;that "fixes" a bug

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	test	ds:[di].VBI_undoFlags, mask VBUF_MOUSE_EVENTS_IN_BITMAP_COORDS
	pushf
	BitSet	ds:[di].VBI_undoFlags, VBUF_MOUSE_EVENTS_IN_BITMAP_COORDS
	
	call	BitmapGetBitmap			;bx <- bitmap handle

	popf
	jnz	translate

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	BitClr	ds:[di].VBI_undoFlags, VBUF_MOUSE_EVENTS_IN_BITMAP_COORDS
	pop	di

translate:

	;
	;  Apply the reverse translation of the passed origin
	;
	
	mov	ss:[subBitmapFile], bx
	mov	ss:[subBitmapBlock], ax
	mov_tr	ax, dx					;ax <- height
	pop	di					;di <- gstring

	push	cx, ax					;save width, height
	mov	cx, ss:[originX]
	mov	dx, ss:[originY]

	neg	cx
	neg	dx

	call	GrSaveTransform

	push	cx, dx
	clr	cx, dx
	call	VisBitmapScaleGStateByInverseResolution
	pop	dx, bx
	clr	ax, cx
	call	GrApplyTranslation

	;
	;	Set the clip path in the gstring.
	;
	
	push	di					;save gstring
	mov	di, ss:[bitmapGState]
	mov	bx, GPT_CURRENT			; get the current path
	call	GrGetPath

	call	MemLock
	xchg	bx, ax				;bx <- gstring seg.
						;ax <- gstring handle
	clr	si				; GString => BX:SI
	mov	cl, GST_PTR
	call	GrLoadGString			; GString handle => SI
	pop	di				; di <- transfer gstring
	push	ax				; save mem handle
	clr	ax,bx,dx			; GSControl => DX
	call	GrDrawGString			; re-create the path

	call	GrSaveState

	mov	cx, PCT_INTERSECTION
	mov	dl, BITMAP_SELECTION_REGION_FILL_RULE
	call	GrSetClipPath

	pop	bx				; bx <- mem handle
	mov	dl, GSKT_LEAVE_DATA
	push	di
	clr	di
	call	GrDestroyGString
	pop	di
	call	MemFree				; free the path-GString handle

	;
	;	Draw the bitmap to the gstring
	;
	mov	cx, ss:[pathLeft]
	mov	dx, ss:[pathTop]
	mov	si, ss:[visBitmapChunk]
	call	VisBitmapScaleGStateByResolution
	mov	dx, ss:[subBitmapFile]
	mov	cx, ss:[subBitmapBlock]
	clr	ax, bx
	call	GrDrawHugeBitmap
	call	GrRestoreState
	call	GrRestoreTransform

	mov	bx, dx
	mov	ax, cx
	push	bp
	clr	bp
	call	VMFreeVMChain
	pop	bp

	;
	;	End the string
	;
	call	GrEndGString

	;    Destroy and kill the gstring for now
	;    though we will eventually want to return it as a vm chain
	;
	mov	dl,GSKT_LEAVE_DATA
	mov	si, di					;si <- GString handle
	call	GrDestroyGString

	pop	cx, dx					;cx,dx <- width, height
popBlockSuccess:
	pop	ax					;ax <- block handle
	stc
done:
	.leave
	ret

pop2Error:
	pop	ax, ax
	clc
	jmp	done
VisBitmapCreateGStringTransferFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapCreateBitmapTransferFormatFromGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Utility routine to construct a bitmap from the passed gstring

Pass:		*ds:si = VisBitmap object

		bp - vm file handle
		ax - vm block handle of gstring

Return:		ax - vm block handle of huge bitmap
		cx, dx - dimensions

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  4, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCreateBitmapTransferFormatFromGString	proc	near
	uses	bx, di, bp, si
	.enter

	;
	;  Load the GString so we can play it
	;
	push	si				;save bitmap chunk
	mov	cl, GST_VMEM
	mov	si, ax
	mov	bx, bp
	call	GrLoadGString			;si <- gstring

	clr	di, dx
	call	GrGetGStringBounds

	mov	di, si				;di <- gstring
	pop	si				;*ds:si <- VisBitmap

	;
	;  Calculate the dimensions
	;
	sub	cx, ax
	sub	dx, bx

	push	cx, dx				;save dimensions

	push	ax, bx				;save coords

	;
	;  Allocate our bitmap
	;
	mov	bx, bp				;bx <- vm file
	push	di				;save gstring
	call	CreateBitmapCommon
	pop	si				;si <- gstring

	pop	dx, bx				;dx,bx <- coords
	push	ax				;save block handle
	clr	ax, cx

	;
	; Apply the inverse translation so that everything comes out nice
	;
	negwwf	dxcx
	negwwf	bxax
	call	GrApplyTranslation

	call	BitmapWriteGStringToBitmapCommon

	clr	di
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString

	pop	ax				;ax <- vm block handle
	pop	cx, dx				;cx,dx <- dimensions

	.leave
	ret
VisBitmapCreateBitmapTransferFormatFromGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGetBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns a bitmap that is a sub portion of the VisBitmap's
		bitmap. This routine exists solely due to the fact that
		GrGetBitmap can't return a masked bitmap

Pass:		*ds:si - VisBitmap
		ax,bx - left, upper coord of sub bitmap
		cx,dx - width, height of sub bitmap

Return:		bx - vm file handle of sub bitmap
		ax - vm block handle of sub bitmap
		di - gstate to bitmap

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 26, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGetBitmap	proc	near
	uses	cx, dx, bp, di
	.enter

if 0
	;
	;  There seems to be a problem with the graphics system drawing
	;  a bitmap to another bitmap at funky offsets, so for the time
	;  being, we'll allocate the full bitmap
	;

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock

	mov	bx, cx
	mov	ax, dx
	mov	dx, bx

if 0	;fucked up
	;
	;  If anyone ever decides to uncomment this part, please
	;  make sure to test the VBI_flags to make sure the bitmap
	;  really needs to be compacted; otherwise you'll screw up
	;  the icon editor.  -stevey 4/14/95
	;
	call	GrCompactBitmap
	mov_tr	ax, cx
else
	clr	bp
	call	VMCopyVMChain
endif

	.leave
	ret
else
	push	ax, bx			;save coords

	;
	;  Allocate our sub bitmap
	;


	call	ClipboardGetClipboardFile		;bx <- VM file
	call	CreateBitmapCommon

	mov_tr	bp, ax			;bp <- vm block handle

	;
	;  Draw the real bitmap to the sub bitmap at the proper offset
	;

	clr	ax, dx
	call	GrSetBitmapMode

	pop	dx, cx			;coords
	push	bx, bp			;save sub bitmap

	mov	bx, cx
	clr	ax, cx
	call	GrUntransformWWFixed
	negwwf	dxcx
	negwwf	bxax
	call	GrApplyTranslation

	clr	cx, dx
	mov	bp, di			;bp <- sub bitmap gstate
	mov	ax, MSG_VIS_BITMAP_DRAW_BITMAP_TO_GSTATE
	call	ObjCallInstanceNoLock

	push	dx
	mov	ax, mask BM_EDIT_MASK
	clr	dx
	call	GrSetBitmapMode
	test	ax, mask BM_EDIT_MASK
	pop	dx
	jz	done

	mov	al, MM_SET
	call	GrSetMixMode

	mov	ax, MSG_VIS_BITMAP_DRAW_BITMAP_TO_GSTATE
	call	ObjCallInstanceNoLock

done:
	call	GrDestroyState		;kill the bitmap's gstate
	pop	bx, ax			;bx <- vm file handle of sub bitmap
					;ax <- vm block handle of sub bitmap
	.leave
	ret
endif
BitmapGetBitmap	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	VisBitmapGenerateTransferItem

DESCRIPTION:	Generate a transfer item for the currently selected region

CALLED BY:	

PASS:
	*ds:si - GrObjBody
	bx - vm file handle to store gstring
	cx, dx - origin of gstring to be created

RETURN:
	carry set if successful
		ax - VM block of transfer item (in clipboard's VM file)

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
VisBitmapGenerateTransferItem	proc	near	uses bx, cx, dx, si, di, bp, es

	class	VisBitmapClass
	.enter

	mov	bp, bx				;bp <- vm file handle

	mov	ax, MSG_VIS_BITMAP_CREATE_GSTRING_TRANSFER_FORMAT
	call	ObjCallInstanceNoLock		;cx <- vm block handle
	LONG	jnc	done
	push	cx				;save width
	push	dx				;save height
	push	ax				;save block handle

	call	VisBitmapCreateBitmapTransferFormatFromGString

	push	cx				;save width
	push	dx				;save height
	push	ax				;save block handle

	push	ds:[LMBH_handle]		;save object handle

	; allocate block for transfer structure

	mov	cx, size ClipboardItemHeader
	clr	ax				;user ID?
	call	VMAlloc
	mov	dx, ax				;save block handle in dx
	call	VMLock
	mov	es, ax				;ds = transfer item

	; set up header

	mov	es:[CIH_sourceID].chunk, si	; chunk
	pop	bx				;bx <- object handle
	mov	es:[CIH_sourceID].handle, bx	; handle
	mov	es:[CIH_owner].chunk, si
	mov	es:[CIH_owner].handle, bx
	mov	es:[CIH_formatCount], 2
	mov	es:[CIH_formats][0].CIFI_format.CIFID_manufacturer, \
							MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats][0].CIFI_format.CIFID_type, CIF_GRAPHICS_STRING
	mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].\
		CIFI_format.CIFID_manufacturer, MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].\
		CIFI_format.CIFID_type, CIF_BITMAP

	pop	es:[CIH_formats][(size ClipboardItemFormatInfo)].\
		CIFI_vmChain.high
	mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].\
		CIFI_vmChain.low, 0
	pop	es:[CIH_formats][(size ClipboardItemFormatInfo)].CIFI_extra2
	pop	es:[CIH_formats][(size ClipboardItemFormatInfo)].CIFI_extra1

	pop	es:[CIH_formats][0].CIFI_vmChain.high
	clr	es:[CIH_formats][0].CIFI_vmChain.low
	pop	es:[CIH_formats][0].CIFI_extra2		;height
	pop	es:[CIH_formats][0].CIFI_extra1		;width

	; copy name

	push	bx, ds
	mov	bx, handle BitmapUndoStrings
	call	MemLock
	mov	ds, ax

assume	ds:BitmapUndoStrings
	mov	si, ds:[unnamedBitmapString]	;ds:si <- source string
	ChunkSizePtr	ds, si, cx		;cx <- length of string
	mov	di, offset CIH_name		;es:di <- dest
	rep	movsb
assume	ds:nothing
	
	call	MemUnlock
	pop	bx, ds

	call	VMUnlock
	mov_tr	ax, dx				;ax <- block handle
	stc
done:
	.leave
	ret
VisBitmapGenerateTransferItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapSetTransferGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Copy the passed gstring to be the VisBitmap's transfer gstring

PASS:		*ds:si	= VisBitmapClass object
		ds:di	= VisBitmapClass instance data

		ss:[bp] - VisBitmapSetTransferGStringParams

RETURN:		
		nothing		

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:	
		Invalidate the area if an old string exists.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetTransferGString	method	dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_SET_TRANSFER_GSTRING
	uses	cx,dx

passedParams	local	nptr.VisBitmapSetTransferGStringParams	push	bp
transferGString	local	hptr
gstringBounds	local	Rectangle

	.enter

if 0
	mov	ax, MSG_VIS_BITMAP_FORCE_CURRENT_EDIT_TO_FINISH
	call	ObjCallInstanceNoLock
endif

	call	WriteTransferGStringIfAny

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ax, ds:[LMBH_handle]
	movdw	ds:[di].VBI_finishEditingOD, axsi
	mov	ds:[di].VBI_finishEditingMsg, MSG_META_DUMMY

	;    Copy the new string
	;

	call	ClipboardGetClipboardFile		;bx <- VM file
	mov	dx, bx

	push	bp
	mov	bp, ss:[passedParams]
	mov	bx, ss:[bp].VBSTGSP_vmFile	; passed vm file handle
	mov	ax, ss:[bp].VBSTGSP_vmBlock	; passed vm block handle

	clr	bp
	call	VMCopyVMChain
	pop	bp

	mov	cl, GST_VMEM
	mov	bx, dx
	push	si				;save object
	xchg	si, ax				;ax <- VisBitmap chunk,
						;si <- gstring chunk
	call	GrLoadGString			;si <- transfer gstring
	mov_tr	bx, ax				;*ds:bx <- VisBitmap
	mov	bx, ds:[bx]
	add	bx, ds:[bx].VisBitmap_offset
	mov	ds:[bx].VBI_transferGString, si	;save transfer gstring

	mov	ss:[transferGString], si
	clr	dx, di
	call	GrGetGStringBounds
	pop	si				;*ds:si <- VisBitmap

	mov	ss:[gstringBounds].R_left, ax
	mov	ss:[gstringBounds].R_top, bx
	mov	ss:[gstringBounds].R_right, cx
	mov	ss:[gstringBounds].R_bottom, dx

	;
	; If the gstring is supposed to end up centered, calculate the
	; center right here
	;
	; the net result is that we want the bitmap's center - gstring center
	;

	push	bp
	mov	bp, ss:[passedParams]
	cmp	ss:[bp].VBSTGSP_location.P_x, CENTER_SELECTION
	jne	afterCenter

	push	ax, cx, dx
	mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_PIXELS
	call	ObjCallInstanceNoLock
	shr	cx
	shr	dx

	mov	ss:[bp].VBSTGSP_location.P_x, cx
	mov	ss:[bp].VBSTGSP_location.P_y, dx
	pop	ax, cx, dx

	push	cx, dx
	add	cx, ax
	add	dx, bx
	sar	cx
	sar	dx
	sub	ss:[bp].VBSTGSP_location.P_x, cx
	sub	ss:[bp].VBSTGSP_location.P_y, dx
	pop	cx, dx

afterCenter:
	pop	bp

	;
	;
	;  Create a bitmap that's the height and width of the passed gstring
	;
	sub	cx, ax
	sub	dx, bx

	;
	;  Calculate the upper left of the transfer bitmap
	;

	xchg	ax, cx
	xchg	bx, dx
	call	VisBitmapConvertVisPointToBitmapPoint
	xchg	ax, cx
	xchg	bx, dx

	push	bp
	mov	bp, ss:[passedParams]
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	add	ax, ss:[bp].VBSTGSP_location.P_x
	mov	ds:[di].VBI_transferBitmapPos.P_x, ax
	add	bx, ss:[bp].VBSTGSP_location.P_y
	mov	ds:[di].VBI_transferBitmapPos.P_y, bx
	push	ax
	movdw	ds:[di].VBI_transferGStringPos, ss:[bp].VBSTGSP_location, ax
	pop	ax

	;
	;  Save this piece of the bitmap before writing over it so
	;  we can restore it later if you user doesn't like it
	;
	inc	cx
	inc	dx				;what the hell
	call	BitmapGetBitmap
	pop	bp
	push	ax				;save vm block

	;
	;  OK: a quick hack to keep things in line: we're going to
	;  clear out the transfer gstring here, 'cause we don't want
	;  it written yet
	;

	clr	ax
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	xchg	ax, ds:[di].VBI_transferGString
	push	ax					;save transfer gstring
	
	segmov	es, SEGMENT_CS, di			; es <- vseg if XIP'ed
	mov	di, offset WriteTransferGStringCB
	mov	ax, INVALIDATE_ENTIRE_FATBITS_WINDOW
	mov	bx, ss:[transferGString]
	push	bp

	mov	bp, ss:[passedParams]
	mov	cx, ss:[bp].VBSTGSP_location.P_x
	mov	dx, ss:[bp].VBSTGSP_location.P_y
	mov	bp, offset undoTransferString
	call	VisBitmapEditSelf

if 0
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
endif

	mov	ax, MSG_VIS_BITMAP_SPAWN_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_BITMAP_NOTIFY_SELECT_STATE_CHANGE
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset

	pop	bp				;ss:bp <- locals
	pop	ds:[di].VBI_transferGString
	pop	ds:[di].VBI_transferBitmap	;vm block handle

	.leave
	ret
if 0
fakePath:
	;
	;  We're given a gstring with no path, so we'll have to
	;  make one ourselves so that the marching ants so up
	;

	mov	cx, PCT_REPLACE
	call	GrBeginPath
	mov	cx, ss:[gstringBounds].R_right
	sub	cx, ss:[gstringBounds].R_left
	mov	dx, ss:[gstringBounds].R_bottom
	sub	dx, ss:[gstringBounds].R_top
	clr	ax, bx
	call	GrDrawRect
	call	GrEndPath
	jmp	copyPath
endif
VisBitmapSetTransferGString	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteTransferGStringCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisBitmap
		di - destination gstate
		bx - source gstate

		cx, dx - offset at which to draw the gstring

Return:		nothing

Destroyed:	This is a VisBitmapEditBitmap callback routine, which
		can trash anything it damn well pleases.

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteTransferGStringCB	proc	far

	.enter

	tst	bx
	jz	done

	;
	;  Kill the current path
	;
	push	cx
	mov	cx, PCT_NULL
	call	GrBeginPath
	pop	cx

	call	GrSaveTransform
	call	VisBitmapScaleGStateByResolution

	mov	si, bx					;si <- gstring

	call	GrGetBitmapMode
	jc	notMask

	test	ax, mask BM_EDIT_MASK
	jz	notMask

	;
	;  We are drawing to a mask, so use our special routine
	;
	
	clr	ax, bx
	call	BitmapDrawGStringToMask
	jmp	afterDraw

notMask:
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos

	clr	ax, bx, dx
	call	GrDrawGString

afterDraw:
	mov	ax, GPT_CURRENT
	call	GrTestPath
	jc	fakePath

restoreTransform:
	call	GrRestoreTransform

done:
	.leave
	ret

fakePath:

	push	di	
	clr	di, dx
	call	GrGetGStringBounds
	pop	di
	jc	restoreTransform

	push	cx
	mov	cx, PCT_REPLACE
	call	GrBeginPath
	pop	cx

	inc	cx
	inc	dx

	call	GrDrawRect
	call	GrEndPath
	jmp	restoreTransform
WriteTransferGStringCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapScaleGStateByResolution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisBitmap
		di - gstate
		cx, dx - amount to translate before scaling

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 14, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapScaleGStateByResolution	proc	far
	class	VisBitmapClass
	uses	ax, bx, cx, dx, bp
	.enter

	;
	;  Translate to passed location
	;
	mov	bx, dx
	mov	dx, cx
	clr	ax, cx
	call	GrApplyTranslation

	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset

	mov	dx, ds:[bp].VBI_yResolution
	mov	bx, 72
	clr	ax, cx
	call	GrUDivWWFixed

	pushwwf	dxcx

	mov	dx, ds:[bp].VBI_xResolution
	clr	cx
	call	GrUDivWWFixed

	popwwf	bxax
	call	GrApplyScale

	.leave
	ret
VisBitmapScaleGStateByResolution	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapScaleGStateByInverseResolution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisBitmap
		di - gstate
		cx, dx - amount to translate before scaling

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 14, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapScaleGStateByInverseResolution	proc	far
	class	VisBitmapClass
	uses	ax, bx, cx, dx, bp
	.enter

	;
	;  Translate to passed location
	;
	mov	bx, dx
	mov	dx, cx
	clr	ax, cx
	call	GrApplyTranslation

	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset

	mov	bx, ds:[bp].VBI_yResolution
	mov	dx, 72
	clr	ax, cx
	call	GrUDivWWFixed

	pushwwf	dxcx

	mov	bx, ds:[bp].VBI_xResolution
	mov	dx, 72
	clr	ax, cx
	call	GrUDivWWFixed

	popwwf	bxax
	call	GrApplyScale

	.leave
	ret
VisBitmapScaleGStateByInverseResolution	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapEditSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap sets up a MSG_VIS_BITMAP_EDIT_BITMAP to itself

Pass:		*ds:si - VisBitmap object

		es:di - vfptr to callback graphics routine

			* ToolEditBitmap will not work for graphics
			  routines that depend upon  ds, es, di, or si
			  as parameters!

		ax,bx,cx,dx - params to callback routine

		bp - chunk handle of undo string within BitmapUndoStrings

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapEditSelf	proc	far
	class	VisBitmapClass
	uses	ax, cx, bp
	.enter

CheckHack <size VisBitmapEditBitmapParams eq (size word * 14)>

	pushdw	esdi		;mask callback
	pushdw	esdi		;normal callback
	mov	di, C_BLACK
	push	di

	;
	;  Assume inval rect is ax,bx,cx,dx
	;
	push	dx
	push	cx
	push	bx
	push	ax

	;
	;  Save params

	push	dx
	push	cx
	push	bx
	push	ax

	;
	;  Tell the VisBitmap that we're going to make an edit
	;

	mov	ax, handle BitmapUndoStrings
	pushdw	axbp
	mov	bp, MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	push	bp
	push	ds:[LMBH_handle], si

	mov	bp, sp

	mov	ax, MSG_VIS_BITMAP_GET_EDITING_GSTATES
	call	ObjCallInstanceNoLock

	add	sp, size VisBitmapGetEditingGStatesParams

	push	cx					;save edit ID

	mov	bp, sp
	
	mov	ax, MSG_VIS_BITMAP_EDIT_BITMAP
	call	ObjCallInstanceNoLock

	add	sp, size VisBitmapEditBitmapParams

if 1
	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	call	ObjCallInstanceNoLock
endif

	.leave
	ret
VisBitmapEditSelf	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapEditSelfInvalAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Just like VisBitmapEditSelf, except it invalidates
		the entire fatbits window, for use when ax,bx,cx,dx
		aren't the inval rect.

Pass:		*ds:si - VisBitmap object

		es:di - vfptr to callback graphics routine

			* ToolEditBitmap will not work for graphics
			  routines that depend upon  ds, es, di, or si
			  as parameters!

		ax,bx,cx,dx - params to callback routine

		bp - chunk handle of undo string within BitmapUndoStrings

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapEditSelfInvalAll	proc	far
	class	VisBitmapClass
	uses	ax, cx, bp
	.enter

CheckHack <size VisBitmapEditBitmapParams eq (size word * 14)>

	pushdw	esdi		;mask callback
	pushdw	esdi		;normal callback
	mov	di, C_BLACK
	push	di

	;
	;  Assume inval rect is ax,bx,cx,dx
	;
	mov	di, INVALIDATE_ENTIRE_FATBITS_WINDOW
	push	di
	push	di
	push	di
	push	di

	;
	;  Save params

	push	dx
	push	cx
	push	bx
	push	ax

	;
	;  Tell the VisBitmap that we're going to make an edit
	;

	mov	ax, handle BitmapUndoStrings
	pushdw	axbp
	mov	bp, MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	push	bp
	push	ds:[LMBH_handle], si

	mov	bp, sp

	mov	ax, MSG_VIS_BITMAP_GET_EDITING_GSTATES
	call	ObjCallInstanceNoLock

	add	sp, size VisBitmapGetEditingGStatesParams

	push	cx					;save edit ID

	mov	bp, sp
	
	mov	ax, MSG_VIS_BITMAP_EDIT_BITMAP
	call	ObjCallInstanceNoLock

	add	sp, size VisBitmapEditBitmapParams

if 1
	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	call	ObjCallInstanceNoLock
endif

	.leave
	ret
VisBitmapEditSelfInvalAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		di - destination gstate
		bx - source gstate

		cx, dx - offset at which to copy the path

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyPath	proc	far
	uses	ax, bx, cx, dx, di, si
	.enter

	mov_tr	ax, di				;ax <- dest gstate
	mov	di, bx				;di <- source gstate
	mov	bx, GPT_CURRENT			; get current path
	call	GrGetPath
	jc	done

	mov_tr	di, ax				;di <- dest gstate
	push	bx
	call	MemLock
	mov_tr	bx, ax

	mov_tr	ax, cx				;ax <- left
	mov	cl, GST_PTR
	clr	si
	call	GrLoadGString

	mov	bx, dx				;bx <- top
	clr	dx
	call	GrDrawGString

	clr	di
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString

	pop	bx
	call	MemFree

done:
	.leave
	ret
CopyPath	endp

BitmapSelectionCode	ends
