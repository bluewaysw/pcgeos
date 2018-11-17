COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		driInitExit.asm

AUTHOR:		Adam de Boor, Oct 30, 1991

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/30/91	Initial revision


DESCRIPTION:
	Functions to initialize and exit the driver.


	$Id: msInitExit.asm,v 1.1 97/04/10 11:55:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSInit
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
			* count max # files we can open and change PSP
			  accordingly so DR DOS lets us open that many
			* for each used slot in the JFT, create a file handle
			  for it in the kernel, then free the JFT slot

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSInit		proc	far
		.enter
		segmov	ds, dgroup, ax
		mov	ah, MSDOS_GET_PSP
		int	21h

		mov	ds:[pspSegment], bx	; save PSP

	;
	; Record version under which we're operating. 
	; 
		mov	ah, MSDOS_GET_VERSION
		int	21h
		mov	{word}ds:[dosVersionMajor], ax
		ForceRef	dosVersionMinor
	;
	; See if this is the right version of DOS
	; Code pages are not supported for DOS < 3.30
	;
if _MS3
		xchg	al, ah			;swap major, minor #s
		cmp	ax, 0x031E		;code pages not supported
		mov	ax, CODE_PAGE_US
		jb	haveCodePage		;  for DOS versions < 3.30
endif
	;
	; Get the current DOS code page and tell the kernel about it.
	;
		mov	ax, (MSDOS_SELECT_CODE_PAGE shl 8) or 1
		int	21h
forceCodePage:
		mov	ax, CODE_PAGE_US	; assume US...
		jc	haveCodePage		;  ...on error
		mov_tr	ax, bx			; ax <- active code page
haveCodePage:
SBCS <		call	LocalSetCodePage				>
		jc	forceCodePage		;  ...on error
		call	DOSInitUseCodePage
;;registerDriver:	

	;
	; Register with the kernel.
	;
		mov	cx, segment DOSStrategy
		mov	dx, offset DOSStrategy
		mov	ax, FSD_FLAGS
		mov	bx, handle 0
		clr	di			; no private data set for disks
		call	FSDRegister
		mov	ds:[fsdOffset], dx

		call	DOSHookCriticalError

if	DEBUG_BOOT_SECTOR_CALLS
		mov	ax, 13h			; vector # to catch
		mov	bx, ds			; bx:cx = handler routine
		mov	cx, offset DebugBootSectorCalls
		segmov	es, ds			; es:di = place to store old
		mov	di, offset int13Save
		call	SysCatchInterrupt
endif

	;
	; Allocate initial boot sector buffer in case we have to ID any floppy
	; disks during the creation of the drive table (as happens on Poqet
	; machines, for example).
	; 
		mov	ax, MSDOS_STD_SECTOR_SIZE
		call	MSInitSetMaxSectorSize

		call	MSLocateDrives

if	SEND_DOCUMENT_FCN_ONLY
ifdef	GPC
EC <		segmov	es, NULL_SEGMENT	; avoid ec +segment death (es >
EC <						;  is CWD table)	      >
		call	DOSInitEnhancedModeFlag
endif	; GPC
endif	; SEND_DOCUMENT_FCN_ONLY

		call	MSLocateFileTable
EC <		segmov	es, ds	; avoid ec +segment death (es is PSP) >
		call	DOSInitOpenFiles
		
	;
	; Turn on wait/post support, if appropriate.
	; 
		call	DOSWaitPostInit

	;
	; Locate the NUL device so we can map device names properly.
	; 
		call	DOSInitNullDevicePointer
	;
	; Enable idle-time hook.
	; 
		call	DOSIdleInit

if SEND_DOCUMENT_FCN_ONLY
		call	DOSInitRecordDocPaths
endif	; SEND_DOCUMENT_FCN_ONLY
		
		dec	ds:[dosPreventCritical]

		clc
		.leave
		ret
MSInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSInitSetMaxSectorSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the size of the largest sector known, enlarging the
		boot sector buffer if necessary.

CALLED BY:	MSInit, MSInitAllocDrive
PASS:		ax	= potential new maximum
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSInitSetMaxSectorSize proc near
		uses	bx
		.enter
		cmp	ax, ds:[maxSector]
		jbe	done
		
EC <		push	es						>
EC <		segmov	es, ds		; avoid ec +segment death	>

		mov	ds:[maxSector], ax
		mov	bx, ds:[bootSectorHandle]
		tst	bx
		jz	allocNewBuffer
		call	MemFree
allocNewBuffer:
		call	DOSAllocateSectorBuffer
		mov	ds:[bootSector], ax
		mov	ds:[bootSectorHandle], bx

EC <		pop	es						>
done:
		.leave
		ret
MSInitSetMaxSectorSize endp

;==============================================================================
;
;			    DRIVE LOCATION
;
;==============================================================================

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSFetchCWDTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate and return the table of current directories, aka
		the logical drive table. Perform consistency checks to
		ensure we can actually use it.

CALLED BY:	MSLocateDrives
PASS:		ds	= dgroup
RETURN:		carry set if CDT is unusable
		carry clear if it's ok:
			es:di	= start of the table
			cx	= number of entries in the table.
			ds:[driveTable] set to base of LDT
		ds:[firstDCB] set to the first DCB in the chain in either
			case.
DESTROYED:	ax, bx, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSFetchCWDTable proc	near
		.enter
	;
	; Fetch the length and start of the CD table
	;
		mov	ah, MSDOS_GET_DOS_TABLES
		int	21h
		mov	ax, es:[bx].DLOL_DCB.offset
		mov	ds:[firstDCB].offset, ax
		mov	ax, es:[bx].DLOL_DCB.segment
		mov	ds:[firstDCB].segment, ax

		clr	cx
if _MS3
		tst	ds:[dosVersionMinor]
		jnz	not3_0
		mov	cl, es:[bx].D3LOL_lastDrive
		les	di, es:[bx].D3LOL_CWDs
		jmp	haveCWD
not3_0:
endif
		mov	cl, es:[bx].DLOL_lastDrive
		les	di, es:[bx].DLOL_CWDs
