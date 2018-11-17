COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskmaxMain.asm

AUTHOR:		Adam de Boor, Sep 19, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/19/91		Initial revision


DESCRIPTION:
	...
		

	$Id: taskmaxMain.asm,v 1.1 97/04/18 11:58:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskMaxSwitchExecCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch to the given task or perform a DosExec requested of
		us by another thread.

CALLED BY:	MSG_TD_SWITCH, MSG_TD_DOS_EXEC
PASS:		ds = es = dgroup
		cx	= DosExecArgs handle, if MSG_TD_DOS_EXEC
		dx	= index of task to which to switch if MSG_TD_SWITCH
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskMaxSwitchExecCommon	method dynamic TaskMaxClass, MSG_TD_SWITCH, 
				MSG_TD_DOS_EXEC
		.enter
	;
	; Export our current clipboard, if it's changed.
	; 
		call	TCBExport
	;
	; Now suspend things.
	; 
		inc	ax
			CheckHack <MSG_TD_CONTINUE_SWITCH eq MSG_TD_SWITCH+1>
			CheckHack <MSG_TD_CONTINUE_DOS_EXEC eq \
					MSG_TD_DOS_EXEC+1>
		call	TaskBeginSuspend
		jnc	done
	;
	; Suspend denied, so invoke the appropriate abort message so we clean
	; up properly.
	; 
		inc	ax
		inc	ax
		mov	bx, handle 0
		clr	di
		call	ObjMessage
done:
		.leave
		ret
TaskMaxSwitchExecCommon	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskMaxContinueSwitch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue a task switch begun by MSG_TD_SWITCH, now that
		all the applications in the world have had their say.

CALLED BY:	MSG_TD_CONTINUE_SWITCH
PASS:		ds = es = dgroup
		dx	= index of task to which to switch
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskMaxContinueSwitch method dynamic TaskMaxClass, MSG_TD_CONTINUE_SWITCH
		.enter
	;
	; Unregister ourselves as the task manager so the user can actually
	; bring up the menu to initiate a Copy or Paste operation
	; 
		push	dx
		mov	ax, TMAPI_SET_TASK_MGR
		mov	dl, 0
		call	TMInt2f
		pop	dx
	;
	; Tell the switcher to switch to that task.
	; 
		mov	ax, TMAPI_SWITCH_TO_TASK
		call	TMInt2f
	;
	; And register ourselves as the task manager again.
	; 
		mov	ax, TMAPI_SET_TASK_MGR
		mov	dl, 1
		call	TMInt2f
	;
	; Reconnect everything.
	; 
		call	TaskResume
	;
	; And tell our agent to rebuild the express list entries.
	; 
		mov	ax, MSG_TA_REDO_TASKS
		mov	bx, handle TaskApp
		mov	si, offset TaskApp
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Import any new clipboard data from the peanut gallery.
	; 
		call	TCBImport
		.leave
		ret
TaskMaxContinueSwitch endm

	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskMaxContinueDosExec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish the DosExec some other thread started, actually
		asking the task-switcher to do the right thing.

