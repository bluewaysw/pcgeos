COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel System Functions -- Miscellaneous Functions
FILE:		sysMisc.asm

AUTHOR:		Adam de Boor, Apr  6, 1989

ROUTINES:
	Name			Description
	----			-----------
   GLB  SysEmptyRoutine		Routine that should never be called
   GLB	SysShutdown		Exit the system gracefully
   GLB	SysGetConfig		Return system configuration information
   GLB	SysSetExitFlags		Set/clear exit flags
   GLB	UtilHex32ToAscii	Convert a 32-bit number to an ascii
   GLB	UtilAsciiToHex32	Convert an ASCII string to a 32-bit number
   				string.
  RGLB	SysLockBIOS		Gain exclusive access to DOS/BIOS
  RGLB	SysUnlockBIOS		Release exclusive access to DOS/BIOS

   EXT  SysCallCallbackBP	Call a standard callback function passing
   				bp properly.
   EXT	SysJumpVector		Call a vector w/o trashing registers
   EXT	SysLockCommon		Perform common module-lock lock operations
   EXT	SysUnlockCommon		Perform common module-lock unlock operations
   EXT  SysPSemCommon		Perform common PSem operations
   EXT 	SysVSemCommon		Perform common VSem operations

   EXT	SysCopyToStack*		Copy a buffer to the stack for XIP

   GLB  SYSSETINKWIDTHANDHEIGHT	Set the default ink thickness
   GLB	SYSGETINKWIDTHANDHEIGHT	

   GLB	SYSDISABLEAPO		disable auto power off
   GLB	SYSENABLEAPO		enable auto power off

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 6/89		Initial revision


DESCRIPTION:
	Miscellaneous system functions


	$Id: sysMisc.asm,v 1.2 98/04/30 15:50:39 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysSetExitFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets and clears the exit flags (this is intended for use
		by task-switching drivers, primarily)

CALLED BY:	RESTRICTED GLOBAL
PASS:		bh - flags to clear
		bl - flags to set
RETURN:		bl - exitFlags
DESTROYED:	bh
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysSetExitFlags	proc	far
	uses	ds
	.enter
EC <	test	bl, not mask ExitFlags					>
EC <	jnz	bad							>
EC <	test	bh, not mask ExitFlags					>
EC <	jz	good							>
EC <bad:								>
EC <	ERROR	BAD_EXIT_FLAGS						>
EC <good:								>
	LoadVarSeg	ds			;Get ptr to idata
	or	bl,ds:[exitFlags]		;Set bits
	not	bh				;
	and	bl,bh				;Clear bits
	mov	ds:[exitFlags],bl		;
	.leave
	ret
SysSetExitFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadVarSegDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the kernel's data segment into DS

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ds	= idata
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
kernelData	word	dgroup
LoadVarSegDS	proc	near
		.enter
		mov	ds, cs:kernelData
		.leave
		ret
LoadVarSegDS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadVarSegES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the kernel's data segment into ES

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		es	= idata
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadVarSegES	proc	near
		.enter
		mov	es, cs:kernelData
		.leave
		ret
LoadVarSegES	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysEmptyRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A routine to which empty slots in the jump table are vectored

CALLED BY:	Shouldn't be
PASS:		Anything
RETURN:		Never
DESTROYED:	Everything

PSEUDO CODE/STRATEGY:
       FatalError(SYS_EMPTY_CALLED)


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysEmptyRoutine	proc	far
		ERROR	SYS_EMPTY_CALLED
SysEmptyRoutine	endp

ForceRef	SysEmptyRoutine		;Used for "skip" in .gp file



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cause the system to exit

CALLED BY:	EXTERNAL
PASS:		ax - SysShutdownType. See documentation in system.def for
		   	additional parameters specific to the type of shutdown
RETURN:		only as noted in system.def
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysShutdown	proc	far
	uses	es, ds, si, di
	.enter

EC <	cmp	ax,SysShutdownType					>
EC <	ERROR_AE	BAD_SHUTDOWN_TYPE				>

	mov_tr	di, ax
	LoadVarSeg	es, ax
	shl	di
	jmp	cs:[shutdownTable][di]

shutdownTable	nptr.near	clean,			; SST_CLEAN
				cleanForced,		; SST_CLEAN_FORCED
				dirty,			; SST_DIRTY
				EndGeosDoubleFault,	; SST_PANIC
				reboot,			; SST_REBOOT
				restart,		; SST_RESTART
				final,			; SST_FINAL
				suspend,		; SST_SUSPEND
				confirmStart,		; SST_CONFIRM_START
				confirmEnd,		; SST_CONFIRM_END
				cleanReboot,		; SST_CLEAN_REBOOT
				powerOff		; SST_POWER_OFF

	;--------------------
dirty:
	inc	es:[errorFlag]		; set errorFlag so we don't delete
					;  the GEOS_ACT.IVE file, thereby
					;  alerting us to the non-standard
					;  exit next time.
	; FALL THROUGH
	;--------------------
final:
	cmp	si, -1
	je	die

	; move the string to messageBuffer

	mov	di, offset messageBuffer
	mov	cx, length messageBuffer-1

copyLoop:
if not DBCS_PCGEOS
	lodsb
else
	lodsw
EC  <	tst	ah							>
EC <	WARNING_NZ LARGE_VALUE_FOR_CHARACTER				>
endif
	stosb
	tst	al
	loopne	copyLoop
	clr	al
	stosb
die:
	jmp	EndGeos

	;--------------------
reboot:
	ornf	es:[exitFlags], mask EF_RESET
	jmp	EndGeos

	;--------------------
restart:
	call	DosExecPrepareForRestart
	LONG jc	done

	;--------------------
cleanForced:
	; If the UI is not running, just exit

	mov	bx,es:[uiHandle]
	tst	bx
	jz	die

	; The UI is running -- tell it to kill all apps & fields. No ack optr
	; or ID, as the UI will call us back with SST_FINAL when everything's
	; ready to go.

	mov	ax, MSG_META_DETACH
	clr	cx, dx, bp, di
	call	ObjMessage
	clc
	jmp	done

	;--------------------
powerOff:
	push	ds, si, di

; jfh 12/05/03 - lets put the string in a resource for localization
	mov	bx, handle MovableStrings
	call	MemLock
	mov	ds, ax

;	segmov	ds, cs
	mov	si, offset PowerOffString
	mov	si, ds:[si]			; ds:si <- PowerOffString
	mov	di, offset messageBuffer
	LocalCopyString

	call	MemUnlock

	pop	ds, si, di

	ornf	es:[exitFlags], mask EF_POWER_OFF
	jmp	short clean

;PowerOffString	char	"You may now safely turn off the computer.",0

	;--------------------
cleanReboot:
	ornf	es:[exitFlags], mask EF_RESET

	; FALL THROUGH
	;--------------------
clean:
	mov	di, GCNSCT_SHUTDOWN

cleanSuspendCommon:
	segmov	ds, es

	;
	; Gain exclusive access to the shutdown-status variables.
	; 
	PSem	ds, shutdownBroadcastSem, TRASH_AX_BX

	;
	; If something else is already shutting down the system, fail this
	; request.
	; 
	tst	ds:[shutdownConfirmCount]
	jnz	failCleanSuspend
	
	;
	; Record the object we should notify when the final confirmation
	; comes in.
	; 
	mov	ds:[shutdownAckOD].handle, cx
	mov	ds:[shutdownAckOD].chunk, dx
	mov	ds:[shutdownAckMsg], bp

	;
	; Start the count off at 1 so we can reliably figure out when to send
	; out notification and deal with not having anyone interested in what
	; we've got to say...The extra 10,000 are to deal with having something
	; being notified being run by this thread (since we can't add the
	; count of the number of notifications in until GCNListRecordAndSend
	; returns).
	; 
	mov	ds:[shutdownConfirmCount], 10001

	VSem	ds, shutdownBroadcastSem, TRASH_AX_BX

	;
	; Broadcast the intent to shutdown.
	; 
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	si, GCNSLT_SHUTDOWN_CONTROL
	mov	bp, di
	clr	di			; not status message
	mov	ax, MSG_META_CONFIRM_SHUTDOWN
	call	GCNListRecordAndSend

	;
	; Record the number of acks needed and remove our protective 10,000
	; 
	add	ds:[shutdownConfirmCount], cx
	sub	ds:[shutdownConfirmCount], 10000
	
	;
	; Now perform an SST_CONFIRM_END allowing the shutdown, thereby sending
	; confirmation to the caller if there was no one on the list.
	; 
	mov	cx, TRUE
	jmp	confirmEnd

failCleanSuspend:
	;
	; Someone else is doing a shutdown, so we can't start this one off.
	; Release the broadcast semaphore and return carry set.
	; 
	VSem	ds, shutdownBroadcastSem, TRASH_AX_BX
doneCarrySet:
	stc
done:
	.leave
	ret
	
	;--------------------
suspend:
	mov	di, GCNSCT_SUSPEND
	jmp	cleanSuspendCommon

	;--------------------
confirmStart:
	;
	; Gain the exclusive right to ask the user to confirm.
	; 
	segmov	ds, es
	PSem	ds, shutdownConfirmSem, TRASH_AX_BX
	
	;
	; If not already refused, return carry clear.
	; 
	tst	ds:[shutdownOK]
	jnz	done

	;
	; Someone's already refused the shutdown, so call ourselves to deny
	; the request and return carry set.
	clr	cx
	mov	ax, SST_CONFIRM_END
	call	SysShutdown
	jmp	doneCarrySet

	;--------------------
confirmEnd:
	segmov	ds, es
	jcxz	denied
	
