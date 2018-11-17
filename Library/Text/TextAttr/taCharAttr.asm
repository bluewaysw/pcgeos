COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Text
FILE:		textMethodCharAttr.asm

METHODS:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:
	This file contains method handlers for charAttr methods

	$Id: taCharAttr.asm,v 1.1 97/04/07 11:18:51 newdeal Exp $

------------------------------------------------------------------------------@

TextAttributes segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextSetCharAttrByDefault --
		    MSG_VIS_TEXT_SET_CHAR_ATTR_BY_DEFAULT for VisTextClass

DESCRIPTION:	Set the entire charAttr structure for the selected area to a
		default value.  If the object does not have multiple charAttrs,
		set the charAttr for the entire object.

PASS:
	*ds:si - instance data (VisTextInstance)
	ss:bp - VisTextSetCharAttrByDefaultParams

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

SetCharAttrFrame	struct
    SCAF_range		VisTextRange
    SCAF_charAttr	VisTextCharAttr
SetCharAttrFrame	ends

VisTextSetCharAttrByDefault	proc	far
				; MSG_VIS_TEXT_SET_CHAR_ATTR_BY_DEFAULT
	class	VisTextClass

	push	bp
	mov	ax, ss:[bp].VTSCABDP_charAttr

	; allocate a temporary structure

	sub	sp, size SetCharAttrFrame
	segmov	es, ss, cx		;stack segment is also in cx
	mov	di, sp			;es:di = dest

	push	si, ds
	mov	ds, cx
	mov	si, bp			;ds:si = source
	mov	cx, (size VisTextRange)/2
	rep movsw
	pop	si, ds

	; get default into structure, set up frame

	lea	bp, ss:[di-(size VisTextRange)].SCAF_charAttr
	call	TextMapDefaultCharAttr
	sub	bp, offset SCAF_charAttr

	call	SetCharAttrCommon

	add	sp, size SetCharAttrFrame
	pop	bp
	ret

VisTextSetCharAttrByDefault	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextSetCharAttrByToken --
		    MSG_VIS_TEXT_SET_CHAR_ATTR_BY_TOKEN for VisTextClass

DESCRIPTION:	Set the entire charAttr structure for the selected area to a
		given token.

PASS:
	*ds:si - instance data (VisTextInstance)
	ss:bp - VisTextSetCharAttrByTokenParams

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
VisTextSetCharAttrByToken	proc	far
				; MSG_VIS_TEXT_SET_CHAR_ATTR_BY_TOKEN
	class	VisTextClass

	; unhilite and get the range of the selected area

	call	UnHiliteAndFixupCharAttrRange
	push	bx						;save vm file

	push	ax
	mov	ax, offset StyleString
	call	TU_StartChainIfUndoable
	pop	ax

	mov	ax, ss:[bp].VTSCABTP_charAttr
	mov	bx, offset VTI_charAttrRuns
	clr	cx
EC <	call	ECCheckRun						>
	call	ModifyRun
EC <	call	ECCheckRun						>
	call	UpdateLastRunPositionByRunOffset

	call	TU_EndChainIfUndoable
	; reflect the change

	pop	bx
	call	ReflectChangeUpdateGeneric
	ret

VisTextSetCharAttrByToken	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextSetCharAttr -- MSG_VIS_TEXT_SET_CHAR_ATTR for VisTextClass

DESCRIPTION:	Set the entire charAttr structure for the selected area.  If the
		object does not have multiple charAttrs, set the charAttr for the
		entire object.

PASS:
	*ds:si - instance data (VisTextInstance)
	ss:bp - VisTextSetCharAttrParams structure

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

VisTextSetCharAttr		proc	far	; MSG_VIS_TEXT_SET_CHAR_ATTR
	class	VisTextClass

if ERROR_CHECK
	;
	; Validate that the char attr is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	movdw	bxsi, ss:[bp].VTSCAP_charAttr				>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	; copy charAttr onto the stack

	push	bp
	sub	sp, size SetCharAttrFrame
	segmov	es, ss
	mov	di, sp

	push	si, ds
	segmov	ds, ss
	mov	si, bp
	mov	cx, (size VisTextRange) / 2
	rep movsw				;copy range
	lds	si, ss:[bp].VTSCAP_charAttr
	mov	cx, (size VisTextCharAttr) / 2
	rep movsw
	pop	si, ds
	mov	bp, sp

	call	SetCharAttrCommon

	add	sp, size SetCharAttrFrame
	pop	bp
	ret

VisTextSetCharAttr	endp

;---

SetCharAttrCommon	proc	near
	class	VisTextClass

	; unhilite and get the range of the selected area

	call	UnHiliteAndFixupCharAttrRange
	push	bx						;save vm file

