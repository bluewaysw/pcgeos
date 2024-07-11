COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Gadget Library
FILE:		gadgetdlog.asm

AUTHOR:		David Loftesness, Sep 22, 1994

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_ENT_VIS_SHOW	Special handling for ENT_VIS_HIDE and
				ENT_VIS_SHOW.

    MTD MSG_ENT_VIS_HIDE	Special handling for ENT_VIS_HIDE and
				ENT_VIS_SHOW.

    MTD MSG_GADGET_DIALOG_BUILD_FOCUS_PATH_IN_ENT_VIS_SHOW,
	MSG_GADGET_DIALOG_REMEMBER_FOCUS_IN_ENT_VIS_HIDE
				Build a focus path from ourself down to the
				component specified in .focus.

    MTD MSG_ENT_INITIALIZE	Set up our instance data

    MTD MSG_ENT_GET_CLASS	return "dialog"

    MTD MSG_GEN_INTERACTION_INITIATE
				

    MTD MSG_GEN_GUP_INTERACTION_COMMAND
				raise the aboutToClose event, if we're
				being dismissed.

    MTD MSG_GADGET_SET_LEFT,
	MSG_GADGET_SET_TOP	

    MTD MSG_GADGET_SET_WIDTH,
	MSG_GADGET_SET_HEIGHT	

    MTD MSG_GADGET_GET_LEFT,
	MSG_GADGET_GET_TOP	

    MTD MSG_GADGET_SET_LOOK	do some extra work when setting looks

    MTD MSG_GADGET_DIALOG_BRING_TO_FRONT
				Bring the dialog to the front, if it's
				already on screen

    MTD MSG_META_MUP_ALTER_FTVMC_EXCL
				Allow ourself to gain the focus only if our
				GDI_dialogType permits it.  (GDT_TOOL_BOX
				and GDT_ON_TOP dialogs are not allowed to
				grab the focus.)
				
				Also, don't allow a GDT_POPUP to gain the
				target.

 ?? INT GadgetDialogCheckIfNotTargetable
				If we're a POPUP, ON_TOP or TOOL_BOX, then
				we're not targetable.

    MTD MSG_GADGET_DIALOG_RELEASE_FOCUS_EXCL_IF_POPUP
				GadgetDialogMetaMupAlterFtvmcExcl sends out
				a classed RELEASE_FOCUS_EXCL_IF_POPUP to
				focus to make any popped-up popups come
				down when an on-top or tool-box is clicked
				on.

    MTD MSG_META_GAINED_SYS_FOCUS_EXCL,
	MSG_META_LOST_SYS_FOCUS_EXCL
				Handle gain/loss of the system focus.

 ?? INT DisappearIfPopupAndLostFocus
				If we are a popup that has lost the focus,
				we should come down.  Note: If this is
				called, then we've lost the focus.  Just
				check if we're a popup.

    MTD MSG_GADGET_DIALOG_GET_TYPE
				Get the type data out of GDI_dialogType

    MTD MSG_GADGET_DIALOG_GET_TYPE_INTERNAL
				Internal handler for getting
				GDI_dialogType.

    MTD MSG_GADGET_DIALOG_SET_TYPE
				Set our type data (in GDI_dialogType).

 ?? INT GadgetDialogUpdateForTypeChange
				Change dialog's attrs and redraw.

 ?? INT GadgetDialogChangeModality
				Changes the dialog's modality if necessary.
				Modal and sys-modal dialogs need to be made
				GIA_MODAL/GIA_SYS_MODAL.

 ?? INT GadgetDialogChangeWinPriority
				Change the dialog's window priority.

 ?? INT GadgetDialogChangeWinPriorityLow
				Change a window's priority.

    MTD MSG_GADGET_DIALOG_GET_FOCUS
				Get the focus component out of GDI_focus.
				The dialog tries to make this component the
				system focus when it (the dialog) is
				active.

    MTD MSG_GADGET_DIALOG_SET_FOCUS
				Set the form's focus component, GDI_focus.
				The dialog will try to make this component
				the system focus when it (the dialog) is
				active.

 ?? INT GadgetDialogCheckIfNotFocusable
				Check if the passed dialog is GDT_ON_TOP or
				GDT_TOOL_BOX, in which case it is not
				focusable.

    MTD MSG_ENT_SET_PARENT	Only allow "app" to be the parent of a
				dialog.

    MTD MSG_META_TEST_WIN_INTERACTIBILITY
				GDT_ON_TOPs are *always* interactable.
				More to the point, they're interactable
				even if a modal window is up.

    MTD MSG_ENT_VIS_SET_ENABLED	If we're in the focus path and we're being
				disabled, change the focus to be ourself
				(and not one of our children).

    MTD MSG_META_RAW_UNIV_LEAVE	propogate leave messages to all ent
				children

    MTD MSG_VIS_COMP_GET_MARGINS
				Tell the ui the we have margins of 0. This
				code should be in the SPUI, but it is
				easier to only put on legos components
				here.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/22/94   	Initial revision


DESCRIPTION:
	Most of work in this file is for dealing with window
	priorties, dialog types and focus issues. <none of which I
	know about>

	There are also a couple of geometry and sizing issues.  There
	are taken care with common routines that forms must use too.
	The main problem is that they put children in gadget area and
	we need to turn off geometry in the gadget area, but not
	outside the gadget area.  We also need to make sure that
	sizing sticks, if you size a window with the mouse, it needs
	affect the property.  PCV doesn't allow sizing.


	Lastly, it should be remebered that floaters are a subclass of
	dialogs.  Changes you make here will be reflected there.  You
	may also wonder why we have forms, dialogs, and floaters
	(especially in pcv where forms are plain.)  There is no good
	answer for this.

	$Id: gdgdlog.asm,v 1.1 98/03/11 04:30:06 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; I've found no way to get GDT_SYS_MODAL dialogs to behave sys-modally *and*
