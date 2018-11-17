COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ClipSamp (Clipboard Sample application)
FILE:		clipsamp.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/91		Initial version

DESCRIPTION:
	This file source code for the ClipSamp application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

	ClipSamp demonstrates two UI mechanisms:  the Clipboard and
	quick-transfer.  The clipboard is demonstrated with a Cut/Copy/Paste
	Edit menu.  The Paste menu item is enabled or disabled depending on
	the compatibility of the current clipboard item.  ClipSamp can source
	a CIF_TEXT quick-transfer (copy-only, no move) and can recieve a
	CIF_TEXT quick-transfer.  Mouse-pointer-shape feedback is given when
	ClipSamp is the potential quick-transfer destination.  ClipSamp also
	shows how to handle notification when a ClipSamp-sourced quick-transfer
	item is processed by some destination object.

RCS STAMP:
	$Id: clipsamp.asm,v 1.1 97/04/04 16:32:34 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def

include object.def
include	graphics.def
include lmem.def
include	file.def
include char.def
include localize.def

include hugearr.def
include vm.def
include font.def
include Objects/winC.def
include Objects/inputC.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	Objects/vTextC.def

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Object Class include files
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;Here we define "ClipSampProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of
;will be created, and will handle all application-related events (methods).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

ClipSampProcessClass	class	GenProcessClass

;METHOD DEFINITIONS: these methods are defined for ClipSampProcessClass.

;Note: instances of ClipSampProcessClass are actually hybrid objects.
;Instead of allocating a chunk in an Object Block to contain the instance data
;for this object, we use the application's DGROUP resource. This resource
;contains both idata and udata sections. Therefore, to create instance data
;for this object (such as textColor), we define a variable in idata,
;instead of defining an instance data field here.

ClipSampProcessClass	endc	;end of class definition


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "clipsamp.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;clipsamp.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		clipsamp.rdef		;include compiled UI definitions


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

;Class definition is stored in the application's idata resource here.

	ClipSampProcessClass	mask CLASSF_NEVER_SAVED

;initialized variables (In a sense, these variables can be considered
;instance data for the ClipSampProcessClass object. See above.)

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

windowHandle	hptr.Window
textHandle	hptr.HandleMem

doingFeedback	byte			; TRUE if providing quick-transfer
					;	feedback

udata	ends

;------------------------------------------------------------------------------
;		Code for ClipSampProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	register ourselves for clipboard notification

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		es - segment of ClipSampProcessClass (dgroup)
		bp - handle of extra state block (text block)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampOpenApplication	method	ClipSampProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION
	clr	es:[windowHandle]
	;
	; copy extra state block, if any, as text block
	;
	tst	bp
	jz	noExtraBlock
	push	ax, cx, si, ds, es
	mov	bx, bp
	call	MemLock				; lock extra state block
	push	bx
	mov	ds, ax
	clr	si
	mov	ax, MGIT_SIZE
	call	MemGetInfo			; ax = size of extra state block
	push	ax				; save it
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc			; bx = new text block handle
	pop	cx				; cx = size of block
	mov	bp, 0				; in case of error
	jc	memErr
	mov	bp, bx				; bp = new text block handle
	mov	es, ax
	mov	di, 0
	rep movsb				; copy text over
memErr:
	pop	bx
	call	MemUnlock			; unlock extra state block
						; (will be freed by system)
	mov	bx, bp
	tst	bx				; handle error above
	jz	noTextBlock
	call	MemUnlock			; unlock our new text block
noTextBlock:
	pop	ax, cx, si, ds, es
noExtraBlock:
	mov	es:[textHandle], bp		; bp = 0 if none
	;
	; first, call superclass to do standard handling
	;
	mov	di, offset ClipSampProcessClass
	call	ObjCallSuperNoLock
	;
	; then, register ourselves
	;
	call	GeodeGetProcessHandle		; bx = process handle
	mov	cx, bx
	clr	dx				; dx = 0 for process
	call	ClipboardAddToNotificationList
	;
	; let's force updating of the "Paste" item; ClipboardAddToNotificationList
	; does this, but it does it through the application queue, so it
	; doesn't happen immediately
	;
	call	ClipSampNotifyNormalTransferItemChanged
	ret
ClipSampOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unregister ourselves for clipboard notification

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		es - segment of ClipSampProcessClass (dgroup)