EC <	add	bp, offset SCAF_charAttr				>
EC <	call	ECCheckCharAttr						>
EC <	sub	bp, offset SCAF_charAttr				>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS
	jnz	multiple

	; Single charAttr -- set it

	add	bp, offset SCAF_charAttr
	call	SetSingleCharAttr
	sub	bp, offset SCAF_charAttr
	jmp	done

	; Multiple charAttrs -- add the charAttr

multiple:
	mov	bx, offset VTI_charAttrRuns
	call	SetCharAttrOrParaAttrMultiple

	; reflect the change

done:
	pop	bx
	call	ReflectChangeUpdateGeneric
	ret

SetCharAttrCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetCharAttrOrParaAttrMultiple

DESCRIPTION:	Set an entire charAttr or paraAttr structure for a text object with
		multiple charAttrs or paraAttrs

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset of run
	ss:bp - VisTextSetCharAttrParams

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
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
SetCharAttrOrParaAttrMultiple	proc	near
	class	VisTextClass
	push	bx
	add	bp, offset VTSCAP_charAttr
	mov	ax, offset AddElement
	call	LockAndCall			;bx = token
	sub	bp, offset VTSCAP_charAttr
	mov_tr	ax, bx
	pop	bx

	; Set up an undo chain for this change, with a title appropriate for
	; the type of change we are performing

	push	ax
	mov	ax, offset FormattingString
	cmp	bx, VTI_paraAttrRuns
	jz	isParaAttrChange
	mov	ax, offset StyleString
isParaAttrChange:
	call	TU_StartChainIfUndoable
	pop	ax

	; modify the charAttr run -- pass 0 as the adjust vector, meaning that
	; we want to replace the token for the selected area with this token

	push	ax				;save token
	clr	cx
EC <	call	ECCheckRun						>
	call	ModifyRun			;dxax = last run position
EC <	call	ECCheckRun						>
	call	UpdateLastRunPositionByRunOffset
	pop	ax				;recover token

	call	TU_EndChainIfUndoable
	; remove the reference we made to the new charAttr

	mov_tr	cx, ax				;cx = element
	mov	ax, offset RemoveElement
	call	LockAndCall

	ret

SetCharAttrOrParaAttrMultiple	endp

;---

	; ax = offset of routine (must be a FAR routine)
	; bx = offset to run
	; cx = value to pass in bx

LockAndCall	proc	near	uses si
	.enter
	;
	; Since the block may move if we are adding runs to the
	; same block that contains the text object, we need to
	; update the segment in ds before returning.
	;
	push	ds:LMBH_handle			;save the handle

	push	ax, cx
	call	RunArrayLock
	pop	ax, bx
	push	cs				;destination is FAR
	call	ax
	call	RunArrayUnlock

	pop	si				;si <- block handle
	xchg	bx, si				;save bx in si
						;bx <- block handle
	call	MemDerefDS			;restore block segment
	mov	bx, si				;restore bx
						;si restored by .leave
	.leave
	ret

LockAndCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetSingleCharAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the character attributes at a given offset,
		taking into account the VisLargeTextDisplayModes.

CALLED BY:	MSG_VIS_TEXT_GET_SINGLE_CHAR_ATTR
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - ptr to VisTextCharAttr

RETURN:		buffer - filled
		dx:ax - # of consecutive chars

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetSingleCharAttr	proc	far ;MSG_VIS_TEXT_GET_SINGLE_CHAR_ATTR
	mov	ax, cx				;dx:ax <- position
	mov	cl, GSFPT_INSERTION		;cl <- GetCharAttrForPosTypes
	call	TA_GetCharAttrForPosition
	ret
VisTextGetSingleCharAttr		endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextGetCharAttr -- MSG_VIS_TEXT_GET_CHAR_ATTR for VisTextClass

DESCRIPTION:	Return the charAttr structure for the selected area.

PASS:
	*ds:si - instance data (VisTextInstance)

	dx - size VisTextGetAttrParams (if called remotely)
	ss:bp - VisTextGetAttrParams structure

RETURN:
	ax - charAttr token (CA_NULL_ELEMENT if multiple)
	buffer - filled

DESTROYED:
	dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

VTGCA_Frame	struct
    VTGCA_element	VisTextCharAttr <>

	; the following fields are pushed on the stack

    VTGCA_passedFrame	nptr

VTGCA_Frame	ends

VisTextGetCharAttr	proc	far	; MSG_VIS_TEXT_GET_CHAR_ATTR
	class	VisTextClass

if ERROR_CHECK
	;
	; Validate that the char attr is *not* in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	movdw	bxsi, ss:[bp].VTGAP_attr				>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	push	si, ds

	; zero out return values

	test	ss:[bp].VTGAP_flags, mask VTGAF_MERGE_WITH_PASSED
	jnz	skipZero
	les	di, ss:[bp].VTGAP_return
	clr	ax
	stosw
	stosw
	stosw
