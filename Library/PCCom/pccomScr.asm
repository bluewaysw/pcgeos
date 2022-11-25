COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        PCCom Library
FILE:		pccomScr.asm

AUTHOR:		Cassie Hartzog, Nov 11, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	11/11/93	Initial revision


DESCRIPTION:
	

	$Id: pccomScr.asm,v 1.1 97/04/05 01:26:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

parseSeq	dw	?		; Place to store escape sequence
parseFlags	db	0		; Parser state flags
SCRGETFIRST	equ	00000001b	; Get first char of esc sequence
SCRGETSECOND	equ	00000010b	; Get second char of esc sequence
delimiter	db	DEFAULT_DELIMITER ; default argument delimiter
		even
idata 	ends

Main		segment resource

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the input sequence coming over the serial line.

CALLED BY:	ConsumeOneByte

PASS:		AL = character 
		ds, es - dgroup

RETURN:		Nothing.

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
ParseInput	proc	far
		.enter

		mov	bl, ds:[parseFlags]
		tst	bl
		jnz	inSequence	; Already parsing a sequence

		cmp	al, 20h		; Is it a control code?
		jb	checkEscape	; Look for an escape char

	;
	; Echo char to screen on remote side...
	;
exit:
		.leave
		ret

inSequence:
	;
	; Already parsing a sequence. Figure out what we want this
	; character for and, if the sequence is finished, Do The Right
	; Thing
	;
		test	bl, SCRGETFIRST
		jz	notFirst
		mov	{byte} ds:[parseSeq], al
	;
	; Switch to getting the second character and return
	;
		xor	bl, SCRGETFIRST OR SCRGETSECOND
		mov	ds:[parseFlags], bl
		jmp	exit
notFirst:
		test	bl, SCRGETSECOND
		jz	notSecond
		mov	{byte} ds:[parseSeq+1], al
	;
	; Figure out what to do. Sets parseFlags appropriately.
	;
		call	ParseSeq
		jmp	exit
notSecond:
	;
	; Should never get here. But if we do, clear out the flags
	;
		clr	ds:[parseFlags]
		jmp	exit		; Discard character

checkEscape:
		cmp	al, 0x1b		; is it an ESCAPE char?
		jne	checkReturn
	;
	; Note arrival of first character of escape sequence
	;
		or	ds:[parseFlags], SCRGETFIRST
		jmp	exit

checkReturn:
		cmp	al, 0xd			; is it a RETURN char?
		jne	exit
	;
	; Write cwd prompt to remote screen
	;
		call	ScrWriteNewLine
		call	FileWriteCurrentPath
		mov	al, '>'
		call	ScrWrite
		jmp	exit
		
ParseInput	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseSeq
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out what to do with the current escape sequence

CALLED BY:	ParseInput (INTERNAL)

PASS:		The two-character sequence in scrSeq
		ds, es - dgroup

RETURN:		Nothing.

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
	Use the two characters to search through a string of possible
	sequences.

	When the correct one is found, figure its offset from the start
	of the string and use that to index into a jump table.

	Call the routine to do its thing.

	If not a valid sequence, reset the flags and return.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	To make life easier for the termcap entries that do things multiple
	times, we load cx with 1 before calling the sequence handler. Since
	the first arg is placed in cx before the handler for a sequence-with-
	arguments is called, this allows these multiple things to simply install
	the regular sequence-without-arguments handler after setting the
	SCR1ARG flag.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
scrSequences	db	"XFLSCDMDRDRFMVCPEX"
;
; PCCom extension( 4/22/94, jang ) - new escape sequences
; : LL(long file listing), LM(medium long file listing),
;   AD( Available drives ), FS( Free space on a drive ), EB( echo-back on/off),
;   AK( acknowledgement on/off ) 
; Change delimiter extension (cassie, 2/24/95)
;   DD (display delimiter), DX (change delimiter)
;
                db      "LLLMADFSEBAKDDDX"
;
; PCCom Integrity extension
;   RB (RoBust mode)
;   RK (Robust acK)
;   FZ (FilesiZe)
;   RE (REmark)
;   DA (DAta)
;
		db	"RBRKFZREDA"

scrNumSeqs	= $-scrSequences

scrSeqJumps	dw	offset FileStartXfer
		dw	offset FileShortLs
		dw	offset FileCd
		dw	offset FileMkDir
		dw	offset FileRmDir
		dw	offset FileRmFile
		dw	offset FileRenameFile
		dw	offset FileCopyFile
		dw	offset ScrExit
;
; PCCom Extension( 4/22/94, jang )
;
                dw      offset FileLongLs
		dw	offset FileMedLs
                dw      offset FileAvailableDrives
                dw      offset FileDriveFreeSpace 
                dw      offset FileEchoBack
                dw      offset FileAcknowledgement
		dw	offset FileDisplayDelimiter
		dw	offset FileChangeDelimiter
