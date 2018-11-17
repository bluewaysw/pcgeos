COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefItemGroup.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.

DESCRIPTION:
	

	$Id: prefItemGroup.asm,v 1.1 97/04/04 17:50:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Determine whether this object's selection state has
		changed

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= Segment of PrefItemGroupClass.

RETURN:		IF CHANGED
			CARRY SET

		ELSE
			CARRY CLEAR
		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupHasStateChanged	method	dynamic	PrefItemGroupClass, 
					MSG_PREF_HAS_STATE_CHANGED

buffer	local	PREF_ITEM_GROUP_MAX_SELECTIONS dup (word)
	.enter

	push	bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
	mov	cx, ss
	lea	dx, buffer
	call	ObjCallInstanceNoLock
	pop	bp

	mov	di, ds:[si]
	add	di, ds:[di].Pref_offset

	mov	cx, ds:[di].PIGI_originalNumSelections	
	cmp	ax, cx
	jne	changed

	; If original is zero, and new = original, then no change.

	jcxz	noChange

	lea	bx, buffer		; ss:bx - buffer
	cmp	cx, 1
	jne	compareMultiple

	; Only one item is selected, so compare it 
	
	mov	ax, ds:[di].PIGI_originalSelection
	cmp	ax, buffer
	je	noChange
	jmp	changed

compareMultiple:
	; CX = number items to compare
	; ss:bx - buffer of selected items

	push	ds, si
	mov	si, ds:[di].PIGI_originalSelection
	mov	si, ds:[si]

EC <	call	ECCheckLMemChunk	>

	segmov	es, ss, di
	mov	di, bx
	repe	cmpsw
	pop	ds, si

	je	noChange

changed:
	stc
	jmp	done

noChange:
	clc
done:
	.leave
	ret

PrefItemGroupHasStateChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Reset this item group to the state it had after
		MSG_META_LOAD_OPTIONS.

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= Segment of PrefItemGroupClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupReset	method	dynamic	PrefItemGroupClass, 
					MSG_GEN_RESET
	.enter

	mov	bp, ds:[di].PIGI_originalNumSelections
	tst	bp
	jz	none

	cmp	bp, 1
	je	single

	mov	ax, MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS
	mov	cx, ds
	mov	di, ds:[di].PIGI_originalSelection
	mov	dx, ds:[di]
	jmp	callIt
none:
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	jmp	callIt

single:
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, ds:[di].PIGI_originalSelection
	clr	dx
callIt:
	call	ObjCallInstanceNoLock

	call	UpdateText

	.leave
	ret
PrefItemGroupReset	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupGenLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle the low-level part

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= Segment of PrefItemGroupClass.
		ss:bp	- GenOptionsParams

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupGenLoadOptions	method	dynamic	PrefItemGroupClass, 
					MSG_GEN_LOAD_OPTIONS

EC <	call	ECCheckGenOptionsParams		>

	test	ds:[di].PIGI_initFileFlags, mask PIFF_USE_ITEM_STRINGS or \
		mask PIFF_USE_ITEM_MONIKERS
	jz	callSuper

	call	StringListLoadOptions
	ret

callSuper:
	mov	di, offset PrefItemGroupClass
	GOTO	ObjCallSuperNoLock
PrefItemGroupGenLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupMetaLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	handle the higher-level part

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= Segment of PrefItemGroupClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	The reason things are broken apart in this most infuriating
	fashion is that there is different behavior at the low level
	for the different classes (Ie, PrefDeviceList loads stuff
	differently than PrefItemGroup).  However, once the options
	are loaded, we want to collect the data and store it in the
	"original" fields. 

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupMetaLoadOptions	method	dynamic	PrefItemGroupClass, 
					MSG_META_LOAD_OPTIONS

		test	ds:[di].PIGI_initFileFlags,
					mask PIFF_SUSPEND_ON_LOAD_OPTIONS 
		jz	afterSuspend

		push	ax
		mov	ax, MSG_META_SUSPEND
		call	ObjCallInstanceNoLock
		pop	ax
		
