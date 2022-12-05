COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		pccomData.asm

AUTHOR:		Robert Greenwalt, Nov 18, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/18/96   	Initial revision


DESCRIPTION:
		
	Code for the PCComData command.

	$Id: pccomData.asm,v 1.1 97/04/05 01:26:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Main		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We received some data - notify if needed.

CALLED BY:	ParseSeq
PASS:		ds, es - dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrData	proc	near
	uses	dx,si,bp, es
	.enter
EC <		call	ECCheckES_dgroup				>
EC <		call	ECCheckDS_dgroup				>
		PSem	es, dataSem, TRASH_BX
	;
	; Read the size
	;
		clrdw	es:[fSize]
		call	ComReadWithWait
		jc	toOutaHere
		mov	cl, al
		call	ComReadWithWait
		jnc	haveSize
toOutaHere:
		jmp	outaHere
haveSize:
		mov	ah, al
		mov	al, cl
		mov	dx, ax		; save it in dx
	;
	; Check if we can allocate it
	;
		tst	ax
		jz	toOutaHere
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		LONG_EC	jc	noMemory
		mov	es, ax
	;
	; Check if we can accept it.  If our remaining buffer size is
	; neg, we're full.
	;
		tst	ds:[dataBufferSize].high
		LONG_EC	js	noSpace
	;
	; Now, just read the thing
	;
		clr	di		; es:di = data buffer
		mov	cx, dx		; cx = size
loopTop:
		call	ComReadWithWait
EC<		jc	toFreeAbort					>
NEC<		jc	freeAbort					>
		stosb
		loop	loopTop
	;
	; update the space remaining
	;
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		sub	ds:[dataBufferSize].low, ax
		sbb	ds:[dataBufferSize].high, 0
	;
	; Send out the block
	;
		mov	cx, bx
		call	MemUnlock
		movdw	bxsi, ds:[datacallbackOD]
		mov	ax, ds:[datacallbackMSG]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
outaHere:
		VSem	ds, dataSem, TRASH_AX_BX
		.leave
		ret
EC<toFreeAbort:								>
EC<		jmp	freeAbort					>
noMemory:
		mov	ah, PCCAT_MEMORY_ALLOC_FAILURE
		jmp	abort
noSpace:
		mov	ah, PCCAT_DATA_BUFFER_FULL
abort:
		or	ds:[sysFlags], mask SF_EXIT	; mark for abort
		call	ComReadWithWait
freeAbort:
		call	MemFree
		jmp	outaHere
ScrData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMDATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send whatever to the remote machine

CALLED BY:	GLOBAL
PASS:		on stack:
		word - size of buffer
		fptr - to a buffer which contains data

RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_COMMAND_ABORTED
		ah - PCComAbortType

DESTROYED:	nothing

	Name	Date		Description
	----	----		-----------
	robertg	21 sep 1996	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMDATA	proc	far	bSize:word, myData:fptr
	uses	bx,ds,es,si,cx
	.enter
	;
	; some EC schme - check args
	;
EC<		pushdw	esdi						>
EC<		movdw	esdi, myData					>
EC<		Assert_fptr	esdi					>
EC<		add	di, bSize					>
EC<		dec	di						>
EC<		Assert_fptr	esdi					>
EC<		popdw	esdi						>
	;
	; OK, proceed..
	;
		call	ActiveStartupChecks
		jc	done
	;
	; Check for null - send nothing
	;
		tst	bSize
		jz	done
	;
	; send DA command
	;
		call	RobustCollectOn		; dest noth
		mov	ax, DATA_COMMAND
		call	PCComSendCommand	; dest ax
	;
	; Now send the Size
	;
		mov	ax, bSize
		call	ComWrite		; low byte ; dest noth
		mov	al, ah
		call	ComWrite		; high
		call	RobustCollectOff	; dest noth
		jc	error
	;
	; And send the data
	;
		call	RobustCollectOn
		segmov	es, ds, ax
		movdw	dssi, myData
		mov	cx, bSize
		call	ComWriteBlock		; comwriteblock is ok
						; with huge blocks if
						; RobustCollect is
						; on..
						; dest noth
		segmov	ds, es, ax
		call	RobustCollectOff

		mov	al, PCCRT_NO_ERROR
		jnc	done
error:
		mov	al, PCCRT_COMMAND_ABORTED
done:
		clr	ds:[err]
		call	ActiveShutdownDuties	; dest noth
EC<		Assert_PCComReturnType	al			>
	
	.leave
	ret
PCCOMDATA	endp
	SetDefaultConvention



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMSETDATANOTIFICATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to setup the notification and buffering for
		PCComData.

