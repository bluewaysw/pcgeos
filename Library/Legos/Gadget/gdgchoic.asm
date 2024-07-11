COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdgchoic.asm

AUTHOR:		Ronald Braunstein, Jun  9, 1995

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_RESOLVE_VARIANT_SUPERCLASS
				Inform the system of our association to
				GenChoice

    MTD MSG_ENT_INITIALIZE	Create a singe GenItem inside.

    MTD MSG_GADGET_GET_CAPTION	Set and get the caption of the item, not
				the group

    MTD MSG_GADGET_SET_CAPTION	Replaces the moniker with the string passed
				in.

    MTD MSG_GADGET_CHOICE_GET_SELECTED_COMPONENT
				Figures out which sibling is selected. This
				can be sent to any of the choices.

 ?? INT GadgetChoiceGetSelectedComponentCallback
				Checks to see if the current component is a
				selected choice

    MTD MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
				Unselect and sibling choices and select
				this one

    MTD MSG_ENT_GET_CLASS	return "choice"

    MTD MSG_GADGET_CHOICE_GET_STATUS
				Get the selected status of this choice

    MTD MSG_GADGET_CHOICE_SET_STATUS
				Sets the choice either on or off. This
				won't send out a changed event.

    MTD MSG_GADGET_CHOICE_GET_CHOICE
				Get the selected sibling of the choice.

    MTD MSG_GADGET_CHOICE_SET_CHOICE
				Sets the choice either on or off. This
				won't send out a changed event.

    MTD MSG_GADGET_CHOICE_STATUS_MSG
				Call basic code to notify the change.

    MTD MSG_META_START_SELECT	Don't send double presses as we don't deal
				with them.

    MTD MSG_GADGET_SET_GRAPHIC	Extracts the GSTRING or BITMAP from the
				LegosComplex passed in the ComponentData
				protion of the SetPropertyArgs and sets the
				graphic moniker of this object from
				that. Set the moniker on the item, not the
				item group

    MTD MSG_META_GAINED_SYS_FOCUS_EXCL
				We have gained the system focus so tell the
				keyboard components.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/ 9/95   	Initial revision


DESCRIPTION:

	A choice component is a GenItemGroup / GenItem pair.  There is
	only one GenItem per ItemGroup.  Exclusive behavior is gained
	by explicity asking all siblings if they are selected.  The
	component part is the GenItemGroup (It gets the Ent Messages).
	The Item does not have an Ent part and is only used for some
	focus behavior anywhere.  The GenItem is created dynamically
	during EntInitialize for the component.  The choice subclasses
	the gadget moniker property so it can set the moniker on the
	item.

	Selection events get sent to both the newly selected choice
	and the previously selected choice.  Great care is spent
	sending the event to the choice being unselected first.  We
	use the modified bit to know if we should actually send
	events.  This allows us to only send events on user
	interaction and not send events when a choice is set via basic
	code (this helps to avoid infinite loops).

	$Id: gdgchoic.asm,v 1.1 98/03/11 04:31:27 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	GadgetChoiceClass

	GenItemFocusClass
	; The only reason for this subclass is to tell the keyboard
	; components that the system focus has changed.  GadgetChoice
	; will not get the system focus, but its GenItemFocus child will.
	;

idata	ends

GadgetListCode	segment	resource
makePropEntry choice, status, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CHOICE_GET_STATUS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CHOICE_SET_STATUS>

makePropEntry choice, choice, LT_TYPE_COMPONENT,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CHOICE_GET_CHOICE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CHOICE_SET_CHOICE>

makeUndefinedPropEntry choice, readOnly

compMkPropTable GadgetChoiceProperty, choice, status, choice, readOnly


GadgetInitCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association to GenChoice

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
RETURN:		cx:dx	= superclass to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceMetaResolveVariantSuperclass	method dynamic GadgetChoiceClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter

	cmp	cx, Gadget_offset
	je	returnSuper

	mov	di, offset GadgetChoiceClass
	call	ObjCallSuperNoLock
done:
	.leave
	ret

returnSuper:
	mov	cx, segment GenItemGroupClass
	mov	dx, offset GenItemGroupClass
	jmp	done

GadgetChoiceMetaResolveVariantSuperclass	endm

