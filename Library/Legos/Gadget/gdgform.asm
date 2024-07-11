COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Gadget Library
FILE:		GdgForm.asm

AUTHOR:		David Loftesness, Jun 28, 1994

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_ENT_INITIALIZE	arrange our guts the way we wants 'em

    MTD MSG_META_RESOLVE_VARIANT_SUPERCLASS
				Inform the system of our association to
				GenPrimary.

    MTD MSG_ENT_GET_CLASS	Return "form"

    MTD MSG_ENT_VIS_SHOW	

    MTD MSG_ENT_VIS_OPEN	Forms should come to the front when set
				visible even if already visible.

    MTD MSG_ENT_VIS_HIDE	Hide the form.  Generate an "aboutToClose"
				event if necessary.  Also remember our
				current focus object for if/when we become
				visible again later.

    MTD MSG_GADGET_FORM_BUILD_FOCUS_PATH_IN_ENT_VIS_SHOW,
	MSG_GADGET_FORM_REMEMBER_FOCUS_IN_ENT_VIS_HIDE
				Build a focus path from ourself down to the
				component specified in .focus.

 ?? INT GadgetWindowGetWidthHeight
				

    MTD MSG_GADGET_SET_LEFT,
	MSG_GADGET_SET_TOP	

 ?? INT GadgetWindowSetLeftTop	

    MTD MSG_GADGET_SET_WIDTH,
	MSG_GADGET_SET_HEIGHT	

 ?? INT GadgetWindowSetWidthHeight
				

    MTD MSG_GADGET_GET_LEFT,
	MSG_GADGET_GET_TOP	

 ?? INT GadgetWindowGetLeftTop	

 ?? INT GadgetOLVisPositionBranch
				positions all the objects under the current
				object.  This is the message that is called
				by the geometry manager, and is the message
				that should be subclassed by objects that
				want to do their own child object
				positioning or do something else based on
				the move.

 ?? INT ClearGeomBitsOnForm	Clears geometry (VOF_GEOMETRY_INVALID,
				VOF_GEO_UPDATE_PATH) bits on the form and
				the OLGadgetArea.  This should be called by
				grouping objects that have OL (specific UI)
				built out objects in it whose VisOptFlags
				we need to muck with.

 ?? INT GadgetOLMetaStartSelect	When the user clicks on the margins to
				resize, set some instance data so we know
				when to resize in the end select.

 ?? INT GadgetOLMetaEndSelect	An END_SELECT is a signal that we were just
				resized or moved (in addition to having
				been selected).  If we were resized or
				moved, correctly set the size / position
				vardata so we keep the size.

    MTD MSG_VIS_UPDATE_WINDOWS_AND_IMAGE
				Subclassing this message here is a total
				hack and probably makes redrawing slower.

 ?? INT GadgetOLSpecBuildBranch	Do a spec build for GadgetGeom stuff that
				have OL stuff too.  (We need to figure out
				the right VisParent for later

 ?? INT GadgetOLVisRecalcSize	We can't let the geometry manager figure
				this out for us because it doesn't get it
				right for positioned children.

    MTD MSG_VIS_DRAW		Change the background color of the form on
				open.

    MTD MSG_ENT_SET_NAME	When the name gets set, set the moniker
				too. We have do this is GadgetForm, because
				monikers for primaries are screwy.

    MTD MSG_GADGET_FORM_GET_FOCUS
				Get the focus component out of GFI_focus.
				The form tries to make this component the
				system focus when it (the form) is active.

    MTD MSG_GADGET_FORM_SET_FOCUS
				Set the form's focus component, GFI_focus.
				The form will try to make this component
				the system focus when it (the form) is
				active.

    MTD MSG_GADGET_FORM_BRING_TO_FRONT
				Bring the form to the front, if it's
				already on screen

    MTD MSG_META_GAINED_SYS_FOCUS_EXCL
				Method for handling the gain/loss of the
				system focus.

    MTD MSG_ENT_SET_PARENT	Only allow "app" to be the parent of a
				form.

    MTD MSG_ENT_VIS_SET_ENABLED	If we're in the focus path and we're being
				disabled, change the focus to be ourself
				(and not one of our children).

    MTD MSG_META_RAW_UNIV_LEAVE	propogate leave messages to all ent
				children

    MTD MSG_GADGET_SET_LOOK	

    MTD MSG_VIS_COMP_GET_MARGINS
				Tell the ui the we have margins of 0. This
				code should be in the SPUI, but it is
				easier to only put on legos components
				here.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/28/94   	Initial revision


DESCRIPTION:
	Hmm, forms are a bit tricky.  The main problem with form is
	geometry.  In Geos, a form is GenPrimary.  This is a problem
	as a GenPrimary comes with a lot of baggage: a title bar, an
	optional menu bar, an OLGadgetArea (place for putting stuff)
	and a resize border.  A lot of work was done to disable
	geometry in the OLGadgetArea but leave it active on the form.
	It turns out that for PCV, where forms don't have titlebars,
	menubars or resize borders, much of this work is probably
	useless.

	The geometry problem is that we need to get the OLGadgetArea
	to size as needed correctly when children are custom placed.
	Reflecting back, I think it would have been better to fix the
	geometry manger than try and get around it here.  The geometry
	manager doesn't do the right thing for children that have a
	custom position.  It doesn't know how to size the composite
	holding the children.  The spui won't easily give us the
	OLGadgetArea.   We can figure out how big it is supposed to
	be, but getting it size correctly at the right time is tricky.

	Primaries can only have text monikers and inherit the moniker
	from the app if none is given.  This causes a problem as the
	user doesn't expect it, and the long moniker of the app can
	inhibit the size of the primary (it tries to be as big as the
	moniker).  But since the pcv has no titlebars on forms, the

	Please don't hunt me down for naming some functions like
	GadgetOLXXX. These are generally functions that are common to
	forms and dialogs and that would not be needed in world with a
	better spui.  They aren't really related to the component api,
	but with the objects interface with the spui and I wanted to
	differentiate them somehow. (At one point I created a class
	between GenPrimary and Ent...)
	
		
	$Id: gdgform.asm,v 1.1 98/03/11 04:30:18 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	GadgetFormClass
idata	ends

makeActionEntry form, BringToFront, MSG_GADGET_FORM_BRING_TO_FRONT, LT_TYPE_UNKNOWN, 0

compMkActTable	form, BringToFront
MakeActionRoutines Form, form

makePropEntry form, focus, LT_TYPE_COMPONENT,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_FORM_GET_FOCUS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_FORM_SET_FOCUS>

makeUndefinedPropEntry form, graphic

compMkPropTable Form, form, focus, graphic
MakePropRoutines Form, form


; these are used to get at the gadgetarea.

;include internal\specui\olctrlcl.def
;include internal\specui\olwincla.def
;include	internal\specui\olmenued.def


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	arrange our guts the way we wants 'em

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormEntInitialize	method dynamic GadgetFormClass, 
					MSG_ENT_INITIALIZE
	.enter

	;
	; Tell superclass to do its thing
	;
		mov	di, offset GadgetFormClass
		call	ObjCallSuperNoLock
	;
	; Set the moniker to "NewBASIC", so it doesn't inherit it from the
	; app.  HINT_DO_NOT_USE_MONIKER does not seem to work.
	; nor does, HINT_CAN_CLIP_MONIKER_WIDTH
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	cx, cs
		mov	dx, offset newMoniker
		mov	bp, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
	;
	; And do some other fun stuff to the primary
	;
	; We remove the file menu because it wouldn't be a BASIC
	; component, and we couldn't add our components to it.
	;
		clr	cx
		mov	ax, HINT_PRIMARY_NO_FILE_MENU
		call	ObjVarAddData
		
	;
	; need to set this on all forms, as trying to do in during the
	; EntInitialize on "the right form/dialog/window" for the ink
	; did not work so well.
	;
		mov	ax, ATTR_GEN_WINDOW_ACCEPT_INK_EVEN_IF_NOT_FOCUSED
		clr	cx
		call	ObjVarAddData
		
	.leave
	ret
GadgetFormEntInitialize	endm
newMoniker TCHAR "NewBASIC",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association to GenPrimary.

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		cx:dx	= superclass to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
 	----	----		-----------
	dloft	6/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormMetaResolveVariantSuperclass	method dynamic GadgetFormClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

		compResolveSuperclass	GadgetForm, GenPrimary
		
GadgetFormMetaResolveVariantSuperclass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return "form"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		cx:dx	= form
DESTROYED:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormGetClass	method dynamic GadgetFormClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetFormString
		mov	dx, offset GadgetFormString
		ret
GadgetFormGetClass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFEntVisShow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_VIS_SHOW
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
	dloft	9/23/95		Shuffled event/callsuper order, slimmed down
				stack usage.
	jmagasin 3/18/96	Call utility routine to raise aboutToOpen.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFEntVisShow	method dynamic GadgetFormClass, 
					MSG_ENT_VIS_SHOW
		uses	ax, cx, dx, bp
		.enter

	;
	; Call superclass.
	;
		mov	ax, MSG_ENT_VIS_SHOW
		mov	di, offset GadgetFormClass
		call	ObjCallSuperNoLock
	;
	; Need to make our focus the object specified in our
	; instance data.
	;
		mov	ax, MSG_GADGET_FORM_BUILD_FOCUS_PATH_IN_ENT_VIS_SHOW
		call	ObjCallInstanceNoLock
	;
	; Also need to come to the top, even if we were already
	; visible.
	;
		mov	ax, MSG_GADGET_FORM_BRING_TO_FRONT
		call	ObjCallInstanceNoLock

		.leave
		ret
GFEntVisShow	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure to bring to front after we are visible if we
		just recieve an ENT_VIS_SHOW.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This code is here to deal with the fact that forms do not yet have a
	window immediately after they are set visible (due to the use of
	VUM_DELAYED_...).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	4/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormVisOpen method dynamic GadgetFormClass, MSG_VIS_OPEN
		.enter

	;
	; Raise an aboutToOpen event if necessary.
	;
		call	GadgetUtilRaiseOpenEventIfNecessary
	;
	; Let superclass do its thing.
	;
		mov	di, offset GadgetFormClass
		call	ObjCallSuperNoLock
	;
	; And make sure we come to the front.
	;
		mov	ax, MSG_GEN_BRING_TO_TOP
		call	ObjCallInstanceNoLock

		.leave
		ret
GadgetFormVisOpen endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFEntVisHide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hide the form.  Generate an "aboutToClose" event
		if necessary.  Also remember our current focus
		object for if/when we become visible again later.

CALLED BY:	MSG_ENT_VIS_HIDE
PASS:		*ds:si	= GadgetDialogClass object
		ds:di	= GadgetDialogClass instance data
		ds:bx	= GadgetDialogClass object (same as *ds:si)
		es 	= segment of GadgetDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/29/95   	Initial version
	dloft	9/25/95		Fixed problems with nested visual update
	jmagasin 3/18/96	Moved some pushes/pops to after "IfNecessary"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFEntVisHide	method dynamic GadgetFormClass, 
					MSG_ENT_VIS_HIDE
		.enter
	;
	; Generate an "aboutToClose" event if VA_REALIZED.
	;
		call	GadgetUtilRaiseCloseEventIfNecessary
		jz	callSuper			; Not realized.
	;
	; Remember our .focus object for when we come back up.
	; (GadgetUtilGetFocusCommon will set our .focus inst data.)
	;
		push	cx,dx
		mov	ax, MSG_GADGET_FORM_REMEMBER_FOCUS_IN_ENT_VIS_HIDE
		call	ObjCallInstanceNoLock
		pop	cx,dx
		
callSuper:
		mov	ax, MSG_ENT_VIS_HIDE
		mov	di, offset GadgetFormClass
		call	ObjCallSuperNoLock

		.leave
		ret
GFEntVisHide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormBuildFocusPathForEntVisShow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a focus path from ourself down to the
		component specified in .focus.

CALLED BY:	MSG_GADGET_FORM_BUILD_FOCUS_PATH_IN_ENT_VIS_SHOW
		MSG_GADGET_FORM_REMEMBER_FOCUS_IN_ENT_VIS_HIDE
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		nothing
DESTROYED:	cx, dx (for HIDE)
SIDE EFFECTS:
		We have this method becuase BGadgetFormClass needs
		to intercept it and do *nothing*.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormBuildFocusPathInEntVisShow	method dynamic GadgetFormClass, 
			MSG_GADGET_FORM_BUILD_FOCUS_PATH_IN_ENT_VIS_SHOW,
			MSG_GADGET_FORM_REMEMBER_FOCUS_IN_ENT_VIS_HIDE
	;
	; Build focus path or record current focus according to message.
	;
		mov	bx, GadgetForm_offset
		mov	di, GFI_focus
		cmp	ax, MSG_GADGET_FORM_REMEMBER_FOCUS_IN_ENT_VIS_HIDE
		je	remInEntVisHide
		call	GadgetUtilBuildFocusPathInEntVisShow
		ret
remInEntVisHide:
		call	GadgetUtilRememberFocusInEntVisHide
		ret
GadgetFormBuildFocusPathInEntVisShow	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormGetWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GET_WIDTH
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
	jmagasin 7/11/96	Raise RTE if not visible (unless bgadget).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
method GadgetWindowGetWidthHeight, GadgetFormClass, MSG_GADGET_GET_WIDTH

method GadgetWindowGetWidthHeight, GadgetFormClass, MSG_GADGET_GET_HEIGHT

method GadgetWindowGetWidthHeight, GadgetDialogClass, MSG_GADGET_GET_WIDTH

method GadgetWindowGetWidthHeight, GadgetDialogClass, MSG_GADGET_GET_HEIGHT

GadgetWindowGetWidthHeight	proc	far

		uses	bp
		.enter
		mov	dx, ax
		clr	cx
		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
		call	ObjVarFindData
		jnc	returnCX
		mov	cx, ds:[bx].SWSP_x
		cmp	dx, MSG_GADGET_GET_WIDTH
		je	returnCX
		Assert	e dx, MSG_GADGET_GET_HEIGHT
		mov	cx, ds:[bx].SWSP_y

returnCX:
	; make sure the sign bit is correct
		test	cx, mask SWSS_SIGN
		jz	signChecked		; jump if no sign bit
		or	cx,  mask SWSS_RATIO


signChecked:
	;
	; If its 0, because there is a hint, then get the real size.
	; But we must check visibility since it's illegal to ask for
	; the width/height of a non-visible gadget (unless it's 
	; size-as-specified).
	;
		cmp	cx, 0
		jne	retCX
		mov_tr	bx, dx
		call	GadgetCheckVisibleBeforeGettingSize
		jmp	exit
		
retCX:
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_data.LD_integer, cx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
exit:
		.leave
		ret
GadgetWindowGetWidthHeight	endp

		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormSetLeft
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
GadgetFormSetLeft	method dynamic GadgetFormClass, 
					MSG_GADGET_SET_LEFT,
					MSG_GADGET_SET_TOP
				
		uses	bp
		.enter
		call	GadgetWindowSetLeftTop
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetFormSetLeft	endm

GadgetWindowSetLeftTop	proc	far

		.enter
	;
	; Use the right type to store as pixels
	;
		mov	bx, 1				; left
		cmp	ax, MSG_GADGET_SET_LEFT
		je	cont
		Assert	e ax, MSG_GADGET_SET_TOP
		mov	bx, 0
cont:
		push	ax		; message
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr

		Assert	fptr	esdi
		mov	ax, es:[di].CD_data.LD_integer

	;		call	ConvertPixelsToPercent100
	;		call	ConvertPercent100ToPercent1024

setType::
		mov_tr	dx, ax
	; clear ratio bit, will still be negative if it was before.
		
		and	dx, not mask SWSS_RATIO


		mov	ax, HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT
		call	ObjVarFindData
		jc	found
		mov	cx, size SpecWinSizePair
		call	ObjVarAddData
found:
		pop	ax
		cmp	ax, MSG_GADGET_SET_LEFT
		jne	setHeight
		mov	ds:[bx].SWSP_x, dx
		jmp	done
setHeight:
		Assert	e ax, MSG_GADGET_SET_TOP
		mov	ds:[bx].SWSP_y, dx
done:
		.leave
		ret

GadgetWindowSetLeftTop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormSetWidth
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
GadgetFormSetWidth	method dynamic GadgetFormClass, 
					MSG_GADGET_SET_WIDTH,
					MSG_GADGET_SET_HEIGHT
				
	uses	bp
	.enter

		call	GadgetWindowSetWidthHeight
		
	;
	; Set it invalid so the next child added shows up.
	; FIXME, do I still need this hack, I don't think so -- ron
		
		mov	cl, mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_MANUAL
		call	VisMarkInvalid

		
		
	.leave
	Destroy	ax, cx, dx
	ret
GadgetFormSetWidth	endm

GadgetWindowSetWidthHeight	proc	far
		.enter
	;
	; Use the right type to store as pixles
	;
		mov	bx, 1				; width
		cmp	ax, MSG_GADGET_SET_WIDTH
		je	cont
		Assert	e ax, MSG_GADGET_SET_HEIGHT
		mov	bx, 0
cont:
		push	ax		; message
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr

		Assert	fptr	esdi
		mov	ax, es:[di].CD_data.LD_integer


setType::
		mov_tr	dx, ax
	; only nonnegative width/height allowed
		
		and	dx, not (mask SWSS_RATIO or mask SWSS_SIGN)


		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
		call	ObjVarFindData
		jc	found
		mov	cx, size SpecWinSizePair
		call	ObjVarAddData
found:
		pop	ax
		cmp	ax, MSG_GADGET_SET_WIDTH
		jne	setHeight
		mov	ds:[bx].SWSP_x, dx
		jmp	done
setHeight:
		Assert	e ax, MSG_GADGET_SET_HEIGHT
		mov	ds:[bx].SWSP_y, dx
done:
		mov	ax, MSG_ENT_GET_FLAGS
		call	ObjCallInstanceNoLock

	;	test	al, mask EF_VISIBLE
	;	jz	bye
	;	Tell the window to recalc its size so it draws correctly
	;		mov	ax, MSG_VIS_UPDATE_WINDOWS_AND_IMAGE
	;		clr	cx
	;		call	ObjCallInstanceNoLock
bye::
		.leave
		ret
GadgetWindowSetWidthHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormGetLeft
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
GadgetFormGetLeft	method dynamic GadgetFormClass, 
					MSG_GADGET_GET_LEFT,
					MSG_GADGET_GET_TOP
		uses	bp
		.enter
		call	GadgetWindowGetLeftTop

		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetFormGetLeft	endm

GadgetWindowGetLeftTop	proc	far
		.enter
;; this only works if resizing by hand updates the hints, it does now
		mov	dx, ax
		clr	cx
		mov	ax, HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT
		call	ObjVarFindData
		jnc	returnCX
		mov	cx, ds:[bx].SWSP_x
		cmp	dx, MSG_GADGET_GET_LEFT
		je	returnCX
		Assert	e dx, MSG_GADGET_GET_TOP
		mov	cx, ds:[bx].SWSP_y

		
returnCX:
	;
	; If the SWSS_SIGN bit is set, set the real sign bit
	;
		test	cx, mask SWSS_SIGN
		jz	extended
		or	cx, mask SWSS_RATIO
extended:
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_data.LD_integer, cx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		.leave
		ret

GadgetWindowGetLeftTop endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormVisPositionBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	positions all the objects under the current object.  This is
		the message that is called by the geometry manager, and is
		the message that should be subclassed by objects that want to
		do their own child object positioning or do something else
		based on the move.

CALLED BY:	MSG_VIS_POSITION_BRANCH, geometry manager
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
		cx	= left edge 
		dx	= top edge 
RETURN:		Nothing.
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Call superclass to place items in title bar.
		If not tiled (tiled = managed)
			1) If ent object, position it.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
