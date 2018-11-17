COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Text
FILE:		taRunManip.asm

ROUTINES:

	Name			Description
	----			-----------
   EXT	TA_UpdateRunsForReplacement Update all run structures to reflect a
				    text replacement operation
   EXT	TA_UpdateRunsForSelectionChange Update all run structures to reflect a
				        selection change

   INT	ModifyRun		Modify a range of a run array
   INT	EnumRunsInRange		Enumerate the runs in a range to a callback
				routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

DESCRIPTION:
	This file contains the internal routines to handle charAttr, paraAttr and
type runs.  None of these routines are directly accessable outisde the text
object.

	$Id: taRunManip.asm,v 1.1 97/04/07 11:18:39 newdeal Exp $

------------------------------------------------------------------------------@

TextAttributes segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ModifyRun

DESCRIPTION:	Modify a range of a run array

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset of run structure

	ax, dx - data for callback
	ss:bp - VisTextRange followed by any modification data
	cx:di - address of routine to combine an element with a change (where
	     ax, bx stores the change) or cx=0 to replace with ax (where
	     ax is a token)
		* or ax = CA_NULL_ELEMENT for return to base style

		Adjust routine:
		PASS:
			ss:bp - element
			ss:di - ss:bp passed to ModifyRun
			*ds:si - run
			ax, dx - modData
			bx - value passed to ModifyRun in bx
		RETURN:
			ss:bp - updated
		DESTROYED:
			ax, bx, cx, dx, si, di, bp, es

RETURN:
	dxax - last run position (0xffff if no change (insertion el change))

DESTROYED:
	cx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

ModifyRunFrame	struct
    MRF_element		byte (size VisTextMaxParaAttr) dup (?)

	; these fields are stored by pushing them on the stack

    MRF_textSize	dword
    MRF_passedFrame	nptr
    MRF_run		word
    MRF_modStart	dword
    MRF_modEnd		dword
    MRF_dataAX		word
    MRF_dataDX		word
    MRF_object		optr
    MRF_adjustRoutine	dword		;cx:di - callback routine or 0

ModifyRunFrame	ends

ModifyRun	proc	far	uses bp, es
	class	VisTextClass
	.enter

	; first we need some stack space to do our thing

	push	ax				;word on stack
	push	bp
	mov	bp, sp
	mov	{word} ss:[bp+2], SS_BUF_SIZE
	pop	bp
	call	SwitchStackWithData

;
;	If this operation just sets the insertion token, then we don't want to
;	add any undo items.
;
;	We are just setting an insertion token if:
;		The range is null (i.e. start = end)
;		The run we are changing is not a para attr run.		
;

	push	cx
	cmpdw	ss:[bp].VTR_start, ss:[bp].VTR_end, cx
	pop	cx
	jnz	areaSelected
	cmp	bx, offset VTI_paraAttrRuns
	jz	areaSelected

	call	TU_AbortChainIfUndoable

	call	ModifyRunWithoutUndo
	jmp	exit

areaSelected:
	push	cx, ax
	mov	cx, bx
	call	CheckIfRunsInRangeForUndo
	tst	ax			;No undo
	jz	10$

;	Save the runs in the range that will be modified.

	push	bx
	mov	bx, bp
	call	TU_CreateUndoForRunsInRange
	pop	bx
10$:
	pop	cx, ax

;	Modify the runs

	call	ModifyRunWithoutUndo

;	Create an undo action that will delete runs across the range we have
;	modified (if there are no runs in this range, nothing will be
;	added).

	push	cx, ax
	mov	cx, bx			;CX <- run offset
	call	CheckIfRunsInRangeForUndo
	tst	ax			;Exit if no undo/no runs in range
	jz	noPostUndo

	push	bx
	mov	bx, bp
	call	TU_CreateUndoForRunModification
	pop	bx
noPostUndo:
	pop	cx, ax
exit:
	pop	di
	add	sp, SS_BUF_SIZE
	call	ThreadReturnStackSpace

	.leave
	ret
ModifyRun	endp

;---

ModifyRunWithoutUndo	proc	near
	class	VisTextClass
	.enter