releaseConfirmSem:
	VSem	ds, shutdownConfirmSem, TRASH_AX_BX


	;
	; Gain exclusive access to the confirm count & attendant variables, to
	; prevent some other thread from coming in after the dec but before we
	; can load the other variables, and trashing them...
	; 
	PSem	ds, shutdownBroadcastSem, TRASH_AX_BX
	dec	ds:[shutdownConfirmCount]
	jz	sendShutdownConfirmAck

confirmEndComplete:
	VSem	ds, shutdownBroadcastSem, TRASH_AX_BX
	clc			; carry clear for SST_CLEAN/SST_SUSPEND...
	jmp	done

denied:
	;
	; Caller is refusing the shutdown, so mark the shutdown as denied
	; and do all the normal processing for SST_CONFIRM_END.
	; 
	mov	ds:[shutdownOK], FALSE
	jmp	releaseConfirmSem

sendShutdownConfirmAck:
	;
	; Fetch shutdownOK into CX to tell the original caller whether it's
	; ok to shutdown/suspend.
	; 
	clr	cx
	mov	cl, TRUE
	xchg	ds:[shutdownOK], cl
	;
	; If no shutdownAckOD, it means we should notify the UI in the normal
	; fashion.
	; 
	mov	bx, ds:[shutdownAckOD].handle
	tst	bx
	jz	sendToUI
	mov	ax, ds:[shutdownAckMsg]
	mov	si, ds:[shutdownAckOD].chunk

sendShutdownAckMessage:
	clr	di
	call	ObjMessage
	jmp	confirmEndComplete

sendToUI:
	;
	; If the shutdown was refused and there's no one specific to notify, we
	; don't need to notify anyone. The UI hasn't been involved in the shut-
	; down hitherto, so there's no need to notify it.
	; 
	mov	bx, ds:[uiHandle]
EC <	tst	bx						>
EC <	ERROR_Z	NO_ONE_TO_SEND_SHUTDOWN_ACK_TO_ALAS		>
	mov	ax, MSG_META_DETACH
	clr	dx, bp			; no Ack OD
	tst	cx
	jnz 	sendShutdownAckMessage

	;
	; If marked as running a DOS application, let the task driver know
	; the shutdown was aborted.
	; 
	test	ds:[exitFlags], mask EF_RUN_DOS
	jz	confirmEndComplete
	
	mov	di, DR_TASK_SHUTDOWN_COMPLETE
	call	ds:[taskDriverStrategy]
	jmp	confirmEndComplete

SysShutdown	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SYSGETCONFIG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the system configuration

CALLED BY:	GLOBAL
PASS:		Nothing
RETURN:		AL	= SysConfigFlags reflecting system status
		AH	= reserved
		DL	= SysProcessorType given processor type
		DH	= SysMachineType giving machine type
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SYSGETCONFIG	proc	far
		push	ds
		LoadVarSeg ds
		clr	ax
		mov	al, ds:sysConfig
		mov	dx, word ptr ds:sysProcessorType
		pop	ds
		ret
SYSGETCONFIG	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SYSGETPENMODE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine returns AX = TRUE or FALSE depending upon whether
		or not the machine PC/GEOS is running on is Pen-based or not.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		AX = TRUE if PC/GEOS is running on a pen-based system.
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SYSGETPENMODE	proc	far	uses	ds
	.enter
	LoadVarSeg	ds, ax
	mov	ax, ds:[penBoolean]
	.leave
	ret
SYSGETPENMODE	endp

IMResident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysDisableAPO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable auto power off feature

CALLED BY:	Global
PASS:		nothing
RETURN:		nothing
DESTROYED:	ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if disableAPOCount > 0 
		dec disableAPOCount

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SYSDISABLEAPO	proc	far
	uses	ds
	.enter
	call	LoadVarSegDS
	inc	ds:[disableAPOCount]
EC<	ERROR_Z DISABLE_APO_COUNT_OVERFLOW			>
	.leave
	ret
SYSDISABLEAPO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysEnableAPO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable auto power off feature

CALLED BY:	Global
PASS:		nothing
RETURN:		nothing
DESTROYED:	ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SYSENABLEAPO	proc	far
	uses	ds
	.enter
	call	LoadVarSegDS
	dec	ds:[disableAPOCount]
EC<	ERROR_S	DISABLE_APO_COUNT_OVERFLOW			>
	.leave
	ret
SYSENABLEAPO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SysGetInkWidthAndHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function returns the current height and width to
		be used as defaults for drawing ink

CALLED BY:	Global
PASS:		nothing
RETURN:		ax - default width and height
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	4/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SYSGETINKWIDTHANDHEIGHT	proc	far
	uses	ds
	.enter
	LoadVarSeg	ds, ax
	mov	ax, ds:[inkDefaultWidthAndHeight]
	.leave
	ret
SYSGETINKWIDTHANDHEIGHT	endp

IMResident	ends

IMPenCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysSetInkWidthAndHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the default ink width value

CALLED BY:	global
PASS:		ax - ink height and width
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	4/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysSetInkWidthAndHeight	proc	far
	uses	bx, ds
	.enter
	LoadVarSeg	ds, bx
	mov	ds:[inkDefaultWidthAndHeight], ax
	.leave
	ret
SysSetInkWidthAndHeight	endp

IMPenCode	ends


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UtilHex32ToAscii

DESCRIPTION:	Converts a 32 bit unsigned number to its ASCII representation.

CALLED BY:	INTERNAL (GenerateLabel)

PASS:		DX:AX	= DWord to convert
		CX	= UtilHexToAsciiFlags
				UHTAF_INCLUDE_LEADING_ZEROS
				UHTAF_NULL_TERMINATE
		ES:DI	= Buffer to place string. Should be of size:
				UHTA_NO_NULL_TERM_BUFFER_SIZE or
				UHTA_NULL_TERM_BUFFER_SIZE

RETURN:		CX	= Length of the string (not including NULL)

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	You might think that one could use the 8086 32bit divide instruction
	to perform the conversion here. You'd be wrong. The divisor (10) is
	too small. Given something greater than 64k * 10, we will get a divide-
	by-zero trap the first time we try to divide. So we use "32-bit"
	division with a 16-bit divisor to avoid such problems, doing two
	divides instead of one, etc.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	Don	1/92		Changed dword parameter to DX:AX

-------------------------------------------------------------------------------@

UtilHex32ToAscii	proc	far
	uses	ax, bx, dx, di, si, bp
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx, si					>
EC <	movdw	bxsi, esdi				>
EC <	call	ECAssertValidFarPointerXIP		>
EC <	pop	bx, si					>
endif	
	mov	si, cx				;place flags in si
	;
	; Check for a signed value
	;
	test	si, mask UHTAF_SIGNED_VALUE
	jz	notSigned
	tst	dx
	jns	notSigned
	;
	; The value is signed and negative.  Stick in a minus sign and negate.
	;
	negdw	dxax				;dx:ax <- negative of value
	push	ax
DBCS <	LocalLoadChar ax, C_MINUS_SIGN					>
SBCS <	LocalLoadChar ax, C_MINUS					>
	LocalPutChar esdi, ax
	pop	ax
	jmp	afterSigned

notSigned:
	andnf	si, not (mask UHTAF_SIGNED_VALUE)
afterSigned:
	;
	; First convert the number to characters, storing each on the stack
	;
	mov	bx, 10				;print in base ten
	clr	cx				;cx <- char count
	xchg	ax, dx
nextDigit:
	mov	bp, dx				;bp = low word
	clr	dx				;dx:ax = high word
	div	bx
	xchg	ax, bp				;ax = low word, bp = quotient
	div	bx
	xchg	ax, dx				;ax = remainder, dx = quotient
	add	al, '0'				;convert to ASCII
	push	ax				;save character
	inc	cx
	mov	ax, bp				;retrieve quotient of high word
	or	bp, dx				;check if done
	jnz	nextDigit			;if not, do next digit

	; Now let's see if we need to provide leading zeroes. A 32-bit
	; binary values can be as long as ten digits.
	;
	test	si, mask UHTAF_INCLUDE_LEADING_ZEROS
	jz	copyChars
	sub	bx, cx				;bx <- number of 0s needed
	mov	cx, bx				;place count in cx
	jcxz	tenDigits			;if already ten digits, jump
	mov	ax, '0'				;character to push
addLeadZeros:
	push	ax
	loop	addLeadZeros
tenDigits:
	mov	cx, 10				;digit count = 10

	; Now pop the characters into its buffer, one-by-one
	;
copyChars:
	mov	dx, cx				;dx = character count
DBCS <	test	si, mask UHTAF_SBCS_STRING	;want SBCS string?	>
DBCS <	jnz	nextCharSBCS			;branch if SBCS		>
nextChar:
	pop	ax				;retrieve character
SBCS <	stosb								>
DBCS <	stosw								>
	;
	; Check for thousands separators
	;
	test	si, mask UHTAF_THOUSANDS_SEPARATORS
	jz	afterComma			;branch if no separators
	cmp	cx, 10
	je	storeComma
	cmp	cx, 7
	je	storeComma
	cmp	cx, 4
	je	storeComma
afterComma:
	loop	nextChar			;loop to print all
DBCS <afterChars:							>
	;
	; Count the sign character if we added it above
	;
	test	si, mask UHTAF_SIGNED_VALUE
	jz	noSignChar
	inc	dx				;dx <- one more char
noSignChar:
	;
	; Add a NULL if requested
	;
	test	si, mask UHTAF_NULL_TERMINATE	;NULL-terminate the string ??
	jz	noNULL				;nope, so we're done
SBCS <	mov	{byte} es:[di], 0		;this is fastest	>
DBCS <	mov	{wchar}es:[di], 0		;this is fastest	>
noNULL:
	mov	cx, dx				;cx = character count

	.leave
	ret

storeComma:
	inc	dx				;dx <- 1 more character
	push	cx, dx
	call	LocalGetNumericFormat
	mov	ax, bx				;ax <- thousands separator
	LocalPutChar esdi, ax
	pop	cx, dx
	jmp	afterComma

