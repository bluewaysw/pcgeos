COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		syslanch.asm

AUTHOR:		RON, Apr 16, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/16/96		Initial revision


DESCRIPTION:
	
		

	$Id: syslanch.asm,v 1.1 98/03/11 04:29:42 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetHardIconClass	class	GenTriggerClass ;GadgetButtonClass
	MSG_HARD_ICON_PRESSED	message
	GHI_launcher	optr
	GHI_iconNumber  word
GadgetHardIconClass	endc

DEFAULT_MEMORY_RESERVED	equ 32		; kilobytes
;
; Deal with all the ui for the launcher class here.
; Keep it separate from the component as it is likely to change.
; The component has no ui in the spec.
GenLauncherClass	class GenInteractionClass
GenLauncherClass	endc

idata	segment
	theLauncherArray dword	0	; Array of all launcher components
	SystemLauncherClass
	GadgetHardIconClass
	GenLauncherClass
	memoryReserved	word	DEFAULT_MEMORY_RESERVED
	memoryReservedFlag	word 0	; Gets set to 1 once memoryReserved
					; is set.
idata	ends

public theLauncherArray

makeActionEntry launcher, SwitchTo, MSG_SYSTEM_LAUNCHER_ACTION_SWITCH_TO, LT_TYPE_VOID, 1
makeActionEntry launcher, GoTo, MSG_SYSTEM_LAUNCHER_ACTION_GO_TO, LT_TYPE_VOID, 2
;; _GoTo is temporary, because the compiler thinks goto is a token
makeActionEntry launcher, _GoTo, MSG_SYSTEM_LAUNCHER_ACTION_GO_TO, LT_TYPE_VOID, 2
makeActionEntry launcher, RequestMemory, MSG_SYSTEM_LAUNCHER_ACTION_REQUEST_MEMORY, LT_TYPE_INTEGER, 1

makeActionEntry launcher, Hide, MSG_SYSTEM_LAUNCHER_ACTION_HIDE, LT_TYPE_VOID, 1

compMkActTable launcher, SwitchTo, _GoTo, GoTo, RequestMemory, Hide

; _memoryRequest, _memoryDemand, _outOfMemory

MakeSystemActionRoutines SystemLauncher, launcher
;MakeSystemActionProp SystemLauncher, launcher

makePropEntry launcher, memoryAvailable, LT_TYPE_INTEGER, \
   PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_LAUNCHER_GET_MEMORY_AVAILABLE>, \
   PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_LAUNCHER_SET_MEMORY_AVAILABLE>

makePropEntry launcher, memoryReserve, LT_TYPE_INTEGER, \
   PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_LAUNCHER_GET_MEMORY_RESERVED>, \
   PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_LAUNCHER_SET_MEMORY_RESERVED>

compMkPropTable SystemLauncherProperty, launcher, memoryAvailable, memoryReserve

MakeSystemPropRoutines SystemLauncher, launcher
include sysstats.def
include	Internal/heapInt.def

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemLauncherMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the system know our real class tree. 

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= SystemLauncherClass object
		ds:di	= SystemLauncherClass instance data
		ds:bx	= SystemLauncherClass object (same as *ds:si)
		es	= segment of SystemLauncherClass
		ax	= message #
RETURN:		cx:dx	= fptr to class
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemLauncherMetaResolveVariantSuperclass	method dynamic SystemLauncherClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
		
		compResolveSuperclass SystemLauncher, GenLauncher

SystemLauncherMetaResolveVariantSuperclass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemLauncherEntGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= SystemLauncherClass object
		ds:di	= SystemLauncherClass instance data
		ds:bx	= SystemLauncherClass object (same as *ds:si)
		es	= segment of SystemLauncherClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemLauncherEntGetClass	method dynamic SystemLauncherClass, 
					MSG_ENT_GET_CLASS
		.enter
		mov	cx, segment SystemLauncherString
		mov	dx, offset SystemLauncherString
		.leave
		ret
