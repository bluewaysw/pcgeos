COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        PCCom Library
FILE:		pccomUtils.asm

AUTHOR:		Cassie Hartzog, Nov 12, 1993

ROUTINES:
	Name			Description
	----			-----------
EXT	PCComFileEnumCallback	callback to match wildcards against DOS names
EXT	Sync			sync up by waiting for a ffh
EXT	CalcCRC			calculate 16-bit CRC
EXT	IncCRC			increment the CRC
EXT	FileCompareCheckSum	consume the checksum sent by host
EXT	ComRead			read a byte from serial port
EXT	ComReadWithWait		read a byte, waiting if nothin in port
EXT	ComWrite		write a byte to the serial port, block if busy
EXT	WaitForChar		poll the port until a specific char appears
EXT	PassiveCommandStart	Common code to run before executing command
EXT	PassiveCommandEnd	Common code to run after executing command

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	11/12/93	Initial revision


DESCRIPTION:
	Utility routines.	

	$Id: pccomUtils.asm,v 1.1 97/04/05 01:25:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Main	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether the DOS name of this file matches the
		passed pattern.

CALLED BY:	FileSend and FileLS, via FileEnumPtr
PASS:		ds = segment of FileEnumCallbackData
		bp = inherited stack frame
RETURN:		carry clear to accept file
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileEnumCallback	proc	far params:FileEnumParams
		uses	ax, bx, cx, si, di, ds, es
		.enter	inherit far

		clr	si		; ds:si <- array in which to search
		mov	ax, FEA_DOS_NAME
		call	FileEnumLocateAttr
EC <		ERROR_C	MISSING_FILE_ENUM_ATTR				>

NEC <		jc	done						>
		les	di, es:[di].FEAD_value
NOFXIP<		lds	si, ss:[params].FEP_cbData1			>
FXIP<		LoadDGroup	ds, bx					>
FXIP<		mov	si, offset filename				>
		mov	cx, ss:[params].FEP_cbData2.low			
		call	FEStringMatch
NEC <done:								>
		.leave
		ret
PCComFileEnumCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FEStringMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform UNIX-standard wildcard matching of a string against
		a pattern. In the pattern, the following characters have
		special meaning:
			*	= 0 or more of any character
			?	= any single character
			[..]	= a character range, where a single character
				  within the range matches.
			[^..]	= an inverse character range, where a single
				  character not within the range matches.
		The special meaning of these characters can be escaped by
		preceding them with a backslash.

CALLED BY:	FEWildcard
PASS:		ds:si	= pattern to match
		es:di	= string being matched
		cx	= non-zero if matching should be case-insensitive
RETURN:		carry clear if string matches the pattern.
DESTROYED:	si, di, ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Perhaps lock LocalUpcaseChar at the start? Requires another
		level, as locking it each recursion would be a waste of time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEStringMatch	proc	near
		.enter
compareChar:
	;
	; Get pattern character into AL and string character into BL. If
	; we're being insensitive to case, upcase both.
	; 
		clr	ax
		mov	bx, ax
		mov	al, ds:[si]
		mov	bl, es:[di]
		jcxz	haveChars
		call	LocalUpcaseChar
		xchg	ax, bx
		call	LocalUpcaseChar
		xchg	ax, bx
haveChars:
	;
	; If at end of the pattern, only match if at the end of the string.
	; 
		tst	al
		jnz	checkSubstring
		tst	bl
		jz	done
fail:
		stc
done:
		.leave
		ret

	;--------------------
checkSubstring:
	;
	; If pattern char is *, it matches any substring. We handle this quite
	; simply by recursing for each possible suffix of the string until
	; we either reach the end of the string without matching, or we
	; find one that matches. As a simple optimization, if * is the last
	; character in the pattern, we declare a match immediately.
	; 
		cmp	al, '*'
		jne	checkSingle

		inc	si		; advance pattern pointer so we're
					;  matching against the rest of the
					;  pattern.
		tst	{char}ds:[si]
		jz	done
starLoop:
		push	si, di
		call	FEStringMatch	; check current suffix
		pop	si, di
		jnc	done		; match => happiness

	    ;
	    ; advance to next (shorter) suffix and loop if we're not at the
	    ; end of the string.
	    ;
		inc	di
		tst	{byte}es:[di]
		jnz	starLoop
	    ;
	    ; hit end of string w/o finding a suffix that matched, so declare
	    ; a mistrial.
	    ;
		jmp	fail

	;--------------------
checkSingle:
	;
	; If pattern char is ?, it matches any character in the string except
	; the null-terminator.
	; 
		cmp	al, '?'
		jne	checkRange
		
		tst	bl
		LONG_EC	jnz	nextChar

		jmp	fail

	;--------------------
checkRange:
	;
	; If pattern char is '[', it introduces a range of possible matches.
	; 
		cmp	al, '['
		jne	checkBackslash
		
		push	dx
		clr	dx		; assume not inverse

		inc	si
		cmp	{char}ds:[si], '^'	; inverse range?
		jne	rangeLoop
		not	dx		; flag inverse
rangeLoop:
	    ;
	    ; Fetch next char of range, upcasing as necessary.
	    ; 
		lodsb
		jcxz	haveNextPatternChar
		call	LocalUpcaseChar
haveNextPatternChar:
	    ;
	    ; If pattern character is ] or the null-terminator, then the range
	    ; is complete (XXX: what about backslash to escape ]?)
	    ; 
		cmp	al, ']'
		je	rangeCheckDone
		tst	al		; XXX: unterminated range
		je	rangeCheckDone
		cmp	al, bl
		je	rangeMatch
		ja	ignoreSubRange	; if pattern char above string char,
					;  we need to ignore any following
					;  subrange (as introduced via a - as
					;  the next character), as string can't
					;  possibly be in the subrange.

	    ;
	    ; If subrange indicated (next pattern char is -), fetch the end
	    ; of the subrange, upcase it as necessary, and see if the string
	    ; char falls under or at the end char, indicating it's in the
	    ; subrange, since we already know the string char is above
	    ; the start of the subrange.
	    ; 
		cmp	{char}ds:[si], '-'
		jne	rangeLoop

		inc	si
		lodsb
		jcxz	haveSecondRangeChar
		call	LocalUpcaseChar
haveSecondRangeChar:
		tst	al
		jz	rangeCheckDone	; XXX: unterminated range
		cmp	al, bl
		jb	rangeLoop	; pattern below string, so string char
					; outside of range...
rangeMatch:
	    ;
	    ; String char matched the pattern char or fell within one of its
	    ; subranges. Invert our return value (DX) to indicate this, thus
	    ; giving us non-zero for a standard range and 0 for an inverse
	    ; range.
	    ; 
		not	dx
		mov	al, 1	; so we don't decide the character on which
				;  we stopped (which might be ]) is actually
				;  the end of the range...

rangeCheckDone:
	    ;
	    ; We've either gone through all the chars of the range, or have
	    ; decided the thing matched the range, so make sure ds:si points
	    ; past the range.
	    ;
		cmp	al, ']'
		je	testRangeResult
		tst	al
		jz	unterminatedRange
		lodsb
		jmp	rangeCheckDone

ignoreSubRange:
	    ;
	    ; String char fell below first char of possible subrange, so we've
	    ; only to skip the subrange if we see it.
	    ; 
		cmp	{char}ds:[si], '-'
		jne	rangeLoop
		inc	si
		lodsb
		tst	al
		jnz	rangeLoop

unterminatedRange:
		dec	si		; point back at null so we know we're
					;  done with the pattern

testRangeResult:
	    ;
	    ; DX contains the result of the comparison. 0 if string char isn't
	    ; in the range, and non-zero if it did. Because we initialize DX to
	    ; -1 if an inverse range was specified, and use "not dx" to flag
	    ; a match, we need only tst dx here to decide whether to accept
	    ; the string char as matching or not.
	    ; 
		tst	dx
		pop	dx
		jnz	nextStringChar	; si already advanced past range...
		jmp	fail

	;--------------------
checkBackslash:
	;
	; If pattern char is a backslash, it escapes special meaning for the
	; following character, unless following character is the null-
	; terminator, in which case the match fails.
	; 
		cmp	al, '\\'
		jne	checkNormal
		inc	si
		mov	al, ds:[si]
		tst	al
		LONG jz	fail
		jcxz	checkNormal
		call	LocalUpcaseChar
	;--------------------
checkNormal:
		cmp	al, bl
		LONG jne	fail
nextChar:
		inc	si
nextStringChar:
		inc	di
		jmp	compareChar
FEStringMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Sync
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sync up by waiting for a SYNC

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry clear if SYNC, NAK or NAK_QUIT received, else
		carry set 

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/31/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Sync	proc	near
		mov	al, SYNC
		call	WaitForChar	; al <- SYNC, NAK or NAK_QUIT
if _DEBUG
		jc	done
		push	ax
		mov	al, 's'
		call	DebugDisplayChar
		pop	ax	
		call	DebugDisplayByte				
done:
endif
		ret
Sync	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCRC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate 16-bit CRC

CALLED BY:	FileReadBlock, WriteDataBlock

PASS:		es:di		- packet of chars to calculate CRC for
		ax		- initial value (usually 0)
		cx		- number of chars in packet

RETURN:		ax		- CRC