if DBCS_PCGEOS
nextCharSBCS:
	pop	ax				;retrieve character
	stosb					;store SBCS character
	loop	nextCharSBCS			;loop to print all
	jmp	afterChars
endif
UtilHex32ToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilAsciiToHex32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a null-terminated ASCII string into a dword. The
		string may be signed or unsigned.

CALLED BY:	GLOBAL

PASS:		DS:SI	= String to convert

RETURN:		DX:AX	= DWord value
		Carry	= Clear (valid number)
			- or -
		Carry	= Set (invalid number)
		AX	= UtilAsciiToHexError

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UtilAsciiToHex32	proc	far
	uses	bx, cx, bp, si
	.enter
	
if	FULL_EXECUTE_IN_PLACE
EC <	call	ECCheckBounds				>
endif	
	; See if we have a leading minus sign
	;
	clr	ax				; assume positive number
	LocalCmpChar ds:[si], '+'		; just skip over a '+', as we
	je	skipChar			; assume the number is positive
	LocalCmpChar ds:[si], '-'		; check for negative sign
	jne	startConversion			; if not there, jump
	dec	ax				; else set minus boolean
skipChar:
	inc	si				; increment past minus sign
	LocalNextChar dssi			; increment past minus sign
	
	; Calculate the number, digit by digit
	;
startConversion:
	push	ax				; save minus boolean
	clrdw	dxcx				; initialize our number
convertDigit:
	LocalGetChar ax, dssi			; get the next digit	
	LocalIsNull	ax			; NULL termination ??
	jz	done				; yes, so jump
SBCS <	sub	al, '0'				; turn into a number	>
DBCS <	sub	ax, '0'				; turn into a number	>
SBCS <	cmp	al, 9				; ensure we have a digit >
DBCS <	cmp	ax, 9				; ensure we have a digit >
	ja	notADigit
	shldw	dxcx				; double current value
	jc	overflow
	movdw	bpbx, dxcx
	shldw	dxcx
	jc	overflow
	shldw	dxcx				; 8 * original value => DX:CX
	jc	overflow
	adddw	dxcx, bpbx			; and in 2 * original value
	jc	overflow
SBCS <	clr	ah							>
	add	cx, ax				; add in new digit
	adc	dx, 0				; propogate carry
	jnc	convertDigit			; loop until done, or overflow

	; Deal with error - either an invalid digit or overflow
overflow:
	mov	cx, UATH_CONVERT_OVERFLOW
	jmp	error				; we fail with an error
notADigit:
	mov	cx, UATH_NON_NUMERIC_DIGIT_IN_STRING
error:
	stc
done:
	pop	ax				; minus boolean => AX
	xchg	ax, cx				; result => DX:AX, boolean => CX
	jc	exit				; if error, don't do anything
	jcxz	exit				; if zero, we're OK
	mov	cx, UATH_CONVERT_OVERFLOW
	test	dh, 0x80			; high bit must be clear
	stc
	jnz	exit				; ...else we have overflow
	negdw	dxax				; else negate the number
	clc					; ensure carry is clear
exit:
	.leave
	ret
UtilAsciiToHex32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallCallbackBP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Standard utility function for calling a callback function
		where bp must be passed. The calling function must have a
		stack frame whose first local variable is a far pointer
		to the callback routine.

CALLED BY:	ThreadProcess, FilePathProcess, GeodeProcess, DiskForEach,
		WinForEach

PASS:		ax, cx, dx, ss:[bp] = data to pass to callback.
			ss:[bp] is the bp from entry to the calling function

RETURN:		ax, cx, dx, ss:[bp] = data returned by callback
		carry - returned from callback

DESTROYED:	si (callback may destroy di as well)

PSEUDO CODE/STRATEGY:
		Notes - ss:bp points to the word to pass in to called routine
			as bp.

		save this pointer
		load in bp to pass to routine
		call routine
		restore pointer to BPData
		stuff returned BP value into BPData
		return

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/90		Initial version
	todd	02/10/94	Added XIP version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCallCallbackBP proc	near
callback	local	fptr.far
		.enter	inherit

		push	bp

	;
	;  See if we are passed a vfptr, or an fptr.
	;  Do different actions, depending upon the state
	;  of the high-byte of the segment.
	;			-- todd 02/17/94
FXIP<		cmp	{byte}callback.segment.high, SIG_UNUSED_FF	>
FXIP<		je	doHighMemCall					>

FXIP<		cmp	{byte}callback.segment.high, high MAX_SEGMENT	>
FXIP<		jae	doProcCall					>

doHighMemCall::

	;
	;  We got here by one of two ways, either we are
	;  calling something in high memory, or we are calling
	;  a segment that doesn't have an 0fh, in the high nibble.
	;			-- todd 02/17/94
		lea	si, callback	; ss:[si] = callback routine
		mov	bp, ss:[bp]	; recover bp passed to caller
		call	{dword}ss:[si]

done::

		mov	si, bp		; preserve returned bp
		pop	bp		; recover our frame pointer
		mov	ss:[bp], si	; store returned bp for possible
					;  return/next call

		.leave
		ret

doProcCall::
	;
	;  Stuff AX and BX into ThreadPrivData so they will be
	;  passed along to routine.  Passing BX in this way
	;  is easier than pushing and popping, and faster as well.
	;			-- todd 02/10/94

FXIP<		mov	ss:[TPD_dataAX], ax				>
FXIP<		mov	ss:[TPD_dataBX], bx				>
FXIP<		movdw	bxax, callback	; bx:ax <- vfptr to callback	>
FXIP<		mov	bp, ss:[bp]	; bp <- data to pass in bp	>

FXIP<		call	ProcCallFixedOrMovable				>
FXIP<		jmp	short done					>

SysCallCallbackBP endp

SysCallCallbackBPFar proc far
		call	SysCallCallbackBP
		ret
SysCallCallbackBPFar endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysLockBIOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain exclusive access to BIOS/DOS

CALLED BY:	RESTRICTED GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysLockBIOSFar	proc	far
		call	SysLockBIOS
		ret
SysLockBIOSFar	endp
		public	SysLockBIOSFar

SysLockBIOS	proc	near
		push	bx
		mov	bx, offset biosLock
		jmp	SysLockCommon
SysLockBIOS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysUnlockBIOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive access to BIOS/DOS

CALLED BY:	RESTRICTED GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysUnlockBIOSFar proc	far
		call	SysUnlockBIOS
		ret
SysUnlockBIOSFar endp
		public	SysUnlockBIOSFar

SysUnlockBIOS	proc	near

if CHECKSUM_DOS_BLOCKS
	;
	; Before releasing the BIOS lock, perform checksums of various DOS
	; blocks and save them away for SysLockBIOS.
	;
		call	SysComputeDOSBlockChecksums
endif
		push	bx
		mov	bx, offset biosLock
		jmp	SysUnlockCommon
SysUnlockBIOS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysLockCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform common module-lock activities for the various
		module locks in the kernel. THIS MUST BE JUMPED TO

CALLED BY:	EXTERNAL
PASS:		bx	= offset in idata of the ThreadLock to lock
		previous bx pushed on stack
RETURN:		doesn't.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysLockCommon	proc	near jmp
				on_stack	bx retn
		push	ds
				on_stack	ds bx retn
		LoadVarSeg	ds

		push	ax
				on_stack	ax ds bx retn

;	Crash if someone is trying to call this from the kernel thread,
;	after the kernel has been initialized. This catches problems where
;	people try to grab semaphores from the Idle loop.
;
;	It turns out that ThreadDestroy locks down blocks while on the kernel
;	thread, but it already has the heap semaphore, so we don't bother
;	checking the heap semaphore here (if we actually block on the heap
;	semaphore, it will still die in BlockOnLongQueue).

EC <		cmp	bx, offset heapSem				>
EC <		jz	notKernel					>
EC <		tst	ds:[currentThread]				>
EC <		jnz	notKernel					>
EC <		tst	ds:[interruptCount]				>
EC <		jnz	notKernel					>
EC <		tst	ds:[initFlag]					>
EC <		jnz	notKernel					>

	; the stub sometimes calls MemLock pretending to be the kernel. so
	; it sets TPD_dataAX to be 0xadeb specifically for this piece of EC
	; code, so that it knows that its really the stub and not the kernel
	; that is running here. jimmy - 8/94
	
	; This is no longer true.  Instead, the swat stub does nothing
	; special when it calls MemLock.  It just so happens that when the
	; stub fakes calling MemLock, its ThreadPrivateData has no exception
	; handlers.  So, to make things all better (now that the exception
	; handlers are in a separate block), simply check to see if the
	; TPD_exceptionHandlers ptr is null.  If it is NULL, and the
	; "currentThread" is 0, we know it is the swat stub.  In that case,
	; DO NOT fatal error.  JimG - 6/4/96

EC <		tst	ss:[TPD_exceptionHandlers]			>
EC <		jz	notKernel					>

;	At this point, we know that this is actually the kernel thread.  But
;	there is a special case for ThreadDestroy where we know that (1) the
;	kernel thread has the BIOS lock (in a manner of speaking) and (2) it
;	will not block if we call SysLockBIOS.  So, if the kernel thread
;	tries to grab the BIOS and the kernel already has it (i.e., the
;	TL_owner is 0) then don't complain about it.

EC <		cmp	bx, offset biosLock				>
EC <		jne	notBiosLock					>
EC <		tst	ds:[bx].TL_owner				>
EC <		jz	notKernel					>
EC <notBiosLock:							>

EC <		ERROR	BLOCK_IN_KERNEL					>

