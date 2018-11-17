COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1994.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Icon editor
MODULE:		Viewer
FILE:		viewerKbd.asm

AUTHOR:		Steve Yegge, Jun 17, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT ViewerKeyUp		User pressed the up-arrow key

    INT FindIconAboveMe		Returns the icon "above" the selected icon.

    INT ViewerKeyDown		User pressed the down-arrow key.

    INT FindIconBelowMe		Returns an icon below the passed one, if
				possible.

    INT ViewerKeyLeft		User pressed the left-arrow key or
				shift+tab

    INT ViewerKeyRight		User pressed the right-arrow key or the tab
				key.

    INT ViewerKeyEnter		User pressed the return key.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/17/94		Initial revision

DESCRIPTION:

	Keyboard navigation for the database viewer.

	$Id: viewerKbd.asm,v 1.1 97/04/04 16:07:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ViewerCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate keyboard navigation routine.

CALLED BY:	MSG_META_KBD_CHAR

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high = scan code

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- if we're releasing the key, bail
	- if it's not an arrow key, tab, enter, or one of the
	  edit keys, then bail
	- call the appropriate handler
	- have the title bar redo its triggers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerKbdChar		proc	far
		class	DBViewerClass
		.enter
	;
	;  Correct character set?
	;
		cmp	ch, CS_CONTROL
		jne	done
	;
	;  If they're releasing the key do nothing.
	;
		test	dl, mask CF_RELEASE
		jnz	done

		cmp	cl, VC_UP
		jne	notUp
		
		call	ViewerKeyUp
		jmp	short	gotKey
notUp:
		cmp	cl, VC_DOWN
		jne	notDown
		
		call	ViewerKeyDown
		jmp	short	gotKey
notDown:
		cmp	cl, VC_RIGHT
		jne	notRight
		
		call	ViewerKeyRight
		jmp	short	gotKey
notRight:
		cmp	cl, VC_LEFT
		jne	notLeft
		
		call	ViewerKeyLeft
		jmp	short	gotKey
notLeft:
		cmp	cl, VC_ENTER
		jne	notEnter
		
		call	ViewerKeyEnter
		jmp	short	gotKey
notEnter:
		cmp	cl, VC_TAB
		jne	notTab
		
		test	dh, mask SS_LSHIFT or mask SS_RSHIFT
		jnz	shiftTab
		
		call	ViewerKeyRight			; tab
		jmp	short	gotKey
shiftTab:
		call	ViewerKeyLeft			; shift+tab
notTab:
		cmp	cl, VC_DEL
		jne	done
		
		mov	ax, MSG_DB_VIEWER_DELETE_ICONS
		call	ObjCallInstanceNoLock
		
		jmp	short	gotKey
gotKey:
	;
	;  Make sure the selection is visible by scrolling the view.
	;
		mov	ax, MSG_DB_VIEWER_SHOW_SELECTION
		call	ObjCallInstanceNoLock
	;
	;  One of the keys was pressed, so we know we're at 1
	;  selection now.  Tell the title bar.
	;
		mov	cx, 1				; 1 selection
		mov	ax, MSG_DB_VIEWER_ENABLE_UI
		call	ObjCallInstanceNoLock
		
done:
		.leave
		ret
DBViewerKbdChar	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerKeyUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User pressed the up-arrow key

CALLED BY:	DBViewerKbdChar

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	- at this point we have a problem.  I will draw a picture of
	  it for you:

			-----------------
			|		|
			|		|
			|		|
			|		|
			-----------------

		----------	     ----------
		|	 |	     |	      |
		|	 |	     |	      |
		|	 |	     |	      |
		----------	     ----------

		---------------------------------
		|				|
		|				|
		|				|
		|	   (selected)		|
		|				|
		|				|
		|				|
		---------------------------------

	The problem is, if the bottom icon is selected, and the
	user hits the up-arrow key, which icon should get selected?
	There are many special cases, considering icons can have
	variable heights & widths.

	Ideally, you'd want an algorithm that meets the following
	criteria:

		1)  If there is a row of icons above the currently
		    selected icon, one of the icons in that row
		    should be selected.
		2)  If only one icon is immediately above the
		    selected icon (as will be the case when all
		    icons are equal-sized, or sometimes if the
		    icons in the row above are larger than the
		    selected icon), then that one should always
		    get selected.
		3)  If more than one icon is "immediately above"
	       	    the selected icon (as in the drawing), then
		    the result should be predictable by the user.
		    (e.g. the leftmost icon, or rightmost, or
		    some other set position, should always be
		    selected).

	This algorithm would take more time and space than I want
	to give it, so I'm going to use a different algorithm that
	is predictable for the user (hopefully), and works well
	when all the icons are the same size (a typical case, 
	presumably).  (See below)

