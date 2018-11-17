COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefDialog.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/22/92   	Initial version.

DESCRIPTION:
	
	$Id: prefDialog.asm,v 1.1 97/04/04 17:50:27 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Intercept IC_INTERACTION_COMPLETE, if need be	

PASS:		*ds:si	= PrefDialogClass object
		ds:di	= PrefDialogClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

	If the REBOOT_IF_CHANGED flag is set, then don't allow this
	command to go to the superclass.  We'll send it there directly
	in our APPLY handler

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDialogGupInteractionCommand	method	dynamic	PrefDialogClass, 
					MSG_GEN_GUP_INTERACTION_COMMAND

	;
	; If this is IC_INTERACTION_COMPLETE, then make sure none of
	; the objects in the tree wants to reboot.  If one does, then
	; we have to drop this on the floor, and let the APPLY handler
	; deal with it later (the apply handler will send it directly
	; to the superclass)
	;

	cmp	cx, IC_INTERACTION_COMPLETE
	jne	callSuper

	push	cx
	mov	ax, MSG_PREF_GET_REBOOT_INFO
	call	ObjCallInstanceNoLock
	tst	cx			; reboot?
	pop	cx
	jz	callSuper		; no

	ret

	
callSuper:
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	di, offset PrefDialogClass
	GOTO	ObjCallSuperNoLock
PrefDialogGupInteractionCommand	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle MSG_GEN_APPLY

PASS:		*ds:si	= PrefDialogClass object
		ds:di	= PrefDialogClass instance data
		es	= Segment of PrefDialogClass.

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDialogApply	method	dynamic	PrefDialogClass, 
					MSG_GEN_APPLY
		.enter
		
		
	;
	; See if any objects in this tree have changed such that they
	; want to reboot the system.
	;
		
		mov	ax, MSG_PREF_GET_REBOOT_INFO
		call	ObjCallInstanceNoLock
		jcxz	afterReboot
		
	;
	; ^lcx:dx - reboot string.  Put up the dialog asking user if
	; s/he wants to reboot
	;
		mov	ax, MSG_PREF_DIALOG_CONFIRM_REBOOT
		call	ObjCallInstanceNoLock
		jnc	done
		
	;
	; Send myself a REBOOT message, but make sure it goes on the
	; queue, so we have time to save options, etc
	;
		mov	ax, MSG_PREF_DIALOG_REBOOT
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		
afterReboot:
		
	;
	; Send GEN_APPLY to superclass, to deal with saving options, etc.
	;
		
		mov	ax, MSG_GEN_APPLY
		mov	di, offset PrefDialogClass
		call	ObjCallSuperNoLock
		clc
done:
		.leave
		ret
PrefDialogApply	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogReboot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Restart PC/GEOS	

PASS:		*ds:si	= PrefDialogClass object
		ds:di	= PrefDialogClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDialogReboot	method	dynamic	PrefDialogClass, 
					MSG_PREF_DIALOG_REBOOT
	;
	; See if now is a good time to shutdown.  The kernel will
	; notify us after all other apps have had a chance to say yea
	; or nay.
	;
		
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bp, MSG_PREF_DIALOG_RESTART_ACK
		mov	ax, SST_CLEAN		
		call	SysShutdown
		ret
PrefDialogReboot	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogRestartAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Receive acknowledgement from the kernel whether it's
		OK to restart the system

PASS:		*ds:si	- PrefDialogClass object
		ds:di	- PrefDialogClass instance data
		es	- dgroup
		cx	- nonzero if it's OK, zero otherwise

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/25/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDialogRestartAck	method	dynamic	PrefDialogClass, 
					MSG_PREF_DIALOG_RESTART_ACK

		push	cx			; confirm/deny 		
		
	;
	; Send IC_INTERACTION_COMPLETE directly to the superclass
	;
		
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_INTERACTION_COMPLETE
		mov	di, offset PrefDialogClass
		call	ObjCallSuperNoLock
	;
	; If denied, do nothing.  Should probably put up an
	; informational message or something.
	;
		pop	cx
		jcxz	done
		
		
		mov	cx, PDCT_RESTART
		call	PrefDialogNotifyChange

	;
	; See which SysShutdownType to use
	;
		mov	ax, ATTR_PREF_DIALOG_SYS_SHUTDOWN_TYPE
		call	ObjVarFindData
		mov	ax, SST_RESTART
		jnc	gotSST
		mov	ax, ds:[bx]
		clr	cx, dx			;cx:dx <- no ack OD
gotSST:
		call	SysShutdown
done:
		ret
PrefDialogRestartAck	endm




COMMENT @----------------------------------------------------------------------

FUNCTION:	PrefDialogConfirmReboot

DESCRIPTION:	make sure the user wants to restart system

PASS:		^lcx:dx - argument string
		

RETURN:		carry SET if afirmative
		carry clear otherwise

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version
	chrisb	4/22/92		cleaned up.
------------------------------------------------------------------------------@
	
PrefDialogConfirmReboot	method dynamic PrefDialogClass,
					MSG_PREF_DIALOG_CONFIRM_REBOOT
		.enter
		
		mov	bx, handle parameterChangeConfirmation
		mov	si, offset parameterChangeConfirmation
		
		clr	ax