DESTROYED:	none

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/22/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
crcTable	label	word
dw	0x0000,  0x1021,  0x2042,  0x3063,  0x4084,  0x50a5,  0x60c6,  0x70e7
dw	0x8108,  0x9129,  0xa14a,  0xb16b,  0xc18c,  0xd1ad,  0xe1ce,  0xf1ef
dw	0x1231,  0x0210,  0x3273,  0x2252,  0x52b5,  0x4294,  0x72f7,  0x62d6
dw	0x9339,  0x8318,  0xb37b,  0xa35a,  0xd3bd,  0xc39c,  0xf3ff,  0xe3de
dw	0x2462,  0x3443,  0x0420,  0x1401,  0x64e6,  0x74c7,  0x44a4,  0x5485
dw	0xa56a,  0xb54b,  0x8528,  0x9509,  0xe5ee,  0xf5cf,  0xc5ac,  0xd58d
dw	0x3653,  0x2672,  0x1611,  0x0630,  0x76d7,  0x66f6,  0x5695,  0x46b4
dw	0xb75b,  0xa77a,  0x9719,  0x8738,  0xf7df,  0xe7fe,  0xd79d,  0xc7bc
dw	0x48c4,  0x58e5,  0x6886,  0x78a7,  0x0840,  0x1861,  0x2802,  0x3823
dw	0xc9cc,  0xd9ed,  0xe98e,  0xf9af,  0x8948,  0x9969,  0xa90a,  0xb92b
dw	0x5af5,  0x4ad4,  0x7ab7,  0x6a96,  0x1a71,  0x0a50,  0x3a33,  0x2a12
dw	0xdbfd,  0xcbdc,  0xfbbf,  0xeb9e,  0x9b79,  0x8b58,  0xbb3b,  0xab1a
dw	0x6ca6,  0x7c87,  0x4ce4,  0x5cc5,  0x2c22,  0x3c03,  0x0c60,  0x1c41
dw	0xedae,  0xfd8f,  0xcdec,  0xddcd,  0xad2a,  0xbd0b,  0x8d68,  0x9d49
dw	0x7e97,  0x6eb6,  0x5ed5,  0x4ef4,  0x3e13,  0x2e32,  0x1e51,  0x0e70
dw	0xff9f,  0xefbe,  0xdfdd,  0xcffc,  0xbf1b,  0xaf3a,  0x9f59,  0x8f78
dw	0x9188,  0x81a9,  0xb1ca,  0xa1eb,  0xd10c,  0xc12d,  0xf14e,  0xe16f
dw	0x1080,  0x00a1,  0x30c2,  0x20e3,  0x5004,  0x4025,  0x7046,  0x6067
dw	0x83b9,  0x9398,  0xa3fb,  0xb3da,  0xc33d,  0xd31c,  0xe37f,  0xf35e
dw	0x02b1,  0x1290,  0x22f3,  0x32d2,  0x4235,  0x5214,  0x6277,  0x7256
dw	0xb5ea,  0xa5cb,  0x95a8,  0x8589,  0xf56e,  0xe54f,  0xd52c,  0xc50d
dw	0x34e2,  0x24c3,  0x14a0,  0x0481,  0x7466,  0x6447,  0x5424,  0x4405
dw	0xa7db,  0xb7fa,  0x8799,  0x97b8,  0xe75f,  0xf77e,  0xc71d,  0xd73c
dw	0x26d3,  0x36f2,  0x0691,  0x16b0,  0x6657,  0x7676,  0x4615,  0x5634
dw	0xd94c,  0xc96d,  0xf90e,  0xe92f,  0x99c8,  0x89e9,  0xb98a,  0xa9ab
dw	0x5844,  0x4865,  0x7806,  0x6827,  0x18c0,  0x08e1,  0x3882,  0x28a3
dw	0xcb7d,  0xdb5c,  0xeb3f,  0xfb1e,  0x8bf9,  0x9bd8,  0xabbb,  0xbb9a
dw	0x4a75,  0x5a54,  0x6a37,  0x7a16,  0x0af1,  0x1ad0,  0x2ab3,  0x3a92
dw	0xfd2e,  0xed0f,  0xdd6c,  0xcd4d,  0xbdaa,  0xad8b,  0x9de8,  0x8dc9
dw	0x7c26,  0x6c07,  0x5c64,  0x4c45,  0x3ca2,  0x2c83,  0x1ce0,  0x0cc1
dw	0xef1f,  0xff3e,  0xcf5d,  0xdf7c,  0xaf9b,  0xbfba,  0x8fd9,  0x9ff8
dw	0x6e17,  0x7e36,  0x4e55,  0x5e74,  0x2e93,  0x3eb2,  0x0ed1,  0x1ef0

CalcCRC	proc	near
	uses	bx,cx,di
	.enter
		jcxz	done				; empty block
doCRC:
		mov	bx, ax				;		
		xor	bh, es:[di]			; (chksm>>8)^c]
		inc	di				; advance char ptr
		mov	bl, bh				;point to table
		clr	bh
		shl	bx, 1				;compute offset into table
		mov	ah, al 				;
		clr	al				;chksm<<8
		xor	ax, cs:crcTable[bx]		;chksm<<8 ^ crctab[(chksm>>8)^c]
		loop	doCRC
done:
	.leave
	ret
CalcCRC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncCRC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	increment the CRC

CALLED BY:	GLOBAL

PASS:		ax = old crc
		bl = next character
		
RETURN:		ax = new crc

DESTROYED:	none

PSEUDOCODE/STRATEGY:	
	short
	IncCRC(short crc, char c)
	{ 
	    unsigned short   cs;
	    char   *ind;
	    short   val;

	    cs = crc;
	    cs ^= (short)(c << 8);
	    ind = (char *)crcTable;
	    cs = (cs >> 8);
	    cs = (cs << 1);
	    ind += cs;
	    val = *(short *)ind;
	    crc = (crc << 8);
	    crc ^= val;
	    return crc;
	}

	or

	    return ((crc << 8) ^ crcTable[((crc >> 8) ^ c) & 0xff]);

	for short.

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/12/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IncCRC	proc	near
	uses	bx
	.enter
		xor	ah, bl				; crc.high ^= char
		xchg	al, ah				; crc <<= 8
		mov	bx, ax				; bx <- crcTable index
		clr	bh
		mov	al, bh				; finish <<= 8...
		shl	bx				; table holds words...
		xor	ax, cs:[crcTable][bx]		; crc = (crc<<8) ^
							;  crcTable[(crc>>8)^c]
	.leave
	ret
IncCRC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCompareChecksum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the checksum that was sent by the host matches the
		one we've calculated in 'checksum'
		
		VESTIGIAL. RECEIVED CHECKSUM IS IGNORED.

CALLED BY:	FileReceive
PASS:		nothing
RETURN:		Carry set if time out, else Zero flag set.
DESTROYED:	dx, di, cx

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCompareChecksum	proc	near
	;
	; Just read the thing. the checksum is vestigial. -- ardeb 4/28/93
	; 
		mov	cx, 2
		sub	sp, cx
		mov	di, sp
		call	FileReadNBytes
		jc	done
		clr	dx			; set Z flag
done:
		pop	cx			; restore stack pointer
		ret
FileCompareChecksum	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a byte from the input buffer.

CALLED BY:	UTILITY
PASS:		nothing
RETURN:		carry set if nothing there, else
		AL contains byte
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		if (negotiationStatus == PNS_ROBUST) && timed-out
			pccomAbortType <- PCCAT_CONNECTION_LOST


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComRead		proc	near
		uses	bx, es
		.enter		

		LoadDGroup	es, ax
		tst	es:[serialHandle]
		stc
		jz	done

		cmp	es:[negotiationStatus], PNS_ROBUST
		je	isRobust

		call	UnprotectedComRead
done:								
		.leave
		ret

isRobust:
		call	RobustComRead
		jmp	done
ComRead		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComReadWithWait
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read until we actually find something

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if timed out
		else al - byte read

DESTROYED:	ah

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:
		if timed-out
			pccomAbortType <- PCCAT_CONNECTION_LOST

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/ 3/92		Initial version.
	cassie	2/07/95		revised timeout values

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComReadWithWait	proc	near
		uses	es
		.enter
		LoadDGroup	es, ax

		tst	es:[serialHandle]
		stc
		jz	done

		cmp	es:[negotiationStatus], PNS_ROBUST
		je	isRobust

		call	UnprotectedComReadWithWait
		jc	timeOut
done:
		.leave
		ret

isRobust:
		call	RobustComRead
		jmp	done
timeOut:
	;
	; non-robust timeout.  We seem to have lost the connection.
	; Renegotiate if we try to reconnect.
	;
		mov	es:[negotiationStatus], PNS_UNDECIDED
		mov	ah, PCCAT_CONNECTION_LOST 
		call	PCComPushAbortTypeES
		jmp	done

ComReadWithWait	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComWriteFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ComWrite

CALLED BY:	GLOBAL
PASS:		al	= byte to write to serial line
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComWriteFar	proc	far
		ForceRef	ComWriteFar
		call	ComWrite
		ret
ComWriteFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a byte to the serial port, blocking if port is busy.

CALLED BY:	UTILITY
PASS:		al - byte to write
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/12/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComWrite		proc	near
		uses	ax, bx, cx, ds
		.enter

		LoadDGroup	ds, cx		
		tst	ds:[serialHandle]
		jz	done

		cmp	ds:[negotiationStatus], PNS_ROBUST
		je	isRobust

		mov	cl, al			; cl <- byte to write
		mov	bx, ds:[serialPort]
		mov	ax, STREAM_BLOCK	; BLOCK until port is ready
		CallSer	DR_STREAM_WRITE_BYTE, ds
done:
		.leave
		ret
	;
	; OK, we are in robust comm mode - send it that way.
	;
isRobust:
		test	ds:[sysFlags], mask SF_COLLECT_OUTPUT
		jz	notCollecting
		call	RobustCollectChar
		jmp	done
notCollecting:
		call	RobustSendChar
		jmp	done

ComWrite		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComWriteBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a block of data from a buffer

CALLED BY:	FileSend

PASS:		DS:SI = buffer to write 
		CX = number of bytes to write
		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComWriteBlock		proc	near
		uses	ax, bx, ds
		.enter

		jcxz	done

EC <		call	ECCheckES_dgroup				>
	;
	; Check if we are in robust mode
	;
		cmp	es:[negotiationStatus], PNS_ROBUST
		je	isRobust

		mov	bx, es:[serialPort]
		mov	ax, STREAM_BLOCK	; BLOCK until port is ready
		CallSer	DR_STREAM_WRITE, es
done:
		.leave
		ret
isRobust:
		test	es:[sysFlags], mask SF_COLLECT_OUTPUT
		jz	justSend
		call	RobustCollectBlock
		jmp	done
justSend:
		call	RobustSendBlock
		jmp	done

ComWriteBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WaitForChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read until we find a specific char

CALLED BY:	GLOBAL


PASS:		al =  char to wait for

RETURN:		carry SET if timed out OR aborted (ie. err!=0)
			else
		carry clear and al = character received, NAK or NAK_QUIT

DESTROYED:	ah

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/ 3/92		Initial version.
	cassie	2/07/95		revised timeout values

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WaitForChar	proc	near
time	local	dword
goal	local	byte
		uses	ds, bx
		.enter

		LoadDGroup	ds, bx

		mov	ss:[goal], al
	;
	; Check for robust mode - it doesn't return unless we timeout!
	;
		cmp	ds:[negotiationStatus], PNS_ROBUST
		jne	normalMethod
robustRetry:
		call	ComRead
		jc	toDone
	;
	; Check if we've aborted, if so, then don't try waiting for
	; the target character.
	;
		tst	ds:[err]
		stc				; aborting 
		jnz	toDone
	;
	; Found target character?
	;
		cmp	al, ss:[goal]
		jne	robustRetry
toDone:
		jmp	done

normalMethod:
	;
	; set the current time 
	;
		call	TimerGetCount
		movdw	ss:[time], bxax

readLoop:
		call	ComRead
		jc	checkForTimeout

		cmp	al, ss:[goal]
		je	gotIt
		cmp	al, NAK
		je	gotIt
		cmp	al, NAK_QUIT
		je	gotIt

checkForTimeout:
	;
	; if more than 10 seconds has passed, time out.
	;
		call	TimerGetCount
		subdw	bxax, ss:[time]
		cmpdw	bxax, 600		; 600 ticks = 10 seconds
		jae	timeOut
		jmp	readLoop
gotIt:
		clc
done:
		.leave
EC <		Destroy ah						>
		ret
timeOut:
	;
	; non-robust timeout.  We seem to have lost the connection.
	; Renegotiate if we try to reconnect.
	;
		mov	ds:[negotiationStatus], PNS_UNDECIDED	
		mov	ah, PCCAT_CONNECTION_LOST
		call	PCComPushAbortType
		stc
		jmp	done

WaitForChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComDrainQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	loop until the write queue is empty

CALLED BY:	GLOBAL

PASS:		ds = dgroup

RETURN:		Void.

DESTROYED:	ax, bx

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/23/93	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComDrainQueue	proc	far

EC <		call	ECCheckDS_dgroup				>
		mov	bx, ds:[serialPort]
drainLoop:
		mov	ax, STREAM_WRITE
		CallSer	DR_STREAM_QUERY, ds
		jc	done
		cmp	ax, (BUFFER_SIZE - 1)
		jb	drainLoop
done:
		ret
ComDrainQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushAll, PopAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save, Restore all registers.

CALLED BY:	INTERNAL
PASS:		nothing		
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PushAll		proc	near
		push	es, ds, bp, di, si, dx, cx, bx, ax
		mov	bp, sp
		push	ss:[bp].PAF_ret		; push passed return
						; address for return
		mov	bp, ss:[bp].PAF_bp	; recover passed bp
		ret
