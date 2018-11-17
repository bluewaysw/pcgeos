COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Object
FILE:		objectClass.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ObjCallInstance		Call a method of the given instance's class
   GLB	ObjCallInstanceNoLock	Call a method of the given instance's class
				without locking the instance.
   GLB	ObjCallInstanceNoLockES	Call a method of the given instance's class,
				fixing up both DS and ES
   GLB	ObjCallClassNoLock	Call a method of the given class without
				locking the instance.
   GLB	ObjCallSuperNoLock	Call a method of the given class's superclass
				without locking the instance.
   GLB	ObjCallMethodTable	Call a method of the given class (primative)
   GLB	ObjFindClass		Find the address of a given class

CALLED BY:	GLOBAL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version

DESCRIPTION:
	This file contains the kernel's object related routines

	$Id: objectClass.asm,v 1.1 97/04/05 01:14:43 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

FUNCTION:	SendMessage

DESCRIPTION:	Send a message to an object

CALLED BY:	INTERRNAL
		ObjMessage

PASS:
	bx:si - ^lbx:si = object descriptor
	di - flags -- MessageFlags:
		MF_FIXUP_DS - Return ds pointing to same block
		MF_FIXUP_ES - Return es pointing to same block
		MF_CALL	    - don't preserve ax, cx, dx, bp
	ax - method
	cx, dx, bp - data

RETURN:
	ax, cx, dx, bp - return values
	di - 0

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

SendMessage	proc	far

	xchg	ax, di			;ax <- MessageFlags (produces smaller
					; code, below), di <- method #

	; push correct handles for fixups and push address for later

	test	ax,mask MF_FIXUP_DS or mask MF_FIXUP_ES
	jnz	dsOrBoth

	; fixup none

EC <	call	NullDSIfObjBlock					>
	push	ds

	test	ax,mask MF_CALL
	mov	ax,offset SM_fixupNone		;assume call
	jmp	pushESAndBranch

dsOrBoth:

EC <	push	di							>
EC <	mov	di, ds:[LMBH_handle]					>
EC <	call	CheckMemHandleNSDI					>
EC <	pop	di							>

	push	ds:[LMBH_handle]

	test	ax,mask MF_FIXUP_ES
	jz	dsOnly

	; fixup both

EC <	push	di							>
EC <	mov	di, es:[LMBH_handle]					>
EC <	call	CheckMemHandleNSDI					>
EC <	pop	di							>

	push	es:[LMBH_handle]

	test	ax,mask MF_CALL
	mov	ax,offset SM_fixupDSES		;assume call
	jnz	gotOffset
	jmp	pushGotOffset

dsOnly:

	test	ax,mask MF_CALL
	mov	ax,offset SM_fixupDS		;assume call

pushESAndBranch:
EC <	call	NullESIfObjBlock					>
	push	es
	jnz	gotOffset

pushGotOffset:
	push	ax
	push	di, cx, dx, bp			;original ax is in DI now
	mov	ax, offset popThenFixup

gotOffset:
	push	ax				;save fixup offset

	xchg	ax, di				;ax <- method num (1-byte inst)

	; Check for process or object

	LoadVarSeg	ds, di
	cmp	ds:[bx].HT_handleSig,SIG_THREAD
	jz	callThread
	cmp	ds:[bx].HG_owner, bx
	je	callThread

	FastLock1	ds, bx, di, 1, 2
	jc	SM_fullyDiscarded
afterLock:

if	ANALYZE_WORKING_SET
	call	WorkingSetObjBlockInUse
endif

	; di = segment of locked block
	mov	ds,di

NEC <	cmp	bx, ds:[LMBH_handle]					>
NEC <	jnz	necError						>

	mov	di,ds:[si]
	les	di,ds:[di][MB_class]

	call	ObjCallMethodTableSaveBXSI	; ds <- idata

if	ANALYZE_WORKING_SET
	call	WorkingSetObjBlockNotInUse
endif

	; Unlock the block (preserves the carry)

	FastUnLock	ds, bx, di

	; recover segment registers

	retn				;*** Go to fixup offset, one of:
					;	SM_fixupNone
					;	SM_fixupDS
					;	SM_fixupDSES
					;	popThenFixup

	; slow part of lock

	FastLock2	ds, bx, di, 1, 2

	; send to this thread
callThread:
	;
	; point ds to the thread's dgroup
	;
	mov	ds, ss:[TPD_dgroup]
	les	di,ss:[TPD_classPointer]	; es:di <- thread's class
	call	ObjCallMethodTableSaveBXSI	;ds <- idata
	retn					;return to fixup routine

	; Block is fully discarded

SM_fullyDiscarded label near
	xchg	di,ax				;di = method (1-byte inst)
	call	FullObjLock
	xchg	ax,di				;ax = method, di = seg address
 	InsertMessageProfileEntry PET_MSG_DISCARD, 1, ax
	jmp	afterLock

;-------------------------------------

NEC <necError:								>
NEC <	ERROR	ILLEGAL_HANDLE						>

;-------------------------------------
; ds = idata

popThenFixup:
	pop	ax, cx, dx, bp		;recover saved registers
	retn				;go to the real fixup routine

SM_fixupNone label near
	InsertMessageProfileEntry PET_END_CALL, 1, ax
	pop	es
	pop	ds
	mov	di,0			;don't trash the carry
	ret

SM_fixupDS label near
	InsertMessageProfileEntry PET_END_CALL, 1, ax
	pop	es
	pop	di			;recover handle of ds passed
EC <	call	CheckMemHandleNSDI					>
	mov	ds,ds:[di][HM_addr]
	mov	di,0			;don't trash the carry
	ret


SM_fixupDSES label near
	InsertMessageProfileEntry PET_END_CALL, 1, ax
	pop	di			;recover handle of es passed
EC <	call	CheckMemHandleNSDI					>
	mov	es,ds:[di][HM_addr]
	pop	di			;recover handle of ds passed
EC <	call	CheckMemHandleNSDI					>
	mov	ds,ds:[di][HM_addr]
	mov	di,0			;don't trash the carry
	ret
SwatLabel SendMessage_end
SendMessage	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckMemHandleNSDI

DESCRIPTION:	An attempt to save bytes in EC version.  Pulled common 
		sequence here

CALLED BY:	INTERNAL

PASS:
	di	- handle of memory handle to check

RETURN:
	Nothing - not even flags affected

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

if	ERROR_CHECK
CheckMemHandleNSDI	proc	near
	pushf
	xchg	bx,di
	call	ECCheckMemHandleNSFar
	xchg	bx,di
	popf
	ret
CheckMemHandleNSDI	endp

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjCallInstanceNoLock

DESCRIPTION:	Call a method of the given instance's class.  Do not lock
		the block.

	WARNING: This routine assumes that the object block being sent to is
		 run by the same process and is already locked.  It is the
		 responsibility of the caller to ensure that this is the
		 case.

CALLED BY:	GLOBAL

PASS:
	ax - method number to call
	cx, dx, bp - other data to pass
	*ds:si - instance data of object to call (si is lmem handle)
	ds - pointing to an object block or other local memory block or a core
	     block (the important part: ds:0 must be the handle of the block)

RETURN:
	carry - if no method routine called: 0
		if method routine called: set by method
	carry, ax, cx, dx, bp - return value (if any)
	ds - pointing to the same block as the "ds" passed.  The address could
	     be different since local memory blocks can move while locked.
	bx, si, di, unchanged

	es - If es = ds when ObjCallInstanceNoLock is called, es is
	destroyed.  Otherwise, es unchanged.

DESTROYED:
	none (possibly es, see above)

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

	Method Routine:
	PASS:
		es - segment of class called
		*ds:si - instance data of object called
		ds:bx - instance data of object called (= *ds:si)
		if class of method handler is in a master part
		    ds:di - data for master part of method handler
		else
		    ds:di - instance data of object called (= *ds:si)
		cx, dx, bp - other data
		ax - method number
	RETURN (if method has return values, else these may also be destroyed):
		ax, cx, dx, bp
	CAN DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

ObjCallInstanceNoLock	proc	far
 	InsertMessageProfileEntryDSSI PET_OCINL, 1, ax	
EC <	call	NullESIfObjBlock					>
	push	bx, si, di, es
	mov	di,ds:[si]
if ERROR_CHECK
	les	di,ds:[di].MB_class	; Pull CallMethodCommonLoadESDI call
	call	CallMethodCommon	; in here to lighten EC stack burden
	pop	bx, si, di, es
	call	NullSegmentRegisters	
	ret
else
	GOTO_ECN	CallMethodCommonLoadESDI, es, di, si, bx
endif
SwatLabel	ObjCallInstanceNoLock_end
ObjCallInstanceNoLock	endp

;---

ObjGotoInstanceTailRecurse	proc	far
	mov	di,ds:[si]
	les	di,ds:[di].MB_class
	GOTO_ECN	ObjCallMethodTable
SwatLabel ObjGotoInstanceTailRecurse_end
ObjGotoInstanceTailRecurse	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjCallInstanceNoLockES

DESCRIPTION:	Call a method of the given instance's class, fixing up both DS
		and ES

	WARNING: This routine assumes that the object block being sent to is
		 run by the same process and is already locked.  It is the
		 responsibility of the caller to ensure that this is the
		 case.

	WARNING: This routine assumes that both DS and ES point at blocks in
		 which the first word of the block is the block handle.  If
		 this is not the case, the routine will die horribly.

CALLED BY:	GLOBAL

PASS:
	ax - method number to call
	cx, dx, bp - other data to pass
	*ds:si - instance data of object to call (si is lmem handle)
	ds - pointing to an object block or other local memory block or a core
	     block (the important part: ds:0 must be the handle of the block)
	es - pointing to an object block or other local memory block or a core
	     block (the important part: es:0 must be the handle of the block)

RETURN:
	carry - if no method routine called: 0
		if method routine called: set by method
	carry, ax, cx, dx, bp - return value (if any)
	ds - pointing to the same block as the "ds" passed.  The address could
	     be different since local memory blocks can move while locked.
	es - pointing to the same block as the "es" passed.  The address could
	     be different since local memory blocks can move while locked.
	bx, si, di - unchanged

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.


	Method Routine:
	PASS:
		es - segment of class called
		*ds:si - instance data of object called
		ds:bx - instance data of object called (= *ds:si)
		if class of method handler is in a master part
		    ds:di - data for master part of method handler
		else
		    ds:di - instance data of object called (= *ds:si)
		cx, dx, bp - other data
		ax - method number
	RETURN (if method has return values, else these may also be destroyed):
		ax, cx, dx, bp
	CAN DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

ObjCallInstanceNoLockES	proc	far	uses di
	.enter
 	InsertMessageProfileEntryDSSI PET_OCINLES, 1, ax
EC <	call	FarCheckDS_ES						>
	push	ds:[LMBH_handle]			;save handle of ds
	push	es:[LMBH_handle]			;save handle of es

	mov	di,ds:[si]
	les	di,ds:[di][MB_class]

	call	ObjCallMethodTableSaveBXSI	; ds <- idata

	InsertMessageProfileEntry PET_END_CALL, 1, ax
	pop	di			;recover handle of es passed