;
; PCCom Integrity extension
;
		dw	offset FileRobust
		dw	offset RobustReset
		dw	offset FileSendSize
		dw	offset ScrRemark
		dw	offset ScrData

ParseSeq	proc	near
		.enter

		clr	ds:[parseFlags]		; Reset parse flags
		segmov	es, cs, ax
		mov	di, offset scrSequences	; es:di <- esc seq table
		mov	ax, ds:[parseSeq]	; Fetch sequence into ax
		mov	cx, scrNumSeqs
		repne scasw			; Look for sequence
		segmov	es, ds, bx		; restore es first
		jne	discard
	;
	; Find the correct handler function and place its address
	; in ax. Note that di points just beyond the one matched, so
	; we subtract 2 from scrSeqJumps to get the right function
	;
		mov	bx, di
		sub	bx, offset scrSequences
		mov	ax, cs:[scrSeqJumps - 2][bx]
		mov	cx, 1			; Make life easier by
						; setting cx to one.
		call	PassiveCommandStart
		call	ax
		call	PassiveCommandEnd

	;
	; Resume accepting input, now that the command has been
	; processed.
	;
		BitClr	ds:[sysFlags], SF_SUSPEND_INPUT
discard:
	;
	; Sequence was bogus, discard it
	;
		.leave
		ret
ParseSeq	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrWriteFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ScrWrite for routines outside this code segment

CALLED BY:	GLOBAL
PASS:		al = char
		es = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrWriteFar	proc	far
		call	ScrWrite
		ret
ScrWriteFar	endp
ForceRef	ScrWriteFar


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrWrite	(&&)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Echo a char to host
		If there is an active StringBlock, write char into that block
		instead of sending directly to the application.

CALLED BY:	ParseInput
PASS:		al - char
		es - dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrWrite		proc	near
		pushf
		call	PushAll
EC <		call	ECCheckES_dgroup			>
	;
	; If so desired, echo char back to remote device
	;
		tst	es:[echoBack]
		jz	noEcho
		push	ax
		mov	bx, '-'
		mov	cx, es:[remoteCodePage]
SBCS<		call	LocalGeosToCodePageChar			>
		call	ComWrite
		pop	ax
noEcho:
	;
	; Don't send newline to app - Text object cannot display it.
	;
		cmp	al, '\n'
		je	done

	;
	; notify callbackOD of character to be displayed
	;
		test 	es:[sysFlags], mask SF_NOTIFY_OUTPUT
		jz	done
		tst	es:[currentStringBlock].SB_handle
		jnz	writeToStringBlock
		mov	bp, ax
		mov	dx, GWNT_PCCOM_DISPLAY_CHAR
		mov	ax, MSG_META_NOTIFY
		call	SendNotification
done:
		call	PopAll
		popf
		ret
writeToStringBlock:
	;
	; write to string block instead of directly to screen
	;
		call	StringBlockWrite
		jmp	done

ScrWrite		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrWriteNewLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a new line (CR, LF)

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrWriteNewLine		proc	near
		uses ax
		.enter
		mov	al, '\n'
		call	ScrWrite
		mov	al, '\r'
		call	ScrWrite
		.leave
		ret
ScrWriteNewLine		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrWriteStandardString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write a standard string

CALLED BY:	UTILITY
PASS:		bx - offset of string in Strings resource
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrWriteStandardString		proc	near
		uses	ax,bx,si,ds
		.enter
		mov	si, bx
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]		; ds:si <- string
		call	ScrWriteString
		mov	bx, handle Strings
		call	MemUnlock

		.leave
		ret
ScrWriteStandardString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrWriteString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a string to screen

CALLED BY:	UTILITY
PASS:		ds:si - SBCS string
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrWriteString		proc	near

		pushf
		call	PushAll
		LoadDGroup	es, ax
		mov	di, si			; ds:di <- string
	;
	; Write the string over the serial port if echo is desired
	;
		tst	es:[echoBack]
		jz	noEcho
		mov	cx, es:[remoteCodePage]
		mov	bx, '-'
echoLoop:
		lodsb
SBCS<		call	LocalGeosToCodePageChar			>
		tst	al
		jz	noEcho
		call	ComWrite
		jmp	echoLoop
noEcho:
		mov	si, di			; ds:si <- string
	;
	; Check if caller wants to receive output
	;
		test 	es:[sysFlags], mask SF_NOTIFY_OUTPUT
		jz	done
	;
	; Check for an active string block
	;
		tst	es:[currentStringBlock].SB_handle
		jnz	writeToStringBlock
	;
	; Notify the app that a string is ready to be displayed
	;
		segmov	es, ds, ax		; es:di <- string
