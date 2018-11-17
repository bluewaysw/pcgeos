COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		gfsEntry.asm

AUTHOR:		Adam de Boor, April 13, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/13/93		Initial revision


DESCRIPTION:
	Entry point & jump table.
		

	$Id: gfsEntry.asm,v 1.1 97/04/18 11:46:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment


if not _PCMCIA

DriverTable	FSDriverInfoStruct <
	<			; FSDIS_common
	    <GFSStrategy>,		; DIS_strategy, all else default.
	    DriverExtendedInfo
	>,
	FSD_FLAGS,
	0,	; FDIS_altStrat
	<
	    0,
	    0
	>			; FDIS_altProto
>		
public DriverTable	; avoid warning

endif

idata	ends

Resident	segment	resource

DefFSFunction	macro	routine, constant
.assert ($-fsFunctions) eq constant*2, <Routine for constant in the wrong slot>
.assert (type routine eq far)
		fptr	routine
		endm

fsFunctions	label	fptr.far
DefFSFunction GFSInit,			DR_INIT
DefFSFunction GFSExit,			DR_EXIT

DefFSFunction GFSSuspend,		DR_SUSPEND
DefFSFunction GFSUnsuspend,		DR_UNSUSPEND

DefFSFunction GFSTestDevice,		DRE_TEST_DEVICE
DefFSFunction GFSDoNothing,		DRE_SET_DEVICE

DefFSFunction GFSDiskID,		DR_FS_DISK_ID
DefFSFunction GFSDiskInit,		DR_FS_DISK_INIT

if _PCMCIA
DefFSFunction GFSDiskLock,		DR_FS_DISK_LOCK
DefFSFunction GFSDiskUnlock,		DR_FS_DISK_UNLOCK
else
DefFSFunction GFSDoNothing,		DR_FS_DISK_LOCK
DefFSFunction GFSDoNothing,		DR_FS_DISK_UNLOCK
endif

DefFSFunction GFSUnsupported,		DR_FS_DISK_FORMAT
DefFSFunction GFSDiskFindFree,		DR_FS_DISK_FIND_FREE
DefFSFunction GFSDiskInfo,		DR_FS_DISK_INFO
DefFSFunction GFSUnsupported,		DR_FS_DISK_RENAME
DefFSFunction GFSUnsupported,		DR_FS_DISK_COPY
DefFSFunction GFSDiskSave,		DR_FS_DISK_SAVE
DefFSFunction GFSDoNothing,		DR_FS_DISK_RESTORE	; just clear
								;  carry, but
								;  might need
								;  more later.
DefFSFunction GFSDoNothing,		DR_FS_CHECK_NET_PATH	; never called
DefFSFunction GFSCurPathSet,		DR_FS_CUR_PATH_SET
DefFSFunction GFSCurPathGetID,		DR_FS_CUR_PATH_GET_ID
if _PCMCIA
DefFSFunction GFSCurPathDelete,		DR_FS_CUR_PATH_DELETE
DefFSFunction GFSCurPathCopy,		DR_FS_CUR_PATH_COPY
else
DefFSFunction GFSDoNothing,		DR_FS_CUR_PATH_DELETE
DefFSFunction GFSDoNothing,		DR_FS_CUR_PATH_COPY
endif

DefFSFunction GFSHandleOp,		DR_FS_HANDLE_OP
DefFSFunction GFSAllocOp,		DR_FS_ALLOC_OP
DefFSFunction GFSPathOp,		DR_FS_PATH_OP
DefFSFunction GFSCompareFiles,		DR_FS_COMPARE_FILES
DefFSFunction GFSFileEnum,		DR_FS_FILE_ENUM
DefFSFunction GFSDoNothing,		DR_FS_DRIVE_LOCK
DefFSFunction GFSDoNothing,		DR_FS_DRIVE_UNLOCK
if	DBCS_PCGEOS
DefFSFunction GFSDoNothing,		DR_FS_CONVERT_STRING
endif
CheckHack <($-fsFunctions)/2 eq FSFunction>

FILE <DefFSFunction MFSCloseFile,	DR_MFS_CLOSE_MEGAFILE		>
FILE <DefFSFunction MFSReopenFile,	DR_MFS_REOPEN_MEGAFILE		>
FILE <CheckHack <($-fsFunctions)/2 eq MegaFileFSFunction>		>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSStrategy
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
GFSStrategy	proc	far
if	ERROR_CHECK
if	_FILE
		cmp	di, MegaFileFSFunction
