COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		deskdisplayTool.asm

AUTHOR:		Adam de Boor, Jan 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/30/92		Initial revision


DESCRIPTION:
	Implementation of DeskToolClass
		

	$Id: cdeskdisplayTool.asm,v 1.2 98/06/03 13:23:54 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



PseudoResident segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskToolPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	provide feedback during direct-manipulation

CALLED BY:	MSG_META_PTR

PASS:		usual object stuff
			ds:di = DeskTool instance data
		es - segment of DeskToolClass
		bp - UIFA flags
			UIFA_IN - set mouse pointer if in bounds of this object

RETURN:		ax = MouseReturnFlags

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/11/91		Initial version for 2.0 quick-transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskToolPtr	method	DeskToolClass, MSG_META_PTR
	add	di, offset DT_flags		; ds:di = flags
	mov	bx, offset Callback_DeskToolPtr	; callback routine
	mov	ax, offset DeskToolClass
	call	ToolPtrCommon
	ret
DeskToolPtr	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Callback_DeskToolPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback for DeskToolPtr that determines the quick
		transfer default for move/copy.

CALLED BY:	ToopPtrCommon

PASS:		*ds:si = DeskTool object

RETURN:		ax = CQTF_MOVE, CQTF_COPY, CQTF_CLEAR

DESTROYED:	???

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Desktools aren't used right now.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/17/93	Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Callback_DeskToolPtr	proc	near
	class	DeskToolClass
	.enter

	call	CheckQuickTransferType		; is CIF_FILES supported?
	mov	ax, CQTF_CLEAR			; assume not
	jc	done				; no, just clear cursor
	
	mov	ax, CQTF_MOVE			; default to move

	;
	; Only the FileCabinet Wastebasket uses this class right now, 
	; if this class is used by anyone else they should put in the
	; appropriate behavior.
	;
done:
	.leave
	ret
Callback_DeskToolPtr	endp

DeskToolLostGadgetExcl	method	DeskToolClass, MSG_VIS_LOST_GADGET_EXCL
	add	di, offset DT_flags
	call	ToolLostGadgetExclCommon
	ret
DeskToolLostGadgetExcl	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolPtrCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	a common routine for handlers of MSG_META_PTR

CALLED BY:	DriveToolPtr, DirToolPtr, DeskToolPtr

PASS:		ds:*si = tool object
		cx, dx, bp = data from MSG_META_PTR
		ds:di = flags
		bx = callback routine
		es:ax = segment:offset of tool class

RETURN:		ax = MouseReturnFlags

DESTROYED:	???

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/17/93	Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolPtrCommon	proc	near
	push	ax, cx, dx, bp			; save MSG_META_PTR data
	test	bp, mask UIFA_MOVE_COPY shl 8	; quick-transfer in progress?
;don't need this anymore as we fake UIFA_MOVE_COPY at the app-obj
;- brianc 6/28/93
;if _ZMGR
;	jnz	qtInProgress
;	test	es:[fileDragging], mask FDF_MOVECOPY
;qtInProgress:
;endif
	jz	done				; nope
	call	ClipboardGetQuickTransferStatus	; quick-transfer in progress?
	jz	done				; nope
	test	bp, mask UIFA_IN shl 8		; in bounds?
	jnz	inBounds			; yes, start feedback
	call	ToolLostGadgetExclCommon	; else, stop feedback
	jmp	short done
inBounds:
	;
	; grab mouse, if not already grabbed
	;
	test	{DesktopToolFlags} ds:[di], mask DTF_FEEDBACK_ON
	jnz	setCursor			; already doing feedback
						;	(just ensure cursor)
	call	VisTakeGadgetExclAndGrab	; grab mouse
	ornf	{DesktopToolFlags} ds:[di], mask DTF_FEEDBACK_ON
setCursor:
	call	bx				; returns ax = cursor type
	call	ClipboardSetQuickTransferFeedback
done:
	;
	; call superclass to handle lower-level ptr operations
	;
	pop	di, cx, dx, bp			; retrieve MSG_META_PTR data
						;	and class (es:di)
	mov	ax, MSG_META_PTR
	call	ObjCallSuperNoLock
						; assume in bounds
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	test	bp, mask UIFA_IN shl 8		; in bounds?
	jnz	exit				; yes
	mov	ax, mask MRF_REPLAY		; else, replay pointer event
exit:
	ret
ToolPtrCommon	endp

ToolLostGadgetExclCommon	proc	near
	push	ax
	test	{DesktopToolFlags} ds:[di], mask DTF_FEEDBACK_ON
	jz	done
	andnf	{DesktopToolFlags} ds:[di], not mask DTF_FEEDBACK_ON
	call	VisReleaseMouse
	mov	ax, CQTF_CLEAR
	call	ClipboardSetQuickTransferFeedback
done:
	pop	ax
	ret
ToolLostGadgetExclCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskToolEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle direct-manipulation

CALLED BY:	MSG_META_END_MOVE_COPY

PASS:		usual object stuff
		es - segment of DeskToolClass
		bp - UIFA flags

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskToolEndMoveCopy	method	DeskToolClass, MSG_META_END_MOVE_COPY
	call	DeskToolLostGadgetExcl		; release mouse, if needed
	mov	di, MSG_DESKTOOL_QT_INTERNAL
	call	ToolQuickTransfer
	ret
DeskToolEndMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskToolEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle direct-manipulation for ZMGR

CALLED BY:	MSG_META_END_SELECT

PASS:		usual object stuff
		es - segment of DeskToolClass
		bp - UIFA flags

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PEN_BASED

