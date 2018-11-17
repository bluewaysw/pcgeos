COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefInteraction.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.

DESCRIPTION:
	

	$Id: prefInteraction.asm,v 1.1 97/04/04 17:50:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	See if we should load our options

PASS:		*ds:si	- PrefInteractionClass object
		ds:di	- PrefInteractionClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefInteractionInitiate	method	dynamic	PrefInteractionClass, 
					MSG_GEN_INTERACTION_INITIATE
	uses	ax
	.enter

	test	ds:[di].PII_attrs, mask PIA_LOAD_OPTIONS_ON_INITIATE
	jz	done


	;
	; send the Pref-level initialization message -- sending down
	; the features and interface level, so that objects can decide
	; whether to be on-screen or not.
	;

	mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
	call	UserCallApplication
	mov_tr	cx, ax			; features (dx is level)
	mov	ax, MSG_PREF_INIT
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_LOAD_OPTIONS
	call	ObjCallInstanceNoLock
done:
	.leave
	mov	di, offset PrefInteractionClass
	GOTO	ObjCallSuperNoLock
PrefInteractionInitiate	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	See if any kids have changed

PASS:		*ds:si	= PrefInteractionClass object
		ds:di	= PrefInteractionClass instance data
		es	= Segment of PrefInteractionClass.

RETURN:		carry SET if changed

DESTROYED:	ax,cx,dx,bp 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefInteractionHasStateChanged	method	dynamic	PrefInteractionClass, 
					MSG_PREF_HAS_STATE_CHANGED
	.enter

	; Call Gen children, stopping on CARRY

	clr	di
	push	di, di		; initial child
	mov	bx, offset GI_link
	push	bx
	push	di		; segment of CB = 0
	mov	di, OCCT_DONT_SAVE_PARAMS_TEST_ABORT
	push	di		; offset of CB

	mov	bx, offset Gen_offset
	mov	di, offset GI_comp

	call	ObjCompProcessChildren
	.leave
	ret
PrefInteractionHasStateChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionGetRebootInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the optr of a reboot string, or 0 if none

PASS:		*ds:si	- PrefInteractionClass object
		ds:di	- PrefInteractionClass instance data
		es	- dgroup

RETURN:		^lcx:dx - reboot string, or cx=0 if none

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefInteractionGetRebootInfo	method	dynamic	PrefInteractionClass, 
					MSG_PREF_GET_REBOOT_INFO

		mov	bx, offset PrefInteractionGetRebootInfoCB
		GOTO	PrefProcessChildren
		
PrefInteractionGetRebootInfo	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionGetRebootInfoCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to see if child has any reboot info

CALLED BY:	PrefInteractionGetRebootInfo

PASS:		*ds:si - child

RETURN:		carry SET if has info,
			^lcx:dx - reboot string
		carry CLEAR otherwise
			cx = 0

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefInteractionGetRebootInfoCB	proc far
	;
	; Make sure the child is a Pref object before sending it this
	; message.
	;
		call	IsObjectInPrefClass
		jc	askIt
	;
	; Not a Pref object, so return cx = 0 and carry clear.
	; 
		clr	cx
		jmp	done
askIt:
		mov	ax, MSG_PREF_GET_REBOOT_INFO
		call	ObjCallInstanceNoLock
		clc
		jcxz	done
		stc
done:
		ret
PrefInteractionGetRebootInfoCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsObjectInPrefClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry SET if object is a subclass of PrefClass.
		Necessary because people obstinately continue to add
		non-pref subclasses to pref trees.

CALLED BY:	PrefInteractionGetRebootInfoCB

PASS:		*ds:si - object to check

RETURN:		carry SET if PrefClass subclass,
		carry CLEAR otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsObjectInPrefClass	proc near
		uses	es,di
		.enter
		segmov	es, <segment PrefClass>, di
		mov	di, offset PrefClass
		call	ObjIsObjectInClass
		.leave
		ret
IsObjectInPrefClass	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionLoadOptionsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to send MSG_META_LOAD_OPTIONS to each
		child, if the proper flag is set

CALLED BY:	PrefInteractionLoadOptions

PASS:		*ds:si - child to call

RETURN:		carry clear

DESTROYED:	ax,bx,cx,dx,si,di,bp,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefInteractionLoadOptionsCB	proc far
		class	PrefClass

	;
	; If not a PrefClass subclass, then don't dereference a random
	; bit in memory...
	;
		call	IsObjectInPrefClass
		jnc	sendLoad
		

		DerefPref	ds, si, di
		test	ds:[di].PI_attrs, mask PA_LOAD_IF_USABLE
		jz	sendLoad

		mov	ax, MSG_GEN_GET_USABLE
		call	ObjCallInstanceNoLock
		jnc	done

sendLoad:
		mov	ax, MSG_META_LOAD_OPTIONS
		call	ObjCallInstanceNoLock
		clc

done:
		ret
PrefInteractionLoadOptionsCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Send the message along to all USABLE children

PASS:		*ds:si	= PrefInteractionClass object
		ds:di	= PrefInteractionClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefInteractionLoadOptions	method	dynamic	PrefInteractionClass, 
					MSG_META_LOAD_OPTIONS

	mov	bx, offset PrefInteractionLoadOptionsCB
	GOTO	PrefProcessChildren
PrefInteractionLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Send to each child that has the proper flags set

