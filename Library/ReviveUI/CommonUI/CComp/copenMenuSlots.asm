COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1994.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		specific UI
FILE:		copenMenuSlots.asm

AUTHOR:		Steve Yegge, Dec  9, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT PositionChildren        Manually position our children.

    INT PositionMenuChildrenCB  Get information about menu bar children.

    INT PositionChildrenHeuristically 
				Find a way to position children in groups.

    INT ShowCurGroup            Show the currently selected group of menu
				children (and hide all others).

    INT PositionSingleGroup     Fewer children than slots => position
				simply.

    INT PositionMultipleGroup   Position one of several child groups.

    INT SeeIfSpecialChild       Return TRUE if this has the passed hint

    INT PositionChildrenWithSlotHints 
				Position children that are requesting
				slots.

    INT ShowCurGroupWithSlotHints 
				Show the currently selected group of menu
				children (and hide all others).

    INT PositionSingleGroupWithSlotHints 
				Position 1-5 children in requested slots.

    INT PositionMultipleGroupWithSlotHints 
				Position 1-5 children in requested slots.

    INT GetSlotNumber           Find out what slot was requested.

    INT PositionChildrenOffscreen 
				Position all children offscreen.

    INT OffScreenCallback       Position the object offscreen.

    INT GetChildWithSlotHint    Find the child requesting the current slot,
				if any.

    INT SlotHintCallBack        See if this child has requested slot hint
				number.

    INT CountChildrenAndCalcGroups 
				Count children and get number of groups.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 9/94	Initial revision

DESCRIPTION:

	Code implementing HINT_SEEK_SLOT for menu bars; also
	implements having more menu-bar objects than can fit
  	onscreen (they're split into groups and a new trigger
	is created to cycle through the groups).

	$Id: copenMenuSlots.asm,v 1.8 95/06/08 18:27:35 brianc Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MenuBarCommon	segment	resource

jediPositionTable	word \
		SLOT_1_X_OFFSET,		; F1
		SLOT_2_X_OFFSET,		; F2
		SLOT_3_X_OFFSET,		; F3
		SLOT_4_X_OFFSET,		; F4
		SLOT_5_X_OFFSET			; F5


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Manually position our children.

CALLED BY:	OLMenuBarPositionBranch

PASS:		*ds:si = menu bar

RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

  PositionChildren:

	if ( /*first child has slot hint */ ) {
	  PositionChildrenWithSlotHints();
	} else {
	  PositionChildrenHeuristically();
	}

  PositionChildrenHeuristically:

	/* get current child count and exclude special kids */

	#children = MSG_VIS_COUNT_CHILDREN(OLMenuBar);
	#children = #children - NUM_SPECIAL_KIDS;	/* currently 3 */

	/* curCount is the menu bar's instance counter
	   that keeps track of how many children it thinks it has */

	if (curCount != #children) {
		/* this means we're either coming up for the
		   first time, or someone set one of our children
		   usable/not-usable.  */ 
	  curCount := #children;
	  curGroup := 0;
	}

	ShowCurGroup();

  ShowCurGroup:

	if #children <= 5 {
	  position children in slots 1-5;
	  position More trigger offscreen;
	}
	else {
	  for (i=0; i<4; i++) {
	    /* check if child i is out of bounds -> barf */
	    /* if not illegal, position in a slot */
	    put child (i + (4)*curGroup) in slot i;
	  }
	  put More trigger in slot 5
 	}

	/* position special children specially */

	app menu -> slot 6;

  PositionChildrenViaMoreTrigger:

	/* possible optimization: if curCount = #children,
	   skip recalculation of number of groups below */

	/* figure out whether to reset or increment curGroup:
	   first calc numGroups */

	#	numGroups	picture
	---------------------------------------------
	0-5 	1		*****	(0-4 in positions 1-5)
				M	(More trigger offscreen)

	6-8	2		****M
				****	(5-8 positioned offscreen)

	9-12	3		****M
				****	(5-8 offscreen)
				****	(9-12 offscreen)

	13-16	4		****M
				****	(5-8 offscreen)
				****	(9-12 offscreen)
				****	(13-16 offscreen)

	algorithm:

	  if (0 <= #children <=5) { numGroups = 1 } else
	  if (6 <= #children <= 8) { numGroups = 2 } else
	  numGroups = 3 + ((numChildren - 8) div 4);

	/* now reset or increment curGroup */

	if (curGroup >= numGroups-1) { curGroup = 0; }
	if (curGroup < numGroups-1)  { curGroup++; }

	/* finally, show the current group */

	ShowCurGroup();

  PositionChildrenWithSlotHints:

   /* Similar to PositionChildrenHeuristically except that:

	- #children = <highest slot number found>
	  (get that number by traversing children)
	- ShowCurGroup() is replaced by ShowCurGroupWithSlotHints() */

  ShowCurGroupWithSlotHints:

	if #children <= 5 {
	  position children in requested slots;
	  position More trigger offscreen;
	}
	else {
	  for (i=0; i<4; i++) {
	    /* find child with slot hint (i + (4)*curGroup) */
	    /* if found, position child in slot i */
	  }
	  put More trigger in slot 5
 	}

	/* position special children specially */

	app menu -> slot 6;


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	10/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionChildren	proc	near
		.enter
	;
	;  Get the child count (or highest slot number).
	;
		call	CountChildrenAndCalcGroups
	;
	;  If we found a slot hint, position children accordingly.
	;
		tst	ax
		jnz	slotHints

		call	PositionChildrenHeuristically
		jmp	done
slotHints:
		call	PositionChildrenWithSlotHints
done:		
		.leave
		ret
PositionChildren	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionMenuChildrenCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about menu bar children.

CALLED BY:	PositionChildren via ObjCompProcessChildren

PASS:		*ds:si	= child
		*es:di	= composite
		cx = child number

RETURN:		cx = total number of children counted so far
		ax = nonzero to indicate there are slot hints present
		dx = highest requested slot number (if any)
		carry set to end processing (never set)

DESTROYED:	everythin' else

PSEUDO CODE/STRATEGY:

	Check every child for a slot hint, since some specific
  	UIs might support having some children with and some without.
	Keep track of the child count along the way so we don't have
	to call VisCountChildren() later.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	10/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionMenuChildrenCB	proc	far
		.enter
if _JEDIMOTIF
	;
	;  JEDI: Check for special children, don't count 'em
	;
		push	ax
		mov	ax, TEMP_OL_BUTTON_MORE_TRIGGER
		call	ObjVarFindData
		pop	ax
		jc	exit
		push	ax
		mov	ax, TEMP_OL_BUTTON_APP_MENU_BUTTON
		call	ObjVarFindData
		pop	ax
		jc	exit
endif
	;
	;  Check the child for a slot hint.  If found, make ax
	;  nonzero and if the requested slot is the highest found
	;  so far make it the current highest.
	;
		mov_tr	bp, ax			; save ax (0 if none found yet)
		mov	ax, HINT_SEEK_SLOT
		call	ObjVarFindData		; ds:[bx] = extra data
		mov_tr	ax, bp			; restore boolean
		jnc	done			; not found; skip this child
	;
	;  This child has a slot hint.  If its hint number is lower
	;  than the current high, skip to the next child.
	;
		mov	ax, 1			; slot hints = TRUE
		cmp	dx, {word}ds:[bx]
		jae	done
	;
	;  Set the current slot number as the current high.
	;
		mov	dx, {word}ds:[bx]
done:
	;
	;  On the way out, increment our child counter.
	;
		inc	cx			; no effect on carry flag
exit:
		clc				; continue processing

		.leave
		ret
PositionMenuChildrenCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionChildrenHeuristically
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a way to position children in groups.

CALLED BY:	PositionChildren()

PASS:		*ds:si	= menu bar object
		dx	= number of children of the menu bar

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

  PositionChildrenHeuristically:

	/* get current child count and exclude special kids */

	#children = #children - NUM_SPECIAL_KIDS;	/* 3 for Jedi */

	/* curCount is the menu bar's instance counter
	   that keeps track of how many children it thinks it has */

	if (curCount != #children) {
		/* this means we're either coming up for the
		   first time, or someone set one of our children
		   usable/not-usable.  */ 
	  curCount := #children;
	  curGroup := 0;
	}

	ShowCurGroup();

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionChildrenHeuristically	proc	near
		uses	bp, cx
		.enter
	;
	;  If OLMBAR_curCount != numKids (cx), then we need to
	;  reset our instance data, because something has changed.
	;  (maybe we're coming up for the first time, or perhaps
	;  the user has set one of our children usable/not usable
	;  or added/removed a child from our list).
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		cmp	ds:[di].OLMBAR_curCount, dx
		je	showGroup

		mov	ds:[di].OLMBAR_curCount, dx
		clr	ds:[di].OLMBAR_curGroup
showGroup:
		call	ShowCurGroup

		.leave
		ret
PositionChildrenHeuristically	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowCurGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the currently selected group of menu children
		(and hide all others).

CALLED BY:	PositionChildrenHeuristically,
		PositionChildrenViaMoreTrigger

PASS:		*ds:si = menu bar object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

  ShowCurGroup:

	if OLMBAR_curCount <= 5 {
	  position children in slots 1-5;
	  position More trigger offscreen;
	}
	else {
	  for (i=0; i<4; i++) {
	    /* check if child i is out of bounds -> barf */
	    /* if not illegal, position in a slot */
	    put child (i + (4)*curGroup) in slot i;
	  }
	  put More trigger in slot 5
 	}

	/* position special children specially, if any */

	app menu -> slot 6;

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowCurGroup	proc	near
		uses	di
		.enter
	;
	;  If OLMBAR_curCount <= NUM_SLOTS, then there's no need
	;  to display the More trigger (put it offscreen).
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		cmp	ds:[di].OLMBAR_curCount, MENU_BAR_NUMBER_OF_SLOTS
		ja	multipleGroups
	;
	;  We only have one group.  Position children in slots 1-5.
	;
		call	PositionSingleGroup
		jmp	done
multipleGroups:
		call	PositionMultipleGroup
done:
		.leave
		ret
ShowCurGroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionSingleGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fewer children than slots => position simply.

CALLED BY:	ShowCurGroup

PASS:		*ds:si	= OLMenuBar object
		*ds:di	= OLMenuBarInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionSingleGroup	proc	near
		uses	ax,bx,cx,dx,si,di,bp

		parentObj	local	lptr	push	si
		child		local	optr
		counter		local	word

		.enter
	;
	;  Loop through the children, positioning them with the
	;  table.
	;
		clr	ss:counter
childLoop:
	;
	;  Get next child and save it.
	;
		mov	cx, ss:counter
		push	bp				; locals
		mov	si, ss:parentObj
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock		; ^lcx:dx = child
		pop	bp				; locals

		mov	ss:child.handle, cx
		mov	ss:child.chunk, dx
		jc	done				; no more children!
	;
	;  If this child is the proverbial "More" trigger, hide
	;  it offscreen.
	;
		mov	bx, cx				; ^lbx:dx = child
		mov	ax, TEMP_OL_BUTTON_MORE_TRIGGER
		call	SeeIfSpecialChild
		jnc	notMore

		mov	cx, OFFSCREEN_X_POSITION	; hide More trigger
		mov	dx, OFFSCREEN_Y_POSITION
		jmp	setPosition
notMore:
	;
	;  If it's the "App" menu, position it specially.
	;
		mov	ax, TEMP_OL_BUTTON_APP_MENU_BUTTON
		call	SeeIfSpecialChild
		jnc	notAppMenu

		mov	cx, APP_MENU_X_OFFSET
		mov	dx, MENU_BAR_BUTTON_Y_OFFSET
		jmp	adjustAndSet
notAppMenu:
	;
	;  Get the (x, y) position for the child, with respect
	;  to the parent's upper-left corner.
	;
		mov	bx, ss:counter
		shl	bx				; word-entry table
		mov	cx, cs:[jediPositionTable][bx]	; x-position
		mov	dx, MENU_BAR_BUTTON_Y_OFFSET	; y-position
adjustAndSet:
	;
	;  Adjust the child (x, y) position by adding parent's
	;  upper-left coordinates.
	;
		mov	si, ss:parentObj
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset		; re-dereference parent

		add	cx, ds:[di].VI_bounds.R_left
		add	dx, ds:[di].VI_bounds.R_top
setPosition:
	;
	;  Move the child.
	;
		push	bp				; locals
		mov	bx, ss:child.handle
		mov	si, ss:child.chunk		; ^lbx:si = child
		mov	ax, MSG_VIS_POSITION_BRANCH
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp				; locals
	;
	;  Set up to loop to next child.
	;
		inc	ss:counter
		jmp	childLoop
done:
		.leave
		ret
PositionSingleGroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionMultipleGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position one of several child groups.

CALLED BY:	ShowCurGroup()

PASS:		*ds:si	= OLMenuBar object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	position all children offscreen to make things easy, first.

	/* position the 1-4 children in this group */
	for (i=0; i<4; i++) {
	    /* check if child i is out of bounds -> barf */
	    /* if not illegal, position in a slot */
	  put child (i + (4)*curGroup) in slot i;
	}

	put More trigger in slot 5

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionMultipleGroup	proc	near
		uses	ax,bx,cx,dx,si,di,bp

		parentObj	local	lptr	push	si
		counter		local	word
		child		local	optr

		.enter
	;
	;  Position all the children offscreen for starters.
	;  (The callback will position the App menu and More
	;  trigger in the right places).
	;
		call	PositionChildrenOffscreen
	;
	;  Now position the 1-4 children from the current group.
	;
		clr	ss:counter		; i = 0
childLoop:
	;
	;  Calculate i + 4*curGroup.
	;
		mov	cx, ss:counter		; cx = i
		mov	si, ss:parentObj	; *ds:si = parent
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset	; ds:di = OLMenuBarInstance
		mov	dx, ds:[di].OLMBAR_curGroup
		shl	dx			; dx = curGroup * 2
		shl	dx			; dx = curGroup * 4
		add	cx, dx			; cx = child number to get
	;
	;  Get child(i+4*curGroup) to put in slot i.
	;
		push	bp			; locals
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock	; ^lcx:dx = child
		pop	bp			; locals
		jc	doneLoop
		movdw	ss:child, cxdx		; save it

if _JEDIMOTIF	;--------------------------------------------------------------
	;
	;  If it's the More trigger, we're out of children.
	;
		mov	ax, TEMP_OL_BUTTON_MORE_TRIGGER
		mov	bx, cx			; ^lbx:dx = child
		call	SeeIfSpecialChild
		jc	doneLoop
	;
	;  If it's the "App" menu, position it specially.
	;
		mov	ax, TEMP_OL_BUTTON_APP_MENU_BUTTON
		call	SeeIfSpecialChild
		jc	doneLoop

endif	; _JEDIMOTIF ----------------------------------------------------------

	;
	;  Get the child position from the table.
	;
		mov	bx, ss:[counter]
		shl	bx			; word-entry table
		mov	cx, cs:[jediPositionTable][bx]
		mov	dx, MENU_BAR_BUTTON_Y_OFFSET
	;
	;  Adjust position by adding menu bar upper-left corner.
	;
		add	cx, ds:[di].VI_bounds.R_left
		add	dx, ds:[di].VI_bounds.R_top
	;
	;  Set the position of the child.
	;
		push	bp			; locals
		movdw	bxsi, ss:child
		mov	ax, MSG_VIS_POSITION_BRANCH
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp			; locals
		
		inc	ss:counter		; next slot
		cmp	ss:counter, MENU_BAR_NUMBER_OF_SLOTS - 1
		jb	childLoop
doneLoop:
		.leave
		ret
PositionMultipleGroup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeeIfSpecialChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return TRUE if this has the passed hint

CALLED BY:	PositionSingleGroup, PositionMultipleGroup

PASS:		^lbx:dx = object to check

RETURN:		carry set if it's got the hint.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeeIfSpecialChild	proc	near
		uses	bx, si, ds
		.enter
	;
	;  Lock the thing down (probably not necessary, but...)
	;
		push	ax
		call	ObjLockObjBlock		; ax = segment
		mov	ds, ax			; *ds:si = child
		pop	ax
	;
	;  See if it's got the hint.
	;
		push	bx
		mov	si, dx
		call	ObjVarFindData
		pop	bx

		call	MemUnlock
		
		.leave
		ret
SeeIfSpecialChild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionChildrenWithSlotHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position children that are requesting slots.

CALLED BY:	PositionChildren()

PASS:		*ds:si	= menu bar object
		dx	= highest requested slot #

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

    Similar to PositionChildrenHeuristically except that:

	- curCount = <highest slot number found>
	  (get that number by traversing children)
	- ShowCurGroup() is replaced by ShowCurGroupWithSlotHints()

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionChildrenWithSlotHints	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  If OLMBAR_curCount != numKids (dx), then we need to
	;  reset our instance data, because something has changed.
	;  (maybe we're coming up for the first time, or perhaps
	;  the user has set one of our children usable/not usable
	;  or added/removed a child from our list).
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		cmp	ds:[di].OLMBAR_curCount, dx
		je	showGroup

		mov	ds:[di].OLMBAR_curCount, dx
		clr	ds:[di].OLMBAR_curGroup
showGroup:
		call	ShowCurGroupWithSlotHints

		.leave
		ret
PositionChildrenWithSlotHints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowCurGroupWithSlotHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the currently selected group of menu children
		(and hide all others).

CALLED BY:	PositionChildrenHeuristically,
		PositionChildrenViaMoreTrigger

PASS:		*ds:si = menu bar object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

  ShowCurGroupWithSlotHints:

	if #children <= 5 {
	  position children in requested slots;
	  position More trigger offscreen;
	}
	else {
	  for (i=0; i<4; i++) {
	    /* find child with slot hint (i + (4)*curGroup) */
	    /* if found, position child in slot i */
	  }
	  put More trigger in slot 5
 	}

	/* position special children specially */

	app menu -> slot 6;

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowCurGroupWithSlotHints	proc	near
		uses	di
		.enter
	;
	;  If OLMBAR_curCount <= NUM_SLOTS, then there's no need
	;  to display the More trigger (put it offscreen).
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		cmp	ds:[di].OLMBAR_curCount, MENU_BAR_NUMBER_OF_SLOTS
		ja	multipleGroups
	;
	;  We only have one group.  Position children in slots 1-5.
	;
		call	PositionSingleGroupWithSlotHints
		jmp	done