method GadgetOLVisPositionBranch, GadgetFormClass, MSG_VIS_POSITION_BRANCH

; leave line blank.
method GadgetOLVisPositionBranch, GadgetDialogClass, MSG_VIS_POSITION_BRANCH

;
; Note, clippers have a similar routine in gdgwin.asm
; 

GadgetOLVisPositionBranch	proc	far
		class	GadgetGeomClass
	;
	; Are we tiled?
		Assert	objectPtr, dssi, GadgetGeomClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGeom_offset
		test	ds:[di].GGI_flags, mask GGF_TILED
		jnz	callSuper

	;
	; I think the GeometryValid bits should be clear now.
	; lets ensure they are.
	; Only do it if not tiled or there may be no specific
	; vis parent.
		
		call	ClearGeomBitsOnForm
;;;	call	GadgetUtilUnManageChildren

	;
	; For PCV, we want the OLGadgetArea to appear at 0,0 so we don't
	; ask the superclass to place it.
	; If PCV had title bars / system menus / menu bars / scrollbars
	; as part of any object we would need to call the superclass to get
	; those in the right place.
if (not _PCV)	
		mov	ax, MSG_VIS_POSITION_BRANCH
		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock
endif	; PCV
;;;		call	GadgetUtilManageChildren
		call	GadgetUtilPositionChildren
		jmp	done
	;
	; Use GadgetGeomClass because this proc is used for both forms
	; and dialog and their first common superclass is GadgetGeomClass.
	;