SystemLauncherEntGetClass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenLauncherMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the inteaction as Dialog.

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= GenLauncherClass object
		ds:di	= GenLauncherClass instance data
		ds:bx	= GenLauncherClass object (same as *ds:si)
		es 	= segment of GenLauncherClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenLauncherMetaInitialize	method dynamic GenLauncherClass, 
					MSG_META_INITIALIZE

		.enter
		mov	di, offset GenLauncherClass
		call	ObjCallSuperNoLock

	; Take care of our Gen instance data.
	; (can be done in META_INITIALIZE of geninteraction subclass)
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].GII_type, GIT_ORGANIZATIONAL
		mov	ds:[di].GII_visibility, GIV_DIALOG
		mov	ds:[di].GII_attrs, mask GIA_NOT_USER_INITIATABLE

		.leave
		ret
GenLauncherMetaInitialize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SLMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we are marked as Gen

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= SystemLauncherClass object
		ds:di	= SystemLauncherClass instance data
		ds:bx	= SystemLauncherClass object (same as *ds:si)
		es 	= segment of SystemLauncherClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	7/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SLMetaInitialize	method dynamic SystemLauncherClass, 
					MSG_META_INITIALIZE
	uses	ax, cx, dx, bp
		.enter
		mov	di, offset SystemLauncherClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		BitSet	ds:[di].EI_state, ES_IS_GEN
		.leave
		ret
SLMetaInitialize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SLEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some destruction

CALLED BY:	MSG_ENT_DESTROY
PASS:		*ds:si	= SystemLauncherClass object
		ds:di	= SystemLauncherClass instance data
		ds:bx	= SystemLauncherClass object (same as *ds:si)
		es 	= segment of SystemLauncherClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SLEntDestroy	method dynamic SystemLauncherClass, 
					MSG_ENT_DESTROY
	uses	ax, cx, dx, bp
	.enter
		mov	di, offset theLauncherArray
		call	GadgetUtilRemoveSelfFromArray

		mov	ax, MSG_ENT_DESTROY
		mov	di, offset SystemLauncherClass
		call	ObjCallSuperNoLock

	.leave
	ret
SLEntDestroy	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemLauncherEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create some ui for hard icons.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= SystemLauncherClass object
		ds:di	= SystemLauncherClass instance data
		ds:bx	= SystemLauncherClass object (same as *ds:si)
		es	= segment of SystemLauncherClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Add to global array of launchers

	Notify alarm server of our creation, if one exists for this
	component's interpreter.

	This stuff probably could go in SPEC_BUILD_BRANCH instead.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/16/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemLauncherEntInitialize	method dynamic SystemLauncherClass, 
					MSG_ENT_INITIALIZE
		.enter
	;
	; Let the superclass do its thing.
	;
		mov	di, offset SystemLauncherClass
		call	ObjCallSuperNoLock

	; Add to array, notify alarm server in case it's waiting
	; on creation of a launcher to set off some alarms.
	; See discussion in alserver.goc header
	;
		mov	di, offset theLauncherArray
		call	GadgetUtilAddSelfToArray
		push	bx,si
		call	GetAlarmServer
		jc	afterNotify
		mov	ax, MSG_AFS_ACTIVATE_ALARMS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage	;ax cx dx bp
afterNotify:
		pop	bx,si
		

		mov	ax, HINT_ORIENT_CHILDREN_HORIZONTALLY
		clr	cx
		call	ObjVarAddData

		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		mov	cx, 6		; create 6 buttons


	;
	; Create the buttons
	;
addButton:

		mov	ax, segment GadgetHardIconClass
		mov	es, ax
		mov	di, offset GadgetHardIconClass

	; create the button
		push	cx		; loop variable
		mov	dx, si		; primary nptr
		mov	bx, ds:[LMBH_handle]
		mov	cx, bx
		call	ObjInstantiate
	; ds:si = child, ds:dx = primary
	; add it to the primary
		mov	ax, MSG_GEN_ADD_CHILD
		xchg	dx, si		; cx:dx - child
		mov	bp, CCO_FIRST
		call	ObjCallInstanceNoLock

		xchg	dx, si
		push	dx		; primary

		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	cx, cs
		mov	dx, offset defaultMoniker
		mov	bp, VUM_NOW
		call	ObjCallInstanceNoLock

	; set it usable
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