PushAll		endp

PopAll	proc	near
		mov	bp, sp
		pop	ss:[bp+2].PAF_ret	; pop return address
						; into slot saved 
						;  for it...
		pop	es, ds, bp, di, si, dx, cx, bx, ax
		ret
PopAll	endp

;--------------------------------------------------------------------------
; 		Frame created by PushAll
;
; ss:sp points at the base of a PushAllFrame upon return from PushAll.
;--------------------------------------------------------------------------
	; WARNING: This structure must match the PushAll and PopAll routines.
	; At least one routine, depends on the order of fields in this
	; structure.

PushAllFrame	struct
    PAF_ax	word
    PAF_bx	word
    PAF_cx	word
    PAF_dx	word
    PAF_si	word
    PAF_di	word
    PAF_bp	word
    PAF_ds	word
    PAF_es	word
    PAF_ret	nptr		; near return address.
PushAllFrame	ends

;--------------------------------------------------------------------------
;		EC code
;--------------------------------------------------------------------------

if ERROR_CHECK

ECCheckDS_dgroup		proc	far
		pushf	
		push	ax, bx
		mov	ax, ds
		LoadDGroup	ds, bx
		mov	bx, ds
		cmp	ax, bx
		ERROR_NE	SEGMENT_REGISTER_NOT_DGROUP
		pop	ax, bx
		popf
		ret
ECCheckDS_dgroup		endp

ECCheckES_dgroup		proc	far
	ForceRef	ECCheckES_dgroup
		pushf
		push	ax, bx
		mov	ax, es
		LoadDGroup	es, bx
		mov	bx, es
		cmp	ax, bx
		ERROR_NE	SEGMENT_REGISTER_NOT_DGROUP
		pop	ax, bx
		popf
		ret
ECCheckES_dgroup		endp

endif

if	_DEBUG
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DebugDisplayWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a word to the app.

CALLED BY:	
PASS:		ax - word to print
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DebugDisplayWord		proc	far
	ForceRef	DebugDisplayWord
		pushf
		push	ax
		mov	al, ah
		call	DebugPrintByte
		pop	ax
		call	DebugPrintByte
		push	ax
		mov	al, ' '
		call	DebugDisplayChar
		pop	ax
		popf

		ret
DebugDisplayWord		endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DebugPrintByte
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
DebugPrintByte	proc	near
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
		call	DebugDisplayChar
		pop	ax

		and	al, 0fh
		xlatb	cs:
		call	DebugDisplayChar
;		mov	al, ' '
;		call	DebugDisplayChar
		popf
		.leave
		ret
DebugPrintByte	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DebugDisplayByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret a byte as char if in ascii range, 
		else print it as HEX.

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
DebugDisplayByte	proc	near
		uses	ax, bx
		ForceRef DebugDisplayByte
		.enter
		pushf
		cmp	al, SYNC
		je	doBytes
		cmp	al, 20h 
		jae	doChar
doBytes:
		push	ax
		mov	bx, offset nibbles
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		and	al, 0fh
		xlatb	cs:
		call	DebugDisplayChar
		pop	ax

		and	al, 0fh
		xlatb	cs:
		call	DebugDisplayChar
		mov	al, ' '
doChar:
		call	DebugDisplayChar
		popf
		.leave
		ret
DebugDisplayByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DebugDisplayChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send a char to app

CALLED BY:	UTILITY
PASS:		al - char to print
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DebugDisplayChar		proc	far
		pushf
		call 	PushAll
		mov	bp, ax
		mov	dx, GWNT_PCCOM_DISPLAY_CHAR
		mov	ax, MSG_META_NOTIFY
		call	SendNotification
		call 	PopAll
		popf
		ret
DebugDisplayChar		endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringBlockStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the string block.

CALLED BY:	GLOBAL
PASS:		es - dgroup
RETURN:		CF set if error
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringBlockStart	proc	far
		uses	ax, bx, cx
		.enter

EC <	call	ECCheckES_dgroup					>
	;
	; Check if there is a string block currently being used
	; if so, return error
	; otherwise, allocate a new one
	;
		tst	es:[currentStringBlock].SB_handle
		jnz	error
	;
	; Allocate a new block
	;
		mov	ax, STRING_BLOCK_DEFAULT_SIZE
		mov	cx, ALLOC_DYNAMIC
		call	MemAlloc
		jc	error
	;
	; Store block information
	;
		mov	es:[currentStringBlock].SB_handle, bx
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
		
StringBlockStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringBlockSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the current string block to applications object
		that receives output messages if we are supposed to.

CALLED BY:	GLOBAL
PASS:		es - dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringBlockSend	proc	far
		
		pushf
		call	PushAll

EC <	call	ECCheckES_dgroup					>
		mov	bx, es:[currentStringBlock].SB_handle
		call	MemLock			; ax <- segment address
		mov	ds, ax			; ds = seg addr of Str Blk
	;
	; make sure the string ends with a null character
	;
		mov	si, es:[currentStringBlock].SB_currentPos
		mov	{byte}ds:[si], 0

	;
	; Unlock string block, and send notification with the string block
	;
		call	MemUnlock
		mov	bp, bx
		mov	dx, GWNT_PCCOM_DISPLAY_STRING
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		call	SendNotification
	;
	; Lastly, reinitialize currentStringBlock
	;
		mov	es:[currentStringBlock].SB_handle, 0
		mov	es:[currentStringBlock].SB_size, 0
		mov	es:[currentStringBlock].SB_currentPos, 0
		call	PopAll
		popf
		ret
StringBlockSend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringBlockWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes a character into StringBlock

CALLED BY:	GLOBAL
PASS:		al = char to write
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
StringBlockWrite	proc	far
		uses	ax,bx,ds
		.enter
		
EC <		call	ECCheckES_dgroup				>
	;
	; Lock down the current string block
	;
		push	ax
		segmov	ds, es, ax			; ds = dgroup
		mov	bx, ds:[currentStringBlock].SB_handle
		mov	di, ds:[currentStringBlock].SB_currentPos
		call	MemLock				; ax = seg addr
		mov	es, ax				; es:di = next char pos
		pop	ax
EC <		Assert_fptr esdi					>
		stosb					; di++
		mov	ds:[currentStringBlock].SB_currentPos, di
		inc	ds:[currentStringBlock].SB_size
		call	MemUnlock
	;
	; Send the block if full
	;
		call	StringBlockWriteEndCommon
		
		.leave
		ret
StringBlockWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringBlockWriteString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes a string into string block

CALLED BY:	GLOBAL
PASS:		ds:si = fptr to SBCS string
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringBlockWriteString	proc	far
		uses	ax,bx,cx,si,di,ds,es
		.enter

EC <		call	ECCheckES_dgroup				>
	;
	; Get string size to add to StringBlock
	;
		segmov	es, ds, ax
		mov	di, si
SBCS<		call	LocalStringSize			; cx = new string size>
DBCS<		call	PCComSBCSStringLength					>
DBCS<		inc	cx							>
	;
	; Lock down the current string block
	;
		LoadDGroup	es, ax
		add	es:[currentStringBlock].SB_size, cx
EC <		cmp	es:[currentStringBlock].SB_size, STRING_BLOCK_DEFAULT_SIZE>
EC <		ERROR_AE STRING_BLOCK_OVERFLOW				>
		mov	bx, es:[currentStringBlock].SB_handle
		mov	di, es:[currentStringBlock].SB_currentPos
		call	MemLock				; ax = seg addr
		mov	es, ax				; es:di = next char pos
							; ds:si = new string
	;
	; Check if the resulting pointers would exceed boundaries
	;
EC <		push	si, di						>
EC <		add	di, cx						>
EC <		add	si, cx						>
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
EC <		pop	si, di						>
		rep	movsb				; copy string
		call	MemUnlock
	;
	; di = new next char position
	;
		LoadDGroup	ds, ax
		mov	ds:[currentStringBlock].SB_currentPos, di
	;
	; Send the block if full
	;
		call	StringBlockWriteEndCommon
		.leave
		ret
StringBlockWriteString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringBlockWriteEndCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	If currentStringBlock.size > STRING_BLOCK_MAX_SIZE, send the
		block and allocate a new block

CALLED BY:	StringBlockWrite, StringBlockWriteString
PASS:		ds = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Note that StringBlockWriteString does not check that
	currentStringBlock.size + string size < STRING_BLOCK_MAX_SIZE
	before writing the string. As STRING_BLOCK_DEFAULT_SIZE is larger
	than the max size, there is some room for overflow.  Right now
	there are 200 bytes for overflow. As long as no string is longer
	than that, this will work.  Since only FileLS uses a string block,
	and it always puts out a directory listing piece by piece, it
	should never overflow the block. The assertion will ensure that
	there is a fairly large overflow buffer.	--cassie 2/16/95

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringBlockWriteEndCommon	proc	near
	uses	es
	.enter
	.assert (STRING_BLOCK_DEFAULT_SIZE - STRING_BLOCK_MAX_SIZE) ge 100
		
EC <		call	ECCheckDS_dgroup				>
		segmov	es, ds
	;
	; If currentStringBlock.size > STRING_BLOCK_MAX_SIZE
	;	send the block to application, reinitialize currentStringBlock
	; Otherwise
	;	do nothing
	;
EC <		cmp	ds:[currentStringBlock].SB_size, STRING_BLOCK_DEFAULT_SIZE>
EC <		ERROR_AE STRING_BLOCK_OVERFLOW					>
		cmp	ds:[currentStringBlock].SB_size, STRING_BLOCK_MAX_SIZE
		jb	done

		call	StringBlockSend
		call	StringBlockStart
done:
	.leave
	ret
StringBlockWriteEndCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ActiveStartupChecks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called by the Routine stubs of the
active pccom library.  It does the checks to verify proper
initialization, etc.

CALLED BY:	Internal
PASS:		nothing
RETURN:		ds	= dgroup
		bx	= threadHandle
		al = PCComReturnType

		if (al == PCCRT_COMMAND_ABORTED)
			ah = PCComAbortType

		SF_SUSPEND_INPUT Set
		on error
			carry set
			SF_SUSPEND_INPUT not modified
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ActiveStartupChecks	proc	near
	uses	cx
	.enter
		LoadDGroup	ds, ax

		call	CheckCaller
		jnz	toNoThread

		cmp	ds:[serialPort], NO_PORT
		je	toNoThread

		mov	bx, ds:[threadHandle]
		tst	bx
		jnz	haveThread
toNoThread:
		jmp	noThread
weAreDead:
		mov	al, PCCRT_COMMAND_ABORTED
		mov	ah, PCCAT_CONNECTION_LOST
		stc
		jmp	done
haveThread:
	;
	; Check to see if the connection is dead
	;
		cmp	ds:[negotiationStatus], PNS_DEAD
		je	weAreDead
	;
	; OK, check to see if we are already doing something
	;
		test	ds:[sysFlags], mask SF_SUSPEND_INPUT
		jnz	weAreBusy	; is someone else eating the stream?

