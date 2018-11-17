COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Designs In Light, 2000 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Library/Pref/PrefPM
FILE:		prefpm.asm

AUTHOR:		Gene Anderson

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/8/00		Initial revision

DESCRIPTION:
	Contains the code for a power management module

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def
include object.def
include	graphics.def
include gstring.def
include	win.def
include char.def
include system.def					; need for SCI access
include timer.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def

;------------------------------------------------------------------------------
;	Include object definitions
;------------------------------------------------------------------------------

include Objects/vTextC.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------

UseDriver Internal/powerDr.def
 
include prefpm.def
include prefpm.rdef


;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata segment
	PrefPowerDialogClass
	DriverStatusDialogClass
idata ends

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PrefPowerCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPowerGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		nothing 

RETURN:		dx:ax - OD of root of tree

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/08/00	Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPowerGetPrefUITree	proc far
	mov	dx, handle PrefPowerRoot
	mov	ax, offset PrefPowerRoot
	ret
PrefPowerGetPrefUITree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPowerGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr

PASS:		ds:si - PrefModuleInfo structure to be filled in

RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/08/00	Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPowerGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_HARDWARE or mask PMF_SYSTEM
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle  PrefPowerMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset  PrefPowerMonikerList
	mov	{word} ds:[si].PMI_monikerToken, 'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'P' or ('W' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 
	
	.leave
	ret
PrefPowerGetModuleInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallPowerDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the power management driver

CALLED BY:	UTILITY

PASS:		di - DR_POWER_*
		ax, bx, cx, dx - arguments

RETURN:		depends on function
		carry - depends on function (set if error)

DESTROYED:	depends on function

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/08/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetPowerDriver	proc	near
		uses	ax

		.enter
		mov	ax, GDDT_POWER_MANAGEMENT
		call	GeodeGetDefaultDriver
		mov_tr	bx, ax
		tst	bx

		.leave
		ret
GetPowerDriver	endp

CallPowerDriverStatus	proc
		uses	di
		.enter

		mov	di, DR_POWER_GET_STATUS
		call	CallPowerDriver

		.leave
		ret
CallPowerDriverStatus	endp

CallPowerDriver	proc	near
		uses	es, di
driverStrat	local	fptr.far
		.enter

	;
	; get the driver handle, if any
	;
		call	GetPowerDriver
		stc				;carry <- in case of error
		jz	done			;branch if no driver
	;
	; call the driver
	;
		push	ds, si, ax
		call	GeodeInfoDriver		;ds:si <- DriverInfoStruct
		movdw	ss:driverStrat, ds:[si].DIS_strategy, ax
		pop	ds, si, ax
		call	ss:driverStrat
done:
		.leave
		ret
CallPowerDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPowerDialogOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle opening of "Power" section

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of PrefKbdDialogClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/08/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPowerDialogOpen		method dynamic PrefPowerDialogClass,
						MSG_VIS_OPEN
	;
	; start a timer to update the screen
	;
		push	ax, bx, bp
		mov	al, TIMER_EVENT_CONTINUAL
		mov	bx, ds:OLMBH_header.LMBH_handle	;bx:si <- OD
		clr	cx				;cx <- first
		mov	dx, MSG_PREF_POWER_DIALOG_UPDATE_STATUS
		mov	di, STATUS_TIMER_INTERVAL
		call	TimerStart

		mov	di, ds:[si]
		add	di, ds:[di].PrefPowerDialog_offset
		mov	ds:[di].PPDI_timerID, ax
		mov	ds:[di].PPDI_timerHandle, bx
		pop	ax, bx, bp
	;
	; finish opening
	;
		mov	di, offset PrefPowerDialogClass
		GOTO	ObjCallSuperNoLock

PrefPowerDialogOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPowerDialogClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle closing of "Power" section

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of PrefKbdDialogClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/09/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPowerDialogClose		method dynamic PrefPowerDialogClass,
						MSG_VIS_CLOSE
		tst	ds:[di].PPDI_timerHandle
		jz	done
	;
	; stop our timer
	;
		push	ax, bx
		clr	ax, bx
		xchg	ax, ds:[di].PPDI_timerID
		xchg	bx, ds:[di].PPDI_timerHandle
		call	TimerStop
		pop	ax, bx
	;
	; finish opening
	;
