COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Main
FILE:		mainDiskOps.asm

ROUTINES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/89		Initial version

DESCRIPTION:
	This file contains code to handle disk copy and disk format.

	$Id: cmainDiskOps.asm,v 1.2 98/06/03 13:37:08 joon Exp $

------------------------------------------------------------------------------@

DiskCode	segment resource

if _GMGR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskStartDiskFormatBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up format disk box

CALLED BY:	MSG_META_START_DISK_FORMAT_BOX

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskStartDiskFormatBox	method	DesktopClass, MSG_META_START_DISK_FORMAT_BOX
	call	ShowHourglass
	;
	; set up media-type list in dialog
	;
	mov	bx, handle DiskFormatSourceList
	mov	si, offset DiskFormatSourceList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessageCallFixup		; ax = selection
	mov	cx, ax				; cx = selection
	mov	ax, MSG_DISK_FORMAT_SOURCE_DRIVE
	mov	bx, handle 0			; bx = proces handle
	call	ObjMessageCallFixup		; fake apply msg

if not _ZMGR
	;
	; set QuickFormat option on or off according to Advanced Disk Options
	;
	mov	bx, handle OptionsList
	mov	si, offset OptionsList
	mov	cx, mask OMI_SHOW_ADV_DISK_OPTIONS
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	call	ObjMessageCall
	mov	ax, MSG_GEN_SET_USABLE
	jc	gotMessage
	mov	ax, MSG_GEN_SET_NOT_USABLE
gotMessage:
	mov	dl, VUM_NOW
	mov	bx, handle DiskFormatQuickMode
	mov	si, offset DiskFormatQuickMode
	call	ObjMessageCall
endif		; if (not _ZMGR)
	;
	; bring up format box
	;
	mov	bx, handle DiskFormatBox
	mov	si, offset DiskFormatBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageFixup
	call	HideHourglass
	ret
DiskStartDiskFormatBox	endm

endif		; if _GMGR






if _GMGRONLY		; no disk copy and disk rename for GeoLauncher


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskStartDiskCopyBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up copy disk box

CALLED BY:	MSG_META_START_DISK_COPY_BOX

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskStartDiskCopyBox	method	DesktopClass, MSG_META_START_DISK_COPY_BOX
	call	ShowHourglass
	;
	; set up destination list in dialog
	;
	mov	bx, handle DiskCopySourceList
	mov	si, offset DiskCopySourceList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessageCallFixup		; ax = selection
	mov	cx, ax				; cx = selection
	mov	ax, MSG_DISK_COPY_SOURCE_DRIVE
	mov	bx, handle 0			; bx = proces handle
	call	ObjMessageCallFixup		; fake apply msg

if not _ZMGR
	;
	; set Greedy option on or off according to Advanced Disk Options
	;
	mov	bx, handle OptionsList
	mov	si, offset OptionsList
	mov	cx, mask OMI_SHOW_ADV_DISK_OPTIONS
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	call	ObjMessageCall
	mov	ax, MSG_GEN_SET_USABLE
	jc	gotMessage
	mov	ax, MSG_GEN_SET_NOT_USABLE
gotMessage:
	mov	dl, VUM_NOW
	mov	bx, handle DiskCopyGreedyOption
	mov	si, offset DiskCopyGreedyOption
	call	ObjMessageCall
endif		; if (not _ZMGR)
	;
	; bring up copy box
	;
	mov	bx, handle DiskCopyBox
	mov	si, offset DiskCopyBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageFixup
	call	HideHourglass
	ret
DiskStartDiskCopyBox	endm

endif		; if _GMGRONLY

if not _FCAB


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskCopyCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle disk copy

CALLED BY:	MSG_DISK_COPY_COPY

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskCopyCopy	method	DesktopClass, MSG_DISK_COPY_COPY
	call	IndicateBusy
	mov	ss:[recurErrorFlag], 0		; allows us to use common
						;	dialog box code
	mov	ss:[copyStatusMoniker], 0	; prepare for status reporting
	mov	ss:[activeCopyStatusMoniker], 0
	;
	; get source drive number
	;
GM<	mov	bx, handle DiskMenuResource	; bx:si = disk list	>
GM<	mov	si, offset DiskMenuResource:DiskCopySourceList		>
GM<	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION			>
GM<	call	ObjMessageCall			; al = source drive number >
ND<	mov	ax,  ss:[ndClickedOnDrive]	; ah = source media descriptor
	push	ax				; save 'em
	;
	; clear out progress fields
	;
	mov	ax, DCC_REPORT_READ_PCT
	mov	dx, 1000
	call	CopyCallbackRoutine
	;
	; enable cancel button
	;
	clr	ss:[cancelOperation]		; clear cancel flag
	clr	ss:[cancelMonikerToChange]	; no moniker to change
	mov	bx, handle CopyStatusCancel
	mov	si, offset CopyStatusCancel
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCall
	;
	; get destination drive number
	;
	mov	bx, handle DiskMenuResource	; bx:si = disk list
	mov	si, offset DiskMenuResource:DiskCopyDestList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessageCall			; al = dest drive number
						; ah = dest media descriptor
	pop	bx				; bl = source drive number
	mov	dh, bl				; dh = source
	mov	dl, al				; dl = dest

	;
	; Get greedy flag
	; 
	push	dx
	mov	bx, handle DiskMenuResource
	mov	si, offset DiskMenuResource:DiskCopyGreedyOption
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessageCall			; al <- DiskCopyFlags
	pop	dx

	mov	cx, SEGMENT_CS			; cx:bp = status callback
	mov	bp, offset CopyCallbackRoutine
	push	ax
	mov	ax, ACTIVE_TYPE_DISK_COPY
	call	DesktopMarkActive			; application will be active
	pop	ax
	jnz	done				; if already active, do nada
	mov	ss:[destinationInserted], FALSE
	call	DiskCopy
	call	MarkNotActive			; (preserves flags)
	jc	error				; error
	mov	ax, DISK_COPY_OK
error:
	cmp	ax, ERR_OPERATION_CANCELLED
	jne	afterCancelCheck
	cmp	ss:[destinationInserted], TRUE
	je	afterCancelCheck
	mov	ax, ERR_CANCEL_SANS_DEST
afterCancelCheck:
	;
	; make sure status box is down
	;
	push	ax				; save results
	mov	bx, handle CopyStatusBox
	mov	si, offset CopyStatusBox
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjMessageCall
	pop	ax				; retrieve results
	;
	; report disk copy error or success
	;
	segmov	ds, cs, si
	mov	si, offset CopyDiskErrorTable
FXIP<	mov	cx, (length CopyDiskErrorTable)*(size DesktopErrorTableEntry) >
FXIP<	call	SysCopyToStackDSSI		;ds:si = table on stack	>
	call	DesktopErrorReporter		; else, report error
FXIP<	call	SysRemoveFromStack	;release stack space		>
done:
	call	IndicateNotBusy
	ret
DesktopDiskCopyCopy	endm

;
; The following errors, which DiskCopy is capable of returning, should
; never come back to us, as we always pass valid data, to the best of our
; ability:
; 	- ERR_INVALID_SOURCE_DRIVE
; 	- ERR_INVALID_DEST_DRIVE
; 	- ERR_SOURCE_DRIVE_DOESNT_SUPPORT_DISK_COPY
; 	- ERR_DEST_DRIVE_DOESNT_SUPPORT_DISK_COPY
; 	- ERR_DRIVES_HOLD_DIFFERENT_FILESYSTEM_TYPES
; 	- FMT_CANNOT_FORMAT_FIXED_DISKS_IN_CUR_RELEASE
; 	- FMT_BAD_PARTITION_TABLE
; 	- FMT_ERR_READING_PARITION_TABLE
;	- FMT_ERR_NO_PARTITION_FOUND
;	- FMT_ERR_MULTIPLE_PRIMARY_PARTITIONS
;	- FMT_ERR_NO_EXTENDED_PARTITION_FOUND
;	- FMT_READY
;	- FMT_RUNNING
;	- FMT_ERR_DISK_UNAVAILABLE (applies only to network drives)
;

CopyDiskErrorTable	DesktopErrorTableEntry \
    <
	DISK_COPY_OK,
	CopyCopyOKStr,
	mask DETF_NOTICE
    >,
    <
	ERR_DISKCOPY_INSUFFICIENT_MEM,
	CopyNoMemErrStr,
	0
    >,
    <
	FMT_ERR_CANNOT_ALLOC_SECTOR_BUFFER,
	CopyNoMemErrStr,
	0
    >,
    <
	ERR_CANT_READ_FROM_SOURCE,
	CopyReadErrStr,
	0
    >,
    <
	ERR_CANT_WRITE_TO_DEST,
	CopyWriteErrStr,
	0
    >,
    <
	ERR_OPERATION_CANCELLED,
	CopyCancelledErrStr,
	mask DETF_NOTICE
    >,
    <
	ERR_CANCEL_SANS_DEST,
	CopyCancelSansDestErrStr,
	mask DETF_NOTICE
    >,
    <
	FMT_ABORTED,
	CopyFmtFormatAbortedErrStr,
	mask DETF_NOTICE
    >,
    <
	FMT_DRIVE_NOT_READY,
	CopyCantFormatDestErrStr,
	0
    >,
    <
	FMT_ERR_WRITING_BOOT,
	CopyCantFormatDestErrStr,
	0
    >,
    <
	FMT_ERR_WRITING_ROOT_DIR,
	CopyCantFormatDestErrStr,
	0
    >,
    <
	FMT_ERR_WRITING_FAT,
	CopyCantFormatDestErrStr,
	0
    >,
    <
	FMT_SET_VOLUME_NAME_ERR,
	CopyCantFormatDestErrStr,
	0
    >,
    <
	FMT_ERR_CANNOT_FORMAT_TRACK,
	CopyCantFormatDestErrStr,
	0
    >,
    <
	FMT_ERR_DISK_IS_IN_USE,
	CopyFmtErrDiskIsInUseStr,
	0
    >,
    <
	ERR_DISK_IS_IN_USE,
	CopyFmtErrDiskIsInUseStr,
	0
    >,
    <
	FMT_ERR_WRITE_PROTECTED,
	CopyFmtErrWriteProtectedStr,
	0
    >,
    <
    	ERR_SOURCE_DISK_INCOMPATIBLE_WITH_DEST_DRIVE,
	CopySourceDiskIncompatibleWithDestDriveStr,
	0
    >,
    <
    	ERR_SOURCE_DISK_NOT_FORMATTED,
	CopySourceDiskNotFormattedStr,
	0
    >,
    <NIL>