weAreFree:
		BitSet	ds:[sysFlags], SF_SUSPEND_INPUT
	;
	; Keep only certain flags and mask out the rest.
	;
		andnf	ds:[sysFlags], (mask SF_SUSPEND_INPUT or \
					mask SF_NOTIFY_EXIT or \
					mask SF_NOTIFY_OUTPUT)
		clr	ds:[err]

	;
	; Make the threshhold at which the Stream driver will notify
	; us of incoming characters really high, since we don't want
	; to be notified while doing the file transfer.
	;
		push	bx
		mov	cx, PCCOM_TRANSFER_THRESHOLD
		mov     ax, STREAM_READ
		mov     bx, ds:[serialPort]
		CallSer DR_STREAM_SET_THRESHOLD, ds
		pop	bx

		call	PCComNegotiate

		mov	al, PCCRT_NO_ERROR
		clc
done:
EC<		Assert_PCComReturnType	al				>
	.leave
	ret

weAreBusy:
	;
	; Wait 1.5 time-out period and then try again.
	;
		mov	ax, DEFAULT_TIMEOUT * 3 / 2
		call	TimerSleep
		test	ds:[sysFlags], mask SF_SUSPEND_INPUT
		LONG_EC jz	weAreFree

		mov	al, PCCRT_BUSY
		stc
		jmp	done
noThread:
		mov	al, PCCRT_NOT_INITIALIZED
		stc
		jmp	done
ActiveStartupChecks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ActiveShutdownDuties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do what needs doing by the Active PCCom stubs

CALLED BY:	active stubs
PASS:		nothing

RETURN:		ah	- PCComAbortType

DESTROYED:	nothing
SIDE EFFECTS:	
		resets the stream notification threshold

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	11/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ActiveShutdownDuties	proc	near
	uses	bx,cx,dx,ds
	.enter

		push	ax				; preserve al
		LoadDGroup	ds, ax

EC<		mov	bx, ds:[robustInputStart]			>
EC<		cmp	bx, ds:[robustInputEnd]				>
EC<		ERROR_NE	YOU_HAVE_NOT_EATEN_EVERYTHING_YET	>
		mov	cx, 1
		mov	ax, STREAM_READ
		mov	bx, ds:[serialPort]
		CallSer	DR_STREAM_SET_THRESHOLD, ds

		and	ds:[sysFlags], RESET_SYSFLAGS_MASK
		pop	ax				; restore al
		mov	ah, ds:[pccomAbortType]
	.leave
	ret
ActiveShutdownDuties	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PassiveCommandStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to execute before server command.

CALLED BY:	ParseSeq

PASS:		ds	- pccom dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		input-stream notification threshold set to
			PCCOM_TRANSFER_THRESHOLD
	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PassiveCommandStart	proc	near
	uses	ax,bx,cx
	.enter

EC <		call	ECCheckDS_dgroup				>

	;
	; Since we're going to poll for the rest of the data, there's
	; no need for anymore notification messages to be sent.  Set
	; notification threshold to an arbitrarily large value.
	;
		mov	cx, PCCOM_TRANSFER_THRESHOLD
		mov	ax, STREAM_READ
		mov	bx, ds:[serialPort]
		CallSer	DR_STREAM_SET_THRESHOLD, ds
	;
	; Upon leaving this routine, we could assume that the error
	; flags are cleared.
	;
		Assert e	ds:[err], 0
		Assert bitClear	ds:[sysFlags], SF_EXIT
	;
	; Assert no connections active.
	;
		Assert e	ds:[iacpConnection], IACP_NO_CONNECTION

	.leave
	ret
PassiveCommandStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PassiveCommandEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to execute after server command

CALLED BY:	ParseSeq

PASS:		ds	- pccom dgroup

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		input-stream notification threshold set to 1

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PassiveCommandEnd	proc	near
	uses	ax,bx,cx,dx,bp,si,di,es
	.enter

	;
	; Clear out any queued MSG_PCCOM_READ_DATA
	;
		mov	ax, segment FlushQueue	; set the compare routine
		push	ax
		mov	ax, offset FlushQueue
		push	ax

		mov	bx, ds:[threadHandle]	; set the optr (thread)
		clr	si

		mov	ax, MSG_META_DUMMY
		mov	di, mask MF_FORCE_QUEUE or mask MF_CUSTOM or \
				mask MF_CHECK_DUPLICATE
		call	ObjMessage
	;
	; Reset notification threshold to 1.
	;
		mov	cx, 1
		mov	ax, STREAM_READ
		mov	bx, ds:[serialPort]
		CallSer	DR_STREAM_SET_THRESHOLD, ds
	;
	; Reset error flags.
	;
		BitClr	ds:[sysFlags], SF_EXIT
		clr	ds:[err]
	;
	; Ok, close any IACP connection and release any file access
	; we've grabbed.
	;
		segmov	es, ds, ax		; dgroup
		call	PCComReleaseFileAccess

	.leave
	ret
PassiveCommandEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNullTermStringToBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy Null Terminated String To Buffer

CALLED BY:	int
PASS:		ds:si - source string
		es:di - destination buffer
		cx - length of destination buffer
RETURN:		carry set if string not nulled within confines of buffer
DESTROYED:	si advanced to null
		di advanced to end of buffer
		cx destroyed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We have a null terminated string that we want in a
buffer, but we don't know that the string is nulled out to the full
length of the receiving buffer so we can't just rep movsb or we put
potential garbage in the tail of the buffer.  We can't just stop when
we hit the null or we potentially leave garbage in the tail of the
buffer.  We must do a combination of the two

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNullTermStringToBuffer	proc	near
	.enter
DBCS<		shr	cx						>
copyLoop:
		jcxz	error
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
SBCS<		lodsb							>
SBCS<		stosb							>
DBCS<		lodsw							>
DBCS<		stosw							>
		dec	cx
		tst	al
		jnz	copyLoop

DBCS<		shl	cx						>
EC <		push	di						>
EC <		add	di, cx						>
EC <		Assert_fptr	esdi					>
EC <		pop	di						>
		rep stosb
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
CopyNullTermStringToBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSetDestination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We are getting files into a particular directory

CALLED BY:	PCComDoGet
PASS:		destname - destination pathname
		es - dgroup
RETURN:		on error, carry set and	al - PCComReturnType
		ds - dgroup (even if carry set)
DESTROYED:	nothing
SIDE EFFECTS:	You must remeber to Pop the old dir back

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSetDestination	proc	near
	uses	bx,cx,dx,si,di
	.enter
EC<		call	ECCheckES_dgroup				>
	;
	; Push current dir
	;
		push	ax
		segmov	ds, es, ax
		call	FILEPUSHDIR
		tst	es:[dataBlock]
		LONG_EC	jz	popDone
	;
	; copy given buffer into pathname
	;
		mov	di, offset pathname
		mov	si, offset destname
		mov	cx, size pathname
EC <		push	si, di						>
EC <		add	di, cx						>
EC <		add	si, cx						>
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
EC <		pop	si, di						>
		rep movsb
		clr	{byte}ds:[destname]
	;
	; break the pathname into path and name
	;
		call	FindTail
	;
	; put filename into destname
	;
		mov	si, offset filename
		mov	di, offset destname
		tst	{byte}ds:[si]
		jz	haveNoName
		or	ds:[sysFlags], mask SF_USE_DOS_NAME
		mov	cx, size filename
EC <		push	si, di						>
EC <		add	di, cx						>
EC <		add	si, cx						>
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
EC <		pop	si, di						>
		rep movsb
		mov	cx, (size pathname - size filename)
		clr	al
		rep stosb
	;
	; change to pathname
	;
haveNoName:
		clr	bx
		mov	dx, offset pathname
		call	FileSetCurrentPath
		jc	error
popDone:
		pop	ax			; no error, restr ax
done:
		.leave
		ret

error:
		mov	al, PCCRT_BAD_DEST_PATH
		stc
		pop	bx			; fixup stack
		jmp	done
GetSetDestination	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendSetDestination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the remote so that the files go in the right place.

CALLED BY:	(INTERNAL) PCCOMSEND
PASS:		ds - dgroup
		es:si - geos-char DOS destination file path
RETURN:		carry set on error
		al - PCComReturnType
		dgroup:[destname] - filled with destination filename in the
		                    remote DOS code page character set
DESTROYED:	es
SIDE EFFECTS:	If the destination file path contains a directory path,
		the server's current working directory is saved in
		dgroup:[oldpath] and its working directory is changed to
		the passed directory path.
		dgroup:[pathname] is trashed
		dgroup:[filename] is trashed

PSEUDO CODE/STRATEGY:
	Split the dest file path in to a directory path and filename.
	Convert the filename from the Geos character set to the remote 
	DOS code page and store it in dgroup:[destname].
	if the directory path in non-null
	    save the server's current working directory in dgroup:[oldpath]
	    change the server's working directory using the directory path

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/24/95    	Initial version
	lester	7/ 9/96  	fixed a bug and updated the header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendSetDestination	proc	near
	uses	bx,cx,dx,si,di,bp
	.enter
EC<		call	ECCheckDS_dgroup				>

	;
	; Split the dest file path into a directory path and filename.
	;
		segxchg	es, ds, ax		; es - dgroup, 
						; ds:si - dest file path
		mov	di, offset pathname	; es:di - pathname
		mov	cx, size pathname
		call	CopyNullTermStringToBuffer; pathname <- dest file path
		LONG_EC	jc	error

		segmov	ds, es, ax		; es - dgroup
		call	FindTail		; pathname <- directory path
						; filename <- dest filename
	;
	; Convert the filename from the Geos character set to the 
	; remote DOS code page.
	;
		mov	si, offset filename	; ds:si - filename
		clr	cx			; null terminated
		call	PCComGeosToDos
	;
	; Copy the converted filename into dgroup:[destname]
	;	
	;	ds:si - filename
	;	es - dgroup
		mov	di, offset destname	; es:di - destname
		mov	cx, size destname
EC <		push	si, di						>
EC <		add	di, cx						>
EC <		add	si, cx						>
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
EC <		pop	si, di						>
		rep movsb

	;
	; Check if we have a directory path
	;
		tst	{byte}ds:[pathname]
		jz	noPath
	;
	; Capture the server's current working path into oldpath
	;
		mov	cx, ds
		mov	dx, offset oldpath	; cx:dx - oldpath
		call	PCComDoPWD
		cmp	al, PCCRT_NO_ERROR
		jne	error
	;
	; now change into the pathname
	;
		mov	cx, ds
		mov	dx, offset pathname	; cx:dx - pathname
		call	PCComDoCD
		clr	{byte}ds:[pathname]	; else we mistake this
						; pathname for the filename
						; when sending out status
						; reports
		cmp	al, PCCRT_NO_ERROR
		jne	error
done:
	.leave
	ret
noPath:
		clr	al
		mov	ds:[oldpath], al
EC <		Assert	e al, PCCRT_NO_ERROR >	; return al = PCCRT_NO_ERROR
		jmp	done
error:
		call	ComDrainQueue
		clr	ds:[err]
		call	ActiveShutdownDuties
		mov	al, PCCRT_BAD_DEST_PATH
		stc
		jmp	done
SendSetDestination	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to send out a status report for the current
		operation.

CALLED BY:	lots of pccom Code
PASS:		ds - dgroup
		cl - PCComReturnType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We don't let them read directly from working variables as
those need to be immediately available to the active thread (can't
semaphore protect em) and we want them to be consistent..  so we take
a picture of the working vars now and let the user look at it whenever
they want to.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendStatus	proc	near
	uses	ax,bx,cx,dx,si,di,bp,es
	.enter
