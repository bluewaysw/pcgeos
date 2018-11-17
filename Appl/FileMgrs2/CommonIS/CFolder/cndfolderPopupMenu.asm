COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		cndfolderPopupMenu.asm

AUTHOR:		Joon Song, Mar 19, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/19/93   	Initial revision


DESCRIPTION:
	This file contains code for NDPopupMenuClass
		

	$Id: cndfolderPopupMenu.asm,v 1.2 98/06/03 13:11:37 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDFolderCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPopupMenuVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that only one popup menu is open at any one time.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= NDPopupMenuClass object
		es 	= segment of NDPopupMenuClass
		bp	= 0 if top window, else window for object to open on
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/19/93   	Initial version
	dlitwin 3/27/93		added the "folderInitiated" check

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPopupMenuVisOpen	method dynamic NDPopupMenuClass, 
					MSG_VIS_OPEN
	uses	ax, si, bp, es
	.enter

	segmov	es, dgroup, ax
	;
	; Indicate that we are the popup menu
	;
	mov	bx, ds:[LMBH_handle]
	mov	cx, si			; save object's chunk handle in cx
	xchgdw	bxsi, es:[popupMenu]
	tst	bx
	jz	done
	;
	; Close the previous popup menu
	;
	push	cx			; save object's chunk handle
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx			; restore object's chunk handle
done:
	;
	; Check to see if we were brought up by the system menu, and if so
	; make sure the folder to which our menu items will send their
	; messages will have the correct NewDeskPopUpType.
	;
	mov	si, cx			; restore object's chunk handle to si
	tst	ds:[di].NDPM_folderInitiated
	jnz	initiatedByFolder

	call	NDPopupMenuSetFolderPopupTypeToWhitespace

initiatedByFolder:
	clr	ds:[di].NDPM_folderInitiated

	.leave

	mov	di, offset NDPopupMenuClass
	GOTO	ObjCallSuperNoLock

NDPopupMenuVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPopupMenuSetFolderPopupTypeToWhitespace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message back to the folder class associated with
		this window (the window of the drop down menu) to set its
		instance data as if this were brought up like a whitespace
		popup, so the Sort/View UI will send its messages to the 
		right place.  This basically nukes the need for the
		"send as whitespace" message, but the "send as selected" and
		"send as single selection" messages still have use in that
		they do selection checking and error handling as well as
		setting the popup type.  Not worth changing all the "send as
		whitespace" messages, as they will do the right thing now, 
		albeit a bit redundantly.

CALLED BY:	NDPopupMenuVisOpen

PASS:		*ds:si	- NDPopupMenu object
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/27/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPopupMenuSetFolderPopupTypeToWhitespace	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	push	si, di
	mov	ax, MSG_ND_FOLDER_SET_POPUP_TYPE
	mov	cl, WPUT_WHITESPACE
	mov	bx, segment NDFolderClass
	mov	si, offset NDFolderClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; record into a ClassedEvent
	mov	cx, di				; move ClassedEvent into cx
	pop	si, di

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_OBJ_BLOCK_OUTPUT
	call	ObjCallInstanceNoLock

	.leave
	ret
NDPopupMenuSetFolderPopupTypeToWhitespace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPopupMenuSetFolderInitiated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the NDPM_folderInitiated flag to indicate that the
		popup was brought up by the folder and so the NDFOI_popUpType
		is already correct.


CALLED BY:	MSG_ND_POPUP_MENU_SET_FOLDER_INITIATED

PASS:		*ds:si	= NDPopupMenuClass object
		ds:di	= NDPopupMenuClass instance data

RETURN:		none
DESTROYED:	none

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPopupMenuSetFolderInitiated method dynamic NDPopupMenuClass, 
					MSG_ND_POPUP_MENU_SET_FOLDER_INITIATED
	.enter

	mov	ds:[di].NDPM_folderInitiated, -1

	.leave
	ret
NDPopupMenuSetFolderInitiated	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPopupVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that only one popup menu is open at any one time

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= NDPopupMenuClass object
		ds:di	= NDPopupMenuClass instance data
		ds:bx	= NDPopupMenuClass object (same as *ds:si)
		es 	= segment of NDPopupMenuClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This should work since all UI objects are run by
		a single thread.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPopupVisClose	method dynamic NDPopupMenuClass, 
					MSG_VIS_CLOSE
	mov	di, offset NDPopupMenuClass
	call	ObjCallSuperNoLock		

	segmov	es, dgroup, ax
	;
	; Check to see if any other popup menus have opened since we opened.
	;
	mov	bx, ds:[LMBH_handle]
	cmp	bx, es:[popupMenu].handle
	jne	done
	;
	; No, indicate that there are no popup menus open.
	;
	mov	es:[popupMenu].handle, NULL
done:
	ret	
NDPopupVisClose	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDSortViewPopupVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach the GlobalMenuSortAndView to ourselves in the 
		subinteraction and child position specified in our instance
		data.

CALLED BY:	MSG_VIS_OPEN

PASS:		*ds:si	= NDPopupMenuClass object
		es	= segment of NDSortViewPopupMenuClass
RETURN:		nothing
DESTROYED:	all

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/25/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDSortViewPopupVisOpen method dynamic NDSortViewPopupMenuClass,
					MSG_VIS_OPEN
	.enter

	push	bp, es
	segmov	es, dgroup, ax

	cmp	ds:[LMBH_handle], handle GlobalMenuResource
	jne	notGlobalMenu

	test	es:[globalMenuState].GMB_low, mask GMBL_SORT
