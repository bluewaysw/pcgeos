COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentPageSetup.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file method handlers and related code for WriteDocumentClass.

	$Id: documentPageSetup.asm,v 1.1 97/04/04 15:57:03 newdeal Exp $

------------------------------------------------------------------------------@

include Internal/prodFeatures.def

DocEditMP segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentMPBodySuspend --
		MSG_WRITE_DOCUMENT_MP_BODY_SUSPEND for WriteDocumentClass

DESCRIPTION:	Notification that a master page body has been suspended

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/22/93		Initial version

------------------------------------------------------------------------------@
WriteDocumentMPBodySuspend	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_MP_BODY_SUSPEND

	inc	ds:[di].WDI_mpBodySuspendCount
	ret

WriteDocumentMPBodySuspend	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentMPBodyUnsuspend --
		MSG_WRITE_DOCUMENT_MP_BODY_UNSUSPEND for WriteDocumentClass

DESCRIPTION:	Notification that a master page body has been unsuspended

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/22/93		Initial version

------------------------------------------------------------------------------@
WriteDocumentMPBodyUnsuspend	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_MP_BODY_UNSUSPEND

	dec	ds:[di].WDI_mpBodySuspendCount
	jnz	done

	test	ds:[di].WDI_state, mask WDS_RECALC_ABORTED
	jz	done

	andnf	ds:[di].WDI_state, not mask WDS_RECALC_ABORTED

	mov	ax, MSG_WRITE_DOCUMENT_RECALC_LAYOUT
	call	ObjCallInstanceNoLock

done:
	ret

WriteDocumentMPBodyUnsuspend	endm

DocEditMP ends

;---

DocPageSetup segment resource

DPS_ObjMessageNoFlags	proc	near
	push	di
	clr	di
	call	ObjMessage
	pop	di
	ret
DPS_ObjMessageNoFlags	endp

DPS_ObjMessageFixupDS	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DPS_ObjMessageFixupDS	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentChangePageSetup --
		MSG_WRITE_DOCUMENT_CHANGE_PAGE_SETUP for WriteDocumentClass

DESCRIPTION:	Change the page setup

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/27/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentChangePageSetup	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_CHANGE_PAGE_SETUP
section		local	SectionArrayElement
	.enter

	; get the data from the dialog box

	push	si
	GetResourceHandleNS	LayoutColumnsValue, bx

if _SECTION_SUPPORT
	mov	si, offset LayoutFirstPageValue
	call	callValueGetValue
	mov	section.SAE_startingPageNum, dx

	mov	si, offset LayoutFirstBooleanGroup
	call	callBooleanGetValue
	mov	section.SAE_flags, ax

elseif _ALLOW_STARTING_PAGE
	mov	si, offset LayoutFirstPageValue
	call	callValueGetValue
	mov	ss:[section].SAE_startingPageNum, dx

	clr	ss:[section].SAE_flags

else
	clr	ss:[section].SAE_startingPageNum
	clr	ss:[section].SAE_flags
endif

	mov	si, offset LayoutColumnsValue
	call	callValueGetValue
	mov	section.SAE_numColumns, dx

	mov	si, offset LayoutColumnSpacingDistance
	call	callValueGetDistance
	mov	section.SAE_columnSpacing, dx
	mov	si, offset LayoutColumnRuleWidthDistance
	call	callValueGetDistance
	mov	section.SAE_ruleWidth, dx

	mov	si, offset LayoutMasterPageList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	push	bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
	inc	ax
	mov	section.SAE_numMasterPages, ax

	mov	si, offset LayoutMarginLeftDistance
	call	callValueGetDistance
	mov	section.SAE_leftMargin, dx
	mov	si, offset LayoutMarginTopDistance
	call	callValueGetDistance
	mov	section.SAE_topMargin, dx
	mov	si, offset LayoutMarginRightDistance
	call	callValueGetDistance
	mov	section.SAE_rightMargin, dx
	mov	si, offset LayoutMarginBottomDistance
	call	callValueGetDistance
	mov	section.SAE_bottomMargin, dx
	pop	si

	call	LockMapBlockES

	; verify that this new page setup is legal, given the page size
	call	GetSectionToOperateOn
	call	SectionArrayEToP_ES		;es:di = SectionArrayElement
	call	ValidateNewPageSetup
	LONG jc	done

if	_REGION_LIMIT
	;
	; If we're enforcing region limits, auto-save the document before
	; changing the number of regions.  If the auto-save fails, don't
	; change the page setup.
	;
	call	ForceAutoSave
	LONG	jc	done	
endif		

	call	IgnoreUndoAndFlush
	call	VMDirtyES

	call	SuspendDocument

	; Get the page setup changes from the various UI objects and stuff
	; them in the section array

	mov	ax, offset PageSetupTitlePageString
	mov	cx, offset EditHeaderTitlePageTable
	mov	dx, CustomDialogBoxFlags \
			<0, CDT_QUESTION, GIT_MULTIPLE_RESPONSE,0>
	call	GetSectionToOperateOn
	call	SectionArrayEToP_ES		;es:di = SectionArrayElement

	; has anything changed that requires recalculation ?

	mov	ax, section.SAE_numMasterPages
	cmp	ax, es:[di].SAE_numMasterPages
	jnz	gotRecalcFlag
	mov	ax, section.SAE_numColumns
	cmp	ax, es:[di].SAE_numColumns
	jnz	gotRecalcFlag
	mov	ax, section.SAE_ruleWidth
	cmp	ax, es:[di].SAE_ruleWidth
	jnz	gotRecalcFlag
	mov	ax, section.SAE_columnSpacing
	cmp	ax, es:[di].SAE_columnSpacing
	jnz	gotRecalcFlag
	mov	ax, section.SAE_leftMargin
	cmp	ax, es:[di].SAE_leftMargin
	jnz	gotRecalcFlag
	mov	ax, section.SAE_topMargin
	cmp	ax, es:[di].SAE_topMargin
	jnz	gotRecalcFlag
	mov	ax, section.SAE_rightMargin
	cmp	ax, es:[di].SAE_rightMargin
	jnz	gotRecalcFlag
	mov	ax, section.SAE_bottomMargin
	cmp	ax, es:[di].SAE_bottomMargin
gotRecalcFlag:

	pushf

	push	si, di, ds
	segmov	ds, ss
	lea	si, section
	add	si, offset SAE_startCopyVars
	add	di, offset SAE_startCopyVars
	mov	cx, (offset SAE_endCopyVars) - (offset SAE_startCopyVars)
	rep	movsb
	pop	si, di, ds

	popf
	jz	noRecalc
	call	RecalculateSection		; carry set if error
	jmp	afterRecalc
noRecalc:
	push	bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	bp
if _REGION_LIMIT
	clc
endif

afterRecalc:

if _REGION_LIMIT
	;
	; Don't unsuspend the document, because unsuspending articles
	; can cause them to recalculate, and try to add new regions.
	;
	jc	abort
endif
	call	UnsuspendDocument

	mov	ax, mask NF_PAGE or mask NF_SECTION or mask NF_TOTAL_PAGES
	call	SendNotification

	call	AcceptUndo