multipleGroups:
		call	PositionMultipleGroupWithSlotHints
done:
		.leave
		ret
ShowCurGroupWithSlotHints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionSingleGroupWithSlotHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position 1-5 children in requested slots.

CALLED BY:	ShowCurGroupWithSlotHints

PASS:		*ds:si	= OLMenuBar object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionSingleGroupWithSlotHints	proc	near
		uses	ax,bx,cx,dx,si,di,bp

		parentObj	local	lptr	push	si
		child		local	optr
		counter		local	word

		.enter
	;
	;  Loop through the children, positioning them using the
	;  slot hint as an index into a table.
	;
		clr	ss:counter
childLoop:
	;
	;  Get next child and save it.
	;
		mov	cx, ss:counter
		push	bp				; locals
		mov	si, ss:parentObj
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock		; ^lcx:dx = child
		pop	bp				; locals

		mov	ss:child.handle, cx
		mov	ss:child.chunk, dx
		jc	done				; no more children!

if _JEDIMOTIF	;---------------------------------------------------------------
	;
	;  If this child is the proverbial "More" trigger, hide
	;  it offscreen.
	;
		mov	bx, cx				; ^lbx:dx = child
		mov	ax, TEMP_OL_BUTTON_MORE_TRIGGER
		call	SeeIfSpecialChild
		jnc	notMore

		mov	cx, OFFSCREEN_X_POSITION	; hide More trigger
		mov	dx, OFFSCREEN_Y_POSITION
		jmp	setPosition
