COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		articleArticle.asm

ROUTINES:
	Name			Description
	----			-----------
    INT GetRegionPos		Get the position of a region

    INT AppendDeleteCommon	Add another region to an article

    INT ToAttrMgrCommon		Substitute a text attribute token

METHODS:
	Name			Description
	----			-----------
    StudioArticleReplaceParams  Filter replace operations to prevent
				page name chacters from being replaced.

				MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
				StudioArticleClass

    StudioArticleSetDisplayMode Handle change of display mode

				MSG_VIS_LARGE_TEXT_SET_DISPLAY_MODE
				StudioArticleClass

    StudioArticleCurrentRegionChanged  
				Generate additional notifications for the
				article

				MSG_VIS_LARGE_TEXT_CURRENT_REGION_CHANGED
				StudioArticleClass

    StudioArticleRegionIsLast	Handle notification that a region is the
				last region

				MSG_VIS_LARGE_TEXT_REGION_IS_LAST
				StudioArticleClass

    StudioArticleAppendRegion	Add another region to an article

				MSG_VIS_LARGE_TEXT_APPEND_REGION
				StudioArticleClass

    StudioArticleSubstAttrToken	Substitute a text attribute token

				MSG_VIS_TEXT_SUBST_ATTR_TOKEN
				StudioArticleClass

    StudioArticleRecalcForAttrChange  
				Recalculate for an attribute change

				MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE
				StudioArticleClass

    StudioArticleGetObjectForSearchSpell  
				Get the next object for search/spell

				MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
				StudioArticleClass

    StudioArticleSetVisParent	Set the vis parent for an article

				MSG_STUDIO_ARTICLE_SET_VIS_PARENT
				StudioArticleClass

    StudioArticleDisplayObjectForSearchSpell  
				Display the object

				MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL
				StudioArticleClass

    StudioArticleCrossSectionReplaceAborted  
				Notification that a cross section change
				has been aborted

				MSG_VIS_TEXT_CROSS_SECTION_REPLACE_ABORTED
				StudioArticleClass

    StudioArticleSetHyperlinkTextStyle
				Tell the document to remember the 
				new ShowAllHyperlinks setting.

				MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE
				StudioArticleClass

    StudioArticleDescribeAttrs	Check for indeterminate style and set
				global flag.

				MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS
				StudioArticleClass

    StudioArticleDefineStyle
				Check for indeterminate style and for the
				Boxed char attribute.

				MSG_META_STYLED_OBJECT_DEFINE_STYLE
 				MSG_META_STYLED_OBJECT_REDEFINE_STYLE
				StudioArticleClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for StudioArticleClass.

	$Id: articleArticle.asm,v 1.1 97/04/04 14:38:31 newdeal Exp $

------------------------------------------------------------------------------@

idata segment
	StudioArticleClass
	styleIndeterminate	BooleanByte	BB_FALSE
	; styleIndeterminate is BB_FALSE if the described style 
	;  is NOT indeterminate. styleIndeterminate MUST be initialized 
	;  to BB_FALSE.
idata ends

DocNotify segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleReplaceWithTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup pasted page name chars.

CALLED BY:	MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
		ss:bp - CommonTransferParams
RETURN:		bp - unchanged
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleReplaceWithTransferFormat 	method dynamic StudioArticleClass,
				MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT

		mov	di, bp			; ss:di <- CommonTransferParams
		uses	bp
params		local	EnumPageNameGraphicsLocals
		.enter
	;
	; Suspend the text, because if it tries to draw a page name
	; before the tokens have been updated, it could crash.
	;
		call	SuspendObject
	;
	; Make a note of the text object optr
	;
		mov	ax, ds:[LMBH_handle]
		movdw	ss:[params].EPNGL_textObj, axsi
		push	bp			; save locals
	;
	; Lock the transfer block header, get the HugeArray block 
	; containing the text, and get the number of chars being pasted.
	;
		push	di, es
		mov	bx, ss:[di].CTP_vmFile
		mov	ax, ss:[di].CTP_vmBlock
		call	VMLock
		mov	es, ax
		mov	di, es:[TTBH_text].high		;^vbx:di <- text
		call	VMUnlock
		call	HugeArrayGetCount
		pop	bp, es
	;
	; Go ahead and paste the text
	;
		pushdw	dxax
		mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock
	;
	; Now find out what the selection is, we will use the range end
	; as the end position of the fixup range.
	;
		sub	sp, size VisTextRange
		mov	bp, sp
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		call	ObjCallInstanceNoLock
		movdw	cxbx, ss:[bp].VTR_end
		add	sp, size VisTextRange
	;
	; Calculate the end range by adding the number of chars
	; that were pasted, less the NULL.
	; 
		popdw	dxax			;get the #chars being pasted
		tstdw	dxax
		pop	bp			; restore locals
		jz	noText
		decdw	dxax			;subtract the NULL
		pushdw	cxbx			;save the range end
		subdw	cxbx, dxax		;subtract #chars pasted
		movdw	dxax, cxbx		;dx.ax <- range start
		popdw	cxbx			;cx.bx <- range end
		push	dx, ax, cx, bx
	;
	; Make each page name graphic unique.
	;
		mov	di, offset FixupPageNameGraphic
		call	EnumPageNameGraphics
	;
	; If we've pasted text containing a context run but no graphic,
	; the hyperlink controller will confusingly show the associated
	; page name in black. We avoid this by clearing the context over
	; the whole pasted range, then going through the page name
	; graphics and setting the context appropriately.
	;
		mov	di, bx			; di <- range end
		mov	bx, ss:[params].EPNGL_textObj.handle
		call	MemDerefDS		; ds:si <- text object
		mov	bx, di			; bx <- range end
		mov	di, CA_NULL_ELEMENT
		call	SetContextCallSuperNoLock
		clrdw	ss:[params].EPNGL_count
		mov	di, offset SetStoredContextOnPageNameGraphic
		call	EnumPageNameGraphics
	;
	; Store the number of contexts set in vardata so as to tell
	; StudioArticleSetContext to just pass the context-setting
	; message to its superclass.
	;
		tstdw	ss:params.EPNGL_count
		jz	setHyperlinkStyle
		mov	cx, size dword
		mov	ax, ATTR_SA_SET_STORED_CONTEXT_COUNT
		call	ObjVarAddData			;ds:bx - ptr to count
		movdw	dxax, ss:params.EPNGL_count
		movdw	ds:[bx], dxax
setHyperlinkStyle:
	;
	; Update the pasted text to have the same hyperlink style
	; as is set in this Article.
	;       
		movdw	bxsi, ss:[params].EPNGL_textObj
		call	MemDerefDS
		pop	dx, ax, cx, bx			; restore range
		call	SetHyperlinkStyleOnPastedText
noText:
		call	UnsuspendObject
		.leave
		ret

StudioArticleReplaceWithTransferFormat		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetStoredContextOnPageNameGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the context on a PNG using the token stored in it.

CALLED BY:	INTERNAL	StudioArticleReplaceWithTransferFormat
					(via EnumPageNameGraphic)
PASS:		ds:si	= graphic TextRunArrayElement
		es	= segment of graphic element array
		ss:bp	= optr of text object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, si, ds
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetStoredContextOnPageNameGraphic	proc	near
		.enter inherit StudioArticleReplaceWithTransferFormat
	;
	; First get the token for the context which should be set on
	; this graphic.
	;
		pushdw	dssi
		mov	ax, ds:[si].TRAE_token
		segmov	ds, es
		mov	si, VM_ELEMENT_ARRAY_CHUNK
		call	ChunkArrayElementToPtr	; ds:di <- graphic
		mov	di, 
		    {word} ds:[di].VTG_data.VTGD_variable.VTGV_privateData[2]
		popdw	dssi
	;
	; Now get the graphic's position and set the context. Do this
	; on the queue since the article is currently suspended, so the
	; text hasn't been recalculated since the paste.
	;
		clr	dh
		mov	dl, ds:[si].TRAE_position.WAAH_high
		mov	ax, ds:[si].TRAE_position.WAAH_low

		movdw	bxsi, ss:[params].EPNGL_textObj
		call	MemDerefDS		; ds:si <- text object

		movdw	cxbx, dxax
		incdw	cxbx
		call	SetContextQueue

		incdw	ss:[params].EPNGL_count
	;
	; Keep enumerating.
	;
		clc
		.leave
		ret
SetStoredContextOnPageNameGraphic	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupPageNameGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup stored page name token in pasted page name graphics

CALLED BY:	StudioArticleReplaceWithTransferFormat, via
			EnumPageNameGraphics
PASS:		ds:si - graphic TextRunArrayElement
		ss:bp	= inherited EnumPageNameGraphicLocals
		bx - stored name token
		es - segment of graphic element array 
RETURN:		
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/94	Initial version
	jenny	12/ 9/94	Store a unique ID in the privateData

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTypeParams	struct
    GTP_params	VisTextGetAttrParams
    GTP_attrs	VisTextType
    GTP_diffs	VisTextTypeDiffs
GetTypeParams	ends

FixupPageNameGraphic		proc	near
		uses	ds, bp
		.enter inherit StudioArticleReplaceWithTransferFormat
	;
	; Get the position of this graphic
	;
		clr	dh
		mov	dl, ds:[si].TRAE_position.WAAH_high
		mov	ax, ds:[si].TRAE_position.WAAH_low
		push	ds:[si].TRAE_token	;save graphic token

		movdw	bxsi, ss:[params].EPNGL_textObj
		push	bp			; save ptr into stack
	;
	; Get the type run on this graphic character
	;
		sub	sp, size GetTypeParams
		mov	bp, sp
		movdw	ss:[bp].VTGAP_range.VTR_start, dxax
		incdw	dxax
		movdw	ss:[bp].VTGAP_range.VTR_end, dxax
		mov	ax, ss
		lea	dx, ss:[bp].GTP_attrs
		movdw	ss:[bp].VTGAP_attr, axdx
		lea	dx, ss:[bp].GTP_diffs
		movdw	ss:[bp].VTGAP_return, axdx
		clr	ss:[bp].VTGAP_flags
		mov	ax, MSG_VIS_TEXT_GET_TYPE
		mov	di, mask MF_CALL 
		call	ObjMessage
	;
	; Get the context token that is set on this character, and
	; check if it is different from that which is stored in the 
	; graphic's variable data (it was passed in bx)
	;
EC <		test	ss:[bp].GTP_diffs, mask VTTD_MULTIPLE_CONTEXTS >
EC <		ERROR_NZ -1 					>
		mov	bx, ss:[bp].GTP_attrs.VTT_context
EC <		cmp	bx, CA_NULL_ELEMENT			>
EC <		ERROR_E -1					>
		add	sp, size GetTypeParams

		pop	bp			;ss:bp <- text optr
		pop	ax			;restore graphic token
	;
	; The name token has changed.  Update the value stored in 
	; the page name graphic variable data.
	;
		segmov	ds, es, si
		mov	si, VM_ELEMENT_ARRAY_CHUNK
		call	ChunkArrayElementToPtr	; ds:di - graphic

EC <		cmp	ds:[di].VTG_type, VTGT_VARIABLE  	>
EC <		ERROR_NE -1					>
EC <		cmp	ds:[di].VTG_data.VTGD_variable.VTGV_type, VTVT_CONTEXT_NAME >
EC <		ERROR_NE -1					>

	;
	; Store the name token in the graphic's privateData.
	;
		mov	{word} \
		    ds:[di].VTG_data.VTGD_variable.VTGV_privateData[2], bx
	;
	; Now get the fileID and unique page name graphic ID and store
	; them in the privateData too.
	;
		push	ds
		movdw	bxsi, ss:[params].EPNGL_textObj
		call	MemDerefDS
		call	GetWholePageNameGraphicID	; dx:ax <- FileID
							; cx <- ID unique
							;  within file
		pop	ds
		mov	{word} \
		    ds:[di].VTG_data.VTGD_variable.VTGV_privateData[4], dx
		mov	{word} \
		    ds:[di].VTG_data.VTGD_variable.VTGV_privateData[6], ax
		mov	{word} \
		    ds:[di].VTG_data.VTGD_variable.VTGV_privateData[8], cx

		call	VMDirtyDS

		clc
	
		.leave
		ret
FixupPageNameGraphic		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHyperlinkStyleOnPastedText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the Boxed char attr and set the hyperlink style
		on the passed range of text.

CALLED BY:	(INTERNAL) StudioArticleReplaceWithTransferFormat
PASS:		*ds:si - article
		dx:ax - start pos
		cx:bx - end pos
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetHyperlinkStyleOnPastedText	proc	near
		uses	bp
		.enter
	;
	; Set up VisTextRange with the passed positions.
	;
		pushdw	cxbx
		pushdw	dxax
		mov	bp, sp				;ss:bp <- VisTextRange
	;
	; Don't want article to draw itself until after the
	; style change has completed.
	;
	; Can't do this without causing a crash when QuickCopy between two
	; files.  When suspend count reaches 0 (which is in UPATE_HYPERLINK
	; handler if object is suspended here and unsuspended there), 
	; undo chain is ended and undo chain start count would go to 0.
	; The problem is that UPDATE_HYPERLINK is received after the
	; document loses the model exclusive, and at that point it calls
	; MSG_GEN_PROCESS_UNDO_SET_CONTEXT, which expects the start count
	; to be zero.  -- cassie 12/12/94
	; 
;;		call	SuspendObject
	;
	; Queue this message, as it must be handled after
	; MSG_HSTEXT_UPDATE_HOT_SPOT_ARRAY which gets sent during
	; the text replace.  Updating the hyperlink style causes
	; MSG_VIS_TEXT_ATTRIBUTE_CHANGE to be sent, which the HotSpot
	; library intercepts as a sign that it might need to move some
	; hotspots, eg. if justification changed.  If hotspots are moved
	; before the hotspot array has been updated, it will be out of synch.
	;
		mov	ax, MSG_STUDIO_ARTICLE_UPDATE_HYPERLINK_STYLE_FOR_PASTE
		mov	dx, size VisTextRange
		call	SA_ObjMessageQueueStackDS
		add	sp, size VisTextRange
		.leave
		ret
