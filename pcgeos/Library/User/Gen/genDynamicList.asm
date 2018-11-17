COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		GenDynamicList.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenDynamicListClass	Dynamic list object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

DESCRIPTION:
	This file contains routines to implement the dynamic list class.

	$Id: genDynamicList.asm,v 1.1 97/04/07 11:45:35 newdeal Exp $

------------------------------------------------------------------------------@

; see documentation in /staff/pcgeos/Library/User/Doc/GenDynamicList.doc
	
UserClassStructures	segment resource

; Declare the class record

	GenDynamicListClass

UserClassStructures	ends

;---------------------------------------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenDynamicListClass

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

GenDynamicListBuild	method	GenDynamicListClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_DYNAMIC_LIST
	GOTO	GenQueryUICallSpecificUI

GenDynamicListBuild	endm




COMMENT @----------------------------------------------------------------------

		GenDynamicListRelocOrUnReloc

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

GenDynamicListRelocOrUnReloc	method GenDynamicListClass, reloc
				; We only need to handle unrelocation, where
				; this object is about to go out to a state 
				; file.
	cmp	ax, MSG_META_UNRELOCATE
	je	unrelocateDynamicList

;relocateDynamicList:

EC <	tst	[di].GI_comp.CP_firstChild.handle			>
EC <	ERROR_NZ	UI_DYNAMIC_LIST_MAY_NOT_HAVE_STATIC_CHILDREN	>

	jmp	done

unrelocateDynamicList:
				; Clear out our generic child link.  All 
				; generic children created by the specific UI
				; should be created as IGNORE_DIRTY, so that
				; they will be tossed before going into the
				; state file.  We do NOT want to leave
				; a link in this object pointing
				; off in to space, now, do we?  No.
	clr	ax
	mov	[di].GI_comp.CP_firstChild.handle, ax
	mov	[di].GI_comp.CP_firstChild.chunk, ax

done:
	clc
	mov	di, offset GenDynamicListClass
	call	ObjRelocOrUnRelocSuper
	ret

GenDynamicListRelocOrUnReloc	endm


Build ends

DynaCommon segment resource


DC_DerefGenDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	ret
DC_DerefGenDI	endp

DC_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
DC_ObjCallInstanceNoLock	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListGetItemClass -- 
		MSG_GEN_DYNAMIC_LIST_GET_ITEM_CLASS for GenDynamicListClass

DESCRIPTION:	Returns item class.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_DYNAMIC_LIST_GET_ITEM_CLASS

RETURN:		cx:dx   - class to use for item
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/13/92		Initial Version

------------------------------------------------------------------------------@

GenDynamicListGetItemClass	method dynamic	GenDynamicListClass,
				MSG_GEN_DYNAMIC_LIST_GET_ITEM_CLASS

	mov	cx, segment GenItemClass
	mov	dx, offset GenItemClass
	ret
GenDynamicListGetItemClass	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	ItemsChangedCallback

SYNOPSIS:	Validates items that need changing.

CALLED BY:	ObjCompProcessChildren(via GenDynamicListNumVisibleItemsChanged)
				      (via GenDynamicListSetNumItems)

PASS:		*ds:si - item
		*es:di - parentu
		cx     - generic position of item
		dx     - position of first item needing changing
		bp     - identifier of item

RETURN:		carry clear to do all children

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/16/92		Initial version

------------------------------------------------------------------------------@

ItemsChangedCallback	proc	far
	class	GenDynamicListClass
   	.warn -unref_local

	numVisItems		local	word
	scrollOffset		local 	word
	leaveAlone		local	word
	moveIdentifierFlag	local	word

	mov	bx, bp
	.enter
	mov	moveIdentifierFlag, si		;need to set this non-zero
						;  so identifiers will be set
	;
	; Validate all items past the first item needing changing.
	;
	cmp	cx, dx				;needs changing?
	jb	skipItem			;no, skip item
	push	dx
	mov	dx, bx
	call	ValidateItem			;else validate the item
	pop	dx
skipItem:
	inc	cx				;bump position
	clc					;continue
	.leave
	inc	bp				;bump identifier

   	.warn @unref_local
	ret
ItemsChangedCallback	endp







COMMENT @----------------------------------------------------------------------

ROUTINE:	RemoveItemsCallback

SYNOPSIS:	Removes the appropriate number of items.

CALLED BY:	GenDynamicListNumVisibleItemsChanged

PASS:		*ds:si -- item
		cx     -- position
		dx     -- first item to remove
	
RETURN:		nothing

DESTROYED:	ax, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/16/92		Initial version

------------------------------------------------------------------------------@

RemoveItemsCallback	proc	far
	class	GenClass

	cmp	cx, dx
	jb	skipItem			;nothing to remove, continue
	push	cx, dx
	clr	bp				;shouldn't dirty
	mov	ax, MSG_GEN_DESTROY

	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	; was VUM_NOW , but causes 
						; problems when initializes
						; are done during UPDATE_UI,i.e.
						; a VIS_OPEN.  -cbh 3/ 9/93

	call	DC_ObjCallInstanceNoLock		;else remove ourselves

;	mov	dl, VUM_NOW
;	mov	bx, ds:[LMBH_handle]
;	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
;	call	ObjMessage

	pop	cx, dx
skipItem:
	inc	cx				;bump position
	clc					;continue
	ret
RemoveItemsCallback	endp







COMMENT @----------------------------------------------------------------------

ROUTINE:	ValidateItem

SYNOPSIS:	Validates an item, requesting its moniker, etc.

CALLED BY:	ItemsChangedCallback
		ForwardSetMkrs
		BackwardSetMkrs

PASS:		*ds:si -- item
		*es:di -- dynamic list
		dx     -- item identifier

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/16/92		Initial version

------------------------------------------------------------------------------@

ValidateItem	proc	near		uses	ax, cx, dx, bp, si
	numVisItems		local	word
	scrollOffset		local 	word
	leaveAlone		local	word
	moveIdentifierFlag	local	word
	class	GenDynamicListClass

	.enter	inherit
	;
	; Set the identifier for the item.
	;
	tst	moveIdentifierFlag		;not moving identifiers, branch
	jz	5$
	push	dx
	mov	cx, dx
	mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
	call	DC_ObjCallInstanceNoLock
	pop	dx
5$:
	;
	; First, see if this item should even be displayed (we may be at the
	; end of the list, and we may not have enough items to fill the screen)
	;
	call	ItemEnsuredUsable
	jnc	exit				;not usable, exit
	;
	; Nuke the existing moniker, set not interactable, and redraw.
	;
	push	di				;save list
	call	NukeExistingMoniker
	clr	cx				
	mov	ax, MSG_GEN_ITEM_SET_INTERACTABLE_STATE
	call	GenCallSpecIfGrown

	;
	; Now assume the item will be enabled, and set it as such.  The specific
	; may (read: will) expect to get a MSG_SPEC_NOTIFY_NOT_ENABLED for the
	; new item if it turns out to be disabled when the moniker comes in from
	; the app, so it can deal with keyboard navigation correctly.  
	; -cbh 6/24/92  (Changed to VUM_DELAYED..., as updates aren't readily
	; happening anymore. -cbh 5/19/93)
	;
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	;update done below...
	mov	ax, MSG_GEN_SET_ENABLED		;assume enabled
	call	ObjCallInstanceNoLock		;else set enabled

	;
	; Query for the item's moniker.
	;
	call	DC_DerefGenDI
.warn -private
	mov	bp, ds:[di].GII_identifier	;pass identifier (not necessary
						;  the same as that passed in!)
.warn @private
	pop	si				;restore list

	mov	di, 700
	call	ThreadBorrowStackSpace
	push	di

	mov	cx, ds:[LMBH_handle]		;ourselves in ^lcx:dx
	mov	dx, si
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
						;don't do this immediately!
						; my attempts to optimally
						; draw when all items become
						; interactable will fail.5/20/93
	mov	ax, MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
	call	ObjMessage

	pop	di
	call	ThreadReturnStackSpace