.warn -private
	; store the primary in the button
		mov	di, ds:[si]
		add	di, ds:[di].GadgetHardIcon_offset
		mov	bx, ds:[LMBH_handle]
		pop	si		; primary
		movdw	ds:[di].GHI_launcher, bxsi
		

	; repeat
		pop	cx		; loop variable
		mov	bx, cx
		dec	bx
		mov	ds:[di].GHI_iconNumber, bx
.warn @private
		loop	addButton

	;
	; Move the primary to the bottom and add some buttons
	; to simulate hard icons.
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

		call	VisMarkFullyInvalid

		mov	ax, HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT
		mov	cx, size SpecWinSizePair
		call	ObjVarAddData
		mov	ds:[bx].SWSP_x, 20	; mask SWSS_RATIO or PCT_40
		mov	ds:[bx].SWSP_y, 300	;mask SWSS_RATIO or PCT_100

		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock


		.leave
		ret
SystemLauncherEntInitialize	endm
defaultMoniker	TCHAR "h", 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SLAlarmRing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise the _ring event

CALLED BY:	MSG_SL_ALARM_RING
PASS:		*ds:si	= SystemLauncherClass object
		ds:di	= SystemLauncherClass instance data
		ds:bx	= SystemLauncherClass object (same as *ds:si)
		es 	= segment of SystemLauncherClass
		ax	= message #
		ss:bp	= AlarmRingStruct
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/31/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlarmRingStruct	struct
    contextOptr		optr
    mlOptr		optr
AlarmRingStruct	ends

alarmString	TCHAR	"alarm", 0
SLAlarmRing	method dynamic SystemLauncherClass, MSG_SL_ALARM_RING
	passedBP local	word	push	bp
	params	local	EntHandleEventStruct
	result	local	ComponentData
ForceRef	result			; Not used yet, maybe later

	uses	ax, cx, dx, bp
	.enter

	; convert mlString to runheap string
		mov	di, ss:[passedBP]
		mov	bx, ss:[di].mlOptr.high
		push	bx
		call	MemLock
		mov	es, ax
		mov	di, ss:[di].mlOptr.low
		mov	di, es:[di]	; ax:di <- string to put on heap
		call	LocalStringLength
		inc	cx		; add null
DBCS <		shl	cx		; convert to size		>
		mov	dl, 0		; 0 reference count
		mov	bx, RHT_STRING
		call	RunHeapAlloc_asm; ax <- token
		pop	bx
		call	MemUnlock
		push	ax

	; convert contextString to runheap string
		mov	di, ss:[passedBP]
		mov	bx, ss:[di].contextOptr.high
		push	bx
		call	MemLock
		mov	es, ax
		mov	di, ss:[di].contextOptr.low
		mov	di, es:[di]	; ax:di <- string to put on heap
		call	LocalStringLength
		inc	cx		; add null
DBCS <		shl	cx		; convert to size		>
		mov	dl, 0		; 0 reference count
		mov	bx, RHT_STRING
		call	RunHeapAlloc_asm
		mov_tr	cx, ax		; cx <- context token
		pop	bx
		call	MemUnlock
		pop	bx		; bx <- ML token

		mov	ax, offset alarmString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		mov	ss:[params].EHES_argc, 2
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_STRING
		mov	ss:[params].EHES_argv[0].CD_data.LD_string, bx
		mov	ss:[params].EHES_argv[(size ComponentData)].CD_type, LT_TYPE_STRING
		mov	ss:[params].EHES_argv[(size ComponentData)].CD_data.LD_string, cx
		lea	ax, ss:[result]
		movdw	ss:[params].EHES_result, ssax
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss
		lea	dx, ss:[params]	; cx:dx <- params
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjCallInstanceNoLock
	.leave
	ret
SLAlarmRing	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemLauncherActionGoTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise the goTo event with the correct actions