done:
	call	VMUnlockES

if _REGION_LIMIT
exit:
	;
	; Everything is okay, so enable auto-save.
	; It was turned off in ForceAutoSave
	;
	call	EnableAutoSave
endif
	.leave
	ret

if _REGION_LIMIT
abort:
	call	VMUnlockES
	call	WarnUserAndRevertDocument
	call	AcceptUndo
	jmp	exit
endif

;---

callValueGetValue:
	push	di, bp
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;dx.cx = value / 8
	pop	di, bp
	retn

;---

if _SECTION_SUPPORT
callBooleanGetValue:
	push	di, bp
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;ax = booleans
	pop	di, bp
	retn
endif

;---

callValueGetDistance:
	call	callValueGetValue
	shl	cx
	rcl	dx
	shl	cx
	rcl	dx
	shl	cx
	rcl	dx
	retn

WriteDocumentChangePageSetup	endm


if _REGION_LIMIT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WarnUserAndRevertDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Warn user the document is about to revert.

CALLED BY:	WriteDocumentChangePageSetup
PASS:		*ds:si - WriteDocument
		es - header
RETURN:		nada
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WarnUserAndRevertDocument		proc	near
	class	WriteDocumentClass
	uses	es, bp
	.enter
		
	;
	; Set the revert-to-auto-save flag just in case the page
	; format change causes a revert to auto-save...if the region
	; limit warning threshhold is crossed on the way to hitting
	; the limit, the warning will be displayed after the user has
	; been notified that the document is being reverted.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDI_operation, GDO_REVERT_TO_AUTO_SAVE
	;
	; Start by recording event to dispatch once all the queues are freed
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			; Pass Event in cx
	;
	; There may be other MSG_META_OBJ_FLUSH_INPUT_QUEUE messages
	; on the queue which will send MSG_META_OBJ_FINAL_FREE to some
	; of the grobjects. To make sure those are all handled before
	; the document is reverted, flush the queues first.
	;
	call	GeodeGetProcessHandle
	mov	dx, bx
	clr	bp
	mov	di, mask MF_FORCE_QUEUE	
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	call	ObjMessage

	.leave
	ret
WarnUserAndRevertDocument		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentRevertToAutoSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of WriteDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDocumentRevertToAutoSave		method dynamic WriteDocumentClass,
					MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE

	mov	ax, offset RevertingDocumentWarningString
	call	DisplayWarning

	call	MarkBusy
	call	IgnoreUndoAndFlush
	;
	; Reset some document instance data so that it is in the right
	; state after the revert (the document object does not get
	; reverted - only the document file data).
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].WDI_state, not (mask WDS_RECALC_ABORTED or \
		mask WDS_SUSPENDED_FOR_APPENDING_REGIONS or \
		mask WDS_SEND_SIZE_PENDING)
	clr	cx
	mov	ds:[di].WDI_mpBodySuspendCount, cx
	mov	ds:[di].WDI_currentPage, cx
	mov	ds:[di].WDI_currentSection, cx

	mov	di, 1200
	call	ThreadBorrowStackSpace

	push	di
	mov	ax, MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE
	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock
	pop	di

	call	ThreadReturnStackSpace

	call	MarkNotBusy
	call	AcceptUndo
	ret
WriteDocumentRevertToAutoSave		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentPhysicalRevertToAutoSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take care of unsuspending the view.

CALLED BY:	MSG_GEN_DOCUMENT_PHYSICAL_REVERT_TO_AUTO_SAVE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of WriteDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDocumentPhysicalRevertToAutoSave	method dynamic WriteDocumentClass,
				MSG_GEN_DOCUMENT_PHYSICAL_REVERT_TO_AUTO_SAVE

	;
	; If the document was suspended, so was the MainBody, and
	; by extension, their drawing window.  We need to unsuspend
	; that window if anything is to draw through it after the
	; revert is done. We do that by unsuspending the view.
	; The document may be suspended many times, incrementing
	; WDI_suspendCount every time, but only sending a suspend
	; message to the body (and window) the first time.
	; Therefore, we only need to unsuspend the view once.
	;
	; The message must be force-queued so that it arrives after
	; the revert-to-auto-save has completed.
	;
		clr	cx
		xchg	cx, ds:[di].WDI_suspendCount

		push	cx
		mov	di, offset WriteDocumentClass
		call	ObjCallSuperNoLock
		pop	cx

		jcxz	done
	;
	; Record a message to unsuspend the GenView.
	;
		push	si
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_display
		mov	si, offset MainView		;^lbx:si = GenView
		mov	ax, MSG_GEN_VIEW_UNSUSPEND_UPDATE
		mov	di, mask MF_RECORD
		call	ObjMessage			;^hdi <- event
		pop 	si
	;
	; Force queue the msg to dispatch the event. This will force it
	; to stay in the process queue for a while, before being sent
	; to the UI queue.
	;
		mov	cx, di
		mov	dx, mask MF_FORCE_QUEUE		
		mov	ax, MSG_META_DISPATCH_EVENT
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

done:		
		ret
WriteDocumentPhysicalRevertToAutoSave		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceAutoSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Autosave the document before doing something that
		might cause it to be reverted.

CALLED BY:	INTERNAL
PASS:		*ds:si	- document
RETURN:		carry set if document is untitled and past the
			untitled document size threshold
		carry clear if document was autosaved
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 2/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceAutoSave		proc	near
		class	WriteDocumentClass
		uses	bx, cx, dx, bp
		.enter

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		test	ds:[di].GDI_attrs, mask GDA_UNTITLED
		jz	saveIt


saveIt:		
		mov	ax, MSG_GEN_DOCUMENT_AUTO_SAVE
		call	ObjCallInstanceNoLock
	;
	; Turn off auto-save while we perform an action which could
	; potentially revert the document.
	;
;; NOTE: The sense of these messages is reversed!!!
;;
;;		mov	ax, MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE
		mov	ax, MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE
		call	ObjCallInstanceNoLock
		clc
	
done::		
		.leave
		ret

		
ForceAutoSave		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableAutoSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable auto save, but queue the message so that the
		danger of getting a MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE
		has passed by the time it is received.

CALLED BY:	INTERNAL
PASS:		*ds:si - document
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableAutoSave		proc	near
		uses	bp
		.enter

;; NOTE: The sense of these messages is reversed!!!
;;
;;		mov	ax, MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE
		mov	ax, MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di

		call	GeodeGetProcessHandle
		mov	dx, bx
		clr	bp
		mov	di, mask MF_FORCE_QUEUE	
		mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
		call	ObjMessage

		.leave
		ret
EnableAutoSave		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentEnableAutoSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn auto-save back on