exit:
	.leave
	ret
ValidateItem	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListQueryItemMoniker -- 
		MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER for GenDynamicListClass

DESCRIPTION:	A dynamic list sends this to itself to query for an item's
		moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
		^lcx:dx - calling dynamic list
		bp      - item to get moniker for

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
	chris	4/ 1/92		Initial Version

------------------------------------------------------------------------------@

GenDynamicListQueryItemMoniker	method dynamic	GenDynamicListClass,
				MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER

	mov	ax, ds:[di].GDLI_queryMsg	;get query message
	tst	ax
	jz	exit				;none specified, exit

	mov	bx, offset GIGI_destination
	call	GenGetDWord		; destination in ^lcx:dx
	push	cx, dx			; push them for GenProcessAction
	mov	cx, ds:[LMBH_handle]	; ^lcx:dx <- ourselves
	mov	dx, si
	mov	di, mask MF_FIXUP_DS
	call	GenProcessAction	; send the message
exit:
	ret
GenDynamicListQueryItemMoniker	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	ItemEnsuredUsable

SYNOPSIS:	Ensures that an item is usable.  Sets the item usable or
		not usable as needed.  An item is set not usable if its
		identifier is outside the number of items.

CALLED BY:	ValidateItem, StoreItemInfo

PASS:		*ds:si -- item
		*ds:di -- dynamic list
		dx -- item identifier

RETURN:		carry set if item should be usable

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/16/92		Initial version

------------------------------------------------------------------------------@

ItemEnsuredUsable	proc	near	uses	di, cx, ax
	class	GenDynamicListClass
	.enter
	mov	di, ds:[di]			;dynamic list instance
	add	di, ds:[di].Gen_offset
	cmp	dx, ds:[di].GDLI_numItems	;see if within number of items
	jae	setNotUsable			;no, branch to set not usable

	mov	ch, TRUE
	stc					;set usable
	jmp	short finish

setNotUsable:
	clr	ch				;don't set usable
	clc					;return not usable
finish:
	pushf
	mov	cl, mask GS_USABLE
	call	SetGenState
	popf
	.leave
	ret
ItemEnsuredUsable	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetGenState

SYNOPSIS:	Sets or clears a GenStates flag.

CALLED BY:	ValidateItem, ObjectEnsuredUsable, StoreItemInfo

PASS:		*ds:si -- item
		cl -- GS_ENABLED or GS_USABLE
		ch -- non-zero to set, zero to clear
	
RETURN:		nothing

DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/16/92		Initial version

------------------------------------------------------------------------------@

SetGenState	proc	near
	class	GenClass

	call	DC_DerefGenDI

	tst	ch
	jz	clearing			;clearing, branch
;setting:
	mov	ax, MSG_GEN_SET_ENABLED
	test	cl, mask GS_ENABLED
	jnz	10$
	mov	ax, MSG_GEN_SET_USABLE
10$:
	test	ds:[di].GI_states, cl
	jnz	exit
	jmp	short update

clearing:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	test	cl, mask GS_ENABLED
	jnz	15$
	mov	ax, MSG_GEN_SET_NOT_USABLE
15$:
	test	ds:[di].GI_states, cl
	jz	exit

update:
	push	dx, bp
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	;VUM_MANUAL doesn't seem to work
						;VUM_NOW works, but causes 
						; problems when initializes
						; are done during UPDATE_UI,i.e.
						; a VIS_OPEN.  -cbh 2/12/93
	call	DC_ObjCallInstanceNoLock

;	mov	dl, VUM_NOW
;	mov	bx, ds:[LMBH_handle]
;	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
;	call	ObjMessage

	pop	dx, bp
exit:
	ret
SetGenState	endp








COMMENT @----------------------------------------------------------------------

ROUTINE:	NukeExistingMoniker

SYNOPSIS:	Nukes any moniker that's already there.

CALLED BY:	ValidateItem

PASS:		*ds:si -- item

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/16/92		Initial version

------------------------------------------------------------------------------@

NukeExistingMoniker	proc	near		uses	ax
	class	GenClass
	.enter
	call	DC_DerefGenDI
	clr	ax
	xchg	ax, ds:[di].GI_visMoniker
	tst	ax
	jz	10$
	call	LMemFree			;nuke the moniker
10$:
	.leave
	ret
NukeExistingMoniker	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	DoAllChildren

SYNOPSIS:	Processes all the dynamic list's generic children.

CALLED BY:	utility

PASS:		*ds:si -- parent
		di -- offset of routine to call		
		cx, dx, bp -- anything passed

RETURN:		cx, dx, bp -- anything returned

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/16/92		Initial version

------------------------------------------------------------------------------@

DoAllChildren	proc	far
	class	GenClass
;	mov	bx, ds:[si]			
;	add	bx, ds:[bx].Gen_offset
;	tst	ds:[bx].GI_comp.CP_firstChild.handle
;	jz	exit				;no children, exit
;
	clr	bx				;initial child (first
	push	bx				;    child of
	push	bx				;    composite)
	mov	bx,offset GI_link		;pass offset to LinkPart
	push	bx

NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
		
	mov	bx, di
	push	bx				;pass callback routine (off)
	mov	bx,offset Gen_offset		;pass offset to master part
	mov	di,offset GI_comp		;pass offset to composite
	call	ObjCompProcessChildren
;exit:
	ret
DoAllChildren	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListReplaceItemMoniker -- 
		MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER

DESCRIPTION:	Copys the moniker for the item passed.  This is basically
		a preprocessor for MSG_GEN_REPLACE_VIS_MONIKER.  It will first
		check to see if the dynamic list item the moniker is intended
		for is still on the screen.  If not, then it will exit.  If so,
		then it will first set any state flags for the item if it has
		any exclusives.  Then it will pass the moniker through
		to MSG_GEN_REPLACE_VIS_MONIKER.  It will always try to replace
		the moniker, since one will be created if there wasn't 
		originally a moniker assigned to it.

PASS: 		*ds:si	- instance data
		es	- segment of GenDynamicListClass
		ax	- MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
		dx	- # of bytes on stack
		ss:bp	- ReplaceItemMonikerFrame
		(For XIP'ed geodes, the fptrs in the ReplaceItemMonikerFrame
			*cannot* be pointing into the movable XIP code seg.)

RETURN:		nothing

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Clayton	12/89		Initial version

------------------------------------------------------------------------------@

GenDynamicListReplaceItemMoniker	method	dynamic GenDynamicListClass,
				MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	uses	ax,dx,si
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		cmp	ss:[bp].RIMF_sourceType, VMST_FPTR		>
EC <		jne	xipSafe						>
EC <		cmp	ss:[bp].RIMF_dataType, VMDT_NULL		>
EC <		je	xipSafe						>
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].RIMF_source			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
EC < xipSafe:								>
endif
	
	;
	; First, get the item being referenced in ^lbx:si.  If the object
	; isn't found, it probably got moved offscreen -- just exit.
	;
	call	GetItemOptr
	jnc	done				;not found, done

	;
	; Enable the item if needed.
	;
	push	si, ax
	movdw	bxsi, cxdx			;now in ^lbx:si
	mov	ax, MSG_GEN_SET_ENABLED		;assume enabled
	test	ss:[bp].RIMF_itemFlags, mask RIMF_NOT_ENABLED
	jz	10$				;should enable, branch
	mov	ax, MSG_GEN_SET_NOT_ENABLED
10$:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	;update no longer done below.
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessageBp			;else set enabled
	pop	dx, ax				;*ds:dx <- item group
						;ax <- identifier

	;
	; Alas, if we disabled the item, we must re-check our item's optr, 
	; since it might have caused the list to scroll around, changing things.
	;
	test	ss:[bp].RIMF_itemFlags, mask RIMF_NOT_ENABLED
	jz	20$				;is enabled, branch
	mov	si, dx				;*ds:si <- item group
	mov	cx, ax				;cx <- identifier
	call	GetItemOptr		
	jnc	done				;no longer visible, exit
	movdw	bxsi, cxdx			;now in ^lbx:si