CheckHack < length  CopyDiskErrorTable eq 20>

endif		; if (not _FCAB)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskFormatFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle disk format

CALLED BY:	MSG_DISK_FORMAT_FORMAT

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskFormatFormat	method	DesktopClass, MSG_DISK_FORMAT_FORMAT
	;
	; See if should quick-format if possible.
	; 
	mov	bx, handle DiskMenuResource
	mov	si, offset DiskMenuResource:DiskFormatQuickMode
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessageCallFixup		; ax = DiskFormatFlags
	push	ax				; save DiskFormatFlags
	;
	; get drive number to format
	;
GM<	mov	bx, handle DiskMenuResource	; bx:si = disk list	>
GM<	mov	si, offset DiskMenuResource:DiskFormatSourceList	>
GM<	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION			>	
GM<	call	ObjMessageCallFixup		; al = drive number	>
ND<	mov	ax, ss:[ndClickedOnDrive]	; ah = media descriptor	>
	push	ax				; save 'em
	;
	; get media format to use
	;
	mov	bx, handle DiskMenuResource	; bx:si = media list
	mov	si, offset DiskMenuResource:DiskFormatMediaList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessageCallFixup		; al = media type
	pop	bx				; bl = drive
						; bh = media (max.)
	mov	ah, al				; ah = media
	mov	al, bl				; al = drive
	pop	cx				; DiskFormatFlags

if	_PCMCIA_FORMAT
	call	DesktopDiskFormatCheckForPCMCIASpecialCases
	jc	done
endif
	mov	bp,cx				;DiskFormatFlags
	mov	cx,ax				;MediaType,drive number
	mov	dh,bh				;maxMedia

	mov	ax,MSG_DISK_FORMAT_FORMAT_LOW
	mov	bx, handle 0
	call	ObjMessageNone 

if	_PCMCIA_FORMAT
done:
endif
	ret
DesktopDiskFormatFormat		endp


if	_PCMCIA_FORMAT

iniPCMCIAFormatCategory char "pcmciaFormat",0

iniPCMCIAFormatFlashCommandKey char "flashCommand",0
iniPCMCIAFormatFlashPreArgsKey char "flashPreArgs",0
iniPCMCIAFormatFlashPostArgsKey char "flashPostArgs",0

iniPCMCIAFormatATACommandKey char "ataCommand",0
iniPCMCIAFormatATAPreArgsKey char "ataPreArgs",0
iniPCMCIAFormatATAPostArgsKey char "ataPostArgs",0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskFormatCheckForPCMCIASpecialCases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for PCMCIA MediaTypes that require special processing.
		Performing processing if necessary

CALLED BY:	INTERNAL
		DesktopDiskFormatFormat

PASS:		ah - MediaType
		al - drive number
		bh - max. media
		cx - DiskFormatFlags

RETURN:		
		stc - don't call DesktopDiskFormatFormatLow
		clc - proceed as normal

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskFormatCheckForPCMCIASpecialCases		proc	near

command		local	PathName
args		local	PathName		;this should be big enough
driveNumber	local	byte
commandOffset	local	word
preArgsOffset	local	word
postArgsOffset	local	word

ForceRef	command
ForceRef	args
ForceRef	commandOffset
ForceRef	preArgsOffset
ForceRef	postArgsOffset

	.enter

	mov	driveNumber,al

	cmp	ah, MEDIA_FLASH
	je	mediaFlash

	cmp	ah, MEDIA_ATA
	je	mediaATA

	clc
done:
	.leave
	ret

mediaFlash:
	call	DesktopDiskFormatFormatFlash
	stc
	jmp	done

mediaATA:
	call	DesktopDiskFormatFormatATA
	stc
	jmp	done

DesktopDiskFormatCheckForPCMCIASpecialCases		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskFormatFormatFlash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup vardata and make dos call to format a FLASH pcmcia
		card

CALLED BY:	INTERNAL
		DesktopDiskFormatCheckForPCMCIASpecialCases

PASS:		ah = MEDIA_FLASH
		bh - max. media
		cx - DiskFormatFlags
		inherited stack frame
			driveNumber - set

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskFormatFormatFlash		proc	near

	uses	ax,bx,cx,dx,di,si
	.enter inherit DesktopDiskFormatCheckForPCMCIASpecialCases

	;   Let user know what is happening.
	;   This isn't an error but the it does what I want it to.
	;

	mov	ax,FORMAT_PCMCIA_EXIT_TO_DOS_LONG
	call	DesktopOKError

	;    Get Dos command and execute it
	;

	mov	cx,offset iniPCMCIAFormatFlashCommandKey
	mov	commandOffset, cx
	mov	cx,offset iniPCMCIAFormatFlashPreArgsKey
	mov	preArgsOffset, cx
	mov	cx,offset iniPCMCIAFormatFlashPostArgsKey
	mov	postArgsOffset, cx
	call	DesktopDiskFormatGetPCMCIAFormatCommand
EC <	jc	iniError
NEC <	jc	errorDB
	
	call	DesktopDiskFormatPCMCIADosExec
EC <	jc	dosExecError
NEC <	jc	errorDB


	;    Add vardata to the application object so that we
	;    will know on startup that we exited to format a flash card
	;

	push	bp
	sub	sp,size AddVarDataParams
	mov	bp,sp
	clrdw	ss:[bp].AVDP_data
	mov	ss:[bp].AVDP_dataSize, 0
	mov	ss:[bp].AVDP_dataType, ATTR_DESKTOP_FORMATTING_FLASH_CARD or \
				mask VDF_SAVE_TO_STATE	;duh
	mov	dx,size AddVarDataParams
	mov	bx,handle Desktop
	mov	si,offset Desktop
	mov	di,mask MF_STACK or mask MF_CALL
	mov	ax,MSG_META_ADD_VAR_DATA
	call	ObjMessage
	add	sp,size AddVarDataParams
	pop	bp					;locals

done:
	.leave
	ret

if	ERROR_CHECK
iniError:
WARNING	< WARNING_MISSING_INI_FILE_STUFF_FOR_PCMCIA_FORMAT >
	jmp	errorDB
dosExecError:
WARNING	< WARNING_MISSING_INI_FILE_STUFF_FOR_PCMCIA_FORMAT >
	jmp	errorDB
endif

errorDB:
	mov	ax,ERROR_UNABLE_TO_EXECUTE_DOS_PROGRAM_TO_FORMAT_PCMCIA
	call	DesktopOKError

	jmp	done

DesktopDiskFormatFormatFlash		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskFormatFormatATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup vardata and make dos call to format a ATA pcmcia
		card

CALLED BY:	INTERNAL
		DesktopDiskFormatCheckForPCMCIASpecialCases

PASS:		ah = MEDIA_ATA
		bh - max. media
		cx - DiskFormatFlags
		inherited stack frame
			driveNumber - set

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskFormatFormatATA		proc	near

	uses	ax,bx,cx,dx,di,si
	.enter inherit DesktopDiskFormatCheckForPCMCIASpecialCases

	;   Hey, there is an add sp,4 at errorDB: later in this 
	;   routine to clear the stack. If you change what is pushed
	;   then fix the add.
	;

	push	bx,cx			;passed info

	;   Let user know what is happening.
	;   This isn't an error but the it does what I want it to.
	;

	mov	ax,FORMAT_PCMCIA_EXIT_TO_DOS_SHORT
	call	DesktopOKError

	;    Get Dos command and execute it
	;

	mov	cx,offset iniPCMCIAFormatATACommandKey
	mov	commandOffset,cx
	mov	cx,offset iniPCMCIAFormatATAPreArgsKey
	mov	preArgsOffset,cx
	mov	cx,offset iniPCMCIAFormatATAPostArgsKey
	mov	postArgsOffset,cx
	call	DesktopDiskFormatGetPCMCIAFormatCommand
EC <	jc	iniError
NEC <	jc	errorDB
	
	call	DesktopDiskFormatPCMCIADosExec
EC <	jc	dosExecError
NEC <	jc	errorDB


	;    Add vardata to the application object so that we
	;    will know on startup that we exited to format an 
	;    ata card
	;

	pop	bx,cx			;passed info
	mov	al,driveNumber
	push	bp
	sub	sp,size DesktopFormattingATACard
	mov	di,sp
	sub	sp,size AddVarDataParams
	mov	bp,sp
	movdw	ss:[bp].AVDP_data,ssdi			;fptr to DFAC struct
	mov	ss:[bp].AVDP_dataSize, size DesktopFormattingATACard
	mov	ss:[bp].AVDP_dataType, ATTR_DESKTOP_FORMATTING_ATA_CARD or \
				mask VDF_SAVE_TO_STATE	;duh
	mov	ss:[di].DFAC_driveNumber,al
	mov	ss:[di].DFAC_maxMedia,bh
	mov	ss:[di].DFAC_diskFormatFlags,cx
	mov	dx,size AddVarDataParams
	mov	bx,handle Desktop
	mov	si,offset Desktop
	mov	di,mask MF_STACK or mask MF_CALL	;must do call
	mov	ax,MSG_META_ADD_VAR_DATA
	call	ObjMessage
	add	sp,size DesktopFormattingATACard + size AddVarDataParams
	pop	bp					;locals

done:
	.leave
	ret