GadgetInitCode	ends
MakePropRoutines Choice, choice
GadgetInitCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a singe GenItem inside.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceEntInitialize	method dynamic GadgetChoiceClass, 
					MSG_ENT_INITIALIZE
		self	local	nptr	push	si
		item	local	nptr
		.enter
		mov	di, offset GadgetChoiceClass
		call	ObjCallSuperNoLock
		
	;
	; Create a GenItem in same block
	;
		mov	bx, ds:[LMBH_handle]
		mov	ax, segment GenItemFocusClass
		mov	es, ax
		mov	di, offset GenItemFocusClass
		call	ObjInstantiate
		mov	ss:[item], si

	;
	; Add the item beneath the ItemGroup and set the item usable
	;
		push	bp
		mov	ax, MSG_GEN_ADD_CHILD
		mov	cx, bx
		mov	dx, si
		mov	si, ss:[self]
		mov	bp, CCO_FIRST
		call	ObjCallInstanceNoLock

	;
	; Send some useful init messages to the item group
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		clr	dx
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_ITEM_GROUP_SET_BEHAVIOR_TYPE
		mov	cl, GIGBT_EXCLUSIVE_NONE
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_ITEM_GROUP_SET_DESTINATION
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	ObjCallInstanceNoLock

		pop	bp


	; now set us up to recieve the status message
		mov	ax, ATTR_GEN_ITEM_GROUP_STATUS_MSG
		mov	cx, 2
		call	ObjVarAddData
		mov	ds:[bx], MSG_GADGET_CHOICE_STATUS_MSG
				
		mov	di, ds:[si]			; deref handle
		add	di, ds:[di].GadgetChoice_offset
		mov	si, ss:[item]
		mov	ds:[di].GCI_item, si
	;
	; Now, send some messages to the new item.
	;

		push	bp
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
	;
	; Set the identifier for the Boolean
	;
		mov	ax, MSG_GEN_BOOLEAN_SET_IDENTIFIER
		mov	cx, 1
		call	ObjCallInstanceNoLock

		pop	bp
		
		.leave
		Destroy ax, cx, dx, bp	
		ret
GadgetChoiceEntInitialize	endm

GadgetInitCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceGadgetGetCaption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set and get the caption of the item, not the group

CALLED BY:	MSG_GADGET_GET_CAPTION
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
		^fss:bp	= GetPropertyArgs
RETURN:		*(ss:[bp].GPA_compDataPtr).CD_data.LD_string filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceGadgetGetCaption	method dynamic GadgetChoiceClass, 
					MSG_GADGET_GET_CAPTION
		.enter
		mov	si, ds:[di].GCI_item
		call	GadgetGetCaption
		.leave
		ret

GadgetChoiceGadgetGetCaption	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceGadetSetCaption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the moniker with the string passed in.

CALLED BY:	MSG_GADGET_SET_CAPTION
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es	= segment of GadgetChoiceClass
		ax	= message #
		^fss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceGadgetSetCaption	method dynamic GadgetChoiceClass, 
					MSG_GADGET_SET_CAPTION
		.enter
		mov	si, ds:[di].GCI_item
		call	GadgetSetCaption
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetChoiceGadgetSetCaption	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceGetSelectedComponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figures out which sibling is selected.
		This can be sent to any of the choices.

CALLED BY:	MSG_GADGET_CHOICE_GET_SELECTED_COMPONENT
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
		cx	= 0 if should ignore self, 1 if include
RETURN:		cx:dx	= selected component (item group) or 0
		CF set iff found
DESTROYED:	di, ax, bp, es [callback destroys es]
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceGetSelectedComponent	method dynamic GadgetChoiceClass, 
					MSG_GADGET_CHOICE_GET_SELECTED_COMPONENT
		.enter
	;
	; Get parent
	;
		mov	bp, cx
		mov	ax, MSG_ENT_GET_PARENT
		call	ObjCallInstanceNoLock
		mov	bx, cx			; parent == cx:dx or bx:dx
		jcxz	done

	;
	; Set cxdx to self if we should ignore self or 0 if not
	;
		push	dx		; parent chunk
		clrdw	cxdx
		tst	bp		; bp 0 to ignore, flag NZ to ignore
		jnz	setupCallback
		mov	cx, ds:[LMBH_handle]
		mov	dx, si		; cx:dx = self

