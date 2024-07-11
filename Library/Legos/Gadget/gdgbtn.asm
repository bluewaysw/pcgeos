COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Gadget
FILE:		GadgetButton.asm

AUTHOR:		David Loftesness, Jun  6, 1994

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_RESOLVE_VARIANT_SUPERCLASS
				Inform the system of our association to
				GenButton

    MTD MSG_GEN_TRIGGER_SEND_ACTION
				intercept this message to call a user
				function

    MTD MSG_GADGET_BUTTON_SET_DEFAULT
				Sets the Default property for the button.

    MTD MSG_GADGET_BUTTON_GET_DEFAULT
				Gets the Default property

    MTD MSG_GADGET_BUTTON_SET_DESTRUCTIVE
				Sets the Destructive property for the
				button.

    MTD MSG_GADGET_BUTTON_GET_DESTRUCTIVE
				Gets the Destructive property

    MTD MSG_GADGET_BUTTON_SET_CLOSE_DIALOG
				Set the closeDialog property of a button.

    MTD MSG_GADGET_BUTTON_GET_CLOSE_DIALOG
				Get the closeDialog property.

    MTD MSG_ENT_GET_CLASS	return "button"

    MTD MSG_ENT_INITIALIZE	

    MTD MSG_GADGET_BUTTON_SET_CANCEL
				

    MTD MSG_GADGET_BUTTON_GET_CANCEL
				

 ?? INT ButtonSetDefaultOnWindow
				Adds vardata to the wingroup to tell it
				that we are the default button.  This is
				done so we can make sure not to set more
				than one default for the win group.

 ?? INT ButtonGetDefaultOnWindow
				Adds vardata to the wingroup to tell it
				that we are the button.  This is done so we
				can make sure not to set more than one
				default for the win group.

    MTD MSG_GEN_FIND_KBD_ACCELERATOR
				Make sure we have the focus before we allow
				a kbd accelerator to be used.

    MTD MSG_SPEC_BUILD		Build ourself and set the default if we
				need to.

 ?? INT ButtonCheckDialogForFocus
				see if a dialog has the focus by walking
				down the focus tree

    MTD MSG_GADGET_SET_SIZE_HCONTROL,
	MSG_GADGET_SET_SIZE_VCONTROL
				Allow/disallow clipping based on the type
				of size control desired.
				
				AS_SPECIFIED: clip if needed AS_NEEDED: no
				clipping AS_SMALL_AS_POSSIBLE: no clipping
				AS_BIG_AS_POSSIBLE: clip if needed

    MTD MSG_GADGET_SET_WIDTH,
	MSG_GADGET_SET_HEIGHT	If user specifies width/height, then he
				implicitly specifies sizeH/VControl as
				AS_SPECIFIED, so we need to set
				HINT_CAN_CLIP_MONIKER_{WIDTH/HEIGHT}.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/ 6/94   	Initial revision


DESCRIPTION:
	Code for buttons.  A button is basically a GenTrigger.  It is
	only slightly complicated because the spui puts restrictions
	on some of its properties.  The spui doesn't allow for more
	than one GenTrigger beneath a WinGroup (dialog/form) to have
	HINT_DEFAULT_ACTION so we jump through hoops to make sure this
	doesn't happen. Secondly, instead of using the Spui hints for
	closing a dialog, we do some work ourselves.  The Spui will
	complain if more than one trigger in a group has the close
	dialog hint.  Note that these spui restrictions may only show
	up in ECLastly, the destructive property is pretty useless as
	it doesn't really fit into the legos api.  It comes from world
	where the ui does more work for you.
	
	$Id: gdgbtn.asm,v 1.1 98/03/11 04:28:25 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


idata	segment
	GadgetButtonClass
idata	ends

makePropEntry button, default, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_BUTTON_GET_DEFAULT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_BUTTON_SET_DEFAULT>

makePropEntry button, cancel, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_BUTTON_GET_CANCEL>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_BUTTON_SET_CANCEL>
	
makePropEntry button, destructive, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_BUTTON_GET_DESTRUCTIVE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_BUTTON_SET_DESTRUCTIVE>