if _MS3
haveCWD:
endif
		mov	ds:[driveTable].offset, di
		mov	ds:[driveTable].segment, es
	;
	; Make sure the thing makes sense.
	;
		mov	ax, es
		dec	ax			; -1?
		jz	useDCBs			; yes -- no existee
		inc	ax			; 0?
		jz	useDCBs			; yes -- no existee

		lea	si, es:[di].CD_path	; make sure all bytes up
						;  to null terminator of the
						;  path for the first drive are
						;  ascii chars
		lodsb	es:			; check first char separately
		cmp	al, '\\'		; network drive?
		je	checkLoop
		cmp	al, 'A'			; drive letter?
		jb	useDCBs
		cmp	al, 'Z'
		ja	useDCBs
checkLoop:
		lodsb	es:
		tst	al		; (clears carry)
		jz	done
;XXX: THESE COMPARISONS ARE BOGUS, BUT I THINK LocalIsDosChar IS OUT UNLESS
;ALL CODE PAGE RESOURCES ARE PRELOADED.
		cmp	al, ' '
		jbe	useDCBs
		cmp	al, 0x7f
		jb	checkLoop
useDCBs:
		stc			; indicate our displeasure
		mov	ds:[driveTable].segment, 0
done::
		.leave
		ret
MSFetchCWDTable endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLocateDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all the drives we can manage. Ideally this would
		rely less on internal DOS data structures, but they've
		not made it easy on us. There exists only one function
		(undocumented, of course) that might be of help, AH=32h,
		except that for drives whose device control block is marked
		invalid, the damn thing actually goes to the drive to
		do God only knows what, which we can't allow.

CALLED BY:	MSInit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We should use the MSDOS_GET_LOGICAL_DRIVE_MAP to detect
		aliases, allocate a private data chunk for the drive that
		points to the other drive mapped, then call
		MSDOS_SET_LOGICAL_DRIVE_MAP before issuing a call, if the
		drive wasn't the last one accessed. Our own disk-tracking
		logic should properly deal with getting the desired disk
		in the drive.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLocateDrives proc	near
		.enter
		call	MSFetchCWDTable
		jc	useDCBs
	;
	; Loop over all of them:
	; 	bx	= drive #
	; 	es:di	= current CurrentDirectory
	; 	cx	= # entries left to process
	; 	ax	= junk
	;
		clr	bx		; start w/drive #0
cdLoop:
	    ;
	    ; Skip any substituted or joined drives -- we can't handle
	    ; them yet, so they don't exist.
	    ; XXX: Use DES_ALIAS when it's supported.
	    ;
		mov	ax, es:[di].CD_status

		test 	ax, mask CDS_SUBST or mask CDS_JOINED
		jnz	next

		test	ax, mask CDS_NETWORK
		jnz	next		; handled by msnet driver

		test	ax, mask CDS_LOCAL
		jz	next

		push	es, bx, cx
		les	bx, es:[di].CD_DCB
		call	MSCreateDriveFromDCB
		pop	es, bx, cx
next:
		add	di, size CurrentDirectory
		inc	bx
		loop	cdLoop
done:
		.leave
		ret

	;--------------------
	; Logical drive table isn't reliable, so just initialize the drive
	; map from the chain of Device Control Blocks.
	;
useDCBs:
		les	bx, ds:[firstDCB]
dcbLoop:
		call	MSCreateDriveFromDCB
		les	bx, es:[bx].DCB_nextDCB
		cmp	bx, -1
		jne	dcbLoop
		jmp	done
MSLocateDrives endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCreateDriveFromDCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a drive entry given the drive's DeviceControlBlock

CALLED BY:	MSLocateDrives
PASS:		es:bx	= DeviceControlBlock
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, si

PSEUDO CODE/STRATEGY:
	    if the media field indicates the drive is fixed
	    	trust it
	    else
	    	see if device driver thinks the media are removable
		if not, declare the disk fixed
		else if the device driver supports generic ioctls
		    fetch the device parameters
		    map the returned media byte to our own media byte and
		    record the drive as using a removable media
    	    	else
		    use the media byte in the DCB to call the BUILD_BPB
		    function of the driver
		    if successful, use the BPB to figure the type of drive
		    else declare drive missing...?



KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCreateDriveFromDCB proc	near
		.enter

	;
	; Get logical drive number (as opposed to physical drive number)
	;
		mov	dl, es:[bx][DCB_drive]

	; edigeron 3/15/01
	; According to the comp.os.msdos.programmer FAQ, if I check the
	; BIOS equipment byte at 0040:0010, bits 7-6 will be one less than
	; the number of diskette drives. So, if those bits are 0, then we
	; don't have a B: drive.

		cmp	dl, 1
		jne	notBDrive
		push	es
		mov	ax, BIOS_DATA_SEG
		mov	es, ax
		test	es:[BIOS_EQUIPMENT], mask EC_NUM_FLOPPIES
		pop	es
		jz	done

notBDrive:
	;
	; First see if the media type is declared as fixed in the device
	; control block. If so, we assume it's there and waiting.
	;
		cmp	{byte}es:[bx].DCB_media, DOS_MEDIA_FIXED_DISK
		jne	probablyNotFixed
	;
	; 3/16/93: to cope with stacked floppies, where Stacker sets the
	; media type to be FIXED, we also consult with DOS using ioctls to
	; see what it thinks of the thing. -- ardeb
	; 
		call	MSFetchDeviceParams
		jc	isFixed		; => couldn't fetch, so assume fixed
		test	cx, mask DS_MEDIA_REMOVABLE
		jnz	createDrive	; => removable, so DCB has been messed
					;  with
isFixed:
		mov	cx, DRIVE_FIXED or mask DS_PRESENT
		mov	ax, MEDIA_FIXED_DISK shl 8
	;
	; If the device uses some sector size smaller than the standard, assume
	; it's a RAM disk...valid assumption?
	;
		cmp	es:[bx].DCB_sectorSize, MSDOS_STD_SECTOR_SIZE
		jae	createDrive
		mov	cx, DRIVE_RAM or mask DS_PRESENT
		jmp	createDrive

probablyNotFixed:
	;----------------------------------------------------------------------
	;see if the driver is reasonable
		cmp	es:[bx].DCB_deviceHeader.segment, 0
		jnz	haveDriver

	;
	; Assume bogus IBM ROM "drive" -- fixed, present drive of unknown format
	;
		mov	cx, DRIVE_RAM or mask DS_PRESENT or \
				mask DS_NETWORK
		mov	ax, MEDIA_FIXED_DISK shl 8	; no change line for
							; fixed disk
		jmp	createDrive