EC <	call	T_AssertIsVisText					>

	; allocate local space and store local variables

	push	cx			;push callback - high word
	push	di			;low word
	push	ds:[LMBH_handle]	;object.handle
	push	si			;object.chunk
	push	dx			;dataDX
	push	ax			;dataAX
	pushdw	ss:[bp].VTR_end		;modEnd
	pushdw	ss:[bp].VTR_start	;modStart
	push	bx			;run
	push	bp			;passed frame

	call	TS_GetTextSize		;dx.ax = size
	push	dx
	push	ax

	sub	sp, size VisTextMaxParaAttr
	mov	bp, sp			;ss:bp = ModifyRunFrame

	; if (modStart == modEnd) {

	cmpdw	ss:[bp].MRF_modStart, ss:[bp].MRF_modEnd, cx
	LONG jnz areaSelected
	cmp	bx, offset VTI_paraAttrRuns
	LONG jz	areaSelected

	; if we are at the end of the text then act as if an area is selected

	cmpdw	dxax, ss:[bp].MRF_modStart
	jz	areaSelected

	;    if (adjustVector == 0) {
	;	SetInsertionElement(modData)

	tst	ss:[bp].MRF_adjustRoutine.segment
	jnz	changeInsertionElement
	mov	bx, ss:[bp].MRF_dataAX
	cmp	bx, CA_NULL_ELEMENT
	jz	changeInsertionElement

	; replace insertion token with the given token

	mov	ax, ss:[bp].MRF_run
	call	SetInsertionElement
setDXdone:
	mov	dx, 0xffff
	jmp	done

	;    else {
	;	temp = GetRunForPosition(modStart).token
	;	GetElement(buf, temp)
	;	adjustVector(buf, modData)
	;	AddElement(buf, 0)
	;	SetInsertionElement(temp)
	;    }

changeInsertionElement:
	mov	bx, ss:[bp].MRF_run
	call	GetInsertionElement		;if an insertion element
	cmp	bx, CA_NULL_ELEMENT		;already exists then modify it
	jnz	insertionElementExists
	movdw	dxax, ss:[bp].MRF_modStart
	mov	bx, ss:[bp].MRF_run
	call	TSL_IsParagraphStart
	jnc	useLeft
						; this is the start of
						; a line -- use the
						; attributes to the
						; Right
	call	GetRunForPosition
	jmp	gotRun

useLeft:
						; this is NOT the
						; start of a line --
						; use the attributes
						; to the Left
	call	GetRunForPositionLeft
gotRun:
	call	MR_Unlock

insertionElementExists:
	push	bx
	mov	bx, ss:[bp].MRF_run
	call	RunArrayLock
	pop	bx
	call	ElementAddRef
	call	MR_ModifyElementLow
	call	MR_Unlock

	mov	ax, ss:[bp].MRF_run
	call	SetInsertionElement

	push	bx
	mov	bx, ss:[bp].MRF_run
	call	RunArrayLock
	pop	bx
	call	RemoveElement
	call	MR_Unlock
	jmp	setDXdone

	; } else {
	;    find charAttr run covering the modStart
	;    if (modStart != start of run) {
	;	insert a run before this one for the text before the start
	;	of the modification
	;    }

areaSelected:
	movdw	dxax, ss:[bp].MRF_modEnd	;find token for end of
						;range to change
	call	GetRunForPosition		;bx = token

	call	ElementAddRef		;increment its ref count so that the
					;element does not go away too early
	push	bx			;save token covering end of range

	call	MR_Unlock		;*ds:si = text object

	movdw	dxax, ss:[bp].MRF_modStart
	mov	bx, ss:[bp].MRF_run
	call	GetRunForPosition

	; ds:si = run element, dx:ax = pos, bx = token, cx = # consecutive

	cmpdw	dxax, ss:[bp].MRF_modStart
	jz	runAtStart

	; if there is not a run at the start of the range to modify then
	; insert a run where the selection changes

	call	RunArrayInsert
	call	RunArrayNext			;move to run after one inserted
	call	RunArrayMarkDirty
	mov	ax, ss:[bp].MRF_modStart.low	;it starts at beginning of
	mov	ds:[si].TRAE_position.WAAH_low,ax	;area modified
	mov	al, ss:[bp].MRF_modStart.high.low
	mov	ds:[si].TRAE_position.WAAH_high, al

runAtStart:

	;    while (modEnd >= start of next run) {

	; ds:si = run

topLoop:
	call	MR_ModifyElement
	call	RunArrayNext			;dx.ax = position

	cmpdw	dxax, ss:[bp].MRF_modEnd
	jb	topLoop
	jz	endLoop				; if exact match then done

	; if not exact match then we must add a run at the end

	; ds:si = run AFTER our range, dx.ax = position

	; add a run at the end so that our changes do not affect text beyond
	; the end of the selected area

	; if we were passed (x, textSize) then don't add a run at the end
	; of the text (since it is not needed)

	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH
	movdw	dxax, ss:[bp].MRF_modEnd
	jnz	notSpecialEnd
	cmpdw	dxax, ss:[bp].MRF_textSize
	jz	endLoop
notSpecialEnd:
	pop	bx			;recover token for end of range
	push	bx
	call	RunArrayInsert

endLoop:

	pop	bx			;discard token at end of range
	call	RemoveElement		;after decrementing its ref count
	call	MR_Unlock
	mov	bx, ss:[bp].MRF_run
	call	CoalesceRun		;dxax = last run

	; free local space

done:
 	mov	bx, ss:[bp].MRF_run					
	mov	bp, ss:[bp].MRF_passedFrame
	add	sp,size ModifyRunFrame


	.leave
	ret

ModifyRunWithoutUndo	endp

;----------

MR_Unlock	proc	near
	call	RunArrayUnlock
	FALL_THRU	MR_LoadText
MR_Unlock	endp

MR_LoadText	proc	near
	push	bx
	mov	bx, ss:[bp].MRF_object.handle
	call	MemDerefDS
	mov	si, ss:[bp].MRF_object.chunk
	pop	bx
	ret
MR_LoadText	endp

;------------

	; ds:si - run array element

MR_ModifyElement	proc	near
	class	VisTextClass
	.enter

	; get the old element stored here and remove a reference to it

	mov	bx, ds:[si].TRAE_token
	call	MR_ModifyElementLow
	call	RunArrayMarkDirty
	mov	ds:[si].TRAE_token, bx

	.leave
	ret

MR_ModifyElement	endp

;-----------

	; bx = element

MR_ModifyElementLow	proc	near	uses cx
	class	VisTextClass
	.enter

	call	GetElement
	call	RemoveElement
	tst	ss:[bp].MRF_adjustRoutine.segment
	jz	substitute

	; adjust the element using the callback routine, then add it back

	call	MR_CallAdjustVector
afterAdjust:
	call	AddElement			;returns bx = token
common:

	.leave
	ret

	; substitute the existing element with the passed element

substitute:
	mov	bx, ss:[bp].MRF_dataAX
	cmp	bx, CA_NULL_ELEMENT
	jz	returnToBaseStyle
	call	ElementAddRef
	jmp	common

	; passed CA_NULL_ELEMENT which means return to base style

returnToBaseStyle:
	mov	ax, ss:[bp].SSEH_style
	cmp	ax, CA_NULL_ELEMENT
	jz	afterAdjust
	pushdw	dssi
	push	di
	call	MR_LoadText

	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GetStyleArray
	call	StyleSheetLockStyleChunk	; *ds:si = style, carry = flag
	pushf
	call	ChunkArrayElementToPtr		; ds:di = style
	mov	ax, ds:[di].TSEH_charAttrToken
	cmp	ss:[bp].MRF_run, offset VTI_charAttrRuns
	jz	10$
	mov	ax, ds:[di].TSEH_paraAttrToken
10$:
	popf
	call	StyleSheetUnlockStyleChunk
	add	sp, size StyleChunkDesc

	pop	di
	popdw	dssi
	mov_tr	bx, ax
	call	GetElement			;use *base* element
	jmp	afterAdjust

MR_ModifyElementLow	endp

;------------

	;ss:bp - element

MR_CallAdjustVector	proc	near		uses	cx, si, di, bp, es
	.enter
	mov	ax, ss:[bp].MRF_dataAX
	mov	dx, ss:[bp].MRF_dataDX
	mov	bx, ss:[bp].MRF_run
	mov	di, ss:[bp].MRF_passedFrame
	call	ss:[bp].MRF_adjustRoutine
	.leave
	ret

MR_CallAdjustVector	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	EnumRunsInRange

DESCRIPTION:	Enumerate the runs in a range to a callback routine

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset of run structure

	ss:bp - VisTextRange to enumerate
	ax, cx, di - enumData
	dx - callback routine

		Callback routine:
		PASS:
			ss:bp - element
			*ds:si - run
			ax, cx, di - enumData
		RETURN:
			ax, cx, di - possibly changed
		DESTROYED:
			bx, dx, si, bp, ds, es

RETURN:
	ax, cx, di - enumData

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


EnumRunsInRangeFrame	struct
    ERIRF_element	VisTextMaxParaAttr <>

	; these fields are stored by pushing them on the stack

    ERIRF_enumEnd	dword
    ERIRF_passedFrame	word		;bp
    ERIRF_callback	word		;di
    ERIRF_dataAX	word		;ax
    ERIRF_dataCX	word		;cx
    ERIRF_dataDI	word		;di
    ERIFR_object	optr		;ds:si
EnumRunsInRangeFrame	ends

EnumRunsInRange	proc	far
EC <	call	T_AssertIsVisText					>

	; allocate local space

	push	ds			;object
	push	si

	push	di
	push	cx
	push	ax
	push	dx			;save callback
	push	bp			;passed frame
	pushdw	ss:[bp].VTR_end

	movdw	dxax, ss:[bp].VTR_start
	cmpdw	dxax, ss:[bp].VTR_end
	jnz	areaSelected
	call	GetRunForPositionLeft
	jmp	common
areaSelected:
	call	GetRunForPosition		;returns cx = token
common:

	sub	sp, size VisTextMaxParaAttr
	mov	bp, sp

topLoop:

	;     call callback routine

	push	cx, si, di, ds, es
	call	GetElement
	mov	ax, ss:[bp].ERIRF_dataAX
	mov	cx, ss:[bp].ERIRF_dataCX
	mov	di, ss:[bp].ERIRF_dataDI
	push	bp
	call	ss:[bp].ERIRF_callback		;call callback
	pop	bp
	mov	ss:[bp].ERIRF_dataAX, ax
	mov	ss:[bp].ERIRF_dataCX, cx
	mov	ss:[bp].ERIRF_dataDI, di
	pop	cx, si, di, ds, es

	;     find next run
	; } while (run.start < enumEnd)

	call	RunArrayNext
	cmpdw	dxax, ss:[bp].ERIRF_enumEnd
	jb	topLoop

	call	RunArrayUnlock

	add	sp,(size EnumRunsInRangeFrame)-14
	pop	bp
	pop	dx
	pop	ax
	pop	cx
	pop	di
	pop	si
	pop	ds
	ret

EnumRunsInRange	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_UpdateRunsForReplacement

DESCRIPTION:	Update all run structures to reflect a text replace operation.
		Called BEFORE the text is updated.

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisTextInstance
	ss:bp - VisTextReplaceParameters, these fields used:
		VTRP_range
		VTRP_insCount
	dxax - text size

RETURN:
	carry - set if SendCharAttrParaAttrChange needs to be called
	zero flag - set (z) if a paraAttr change occurred as a result of the
		replace operation.

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

TextUpdateRuns segment resource

UpdateRunFlags	record
    :8					;force to a word
    URF_CHAR_ATTR_RUN:1
    URF_PARA_ATTR_RUN:1
    URF_TYPE_RUN:1
    URF_GRAPHIC_RUN:1
    URF_UPDATE_UI:1
    URF_NEED_COALESCE:1
    URF_MIDDLE:1
    URF_DELETION:1
UpdateRunFlags	end

TA_UpdateRunsForReplacement	proc	far	uses ax, bx, cx, dx, di
	class	VisTextClass
	.enter

EC <	call	T_AssertIsVisText					>

	; we need to update each run structure that exists

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	bl, ds:[bx].VTI_storageFlags
	clr	bh				;bh is flag for sending change

	; if there are any runs then call to the TextAttribute resource
	; to update them so that we can have one *one* ResourceCallInt

	test	bl, mask VTSF_GRAPHICS or mask VTSF_MULTIPLE_CHAR_ATTRS \
			or mask VTSF_MULTIPLE_PARA_ATTRS or mask VTSF_TYPES
	jz	noRuns
	call	UpdateMultipleRuns
noRuns:

	; Stuff the carry and zero flags.

	lahf
	and	ah, not (mask CPU_CARRY or mask CPU_ZERO)
	or	ah, bh
	sahf

	.leave
	ret

TA_UpdateRunsForReplacement	endp

TextUpdateRuns ends

;------

	; dxax = text size
	; bl = VisTextStorageFlags
	; bh = return flags (CPUFlags)
	; ss:bp = VisTextReplaceParameters

UpdateMultipleRuns	proc	far
	class	VisTextClass

	; get the size of the text

	subdw	dxax, ss:[bp].VTRP_range.VTR_end
	mov_tr	di, ax
	or	di, dx				;di = 0 if at end of text
	jz	atEnd
	mov	di, mask URF_MIDDLE
atEnd:
	cmpdw	ss:[bp].VTRP_range.VTR_start, ss:[bp].VTRP_range.VTR_end, ax
	jz	noDeletion
	or	di, mask URF_DELETION
noDeletion:	

	; update graphic runs if needed

	; if we're inserting at the end of the object then no update is needed

	clr	ax				;no insertion token
	mov	dx, offset VTCRI_lastGraphicRun	;offset in cached data
	mov	cl, mask VTSF_GRAPHICS		;flags
	call	doUpdateCheckGraphic
	jnc	afterGraphic

	push	di
	call	UpdateGraphicRun		;dxax = last run
	pop	di
	mov	cx, offset VTCRI_lastGraphicRun	;offset in cached data
	call	UpdateLastRunPosition
afterGraphic:

	; update charAttr runs if needed

	mov	ax, ATTR_VIS_TEXT_CHAR_ATTR_INSERTION_TOKEN
	mov	dx, offset VTCRI_lastCharAttrRun	;offset in cached data
	mov	cl, mask VTSF_MULTIPLE_CHAR_ATTRS	;flags
	call	doUpdateCheck
	jnc	afterCharAttr

	push	di
	mov	cx, offset VTI_charAttrRuns
	ornf	di, mask URF_CHAR_ATTR_RUN
	call	UpdateRun
	pop	di
	jnc	10$				;if carry set then update UI
	ornf	bh, mask CPU_CARRY
10$:
	mov	cx, offset VTCRI_lastCharAttrRun	;offset in cached data
	call	UpdateLastRunPosition
afterCharAttr:

	; update paraAttr runs if needed

	clr	ax					;no insertion token
	mov	dx, offset VTCRI_lastParaAttrRun	;offset in cached data
	mov	cl, mask VTSF_MULTIPLE_PARA_ATTRS	;flags
	call	doUpdateCheck
	jnc	afterParaAttr

	push	di
	mov	cx, offset VTI_paraAttrRuns
	ornf	di, mask URF_PARA_ATTR_RUN
	call	UpdateRun
	pop	di
	jnc	20$				;if carry set then update UI
	or	bh, mask CPU_CARRY or mask CPU_ZERO
20$:
	mov	cx, offset VTCRI_lastParaAttrRun	;offset in cached data
	call	UpdateLastRunPosition
afterParaAttr:

	; update type runs if needed

	mov	ax, ATTR_VIS_TEXT_TYPE_INSERTION_TOKEN
	mov	dx, offset VTCRI_lastTypeRun	;offset in cached data
	mov	cl, mask VTSF_TYPES		;flags
	call	doUpdateCheck
	jnc	afterType

	push	di
	mov	cx, OFFSET_FOR_TYPE_RUNS
	ornf	di, mask URF_TYPE_RUN
	call	UpdateRun
	pop	di
	jnc	30$				;if carry set then update UI
	or	bh, mask CPU_CARRY
30$:
	mov	cx, offset VTCRI_lastTypeRun	;offset in cached data
	call	UpdateLastRunPosition
afterType:
	ret

;---

	; ax = vardata
	; cl = flag to test
	; dx = offset in cached data

	; return carry set to update

doUpdateCheck:

	; test for the simple case first: if inserting at the end then optimize

	test	di, mask URF_MIDDLE or mask URF_DELETION
	jz	optimizeIfNoInsertionToken

doUpdateCheckGraphic:
	test	bl, cl				;if no runs then no update
	jz	done

	; the trickier case is that of the action happening after the last
	; run

	push	ax, bx
	mov	ax, TEMP_VIS_TEXT_CACHED_RUN_INFO
	call	ObjVarFindData
	jnc	noOptPop
	add	bx, dx				;ds:bx = last run
	cmpdw	ss:[bp].VTRP_range.VTR_start, ds:[bx], ax
	jbe	noOptPop
	pop	ax, bx

	; we can skip updating if there is no insertion token

optimizeIfNoInsertionToken:
	tst_clc	ax
	jz	done
	push	bx
	call	ObjVarFindData
	pop	bx
done:
	retn

noOptPop:
	pop	ax, bx
	stc
	retn

UpdateMultipleRuns	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateLastRunPosition

DESCRIPTION:	Update the cached position of the last run

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	dxax - last run position
	cx - offset in VisTextCachedRunInfo

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
	Tony	5/16/92		Initial version

------------------------------------------------------------------------------@
UpdateLastRunPosition	proc	near
	push	bx
	push	ax
	mov	ax, TEMP_VIS_TEXT_CACHED_RUN_INFO or mask VDF_SAVE_TO_STATE
	call	ObjVarFindData
	jnc	create
exists:
	pop	ax
	add	bx, cx			;ds:bx = offset
	movdw	ds:[bx], dxax
	pop	bx
	ret

	; initialize new data to 0xffff

create:
	push	cx, di, es
	mov	cx, size VisTextCachedRunInfo
	call	ObjVarAddData
	segmov	es, ds
	mov	di, bx
	mov	ax, 0xffff
	mov	cx, (size VisTextCachedRunInfo) / 2
	rep	stosw
	pop	cx, di, es
	jmp	exists

UpdateLastRunPosition	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateLastRunPositionByRunOffset

DESCRIPTION:	Given a run offset call UpdateLastRunPosition

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	dxax - last run position
	bx - run offset

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
	Tony	5/16/92		Initial version

------------------------------------------------------------------------------@
UpdateLastRunPositionByRunOffset	proc	far	uses cx
	class	VisTextClass
	.enter

	; this is a flag indicating that the last run did not change

	cmp	dx, 0xffff
	jz	done

	mov	cx, offset VTCRI_lastCharAttrRun
	cmp	bx, offset VTI_charAttrRuns
	jz	10$
	mov	cx, offset VTCRI_lastParaAttrRun
	cmp	bx, offset VTI_paraAttrRuns
	jz	10$
	mov	cx, offset VTCRI_lastGraphicRun
	cmp	bx, OFFSET_FOR_GRAPHIC_RUNS
	jz	10$
	mov	cx, offset VTCRI_lastTypeRun
EC <	cmp	bx, OFFSET_FOR_TYPE_RUNS				>
EC <	ERROR_NZ ILLEGAL_RUN_TYPE					>
10$:
	call	UpdateLastRunPosition
done:
	.leave
	ret

UpdateLastRunPositionByRunOffset	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_UpdateRunsForSelectionChange

DESCRIPTION:	Update all run structures to reflect that the selection has
		changed

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisTextInstance

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

TextUpdateRuns segment resource

TA_UpdateRunsForSelectionChange	proc	far	uses di
	class	VisTextClass
	.enter

EC <	call	T_AssertIsVisText					>

	; we need to update the charAttr and type runs if they exist

	call	Text_DerefVis_DI

	; update charAttr runs if needed

	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS
	jz	afterCharAttr
	call	ClearCharAttr
afterCharAttr:
	call	ClearTypeAttr
	
	.leave
	ret

TA_UpdateRunsForSelectionChange	endp

TextUpdateRuns ends

ClearCharAttr	proc	far	uses	ax, bx, dx
	class	VisTextClass
	.enter

	mov	ax, ATTR_VIS_TEXT_CHAR_ATTR_INSERTION_TOKEN
	call	ObjVarFindData
	jnc	done

	call	EditUnHilite
	mov	bx, offset VTI_charAttrRuns
	mov	dx, 1
	call	ClearInsertionElement
	call	EditHilite
done:
	.leave
	ret

ClearCharAttr	endp

ClearTypeAttr	proc	far	uses	ax, bx, dx
	class	VisTextClass
	.enter

	mov	ax, ATTR_VIS_TEXT_TYPE_INSERTION_TOKEN
	call	ObjVarFindData
	jnc	done

	call	EditUnHilite
	mov	bx, OFFSET_FOR_TYPE_RUNS
	mov	dx, 1
	call	ClearInsertionElement
	call	EditHilite
done:
	.leave
	ret

ClearTypeAttr	endp

;========================================================================
;	Internal routines
;========================================================================



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoUpdateRunUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates any necessary undo actions for Update{Graphic}Run

CALLED BY:	GLOBAL
PASS:		ss:bx - VisTextReplaceParams
		cx - run offset
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoUpdateRunUndo	proc	near	uses	ax, bp, di
	class	VisTextClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_features, mask VTF_ALLOW_UNDO
	LONG jz	exit

EC <	xchg	bx, bp							>
EC <	call	TS_ECCheckParams					>
EC <	xchg	bx, bp							>

	cmpdw	ss:[bx].VTRP_range.VTR_end, ss:[bx].VTRP_range.VTR_start, ax
	LONG jz	inserting


;	If we are undoing a previous replace, we don't usually need to
;	add more undo information, as in general there was enough undo
;	information already generated.
;

;	The only case where it is necessary to add more undo info is when
;	we are deleting text, as the run information can be lost forever
;	(e.g. The user sets an insertion token, types some text, then undoes
;	the typing, we *need* to generate run undo information, because
;	the run information for that range just goes back into the insertion
;	token, and is not saved in the undo chain).
;

	tstdw	ss:[bx].VTRP_insCount
	jz	generateUndoInformation
	test	ss:[bx].VTRP_flags, mask VTRF_UNDO
	jnz	exit
generateUndoInformation:


;
;	Non-para-attr runs can be optimized this way:
;
;	1) If the range has any runs in it *before* the end, we save the
;	   entire range, *including the end*.
;
;	2) If the range has no runs in it except at the end, don't bother
;	   saving anything.
;
;
;	For para-attr runs, we need to check the entire range (for example, if
;	there is a CR at position 14h, and a para attr at position 15h, and
;	we delete the CR, the following para attr will disappear too, even
;	though it is at the end of the range being modified). This is different
;	from other types of runs, as if the only run in the replace range comes
;	at the end of the range, it will get moved, but not deleted, so no
;	undo information needs to be stored.
;


	mov	bp, bx
	pushdw	ss:[bp].VTRP_range.VTR_end
	cmp	cx, offset VTI_paraAttrRuns
	jnz	normalRun

	call	CheckIfRunsInRangeForUndo
	tst	ax
	jz	noRunsInRange