CALLED BY:	MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE, really.
		NOTE: The sense of these messages is reversed!!!

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of WriteDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDocumentEnableAutoSave		method dynamic WriteDocumentClass,
					MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE
	;
	; Don't turn auto-save back on if we're not in the middle
	; of a REVERT_TO_AUTO_SAVE operation.
	;
		cmp	ds:[di].GDI_operation, GDO_REVERT_TO_AUTO_SAVE
		je	reverting
	;
	; It could be that we're on our way to doing a revert, we
	; just don't know it yet because it is taking so long to
	; recalculate all the regions.  If the document is still
	; suspended, don't enable auto-save.  
	;
		tst	ds:[di].WDI_suspendCount
		jnz	reverting

		mov	di, offset WriteDocumentClass
		GOTO	ObjCallSuperNoLock

reverting:
	;
	; If we're being reverted, put the message to enable auto-save
	; back on the queue.
	;
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		GOTO	ObjMessage
WriteDocumentEnableAutoSave		endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValidateTopBottomMarginForHeaderFooter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	validate the user's cahnges to top/bottom margin in
		Page Setup dialog box
CALLED BY:	INTERNAL
PASS:		es:di = SetionArrayElement
		ss:bp - inherited variables (including the new page setup)
		ax - bottom margin
		bx - top margin

RETURN:		carry - set if the user does not to continue with the
			page setup
		carry - clear if the user want to continue and erase
			the existing header/footer
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	11/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValidateTopBottomMarginForHeaderFooter	proc	near
headerFooterOffset	local	word
fileHandle		local	word
vmBlockHandle		local	word
bottomMargin		local	word
minMargin		local	word
	uses	ax, bx, cx, dx, si, di
	.enter 
	mov	ss:[bottomMargin], ax
	mov	cx, es:[di].SAE_masterPages	;ax = VM block
	mov	ss:[vmBlockHandle], cx

	mov	cx, bx			; top margin
	call	ConvertToPixelsCX

	call	GetFileHandle
	mov	ss:[fileHandle],bx

	mov	dx, ax			; bottom margin
if _DWP
	mov	ax, HEADER_FOOTER_INSET_BOTTOM + HEADER_FOOTER_SPACING +\
		    MINIMUM_HEADER_FOOTER_HEIGHT
else
	mov	ax, HEADER_FOOTER_INSET_Y + HEADER_FOOTER_SPACING + \
                    MINIMUM_HEADER_FOOTER_HEIGHT
endif
	mov	ss:[minMargin], ax
	mov	bx, ss:[fileHandle]		; file handle
	cmp	cx, ax
	mov	ss:[headerFooterOffset], offset MPBH_header
	jl	checkExistingHeaderFooter

checkBottomMargin:
	mov	cx, ss:[bottomMargin]
	call	ConvertToPixelsCX
	cmp	cx, ss:[minMargin]
	mov	ss:[headerFooterOffset], offset MPBH_footer
	jl	checkExistingHeaderFooter
	jmp	done

checkExistingHeaderFooter:
	mov	bx, ss:[fileHandle]		; file handle

gotMasterPage::
	mov	ax, ss:[vmBlockHandle]
	call	WriteVMBlockToMemBlock		; ax = memory handle

	mov_tr	bx, ax				;bx = master page block
	push	bx, ds
	call	ObjLockObjBlock			; ax = segment
	mov	ds, ax
	mov	di, ss:[headerFooterOffset]
	movdw	axbx, ds:[di]			; all we want is to
						; check ax =? 0
	mov	bx, ss:[fileHandle]
	pop	bx, ds
	call	MemUnlock
	tst	ax				;if zero then none exists
	jnz	noRoomForHeaderFooter		; thus, no need to
	jmp	continueSetup			; warn the user
done:
	.leave
	ret

continueSetup:
	cmp	di, offset MPBH_header
	mov	ss:[headerFooterOffset], offset MPBH_footer
	je	checkBottomMargin
	clc
	jmp	done

noRoomForHeaderFooter:
	cmp	di, offset MPBH_header
	jne	noRoomForFooter
	mov	ax, offset HeaderDataLostString
	jmp	error	

noRoomForFooter:
	mov	ax, offset FooterDataLostString

error:
	; we are going to delete the footer and header... better warn
	; the user...
	call	DisplayQuestion

	cmp	ax, IC_YES
	je	continueSetup
	stc
	jmp	done

ValidateTopBottomMarginForHeaderFooter	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ValidateNewPageSetup

DESCRIPTION:	Validate the user's changes to the Page Setup dialog box

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es:di  - SectionArrayElement
	ss:bp - inherited variables (including the new page setup)

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/22/93		Initial version

------------------------------------------------------------------------------@
ValidateNewPageSetup	proc	near
	.enter inherit WriteDocumentChangePageSetup

	; to be legal in Y the columns must be at least 1 inch high


	mov	bx, section.SAE_topMargin
	mov	ax, section.SAE_bottomMargin
	; verify that this new top bottom margin is enough to contain
	; existing header footer

	call	ValidateTopBottomMarginForHeaderFooter
	jc	done

	add	bx, section.SAE_bottomMargin
	shr	bx
	shr	bx
	shr	bx				;convert to points
	mov	ax, es:MBH_pageSize.XYS_height
	sub	ax, bx				;ax = column height
	jbe	heightError
	cmp	ax, MINIMUM_COLUMN_HEIGHT
	jae	heightOK
heightError:
	mov	ax, offset ColumnTooShortString
	jmp	error

heightOK:

	; to be legal in X the column with must be OK

	; totalColumnSpacing = (numColumns-1) * columnSpacing

	mov	ax, section.SAE_numColumns
	dec	ax
	mul	section.SAE_columnSpacing	;ax = total spacing
	add	ax, section.SAE_leftMargin
	add	ax, section.SAE_rightMargin
	shr	ax
	shr	ax
	shr	ax
	mov_tr	bx, ax

	; calculate the column width
	;	= (pageWidth - totalSpacing) / numColumns

	mov	ax, es:MBH_pageSize.XYS_width
	sub	ax, bx
	jc	widthError
	div	section.SAE_numColumns
	cmp	ax, MINIMUM_COLUMN_WIDTH
	jae	regionOK
widthError:
	mov	ax, offset ColumnTooNarrowString
error:
	call	DisplayError
	stc
	jmp	done

regionOK:
	clc
done:
	.leave
	ret

ValidateNewPageSetup	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalculateSection

DESCRIPTION:	Recalculate the master pages for a section

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - section array element

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 4/92		Initial version

------------------------------------------------------------------------------@
RecalculateSection	proc	far
EC <	call	AssertIsWriteDocument					>

	; Recalculate the master pages for the document

	clr	bx
	mov	cx, es:[di].SAE_numMasterPages
recalcLoop:
	mov	ax, es:[di][bx].SAE_masterPages
	tst	ax
	jnz	notNew
	call	DuplicateMasterPage		;create a new master page
	mov	es:[di][bx].SAE_masterPages, ax
notNew:
	call	RecalcMPFlowRegions

	push	bx, cx
	call	FindOpenMasterPage
	mov	dx, bx				;dx = display block
	pop	bx, cx
	jnc	noRename
	call	SetMPDisplayName
noRename:

	add	bx, size word
	loop	recalcLoop

	; Check for extra (unneeded) master pages at the end

