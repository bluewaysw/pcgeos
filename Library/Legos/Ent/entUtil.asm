COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Ent Library
FILE:		entutil.asm
AUTHOR:		David Loftesness
ROUTINES:

	     

    INT ENTDISPATCHACTION	C Stubs for routines below

    INT ENTDISPATCHGETPROPERTY	C Stubs for routines below

    INT ENTDISPATCHSETPROPERTY	C Stubs for routines below

    GLB EntDispatchGetProperty	Search a table of PropEntryStructs for
				a given property. Takes appropriate action
				based on the value contained in the
				PropEntryStruct, if found.

    GLB EntDispatchSetProperty	Search a table of PropEntryStructs for
				a given property. Takes appropriate action
				based on the value contained in the
				PropEntryStruct, if found.

    GLB CheckTypeAndSignalError	Search a table of PropEntryStructs
				for a given property. Takes appropriate
				action based on the value contained in the
				PropEntryStruct, if found.

    GLB EntGrabTableEntry	Search a property table and return the
				PropEntryStruct

    GLB EntDispatchFromStruct	Performs the action specified in the
				passed PropEntryStruct.

    INT EntUtilGetName		Copy this component's name into the passed
				buffer

    INT EntGetVMFile		Returns the vm file the component should use
				for storing complex data

    INT ENTGETVMFILE		C Stubs for routines below

    EXT EntCreateComplexHeader	Allocates a VMBlock for storing the
				ClipboardItemHeader.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	8/31/94		Initial version.

DESCRIPTION:
	

	$Revision:   1.24  $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ENTDISPATCHACTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C Stubs for EntDispatchAction
		To use, call from within ENT_DO_ACTION handler as follows:

		   EntDispatchAction(oself, ComponentActionTable, &actionName)

		passing the reference to actionName allows this
		routine to convieniently forward variables passed on
		the stack to the assembly handlers without copying them.

CALLED BY:	GLB
PASS:		optr					component
		fptr.nptr.ActionEntryStructs		actionTable
		nptr.EntDoActionArgs			argorig
	
RETURN:		PropertyDispatchType for property, if found
		else 0
DESTROYED:	nothing
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	 12/9/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ENTDISPATCHACTION	proc far component:optr,
 				 actionTable:fptr.nptr.ActionEntryStruct,
				 args:nptr.EntDoActionArgs

		uses	si, es, ds
		.enter
		push	bp			;  uses bp is not enough
		movdw	bxsi, component
		call	MemDerefDS		; ds:si = pself
		les	bx, actionTable		; es:bx = actionTable 
		mov	bp, ss:[args]		; ss:bp = EntDoActionArgs
		call	EntDispatchAction	; okay to trash bp as long
		pop	bp			; as stack frame is restored
		.leave				
		ret
ENTDISPATCHACTION	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ENTDISPATCHGET/SETPROPERTY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C Stubs for routines below
		To use, call from within ENT_SET/GET_PROPERTY handler:

		   EntDispatchSet/GetProperty(oself, PropertyTable, &prop)

CALLED BY:	GLB
PASS:		optr					component
		fptr.nptr.PropEntryStruct		propTable
		fptr.ComponentData			value
		fptr.TCHAR				propName
RETURN:		PropertyDispatchType for property, if found
		else 0
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 1/25/95    	Initial version
	martin	 12/13/97    	Revised for optimal argument passing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ENTDISPATCHGETPROPERTY	proc far component:optr,
				 propTable:fptr.nptr.PropEntryStruct,
				 args:nptr.GetPropertyArgs

		uses	si, es, ds
		.enter
		push	bp			;  uses bp is not enough
		movdw	bxsi, component
		call	MemDerefDS		; ds:si = pself
		les	bx, propTable		; es:bx = propTable 
		mov	bp, ss:[args]		; ss:bp = GetPropertyArgs
		call	EntDispatchGetProperty	; okay to trash bp as long
		pop	bp			; as stack frame is restored
		.leave				
		ret
ENTDISPATCHGETPROPERTY	endp