skipZero:

	; allocate stack space and save vars

	movdw	dxax, ss:[bp].VTGAP_range.VTR_start
	mov	di, bp

	push	bp				;passed frame
	sub	sp, (size VTGCA_Frame)-2
	mov	bp, sp

	; if we are to merge with the passed attributes then copy the passed
	; structure in

	test	ss:[di].VTGAP_flags, mask VTGAF_MERGE_WITH_PASSED
	jz	skipCopy
	push	si, di, ds, es
	lds	si, ss:[di].VTGAP_attr		;ds:si = source
	segmov	es, ss
	mov	di, bp				;es:di = dest
	mov	cx, (size VisTextCharAttr) / 2
	rep	movsw
	pop	si, di, ds, es
skipCopy:

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS
	jnz	multiple

	; one charAttr -- get it

	; ss:bp = VTGCA_Frame, ss:di = VisTextGetAttrParams

	call	GetSingleCharAttr
	test	ss:[di].VTGAP_flags, mask VTGAF_MERGE_WITH_PASSED
	jnz	toOneRun
	jmp	done
toOneRun:
	jmp	oneRun
multiple:

	; ss:bp = VTGCA_Frame, ss:di = VisTextGetAttrParams

	xchg	bp, di				;ss:di = VTGCA_Frame
						;ss:bp = VisTextGetAttrParams
	call	FixupCharAttrRange
	clr	bx				;no context
	call	TA_GetTextRange

	; first fill the buffer with the first run

	push	si, ds
	movdw	dxax, ss:[bp].VTR_start
	cmpdw	dxax, ss:[bp].VTR_end		;if area selected then
	xchg	bp, di				;ss:bp = VTGCA_Frame
						;ss:di = VisTextGetAttrParams
	mov	bx, offset VTI_charAttrRuns
	jnz	getRight			;don't use run to the left

	; no area selected -- check for insertion element

	call	GetInsertionElement
	cmp	bx, CA_NULL_ELEMENT
	jz	noInsertionElement

	; insertion element exists - return it

	push	bx
	mov	bx, offset VTI_charAttrRuns
	call	RunArrayLock
	pop	bx
	call	GetElement
	call	RunArrayUnlock
	pop	si, ds
	mov	di, ss:[bp].VTGCA_passedFrame
	mov_tr	ax, bx				;ax = token
	jmp	oneRun

noInsertionElement:
	mov	bx, offset VTI_charAttrRuns
	call	TSL_IsParagraphStart
	jc	getRight

	; if we're at the end of the text then use the attributes to the
	; right in case there is a run hanging out at the end

	movdw	cxdi, dxax			;save position
	call	TS_GetTextSize
	cmpdw	dxax, cxdi
	movdw	dxax, cxdi
	jz	getRight

	call	GetRunForPositionLeft		;returns cx = token
	jmp	common
getRight:
	call	GetRunForPosition		;returns cx = token
common:
	call	GetElement

	; if (selectionEnd >= run.end) {
	;	selection in one run, return token
	; } else {
	;	selection in more than one run, return 0
	; }

	push	bx
	call	RunArrayNext		;dxax = next run position
	pop	bx
	call	RunArrayUnlock

	pop	si, ds
	mov	di, ss:[bp].VTGCA_passedFrame
	cmpdw	dxax, ss:[di].VTR_end
	mov_tr	ax, bx				;ax = token
	jae	oneRun

	; use enumeration function to scan all runs

	mov	dx, offset GetCharAttrCallback
	xchg	di, bp				;ss:di = frame, ss:bp = range
	mov	bx, offset VTI_charAttrRuns
	call	EnumRunsInRange
	xchg	di, bp
	mov	ax, CA_NULL_ELEMENT		;return multiple tokens
	jmp	done

oneRun:
	test	ss:[di].VTGAP_flags, mask VTGAF_MERGE_WITH_PASSED
	jz	done

	; diff this single structure with the passed structure

	push	di
	movdw	dxbx, ss:[di].VTGAP_return	;dx:bx=VisTextCharAttrDiffs
	lds	si, ss:[di].VTGAP_attr		;dssi = passed
	segmov	es, ss
	mov	di, bp				;es:di = single attr
	call	DiffCharAttr
	pop	di

done:

	; fill the destination buffer

	segmov	ds, ss				;ds:si = source
	mov	si, bp
	les	di, ss:[di].VTGAP_attr		;es:di = dest
	mov	cx, (size VisTextCharAttr)/2
	rep	movsw

	; recover local space

	add	sp, (size VTGCA_Frame)-2
	pop	bp

	pop	si, ds

	ret

VisTextGetCharAttr	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetCharAttrCallback

DESCRIPTION:	Mark the differences between the given charAttr and the base
		charAttr

CALLED BY:	INTERNAL -- Callback from EnumRunsInRange
				(from VisTextGetCharAttr)

PASS:
	ss:bp - element from run
	ss:di - VTGCA_Frame

RETURN:

DESTROYED:
	ax, bx, ds, si, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
