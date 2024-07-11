COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Service Components (Timer component)
FILE:		srvtimer.asm

AUTHOR:		dubois, Sep  7, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/ 7/95   	Initial revision


DESCRIPTION:
	Defines Timer service component
		

	$Id: srvtimer.asm,v 1.1 98/03/11 04:30:00 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
ServiceTimerClass
idata	ends


GadgetTimerCode		segment resource
;; Name of event raised in ST_TICK
;;
timerRingEventString	TCHAR	"ring", C_NULL

;; Property and Action tables
;;

makePropEntry timer, interval, LT_TYPE_INTEGER,			\
	PDT_SEND_MESSAGE, <PD_message	MSG_ST_GET_INTERVAL>,	\
	PDT_SEND_MESSAGE, <PD_message	MSG_ST_SET_INTERVAL>

makePropEntry timer, enabled, LT_TYPE_INTEGER,			\
	PDT_SEND_MESSAGE, <PD_message	MSG_ST_GET_ENABLED>,	\
	PDT_SEND_MESSAGE, <PD_message	MSG_ST_SET_ENABLED>

compMkPropTable _nuke, timer, \
	interval, enabled

compMkActTable timer

MakeSystemPropRoutines ServiceTimer, timer
;;
;; Currently no actions
;;

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;% Standard methods for using and resolving non-byte-compiled actions
;% and properties, returning class name.  These are all cookie-cutter
;% routines.
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

COMMENT @
DESCRIPTION:	

@

STEntDoAction	method dynamic ServiceTimerClass, MSG_ENT_DO_ACTION
		segmov	es, cs
		mov	bx, offset timerActionTable
		mov	di, offset ServiceTimerClass
		mov	ax, segment dgroup
		call	EntUtilDoAction
		ret
STEntDoAction	endm

STEntResolveAction method dynamic ServiceTimerClass, MSG_ENT_RESOLVE_ACTION
		segmov	es, cs
		mov	bx, offset timerActionTable
		mov	di, offset ServiceTimerClass
		mov	ax, segment dgroup
		call	EntResolveActionCommon
		ret
STEntResolveAction endm


STEntGetClass method dynamic ServiceTimerClass, MSG_ENT_GET_CLASS
	; ServiceTimerString defined with makeECPS
		mov	cx, segment ServiceTimerString
		mov	dx, offset ServiceTimerString
		ret
STEntGetClass endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STMetaResolveVariantSuperclass
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
STMetaResolveVariantSuperclass	method dynamic ServiceTimerClass, 
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
STMetaResolveVariantSuperclass	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear some flags that ent sets

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= ServiceTimerClass object
		ds:di	= ServiceTimerClass instance data
		ds:bx	= ServiceTimerClass object (same as *ds:si)
		es 	= segment of ServiceTimerClass
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
STMetaInitialize	method dynamic ServiceTimerClass, 
					MSG_META_INITIALIZE
	uses	ax, cx, dx, bp
	.enter
		mov	di, offset ServiceTimerClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		BitClr	ds:[di].EI_state, ES_IS_GEN
		BitClr	ds:[di].EI_state, ES_IS_VIS

		clr	ax
		mov	ds:[di].STI_timerHandle, ax
		mov	ds:[di].STI_interval, 60
		mov	ds:[di].STI_enabled, 0
	.leave
	ret
STMetaInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up timer when component gets destroyed

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= ServiceTimerClass object
		ds:di	= ServiceTimerClass instance data
		ds:bx	= ServiceTimerClass object (same as *ds:si)
		es 	= segment of ServiceTimerClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STMetaDetach	method dynamic ServiceTimerClass, MSG_ENT_DESTROY
	uses	ax
	.enter
		mov	bx, ds:[di].STI_timerHandle
		tst	bx
		jz	done
		clr	ax		; continual timer
		call	TimerStop
done:
	.leave
		mov	di, offset ServiceTimerClass
		call	ObjCallSuperNoLock
	ret
STMetaDetach	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Arrange our properties the way we wants 'em

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= ServiceTimerClass object
		ds:di	= ServiceTimerClass instance data
		ds:bx	= ServiceTimerClass object (same as *ds:si)
		es 	= segment of ServiceTimerClass
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
STEntInitialize	method dynamic ServiceTimerClass, 
					MSG_ENT_INITIALIZE
	uses	ax, cx, dx, bp
	.enter
		mov	di, offset ServiceTimerClass
		call	ObjCallSuperNoLock
	.leave
	ret
STEntInitialize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STTick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise the "ring" event

CALLED BY:	MSG_ST_TICK
PASS:		ds,si,di,bx,es,ax - standard method stuff
		cx:dx	- Tick count
		bp	- Timer ID
RETURN:		nothing
DESTROYED:	can destroy everything
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STTick	method dynamic ServiceTimerClass, 
					MSG_ST_TICK
	uses	ax, cx, dx, bp
	.enter

	; User could have disabled us while the TICK was in the queue...
	;
		tst	ds:[di].STI_enabled
		jz	done

		mov	dx, cs
		mov	ax, offset timerRingEventString
		call	ServiceRaiseEvent
done:
	.leave
	ret
STTick	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the "enabled" property