checkExtraMasterPageLoop:
	cmp	bx, MAX_MASTER_PAGES * (size word)
	jz	afterCheckMP
	clr	ax
	xchg	ax, es:[di][bx].SAE_masterPages
	tst	ax
	jz	afterCheckMP
	call	VMDirtyES
	call	DeleteMasterPage
	add	bx, size word
	jmp	checkExtraMasterPageLoop
afterCheckMP:

	; now recalculate the article regions for the section

	call	RecalculateArticleRegions

	ret

RecalculateSection	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalculateArticleRegions

DESCRIPTION:	Recalculate the article regions

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - section array element

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/12/92		Initial version

------------------------------------------------------------------------------@
RecalculateArticleRegions	proc	far
	class	WriteDocumentClass

EC <	call	AssertIsWriteDocument					>

	push	ds
	call	WriteGetDGroupDS
	test	ds:[miscSettings], mask WMS_AUTOMATIC_LAYOUT_RECALC
	pop	ds
	jz	noRecalc

	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	tst	ds:[bx].WDI_mpBodySuspendCount
	jz	recalc
	ornf	ds:[bx].WDI_state, mask WDS_RECALC_ABORTED

noRecalc:
	ornf	es:[di].SAE_flags, mask SF_NEEDS_RECALC
	call	VMDirtyES
	ret

recalc:
	call	RecalculateArticleRegionsLow
	ret

RecalculateArticleRegions	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalculateArticleRegionsLow

DESCRIPTION:	Recalculate the article regions ignoring the MANUAL flag

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - section array element

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/12/92		Initial version

------------------------------------------------------------------------------@
RecalculateArticleRegionsLow	proc	far
EC <	call	AssertIsWriteDocument					>

	call	SuspendFlowRegionNotifications
	call	SuspendDocument

	push	bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	bp

	; recalculate the paths stored with the flow regions for each master
	; page

	clr	bx
	mov	cx, es:[di].SAE_numMasterPages
destroyLoop:
	mov	ax, es:[di][bx].SAE_masterPages
	call	RecalculateMPTextFlowRegions
	add	bx, size word
	loop	destroyLoop

	push	es:[di].SAE_numPages

	push	si, ds
	segmov	ds, es
	mov	si, offset SectionArray
	call	ChunkArrayPtrToElement
	pop	si, ds
	mov_tr	dx, ax				;dx = section number

	call	GetFileHandle
	mov	cx, bx

	; delete all old flow regions

	push	si, ds, es
	segmov	ds, es
	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset DeleteArticleRegionsInSectionCallback
	call	ChunkArrayEnum
	pop	si, ds, es
	pop	cx				;cx = num pages
	mov_tr	ax, dx				;ax = section

	; create flow regions for all pages

	clr	bx
pageLoop:
	push	cx
	mov	cx, 0x0100			;pass "create only" flag
	clr	dx				;not direct user action
	call	AddDeletePageToSection
	pop	cx

if	_REGION_LIMIT
	jc	done
endif		
	inc	bx
	loop	pageLoop

	call	UnsuspendDocument

if	_REGION_LIMIT
done:
endif		
	call	UnsuspendFlowRegionNotifications
	ret

RecalculateArticleRegionsLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteArticleRegionsInSectionCallback

DESCRIPTION:	Delete all article regions in a given section

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleArrayElement
	cx - vm file
	dx - section number

RETURN:
	carry - set to end (always returned clear)

DESTROYED:
	ax, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/27/92		Initial version

------------------------------------------------------------------------------@
DeleteArticleRegionsInSectionCallback	proc	far
	push	ds:[LMBH_handle]
	segmov	es, ds				;es = map block

	mov	bx, cx
	mov	ax, ds:[di].AAE_articleBlock
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	push	bx
	call	ObjLockObjBlock
	mov	ds, ax				;ds = article block

	mov	si, offset ArticleRegionArray
	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_count
	jcxz	done
	add	di, ds:[di].CAH_offset

deleteLoop:
	cmp	dx, ds:[di].VLTRAE_section
	jnz	next
	call	DeleteArticleRegion
	sub	di, size ArticleRegionArrayElement
next:
	add	di, size ArticleRegionArrayElement
	loop	deleteLoop
done:
	pop	bx
	call	MemUnlock

	pop	bx
	call	MemDerefDS

	clc
	ret

DeleteArticleRegionsInSectionCallback	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentReportPageSize -- MSG_PRINT_REPORT_PAGE_SIZE
							for WriteDocumentClass

DESCRIPTION:	Handle a change in the page size

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	ss:bp - PageSizeReport

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 1/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentReportPageSize	method dynamic	WriteDocumentClass,
						MSG_PRINT_REPORT_PAGE_SIZE

	mov	ax, ss:[bp].PSR_width.low
	mov	bx, ss:[bp].PSR_height.low
	mov	cx, ss:[bp].PSR_layout
	clr	dx

newHeight	local	word		push	bx
newWidth	local	word		push	ax
layout		local	PageLayout	push	cx
document	local	optr		push	ds:[LMBH_handle], si
oldWidth	local	dword		push	dx, dx
oldHeight	local	dword		push	dx, dx
fileHandle	local	hptr
widthChange	local	dword
heightChange	local	dword
insDelParams	local	InsertDeleteSpaceParams
if _LABELS
newMargin	local	word
endif
	.enter

	call	LockMapBlockES

	; verify that this new page setup is legal, given the page size

	call	ValidateNewPageSize
	LONG jc	done

if	_REGION_LIMIT
	;
	; If we're enforcing region limits, auto-save the document before
	; changing the page size.  If the auto-save fails, don't change
	; the page size. 
	;
	call	ForceAutoSave
	LONG	jc	done		
endif		

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, newWidth
	mov	bx, newHeight
	mov	cx, layout
	mov	ds:[di].WDI_pageHeight, bx
	mov	ds:[di].WDI_size.PD_x.low, ax
	call	IgnoreUndoAndFlush
	call	VMDirtyES

	; DON'T suspend notifications because deleting space may cause
	; flow regions to be deleted, and we want to make sure we get
	; notification so that we clean up our ArticleArrayElement
	; structures.  Fail case is taking a multi-page document and
	; converting the page size to 1-inch high labels. -chrisb 5/94
		