ENTDISPATCHSETPROPERTY	proc far component:optr,
				 propTable:fptr.nptr.PropEntryStruct,
				 args:nptr.SetPropertyArgs

		uses	si, es, ds
		.enter
		push	bp			;  uses bp is not enough
		movdw	bxsi, component
		call	MemDerefDS		; ds:si = pself
		les	bx, propTable		; es:bx = propTable 
		mov	bp, ss:[args]		; ss:bp = SetPropertyArgs
		call	EntDispatchSetProperty	; okay to trash bp as long
		pop	bp			; as stack frame is restored
		.leave				
		ret
ENTDISPATCHSETPROPERTY	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntDispatch(Get/Set)Property
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a table of PropEntryStructs for a given property.
		Takes appropriate action based on the value contained in the
		PropEntryStruct, if found.

CALLED BY:	GLOBAL

PASS:		*ds:si = component being queried
		es:bx = property table (list of nptr.PropEntryStructs)
		ss:bp = SetPropertyArgs or GetPropertyArgs

RETURN:		if property found:
			ax = PropertyDispatchType
		else
			ax = 0

		if ax = PDT_WORD_DATA:
			cx:dx = PropertyData
		if ax = PDT_DWORD_DATA:
			cx:dx = dword data
		if ax = PDT_SEND_MESSAGE
			cx:dx = nothing interesting

DESTROYED:	ax & dx, though more may be destroyed by called methods or
		routines via PDT_CALL_FPTR or PDT_SEND_MESSAGE

		always preserved:	ds, si, es

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	8/30/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EntDispatchGetProperty	proc	far
		.enter
		Assert_fptr			esbx
		Assert_chunk			si, ds
		movdw	dxcx, ss:[bp].GPA_propName
		Assert_nullTerminatedAscii	dxcx

		call	EntGrabTableEntry 	; es:dx = PropEntryStruct
		mov	ax, dx			; check error
		inc	ax
		jz	notFound

		mov	ax, PDT_UNDEFINED_PROPERTY
		mov	bx, dx
		cmp	es:[bx].PES_get.PDS_dispatchType, ax
		je	notFound
		
		Assert_nptr	dx, es

		mov_tr	bx, dx
		add	bx, offset PES_get
		call	EntDispatchFromStruct
		Assert_etype	ax, PropertyDispatchType
notFound:
		.leave
		ret
EntDispatchGetProperty	endp

EntDispatchSetProperty	proc	far
		.enter
		
		Assert_fptr			esbx
		Assert_chunk			si, ds
		movdw	dxcx, ss:[bp].SPA_propName
		Assert_nullTerminatedAscii	dxcx

		call	EntGrabTableEntry 	; es:dx = PropEntryStruct
		mov	ax, dx
		inc	ax			; check error
		jz	notFound

		mov	ax, PDT_UNDEFINED_PROPERTY
		mov	bx, dx
		cmp	es:[bx].PES_get.PDS_dispatchType, ax
		je	done

	; assume the worst
		mov	ax, PDT_ERROR
		
	;
	; Check that the type is correct, dispatch if so
	;
		Assert_nptr	dx, es
		call	CheckTypeAndSignalError
		jc	done

		mov	bx, dx
		add	bx, offset PES_set
		call	EntDispatchFromStruct
done:
		Assert_etype	ax, PropertyDispatchType
notFound:
		.leave
		ret
EntDispatchSetProperty	endp

		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTypeAndSignalError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check to see if passed type equals expected type

CALLED BY:	
PASS:		
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:	do some simple conversions if possible
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckTypeAndSignalError		proc	far
	;
	; args: es:dx = PropEntryStruct
	;	ss:bp = SetPropertyArgs
	; return: flags set, je will jump if types match
	;	ax = PDT_ERROR
	;
		push	ds, di
		lds	bx, ss:[bp].SPA_compDataPtr
		mov	di, dx
		mov	di, es:[di].PES_propType
		cmp	ds:[bx].CD_type, di
		je	done
	;
	; signal error
	;
		cmp	di, LT_TYPE_NONE
		je	done			; don't do type checking on
						; TYPE_NONE properties...

	; if we are expecting an integer and get a long, see if the
	; long is actually a legal integer value, and if so, coerce it
		cmp	di, LT_TYPE_INTEGER
		jne	notLongToInt

		cmp	ds:[bx].CD_type, LT_TYPE_LONG
		jne	notLongToInt

	; now check the long value
		mov	ds:[bx].CD_type, LT_TYPE_INTEGER
		tst	ds:[bx].CD_data.LD_long.high
		jz	done
		cmp	ds:[bx].CD_data.LD_long.high, 0xffff
		je	done
		jmp	error