haveDriver:
	;
	;if driver supports Open/Close/Removable Media calls, we can just
	;call that function to see if the thing is fixed or floppy.
	;
		call	MSMediaRemovable?
		mov	cx, DRIVE_RAM or mask DS_PRESENT
		mov	ax, MEDIA_FIXED_DISK shl 8
		jnc	createDrive	; If not removable but not known as a
					;  fixed disk, it's probably a RAM disk.

	;
	; Fetch device parameters using generic IOCTL call, if driver supports
	; it.
	;
    		call	MSFetchDeviceParams
		jnc	createDrive

	;
	; No IOCTL -- Try the BIOS data area Drive/Media state variables
	; for drives 0 and 1, if this is one of those. Older BIOSes don't
	; support these variables, so we have to make sure they're reasonable.
	;
		call	MSCheckBIOSData
		jnc	createDrive

	;
	; No IOCTL, BIOS data unavailable -- use the value in the DCB. We
	; can't ask the driver to build a BPB as that can confuse the driver
	; and we're supposed to pass in the first sector of the FAT to that
	; call anyway, which we can't do if there's no disk in the drive. So we
	; rely on DOS's last judgment of the thing...
	;
		call	MSCheckDCB
		jnc	createDrive

			; call it fixed disk of unknown type. what the
			; heck.... -- ardeb 5/30/91
		mov	cx, DRIVE_UNKNOWN or mask DS_PRESENT
		mov	ax, MEDIA_FIXED_DISK shl 8

createDrive:
	;
	; cx	= DriveExtendedStatus
	; al	= DDPDFlags
	; ah	= MediaType
	; es:bx	= DeviceControlBlock
	; 
if PZ_PCGEOS
	;
	; if we've got a drive D: or E: that is MEDIA_1M2 or MEDIA_720,
	; convert it to MEDIA_1M232
	;
		push	dx
		mov	dl, es:[bx].DCB_drive
		cmp	dl, 3
		je	mightBe1M232
		cmp	dl, 4
		jne	not1M232
mightBe1M232:
		call	MSCheckFD12
		jne	not1M232
		cmp	ah, MEDIA_1M2
		je	is1M232
		cmp	ah, MEDIA_720K
		jne	not1M232
is1M232:
		mov	ah, MEDIA_1M232
		mov	cx, mask DES_FORMATTABLE or \
				((mask DS_PRESENT or \
				mask DS_MEDIA_REMOVABLE or \
				(DRIVE_3_5 shl offset DS_TYPE)) \
					shl offset DES_EXTERNAL)
not1M232:
		pop	dx
endif
		call	MSInitCheckMediaOverride
		jc	done		; => ignore drive

		call	MSInitAllocDrive
done:
		.leave
		ret
MSCreateDriveFromDCB endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCheckFD12
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for FD12.SYS

CALLED BY:	MSCreateDriveFromDCB
PASS:		dl	= logical drive
		DOS/BIOS grabbed
RETURN:		Z set if FD12.SYS
		Z clear if not
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if PZ_PCGEOS
MSCheckFD12	proc	near
	uses	es, ds, ax, bx, cx, dx, di, si
	.enter
	mov	ax, 0803h
	int	2fh				; ds:di = BDS
findLoop:
	cmp	di, -1
	je	notFound
	cmp	ds:[di+5], dl			; compare logical drive
	je	found
	lds	di, {dword} ds:[di]		; get next BDS
	jmp	short findLoop

notFound:
	cmp	di, 0				; clear Z flag (no FD12.SYS)
	jmp	done

found:
	mov	dl, ds:[di+4]			; dl = physical drive
	mov	ah, B13F_SET_MEDIA_TYPE
	mov	cx, 4c08h		; 76 tracks, 8 sects
	int	13h			; es:di = drive params table
	mov	cx, FD12SIG_SIZE
	segmov	ds, cs
	mov	si, offset FD12Sig
	repe	cmpsb
done:
	.leave
	ret
MSCheckFD12	endp

FD12Sig	byte	0xdf, 0x2, 0x25, 0x3, 0x8, 0x35
FD12SIG_SIZE equ ($-FD12Sig)
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSInitAllocDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize a drive descriptor for us to manage.

CALLED BY:	MSCreateDriveFromDCB
PASS:		cx	= DriveExtendedStatus
		al	= DDPDFlags
		ah	= MediaType
		es:bx	= DeviceControlBlock
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSInitAllocDrive proc near
		.enter
	;
	; Allocate our private data for the drive first, so when the kernel
	; calls us back to re-register any disks known on this drive, we
	; have valid private data for the drive.
	;
		push	cx, ax
EC <		push	es						>
EC <		segmov	es, ds	;avoid ec +segment death		>
		call	FSDLockInfoExcl
		mov	ds, ax
		mov	cx, size DOSDrivePrivateData
		call	LMemAlloc
		mov_tr	si, ax
EC <		pop	es						>
		pop	ax
		push	ax
		mov	ds:[si].DDPD_flags, al
		mov	ax, es:[bx].DCB_sectorSize
		mov	ds:[si].DDPD_sectorSize, ax

	;
	; See if the drive's an alias and deal with that.
	; 
		call	MSInitCheckDriveAlias
	;
	; Remember the DOS information, for checking on disk changes.
	; 
		mov	ds:[si].DDPD_dcb.offset, bx
		mov	ds:[si].DDPD_dcb.segment, es
		mov	al, es:[bx].DCB_unit
		mov	ds:[si].DDPD_unit, al
		
		mov	ax, es:[bx].DCB_deviceHeader.offset
		mov	ds:[si].DDPD_device.offset, ax
		mov	ax, es:[bx].DCB_deviceHeader.segment
		mov	ds:[si].DDPD_device.segment, ax

		tst	ax
		jz	privateDataComplete
		push	ds, si
		mov	ds, ax
		mov	si, es:[bx].DCB_deviceHeader.offset
		test	ds:[si].DH_attr, mask DA_STDIN_HUGE
		pop	ds, si
		jz	privateDataComplete