RETURN:		cx - handle of extra state block (text block)

DESTROYED:	bx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampCloseApplication	method	ClipSampProcessClass,
					MSG_GEN_PROCESS_CLOSE_APPLICATION
	clr	cx
	xchg	cx, es:[textHandle]
	push	cx
	;
	; first, un-register ourselves
	;
	call	GeodeGetProcessHandle		; bx = process handle
	mov	cx, bx
	clr	dx				; dx = 0 for process
	call	ClipboardRemoveFromNotificationList
	;
	; since we are going away, we want to make sure that we will not
	; be sent any quick-transfer notification (the routine will only
	; clear the notification OD if it matches the one we pass it --
	; this ensures that we don't accidentally clear someone else's
	; notification OD)
	;
	clr	di				; bx:di = process OD
	call	ClipboardClearQuickTransferNotification
	;
	; return text block as extra state block
	;
	pop	cx
	ret
ClipSampCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	redraw our window

CALLED BY:	MSG_META_EXPOSED

PASS:		cx - window handle
		es - segment of ClipSampProcessClass (dgroup)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampExposed	method	ClipSampProcessClass, MSG_META_EXPOSED
	mov	es:[windowHandle], cx		; save window handle
	mov	di, cx
	call	GrCreateState
	call	GrBeginUpdate
	mov	bx, es:[textHandle]
	tst	bx
	jz	done
	push	bx
	call	MemLock
	mov	ds, ax				; ds:si = text
	clr	si
	clr	bx				; start lines at top of view
	clr	cx
	mov	bp, si				; save beginning of line
nextChar:
	lodsb
	inc	cx				; one more character to print
	tst	al				; null-terminator?
	jz	doneWithLines			; yes, print last line
	cmp	al, 13				; carriage-return?
	jne	nextChar			; no, keep checking
	xchg	bp, si				; bp = beginning of next line
						; si = beginning of this line
	call	DrawTextLine
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics			; dx = height
	add	bx, dx				; move to next line
	mov	si, bp				; si = beginning of next line
	clr	cx				; reset line length counter
	jmp	short nextChar

doneWithLines:
	mov	si, bp				; si = beginning of last line
	call	DrawTextLine
	pop	bx
	call	MemUnlock
done:
	call	GrEndUpdate
	call	GrDestroyState
	ret
ClipSampExposed	endm

DrawTextLine	proc	near
	clr	ax				; draw at (0,N)
	dec	cx				; don't draw CR
	jcxz	noText
	call	GrDrawText
noText:
	ret
DrawTextLine	endp

;
; code below is for clipboard
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "Cut" menu item - move text into clipboard

CALLED BY:	MSG_META_CLIPBOARD_CUT

PASS:		es - segment of ClipSampProcessClass (dgroup)

RETURN:		nothing
		(text move to clipboard)

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampCut	method	ClipSampProcessClass, MSG_META_CLIPBOARD_CUT
	push	es			; save dgroup
	call	ClipSampCopy		; first copy the text into clipboard
	pop	es			; retreive dgroup
	;
	; then delete the text
	;
	clr	bx
	xchg	bx, es:[textHandle]
	tst	bx
	jz	noOldText
	call	MemFree			; free old text block
noOldText:
	call	ResetViewArea
	ret
ClipSampCut	endm

ResetViewArea	proc	near
	mov	di, ss:[windowHandle]
	tst	di
	jz	done
	clr	ax
	clr	bx
	mov	cx, LARGEST_POSITIVE_COORDINATE
	mov	dx, LARGEST_POSITIVE_COORDINATE
	call	GrCreateState
	call	GrInvalRect
	call	GrDestroyState
done:
	ret
ResetViewArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "Copy" menu item - put copy of text into clipboard

CALLED BY:	MSG_META_CLIPBOARD_COPY

PASS:		es - segment of ClipSampProcessClass (dgroup)

RETURN:		nothing
		(text copied into clipboard)

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampCopy	method	ClipSampProcessClass, MSG_META_CLIPBOARD_COPY
	clr	si			; normal transfer item
	call	CopyCommon
	ret
ClipSampCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	creation and registration of normal or quick transfer item

CALLED BY:	ClipSampCopy
		ClipSampStartMoveCopy

PASS:		si - ClipboardItemFlags
			0 for normal item
			CIF_QUICK for quick-transfer item
		es - segment of ClipSampProcessClass (dgroup)

