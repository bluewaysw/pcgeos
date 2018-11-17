COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CList (common code for specific UIs)
FILE:		citemBooleanGroup.asm

METHODS:
 Name			Description
 ----			-----------

ROUTINES:
 Name			Description
 ----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial revision

DESCRIPTION:
	$Id: citemBooleanGroup.asm,v 1.1 97/04/07 10:55:27 newdeal Exp $

-------------------------------------------------------------------------------@


ItemCommon	segment	resource






COMMENT @----------------------------------------------------------------------

METHOD:		OLBooleanGroupSetModifiedItemState -- 
		MSG_OL_ITEM_GROUP_SET_MODIFIED_ITEM_STATE 
		for OLBooleanGroupClass

DESCRIPTION:	Sets the modified item state for a boolean group.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_ITEM_GROUP_SET_MODIFIED_ITEM_STATE

		cx	- item 
		dh	- zero to deselect, non-zero to select
		dl	- OLItemUpdateFlags

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
	chris	3/ 2/92		Initial Version

------------------------------------------------------------------------------@

OLBooleanGroupSetModifiedItemState	proc	far

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLIGI_updateFlags, dl	;set update flags

	push	cx				;save item
	mov	dl, dh				;extend dh to word
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	call	ObjCallInstanceNoLock		;call message

	pop	cx				;restore item ID
	push	cx				;save it again
	clr	dx				;no longer indeterminate
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_INDETERMINATE_STATE
	call	ObjCallInstanceNoLock		;call message

	pop	cx				;restore item ID
	clr	dx				;none to clear
	push	cx				;save item again
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	call	ObjCallInstanceNoLock
	pop	cx				;restore item

	;
	; At this point, let's spit out a status message and apply message,
	; if appropriate.
	;
	;	cx -- item to indicate modified
	
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG
	call	ObjCallInstanceNoLock
	GOTO	FinishSetModifiedState

OLBooleanGroupSetModifiedItemState	endp





COMMENT @----------------------------------------------------------------------

METHOD:		OLBooleanGroupUpdateSpecificObject -- 
		MSG_SPEC_UPDATE_SPECIFIC_OBJECT for OLBooleanGroupClass

DESCRIPTION:	Handles updating of the specific representation of the item
		list.  This message assumes some change has been made.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_SPECIFIC_OBJECT

		cx	- changed booleans

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
	chris	2/27/92		Initial Version

------------------------------------------------------------------------------@

OLBooleanGroupUpdateSpecificObject	proc	far

	call	VisCheckIfSpecBuilt	; Make sure we're vis built.
	jnc	exit			; if not, quit.

EC <	tst	cx							>
EC <	ERROR_Z	OL_ERROR			;shouldn't happen	>

	mov	dl, ds:[di].OLIGI_updateFlags	;get update flags to pass
	;
	; If the user is pressing on an item, we'll reset all state, including
	; intermediate mode.  Unless, of course, we've set a certain flag
	; while in the process of ending intermediate mode.
	;
	test	dl, mask OLIUF_LEAVE_FOCUS_AND_GRAB_ALONE
	jnz	update
	call	OLItemGroupAbortAllUserInteraction
update:
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GBGI_selectedBooleans
	mov	bp, ds:[di].GBGI_indeterminateBooleans

	clr	bx				; initial child (first
	push	bx				; child of
	push	bx				; composite)
	mov	bx, offset GI_link		;pass offset to LinkPart
	push	bx
	mov	bx, SEGMENT_CS
	push	bx				;pass callback routine (seg)
	mov	bx, offset UpdateBoolean
	push	bx				;pass callback routine (off)
	mov	bx, offset Gen_offset		;pass offset to master part
	mov	di, offset GI_comp		;pass offset to composite
	call	ObjCompProcessChildren

	;
	; Check update flags to see if we can mess with focus.  Clear the
	; update flags for next time.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	clr	ds:[di].OLIGI_updateFlags	;clear update flags
exit:
	ret
OLBooleanGroupUpdateSpecificObject	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateBoolean

SYNOPSIS:	Updates a boolean based on our instance data.