if _MS3
	;
	; for DOS < 3.31, must not set DDPDF_HUGE flag, as they
	; will choke if given 32-bit sectors.
	;
		push	ds, si
		segmov	ds, dgroup, si
		cmp	ds:[dosVersionMinor], 31
		pop	ds, si
		jb	privateDataComplete
endif
		ornf	ds:[si].DDPD_flags, mask DDPDF_HUGE
privateDataComplete:
EC <		push	es						>
EC <		segmov	es, cs	; avoid ec +segment death		>
		call	FSDUnlockInfoExcl
EC <		pop	es						>
		segmov	ds, dgroup, ax
	;
	; Deal with setting of maxSector.
	;
		mov	ax, es:[bx].DCB_sectorSize
		call	MSInitSetMaxSectorSize
		pop	cx, ax
	;
	; Call the kernel to create the DriveStatusEntry for the beast.
	; 
		mov	al, es:[bx].DCB_drive
		add	al, 'A'			; form name of drive
		mov	{byte}ds:[driveName][0], al
		mov	bx, si			; bx <- private data
		sub	al, 'A'			; al <- drive number again
		mov	dx, ds:[fsdOffset]	; FSD to manage it (us)
		mov	si, offset driveName	; ds:si <- name
		ornf	cx, mask DES_LOCAL_ONLY	; mark as local only, until
						;  corrected by network FSD
						;  loaded after us...
EC <		push	es						>
EC <		segmov	es, cs	; avoid ec +segment death		>
		call	FSDInitDrive
EC <		pop	es						>
		.leave
		ret
MSInitAllocDrive endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSInitCheckMediaOverride
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look in the .ini file to see if there's an override on
		the capacity or presence of the drive being defined.

CALLED BY:	MSCreateDriveFromDCB
PASS:		es:bx	= DeviceControlBlock
		cx	= DriveExtendedStatus about to be used
		al	= DDPDFlags about to be used
		ah	= MediaType about to be used
RETURN:		carry clear if drive should be defined:
			cx, al, ah 	= set appropriately
		carry set if drive should be ignored
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
systemCatStr	char	'system', 0
MSInitCheckMediaOverride proc	near
		uses	ds, si, dx
		.enter
	;
	; Form the "drive <x>" key.
	; 
		mov	si, offset systemCatStr
		push	ax, cx
		segmov	ds, dgroup, cx	; ds, cx <- dgroup
		mov	al, es:[bx].DCB_drive
		add	al, 'A'
		mov	ds:[driveKeyStr][DRIVE_KEY_LETTER_OFFSET], al
		mov	dx, offset driveKeyStr	; cx:dx <- key
		segmov	ds, cs			; ds:si <- category
EC <		push	es
EC <		segmov	es, cs			; avoid ec +segment death>
		call	InitFileReadInteger	; dx <- capacity
EC <		pop	es						>
		mov_tr	dx, ax
		pop	ax, cx

	;
	; Now use the capacity we got back to change ax and cx appropriately.
	; 
if _MS3
		jc	checkWithBIOS
else
		jc	doNothing	; => no key, so leave as-is
endif
		tst	dx		; ignore drive?
		stc
		jz	done		; yes

		mov	si, IDT_LOW_5_25
		cmp	dx, 360		; 360K or below?
		jbe	setStatus	; yes

		mov	si, IDT_LOW_3_5
		cmp	dx, 720		; 720K or below?
		jbe	setStatus	; yes

		mov	si, IDT_HIGH_5_25
		cmp	dx, 1200	; 1.2M or below?
		jbe	setStatus	; yes

		mov	si, IDT_LOW_8	; XXX: 1.44M
		cmp	dx, 1440	; 1.44M or below?
		jbe	setStatus
		
		mov	si, IDT_ULTRA_HIGH_3_5
		cmp	dx, 2880	; 2.88M or below?
		ja	strange		; no
setStatus:
		mov	ah, cs:[deviceMediaMap][si]
		shl	si
		mov	cx, cs:[deviceStatusMap][si]
statusSet:
		clr	al		; no special flags yet
doNothing:
		clc
done:
		.leave
		ret
if _MS3
	;
	; For single-floppy systems under anything below 3.20, we can't use the
	; logical drive map things to avoid getting annoying messages from DOS
	; that lock up the machine when the user clicks on the alias. So if
	; there's no preference in the .ini file, and this is some version
	; before 3.20, and the BIOS data says the drive doesn't exist, we
	; don't allow it to be seen. This doesn't handle the case where the
	; user used drive B: just before launching GEOS, as then when they
	; click on A, we'll get the annoying message, but there's only so
	; much we can do...
	; 				-- ardeb 11/24/92
	; 
checkWithBIOS:
		segmov	ds, dgroup, dx
		cmp	ds:[dosVersionMinor], 20
		jae	doNothing

		test	cx, mask DS_MEDIA_REMOVABLE	; fixed?
		jz	doNothing	; yes -- do nothing

		mov_tr	dx, ax		; preserve ax, in case we keep drive
		int	11h		; ax <- EqptConfig
		xchg	ax, dx
		test	dx, mask EC_FLOPPY	; any floppies?
		jz	ignoreIt		; no
		andnf	dl, mask EC_NUM_FLOPPIES
			CheckHack <offset EC_NUM_FLOPPIES eq 6 and \
				   width EC_NUM_FLOPPIES eq 2>
		rol	dl
		rol	dl			; dl = max floppy # (0-origin)
		cmp	es:[bx].DCB_drive, dl
		jbe	doNothing
ignoreIt:
		stc
		jmp	done
endif	; _MS3

strange:
	;
	; Treat anything else as a fixed disk drive.
	; 
		mov	cx, DriveExtendedStatus <0,0,0,0,0,<1,0,0,DRIVE_FIXED>>
		mov	ah, MEDIA_FIXED_DISK
		jmp	statusSet
MSInitCheckMediaOverride endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSInitCheckDriveAlias
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the drive being created is an alias for any other
		drive and set up the private data appropriately.