RETURN:		carry clear if successful
		carry set if error (nothing copied)

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyCommon	proc	near
	mov	bx, es:[textHandle]		; ax = handle of text block
	tst	bx
	jnz	haveText
	stc					; indicate nothing copied
doneJMP:
	jmp	done				; no text, done

haveText:
	call	MemLock
	mov	es, ax
	clr	di
	clr	al
	mov	cx, -1
	repne scasb
	not	cx				; cx = length with null
	dec	cx
	call	MemUnlock
	stc					; in case no text
	jcxz	doneJMP				; no text
	push	si				; save quick/normal flag
	call	BuildTextTransferBlock		; returns: ax - text transfer
						;		VM block handle
	mov	dx, ax				; save data VM block handle
	call	ClipboardGetClipboardFile		; bx = Transfer VM File handle
	mov	ax, 1111			; VM block ID (non-zero)
	mov	cx, size ClipboardItemHeader	; size of block
	call	VMAlloc				; returns: ax - VM block handle
	push	ax				; save it
	call	VMLock				; lock header block
	mov	es, ax				; es = segment of header block
	;
	; fill in general clipboard item information
	;
	push	bx
	call	GeodeGetProcessHandle		; bx = process handle
	mov	es:[CIH_owner].handle, bx	; owner is process
	pop	bx
	mov	es:[CIH_owner].chunk, 0
	mov	es:[CIH_flags], si		; quick or normal flag
	mov	es:[CIH_sourceID].handle, 0	; no associated document
	mov	es:[CIH_sourceID].chunk, 0
	;
	; fill in name for clipboard item
	;
	segmov	ds, cs				; ds:si = source of name
	mov	si, offset SampleTextName
	mov	di, offset CIH_name		; es:di = destination for name
	mov	cx, SAMPLE_TEXT_NAME_SIZE
	rep movsb				; copy in name
	;
	; fill in pointer to data block as the only format
	;
	mov	es:[CIH_formatCount], 1	; only CIF_TEXT format
						; the following syntax only
						;	works for the 1st format
	mov	es:[CIH_formats][0].CIFI_format.CIFID_manufacturer, \
							MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats][0].CIFI_format.CIFID_type, CIF_TEXT
	mov	es:[CIH_formats][0].CIFI_vmChain.high, dx
	clr	es:[CIH_formats][0].CIFI_vmChain.low
	mov	es:[CIH_formats][0].CIFI_extra1, 0	; no extra info
	mov	es:[CIH_formats][0].CIFI_extra2, 0
	call	VMUnlock			; unlock header block
	;
	; now, actually put it on the clipboard
	;
	pop	ax		; bx:ax = (Transfer VM File):(VM block handle)
				;		of header block
	pop	bp		; get quick/normal flag
	call	ClipboardRegisterItem		; (return carry flag)
done:
	ret
CopyCommon	endp

;
; null-terminated name for sample clipboard item
;
SampleTextName	byte	'Sample Text',0
SAMPLE_TEXT_NAME_SIZE = $-SampleTextName


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildTextTransferBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	build a CIF_TEXT data block

CALLED BY:	ClipSampCopy

PASS:		bx - block handle of null-terminated text

RETURN:		ax - VM block handle of CIF_TEXT data block

DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/21/91	Initial version
	brianc	4/6/91		updated for new CIF_TEXT format

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildTextTransferBlock	proc	near	uses	si
	.enter
	;
	; lock down text
	;
	push	bx
	call	MemLock
	mov	dx, ax				; dx:bp = ptr to null-terminated
	clr	bp				;	text
	;
	; create a temporary text object to build CIF_TEXT data block
	;
	mov	al, 0				; no styles, etc.
	mov	ah, 0				; no regions
	call	ClipboardGetClipboardFile		; bx = Transfer VM File handle
	call	TextAllocClipboardObject	; ^lbx:si = text object
	;
	; set the text in the text object
	;	dx:bp = ptr to null-terminated text
	;
	clr	cx				; text is null-terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; tell the text object that we are done with it
	;
	mov	ax, TCO_RETURN_TRANSFER_FORMAT
	call	TextFinishWithClipboardObject	; ax = CIF_TEXT block
	;
	; finish up
	;
	pop	bx				; unlock text block
	call	MemUnlock
	.leave
	ret
BuildTextTransferBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "Paste" menu item - replace text with clipboard item

