COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Service Components (TimeDate component)
FILE:		srvdate.asm

AUTHOR:		Paul L. Du Bois, Aug  8, 1995

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_ENT_DO_ACTION	

    MTD MSG_ENT_RESOLVE_ACTION	

    MTD MSG_ENT_SET_PROPERTY	

    MTD MSG_ENT_GET_PROPERTY	

    MTD MSG_ENT_RESOLVE_PROPERTY
				

    MTD MSG_ENT_GET_CLASS	

    MTD MSG_META_RESOLVE_VARIANT_SUPERCLASS
				Inform system that we are Meta but not Gen
				or Vis

    MTD MSG_META_INITIALIZE	Clear some flags that ent sets

    MTD MSG_META_DETACH		Clean up timer when component gets
				destroyed

    MTD MSG_ENT_INITIALIZE	Arrange our properties the way we wants 'em

    MTD MSG_STD_GET_DATE	Get the system date or time into a struct

    MTD MSG_STD_GET_TIMEINTEREST
				Get timeInterest property

    MTD MSG_STD_SET_DATE	Set the system date or time from a struct

    MTD MSG_STD_SET_TIMEINTEREST
				Set timeInterest property

    MTD MSG_STD_ACTION_GETDAYOFWEEK
				Return day of week for given date.
				1-Sunday, 7-Saturday

    MTD MSG_STD_ACTION_GETDAYSINMONTH
				Get number of days in a month

    MTD MSG_STD_TIMER_TICK	Possibly raise dateChanged or timeChanged
				events

    EXT ServiceAlloc3IntStruct	Allocate a Date structure (refcount 0) on
				runtime heap

    INT STD_CheckActionTypes_INT
				Check that all types in EDAA_argv are
				LT_TYPE_INTEGER

    INT STD_CalcDayOfWeek	Calculate day of week of for given
				(month,year)

    INT STD_IsLeapYear		Determines if the given year is a leap year

    INT ServiceRaiseEvent	Raise an event with no args

    INT STD_UpdateCountdown	Update minutes-until-XXX instance data

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/ 8/95   	Initial revision


DESCRIPTION:
	Defines TimeDate service component.

	$Id: srvdate.asm,v 1.1 98/03/11 04:30:40 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment
	ServiceTimeDateClass
idata	ends

;; FIXME: maybe move these somewhere useful?

; Days in each month (excluding leap years)
;
monthLengths 	label	byte
	byte	0	; zero padding
	byte	31	; January
	byte	28	; February
	byte	31	; March
	byte	30	; April
	byte	31	; May
	byte 	30	; June
	byte	31	; July
	byte	31	; August
	byte	30	; September
	byte	31	; October
	byte 	30	; November
	byte	31	; December

; Values of day of week:
;  SUN = 0, MON = 1; etc...
;
; Offset arrays to calculate day of week of 1st day of each month
;
monthOffsets	label	byte
	byte	0	; zero padding
	byte	0	; Jan (by definition)
	byte	3	; Feb
	byte	3	; Mar
	byte	6	; Apr
	byte	1	; May
	byte	4	; Jun
	byte	6	; Jul
	byte	2	; Aug
	byte	5	; Sep
	byte	0	; Oct
	byte	3	; Nov
	byte 	5	; Dec

;; Smallest year accessible
LOW_YEAR	equ	1900
;; Day of week of Jan 1, 1900
BASE_DAY	equ	1

timeChangedString	TCHAR	"timeChanged", C_NULL
dateChangedString	TCHAR	"dateChanged", C_NULL


;; Create property table
;;

makePropEntry timedate, timeInterest, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_STD_GET_TIMEINTEREST>, \
	PDT_SEND_MESSAGE, <PD_message MSG_STD_SET_TIMEINTEREST>

makePropEntry timedate, systemClock, LT_TYPE_LONG, \
	PDT_SEND_MESSAGE, <PD_message MSG_STD_GET_SYSTEMCLOCK>, \
	PDT_SEND_MESSAGE, <PD_message MSG_STD_SET_SYSTEMCLOCK>

compMkPropTable _nuke, timedate, timeInterest, systemClock

;; Create action table
;;
makeActionEntry timedate, GetDayOfWeek \
	MSG_STD_ACTION_GETDAYOFWEEK, LT_TYPE_INTEGER, 3

makeActionEntry timedate, GetDaysInMonth \
	MSG_STD_ACTION_GETDAYSINMONTH, LT_TYPE_INTEGER, 2

makeExtendedActionEntry timedate, GetTime \
	MSG_STD_ACTION_GETTIME, LT_TYPE_STRUCT, TimeOfDay, 0
makeExtendedActionEntry timedate, SetTime \
	MSG_STD_ACTION_SETTIME, LT_TYPE_VOID, TimeOfDay, 1
	
makeExtendedActionEntry timedate, GetDate \
	MSG_STD_ACTION_GETDATE, LT_TYPE_STRUCT, Date, 0
makeExtendedActionEntry timedate, SetDate \
	MSG_STD_ACTION_SETDATE, LT_TYPE_VOID, Date, 1

makeExtendedActionEntry timedate, FormatDate \
	MSG_STD_ACTION_FORMATDATE, LT_TYPE_STRING, Date, 2

makeExtendedActionEntry timedate, ParseDate \
	MSG_STD_ACTION_PARSEDATE, LT_TYPE_STRUCT, Date, 1

makeExtendedActionEntry timedate, FormatTime \
	MSG_STD_ACTION_FORMATTIME, LT_TYPE_STRING, TimeOfDay, 2