;;	call	SuspendFlowRegionNotifications

	; Set common parameters

	clr	dx
	mov	insDelParams.IDSP_type, mask IDST_MOVE_OBJECTS_BELOW_AND_RIGHT_OF_INSERT_POINT_OR_DELETED_SPACE or mask IDST_RESIZE_OBJECTS_INTERSECTING_SPACE or mask IDST_DELETE_OBJECTS_SHRUNK_TO_ZERO_SIZE
	mov	insDelParams.IDSP_position.PDF_x.DWF_frac, dx
	mov	insDelParams.IDSP_space.PDF_x.DWF_frac, dx
	mov	insDelParams.IDSP_position.PDF_y.DWF_frac, dx
	mov	insDelParams.IDSP_space.PDF_y.DWF_frac, dx

	; First update the variables in the map block

	mov	es:MBH_pageInfo, cx
	mov	cx, ax
	mov	dx, bx
	xchg	cx, es:MBH_pageSize.XYS_width		;store new, get old
	xchg	dx, es:MBH_pageSize.XYS_height

	mov	oldWidth.low, cx
	mov	oldHeight.low, dx

	call	SendPageSizeToView

	sub	ax, cx				;ax = width change
	sub	bx, dx				;bx = height change
	push	bx
	cwd
	movdw	widthChange, dxax
	pop	ax
	cwd
	movdw	heightChange, dxax

	call	GetFileHandle
	mov	fileHandle, bx

	; Change the width of the main body

	movdw	insDelParams.IDSP_position.PDF_x.DWF_int, oldWidth, ax
	movdw	insDelParams.IDSP_space.PDF_x.DWF_int, widthChange, ax
	clrdw	insDelParams.IDSP_position.PDF_y.DWF_int
	clrdw	insDelParams.IDSP_space.PDF_y.DWF_int

	call	MarkBusy
	call	SuspendDocument
		
	mov	ax, es:MBH_grobjBlock
	call	WriteVMBlockToMemBlock
	mov_tr	bx, ax
	mov	si, offset MainBody
	call	callSpace

	; Now go through all the pages moving graphics as needed

	; note that this is an O(N^2) algorithm, since for each page we add
	; space, which causes the grobj to send a message to every grobj
	; object -- sigh

	mov	cx, es:MBH_totalPages
	clrdw	dxax
resizeLoop:
	pushdw	dxax
	adddw	dxax, oldHeight
	movdw	insDelParams.IDSP_position.PDF_y.DWF_int, dxax
	movdw	insDelParams.IDSP_space.PDF_y.DWF_int, heightChange, di
	clrdw	insDelParams.IDSP_position.PDF_x.DWF_int
	clrdw	insDelParams.IDSP_space.PDF_x.DWF_int
	popdw	dxax
	add	ax, newHeight
	adc	dx, 0
	call	callSpace
	loop	resizeLoop

	; Loop through each section, changing the bounds of the master pages
	; and recalculating the page setup

	movdw	insDelParams.IDSP_position.PDF_x.DWF_int, oldWidth, ax
	movdw	insDelParams.IDSP_space.PDF_x.DWF_int, widthChange, ax
	movdw	insDelParams.IDSP_position.PDF_y.DWF_int, oldHeight, ax
	movdw	insDelParams.IDSP_space.PDF_y.DWF_int, heightChange, ax

	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset ChangeSectionPageSizeCallback
	call	ChunkArrayEnum

	; Reset the bounds of the document

	movdw	bxsi, document
	call	MemDerefDS

	call	UnsuspendDocument
	call	MarkNotBusy
		
	; update the size stored in the views

	call	SendDocumentSizeToView

	push	si
	mov	di, ds:[OpenMasterPageArray]
	mov	cx, ds:[di].CAH_count
	jcxz	noMasterPages
	add	di, ds:[di].CAH_offset
resizeMPLoop:
	push	cx
	mov	ax, ds:[di].OMP_vmBlock
	mov	bx, ds:[di].OMP_display
	mov	cx, ds:[di].OMP_content
	call	SendMPSizeToView
	add	di, size OpenMasterPage
	pop	cx
	loop	resizeMPLoop
noMasterPages:
	pop	si					;document chunk

;;	call	UnsuspendFlowRegionNotifications

	call	AcceptUndo

done:

if _LABELS
	; If we've changed to or from labels, we've then changed the margins
	; So, we'd better update the PageSetup dialog box, if it is currently
	; visible

	tst	ss:[newMargin]				;if no new margin
	jz	afterNotification			;no need to do this.
	mov	ax, mask NF_SECTION			;update section data
	call	SendNotification
afterNotification:
endif

	call	VMUnlockES


if _REGION_LIMIT
	;
	; Everything is okay, so enable auto-save.
	; It was turned off in ForceAutoSave
	;
	call	EnableAutoSave
endif
	.leave
	ret

;---

callSpace:
	push	ax, cx, dx, bp
	lea	bp, insDelParams
 	mov	ax, MSG_VIS_LAYER_INSERT_OR_DELETE_SPACE
	call	DPS_ObjMessageNoFlags
	pop	ax, cx, dx, bp
	retn

WriteDocumentReportPageSize	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	ValidateNewPageSize

DESCRIPTION:	Validate the user's changes to the Page Size dialog box

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block
	ss:bp - inherited variables (including newHeight and newWidth)

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/22/93		Initial version

------------------------------------------------------------------------------@
ValidateNewPageSize	proc	near	uses si, ds
	class	WriteDocumentClass
	.enter inherit WriteDocumentReportPageSize

if _LABELS
	; Let's see if we are changing to or from labels

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	clr	dx
	mov	cx, layout
	and	cx, mask PLP_TYPE		; new PageType -> cx
	mov	ax, es:MBH_pageInfo
	and	ax, mask PLP_TYPE		; old PageType -> ax
	cmp	ax, cx
	je	verifySections
	cmp	ax, PT_LABEL
	je	pageTypeChange
	cmp	cx, PT_LABEL
	jne	verifySections

pageTypeChange:
	; Calculate the new (default) margin for all sections, and
	; the minimum margin table to use if all sections check out

	mov	dx, US_DEFAULT_DOCUMENT_MARGIN
	cmp	cx, PT_LABEL
	jne	verifySections
	mov	dx, US_DEFAULT_LABEL_MARGIN
verifySections:
	mov	ss:[newMargin], dx		; save new margin value
endif

	; Verify all sections in the document

	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset ValidateSectionForNewPageSize
	call	ChunkArrayEnum
	jnc	done
	call	DisplayError
	stc
done:
	.leave
	ret
ValidateNewPageSize	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ValidateSectionForNewPageSize

DESCRIPTION:	Validate that the given section is legal for the new page size

CALLED BY:	INTERNAL

PASS:
	ds:di - SectionArrayElement
	ss:bp - inherited variables (including newHeight and newWidth)

RETURN:
	carry - set if error
		ax - error message if error

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/22/93		Initial version

------------------------------------------------------------------------------@
ValidateSectionForNewPageSize	proc	far
	.enter inherit WriteDocumentReportPageSize

	; to be legal in Y the columns must be at least 1 inch high

	mov	bx, ds:[di].SAE_topMargin
	add	bx, ds:[di].SAE_bottomMargin
if _LABELS
	mov	ax, ss:[newMargin]
	tst	ax
	jz	doneMarginCheck1
	mov_tr	bx, ax
	shl	bx, 1				; double margin for top & bottom
ifdef _VS150
	cmp	ax, US_DEFAULT_DOCUMENT_MARGIN	;on the VS150, the bottom margin
	jne	doneVS150			;needs to be 1/4 inches, so
	add	ax, (18*8)			;we adjust as needed
doneVS150:
endif
doneMarginCheck1:
endif
	shr	bx
	shr	bx
	shr	bx				;convert to points
	mov	ax, newHeight
	sub	ax, bx				;ax = column height
	jbe	heightError
	cmp	ax, MINIMUM_COLUMN_HEIGHT
	jae	heightOK