CALLED BY:	OLBooleanGroupUpdateSpecificObject (via ObjCompProcessChildren)

PASS:		*ds:si -- item group
		ax     -- selected booleans
		bp     -- indeterminate booleans
		dl     -- OLItemUpdateFlags
		cx     -- bits that need updating

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/28/92		Initial version

------------------------------------------------------------------------------@

UpdateBoolean	proc	far		uses	ax, cx, dx, bp, si
	class	GenBooleanClass
	.enter
	;
	; Set OLIS_SELECTED and OLIS_INDETERMINATE based on the generic state.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GBI_identifier	;boolean's identifer in bx
	test	bx, cx				;object need an update?
	jz	exit				;no, exit

	mov	di, ax				;selected booleans in di
	clr	cx				;zero the state flags

	test	bx, di				;see if selected
	jz	10$				        
	or	cl, mask OLIS_SELECTED
10$:
	test	bx, bp				;see if indeterminate
	jz	20$				        
	or	cl, mask OLIS_INDETERMINATE
20$:
	mov	ax, MSG_OL_ITEM_SET_STATE	;update the item
	call	ObjCallInstanceNoLock
exit:
	.leave
	ret
UpdateBoolean	endp







COMMENT @----------------------------------------------------------------------

ROUTINE:	OLBooleanGroupCheckAllChildrenUnique
		MSG_OL_IGROUP_EC_CHECK_ALL_CHILDREN_UNIQUE
		for OLBooleanGroupClass

SYNOPSIS:	Make sure all children are unique.

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

if	ERROR_CHECK

OLBooleanGroupCheckAllChildrenUnique 	proc	far
	clr	cx				;no identifiers yet

	clr	bx				; initial child (first
	push	bx				; child of
	push	bx				; composite)
	mov	bx,offset GI_link		;pass offset to LinkPart
	push	bx
	mov	bx, SEGMENT_CS
	push	bx				;pass callback routine (seg)
	mov	bx,offset CheckBooleanUnique
	push	bx				;pass callback routine (off)
	mov	bx,offset Gen_offset		;pass offset to master part
	mov	di,offset GI_comp		;pass offset to composite
	call	ObjCompProcessChildren
	ret
OLBooleanGroupCheckAllChildrenUnique	endp

endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckBooleanUnique

SYNOPSIS:	Checks to make sure boolean has unique bits.

CALLED BY:	ObjCompProcessChildren (via ECCheckAllChildrenUnique)

PASS:		*ds:si -- child in question
		cx     -- or'ed sum of ID's done so far

RETURN:		cx     -- updated

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 2/92		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

CheckBooleanUnique	proc	far		
	class	GenBooleanClass

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GBI_identifier	;get ID
	test	cx, ax				;make sure no common bitfields
	ERROR_NZ	OL_ERROR_NO_TWO_BOOLEANS_CAN_HAVE_COMMON_BITFIELDS

	or	cx, ax				;or in this ID
	clc					;continue
	ret
CheckBooleanUnique	endp

endif

ItemCommon ends

;------------------------------

ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLBooleanGroupGetItemState -- 
		MSG_OL_IGROUP_GET_ITEM_STATE for OLBooleanGroupClass

DESCRIPTION:	Returns item state for any item.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_GET_ITEM_STATE

		cx	- item identifier

RETURN:		al      - OLItemState:
				OLIS_SELECTED if item is selected
				OLIS_INDETERMINATE if item is indeterminate
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		di 	(can be called statically)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/ 2/92		Initial Version

------------------------------------------------------------------------------@

OLBooleanGroupGetItemState	proc	far
	;
	; Return the proper indeterminate and selected state for the item.
	; (We'll do this in an optimized way, rather than send a message.)
	;
	clr	ax				;nothing to return yet
	call	IVC_DerefGenDI
	test	ds:[di].GBGI_selectedBooleans, cx
	jz	selectedStateSet
	or	al, mask OLIS_SELECTED

selectedStateSet:
	test	ds:[di].GBGI_indeterminateBooleans, cx
	jz	exit
	or	al, mask OLIS_INDETERMINATE
exit:
	ret
OLBooleanGroupGetItemState	endp

ItemVeryCommon ends

