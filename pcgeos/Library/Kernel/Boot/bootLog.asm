COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bootLog.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	LogInit			INTERNAL - Intialize log file

	LogWriteInitEntry	GLOBAL - write an entry to the log file
					preceeded by the word "Initializing "

	LogWriteEntry		GLOBAL - write an entry to the log file

	LogTerminateEntry	INTERNAL - terminate an entry with a CR, LF
					and commits the file as well

	LogWriteString		INTERNAL
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision
	Doug	8/91		Moved from UI to kernel

DESCRIPTION:
	Allows the system to write stuff out to a log file.
	Belongs logically to the file module in the kernel but there's
	no need for this stuff to be in fixed memory.
		
	$Id: bootLog.asm,v 1.1 97/04/05 01:10:54 newdeal Exp $

-------------------------------------------------------------------------------@



COMMENT @-----------------------------------------------------------------------

FUNCTION:	LogInit

DESCRIPTION:	Called to initialize the log file.

CALLED BY:	INTERNAL
		BootInit

PASS:		ds - dgroup

RETURN:		

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

LocalDefNLString	logFilename <"GEOS.LOG", 0			>
logBeginString		char	"Logging On", 0

LogInit	proc	near	uses	ax, cx, dx, si
	.enter

	call	LogTestIfLogging		; make sure logging
	jc	done

	call	FilePushDir
	push	ds
	segmov	ds, cs, si

	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath		; change to system dir

	mov	ax, ((FILE_CREATE_TRUNCATE or mask FCF_NATIVE) shl 8) or \
			(FILE_DENY_W or FILE_ACCESS_RW)
	clr	cx				; no special file attrs
	mov	dx, offset cs:logFilename

	;
	;  Unless there is a dos present, there is no point
	;	in creating a log file, as no one can look
	;	at it...
	call	FileCreate			; ax <- file handle	
	jnc	storeHan						

	clr	ax

storeHan:							
	pop	ds				; ds <- dgroup
	mov	ds:logFileHan, ax
	call	FilePopDir

	push	ds
	mov	ds, si
	mov	si, offset logBeginString
	call	LogWriteEntry
	pop	ds

	clc
done:
	.leave
	ret

LogInit	endp




COMMENT @-----------------------------------------------------------------------

FUNCTION:	LogWriteInitEntry

DESCRIPTION:	Writes a string to the log preceeded by the word
		"Initializing ".

CALLED BY:	GLOBAL

PASS:		ds:si - string to write to the log
			There is no need for a preceeding space.

RETURN:		carry set if error

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

; strings

logInitStr		char	"Initializing ", 0
SBCS <logCRLFStr	char	VC_ENTER, VC_LF, 0			>
DBCS <logCRLFStr	char	C_ENTER, C_LINEFEED, 0			>

if DBCS_PCGEOS
LogWriteDBCSEntry	proc	far
	uses	ds, si, es, di, ax
	.enter

	sub	sp, 256
	segmov	es, ss
	mov	di, sp				;es:di <- ptr to dest buffer
charLoop:
	lodsw					;ax <- get DBCS char
	stosb					;<- store SBCS char
	tst	ax				;NULL?
	jnz	charLoop			;loop until reached NULL

	segmov	ds, ss
	mov	si, sp				;ds:si <- ptr to SBCS string
	call	LogWriteInitEntry

	add	sp, 256

	.leave
	ret
LogWriteDBCSEntry	endp
endif


if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
LogWriteInitEntry	proc	far
		mov	ss:[TPD_dataBX], handle LogWriteInitEntryReal
		mov	ss:[TPD_dataAX], offset LogWriteInitEntryReal
		GOTO	SysCallMovableXIPWithDSSI
LogWriteInitEntry	endp
CopyStackCodeXIP	ends

else

LogWriteInitEntry	proc	far
		FALL_THRU	LogWriteInitEntryReal
LogWriteInitEntry	endp

endif

LogWriteInitEntryReal	proc	far	uses	ax, bx,cx,dx,ds	
	.enter

	call	LogTestIfLogging		; make sure logging
	jc	done

	mov	bx, ds
	mov	cx, si			; save ds:si

	mov	dx, dgroup		; dx <- dgroup
	mov	ds, dx
	PSem	ds, logFileSem		; grab semaphore

	segmov	ds, cs, si
	mov	si, offset logInitStr
	call	LogWriteString		; write "Initializing "
	mov	ds, bx			; restore ds:si
	mov	si, cx
	jc	exit

	call	LogWriteString
	jc	exit

	call	LogTerminateEntry