20$:
	;
	; Now copy the moniker to the object.
	;	ss:bp = ReplaceItemMonikerFrame (extension of
	;		ReplaceVisMonikerFrame)
	;
	; We will assume a VUM_DELAYED_VIA_UI_QUEUE on the assumption that we
	; only want a single update to happen.  The specific UI can (and will,
	; for the scrolling version) subclass MSG_SPEC_UPDATE_VIS_MONIKER to
	; change the update mode.
	;
	mov	ss:[bp].RVMF_updateMode, VUM_DELAYED_VIA_APP_QUEUE
	mov	dx, size ReplaceVisMonikerFrame
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessageBp

	;
	; Mark the item interactable again.
	;
	mov	cx, si					;cx != 0 
	mov	ax, MSG_GEN_ITEM_SET_INTERACTABLE_STATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessageBp
done:
	.leave

	GOTO	GenCallSpecIfGrown

GenDynamicListReplaceItemMoniker	endm



ObjMessageBp	proc	near
	push	bp
	call	ObjMessage
	pop	bp
	ret
ObjMessageBp	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetItemOptr

SYNOPSIS:	Returns item optr

CALLED BY:	GenDynamicListReplaceItemMoniker

PASS:		*ds:si -- item group	
		ss:bp -- ReplaceItemMonikerFrame

RETURN:		^lcx:dx -- item 
		ax -- identifier
		carry set if not found

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/25/92		Initial version

------------------------------------------------------------------------------@

GetItemOptr	proc	near
	;
	; First, get the item being referenced in ^lbx:si.  If the object
	; isn't found, it probably got moved offscreen -- just exit.
	;
	mov	cx, ss:[bp].RIMF_item		;get the item number
	push	bp
	push	cx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	call	DC_ObjCallInstanceNoLock		;item in ^lcx:dx
	pop	ax
	pop	bp
	ret
GetItemOptr	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListViewOriginChanged -- 
		MSG_GEN_DYNAMIC_LIST_TOP_ITEM_CHANGED for GenDynamicListClass

DESCRIPTION:	View's origin changed. 

PASS:		*ds:si 	- instance data
		ds:di   - GenInstance
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_VIEW_ORIGIN_CHANGED

		cx	- top item
		dx	- previous top item
		bp 	- number of visible items

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
	chris	3/ 5/92		Initial Version

------------------------------------------------------------------------------@

GenDynamicListViewOriginChanged	method dynamic	GenDynamicListClass,
				MSG_GEN_DYNAMIC_LIST_TOP_ITEM_CHANGED

	clr	ax				;scroll all the way up
;	mov	di, -1				;need to move identifiers
						; (di already non-zero by
						;  definition of method handler)
	call	GenDynamicListScroll
	ret
GenDynamicListViewOriginChanged	endm







COMMENT @----------------------------------------------------------------------

ROUTINE:	GenDynamicListScroll

SYNOPSIS:	Scrolls some items in a dynamic list.

CALLED BY:	GenDynamicListTopItemChanged
		GenDynamicListDeleteItem
		GenDynamicListAddItems

PASS:		*ds:si -- dynamic list
		ax - items at the top to leave alone when scrolling
		cx - top item
		dx - top item before scroll (cx - scroll offset)
		bp - number of visible items
		di - move identifier flag (if non-zero, will reset identifiers
			for each item as the scrolling requires)

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	the idea is to move monikers from the source to the destination

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/18/92		Initial version

------------------------------------------------------------------------------@
;
; ItemInfo, used for moving item monikers and enabled states around.
;
ItemInfo	struct
	II_visMoniker	lptr	VisMoniker
		;Pointer to the item's moniker
	II_state	GenStates
		;Item's GS_ENABLED flag
ItemInfo	ends


GenDynamicListScroll	proc	near
	numVisItems	local	word
	scrollOffset	local 	word
	leaveAlone	local	word
	moveIdentifierFlag	local	word

	mov	bx, bp
	.enter
	mov	leaveAlone, ax			;items to leave alone
	mov	moveIdentifierFlag, di		;move identifier flag
	mov	ax, bx
	mov	numVisItems, ax			;keep number of items here
	;
	; Move monikers around as necessary.
	;
	mov	bx, cx				;bx <- newTop - prevTop,
	sub	bx, dx				;  or the "offset"
	mov	scrollOffset, bx		;store it
	jz	exit				;no change, exit
	js	scrollBackwards			;scrolling backwards, branch

	;
	; Scrolling forward.  In the first pass, nuke the first "offset"
	; items, and collect monikers from the rest into a stack frame which
	; we create.
	;
	sub	ax, bx				;subtract offset fr numVisItems
	mov	di, offset ForwardGetMkrs	;first pass routine
	mov	dx, offset ForwardSetMkrs
	jmp	short scroll

scrollBackwards:
	;
	; Scrolling backward.  In the first pass, nuke the last "offset"
	; items, and collect monikers from the rest into a stack frame which
	; we create.
	;
	add	ax, bx				;add offset to numVisItems
	mov	di, offset BackwardGetMkrs	;first pass routine
	mov	dx, offset BackwardSetMkrs	;second pass routine

scroll:
	;
	; Scroll away.
	;	ax -- size of ItemInfo buffer needed, before subtracting the
	;		items to leave alone
	;	cx -- new item item
	;	di -- first pass routine
	;	dx -- second pass routine
	;
	sub	ax, leaveAlone			;don't need these
	mov	bx, sp
	tst	ax				;too much to scroll, branch
	js	10$
	sub	sp, ax				;create a buffer for item info
	sub	sp, ax
	sub	sp, ax
10$:						CheckHack <(size ItemInfo) eq 3>
						;+0 = buffer on stack
	mov	ax, sp				;ss:ax points to buffer
	push	bx				;+1 save old stack pointer
	mov	bx, ds:[LMBH_handle]
	push	bx				;+2 save mem handle
	push	ax, cx, dx			;+5 save start of buffer, new
						;  top item, second pass rout
	clr	cx				;cx <- position	
	call	DoAllChildren			; get the monikers
	pop	ax, dx, di			;-5
	;
	; In the second pass, we'll set new monikers for the first items,
	; and request monikers for the last "offset" items.
	;	ax - start of buffer
	;	dx - new top item (identifier of first item)
	;	di - routine to call for second pass
	;
	push	ax				;+6 start of buffer
	clr	cx				;position
	call	DoAllChildren			;shift monikers, ask for new
	pop	di				;-6 di <- start of buffer

	;
	; Free any leftover, unused monikers
	;
	pop	bx				;-2 obj block handle
	call	MemDerefDS			; restore Obj block
	pop	bx				;-1 restore old stack pointer

freeUnused:
	cmp	di, bx
	jae	allGone
	mov	ax, ss:[di].II_visMoniker
	tst	ax
	jz	nextMoniker
	call	LMemFree
nextMoniker:
	add	di, size ItemInfo
	jmp	freeUnused	
allGone:
	mov	sp, bx				;-0 nuke buffer

	;Commented back in.  Sigh. 6/22/93 cbh
	mov	cx, leaveAlone
	push	bp
	mov	ax, MSG_GEN_ITEM_GROUP_REDRAW_ITEMS
	call	DC_ObjCallInstanceNoLock		
	pop	bp
exit:
	.leave
	ret
GenDynamicListScroll	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	ForwardGetMkrs

SYNOPSIS:	Stores and nukes monikers as needed for forward scrolling.

CALLED BY:	FAR

PASS:		ss:ax -- ItemInfo: next place to store moniker handle
		cx -- generic position of item
		ss:bp -- local vars:
			numVisItems -- number of items visible
			offset -- (newTopItem - oldTopItem)

RETURN:		cx, incremented

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/17/92		Initial version

