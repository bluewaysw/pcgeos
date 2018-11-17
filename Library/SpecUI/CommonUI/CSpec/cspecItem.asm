COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec (common code for several specific ui's)
FILE:		cspecItem.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildItemList		Convert GenItemList to the OL equivalent
   GLB	OLBuildItemGroup	Convert GenItemGroup to the OL equivalent
   GLB	OLBuildDynamicList	Convert GenDynamicList to the OL equivalent
   GLB	OLBuildItem		Convert GenItem to the OL equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of various exclusive-type objects

	$Id: cspecItem.asm,v 1.1 97/04/07 10:51:10 newdeal Exp $

------------------------------------------------------------------------------@


Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildBooleanGroup

DESCRIPTION:	Return the specific UI class for a GenBooleanGroup

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data
	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx, dx, bp - ?

RETURN:
	cx:dx - class (cx = 0 for no conversion)

DESTROYED:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

------------------------------------------------------------------------------@


OLBuildBooleanGroup	proc	far

	;Always convert to OLItemGroupClass

	mov	dx, offset OLItemGroupClass

	segmov	es, cs				
	mov	di, offset cs:OLBuildBooleanGroupHints	
	mov	ax, length (cs:OLBuildBooleanGroupHints)
	call	ObjVarScanData

	mov	cx, segment OLItemGroupClass
	ret

OLBuildBooleanGroup	endp

OLBuildBooleanGroupHints	VarDataHandler \
	<HINT_BOOLEAN_GROUP_SCROLLABLE, \
			offset Build:OLBuildItemGroupHintScrollable>





COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildDynamicList

DESCRIPTION:	Return the specific UI class for a GenDynamicList

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data
	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx, dx, bp - ?

RETURN:
	cx:dx - class (cx = 0 for no conversion)

DESTROYED:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

------------------------------------------------------------------------------@


OLBuildDynamicList	proc	far

	FALL_THRU	OLBuildItemGroup

OLBuildDynamicList	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildItemGroup

DESCRIPTION:	Return the specific UI class for a GenItemGroup

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data
	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx, dx, bp - ?

RETURN:
	cx:dx - class (cx = 0 for no conversion)

DESTROYED:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

------------------------------------------------------------------------------@


OLBuildItemGroup	proc	far

	;Always convert to OLItemGroupClass

	mov	dx, offset OLItemGroupClass

	segmov	es, cs				
	mov	di, offset cs:OLBuildItemGroupHints	
	mov	ax, length (cs:OLBuildItemGroupHints)
	call	ObjVarScanData

	mov	cx, segment OLItemGroupClass
	ret

OLBuildItemGroup	endp

OLBuildItemGroupHints	VarDataHandler \
	<HINT_ITEM_GROUP_SCROLLABLE, \
			offset Build:OLBuildItemGroupHintScrollable>

OLBuildItemGroupHintScrollable	proc	far

	; If the item group is a selection box, we don't want
	; to make it an OLScrollListClass.
	;
if	SELECTION_BOX
	mov	ax, HINT_ITEM_GROUP_MINIMIZE_SIZE
	call	ObjVarFindData
	jc	exit
endif
	mov	dx, offset OLScrollListClass
exit::
	ret

OLBuildItemGroupHintScrollable	endp

			

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildBoolean

DESCRIPTION:	Return the specific UI class for a GenBoolean.

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data
	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx, dx, bp - ?

RETURN:
	cx:dx - class (cx = 0 for no conversion)

DESTROYED:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

------------------------------------------------------------------------------@


OLBuildBoolean	proc	far
	FALL_THRU	OLBuildItem

OLBuildBoolean	endp
			
			

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildItem

DESCRIPTION:	Return the specific UI class for a GenItem.

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data
	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx, dx, bp - ?

RETURN:
	cx:dx - class (cx = 0 for no conversion)

DESTROYED:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

------------------------------------------------------------------------------@


OLBuildItem	proc	far
	;
	; Call our parent to find out what class of object we should be.
	; If we ever re-do open look, we'll probably want to test OLIGS_
	; CHECKBOXES rather in addition to checking GIGBT_NON_EXCLUSIVE.
	;
	call	OLItemGetParentState		; Check the parent's state

	test	cl, mask OLIGS_SCROLLABLE	; Is the item group scrollable?
	mov	cx, offset OLItemClass		; Assume it's an item
	jz	10$				; Not scrollable, branch
	mov	cx, offset OLScrollableItemClass ;Else we're a scrollable item
	jmp	short exit
10$:
	cmp	dl, GIGBT_NON_EXCLUSIVE		; Supposed to be exclusive?
	jne	exit				; No, we're an OLItem
	mov	cx, offset OLCheckedItemClass	; Else we're checked
exit:
	mov	dx, cx
	mov	cx, segment CommonUIClassStructures
	ret

OLBuildItem	endp


Build ends