notLongToInt:
	; check for int to long...
		cmp	di, LT_TYPE_LONG
		jne	error
		cmp	ds:[bx].CD_type, LT_TYPE_INTEGER
		jne	error
	; convert the int to a long
		mov	ds:[bx].CD_type, LT_TYPE_LONG
	; test high bit
		clr	ds:[bx].CD_data.LD_long.high
		test	ds:[bx].CD_data.LD_integer, 0x8000
		jz	done
		mov	ds:[bx].CD_data.LD_long.high, 0xffff
		clc
		jmp	done
error:
		mov	ds:[bx].CD_type, LT_TYPE_ERROR
		mov	ds:[bx].CD_data.LD_error, \
			CPE_PROPERTY_TYPE_MISMATCH
		stc
done:
		pop	ds, di
		ret
		
CheckTypeAndSignalError		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntDispatchAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a table of ActionEntryStructs for a given action.
		Takes appropriate action based on the value contained in the
		ActionEntryStruct, if found.

CALLED BY:	GLOBAL

PASS:		*ds:si = component being queried
		es:bx = action table (list of nptr.ActionEntryStructs)
		ss:bp = EntDoActionArgs

RETURN:		if action found:
			ax = 1
		else
			ax = 0

				

DESTROYED:	ax & dx, though more may be destroyed by called methods or
		routines via PDT_CALL_FPTR or PDT_SEND_MESSAGE

		always preserved:	ds, si, es

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/30/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EntDispatchAction	proc	far
		.enter
		Assert_fptr			esbx
		Assert_chunk			si, ds
		movdw	dxcx, ss:[bp].EDAA_actionName
		Assert_nullTerminatedAscii	dxcx

		call	EntGrabTableEntry 	; es:dx = ActionEntryStruct
		mov	ax, dx			; check error
		inc	ax
		jz	notFound

		Assert_nptr	dx, es
		mov	bx, dx
		mov	ax, es:[bx].AES_message
		call	ObjCallInstanceNoLock
	;;  now stuff a non-zero value into ax so we know it got handled
		mov	ax, 1
notFound:
		.leave
		ret
EntDispatchAction	endp
public EntDispatchAction

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGrabTableEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a property table and return the PropEntryStruct
		Also works on action tables conveniently enough

CALLED BY:	GLOBAL
PASS:		es:bx = property table (list of nptr.PropEntryStructs)
		dx:cx = name of property to look for

RETURN:		dx = nptr.PropEntryStruct, if found
		dx = -1, if not found
DESTROYED:	ax, cx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	1/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGrabTableEntry	proc	near
	uses 	ds, si, di, bx
	.enter

		mov	di, cx			
		segmov	ds, es, cx		; ds:bx -> prop table
						; es:di -> prop name
		mov	es, dx
		call	LocalStringLength
		inc	cx			; count the NULL
		mov_tr	ax, cx			; store length in ax

		mov	dx, di			; store pointer in dx
tableLoop:
		mov	cx, ax			; restore string length
	;
	; es:di - property to look for
	; cx	- length of property string
	; ds:bx - fptr to table of nptr.PropEntryStruct
	;
		mov	si, ds:[bx]
		cmp	si, ENT_PROPERTY_TABLE_TERMINATOR   ; end of table?
		jz	notFound

		mov	si, ds:[si].PAC_name	; deref string
EC <		Assert	okForRepCmpsb					>
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		mov	di, dx			; restore property name ptr
		jz	foundIt
		add	bx, size nptr
		jmp	tableLoop