------------------------------------------------------------------------------@

ForwardGetMkrs	proc	far
	numVisItems	local	word
	scrollOffset		local 	word
	leaveAlone	local	word
	moveIdentifierFlag	local	word
	.enter	inherit

	cmp	cx, leaveAlone
	jb	exit				;ignoring these

	mov	bx, scrollOffset
	add	bx, leaveAlone
	cmp	cx, bx
	jae	getMoniker			
	;
	; Items at the top are being scrolled off.  We'll nuke their monikers.
	;
	call	NukeExistingMoniker	
	jmp	short exit

getMoniker:
	;
	; For most items, we'll grab their moniker chunk to be moved elsewhere.
	; We'll also grab the enabled state of the item.
	;
	call	GetItemInfo			;get item info
exit:
	inc	cx				;bump position
	clc
	.leave
	ret
ForwardGetMkrs	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetItemInfo

SYNOPSIS:	Gets item moniker and enabled state.  Clears item's reference
		to the moniker, since it will be used somewhere else and we
		don't want it to be nuked.

CALLED BY:	ForwardGetMkrs, BackwardGetMkrs

PASS:		*ds:si -- item
		ss:ax  -- ItemInfo: buffer element to store stuff in	

RETURN:		ax -- updated to point at next element

DESTROYED:	di, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/17/92		Initial version

------------------------------------------------------------------------------@

GetItemInfo	proc	near
	class	GenClass
	mov	di, ax				
	segmov	es, ss				;ItemInfo buffer in es:di
	mov	bx, ds:[si]			
	add	bx, ds:[bx].Gen_offset
	clr	ax
	xchg	ax, ds:[bx].GI_visMoniker	
	stosw					;store vis moniker in buffer
	mov	al, ds:[bx].GI_states
	and	al, mask GS_ENABLED		;keep enabled flag
	stosb					;store it
	mov	ax, di				;update buffer pointer
	ret
GetItemInfo	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ForwardSetMkrs

SYNOPSIS:	Stores and queries for monikers as needed for forward scrolling.

CALLED BY:	FAR

PASS:		ss:ax -- ItemInfo: next place to get moniker from
		cx -- generic position of item
		dx -- identifier of item
		ss:bp -- local vars:
			numVisItems -- number of items visible
			scrollOffset -- (newTopItem - oldTopItem)

RETURN:		cx, dx, ax -- updated as needed

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/17/92		Initial version

------------------------------------------------------------------------------@

ForwardSetMkrs	proc	far
	numVisItems	local	word
	scrollOffset		local 	word
	leaveAlone	local	word
	moveIdentifierFlag	local	word
	.enter	inherit

	cmp	cx, leaveAlone
	jb	exit				;ignoring these

	mov	bx, numVisItems	
	sub	bx, scrollOffset
	cmp	cx, bx				;pos < numVisItems-scrollOffset
	jge	queryForMoniker			;  
	;
	; For most of the items, we can just grab a moniker from our buffer.
	;
	call	StoreItemInfo			;store moniker, enabled flag
	jmp	short exit

queryForMoniker:
	;
	; For the items being scrolled on, we'll have to query for the
	; monikers.
	;
	call	ValidateItem			;validate the thing
exit:
	inc	cx				;bump position
	inc	dx				;bump identifier
	clc
	.leave
	ret
ForwardSetMkrs	endp







COMMENT @----------------------------------------------------------------------

ROUTINE:	BackwardGetMkrs

SYNOPSIS:	Stores and nukes monikers as needed for backward scrolling.

CALLED BY:	FAR

PASS:		ss:ax -- ItemInfo: next place to store moniker handle
		cx -- generic position of item
		ss:bp -- local vars:
			numVisItems -- number of items visible
			scrollOffset -- (newTopItem - oldTopItem)

RETURN:		cx, incremented

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/17/92		Initial version

------------------------------------------------------------------------------@

BackwardGetMkrs	proc	far
	numVisItems	local	word
	scrollOffset		local 	word
	leaveAlone	local	word
	moveIdentifierFlag	local	word
	.enter	inherit

	cmp	cx, leaveAlone
	jb	exit				;ignoring these

	mov	bx, numVisItems
	add	bx, scrollOffset
	cmp	cx, bx				;pos >= numVisItems+scrollOffset
	jge	nukeMoniker			
	;
	; The first bunch of items are moving down.  We'll grab their monikers.
	;
	call	GetItemInfo			;get item info
	jmp	short exit

nukeMoniker:
	;
	; There are items at the bottom that are moving offscreen.  Nuke their
	; monikers.
	;
	call	NukeExistingMoniker	
exit:
	inc	cx				;bump position
	clc					;continue
	.leave
	ret
BackwardGetMkrs	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	BackwardSetMkrs

SYNOPSIS:	Stores and queries for monikers as needed for backward 
		scrolling.

CALLED BY:	FAR

PASS:		ss:ax -- ItemInfo: next place to get moniker from
		cx -- generic position of item
		dx -- identifier of item
		ss:bp -- local vars:
			numVisItems -- number of items visible
			scrollOffset -- (newTopItem - oldTopItem)

RETURN:		cx, dx, ax -- updated as needed

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/17/92		Initial version

------------------------------------------------------------------------------@

BackwardSetMkrs	proc	far
	numVisItems	local	word
	scrollOffset		local 	word
	leaveAlone	local	word
	moveIdentifierFlag	local	word
	.enter	inherit

	mov	bx, leaveAlone
	cmp	cx, bx
	jb	exit				;ignoring these

	sub	bx, scrollOffset
	cmp	cx, bx				;branch if pos >= - scrollOffset
	jae	storeMoniker			
	;
	; For the first few items, we'll be querying for a new moniker.
	;
	call	ValidateItem			;validate the thing
	jmp	short exit

storeMoniker:
	;
	; For the rest of the items, we'll store a moniker from our buffer.
	;
	call	StoreItemInfo			;store moniker, enabled flag
exit:
	inc	cx				;bump position
	inc	dx				;bump identifier
	clc
	.leave
	ret
BackwardSetMkrs	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	StoreItemInfo

SYNOPSIS:	Stores item moniker and enabled state.

CALLED BY:	ForwardSetMkrs, BackwardSetMkrs

PASS:		*ds:si -- item
		ss:ax  -- ItemInfo: buffer element to store from 
		dx     -- identifier

RETURN:		ax -- updated to point at next element

DESTROYED:	di, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/17/92		Initial version

------------------------------------------------------------------------------@

StoreItemInfo	proc	near
	numVisItems		local	word
	scrollOffset		local 	word
	leaveAlone		local	word
	moveIdentifierFlag	local	word
	.enter	inherit

	class	GenClass

	call	ItemEnsuredUsable
	jnc	justSetIdentifier

	;
	; Store the vis moniker.
	;
	push	di				;save item group handle
	mov	di, ax				;ss:di <- ItemInfo
	mov	bx, ss:[di].II_visMoniker	;get vis moniker
	clr	ss:[di].II_visMoniker		; mark ItemInfo as used
	mov	di, bx
	mov	bx, ds:[si]			
	add	bx, ds:[bx].Gen_offset
	mov	ds:[bx].GI_visMoniker, di	;store it
	tst	di				;see if there was a moniker
	pop	di				;*es:di <- item group

	;
	; If there was some kind of moniker (i.e. we weren't just copying from
	; an item that is still awaiting a moniker from the application), we'll
	; set it interactable.n
	;
	jz	noMonikerToStore		;there was no moniker, branch

	push	cx, dx, bp, ax
	mov	cx, si					;cx != 0 
	mov	ax, MSG_GEN_ITEM_SET_INTERACTABLE_STATE
	call	DC_ObjCallInstanceNoLock
	pop	cx, dx, bp, ax
	jmp	short setIdentifier