PASS:		*ds:si	= PrefInteractionClass object
		ds:di	= PrefInteractionClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefInteractionSaveOptions	method	dynamic	PrefInteractionClass, 
					MSG_META_SAVE_OPTIONS

	mov	bx, offset PrefInteractionSaveOptionsCB
	FALL_THRU	PrefProcessChildren
PrefInteractionSaveOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefProcessChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Call a callback routine for each child

PASS:		*ds:si	= PrefClass object
		bx - offset of routine to call -- must be a FAR
		proc in this segment

		ax, cx, dx, bp - message data

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefProcessChildren	proc	far

	class	PrefClass

	clr	di			; initial child
	push	di, di 
	mov	di, offset GI_link	; Pass offset to LinkPart
	push	di
	push	cs			; callback routine
	push	bx
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
	ret

PrefProcessChildren	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionSaveOptionsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to see if we should pass
		MSG_META_SAVE_OPTIONS to each child

CALLED BY:	PrefInteractionSaveOptions

PASS:		*ds:si - child to check
		ax - MSG_META_SAVE_OPTIONS

RETURN:		carry clear

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefInteractionSaveOptionsCB	proc far
		class	PrefClass
		.enter

		call	IsObjectInPrefClass
		jnc	saveIt
	;
	; Felch the attributes into BL
	;

		DerefPref	ds, si, di
		mov	bl, ds:[di].PI_attrs
		test	bl, mask PA_SAVE_IF_USABLE
		jz	passedUsableTest

	;
	; First, see if usable
	;

		mov	ax, MSG_GEN_GET_USABLE
		call	ObjCallInstanceNoLock
		jnc	done

	;
	; See if enabled
	;

passedUsableTest:
		test	bl, mask PA_SAVE_IF_ENABLED
		jz	passedEnabledTest

		mov	ax, MSG_GEN_GET_ENABLED
		call	ObjCallInstanceNoLock
		jnc	done

	;
	; See if state has changed
	;

passedEnabledTest:
		test	bl, mask PA_SAVE_IF_CHANGED
		jz	saveIt

		mov	ax, MSG_PREF_HAS_STATE_CHANGED
		call	ObjCallInstanceNoLock
		jnc	done

	;
	; At long last, send the message!
	;

saveIt:
		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjCallInstanceNoLock
		clc
done:
		.leave
		ret
PrefInteractionSaveOptionsCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize this object, and all of its children

PASS:		*ds:si	= PrefInteractionClass object
		ds:di	= PrefInteractionClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefInteractionInit	method	dynamic	PrefInteractionClass, 
				MSG_PREF_INIT,
				MSG_PREF_SET_ORIGINAL_STATE

		push	ax, cx, dx, bp
		mov	di, offset PrefInteractionClass
		call	ObjCallSuperNoLock
		pop	ax, cx, dx, bp
		push	ax, cx, dx, bp
		mov	di, offset PrefInteractionClass
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL
		call	ObjCallInstanceNoLock
		pop	ax, cx, dx, bp

		mov	bx, offset PrefSendToPrefClassCB
		GOTO	PrefProcessChildren
PrefInteractionInit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSendToPrefClassCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to send MSG_PREF_INIT to children if
		they're of PrefClass

CALLED BY:	PrefInteractionInit, PrefItemGroupInit

PASS:		*ds:si - child
		ax, cx, dx, bp - message data

RETURN:		carry clear 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSendToPrefClassCB	proc far
		uses	ax,cx,dx,bp
		.enter

		call	IsObjectInPrefClass
		jnc	done

		call	ObjCallInstanceNoLock
		clc
done:
		.leave
		ret
PrefSendToPrefClassCB	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save options if our bit tells us to.

PASS:		*ds:si	- PrefInteractionClass object
		ds:di	- PrefInteractionClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefInteractionApply	method	dynamic	PrefInteractionClass, 
					MSG_GEN_APPLY
	;
	; Call superclass FIRST, so that objects that do things on
	; apply can do so before saving options.
	;
		mov	di, offset PrefInteractionClass
		call	ObjCallSuperNoLock

		DerefPref	ds, si, di
		mov	bl, ds:[di].PII_attrs
		test	bl, mask PIA_SAVE_OPTIONS_ON_APPLY
		jz	afterSave

		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjCallInstanceNoLock

		call	InitFileCommit
afterSave:
		test	bl, mask PIA_COMPLETE_INTERACTION_ON_APPLY
		jz	done
	;
	; Now, send our superclass this message, since it didn't get
	; it before
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_INTERACTION_COMPLETE
		mov	di, offset PrefInteractionClass
		GOTO	ObjCallSuperNoLock
done:
		ret
PrefInteractionApply	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInteractionGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If the flag is set, then swallow
		IC_INTERACTION_COMPLETE, as we'll send it to ourselves
		once we know everything's OK.

PASS:		*ds:si	- PrefInteractionClass object
		ds:di	- PrefInteractionClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefInteractionGupInteractionCommand	method	dynamic	PrefInteractionClass, 
				MSG_GEN_GUP_INTERACTION_COMMAND

		cmp	cx, IC_INTERACTION_COMPLETE
		je	check
gotoSuper:
		mov	di, offset PrefInteractionClass
		GOTO	ObjCallSuperNoLock

check:
		test	ds:[di].PII_attrs,
				mask PIA_COMPLETE_INTERACTION_ON_APPLY 
		jz	gotoSuper
		ret
PrefInteractionGupInteractionCommand	endm