notFound:
		mov	dx, -1
done:
		segmov	es, ds, ax		; quicker than "uses es"
	.leave
		ret
foundIt:
	;
	; ds:[bx] is pointing at nptr.PropEntryStruct.  Deref and return in
	; dx.
	;
		mov	dx, ds:[bx]
		jmp	done
EntGrabTableEntry	endp



		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetPropNameAndDataCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common routine for getting a property by its prop number

CALLED BY:	GLOBAL
PASS:		cx:bx = propertyTable pointer
		di = pointer to super class
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetPropNameAndDataCommon	proc	far
		.enter
		push	es, ds, di, bx, si
		mov	ax, ss:[bp].EGPNADS_propNum
	; map prop number to message number
		shl	ax
		add	ax, MSG_ENT_GET_PROPERTY_0
		mov	es, cx
		call	EntGrabPropertyTableEntryForPropNum
		push	ds
		.assert offset EGPNADS_getProp eq 0
		lds	di, ss:[bp].GPA_compDataPtr
		mov	ds:[di].CD_type, LT_TYPE_ERROR
		pop	ds
		cmp	si, ENT_PROPERTY_TABLE_TERMINATOR
		jne	getProp

		pop	es, ds, di, bx, si
		mov	ax, MSG_ENT_GET_PROPERTY_NAME_AND_DATA
		call	ObjCallSuperNoLock
		jmp	done
getProp:
		push	ds
		lds	di, ss:[bp].EGPNADS_name
		mov	si, es:[si].PES_propName
		movdw	ss:[bp].EGPNADS_getProp.GPA_propName, essi
	; es:si = propName
	; ds:di = name buffer
		segxchg	es, ds
		LocalCopyString
		segmov	es, ds
		pop	ds
		pop	es, ds, di, dx, si ; save new bx, trash dx
		mov	ax, MSG_ENT_GET_PROPERTY
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
EntGetPropNameAndDataCommon	endp
	public EntGetPropNameAndDataCommon
		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGrabTableEntryForPropNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		es:bx = property table (list of nptr.PropEntryStructs)
		ax = propNum
RETURN:		si = TABLE_TERMINATOR if not found, or es:si = PropEntryStruct
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGrabPropertyTableEntryForPropNum	proc	far
		.enter
tableLoop:
	;
	; es:bx - fptr to table of nptr.PropEntryStruct
	;
		mov	si, es:[bx]
		cmp	si, ENT_PROPERTY_TABLE_TERMINATOR   ; end of table?
		jz	done

		cmp	ax, es:[si].PES_get.PDS_dispatchData.PD_message
		je	done
		add	bx, size nptr
		jmp	tableLoop
done:
		.leave
		ret
EntGrabPropertyTableEntryForPropNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntDispatchFromStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs the action specified in the passed PropEntryStruct.

CALLED BY:	GLOBAL
PASS:		es:bx = PropEntryStruct
		ds:si = locked object to send message to, if necessary

		all other registers (except ax) can be used to pass data to
		called method or routine.

RETURN:		ax = PropertyDispatchType
		if ax = PDA_WORD_DATA,
			cx = word data
		if ax = PDA_DWORD_DATA
			dx:cx = dword data

		other registers are set by called method or routine (for
		PDA_SEND_MESSAGE and PDA_CALL_FPTR)

DESTROYED:	nothing, unless destroyed by called method or routine
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	1/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntDispatchFromStruct	proc	near
		uses	bx
		.enter

		mov	ax, es:[bx].PDS_dispatchType
		cmp	ax, PDT_SEND_MESSAGE
		je	sendMessage
		cmp	ax, PDT_DWORD_DATA
		je	returnData
		cmp	ax, PDT_WORD_DATA
		je	returnData
	CheckHack <PDT_WORD_DATA lt PDT_DWORD_DATA>
		cmp	ax, PDT_CALL_FPTR
		je	doCall
done:
		.leave
		ret
returnData:
		movdw	dxcx, es:[bx].PDS_dispatchData
	CheckHack <(size PropertyDispatchData) eq (size dword)>
		jmp	done