CALLED BY:	MSG_META_CLIPBOARD_PASTE

PASS:		es - segment of ClipSampProcessClass (dgroup)

RETURN:		nothing
		(text replaced with clipboard item)

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampPaste	method	ClipSampProcessClass, MSG_META_CLIPBOARD_PASTE
	clr	bp				; paste normal item
	call	PasteCommon
	ret
ClipSampPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle pasting of normal or quick-transfer item

CALLED BY:	ClipSampPaste
		ClipSampEndMoveCopy

PASS:		bp - ClipboardItemFlags
			0 for normal item
			CIF_QUICK for quick-transfer item

RETURN:		bp - ClipboardQuickNotifyFlags for ClipboardEndQuickTransfer
		(text replaced with transfer item)

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/26/91	Initial version
	brianc	4/6/92		Updated for new CIF_TEXT format

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteCommon	proc	near
	;
	; first, find out if there is a normal clipboard item and if it
	; supports the CIF_TEXT format
	;	bp = quick/normal
	;
	mov	di, mask CQNF_NO_OPERATION	; assume quick-item will not
						;	be accepted
						; allocate room on stack for
						;	formats buffer
	call	ClipboardQueryItem		; returns: bx:ax = header block
						;	   bp = format count
	tst	bp				; any item?
	LONG jz	done				; nope, nothing to paste
	mov	cx, MANUFACTURER_ID_GEOWORKS		; search for CIF_TEXT
	mov	dx, CIF_TEXT
	call	ClipboardTestItemFormat
	LONG jc	done				; nope, nothing to paste
	;
	; a clipboard item exists and does support CIF_TEXT, let's get it
	;
	push	bx, ax				; save header info
	mov	cx, MANUFACTURER_ID_GEOWORKS	; search for CIF_TEXT
	mov	dx, CIF_TEXT
	call	ClipboardRequestItemFormat	; pass bx:ax returned from
						;	ClipboardQueryItem
						; returns: bx:ax = CIF_TEXT item
	;
	; let's process the item by replacing our text block with the
	; text in the item
	;
	; since it is in CIF_TEXT format, we know that the data block is in
	; TextTransferBlockHeader format; all we'll use is the text, it is
	; stored as a HugeArray; we cycle through the HugeArray
	;
	push	di				; save ClipboardQuickNotifyFlags
	push	es				; save dgroup
	call	VMLock				; lock CIF_TEXT data block
						; returns: ax - segment of item
						;	   bp - mem handle
	mov	ds, ax				; ds = TextTransferBlockHeader
	mov	di, ds:[TTBH_text].high		; di = text huge array
	call	VMUnlock			; unlock CIF_TEXT data block
	mov	si, bx				; si = VM file handle
	clr	ax				; start from first character
	mov	dx, ax
	mov	bx, ax				; no new text buffer yet
	mov	bp, ax				; starting position in new
						;	text buffer
pasteLoop:
	pushdw	dxax				; save dx:ax = position
	push	si				; save VM file handle
	push	bx				; save mem buffer
	mov	bx, si				; bx = VM file handle
	call	HugeArrayLock			; ds:si = text, ax = #chars
	pop	bx				; restore mem buffer
	mov	cx, ax				; cx = #chars
	tst	bx
	jnz	haveBuffer
	push	cx				; save #chars
	mov	ax, cx				; size of buffer
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc			; bx = handle
						; ax = segment
	jnc	allocOK
	mov	bx, 0				; indicate memory error
allocOK:
	pop	cx				; cx = #chars
	jmp	short copyText			; carry set if error

haveBuffer:
	mov	ax, bp				; ax = current size
	add	ax, cx				; ax = new size
	push	cx				; save #chars
	clr	ch
	call	MemReAlloc			; carry set if error
	pop	cx
copyText:
	;
	; carry set if memory error
	; carry clear if ok
	;	bx = block handle, if any (0 if none)
	;	cx = # chars
	;
	jc	memError			; memory error
	mov	es, ax
	xchg	bp, di				; es:di = place to copy text
						; bp = HugeArray VM block handle
	rep movsb				; copy over the text
	xchg	bp, di				; es:bp = place to copy text
						; di = HugeArray VM block handle
