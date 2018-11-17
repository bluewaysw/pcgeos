COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/User
FILE:		userListUtils.asm

AUTHOR:		Gene Anderson, Feb 15, 1990

ROUTINES:
	Name			Description
	----			-----------
	UserFontCreateList	Query the system and create a list of fonts.
	UserCreateListEntry	Make a list entry out of a string.
	UserAddEntryToList	Add a list entry to the list.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/15/90		Initial revision

DESCRIPTION:
	Routines to query the system and build out a list of fonts.
	This is designed to be used by applications to dynamically
	build a font menu or list, so they don't have to hardwire a
	list in.

	The routines UserCreateListEntry and UserAddEntryToList are designed
	to be generic. UserCreateListEntry just takes a NULL-terminated string
	and makes a GenListEntry. UserAddEntryToList just takes the chunk of
	parent list, the chunk of the list entry and the value for
	the entry to pass to the routine for the list.

	This would (theoretically) allow you to dynamically create
	a list of any strings and data each should return. This is
	different than dynamic lists, which is designed for large
	lists that can change.

	$Id: userListUtils.asm,v 1.1 97/04/07 11:45:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ListUtils segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserCreateItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a GenItem for a given string.
CALLED BY:	UserFontCreateList

PASS:		es:di - ptr to font string (NULL terminated)
		(es:di *cannot* be pointing in the movable XIP code segment.)
		*ds:si - parent
		bx - block of parent
		ds - pointing to a "fixupable" block
		dx - mask OCF_IGNORE_DIRTY if created entry should be marked
		     ignore dirty, 0 if not
RETURN:		dx - lmem handle of new list entry
		ds - updated to point at segment of same block as on entry
DESTROYED:	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/15/90		Initial version
	cbh	4/ 9/92		GenItem version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserCreateItem	proc	far
	uses	ax, cx, si, di, bp, es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; Instantiate a new list item
	;
	push	di, es
	mov	ax, segment GenItemClass
	mov	es, ax
	mov	di, offset GenItemClass		;ds:si <- ptr to object
	
	push	dx				;save IGNORE_DIRTY flag
	call	ObjInstantiate			;si == handle of list item
	pop	dx

	;
	; Mark the sucker as ignore-dirty, if requested
	;
	test	dx, mask OCF_IGNORE_DIRTY
	jz	noDirty
	push	bx
	mov	ax, si
	mov	bx, mask OCF_IGNORE_DIRTY
	call	ObjSetFlags
	pop	bx
noDirty:

	; *ds:si = child

	pop	di, es
	;
	; Set the moniker to the string that was passed:
	; Set up the CopyVisMonikerFrame and create a moniker chunk that
	; replaces any moniker (none) in the list entry and marks the new
	; moniker chunk as ignoreDirty.
	;
	push	si
	push	dx				;save object dirty flag
	mov	cx, es
	mov	dx, di				;string in es:di
	mov	bp, VUM_MANUAL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;create a moniker chunk (AX)

	pop	dx				;restore object dirty flag
	test	dx, mask OCF_IGNORE_DIRTY	;if object is ignore-dirty,
	jz	10$				; moniker s/b too
	push	bx
	mov	bx, mask OCF_IGNORE_DIRTY or (mask OCF_DIRTY shl 8)
	call	ObjSetFlags			; set ignore-dirty flag for
						;	chunk, clear dirty
	pop	bx
10$:

	pop	dx				;dx <- lmem handle of item
	.leave
	ret
UserCreateItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserAddItemToGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a font GenItem to the list, set it usable and
		set its action/data.
CALLED BY:	FontListCreate

PASS:		*ds:si - parent
		bx - handle of parent block
		dx - chunk of font entry (ie. ^lGenListEntry)
		cx - action/data for entry (FontID)
RETURN:		ds - updated to point at segment of same block as on entry
DESTROYED:	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/15/90		Initial version
	cbh	4/ 9/92		GenItem version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserAddItemToGroup	proc	far	uses	ax, bx, cx, dx, bp, di, si
	class	GenItemClass

	.enter

	push	cx

	; Add the list item to the list of fonts

	mov	cx, bx

	mov	ax, offset GI_link
	mov	bx, Gen_offset
	mov	di, GI_comp
	mov	bp, CCO_LAST or mask CCF_MARK_DIRTY;bp <- flags (CompChildFlags)
	call	ObjCompAddChild

	; set action

	mov	si, dx
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	pop	ds:[di].GII_identifier

	; set usable

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	.leave
	ret
UserAddItemToGroup	endp

ListUtils ends