GetCharAttrCallback	proc	near

	; load parameters and call the diff routine

	segmov	es, ss				;es:di = element #2
	segmov	ds, es
	mov	si, bp				;ds:si = element #1

	mov	bx, ss:[di].VTGCA_passedFrame	;ss:bx=VisTextGetCharAttrParams
	mov	dx, ss:[bx].VTGAP_return.segment
	mov	bx, ss:[bx].VTGAP_return.offset  ;dx:bx=VisTextCharAttrDiffs

	call	DiffCharAttr
	
	ret

GetCharAttrCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DiffCharAttr

DESCRIPTION:	Compute the difference between two character attribute
		structures

CALLED BY:	INTERNAL

PASS:
	ds:si - char attr #1
	es:di - char attr #2
	dx:bx - VisTextCharAttrDiffs to "or" results into

RETURN:
	dx:bx - structure updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91		Initial version

------------------------------------------------------------------------------@
DiffCharAttr	proc	far	uses	ax, cx
	.enter

	push	ds
	mov	ds, dx
	mov	cx, ds:[bx].VTCAD_diffs
	pop	ds

	; compare names

	mov	ax, ds:[si].VTCA_meta.SSEH_style
	cmp	ax, es:[di].VTCA_meta.SSEH_style
	jz	sameName
	ornf	cx, mask VTCAF_MULTIPLE_STYLES
sameName:

	; compare track kerning

	mov	ax, {word} ds:[si].VTCA_trackKerning
	cmp	ax, {word} es:[di].VTCA_trackKerning
	jz	sameTrackKerning
	ornf	cx, mask VTCAF_MULTIPLE_TRACK_KERNINGS
sameTrackKerning:

	; compare fonts

	mov	ax, ds:[si].VTCA_fontID
	cmp	ax, es:[di].VTCA_fontID
	jz	sameFont
	ornf	cx, mask VTCAF_MULTIPLE_FONT_IDS
sameFont:

	push	dx
	mov	ax, {word} ds:[si].VTCA_fontWeight
	mov	dx, {word} es:[di].VTCA_fontWeight
	cmp	al, dl
	jz	sameFontWeight
	ornf	cx, mask VTCAF_MULTIPLE_FONT_WEIGHTS
sameFontWeight:
	cmp	ah, dh
	jz	sameFontWidth
	ornf	cx, mask VTCAF_MULTIPLE_FONT_WIDTHS
sameFontWidth:
	pop	dx

	; compare point size

	mov	ax, ds:[si].VTCA_pointSize.WBF_int
	cmp	ax, es:[di].VTCA_pointSize.WBF_int
	jnz	diffSize
	mov	al, ds:[si].VTCA_pointSize.WBF_frac
	cmp	al, es:[di].VTCA_pointSize.WBF_frac
	jz	sameSize
diffSize:
	ornf	cx, mask VTCAF_MULTIPLE_POINT_SIZES
sameSize:

	; compare colors

	mov	ax, ds:[si].VTCA_color.low	;ah = info, al = redOrIndex
	cmp	ax, es:[di].VTCA_color.low
	jnz	diffColor
	mov	ax, ds:[si].VTCA_color.high
	cmp	ax, es:[di].VTCA_color.high
	jz	sameColor
diffColor:
	ornf	cx, mask VTCAF_MULTIPLE_COLORS
sameColor:

	; compare gray screens

	mov	al, ds:[si].VTCA_grayScreen
	cmp	al, es:[di].VTCA_grayScreen
	jz	sameGrayScreen
	ornf	cx,mask VTCAF_MULTIPLE_GRAY_SCREENS
sameGrayScreen:

	; compare hatches

	mov	ax, {word} ds:[si].VTCA_pattern
	cmp	ax, {word} es:[di].VTCA_pattern
	jz	samePattern
	ornf	cx,mask VTCAF_MULTIPLE_PATTERNS
samePattern:

	; compare bg colors

	mov	ax, ds:[si].VTCA_bgColor.low	;ah = info, al = redOrIndex
	cmp	ax, es:[di].VTCA_bgColor.low
	jnz	diffBGColor
	mov	ax, ds:[si].VTCA_bgColor.high
	cmp	ax, es:[di].VTCA_bgColor.high
	jz	sameBGColor
diffBGColor:
	ornf	cx, mask VTCAF_MULTIPLE_BG_COLORS
sameBGColor:

	; compare bg gray screens

	mov	al, ds:[si].VTCA_bgGrayScreen
	cmp	al, es:[di].VTCA_bgGrayScreen
	jz	sameBGGrayScreen
	ornf	cx,mask VTCAF_MULTIPLE_BG_GRAY_SCREENS
sameBGGrayScreen:

	; compare bg patterns

	mov	ax, {word} ds:[si].VTCA_bgPattern
	cmp	ax, {word} es:[di].VTCA_bgPattern
	jz	sameBGPattern
	ornf	cx,mask VTCAF_MULTIPLE_BG_PATTERNS