EC <notKernel:								>
EC <		tst	ds:[interruptCount]				>
EC <		ERROR_NZ	NOT_ALLOWED_TO_PSEM_IN_INTERRUPT_CODE	>

		; XXX: TRASH_AX_BX doesn't really trash BX, since it holds the
		; address of the module lock. This is just to save bytes and
		; cycles by not pushing and popping BX when the macro can't
		; destroy BX anyway, since it has to use it to claim ownership
		; of the lock once the semaphore in the lock has been grabbed.
		; So much for data-hiding-via-macros... -- ardeb/tony 11/15/90
		LockModule	ds:[currentThread], ds, [bx], TRASH_AX_BX, \
				<ax ds bx retn>
		pop	ax

		cmp	bx, offset biosLock
		je	saveStack
done:
				on_stack	ds bx retn
		pop	ds
				on_stack	bx retn
		pop	bx
				on_stack	retn
		ret
saveStack:
	;
	; Save the current stack segment away so ThreadFindStack has a chance
	; of finding the right one.
	; 
		mov	ds:[biosStack], ss

if CHECKSUM_DOS_BLOCKS
	;
	; After acquiring the BIOS lock, perform checksums of various DOS
	; blocks, and see if they have changed from the last SysUnlockBIOS.
	;
		call	SysCompareDOSBlockChecksums
endif	; CHECKSUM_DOS_BLOCKS

		jmp	done
SysLockCommon	endp


if CHECKSUM_DOS_BLOCKS

dosBlockNames	char	7, "COMMAND"
		char	0

MAX_DOS_CHECKSUMS	equ	10

DOSBlockStruct	struct
	dbSeg	word
	dbSize	word
	dbSum	word
DOSBlockStruct	ends
		
udata	segment
DOSBlockInit	byte	?
numDOSBlocks	byte	?
DOSBlocks	DOSBlockStruct	MAX_DOS_CHECKSUMS dup(<>)
udata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysSetDOSTables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the DOS block checksum structures.  This routine
		loops thru the DOS MCB chain, identifying each block in the
		system.  Blocks of interest include certain subsegments of
		system blocks and blocks listed in dosBlockNames.  These
		currently include:

		DOS system subsegments:
			System file tables
			FCB's
			Current Directory Table
			Stacks
		Blocks identified by name:
			COMMAND

		Each block's segment and size is stored in the global 
		DOSBlocks table.  This table is used later by 
		SysCompute... and SysCompareDOSBlockChecksums to monitor
		each block independently.

CALLED BY:	BootInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Scan the DOS MCB chain for blocks to check
		Store interesting blocks in DOSBlocks

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	3/7/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysSetDOSTables	proc	far
		pusha
	;
	; Get the address of the various DOS system tables and store
	; it in the reply. This uses the undocumented DOS function
	; 52, which returns in ES:BX a pointer to a table of pointers
	; to various system data structures.
	; 
		mov	ah, 52h	; Get DOS tables...
		int	21h
	;
	; Point to the start of the checksum table and clear it.
	;
		mov	bp, offset DOSBlocks
		clr	ds:[numDOSBlocks]
		clr	ds:[DOSBlockInit]
	;
	; Iterate the DOS MCBs to find interesting blocks
	;
		segmov	es, es:[bx-2]
next:
		mov	cx, {word}es:3	; cx <- size (in paragraphs)
		mov	ax, {word}es:1	; ax <- owner
		tst	ax		; maybe IRQ
		je	nope
		cmp	ax, 8		; system - yes
		je	doSystem
		cmp	ax, 7		; excluded - no
		je	nope
		cmp	ax, 6		; umb - no
		je	nope
		cmp	ax, 0fffdh	; 386MAX - no
		jae	nope
	;
	; It's something real, check the name.
	;
		push	ax, cx, ds, es
		dec	ax
		mov	es, ax		; es:0 <- owner's MCB
		segmov	ds, cs, ax
		mov	si, offset dosBlockNames
nextName:
		mov	cl, {byte}ds:[si]
		tst	cl
		stc
		jz	endName
		inc	si
		clr	ch
		mov	di, 8
		repe	cmpsb
		clc
		jne	goNextName	; mismatch in given bytes
		cmp	di, 16		; compared all 8 chars?
		je	endName
		tst	{byte}es:[di]	; if not, is null term there?
		je	endName
goNextName:
		add	si, cx
		jmp	nextName
endName:
		pop	ax, cx, ds, es
		jc	nope
if 0 ; This turned out not to be such a great idea.
;		jnc	doit
	;
	; Check if it's our (loader's) block, and if so, add the PSP to the
	; list (only the first 110h bytes (MCB + PSP))
	;
		mov	ax, es
		inc	ax
		cmp	ax, ds:[loaderVars].KLV_pspSegment
		jne	nope
		mov	cx, (110h shr 4)
		; fall-thru to doit...
endif
	;
	; We like this one, add it to the list.
	;
doit::
		segmov	ds:[bp].dbSeg, es, ax
		mov	ds:[bp].dbSize, cx
		inc	ds:[numDOSBlocks]
		add	bp, size DOSBlockStruct
	;
	; Advance to next block.
	;
nope:
		mov	al, {byte}es:0
		mov	cx, {word}es:3	; cx <- size (in paragraphs)
		mov	dx, es
		add	dx, cx
		inc	dx
		mov	es, dx			; es <- next block
		cmp	al, 04dh		; was block control?
		je	next
		cmp	{byte}es:0, 04dh	; is next block control?
	LONG	je	next

		popa
		ret
	;
	; Check the subsegments of the system block (if it has any).
	;
doSystem:
		cmp	{word}es:8, 04353h	; Is this video memory?
		je	nope
		mov	di, 16		; di <= byte offset of current sub
		mov	dx, 1		; dx <= paragraph offset of current sub
nextSub:
		cmp	dx, cx		; stop when we exceed main block size
		ja	doneSystem
		mov	al, {byte}es:[di]
		mov	bx, {word}es:[di+3]	; bx <= paragraphs in sub
		cmp	al, 'F'		; System file tables
		je	doSub
		cmp	al, 'X'		; FCB's
		je	doSub
		cmp	al, 'L'		; Current Directory Table
		je	doSub
;		cmp	al, 'S'		; Stacks
;		je	doSub
		jmp	nopeSub
	;
	; We like this subsegment, add it to the list.
	;
doSub:
		mov	ax, es		; compute zero-based segment
		add	ax, dx
		mov	ds:[bp].dbSeg, ax
		mov	ds:[bp].dbSize, bx
		inc	ds:[numDOSBlocks]
		add	bp, size DOSBlockStruct
	;
	; Move to next subsegment.
	;
nopeSub:
		inc	bx
		add	dx, bx		; update current paragraph offset
		shl	bx
		shl	bx
		shl	bx
		shl	bx		; bx <- byte length of sub
		add	di, bx		; update current byte offset
		jmp	nextSub
	;
	; We're currently pointing to the next block, so update es
	; and return to the main loop.
	;
doneSystem:
		mov	ax, es		; compute zero-based segment
		add	ax, dx
		mov	es, ax
		jmp	next

SysSetDOSTables	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysComputeDOSBlockChecksums
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loop thru DOSBlocks, compute the checksums for each block,
		and store the results for future comparison.

CALLED BY:	SysUnlockBIOS
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	3/7/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysComputeDOSBlockChecksums	proc	near
		uses ax, bx, cx, si, di, ds, es
		.enter
		pushf
		LoadVarSeg	ds
	;
	; Only compute if biosLock is about to be completely unlocked.
	;
		cmp	ds:[biosLock].TL_nesting, 1
		jne	done
	;
	; Iterate the DOSBlocks table, checksumming (is that a real word?)
	; each block and storing the result.
	;
		clr	ch
		mov	cl, ds:[numDOSBlocks]
		tst	cl
		jz	done
		mov	si, offset DOSBlocks
next:
		xchg	bx, cx
		segmov	es, ds:[si].dbSeg, ax
		mov	cx, ds:[si].dbSize
		call	SysComputeDBChecksum
		mov	ds:[si].dbSum, ax
		add	si, size DOSBlockStruct
		xchg	bx, cx
		loop	next
done:
		popf
		.leave
		ret
SysComputeDOSBlockChecksums	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCompareDOSBlockChecksums
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loop thru DOSBlocks, compute the checksums for each block,
		and compare them to the previously stored results.  If a 
		block has changed, EC will throw a FatalError, and NC will
		display a SysNotify box.

CALLED BY:	SysLockCommon
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	3/7/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCompareDOSBlockChecksums	proc	near
		uses ax, bx, cx, si, di, ds, es
		.enter
		pushf
		LoadVarSeg	ds
	;
	; Only compare if biosLock was locked for the first time.
	;
		cmp	ds:[biosLock].TL_nesting, 1
		jne	done
	;
	; If this is the first call, do nothing.  The checksums are not
	; initialized, and the FS skeleton driver has been making direct
	; int 21h calls up until now.  Allow the followup SysUnlockBIOS
	; to initialize the checksums and then all will be happy.
	;
		tst	ds:[DOSBlockInit]
		jz	notYet
	;
	; Iterate the DOSBlocks table, checksumming (is that a real word?)
	; each block and comparing the result with the previous results.
	;
		clr	ch
		mov	cl, ds:[numDOSBlocks]
		tst	cl
		jz	done
		mov	si, offset DOSBlocks
next:
		xchg	bx, cx
		segmov	es, ds:[si].dbSeg, ax
		mov	cx, ds:[si].dbSize
		call	SysComputeDBChecksum
		cmp	ds:[si].dbSum, ax
		jne	mismatch
		add	si, size DOSBlockStruct
		xchg	bx, cx
		loop	next
done:
		popf
		.leave
		ret
notYet:
		inc	ds:[DOSBlockInit]
		jmp	done
	;
	; Raiase a SysNotify error message.
	;