setupCallback:
		pop	si		; parent chunk
	; lock down parent block
		push	bx
		call	ObjLockObjBlock
		mov	ds, ax

		mov	bx, offset Ent_offset
		mov	di, offset EI_comp
		clr	bp
		pushdw	bpbp
		mov	ax, offset EI_link
		push	ax
		mov	ax, offset GadgetChoiceGetSelectedComponentCallback
		pushdw	csax
		call	ObjCompProcessChildren
		pop	bx
		call	MemUnlock
done:
		.leave
		Destroy ax, bp
		ret

		
GadgetChoiceGetSelectedComponent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceGetSelectedComponentCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the current component is a selected
		choice

CALLED BY:	MSG_GADGET_CHOICE_GET_SELECTED_COMPONENT_CALLBACK
PASS:		*ds:si	= GadgetChoiceClass object
		*es:di	= composite
		ax	= message #
		cx:dx	= component to skip if any
		
RETURN:		CF	set iff found
		cx:dx	= Component (ItemGroup) 
DESTROYED:	ax, bp, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceGetSelectedComponentCallback	proc	far

		.enter
	;
	; Check to see if this object is a choice
	;
		mov	ax, segment GadgetChoiceClass
		mov	es, ax
		mov	di, offset GadgetChoiceClass
		call	ObjIsObjectInClass
		jnc	done
	;
	; If we are supposed to skip this component, then do so.
	;
		mov	ax, ds:[LMBH_handle]
		cmpdw	axsi, cxdx
		je	done
		
	;
	; Now see if the item is selected in this group
	;
		pushdw	cxdx			; object to ignore
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		popdw	cxdx			; object to ignore
EC <		mov	di, -1						>
		Assert 	e di, GIGS_NONE
		cmp	ax, GIGS_NONE
						; ax can never be greater \
						; than -1 (unsigned) so this \
						; this hack works :)
		jnc	done			; if not found, don't trash \
						; cxdx
		mov	cx, ds:[LMBH_handle]
		mov	dx, si

done:
		.leave
		Destroy	ax, bp, di
		ret

GadgetChoiceGetSelectedComponentCallback	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceGenItemGroupSetSingleSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unselect and sibling choices and select this one

CALLED BY:	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
		cx	= indentifier of the item to select
			  (should always be 1 in our case)
		dx	= non-zero if indeterminate
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		If this is a user interaction:
			Get old selected component.
			Set modifed bit on old component
			Send old component Status change (so it gets an event)
			Send message to superclass so we change.
			Superclass will send status change to us.

		If this is a property being set:
			modified bit shouldn't be set on new or old selection
			don't send status changes.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceGenItemGroupSetSingleSelection	method dynamic GadgetChoiceClass, 
					MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		.enter
		mov	ax, MSG_GADGET_CHOICE_GET_SELECTED_COMPONENT
		call	ObjCallInstanceNoLock
		jnc	setNew
	;
	; If we are modified, then set the old choice modified
	;
		push	si			; new component

		pushdw	cxdx			; old component
		mov	ax, MSG_GEN_ITEM_GROUP_IS_MODIFIED
		call	ObjCallInstanceNoLock
		popdw	bxsi			; old component
		jnc	setNotSelected
		
		mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
		mov	cx, 1
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage

setNotSelected:
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		clr	dx
		call	ObjMessage
		pop	si		; component to select (self)

setNew:
		
	;
	; Set *ds:si selected;
	;

		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, 1
		clr	dx
		mov	di, offset GadgetChoiceClass
		call	ObjCallSuperNoLock
		.leave
		Destroy	ax, cx, dx, bp	
		ret
GadgetChoiceGenItemGroupSetSingleSelection	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return "choice"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
RETURN:		cx:dx	= fptr.char

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceGetClass	method dynamic GadgetChoiceClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetChoiceString
		mov	dx, offset GadgetChoiceString
		ret
GadgetChoiceGetClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceGetStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selected status of this choice

CALLED BY:	MSG_GADGET_CHOICE_GET_STATUS
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceGetStatus	method dynamic GadgetChoiceClass, 
					MSG_GADGET_CHOICE_GET_STATUS
		.enter

		push	bp
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pop	bp

	; ax = id of selected item or GIGS_NONE
		clr	cx
		cmp	ax, GIGS_NONE
		je	setValue
		inc	cx	; return 1 if we're selected
