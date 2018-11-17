COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driCritical.asm

AUTHOR:		Adam de Boor, Oct 31, 1991

ROUTINES:
	Name			Description
	----			-----------
    EXT DOSCriticalError	Handle critical error from MS-DOS

    INT DOSHookCriticalError	Grab the critical error vector so we can
				field them.

    EXT DOSUnhookCriticalError	Restore the critical error interrupt

    INT DOSPreventCriticalErr	Prevent critical errors from getting to the
				user.

    INT DOSAllowCriticalErr	Allow critical errors to get to the user.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/31/91	Initial revision


DESCRIPTION:
	Critical-error handling with grace and finesse.
		

	$Id: dosCritical.asm,v 1.1 97/04/10 11:55:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FULL_EXECUTE_IN_PLACE
ResidentXIP	segment resource
else
Resident	segment	resource
endif



if _REDMS4
continue	= mask SNF_RETRY
else
continue	= mask SNF_ABORT or mask SNF_RETRY
endif

panic		= mask SNF_EXIT or mask SNF_REBOOT

idata		segment


notifyFlags	SysNotifyFlags	\
		continue,	; Write-protected
		0,		; Drive unknown -- our fault, so just return
				;  error
		continue,	; Drive not ready
		panic,		; Unknown command --  DOS's fault
		continue,	; Data error
		panic,		; Bad request -- DOS's fault
		continue,	; Seek error
		continue,	; Unknown media
		continue,	; Sector not found
		0,		; Out of paper -- critical, wot?
		continue,	; Write fault
		continue,	; Read fault
		continue	; General failure


			
errorMessages	lptr	writeProtected,
			0,
			driveNotReady,
			unknownCommand,
			dataError,
			badRequest,
			seekError,
			unknownMedia,
			sectorNotFound,
			0,
			writeFault,
			readFault,
			generalFailure


idata		ends

udata		segment
ceDriveOffset	word		; offset of \1 in ceDrive string, where drive
				;  letter is placed for critical errors
				;  involving disk drives.
udata		ends


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSCriticalError

DESCRIPTION:	Handle critical error from MS-DOS

CALLED BY:	EXTERNAL
		INT 24h

PASS:
	ah - bit 7: 0 if disk error, otherwise 1 (char dev or FAT or memory)
	     bit 5: CR_IGNORE allowed (>= 3.10 only)
	     bit 4: CR_RETRY allowed (>= 3.10 only)
	     bit 3: CR_FAIL allowed (>= 3.10 only)
	     bit 1,2:	00 = MS-DOS area (boot sector)
			01 = FAT
			10 = root dir
			11 = files area
	     bit 0: 1 if write, 0 if read
	al - drive # if ah.7 == 0
	bp:si - address of device header control block (check 
		DH_attr.DA_CHAR_DEV to ensure validity)
	di - lower byte - error code
	
	on stack:
		iret frame to caller of DOS
		es
		ds
		bp
		di
		si
		dx
		cx
		bx
		ax
		iret frame from "int 24h"	<- sp


RETURN:
	al - action code:
		0 - ignore error
		1 - retry operation
		2 - terminate program through INT 23h
		3 - Fail system call in progress

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@
DOSCriticalError	proc	far	cframe:CriticalFrame
		uses	bx, si, di, ds, es, cx, dx
		.enter
		INT_ON
FXIP<		call	LoadVarSegDSFar					>
NOFXIP<		call	LoadVarSegDS					>
EC <		segmov	es,ds	; Avoid death in SysNotify. ES is DOS...>

		andnf	di, 0xff	; discard unused high byte
	;
	; If initialization not complete, abort the call in-progress.
	; 
		tst	ds:[dosPreventCritical]
		jz	setDriveLetter
		shl	di			; returnError expects this
						;  left shifted, so oblige it.
		jmp	returnError

setDriveLetter:
		test	ah, mask CEF_CHAR_DEV
		jnz	checkError
		
		push	ax, di
		add	al, 'A'
		segmov	es, Strings, di
		mov	di, ds:[ceDriveOffset]
		mov	es:[di], al
		pop	ax, di
checkError:
	;
	; The VLM version of NETX likes to generate this heretofore unknown
	; critical error in the face of a sharing violation. Catch it
	; and treat it as it deserves.
	; 				-- ardeb 4/6/94
	; 
		cmp	di, CE_SHARING_VIOLATION
		je	sharingViolation

		cmp	di, CE_DRIVE_NOT_READY
		jne	checkGF

		test	ah, mask CEF_CHAR_DEV
		jz	checkExtendedCode
	
