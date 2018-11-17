COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		messageDetails.asm

AUTHOR:		Adam de Boor, May 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/26/94		Initial revision


DESCRIPTION:
	
		

	$Id: messageDetails.asm,v 1.1 97/04/05 01:20:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS		; ENTIRE FILE IS A NOP UNLESS THIS IS TRUE

MailboxClassStructures	segment	resource
	MessageDetailsClass
MailboxClassStructures	ends

MessageUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message to display in the box and bring the box up
		on-screen

CALLED BY:	MSG_MD_SET_MESSAGE
PASS:		cxdx	= MailboxMessage
		bp	= address # (+ dups) to display, if message is in the
			  outbox
		*ds:si	= MessageDetails
		ds:di	= MessageDetailsInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		- set the subject as the text for the MDI_subjectText
		  object
		- store the longhand version of the message's
		  registration date in the MDI_dateText object.
		- set the moniker back to MDI_titleMoniker, freeing any
		  existing one, and mangling it according to the
		  string returned by MSG_MD_GET_TITLE_STRING
		- replace the moniker of the MDI_actionTrigger object
		  with the MDI_deliveryMoniker and then mangle a copy
		  of that moniker according to the string returned
		  by MSG_MD_GET_DELIVERY_VERB
		- invoke the MSG_GEN_INTERACTION_INITIATE method
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDSetMessage	method dynamic MessageDetailsClass, MSG_MD_SET_MESSAGE
		push	dx
		mov	dx, ds:[di].MDI_message.high
		tst	dx
		jz	storeNew
		mov	ax, ds:[di].MDI_message.low
		call	MailboxGetAdminFile
		call	DBQDelRef
storeNew:
		pop	dx
	;
	; Place an additional reference on the message while we've got it.
	; 
		MovMsg	dxax, cxdx
		call	MailboxGetAdminFile
		call	DBQAddRef
	;
	; Record the message and address #, in case we have to queue it for
	; transmission.
	; 
		movdw	ds:[di].MDI_message, dxax
		mov	ds:[di].MDI_address, bp
	;
	; Lock down the message so we can get to its subject & date stamp.
	; 
		push	ds
		mov	bx, di
		call	MessageLock
		segmov	es, ds			; *es:di <- MailboxMessageDesc
		pop	ds			; ds <- object block, again
	;
	; Dereference the subject chunk and tell the subject text object to
	; use that text for its own.
	; 
		mov	di, es:[di]
		push	di, si			; preserve deref'ed msg &
						;  object chunk
		mov	di, es:[di].MMD_subject
		mov	bp, es:[di]
		mov	dx, es			; dx:bp <- string
		clr	cx			; cx <- null-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	si, ds:[bx].MDI_subjectText
		call	ObjCallInstanceNoLock
		pop	di, si			; es:di <- MailboxMessageDesc
						; *ds:si <- MessageDetails
	;
	; Fetch out the registration time before unlocking the message
	; descriptor.
	; 
		movdw	bxax, es:[di].MMD_registered
		call	DBUnlock
	;
	; Format the registration time in the long-form.
	; 
		mov	cx, UFDTF_LONG_FORM
		call	UtilFormatDateTime	; *ds:ax <- string

		Assert	chunk, ax, ds

	;
	; Set that as the text with an *optr*, not a pointer, since the text
	; is in the same block.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].MessageDetails_offset
		push	si, ax

		mov	si, ds:[di].MDI_dateText; *ds:si <- text obj
		mov	dx, ds:[LMBH_handle]
		mov_tr	bp, ax			; ^ldx:bp <- string
		clr	cx			; cx <- null-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		call	ObjCallInstanceNoLock
		pop	si, ax			; *ds:si <- MessageDetails
						; *ds:ax <- date string
		call	LMemFree		; free the date string
	;
	; Restore our moniker to the template title moniker, freeing whatever
	; we had before.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].MessageDetails_offset
			CheckHack <MessageDetails_offset eq Gen_offset>
		mov	ax, ds:[di].MDI_titleMoniker

		Assert	chunk, ax, ds

		xchg	ds:[di].GI_visMoniker, ax
		tst	ax
		jz	mangleTitle
		call	LMemFree