SBCS<		call	LocalStringSize	; cx <- # of bytes, including NULL	>
DBCS<		call	PCComSBCSStringLength					>
DBCS<		inc	cx							>
	;
	; Allocate a block big enough to hold the string.
	;
		push	cx
		mov	ax, cx
		mov	cx, ALLOC_DYNAMIC
		call	MemAlloc
		pop	cx
		jc	done
	;
	; Copy the string to the new block
	;
		call	MemLock
		mov	es, ax
		clr	di
		rep	movsb		
		call	MemUnlock

		mov	bp, bx
		mov	dx, GWNT_PCCOM_DISPLAY_STRING
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		call	SendNotification

done:
		call	PopAll
		popf
		ret

writeToStringBlock:
	;
	; Write to string block instead of writing directly to the screen
	;
		call	StringBlockWriteString
		jmp	done

ScrWriteString		endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrPrintByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a byte in HEX to the app

CALLED BY:	Debugging things

PASS:		AL	= byte to print

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/27/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
nibbles		db	"0123456789ABCDEF"

ScrPrintByte	proc	near
		uses	ax, bx
		.enter

		pushf
		push	ax
		mov	bx, offset nibbles
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		and	al, 0fh
		xlatb	cs:
		call	ScrWrite
		pop	ax

		and	al, 0fh
		xlatb	cs:
		call	ScrWrite
		mov	al, ' '
		popf
		.leave
		ret
ScrPrintByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a notification to app 

CALLED BY:	ScrWrite, ScrWriteString
PASS:		ax - MSG_META_NOTIFY message to be sent
		dx - NT_type
		bp - data to send with notification
RETURN:		nothing
DESTROYED:	bx,cx,si,di,bp,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendNotification		proc	near

	LoadDGroup	ds, bx
	movdw	bxsi, ds:[callbackOD]
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	ret
SendNotification		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remote machine has sent the "exit" command.
		Exit and notify caller if notification is desired.

CALLED BY:	ParseSeq
PASS:		ds, es - dgroup
RETURN:		nothing
DESTROYED:	ax,bx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrExit		proc	near
EC <		call	ECCheckDS_dgroup				>

		BitSet	ds:[sysFlags], SF_SCREXIT
		call	PCCOMEXIT


		ret
ScrExit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrRemark
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spew out a remark.  Useful for commenting installs, etc.

CALLED BY:	ParseSeq
PASS:		ds, es - dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	3/26/96    	Initial version
	Ron	1/6/96		Fixed bug that shows up on Responder

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrRemark	proc	near
	.enter
	;
	; get the comment to spew
	;
		clr	{byte}ds:[general_buf]
		mov	di, offset general_buf
		mov	cx, size general_buf
loopTop:
		call	ComReadWithWait
		jc	noComment
		stosb
		tst	al
		loopnz	loopTop
	;
	; Send it off!
	;
		push	si			; ???
		mov	si, offset general_buf
		xchg	al, es:[echoBack]	; clear echoBack
		call	ScrWriteString		; pass ds:si
		pop	si			; ???
		mov_tr	es:[echoBack],al	; restore echoBack
noComment:
		mov	di, PCET_NORMAL
		call	FileEndCommand
	.leave
	ret
ScrRemark	endp

if DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrDBCStoSBCS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change DBCS 0-256 value ascii to SBCS (strip extra zeros)

CALLED BY:	INTERNAL
PASS:		ds:si	= buffer to translate
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	translated

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg		1/31/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrDBCStoSBCS	proc	far
	uses	ax,si,di,es
	.enter
		segmov	es, ds, ax
		mov	di, si
loopTop:
EC <		Assert_fptr	dssi					>
		lodsw
		stosb
		tst	ax
		jnz	loopTop
	.leave
	ret
ScrDBCStoSBCS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrSBCStoDBCS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change SBCS into the lower byte of DBCS

CALLED BY:	INTERNAL
PASS:		es:di = buffer to translate (null terminated)
RETURN:		es:di = one byte past end of arg
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg		1/31/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrSBCStoDBCS	proc	near
	uses	ax,cx,si,ds
	.enter
		pushf				; store direction flag
		call	PCComSBCSStringLength
	;
	; setup source
	;
		segmov	ds, es, ax
		add	di, cx
		mov	si, di
	;
	; setup dest
	;
		add	di, cx
		push	di			; store end offset
		clr	ah
		inc	cx			; for the null
		std
loopTop:
		lodsb
		call	PCComUpcaseChar
		stosw
		loop	loopTop
		pop	di			; reset end offset
		add	di, 2			; first byte past end
		popf				; reset direction flag
	.leave
	ret
ScrSBCStoDBCS	endp

endif	; DBCS_PCGEOS

Main		ends