EC <		push	es		; ec +segment protection	>
		mov	es, ss:[bp]
		test	es:[si].DH_attr, mask DA_CHAR_DEV
EC <		pop	es						>
		jz	checkExtendedCode	; no
	
	;
	; DRIVE_NOT_READY for character device. Copy the name into the
	; string and put up the error message
	; 
		push	di, ds
		segmov	es, <segment deviceTimeout>, di
		assume 	es:Strings
		mov	di, es:[deviceTimeout]
		add	si, offset DH_name
		mov	ds, ss:[bp]
		mov	cx, length DH_name
		rep	movsb
		pop	di, ds
		shl	di
		mov	si, offset deviceTimeout
		assume	es:nothing
		jmp	putupErrorHaveMessage
		
checkExtendedCode:
	;
	; Handle sharing violations, which are reported as DRIVE_NOT_READY
	; critical errors, for some ungodly reason.
	; 
		clr	bx
		push	di, ax
		mov	ah, MSDOS_GET_EXT_ERROR_INFO	; nukes cl, dx, si, di,
							;  es, ds
		call	FileInt21
		pop	di, si
		xchg	ax, si			; ax <- CriticalErrorFlags
						; si <- error code
	;
	; If error returned is SHARING_VIOLATION, just fail the thing, returning
	; that error.
	;
		cmp	si, ERROR_SHARING_VIOLATION
		jne	checkShareOverflow

sharingViolation:
		mov	di, (ERROR_SHARING_VIOLATION - ERROR_WRITE_PROTECTED) \
				shl 1
		jmp	returnError

checkShareOverflow:
		cmp	si, ERROR_SHARING_OVERFLOW
		jne	putUpError
	;
	; Special case for general failure due to overflowing SHARE.EXE's
	; table -- provide informative message.
	; 
		mov	ax, segment Strings
		mov	ds, ax			; ds <- seg addr of strings
		mov	si, offset shareOverflow1
		mov	si, ds:[si]		; ds:si <- ptr to string
		clr	di
		mov	ax, mask SNF_CONTINUE or mask SNF_BIZARRE
		call	SysNotify

		mov	di, (ERROR_SHARING_OVERFLOW - ERROR_WRITE_PROTECTED) \
				shl 1
		jmp	returnError
	

checkGF:
if not _OS2		; wait/post not used under OS/2
	;
	; Win95 is generating a bogus CriticalError for sharing violation,
	; so we must always check the extended error.  --cassie 11/21/95
	;
		cmp	di, CE_GENERAL
;;		jne	putUpError
		jne	checkExtendedCode
	
	;
	; if wait/post is enabled, it could well be the cause of this critical
	; error, so disable it and retry the operation.
	; 

		tst	ds:[dosWaitPostOn]
		jz	checkExtendedCode	; => never turned on
		tst	ds:[dosWPDisabled]
		jnz	checkExtendedCode	; => already disabled

		mov	ds:[dosWPDisabled], TRUE
		mov	al, CR_RETRY
		jmp	done
else
		cmp	di, CE_GENERAL
		je	checkExtendedCode
endif
	
	;--------------------
putUpError:
	; We want to put up a message now. di is the error code
	; 
		shl	di
		cmp	di, size notifyFlags	;if weird error code then handle
		jae	unrecognizedError	;it specially

		mov	si, ds:errorMessages[di]	; si <- chunk handle

		
putupErrorHaveMessage::
	; *Strings:si = message
	; for RESPONDER: *Strings:dx = message2
	; di = error * 2
	; ah = CriticalErrorFlags

		mov_tr	bx, ax			; bh <- CriticalErrorFlags
		mov	ax, ds:notifyFlags[di]
		tst	ax			; No notify flags => don't
						;  notify
		jz	returnError		; just fail the request

		mov	cx, segment Strings
		mov	ds, cx			
		assume	ds:Strings	
		mov	si, ds:[si]		; ds:si <- ptr to string

		test	bh, mask CEF_CHAR_DEV
		mov	bx, ds:[ceDriveString]
		jz	haveStrings

		clr	bx

haveStrings::
		xchg	bx, di			; save error code in bx
						; di <- second string

		call	SysNotify
		assume	ds:dgroup

		mov	di, bx			; di <- error code
		test	ax, mask SNF_RETRY
		mov	al, CR_RETRY		; Assume retry
		jz	returnError