; to stay in their property order (below GDT_ON_TOP).  This problem is
; logged as bug 51262.  As of milestone 6S, proper order is more important
; than sys-modality.  So I'm introducing the following constant to get the
; order right.  Set this constant FALSE if you want GDT_SYS_MODAL dialogs
; to behave sys-modally but out of order.
;
_SYS_MODALS_BEHAVE_LIKE_MODALS = TRUE

; needed for hack in the focus change for popups
include Legos/Internal/progtask.def

idata	segment
	GadgetDialogClass
idata	ends

makeActionEntry dialog, BringToFront, MSG_GADGET_DIALOG_BRING_TO_FRONT, LT_TYPE_UNKNOWN, 0

compMkActTable	dialog, BringToFront
MakeActionRoutines Dialog, dialog

makePropEntry dialog, focus, LT_TYPE_COMPONENT, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DIALOG_GET_FOCUS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DIALOG_SET_FOCUS>

makePropEntry dialog, type, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DIALOG_GET_TYPE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_DIALOG_SET_TYPE>

makeUndefinedPropEntry dialog, graphic

compMkPropTable Dialog, dialog, focus, type, graphic
MakePropRoutines Dialog, dialog


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDEntShow, GDEntHide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special handling for ENT_VIS_HIDE and ENT_VIS_SHOW.

CALLED BY:	MSG_ENT_VIS_SHOW, MSG_ENT_VIS_HIDE
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/21/95   	Initial version
	jmagasin 1/15/96	Make GDI_focus our focus when become visible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDEntVisShow	method dynamic GadgetDialogClass, 
					MSG_ENT_VIS_SHOW
		uses	ax, cx, dx, bp
		.enter

		push	ds:LMBH_handle, si
		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock
		pop	bx, si
		
		call	MemDerefDS
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
	;
	; Need to make our focus the object specified in our
	; .focus instance data.
	;
		mov	ax, MSG_GADGET_DIALOG_BUILD_FOCUS_PATH_IN_ENT_VIS_SHOW
		call	ObjCallInstanceNoLock

		.leave
		ret
GDEntVisShow	endm

GDEntVisHide	method dynamic GadgetDialogClass,
						MSG_ENT_VIS_HIDE
		.enter
	;
	; Generate an "aboutToClose" event if VA_REALIZED
	; and don't have hint saying not to raise event.
	;
		call	GadgetUtilRaiseCloseEventIfNecessary
		jz	callSuper			; Not realized.
	;
	; Remember our .focus object for when we come back up.
	; (GadgetUtilGetFocusCommon will set our .focus inst data.)
	;
		push	cx,dx
		mov	ax, MSG_GADGET_DIALOG_REMEMBER_FOCUS_IN_ENT_VIS_HIDE
		call	ObjCallInstanceNoLock
		pop	cx,dx
	;
	; Call superclass.
	;
callSuper:
		;push	ds:LMBH_handle, si		not necessary...
		mov	ax, MSG_ENT_VIS_HIDE
		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock
		;pop	bx, si				..no code below

	;
	; dl 9/5/95 -- don't send GUP if we're not usable (hides our parent
	; object!)
	;
	; dl 9/25/95 -- removed completely.  We'll never be usable after
	; calling the superclass... why was this code needed originally?
	;
if 0
		mov	ax, MSG_GEN_GET_USABLE
		call	ObjCallInstanceNoLock
		jnc	done
		
		call	MemDerefDS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjCallInstanceNoLock
done:
endif
		.leave
		ret
GDEntVisHide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogBuildFocusPathInEntVisShow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a focus path from ourself down to the
		component specified in .focus.

CALLED BY:	MSG_GADGET_DIALOG_BUILD_FOCUS_PATH_IN_ENT_VIS_SHOW
		MSG_GADGET_DIALOG_REMEMBER_FOCUS_IN_ENT_VIS_HIDE
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	cx, dx (for HIDE)
SIDE EFFECTS:
		We have this method becuase BGadgetDialogClass needs
		to intercept it and do *nothing*.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogBuildFocusPathInEntVisShow	method dynamic GadgetDialogClass, 
			MSG_GADGET_DIALOG_BUILD_FOCUS_PATH_IN_ENT_VIS_SHOW,
			MSG_GADGET_DIALOG_REMEMBER_FOCUS_IN_ENT_VIS_HIDE
	;
	; If we're of type GDT_TOOL_BOX or GDT_ON_TOP, then we
	; don't need to build a focus path (b/c we never get the focus).
	;
		mov_tr	bx, ax
		call	GadgetDialogCheckIfNotFocusable
		mov_tr	ax, bx
		jz	done
	;
	; Build focus path or record current focus according to message.
	;
		mov	bx, GadgetDialog_offset
		mov	di, GDI_focus
		cmp	ax, MSG_GADGET_DIALOG_REMEMBER_FOCUS_IN_ENT_VIS_HIDE
		je	remInEntHide
		call	GadgetUtilBuildFocusPathInEntVisShow
		ret
remInEntHide:
		call	GadgetUtilRememberFocusInEntVisHide
done:
		ret