notMore:
	;
	;  If it's the "App" menu, position it specially.
	;
		mov	ax, TEMP_OL_BUTTON_APP_MENU_BUTTON
		call	SeeIfSpecialChild
		jnc	notAppMenu

		mov	cx, APP_MENU_X_OFFSET
		mov	dx, MENU_BAR_BUTTON_Y_OFFSET
		jmp	adjustAndSet
notAppMenu:
endif	; _JEDIMOTIF -----------------------------------------------------------

	;
	;  Get the (x, y) position for the child, with respect
	;  to the parent's upper-left corner.  Do this by
	;  retrieving the slot hint and using it to index
	;  into the position table.  (0-indexed)
	;
		movdw	bxsi, ss:child
		call	GetSlotNumber
		jnc	noPosition			; no slot number

		shl	bx				; word-entry table
		mov	cx, cs:[jediPositionTable][bx]	; x-position
		mov	dx, MENU_BAR_BUTTON_Y_OFFSET	; y-position
adjustAndSet:
	;
	;  Adjust the child (x, y) position by adding parent's
	;  upper-left coordinates.
	;
		mov	si, ss:parentObj
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset		; re-dereference parent

		add	cx, ds:[di].VI_bounds.R_left
		add	dx, ds:[di].VI_bounds.R_top