CALLED BY:	MSCreateDriveFromDCB
PASS:		ds:si	= MSDrivePrivateData
		es:bx	= DeviceControlBlock
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSInitCheckDriveAlias proc near
		uses	bx, es, cx, di
		.enter
	;
	; Assume drive isn't an alias.
	; 
		mov	ds:[si].DDPD_aliasLock, 0
	;
	; See if there's another drive sharing the physical drive with this
	; one.
	; 
		mov	bl, es:[bx].DCB_drive
		mov	cx, bx		; save drive #
		inc	bx		; 1-origin (1-byte inst)
		mov	ax, MSDOS_GET_LOGICAL_DRIVE_MAP
		int	21h
		jc	done		; ick

		tst	al
		jz	done		; => no alias
	;
	; There is. See if this is the current drive for the device.
	; 
		ornf	ds:[si].DDPD_flags, mask DDPDF_ALIAS
		segmov	es, dgroup, di

		dec	ax		; al <- 0-origin drive (1-byte inst)
		cmp	al, cl
		jne	lookForPrimary	; not us, so locate the primary, if
					;  it's defined...
		
	;
	; This is the current drive for the device, so allocate the thread
	; lock for the pair *here*.
	; 
		call	ThreadAllocThreadLock
		mov	ds:[si].DDPD_aliasLock, bx
	;
	; Now see if there's another drive defined already that has us as
	; an alias so we can store its number in our private data and the
	; handle of the thread lock in its data.
	; 
		mov	di, offset FIH_driveList - offset DSE_next
findSecondaryLoop:
		mov	di, ds:[di].DSE_next
		tst	di			; end of the line?
		jz	done			; ja
	;
	; Make sure the drive is managed by us before we go looking at its
	; private data...
	; 
		mov	ax, ds:[di].DSE_fsd
		cmp	ax, es:[fsdOffset]
		jne	findSecondaryLoop

		mov	bx, ds:[di].DSE_private
		test	ds:[bx].DDPD_flags, mask DDPDF_ALIAS
		jz	findSecondaryLoop

		cmp	ds:[bx].DDPD_alias, cl	; are we its other half?
		jne	findSecondaryLoop	; no

	;
	; Found the other half of this pair. Give it the handle of the
	; thread lock we share, and fetch its number for our own private data.
	; 
		mov	ax, ds:[si].DDPD_aliasLock
		mov	ds:[bx].DDPD_aliasLock, ax
		mov	al, ds:[di].DSE_number
		mov	ds:[si].DDPD_alias, al
done:
		.leave
		ret

lookForPrimary:
	;
	; This is the second half of the alias pair. Record the first half
	; and go see if it's already defined, so we can give it our own
	; number and get the alias lock from it.
	; 
		mov	ds:[si].DDPD_alias, al

		push	cx			; save our number

		mov_tr	cx, ax			; cl <- primary's number

		mov	di, offset FIH_driveList - offset DSE_next
findPrimaryLoop:
		mov	di, ds:[di].DSE_next
		tst	di			; end of the line?
		jz	primaryNotFound		; ja -- primary not defined yet,
						;  but we need to clear our
						;  drive number off the stack

		cmp	ds:[di].DSE_number, cl	; is it our other half?
		jne	findPrimaryLoop		; no
	;
	; EC: Make sure the drive is managed by us before we go looking at its
	; private data...
	; 
EC <		mov	ax, ds:[di].DSE_fsd				>
EC <		cmp	ax, es:[fsdOffset]				>
EC <		ERROR_NE PRIMARY_ALIAS_NOT_MANAGED_BY_US		>

	;
	; Found the other half of this pair. Fetch the handle of the
	; thread lock we share, and store our number into its private data
	; 
		mov	bx, ds:[di].DSE_private

		mov	ax, ds:[bx].DDPD_aliasLock
		mov	ds:[si].DDPD_aliasLock, ax
		pop	ax			; al <- our number
		mov	ds:[bx].DDPD_alias, al	; tell it about us, as otherwise
						;  it has no way of knowing
						;  who its other half is.
		jmp	done

primaryNotFound:
	;
	; Primary drive not created yet. When it is, it will come looking for
	; us and set up our private data properly.
	; 
		inc	sp			; discard our drive number.
		inc	sp
		jmp	done
MSInitCheckDriveAlias endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSMediaRemovable?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the device driver thinks the media are removable

CALLED BY:	MSCreateDriveFromDCB
PASS:		es:bx	= DeviceControlBlock for the device
		ds:si	= DeviceHeader for the device
RETURN:		carry set if the media are removable or we can't tell
DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSMediaRemovable? proc	near
		uses	bx
		.enter
	;
	; Does the driver support this call? If not, tell caller the media
	; are removable (worst-case)
	;
		mov	bl, es:[bx].DCB_drive
		inc	bx		; drive is 1-origin
		mov	ax, MSDOS_IOCTL_CHECK_REMOVABLE
		int	21h
		jc	removable	; assume removable on error (w-c)

		tst	ax		; ax == 0 if removable (clears carry)
		jnz	done
removable:
		stc
done:
		.leave
		ret
MSMediaRemovable? endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSFetchDeviceParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch and analyze the device parameters from a device,
		if the driver allows it.

CALLED BY:	InitDriveMap
PASS:		es:bx	= DeviceControlBlock for the device
		ds:si	= DeviceHeader for the device
RETURN:		carry set couldn't fetch the parameters
		carry clear if could:
			cx	= DriveExtendedStatus
			ah	= MediaType of default media
			al	= DDPDFlags
DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSFetchDeviceParams proc	near
params	    	local	GetDeviceParams
		uses	bx, dx, ds
		.enter
		push	bx
		mov	bl, es:[bx].DCB_drive
		inc	bx		; drive is 1-origin
		mov	cx, (8 shl 8) or 60h	; ioctl category is 8 (disk)
						;  function is 60h (Get
						;  Device Params)
		segmov	ds, ss
		lea	dx, ss:[params]
		mov	ss:[params].GDP_specialFuncs, 0	; Get default BPB
	;
	; Issue the call and deal with the result.
	;
		mov	ax, MSDOS_IOCTL_GEN_BLOCK_DEV
		int	21h
		jc	done		; error

		mov	cx, mask DS_PRESENT
		test	ss:[params].GDP_deviceAttrs, mask IDA_FIXED
		jnz	10$
		ornf	cx, mask DS_MEDIA_REMOVABLE or mask DES_FORMATTABLE