sendMessage:
		mov	ax, es:[bx].PDS_dispatchData.PD_message
		call	ObjCallInstanceNoLock
		mov	ax, PDT_SEND_MESSAGE
		jmp	done

doCall:
		call	es:[bx].PDS_dispatchData.PD_fptr
		mov	ax, PDT_CALL_FPTR
		jmp	done
		
EntDispatchFromStruct	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the vm file the component should use for storing
		complex data

CALLED BY:	External
PASS:		ds	- segment of component object block
RETURN:		ax	= vm file handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 2/06/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetVMFile	proc	far
		uses	bx, cx, dx, es, si, di
		.enter
	;
	; Ask the interpreter for the ptask.
	;
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		movdw	bxsi, ds:[EOBH_interpreter], ax
		mov	ax, MSG_INTERP_GET_STATE
		call	ObjMessage		; ax = ptask handle
	;
	; Get the vm file associated with this ptask.
	;
		push	ax			; one arg to c func
		call	ProgGetVMFile
		add	sp, size word		; restore arg

		.leave
		ret
EntGetVMFile	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ENTGETVMFILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C Stubs for routines below

CALLED BY:	GLB
PASS:		optr					component
RETURN:		vm file handle
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 2/6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
ENTGETVMFILE	proc far component:optr
		uses	ds, bx
		.enter

		mov	bx, component.handle
		call	ObjLockObjBlock
		mov	ds, ax
		call	EntGetVMFile
		call	MemUnlock
		
		.leave
		ret
ENTGETVMFILE	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntCreateComplexHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a VMBlock for storing the ClipboardItemHeader.

CALLED BY:	EXTERNAL
PASS:		bx	= VMFileHandle to create block in
RETURN:		ax	= VMBlock of ClipboardItemHeader, dirty
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 2/08/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntCreateComplexHeader	proc	far

		uses	cx
		.enter
		clr	ax			;id
		mov	cx, size ClipboardItemHeader
		call	VMAlloc
		.leave
	ret
EntCreateComplexHeader	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntDestroyTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	destroy a component tree, its children, and remove it from
		all trees (Ent, Gen, Vis)

CALLED BY:	GLOBAL
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	FIXME:	Make sure the Ent linkage is updated in the parent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntDestroyTree	method	EntClass,	MSG_ENT_DESTROY
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	al, ds:[di].EI_state
	clr	ah		
	push	ax

	test	ax, mask ES_IS_GEN
	jz	notUsable
	
	;;  lets set gen objects no usable so we don't have to watch
	;;  the tree unbuild itself in all its glorious detail

	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjCallInstanceNoLock
notUsable:
	
	;; first recurse down the ent tree
	mov	ax, MSG_ENT_DESTROY
	mov	bx, ds:LMBH_handle
	mov	di, mask MF_RECORD
	call	ObjMessage
	
	mov	cx, di	;  move event handle into cx for ENT_SENT_TO_CHILDREN
	mov	ax, MSG_ENT_SEND_TO_CHILDREN
	call	ObjCallInstanceNoLock

	pop	ax		;  grab entflags from stack

	;;
	;; Remove the Ent linkages without destroying anything
	call EntRemoveSelfFromParent

	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	bx, ds:LMBH_handle
	;;  if its a GEN thing, then do a GenDestroy, if its vis do 
	;;  a VisDestroy else do a MetaDetach
	
	test	ax, mask ES_IS_GEN
	jz	tryVis
	clr	bp
	mov	di, mask MF_CALL	
	mov	ax, MSG_GEN_DESTROY
	call	ObjMessage
	jmp	done
tryVis:
	test	ax, mask ES_IS_VIS
	jz	doMeta
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_DESTROY
	call	ObjMessage
	jmp	done
doMeta:

	;; send the object a detach, with the ack going to the app object
	;; remove the object from its parent the ent tree

	clr	cx
	mov_tr	ax, si
	mov_tr	si, ax
	movdw	dxbp, bxsi
	clr	di
	mov	ax, MSG_META_DETACH
	call	ObjMessage
