COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved
	Copyright (c) New Deal 1998 -- All Rights Reserved

PROJECT:	
MODULE:
FILE:		driInitExit.asm

AUTHOR:		Gene, January 23, 1998

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/23/98		based on OS/2


DESCRIPTION:
	Functions to initialize and exit the driver.


	$Id: ntfatInitExit.asm,v 1.1 98/01/24 23:13:56 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2Init
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
OS2Init		proc	far
		.enter
		segmov	ds, dgroup, ax
		mov	ah, MSDOS_GET_PSP
		int	21h

		mov	ds:[pspSegment], bx	; save PSP

	;
	; Get the current DOS code page and tell the kernel about it.
	;
		mov	ax, (MSDOS_SELECT_CODE_PAGE shl 8) or 1
		int	21h
		mov	ax, CODE_PAGE_US	; assume US...
		jc	haveCodePage		;  ...on error
		mov_tr	ax, bx			; ax <- active code page
haveCodePage:
		call	LocalSetCodePage
		call	DOSInitUseCodePage
;registerDriver:	
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
	;
	; Allocate initial boot sector buffer in case we have to ID any floppy
	; disks during the creation of the drive table (as happens on Poqet
	; machines, for example).
	; 
		mov	ax, MSDOS_STD_SECTOR_SIZE
		call	OS2InitSetMaxSectorSize

		call	OS2LocateDrives

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

EC <		segmov	es, ds	; avoid ec +segment death (es is PSP) >
		call	DOSInitOpenFiles
	;
	; Locate the NUL device so we can map device names properly.
	; 
		call	DOSInitNullDevicePointer
	;
	; Enable idle-time hook.
	; 
		call	DOSIdleInit
		
		dec	ds:[dosPreventCritical]
		clc
		.leave
		ret
OS2Init	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2InitSetMaxSectorSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the size of the largest sector known, enlarging the
		boot sector buffer if necessary.

CALLED BY:	OS2Init, OS2InitAllocDrive
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
OS2InitSetMaxSectorSize proc near
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
OS2InitSetMaxSectorSize endp

;==============================================================================
;
;			    DRIVE LOCATION
;
;==============================================================================

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2LocateDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all the drives we can manage. Ideally this would
		rely less on internal DOS data structures, but they've
		not made it easy on us. There exists only one function
		(undocumented, of course) that might be of help, AH=32h,
		except that for drives whose device control block is marked
		invalid, the damn thing actually goes to the drive to
		do God only knows what, which we can't allow.

CALLED BY:	OS2Init
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
OS2LocateDrives proc	near
		.enter
		clr	bx
driveLoop:
		call	OS2CreateDrive
		inc	bx
		cmp	bx, MSDOS_MAX_DRIVES
		jb	driveLoop

		.leave
		ret
OS2LocateDrives endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2CreateDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a drive entry given the drive's DeviceControlBlock

CALLED BY:	OS2LocateDrives
PASS:		bx	= drive number (0-origin)
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
OS2CreateDrive proc	near
		.enter
	;
	; Fetch device parameters using generic IOCTL call, if driver supports
	; it.
	;
    		call	OS2FetchDeviceParams
		jnc	createDrive
	;
	; If drive is invalid, then don't create something for it...
	;
		cmp	ax, ERROR_INVALID_DRIVE
		je	done
	;
	; See if it's local or remote.
	;
		mov	ax, MSDOS_IOCTL_DRIVE_REMOTE?
		inc	bx		; 1-origin...
		int	21h
		dec	bx
	;
	; 1/23/98: If this call fails, then don't create the drive.
	; Running under NT 4.0 FAT, phantom network drives are created
	; for any unused drives A-Z if the original branch is taken.
	;
	;	jc	godOnlyKnows
		jc	done

		test	dx, 1 shl 12	
		jz	godOnlyKnows

		mov	cx, DRIVE_FIXED or mask DS_PRESENT or mask DS_NETWORK
		mov	ax, MEDIA_FIXED_DISK shl 8
		mov	dx, MSDOS_STD_SECTOR_SIZE
		jmp	createDrive

godOnlyKnows:
	;
	; Else drive must not support generic IOCTL...
	;
			; call it fixed disk of unknown type. what the
			; hooey.... -- ardeb 5/30/91
		mov	cx, DRIVE_UNKNOWN or mask DS_PRESENT
		mov	ax, MEDIA_FIXED_DISK shl 8
		mov	dx, MSDOS_STD_SECTOR_SIZE
createDrive:
	;
	; cx	= DriveExtendedStatus
	; al	= DDPDFlags
	; ah	= MediaType
	; dx	= sector size
	; bx	= drive number
	; 
		call	OS2InitCheckMediaOverride
		jc	done		; => ignore drive

		call	OS2InitAllocDrive