10$:
		clr	bx
		mov	bl, ss:[params].GDP_deviceType
		cmp	bx, IDT_OTHER
		je	handleOther
		cmp	bx, length deviceMediaMap
		jae	handleUnknown
		mov	ah, cs:deviceMediaMap[bx]
		shl	bx	| CheckHack <type deviceStatusMap eq word>
		ornf	cx, cs:deviceStatusMap[bx]
done:
		pop	bx
		jc	exit
	;
	; See if the device has a disk-changed signal, setting the
	; proper flag in DDPDFlags if so.
	;
		clr	al
		test	ss:[params].GDP_deviceAttrs, mask IDA_HAS_CHANGE_LINE
		jz	exit
		ornf	al, mask DDPDF_HAS_CHANGE_LINE
exit:
		.leave
		ret
handleOther:
	;
	; Got back an "other" device type, so use the media descriptor
	; in the BPB instead.
	;
		push	cx
		mov	cx, ss:[params].GDP_bpb.BPB_sectorsPerTrack
		mov	bl, ss:[params].GDP_bpb.BPB_mediaDescriptor
if _FXIP and ERROR_CHECK
	;
	; es is pointing into DOS here.  When in FXIP,
	; DOSDiskMapDosMediaToGEOSMedia is called via ResourceCallInt.  If
	; "ec segment" is on, ResourceCallInt sets es to null because the DOS
	; segment is unknown to GEOS.  We preserve es here so it won't be
	; destroyed when we return.
	;
	; When not in FXIP, DOSDiskMapDosMediaToGEOSMedia is called with a
	; far "call" instruction, so no EC code will biff es.
	;
	; --- AY 11/14/94
	;
		push	es
endif
		call	DOSDiskMapDosMediaToGEOSMedia
if _FXIP and ERROR_CHECK
		pop	es
endif
		pop	cx
		mov	bl, ah
		ornf	cl, cs:geosMediaToDriveType[bx-1]
	;
	; Deal with weirdness in DR-DOS 3.41, where it returns IDT_OTHER for
	; a 1.44M disk, but then returns a default BPB for a 720K disk. Since
	; by rights a 720K drive should be returning IDT_LOW_3_5, if the
	; default BPB is for a 720K disk, we know it's a 3.5" drive, so just
	; claim it's 1.44M...
	;
		cmp	ah, MEDIA_720K
		clc
		jne	done
		mov	ah, MEDIA_1M44
		jmp	done

handleUnknown:
	;
	; 1/6/93: added in response to SuperStor 2.04, which returns a
	; deviceType of 10 for a reserved drive letter (on which one may
	; mount a compressed volume on the fly). Just mark the thing as
	; fixed and non-formattable.
	; 
		mov	ax, (MEDIA_FIXED_DISK shl 8) or 0
		mov	cx, DriveExtendedStatus <0,0,0,0,0,<1,0,0,DRIVE_FIXED>>
		jmp	done
MSFetchDeviceParams endp

