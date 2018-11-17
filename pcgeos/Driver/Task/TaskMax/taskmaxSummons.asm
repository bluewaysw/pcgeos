COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskmaxSummons.asm

AUTHOR:		Adam de Boor, Oct  1, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/ 1/91	Initial revision


DESCRIPTION:
	Special subclass of GenInteraction to initialize the control box each
	time it comes up.
		

	$Id: taskmaxSummons.asm,v 1.1 97/04/18 11:58:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMSVisBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special build handler to decide some things about how our
		box should like, like should we even display the EMS limit.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= TaskMaxSummons object
		other spec-build-type-things, none of which we use
RETURN:		?
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
emm_device_name	char	"EMMXXXX0"	;guaranteed name of EMM driver
emmPermName	char	"emm     "	;permanent name of our EMM swap driver

EMM_INT		equ	67h

TMSVisBuild	method dynamic TaskMaxSummonsClass, MSG_SPEC_BUILD
		uses	ax, cx, dx, bp
		.enter
	;
	; See if there's an EMS manager around. And no, we can't just look
	; for our having loaded emm.geo. An EMM will always have the
	; string EMMXXXX0 at the DH_name field of the device header located
	; at the base of the segment pointed to by the int 67h vector.
	; 

		push	ds, es, si

		clr	ax
		mov	es, ax
		mov	es, es:[EMM_INT*size fptr].segment
		mov	di, offset DH_name
		segmov	ds, cs
		mov	si, offset emm_device_name
		mov	cx, length emm_device_name
		repe	cmpsb
		pop	ds, es, si
		je	doEMS
	;
	; 10/28/91: wheee. The above comment is slightly off. On some systems,
	; the protection mechanisms in the EMM driver will revector int 67h,
	; and the driver doesn't have EMMXXXX0 at the base of its idata, so
	; we also have to look for our emm driver being loaded.
	;
		push	es, di, dx
		segmov	es, cs
		mov	di, offset emmPermName
		mov	ax, length emmPermName
		clr	bx
		mov	cx, mask GA_DRIVER
		clr	dx
		call	GeodeFind
		pop	es, di, dx
		jnc	noEMS
doEMS:
	;
	; Manager present. Find how many pages there are total and make that
	; the maximum value for the EMSLimitRange
	; 
		call	SysLockBIOS
		mov	ah, 42h		; get page count
		int	EMM_INT		; bx <- free pages, dx <- total pages
		call	SysUnlockBIOS

		mov	cl, 4
		shl	dx, cl		; *16 to get Kb
		clr	cx		; dx.cx <- max
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		push	si
		mov	bx, handle EMSLimitRange
		mov	si, offset EMSLimitRange
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
	;
	; Take note that EMS stuff needs doing.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].TaskMaxSummons_offset
		mov	ds:[di].TMSI_doEMSStuff, TRUE
	;
	; Deal with the clipboard-enable exclusive, now we know we've got
	; a generic parent.
	;
setClipboardExcl:
		push	si
		mov	bx, handle CopyPasteList
		mov	si, offset CopyPasteList
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, es:[tmcbEnabled]
		clr	dx		; no indeterminate
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si

passItUp:
		.leave
		mov	di, offset TaskMaxSummonsClass
		CallSuper	MSG_SPEC_BUILD
		ret
noEMS:
	;
	; No manager present, so set the range not usable.
	; 
		push	si
		mov	bx, handle EMSLimitRange
		mov	si, offset EMSLimitRange
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
		jmp	setClipboardExcl
TMSVisBuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMSVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for VIS_OPEN to initialize the list of active tasks
		before the control box comes up on screen

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= TaskMaxSummons object
		other VIS_OPEN related stuff that we ignore
RETURN:		?
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SWAP_INFO_BUF_SIZE	equ	16		; should be more than ample