done:
		.leave
		iret

	; special case for a weird error code -- pass it on

unrecognizedError:

if	PASS_ON_WEIRD_CRITICAL_ERRORS
		.leave
		push	bx, ax, ds
FXIP<		call	LoadVarSegDSFar					>
NOFXIP<		call	LoadVarSegDS					>
		mov	bx, offset dosCriticalSave
		jmp	DOSPassOnInterrupt

else
	; OLD hacked code to always retry
		mov	al, CR_RETRY
		jmp	done
endif

returnError:
		sar	di			; use arithmetic right shift to
						;  deal with negativity of DI
						;  if we get here owing to a
						;  sharing violation...
		add	di, ERROR_WRITE_PROTECTED
		clr	bx			; return carry clear
	;
	; special case for MSDOS_FREE_SPACE which is not an FCB routine,
	; but does need to return AX = ffff for an error
	;
		mov	ax, 0xffff		; Assume MSDOS_FREE_SPACE
		cmp	cframe.CF_ax.high, MSDOS_FREE_SPACE
		je	abort
	;
	; If original function call was for an FCB-related function,
	; return al as 0xff (no error code) b/c that's what DOS does for
	; other errors.
	;
		mov	ax, 0xff		; Assume FCB
		cmp	cframe.CF_ax.high, MSDOS_FIRST_FCB_CALL
		jb	returnErrorCode
		cmp	cframe.CF_ax.high, MSDOS_LAST_FCB_CALL
		jbe	abort
	
	;
	; For handle functions, convert the critical error code to a regular
	; error code to be returned in AX with the carry set.
	;
returnErrorCode:
		mov	ax, di			; ax <- error code
		inc	bx			; Signal carry should be set
abort:
	;
	; Record the error in the thread-private data instead for Int21 to
	; pick up. Can't just return to the caller of DOS as doing so leaves
	; DOS in an "unstable" state. E.g. the DTA could have been shifted to
	; the buffer being used for a read, which wreaks havoc with FileEnum
	; (and any data that happen to be there when the FileEnum occurs...).
	; 
		call	FSDRecordError
FXIP<		call	LoadVarSegDSFar					>
NOFXIP<		call	LoadVarSegDS					>
		mov	ds:[dosLastCritical], di; record real error for
						;  DOSUtilInt21

if _MS3
		cmp	ds:[dosVersionMinor], 10
		jae	useFail
		mov	al, CR_IGNORE	; blech.
		jmp	done
useFail:
endif
		mov	al, CR_FAIL	; Tell DOS to fail the request.
					; XXX: should probably check the bit
					;  that says whether we're allowed to
					;  do this...
		jmp	done	
DOSCriticalError endp


if FULL_EXECUTE_IN_PLACE
ResidentXIP	ends
else
Resident	ends
endif

idata	segment 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DebugBootSectorCalls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Debugs boot sector calls.

CALLED BY:	Int 13 interrupt vector

PASS:		depends on function call

RETURN:		depends on function call

DESTROYED:	depends on function call

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/28/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DEBUG_BOOT_SECTOR_CALLS


I21IFrame struct
    I21IF_bp	word
    I21IF_ax	word
    I21IF_retf	fptr.far
    I21IF_flags	CPUFlags
I21IFrame ends


DebugBootSectorCalls	proc	far

if	_FXIP
	PrintError <Cannot use DebugBootSectorCalls on full XIP systems>
endif

		;
		; Save parameters to look at later.
		;
		mov	{word} cs:bootSectorParams.BSPL_numSectors, ax
		mov	{word} cs:bootSectorParams.BSPL_sectorNum, cx
		mov	{word} cs:bootSectorParams.BSPL_driveNum, dx
		movdw	cs:bootSectorParams.BSPL_buffer, esbx

		cmp	ah, B13F_READ_SECTOR
		je	enterCheckDriveNum
		cmp	ah, B13F_WRITE_SECTOR
		jne	EnterInt13Call

enterCheckDriveNum:
		cmp	dl, 1
		jne	skipInt13Call

EnterInt13Call	label	near		;print regs here
		nop

