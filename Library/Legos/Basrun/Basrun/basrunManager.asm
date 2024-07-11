COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bw_hack.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/15/94		Initial version.

DESCRIPTION:
	hack to deal with getting DS = dgroup

	$Revision: 1.2 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include resource.def
include char.def
include geode.def
include object.def
include profile.def
include ec.def
include assert.def
include localize.def
include thread.def	
include stdapp.def
include resource.def

UseLib Legos/ent.def
include Legos/runheap.def
include Legos/Internal/runtask.def

include Internal/flowC.def
include Internal/threadIn.def
include Objects/inputC.def
include Internal/streamDr.def
include heapint.def

; EC  <COMP_E_TEXT	segment public "CODE" byte		>
; NEC <COMP_G_TEXT	segment public "CODE" byte		>
COMP_TEXT	segment public "CODE" byte
global _RunComponentLockHeap:far
global _RunComponentUnlockHeap:far
COMP_TEXT	ends
; NEC <COMP_G_TEXT	ends					>
; EC  <COMP_E_TEXT	ends					>
		
;;Warnings etype word, 300
RW_SOMETHING_STRANGE		enum Warnings, 300
RW_NULL_HUGE_ARRAY_IN_RTASK	enum Warnings
RW_NULL_STABLE_IN_RTASK		enum Warnings
RW_DESTROYING_RTASK_WITH_REFERENCES		enum Warnings
RW_OVERWRITING_BUGINFO_BLOCK	enum Warnings
RW_RTASKS_DO_NOT_MATCH		enum Warnings
RW_STACK_UNBALANCED		enum Warnings
RW_FUNC_CALL_WHEN_BUSY		enum Warnings
RW_FUNC_CALL_FAILED		enum Warnings
RW_FUNC_CALL_WHEN_DISABLE	enum Warnings


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PROFILEWRITEGENERICENTRY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ProfileWriteGenericEntry

CALLED BY:	GLOBAL

C DECLARATION:  extern void _far _pascal
		  ProfileWriteGenericEntry(word data, ProfileModeFlags flags,
					   ProfileEntryType type);
				

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 3/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BCHACK	segment resource

ifdef PROFILE
SetGeosConvention
PROFILEWRITEGENERICENTRY	proc	far		\
	dat: word
public PROFILEWRITEGENERICENTRY
	uses	ds
	.enter
		mov	ax, PET_GENERIC
		mov	bl, mask PMF_GENERIC
		mov	cx, ss:[dat]
		call	ProfileWriteGenericEntry
	.leave
	ret
PROFILEWRITEGENERICENTRY	endp
SetDefaultConvention
endif

SetGeosConvention

DOSERIALNOTIFYSTUFF	proc	far	driver:hptr, port:word, destObj:optr, destMsg:word
public DOSERIALNOTIFYSTUFF
	uses ax, bx, cx, dx, bp, si, di, ds, es
	.enter

	; load up the registers
	;
	mov	bx, ss:[driver]
	call 	GeodeInfoDriver			;ds:si <- ptr to info table

	movdw	cxdx, ss:[destObj]
	mov     ax, StreamNotifyType <1,SNE_DATA,SNM_MESSAGE>
	mov     bx, ss:[port]
	mov     bp, ss:[destMsg]		;must be last!
	mov	di, DR_STREAM_SET_NOTIFY
	call	ds:[si].DIS_strategy

	.leave
	ret
DOSERIALNOTIFYSTUFF	endp
SetDefaultConvention

setDSToDgroup	proc	far
	mov	ax, ds		; return old DS in ax
	segmov	ds, dgroup, dx
	ret
setDSToDgroup	endp
	public	setDSToDgroup


restoreDS	proc	far	oldDS:word
	.enter
	segmov	ds, oldDS, ax
	.leave
	ret
restoreDS	endp
	public restoreDS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunMainMessageDispatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	try to dispatch messages on queue from RunMainLoop

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunMainMessageDispatch	proc	far	rtaskHan_DONT_USE:hptr
		uses	ax,bx,cx,dx,bp,si,di
		.enter

	; can't use locals with borrowed stack
	;
		mov	bx, ss:[rtaskHan_DONT_USE]

		mov	di, 4096
		call	ThreadBorrowStackSpace
		push	di
		push	bx
