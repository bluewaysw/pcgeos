COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		netwareEntry.asm

AUTHOR:		Adam de Boor, Mar 29, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/29/92		Initial revision


DESCRIPTION:
	Strategy routines and function tables for the NetWare IFS driver.
		

	$Id: netwareEntry.asm,v 1.1 97/04/10 11:55:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment



DriverTable	FSDriverInfoStruct <
	<			; FSDIS_common
	    <NWStrategy>,		; DIS_strategy, all else default.
	    DriverExtendedInfo
	>,
	FSD_FLAGS,
	NWSecondaryStrategy,	; FDIS_altStrategy
	<
	    DOS_SECONDARY_FS_PROTO_MAJOR,
	    DOS_SECONDARY_FS_PROTO_MINOR
	>			; FDIS_altProto
>
public	DriverTable

idata	ends

Resident	segment	resource

DefFSFunction	macro	routine, constant
ifidn <routine>, <NWHandOff>
		fptr.far	0
else
.assert ($-fsFunctions) eq constant*2, <Routine for constant in the wrong slot>
.assert (type routine eq far)
		fptr.far	routine
endif
		endm

fsFunctions	label	fptr.far
DefFSFunction NWInit,			DR_INIT
DefFSFunction NWExit,			DR_EXIT
DefFSFunction NWExit,			DR_SUSPEND
DefFSFunction NWUnsuspend,		DR_UNSUSPEND
DefFSFunction NWDoNothing,		DRE_TEST_DEVICE
DefFSFunction NWDoNothing,		DRE_SET_DEVICE
DefFSFunction NWDiskID,			DR_FS_DISK_ID
DefFSFunction NWDiskInit,		DR_FS_DISK_INIT
DefFSFunction NWDoNothing,		DR_FS_DISK_LOCK
DefFSFunction NWDoNothing,		DR_FS_DISK_UNLOCK
DefFSFunction NWError,			DR_FS_DISK_FORMAT
DefFSFunction NWHandOff,		DR_FS_DISK_FIND_FREE
DefFSFunction NWHandOff,		DR_FS_DISK_INFO
DefFSFunction NWDiskRename,		DR_FS_DISK_RENAME
DefFSFunction NWError,			DR_FS_DISK_COPY
DefFSFunction NWDiskSave,		DR_FS_DISK_SAVE
DefFSFunction NWDiskRestore,		DR_FS_DISK_RESTORE
DefFSFunction NWCheckNetPath,		DR_FS_CHECK_NET_PATH
DefFSFunction NWHandOff,		DR_FS_CUR_PATH_SET
DefFSFunction NWHandOff,		DR_FS_CUR_PATH_GET_ID
DefFSFunction NWHandOff,		DR_FS_CUR_PATH_DELETE
DefFSFunction NWHandOff,		DR_FS_CUR_PATH_COPY
DefFSFunction NWHandOff,		DR_FS_HANDLE_OP
DefFSFunction NWHandOff,		DR_FS_ALLOC_OP
DefFSFunction NWHandOff,		DR_FS_PATH_OP
DefFSFunction NWCompareFiles,		DR_FS_COMPARE_FILES
DefFSFunction NWHandOff,		DR_FS_FILE_ENUM
DefFSFunction NWDoNothing,		DR_FS_DRIVE_LOCK
DefFSFunction NWDoNothing,		DR_FS_DRIVE_UNLOCK
DBCS <DefFSFunction NWDoNothing,		DR_FS_CONVERT_STRING>
CheckHack <($-fsFunctions)/2 eq FSFunction>
DefFSFunction NWMapDrive,		DR_NETWARE_MAP_DRIVE
CheckHack <($-fsFunctions)/2 eq NetWareFunction>

DefSFSFunction	macro	routine, constant
.assert ($-dosSecondaryFunctions) eq constant*2, <Routine for constant in the wrong slot>
.assert (type routine eq far)
		fptr.far	routine
		endm