afterSuspend:
		mov	di, offset PrefItemGroupClass
		call	ObjCallSuperNoLock

	; handle overrides, if any

		call	SelectOverrideIfNoneSelected

	;
	; Now, set the original state of this object
	;
		mov	ax, MSG_PREF_SET_ORIGINAL_STATE
		call	ObjCallInstanceNoLock

	;
	; Send out our status message, if any. 
	;

		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		clr	cx			; don't set MODIFIED flag
		call	ObjCallInstanceNoLock

	;
	; Update text associated with item group
	;
		call	UpdateText

	;
	; If suspended, unsuspend
	;
		DerefPref	ds, si, di
		test	ds:[di].PIGI_initFileFlags, 
					mask PIFF_SUSPEND_ON_LOAD_OPTIONS 
		jz	done

		mov	ax, MSG_META_UNSUSPEND
		GOTO	ObjCallInstanceNoLock
done:
		
		ret
PrefItemGroupMetaLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupSetOriginalState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the "original" state of the object, so that it
		will be returned to on a RESET

PASS:		*ds:si	- PrefItemGroupClass object
		ds:di	- PrefItemGroupClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupSetOriginalState	method	dynamic	PrefItemGroupClass, 
					MSG_PREF_SET_ORIGINAL_STATE
		uses	ax,cx,dx,bp
		.enter
		
	;
	; Get the # of selections. If only one, then just get it.
	;
		
		mov	ax, MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS
		call	ObjCallInstanceNoLock
		mov_tr	bx, ax				; bx <- num selections

	; None selected?

		mov	ax, GIGS_NONE
		tst	bx
		jz	storeOriginals

	; One selected?

		cmp	bx, 1
		je	getSingle

	;
	; Otherwise, allocate a chunk, and read in all the selections.
	;
		mov	cx, bx			; num selections
		shl	cx, 1			; size of chunk
		clr	al
		call	LMemAlloc
		mov	di, ax			; new chunk handle
		mov	dx, ds:[di]		; deref buffer
	
		mov	cx, ds
		mov	bp, bx			; num selections
		mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
		call	ObjCallInstanceNoLock
		mov	ax, di			; chunk handle of buffer
		jmp	storeOriginals

getSingle:
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock


storeOriginals:
	; ax - chunk handle of mult selections (or single selection)
	; bx - number of selections

		DerefPref	ds, si, di
		mov	ds:[di].PIGI_originalNumSelections, bx
		mov	ds:[di].PIGI_originalSelection, ax

		.leave
		ret
PrefItemGroupSetOriginalState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupSetItemState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Scan the hints -- do the right thang

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= Segment of PrefItemGroupClass.
		cx 	- identifier of item
		dx 	- nonzero if selected, zero otherwise

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupSetItemState	method	dynamic	PrefItemGroupClass, 
				MSG_GEN_ITEM_GROUP_SET_ITEM_STATE

		push	cx,dx
		mov	di, offset PrefItemGroupClass
		call	ObjCallSuperNoLock
		pop	cx,dx

		mov	ax, ATTR_PREF_ITEM_GROUP_OVERRIDE
		call	ObjVarFindData
		jnc	done

		call	PrefItemGroupOverride
done:
		ret

PrefItemGroupSetItemState	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupSendStatusMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle all of the SET_SELECTION messages and scan the
		var data

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= Segment of PrefItemGroupClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupSendStatusMsg	method	PrefItemGroupClass,
				MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	mov	di, offset PrefItemGroupClass
	call	ObjCallSuperNoLock
	FALL_THRU	PrefItemGroupScanVarData
PrefItemGroupSendStatusMsg	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupScanVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the var data handlers.  This should be done
		whenever an item changes.

CALLED BY:	PrefItemGroupSendStatusMsg

PASS:		*ds:si - item group

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefItemGroupScanVarData	proc far
		class	PrefItemGroupClass

		uses	es,ax,di

		.enter

		
	;
	; If we're suspended, then bail.
	;
		
		DerefPref	ds, si, di
		tst	ds:[di].PIGI_suspendCount
		jnz	done

	;
	; Otherwise, do it.
	;
		
		segmov	es, cs
		mov	ax, length PrefItemGroupVarDataHandlers
		mov	di, offset PrefItemGroupVarDataHandlers
		call	ObjVarScanData
