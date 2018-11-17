COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskDriver.asm

AUTHOR:		Adam de Boor, Sep 21, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/21/91		Initial revision


DESCRIPTION:
	Device-driver interface for this thing....
		
	The following functions must be implemented by switcher-dependent
	code:
		TaskDrInit		should *not* fail if switcher not
					loaded
		TaskDrExit
		TaskDrTestDevice	fail if switcher not loaded
		TaskDrSetDevice		brings switcher support on-line
		

	$Id: taskDriver.asm,v 1.1 97/04/18 11:58:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment

DriverTable	TaskDriverInfoStruct	<
	<			; TDIS_common
	    <				; DEIS_common
		TaskStrategy,			; DIS_strategy
		mask DA_HAS_EXTENDED_INFO,	; DIS_driverAttributes
		DRIVER_TYPE_TASK_SWITCH		; DIS_driverType
	    >,
	    handle TaskDriverExtInfo	; DEIS_resource
	>,
	mask TDF_SUPPORTS_TASK_LIST	; TDIS_flags
>
public	DriverTable

idata		ends

Resident	segment	resource


tsFunctions	label	nptr.near

DefTSFunction	macro	routine, constant
.assert ($-tsFunctions) eq constant, <Routine for constant in the wrong slot>
.assert (type routine eq near)
		nptr	routine
		endm

DefTSFunction	TaskDrInit,			DR_INIT
DefTSFunction	TaskDrExit,			DR_EXIT
DefTSFunction	TaskDrDoNothing,		DR_SUSPEND
DefTSFunction	TaskDrDoNothing,		DR_UNSUSPEND
DefTSFunction	TaskDrTestDevice,		DRE_TEST_DEVICE
DefTSFunction	TaskDrSetDevice,		DRE_SET_DEVICE
DefTSFunction	TaskDrBuildList,		DR_TASK_BUILD_LIST
DefTSFunction	TaskDrSwitch,			DR_TASK_SWITCH
DefTSFunction	TaskDrDelete,			DR_TASK_DELETE
DefTSFunction	TaskDrStart,			DR_TASK_START
DefTSFunction	TaskDrDoNothing,		DR_TASK_APPS_SHUTDOWN
DefTSFunction	TaskDrDoNothing,		DR_TASK_SHUTDOWN_COMPLETE
.assert	$-tsFunctions eq TaskFunction


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine for our driver aspect.

CALLED BY:	kernel
PASS:		di	= DriverFunction
RETURN:		carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskStrategy	proc	far
		.enter
EC <		cmp	di, TaskFunction				>
EC <		ERROR_AE	INVALID_DRIVER_FUNCTION			>
EC <		test	di, 1						>
EC <		ERROR_NZ	INVALID_DRIVER_FUNCTION			>

   		call	cs:[tsFunctions][di]
		.leave
		ret
TaskStrategy 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Guess what?

CALLED BY:	TaskStrategy
PASS:		nothing important
RETURN:		carry clear
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrDoNothing	proc	near
		.enter
		clc
		.leave
		ret
TaskDrDoNothing	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrBuildList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add entries to a list, one per active task. All entries are
		marked ignore dirty.

CALLED BY:	DR_TASK_BUILD_LIST
PASS:		^lcx:dx	= GenItemGroup to which to append the entries
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrBuildList proc	near
		uses	bx, si, bp
		.enter
		mov	bx, handle TaskApp
		mov	si, offset TaskApp
		mov	ax, MSG_TA_BUILD_TASK_LIST
		mov	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
TaskDrBuildList endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrSwitch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch to the task whose identifier is passed.

CALLED BY:	DR_TASK_SWITCH
PASS:		cx	= identifier from selected item
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrSwitch	proc	near
		uses	bx, bp, dx
		.enter
	;
	; Tell our process to switch to that task.
	; 
		mov	bx, handle 0
		mov	dx, cx
		clr	di
		mov	ax, MSG_TD_SWITCH
		call	ObjMessage
		.leave
		ret
TaskDrSwitch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the task whose TaskItem is passed.

CALLED BY:	DR_TASK_DELETE
PASS:		^lcx:dx	= list entry whose task should be nuked
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrDelete	proc	near
		uses	bx, si, cx, dx, bp
		.enter
		mov	bx, cx
		mov	si, dx

EC <		mov	cx, segment TaskItemClass			>
EC <		mov	dx, offset TaskItemClass			>
EC <		mov	ax, MSG_META_IS_OBJECT_IN_CLASS			>
EC <		mov	di, mask MF_CALL				>
EC <		call	ObjMessage					>
EC <		ERROR_NC	PASSED_LIST_ENTRY_NOT_ONE_OF_OURS	>

   		mov	ax, MSG_TI_NUKE_TASK
		mov	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
TaskDrDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spawn a new task with the passed args.

CALLED BY:	DR_TASK_START
PASS:		ds	= segment of locked DosExecArgs block
		cx:dx	= boot directory
RETURN:		carry set if couldn't start
			ax	= FileError
		carry clear if task is on its way:
			ax	= destroyed
DESTROYED:	bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrStart	proc	near
		.enter
	;
	; Just unlock the thing and ship it off to our process to deal with.
	; 
		mov	bx, ds:[DEA_handle]
		call	MemUnlock
		mov	cx, bx
		mov	bx, handle 0
		mov	ax, MSG_TD_DOS_EXEC
		clr	di
		call	ObjMessage
		.leave
		ret
TaskDrStart	endp


Resident	ends

