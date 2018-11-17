COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genItemGroup.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenItemGroupClass	Item group object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

DESCRIPTION:
	This file contains routines to implement the item group class

	$Id: genItemGroup.asm,v 1.1 97/04/07 11:44:40 newdeal Exp $

------------------------------------------------------------------------------@

; see documentation in /staff/pcgeos/Library/User/Doc/GenItemGroup.doc
	
UserClassStructures	segment resource

; Declare the class record

	GenItemGroupClass

method	GenBooleanGroupGetBooleanOptr, GenItemGroupClass,
				       MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR

UserClassStructures	ends

;---------------------------------------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenItemGroupClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es
REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

GenItemGroupBuild	method	GenItemGroupClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_ITEM_GROUP
	GOTO	GenQueryUICallSpecificUI
GenItemGroupBuild	endm





COMMENT @----------------------------------------------------------------------

		GenItemGroupRelocOrUnReloc

DESCRIPTION:	relocate or unrelocate dynamic list

	SPECIAL NOTE:  This routine is run by the application's
	process thread.

PASS:	*ds:si - instance data

	ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE

	cx - handle of block containing relocation
	dx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE
	bp - data to pass to ObjRelocOrUnRelocSuper

RETURN:
	carry - set if error
	bp - unchanged


RETURN:	carry clear to indicate successful relocation!

ALLOWED TO DESTROY:
	ax, cx, dx
	bx, si, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version

------------------------------------------------------------------------------@

GenItemGroupRelocOrUnReloc	method GenItemGroupClass, reloc
				; We only need to handle unrelocation, where
				; this object is about to go out to a state 
				; file.
	cmp	ax, MSG_META_UNRELOCATE
	je	done

	;
	; Allow the app writer to specify an identifier but leave the number
	; of selections at 0.   We'll adjust the number of selections to 
	; one here.  -cbh 2/23/93
	;
	tst	ds:[di].GIGI_numSelections
	jnz	done		
	cmp	ds:[di].GIGI_selection, GIGS_NONE
	je	done
	inc	ds:[di].GIGI_numSelections

done:
	clc
	mov	di, offset GenItemGroupClass
	call	ObjRelocOrUnRelocSuper
	ret

GenItemGroupRelocOrUnReloc	endm


Build ends


BuildUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupReplaceParams

DESCRIPTION:	Replaces any generic instance data paramaters that match
		BranchReplaceParamType

PASS: 		*ds:si - instance data
		es - segment of MetaClass
	
		ax - MSG_GEN_BRANCH_REPLACE_PARAMS
	
		dx	- size BranchReplaceParams structure
		ss:bp	- offset to BranchReplaceParams


RETURN:		nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


GenItemGroupReplaceParams	method	GenItemGroupClass,
					MSG_GEN_BRANCH_REPLACE_PARAMS
	cmp	ss:[bp].BRP_type, BRPT_OUTPUT_OPTR	; Replacing output OD?
	je	replaceOD		; 	branch if so
	jmp	short done

replaceOD:
					; Replace action OD if matches
					;	search OD

	mov	ax, MSG_GEN_ITEM_GROUP_SET_DESTINATION
	mov	bx, offset GIGI_destination
	call	GenReplaceMatchingDWord
done:
	mov	ax, MSG_GEN_BRANCH_REPLACE_PARAMS
	mov	di, offset GenItemGroupClass
	GOTO	ObjCallSuperNoLock

GenItemGroupReplaceParams	endm

BuildUncommon ends

;---

ItemCommon segment resource

IC_DerefGenDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	ret	
IC_DerefGenDI	endp

IC_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret	
IC_ObjCallInstanceNoLock	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSetNoneSelected -- 
		MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED for GenItemGroupClass

DESCRIPTION:	Sets none selected.

PASS:		*ds:si 	- instance data
		dx 	- non-zero if indeterminate

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@
GenItemGroupSetNoneSelected	method dynamic	GenItemGroupClass,
				MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	;
	; Copy old selections to update list.
	; 
	clr	ax				;no new selections
	call	CalcUpdateListSize		;ax <- size of update buffer
	clr	bp				; assume zero-sized
	tst	ax
	jz	setSelection

	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	mov	bp, bx				; bp = block handle
	jc	quit

	clr	ax
	call	CopyCurSelectionsToUpdateList

setSelection:
	push	ax, bp
	clr	ax				;num selections
	mov	bp, GIGS_NONE			;selection
	call	SetSingleSelection
	pop	ax, bp				;restore these
	jnc	exit				;no change, exit

	;
	; Call specific UI to update old selections.
	; ^hbp -- list of old selections, ax -- size of list
	;
	push	bp
	call	UpdateSpecificObject
	pop	bp
exit:
	tst	bp
	jz	quit		
	mov	bx, bp
	call	MemFree
quit:
	Destroy ax, cx, dx, bp
	ret
GenItemGroupSetNoneSelected	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetSingleSelection

SYNOPSIS:	Finishes setting a single (or no) selection.  Sets the 
		indeterminate flag, number of selections, and selection if
		needed, nuking the old selections chunk if there were 
		previously multiple selections. Dirties the object if needed.
		Calls superclass to update object if needed.

CALLED BY:	GenItemGroupSetNoneSelected, GenItemGroupSetSingleSelection

PASS:		*ds:si -- object
		ax     -- num selections to set
		bp     -- selection
		dx     -- non-zero if we're to set the indeterminate flag

RETURN:		carry set if any change

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/21/92		Initial version

------------------------------------------------------------------------------@

SetSingleSelection	proc	far
	class	GenItemGroupClass

	;
	; First, remove the selection chunk if there were more than 1 selection
	; last time around.
	; 
	call	IC_DerefGenDI
	cmp	ds:[di].GIGI_numSelections, 1
	jbe	10$
	push	ax
	mov	ax, ds:[di].GIGI_selection
	call	ObjFreeChunk			;can't use LMemFree, since
						; chunk might come from resource
	pop	ax
10$:
	mov	cx, dx				;indeterminate flag in cx
	clr	dx				;nothing changed yet
	FALL_THRU	SetSelection

SetSingleSelection	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetSelection

SYNOPSIS:	Finishes setting one or more selections.   Set the
		number of selections, and selection if needed.
		Assumes conversion to or from a selections chunk
		is complete, and that setting of any indeterminate flag is
		done.  Dirties the object if needed.  Calls superclass to 
		update object if needed.

CALLED BY:	SetSingleSelection, GenItemGroupSetMultipleSelections

PASS:		*ds:si -- object
		ax     -- num selections to set
		bp     -- selection
		cx     -- non-zero if we're to set the indeterminate flag.
		dx     -- non-zero if we're already changed and should call
			  superclass to update

RETURN:		carry set if any change

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/21/92		Initial version

------------------------------------------------------------------------------@

SetSelection	proc	far
	class	GenItemGroupClass

	;
	; Set the indeterminate flag, if necessary.
	; 
	push	dx
	mov	dl, mask GIGSF_INDETERMINATE
	mov	bx, offset GIGI_stateFlags
	call	GenSetBitInByte
	pop	dx
	jnc	noIndChange			;didn't change things, branch
	dec	dx				;else set dirty flag
noIndChange:

	;
	; Clear the modified flag.
	;
	clr	cx
	push	dx
	mov	dl, mask GIGSF_MODIFIED
	call	GenSetBitInByte			;clear modified state
	pop	dx
	jnc	noModChange
	dec	dx				;else set dirty flag
noModChange:

	xchg	dx, bp				;selection in dx, state change
						;  flag in bp
	mov	cx, ax				;num selections in cx
	mov	bx, offset GIGI_selection
	call	GenSetDWord			;set new selection
	jnc	noSelChange			;nothing changed, branch
	dec	bp				;else set dirty flag
noSelChange:
	tst	bp
	jz	exit				;no change, exit, carry clear
	stc					;else set carry
exit:
	ret
SetSelection	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	CopyCurSelectionsToUpdateList

SYNOPSIS:	Takes all current selections and adds them to an update list.

CALLED BY:	OLItemGroupSetNoneSelected
		OLItemGroupSetSingleSelection
		OLItemGroupSetMultipleSelections

PASS:		*ds:si -- item group
		^hbp   -- buffer to use
		ax     -- size of buffer filled already (numItems * 2)

RETURN:		ax     -- updated for new items added

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/27/92		Initial version