setValue:
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetChoiceGetStatus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceSetChoice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the choice either on or off.
		This won't send out a changed event.

CALLED BY:	MSG_GADGET_CHOICE_SET_STATUS
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceSetStatus	method dynamic GadgetChoiceClass, 
					MSG_GADGET_CHOICE_SET_STATUS
		.enter
		
		Assert	fptr ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	wrongType
		mov	cx, es:[di].CD_data.LD_integer

		push	bp
		clr	dx				; determinated
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		jcxz	setChoice
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
setChoice:
		mov	cx, 1				; id of item if needed
		mov	di, offset GadgetChoiceClass
		call	ObjCallInstanceNoLock

	;
	; Send a status message so we can clear the extra selection
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		clr	cx
		call	ObjCallInstanceNoLock
		pop	bp
		
done:		
		.leave
		ret
wrongType:
	;	FIXME -- add code here
		jmp	done
GadgetChoiceSetStatus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceGetChoice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selected sibling of the choice.

CALLED BY:	MSG_GADGET_CHOICE_GET_CHOICE
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceGetChoice	method dynamic GadgetChoiceClass, 
					MSG_GADGET_CHOICE_GET_CHOICE
		.enter

		push	bp
		mov	cx, 1				; allow self
		mov	ax, MSG_GADGET_CHOICE_GET_SELECTED_COMPONENT
		call	ObjCallInstanceNoLock
		pop	bp
		jc	returnComponent
		clrdw	cxdx
returnComponent:
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_COMPONENT
		movdw	es:[di].CD_data.LD_comp, cxdx
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetChoiceGetChoice	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceSetChoice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the choice either on or off.
		This won't send out a changed event.

CALLED BY:	MSG_GADGET_CHOICE_SET_CHOICE
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

method GadgetUtilReturnReadOnlyError, GadgetChoiceClass, MSG_GADGET_CHOICE_SET_CHOICE
if 0
	;
	; This doesn't seem to work and was taken out of the spec
	; But I just can't get myself to delete it yet.
	;
GadgetChoiceSetChoice	method dynamic GadgetChoiceClass, 
					MSG_GADGET_CHOICE_SET_CHOICE
		uses	bp
		.enter
		
		Assert	fptr ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_COMPONENT
		jne	wrongType
		push	ds, si, es
		movdw	bxsi, es:[di].CD_data.LD_comp

	;
	; Check if they are changing the choice or clearing it.
	;
		cmp	bx, 0
		je	clearChoice

	;
	; To change the choice, just tell the new choice to select itself
	; pass in component to set in bx:si
;setChoice:
		clr	dx				; determinate
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, 1				; id of item if needed
		clr	di
		call	ObjMessage
		jmp	done
	;
	; To clear the choice, find the selected one and deselect it.
	;
clearChoice:
		mov	cx, 1				; allow self
		mov	ax, MSG_GADGET_CHOICE_GET_SELECTED_COMPONENT
		call	ObjCallInstanceNoLock
		jnc	done		; nothing to deselect

		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		clr	dx
		clr	di
		call	ObjMessage

done:
		pop	ds, si, es
	;
	; Send a status message so we can clear the extra selection
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		clr	cx
		call	ObjCallInstanceNoLock
		.leave
		ret
wrongType:
	; FIXME - add code here
		jmp	done
GadgetChoiceSetChoice	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceGenApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call basic code to notify the change.

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
		cx	= current selection or GIGS_NONE
		bp	= number of selections
		dl 	= GenItemGroupFlags
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If None selected:
		if not modified
			leave
		else
			send basic event
	else
		if not modified
			unselect old (not self)
			leave
		else
			set old modified
			unselect old (send message to self)
			send basic event

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
changedString	TCHAR "changed", C_NULL, C_NULL
GadgetChoiceGenApply	method dynamic GadgetChoiceClass,
					MSG_GADGET_CHOICE_STATUS_MSG
		self	local	nptr		push	si
		flags	local	word		push	dx
		params	local	EntHandleEventStruct
		result	local	ComponentData
ForceRef	result		; Not used yet, mayber later
		.enter
		cmp	cx, GIGS_NONE
		jne	gotSelected
	;
	; We just became unselected
	; If we aren't modified by user, then leave, else send event
	;
		test	dl, mask GIGSF_MODIFIED
		LONG jz	done
		jmp	sendEvent