memError:
	call	HugeArrayUnlock			; (preserves flags)
	pop	si				; restore VM file handle
	popdw	dxax				; restore dx:ax = position
	jc	atEnd				; if mem error, stop
	cmp	{byte} es:[bp-1], 0		; just copied null-termination?
	je	atEnd				; yes, reached end of text, done
	add	ax, cx				; update position with # chars
	adc	dx, 0
	tst	dx				; stop at 64K
	jz	pasteLoop
atEnd:
	tst	bx				; any mem block?
	jz	noUnlock			; nope
	call	MemUnlock			; unlock our new text block
noUnlock:
	pop	es				; retreive dgroup
	xchg	es:[textHandle], bx		; save new text block, if any
	tst	bx
	jz	noOldText
	call	MemFree				; free old text block
noOldText:
	pop	di				; retrieve ClipboardQuickNotifyFlags
	pop	bx, ax				; retrieve header block info
	mov	di, mask CQNF_COPY		; indicate text copied
done:
	;
	; now, tell the clipboard that we are finished with this item
	;	bx:ax = (Transfer VM File):(VM block handle) of item's
	;		header block
	;	di = ClipboardQuickNotifyFlags
	;
	call	ClipboardDoneWithItem		; pass bx:ax = header block
	mov	bp, di				; return ClipboardQuickNotifyFlags
	;
	; finally, force our view to redraw
	;
	call	ResetViewArea
	ret
PasteCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampNotifyNormalTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enables or disables Paste item depending on the availability
		of a CIF_TEXT item on the clipboard

CALLED BY:	MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

PASS:		ds - segment of stack, dgroup, thread etc.

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampNotifyNormalTransferItemChanged	method	ClipSampProcessClass,
				MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	clr	bp				; check normal item
	call	ClipboardQueryItem		; returns: bx:ax = header block
						;	   bp = format count
	tst	bp				; any normal item?
	mov	si, MSG_GEN_SET_NOT_ENABLED	; assume not
	jz	done				; no normal item, done
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT			; check for CIF_TEXT format
	call	ClipboardTestItemFormat
	jc	done				; not found, done
	mov	si, MSG_GEN_SET_ENABLED	; else, enable "Paste" item
done:
	;
	; now, tell the clipboard that we are finished with this item
	;	bx:ax = (Transfer VM File):(VM block handle) of item's
	;		header block
	;
	call	ClipboardDoneWithItem		; pass bx:ax = header block
	;
	; now enable or disable Paste item appropriately
	;
	mov	ax, si
	GetResourceHandleNS	EditPaste, bx
	mov	si, offset EditPaste
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
ClipSampNotifyNormalTransferItemChanged	endm

;
; code below is for quick-transfer
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle MSG_META_START_MOVE_COPY - begin a quick-transfer

CALLED BY:	MSG_META_START_MOVE_COPY

PASS:		es - segment of ClipSampProcessClass (dgroup)

RETURN:		ax - MouseReturnFlags

DESTROYED:	bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampStartMoveCopy	method	ClipSampProcessClass, MSG_META_START_MOVE_COPY
	;
	; first, start the UI part of the quick-transfer
	;
						; we can only copy text out
						;	(cannot move)
	mov	si, mask CQTF_COPY_ONLY or mask CQTF_NOTIFICATION
	mov	ax, CQTF_COPY			; initial feedback cursor
	call	GeodeGetProcessHandle		; bx = our process
	clr	di				; bx:di = OD for our process
						;	(notification OD)
	call	ClipboardStartQuickTransfer
	jc	done				; quick-transfer already in
						;	progress, do nothing
	;
	; then, create and register a quick-transfer item
	;
	mov	si, mask CIF_QUICK		; quick-transfer item
	push	ds, es
	call	CopyCommon
	pop	ds, es
	jc	error				; handle error
	;
	; quick-transfer sucessfully started, allow the mouse pointer to
	; wander everywhere for feedback
	;
	GetResourceHandleNS	ClipSampView, bx
	mov	si, offset ClipSampView
	mov	ax, MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	short done

error:
	;
	; handle error creating item by stoping UI part of quick-tranfser
	;
	call	ClipSampStopFeedback
done:
	mov	ax, mask MRF_PROCESSED		; accepted mouse event
	ret
ClipSampStartMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle MSG_PTRs by providing quick-transfer feedback,
		if necessary

CALLED BY:	MSG_META_PTR

PASS:		cx, dx - mouse position
		bp high - UIFunctionsActive
		es - segment of ClipSampProcessClass (dgroup)
		ds - segment of stack, dgroup, thread etc.