------------------------------------------------------------------------------@
CopyCurSelectionsToUpdateList	proc	near
	uses	bx, cx, dx, bp, si, es
	class	GenItemGroupClass
	.enter
	;
	; Lock buffer containing items.
	;
	tst	bp				; if no buffer, there are no
	jz	quit				; possible updates, so we don't
						; do need to do anything (and we
						; won't lock a NULL handle)
						;   -Don 6/20/95
	push	ax
	mov	bx, bp
	call	MemLock
	mov	es, ax
	pop	ax				; pointer into list
	jc	quit

	mov	dx, ax
	mov	cx, es				; cx:dx = buffer
	call	IC_DerefGenDI
	mov	bp, ds:[di].GIGI_numSelections	;pass num selections
	push	ax
	call	GenItemGroupGetMultipleSelections
	mov	cx, ax				;return num selections
	shl	cx, 1				;double for buffer size
	pop	ax
	add	ax, cx				;add to size of buffer

	;
	; Unlock buffer block.
	;
	call	MemUnlock
quit:
	.leave
	ret
CopyCurSelectionsToUpdateList	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSetSingleSelection -- 
		MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION for GenItemGroupClass

DESCRIPTION:	Sets a single selection.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION

		cx -- identifier of the item to select
		dx -- non-zero if indeterminate

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@
GenItemGroupSetSingleSelection	method dynamic	GenItemGroupClass,
				MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	;
	; Copy old selections to update list, after making room for old
	; selections plus the new one.
	; 
	mov	ax, 1				;one new selection
	call	CalcUpdateListSize		;figure size for update list
	clr	bp				; assume zero-sized
	tst	ax
	jz	setSelection
	;
	; Allocate a block for the update list.
	;
	push	cx
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	pop	cx
	mov	bp, bx
	jc	quit
		
	clr	ax
	call	CopyCurSelectionsToUpdateList

setSelection:
	push	ax, bp
	mov	bp, cx				;selection
	mov	ax, 1				;num selections
	call	SetSingleSelection
	pop	ax, bp				;restore these

	jnc	exit				;no change, exit
	;
	; Call specific UI to update old and new selections.
	; ^hbp -- list of old selections, ax -- size of list
	;
	call	CopyCurSelectionsToUpdateList
updateAnyway::
	push	bp
	call	UpdateSpecificObject		
	pop	bp
exit:
	tst	bp
	jz	quit
	mov	bx, bp
	call	MemFree
quit:
	ret
GenItemGroupSetSingleSelection	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcUpdateListSize

SYNOPSIS:	Calculates a size for the update list, by adding the number
		of old and new selections.

CALLED BY:	GenItemGroupSetSingleSelection
		GenItemGroupSetNoneSelected
		GenItemGroupSetMultipleSelections

PASS:		ds:di -- item group  GenInstance
		ax    -- number of new selections

RETURN:		ax    -- buffer size needed.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/28/92		Initial version

------------------------------------------------------------------------------@

CalcUpdateListSize	proc	near
	class	GenItemGroupClass
	add	ax, ds:[di].GIGI_numSelections	;add new selections to old
	shl	ax, 1				;double for word offset
	ret
CalcUpdateListSize	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSetMultipleSelections -- 
		MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS for GenItemGroupClass

DESCRIPTION:	Sets multiple selections.

PASS:		*ds:si 	- instance data
		ax 	- MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS

		cx:dx	- buffer with the selections
		bp	- number of selections

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@
GenItemGroupSetMultipleSelections	method dynamic	GenItemGroupClass,
				MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS
	;
	; Copy old selections to update list, after making room for old
	; selections plus the new ones.
	; 
	mov	ax, bp				;number of new selections
	mov	bx, bp				;also in bx for safekeeping
	call	CalcUpdateListSize		;ax <- size for update list
	clr	bp				; assume zero-sized
	tst	ax
	jz	setSelections

	;
	;  Allocate block in which to hold selections.
	;
	push	bx, cx
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	mov	bp, bx				; block handle
	pop	bx, cx				; bx = #selections
						; cx:dx = buffer w/ selections
	jc	quit				; allocation failed

	clr	ax				; nothing filled so far
	call	CopyCurSelectionsToUpdateList

setSelections:
	push	ax, bp				; #filled + buffer handle
	mov	bp, bx				; bp = new number of selections

	call	SetMultiSelection		; go handle setting of the 
						;   selection

	pop	ax, bp				; restore these
	jnc	exit				; no change, exit

	;
	; Call specific UI to update old and new selections.
	; ^hbp -- list of old selections, ax -- size of list
	;
	call	CopyCurSelectionsToUpdateList
	push	bp
	call	UpdateSpecificObject
	pop	bp
exit:
	tst	bp
	jz	quit
	mov	bx, bp
	call	MemFree
quit:
	ret
GenItemGroupSetMultipleSelections	endm






COMMENT @----------------------------------------------------------------------

ROUTINE:	SetMultiSelection

SYNOPSIS:	Sets a selection from a selection list.

CALLED BY:	GenItemGroupSetMultipleSelections
		GenDynamicListRemoveItems

PASS:		*ds:si -- item group
		cx:dx  -- buffer containing the selections
		bp     -- number of selections

RETURN:		carry set if a change was made in the selection

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 7/92		Initial version

------------------------------------------------------------------------------@

SetMultiSelection	proc	far
	class	GenItemGroupClass
	;
	; First, see we're trying to set none or one selection, and do the
	; right thing if so.
	;
	cmp	bp, 1
	ja	multiSelections			;multi-selection, branch
	mov	ax, bp				;num selections

	mov	bp, GIGS_NONE			;assume no selections
	tst	ax				;none, go set it
	jz	setSingleSelection

	mov	es, cx				;have es:bx point to list
	mov	bx, dx
	mov	bp, es:[bx]			;selection in bp

setSingleSelection:
	clr	dx				;no indeterminate flag
	call	SetSingleSelection
	jmp	short exit			;exit

multiSelections:
	;
	; First, create an LMem chunk if we need one, or resize the existing
	; one.
	;
	clr	bx				;so far, no differences
	call	IC_DerefGenDI
	mov	al, ds:[di].GIGI_stateFlags	;ax <- state flags
	push	ax				;save for later

	push	cx
	mov	cx, bp				;cx <- number of items
	mov	ax, ds:[di].GIGI_selection	;selection chunk in ax, if any

	cmp	cx, ds:[di].GIGI_numSelections	;any change in # items?
	je	fillChunk			;no, branch

	shl	cx, 1				;double for chunk size
	cmp	ds:[di].GIGI_numSelections, 1	;old selection <= 1?
	ja	resizeChunk			;no, go resize chunk
	mov	al, mask OCF_DIRTY		;else allocate a dirty chunk
	call	LMemAlloc			
	jmp	short sizeChanged

resizeChunk:
	call	LMemReAlloc
	
sizeChanged:
	dec	bx				;mark chunk changed

fillChunk:
	pop	cx
	;
	; Buffer to copy selections from in cx:dx, number of selections in bp,
	; selections chunk handle in ax.  Do the copy, marking bx non-zero
	; when we see a difference.
	;
	push	si, ds, ax			;save chunk, object handle
	segmov	es, ds				;dest in *es:di
	mov	di, ax
	mov	di, es:[di]			;now es:di
	mov	ds, cx				;source in ds:si
	mov	si, dx
	mov	cx, bp				;number of selections in cx
copyLoop:
	lodsw					;get a word from source
	cmp	ax, {word} es:[di]		;compare to destination
	je	store				;no difference, branch
	dec	bx				;else mark dirty
store:
	stosw					;store the word
	loop	copyLoop			;and loop until done
	pop	ds, ax				;chunk back in *ds:ax

	clr	dx				;assume no update needed
	tst	bx
	jz	doneWithStore			;no changes here, branch
	mov	si, ax				;chunk handle in si
	call	ObjMarkDirty			;ensure chunk marked dirty
	dec	dx				;and we'll update in specUI

doneWithStore:
	pop	si
	xchg	bp, ax				;selection chunk in bp
						;num selections in ax
						;dx <- changed flag
	pop	cx				;pass current indeterminate
	andnf	cx, mask GIGSF_INDETERMINATE	;  state in cx
	call	SetSelection
exit:
	ret
SetMultiSelection	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ECCheckNumSelections

SYNOPSIS:	Checks number of selections.

CALLED BY:	utility

PASS:		*ds:si -- list

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/24/92		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK
ECCheckNumSelections	proc	near	uses	ax, bx, cx, dx, bp, si, di
	class	GenItemGroupClass
	.enter
	call	IC_DerefGenDI
	mov	cx, ds:[di].GIGI_numSelections
	mov	dx, ds:[di].GIGI_selection
	cmp	cx, 0
	jne	10$
	cmp	dx, GIGS_NONE
	ERROR_NE GEN_ITEM_GROUP_SELECTION_MARKED_INCORRECTLY_FOR_ZERO_SELECTIONS
	jmp	short exit
10$:
	cmp	cx, 1
	je	exit
	xchg	dx, si							
	call	ECLMemValidateHandle		;if you got a fatal error here,
						;  it means you didn't specify
						;  a proper selection chunk
	xchg	dx, si							
	ChunkSizeHandle	ds, dx, dx		;size in dx
	shr	dx, 1				;divide by two for num sels
	cmp	cx, dx
	ERROR_NE GEN_ITEM_GROUP_INCORRECT_SIZE_FOR_SELECTION_CHUNK
exit:
	.leave
	ret
ECCheckNumSelections	endp
endif


COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupGetSelection -- 
		MSG_GEN_ITEM_GROUP_GET_SELECTION for GenItemGroupClass

DESCRIPTION:	Gets the current selection.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_GET_SELECTION

RETURN:		ax	- current selection, or GIGS_NONE if no selections,
			  or the first selection in the item group if there
			  are multiple selections.
		carry set if none selected
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupGetSelection	method dynamic	GenItemGroupClass,
				MSG_GEN_ITEM_GROUP_GET_SELECTION

EC <	call	ECCheckNumSelections		;make sure set correctly >

	mov	ax, ds:[di].GIGI_selection
	cmp	ds:[di].GIGI_numSelections, 1	;1 or zero selections, branch
	jbe	exit	

	mov	di, ax				;put selection chunk in ax
EC <	xchg	di, si							>
EC <	call	ECLMemValidateHandle					>
EC <	xchg	di, si							>
	mov	di, ds:[di]			;else dereference chunk
	mov	ax, ds:[di]			;return first entry
exit:
	Destroy	cx, dx, bp
	ret
GenItemGroupGetSelection	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupGetNumSelections -- 
		MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS for GenItemGroupClass

DESCRIPTION:	Returns number of selections.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS

RETURN:		ax -- number of selections
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupGetNumSelections	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS

EC <	call	ECCheckNumSelections		;make sure set correctly >
	mov	ax, ds:[di].GIGI_numSelections
	Destroy	cx, dx, bp
	ret
GenItemGroupGetNumSelections	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupGetMultipleSelections -- 
		MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS for GenItemGroupClass

DESCRIPTION:	Returns multiple selections.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS

		cx:dx	- buffer to hold the selections
		bp	- max selections

RETURN:		cx:dx	- preserved, filled in with the selections
		ax	- number of selections
		carry set if none selected
		bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupGetMultipleSelections	method GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS

EC <	call	ECCheckNumSelections		;make sure set correctly >
	uses	cx
	.enter
	mov	ax, ds:[di].GIGI_numSelections	;get num selections
	tst	ax				;no selections, we're done
	jz	exit

	cmp	bp, ax				;can we fit the selections?
	jb	exit				;nope, get out

	push	ax
	mov	si, ds:[di].GIGI_selection	;get selection, or chunk

	mov	es, cx				;buffer in es:di
	mov	di, dx

	cmp	ax, 1				;one or no selections?
	ja	multiSelections			;more than one, branch
	mov	es:[di], si			;else store the selection
	jmp	short done

multiSelections:
	mov	cx, ax				;amount to copy
EC <	call	ECLMemValidateHandle					>
	mov	si, ds:[si]			;ds:si <- start of chunk
	rep	movsw				;copy selections into buffer
	
done:
	pop	ax				;restore num selections
	tst	ax
	jnz	exit
	stc					;return carry set for no sel
exit:
	.leave
	Destroy	bp
	ret
GenItemGroupGetMultipleSelections	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSetIndeterminateState -- 
		MSG_GEN_ITEM_GROUP_SET_INDETERMINATE_STATE for GenItemGroupClass

DESCRIPTION:	Sets the indeterminate state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SET_INDETERMINATE_STATE
		
		cx	- non-zero to set the item group indeterminate

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupSetIndeterminateState	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_SET_INDETERMINATE_STATE

	mov	dl, mask GIGSF_INDETERMINATE
	mov	bx, offset GIGI_stateFlags
	call	GenSetBitInByte
	jnc	exit
	call	UpdateAllChildren	
exit:
	Destroy	ax, cx, dx, bp
	ret
GenItemGroupSetIndeterminateState	endm






COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateAllChildren

SYNOPSIS:	We need to update all children.

CALLED BY:	GenItemGroupSetIndeterminateState

PASS:		*ds:si -- item group

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 2/92		Initial version

------------------------------------------------------------------------------@

UpdateAllChildren	proc	near
	class	GenItemGroupClass
	
	;
	; Make room for all the generic children.
	;
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	IC_ObjCallInstanceNoLock	;returned in dx
	shl	dx, 1				;double for word offset
	sub	sp, dx
	mov	bp, sp
	push	bp, dx				;save start, size of buffer

	mov	di, offset AddChildIdentifier
	call	GenItemGroupProcessChildren
						;returns list of ID's 
	pop	bp, ax				;restore start, size of buffer
	push	ax
	call	UpdateSpecificObject
	pop	dx
	add	sp, dx
	ret
UpdateAllChildren	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	GenItemGroupProcessChildren

SYNOPSIS:	Does a ObjCompProcessChildren on Gen part.

CALLED BY:	UpdateAllChildren	
		GenItemGroupScanItems

PASS:		*ds:si -- item group	
		di -- offset to callback routine
		ax, cx, dx, bp -- args

RETURN:		carry set if callback returned carry set
		ax, cx, dx, bp -- return args

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/20/92		Initial version

------------------------------------------------------------------------------@

GenItemGroupProcessChildren	proc	far
	class	GenClass
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset GI_link
	push	bx			;push offset to LinkPart
NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
     	mov	bx, di
	push	bx

	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
	ret
GenItemGroupProcessChildren	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	AddChildIdentifier

SYNOPSIS:	Adds an identifier

CALLED BY:	ObjCompProcessChildren (via MakeListOfAllChildren)

PASS:		*ds:si -- child in question
		ss:bp  -- place to add identifier

RETURN:		bp     -- passed bp+2

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 2/92		Initial version

------------------------------------------------------------------------------@

AddChildIdentifier	proc	far
	class	GenItemClass

	call	IC_DerefGenDI
	mov	di, ds:[di].GII_identifier	;add identifier to list
	mov	ss:[bp], di
	add	bp, 2
	clc					;continue
	ret
AddChildIdentifier	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateSpecificObject

SYNOPSIS:	Calls specific incarnation to update itself.

CALLED BY:	utility

PASS:		*ds:si	-- object
		bp	-- handle of block containing list of update items
		ax	-- size of list

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/27/92		Initial version

------------------------------------------------------------------------------@

UpdateSpecificObject	proc	near
	class	GenItemGroupClass
	tst	ax
	jz	exit
	mov	dx, ax				;size of buffer in dx
	mov	ax, MSG_SPEC_UPDATE_SPECIFIC_OBJECT
	call	GenCallSpecIfGrown
exit:
	ret
UpdateSpecificObject	endp





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupIsIndeterminate -- 
		MSG_GEN_ITEM_GROUP_IS_INDETERMINATE for GenItemGroupClass

DESCRIPTION:	Returns whether item group is indeterminate.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_IS_INDETERMINATE

RETURN:		carry set if item group is modified.
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupIsIndeterminate	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_IS_INDETERMINATE

	test	ds:[di].GIGI_stateFlags, mask GIGSF_INDETERMINATE
	jz	exit				;not modified, exit, carry clear
	stc	
exit:
	Destroy	ax, cx, dx, bp
	ret
GenItemGroupIsIndeterminate	endm







COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSetModifiedState -- 
		MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE for GenItemGroupClass

DESCRIPTION:	

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE

		cx	- non-zero to mark modified, zero to mark not modified.

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupSetModifiedState	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE

	push	cx
	mov	dl, mask GIGSF_MODIFIED
	mov	bx, offset GIGI_stateFlags
	call	GenSetBitInByte
	pop	cx
	jnc	exit				;no change, exit
	tst	cx
	jz	exit				;not setting modified, exit

	;	
	; Make the summons this object is in applyable.  -cbh 6/25/92
	;
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	ObjCallInstanceNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret

GenItemGroupSetModifiedState	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupIsModified -- 
		MSG_GEN_ITEM_GROUP_IS_MODIFIED for GenItemGroupClass

DESCRIPTION:	Returns whether item group is modified.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_IS_MODIFIED

RETURN:		carry set if item group is modified.
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupIsModified	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_IS_MODIFIED

	test	ds:[di].GIGI_stateFlags, mask GIGSF_MODIFIED
	jz	exit				;not modified, exit, carry clear
	stc	
exit:
	Destroy	ax, cx, dx, bp
	ret
GenItemGroupIsModified	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSendStatusMsg -- 
		MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG for GenItemGroupClass

DESCRIPTION:	Sends off the status message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG

		cx	- non-zero if GIGSF_MODIFIED bit should be passed set
			  in status message

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupSendStatusMsg	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	mov	ax, ATTR_GEN_ITEM_GROUP_STATUS_MSG
	call	ObjVarFindData		; ds:bx = data, if found
	jnc	exit			; no message, exit
	mov	ax, ds:[bx]		; else, fetch message

	tst	cx			; check for changed flag passed
	jz	10$			; no, branch
	mov	ch, mask GIGSF_MODIFIED	; else pass modified
10$:
	mov	cl, ds:[di].GIGI_stateFlags
	andnf	cl, mask GIGSF_INDETERMINATE
	ornf	cl, ch			; use indeterminate flag plus modified
					;   flag passed
	clr	di			; don't close window!
	GOTO	GenItemSendMsg
exit:	
	ret

GenItemGroupSendStatusMsg	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	GenItemSendMsg

SYNOPSIS:	Sends a message to the destination, with usual arguments.

CALLED BY:	GenItemGroupSendStatusMsg, GenItemGroupApply

PASS:		*ds:si -- object
		ax     -- message to send
		cl     -- state flags to pass
		di     -- non-zero if we should check to close the window

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/24/92		Initial version

------------------------------------------------------------------------------@

GenItemSendMsg	proc	far
	class	GenItemGroupClass

	tst	ax			; no message, exit
	jz	exit
	mov	dx, cx			; state flags in dl now

	mov	bx, di			; close window flag in bx
	call	IC_DerefGenDI
	pushdw	ds:[di].GIGI_destination ; push them for GenProcessAction

	mov	cx, ds:[di].GIGI_selection
	mov	bp, ds:[di].GIGI_numSelections

	cmp	bp, 1			; more than one selection?
	jbe	sendit			; no, branch
	mov	di, cx			; else use selection as chunk
EC <	xchg	di, si							>
EC <	call	ECLMemValidateHandle					>
EC <	xchg	di, si							>
	mov	di, ds:[di]		; deref
	mov	cx, ds:[di]		; and return first selection
sendit:
	tst	bx			; see if should process attrs
	jz	10$			; no, branch
	call	GenProcessGenAttrsBeforeAction
10$:
	mov	di, mask MF_FIXUP_DS
	call	GenProcessAction	; send the message
	tst	bx
	jz	exit
	call	GenProcessGenAttrsAfterAction
exit:
	Destroy	ax, cx, dx, bp
	ret
GenItemSendMsg	endp





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupApply -- 
		MSG_GEN_APPLY for GenItemGroupClass

DESCRIPTION:	Handles applies.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_APPLY

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/24/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupApply	method dynamic	GenItemGroupClass, MSG_GEN_APPLY
	;	
	; In general, only send out apply if modified.
	;
	mov	ax, ds:[di].GIGI_applyMsg
	mov	cl, ds:[di].GIGI_stateFlags
	test	cl, mask GIGSF_MODIFIED			;modified?
	jnz	sendMsg					;yes, send message

	;
	; Not modified, will still send apply message if dougarized hint is
	; present...
	;
	push	ax			; message number
	mov	ax, ATTR_GEN_SEND_APPLY_MSG_ON_APPLY_EVEN_IF_NOT_MODIFIED
	call	ObjVarFindData				;does this exist?
	pop	ax			; message number
	jc	sendMsg					;yes, send anyway
	ret
sendMsg:
	;
	; Send out the apply message
	;
	mov	di, si			; set di non-zero to allow closing
					;   of windows
	call	GenItemSendMsg
	;
	; Clear the modified bit.
	;
	call	IC_DerefGenDI
	and	ds:[di].GIGI_stateFlags, not mask GIGSF_MODIFIED
	ret

GenItemGroupApply	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSetItemState -- 
		MSG_GEN_ITEM_GROUP_SET_ITEM_STATE for GenItemGroupClass

DESCRIPTION:	Sets an individual item state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SET_ITEM_STATE

		cx -- identifier 
		dx -- non-zero to select, zero to deselect

RETURN:		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupSetItemState	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_SET_ITEM_STATE
	;
	; First, create a buffer with the current selections.
	;
	mov	ax, dx				;select flag
	mov	dx, ds:[di].GIGI_numSelections	;get number of selections
	inc	dx				;make extra room for any add
	shl	dx, 1				;add room	

	push	ax, cx				;passed args
	mov	ax, dx				;not mov_tr!
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	mov	bp, bx				;bp = block handle
	mov	bx, ax				;bx = segment
	pop	ax, cx				;select flag & identifier
	jc	quit

	;
	; Fill the buffer with the current selections.
	;
	push	ax, cx, bp			;save selectFlag, ID, buffer ptr
	mov	bp, dx				;bp = max selections
	mov	cx, bx
	clr	dx				;buffer in cx:dx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
	call	IC_ObjCallInstanceNoLock	;selections in ss:bp now
	pop	dx, cx, bp			;  numSelections returned in ax

	clr	di
	mov	es, bx				;es:di points to selections
	;
	; es:di now points to buffer of selections.  dx holds the select flag,
	; cx holds the ID to add/remove, ax holds number of selections.
	;
	tst	dx				;selecting?
	jnz	select				;yes, branch
deselect::

	call	GetItemPosition			;is the item selected?
	jnc	exit				;no, get out now
						;else bx is offset to item.
	;
	; Remove the item at offset bx from es:di, moving the ones after it
	; up.
	;
	push	di				;save start of selections
	push	ds, si				;save object
	add	di, bx				;point at item to remove
	shr	bx, 1				;get number of entries to item
	mov	cx, ax				;number of selections
	sub	cx, bx				;subtract offset to bad one
	segmov	ds, es				;source = destination
	mov	si, di
	add	si, 2				;now source is destination + 2
	rep	movsw				;move other items up
	dec	ax				;one less selection
	pop	ds, si				;restore object
	jmp	short setNewSelections		;and go set the new selections
	
select:
	call	GetItemPosition			;item already selected?
	jc	exit				;yes, get out now.
	;
	; Add item to end of selection list.
	;
	push	di				;save start of selections
	add	di, ax				;point to end of selections
	add	di, ax
	mov	{word} es:[di], cx		;add item at end
	inc	ax				;one more selection

setNewSelections:
	pop	di				;restore start of selections
	;
	; ds:di points to selection list, ax has number of entries.
	;
	mov	cx, es				;cx:dx is selection list
	mov	dx, di
	push	bp				;buffer block handle
	mov	bp, ax				;num selections
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS
	call	IC_ObjCallInstanceNoLock
	pop	bp				;buffer block handle
exit::
	mov	bx, bp
	call	MemFree		
quit:
	Destroy	ax, cx, dx, bp
	ret
GenItemGroupSetItemState	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupIsItemSelected -- 
		MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED for GenItemGroupClass

DESCRIPTION:	Returns whether item is selected.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED

		cx -- identifier of item to check on

RETURN:		carry set if item is selected
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupIsItemSelected	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
	mov	ax, ds:[di].GIGI_numSelections
	cmp	ax, 1				;more than one selection, branch
	ja	multiSels			

	cmp	cx, ds:[di].GIGI_selection
	clc					;assume no match
	jne	exit				;doesn't match selection, branch
	stc					;else say match
	jmp	short exit			;and branch
multiSels:
	segmov	es, ds
	mov	di, ds:[di].GIGI_selection
EC <	xchg	di, si							>
EC <	call	ECLMemValidateHandle					>
EC <	xchg	di, si							>
	mov	di, ds:[di]			;es:di points to selections
	call	GetItemPosition			;returns carry set if selected
exit:
	Destroy	ax, cx, dx, bp
	ret
GenItemGroupIsItemSelected	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetItemPosition

SYNOPSIS:	Returns position of item in item group selection list.

CALLED BY:	GenItemGroupIsItemSelected

PASS:		es:di  -- pointer to start of selections
		cx     -- identifier
		ax     -- number of selections

RETURN:		carry set if item found, with:
			bx -- offset in list to item

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/24/92		Initial version

------------------------------------------------------------------------------@

GetItemPosition	proc	near			uses	ax, cx
	class	GenItemGroupClass

	.enter
	xchg	ax, cx				;numSelections in cx
						;identifier in ax
	push	di				;save start
	jcxz	noMatch				;if no selections, can't be in
						;	list -- no match.
	repne	scasw				;scan for a match
	jne	noMatch				;no match, exit
	mov	bx, di				;points past found match
	sub	bx, 2				;back up to match
	pop	di
	sub	bx, di				;subtract start of list
	stc
	jmp	short exit
noMatch:
	pop	di				;unload start
	clc
exit:
	.leave
	ret
GetItemPosition	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupMakeItemVisible -- 
		MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE for GenItemGroupClass

DESCRIPTION:	Makes an item visible.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE

		cx	- identifier of item to ensure visible

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupMakeItemVisible	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE,
				MSG_GEN_ITEM_GROUP_SET_FOCUS_ITEM
	call	VisCheckIfSpecBuilt		;if not visually built
	jnc	exit				;then exit
	call	GenCallSpecIfGrown		;slower but cheaper
exit:
	Destroy	ax, cx, dx, bp
	ret
GenItemGroupMakeItemVisible	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupGetFocusItem --
		MSG_GEN_ITEM_GROUP_GET_FOCUS_ITEM for GenItemGroupClass

DESCRIPTION:	Returns the id of the current user exclusive

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_GET_FOCUS_ITEM
RETURN:		cx	- identifier of item with user exclusive,
			  GIGS_NONE if no user excl or not spec-built.
		carry	- set if no user exclusive.

DESTROYS:	ax, bx, dx, bp

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupGetFocusItem	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_GET_FOCUS_ITEM
	call	VisCheckIfSpecBuilt		;if not visually built
	mov	cx, GIGS_NONE			; prepare for failure
	cmc
	jc	exit				;then exit
	call	GenCallSpecIfGrown		;slower but cheaper
exit:
	Destroy	ax, dx, bp
	ret
GenItemGroupGetFocusItem	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupGetDestination -- 
		MSG_GEN_ITEM_GROUP_GET_DESTINATION for GenItemGroupClass

DESCRIPTION:	Returns the destination.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_GET_DESTINATION

RETURN:		^lcx:dx - destination
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupGetDestination	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_GET_DESTINATION
	mov	bx, offset GIGI_destination
	call	GenGetDWord
	Destroy	ax, bp
	ret
GenItemGroupGetDestination	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSetDestination -- 
		MSG_GEN_ITEM_GROUP_SET_DESTINATION for GenItemGroupClass

DESCRIPTION:	Sets a new destination.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SET_DESTINATION

		^lcx:dx - destination

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupSetDestination	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_SET_DESTINATION
	mov	bx, offset GIGI_destination
	GOTO	GenSetDWord
GenItemGroupSetDestination	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupGetApplyMsg -- 
		MSG_GEN_ITEM_GROUP_GET_APPLY_MSG for GenItemGroupClass

DESCRIPTION:	Returns apply message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_GET_APPLY_MSG

RETURN:		ax 	- current apply message
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupGetApplyMsg	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_GET_APPLY_MSG
	mov	ax, ds:[di].GIGI_applyMsg
	Destroy	cx, dx, bp
	ret
GenItemGroupGetApplyMsg	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSetApplyMsg -- 
		MSG_GEN_ITEM_GROUP_SET_APPLY_MSG for GenItemGroupClass

DESCRIPTION:	Sets a new apply message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SET_APPLY_MSG

		cx	- new apply message

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupSetApplyMsg	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_SET_APPLY_MSG
	mov	bx, offset GIGI_applyMsg
	GOTO	GenSetWord
GenItemGroupSetApplyMsg	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupGetBehaviorType -- 
		MSG_GEN_ITEM_GROUP_GET_BEHAVIOR_TYPE for GenItemGroupClass

DESCRIPTION:	Returns behavior type.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_GET_BEHAVIOR_TYPE

RETURN:		al 	- GenItemGroupBehaviorType
		ah, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupGetBehaviorType	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_GET_BEHAVIOR_TYPE

	mov	al, ds:[di].GIGI_behaviorType
	Destroy	ah, cx, dx, bp
	ret
GenItemGroupGetBehaviorType	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSetBehaviorType -- 
		MSG_GEN_ITEM_GROUP_SET_BEHAVIOR_TYPE for GenItemGroupClass

DESCRIPTION:	Sets a new behavior type.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SET_BEHAVIOR_TYPE

		cl	- GenItemGroupBehaviorType

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupSetBehaviorType	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_SET_BEHAVIOR_TYPE
EC <	call	GenEnsureNotUsable						>
	mov	bx, offset GIGI_behaviorType
	GOTO	GenSetByte
GenItemGroupSetBehaviorType	endm






COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupScanItems -- 
		MSG_GEN_ITEM_GROUP_SCAN_ITEMS for GenItemGroupClass

DESCRIPTION:	Scans forwards or backwards for a new item, wrapping if
		desired.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SCAN_ITEMS

		cl -- GenScanItemsFlags
		dx -- initial item identifier
		bp -- absolute scan amount (direction depends on GSIF_FORWARD)

RETURN:		carry set if have result, with:
			ax -- the resulting identifier
			dx, bp -- destroyed
		else
			ax -- usable position of item we wanted to find
			dx -- identifier of first usable and enabled item
			bp -- identifier of last usable and enabled item
		cl -- GenScanItemsFlags, updated

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupScanItems	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_SCAN_ITEMS
	firstItem	local	word
	lastItem	local	word
	childCount	local	word
	
	mov	bx, bp				;scan amount
	.enter	
	mov	ax, dx				;pass child in ax
	push	bx				;save scan amount
	clr	firstItem			;no first item yet
	clr	lastItem			;no last item yet
	clr	childCount
	clr	dx				;initialize count

	;
	; Return usable position of the child we want.  (If the child
	; itself isn't usable, and we're planning on scanning backwards,
	; we'll add one to the position to make things work.)  Also
	; returns the first and last usable and enabled items, to be
	; more useful.
	;
	mov	di, offset GetChildUsablePosition
	call	GenItemGroupProcessChildren	;dx <- usable position of 
	pop	bx				;   initial item
	test	cl, mask GSIF_USABLE_AND_ENABLED_ITEM_FOUND
	jz	notFoundReturnFirstOrLast	;nope, exit
	test	cl, mask GSIF_INITIAL_ITEM_FOUND
	jz	notFoundReturnFirstOrLast	;not found, return first or last

	test	cl, mask GSIF_FORWARD		;backward, negate scan amount
	jnz	10$
	neg	bx
10$:
	add	dx, bx				;add scan amount to position
	js	notFound			;went past beginning, branch
	cmp	dx, childCount			;see if past end of list
	jae	notFound			;went past end, branch

	;
	; Return identifier of child at the usable position we pass.
	; The child must be usable *and* enabled, however, or we look
	; a little more forward or back until we find one.
	;
	push	bp
	clr	bp				;initialize running position
	mov	di, offset GetItemAtPosition	;find child at this position
	and	cl, not mask GSIF_USABLE_AND_ENABLED_ITEM_FOUND
	call	GenItemGroupProcessChildren
	pop	bp
	jnc	notFoundReturnFirstOrLast	;didn't ever exit, not found
	test	cl, mask GSIF_USABLE_AND_ENABLED_ITEM_FOUND
	jnz	exitHaveResult			;returned carry *and* have this
						;  flag set, we've got a result

	or 	cl, mask GSIF_USABLE_AND_ENABLED_ITEM_FOUND
						;set this bit again, we want it
						;  to again reflect the result
						;  of the first pass (i.e. any	
						;  item found)
notFoundReturnFirstOrLast:
	;
	; On dynamic lists, if the search for an item at the usable position
	; failed, we'll return a value that is either just before or just
	; after the usable items available.
	;
	test	cl, mask GSIF_DYNAMIC_LIST	
	jz	notFound			;not dynamic, branch
	mov	dx, -1				;assume going backward
	test	cl, mask GSIF_FORWARD		;going forward?
	jz	notFound			;no, dx <- first position - 1
	mov	dx, childCount			;else return last pos + 1
	
notFound:
	;
	; Nothing found.  If not wrapping around, forward scans return last 
	; item, backwards scans, the first item.  If wrapping around or
	; going from start, the opposite is true.  
	;
	test	cl, mask GSIF_DYNAMIC_LIST	;dynamic list, handle specially
	jnz	dynamicNotFound

	mov	ax, lastItem			;assume forward, no wrapping
	mov	bx, firstItem			;alternate possibility
	test	cl, mask GSIF_FORWARD		;going forward?
	jne	20$				;yep, branch
	xchg	ax, bx				;else switch return values
20$:
	test	cl, mask GSIF_WRAP_AROUND or mask GSIF_FROM_START
	jz	exitHaveResult			;no, we're done
	xchg	ax, bx				;else switch return values
	jmp	short exitHaveResult

dynamicNotFound:
	;
	; In dynamic lists, when an item is not found, we'll return the position
	; of the item we were trying to find, relative to the position of the
	; first child (i.e. -1 for the item before the first child, etc).
	;
	mov	ax, dx				;return requested item in ax
	mov	dx, firstItem			;first us/en item in dx
	mov	bx, lastItem			;last us/en item - bx (bp later)
	clc
	jmp	short exit

exitHaveResult:
	test	cl, mask GSIF_USABLE_AND_ENABLED_ITEM_FOUND
	jz	exit				;never found an item, don't set
						;  the carry, return data is
						;  bogus for non-dynamic lists
	stc
exit:
	.leave
	mov	bp, bx				;in case returning bp value
	ret
GenItemGroupScanItems	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetChildUsablePosition

SYNOPSIS:	Returns usable position of the child we want.  (If the child
		itself isn't usable, and we're planning on scanning backwards,
		we'll add one to the position to make things work.)  Also
		returns the first and last usable and enabled items, to be
		more useful.

CALLED BY:	ObjCompProcessChildren

PASS:		*ds:si -- item
		*es:di -- parent
		ax -- identifier to search for
		cl -- GenScanItemsFlags
		dx -- count
		firstItem -- identifier of first usable/enabled child 
		lastItem -- identifier of last usable/enabled child 
		childCount -- number of generic children to this point

RETURN:		ax, cl, dx, firstItem, lastItem -- updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/92		Initial version

------------------------------------------------------------------------------@

GetChildUsablePosition	proc	far
	firstItem	local	word
	lastItem	local	word
	childCount	local 	word

	class	GenItemClass
	.enter	inherit
	;
	; First, check for a match in the states.
	;
	call	GetUsableEnabledState		;returns state in bl,
						;  item GenInstance in ds:di
	;
	; Check for a match with the item.
	;
	mov	di, ds:[di].GII_identifier	;get identifier

	test	cl, mask GSIF_FROM_START	;there is no initial item...
	jnz	checkState

	cmp	di, ax				;see if identifier matches
	jne	checkState			;no, branch
	or	cl, mask GSIF_INITIAL_ITEM_FOUND ;else mark as found
	;
	; We had a match.  If our item isn't usable, then we'll have to bump
	; the count for backward queries, so that finding the previous usable
	; item will still work.  
	;
	test	bl, mask GS_USABLE		;our item usable?
	jnz	isUsable			;yes, branch
	test	cl, mask GSIF_FORWARD		;backward query?
	jnz	checkState			;no, we're fine
	inc	dx				;else bump the count 

checkState:
	test	bl, mask GS_USABLE		;see if a usable item
	jz	exit				;not usable, exit

isUsable:
	;
	; Object is usable -- bump the position count if we haven't found our 
	; item yet.  Also, if the item is enabled as well, we'll update the
	; first and last items as needed.	
	;
	test	bl, mask GS_ENABLED
	jz	bumpPosition			;not enabled, forget first/last

	test	cl, mask GSIF_USABLE_AND_ENABLED_ITEM_FOUND
	jnz	storeLast			
	mov	firstItem, di			;found first item, store
	or	cl, mask GSIF_USABLE_AND_ENABLED_ITEM_FOUND

storeLast:
	mov	lastItem, di			;store last child

bumpPosition:
	test	cl, mask GSIF_INITIAL_ITEM_FOUND	
						;has our item been found?
	jnz	exit				;already found, exit
	inc	dx				;else bump the count
exit:
	inc	childCount			;bump the number of children
	clc					;continue in all circumstances
	.leave
	ret
GetChildUsablePosition	endp


GetUsableEnabledState	proc	near		;returns state in bl
	class	GenClass
	call	IC_DerefGenDI
	mov	bl, ds:[di].GI_states		;see if states match
	and	bl, mask GS_USABLE or mask GS_ENABLED
	ret	
GetUsableEnabledState	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetItemAtPosition

SYNOPSIS:	Returns identifier of child at the usable position we pass.
		The child must be usable *and* enabled, however, or we look
		a little more forward or back until we find one.

CALLED BY:	ObjCompProcessChildren

PASS:		*ds:si -- item
		*es:di -- parent
		ax -- running USABLE/ENABLED identifier
		cl -- GenScanItemsFlags
		dx -- position to search for
		bp -- running count

RETURN:		carry set if a match, with:
			ax -- the item identifier
		else
			ax -- running count, updated

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/92		Initial version

------------------------------------------------------------------------------@

GetItemAtPosition	proc	far
	class	GenItemClass
	;
	; First, check for a match in the states.
	;
	call	GetUsableEnabledState		;returns state in bl,
						;  item GenInstance in ds:di
	;
	; If enabled and usable, will save the position.
	;
	cmp	bl, mask GS_USABLE or mask GS_ENABLED
	jne	10$				;see if usable and enabled

	mov	ax, ds:[di].GII_identifier	;matches, save identifier
	or	cl, mask GSIF_USABLE_AND_ENABLED_ITEM_FOUND
10$:
	;
	; If usable, we'll see if we've matched the passed position.  If so,
	; we will return ourselves if we're usable *and* enabled; otherwise 
	; we'll return the previous or next usable and enabled item.
	;
	test	bl, mask GS_USABLE
	jz	exit				;not usable, exit
	
	cmp	bp, dx				;matched passed position?
	jne	incCount			;no, branch to continue

	test	bl, mask GS_ENABLED		;is our match enabled?
	stc					;assume so, return found
	jnz	exit				;yes, exit for good.

	test	cl, mask GSIF_FORWARD		;are we scanning forward?
	stc					;assume so, return found
	jz	exit				;no, we'll previously stored
						;  enabled-and-usable item
						;else we'll look until we find
	dec	bp				;  an enabled-and-usable item	
						;  (don't adjust position)
incCount:
	inc	bp				;increment usable position
	clc					;continue
exit:
	ret
GetItemAtPosition	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	GetFirstLastItems

SYNOPSIS:	Returns identifiers of the first and last usable items.

CALLED BY:	GenDynamicListScanItems (via GenItemGroupProcessChildren)

PASS:		*ds:si -- dynamic list
		ax -- running first item (-1 if not yet found)
		bp -- last item (-1 if not yet found)

RETURN:		ax, dx -- updated

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/26/92		Initial version

------------------------------------------------------------------------------@

GetFirstLastItems	proc	far
	class	GenItemClass

	call	IC_DerefGenDI
	test	ds:[di].GI_states, mask GS_USABLE
	jz	exit				;not usable, exit
	mov	di, ds:[di].GII_identifier
	cmp	ax, -1
	jne	storeLast			;found first item, branch
	mov	ax, di				;else store as first item

storeLast:
	mov	bp, di				;store last item
exit:
	ret
GetFirstLastItems	endp




COMMENT @----------------------------------------------------------------------

METHOD:	    GenItemGroupGetUniqueIdentifier -- 
	    MSG_GEN_ITEM_GROUP_GET_UNIQUE_IDENTIFIER for GenItemGroupClass

DESCRIPTION:	Returns a unique identifier for the item group.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_GET_UNIQUE_IDENTIFIER

RETURN:		ax 	- unique identifier
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/ 7/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupGetUniqueIdentifier	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_GET_UNIQUE_IDENTIFIER

	clr	bp				;why not search for zero first

findIdentifierInBp:
	clr	dx				;nothing found yet
	mov	ax, dx				;init highest identifier
	mov	di, offset GetUniqueIdentifier	;find child at this position
	call	GenItemGroupProcessChildren
	tst	dx				;was ID found?
	jnz	10$				;yes, do some more stuff
	mov	ax, bp				;else return the ID
	jmp	short exit			;and get out
10$:
	inc	ax				;assume we'll take highest ID+1
	jnz	exit				;didn't wrap around, exit
	inc	bp				;else bump and look for next
	jmp	short findIdentifierInBp	;and loop
exit:
	ret
GenItemGroupGetUniqueIdentifier	endm






COMMENT @----------------------------------------------------------------------

ROUTINE:	GetUniqueIdentifier

SYNOPSIS:	Returns a unique identifier.

CALLED BY:	GenItemGroupRequestUniqueIdentifier 
		(via GenItemGroupProcessChildren)

PASS:		*ds:si -- object
		bp     -- identifier to search for
		ax     -- running search of highest identifier
		dx     -- zero if identifier not found, non-zero if found

RETURN:		carry clear, so we'll continue in all circumstances

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 7/92		Initial version

------------------------------------------------------------------------------@

GetUniqueIdentifier	proc	far
	class	GenItemClass
	call	IC_DerefGenDI
	mov	cx, ds:[di].GII_identifier	;get item identifier
	cmp	cx, bp				;see if match
	jne	10$				;no, branch
	dec	dx				;else mark no match
10$:
	cmp	cx, ax				;see if > highest identifier
	jbe	exit				;no, exit
	mov	ax, cx				;else store as highest
exit:
	clc					;always continue
	ret
GetUniqueIdentifier	endp







COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupSetMonikerSelection -- 
		MSG_GEN_ITEM_GROUP_SET_MONIKER_SELECTION for GenItemGroupClass

DESCRIPTION:	Sets selection via the moniker text passed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SET_MONIKER_SELECTION
	
		cx:dx - text to match
		(cx:dx *cannot* be pointing into the movable XIP code resource.)
		bp    - non-zero if we're to get an exact match

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/19/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupSetMonikerSelection	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_SET_MONIKER_SELECTION
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr (cx:dx) passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	ax, mask GFOWMF_SKIP_THIS_NODE	;don't check ourselves
	tst	bp				;do we need an exact match?
	jz	10$
;	ORNF	ax, mask GFOWMF_EXACT_MATCH	;yes, set the flag
	mov	ax, cx
	jmp	short setSelection
10$:
	mov	bp, ax
	mov	ax, MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER
	call	IC_ObjCallInstanceNoLock		;found no match, branch
	jnc	exit

	cmp	dx, si				;make sure not ourselves
	jne	found				;is ourselves, exit
	cmp	cx, ds:[LMBH_handle]
	je	exit			
found:
	;
	; Found a match.  Look up the object's identifier and set the selection,
	; as if the user had set it.
	;
	push	si
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;returns ID in ax
	pop	si

setSelection:
	clr	dx
	mov	cx, ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	IC_ObjCallInstanceNoLock
	
	;
	; Set the item group modified and send the status message, as if the
	; user had clicked on it.  This will enable the text object to update
	; itself to the complete text, if needed.
	;
	mov	cx, si				;pass non-zero
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	IC_ObjCallInstanceNoLock
	mov	cx, si				;pass modified
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	GOTO	ObjCallInstanceNoLock
exit:
	ret
GenItemGroupSetMonikerSelection	endm



ItemCommon ends


IniFile segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:  GenItemGroupLoadOptions -- MSG_GEN_LOAD_OPTIONS for GenItemGroupClass

DESCRIPTION:	Load options from .ini file

PASS:
	*ds:si - instance data
	es - segment of GenItemGroupClass

	ax - The message

	ss:bp - GenOptionsParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
GenItemGroupLoadOptions	method dynamic	GenItemGroupClass, 
						MSG_GEN_LOAD_OPTIONS

	mov	dx, ds:[di].GIGI_selection

	mov	ax, ATTR_GEN_ITEM_GROUP_INIT_FILE_BOOLEAN
	call	ObjVarFindData			;carry set for boolean
	call	GenOptGetInteger		;ax = value
	mov_tr	cx, ax				;cx = data
	jc	done

	cmp	cx, dx
	jz	done

	clr	dx				;no indeterminates
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION	
	call	ObjCallInstanceNoLock

	mov	cx, si				;set non-zero
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_APPLY
	GOTO	ObjCallInstanceNoLock
done:
	ret

GenItemGroupLoadOptions	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenOptGetInteger

DESCRIPTION:	Get an integer from the .ini file

CALLED BY:	INTERNAL

PASS:
	carry - set to use InitFileReadBoolean
	ss:bp - GenOptionsParams

RETURN:
	carry - clear if successful
	ax - integer

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
GenOptGetInteger	proc	near	uses cx, dx, si, ds
	.enter

	segmov	ds, ss
	lea	si, ss:[bp].GOP_category
	mov	cx, ss
	lea	dx, ss:[bp].GOP_key
	jc	boolean
	call	InitFileReadInteger
	jmp	common
boolean:
	call	InitFileReadBoolean
common:

	.leave
	ret

GenOptGetInteger	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenItemGroupSaveOptions -- MSG_GEN_SAVE_OPTIONS for GenItemGroupClass

DESCRIPTION:	Save our options

PASS:
	*ds:si - instance data
	es - segment of GenItemGroupClass

	ax - The message

	ss:bp - GenOptionsParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91	Initial version

------------------------------------------------------------------------------@
GenItemGroupSaveOptions	method dynamic	GenItemGroupClass, MSG_GEN_SAVE_OPTIONS

	push	bp				; GenOptionsParams
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock		;ax = value
	pop	bp				; GenOptionsParams

	push	ax
	mov	ax, ATTR_GEN_ITEM_GROUP_INIT_FILE_BOOLEAN
	call	ObjVarFindData
	pop	ax
	call	GenOptWriteInteger
	ret
GenItemGroupSaveOptions	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenOptWriteInteger

DESCRIPTION:	Write an integer from the .ini file

CALLED BY:	INTERNAL

PASS:
	carry - set to use InitFileWriteBoolean
	ss:bp - GenOptionsParams
	ax - integer

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
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
GenOptWriteInteger	proc	near	uses cx, dx, si, bp, ds
	.enter

	segmov	ds, ss
	lea	si, ss:[bp].GOP_category
	mov	cx, ss
	lea	dx, ss:[bp].GOP_key
	mov	bp, ax				;bp = value
	jc	boolean
	call	InitFileWriteInteger
	jmp	common
boolean:
	call	InitFileWriteBoolean
common:

	.leave
	ret

GenOptWriteInteger	endp

IniFile ends

idata	segment	

method GenItemGroupScanItems, GenBooleanGroupClass, \
			      MSG_GEN_BOOLEAN_GROUP_SCAN_BOOLEANS

idata	ends


ItemExtended	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGroupUpdateExtendedSelection -- 
		MSG_GEN_ITEM_GROUP_UPDATE_EXTENDED_SELECTION for 
		GenItemGroupClass

DESCRIPTION:	Updates an extended selection appropriately.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_UPDATE_EXTENDED_SELECTION
		ss:bp	- GenItemGroupUpdateExtSelParams

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	9/22/92		Initial Version

------------------------------------------------------------------------------@

GenItemGroupUpdateExtendedSelection	method dynamic	GenItemGroupClass, \
				MSG_GEN_ITEM_GROUP_UPDATE_EXTENDED_SELECTION

	clr	ax				;position counter
	clr	dl
	mov	di, offset ConvertToPositions
	call	ItemExtendedProcessChildren
	call	SetupChangeItemArgs		;set up range to change in cx,dx
	jnc	exit				;nothing to do, get out.

	clr	ax				;child count
	mov	di, offset GenItemGroupChangeItem
	call	ItemExtendedProcessChildren
exit:
	.leave
	ret
GenItemGroupUpdateExtendedSelection	endm


ItemExtendedProcessChildren	proc	near
	class	GenClass
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset GI_link
	push	bx			;push offset to LinkPart
NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx, di
	push	bx

	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
	ret
ItemExtendedProcessChildren	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ConvertToPositions

SYNOPSIS:	Converts various item identifiers to generic positions.

CALLED BY:	GenItemGroupUpdateExtendedSelection
		(via GenItemGroupProcessChildren)

PASS:		*ds:si -- item group
		ax -- child count
		dl -- ConvertPositionsFlags
		ss:bp -- GenItemGroupUpdateExtendedSelectionParams

RETURN:		ax -- updated 
		dl -- updated

DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/22/92		Initial version

------------------------------------------------------------------------------@
ConvertPositionsFlags	record
	CPF_ANCHOR_CONVERTED:1
	CPF_EXTENT_CONVERTED:1
	CPF_PREV_EXTENT_CONVERTED:1
ConvertPositionsFlags	end


ConvertToPositions	proc	far
	class	GenItemClass
	;
	; Basically, when we get an identifier match, we replace the passed
	; thing with the position.
	;
	call	IE_DerefGenDI
	mov	cx, ds:[di].GII_identifier

	test	dl, mask CPF_ANCHOR_CONVERTED
	jnz	10$
	cmp	cx, ss:[bp].GIGUESP_anchorItem
	jne	10$
	mov	ss:[bp].GIGUESP_anchorItem, ax
	or	dl, mask CPF_ANCHOR_CONVERTED
10$:
	test	dl, mask CPF_EXTENT_CONVERTED
	jnz	20$
	cmp	cx, ss:[bp].GIGUESP_extentItem
	jne	20$
	mov	ss:[bp].GIGUESP_extentItem, ax
	or	dl, mask CPF_EXTENT_CONVERTED
20$:
	test	dl, mask CPF_PREV_EXTENT_CONVERTED
	jnz	30$
	cmp	cx, ss:[bp].GIGUESP_prevExtentItem
	jne	30$
	mov	ss:[bp].GIGUESP_prevExtentItem, ax
	or	dl, mask CPF_PREV_EXTENT_CONVERTED
30$:
	inc	ax				;next item
	clc
	ret
ConvertToPositions	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupChangeItemArgs

SYNOPSIS:	Sets up items that need changing.

CALLED BY:	GenItemGroupUpdateExtendedSelection
		GenDynamicListUpdateExtendedSelection

PASS:		*ds:si -- item group or such thing

RETURN:		carry set if any change happening, with
			ax -- anchor
			cx -- start of changing items
			dx -- end of changing items

DESTROYED:	something

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/22/92		Initial version

------------------------------------------------------------------------------@

SetupChangeItemArgs	proc	near
	mov	cx, ss:[bp].GIGUESP_extentItem
	mov	dx, ss:[bp].GIGUESP_prevExtentItem
	mov	ax, ss:[bp].GIGUESP_anchorItem

	;
	; If this is the first go-around, just do anchor to extent and exit.
	;
	test	ss:[bp].GIGUESP_flags, mask ESF_INITIAL_SELECTION
	jz	5$
	mov	dx, ax				;use anchor as old extent
	cmp	cx, dx				;order start and end
	jbe	returnChanged
	xchg	cx, dx
	jmp	short returnChanged
5$:
	;
	; Order the old and new extents.
	;
	cmp	cx, dx
	clc					;assume unchanged
	je	exit				;no change, get out now.
	jl	10$				;(used because of clc above --
						; shouldn't be a problem)
	xchg	cx, dx
10$:
	; 
	; Figure out if both less than anchor, both more, or one on each
	; side (flipped the selection), and do the right thing.
	;
	cmp	cx, ax				;below anchor?
	jb	belowAnchor

;aboveAnchor:					;cx above anchor
	cmp	dx, ax				;dx below anchor?
	jb	returnChanged			;below, flipping, have selection
	inc	cx				;else changed items above cx
	jmp	short returnChanged

belowAnchor:					;cx below anchor
	cmp	dx, ax				;dx above anchor?
	ja	returnChanged			;above, flipping, have selection
	dec	dx				;else changed items below dx
	
returnChanged:
	stc					
exit:
	ret
SetupChangeItemArgs	endp







COMMENT @----------------------------------------------------------------------

ROUTINE:	GenItemGroupChangeItem

SYNOPSIS:	Changes an item.

CALLED BY:	GenItemGroupChangeItems 
		(via GenItemGroupProcessChildren)

PASS:		*ds:si -- item
		*es:di -- item group
		ax -- current item
		cx -- start of changing items
		dx -- end of changing items
		ss:bp -- GenItemGroupUpdateExtSelParams

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/22/92		Initial version

------------------------------------------------------------------------------@

GenItemGroupChangeItem	proc	far
	class	GenItemClass
	push	ax, cx, dx, bp
	mov	si, ds:[si]			
	add	si, ds:[si].Gen_offset
	test	ds:[si].GI_states, mask GS_USABLE
	jz	exit				;skip if not usable

	;
	; Figure out whether this item is changing from last time.  (On
	; an initial selection, nothing is changing from last time, or so
	; we must treat it, as far as whether to clear an item no longer in
	; the selection.)
	;
	push	ds:[si].GII_identifier		;save identifier
	clr	si				;assume not changing
	test	ss:[bp].GIGUESP_flags, mask ESF_INITIAL_SELECTION
	jnz	notChanging			;initial selection, no changes
	cmp	ax, cx
	jb	notChanging
	cmp	ax, dx
	ja	notChanging

	dec	si				;say changing

notChanging:
	pop	cx				;restore item identifier
	mov	dx, si				;pass changing flag in dx
	mov	bx, ax				;child position
	mov	ax, ss:[bp].GIGUESP_anchorItem
	segmov	ds, es
	mov	si, di				;item group in *ds:si
	call	ChangeItem
exit:
	pop	ax, cx, dx, bp
	inc	ax
	clc					;always continue
	ret

GenItemGroupChangeItem	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	ChangeItem

SYNOPSIS:	Changes an item.

CALLED BY:	ChangeItems (via GenItemGroupProcessChildren)

PASS:		*ds:si -- parent
		ax     -- anchor item
		bx     -- child position
		cx     -- identifier of child
		dx     -- non-zero if the item is changing
		ss:bp  -- GenItemGroupUpdateExtSelParams

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/10/92		Initial version

------------------------------------------------------------------------------@

ChangeItem	proc	far			

if SELECT_DISABLED_LIST_ITEMS
	class	GenItemGroupClass
	; 
	; In Lizzy, if we're doing selection and this is a
	; non-exclusive list, it doesn't matter if items are disabled or not
	;
	test	ss:[bp].GIGUESP_flags, mask ESF_SELECT
	jz	checkDisabled

	call	IE_DerefGenDI
	cmp	ds:[di].GIGI_behaviorType, GIGBT_NON_EXCLUSIVE
	je	checkOK

checkDisabled:
endif
	;
	; If the item exists and is not enabled, we don't want to do anything
	; with it.
	;
	call	CheckItemDisabled		;don't mess with disabled items
	jc	exit

if SELECT_DISABLED_LIST_ITEMS
checkOK:
endif

	test	ss:[bp].GIGUESP_flags, mask ESF_INITIAL_SELECTION
	jnz	5$
	cmp	bx, ax				;if anchor item, get out.
	je	exit				; (anchor never changes)
5$:
	test	ss:[bp].GIGUESP_flags, mask ESF_XOR_INDIVIDUAL_ITEMS
	jnz	xoringSelection
	
	;
	; If doing normal selection, set the ones currently between the anchor
	; and new extent item, as they must be changing to an on state. 
	; Otherwise, they're going off.
	;
	mov	di, ss:[bp].GIGUESP_extentItem	;get extent item
	cmp	ax, di				;order anchor and extent
	jbe	10$
	xchg	ax, di
10$:	
	push	dx				;save the whither-changing flag
	clr	dx				;assume turning off
	cmp	bx, ax				;in range?
	jb	itemNotInSelection		;no, turn it off, maybe.
	cmp	bx, di
	ja	itemNotInSelection
	pop	ax				;jettison whither-changing flag
	test	ss:[bp].GIGUESP_flags, mask ESF_SELECT
	jz	setItem				;not selecting items, branch

	dec	dh				;else we'll be turning on

	jmp	short setItem

itemNotInSelection:
	pop	ax				;restore whither changing flag

	test	ss:[bp].GIGUESP_flags, mask ESF_CLEAR_UNSELECTED_ITEMS
	jnz	setItem				;clearing all unselected items,
						;  then go do it

	;
	; Not clearing all unselected items.  In this case, we'll check a flag
	; and restore the selection from an old state if the item is leaving
	; the selection, and do nothing if the item was always outside the 
	; selection.
	;
	tst	ax				;not changing, do nothing
	jz	exit

;	This should be changed to a flag being passed in, to either clear the
;	thing or restore it.
;	test	ss:[bp].GIGUESP_flags, mask ESF_CLEAR_UNSELECTED_ITEMS
;	jz	exit				;exit if we're not clearing it
	jmp	short setItem			;else go clear it

xoringSelection:
	;
	; Xor the item.
	;
	clr	dx				;assume turning off
	push	bp
	mov	ax, MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
	call	IE_ObjCallInstanceNoLock
	pop	bp
	jc	setItem				;currently on, turn off	
	dec	dx				;else turn on
	
setItem:
	;
	; dh non-zero to select.
	;
	mov	dl, ss:[bp].GIGUESP_passFlags
	mov	ax, ss:[bp].GIGUESP_setSelMsg
	call	IE_ObjCallInstanceNoLock

exit:
	ret
ChangeItem	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckItemDisabled

SYNOPSIS:	Checks to see if an item exists and is not enabled.

CALLED BY:	ChangeItem

PASS:		*ds:si -- item group
		cx -- item to check

RETURN:		carry set if disabled

DESTROYED:	dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/29/92		Initial version

------------------------------------------------------------------------------@

CheckItemDisabled	proc	near		uses	ax, bx, cx, dx, si, bp
	.enter
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	call	IE_ObjCallInstanceNoLock	;optr in ^lcx:dx
	jnc	exit				;item not found, return OK

	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_CHECK_IF_FULLY_ENABLED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmc					;return carry set if disabled
exit:
	.leave
	ret
CheckItemDisabled	endp

IE_DerefGenDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	ret
IE_DerefGenDI	endp

IE_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
IE_ObjCallInstanceNoLock	endp

ItemExtended	ends