GadgetDialogBuildFocusPathInEntVisShow	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up our instance data

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:
SIDE EFFECTS:	master levels built out

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogEntInitialize	method dynamic GadgetDialogClass, 
					MSG_ENT_INITIALIZE
		.enter
	;
	; Let superclass do its thing.
	;
		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock

	;
	; Our default priority is GDT_NON_MODAL, which is
	; GDT_POPUP - GDT_NON_MODAL shl 1 = WIN_PRIO_COMMAND.
	;
		mov	di, ds:[si]
		add	di, ds:[di].GadgetDialog_offset
		mov	ds:[di].GDI_dialogType, GDT_NON_MODAL
		mov	cx, size WinPriority
		mov	ax, ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY
		call	ObjVarAddData
		CheckHack	< GDT_POPUP - GDT_NON_MODAL eq 5 >
		mov	{byte} ds:[bx], WIN_PRIO_COMMAND

	;
	; Take care of our Gen instance data.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].GII_type, GIT_ORGANIZATIONAL
		mov	ds:[di].GII_visibility, GIV_DIALOG
		mov	ds:[di].GII_attrs, mask GIA_NOT_USER_INITIATABLE

		mov	ax, ATTR_GEN_WINDOW_ACCEPT_INK_EVEN_IF_NOT_FOCUSED
		clr	cx
		call	ObjVarAddData

		mov	ax, HINT_PRESERVE_FOCUS
		call	ObjVarAddData
	;
	; try setting the things targetable so text objects under
	; dialogs will send out notification of selection changed to
	; the clipboard component
	; Caveat: GDT_POPUPs will not grab the target.  If they could,
	; then we wouldn't be able to implement cut/copy/paste dialogs
	; because. -jmagasin 4/24
	;
		mov	ax, MSG_GEN_SET_ATTRS
		mov	cl, mask GA_TARGETABLE
		clr	ch
		call	ObjCallInstanceNoLock
		.leave
		ret
GadgetDialogEntInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	you know

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		cx:dx	= superclass to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeResolveSuperClassRoutine Dialog, GenInteraction



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return "dialog"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		cx:dx	= fptr.char

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogGetClass	method dynamic GadgetDialogClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetDialogString
		mov	dx, offset GadgetDialogString
		ret
GadgetDialogGetClass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDGenInitiateInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/29/95   	Initial version
	jmagasin 3/18/96	Changed to use utility routine.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDGenInteractionInitiate	method dynamic GadgetDialogClass, 
					MSG_GEN_INTERACTION_INITIATE
		.enter

		call	GadgetUtilRaiseOpenEventIfNecessary

		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock

		.leave
		ret
GDGenInteractionInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDGenGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	raise the aboutToClose event, if we're being dismissed.

CALLED BY:	MSG_GEN_GUP_INTERACTION_COMMAND
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDGenGupInteractionCommand	method dynamic GadgetDialogClass, 
					MSG_GEN_GUP_INTERACTION_COMMAND
		.enter

		cmp	cx, IC_DISMISS
		jne	callSuper

		call	GadgetUtilRaiseCloseEventIfNecessary
callSuper:
		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock
		
		.leave
		ret
GDGenGupInteractionCommand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogSetLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_SET_LEFT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogSetLeft	method dynamic GadgetDialogClass, 
					MSG_GADGET_SET_LEFT,
					MSG_GADGET_SET_TOP
				
		uses	bp
		.enter
		call	GadgetWindowSetLeftTop
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetDialogSetLeft	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogSetWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_SET_WIDTH
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogSetWidth	method dynamic GadgetDialogClass, 
					MSG_GADGET_SET_WIDTH,
					MSG_GADGET_SET_HEIGHT
				
	uses	bp
	.enter

		call	GadgetWindowSetWidthHeight
		
		
	.leave
	Destroy	ax, cx, dx
	ret
GadgetDialogSetWidth	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogGetLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GET_LEFT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogGetLeft	method dynamic GadgetDialogClass, 
					MSG_GADGET_GET_LEFT,
					MSG_GADGET_GET_TOP
		uses	bp
		.enter
		call	GadgetWindowGetLeftTop

		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetDialogGetLeft	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDGadgetSetLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do some extra work when setting looks

CALLED BY:	MSG_GADGET_SET_LOOK
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
  Actually, we don't want the title bar, ever.  dl 3/15/96

GDGadgetSetLook	method dynamic GadgetDialogClass, 
					MSG_GADGET_SET_LOOK
		uses	ax, cx, dx, bp
		.enter
		
		mov	di, offset GadgetDialogClass
		push	ds:[LMBH_handle]
		call	ObjCallSuperNoLock
		pop	bx
		call	MemDerefDS
		mov	di, ds:[si]
		add	di, ds:[di].GadgetDialog_offset
		mov	cl, ds:[di].GI_look
		tst	cl
		clr	ch
		mov	ax, HINT_WINDOW_NO_TITLE_BAR
		jcxz	addTitleBar
		clr	cx
		call	ObjVarAddData
done:
		.leave
		ret
addTitleBar:
		call	ObjVarDeleteData
		jmp	done
GDGadgetSetLook	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDGadgetDialogBringToFront
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the dialog to the front, if it's already on screen

CALLED BY:	MSG_GADGET_DIALOG_BRING_TO_FRONT
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDGadgetDialogBringToFront	method dynamic GadgetDialogClass, 
					MSG_GADGET_DIALOG_BRING_TO_FRONT
		.enter

		mov	ax, MSG_GEN_GET_USABLE
		call	ObjCallInstanceNoLock
		jnc	done

		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
GDGadgetDialogBringToFront	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogMetaMupAlterFtvmcExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow ourself to gain the focus only if our
		GDI_dialogType permits it.  (GDT_TOOL_BOX and
		GDT_ON_TOP dialogs are not allowed to grab the focus.)

		Also, don't allow a GDT_POPUP to gain the target.