callSuper:
		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock

done:
		.leave
		ret
GadgetOLVisPositionBranch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearGeomBitsOnForm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears geometry (VOF_GEOMETRY_INVALID, VOF_GEO_UPDATE_PATH)
		bits on the form and the OLGadgetArea.  This should be called
		by grouping objects that have OL (specific UI) built out
		objects in it whose VisOptFlags we need to muck with.

CALLED BY:	GadgetOLVisPositionBranch
PASS:		*ds:si		= GadgetGeomClass object. (not tiled)
RETURN:		nada
DESTROYED:	nothing
SIDE EFFECTS:	Who really knows what setting these bits do?

PSEUDO CODE/STRATEGY: 
		It probably should have been done in the VIS_RECALC_SIZE
		handler, but all attempts at doing that seem to have failed.
		Now we do it in the VIS_POSITION_BRANCH handler and it seems
		to work.  If the bits aren't cleared, then the child after
		the last child that would fit in orientation direction
		(if geometry were on) won't show up.  (The 9th button on
		a default size form).

		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearGeomBitsOnForm	proc	near
		class	VisClass
		uses ax, si, di, cx, dx
		.enter
	; clear the VisOptFlags bits on the form that should be cleared
	; by now
EC <		call	VisCheckVisAssumption				>
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or mask VOF_GEO_UPDATE_PATH)
		call	GadgetUtilGetCorrectVisParent
	;
	; If there is no specific vis parent, something is wrong.
	; It should have been set in SPEC_BUILD_BRANCH handler.
		Assert	ne, cx, 0
		jcxz	done
	;
	; clear the VisOptFlags bits on the OLGadget area that should be
	; cleared by now

		mov	si, dx
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or mask VOF_GEO_UPDATE_PATH)
done:
		.leave
		ret
