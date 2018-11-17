COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bnfMain.asm

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
		

	$Id: bnfMain.asm,v 1.1 97/04/18 11:58:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFSwitchExecCommon
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
BNFSwitchExecCommon	method dynamic BNFClass, MSG_TD_SWITCH, 
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
BNFSwitchExecCommon	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFContinueSwitch
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
BNFContinueSwitch method dynamic BNFClass, MSG_TD_CONTINUE_SWITCH
		.enter
	;
	; Tell the switcher to switch to that task.
	; 
		mov	bx, BNFAPI_SWITCH
		call	BNFCall
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
BNFContinueSwitch endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFAllocID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an ID we can use for the new task. We prefer things
		that begin with a G (for GEOS, of course) and start with
		numbers as the second char, but will accept a letter if
		need be.

CALLED BY:	BNFDosExec
PASS:		nothing
RETURN:		ax	= ID to use
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This needn't be particularly fast, and there's
		not much to search, so we just pick a second char and
		linearly search the table to see if that ID's been taken yet.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BNFAllocID	proc	near
taskTable	local	BNF_MAX_TASKS dup(BNFTask)
		uses	bx, cx, dx, di, es
		.enter
	;
	; Find the current tasks.
	; 
		segmov	es, ss
		lea	di, ss:[taskTable]
		mov	bx, BNFAPI_FIND_TASKS
		call	BNFCall
		mov_tr	cx, ax	; cx <- # active tasks
		mov	ax, 'G' or ('1' shl 8)
idLoop:
		push	cx, di
checkLoop:
		cmp	es:[di].BNFT_id, ax	; this task have this ID?
		je	nextID			; yup -- can't use ID

		add	di, size BNFTask
		loop	checkLoop

		add	sp, 4		; discard table size & start. AX already
					;  holds ID for return.
		.leave
		ret
nextID:
	;
	; Restore table size and start.
	; 
		pop	cx, di
	;
	; Advance to next second char
	; 
		inc	ah
		cmp	ah, '9' + 1
		jne	idLoop
	;
	; Switch over to using letters as the second char. This all assumes
	; that there can be no more than 36 running tasks so not all
	; combinations of G with a lower-case letter can be used at once
	; 
		mov	ah, 'a'
			CheckHack <BNF_MAX_TASKS le 36>
		jmp	idLoop
BNFAllocID	endp

	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFContinueDosExec
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

BNFContinueDosExec method dynamic BNFClass, MSG_TD_CONTINUE_DOS_EXEC
spawnArgs	local	BNFSpawnStruct
		.enter
	;
	; Save frame block so we can free it when we're done.
	; 
		push	cx
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
	; Set up a BNFSpawnStruct for B&F to use.
	; 
		segmov	es, ss		; zero the thing out
		lea	di, ss:[spawnArgs]
		mov	cx, size spawnArgs
		clr	al
		rep	stosb
	    ;
	    ; Copy in the easy things. Working directory first.
	    ; 
		mov	si, offset DEA_cwd.DEDAP_path
		lea	di, ss:[spawnArgs].BNFSS_workDir
		mov	cx, size BNFSS_workDir
		rep	movsb
	    ;
	    ; Now copy the program to the progDir, keeping track of the final
	    ; backslash so we can truncate at the directory
	    ; line to the description field there.
	    ; 
		mov	si, offset DEA_prog.DEDAP_path
		lea	di, ss:[spawnArgs].BNFSS_progDir
saveBSPosition:
		mov	dx, di		
progDirLoop:
		lodsb
		stosb
		cmp	al, '\\' 
		je	saveBSPosition
		tst	al
		jnz	progDirLoop
		CheckHack <size DEDAP_path lt size BNFSS_progDir>

	;
	; Copy the final component to BNFSS_progName and the first part of
	; BNFSS_description
	; 
		push	ds
		segmov	ds, es
		mov	si, dx
		lea	di, ss:[spawnArgs].BNFSS_description
		clr	cx
progCopyLoop:
		lodsb
		mov	ds:[di+(BNFSS_progName-BNFSS_description)], al
		stosb
		tst	al
		loopne	progCopyLoop		; decrements cx too...
		dec	di

	;
	; Truncate BNFSS_progDir at the start of the final component, biffing
	; the trailing backslash if appropriate. Note that the path always
	; begins with a drive specifier, so we needn't worry about si being
	; the start of the field.
	; 
		mov	si, dx
		dec	si			; point to backslash
		cmp	{char}ds:[si-1], ':'	; root path?
		jne	truncateProgDir
		inc	si			; leave backslash alone, but
						;  biff first char of file
						;  name
truncateProgDir:
		mov	{char}ds:[si], 0
	;
	; Append the arguments to the program name in BNFSS_description.
	; The DEA_args array always begins with a space, so we needn't
	; put one in ourselves.
	; 
		add	cx, size BNFSS_description-1
		pop	ds			; ds <- DosExecArgs
		mov	si, offset DEA_args
		cmp	cl, ds:[DEA_argLen]
		jbe	copyArgs
		mov	cl, ds:[DEA_argLen]
copyArgs:
		rep	movsb
		clr	al
		stosb
	;
	; Copy the args to the BNFSS_args, null-terminated.
	; 
		mov	si, offset DEA_args
		mov	cl, ds:[DEA_argLen]
		clr	ch
		lea	di, ss:[spawnArgs].BNFSS_args
		rep	movsb
		clr	al
		stosb
	    ;
	    ; Allocate a task ID for the beast.
	    ; 
	    	call	BNFAllocID
		mov	{word}ss:[spawnArgs].BNFSS_id, ax
	    ;
	    ; XXX: what about a hot key?
	    ; 
	;
	; Ask the task switcher to create a new task.
	; 
		lea	di, ss:[spawnArgs]
		mov	bx, BNFAPI_SPAWN
		call	BNFCall
	;
	; Make fake keyboard BIOS call so B&F thinks it's safe to act.
	; 
		push	ax
		mov	ah, 1
		int	16h
		pop	ax
	;
	; Resume PC/GEOS now we're back.
	; 
		pop	ds			; ds <- dgroup
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
		push	ax			; save error code
		call	TCBImport
	;
	; And tell our agent to rebuild the express list entries.
	; 
		mov	ax, MSG_TA_REDO_TASKS
		mov	bx, handle TaskApp
		mov	si, offset TaskApp
		mov	di, mask MF_CALL
		push	bp
		call	ObjMessage
		pop	bp
		pop	ax
	;
	; If the spawn failed, tell the user about it now.
	;
		tst	ax
		jz	done

		push	bp
		mov	bp, offset cannotSpawnTask
		mov	dx, ax		; no 1st arg
		mov	si, ax		; no 2d arg
		call	TaskChunkError
		pop	bp
done:
		.leave
		ret

BNFContinueDosExec	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFAbortDosExec
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
BNFAbortDosExec method dynamic BNFClass, MSG_TD_ABORT_DOS_EXEC
		.enter
		mov	bx, cx
		call	MemFree
	; rough, huh?
		.leave
		ret
BNFAbortDosExec endm

Movable		ends