CALLED BY:	MSG_META_MUP_ALTER_FTVMC_EXCL
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		GDT_POPUPs may not grab the target.  If they did, then
		we couldn't implement a cut/copy/paste dialog -- the
		target would leave the thing we were trying to do
		cut/copy/paste with.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogMetaMupAlterFtvmcExcl	method dynamic GadgetDialogClass, 
					MSG_META_MUP_ALTER_FTVMC_EXCL
		.enter
	;
	; If this is a target grab and we're a GDT_POPUP,
	; GDT_TOOL_BOX, or GDT_ON_TOP, bail.
	;
		test	bp, mask MAEF_TARGET
		jz	checkForFocusChange
		test	bp, mask MAEF_GRAB
		jz	checkForFocusChange
		call	GadgetDialogCheckIfNotTargetable
		jnc	checkForFocusChange
		
		and	bp, not (mask MAEF_TARGET)
		test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
		jz	done
	;
	; If this is not focus related, or if this is a release
	; (of the focus or anything else) call superclass.
	;
checkForFocusChange:
		test	bp, mask MAEF_FOCUS
		jz	callSuperClass
		test	bp, mask MAEF_GRAB
		jz	callSuperClass		; some kind of release
	;
	; This is a focus grab so check if we're of type
	; GDT_TOOL_BOX or ON_TOP.  If so, don't grab the focus.
	;
		call	GadgetDialogCheckIfNotFocusable
		jz	dontGrabFocus

callSuperClass:
		mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
		Assert	objectPtr dssi, GadgetDialogClass
		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret

dontGrabFocus:
		and	bp, not (mask MAEF_FOCUS)
		test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
		jnz	callSuperClass
		jmp	done
GadgetDialogMetaMupAlterFtvmcExcl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogMetaQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a POPUP dialog comes down if some other
		dialog receives a pen press.

CALLED BY:	MSG_META_QUERY_IF_PRESS_IS_INK
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		whatever superclass returns
DESTROYED:	whatever superclass destroys
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	A popup will come down when it loses the focus.  But tool box
	and on-top windows don't grab the focus, so they need special
	handling.
	
	MSG_META_MUP_ALTER_FTVMC_EXCL used to ensure that a popup
	comes down when the user clicks in some non-focusable window,
	such as a toolbox or on-top.  But sometimes these nonfocusables
	don't receive META_MUP_ALTER_..., so the popup doesn't come down.
	Hence now we tell the popup here. (fixes bug 58091)

	We could also intercept MSG_META_START_SELECT, but GadgetDialog
	Class already intercepts this in GadgetOLMetaStartSelect.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 9/11/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogMetaQueryIfPressIsInk method dynamic GadgetDialogClass, 
					MSG_META_QUERY_IF_PRESS_IS_INK
		.enter
	;
	; If we're a nonfocusable dialog (on-top or toolbox), then
	; we need to tell the popup to come down.  We tell it b/c
	; it won't lose the focus -- the usual way it knows to come
	; down.
	;
		call	GadgetDialogCheckIfNotFocusable
		jnz	callSuper
	;
	; Tell the popup (if any) to scat!
	;
		push	cx,dx,si
		mov	ax, MSG_GADGET_DIALOG_RELEASE_FOCUS_EXCL_IF_POPUP
		mov	bx, segment GadgetDialogClass
		mov	si, offset GadgetDialogClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_FOCUS
		call	UserCallApplication
		pop	cx,dx,si

callSuper:
		mov	ax, MSG_META_QUERY_IF_PRESS_IS_INK
		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock

		.leave
		ret
GadgetDialogMetaQueryIfPressIsInk endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogCheckIfNotTargetable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're a POPUP, ON_TOP or TOOL_BOX, then we're
		not targetable.

CALLED BY:	GadgetDialogMetaMupAlterFtvmcExcl only
PASS:		ds:di		- instance data of a GadgetDialog
RETURN:		carry flag	- set if we're *not* targetable
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogCheckIfNotTargetable	proc	near
		.enter
.warn -private
		cmp	ds:[di].GDI_dialogType, GDT_TOOL_BOX
		je	notTargetable
		cmp	ds:[di].GDI_dialogType, GDT_ON_TOP
		je	notTargetable
		cmp	ds:[di].GDI_dialogType, GDT_POPUP
		je	notTargetable
		clc
.warn @private
done:		
		.leave
		ret
notTargetable:
		stc
		jmp	done
GadgetDialogCheckIfNotTargetable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogReleaseFocusExclIfPopup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GadgetDialogMetaMupAlterFtvmcExcl sends out a classed
		RELEASE_FOCUS_EXCL_IF_POPUP to focus to make any popped-up
		popups come down when an on-top or tool-box is clicked
		on.

CALLED BY:	MSG_GADGET_DIALOG_RELEASE_FOCUS_EXCL_IF_POPUP
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		We don't just intercept MSG_META_RELEASE_FOCUS_EXCL
		because a dialog might receive the meta message for
		some reason other than a tool-box/on-top telling it to
		come down. (see above GadgetDialogMetaMupAlterFtvmcExcl
		above).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogReleaseFocusExclIfPopup	method dynamic GadgetDialogClass, 
				MSG_GADGET_DIALOG_RELEASE_FOCUS_EXCL_IF_POPUP
		.enter

		cmp	ds:[di].GDI_dialogType, GDT_POPUP
		jne	done			; Ignore msg if not popup.
		mov	ax, MSG_META_RELEASE_FOCUS_EXCL
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
GadgetDialogReleaseFocusExclIfPopup	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogGainedLostSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle gain/loss of the system focus.

