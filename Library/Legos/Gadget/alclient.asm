COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Service Components (Alarm component)
FILE:		alclient.asm

AUTHOR:		dubois, Aug 29, 1995

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_ENT_DO_ACTION	

    MTD MSG_ENT_RESOLVE_ACTION	

    MTD MSG_ENT_GET_CLASS	

    INT GetAlarmServer		Call alarm server, passing locked id in
				cx:dx

    INT ObjMessageAlarmServerGetID
				Call alarm server, passing locked id in
				cx:dx

    MTD MSG_META_RESOLVE_VARIANT_SUPERCLASS
				Inform system that we are Meta but not Gen
				or Vis

    MTD MSG_META_INITIALIZE	Clear some flags that ent sets

    MTD MSG_ENT_DESTROY		Clean up timer when component gets
				destroyed

    MTD MSG_ENT_INITIALIZE	Arrange our properties the way we wants 'em

    MTD MSG_SAC_GET_UNIQUE_ID,
	MSG_SAC_GET_MODULE_CONTEXT
				Legos Property Handler -- uniqueID

    MTD MSG_SAC_SET_UNIQUE_ID	Legos Property Handler -- set uniqueID

    MTD MSG_SAC_SET_MODULE_CONTEXT
				Legos Property Handler -- set moduleContext

    MTD MSG_SAC_SET_ENABLED	Set the "enabled" property

    MTD MSG_SAC_GET_ENABLED	Get the "enabled" property

    MTD MSG_SAC_ACTION_SETALARMDATE,
	MSG_SAC_ACTION_SETALARMTIME
				Set alarmDate/alarmTime property

    MTD MSG_SAC_ACTION_GETALARMDATE,
	MSG_SAC_ACTION_GETALARMTIME
				Get alarmDate/alarmTime property

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/29/95   	Initial revision


DESCRIPTION:
	Defines Alarm service component.

	$Id: alclient.asm,v 1.1 98/03/11 04:31:02 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include alserver.def
idata	segment
ServiceAlarmClientClass
idata	ends


GadgetAlarmClientCode		segment resource
;; Name of event raised in SA_ALARM_DING
;;
makePropEntry alarm, uniqueID, LT_TYPE_STRING,			\
	PDT_SEND_MESSAGE, <PD_message	MSG_SAC_GET_UNIQUE_ID>,	\
	PDT_SEND_MESSAGE, <PD_message	MSG_SAC_SET_UNIQUE_ID>

makePropEntry alarm, enabled, LT_TYPE_INTEGER,			\
	PDT_SEND_MESSAGE, <PD_message	MSG_SAC_GET_ENABLED>,	\
	PDT_SEND_MESSAGE, <PD_message	MSG_SAC_SET_ENABLED>

makePropEntry alarm, moduleContext, LT_TYPE_STRING,			\
	PDT_SEND_MESSAGE, <PD_message	MSG_SAC_GET_MODULE_CONTEXT>,	\
	PDT_SEND_MESSAGE, <PD_message	MSG_SAC_SET_MODULE_CONTEXT>

compMkPropTable _nuke, alarm, \
	uniqueID, enabled, moduleContext

makeExtendedActionEntry alarm, GetAlarmDate \
	MSG_SAC_ACTION_GETALARMDATE, LT_TYPE_STRUCT, Date, 0
makeExtendedActionEntry alarm, SetAlarmDate \
	MSG_SAC_ACTION_SETALARMDATE, LT_TYPE_VOID, Date, 1
	
makeExtendedActionEntry alarm, GetAlarmTime \
	MSG_SAC_ACTION_GETALARMTIME, LT_TYPE_STRUCT, TimeOfDay, 0
makeExtendedActionEntry alarm, SetAlarmTime \
	MSG_SAC_ACTION_SETALARMTIME, LT_TYPE_VOID, TimeOfDay, 1
	
compMkActTable alarm, \
	GetAlarmDate, SetAlarmDate, \
	GetAlarmTime, SetAlarmTime

MakeSystemPropRoutines ServiceAlarmClient, alarm

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;% Standard methods for using and resolving non-byte-compiled actions
;% and properties, returning class name.  These are all cookie-cutter
;% routines.
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

COMMENT @
DESCRIPTION:	

@