setPosition:
	;
	;  Move the child.
	;
		push	bp				; locals
		mov	bx, ss:child.handle
		mov	si, ss:child.chunk		; ^lbx:si = child
		mov	ax, MSG_VIS_POSITION_BRANCH
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp				; locals
noPosition:
	;
	;  Set up to loop to next child.
	;
		inc	ss:counter
		jmp	childLoop
done:
		.leave
		ret
PositionSingleGroupWithSlotHints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionMultipleGroupWithSlotHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CALLED BY:	ShowCurGroupWithSlotHints()

PASS:		*ds:si	= OLMenuBar object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	position all children offscreen to make things easy, first.

	for (i=0; i<4; i++) {
	    /* find child with slot hint (i + (4)*curGroup) */
	    /* if found, position child in slot i */
	}

	put More trigger in slot 5

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionMultipleGroupWithSlotHints	proc	near
		uses	ax,bx,cx,dx,si,di,bp

		parentObj	local	lptr	push	si
		counter		local	word
		child		local	optr

		.enter
	;
	;  Position everything offscreen.
	;
		call	PositionChildrenOffscreen
	;
	;  Now position the 1-4 children from the current group.
	;
		clr	ss:counter		; i = 0
childLoop:
	;
	;  Calculate i + 4*curGroup.
	;
		mov	cx, ss:counter		; cx = i
		mov	si, ss:parentObj	; *ds:si = parent
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset	; ds:di = OLMenuBarInstance
		mov	dx, ds:[di].OLMBAR_curGroup
		shl	dx			; dx = curGroup * 2
		shl	dx			; dx = curGroup * 4
		add	cx, dx			; cx = child number to get
	;
	;  Get child(i+4*curGroup) to put in slot i.  Here
	;  is the difference between PositionMultipleGroup and
	;  this routine:  if we don't find the child, we move
	;  on to the next slot.
	;
		call	GetChildWithSlotHint	; ^lcx:dx = child
		jnc	nextSlot
		Assert	optr	cxdx
		movdw	ss:child, cxdx		; save it
	;
	;  Get the slot position from the table.
	;
		mov	bx, ss:[counter]
		shl	bx			; word-entry table
		mov	cx, cs:[jediPositionTable][bx]
		mov	dx, MENU_BAR_BUTTON_Y_OFFSET
	;
	;  Adjust position by adding menu bar upper-left corner.
	;
		add	cx, ds:[di].VI_bounds.R_left
		add	dx, ds:[di].VI_bounds.R_top
	;
	;  Set the position of the child.
	;
		push	bp			; locals
		movdw	bxsi, ss:child
		mov	ax, MSG_VIS_POSITION_BRANCH
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp			; locals
nextSlot:
	;
	;  Move on to the next slot.
	;
		inc	ss:counter		; next slot
		cmp	ss:counter, MENU_BAR_NUMBER_OF_SLOTS - 1
		jb	childLoop