CALLED BY:	MSG_META_GAINED_SYS_FOCUS_EXCL
		MSG_META_LOST_SYS_FOCUS_EXCL
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
		^lcx:dx	= object wishing to grab the exclusive
			  (Empirically determined.)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogGainedLostSysFocusExcl	method dynamic GadgetDialogClass, 
					MSG_META_GAINED_SYS_FOCUS_EXCL,
					MSG_META_LOST_SYS_FOCUS_EXCL
		.enter
	;
	; Call superclass.
	;
		push	di			; Save inst data addr.
		mov	bx, ax			; Save message.
		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock
		pop	di
	;
	; Did we gain or lose the focus?
	;
		cmp	bx, MSG_META_LOST_SYS_FOCUS_EXCL
		je	checkPopup
	;
	; We gained the focus.  Clear pen grab if we're a modal
	; dialog.
	;
		CheckHack < GDT_MODAL eq GDT_SYS_MODAL - 1 >
		CheckHack < GDT_POPUP eq GDT_SYS_MODAL + 2 >
		mov	al, {byte}ds:[di].GDI_dialogType
		cmp	al, GDT_MODAL
		jl	comeToFront		; Can't be a popup.
		cmp	al, GDT_SYS_MODAL
		jg	comeToFront
		call	VisForceGrabMouse	; Steal the grab.
		call	VisReleaseMouse		; We don't need it.
	;
	; Come to front if gained focus.  If user pressed on us,
	; then we're already at the front.  But if code set ui.focus
	; to us, then we might not be at the front.
	;
comeToFront:
		mov	ax, MSG_GADGET_DIALOG_BRING_TO_FRONT
		call	ObjCallInstanceNoLock
		jmp	done
	;
	; We lost the focus.  If we're a popup dialog, disappear.
	;
checkPopup:
		call	DisappearIfPopupAndLostFocus

done:
		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetDialogGainedLostSysFocusExcl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisappearIfPopupAndLostFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we are a popup that has lost the focus, we should
		come down.  Note: If this is called, then we've
		lost the focus.  Just check if we're a popup.

CALLED BY:	GadgetDialogGainedLostFocusExcl
PASS:		*ds:si	- GadgetDialog object
		ds:di	- GadgetDialog instance data
RETURN:		nothing
DESTROYED:	ax, di, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisappearIfPopupAndLostFocus	proc	near
		.enter
.warn -private
		Assert	objectPtr dssi, GadgetDialogClass
	;
	; Are we a popup that's lost the focus?
	;
		cmp	ds:[di].GDI_dialogType, GDT_POPUP
		jne	done
	;
	; If we've already been marked as not visible, then don't
	; bother sending ourself an ENT_VIS_HIDE.
	;
		mov	ax, MSG_ENT_GET_FLAGS
		call	ObjCallInstanceNoLock
		test	al, mask EF_VISIBLE
		jz	done
	;
	; Yes, so come down.  Use queue to delay.
	;
	; if we have hit a RunTimeError than we don't want to do this
	; due to problems with the RunTime error dialog sending this
	; message through thus causing the Dialog's window to be freed
	; which causes problems because we might have be called through
	; VisSendMouseDataToGrab which saves the Window handle - sigh
		push	si, es
		movdw	bxsi, ds:EOBH_interpreter
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_INTERP_GET_STATE
		call	ObjMessage
	; ax = ptask
		mov	bx, ax
		call	MemLock
		mov	es, ax
		tst	es:PT_err
		call	MemUnlock
		pop	si, es
		jnz	done
		
		mov	ax, MSG_ENT_VIS_HIDE
		mov	bx, ds:LMBH_handle
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
.warn @private
		.leave
		ret
DisappearIfPopupAndLostFocus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogGetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the type data out of GDI_dialogType

CALLED BY:	MSG_GADGET_DIALOG_GET_TYPE
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		filled in GetPropertyArgs' *GPA_compDataPtr
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogGetType	method dynamic GadgetDialogClass,
					MSG_GADGET_DIALOG_GET_TYPE

		.enter

		les	bx, ss:[bp].GPA_compDataPtr
		Assert	fptr, esbx
		clr	ah
		mov	al, {byte}ds:[di].GDI_dialogType
		Assert	urange al, GDT_NON_MODAL, GDT_POPUP
		mov	es:[bx].CD_data.LD_integer, ax
		mov	es:[bx].CD_type, LT_TYPE_INTEGER

		.leave
		Destroy	ax, cx, dx
		ret

GadgetDialogGetType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogGadgetDialogGetTypeInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal handler for getting GDI_dialogType.

CALLED BY:	MSG_GADGET_DIALOG_GET_TYPE_INTERNAL
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		al	= GDI_dialogType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/10/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogGadgetDialogGetTypeInternal	method dynamic GadgetDialogClass, 
					MSG_GADGET_DIALOG_GET_TYPE_INTERNAL
		.enter

		mov	al, {byte}ds:[di].GDI_dialogType
		
		.leave
		ret
GadgetDialogGadgetDialogGetTypeInternal	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogSetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our type data (in GDI_dialogType).

CALLED BY:	MSG_GADGET_DIALOG_SET_TYPE
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		filled in SetPropertyArgs' *SPA_compDataPtr 
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogSetType	method dynamic GadgetDialogClass, 
					MSG_GADGET_DIALOG_SET_TYPE

		.enter
	;
	; Set our priority if it's a legal value, and if it's different
	; than our current value.
	;
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr, esbx

		cmp	es:[bx].CD_type, LT_TYPE_INTEGER
		jne	wrongType
		
		mov	al, {byte}es:[bx].CD_data.LD_integer
		cmp	al, GDT_NON_MODAL
		jl	typeOutOfRange
		cmp	al, GDT_POPUP
		jg	typeOutOfRange
		
		Assert	urange al, GDT_NON_MODAL, GDT_POPUP
		cmp	{byte}ds:[di].GDI_dialogType, al
		je	done
	;
	; Change the dialog's attrs and redraw.
	;
		call	GadgetDialogUpdateForTypeChange
		jc	specificError			; Dialog was visible.
		mov	{byte}ds:[di].GDI_dialogType, al
		