ClearGeomBitsOnForm	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormMetaStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the user clicks on the margins to resize, set some
		instance data so we know when to resize in the end select.

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
		cx	= left
		dx	= top
RETURN:		ax	= MouseReturnFlags
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
method GadgetOLMetaStartSelect, GadgetDialogClass, MSG_META_START_SELECT

; Don't allow forms to be resizable anymore.
method GadgetOLMetaStartSelect, GadgetFormClass, MSG_META_START_SELECT

;
; keep a word to share between start select and end select.
; it is not protected by a semaphore as you must get start end select
; before you can get start select in another thread (or object in same
; thread), seems better than vardata ...
; Oh yeah, I define this stuff in code here as this is the only place
; that uses it.

GadgetResizeHackFlags	record
	:4
	GRHF_TOP	:1	; on top border
	GRHF_LEFT	:1	; on left
	GRHF_BOTTOM	:1	; on bottom
	GRHF_RIGHT	:1	; on right
GadgetResizeHackFlags	end


udata	segment
resizeInfo	GadgetResizeHackFlags
udata	ends

GadgetOLMetaStartSelect	proc	far
		class	GadgetGeomClass
		uses	es
		.enter
	;
	; Determine if they clicked on a resize border
	; Perhaps we can use UIFunctionsActive in bp to determine this.
	; (assume all resize borders are same size, ignore the fact the
	; top margin contains a title bar.
		push	cx, dx, bp		; args
		mov	ax, MSG_VIS_COMP_GET_MARGINS
		call	ObjCallInstanceNoLock
		mov	di, segment dgroup
		segmov	es, di
		clr	es:[resizeInfo]

	; get the smallest border in cx
		cmp	cx, ax
		jl	verticalVsCX
		xchg	cx, ax

verticalVsCX:
		Assert	le, cx, ax
		cmp	bx, dx
		jl	BXvsCX
		xchg	bx, dx
BXvsCX:
		Assert	le, bx, dx
		cmp	cx, bx
		jle	foundBorder
		xchg	bx, cx

foundBorder:
		Assert	le, cx, bx
		mov	ax, cx			; border width
		pop	cx, dx, bp		; args

	;
	; If the mouse click is on the border set some instance data
	; check left, top
	; ax = size of border
FORM_RESIZE_CORNER_SIZE	equ 30
		cmp	cx, ax			; on left?
		jle	isLeft			; branch if so
		cmp	dx, ax			; on top corner?
		jg	checkTop		; branch if not
		cmp	cx, FORM_RESIZE_CORNER_SIZE
		jle	isLeft			; branch if so
checkTop:
		cmp	dx, ax			; on top?
		jle	isTop			; branch if so
		cmp	cx, ax			; on top corner

checkRight:
		pushdw	cxdx			; mouseclick
		call	VisGetSize
		sub	cx, ax
		sub	dx, ax
		movdw	axbx, cxdx		; coords before border
		popdw	cxdx			; mouse click
	; Does the click happen after the start of the border
	; cx = mouse click, ax = start of border.
		cmp	cx, ax
		jl	checkBottom
		BitSet	es:[resizeInfo], GRHF_RIGHT
checkBottom:
		cmp	dx, bx
		jl	onBorder
		BitSet	es:[resizeInfo], GRHF_BOTTOM
onBorder:
		cmp	es:[resizeInfo], 0
		je	callSuper
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGeom_offset
		BitSet	ds:[di].GGI_flags, GGF_RESIZING

callSuper:
	;
	; cx, dx, bp should be as passed in.
		mov	ax, MSG_META_START_SELECT
		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock
done::

		.leave
		ret

isLeft:
		BitSet	es:[resizeInfo], GRHF_LEFT
		jmp	checkTop

isTop:
		BitSet	es:[resizeInfo], GRHF_TOP
		jmp	checkRight

		
GadgetOLMetaStartSelect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormMetaEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An END_SELECT is a signal that we were just resized or moved
		(in addition to having been selected).  If we were resized or
		moved, correctly set the size / position vardata so we keep
		the size.
	
CALLED BY:	MSG_META_END_SELECT
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		End select only gets sent when you resize or move, not when
		you click inside the OLGadgetArea.

		It should be noted that this still doesn't do the right thing
		at run-time.  It just so happens that we get an extra
		END_SELECT at buildtime after the dialog has been resized or
		moved.  (maybe just moving to after calling the superclass
		will fix it.)  No, calling the superclass here is what sends
		the MSG_VIS_RECALC_SIZE where we have problems and don't know
		the new size is.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
method GadgetOLMetaEndSelect, GadgetDialogClass, MSG_META_END_SELECT

; don't allow forms to be resizable anymore.
method GadgetOLMetaEndSelect, GadgetFormClass, MSG_META_END_SELECT

GadgetOLMetaEndSelect	proc	far
		class	GadgetGeomClass
		uses	es, bp
		.enter
		test	ds:[di].GGI_flags, mask GGF_RESIZING
		jz	callSuper
		BitClr	ds:[di].GGI_flags, GGF_RESIZING
		push	cx, dx, bp		; args to superclass
	;
	; Position magically works, cool, I wonder why.
	;
	; 	new size in cx, dx
	;
	; FIXME: cx, dx isn't new size it is where the mouse is clicked.
	; This is only the new size if the user resized by using the bottom
	; right corner.  If cx, or dx are negative you need to abs() them and
	; add the value to the size.

	; Alos dragging a size is acting like dragging a corner.

	; All we want to do here is set the vardata hint the superclass will do
	; everything else interesting.
	; I really need to make common routines for doing this next step.
	;
		push	cx, dx		; x, y click
		call	VisGetSize
		mov	ax, cx		; old width
		mov	bx, dx		; old height
		pop	cx, dx		; x, y click

	; ax, bx:  mouse click
	; cx, dx:  old size
		
	;
	; Set the new size depending on which border they selected and
	; where they dragged it to.
	;
		mov	di, segment dgroup
		segmov	es, di
		test	es:[resizeInfo], mask GRHF_LEFT
		je	checkRight
	; left border, width  = oldwidth - new position
		xchg	cx, ax		; cx <- old width, ax <- x click
		sub	cx, ax
		jmp	checkTop
checkRight:
	; if right border, width = new position
		test	es:[resizeInfo], mask GRHF_RIGHT
		jne	checkTop
	; neither left or right border. new width = old width
		mov_tr	cx, ax

checkTop:
	; cx = new width
		test	es:[resizeInfo], mask GRHF_TOP
		je	checkBottom
	; top border, height = oldheight - new position
		xchg	bx, dx		; dx <- old height, bx <- y click
		sub	dx, bx
		jmp	addVardata
checkBottom:
	; if bottom border, height = new position
		test	es:[resizeInfo], mask GRHF_BOTTOM
		jne	addVardata
	; neither top not bottom border, new height = old height.
		mov_tr	dx, bx

addVardata:
		push	cx			; width
		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
		mov	cx, size SpecWinSizePair
		call	ObjVarAddData
		pop	cx			; width
		mov	ds:[bx].SWSP_x, cx
		mov	ds:[bx].SWSP_y, dx	; height

	; call super now that we have a good size.
		pop	cx, dx, bp		; args to superclass
		mov	ax, MSG_META_END_SELECT
callSuper:
		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock

	;
	; now set the position as it no longer magically works
		push	ax			; return value
		call	VisGetBounds
		mov_tr	bp, ax			; x value
		mov_tr	dx, bx			; y value
		mov	ax, HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT
		mov	cx, size SpecWinSizePair
		call	ObjVarAddData
		mov	ds:[bx].SWSP_x, bp
		mov	ds:[bx].SWSP_y, dx
		pop	ax			; return value
		
		.leave
		ret
GadgetOLMetaEndSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormVisUpdateWindowsAndImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subclassing this message here is a total hack and probably
		makes redrawing slower.

CALLED BY:	MSG_VIS_UPDATE_WINDOWS_AND_IMAGE
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The problem occurs when the user adds more components than
		would fit in one direction in a form.  At that point the
		form stops drawing the new button (probably because the
		GadgetArea  doesn't bother to invalidate things if they
		don't fit.  This message gets sent out after a new object
		is added so it doesn't help to redraw the current component,
		but instead the next one.  We don't need to worry about the
		first one added because the GadgetArea thinks it will fit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
GadgetFormVisUpdateWindowsAndImage	method dynamic GadgetFormClass, 
					MSG_VIS_UPDATE_WINDOWS_AND_IMAGE
		.enter
		push	cx		; flags
		mov	cl, mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_MANUAL
		call	VisMarkInvalid


		pop	cx		; flags
		mov	ax, MSG_VIS_UPDATE_WINDOWS_AND_IMAGE
		
		mov	di, offset GadgetFormClass
		call	ObjCallSuperNoLock
		.leave
		ret
GadgetFormVisUpdateWindowsAndImage	endm
endif


; ================ from geom ==============



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetOLSpecBuildBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a spec build for GadgetGeom stuff that have OL stuff
		too.  (We need to figure out the right VisParent for later

CALLED BY:	
PASS:		*ds:si		- some Gadget object
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
method GadgetOLSpecBuildBranch, GadgetDialogClass, MSG_SPEC_BUILD_BRANCH

method GadgetOLSpecBuildBranch, GadgetFormClass, MSG_SPEC_BUILD_BRANCH


GadgetOLSpecBuildBranch	proc	far
		class	GadgetGeomClass
		.enter
		
		test	ds:[di].GGI_flags, mask GGF_TILED
		pushf

	; call super of geom, not form
		Assert	objectPtr, dssi, GadgetGeomClass
		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock

		popf
		jnz	setData
		
	;
	; These have to be set or buttons in groups in groups don't
	; show up in the builder unless you force a recalc
	; FIXME: I'm not really sure if I still need to do this.
	;
		mov	ax, MSG_VIS_SET_GEO_ATTRS
		mov 	cl, mask VGA_ALWAYS_RECALC_SIZE ;or mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
		clr	ch

		mov	dl, VUM_MANUAL
		call	ObjCallInstanceNoLock

setData:
	;
	; Figure who the viscomp that manages our children is.
	; It was just created by  our superclass, if at all.

	;
	; Add dummy object to form so we can get the gadget area, so
	; we can set the size later and get its position.
	;
		push	si				; form
		mov	ax, segment GadgetButtonClass
		mov	es, ax
		mov	di, offset GadgetButtonClass
		mov	bx, ds:[LMBH_handle]
		call	ObjInstantiate
		mov	dx, si			; trigger
		pop	si				; form

		mov	ax, MSG_GEN_ADD_CHILD
		mov	cx, bx
		mov	bp, CCO_FIRST
		call	ObjCallInstanceNoLock

		push	si			; form
		mov	si, dx			; trigger
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock

		mov	ax, MSG_VIS_FIND_PARENT
		call	ObjCallInstanceNoLock
		pushdw	cxdx		; parent

		mov	ax, MSG_GEN_DESTROY
		clr	bp
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
		popdw	cxdx		; parent
		pop	si			;form

		Assert	objectPtr, dssi, GadgetGeomClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGeom_offset
		jcxz	storeSelf
		Assert	e, cx, ds:[LMBH_handle]
		movdw	ds:[di].GGI_childParent, cxdx
		jmp	inval
		
storeSelf:
	;
	; If the child we added didn't have a vis parent, it is because
 	; the windowed object was going to be the parent and it was not set
	; visible and it doesn't have gadgetArea to put things in.
	; This happens for dialogs and floaters.
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		movdw	ds:[di].GGI_childParent, cxdx

inval:
	; FIXME: this probably isn't still needed.
	;
		call	VisMarkFullyInvalid
		

done::
		.leave
		ret
GadgetOLSpecBuildBranch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormVisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We can't let the geometry manager figure this out for
		us because it doesn't get it right for positioned children.

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
		ax	= message #
		cx	= RecalcSizeArgs -- suggest width for object
		dx	= RecalcSizeArgs -- suggest height for object
RETURN:		cx	= widt to use
		dx	= height to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
method GadgetOLVisRecalcSize, GadgetFormClass, MSG_VIS_RECALC_SIZE

method GadgetOLVisRecalcSize, GadgetDialogClass, MSG_VIS_RECALC_SIZE

;
; Note: Clippers have a similar routine in gdgwin.asm
; 

GadgetOLVisRecalcSize	proc	far
		class	GadgetGeomClass
		.enter
		Assert	objectPtr, dssi, GadgetGeomClass
		test	ds:[di].GGI_flags, mask GGF_TILED
		pushf

callSuper::
	; the superclass needs to be called when not tiling,
	; to place all of its OL stuff itself.  Mark everything else as
	; not managed so it doesn't mess with it.
	;
		jnz	afterChildManagement
		call	GadgetUtilUnManageChildren
afterChildManagement:

	; call superclass of Geom, not form so we don't do everything
	; twice
if (not _PCV)
		mov	di, offset GadgetGeomClass
		mov	ax, MSG_VIS_RECALC_SIZE
		call	ObjCallSuperNoLock
else
	;
	; PCV wants to place the OLGadgetArea in windows at 0,0 not (1,1)
	; (2,2).  The way to do this to call VisCompResize directly, clearing
	; the margin info.  Amazingly this will place things at the right place
	; too (or so the theory goes).  We can force this to then call
	; MSG_VIS_COMP_GET_MARGINS or just set the info we want.
	; Unfortunately, this means that menubars (popups), title bars and
	; other spui gadgetry won't be positioned correctly.
	;
		clr	bp	; VisCompSpacingMarginsInfo
		call	VisCompRecalcSize
endif
		popf
		jnz	reallyDone

custom::
	;
	; future notes:
	; 	cx:dx is the sized passed in and what we pass to our children.
	;	It is not necessarily our size, but that is okay.
	;	I don't think we want to call SizeSelf because if we are
	; 	as small as possible then our children will not have been sized
	;	yet, which we need.
	;
	;	Also, we probably should remove our margins here.
	; 	(ask self, not superclass for margins so we can add in
	;	tile offsets as defined in legos to the vis comp margins.)
	;
		
	;
	; If we are not tiled, size our gadget area and our
	; children and ourself
	;
	; moved to UpdateGeometry code
		call	GadgetUtilVisRecalcSize		; size children
	;
		
	; If we have any children, then set the gadget area to the size
	; it needs to be instead of setting the size on the primary.
	;
		pushdw	cxdx		; size
		call	GadgetUtilGetCorrectVisParent
		mov	bp, si		; form
		mov	si, dx
		mov	ax, cx						
		popdw	cxdx		; size
		jc	sizeSelf
		cmp	ax, 0
		je	sizeSelf
	; assume gadget area in same block
		Assert	e, ds:[LMBH_handle], ax
	; *ds:si	= gadget area.
	; cx:dx		= correct size

		push	si		; gadget area
		mov	ax, si
		mov	si, bp		; form
		call	GadgetUtilSizeSelf
		cmp	si, ax
		je	afterGadgetArea
		pushdw	cxdx		; real width /height
		
	; don't add in gadget insets on the actual vis size.
		mov	ax, MSG_VIS_COMP_GET_MARGINS
		mov	di, offset GadgetGeomClass
		call	ObjCallClassNoLock
		add	ax, cx
		add	bp, dx
		popdw	cxdx		; real width height
		mov	di, si		; form
		pop	si		; gadget area

		push	di		; form
		pushdw	cxdx		; total width,height
		sub	cx, ax		; - width
		sub	dx, bp		; - height
		call	VisSetSize
		popdw	cxdx		; total width, height of self
		
afterGadgetArea:
		pop	si		; form
done:

		call	GadgetUtilManageChildren
reallyDone:
		.leave
		ret
sizeSelf:
		mov	si, bp
		call	GadgetUtilSizeSelf
		jmp	done

GadgetOLVisRecalcSize	endp


ifdef COLOR_WACKINESS_FORM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the background color of the form on open.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		GrFillRect(VisGetBounds)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormVisDraw	method dynamic GadgetFormClass, 
					MSG_VIS_DRAW
	.enter

		
		test	cl, mask DF_EXPOSED
		jz	callSuper
		
		push	cx
	;		mov	al, ds:[di].GI_bgPattern
		mov	al, SDM_100
		mov	di, bp			; gstate

		call	GrSetAreaMask
		mov	ax, C_BLACK
		call	GrSetAreaColor
		call	VisGetSize
		clr	ax, bx
		call	GrFillRect
		pop	cx
		mov	al, SDM_100
		call	GrSetAreaMask


callSuper::
		mov	ax, MSG_VIS_DRAW
		mov	di, offset GadgetFormClass
		call	ObjCallSuperNoLock


	.leave
	ret
GadgetFormVisDraw	endm

endif

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormEntSetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the name gets set, set the moniker too. We have do this
		is GadgetForm, because monikers for primaries are screwy.

CALLED BY:	MSG_ENT_SET_NAME
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
		^fcx:dx	= fptr to buffer of name
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	11/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormEntSetName	method dynamic GadgetFormClass, 
					MSG_ENT_SET_NAME
	uses	ax, cx, dx, bp
		.enter
		push	cx, dx
		mov	bp, VUM_NOW
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		call	ObjCallInstanceNoLock
		pop	cx, dx
	;
	; Skip gadget class
	; It changes the moniker for us, but we really don't want it to.
	;
		mov	di, offset GadgetClass
		mov	ax, MSG_ENT_SET_NAME
		call	ObjCallSuperNoLock
		
		.leave
	ret
GadgetFormEntSetName	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormGetFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the focus component out of GFI_focus.  The form
		tries to make this component the system focus when
		it (the form) is active.

CALLED BY:	MSG_GADGET_FORM_GET_FOCUS
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		filled in GetPropertyArgs' GPA_compDataPtr
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Hey, this turned out to be one of the more interesting
		methods!  .focus is supposed to be up to date with
		the user's changing the focus hierarchy below the form,
		via keyboard navigation or pen presses.  This was originally
		accomplished by intercepting MSG_META_MUP_ALTER_FTVMC_EXCL
		and recording who was trying to grab the focus -- that
		didn't quite work.

		So.....we don't watch every focus event.  Instead we
		wait for legos code to ask us for our .focus, at which
		point we figure it out.  Hey, procrastination at work!


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormGetFocus	method dynamic GadgetFormClass, 
					MSG_GADGET_FORM_GET_FOCUS
		.enter

		mov	di, GadgetForm_offset
		mov	ax, offset GFI_focus
		call	GadgetUtilGetFocusCommon
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetFormGetFocus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormSetFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the form's focus component, GFI_focus.  The form
		will try to make this component the system focus when
		it (the form) is active.

CALLED BY:	MSG_GADGET_FORM_SET_FOCUS
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormSetFocus	method dynamic GadgetFormClass, 
					MSG_GADGET_FORM_SET_FOCUS
		.enter
	;
	; Call common code for all windows (forms, dialogs, floaters).
	;
		call	GadgetUtilSetFocusHelper
		jnc	checkIfNeedRuntimeError
	;
	; Actually set the .focus property, even if the path
	; couldn't be built due to an unfocusable gadget.
	;
		movdw	ds:[di].GFI_focus, cxdx, ax
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

GadgetFormSetFocus	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormBringToFront
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the form to the front, if it's already on screen

CALLED BY:	MSG_GADGET_FORM_BRING_TO_FRONT
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormBringToFront	method dynamic GadgetFormClass, 
					MSG_GADGET_FORM_BRING_TO_FRONT
		.enter

		mov	ax, MSG_GEN_GET_USABLE
		call	ObjCallInstanceNoLock
		jnc	done

		mov	ax, MSG_GEN_BRING_TO_TOP
		call	ObjCallInstanceNoLock
done:
		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetFormBringToFront	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormGainedLostSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method for handling the gain/loss of the system focus.

CALLED BY:	MSG_META_GAINED_SYS_FOCUS_EXCL
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFormGainedLostSysFocusExcl	method dynamic GadgetFormClass, 
					MSG_META_GAINED_SYS_FOCUS_EXCL
		.enter
	;
	; Call superclass.
	;
		mov	di, offset GadgetFormClass
		call	ObjCallSuperNoLock
	;
	; Come to front.  If user pressed on us, then we're
	; already at the front.  But if code set ui.focus
	; to us, then we might not be at the front.
	;
		mov	ax, MSG_GADGET_FORM_BRING_TO_FRONT
		call	ObjCallInstanceNoLock
done::
		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetFormGainedLostSysFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormEntSetParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Only allow "app" to be the parent of a form.

CALLED BY:	MSG_ENT_SET_PARENT
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
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
GadgetFormEntSetParent	method dynamic GadgetFormClass, 
					MSG_ENT_SET_PARENT
		.enter
	;
	; Make sure "app" is the requested parent.
	;
		mov	di, offset GadgetFormClass
		call	GadgetUtilCheckParentIsApp
		
		.leave
		ret
GadgetFormEntSetParent	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're in the focus path and we're being disabled,
		change the focus to be ourself (and not one of our
		children).

CALLED BY:	MSG_ENT_VIS_SET_ENABLED
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
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
GadgetFormSetEnabled	method dynamic GadgetFormClass, 
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
		movdw	ds:[di].GFI_focus, bxsi, ax
afterFocusChanges:
		mov	ax, MSG_ENT_VIS_SET_ENABLED
	;
	; Call superclass.
	;
callSuper:
		mov	bx, segment GadgetFormClass
		mov	es, bx
		mov	di, offset GadgetFormClass
		call	ObjCallSuperNoLock
		
		.leave
		ret
GadgetFormSetEnabled	endm


		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFMetaUnivLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	propogate leave messages to all ent children

CALLED BY:	MSG_META_UNIV_LEAVE
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
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
GFormMetaUnivLeave	method dynamic GadgetFormClass, 
					MSG_META_RAW_UNIV_LEAVE
		uses	ax, cx, dx, bp
		.enter
		mov	di, offset GadgetFormClass
		call	ObjCallSuperNoLock

	; passing this to ourselves will end up propogating all the
	; way down the ent tree by the default ent handler
		mov	ax, MSG_ENT_UNIV_LEAVE
		mov	di, offset GadgetFormClass
		call	ObjCallInstanceNoLock
		.leave
		ret
GFormMetaUnivLeave	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFGadgetSetLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_SET_LOOK
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/11/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_PCV

GFGadgetSetLook	method dynamic GadgetFormClass, 
					MSG_GADGET_SET_LOOK
passedBP	local word	push bp
		uses	es, bp
		.enter
		mov	bp, passedBP
		les	di, ss:[bp].SPA_compDataPtr
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
	; let the gadget class handler assign the error, saves code
		jne	done
		mov	ax, es:[di].CD_data.LD_integer
		mov	di, ds:[si]
		add	di, ds:[di].GadgetForm_offset
		mov	ds:[di].GI_look, al
		mov	bx, HINT_BLANK_WINDOW_STYLE
		mov	cx, HINT_BLANK_GREY_WINDOW_STYLE
		tst	al
		jz	blankOrGrey
		xchg	bx, cx
		cmp	al, 1
		je	blankOrGrey
	;border
		mov	ax, bx
		call	ObjVarDeleteData
		mov	ax, cx
		call	ObjVarDeleteData
		jmp	done
blankOrGrey:
		mov	ax, cx
		call	ObjVarDeleteData
		mov	ax, bx
		clr	cx
		call	ObjVarAddData
done:
		.leave	; restore es and bp
	;		mov	ax, MSG_GADGET_SET_LOOK
	;	mov	di, offset GadgetFormClass
	;	call	ObjCallSuperNoLock
		ret
GFGadgetSetLook	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFormVisCompGetMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the ui the we have margins of 0.
		This code should be in the SPUI, but it is easier to only
		put on legos components here.

CALLED BY:	MSG_VIS_COMP_GET_MARGINS
PASS:		*ds:si	= GadgetFormClass object
		ds:di	= GadgetFormClass instance data
		ds:bx	= GadgetFormClass object (same as *ds:si)
		es 	= segment of GadgetFormClass
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
GadgetFormVisCompGetMargins	method dynamic GadgetFormClass, 
					MSG_VIS_COMP_GET_MARGINS
		.enter
		clr	ax, cx, dx, bp
		.leave
		ret
GadgetFormVisCompGetMargins	endm


endif

