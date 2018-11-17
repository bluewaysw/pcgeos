COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fsdInit.asm

AUTHOR:		Adam de Boor, Oct 17, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/17/91	Initial revision


DESCRIPTION:
	Initialization code for FSD module
		

	$Id: fsdInit.asm,v 1.3 98/01/24 22:29:00 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include kernelGlobal.def


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Int21Intercept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special intercept to prevent context switches while
		TSR's or networks are in DOS.

CALLED BY:	int 21h
PASS:		?
RETURN:		?
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment

I21IFrame struct
    I21IF_bp	word
    I21IF_ax	word
    I21IF_retf	fptr.far
    I21IF_flags	CPUFlags
I21IFrame ends

Int21Intercept	proc	far
	call	SysEnterCritical
	; push the flags originally passed to us so interrupts are in the
	; right state when DOS returns to us.
	push	ax
	push	bp
	mov	bp, sp
	mov	ax, ss:[bp].I21IF_flags
	; Turn off the trap flag while in DOS
SSP <	andnf	ax, not mask CPU_TRAP			>
	xchg	ax, ss:[bp].I21IF_ax
	pop	bp
SSP <	call	SaveAndDisableSingleStepping		>
	call	cs:[dosAddr]
SSP <	call	RestoreSingleStepping			>
	call	SysExitCritical
	ret	2	; return flags from DOS, not from entry!
Int21Intercept	endp

idata	ends

kinit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the FSD module

CALLED BY:	InitGeos
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFSD		proc	near
		.enter

	;
	; initialize the skeleton file system driver to point to our internal
	; driver.
	;
	; Can't do MemDerefES here, as the FSInfoResource block isn't locked.
	; I don't know why we don't lock it here, though...
	;
		mov	bx, handle FSInfoResource
		mov	es, ds:[bx].HM_addr

		assume	es:FSInfoResource
if	FULL_EXECUTE_IN_PLACE
		mov	es:[fileSkeletonDriver].FSD_strategy.offset,
				offset FSDSStrategyStub
		mov	es:[fileSkeletonDriver].FSD_strategy.segment,
				segment FSDSStrategyStub
else
		mov	es:[fileSkeletonDriver].FSD_strategy.offset,
				offset FSDSStrategy
		mov	es:[fileSkeletonDriver].FSD_strategy.segment, cs
endif
	;
	; Extract the address of DOS for use by Int21. (a) it's
	; faster and (b) it allows an application to field int 21's for a
	; DOS application if the thing is "well-behaved". We'll see if it
	; ever happens.
	;
		segmov	es, ds
		mov	di, offset dosAddr	;place to store old vector
		mov	bx, ds
		mov	cx, offset Int21Intercept
		mov	ax, 21h
		call	SysCatchInterrupt

	;
	; Fetch the DOS version so we know what primary FS driver to load in
	; LoadFSDriver, and to deal with various version dependencies
	; throughout this module.
	; 
		mov	ax, MSDOS_GET_VERSION shl 8	; al = 0 so we know if
							;  DOS is < 2.0...
		int	21h
		mov	ds:[dosVersion], ax
		mov	ds:[oemSerialNum.low], cx
		mov	ds:[oemSerialNum.high], bx

	;
	; See if we're running in a Windows NT box...
	;
		cmp	ax, 5
		jne	notNT
		mov	ax, 3306h	;  DOS 5+ - GET TRUE VERSION
		int	21h
		cmp	bx, 3205h 	; WINNT will always return ver 5.50
		jne	notNT
		mov	ds:[isWINNT], BB_TRUE		
notNT:	
	
	;
	; See if we're running under DRDOS...
	; 
		mov	ax, DRDOS_GET_VERSION
		int	21h
		jc	done
		cmp	ax, DVER_3_41
		je	10$
		cmp	ax, DVER_5_0
		je	10$
		cmp	ax, DVER_3_40
		je	10$
		cmp	ax, DVER_6_0
		je	10$
done:
		.leave
		ret