DeskToolEndSelect	method	DeskToolClass, MSG_META_END_SELECT
	push	es
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_MOVECOPY
	pop	es
	jz	callSuper
	call	DeskToolLostGadgetExcl		; release mouse, if needed
	mov	di, MSG_DESKTOOL_QT_INTERNAL
	call	ToolQuickTransfer
	ret

callSuper:
	mov	di, offset DeskToolClass
	GOTO	ObjCallSuperNoLock

DeskToolEndSelect	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolQuickTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	DeskToolEndMoveCopy,
		DirToolEndMoveCopy,
		DriveToolEndMoveCopy

PASS:		di = internal QT method to send to Desktop thread
		bp = UIFA flags from MSG_META_END_MOVE_COPY
		es = segment of class

RETURN:		none
DESTROYED:	???

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	1/26/93		Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolQuickTransfer	proc	near
	.enter


	;
	; clear quick transfer flags
	;
	push	es
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	andnf	es:[fileDragging], not (mask FDF_MOVECOPY or \
						mask FDF_SELECT_MOVECOPY)
	pop	es

if _ZMGR
	;
	; if ZMGR, VisContent didn't do a ClipboardHandleEndMoveCopy
	; because we faked it with a END_SELECT, so we need to do it
	; ourselves
	;
	mov	bx, -1			; have active grab (us)
	clc				; don't check quick-transfer status
	call	ClipboardHandleEndMoveCopy
endif

	push	bp				; save flags
	mov	bp, mask CIF_QUICK
	call	ClipboardQueryItem		; returns:
						; cx:dx - owner of drag files
	tst	bp				; bp = count of formats
						;	(use results later)
	pop	bp				; retrieve flags
	push	bx, ax				; bx:ax - transfer item header
	jz	done				; no transfer item, done

	;
	; We don't have to worry about MANUFACTURER_ID_WIZARD, as the 
	; NewDesk doesn't use the "tools" i.e. tool buttons in the tool area.
	;
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_FILES
	push	bp
	call	ClipboardRequestItemFormat	; get file list block (bx:ax)
	pop	bp				;  and flags in cx:dx
	tst	ax				; does format exist?
	jz	done				; no, done

	;
	; copy file list
	;	bp = UIFA flags
	;
	mov	dx, bp				; dx = UIFA flags
	push	di, es, ds, si			; save our instance
	call	VMLock				; ax = segment, bp = mem handle
	mov	bx, bp
	mov	ds, ax

	mov	ax, MGIT_SIZE
	call	MemGetInfo
	push	ax				; size
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc
	pop	cx				; size
	jc	memError

	mov	es, ax
	clr	si, di
	;
	; Hack!  Rely on the fact that MemGetInfo(MGIT_SIZE) always
	; returns an even number
	;
EC <	test	cx, 1				>
EC <	ERROR_NZ DESKTOP_FATAL_ERROR		>
	shr	cx
	rep movsw				; copy file list
	mov	es:[FQTH_UIFA], dx		; save UIFA flags in file list
	mov	di, bx				; di = handle of copied block
	call	MemUnlock			; unlock it
	clc					; indicate no error

errorExit:
	call	VMUnlock			; unlock original file list
	pop	ax, es, ds, dx			; retrieve instance (dx = si)
	jc	done				; if error, done
if GPC_DRAG_SOUND
	call	UtilDragSound
endif
	;
	; send file list to desktop thread so application has burden of
	; expensive file operations
	;	send:	cx:dx - this object
	;		di - handle of filelist block
	;		ax - internal method
	;
	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = our instance
	mov	bp, di				; bp = file list block handle
	mov	bx, handle 0 			; bx = desktop process
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	pop	bx, ax				; bx:ax = transfer item header
	call	ClipboardDoneWithItem		; tell UI we're done
	;
	; whatever the case, stop the UI part of the quick-transfer
	;
	; as we don't know whether a move or copy will be preformed, let's
	; just say that the item was not accepted -- the ramification of this
	; is just that no notification will be sent out to the owner;
	; currently, only GeoManager generates CIF_FILES, and we don't need
	; notification, so we let this slip
	;
	mov	bp, mask CQNF_NO_OPERATION	; bp = ClipboardQuickNotifyFlags
	call	ClipboardEndQuickTransfer

	mov	ax, mask MRF_PROCESSED

	.leave
	ret

memError:
	;
	; send method to process to put up error box for us
	;
	mov	cx, ERROR_INSUFFICIENT_MEMORY	; report error
	mov	ax, MSG_REMOTE_ERROR_BOX
	mov	bx, handle 0
	call	ObjMessageForce
	stc					; indicate error reported
	jmp	errorExit

ToolQuickTransfer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskToolGetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get tool type for this tool

CALLED BY:	MSG_DESK_TOOL_GET_TYPE

PASS:		usual object stuff

RETURN:		dl - tool type

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskToolGetType	method	dynamic DeskToolClass, MSG_DESK_TOOL_GET_TYPE
	mov	dl, ds:[di].DT_toolType		; get drive number
	ret
DeskToolGetType	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	      DeskToolActivate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:     handle activation via keyboard navigation

CALLED BY:    MSG_GEN_ACTIVATE

PASS:	      usual object stuff
	      es - segment of DeskToolClass

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	      none

REVISION HISTORY:
      Name    Date	      Description
      ----    ----	      -----------
      brianc  1/30/92	      Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskToolActivate      method  DeskToolClass, MSG_GEN_ACTIVATE
	cmp	ds:[di].DT_toolType, DESKTOOL_WASTEBASKET
	jne	done
	;
	; trash can activated, start delete (handily uses menu-delete code
	; which asks before deleting when confirmation is off)
	;
	mov	ax, MSG_FM_START_DELETE
	mov	bx, handle 0
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	ret
DeskToolActivate      endm

PseudoResident	ends
