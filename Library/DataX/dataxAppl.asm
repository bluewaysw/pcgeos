COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Data Exchange Library
FILE:		dataXAppl.asm

AUTHOR:		Robert Greenwalt, Nov  6, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 6/96   	Initial revision


DESCRIPTION:
		
	Implements internal DataX routines.

	Todo:
	  Probably could generalize the code that generates the
	  warning CUSTOM_BEHAVIOR_RETURNED_UNEXPECTED_ERROR_TYPE
	  by passing in the infoWord and the return type and 
	  checking to see if the return type falls within expected
	  values for the infoWord.  

	  Code the shutdown behavior like the init behavior as a
	  special case.  Right now it behaves like a special case, but
	  is coded in the main loop.  
	 

	$Id: dataxAppl.asm,v 1.1 97/04/04 17:54:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DataXAppl	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXAMetaIacpDataExchange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Startup a pipe element

CALLED BY:	MSG_META_IACP_DATA_EXCHANGE
PASS:		*ds:si	= DataXApplicationClass object
		ds:di	= DataXApplicationClass instance data
		ds:bx	= DataXApplicationClass object (same as *ds:si)
		es 	= segment of DataXApplicationClass
		ax	= message #
		cx:dx	= fptr to our DataXInfo
		bp	= IACPConnection
RETURN:		nothing
DESTROYED:	anything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Ok.  We need to set things up so that the early-init can copy
things into custom data (and things are in behavior-friendly layout)
but we want it on the stack later..  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 6/96   	Initial version
	robertg	 1/ 7/97	Reusable version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXAMetaIacpDataExchange	method dynamic DataXApplicationClass, 
					MSG_META_IACP_DATA_EXCHANGE
		.enter
	;
	; Setup our routineTable.
	;

		movdw	bxsi, ds:[di].DXA_iacpInitParameters
		call	DXSetCustomBehaviors	; bx = PEH handle
						; bp = connection
						; es = PEH segment
						; cx:dx = DataXInfo
		jc	sendAck
	;
	; Setup our instance data
	;

		call	DXCopyInitInfo		; bx = PEH handle
						; bp = connection
						; es = PEH segment
	;
	; Do initialization stuff - call the behavior
	;

		call	DXCallInitBehavior	; trashes all but
						; handle of PEH and
						; connection in bp
		jc	sendAck
	;
	; Startup our new thread. - needs handle of PEH
	;
		push	bp,bx,ax		; store IACPConnection
						; and PEH handle
		mov	al, PRIORITY_STANDARD
		mov	cx, bx			; preserve handle of datablock
		call	GeodeGetProcessHandle	
		mov	bp, bx			;^hbp <- process
		mov	bx, cx			; restore handle of datablock
		mov	cx, segment DataXFixed
		mov	dx, offset DXMain	; cx:dx = routine vector
		mov	di, 400h
		call	ThreadCreate
		pop	bp,bx,ax
		jc	threadError
	;
	; Send back an acknowledgement!
	;
sendAck:
		call	DXSendStartupAck
		.leave
		ret
threadError:
		call	MemFree
		mov	ax, mask DXSF_MEMORY_ERROR
		jmp	sendAck
DXAMetaIacpDataExchange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXSetCustomBehaviors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the behavior override table to this elements PEH block

CALLED BY:	DXAMetaIacpDataExchange - Element startup
PASS:		bxsi = lptr of CustomDataSizeAndRoutineTable
RETURN:		on error
			carry set
			ax = DataXFlags indicating error
		else
			carry clear
			bx - handle of new elements PEH block
			es - segment of datablock
DESTROYED:	ax, si, di, ds
SIDE EFFECTS:	
		Allocates the temp PEH block

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXSetCustomBehaviors	proc	near
		uses	cx
		.enter
		tst	bx
		jnz	haveCustom
	;
	; Just use the null terminator on our default table
	;
		mov	ax, segment DefaultBehaviorTable
		mov	ds, ax
		mov	si, (offset DefaultBehaviorTable + \
			(size DefaultBehaviorTable - size RoutineTableEntry))
		jmp	haveTable
