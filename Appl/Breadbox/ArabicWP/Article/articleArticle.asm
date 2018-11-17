COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		articleArticle.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for WriteArticleClass.

	$Id: articleArticle.asm,v 1.1 97/04/04 15:57:14 newdeal Exp $

------------------------------------------------------------------------------@

GeoWriteClassStructures	segment	resource
	WriteArticleClass
GeoWriteClassStructures	ends

DocNotify segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteArticleCurrentRegionChanged --
		MSG_VIS_LARGE_TEXT_CURRENT_REGION_CHANGED for WriteArticleClass

DESCRIPTION:	Generate additional notifications for the article

PASS:
	*ds:si - instance data
	es - segment of WriteArticleClass

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
WriteArticleCurrentRegionChanged	method dynamic	WriteArticleClass,
				MSG_VIS_LARGE_TEXT_CURRENT_REGION_CHANGED

	call	GetRegionPos

	mov	ax, MSG_WRITE_DOCUMENT_SET_POSITION_ABS
	call	VisCallParent

	ret

WriteArticleCurrentRegionChanged	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetRegionPos

DESCRIPTION:	Get the position of a region

CALLED BY:	INTERNAL

PASS:
	*ds:si - WriteArticle
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

DocNotify ends

DocPageCreDest segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteArticleRegionIsLast -- MSG_VIS_LARGE_TEXT_REGION_IS_LAST
							for WriteArticleClass

DESCRIPTION:	Handle notification that a region is the last region

PASS:
	*ds:si - instance data
	es - segment of WriteArticleClass

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
WriteArticleRegionIsLast	method dynamic	WriteArticleClass,
					MSG_VIS_LARGE_TEXT_REGION_IS_LAST

	; in draft mode we want to bail completely and not delete regions

	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITH_STYLES
	jae	done

	mov	di, MSG_WRITE_DOCUMENT_DELETE_PAGES_AFTER_POSITION
	GOTO	AppendDeleteCommon
done:
	ret

WriteArticleRegionIsLast	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteArticleAppendRegion -- MSG_VIS_LARGE_TEXT_APPEND_REGION
							for WriteArticleClass

DESCRIPTION:	Add another region to an article

PASS:
	*ds:si - instance data
	es - segment of WriteArticleClass

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
WriteArticleAppendRegion	method dynamic	WriteArticleClass,
						MSG_VIS_LARGE_TEXT_APPEND_REGION

	mov	di, MSG_WRITE_DOCUMENT_APPEND_PAGES_VIA_POSITION
	FALL_THRU	AppendDeleteCommon

WriteArticleAppendRegion	endm

;---

	; di = message

AppendDeleteCommon	proc	far
	class	WriteArticleClass

	; first we suspend ourself (so that the suspend/unsuspend from
	; inserting regions has no ill effects)

	push	cx
	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock
	pop	cx				;cx = region #

	; now we add pages

	call	GetRegionPos			;cx = x, dxbp = y

	mov_tr	ax, di
	call	VisCallParent

if _REGION_LIMIT
	jc	done
endif		
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

if _REGION_LIMIT
done:
endif		
	ret

AppendDeleteCommon	endp

DocPageCreDest ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteArticleSubstAttrToken -- MSG_VIS_TEXT_SUBST_ATTR_TOKEN
							for WriteArticleClass

DESCRIPTION:	Substitute a text attribute token

PASS:
	*ds:si - instance data
	es - segment of WriteArticleClass

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
WriteArticleSubstAttrToken	method dynamic	WriteArticleClass,
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
	mov	di, offset WriteArticleClass
	GOTO	ObjCallSuperNoLock

WriteArticleSubstAttrToken	endm

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

MESSAGE:	WriteArticleRecalcForAttrChange --
		MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE for WriteArticleClass

DESCRIPTION:	Recalculate for an attribute change

PASS:
	*ds:si - instance data
	es - segment of WriteArticleClass

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
WriteArticleRecalcForAttrChange	method dynamic	WriteArticleClass,
					MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE

	tst	cx
	jnz	toSuper

	; send to attribute manager to take care of

	mov	ax, MSG_GOAM_RECALC_FOR_TEXT_ATTR_CHANGE
	mov	di, mask MF_RECORD
	call	ToAttrMgrCommon
	ret

toSuper:
	mov	di, offset WriteArticleClass
	GOTO	ObjCallSuperNoLock

WriteArticleRecalcForAttrChange	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteArticleGetObjectForSearchSpell --
		MSG_META_GET_OBJECT_FOR_SEARCH_SPELL for WriteArticleClass