makePropEntry button, closeDialog, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_BUTTON_GET_CLOSE_DIALOG>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_BUTTON_SET_CLOSE_DIALOG>

makeUndefinedPropEntry button, readOnly

compMkPropTable GadgetButtonProperty, button, default, cancel, destructive, closeDialog,readOnly

MakePropRoutines Button, button


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association to GenButton

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
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
GadgetButtonMetaResolveVariantSuperclass	method dynamic GadgetButtonClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter

	cmp	cx, Gadget_offset
	je	returnSuper

	mov	di, offset GadgetButtonClass
	call	ObjCallSuperNoLock
done:
	.leave
	ret

returnSuper:
	mov	cx, segment GenTriggerClass
	mov	dx, offset GenTriggerClass
	jmp	done

GadgetButtonMetaResolveVariantSuperclass	endm

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonSendAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	intercept this message to call a user function

CALLED BY:	MSG_GEN_BUTTON_SEND_ACTION
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
		cl	= zero if regular click
			= non-zero if double-click
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Some would argue that the trigger should send a message to
	itself that we should intercept instead of intercepting the
	message that tells the button to notify someone.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/ 3/94   	Initial version
	jmagasin 4/22/96	Raise IC_DISMISS if .closeDialog=1.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
clickString		TCHAR	"pressed", C_NULL
GadgetButtonSendAction	method dynamic GadgetButtonClass, 
					MSG_GEN_TRIGGER_SEND_ACTION
		params	local	EntHandleEventStruct
		result	local	ComponentData
ForceRef	result		; Not used yet, mayber later
		.enter
	;
	; Let superclass do its thing.
	;
		mov_tr	bx, bp
		mov	di, offset GadgetButtonClass
		call	ObjCallSuperNoLock
		mov_tr	bp, bx
	;
	; Raise a "pressed" event.
	;
		mov	ax, offset clickString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		mov	dx, ax
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 0
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjCallInstanceNoLock
	;
	; Close our parent dialog if .closeDialog=1.
	;
		mov	di, ds:[si]
		add	di, ds:[di].GadgetButton_offset
		test	ds:[di].GBI_flags, mask GBF_CLOSE_DIALOG
		jz	done
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		mov_tr	bx, bp
		call	ObjCallInstanceNoLock
		mov_tr	bp, bx
done:
		.leave
		ret
		
GadgetButtonSendAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonSetDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the Default property for the button.

CALLED BY:	MSG_GADGET_BUTTON_SET_DEFAULT
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
		^fss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Make sure we are the only GenTrigger below the
		wingroup that has this hint.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonSetDefault	method dynamic GadgetButtonClass, 
					MSG_GADGET_BUTTON_SET_DEFAULT
		uses	bp
		.enter
	;
	; Get the old default and take away its default hint.
	;
		call	ButtonGetDefaultOnWindow
	; if there is not set, then just set us.
		jcxz	setUs
	; if we are not in a GadgetClass wingroup then don't try to set
	; the default.
		jc	done
		push	ds:[LMBH_handle], si		; self
		movdw	bxsi, cxdx			; win group
		call	ObjLockObjBlock
		mov	ds, ax
		Assert	objectPtr, dssi, GadgetButtonClass
		mov	ax, HINT_DEFAULT_DEFAULT_ACTION
		call	ObjVarDeleteData
	;
	; If win group is visible, then unbuild and rebuild it so the
	; win group knows the default is gone.
	;
		mov	ax, MSG_ENT_GET_FLAGS
		call	ObjCallInstanceNoLock
		test	al, mask EF_VISIBLE
		jz	visible
		push	bp, cx, dx
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjCallInstanceNoLock
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjCallInstanceNoLock
		pop	bp, cx, dx

visible:

		call	MemUnlock
		pop	bx, si				; self
		call	MemDerefDS
setUs:
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr, esdi
		mov	ax, HINT_DEFAULT_DEFAULT_ACTION
		Assert	objectPtr, dssi, GadgetButtonClass
		call	GadgetUtilCheckIntegerAndSetHint
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
	;
	; Only set the default if we are Setting the default (not 0)
		tst	es:[di].CD_data.LD_integer
		jz	rebuild
		call	ButtonSetDefaultOnWindow
	;
	; If we are visible, then rebuild so default will show up.
	; FIXME, should add gdget routine for doing this.