done:
	.leave
	ret
EntDestroyTree	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntRemoveSelfFromParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove self from parent's ent linkage.

CALLED BY:	EntDestroyTree
PASS:		^lbx:si		- object to remove
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntRemoveSelfFromParent	proc	near
	uses	ax,bx,cx,dx,si,di, bp
		.enter
		pushdw	bxsi		; self
		mov	ax, MSG_ENT_GET_PARENT
		call	ObjCallInstanceNoLock
		movdw	bxsi, cxdx		; parent
		popdw	cxdx		; self, object to remove
		mov	ax, MSG_ENT_REMOVE_CHILD
		mov	bp, mask CCF_MARK_DIRTY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		
		.leave
		ret
EntRemoveSelfFromParent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deal with EntDestroy for non Gen/Vis objects

CALLED BY:	MSG_META_ACK
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 3/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntAck	method dynamic EntClass, MSG_META_ACK
	uses	ax
	.enter
	mov	ax, MSG_META_OBJ_FREE
	call	ObjCallInstanceNoLock
	.leave
	ret
EntAck	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntAppMetaAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't free the app

CALLED BY:	MSG_META_ACK
PASS:		*ds:si	= EntAppClass object
		ds:di	= EntAppClass instance data
		ds:bx	= EntAppClass object (same as *ds:si)
		es 	= segment of EntAppClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntAppMetaAck	method dynamic EntAppClass, 
					MSG_META_ACK
		.enter
	; note, we are skipping Ent's handler here so we don't free the app.
		
		mov	di, offset EntClass
		call	ObjCallSuperNoLock
		.leave
		ret
EntAppMetaAck	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ENTRESOLVEPROPERTYACCESS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for EntResolvePropertyAccess

CALLED BY:	GLOBAL

C DECLARATION:	extern Boolean _far _pascal
		    EntResolvePropertyAccess(PropEntryStruct _near **propTable,
					     EntResolveStruct* ers);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
ENTRESOLVEPROPERTYACCESS	proc far \
	propTable:fptr.nptr.PropEntryStruct,
	resolve:fptr.EntResolveStruct

	uses	si, di, es, ds
	.enter
		les	bx, propTable
		mov	dx, resolve.segment
		mov	bp, resolve.offset
		call	EntResolvePropertyAccess

		cmc			; set ax if successful
		mov	ax, 0
		adc	ax, ax
	.leave
	ret
ENTRESOLVEPROPERTYACCESS	endp
public ENTRESOLVEPROPERTYACCESS
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntResolvePropertyAccess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a table of PropEntryStructs for a given property.
		Returns the Get message -- add one to get Set message.

CALLED BY:	GLOBAL

PASS:		es:bx = property table (list of nptr.PropEntryStructs)
		dx:bp = EntResolveStruct

RETURN:		carry set if not found, otherwise dx:bp filled in

DESTROYED:	ax, cx
		always preserved:	ds, si, es

BUGS/THOUGHTS:	Why not just return the PropEntryStruct? --dubois

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	5/8/95		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EntResolvePropertyAccess 	proc 	far
	uses	ds,si, es,di, bx,dx
	.enter
		Assert	fptr	esbx
		Assert	fptr	dxbp

		mov	ds, dx
		movdw	dxcx, ds:[bp].ERS_propOrAction
		Assert	nullTerminatedAscii	dxcx

		call	EntGrabTableEntry 	; es:dx = PropEntryStruct
		cmp	dx, -1
		LONG_EC	je	notFound

		segxchg	es, ds
		mov	si, dx		; ds:si - PropEntryStruct
		Assert	nptr	si, ds

	; extract data from the PropEntryStruct (ds:si) into
	; EntResolveStruct (es:bp)
	;
		cmp	ds:[si].PES_get.PDS_dispatchType, PDT_UNDEFINED_PROPERTY
		jne	cont
		mov	es:[bp].ERS_type, LT_TYPE_VOID
		jmp	found	