SACEntDoAction	method dynamic ServiceAlarmClientClass, MSG_ENT_DO_ACTION
		segmov	es, cs
		mov	bx, offset alarmActionTable
		mov	di, offset ServiceAlarmClientClass
		mov	ax, segment dgroup
		call	EntUtilDoAction
		ret
SACEntDoAction	endm

SACEntResolveAction method dynamic ServiceAlarmClientClass, MSG_ENT_RESOLVE_ACTION
		segmov	es, cs
		mov	bx, offset alarmActionTable
		mov	di, offset ServiceAlarmClientClass
		mov	ax, segment dgroup
		call	EntResolveActionCommon
		ret
SACEntResolveAction endm


SACEntGetClass method dynamic ServiceAlarmClientClass, MSG_ENT_GET_CLASS
		mov	cx, segment ServiceAlarmClientString
		mov	dx, offset ServiceAlarmClientString
		ret
SACEntGetClass endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAlarmServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve alarm server object

CALLED BY:	EXTERNAL
PASS:		ds	- sptr.EntObjBlockHeader
RETURN:		carry	- set if found
		^lbx:si	- alarm server, or NullOptr
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAlarmServer	proc far
	uses	ax,cx,dx,bp,di
	.enter
		EntGetInterpreter	bxsi
		mov	ax, MSG_INTERP_GET_ALARM_SERVER
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		movdw	bxsi, cxdx
		tstdw	bxsi
		jz	notOK
		Assert	optr, bxsi
		clc
done:
	.leave
	ret
notOK:
		stc
		jmp	done
GetAlarmServer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessageAlarmServerGetID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call alarm server, passing locked id in cx:dx

CALLED BY:	INTERNAL
PASS:		*ds:si	- AlarmClient object
		ax	- message
		bp	- arg

RETURN:		ax,cx,dx- as returned by alarm server
		bp	- unchanged!
		carry	- set if call did not reach the server

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessageAlarmServerGetID	proc	near
	class	ServiceAlarmClientClass
	uses	bx,di, bp, es
	.enter
		Assert	objectPtr, dssi, ServiceAlarmClientClass
		Assert	ge, ax, MSG_AFS_CLIENT_ATTACH
	; These take uniqueID on the stack, or don't take uniqueID
		Assert	ne, ax, MSG_AFS_SET_CONTEXT
		Assert	ne, ax, MSG_AFS_PUT_ALARM_ENTRY

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset

		push	si
		push	ax
		mov	ax, ds:[di].SACI_uniqueID
		tst	ax
		jz	pop2_done

	; Get the server, stc if failed
		call	GetAlarmServer
		jc	pop2_done

		call	RunHeapLock_asm
		movdw	cxdx, esdi
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		pop	ax
		call	ObjMessage
		pop	si

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		push	ax
		mov	ax, ds:[di].SACI_uniqueID
		call	RunHeapUnlock_asm
		pop	ax
		clc
done:
	.leave
	ret
pop2_done:
		pop	ax
		pop	si
	;		add	sp, 4
		stc
		jmp	done
ObjMessageAlarmServerGetID	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform system that we are Meta but not Gen or Vis

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		cx	- Master class offset
RETURN:		cxdx	- ClassPtr of superclass
DESTROYED:	
PSEUDO CODE/STRATEGY:
	Return ML2Class, a null-ish class at the 2nd master level

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACMetaResolveVariantSuperclass	method dynamic ServiceAlarmClientClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
	;uses	ax, bp
	.enter
	; Only variant class to resolve should be Ent
	; since ML2Class is master but not variant
	;
EC <		cmp	cx, Ent_offset					>
EC <		ERROR_NE -1						>
		mov	cx, segment ML2Class
		mov	dx, offset ML2Class
	.leave
	ret
SACMetaResolveVariantSuperclass	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear some flags that ent sets

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= ServiceAlarmClientClass object
		ds:di	= ServiceAlarmClientClass instance data
		ds:bx	= ServiceAlarmClientClass object (same as *ds:si)
		es 	= segment of ServiceAlarmClientClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	SACI_date must hold a valid TimerCompressedDate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACMetaInitialize	method dynamic ServiceAlarmClientClass, 
					MSG_META_INITIALIZE
	uses	ax, cx, dx, bp
	.enter
		mov	di, offset ServiceAlarmClientClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		BitClr	ds:[di].EI_state, ES_IS_GEN
		BitClr	ds:[di].EI_state, ES_IS_VIS

		clr	ax
		mov	ds:[di].SACI_uniqueID, ax
	.leave
	ret