noMonikerToStore:
	;
	; There's no moniker to store.  If we're not moving identifiers, what
	; we really need to do is query for this moniker, as the moniker
	; queried for from the source of the scroll is not not valid for this
	; new object.
	;
	tst	moveIdentifierFlag		;moving identifiers, branch
	jnz	setIdentifier
	push	cx, dx, bp
	call	ValidateItem			;query for new moniker
	jmp	short 5$			;and branch to copy enabled 

setIdentifier:
	;
	; Set the identifier for the item.
	;
	push	cx, dx, bp
	tst	moveIdentifierFlag		;not moving identifiers, branch
	jz	5$
	mov	cx, dx
	push	ax
	mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
	call	DC_ObjCallInstanceNoLock
	pop	ax				;ss:ax <- ItemInfo
5$:
	;
	; Set enabled state properly.  We're going to set the instance data
	; directly, and expect that MSG_GEN_ITEM_REDRAW will deal with keeping
	; the specific enabled state correct.  (Otherwise we run into problems
	; with moving the focus when the item receives a MSG_SPEC_NOTIFY_SET_-
	; NOT_ENABLED message).
	;
	mov	bx, ds:[si]			
	add	bx, ds:[bx].Gen_offset
	or	ds:[bx].GI_states, mask GS_ENABLED
	mov	di, ax				;ss:di <- ItemInfo
	tst	ss:[di].II_state
	jnz	10$
	and	ds:[bx].GI_states, not mask GS_ENABLED
10$:
	;
	; Redraw the item to reflect its new moniker.
	;
;	mov	ax, MSG_GEN_ITEM_REDRAW		
;	call	GenCallSpecIfGrown
	pop	cx, dx, bp

;	mov	ax, di				;update buffer pointer
	add	ax, size ItemInfo		;bump it
exit:
	.leave
	ret

justSetIdentifier:
	;
	; even if we are not usable, we need to set the identifier (just like
	; ValidateItem)
	;
	; (should just move the SET_IDENTIFIER to the beginning of the routine)
	;
	tst	moveIdentifierFlag		;not moving identifiers, branch
	jz	exit
	push	ax, cx, dx, bp
	mov	cx, dx				; cx = identifier
	mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
	call	DC_ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
	jmp	short exit

StoreItemInfo	endp






COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListAddItems -- 
		MSG_GEN_DYNAMIC_LIST_ADD_ITEMS for GenDynamicListClass

DESCRIPTION:	Adds an items to the dynamic list.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
		cx	- item identifier to add after
		dx 	- number of items to add

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
	chris	3/16/92		Initial Version

------------------------------------------------------------------------------@

GenDynamicListAddItems	method dynamic	GenDynamicListClass,
				MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
	mov	bx, dx
	GOTO	FinishAddRemove

GenDynamicListAddItems	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListRemoveItems -- 
		MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS for GenDynamicListClass

DESCRIPTION:	Removes an item to the dynamic list.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
		cx	- item identifier to remove
		dx	- number of items to remove

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
	chris	3/16/92		Initial Version

------------------------------------------------------------------------------@

GenDynamicListRemoveItems	method dynamic	GenDynamicListClass,
				MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS

EC <	cmp	dx, ds:[di].GDLI_numItems				>
EC <	ERROR_A	UI_VALUE_REMOVING_MORE_ITEMS_THAN_EXIST			>

	mov	bx, dx
	neg	bx

FinishAddRemove	label	far

	;	
	; On adds, we'll limit cx to the last item + 1.
	; On removes, we'll limit cx to the last item - numItemsRemoving + 1.
	;
	;	cx -- position to add/remove from
	;	dx -- numItems to add or remove
	;	bx -- numItems for an add, -numItems for a remove
	;
	tst	bx				;removing?
	js	2$				;yes, branch
	clr	dx				;numItemsAdded dont affect limit
2$:
	neg	dx				;calculate limit
	add	dx,  ds:[di].GDLI_numItems

	cmp	cx, dx				;see if past limit
	jbe	5$				;everything fine, branch
	mov	cx, dx				;else limit cx
5$:
	;
	; Change the number of items.
	;
	add	ds:[di].GDLI_numItems, bx	;adjust number of items

	call	ObjMarkDirty

	call	AdjustSelectionsAsNeeded	;update current selection

	call	InitItemChanges			;ax <- top item
						;bp <- num visible items
						;bx <- numItemsAdding for add, 
						;   -numItemsRemoving for remove
						;cx <- place to add/remove

	; Make adjustments based on the new list height.
	;
	cmp	cx, ax				;item to remove above top item?
	jb	scrollThings			;yes, go handle
	mov	dx, ax				;top item in dx
	add	dx, bp				;get bottom item
	dec	dx
	cmp	cx, dx				;below bottom item?
	ja	exit				;no, nothing to do, exit
	
scrollThings:
	;
	; Scroll anything below the item being added/removed.
	;	ax -- top item
	;	cx -- item identifier we're adding/removing
	;	bx -- numItemsAdding for an add, -numItemsRemoving for a remove
		; 
	sub	cx, ax				;get number of items to ignore
	jae	10$
	clr	cx				;above top item, redraw all
