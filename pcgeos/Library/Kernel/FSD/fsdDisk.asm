COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Kernel -- FSD
FILE:		diskFSD.asm

AUTHOR:		Adam de Boor, Jul 18, 1991

ROUTINES:
	Name			Description
	----			-----------
	FSDGenNameless		Generate an "Unnamed" volume label for a disk
	FSDAllocDisk		Allocate & initialize a new disk handle
	FSDAskForDisk		Ask the user to insert a particular disk.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	7/18/91		Initial revision


DESCRIPTION:
	Disk-related FSD helper routines.
		

	$Id: fsdDisk.asm,v 1.1 97/04/05 01:17:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Filemisc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDGenNameless
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a label for an unnamed disk, perhaps notifying
		the user of its generation.

CALLED BY:	RESTRICTED GLOBAL
       		(FileSystem Drivers)
PASS:		es:si	= DiskDesc for the disk being initialized
		ah	= FSDNamelessAction to take, as far as reporting
			  (or even doing anything) is concerned.
RETURN:		es:[si].DD_volumeLabel filled in
		es:[si].DD_flags.DF_NAMELESS set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDGenNameless	proc	far
		call	PushAllFar
	;
	; Always set the DF_NAMELESS flag for the disk, as it'll have been
	; wiped out by DiskReRegister should we be told to ignore this
	; request.
	; 
		ornf	es:[si].DD_flags, mask DF_NAMELESS
	;
	; Abort now if we don't really want to generate anything here.
	; 
		cmp	ah, FNA_IGNORE
		LONG je	done
	;
	; Else, space-fill the volume label, as that's how these things are
	; stored.
	; 
		lea	di, es:[si].DD_volumeLabel
		mov	cx, length DD_volumeLabel
		LocalLoadChar ax, ' '
SBCS <		rep	stosb						>
DBCS <		rep	stosw						>
	;
	; Copy in the "Unnamed" portion of the generated label.
	; 
		sub	di, size DD_volumeLabel