10$:
	;
	; Flag this as a supported version of DR-DOS.
	;
		mov	ds:[isDRDOS], BB_TRUE
		jmp	done
InitFSD		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadFSDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the appropriate FS driver for the operating system
		being used.

CALLED BY:	InitGeos
PASS:		nothing
RETURN:		only if driver successfully loaded
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
fsDrivers	nptr	\
	dos3Name,
	dos4Name,
	dos4Name,	;DOS 5 is same as DOS 4
	dos4Name,	;DOS 6 is same as DOS 4
	dos4Name,	;DOS 7 is Win95 - compatible with DOS 4
	dos4Name,	;DOS 8 is Win98 / ME
	ntfatName	;DOS 9 is WinNT FAT - similar to OS/2
	
EC <LocalDefNLString dos3Name 	<'ms3ec.geo',0>				>
EC <LocalDefNLString dos4Name 	<'ms4ec.geo',0>				>
EC <LocalDefNLString drdosName 	<'driec.geo',0>				>
EC <LocalDefNLString os2Name 	<'os2ec.geo',0>				>
EC <LocalDefNLString ntfatName	<'ntfatec.geo',0>			>
NEC <LocalDefNLString dos3Name 	<'ms3.geo',0>				>
NEC <LocalDefNLString dos4Name 	<'ms4.geo',0>				>
NEC <LocalDefNLString drdosName <'dri.geo',0>				>
NEC <LocalDefNLString os2Name 	<'os2.geo',0>				>
NEC <LocalDefNLString ntfatName	<'ntfat.geo',0>				>

;
; 1/19/98: DOS 7 is Win95's version of DOS which supports longnames.
; There is/was a version of a GEOS driver under development for it,
; but it was never completed, at least not to be general purpose
; for the desktop.  It is backwards compatible with DOS 4. -- eca
;

secondaries	nptr	FSDAutoLoadNetWare, FSDAutoLoadMSNet, FSDAutoLoadCDROM
LoadFSDriver	proc	near	uses es
		uses	ds, es
		
		.enter
	;
	; Call the DR_INIT function of the skeleton driver to do what it needs
	; to, e.g. to create file handles for us and for the .ini file...
	; This is a bit ass-backwards, as the skeleton driver will have
	; long-since been used to create disks for the drives in the various
	; standard paths, but the DR_INIT function of the skeleton is
	; a convenient place to have this functionality, and it can't do what
	; it needs to do until those disk descriptors have been made.
	; 
		call	FileLockInfoSharedToES
		mov	di, DR_INIT
		call	es:[fileSkeletonDriver].FSD_strategy
		call	FSDUnlockInfoShared

if	BACKUP_AND_RESTORE_INI_FILE

;	Now that we have a file handle associated with the .ini file,
;	validate the .ini file. If it is OK, then back it up. If it
;	isn't, then restore from the last saved backup
	
		push	bx, ds
		LoadVarSeg	ds	
		mov	bx, ds:[loaderVars].KLV_initFileBufHan
		mov	cx, ds:[loaderVars].KLV_initFileSize
		dec	cx		;Ignore EOF
		call	MemLock
		mov	ds, ax
		call	ValidateIniFileFar
		call	MemUnlock
		pop	bx, ds
		jnc	fileIsOK

;	The file is trashed - try to restore from the last saved version.

		call	InitFileRevert
		jmp	continue

fileIsOK:

;	The file is in good shape - save a backup copy

		call	InitFileSave

continue:
endif

;;
;; If we don't want to automatically load fs drivers based on version
;; number, then don't.  Only load based on .ini file.
;;
	;
	; Check ini key to see if the user explicitly tells us the
	; primary FSD or if we should load one based on version number.
	; If the key is set, but the geode can't be loaded, the kernel
	; won't revert to autoloading based on dos version number.
	;
if	PRIMARY_FSD_FOUND_IN_INITFILE
		LoadVarSeg	ds, bx
		mov	dx, offset primaryFSDString
		call	GetSystemString
		jnc	loadDriverHaveDS