makeExtendedActionEntry timedate, ParseTime \
	MSG_STD_ACTION_PARSETIME, LT_TYPE_STRUCT, TimeOfDay, 1
	
	
compMkActTable timedate, GetDayOfWeek, GetDaysInMonth, \
	GetTime, SetTime, GetDate, SetDate, FormatDate, ParseDate, \
	FormatTime, ParseTime

MakeSystemPropRoutines ServiceTimeDate, timedate


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;% Standard methods for using and resolving non-byte-compiled actions
;% and properties, returning class name.  These are all cookie-cutter
;% routines.
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

COMMENT @
DESCRIPTION:	

@

STDEntDoAction	method dynamic ServiceTimeDateClass, MSG_ENT_DO_ACTION
		segmov	es, cs
		mov	bx, offset timedateActionTable
		mov	di, offset ServiceTimeDateClass
		mov	ax, segment dgroup
		call	EntUtilDoAction
		ret
STDEntDoAction	endm

STDEntResolveAction method dynamic ServiceTimeDateClass, MSG_ENT_RESOLVE_ACTION
		segmov	es, cs
		mov	bx, offset timedateActionTable
		mov	di, offset ServiceTimeDateClass
		mov	ax, segment dgroup
		call	EntResolveActionCommon
		ret
STDEntResolveAction endm

STDEntGetClass method dynamic ServiceTimeDateClass, MSG_ENT_GET_CLASS
	; ServiceTimeDateString defined with makeECPS
		mov	cx, segment ServiceTimeDateString
		mov	dx, offset ServiceTimeDateString
		ret
STDEntGetClass endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform system that we are Meta but not Gen or Vis

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		cx	- Master class offset
RETURN:		cxdx	- ClassPtr of superclass
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Return ML2Class, a null-ish class at the 2nd master level

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDMetaResolveVariantSuperclass	method dynamic ServiceTimeDateClass, 
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
STDMetaResolveVariantSuperclass	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear some flags that ent sets

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
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
STDMetaInitialize	method dynamic ServiceTimeDateClass, 
					MSG_META_INITIALIZE
	uses	ax, cx, dx, bp
	.enter
		mov	di, offset ServiceTimeDateClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		BitClr	ds:[di].EI_state, ES_IS_GEN
		BitClr	ds:[di].EI_state, ES_IS_VIS
		clr	ds:[di].STDI_timerHandle

	.leave
	ret
STDMetaInitialize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up timer when component gets destroyed

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDEntDestroy	method dynamic ServiceTimeDateClass, \
					MSG_ENT_DESTROY
	uses	ax, cx, dx
	.enter
	;
	; Stop our timer.
	;
		clr	ax		; id is zero for continual timers
		mov	bx, ds:[di].STDI_timerHandle
		call	TimerStop
	;
	; Get off the GCNSLT_DATE_TIME list.
	;
		mov	ax, MSG_STD_REMOVE_FROM_DATE_TIME_LIST
		call	ObjCallInstanceNoLock

	.leave
		mov	di, offset ServiceTimeDateClass
		call	ObjCallSuperNoLock
	ret
STDEntDestroy	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDRemoveFromDateTimeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove ourself from the GCNSLT_DATE_TIME list.

		This message provided so that BServive can intercept
		it and do nothing.

CALLED BY:	MSG_STD_REMOVE_FROM_DATE_TIME_LIST
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDRemoveFromDateTimeList	method dynamic ServiceTimeDateClass, 
					MSG_STD_REMOVE_FROM_DATE_TIME_LIST
		.enter
	;
	; Remove self from GCNSLT_DATE_TIME.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_DATE_TIME
		call	GCNListRemove
		
		.leave
		Destroy	ax, cx, dx
		ret
STDRemoveFromDateTimeList	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Arrange our properties the way we wants 'em

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Initialize minutes-to-midnight and minutes-to-next-ding.
	Start up a timer which ticks every minute.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDEntInitialize	method dynamic ServiceTimeDateClass, 
					MSG_ENT_INITIALIZE
	uses	ax, cx, dx, bp
	.enter

		mov	ds:[di].STDI_timeInterest, 0
		call	STD_UpdateCountdown
	;
	; Set up a once-a-minute timer
	;
		mov	ax, MSG_STD_CREATE_NEW_TIMER
		call	ObjCallInstanceNoLock
	;
	; Let superclass do its thing.
	;
		mov	ax, MSG_ENT_INITIALIZE
		mov	di, offset ServiceTimeDateClass
		call	ObjCallSuperNoLock
	;
	; Add ourself to GCNSLT_DATE_TIME so that we'll be notified
	; whenever anyone changes the date/time.  (See TimerSetDateTime,
	; which is called STDActionSetdate.)
	;
		mov	ax, MSG_STD_ADD_TO_DATE_TIME_LIST
		call	ObjCallInstanceNoLock
		
	.leave
	ret
STDEntInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDCreateNewTimerMethod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new timer, and destroy any old timer.
		This method is only called by ENT_INITIALIZE.  It's
		provided so that BServiceTimeDateClass can intercept
		it and do nothing (b/c BService doesn't want a timer).

CALLED BY:	MSG_STD_CREATE_NEW_TIMER
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/24/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDCreateNewTimerMethod	method dynamic ServiceTimeDateClass, 
					MSG_STD_CREATE_NEW_TIMER
		.enter

		call	STDCreateNewTimer
		
		.leave
		ret
STDCreateNewTimerMethod	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDCreateNewTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new timer, and destroy any old timer.

CALLED BY:	
PASS:		*ds:si	- ServiceTimeDateClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDCreateNewTimer	proc	near
		class	ServiceTimeDateClass
		.enter
	;
	; Deref self.
	;
		CheckHack < ServiceTimeDate_offset eq Ent_offset >
		mov	di, ds:[si]
		add	di, ds:[di].ServiceTimeDate_offset
	;
	; Destroy our old timer if we've got one.
	;
		mov	bx, ds:[di].STDI_timerHandle
		tst	bx
		jz	createNewTimer
		clr	ax		; id is zero for continual timers
		call	TimerStop
	;
	; Create new timer.
	;
createNewTimer:
		push	di
		call	TimerGetDateAndTime	; dh <- seconds
		mov	cl, 60
		sub	cl, dh		; cl <- seconds to next minute
		mov	ax, 60
		mul	cl		
		mov_tr	cx, ax		; cx <- ticks to next minute

		mov	al, TIMER_EVENT_CONTINUAL
		mov	dx, MSG_STD_TIMER_TICK
		mov	di, 3600	; 3600 ticks per minute

		mov	bx, ds:[LMBH_handle]
		call	TimerStart	; bx <- timer handle

		pop	di
		mov	ds:[di].STDI_timerHandle, bx

		.leave
		ret
STDCreateNewTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDAddToDateTimeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add self to GCNSLT_DATE_TIME so that we can generate
		dateChanged messages.

		This message provided so that BService can intercept
		and do nothing.

CALLED BY:	MSG_STD_ADD_TO_DATE_TIME_LIST
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDAddToDateTimeList	method dynamic ServiceTimeDateClass, 
					MSG_STD_ADD_TO_DATE_TIME_LIST
		.enter
	;
	; Add ourself to the list.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si				; cx:dx = oself
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_DATE_TIME
		call	GCNListAdd

		.leave
		Destroy	ax, cx, dx
		ret
STDAddToDateTimeList	endm



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%		property GET and SET methods
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDActionGetdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the system date or time into a struct

CALLED BY:	MSG_STD_ACTION_GETDATE, MSG_STD_ACTION_GETTIME

PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDActionGetdate	method dynamic ServiceTimeDateClass, 
					MSG_STD_ACTION_GETDATE,
					MSG_STD_ACTION_GETTIME
	.enter
		les	di, ss:[bp].EDAA_runHeapInfoPtr
		call	ServiceAlloc3IntStruct
		mov	si, bx		; si <- token

		cmp	ax, MSG_STD_ACTION_GETDATE
		pushf
		call	TimerGetDateAndTime
		popf
		je	storeDate

	; Store result of TimerGetDateAndTime in struct.
	; ax - year, bl - month, bh - day, cl - day of week
	; ch - hours, dl - mins, dh - secs
	;		
CheckHack <size LegosStructField eq 5>
storeTime::
		clr	ax
		mov	al, ch
		mov	es:[di][0].LSF_value.low, ax
		mov	al, dl
		mov	es:[di][5].LSF_value.low, ax
		mov	al, dh
		mov	es:[di][10].LSF_value.low, ax
		jmp	unlock
storeDate:
		mov	es:[di][0].LSF_value.low, ax
		clr	ah
		mov	al, bl
		mov	es:[di][5].LSF_value.low, ax
		mov	al, bh
		mov	es:[di][10].LSF_value.low, ax

unlock:
	; Unlock and return token
	;
		push	si
		pushdw	ss:[bp].EDAA_runHeapInfoPtr
		call	RunHeapUnlock
		add	sp, 6

		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_STRUCT
		mov	es:[di].CD_data.LD_struct, si
	.leave
	Destroy	ax, cx, dx
	ret
STDActionGetdate	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDGetTimeinterest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get timeInterest property

CALLED BY:	MSG_STD_GET_TIMEINTEREST
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDGetTimeinterest	method dynamic ServiceTimeDateClass, 
					MSG_STD_GET_TIMEINTEREST
	.enter
		mov	ax, ds:[di].STDI_timeInterest
		lds	si, ss:[bp].GPA_compDataPtr
		mov	ds:[si].CD_type, LT_TYPE_INTEGER
		mov	ds:[si].CD_data.LD_integer, ax
	.leave
	Destroy	ax, cx, dx
	ret
STDGetTimeinterest	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDActionSetdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the system date or time from a struct

CALLED BY:	MSG_STD_SET_DATE, MSG_STD_SET_TIME
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		*EDAA_retval.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:
	System date or time is set

PSEUDO CODE/STRATEGY:
	Assume if we get a TYPE_STRUCT, it's the right kind of struct.
	Rely on runtime/compiler to ensure this.

BUGS:
	Not really a bug, but updates countdown instance data both
	on set date and set time, instead of just on set time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDActionSetdate	method dynamic ServiceTimeDateClass, 
					MSG_STD_ACTION_SETDATE,
					MSG_STD_ACTION_SETTIME
	uses	bp
	.enter
		les	di, ss:[bp].EDAA_argv
		cmp	es:[di].CD_type, LT_TYPE_STRUCT
		mov	cx, CAE_WRONG_TYPE
		jne	errorDone

		push	ds, si		; save object
		mov	si, ax		; save message
		sub	sp, size RunHeapLockStruct
		mov	bx, sp

		movdw	ss:[bx].RHLS_rhi, ss:[bp].EDAA_runHeapInfoPtr, ax
		mov	ax, es:[di].CD_data.LD_struct
		mov	ss:[bx].RHLS_token, ax
		lea	ax, ss:[bx].RHLS_eptr
		movdw	ss:[bx].RHLS_dataPtr, ssax
		mov	di, bx		; bx will be trashed
		call	RunHeapLock
		les	di, ss:[di].RHLS_eptr
		
		cmp	si, MSG_STD_ACTION_SETDATE
		je	setDate
setTime::
		call	STDValidateTimeArgs
		jc	dataError
		mov	cl, mask SDTP_SET_TIME
		jmp	doSet
setDate:
	; Set bl/bh/ax assuming es:di is a struct Date
	;
		call	STDValidateDateArgs
		jc	dataError
		mov	cl, mask SDTP_SET_DATE

doSet:
		call	TimerSetDateAndTime		; This will cause
							; all TimeDates to
							; get dateChanged().
		call	RunHeapUnlock
		add	sp, size RunHeapLockStruct

		pop	ds, si		; restore object
		call	STD_UpdateCountdown
		call	STDCreateNewTimer

done:
	.leave
	Destroy	ax, cx, dx
	ret

errorDone:
	; expects error in cx
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, cx
		jmp	done

dataError:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, \
			CPE_SPECIFIC_PROPERTY_ERROR
		call	RunHeapUnlock
	; pop off object as well as RHLS
		add	sp, size RunHeapLockStruct+4
		jmp	done

STDActionSetdate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDValidateDateArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed Date structure has a
		valid date.

CALLED BY:	STDActionSetDate, STDActionFormatDate
PASS:		es:di	- Date struct
RETURN:		carry	- set if error
			  clear if valid data in TimeOfDay
				ax - year (1980-2099)
				bl - month
				bh - day
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDValidateDateArgs	proc	near
		uses	dx
		.enter
CheckHack <size LegosStructField eq 5>
	;
	; Check month.  Put in bl.
	;
		mov	bx, es:[di][5].LSF_value.low	; months
		cmp	bx, 1
		jb	error
		cmp	bx, 12
		ja	error
	;
	; Check year.  Put in ax.
	;
		mov	ax, es:[di][0].LSF_value.low	; years
		cmp	ax, 1980
		jb	error
		cmp	ax, 2099
		ja	error
	;
	; Check day.  Put in dx
	;
		mov	dx, es:[di][10].LSF_value.low	; day
		cmp	dx, 1
		jb	error
		clr	cx
		call	LocalCalcDaysInMonth		; ch <- max
		xchg	cl, ch
		cmp	dx, cx
		ja	error
	;
	; bl/bh/ax <- mm/dd/yyyy
	;
		mov	bh, dl
		clc

done:		
		.leave
		ret
error:
		stc
		jmp	done
STDValidateDateArgs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDNotifyDateTimeChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise a dateChanged event.

CALLED BY:	MSG_NOTIFY_DATE_TIME_CHANGE
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
		ax	= message #
		cl	- SetDateTimeParams
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDNotifyDateTimeChange	method dynamic ServiceTimeDateClass, 
					MSG_NOTIFY_DATE_TIME_CHANGE
		.enter

	; Raise the event.
	;
		test	cl, mask SDTP_SET_DATE
		jz	afterRaise

		mov	dx, cs
		mov	ax, offset dateChangedString
		call	ServiceRaiseEvent
afterRaise:
		test	cl, mask SDTP_SET_TIME
		jz	done

		mov	dx, cs
		mov	ax, offset timeChangedString
		call	ServiceRaiseEvent
		
done:
		.leave
		Destroy	ax, cx, dx, bp
		ret
STDNotifyDateTimeChange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDSetTimeinterest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set timeInterest property

CALLED BY:	MSG_STD_SET_TIMEINTEREST
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDSetTimeinterest	method dynamic ServiceTimeDateClass, 
					MSG_STD_SET_TIMEINTEREST
	uses	bp
	.enter
		les	bx, ss:[bp].SPA_compDataPtr
		cmp	es:[bx].CD_type, LT_TYPE_INTEGER
		mov	ax, es:[bx].CD_data.LD_integer
		je	gotInt

		cmp	es:[bx].CD_type, LT_TYPE_LONG
		jne	typeErrorDone

gotLong::
	; negative?
	;
		mov	dx, es:[bx].CD_data.LD_long.high	;dxax <- long
		test	dx, 0x8000
		jnz	setZero

	; greater than 0x7fff?
	;
		tst	dx
		jnz	setSixty
		test	ax, 0x8000
		jnz	setSixty

	; within normal int range... just fall through
	;
gotInt:
		cmp	ax, 60
		jg	setSixty
		cmp	ax, 0
		jl	setZero
setIt:
		mov	ds:[di].STDI_timeInterest, ax
		call	STD_UpdateCountdown
done:
	.leave
	Destroy	ax, cx, dx
	ret
setZero:
		clr	ax
		jmp	setIt
setSixty:
		mov	ax, 60
		jmp	setIt

typeErrorDone:
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, \
			CPE_PROPERTY_TYPE_MISMATCH
		jmp	done
STDSetTimeinterest	endm

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%		ACTION methods
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDActionGetdayofweek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return day of week for given date.  1-Sunday, 7-Saturday

CALLED BY:	MSG_STD_ACTION_GETDAYOFWEEK
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ACTION GetDayOfWeek(year as int, month as int, day as int) AS integer

	SPEC: Year must be > 1900

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDActionGetdayofweek	method dynamic ServiceTimeDateClass, 
					MSG_STD_ACTION_GETDAYOFWEEK
	uses	bp
	.enter
		call	STD_CheckActionTypes_INT
		jc	done
		
		les	di, ss:[bp].EDAA_argv

		mov	ax, es:[di].CD_data.LD_integer
		cmp	ax, 1900		; follow spec
		jng	specError
		mov	bx, es:[di][size ComponentData].CD_data.LD_integer
		mov	dx, es:[di][(size ComponentData)*2].CD_data.LD_integer
		call	STD_CalcDayOfWeek	; cl <- day of week
		jc	error

		clr	ch	
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
done:
	.leave
	Destroy	ax, cx, dx
	ret

specError:
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
	; Set error. ax - error to set
	;
error:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
STDActionGetdayofweek	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDActionGetdaysinmonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get number of days in a month

CALLED BY:	MSG_STD_ACTION_GETDAYSINMONTH
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ACTION GetDaysInMonth(year as int, month as int) AS integer

	Spec: year must be > 1900

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDActionGetdaysinmonth	method dynamic ServiceTimeDateClass, 
					MSG_STD_ACTION_GETDAYSINMONTH
	uses	bp
	.enter
		call	STD_CheckActionTypes_INT
		jc	done

		les	di, ss:[bp].EDAA_argv
		
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		mov	si, es:[di].CD_data.LD_integer
		cmp	si, LOW_YEAR
		jl	errorDone
		cmp	si, 1900
		jng	errorDone

		mov	bx, es:[di][size ComponentData].CD_data.LD_integer
		cmp	bx, 1
		jb	errorDone
		cmp	bx, 12
		ja	errorDone

		mov	cl, {byte}cs:[monthLengths][bx]
		clr	ch		; cx <- length of month

	; Now look for a leap year
	;
		cmp	bx, 2		; is the month February
		jne	returnIt	; no - we're done
		call	STD_IsLeapYear	; is it a leap year ?
		jnc	returnIt
		inc	cx		; add a day

returnIt:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
done:
	.leave
	Destroy	ax, cx, dx
	ret
errorDone:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
STDActionGetdaysinmonth	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ServiceValidDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return true if date passed is valid

CALLED BY:	EXTERNAL
PASS:		cx	- year (must be gt 1900)
		bx	- month
		ax	- day
RETURN:		carry	- set if valid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	2/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ServiceValidDate	proc	far
	uses	ax,bx,si
	.enter
	; check year
		mov	si, cx		; si - year
		cmp	si, 1900
		jng	noGood

	; check month
		cmp	bx, 1
		jl	noGood
		cmp	bx, 12
		jg	noGood

	; check day
		cmp	ax, 1
		jl	noGood

		Assert	e, bh, 0
		cmp	bl, 2
		mov	bl, {byte}cs:[monthLengths][bx]
		jne	noLeapAdd
		call	STD_IsLeapYear
		adc	bl,0

noLeapAdd:
		cmp	ax, bx
		jg	noGood
		stc
done:
		mov	cx, si		; restore cx
	.leave
	ret
noGood:
		clc
		jmp	done
ServiceValidDate	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDTimerTick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Possibly raise dateChanged or timeChanged events

CALLED BY:	MSG_STD_TIMER_TICK
PASS:		ds,si,di,bx,es,ax - standard method stuff
RETURN:		nothing
DESTROYED:	ax,bp,cx,dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If either of our countdowns _reaches_ zero, raise an event and
	reset it.  If a countdown is already zero, assume that it is
	currently inactive.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDTimerTick	method dynamic ServiceTimeDateClass, 
					MSG_STD_TIMER_TICK

checkDate::
	; This should never be inactive
	;
EC <		tst	ds:[di].STDI_dateDelta				>
EC <		ERROR_Z	-1						>
		dec	ds:[di].STDI_dateDelta
		jnz	checkTime
		
	; Hit zero -- raise date changed event and reset STDI_dateDelta.
	;
	; If timeInterest is non-zero, then set things up so a timeChanged
	; event will occur as well -- spec says ding every
	; (timeInterest * n) minutes after midnight, for integral n
	;
raiseDate::
		mov	ds:[di].STDI_dateDelta, (24 * 60)
		mov	dx, cs
		mov	ax, offset dateChangedString
		call	ServiceRaiseEvent
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset

;;	don't do this -- try and keep timeInterest zero if
;;	time events are disabled
;;		mov	ds:[di].STDI_timeDelta, 1
		tst	ds:[di].STDI_timeInterest
		jz	done
		jmp	raiseTime

checkTime:
		tst	ds:[di].STDI_timeInterest
		jz	done		; timeChanged events inactive
		dec	ds:[di].STDI_timeDelta
		jnz	done

	; Hit zero -- raise time changed event and reset STDI_timeDelta
	;
raiseTime:
		mov	dx, cs
		mov	ax, offset timeChangedString
		call	ServiceRaiseEvent
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset

		mov	ax, ds:[di].STDI_timeInterest
		mov	ds:[di].STDI_timeDelta, ax
done:
	ret
STDTimerTick	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ServiceAlloc3IntStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a Date structure (refcount 0) on runtime heap

CALLED BY:	EXTERNAL, STDGetDate
PASS:		es:di	- fptr.RunHeapInfo
RETURN:		es:di	- Locked Date structure
		bx	- RunHeapToken
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Also used to allocate a Time structure, as Date and Time are both
	just 3 integers.  Structure fields will _not_ be zero-initialized.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ServiceAlloc3IntStruct	proc	far
	uses	bp, ax, cx, dx
	.enter

	; Allocate the struct
	;
		sub	sp, size RunHeapAllocStruct
		mov	bp, sp

		movdw	ss:[bp].RHAS_rhi, esdi
		mov	ss:[bp].RHAS_type, RHT_STRUCT
		mov	ss:[bp].RHAS_size, 3 * (size LegosStructField)

		clr	ax
		mov	ss:[bp].RHAS_refCount, al
		movdw	ss:[bp].RHAS_data, axax

		call	RunHeapAlloc		; ax <- token, trash es
		popdw	esdi			; rhi is on the top of stack
		add	sp, size RunHeapAllocStruct-4

	; Lock token into esdi
	;
		sub	sp, size RunHeapLockStruct
		mov	bp, sp
		
		movdw	ss:[bp].RHLS_rhi, esdi
		mov	ss:[bp].RHLS_token, ax
		lea	bx, ss:[bp].RHLS_eptr
		movdw	ss:[bp].RHLS_dataPtr, ssbx

		call	RunHeapLock
		les	di, ss:[bp].RHLS_eptr	; es:di <- locked struct
		mov	bx, ss:[bp].RHLS_token	; bx <- token
		add	sp, size RunHeapLockStruct

	; Initialize type bytes.  es:di is an array of 3 LegosStructFields
	;
		mov	es:[di].LSF_type, LT_TYPE_INTEGER
		mov	es:[di].(size LegosStructField)+LSF_type, \
				LT_TYPE_INTEGER
		mov	es:[di].((size LegosStructField)*2)+LSF_type, \
				LT_TYPE_INTEGER
	.leave
	ret
ServiceAlloc3IntStruct	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STD_CheckActionTypes_INT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that all types in EDAA_argv are LT_TYPE_INTEGER

CALLED BY:	INTERNAL, action handlers
PASS:		ss:bp	- EntDoActionArgs
RETURN:		carry	- set on error (error filled in)

DESTROYED:	ax, cx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STD_CheckActionTypes_INT	proc	near
	uses	es,di
	.enter
		mov	cx, ss:[bp].EDAA_argc
		les	di, ss:[bp].EDAA_argv
		mov	ax, CAE_WRONG_TYPE
		jmp	$1

checkType:
		add	di, size ComponentData
$1:
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		loope	checkType

		jne	errorDone

		clc
done:
	.leave
	ret
errorDone:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		stc
		jmp	done
STD_CheckActionTypes_INT	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 		STD_CalcDayOfWeek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate day of week of for given (year,month,day)

CALLED BY:	INTERNAL

PASS:		ax 	= desired year
		bx 	= desired month (Jan = 1; Dec = 12)
		dx 	= desired day

RETURN: 	cl	= day of the week (0 = Sunday)
		carry	- set on error (ax = error)

DESTROYED:	ch, dx, si

PSEUDO CODE/STRATEGY:
	Calculate day "shifts" between base year and needed year
		
	DayofWeek = ((this year - base year) + leap years in that interval
			+ monthOffset[this month]) mod (daysinWeek = 7)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	 6/12/89	Initial version
	Don	 7/ 6/89	Fixed up leap year stuff
	dubois	 8/24/95	Stolen, renamed, tweaked

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STD_CalcDayOfWeek	proc	far
		uses	ax, bx
		.enter

		cmp	ax, LOW_YEAR
		jb	errorDone
		cmp	bx, 1
		jb	errorDone
		cmp	bx, 12
		ja	errorDone
		cmp	dx, 1
		jb	errorDone
		tst	dh
		jnz	errorDone
		call	LocalCalcDaysInMonth	; ch = # days
		cmp	dl, ch
		jna	noError
errorDone:
		stc
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done

	; Calculate difference between this year and base year
	;
noError:
		mov	cl, bl		; cl <- month
		mov	bx, ax		; bx <- year
		
		mov	dh, cl		; dh <- month, dl <- day
		mov	si, bx
		sub	bx, LOW_YEAR	; find difference
		jz	almostDone	; if 1900, skip this mess
		mov	cx, bx		; diff in CX
		mov	ax, bx		; diff in AX

	; Now account for leap years (running total in BX)
	;
		dec	cx		; ignore the current year
		shr	cx, 1		
		shr	cx, 1		; divide by 4
		add	bx, cx		; add in leap years

	; No leap years on century marks
	;
		dec	ax		; ignore the current year
		push	dx		; save the reg
		clr	dx		
		mov	cx, 100		; set up divide
		div	cx		; divide 
		sub	bx, ax		; update count
		pop	dx		; restore this register

	; Except on years evenly divisible by 400
	;
		add	al, 3		; ease the math
		shr	ax, 1		
		shr	ax, 1		; divide by 4
		add	bx, ax		; update the count

	; What if this year is a leap year ??
	;
		cmp	dh, 2		; compare month with Feb
		jle	almostDone	; leap year doesn't matter
		call	STD_IsLeapYear	; is this year a leap year ?
		jnc	almostDone	; carry clear - not a leap year
		inc	bx		; add one day for leap year

	; Add in the base day & month offset
	;
almostDone:
		add	bx, BASE_DAY	; add in base day
		mov	ax, bx		; total day offset to AX
		mov	bl, dh		
		clr	bh		
		mov	cl, {byte}cs:[monthOffsets][bx]; add month offset
		add	cl, dl		; account for day of month
		dec	cl		; 1st day is zero offset
		clr	ch		
		add	ax, cx		; update total day offset

	; Finally - one big divide
	;
		clr	dx		
		mov	cx, 7		; set up divide
		div	cx		; days mod 7
		mov	cl, dl		; cl <- day of week
		clc			; carry <- no error
done:
		.leave
		ret
STD_CalcDayOfWeek	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STD_IsLeapYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the given year is a leap year

CALLED BY:	INTERNAL

PASS:		si	= Year

RETURN:		Carry	= Set if a leap year
			= Clear if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/30/89	Initial version
	dubois	 8/24/95	Stolen, renamed, tweaked

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

STD_IsLeapYear	proc	far
	uses	ax, cx, dx
	.enter

	; Is the year divisible by 4
	;
		mov	ax, si
		and	ax, 3		; is a leap year?
		jnz	done		; carry is clear

	; Maybe a leap year - check for divisible by 100
	;
		mov	ax, si		; get the year again
		clr	dx		; clear the high byte
		mov	cx, 100		; set up divisor
		div	cx		; is it a century ??
		tst	dx		; check remainder
		jne	setCarry	; a leap year - carry clear

	; Still a leap year if divisible by 400 (at this point by 4)
	;
		and	ax, 3		; is evenly divisble by 4 ??
		jnz	done		; no
setCarry:
		stc			; set carry for leap year
done:
	.leave
	ret
STD_IsLeapYear	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ServiceRaiseEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise an event with no args

CALLED BY:	EXTERNAL, MSG_STD_SET_{DATE,TIME} MSG_STD_TIMER_TICK
PASS:		dx:ax	- event name
		*ds:si	- component raising event

RETURN:		ax	- set if handled
DESTROYED:	dx
SIDE EFFECTS:	
	May move block on heap, invalidating pointers to instance data.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ServiceRaiseEvent	proc	far
	uses	di, cx
	params	local	EntHandleEventStruct
	result	local	ComponentData
	.enter

		movdw	[params].EHES_eventID.EID_eventName, dxax
		lea	ax, [result]
		movdw	[params].EHES_result, ssax
		mov	[params].EHES_argc, 0

		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	di, mask MF_CALL or mask MF_REPLACE
		lea	dx, [params]
		mov	cx, ss		; cx:dx <- params
		call	ObjCallInstanceNoLock
	.leave
	ret
ServiceRaiseEvent	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STD_UpdateCountdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update minutes-until-XXX instance data

CALLED BY:	INTERNAL, MSG_ENT_INITIALIZE, MSG_STD_SET_{DATE,TIME}
PASS:		*ds:si	- object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.warn -private
STD_UpdateCountdown	proc	near
	uses	ax,bx,cx,dx, di
	.enter
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset

		call	TimerGetDateAndTime

setDateDelta::
	; Set # minutes until midnight
	; requires ch, dl (hh, mm)
	;
		mov	ax, 60
		mul	ch		; ax <- convert hours to minutes
		mov	bl, dl
		clr	bh		; bx <- minutes past hour
		add	bx, ax		; bx <- minutes past midnight
		mov	ax, (24 * 60)	; minutes/day
		sub	ax, bx		; ax <- minutes until midnight
		mov	ds:[di].STDI_dateDelta, ax

	; Set # minutes until next time ding.
	; We ding every <timeInterest> minutes past midnight
	; ax - timeInterest
	; bx - minutes past midnight
	;
	; minutes until next =
	;  timeInterest - (minutes since last ding)
	;
		mov	ds:[di].STDI_timeDelta, 0 ; assume no timeInterest
		mov	ax, ds:[di].STDI_timeInterest
		tst	ax
		jz	done

		xchg	bx, ax
		clr	dx		; dx:ax <- minutes past midnight
		div	bx		; dx <- # minutes since last "ding"
		sub	bx, dx		; bx <- # minutes until next "ding"
		mov	ds:[di].STDI_timeDelta, bx
done:
	.leave
	ret
STD_UpdateCountdown	endp
.warn @private


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDGetSystemclock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the system clock 

CALLED BY:	MSG_STD_GET_SYSTEMCLOCK
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDGetSystemClock	method dynamic ServiceTimeDateClass, 
					MSG_STD_GET_SYSTEMCLOCK
		.enter

		call	TimerGetCount
	;
	; value returned in bxax is in ticks (1/60th second).  Convert to
	; milliseconds (multiply by 1000/60, or 16.666666...).
	;
		movdw	dxcx, bxax
		
		shldw	bxax			; multiply by 16
		shldw	bxax
		shldw	bxax
		shldw	bxax
		pushdw	bxax
	;
	; Now to get the 2/3 we're looking for.  We can't use div because it
	; doesn't give a 32-bit integer result.  Instead, we'll chain two
	; calls to GrUDivWWFixed together.
	;
	; First, we divide high word by 3
	;
		push	cx			; save low word
		mov_tr	cx, dx
		clr	dx, bx			; clear high words
		mov	ax, 3
		call	GrUDivWWFixed		; divide by 3, dx:cx = WWFixed
						; result
	;
	; Save away result and divide low word by 3
	;
		pop	bx			; restore low word
		push	dx, cx
		mov	cx, bx
		clr	dx, bx			; clear high words
		call	GrUDivWWFixed
		mov	cx, dx			; move result into low word
		clr	dx			; toss the fraction
	;
	; restore earlier result, add the two together and add to the earlier
	; result.
	;
		pop	bx, ax
		adddw	dxcx, bxax
		shldw	dxcx			; finally, multiply by 2

		popdw	bxax			; 16*ticks
		adddw	dxcx, bxax		; + (2/3)*ticks
		
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_type, LT_TYPE_LONG
		movdw	es:[di].CD_data.LD_long, dxcx
				
		.leave
		ret
STDGetSystemClock	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDSetSystemclock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	error -- read only property

CALLED BY:	MSG_STD_SET_SYSTEMCLOCK
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDSetSystemClock	method dynamic ServiceTimeDateClass, 
					MSG_STD_SET_SYSTEMCLOCK
		.enter
		
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_READONLY_PROPERTY
		
		.leave
		ret
STDSetSystemClock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDFormatDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a date

CALLED BY:	MSG_STD_FORMATDATE
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
		ax	= message #

		ss:bp - EntDoActionArgs
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/ 9/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDFormatDate	method dynamic ServiceTimeDateClass, 
					MSG_STD_ACTION_FORMATDATE
		uses	bp, si
		.enter

	;
	; check the argument type
	;
		les	di, ss:[bp].EDAA_argv
		cmp	es:[di].CD_type, LT_TYPE_STRUCT
		mov	cx, CAE_WRONG_TYPE
		jne	errorDone
	;
	; Get the format (it is easier now than after we lock stuff on
	; the run heap)
	;
		mov	si, es:[di][(size ComponentData)].CD_data.LD_integer
		cmp	si, DTF_END_DATE_FORMATS
		jb	formatOK
		mov	si, DTF_SHORT
formatOK:
	;
	; Get the struct
	;
		mov	ax, es:[di].CD_data.LD_struct	;ax <- struct token
		mov	dx, ax
		call	RunHeapLock_asm
	;		
	; Set bl/bh/ax assuming es:di is a struct Date
	;
		call	STDValidateDateArgs
	;
	; unlock the run heap shme
	;
		pushf
		push	ax
		mov	ax, dx				;ax <- struct token
		call	RunHeapUnlock_asm
		pop	ax
		popf
		jc	errorDone			;branch if error
	;
	; Calculate the day of the week in case the format needs it
	;
		push	bx, si
		clr	dh
		mov	dl, bh				;dx <- day
		clr	bh				;bx <- month
		call	STD_CalcDayOfWeek
		pop	bx, si
		jc	errorDone
	;
	; format the beastie
	;
		sub	sp, DATE_TIME_BUFFER_SIZE*(size TCHAR)
		mov	di, sp
		segmov	es, ss				;es:di <- ptr to buf
		call	LocalFormatDateTime
	;
	; allocate and return a string
	;
		inc	cx			;cx <- length w/NULL
DBCS <		shl	cx, 1			;cx <- size >
		mov	bx, RHT_STRING
		mov	ax, es			;ax:di <- ptr to data
		clr	dx			;dx <- ref count
		call	RunHeapAlloc_asm

		add	sp, DATE_TIME_BUFFER_SIZE*(size TCHAR)
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax

done:
		.leave
		ret

errorDone:
		stc
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done
STDFormatDate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDFormatTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a time

CALLED BY:	MSG_STD_FORMATTIME
PASS:		*ds:si	= ServiceTimeDateClass object
		ds:di	= ServiceTimeDateClass instance data
		ds:bx	= ServiceTimeDateClass object (same as *ds:si)
		es 	= segment of ServiceTimeDateClass
		ax	= message #

		ss:bp - EntDoActionArgs
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/17/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDFormatTime	method dynamic ServiceTimeDateClass, 
					MSG_STD_ACTION_FORMATTIME
		uses	bp, si
		.enter

	;
	; check the argument type
	;
		les	di, ss:[bp].EDAA_argv
		cmp	es:[di].CD_type, LT_TYPE_STRUCT
		mov	cx, CAE_WRONG_TYPE
		jne	errorDone
	;
	; Get the format (it is easier now than after we lock stuff on
	; the run heap)
	;
		mov	si, es:[di][(size ComponentData)].CD_data.LD_integer
		cmp	si, DTF_START_TIME_FORMATS
		jb	setFormat
		cmp	si, DTF_END_TIME_FORMATS
		jb	formatOK
setFormat:
		mov	si, DTF_HM_24HOUR
formatOK:
	;
	; Get the struct
	;
		mov	ax, es:[di].CD_data.LD_struct	;ax <- struct token
		call	RunHeapLock_asm
	;		
	; Set ch:dl:dh = h:m:s assuming es:di is a struct Time
	;
		call	STDValidateTimeArgs
	;
	; unlock the run heap shme
	;
		pushf
		call	RunHeapUnlock_asm
		popf
		jc	errorDone			;branch if error
	;
	; format the beastie
	;
		sub	sp, DATE_TIME_BUFFER_SIZE*(size TCHAR)
		mov	di, sp
		segmov	es, ss				;es:di <- ptr to buf
		call	LocalFormatDateTime
	;
	; allocate and return a string
	;
		inc	cx			;cx <- length w/NULL
DBCS <		shl	cx, 1			;cx <- size >
		mov	bx, RHT_STRING
		mov	ax, es			;ax:di <- ptr to data
		clr	dx			;dx <- ref count
		call	RunHeapAlloc_asm

		add	sp, DATE_TIME_BUFFER_SIZE*(size TCHAR)
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax

done:
		.leave
		ret

errorDone:
		stc
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done
STDFormatTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDValidateTimeArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get and validate the time from a struct

CALLED BY:	STDFormatTime
PASS:		es:di - ptr to TimeOfDay struct
RETURN:		ch - hours
		dl - minutes
		dh - seconds

DESTROYED:	cl
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/17/97    	broke out common code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDValidateTimeArgs	proc	near
		uses	ax
		.enter

	; Set ch:dl:dh assuming es:di is a struct Time
	; Point si at the time changed string
	; Don't optimize the cmps to cmp of byte registers -- we want
	; to check the whole word
	;
CheckHack <size LegosStructField eq 5>
		mov	cx, es:[di][0].LSF_value.low	; hours
		cmp	cx, 23
		ja	dataError
		mov	ch, cl
		mov	dx, es:[di][5].LSF_value.low	; minutes
		cmp	dx, 59
		ja	dataError
		mov	ax, es:[di][10].LSF_value.low	; seconds
		cmp	ax, 59
		ja	dataError
		mov	dh, al		; ch:dl:dh <- hh:mm:ss
		clc				;carry <- no error
done:

		.leave
		ret

dataError:
		stc				;carry <- error
		jmp	done
STDValidateTimeArgs	endp