gotSelected:
	;
	; We just became selected
	; If we aren't modifed by user, just unselect old
	; else modify and unselect old.
	;

		push	bp
		mov	ax, MSG_GADGET_CHOICE_GET_SELECTED_COMPONENT
		clr	cx
		call	ObjCallInstanceNoLock
		pop	bp
	; If nothing was selected then just send the selected event
		jnc	sendEvent
	; old in cx:dx
;; unselectOld:
		push	bp
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		movdw	bxsi, cxdx
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		clr	dx
		call	ObjMessage

	;
	; Send the old one a status msg as the the system doesn't
	; automatically do it.
	;
		pop	bp
		push	bp
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		clr	cx
		mov	dx, ss:[flags]
		test	dl, mask GIGSF_MODIFIED
		jz	updateStatus
		inc	cx
updateStatus:
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
sendEvent:
	;
	; Now inform the user, unless not modifed
	;
		mov	dx, ss:[flags]
		test	dl, mask GIGSF_MODIFIED
		jz	done
		mov	si, ss:[self]
		mov	ax, offset changedString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		mov	dx, ax
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 0
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock

done:		
		.leave
		ret
GadgetChoiceGenApply		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceMetaStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't send double presses as we don't deal with them.

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceMetaStartSelect	method dynamic GadgetChoiceClass, 
					MSG_META_START_SELECT
		.enter
		mov	di, offset GadgetChoiceClass
		BitClr	bp, BI_DOUBLE_PRESS
		call	ObjCallSuperNoLock
		.leave
		ret
GadgetChoiceMetaStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceSetGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extracts the GSTRING or BITMAP from the LegosComplex passed 
		in the ComponentData protion of the SetPropertyArgs and sets
		the graphic moniker of this object from that. Set the moniker
		on the item, not the item group

CALLED BY:	MSG_GADGET_SET_GRAPHIC
PASS:		*ds:si	= GadgetChoiceClass object
		ds:di	= GadgetChoiceClass instance data
		ds:bx	= GadgetChoiceClass object (same as *ds:si)
		es 	= segment of GadgetChoiceClass
		ax	= message #
		^fss:bp	= SetPropertyArgs

RETURN:		nothing
DESTROYED:	ax, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceSetGraphic	method dynamic GadgetChoiceClass, 
					MSG_GADGET_SET_GRAPHIC
		.enter
		mov	dx, ds:[di].GCI_item 	; GenItem to get moniker
		call	GadgetSetGraphicOnObject
		
		.leave
		Destroy ax, cx, dx
		ret
GadgetChoiceSetGraphic	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetChoiceSetLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the look for the group.  Removes old looks if needed.

CALLED BY:	MSG_GADGET_SET_LOOK
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/17/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetChoiceSetLook	method dynamic GadgetChoiceClass, 
					MSG_GADGET_SET_LOOK
		.enter

	;
	; have our superclass set the look
	;
		mov	di, offset GadgetChoiceClass
		call	ObjCallSuperNoLock
	;
	; call utility to add and remove hints as necessary
	;
		mov	ax, GadgetChoiceLook		;ax <- maximum look
		mov	cx, length choiceHints		;cx <- length of hints
		segmov	es, cs
		mov	dx, offset choiceHints		;es:dx <- ptr to hints
		call	GadgetUtilSetLookHints
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetChoiceSetLook	endm

choiceHints word \
	HINT_ITEM_GROUP_TOOLBOX_STYLE
choiceRadioHints nptr \
	GadgetRemoveHint	;no: toolbox style
choiceToolHints nptr \
	GadgetAddHint		;toolbox style

CheckHack <length choiceRadioHints eq length choiceHints>
CheckHack <length choiceToolHints eq length choiceHints>
CheckHack <offset choiceRadioHints eq offset choiceHints+size choiceHints>
CheckHack <offset choiceToolHints eq offset choiceRadioHints+size choiceRadioHints>

ForceRef choiceRadioHints
ForceRef choiceToolHints

CheckHack <LOOK_CHOICE_RADIO_BUTTON eq 0>
CheckHack <LOOK_CHOICE_TOOL_BUTTON eq 1>

GadgetListCode	ends