heightError:
	mov	ax, offset PageSizeColumnTooShortString
	jmp	error

heightOK:

	; to be legal in X the column with must be OK

	; totalColumnSpacing = (numColumns-1) * columnSpacing

	mov	ax, ds:[di].SAE_numColumns
	dec	ax
	mul	ds:[di].SAE_columnSpacing	;ax = total spacing
if _LABELS
	mov	bx, ss:[newMargin]
	tst	bx
	jz	doneMarginCheck2
	shl	bx, 1				; double margin for left & right
	add	ax, bx
	jmp	continue
doneMarginCheck2::
endif
	add	ax, ds:[di].SAE_leftMargin
	add	ax, ds:[di].SAE_rightMargin
continue::
	shr	ax
	shr	ax
	shr	ax
	mov_tr	bx, ax

	; calculate the column width
	;	= (pageWidth - totalSpacing) / numColumns

	mov	ax, newWidth
	sub	ax, bx
	jc	widthError
	div	ds:[di].SAE_numColumns
	cmp	ax, MINIMUM_COLUMN_WIDTH
	jae	regionOK
widthError:
	mov	ax, offset PageSizeColumnTooNarrowString
error:
	stc
	jmp	done

regionOK:
	clc
done:
	.leave
	ret

ValidateSectionForNewPageSize	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ChangeSectionPageSizeCallback

DESCRIPTION:	Change the page size for a section

CALLED BY:	WriteDocumentReportPageSize (via ChunkArrayEnum)

PASS:
	ds:di - SectionArrayElement
	ss:bp - inherited variables (from WriteDocumentReportPageSize)

RETURN:
	carry - clear (continue enumeration)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 1/92		Initial version

------------------------------------------------------------------------------@
ChangeSectionPageSizeCallback	proc	far
	.enter inherit WriteDocumentReportPageSize

	push	ds:[LMBH_handle]

	; loop through each master page

	mov	cx, ds:[di].SAE_numMasterPages
	clr	bx
changeSizeLoop:
	push	bx

	mov	ax, ds:[di][bx].SAE_masterPages
	mov	bx, fileHandle
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	mov	si, offset MasterPageBody

	; change the bounds of the body

	push	bp
	lea	bp, insDelParams
 	mov	ax, MSG_VIS_LAYER_INSERT_OR_DELETE_SPACE
	call	DPS_ObjMessageNoFlags
	pop	bp

	pop	bx
	add	bx, size hptr
	loop	changeSizeLoop

	; and recalculate the master page

	segmov	es, ds				;es:di = SectionArrayElement
	movdw	bxsi, document
	call	MemDerefDS

if _LABELS
	; because of labels, we may have changed the default margins
	; for each section. If so, do this work now

	mov	ax, ss:[newMargin]
	tst	ax
	jz	doRecalc
	mov	es:[di].SAE_leftMargin, ax
	mov	es:[di].SAE_rightMargin, ax
if _DWP
	cmp	ax, US_DEFAULT_LABEL_MARGIN
	jne	setTopMargin
	mov	es:[di].SAE_leftMargin, MINIMUM_LEFT_MARGIN_SIZE
	mov	es:[di].SAE_rightMargin, MINIMUM_RIGHT_MARGIN_SIZE
setTopMargin:
endif
	mov	es:[di].SAE_topMargin, ax
ifdef _VS150
	cmp	ax, US_DEFAULT_DOCUMENT_MARGIN	;on the VS150, the bottom margin
	jne	setBottomMargin			;needs to be 1/4 inches, so
	add	ax, (18*8)			;we adjust as needed
setBottomMargin:
endif
	mov	es:[di].SAE_bottomMargin, ax
doRecalc:
endif
	call	RecalculateSection

	pop	bx
	call	MemDerefDS

	clc
	.leave
	ret

ChangeSectionPageSizeCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalcMPFlowRegions

DESCRIPTION:	Recalculate flow regions for a master page

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - SectionArrayElement
	bx - master page number * 2
	ax - master page VM block

RETURN:
	ds - fixed up

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
RecalcMPFlowRegions	proc	far	uses ax, bx, cx, dx, si, bp, di
	.enter

	mov	cx, di				;save SAE offset
	mov	di, 1500
	call	ThreadBorrowStackSpace
	push	di
	mov	di, cx				;restore SAE offset

EC <	call	AssertIsWriteDocument					>

	call	IgnoreUndoAndFlush

	call	SuspendFlowRegionNotifications

	mov	cx, bx				;save master page # (*2)

	; lock master page block into DS

	call	WriteVMBlockToMemBlock
	mov_tr	bx, ax
	call	ObjSwapLock
	push	bx				;save master page block
	push	cx				;save master page #

	; delete old flow regions for page

	push	di
	mov	si, offset FlowRegionArray
	mov	bx, cs
	mov	di, offset DeleteFlowRegionCallback
	call	ChunkArrayEnum
	pop	di
	call	ChunkArrayZero

	; create new flow regions for page based on page setup

	; totalColumnSpacing = (numColumns-1) * columnSpacing

	mov	ax, es:[di].SAE_numColumns
	dec	ax
	mov	cx, es:[di].SAE_columnSpacing
	call	ConvertToPixelsCX
	mul	cx				;ax = total spacing

	; calculate the column width
	;	= (pageWidth - totalSpacing) / numColumns

	mov	bx, es:MBH_pageSize.XYS_width
	mov	cx, es:[di].SAE_leftMargin
	call	ConvertToPixelsCX
	sub	bx, cx				;bx = page width - left
EC <	ERROR_C	BAD_COLUMN_WIDTH					>
	mov	cx, es:[di].SAE_rightMargin
	call	ConvertToPixelsCX
	sub	bx, cx				;bx = live text width
EC <	ERROR_C	BAD_COLUMN_WIDTH					>
	sub	bx, ax				;subtract out spacing
EC <	ERROR_C	BAD_COLUMN_WIDTH					>

	mov_tr	ax, bx
	clr	dx				;dx.ax = (width - spacing)
	div	es:[di].SAE_numColumns		;ax = width, dx = remainder
EC <	cmp	ax, MINIMUM_COLUMN_WIDTH				>
EC <	ERROR_B	BAD_COLUMN_WIDTH					>
	mov_tr	bp, ax				;bp = column width

	; get the left position for the columns (this is tricky if there
	; are two master pages)

	pop	bx				;bx = master page # (*2)
	mov	ax, es:[di].SAE_leftMargin	;position to create at
	cmp	es:[di].SAE_numMasterPages, 1
	jz	oneMasterPage
	tst	bx
	jz	oneMasterPage
	mov	ax, es:[di].SAE_rightMargin
oneMasterPage:

	call	ConvertToPixelsAX

	; loop to create the columns

	mov	cx, es:[di].SAE_numColumns
	mov	si, offset FlowRegionArray

	;	ax = current left side
	;	cx = number of columns (counter)
	;	bp = column width
	;	dx = remainder (extra pixels to distribute)