doneLoop:
		.leave
		ret
PositionMultipleGroupWithSlotHints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSlotNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find out what slot was requested.

CALLED BY:	PositionSingleGroupWithSlotHints

PASS:		^lbx:si = child object

RETURN:		bx	= slot number requested
		carry set if slot found
		carry clear if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSlotNumber	proc	near
		uses	ax, cx, dx, si, ds
		.enter
	;
	;  Lock the thing down (probably not necessary, but...)
	;
		call	ObjLockObjBlock		; ax = segment
		mov	ds, ax			; *ds:si = child
	;
	;  See if it's got the hint.
	;
		mov	dx, bx
		mov	ax, HINT_SEEK_SLOT
		call	ObjVarFindData
		jnc	unlock			; not found
	;
	;  Save slot hint in cx, unlock the object block, and
	;  return slot hint in bx.
	;
		mov	cx, {word}ds:[bx]	; save slot number, if any
unlock:
		lahf				; save whether found
		mov	bx, dx			; bx = object block
		call	MemUnlock
		mov	bx, cx			; bx = slot hint
		sahf				; return whether found

		.leave
		ret
GetSlotNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionChildrenOffscreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position all children offscreen.

CALLED BY:	PositionMultipleGroup,
		PositionMultipleGroupWithSlotHints

PASS:		*ds:si = OLMenuBar object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionChildrenOffscreen	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		clr	cx, di		; start at child 0
		push	di
		push	di			; push starting child #

		mov	di, offset VI_link
		push	di			; push offset to LinkPart

		mov	di, SEGMENT_CS
		push	di
		mov	di, offset OffScreenCallback
		push	di

		mov	bx, offset Vis_offset	; Use the vis linkage
		mov	di, offset VCI_comp
		call	ObjCompProcessChildren

		.leave
		ret
PositionChildrenOffscreen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OffScreenCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the object offscreen.

CALLED BY:	PositionMultipleGroup via ObjCompProcessChildren

PASS:		*ds:si	= object
		es:di	= composite
		cx	= child number

RETURN:		cx	= next child

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OffScreenCallback	proc	far
		uses	cx				; not really
		.enter
	;
	;  If it's the app menu, position differently.
	;
		mov	di, es:[di]
		add	di, es:[di].Vis_offset		; deref parent

		mov	ax, TEMP_OL_BUTTON_APP_MENU_BUTTON
		call	ObjVarFindData
		jnc	notAppMenu

		mov	cx, APP_MENU_X_OFFSET
		mov	dx, MENU_BAR_BUTTON_Y_OFFSET
		add	cx, es:[di].VI_bounds.R_left	; adjust to parent
		add	dx, es:[di].VI_bounds.R_top
		jmp	setPosition
