COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Item (Sample PC GEOS application)
FILE:		user.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/1/92		Initial version

DESCRIPTION:
	This file source code for the Item application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: user.asm,v 1.1 97/04/04 16:34:31 newdeal Exp $

------------------------------------------------------------------------------@

ItemCommonCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemListItemSelected -- MSG_ITEM_LIST_ITEM_SELECTED handler

DESCRIPTION:	The GenDynamicList object sends this message, when the
		user selects (or unselects) an item in the list.

PASS:		ds	= dgroup
		cx	= index for selected item in list (0-N)

RETURN:		ds	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		initial version

------------------------------------------------------------------------------@

ItemListItemSelected	method	ItemGenProcessClass, MSG_ITEM_LIST_ITEM_SELECTED

	;was an item selected?

	tst	cx
	jns	getValue

	;an item was deselected: disable the GenValue

	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ItemCallGenValue
	jmp	done

getValue:
	;an item was selected: make sure the GenValue is enabled

	push	cx
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_ENABLED
	call	ItemCallGenValue
	pop	cx

	;get the current value for the item at this index (0-N)

	call	ItemGetValue			;returns ax = value

	mov	dx, ax				;dx = value

	;set the GenValue object to display this value

	mov	ax, MSG_GEN_VALUE_SET_VALUE
	clr	bp				;not indeterminate
	call	ItemCallGenValue

done:
	ret
ItemListItemSelected	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemListRequestItemMoniker -- MSG_ITEM_LIST_REQUEST_ITEM_MONIKER
			handler.

DESCRIPTION:	The GenDynamicList sends this message to our process object,
		for each list item that it needs a moniker for.

PASS:		ds	= dgroup
		^lcx:dx	= ItemGenDynamicList
		bp	= entry # of requested moniker 

RETURN:		ds	= same

DESTROYED:	es, plus others

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		initial version

------------------------------------------------------------------------------@

ItemListRequestItemMoniker	method	ItemGenProcessClass,
					MSG_ITEM_LIST_REQUEST_ITEM_MONIKER

passedBP	local	word \
		push	bp

buffer		local	10 dup (char) 	;buffer on stack to hold temporary
					;text string.
	.enter

	;call the list code to get the value for this

	push	bp			;save frame pointer
	push	cx, dx

	mov	cx, passedBP		;cx = item number, as passed into
					;routine using BP
	call	ItemGetValue		;returns ax = value

	;convert that value into an ascii string

	push	cx
	clr	dx			;dx:ax = value
	mov	cx, mask UHTAF_NULL_TERMINATE
	segmov	es, ss
	lea	di, buffer		;es:di = buffer on stack
	call	UtilHex32ToAscii
	pop	bp			;bp = list item #

	;send the moniker value to the list

	pop	bx, si			;set ^lbx:si = dynamic list object

	mov	cx, es			;cx:dx = ascii string, null term.
	mov	dx, di

	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	.leave
	ret
ItemListRequestItemMoniker	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemInsertItem -- MSG_ITEM_INSERT_ITEM

DESCRIPTION:	This message is sent by one of our GenTriggers, when the
		user clicks on it.

PASS:		ds	= dgroup

RETURN:		ds	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		initial version

------------------------------------------------------------------------------@

ItemInsertItem	method	ItemGenProcessClass, MSG_ITEM_INSERT_ITEM

	;first see if we have any items in the list

	mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
	call	ItemCallGenDynamicList	;returns cx = number of items

	clr 	ax
	tst	cx
	jz	insertHere		;skip if no items in list (cx=0)...

	;get the index of the currently selected item in the list

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ItemCallGenDynamicList	;returns ax = index
	jc	done			;abort if nothing selected...

	mov	cx, ax			;cx = location to insert

insertHere:
	;Insert a new item in the list, starting at location CX

EC <	push	cx							>
	
	call	ItemInsert

EC <	pop	ax							>
EC <	cmp	ax, cx							>
EC <	ERROR_NE ITEM_ERROR_CALL_TRASHED_REGISTER			>

	;now tell the dynamic list about the change

	mov	dx, 1			;insert 1 item

	mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
	call	ItemCallGenDynamicList

done:
	ret
ItemInsertItem	endm


ItemCallGenDynamicList	proc	near

	GetResourceHandleNS ItemGenDynamicList, bx
	mov	si, offset ItemGenDynamicList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;returns ax = index
	ret
ItemCallGenDynamicList	endp


ItemCallGenValue	proc	near
	GetResourceHandleNS	ItemGenValue, bx
	mov	si, offset ItemGenValue
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
ItemCallGenValue	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDeleteItem -- MSG_ITEM_DELETE_ITEM

DESCRIPTION:	This message is sent by one of our GenTriggers, when the
		user clicks on it.

PASS:		ds	= dgroup

RETURN:		ds	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		initial version

------------------------------------------------------------------------------@

ItemDeleteItem	method	ItemGenProcessClass, MSG_ITEM_DELETE_ITEM

	;get the index of the currently selected item in the list

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ItemCallGenDynamicList	;returns ax = index
	jc	done			;abort if nothing selected...

	;Delete this item

	mov	cx, ax			;cx = index for item to delete
EC <	push	cx							>

	call	ItemDelete

EC <	pop	ax							>
EC <	cmp	ax, cx							>
EC <	ERROR_NE ITEM_ERROR_CALL_TRASHED_REGISTER			>

	mov	dx, 1			;insert 1 item

	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
	call	ItemCallGenDynamicList

done:
	ret
ItemDeleteItem	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemSetItemValue -- MSG_ITEM_SET_ITEM_VALUE

DESCRIPTION:	This message is sent from the GenValue object when the
		user makes a change to the value in it.

PASS:		ds	= dgroup
		dx.cx	= signed <integer>.<fraction> current value
			  Thus, dl holds the new value (0-99)
		bp low	= GenValueStateFlags

RETURN:		ds	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		initial version

------------------------------------------------------------------------------@

ItemSetItemValue	method	ItemGenProcessClass, MSG_ITEM_SET_ITEM_VALUE

	;get the index of the currently selected item in the list

	push	dx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ItemCallGenDynamicList	;returns ax = index
	pop	cx
	jc	done			;abort if nothing selected...

	;Set the value for this item

	xchg	cx, ax			;cx = index for item
					;ax = new value
EC <	push	cx							>

	call	ItemSetValue

EC <	pop	ax							>
EC <	cmp	ax, cx							>
EC <	ERROR_NE ITEM_ERROR_CALL_TRASHED_REGISTER			>

	;now tell the Dynamic list about the new value for this item

	mov	bp, cx			;bp = index to item which changed
	GetResourceHandleNS ItemGenDynamicList, cx
	mov	dx, offset ItemGenDynamicList
	call	ItemListRequestItemMoniker

done:
	ret
ItemSetItemValue	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemRescanList -- MSG_ITEM_RESCAN_LIST

DESCRIPTION:	This message is sent by one of our GenTriggers, when the
		user clicks on it.

PASS:		ds	= dgroup

RETURN:		ds	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		initial version

------------------------------------------------------------------------------@

ItemRescanList	method	ItemGenProcessClass, MSG_ITEM_RESCAN_LIST

	mov	cx, GDLI_NO_CHANGE
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ItemCallGenDynamicList

	;and scroll back to the top of the list

	clr	cx
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	call	ItemCallGenDynamicList

	;an item was deselected: disable the GenValue

	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ItemCallGenValue

	ret
ItemRescanList	endm

ItemCommonCode	ends		;end of CommonCode resource