rebuild:
		Assert	objectPtr, dssi, GadgetButtonClass
		mov	ax, MSG_ENT_GET_FLAGS
		call	ObjCallInstanceNoLock
		test	al, mask EF_VISIBLE
		jz	done
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjCallInstanceNoLock
		
	;
	; If the button is visible, then rebuild it so the default will
	; show up if there used to be.
	;
done:
		.leave
		Destroy ax, cx, dx
		ret
GadgetButtonSetDefault	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonGetDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the Default property

CALLED BY:	MSG_GADGET_BUTTON_GET_DEFAULT
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		nada
DESTROYED:	ax, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonGetDefault	method dynamic GadgetButtonClass, 
					MSG_GADGET_BUTTON_GET_DEFAULT
		.enter
		mov	ax, HINT_DEFAULT_DEFAULT_ACTION
		call	GadgetUtilCheckHintAndSetInteger
		.leave
		Destroy ax, cx, dx
		ret
GadgetButtonGetDefault	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonSetDestructive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the Destructive property for the button.

CALLED BY:	MSG_GADGET_BUTTON_SET_DESTRUCTIVE
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
		^fss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonSetDestructive	method dynamic GadgetButtonClass, 
					MSG_GADGET_BUTTON_SET_DESTRUCTIVE
		uses	bp
		.enter
		les	di, ss:[bp].SPA_compDataPtr
		mov	ax, HINT_TRIGGER_DESTRUCTIVE_ACTION
		call	GadgetUtilCheckIntegerAndSetHint
		.leave
		Destroy ax, cx, dx
		ret
GadgetButtonSetDestructive	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonGetDestructive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the Destructive property

CALLED BY:	MSG_GADGET_BUTTON_GET_DESTRUCTIVE
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		nada
DESTROYED:	ax, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonGetDestructive	method dynamic GadgetButtonClass, 
					MSG_GADGET_BUTTON_GET_DESTRUCTIVE
		.enter
		mov	ax, HINT_TRIGGER_DESTRUCTIVE_ACTION
		call	GadgetUtilCheckHintAndSetInteger
		.leave
		Destroy ax, cx, dx
		ret
GadgetButtonGetDestructive	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonSetCloseDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the closeDialog property of a button.

CALLED BY:	MSG_GADGET_BUTTON_SET_CLOSE_DIALOG
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		nothing (error if necessary)
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonSetCloseDialog	method dynamic GadgetButtonClass, 
					MSG_GADGET_BUTTON_SET_CLOSE_DIALOG
		.enter
	;
	; Fetch our argument.
	;
		mov	bx, di
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	typeError
		clr	cx
		or	cx, es:[di].CD_data.LD_integer
		jcxz	setProperty
		BitSet	cl, GBF_CLOSE_DIALOG
	;
	; Save new flags.
	;
setProperty:
		mov	di, bx
		mov	ds:[di].GBI_flags, cl
done:
		.leave
		Destroy	ax, cx, dx
		ret

typeError:
		mov	ax, CPE_PROPERTY_TYPE_MISMATCH
		call	GadgetUtilReturnSetPropError
		jmp	done
GadgetButtonSetCloseDialog	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonGetCloseDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the closeDialog property.

CALLED BY:	MSG_GADGET_BUTTON_GET_CLOSE_DIALOG
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonGetCloseDialog	method dynamic GadgetButtonClass, 
					MSG_GADGET_BUTTON_GET_CLOSE_DIALOG
		.enter
	;
	; Get our closeDialog property.
	;
		CheckHack < offset GBF_CLOSE_DIALOG eq 0 >	; retn 0 or 1
		mov	cl, mask GBF_CLOSE_DIALOG
		and	cl, ds:[di].GBI_flags
		clr	ch
	;
	; Stuff return value.
	;
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetButtonGetCloseDialog	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return "button"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
RETURN:		cx:dx	= fptr.char

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonGetClass	method dynamic GadgetButtonClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetButtonString
		mov	dx, offset GadgetButtonString
		ret