CALLED BY:	GLOBAL
PASS:		on stack
			datacallbackOptr
			datacallbackMSG
			dataBufferSize	- can't be negative!
RETURN:		al = PCComReturnType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Only let it be set once!  Simplifies things	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMSETDATANOTIFICATION	proc	far	dataBufferSZ:dword,
						callbackMsg:word,
						callbackOptr:optr
	uses	bx, si, ds
	.enter
		Assert ge	dataBufferSZ.high, 0
EC<		pushdw	bxsi						>
EC<		movdw	bxsi, callbackOptr				>
EC<		call	ECCheckOD					>
EC<		popdw	bxsi						>
		LoadDGroup	ds, ax
	;
	; Check for pre-existing data notification pointer
	;
		PSem	ds, dataSem, TRASH_AX_BX
		movdw	axsi, ds:[datacallbackOD]
		tst	ax
		mov	ax, PCCRT_IN_USE
		LONG_EC	jnz	shutdownDone
	;
	; Store the new stuff
	;
		movdw	axbx, callbackOptr
		movdw	ds:[datacallbackOD], axbx
		mov	ax, callbackMsg
		mov	ds:[datacallbackMSG], ax
		movdw	axbx, dataBufferSZ
		movdw	ds:[dataBufferSize], axbx
		mov	ax, PCCRT_NO_ERROR
shutdownDone:
		VSem	ds, dataSem, TRASH_BX
	.leave
	ret
PCCOMSETDATANOTIFICATION	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMWAIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait for a period - if no data, sound alarm

CALLED BY:	GLOBAL
PASS:		on stack:
		word - wait time in ticks (60/s)

		Must have set Data Notification (PCCOMSETDATANOTIFICATION) 
		prior to this call else PCCRT_NOT_INTIALIZED.

RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMWAIT	proc	far	waitTime:word
	uses	ds, bx, si, cx, dx
		.enter
		call	ActiveStartupChecks
		jc	done
	;
	; Check for data notification pointer
	;
		movdw	bxsi, ds:[datacallbackOD]
		tst	bx
		mov	ax, PCCRT_NOT_INITIALIZED
		jz	shutdownDone
EC<		call	ECCheckOD					>
	;
	; Set a new timer
	;
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, waitTime
		mov	dx, MSG_PCCOM_WAIT_ALARM
		call	TimerStart
		mov	ds:[waitTimer], bx
		mov	ds:[waitTimerID], ax
		mov	ax, PCCRT_NO_ERROR
shutdownDone:
		call	ActiveShutdownDuties
done:
		.leave
		ret
PCCOMWAIT	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMACKDATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We're finished with this data.

CALLED BY:	GLOBAL
PASS:		on stack
			hptr of data block you're acking
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	data block is freed

PSEUDO CODE/STRATEGY:
	The waitTimer is a synchronizing word - xchg it so that we
clear it the same time we sample it.  The alarm wont go off if it is clear.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMACKDATA	proc	far	oldData:hptr
	uses	ax, bx, ds
		.enter
		LoadDGroup	ds, ax
		clr	bx
		xchg	bx, ds:[waitTimer]
		mov	ax, ds:[waitTimerID]
		tst	bx
		jz	timerDone
		call	TimerStop
		clr	ds:[waitTimerID]
timerDone:
		PSem	ds, dataSem, TRASH_AX_BX
		mov	bx, oldData
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		add	ds:[dataBufferSize].low, ax
		adc	ds:[dataBufferSize].high, 0
		call	MemFree
		VSem	ds, dataSem, TRASH_AX_BX
		.leave
		ret
PCCOMACKDATA	endp
	SetDefaultConvention



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCPccomWaitAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait time is up - notify if needed

CALLED BY:	MSG_PCCOM_WAIT_ALARM
PASS:		*ds:si	= PCComClass object
		ds:di	= PCComClass instance data
		ds:bx	= PCComClass object (same as *ds:si)
		es 	= segment of PCComClass
		ax	= message #
RETURN:		
DESTROYED:	ax, bx, cx, dx, si, di, bp, es - but that's OK
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 1/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCCPccomWaitAlarm	method dynamic PCComClass, 
					MSG_PCCOM_WAIT_ALARM
	.enter
	;
	; Check if we've already sent data
	;
		LoadDGroup	es, ax
		movdw	bxsi, es:[datacallbackOD]
		mov	ax, es:[datacallbackMSG]
		tst	es:[waitTimer]
		jz	outaHere
	;
	; ok, send the notice
	;
		clr	cx
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
outaHere:
		.leave
		ret
PCCPccomWaitAlarm	endm

Main		ends