EC<		call	ECCheckDS_dgroup				>
	;
	; Get the semaphore
	;
		PSem	ds, statusSem, TRASH_AX_BX
	;
	; publish the data
	;
		mov	ds:[statusCond], cl
		cmp	cl, PCCRT_FILE_STARTING
		LONG_EC	jne	noName

		segmov	es, ds, ax

	;
	; ok, we don't know whether the filename is in the pathname (Get?) or
	; the filename (Send?), so we check the pathname and if it has no
	; string we go with the filename.
	;
		mov	si, offset pathname
		tst	{byte}es:[si]
		jnz	continue
		mov	si, offset filename
continue:
		mov	di, offset statusName
		mov	cx, length pathname -1
EC <		push	si, di						>
EC <		add	di, cx						>
EC <		add	si, cx						>
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
EC <		pop	si, di						>
		rep movsb
		clr	{byte}es:[di]		; forces it to be null terminated
						; in the worst case
		movdw	dxax, ds:[fSize]
		test	ds:[sysFlags], mask SF_GEOS_FILE
		jz	dontAddHeaderSize
		add	ax, size geosFileHeader
		adc	dx, 0
dontAddHeaderSize:
		movdw	ds:[statusFileSize], dxax
		movdw	ds:[statusThresholdSize], dxax

		mov	cx, ds:[numStatus]
	
		jcxz	noName

		clr	ds:[statusThresholdSize].high
		mov	ds:[statusThresholdSize].low, cx
		clr	ds:[statusGrainSize].high
		mov	ds:[statusGrainSize].low, cx

noName:
	;
	; Check if we are doing a GetFileSize op
	;
		test	ds:[sysFlags], mask SF_JUST_GET_SIZE
		LONG	jnz	justSize
	;
	; Check if we have a destination
	;
		tst	{word}ds:[statusDest]
		LONG_EC	jz	done

		movdw	dxax, ds:[statusFileSize]	;   original file size
		subdw	dxax, ds:[fSize]		; - size remaining
		movdw	ds:[statusXferSize], dxax	; = size xferred
	;
	; Decide if we should send an update
	;
		mov	cl, ds:[statusCond]
		mov	di, mask MF_FORCE_QUEUE
		cmp	cl, PCCRT_TRANSFER_CONTINUES
		LONG_EC	jne	doSend

		mov	di, mask MF_CAN_DISCARD_IF_DESPERATE or \
			    mask MF_FORCE_QUEUE

		movdw	dxbp, ds:[statusXferSize]
		cmpdw	dxbp, ds:[statusThresholdSize]
;		LONG_EC	jc	done
		LONG_EC	jb	done

	;
	; Setup next threshold by adding the grain size to the current
	; threshold
	;
		movdw	bxsi, ds:[statusThresholdSize]
		adddw	bxsi, ds:[statusGrainSize]
		movdw	ds:[statusThresholdSize], bxsi

doSend:
		movdw	bxsi, ds:[statusDest]
		cmp	cl, PCCRT_TRANSFER_COMPLETE
		LONG_EC	je	wrapUp
		cmp	cl, PCCRT_COMMAND_ABORTED
		LONG_EC	je	wrapUp
wrapUpDone:
	;
	; By default, pccomAbortType has a value of 0, PCCAT_DEFAULT_ABORT,
	; so just stuff it.
	;
		mov	ch, ds:[pccomAbortType]
		movdw	dxbp, ds:[statusXferSize]
		mov	ax, ds:[statusMSG]	
		call	ObjMessage
done:
	;
	; release semaphore
	;
		VSem	ds, statusSem, TRASH_AX_BX
	.leave
	ret

justSize:
	;
	; If the transfer isn't over, don't do anything
	;
		cmp	ds:[statusCond], PCCRT_TRANSFER_COMPLETE
		je	isFinished
		cmp	ds:[statusCond], PCCRT_COMMAND_ABORTED
		jne	done
isFinished:
	;
	; Grab the size
	;
		movdw	dxax, ds:[fSize]
		movdw	ds:[statusFileSize], dxax
	;
	; If the file existed, we aborted and err will be set
	;
		tst	ds:[err]
		jz	notFound
		mov	ds:[statusCond], PCCRT_NO_ERROR		
notFound:
		VSem	ds, pauseSem, TRASH_AX_BX
		jmp	done
wrapUp:
	;
	; OK, we finished a transfer, so we need to clean up.  If we
	; changed directories, we need to change back
	;
		tst	{byte}ds:[oldpath]
		jz	bitWork

		push	cx, bx, si, di		;
		push	ds:[sysFlags]		; preserve state
		mov	cl, ds:[err]		;
		push	cx			;

		mov	cx, ds
		mov	dx, offset oldpath
		BitClr	ds:[sysFlags], SF_EXIT	; have to go in w/o
		clr	ds:[err]		; errors
		call	PCComDoCD

		pop	cx			;
		mov	ds:[err], cl		;
		pop	ds:[sysFlags]		; restore state
		pop	cx, bx, si, di		;

		clr	{byte}ds:[oldpath]
bitWork:
		clr	{word}ds:[statusDest]
		clr	ds:[err]
		call	ActiveShutdownDuties
		jmp	wrapUpDone
SendStatus	endp

SendStatusES	proc	near
	uses	ds
	.enter

		segmov	ds, es
		call	SendStatus

	.leave
	ret
SendStatusES	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendEchoOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the EchoOn Command and eat the reply

CALLED BY:	internal
PASS:		ds - dgroup
RETURN:		carry set on timeout
DESTROYED:	al
SIDE EFFECTS:	
		if timed-out
			pccomAbortType = PCCAT_CONNECTION_LOST

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendEchoOn	proc	near
	.enter

EC <		call	ECCheckDS_dgroup				>
	;
	; First, make sure our echoback is OFF (else both sides will
	; echo stuff back and forth forever - Agh!)
	;
		clr	ds:[echoBack]
	;
	; Now, send the command
	;
		call	RobustCollectOn		; set for burst mode
		mov	ax, ECHOBACK_COMMAND
		call	PCComSendCommand
		mov	al, 'o'
		call	ComWrite
		mov	al, 'n'
		call	ComWrite
		mov	al, ds:[delimiter]
		call	ComWrite
		call	RobustCollectOff
		jc	timedOut
	; we'll get back
	; geos:"\0a\0dEchoback = on\0aC:blah>;"
	; dos: "Echoback = on;\d\a"

		mov	al, ';'
		call	WaitForChar
		jc	timedOut

done:
	.leave
	ret

timedOut:
		mov	ah, PCCAT_CONNECTION_LOST
		call	PCComPushAbortType	; CF - preserved
		jmp	done

SendEchoOn	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendEchoOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the echooff command

CALLED BY:	internal
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	al
SIDE EFFECTS/PSEUDO CODE/STRATEGY:
		if (negotiationStats= PNS_ROBUST) && timed-out
			pccomAbortType = PCCAT_CONNECTION_LOST


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendEchoOff	proc	near
	.enter
EC <		call	ECCheckDS_dgroup				>

	;
	; If aborted AND in RobustMode, then no need to send cuz the
	; other side will reset to ECHO_OFF automatically during
	; re-negotiation.
	;
		tst	ds:[err]
		jz	noAbort
		cmp	ds:[negotiationStatus], PNS_ROBUST
		je	done

noAbort:
		call	RobustCollectOn
		mov	ax, ECHOBACK_COMMAND
		call	PCComSendCommand
		mov	al, 'o'
		call	ComWrite
		mov	al, 'f'
		call	ComWrite
		mov	al, 'f'
		call	ComWrite
		mov	al, ds:[delimiter]
		call	ComWrite
		call	RobustCollectOff
done:
	.leave
	ret
SendEchoOff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendAckOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn remote acknowledgment on

CALLED BY:	int
PASS:		ds - dgroup
		carry set if we should expect echo
RETURN:		carry set on error (ack off)
DESTROYED:	ax, bx
SIDE EFFECTS:	
		if timed-out
			pccomAbortType = PCCAT_CONNECTION_LOST

		may dirty input buffer

PSEUDO CODE/STRATEGY:
	input buffer may be dirty!  Assume no \27 in input buffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendAckOn	proc	near
	.enter
EC <		call	ECCheckDS_dgroup				>

		pushf				; preserve CF
		call	RobustCollectOn
		mov	ax, ACKNOWLEDGMENT_COMMAND
		call	PCComSendCommand
		mov	al, 'o'
		call	ComWrite
		mov	al, 'n'
		call	ComWrite
		mov	al, ds:[delimiter]
		call	ComWrite
		call	RobustCollectOff
		jc	error
	;
	; we will either get Ack or "\r\nAcknowledge = on\r\nC:blah>;"Ack
	;
		call	WaitForAck
		jc	error
		popf	
		clc

done:
	.leave
	ret
	;
	; we had a problem - did not get acknowledgement back
	;
error:
		popf				; restore CF
		call	SendAckOff
		stc
		jmp	done
SendAckOn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendAckOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn the remote's Ack off

CALLED BY:	int
PASS:		ds - dgroup
		carry set if we should expect echo

RETURN:		CF - SET on error
DESTROYED:	nothing
SIDE EFFECTS:	
		may leave input stream dirty..  sorry!
		if timed-out
			pccomAbortType = PCCAT_CONNECTION_LOST

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendAckOff	proc	near
	uses	ax
	.enter
EC <		call	ECCheckDS_dgroup				>

	;
	; If aborted AND in RobustMode, then no need to send cuz the
	; other side will reset to ACK_OFF automatically during
	; re-negotiation.
	;
		lahf				; CF passed in
		tst	ds:[err]
		jz	noAbort
		cmp	ds:[negotiationStatus], PNS_ROBUST
		stc				; error behavior
		je	done

noAbort:
		sahf				; CF passed-in
		pushf
		call	RobustCollectOn
		mov	ax, ACKNOWLEDGMENT_COMMAND
		call	PCComSendCommand
		mov	al, 'o'
		call	ComWrite
		mov	al, 'f'
		call	ComWrite
		mov	al, 'f'
		call	ComWrite
		mov	al, ds:[delimiter]
		call	ComWrite
		call	RobustCollectOff
		popf
		jnc	done
	;
	; eat the echo
	;
		mov	al, ';'
		call	WaitForChar
		jc	timedOut
done:
	.leave
	ret

timedOut:
		mov	ah, PCCAT_CONNECTION_LOST
		call	PCComPushAbortType
		jmp	done
SendAckOff	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WaitForAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We are expecting and Ack - eat it and return carry indication.

CALLED BY:	int
PASS:		ds - dgroup
		carry set if already have ESC
RETURN:		carry clear if found Ack else carry set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WaitForAck	proc	near
	uses	ax, bx
	.enter
EC <		call	ECCheckDS_dgroup				>
		jc	haveESC

		mov	al, 1bh
		call	WaitForChar
		jc	done
haveESC:
		clr	bx			; count the number of
						; correct chars
		call	ComReadWithWait
		jc	done
		cmp	al, 'A'
		jne	checkNAK
		inc	bx
char2:
		call	ComReadWithWait
		jc	done
		cmp	al, 'C'
		jne	char3
		inc	bx
char3:
		call	ComReadWithWait
		jc	done
		cmp	al, 'K'
		jne	doneErr
		sub	bx, 2			; if the even one of
						; the first two chars
						; was bad, bx will be
						; less than 2 and this
						; will set the carry..
done:
		.leave
		ret
doneErr:
		stc
		jmp	done

checkNAK:
	; 
	; We didn't receive an ack, but if it's a NAK, then we should
	; retrieve the error code.  We'll only do this if we're in
	; Robust mode -- backwards compatibility issue.  Note: SET CF
	; for NAK.
	;