dispatchLoop:
	; check HALT flag, never dispatch a message if the halt flag
	; is set, as if that message happens to be MSG_LA_STOP we
	; are in big trouble

	; on stack: rtaskHan, stack token
		pop	bx
		push	bx
		tst	bx
		jz	noTask
		push	ds
		call	MemLock
		mov	ds, ax
		cmp	ds:[RT_builderRequest], BBR_HALT
		call	MemUnlock
		pop	ds
		je	done
noTask:
		
	; I changed this loop to reget the count of the number of
	; messages so that if dispatching a message somehow causes
	; RunMainDispatch to get called in a recursive call to
	; RunMainLoop it doesn't try to send non-existant messages
		clr	bx
		call	GeodeInfoQueue
		tst	ax
		jz	done
		mov	di, mask MF_CALL
		call	QueueGetMessage
		mov_tr	bx, ax
		call	MessageDispatch
		loop	dispatchLoop
done:
		pop	di		; ignore the rtaskHan
		pop	di
		call	ThreadReturnStackSpace
		.leave
		ret
RunMainMessageDispatch	endp
	public RunMainMessageDispatch



		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BugSitAndSpinFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	filter out MSG_META_QUERY_IF_PRESS_IS_INK
CALLED BY:	BugSitAndSpin through MessageProcess
PASS:		ss:di = pointer to BugSitAndSpinStruct
		ax,bp,cx,dx - message stuff

RETURN:		will free up and clear the queueHandle if done
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	These messages are handled specially:

	<BSASS_msgToSeek>			stop filtering
	MSG_META_PTR				ignore
	MSG_META_QUERY_IF_PRESS_IS_INK		send canned reply
	MSG_META_RESERVED_1			toggle dispatch

	Default behavior is to store messages on another queue for later
	If the "dispatch" flag is set in BSASS, we dispatch the message
	normally instead.  This is used by the debugger to set properties

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BugSitAndSpinStruct	struct
	BSASS_newQueue		hptr
	BSASS_msgToSeek		word
	BSASS_dispatch		word	;debugger sets this
BugSitAndSpinStruct	end

BugSitAndSpinFilter	proc	far
		.enter
		pushf
		cmp	ax, ss:[di].BSASS_msgToSeek
		je	weAreOuttaHere
		cmp	ax, MSG_META_RESERVED_1
		je	maybeToggleDispatch
		tst	ss:[di].BSASS_dispatch
		jnz	dispatch
		cmp	ax, MSG_META_QUERY_IF_PRESS_IS_INK
		je	sendInkReply
		cmp	ax, MSG_META_PTR	; get rid of these useless guys
		je	ignore

	;
	; Default: post the message for later dispatching
	; this code is copied from DispatchFromUserDoDialog
	;
save::
		popf
		push	di
		mov	di, mask MF_RECORD
		jnc	haveStack
		ornf	di, mask MF_STACK
haveStack:
		call	ObjMessage
		mov	ax, di
		pop	di
		mov	bx, ss:[di].BSASS_newQueue
postDone:
		mov	si, sp
		clr	cx
		xchg	cx, ss:[si+4]
		mov	si, cx
		clr	di
		call	QueuePostMessage
done:
		.leave
		ret
	;
	; Only toggle if there are no messages waiting on queue
	; to avoid synchronization problems
	;
maybeToggleDispatch:
		push	ax,bx
		clr	bx
		call	GeodeInfoQueue
		tst	ax
		mov	dx, bx		; save queue handle (assume dx unused)
		pop	ax,bx
		jnz	resend
		not	ss:[di].BSASS_dispatch
		jmp	dispatch	; so caller unblocks
resend:
		popf
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov_tr	ax, di		; ax <- event
		mov	bx, dx		; bx <- current event queue
		jmp	postDone
	;
	; Dispatch the message normally
	;
dispatch:
		popf
		mov	di, mask MF_CALL
		jnc	haveStack2
		ornf	di, mask MF_STACK