mismatch:
EC <		ERROR_NE DOS_BLOCK_CHECKSUM_CHANGED		>
		call	SysDBCFailure
		; allow shutdown to occur unchallenged
		clr	ds:[numDOSBlocks]
		jmp	done

SysCompareDOSBlockChecksums	endp

SysComputeDBChecksum	proc	near
	; es:0 = start of block
	; cx = length (in paragraphs) of block
		push	dx
		mov	dx, es
		clr	ax
next:
		add	ax, {word}es:00h	; sum this paragraph
		add	ax, {word}es:02h
		add	ax, {word}es:04h
		add	ax, {word}es:06h
		add	ax, {word}es:08h
		add	ax, {word}es:0ah
		add	ax, {word}es:0ch
		add	ax, {word}es:0eh
		inc	dx			; go to the next one
		mov	es, dx			; ack! Segment arithmetic!
		loop	next
		pop	dx
		ret
SysComputeDBChecksum	endp

SysDBCFailure	proc	near
	; ds:si = DOSBlockStruct that changed
	; ax = new checksum
newSum	local	word	push ax			; save new checksum
		uses	ds
		.enter
		mov	al, KS_DOS_BLOCK_CHECKSUM_BAD
		call	AddStringAtMessageBuffer

		inc	di			;put second string after first
		push	di
		mov	al, 'B'			; write "B"
		stosb
		mov	ax, ds:[si].dbSeg	; write segment
		call	Hex16ToAscii
		mov	ax, ('S' shl 8) or C_SPACE	; write " S"
		stosw
		mov	ax, ds:[si].dbSize	; write size
		call	Hex16ToAscii
		mov	ax, ('O' shl 8) or C_SPACE	; write " O"
		stosw
		mov	ax, ds:[si].dbSum	; write old sum
		call	Hex16ToAscii
		mov	ax, ('N' shl 8) or C_SPACE	; write " N"
		stosw
		mov	ax, ss:newSum		; write new sum
		call	Hex16ToAscii
		clr	al			; write null term
		stosb
		segmov	ds, es			; both strings are in dgroup...
		pop	di			; ds:di <- second string
		mov	si, offset messageBuffer	; ds:si <- first string
		mov	ax, mask SNF_EXIT
		call	SysNotify

		.leave
		ret
SysDBCFailure	endp

nibbles		db	"0123456789ABCDEF"
Hex16ToAscii	proc	near
		push	ax
		xchg	ah, al
		push	ax
		mov	bx, offset nibbles
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		and	al, 0fh
		xlatb	cs:
		stosb
		pop	ax
		and	al, 0fh
		xlatb	cs:
		stosb
		pop	ax
		push	ax
		mov	bx, offset nibbles
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		and	al, 0fh
		xlatb	cs:
		stosb
		pop	ax
		and	al, 0fh
		xlatb	cs:
		stosb
		ret
Hex16ToAscii	endp

endif	; CHECKSUM_DOS_BLOCKS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysUnlockCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform common module-unlock activities for the various
		module locks in the kernel. THIS MUST BE JUMPED TO

CALLED BY:	Unlock*
PASS:		bx	= offset in idata of the ThreadLock to unlock
		previous bx pushed on stack
RETURN:		doesn't.
DESTROYED:	nothing, not even flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysUnlockCommon	proc	near jmp
				on_stack	bx retn
		pushf
				on_stack	cc bx retn
		push	ds
				on_stack	ds cc bx retn
		LoadVarSeg	ds

		push	ax
				on_stack	ax ds cc bx retn
		UnlockModule	ds:[currentThread], ds, [bx], TRASH_AX_BX, \
				<ax ds cc bx retn>
		pop	ax
				on_stack	ds cc bx retn

		pop	ds
				on_stack	cc bx retn
		popf
				on_stack	bx retn
		pop	bx
				on_stack	retn
		ret
SysUnlockCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysPSemCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform common PSem activities for the various
		semaphores in the kernel. THIS MUST BE JUMPED TO

CALLED BY:	PSem*
PASS:		bx	= offset in idata of the Semaphore to P
		previous bx pushed on stack