SACMetaInitialize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up timer when component gets destroyed

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= ServiceAlarmClientClass object
		ds:di	= ServiceAlarmClientClass instance data
		ds:bx	= ServiceAlarmClientClass object (same as *ds:si)
		es 	= segment of ServiceAlarmClientClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACEntDestroy	method dynamic ServiceAlarmClientClass, MSG_ENT_DESTROY
	uses	ax
	.enter
		mov	ax, MSG_AFS_CLIENT_DETACH
		call	ObjMessageAlarmServerGetID
	.leave
		mov	di, offset ServiceAlarmClientClass
		call	ObjCallSuperNoLock
	ret
SACEntDestroy	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Arrange our properties the way we wants 'em

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= ServiceAlarmClientClass object
		ds:di	= ServiceAlarmClientClass instance data
		ds:bx	= ServiceAlarmClientClass object (same as *ds:si)
		es 	= segment of ServiceAlarmClientClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACEntInitialize	method dynamic ServiceAlarmClientClass, 
					MSG_ENT_INITIALIZE
	uses	ax, cx, dx, bp
	.enter
		mov	di, offset ServiceAlarmClientClass
		call	ObjCallSuperNoLock
	.leave
	ret
SACEntInitialize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACGetUniqueId
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler -- uniqueID

CALLED BY:	MSG_SAC_GET_UNIQUE_ID
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACGetUniqueId	method dynamic ServiceAlarmClientClass, 
					MSG_SAC_GET_UNIQUE_ID
	uses	bp
	.enter
		mov	ax, ds:[di].SACI_uniqueID
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax
	.leave
	Destroy	ax, cx, dx
	ret
SACGetUniqueId	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACGetModuleContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler -- get moduleContext

CALLED BY:	MSG_SAC_GET_MODULE_CONTEXT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/31/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACGetModuleContext	method dynamic ServiceAlarmClientClass, 
					MSG_SAC_GET_MODULE_CONTEXT
	uses	bp
	.enter
		push	ax
		mov	ax, MSG_AFS_GET_ALARM_ENTRY
		call	ObjMessageAlarmServerGetID
		movdw	esbx, cxdx
		pop	ax
		jc	errorDone

		mov	di, es:[bx].AE_moduleContext
		mov	di, es:[di]
		mov	ax, es		; ax:di <- string to put on heap
		call	LocalStringLength
		inc	cx		; add null
DBCS <		shl	cx		; convert to size		>
		mov	dl, 0		; 0 reference count
		mov	bx, RHT_STRING
		call	RunHeapAlloc_asm; ax <- token

		mov	bx, es:[LMBH_handle]
		call	MemUnlock

		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax
done:
	.leave
	Destroy	ax, cx, dx
	ret
errorDone:
		les	bx, ss:[bp].SPA_compDataPtr
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, \
			CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done
SACGetModuleContext	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACSetUniqueId
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler -- set uniqueID

CALLED BY:	MSG_SAC_SET_UNIQUE_ID
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACSetUniqueId	method dynamic ServiceAlarmClientClass, 
					MSG_SAC_SET_UNIQUE_ID
	uses	bp
	.enter

	; Empty string is an illegal uniqueID
		les	bx, ss:[bp].SPA_compDataPtr
		mov	ax, es:[bx].CD_data.LD_string
		push	di
		call	RunHeapLock_asm

	;
	; Check the length of the string.
	;

		call	LocalStringLength
		pop	di
		call	RunHeapUnlock_asm

		MAX_ID_LENGTH equ 150

		jcxz	errorDone
		cmp	cx, MAX_ID_LENGTH
		ja	errorDone
		

	; Sever connection between this object and the state kept by server
	; OK if this fails -- probably will, at build time
		mov	bx, ds:[di].SACI_uniqueID
		tst	bx
		jz	afterDetach
		mov	ax, MSG_AFS_CLIENT_DETACH
		call	ObjMessageAlarmServerGetID

		mov_tr	ax, bx
		call	RunHeapDecRef_asm