done:
		mov	di, offset PrefPowerDialogClass
		GOTO	ObjCallSuperNoLock
PrefPowerDialogClose		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPowerDialogOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle opening of "Power" section

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of PrefKbdDialogClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/08/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPowerDialogUpdateStatus		method dynamic PrefPowerDialogClass,
					MSG_PREF_POWER_DIALOG_UPDATE_STATUS
		.enter

	;
	; see if the driver is loaded
	;
		call	GetPowerDriver
		jz	noDriver
	;
	; get the percentage left
	;
		mov	ax, PGST_BATTERY_CHARGE_PERCENT
		call	CallPowerDriverStatus
		jnc	percentOK			;branch if no error
	;
	; percent not supported
	;
		mov	bp, offset PowerNoPercentString
		call	UpdateStatusText
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	doEnableDisable
		jmp	getPowerSource

	;
	; make sure the meter is enabled
	;
percentOK:
		push	ax, dx
		mov	ax, MSG_GEN_SET_ENABLED
		call	doEnableDisable
		pop	ax, dx
	;
	; set the meter level
	;
		mov	cx, 10
		div	cx				;dx:ax <- percentage
		mov	cx, ax				;cx <- percentage
		clr	bp				;bp <- not intd.
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		mov	si, offset BatteryMeter
		call	ObjCallInstanceNoLock
	;
	; get the power source
	;
getPowerSource:
		mov	ax, PGST_STATUS
		call	CallPowerDriverStatus
		mov	bp, offset PowerNoACString
		jc	gotString			;branch if error
		test	bx, mask PS_AC_ADAPTER_CONNECTED
		jz	gotString			;branch if not sppt.
		mov	bp, offset PowerACString
		test	ax, mask PS_AC_ADAPTER_CONNECTED
		jnz	gotString			;branch if AC power
		mov	bp, offset PowerBatteryString
	;
	; set the power source string
	;
gotString:
		call	UpdateStatusText
done::
		.leave
		ret

	;
	; no driver loaded, disable the meter and the dialog
	;
noDriver:
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	doEnableDisable
		mov	si, offset DriverStatusDB
		call	doEnableDisableObj
		mov	bp, offset PowerNoAPMString
		jmp	gotString

doEnableDisable:
		mov	si, offset BatteryMeter
doEnableDisableObj:
		push	ax, dx, bp
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		pop	ax, dx, bp
		retn
PrefPowerDialogUpdateStatus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateStatusText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update the status text line

CALLED BY:	UTILITY

PASS:		ds - seg addr of object block
		bp - chunk of string

RETURN:		ds - fixed up

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/08/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateStatusText	proc	near
		uses	ax, cx, dx, si, bp
		.enter

		mov	dx, handle Strings		;^ldx:bp <- string
		clr	cx				;cx <- NULL-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		mov	si, offset PowerSource
		call	ObjCallInstanceNoLock

		.leave
		ret
UpdateStatusText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateListStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update a boolean list status

CALLED BY:	UTILITY

PASS:		ax - flags to set
		bx - flags to enable
		*ds:si - GenBooleanGroup

RETURN:		ds - fixed up

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/09/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateListStatus	proc	near
		uses	ax, bx, cx, dx, bp

		.enter

	;
	; set the appropriate booleans
	;
		mov	cx, ax				;cx <- selected bools
		clr	dx				;dx <- indt. bools
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
		call	ObjCallInstanceNoLock
	;
	; enable or disable booleans as appropriate
	;
		mov	dx, 0x0001
		mov	cx, 16
enableLoop:
		push	bx, cx, dx, si
		mov	cx, dx				;cx <- boolean
		mov	di, dx				;di <- boolean
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_BOOLEAN_OPTR
		call	ObjCallInstanceNoLock
		jnc	notFound			;branch if not found
		mov	ax, MSG_GEN_SET_ENABLED		;ax <- assume enable
		test	bx, di				;enable?
		jnz	gotMsg				;branch if so
		inc	ax				;ax <- disable
	CheckHack <MSG_GEN_SET_NOT_ENABLED eq MSG_GEN_SET_ENABLED+1>
