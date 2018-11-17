COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentNotify.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the VisContent related code for WriteDocumentClass

	$Id: documentNotify.asm,v 1.1 97/04/04 15:56:44 newdeal Exp $

------------------------------------------------------------------------------@

DocNotify segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	LockAndSendNotification

DESCRIPTION:	Load the map block and send notification

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	ax - NotifyFlags (0 if we are losing the target)

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
	Tony	9/23/92		Initial version

------------------------------------------------------------------------------@
LockAndSendNotification	proc	far	uses es
	.enter

	call	LockMapBlockES
	call	SendNotification
	call	VMUnlockES

	.leave
	ret

LockAndSendNotification	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendNotification

DESCRIPTION:	Send notification block(s) out

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block (locked)
	ax - NotifyFlags (0 if we are losing the target)

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
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
SendNotification	proc	far	uses ax, bx, cx, dx, di, bp
data		local	UIUpdateData
gcnParams	local	GCNListMessageParams
	.enter
	class	WriteDocumentClass

EC <	call	AssertIsWriteDocument					>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ax
	jz	10$
	test	ds:[di].WDI_state, mask WDS_MODEL
	LONG jz	done
10$:

	mov	data.UIUD_updateFlags, ax

	;--------------------------------------
	; Generate NotifyPageStateChange
	;--------------------------------------

	push	ax, si
	clr	bx
	tst	ax
	jz	gotBlock
	test	ax, mask NF_PAGE
	LONG jz	afterPage

	push	di
	clr	ax
	call	SectionArrayEToP_ES		;es:di = first section
	mov	cx, es:[di].SAE_startingPageNum
	mov	dx, es:MBH_totalPages
	pop	di

	push	es
	push	cx
	mov	ax, size NotifyPageStateChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	es, ax
	pop	cx

	mov	ax, ds:[di].WDI_currentPage
	add	ax, cx
	mov	es:[NPSC_currentPage], ax
	mov	es:[NPSC_firstPage], cx
	add	dx, cx
	dec	dx
	mov	es:[NPSC_lastPage], dx
	pop	es

	call	MemUnlock
	mov	ax, 1
	call	MemInitRefCount

gotBlock:
	push	bp
	mov	bp, bx
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_PAGE_STATE_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bp

	mov	gcnParams.GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	gcnParams.GCNLMP_ID.GCNLT_type,
				GAGCNLT_APP_TARGET_NOTIFY_PAGE_STATE_CHANGE
	mov	gcnParams.GCNLMP_block, bx
	mov	gcnParams.GCNLMP_event, di

	; if clearing status, meaning we're no longer the target, set bit to
	; indicate this clearing should be avoided if the status will get
	; updated by a new target.

	mov	ax, mask GCNLSF_SET_STATUS
	tst	bx
	jnz	afterTransitionCheck
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
afterTransitionCheck:
	mov	gcnParams.GCNLMP_flags, ax

	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST   ; Update GCN list
	mov	dx, size GCNListMessageParams		   ; create stack frame
	push	bp
	lea	bp, gcnParams
	call	GenSendToProcessStack
	pop	bp

afterPage:
	pop	ax, si

	;--------------------------------------
	; Send out notification to the app object
	;--------------------------------------

	tst	ax				;if losing the target
	LONG jz	done				;then bail

	push	ax
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	clr	ax
	test	ds:[di].WDI_state, mask WDS_TARGET
	jz	20$
	ornf	ax, mask UIUF_DOCUMENT_IS_TARGET
20$:
	call	DoesTitlePageExist
	jnc	30$
	ornf	ax, mask UIUF_TITLE_PAGE_EXISTS
