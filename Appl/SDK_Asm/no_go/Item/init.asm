COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Item (Sample PC GEOS application)
FILE:		init.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/1/92		Initial version

DESCRIPTION:
	This file source code for the Item application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: init.asm,v 1.1 97/04/04 16:34:30 newdeal Exp $

------------------------------------------------------------------------------@

ItemCommonCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemGenProcessOpenApplication --
					MSG_GEN_PROCESS_OPEN_APPLICATION

SYNOPSIS:	This is the method handler for the method that is sent out
		when the application is started up or restarted from
		state. After calling our superclass, we do any initialization
		that is necessary.

CALLED BY:	

PASS:		AX	= Method
		CX	= AppAttachFlags
		DX	= Handle to AppLaunchBlock
		BP	= Block handle
		DS, ES	= DGroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/1/92		Initial version

------------------------------------------------------------------------------@
INITIAL_NUMBER_OF_ITEMS		equ	4

ItemGenProcessOpenApplication	method	ItemGenProcessClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION

	;Initialize our list (create an LMem heap for it.)

	call	ItemInitializeList

	;before any UI elements are visible on the screen, create our
	;linked list.

	mov	cx, INITIAL_NUMBER_OF_ITEMS
					;set the number of items to be created

10$:	;create an item

	push	cx			;save the counter

	mov	ax, cx			
	dec	ax			;correct the value to be stored
	clr	cx			;Always insert @ the head of the list
	call	ItemInsert

	pop	cx			;recover the counter
	loop	10$			;and insert next item, if appropriate

	;tell the list how many items it has initially

	mov	cx, INITIAL_NUMBER_OF_ITEMS

	GetResourceHandleNS ItemGenDynamicList, bx
	mov	si, offset ItemGenDynamicList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	;Now call our superclass

	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	mov	di, offset ItemGenProcessClass	; class of SuperClass we call
	call	ObjCallSuperNoLock		; method already in AX

	ret
ItemGenProcessOpenApplication	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemGenProcessCloseApplication --
					MSG_GEN_PROCESS_CLOSE_APPLICATION

SYNOPSIS:	This is the method handler for the method that is sent out
		when the application is exited.

CALLED BY:	

PASS:		AX	= Method
		DS, ES	= DGroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/1/92		Initial version

------------------------------------------------------------------------------@

ItemGenProcessCloseApplication	method	ItemGenProcessClass,
					MSG_GEN_PROCESS_CLOSE_APPLICATION

	;Destroy our list.

	call	ItemDestroyList

	;Now call our superclass

	mov	ax, MSG_GEN_PROCESS_CLOSE_APPLICATION
	mov	di, offset ItemGenProcessClass	; class of SuperClass we call
	call	ObjCallSuperNoLock		; method already in AX

	ret
ItemGenProcessCloseApplication	endm

ItemCommonCode	ends		;end of CommonCode resource
