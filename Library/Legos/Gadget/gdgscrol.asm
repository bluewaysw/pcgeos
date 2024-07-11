COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Gadget library
FILE:		gdgscrol.asm

AUTHOR:		dloft, Sep 18, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/18/95   	Initial revision


DESCRIPTION:
	Implementation of the scrollbar component
		

	$Id: gdgscrol.asm,v 1.1 98/03/11 04:27:18 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	GadgetScrollbarClass
idata	ends

makePropEntry scrollbar, thumbSize, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SCROLLBAR_GET_THUMBSIZE>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SCROLLBAR_SET_THUMBSIZE>

makePropEntry scrollbar, notifyDrag, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SCROLLBAR_GET_NOTIFYDRAG>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SCROLLBAR_SET_NOTIFYDRAG>

makeUndefinedPropEntry scrollbar, caption
makeUndefinedPropEntry scrollbar, readOnly
makeUndefinedPropEntry scrollbar, graphic

compMkPropTable	GadgetScrollbarProperty, scrollbar, thumbSize, \
	notifyDrag, caption, readOnly, graphic
MakePropRoutines Scrollbar, scrollbar


GadgetInitCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetScrollbarEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set HINT_VALUE_Y_SCROLLER to ensure that we look like a
		scrollbar.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetScrollbarEntInitialize	method dynamic GadgetScrollbarClass, 
					MSG_ENT_INITIALIZE
		.enter
	;
	; Set up some hints so that GenValueClass knows what to build out
	; into...
	;
		mov	ax, HINT_VALUE_DISPLAYS_RANGE
		mov	cx, size WWFixed
		call	ObjVarAddData
		mov	ds:[bx].WWF_int, 0	; use 0 as default range
						; until the property is set
		clr	cx
		mov	ax, HINT_VALUE_Y_SCROLLER
		call	ObjVarAddData
	;
	; Tell superclass to do its thing
	;
		mov	ax, MSG_ENT_INITIALIZE
		mov	di, offset GadgetScrollbarClass
		call	ObjCallSuperNoLock

	;
	; notifyDrag = 0 by default.  dl 10/11/95
	;		mov	ax, HINT_VALUE_IMMEDIATE_DRAG_NOTIFICATION
	;		call	ObjVarAddData

		mov	ax, MSG_GEN_VALUE_SET_APPLY_MSG
		mov	cx, MSG_GADGET_SCROLLBAR_SCROLL_TOP
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_VALUE_SET_DESTINATION
		mov	cx, ds:[LMBH_handle]
		mov	dx, si				; ^lcx:dx = oself
		call	ObjCallInstanceNoLock

		.leave
		ret
GadgetScrollbarEntInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetScrollbarEntValidateParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't allow scrollbars at any level below GenView or it will
		crash.

CALLED BY:	MSG_ENT_VALIDATE_PARENT
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
		^lcx:dx	= potential parent
		
RETURN:		ax	= nonzero to reject parent
			  0 to accept parent
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	12/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetScrollbarEntValidateParent	method dynamic GadgetScrollbarClass, 
					MSG_ENT_VALIDATE_PARENT
	uses	cx, dx, bp
		.enter
		mov	ax, MSG_GEN_GUP_FIND_OBJECT_OF_CLASS
		movdw	bxsi, cxdx
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	cx, segment GenViewClass
		mov	dx, offset GenViewClass
		call	ObjMessage
		clr	ax
		jcxz	done	; not found, return ok: ax = 0
		inc	ax	; found, return not ok: ax = 1
done:
		
		.leave
		ret
GadgetScrollbarEntValidateParent	endm

GadgetInitCode	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSGadgetScrollbarScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	React to a mouse click by the user

CALLED BY:	MSG_GADGET_SCROLLBAR_SCROLL_TOP, etc.
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
changedEvent	TCHAR	"changed", C_NULL