GadgetButtonGetClass	endm

if 0	; not needed


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonEntIntialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_INTIALIZE
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonEntInitialize	method dynamic GadgetButtonClass, 
					MSG_ENT_INITIALIZE
		.enter
		mov	di, offset GadgetButtonClass
		call	ObjCallSuperNoLock

	;
	; Setup instance data so InteractionCommands get sent to the right
	; place.  It is supposed to work to leave them null, but .... it
	; doesn't.

		mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		mov	cx, MSG_GEN_GUP_INTERACTION_COMMAND
		call	ObjCallInstanceNoLock
		.leave
		ret
GadgetButtonEntInitialize	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonSetCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_BUTTON_SET_CANCEL
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonSetCancel	method dynamic GadgetButtonClass, 
					MSG_GADGET_BUTTON_SET_CANCEL

		.enter

		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	cx, es:[di].CD_data.LD_integer
		push	bp
		mov	ax, MSG_GEN_SET_KBD_ACCELERATOR
	; if they don't want one, (pass in 0) then set it to 0
		jcxz	setIt
SBCS <		mov	cx, KeyboardShortcut <1,0,0,0,0xf,VC_ESCAPE>	>
	; hack for DBCS in kbd driver allows us to use C_SYS_ESCAPE here
DBCS <		mov	cx, KeyboardShortcut <1,0,0,0,C_SYS_ESCAPE and \
								mask KS_CHAR>>
setIt:
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
		pop	bp
		.leave
		Destroy	ax, bx, cx
		ret
GadgetButtonSetCancel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonGetCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_BUTTON_GET_CANCEL
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonGetCancel	method dynamic GadgetButtonClass, 
					MSG_GADGET_BUTTON_GET_CANCEL
		uses	bp
		.enter

		les	di, ss:[bp].GPA_compDataPtr
		mov	ax, MSG_GEN_GET_KBD_ACCELERATOR
		call	ObjCallInstanceNoLock
		jcxz	returnIt
		mov	cx, 1
returnIt:
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		.leave
		Destroy	ax, cx, dx
		ret
GadgetButtonGetCancel	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ButtonSetDefaultOnWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds vardata to the wingroup to tell it that we are the
		default button.  This is done so we can make sure not
		to set more than one default for the win group.

CALLED BY:	
PASS:		*ds:si		- GadgetButtonClass
		cx:dx		- optr of button to set
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	Will resize objblock and move it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ButtonSetDefaultOnWindow	proc	near
		class	GadgetButtonClass
		button	local	optr	push	cx, dx
	uses	ax,bx,cx,dx,si,di,bp
		.enter

	; There is no good reason why I shouldn't be able to query up
	; for a win group.
		SGQT_WIN_GROUP equ SPEC_GEN_QUERY_START + 4
		push	bp
		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, SGQT_WIN_GROUP
		call	ObjCallInstanceNoLock
		pop	bp
	; no win group, we probably aren't visible
		jnc	setInstanceData

		push	bp
		lea	ax, ss:[button]
		movdw	bxsi, cxdx
		sub	sp, size AddVarDataParams
		mov	bp, sp
		movdw	ss:[bp].AVDP_data, ssax
		mov	ss:[bp].AVDP_dataSize, size optr
		mov	ss:[bp].AVDP_dataType, ATTR_GADGET_DEFAULT_BUTTON
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
		call	ObjMessage
		add	sp, size AddVarDataParams
		pop	bp
done:
		.leave
		ret
setInstanceData:
	;
	; We want to set ourselves as the default but can't tell the
	; win group that we are the default. Rather than risk just doing it,
	; set a flag to tell us to do it a the spec build.  
	; Assume we can't just do it becuase our win group (and therfore me)
	; is not visible.
	;
		Assert	objectPtr, dssi, GadgetButtonClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetButton_offset
		mov	ds:[di].GBI_default, 1
		jmp	done
ButtonSetDefaultOnWindow	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ButtonGetDefaultOnWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds vardata to the wingroup to tell it that we are the
		button.  This is done so we can make sure not to set
		more than one default for the win group.