EC <	call	CheckMemHandleNSDI					>
	mov	es,ds:[di][HM_addr]

	pop	di			;recover handle of ds passed
EC <	call	CheckMemHandleNSDI					>
	mov	ds,ds:[di][HM_addr]

	.leave
	ret

ObjCallInstanceNoLockES	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjCallClassNoLock

DESCRIPTION:	Call a method of the given class.  If the method is not defined
		for the class, call the method of the class's superclass.

	WARNING: This routine assumes that the object block being sent to is
		 run by the same process and is already locked.  It is the
		 responsibility of the caller to ensure that this is the
		 case.

CALLED BY:	GLOBAL

PASS:
	ax - method number to call
	cx, dx, bp - other data to pass
	*ds:si - instance data to pass (si is lmem handle)
		 or ds = core block of process
	es:di - class to call
	ds - pointing to an object block or other local memory block or a core
	     block (the important part: ds:0 must be the handle of the block)

RETURN:
	carry - if no method routine called: 0
		if method routine called: set by method
	carry, ax, cx, dx, bp - return value (if any)
	ds - pointing to the same block as the "ds" passed.  The address could
	     be different since local memory blocks can move while locked.
	bx, si, di, es - unchanged

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.


	Method Routine:
	PASS:
		es - segment of class called
		*ds:si - instance data of object called
		ds:bx - instance data of object called (= *ds:si)
		if class of method handler is in a master part
		    ds:di - data for master part of method handler
		else
		    ds:di - instance data of object called (= *ds:si)
		cx, dx, bp - other data
		ax - method number
	RETURN (if method has return values, else these may also be destroyed):
		ax, cx, dx, bp
	CAN DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

ObjCallClassNoLock	proc	far
	push	bx, si, di, es
 	InsertMessageProfileEntryDSSI PET_OCCNL, 1, ax
	GOTO_ECN	CallMethodCommon, es, di, si, bx
SwatLabel ObjCallClassNoLock_end
ObjCallClassNoLock	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjCallSuperNoLock

DESCRIPTION:	Call a method of the given class's superclass.

	WARNING: This routine assumes that the object block being sent to is
		 run by the same process and is already locked.  It is the
		 responsibility of the caller to ensure that this is the
		 case.

CALLED BY:	GLOBAL

PASS:
	ax - method number to call
	cx, dx, bp - other data to pass
	*ds:si - instance data of object called
		 or ds = core block of process
	es:di - class to call superclass of
	ds - pointing to an object block or other local memory block or a core
	     block (the important part: ds:0 must be the handle of the block)

RETURN:
	carry - if no method routine called: 0
		if method routine called: set by method
	carry, ax, cx, dx, bp - return value (if any)
	ds - pointing to the same block as the "ds" passed.  The address could
	     be different since local memory blocks can move while locked.
	bx, si, di, es - unchanged

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.


	Method Routine:
	PASS:
		es - segment of class called
		*ds:si - instance data of object called
		ds:bx - instance data of object called (= *ds:si)
		if class of method handler is in a master part
		    ds:di - data for master part of method handler
		else
		    ds:di - instance data of object called (= *ds:si)
		cx, dx, bp - other data
		ax - method number
	RETURN (if method has return values, else these may also be destroyed):
		ax, cx, dx, bp
	CAN DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

ObjCallSuperNoLock	proc	far
	push	bx, si, di, es
 	InsertMessageProfileEntryDSSI PET_OCSNL, 1, ax
;	If the class we are sending to is not MetaClass, or a descendent of
;	ProcClass (because those classes do not necessarily have any
;	instance data) make sure that:
;
;	1) There is a valid object being passed
;	2) The object is of the passed class

EC <	call	ECCheckClass						>
EC <	pushdw	dssi							>
EC <	mov	si, segment ProcessClass				>
EC <	mov	ds, si							>
EC <	mov	si, offset ProcessClass					>
EC <	call	ObjIsClassADescendant					>
EC < 	popdw	dssi							>
EC <	jc	noObjCheck	>	;Branch if passed ProcessClass

EC <	cmp	di, offset MetaClass					>
EC <	jnz	doObjCheck						>
EC <	push	ax							>
EC <	mov	ax, es							>
EC <	cmp	ax, segment MetaClass					>
EC <	pop	ax							>
EC <	jz	noObjCheck						>
EC <doObjCheck:								>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OBJECT_PASSED_TO_ObjCallSuperNoLock_IS_NOT_OF_PASSED_CLASS >
EC <noObjCheck:								>


EC <	; See if current class instance data grown			>
EC <	push	bx							>
EC <	push	di							>
EC <	mov	bx, es:[di].Class_masterOffset				>
EC <	tst	bx							>
EC <	jz	EC_NoMasters						>
EC <	mov	di, ds:[si]						>
EC <	cmp	word ptr ds:[di][bx], 0		; see if null offset	>
EC <	ERROR_Z	OBJ_NOT_GROWN_AT_CURRENT_CLASS_LEVEL			>
EC <EC_NoMasters:							>
EC <	pop	di							>
EC <	pop	bx							>

	mov	bx,es:[di].Class_superClass.segment
EC <	tst	bx							>
EC <	ERROR_Z	BAD_CLASS						>

	cmp	bx,VARIANT_CLASS			;variant class ?
	jz	variant
	mov	di,es:[di].Class_superClass.offset
	mov	es,bx
	GOTO_ECN	CallMethodCommon, es, di, si, bx

	; must build new part

build:
	pop	di			; recover class offset
	call	ResolveVariant
	GOTO_ECN	CallMethodCommon, es, di, si, bx

	; superclass is a variant -- get class from instance data

variant:
	mov	bx,es:[di].Class_masterOffset
	push	di			; save class offset, in case needed
	mov	di,ds:[si]
	add	di,ds:[di][bx]		; get offset
	cmp	ds:[di].MB_class.segment,0
	jz	build
	inc	sp			; didn't need class offset, fix stack
	inc	sp

	FALL_THRU_ECN	CallMethodCommonLoadESDI, es, di si, bx
SwatLabel ObjCallSuperNoLock_end
ObjCallSuperNoLock	endp

;----

CallMethodCommonLoadESDI	proc	ecnear
	les	di,ds:[di].MB_class
	FALL_THRU_ECN	CallMethodCommon
SwatLabel	CallMethodCommonLoadESDI_end
CallMethodCommonLoadESDI	endp

;-------
CallMethodCommon	proc	ecnear
	push	ds:[LMBH_handle]			;save handle of ds
	call	ObjCallMethodTable
	pop	di			;recover handle of ds passed
	LoadVarSeg	ds
EC <	call	CheckMemHandleNSDI					>
	mov	ds,ds:[di][HM_addr]
 	InsertMessageProfileEntry PET_END_CALL, 1, ax
	FALL_THRU_POP	es, di, si, bx
	ret
SwatLabel CallMethodCommon_end
CallMethodCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjCallMethodTableSaveBXSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call ObjCallMethodTable, preserving BX & SI from harm

CALLED BY:	SendMessage, ObjCallInstanceNoLock
PASS:		stuff for OCMT
RETURN:		stuff from OCMT plus
		ds	= idata
DESTROYED:	not bx or si, that's for sure

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjCallMethodTableSaveBXSI proc	near	uses bx, si
		.enter
		call	ObjCallMethodTable
		LoadVarSeg	ds
		.leave
		ret
SwatLabel ObjCallMethodTableSaveBXSI_end
ObjCallMethodTableSaveBXSI endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordMessageStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record in a buffer the number of messages 

CALLED BY:	ObjCallMethodTable

PASS:		ES:DI	= ClassStruc pointer
		AX	= Message number

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We leave a 3-word stack frame on the stack, containing
		that starting time of the call (2 words) and an offset
		into our message/class table.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if		RECORD_MESSAGES
RMS_OFFSET	equ	12
RecordMessageStart	proc	near
		sub	sp, 6			; save room for time, offset
		uses	ax, bx, cx, si, bp, ds
		.enter
	
		; First record the time. We move the return address three
		; words forward, so we can leave the time/offset data on
		; the stack.
		;
		mov	bp, sp
		push	ax			; save message
		call	TimerStartCount		; start time => BX:AX
		mov	cx, ss:[bp+RMS_OFFSET+6]
		mov	ss:[bp+RMS_OFFSET+2], bx
		mov	ss:[bp+RMS_OFFSET+4], ax
		mov	ss:[bp+RMS_OFFSET+0], cx
		LoadVarSeg	ds, ax
		pop	ax			; restore message
		cmp	ds:[recMsgState], TRUE
		jne	done

		; Search through the buffer for the class/message pair
		;
		mov	bx, es			; class pointer => BX:DI
		mov	si, offset recMsgTable
		mov	cx, ds:[recMsgHeader].RMH_usedEntries
		jcxz	newEntry
bufferLoop:
		cmp	ds:[si].RME_message, ax
		jne	next
		cmp	ds:[si].RME_class.offset, di
		jne	next
		cmp	ds:[si].RME_class.segment, bx
		je	found
next:
		add	si, size RecordedMessageEntry
		loop	bufferLoop
		
		; We need to add another entry into the buffer
newEntry:
		dec	ds:[recMsgHeader].RMH_freeEntries
		jz	tableFull
		inc	ds:[recMsgHeader].RMH_usedEntries
		mov	ds:[si].RME_message, ax
		mov	ds:[si].RME_class.low, di
		mov	ds:[si].RME_class.high, bx
		clr	ds:[si].RME_count
found:
		inc	ds:[si].RME_count
done:
		mov	ss:[bp+RMS_OFFSET+6], si
		INT_ON

		.leave
		ret

		; If table overflows, keep count of unrecorded messages
tableFull:
		inc	ds:[recMsgHeader].RMH_freeEntries
		inc	ds:[recMsgHeader].RMH_unrecorded
		jmp	done
RecordMessageStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordMessageEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the time required to complete a message call.

CALLED BY:	ObjCallMethodTable

PASS:		SS:SP	= Timer Ticks
			  Timer Units
			  MessageRecordEntry offset
			  Return address (near)

RETURN:		Nothing

DESTROYED:	BX, SI, DI, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EC  <RecordMessageEnd	proc	near	jmp				>
NEC <RecordMessageEnd	proc	far	jmp				>

		; Pop arguments off of the stack, and record the time change
		;
		mov	di, ax			; store AX
		LoadVarSeg	ds, ax
		pop	bx			; Timer ticks => BX
		pop	ax			; Timer units => AX
		pop	si			; RecordedMessageEntry => DS:SI
		pushf
		cmp	ds:[recMsgState], TRUE
		jne	done
		call	TimerEndCount		; update running time total
done:
		popf
		mov	ax, di			; restore AX
		ret
RecordMessageEnd	endp
endif

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjGotoSuperTailRecurse

DESCRIPTION:	This is an optimized version of ObjCallSuperNoLock that
		only works in the case of tail recursion.

CALLED BY:	GLOBAL

PASS:
	ax - method number to call
	cx, dx, bp - other data to pass
	ds:*si - instance data to pass (si is lmem handle)
		 or ds = core block of process
	es:di - class to call superclass of
	ds - pointing to an object block or other local memory block or a core
	     block (the important part: ds:0 must be the handle of the block)