done:
		.leave
		ret
PrefItemGroupScanVarData	endp


PrefItemGroupVarDataHandlers	VarDataHandler \
	<ATTR_PREF_ITEM_GROUP_ENABLE, EnableOrDisableObjects>,
	<ATTR_PREF_ITEM_GROUP_STATUS_TEXT, UpdateTextCommon>




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupOverride
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with an override

CALLED BY:	PrefItemGroupSetItemState

PASS:		cx - item being changed
		dx - nonzero if selected, zero otherwise
		*ds:si - item group
		ds:bx - address of identifier of override item

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefItemGroupOverride	proc far
	uses	cx,dx
	.enter


	mov	bx, ds:[bx]		; override item

	; On any deselect, make sure at least one item is selected

	tst	dx
	jz	selectOverrideIfNone

	; If selecting override item, deselect all others

	cmp	bx, cx
	jne	notOverride

	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	call	ObjCallInstanceNoLock
	jmp	selectOverrideIfNone

notOverride:
	; Otherwise, deselect the override item.  Note, this will cause
	; this routine to be called again, but it should pass
	; harmlessly through to the bottom.

	mov_tr	cx, bx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_ITEM_STATE
	clr	dx
	call	ObjCallInstanceNoLock
	jmp	done

selectOverrideIfNone:
	call	SelectOverrideIfNoneSelected
done:
	.leave
	ret
PrefItemGroupOverride	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectOverrideIfNoneSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the override if no other items are selected.

CALLED BY:	PrefItemGroupOverride, 
		PrefItemGroupMetaLoadOptions

PASS:		*ds:si - prefItemgroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectOverrideIfNoneSelected	proc near
	uses	ax,bx,cx,dx
	.enter
	mov	ax, ATTR_PREF_ITEM_GROUP_OVERRIDE
	call	ObjVarFindData
	jnc	done
	mov	bx, ds:[bx]		; override identifier

	mov	ax, MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS
	call	ObjCallInstanceNoLock
	tst	ax
	jnz	done

	mov	cx, bx			; override item
	clr	dx			; no indeterminates
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
SelectOverrideIfNoneSelected	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableOrDisableObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable any objects linked to this item
		group based on the state of the items in the group.

CALLED BY:	ObjVarScanData via PrefItemGroupSetItemState

PASS:		ds:bx - var data PrefEnableData structure
		*ds:si - PrefItemGroup object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableOrDisableObjects	proc far
		class	PrefItemGroupClass
	;
	; Fetch the vardata
	;
		push	ds:[bx].PED_lptr
		mov	cx, ds:[bx].PED_item
		mov	bl, ds:[bx].PED_flags

		test	bl, mask PEF_DISABLE_IF_NONE
		jz	checkItem

	;
	; Don't check this item -- just check the number of selections
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS
		call	ObjCallInstanceNoLock
		mov	bh, al
		or	bh, ah
		jmp	gotFlag

checkItem:
	;
	; Check this particular item  
	;
		clr	bh		; not enabled
		mov	ax, MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
		call	ObjCallInstanceNoLock
		jnc	checkFlag
		not	bh		; enabled
checkFlag:
		test	bl, mask PEF_DISABLE_IF_SELECTED
		jz	gotFlag
		not	bh

gotFlag:
		mov	ax, MSG_GEN_SET_ENABLED
		tst	bh
		jnz	sendIt
		inc	ax
		CheckHack <MSG_GEN_SET_NOT_ENABLED eq MSG_GEN_SET_ENABLED+1>
sendIt:
		pop	si
		mov	dl, VUM_NOW
		GOTO	ObjCallInstanceNoLock

EnableOrDisableObjects	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save options

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= Segment of PrefItemGroupClass.
		ss:bp 	= GenOptionsParams

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupSaveOptions	method	dynamic	PrefItemGroupClass, 
					MSG_GEN_SAVE_OPTIONS
	.enter