PSEUDO CODE/STRATEGY:

	- get first selection
	- if none selected, select first child and quit

	- find the midpoint of the top row of pixels of the
	  selected icon.  Start moving up in small increments
	  until you've either:

		* found a child, or
		* hit the top of the content

	  If we find a child, we deselect the current icon and
	  select the new one, otherwise just quit.

	- count the total number of selections:
		if more than one, use DBViewerSetSingleSelection
		if only one, use DBViewerSetSelection twice

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerKeyUp	proc	near
		uses	si
		.enter
		
		mov	ax, MSG_DB_VIEWER_GET_FIRST_SELECTION
		call	ObjCallInstanceNoLock		; returns in cx
		jnc	foundOne
		
		clr	cx
		mov	dx, 1
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock
		jmp	short	done
foundOne:
	;
	;  At this point, cx = (first selection).  We need to find the
	;  next one, if any.
	;
		call	FindIconAboveMe			; dx <- new icon
		jc	done				; none found.
	;
	;  At this point, cx = (first selection) and dx = (next selection)
	;  If there is more than one selection, we want to do a
	;  DBViewerSetSingleSelection to get rid of all the
	;  other selections.  On the other hand, that's really slow,
	;  so if there's only one selection, we should just select
	;  the next one and deselect the previous one.
	;
		push	cx				; save old icon
		call	DBViewerGetNumSelections	; returns in cx
		mov_tr	ax, cx				; ax = # selections
		pop	cx				; restore old icon
		cmp	ax, 1				; ax = num selections
		je	oneSelected
		
		mov	cx, dx				; cx = new one
		clr	bp				; UIFunctionsActive
		mov	ax, MSG_DB_VIEWER_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
		
		jmp	short	done
oneSelected:
	;
	;  At this point, dx = (new selection) and cx = (old selection).
	;  Select the new one and deselect the old one.
	;
		xchg	cx, dx				; cx = new one
		push	dx				; save old one
		mov	dx, 1				; select it
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock
		
		pop	cx				; restore old one
		clr	dx				; deselect it
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
ViewerKeyUp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindIconAboveMe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the icon "above" the selected icon.

CALLED BY:	ViewerKeyUp

PASS:		*ds:si	= DBViewer object
		cx	= selected icon

RETURN:		dx	= icon to select
		carry set if not found, clear if found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Move up from the middle of the selected icon until we
	either hit the top of the content, or we hit an icon.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/3/93		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindIconAboveMe	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,di,bp
		.enter
	;
	;  Find the (x,y) position in the top-middle of the passed icon.
	;
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock		; ^lcx:dx = child
		
		push	ds:[LMBH_handle], si		; save viewer
		
		movdw	bxsi, cxdx
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjMessage		; (ax, bp) = UL; (cx, dx) = LR
		
		sub	cx, ax			; cx = (right-left)
		shr	cx			; cx = cx/2
		add	cx, ax			; cx = left + (right-left)/2
		mov	dx, bp			; (cx,dx) = top-middle point
	;
	;  Start moving upward at some reasonable jump-interval until
	;  we hit the top, or a child.  Each time, call the child
	;  under the point, asking it for its number, and if we
	;  find one we'll have its number.
	;
		pop	bx, si
		call	MemDerefDS		; *ds:si = Viewer object
searchLoop:
		sub	dx, VIEWER_VERTICAL_CHILD_SPACING
		mov	ax, MSG_VIS_ICON_GET_NUMBER
		call	VisCallChildUnderPoint	; returns number in cx
		jc	foundOne		; found a child
		
		cmp	dx, 0
		jg	searchLoop
	;
	;  If we got here, we hit the top of the content without
	;  finding a child.  Set the carry and bail.
	;
		stc
		jmp	short	done