DESCRIPTION:	Get the next object for search/spell

PASS:
	*ds:si - instance data
	es - segment of WriteArticleClass

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
WriteArticleGetObjectForSearchSpell	method dynamic	WriteArticleClass,
					MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
	call	VisCallParent
	ret

WriteArticleGetObjectForSearchSpell	endm

DocSTUFF ends

DocMiscFeatures segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteArticleSetVisParent -- MSG_WRITE_ARTICLE_SET_VIS_PARENT
						for WriteArticleClass

DESCRIPTION:	Set the vis parent for an article

PASS:
	*ds:si - instance data
	es - segment of WriteArticleClass

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
WriteArticleSetVisParent	method dynamic	WriteArticleClass,
					MSG_WRITE_ARTICLE_SET_VIS_PARENT

	ornf	dx, LP_IS_PARENT
	movdw	ds:[di].VI_link.LP_next, cxdx
	ret

WriteArticleSetVisParent	endm

DocMiscFeatures ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteArticleDisplayObjectForSearchSpell --
		MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL for WriteArticleClass

DESCRIPTION:	Display the object

PASS:
	*ds:si - instance data
	es - segment of WriteArticleClass

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
WriteArticleDisplayObjectForSearchSpell	method dynamic	WriteArticleClass,
					MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL

	call	MakeContentEditable
	ret

WriteArticleDisplayObjectForSearchSpell	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteArticleCrossSectionReplaceAborted --
		MSG_VIS_TEXT_CROSS_SECTION_REPLACE_ABORTED for WriteArticleClass

DESCRIPTION:	Notification that a cross section change has been aborted

PASS:
	*ds:si - instance data
	es - segment of WriteArticleClass

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
WriteArticleCrossSectionReplaceAborted	method dynamic	WriteArticleClass,
				MSG_VIS_TEXT_CROSS_SECTION_REPLACE_ABORTED

	mov	ax, offset CrossSectionReplaceAbortedString
	call	DisplayError
	ret

WriteArticleCrossSectionReplaceAborted	endm

;
; only select text in current section
;

ifdef GPC

WriteArticleSelectAll	method	dynamic	WriteArticleClass,
				MSG_META_SELECT_ALL, MSG_VIS_TEXT_SELECT_ALL
		selAll		local	VisTextRange
		regStart	local	dword
		regEnd		local	dword
		curSelStart	local	dword
		selAllSection	local	word
		.enter
		movdw	bxax, ds:[di].VTI_selectStart
		movdw	curSelStart, bxax
		clrdw	bxax
		movdw	selAll.VTR_start, bxax
		movdw	selAll.VTR_end, bxax
		movdw	regStart, bxax
		movdw	regEnd, bxax
		mov	selAllSection, ax
		push	si
		mov	si, ds:[di].VLTI_regionArray
		call	ChunkArrayGetCount
findStartLoop:
		call	ChunkArrayElementToPtr
		LONG jc	gotSelection
		adddw	regEnd, ds:[di].VLTRAE_charCount, bx
	; if new section, start selectAll here
		mov	bx, ds:[di].VLTRAE_section
		cmp	bx, selAllSection
		je	gotSection
		mov	selAllSection, bx
		movdw	selAll.VTR_start, regStart, bx
gotSection:
	; if selection is in this region, found start
		cmpdw	curSelStart, regEnd, bx
		jb	findEndLoop
		adddw	regStart, ds:[di].VLTRAE_charCount, bx
		inc	ax
		loop	findStartLoop

findEndLoop:
	; find all matching sections
		mov	bx, ds:[di].VLTRAE_section
		cmp	selAllSection, bx
		jne	gotSelection
	; same section as selection, selectAll to end of this region
		movdw	selAll.VTR_end, regEnd, bx
	; some hacks for last region
		cmp	cx, 1			; last region, select all
		jbe	gotEnd
		tstdw	selAll.VTR_end
		jz	gotEnd
		decdw	selAll.VTR_end		; otherwise don't include
						; region break
gotEnd:
		jcxz	gotSelection
		dec	cx
		jcxz	gotSelection		; stop at end
		inc	ax
		call	ChunkArrayElementToPtr
		jc	gotSelection		; erm...stop at end
		movdw	regStart, regEnd, bx
		adddw	regEnd, ds:[di].VLTRAE_charCount, bx
		jmp	short findEndLoop

gotSelection:
		pop	si
		push	bp
		lea	bp, selAll
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE
		call	ObjCallInstanceNoLock
		pop	bp
		.leave
		ret
WriteArticleSelectAll	endm

endif

DocSTUFF ends