SetHyperlinkStyleOnPastedText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleUpdateHyperlinkStyleForPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some text has been pasted.  Need to update the hyperlink
		style on the updated text to agree with the state of the
		Show All Hyperlinks button.

CALLED BY:	MSG_STUDIO_ARTICLE_UPDATE_HYPERLINK_STYLE_FOR_PASTE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
		ss:bp - VisTextRange 
		article is suspended
RETURN:		nothing, but unsuspend the article
DESTROYED:	ax, cx, dx, bp 
		bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	unsuspends the article
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/11/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleUpdateHyperlinkStyleForPaste  method dynamic StudioArticleClass,
			MSG_STUDIO_ARTICLE_UPDATE_HYPERLINK_STYLE_FOR_PASTE
	
	;
	; Since object can't be suspended by SetHyperlinkStyleOnPastedText,
	; we do it here. Unfortunately, this means that the text is
	; visible after it is pasted but before the hyperlink style is set.
	;
		call	SuspendObject
		mov	di, bp
	;
	; Start setting up the VisTextSetTextStyleParams
	;
		sub	sp, (size VisTextSetTextStyleParams)
		mov	bp, sp		; ss:bp <- params

		movdw	ss:[bp].VTSTSP_range.VTR_start, ss:[di].VTR_start, ax
		movdw	ss:[bp].VTSTSP_range.VTR_end, ss:[di].VTR_end, ax
	;
	; We don't want any undo chains for the style changes below.
	; This is because things will get out of synch if the user undo'es
	; and redo'es the paste/move/copy.
	;
		push	bp
		clr	cx				; cx <- clear nothing
		mov	dx, mask VTF_ALLOW_UNDO		; dx <- clear undo
		mov	ax, MSG_VIS_TEXT_SET_FEATURES
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; The text could have the Boxed char attr used on non hyperlinks
	; if we are paste/move/copy'ing from a different app so we need 
	; to remove the Boxed char attr from the paste/move/copy'ed text.
	;
		clr	ax
		mov	ss:[bp].VTSTSP_styleBitsToSet, ax
		mov	ss:[bp].VTSTSP_styleBitsToClear, ax
		mov	ss:[bp].VTSTSP_extendedBitsToSet, ax
		mov	ss:[bp].VTSTSP_extendedBitsToClear, mask VTES_BOXED

		mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
		call	ObjCallInstanceNoLock
	;
	; The status of ShowAllHyperlinks can be different between the
	; source and destination documents, so we need to check the status
	; and set the hyperlink style.
	;
		mov	ax, MSG_STUDIO_DOCUMENT_GET_MISC_FLAGS
		call	VisCallParent		; dx <- MiscStudioDocumentFlags
		
	; Set the hyperlink style.
	; We can use the params set up above except we may need to change
	; the extendedBitsTo[Set/Clear]
	;
	; We send the MSG_TEXT_SET_HYPERLINK_TEXT_STYLE to our superclass
	; because we don't want to intercept it ourself.
	;
		test	dx, mask MSDF_SHOW_HYPERLINKS
		jz	dontShowHyperlinks
		mov	ss:[bp].VTSTSP_extendedBitsToSet, mask VTES_BOXED
		clr	ss:[bp].VTSTSP_extendedBitsToClear
dontShowHyperlinks:
		mov	ax, MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE
		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock

		add	sp, (size VisTextSetTextStyleParams)
	;
	; Resume allowing undo.
	;
		mov	cx, mask VTF_ALLOW_UNDO		; dx <- set undo
		clr	dx				; cx <- clear nothing
		mov	ax, MSG_VIS_TEXT_SET_FEATURES
		call	ObjCallInstanceNoLock
	;
	; Unsuspend the article, so it will draw itself.
	;
		call	UnsuspendObject

		ret
StudioArticleUpdateHyperlinkStyleForPaste		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleFilterViaReplaceParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent single page name chars from being replaced.

CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
		ss:bp pp- VisTextReplaceParameters
RETURN:		carry clear to accept replacement,
		carry set to deny it
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 8/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleFilterViaReplaceParams	method dynamic StudioArticleClass,
					MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
	;
	; Check for a one character replace range.
	;
		movdw	dxax, ss:[bp].VTRP_range.VTR_end
		subdw	dxax, ss:[bp].VTRP_range.VTR_start
		tst	dx
		LONG	jnz	accept
		cmp	ax, 1
		LONG	jne	accept
	;
	; Check for a page name graphic at this position
	;
		movdw	dxax, ss:[bp].VTRP_range.VTR_start
		movdw	cxbx, ss:[bp].VTRP_range.VTR_end
		mov	di, offset IsPageNameGraphicHere
		call	EnumPageNameGraphics		;carry set if pnc found
		LONG	jnc	accept
	;
	; Check for a simple delete, as opposed to a replace.  We don't
	; deal with replaces here, so just fail the replace.
	;
		tstdw	ss:[bp].VTRP_insCount
		LONG	jnz	fail

EC <modifyReplace::							>
	;
	; We know that a single page name character is about to be
	; deleted.  If it is being deleted because the user has chosen
	; to clear some or all page names, we don't want to filter or
	; modify the replace.  The number of deletions to ignore is stored
	; in vardata.
	;
		mov	ax, ATTR_SA_CLEAR_PAGE_NAME_CHAR_COUNT
		call	ObjVarFindData			;ds:bx - ptr to count
		jnc	notClearingPageName
		subdw	ds:[bx], 1
		tstdw	ds:[bx]				;more to ignore?
		LONG	jnz	accept
		call	ObjVarDeleteData		;this is last, so
		LONG	jmp	accept			;  delete vardata

notClearingPageName:
	;
	; Check whether there is a selection.  If so, don't allow the 
	; replace.
	;
		mov	di, ds:[si]
		add	di, ds:[di].StudioArticle_offset
		movdw	dxax, ds:[di].VTI_selectStart
		cmpdw	dxax, ds:[di].VTI_selectEnd
		je	isSelection
	;
	; Beep if the user is trying to cut a page name char
	;
		mov	ax, SST_ERROR
		call	UserStandardSound
		LONG 	jmp fail
isSelection:
	;	
	; Save the current message's range start.  We will modify it
	; below, before sending out a new replace message.
	;
		pushdw	ss:[bp].VTRP_range.VTR_start
	;
	; If the current cursor position is after the replace range start
	; position, we must be in the process of backspacing over the char.
	; If the cursor position is at or before the replace range start,
	; the char is being deleted.  Adjust the replace range so that 
	; we delete the next or backspace over the previous char.
	;
		cmpdw	dxax, ss:[bp].VTRP_range.VTR_start
		mov	ax, -1			;subtract 1 to backspace prev
		ja	adjustRange
		mov	ax, 1			;add 1 to delete the next
adjustRange:
	;
	; Add the adjustment, and check for falling off the end of the text
	;
		cwd
		adddw	ss:[bp].VTRP_range.VTR_start, dxax
		cmpdw	ss:[bp].VTRP_range.VTR_start, -1	;start is < 0?
		je	failReset

		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		cmpdw	ss:[bp].VTRP_range.VTR_start, dxax	;start == end?
		je	failReset
	;
	; Force queue a message to move the cursor to the new position
	; so that after the subsequent replace, the cursor is in the
	; position, visually.
	;
		movdw	dxax, ss:[bp].VTRP_range.VTR_start
		movdw	ss:[bp].VTRP_range.VTR_end, dxax
		push	bp
		mov	dx, size VisTextRange
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE
		call	SA_ObjMessageQueueStackDS
		pop	bp
	;
	; Force queue a replace message with the new params.
	;
		incdw	ss:[bp].VTRP_range.VTR_end
		mov	dx, size VisTextReplaceParameters
		mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
		call	SA_ObjMessageQueueStack
failReset:
	;
	; Restore the original params range.
	;
		popdw	dxax
		movdw	ss:[bp].VTRP_range.VTR_start, dxax
		incdw	dxax
		movdw	ss:[bp].VTRP_range.VTR_end, dxax
fail:
		stc
		ret

accept:
	;
	; Let our superclass handle this.
	;
		mov	ax, MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
		mov	di, offset StudioArticleClass
		GOTO	ObjCallSuperNoLock

StudioArticleFilterViaReplaceParams		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear context on page break after it's inserted.

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= StudioArticleClass object
		ax	= message #

		cx	= character
		dh	= ShiftState

RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleKbdChar	method dynamic StudioArticleClass, 
					MSG_META_KBD_CHAR
	;
	; First have the superclass go ahead so the text gets modified.
	;
		push	cx, dx
		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock
		pop	cx, dx
	;
	; Now see if the character was a page break.
	;
SBCS <		cmp	cx, (VC_ISCTRL shl 8) or VC_ENTER		>
DBCS <		cmp	cx, C_SYS_ENTER					>
		jne	done
		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jz	done
		test	dh, not (mask SS_LCTRL or mask SS_RCTRL)
		jnz	done
	;
	; It was a page break. Find its position in the text.
	;
		sub	sp, size VisTextSetContextParams
		mov	bp, sp			; ss:bp <- VTSCXP_range
		mov	dx, ss			; dx:bp <- ditto
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		call	ObjCallInstanceNoLock
	;
	; Note that VTSCXP_range.VTR_start = VTSCXP_range.VTR_end
	; since we just entered a character. Tweak range.
	;
		call	GetWholeArticleRange	; cx:bx <- end of article
		cmpdw	ss:[bp].VTSCXP_range.VTR_end, cxbx
		je	decStart
		incdw	ss:[bp].VTSCXP_range.VTR_end
clearContext:
	;
	; Clear the context on the page break so as to prevent any
	; context currently set on it from expanding across the page
	; boundary.
	;
		mov	ss:[bp].VTSCXP_flags, mask VTCF_TOKEN
		mov	ss:[bp].VTSCXP_context, CA_NULL_ELEMENT
		call	SetContextCallSuperNoLockLow
		add	sp, size VisTextSetContextParams
done:
		ret

decStart:
		decdw	ss:[bp].VTSCXP_range.VTR_start
		jmp	clearContext

StudioArticleKbdChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleRecalcHotspots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A page has been added or deleted.  Recalc the position
		of hotspots on adjacent pages.

CALLED BY:	MSG_STUDIO_ARTICLE_RECALC_HOTSPOTS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
		cx - first page to recalc
		dx - last page to recalc
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleRecalcHotspots		method dynamic StudioArticleClass,
					MSG_STUDIO_ARTICLE_RECALC_HOTSPOTS

		sub	sp, size VisTextRange
		mov	bp, sp

		push	dx				;save end page number
		call	GetPageRangeFromPageNumber	;dx:ax = start offset
		movdw	ss:[bp].VTR_start, dxax
		pop	cx
		call	GetPageRangeFromPageNumber	;cx:bx = end offset
		movdw	ss:[bp].VTR_end, cxbx

		mov	ax, MSG_HSTEXT_RECALC_HOT_SPOTS
		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock
		add	sp, size VisTextRange
		
		ret
StudioArticleRecalcHotspots		endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleCurrentRegionChanged --
		MSG_VIS_LARGE_TEXT_CURRENT_REGION_CHANGED for StudioArticleClass

DESCRIPTION:	Generate additional notifications for the article

PASS:
	*ds:si - instance data
	es - segment of StudioArticleClass

	ax - The message

	cx - region number

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
StudioArticleCurrentRegionChanged	method dynamic	StudioArticleClass,
				MSG_VIS_LARGE_TEXT_CURRENT_REGION_CHANGED

	mov	dx, cx
	mov	ax, MSG_STUDIO_ARTICLE_PAGE_CHANGED
	call	ObjCallInstanceNoLock
		
	call	GetRegionPos

	mov	ax, MSG_STUDIO_DOCUMENT_SET_POSITION_ABS
	call	VisCallParent

	ret

StudioArticleCurrentRegionChanged	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetRegionPos

DESCRIPTION:	Get the position of a region

CALLED BY:	INTERNAL

PASS:
	*ds:si - StudioArticle
	cx - region number

RETURN:
	cx - x position
	dxbp - y position

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/16/92		Initial version

------------------------------------------------------------------------------@
GetRegionPos	proc	far	uses si, di
	.enter

	mov_tr	ax, cx
	mov	si, offset ArticleRegionArray
	call	ChunkArrayElementToPtr
	mov	cx, ds:[di].VLTRAE_spatialPosition.PD_x.low
	movdw	dxbp, ds:[di].VLTRAE_spatialPosition.PD_y

	.leave
	ret
GetRegionPos	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for and handle deleting graphic variables of type
		VTVT_CONTEXT_NAME

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
		cx - ManufacturerID
		dx - notification type
		bp - notification specific data
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/19/94		Initial version
	jenny	9/11/94		Fixed page name change notification
	jenny	11/09/94	Now deals with insertions.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleNotifyWithDataBlock	method dynamic StudioArticleClass,
					MSG_META_NOTIFY_WITH_DATA_BLOCK
	;
	; We're interested only in variable graphic insertions/deletions.
	;
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		LONG	jne	callSuper
		cmp	dx, GWNT_DELETE_VARIABLE_GRAPHIC
		LONG	jne	callSuper
	;
	; Lock the data block.
	;
		push	ax, cx, dx, bp, es
		mov	bx, bp
		call	MemLock
		mov	es, ax		; es:0 <- NotifyDeleteVariableGraphic
	;
	; If the variable graphic wasn't associated with a context
	; name, never mind.
	;
		cmp	es:[NDVG_type], VTVT_CONTEXT_NAME
		jne	unlockBlock
	;
	; Handle insertion or deletion.
	;
		movdw	dxax, es:[NDVG_position]
		cmp	es:[NDVG_action], VGAT_INSERT
		je	handleInsertion