scrollbarEventTable	GadgetScrollbarScrollType \
	-1,				; top of scrollbar not supported
	ST_BACK_PAGE,
	ST_BACK_ARROW,
	ST_THUMB,
	ST_FORWARD_ARROW,
	ST_FORWARD_PAGE,
	-1				; bottom of scrollbar not supported

NUM_CHANGED_EVENT_ARGS	= 1

GadgetScrollbarScroll	method dynamic GadgetScrollbarClass, 
					MSG_GADGET_SCROLLBAR_SCROLL_TOP,
					MSG_GADGET_SCROLLBAR_SCROLL_PAGE_UP,
					MSG_GADGET_SCROLLBAR_SCROLL_UP,
					MSG_GADGET_SCROLLBAR_SCROLL_SET,
					MSG_GADGET_SCROLLBAR_SCROLL_DOWN,
					MSG_GADGET_SCROLLBAR_SCROLL_PAGE_DOWN,
					MSG_GADGET_SCROLLBAR_SCROLL_BOTTOM
	params	local	EntHandleEventStruct
		.enter
		
		push	ax, bp
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		call	ObjCallInstanceNoLock
		

		pop	bx, bp			; msg number
		sub	bx, MSG_GADGET_SCROLLBAR_SCROLL_TOP
		shl	bx			; word table
		mov	ax, cs:[scrollbarEventTable][bx]
		cmp	ax, -1
		je	done


		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, ax
		mov	ax, offset changedEvent
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, NUM_CHANGED_EVENT_ARGS
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	di, mask MF_CALL
		lea	dx, params
		mov	cx, ss
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
GadgetScrollbarScroll	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetScrollbarGetThumb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the thumbSize property

CALLED BY:	MSG_GADGET_SCROLLBAR_GET_THUMB
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetScrollbarGetThumbsize	method dynamic GadgetScrollbarClass, 
					MSG_GADGET_SCROLLBAR_GET_THUMBSIZE
		.enter

		mov	ax, HINT_VALUE_DISPLAYS_RANGE
		call	ObjVarFindData
EC <		ERROR_NC	-1					>

		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	ax, {word} ds:[bx].WWF_int
		mov	es:[di].CD_data.LD_integer, ax
		
		.leave
		ret
GadgetScrollbarGetThumbsize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetScrollbarSetThumbsize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return our thumbSize property

CALLED BY:	MSG_GADGET_SCROLLBAR_SET_THUMBSIZE
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	* Some enterprising engineer could probably combine this method with
	the get method for the same property...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/26/95   	Initial version
	jmagasin 5/6/96		Constrain thumbSize to 0..32767

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetScrollbarSetThumbsize	method dynamic GadgetScrollbarClass, 
					MSG_GADGET_SCROLLBAR_SET_THUMBSIZE
		.enter
	;
	; Deref vardata.
	;
		mov	ax, HINT_VALUE_DISPLAYS_RANGE
		call	ObjVarFindData
EC <		ERROR_NC	-1					>
	;
	; Get argument and constrain to 0..32767.
	;
		les	di, ss:[bp].SPA_compDataPtr
		mov	ax, es:[di].CD_data.LD_integer
		test	ax, 8000h
		jz	storeThumbSize
		clr	ax				; ax was <0

storeThumbSize:
		mov	{word} ds:[bx].WWF_int, ax
		
		.leave
		ret
GadgetScrollbarSetThumbsize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetScrollbarSetOrientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the orientation property

CALLED BY:	MSG_GADGET_SCROLLBAR_SET_ORIENTATION
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetScrollbarSetOrientation	method dynamic GadgetScrollbarClass, 
					MSG_GADGET_SCROLLBAR_SET_ORIENTATION
		.enter

		les	di, ss:[bp].SPA_compDataPtr
		tst	es:[di].CD_data.LD_integer
		jz	addHint

		xchg	ax, dx
addHint:
		clr	cx
		call	ObjVarAddData

		mov_tr	ax, dx
		call	ObjVarDeleteData
		
		.leave
		ret