columnLoop:
	push	cx, bp

	; set carry to create rule

	cmp	cx, 1
	clc
	jz	noRule
	tst_clc	es:[di].SAE_ruleWidth
	jz	noRule
	stc
noRule:
	pushf

	; calcuate column bounds

	mov	cx, ax
	add	cx, bp
	tst	dx
	jz	noExtraPixelsToDistribute
	inc	cx
	dec	dx
noExtraPixelsToDistribute:

	popf
	push	dx				;save # extra pixels
	pushf
	push	ax
	mov	ax, es:[di].SAE_topMargin
	call	ConvertToPixelsAX
	mov_tr	bx,ax
	mov	dx, es:MBH_pageSize.XYS_height
	mov	ax, es:[di].SAE_bottomMargin
	call	ConvertToPixelsAX
	sub	dx, ax
	pop	ax
	clr	bp				;use main article
	popf					;pass rule flag
	call	CreateMPFlowRegion

	mov_tr	ax, cx				;new left = old right
	mov	cx, es:[di].SAE_columnSpacing
	call	ConvertToPixelsCX
	add	ax, cx
	pop	dx				;recover # extra pixels
	pop	cx, bp
	loop	columnLoop

	; Create/move header and footer objects

	; Note that we must create the object one pixel larger on each
	; edge than we really want it to be because the text will end up
	; being inset one pixel

	; Header...

	mov	ax, HEADER_FOOTER_INSET_X-1		;ax = left

if _DWP
	mov	bx, HEADER_FOOTER_INSET_TOP-1		;bx = top
else
	mov	bx, HEADER_FOOTER_INSET_Y-1		;bx = top
endif
	mov	cx, es:MBH_pageSize.XYS_width
	sub	cx, ax					;cx = right
	inc	cx
	mov	dx, es:[di].SAE_topMargin
	call	ConvertToPixelsDX
	sub	dx, HEADER_FOOTER_SPACING		;dx = bottom
	inc	dx
	push	ax, cx, di
	mov	di, offset MPBH_header
	clr	bp					;header
	call	createDeleteHeaderFooter
	pop	ax, cx, di

	; Footer...

	mov	dx, es:MBH_pageSize.XYS_height
	mov	bx, dx

if _DWP
	sub	dx, HEADER_FOOTER_INSET_BOTTOM		;dx= bottom
else
	sub	dx, HEADER_FOOTER_INSET_Y		;dx= bottom
endif
	inc	dx
	push	ax
	mov	ax, es:[di].SAE_bottomMargin
	call	ConvertToPixelsAX
	sub	bx, ax
	pop	ax
	add	bx, HEADER_FOOTER_SPACING		;bx = top
	dec	bx
	push	di
	mov	di, offset MPBH_footer
	mov	bp, 1					;footer
	call	createDeleteHeaderFooter
	pop	di

	pop	bx
	call	ObjSwapUnlock

	call	UnsuspendFlowRegionNotifications

	call	AcceptUndo

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

	; pass:
	;	ax, bx, cx, dx = bounds
	;	ds:di = &optr
	;	bp = non-zero for footer
	; destroy:
	;	ax, bx, cx, dx, si, di, bp

createDeleteHeaderFooter:
	push	dx
	sub	dx, bx
	cmp	dx, MINIMUM_HEADER_FOOTER_HEIGHT 
	pop	dx
	LONG jl	noHeaderFooter

	sub	cx, ax				;cx = width
	sub	dx, bx				;dx = height
	tst	ds:[di].handle
	jz	createNewHeaderFooter

	; move the existing header/footer

	push	bx
	mov	bx, ds:[di].handle
	call	VMBlockToMemBlockRefDS		;bx = handle
	mov	si, bx
	pop	bx

	push	ds:[LMBH_handle]
	push	si, ds:[di].chunk		;push object optr
	clr	di
	push	di				;push y pos high
	call	MoveGrObj
	pop	bx
	call	MemDerefDS
	retn

	; ax, bx, cx, dx = bounds
	; bp = non-zero for footer
	; destroy: bx, cx, dx

createNewHeaderFooter:

	; create a new header/footer

	push	ds:[LMBH_handle], di

	clr	di
	push	di				;push y pos high
	push	ds:[LMBH_handle]
	mov	di, offset MasterPageBody
	push	di				;push body optr
	mov	di, segment WriteHdrFtrGuardianClass
	push	di
	mov	di, offset WriteHdrFtrGuardianClass ;push class pointer
	push	di
	mov	di, GRAPHIC_STYLE_HEADER_FOOTER
	push	di

	tst	bp
	jnz	footer
	mov	di, TEXT_STYLE_HEADER
	jmp	hfCommon
footer:
	mov	di, TEXT_STYLE_FOOTER
hfCommon:
	push	di
	mov	di, HEADER_FOOTER_LOCKS
	push	di
	call	CreateGrObj			;cx:dx = new object

	pop	bx, di
	call	MemDerefDS
	call	MemBlockToVMBlockCX
	movdw	ds:[di], cxdx

	retn

noHeaderFooter:
	clrdw	bxsi
	xchgdw	bxsi, ds:[di]
	tst	bx
	jz	noHeaderFooterToDelete

	call	VMBlockToMemBlockRefDS		;bx = handle
	clr	cx
	mov	dx, mask GrObjLocks		;clear all the locks so that
	mov	ax, MSG_GO_CHANGE_LOCKS		;we can delete the object
	call	DPS_ObjMessageFixupDS
	mov	ax, MSG_GO_CLEAR
	call	DPS_ObjMessageFixupDS
noHeaderFooterToDelete:
	retn

RecalcMPFlowRegions	endp

;---

ConvertToPixelsAX	proc	near
	add	ax, 4
	shr	ax
	shr	ax
	shr	ax
	ret
ConvertToPixelsAX	endp

;---

ConvertToPixelsCX	proc	near
	xchg	ax, cx
	call	ConvertToPixelsAX
	xchg	ax, cx
	ret
ConvertToPixelsCX	endp

;---

ConvertToPixelsDX	proc	near
	xchg	ax, dx
	call	ConvertToPixelsAX
	xchg	ax, dx
	ret
ConvertToPixelsDX	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteFlowRegionCallback

DESCRIPTION:	Callback to delete the objects associated with a flow region

CALLED BY:	INTERNAL

PASS:
	*ds:si - array
	ds:di - FlowRegionArrayElement

RETURN:
	carry - set to end (always return clear)

DESTROYED:
	ax, bx, cx, dx, si, di, bp, es - can destroy

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
DeleteFlowRegionCallback	proc	far

	; delete the associated GrObj object

	movdw	bxsi, ds:[di].FRAE_flowObject
	call	VMBlockToMemBlockRefDS
	mov	ax, MSG_GO_CLEAR
	call	DPS_ObjMessageFixupDS

	call	DeleteFlowRegionAccessories

	clc
	ret

DeleteFlowRegionCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteFlowRegionAccessories

DESCRIPTION:	Delete the accessory objects to a flow region

CALLED BY:	INTERNAL

PASS:
	ds:di - FlowRegionArrayElement

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/13/92		Initial version

