COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdgtoggl.asm

AUTHOR:		Ronald Braunstein, Jun  9, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/ 9/95   	Initial revision


DESCRIPTION:
	
Info:
	A choice component is a GenItemGroup / GenItem pair.  There is only
	one item per group.  Exclusive behavior is gained by explicity
	asking all siblings if they are selected.  The component part is
	the GenItemGroup (It gets the Ent Messages).  The Item does not have
	an Ent part is not actually used anywhere.  The item is created
	dynamically during EntInitialize for group.  The choice subclasses
	the gadget moniker property so it can set the moniker on the item.
		

	$Id: gdgtoggl.asm,v 1.1 98/03/11 04:30:11 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


idata	segment
	GadgetToggleClass

	GenBooleanFocusClass
	; The only reason for this subclass is to tell the keyboard
	; components that the system focus has changed.  GadgetToggle
	; will not get the system focus, but its GenBooleanFocus child
	; will.
	;

idata	ends

GadgetListCode	segment	resource


makePropEntry toggle, status, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TOGGLE_GET_STATUS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TOGGLE_SET_STATUS>

makeUndefinedPropEntry toggle, readOnly

compMkPropTable GadgetToggleProperty, toggle, status, readOnly


GadgetInitCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetToggleMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association to GenToggle

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetToggleClass object
		ds:di	= GadgetToggleClass instance data
		ds:bx	= GadgetToggleClass object (same as *ds:si)
		es 	= segment of GadgetToggleClass
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
GadgetToggleMetaResolveVariantSuperclass	method dynamic GadgetToggleClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter

	cmp	cx, Gadget_offset
	je	returnSuper

	mov	di, offset GadgetToggleClass
	call	ObjCallSuperNoLock
done:
	.leave
	ret

returnSuper:
	mov	cx, segment GenBooleanGroupClass
	mov	dx, offset GenBooleanGroupClass
	jmp	done

GadgetToggleMetaResolveVariantSuperclass	endm

GadgetInitCode	ends

MakePropRoutines Toggle, toggle

GadgetInitCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetToggleEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a singe GenItem inside.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetToggleClass object
		ds:di	= GadgetToggleClass instance data
		ds:bx	= GadgetToggleClass object (same as *ds:si)
		es 	= segment of GadgetToggleClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetToggleEntInitialize	method dynamic GadgetToggleClass, 
					MSG_ENT_INITIALIZE
		self	local	nptr	push	si
		item	local	nptr
		.enter
		mov	di, offset GadgetToggleClass
		call	ObjCallSuperNoLock
	;
	; Create a GenItem in same block
	;
		mov	bx, ds:[LMBH_handle]
		mov	ax, segment GenBooleanFocusClass
		mov	es, ax
		mov	di, offset GenBooleanFocusClass
		call	ObjInstantiate
		mov	ss:[item], si
	;
	; Set the identifier for the Boolean
	;
		push	bp
		mov	ax, MSG_GEN_BOOLEAN_SET_IDENTIFIER
		mov	cx, 1
		call	ObjCallInstanceNoLock
		pop	bp

	;
	; Add the item beneath the ItemGroup and set the item usable
	;
		push	bp
		mov	ax, MSG_GEN_ADD_CHILD
		mov	cx, bx
		mov	dx, si
		mov	si, ss:[self]
		mov	bp, CCO_FIRST
		call	ObjCallInstanceNoLock
	;
	; Send some useful init messages to the item group
	;
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_DESTINATION
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	ObjCallInstanceNoLock

if 0
		mov	ax, MSG_GEN_ITEM_GROUP_SET_BEHAVIOR_TYPE
		mov	cl, GIGBT_EXCLUSIVE_NONE
		call	ObjCallInstanceNoLock
endif

		pop	bp

	; now set us up to recieve the status message
		mov	ax, ATTR_GEN_BOOLEAN_GROUP_STATUS_MSG
		mov	cx, 2
		call	ObjVarAddData
		mov	ds:[bx], MSG_GADGET_TOGGLE_STATUS_MSG
				
		mov	di, ds:[si]			; deref handle
		add	di, ds:[di].GadgetToggle_offset
		mov	si, ss:[item]
		mov	ds:[di].GTGI_item, si
	;
	; Now, send some messages to the new item.
	;

		push	bp
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		pop	bp
		
		.leave
		Destroy ax, cx, dx, bp	
		ret
GadgetToggleEntInitialize	endm

GadgetInitCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetToggleGadgetGetCaption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set and get the caption of the item, not the group

CALLED BY:	MSG_GADGET_GET_CAPTION
PASS:		*ds:si	= GadgetToggleClass object
		ds:di	= GadgetToggleClass instance data
		ds:bx	= GadgetToggleClass object (same as *ds:si)
		es 	= segment of GadgetToggleClass
		ax	= message #
		^fss:bp	= GetPropertyArgs
RETURN:		*(ss:[bp].GPA_compDataPtr).CD_data.LD_string filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetToggleGadgetGetCaption	method  GadgetToggleClass, 
					MSG_GADGET_GET_CAPTION
		.enter
		mov	si, ds:[di].GTGI_item
		call	GadgetGetCaption
		.leave
		ret