if	ERROR_CHECK
iniError:
WARNING	< WARNING_MISSING_INI_FILE_STUFF_FOR_PCMCIA_FORMAT >
	jmp	errorDB
dosExecError:
WARNING	< WARNING_MISSING_INI_FILE_STUFF_FOR_PCMCIA_FORMAT >
	jmp	errorDB
endif

errorDB:
	add	sp,4				;clear passed info
	mov	ax,ERROR_UNABLE_TO_EXECUTE_DOS_PROGRAM_TO_FORMAT_PCMCIA
	call	DesktopOKError

	jmp	done

DesktopDiskFormatFormatATA		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskFormatGetPCMCIAFormatCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in stack frame with command name and args

CALLED BY:	INTERNAL
		DesktopDiskFormatFormatFlash
		DesktopDiskFormatFormatATA

PASS:		
		inherited stack frame

RETURN:		
		clc - no error
		stc - couldn't find ini category or key or bad drive number

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskFormatGetPCMCIAFormatCommand		proc	near
	uses	ax,bx,cx,dx,di,si,ds,es
	.enter inherit DesktopDiskFormatCheckForPCMCIASpecialCases

	;    Get command to execute from ini file
	;

	push	bp				;locals
	mov	ax,ss
	mov	es,ax				;destination
	lea	di, command
	mov	si,offset iniPCMCIAFormatCategory
	mov	dx,commandOffset
	mov	cx,cs
	mov	ds,cx
	mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
		(size PathName shl offset IFRF_SIZE)
	call	InitFileReadString
	pop	bp				;locals
	jc	done				;bail if error
	
	;    Get arguments to put before the drive letter and 
	;    curse the boneheads at msystem while you are at it.
	;

	push	bp				;locals
	lea	di, args			;dest buffer offset
	mov	dx, preArgsOffset		
	mov	cx,cs
	mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
		(size PathName shl offset IFRF_SIZE)
	call	InitFileReadString
	pop	bp				;locals

	;   Put a space after the preArgs, if there are any
	;

	jcxz	getDriveName			;number of chars in pre args
	add	di,cx				;after preArgs
	mov	al,C_SPACE
	stosb

getDriveName:
	;    Put drive name plus : and a space at current position of args
	;

	mov	al,driveNumber
	neg	cx				;bytes in args already used
	add	cx, size args			;bytes available in args
	call	DriveGetName
	jc	done
	mov	ax,C_COLON or (C_SPACE shl 8)
	stosw
	
	;    Get args to use after driver letter from ini file
	;

	push	bp				;locals
	mov	dx, postArgsOffset
	mov	cx,cs
	mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
		(size PathName shl offset IFRF_SIZE)
	call	InitFileReadString
	pop	bp				;locals
	jc	noPostArgs

done:
	.leave
	ret

noPostArgs:
	;    If no postArgs then null terminate the args string
	;

	clr	al
	stosb
	clc					;success
	jmp	done

DesktopDiskFormatGetPCMCIAFormatCommand		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskFormatPCMCIADosExec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute the dos command in the passed stack frame to
		format or prepare for format a PCMCIA card

CALLED BY:	INTERNAL
		DesktopDiskFormatFormatFlash
		DesktopDiskFormatFormatATA

PASS:		inherited stack frame

RETURN:		
		clc - ok
			ax - Destroyed
		stc - couldn't run dos program
			ax - FileError
DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskFormatPCMCIADosExec		proc	near
	uses	bx,cx,si,di,ds,es
	.enter inherit DesktopDiskFormatCheckForPCMCIASpecialCases

	push	bp				;locals
	clr	bx				;no disk handle
	mov	ax,ss
	mov	ds,ax				;command string segment
	lea	si, command
	mov	es,ax				;args string segment
	lea	di, args
	clr	ax,bp,dx			;no execute path
	mov	cx,mask DEF_FORCED_SHUTDOWN
	call	DosExec
	pop	bp				;locals

	.leave
	ret
DesktopDiskFormatPCMCIADosExec		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopHandlePCMCIAFormatOnOpenComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for vardata that indicates that we shutdown to
		format a pcmcia card.
		

CALLED BY:	INTERNAL
		DesktopOpenComplete

PASS:		*ds:si - Desktop

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopHandlePCMCIAFormatOnOpenComplete		proc	far
	uses	ax,bx
	.enter

	mov	ax,ATTR_DESKTOP_FORMATTING_FLASH_CARD
	call	ObjVarFindData
	jc	mediaFlash

	mov	ax,ATTR_DESKTOP_FORMATTING_ATA_CARD
	call	ObjVarFindData
	jc	mediaATA

done:
	.leave
	ret

mediaFlash:
	call	DesktopCompletePCMCIAFlashFormat
	jmp	done

mediaATA:
	call	DesktopCompletePCMCIAATAFormat
	jmp	done

DesktopHandlePCMCIAFormatOnOpenComplete		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopCompletePCMCIAFlashFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete formatting of PCMCIA Flash card. Notify
		user of any error condition

CALLED BY:	INTERNAL
		DesktopHandlePCMCIAFormatOnOpenComplete

PASS:		*ds:si - Desktop
		ds:bx - ATTR_DESKTOP_FORMATTING_FLASH_CARD vardata

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopCompletePCMCIAFlashFormat		proc	near
	uses	ax,di,si,cx,dx
	.enter

	mov	ax,ATTR_DESKTOP_FORMATTING_FLASH_CARD
	call	ObjVarDeleteData

	mov	di,offset flashFormatTerminationCodes
	mov	si,offset flashFormatErrorNumbers
	mov	cx,length flashFormatTerminationCodes
	mov	dx,FORMAT_PCMCIA_FAILED_FOR_UNKNOWN_REASON
	call	DesktopDiskFormatDisplayPCMCIAFormatResults

	.leave
	ret
DesktopCompletePCMCIAFlashFormat		endp

	;    Success must be first entry in table
	;
flashFormatTerminationCodes byte \
	0,
	1,
	2,
	3,
	5,
	7,
	8,
	9,
	10,
	11,
	12,
	13,
	20,
	21,
	22,
	23,
	24,
	25,
	26,
	27,
	28,
	29,
	30,
	31

flashFormatErrorNumbers word \
	FORMAT_PCMCIA_FLASH_SUCCESSFUL,
	FORMAT_PCMCIA_WRITE_PROTECTED,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
	FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER


CheckHack <length flashFormatTerminationCodes eq length flashFormatErrorNumbers>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopCompletePCMCIAATAFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete formatting of PCMCIA ATA card. Notify
		user of any error condition

CALLED BY:	INTERNAL
		DesktopHandlePCMCIAFormatOnOpenComplete

PASS:		*ds:si - Desktop
		ds:bx - ATTR_DESKTOP_FORMATTING_ATA_CARD vardata

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopCompletePCMCIAATAFormat		proc	near
	uses	ax,bx,cx,dx,di,si
	.enter

	;    Get info needed to complete formating of card
	;

	mov	ch,MEDIA_ATA
	mov	cl,ds:[bx].DFAC_driveNumber
	mov	bp,ds:[bx].DFAC_diskFormatFlags
	ornf	bp, mask DFF_FORCE_ERASE
	mov	dh,ds:[bx].DFAC_maxMedia

	push	cx,dx,si			;formatting info, Desktop chunk
	mov	di,offset ataFormatTerminationCodes
	mov	si,offset ataFormatErrorNumbers
	mov	cx, length ataFormatTerminationCodes
	mov	dx,PARTITION_PCMCIA_ATA_FAILED
	call	DesktopDiskFormatDisplayPCMCIAFormatResults
	pop	cx,dx,si			;formating info, Desktop chunk
	jnc	nukeVarData	

	;    Complete formatting of card on the process thread
	;

	call	GeodeGetProcessHandle
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_DISK_FORMAT_FORMAT_LOW
	call	ObjMessage



nukeVarData:
	mov	ax,ATTR_DESKTOP_FORMATTING_ATA_CARD
	call	ObjVarDeleteData

	.leave
	ret
DesktopCompletePCMCIAATAFormat		endp


	;    Success must be first entry in table
	;

ataFormatTerminationCodes byte \
	0
ataFormatErrorNumbers word \
	0					;don't display anything

CheckHack <length ataFormatTerminationCodes eq length ataFormatErrorNumbers>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskFormatDisplayPCMCIAFormatResults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dos termination code and display success or
		failure messages.

CALLED BY:	INTERNAL

PASS:		di - offset from cs to child termination code table
		si - offset from cs to DesktopErrors table
		cx - length in bytes of child termination code table
		dx - DesktopErrors number to use if parent
			termination code is non zero or child termination
			code cannot be found

RETURN:		
		stc - success
		clc - fail

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskFormatDisplayPCMCIAFormatResults		proc	near
	uses	ax,bx,cx,dx,di,si,es

termCode	local	byte

	.enter

	;    Get termination code
	;

	mov	ah,0x4d			
	call	FileInt21

	mov	termCode,ah			;parent termination code
	tst	ah
	jnz	unknownFailure
	mov	termCode,al			;child termination code

	;    Search termination code table
	;

	segmov	es,cs
	mov	bx,di				;save original offset
	repne	scasb
	jnz	unknownFailure

	;   Convert byte offset that is one byte past found 
	;   termination code to word offset and point into 
	;   DesktopErrors table.
	;

	sub	di,bx				;subtract original offset
	dec	di
	shl	di,1
	add	si,di

	;    Get DesktopErrors from table. If it is zero then
	;    bail with out displaying anything
	;

	mov	ax,es:[si]
	tst	ax
	jz	noError

	;    If was first "error" in table, then we were actually
	;    successful.
	;

	tst	di
	jnz	failureOKError

	call	DesktopOKError

noError:
	stc

done:
	.leave
	ret

unknownFailure:
	mov	ax,dx
failureOKError:
	clr	dx					;assume no string block
	cmp	ax,FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER
	je	createNumberString