RETURN:		ax - MouseReturnFlags

DESTROYED:	bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampPtr	method	ClipSampProcessClass, MSG_META_PTR
	test	bp, mask UIFA_MOVE_COPY shl 8	; quick-transfer active?
	jz	exit				; nope, do nothing
	call	ClipboardGetQuickTransferStatus	; really in progress?
	jz	exit				; nope
	;
	; need to check the current quick-transfer item to see if it supports
	; the CIF_TEXT format
	;
	push	bp				; save UIFunctionsActive
	mov	si, sp				; save stack
	mov	bp, mask CIF_QUICK
	call	ClipboardQueryItem		; bp = # formats, cx:dx = owner
						; bx:ax = VM file:VM block
	tst	bp				; any formats?
	stc					; assume none
	jz	done				; none, done (carry set)
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT
	call	ClipboardTestItemFormat		; is CIF_TEXT there?
						; (carry clear if so)
done:
	pushf					; save result flag
	call	ClipboardDoneWithItem
	popf					; retreive result flag
	mov	sp, si				; recover stack space
	pop	bp				; retrieve UIFunctionsActive
	;
	; now, set the mouse pointer shape to provide feedback
	;	carry = clear if CIF_TEXT supported
	;
	mov	ax, CQTF_COPY			; assume CIF_TEXT supported
	jnc	haveCursor
	mov	ax, CQTF_CLEAR			; not supported -> clear cursor
haveCursor:
	call	ClipboardSetQuickTransferFeedback	; set cursor
						;	(pass bp along)
	mov	es:[doingFeedback], TRUE
exit:
	mov	ax, mask MRF_PROCESSED		; accepted mouse event
	ret
ClipSampPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampStopFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle MSG_SUBVIEW_LOST_GADGET_EXCL
		by stopping quick-transfer feedback

CALLED BY:	MSG_SUBVIEW_LOST_GADGET_EXCL

PASS:		es - segment of ClipSampProcessClass (dgroup)
		ds - segment of stack, dgroup, thread etc.

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/02/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampStopFeedback	method	ClipSampProcessClass, \
					MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL
	cmp	es:[doingFeedback], TRUE
	jne	done
	mov	ax, CQTF_CLEAR
	call	ClipboardSetQuickTransferFeedback
	mov	es:[doingFeedback], FALSE
done:
	ret
ClipSampStopFeedback	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle MSG_META_END_MOVE_COPY - quick-paste item if CIF_TEXT
		available

CALLED BY:	MSG_META_END_MOVE_COPY

PASS:		nothing

RETURN:		ax - MouseReturnFlags

DESTROYED:	bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampEndMoveCopy	method	ClipSampProcessClass, MSG_META_END_MOVE_COPY
	mov	bp, mask CIF_QUICK		; paste quick-transfer item
	call	PasteCommon
	call	ClipboardEndQuickTransfer		; end quick-transfer
						;	(clears q-t item)
	mov	ax, mask MRF_PROCESSED		; accepted mouse event
	ret
ClipSampEndMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSampNotifyQuickTransferConcluded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle notification that a quick-transfer that we started
		has finished

CALLED BY:	MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED

PASS:		bp - ClipboardQuickNotifyFlags
		es - segment of ClipSampProcessClass (dgroup)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipSampNotifyQuickTransferConcluded	method	ClipSampProcessClass, \
				MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED
	test	bp, mask CQNF_COPY		; it should be a copy
	jz	errorBell			; ring bell if not
	mov	di, es:[windowHandle]		; di = our View's window
	call	GrCreateState			; di = gstate
	call	GrGetWinBounds			; ax - dx = window bounds
	push	ax
	mov	al, MM_INVERT
	call	GrSetMixMode			; invert window
	pop	ax
	call	GrFillRect
	call	GrFillRect			; invert back
	call	GrDestroyState
	jmp	short done

errorBell:
	mov	ax, SST_ERROR			; sound error bell
	call	UserStandardSound
	test	bp, mask CQNF_NO_OPERATION	; was the item rejected?
	jnz	done				; yes, done
	mov	ax, SST_ERROR			; else, sound another bell
	call	UserStandardSound
done:
	ret
ClipSampNotifyQuickTransferConcluded	endm

					
CommonCode	ends		;end of CommonCode resource
