COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mainTimedDialog.asm

AUTHOR:		Eric Weber, Mar 13, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/13/96   	Initial revision


DESCRIPTION:
	Code for TermTimedDialogClass
		
	$Id: mainTimedDialog.asm,v 1.1 97/04/04 16:55:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermTimedDialogInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate a timed dialog

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= TermTimedDialogClass object
		ds:di	= TermTimedDialogClass instance data
		es 	= segment of TermTimedDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermTimedDialogInitiate	method dynamic TermTimedDialogClass, 
					MSG_GEN_INTERACTION_INITIATE
		uses	ax
		.enter
	;
	; wait for both a timeout and a dismissal
	;
		clr	ds:[di].TTDI_state
	;
	; compute timeout
	;
		mov	al, ds:[di].TTDI_minVisibility
		mov	ah, 60
		mul	ah
		mov	cx, ax				; time in ticks
	;
	; start the timer
	;
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	bx, ds:[LMBH_handle]
		mov	dx, MSG_TERM_TIMED_DIALOG_TIMEOUT
		call	TimerStart
	;
	; notify superclass
	;
		.leave
		mov	di, offset TermTimedDialogClass
		GOTO	ObjCallSuperNoLock
TermTimedDialogInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermTimedDialogTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The timer has expired

CALLED BY:	MSG_TERM_TIMED_DIALOG_TIMEOUT
PASS:		*ds:si	= TermTimedDialogClass object
		ds:di	= TermTimedDialogClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermTimedDialogTimeout	method dynamic TermTimedDialogClass, 
					MSG_TERM_TIMED_DIALOG_TIMEOUT
	;
	; note that we've timed out
	;
		or	ds:[di].TTDI_state, mask TTDS_TIMED_OUT
		test	ds:[di].TTDI_state, mask TTDS_DISMISSED
		jz	done
	;
	; if we were previously dismissed, try again now
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjCallInstanceNoLock
done:
		ret
TermTimedDialogTimeout	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermTimedDialogGenGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Possibly dismiss the dialog

CALLED BY:	MSG_GEN_GUP_INTERACTION_COMMAND
PASS:		*ds:si	= TermTimedDialogClass object
		ds:di	= TermTimedDialogClass instance data
		es 	= segment of TermTimedDialogClass
		ax	= message #
		cx	= InteractionCommand
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermTimedDialogGenGupInteractionCommand	method dynamic TermTimedDialogClass, 
					MSG_GEN_GUP_INTERACTION_COMMAND
	;
	; only worry about DISMISS
	;
		cmp	cx, IC_DISMISS
		jne	callSuper
	;
	; note that we've been dismissed
	;
		or	ds:[di].TTDI_state, mask TTDS_DISMISSED
		test	ds:[di].TTDI_state, mask TTDS_TIMED_OUT
		jz	done
	;
	; if we also timed out, really dismiss the dialog
	;
callSuper:
		mov	di, offset TermTimedDialogClass
		call	ObjCallSuperNoLock
done:
		ret
TermTimedDialogGenGupInteractionCommand	endm