cont:
		memmov	es:[bp].ERS_message, \
			ds:[si].PES_get.PDS_dispatchData.PD_message, ax

		memmov	es:[bp].ERS_type, ds:[si].PES_propType, ax
	; since we are using TYPE_VOID to indicate an undefined
	; property, we better not be returning an actual property of
	; type LT_TYPE_VOID - if this turns out to be problem we could
	; add another type, or added another field to the EntResolveStruct
		Assert_ne es:[bp].ERS_type, LT_TYPE_VOID

	; Fill type buffer if necessary
	;
		tstdw	es:[bp].ERS_typeBuf
		jz	found		; no buffer to fill
		cmp	ds:[si].PES_propType, LT_TYPE_STRUCT
		jne	found

		mov	si, ds:[si].EPES_typeName
		les	di, es:[bp].ERS_typeBuf
		
		mov	cx, ENT_TYPE_BUFFER_LENGTH
		LocalCopyNString	; rep movs[bw]
found:
		clc
done:
		.leave
		ret
notFound:
		stc
		jmp	done
EntResolvePropertyAccess	endp
public EntResolvePropertyAccess

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntResolveAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a table of ActionEntryStructs for a given action
		Returns the appropriate message.

CALLED BY:	GLOBAL

PASS:		es:bx = property table (list of nptr.PropEntryStructs)
		dx:bp = EntResolveStruct

RETURN:		carry set if not found, otherwise dx:bp filled in

DESTROYED:	ax,cx
		always preserved:	ds, si, es

BUGS/THOUGHTS:	Why not just return the PropEntryStruct? --dubois

PSEUDOCODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/8/95		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntResolveAction 	proc 	far
	uses	ds,es, si,di, bx,dx
	.enter
		Assert	fptr			esbx
		Assert	fptr			dxbp

		mov	ds, dx
		movdw	dxcx, ds:[bp].ERS_propOrAction
		Assert	nullTerminatedAscii	dxcx

		call	EntGrabTableEntry 	; es:dx = ActionEntryStruct
		cmp	dx, -1
		LONG_EC	je	notFound

		mov	di, dx
		Assert	nptr	di, es

	; extract the message data from the PropEntryStruct
	;
		memmov	ds:[bp].ERS_message, es:[di].AES_message, ax
		memmov	ds:[bp].ERS_type, es:[di].AES_type, ax
		memmov	ds:[bp].ERS_numParams, es:[di].AES_numParams
	; Fill type buffer if necessary
	;
		tstdw	ds:[bp].ERS_typeBuf
		jz	found
		cmp	es:[di].AES_type, LT_TYPE_STRUCT
		jne	found

		segxchg	ds, es
		mov	si, ds:[di].EAES_typeName
		les	di, es:[bp].ERS_typeBuf
		mov	cx, ENT_TYPE_BUFFER_LENGTH
		LocalCopyNString	; rep movs[bw]
found:
		clc
done:
	.leave
	ret
notFound:
		stc
		jmp	done
EntResolveAction	endp
public EntResolveAction



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntUtilCheckClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code to check a class

CALLED BY:	GLOBAL
PASS:		cx:dx = child to validate, es:di = class to check
RETURN:		ax = 0 if object in class
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntUtilCheckClass proc	far
		.enter
		mov	bx, cx
		call	ObjLockObjBlock

		mov	ds, ax
		mov	si, dx			; *ds:si = potential child
		call	ObjIsObjectInClass

		jnc	reject

		clr	ax
done:
		call	MemUnlock
		
		.leave
		ret
reject:
		mov	ax, 1
		jmp	done
			
EntUtilCheckClass	endp
public EntUtilCheckClass



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntUtilGetProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to get a property.

CALLED BY:	Utility
PASS:		es:bx	= property table
		ax	= segment of class
		di	= offset of class
		ss:bp	= GetPropertyArgs