EC <		cmp	es:[NDVG_action], VGAT_DELETE			>
EC <		ERROR_NE INVALID_VARIABLE_GRAPHIC_ACTION_TYPE		>
		call	HandleVariableGraphicDeletion

unlockBlock:
		pop	ax, cx, dx, bp, es
		mov	bx, bp
		call	MemUnlock
		call	MemDecRefCount
callSuper:
		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock
		ret

handleInsertion:
		call	HandleVariableGraphicInsertion
		jmp	unlockBlock

StudioArticleNotifyWithDataBlock		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleVariableGraphicDeletion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after the deletion of a page name graphic

CALLED BY:	INTERNAL	StudioArticleNotifyWithDataBlock
PASS:		*ds:si	= article
		dx:ax	= position of variable graphic
RETURN:		nothing
DESTROYED:	bp
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 9/94    	Broke out of StudioArticleNotifyWithDataBlock

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleVariableGraphicDeletion	proc	near
		class	VisTextClass
graphicPos	local	dword	push	dx, ax
pageStart	local	dword	
pageEnd		local	dword	
		.enter
	;
	; If we've kept a count of variable graphic deletions that
	; we've already handled and can here ignore, decrement it.
	;
		mov_tr	cx, ax			; dx:cx <- graphic position
		mov	ax, ATTR_SA_IGNORE_DELETE_VARIABLE_GRAPHICS
		call	ObjVarFindData			;ds:bx - ptr to count
		jnc	noIgnore	
		subdw	ds:[bx], 1
		tstdw	ds:[bx]
		LONG	jnz	ignore			;more to ignore?
		call	ObjVarDeleteData		;this is last, so
		jmp	ignore				; delete vardata

noIgnore:		
	;
	; get the run bounds for the page name char's context type run
	;
		movdw	dxax, ss:graphicPos
		call	GetTypeRunBounds	; dx:ax <- run start
						; cx:bx <- run end
	;
	; now clear the context on that run - call super because we don't
	; want StudioArticle to get the message and try to delete the
	; page name character again - it is in the process of being deleted
	; by some user action.
	;
		mov	di, CA_NULL_ELEMENT
		call	SetContextCallSuperNoLock
	;
	; First see if there is a page name character before the one
	; being deleted.
	;
		movdw	dxax, ss:graphicPos
		call	GetPageRangeAndNumber	; di <- page number
		movdw	ss:pageStart, dxax	; start at page start
		movdw	ss:pageEnd, cxbx	; save page end
		movdw	cxbx, ss:graphicPos	; stop at this page name char
		call	GetPageName		; ax <- token
		cmp	ax, CA_NULL_ELEMENT	; any page name char there?
		jne	notify			; yes, send the notification
	;
	; Then check for a page name char after the one being deleted.
	;
		movdw	dxax, ss:graphicPos	
		incdw	dxax			; start after page name char
		movdw	cxbx, ss:pageEnd	; stop at page end
		call	GetPageName		; ax <- token
notify:
	;
	; Notify the world that the page name has changed.
	;
		call	NameTokenToListIndex	; ax <- index
		mov	dl, PNCT_DELETE_VARIABLE_GRAPHIC
		call	GenerateAndSendPageNameNotification
ignore:
		.leave
		ret
HandleVariableGraphicDeletion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleVariableGraphicInsertion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the world that the current page has a new name.

CALLED BY:	INTERNAL	StudioArticleNotifyWithDataBlock
PASS:		*ds:si	= article
		dx:ax	= position of variable graphic
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleVariableGraphicInsertion	proc	near
params		local	EnumPageNameGraphicsLocals
warnString	local	word
pageName	local	word
		.enter
	;
	; Get the page range, needed to get the name and count the graphics.
	;
		pushdw	dxax
		call	GetPageRangeAndNumber	; dx:ax <- start offset
						; cx:bx <- end offset
	;
	; Get the name of the page to use for the notification.
	;
		push	ax
		call	GetPageName
		mov	ss:[pageName], ax
		pop	ax
	;
	; If there's more than one page name graphic on this page, then
	; we'll be putting up a warning later.
	;
		clr	ss:[warnString]
		clrdw	ss:[params].EPNGL_count
		mov	di, offset CountPageNameGraphicsCallback
		call	EnumPageNameGraphics
		cmpdw	ss:[params].EPNGL_count, 1
		je	getName
EC <		ERROR_B	PAGE_NAME_GRAPHIC_MYSTERIOUSLY_MISSING		>
		mov	ss:[warnString], offset TooManyNamesOnPageWarningString
getName:
	;
	; Get graphic's range and name token so as to set the context on it.
	; The context may be set already (e.g. if pasting), but it may
	; not (e.g. if undoing a delete).
	;
		popdw	dxax		; dx:ax <- start position of graphic
		push	ax
		movdw	cxbx, dxax
		incdw	cxbx
		call	GetPageName
		mov_tr	di, ax		; di <- token
		pop	ax
		call	SetContextCallSuperNoLock
	;
	; Do we have more than one page with this graphic's name?
	;
		mov	ss:[params].EPNGL_name, di
		call	GetWholeArticleRange
		clrdw	ss:[params].EPNGL_count
		mov	di, offset MatchPageNameTwiceCallback
		call	EnumPageNameGraphics	; carry <- set if two
						;  matches found
	;
	; Select an appropriate warning string if so.
	;
		mov	ax, ss:[params].EPNGL_name
		mov	di, ss:[warnString]
		jnc	warnIfNecessary
		tst	di
		mov	cx, offset PageNameAlreadyUsedWarningString
		jz	gotString
		mov	cx, offset TooManyOnPageAndAlreadyUsedWarningString
gotString:
		mov	di, cx