GadgetScrollbarSetOrientation	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSGadgetScrollbarSetNotifydrag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the notifyDrag property

CALLED BY:	MSG_GADGET_SCROLLBAR_SET_NOTIFYDRAG
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GSGadgetScrollbarSetNotifydrag	method dynamic GadgetScrollbarClass, 
					MSG_GADGET_SCROLLBAR_SET_NOTIFYDRAG
		.enter

		mov	ax, HINT_VALUE_IMMEDIATE_DRAG_NOTIFICATION

		les	di, ss:[bp].SPA_compDataPtr
		tst	es:[di].CD_data.LD_integer
		jz	removeHint

		call	ObjVarAddData
done:
		.leave
		ret
removeHint:
		call	ObjVarDeleteData
		jmp	done
GSGadgetScrollbarSetNotifydrag	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSGadgetScrollbarGetnotifydrag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the notifyDrag property

CALLED BY:	MSG_GADGET_SCROLLBAR_GET_NOTIFYDRAG
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GSGadgetScrollbarGetNotifydrag	method dynamic GadgetScrollbarClass, 
					MSG_GADGET_SCROLLBAR_GET_NOTIFYDRAG
		.enter

		mov	ax, HINT_VALUE_IMMEDIATE_DRAG_NOTIFICATION
		call	GadgetUtilCheckHintAndSetInteger

		.leave
		ret
GSGadgetScrollbarGetNotifydrag	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSVisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	stuff our size based on the fixed_size hints.

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Ask for fixed size.
	Null out the fixed size for the dimension that we're not
	Replace any 0 values with values obtained by calling the superclass
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0

This code does lots of fancy stuff to prevent twistiness and keep the
size of the perpendicular dimension of the scrollbar from getting out of hand.
Unfortunately, it conflicted with the "spin button" look, so I simplified it
and placed the new version below.  The two should probably be merged at some
point...		dl 2/23/96

GadgetScrollbarVisRecalcSize	method dynamic GadgetScrollbarClass, 
					MSG_VIS_RECALC_SIZE
		.enter

		push	cx, dx			; save passed-in sizes

		mov	ax, MSG_GEN_GET_FIXED_SIZE
		call	ObjCallInstanceNoLock

		pop	ax, bp			; restore passed-in sizes

		call	GSZeroOutDimensionValue
		
		push	cx, dx			; Save the fixed_size sizes.
		movdw	cxdx, axbp

		call	GSEnsureMinHeight	; prevent the "twisties"
callRecalc::
		mov	ax, MSG_VIS_RECALC_SIZE
		mov	di, offset GadgetScrollbarClass
		call	ObjCallSuperNoLock
		pop	ax			; pushed cx
		tst	ax
		jz	dxOkay
		mov	dx, ax
dxOkay:
		pop	ax			; pushed dx
		tst	ax
		jz	doneUpdate
		mov	cx, ax
doneUpdate:
		call	GSEnsureMinHeightAndWidth
						; neither can be less than
						; 15...
	;
	; update our FIXED_SIZE values
	;
		mov	al, VUM_DELAYED_VIA_UI_QUEUE
		call	GadgetUtilGenSetFixedSize
		.leave
		ret
GadgetScrollbarVisRecalcSize	endm
endif

GadgetScrollbarVisRecalcSize	method dynamic GadgetScrollbarClass, 
					MSG_VIS_RECALC_SIZE
		.enter

		mov	ax, MSG_GEN_GET_FIXED_SIZE
		call	ObjCallInstanceNoLock

callRecalc::
		mov	ax, MSG_VIS_RECALC_SIZE
		mov	di, offset GadgetScrollbarClass
		call	ObjCallSuperNoLock

		.leave
		ret
GadgetScrollbarVisRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetScrollbarGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return "scrollbar"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
RETURN:		cx:dx	= "scrollbar"
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetScrollbarGetClass	method dynamic GadgetScrollbarClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetScrollbarString
		mov	dx, offset GadgetScrollbarString
		ret
GadgetScrollbarGetClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	take care of stuff before going away

CALLED BY:	MSG_ENT_DESTROY
PASS:		*ds:si	= GadgetScrollbarClass object
		ds:di	= GadgetScrollbarClass instance data
		ds:bx	= GadgetScrollbarClass object (same as *ds:si)
		es 	= segment of GadgetScrollbarClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	because of the SPUIs internal timer which has the tendancy to
	rind after the object is destroyed, I am going to try to turn
	it off by doing a MSG_VIS_LOST_GADGET_EXCL before continuing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/18/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GSEntDestroy	method dynamic GadgetScrollbarClass, 
					MSG_ENT_DESTROY
		uses	ax, cx, dx, bp
		.enter

	; as I did for GadgetNumberClass, the Scrollbar spui class
	; likes to keep around a timer which sometimes goes off after
	; the object has gone on to greater pastures, so in an attept
	; to shutdown the timer (there is no API for doing that
	; explicitly) I am doing this, as, from looking at the code,
	; it seems to turn off the timer - sigh
		push	ax, cx, dx, bp
		mov	ax, MSG_VIS_LOST_GADGET_EXCL
		call	ObjCallInstanceNoLock
		pop	ax, cx, dx, bp

		mov	di, offset GadgetScrollbarClass
		call	ObjCallSuperNoLock
		.leave
		ret
GSEntDestroy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetScrollbarSetLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the look for the scrollbar

CALLED BY:	MSG_GADGET_SET_LOOK
PASS:		*ds:si	= GadgetScrollbar object
		ds:di	= GadgetScrollbar instance data
		ds:bx	= GadgetScrollbar object (same as *ds:si)
		es 	= segment of GadgetScrollbar
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/25/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetScrollbarSetLook	method dynamic GadgetScrollbarClass,
					MSG_GADGET_SET_LOOK
		.enter

	;
	; call our superclass
	;
		mov	di, offset GadgetScrollbarClass
		call	ObjCallSuperNoLock
	;
	; call utility to add and remove hints as necessary
	;
		mov	ax, GadgetScrollbarLook		;ax <- maximum look
		mov	cx, length scrollHints		;cx <- length of hints
		segmov	es, cs
		mov	dx, offset scrollHints		;es:dx <- ptr to hints
		call	GadgetUtilSetLookHints

		.leave
		Destroy ax, cx, dx
		ret

scrollHints word \
	HINT_VALUE_X_SCROLLER,
	HINT_VALUE_Y_SCROLLER,
	HINT_VALUE_NO_DIGITAL_DISPLAY
spinHints nptr \
	GadgetRemoveHint,	;no: x scroller
	GadgetAddHint,		;y scroller
	GadgetAddHint		;no digital display
vertHints nptr \
	GadgetRemoveHint,	;no: x scroller
	GadgetAddHint,		;y scroller
	GadgetRemoveHint	;no: no digital display
horizHints nptr \
	GadgetAddHint,		;x scroller
	GadgetRemoveHint,	;no: y scroller
	GadgetRemoveHint	;no: no digital display

CheckHack <length spinHints eq length scrollHints>
CheckHack <length vertHints eq length scrollHints>
CheckHack <length horizHints eq length scrollHints>
CheckHack <offset spinHints eq offset scrollHints+size scrollHints>
CheckHack <offset vertHints eq offset spinHints+size spinHints>
CheckHack <offset horizHints eq offset vertHints+size vertHints>

ForceRef spinHints
ForceRef vertHints
ForceRef horizHints

CheckHack <LOOK_SCROLLBAR_SPINNER eq 0>
CheckHack <LOOK_SCROLLBAR_VERTICAL eq 1>
CheckHack <LOOK_SCROLLBAR_HORIZONTAL eq 2>

GadgetScrollbarSetLook	endm
