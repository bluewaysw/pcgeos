COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Item (Sample PC GEOS application)
FILE:		list.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/1/92		Initial version

DESCRIPTION:
	This file source code for the Item application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: list.asm,v 1.1 97/04/04 16:34:28 newdeal Exp $

------------------------------------------------------------------------------@


;------------------------------------------------------------------------------
;			Structure Definitions
;------------------------------------------------------------------------------

	;######################################################################
ListNode	struc
	LN_value	word		; numeric data for the node
	LN_next		lptr.ListNode	; chunk handle of next ListNode
ListNode	ends
	;######################################################################

;------------------------------------------------------------------------------
;			Initialized Variables
;------------------------------------------------------------------------------

idata	segment

	;######################################################################
itemListHead	lptr.ListNode		; chunk handle of 1st item in list
	;######################################################################

idata	ends

;------------------------------------------------------------------------------
;				Code
;------------------------------------------------------------------------------

ItemCommonCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemInitializeList

DESCRIPTION:	Initialize our ItemList as follows:

			Create a global memory block
			Set up the LMemHeader structure at the beginning
				of that block.

			< ANYTHING ELSE THAT IS NECESSARY >

CALLED BY:	ItemGenProcessOpenApplication

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		Initial version

------------------------------------------------------------------------------@

INITIAL_LMEM_HEAP_FREE_SPACE		equ	10	;will be resized bigger
INITIAL_NUMBER_OF_CHUNK_HANDLES		equ	10	;should be plenty

ItemInitializeList	proc	near
	uses	ds			;OK to push and pop ds, because
					;dgroup segments are not movable
					;or swapable.
	.enter

	;######################################################################
	;FILL THIS IN

	;######################################################################

	.leave
	ret
ItemInitializeList	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDestroyList

DESCRIPTION:	Free the global memory block that contains our list.

CALLED BY:	ItemGenProcessCloseApplication

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		Initial version

------------------------------------------------------------------------------@

ItemDestroyList	proc	near
	.enter

	;get the handle for the LMem block on the heap, and free that block

	mov	bx, ds:[itemListBlock]

EC <	tst	bx							>
EC <	ERROR_Z ITEM_ERROR_BLOCK_ALREADY_DESTROYED			>

	call	MemFree

	clr	ds:[itemListBlock]

	.leave
	ret
ItemDestroyList	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemGetValue

DESCRIPTION:	Get the value for the specified item in the list.

PASS:		ds	= dgroup
		cx	= item # (0 means first item in the list)

RETURN:		ds, cx	= same
		ax	= value

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		initial version

------------------------------------------------------------------------------@

ItemGetValue	proc	near
	;######################################################################
	;FILL THIS IN

	mov	ax, cx				;this is just a place-holder.
						;You can nuke it.

	;######################################################################
	ret
ItemGetValue	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemSetValue

DESCRIPTION:	Set the value for the specified item in the list.

PASS:		ds	= dgroup
		cx	= item # (0 means first item in the list)
		ax	= new value

RETURN:		ds, cx	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		initial version

------------------------------------------------------------------------------@

ItemSetValue	proc	near
	;######################################################################
	;FILL THIS IN

	;######################################################################
	ret
ItemSetValue	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemInsert

DESCRIPTION:	Insert an item before the specified item in the list,
		and give it an initial value.

PASS:		ds	= dgroup
		cx	= item # (0 means first item in the list)
		ax	= initial value for item

RETURN:		ds, cx	= same

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		initial version

------------------------------------------------------------------------------@

ItemInsert	proc	near
	uses	cx, ds			;OK to push and pop ds, because
					;dgroup segments are not movable
					;or swapable.
	.enter

	;######################################################################
	;FILL THIS IN

	;######################################################################

	.leave
	ret
ItemInsert	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDelete

DESCRIPTION:	Delete the specified item in the list.

PASS:		ds	= dgroup
		cx	= item # (0 means first item in the list)

RETURN:		ds, cx	= same

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/92		initial version

------------------------------------------------------------------------------@

ItemDelete	proc	near
	;######################################################################
	;FILL THIS IN

	;######################################################################

	ret
ItemDelete	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemFindNode

DESCRIPTION:	Locates a specified node within the linked list

CALLED BY:	ItemInsert, ItemDelete, ItemGetValue, ItemSetValue

PASS:		es	= dgroup
		ds	= segment of the block containing the linked list
		cx	= item # (0 means first item in the list)

RETURN:		si	= chunk handle of the specified item/node

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	?	?/92		Initial version

------------------------------------------------------------------------------@

ItemFindNode	proc	near
	.enter

	;######################################################################
	;FILL THIS IN

	;######################################################################

	.leave
	ret
ItemFindNode	endp

ItemCommonCode	ends		;end of CommonCode resource