CALLED BY:	MSG_ST_SET_ENABLED
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
STSetEnabled	method dynamic ServiceTimerClass, 
					MSG_ST_SET_ENABLED
	uses	bp
	.enter
		les	bx, ss:[bp].SPA_compDataPtr
		cmp	es:[bx].CD_type, LT_TYPE_INTEGER
		mov	ax, CPE_PROPERTY_TYPE_MISMATCH
		jne	errorDone

		tst	es:[bx].CD_data.LD_integer
		jz	disableMe

enableMe::
		tst	ds:[di].STI_enabled
		jnz	afterTimer
		call	ST_EnableTimer
		jmp	afterTimer

disableMe:
		tst	ds:[di].STI_enabled
		jz	afterTimer
		call	ST_DisableTimer

	; All the timer set/stop work is done now, so
	; set the enabled prop
	;
afterTimer:
		les	bx, ss:[bp].SPA_compDataPtr
		mov	ax, 1
		tst	es:[bx].CD_data.LD_integer
		jnz	setIt
		clr	ax
setIt:
		mov	ds:[di].STI_enabled, ax

done:
	.leave
	Destroy	ax, cx, dx
	ret
errorDone:
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, ax
		jmp	done
STSetEnabled	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STGetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the "enabled" property

CALLED BY:	MSG_ST_GET_ENABLED, MSG_ST_GET_INTERVAL
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
STGetEnabled	method dynamic ServiceTimerClass, 
					MSG_ST_GET_ENABLED,
					MSG_ST_GET_INTERVAL		
	uses	bp
	.enter
		mov_tr	bx, ax

		mov	ax, ds:[di].STI_enabled	; assume success
		cmp	bx, MSG_ST_GET_ENABLED
		je	getIt
		Assert	e bx, MSG_ST_GET_INTERVAL
		mov	ax, ds:[di].STI_interval
getIt:
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
	.leave
	Destroy	ax, cx, dx
	ret
STGetEnabled	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STSetInterval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the "interval" property

CALLED BY:	MSG_ST_SET_INTERVAL
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STSetInterval	method dynamic ServiceTimerClass, 
					MSG_ST_SET_INTERVAL
	uses	bp
	.enter
		les	bx, ss:[bp].SPA_compDataPtr
		cmp	es:[bx].CD_type, LT_TYPE_INTEGER
		mov	ax, CPE_PROPERTY_TYPE_MISMATCH
		jne	errorDone

		mov	cx, es:[bx].CD_data.LD_integer
		cmp	cx, 0
		jg	setIt
		mov	cx, 1		; clip to range, not error
setIt:
		mov	ds:[di].STI_interval, cx

	; If we're not enabled, don't have to worry about stopping
	; and starting the timer
	;
		tst	ds:[di].STI_enabled
		jz	done
		call	ST_DisableTimer
		call	ST_EnableTimer
done:
	.leave
	Destroy	ax, cx, dx
	ret
errorDone:
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, ax
		jmp	done
STSetInterval	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ST_EnableTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a continual timer

CALLED BY:	INTERNAL, STSetEnabled, STSetInterval
PASS:		*ds:si	- ServiceTimer object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Enables a continual timer, with interval that is stored
	in instance data.  Assumes no timer is currently running.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.warn -private
ST_EnableTimer	proc	near
	uses	ax,bx,cx,dx, di
	.enter
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset

		Assert	e, ds:[di].STI_timerHandle, 0

		mov	cx, ds:[di].STI_interval
		Assert	ne cx, 0
		mov	di, cx
		mov	al, TIMER_EVENT_CONTINUAL
		mov	bx, ds:[LMBH_handle]
		mov	dx, MSG_ST_TICK
		call	TimerStart

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		mov	ds:[di].STI_timerHandle, bx
	.leave
	ret
ST_EnableTimer	endp
.warn @private

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ST_DisableTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable timer

CALLED BY:	INTERNAL, STSetEnabled, STSetinterval
PASS:		*ds:si	- ServiceTimer object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Disables continual timer.  Assumes one is already running.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.warn -private
ST_DisableTimer	proc	near
	uses	ax, bx, di
	.enter
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset

		Assert	ne, ds:[di].STI_timerHandle, 0

		mov	bx, ds:[di].STI_timerHandle
		clr	ax
		mov	ds:[di].STI_timerHandle, ax
		call	TimerStop
	.leave
	ret
ST_DisableTimer	endp
.warn @private



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STEntPause, Resume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pause a timer/resume a timer

CALLED BY:	MSG_ENT_PAUSE, MSG_ENT_RESUME
PASS:		*ds:si	= ServiceTimerClass object
		ds:di	= ServiceTimerClass instance data
		ds:bx	= ServiceTimerClass object (same as *ds:si)
		es 	= segment of ServiceTimerClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STEntPause	method dynamic ServiceTimerClass, MSG_ENT_PAUSE
		.enter
		call	ST_DisableTimer
		mov	di, offset ServiceTimerClass
		call	ObjCallSuperNoLock
		.leave
		ret
STEntPause	endm

STEntResume	method dynamic ServiceTimerClass, MSG_ENT_RESUME
		.enter
		call	ST_EnableTimer
		mov	di, offset ServiceTimerClass
		call	ObjCallSuperNoLock
		.leave
		ret
STEntResume	endm

GadgetTimerCode		ends