RETURN:		(see EntDispatchGetProperty, EntGetPropertyFromTable)
DESTROYED:	ax, cx, dx, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 6/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntUtilGetProperty	proc	far
		.enter
	;
	; Do we know about this property?
	;
		push	ax				; save class seg
		call	EntDispatchGetProperty
		tst	ax
		jz	callSuper
		cmp	ax, PDT_UNDEFINED_PROPERTY
		jne	done
	;
	; It's an undefined property, so try it as a custom property.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		call	EntGetPropertyFromTable
		jmp	done
	;
	; We don't know about the property, perhaps the superclass does.
	;
callSuper:
		pop	es
		sub	sp, 2
		mov	ax, MSG_ENT_GET_PROPERTY
		call	ObjCallSuperNoLock
done:
		add	sp, 2				; fixup stack
		.leave
		ret
EntUtilGetProperty	endp
public EntUtilGetProperty



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntUtilSetProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code for setting properties

CALLED BY:	all ent class property setting routines
PASS:		es:bx = property table
		ax = segment of class
		di = offset of class 
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntUtilSetProperty	proc	far
		.enter

	;
	; Do we know about this property
	;
		push	ax				; save class seg
		call	EntDispatchSetProperty
		tst	ax
		jz	callSuper

	; see if it was an undefined property, if so, try it as a
	; custom property
		cmp	ax, PDT_UNDEFINED_PROPERTY
		jne	done

	; ok, it was an undefined property, add it as a custom
	; property
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		call	EntSetPropertyInTable
		jmp	done
callSuper:
        ;
	; We don't know about the property, perhaps the superclass does
	;
		pop	es
		sub	sp, 2
		mov	ax, MSG_ENT_SET_PROPERTY
		call	ObjCallSuperNoLock
		
done:
		add	sp, 2				; fixup stack
		.leave
		ret
EntUtilSetProperty	endp
public EntUtilSetProperty



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntResolvePropertyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for resolve handlers

CALLED BY:	EXTERNAL, All ent resolve handlers

PASS:		es:bx = property table
		dx:bp = EntResolveStruct
		ax = segment of class
		di = offset of class

RETURN:		carry	- set if not found
		dx:bp	- filled in if found

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntResolvePropertyCommon	proc	far
		.enter

		push	cx
		push	ax
		
		call	EntResolvePropertyAccess
		jc	callSuper
	; make sure its not an UNDEFINED_PROPERTY
		mov	es, dx
		cmp	es:[bp].ERS_type, LT_TYPE_VOID
		je	undefinedProperty
		clc
		jmp	done
callSuper:
		pop	es
		push	es
		mov	ax, MSG_ENT_RESOLVE_PROPERTY
		call	ObjCallSuperNoLock
done:
		pop	ax
		pop	cx
		.leave
		ret
undefinedProperty:
		stc
		jmp	done
EntResolvePropertyCommon	endp
public EntResolvePropertyCommon



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntResolveActionCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for resolve handlers

CALLED BY:	EXTERNAL, All ent resolve handlers

PASS:		es:bx = action table
		dx:bp = EntResolveStruct
		ax = segment of class
		di = offset of class

RETURN:		carry	- set if not found
		dx:bp	- filled in if found

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntResolveActionCommon	proc	far
		.enter

		push	ax				; save class seg
		call	EntResolveAction
		pop	es
		jnc	done

		mov	ax, MSG_ENT_RESOLVE_ACTION
		call	ObjCallSuperNoLock
done:
		.leave
		ret
EntResolveActionCommon	endp
public EntResolveActionCommon



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntUtilDoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code for doing generic actions

CALLED BY:	
PASS:		*ds:si	- component
		es:bx	- action table (list of nptr.ActionEntryStructs)
		ss:bp	- EntDoActionArgs
		ax	- segment of class
		di	- offset of class 
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntUtilDoAction	proc	far
	.enter

	;
	; Do we know about this property
	;
		push	ax				; save class seg
		call	EntDispatchAction
		tst	ax
		jnz	done
        ;
	; We don't know about the property, perhaps the superclass does
	;
		pop	es
		sub	sp, 2
		mov	ax, MSG_ENT_DO_ACTION
		call	ObjCallSuperNoLock
done:
		add	sp, 2				; fixup stack
	.leave
	ret
EntUtilDoAction	endp
public EntUtilDoAction