sameBGPattern:

	; compare text charAttrs

	mov	al, ds:[si].VTCA_textStyles
	xor	al, es:[di].VTCA_textStyles

	push	ds
	mov	ds, dx
	or	ds:[bx].VTCAD_textStyles, al
	mov	ds:[bx].VTCAD_diffs, cx
	pop	ds

	; compare extended charAttrs

	mov	ax, ds:[si].VTCA_extendedStyles
	xor	ax, es:[di].VTCA_extendedStyles
	push	ds
	mov	ds, dx
	or	ds:[bx].VTCAD_extendedStyles, ax
	pop	ds

	.leave
	ret

DiffCharAttr	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextCharAttrAdd -- MSG_VIS_TEXT_ADD[-1z_CHAR_ATTR for VisTextClass

DESCRIPTION:	Add a given charAttr to the charAttr array and initialize its
		reference count to one.

	*** Note: Calling this method on a text object that does not have
	***	  multiple charAttrs will result in a fatal error.

PASS:
	*ds:si - instance data (VisTextInstance)

	dx - size VisTextCharAttr (if called remotely)
	ss:bp - VisTextCharAttr

RETURN:
	ax - charAttr token

DESTROYED:
	dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

VisTextCharAttrAdd		proc	far	; MSG_VIS_TEXT_ADD_CHAR_ATTR
	class	VisTextClass

	mov	ax, offset AddElement
	FALL_THRU	AddRemoveCharAttrCommon

VisTextCharAttrAdd	endp

;---

AddRemoveCharAttrCommon	proc	far
	class	VisTextClass
	mov	bx, offset VTI_charAttrRuns
	call	LockAndCall			;ax = token
	ret
AddRemoveCharAttrCommon	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextCharAttrRemove -- MSG_VIS_TEXT_ADD_CHAR_ATTR for VisTextClass

DESCRIPTION:	Remove a given charAttr from the charAttr array.

	*** Note: Calling this method on a text object that does not have
	***	  multiple charAttrs will result in a fatal error.

PASS:
	*ds:si - instance data (VisTextInstance)

	cx - token to remove

RETURN:
	none

DESTROYED:
	dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

VisTextCharAttrRemove		proc	far	; MSG_VIS_TEXT_REMOVE_CHAR_ATTR
	class	VisTextClass

	mov	ax, offset RemoveElement
	GOTO	AddRemoveCharAttrCommon

VisTextCharAttrRemove	endp

;-----------------------------------------------------------------------------
;		Utility routines below here
;-----------------------------------------------------------------------------

COMMENT @----------------------------------------------------------------------

FUNCTION:	CharAttrChangeCommon

DESCRIPTION:	Do a change for a charAttr routine

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance data (VisTextInstance)
	ss:bp - VisTextRange
	ax, dx - callback data
	di - offset of callback

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
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
CharAttrChangeCommon	proc	far
	class	VisTextClass

	call	UnHiliteAndFixupCharAttrRange
	push	bx				;save vm file

	mov	cx, cs				;segment of callback

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS
	pop	di
	jnz	multiple

	call	DoSingleCharAttrChange
	clr	ax
	clrdw	ss:[bp].VTR_start, ax
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END
	jmp	done

	; Multiple charAttrs -- add the charAttr

multiple:

	; modify the charAttr run

	push	ax
	mov	ax, offset StyleString
	call	TU_StartChainIfUndoable
	pop	ax

	mov	bx, offset VTI_charAttrRuns
EC <	call	ECCheckRun						>
	call	ModifyRun
EC <	call	ECCheckRun						>
	call	UpdateLastRunPositionByRunOffset
	call	TU_EndChainIfUndoable
done:
	pop	bx
	call	ReflectChangeUpdateGeneric
	ret

CharAttrChangeCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UnHiliteAndFixupCharAttrRange

DESCRIPTION:	Given an instance, call EditUnHilite and return the selected
		range

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisTextInstance
	ss:bp - VisTextRange
	bx - VisTextRangeContext

RETURN:
	none

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

FixupCharAttrRange	proc	far
	class	VisTextClass
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS
	jnz	10$
	mov	ss:[bp].VTR_start.high, VIS_TEXT_RANGE_SELECTION
10$:
	ret

FixupCharAttrRange	endp

;---

UnHiliteAndFixupCharAttrRange	proc	far
	call	FixupCharAttrRange
	mov	bx, mask VTRC_CHAR_ATTR_CHANGE
	GOTO	UnHiliteCommon

UnHiliteAndFixupCharAttrRange	endp

;---

FixupParaAttrRange	proc	near
	class	VisTextClass
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VTI_storageFlags, mask VTSF_MULTIPLE_PARA_ATTRS
	jnz	10$
	mov	ss:[bp].VTR_start.high, VIS_TEXT_RANGE_SELECTION
10$:
	ret

FixupParaAttrRange	endp

;---

UnHiliteAndFixupParaAttrRange	proc	far
	call	FixupParaAttrRange
	mov	bx, mask VTRC_PARAGRAPH_CHANGE
	FALL_THRU	UnHiliteCommon

UnHiliteAndFixupParaAttrRange	endp

;---
UnHiliteCommon	proc	far
	call	TA_GetTextRange
	call	TextCheckCanCalcNoRange
	jc	noCreateGState
	call	TextGStateCreate
	call	EditUnHilite			;Prepare to change...
noCreateGState:
	ret

UnHiliteCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetSingleCharAttr

DESCRIPTION:	Set the charAttr for a single charAttr text object

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisTextInstance
	ss:bp - VisTextCharAttr

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
SetSingleCharAttr	proc	near			uses	ax, cx, si, di
	class	VisTextClass
	.enter

EC <	call	ECCheckCharAttr						>

	mov	di, ds:[si]			;ds:si = instance
	add	di, ds:[di].Vis_offset

	; check for a default

	call	TextFindDefaultCharAttr
	jnc	noDefault

	; its a default -- remove the chunk

	test	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR
	xchg	ax, ds:[di].VTI_charAttrRuns
	jnz	done
	ornf	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR
	call	ObjFreeChunk
	jmp	done

	; not a default charAttr -- must make a chunk

noDefault:
	test	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR
	mov	di, ds:[di].VTI_charAttrRuns
	jz	common

	; no chunk exists -- create one

	mov	ax, si
	call	ObjGetFlags
	and	al, mask OCF_IGNORE_DIRTY

	mov	cx, size VisTextCharAttr
	or	al, mask OCF_DIRTY
	call	LMemAlloc
	mov	di, ds:[si]			;ds:si = instance
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].VTI_storageFlags, not mask VTSF_DEFAULT_CHAR_ATTR
	mov	ds:[di].VTI_charAttrRuns, ax
	mov_tr	di, ax

	; *ds:di = chunk to set

