COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		cdromInitExit.asm

AUTHOR:		Adam de Boor, Mar 29, 1992

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/29/92		Initial revision


DESCRIPTION:
	Functions to initialize and exit the driver.


	$Id: cdromInitExit.asm,v 1.1 97/04/10 11:55:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the driver.

CALLED BY:	DR_INIT
PASS:		nothing
RETURN:		carry set if couldn't initialize
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		This function is responsible for a number of things to
		initialize the system, as well as this driver, to wit:
			* locate all drives we can manage and create
			  them in the kernel.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMInit	proc	far
		.enter
	;
	; Ensure extensions actually loaded.
	; 
		mov	ax, MSDOS_GET_VERSION shl 8
		int	21h
		cmp	al, 3		; pre-3.0 had no int 2fh support
		jb	fail
		
		clr	bx		; clear to allow check for graphics.com
					;  conflict
		mov	ax, CDROM_GET_STATUS
		int	2fh
		
; the spec does not, in fact, have AL returning non-zero, unlike most other
; int 2fh installation checks. This test bombs with NWCDEX in NWDOS 7
; 		-- ardeb 10/6/93
;		tst	al
;		jz	fail

		tst	bx		; graphics.com or no one responded?
		jz	fail		; yes -- bail
		
	;
	; See if the primary FSD has been loaded yet and ensure its aux protocol
	; number is compatible.
	; 
		mov	ax, GDDT_FILE_SYSTEM
		call	GeodeGetDefaultDriver
		tst	ax
		jz	fail			; not loaded, so we can do
						;  nothing
		mov_tr	bx, ax
		call	GeodeInfoDriver
		
		mov	ax, ds:[si].FSDIS_altStrat.offset
		mov	bx, ds:[si].FSDIS_altStrat.segment
		mov	cx, ds:[si].FSDIS_altProto.PN_major
		mov	dx, ds:[si].FSDIS_altProto.PN_minor

		segmov	ds, dgroup, di
		mov	ds:[cdromPrimaryStrat].offset, ax
		mov	ds:[cdromPrimaryStrat].segment, bx
		cmp	cx, DOS_PRIMARY_FS_PROTO_MAJOR
		jne	fail
		cmp	dx, DOS_PRIMARY_FS_PROTO_MINOR
		jb	fail
	;
	; We may need the PSP at some point...
	; 
		mov	ah, MSDOS_GET_PSP
		int	21h
		mov	ds:[pspSegment], bx	; save PSP
	;
	; Since the extensions are loaded and we have drives, we remain.
	;
	; Register with the kernel.
	;
		mov	cx, segment CDROMStrategy
		mov	dx, offset CDROMStrategy
		mov	ax, FSD_FLAGS
		mov	bx, handle 0
		clr	di			; no disk-private data here
		call	FSDRegister
		mov	ds:[fsdOffset], dx

		call	CDROMInitLocateDrives

		segmov	es, ds
		call	CDROMInitOpenFiles
	;
	; Intercept critical errors so we can cope with our own errors
	; gracefully
	; 
		mov	di, offset cdromOldInt24
		mov	bx, segment CDROMCriticalError
		mov	cx, offset CDROMCriticalError
		mov	ax, CRITICAL_VECTOR
		call	SysCatchInterrupt

		clc
done:
		.leave
		ret
fail:
		stc
		jmp	done
CDROMInit		endp


;==============================================================================
;
;			    DRIVE LOCATION
;
;==============================================================================

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMInitLocateDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all the drives we can manage.

CALLED BY:	CDROMInit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMInitLocateDrives proc	near
		uses	bp, ds
		.enter
	;
	; Get the drive descriptors and letters for all the CD ROM drives.
	; 
		mov	ax, CDROM_GET_STATUS
		int	2fh			; bx <- # of drives
		mov	ds:[numDrives], bx
	    ;
	    ; Make room for the individual tables (drive number and drive
	    ; device driver) on the stack.
	    ; 
			CheckHack <size CDROMDeviceStruct eq 5>
		shl	bx
		mov	ax, bx
		shl	bx
		add	bx, ax
		mov	bp, sp		; save stack start

		sub	sp, bx
		segmov	es, ss
		mov	bx, sp		; es:bx <- buffer
		mov	ax, CDROM_GET_DRIVE_DEVICE_LIST
		int	2fh

		mov	bx, bp
		sub	bx, ds:[numDrives]	; es:bx <- buffer
		mov	ax, CDROM_GET_DRIVES
		int	2fh
	;
	; Merge the two tables
	; 
		mov	si, sp			; ss:si <- device driver table
		segmov	es, ds
		mov	cx, ds:[numDrives]	; cx <- # drives
		mov	di, offset cdromDrives	; es:di <- dest table