;
; Some DOS 3.2 versions return IDT_LOW_8 as the ioctl drive type for
; a 1.44M 3.5".  This is understandable as 1.44M support was not
; added until DOS 3.3.  But what the heck, we'll recognize it.
; (Sorry, we won't support low density 8" drives.)
;
deviceStatusMap	DriveExtendedStatus \
	<0,0,1,0,0,<1,1,0,DRIVE_5_25>>,		; IDT_LOW_5_25
	<0,0,1,0,0,<1,1,0,DRIVE_5_25>>,		; IDT_HIGH_5_25
	<0,0,1,0,0,<1,1,0,DRIVE_3_5>>,		; IDT_LOW_3_5
	<0,0,1,0,0,<1,1,0,DRIVE_3_5>>,		; IDT_LOW_8
	<0,0,0,0,0,<1,1,0,DRIVE_8>>,		; IDT_HIGH_8
	<0,0,0,0,0,<1,0,0,DRIVE_FIXED>>,	; IDT_FIXED
	<0,0,0,0,0,<1,0,0,DRIVE_UNKNOWN>>,	; IDT_TAPE
	<0,0,0,0,0,<1,0,0,DRIVE_UNKNOWN>>,	; IDT_OTHER
	<0,0,0,0,0,<1,1,0,DRIVE_CD_ROM>>,	; IDT_RW_OPTICAL
	<0,0,1,0,0,<1,1,0,DRIVE_3_5>>		; IDT_ULTRA_HIGH_3_5
	;L R F A B  P R	N TYPE
	;O E O L U  R E	E
	;C A R I S  E M	T
	;A D M A Y  S O	W
	;L   A S    E V	O
	;  O T 	    N A	R
	;  N T	    T B	K
	;  L A	      L
	;  Y B	      E
	;    L
	;    E

deviceMediaMap	MediaType \
	MEDIA_360K,		; IDT_LOW_5_25
	MEDIA_1M2,		; IDT_HIGH_5_25
	MEDIA_720K,		; IDT_LOW_3_5
	MEDIA_1M44,		; IDT_LOW_8
	MEDIA_CUSTOM,		; IDT_HIGH_8
	MEDIA_FIXED_DISK,	; IDT_FIXED
	MEDIA_CUSTOM,		; IDT_TAPE
	MEDIA_CUSTOM,		; IDT_OTHER
	MEDIA_CUSTOM,		; IDT_RW_OPTICAL
	MEDIA_2M88		; IDT_ULTRA_HIGH_3_5

if PZ_PCGEOS
geosMediaToDriveType	DriveType \
	DRIVE_5_25,		; MEDIA_160K
	DRIVE_5_25,		; MEDIA_180K
	DRIVE_5_25,		; MEDIA_320K
	DRIVE_5_25,		; MEDIA_360K
	DRIVE_3_5,		; MEDIA_720K
	DRIVE_5_25,		; MEDIA_1M2
	DRIVE_3_5,		; MEDIA_1M44
	DRIVE_3_5,		; MEDIA_2M88
	DRIVE_FIXED,		; MEDIA_FIXED_DISK
	DRIVE_UNKNOWN,		; MEDIA_CUSTOM
	DRIVE_PCMCIA,		; MEDIA_SRAM
	DRIVE_PCMCIA,		; MEDIA_ATA
	DRIVE_PCMCIA,		; MEDIA_FLASH
	DRIVE_3_5,		; MEDIA_640K
	DRIVE_3_5		; MEDIA_1M232
else
geosMediaToDriveType	DriveType \
	DRIVE_5_25,		; MEDIA_160K
	DRIVE_5_25,		; MEDIA_180K
	DRIVE_5_25,		; MEDIA_320K
	DRIVE_5_25,		; MEDIA_360K
	DRIVE_3_5,		; MEDIA_720K
	DRIVE_5_25,		; MEDIA_1M2
	DRIVE_3_5,		; MEDIA_1M44
	DRIVE_3_5,		; MEDIA_2M88
	DRIVE_FIXED,		; MEDIA_FIXED_DISK
	DRIVE_UNKNOWN,		; MEDIA_CUSTOM
	DRIVE_PCMCIA,		; MEDIA_SRAM
	DRIVE_PCMCIA,		; MEDIA_ATA
	DRIVE_PCMCIA		; MEDIA_FLASH
endif

CheckHack <length geosMediaToDriveType eq MediaType-1>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCheckBIOSData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the BIOS data area in an attempt to determine the type
		of drive being examined.

CALLED BY:	SetStatusFromDCB
PASS:		es:bx	= device control block
RETURN:		carry clear if drive type determined:
			cx	= DriveExtendedStatus
			ah	= MediaType
			al	= DDPDFlags
DESTROYED:	cx (if carry returned set)

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCheckBIOSData proc	near
		.enter
	;
	; See if drive is 0 or 1. If not, we can't hope to find anything in
	; the BIOS area.
	;
		mov	al, es:[bx].DCB_drive
		cmp	al, 2
		ja	done

	;
	; Fetch the proper BiosMediaState variable from the data area.
	;
		push	ds, bx
		mov	bx, BIOS_DATA_SEG
		mov	ds, bx
		mov	bl, al	| CheckHack <BIOS_DATA_SEG lt 256>
		add	bx, offset BIOS_MEDIA_STATE_0
		mov	cl, ds:[bx]
		pop	ds, bx

		tst	cl		; nothing there? (old BIOS)
		jz	done		; right -- just use DCB

					; drive/media unknown or reserved?
		andnf	cx, mask BMS_DRIVE_MEDIA
		cmp	cl, BiosMediaState <0,0,0,BDMS_RESERVED>
		jae	done		; yes -- just use DCB


			CheckHack <BDMS_360IN360NE eq 0>
		jcxz	is360k
		mov	ah, MEDIA_1M2	; assume 1.2M
		cmp	cl, BDMS_360IN360
		jne	success
is360k:
		mov	ah, MEDIA_360K
success:
					;can only be 5.25" drive...
		mov	cx, DriveExtendedStatus <
			0,	; DES_LOCAL_ONLY
			0,	; DES_READ_ONLY
			1,	; DES_FORMATTABLE
			0,	; DES_ALIAS
			0,	; DES_BUSY
			<
				1,		; DS_PRESENT
				1,		; DS_MEDIA_REMOVABLE
				0,		; DS_NETWORK
				DRIVE_5_25	; DS_TYPE
			>
		>
		clr	al	; no extra private flags from us, man
		stc			; so we return carry clear

done:
		cmc			; return carry set correctly. All
					;  failure branches have carry clear,
					;  so...
		.leave
		ret
MSCheckBIOSData endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCheckDCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try and figure the type of drive by examining the data in
		the DCB.

CALLED BY:	SetStatusFromDCB
PASS:		es:bx	= DeviceControlBlock
		ds	= dgroup
RETURN:		carry set if drive type couldn't be determined
		carry clear if it could:
			cx	= DriveExtendedStatus for the drive
			ah	= GEOS media descriptor
			al	= DDPDFlags
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCheckDCB	proc	near	uses bx
		.enter
		mov	al, es:[bx].DCB_media
		clr	ah
		cmp	al, DOS_MEDIA_CUSTOM
		stc			; assume DOS doesn't know either...
		je	done

		mov	cx, 15		; this is used only to distinguish
					; between 720K and 1.2M. Since 720K
					; exists only in 3.2 and later, where
					; MSFetchDeviceParams would have
					; worked, just pretend drive has 15
					; s.p.t. so we get MEDIA_1M2...

		push	bx
		mov_trash	bx, ax	; bx <- DOS media descriptor
if _FXIP and ERROR_CHECK
		push	es
endif
		call	DOSDiskMapDosMediaToGEOSMedia
if _FXIP and ERROR_CHECK
		pop	es
endif

				; (ch cleared by load of cx with 15, above)
		mov	cl, cs:MediaToDriveTypeLookup[bx-0xf0]
		ornf	cx, mask DES_FORMATTABLE or mask DS_PRESENT or\
				mask DS_MEDIA_REMOVABLE
		pop	bx
		call	MSVerifyMediaCapacity

		clr	al		; can't have change line or would
					;  support IOCTL...
done:
		.leave
		ret
MSCheckDCB	endp


MediaToDriveTypeLookup	DriveType \
	DRIVE_3_5,	;0f0h - 1.44M
	DRIVE_UNKNOWN,	;0f1h
	DRIVE_UNKNOWN,	;0f2h
	DRIVE_UNKNOWN,	;0f3h
	DRIVE_UNKNOWN,	;0f4h
	DRIVE_UNKNOWN,	;0f5h
	DRIVE_UNKNOWN,	;0f6h
	DRIVE_UNKNOWN,	;0f7h
	DRIVE_FIXED,	;0f8h - fixed disk
	DRIVE_5_25,	;0f9h - 1.2M or 720K, can't use lookup
	DRIVE_3_5,	;0fah XXX: 2.11 on Tosh1000SE uses this for 720K 3.5"
	DRIVE_UNKNOWN,	;0fbh
	DRIVE_5_25,	;0fch - 180K
	DRIVE_5_25,	;0fdh - 360K
	DRIVE_5_25,	;0feh - 160K
	DRIVE_5_25	;0ffh - 320K

mediaSizeTable	dword	160*1024,	; MEDIA_160K
			180*1024,	; MEDIA_180K
			320*1024,	; MEDIA_320K
			360*1024,	; MEDIA_360K
			720*1024,	; MEDIA_720K
			1200*1024,	; MEDIA_1M2
			1440*1024,	; MEDIA_1M44
			2880*1024	; MEDIA_2M88


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSVerifyMediaCapacity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the drive capacity encoded in the disk geometry
		matches that encoded in the media type. Bernoulli boxes
		are notorious for not matching, e.g.

CALLED BY:	MSCheckDCB, MSFetchDeviceParams
PASS:		cx	= DriveExtendedStatus
		es:bx	= device control block
		ah	= MediaType

RETURN:		cx	= DriveExtendedStatus (possibly modified)
		ah	= MediaType (changed to MEDIA_CUSTOM if listed
			  capacity doesn't match that of media descriptor)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSVerifyMediaCapacity proc	near
		uses	dx, si
		.enter
	;
	; The number of bytes on the disk is:
	;
	;	(sectorSize*sectorsPerCluster)*numberOfClusters
	;
	; Because the sectorsPerCluster is encoded as DCB_clusterShift, we
	; reverse the order of the multiplications. DCB_endFilesArea is
	; the total number of clusters on the disk.
	;
		push	cx, ax
		mov	ax, es:[bx].DCB_sectorSize
		mov	dx, es:[bx].DCB_endFilesArea
		dec	dx			; first real cluster in the
						;  files area is #2, but
						;  we need a count of the
						;  clusters, and decrementing
						;  by 2 would give us a number
						;  by which we could calculate
						;  the last sector...
		mul	dx			; dx:ax <- size * number

		clr	ch
		mov	cl, es:[bx].DCB_clusterShift
		jcxz	shiftDone
shiftLoop:
		shl	ax
		rcl	dx
		loop	shiftLoop
shiftDone:
	;
	; Now add in the number of sectors to the start of the files area.
	; 
		mov	si, dx
		mov	cx, ax
		mov	ax, es:[bx].DCB_startFilesArea
		mul	es:[bx].DCB_sectorSize
		
		add	ax, cx
		adc	dx, si
	;
	; dx:ax is now the rated capacity of the drive. See if it matches
	; that for the media descriptor.
	;
		pop	cx
		push	cx
		xchg	cl, ch
		clr	ch
		cmp	cx, length mediaSizeTable
		jae	popDone		; not in table => leave it alone (either
					;  custom already, or fixed (!))

		mov	si, cx
		shl	si		; *4 to index the table
		shl	si
		cmp	ax, cs:mediaSizeTable[si-4].low	; si-4 b/c MediaType
		jne	custom				;  start at 1
		cmp	dx, cs:mediaSizeTable[si-4].high
		jne	custom
popDone:
		pop	cx, ax		; recover passed data untouched
done:
		.leave
		ret
custom:
		pop	cx, ax
	;
	; Set the media type to custom, and mark the drive not formattable.
	; 
		mov	ah, MEDIA_CUSTOM
		andnf	cx, not mask DES_FORMATTABLE
		jmp	done
MSVerifyMediaCapacity endp

;==============================================================================
;
;		      FILE TABLE INITIALIZATION
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLocateFileTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate, size and initialize the DR DOS file table.

CALLED BY:	MSInit
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
MSLocateFileTable proc near
		.enter
	;
	; Figure the extent, location and usage of our JFT
	;
		mov	es, ds:[pspSegment]
		mov	ax, es:[PSP_numHandles]		; fetch and record
		mov	ds:[jftSize], ax		;  number of handles
		mov	ds:[jftEntries].Sem_value, ax	;  in the JFT

		les	di, es:[PSP_jftAddr]		; locate and record
		mov	ds:[jftAddr].offset, di		;  the JFT itself
		mov	ds:[jftAddr].segment, es

		xchg	ax, cx				; cx <- # handles
		mov	al, NIL				; look for free handles
countLoop:	
		scasb					; Handle free?
		je	nextHandle			; yes
		dec	ds:[jftEntries].Sem_value	; no -- one fewer
							;  available handle
nextHandle:
		loop	countLoop

	;
	; Locate the start and end of the SFT
	;
		mov	ah, MSDOS_GET_DOS_TABLES
		int	21h
		
		les	di, es:[bx].DLOL_SFT
		mov	ds:[sftStart].segment, es
		mov	ds:[sftStart].offset, di

if _MS3
	;
	; Cope with PC-DOS 3.0, which has a slightly different SFT entry than
	; other 3.x versions of DOS, PC- or MS-. To detect the difference, we
	; check the first character of the first SFT entry's name, which should
	; be for the AUX device, but we allow any character between A and Z,
	; just to be safe. The name in PC-DOS 3.0 is one byte further along
	; than in other versions, you see...
	; 
		cmp	ds:[dosVersionMinor], 0
		ja	findSFTEndLoop
		cmp	es:[di].SFTE_name[0], 'A'
		jb	isPC3
		cmp	es:[di].SFTE_name[0], 'Z'
		jbe	findSFTEndLoop
isPC3:
		mov	ds:[isPC3_0], TRUE
		mov	ds:[sftEntrySize], size SFT30Entry
endif	; _MS3

findSFTEndLoop:
		cmp	es:[di].SFTBH_next.offset, NIL	; no next block?
		je	haveSFTEnd
		les	di, es:[di].SFTBH_next
		jmp	findSFTEndLoop
haveSFTEnd:
		mov	ds:[sftEnd].segment, es
		mov	ds:[sftEnd].offset, di
		mov	ds:[sftInitEnd].segment, es
		mov	ds:[sftInitEnd].offset, di

		.leave
		ret
MSLocateFileTable endp


Init		ends

;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
;
;			    EXIT HANDLING
;
;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down our interaction with DOS.

CALLED BY:	DR_EXIT
PASS:		nothing
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSExit		proc	far
		uses	ds, es, si
		.enter
		call	LoadVarSegDS
	;
	; Unhook idle
	; 
		call	DOSIdleExit
	;
	; Unhook wait/post.
	; 
		call	DOSWaitPostExit
	;
	; Release the critical-error vector.
	; 
		call	DOSUnhookCriticalError
	;
	; Truncate the SFT to its original size (all files should have been
	; closed by now)
	; 
		les	si, ds:[sftInitEnd]
		mov	es:[si].SFTBH_next.offset, NIL
		.leave
		ret
MSExit		endp

Resident	ends
