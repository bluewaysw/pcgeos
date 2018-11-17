COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskmaxApplication.asm

AUTHOR:		Adam de Boor, Oct  4, 1991

ROUTINES:
	Name			Description
	----			-----------
	METHOD_TA_BUILD_TASK_LIST
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/4/91		Initial revision


DESCRIPTION:
	TaskMax-specific implementation of various TaskApplication messages
		

	$Id: taskmaxApplication.asm,v 1.1 97/04/18 11:58:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAFetchTasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the array of current tasks from the switcher

CALLED BY:	EXTERNAL
       		MSG_TA_REDO_TASKS, MSG_TA_BUILD_TASK_LIST
PASS:		ds	= object block
RETURN:		*ds:ax	= chunk array of TATask structures. TAT_flags is
			  ignored
DESTROYED:	es, di, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAFetchTasks	proc	near
us		local	word
taskNameTable	local	word
		uses	bx, si, cx, dx
		.enter
	;
	; Create the array itself.
	; 
		mov	bx, size TATask
		clr	cx
		clr	si
		mov	al, mask OCF_IGNORE_DIRTY
		call	ChunkArrayCreate
		push	si		; save its chunk
	;
	; Now contact TaskMax to find out what tasks are running.
	; 
   		call	SysLockBIOS
		mov	ax, TMAPI_FIND_TASKS
		int	2fh
		call	SysUnlockBIOS

		mov	ss:[us], bx
		mov	ss:[taskNameTable], di
		clr	bx
		pop	dx
	;
	; During this loop:
	; 	bx	= current task index
	; 	cx	= # tasks left to process
	; 	*ds:dx	= chunk array
	; 	ds:si	= task IDs table
	; 	es	= object block

		segxchg	ds, es		; ds <- taskmax data space
					; es <- object block
createLoop:		
		lodsb			; al <- task ID
		cmp	bx, ss:[us]
		je	nextTask
		
	;
	; Append another TATask record to the end of the array.
	; 
		push	si, cx
		mov	si, dx
		push	ds
		segmov	ds, es
		call	ChunkArrayAppend
	;
	; Set the entry's index to the current task index.
	; 
		mov	ds:[di].TAT_index, bx
		pop	ds
	;
	; Copy the name in from TaskMax to TAT_name
	; 
		cbw			; zero-extend (always < 128)
			CheckHack <TM_TASK_NAME_LENGTH eq 8>
		shl	ax		; *8 b/c that's how big task names are
		shl	ax
		shl	ax
		add	ax, ss:[taskNameTable]
		mov_tr	si, ax
		mov	cx, TM_TASK_NAME_LENGTH
			CheckHack <TAT_name eq 0>
		rep	movsb
	;
	; Make sure the thing is null-terminated
	; 
		clr	al
		stosb
		pop	si, cx
nextTask:
	;
	; Advance to the next entry in the TASK_IDS table.
	; 
		inc	bx
		loop	createLoop

	;
	; Return *ds:ax = array
	; 
		mov_tr	ax, dx
		segmov	ds, es
		.leave
		ret
TAFetchTasks	endp

Movable	ends