;	When a run is being deleted, we have to save any runs at the end of
;	the range as well, as they might be coalesced out of existence when
;	the deletion occurs. We save all the runs between the start of this
;	range and the next paragraph after the end of the range.

	movdw	dxax, ss:[bp].VTRP_range.VTR_end
	call	TSL_FindParagraphEnd
	incdw	dxax
	movdw	ss:[bp].VTRP_range.VTR_end, dxax
	call	TS_GetTextSize
	cmpdw	dxax, ss:[bp].VTRP_range.VTR_end
	jae	common
	movdw	ss:[bp].VTRP_range.VTR_end, dxax
	jmp	common
normalRun:
	decdw	ss:[bp].VTRP_range.VTR_end
	call	CheckIfRunsInRangeForUndo	;If no runs in range or no
	incdw	ss:[bp].VTRP_range.VTR_end

	tst	ax
	jz	noRunsInRange

common:

;	There was a run in the range, so create the appropriate undo items

	call	TU_CreateUndoForRunsInRange
	call	TU_CreateUndoForRunModification
noRunsInRange:	
	popdw	ss:[bp].VTRP_range.VTR_end
exit:
	.leave
	ret

inserting:
;	If we are just inserting, no runs will be deleted, so no undo action
;	is necessary, *except* in the case where there is an insertion
;	token. If we have an insertion token, we will generate undo
;	information, otherwise we'll skip the tedium.

	call	GenProcessUndoCheckIfIgnoring	;If ignoring, don't create
	tst	ax				; an undo action.
	jnz	exit

	cmp	cx, offset VTI_paraAttrRuns	;No insertion elements for
	jz	exit				; paraAttr runs.
	push	bx
	mov	bx, cx
	call	GetInsertionElement
	cmp	bx, CA_NULL_ELEMENT		;If inserting w/o an insertion
	pop	bx				; element, just exit (no runs
	jz	exit				; will be modified).

	mov	bp, bx
	call	TU_CreateUndoForRunModification
	jmp	exit