TMSVisOpen	method dynamic TaskMaxSummonsClass, MSG_VIS_OPEN
		uses	ax, cx, dx, bp, es
		.enter
		assume	ds:Interface
		push	si
	;
	; Tell ourselves nothing's been selected so we disable the Run and
	; Delete triggers.
	; 
		clr	bp
		mov	ax, MSG_TMS_TASK_SELECT
		call	ObjCallInstanceNoLock
	;
	; Nuke any tasks currently in the list. This should cause us to be
	; notified that there's no exclusive and we'll disable the Run and
	; Delete triggers.
	; 
		mov	bx, handle ActiveTaskList
		call	ObjSwapLock
		mov	si, offset ActiveTaskList
		mov	ax, MSG_GEN_DESTROY
		mov	dx, VUM_NOW
		clr	bp
		push	bx
		call	GenSendToChildren
		
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		clr	dx		; not indeterminate
		call	ObjCallInstanceNoLock

		pop	bx
		call	ObjSwapUnlock
	;
	; Have our application object rebuild the list.
	; 
		mov	cx, bx
		mov	dx, si
		mov	bx, handle TaskApp
		mov	si, offset TaskApp
		mov	ax, MSG_TA_BUILD_TASK_LIST
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Figure the swap space used and available and tell the user
	; about it.
	; 
		mov	ax, TMAPI_GET_SWAP_INFO
		call	TMInt2f

		sub	sp, SWAP_INFO_BUF_SIZE
		segmov	es, ss
		mov	di, sp

		mov_tr	ax, dx	; ax <- kb free

	    ; convert kb free to ascii on the stack
		call	convertToAscii

	    ; add tag
			CheckHack <segment kbText eq segment TaskControl>
		mov	si, ds:[kbText]
		ChunkSizePtr	ds, si, cx
		rep	movsb
		
	;
	; Set the text for the SwapSpaceInfo object to be what we just figured.
	; 
		mov	bp, sp
		mov	dx, ss		; dx:bp <- fptr
		clr	cx		; null-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	bx, handle SwapSpaceInfo
		mov	si, offset SwapSpaceInfo
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Clear the stack.
	; 
		add	sp, SWAP_INFO_BUF_SIZE

	;
	; Fetch the current limit and set it as the value for the range, if
	; we're doing that sort of thing.
	; 
		pop	si
		mov	di, ds:[si]
		add	di, ds:[di].TaskMaxSummons_offset
		tst	ds:[di].TMSI_doEMSStuff
		jz	passItUp

		mov	ax, TMAPI_GET_MAX_LIM
		call	TMInt2f
		mov	cl, 4
		shl	dx, cl		; * 16 to convert to Kb
		clr	cx		; dx.cx <- value
		clr	bp		; not indeterminate
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		push	si
		mov	si, offset EMSLimitRange
		mov	bx, handle EMSLimitRange
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
passItUp:
		.leave
		mov	di, offset TaskMaxSummonsClass
		CallSuper	MSG_VIS_OPEN
		ret
	;--------------------
	; routine to convert ax to ascii at es:di, advancing es:di beyond
	; the result.
	; Pass:		ax	= number to convert
	;		es:di	= place to store result
	; Return:	es:di	= byte after number
	; Destroy:	cx, dx
convertToAscii:
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii
		add	di, cx
		retn
TMSVisOpen	endm

assume	ds:dgroup



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMSVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle EMS limit stuff when the box comes down

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= TaskMaxSummons object
		ds:di	= TaskMaxSummonsInstance
		other vis-close things
RETURN:		?
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMSVisClose	method dynamic TaskMaxSummonsClass, MSG_VIS_CLOSE
		uses	ax, cx, dx, bp
		.enter
		tst	ds:[di].TMSI_doEMSStuff
		jz	passItUp
		
		push	si
		mov	bx, handle EMSLimitRange
		mov	si, offset EMSLimitRange
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage	; dx.cx <- value
		mov	cl, 4
		shr	dx, cl		; convert to pages again
		mov	ax, TMAPI_SET_MAX_LIM
		call	TMInt2f
		pop	si
passItUp:
		.leave
		mov	di, offset TaskMaxSummonsClass
		CallSuper	MSG_VIS_CLOSE
		ret
TMSVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMSTaskSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a task has been selected (or that no tasks are
		selected) and enable/disable the Run & Delete triggers
		appropriately

CALLED BY:	MSG_TMS_TASK_SELECT
PASS:		*ds:si	= TaskMaxSummons object
		cx	= index from selected entry
		dl	= GenItemGroupStateFlags
		bp	= number of selections
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMSTaskSelect	method dynamic TaskMaxSummonsClass, MSG_TMS_TASK_SELECT
		.enter
		mov	ax, MSG_GEN_SET_ENABLED
		tst	bp
		jnz	enableDisable
		mov	cx, -1			; flag no task selected
		mov	ax, MSG_GEN_SET_NOT_ENABLED
enableDisable:
		mov	ds:[di].TMSI_curTask, cx
		mov	bx, handle TaskRunTrigger
		call	ObjSwapLock
		push	ax
		mov	si, offset TaskRunTrigger
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		pop	ax
		CheckHack <segment TaskDeleteTrigger eq segment TaskRunTrigger>
		mov	si, offset TaskDeleteTrigger
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		call	ObjSwapUnlock
		.leave
		ret
TMSTaskSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMSRunSelectedTask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run the currently-selected task.