haveCustom:
EC<		call	ECCheckMemHandle				>
	;
	; Lock down our CDSART block
	;
		call	MemLock
		mov	ds, ax
EC<		mov	ax, si						>
EC<		call	ECLMemExists					>
		mov	si, ds:[si]	; deref our custom routine table
haveTable:
	;
	; Measure the size of the RoutineTable
	;
		push	bx		; store CDSART handle
		segmov	es, ds
		mov	di, si
EC<		call	ECDXCheckRoutineTable				>
		clr	ax
		call	DXFindBehavior
		mov	ax, es:[di].RTE_routine.low	; get custom size
		sub	di, si		; di = size of custom RoutineTable
		add	di, size RoutineTableEntry	; size includes null
		push	di
	;
	; Allocate our datablock
	;
		add	ax, size PipeElementHeader
		push	ax		; ax = offset to custom routinetable
		add	ax, di		; add in the size of custom routinetable
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	es, ax
		pop	ax		; size of custom data + header
		pop	cx		; size of custom routines
		LONG_EC	jc	memError
	;
	; Start storing
	;
		mov	es:[PEH_customRoutines], ax
		mov	di, ax		; es:di = final start of routinetable

		ArbitraryCopy		; copy the table into our PEH
	;
	; Find the default behavior (simplifies DXFindBehavior, making
	; all searches faster)
	;
		mov	di, es:[PEH_customRoutines]
		mov	ax, DXIW_DEFAULT_BEHAVIOR
		mov	cx, bx
		call	DXFindBehavior
		jc	noDefault
		movdw	axbx, es:[di].RTE_routine
		movdw	es:[PEH_defaultRoutine], axbx
noDefault:
		clc
done:
		pop	bx
	;
	; and unlock the custom info (CDSART) block
	;
		pushf
		tst	bx
		jz	noBlock
		call	MemUnlock
noBlock:
		popf
		mov	bx, cx
	.leave
	ret
memError:
	;
	;ERROR!
	;
		mov	ax, mask DXSF_MEMORY_ERROR
		stc
		jmp	done
DXSetCustomBehaviors	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXFindBehavior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a routine table for a particular DXInfoWord

CALLED BY:	Internal
PASS:		es:di - fptr to a null terminated RoutineTable
		ax - DXInfoWord to search for
RETURN:		carry set if not found
		es:di - points to RoutineTable Entry
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXFindBehavior	proc	far
		.enter
EC<		call	ECDXCheckRoutineTable				>
		sub	di, size RoutineTableEntry
loopTop:
		add	di, size RoutineTableEntry
		mov	bx, es:[di].RTE_infoWord
		cmp	bx, ax
		je	done
		tst	bx
		jnz	loopTop
	;
	; Not found!
	;
		stc
done:
		.leave
		ret
DXFindBehavior	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXFindInheritedBehavior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find an inherited behavior.

CALLED BY:	DXMAIN, DXManulCallBehavior
PASS:		ax 	= DXInfoWord
RETURN:		same as DXFindBehavior
DESTROYED:	same as DXFindBehavior
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

 Inherited behaviors reside in the DefualtBehaviorTable.  Setup	es:di
 for call to DXFindBehavior.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg		2/ 6/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXFindInheritedBehavior	proc	far
	.enter
		mov	di, segment DefaultBehaviorTable
		mov	es, di
		mov	di, offset DefaultBehaviorTable
		call	DXFindBehavior
	.leave
	ret
DXFindInheritedBehavior	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXCopyInitInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy and analyse the passed in data

CALLED BY:	DXAMetaIacpDataExchange
PASS:		es:[0] = beginning of datablock
		cx:dx = fptr to DataXInfo
RETURN:		nothing
DESTROYED:	cx,di,si,ax
SIDE EFFECTS:	sets
		PEH_pipeDirection
		PEH_pipeToggle
		PEH_*Semaphore*