30$:
	mov	data.UIUD_flags, ax

	mov	ax, es:MBH_startingSectionNum
	mov	data.UIUD_startingSectionNum, ax

	push	di
	clr	ax
	call	SectionArrayEToP_ES		;es:di = SectionArrayElement
	mov	ax, es:[di].SAE_startingPageNum
	mov	data.UIUD_startingPageNum, ax
	pop	di

	mov	ax, es:MBH_totalPages
	mov	data.UIUD_totalPages, ax
	mov	ax, ds:[di].WDI_currentPage
	mov	data.UIUD_currentPage, ax
	movdw	data.UIUD_pageSize, es:MBH_pageSize, ax
	mov	ax, es:MBH_pageInfo
	mov	data.UIUD_pageInfo, ax
	mov	ax, es:MBH_displayMode
	mov	data.UIUD_displayMode, ax

	mov	bx, offset SectionArray
	mov	bx, es:[bx]
	mov	ax, es:[bx].CAH_count
	mov	data.UIUD_totalSections, ax

	mov	ax, ds:[di].WDI_currentSection
	mov	data.UIUD_currentSection, ax

	; copy data from the current section (both data and name)

	CheckHack <((offset UIUD_section) + (size UIUD_section)) eq (offset UIUD_sectionName)>

	call	SectionArrayEToP_ES		;es:di = SectionArrayElement
						;cx = size
	push	si, ds, es
	segmov	ds, es
	mov	si, di				;ds:si = source
	segmov	es, ss
	lea	di, data.UIUD_section
	rep	movsb
	clr	ax
SBCS <	stosb					;null terminate the name >
DBCS <	stosw					;null terminate the name >
	pop	si, ds, es

	pop	ax				;ax = flags
	mov	cx, ss
	lea	dx, data
	push	bp
	mov_tr	bp, ax
	mov	ax, MSG_WRITE_APPLICATION_SET_DOCUMENT_STATE
	call	GenCallApplication
	pop	bp

	;--------------------------------------------------
	; generate GW_APP_GCN_PAGE_INFO_CHANGE notification
	;--------------------------------------------------

	push	es
	mov	ax, size NotifyPageInfoChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	es, ax

	mov	ax, data.UIUD_pageSize.XYS_width
	mov	es:[NPIC_width], ax
	mov	ax, data.UIUD_pageSize.XYS_height
	mov	es:[NPIC_height], ax
	mov	ax, data.UIUD_section.SAE_rightMargin
	mov	es:[NPIC_rightMargin], ax
	mov	ax, data.UIUD_section.SAE_leftMargin
	mov	es:[NPIC_leftMargin], ax
	mov	ax, data.UIUD_section.SAE_topMargin
	mov	es:[NPIC_topMargin], ax
	mov	ax, data.UIUD_section.SAE_bottomMargin
	mov	es:[NPIC_bottomMargin], ax
	pop	es

	call	MemUnlock
	mov	ax, 1
	call	MemInitRefCount

	push	bp
	mov	bp, bx
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_PAGE_INFO_STATE_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bp

	mov	gcnParams.GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	gcnParams.GCNLMP_ID.GCNLT_type,
				GAGCNLT_APP_TARGET_NOTIFY_PAGE_INFO_STATE_CHANGE
	mov	gcnParams.GCNLMP_block, bx
	mov	gcnParams.GCNLMP_event, di
	mov	gcnParams.GCNLMP_flags, mask GCNLSF_SET_STATUS

	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST   ; Update GCN list
	mov	dx, size GCNListMessageParams		   ; create stack frame
	push	bp
	lea	bp, gcnParams
	call	GenSendToProcessStack
	pop	bp

done:
	.leave
	ret

SendNotification	endp

;---

GenSendToProcessStack	proc	near uses	bx, si, di
	.enter
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	clr	si
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	.leave
	ret
GenSendToProcessStack	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DoesTitlePageExist

DESCRIPTION:	Determine if a title page section exists

CALLED BY:	INTERNAL

PASS:
	es - map block

RETURN:
	carry - set if master page exists

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/26/92		Initial version

------------------------------------------------------------------------------@
DoesTitlePageExist	proc	far	uses ax, bx, cx, dx, si, di, ds, es
	.enter

	segmov	ds, es
	mov	si, offset SectionArray		;*ds:si = section array

	; if only one section then no title page

	call	ChunkArrayGetCount		;cx = count
	cmp	cx, 1
	clc
	jz	done

	mov	bx, handle TitlePageSectionName
	call	MemLock
	mov	es, ax
assume es:nothing
	mov	di, es:[TitlePageSectionName]	;es:di = name to search for
	clr	cx				;null terminated
	clrdw	dxax				;do not return data
	call	NameArrayFind
	call	MemUnlock
done:
	.leave
	ret

DoesTitlePageExist	endp

DocNotify ends