else
		cmp	di, FSFunction
endif
endif
EC <		ERROR_AE	INVALID_FS_FUNCTION			>
EC <		test	di, 1						>
EC <		ERROR_NZ	INVALID_FS_FUNCTION			>
	;
	; If the routine is in fixed memory, call it directly.
	; 
		shl	di		; *2 to get dwords
		add	di, offset fsFunctions
		FALL_THRU_ECN	GFSEntryCallFunction
GFSStrategy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEntryCallFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the function whose fptr is pointed to by cs:di, dealing
		with movable/fixed state of the routine.

CALLED BY:	GFSStrategy
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
GFSEntryCallFunction proc ecnear
		.enter
		push	ss:[TPD_callVector].offset, ss:[TPD_dataAX], ss:[TPD_dataBX]
		pushdw	cs:[di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL	
		pop	ss:[TPD_callVector].offset, ss:[TPD_dataAX], ss:[TPD_dataBX]
		.leave
		ret
GFSEntryCallFunction endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSTestDevice
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
GFSTestDevice	proc	far
		.enter
		clc
		mov	ax, DP_PRESENT
		.leave
		ret
GFSTestDevice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSCurPathCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note another usage for this socket

CALLED BY:	GFSStrategy

PASS:		es:si - DiskDesc

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 3/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PCMCIA
GFSCurPathCopy	proc far
		uses	ds,bx
		.enter
		call	PGFSUDerefSocketFromDisk
		inc	ds:[bx].PGFSSI_inUseCount
		clc
		.leave
		ret
GFSCurPathCopy	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSCurPathDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the in-use count on the socket

CALLED BY:	GFSStrategy

PASS:		es:si - DiskDesc

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 3/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PCMCIA
GFSCurPathDelete	proc far
		uses	ds, bx
		.enter
		call	PGFSUDerefSocketFromDisk
		dec	ds:[bx].PGFSSI_inUseCount
		clc
		.leave
		ret
GFSCurPathDelete	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDiskLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Power up the PCMCIA card

CALLED BY:	GFSStrategy - DR_FS_DISK_LOCK

PASS:		es:si - DiskDesc

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	12/27/00 ayuen: To avoid some deadlock problem in some DOS IFS drivers,
	the kernel is now changed to not grab/release DSE_lockSem around calls
	to DR_FS_DISK_LOCK, such that the IFS driver can decide whether or not
	to enforce mutual-exclusion.  For PGFS driver we need to grab/release
	the semaphore ourselves.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 5/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PCMCIA
GFSDiskLock	proc far
		uses	ax, bx
		.enter
		mov	bx, es:[si].DD_drive
		PSem	es, [bx].DSE_lockSem, TRASH_AX
		call	PGFSPowerOn
		VSem	es, [bx].DSE_lockSem, TRASH_AX_BX
		.leave
		ret
GFSDiskLock	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDiskUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Power down the PCMCIA drive

CALLED BY:	GFSStrategy - DR_FS_DISK_UNLOCK

PASS:		es:si - DiskDesc

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 5/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PCMCIA
GFSDiskUnlock	proc far
		uses	bx
		.enter
		mov	bx, es:[si].DD_drive
		call	PGFSPowerOff
		.leave
		ret
GFSDiskUnlock	endp
endif





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Like the name says. Just clear the carry, to be safe.

CALLED BY:	DRE_SET_DEVICE, 
       		DR_FS_CUR_PATH_DELETE, DR_FS_DRIVE_LOCK,
		DR_FS_DRIVE_UNLOCK
PASS:		nothing
RETURN:		carry clear
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDoNothing	proc	far
		.enter
		clc
		.leave
		ret
GFSDoNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSUnsupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Like the name says. Set the carry and return an error.

CALLED BY:	DR_FS_DISK_FORMAT, DR_FS_DISK_COPY, DR_FS_DISK_RENAME
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
GFSUnsupported	proc	far
		.enter
		stc
		mov	ax, ERROR_UNSUPPORTED_FUNCTION
		.leave
		ret
GFSUnsupported	endp

Resident	ends