afterDetach:
	; ... and attach ourself to a different bit of state
		les	bx, ss:[bp].SPA_compDataPtr
		mov	bx, es:[bx].CD_data.LD_string
		mov	ds:[di].SACI_uniqueID, bx
		tst	bx
		jz	afterAttach

		mov	bp, ds:[EOBH_task]
		mov	ax, MSG_AFS_CLIENT_ATTACH
		call	ObjMessageAlarmServerGetID

		mov_tr	ax, bx
		call	RunHeapIncRef_asm
afterAttach:
done:
	.leave
	Destroy	ax, cx, dx
	ret
errorDone:
		les	bx, ss:[bp].SPA_compDataPtr
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, \
			CPE_PROPERTY_SIZE_MISMATCH
		jmp	done
	
SACSetUniqueId	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACSetModuleContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler -- set moduleContext

CALLED BY:	MSG_SAC_SET_MODULE_CONTEXT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACSetModuleContext	method dynamic ServiceAlarmClientClass, 
					MSG_SAC_SET_MODULE_CONTEXT
	uses	bp
	.enter
		mov	cx, ds:[di].SACI_uniqueID
		tst	cx
		jz	errorDone

		push	si
		call	GetAlarmServer	; bx:si <- alarm server
		jc	error_pop1

		les	di, ss:[bp].SPA_compDataPtr
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapLock_asm

		push	bp

		pushdw	esdi		; arg1: module context
		mov_tr	ax, cx
		call	RunHeapLock_asm
		pushdw	esdi		; arg2: uniqueID

		mov	di, mask MF_CALL or mask MF_STACK or \
				mask MF_FIXUP_DS
		mov	bp, sp
		mov	dx, 8		; 2 fptrs - 8 bytes
		mov	ax, MSG_AFS_SET_CONTEXT
		call	ObjMessage
		add	sp, 8
		pop	bp
		pop	si

	; Unlock the strings
	;
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		mov	ax, ds:[di].SACI_uniqueID
		call	RunHeapUnlock_asm

		les	di, ss:[bp].SPA_compDataPtr
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapUnlock_asm
done:
	.leave
	Destroy	ax, cx, dx
	ret
error_pop1:
		pop	si

errorDone:
		les	bx, ss:[bp].SPA_compDataPtr
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, \
			CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done
SACSetModuleContext	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the "enabled" property

CALLED BY:	MSG_SAC_SET_ENABLED
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACSetEnabled	method dynamic ServiceAlarmClientClass, 
					MSG_SAC_SET_ENABLED
	uses	bp
	.enter
		les	bx, ss:[bp].SPA_compDataPtr
		mov	bp, es:[bx].CD_data.LD_integer
		mov	ax, MSG_AFS_SET_ENABLED
		call	ObjMessageAlarmServerGetID
		jc	errorDone

		tst	ax
		jz	errorDone
done:
	.leave
	Destroy	ax, cx, dx
	ret
errorDone:
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, \
			CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done
SACSetEnabled	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACGetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the "enabled" property

CALLED BY:	MSG_SAC_GET_ENABLED
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACGetEnabled	method dynamic ServiceAlarmClientClass, 
					MSG_SAC_GET_ENABLED
	uses	bp
	.enter
		mov	ax, MSG_AFS_GET_ALARM_ENTRY
		call	ObjMessageAlarmServerGetID
		jc	errorDone
		movdw	esdi, cxdx	; cx:dx <- alarm entry

		clr	ax		; assume not enabled
		tst	es:[di].AE_enabled
		jz	returnIt
		mov	ax, 1

returnIt:
		mov	bx, es:[LMBH_handle]
		call	MemUnlock

		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
done:
	.leave
	Destroy	ax, cx, dx
	ret
errorDone:
		les	bx, ss:[bp].GPA_compDataPtr
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, \
			CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done
SACGetEnabled	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACActionSetalarmdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set alarmDate/alarmTime property

CALLED BY:	MSG_SAC_ACTION_SETALARMDATE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Year is restricted to be in [1980, 2099]
	Client does all validation of args.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACActionSetalarmdate	method dynamic ServiceAlarmClientClass, 
					MSG_SAC_ACTION_SETALARMDATE,
					MSG_SAC_ACTION_SETALARMTIME
	uses	bp
	.enter
		mov_tr	cx, ax		; save message

	; Get struct fields into ax, bh, bl
	; Perform initial coarse bounds checks -- all values should
	; be byte-sized.  More precise checking will be done further down
	;
		les	bx, ss:[bp].EDAA_argv
		cmp	es:[bx].CD_type, LT_TYPE_STRUCT
		mov	ax, CAE_WRONG_TYPE
		jne	errorDone
		mov	ax, es:[bx].CD_data.LD_struct
		call	RunHeapLock_asm		; es:bx <- locked entry

		mov	dx, es:[di][0].LSF_value.low
		cmp	cx, MSG_SAC_ACTION_SETALARMDATE
		jz	getNext		; year is allowed to be > 255
		tst	dh
		jnz	unlockDataError