endif	; PRIMARY_FSD_FOUND_IN_INTIFILE

	;
	; Find version number.
	;
		LoadVarSeg	ds,bx
		mov	si, offset drdosName
		tst	ds:[isDRDOS]
		jnz	loadDriver

		mov	si, offset ntfatName
		tst	ds:[isWINNT]
		jnz	loadDriver

 		mov	bl, ds:dosVersion.low
 		clr	bh

		mov	si, offset os2Name
		cmp	bl, 20			; OS/2?
		je	loadDriver

		mov	ds:exitFlags, mask EF_OLD_EXIT	; Must use old exit
		sub	bx, 3				;  function if < 2.X
		ERROR_B	UNSUPPORTED_DOS_VERSION
		mov	ds:exitFlags, 0

		cmp	bx, length fsDrivers
ifdef GPC_ONLY
		jae	loadIniDrivers		; assume primary defined in
						;  .ini file instead.
else
		jb	checkTable
		mov	si, offset dos4Name	;si <- default to ms4.geo
		jmp	loadDriver
checkTable:
endif

	;
	; Load the appropriate driver, passing PSP in CX to DR_INIT
	; 
		shl	bx
		mov	si, cs:fsDrivers[bx]
	;
	; Check for an unsupported DOS version
	;
		tst	si			; empty entry?
		jz	loadIniDrivers		; branch if so

loadDriver:
		mov	di, ds:[loaderVars].KLV_pspSegment ; this is useless
		segmov	ds, cs
loadDriverHaveDS::
		mov	ax, SP_FILE_SYSTEM_DRIVERS
		mov	cx, FS_PROTO_MAJOR
		mov	dx, FS_PROTO_MINOR
		call	LoadDriver		; does LoadVarSeg for DS
		
		jc	loadIniDrivers		; assume real primary defined
						;  in .ini file instead
	;
	; Save the handle as the primary FSD.
	; 
		mov	ds:[defaultDrivers].DDT_fileSystem, bx
loadIniDrivers:
	;
	; Now load the FS drivers defined in the system::fs key in the ini
	; file.
	; 
		mov	dx, offset fsDrvString
		clr	bp
		call	GetSystemString
		jc	checkSecondaries	; => key non-existent
		
		mov	di, SP_FILE_SYSTEM_DRIVERS
		mov	cx, FS_PROTO_MAJOR
		mov	dx, FS_PROTO_MINOR
		call	ProcessStartupList
		
		call	DoneWithString

checkSecondaries:
if AUTO_SEARCH_FOR_SECONDARIES
	;
	; Now load any secondary IFS drivers for which we've unwisely built-in
	; detection. Currently, this means:
	; 	- Novell NetWare
	; 	- Microsoft Network-compatible (LANtastic et al)
	; 	- CD-ROM
	; 
		mov	si, offset secondaries
		mov	cx, length secondaries
secondaryLoop:
		call	{nptr.near}cs:[si]
		inc	si
		inc	si
		loop	secondaryLoop

	;
	; Now let the IFS drivers know the names of any files they've inherited,
	; so they can determine the 32-bit ID so they know the darn things are
	; in-use.
	; 
		clr	bx		; process the whole list
		mov	di, SEGMENT_CS
		mov	si, offset LFSD_callback
		call	FileForEach
endif ; AUTO_SEARCH_FOR_SECONDARIES

if MULTI_LANGUAGE
	; Indicate that the full driver has been loaded.

		LoadVarSeg	ds
		mov	ds:[fullFileSystemDriverLoaded], TRUE
endif

done::
		.leave
		ret
LoadFSDriver	endp

fsDrvString	char	'fs', 0
if	PRIMARY_FSD_FOUND_IN_INITFILE
primaryFSDString char	'primaryFSD', 0
endif	; PRIMARY_FSD_FOUND_IN_INITFILE

if AUTO_SEARCH_FOR_SECONDARIES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDAutoLoadNetWare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if Novell NetWare is present and load its driver if so.

CALLED BY:	LoadFSDriver
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, dx, ds, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString nwName	<'netwaree.geo',0>			>
NEC <LocalDefNLString nwName	<'netware.geo',0>			>