------------------------------------------------------------------------------@
DeleteFlowRegionAccessories	proc	far	uses si, di, bp
	.enter

	movdw	bxsi, ds:[di].FRAE_ruleObject
	tst	bx
	jz	noRuleObject
	call	VMBlockToMemBlockRefDS
	clr	cx
	mov	dx, mask GrObjLocks		;clear all the locks so that
	mov	ax, MSG_GO_CHANGE_LOCKS		;we can delete the rule object
	call	DPS_ObjMessageFixupDS
	mov	ax, MSG_GO_CLEAR
	call	DPS_ObjMessageFixupDS
noRuleObject:

	; free the region chunk

	mov	ax, offset FRAE_textRegion
	call	DBFreeRefDS
	mov	ax, offset FRAE_drawRegion
	call	DBFreeRefDS

	.leave
	ret

DeleteFlowRegionAccessories	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DBFreeRefDS

DESCRIPTION:	Free a db item, getting the file from DS

CALLED BY:	INTERNAL

PASS:
	ds:[di][ax] - db item to free
	ds - block owned by VM file

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/15/92		Initial version

------------------------------------------------------------------------------@
DBFreeRefDS	proc	far	uses di
	.enter

	add	di, ax
	mov	ax, ds:[di].high
	tst	ax
	jz	done
	mov	di, ds:[di].low

	push	bx
	push	ax
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo			;ax = VM file
	mov_tr	bx, ax				;bx = file
	pop	ax
	call	DBFree
	pop	bx
done:
	.leave
	ret

DBFreeRefDS	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateMPFlowRegion

DESCRIPTION:	Create a flow region for a master page

CALLED BY:	INTERNAL

PASS:
	*ds:si - flow region array
	ax, bx, cx, dx - region bounds
	es:di - SectionArrayElement
	bp - article
	carry - set to create rule

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
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
CreateMPFlowRegion	proc	near	uses ax, bx, cx, dx, di
	.enter

	pushf					;save rule flag

	; add an element to the array of flow regions for the master page

	sub	cx, ax				;cx = width
	sub	dx, bx				;dx = height
	push	ax, bx, cx, dx, di
	call	ChunkArrayAppend		;ds:di = FlowRegionArrayElement
	mov	ds:[di].FRAE_article, bp
	mov	ds:[di].FRAE_position.XYO_x, ax
	mov	ds:[di].FRAE_position.XYO_y, bx
	mov	ds:[di].FRAE_size.XYS_width, cx
	mov	ds:[di].FRAE_size.XYS_height, dx

	; create a GrObj object for the flow region

	push	ds:[LMBH_handle]

	clr	di
	push	di				;push y pos high
	push	ds:[LMBH_handle]
	mov	di, offset MasterPageBody
	push	di				;push body optr
	mov	di, segment FlowRegionClass
	push	di
	mov	di, offset FlowRegionClass	;push class pointer
	push	di
	mov	di, GRAPHIC_STYLE_FLOW_REGION
	push	di
	mov	di, CA_NULL_ELEMENT
	push	di				;textStyle
	mov	di, MASTER_PAGE_FLOW_REGION_LOCKS
	push	di
	call	CreateGrObj			;cx:dx = new object
	pop	bx
	call	MemDerefDS

	; tell the flow region what master page block it is associated with

	mov	bx, ds:[LMBH_handle]
	call	VMMemBlockToVMBlock		;ax = master page VM block
	clr	bx				;bx = article VM block
	call	SetFlowRegionAssociation

	mov	ax, CA_LAST_ELEMENT
	call	ChunkArrayElementToPtr
	call	MemBlockToVMBlockCX
	movdw	ds:[di].FRAE_flowObject, cxdx

	pop	ax, bx, cx, dx, di

	; create ruler object

	popf
	jnc	noRule

	; gutter goes from top to bottom, left = right  = right + spacing/2

	push	ds:[LMBH_handle], si
	add	ax, cx				;ax = right side of region

	mov	cx, es:[di].SAE_ruleWidth
	call	ConvertToPixelsCX
	push	cx				;save rule width

	mov	cx, es:[di].SAE_columnSpacing
	call	ConvertToPixelsCX
	shr	cx
	add	ax, cx				;ax = object pos
	clr	cx				;width = 0

	clr	di
	push	di				;push y pos high
	push	ds:[LMBH_handle]
	mov	di, offset MasterPageBody
	push	di				;push body optr
	mov	di, segment LineClass
	push	di
	mov	di, offset LineClass		;push class pointer
	push	di
	mov	di, GRAPHIC_STYLE_RULE
	push	di
	mov	di, CA_NULL_ELEMENT
	push	di				;textStyle
	mov	di, RULE_LOCKS
	push	di
	call	CreateGrObj			;cx:dx = new object

	movdw	bxsi, cxdx
	pop	dx
	clr	cx				;dx.cx = width
	mov	ax, MSG_GO_SET_LINE_WIDTH
	call	DPS_ObjMessageNoFlags
	movdw	cxdx, bxsi

	pop	bx, si
	call	MemDerefDS

	mov	ax, CA_LAST_ELEMENT
	call	ChunkArrayElementToPtr
	call	MemBlockToVMBlockCX
	movdw	ds:[di].FRAE_ruleObject, cxdx

noRule:

	.leave
	ret

CreateMPFlowRegion	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentResetReapplyMasterPage --
		MSG_WRITE_DOCUMENT_RESET_REAPPLY_MASTER_PAGE
						for WriteDocumentClass

DESCRIPTION:	Reapply the master page for the section after resetting
		the master page

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/29/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentResetReapplyMasterPage	method dynamic	WriteDocumentClass,
				MSG_WRITE_DOCUMENT_RESET_REAPPLY_MASTER_PAGE

	stc
	GOTO	ReapplyCommon

WriteDocumentResetReapplyMasterPage	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentReapplyExistingMasterPage --
		MSG_WRITE_DOCUMENT_REAPPLY_EXISTING_MASTER_PAGE
							for WriteDocumentClass

DESCRIPTION:	Reapply the master page for the section

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/29/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentReapplyExistingMasterPage	method dynamic	WriteDocumentClass,
				MSG_WRITE_DOCUMENT_REAPPLY_EXISTING_MASTER_PAGE

	clc
	FALL_THRU	ReapplyCommon

WriteDocumentReapplyExistingMasterPage	endm

;---

	; carry set to reset and reapply

ReapplyCommon	proc	far
	class	WriteDocumentClass
	pushf

	push	ds:[di].WDI_currentSection

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	call	LockMapBlockES

	call	IgnoreUndoNoFlush
	call	SuspendDocument

	pop	ax
	call	SectionArrayEToP_ES

	popf
	jnc	10$
	call	RecalculateSection
	jmp	common
10$:
	call	RecalculateArticleRegions
common:

	call	UnsuspendDocument
	call	AcceptUndo

	mov	ax, mask NF_PAGE or mask NF_TOTAL_PAGES
	call	SendNotification

	call	VMUnlockES

	ret

ReapplyCommon	endp


DocPageSetup ends