GadgetToggleGadgetGetCaption	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetToggleGadetSetCaption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the moniker with the string passed in.

CALLED BY:	MSG_GADGET_SET_CAPTION
PASS:		*ds:si	= GadgetToggleClass object
		ds:di	= GadgetToggleClass instance data
		ds:bx	= GadgetToggleClass object (same as *ds:si)
		es	= segment of GadgetToggleClass
		ax	= message #
		^fss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetToggleGadgetSetCaption	method dynamic GadgetToggleClass, 
					MSG_GADGET_SET_CAPTION
		.enter
		mov	si, ds:[di].GTGI_item
		call	GadgetSetCaption
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetToggleGadgetSetCaption	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetToggleGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return "toggle"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetToggleClass object
		ds:di	= GadgetToggleClass instance data
		ds:bx	= GadgetToggleClass object (same as *ds:si)
		es 	= segment of GadgetToggleClass
		ax	= message #
RETURN:		cx:dx	= fptr.char

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetToggleGetClass	method dynamic GadgetToggleClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetToggleString
		mov	dx, offset GadgetToggleString
		ret
GadgetToggleGetClass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetToggleGetStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selected status of this toggle

CALLED BY:	MSG_GADGET_TOGGLE_GET_STATUS
PASS:		*ds:si	= GadgetToggleClass object
		ds:di	= GadgetToggleClass instance data
		ds:bx	= GadgetToggleClass object (same as *ds:si)
		es 	= segment of GadgetToggleClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetToggleGetStatus	method dynamic GadgetToggleClass, 
					MSG_GADGET_TOGGLE_GET_STATUS
		.enter

		push	bp
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjCallInstanceNoLock
		pop	bp

		mov	cx, 0
		jc	setValue
		inc	cx			; return 1 if selected
setValue:
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetToggleGetStatus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetToggleSetStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the toggle either on or off.
		This won't send out a changed event.

CALLED BY:	MSG_GADGET_TOGGLE_SET_STATUS
PASS:		*ds:si	= GadgetToggleClass object
		ds:di	= GadgetToggleClass instance data
		ds:bx	= GadgetToggleClass object (same as *ds:si)
		es 	= segment of GadgetToggleClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetToggleSetStatus	method dynamic GadgetToggleClass, 
					MSG_GADGET_TOGGLE_SET_STATUS
		.enter
	;
	; Make sure the state is not modified so we don't send off
	; an event by setting a property
	;
		push	bp
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
		clr	cx				; not modified
		mov	dx, 1
		call	ObjCallInstanceNoLock
		pop	bp
		
		Assert	fptr ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	wrongType
		mov	cx, es:[di].CD_data.LD_integer

		push	bp
		clr	dx				; determinate
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
		jcxz	setStatus
		mov	cx, 1				; id of item (1)
setStatus:
		mov	di, offset GadgetToggleClass
		call	ObjCallInstanceNoLock
		pop	bp
		
done:
		.leave
		ret
wrongType:

	; FIXME - add a handler
		jmp	done
GadgetToggleSetStatus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGenApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call basic code to notify the change.

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= GadgetToggleClass object
		ds:di	= GadgetToggleClass instance data
		ds:bx	= GadgetToggleClass object (same as *ds:si)
		es 	= segment of GadgetToggleClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;changedString		TCHAR	"changed", C_NULL, C_NULL
GadgetToggleGenApply	method dynamic GadgetToggleClass,
					MSG_GEN_APPLY
		params	local	EntHandleEventStruct
		result	local	ComponentData
ForceRef	result		; Not used yet, mayber later
		.enter
	;
	; Now inform the user
	;
		mov	ax, offset changedString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		mov	dx, ax
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 0
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock

		.leave
		ret
GadgetToggleGenApply		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetToggleMetaStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= GadgetToggleClass object
		ds:di	= GadgetToggleClass instance data
		ds:bx	= GadgetToggleClass object (same as *ds:si)
		es 	= segment of GadgetToggleClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetToggleMetaStartSelect	method dynamic GadgetToggleClass, 
					MSG_META_START_SELECT
		BitClr	bp, BI_DOUBLE_PRESS
		mov	di, offset GadgetToggleClass
		call	ObjCallSuperNoLock

		ret
GadgetToggleMetaStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetToggleSetGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extracts the GSTRING or BITMAP from the LegosComplex passed 
		in the ComponentData protion of the SetPropertyArgs and sets
		the graphic moniker of this object from that. Set the moniker
		on the item, not the item group

CALLED BY:	MSG_GADGET_SET_GRAPHIC
PASS:		*ds:si	= GadgetToggleClass object
		ds:di	= GadgetToggleClass instance data
		ds:bx	= GadgetToggleClass object (same as *ds:si)
		es 	= segment of GadgetToggleClass
		ax	= message #
		^fss:bp	= SetPropertyArgs

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetToggleSetGraphic	method dynamic GadgetToggleClass, 
					MSG_GADGET_SET_GRAPHIC
		.enter
		mov	dx, ds:[di].GTGI_item 	; GenItem to get moniker
		call	GadgetSetGraphicOnObject
		
		.leave
		ret
GadgetToggleSetGraphic	endm

GadgetListCode	ends
