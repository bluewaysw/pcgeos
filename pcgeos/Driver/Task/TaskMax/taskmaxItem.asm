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
		

	$Id: taskmaxItem.asm,v 1.1 97/04/18 11:58:08 newdeal Exp $

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
	; See if the task to be nuked has any open files.
	; 
		mov	dx, ds:[di].GII_identifier
		mov	ax, TMAPI_CONVERT_INDEX
		call	TMInt2f
		cmp	dx, -1
		je	done

		push	dx
		mov	ax, TMAPI_CHECK_OPEN_FILES
		call	TMInt2f
		pop	dx
		
		tst	ax		; any still open?
		jz	checkRoot	; no -- make sure at root
		
		mov	bp, offset taskHasOpenFiles
		jmp	confirm

checkRoot:
	;
	; Make sure the task is at the command prompt.
	; 
		mov	ax, TMAPI_TASK_AT_ROOT?
		call	TMInt2f
		mov	bp, offset taskNotAtRoot
		tst	dx
		jnz	confirm
	;
	; All systems go. Biff the thing.
	; 
		mov	ax, MSG_TI_CONFIRMATION_CHOICE
		mov	cx, IC_YES
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
confirm:
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
			1,			; is system modal
			CDT_WARNING,		; warning message
			GIT_AFFIRMATION,	; requiring yes/no answer
			0
		>
	;
	; Set the format string from what was in bp when we got to "confirm".
	; The beast is a chunk handle in the TaskStrings resource, so
	; lock the resource down and derefernce the chunk...
	; 
		mov	bx, handle TaskStrings
		call	MemLock
		mov	ss:[bp].SDP_customString.segment, ax
		mov	es, ax
		mov	di, es:[di]
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
	; Zero out things we don't use.
	;
		clr	bx
		clrdw	ss:[bp].SDP_helpContext, bx
		clrdw	ss:[bp].SDP_customTriggers, bx
		clrdw	ss:[bp].SDP_stringArg2, bx
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
		jmp	done
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
	; S/he asked for it...deleting a task requires TaskMax to switch to
	; it and nuke it there, so we must suspend PC/GEOS and resume as if
	; this were a task switch. Our process wil take care of the rest of
	; things when it receives the TD_CONTINUE_DELETE, including biffing
	; us.
	; 
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bp, ds:[di].GII_identifier
		mov	ax, MSG_TD_CONTINUE_DELETE
		segmov	ds, es
		call	TaskBeginSuspend
done:
		.leave
		ret
TIConfirmationChoice endm

Movable		ends