RETURN:
	NONE

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version

-------------------------------------------------------------------------------@
ObjGotoSuperTailRecurse	proc	far
EC <	call	ECCheckClass						>

EC <	; See if current class instance data grown			>
EC <	push	bx							>
EC <	push	di							>
EC <	mov	bx, es:[di].Class_masterOffset				>
EC <	tst	bx							>
EC <	jz	EC_NoMasters						>
EC <	mov	di, ds:[si]						>
EC <	cmp	{word} ds:[di][bx], 0		; see if null offset	>
EC <	ERROR_Z	OBJ_NOT_GROWN_AT_CURRENT_CLASS_LEVEL			>
EC <EC_NoMasters:							>
EC <	pop	di							>
EC <	pop	bx							>

	mov	bx, es:[di].Class_superClass.segment
EC <	tst	bx							>
EC <	ERROR_Z	BAD_CLASS						>

	cmp	bx,VARIANT_CLASS			;variant class ?
	jz	variant
	mov	di, es:[di].Class_superClass.offset
	mov	es, bx
	GOTO_ECN	ObjCallMethodTable

	; must build new part

build:
	pop	di			; recover class offset
	call	ResolveVariant
	GOTO_ECN	ObjCallMethodTable

	; superclass is a variant -- get class from instance data

variant:
	mov	bx, es:[di].Class_masterOffset
	push	di			; save class offset, in case needed
	mov	di, ds:[si]
	add	di, ds:[di][bx]		; get offset
	cmp	ds:[di].MB_class.segment,0
	jz	build
	inc	sp			; didn't need class offset, fix stack
	inc	sp
	les	di, ds:[di].MB_class

	GOTO_ECN	ObjCallMethodTable
SwatLabel ObjGotoSuperTailRecurse_end
ObjGotoSuperTailRecurse	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjCallMethodTable

DESCRIPTION:	Call a method of the given class

CALLED BY:	INTERNAL
		SendMessage, ObjCallInstanceNoLock, ObjCallInstanceNoLockES
		ObjCallClassNoLock, ObjCallSuperNoLock

PASS:
	es:di - class to call
	ax - method number to call
	cx, dx, bp - other data to pass
	*ds:si - instance data to pass (si is lmem handle)
		 or ds = core block of process

RETURN:
	carry - if no method routine called: 0
		if method routine called: set by method
	ax    - if no method routine called:0
		if method routine called: set by method
	bx, cx, dx, bp, si - return value (if any)
		Note: bx and si are saved and restored by ObjCallMethod

DESTROYED:
	bx, di, ds, es

	Method Routine:
	PASS:
		es - segment of class called
		ds:*si - instance data
		cx, dx, bp - other data
		ax - method number
	RETURN (if method has return values, else these may also be destroyed):
		ax, cx, dx, bp
	CAN DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