skipInt13Call:

		; push the flags originally passed to us so interrupts are in 
		; the right state when DOS returns to us.

		push	ax
		push	bp
		mov	bp, sp
		mov	ax, ss:[bp].I21IF_flags
		xchg	ax, ss:[bp].I21IF_ax
		pop	bp
		call	cs:[int13Save]

		;
		; Not sector=1 and track=0, forget debugging.  Also if not
		; an int 2h.
		;
		push	ds, es, si, di, cx, ax
		pushf
		mov	cs:bootSectorParams.BSPL_retCarry, 0
		jnc	10$
		mov	cs:bootSectorParams.BSPL_retCarry, 0ffh
10$:
    		cmp	cs:bootSectorParams.BSPL_function, B13F_READ_SECTOR
		jne	checkReturnRegs
		cmp	{word} cs:bootSectorParams.BSPL_sectorNum, 1
		jne	checkReturnRegs

		;
		; Reading boot sector, handle specially.
		;
		mov	{word} cs:bootSectorParams.BSPL_numSectorsRead, ax

		segmov	es, cs
		mov	di, offset bootSectorParams.BSPL_returnData

		movdw	dssi, cs:bootSectorParams.BSPL_buffer
		mov	cx, size BootSector
		rep	movsb
		
LeaveBootSectorCall	label	near
		nop

checkReturnRegs:
		;
		; Non boot-sector call, allow swat to read registers if
		; it's anything but a non-floppy read/write sector.
		;
		cmp	cs:bootSectorParams.BSPL_function, B13F_READ_SECTOR
		je	leaveCheckDriveNum
		cmp	cs:bootSectorParams.BSPL_function, B13F_WRITE_SECTOR
		jne	LeaveInt13Call

leaveCheckDriveNum:
		cmp	cs:bootSectorParams.BSPL_driveNum, 1
		jne	done

LeaveInt13Call		label	near
		nop

done:		
		popf
		pop	ds, es, si, di, cx, ax
		ret	2	; return flags from DOS, not from entry!

DebugBootSectorCalls	endp



endif


idata		ends

Init		segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSHookCriticalError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the critical error vector so we can field them.

CALLED BY:	DOSInit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSHookCriticalError proc	far
		.enter
	;
	; Look for the \1 in ceDriveString
	; 
		segmov	es, Strings, di
		assume	es:Strings
		mov	di, es:[ceDriveString]
		ChunkSizePtr es, di, cx
DBCS <		shr	cx						>
		mov	ax, '\1'
		LocalFindChar
		LocalPrevChar	esdi
     
     		mov	ds:[ceDriveOffset], di
		
		assume	es:nothing
	;
	; Now grab the critical-error vector.
	; 
		mov	ax, CRITICAL_VECTOR	; vector # to catch
FXIP<		mov	bx, segment ResidentXIP  ; bx:cx = handler routine >
NOFXIP<		mov	bx, segment Resident				   >
		mov	cx, offset DOSCriticalError
		segmov	es, ds			; es:di = place to store old
		mov	di, offset dosCriticalSave
		call	SysCatchInterrupt
		.leave
		ret
DOSHookCriticalError	endp

Init		ends

Resident	segment	resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSUnhookCriticalError

DESCRIPTION:	Restore the critical error interrupt

CALLED BY:	EXTERNAL
		DR_EXIT handler

PASS:
	ds - our variable segment

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@
DOSUnhookCriticalError	proc	far	uses ax, di
		.enter
		mov	ax, CRITICAL_VECTOR
		segmov	es, ds
		mov	di, offset dosCriticalSave
		call	SysResetInterrupt
		.leave
		ret
DOSUnhookCriticalError	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPreventCriticalErr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent critical errors from getting to the user.

CALLED BY:	DR_DPFS_PREVENT_CRITICAL_ERR
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	dosPreventCritical is incremented and the bios lock grabbed
		(not in that order)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPreventCriticalErr proc	far
		uses	ds
		.enter
		call	SysLockBIOS
		call	LoadVarSegDS
		inc	ds:[dosPreventCritical]
		.leave
		ret
DOSPreventCriticalErr endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSAllowCriticalErr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow critical errors to get to the user.

CALLED BY:	DR_DPFS_ALLOW_CRITICAL_ERR
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	dosPreventCritical is decremented and the BIOS lock released

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSAllowCriticalErr proc	far
		uses	ds
		.enter
		call	LoadVarSegDS
		dec	ds:[dosPreventCritical]
		call	SysUnlockBIOS
		.leave
		ret
DOSAllowCriticalErr endp

Resident	ends