dosSecondaryFunctions	label	fptr.far
DefSFSFunction	NWGetExtAttribute,	DR_DSFS_GET_EXT_ATTRIBUTE
DefSFSFunction	NWSetExtAttribute,	DR_DSFS_SET_EXT_ATTRIBUTE
DefSFSFunction	NWDoNothing,		DR_DSFS_GET_WRITABLE
CheckHack <($-dosSecondaryFunctions)/2 eq DOSSecondaryFSFunction>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWEntryCallFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the function whose fptr is pointed to by cs:di, dealing
		with movable/fixed state of the routine.

CALLED BY:	NWStrategy, NWSecondaryStrategy
PASS:		cs:di	= fptr.fptr.far
RETURN:		whatever
DESTROYED:	bp destroyed by this function before target function called

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version
	sh	4/21/94		XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWMovableFrame	struct
    NWMF_routine	fptr.far
    NWMF_handle		hptr
NWMovableFrame	ends

NWEntryCallFunction proc ecnear
		.enter

		push	ss:[TPD_dataAX]
		push	ss:[TPD_dataBX]
		push	ss:[TPD_callVector].offset
		pushdw	cs:[di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	ss:[TPD_callVector].offset
		pop	ss:[TPD_dataBX]
		pop	ss:[TPD_dataAX]

		.leave
		ret
NWEntryCallFunction endp

if 0

;
; SH 05.03.94
; Drew has spoken: This code removed in favor of the on above.
;

NWEntryCallFunction proc ecnear
		.enter
		cmp	cs:[di].segment, MAX_SEGMENT
		jae	movable
		call	{fptr.far}cs:[di]
done:
		.leave
		ret
movable:
	;
	; Target is movable, so lock down the code resource and call
	; it.
	; 
		sub	sp, size NWMovableFrame
		mov	bp, sp
		push	ax, bx
		mov	bx, cs:[di].segment
		shl	bx		; shift left four
		shl	bx		;  times to convert
		shl	bx		;  virtual segment to
		shl	bx		;  handle
		call	MemLock

		mov	ss:[bp].NWMF_routine.segment, ax
		mov	ss:[bp].NWMF_handle, bx	; save handle for unlock
		mov	ax, cs:[di].offset
		mov	ss:[bp].NWMF_routine.offset, ax
		pop	ax, bx

		call	ss:[bp].NWMF_routine
	;
	; Unlock the code resource and clear the stack of our little frame.
	; 
		CheckHack <offset NWMF_handle+size NWMF_handle eq \
				size NWMovableFrame>

		mov	bp, sp
		xchg	bx, ss:[bp].NWMF_handle	; bx <- code handle, saving
						;  possible return value
		call	MemUnlock
		lea	sp, ss:[bp].NWMF_handle	; clear extra stuff off the
						;  stack
		pop	bx			;  and recover bx for return
		jmp	done
NWEntryCallFunction endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Main entry point for this here driver.

CALLED BY:	kernel
PASS:		di	= FSFunction to perform.
RETURN:		?
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWStrategy	proc	far
;EC <		cmp	di, FSFunction					>
EC <		cmp	di, NetWareFunction				>
EC <		ERROR_AE	INVALID_FS_FUNCTION			>
EC <		test	di, 1						>
EC <		ERROR_NZ	INVALID_FS_FUNCTION			>
		shl	di
		tst	cs:[fsFunctions][di].segment
		jz	handOff
		add	di, offset fsFunctions
		GOTO_ECN	NWEntryCallFunction

handOff:
	;
	; Stack-optimized handling of handing control to the primary FSD:
	; The effect is to push the address of the primary strategy routine
	; for the FSD on the stack and use it as our return address.
	;
		shr	di
		push	bp, ax, ds
		segmov	ds, dgroup, ax
		mov	bp, sp
		mov	ax, ds:[nwPrimaryStrat].segment
		xchg	ax, ss:[bp+4]		; ax <- saved BP, put segment
						;  on the stack
		push	ax			; save BP again
		mov	ax, ds:[nwPrimaryStrat].offset
		xchg	ax, ss:[bp+2]		; ax <- saved AX, put offset
						;  on the stack
		pop	bp			; bp <- saved BP
		pop	ds			; ds <- saved DS
		retf				; go to the primary
NWStrategy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSecondaryStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grudgingly perform some menial task for the primary driver

CALLED BY:	Primary IFS driver
PASS:		di	= DOSSecondaryFSFunction
RETURN:		?
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSecondaryStrategy proc	far
EC <		cmp	di, DOSSecondaryFSFunction			>
EC <		ERROR_AE	INVALID_SECONDARY_FUNCTION		>
EC <		test	di, 1						>
EC <		ERROR_NZ	INVALID_SECONDARY_FUNCTION		>
		shl	di
		add	di, offset dosSecondaryFunctions
		GOTO_ECN	NWEntryCallFunction
NWSecondaryStrategy endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for a function that should never be called.

CALLED BY:	DR_FS_DISK_FORMAT, DR_FS_DISK_COPY
PASS:		nothing
RETURN:		carry set (NEC version) & ax = ERROR_UNSUPPORTED_FUNCTION
		death (EC version)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWError		proc	far
EC <		ERROR	GASP_CHOKE_WHEEZE				>
NEC <		mov	ax, ERROR_UNSUPPORTED_FUNCTION			>
NEC <		stc							>
NEC <		ret							>
NWError		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just what the name implies

CALLED BY:	DRE_TEST_DEVICE, DRE_SET_DEVICE, DR_FS_DRIVE_LOCK,
      		DR_FS_DRIVE_UNLOCK, DR_FS_DISK_LOCK, DR_FS_DISK_UNLOCK,
		DR_SUSPEND, DR_UNSUSPEND
PASS:		nothing
RETURN:		carry clear
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDoNothing	proc	far
		.enter
		clc
		.leave
		ret
NWDoNothing	endp


if 0		; no longer used -- ardeb

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWHandOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hand off a function to the primary IFS driver

CALLED BY:	DR_FS_DISK_FIND_FREE, DR_FS_DISK_INFO, DR_FS_CUR_PATH_SET,
       		DR_FS_CUR_PATH_DELETE, DR_FS_HANDLE_OP, DR_FS_ALLOC_OP,
		DR_FS_PATH_OP, DR_FS_FILE_ENUM
PASS:		cs:di	= fptr.fptr.self
RETURN:		?
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWHandOff	proc	far
	;
	; Convert DI back into its FSFunction enum
	; 
		sub	di, offset fsFunctions
		shr	di
	;
	; Call the primary to perform the function.
	; 
		GOTO	NWCallPrimary
NWHandOff	endp

endif	; 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWCompareFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare two open files (given their SFNs) to see if they
		refer to the same disk file. Note: one or both SFN may actually
		be invalid, owing to the lack of synchronization during
		the closing of a file. The driver must check for this and
		return that the two are unequal.

CALLED BY:	DR_FS_COMPARE_FILES
PASS:		al	= SFN of first file
		cl	= SFN of second file
RETURN:		ah	= flags byte (for sahf) that will allow je if the
			  two files refer to the same disk file (carry will be
			  clear after sahf).
DESTROYED:	al, di

PSEUDO CODE/STRATEGY:
		Can't do this for NetWare

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWCompareFiles	proc	far
		.enter
		or	al, 1	; flag not-equal
		lahf
		.leave
		ret
NWCompareFiles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWIdleHook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the network know the system is idle.

CALLED BY:	int 28h
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWIdleHook	proc	far
		push	ax, bx, bp, ds
	;
	; Issue the i'm-idle-you-silly-network interrupt
	; 
		mov	ah, 84h
		int	2ah
	;
	; Fetch the old int 28h vector
	; 
		segmov	ds, dgroup, ax
		movdw	axbx, ds:[nwOldInt28]
	;
	; Place it on the stack where we pushed ax and bx, recovering ax and
	; bx in the process.
	; 
		pop	ds
		mov	bp, sp
		xchg	ax, ss:[bp+4]
		xchg	bx, ss:[bp+2]
	;
	; Recover bp and "return" to the old handler.
	; 
		pop	bp
		ret
NWIdleHook		endp

Resident	ends