CALLED BY:	
PASS:		*ds:si		- GadgetButtonClass
		
RETURN:		cx:dx		- optr of button  or 0 if none
				- carry set if window not gadget class
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ButtonGetDefaultOnWindow	proc	near
		class	GadgetButtonClass
	uses	ax,bx,si,di,bp, es, ds
		.enter

	; There is no good reason why I shouldn't be able to query up
	; for a win group.
		push	bp
		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, SGQT_WIN_GROUP
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; If noone responds to our request, then we assume no one has
	; the default yet, so we can take it.
		
		jnc	return0

	; Make sure it is an gadget class or we really can't check
	; the vardata. Well maybe that isn't so bad.
	; But if it isn't a gadget class then we are embedded in something
	; else that might have default button somewhere in the wingroup.
	; If this is the case, we can't know if there is a default so
	; we are extra safe and don't set the default.
		movdw	bxsi, cxdx
		call	ObjLockObjBlock
		mov	ds, ax

if 0	; commented out to get property box default to work again.
	; please don't delete this code. It will come back sometime.
	;
		mov	ax, segment GadgetClass
		mov	es, ax
		mov	di, offset GadgetClass
		call	ObjIsObjectInClass
		jnc	done
endif	; temp fix for property boxes

		push	bx		; wingroup objblock
		mov	ax, ATTR_GADGET_DEFAULT_BUTTON
		clrdw	cxdx
		call	ObjVarFindData
		jnc	returnCXDX
		movdw	cxdx, ds:[bx]
returnCXDX:
		stc
		pop	bx		; wingroup objblock
done::
		call	MemUnlock
		cmc
done2:
		.leave
		ret
return0:
		clrdw	cxdx
		clc
		jmp	done2
ButtonGetDefaultOnWindow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonGenFindKbdAccelerator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we have the focus before we allow a kbd accelerator
		to be used.

CALLED BY:	MSG_GEN_FIND_KBD_ACCELERATOR
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high	= scan code
RETURN:		carry set if accelerator found
		ax, cx, dx, bp
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonGenFindKbdAccelerator	method dynamic GadgetButtonClass, 
					MSG_GEN_FIND_KBD_ACCELERATOR
		.enter
	;
	; make sure our dialog has the focus if we want to accept the
	; accelerator
	;
	; first get the dialog

	; There is no good reason why I shouldn't be able to query up
	; for a win group. (but it does rely on internal spui
	; constants )
		push	cx, dx,bp		; args
		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, SGQT_WIN_GROUP
		call	ObjCallInstanceNoLock
	; if not found, bail
		jnc	done

	; now see if the dialog has the focus

		call	ButtonCheckDialogForFocus
		jnc	done
	; Our dialog has the focus, yeah.
	; Let the superclass figure out how to respond.
		pop	cx, dx, bp		; args
		mov	ax, MSG_GEN_FIND_KBD_ACCELERATOR
		mov	di, offset GadgetButtonClass
		call	ObjCallSuperNoLock
		jmp	doneAndPopped
		
done:
		pop	cx, dx, bp		; args
doneAndPopped:
	; clc means not found
		.leave
		ret
GadgetButtonGenFindKbdAccelerator	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build ourself and set the default if we need to.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonSpecBuild	method dynamic GadgetButtonClass, 
					MSG_SPEC_BUILD
		passedBP	local	word	push	bp
		spa		local	SetPropertyArgs
		cdata		local	ComponentData
		.enter
		push	bp
		mov	bp, ss:[passedBP]
		mov	di, offset GadgetButtonClass
		call	ObjCallSuperNoLock
		pop	bp

	;
	; See if we need to set ourselves to be the default
	;
		Assert	objectPtr, dssi, GadgetButtonClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetButton_offset
		mov	cx, ds:[di].GBI_default
		jcxz	done
	;
	; Stop trying to be the default everytime rebuilt.
	;
		clr	ds:[di].GBI_default
		lea	bx, cdata
		movdw	ss:[spa].SPA_compDataPtr, ssbx
		mov	ss:[bx].CD_data.LD_integer, cx

	; try fooling SET_DEFAULT into not setting us not
	; usable/usable getting us into an infinite loop
		.assert Ent_offset eq GadgetButton_offset
		mov	al, ds:[di].EI_flags
		push	ax
		push	ds:[LMBH_handle]
		and	ds:[di].EI_flags, not mask EF_VISIBLE
		push	bp
		lea	bp, spa
		mov	ax, MSG_GADGET_BUTTON_SET_DEFAULT
		call	ObjCallInstanceNoLock
		pop	bp
		pop	bx
		call	MemDerefDS
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		pop	ax
		mov	ds:[di].EI_flags, al