common:
	push	ds, es
	segmov	es, ds				;es:di = dest
	mov	di, ds:[di]
	segmov	ds, ss				;ds:si = source
	mov	si, bp

	mov	cx, (size VisTextCharAttr)/2
	rep	movsw
	pop	ds, es

done:
	.leave
	ret

SetSingleCharAttr	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DoSingleCharAttrChange

DESCRIPTION:	Make a change to a text object with a single charAttr

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisTextObject
	ss:bp - parameter structure (starting with a VisTextRange)
	cx:di - callback routine to make change
	ax, dx - data passed to callback

		Callback routine:
		PASS:
			ss:bp - element
			ss:di - parameter structure
			ax, dx - modData
		RETURN:
			ss:bp - updated
		DESTROYED:
			ax, bx, cx, dx, si, di, bp, es

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

DSSC_frame	struct
    DSSC_charAttr		VisTextCharAttr
    DSSC_callback	dword
DSSC_frame	ends

DoSingleCharAttrChange	proc	near		uses	bp
	.enter

	; save calllback address in frame

	push	cx
	push	di
	mov	di, bp				;ss:di = passed frame

	; allocate charAttr structure no stack

	sub	sp, (size DSSC_frame)-4
	mov	bp, sp

	; get current charAttr

	call	GetSingleCharAttr

	; make the change

EC <	tst	cx							>
EC <	ERROR_Z	CANNOT_SUBSTITUTE_IN_DO_SINGLE_CHAR_ATTR_CHANGE		>
	push	si, bp
	call	ss:[bp].DSSC_callback
	pop	si, bp

	; get the new charAttr

	call	SetSingleCharAttr

	; recover stack space

	add	sp, size DSSC_frame

	.leave
	ret

DoSingleCharAttrChange	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetSingleCharAttr

DESCRIPTION:	Get the charAttr for a single charAttr text object

CALLED BY:	CreateCharAttrRuns, DoSingleCharAttrChange, GetCharAttrForPosition,
		VisTextGetCharAttr

PASS:
	*ds:si - VisTextInstance
	ss:bp - buffer for VisTextCharAttr

RETURN:
	buffer - filled

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

TextFixed	segment resource

GetSingleCharAttr	proc	far
	class	VisTextClass
	uses	ax, cx, di, si, es
	.enter
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	test	ds:[si].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR
	mov	si, ds:[si].VTI_charAttrRuns
	jnz	default

	; not default charAttr -- load from chunk

	mov	si, ds:[si]			;ds:si = VisTextCharAttr

	segmov	es, ss				;es:di = dest
	mov	di, bp
	mov	cx, (size VisTextCharAttr)/2
	rep	movsw

	jmp	done

	; default charAttr -- use routine

default:
	mov_tr	ax, si
	call	TextMapDefaultCharAttr

done:

EC <	call	ECCheckCharAttr						>
	.leave
	ret

GetSingleCharAttr	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextMapDefaultCharAttr

DESCRIPTION:	Load a defualt charAttr

CALLED BY:	INTERNAL

PASS:
	ax - VisTextDefaultCharAttr

	ss:bp - buffer for VisTextCharAttr