haveStack2:
		call	ObjMessage
		jmp	done

	;
	; Ignore -- used for trivial messages
	;
ignore:
		popf
		jmp	done

	;
	; End dispatch loop in caller
	; use MSG_META_DUMMY as a flag to tell BugSitAndSpin we are
	; done spinning as we found the message we were seeking
	;
weAreOuttaHere:
		popf
		mov	ss:[di].BSASS_msgToSeek, MSG_META_DUMMY
		jmp	done

	;
	; Special-case for ink query message
	;
sendInkReply:
		popf
		
		push	di
		mov	ax, MSG_FLOW_INK_REPLY
		mov	cx, IRV_NO_INK
		mov	di, mask MF_CALL
		call	UserCallFlow
		pop	di
		jmp	done
BugSitAndSpinFilter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BugSitAndSpin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	wait for the magic message to send us on our way

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:	try what UserDoDialog does, save up messages
	in a separate queue, then put them back when we get the one we
	are waiting for
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BugSitAndSpin	proc	far	msgToSeek:word
info	local	BugSitAndSpinStruct
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	; inform components that we are pausing
		clr	bx
		mov	info.BSASS_dispatch, bx
		call	GeodeGetAppObject
		mov	ax, MSG_ENT_PAUSE
		mov	di, mask MF_CALL
		call	ObjMessage
		
		call	GeodeAllocQueue
		mov	info.BSASS_newQueue, bx	; save new queue in dx
		mov	ax, msgToSeek
		mov	info.BSASS_msgToSeek, ax
		clr	bx
		call	GeodeInfoQueue
pollLoop:
		push	bx, bp	
		call	QueueGetMessage
		mov	bx, ax
		lea	di, info	; pass this to callback
		clr	si
	; push fptr to callback routine onto stack
		push	SEGMENT_CS
		mov	ax, offset BugSitAndSpinFilter
		push	ax
		call	MessageProcess
		pop	bx, bp
		cmp	info.BSASS_msgToSeek, MSG_META_DUMMY
		jne	pollLoop

		mov	si, bx
		mov	bx, info.BSASS_newQueue
		mov	cx, si
		mov	di, mask MF_INSERT_AT_FRONT
		call	GeodeFlushQueue
		call	GeodeFreeQueue

	; inform components we are continuing
		clr	bx
		call	GeodeGetAppObject
		mov	ax, MSG_ENT_RESUME
		mov	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
BugSitAndSpin	endp
	public BugSitAndSpin

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunGetOrSetBCPropertyLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call a get property message

CALLED BY:	GetProperty
PASS:		on stack:
			fptr.RunHeapInfo
			optr	- component
			word	- message
			fptr.Componentdata
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		need to pass in word instead of byte to avoid alignment
		problems when calling from C
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunGetOrSetBCPropertyLow	proc	far rhi:fptr, comp:optr, mess:word, compData:fptr
	uses di, si, ds
	.enter
	movdw	bxsi, comp
	Assert_optr	bxsi

	mov	ax, mess	; Convert token back to message number
	add	ax, MSG_ENT_GET_PROPERTY_0
		
	movdw	dxcx, compData
	sub	sp, size GetPropertyArgs
	mov	di, sp
	movdw	ss:[di].GPA_compDataPtr, dxcx
	movdw	dxcx, rhi
	movdw	ss:[di].GPA_runHeapInfoPtr, dxcx
	mov	bp, di					; frame ptr	
	mov	di, mask MF_CALL or mask MF_STACK
	mov	dx, size GetPropertyArgs	
		
	call	ObjMessage
	add	sp, size GetPropertyArgs
	.leave
	ret
RunGetOrSetBCPropertyLow	endp
public RunGetOrSetBCPropertyLow


	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunDoBCActionLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do a byte-compile action