10$:
	xchg	ax, cx				;ax <- items to ignore,
						;cx <- top item
	push	ax				;save items to ignore
	mov	dx, cx				;top item also in dx
	;
	; Scrolling "down" for a remove, "up" for an add.  We'll fudge a 
	; previous "top" to produce the correct scroll offset.
	;
	add	dx, bx				;create a previous top
						;  (scr offset = cx - dx)
	clr	di				;don't move identifiers!
	call	GenDynamicListScroll		;scroll items as needed

	;
	; Add this in, since things are not guaranteed to update, and
	; GenDynamicListScroll does not do this anymore.   6/ 2/93 cbh
	; (Changed to ignore items that aren't changing.  What I was thinking
	; when I did a "clr cx", I don't know.  6/21/93 cbh)
	;
	pop	cx				;don't redraw ignored items
;	clr	cx
	push	bp
	mov	ax, MSG_GEN_ITEM_GROUP_REDRAW_ITEMS
	call	DC_ObjCallInstanceNoLock		
	pop	bp

exit:						
	ret
GenDynamicListRemoveItems	endm



CallFirstGenChild	proc	near	;ax <- message, ds:di <- generic part
	class	GenClass
	call	DC_DerefGenDI
	mov	bx, ds:[di].GI_comp.CP_firstChild.chunk
	tst	bx
	jz	exit
	push	si
	mov	si, bx
	mov	bx, ds:[di].GI_comp.CP_firstChild.handle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
exit:
	ret
CallFirstGenChild	endp







COMMENT @----------------------------------------------------------------------

ROUTINE:	AdjustSelectionsAsNeeded

SYNOPSIS:	Updates selections after the items being added/removed.

CALLED BY:	GenDynamicListRemoveItems

PASS:		*ds:si -- dynamic list
		cx -- first item being added/removed
		bx -- shift amount

RETURN:		nothing

DESTROYED:	dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 7/92		Initial version

------------------------------------------------------------------------------@

AdjustSelectionsAsNeeded	proc	near	uses	ax, bx, cx, es
	class	GenDynamicListClass
	.enter
	call	DC_DerefGenDI
	mov	dx, ds:[di].GIGI_numSelections
	tst	dx
	jz	exit				;no selections, exit

	shl	dx, 1				;else double for words
	sub	sp, dx
	mov	bp, sp				;buffer in ss:bp
	push	dx				;save buffer size
	pushdw	dssi				;save our object

	push	cx				;save start of changes
	push	bp
	xchg	dx, bp
	shr	bp, 1				;pass num selections
	mov	cx, ss				;pass buffer in cx:dx, bp=size
	mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
	call	DC_ObjCallInstanceNoLock		;selections in cx:dx
	pop	bp				;now in ss:bp

	mov	cx, ax				;num selections in cx

	;
	; Get the number of items being removed.
	;
	clr	dx				;assume no items removed
	tst	bx				;removing items?
	jns	5$				;no, branch
	mov	dx, bx
	neg	dx				;dx <- number of items removed
5$:
	mov	di, ss
	mov	ds, di
	mov	si, bp				;source in ds:si
	mov	es, di
	mov	di, bp				;dest in es:di
	pop	bp				;first selection that changes
	push	di				;save pointer to first selection

checkItems:
	;
	; For each currently selected item:
	;	if (itemsRemoved) && (item in itemsBeingAddedOrRemoved)
	;		don't keep in new selection list
	;	else if item > itemsBeingAddedOrRemoved
	;		add bx to item and store in new selection list
	;	else
	;		store in new selection list
	;
	; ax -- temporary storage of current item
	; bx -- amount of change
	; dx -- number of items being removed, if any
	; bp -- first item being added/removed
	; cx -- last item being added/removed
	; ds:si -- source
	; es:di -- destination
	;
	push	cx				;save count
	mov	cx, bp				;have cx <- last item removed
	add	cx, dx

	lodsw					;get a selection

	;
	; If selected item being removed, we won't keep it as a selection.
	;
	tst	dx				;removing items?
	jz	10$				;no, branch
	cmp	ax, bp				;see if below items removed
	jb	10$				;yes, branch
	cmp	ax, cx				;<= last item removed?
	jb	doneWithItem			;yes, we won't keep this one
10$:
	;	
	; All selected items above the items being removed must adjust their 
	; positions.
	;
	cmp	ax, cx				;<= last item added/removed?
	jb	storeItem			;nope, store as is
	add	ax, bx				;else adjust the position

storeItem:
	stosw					;store selection as needed

doneWithItem:
	pop	cx				;restore count
	loop	checkItems			;do another item

	pop	dx				;restore pointer to selections
	mov	cx, ds				;cx:dx <- selections
	sub	di, dx				;di <- size of selection buffer
	mov	bp, di				;now in bp
	shr	bp, 1				;halve for item count

	popdw	dssi				;restore our object
	call	SetMultiSelection		;set selection, no update
	pop	dx				;restore buffer size
	add	sp, dx				;restore stack
exit:
	.leave
	ret
AdjustSelectionsAsNeeded	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	InitItemChanges

SYNOPSIS:	Does a bunch of stuff for item adding/removal, new num items.
		Rescrolls the dynamic list to make sure sufficient items
		are onscreen, and returns top item and num visible items.

CALLED BY:	GenDynamicListRemoveItems
		GenDynamicListSetNumItems

PASS:		*ds:si -- dynamic list

RETURN:		ax -- top item
		bp -- num visible items

DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 1/92		Initial version

------------------------------------------------------------------------------@

InitItemChanges	proc	near
	class	GenDynamicListClass

	push	cx, bx
	call	DC_DerefGenDI
	mov	cx, ds:[di].GDLI_numItems
	mov	ax, MSG_GEN_DYNAMIC_LIST_NUM_ITEMS_CHANGED
	call	GenCallSpecIfGrown		;not much point if not grown.
						;   5/17/93 cbh
	;
	; Get the identifier of the top item, and the number of entries (i.e.
	; the numVisibleItems)
	;
	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	call	CallFirstGenChild		;identifier in ax
	push	ax
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	DC_ObjCallInstanceNoLock		;num children in dx
	mov	bp, dx				;now in bp
	pop	ax				;ax <- top item
	pop	cx, bx				
						
	ret
InitItemChanges	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListSetNumItems -- 
		MSG_GEN_DYNAMIC_LIST_INITIALIZE for GenDynamicListClass

DESCRIPTION:	Sets a new number of items.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_DYNAMIC_LIST_INITIALIZE

		cx	- new number of items

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
	chris	4/ 1/92		Initial Version

------------------------------------------------------------------------------@

GenDynamicListInitialize	method dynamic	GenDynamicListClass,
				MSG_GEN_DYNAMIC_LIST_INITIALIZE
	;	
	; If we're not scrollable, we need to ensure that the new items will
	; be visible.
	;
	mov	dx, ds:[di].GDLI_numItems	;get old number of items
	mov	ax, HINT_ITEM_GROUP_SCROLLABLE
	call	ObjVarFindData
	jc	setNumItems
	push	cx, dx
	clr	bp				;no top item
	; 
	; Tell GenDynamicListNumVisibleItemsChanged not to call
	; ItemsChangedCallback for all of the items that it creates by
	; putting TRUE in dx, since we are going to do that.  IP 1/27/94
	;
	mov	dx, TRUE			
	mov	ax, MSG_GEN_DYNAMIC_LIST_NUM_VISIBLE_ITEMS_CHANGED
	call	DC_ObjCallInstanceNoLock
	pop	cx, dx

setNumItems:
	;
	; Use current number of items if passed GDLI_NO_CHANGE.
	;
	; cx -- new num items, dx -- old num items.
	;
	cmp	cx, GDLI_NO_CHANGE		;see if no change in num items
	jne	10$				;nope, branch
	mov	cx, dx				;else use GDLI_numItems
10$:
	mov	bx, offset GDLI_numItems	;set instance data
	call	GenSetWord

	call	InitItemChanges			;ax <- top item
						;bp <- num visible items

	mov	bp, ax				;keep identifier here
	clr	cx				;generic position of child
	mov	dx, cx				;all the items need to change
	mov	di, offset ItemsChangedCallback	;update routine
	call	DoAllChildren

	;
	; Set none selected.  We can modify the list without an update because
	; we can count on REDRAW_ITEMS updating everything as needed.
	; (I've removed the redraw, as it happens elsewhere now, so let's do it
	;  the old-fashioned way.  Somehow this worked before, but now with
	;  the drawing being done later, it wreaks havoc with the selected
	;  item never getting updated (i.e. marked unselected) in the specific
	;  UI.  -cbh 5/24/93)
	;
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	call	ObjCallInstanceNoLock

;	mov	dx, GIGS_NONE			;selection
;	clr	cx				;num selections
;	mov	bx, offset GIGI_selection
;	call	GenSetDWord			;set new selection

	;
	; Update all the items now.
	;
;	clr	cx				;redraw all the items
;	push	bp
;	mov	ax, MSG_GEN_ITEM_GROUP_REDRAW_ITEMS
;	call	DC_ObjCallInstanceNoLock		
;	pop	bp
;
	ret

GenDynamicListInitialize	endm

COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListGetNumItems -- 
		MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS for GenDynamicListClass

DESCRIPTION:	Returns number of items.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS

RETURN:		cx 	- number of items
		ax, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/17/92		Initial Version

------------------------------------------------------------------------------@

GenDynamicListGetNumItems	method dynamic	GenDynamicListClass,
				MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS

	mov	cx, ds:[di].GDLI_numItems
	Destroy	ax, dx, bp
	ret
GenDynamicListGetNumItems	endm


DynaCommon ends

ItemCommon segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListNumVisibleItemsChanged -- 
		MSG_GEN_DYNAMIC_LIST_NUM_VISIBLE_ITEMS_CHANGED for 
		GenDynamicListClass

DESCRIPTION:	Handles view size changing.  We may need to create GenItems
		here to display more entries.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_VIEW_SIZE_CHANGED
		cx	- num visible items
		dx 	- TRUE indicates do not initialze new items
		bp	- current top item

RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if dx is TRUE then any new items which are created, will not be
	initialized.  This is an optimization for
	GenDynamicListInitialize since it will initalize the new items
	anyway 

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/14/92		Initial Version

------------------------------------------------------------------------------@

GenDynamicListNumVisibleItemsChanged	method dynamic	GenDynamicListClass,
				MSG_GEN_DYNAMIC_LIST_NUM_VISIBLE_ITEMS_CHANGED

	;
	; This is for the benefit of non-scrolling dynamic lists.
	;
	mov	bx, dx				;bx init children flag
	cmp	cx, -1
	jne	10$
	mov	cx, ds:[di].GDLI_numItems
10$:
	push	cx, bp
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	IC_ObjCallInstanceNoLock	;previous num children in dx
	pop	cx, bp

	mov_tr	ax, bx				;ax gets init children flag
	mov	bx, cx				;save new numVisible in bx
	sub	cx, dx				;need to add items?
	je	exit				;nothing to be done, exit
	jb	removeItems			;fewer items, branch to remove

	push	ax
	push	dx, bp				;save prev num items, top item
addLoop:
	;
	; We need to add some items to the dynamic list.
	;	cx -- number of items to add
	;
	push	cx				;save count
	push	si
	mov	ax, MSG_GEN_DYNAMIC_LIST_GET_ITEM_CLASS
	call	IC_ObjCallInstanceNoLock	;returns item class in cx:dx
	mov	es, cx
	mov	di, dx
	mov	bx, ds:[LMBH_handle]
	call	GenInstantiateIgnoreDirty	;instantiate an item
	mov	bx, offset Gen_offset		;
	call	ObjInitializePart		;initialize generic part.
	mov	dx, si
	mov	cx, ds:[LMBH_handle]		;new item in ^lcx:dx
	pop	si				;parent in *ds:si
	mov	bp, CCO_LAST			;put last, don't mark dirty
	mov	ax, MSG_GEN_ADD_CHILD
	call	IC_ObjCallInstanceNoLock
	pop	cx				;restore count
	loop	addLoop

	;
	; Having added the items to the generic tree, we'll make sure the
	; items get monikers and stuff.
	;
	pop	dx, bp				;restore prevNumItems, top item

	;
	; test to see if whomever called this routine is going to
	; update the children.  If that is true, than lets not do it
	;
	pop	ax
EC<	cmp	ax, TRUE 						>
EC<	je	doneChecking						>
EC<	cmp	ax, FALSE						>
EC<	je	doneChecking						>
EC<	ERROR   GEN_DYNAMIC_LIST_NUM_VISIBLE_ITEMS_CHANGED_BAD_ARGUMENT	>
EC< doneChecking:							>

	cmp	ax, TRUE
	je	redraw

	clr	cx				;generic position of child
	mov	di, offset ItemsChangedCallback	;update routine
	call	DoAllChildren
	jmp	short redraw

removeItems:
	;
	; We have more items than we need currently.  We'll remove items, so
	; that the dynamic list can always get the current number of visible
	; items by counting the children.
	;	bx - newNumItems
	;
	clr	cx				;generic child position
	mov	dx, bx				;place to start removing items
	mov	di, offset RemoveItemsCallback	;remove items
	call	DoAllChildren
redraw:
;	clr	cx				;redraw all the items
;	mov	ax, MSG_GEN_ITEM_GROUP_REDRAW_ITEMS
;	call	IC_ObjCallInstanceNoLock		
exit:
	ret
GenDynamicListNumVisibleItemsChanged	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListScanItems -- 
		MSG_GEN_ITEM_GROUP_SCAN_ITEMS for GenDynamicListClass

DESCRIPTION:	Scans for items.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_SCAN_ITEMS

		cl	- GenScanItemsFlags
		dx	- initial item
		bp	- absolute scan amount 

RETURN:		carry set if any item found, with:
			ax 	- resultant item
			cl	- GenScanItemsFlags, possibly updated (in
				  particular, GSIF_FORWARD flag reflects the 
				  direction to navigate if the result item turns
				  out to be disabled)
		dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/19/92		Initial Version

------------------------------------------------------------------------------@

GenDynamicListScanItems	method dynamic	GenDynamicListClass,
				MSG_GEN_ITEM_GROUP_SCAN_ITEMS
	; If we're just supposed to look through the existing items, then
	; so be it.  Do the superclass method.
	;
	test	cl, mask GSIF_EXISTING_ITEMS_ONLY
	jz	doScan
	mov	di, offset GenDynamicListClass
	GOTO	ObjCallSuperNoLock

doScan:
	;
	; First, do normal item group scan.   In the simple cases, we will 
	; actually find what we want here.  If so, exit.
	;
	or	cl, mask GSIF_DYNAMIC_LIST	;say we're a dynamic list
	mov	di, offset GenDynamicListClass
	call	ObjCallSuperNoLock		;do superclass stuff
	jc	exit				;we found a result, exit

	;
	; Scan failed for currently usable items.  Get some more info (the
	; identifiers of the first and last usable children).
	;
	push	bp, dx				;save last, first enabled items

	push	ax				;save destination position
	mov	ax, -1				;initialize first usable item
	mov	bp, ax				;and last usable item
	mov	di, offset GetFirstLastItems	;find child at this position
	call	GenItemGroupProcessChildren
	pop	bx				;restore dest position

	call	IC_DerefGenDI
	mov	di, ds:[di].GDLI_numItems	
	dec	di				;di <- identifier of last item

	;
	; We're now ready to return something outside the currently usable
	; region.  Keep the value returned within reasonable range, and use
	; information returned from the original scan in certain situations.
	;
	; ax -- identifier of first usable item
	; bx -- result of failed scan relative to top item
	; cl -- GenScanItemsArgs
	; bp -- identifier of last usable item
	; di -- identifier of last item in dynamic list
	;

	;
	; From-start -- just go to do out-of-range stuff.  If you're looking
	; for the beginning, the superclass returns -1, so if you`re scrolled
	; into the list, it actually returns an onscreen value, which is 	
	; totally wrong.  This may be a problem with the algorithm, but for
	; now I'll do this.  -cbh 9/23/92
	;
	test	cl, mask GSIF_FROM_START
	jnz	outOfDynamicRange		

	add	bx, ax				;adjust position to be a dynamic
						;  list position.
	js 	outOfDynamicRange		;out of range, branch
	cmp	bx, di				
	jbe	inDynamicRange				

outOfDynamicRange:
	;	
	; Not in range, limit to first or last item in list based on whether
	; we're going forward, whether we're wrapping, etc.  The other thing
	; we'll do here is toggle the GSIF_FORWARD flag if we're at the ends
	; in a non-wrapping, non-from-start situation.  The caller of this 
	; message will use the direction flag to decide which direction to go
	; if the item we're returning turns out to be disabled, and if we're
	; going to the end of the list and the item is disabled, we'll want to
	; reverse our direction (and vice-versa for going to the beginning).
	;
	mov	dx, di				;dx <- numItems - 1
	clr	bx				;assume moving to start position
	test	cl, mask GSIF_FORWARD		;going forward?
	jz	20$				;no, branch
	xchg	bx, dx				;else bx <- end position
20$:
	test	cl, mask GSIF_FROM_START or mask GSIF_WRAP_AROUND
	jz	inDynamicRange			;no, we're done
	xchg	bx, dx				;else switch to opposite pos

inDynamicRange:
	;
	; Within dynamic list's range, we'll see if the result end item was
	; actually onscreen.  If it was, we'll use the values returned from
	; the superclass since the superclass had information about whether
	; the desired item was disabled or not.  We also may need to return
	; a different direction based on various flags (see comment in Swap-
	; DirectionsIfNotWrapping).
	;
	pop	dx				;restore first enabled item
	tst	bx				;see if at beginning
	jnz	checkEnd			;no, branch
	call	SwapDirectionsIfNotWrapping	;may need this if item is dis'd
	add	sp, 2				;unload last enabled item

	tst	ax				;are we currently at the top?
	jnz	returnBx			;no, use this value
	mov	bx, dx				;else use better value 
	jmp	short returnBx			;and we're done

checkEnd:
	pop	dx				;restore last enabled item
	cmp	bx, di				;returning last item?
	jne	returnBx			;no, done
	call	SwapDirectionsIfNotWrapping	;may need this if item is dis'd
	cmp	bp, di				;was last item onscreen?
	jne	returnBx			;no, done
	mov	bx, dx				;else use a better value

returnBx:
	push	bx, cx				;save final result, flags
	mov	cx, bx
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	call	GenCallSpecIfGrown		;make sure onscreen
	pop	ax, cx				;ax <- final result, cl <- flags
	stc					;return carry set
exit:
	Destroy	dx, bp
	ret
GenDynamicListScanItems	endm


SwapDirectionsIfNotWrapping	proc	near
	;
	; Called if we're going to return the beginning or end of the list, but
	; don't actually know its enabled state yet.  If it does turn out to
	; be disabled, we'll have to navigate one direction or the other to
	; find a new item.  This routine ensures that the direction is reversed
	; if we're not going to be wrapping or going from the start (i.e. if
	; paging to the beginning of the list, and the item is disabled, we'll
	; change direction to find the first non-disabled item in the list, 
	; rather than wrap.)
	;
	; Pass, return:  cl -- GenItemsScanFlags
	;
	test	cl, mask GSIF_FROM_START or mask GSIF_WRAP_AROUND
	jnz	30$
	xor	cl, mask GSIF_FORWARD		
30$:
	ret
SwapDirectionsIfNotWrapping	endp

ItemCommon	ends

DynaCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListReplaceItemMonikerOptr -- 
		MSG_GEN_ITEM_LIST_REPLACE_ITEM_MONIKER_OPTR for GenClass

DESCRIPTION:	Replace item's current vis moniker with VisMoniker referenced
		by optr.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
		
		^lcx:dx	- source VisMoniker
		bp	- item

RETURN:		ax - chunk handle of vis moniker
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
GenDynamicListReplaceItemMonikerOptr	method	dynamic	GenDynamicListClass,
				MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
	mov	ax, bp				; al = VisUpdateMode
	sub	sp, size ReplaceItemMonikerFrame
	mov	bp, sp
	mov	ss:[bp].RIMF_item, ax
	mov	ss:[bp].RIMF_itemFlags, 0
	mov	ss:[bp].RIMF_source.handle, cx
	mov	ss:[bp].RIMF_source.chunk, dx
	mov	ss:[bp].RIMF_sourceType, VMST_OPTR
	mov	ss:[bp].RIMF_dataType, VMDT_VIS_MONIKER
	mov	dx, ReplaceItemMonikerFrame
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	call	DC_ObjCallInstanceNoLock
	add	sp, size ReplaceItemMonikerFrame
	ret
GenDynamicListReplaceItemMonikerOptr	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListReplaceItemMonikerNullTermTextFPtr -- 
		MSG_GEN_ITEM_LIST_REPLACE_ITEM_TEXT for GenDynamicListClass

DESCRIPTION:	Replace item's current vis moniker with null-terminated text.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		
		cx:dx	- fptr to zero-terminated text
		(For XIP'ed geodes, cx:dx *cannot* be pointing into the
			XIP movable code segment.)
		bp	- item

RETURN:		ax - chunk handle of vis moniker
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
GenDynamicListReplaceItemText 	method	dynamic	GenDynamicListClass,
		MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr (cx:dx) passed in is not pointing into the code
	; segment of the routine/method which sent out this message
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	ax, bp				; bp = item
	sub	sp, size ReplaceItemMonikerFrame
	mov	bp, sp
	mov	ss:[bp].RIMF_itemFlags, 0
	mov	ss:[bp].RIMF_item, ax
	mov	ss:[bp].RIMF_source.handle, cx
	mov	ss:[bp].RIMF_source.chunk, dx
	mov	ss:[bp].RIMF_sourceType, VMST_FPTR
	mov	ss:[bp].RIMF_dataType, VMDT_TEXT
	mov	ss:[bp].RIMF_length, 0
	mov	dx, ReplaceItemMonikerFrame
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	call	DC_ObjCallInstanceNoLock
	add	sp, size ReplaceItemMonikerFrame
	ret
GenDynamicListReplaceItemText	endm






COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListRemoveItemList -- 
		MSG_GEN_DYNAMIC_LIST_REMOVE_ITEM_LIST for GenDynamicListClass

DESCRIPTION:	Removes a list of items.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_DYNAMIC_LIST_REMOVE_ITEM_LIST

		cx:dx	- list of items
		(For XIP'ed geodes, cx:dx *cannot* be pointing into the
			movable XIP cdoe segment.)
		bp	- number of items

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
	chris	5/11/92		Initial Version

------------------------------------------------------------------------------@

GenDynamicListRemoveItemList	method dynamic	GenDynamicListClass, \
				MSG_GEN_DYNAMIC_LIST_REMOVE_ITEM_LIST
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is not pointing into the code segment
	; of the one who sent out this message
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	tst	bp
	jz	exit				;nothing to do, get out
	mov	di, dx
	mov	es, cx				;es:di <- list
	mov	bx, bp				;bx <- count

removeItem:
	;
	; Remove an item.  es:di -- item, bx --	number of items left to do
	;	
	mov	cx, {word} es:[di]
	push	cx
	mov	dx, 1
	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
	call	DC_ObjCallInstanceNoLock
	pop	cx	
	add	di, 2				;next item
	dec	bx
	jz	exit				;no more items left, exit

	;
	; Having removed the item, update any subsequent items in the list
	; whose identifiers would be affected by the removal of the last item.
	;
	push	bx, di				;save current position in list

updateItem:
	cmp	{word} es:[di], cx
EC <	ERROR_E	GEN_DYNAMIC_LIST_SAME_ITEM_TWICE_IN_REMOVAL_LIST	>
	jb	10$				;not after deleted item, branch
	dec	{word} es:[di]			;else update the identifier
10$:
	add	di, 2				;next item
	dec	bx
	jnz	updateItem			;not done, loop
	pop	bx, di				;restore current list position
	jmp	short removeItem		;go remove another one.	
exit:
	ret
GenDynamicListRemoveItemList	endm


DynaCommon ends


ItemExtended	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenDynamicListUpdateExtendedSelection -- 
		MSG_GEN_ITEM_GROUP_UPDATE_EXTENDED_SELECTION for 
		GenDynamicListClass

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

GenDynamicListUpdateExtendedSelection	method dynamic	GenDynamicListClass, \
				MSG_GEN_ITEM_GROUP_UPDATE_EXTENDED_SELECTION

	call	SetupChangeItemArgs		;get item range to change
	jnc	exit				;no change, get out.
	call	GenDynamicListChangeItems
exit:
	ret
GenDynamicListUpdateExtendedSelection	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	GenDynamicListChangeItems

SYNOPSIS:	Changes the items passed in the appropriate way.  In normal
		selections, the changed items that are in the new selection
		are cleared, others are set.  When xoring selections, all 
		items are xor'ed.

CALLED BY:	?

PASS:		*ds:si -- item group
		cx     -- position of first item being changed
		dx     -- position of last item being changed 
		ax     -- anchor item
		ss:bp  -- GenItemGroupUpdateExtendedSelection

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/10/92		Initial version

------------------------------------------------------------------------------@

GenDynamicListChangeItems	proc	near
	class	GenDynamicListClass
	;
	; We'll use bx as our current item, running through all the changed
	; items.
	;
	clr	bx				;init running item
itemLoop:	
	push	ax, bx, cx, dx, bp
	;
	; Figure out whether this item is changing from last time.  (On
	; an initial selection, nothing is changing from last time, or so
	; we must treat it, as far as whether to clear an item no longer in
	; the selection.)
	;
	clr	di				;assume not changing
	test	ss:[bp].GIGUESP_flags, mask ESF_INITIAL_SELECTION
	jnz	notChanged			;initial selection, no changes
	cmp	bx, cx
	jb	notChanged			
	cmp	bx, dx
	ja	notChanged				
	dec	di				;changing

notChanged:
	mov	dx, di				;pass changed flag in dx
	mov	cx, bx
	call	ChangeItem			;change an item

	pop	ax, bx, cx, dx, bp
	inc	bx
	call	IE_DerefGenDI
	cmp	bx, ds:[di].GDLI_numItems	;are we done?
	jb	itemLoop			;nope, move along
	ret
GenDynamicListChangeItems	endp



ItemExtended	ends