failureError:
	call	DesktopOKError
failure:
	clc
	jmp	done


createNumberString:

	;    Alloc a block and put the string representing the numeric
	;    error in it. This is for display with DesktopOKError.
	;

	mov	cl,termCode
	call	CreateNumericStringBlock
	jc	failure
	jmp	failureError



DesktopDiskFormatDisplayPCMCIAFormatResults		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNumericStringBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block and put the asiic termination code string in it

CALLED BY:	INTERNAL
		DesktopDiskFormatDisplayPCMCIAFormatResults

PASS:		
		cl - termination code

RETURN:		
		clc - block created
			dx - block handle
		stc - block not created
			dx - 0

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNumericStringBlock		proc	near
	uses	ax,bx,cx,es
	.enter

	mov	dl,cl				;save termination code
	mov	ax,UHTA_NULL_TERM_BUFFER_SIZE
	mov	cx,mask HF_SHARABLE or (mask HAF_LOCK shl 8)
	call	MemAlloc
	jc	failed
	mov	es,ax	
	mov	al,dl				;term code low word low byte
	clr	ah				;term code low word high byte
	clr	dx,di			;term code high word, buffer offset
	mov	cx,mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	call	MemUnlock
	mov	dx,bx
	clc
done:
	.leave
	ret

failed:
	clr	dx
	stc
	jmp	done

CreateNumericStringBlock		endp



endif	;_PCMCIA_FORMAT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskFormatFormatLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a disk using DiskFormat given the media, drive, etc.
		This routine does not perform any prep work, such as
		partitioning MEDIA_ATA cards.

CALLED BY:	INTERNAL
		DesktopDiskFormatFormat

PASS:		ch - MediaType
		cl - drive number
		dh - max. media
		bp - DiskFormatFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/13/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskFormatFormatLow method DesktopClass, MSG_DISK_FORMAT_FORMAT_LOW
	uses	ax,cx,dx,bp
	.enter

	call	IndicateBusy

	push	bp				;DiskFormatFlags

	mov	ax,cx				;MediaType, drive numer
	mov	bh,dh				;max media

	;
	; warn user about formatting low-density disks in high-density drive
	;	al = drive
	;	ah = media
	;	bh = max. media
	;
	cmp	bh, MEDIA_1M2			; 1.2M?
	jne	no1M2Warning			; nope, no warning needed
	cmp	ah, MEDIA_1M2			; formatting as 1.2M?
	je	no1M2Warning			; yes, no warning needed
	push	ax				; save drive/media
	mov	ax, WARNING_FORMAT_LO_IN_HI	; else, give warning
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES
	pop	ax				; retreive drive/media
	jne	done_JMP_pop
no1M2Warning:

	;
	; user wants to format, prompt for volume name
	;
askForName:
	push	ax				; save drive, media
	mov	bx, handle DiskMenuResource
	mov	si, offset FormatVolumeEntry
	;
	; if nullVolumeName != 0, then the code for XIP have to change too.
	;
NOFXIP <	mov	dx, cs			; dx:bp = null string	>
NOFXIP <	mov	bp, offset nullVolumeName			>
FXIP <		clr	bp						>
FXIP <		push	bp						>
FXIP <		mov	dx, ss						>
FXIP <		mov	bp, sp		;dx:bp = null str on stack	>
	call	CallFixupSetText		; clear last volume name
FXIP <		pop	bp						>
	mov	{byte} ss:[formatVolumeName], 0	; clear volume name buffer

SBCS <	mov	{byte} ss:[formatVolumeName], 0	; clear volume name buffer>
DBCS <	mov	{wchar} ss:[formatVolumeName], 0	; clear volume name buffer>

	mov	si, offset FormatVolumeBox
	call	UserDoDialog			; put up volume name box
						; (ax = 0 if DETACH)
	cmp	ax, OKCANCEL_OK
	pop	ax				; retrieve media, drive
	je	111$				; continue
done_JMP_pop:
	pop	ax				; discard DiskFormatFlags
	jmp	done				; user CANCEL'ed
111$:
	;
	; get volume entered
	;
	push	ax				; save drive, media
FXIP<	push	ds							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	dx, ds				; dx = dgroup		>
FXIP<	pop	ds							>
	mov	bx, handle DiskMenuResource
	mov	si, offset FormatVolumeEntry
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
NOFXIP<	mov	dx, segment dgroup					>
	mov	bp, offset formatVolumeName	; return volume name in buffer
	call	ObjMessageCallFixup		; get volume name
EC <	cmp	cx, VOLUME_NAME_LENGTH					>
EC <	ERROR_A	ERROR_COPY_FORMAT_DISK				>
	;
	; fix-up entered volume name
	;
	push	ds
NOFXIP<	mov	si, segment dgroup					>
FXIP<	GetResourceSegmentNS dgroup, ds					>
FXIP<	segmov	es, ds, si						>
	mov	ds, si				; ds:si = volume name
	mov	es, si
	mov	si, offset formatVolumeName
spaceLoop:
SBCS <	lodsb					; nuke leading spaces	>
DBCS <	lodsw					; nuke leading spaces	>
SBCS <	cmp	al, ' '							>
DBCS <	cmp	ax, ' '							>
	je	spaceLoop
	dec	si				; point at first non-space
DBCS <	dec	si							>
	mov	di, si				; es:di = final volume name
						; ds:si = volume name
	call	CheckVolumeName			; C clr if okay, C set if error
						;	reported (ax = from
						;	DesktopOKError if C=1)
	pop	ds
	jc	badName
	;
	; if no volume name entered, smash user's head with brick
	;
SBCS <	cmp	{byte} ss:[formatVolumeName], 0	; null name?		>
DBCS <	cmp	{wchar} ss:[formatVolumeName], 0	; null name?	>
	jne	goodName			; nope, let user be
	mov	ax, WARNING_DISK_FORMAT_NO_NAME
	call	DesktopYesNoWarning		; harrass user
	cmp	ax, YESNO_YES			; wants to have no name?
	je	goodName			; yes, let it continue
badName:
	xchg	bx, ax				; bx = answer (1-byte inst.)
	pop	ax				; else, retrieve media
	cmp	bx, DESK_DB_DETACH		; detaching?
	je	done_JMP_pop			; yes, no mas
	jmp	askForName			; else, enter name again

goodName:
	;
	; clear percentage done field in format status box
	;
	clr	ax				; 0% done
	call	FormatCallbackRoutine
	;
	; close all Folder Windows for this disk, if any
	;
	pop	ax				; al = drive number
	push	ax
	call	DiskRegisterDiskSilently
	jc	afterRegister
	call	FormatVerifyDestroyDest		; can we clobber src disk?
						; (closes relevant Folder
						;	Windows if so)
	tst	ax
	jnz	doneJNZwPop			; if no destroy dest, exit
afterRegister:
	;
	; put up format status box
	;
	push	bx				; save disk handle (or 0)
	;
	; enable cancel button
	;
	clr	ss:[cancelOperation]		; clear cancel flag
	clr	ss:[cancelMonikerToChange]	; no moniker to change
	mov	bx, handle FormatStatusCancel
	mov	si, offset FormatStatusCancel
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCallFixup

	mov	bx, handle DiskMenuResource
	mov	si, offset FormatStatusBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	push	di				; save volume name (es:di)
	call	ObjMessageCallFixup
	pop	di
	;
	; finally, format disk
	;
	mov	ax, ACTIVE_TYPE_DISK_FORMAT
	call	DesktopMarkActive			; application will be active
	pop	bx
doneJNZwPop:
	pop	ax				; retrieve drive, media
	pop	bp				; retrieve DiskFormatFlags
	jnz	doneJMP				; if cannot mark, then detaching
						;	already and status will
						;	be removed by detaching
	;
	; set path to avoid causing bogus "disk-in-use" errors if our
	; current path just happens to be on the disk we are about to
	; format (we allow formatting disks with open folder windows)
	;
	push	ax
	mov	ax, SP_TOP
	call	FileSetStandardPath
	pop	ax


	mov	cx, SEGMENT_CS			; cx:dx = status callback
	mov	dx, offset FormatCallbackRoutine
						; bx is disk handle or 0, to
						;  indicate disk is known to
						;  be unformatted
	mov	si, offset formatVolumeName	; ds:si <- volume name
 	call	DiskFormat
	call	MarkNotActive			; application activity done
						;	(preserves flags)
	;
	; remove status box
	;
	pushf					; save status
	push	ax, si, di, dx, cx		; save error code, sizes
	mov	bx, handle DiskMenuResource
	mov	si, offset FormatStatusBox
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjMessageFixup
	pop	ax, si, di, dx, cx		; restore error code, sizes
	popf					; restore status
	jnc	success				; success!
	;
	; report format error
	;	(if detach is waiting for us, don't report error -
	;	 "obscure case")
	;
	segmov	ds, cs, si
	mov	si, offset FormatDiskErrorTable
if FULL_EXECUTE_IN_PLACE
	mov	cx, (length FormatDiskErrorTable)*(size DesktopErrorTableEntry)
	call	SysCopyToStackDSSI		;ds:si = table on stack
endif
	call	DesktopErrorReporter		; else, report error
						;	(will not put up box
						;		if detaching)
FXIP <	call	SysRemoveFromStack				>
doneJMP:
	jmp	short done

