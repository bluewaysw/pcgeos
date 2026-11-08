COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File System Drivers
FILE:		hostfsEntry.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB	HostFSStrategy		Entry point
    INT	HostFSEntryCallFunction	Call a routine from the function table
    EXT	HostFSDoNothing		Successful no-op
    EXT	HostFSUnsupported	Unsupported function
    EXT	HostFSTestDevice	Device is always present

DESCRIPTION:
	Driver table, function table and strategy routine.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

DriverTable	FSDriverInfoStruct <
	<				; FSDIS_common
	    <HostFSStrategy>,		; DIS_strategy, all else default.
	    DriverExtendedInfo
	>,
	FSD_FLAGS,
	0,				; FDIS_altStrat
	<
	    0,
	    0
	>				; FDIS_altProto
>
public DriverTable

idata	ends


Resident	segment	resource

DefFSFunction	macro	routine, constant
.assert ($-fsFunctions) eq constant*2, <Routine for constant in the wrong slot>
.assert (type routine eq far)
		fptr	routine
		endm

fsFunctions	label	fptr.far
DefFSFunction HostFSInit,		DR_INIT
DefFSFunction HostFSExit,		DR_EXIT
DefFSFunction HostFSDoNothing,		DR_SUSPEND
DefFSFunction HostFSDoNothing,		DR_UNSUSPEND
DefFSFunction HostFSTestDevice,		DRE_TEST_DEVICE
DefFSFunction HostFSDoNothing,		DRE_SET_DEVICE
DefFSFunction HostFSDiskID,		DR_FS_DISK_ID
DefFSFunction HostFSDiskInit,		DR_FS_DISK_INIT
DefFSFunction HostFSDoNothing,		DR_FS_DISK_LOCK
DefFSFunction HostFSDoNothing,		DR_FS_DISK_UNLOCK
DefFSFunction HostFSUnsupported,	DR_FS_DISK_FORMAT
DefFSFunction HostFSDiskFindFree,	DR_FS_DISK_FIND_FREE
DefFSFunction HostFSDiskInfo,		DR_FS_DISK_INFO
DefFSFunction HostFSUnsupported,	DR_FS_DISK_RENAME
DefFSFunction HostFSUnsupported,	DR_FS_DISK_COPY
DefFSFunction HostFSDiskSave,		DR_FS_DISK_SAVE
DefFSFunction HostFSDoNothing,		DR_FS_DISK_RESTORE
DefFSFunction HostFSDoNothing,		DR_FS_CHECK_NET_PATH
DefFSFunction HostFSCurPathSet,		DR_FS_CUR_PATH_SET
DefFSFunction HostFSCurPathGetID,	DR_FS_CUR_PATH_GET_ID
DefFSFunction HostFSDoNothing,		DR_FS_CUR_PATH_DELETE
DefFSFunction HostFSDoNothing,		DR_FS_CUR_PATH_COPY
DefFSFunction HostFSHandleOp,		DR_FS_HANDLE_OP
DefFSFunction HostFSAllocOp,		DR_FS_ALLOC_OP
DefFSFunction HostFSPathOp,		DR_FS_PATH_OP
DefFSFunction HostFSCompareFiles,	DR_FS_COMPARE_FILES
DefFSFunction HostFSFileEnum,		DR_FS_FILE_ENUM
DefFSFunction HostFSDoNothing,		DR_FS_DRIVE_LOCK
DefFSFunction HostFSDoNothing,		DR_FS_DRIVE_UNLOCK
if	DBCS_PCGEOS
DefFSFunction HostFSDoNothing,		DR_FS_CONVERT_STRING
endif
CheckHack <($-fsFunctions)/2 eq FSFunction>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a function on our drive for the kernel.
CALLED BY:	Kernel
PASS:		di	= function to perform
		other args as appropriate
RETURN:		various and sundry.
DESTROYED:	?

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSStrategy	proc	far
EC <		cmp	di, FSFunction					>
EC <		ERROR_AE	INVALID_FS_FUNCTION			>
EC <		test	di, 1						>
EC <		ERROR_NZ	INVALID_FS_FUNCTION			>
		shl	di			; *2 to get dwords
		add	di, offset fsFunctions
		FALL_THRU_ECN	HostFSEntryCallFunction
HostFSStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSEntryCallFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the function whose fptr is pointed to by cs:di.
CALLED BY:	HostFSStrategy
PASS:		cs:di	= fptr.fptr.far
RETURN:		whatever
DESTROYED:	bp destroyed by this function before target function called

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSEntryCallFunction proc ecnear
		.enter
		push	ss:[TPD_callVector].offset, ss:[TPD_dataAX], \
			ss:[TPD_dataBX]
		pushdw	cs:[di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	ss:[TPD_callVector].offset, ss:[TPD_dataAX], \
			ss:[TPD_dataBX]
		.leave
		ret
HostFSEntryCallFunction endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSDoNothing / HostFSUnsupported / HostFSTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Trivial functions.
RETURN:		HostFSDoNothing:	carry clear
		HostFSUnsupported:	carry set, ax = ERROR_UNSUPPORTED_FUNCTION
		HostFSTestDevice:	carry clear, ax = DP_PRESENT
DESTROYED:	nothing else

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSDoNothing	proc	far
		clc
		ret
HostFSDoNothing	endp

HostFSUnsupported proc	far
		mov	ax, ERROR_UNSUPPORTED_FUNCTION
		stc
		ret
HostFSUnsupported endp

HostFSTestDevice proc	far
		mov	ax, DP_PRESENT
		clc
		ret
HostFSTestDevice endp

Resident	ends