CALLED BY:	MSG_SYSTEM_LAUNCHER_ACTION_GO_TO
PASS:		ds,si,di,bx,es,ax - standard method stuff
		argc	= 2
		argv	= STRING(application), STRING(context)
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
goToString	TCHAR	"goTo", 0
SystemLauncherActionGoTo	method dynamic SystemLauncherClass, 
					MSG_SYSTEM_LAUNCHER_ACTION_GO_TO
		passedBP local	word	push	bp
		params	local	EntHandleEventStruct
		result	local	ComponentData
ForceRef	result		; Not used yet, mayber later
		.enter

	; Check and extract arguments

		mov	ax, CAE_WRONG_NUMBER_ARGS
		mov	di, ss:[passedBP]
		cmp	ss:[di].EDAA_argc, 2
		jne	error

		les	di, ss:[di].EDAA_argv
		mov	ax, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	error
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_STRING
		jne	error

	; cx <- application, dx <- context

		mov	cx, es:[di].CD_data.LD_string
		mov	dx, es:[di][size ComponentData].CD_data.LD_string
		
		mov	ax, offset goToString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 2

		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_STRING
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, cx

		mov	ss:[params].EHES_argv[(size ComponentData)].CD_type, LT_TYPE_STRING
		mov	ss:[params].EHES_argv[(size ComponentData)].CD_data.LD_integer, dx

		mov	dx, ax
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
error:
	;
	; Some error, ax contains which one.
		les	di, ss:[di].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
		
SystemLauncherActionGoTo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemLauncherActionSwitchTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise the switchTo event with the correct actions

CALLED BY:	MSG_SYSTEM_LAUNCHER_ACTION_SWITCH_TO
PASS:		*ds:si	= SystemLauncherClass object
		ds:di	= SystemLauncherClass instance data
		ds:bx	= SystemLauncherClass object (same as *ds:si)
		es 	= segment of SystemLauncherClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
switchToString	TCHAR	"switchTo", 0
SystemLauncherActionSwitchTo	method dynamic SystemLauncherClass, 
					MSG_SYSTEM_LAUNCHER_ACTION_SWITCH_TO
		passedBP local	word	push	bp
		params	local	EntHandleEventStruct
		result	local	ComponentData
ForceRef	result		; Not used yet, mayber later
		.enter
	;
	; Grab in the passed actions
	;
		mov	ax, CAE_WRONG_NUMBER_ARGS
		mov	di, ss:[passedBP]
		cmp	ss:[di].EDAA_argc, 1
		jne	error
		les	di, ss:[di].EDAA_argv
		mov	ax, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	error
		mov	dx, es:[di].CD_data.LD_string
		
		mov	ax, offset switchToString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 1
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_STRING
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, dx
		mov	dx, ax
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
error:
	;
	; Some error, ax contains which one.
		les	di, ss:[di].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
		
SystemLauncherActionSwitchTo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemLauncherActionRequestMemory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Action Handler

CALLED BY:	MSG_SYSTEM_LAUNCHER_ACTION_REQUEST_MEMORY
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If the memory requested + memory reserved > memory available
			send _requestMemory event

		Then we probably should send demandMemory, outOfMemory.
		(Do we want to send outOfMemory instead of just return
		an error)  Should outOfMemory be reserved for system requests.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	6/10/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemLauncherActionRequestMemory	method dynamic SystemLauncherClass, 
					MSG_SYSTEM_LAUNCHER_ACTION_REQUEST_MEMORY
		.enter
	;
	; check args
		mov	ax, CAE_WRONG_NUMBER_ARGS
		cmp	ss:[bp].EDAA_argc, 1
		jne	error

		mov	ax, CAE_WRONG_TYPE
		les	di, ss:[bp].EDAA_argv
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	error

	;
	; Decide if we need to send event
	;
		call	GetMemoryAvailLow
		mov	dx, ax			; mem avail
		mov	ax, es:[di].CD_data.LD_integer	; requested
		segmov	es, dgroup, cx
		sub	dx, es:[memoryReserved]
		cmp	dx, ax			; avail > requested?
		jge	afterEvent

	;
	; send event
	;
		call	RaiseRequestEvent

afterEvent:
	; FIXME: always return the requested amount.
	; should return 0 if not enough.
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
done:
	.leave
	Destroy	ax, cx, dx
		ret