done:		
		.leave
		ret
GadgetButtonSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ButtonCheckDialogForFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	see if a dialog has the focus by walking down the focus
		tree

CALLED BY:	GadgetButtonGenFindKbdAccelerator
PASS:		cx:dx	- dialog to check
RETURN:		Carry clear if not found, set if found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ButtonCheckDialogForFocus	proc	near
		dlog	local	optr	push	cx, dx
	uses	ax,bx,cx,dx,si,di,bp
		.enter
		push	bp
		mov	ax, MSG_META_GET_FOCUS_EXCL
		call	UserCallSystem
		pop	bp
		jnc	endOfTheLine

		mov	ax, MSG_META_GET_FOCUS_EXCL
		
	;
	;  ^lcx:dx contains the optr of the top level focus; we'll
	;  recursively send the GET_FOCUS message until we get no
	;  response.
	;
focusLoop:
		cmpdw	cxdx, ss:[dlog]
		je	done
		
		movdw	bxsi, cxdx
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		push	ax, bp
		call	ObjMessage
		pop	ax, bp
		jnc	endOfTheLine
		jcxz	endOfTheLine	

		jmp	focusLoop

endOfTheLine:
		stc
done:
		cmc
		.leave
		ret
ButtonCheckDialogForFocus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonSetSizeHVControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow/disallow clipping based on the type of
		size control desired.

			AS_SPECIFIED:		clip if needed
			AS_NEEDED:		no clipping
			AS_SMALL_AS_POSSIBLE:	no clipping	
			AS_BIG_AS_POSSIBLE:	clip if needed


CALLED BY:	MSG_GADGET_SET_SIZE_HCONTROL
		MSG_GADGET_SET_SIZE_VCONTROL
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		nothing
DESTROYED:	cx, dx, + whatever superclass call destroys
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonSetSizeHVControl	method dynamic GadgetButtonClass, 
					MSG_GADGET_SET_SIZE_HCONTROL,
					MSG_GADGET_SET_SIZE_VCONTROL
		.enter
	;
	; Utility function does all the work.
	;
		call	GadgetUtilClipMkrBasedOnSizeControl

	;
	; Let superclass do its thing.
	;
		mov	bx, segment GadgetButtonClass
		mov	es, bx
		mov	di, offset GadgetButtonClass
		call	ObjCallSuperNoLock

		.leave
		Destroy	cx, dx
		ret
GadgetButtonSetSizeHVControl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetButtonSetWidthHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If user specifies width/height, then he implicitly
		specifies sizeH/VControl as AS_SPECIFIED, so we need
		to set HINT_CAN_CLIP_MONIKER_{WIDTH/HEIGHT}.

CALLED BY:	MSG_GADGET_SET_WIDTH
		MSG_GADGET_SET_HEIGHT
PASS:		*ds:si	= GadgetButtonClass object
		ds:di	= GadgetButtonClass instance data
		ds:bx	= GadgetButtonClass object (same as *ds:si)
		es 	= segment of GadgetButtonClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx and whatever superclass destroys
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetButtonSetWidthHeight	method dynamic GadgetButtonClass, 
					MSG_GADGET_SET_WIDTH,
					MSG_GADGET_SET_HEIGHT
		.enter

		call	GadgetUtilClipMkrForFixedSize
		mov	di, offset GadgetButtonClass
		call	ObjCallSuperNoLock

		.leave
		Destroy	ax, cx, dx
		ret
GadgetButtonSetWidthHeight	endm