SBCS <		mov	al, KS_UNNAMED					>
DBCS <		mov	al, KS_UNNAMED or KS_DBCS_DEST			>
		call	AddStringAtESDIFar
		
	;
	; Now give the thing the next number in the sequence.
	; 
		LoadVarSeg	ds
		push	ax
		mov	ax, ds:[assocNum]
		inc	ax
		mov	ds:[assocNum], ax

		clr	dx
		mov	cx, dx		; no special flags
		call	UtilHex32ToAscii
		pop	ax
		
	;
	; If we've not been asked to be quiet about this, proclaim the
	; volume's new (fake) name to the world.
	; 
		cmp	ah, FNA_SILENT
		je	done
	;
	; If the media aren't removable, there's no point in telling the
	; user of the association, as s/he'll never be prompted for the disk...
	; 
		mov	di, es:[si].DD_drive
		test	es:[di].DSE_status, mask DS_MEDIA_REMOVABLE
		jz	done

		segmov	ds, es		; ds <- FSIR
	;
	; We must build up the string calling our friend, the localization
	; driver, to get the strings (AddStringAtMessageBuffer expects
	; ds to be dgroup, so can't use that...)
	;
		LoadVarSeg	es
		mov	di, offset messageBuffer
SBCS <		mov	al, KS_THE_DISK_IN_DRIVE			>
DBCS <		mov	al, KS_THE_DISK_IN_DRIVE or KS_DBCS_DEST	>
		call	AddStringAtESDIFar

if not SINGLE_DRIVE_DOCUMENT_DIR
	    ;
	    ; Copy in the drive's name.
	    ;
		push	si
		mov	si, ds:[si].DD_drive
		add	si, offset DSE_name
		LocalCopyString
		pop	si			; ds:si <- DiskDesc

		LocalPrevChar esdi		; back up to NULL
endif

	    ;
	    ; Copy in the second part of the first line
	    ; 
SBCS <		mov	al, KS_HAS_NO_NAME_AND				>
DBCS <		mov	al, KS_HAS_NO_NAME_AND or KS_DBCS_DEST		>
		call	AddStringAtESDIFar

	    ;
	    ; Store second string after first, leaving the null between
	    ;
		LocalNextChar	esdi
		push	di

SBCS <		mov	al, KS_WILL_BE_REFERRED_TO_AS			>
DBCS <		mov	al, KS_WILL_BE_REFERRED_TO_AS or KS_DBCS_DEST	>
		call	AddStringAtESDIFar

	    ;
	    ; Copy the volume name from the disk descriptor. Note that all
	    ; volume names are already in the PC/GEOS character set, having
	    ; been mapped there by the FSD.
	    ; 
		mov	cx, length DD_volumeLabel
		add	si, offset DD_volumeLabel
		LocalCopyNString		;rep movsb/movsw

		segmov	ds, es		; both strings are in dgroup...
		pop	di		; ds:di <- second string
		mov	si, offset messageBuffer	; ds:si <- first string
		mov	ax, mask SNF_CONTINUE	; can only continue from here
		call	SysNotify
	;
	; Zero out the buffer so that no message will be displayed when we shut
	; down.
	; 
		mov	ds:[messageBuffer], 0
done:
		call	PopAllFar
		ret
FSDGenNameless	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDAllocDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize a new disk descriptor, linking it
		into the chain of known disks.

CALLED BY:	RESTRICTED GLOBAL
       		(FileSystem drivers, DiskRegisterCommon)
PASS:		es	= FSInfoResource locked for shared access
		cx:dx	= 32-bit ID for the disk
		al	= DiskFlags for the disk
		ah	= MediaType for the disk
		si	= DriveStatusEntry offset of drive in which the
			  disk is located.
RETURN:		si	= DiskDesc offset
		ds fixed up if pointing to FSInfoResource on entry, else
			destroyed.
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDAllocDisk	proc	far
		.enter
		call	FSDUpgradeSharedInfoLock
		segmov	ds, es
	;
	; Allocate a handleless chunk for the descriptor from the FSIR
	; 
		push	ax		; save DiskFlags & MediaType for later
		push	cx
		mov	cx, size DiskDesc
		call	LMemAlloc
		; XXX: check for errors?
		
		call	FSDDowngradeExclInfoLock
		mov	bx, ax		; ds:bx <- DiskDesc since si holds
					;  DriveStatusEntry

	;
	; Set the various fields....we don't bother with DD_volumeLabel as
	; it'll be filled in soon anyway.
	; 
		pop	ds:[bx].DD_id.high
		mov	ds:[bx].DD_id.low, dx
		pop	ax
		mov	ds:[bx].DD_flags, al
		mov	ds:[bx].DD_media, ah
		mov	ds:[bx].DD_drive, si
		mov	ds:[bx].DD_private, 0
		
	;
	; Link the new descriptor as the head of the chain.
	; 
		INT_OFF
		mov	ax, bx
		xchg	ax, ds:[FIH_diskList]
		mov	ds:[bx].DD_next, ax
		INT_ON
		
		mov	si, bx		; return DiskDesc in si
		.leave
		ret
FSDAllocDisk	endp

Filemisc ends

FSResident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDAskForDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the user to insert the passed disk.

CALLED BY:	FS Drivers
PASS:		es:si	= DiskDesc requested.
		al	= FILE_NO_ERRORS bit set if user is not allowed to
			  abort the disk lock.
RETURN:		carry set if user aborted.
		carry clear if user said disk was there.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDAskForDisk	proc	far
		call	PushAllFar
		
		segmov	ds, es
		
		push	ax		; save FILE_NO_ERRORS flag


	;
	; Create the first string from the KS_PLEASE_INSERT_DISK string and
	; the volume label for the disk.
	; 
		push	ds		; AddStringAtMessageBuffer
		LoadVarSeg	ds	;  expects DS to be dgroup, for some
					;   reason...
		mov	al, KS_PLEASE_INSERT_DISK
		call	AddStringAtMessageBufferFar
		pop	ds

		mov	bx, si		; save DiskDesc offset
		add	si, offset DD_volumeLabel
		mov	cx, length DD_volumeLabel
		LocalCopyNString		;rep movsb/movsw
		LocalClrChar ax
		LocalPutChar esdi, ax		; null-terminate

	;
	; Set es:di to storage for second string, which comes immediately after
	; the first.
	;
		LocalNextChar esdi
		push	di		; save start for SysNotify
		
SBCS <		mov	al, KS_INTO_DRIVE				>
DBCS <		mov	al, KS_INTO_DRIVE or KS_DBCS_DEST		>
		call	AddStringAtESDIFar

if not SINGLE_DRIVE_DOCUMENT_DIR
		mov	si, ds:[bx].DD_drive
		add	si, offset DSE_name	; copy in the null-terminated
						;  drive name.
		LocalCopyString			;copy NULL-terminated string
endif

	;
	; Put up the notification box using the strings we just put together.
	; 
		pop	di

haveStrings::
		mov	si, offset messageBuffer
		segmov	ds, es		; ds:si, ds:di <- messages

		pop	ax		; recover FILE_NO_ERRORS flag
		test	al, FILE_NO_ERRORS
		mov	ax, mask SNF_CONTINUE	; assume set...
		jnz	notify

if not NO_ABORT_IN_INSERT_DISK_DIALOG
		;	
		; No abort option in Redwood!   Too many bad things happen
		; on aborts.   3/23/94 cbh   (Restored, we'll see what QA
		; problems result.  5/ 8/94 cbh.)  (Canon asked us to remove
		; it again, fine.  5/26/94 cbh)
		;
		ornf	ax, mask SNF_ABORT	; FILE_NO_ERRORS not set, so
						;  give user (A)bort option
endif

notify:
		call	SysNotify
	;
	; If user chose A~bort, return carry set.
	; 
		test	ax, mask SNF_ABORT
		jz	done
		stc
done:
		mov	ds:[messageBuffer], 0	; mark messageBuffer empty
						;  so no notice gets printed
						;  when we finally exit.
		call	PopAllFar
		ret
FSDAskForDisk	endp

FSResident	ends