error:
	; ax = error
		les	di, ss:[bp].EDAA_retval
		Assert	fptr, esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done

SystemLauncherActionRequestMemory	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetHardIconHardIconPressed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_HARD_ICON_PRESSED
PASS:		*ds:si	= GadgetHardIconClass object
		ds:di	= GadgetHardIconClass instance data
		ds:bx	= GadgetHardIconClass object (same as *ds:si)
		es	= segment of GadgetHardIconClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/16/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
clickString		TCHAR	"hardIconPressed", C_NULL
GadgetHardIconHardIconPressed	method dynamic GadgetHardIconClass, 
					MSG_GEN_TRIGGER_SEND_ACTION
		params	local	EntHandleEventStruct
		result	local	ComponentData
ForceRef	result		; Not used yet, mayber later
		.enter

		pushdw	ds:[di].GHI_launcher
		push	ds:[di].GHI_iconNumber
		push	bp			; frame ptr
		mov	di, offset GadgetHardIconClass
		call	ObjCallSuperNoLock
		pop	bp			; frame ptr
		pop	dx		; icon number
		
		mov	ax, offset clickString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 1
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, dx
		mov	dx, ax
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		popdw	bxsi				; launcher
		call	ObjMessage
		.leave
		ret
GadgetHardIconHardIconPressed	endm

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetHardIconMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetHardIconClass object
		ds:di	= GadgetHardIconClass instance data
		ds:bx	= GadgetHardIconClass object (same as *ds:si)
		es 	= segment of GadgetHardIconClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetHardIconMetaResolveVariantSuperclass	method dynamic GadgetHardIconClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
		compResolveSuperclass GadgetHardIcon, GenTrigger

		ret
GadgetHardIconMetaResolveVariantSuperclass	endm
endif		


;
; Don't allow anyone to close the launcher dialog as there
; is now way of getting it back.
GupInteractionCommand	method dynamic GenLauncherClass,
					MSG_GEN_GUP_INTERACTION_COMMAND
		.enter

		cmp	cx, IC_DISMISS
		je 	done

		mov	di, offset GenLauncherClass
		call	ObjCallSuperNoLock
done:
		
		.leave
		ret
GupInteractionCommand	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RaiseRequestEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a basic event so the user can draw a cell

CALLED BY:	INTERNAL
PASS:		*ds:si	- Launcher Component
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		FIXME, merge with RaiseChangedEvent, save some code space!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
launcherRequestString TCHAR "memoryRequest", 0

RaiseRequestEvent	proc	near
 		params		local	EntHandleEventStruct
		result		local	ComponentData
		ForceRef	result
		uses	ax, cx, dx, bp, si, di, bp
		.enter
		Assert	objectPtr dssi, SystemLauncherClass

		mov	di, offset launcherRequestString
		movdw	ss:[params].EHES_eventID.EID_eventName, csdi
		lea	di, result
		movdw	ss:[params].EHES_result, ssdi
		mov	ss:[params].EHES_argc, 1
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, ax
		lea	dx, ss:[params]
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock

		.leave
		ret
RaiseRequestEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemLauncherGetMemoryAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_SYSTEM_LAUNCHER_GET_MEMORY_AVAILABLE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RB	6/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemLauncherGetMemoryAvailable	method dynamic SystemLauncherClass, 
					MSG_SYSTEM_LAUNCHER_GET_MEMORY_AVAILABLE
		.enter

		call	GetMemoryAvailLow

		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_data.LD_integer, ax
		mov	es:[di].CD_type, LT_TYPE_INTEGER
	.leave
	Destroy	ax, cx, dx
	ret
SystemLauncherGetMemoryAvailable	endm

method GadgetUtilReturnReadOnlyError, SystemLauncherClass, MSG_SYSTEM_LAUNCHER_SET_MEMORY_AVAILABLE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMemoryAvailLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the amount of available memory (as reported by
		SysGetInfo)