gotMsg:
		mov	bx, cx
		mov	si, dx				;^lbx:di <- boolean
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
notFound:
		pop	bx, cx, dx, si
		shl	dx, 1				;dx <- next bit
		loop	enableLoop			;loop while more

		.leave
		ret
UpdateListStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update a GenValue status

CALLED BY:	UTILITY

PASS:		ax - value
		carry - set to disable
		*ds:si - GenValue

RETURN:		ds - fixed up

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/09/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateValue	proc	near
		uses	ax, bx, cx, dx, bp
		.enter

		mov	cx, ax				;cx <- value
	;
	; enable or disable
	;
		mov	ax, MSG_GEN_SET_ENABLED
		jnc	gotMsg
		inc	ax
	CheckHack <MSG_GEN_SET_NOT_ENABLED eq MSG_GEN_SET_ENABLED+1>
		clr	cx				;cx <- no value
gotMsg:
		push	cx
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		pop	cx
	;
	; set the value
	;
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		clr	bp				;bp <- not indt.
		call	ObjCallInstanceNoLock

		.leave
		ret
UpdateValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	format a number

CALLED BY:	UTILITY

PASS:		es:di - ptr to buffer
		ax - # to format

RETURN:		es:di - ptr after last char

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/09/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatNum	proc	near
		uses	cx, dx
		.enter

		mov	cx, mask UHTAF_NULL_TERMINATE
		clr	dx				;dx:ax <- number
		call	UtilHex32ToAscii
DBCS <		shl	cx, 1				;*2 for DBCS>
		add	di, cx				;es:di <- ptr to NULL

		.leave
		ret
FormatNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriverStatusDialogOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle opening of "Driver Info" dialog

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si - DriverStatusDialogClass object
		ds:di - DriverStatusDialogClass instance

		bp - window handle

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/08/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriverStatusDialogOpen		method dynamic DriverStatusDialogClass,
						MSG_VIS_OPEN
		uses	ax, bp, es, si
buffer		local	50 dup (byte)
protoNum	local	ProtocolNumber
relNum		local	ReleaseNumber
		.enter
	;
	; get the handle of the power driver
	;
		call	GetPowerDriver
		LONG jc	done				;branch if error
		segmov	es, ss
	;
	; get the driver permanent name
	;
		lea	di, ss:buffer
		mov	ax, GGIT_PERM_NAME_ONLY
		call	GeodeGetInfo
		mov	{TCHAR} ss:buffer[GEODE_NAME_SIZE], 0
		mov	si, offset DSName
		call	setText
	;
	; get the protocol
	;
		lea	di, ss:protoNum
		mov	ax, GGIT_GEODE_PROTOCOL
		call	GeodeGetInfo
		lea	di, ss:buffer
		mov	ax, ss:protoNum.PN_major
		call	FormatNum
		LocalLoadChar ax, '.'
		LocalPutChar esdi, ax
		mov	ax, ss:protoNum.PN_minor
		call	FormatNum
		mov	si, offset DSProto
		call	setText
	;
	; get the release
	;
		lea	di, ss:relNum
		mov	ax, GGIT_GEODE_RELEASE
		call	GeodeGetInfo
		lea	di, ss:buffer
		mov	ax, ss:relNum.RN_major
		call	FormatNum
		LocalLoadChar ax, '.'
		LocalPutChar esdi, ax
		mov	ax, ss:relNum.RN_minor
		call	FormatNum
		LocalLoadChar ax, ' '
		LocalPutChar esdi, ax
		mov	ax, ss:relNum.RN_change
		call	FormatNum
		LocalLoadChar ax, '-'
		LocalPutChar esdi, ax
		mov	ax, ss:relNum.RN_engineering
		call	FormatNum
		mov	si, offset DSRelease
		call	setText
	;
	; get the APM version
	;
		mov	{TCHAR}ss:buffer, 0
		mov	di, DR_POWER_ESC_COMMAND
		mov	si, POWER_ESC_GET_VERSION
		call	CallPowerDriver
		jc	gotAPMText
		lea	di, ss:buffer
		LocalLoadChar dx, 'v'
		LocalPutChar esdi, dx
		mov	dl, al				;dl <- proto minor
		mov	al, ah
		clr	ah				;ax <- proto major
		call	FormatNum
		LocalLoadChar ax, '.'
		LocalPutChar esdi, ax
		mov	al, dl				;ax <- proto minor
		call	FormatNum