done:
		.leave
		Destroy	ax, cx, dx
		ret
	;
	; Error-handling.
	;
specificError:
		mov	es:[bx].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	returnError
wrongType:
		mov	es:[bx].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	returnError
typeOutOfRange:
		mov	es:[bx].CD_data.LD_error, CPE_PROPERTY_SIZE_MISMATCH
returnError:
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		jmp	done
GadgetDialogSetType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogUpdateForTypeChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change dialog's attrs and redraw.

CALLED BY:	GadgetDialogSetType
PASS:		*ds:si	- dialog
		ds:di	- dialog's instance data
		al	- Legos GadgetDialogType
RETURN:		carry	- set if error
DESTROYED:	cx,dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogUpdateForTypeChange	proc	near
		uses	bp, bx, di, ax
		.enter
		Assert	objectPtr dssi, GadgetDialogClass
	;
	; Are we usable?
	;
		mov_tr	bl, al
		mov	ax, MSG_GEN_GET_USABLE
		call	ObjCallInstanceNoLock
		jc	done				; Error!
		mov_tr	al, bl

	;
	; Change modality if necessary.
	;
		call	GadgetDialogChangeModality
	;
	; Change window priority.
	;
		call	GadgetDialogChangeWinPriority

		clc					; No error.
done:
		.leave
		ret
GadgetDialogUpdateForTypeChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogChangeModality
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes the dialog's modality if necessary.  Modal and
		sys-modal dialogs need to be made GIA_MODAL/GIA_SYS_MODAL.

CALLED BY:	GadgetDialogUpdateForTypeChange only
PASS:		*ds:si	- dialog object
		al	- GadgetDialogType
RETURN:		nothing
DESTROYED:	cx,dx,bp,bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/21/95    	Initial version
	jmagasin 4/22/96	Added _SYS_MODALS_BEHAVE_LIKE_MODALS
				conditional code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogChangeModality	proc	near
	uses	ax
		.enter
	;
	; Get current attrs.
	;
		mov_tr	bl, al				; Save new type.
		mov	ax, MSG_GEN_INTERACTION_GET_ATTRS
		call	ObjCallInstanceNoLock		; cl <- attrs
		mov	ch, cl
	;
	; Figure out desired attrs.
	;
		or	ch, mask GIA_MODAL
		cmp	bl, GDT_MODAL
		je	checkOriginal			; Want modal
		mov	ch, cl
ifdef _SYS_MODALS_BEHAVE_LIKE_MODALS
		or	ch, mask GIA_MODAL
else
		or	ch, mask GIA_SYS_MODAL
endif
		cmp	bl, GDT_SYS_MODAL
		je	checkOriginal			; Want sys modal
		and	ch, not (mask GIA_MODAL or mask GIA_SYS_MODAL)
checkOriginal:
	;
	; At this point ch has the desired attrs, so compare with cl,
	; the current attrs.  If not same, mask out all but attrs to
	; clear from cl.  Then switch ch/cl to set up for call to
	; SET_ATTRS.
	;
		cmp	ch, cl
		je	done				; No change req'd.
ifdef _SYS_MODALS_BEHAVE_LIKE_MODALS
		and	cl, mask GIA_MODAL
else
		and	cl, mask GIA_MODAL or mask GIA_SYS_MODAL
endif
		xchg	cl, ch
	;
	; Change dialog attrs.
	;
		mov	ax, MSG_GEN_INTERACTION_SET_ATTRS
		call	ObjCallInstanceNoLock

done:
		.leave
		Destroy	cx, dx, bp
		ret
GadgetDialogChangeModality	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogChangeWinPriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the dialog's window priority.

CALLED BY:	GadgetDialogUpdateForTypeChange only
PASS:		*ds:si	- dialog
		al	- Legos GadgetDialogType