notAppMenu:
	;
	;  If it's the More trigger, position differently.
	;
		mov	ax, TEMP_OL_BUTTON_MORE_TRIGGER
		call	ObjVarFindData
		jnc	normalChild

		mov	cx, MORE_TRIGGER_X_OFFSET
		mov	dx, MENU_BAR_BUTTON_Y_OFFSET
		add	cx, es:[di].VI_bounds.R_left	; adjust to parent
		add	dx, es:[di].VI_bounds.R_top
		jmp	setPosition
normalChild:
		mov	cx, OFFSCREEN_X_POSITION
		mov	dx, OFFSCREEN_Y_POSITION
setPosition:
		mov	ax, MSG_VIS_POSITION_BRANCH
		call	ObjCallInstanceNoLock
done:
		.leave
		inc	cx				; next child
		ret
OffScreenCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildWithSlotHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the child requesting the current slot, if any.

CALLED BY:	PositionMultipleGroupWithSlotHints

PASS:		cx	= slot number

RETURN:		carry set if found - 
		  ^lcx:dx = child with that hint
		carry clear if not found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildWithSlotHint	proc	near
		uses	ax, bx, di
		.enter
	;
	;  Traverse the children to look for the hint.
	;
		clr	di			; start at child 0
		push	di
		push	di			; push starting child #

		mov	di, offset VI_link
		push	di			; push offset to LinkPart

		mov	di, SEGMENT_CS
		push	di
		mov	di, offset SlotHintCallBack
		push	di

		mov	bx, offset Vis_offset	; Use the vis linkage
		mov	di, offset VCI_comp
		call	ObjCompProcessChildren
	;
	;  Depending on what was returned in ax, return the
	;  carry to indicate success or failure.
	;
		tst_clc	ax
		jz	done
		stc
done:
		.leave
		ret
GetChildWithSlotHint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlotHintCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this child has requested slot hint number.

CALLED BY:	GetChildWithSlotHint

PASS:		*ds:si	= child
		cx	= slot number for which to search

RETURN:		carry - set to end processing
		ax    - nonzero if child was found

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlotHintCallBack	proc	far
		uses	es
		.enter
	;
	;  First check to see if we have the hint at all.  If
	;  the object is of OLButtonClass (or a subclass), then
	;  the hint won't be on this object; instead it'll be
	;  on the associated Gen object.
	;
		mov	dx, si				; save vis object
		mov	di, segment OLButtonClass
		mov	es, di
		mov	di, offset OLButtonClass
		call	ObjIsObjectInClass
		jnc	checkHint
	;
	;  Check associated Gen object instead...
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		mov	si, ds:[di].OLBI_genChunk	; *ds:si = gen object
checkHint:
		mov	ax, HINT_SEEK_SLOT
		call	ObjVarFindData			; carry set if found
		jnc	notFound
	;
	;  Check the extra data.
	;
		mov	si, dx				; *ds:si = vis object
		cmp	cx, {word}ds:[bx]
		jne	notFound
	;
	;  Return ourselves.
	;
		mov	cx, ds:[LMBH_handle]		; cx = block handle
		mov	dx, si				; ^lcx:dx = object
		mov	ax, 1				; found it
		stc					; end processing
done:
		.leave
		ret
notFound:
		clr	ax				; not found
		clc					; continue processing
		jmp	done
SlotHintCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuBarPositionChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap groups.  Sent by "More" trigger.

CALLED BY:	MSG_OL_MENU_BAR_POSITION_CHILDREN