NFC_GET_DRIVE_FLAG_TABLE equ 0xEF01

FSDAutoLoadNetWare proc	near
		uses	cx, si
		.enter
	;
	; call to get the drive flag table.  Look at the return value to
	; figure out whether netware is actually running
	;
		mov	si, 0xffff		;bogus offset
		mov	ax, NFC_GET_DRIVE_FLAG_TABLE
EC <		push	es	; avoid ec +segment death	>
		call	FileInt21		;es:si = drive flag table
EC <		pop	es					>
		cmp	si, 0xffff
		je	done
	;
	; It certainly seems to be present. Load the driver.
	; 
		mov	ax, SP_FILE_SYSTEM_DRIVERS
		mov	cx, FS_PROTO_MAJOR
		mov	dx, FS_PROTO_MINOR
		segmov	ds, cs
		mov	si, offset nwName
		call	LoadDriver
done:
		.leave
		ret
FSDAutoLoadNetWare endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDAutoLoadMSNet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if an MS-Net compatible network is running and load
		its driver if so.

CALLED BY:	LoadFSDriver
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, dx, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString msnetName	<'msnetec.geo',0>			>
NEC <LocalDefNLString msnetName	<'msnet.geo',0>				>
FSDAutoLoadMSNet proc	near
		uses	cx, si
		.enter
	;
	; Get the machine name. If no ms-net running, this should return an
	; error (ERROR_UNSUPPORTED_FUNCTION, to be precise)
	; NetWare returns 16 blanks for this call, so this isn't a definitive
	; test. 
	; 
		LoadVarSeg	ds, cx
		cmp	ds:[dosVersion].low, 3	; int 2fh not around before 3.0
		jb	done
		mov	ax, MSNET_EXISTENCE_CHECK
		int	2fh
		tst	al		; still 0?
		jz	done		; yes -- not installed
		test	bl, mask MSNIF_REDIRECTOR or mask MSNIF_SERVER
		jz	done
	;
	; Network appears to be running. Load the driver
	; 
		mov	ax, SP_FILE_SYSTEM_DRIVERS
		mov	cx, FS_PROTO_MAJOR
		mov	dx, FS_PROTO_MINOR
		segmov	ds, cs
		mov	si, offset msnetName
		call	LoadDriver
done:
		.leave
		ret
FSDAutoLoadMSNet endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDAutoLoadCDROM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a CD-ROM drive is active and load its driver if so.

CALLED BY:	LoadFSDriver
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, dx, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString cdromName	<'cdromec.geo',0>			>
NEC <LocalDefNLString cdromName	<'cdrom.geo',0>				>
FSDAutoLoadCDROM proc	near
		uses	cx, si
		.enter
		LoadVarSeg	ds, cx
		cmp	ds:[dosVersion].low, 3	; int 3fh not around before 3.0
		jb	done

		clr	bx		; avoid conflict with GRAPHICS.COM
		mov	ax, CDROM_GET_STATUS
		int	2fh
		tst	bx
		jz	done
	;
	; CD-ROM Extensions appear to be loaded. Load the driver
	; 
		mov	ax, SP_FILE_SYSTEM_DRIVERS
		mov	cx, FS_PROTO_MAJOR
		mov	dx, FS_PROTO_MINOR
		segmov	ds, cs
		mov	si, offset cdromName
		call	LoadDriver
done:
		.leave
		ret
FSDAutoLoadCDROM endp

endif ; AUTO_SEARCH_FOR_SECONDARIES




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFSD_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to determine the name of the passed file
		and tell the filesystem driver about it.,

CALLED BY:	LoadFSDriver via FileForEach
PASS:		ds:bx	= HandleFile to look at
RETURN:		carry set to stop enumerating.
DESTROYED:	ax, cx, dx, bp, di, si, es all allowed
SIDE EFFECTS:	not a whole lot that's visible.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
iniSuffix	char	'INI', 0
geoSuffix	char	'GEO', 0
geosIniPermName	char	'GEOS'
		char	(GEODE_NAME_SIZE - length geosIniPermName) dup (' ')