LONG	jz	exit			; exit if sort isn't usable

notGlobalMenu:
BA<	cmp	ds:[LMBH_handle], handle NDDesktopMenu			>
BA<	jne	notDesktopMenu						>
BA<	call	UtilAreWeInEntryLevel?					>
BA<LONG	jc	exit		; Guided DesktopMenu gets no Sort/View menu >
BA<notDesktopMenu:							>
	push	si				; save our object handle

	mov	ax, MSG_GEN_FIND_PARENT
	mov	bx, handle GlobalMenuSortAndView
	mov	si, offset GlobalMenuSortAndView
	call	ObjMessageCallFixup
	jcxz	afterParentCheck

	pop	si				; restore object handle
	push	si				; save object handle again
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	cx, ds:[di].NDSVPM_sortViewParent.handle
	jne	afterParentCheck
	cmp	dx, ds:[di].NDSVPM_sortViewParent.offset
	je	setUsable			; same parent, already attached

afterParentCheck:
	test	es:[globalMenuState].GMB_low, mask GMBL_SORT
	jz	sortViewNotUsable

	push	cx, dx
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset GlobalMenuSortAndView
	call	ObjMessageCallFixup
	pop	cx, dx

sortViewNotUsable:
	jcxz	noParent

	mov	ax, MSG_GEN_REMOVE_CHILD
	mov	bx, cx
	mov	si, dx
	mov	cx, handle GlobalMenuSortAndView
	mov	dx, offset GlobalMenuSortAndView
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjMessageCallFixup

noParent:
	pop	si				; restore object handle
	push	si				; save object handle

	mov	ax, MSG_GEN_ADD_CHILD
	mov	cx, handle GlobalMenuSortAndView
	mov	dx, offset GlobalMenuSortAndView
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].NDSVPM_sortViewParent.handle
	mov	si, ds:[di].NDSVPM_sortViewParent.offset
	mov	bp, ds:[di].NDSVPM_sortViewPosition
	call	ObjMessageCallFixup

	; Add/remove same category hint
	pop	si
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, handle GlobalMenuViewMode
	mov	si, offset GlobalMenuViewMode
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	mov	cl, GIV_POPUP
	test	ds:[di].NDSVPM_sortViewFlags, NDSVPMF_VIEW_NOT_SUBMENU
	jnz	notSubMenu
	mov	cl, GIV_SUB_GROUP
notSubMenu:
	call	ObjMessageCallFixup

setUsable:
	pop	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].NDSVPM_sortViewFlags
	and	ax, mask NDSVPMF_NOT_FOR_MENU or mask NDSVPMF_POPPING_UP
	cmp	ax, mask NDSVPMF_NOT_FOR_MENU
	je	exit
	push	si
	mov	ax, MSG_GEN_SET_USABLE
	mov	bx, handle GlobalMenuSortAndView
	mov	si, offset GlobalMenuSortAndView
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessageCallFixup

	; check for view
	pop	si
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, MSG_GEN_SET_NOT_USABLE
	test	ds:[di].NDSVPM_sortViewFlags, mask NDSVPMF_NO_VIEW
	jnz	viewNotUsable
	mov	ax, MSG_GEN_SET_USABLE
viewNotUsable:
	mov	bx, handle GlobalMenuViewMode
	mov	si, offset GlobalMenuViewMode
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessageCallFixup

	or	es:[globalMenuState].GMB_low, mask GMBL_SORT
	pop	si				; restore object handle

exit:
	pop	bp, es
	mov	ax, MSG_VIS_OPEN
	mov	di, offset NDSortViewPopupMenuClass
	call	ObjCallSuperNoLock

	.leave
	ret
NDSortViewPopupVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDSortViewPopupPrePopup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets Sr
		subinteraction and child position specified in our instance
		data.

CALLED BY:	MSG_ND_POPUP_MENU_PRE_POPUP

PASS:		*ds:si	= NDPopupMenuClass object
		es	= segment of NDSortViewPopupMenuClass
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	3/18/02    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDSortViewPopupPrePopup method dynamic NDSortViewPopupMenuClass,
					MSG_ND_POPUP_MENU_PRE_POPUP
	.enter

	; Not calling super as this message isn't handled in the superclass
	or	ds:[di].NDSVPM_sortViewFlags, mask NDSVPMF_POPPING_UP

	.leave
	ret
NDSortViewPopupPrePopup	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPopupVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the flag that the menu is popping up

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= NDSortViewPopupMenuClass object
		ds:di	= NDSortViewPopupMenuClass instance data
		ds:bx	= NDSortViewPopupMenuClass object (same as *ds:si)
		es 	= segment of NDSortViewPopupMenuClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	3/18/02   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDSortViewPopupVisClose	method dynamic NDSortViewPopupMenuClass, 
					MSG_VIS_CLOSE
	.enter

	and	ds:[di].NDSVPM_sortViewFlags, not mask NDSVPMF_POPPING_UP
	mov	di, offset NDSortViewPopupMenuClass
	call	ObjCallSuperNoLock

	.leave
	ret
NDSortViewPopupVisClose	endm

NDFolderCode ends