CALLED BY:	MSG_TMS_RUN_SELECTED_TASK
PASS:		*ds:si	= TaskMaxSummons object
		ds:di	= TaskMaxSummonsInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMSRunSelectedTask method dynamic TaskMaxSummonsClass,
					MSG_TMS_RUN_SELECTED_TASK
		.enter
	;
	; Fetch the current exclusive while clearing it out.
	; 
		mov	dx, -1
		xchg	ds:[di].TMSI_curTask, dx
		cmp	dx, -1
		je	done		; => this call was spurious,
					;  somehow
	;
	; Send a message to our process to perform the switch.
	; 
		mov	ax, MSG_TD_SWITCH
		mov	bx, handle 0
		clr	di
		call	ObjMessage
done:
		.leave
		ret
TMSRunSelectedTask endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMSDeleteSelectedTask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the currently-selected item to biff its task.

CALLED BY:	MSG_TMS_DELETE_SELECTED_TASK
PASS:		*ds:si	= TaskMaxSummons object
		ds:di	= TaskMaxSummonsInstance
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMSDeleteSelectedTask method dynamic TaskMaxSummonsClass, MSG_TMS_DELETE_SELECTED_TASK
		.enter
		mov	cx, -1
		xchg	cx, ds:[di].TMSI_curTask
		cmp	cx, -1
		je	done		; => spurious call
		
		mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
		mov	si, offset ActiveTaskList
		mov	bx, handle ActiveTaskList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		jnc	done		; => item doesn't exist?

		mov	ax, MSG_TI_NUKE_TASK
		mov	bx, cx
		mov	si, dx
		clr	di
		call	ObjMessage
done:
		.leave
		ret
TMSDeleteSelectedTask endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMSAddNewShell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new task running the command interpreter
		defined by the COMSPEC environment variable.

CALLED BY:	MSG_TMS_ADD_NEW_SHELL
PASS:		*ds:si	= TaskMaxSummons object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nullStr		char	0
TMSAddNewShell	method dynamic TaskMaxSummonsClass, MSG_TMS_ADD_NEW_SHELL
		.enter
		push	ds, si
	;
	; Set registers for DosExec:
	; 	ds:si	= path of program to run (null string => command.com)
	;	bx	= disk handle for same (0 => use drive letter in
	;		  program path)
	; 	es:di	= arguments (none)
	; 	dx:bp	= working directory for program (null pointer => the
	;		  directory from which we were run)
	;	ax	= disk handle for same (0 => use drive letter in
	;		  path)
	;	cl	= DosExecFlags (task is interactive)
	;
		clr	dx, bp, ax	; null cwd => boot path

		segmov	ds, cs, si
		mov	es, si
		mov	si, offset nullStr	; ds:si <- ""
		mov	di, si			; es:di <- ""

		clr	bx	; no disk handle for program path
		mov	cx, mask DEF_INTERACTIVE
		call	DosExec

		pop	ds, si
		jnc	done
	;
	; Couldn't execute the shell. We assume it's because the thing doesn't
	; exist, so go through all the folderol of putting up a standard
	; box from the UI thread.
	; 
		mov	dx, size GenAppDoDialogParams
		sub	sp, dx
		mov	bp, sp			; SS:BP holds the structure
	;
	; Summons is a custom error acknowledge box.
	; 
		mov	ss:[bp].SDP_customFlags, CustomDialogBoxFlags <
			1,			; is system modal
			CDT_ERROR,		; error message
			GIT_NOTIFICATION,	; requiring acknowledgement
			0			; not destructive
		>
	;
	; Set the format string (chunk within TaskStrings is in DI)
	; 
		mov	bx, handle TaskStrings
		call	MemLock
		mov	ss:[bp].SDP_customString.segment, ax
		mov	es, ax
		assume	es:TaskStrings
		mov	ax, es:[couldNotExecShell]
		mov	ss:[bp].SDP_customString.offset, ax
	;
	; Don't need to notify anyone when done.
	; 
		clr	ax
		mov	ss:[bp].GADDP_finishOD.handle, ax
		mov	ss:[bp].GADDP_finishOD.chunk, ax
		mov	ss:[bp].GADDP_message, ax
	;
	; Zero out things we don't use.
	;
		clrdw	ss:[bp].SDP_helpContext, ax
		clrdw	ss:[bp].SDP_customTriggers, ax
		clrdw	ss:[bp].SDP_stringArg1, ax
		clrdw	ss:[bp].SDP_stringArg2, ax
	;
	; Call our application to do the dirty work.
	; 
		mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		mov	bx, handle TaskApp
		mov	si, offset TaskApp

		mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		add	sp, size GenAppDoDialogParams
	;
	; Release the string block...
	; 
		mov	bx, handle TaskStrings
		call	MemUnlock
		assume	es:dgroup
done:
		.leave
		ret
TMSAddNewShell	endm

Movable		ends