CALLED BY:	RunDoAction
PASS:		lot o stuff
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunDoBCActionLow	proc	far	rhi:fptr,
					comp:optr,
					retval:fptr,
					argv:fptr,
					argc:word,
					mess:word
	.enter
	Assert	fptr, retval
	Assert	fptr, argv
	
	sub	sp, size EntDoActionArgs
	mov	bx, sp
	mov	ax, argc
	mov	ss:[bx].EDAA_argc, ax
	movdw	ss:[bx].EDAA_argv, argv, ax
	movdw	ss:[bx].EDAA_retval, retval, ax
	movdw	ss:[bx].EDAA_runHeapInfoPtr, rhi, ax		
	movdw	bxsi, comp
	mov	di, mask MF_CALL or mask MF_STACK
	mov	dx, size EntDoActionArgs

	Assert	optr	bxsi
	mov	ax, mess	; Convert token back to message number
	add	ax, MSG_ENT_DO_ACTION_0
	mov	bp, sp
	call	ObjMessage
	add	sp, size EntDoActionArgs
	
	.leave
	ret
RunDoBCActionLow	endp
public RunDoBCActionLow

BCHACK	ends

RUNHEAP_TEXT	segment public "CODE" byte
SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunHeapIncRef_asm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Asm stub for RunHeapIncRef

CALLED BY:	GLOBAL
PASS:		ax	- RunHeapToken
		ds	- sptr.EntObjectBlock
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunHeapIncRef_asm	proc	far
	uses	ax,bx,cx,dx,es
	.enter
		push	ax
		call	RunComponentLockHeap_asm
		pushdw	dxax
ifdef __BORLANDC__
		call	_RunHeapIncRef
else
		call	RunHeapIncRef
endif
		add	sp, 6
		call	RunComponentUnlockHeap_asm
	.leave
	ret
RunHeapIncRef_asm	endp
public RunHeapIncRef_asm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunHeapDecRef_asm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Asm stub for RunHeapDecRef

CALLED BY:	GLOBAL
PASS:		ax	- RunHeapToken
		ds	- sptr.EntObjectBlock
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunHeapDecRef_asm	proc	far
	uses	ax,bx,cx,dx,es
	.enter
		push	ax
		call	RunComponentLockHeap_asm
		pushdw	dxax
ifdef __BORLANDC__
		call	_RunHeapDecRef
else
		call	RunHeapDecRef
endif
		add	sp, 6
		call	RunComponentUnlockHeap_asm
	.leave
	ret
RunHeapDecRef_asm	endp
public RunHeapDecRef_asm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunHeapAlloc_asm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Asm stub for RunHeapAlloc

CALLED BY:	External
PASS:		cx		- size
		bx		- RunHeapType
		dl		- init ref count
		^sds		- EntObjectBlock
		ax:di		- data to init with, ax:di = 0 for no init
RETURN:		ax		- RunHeapToken
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunHeapAlloc_asm	proc	far
		uses	bx,cx,dx,si,di,bp, es
		.enter
		mov	es, ax
		mov	si, dx				; ref count
		call	RunComponentLockHeap_asm

		sub	sp, size RunHeapAllocStruct
		mov	bp, sp
		movdw	ss:[bp].RHAS_rhi, dxax
		mov	ss:[bp].RHAS_type, bx
		mov	dx, si				; ref count
		mov	ss:[bp].RHAS_refCount, dl
		mov	ss:[bp].RHAS_size, cx
		movdw	ss:[bp].RHAS_data, esdi
ifdef __BORLANDC__
		call	_RunHeapAlloc
else
		call	RunHeapAlloc
endif
		add	sp, size RunHeapAllocStruct

		call	RunComponentUnlockHeap_asm
		
		.leave
		ret
RunHeapAlloc_asm	endp

public RunHeapAlloc_asm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunHeapLock_asm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Asm stub for RunHeapLock

CALLED BY:	External
PASS:		ax		- RunHeapToken
		ds		- sptr.EntObjectBlock
RETURN:		es:di		- ptr to locked data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunHeapLock_asm	proc	far
		uses	ax,bx,cx,dx,si,bp
		.enter
		mov	bx, ax			; save token
		call	RunComponentLockHeap_asm

		sub	sp, size RunHeapLockStruct
		mov	bp, sp
		movdw	ss:[bp].RHLS_rhi, dxax
		mov	ss:[bp].RHLS_token, bx
		lea	ax, ss:[bp].RHLS_eptr
		movdw	ss:[bp].RHLS_dataPtr, ssax