CALLED BY:	GetMemoryAvailble, RequesetMemory
PASS:		nothing
RETURN:		ax		- Avail mem in k bytes
DESTROYED:	dx, cx
SIDE EFFECTS:	Doesn't compress the heap.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RB	6/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMemoryAvailLow	proc	near
		.enter
	;
	; This doesn't account for swap space.
	; If you want to, use SGIT_SWAP_FREE_SIZE too
		mov	ax, SGIT_HEAP_FREE_SIZE
		call	SysGetInfo
	;
	; convert bytes to k
	;
		mov	cx, 10		; FIXME a div may be more efficient?
		
divide:
		sardw	dxax
		loop	divide

		.leave
		ret
GetMemoryAvailLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemLauncherGetMemoryReserved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_SYSTEM_LAUNCHER_GET_MEMORY_RESERVED
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RB	6/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemLauncherGetMemoryReserved	method dynamic SystemLauncherClass, 
					MSG_SYSTEM_LAUNCHER_GET_MEMORY_RESERVED

		.enter
		segmov	es, dgroup, ax
		mov	ax, es:[memoryReserved]
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
		.leave
		Destroy	ax, cx, dx
		ret
SystemLauncherGetMemoryReserved	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemLauncherSetMemoryReserved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_SYSTEM_LAUNCHER_SET_MEMORY_RESERVED
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Set the library global variable for memory reserved as long as
		it isn't already set.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RB	6/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemLauncherSetMemoryReserved	method dynamic SystemLauncherClass, 
					MSG_SYSTEM_LAUNCHER_SET_MEMORY_RESERVED
		.enter
		les	di, ss:[bp].GPA_compDataPtr
		mov	dx, es:[di].CD_data.LD_integer
		segmov	es, dgroup, ax
		cmp	es:[memoryReservedFlag], 0
		jne	done
		inc	es:[memoryReservedFlag]
		cmp	dx, 0
		ja	setReserve
		clr	dx
setReserve:
		mov	es:[memoryReserved], dx
		
done:
		.leave
		Destroy	ax, cx, dx
		ret
SystemLauncherSetMemoryReserved	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemLauncherActionHide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Action Handler

CALLED BY:	MSG_SYSTEM_LAUNCHER_ACTION_HIDE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Generate the hide event

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	6/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
launcherHideString	TCHAR	"hide", 0
SystemLauncherActionHide	method dynamic SystemLauncherClass, 
					MSG_SYSTEM_LAUNCHER_ACTION_HIDE

		passedBP	local	word	push	bp
 		params		local	EntHandleEventStruct
		result		local	ComponentData
		ForceRef	result
		uses	ax, cx, dx, bp, si, di, bp
		.enter
		mov	bx, ss:[passedBP]
		mov	ax, CAE_WRONG_NUMBER_ARGS
		cmp	ss:[bx].EDAA_argc, 1
		jne	error
		les	di, ss:[bx].EDAA_argv
		mov	ax, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	error

		mov	ax, es:[di].CD_data.LD_string	; application to hide
		
		Assert	objectPtr dssi, SystemLauncherClass

		mov	di, offset launcherHideString
		movdw	ss:[params].EHES_eventID.EID_eventName, csdi
		lea	di, result
		movdw	ss:[params].EHES_result, ssdi
		mov	ss:[params].EHES_argc, 1
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_STRING
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, ax
		lea	dx, ss:[params]
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock
done:
		.leave
		Destroy	ax, cx, dx
		ret
error:
	;
	; Some error, ax contains which one.
		les	di, ss:[bx].EDAA_retval
		Assert	fptr, esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
		
SystemLauncherActionHide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SLNOTIFYLAUNCHERSOFALARM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SLNotifyLaunchersOfAlarm

CALLED BY:	GLOBAL

C DECLARATION:	extern void _far _pascal
		    SLNotifyLaunchersOfAlarm(Message m);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
	SetGeosConvention
SLNOTIFYLAUNCHERSOFALARM	proc	far \
	message: word

	uses	ds,es,si,di		; cs
	.enter
		mov	di, offset theLauncherArray
		mov	ax, ss:[message]
		call	GadgetUtilNotifyCompsOfChange
	.leave
	ret
SLNOTIFYLAUNCHERSOFALARM	endp
	SetDefaultConvention
endif