RETURN:
	buffer - set

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
TextMapDefaultCharAttr	proc	far
	uses	ax, bx, cx, di, es
	.enter

	; zero out the entire charAttr

	mov_tr	bx, ax

	mov	cx, (size VisTextCharAttr)/2
	segmov	es, ss
	mov	di, bp
	clr	ax
	rep	stosw

	mov	ss:[bp].VTCA_meta.SSEH_style, CA_NULL_ELEMENT

	mov	ax, bx

	; set the font

	and	bx, mask VTDCA_FONT
	shl	bx
	mov	bx, cs:[defaultFonts][bx]
	mov	ss:[bp].VTCA_fontID, bx

	; set the point size

	mov	bx, ax
	and	bx, mask VTDCA_SIZE
	mov	cl, offset VTDCA_SIZE
	shr	bx, cl
	mov	bl,cs:[defaultPointSizes][bx]
	mov	ss:[bp].VTCA_pointSize.WBF_int,bx

	; set the text charAttr

	clr	bx				;assume no charAttrs
	test	ax, mask VTDCA_UNDERLINE
	jz	20$
	or	bl, mask TS_UNDERLINE
20$:
	test	ax, mask VTDCA_BOLD
	jz	30$
	or	bl, mask TS_BOLD
30$:
	test	ax, mask VTDCA_ITALIC
	jz	40$
	or	bl, mask TS_ITALIC
40$:
	mov	ss:[bp].VTCA_textStyles, bl

	; set the color

	mov	bl, ah
	and	bl, 15
	mov	bh, CF_INDEX
	mov	ss:[bp].VTCA_color.low, bx

	; set the background color

	mov	ss:[bp].VTCA_bgColor.low, C_WHITE

	; set the gray screens

	mov	ss:[bp].VTCA_grayScreen, SDM_100
	mov	ss:[bp].VTCA_bgGrayScreen, SDM_0
	;
	; set the font weight and width
	;
	mov	{word}ss:[bp].VTCA_fontWeight, FW_NORMAL or (FWI_MEDIUM shl 8)
CheckHack <(offset VTCA_fontWidth) eq (offset VTCA_fontWeight)+1>

EC <	call	ECCheckCharAttr						>

	.leave
	ret
TextMapDefaultCharAttr	endp


defaultFonts	FontID	\
	FID_BERKELEY, FID_CHICAGO, FID_BISON, FID_WINDOWS, FID_LED,
	FID_ROMA, FID_UNIVERSITY,
	FID_DTC_URW_ROMAN, FID_DTC_URW_SANS, FID_DTC_URW_MONO,
	FID_DTC_URW_SYMBOLPS, FID_DTC_CENTURY_SCHOOLBOOK,
	FID_PIZZA_KANJI, FID_BITSTREAM_KANJI_HON_MINCHO,
	FID_BITSTREAM_KANJI_SQUARE_GOTHIC, FID_JSYS, FID_ESQUIRE


SBCS <defaultPointSizes	byte 8, 9, 10, 12, 14, 18, 24, 36		>
DBCS <defaultPointSizes	byte 8, 9, 10, 12, 16, 18, 24, 36		>

TextFixed	ends

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextFindDefaultCharAttr

DESCRIPTION:	Given an charAttr structure, determine if it is one of the
		default charAttrs

CALLED BY:	SetSingleCharAttr

PASS:
	ss:bp - VisTextCharAttr

RETURN:
	carry - set if charAttr is one of the default charAttrs
	ax - VisTextDefaultCharAttr

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

TextAttributes segment resource

TextFindDefaultCharAttr	proc	far	uses	bx, cx, di, es
	.enter

EC <	call	ECCheckCharAttr						>

	; make es point at tables we use

if	0
	mov	bx, handle defaultFonts
	call	MemLock
else
	;
	; defaultFonts is now in the TextFixed module
	;
	mov	ax, segment defaultFonts
	mov	es, ax
endif

	; FIRST: Check everything that must be set a certain way

	; test for many things that must be zero

	mov	ax, {word} ss:[bp].VTCA_trackKerning
	or	ax, ss:[bp].VTCA_extendedStyles
	jz	5$
toNoDefault:
	jmp	noDefault
5$:
	;
	; Test the font width and font weight
	;
	cmp	{word}ss:[bp].VTCA_fontWeight, FW_NORMAL or (FWI_MEDIUM shl 8)
	jne	toNoDefault