EC <		call	ECCheckDS_dgroup				>
		cmp	ds:[negotiationStatus], PNS_ROBUST
		jne	char2

		cmp	al, 'N'
		jne	char2
		inc	bx			; success count

char2NAK::
	;
	; Get the second character.
	;
		call	ComReadWithWait
		jc	done
		cmp	al, 'A'
		jne	char3NAK
		inc	bx			; success count
char3NAK:
		call	ComReadWithWait
		jc	done
		cmp	al, 'K'
		jne	doneErr

		cmp	bx, 2			; CF set if less than 2
		jb	done
		
getErrorCode::
		call	ComReadWithWait		; al <= error code
EC <		WARNING_C	PROTOCOL_EXPECTING_ABORT_TYPE		>
		jc	done			; jmp if no error code
		mov_tr	ah, al
		ornf	ah, PCCAT_REMOTE_ABORT	; not local abort
		call	PCComPushAbortType
		jmp	doneErr		

WaitForAck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetXmitCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send Get Command and wildname and prep the name buffer
		for incoming filenames.

CALLED BY:	PCComPCGet (CLIENT)
PASS:		ds, es - dgroup
RETURN:		ds, es - dgroup
		bx - dataBlock handle
		carry set on error
DESTROYED:	ax, cx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetXmitCommand	proc	near
	.enter
EC <		call	ECCheckDS_dgroup				>
EC <		call	ECCheckES_dgroup				>

	;
	; send the fetch command
	;
		call	RobustCollectOn
		mov	ax, FILE_TRANSFER_COMMAND
		call	PCComSendCommand
		mov	al, FETCH_RAW_COMMAND
		call	ComWrite
	;
	; send wildname - could be in dataBlock, or could be in
	; pathname, check dataBlock first
	;
		mov	cx, es:[dataBlock]
		tst	cx
		jnz	haveBlock
	;
	; wildname is in dgroup:pathname, find null
	;
		mov	si, offset pathname
		mov	di, si
		mov	cx, size pathname
		clr	al
		repnz	scasb
		LONG_EC	jne	done
	;
	; send the string (using length found above
	;
		sub	di, si
		mov	cx, di
		call	ComWriteBlock
		clc
		jmp	done
	;
	; wildname was in dataBlock - display it
	;
haveBlock:
		mov	bx, offset requesting
		call	ScrWriteStandardString

		mov	bx, cx			; bx - dataBlock

		call	MemLock
		mov	ds, ax
		clr	si, di			; ds:si - wildname
		call	ScrWriteString
	;
	; Send wildname, scan for length first
	;
		segxchg	ds, es			; es:di - wildname
		mov	cx, size pathname
		clr	ax
		repnz scasb
		pushf				; record wether we
						; found a null or not
		jne	dontSend
	;
	; translate wildname
	;
		segxchg	ds, es
		clr	si, cx
		call	PCComGeosToDos
	;
	; Send it
	;
		mov	cx, di
		clr	si
		call	ComWriteBlock

dontSend:
		call	MemUnlock
		segmov	ds, es, ax
		popf				; now, did we find a
						; null and send, or
						; did we abort?
		jne	done

	;
	; since we sent a valid wildname from the datablock we know
	; that we need to prep the datablock to receive the
	; transmitted filenames - make it a good starting size:
	;
		mov	ax, (FILE_LIST_RECORD_SIZE + 1) * 2
		clr	cx
		mov	es:[currentSize], ax
		mov	es:[currentOffset], cx
		mov	bx, es:[dataBlock]
		call	MemReAlloc
done:
		pushf
		call	RobustCollectOff
		popf
	.leave
	ret
GetXmitCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadIntoPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want to read the bytes from the com port into our
		pathname string, stopping at the end of the buffer or
		at a null char.

CALLED BY:	FileStartXfer
PASS:		ds,es - dgroup
RETURN:		carry flag on time out
		SF_BAD_FILENAME set if needed
DESTROYED:	di, ax, bx
SIDE EFFECTS:	
		pathname <- string

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadIntoPathname	proc	near
	.enter
EC <		call	ECCheckDS_dgroup				>
EC <		call	ECCheckES_dgroup				>

		mov	di, offset pathname
		mov	bx, di
SBCS<		add	bx, size pathname -1				>
DBCS<		add	bx, ((size pathname)/2) -1			>
nameLoop:
		call	ComReadWithWait
		jc	done
EC <		Assert_fptr	esdi					>
		stosb
		tst	al
		jz	haveFilename
		cmp	di, bx
		jb	nameLoop
	;
	; The filename is too long - means that null-terminator
	; was never received.  Just set the flag and continue, in hopes
	; that the sender is using the new protocol, and will send
	; the filename in the first block.  If the sender is using the
	; old protocol, we will have to abort after the first block is 
	; found not to contain the filename.
	;
setAbort:
		or	es:[sysFlags], mask SF_BAD_FILENAME
done:
	.leave
	ret
haveFilename:
DBCS<		mov	di, offset pathname				>
DBCS<		call	ScrSBCStoDBCS					>
	;
	; Check for serial port overrun errors.  If overrun did occur,
	; the filename is probably garbled.
	;
		cmp	es:[negotiationStatus], PNS_ROBUST
		je	done
		mov     ax, STREAM_READ
		mov     bx, ds:[serialPort]
		CallSer DR_STREAM_GET_ERROR, ds
		test	ax, mask SE_OVERRUN	; clears carry
		jz	done
if _DEBUG
		call	DebugDisplayWord
		mov	al, 'E'
		call	DebugDisplayChar
endif
		clc
		jmp	setAbort


ReadIntoPathname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrepBufferForNextName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make room in the dataBlock for the next filename

CALLED BY:	Internal
PASS:		ds, es - dgroup
RETURN:		carry set on error - cl set
DESTROYED:	bx, ax, cx
SIDE EFFECTS:	dataBlock may be resized

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrepBufferForNextName	proc	near
	.enter
EC <		call	ECCheckDS_dgroup				>
EC <		call	ECCheckES_dgroup				>

	;
	; verify the existence of a dataBlock
	;
		mov	bx, es:[dataBlock]
		tst	bx
		jz	done

	;
	; check if there is another record worth of room left
	;
		mov	ax, es:[currentOffset]
		add	ax, FILE_LIST_RECORD_SIZE + 1
		ERROR_C	TOO_MANY_FILES_IN_FILE_ENUM

		cmp	es:[currentSize], ax
		jnbe	done

	;
	; add another record worth of room (so that we're make space
	; for two full records)
	;
		add	ax, FILE_LIST_RECORD_SIZE + 1
		ERROR_C TOO_MANY_FILES_IN_FILE_ENUM
		mov	es:[currentSize], ax
		clr	cx
		call	MemReAlloc
done:
	.leave
	ret
PrepBufferForNextName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPathnameToDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	we need to copy a filename in ds:pathname to the datablock

CALLED BY:	FileReceive
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		translate the pathname to geos
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyPathnameToDataBlock	proc	near
	uses	ax, bx, di, si, es, cx
	.enter
EC <		call	ECCheckDS_dgroup				>

		mov	bx, ds:[dataBlock]
		tst	bx
		jz	done

		mov	si, offset pathname
		mov	cx, size pathname
SBCS<		call	PCComDosToGeos					>
	;
	; setup es:di - next char spot in datablock
	;	ds:si - dgroup:pathname
	;	cx -	amount to copy 
	;
		call	MemLock
		mov	es, ax
		mov	di, ds:[currentOffset]
		mov	cx, FILE_LIST_RECORD_SIZE
	;
	; copy it
	;
nameCopyLoop:
SBCS<		lodsb							>
DBCS<		lodsw							>
		tst	al
		jz	padIt
EC <		Assert_fptr	esdi					>
SBCS<		stosb							>
SBCS<		dec	cx						>
SBCS<		jnz	nameCopyLoop					>
DBCS<		stosw							>
DBCS<		sub	cx, 2						>
DBCS<		ja	nameCopyLoop					>
	;
	; now, fill the rest (after we hit null) with spaces
	;
padIt:
		mov	al, ' '
EC <		push	di						>
EC <		add	di, cx						>
EC <		Assert_fptr	esdi					>
EC <		pop	di						>
		rep stosb
		mov	ds:[currentOffset], di
		clr	{byte}es:[di]
		call	MemUnlock
done:
	.leave
	ret
CopyPathnameToDataBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add space to our buffer

CALLED BY:	PCCOMLISTDRIVES
PASS:		bx	= handle (locked)
		si	= new size for buffer
RETURN:		cx	= number of chars we can add
		si	= buffer size for next trip through
		es	= new segment
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeSpace	proc	near
	.enter
		mov	ax, si
		clr	ch
		call	MemReAlloc
		jc	done
		mov	es, ax
		mov	cx, BUFFER_SIZE
		add	si, cx
done:
	.leave
	ret
MakeSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Make83DosName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make it 8.3

CALLED BY:	PCComDoMkdir (CLIENT)
PASS:		es:di 	= buffer of Dos-Char dir name, null terminated
		cx	= length of string
RETURN:		buffer changed - truncate
		cx	= new length
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Make83DosName	proc	near
		uses	ax,si,di,ds,es
		.enter
	;
	; Setup - use ds:si to scan forward, es:di to write name
	; cx counts chars
	;
		push	cx
		segmov	ds, es
		mov	si, di
		mov	cx, DOS_FILE_NAME_CORE_LENGTH
	;
	; now, move through the body of the name transcribing as we go,
	; up to eight chars until we reach a null (done) or we find a '.'
	;
nameTop:
		lodsb
		tst	al
		jz	done

		cmp	al, '.'
		je	extension
		stosb
		loop	nameTop
	;
	; we fell out of the loop..  we're still in the body of the
	; name, but we don't want anymore of these chars.  move
	; through them looking for null or '.'
	;
waitForPeriod:
		lodsb
		cmp	al, '.'
		je	extension
		tst	al
		jnz	waitForPeriod
		jmp	done
	;
	; we found a period, so now we can get three chars of
	; extension.  write the period and then get the next three
	;
extension:
		stosb
		mov	cx, DOS_FILE_NAME_EXT_LENGTH
extTop:
		lodsb
		tst	al
		je	done
		stosb
		loop	extTop

		clr	al
		mov	cl, 0xff
		xchg	si, di
		repne	scasb
		xchg	si, di
done:
		stosb
		pop	cx
		sub	si, di
		sub	cx, si
		.leave
		ret
Make83DosName	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckInputStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	7/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckInputStream	proc	near
	uses	ax
	.enter
loopTop:
	call	ComReadWithWait
	jc	done
	jmp	loopTop
done:
	.leave
	ret
CheckInputStream	endp
endif	;0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ListDrivesCommandSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up some initial stuff and send the command

CALLED BY:	PCComDoListDrives	(CLIENT)
PASS:		ds - dgroup
		bx - handle of return buffer
RETURN:		dx - 0x0e20
		bp - 0x2020
		si - initial buffer size
		es:di - initial buffer pointer (0)
		bx - handle of return buffer (locked)
		carry set on error
		if error
			al - PCCRT_COMMAND_ABORTED
		else
			ax - first non-control char

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ListDrivesCommandSend	proc	near
	.enter
EC<		call	ECCheckDS_dgroup				>
	;
	; checkout the passed in handle and lock it
	;
		call	MemLock
	;
	; ok, now we can turn on echo - if trouble bail with carry on
	;
		call	SendEchoOn
		jc	error
	;
	; setup some initial values
	;   di goes to beginning of buffer, and si is set to the
	;   initial buffer size
	;
		mov	dx, (0xe shl 8) or ' '
		mov	bp, (' ' shl 8) or ' '
		mov	si, BUFFER_SIZE
		clr	di
	;
	; now send the command
	;
		mov	ax, AVAILABLE_DRIVE_COMMAND
		call	PCComSendCommand
	;
	; and read the junky startup \a and \d chars (or anything
	; below \e :) )
	;