EC <	call	ECCheckGenOptionsParams		>

	; See if we should use strings

	test	ds:[di].PIGI_initFileFlags, mask PIFF_USE_ITEM_STRINGS \
			or mask PIFF_USE_ITEM_MONIKERS
	jz	callSuper

	call	StringListSaveOptions
	jmp	done

callSuper:

	; All other types handled by superclass

	mov	ax, MSG_GEN_SAVE_OPTIONS
	mov	di, offset PrefItemGroupClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret
PrefItemGroupSaveOptions	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupSetOriginalSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the original selection (single) for the item group	

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= Segment of PrefItemGroupClass.
		cx	= selection

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupSetOriginalSelection	method	dynamic	PrefItemGroupClass, 
				MSG_PREF_ITEM_GROUP_SET_ORIGINAL_SELECTION

	uses	ax,cx,dx,bp
	.enter
	mov	ds:[di].PIGI_originalSelection, cx
	mov	ds:[di].PIGI_originalNumSelections, 1
	clr	dx			; no indeterminates
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefItemGroupSetOriginalSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update any text display objects

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupApply	method	dynamic	PrefItemGroupClass, 
					MSG_GEN_APPLY

		tst	ds:[di].PIGI_suspendCount
		jnz	done

		push	ax
		call	UpdateText
		pop	ax

		mov	di, offset PrefItemGroupClass
		GOTO	ObjCallSuperNoLock

done:
		ret
PrefItemGroupApply	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the GenText object if any on APPLY/RESET

CALLED BY:

PASS:		*ds:si - PrefItemGroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:	
	We have to copy the text to the stack first because
	REPLACE_ALL_PTR can't deal with text in the same block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateText	proc near

	mov	ax, ATTR_PREF_ITEM_GROUP_TEXT_DISPLAY
	call	ObjVarFindData
	jnc	done

	call	UpdateTextCommon
done:
	ret
UpdateText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateTextCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text object to the selected item's moniker

CALLED BY:	UpdateText, ObjVarScanData via 

PASS:		ds:bx - address of vardata (lptr of text object)
		*ds:si - PrefItemGroup		

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateTextCommon	proc far

		class	PrefItemGroupClass

		.enter

		DerefPref	ds, si, di
		tst	ds:[di].PIGI_suspendCount
		jnz	done

		mov	cx, ds:[bx]
		mov	ax, MSG_PREF_ITEM_GROUP_UPDATE_TEXT
		call	ObjCallInstanceNoLock
done:

		.leave	
		ret
UpdateTextCommon	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the text object with the selected item's text

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= dgroup
		*ds:cx	- text object to update
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupUpdateText	method	dynamic	PrefItemGroupClass, 
					MSG_PREF_ITEM_GROUP_UPDATE_TEXT

SBCS <textBuf	local	MAX_TEXT_BUFFER_SIZE dup (char)			>
DBCS <textBuf	local	MAX_TEXT_BUFFER_SIZE dup (wchar)		>

	.enter

	push	cx		; lptr of text object


	; Null-initialize the string, in case the message isn't handled

SBCS <	mov	{char} textBuf, 0					>
DBCS <	mov	{wchar} textBuf, 0					>

	push	bp
	mov	cx, ss
	lea	dx, ss:[textBuf]
	mov	bp, MAX_TEXT_BUFFER_SIZE
	mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
	call	ObjCallInstanceNoLock
	pop	bp

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	pop	si			; text object
	
	push	bp
	mov	bp, dx
	mov	dx, cx
	clr	cx
	call	ObjCallInstanceNoLock

	;
	; Have the text send out its status message, if any
	;

	mov	ax, MSG_GEN_TEXT_SEND_STATUS_MSG
	call	ObjCallInstanceNoLock
	pop	bp

	.leave
	ret