CALLED BY:	MSG_TD_CONTINUE_DOS_EXEC
PASS:		ds = es = dgroup
		cx	= handle of DosExecArgs
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskMaxContinueDosExec method dynamic TaskMaxClass, MSG_TD_CONTINUE_DOS_EXEC
		.enter
		push	cx		; save DosExecArgs handle
	;
	; Make sure the needed disks are in their drives.
	; 
		push	es		; save dgroup

		mov	bx, cx
		call	MemLock
		mov	ds, ax
	;
	; XXX: in theory, we'd like to lock the program and working-directory
	; disks at this point. However, if the disk isn't in the drive,
	; SysNotify is (currently) unable to prompt the user, as the video
	; driver has suspended operation, so we just put our faith in ...
	; whatever.
	; 

	;
	; Switch to the directory the caller of DosExec requested.
	; 
		pop	es		; es <- dgroup
		push	es		;  and save it again, so unlockCWD and
					;   doResume have a consistent
					;   environment in which to operate

		mov	bx, offset DEA_cwd.DEDAP_path
		call	TaskMaxChangeDirectory
	;
	; Now set up execBlock properly
	; 
		mov	es:[execBlock].DEA_cmdTail.offset, offset DEA_argLen
		mov	es:[execBlock].DEA_cmdTail.segment, ds
		mov	si, offset DEA_args
		mov	di, offset fcb1
		mov	es:[execBlock].DEA_fcb1.offset, di
		mov	es:[execBlock].DEA_fcb1.segment, es
		mov	ax, MSDOS_PARSE_FILENAME shl 8 or \
				DosParseFilenameControl <
					0,	; always set ext
					0,	; always set name
					0,	; always set drive
					1	; ignore leading space
				>
		call	FileInt21	; ds:si <- after first name

		mov	di, offset fcb2
		mov	es:[execBlock].DEA_fcb2.offset, di
		mov	es:[execBlock].DEA_fcb2.segment, es
		mov	ax, MSDOS_PARSE_FILENAME shl 8 or \
				DosParseFilenameControl <
					0,	; always set ext
					0,	; always set name
					0,	; always set drive
					1	; ignore leading space
				>
		call	FileInt21
	;
	; XXX: taskmax doesn't copy over the environment anyway, so just tell
	; it to inherit the parent's environment.
	; 
		mov	es:[execBlock].DEA_envBlk, 0

	;
	; Unregister ourselves as the task manager so the user can actually
	; bring up the menu to initiate a Copy or Paste operation
	; 
		mov	ax, TMAPI_SET_TASK_MGR
		mov	dl, 0
		int	2fh
	;
	; Ask the task switcher to create the new task.
	; 
		mov	dx, offset DEA_prog.DEDAP_path
		mov	bx, offset execBlock
		mov	ax, TMAPI_START_TASK
		clr	cx		; just run the thing, don't come back
					;  after a bit...
		int	2fh
	;
	; And register ourselves as the task manager again.
	; 
		mov	ax, TMAPI_SET_TASK_MGR
		mov	dl, 1
		int	2fh
	;
	; XXX: unlock disks here
	; 
		pop	ds			; ds <- dgroup
	;
	; Resume PC/GEOS now we're back.
	; 
		segmov	es, ds
		call	TaskResume

	;
	; Free the DosExecArgs block, finally.
	; 
		pop	bx
		call	MemFree
	;
	; Import any new clipboard data from other tasks.
	; 
		call	TCBImport
	;
	; And tell our agent to rebuild the express list entries.
	; 
		mov	ax, MSG_TA_REDO_TASKS
		mov	bx, handle TaskApp
		mov	si, offset TaskApp
		mov	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
TaskMaxContinueDosExec	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:       TaskMaxChangeDirectory

DESCRIPTION:    Change to the given directory, changing the drive if necessary.
                This is allowed to use int 21h as it won't be used while
                a DOS executive might be running.

CALLED BY:      INTERNAL
       		TaskMaxContinueDosExec

PASS:           ds:bx - pathname

RETURN:         carry clear if successful
                else ax = error code

DESTROYED:      ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Cheng   9/89            Initial version

-------------------------------------------------------------------------------@

TaskMaxChangeDirectory     proc    near	uses dx
        .enter
        mov     dx, ds:[bx]             ;dl <- drive letter

        sub     dl, 'A'			; always upper-case
        mov     ah, MSDOS_SET_DEFAULT_DRIVE
        int     21h

        mov     dx, bx
        mov     ah, MSDOS_SET_CURRENT_DIR
        int     21h
        .leave
        ret
TaskMaxChangeDirectory     endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskMaxAbortDosExec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User aborted the TD_DOS_EXEC, so clean up after it.

CALLED BY:	MSG_TD_ABORT_DOS_EXEC
PASS:		ds = es = dgroup
		cx	= handle of DosExecArgs block
RETURN:		nothing
DESTROYED:	anything I want

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskMaxAbortDosExec method dynamic TaskMaxClass, MSG_TD_ABORT_DOS_EXEC
		.enter
		mov	bx, cx
		call	MemFree
	; rough, huh?
		.leave
		ret
TaskMaxAbortDosExec endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskMaxContinueDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue the deletion of the task that was started by
		MSG_TI_NUKE_TASK having been sent to a TaskItem object,
		now the system has been suspended.

CALLED BY:	MSG_TD_CONTINUE_DELETE
PASS:		^lcx:dx	= TaskItem object
		bp	= index of task being nuked
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskMaxContinueDelete method dynamic TaskMaxClass, MSG_TD_CONTINUE_DELETE
		.enter
		push	cx, dx
		mov	dx, bp
		mov	ax, TMAPI_DELETE_TASK
		call	TMInt2f
		
		call	TaskResume
	;
	; Having nuked the task, nuke the object, asking for immediate update
	; of our generic parent.
	; 
		pop	bx, si
		mov	ax, MSG_GEN_DESTROY
		mov	dx, VUM_NOW
		clr	bp		; no need to mark things dirty
		clr	di
		call	ObjMessage
	;
	; Tell our app to rebuild the Express menu task lists.
	; 
		mov	bx, handle TaskApp
		mov	si, offset TaskApp
		mov	ax, MSG_TA_REDO_TASKS
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		.leave
		ret
TaskMaxContinueDelete endm

Movable		ends
