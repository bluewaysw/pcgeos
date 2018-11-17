COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskmaxItem.asm

AUTHOR:		Adam de Boor, Oct  4, 1991

ROUTINES:
	Name			Description
	----			-----------
	MSG_TI_NUKE_TASK	
	MSG_TI_CONFIRMATION_CHOICE

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/4/91		Initial revision


DESCRIPTION:
	TaskMax-specific implementation of methods for TaskItemClass
		

	$Id: bnfItem.asm,v 1.1 97/04/18 11:58:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Movable	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TINukeTask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the task for which this entry exists.

CALLED BY:	MSG_TI_NUKE_TASK
PASS:		*ds:si	= TaskItem object
		ds:di	= TaskItemInstance
RETURN:		carry set if user aborted the deletion.
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIndexE EFFECTS/IndexEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TINukeTask	method dynamic TaskItemClass, MSG_TI_NUKE_TASK
		.enter
	;
	; Confirm with the user that s/he really wants to nuke this task that's
	; in an awkward position. We also are in an awkward position, as
	; we're running on the UI thread and so can't use UserStandardDialog,
	; but must instead play games.
	; 
		mov	di, bp			; di <- chunk of message
						;  string in TaskStrings
						;  resource

		mov	dx, size GenAppDoDialogParams
		sub	sp, dx
		mov	bp, sp			; SS:BP holds the structure
	;
	; Summons is a custom warning yes/no box.
	; 
		mov	ss:[bp].SDP_customFlags, CustomDialogBoxFlags <
			0,			; not system modal
			CDT_WARNING,		; warning message
			GIT_AFFIRMATION,0>	; requiring yes/no answer
	;
	; Set the format string from what was in bp when we got to "confirm".
	; The beast is a chunk handle in the TaskStrings resource, so
	; lock the resource down and derefernce the chunk...
	; 
		mov	bx, handle TaskStrings
		call	MemLock
		mov	ss:[bp].SDP_customString.segment, ax
		mov	es, ax
		assume	es:TaskStrings
		mov	di, es:[confirmNukage]
		mov	ss:[bp].SDP_customString.offset, di
	;
	; The confirmation strings require the name of the task as the first
	; argument. The name of the task exists as a null-terminated string
	; in our vis moniker, so go get it.
	;
	; XXX: if the box is built in the same block as this object, life
	; could get messy.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	di, ds:[di].GI_visMoniker
		mov	di, ds:[di]
		add	di, offset VM_data.VMT_text
		mov	ss:[bp].SDP_stringArg1.segment, ds
		mov	ss:[bp].SDP_stringArg1.offset, di
	;
	; Tell the box to notify us when it's done its thing.
	; 
		mov	bx, ds:[LMBH_handle]		; block handle => BX
		mov	ss:[bp].GADDP_finishOD.handle, bx
		mov	ss:[bp].GADDP_finishOD.chunk, si
		mov	ss:[bp].GADDP_message, MSG_TI_CONFIRMATION_CHOICE
	;
	; Finally, contact the application object that's in charge of this
	; list entry and tell it to build & put up the box.
	; 
		mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		mov	bx, handle TaskApp
		mov	si, offset TaskApp
		mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; put up the dialog box
		add	sp, size GenAppDoDialogParams
		
		mov	bx, handle TaskStrings
		call	MemUnlock
		assume	es:dgroup
		.leave
		ret
TINukeTask	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIConfirmationChoice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has answered our question of whether to really
		delete the task that s/he had chosen. Act on it.

CALLED BY:	MSG_TI_CONFIRMATION_CHOICE
PASS:		*ds:si	= TaskItem object
		ds:di	= TaskItemInstance
		cx	= InteractionCommand
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TIConfirmationChoice method dynamic TaskItemClass, MSG_TI_CONFIRMATION_CHOICE
		.enter
		cmp	cx, IC_YES
		jne	done		; if not affirmative, then
					;  do nothing.
	;
	; S/he asked for it...deleting a task in B&F is as simple as calling
	; a function. No need to suspend, etc.
	; 
		mov	dx, ds:[di].GII_identifier
		mov	bx, BNFAPI_DELETE_TASK
		call	BNFCall
	;
	; Now delete ourselves and redo the task list(s).
	; 
		mov	ax, MSG_GEN_DESTROY
		mov	dl, VUM_NOW
		mov	bp, mask CCF_MARK_DIRTY
		call	ObjCallInstanceNoLock

		mov	bx, handle TaskApp
		mov	si, offset TaskApp
		mov	ax, MSG_TA_REDO_TASKS
		clr	di
		call	ObjMessage
done:
		.leave
		ret
TIConfirmationChoice endm

Movable		ends