.assert (offset SDOP_helpContext eq offset SDP_customTriggers+4)
		push	ax, ax				;SDOP_helpContext


.assert (offset SDOP_customTriggers eq offset SDP_stringArg2+4)
		push	ax, ax		; SDOP_customTriggers

.assert (offset SDOP_stringArg2 eq offset SDOP_stringArg1+4)
		push	ax, ax		; SDP_stringArg2

.assert (offset SDOP_stringArg1 eq offset SDP_customString+4)
		push	cx		; SDP_stringArg1
		push	dx

.assert (offset SDOP_customString eq offset SDP_customFlags+2)
		push	bx		; SDOP_customString
		push	si

.assert (offset SDOP_customFlags eq 0)
		mov	ax, 
		(CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
		(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)

		push	ax		; SDOP_customFlags
					; params passed on stack
		call	UserStandardDialogOptr

		cmp	ax, IC_YES	; clears carry if equal
		clc
		jne	done
		stc
done:
		.leave
		ret
PrefDialogConfirmReboot	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let anyone interested know we're being opened

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= PrefDialog object
		bp	= 0 if top window, else window on which object 
			  should open
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialogVisOpen method dynamic PrefDialogClass, MSG_VIS_OPEN
		mov	cx, PDCT_OPEN
		call	PrefDialogNotifyChange

		mov	di, offset PrefDialogClass
		GOTO	ObjCallSuperNoLock
PrefDialogVisOpen endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let anyone interested know we're being closed

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= PrefDialog object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialogVisClose method dynamic PrefDialogClass, MSG_VIS_CLOSE
	mov	cx, PDCT_CLOSE
	call	PrefDialogNotifyChange

	mov	di, offset PrefDialogClass
	GOTO	ObjCallSuperNoLock
PrefDialogVisClose endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogBlockFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let anyone interested know we're being destroyed

CALLED BY:	MSG_META_BLOCK_FREE
PASS:		*ds:si	= PrefDialog object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialogBlockFree	method dynamic PrefDialogClass, MSG_META_BLOCK_FREE
	mov	cx, PDCT_DESTROY
	call	PrefDialogNotifyChange

	mov	di, offset PrefDialogClass
	GOTO	ObjCallSuperNoLock
PrefDialogBlockFree		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogNotifyChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify anyone interested of a change in our state.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= PrefDialog object
		cx	= PrefDialogChangeType
RETURN:		nothing
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 3/92 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialogNotifyChange proc	near
	class	PrefDialogClass
	uses	ax, bx, dx, bp, di
	.enter
	;
	; Record the message to send through the list, aiming it only at
	; subclasses of PrefClass
	; 
	mov	ax, MSG_PREF_NOTIFY_DIALOG_CHANGE
	push	si
	mov	bx, segment PrefClass
	mov	si, offset PrefClass
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = event
	pop	si
	;
	; Now call ourselves to send the message out over the list.
	; 
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, PDGCNLT_DIALOG_CHANGE
	mov	ss:[bp].GCNLMP_block, 0
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, 0
	mov	ax, MSG_META_GCN_LIST_SEND
	call	ObjCallInstanceNoLock
	add	sp, size GCNListMessageParams
	.leave
	ret
PrefDialogNotifyChange		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogMakeApplyable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If dialog box is sitting inside another dialog, forcibly
		continue the travel of a MSG_GEN_MAKE_APPLYABLE message
		to the parent object.

CALLED BY:	MSG_GEN_MAKE_APPLYABLE
PASS:		*ds:si	= PrefDialog object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialogMakeApplyable method dynamic PrefDialogClass, MSG_GEN_MAKE_APPLYABLE
	.enter
	mov	di, offset PrefDialogClass
	call	ObjCallSuperNoLock
	
	mov	cx, es
	mov	dx, offset PrefDialogClass
	mov	ax, MSG_GEN_GUP_TEST_FOR_OBJECT_OF_CLASS
	call	GenCallParent
	jnc	done		; => not a cascaded dialog
	
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	GenCallParent
done:
	.leave
	ret
PrefDialogMakeApplyable endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This handler is provided so that an object of
		PrefDialogClass can be on an application's active
		list, and thus, automatically send itself
		MSG_PREF_INIT, followed by MSG_META_LOAD_OPTIONS, when
		the app comes up.

PASS:		*ds:si	= PrefDialogClass object
		ds:di	= PrefDialogClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDialogAttach	method	dynamic	PrefDialogClass, 
					MSG_META_ATTACH
	mov	di, offset PrefDialogClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_PREF_INIT
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_LOAD_OPTIONS
	GOTO	ObjCallInstanceNoLock
PrefDialogAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialogLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make ourselves not applyable after loading options, to cope
		with the behaviour of various generic objects that make
		us applyable if the loaded option is different from the
		default for the gadget.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= PrefDialog object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialogLoadOptions method dynamic PrefDialogClass, MSG_META_LOAD_OPTIONS

		mov	di, offset PrefDialogClass
		call	ObjCallSuperNoLock

		mov	ax, MSG_GEN_MAKE_NOT_APPLYABLE
		GOTO	ObjCallInstanceNoLock

PrefDialogLoadOptions endm