LFSD_callback	proc	far
if DBCS_PCGEOS
tail		local	DOS_DOT_FILE_NAME_LENGTH_ZT dup(wchar)
else
tail		local	DOS_DOT_FILE_NAME_LENGTH_ZT dup(char)
endif
path		local	PathName
		uses	ds
		.enter
			CheckHack <FA_READ_ONLY eq 0>
		test	ds:[bx].HF_accessFlags, mask FAF_MODE
		jz	mustBeGeode
	;
	; The only read/write file open at this point is the ini file...
	; 
		mov	cx, cs
		mov	dx, offset geosIniPermName
		mov	si, offset iniSuffix
		mov	ax, SP_TOP
		jmp	constructTail

mustBeGeode:
	;
	; Lock down the owner's core block and point cx:dx to its permanent
	; name.
	; 
		push	bx, ds
		mov	bx, ds:[bx].HM_owner
		call	MemLock
		mov	ds, ax
		mov_tr	cx, ax
		mov	dx, offset GH_geodeName	; cx:dx <- permanent name
		mov	si, offset geoSuffix	; cs:si <- suffix to use
	;
	; If the thing is a driver, it must be a filesystem driver. Anything
	; else must be the kernel, which resides in SP_SYSTEM.
	;
		test	ds:[GH_geodeAttr], mask GA_DRIVER
		pop	bx, ds
		mov	ax, SP_SYSTEM
		jz	constructTail
		mov	ax, SP_FILE_SYSTEM_DRIVERS
constructTail:
	;
	; cx:dx	= source permanent name
	; cs:si	= suffix to append
	; ax	= StandardPath in which to find the thing
	; 
		push	bx
		push	ds
		push	ax
		push	si
	;
	; First build the name of the file itself. Want the permanent name,
	; without
	; 
		segmov	es, ss
		lea	di, ss:[tail]
		movdw	dssi, cxdx
		clr	bx
DBCS <		clr	ah						>	
		mov	cx, GEODE_NAME_SIZE
copyNameLoop:
		lodsb
		cmp	al, ' '
		jne	notSpace
		tst	bx
		jnz	storeNameChar	; already marking start of space range
		mov	bx, di		; remember this place
		jmp	storeNameChar
notSpace:
		clr	bx		; hit non-space, so close out previous
					;  space run, if such there were
storeNameChar:
		LocalPutChar esdi, ax
		loop	copyNameLoop
		
		tst	bx
		jz	appendSuffix
		mov	di, bx		; back up to first trailing space
appendSuffix:
EC <		lea	ax, ss:[tail]					>
EC <		sub	ax, di						>
if DBCS_PCGEOS
EC <		cmp	ax, -GEODE_NAME_SIZE*2	; all chars used?	>
EC <		je	ecAppended		; yes, no room for ec	>
EC <		cmp	ax, -(GEODE_NAME_SIZE-1)*2; all but one used?	>
EC <		mov	ax, 'e'						>
EC <		stosw							>
EC <		je	ecAppended		; yes, no room for c	>
EC <		mov	ax, 'c'						>
EC <		stosw							>
EC <ecAppended:								>
else
EC <		cmp	ax, -GEODE_NAME_SIZE	; all chars used?	>
EC <		je	ecAppended		; yes, no room for ec	>
EC <		cmp	ax, -(GEODE_NAME_SIZE-1); all but one used?	>
EC <		mov	al, 'e'						>
EC <		stosb							>
EC <		je	ecAppended		; yes, no room for c	>
EC <		mov	al, 'c'						>
EC <		stosb							>
EC <ecAppended:								>
endif
		pop	si
		mov	ax, cs
		mov	bx, ds
		cmp	ax, bx
		je	coreBlockUnlocked
		mov	bx, ds:[GH_geodeHandle]
		call	MemUnlock
coreBlockUnlocked:
if DBCS_PCGEOS
		mov	ax, '.'
		stosw
		segmov	ds, cs
		mov	cx, (length geoSuffix)