RETURN:		doesn't.
DESTROYED:	nothing (carry flag preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysPSemCommon	proc	near jmp
				on_stack	bx retn
		push	ds
				on_stack	ds bx retn
		LoadVarSeg	ds

EC <		tst	ds:[interruptCount]				>
EC <		ERROR_NZ	NOT_ALLOWED_TO_PSEM_IN_INTERRUPT_CODE	>
		
		push	ax
				on_stack	ax ds bx retn
		PSem		ds, [bx], TRASH_AX_BX, NO_EC
		pop	ax
				on_stack	ds bx retn

		pop	ds
				on_stack	bx retn
		pop	bx
				on_stack	retn
		ret
SysPSemCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysVSemCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform common VSem activities for the various
		semaphores in kernel. THIS MUST BE JUMPED TO

CALLED BY:	VSem*
PASS:		bx	= offset in idata of the Semaphore to V
		previous bx pushed on stack
RETURN:		doesn't.
DESTROYED:	nothing, not even flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysVSemCommon	proc	near jmp
				on_stack	bx retn
		pushf
				on_stack	cc bx retn
		push	ds
				on_stack	ds cc bx retn
		LoadVarSeg	ds
				on_stack	ax ds cc bx retn

		push	ax
		VSem		ds, [bx], TRASH_AX_BX, NO_EC
		pop	ax
				on_stack	ds cc bx retn

		pop	ds
				on_stack	cc bx retn
		popf
				on_stack	bx retn
		pop	bx
				on_stack	retn
		ret
SysVSemCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysJmpVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Jump through a vector w/o destroying registers

CALLED BY:	Thread{Exception}Handlers
PASS: 		ds:bx	= vector
		on stack:
			sp ->	ds
				ax
				bx
				ret			
RETURN:		doesn't
DESTROYED:	ax, bx and ds restored to their values from entry to the
		interrupt.

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOIStack	struct
    SPOIS_bp		word
    SPOIS_ax		word
    SPOIS_bx		word
    SPOIS_retAddr	fptr.far
    SPOIS_flags		word
SPOIStack	ends

SysJmpVector proc far jmp
		on_stack	ds ax bx retf
	;
	; Fetch the old vector into ax and bx
	; 
	mov	ax, ds:[bx].offset
	mov	bx, ds:[bx].segment
	pop	ds

		on_stack	ax bx retf
	;
	; Now replace the saved ax and bx with the old vector, so we can
	; just perform a far return to get to the old handler.
	; 
	push	bp
		on_stack	bp ax bx retf
	mov	bp, sp
	xchg	ax, ss:[bp].SPOIS_ax
	xchg	bx, ss:[bp].SPOIS_bx
	pop	bp
		on_stack	retf
	ret
SysJmpVector endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysGetECLevel

DESCRIPTION:	Return value of sysECLevel

CALLED BY:	GLOBAL

PASS:
	Nothing
RETURN:
	ax - ErrorCheckingFlags
	bx - error checking block (valid if ECF_BLOCK_CHECKSUM)

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Get exclusive on default video driver

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

SysGetECLevel	proc	far

if	ERROR_CHECK
	push	ds
	LoadVarSeg	ds
	mov	ax, ds:[sysECLevel]	; fetch the error checking level
	mov	bx, ds:[sysECBlock]
	pop	ds
else
	clr	ax
	clr	bx
endif
	ret

SysGetECLevel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysSetECLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current error-check level

CALLED BY:	GLOBAL
PASS:		AX	= ErrorCheckingFlags
		BX	= error checking block (if any)
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SysSetECLevel	proc	far
if ERROR_CHECK
	push	ds
   	LoadVarSeg ds
	mov	ds:[sysECLevel], ax
	mov	ds:[sysECBlock], bx
	mov	ds:[sysECChecksum], 0		;invalid -- recalculate
	pop	ds
endif
	ret
SysSetECLevel	endp

Filemisc	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysGetDosEnvironment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks up an environment variable in the environment buffer.

CALLED BY:	GLOBAL
PASS:		ds:si - variable name to look up (null terminated)
		es:di - dest buffer to store data (null terminated string)
		cx - max # bytes to store in buffer including null
RETURN:		carry set if environment variable not found
DESTROYED:	none
 
PSEUDO CODE/STRATEGY:
		Data in Environment Block consists of null terminated strings
		of the form: <variable name>=<variable data>. The end of the 
		block comes when a null byte is found in place of the variable
		name.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
SysGetDosEnvironment	proc	far
		mov	ss:[TPD_dataBX], handle SysGetDosEnvironmentReal
		mov	ss:[TPD_dataAX], offset SysGetDosEnvironmentReal
		GOTO	SysCallMovableXIPWithDSSI
SysGetDosEnvironment	endp
CopyStackCodeXIP	ends

else

SysGetDosEnvironment	proc	far
	FALL_THRU	SysGetDosEnvironmentReal
SysGetDosEnvironment	endp

endif

SysGetDosEnvironmentReal	proc	far	uses	ax, bx, ds, si, cx, di
	.enter
EC <	call	FarCheckDS_ES						>
	push	es, di, cx

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx, si							>
EC <	movdw	bxsi, esdi						>
EC <	call	ECAssertValidFarPointerXIP				>
EC <	pop	bx, si							>
endif

;	GET LENGTH OF PASSED VARIABLE NAME

	segmov	es, ds, di		;ES:DI <- ptr to variable string
	mov	di, si
	mov	cx, -1
	clr	ax
        repne	scasb
	not	cx			;CX <- # bytes (sans null term)
	dec	cx			;If passed nullstring, return not found
	jcxz	notFound		;

	segmov	es, dgroup, di
	mov	es, es:[loaderVars].KLV_pspSegment
	mov	es, es:[PSP_envBlk]	;es:di <- env block
	clr	di
	mov	ax, di

;	SEARCH THROUGH THE ENVIRONMENT BLOCK 

varSearchTop:

;	ES:DI <- PTR TO ENVIRONMENT BLOCK ENTRY
;	DS:SI <- PTR TO VARIABLE NAME TO MATCH
;	CX <- # BYTES IN SOURCE STRING (NOT COUNTING NULL)	

	cmp	{byte} es:[di], 0	;At end of env block?
	jz	notFound		;Branch if so

	push	cx, si			;
	repe	cmpsb			;Compare source and dest strings
	pop	si			;
	jnz	noMatch			;Branch if they didn't match
	cmp	{byte} es:[di], '='	;If they matched, make sure next byte
	jz	match			; is '=' -- branch if so
noMatch:
					;AX is always 0 here
	mov	cx, -1
	repne	scasb			;ES:DI <- ptr beyond null terminator
	pop	cx
	jmp	varSearchTop
match:
	inc	sp
	inc	sp			;discard saved CX
	inc	di			;ES:DI <- ptr to variable data
	segmov	ds, es, si		;DS:SI <- ptr to variable data
	mov	si, di
	mov	cx, -1
	repne	scasb
	not	cx			;CX <- # bytes + null terminator
	pop	es, di, bx		;BX <- max # bytes to copy
					;ES:DI <- dest buffer
	cmp	cx, bx			;
	jle	80$			;
	mov	cx, bx			;
80$:
	rep	movsb			;
	mov	{byte} es:[di][-1], 0	;Null terminate the string
	clc
	jmp	exit
notFound:
	pop	es, di, cx
	stc
exit:
	.leave
	ret
SysGetDosEnvironmentReal	endp

Filemisc	ends


CopyStackCodeXIP	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCopyToStackDSBX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy passed parameter to stack

CALLED BY:	GLOBAL

PASS:		ds:bx	-> fptr to block to copy
		cx	-> size of buffer to copy
			   (0 if null terminated string (DBCS or SBCS))

RETURN:		ds:bx	<- fptr to block on stack

DESTROYED:	nothing

SIDE EFFECTS:
		Modifies TPD_stackBot to reserve space on stack

PSEUDO CODE/STRATEGY:
		Fiddle with pointers, then call SysCopyToStack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCopyToStackDSBXFar	proc	far
if	FULL_EXECUTE_IN_PLACE
	call	SysCopyToStackDSBX
endif
	ret
SysCopyToStackDSBXFar	endp

if	FULL_EXECUTE_IN_PLACE
SysCopyToStackDSBX	proc	near
	xchg	si, bx

	call	SysCopyToStack

	xchg	bx, si
	ret
SysCopyToStackDSBX	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCopyToStackDSDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy passed parameter to stack

CALLED BY:	GLOBAL

PASS:		ds:dx	-> fptr to block to copy
		cx	-> size of buffer to copy
			   (0 if null terminated string (DBCS or SBCS))

RETURN:		ds:dx	<- fptr to block on stack

DESTROYED:	nothing

SIDE EFFECTS:
		Modifies TPD_stackBot to reserve space on stack

PSEUDO CODE/STRATEGY:
		Fiddle with pointers, then call SysCopyToStack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCopyToStackDSDXFar	proc	far
if	FULL_EXECUTE_IN_PLACE
	call	SysCopyToStackDSDX
endif
	ret
SysCopyToStackDSDXFar	endp

if	FULL_EXECUTE_IN_PLACE
SysCopyToStackDSDX	proc	near
	xchg	si, dx

	call	SysCopyToStack

	xchg	dx, si
	ret
SysCopyToStackDSDX	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCopyToStackBXSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy passed parameter to stack

CALLED BY:	GLOBAL

PASS:		bx:si	-> fptr to block to copy
		cx	-> size of buffer to copy
			   (0 if null temrinated string (DBCS or SBCS))

RETURN:		bx:si	<- fptr to block on stack

DESTROYED:	nothing

SIDE EFFECTS:
		Modified TPD_stackBot to reserve space on stack

PSEUDO CODE/STRATEGY:
		Fiddle with pointers, then call SysCopyToStack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCopyToStackBXSIFar	proc	far
if	FULL_EXECUTE_IN_PLACE
	call	SysCopyToStackBXSI
endif
	ret
SysCopyToStackBXSIFar	endp

if	FULL_EXECUTE_IN_PLACE
SysCopyToStackBXSI	proc	near
	segxchg	bx, ds

	call	SysCopyToStack

	segxchg	ds, bx
	ret
SysCopyToStackBXSI	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCopyToStackESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy passed parameter to stack

CALLED BY:	GLOBAL

PASS:		es:di	-> fptr to block to copy
		cx	-> size of buffer to copy
			   (0 if null termined string (DBCS or SBCS))

RETURN:		es:di	<- fptr to block on stack

DESTROYED:	nothing

SIDE EFFECTS:
		Allocates space on bottom of stack (below TPD_stackBot)

PSEUDO CODE/STRATEGY:
		Swap the pointers around so we can call SysCopyToStack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCopyToStackESDIFar	proc	far
if	FULL_EXECUTE_IN_PLACE
	call	SysCopyToStackESDI
endif
	ret
SysCopyToStackESDIFar	endp

if	FULL_EXECUTE_IN_PLACE
SysCopyToStackESDI	proc	near
	xchg	si, di					; ds:si <- buffer
	segxchg	ds, es					

	call	SysCopyToStack		; ds:si <- new buffer on stack
	
	segxchg	es, ds					; es:di <- new buffer
	xchg	di, si
	ret
SysCopyToStackESDI	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCopyToStack, SysCopyToStackDSSI, SysCopyToStackDSSIFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move a passed in parameter block to the stack

CALLED BY:	SysCopyToStack*

PASS:		ds:si	-> block to copy
		cx	-> size (or zero if null terminated)

RETURN:		ds:si	<- buffer on stack

DESTROYED:	nothing

SIDE EFFECTS:
		Modifies TPD_stackBot.  This reduces the amount of stack
		space temporarily available to the thread, but it has the
		same affect as allocating the space on the stack, and this
		method doesn't mess up the call stack.

		It all gets returned to the thread in the end...

PSEUDO CODE/STRATEGY:

		As opposed to mucking about with the stack (my idea), Andrew
		suggested we just copy the needed data to the TPD_stackBot,
		and adjust TPD_stackBot so that we don't worry about it being
		written over.

		This is inspired, and he should be given a large golden
		plack indicating what a computer stud he is.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC_VALUE	equ	042294
SysCopyToStackStruct	struct
	SCTSS_oldBottom	word
	;The old bottom of the stack

	SCTSS_siDifference	word
	;The difference between the old value of SI and new value. We can
	; convert between pointers into the copied buffer and the original
	; buffer by adding this difference to the pointer.

	SCTSS_restoreRegsRout	nptr.near
	;The routine to call to restore registers when
	; SysRemoveFromStackPreserveRegs is called

EC <	SCTSS_ecValue	word					>
	;An EC value we store/check to make sure the stack isn't
	; mangled.
SysCopyToStackStruct	ends

SysCopyToStackDSSIFar	proc	far
if	FULL_EXECUTE_IN_PLACE
	call	SysCopyToStack
endif
	ret
SysCopyToStackDSSIFar	endp

if	FULL_EXECUTE_IN_PLACE
SysCopyToStackDSSI	label	near
SysCopyToStack		proc	near
	uses	ax, bp
	.enter
	pushf
	;
	;  First things first.  See if the value needs to be copied
	;  to the stack at all (if it's not in an XIP resource,
	;  we don't need to worry about it.)
	push	ds
	mov	ax, ds			; ax <- current segment
	LoadVarSeg	ds
	sub	ax, ds:[loaderVars].KLV_mapPageAddr
	pop	ds
	jc	noCopy		; => Below XIP segment

	cmp	ax, (MAPPING_PAGE_SIZE/16)
	jb	copy		; => In XIP segment

noCopy:
	;
	;  No need to copy it, but we still need to leave the
	;  stack in a state that SysReturnStack will understand.
	mov	bp, ss:[TPD_stackBot]		; bp <- current bottom
	add	ss:[TPD_stackBot], size SysCopyToStackStruct
				; Make space for structure
	
	mov	ss:[bp].SCTSS_oldBottom, bp	; Store old stackBot value
	clr	ss:[bp].SCTSS_siDifference
EC <	clr	ss:[bp].SCTSS_restoreRegsRout				>
EC <	mov	ss:[bp].SCTSS_ecValue, EC_VALUE 			>
					; Store sentinel to check for stack
					; mangling


done:
	popf
	;
	;  With that done, let's return...
	.leave

	ret

copy:
	push	cx, di, es			; save trashed registers

	;
	;  Now, with the case of null terminated strings, we
	;  won't know the length until we scan the string.  Sigh.
	;  See if we need to scan the list, or if we were passed
	;  in the string length
	jcxz	getLength	; => look for null
reserveSpaceOnStack:

	;
	;  With the correct length available (for whatever reason),
	;  we now reserve space at the base of the stack and
	;  move the data over.
	mov	ax, ss:[TPD_stackBot]		; ax <- original stack bottom

	;
	;  To reserve space, we adjust the stack bottom so
	;  we have room to copy the buffer, the previous stack
	;  bottom, and possibly an EC value as well.
	segmov	es, ss, di			; es:di <- new buffer
	mov	di, ax

	mov	bp, ax				; bp <- current stack bottom
	add	bp, cx				; reserve space at base of stack
	add	bp, size SysCopyToStackStruct

	;
	;  Now that we know what we want to change the stackBot
	;  to, let's make sure we don't overwrite the existing
	;  stack, shall we?
EC <	cmp	bp, sp							>
EC <	ERROR_AE	STACK_OVERFLOW 					>

	mov	ss:[TPD_stackBot], bp		; mark new bottom of stack

	mov	ss:[bp - size SysCopyToStackStruct].SCTSS_oldBottom, ax
	mov	ss:[bp - size SysCopyToStackStruct].SCTSS_siDifference, si
	sub	ss:[bp - size SysCopyToStackStruct].SCTSS_siDifference, ax
						; store original stack bottom
EC <	mov	ss:[bp - size SysCopyToStackStruct].SCTSS_restoreRegsRout,0 >
EC <	mov	ss:[bp - size SysCopyToStackStruct].SCTSS_ecValue, EC_VALUE>
						; mark with special value
EC <	call	ECCheckStack						>
	;
	;  Now that that has been taken care of, copy the buffer
	;  to the stack, storing the start of the buffer for later.
	shr	cx, 1			; convert from byte to words...
	rep	movsw			; move all the words...
	jnc	cleanUp	; => even byte length
	movsb				; and the byte...

cleanUp:
	mov_tr	si, ax				; ds:si <- buffer
	segmov	ds, ss, ax

	pop	cx, di, es			; restore trashed registers
	jmp	done

getLength:
	;
	;  Get the length of the passed in null-terminated string
	;  worrying about DBCS...
	segmov	es, ds, ax			; es:di <- length
	mov	di, si
	LocalStrSize	<includeNull>		; cx <- length
						; ax, di destroyed
	jmp	reserveSpaceOnStack
SysCopyToStack	endp
endif
ForceRef	SysCopyToStack

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysRemoveFromStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore Stack space used to hold parameters

CALLED BY:	INTERNAL

PASS:		ss:sp	-> as returned by SysCopyToStack

RETURN:		ss:sp	-> as before call to SysCopyToStack

DESTROYED:	nothing

SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Get value at top of bottom of stack and
		assign it as new bottom of stack.

		For EC, make sure our value is there as well...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysRemoveFromStackFar	proc	far
if	FULL_EXECUTE_IN_PLACE
	call	SysRemoveFromStack
endif
	ret
SysRemoveFromStackFar	endp

if	FULL_EXECUTE_IN_PLACE
SysRemoveFromStack	proc	near
	uses	bp
	.enter
	mov	bp, ss:[TPD_stackBot]

EC <	pushf								>
EC <	cmp	ss:[bp-size SysCopyToStackStruct].SCTSS_ecValue, EC_VALUE>
EC <	ERROR_NE SYS_COPY_TO_STACK_ERROR_BOTTOM_OF_STACK_MANGLED	>
EC <	popf								>

	mov	bp, ss:[bp-size SysCopyToStackStruct].SCTSS_oldBottom
							;bp <- old stackBot
EC <	pushf								>
EC <	cmp	bp, ss:[TPD_stackBot]					>
EC <	ERROR_AE	SYS_COPY_TO_STACK_ERROR_BOTTOM_OF_STACK_MANGLED >
EC <	popf								>

	mov	ss:[TPD_stackBot], bp

EC<	call	ECCheckStack						>
	.leave
	ret
SysRemoveFromStack	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCopyToStackPreserve*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls SysCopyToStack, but stores a routine to call to restore
		the registers afterwards.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		registers munged
DESTROYED:	nada (flags preserved)
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysCopyToStackPreserveDSDX	proc	near
	mov	ss:[TPD_callTemporary], offset SysRemoveFromStackPreserveDX
	xchg	dx, si
	call	SysCopyToStackPreserveCommon
	xchg	dx, si
	ret
SysCopyToStackPreserveDSDX	endp

if 0
SysCopyToStackPreserveDSBX	proc	near
	mov	ss:[TPD_callTemporary], offset SysRemoveFromStackPreserveBX
	xchg	bx, si
	call	SysCopyToStackPreserveCommon
	xchg	bx, si
	ret
SysCopyToStackPreserveDSBX	endp
endif

SysCopyToStackPreserveESDI	proc	near
	xchg	si, di
	segxchg	ds, es
	mov	ss:[TPD_callTemporary], offset SysRemoveFromStackPreserveDI
	call	SysCopyToStackPreserveCommon
	segxchg	ds, es
	xchg	si, di
	ret
SysCopyToStackPreserveESDI	endp

SysCopyToStackPreserveDSDI	proc	near
	mov	ss:[TPD_callTemporary], offset SysRemoveFromStackPreserveDI
	xchg	si, di
	call	SysCopyToStackPreserveCommon
	xchg	si, di
	ret
SysCopyToStackPreserveDSDI	endp

SysCopyToStackPreserveDXSI	proc	near
	mov	ss:[TPD_callTemporary], offset SysRemoveFromStackPreserveSI
	xchg	bx, dx
	call	SysCopyToStackPreserveCommon
	xchg	bx, dx
	ret
SysCopyToStackPreserveDXSI	endp

SysCopyToStackPreserveDSSI	proc	near
	mov	ss:[TPD_callTemporary], offset SysRemoveFromStackPreserveSI
	FALL_THRU	SysCopyToStackPreserveCommon
SysCopyToStackPreserveDSSI	endp

SysCopyToStackPreserveCommon		proc	near	uses	bp, ax
	.enter
	call	SysCopyToStackDSSI
	mov	bp, ss:[TPD_stackBot]
	mov	ax, ss:[TPD_callTemporary]
	mov	ss:[bp - size SysCopyToStackStruct].SCTSS_restoreRegsRout, ax
	.leave
	ret
SysCopyToStackPreserveCommon	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysRemoveFromStackPreserveRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the appropriate routine to remove the data from the
		stack and preserve register values (we have to go through
		these shenanigans because we copy data to the stack, and
		call routines, that return pointers into that data, so we
		need to modify those pointers to return to the correct place.

CALLED BY:	GLOBAL
PASS:		various
RETURN:		regs updated
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysRemoveFromStackPreserveRegs	proc	near	uses	bp
	.enter
	mov	bp, ss:[TPD_stackBot]

EC <	pushf								>
EC <	cmp	ss:[bp-size SysCopyToStackStruct].SCTSS_ecValue, EC_VALUE>
EC <	ERROR_NE SYS_COPY_TO_STACK_ERROR_BOTTOM_OF_STACK_MANGLED	>
EC <	cmp	ss:[bp - size SysCopyToStackStruct].SCTSS_restoreRegsRout,0 >
EC <	ERROR_Z	SYS_COPY_TO_STACK_ERROR_NO_RESTORE_REGS_ROUTINE		>
EC <	popf								>

	call	ss:[bp - size SysCopyToStackStruct].SCTSS_restoreRegsRout
	.leave
	ret
SysRemoveFromStackPreserveRegs	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysRemoveFromStackPreserve*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restores registers after a call to a routine that may have
		changed them, and updates the stack

CALLED BY:	GLOBAL
PASS:		various regs
RETURN:		regs updated
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysRemoveFromStackPreserveDI	proc	near
	xchg	si, di
	call	SysRemoveFromStackPreserveSI
	xchg	si, di
	ret
SysRemoveFromStackPreserveDI	endp

SysRemoveFromStackPreserveDX	proc	near
	xchg	si, dx
	call	SysRemoveFromStackPreserveSI
	xchg	si, dx
	ret
SysRemoveFromStackPreserveDX	endp

if 0
SysRemoveFromStackPreserveBX	proc	near
	xchg	si, bx
	call	SysRemoveFromStackPreserveSI
	xchg	si, bx
	ret
SysRemoveFromStackPreserveBX	endp
endif

SysRemoveFromStackPreserveSI	proc	near	uses	bp
	.enter
	pushf
	mov	bp, ss:[TPD_stackBot]
	add	si, ss:[bp - size SysCopyToStackStruct].SCTSS_siDifference
	popf
	call	SysRemoveFromStack
	.leave
	ret
SysRemoveFromStackPreserveSI	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCopyToBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block and copy data into it.

CALLED BY:	INTERNAL

PASS:		ds:si	= address of data to copy
		cx	= size of data

RETURN:		carry set if insufficient memory, else
		ds:si	= address to copy of data
		bx	= handle of locked data block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOTE:	Caller is responsible for freeing block.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/19/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCopyToBlockFar	proc	far
if	FULL_EXECUTE_IN_PLACE
	call	SysCopyToBlock
endif
	ret
SysCopyToBlockFar	endp

if	FULL_EXECUTE_IN_PLACE
SysCopyToBlock	proc	near
		uses	ax,cx,di
		.enter
	;
	; Allocate a locked block for the data.
	;		
		push	cx				; save size for copy
		mov_tr	ax, cx				; ax = size of data
		mov	cx, ALLOC_FIXED
		call	MemAllocFar			; ^hbx = block
							; ax = address of block
		pop	cx				; cx = size of data
		jc	exit				; no more memory...
	;
	; Copy the data to the block.
	;
		mov	es, ax
		clr	di				; es:di = dest of copy
		
		shr	cx, 1				; convert byte to words
		rep	movsw
		jnc	done				; even byte length
		movsb					; and the byte...
done:
		segmov	ds, es, si
		clr	si				; ds:si = copied data
		clc					; all is well
exit:
		.leave
		ret
SysCopyToBlock	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallMovableXIPWithDSSIAndESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a movable routine passing DS:SI and ES:DI on stack

CALLED BY:	INTERNAL

PASS:		ds:dx	-> 1st buffer to pass
		es:di	-> 2nd buffer to pass
		TPD_dataBX:TPD_dataAX -> handle:offset of routine to call

RETURN:		As per routine

DESTROYED:	si, di, ds, es unchanged
		others as per routine
		
SIDE EFFECTS:	
		Copies blocks to stack

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysCallMovableXIPWithDSSIAndESDI	proc	far		uses	ds, es
	.enter

;	On full-XIP systems, we need to copy the data to the stack, but
;	also return a pointer into that data, so calculate the amount
;	the pointer changes, and return the original pointer, modified by
;	the passed amount.

	push	cx
	clr	cx
	call	SysCopyToStackPreserveDSSI
	pop	cx

	mov	ss:[TPD_callTemporary], offset SysCopyToStackPreserveESDI
	call	SysCallMovableXIP

	call	SysRemoveFromStackPreserveRegs
	.leave
	ret
SysCallMovableXIPWithDSSIAndESDI	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallMovableXIPWithDSDXAndESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies ds:dx and es:di to the stack before calling a movable
		routine

CALLED BY:	various
PASS:		ds:dx, es:di - null terminated strings
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysCallMovableXIPWithDSDXAndESDI	proc	far
	uses	ds, es
	.enter
	push	cx
	clr	cx
	call	SysCopyToStackPreserveDSDX
	pop	cx

	mov	ss:[TPD_callTemporary], offset SysCopyToStackPreserveESDI
	call	SysCallMovableXIP

	call	SysRemoveFromStackPreserveRegs
	.leave
	ret
SysCallMovableXIPWithDSDXAndESDI	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallMovableXIPWithDSDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a movable routine with ds:dx pointing to valid parameter

CALLED BY:	INTERNAL

PASS:		ds:dx	-> Parameters to copy to stack (null terminated)
		TPD_dataBX:TPD_dataAX -> handle:offset to routine to call
						after copying to stack
		Others as per Routine

RETURN:		As per routine

DESTROYED:	dx, ds unchanged
		others as per routine

SIDE EFFECTS:
		Copies block to stack

PSEUDO CODE/STRATEGY:
		Copy the parameter block to the stack
		Call the specified routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysCallMovableXIPWithDSDX	proc	far
	uses	ds
	.enter
	mov	ss:[TPD_callTemporary], offset SysCopyToStackPreserveDSDX
	call	SysCallMovableXIP
	.leave
	ret
SysCallMovableXIPWithDSDX	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallMovableXIPWithDSBX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a movable routine with ds:bx pointing to valid parameter

CALLED BY:	INTERNAL

PASS:		ds:bx	-> Parameters to copy to stack (null terminated)
		TPD_dataBX:TPD_dataAX -> handle:offset to routine to call
						after copying to stack
		Others as per Routine

RETURN:		As per routine

DESTROYED:	bx, ds unchanged
		others as per routine

SIDE EFFECTS:
		Copies block to stack

PSEUDO CODE/STRATEGY:
		Copy the parameter block to the stack
		Call the specified routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
if	FULL_EXECUTE_IN_PLACE
SysCallMovableXIPWithDSBX	proc	far
	uses	ds
	.enter
	mov	ss:[TPD_callTemporary], offset SysCopyToStackPreserveDSBX
	call	SysCallMovableXIP
	.leave
	ret
SysCallMovableXIPWithDSBX	endp
endif 
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallMovableXIPWithESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a movable routine with es:di pointing to valid parameter

CALLED BY:	INTERNAL

PASS:		es:di	-> Parameters to copy to stack (null terminated)
		TPD_dataBX:TPD_dataAX -> handle:offset to routine to call
						after copying to stack
		Others as per Routine

RETURN:		As per routine

DESTROYED:	di, es unchanged
		others as per routine

SIDE EFFECTS:
		Copies block to stack

PSEUDO CODE/STRATEGY:
		Copy the parameter block to the stack
		Call the specified routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysCallMovableXIPWithESDI	proc	far
	uses	es
	.enter
	mov	ss:[TPD_callTemporary], offset SysCopyToStackPreserveESDI
	call	SysCallMovableXIP
	.leave
	ret
SysCallMovableXIPWithESDI	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallMovableXIPWithDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a movable routine with ds:si pointing to valid parameter

CALLED BY:	INTERNAL

PASS:		ds:si	-> Parameters to copy to stack (null terminated)
		TPD_dataBX:TPD_dataAX -> handle:offset to routine to call
						after copying to stack
		Others as per Routine

RETURN:		As per routine

DESTROYED:	si, ds unchanged
		others as per routine

SIDE EFFECTS:
		Copies block to stack

PSEUDO CODE/STRATEGY:
		Copy the parameter block to the stack
		Call the specified routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysCallMovableXIPWithDSSI	proc	far
	uses	ds
	.enter
	mov	ss:[TPD_callTemporary], offset SysCopyToStackPreserveDSSI
	call	SysCallMovableXIP
	.leave
	ret
SysCallMovableXIPWithDSSI	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallMovableXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a passed routine, saving the specified parameter
		block on the stack if needed

CALLED BY:	INTERNAL

PASS:		ss:[TPD_callTemporary] -> near SysCopyTo* to call
		fptr of routine call after copy stored in:
			ss:[TPD_dataBX]:ss:[dataAX]
			( that is dataBX is handle, dataAX is offset)

RETURN:		as per routine

DESTROYED:	as per SysCopyTo* routine

SIDE EFFECTS:
		Copies and frees block on the stack

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysCallMovableXIP	proc	near
	.enter
	;
	;  Copy parameter to stack (assume null terminated)
	push	cx
	clr	cx
	call	ss:[TPD_callTemporary]
	pop	cx

	;
	;  Call routine passing correct values in AX & BX
	xchg	ss:[TPD_dataBX], bx		; bx <- handle
	xchg	ss:[TPD_dataAX], ax		; ax <- offset
	call	ProcCallModuleRoutine

	;
	;  Remove parameter from stack
	call	SysRemoveFromStackPreserveRegs
	.leave
	ret
SysCallMovableXIP	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallMovableXIPWithDSDIBlock /*DSSIBlock /*DXSIBlock...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a movable routine with ds:di/ds:si/dx:si pointing to 
		a valid	parameter.

CALLED BY:	INTERNAL

PASS:		ds:di/ds:si/dx:si -> Parameters to copy to stack 
		TPD_dataBX:TPD_dataAX -> handle:offset to routine to call
						after copying to stack
		TPD_callVector.segment -> size of data to copy to stack 

RETURN:		As per routine

DESTROYED:	ds, di unchanged (or ds, si or dx, si, depending on routine)
		others as per routine

SIDE EFFECTS:
		Copies block to stack

PSEUDO CODE/STRATEGY:
		Copy the parameter block to the stack
		Call the specified routine

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/11/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	
SysCallMovableXIPWithDSDIBlock	proc	far
		uses	ds
		.enter
		
		mov	ss:[TPD_callTemporary], offset SysCopyToStackPreserveDSDI
		call	SysCallMovableXIPBlock
		
		.leave
		ret
SysCallMovableXIPWithDSDIBlock	endp

SysCallMovableXIPWithDSSIBlock	proc	far
		uses	ds
		.enter
	
		mov	ss:[TPD_callTemporary], offset SysCopyToStackPreserveDSSI
		call	SysCallMovableXIPBlock
		
		.leave
		ret
SysCallMovableXIPWithDSSIBlock	endp

SysCallMovableXIPWithDXSIBlock	proc	far
		uses	dx
		.enter
	
		mov	ss:[TPD_callTemporary], offset SysCopyToStackPreserveDXSI
		call	SysCallMovableXIPBlock
		
		.leave
		ret
SysCallMovableXIPWithDXSIBlock	endp
endif
	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallMovableXIPWithDSSIAndESDIBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a movable routine with ds:si and es:di pointing to 
		a valid	parameter.

CALLED BY:	INTERNAL

PASS:		es:di	-> Parameter to copy to stack 
		ds:si	-> Parameter to copy to stack
		TPD_dataBX:TPD_dataAX -> handle:offset to routine to call
						after copying to stack
		TPD_callVector.segment -> size of data to copy to stack 
				( Data in es:di and ds:si MUST be same size!)

RETURN:		As per routine

DESTROYED:	ds, di unchanged
		others as per routine

SIDE EFFECTS:
		Copies block to stack

PSEUDO CODE/STRATEGY:
		Copy the parameter block to the stack
		Call the specified routine

		Copy ESDI data to stack first so we don't have 
		to write a SysCallMovableXIPWithESDIBlock.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/11/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysCallMovableXIPWithDSSIAndESDIBlock	proc	far
		uses	ds, es
		.enter
		
		push	cx
		mov	cx, ss:[TPD_callVector].segment	; cx = size
		call	SysCopyToStackPreserveESDI
		pop	cx

		mov	ss:[TPD_callTemporary], offset SysCopyToStackPreserveDSSI
		call	SysCallMovableXIPBlock

		call	SysRemoveFromStackPreserveRegs
	
		.leave
		ret
SysCallMovableXIPWithDSSIAndESDIBlock	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCallMovableXIPBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a passed routine, saving the specified parameter
		block on the stack if needed

CALLED BY:	INTERNAL

PASS:		ss:[TPD_callTemporary] -> near SysCopyTo* to call
		ss:[TPD_callVector].segment -> size of data to be copied
		fptr of routine to call after copy stored in:
			ss:[TPD_dataBX]:ss:[dataAX]
			( that is dataBX is handle, dataAX is offset)
RETURN:		as per routine

DESTROYED:	as per SysCopyTo* routine

SIDE EFFECTS:
		Copies and frees block on the stack.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/11/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
SysCallMovableXIPBlock	proc	near
	;
	; Copy paramter to stack.
	;
		push	cx
		mov	cx, ss:[TPD_callVector].segment	; cx = size
		call	ss:[TPD_callTemporary]
		pop	cx
	
	;
	; Call routine passing correct values in AX & BX
	;
		xchg	ss:[TPD_dataBX], bx		; bx <- handle
		xchg	ss:[TPD_dataAX], ax		; ax <- offset
		call	ProcCallModuleRoutine

	;
	;  Remove parameter from stack
	;
		call	SysRemoveFromStackPreserveRegs
		ret
SysCallMovableXIPBlock	endp
endif

CopyStackCodeXIP		ends