getNext:
		tst	es:[di][5].LSF_value.low.high
		jnz	unlockDataError
		mov	bh, es:[di][5].LSF_value.low.low

		tst	es:[di][10].LSF_value.low.high
		jnz	unlockDataError
		mov	bl, es:[di][10].LSF_value.low.low

		call	RunHeapUnlock_asm
		mov_tr	ax, dx

	; ax,bh,bl - date or time, cx - message
		push	cx
		push	ax
		mov	ax, MSG_AFS_GET_ALARM_ENTRY
		call	ObjMessageAlarmServerGetID	; cx:dx <- entry
		pop	ax
		pop	di		; di <- message
		jc	specificError

		mov	es, cx
		xchg	di, dx		; esdi <- entry, dx <- message
		cmp	dx, MSG_SAC_ACTION_SETALARMDATE
		je	setDate
setTime::
		mov	es:[di].AE_hour, al
		mov	es:[di].AE_minute, bh
		mov	es:[di].AE_second, bl
		jmp	putEntry
setDate:
		mov	es:[di].AE_year, ax
		mov	es:[di].AE_month, bh
		mov	es:[di].AE_day, bl
putEntry:
		push	si
		pushdw	esdi
ifdef __HIGHC__
		call	ValidEntryDateAndTime	; trashes everything!
else
		call	_ValidEntryDateAndTime	; trashes everything!
endif
		popdw	cxdx		; cx:dx <- entry to put
		pop	si
		tst	ax
		jz	specificError

		mov	ax, MSG_AFS_PUT_ALARM_ENTRY
		call	GetAlarmServer
		Assert	carryClear
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		tst	ax
		jz	specificError
done:
	.leave
	Destroy	ax, cx, dx
	ret
unlockDataError:
		call	RunHeapUnlock_asm
specificError:
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
errorDone:
		les	bx, ss:[bp].EDAA_retval
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, ax
		jmp	done

SACActionSetalarmdate	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACActionGetalarmdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get alarmDate/alarmTime property

CALLED BY:	MSG_SAC_ACTION_GETALARMDATE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACActionGetalarmdate	method dynamic ServiceAlarmClientClass, 
					MSG_SAC_ACTION_GETALARMDATE,
					MSG_SAC_ACTION_GETALARMTIME
	uses	bp
	.enter
		push	ax
		mov	ax, MSG_AFS_GET_ALARM_ENTRY
		call	ObjMessageAlarmServerGetID
		pop	ax
		jc	errorDone
		movdw	esdi, cxdx
		cmp	ax, MSG_SAC_ACTION_GETALARMDATE
		je	getDate

	; Get time or date into ax:cx:dx
getTime::
		clr	ah
		mov	al, es:[di].AE_hour
		mov	ch, ah
		mov	cl, es:[di].AE_minute
		mov	dh, ah
		mov	dl, es:[di].AE_second
		jmp	setIt
getDate:
		mov	ax, es:[di].AE_year
		clr	ch
		mov	cl, es:[di].AE_month
		mov	dh, ch
		mov	dl, es:[di].AE_day
setIt:
		mov	bx, es:[LMBH_handle]
		call	MemUnlock

		les	di, ss:[bp].EDAA_runHeapInfoPtr
		call	ServiceAlloc3IntStruct	; es:di <- struct, bx <- token

		mov	es:[di][0].LSF_value.low, ax
		mov	es:[di][5].LSF_value.low, cx
		mov	es:[di][10].LSF_value.low, dx

		mov_tr	ax, bx
		call	RunHeapUnlock_asm

		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_STRUCT
		mov	es:[di].CD_data.LD_struct, ax
done:
	.leave
	Destroy	ax, cx, dx
	ret
errorDone:
		les	bx, ss:[bp].EDAA_retval
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done
SACActionGetalarmdate	endm

GadgetAlarmClientCode		ends
