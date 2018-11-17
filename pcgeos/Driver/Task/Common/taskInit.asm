COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskInit.asm

AUTHOR:		Adam de Boor, Sep 19, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/19/91		Initial revision


DESCRIPTION:
	Genesis.

	$Id: taskInit.asm,v 1.1 97/04/18 11:58:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize everything. This should be fun. The presence of
		the task-switcher has already been checked by our strategy
		routine when its DR_INIT function was called.

CALLED BY:	MSG_META_ATTACH
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TaskAttach	method	TaskDriverClass, MSG_META_ATTACH
	;
	; Wait for DRE_TEST_DEVICE to be called and taskProcessStartupOK to be
	; set appropriately.
	; 
		PSem	ds, taskProcessStartupSem, TRASH_AX_BX
		tst	ds:[taskProcessStartupOK]
		jnz	finishStartup
	;
	; Task-switcher not present, so we should bail.
	; 
		clr	cx, dx, bp, si
		jmp	ThreadDestroy

finishStartup:
	;
	; Deal with normal application cruft that would have been handled
	; by UserLoadApplication if we were loaded in the normal fashion.
	; 
		call	CreateLaunchBlock	; dx = block handle

if not _GEOSTS
		push	bx, dx, ds
		mov	bx, dx
		call	MemLock
		mov	ds, ax
		mov	ax, ds:[ALB_genParent].handle
		mov	si, ds:[ALB_genParent].chunk
		call	MemUnlock
		mov_tr	bx, ax			;^lBX:SI <- parent field
		mov	ax, MSG_GEN_FIELD_APP_STARTUP_NOTIFY
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Let the superclass do its thing...
	; 
		pop	bx, dx, ds
endif
		mov	di, offset TaskDriverClass
		mov	ax, MSG_META_ATTACH
		GOTO	ObjCallSuperNoLock
TaskAttach	endp

Resident	ends

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateLaunchBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need a launch block to deal with MSG_META_ATTACH, and
		we don't have one yet...

CALLED BY:	INTERNAL
		TaskAttach

PASS:		nothing

RETURN:		dx		- handle to AppLaunchBlock

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		do the same as UserLoadApplication does

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateLaunchBlock proc	far
		uses	ax, cx, bx, es, ds, si, di
		.enter

	;
	; Alloc a block big enough for the job
	;
        	mov     ax, size AppLaunchBlock
		mov     cx, (mask HAF_ZERO_INIT shl 8) or mask HF_SHARABLE \
				or ALLOC_DYNAMIC_NO_ERR_LOCK
		call    MemAlloc
		mov	es, ax			; es -> block
						;  Do NOT set ds there, as that
						;  screws up MF_FIXUP_DS in
						;  UserCallSystem

	;
	; Now locate the system field, to which we want to attach. We don't
	; want to attach to just the current field, as that might shut down
	; while the system is still active, and then where would we be?
	; 
		push	bx			;Save ALB handle

		
		mov	cx, cs
		mov	dx, offset LocateSystemField
		mov	bp, es			; bp <- ax for callback
		mov	ax, MSG_GEN_SYSTEM_FOREACH_FIELD
		call	UserCallSystem

	;
	; Fill in a filename within SP_TASK_SWITCH_DRIVERS, setting that as
	; our working dir.
	;
		mov	es:[ALB_appRef].AIR_diskHandle, SP_TASK_SWITCH_DRIVERS
		mov	es:[ALB_diskHandle], SP_TASK_SWITCH_DRIVERS
		mov	{word}es:[ALB_path], '\\' or (0 shl 8)
		segmov	ds, cs
		mov	si, offset ourName	; copy filename next.
		mov	di, offset ALB_appRef.AIR_fileName
nameLoop:
		lodsb				; get next char
		stosb				; store it even if zero
		tst	al			; if terminator, exit loop
		jnz	nameLoop

						; Set AppLaunchFlag to request
						; being opened in back of other
						; apps.  This will keep the
						; spooler from taking the focus
						; away from any other app
		mov	es:[ALB_launchFlags], mask ALF_OPEN_IN_BACK

	;
	; All done copying name over, that's really all we need, as everything
	; else is zero-initialized when the block is allocated.
	; 
		pop	bx			; restore handle
		mov	dx, bx
		call	MemUnlock
		.leave
		ret
CreateLaunchBlock endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocateSystemField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the passed field as the one to which we should
		attach, on the assumption it's the last, i.e. the system,
		field.

CALLED BY:	CreateLaunchBlock via MSG_GEN_SYSTEM_FOREACH_FIELD
PASS:		^lbx:si	= field
		ax	= segment of AppLaunchBlock
RETURN:		carry set to stop enumerating
DESTROYED:	es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocateSystemField proc	far
		.enter
		mov	es, ax
		mov	es:[ALB_genParent].handle, bx
		mov	es:[ALB_genParent].chunk, si
		clc
		.leave
		ret
LocateSystemField endp

if not _GEOSTS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin life as an application

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		ds = es = dgroup
		cx	= AppAttachFlags
		dx	= handle of AppLaunchBlock
		bp	= handle of extra block from state file, or 0 if none.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDOpenApplication method dynamic TaskDriverClass, MSG_GEN_PROCESS_OPEN_APPLICATION
		uses	ax, cx, dx, bp
		.enter

		mov	cx, handle TaskApp
		mov	dx, offset TaskApp
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
		call	GCNListAdd
	;
	; Fetch the initial batch of tasks...
	; 
		mov	ax, MSG_TA_REDO_TASKS
		mov	bx, cx
		mov	si, dx
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		mov	di, offset TaskDriverClass
		GOTO	ObjCallSuperNoLock
TDOpenApplication endm
endif

if not _GEOSTS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End life as an application

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		ds = es = dgroup
RETURN:		cx	= block to add to state file
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDCloseApplication method dynamic TaskDriverClass, MSG_GEN_PROCESS_CLOSE_APPLICATION
		uses	ax, cx, dx, bp
		.enter
		mov	cx, handle TaskApp
		mov	dx, offset TaskApp
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
		call	GCNListRemove
		.leave
	;
	; No extra state, thanks.
	; 
		clr	cx
		ret
TDCloseApplication endm
endif 
Movable		ends