success:
	;
	; format succesful
	;	si:di = bytes good
	;	dx:cx = bytes bad
	;	(if detach is waiting for us, don't put up box)
	;
	cmp	ss:[willBeDetaching], TRUE	; detach waiting?
	je	done				; yes, no box
	cmp	ss:[detachActiveHandling], TRUE	; detach-while-active box up?
	je	done				; yes, no box
	mov	ax, SST_NOTIFY
	call	UserStandardSound
	push	si, di				; save good bytes
	push	dx, cx				; save bad bytes
	add	di, cx
	adc	si, dx
	mov	dx, di				; ax:dx = total
	mov	ax, si
	mov	si, offset FormatSizesText1
	call	ConvertAndShowSize
	pop	ax, dx				; ax:dx = bad
	mov	si, offset FormatSizesText2
	call	ConvertAndShowSize
	pop	ax, dx				; ax:dx = good
	mov	si, offset FormatSizesText3
	call	ConvertAndShowSize
	mov	bx, handle DiskMenuResource
	mov	si, offset FormatDoneBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageNone
done:


	call	IndicateNotBusy

	.leave
	ret
DesktopDiskFormatFormatLow		endp


ife FULL_EXECUTE_IN_PLACE
LocalDefNLString nullVolumeName <0>
endif



;
; pass:
;	bx = disk handle of old source disk
;
; return:
;	ax = 0 to continue
;	ax <> 0 to cancel
; destroy:
;	nothing
;
FormatVerifyDestroyDest	proc	near
	uses	dx, si, di, ds, si
	.enter
	call	DiskGetDrive			; al = drive
	mov	dl, al				; dl = drive
						; bx = disk handle
	mov	ax, DCC_VERIFY_DEST_DESTRUCTION	; use this handy code
	call	CopyCallbackRoutine		; ax = 0 to continue
	.leave
	ret
FormatVerifyDestroyDest	endp

ConvertAndShowSize	proc	near
SBCS <	sub	sp, 20							>
DBCS <	sub	sp, 20*(size wchar)					>
	mov	di, sp
	segmov	es, ss
	call	ASCIIizeDWordAXDX
	mov	dx, ss				; dx:bp = ASCII bytes
	mov	bp, sp
	mov	bx, handle DiskMenuResource	; bx:si = size text object
	call	CallFixupSetText
SBCS <	add	sp, 20							>
DBCS <	add	sp, 20*size(wchar)					>
	ret
ConvertAndShowSize	endp

; The following errors, which DiskFormat is capable of returning, should
; never come back to us, as we always pass valid data, to the best of our
; ability:
; 	- FMT_CANNOT_FORMAT_FIXED_DISKS_IN_CUR_RELEASE
; 	- FMT_BAD_PARTITION_TABLE
; 	- FMT_ERR_READING_PARITION_TABLE
;	- FMT_ERR_NO_PARTITION_FOUND
;	- FMT_ERR_MULTIPLE_PRIMARY_PARTITIONS
;	- FMT_ERR_NO_EXTENDED_PARTITION_FOUND
;	- FMT_READY
;	- FMT_RUNNING
;	- FMT_ERR_DISK_UNAVAILABLE (applies only to network drives)
;
FormatDiskErrorTable	DesktopErrorTableEntry \
    <
    	FMT_ABORTED,
	FmtFormatAbortedErrStr,
	mask DETF_NOTICE
    >,
    <
	FMT_DRIVE_NOT_READY,
	FmtDriveNotReadyErrStr,
	0
    >,
    <
	FMT_ERR_WRITING_BOOT,
	FmtErrWritingBootErrStr,
	0
    >,
    <
	FMT_ERR_WRITING_ROOT_DIR,
	FmtErrWritingRootDirErrStr,
	0
    >,
    <
	FMT_ERR_WRITING_FAT,
	FmtErrWritingFatErrStr,
	0
    >,
    <
	FMT_SET_VOLUME_NAME_ERR,
	FmtErrSetVolumeNameErrStr,
	0
    >,
    <
	FMT_ERR_DISK_IS_IN_USE,
	FmtErrDiskIsInUseStr,
	0
    >,
    <
	FMT_ERR_WRITE_PROTECTED,
	FmtErrWriteProtectedStr,
	0
    >,
    <
	FMT_ERR_CANNOT_ALLOC_SECTOR_BUFFER,
	FmtErrNoMemStr,
	0
    >,
    <
        FMT_ERR_CANNOT_FORMAT_TRACK,
	FmtErrCantFormatTrackStr,
	0
    >,
    <NIL>

CheckHack < length  FormatDiskErrorTable eq 11 >

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatCallbackRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine for disk format to report status

CALLED BY:	format code

PASS:		ax = percentage done

RETURN:		carry set to CANCEL
		carry clear to continue

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/23/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatCallbackRoutine	proc	far
	uses	ax, bx, cx, dx, ds, si, es, di, bp
	.enter
	;
	; show percentage done
	;
	mov	dx, ax				; ax:dx = percent
	clr	ax
	mov	di, offset formatStatusBuffer	; es:di = buffer for string
	mov	bp, di
	segmov	es, ss
	call	ASCIIizeDWordAXDX		; es:di = null-term at end
if DBCS_PCGEOS
	mov	ax, '%'
	stosw
	clr	ax
	stosw					; tack on percent sign and null
else
	mov	ax, '%' or (0 shl 8)
	stosw					; tack on percent sign and null
endif
	mov	dx, ss				; dx:bp = ASCII bytes
	mov	bx, handle DiskMenuResource	; bx:si = size text object
	mov	si, offset FormatStatusPercentage
	push	dx, bp				; save message params
	mov     ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr     cx                              ; null-terminated text
	call    ObjMessageNone			; don't use MF_CALL
	pop	dx, bp
	cmp	ss:[detachActiveHandling], TRUE	; detach-while-active box up?
	jne	40$				; nope
	cmp	ss:[activeType], ACTIVE_TYPE_DISK_FORMAT
	jne	40$				; nope
	mov	bx, handle ActiveFormatProgress	; if so, update progress there
	mov	si, offset ActiveFormatProgress
	mov     ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr     cx                              ; null-terminated text
	call    ObjMessageNone			; don't use MF_CALL
40$:
	;
	; check for cancel
	;
	clc					; assume no cancel
	cmp	ss:[cancelOperation], 0		; cancel?
	je	80$				; no
	mov	ss:[cancelOperation], 0		; else, clear flag
	stc					; 	and indicate cancel
80$:
	.leave
	ret
FormatCallbackRoutine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCallbackRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine for disk copy to report status, prompt
		for source and destination disks

CALLED BY:	copy routine

PASS/RETURN:

;DCC_GET_SOURCE_DISK
;	passed:
;		ax - DCC_GET_SOURCE_DISK
;		dl - 0 based drive number
;	callback routine to return:
;		ax = 0 to continue, non-0 to abort
;

;DCC_REPORT_NUM_SWAPS
;	passed:
;		ax - DCC_REPORT_NUM_SWAPS
;		dx - number of swaps required
;	callback routine to return:
;		ax = 0 to continue, non-0 to abort
;

;DCC_GET_DEST_DISK
;	passed:
;		ax - DCC_GET_DEST_DISK
;		dl - 0 based drive number
;	callback routine to return:
;		ax = 0 to continue, non-0 to abort
;

;DCC_VERIFY_DEST_DESTRUCTION
;	passed:
;		ax - DCC_REPORT_NUM_SWAPS
;		bx - disk handle of destination disk
;		dl - 0 based drive number
;		ds:si - name of destination disk
;	callback routine to return:
;		ax = 0 to continue, non-0 to abort
;

;DCC_REPORT_FORMAT_PCT
;	passed:
;		ax - DCC_REPORT_FORMAT_PCT
;		dx - percentage of destination disk formatted
;	callback routine to return:
;		ax = 0 to continue, non-0 to abort

;DCC_REPORT_READ_PCT
;	passed:
;		ax - DCC_REPORT_READ_PCT
;		dx - percentage of source disk read
;	callback routine to return:
;		ax = 0 to continue, non-0 to abort
;

;DCC_REPORT_WRITE_PCT
;	passed:
;		ax - DCC_REPORT_WRITE_PCT
;		dx - percentage of dest disk written
;	callback routine to return:
;		ax = 0 to continue, non-0 to abort
;

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/23/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyCallbackRoutine	proc	far
	uses	bx, cx, dx, si, di, ds, es, bp
	.enter
	clr	di
copyCallbackLoop:
	cmp	ax, cs:[copyCallbackTable][di]
	je	haveRout
	add	di, 2
EC <	cmp	di, COPY_CALLBACK_TABLE_SIZE				>
EC <	ERROR_Z	UNKNOWN_COPY_CALLBACK_VALUE				>
	jmp	short copyCallbackLoop
haveRout:
	mov	ax, cs:[copyCallbackRoutTable][di]
	call	ax
	.leave
	ret
CopyCallbackRoutine	endp

copyCallbackTable	label	word
ifndef GEOLAUNCHER
	word	DCC_GET_SOURCE_DISK
	word	DCC_REPORT_NUM_SWAPS
	word	DCC_GET_DEST_DISK
endif
	word	DCC_VERIFY_DEST_DESTRUCTION
ifndef GEOLAUNCHER
	word	DCC_REPORT_FORMAT_PCT
	word	DCC_REPORT_READ_PCT
	word	DCC_REPORT_WRITE_PCT
endif
COPY_CALLBACK_TABLE_SIZE equ ($-copyCallbackTable)

copyCallbackRoutTable	label	word
ifndef GEOLAUNCHER
	word	offset CopyCallbackGetSourceDisk
	word	offset CopyCallbackReportNumSwaps
	word	offset CopyCallbackGetDestDisk
endif
	word	offset CopyCallbackVerifyDestDestruction
ifndef GEOLAUNCHER
	word	offset CopyCallbackReportFormatPct
	word	offset CopyCallbackReportReadPct
	word	offset CopyCallbackReportWritePct

;
; pass:	dl = source drive
; return:	ax = 0 to continue
CopyCallbackGetSourceDisk	proc	near
	mov	ax, WARNING_DISK_COPY_SOURCE
	FALL_THRU	CopyCallbackGetDiskCommon
CopyCallbackGetSourceDisk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCallbackGetDiskCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the user for a disk

CALLED BY:	(INTERNAL) CopyCallbackGetSourceDisk,
			   CopyCallbackGetDestDisk
PASS:		ax	= message to pass to DesktopYesNoWarning
		dl	= drive number
RETURN:		ax	= 0 to continue
DESTROYED:	cx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyCallbackGetDiskCommon proc	near
SBCS <	mov	cx, DRIVE_NAME_MAX_LENGTH				>
DBCS <	mov	cx, DRIVE_NAME_MAX_LENGTH*2				>
	sub	sp, cx
	mov	di, sp
	segmov	es, ss
	push	ax
	mov	al, dl
	call	DriveGetName
	pop	ax
	jc	cancel

	segmov	ds, ss
	mov	dx, sp			; ds:dx <- drive name
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES		; acknowledged?
	mov	ax, 0			; assume so (preserve flag)
	je	done			; yes, return ax = 0
		CheckHack <WARNING_DISK_COPY_SOURCE ne -1>
		CheckHack <WARNING_DISK_COPY_DEST ne -1>
cancel:
	inc	ax			; else, return non-zero
done:
SBCS <	add	sp, DRIVE_NAME_MAX_LENGTH	; clear stack		>
DBCS <	add	sp, DRIVE_NAME_MAX_LENGTH*2	; clear stack		>
	ret
CopyCallbackGetDiskCommon endp

;
; pass:	dx = num swaps required
; return:	ax = 0 to continue
CopyCallbackReportNumSwaps	proc	near
SBCS <	sub	sp, 10							>
DBCS <	sub	sp, 10*(size wchar)					>
	clr	ax				; ax:dx = num swaps
	cmp	dx, 1
	je	done				; assume answer is yes if
						;  it will require only 1
						;  disk swap
	mov	di, ss
	mov	es, di
	mov	ds, di
	mov	di, sp
	call	ASCIIizeDWordAXDX
	mov	dx, sp				; ds:dx = num swaps
	mov	ax, WARNING_DISK_COPY_NUM_SWAPS
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES			; continue?
	mov	ax, 0				; assume so (preserve flag)
	je	done				; yes, return ax=0
	inc	ax				; else, return non-zero
done:
SBCS <	add	sp, 10							>
DBCS <	add	sp, 10*(size wchar)					>
	ret
CopyCallbackReportNumSwaps	endp

;
; pass:	dl = dest drive
; return:	ax = 0 to continue
CopyCallbackGetDestDisk	proc	near
	mov	ax, WARNING_DISK_COPY_DEST
	GOTO	CopyCallbackGetDiskCommon
CopyCallbackGetDestDisk	endp

endif

;
; pass:	bx = disk handle of dest. disk
;	dl = dest drive
; return:	ax = 0 to continue
;
CopyCallbackVerifyDestDestruction	proc	near
	;
	; Figure the name of the drive and the disk at once.
	; 
SBCS <	mov	cx, DRIVE_NAME_MAX_LENGTH+ size VolumeName		>
DBCS <	mov	cx, DRIVE_NAME_MAX_LENGTH*2+ size VolumeName		>
	sub	sp, cx
	segmov	es, ss, ax
	mov	ds, ax
	mov	di, sp		; es:di <- buffer
	mov	al, dl		; al <- drive number
	mov	dx, di		; ds:dx <- drive name, in case unnamed
	call	DriveGetName

	LocalNextChar esdi	; skip null-term
	dec	cx
DBCS <	dec	cx							>
	call	DiskGetVolumeName

	mov	ax, WARNING_DISK_COPY_DESTROY_DEST_NO_NAME
	call	DiskCheckUnnamed
	jc	50$
	mov	dx, di		; use disk name instead
	mov	ax, WARNING_DISK_COPY_DESTROY_DEST_NAME	; assume have disk name
50$:
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES			; acknowledged?
	mov	ax, 0				; assume so (preserve flag)
	je	done				; yes, return ax=0
	inc	ax				; else, return non-zero
done:
	; if destruction allowed, folders and tree will deal with getting
	; file-change notification of the disk having been formatted.

SBCS <	add	sp, DRIVE_NAME_MAX_LENGTH+size VolumeName		>
DBCS <	add	sp, DRIVE_NAME_MAX_LENGTH*2+size VolumeName		>
	ret
CopyCallbackVerifyDestDestruction	endp

ifndef GEOLAUNCHER		; no disk operations for GeoLauncher

;
; pass:
;	dx = pct of format done
; return:
;	ax = 0 to continue
CopyCallbackReportFormatPct	proc	near
	mov	ss:[destinationInserted], TRUE
	mov	cx, offset CopyStatusFormatMoniker
	mov	bp, offset ActiveCopyStatusFormatMoniker
	call	CopyCallbackReportPctCommon
	ret
CopyCallbackReportFormatPct	endp

;
; pass:
;	dx = pct of read done
; return:
;	ax = 0 to continue
CopyCallbackReportReadPct	proc	near
	mov	ss:[destinationInserted], FALSE
	mov	cx, offset CopyStatusReadingMoniker
	mov	bp, offset ActiveCopyStatusReadingMoniker
	call	CopyCallbackReportPctCommon
	ret
CopyCallbackReportReadPct	endp

;
; pass:
;	dx = pct of write done
; return:
;	ax = 0 to continue
CopyCallbackReportWritePct	proc	near
	mov	ss:[destinationInserted], TRUE
	mov	cx, offset CopyStatusWritingMoniker
	mov	bp, offset ActiveCopyStatusWritingMoniker
	call	CopyCallbackReportPctCommon
	ret
CopyCallbackReportWritePct	endp

;
; pass:
;	cx = chunk of moniker for CopyStatusGroup
;	bp = chunk of moniker for ActiveCopyProgressGroup
;	dx = percentage done (if > 100, zeros percentage fields without
;		bringing up box)
;
CopyCallbackReportPctCommon	proc	near
	cmp	dx, 100
	jbe	10$
	clr	dx				; zero percentage field
	jmp	short 20$
10$:
	push	dx			; save percentage
	push	bp			; save moniker for active box
	;
	; make sure correct moniker is showing.
	;
	; NOTE: do not MF_CALL these things, as ui thread might be blocked
	; on what we're doing in the filesystem.
	;
	mov	bx, handle CopyStatusGroup
	mov	si, offset CopyStatusGroup
	cmp	cx, ss:[copyStatusMoniker]	; correct moniker?
;
	je	17$				; yes, done
	mov	ss:[copyStatusMoniker], cx
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_NOW
	call	ObjMessageNone			; set desired moniker
;
17$:
	;
	; do the same for the active progress box, if needed
	;
	pop	cx				; cx <- desired moniker

	cmp	ss:[detachActiveHandling], TRUE	; detach-while-active box up?
	jne	117$				; nope, not needed
	cmp	ss:[activeType], ACTIVE_TYPE_DISK_COPY
	jne	117$				; nope, not needed

	mov	bx, handle ActiveCopyProgressGroup
	mov	si, offset ActiveCopyProgressGroup
	cmp	cx, ss:[activeCopyStatusMoniker]	; correct moniker?
;
	je	117$				; yes, done
	mov	ss:[activeCopyStatusMoniker], cx	; save moniker
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_NOW
	call	ObjMessageNone			; set desired moniker
;
;
117$:
	;
	; make sure box is up
	;
	mov	bx, handle CopyStatusBox
	mov	si, offset CopyStatusBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
; avoid deadlock possibility - brianc 12/26/90
;	call	ObjMessageCall
	call	ObjMessageNone
;
	pop	dx				; retrieve percentage
20$:
	;
	; show percentage done
	;
	clr	ax				; ax:dx = percent
	segmov	es, ss
	mov	di, offset formatStatusBuffer	; buffer must be FIXED
	mov	bp, di
	call	ASCIIizeDWordAXDX
if DBCS_PCGEOS
	mov	ax, '%'
	stosw					; tack on percent sign and null
	clr	ax
	stosw
else
	mov	ax, '%' or (0 shl 8)
	stosw					; tack on percent sign and null
endif
	mov	dx, ss				; dx:bp = ASCII bytes
	mov	bx, handle CopyStatusPercentage	; bx:si = size text object
	mov	si, offset CopyStatusPercentage
	push	dx, bp				; save message params
	mov     ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr     cx                              ; null-terminated text
	call    ObjMessageNone			; don't use MF_CALL
	pop	dx, bp				; retrieve message params
	cmp	ss:[detachActiveHandling], TRUE	; detach-while-active box up?
	jne	40$				; nope
	cmp	ss:[activeType], ACTIVE_TYPE_DISK_COPY
	jne	40$				; nope
	mov	bx, handle ActiveCopyProgress	; bx:si = detach-while-active
	mov	si, offset ActiveCopyProgress	;	progress string
	mov     ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr     cx                              ; null-terminated text
	call    ObjMessageNone			; don't use MF_CALL
40$:
	;
	; check for cancel
	;
	clr	ax				; assume no cancel
	cmp	ss:[cancelOperation], 0		; cancel?
	je	80$				; no
	mov	ss:[cancelOperation], 0		; else, clear flag
	inc	ax				; 	and indicate cancel
80$:
	ret
CopyCallbackReportPctCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskCopySourceDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle click on disk copy source drive - enable/disable
		matching destination drives

CALLED BY:	MSG_DISK_COPY_SOURCE_DRIVE send by disk copy
		source drive GenList object

PASS:		cx = identifier of the exclusive drive in source list

RETURN:		carry clear (so carry error handling will not be triggered)
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskCopySourceDrive	method	DesktopClass, 
					MSG_DISK_COPY_SOURCE_DRIVE

	sourceDrive	local	byte
	sourceMedia	local	byte
	entryPosition	local	word

	.enter

	call	ShowHourglass

						; cl = drive number
						; ch = media descriptor
	mov	sourceDrive, cl
	mov	sourceMedia, ch			; save it
	;
	; loop through all destination drives, enabling/disabling their
	; buttons if the have compatible/incompatible media
	;
	clr	entryPosition			; first position in dest. list
driveLoop:
	mov	cx, entryPosition		; position to get
	mov	bx, handle DiskMenuResource	; bx:si = destination list
	mov	si, offset DiskMenuResource:DiskCopyDestList
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	push	bp
	call	ObjMessageCall			; cx:dx = child's OD
	pop	bp
	jc	done				; no more children

	mov	bx, cx				; bx:si = drive clicked on
	mov	si, dx
	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	push	bp
	call	ObjMessageCall			; al = drive number
						; ah = media descriptor
	pop	bp

	mov	di, MSG_GEN_SET_ENABLED	; assume compatible

	;
	; See if source drive supports default media of dest drive, first
	; 
	push	ax
	mov	al, sourceDrive
	call	DriveTestMediaSupport
	pop	ax
	push	ax
	jnc	10$				; yup

	;
	; How about the other way around?
	; 
	push	ax				; save identifier
	mov	ah, sourceMedia			; al = dest drv, ah = src media
	call	DriveTestMediaSupport		; compatible?
	jnc	10$				; yes
	mov	di, MSG_GEN_SET_NOT_ENABLED	; not compatible
10$:
	mov	ax, di				; ax = method
	mov	dl, VUM_NOW			; update
	push	bp
	call	ObjMessageCall			; enable/disable button
	pop	bp
	;
	; if this is source drive, select it
	;	ax = identifier
	;
	pop	ax				; restore identifier
	cmp	al, sourceDrive			; is this source drive?
	jne	20$				; no
	push	bp
	mov	cx, ax				; cx = identifier of button
	mov	bx, handle DiskMenuResource	; bx:si = GenItemGroup
	mov	si, offset DiskMenuResource:DiskCopyDestList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjMessageCall			; select it
	pop	bp
20$:
	inc	entryPosition			; do next one
	jmp	short driveLoop

done:
	call	HideHourglass
	clc					; no error

	.leave

	ret
DesktopDiskCopySourceDrive	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDiskFormatSourceDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle click on disk format source drive - enable/disable
		matching media types

CALLED BY:	MSG_DISK_FORMAT_SOURCE_DRIVE send by disk format
		source drive GenList object

PASS:		cx = identifier of the exclusive drive in format source list
			(cl is drive number, ch is media descriptor)
RETURN:		carry clear (so carry error handling will not be triggered)

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDiskFormatSourceDrive	method	DesktopClass,
						MSG_DISK_FORMAT_SOURCE_DRIVE

	sourceDrive	local	byte
	sourceMedia	local	byte

	.enter

	call	ShowHourglass

						; cl = drive number
						; ch = media descriptor
	mov	sourceDrive, cl			; save 'em
	mov	sourceMedia, ch
	clr	di				; start of table
nextMedia:
	mov	ax, cs:[DiskFormatMediaDescriptorTable][di]	; al = media
	mov	ah, sourceDrive
	xchg	al, ah				; al = drive, ah = media
	call	DriveTestMediaSupport		; is media available for drive?
	mov	ax, MSG_GEN_SET_USABLE	; assume so
	jnc	burp				; if so, set usable
	mov	ax, MSG_GEN_SET_NOT_USABLE	; else, set not usable
burp:
	mov	bx, handle DiskMenuResource
	mov	si, cs:[DiskFormatMediaButtonTable][di]
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE	; update later
	push	di				; save table offset
	call	ObjMessageNone			; set button status
						; (preserves bp)
	pop	di				; retrieve table offset
	;
	; select default media for this drive
	;
	mov	ax, cs:[DiskFormatMediaDescriptorTable][di]	; al = media
	cmp	al, sourceMedia			; is this it?
	jne	notDefault
	clr	ah				; ax = media type
	push	bp, di
	mov	cx, ax				; cx = media type
	mov	bx, handle DiskFormatMediaList	; bx:si = format source list
	mov	si, offset DiskFormatMediaList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjMessageCall			; select it
	pop	bp, di
notDefault:
	add	di, 2				; move to next entry
	cmp	di, DISK_FORMAT_MEDIA_TABLE_SIZE	; end of table?
	jne	nextMedia			; no, do next media

	call	HideHourglass
	clc					; no errors

	.leave

	ret
DesktopDiskFormatSourceDrive	endm

;
; tables mapping media descriptors to buttons in .ui file
;

DiskFormatMediaDescriptorTable	label	word
	word	MEDIA_160K
	word	MEDIA_180K
	word	MEDIA_320K
	word	MEDIA_360K
	word	MEDIA_720K
	word	MEDIA_1M2
	word	MEDIA_1M44
	word	MEDIA_2M88
	word	MEDIA_FIXED_DISK
	word	MEDIA_CUSTOM
	word	MEDIA_SRAM
	word	MEDIA_ATA
if	_PCMCIA_FORMAT
	word	MEDIA_FLASH
endif
if PZ_PCGEOS
;	word	MEDIA_640K
	word	MEDIA_1M232
endif
	
DISK_FORMAT_MEDIA_TABLE_SIZE	equ	($ - DiskFormatMediaDescriptorTable)

DiskFormatMediaButtonTable	label	word
	word	offset DiskMenuResource:DiskFormatMedia160
	word	offset DiskMenuResource:DiskFormatMedia180
	word	offset DiskMenuResource:DiskFormatMedia320
	word	offset DiskMenuResource:DiskFormatMedia360
	word	offset DiskMenuResource:DiskFormatMedia720
	word	offset DiskMenuResource:DiskFormatMedia1M2
	word	offset DiskMenuResource:DiskFormatMedia1M44
	word	offset DiskMenuResource:DiskFormatMedia2M88
	word	offset DiskMenuResource:DiskFormatMediaFixed
	word	offset DiskMenuResource:DiskFormatMediaCustom
	word	offset DiskMenuResource:DiskFormatMediaSRAM
	word	offset DiskMenuResource:DiskFormatMediaATA
if	_PCMCIA_FORMAT
	word	offset DiskMenuResource:DiskFormatMediaFLASH
endif
if PZ_PCGEOS
;	word	offset DiskMenuResource:DiskFormatMedia640
	word	offset DiskMenuResource:DiskFormatMedia1M232
endif

if _GMGRONLY		; no disk operations for GeoLauncher

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskStartDiskRenameBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up rename disk box with useful drive

CALLED BY:	MSG_META_START_DISK_RENAME_BOX

PASS:		es - segment of DesktopClass

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/24/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskStartDiskRenameBox	method	DesktopClass, MSG_META_START_DISK_RENAME_BOX
	call	ShowHourglass
	;
	; get current disk, in case of no target
	;
	mov	bx, handle DiskRenameBox	; bx:si = rename box
	mov	si, offset DiskRenameBox
	mov	ax, MSG_FOB_GET_DISK_HANDLE
	call	ObjMessageCall			; cx = disk handle
	tst	cx
	jnz	haveOldDisk
NOFXIP<	segmov	es, dgroup, cx						>
FXIP  <	mov	cx, bx							>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP  <	mov	bx, cx							>


	mov	cx, es:[geosDiskHandle]		; just use GEOS disk handle

haveOldDisk:

	push	cx				; save it
	;
	; get current target drive
	;
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_META_GET_TARGET_EXCL
	call	ObjMessageCallFixup		; cx:dx = target GenDisplay
	pop	bx				; bx = current disk handle
	jcxz	haveDisk			; no target, use current
if not _ZMGR
if _TREE_MENU
	cmp	cx, handle TreeWindow
	jne	notTree
	cmp	dx, offset TreeWindow
	jne	notTree
	;
	; tree is target
	;
	mov	bx, handle TreeObject
	mov	si, offset TreeObject
	jmp	diskCommon
	;
	; get target folder
	;
notTree:
endif		; if _TREE_MENU
endif
	mov     bx, ss:[targetFolder]           ; bx:si = target folder object
	mov     si, offset FolderObjectTemplate:FolderObject	; common offset
if not _ZMGR
if _TREE_MENU
diskCommon:
endif		; if _TREE_MENU
endif
	sub	sp, size DiskInfoStruct
	mov	dx, ss				; dx:bp = buffer
	mov	bp, sp
	mov	ax, MSG_GET_DISK_INFO
	call	ObjMessageCallFixup		; fill buffer, ax <- disk
	mov_tr	bx, ax				; bx <- disk handle
	add	sp, size DiskInfoStruct

haveDisk:
	;
	; show this drive in rename drive list and its name in name area
	;	bx = disk handle
	;

	;
	; make sure that we've got an entry in the DiskRenameDriveList before
	; trying to set it
	;
	push	bx
	call	DiskGetDrive			; al = drive
	call	DriveGetDefaultMedia		; ah = media
	mov	cx, ax				; cx = identifier
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	mov	bx, handle DiskRenameDriveList
	mov	si, offset DiskRenameDriveList
	call	ObjMessageCallFixup
	pop	bx
	jc	setRenameDisk			; found, set it

	;
	; curent disk not found in DiskRenameDriveList, try currently selected
	; disk in DiskRenameDriveList
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle DiskRenameDriveList
	mov	si, offset DiskRenameDriveList
	call	ObjMessageCallFixup		; ax = current selection
	cmp	ax, GIGS_NONE
	je	dontSet				; nothing found
	mov	cx, ax				; cx = identifer
	mov	ax, MSG_DISK_RENAME_DRIVE
	mov	bx, handle 0
	clr	di
	call	ObjMessage
	jmp	short dontSet			; finish up

setRenameDisk:
	push	bx
	call	SetRenameDriveButton
	pop	bx
	call	SetAndStoreRenameDisk		; show its name
dontSet:
	;
	; bring up rename box
	;
	mov	bx, handle DiskRenameBox
	mov	si, offset DiskRenameBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageFixup
	call	HideHourglass
	ret

DiskStartDiskRenameBox	endm

endif		; if _GMGRONLY


if not _FCAB

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskRenameRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rename disk

CALLED BY:	MSG_DISK_RENAME

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/05/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskRenameRename	method	DesktopClass, MSG_DISK_RENAME
	call	ShowHourglass
	;
	; get new volume name
	;
	mov	bx, handle DiskRenameDestName
	mov	si, offset DiskRenameDestName
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx				; return global block
	call	ObjMessageCallFixup		; cx <- block
	mov	bx, cx
	push	bx				; save volume name block
	call	MemLock
	mov	ds, ax
	;
	; get disk handle
	;
	mov	bx, handle DiskRenameBox	; bx:si = rename box
	mov	si, offset DiskRenameBox
	mov	ax, MSG_FOB_GET_DISK_HANDLE
	call	ObjMessageCall			; cx = disk handle
	mov	bx, cx				; bx = disk handle
	clr	si				; ds:si = new name
	call	CheckVolumeName			; C clr if okay, C set if error
						;	reported (ax = from
						;	DesktopOKError if C=1)
	jc	afterRename			; error, done, allows new name
	call	DiskSetVolumeName
	jnc	afterRename
	cmp	ax, ERROR_WRITE_PROTECTED	; useful error?
	je	44$				; yes, use it
	cmp	ax, ERROR_INVALID_NAME
	je	44$
	mov	ax, ERROR_DISK_RENAME		; report generic disk rename
						;	error, as DOS doesn't
						;	give useful error code
44$:
	call	DesktopOKError			; put up box and wait
afterRename:
	pop	bx				; free volume name block
	pushf					; save rename status
	call	MemFree
	popf					; retrieve rename status
	jc	done				; if error, don't dismiss
	;
	; broadcast disk name change
	;	cx = disk handle of disk renamed
	;
	mov	dx, cx
	mov	ax, MSG_UPDATE_DISK_NAME	; disk name changed for DX
	mov	di, mask MF_FORCE_QUEUE		; do later
	call	SendToTreeAndBroadcast
	;
	; close rename disk box (since operation successful)
	;
	mov	bx, handle DiskRenameBox
	mov	si, offset DiskRenameBox
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjMessageNone
done:
	call	HideHourglass
	ret
DiskRenameRename	endm

endif		; if (not _FCAB)

;
; pass:
;	ds:si - volume name
; return:
;	carry clear if no error
;	carry set if error (error reported)
;		AX = error code
;
CheckVolumeName	proc	near
	uses	si
	.enter
checkChar:
if DBCS_PCGEOS
	lodsw
	cmp	ax, 0
else
	lodsb
	cmp	al, 0				; end of name?
endif
	jz	done				; yes, carry clear
	call	CheckDOSVolumeNameChar		; Z=1 if bad char
	jne	checkChar
	mov	ax, ERROR_BAD_VOLUME_NAME
	call	DesktopOKError
	stc					; indicate error
done:
	.leave
	ret
CheckVolumeName	endp

;
; al = character to check
;
CheckDOSVolumeNameChar	proc	near
	uses	es, di, cx
	.enter
	segmov	es, cs, di
	mov	di, offset DOSBadVolumeCharsTable
	mov	cx, DOS_BAD_VOLUME_CHARS_LENGTH
SBCS <	repne scasb							>
DBCS <	repne scasw							>
	.leave
	ret
CheckDOSVolumeNameChar	endp

SBCS <DOSBadVolumeCharsTable	byte	'*?/\\|.,;:+=<>[]()&^'		>
SBCS <DOS_BAD_VOLUME_CHARS_LENGTH equ ($-DOSBadVolumeCharsTable)	>
DBCS <DOSBadVolumeCharsTable	wchar	'*?/\\|.,;:+=<>[]()&^'		>
DBCS <DOS_BAD_VOLUME_CHARS_LENGTH equ (($-DOSBadVolumeCharsTable)/(size wchar))>

if not _FCAB


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskRenameRenameDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read disk specified and show current volume name, if any

CALLED BY:	MSG_DISK_RENAME_DRIVE

PASS:		cx = identifier of the exclusive drive in rename drive list

RETURN:		carry	- set on error
			- clear if OK
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/05/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskRenameRenameDrive	method	DesktopClass, MSG_DISK_RENAME_DRIVE
	call	ShowHourglass
	;
	; get drive number
	;
	mov	ax, cx				; al = drive number
						; ah = media descriptor
	call	DiskRegisterDiskSilently
						; bx = disk handle, if any
	jnc	noError
	mov	ax, ERROR_DRIVE_NOT_READY	; report error, if so
	call	DesktopOKError
	;
	; For GeoManager, restore last selected drive
	;
GM<	mov	bx, handle DiskRenameBox	; bx:si = rename box	>
GM<	mov	si, offset DiskRenameBox				>
GM<	mov	ax, MSG_FOB_GET_DISK_HANDLE				>
GM<	call	ObjMessageCallFixup		; cx = disk handle	>
GM<	mov	bx, cx							>
GM<	call	SetRenameDriveButton		; select this drive	>

	stc					; let caller know we failed
	jmp	short exit

noError:
GM<	push	bx							>
	call	SetAndStoreRenameDisk
GM<	pop	bx							>
GM<	call	SetRenameDriveButton		; force drive button to be >
						;	correct again
	clc					; no error
exit:
	call	HideHourglass
	ret
DiskRenameRenameDrive	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAndStoreRenameDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save a diskhandle of the drive to rename.

CALLED BY:	DiskRenameRenameDrive

PASS:		bx - disk handle to store

RETURN:		none

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/14/92	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetAndStoreRenameDisk	proc	near
	;
	; store disk handle with rename box
	;
	push	bx				; save disk handle
	mov	cx, bx				; cx = disk handle
	mov	bx, handle DiskRenameBox	; bx:si = rename box
	mov	si, offset DiskRenameBox
	mov	ax, MSG_FOB_SET_DISK_HANDLE
	call	ObjMessageCallFixup
	pop	bx				; restore disk handle
	;
	; show current volume name
	;

; volume buffer (with room for unnamed brackets)
SBCS <FULL_VOLUME_NAME_LENGTH = VOLUME_NAME_LENGTH+1+2			>
DBCS <FULL_VOLUME_NAME_LENGTH = (VOLUME_NAME_LENGTH+1+2)*2		>

	sub	sp, FULL_VOLUME_NAME_LENGTH
	segmov	es, ss
	mov	di, sp
	LocalLoadChar ax, '['
	LocalPutChar esdi, ax				; in case unnamed
	call	DiskGetVolumeName
	call	DiskCheckUnnamed			; unnamed?
	jnc	40$				; no
	;
	; unnamed, add ending bracket
	;
SBCS <	push	di							>
SBCS <	mov	al, 0							>
DBCS <	clr	ax							>
	mov	cx, VOLUME_NAME_LENGTH
SBCS <	repne scasb				; es:di = after null	>
DBCS <	repne scasw				; es:di = after null	>
	LocalPrevChar esdi			; es:di = null
	mov	ax, ']'				; bracket + null
	stosw
DBCS <	clr	ax							>
DBCS <	stosw								>
SBCS <	pop	di							>
SBCS <	dec	di				; point at beginning bracket >
DBCS <	mov	di, sp				; point at beginning bracket >
	stc
40$:
	mov	dx, es
	mov	bp, di
	mov	bx, handle DiskRenameSrcName
	mov	si, offset DiskRenameSrcName
	push	dx, bp
	pushf
	call	CallFixupSetText
	;
	; put source name in dest. name field and select it
	;
	popf					; retrieve unnamed? result
	pop	dx, bp				; retrieve method params
	jnc	80$				; => has name

NOFXIP<	mov	dx, cs				; if unnamed, use null string >
FXIP<	push	ds
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	dx, ds				; dx = dgroup		>
FXIP<	pop	ds							>
	mov	bp, offset nullRenameString			
		
80$:
	mov	bx, handle DiskRenameDestName
	mov	si, offset DiskRenameDestName
	call	CallFixupSetText
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL ; select name
	mov	cx, 0
	mov	dx, 0x8000
	call	ObjMessageCallFixup
	add	sp, FULL_VOLUME_NAME_LENGTH
	ret
SetAndStoreRenameDisk	endp


if FULL_EXECUTE_IN_PLACE
idata	segment
endif

LocalDefNLString nullRenameString <0>

if FULL_EXECUTE_IN_PLACE
idata	ends
endif


if _GMGRONLY
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRenameDriveButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the ui for the disk-to-be-renamed to the drive of the
		passed in diskhandle.
t
CALLED BY:	DiskRenameRenameDrive

PASS:		bx - diskhandle

RETURN:		none
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/14/92	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetRenameDriveButton	proc	near
	call	DiskGetDrive			; al = drive
	call	DriveGetDefaultMedia		; ah = media
	mov	cx, ax				; cx = drive/media
	mov	bx, handle DiskMenuResource	; bx:si = disk list
	mov	si, offset DiskMenuResource:DiskRenameDriveList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjMessageCallFixup
	ret
SetRenameDriveButton	endp

endif		; if _GMGRONLY
endif		; if (not _FCAB)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CancelTriggerTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle press on cancel button

CALLED BY:	MSG_GEN_TRIGGER_SEND_ACTION

PASS:		es - segment of CancelTriggerClass

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CancelTriggerTrigger	method	CancelTriggerClass, MSG_GEN_TRIGGER_SEND_ACTION

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	;
	; flag cancel
	;
	mov	es:[cancelOperation], 0xff

	push	ax
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ObjCallInstanceNoLock

	tst	es:[cancelMonikerToChange]	; moniker to change?
	jz	skip

	push	si
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_NOW
	mov	cx, offset StoppingProgressMoniker
	mov	bx, handle ProgressUI
	mov	si, es:[cancelMonikerToChange]
	call	ObjMessageCallFixup
	pop	si

skip:
	pop	ax
	;
	; call superclass to do its stuff
	;
	segmov	es, <segment CancelTriggerClass>, di
	mov	di, offset CancelTriggerClass
	call	ObjCallSuperNoLock

	ret
CancelTriggerTrigger	endp

DiskCode	ends