RETURN:		nothing
DESTROYED:	cx,dx,di,bx,ax
SIDE EFFECTS:
		FIXME: System modals don't behave sys-modally with
		ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY on them, so
		we get rid of the attr.  But this messes up the
		desired window hierarchy -- sys-modals jump above
		on-tops and popups.  Not sure of how to fix this.
		Maybe there's some way to get sys modal behavior
		with the attr.  Or maybe all an apps windows should
		be moved up to LAYER_PRIO_MODAL.

		Hey, here's a solution! Let sys-modals have the priority
		attr.  Make them behave sys-modally by handling
		MSG_META_TEST_WIN_INTERACTIBILITY. FIXME: won't work
		because sys-modals with attr won't even receive the
		TEST msg.  Could make them modal, but they still won't
		receive the test msg for windows not part of the application.

		Okay, I tried moving all windows type GDT_SYS_MODAL or
		higher to LAYER_PRIO_MODAL.  This allowed the window
		system to find GDT_SYS_MODALs (before, they weren't in
		LAYER_PRIO_MODAL so the window system couldn't find them).
		So GDT_SYS_MODALs became sys-modal.  But, they then dis-
		regarded their ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY attr
		(in fact, it seemed to get removed somewhere).  So sys-
		modals went back to the top (above GDT_ON_TOP and POPUP).


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/21/95    	Initial version
	jmagasin 4/22/96	Added _SYS_MODALS_BEHAVE_LIKE_MODALS
				conditional code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogChangeWinPriority	proc	near
		.enter
		Assert	objectPtr dssi, GadgetDialogClass

ifdef _SYS_MODALS_BEHAVE_LIKE_MODALS
	;
	; GDT_SYS_MODALS must be in WIN_PRIO_MODAL or they won't
	; be modal.
	;
		cmp	al, GDT_SYS_MODAL
		jne	convertToGeosPriority
		mov	al, GDT_MODAL
else
	;
	; If we're supposed to become system-modal, get rid
	; of our custom window attr.
	;
		cmp	al, GDT_SYS_MODAL
		jne	convertToGeosPriority
		mov	ax, ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY
		call	ObjVarDeleteData
		jmp	done
endif
	;
	; Convert Legos priority into GEOS priority.
	;
convertToGeosPriority:
		mov	dl, 1
		cmp	al, GDT_POPUP			; Don't want 0 for
		je	setPriority			; GEOS priority.
		mov	dl, GDT_POPUP
		sub	dl, al
		shl	dl, 1				; dl = GEOS prirty
	;
	; Change window priority.
	;
setPriority:
		call	GadgetDialogChangeWinPriorityLow
ifndef _SYS_MODALS_BEHAVE_LIKE_MODALS
done:
endif
		.leave
		Destroy	cx, dx, di
		ret
GadgetDialogChangeWinPriority	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogChangeWinPriorityLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change a window's priority.

CALLED BY:	GadgetDialogChangeWinPriority,
PASS:		*ds:si	- dialog object
		dl	- GEOS window priority
		
RETURN:		nothing
DESTROYED:	cx, dx, di, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogChangeWinPriorityLow	proc	near
	uses	bp
		.enter
		Assert	objectPtr dssi, GadgetDialogClass
	;
	; Set window priority.
	;
		mov	ax, ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY
		mov	cx, size WinPriority
		call	ObjVarAddData
		mov	{byte}ds:[bx], dl
	;
	; Visually update for new priority, if necessary.
	;
		push	dx				; Save priority
		mov	ax, MSG_VIS_QUERY_WINDOW
		call	ObjCallInstanceNoLock		; ^hcx = win han
		pop	ax				; - Window priority
		jcxz	done				; No window crntly.

		clr	ah
		clr	dx
		mov	di, cx
		call	WinChangePriority
done:
		.leave
		ret
GadgetDialogChangeWinPriorityLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogGetFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the focus component out of GDI_focus.  The dialog
		tries to make this component the system focus when
		it (the dialog) is active.

CALLED BY:	MSG_GADGET_DIALOG_GET_FOCUS
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		filled in GetPropertyArgs' GPA_compDataPtr
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogGetFocus	method dynamic GadgetDialogClass, 
					MSG_GADGET_DIALOG_GET_FOCUS
		.enter
	;
	; If we're GDT_TOOL_BOX or GDT_ON_TOP, don't bother to
	; set the focus property.
	;
		call	GadgetDialogCheckIfNotFocusable
		jz	notFocusable
	;
	; We're focusable.
	;
		mov	di, GadgetDialog_offset
		mov	ax, offset GDI_focus
		call	GadgetUtilGetFocusCommon
done:
		.leave
		Destroy	ax, cx, dx
		ret

notFocusable:
		les	bx, ss:[bp].GPA_compDataPtr
		Assert	fptr, esbx
		clrdw	es:[bx].CD_data.LD_comp
		mov	es:[bx].CD_type, LT_TYPE_COMPONENT
		jmp	done

GadgetDialogGetFocus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogSetFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the form's focus component, GDI_focus.  The dialog
		will try to make this component the system focus when
		it (the dialog) is active.

CALLED BY:	MSG_GADGET_DIALOG_SET_FOCUS
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogSetFocus	method dynamic GadgetDialogClass, 
					MSG_GADGET_DIALOG_SET_FOCUS
		.enter
	;
	; If we're GDT_TOOL_BOX or GDT_ON_TOP, don't bother to
	; set the focus property.
	;
		call	GadgetDialogCheckIfNotFocusable
		jz	done
	;
	; Call common code for all windows (forms, dialogs, floaters).
	;
		call	GadgetUtilSetFocusHelper
		jnc	checkIfNeedRuntimeError
	;
	; Actually set the .focus property, even if the path
	; couldn't be built due to an unfocusable gadget.
	;
		movdw	ds:[di].GDI_focus, cxdx, ax
done:
		.leave
		Destroy	ax, cx, dx
		ret
	;
	; Need runtime errors if desired focus not a descendant.
	;
checkIfNeedRuntimeError:
		jz	done			; Don't need an error.
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		call	GadgetUtilReturnSetPropError
		jmp	done

GadgetDialogSetFocus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogCheckIfNotFocusable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the passed dialog is GDT_ON_TOP or
		GDT_TOOL_BOX, in which case it is not focusable.

CALLED BY:	GadgetDialogClass utility
PASS:		ds:di	- GadgetDialogClass instance data
			  ds:[di].GDI_dialogType is the type property
RETURN:		zf	- set if this dialog is not focusable
			- clear if this dialog is focusable
DESTROYED:	al
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogCheckIfNotFocusable	proc	near
		.enter
.warn -private
		mov	al, {byte}ds:[di].GDI_dialogType
		cmp	al, GDT_ON_TOP
		je	done
		cmp	al, GDT_TOOL_BOX
.warn @private
done:
		.leave
		ret
GadgetDialogCheckIfNotFocusable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogEntSetParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Only allow "app" to be the parent of a dialog.

CALLED BY:	MSG_ENT_SET_PARENT
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
		cx:dx	= optr to parent
RETURN:		ax	= 0 if parent is "app" (only acceptable parent)
			= nonzero if non-"app" parent was requested
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/ 8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogEntSetParent	method dynamic GadgetDialogClass, 
					MSG_ENT_SET_PARENT
		.enter
	;
	; Make sure "app" is the requested parent.
	;
		mov	di, offset GadgetDialogClass
		call	GadgetUtilCheckParentIsApp
		
		.leave
		ret
GadgetDialogEntSetParent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogMetaTestWinInteractibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GDT_ON_TOPs are *always* interactable.  More to the
		point, they're interactable even if a modal window
		is up.

CALLED BY:	MSG_META_TEST_WIN_INTERACTIBILITY
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
		^lcx:dx	= input object to check
		^hbp	= window to check
RETURN:		carry	- set if ^lcx:dx in a GDT_ON_TOP
			- set if ^lcx:dx is ourself
			- clear if we are GDT_SYS_MODAL FIXME
			- superclass determines carry otherwise

DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/10/96   	Initial version
	jmagasin 4/22/96	Added _SYS_MODALS_BEHAVE_LIKE_MODALS
				conditional code.  Also, set cf if
				testing interactibility w.r.t. ourself.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogMetaTestWinInteractibility	method dynamic GadgetDialogClass, 
					MSG_META_TEST_WIN_INTERACTIBILITY
		.enter
	;
	; If we're testing interactibility with respect to ourself,
	; then just return carry set.
	;
		cmp	si, dx
		jne	afterSelfCheck
		cmp	ds:[LMBH_handle], cx
		jne	afterSelfCheck
		stc
		jmp	done
afterSelfCheck:
	;
	; Is the passed optr even a dialog?  If not, then it sure ain't
	; an ON_TOP.  Without this check, we'll happily crash as
	; MSG_GADGET_DIALOG_GET_TYPE_INTERNAL is mapped to some random
	; message belonging to the class of the passed object in ^lcx:dx.
	;
		push	cx, dx, bp, si		; Save for super, if nec.
		push	di
		movdw	bxsi, cxdx, ax
		mov	cx, segment GadgetDialogClass
		mov	dx, offset GadgetDialogClass
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		jnc	callSuper
	;
	; It's a dialog, but is it a GDT_ON_TOP?
	;
		mov	ax, MSG_GADGET_DIALOG_GET_TYPE_INTERNAL
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; al = GadgetDialogType
		cmp	al, GDT_ON_TOP
		je	interactable
	;
	; If we are a sys-modal dialog, and the dialog to check is
	; not GDT_ON_TOP (it's not, or we would've jumped), then
	; return carry=0
	; FIXME: Again, with the custom window attr, sys-modals have
	;        no modality to them at all.  So this msg won't be
	;        received.  Half-soln is to make sys-modals GIA_MODAL
	;	 but of a higher win priority than GDT_MODAL.  This
	;        will make them app modal.
	;
ifdef _SYS_MODALS_BEHAVE_LIKE_MODALS
		pop	di			; Get instance data.
		push	di
		cmp	ds:[di].GDI_dialogType, GDT_SYS_MODAL
		jne	callSuper
		add	sp, 10			; Quick pop.
		clc				; Not interactable.
		jmp	done
endif
	;
	; Passed optr not for a GDT_ON_TOP.  Let superclass
	; decide if we're interactable.
	;
callSuper:
		pop	di
		pop	cx, dx, bp, si		; Restore args for super.
		mov	ax, MSG_META_TEST_WIN_INTERACTIBILITY
		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret

interactable:
		add	sp, 10			; Quick pop.
		stc				; YES, we're interactable
		jmp	done

GadgetDialogMetaTestWinInteractibility	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're in the focus path and we're being disabled,
		change the focus to be ourself (and not one of our
		children).

CALLED BY:	MSG_ENT_VIS_SET_ENABLED
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		whatever superclass returns
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogSetEnabled	method dynamic GadgetDialogClass, 
					MSG_ENT_VIS_SET_ENABLED
		.enter
	;
	; Are we being disabled?
	;
		les	bx, ss:[bp].SPA_compDataPtr
		tst	es:[bx].CD_data.LD_integer
		jnz	callSuper			; Enable window.
	;
	; Yup, we're being disabled.
	;
		call	GadgetUtilRaiseFocusOnWindowDisable
		jnc	afterFocusChanges
		mov	bx, ds:LMBH_handle
		movdw	ds:[di].GDI_focus, bxsi, ax
afterFocusChanges:
		mov	ax, MSG_ENT_VIS_SET_ENABLED
	;
	; Call superclass.
	;
callSuper:
		mov	bx, segment GadgetDialogClass
		mov	es, bx
		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock
		
		.leave
		ret
GadgetDialogSetEnabled	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFMetaUnivLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	propogate leave messages to all ent children

CALLED BY:	MSG_META_UNIV_LEAVE
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFMetaUnivLeave	method dynamic GadgetDialogClass, 
					MSG_META_RAW_UNIV_LEAVE
		uses	ax, cx, dx, bp
		.enter
		mov	di, offset GadgetDialogClass
		call	ObjCallSuperNoLock

	; passing this to ourselves will end up propogating all the
	; way down the ent tree by the default ent handler
		mov	ax, MSG_ENT_UNIV_LEAVE
		mov	di, offset GadgetDialogClass
		call	ObjCallInstanceNoLock
		.leave
		ret
GFMetaUnivLeave	endm
		
if _PCV


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDialogVisCompGetMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the ui the we have margins of 0.
		This code should be in the SPUI, but it is easier to only
		put on legos components here.

CALLED BY:	MSG_VIS_COMP_GET_MARGINS
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		ax	- left margin
		bp	- top margin
		cx	- right margin
		dx	- bottom margin
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This may do the wrong thing if we have menus in the primary.
		Bummer.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetDialogVisCompGetMargins	method dynamic GadgetDialogClass, 
					MSG_VIS_COMP_GET_MARGINS
		.enter
		clr	ax, cx, dx, bp
		.leave
		ret
GadgetDialogVisCompGetMargins	endm


endif