suffixLoop:
		lodsb
		stosw
		loop	suffixLoop
else
		mov	al, '.'
		stosb
		movsw	cs:
		movsw	cs:
endif
	;
	; Now build the full path for the thing.
	; 
		segmov	ds, ss
		lea	dx, ss:[tail]
		lea	di, ss:[path]
		mov	cx, size path
		
		pop	ax
		call	FileSetStandardPath
		clr	ax		; no drive name needed, and please do
					;  look for the file...
		call	FileResolveStandardPath
		
	;
	; Now communicate this information to the FSD responsible for the file.
	; 
		pop	ds
		pop	bx
		call	FileLockInfoSharedToES
		mov	si, ds:[bx].HF_disk
		mov	di, DR_FS_HANDLE_OP
		segmov	ds, ss
		lea	dx, ss:[path]
		mov	ax, (FSHOF_SET_FILE_NAME shl 8) or FILE_NO_ERRORS
		push	bp
		call	DiskLockCallFSD
		pop	bp
		call	FSDUnlockInfoShared

		clc		; continue enumerating, please.
		.leave
		ret
LFSD_callback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDInitComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialization of the kernel is complete. We now need to
		make sure no drives are being run by the skeleton driver,
		or if any are, that no files are open to those drives.

		If there are any files open to drives run by the skeleton
		driver, we panic, as we won't be able to deal with them.

CALLED BY:	InitGeos
PASS:		ds	= dgroup
RETURN:		only if all drives are kosher.
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Should ensure init file handle and kernel file handle have
		geos file handles.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDInitComplete	proc	near
		.enter
	;
	; Make sure no file is open to a drive managed by the skeleton driver.
	; 
		clr	bx
		mov	di, SEGMENT_CS
		mov	si, offset FSDIC_callback
		call	FileForEach
		jnc	filesOK
panic:
		mov	ax, SST_DIRTY
		mov	si, offset messageBuffer	; ds:si <- message
		jmp	SysShutdown
filesOK:
	;
	; Now remove any drives managed by the skeleton driver.
	; 
		call	FSDLockInfoShared
		mov	es, ax
		mov	si, offset FIH_driveList-offset DSE_next
driveLoop:
		mov	bx, es:[si].DSE_next	; es:bx <- next drive
		tst	bx			; end of list?
		jz	ensurePrimary		; yup -- everything's cool
		
		mov	di, es:[bx].DSE_fsd
		test	es:[di].FSD_flags, mask FSDF_SKELETON
		jnz	nukeDrive
		
		mov	si, bx			; not skeleton, so this drive
						;  can stay. Advance SI along
						;  the chain...
		jmp	driveLoop

ensurePrimary:
	;
	; Make sure we actually loaded a primary filesystem driver.
	; 
		cmp	es:[FIH_primaryFSD], offset fileSkeletonDriver
		jne	done
		
		mov	al, KS_PRIMARY_FSD_NOT_LOADED
		call	AddStringAtMessageBufferFar
		jmp	unlockPanic
done:
		call	FSDUnlockInfoShared
		.leave
		ret
nukeDrive:
	;
	; Use the external interface to delete the drive, as it takes care of
	; checking for active disk handles open to the drive, etc.
	; 
		mov	al, es:[bx].DSE_number
		call	FSDUnlockInfoShared
		call	FSDDeleteDrive
	;
	; Re-lock the FSIR so we can continue our traversal.
	; 
		pushf
		call	FSDLockInfoShared
		mov	es, ax
		popf
		jnc	driveLoop

		call	FSDInitDriverNotLoaded
unlockPanic:
		call	FSDUnlockInfoShared
		jmp	panic
FSDInitComplete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDIC_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to determine if any file is open to a
		drive that's managed by the skeleton driver.

CALLED BY:	FSDInitComplete via FileForEach
PASS:		bx	= handle of file to process
		ds	= dgroup
