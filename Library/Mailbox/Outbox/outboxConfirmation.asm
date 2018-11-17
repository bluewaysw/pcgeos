COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxConfirmation.asm

AUTHOR:		Allen Yuen, Jan 22, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/22/95   	Initial revision


DESCRIPTION:
	Code to implement OutboxConfirmationClass which displays a
	not-yet-sendable message just added to the outbox.

	$Id: outboxConfirmation.asm,v 1.1 97/04/05 01:21:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource
	OutboxConfirmationClass
MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message to be displayed in this dialog.

CALLED BY:	MSG_OC_SET_MESSAGE
PASS:		ds:di	= OutboxConfirmationClass instance data
		cxdx	= MailboxMessage w/one extra reference
		bp	= talID (if applicable)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCSetMessage	method dynamic OutboxConfirmationClass, 
					MSG_OC_SET_MESSAGE

EC <	tst	ds:[di].OCI_talID					>
EC <	ERROR_NZ	DUPLICATE_SET_MESSAGE				>
	movdw	ds:[di].OCI_message, cxdx
	mov	ds:[di].OCI_talID, bp


	;
	; Add another reference to the message, which will be removed by the
	; glyph. We keep a reference to the message until the box is dismissed.
	; 
	call	MailboxGetAdminFile	; bx = admin file

	MovMsg	dxax, cxdx
	call	DBQAddRef

	;
	; Tell the glyph to display the message.
	;
	MovMsg	cxdx, dxax
	mov	si, offset OutConfirmMessage
	mov	ax, MSG_MG_SET_MESSAGE_ALL_VIEW
	GOTO	ObjCallInstanceNoLock


OCSetMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCGetReasonOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an address marked with the given talID and fetch its
		failure reason.

CALLED BY:	(INTERNAL) OCSetMessage
PASS:		ds	= lmem block
		cxdx	= MailboxMessage to examine
		bp	= TalID to look for
RETURN:		carry set if no address marked
			cx, dx	= destroyed
		carry clear if have reason:
			^lcx:dx	= reason string
			ds	= fixed up (cx = ds:[LMBH_handle])
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCDismiss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy this dialog after removing 1 ref from the message.

CALLED BY:	MSG_OC_DISMISS
PASS:		*ds:si	= OutboxConfirmationClass object
		ds:di	= OutboxConfirmationClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCDismiss	method dynamic OutboxConfirmationClass, 
					MSG_OC_DISMISS

				;  no need to unmark things. In some cases
				;  (something already sending, e.g.) this
				;  actually would screw things up.
	movdw	dxax, ds:[di].OCI_message
	mov	cx, ds:[di].OCI_talID
	call	OUUnmarkAddresses

	;
	; Remove the reference we left on the message.
	;
	call	MailboxGetAdminFile	; ^vbx = admin file
	call	DBQDelRef
	;
	; Get the application to do the work of destroying us.
	;
	mov	ax, MSG_MA_DESTROY_DIALOG
	mov	cx, ds:[OLMBH_header].LMBH_handle
	mov	dx, si
	GOTO	UserCallApplication

OCDismiss	endm

OutboxUICode	ends