mangleTitle:
	;
	; Fetch the string to go in the title by calling our subclass, then
	; create the new moniker using that.
	;
	; NOTE: We assume we are *not* on-screen at this point, so we don't
	; have to invalidate anything.
	; 
		mov	ax, MSG_MD_GET_TITLE_STRING
		call	ObjCallInstanceNoLock

		Assert	chunk, ax, ds

		call	UtilMangleCopyOfMoniker
		call	LMemFree		; free the title string
	;
	; Fetch the delivery verb for abusing the moniker of the action
	; trigger & the bound text object.
	; 
		mov	ax, MSG_MD_GET_DELIVERY_VERB
		call	ObjCallInstanceNoLock

		Assert	chunk, ax, ds

	;
	; Set the moniker of the action trigger back to the template, freeing
	; whatever it's got now.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].MessageDetails_offset
		push	si			; save details box chunk
	    ;
	    ; Push the stuff for the bounds object so we don't have to
	    ; deref the details box again.
	    ; 
		push	ds:[di].MDI_boundText, ds:[di].MDI_boundMoniker

		mov_tr	bx, ax			; *ds:bx <- verb
		mov	si, ds:[di].MDI_actionTrigger
		mov	ax, ds:[di].MDI_deliveryMoniker
		call	UtilSetMonikerFromTemplate
	;
	; Do likewise for the text object that displays the bounds for the
	; message.
	; 
		pop	si, ax			; *ds:si <- bound text
						; *ds:ax <- bound moniker
		call	UtilSetMonikerFromTemplate
	;
	; Free the verb
	; 
		mov_tr	ax, bx
		call	LMemFree
	;
	; Bring the box up on screen, finally
	; 
		pop	si			; *ds:si <- details box
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		GOTO	ObjCallInstanceNoLock
MDSetMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDMustBeSubclassed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC: Default method for these messages. Just fatal-errors, as
		the messages *must* be intercepted by the subclass.

CALLED BY:	MSG_MD_GET_TITLE_STRING
		MSG_MD_GET_DELIVERY_VERB
PASS:		who cares?
RETURN:		who knows?
DESTROYED:	life
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
MDMustBeSubclassed method dynamic MessageDetailsClass, 
		 		MSG_MD_GET_TITLE_STRING,
				MSG_MD_GET_DELIVERY_VERB
		ERROR	METHOD_MUST_BE_SUBCLASSED
MDMustBeSubclassed endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDReleaseMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the reference we placed on the message we're displaying.

CALLED BY:	MSG_MD_RELEASE_MESSAGE
PASS:		*ds:si	= MessageDetails object
		ds:di	= MessageDetailsInstance
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	MDI_message is set to 0

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDReleaseMessage method	dynamic MessageDetailsClass, MSG_MD_RELEASE_MESSAGE
		uses	dx, ax, bx
		.enter
		clrdw	dxax
		xchgdw	ds:[di].MDI_message, dxax
		tst	dx
		jz	done		; => released by some other means
		call	MailboxGetAdminFile
		call	DBQDelRef
done:
		.leave
		ret
MDReleaseMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the reference to the message is gone.

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= MessageDetails object
		ds:di	= MessageDetailsInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDVisClose	method dynamic MessageDetailsClass, MSG_VIS_CLOSE
		mov	di, offset MessageDetailsClass
		call	ObjCallSuperNoLock
		mov	ax, MSG_MD_RELEASE_MESSAGE
		GOTO	ObjCallInstanceNoLock
MDVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDMbNotifyBoxChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the removed message is the one we're displaying, force
		the box down. This will remove the reference to the message.

CALLED BY:	MSG_MB_NOTIFY_BOX_CHANGE
PASS:		*ds:si	= MessageDetails object
		ds:di	= MessageDetailsInstance
		cxdx	= affected message
		bp	= MailboxGCNListType (ignored)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	see above

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDMbNotifyBoxChange method dynamic MessageDetailsClass, MSG_MB_NOTIFY_BOX_CHANGE
		.enter
		cmpdw	ds:[di].MDI_message, cxdx
		jne	done
			CheckHack <MACT_REMOVED eq 0>
		test	bp, mask MABC_TYPE
		jnz	done		; => still around
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		GOTO	ObjCallInstanceNoLock
done:
		.leave
		ret
MDMbNotifyBoxChange endm

MessageUICode	ends

endif	; _CONTROL_PANELS