junkyChar:
		call	ComReadWithWait
		jc	error
		cmp	al, dh
		jc	junkyChar
done:
	.leave
	ret
error:
		mov	al, PCCRT_COMMAND_ABORTED
		jmp	done
ListDrivesCommandSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ListDrivesStartReading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start reading

CALLED BY:	PCComDoListDrives	(CLIENT)
PASS:		al - first char
		cx - space left in the return buffer
		ds - dgroup
		bx - handle of return buffer
		dx - 0x0e20
		bp - 0x2020
		si - buffer size
		es:di - buffer pointer

RETURN:		CF - SET on error
		if error
			ax - appropriate PCCRT, 
		else
			al - next character, 
			ah - last placed char
			cx - space left in the return buffer
			es - new segment
			si - buffer size for next trip through
		es:di - new buffer ptr

DESTROYED:	nothing
SIDE EFFECTS:	
		size of buffer (es:di) may have increased

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ListDrivesStartReading	proc	near
	.enter

EC <		call	ECCheckDS_dgroup				>
		Assert	handle	bx
		Assert	e dx, 0x0e20
		Assert	e bp, 0x2020

	;
	; now store the previously fetched first char and ensure
	; enough space for the next char
	;
		stosb
		loop	getColon
		call	MakeSpace
		jc	memError
	;
	; Fetch the colon.  This is the only error checking - if we
	; don't get a colon when we expect it we die!
	;
getColon:
		call	ComReadWithWait
		jc	error
		stosb
		cmp	al, ':'
		jne	error
		loop	getVolName
		call	MakeSpace
		jc	memError
	;
	; read in the volume name
	;
	;   Hah!  We don't really char what the first char is.  We
	;   write a '['.  It could be a space or a bracket.
	;
getVolName:
		call	ComReadWithWait
		jc	error
		mov	al, '['
		stosb
		loop	nameLoop
	;
	;   Make space for the name
	;
nameSpace:
		call	MakeSpace
		jc	memError
nameLoop:
	;
	;   Now we get the rest of the name, replacing enclosed spaces
	;   with underscores, ignoring spaces after ']', and only
	;   allowing one space in a row.
	;
		call	ComReadWithWait
		jc	error
		mov	ah, es:[di].-1
		cmp	al, dh			; 0xe - if it's below
		jc	nameDone		; this we assume it's
						; a \d or \a which we
						; treat equivalently

		cmp	ah, ']'			; if we've already
		je	nameLoop		; received a ']'
						; ignore all else

		cmp	ah, dl			; 0x20 - prev char was
		jne	stuffName		; not a space so stuff this

		cmp	ax, bp			; 0x2020 - if we've
		je	nameLoop		; got two spaces in a
						; row (the prev char
						; was a space) then
						; ignore this space

		mov	{byte}es:[di].-1, '_'	; else our prev space
						; is being followed by
						; another valid name
						; char, so it's inside
						; a vol name and needs
						; to be translated to '_'
stuffName:
	;
	;   We've decided what char to place..  so stuff it
	;
		stosb
		loop	nameLoop
		jmp	nameSpace
nameDone:
	;
	;   We're done with the name - but the carry is on - clear it
	;
		clc
done:
	.leave
	ret
memError:
		mov	al, PCCRT_MEMORY_ALLOC_ERROR
		jmp	done
error:
		mov	al, PCCRT_COMMAND_ABORTED
		jmp	done
ListDrivesStartReading	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ListDrivesPostNameProcessing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've finished reading the drive name..  analyse the ending

CALLED BY:	PCComDoListDrives	(CLIENT)
PASS:		ah - last placed char
		al - last read char (control char)
		cx - space left in the return buffer
		ds - dgroup
		bx - handle of return buffer
		dx - 0x0e20
		bp - 0x2020
		si - return buffer size
		es:di - buffer pointer

RETURN:		CF - SET if done
		if CF SET,
			ax - proper PCCRT
			cx - destroyed
			buffer is null-terminated
		else
			al - next character
			cx - space left in the return buffer
		es:di - updated buffer ptr

DESTROYED:	nothing
SIDE EFFECTS:	
		size of buffer (es:di) may have increased

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ListDrivesPostNameProcessing	proc	near
	.enter

EC <		call	ECCheckDS_dgroup				>
		Assert	handle	bx
		Assert	e dx, 0x0e20
		Assert	e bp, 0x2020

	;
	; have read in a postname \a and \d
	;
	;   first check how the volume name ended.  If it ended with a
	;   bracket then it's clean.  If it ended with a space we need
	;   to change that into a bracket.  If it ended with something
	;   else we need to add space (since we'll be adding a ']').
	;
		cmp	ah, ']'		; if we got a ']' we're good.
		je	nameEnded

		cmp	ah, dl		; if we can overwrite a space,
		je	noNeedToAdd	; do that, else we add space
	;
	; the vol name ran right up to the linefeed without a space
	; for a ']'
	;
		mov	al, ']'
		stosb
		loop	nameEnded
		call	MakeSpace
		jc	memError
		jmp	nameEnded
noNeedToAdd:
		mov	{byte}es:[di].-1, ']'
nameEnded:
	;
	;   OK.  The name is cleanly terminated with a ']'.  We have
	;   space for at least one more character.  We've already read
	;   in one control char (\a or \d).  Read the other and then
	;   read one more char to see if we are really done or the
	;   list continues.  If the list continued we would get some
	;   normal text char.
	;
		call	ComReadWithWait
		jc	error
		call	ComReadWithWait
		jc	error
		cmp	al, ';'
		je	dosDone

		cmp	al, dh
		jc	geosDone
		xchg	ah, al		; preserve next drive letter

		mov	al, dl
		stosb			; record space seperator
		xchg	ah, al
		clc
done:
	.leave
	ret
geosDone:
	;
	; We are doing a geos-like finish - expect \d\a\d\aF:\DOS>;
	;
		mov	al, ';'
		call	WaitForChar
		jmp	weAreDone
dosDone:
	;
	; We're doing a dos-like finish expect \a\d;\a\d
	;
		call	ComReadWithWait
		jc	error
		call	ComReadWithWait
		jc	error
weAreDone:
	;
	; We're outahere.  Null terminate this thing, kid, and lets go
	; home. 
	;
		clr	al
		stosb
		mov	ax, di
		clr	ch
		call	MemReAlloc
		mov	al, PCCRT_NO_ERROR
almostDone:
		stc
		jmp	done
error:
		mov	al, PCCRT_COMMAND_ABORTED
		jmp	errorDone
memError:
		mov	al, PCCRT_MEMORY_ALLOC_ERROR

errorDone:
	;
	; Need to null-terminate since returned routine expects a
	; null-terminated string if CF set.
	;
		mov_tr	cx, ax			; error code
		clr	al
		stosb
		mov_tr	ax, cx			; error code
		jmp	almostDone

ListDrivesPostNameProcessing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoLocalGeosToDosOnPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do LocalGeosToDos on the Pathname

CALLED BY:	PCComGetFileSize
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	translates the contents of pathname

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	1/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoLocalGeosToDosOnPathnameES	proc	near
	uses	es
	.enter
		segmov	ds, es
		call	DoLocalGeosToDosOnPathname
	.leave
	ret
DoLocalGeosToDosOnPathnameES	endp

DoLocalGeosToDosOnPathname	proc	near
	uses	ax,cx,si
	.enter
		mov	si, offset pathname
		mov	cx, size pathname
		call	PCComGeosToDos
	.leave
	ret
DoLocalGeosToDosOnPathname	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoLocalDosToGeosOnPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do LocalDosToGeos on the Pathname

CALLED BY:	internal
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	translates the contents of pathname

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	1/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoLocalDosToGeosOnPathnameES	proc	near
	uses	es
	.enter
		segmov	ds, es
		call	DoLocalDosToGeosOnPathname
	.leave
	ret
DoLocalDosToGeosOnPathnameES	endp

DoLocalDosToGeosOnPathname	proc	near
	uses	ax,cx,si
	.enter
		mov	si, offset pathname
		mov	cx, size pathname
		call	PCComDosToGeos
	.leave
	ret
DoLocalDosToGeosOnPathname	endp
endif	;0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDosToGeos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate the string from Dos To Geos

CALLED BY:	Internal
PASS:		ds:si - ptr to text
		cx - max # of chars (0 for NULL-terminated)
RETURN:		carry - set if default character was used
DESTROYED	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	1/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDosToGeos	proc	near
	uses	es,bx
	.enter
		LoadDGroup	es, ax		
		mov	bx, es:[remoteCodePage]
		mov	ax, '-'
		call	LocalCodePageToGeos
	.leave
	ret
PCComDosToGeos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComGeosToDos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate the string from Geos to Dos

CALLED BY:	Internal
PASS:		ds:si - ptr to text
		cx - max # of chars (0 for NULL-terminated)
RETURN:		carry - set if default character was used
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	1/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComGeosToDos	proc	near
	uses	es,bx
	.enter
		LoadDGroup	es, ax
		mov	ax, '-'
		mov	bx, es:[remoteCodePage]
		call	LocalGeosToCodePage
	.leave
	ret
PCComGeosToDos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDirProcessFilespec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initial checking of filespec

CALLED BY:	PCCOMDIR	(CLIENT)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	1/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDirProcessFilespec	proc	near	myDataBlock:hptr,
					myDetailLevel:PCComDirDetailLevel,
					fileSpec:fptr
					fileSpecLength	local	word
	.enter	inherit	far
	;
	; Check for null term file spec
	;
		mov	ss:[fileSpecLength], 0
		tst	ss:[fileSpec].segment
		push	ds
		jz	specDone
		movdw	esdi, ss:[fileSpec]		; es:di <- file spec
		mov	si, di				; es:si <- file spec
		mov	cx, PATH_BUFFER_SIZE		; max length??
		clr	al
		repne	scasb
		segmov	ds, es				; ds:si <- string
		jne	specDone			; if no null, fuggit
	;
	; Is null terminated
	;
		mov	cx, di
		sub	cx, si
		dec	cx				; cx <- length
		mov	ss:[fileSpecLength], cx
	;
	; translate the file spec
	;
		clr	cx
		call	PCComGeosToDos
specDone:
		pop	ds
	.leave
	ret
PCComDirProcessFilespec	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDirStoreData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the command and store the incoming data away

CALLED BY:	PCCOMDIR	(CLIENT)
PASS:		dx - <ESC>';'
		bx - num of retries
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	1/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDirStoreData	proc	near	myDataBlock:hptr,
					myDetailLevel:PCComDirDetailLevel,
					fileSpec:fptr
					fileSpecLength	local	word
	.enter	inherit	far
		inc	bx	; we really want retries +1, but we
				; will contain the confusion