CheckHack <(offset VTCA_fontWidth) eq (offset VTCA_fontWeight)+1>

	; test the gray screen

	cmp	ss:[bp].VTCA_grayScreen, SDM_100
	jnz	toNoDefault

	; test the background gray screen

	cmp	ss:[bp].VTCA_bgGrayScreen, SDM_0
	jnz	toNoDefault

	; test the background color

	cmp	ss:[bp].VTCA_bgColor.CQ_redOrIndex, C_WHITE
	jnz	toNoDefault
	cmp	ss:[bp].VTCA_bgColor.CQ_info, CF_INDEX
	jnz	toNoDefault

	; test the patterns

	cmp	{word} ss:[bp].VTCA_pattern, PT_SOLID
	jnz	toNoDefault
	cmp	{word} ss:[bp].VTCA_bgPattern, PT_SOLID
	jnz	toNoDefault

	; SECOND: Compute the default

	; test the font ID

	mov	ax, ss:[bp].VTCA_fontID
	mov	di, offset defaultFonts		;es:di = default fonts
	mov	cx, length defaultFonts
	repne	scasw				;search for match
	jnz	noDefault
	sub	di, (offset defaultFonts)+2
	mov	bx, di
	shr	bx

	; test the point size

	cmp	ss:[bp].VTCA_pointSize.WBF_frac,0
	jnz	noDefault
	mov	ax,ss:[bp].VTCA_pointSize.WBF_int
	tst	ah
	jnz	noDefault

	mov	di,offset defaultPointSizes
	mov	cx, 8
	repne scasb
	jnz	noDefault
	sub	di,(offset defaultPointSizes)+1
	mov	ax,di
	mov	cl, offset VTDCA_SIZE
	shl	ax,cl
	or	ax,bx				;ax = font and size

	; test the text charAttr

	mov	bl,ss:[bp].VTCA_textStyles
	test	bl, not (mask TS_UNDERLINE or mask TS_BOLD or mask TS_ITALIC)
	jnz	noDefault
	test	bl, mask TS_UNDERLINE
	jz	10$
	ornf	ax, mask VTDCA_UNDERLINE
10$:
	test	bl, mask TS_BOLD
	jz	20$
	ornf	ax, mask VTDCA_BOLD
20$:
	test	bl, mask TS_ITALIC
	jz	30$
	ornf	ax, mask VTDCA_ITALIC
30$:

	; test the color

	mov	bx, ss:[bp].VTCA_color.low	;bl = redOrIndex, bh = info
						;RGB or onBlack not allowed
						;in default
	cmp	bh, CF_INDEX
	jnz	noDefault
	or	ah, bl				;or in color

	; its a default

	stc
done:

if	0
	;
	; defaultFonts is now in the TextFixed module
	;
	mov	bx, handle defaultFonts
	call	MemUnlock			;preserves the carry
endif

	.leave
	ret

	; its not a default

noDefault:
	clc
	jmp	done

TextFindDefaultCharAttr	endp

TextAttributes	ends

;============================================================================
;============================================================================
;		Error checking code below
;============================================================================

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckCharAttr

DESCRIPTION:	Make sure that a VisTextCharAttr structure is legal

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance
	ss:bp - VisTextCharAttr

RETURN:
	none

DESTROYED:
	none -- FLAGS PRESERVED

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@


if	ERROR_CHECK

Text	segment resource

ECCheckCharAttr	proc	far		uses ax, bx, cx, di, es
	.enter
	pushf

	; reference count -- must be <= 30000

	tst	ss:[bp].VTCA_meta.SSEH_meta.REH_refCount.WAAH_high
	ERROR_NZ	VIS_TEXT_CHAR_ATTR_HAS_REF_COUNT_OVER_10000
	cmp	ss:[bp].VTCA_meta.SSEH_meta.REH_refCount.WAAH_low, 30000
	ERROR_A	VIS_TEXT_CHAR_ATTR_HAS_REF_COUNT_OVER_10000

	; no checking for font ID

	; point size -- must be <= MAX_POINT_SIZE
	; point size -- must be >= MIN_POINT_SIZE

	mov	ax, ss:[bp].VTCA_pointSize.WBF_int

	cmp	ax, MIN_POINT_SIZE
	ERROR_B	VIS_TEXT_ILLEGAL_POINT_SIZE
	cmp	ax, MAX_POINT_SIZE
	ERROR_A	VIS_TEXT_ILLEGAL_POINT_SIZE

	; no checking for text charAttrs

	; no checking for colors

	; check the track kerning

	mov	ax, {word} ss:[bp].VTCA_trackKerning

	; track kerning -- must be <= MAX_TRACK_KERNING
	; track kerning -- must be >= MIN_TRACK_KERNING

	cmp	ax, MIN_TRACK_KERNING
	ERROR_L	VIS_TEXT_ILLEGAL_TRACK_KERNING
	cmp	ax, MAX_TRACK_KERNING
	ERROR_G	VIS_TEXT_ILLEGAL_TRACK_KERNING

	; reserved -- must be 0

	segmov	es, ss
	lea	di, ss:[bp].VTCA_reserved
	mov	cx, size VTCA_reserved
	clr	ax
	repe scasb
	ERROR_NZ	VIS_TEXT_CHAR_ATTR_RESERVED_MUST_BE_0

	popf
	.leave
	ret

ECCheckCharAttr	endp

Text	ends

endif

TextAttributes ends