PrefItemGroupUpdateText	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupGetSelectedItemText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the moniker of the (first) selected item

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= dgroup
		cx:dx	= buffer in which to place text
		bp 	= length of buffer (# chars)

RETURN:		bp 	- number of characters returned (0 if no selection)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefItemGroupGetSelectedItemText	method	dynamic	PrefItemGroupClass, 
				MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
	.enter

CheckHack	<size GetItemMonikerParams	eq 8>
CheckHack	<offset GIMP_identifier		eq 0>
CheckHack	<offset GIMP_bufferSize		eq 2>
CheckHack	<offset GIMP_buffer		eq 4>

	push	cx, dx		; buffer

	push	bp		; buffer Size
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock
	jc	popBPDone
	
	push	ax			; selection
	mov	bp, sp
	mov	ax, MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
	call	ObjCallInstanceNoLock

	add	sp, 4		; get identifier & buffer size off
				; stack -- clears carry (sp can't wrap)
				
done:
	pop	cx, dx
	.leave
	ret

popBPDone:
	pop	bp
	mov	bp, 0		; don't trash carry
	jmp	done
PrefItemGroupGetSelectedItemText	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize the item group -- setting it usable/not
		usable, etc.  Also send this to children, unless this
		object is a dynamic list.

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupInit	method	dynamic	PrefItemGroupClass, 
					MSG_PREF_INIT

	push	ax, cx, dx, bp
	mov	di, offset PrefItemGroupClass
	call	ObjCallSuperNoLock
	pop	ax, cx, dx, bp

	;
	; Send this to our children, unless this is a dynamic list.
	;

	mov	di, offset PrefDynamicListClass
	call	ObjIsObjectInClass
	jc	done

	mov	bx, offset PrefSendToPrefClassCB
	call	PrefProcessChildren
done:
	ret
PrefItemGroupInit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupGetItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the moniker of an item

PASS:		*ds:si	= PrefItemGroupClass object
		ds:di	= PrefItemGroupClass instance data
		es	= dgroup
		ss:bp	- GetItemMonikerParams

RETURN:		bp - # of characters returned

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupGetItemMoniker	method	dynamic	PrefItemGroupClass, 
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
		uses	ax,cx,dx
		.enter

	;
	; Get the optr of the item from its identifier
	;

		push	bp
		mov	cx, ss:[bp].GIMP_identifier
		mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
		call	ObjCallInstanceNoLock
		jc	cont
	;
	; There was an error so return 0 charatcers
	;
		pop	bp
		clr	bp
		jmp	exit
cont:
	;
	; Fetch the item's moniker
	;

		mov	bx, cx			; item's handle
		call	ObjLockObjBlock
		mov	ds, ax
	
		mov	si, dx
		mov	ax, MSG_GEN_GET_VIS_MONIKER
		call	ObjCallInstanceNoLock	
		mov	si, ax			; *ds:si - moniker
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx
		add	si, offset VM_data + VMT_text
		sub	cx, offset VM_data + VMT_text
DBCS <		shr	cx, 1			; # bytes -> # chars	>
DBCS <		ERROR_C	DBCS_ERROR					>
		pop	bp

		cmp	cx, ss:[bp].GIMP_bufferSize
		ja	tooBig

		les	di, ss:[bp].GIMP_buffer
		mov	bp, cx
		LocalCopyNString

done:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
exit:
		.leave
		ret
tooBig:
		clr	bp
		jmp	done
PrefItemGroupGetItemMoniker	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefItemGroupClass object
		ds:di	- PrefItemGroupClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupSuspend	method	dynamic	PrefItemGroupClass, 
					MSG_META_SUSPEND
		inc	ds:[di].PIGI_suspendCount
EC <		ERROR_Z INVALID_SUSPEND_COUNT		>
		mov	di, offset PrefItemGroupClass
		GOTO	ObjCallSuperNoLock
PrefItemGroupSuspend	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupUnSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefItemGroupClass object
		ds:di	- PrefItemGroupClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefItemGroupUnSuspend	method	dynamic	PrefItemGroupClass, 
					MSG_META_UNSUSPEND

		dec	ds:[di].PIGI_suspendCount
EC <		cmp	ds:[di].PIGI_suspendCount, -1	>
EC <		ERROR_E INVALID_SUSPEND_COUNT		>

		mov	di, offset PrefItemGroupClass
		GOTO	ObjCallSuperNoLock

PrefItemGroupUnSuspend	endm