on error, sets PEH_pipeError

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXCopyInitInfo	proc	near
	.enter
EC<		pushdw	cxdx						>
EC<		call	ECDXCHECKDATAXINFO				>
	;
	; store the pointer to our DataXInfo
	;
		movdw	es:[PEH_dataXInfo], cxdx
	;
	; find our custom routines dgroup
	;
		call	DXFindDgroup
	;
	; Copy the semaphores
	;
		mov	ds, cx
		mov	si, dx
		add	si, offset DXI_intSemaphoreLeft
		mov	cx, (size hptr) * (4 / 2)	; four of
							; them, but we
							; do word moves
		mov	di, offset PEH_intSemaphoreLeft

		EvenCopy		; copy the semaphores

	;
	; Ok, now check out the semaphores to figure out our direction toggle
	;
		clr	di
		tst	es:[di].PEH_intSemaphoreLeft
		jz	leftmost
		tst	es:[di].PEH_intSemaphoreRight
		jz	rightmost
	;
	; We swing both ways - set up pipePorts so we can use it for
	; an xor toggle
	;
		mov	es:[di].PEH_pipeToggle, mask DXD_LEFT or mask DXD_RIGHT
leftmost:
		mov	es:[di].PEH_pipeDirection, mask DXD_RIGHT
		jmp	haveDirection
rightmost:
		mov	es:[di].PEH_pipeDirection, mask DXD_LEFT
haveDirection:
	.leave
	ret
DXCopyInitInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXCallInitBehavior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to let a custom behavior happen before we acknowledge

CALLED BY:	DXAMetaIacpDataExchange
PASS:		es:[0]= PEH_*
		bx = handle of PEH_*
RETURN:		on Error
			PEH_ block freed.
			ax = DataXStartupFlags indicating error
			carry set
		else
			nothing
DESTROYED:	everything except bp and bx
SIDE EFFECTS:	MAY REALLOCATE PEH BLOCK

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	1/ 7/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXCallInitBehavior	proc	near
	.enter
	;
	; Now find the behavior
	;
		mov	cx, bx			; preserve bx
		mov	ax, DXIW_INITIALIZE
		mov	di, es:[PEH_customRoutines]
		call	DXFindBehavior
		cmc
		jnc	notReentrant

		push	cx
		movdw	bxax, es:[di].RTE_routine
	;
	; setup for call:
	;	set DXBA_*
	;	set ds = PEH_dgroup
	;
		lds	si, es:[PEH_dataXInfo]
		push	ds
		push	si

		push	es
		mov	si, offset PEH_customData
		push	si

		push	es
		clr	cx
		push	cx

		mov	cx, es:[PEH_dgroup]
		mov	ds, cx

	;
	; And call it
	;
		call	ProcCallFixedOrMovable
	;
	; Now Fixup the stack
	;
		add	sp, size DataXBehaviorArguments
		pop	bx
		cmp	ax, DXET_NOT_REENTRANT
		je	notReentrant
		cmp	ax, DXET_REENTRANT
		jne	error
	;
	; ok, reentrant
	;
		mov	ax, mask DXSF_REENTRANT
EC<	Assert carryClear					>
		jmp	done
notReentrant:
		mov	ax, 0
EC<	Assert carryClear					>
done:
	.leave
	ret
error:
	;
	; had an error - free the PEH block and indicate it.
	;
EC <		cmp	ax, DXET_NO_ERROR			>
EC < 		jne	ecContinue				>
EC < 		WARNING CUSTOM_BEHAVIOR_RETURNED_UNEXPECTED_ERROR_TYPE >
EC < 	ecContinue:						>

		call	MemFree
		mov	ax, mask DXSF_PROTOCOL_ERROR
		stc
		jmp	done
DXCallInitBehavior	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXSendStartupAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send back an ack with our status

