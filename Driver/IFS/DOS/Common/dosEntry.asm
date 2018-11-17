COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driEntry.asm

AUTHOR:		Adam de Boor, Oct 30, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/30/91	Initial revision


DESCRIPTION:
	Entry point & jump table.
		

	$Id: dosEntry.asm,v 1.1 97/04/10 11:54:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment



DriverTable	FSDriverInfoStruct <
	<			; FSDIS_common
	    <DOSStrategy>,		; DIS_strategy, all else default.
	    DriverExtendedInfo
	>,
	FSD_FLAGS,
	DOSPrimaryStrategy,	; FDIS_altStrat
	<
	    DOS_PRIMARY_FS_PROTO_MAJOR,
	    DOS_PRIMARY_FS_PROTO_MINOR
	>			; FDIS_altProto
>		
public DriverTable	; avoid warning

idata	ends

if FULL_EXECUTE_IN_PLACE
ResidentXIP	segment resource
else
Resident	segment	resource
endif

DefFSFunction	macro	routine, constant
.assert ($-fsFunctions) eq constant*2, <Routine for constant in the wrong slot>
.assert (type routine eq far)
		fptr	routine
		endm

fsFunctions	label	fptr.far
DRI <DefFSFunction DRIInit,		DR_INIT				>
DRI <DefFSFunction DRIExit,		DR_EXIT				>

MS  <DefFSFunction MSInit,		DR_INIT				>
MS  <DefFSFunction MSExit,		DR_EXIT				>

OS2 <DefFSFunction OS2Init,		DR_INIT				>
OS2 <DefFSFunction OS2Exit,		DR_EXIT				>

DefFSFunction DOSSuspend,		DR_SUSPEND
DefFSFunction DOSUnsuspend,		DR_UNSUSPEND

DefFSFunction DOSTestDevice,		DRE_TEST_DEVICE
DefFSFunction DOSSetDevice,		DRE_SET_DEVICE

DefFSFunction DOSDiskID,		DR_FS_DISK_ID
DefFSFunction DOSDiskInit,		DR_FS_DISK_INIT
DefFSFunction DOSDiskLock,		DR_FS_DISK_LOCK
DefFSFunction DOSDiskUnlock,		DR_FS_DISK_UNLOCK
DefFSFunction DOSDiskFormat,		DR_FS_DISK_FORMAT
DefFSFunction DOSDiskFindFree,		DR_FS_DISK_FIND_FREE
DefFSFunction DOSDiskInfo,		DR_FS_DISK_INFO
DefFSFunction DOSDiskRename,		DR_FS_DISK_RENAME
DefFSFunction DOSDiskCopy,		DR_FS_DISK_COPY
DefFSFunction DOSDiskSave,		DR_FS_DISK_SAVE
DefFSFunction DOSDiskRestore,		DR_FS_DISK_RESTORE
DefFSFunction DOSCheckNetPath,		DR_FS_CHECK_NET_PATH
DefFSFunction DOSCurPathSet,		DR_FS_CUR_PATH_SET
DefFSFunction DOSCurPathGetID,		DR_FS_CUR_PATH_GET_ID
DefFSFunction DOSCurPathDelete,		DR_FS_CUR_PATH_DELETE
DefFSFunction DOSCurPathCopy,		DR_FS_CUR_PATH_COPY
DefFSFunction DOSHandleOp,		DR_FS_HANDLE_OP
DefFSFunction DOSAllocOp,		DR_FS_ALLOC_OP
DefFSFunction DOSPathOp,		DR_FS_PATH_OP
DefFSFunction DOSCompareFiles,		DR_FS_COMPARE_FILES
DefFSFunction DOSFileEnum,		DR_FS_FILE_ENUM
DefFSFunction DOSDriveLock,		DR_FS_DRIVE_LOCK
DefFSFunction DOSDriveUnlock,		DR_FS_DRIVE_UNLOCK
if DBCS_PCGEOS
DefFSFunction DOSConvertString,		DR_FS_CONVERT_STRING
endif
CheckHack <($-fsFunctions)/2 eq FSFunction>

DefPFSFunction	macro	routine, constant
.assert ($-dosPrimaryFunctions) eq (constant-FSFunction)*2, <Routine for constant in the wrong slot>
.assert (type routine eq far)
		fptr	routine
		endm

dosPrimaryFunctions label fptr.far