NOTES:

    Cycle times
    -----------
	 Entry+Exit Overhead
		Module call handler found	580-630
		Far call handler found		310
		No method handler		280

	 Class Searches
	 	Per class which does NOT handle methods from level     101
	 	Per class which DOES handle methods from level         143 +19n

	 	Additional for each master class		        41

    OR, for a module-handled method,:
    
    725 + (140 * #classes above handling class) + (19 * #total methods searched)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Doug	3/90		Speed optimizations, added time table

-------------------------------------------------------------------------------@


NEC <OCMT_necError:							>
NEC <	ERROR	ILLEGAL_HANDLE						>

	;-----------------------------------------------------------------

	; object part is not initialized -- initialize it to es:di

OCMT_initialize:
	mov	di,bp			;pass class in es:di
	call	ObjInitializeMaster
	jmp	afterInit

ObjCallMethodTable	proc	ecnear

	; master offset must be even
	; master offset must be less than 32 (0x20) (arbitrary limit)

NEC <	test	es:[di].Class_masterOffset, 0xffe1			>
NEC <	jnz	OCMT_necError						>

	InsertMessageProfileEntryDSSI PET_OCMT, 1, ax

if	RECORD_MESSAGES
	call	RecordMessageStart	; record the message & class
endif

if	ERROR_CHECK or NONEC_WITH_BACKTRACE
	push	ax			; Save everything interesting on stack
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	es
	push	ds:[LMBH_handle]

if	ERROR_CHECK
	call	ECCheckBlockChecksumFar

;	If we are sending this to a subclass of GenProcessClass, or to
;	meta class, then don't check the object, as DS may not be pointing
;	to a self-referencing object block (for example, if we are sending
;	a message to an event thread of a library w/o a stack, the core
;	block of the library (in DS) will not be self-referencing.

EC <	call	ECCheckClass						>
EC <	pushdw	dssi							>
EC <	mov	si, segment ProcessClass				>
EC <	mov	ds, si							>
EC <	mov	si, offset ProcessClass					>
EC <	call	ObjIsClassADescendant					>
EC < 	popdw	dssi							>
EC <	jc	noObjCheck	>	;Branch if passed ProcessClass

EC <	cmp	di, offset MetaClass					>
EC <	jnz	doObjCheck						>
EC <	push	ax							>
EC <	mov	ax, es							>
EC <	cmp	ax, segment MetaClass					>
EC <	pop	ax							>
EC <	jz	noObjCheck						>

doObjCheck:
	call	CheckObject		; Make sure this is a valid object
					; Do HERE, after the registers are
					; pushed, so that we can get a nice
					; swat printout showing what the
					; thing was TRYING to do.
noObjCheck:
endif
endif

								; 8088 times
								; ----------
	push	bp						; 15
	push	cx						; 15
	mov	bp,di			;es:bp = class		;  2

	; if instance data too small then build it

	; Determine which master class method is defined in
	;
	mov	bx, ax						;  2
	rol	bx, 1		; get top 3 bits in low byte	;  2
	rol	bx, 1						;  2
	rol	bx, 1						;  2
	and	bx, 0007h					;  4
	mov	bl, cs:[bx][bitmaskTable]			;  19


masterLoop:
	mov	cx,es:[bp].Class_masterOffset			; 23
	jcxz	afterInit					;  6   | 18 ->
	mov	di,ds:[si]					; 17
	add	di,cx						;  3
	tst	<word ptr ds:[di]>				; 16
	jz	OCMT_initialize					;  4   | 16 ->
afterInit	label	near

EC <	xchg	di, bp							>
EC <	call	CheckClass						>
EC <	xchg	di, bp							>

	; Test to see if method is actually handled in this class
	;
	test	bl, es:[bp].Class_masterMethods			; 20
	jnz	scanMethodTable					;  4  | 16 ->

notFound:
	; THIS test & two branch combination only works if
	; CLASSF_HAS_DEFAULT is the top bit in the Class_flags
	; structure.  The test leaves sign flag set if there is
	; a default handler for the class, & if not, leaves the
	; zero flag holding whether this class is a master
	; class or not.
	;
	;							; 22
CheckHack <mask CLASSF_HAS_DEFAULT eq 0x80>
	test	es:[bp].Class_flags, \
		mask CLASSF_HAS_DEFAULT or mask CLASSF_MASTER_CLASS
	LONG js	popAndCallDefault				; 4   | 16 ->
	LONG jnz master						; 4   | 16 ->

	; Simple case - just fetch superclass & branch back to
	; scanloop.
	;
	les	bp,es:[bp].Class_superClass			; 35

EC <	xchg	di, bp							>
EC <	call	CheckClass						>
EC <	xchg	di, bp							>

	; Test to see if method is actually handled in this class
	;
	test	bl, es:[bp].Class_masterMethods			; 20
	jz	notFound					;  4  | 16 ->

scanMethodTable:
	; Scan method table for match. es:bp = class structure
	; Since we have already determined that methods defined in
	; the master class that the method passed is defined in
	; ARE handled by this class, then know that Class_methodCount
	; is not 0.
	;
	mov	di,bp						;  2
	add	di,Class_methodTable				;  4
	mov	cx,es:[bp].Class_methodCount			; 23
if OCMT_OPT
	cmp	cx, OCMT_OPT_THRESH
	jbe	straightScan


straightScan:
endif
	repnz	scasw						;  9+19n
	jnz	notFound					;  4   | 16 ->

	; Method found!

found::
	; found method -- call it
	; di points 2 beyond the method number, 1 is the number of methods
	; after the match. To get to the routine we need to evaluate:
	; 	bx = ((di - (bp.Class_methodTable+2)) * 2) + (di + cx*2)
	; the first term yields the offset into the routine table of the
	; routine we want, while the second term advances di to the start
	; of the routine table. This can be simplified to
	; 	bx = ((di - bp - (Class_methodTable+2) + cx) * 2) + di

	mov	bx, di			; Calculate distance	; 2
	sub	bx, bp			; from start of method	; 3
					; table in BX
	sub	bx, Class_methodTable+2				; 4
	add	bx, cx			; Merge in number of	; 3
					; remaining methods
	shl	bx			; Distributive law lets	; 2
					; us do a single
					; multiplication by 2
	add	bx, di			; Point to routine	; 3

popAndCall:

	;	ax = method, es:[bx] = handler, es:[bp] = class

	; test for method handler using the C convention

	test	es:[bp].Class_flags, mask CLASSF_C_HANDLERS
	LONG jnz toCHandler

	; set up extra values to pass to ProcCallModuleRoutine

	mov	ss:[TPD_dataAX], ax	; send method in AX	; 16

	; Skip dereference if msg is going to a ProcessClass. - Joon (3/31/95)

	mov	ax, ds						; 2
	cmp	ax, ss:[TPD_dgroup]				; 
	je	noMasters		; don't dereference	; 4 | 16 ->

EC <	test	si, 1			; si must be a chunk handle	>
EC <	WARNING_NZ INVALID_CHUNK_HANDLE	; si is not a chunk handle	>

	mov	di, ds:[si]					; 17
	mov	ss:[TPD_dataBX], di	; send ds:[si] in BX	; 16
	mov	bp, es:[bp].Class_masterOffset			; 23
	tst	bp						; 3
	jz	noMasters					; 4 | 16 ->
	add	di, ds:[di][bp]		; send part in di	; 23
noMasters:

	; handler in dword ptr es:[bx]

	pop	cx						; 12
	pop	bp						; 12

	; handler in dword ptr es:[bx]

	mov	ax,es:[bx].segment				; 23

HMA <	cmp	ax, HMA_SEGMENT			;check hi-mem segment	>
HMA <	je	CallFixed						>

	cmp	ah, high MAX_SEGMENT	;fixed ?		;  4

EC <	call	ECCheckDirectionFlag					>
CallMethod	label	near
	ForceRef	CallMethod	;Needed for swat

	jb	CallFixed					;  4   | 16 ->


	; CASE for method handler in a movable resource

;movable:
	shl	ax,1						;  2
	shl	ax,1						;  2
					    ;break up series of shifts for
					    ;pre-fetch queue
	mov	bx,es:[bx]		    ;bx = offset of call

	shl	ax,1						;  2
	shl	ax,1						;  2

	xchg	ax,bx			    ;make them right	;  4
					    ;for CallModRout
	
ObjCallModuleMethod	label	far
	ForceRef	ObjCallModuleMethod
	
if NONEC_WITH_BACKTRACE
	call	ProcCallModuleRoutine
NECR <	call	RecordMessageEnd					   >
	jmp	return
else
EC <	call	ProcCallModuleRoutine					   >
EC <	jmp	return							   >
NECR <	call	ProcCallModuleRoutine					   >
NECR <	jmp	RecordMessageEnd					   >
NECNR <	jmp	ProcCallModuleRoutine					   >
endif
	;-----------------------------------------------------------------

popAndCallDefault:
	lea	bx, es:[bp-4]		; fetch default handler	; 13
	jmp	popAndCall					; 15

	;-----------------------------------------------------------------
master:
	;
	; Master class -- need to deal with INITIALIZE and variants
	;
	cmp	ax,MSG_META_INITIALIZE	;don't inherit INIT	; 4
	jz	OCMT_none		;across master classes	; 4   | 16 ->

	mov	cx,es:[bp].Class_superClass.segment		; 23
	cmp	cx,VARIANT_CLASS				; 4
	jbe	variantOrDone					; 4   | 16 ->
	mov	bp,es:[bp].Class_superClass.offset		; 23
	mov	es,cx						; 2
	jmp	masterLoop					; 15

	;-----------------------------------------------------------------


	; trying to send method to an empty part -- send MSG_META_RESOLVE_VARIANT_SUPERCLASS

build:
	mov	di,bp			;pass class in es:di
	call	ResolveVariant
	mov	bp,di
	jmp	masterLoop

	;-----------------------------------------------------------------

	; superclass is a variant -- get class from instance data

variant:
	mov	cl, bl			; save master level	;  2
	mov	bx,es:[bp].Class_masterOffset			; 23
	mov	di,ds:[si]					; 17
	add	di,ds:[di][bx]					; 22
	mov	bl, cl			; restore master level	; 2

	cmp	ds:[di].MB_class.segment,0
	jz	build						;  4   | 16 ->
	les	bp,ds:[di]					; 33
	jmp	masterLoop					; 15

	;-----------------------------------------------------------------

toCHandler:
	jmp	cHandler

	;-----------------------------------------------------------------

	; CASE for method handler in fixed memory

CallFixed	label	near			;Needed for swat
	ForceRef	CallFixed	; Used by Swat TCL code

	mov	ax, es:[bx].segment
	mov	ss:[TPD_callVector].segment, ax
	mov	ax, es:[bx].offset
	mov	ss:[TPD_callVector].offset, ax
	mov	ax, ss:[TPD_dataAX]
	mov	bx, ss:[TPD_dataBX]

if NONEC_WITH_BACKTRACE
EC <	call	ss:[TPD_callVector]					>
EC <	call	ECCheckBlockChecksumFar					>
NECR <	call	ss:[TPD_callVector]					>
NECR <	call	RecordMessageEnd					>
NECNR <	call	ss:[TPD_callVector]					>
	jmp	return
else
EC <	call	ss:[TPD_callVector]					>
EC <	call	ECCheckBlockChecksumFar					>
EC <	jmp	return							>
NECR <	call	ss:[TPD_callVector]					>
NECR <	jmp	RecordMessageEnd					>
NECNR <	jmp	ss:[TPD_callVector]					>
endif

SwatLabel	CallFixed_end
	;-----------------------------------------------------------------

variantOrDone:
	jz	variant

OCMT_none label	near
	pop	cx
	pop	bp
	clr	ax		;return no method sent
	clc			;return no method sent
if ERROR_CHECK or NONEC_WITH_BACKTRACE
return:
EC <	call	ECCheckDirectionFlag					>
	mov	bx, sp			; Fix stack, w/o trashing flags
	lea	sp, [bx+8*word]
endif
if RECORD_MESSAGES
	jmp	RecordMessageEnd
else
	ret
endif
	;-----------------------------------------------------------------

bitmaskTable	label	byte
	byte	01h
	byte	02h
	byte	04h
	byte	08h
	byte	10h
	byte	20h
	byte	40h
	byte	80h

	;-----------------------------------------------------------------

	; Method handler in C
	;	ax = method, es:[bx] = handler, es:[bp] = class
	;	bp, cx on stack, es:di - points after method scanned

cHandler:

	; save method and handler address

	mov	ss:[TPD_dataAX], ax		;save method
	mov	ax, es:[bx].offset
	mov	ss:[TPD_callVector].offset, ax
	mov	ax, es:[bx].segment
	mov	ss:[TPD_callVector].segment, ax

	; fetch MPD and HTD (after methods and handlers)

	; di points 2 beyond the method number, 1 is the number of methods
	; after the match. To get to the routine we need to evaluate:
	; 	bx = ((di - (bp-Class_methodTable+2)) * 1.5) + (di + cx*2)
	;					+ (#methods * 4)
	; the first term yields the offset into the routine table of the
	; routine we want, while the second term advances di to the start
	; of the routine table. This can be simplified to
	; 	bx = ((di - bp - (Class_methodTable+2)) * 1.5) + di + 2*cx

	mov	bx, di			; Calculate distance
	sub	bx, bp			; from start of method table in BX

	sub	bx, Class_methodTable+2
	mov	ax, bx
	shr	ax
	add	bx, ax			; bx = 1.5 * ...

	add	bx, cx
	add	bx, cx
	add	bx, di
	mov	ax, es:[bp].Class_methodCount
	shl	ax
	shl	ax
	add	bx, ax

	mov	ax, es:[bx]			;ax = MPD (MethodParameterDef)
	mov	bl, es:[bx][2]			;bl = HTD (HandlerTypeDef)

	pop	cx
	pop	ss:[TPD_dataBX]			;holds bp passed

	; push registers on the stack so that we can recover the ones
	; that are not return values

	push	cx
	push	ss:[TPD_dataBX]
	push	dx
	push	ss:[TPD_dataAX]			;method

if AUTOMATICALLY_FIXUP_PSELF
	; Save current cmessageFrame and stackBorrowCount.  Also save
	; masterOffset so we can deref.
	;
	; Warning: ThreadFixupPSelf depends on the order in which these
	; 	   arguments, oself, and pself are pushed onto the stack.

	push	ss:[TPD_cmessageFrame]		;save current cmessageFrame
	push	ss:[TPD_stackBorrowCount]	;save current stackBorrowCount
	push	es:[bp].Class_masterOffset	;save Class_masterOffset
endif

	; push standard args

	test	bl, mask HTD_PROCESS_CLASS
	jnz	procClass

	; dereference object (bp still on stack)

	mov	di, ds:[si]
	mov	bp, es:[bp].Class_masterOffset	;bp = master offset
	tst	bp
	jz	cNoMasters
	add	di, ds:[di][bp]
cNoMasters:
	; far model -- FooInstance _far *pself,

if AUTOMATICALLY_FIXUP_PSELF
	mov	ss:[TPD_cmessageFrame], sp	;set new cmessageFrame
	mov	ss:[TPD_stackBorrowCount], 0	;initialize stackBorrowCount
endif

	push	ds				;pself.segment
	push	di				;pself.offset

	push	ds:[LMBH_handle]		;optr.handle
	jmp	argCommon

procClass:
	push	ss:[TPD_threadHandle]		;optr.handle
argCommon:
	push	si				;optr.chunk

	mov	bp, ss:[TPD_dataBX]

if	0
;;;	; FOR NOW: Pass ds/es pointing to the dgroup of the owner of the
;;;	; 	   object block
;;;	; LATER: We can just use the current process's dgroup once each app
;;;	;	 has its own UI thread
;;;PrintMessage <ObjCallMethodTable: Change this after thread change>
;;;if 1
;;;	mov	bx, ds:[LMBH_handle]		;bx = block
;;;	call	MemOwner			;bx = owner
;;;	push	ax
;;;	call	NearLockES
;;;	pop	ax
;;;	mov	di, es:[GH_resHandleOff]
;;;	mov	di, es:[di][2]			;di = handle of dgroup
;;;	call	NearUnlock
;;;	LoadVarSeg	es
;;;	mov	di, es:[di].HM_addr
;;;else
;;;	mov	di, ss:[TPD_dgroup]
;;;endif
;;;
;;;	mov	es, di
;;;	cmp	bl, HM_NEAR			;near model does not have
;;;	jz	noDSDgroup			;ds = dgroup
;;;	mov	ds, di
;;;noDSDgroup:
endif

;	Set DS=dgroup of the geode class lies in

	push	ss:[TPD_callVector].segment	;save callVector segment which
	push	ax, bx, cx			; can get trashed in
	mov	cx, es				; GeodeGetGeodeResourceHandle
	call	SegmentToHandle
EC <	ERROR_NC	-1						>
	mov	bx, cx
	call	MemOwner			;BX <- owning geode
DGROUP_RESID	equ	1
	mov	ax, DGROUP_RESID
	; If the geode's core block is not resident, some EC code in a movable
	; resource may be triggered via RCI and change the callVector, so save
	; it around the call. -dhunter 8/17/2000
EC <	push	ss:[TPD_callVector].offset				>
	call	GeodeGetGeodeResourceHandle
EC <	pop	ss:[TPD_callVector].offset				>
	call	MemDerefDS			;DS <- dgroup of owning geode
	pop	ax, bx, cx
	pop	ss:[TPD_callVector].segment	;restore callVector segment

	push	ss:[TPD_dataAX]			;method

	; test for multiple return values, in which case we must allocate
	; space for the return values and push a far pointer to them as the
	; first argument

	mov	di, ax			;test for return multiple
	andnf	di, mask MPD_RETURN_TYPE
	cmp	di, MRT_MULTIPLE shl offset MPD_RETURN_TYPE
	jnz	notReturnMultiple
	push	ss					;push segment
	push	ss:[TPD_stackBot]			;push offset
	add	ss:[TPD_stackBot], size word * 4	;allocate space for 4
							; words
notReturnMultiple:

	; now we must push the other args (according to the MPD (ax))

	mov	di, ax				;di saves MPD (for after call)
	mov	si, cx				;si = cx param
	test	ax, mask MPD_REGISTER_PARAMS
	jz	notRegisterParams

	andnf	di, mask MPR_PARAM1		;MPR_PARAM1 = bit 0
	call	GetValueToPush
	jc	noPush1
	push	bx
noPush1:

	mov	di, ax
	andnf	di, mask MPR_PARAM2
	mov	cl, offset MPR_PARAM2
	shr	di, cl
	mov	cx, si
	call	GetValueToPush
	jc	noPush2
	push	bx
noPush2:

	mov	di, ax
	andnf	di, mask MPR_PARAM3
	mov	cl, offset MPR_PARAM3
	shr	di, cl
	mov	cx, si
	call	GetValueToPush
	jc	noPush3
	push	bx
noPush3:
	mov_trash	di, ax			;di = MPD

	jmp	afterPushParams

notRegisterParams:
	test	ax, mask MPM_C_PARAMS
	jz	notCParams

	; params in C format -- if three words or less then use registers
	; al = param size in bytes

	cmp	al, 6
	ja	moreThanThreeWords
	cmp	al, 4			;bp is third word, only push if
	jbe	noPushBP		;5 or 6 bytes or parameters
	push	bp
noPushBP:
	cmp	al, 2			;dx is second word, only push if
	jbe	noPushDX		;3 or more bytes or parameters
	push	dx
noPushDX:
	push	cx
	jmp	afterPushParams

moreThanThreeWords:
	clr	ah
pushParamsCommon:
	inc	ax
	shr	ax			;ax = number of word parameters
	add	bp, ax
	add	bp, ax			;point after last word
	mov_trash	cx, ax
pushParamsLoop:
	dec	bp
	dec	bp
	push	ss:[bp]
	loop	pushParamsLoop
	jmp	afterPushParams

notCParams:
	test	ax, mask MSI_STRUCT_AT_SS_BP
	jnz	structSSBP

	; multiple parameters passed on stack because there are too many
	; arguments to fit in registers

	andnf	ax, mask MSI_PARAM_SIZE
	jmp	pushParamsCommon

	; single C parameter is far pointer to structure

structSSBP:
	push	ss			;push segment
	push	bp			;push offset

afterPushParams:

;	Save MethodParameterDef so we can tell if the system trashes it

EC <	mov	bx, ss:[TPD_stackBot]					>
EC <	add	ss:[TPD_stackBot], size word				>
EC <	mov	ss:[bx], di						>

	mov	ax, ss:[TPD_callVector].offset
	mov	bx, ss:[TPD_callVector].segment
CallCHandler label near		; for istep M command
	ForceRef CallCHandler
	call	ProcCallFixedOrMovable
EC <	mov	bx, ss:[TPD_stackBot]					>
EC <	cmp	di, ss:[bx][-size word]					>
EC <	ERROR_NZ	C_METHOD_HANDLER_TRASHED_DI			>
EC <	sub	ss:[TPD_stackBot], size word				>

if AUTOMATICALLY_FIXUP_PSELF
	;
	; Restore previous cmessageFrame and fixup pself.
	;
	add	sp, 2				;remove masterOffset from stack
	pop	ss:[TPD_stackBorrowCount]	;restore previous stackBorrowCt
	pop	ss:[TPD_cmessageFrame]		;restore previous cmessageFrame

	call	ThreadFixupPSelf
endif

	; on stack: ax, cx, dx, bp passed in order for:
	;	pop	ax
	;	pop	dx
	;	pop	bp
	;	pop	cx

	; handle return params (di = MPD) -- test for dword dx:ax specially

	andnf	di, mask MPD_RETURN_TYPE or mask MPD_RETURN_INFO
	cmp	di, (MRT_DWORD shl offset MPD_RETURN_TYPE) or \
			(MRDWR_DX shl ((offset MTDI_HIGH_REG)+ \
					(offset MPD_RETURN_INFO))) or \
			(MRDWR_AX shl ((offset MTDI_LOW_REG)+ \
					(offset MPD_RETURN_INFO)))
	jnz	notDWordDXAX
	pop	bp, bp			;trash ax, dx
	pop	bp
	pop	cx
if ERROR_CHECK or NONEC_WITH_BACKTRACE
	jmp	return
else
NECR <	jmp	RecordMessageEnd					>
NECNR <	ret								>
endif

notDWordDXAX:
	mov	bx, di
	andnf	bx, mask MPD_RETURN_TYPE
	cmp	bx, MRT_VOID shl offset MPD_RETURN_TYPE
	jnz	notVoid

	; void returns ax as carry

	tst	ax				;clears carry
	jz	34$
	stc
34$:
	pop	ax
	pop	dx
	pop	bp
	pop	cx
if ERROR_CHECK or NONEC_WITH_BACKTRACE
	jmp	return
else
NECR <	jmp	RecordMessageEnd					>
NECNR <	ret								>
endif

notVoid:
	andnf	di, mask MPD_RETURN_INFO
	mov	cl, offset MPD_RETURN_INFO
	shr	di, cl				;di = MethodReturnInfo
	cmp	bx, MRT_BYTE_OR_WORD shl offset MPD_RETURN_TYPE
	jnz	notByteOrWord

	; return type MRT_BYTE_OR_WORD, look at MethodReturnByteWordType

	mov_tr	bx, ax
	pop	ax
	pop	dx
	pop	bp
	pop	cx
EC <	cmp	di, length ReturnByteWordTable				>
EC <	ERROR_AE	BAD_C_METHOD_PARAMETER_DEF			>
	shl	di
	call	cs:[di][ReturnByteWordTable]	;sets registers correctly
if ERROR_CHECK or NONEC_WITH_BACKTRACE
	jmp	return
else
NECR <	jmp	RecordMessageEnd					>
NECNR <	ret								>
endif

notByteOrWord:
	cmp	bx, MRT_DWORD shl offset MPD_RETURN_TYPE
	jnz	notDWord

	; return type MRT_DWORD, look at MethodReturnDWordReg

	mov_tr	si, ax				;save low word of return
	mov	bx, dx				;bx = high word of return
	pop	ax
	pop	dx
	pop	bp
	pop	cx

	push	si
	push	di
	andnf	di, mask MTDI_HIGH_REG
	mov	cl, offset MTDI_HIGH_REG
	shr	di, cl
	call	GetDWordReturn
	pop	di
	pop	bx
	andnf	di, mask MTDI_LOW_REG
	call	GetDWordReturn

if ERROR_CHECK or NONEC_WITH_BACKTRACE
	jmp	return
else
NECR <	jmp	RecordMessageEnd					>
NECNR <	ret								>
endif

	; for returning multiple arguments we must pass a far pointer to
	; a buffer for the parameters -- we allocate this buffer at the
	; bottom of the stack

notDWord:

	; return ax in carry

	tst	ax
	jz	99$
	stc
99$:
	pop	ax
	pop	dx
	pop	bp
	pop	cx
	pushf

	mov	bx, ss:[TPD_stackBot]	;de-allocate space
	sub	bx, size word * 4

EC <	cmp	di, length ReturnMultipleTable				>
EC <	ERROR_AE	BAD_C_METHOD_PARAMETER_DEF			>
	shl	di
	call	cs:[di][ReturnMultipleTable]	;sets registers correctly
	mov	ss:[TPD_stackBot], bx	;ss:bx = return values
	popf
if ERROR_CHECK or NONEC_WITH_BACKTRACE
	jmp	return
else
NECR <	jmp	RecordMessageEnd					>
NECNR <	ret								>
endif
SwatLabel ObjCallMethodTable_end
	.unreached
ObjCallMethodTable	endp

;---------------------------------------------

	; ss:bx = buffer

	.warn	-inline_data	; Esp has a bug that causes us to be honked
				;  at for this (it ignores the .unreached
				;  b/c $ is == the last code label...). in
				;  fact, this table poses no problem -- ardeb

ReturnMultipleTable	nptr	ReturnAXBPCXDX, ReturnAXCXDXBP,
				ReturnCXDXBPAX, ReturnDXCX, ReturnBPAXDXCX,
				ReturnMULTIPLEAX
	.warn	@inline_data

ReturnAXBPCXDX	proc	near
	mov	ax, ss:[bx]
	mov	bp, ss:[bx][2]
	mov	cx, ss:[bx][4]
	mov	dx, ss:[bx][6]
	ret
ReturnAXBPCXDX	endp

ReturnDXCX	proc	near
	mov	dx, ss:[bx]
	mov	cx, ss:[bx][2]
	ret
ReturnDXCX	endp

ReturnAXCXDXBP	proc	near
	mov	ax, ss:[bx]
	mov	cx, ss:[bx][2]
	mov	dx, ss:[bx][4]
	mov	bp, ss:[bx][6]
	ret
ReturnAXCXDXBP	endp

ReturnCXDXBPAX	proc	near
	mov	cx, ss:[bx]
	mov	dx, ss:[bx][2]
	mov	bp, ss:[bx][4]
	mov	ax, ss:[bx][6]
	ret
ReturnCXDXBPAX	endp

ReturnBPAXDXCX	proc	near
	mov	bp, ss:[bx]
	mov	ax, ss:[bx][2]
	mov	dx, ss:[bx][4]
	mov	cx, ss:[bx][6]
	ret
ReturnBPAXDXCX	endp

ReturnMULTIPLEAX	proc	near
	mov	ax, ss:[bx]
	ret
ReturnMULTIPLEAX	endp

;---------------------------------------------

ReturnByteWordTable	nptr	ReturnAL, ReturnAH, ReturnCL, ReturnCH,
				ReturnDL, ReturnDH, ReturnBPL, ReturnBPH,
				ReturnAX, ReturnCX, ReturnDX, ReturnBP

ReturnAH	proc	near
	mov	ah, bl
	ret
ReturnAH	endp

ReturnAL	proc	near
	mov	al, bl
	ret
ReturnAL	endp

ReturnAX	proc	near
	mov_tr	ax, bx
	ret
ReturnAX	endp

;-

ReturnCH	proc	near
	mov	ch, bl
	ret
ReturnCH	endp

ReturnCL	proc	near
	mov	cl, bl
	ret
ReturnCL	endp

ReturnCX	proc	near
	mov	cx, bx
	ret
ReturnCX	endp

;-

ReturnDH	proc	near
	mov	dh, bl
	ret
ReturnDH	endp

ReturnDL	proc	near
	mov	dl, bl
	ret
ReturnDL	endp

ReturnDX	proc	near
	mov	dx, bx
	ret
ReturnDX	endp

;-

ReturnBPH	proc	near
	xchg	ax, bp
	mov	ah, bl
	xchg	ax, bp
	ret
ReturnBPH	endp

ReturnBPL	proc	near
	xchg	ax, bp
	mov	al, bl
	xchg	ax, bp
	ret
ReturnBPL	endp

ReturnBP	proc	near
	mov	bp, bx
	ret
ReturnBP	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetDWordReturn

DESCRIPTION:	Get return value for a word of a dword return

CALLED BY:	ObjCallMethodTable

PASS:
	di - MethodReturnDWordReg
	bx - value to place in the correct register

RETURN:
	ax, cx, dx, bp - updated

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

GetDWordReturn	proc	near
	shl	di
	jmp	cs:[ReturnDWordTable][di]
GetDWordReturn	endp

ReturnDWordTable	nptr	ReturnDWordAX, ReturnDWordCX,
				ReturnDWordDX, ReturnDWordBP

ReturnDWordAX	proc	near
	mov_trash	ax, bx
	ret
ReturnDWordAX	endp

ReturnDWordCX	proc	near
	mov	cx, bx
	ret
ReturnDWordCX	endp

ReturnDWordDX	proc	near
	mov	dx, bx
	ret
ReturnDWordDX	endp

ReturnDWordBP	proc	near
	mov	bp, bx
	ret
ReturnDWordBP	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetValueToPush

DESCRIPTION:	Get value to for MethodPassReg

CALLED BY:	ObjCallMethodTable

PASS:
	di - MethodPassReg
	cx - cx param
	dx - dx param
	bp - bp param

RETURN:
	carry - set to push nothing (MPR_NONE)
	bx - value to push

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

GetValueToPush	proc	near
	shl	di
	clr	bx				;clears carry
	jmp	cs:[GetValueTable][di]
GetValueToPush	endp

GetValueTable	nptr	GetNone, GetCL, GetCH, GetDL,
			GetDH, GetCX, GetDX, GetBP

GetNone	proc	near
	stc
	ret
GetNone	endp

GetCL	proc	near
	mov	bl, cl
	ret
GetCL	endp

GetCH	proc	near
	mov	bl, ch
	ret
GetCH	endp

GetDL	proc	near
	mov	bl, dl
	ret
GetDL	endp

GetDH	proc	near
	mov	bl, dh
	ret
GetDH	endp

GetCX	proc	near
	mov	bx, cx
	ret
GetCX	endp

GetDX	proc	near
	mov	bx, dx
	ret
GetDX	endp

GetBP	proc	near
	mov	bx, bp
	ret
GetBP	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CObjMessage

DESCRIPTION:	Send a message using the C calling convention

CALLED BY:	GLOBAL

C DECLARATION:	extern dword
			_far _pascal CObjMessage();

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	We get: (<params>, MessageFlags flags, MemHandle ohan, ChunkHandle och,
				Method me, MethodParameterDef mpd);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/91		Initial version

------------------------------------------------------------------------------@

COMStruct	struct
;;    COMS_savedES	word
    COMS_savedDS	word
    COMS_savedDI	word
    COMS_savedSI	word
    COMS_savedBP	word
    COMS_retAddr	dword
    COMS_mpd		word
    COMS_method		word
    COMS_obj		optr
    COMS_flags		MessageFlags
    COMS_params		label	byte		;parameters in reverse order
COMStruct	ends

COBJMESSAGE	proc	far
	push	bp, si, di, ds			;set up our stack
	mov	bp, sp				;ss:bp points at COMStruct
	lea	bx, ss:[bp].COMS_params		;ss:bx = params

	call	GetCMessageParams		;cx, dx, si = params
						;ax = extra space
	jnc	noSetStack
	ornf	ss:[bp].COMS_flags, mask MF_STACK
noSetStack:

	; Now we've loaded the parameters into the registers, do the call

	push	ax				;save extra space
	push	bx				;save ptr after params
	push	di				;save mpd
	mov	di, ss:[bp].COMS_flags
	mov	ax, ss:[bp].COMS_method
	mov	bx, ss:[bp].COMS_obj.handle
	mov	bp, ss:[bp].COMS_obj.chunk
	xchg	si, bp				;si = chunk, bp = param

	test	di, mask MF_RECORD
	jnz	doRecord

	call	ObjMessage
	jmp	CMessageReturn

	; handle MF_RECORD specially since it returns its value in di,
	; but C wants it in ax

doRecord:
	call	ObjMessage
	mov_trash	ax, di
	jmp	CMessageReturn
SwatLabel COBJMESSAGE_end
COBJMESSAGE	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CMessageDispatch

DESCRIPTION:	Dispatch an encapsulated message

CALLED BY:	GLOBAL

C DECLARATION:	extern dword
			_far _pascal CMessageDispatch();

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	We get: (eventHandle, MessageFlags flags, MethodParameterDef mpd);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/91		Initial version

------------------------------------------------------------------------------@


CODMStruct	struct
;;    CODMS_savedES	word
    CODMS_savedDS	word
    CODMS_savedDI	word
    CODMS_savedSI	word
    CODMS_savedBP	word
    CODMS_retAddr	dword
    CODMS_mpd		word
    CODMS_flags		MessageFlags
    CODMS_event		word
CODMStruct	ends

CMESSAGEDISPATCH	proc	far
	push	bp, si, di, ds			;set up our stack
	mov	bp, sp				;ss:bp points at COMStruct
	lea	bx, ss:[bp+(size CODMStruct)]	;ss:bx = after params

	clr	ax
	push	ax				;save extra space (none)
	push	bx				;save ptr after params
	mov     di,ss:[bp].CODMS_mpd            ;get mpd for MessageDispatch
	push	di				;push for CMessageReturn
	mov	bx, ss:[bp].CODMS_event
	mov	di, ss:[bp].CODMS_flags
	call	MessageDispatch
	jmp	CMessageReturn

CMESSAGEDISPATCH	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CObjCallSuper

DESCRIPTION:	Send a message using the C calling convention

CALLED BY:	GLOBAL

C DECLARATION:	extern dword
			_far _pascal CObjMessage();

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	We get: (<params>, ClassStruct _far *class, MemHandle ohan,
				ChunkHandle och, Method me,
				MethodParameterDef mpd)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/91		Initial version

------------------------------------------------------------------------------@

COMCSStruct	struct
;;    COMCSS_savedES	word
    COMCSS_savedDS	word
    COMCSS_savedDI	word
    COMCSS_savedSI	word
    COMCSS_savedBP	word
    COMCSS_retAddr	dword
    COMCSS_mpd		word
    COMCSS_method	word
    COMCSS_obj		optr
    COMCSS_class	fptr
    COMCSS_params	label	byte		;parameters in reverse order
COMCSStruct	ends

COBJCALLSUPER	proc	far
	push	bp, si, di, ds			;set up our stack
	mov	bp, sp				;ss:bp points at COMStruct
	lea	bx, ss:[bp].COMCSS_params	;ss:bx = params

	call	GetCMessageParams		;cx, dx, si = params
						;ax = extra stack

	; Now we've loaded the parameters into the registers, do the call

	push	ax				;save extra stack
	push	bx				;save ptr after params
	push	di				;save mpd
	les	di, ss:[bp].COMCSS_class
	mov	ax, ss:[bp].COMCSS_method
	mov	bx, ss:[bp].COMCSS_obj.handle
	LoadVarSeg ds
	cmp	bx, ds:[bx].HG_owner
	je	usePassedDS			; => process, so no deref
	cmp	ds:[bx].HG_type, first HandleType
	jae	usePassedDS			; => thread or queue...

	call	MemDerefDS
haveDS:
	mov	bp, ss:[bp].COMCSS_obj.chunk
	xchg	si, bp				;si = chunk, bp = param

	call	ObjCallSuperNoLock

	jmp	CMessageReturn

usePassedDS:
	mov	ds, ss:[bp].COMCSS_savedDS
	jmp	haveDS
SwatLabel COBJCALLSUPER_end
COBJCALLSUPER	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CMessageReturn

DESCRIPTION:	Get return value from message into registers for C

CALLED BY:	CObjMessage, CObjCallSuper

PASS:
	on stack - MessageParameterDef, pointer past params, extra stack
	carry
	ax, cx, dx, bp - return value from method

RETURN:
	ax, dx - return value for C

DESTROYED:
	bx, cx, si, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

CMessageReturn	proc	far jmp
EC <	call	NullSegmentRegisters					>

	pop	di				;di = mpd
	mov_trash	si, ax
	lahf					;ah = flags
	xchg	ax, si				;si = flags

	; DON'T copy stuff back that is passed in ss:bp

if	0
	; test for structure at ss:bp that must be copied back

	test	di, mask MPD_REGISTER_PARAMS or mask MPM_C_PARAMS
	jnz	noStructToCopy
	test	di, mask MSI_STRUCT_AT_SS_BP
	jz	noStructToCopy

	mov	ss:[TPD_dataAX], di		;save MPD
	pop	bx
	pop	di				;di = size to copy
	push	di
	push	bx
	push	cx, si
	mov	cx, di
	shr	cx
	les	di, ss:[bx][-4]			;es:di = dest
	segmov	ds, ss
	mov	si, bp				;ds:si = source
	rep movsw
	pop	cx, si
	mov	di, ss:[TPD_dataAX]		;recover MPD
noStructToCopy:
endif

	; handle return params (di = MPD) -- test for dword dx:ax specially

	andnf	di, mask MPD_RETURN_TYPE or mask MPD_RETURN_INFO
	cmp	di, (MRT_DWORD shl offset MPD_RETURN_TYPE) or \
			(MRDWR_DX shl ((offset MTDI_HIGH_REG)+ \
					(offset MPD_RETURN_INFO))) or \
			(MRDWR_AX shl ((offset MTDI_LOW_REG)+ \
					(offset MPD_RETURN_INFO)))
	jz	done

	mov	bx, di
	andnf	bx, mask MPD_RETURN_TYPE
	cmp	bx, MRT_VOID shl offset MPD_RETURN_TYPE		;bx = type
	jnz	notVoid

	; void returns carry if ax

returnVoid:
EC <	mov	dx, 0xcccc						>
	clr	ax
	test	si, (mask CPU_CARRY) shl 8
	jz	done
	inc	ax
	jmp	done

notVoid:
	andnf	di, mask MPD_RETURN_INFO
	push	cx
	mov	cl, offset MPD_RETURN_INFO
	shr	di, cl				;di = MethodReturnInfo
	pop	cx
	cmp	bx, MRT_BYTE_OR_WORD shl offset MPD_RETURN_TYPE
	jnz	notByteOrWord

	; return type MRT_BYTE_OR_WORD, look at MethodReturnByteWordType

	shl	di
	call	cs:[di][OMReturnByteWordTable]	;sets registers correctly
EC <	mov	dx, 0xcccc						>

done:
	pop	bx				;ss:bx points after params

	; recover extra stack space allocated

	pop	cx
	add	sp, cx


EC <	call	NullSegmentRegisters				>

	pop	bp, si, di, ds
		
	pop	cx				;cx = retAddr.offset
	dec	bx
	dec	bx				;make room for segment
	pop	ss:[bx]				;pop segment and push it
						;at new place
	mov	sp, bx				;pop off args
	push	cx

	ret

notByteOrWord:
	cmp	bx, MRT_DWORD shl offset MPD_RETURN_TYPE
	jnz	notDWord

	; return type MRT_DWORD, look at MethodReturnDWordReg

	mov	bx, cx				;bx = cx return value
	push	di
	andnf	di, mask MTDI_HIGH_REG
	mov	cl, offset MTDI_HIGH_REG
	shr	di, cl
	call	GetDWordOMReturn		;si = high word
	pop	di

	push	si				;save high word
	andnf	di, mask MTDI_LOW_REG
	call	GetDWordOMReturn		;si = low word
	mov_trash	ax, si
	pop	dx
	jmp	done

notDWord:

	; multiple return values, last param is far ptr

	pop	bx
	add	bx, 4
	push	bx
	les	bx, ss:[bx][-4]
	xchg	bx, di			;es:di points at params, bx = type

	shl	bx
	call	cs:[bx][OMReturnMultipleTable]
	jmp	returnVoid

CMessageReturn	endp

;---------------------------------------------

	; es:di = dest

OMReturnMultipleTable	nptr	OMReturnAXBPCXDX, OMReturnAXCXDXBP,
				OMReturnCXDXBPAX, OMReturnDXCX,
				OMReturnBPAXDXCX, OMReturnMULTIPLEAX

OMReturnAXBPCXDX	proc	near
	stosw
	mov_trash	ax, bp
	stosw
	mov_trash	ax, cx
	stosw
	mov_trash	ax, dx
	stosw
	ret
OMReturnAXBPCXDX	endp

OMReturnAXCXDXBP	proc	near
	stosw
	mov_trash	ax, cx
	stosw
	mov_trash	ax, dx
	stosw
	mov_trash	ax, bp
	stosw
	ret
OMReturnAXCXDXBP	endp

OMReturnCXDXBPAX	proc	near
	xchg	ax, cx				;ax = cx param, cx = ax param
	stosw
	mov_trash	ax, dx
	stosw
	mov_trash	ax, bp
	stosw
	mov_trash	ax, cx
	stosw
	ret
OMReturnCXDXBPAX	endp

OMReturnBPAXDXCX	proc	near
	xchg	ax, bp				;ax = bp param, bp = ax param
	stosw
	mov_trash	ax, bp
	stosw
	FALL_THRU	OMReturnDXCX
OMReturnBPAXDXCX	endp

OMReturnDXCX	proc	near
	mov_trash	ax, dx
	stosw
	mov_trash	ax, cx
	FALL_THRU	OMReturnMULTIPLEAX
OMReturnDXCX	endp

OMReturnMULTIPLEAX	proc	near
	stosw
	ret
OMReturnMULTIPLEAX	endp

;---------------------------------------------

OMReturnByteWordTable	nptr	OMReturnAL, OMReturnAH, OMReturnCL, OMReturnCH,
				OMReturnDL, OMReturnDH,
				OMReturnBPL, OMReturnBPH,
				OMReturnAX, OMReturnCX, OMReturnDX, OMReturnBP

OMReturnBPL	proc	near
	mov_trash	ax, bp
	GOTO	OMReturnAL
OMReturnBPL	endp

OMReturnBPH	proc	near
	mov_trash	ax, bp
	FALL_THRU	OMReturnAH
OMReturnBPH	endp

OMReturnAH	proc	near
	mov	al, ah
	FALL_THRU	OMReturnAL
OMReturnAH	endp

OMReturnAL	proc	near
	clr	ah
	FALL_THRU	OMReturnAX
OMReturnAL	endp

OMReturnAX	proc	near
	ret
OMReturnAX	endp

;-

OMReturnCH	proc	near
	mov	cl, ch
	FALL_THRU	OMReturnCL
OMReturnCH	endp

OMReturnCL	proc	near
	clr	ch
	FALL_THRU	OMReturnCX
OMReturnCL	endp

OMReturnCX	proc	near
	mov_trash	ax, cx
	ret
OMReturnCX	endp

;-

OMReturnDH	proc	near
	mov	dl, dh
	FALL_THRU	OMReturnDL
OMReturnDH	endp

OMReturnDL	proc	near
	clr	dh
	FALL_THRU	OMReturnDX
OMReturnDL	endp

OMReturnDX	proc	near
	mov_trash	ax, dx
	ret
OMReturnDX	endp

;-

OMReturnBP	proc	near
	mov_trash	ax, bp
	ret
OMReturnBP	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetDWordOMReturn

DESCRIPTION:	Get return value for a word of a dword return

CALLED BY:	ObjCallMethodTable

PASS:
	di - MethodReturnDWordReg
	bx (cx param), dx, bp - register values from method

RETURN:
	si - value

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

GetDWordOMReturn	proc	near
	shl	di
	jmp	cs:[OMReturnDWordTable][di]
GetDWordOMReturn	endp

OMReturnDWordTable	nptr	OMReturnDWordAX, OMReturnDWordCX,
				OMReturnDWordDX, OMReturnDWordBP

OMReturnDWordAX	proc	near
	mov_trash	si, ax
	ret
OMReturnDWordAX	endp

OMReturnDWordCX	proc	near
	mov	si, bx
	ret
OMReturnDWordCX	endp

OMReturnDWordDX	proc	near
	mov	si, dx
	ret
OMReturnDWordDX	endp

OMReturnDWordBP	proc	near
	mov	si, bp
	ret
OMReturnDWordBP	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetCMessageParams

DESCRIPTION:	Load params for ObjMessage or ObjCallSuperNoLock

CALLED BY:	CObjMessage, CObjCallSuper

PASS:
	ss:bp - COMStruct
	ss:bx - parameters

RETURN:
	carry - set if MF_STACK flag needs to be set
	cx, dx, si - parameters to pass (si holds bp parameter)
	di - mpd
	ss:bx - pointing after parameters
	ax - amount of extra stack space allocated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

GetCMessageParams	proc	near

	; get the MPD and start dealing with the parameters
	; (cx, dx, si) hold the parameters for (cx, dx, bp)

EC <	mov	cx, 0xcccc						>
EC <	mov	dx, 0xcccc						>
EC <	mov	si, 0xcccc						>
	mov	di, ss:[bp].COMS_mpd

	test	di, mask MPD_REGISTER_PARAMS
	jz	notRegisterParams

	push	di
	and	di, mask MPR_PARAM3
	jz	noArg3
	mov	cl, offset MPR_PARAM3
	shr	di, cl
EC <	mov	cx, 0xcccc						>
	call	GetRegisterArg
noArg3:
	pop	di

	push	di
	and	di, mask MPR_PARAM2
	jz	noArg2
	push	cx
	mov	cl, offset MPR_PARAM2
	shr	di, cl
	pop	cx
	call	GetRegisterArg
noArg2:
	pop	di

	push	di
	and	di, mask MPR_PARAM1		;MPR_PARAM1 = bit 0
	jz	noArg1
	call	GetRegisterArg
noArg1:
	pop	di
doneNoExtraStack:
	clr	ax				;clears carry
	ret

notRegisterParams:
	mov	ax, di
	test	ax, mask MPM_C_PARAMS
	jz	notCParams

	; params in C format -- if three words or less then use registers
	; di low = param size in bytes

	cmp	al, 6
	ja	moreThanThreeWords
	mov	cx, ss:[bx]
	inc	bx
	inc	bx			;always pass at least one word
	cmp	al, 2
	jbe	doneNoExtraStack
	mov	dx, ss:[bx]
	inc	bx
	inc	bx
	cmp	al, 4
	jbe	doneNoExtraStack
	mov	si, ss:[bx]
	inc	bx
	inc	bx
	jmp	doneNoExtraStack

moreThanThreeWords:
	clr	ah
stackParamsCommon:
	mov	si, bx			;ss:[bp-param] = params
	add	bx, ax			;ss:bx points after arguments
	mov_trash	dx, ax		;dx = # bytes
EC <	mov	cx, 0xcccc						>
doneNoExtraStackSetMFStack:
	clr	ax
	stc				;return carry set (set MF_STACK)
	ret

notCParams:
	test	ax, mask MSI_STRUCT_AT_SS_BP
	jz	notStructSSBP

	andnf	ax, mask MSI_PARAM_SIZE
	inc	ax
	andnf	ax, not 1		;round to words
	mov	dx, ax			;dx = # bytes

	; See if the segment passed just happens to be the stack.  If so,
	; we can optimize things and not copy all the data

	push	dx
	mov	dx, ss:[bx].segment
	mov	cx, ss
	cmp	cx, dx
	pop	dx
	jnz	copyStructureToStack

	; simple case -- just pass parameters in registers

	mov	si, ss:[bx].offset
	add	bx, (size fptr)
EC <	mov	cx, 0xcccc						>
	jmp	doneNoExtraStackSetMFStack

	; single C parameter is far pointer to structure which must be copied
	; onto the stack, passed in ss:bp and copied back

copyStructureToStack:
	pop	si			;si = return address
	sub	sp, ax			;allocate stack space
	mov	cx, sp			;ss:cx = space to copy to
	push	si			;restore return address

	push	cx			;save stack address
	push	di, ds, es
	segmov	es, ss
	lds	si, ss:[bx]		;ds:si = source
	add	bx, (size fptr)		;ss:bx points after arguments (far ptr)
	mov	di, cx			;es:di = dest
	shr	ax
	mov_trash	cx, ax		;cx = # words
	rep movsw			;copy to buffer on stack
	pop	di, ds, es
	pop	si			;bp param
EC <	mov	cx, 0xcccc						>
	mov	ax, dx			;ax = # bytes of extra stack space
	stc				;return carry set (set MF_STACK)
	ret

notStructSSBP:

	; multiple parameters passed on stack because there are too many
	; arguments to fit in registers

	andnf	ax, mask MSI_PARAM_SIZE
	jmp	stackParamsCommon

GetCMessageParams	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetRegisterArg

DESCRIPTION:	Get a register argument from the stack for CObjMessage

CALLED BY:	CObjMessage

PASS:
	di - MethodPassReg
	ss:bx - pointing at next parameter on stack

RETURN:
	ss:bx - updated
	(cx, dx, si) - updated

DESTROYED:
	ax, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

GetRegisterArg	proc	near
	mov	ax, ss:[bx]
	inc	bx
	inc	bx
	shl	di
	jmp	cs:[ArgValueTable-2][di]
GetRegisterArg	endp

ArgValueTable	nptr	ArgCL, ArgCH, ArgDL, ArgDH, ArgCX, ArgDX, ArgBP

ArgCL	proc	near
	mov	cl, al
	ret
ArgCL	endp

ArgCH	proc	near
	mov	ch, al
	ret
ArgCH	endp

ArgDL	proc	near
	mov	dl, al
	ret
ArgDL	endp

ArgDH	proc	near
	mov	dh, al
	ret
ArgDH	endp

ArgCX	proc	near
	mov_trash	cx, ax
	ret
ArgCX	endp

ArgDX	proc	near
	mov_trash	dx, ax
	ret
ArgDX	endp

ArgBP	proc	near
	mov_trash	si, ax
	ret
ArgBP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjDeref

C DECLARATION:	extern void _far *
			_far _pascal ObjDeref(MemHandle mh,
					ChunkHandle chunk, word masterLevel);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
OBJDEREF	proc	far
	C_GetThreeWordArgs	bx, ax, cx   dx	;bx = han, ax = chunk, cx = off

	push	ds
	call	MemDerefDS
	mov_trash	bx, ax
	mov	ax, ds:[bx]			;ds:ax = obj
	jcxz	done
	mov	bx, ax
EC <	xchg	ax, cx				; ax <- master off.	>
EC <	call	ECObjDeref						>
EC <	xchg	ax, cx							>
	add	bx, cx
	add	ax, ds:[bx]
done:
	mov	dx, ds
	pop	ds

	ret

OBJDEREF	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjDeref1

C DECLARATION:	extern void _far *
			_far _pascal ObjDeref1(MemHandle mh,
					ChunkHandle chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
OBJDEREF1	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = chunk

	push	ds
	call	MemDerefDS
	mov_trash	bx, ax
	mov	bx, ds:[bx]
EC <	mov	ax,4							>
EC <	call	ECObjDeref						>
	add	bx, ds:[bx][4]
	mov_trash	ax, bx
	mov	dx, ds
	pop	ds

	ret

OBJDEREF1	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjDeref2

C DECLARATION:	extern void _far *
			_far _pascal ObjDeref1(MemHandle mh,
					ChunkHandle chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
OBJDEREF2	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = chunk

	push	ds
	call	MemDerefDS
	mov_trash	bx, ax
	mov	bx, ds:[bx]
EC <	mov	ax,6							>
EC <	call	ECObjDeref						>
	add	bx, ds:[bx][6]
	mov_trash	ax, bx
	mov	dx, ds
	pop	ds

	ret

OBJDEREF2	endp
	SetDefaultConvention


if	ERROR_CHECK

ECObjDeref	proc	near
	uses	es,di
	.enter
	les	di,ds:[bx].MB_class					
	tst	es:[di].Class_masterOffset				
	ERROR_Z	OBJ_BAD_DEREF						
	cmp	es:[di].Class_masterOffset,ax				
	ERROR_B	OBJ_BAD_DEREF						
	.leave
	ret
ECObjDeref	endp

endif

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjInstantiate

DESCRIPTION:	Instantiate an object of the given class by allocating a chunk
		for the object, zeroing the new chunk, filling in the class
		pointer and passing a MSG_PROCESS_INSTANTIATE to the object (if the
		object has no master classes).  If the obejct block is run by
		a different process, instantiation is done via a remote call.

CALLED BY:	GLOBAL

PASS:
	es:di - class to instantiate a new object of
	bx - handle of block in which to instantiate the object

RETURN:
	si - handle to the new object
	ds - updated to point at segment of same block as on entry

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.


REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

ObjInstantiate	proc	far	uses ax, cx, dx, di, bp
	.enter

EC <	call	ECCheckLMemHandleNS					>
EC <	call	CheckClass						>

	; We don't know whether we can fix up ds or not.  To find out,
	; assume that ds:[0] is a handle and see if its data address
	; matches ds.

	mov	si,ds:[LMBH_handle]
	mov	ax,ds
	LoadVarSeg	ds
	test	si,15				;if any of the low 4 bits
	jnz	pushSegment			;set then not a handle
	cmp	ax,ds:[si].HM_addr
	jnz	pushSegment

	mov	ax,si				;fixupable, push handle

pushSegment:
	push	ax				;not fixup-able, push segment

	pushf

	push	bx				;save handle

	; Check for remote call

	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo			;ax = exec thread
	cmp	ax, ds:[currentThread]
	jnz	remote

	; Lock the block

	call	ObjLockObjBlock
	mov	ds,ax

	; if class has master parts, just allocate room for its base
	; structure, leaving the parts to be allocated later. If it has
	; no master parts, allocate the entire instance data for the thing.

	push	cx
	mov	cx,es:[di].Class_instanceSize	;cx = size (assume no parts)
	mov	ax,es:[di].Class_masterOffset
	tst	ax
	pushf
	jz	allocThis

	; Allocate enough room to hold the base structure.

	inc	ax
	inc	ax
	xchg	cx, ax
allocThis:

	mov	al, mask OCF_IS_OBJECT or mask OCF_DIRTY
	call	LMemAlloc
	xchg	si,ax				;*ds:si = new object
	mov	bx,ds:[si]			;ds:bx = new object

	; set chunk to zeros

	push	di,es
	segmov	es,ds			;es:di = chunk
	mov	di,bx
	clr	ax
	;
	; The non error-checking version below takes advantage of the fact that
	; LMemAlloc() always rounds up to return a block that is an even number
	; of bytes long, even if the instance data of the object is not an
	; even # of bytes in length.
	;
	; The problem is that in the error checking version, that additional
	; byte is initialized to 0xcc and is checked by the LMem error check
	; code to make sure that it isn't munged. If we initialize with the
	; 'stosw' we will zero this byte and trigger the error
	; 	LMEM_SPACE_AT_END_OF_USED_CHUNK_HAS_CHANGED.
	;
if	ERROR_CHECK
	rep stosb
else
	inc	cx
	shr	cx,1			;convert to words
	rep stosw
endif
	pop	di,es

	; Fill in class pointer

	mov	ds:[bx].MB_class.offset,di
	mov	ds:[bx].MB_class.segment,es

	; ObjCallInstance( MSG_META_INITIALIZE, np, data passed )

	popf				;recover (has parts) flag
	pop	cx
	jnz	noInit

	mov	ax,MSG_META_INITIALIZE
	call	ObjCallClassNoLock
noInit:

	; Unlock the block (preserves the carry)

	pop	bx
	call	NearUnlock

	; Reload DS with address of block at which it was pointing.
	;	on stack:

reloadDS:
	popf				;recover segment/handle flag
	pop	di
	jnz	done

	; got a handle on the stack -- do a fixup

	LoadVarSeg	ds
EC <	call	CheckMemHandleNSDI					>
	mov	di,ds:[di][HM_addr]

done:
	mov	ds, di

	.leave
	ret

;-------------------

	; Must use remote call -- ax = thread to call

remote:
	xchg	ax, bx			; ax <- block in which to instantiate,
					; bx <- thread to call
	xchg	ax, dx			; dx <- block in which to instantiate
					; (1-byte inst)
	mov	ax,MSG_PROCESS_INSTANTIATE		;method
	mov	si,di				;class is bp:si
	mov	bp,es
	mov	di,mask MF_CALL
	call	ObjMessageNear
	mov	si, bp				;chunk returned in bp
	pop	bx			; restore block handle
	jmp	reloadDS
ObjInstantiate	endp


ObjectLoad segment resource	; This function really shouldn't be in kcode.


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjInstantiateForThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ObjInstantiate an object for a thread.  Allocating a memory
		block to store the object if necessary.  The memory blocks
		and the objects instantiated in them will *NOT* be saved to
		state.

CALLED BY:	GLOBAL
PASS:		es:di	= class of new object to instantiate
		bx	= thread to run instantiated object
			  (0 for current thread)
RETURN:		^lbx:si	= optr of new object
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	2/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DESIRED_OBJECT_BLOCK_SIZE	equ	0x1000

OIFTObjLMemBlockHeader	struct
    OOLMBH_header		ObjLMemBlockHeader <>
    OOLMBH_dynamicObjBlock	hptr		; handle of next dynamicObjBlk
OIFTObjLMemBlockHeader	ends

ObjInstantiateForThread	proc	far
	uses	ax,cx,dx,di,bp,ds
	.enter

EC <	call	ECCheckClass						>

	tst	bx				; if thread=0, then instantiate
	jz	current				;  for current thread

EC <	call	ECCheckThreadHandleFar					>
	cmp	bx, ss:[TPD_threadHandle]	; if different thread
	jne	remote				;  then do remote call

current:
	; instantiating object for this thread.
	; find block to instantiate object in.

	mov	bx, ss:[TPD_dynamicObjBlock]	; start in TPD_dynamicObjBlock
blockLoop:
	tst	bx				; do we have an object block?
	jz	allocBlock			; no, then allocate a new block

	call	ObjLockObjBlock
	mov	ds, ax
	mov	cx, ds:[OOLMBH_header].OLMBH_header.LMBH_blockSize
	sub	cx, ds:[OOLMBH_header].OLMBH_header.LMBH_totalFree
	mov	ax, ds:[OOLMBH_dynamicObjBlock]	; move down linked list and
	call	MemUnlock			;  check next object block

	cmp	cx, DESIRED_OBJECT_BLOCK_SIZE	; instantiate here if block
	jb	instantiate			;  is not too big

	mov_tr	bx, ax				; bx = next object block
	jmp	blockLoop

	; we need a new object block.  allocate block.  set otherInfo.
	; add block to dynamicObjBlock linked list.

allocBlock:
	mov	ax, LMEM_TYPE_OBJ_BLOCK
	mov	cx, size OIFTObjLMemBlockHeader
	call	MemAllocLMem			; allocate object block

	mov	ax, ss:[TPD_threadHandle]
	call	MemModifyOtherInfo		; otherInfo = current thread

	call	ObjLockObjBlock			; insert new block at head of 
	mov	ds, ax				;  linked list of dyamicObjBlks
	mov	ax, bx				; ax = new obj block
	xchg	ax, ss:[TPD_dynamicObjBlock]	; head = new obj block
	mov	ds:[OOLMBH_dynamicObjBlock], ax	; link to old head
	call	MemUnlock			; and unlock

instantiate:
	call	ObjInstantiate			; now, instantiate the object
done:
	.leave
	ret

	; instantiating object for another thread.  call other thread to do it.
remote:
	mov	ax, MSG_PROCESS_INSTANTIATE_FOR_THREAD
	movdw	dxbp, esdi
	mov	di, mask MF_CALL
	call	ObjMessage
	movdw	bxsi, dxbp
	jmp	done

ObjInstantiateForThread	endp

ObjectLoad ends



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjLockObjBlock

C DECLARATION:	extern void _far *
			_far _pascal ObjLockObjBlock(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Returns NULL (0) if block is discarded.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
OBJLOCKOBJBLOCK	proc	far	; mh:hptr
	C_GetOneWordArg	bx,   ax,cx		;bx = handle

	clr	dx
	call	ObjLockObjBlock
	xchg	ax, dx
	ret

OBJLOCKOBJBLOCK	endp
	SetDefaultConvention


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjLockObjBlock

DESCRIPTION:	Lock an object block, loading in the resource if
		necessary. If the block is an LMem heap but is not an
		object block, this routine acts like MemLock.

CALLED BY:	GLOBAL

PASS:
	bx - handle of block

RETURN:
	ax - segment

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

ObjLockObjBlock	proc	far

	push	ds
	LoadVarSeg	ds

EC <	call	CheckToLock						>

	FastLock1	ds, bx, ax, OLOB_1, OLOB_2
	jc	OLOB_fullyDiscarded

if	ANALYZE_WORKING_SET
	call	WorkingSetObjBlockInUse
endif

	; Make sure the block's an object block before checking the thread
	; that runs it. This allows chunks to be copied to plain lmem blocks,
	; and, more importantly, to plain lmem blocks that are discarded
	; resources (the ObjLockObjBlock becomes, in effect, a MemLock).
	; Load ES from ds:[bx].HM_addr, rather than AX
	; to catch the case where the lock *is* actually by the wrong thread,
	; but the burden thread for the block resizes something in it in between
	; when we lock it and when we check the thing's lmemType. If we didn't
	; do this, we'd think the lmemType was 0xcc and not check the
	; burden thread, causing mysterious failure elsewhere.
EC <finish:								>
EC <	INT_OFF								>
EC <	push	es							>
EC <	mov	es, ds:[bx].HM_addr					>
EC <	cmp	es:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	jne	ok		    					>
EC <	call	ObjTestIfObjBlockRunByCurThread				>
EC <	ERROR_NZ	OBJ_LOCK_OBJ_BLOCK_BY_WRONG_THREAD		>
EC <ok:									>
EC <	pop	es							>
EC <	INT_ON								>

	pop	ds
	ret

	FastLock2	ds, bx, ax, OLOB_1, OLOB_2

	; Block is fully discarded
	; because this label is used by tcl code as such
	; OLOB_fullyDiscarded+5 if it is moved be sure to check that
	; the tcl code in /staff/pcgeos/Tools/swat/lib.new/objprof.tcl
	; still works!!!
OLOB_fullyDiscarded:
	call	FullObjLock

if	ANALYZE_WORKING_SET
	call	WorkingSetObjBlockInUse
endif

EC <	jmp	finish							>
NEC <	pop	ds							>
NEC <	ret								>
ObjLockObjBlock	endp