CALLED BY:	DXAMetaIacpDataExchange
PASS:		ax - DataXFlags
		bp - IACPConnection
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXSendStartupAck	proc	far
		.enter
	;
	; Record the ack - cx = NULL, dx = DataXFlags
	;
		clr	cx
		mov	dx, ax
		mov	ax, MSG_META_IACP_DATA_EXCHANGE
		mov	di, mask MF_RECORD
		mov	bx, segment MetaClass
		mov	si, offset MetaClass
		call	ObjMessage
	;
	; and send the message
	;
		mov	bx, di
		mov	dx, TO_SELF
		clr	cx
		mov	ax, IACPS_SERVER
		call	IACPSendMessage
		.leave
		ret
DXSendStartupAck	endp



DataXFixed		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXMAIN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Main routine of the pipe mechanism.

CALLED BY:	ThreadCreate
PASS:		cx = hptr of datablock
RETURN:		Dont!  Jmp to ThreadDestroy instead.
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXMAIN	proc	far
	args	local	DataXBehaviorArguments
	ForceRef	args
	.enter
	;
	; startup
	;
		call	DXSetStack
		mov	bx, ss:[bp].PEH_dgroup
		mov	ds, bx
	;
	; Do post-thread init
	;
		mov	ax, DXIW_POST_THREAD_INITIALIZE
		segmov	es, ss, di
		mov	di, ss:[bp].PEH_customRoutines
		call	DXFindBehavior
		jc	noInit
		movdw	bxax, es:[di].RTE_routine
		call	ProcCallFixedOrMovable
	;
	; Now, sleep on your rightmost
	;
noInit:
		mov	bx, ss:[bp].PEH_intSemaphoreRight
		tst	bx
		jnz	haveSema
		mov	bx, ss:[bp].PEH_intSemaphoreLeft
haveSema:
		call	ThreadPSem
loopTop:
		les	di, ss:[bp].PEH_dataXInfo
	;
	; Allow momentary access to the InfoWord (used by the shutdown
	; to synchronize setting the InfoWord)
	;
		mov	bx, es:[di].DXIDXI_infoWordSema
		call	ThreadVSem
		call	ThreadPSem
	;
	; evaluate the infoWord - first check for a system info word 
	; (in which case we will call the DXSystemInfoWord procedure
	; to handle the logic, simplifying this procedure and making
	; it more efficient)
	;
		mov	ax, es:[di].DXI_infoWord
		cmp	ax, DXIW_NON_SYSTEM_INFO_WORDS
	;
	; do it this way (jump to a jump) so it won't jump in the 
	; common case (not a system word).  A conditional jump
	; won't reach.
	;
		jbe	systemWord			
	;
	; Look for a custom behavior
	;
		segmov	es, ss, di
		mov	di, ss:[bp].PEH_customRoutines
		call	DXFindBehavior
		jnc	haveRoutine
	;
	; Look for a default behavior
	;
		tst	{word}ss:[bp].PEH_defaultRoutine.segment
		jz	useInherited
		movdw	bxax, ss:[bp].PEH_defaultRoutine
		jmp	haveRoutineLoaded
systemWord:
		jmp 	DXSystemInfoWord	

useInherited:
	;
	; Look for an inherited behavior
	;
		call	DXFindInheritedBehavior
		jc	noRoutine
haveRoutine:
		movdw	bxax, es:[di].RTE_routine

haveRoutineLoaded:
	;
	; make sure everything looks ok
	;	
		CheckArguments
	;
	; and go...
	;
		call	ProcCallFixedOrMovable
	;
	; make sure nothing important was trashed
	;
	 	CheckArguments

routineExecuted	label near
		cmp	ax, DXET_NO_ERROR
		jne	routineErrorOrInheritedBehavior
noRoutine	label near
	;
	; OK, toggle the direction
	;
		SemaphoreTwiddle
		jmp	loopTop