exit:
	mov	ds, dx			; ds <- dgroup
	VSem	ds, logFileSem		; release semaphore

done:
	.leave
	ret

LogWriteInitEntryReal	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LogWriteEntry

DESCRIPTION:	Writes a string out to the log file with a trailing
		CR, LF.

		We ensure that the info in the file is current by always
		commiting all output.

CALLED BY:	GLOBAL

PASS:		ds:si - offset to string

RETURN:		carry set if error

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
LogWriteEntry	proc	far
		mov	ss:[TPD_dataBX], handle LogWriteEntryReal
		mov	ss:[TPD_dataAX], offset LogWriteEntryReal
		GOTO	SysCallMovableXIPWithDSSI
LogWriteEntry	endp
CopyStackCodeXIP	ends

else

LogWriteEntry	proc	far
		FALL_THRU	LogWriteEntryReal
LogWriteEntry	endp

endif

LogWriteEntryReal	proc	far	uses	ax, dx, ds
	.enter

	call	LogTestIfLogging		; make sure logging
	jc	done

	push	ds
	mov	dx, dgroup
	mov	ds, dx
	PSem    ds, logFileSem          ; grab semaphore
	pop	ds

	call	LogWriteString
	jc	exit

	call	LogTerminateEntry

exit:
	mov	ds, dx
	VSem    ds, logFileSem          ; release semaphore

done:
	.leave
	ret

LogWriteEntryReal	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LogTerminateEntry

DESCRIPTION:	Terminates the current entry with a Carraige Return, Line Feed.
		The log file is also commited.

CALLED BY:	INTERNAL
		LogWriteInitEntry
		LogWriteEntry

PASS:		logFileSem grabbed

RETURN:		carry set if error

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

LogTerminateEntry	proc	near	uses	ax,bx,ds,si
	.enter
	segmov	ds, cs, si
	mov	si, offset logCRLFStr
	call	LogWriteString
	jc	done

	mov	bx, dgroup
	mov	ds, bx
	mov	bx, ds:logFileHan		; bx <- file handle
	tst	bx
	jz	done
	clr	al
	call	FileCommit
done:
	.leave
	ret

LogTerminateEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LogWriteString

DESCRIPTION:	Writes a string out to the log file WITHOUT a trailing
		CR, LF.  A FileCommit is not done.  Use LogTerminateEntry
		when termination and commiting are desired.

		We ensure that the info in the file is current by always
		commiting all output.

CALLED BY:	INTERNAL
		LogWriteInitEntry
		LogWriteEntry

PASS:		ds:si - offset to string
		logFileSem grabbed

RETURN:		carry set if error

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

LogWriteString	proc	near	uses	ax, bx, cx, dx, ds, es, di, si
	.enter
	mov	bx, dgroup
	mov	es, bx			; es <- dgroup
	mov	bx, es:logFileHan	; bx <- file handle

	tst	bx
	jz	writeThroughBIOS

	segmov	es, ds, dx
	mov	dx, si			; ds:dx <- string
	mov	di, dx			; es:di <- string

	clr	al			; locate null
	mov	cx, 0ffffh
	repne	scasb
	not	cx			; cx <- length of string
	dec	cx

	clr	al
	call	FileWriteFar		; write string out

done:
	.leave
	ret

writeThroughBIOS:
	lodsb
	tst	al
	jz	done
	mov	ah, 0xe			; output a single character
	int	10h
	jmp	writeThroughBIOS
LogWriteString	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	LogTestIfLogging

DESCRIPTION:	Check to see if logging is turned on or not

CALLED BY:	INTERNAL
		LogInit
		LogWriteInitEntry
		LogWriteEntry

PASS:	nothing

RETURN:
	carry	- clear if logging,
		  set if logging turned off

DESTROYED:
	al, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/91		Initial version
------------------------------------------------------------------------------@

LogTestIfLogging	proc	near
	call	SysGetConfig		; al <- config flags, dx destroyed
	test	al, mask SCF_LOGGING
	clc				; yes, go ahead...
	jne	done
	stc				; NO!  we're not logging -- exit w/err
done:
	ret

LogTestIfLogging	endp