done:
		.leave
		ret
OS2CreateDrive endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2InitAllocDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize a drive descriptor for us to manage.

CALLED BY:	OS2CreateDrive
PASS:		cx	= DriveExtendedStatus
		al	= DDPDFlags
		ah	= MediaType
		bx	= drive number (0-origin)
		dx	= sector size
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
OS2InitAllocDrive proc near
		uses	bx
		.enter
	;
	; Allocate our private data for the drive first, so when the kernel
	; calls us back to re-register any disks known on this drive, we
	; have valid private data for the drive.
	;
		push	cx, ax
		call	FSDLockInfoExcl
		mov	ds, ax
		mov	cx, size DOSDrivePrivateData
EC <		push	es						>
EC <		segmov	es, ds	;avoid ec +segment death		>
		call	LMemAlloc
		mov_tr	si, ax
EC <		pop	es						>
		pop	ax
		push	ax
		mov	ds:[si].DDPD_flags, al
		mov	ds:[si].DDPD_sectorSize, dx

	;
	; See if the drive's an alias and deal with that.
	; 
		call	OS2InitCheckDriveAlias
	;
	; Remember the DOS information, for checking on disk changes.
	; 
		ornf	ds:[si].DDPD_flags, mask DDPDF_HUGE

EC <		push	es						>
EC <		segmov	es, cs	; avoid ec +segment death		>
		call	FSDUnlockInfoExcl
EC <		pop	es						>
		segmov	ds, dgroup, ax
	;
	; Deal with setting of maxSector.
	;
		mov	ax, dx
		call	OS2InitSetMaxSectorSize
		pop	cx, ax
	;
	; Call the kernel to create the DriveStatusEntry for the beast.
	; 
		mov	al, bl
		add	al, 'A'			; form name of drive
		mov	ds:[driveName][0], al
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
OS2InitAllocDrive endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2InitCheckMediaOverride
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look in the .ini file to see if there's an override on
		the capacity or presence of the drive being defined.

CALLED BY:	OS2CreateDriveFromDCB
PASS:		bx	= drive number (0-origin)
		dx	= sector size
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
OS2InitCheckMediaOverride proc	near
		uses	ds, si, dx
		.enter
	;
	; Form the "drive <x>" key.
	; 
		mov	si, offset systemCatStr
		push	ax, cx
		segmov	ds, dgroup, cx	; ds, cx <- dgroup
		mov	al, bl
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
		jc	doNothing	; => no key, so leave as-is
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
strange:
	;
	; Treat anything else as a fixed disk drive.
	; 
		mov	cx, DriveExtendedStatus <0,0,0,0,0,<1,0,0,DRIVE_FIXED>>
		mov	ah, MEDIA_FIXED_DISK
		jmp	statusSet
OS2InitCheckMediaOverride endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2InitCheckDriveAlias
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the drive being created is an alias for any other
		drive and set up the private data appropriately.

CALLED BY:	OS2CreateDriveFromDCB
PASS:		ds:si	= OS2DrivePrivateData
		bx	= drive number (0-origin)
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OS2InitCheckDriveAlias proc near
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
OS2InitCheckDriveAlias endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2FetchDeviceParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch and analyze the device parameters from a device,
		if the driver allows it.

CALLED BY:	OS2LocateDrives
PASS:		bx	= drive number (0-origin)
RETURN:		carry set couldn't fetch the parameters
			ax	= FileError
		carry clear if could:
			cx	= DriveExtendedStatus
			ah	= MediaType of default media
			al	= DDPDFlags
			dx	= sector size
DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OS2FetchDeviceParams proc	near
params	    	local	GetDeviceParams
		uses	bx, ds
		.enter
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
		jc	exit		; error

		mov	dx, ss:[params].GDP_bpb.BPB_sectorSize
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
		call	DOSDiskMapDosMediaToGEOSMedia
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
OS2FetchDeviceParams endp

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

CheckHack <length geosMediaToDriveType eq MediaType-1>



;==============================================================================
;
;		      FILE TABLE INITIALIZATION
;
;==============================================================================

Init		ends

;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
;
;			    EXIT HANDLING
;
;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2Exit
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
OS2Exit		proc	far
		uses	ds, es, si
		.enter
		call	LoadVarSegDS
	;
	; Unhook idle
	; 
		call	DOSIdleExit
	;
	; Release the critical-error vector.
	; 
		call	DOSUnhookCriticalError
		.leave
		ret
OS2Exit		endp

Resident	ends