routineErrorOrInheritedBehavior:
	;
	; Check for DXET_USE_INHERITED_BEHAVIOR
	;
		les	di, ss:[bp].PEH_dataXInfo
		cmp	ax, DXET_USE_INHERITED_BEHAVIOR
		jne	isError
		mov	ax, es:[di].DXI_infoWord
		jmp	useInherited
	;
	; We generated an error!  Store the error, and skip the dir-toggle 
	; so we go back the way we came.
	;
isError:
		mov	{word}es:[di].DXI_miscInfo, ax
		mov	es:[di].DXI_infoWord, DXIW_ERROR
		mov	al, ss:[bp].PEH_pipeToggle
		xor	ss:[bp].PEH_pipeDirection, al
		jmp	noRoutine
	.leave	.unreached
DXMAIN	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXSystemInfoWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We found a system infoWord.  This routine is a special
		case of the normal DXMAIN loop.  Special checks and
		other "unclean" things go here because a system word
		is both unique and uncommon in its operation.
CALLED BY:	DXMAIN
PASS:		nothing passed, jump from DXMAIN directly
RETURN:		nothing, jump back to DXMAIN
DESTROYED:	everything, most of the time
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Check to see if the InfoWord is invalid 
	<copy algorithm as in DXMAIN, except omit the default case>
	Check if the initial InfoWord was _CLEAN_SHUTDOWN, if so, do some
	  special stuff like restoring the infoWord, forcing ax to 
	  DXET_USE_INHERITED_BEHAVIOR etc.
	Jump back to DXMAIN

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	2/ 6/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXSystemInfoWord	proc	near
	;
	;	Store current infoWord
	;
		mov	es:[di].DXIDXI_oldInfoWord, ax
	; 
	; The infoWord should *never* be one of the following:
	;	DXIW_NULL
	;	DXIW_NON_SYSTEM_INFO_WORDS
	;
EC <		cmp	ax, DXIW_NULL					>
EC <		ERROR_E	INVALID_INFO_WORD				>
EC <		cmp	ax, DXIW_NON_SYSTEM_INFO_WORDS			>
EC <		ERROR_E INVALID_INFO_WORD				>

		segmov	es, ss, di
		mov	di, ss:[bp].PEH_customRoutines
		call	DXFindBehavior
		jnc	systemHaveRoutine
	;
	; don't use the custom defined default routine for system
	; infoWords, but do search for an Inherited Behavior
	;
		call	DXFindInheritedBehavior
	;
	; Jump back to DXMAIN if no routines found
	;
		jnc	systemHaveRoutine
		jmp	noRoutine

systemHaveRoutine:
		movdw	bxax, es:[di].RTE_routine
		call	ProcCallFixedOrMovable
	; 
	; Make sure routine did not trash arguments
	;
		CheckArguments

		les	di, ss:[bp].PEH_dataXInfo
		cmp	es:[di].DXIDXI_oldInfoWord, DXIW_CLEAN_SHUTDOWN
		jne	notShutDown
if ERROR_CHECK
	;
	; Fatal Error if old info word doesn't match info word now.
	; That means someone isn't playing nice.
	;
		cmp	es:[di].DXI_infoWord, DXIW_CLEAN_SHUTDOWN
		ERROR_NE ROUTINE_TRASHED_SYSTEM_INFO_WORD
	;	
	; Issue a warning if the custom behavior for shutdown did not
	; return DXET_USE_INHERITED_BEHAVIOR
	;	
		cmp	ax, DXET_USE_INHERITED_BEHAVIOR
		WARNING_NE CUSTOM_BEHAVIOR_RETURNED_UNEXPECTED_ERROR_TYPE
endif	; ERROR_CHECK
	; 
	; prevent any misbehaved pipe elements from mucking up our shutdown!
	;
		mov	es:[di].DXI_infoWord, DXIW_CLEAN_SHUTDOWN
		mov	ax, DXET_USE_INHERITED_BEHAVIOR

notShutDown:
	;
	; Go back to DXMAIN
	;	
		jmp	routineExecuted

DXSystemInfoWord	endp

DataXFixed		ends

DataXAppl		ends