RETURN:		carry set if file on drive managed by skeleton FSD
DESTROYED:	ax, cx, dx, bp, di, si, es all allowed

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDIC_callback	proc	far
		uses	bx
		.enter
		mov	si, ds:[bx].HF_disk
		tst	si		; device?
		jz	done		; yes -- we're ok.

		call	FSDLockInfoShared
		mov	es, ax
		mov	bx, es:[si].DD_drive
		mov	si, es:[bx].DSE_fsd
		test	es:[si].FSD_flags, mask FSDF_SKELETON
		jnz	deathDeathDeath
unlock:
		call	FSDUnlockInfoShared
done:
		.leave
		ret
deathDeathDeath:
	;
	; Set appropriate message into messageBuffer
	; 
		call	FSDInitDriverNotLoaded
	;
	; And return carry set to indicate our displeasure.
	; 
		stc
		jmp	unlock
FSDIC_callback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDInitDriverNotLoaded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a message indicating the the FSD for the passed
		drive isn't loaded.

CALLED BY:	FSDIC_callback, FSDInitComplete
PASS:		es:bx	= DriveStatusEntry for which FSD is missing.
RETURN:		messageBuffer filled
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDInitDriverNotLoaded proc near
		uses	es, ds, si
		.enter
		segmov	ds, es
	;
	; Store first part of the message, returning us ES:DI set for more
	; storing.
	; 
		mov	al, KS_FILE_SYSTEM_DRIVER_FOR_DRIVE
		call	AddStringAtMessageBufferFar
	;
	; Now copy the null-terminated drive name into the buffer over the null.
	; 
		lea	si, ds:[bx].DSE_name
driveNameLoop:
		LocalGetChar ax, dssi
		LocalPutChar esdi, ax
		LocalIsNull ax
		jnz	driveNameLoop
	;
	; Finally, copy the second part of the message.
	; 
		LocalPrevChar esdi
		mov	al, KS_NOT_LOADED
		call	AddStringAtESDIFar
		.leave
		ret
FSDInitDriverNotLoaded endp

kinit	ends


DosapplCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore our world after a suspend.  In particular, re-insert
		the Int 21 handler.

CALLED BY:	DosExecUnsuspend
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDUnsuspend		proc	near
		uses	es, di, bx, cx, ax
		.enter

		segmov	es, dgroup, ax
		mov	di, offset dosAddr	;place to store old vector
		mov	bx, es
		mov	cx, offset Int21Intercept
		mov	ax, 21h
		call	SysCatchInterrupt

		.leave
		ret
FSDUnsuspend		endp

DosapplCode	ends



FSResident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the FS ready to be suspended.  In particular, restore the
		Int 21 handler.

CALLED BY:	DosExecSuspend
PASS:		ds 	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSuspend		proc	far
		uses	ax, di, es, ds
		.enter

		segmov	ds, dgroup, ax
		call	ResetInt21

		.leave
		ret
FSDSuspend		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore things to as they were before InitFSD was called

CALLED BY:	EndGeos
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	es, ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/23/92		Initial version
	dloft	11/24/93	Moved code to ResetInt21, so as to share with
				FSDSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExitFSD		proc	far
	; restore the old INT 21h vector, making sure it still points to us.
	; not performing this check leads us into trouble. e.g. if one
	; detaches from Swat, Swat will replace the vector we changed
	; with the real DOS handler. Our stuffing Swat's vector back in again
	; leads to much unhappiness.
	;
	; 6/13/91: changed back to just reset int 21h as Swat has changed to
	; always intercept int 21h until the very last moment. things were
	; getting royally screwed up if you attached after geos was running,
	; but stayed attached while geos exited, as int 21h would end up
	; pointing to Int21Intercept again... -- ardeb
	
	call	ResetInt21
	ret
ExitFSD		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetInt21
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls SysResetInterrupt, restoring dosAddr as the handler.

CALLED BY:	INTERNAL	ExitFSD, FSDSuspend
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	es, ax, di

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetInt21		proc	near
		.enter

		segmov	es, ds
		mov	di, offset dosAddr
		mov	ax, 21h
		call	SysResetInterrupt

		.leave
		ret
ResetInt21		endp

FSResident	ends