warnIfNecessary:
	;
	; Warn the user if something's up with the page names.
	;
		tst	di			; any warning string?
		jz	sendNotification
		mov	cx, (CDT_WARNING shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		call	DoPageNameAlreadyUsedDialog
sendNotification:
	;
	; Send a page name change notification, after first sending
	; one to "clear" the status event in case this insertion is
	; the result of a quick copy between to documents.  This is
	; done to ensure that the status bar gets updated.  (If the
	; page name in the originating document is the same as the page
	; name char being pasted, the notification sent below would be
	; the same as the last one sent from the originating document,
	; and the page name controller would never receive it, leaving
	; the status bar blank because it was cleared out by the
	; document change notification.)
	;
		mov	ax, CA_NULL_ELEMENT
		call	PageChangedLow

		mov	ax, ss:[pageName]	; ax <- name of page
						;  (might not be name of
						;  inserted graphic)
		call	PageChangedLow

		.leave
		ret

HandleVariableGraphicInsertion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatchPageNameTwiceCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for two page name tokens matching token passed on stack

CALLED BY:	HandleVariableGraphicInsertion (via EnumPageNameGraphics)

PASS:		ss:bp	= inherited EnumPageNameGraphicsLocals
				EPNGL_name = page name token to match
				EPNGL_count = # matching tokens
		bx	= page name token

RETURN:		carry set if two matches found (stops enumeration)

DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/23/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MatchPageNameTwiceCallback		proc	near
		.enter inherit HandleVariableGraphicInsertion

		cmp	ss:params.EPNGL_name, bx
		clc
		jne	done
		incdw	ss:params.EPNGL_count
		cmpdw	ss:params.EPNGL_count, 2
		clc
		jne	done
		stc			; stop hunting
done:
		.leave
		ret
MatchPageNameTwiceCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CountPageNameGraphicsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add one to the count of page name graphics.

CALLED BY:	HandleVariableGraphicInsertion (via EnumPageNameGraphics)

PASS:		ss:bp	= inherited EnumPageNameGraphicsLocals
				EPNGL_count = number counted so far
		bx	= page name token

RETURN:		carry clear

DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/23/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CountPageNameGraphicsCallback	proc	near
		.enter inherit HandleVariableGraphicInsertion

		incdw	ss:params.EPNGL_count
		clc

		.leave
		ret

CountPageNameGraphicsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetContextCallSuperNoLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the stack frame and set the context.

CALLED BY:	INTERNAL	HandleVariableGraphicDeletion
				HandleVariableGraphicInsertion
PASS:		*ds:si	= article
		di	= context token
		dx:ax	= start of range
		cx:bx	= end of range
RETURN:		nothing
DESTROYED:	es
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetContextCallSuperNoLock	proc	near
		uses	ax, bx, cx, dx, bp, di
		.enter

		sub	sp, size VisTextSetContextParams
		mov	bp, sp				;ss:bp <- VTSCXP
		movdw	ss:[bp].VTSCXP_range.VTR_start, dxax
		movdw	ss:[bp].VTSCXP_range.VTR_end, cxbx
		mov	ss:[bp].VTSCXP_flags, mask VTCF_TOKEN
		mov	ss:[bp].VTSCXP_context, di 
		GetResourceSegmentNS	StudioArticleClass, es
		call	SetContextCallSuperNoLockLow
		add	sp, size VisTextSetContextParams

		.leave
		ret
SetContextCallSuperNoLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetContextCallSuperNoLockLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the text object's superclass to set a context.

CALLED BY:	INTERNAL	StudioArticleClearContextLow
				StudioArticleSetContext
				StudioArticleNotifyWithDataBlock

PASS:		*ds:si	= text object
		es	= segment of text object
		ss:bp	= VisTextSetContextParams
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/12/94    	Broke out of a couple places

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetContextCallSuperNoLockLow	proc	near

		mov	ax, MSG_VIS_TEXT_SET_CONTEXT
		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock
		ret
SetContextCallSuperNoLockLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetContextQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the context via the queue

CALLED BY:	INTERNAL	SetStoredContextOnPageNameGraphic
PASS:		*ds:si	= article
		di	= context token
		dx:ax	= start of range
		cx:bx	= end of range
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetContextQueue	proc	near
		uses	bp
		.enter

		sub	sp, size VisTextSetContextParams
		mov	bp, sp				;ss:bp <- VTSCXP
		movdw	ss:[bp].VTSCXP_range.VTR_start, dxax
		movdw	ss:[bp].VTSCXP_range.VTR_end, cxbx
		mov	ss:[bp].VTSCXP_flags, mask VTCF_TOKEN
		mov	ss:[bp].VTSCXP_context, di 
		mov	ax, MSG_VIS_TEXT_SET_CONTEXT
		mov	dx, size VisTextSetContextParams
		call	SA_ObjMessageQueueStackDS
		add	sp, dx

		.leave
		ret
SetContextQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTypeRunBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the bounds for the type run to which the passed
		position belongs

CALLED BY:	INTERNAL	HandleVariableGraphicDeletion

PASS:		*ds:si	= article
		dx:ax	= position	

RETURN:		dx:ax	= type run start
		cx:bx	= type run end

DESTROYED:	di
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/23/94    	Broke out of HandleVariableGraphicDeletion

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTypeRunBounds	proc	near
	;
	; Get bounds onto stack and return them in registers.
	;
		sub	sp, size VisTextRange
		mov	di, sp
		call	GetTypeRunBoundsLow
		movdw	dxax, ss:[di].VTR_start
		movdw	cxbx, ss:[di].VTR_end
		add	sp, size VisTextRange

		ret
GetTypeRunBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTypeRunBoundsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the bounds for the run to which the passed
		position belongs

CALLED BY:	INTERNAL	GetTypeRunBounds
				FigureRangeAndSetContextThere

PASS:		*ds:si	= article
		ss:di	= VisTextRange to fill with bounds
		dx:ax	= position	
RETURN:		ss:di	= VisTextRange filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/10/94    	Broke out of HandleVariableGraphicDeletion

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTypeRunBoundsLow	proc	near
		uses	bp
		.enter
	;
	; Get the type run bounds for the passed position.
	;
		sub	sp, size VisTextGetRunBoundsParams 
		mov	bp, sp
		movdw	ss:[bp].VTGRBP_position, dxax
		mov	dx, ss
		mov	ss:[bp].VTGRBP_retVal.high, dx
		mov	ss:[bp].VTGRBP_retVal.low, di
		mov	ss:[bp].VTGRBP_type, OFFSET_FOR_TYPE_RUNS
		mov	ax, MSG_VIS_TEXT_GET_RUN_BOUNDS
		call	ObjCallInstanceNoLock
		add	sp, size VisTextGetRunBoundsParams 
		.leave
		ret
GetTypeRunBoundsLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticlePageChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The visible page has changed.  Send a page name notification.

CALLED BY:	MSG_STUDIO_ARTICLE_PAGE_CHANGED
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
		dx - page number 
RETURN:		nothing
DESTROYED:	bx si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/15/94		Initial version
	jenny	11/ 9/94	Broke out PageChanged

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticlePageChanged	method dynamic StudioArticleClass,
				MSG_STUDIO_ARTICLE_PAGE_CHANGED

		uses	cx, dx, bp
		.enter

		mov	cx, dx
		call	GetPageRangeFromPageNumber	;dx:ax = start offset
							;cx:bx = end offset
		call	PageChanged

		.leave
		ret
StudioArticlePageChanged		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current page has changed. Tell the world.

CALLED BY:	INTERNAL	StudioArticlePageChanged

PASS:		*ds:si	= article
		dx:ax	= start of page
		cx:bx	= end of page
RETURN:		nothing
DESTROYED:	ax, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 9/94    	Broke out of StudioArticlePageChanged 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PageChanged	proc	near

		call	GetPageName			; ax <- page name

	; convert the token to a list index and send a notification
		
		FALL_THRU	PageChangedLow

PageChanged	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageChangedLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out notification of page change.

CALLED BY:	INTERNAL	PageChanged
				HandleVariableGraphicInsertion
PASS:		*ds:si	= article
		ax	= page name (context token)
RETURN:		nothing
DESTROYED:	ax, bx, cx, es, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/21/94    	Broke out of PageChanged

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PageChangedLow	proc	near

		call	NameTokenToListIndex		;ax = name index
		mov	dl, PNCT_CHANGE_PAGE
		call	GenerateAndSendPageNameNotification

		ret
PageChangedLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleGetPageName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the passed position, find the page name token

CALLED BY:	MSG_STUDIO_ARTICLE_GET_PAGE_NAME
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
		ss:bp - VisTextRange
RETURN:		ax - name token, or CA_NULL_ELEMENT if none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/30/94		Initial version
	jenny	11/ 9/94	Broke out GetPageName

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleGetPageName		method StudioArticleClass,
					MSG_STUDIO_ARTICLE_GET_PAGE_NAME

		mov	di, bp			; ss:di <- VisTextRange
		call	GetPageRangeFromVisTextRangeStart
		call	GetPageName

		ret
StudioArticleGetPageName		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the page name token for the passed range.

CALLED BY:	INTERNAL	StudioArticleGetPageName
				PageChanged
				HandleVariableGraphicInsertion

PASS:		*ds:si	= article
		dx:ax	= start of page
		cx:bx	= end of page

RETURN:		ax	= page name token
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 9/94    	Broke out of StudioArticleGetPageName

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPageName	proc	near
		uses	di
params 	local	EnumPageNameGraphicsLocals
		.enter

		mov	ss:params.EPNGL_name, CA_NULL_ELEMENT
	;
	; Find the first page name character on the page which
	; contains the passed start offset
	;
		mov	di, offset GetPageNameCallback
		call	EnumPageNameGraphics
		mov	ax, ss:params.EPNGL_name

		.leave
		ret
GetPageName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageNameCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name token for the page

CALLED BY:	GetPageName (via EnumPageNameGraphics)
PASS:		ds:si - TextRunArrayElement
		ss:bp - inherited locals
		bx - page name token
RETURN:		carry set to stop enumerating
		bx saved in local variable "token"
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPageNameCallback		proc	near
		.enter inherit GetPageName

		mov	ss:params.EPNGL_name, bx
		stc
		.leave
		ret
GetPageNameCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateAndSendPageNameNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a page name notification and tell the
		document to send it.

CALLED BY:	INTERNAL	StudioArticlePageChanged
				StudioArticleSetContext
				StudioArticleNotifyWithDataBlock

PASS:		*ds:si	= text object
		ax	= index of page name
		dl	= PageNameChangeType

RETURN:		nothing
DESTROYED:	ax, bx, cx, es, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/12/94    	Broke out of a couple places

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateAndSendPageNameNotification	proc	near

		call	GeneratePageNameNotification	;bx = notification block
		mov	cx, bx
		mov	ax, MSG_STUDIO_DOCUMENT_SEND_PAGE_NOTIFICATION
		call	VisCallParent
		ret
GenerateAndSendPageNameNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeneratePageNameNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a page name token, generate a NotifyPageNameChange
		structure.

CALLED BY:	INTERNAL
PASS:		*ds:si	= text object
		ax	= index of page name
		dl	= PageNameChangeType

RETURN:		bx - handle of notification block
DESTROYED:	es, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeneratePageNameNotification		proc	far
		uses	cx, dx, bp
params	local	VisTextFindNameIndexParams
mname	local	NameArrayMaxElement
		.enter

		cmp	ax, CA_NULL_ELEMENT
		LONG	je	noName
	;
	; get the name from the context token
	;
		mov	ss:[params].VTFNIP_index, ax
		mov	ss:[params].VTFNIP_type, VTNT_CONTEXT
		mov	ss:[params].VTFNIP_file, 0

		segmov	es, ss, ax
		lea	di, ss:[mname]
		movdw	ss:[params].VTFNIP_name, esdi

		mov	cx, size NameArrayMaxElement
		mov	ax, 0
		rep	stosb

		push	bp
		lea	bp, ss:[params]
		mov	ax, MSG_VIS_TEXT_FIND_NAME_BY_INDEX
		call	ObjCallInstanceNoLock
		pop 	bp
		
	;
	; get the length of the name
	;
		push	ds, si
		lea	di, ss:[mname]
		add	di, size VisTextNameArrayElement
		segmov	ds, es, ax
		mov	si, di			; ds:si <- source
		call	LocalStringLength	; cx <- string length, w/o null
	;
	; allocate a notification block
	;
		push	cx			; save the string length
		add	cx, size NotifyPageNameChange
		mov	ax, cx
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
				or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	es, ax
		pop	cx
		mov	es:[NPNC_length], cx
		mov	ax, ss:[params].VTFNIP_index
		mov	es:[NPNC_index], ax
		mov	es:[NPNC_changeType], dl
	;
	; copy the name to the block
	;
		lea	di, es:[NPNC_name]	; es:di <- destination buffer
		rep	movsb
		pop	ds, si			;*ds:si <- Article object
		
		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount
exit:		
		.leave
		ret

noName:
		call	GenerateEmptyPageNameNotification
		jmp	exit
		
GeneratePageNameNotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateEmptyPageNameNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a page name notification for the case
		where the page has no name.

CALLED BY:	INTERNAL
PASS:		dl	= PageNameChangeType
RETURN:		bx	= handle of notification block
DESTROYED:	ax, cx, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateEmptyPageNameNotification		proc	near
		.enter

		mov	ax, size NotifyPageNameChange
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
				or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	es, ax
		mov	es:[NPNC_index], GIGS_NONE
		mov	es:[NPNC_changeType], dl
		clr	es:[NPNC_length]
		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount
		.leave
		ret
GenerateEmptyPageNameNotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameTokenToListIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a name token to its list index counterpart

CALLED BY:	GeneratePageNameNotification, StudioArticleSetContext
PASS:		*ds:si - article
		ax - name token
RETURN:		ax - name list index
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameTokenToListIndex		proc	near
		uses	bp
		.enter
	CheckHack < GIGS_NONE		eq -1 >
	CheckHack < CA_NULL_ELEMENT	eq 0xffff >
		cmp	ax, -1
		je	done
		sub	sp, size VisTextNotifyTypeChange
		mov	bp, sp
		mov	ss:[bp].VTNTC_type.VTT_context, ax	
		mov	ss:[bp].VTNTC_type.VTT_hyperlinkName, -1
		mov	ss:[bp].VTNTC_type.VTT_hyperlinkFile, -1
		mov	ax, MSG_VIS_TEXT_NAME_TOKENS_TO_LIST_INDICES
		call	ObjCallInstanceNoLock
		mov	ax, ss:[bp].VTNTC_index.VTT_context
		add	sp, size VisTextNotifyTypeChange
done:
		.leave
		ret
NameTokenToListIndex		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticlePageNameIndexToToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MESSAGE:	StudioArticlePageNameIndexToToken - 
		MSG_STUDIO_ARTICLE_PAGE_NAME_INDEX_TO_TOKEN

SYNOPSIS:	Converts a name list index to its name token counterpart

PASS:		*ds:si - article
		cx - name list index
RETURN:		ax - name token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticlePageNameIndexToToken		method StudioArticleClass,
				MSG_STUDIO_ARTICLE_PAGE_NAME_INDEX_TO_TOKEN
		uses	bp
		.enter
		CheckHack < GIGS_NONE		eq -1 >
		CheckHack < CA_NULL_ELEMENT	eq 0xffff >

		mov	ax, cx
		cmp	ax, -1
		je	done

		sub	sp, size VisTextFindNameIndexParams + 1
		mov	bp, sp
		mov	ss:[bp].VTFNIP_index, ax
		mov	ss:[bp].VTFNIP_type, VTNT_CONTEXT
		mov	ss:[bp].VTFNIP_file, 0
		clrdw	ss:[bp].VTFNIP_name		; don't return name
		mov	ax, MSG_VIS_TEXT_FIND_NAME_BY_INDEX
		call	ObjCallInstanceNoLock
		add	sp, size VisTextFindNameIndexParams + 1
EC <		cmp	ax, -1						>
EC <		ERROR_E	 PAGE_NAME_DOES_NOT_EXIST			>
done:
		.leave
		ret
StudioArticlePageNameIndexToToken		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleSetDisplayMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle change of display mode

CALLED BY:	MSG_VIS_LARGE_TEXT_SET_DISPLAY_MODE
PASS:		*ds:si	= StudioArticleClass object
		ds:di	= StudioArticleClass instance data
		cx	= VisLargeTextDisplayModes
RETURN:		none
DESTROYED:	everything
SIDE EFFECTS:	might modify VLTI_regionSpacing

PSEUDO CODE/STRATEGY:
	If we're changing to page or condensed mode, put
	DISPLAY_MODE_REGION_SPACING into VLTI_regionSpacing.  For Galley and
	Draft, we don't want the space, so we use 0.  This actually makes
	using the VTF_DONT_SHOW_SOFT_PAGE_BREAKS flag redundant.  Oh well.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	6/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleSetDisplayMode	method dynamic StudioArticleClass, 
					MSG_VIS_LARGE_TEXT_SET_DISPLAY_MODE

		cmp	cx, VLTDM_CONDENSED
		mov	ds:[di].VLTI_regionSpacing, DISPLAY_MODE_REGION_SPACING
		jbe	toSuper
		clr	ds:[di].VLTI_regionSpacing
toSuper:
		mov	di, offset StudioArticleClass
		GOTO	ObjCallSuperNoLock

StudioArticleSetDisplayMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuspendObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend calculation of the passed object

CALLED BY:	INTERNAL
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SuspendObject	proc	near
		uses	ax, cx, dx, bp
		.enter

		mov	ax, MSG_META_SUSPEND
		call	ObjCallInstanceNoLock

		.leave
		ret
SuspendObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnsuspendObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsuspend calculation of the passed object

CALLED BY:	INTERNAL
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnsuspendObject	proc	near
		uses	bp
		.enter

		mov	ax, MSG_META_UNSUSPEND
		call	ObjCallInstanceNoLock

		.leave
		ret
UnsuspendObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SA_ObjMessageQueueStackDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message on the queue with params on the stack.

CALLED BY:	INTERNAL
PASS:		ds:si	= object
		ss:bp	= parameters on stack
		ax	= message
		dx	= size of parameter struct
RETURN:		bx	= handle of object
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SA_ObjMessageQueueStackDS	proc	near

		mov	bx, ds:[LMBH_handle]
		call	SA_ObjMessageQueueStack
		ret
SA_ObjMessageQueueStackDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SA_ObjMessageQueueStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message on the queue with params on the stack.

CALLED BY:	INTERNAL
PASS:		^lbx:si	= object
		ss:bp	= parameters on stack
		ax	= message
		dx	= size of parameter struct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SA_ObjMessageQueueStack	proc	near
		mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
		call	ObjMessage
		ret
SA_ObjMessageQueueStack	endp

DocNotify ends

DocPageCreDest segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleRegionIsLast -- MSG_VIS_LARGE_TEXT_REGION_IS_LAST
							for StudioArticleClass

DESCRIPTION:	Handle notification that a region is the last region

PASS:
	*ds:si - instance data
	es - segment of StudioArticleClass

	ax - The message

	cx - last region #

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/28/92		Initial version

------------------------------------------------------------------------------@
StudioArticleRegionIsLast	method dynamic	StudioArticleClass,
					MSG_VIS_LARGE_TEXT_REGION_IS_LAST

	; in draft mode we want to bail completely and not delete regions

	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITH_STYLES
	jae	done

	mov	di, MSG_STUDIO_DOCUMENT_DELETE_PAGES_AFTER_POSITION
	GOTO	AppendDeleteCommon
done:
	ret

StudioArticleRegionIsLast	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleAppendRegion -- MSG_VIS_LARGE_TEXT_APPEND_REGION
							for StudioArticleClass

DESCRIPTION:	Add another region to an article

PASS:
	*ds:si - instance data
	es - segment of StudioArticleClass

	ax - The message

	cx - region to append after

RETURN:
	carry - set if another region cannot be appended

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
StudioArticleAppendRegion	method dynamic	StudioArticleClass,
						MSG_VIS_LARGE_TEXT_APPEND_REGION

	mov	di, MSG_STUDIO_DOCUMENT_APPEND_PAGES_VIA_POSITION
	FALL_THRU	AppendDeleteCommon

StudioArticleAppendRegion	endm

;---

	; di = message

AppendDeleteCommon	proc	far
	class	StudioArticleClass

	; first we suspend ourself (so that the suspend/unsuspend from
	; inserting regions has no ill effects)

	push	cx
	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock
	pop	cx

	; now we add pages

	call	GetRegionPos			;cx = x, dxbp = y

	mov_tr	ax, di
	call	VisCallParent

	; now nuke the suspend data, so the MSG_META_UNSUSPEND won't do 
	; anything...

	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
	call	ObjVarFindData		;DS:BX <- VisTextSuspendData
EC <	ERROR_NC	-1						>
	clr	ax
	clrdw	ds:[bx].VTSD_recalcRange.VTR_start, ax
	clrdw	ds:[bx].VTSD_recalcRange.VTR_end
	movdw	ds:[bx].VTSD_showSelectionPos, 0xffffffff
	mov	ds:[bx].VTSD_notifications, ax
	mov	ds:[bx].VTSD_needsRecalc, al

	mov	ax, MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	clc
	ret

AppendDeleteCommon	endp

DocPageCreDest ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleSubstAttrToken -- MSG_VIS_TEXT_SUBST_ATTR_TOKEN
							for StudioArticleClass

DESCRIPTION:	Substitute a text attribute token

PASS:
	*ds:si - instance data
	es - segment of StudioArticleClass

	ax - The message

	ss:bp - VisTextSubstAttrTokenParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/26/92		Initial version

------------------------------------------------------------------------------@
StudioArticleSubstAttrToken	method dynamic	StudioArticleClass,
						MSG_VIS_TEXT_SUBST_ATTR_TOKEN

	tst	ss:[bp].VTSATP_relayedToLikeTextObjects
	jnz	toSuper

	; send to attribute manager to take care of

	mov	ax, MSG_GOAM_SUBST_TEXT_ATTR_TOKEN
	mov	dx, size VisTextSubstAttrTokenParams
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ToAttrMgrCommon
	ret

toSuper:
	mov	di, offset StudioArticleClass
	GOTO	ObjCallSuperNoLock

StudioArticleSubstAttrToken	endm

;---

	; ax = message, di = flags

ToAttrMgrCommon	proc	near
	push	si
	mov	bx, segment GrObjAttributeManagerClass
	mov	si, offset GrObjAttributeManagerClass
	call	ObjMessage
	pop	si
	mov	cx, di
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_TARGET
	call	VisCallParent
	ret
ToAttrMgrCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleRecalcForAttrChange --
		MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE for StudioArticleClass

DESCRIPTION:	Recalculate for an attribute change

PASS:
	*ds:si - instance data
	es - segment of StudioArticleClass

	ax - The message

	cx - relayed globally flag

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/26/92		Initial version

------------------------------------------------------------------------------@
StudioArticleRecalcForAttrChange	method dynamic	StudioArticleClass,
					MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE

	tst	cx
	jnz	toSuper

	; send to attribute manager to take care of

	mov	ax, MSG_GOAM_RECALC_FOR_TEXT_ATTR_CHANGE
	mov	di, mask MF_RECORD
	call	ToAttrMgrCommon
	ret

toSuper:
	mov	di, offset StudioArticleClass
	GOTO	ObjCallSuperNoLock

StudioArticleRecalcForAttrChange	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleGetObjectForSearchSpell --
		MSG_META_GET_OBJECT_FOR_SEARCH_SPELL for StudioArticleClass

DESCRIPTION:	Get the next object for search/spell

PASS:
	*ds:si - instance data
	es - segment of StudioArticleClass

	ax - The message

	cx:dx - object that search/spell is currently in
	bp - GetSearchSpellObjectOption

RETURN:
	cx:dx - requested object (or 0 if none)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/19/92		Initial version

------------------------------------------------------------------------------@
StudioArticleGetObjectForSearchSpell	method dynamic	StudioArticleClass,
					MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
	call	VisCallParent
	ret

StudioArticleGetObjectForSearchSpell	endm

DocSTUFF ends

DocMiscFeatures segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleSetVisParent -- MSG_STUDIO_ARTICLE_SET_VIS_PARENT
						for StudioArticleClass

DESCRIPTION:	Set the vis parent for an article

PASS:
	*ds:si - instance data
	es - segment of StudioArticleClass

	ax - The message

	cxdx - parent

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/21/92		Initial version

------------------------------------------------------------------------------@
StudioArticleSetVisParent	method dynamic	StudioArticleClass,
					MSG_STUDIO_ARTICLE_SET_VIS_PARENT

	ornf	dx, LP_IS_PARENT
	movdw	ds:[di].VI_link.LP_next, cxdx
	ret

StudioArticleSetVisParent	endm

DocMiscFeatures ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleDisplayObjectForSearchSpell --
		MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL for StudioArticleClass

DESCRIPTION:	Display the object

PASS:
	*ds:si - instance data
	es - segment of StudioArticleClass

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
	Tony	11/20/92		Initial version

------------------------------------------------------------------------------@
StudioArticleDisplayObjectForSearchSpell method dynamic	StudioArticleClass,
					MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL

	call	MakeContentEditable
	ret

StudioArticleDisplayObjectForSearchSpell	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleCrossSectionReplaceAborted --
		MSG_VIS_TEXT_CROSS_SECTION_REPLACE_ABORTED for StudioArticleClass

DESCRIPTION:	Notification that a cross section change has been aborted

PASS:
	*ds:si - instance data
	es - segment of StudioArticleClass

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
	Tony	11/30/92		Initial version

------------------------------------------------------------------------------@
StudioArticleCrossSectionReplaceAborted	method dynamic	StudioArticleClass,
				MSG_VIS_TEXT_CROSS_SECTION_REPLACE_ABORTED

	mov	ax, offset CrossSectionReplaceAbortedString
	call	DisplayError
	ret

StudioArticleCrossSectionReplaceAborted	endm

DocSTUFF ends

DocNotify segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleGraphicVariableDraw --
		MSG_VIS_TEXT_GRAPHIC_VARIABLE_DRAW for VisTextClass

DESCRIPTION:	draw a variable graphic, handling VTVT_CONTEXT_NAME
		specially

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx - gstate with font and current position set
	dx:bp - VisTextGraphic (dx always = ss)

RETURN:
	cx - width of the graphic
	dx - height of the graphic

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version
	jenny	9/29/94		Broke out size-getting.
------------------------------------------------------------------------------@
StudioArticleGraphicVariableDraw	method dynamic StudioArticleClass,
					MSG_VIS_TEXT_GRAPHIC_VARIABLE_DRAW
	;
	; If it's not a page name, never mind.
	;
		cmp	ss:[bp].VTG_data.VTGD_variable.VTGV_type,
			VTVT_CONTEXT_NAME
		jne	callSuper
	;
	; Get the variable's string and size.
	;
		sub	sp, GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE
		mov	di, sp				; ss:di <- buffer
		call	GetVariableStringAndSize	; ds:si <- string
							; cx <- width
							; dx <- height
							; di <- gstate
		jcxz	done
	;
	; Draw the string.
	;
		push	di				; save gstate
		call	GrSaveState

		mov	ax, C_CYAN
		call	GrSetTextColor

		mov_tr	ax, cx				; save width
		clr	cx				; it's null-terminated
		call	GrDrawTextAtCP
		mov_tr	cx, ax				; cx <- width

		pop	di
		call	GrRestoreState

done:
		add	sp, GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE
		ret

callSuper:
		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock
		ret

StudioArticleGraphicVariableDraw	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioArticleGraphicVariableSize --
		MSG_VIS_TEXT_GRAPHIC_VARIABLE_SIZE for StudioArticleClass

DESCRIPTION:	get the size of a variable graphic, handling 
		VTVT_CONTEXT_NAME specially

PASS:
	*ds:si - instance data
	es - segment of StudioArticleClass

	ax - The message

	cx - gstate with font and current position set
	dx:bp - VisTextGraphic (dx always = ss)

RETURN:
	cx - width of the graphic
	dx - height of the graphic

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version
	jenny	9/29/94		Broke out size-getting.
------------------------------------------------------------------------------@
StudioArticleGraphicVariableSize	method dynamic StudioArticleClass,
					MSG_VIS_TEXT_GRAPHIC_VARIABLE_SIZE
	;
	; If it's not a page name, never mind.
	;
		cmp	ss:[bp].VTG_data.VTGD_variable.VTGV_type,
			VTVT_CONTEXT_NAME
		jne	callSuper
	;
	; Get the size.
	;
		sub	sp, GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE
		mov	di, sp				; ss:di = buffer
		call	GetVariableStringAndSize	; cx <- width
							; dx <- height
		add	sp, GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE
		ret

callSuper:
		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock
		ret

StudioArticleGraphicVariableSize	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetVariableStringAndSize

DESCRIPTION:	Get the string for a variable and its size in points.

CALLED BY:	INTERNAL	StudioArticleGraphicVariableSize
				StudioArticleGraphicVariableDraw
PASS:
	*ds:si	= text object
	es	= dgroup
	dx:bp	= VisTextGraphic (dx always = ss)
	ss:di	= string buffer
	cx	= gstate
RETURN:
	carry	= set if got string (i.e. if showing invisibles)
	ds:si	= string	(ds = ss)
	cx	= width in points
	dx	= height in points
	di	= gstate

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version
	jenny	9/29/94		Added size-getting; no longer uses
				 C_SECTION when not showing invisibles
------------------------------------------------------------------------------@
GetVariableStringAndSize	proc	near
		uses ax, bx, bp
		.enter
	;
	; Only if we're showing invisibles is the variable graphic being
	; represented by its string.
	;
		clr	ax
		xchg	cx, ax		; cx <- assume no string width
					; ax <- gstate
		test	es:[miscSettings], mask SMS_SHOW_INVISIBLES
		jz	gotWidth
		push	ax
	;
	; Push GenDocumentGetVariableParams on the stack.
	;
		push	ds:[LMBH_handle], si		;GDGVP_object
		pushdw	dxbp				;GDGVP_graphic
		pushdw	ssdi				;GDGVP_buffer

		clrdw	dxax
		pushdw	dxax				;GDGVP_position.PD_y
		pushdw	dxax				;GDGVP_position.PD_x
		mov	bp, sp
	;
	; Get the string.
	;
		mov	dx, size GenDocumentGetVariableParams
		mov	ax, MSG_GEN_DOCUMENT_GET_VARIABLE
		call	VisCallParent
		add	sp, size GenDocumentGetVariableParams
		segmov	ds, ss, ax
		mov	si, di				;ds:si = string
	;
	; Now get the size.
	;
		pop	di			; di = gstate
		clr	cx			; it's null-terminated
		call	GrTextWidth
		mov	cx, dx			; cx = width
gotWidth:
		clr	dx			; height = 0
		.leave
		ret

GetVariableStringAndSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleFollowHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we are follwing a link from a hotspot, we need to
		change to the text tool and give the target back to the
		article.
		
CALLED BY:	MSG_VIS_TEXT_FOLLOW_HYPERLINK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
		ss:bp - 
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleFollowHyperlink		method dynamic StudioArticleClass,
						MSG_VIS_TEXT_FOLLOW_HYPERLINK
	;
	; If the current tool is not the Studio text tool, 
	; change to that tool, then callsuper to follow the hyperlink
	;
		push	ds:[LMBH_handle]
		call	IsTextTool
		jc	callSuper
		call	SetStudioTool
callSuper:
		pop	bx
		call	MemDerefDS
		GetResourceSegmentNS	StudioArticleClass, es
		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock
	;
	; Setting a hyperlink changes char attrs, which causes text to
	; update, drawing over any hotspots.  Need to redraw hotspots
	; at this point.
	;
		ret

StudioArticleFollowHyperlink		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAVisTextRenameName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If user is changing a page name, and show invisibles is on,
		redraw.

CALLED BY:	MSG_VIS_TEXT_RENAME_NAME
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
		ss:bp - VisTextNameCommonParams
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAVisTextRenameName		method dynamic StudioArticleClass,
						MSG_VIS_TEXT_RENAME_NAME

		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock
	;
	; is this rename for a context in the same file?
	;
		cmp	ss:[bp].VTNCP_data.VTND_type, VTNT_CONTEXT
		jne	done
		cmp	ss:[bp].VTNCP_data.VTND_file, 0
		jne	done

		call	ForceRedrawIfShowingInvisibles
done:
		ret
SAVisTextRenameName		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceRedrawIfShowingInvisibles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force a redraw if showing invisibles

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceRedrawIfShowingInvisibles		proc	near
		uses	bx, si, bp
		.enter

		GetResourceSegmentNS	dgroup, es
		test	es:[miscSettings], mask SMS_SHOW_INVISIBLES
		jz	noInvisibles
		GetResourceHandleNS	StudioViewControl, bx
		mov	si, offset StudioViewControl
		clr	di
		mov	ax, MSG_GVC_REDRAW
		call	ObjMessage

noInvisibles:
		.leave
		ret
ForceRedrawIfShowingInvisibles		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleSetHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_TEXT_SET_HYPERLINK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleSetHyperlink		method dynamic StudioArticleClass,
						MSG_META_TEXT_SET_HYPERLINK,
						MSG_VIS_TEXT_SET_HYPERLINK
		call	SuspendObject

		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock

		call	UnsuspendObject
		
		ret
StudioArticleSetHyperlink		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleSetContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A page is being named.  Send out a NotifyPageNameChange
		notification.

CALLED BY:	MSG_VIS_TEXT_SET_CONTEXT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioArticleClass
		ax - the message
		ss:bp - VisTextSetContextParams
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/27/94		Initial version
	jenny	9/ 1/94    	Allow only one page name graphic per page

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleSetContext			method dynamic StudioArticleClass,
						MSG_VIS_TEXT_SET_CONTEXT
		mov	di, bp
params		local	EnumPageNameGraphicsLocals
		.enter
	;
	; If we're resetting the stored context on a page name graphic,
	; only the superclass need interest itself.
	;
		mov	ax, ATTR_SA_SET_STORED_CONTEXT_COUNT
		call	ObjVarFindData			;ds:bx - ptr to count
		LONG jc	callSuperOnly
	;
	; Don't redraw till we're through fooling with stuff.
	;
		call	SuspendObject

		mov	ax, ds:[LMBH_handle]
		movdw	ss:params.EPNGL_textObj, axsi
	;
	; get the range's physical boundaries
	;
		push	bp
		mov	bp, di
		call	GetTextRange
		pop	bp
	;
	; We need both the list index (for the page name change notification)
	; and the name token (for the variable graphic). As soon as we have
	; the index, we store it on the stack for later use in the
	; notification.
	;
		mov	ax, ss:[di].VTSCXP_context
		test	ss:[di].VTSCXP_flags, mask VTCF_TOKEN
		jz	getToken
		call	NameTokenToListIndex
		push	ax				; save index
		mov	ax, ss:[di].VTSCXP_context
		jmp	haveToken
getToken:
		push	ax				; save index
		mov	cx, ax
		mov	ax, MSG_STUDIO_ARTICLE_PAGE_NAME_INDEX_TO_TOKEN
		call	ObjCallInstanceNoLock	; ax = name token
		mov	ss:[di].VTSCXP_context, ax
		ornf	ss:[di].VTSCXP_flags, mask VTCF_TOKEN
haveToken:
	;
	; ax = token.  If no token, we are in the process of clearing
	; the page name.
	;
		cmp	ax, CA_NULL_ELEMENT
		je	clearContext
		mov	ss:[params].EPNGL_name, ax	; record token
	;
	; We don't want a context to be set on more than one page.
	;
		test	ss:[di].VTSCXP_flags,
				mask VTCF_ENSURE_CONTEXT_NOT_ALREADY_SET
		jz	setContext
		call	CheckIfPageNameAlreadyUsed
		jc	unsuspendRedraws		; done if name's
							;  been used
	;
	; No need for our superclass to be vigilant, as we know all is well.
	;
		andnf	ss:[di].VTSCXP_flags,
				not mask VTCF_ENSURE_CONTEXT_NOT_ALREADY_SET
setContext:
		call	FigureRangeAndSetContextThere
	;
	; We're dealing with a single context.
	;
		mov	dl, PNCT_SET_CONTEXT
sendNotification:
	;
	; Send a notification that the page name has changed so
	; the page name controller can update its status bar
	;
		pop	ax				; ax <- index
		call	GenerateAndSendPageNameNotification
	;
	; If showing invisibles, force a redraw so
	; that any name changes will be shown.
	;
		call	ForceRedrawIfShowingInvisibles
unsuspendRedraws:
		call	UnsuspendObject
done:
		.leave
		ret

clearContext:
		call	StudioArticleClearContextLow
		jmp	sendNotification

callSuperOnly:
	;
	; ds:[bx] = extra data for ATTR_SA_SET_STORED_CONTEXT_COUNT
	;
		subdw	ds:[bx], 1
		tstdw	ds:[bx]
		jnz	callSuper
		call	ObjVarDeleteData
callSuper:
		push	bp
		mov	bp, di
		call	SetContextCallSuperNoLockLow
		pop	bp
		jmp	done

StudioArticleSetContext		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the physical coordinates corresponding to the
		passed virtual ones

CALLED BY:	INTERNAL	StudioArticleSetContext

PASS:		*ds:si	= article
		ss:bp	= VisTextRange holding virtual coordinates
		ss:di	= ditto

RETURN:		ss:di	= VisTextRange holding physical coordinates
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextRange	proc	near

		clr	cx				;no context
		mov	dx, ss				;dx:bp <- VisTextRange
		mov	ax, MSG_VIS_TEXT_GET_RANGE
		call	ObjCallInstanceNoLock

		ret
GetTextRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureRangeAndSetContextThere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the range over which to set the context and set it.

CALLED BY:	INTERNAL	StudioArticleSetContext

PASS:		*ds:si	= article
		ss:di	= VisTextSetContextParams
		ss:bp	=  inherited EnumPageNameGraphicsLocals
				EPNGL_name = new page name token
RETURN:		nothing
DESTROYED:	ax, cx, bx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureRangeAndSetContextThere	proc	near
		.enter inherit StudioArticleSetContext
	;
	; We want only one context set per page. If we have a page
	; name graphic on the page already, we replace the context
	; token currently associated with it by the token of the new
	; context and get the position of the graphic so as to
	; overwrite the context set at that position with the new context.
	; 
		push	di
		call	GetPageRangeFromVisTextRangeStart
		mov	di, offset ReplaceCurrentContextCallback
		call	EnumPageNameGraphics	; carry <- set if graphic
						;  found
						; ss:[bp].EPNGL_position
						;  <- graphic position
		pop	di
		jc	useRunBounds
	;
	; This page has no existing page name graphic, so insert one.
	;
		movdw	ss:[di].VTR_end, dxax
		clr	bx				; 1st word of data
		mov	dx, VTVT_CONTEXT_NAME		; variable graphic type
		mov	ax, ss:[params].EPNGL_name	; ax <- token
		call 	StudioArticleInsertVariableGraphic
	;
	; We want to apply the context only to the variable graphic, so
	; we limit the range to the first character of the passed range.
	;
		movdw	dxax, ss:[di].VTR_start
		incdw	dxax
		movdw	ss:[di].VTR_end, dxax
setContext:
		push	bp
		mov	bp, di
		call	SetContextCallSuperNoLockLow
		pop	bp
		.leave
		ret
useRunBounds:
	;
	; Find the bounds of the context presently set so as to overwrite
	; that whole range with the new context.
	;
		movdw	dxax, ss:[params].EPNGL_position
		call	GetTypeRunBoundsLow	; ss:[di] <- VisTextRange
						;  filled with bounds
		jmp	setContext

FigureRangeAndSetContextThere	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfPageNameAlreadyUsed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether page name has been assigned to a page already

CALLED BY:	INTERNAL	StudioArticleSetContext

PASS:		*ds:si	= article
		ax	= context token
RETURN:		carry set if page name already used 
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfPageNameAlreadyUsed	proc	near
		uses	di,bp
		.enter
	;
	; Get the range of the whole article.
	;
		push	ax			; save context token
		call	GetWholeArticleRange
	;
	; See if the passed page name has been set on a page already.
	;
		mov	di, offset MatchPageNameCallback
		call	EnumPageNameGraphics	; carry <- set if
						;  graphic found
		pop	ax			; ax <- context token
		jnc	done

		mov	di, offset PageNameAlreadyUsedErrorString
		mov	cx, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		call	DoPageNameAlreadyUsedDialog
		stc
done:
		.leave
		ret
CheckIfPageNameAlreadyUsed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWholeArticleRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range of the article.

CALLED BY:	INTERNAL	CheckIfPageNameAlreadyUsed
				HandleVariableGraphicInsertion

PASS:		*ds:si	= article

RETURN:		dx:ax	= start of range
		cx:bx	= end of range

DESTROYED:	ax
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetWholeArticleRange	proc	near
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		movdw	cxbx, dxax		; cx:bx <- end of article
		clrdw	dxax			; dx:ax <- start of article
		ret
GetWholeArticleRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPageNameAlreadyUsedDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog saying a page name is in use already

CALLED BY:	INTERNAL	CheckIfPageNameAlreadyUsed
PASS:		*ds:si	= article
		ax	= context token
		cx	= flags for UserStandardDialog
		di	= offset of error string to use

RETURN:		nothing
DESTROYED:	cx, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoPageNameAlreadyUsedDialog	proc	near
		uses	ax, si
nameEltBuf	local	MAX_VIS_TEXT_NAME_ARRAY_ELT_SIZE dup(char)
		.enter
	;
	; Get the name array element for the context.
	;
		push	bp
		push	di, cx			; save offset and flags
		mov	cx, ss
		lea	dx, ss:[nameEltBuf]
		mov	bp, ax			; bp <- context token
		mov	ax, MSG_VIS_TEXT_FIND_NAME_BY_TOKEN
		call	ObjCallInstanceNoLock	; ax <- element size
	;
	;  NULL terminate the name string.
	;
		mov	es, cx
		mov	di, dx
		add	di, ax			; es:di <- end of string
		mov	{char}es:[di], 0		
	;
	; Tell the user this page name belongs to a page already.
	;
		mov	di, dx
		add	di, size VisTextNameArrayElement
						; es:di <- name string
		pop	si, ax			; si <- error string offset
						; ax <- flags
		call	DoStandardDialog
		pop	bp

		.leave
		ret
DoPageNameAlreadyUsedDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatchPageNameCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for page name token matching token passed on stack

CALLED BY:	StudioArticleSetContext (via EnumPageNameGraphics)

PASS:		ss:bp	= inherited EnumPageNameGraphicsLocals
				EPNGL_name = page name token to match
		bx	= page name token

RETURN:		carry set if match found (stops enumeration)

DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 3/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MatchPageNameCallback		proc	near
		.enter inherit StudioArticleSetContext

		cmp	ss:params.EPNGL_name, bx
		clc
		jne	done
		stc			; stop hunting
done:
		.leave
		ret
MatchPageNameCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceCurrentContextCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the current page name graphic represent the
		passed page name.

CALLED BY:	StudioArticleSetContext (via EnumPageNameGraphics)

PASS:		ds:si	= graphic TextRunArrayElement
		es	= segment of graphic element array
		ss:bp	= inherited EnumPageNameGraphicsLocals
				EPNGL_name = new page name token for run

RETURN:		ss:[bp].params.EPNGL_position = start position of element
		carry set

DESTROYED:	ax
SIDE EFFECTS:
	Replaces graphic's stored page name token with the passed token.

PSEUDO CODE/STRATEGY:
	Routine assumes there is at most one page name graphic per page and
	so sets the carry to stop the enumeration after one call.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------	
	jenny	9/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceCurrentContextCallback	proc	near
		.enter inherit StudioArticleSetContext
	;
	; First store the new context token for the graphic.
	;
		pushdw	dssi
		mov	ax, ds:[si].TRAE_token
		segmov	ds, es
		mov	si, VM_ELEMENT_ARRAY_CHUNK
		call	ChunkArrayElementToPtr	; ds:di <- graphic
		mov	ax, ss:[params].EPNGL_name
		mov	{word} \
		    ds:[di].VTG_data.VTGD_variable.VTGV_privateData[2], ax
		popdw	dssi
	;
	; Now get the graphic's position and set the carry since we've
	; found the only graphic on the page.
	;
		clr	ax
		mov	al, ds:[si].TRAE_position.WAAH_high
		mov	ss:[params].EPNGL_position.high, ax
		mov	ax, ds:[si].TRAE_position.WAAH_low
		mov	ss:[params].EPNGL_position.low, ax
		stc
		.leave
		ret
ReplaceCurrentContextCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleClearContextLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete page name chars and clear corresponding contexts

CALLED BY:	INTERNAL	StudioArticleSetContext

PASS:		*ds:si	= text object
		es	= segment of text object
		ss:di	= VisTextSetContextParams

RETURN:		dl	= PageNameChangeType

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/20/94		Initial version
	jenny	9/ 1/94    	Broke out DeletePageNameGraphicsInRange
	jenny	10/13/94	Added code broken out of StudioArticleSetContext
				 and check for clearing multiple contexts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleClearContextLow		proc	near
		uses	bp
		.enter inherit StudioArticleSetContext
	;
	; Clear the contexts and delete the page name chars for all
	; page that overlap with the passed range. First get the start
	; of the first page.
	;
		push	di
		call	GetPageRangeFromVisTextRangeStart
		pop	di
		movdw	ss:[di].VTR_start, dxax
	;
	; Then get the end of the last page.
	;
		push	di
		movdw	dxax, ss:[di].VTR_end
		call	GetPageRangeAndNumber	; dx:ax <- start
						; cx:bx <- end
		pop	di
		movdw	ss:[di].VTR_end, cxbx
	;
	; Notice whether the start of the first page is different from
	; the start of the last; this tells us whether we're clearing
	; multiple contexts.
	;
		cmpdw	ss:[di].VTR_start, dxax
		mov	dl, PNCT_SET_CONTEXT
		je	gotChangeType
		mov	dl, PNCT_CLEAR_MULTIPLE_CONTEXTS
gotChangeType:
		push	dx
	;
	; Clear the context(s) and delete the page name graphic(s).
	;
		push	bp, di
		mov	bp, di
		call	SetContextCallSuperNoLockLow
		pop	bp, di
		call	DeletePageNameGraphicsInVisTextRange
	;
	; Return change type.
	;
		pop	dx

		.leave
		ret
StudioArticleClearContextLow		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeletePageNameGraphicsInVisTextRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL		StudioArticleClearContextLow
PASS:		*ds:si	= text object
		ss:di	= VisTextRange
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeletePageNameGraphicsInVisTextRange	proc	near

		movdw	dxax, ss:[di].VTR_start
		movdw	cxbx, ss:[di].VTR_end
		FALL_THRU	DeletePageNameGraphicsInRange

DeletePageNameGraphicsInVisTextRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeletePageNameGraphicsInRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the page name graphics in the passed range.

CALLED BY:	INTERNAL	DeletePageNameGraphicsInVisTextRange
				HandleVariableGraphicInsertion

PASS:		*ds:si	= text object
		ss:bp	= inherited EnumPageNameGraphicsLocals
		dx:ax	= range start
		cx:bx	= range end

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 1/94    	Broke out of StudioArticleClearContextLow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeletePageNameGraphicsInRange	proc	near
		uses	di
		.enter inherit StudioArticleSetContext
	;
	; We don't want any undo chains for these deletions.
	;
		push	cx, dx
		clr	cx				; cx <- set nothing
		mov	dx, mask VTF_ALLOW_UNDO		; dx <- clear undo
		call	SetArticleFeatures
		pop	cx, dx
	;
	; Delete the page name graphics in the passed range.
	;
		clrdw	ss:params.EPNGL_count
		mov	di, offset DeletePageNameGraphic
		call	EnumPageNameGraphics
	;
	; Resume allowing undo.
	;
		mov	cx, mask VTF_ALLOW_UNDO		; dx <- set undo
		clr	dx				; cx <- clear nothing
		call	SetArticleFeatures
	;
	; If we didn't delete anything, we're done.
	;
		tstdw	ss:params.EPNGL_count
		jz	done
	;
	; Add delete count to the ignore count
	;
		mov	ax, ATTR_SA_IGNORE_DELETE_VARIABLE_GRAPHICS
		call	ObjVarFindData			;ds:bx - ptr to count
		jc	varDataExists
		mov	cx, size dword
		call	ObjVarAddData			;ds:bx - ptr to count
		
varDataExists:
		movdw	dxax, ss:params.EPNGL_count
		adddw	ds:[bx], dxax
	;
	; Put the count of number of page name chars to be deleted
	; in vardata, so that we know to not filter their deletion.
	; 
		mov	cx, size dword
		mov	ax, ATTR_SA_CLEAR_PAGE_NAME_CHAR_COUNT
		call	ObjVarAddData			;ds:bx - ptr to count
		movdw	dxax, ss:params.EPNGL_count
		movdw	ds:[bx], dxax
done:
		.leave
		ret
DeletePageNameGraphicsInRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetArticleFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the features for the article

CALLED BY:	INTERNAL	DeletePageNameGraphicsInRange

PASS:		cx	= VisTextFeatures to set
		dx	= VisTextFeatures to clear
		si	= chunk of text object OD
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetArticleFeatures	proc	near
		uses	ax, bx, bp, di
		.enter inherit StudioArticleSetContext

		mov	bx, ss:params.EPNGL_textObj.handle
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_VIS_TEXT_SET_FEATURES
		call	ObjMessage
		.leave
		ret
SetArticleFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeletePageNameGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a page name graphic character

CALLED BY:	StudioArticleUnsetAllContexts (via EnumPageNameGraphics)
PASS:		ds:si - graphic TextRunArrayElement
		inherited variables
RETURN:		carry clear
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeletePageNameGraphic		proc	near
		uses	si, di, bp
		.enter inherit StudioArticleSetContext

		clr	dh
		mov	dl, ds:[si].TRAE_position.WAAH_high
		mov	ax, ds:[si].TRAE_position.WAAH_low

		sub	sp, size VisTextReplaceParameters
		mov	di, sp
	;
	; subtract out the effect of previous deletions, as the
	; graphic we are trying to delete now will have moved
	; from its original position by the time this message arrives
	;
		subdw	dxax, ss:params.EPNGL_count
		movdw	ss:[di].VTRP_range.VTR_start, dxax
		incdw	dxax
		movdw	ss:[di].VTRP_range.VTR_end, dxax
		clrdw	ss:[di].VTRP_insCount
	;
	; the replace must be filtered, so that HotSpotText can
	; update the HotSpotArray
	;
		mov	ss:[di].VTRP_flags, mask VTRF_FILTER
		movdw	bxsi, ss:params.EPNGL_textObj
		
		push	bp
		mov	bp, di
		mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
		mov	dx, size VisTextReplaceParameters
	;
	; Make sure the message goes on the queue. If it were to be
	; called, then the graphic character would be immediately
	; eliminated from the range over which EnumPageNameGraphics is
	; enumerating, which would mean that suddenly the first
	; character after that range would fall within it. If that
	; character were a page name graphic, we'd wind up back here
	; zapping it unjustifiably.  -jenny 10/11/94
	;
		call	SA_ObjMessageQueueStack
		pop	bp
		add	sp, size VisTextReplaceParameters

		incdw	ss:params.EPNGL_count
		clc				;continue enumerating
		.leave
		ret
DeletePageNameGraphic		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsPageNameGraphicHere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set carry to let caller know that there is a page
		name graphic at the passed offset.

CALLED BY:	SAVisTextReplaceParams (via EnumPageNameGraphics)
PASS:		ds:si - graphic TextRunArrayElement
RETURN:		carry set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsPageNameGraphicHere		proc	near
		stc				;stop enumerating
		ret
IsPageNameGraphicHere		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleInsertVariableGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a variable graphic char

CALLED BY:	
PASS:		*ds:si - article
		dx - VisTextVariableType
		bx - format
		ax - name token
		ss:di - range to replace

RETURN:		nothing
DESTROYED:	everything but ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/11/94		Initial version
	jenny	12/ 9/94	Store a unique ID in the privateData

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleInsertVariableGraphic		proc	near
	uses	ax, bp
	.enter
	;
	; Set up the structure to pass and zero it out.
	;
	sub	sp, size ReplaceWithGraphicParams
	mov	bp, sp
	push	ax, di
	segmov	es, ss, ax
	mov	di, bp
	mov	cx, size ReplaceWithGraphicParams
	clr	ax
	rep	stosb
	pop	ax, di

	mov	ss:[bp].RWGP_graphic.VTG_type, VTGT_VARIABLE
	mov	ss:[bp].RWGP_graphic.VTG_flags, mask VTGF_DRAW_FROM_BASELINE
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_manufacturerID,
			MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_type, dx
	mov	{word} \
	    ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData, bx
	mov	{word} \
	    ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData[2], ax
	;
	; Get a unique ID and store it in the graphic's private data.
	;
	call	GetWholePageNameGraphicID	; dx:ax <- FileID
						; cx <- ID unique
						;  within file
	mov	{word} \
	    ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData[4], dx
	mov	{word} \
	    ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData[6], ax
	mov	{word} \
	    ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData[8], cx

	movdw	dxax, ss:[di].VTR_start
	movdw	ss:[bp].RWGP_range.VTR_start, dxax
	movdw	ss:[bp].RWGP_range.VTR_end, dxax

	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC
	mov	dx, size ReplaceWithGraphicParams
	call	ObjCallInstanceNoLock

	add	sp, size ReplaceWithGraphicParams

	.leave
	ret
StudioArticleInsertVariableGraphic		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWholePageNameGraphicID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a unique ID to store in a page name graphic.

CALLED BY:	INTERNAL	StudioArticleInsertVariableGraphic
				FixupPageNameGraphic
PASS:		
RETURN:		dx:ax	= FileID
		cx	= unique internal ID for page name graphic
DESTROYED:	es
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetWholePageNameGraphicID	proc	near
		uses	di
		.enter

		call	GetFileID
		call	GetPageNameGraphicID

		.leave
		ret
GetWholePageNameGraphicID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the file's FileID.

CALLED BY:	INTERNAL	GetWholePageNameGraphicID
PASS:		ds	= segment of article
RETURN:		dx:ax	= FileID
DESTROYED:	cx, di, es
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileID	proc	near

		call	GetFileHandle			; bx <- file handle
		segmov	es, ss
		sub	sp, (size FileID)
		mov	di, sp				; es:di <- buffer
		mov	ax, FEA_FILE_ID
		mov	cx, (size FileID)
		call	FileGetHandleExtAttributes
			CheckHack <size FileID eq size dword>
		mov	dx, {word} es:[di].high
		mov	ax, {word} es:[di].low
		add	sp, (size FileID)

		ret
GetFileID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageNameGraphicID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the unique ID to store in the next page name graphic.

CALLED BY:	INTERNAL	GetWholePageNameGraphicID
PASS:		*ds:si	= article
RETURN:		cx	= ID
DESTROYED:	nothing
SIDE EFFECTS:
	Increments the ID stored with the document.
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPageNameGraphicID	proc	near

		mov	ax, MSG_STUDIO_DOCUMENT_GET_PAGE_NAME_GRAPHIC_ID
		call	VisCallParent		; cx <- unique ID

		ret
GetPageNameGraphicID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageRangeFromVisTextRangeStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the range of the page containing the start of the
		passed text range.

CALLED BY:	INTERNAL	StudioArticleSetContext
				StudioArticleGetPageName

PASS:		*ds:si - article
		ss:di - VisTextRange

RETURN:		dx:ax - start offset of page which contains start select
		cx:bx - end offset of page
		di - page number

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPageRangeFromVisTextRangeStart	proc	near

		movdw	dxax, ss:[di].VTR_start
		FALL_THRU GetPageRangeAndNumber

GetPageRangeFromVisTextRangeStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageRangeAndNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the VisTextRange which covers the page containing
		the passed text position

CALLED BY:	INTERNAL
PASS:		*ds:si - article
		dx:ax - start select position
RETURN:		dx:ax - start offset of page which contains start select
		cx:bx - end offset of page
		di - page number
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPageRangeAndNumber		proc	near
		uses	si, bp
startOffset	local	dword
		.enter

		clrdw	ss:startOffset

		mov	si, offset ArticleRegionArray
		mov	di, ds:[si]
		mov	cx, ds:[di].CAH_count
		add	di, ds:[di].CAH_offset
findLoop:		
		adddw	ss:startOffset, ds:[di].VLTRAE_charCount, bx
		cmpdw	dxax, ss:startOffset
		jb	foundIt
		add	di, size ArticleRegionArrayElement
		loop	findLoop
		sub	di, size ArticleRegionArrayElement

foundIt:
		call	ChunkArrayPtrToElement	;ax = current element, or
		push	ax			;  page number
		movdw	cxbx, ss:startOffset	;cx:bx = start offset of 
						; *next* region
		movdw	dxax, cxbx
		test	ds:[di].VLTRAE_flags, mask VLTRF_ENDED_BY_COLUMN_BREAK
		jz	noBreak			;don't sub off 1 for col break
		decdw	cxbx			;cx:bx = end offset of this reg
noBreak:
		subdw	dxax, ds:[di].VLTRAE_charCount
						;dx:ax = start off. of this reg
		pop	di			;bp = page number
		.leave
		ret
GetPageRangeAndNumber		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageRangeFromPageNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the VisTextRange which covers the passed page number

CALLED BY:	INTERNAL
PASS:		*ds:si - article
		cx - page number
RETURN:		dx:ax - start offset of page which contains start select
		cx:bx - end offset of page
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/15/94		Initial version
	jenny	9/14/94		Fixed not to assume that a page break
				 follows the last page

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPageRangeFromPageNumber		proc	near
		uses	si
startOffset	local	dword
		.enter
	;
	; First find out whether this is the last page and save the
	; flags so we'll know later.
	;
		mov	si, offset ArticleRegionArray
		mov	si, ds:[si]
		inc	cx
		cmp	cx, ds:[si].CAH_count
EC <		ERROR_A	PAGE_INDEX_OUT_OF_RANGE				>
		pushf
		dec	cx
	;
	; Start off at the first page and count up to get the info for
	; the page passed.
	;
		clrdw	startOffset
		add	si, ds:[si].CAH_offset
		jcxz	foundPage
countLoop:		
		adddw	ss:startOffset, ds:[si].VLTRAE_charCount, bx
		add	si, size ArticleRegionArrayElement
		loop	countLoop
foundPage:
		movdw	dxax, ss:startOffset	;dx:ax = start offset
		movdw	cxbx, dxax
		adddw	cxbx, ds:[si].VLTRAE_charCount
	;
	; Now restore the flags which indicate whether we're dealing
	; with the last page. If we're not, decrement the end offset so
	; as not to include the page break character in the range.
	;
		popf
		je	done
		decdw	cxbx			;cx:bx = end offset 
done:
		.leave
		ret
GetPageRangeFromPageNumber		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumPageNameGraphics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all the graphic runs within a give text range.

CALLED BY:	INTERNAL
PASS:		*ds:si - article
		dx:ax - start pos
		cx:bx - end pos
		di - offset of callback routine in this segment
		bp - data

		Passed to callback:
			ds:si - TextRunArrayElement
			bx - page name token
			bp - data
			es - segment of graphic element array

		Return: carry set to stop enumerating, clear to continue
		Can destroy: ax,bx,cx,dx,si,di,ds,es

RETURN:		carry set if callback set it to stop enumeration
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/15/94		Initial version
	jenny	9/ 1/94    	Now returns carry set if callback set it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumPageNameGraphics		proc	far
		uses	ax,bx,cx,dx,bp,si,ds,es
passedBP	local	word 	push	bp
rangeEnd	local	dword 	push	cx, bx	
callback	local	nptr 	push	di
		.enter

		call	GetFileHandle		;bx = file

		call	LockGraphicRunArray	;ds:si = first element
		jnc  	exit			;cx = # consecutive elements
						;di = elt array VM blk han 
		call	LockGraphicElementArray	;es = segment of element array

topLoop:
		jcxz	doneClearCarry		;no more elements?

	; check if this graphic element is past the end of the range
		
		mov	bx, ss:rangeEnd.high
		cmp	bl, ds:[si].TRAE_position.WAAH_high
		jne	10$
		mov	bx, ss:rangeEnd.low
		cmp	bx, ds:[si].TRAE_position.WAAH_low
10$:
		jbe	doneClearCarry

	; see if this element comes after the start of the range
		
		cmp	dl, ds:[si].TRAE_position.WAAH_high
		jnz	20$
		cmp	ax, ds:[si].TRAE_position.WAAH_low
20$:
		ja 	continue
		
		mov	bx, ds:[si].TRAE_token
		call	IsGraphicAPageNameGraphic	;bx <- name token
		jc	continue
		mov	di, ss:[callback]
		push	ax, cx, dx, bp, si, ds, es
		mov	bp, ss:[passedBP]
		call	di				;call the callback
		pop	ax, cx, dx, bp, si, ds, es
		jc	done				;abort enum?
continue:
		add	si, size TextRunArrayElement
		loop	topLoop

		xchg	ax, cx			;huge array code uses ax
		push	dx
		sub	si, size TextRunArrayElement
		call	HugeArrayNext			;for count
		pop	dx
		xchg	ax, cx
		jmp	topLoop

doneClearCarry:
		clc
done:
		call	HugeArrayUnlock
		call	VMUnlockES
exit:
		.leave
		ret
EnumPageNameGraphics		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsGraphicAPageNameGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether the graphic element defines a page name

CALLED BY:	GetCurrentPageNameToken
PASS:		bx - element token
		es - segment of graphic element array
RETURN:		carry set if not a page name graphic
		carry clear if graphic defines a page name,
			bx - name token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsGraphicAPageNameGraphic		proc	far
		uses	ax, ds, si, di
		.enter	

		cmp	bx, CA_NULL_ELEMENT
		je	noGood
		
		segmov	ds, es, ax
		mov	si, VM_ELEMENT_ARRAY_CHUNK
		mov	ax, bx
		call	ChunkArrayElementToPtr	; ds:di - graphic

		cmp	ds:[di].VTG_type, VTGT_VARIABLE
		jne	noGood
		cmp	ds:[di].VTG_data.VTGD_variable.VTGV_type,
			VTVT_CONTEXT_NAME
		jne	noGood
		mov	bx,
		{word}ds:[di].VTG_data.VTGD_variable.VTGV_privateData[2]
		clc
		jmp	done
noGood:
		stc
done:		
		.leave
		ret
IsGraphicAPageNameGraphic		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockGraphicRunArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the graphic run array

CALLED BY:	
PASS:		*ds:si - article
		bx - file handle
RETURN:		carry clear if no graphic runs
		carry set if graphic runs
			ds:si - first element
			cx - # consecutive elements
			di - VM Block handle of element array
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockGraphicRunArray		proc	near
		uses	ax, dx, bp
		.enter	

		push	bx
		mov	ax, ATTR_VIS_TEXT_GRAPHIC_RUNS		
		call	ObjVarFindData
		mov	di, {word}ds:[bx]	;di = VM Block handle
		pop	bx
		jnc	done

		mov	ax, di
		call	VMLock		
		mov	ds, ax			; ds -> TextLargeRunArrayHeader
		push	ds:[TLRAH_elementVMBlock]	; save handle
		call	VMUnlock		; release block
		
		clr	ax, dx			;start with element #0
		call	HugeArrayLock		;ds:si = element #0
EC <		tst	ax						>
EC <		ERROR_Z	-1						>
		mov	cx, ax			;cx = # consecutive
		pop	di			;get element array handle
		stc
done:
		.leave
		ret
LockGraphicRunArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockGraphicElementArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the graphic element array

CALLED BY:	GetCurrentPageNameToken
PASS:		ds - segment of graphic run array
		^vbx:di - element array
RETURN:		es - segment of graphic element arrray

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockGraphicElementArray		proc	near 	
		push	ax, bp
		mov	ax, di
		call	VMLock
		mov	es, ax
		pop	ax, bp
		ret
LockGraphicElementArray		endp

;---

GetFileHandle	proc	near
		push	ax
		mov	bx, ds:[LMBH_handle]	;ds = article segment
		mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
		call	MemGetInfo
		mov	bx, ax			;bx = file handle
		pop	ax
		ret
GetFileHandle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleSetHyperlinkTextStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the document to remember the new ShowAllHyperlinks
		setting.

CALLED BY:	MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE
PASS:		*ds:si	= StudioArticleClass object
		ds:di	= StudioArticleClass instance data
		ds:bx	= StudioArticleClass object (same as *ds:si)
		es 	= segment of StudioArticleClass
		ax	= message #

		ss:bp - VisTextSetTextStyleParams

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

SIDE EFFECTS:	
	Sets MBH_miscFlags in the document MapBlockHeader

PSEUDO CODE/STRATEGY:
	This code is dependent on the VTES_BOXED style being used 
	to show hyperlinks. 
	
	We also do some checking that depends on the VTSTSP_range 
	being set from 0 to TEXT_ADDRESS_PAST_END 
	by the ShowHyperlinks code in the hyperlink controller.
	We do the checking because this message also gets sent out
	by VisTextSetHyperlink in the text library and in that case we 
	don't want to waste time notifying the document of the 
	ShowAllHyperlinks setting. The ShowAllHyperlinks setting 
	will only change when the hyperlink controller sends us 
	the message.

	Also we ignore undo actions associated with changing the
	hyperlink text style. This serves two purposes: it keeps the
	handle table from filling up with excessive undo actions,
	and it avoids problems with clipboard paste and 
	quick move/copy where the user Undo'es the action, changes
	the ShowAllHyperlinks setting, and then Redo'es the action.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/ 8/94   	Initial version
	cassie	 3/13/95   	ignore undo actions instead of
				 flushing the undo chain

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleSetHyperlinkTextStyle	method dynamic StudioArticleClass, 
					MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE
	;
	; Check if we're being called by HyperlinkController, and
	; if so, update the document state.
	;
	cmpdw	ss:[bp].VTSTSP_range.VTR_start, 0
	jne	callSuper
	cmpdw	ss:[bp].VTSTSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	jne	callSuper

	;
	; Update the document's MSDF_SHOW_HYPERLINKS flag.
	;
	; Assume we're going to show the hyperlinks; then check if
	; that's true.
	;
	mov	cx, mask MSDF_SHOW_HYPERLINKS
	clr	dx
	test	ss:[bp].VTSTSP_extendedBitsToSet, mask VTES_BOXED
	jnz	showHyperlinks
	xchg	cx, dx				; unset MSDF_SHOW_HYPERLINKS
showHyperlinks:
	mov	ax, MSG_STUDIO_DOCUMENT_SET_MISC_FLAGS
	call	VisCallParent		

callSuper:
	;
	; Suspend the text object so the Undo moniker does not change twice
	;	
	call	MarkBusy
	call	IgnoreUndoNoFlush
	call	SuspendObject
	;
	; Call super to change the hyperlink text style.
	;	
	mov	ax, MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE
	mov	di, offset StudioArticleClass
	call	ObjCallSuperNoLock

	call	UnsuspendObject
	call	AcceptUndo
	call	MarkNotBusy
	ret
StudioArticleSetHyperlinkTextStyle	endm

DocNotify ends


DocMiscFeatures segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleDescribeAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for indeterminate style and set global flag.

CALLED BY:	MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS
PASS:		*ds:si	= StudioArticleClass object
		ds:di	= StudioArticleClass instance data
		ds:bx	= StudioArticleClass object (same as *ds:si)
		es 	= segment of StudioArticleClass
		ax	= message #

		ss:bp	- SSCDescribeAttrsParams

RETURN:		nothing
DESTROYED:	ax
	bx, si, di, ds, es (method handler)

SIDE EFFECTS:	
	Modifies the global variable styleIndeterminate.

PSEUDO CODE/STRATEGY:
	For the reason that we intercept this message, see strategy 
	of StudioArticleDefineStyle.

	Pseudo code for this method:
	- Call super to describe the attrs and fill in the 
	  SSCDAP_textObject.
	- Check if we are using a new styles library since we assume
	  the new styles library will have the bug (that we are avoiding)
	  fixed.
	- Get the description string from the SSCDAP_textObject.
	- Get a pointer to our StringUsedForTestingForIndeterminateStyle.
	- Compare the two strings up to the length of out StringUsedForTest...
	- Store the result in a global variable.

	NOTE: styleIndeterminate must be initialized to BB_FALSE since it
	      will never get set if we have a new styles library.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleDescribeAttrs	method dynamic StudioArticleClass, 
					MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS
		uses	cx, dx, bp
		.enter
	;
	; Call super to describe the attrs.
	;
		push	bp
		mov	di, offset StudioArticleClass
		call	ObjCallSuperNoLock
		pop	bp
	;	
	; Check the version of the style library.
	;
		call	CheckStylesLibraryProtocol ; carry set if old version
		jnc	done			   ; no need to check
	;
	; Check if the style is indeterminate.
	; We cheat here by looking at the description that the superclass
	; put into the describeTextObject.
	;

	; Grab the description string from the describeTextObject.

		mov	ax, MSG_VIS_TEXT_GET_ALL_OPTR
		movdw	bxsi, ss:[bp].SSCDAP_textObject
		GetResourceHandleNS	BufferStringForTestingForIndeterminateStyle, dx
		mov	bp, offset BufferStringForTestingForIndeterminateStyle
		mov	di, mask MF_CALL
		call	ObjMessage		; trash ds
				; cx <- chunk handle w/ null terminated text
		mov	bx, dx
		push	bx			; save handle to unlock later
		call	MemLock			; lock resource #1
		mov	ds, ax
		mov	si, cx
		mov	si, ds:[si]		; ds:si <- description string

	; Grab the StringUsedForTestingForIndeterminateStyle string.

		GetResourceHandleNS	StringUsedForTestingForIndeterminateStyle, bx
		call	MemLock			; lock resource #2
		mov	es, ax
		mov	di, offset StringUsedForTestingForIndeterminateStyle
		mov	di, es:[di]		; es:di <- testing string

	; Compare the two strings up to the length of the testing string.

		call	LocalStringLength
			; cx <- # of chars in StringUsedForTesting...
		call	LocalCmpStrings
		call	MemUnlock		; unlock resource #2
		
		pop	bx
		call	MemUnlock		; unlock resource #1

		jnz	notIndeterminate
		mov	ch, BB_TRUE
		jmp	short storeResult
notIndeterminate:
		mov	ch, BB_FALSE
storeResult:
	;
	; Store the result in the global variable styleIndeterminate.
	;
		call	StudioGetDGroupES
		mov	es:[styleIndeterminate], ch
done:
		.leave
		ret
StudioArticleDescribeAttrs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckStylesLibraryProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find out whether styles library has the 'defining
		an indeterminate style' bug fixed or not.

CALLED BY:	(INTERNAL) StudioArticleDescribeAttrs
PASS:		nothing
RETURN:		carry set if styles library is old and doesn't
		have the 'defining an indeterminate style' bug fixed.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckStylesLibraryProtocol		proc	near
		uses	ax,bx,di,es
		.enter

		sub	sp, size ReleaseNumber
		mov	di, sp
		segmov	es, ss, ax
		mov	bx, handle styles
		mov	ax, GGIT_GEODE_RELEASE
		call	GeodeGetInfo
	;
	; Anything below 2.1 will be treated specially
	;
		cmp	ss:[di].RN_major, 2		;carry set if < 2
		jc	done
		cmp	ss:[di].RN_minor, 1		;carry set if < 1
done:
		lahf
		add	sp, size ReleaseNumber
		sahf

		.leave
		ret
CheckStylesLibraryProtocol		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioArticleDefineStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for indeterminate style and for the Boxed char 
		attribute.

CALLED BY:	MSG_META_STYLED_OBJECT_DEFINE_STYLE
		MSG_META_STYLED_OBJECT_REDEFINE_STYLE
PASS:		*ds:si	= StudioArticleClass object
		ds:di	= StudioArticleClass instance data
		ds:bx	= StudioArticleClass object (same as *ds:si)
		es 	= segment of StudioArticleClass
		ax	= message #

		ss:bp - SSCDefineStyleParams

RETURN:		nothing	
DESTROYED:	
	bx, si, di, ds, es (method handler)

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	The 2.01 version of the Styles library has a bug where it does
	not disable the DefineNewStyle trigger when there is an 
	Indeterminate style selected. We don't want to ship a new
	version of the Style library so we need to check if the style is
	Indeterminate and report an error to the user.

	We just have to check the global variable styleIndeterminate that
	was set when MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS was intercepted.

	We also want to reserve the Boxed char attribute for showing 
	hyperlinks so we need to check if the user is trying to define
	or redefine a style with the Boxed char attr and tell them that
	they can not.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioArticleDefineStyle	method dynamic StudioArticleClass, 
					MSG_META_STYLED_OBJECT_DEFINE_STYLE,
					MSG_META_STYLED_OBJECT_REDEFINE_STYLE
	uses	ax, cx, dx, bp
passedBP	local	word	push	bp
getParams	local	VisTextGetAttrParams
charAttr	local	VisTextCharAttr
charDiffs	local	VisTextCharAttrDiffs

ForceRef	getParams
ForceRef	charAttr
ForceRef	charDiffs
	.enter
	;	
	; Check if the style is indeterminate.
	;
		call	StudioGetDGroupES
		cmp	es:[styleIndeterminate], BB_TRUE
		je	reportIndeterminateError
	;
	; Get the Character Attributes of the selected text
	; and check for the Boxed char attribute.
	;
		call	SA_GetCharAttr
		call	SA_CheckForBoxedCharAttr
		jc	done
	;
	; Call super to define the style.	
	;
		push	bp
		; ax is still the message
		mov	di, offset StudioArticleClass
		mov	bp, passedBP
		call	ObjCallSuperNoLock
		pop	bp
done:
		.leave
		ret

reportIndeterminateError:
		call	SA_ReportIndeterminateStyleError
		jmp	short done

StudioArticleDefineStyle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SA_GetCharAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the char attrs of the current selected area

CALLED BY:	(INTERNAL) StudioArticleDefineStyle
PASS:		*ds:si - article
		inherited locals
RETURN:		charAttr and charDiffs filled in
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SA_GetCharAttr	proc	near
	uses	ax, dx
	.enter	inherit	StudioArticleDefineStyle

	lea	ax, charAttr
	movdw	getParams.VTGAP_attr, ssax
	lea	ax, charDiffs
	movdw	getParams.VTGAP_return, ssax

	mov	ax, MSG_VIS_TEXT_GET_CHAR_ATTR
	clr	getParams.VTGAP_flags
	mov	getParams.VTGAP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION

	push	bp
	lea	bp, getParams
	mov	dx, (size getParams)
	call	ObjCallInstanceNoLock
	pop	bp

	.leave
	ret
SA_GetCharAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SA_ReportIndeterminateStyleError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show indeterminate style error message to user

CALLED BY:	(INTERNAL) StudioArticleDefineStyle
PASS:		*ds:si	- article
RETURN:		nothing
DESTROYED:	ax, bx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SA_ReportIndeterminateStyleError	proc	near

	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	bx, offset ErrorCanNotDefineInteterminateStyle
	call	PutupHelpBox

	ret
SA_ReportIndeterminateStyleError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SA_CheckForBoxedCharAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report an error if the Boxed char attr is set

CALLED BY:	(INTERNAL) StudioArticleDefineStyle
PASS:		*ds:si - article
		inherited locals
RETURN:		carry set if VTES_BOXED char atts set
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SA_CheckForBoxedCharAttr	proc	near
	uses	ax, bx
	.enter	inherit	StudioArticleDefineStyle
	;
	; Test the charAttr for the BOXED char attr
	;
	test	charAttr.VTCA_extendedStyles, mask VTES_BOXED
	jnz	reportError

	clc			; carry clear <- no Boxed char attr
done:	
	.leave
	ret

reportError:
	;
	; Display error and return carry set
	;
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	bx, offset ErrorCanNotDefineStyleWithBoxedCharAttr
	call	PutupHelpBox

	stc			; carry set <- indeterminate style
	jmp	short done

SA_CheckForBoxedCharAttr	endp

DocMiscFeatures	ends