retry:
	;
	; looptop variable adjustments:
	;   di goes to beginning of buffer again, bx gets decremented
	;   indicating another attempt, and si is set to the initial
	;   buffer size
	;
		mov	si, BUFFER_SIZE
		clr	di
		dec	bx
		LONG	jz	error
	;
	; send directory listing command - note that the second char
	; (excluding ESC) is the detail level stored on the stack
	;
		call	RobustCollectOn
		mov	al, 1bh
		call	ComWrite
		mov	al, 'L'
		call	ComWrite
		mov	ax, ss:[myDetailLevel]
		call	ComWrite
	;
	; See if we've got a file specification here
	;
		tst	ss:[fileSpecLength]
		jz	noSpec
	;
	;  Write the file spec out
	;
		push	es, ds, si
		LoadDGroup	es, ax
		movdw	dssi, ss:[fileSpec]
		mov	cx, ss:[fileSpecLength]
		call	ComWriteBlock
		pop	es, ds, si
noSpec:
		mov	al, ds:[delimiter]
		call	ComWrite
		call	RobustCollectOff
	;
	; first loop - this loop stores the incoming data in our
	; buffer, reallocing as needed
	;
reAlloc:
		mov	ax, si			; si is new size
		mov	ch, mask HAF_NO_ERR or mask HAF_LOCK
		push	bx
		mov	bx, ss:[myDataBlock]
		call	MemReAlloc
		pop	bx
		jc	memError

		mov	es, ax
		mov	cx, BUFFER_SIZE
		add	si, cx			; set size for next pass
		jc	bigBufferError
		dec	cx			; set proper loop limit
	;
	; now, actually do loop, screening out ';' and watching for
	; the terminating ESC char.
	;
loopTop:
		call	ComReadWithWait
		LONG_EC	jc	retry
		cmp	al, dl			; ';'
		je	loopTop
		cmp	al, dh			; ESC
		je	done
EC<		Assert_fptr	esdi				>
		stosb
		loop	loopTop
	;
	; if we fall out of the loop we've filled up our current
	; buffer - make in bigger (si is already set with new size)
	;
		jmp	reAlloc
errorDone:
		clc
		call	WaitForAck
		stc
done:
	.leave
	ret

memError:
		mov	al, PCCRT_MEMORY_ALLOC_ERROR
		jmp	errorDone
bigBufferError:
	;
	; the results buffer is bigger than 64K!  Wow!  Truncate the
	; data, receive the rest, and return an error.
	;
		sub	di, 80		; back up at least a line
		mov	al, 0ah		; look for a newline
		repne	scasb
		cmp	{byte}es:[di], 0dh	; now it's either "\a\d" or
						; "\d\a" - is the next char
						; the '\d'?
		jne	thisChar	
		inc	di
thisChar:
		clr	{byte}es:[di]	; put a null after the pair

		mov	al, PCCRT_TOO_MUCH_OUTPUT
		jmp	errorDone

error:
		mov	al, PCCRT_COMMAND_ABORTED
		jmp	errorDone
PCComDirStoreData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComPushAbortType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the given error code in a global var only if one
		doesn't already exists.

CALLED BY:	PCCom routines

PASS:		ah - PccomAbortType
		ds - dgroup of pccom

RETURN:		err set if AbortType=PCCAT_CONNECTION_LOST
DESTROYED:	nothing - all flags preserved
SIDE EFFECTS:	
		pccomAbortType - set with PCComAbortType

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	11/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComPushAbortType	proc	near
	.enter

		pushf					; save flags

EC <		call	ECCheckDS_dgroup				>

	;
	; We'll need to renegotiate the for the next Active command.
	;
		or	ds:[robustResetRemoteState], 1

		cmp	ds:[pccomAbortType], PCCAT_DEFAULT_ABORT
		jne	skipStore			; existing error

		cmp	ah, PCCAT_REMOTE_RESERVED_ABORT_TYPE
		je	reservedCodeNumber
	;
	; If we have a broken connection, then set the err flag to
	; indicate that we've aborted.
	;
		cmp	ah, PCCAT_CONNECTION_LOST
		jne	skipSetErr
		mov	ds:[err], 1
skipSetErr:

	;
	; Tell the other side to abort.
	;
		BitSet	ds:[sysFlags], SF_EXIT		; mark to abort

		mov	ds:[pccomAbortType], ah

skipStore:
		popf					; pop flags

	.leave
	ret

reservedCodeNumber:
	;
	; We do not allow file errors that matches the ROBUST_QUOTE
	; character.  So if this happens, then we'll just make it the
	; generic abort code PCCAT_DEFAULT_ABORT
	;
EC <		WARNING	INVALID_PCCOM_ABORT_TYPE			>
		mov	ds:[pccomAbortType], PCCAT_DEFAULT_ABORT
		jmp	skipStore

PCComPushAbortType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComPushAbortTypeES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the given error code in a global var only if one
		doesn't already exists.

CALLED BY:	PCCom routines

PASS:		ah - PCComAbortType
		es - dgroup of pccom

RETURN:		nothing
DESTROYED:	nothing - all flags preserved
SIDE EFFECTS:	
		pccomAbortType - set with PCComAbortType

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	11/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComPushAbortTypeES	proc	near
	uses	ds
	.enter

EC <		call	ECCheckES_dgroup				>

		segmov	ds, es				; dgroup
		call	PCComPushAbortType

	.leave
	ret
PCComPushAbortTypeES	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolveFileErrorToPCCAT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given common FileError and filename, will map to a PCCAT.

CALLED BY:	(EXTERNAL)

PASS:		ds:dx	- null-terminated filename/pathname
		ax	- FileError
		es	- pccom dgroup
		es:[sysFlags]	- SF_GEOS_FILE, SF_USE_DOS_NAME
			if SF_USE_DOS_NAME -> 
				filename is DOS 8.3 name
			else if SF_GEOS_FILE ->
				filename is Geos long name
			else
				filename is DOS 8.3 name

RETURN:		ah	- PCComAbortType

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Mapping:

	ERROR_FILE_NOT_FOUND	-> See PCComFileNotFound
	ERROR_PATH_NOT_FOUND	-> See PCComPathNotFound
	ERROR_ACCESS_DENIED	-> See PCComAccessDenied
	ERROR_SHARING_VIOLATION	-> PCCAT_FILE_IN_USE
	ERROR_FILE_IN_USE	-> PCCAT_FILE_IN_USE
	ERROR_WRITE_PROTECTED	-> PCCAT_VOLUME_WRITE_PROTECTED
	ERROR_INVALID_DRIVE	-> PCCAT_INVALID_DRIVE
	ERROR_DRIVE_NOT_READY	-> PCCAT_VOLUME_UNAVAILABLE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolveFileErrorToPCCAT	proc	near
	uses	cx
	.enter

EC <		call	ECCheckES_dgroup				>

		mov	cx, ax			; FileError
		cmp	cx, ERROR_FILE_NOT_FOUND
		je	fileNotFound

		cmp	cx, ERROR_PATH_NOT_FOUND
		je	pathNotFound

		cmp	cx, ERROR_ACCESS_DENIED
		je	accessDenied

		cmp	cx, ERROR_SHARING_VIOLATION
		mov	ah, PCCAT_FILE_IN_USE
		je	done

		cmp	cx, ERROR_FILE_IN_USE
		mov	ah, PCCAT_FILE_IN_USE
		je	done

		cmp	cx, ERROR_WRITE_PROTECTED
		mov	ah, PCCAT_VOLUME_WRITE_PROTECTED
		je	done

		cmp	cx, ERROR_INVALID_DRIVE
		mov	ah, PCCAT_INVALID_DRIVE
		je	done

		cmp	cx, ERROR_DRIVE_NOT_READY
		mov	ah, PCCAT_VOLUME_UNAVAILABLE
		je	done

	;
	; Not mapping this particular file error.
	;
		mov	ah, PCCAT_DEFAULT_ABORT
done:
	.leave
	ret

fileNotFound:
		call	PCComFileNotFound
		jmp	done

pathNotFound:
		call	PCComPathNotFound
		jmp	done

accessDenied:
		call	PCComAccessDenied
		jmp	done

ResolveFileErrorToPCCAT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForWildCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for wildcard chars

CALLED BY:	FileSend
PASS:		filename - filename
RETURN:		es - dgroup
		ds - dgroup
		zero set - found wildcard
DESTROYED:	ax, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForWildCards	proc	near
	.enter
EC <		call	ECCheckES_dgroup				>
EC <		call	ECCheckDS_dgroup				>

		mov 	ax, '?'
		mov	cx, DOS_DOT_FILE_NAME_SIZE
		mov	di, offset filename
		LocalFindChar
		jz	done

		mov	ax, '*'
		mov	cx, DOS_DOT_FILE_NAME_SIZE
		mov	di, offset filename
		LocalFindChar
done:				
	.leave
	ret
CheckForWildCards	endp

if DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComSBCSStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give us the size of the the string without the null

CALLED BY:	INTERNAL
PASS:		es:di	= null terminated string
RETURN:		cx	= # bytes (without null)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg		2/ 6/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComSBCSStringLength	proc	far
	uses	di, ax
	.enter
		mov	cx, 0xffff
		clr	al
		repne	scasb
		not	cx
		dec	cx
	.leave
	ret
PCComSBCSStringLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDBCSStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give us the size of the DBCS string without the null

CALLED BY:	INTERNAL
PASS:		es:di	= null terminated DBCS string
RETURN:		cs	= # bytes (without null)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg		2/ 9/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDBCSStringLength	proc	far
	uses	di, ax
	.enter
		mov	cx, 0xffff
		clr	ax
		repne	scasw
		not	cx
		dec	cx
		shl	cx		; the size is bytes..
	.leave
	ret
PCComDBCSStringLength	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComCopyString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string

CALLED BY:	INTERNAL
PASS:		es:di
		ds:si
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg		2/ 6/97    	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComCopyString	proc	near
	uses	si,di
	.enter
copyLoop:
		lodsb
		stosb
		tst	al
		jnz	copyLoop
	.leave
	ret
PCComCopyString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComCmpStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare SBCS Strings

CALLED BY:	INTERNAL
PASS:		ds:si - string1
		es:di - string 2
		cx = maximum# of chars to compare (0 for null terminated)
RETURN:		flags - same as in cmps instruction - see LocalCmpStrings
			
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg		2/ 6/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComCmpStrings	proc	far
	uses	ax,cx,si,di
	.enter
		jcxz	needSize
haveSize:
		lodsb
		scasb
		jne	noMatch
loopAgain:
		loop	haveSize
cmpDone:
	.leave
	ret

needSize:
		call	PCComSBCSStringLength
		inc	cx		; both better be null term in
					; same place..  compare those too
		jmp	haveSize
noMatch:
		pushf			; incase we need the original result
	;
	; OK, this is case insensitive
	;
		cmp	al, 'A'
		jb	reallyNoMatch
		cmp	al, 'Z'
		ja	notUpper
		add	al, 'a' - 'A'
		jmp	cmpAgain
notUpper:
		cmp	al, 'a'
		jb	reallyNoMatch
		cmp	al, 'z'
		add	al, 'A' - 'a'
		jbe	cmpAgain
reallyNoMatch:
		popf
		jmp	cmpDone
cmpAgain:
		dec	di
		scasb
		jne	reallyNoMatch
		popf
		jmp	loopAgain
PCComCmpStrings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComUpcaseChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upcase a single SBCS char

CALLED BY:	INTERNAL
PASS:		al - character to upcase
RETURN:		al - uppercase character
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg		2/ 6/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComUpcaseChar	proc	far
	.enter
		cmp	al, 'a'
		jc	done
		cmp	al, 'z'
		ja	done
		add	al, ('A' - 'a')
done:
	.leave
	ret
PCComUpcaseChar	endp


endif	; DBCS_PCGEOS


Main	ends