mergeTableLoop:
	CheckHack <offset CDRDS_unit eq 0 and offset CDRD_unit eq 0>
		movsb	ss:			; transfer unit #
		mov	al, ss:[bx]		; al <- drive #
	CheckHack <offset CDRD_number eq 1>
		stosb
	CheckHack <offset CDRDS_device eq 1 and offset CDRD_device eq 2>
		movsw	ss:
		movsw	ss:
		inc	bx
		loop	mergeTableLoop
		
		mov	sp, bp		; clear the stack

	;
	; Now create drive descriptors for them.
	; 
		mov	di, offset cdromDrives
		mov	cx, ds:[numDrives]
		segmov	ds, ss
createLoop:
		push	cx
		mov	al, es:[di].CDRD_number
		mov	ah, MEDIA_CUSTOM
		mov	cx, mask DS_PRESENT or DRIVE_CD_ROM or \
				mask DS_MEDIA_REMOVABLE or mask DES_READ_ONLY
		mov	dx, es:[fsdOffset]
		clr	bh		; set up drive name
		mov	bl, al
		add	bl, 'A'
		push	bx
		mov	si, sp		; ds:si <- null-term drive name
		clr	bx		; no private data
		call	FSDInitDrive
		pop	bx		; clear off drive letter
		pop	cx
		add	di, size CDROMDrive
		loop	createLoop
done:
		.leave
		ret
CDROMInitLocateDrives endp

;==============================================================================
;
;			 OPEN FILE TAKE-OVER
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMInitOpenFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all files in the open-file list that are on drives
		we manage and alter their private data and SFN to our
		liking.

CALLED BY:	CDROMInit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMInitOpenFiles proc	near
		.enter
		clr	bx			; process entire list
		mov	dx, ds:[fsdOffset]	; pass the offset of our
						;  FSDriver record
		mov	di, cs
		mov	si, offset CDRIOF_callback
		call	FileForEach
		.leave
		ret
CDROMInitOpenFiles endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDRIOF_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to initialize file handles that were
		opened with the skeleton FSD.

CALLED BY:	CDROMInitOpenFiles via FileForEach
PASS:		ds:bx	= HandleFile
		dx	= offset of our FSDriver record
RETURN:		carry set to end processing
DESTROYED:	ax, cx, bp, di, si, es may all be nuked

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDRIOF_callback	proc	far
		.enter
	;
	; See if the file handle is on one of our drives by checking if the
	; DSE_fsd field of the drive of the disk the file is on matches our
	; own.
	; 
		mov	si, ds:[bx].HF_disk
		tst	si		; device?
		jz	done		; yes => not our responsibility

		call	FSDLockInfoShared
		mov	es, ax
		mov	si, es:[si].DD_drive
		cmp	es:[si].DSE_fsd, dx
		call	FSDUnlockInfoShared
		jne	done

		mov	di, DR_DPFS_INIT_HANDLE
		call	CDROMCallPrimary
done:
		clc		; continue processing
		.leave
		ret
CDRIOF_callback	endp

Init		ends

;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
;
;			    EXIT HANDLING
;
;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down our interaction with MSCDEX

CALLED BY:	DR_EXIT
PASS:		nothing
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMExit	proc	far
		uses	es, di, ax
		.enter
		segmov	es, dgroup, ax
		tst	es:[cdromOldInt24].segment
		jz	done		; => didn't get as far as intercepting
					;  it
		mov	di, offset cdromOldInt24
		mov	ax, CRITICAL_VECTOR
		call	SysResetInterrupt
done:
		clc
		.leave
		ret
CDROMExit	endp

Resident	ends