PASS:		*ds:si	= OLMenuBarClass object
		ds:di	= OLMenuBarClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

  PositionChildrenViaMoreTrigger:

	/* possible optimization: if curCount = #children,
	   skip recalculation of number of groups below */

	/* figure out whether to reset or increment curGroup:
	   first calc numGroups */

	#	numGroups	picture
	---------------------------------------------
	0-5 	1		*****	(0-4 in positions 1-5)
				M	(More trigger offscreen)

	6-8	2		****M
				****	(5-8 positioned offscreen)

	9-12	3		****M
				****	(5-8 offscreen)
				****	(9-12 offscreen)

	13-16	4		****M
				****	(5-8 offscreen)
				****	(9-12 offscreen)
				****	(13-16 offscreen)

	algorithm:

	  if (0 <= #children <=5) { numGroups = 1 } else
	  if (6 <= #children <= 8) { numGroups = 2 } else
	  numGroups = 3 + ((numChildren - 8) div 4);

	/* now reset or increment curGroup */

	if (curGroup >= numGroups-1) { curGroup = 0; }
	if (curGroup < numGroups-1)  { curGroup++; }

	/* finally, show the current group */

	ShowCurGroup();

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLMenuBarPositionChildren	method dynamic OLMenuBarClass, 
					MSG_OL_MENU_BAR_POSITION_CHILDREN
		.enter

	;
	; First close all menus
	;
		push	si
		mov	ax, MSG_OL_MENU_BUTTON_CLOSE_MENU
		mov	bx, segment OLMenuButtonClass
		mov	si, offset OLMenuButtonClass
		mov	di, mask MF_RECORD
		call	ObjMessage		; di = classed event
		pop	si
		mov	cx, di			; cx = classed event
		mov	ax, MSG_VIS_SEND_TO_CHILDREN
		call	ObjCallInstanceNoLock

	;
	;  Run through the children and either a) count them, or
	;  b) get the highest requested slot (if the children have
	;  slot hints).  Then figure out the number of groups from
	;  that.
	;
		call	CountChildrenAndCalcGroups
	;
	;  Now reset or increment curGroup:
	;	if (curGroup >= numGroups-1) { curGroup = 0; }
	;	if (curGroup < numGroups-1)  { curGroup++; }
	;
		dec	cx			; cx = numGroups-1

		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		cmp	ds:[di].OLMBAR_curGroup, cx
		jae	reset

		inc	ds:[di].OLMBAR_curGroup
		jmp	showGroup
reset:
		clr	ds:[di].OLMBAR_curGroup
showGroup:
	;
	;  Show the current group.
	;
		tst	ax
		jnz	slotHints

		call	PositionMultipleGroup
		jmp	invalParent
slotHints:
		call	PositionMultipleGroupWithSlotHints
invalParent:
	;
	;  Invalidate the parent to force the children to redraw.
	;
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_IMAGE_INVALID
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock

		.leave
		ret
OLMenuBarPositionChildren	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CountChildrenAndCalcGroups
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count children and get number of groups.

CALLED BY:	OLMenuBarPositionChildren, PositionChildren

PASS:		*ds:si	= OLMenuBar

RETURN:		ax = nonzero for slot hints:
		  dx = highest slot hint
		ax = zero for no slot hints:
		  dx = num children (not counting app or more triggers)
		cx = num groups

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CountChildrenAndCalcGroups	proc	near
		uses	bx,si,di
		.enter
	;
	;  Loop through children to determine if they have
	;  slot hints, and if so, what the highest slot-hint
	;  number is.  This routine counts the children, too.
	;
		clr	ax, cx, dx, di		; start at child 0
		push	di
		push	di			; push starting child #

		mov	di, offset VI_link
		push	di			; push offset to LinkPart

		mov	di, SEGMENT_CS
		push	di
		mov	di, offset PositionMenuChildrenCB
		push	di

		mov	bx, offset Vis_offset	; Use the vis linkage
		mov	di, offset VCI_comp
		call	ObjCompProcessChildren
	;
	;  Returned:  cx = child count, ax = nonzero if slot
	;  hints were found, dx = highest slot number requested.
	;
	;  Reality check to see if we hosed the count.
	;
EC <		cmp	cx, REALITY_CHECK_MAX_NUM_CHILDREN		>
EC <		ERROR_A	-1						>
	;
	;  Set up cx = child count or highest slot
	;
		tst	ax			; slot hints?
		jnz	gotNumChildren		; yep, use dx
		mov	dx, cx			; nope, use cx
gotNumChildren:
	;
	;  Calculate the current number of groups, as it may
	;  have changed since we last checked it:
	;
	;    if (0 <= #children <=5) { numGroups = 1 }
	;
		mov	cx, 1
		cmp	dx, MENU_BAR_NUMBER_OF_SLOTS
		jbe	gotGroups	
	;
	;  if (6 <= #children <= 8) { numGroups = 2 }
	;
	;  (I don't really know how to map the "8" to the
	;  constants I've defined -- lame, eh?  I got it
	;  empirically by looking at the drawings.)
	;
		inc	cx
		cmp	dx, 8
		jbe	gotGroups
	;
	;  numGroups = 3 + ((numChildren - 8) div 4);
	;
		mov	ax, dx				; save num children
		sub	dx, 8
		shr	dx
		shr	dx
		inc	dx
		inc	dx
		inc	dx
		mov	cx, dx
		mov_tr	dx, ax				; dx = #children
gotGroups:
		.leave
		ret
CountChildrenAndCalcGroups	endp


MenuBarCommon	ends