gotAPMText:
		mov	si, offset DSAPMProto
		call	setText

	;
	; power on warnings
	;
		mov	ax, PGST_POWER_ON_WARNINGS
		call	CallPowerDriverStatus
		mov	si, offset DSPowerOnWarnings
		call	UpdateListStatus
	;
	; power poll warnings
	;
		mov	ax, PGST_POLL_WARNINGS
		call	CallPowerDriverStatus
		mov	si, offset DSPollWarnings
		call	UpdateListStatus
	;
	; power status
	;
		mov	ax, PGST_STATUS
		call	CallPowerDriverStatus
		mov	si, offset DSStatus
		call	UpdateListStatus
	;
	; charge minutes
	;
		mov	ax, PGST_BATTERY_CHARGE_MINUTES
		call	CallPowerDriverStatus
		mov	si, offset DSChargeMinutes
		call	UpdateValue
	;
	; charge percentage
	;
		mov	ax, PGST_BATTERY_CHARGE_PERCENT
		call	CallPowerDriverStatus
		pushf
		mov	cx, 10
		div	cx				;dx:ax <- percentage
		popf
		mov	si, offset DSChargePercent
		call	UpdateValue

	;
	; finish opening
	;

done:
		.leave
		mov	di, offset DriverStatusDialogClass
		GOTO	ObjCallSuperNoLock


setText:
		push	bp
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	dx, ss
		lea	bp, ss:buffer			;dx:bp <- text
		clr	cx				;cx <- NULL-terminated
		call	ObjCallInstanceNoLock
		pop	bp
		retn
DriverStatusDialogOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefPowerDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle apply of "Power" section

CALLED BY:	MSG_GEN_PRE_APPLY
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of PrefKbdDialogClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/09/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefPowerDialogPreApply		method dynamic PrefPowerDialogClass,
						MSG_GEN_PRE_APPLY
driverName	local	NAME_ARRAY_MAX_NAME_SIZE	dup (TCHAR)
		.enter

		push	ax, si, es
	;
	; see if there is any driver selected besides "none"
	;
		push	bp
		mov	si, offset PMDriverList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pop	bp
		jc	done				;branch if none
		tst	ax				;first item?
		je	done				;branch if first
	;
	; get the selected driver name
	;
		push	bp
		mov	cx, ss
		lea	dx, ss:driverName		;cx:dx <- buffer
		mov	bp, length driverName		;bp <- length
		mov	si, offset PMDriverList
		mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; go to SP_POWER_DRIVERS and try to load the driver
	;
		mov	ax, SP_POWER_DRIVERS
		call	FileSetStandardPath
		push	ds
		segmov	ds, ss
		lea	si, ss:[driverName]
		clr	ax, bx				;no protocol numbers
		call	GeodeUseDriver
		pop	ds
		jc	cantLoad
		call	GeodeFreeDriver
done:
		clc					;carry <- no error
donePop:
		pop	ax, si, es

		.leave
		ret

	;
	; can't load the driver -- complain
	;
cantLoad:
		mov	si, offset APMNotFoundErr
		call	ReportError
		stc					;carry <- error
		jmp	donePop
PrefPowerDialogPreApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReportError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up annoying DB to inform user something went wrong
CALLED BY:	UTILITY

PASS:		si - chunk of error string
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/10/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReportError	proc	near
		uses	ax, bx, cx, dx, si, di, bp, ds
		.enter

		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]

		mov	dx, (size GenAppDoDialogParams)
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].GADDP_dialog.SDP_customFlags, CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION, 0>
		movdw	ss:[bp].GADDP_dialog.SDP_customString, dssi
		clr	ax
		clrdw	ss:[bp].GADDP_dialog.SDP_customTriggers, ax
		clrdw	ss:[bp].GADDP_dialog.SDP_helpContext, ax
		clrdw	ss:[bp].GADDP_finishOD, ax
		mov	ss:[bp].GADDP_message, ax

		mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		call	UserCallApplication

		add	sp, (size GenAppDoDialogParams)

		mov	bx, handle Strings
		call	MemUnlock

		.leave
		ret
ReportError	endp

PrefPowerCode	ends