ifdef __BORLANDC__
		call	_RunHeapLockExternal
else
		call	RunHeapLockExternal
endif
		mov	bp, sp
		les	di, ss:[bp].RHLS_eptr
		add	sp, size RunHeapLockStruct

		call	RunComponentUnlockHeap_asm
		.leave
		ret
RunHeapLock_asm	endp
public	RunHeapLock_asm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunHeapUnlock_asm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Asm stub for RunHeapUnlock

CALLED BY:	External
PASS:		ax		- RunHeapToken
		ds		- sptr.EntObjectBlock
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunHeapUnlock_asm	proc	far
		uses	ax,bx,cx,dx,si,bp,es,di
		.enter
		mov	bx, ax			; save token
		call	RunComponentLockHeap_asm

		sub	sp, size RunHeapLockStruct
		mov	bp, sp
		movdw	ss:[bp].RHLS_rhi, dxax
		mov	ss:[bp].RHLS_token, bx
ifdef __BORLANDC__
		call	_RunHeapUnlockExternal
else
		call	RunHeapUnlockExternal
endif
		mov	bp, sp
		add	sp, size RunHeapLockStruct

		call	RunComponentUnlockHeap_asm
		.leave
		ret
RunHeapUnlock_asm	endp
public	RunHeapUnlock_asm
RUNHEAP_TEXT ends


COMPONEN_TEXT	segment public "CODE" byte


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunComponentLockHeap_asm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		^sds	- EntObjectBlock 
RETURN:		dx:ax	- fptr.RunHeapInfo
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunComponentLockHeap_asm	proc	far
		uses	bx,cx,si,di,bp, es
		.enter
		clr	ax
		pushdw	dsax
ifdef __BORLANDC__
		call	_RunComponentLockHeap
else
		call	RunComponentLockHeap
endif
		add	sp, size fptr
		.leave
		ret
RunComponentLockHeap_asm	endp
public RunComponentLockHeap_asm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunComponentUnlockHeap_asm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		^sds	- EntObjectBUnlock 
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunComponentUnlockHeap_asm	proc	far
		uses	ax,bx,cx,dx,si,di,bp, es
		.enter
		clr	ax
		pushdw	dsax
ifdef __BORLANDC__
		call	_RunComponentUnlockHeap
else
		call	RunComponentUnlockHeap
endif
		add	sp, size fptr
		.leave
		ret
RunComponentUnlockHeap_asm	endp
public RunComponentUnlockHeap_asm
	
COMPONEN_TEXT	ends

COMPONEN_TEXT	segment public "CODE" byte

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMCOPYVMCHAIN_FIX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a VMChain correctly

C FUNCTION:	VMCopyVMChain_FIX

C DECLARATION:	extern VMChain
			_far _pascal VMCopyVMChain(VMFileHandle sourceFile,
			       			   VMBlockHandle sourceChain,
			       			   VMFileHandle destFile);
CALLED BY:	GLOBAL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
VMCOPYVMCHAIN_FIX	proc	far	sourceFile:word, sourceChain:dword,
				destFile:word
	.enter	

	mov	bx, sourceFile
	mov	dx, destFile
	mov	ax, sourceChain.high
	mov	bp, sourceChain.low

;	DON'T DO THIS - It trashes BP first
;	movdw	bpax, sourceChain

	call	VMCopyVMChain
	mov	dx, bp
	xchg	dx, ax
	.leave
	ret

VMCOPYVMCHAIN_FIX	endp
public VMCOPYVMCHAIN_FIX


		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BasrunHandleSetOwner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	change owner of block to be basrun

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	12/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BASRUNHANDLESETOWNER	proc	far 	memHandle:hptr
		uses	bx
		.enter
		mov	ax, handle 0
		mov	bx, memHandle
		call	HandleModifyOwner
		.leave
		ret
BASRUNHANDLESETOWNER	endp
	public BASRUNHANDLESETOWNER

	SetDefaultConvention
COMPONEN_TEXT	ends