DoUpdateRunUndo	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateRun

DESCRIPTION:	Update a run structure to reflect a text replace operation

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - offset of run

	di - UpdateRunFlags
	ss:bp - VisTextReplaceParameters, these fields used:
		VTRP_range
		VTRP_insCount
		VTRP_flags.VTRF_USER_MODIFICATION
		VTRP_flags.VTRF_UNDO

RETURN:
	carry - set if UI should be updated
	dxax - last run position

DESTROYED:
	cx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	UpdateRuns(runs, position, insCount, delCount)
	{
	    runPtr, runStart, runEnd = GetRunForPosition
	    while ( (runEnd - position) <= delCount ) {
		RunArrayDelete(runPtr)
		runPtr, runStart, runEnd = LoadRegsFromRun
	    }
	    adjustment = insCount - delCount
	    while (runPtr->runStart != 0) {
		runPtr->runStart += adjustment
		runPtr++
	    }
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

UpdateRun	proc	near
EC <	call	T_AssertIsVisText					>

	push	bx
	movdw	dxax, ss:[bp].VTRP_range.VTR_end	;dx.ax = range end
	subdw	dxax, ss:[bp].VTRP_range.VTR_start	;dx.ax = delete count
	mov	bx, bp

runOffset	local	word	\
		push	cx
object		local	optr	\
		push	ds:[LMBH_handle], si
insCount	local	dword	\
		push	ss:[bx].VTRP_insCount.high, \
			ss:[bx].VTRP_insCount.low
delCount	local	dword	\
		push	dx, ax

deleteRange	local	VisTextRange	\
		push	ss:[bx].VTRP_range.VTR_end.high, \
			ss:[bx].VTRP_range.VTR_end.low, \
			ss:[bx].VTRP_range.VTR_start.high, \
			ss:[bx].VTRP_range.VTR_start.low


flags		local	UpdateRunFlags	\
		push	di
runPosition	local	dword
nextRunPosition	local	dword
modifyRange	local	VisTextRange
lastBlockDirtied local	hptr
	class	VisTextClass
	.enter

	call	DoUpdateRunUndo

	mov	bx, cx
	mov	lastBlockDirtied, 0

EC <	call	ECCheckRun						>

	; if we are replacing (both deleting and inserting) we want to get
	; the token for the selected area and use it as the insertion token

	tstdw	insCount
	jz	noReplace
	tstdw	delCount
	jz	noReplace

	test	flags, mask URF_PARA_ATTR_RUN
	jnz	noReplace

	; we're doing a replace...

	ornf	flags, mask URF_UPDATE_UI
	movdw	dxax, deleteRange.VTR_start
	call	GetRunForPosition
	call	RunArrayUnlock
	call	loadObject
	mov	ax, runOffset
	call	SetInsertionElement
	mov	bx, runOffset

noReplace:

	movdw	dxax, deleteRange.VTR_start
	call	GetRunForPositionLeft		;ds:si = first element
						;dx.ax = position, bx = token
						;cx = # consecutive
	tstdw	dxax
	jz	runLoop
	call	RunArrayPrevious

	;--------------
	; for each run

runLoop:
	call	LoadRegsFromRun

	; *** case 0: at last run -> end

	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH
	jz	toDoneWithRuns

	movdw	runPosition, dxax

	; move to NEXT run -- this means that we point at the run after
	; the run the we are processing

	call	RunArrayNext
	movdw	nextRunPosition, dxax

	; *** case -1: if only one run then don't remove it

	tstdw	runPosition
	jnz	notFirstRunAndOnlyRun

	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH
	jnz	notFirstRunAndOnlyRun
toDoneWithRuns:
	jmp	doneWithRuns
notFirstRunAndOnlyRun:

	;*** case 1: run is entirely before range -> do nothing
	;	if (run.end < range.start)
	;		OR (if run.end = range.start && paraAttr run)

	cmpdw	dxax, deleteRange.VTR_start
	jbe	runLoop

	;*** case 2: run is entirely after range -> adjust run
	;	if (run.start >= range.end)

	cmpdw	runPosition, deleteRange.VTR_end, bx
	LONG jb	notCase2
	LONG ja	case2

	; the run starts at the exact end of the range
	;	charAttrs/types - if not at the beginning of a paragraph
	;			  then adjust
	;	paraAttrs - if no delete then skip
	;		 if delete then extend range to next PP

	test	flags, mask URF_PARA_ATTR_RUN
	jnz	case2ParaAttr

	; if we are deleting and the character after the end of the
	; deletion is a CR then extend the run to cover the CR -- added 11/10/92

	tstdw	delCount
	jz	afterCharParaEndAdjust
	push	si, ds				;save position in run
	call	loadObject
	movdw	dxax, runPosition
	call	TSL_IsParagraphEnd		;carry set if so
	pop	si, ds
	LONG jz	doDelete		;skip if end of file
	jnc	afterCharParaEndAdjust
	call	RunArrayPrevious
	add	ds:[si].TRAE_position.WAAH_low, 1
	adc	ds:[si].TRAE_position.WAAH_high, 0
	call	markDirty
	call	RunArrayNext
afterCharParaEndAdjust:

	push	si, ds				;save position in run
	call	loadObject
	movdw	dxax, deleteRange.VTR_end
	call	TSL_IsParagraphStart		;carry set if so
	jnc	noForceControllerUpdate
	ornf	flags, mask URF_UPDATE_UI
noForceControllerUpdate:
	movdw	dxax, deleteRange.VTR_start
	call	TSL_IsParagraphStart		;carry set if so
	pop	si, ds
	jnc	case2

	; we are at the beginning of a paragraph so we don't want to adjust
	; for the insertion but we do want to adjust for the deletion (if any)

	tstdw	delCount
	jz	toRunLoop2
	ornf	flags, mask URF_NEED_COALESCE
	call	RunArrayPrevious		;dxax = position
	subdw	dxax, delCount
	jmp	storePosition

case2ParaAttr:
	tstdw	delCount
	jz	toRunLoop2
	jmp	extendRangeToNextPP

case2:
	tstdw	runPosition			;don't adjust run starting at 0
	jz	toRunLoop2

	; point at previous run since we will modify it

	call	RunArrayPrevious		;dxax = position
	tstdw	delCount
	jz	noNeedCoalesce
	ornf	flags, mask URF_NEED_COALESCE
noNeedCoalesce:
	subdw	dxax, delCount
addInsCountAndStore:
	adddw	dxax, insCount
storePosition:
	mov	ds:[si].TRAE_position.WAAH_low, ax
	mov	ds:[si].TRAE_position.WAAH_high, dl
	movdw	runPosition, dxax		;store new position
	call	markDirty
	call	RunArrayNext
toRunLoop2:
	jmp	runLoop

notCase2:

	;	if (run.start >= range.start)

	cmpdw	runPosition, deleteRange.VTR_start, bx
	jb	toRunLoop2

	; NOTE!  This is recently added to fix a bug deleting the
	;	 first character of a charAttr run
	;	-> runStart == rangeStart
	;		if (runEnd > deleteRange.VTR_end) then do nothing

	jnz	notCase25
	test	flags, mask URF_MIDDLE			;if at end then always
	jz	notCase25				;delete the run
	cmpdw	dxax, deleteRange.VTR_end
	jbe	notCase25

	; *unless* there is only one more character in the run and it is a CR

	decdw	dxax
	cmpdw	dxax, deleteRange.VTR_end
	jnz	notCase25Inc
	test	flags, mask URF_PARA_ATTR_RUN
	jnz 	toRunLoop2
	pushdw	dssi
	call	loadObject
	call	TSL_IsParagraphEnd		;carry set if so
	popdw	dssi
	jnc	toRunLoop2

	; *unless* this is the only character on a line

	pushdw	dssi
	call	loadObject
	movdw	dxax, deleteRange.VTR_start
	call	TSL_IsParagraphStart		;carry set if so
	popdw	dssi
	jc	toRunLoop2
	jmp	doDelete

notCase25Inc:
	incdw	dxax
notCase25:

	; *** case 3: run entirely in range -> delete
	;		if (run.end <= range.end) OR (deleting at end flag)

	ornf	flags, mask URF_UPDATE_UI
	test	flags, mask URF_MIDDLE
	jnz	inMiddle

	;	Added 11/4/92
	;	We are deleting at the end -- if this is the last run and it
	;	is a paragraph attibute run then we do not want to make the
	;	change (so that lines at the end work correctly)
	;	-- or if this is a character attribute run at the beginning
	;	   of a paragraph

	test	flags, mask URF_PARA_ATTR_RUN
	jnz	doSpecialForDeletingAtEnd
	pushdw	dssi
	call	loadObject
	movdw	dxax, deleteRange.VTR_start
	call	TSL_IsParagraphStart		;carry set if so
	popdw	dssi
	jnc	doDelete
doSpecialForDeletingAtEnd:
	cmp	nextRunPosition.high, TEXT_ADDRESS_PAST_END_HIGH
	jnz	doDelete

	; if we are deleting at the end of the range end the entire run is
	; being nuked then nuke the run

	cmpdw	runPosition, deleteRange.VTR_start, ax
	ja	doDelete
	jmp	runLoop

inMiddle:
	cmpdw	dxax, deleteRange.VTR_end
	ja	notCase3
doDelete:
	call	RunArrayPrevious		;dxax = position
doDeleteAfterMoveBack:
	call	RunArrayDelete
	tstdw	runPosition			;if we deleted the first run
	jnz	notDeleteFirst			;then set next to 0
	clr	ax
	mov	ds:[si].TRAE_position.WAAH_low, ax
	mov	ds:[si].TRAE_position.WAAH_high, al
	call	markDirty
notDeleteFirst:
	ornf	flags, mask URF_NEED_COALESCE or mask URF_UPDATE_UI
toRunLoop:
	jmp	runLoop
notCase3:

	; *** case 4: run crosses end of range
	;			CHAR_ATTR -> run.start = range.start + insCount
	;			PARA_ATTR -> change start of run to be the 
	;				 start of the next paragraph after the 
	;				 end of the range

	tstdw	deleteRange.VTR_start
	jz	toRunLoop
	test	flags, mask URF_PARA_ATTR_RUN
	jnz	extendRangeToNextPP
	call	RunArrayPrevious
	movdw	dxax, deleteRange.VTR_start		;added 8/22/92
	jmp	addInsCountAndStore

	; *** case 4F (the ....ed part)
	;	The run contains the end of the range

extendRangeToNextPP:
	ornf	flags, mask URF_UPDATE_UI

	; We have a run that crosses the end of the range being deleted.  We
	; need to move the start of the run forward to the start of the next
	; paragraph (after any text that we've inserted).
	; we want to start looking for the end of the paragraph at the end
	; of the range to be deleted

	movdw	dxax, deleteRange.VTR_start
	push	si, ds				;save position in run
	call	loadObject
	call	TSL_IsParagraphStart		;carry set if so
	movdw	dxax, deleteRange.VTR_end
	jc	extendCommon
	call	TSL_FindParagraphEnd		;carry set if end of text
	pushf
	incdw	dxax				;point after CR
	popf
	jnc	extendCommon
	mov	dx, TEXT_ADDRESS_PAST_END_HIGH
	mov	ax, TEXT_ADDRESS_PAST_END_LOW
extendCommon:
	pop	si, ds

	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH
	jz	doDelete
	pushdw	dxax
	call	RunArrayPrevious
	popdw	dxax
	call	markDirty
	mov	ds:[si].TRAE_position.WAAH_low, ax
	mov	ds:[si].TRAE_position.WAAH_high, dl

	; if we have extended the run so that it reaches the next
	; paragraph then we don't need the run and we should delete it

	cmpdw	dxax, nextRunPosition
	LONG jz	doDeleteAfterMoveBack

	; we have computed the position, now we have to adjust it for the
	; number of characters that we are deleting

	subdw	dxax, delCount
	cmpdw	dxax, deleteRange.VTR_start
	jz	toStorePosition		; only add if ax != change position
	adddw	dxax, insCount
toStorePosition:
	jmp	storePosition

;-------

doneWithRuns:

	call	RunArrayUnlock
	call	loadObject
	mov	bx, runOffset

	test	flags, mask URF_NEED_COALESCE
	jz	noCoalesce
	call	CoalesceRun			;dxax = last run
	movdw	runPosition, dxax
noCoalesce:

	; if (insertion token) then change inserted text

	cmp	bx, offset VTI_paraAttrRuns
	LONG jz	afterInsertionToken
	clr	dx
	call	ClearInsertionElement
	cmp	bx, CA_NULL_ELEMENT
	jz	afterInsertionToken
	tstdw	insCount
	jnz	useToken

	; we are biffing an insertion token, we must update the UI

	ornf	flags, mask URF_UPDATE_UI
	jmp	biffToken

useToken:
	push	bx				;save token
	movdw	dxax, deleteRange.VTR_start
	movdw	modifyRange.VTR_start, dxax

	; if we are changing the character attributes at the end of a line
	; then change the CR also

	test	flags, mask URF_PARA_ATTR_RUN
	jnz	noInsertionTokenCharAttrAdjust
	call	TSL_IsParagraphEnd		;carry set if end of PP
						;zero set if end of text
	jnc	noInsertionTokenCharAttrAdjust
	jz	noInsertionTokenCharAttrAdjust
	incdw	dxax
noInsertionTokenCharAttrAdjust:
	adddw	dxax, insCount

	test	flags, mask URF_MIDDLE
	jnz	notAtEnd
	clr	ax
	movdw	dxax, TEXT_ADDRESS_PAST_END
notAtEnd:
	movdw	modifyRange.VTR_end, dxax

	pop	ax				;ax = token
	push	ax

;	We can't let ModifyRun do its own undo for this change, as
;	it creates runs *as they should be after the replace*.

	mov	bx, runOffset
	clr	cx				;callback (use ax as token)
	push	bp
	lea	bp, modifyRange
	call	ModifyRunWithoutUndo
	pop	bp

	movdw	runPosition, dxax
	pop	bx				;bx = token

biffToken:
	push	bx
	mov	bx, runOffset
	call	RunArrayLock
	pop	bx
	call	RemoveElement
	call	RunArrayUnlock
	call	loadObject

afterInsertionToken:

	; set carry if UI should be updated

	test	flags, mask URF_UPDATE_UI
	jz	noUpdateUI
	tstdw	delCount
	clc
	jz	noUpdateUI
	stc
noUpdateUI:

	; Note that we can't call ECCheckRun here since it relies on the
	; size of the text which has not been updated yet

	movdw	dxax, runPosition		;return last run
	.leave
	pop	bx
	ret

;---

loadObject:
	push	bx
	mov	bx, object.handle
	call	MemDerefDS
	mov	si, object.chunk
	pop	bx
	retn

;---

markDirty:
	push	ax
	mov	ax, ds:LMBH_handle
	cmp	ax, lastBlockDirtied
	jz	skipDirty
	mov	lastBlockDirtied, ax
	call	RunArrayMarkDirty
skipDirty:
	pop	ax
	retn

UpdateRun	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateGraphicRun

DESCRIPTION:	Update a run structure to reflect a text replace operation

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object

	di - UpdateRunFlags
	ss:bp - VisTextReplaceParameters, these fields used:
		VTRP_range
		VTRP_insCount

RETURN:
	dxax - last run position

DESTROYED:
	cx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

UpdateGraphicRun	proc	near
	class	VisTextClass

	push	bx
	push	ds:[LMBH_handle], si

EC <	call	T_AssertIsVisText					>

	movdw	dxax, ss:[bp].VTRP_range.VTR_end
	subdw	dxax, ss:[bp].VTRP_range.VTR_start
	mov	bx, bp
	clr	cx

insCount	local	dword	\
		push	ss:[bx].VTRP_insCount.high, \
			ss:[bx].VTRP_insCount.low
delCount	local	dword	\
		push	dx, ax
insPosition	local	dword	\
		push	ss:[bx].VTRP_range.VTR_start.high, \
			ss:[bx].VTRP_range.VTR_start.low

runPosition	local	dword	\
		push	cx, cx
lastBlockDirtied local	hptr	\
		push	cx
rangeEnd	local	dword
vmfile		local	word
	.enter

	mov	cx, OFFSET_FOR_GRAPHIC_RUNS
	call	DoUpdateRunUndo
	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
EC <	call	ECCheckRun						>

	call	T_GetVMFile			; bx = VM file
	mov	vmfile, bx


	; first deal with deletion

	movdw	dxax, delCount
	adddw	dxax, insPosition
	movdw	rangeEnd, dxax

	movdw	dxax, insPosition
	call	GetGraphicRunForPositionLeft	;ds:si = first element
						;dx.ax = position, bx = token
						;cx = # consecutive

topLoop:
	call	LoadRegsFromRun

	; ds:si = graphic run element
	; dxax = position after last deleted charater

	; case 0: at the end -- done

	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH
	jz	endLoop

	movdw	runPosition, dxax

	; case 1: deletion raange ends before start of run -- update the
	;	  position in the run to account for insert/delete

	cmpdw	dxax, rangeEnd
	jb	notCase1

	movdw	dxax, insCount			;calculate change
	subdw	dxax, delCount
	add	ds:[si].TRAE_position.WAAH_low, ax
	adc	ds:[si].TRAE_position.WAAH_high, dl
	adddw	runPosition, dxax
	call	markDirty
next:
	call	RunArrayNext
	jmp	topLoop

	; case 2: the deletion starts before this run -- delete this run (since
	; we already know that the deletion ends after this run)

	; case 3: the deletion starts after this run, loop

notCase1:
	cmpdw	dxax, insPosition
	jb	next

	; case 2 here...

	mov	bx, vmfile
	call	RunArrayDelete			;Nuke this run.
	jmp	topLoop				;Loop to check next one.

endLoop:
	call	RunArrayUnlock

	movdw	dxax, runPosition
	.leave

	pop	bx, si
	call	MemDerefDS
	pop	bx
	ret

;---

markDirty:
	push	ax
	mov	ax, ds:LMBH_handle
	cmp	ax, lastBlockDirtied
	jz	skipDirty
	call	RunArrayMarkDirty
skipDirty:
	pop	ax
	retn

UpdateGraphicRun	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CoalesceRun

DESCRIPTION:	Coalesce a run array by removing redundant elements

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset of run

RETURN:
	dxax - last run position

DESTROYED:
	cx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

CoalesceRun	proc	far	uses bx, si, ds
	class	VisTextClass

lastToken	local	word
lastPos		local	dword
	.enter

EC <	call	T_AssertIsVisText					>
EC <	cmp	bx, OFFSET_FOR_GRAPHIC_RUNS				>
EC <	ERROR_Z	CANNOT_COALESCE_GRAPHICS_RUNS				>

	call	RunArrayLock
topLoopReload:
	call	LoadRegsFromRun			;dx.ax = pos, bx = token
topLoop:
	mov	lastToken, bx
	movdw	lastPos, dxax

	call	RunArrayNext
next:
	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH
	jz	done

	cmp	bx, lastToken
	jz	removeHere
	cmpdw	dxax, lastPos
	jnz	topLoop

	; two runs at the same position -- remove the *first* one

	call	RunArrayPrevious
	call	RunArrayDelete
	jmp	topLoopReload

removeHere:
	call	RunArrayDelete
	call	LoadRegsFromRun			;dx.ax = pos, bx = token
	jmp	next

done:
	call	RunArrayUnlock

	movdw	dxax, lastPos

	.leave
	ret

CoalesceRun	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TA_ExtendedStyleEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate certain extended styles to a callback.

CALLED BY:	Utility
PASS:		*ds:si	= Instance
		bp	= Information for callback
		On stack:	(Pushed in this order)
			word	VisTextExtendedStyle
			word	ExtendedStyleCallbackType
			dword	rangeEnd
			dword	Start offset to look from
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Callback API:
	Pass:
		ss:bx	- VisTextRange
		ss:cx	- VisTextCharAttr
		di	- gstate
		bp	- Same as passed to ExtendedStyleEnum
	Return:
		none
	Can destroy:
		ax, bx, cx, dx, di, dp

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextBorder segment resource

TA_ExtendedStyleEnum	proc	near	\
				enumRange:VisTextRange,
				callback:nptr.near,
				styleBit:VisTextExtendedStyles
					uses	ax, bx, cx, dx, di, si, ds
textObject	local	fptr		push ds, si
styleRange	local	VisTextRange
currentState	local	word
charAttr	local	VisTextCharAttr
charAttrToPass	local	VisTextCharAttr
	class	VisTextClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS
	LONG jz	singleCharAttr

	mov	currentState, 0

	; find the first run in the range

	movdw	styleRange.VTR_start, enumRange.VTR_start, ax

	mov	bx, offset VTI_charAttrRuns
	movdw	dxax, enumRange.VTR_start
	call	FarGetRunForPosition		;ds:si = TextRunArrayElement
						;cx = count, di = data

getStartElement:
	push	bp
	lea	bp, charAttrToPass
	call	GetElement
	pop	bp

findStyleLoop:
	;
	; dx.ax	= End of the current style run.
	; charAttr = Attributes for the current run.
	; charAttrToPass = Attributes for the first style run we saw.
	;
	cmpdw	dxax, enumRange.VTR_end
	jae	checkStateDone

	; get the attribute structure

	push	bp
	lea	bp, charAttr
	call	GetElement
	pop	bp

	; has the state changed ? (also set new state)

	push	ax
	;
	; Set ax = 1 if the next run contains the style bit that 
	; we're interested in
	;
	mov	ax, charAttr.VTCA_extendedStyles
	and	ax, styleBit

	;
	; Set ax to the old state (1 if contains style, 0 if not)
	; Set the current state to reflect whether the current run contains
	; the style we're interested in.
	;
	xchg	ax, currentState
	
	;
	; Set ax to 1 if the state has changed from the old to the new, and
	; 0 if the state has not changed (ie: both runs have the same extended
	; style).
	;
	xor	ax, currentState
	pop	ax
	
	;
	; Z=1 (jz) if both the previous run and the current run contain the
	; same extended style.
	;
	jnz	stateChanged
	
	;
	; The state has not changed. Normally we'd just branch in order to
	; accumulate the runs into one big run. This works for things like
	; boxed and button text, but it doesn't work for the background
	; color. The background color is considered to have changed any time
	; that the color changes.
	;
	; Though the two runs we've examined contain the same extended-style
	; state for the style we're interested in, that doesn't mean that 
	; this style is actually set. It may be that we're looking at two 
	; runs which are the same, neither having the extended style we're 
	; interested in.
	;
	tst	currentState
	jz	next				; Branch if run is not on

	;
	; The runs are the same, and they both have the extended style we're
	; interested in *set*. We want to check to see if the bit in question
	; is the background color bit. If it is not then we can just accumulate
	; this into the previous run to create one large one.
	;
	test	styleBit, mask VTES_BACKGROUND_COLOR
	jz	next				; Branch if not background color

	;
	; It's a background color. This means that we need to check to see
	; the background color is different in the previous state and the
	; current state. If it is, we need to force this run to be drawn and
	; then continue with the next run.
	;
	call	CompareBackgrounds		; z=1 (jz) if they are the same
	jz	next				; no -- keep looping

	;
	; The type of extended style has not changed, but unfortunately the
	; state really has. We need to call the callback here.
	;
	pushdw	dxax				; save start of next run
	call	callCallback			; draw the style
	popdw	dxax				; restore start of next run
	jmp	setStartAndLoop	

stateChanged:
	; state has changed, has it changed from ON to OFF ?

	tst	currentState
	jnz	setStartAndLoop			; no - OFF to ON - look for end

	; the state has changed from ON to OFF -- call the callback

	call	callCallback

next:
	call	FarRunArrayNext
	jmp	findStyleLoop

	; set the start of the range 

setStartAndLoop:
	movdw	styleRange.VTR_start, dxax
	jmp	getStartElement

checkStateDone:
	tst	currentState
	jz	done
	call	callCallback
	
done:
	call	FarRunArrayUnlock

exit:
	.leave
	ret	@ArgSize

	; the text object only has a single character attribute, so call
	; the callback passing the range for the entire line

singleCharAttr:
	push	bp
	lea	bp, charAttrToPass
	call	GetSingleCharAttr
	pop	bp

	mov	ax, charAttrToPass.VTCA_extendedStyles
	and	ax, styleBit
	jz	exit
	mov	currentState, ax

	movdw	styleRange.VTR_start, enumRange.VTR_start, ax
	movdw	dxax, enumRange.VTR_end
	call	callCallback
	jmp	exit

;---

	; dxax = end of range

callCallback:

	; store the range end first

	cmpdw	dxax, enumRange.VTR_end
	jbe	10$
	movdw	dxax, enumRange.VTR_end
10$:
	movdw	styleRange.VTR_end, dxax

	push	bx, cx, si, di, ds, bp
	movdw	dssi, textObject
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VTI_gstate
	lea	bx, styleRange			; ss:bx <- VisTextRange
	lea	cx, charAttrToPass		; ss:cx <- VisTextCharAttr
	mov	dx, callback			; dx = callback
	mov	bp, ss:[bp]			; Restore passed bp
	call	dx				; Call the callback
	pop	bx, cx, si, di, ds, bp
	retn

TA_ExtendedStyleEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareBackgrounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two backgrounds to see if they're the same

CALLED BY:	TA_ExtendedStyleEnum
PASS:		ss:bp	= Inheritable stack frame
RETURN:		Z	= 1 (jz) if the backgrounds are the same
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/10/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareBackgrounds	proc	near
	uses	ax
	.enter	inherit	TA_ExtendedStyleEnum
	;
	; Check the colors first.
	;
		CheckHack <size ColorQuad eq size dword>
	cmpdw	charAttrToPass.VTCA_bgColor, charAttr.VTCA_bgColor, ax
	jne	done
	
	;
	; Check the gray-screen.
	;
	mov	al, charAttrToPass.VTCA_bgGrayScreen
	cmp	al, charAttr.VTCA_bgGrayScreen
	jne	done
	
	;
	; Check the pattern
	;
	mov	ax, {word} charAttrToPass.VTCA_bgPattern
	cmp	ax, {word} charAttr.VTCA_bgPattern

	;;; Flags set for the compare
done:
	.leave
	ret
CompareBackgrounds	endp

TextBorder ends

;------------------------------------------------------------------------------
;		ERROR CHECKING
;------------------------------------------------------------------------------

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckRun

DESCRIPTION:	Check a run for validity

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset of run

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

if	ERROR_CHECK

TextEC segment resource

ECCheckParaAttrPositions	proc	far	uses ax, bx
	class	VisTextClass
	.enter
	pushf
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VTI_storageFlags, mask VTSF_MULTIPLE_PARA_ATTRS
	jz	done
	mov	ax, TRUE
	mov	bx, offset VTI_paraAttrRuns
	call	ECCheckRunCommon
done:
	popf
	.leave
	ret

ECCheckParaAttrPositions	endp


;---

ECCheckRun	proc	far	uses ax
	.enter
	mov	ax, FALSE
	call	ECCheckRunCommon
	.leave
	ret

ECCheckRun	endp

;---

ECCheckRunCommon	proc	far	uses	bx, cx, dx, si, di, bp, ds
	class	VisTextClass
tsize	local	dword
lastPos	local	dword
runOff	local	word
obj	local	fptr
rflag	local	word
	.enter
	pushf

	movdw	obj, dssi
	mov	rflag, ax

	call	TS_GetTextSize			;dx.ax = size
	movdw	tsize, dxax
	mov	lastPos.high, 0xffff
	mov	runOff, bx

	call	FarRunArrayLock			;ds:si = run element
	call	ECCheckRunsElementArray

	cmp	bx, offset VTI_charAttrRuns
	jz	checkFirst
	cmp	bx, offset VTI_paraAttrRuns
	jz	checkFirst
	cmp	bx, OFFSET_FOR_TYPE_RUNS
	jnz	dontCheckFirst
checkFirst:
	tst	ds:[si].TRAE_position.WAAH_high
	ERROR_NZ	TEXT_RUN_FIRST_POSITION_NOT_0
	tst	ds:[si].TRAE_position.WAAH_low
	ERROR_NZ	TEXT_RUN_FIRST_POSITION_NOT_0

dontCheckFirst:
	call	LoadRegsFromRunFar

topLoop:

	; dx.ax = run position

	cmp	ax, TEXT_ADDRESS_PAST_END_LOW
	jnz	notEnd
	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH
	jz	endLoop
notEnd:

	; OK, we're not on the last run. Check for legal position.

	cmpdw	dxax, tsize
	ERROR_A	TEXT_RUN_AFTER_END_OF_TEXT

	cmp	lastPos.high, 0xffff
	jz	next

	cmpdw	dxax, lastPos
	ERROR_Z	TEXT_RUN_CONSECUTIVE_ELEMENTS_EQUAL
	ERROR_B	TEXT_RUN_CONSECUTIVE_ELEMENTS_SWAPPED

	; if this is a ruler run then ensure that it is at a legal position

	tst	rflag
	jz	next
	cmp	runOff, offset VTI_paraAttrRuns
	jnz	next
	tstdw	dxax
	jz	next
	pushdw	dssi
	movdw	dssi, obj
	call	TSL_IsParagraphStart
	ERROR_NC	TEXT_PARA_ATTR_RUN_NOT_AT_PARAGRAPH_BOUNDRY
	popdw	dssi

next:
	movdw	lastPos, dxax
	call	FarRunArrayNext
	jmp	topLoop

endLoop:
	call	FarRunArrayUnlock

	popf
	.leave
	ret

ECCheckRunCommon	endp
;
;	ROUTINE: ECCheckRunOffset
;
;	Pass: cx = run offset
;	Return: nothing
;	Destroyed: nothing
;

ECCheckRunOffset	proc	far
	class	VisTextClass
	cmp	cx, offset VTI_charAttrRuns				
	jz	10$							
	cmp	cx, offset VTI_paraAttrRuns				
	jz	10$							
	cmp	cx, OFFSET_FOR_GRAPHIC_RUNS				
	jz	10$							
	cmp	cx, OFFSET_FOR_TYPE_RUNS				
	ERROR_NZ	ILLEGAL_RUN_TYPE				
10$:
	ret
ECCheckRunOffset	endp

TextEC ends

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TA_DecrementRefCountsFromHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine decrements the reference counts for the elements
		associated with the run in the passed array.

CALLED BY:	GLOBAL
PASS:		bx.di - Huge array containing TextRunArrayElements
		dx - run offset
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, ds, si, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TA_DecrementRefCountsFromHugeArray	proc	far
	.enter

;	Lock down the first TextRunArrayElement

	push	dx, ds, si

	clrdw	dxax			;Get a ptr to the first run
	call	HugeArrayLock
	segmov	es, ds			;ES:BP <- ptr to TextRunArrayElement
	mov	bp, si			; in huge array.

	pop	dx, ds, si

;	We lock down the associated run array - we don't actually care 
;	about the runs, but we have to lock down the runs to access the
;	elements.

	call	T_GetVMFile
	push	bx

	mov	bx, dx			;BX <- run offset
	call	RunArrayLock		;DS:SI <- element array
					;DI <- token to pass to other array
					; routines
	pop	cx
next:

;	Remove the reference from the element.

	mov	bx, es:[bp].TRAE_token
	call	RemoveElement

;	Go to the next element in the list

	dec	ax			;If we've reached the last element
	jz	nextBlock		; in this huge array block, branch
	add	bp, size TextRunArrayElement
	jmp	next
nextBlock:
	segxchg	ds, es
	xchg	si, bp
	call	HugeArrayNext
	segxchg	ds, es
	xchg	si, bp
	tst	ax			;Branch if there are more elements
	jnz	next

;	Unlock the huge array and the run array

	call	RunArrayUnlock
	segmov	ds, es
	call	HugeArrayUnlock
	.leave
	ret
TA_DecrementRefCountsFromHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TA_DeleteRunsInRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the runs in the passed range

CALLED BY:	GLOBAL
PASS:		ss:bp - VisTextRange
		cx - run offset
		*ds:si - VisText object
RETURN:		nothing
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TA_DeleteRunsInRange	proc	far	uses	ax,bx,cx,dx,bp,di
	class	VisTextClass
	.enter
EC <	call	T_AssertIsVisText					>
	mov	bx, bp
	call	CheckIfRunsInRangeForUndo	;If no runs in this range, exit
	tst	ax
	jz	exit
	
	push	cx				;Save run offset

	call	TU_CreateUndoForRunsInRange

TA_DRIR_deleting label near			;Used by swat
ForceRef	TA_DRIR_deleting
	push	ds:[LMBH_handle], si

;	Now that we are deleting runs, the "last run" may change, so nuke
;	the cached information.

	mov	ax, TEMP_VIS_TEXT_CACHED_RUN_INFO
	call	ObjVarDeleteData


	movdw	dxax, ss:[bp].VTR_start
	mov	bx, cx
	call	GetRunForPosition	;DX.AX = offset, bx = token
loopTop:

;	For each element in the run {
;		if (element.position > rangeStart)
;			continue;
;		else if (element.position > rangeEnd)
;			return()
;		else if (element.position == TEXT_ADDRESS_PAST_END)
;			return()
;		else  /* rangeEnd > element.position > range Start
;			Delete this element
;	}

	cmpdw	dxax, ss:[bp].VTR_start
	jb	noDelete
	cmpdw	dxax, ss:[bp].VTR_end
	ja	TA_DRIR_done
	cmpdw	dxax, TEXT_ADDRESS_PAST_END
	je	TA_DRIR_done
TA_DRIR_doingDelete label near				;USED BY SWAT
ForceRef	TA_DRIR_doingDelete

	call	RunArrayDelete		;Delete the element and goto the next
	call	LoadRegsFromRun		; one
	jmp	loopTop
noDelete:
	call	RunArrayNext
	jmp	loopTop
TA_DRIR_done	label	near				;USED BY SWAT
	call	RunArrayUnlock
	pop	bx, si
	call	MemDerefDS

;	Invalidate this change

	pop	cx
	cmp	cx, offset VTI_paraAttrRuns
	jnz	doInval

;	If changing para attrs, we need to change bounds of inval

	mov	bx, mask VTRC_PARAGRAPH_CHANGE \
		or mask VTRC_PARA_ATTR_BORDER_CHANGE
	call	TA_GetTextRange	
doInval:
	call	ReflectChange
exit:
	.leave
	ret
TA_DeleteRunsInRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TA_RestoreRunsFromHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore runs from the huge array

CALLED BY:	GLOBAL
PASS:		bx.di - huge array with runs in it
		cx - run offset
		*ds:si - VisText object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TA_RestoreRunsFromHugeArray	proc	far	uses	ax, bx, cx, dx, si,di
	class	VisTextClass
	numRuns	local	dword
	curRun	local	fptr.TextRunArrayElement
	runOff	local	word
	theRange	local	VisTextRange
	.enter
EC <	call	T_AssertIsVisText					>

	push	ds:[LMBH_handle], si
	pushdw	dssi
	mov	runOff, cx

TA_RRFHA_start	label near	;USED BY SWAT
ForceRef	TA_RRFHA_start
	call	HugeArrayGetCount
EC <	tstdw	dxax							>
EC <	ERROR_Z	UNDO_INFO_CONTAINS_NO_RUNS				>
	decdw	dxax
	movdw	numRuns, dxax

;	Lock down the first element to add

	clrdw	dxax
	call	HugeArrayLock	;DS:SI <- huge array
	movdw	curRun, dssi

;	Get a pointer to the item to insert before

	mov	ax,  ds:[si].TRAE_position.WAAH_low
	mov	dl,  ds:[si].TRAE_position.WAAH_high
	popdw	dssi

	movdw	theRange.VTR_start, dxax
	mov	bx, runOff
	call	GetRunForPosition

;	We want to get a pointer to the item *after* the first item we
;	want to restore. Usually, GetRunForPosition returns the
;	run *before* the passed position, but not always (for example,
;	the previous run may have been deleted by a call to
;	TA_DeleteRunsInRange).

	cmpdw	dxax, theRange.VTR_start	;
	ja	insert
addNext:
	call	RunArrayNext		;DS:SI <- ptr to array item to insert
					; before.
insert:

;	Insert the run array element from the huge array

	call	getRegsFromHugeArray
	call	RunArrayInsert

	subdw	numRuns,1		;Loop until no more items to add
	jnc	addNext
	call	RunArrayUnlock

	movdw	dsdi, curRun
	mov	ax, ds:[di].TRAE_position.WAAH_low
	mov	theRange.VTR_end.low, ax
	mov	al, ds:[di].TRAE_position.WAAH_high
	clr	ah
	mov	theRange.VTR_end.high, ax
	call	HugeArrayUnlock

	pop	bx, si
	call	MemDerefDS		;*DS:SI <- text object

;	Coalesce the runs and update the cached run information

	mov	bx, runOff		;Coalesce the runs (don't coalesce the
					; graphic runs - there is no need)
	cmp	bx, OFFSET_FOR_GRAPHIC_RUNS
	je	graphic
	call	CoalesceRun
	call	UpdateLastRunPositionByRunOffset
	jmp	TA_RRFHA_done
graphic:
	mov	ax, TEMP_VIS_TEXT_CACHED_RUN_INFO
	call	ObjVarDeleteData
TA_RRFHA_done	label	near				;NEEDED FOR SWAT
EC <	call	ECCheckRun						>


	push	bp
	mov	cx, runOff
	lea	bp, theRange

;	Create an undo action for these runs

	call	TU_CreateUndoForRunModification

;	Invalidate the range over which we changed the runs

	cmp	cx, offset VTI_paraAttrRuns
	jnz	noRangeChange

;	If changing para attrs, we need to change bounds of inval

	mov	bx, mask VTRC_PARAGRAPH_CHANGE \
		or mask VTRC_PARA_ATTR_BORDER_CHANGE
	call	TA_GetTextRange	

noRangeChange:

	call	ReflectChange
	pop	bp
	.leave
	ret

getRegsFromHugeArray:
	push	ds, si
	movdw	dssi, curRun
	mov	ax,  ds:[si].TRAE_position.WAAH_low
	mov	dl,  ds:[si].TRAE_position.WAAH_high
	mov	bx, ds:[si].TRAE_token
	pushdw	dxax
TA_RRFHA_beforeNext label near			;USED BY SWAT
ForceRef	TA_RRFHA_beforeNext
	call	HugeArrayNext
	movdw	curRun, dssi
	popdw	dxax
	pop	ds, si
	retn
TA_RestoreRunsFromHugeArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfRunsInRangeForUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if there are any runs in the passed range

CALLED BY:	GLOBAL
PASS:		ss:bp - VisTextRange
		cx - run offset
		*ds:si - VisText object
RETURN:		ax = non-zero if there was a run in the range, and if the
		     object was undoable
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfRunsInRangeForUndoFar	proc	far
	call	CheckIfRunsInRangeForUndo
	ret
CheckIfRunsInRangeForUndoFar	endp
CheckIfRunsInRangeForUndo	proc	near	uses	dx, cx, ds, si, di, bx
	class	VisTextClass

;	If no undo, then don't create any undo actions

	clr	ax
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	test	ds:[di].VTI_features, mask VTF_ALLOW_UNDO
	pop	di
	jz	exit


;	If we are ignoring undo actions, don't create any.

	call	GenProcessUndoCheckIfIgnoring
	tst	ax
	mov	ax, 0			;Don't change to "clr"
	jnz	exit

	.enter
	mov	bx, cx
	movdw	dxax, ss:[bp].VTR_start
	call	GetRunForPosition
loopTop:
	cmpdw	dxax, TEXT_ADDRESS_PAST_END
	je	noRuns
	cmpdw	dxax, ss:[bp].VTR_start
	jae	doCheck
	call	RunArrayNext
	jmp	loopTop
doCheck:
	cmpdw	dxax, ss:[bp].VTR_end
	mov	ax, TRUE	;AX = TRUE if we found a run in the range
	jbe	done
noRuns:
	clr	ax		;Else, AX = FALSE
done:
	call	RunArrayUnlock
	.leave
exit:
	ret
CheckIfRunsInRangeForUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TA_AppendRunsInRangeToHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends all the runs in this range to the huge array.
		It also ups the reference counts on the tokens.

CALLED BY:	GLOBAL
PASS:		ss:bp - VisTextRange
		bx.di - Huge Array
		cx - run offset
RETURN:		nothing
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TA_AppendRunsInRangeToHugeArray	proc	far	uses	ax, bx, cx, dx, bp, di, si, ds
	xchg	bx, bp
	movdw	dxax, ss:[bx].VTR_start

.warn -unref_local
	harrayFile	local	hptr	\
			push	bp

	params		local	word	\
			push	bx

	harray		local	word	\
			push	di
.warn @unref_local
	runOffset	local	word	\
			push	cx

	endOffset	local	dword 	\
			push	ss:[bx].VTR_end.high, ss:[bx].VTR_end.low

	startOffset	local	dword	\
			push	dx, ax
	.enter

	mov	bx, runOffset
	call	GetRunForPosition	;DX.AX = offset, bx = token
EC <	cmpdw	dxax, endOffset						>
EC <	ERROR_A	NO_RUNS_IN_RANGE					>
loopTop:
	cmpdw	dxax, TEXT_ADDRESS_PAST_END
	je	TA_ARIRTHA_done
	cmpdw	dxax, startOffset
	jb	toNext

;	Increment the associated token's reference count so it does not go
;	away if this run gets deleted. It gets decremented when this undo
;	item is freed.

	call	ElementAddRef

	call	AddItemToHugeArray
toNext:
	call	RunArrayNext
	cmpdw	dxax, endOffset
	jbe	loopTop
TA_ARIRTHA_done label near
	call	RunArrayUnlock
	.leave
	ret
TA_AppendRunsInRangeToHugeArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddItemToHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends the passed TextRunArrayElement to the file

CALLED BY:	GLOBAL
PASS:		dx.ax - TRAE_element
		bx - token
		ss:bp - inherited stack frame
RETURN:		nada
DESTROYED:	dx, ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddItemToHugeArray	proc	near	uses	cx, bx, bp, si, di
	.enter	inherit	TA_AppendRunsInRangeToHugeArray
	sub	sp, size TextRunArrayElement+1
	mov	si, sp
	mov	ss:[si].TRAE_token, bx
	mov	ss:[si].TRAE_position.WAAH_low, ax
	mov	ss:[si].TRAE_position.WAAH_high, dl

	mov	bx, harrayFile
	mov	di, harray

	mov	bp, ss		;BP:SI <- data
	mov	cx, 1		;Add one element
	call	HugeArrayAppend

	add	sp, size TextRunArrayElement+1
	.leave
	ret
AddItemToHugeArray	endp


TextAttributes	ends
