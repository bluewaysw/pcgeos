COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bnfApplication.asm

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
	B&F-specific implementation of various TaskApplication messages
		

	$Id: bnfApplication.asm,v 1.1 97/04/18 11:58:10 newdeal Exp $

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
taskTable	local	BNF_MAX_TASKS dup(BNFTask)
		uses	bx, si, cx, dx
		.enter
	;
	; Find our own task index so we can skip that entry in the table.
	; 
		mov	bx, BNFAPI_GET_ACTIVE_TASK_NUM
		call	BNFCall
		mov	ss:[us], ax
	;
	; Fetch the table of tasks
	; 
		mov	bx, BNFAPI_FIND_TASKS
		segmov	es, ss
		lea	di, ss:[taskTable]
		call	BNFCall
		push	ax		; save # of tasks
	;
	; Create the array itself.
	; 
		mov	bx, size TATask
		clr	cx
		clr	si
		mov	al, mask OCF_IGNORE_DIRTY
		call	ChunkArrayCreate
	;
	; During this loop:
	; 	bx	= current task index
	; 	cx	= # tasks left to process
	; 	*ds:dx	= chunk array
	; 	ds:si	= task table
	; 	es	= object block
		pop	cx		; cx <- # valid tasks in table
		mov	dx, si		; *ds:dx <- chunk array
		clr	bx		; first task is #0
		segmov	es, ds		; es <- object block
		segmov	ds, ss		; ds:si <- task table
		lea	si, ss:[taskTable]
createLoop:		
		cmp	bx, ss:[us]
		je	nextTask
	;
	; Append another TATask record to the end of the array.
	; 
		push	cx, si
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
	; Copy the name in from B&F to TAT_name
	; 
		pop	si
		push	si
		add	si, offset BNFT_description
		mov	cx, BNF_TASK_NAME_LENGTH
			CheckHack <TAT_name eq 0>
		rep	movsb
	;
	; Make sure the thing is null-terminated
	; 
			CheckHack <BNF_TASK_NAME_LENGTH lt TASK_NAME_LENGTH>
		clr	al
		stosb
		pop	cx, si
nextTask:
	;
	; Advance to the next entry in the table.
	; 
		inc	bx
		add	si, size BNFTask
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