foundOne:
	;
	;  If we got here, we found a child, and it returned its
	;  number in cx.  Move it into dx, clear the carry and bail.
	;
		mov	dx, cx
		clc
done:
		.leave
		ret
FindIconAboveMe	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerKeyDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User pressed the down-arrow key.

CALLED BY:	DBViewerKbdChar

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:

	- get first selection
	- if none selected, select first child and quit

	- find a child below us, if possible.  Select it.
	  (see the comments in ViewerKeyUp's header).

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerKeyDown	proc	near
		uses	si
		.enter
		
		mov	ax, MSG_DB_VIEWER_GET_FIRST_SELECTION
		call	ObjCallInstanceNoLock		; returns in cx
		jnc	foundOne
		
		clr	cx
		mov	dx, 1
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock
		jmp	short	done
foundOne:
	;
	;  At this point, cx = (first selection).  We need to find
	;  the next selection.
	;
		call	FindIconBelowMe			; dx <- new one
		jc	done				; not found
	;
	;  At this point, cx = (first selection) and dx = (new selection).
	;  If there is more than one selection, we want to do a
	;  DBViewerSetSingleSelection to get rid of all the
	;  other selections.  On the other hand, that's really slow,
	;  so if there's only one selection, we should just select
	;  the next one and deselect the previous one.
	;
		push	cx				; save new selection
		call	DBViewerGetNumSelections	; returns in cx
		mov_tr	ax, cx
		pop	cx				; restore new icon
		cmp	ax, 1				; ax = num selections
		je	oneSelection
		
		mov	cx, dx				; new selection
		clr	bp				; UIFunctionsActive
		mov	ax, MSG_DB_VIEWER_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
		
		jmp	short	done
oneSelection:
	;
	;  At this point, cx = (old selection) and dx = (new selection).
	;  Select the new one and deselect the old one.
	;
		xchg	cx, dx				; cx = new one
		push	dx				; save old one
		mov	dx, 1				; select it
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock
		
		pop	cx				; restore old one
		clr	dx				; deselect it
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
ViewerKeyDown	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindIconBelowMe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns an icon below the passed one, if possible.

CALLED BY:	ViewerKeyDown

PASS:		cx	= selected icon

RETURN:		dx	= new icon
		carry set if not found, clear if found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- see FindIconAboveMe

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/2/93		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindIconBelowMe	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,di,bp
		.enter
	;
	;  Find the (x,y) position in the bottom-middle of the passed icon.
	;
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock		; ^lcx:dx = child
		
		push	ds:[LMBH_handle], si		; save viewer
		
		movdw	bxsi, cxdx
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjMessage		; (ax, bp) = UL; (cx, dx) = LR
		
		sub	cx, ax			; cx = (right-left)
		shr	cx			; cx = cx/2
		add	cx, ax			; cx = left + (right-left)/2
	;
	; (cx, dx) = bottom-middle point
	;
	;  Start moving down at some reasonable jump-interval until
	;  we hit the bottom, or a child.  Each time, call the child
	;  under the point, asking it for its number, and if we
	;  find one we'll have its number.  First we have to get the
	;  bottom of the content.
	;
		pop	bx, si
		call	MemDerefDS		; *ds:si = Viewer object
		
		push	cx, dx			; save starting point
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock	; dx = height
		mov	bp, dx			; loop-test value
		pop	cx, dx			; restore starting point
		add	dx, VIEWER_VERTICAL_CHILD_SPACING
searchLoop:
		mov	ax, MSG_VIS_ICON_GET_NUMBER
		call	VisCallChildUnderPoint	; returns number in cx
		jc	foundOne		; found a child
		
		add	dx, VIEWER_VERTICAL_CHILD_SPACING
		cmp	dx, bp			; hit bottom yet?
		jl	searchLoop
	;
	;  If we got here, we hit the top of the content without
	;  finding a child.  Set the carry and bail.
	;
		stc
		jmp	short	done
foundOne:
	;
	;  If we got here, we found a child, and it returned its
	;  number in cx.  Move it into dx, clear the carry and bail.
	;
		mov	dx, cx
		clc
done:
		.leave
		ret
FindIconBelowMe	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerKeyLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User pressed the left-arrow key or shift+tab

CALLED BY:	DBViewerKbdChar

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:

	- pretty much the same as ViewerKeyRight

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerKeyLeft	proc	near
		uses	si
		.enter
		
		mov	ax, MSG_DB_VIEWER_GET_FIRST_SELECTION
		call	ObjCallInstanceNoLock		; returns in cx
		jnc	foundOne
		
		clr	cx				; first child
		mov	dx, 1				; select it
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock
		jmp	short	done
foundOne:
	;
	;  See if we're already at the far left.  If so, bail.
	;
		tst	cx
		jz	done
	;
	;  At this point, cx = (first selection).  If there is more
	;  than one selection, we want to turn the others off, but
	;  since it's slow, we check for this condition first.  If
	;  there's only one selection, we select the next one, and
	;  deselect the current one.  (This is the typical case).
	;
		mov_tr	ax, cx
		call	DBViewerGetNumSelections	; returns in cx
		xchg	cx, ax				; cx = selection
		cmp	ax, 1
		je	oneSelected
		
		clr	bp				; UIFunctionsActive
		dec	cx				; cx = previous
		mov	ax, MSG_DB_VIEWER_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
		
		jmp	short	done
oneSelected:
		
		push	cx				; save current
		dec	cx				; cx = previous
		mov	dx, 1				; select it
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock
		
		pop	cx				; restore current
		clr	dx				; deselect it
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock		; deselect self
done:
		.leave
		ret
ViewerKeyLeft	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerKeyRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User pressed the right-arrow key or the tab key.

CALLED BY:	DBViewerKbdChar

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:

	- get the first selection
	- if none, set first icon as selection and bail
	- if already at far right, quit
 	- count the selections
	- if only one, do the fast way
	- of more than one, do the slow way

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerKeyRight	proc	near
		uses	si
		.enter
		
		mov	ax, MSG_DB_VIEWER_GET_FIRST_SELECTION
		call	ObjCallInstanceNoLock		; returns in cx
		jnc	foundOne
		
		clr	cx				; first child
		mov	dx, 1				; select it
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock
		jmp	short	done
foundOne:	
	;
	;  See if we're already at the far right.  If so, bail.
	;
		push	cx, ds:[LMBH_handle], si	; save selection & OD
		mov	ax, MSG_VIS_COUNT_CHILDREN
		call	ObjCallInstanceNoLock		; returns in dx
		pop	cx, bx, si			; cx = selection
		
		dec	dx				; 0-indexed children
		cmp	cx, dx				; are we last?
		je	done
		
		call	MemDerefDS			; *ds:si = object
	;
	;  At this point, cx = (first selection).  If there is more 
	;  than one selection, we want to turn the others off, but
	;  since this is slow, we check for this condition first.
	;  Otherwise we just select the next icon, and deselect the
	;  current one.
	;
		push	cx				; save selection
		
		mov	ax, MSG_DB_VIEWER_GET_NUM_SELECTIONS
		call	ObjCallInstanceNoLock		; returns in cx
		cmp	cx, 1
		je	oneSelected
		
		pop	cx				; cx = selection
		inc	cx				; cx = next
		clr	bp				; UIFunctionsActive
		mov	ax, MSG_DB_VIEWER_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
		
		jmp	short	done
oneSelected:
		pop	cx				; cx = selection
		inc	cx				; cx = next
		mov	dx, 1				; select next
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock		; destroys nothing
		
		dec	cx				; cx = current
		clr	dx
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock		; deselect self
done:
		.leave
		ret
ViewerKeyRight	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerKeyEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User pressed the return key.

CALLED BY:	DBViewerKbdChar

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:

	- select the first icon if none selected
	- send an edit-icon message to the process

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerKeyEnter	proc	near
		uses	si
		.enter
		
		mov	ax, MSG_DB_VIEWER_GET_FIRST_SELECTION
		call	ObjCallInstanceNoLock			; returns in cx
		jnc	foundOne
		
		clr	cx
		mov	dx, 1
		mov	ax, MSG_DB_VIEWER_SET_SELECTION
		call	ObjCallInstanceNoLock
		jmp	short	done
foundOne:
	;
	;  Make this the currently-edited icon.
	;
		mov	ax, MSG_DB_VIEWER_EDIT_ICON
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
ViewerKeyEnter	endp

ViewerCode	ends