DefPFSFunction	DOSAllocDosHandleFar, DR_DPFS_ALLOC_DOS_HANDLE
DefPFSFunction	DOSFreeDosHandleFar, DR_DPFS_FREE_DOS_HANDLE
DefPFSFunction	DOSLockCWDFar, DR_DPFS_LOCK_CWD
DefPFSFunction	DOSUnlockCWD, DR_DPFS_UNLOCK_CWD
DefPFSFunction	DOSUtilOpenFar, DR_DPFS_OPEN_INTERNAL
DefPFSFunction	DOSInitTakeOverFile, DR_DPFS_INIT_HANDLE
DefPFSFunction	DOSInvalCurPath, DR_DPFS_INVAL_CUR_PATH
DefPFSFunction	DOSMapVolumeName, DR_DPFS_MAP_VOLUME_NAME
DefPFSFunction	DOSVirtMapToDOS, DR_DPFS_MAP_TO_DOS
DefPFSFunction	DOSUtilInt21, DR_DPFS_CALL_DOS
DefPFSFunction	DOSPreventCriticalErr, DR_DPFS_PREVENT_CRITICAL_ERR
DefPFSFunction	DOSAllowCriticalErr, DR_DPFS_ALLOW_CRITICAL_ERR
DefPFSFunction	DOSDiskPLockSectorBuffer, DR_DPFS_P_LOCK_SECTOR_BUFFER
DefPFSFunction	DOSDiskUnlockVSectorBuffer, DR_DPFS_UNLOCK_V_SECTOR_BUFFER

.assert ($-dosPrimaryFunctions)/2 eq (DOSPrimaryFSFunction-first DOSPrimaryFSFunction)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a function on one of our drives for the kernel.

CALLED BY:	Kernel
PASS:		di	= function to perform
		other args as appropriate
RETURN:		various and sundry.
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSStrategy	proc	far
		.enter
EC <		cmp	di, FSFunction					>
EC <		ERROR_AE	INVALID_FS_FUNCTION			>
EC <		test	di, 1						>
EC <		ERROR_NZ	INVALID_FS_FUNCTION			>
	;
	; If the routine is in fixed memory, call it directly.
	; 
		shl	di		; *2 to get dwords
		add	di, offset fsFunctions
		call	DOSEntryCallFunction
		.leave
		ret
DOSStrategy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSEntryCallFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the function whose fptr is pointed to by cs:di, dealing
		with movable/fixed state of the routine.

CALLED BY:	DOSStrategy, DOSPrimaryStrategy
PASS:		cs:di	= fptr.fptr.far
RETURN:		whatever
DESTROYED:	bp destroyed by this function before target function called

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSEntryCallFunction proc near
		.enter
		push	ss:[TPD_callVector].offset, ss:[TPD_dataAX], ss:[TPD_dataBX]
		pushdw	cs:[di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL	
		pop	ss:[TPD_callVector].offset, ss:[TPD_dataAX], ss:[TPD_dataBX]

		.leave
		ret
DOSEntryCallFunction endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPrimaryStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Similar to DOSStrategy, but the operation is performed
		on a drive not actually managed by us. In effect, we're
		acting as a library for a secondary FSD.

CALLED BY:	Secondary FSD's
PASS:		di	= function to perform
		other args as appropriate
RETURN:		values as appropriate to the function performed
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPrimaryStrategy proc	far
		.enter
EC <		call	ECCheckStack					>
EC <		test	di, 1						>
EC <		ERROR_NZ	INVALID_DOS_PRIMARY_FS_FUNCTION		>
EC <		cmp	di, DOSPrimaryFSFunction			>
EC <		ERROR_AE	INVALID_DOS_PRIMARY_FS_FUNCTION		>
	;
	; If standard FS function, just pass it directly off to our sibling
	; strategy function.
	; 
		cmp	di, FSFunction
		jae	special
		call	DOSStrategy
done:
		.leave
		ret
special:
		sub	di, FSFunction
		shl	di
		add	di, offset dosPrimaryFunctions
		call	DOSEntryCallFunction
		jmp	done
DOSPrimaryStrategy endp

if FULL_EXECUTE_IN_PLACE
ResidentXIP	ends
Resident	segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSTestDevice	proc	far
		.enter
		clc
		mov	ax, DP_PRESENT
		.leave
		ret
DOSTestDevice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSSetDevice	proc	far
		.enter
		.leave
		ret
DOSSetDevice	endp

Resident	ends
