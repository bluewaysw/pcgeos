COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Dial
FILE:		dialModem.asm

AUTHOR:		Ted H. Kim, 1/4/90

ROUTINES:
	Name			Description
	----			-----------
	InitComUse		Initializes the baud rate and other stuff
	CloseComPort		Close up the serial port 
	CheckInput		Notification routine for serial port input
	TimedOut		Gets called when timed out after connecting
	ReadIniFile		Reads in serial port settings from geos.ini file
	SetSerialPart1		Sets internal serial port settings		
	SetSerialPart2		Sets more serial port settings
	SearchString2		Searches for a word in a string
	OpenComPort		Open up a com port for communication
	DialUp			Makes a phone call
	PreparePhoneCall	Sets up the modem for voice communication
	DialTheNumber		Dials the number given 
	GetPhoneNumber		Grabs the complete phone number to display
	GetAreaCode		Grabs the area code to display
	CheckForNumber		Checks to see if a char is a numeric character
	AddOtherNumbers		Dials prefix or area code if there are any 
	EndPhoneCall		Terminates the phone call
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	1/4/90		Initial revision
	ted	3/92		Complete restructuring for 2.0

DESCRIPTION:
	This file contains all the modem related routines.

	$Id: dialModem.asm,v 1.1 97/04/04 15:49:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitComUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up variables for using the Serial Driver routines.

CALLED BY:	RolodexOpenApp	

PASS:		serialPort - set to a usuable com port

RETURN:		all serial variables initialized
		serialHandle - handle of serial driver 

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	1/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitComUse	proc	near
	clr	ds:[lastModified]
	clr	ds:[lastModified+2]		; initialize time stamp
	mov	ds:[changeFlag], 0		; initialize change flag
	mov	ds:[toneType], -1		; initialize to touch tone
	mov	ds:[serialPort], SERIAL_COM1	; default com port - com one
	mov	ds:[serialBaud], SB_1200	; assume 1200 bps
	mov	ds:[serialHS], SM_COOKED	; handshake info 
	mov	ds:[serialFlow], mask SFF_SOFTWARE	; assume software flow
	mov	ds:[serialFormat], SerialFormat<0,0,SP_NONE,0,SL_8BITS>
	mov	ds:[serialModem], mask SMC_RTS or mask SMC_DTR
	mov	ds:[serialModemStatus], mask SMS_CTS or mask SMS_DCD or \
					mask SMS_DSR
	mov	bx, handle serial
	mov	ds:[serialHandle], bx		; save handle of serial driver
	mov	ax, ds				; save our seg register
	call 	GeodeInfoDriver			; get ptr to info table
	mov	bx, ds:[si].DIS_strategy.offset	; get the routine offset
	mov	dx, ds:[si].DIS_strategy.segment; get routine segment
	mov	ds, ax				; restore ds
	mov	ds:serialDriver.offset, bx	; store driver offset 
	mov	ds:serialDriver.segment, dx	; store driver segment
	mov	ds:[portOpen], PORT_NOT_OPEN	; serial port is not open yet
	ret
InitComUse	endp

Init	ends

Exit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseComPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the com port

CALLED BY:	UTILITY

PASS:		serialPort - com port to close

RETURN:		carry set if error 

DESTROYED:	ax, bx, cx, dx, di, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	1/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseComPort	proc	far
	tst	ds:[serialHandle]		; was serial driver loaded? 
	je	noError				; if not, exit
	cmp	ds:[serialPort], NO_PORT	; was serial port open?
	je	noError				; if not, exit
	cmp	ds:[portOpen], PORT_NOT_OPEN	; if port not open,
	je	noError				; exit
	cmp	ds:[portOpen], NO_MODEM		; if there is no modem,
	je	noError				; exit
	mov	bx, ds:[serialPort]		; bx - com port to close up 
	mov	ax, STREAM_BOTH
	CallSer	DR_STREAM_FLUSH			; flush any input
	mov	ax, STREAM_DISCARD		; make sure port is empty
	CallSer	DR_STREAM_CLOSE			; then close it
	;mov	ds:[serialPort], NO_PORT	; no port is open
	mov	ds:[portOpen], PORT_NOT_OPEN
	jmp	short	exit
noError:
	clc
exit:
	ret	
CloseComPort	endp

Exit	ends

Fixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification routine for serial input - i.e. this is 
		the routine that gets called whenever there is a new
		character to be read in serial port.

CALLED BY:	Serial Driver

PASS:		cx - segment address of dgroup
		al - character to be read in

RETURN:		carry set if the character is processed 
		new character is stored in inputBuffer
		offsetInput is updated

DESTROYED:	bx

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine has to be in fixed code module
	so I can do stuff like 'mov	bx, segment dgroup'.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckInput	proc	far
	push	ds
	push	si			; save ds and si
	mov	ds, cx
	mov	si, ds:[offsetInput]	; ds:si - pointer to input buffer
	mov	ds:[si], al 		; store the new character
	inc	ds:[offsetInput]	; update the offset
	pop	si
	pop	ds			; restore ds and si
	stc				; the character has been processed
	ret
CheckInput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimedOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine that gets called when dialing times out

CALLED BY:	Kernel

PASS:		ax - handle of DialSummons object

RETURN:		nothing

DESTROYED:	ax, bx, dx, si, di

PSEUDO CODE/STRATEGY:
	Set DialSummons unusable.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimedOut	proc	far	
	mov	si, offset DialSummons		; bx:si - OD of DialSummons 
	mov	bx, ax
	mov	ax, MSG_GEN_SET_NOT_USABLE	; make the summons not usable
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	; VisUpdateMode => DL
	clr	di				; not a call
	call	ObjMessage			; make dialogue box disappear
	ret
TimedOut	endp

Fixed	ends

Modem	segment	resource

BaudToConst	label		word
		
	; first column is how the user will specify the baud rate
	; second column is the corresponding baud rate constant

	word	300, SB_300
	word	600, SB_600
	word	1200, SB_1200
	word	2400, SB_2400
	word	4800, SB_4800
	word	9600, SB_9600
	word	19200, SB_19200
End_BaudToConst	label	word
Length_BaudToConst	equ	(End_BaudToConst - BaudToConst) / (2*(size word))

	; modem key and category strings in GEOS.INI file

	modemString	char	'modem', 0
	modemKeyString	char	'modems', 0	; == string
	portString	char	'port', 0	; == string (com1,com2,com3)
	toneString	char	'toneDial', 0	; == boolean
	baudString	char	'baudRate', 0	; == intger (2400,9600,19200)
	handShakeString	char	'handshake', 0	; == low-string(n*,h*,s*)
	parityString	char	'parity', 0	; == low-string(one,none,even,odd)
	wordLenString	char	'wordLength', 0	; == intger (5,6,7,8)
	stopBitsString	char	'stopBits', 0	; == low-string(,2)
	remoteString	char	'stopRemote', 0	; == low-string(,d*)
	localString	char	'stopLocal', 0	; == low-string(*cts,*dcd,*dsr)

	;  Strings in .ini file under "stopLocal=" (must be lower case)
	;
	LocalDefNLString	ctsString, <'cts', 0>
	LocalDefNLString	dcdString, <'dcd', 0>
	LocalDefNLString	dsrString, <'dsr', 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads in serial port settings from geos.ini file

CALLED BY:	OpenComPort

PASS:		ds - dgroup

RETURN:		various settings read in

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Read "[modem]modems=" to see which modem we're to use.
		If DBCS, convert modem name to SBCS since categories
			must be SBCS (sigh).
		With the modem name as a category name, get its settings.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Keys are always stored in SBCS.  Numeric values are SBCS.
		String values are in DBCS or SBCS depeing on kernel compile.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/26/90		Initial version
	witt	1/20/94  	Overhaul and cleanup, DBCS-ized too!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadIniFile	proc	near
	push	ds
	segmov	ds, cs, ax
	mov	si, offset modemString		; ds:si - category string
	mov	cx, ds
	mov	dx, offset modemKeyString	; cx:dx - key string
	clr	bp				; allocate a buffer for string
	call	InitFileReadString		; find modem name to use
						; bx - entry handle
	pop	ds
	jnc	noError				; if found, skip
empty:
	mov	ds:[portOpen], NO_MODEM		; set no modem flag
	jmp	short	exit			; and quit
noError:
	tst	cx				; is there a string?
	jne	notEmpty			; if not, skip	
	call	MemFree				; delete this block
	jmp	empty				; set flag and exit

notEmpty:
	push	bx				; save the handle
	call	MemLock				; lock the data block
	mov	es, ax	
	clr	di				; es:di - ptr to modem names
DBCS <	clr	si				; es:si - ptr DBCS modem name>
miniLoop:
if DBCS_PCGEOS
	; NOTE for DBCS:
	;  As strings in Ini file are in unicode, and keyword strings
	;  are still ASCIIZ, we have to convert them for further use.
	;  C_NULL or C_CR are terminators.

	mov	ax, {wchar} es:[si] 		; get a character
	LocalIsNull	ax			; are we end of buffer?
	je	found				; if so, exit the loop
	cmp	ax, C_CR			; is this a CR character
	je	found				; if so, exit the loop
EC <	cmp	ax, 127				; Is char Unicode unique? >
EC <	ERROR_AE 0				;  Yes, bitch loudly!	  >

	stosb					; es:di <- Ascii(AX)
	LocalNextChar	essi			; otherwise, check the next char
	jmp	miniLoop	
else
	cmp	{byte} es:[di], 0		; are we end of buffer?
	je	found				; if so, exit the loop
	cmp	{byte} es:[di], C_CR		; is this a CR character
	je	found				; if so, exit the loop
	inc	di				; otherwise, check the next char
	jmp	miniLoop	
endif

	; Use name at es:0 at category string to read in options for
	; this particular modem. ds = segment where keywords string stored.

found:
	LocalClrChar	es:[di]			; null terminate the string	>
	push	ds				; save seg addr of core block
	call	SetSerialPart1			; read in serial port info
	call	SetSerialPart2			; 	from geos.ini file

	pop	ds				; restore seg addr of core block
	pop	bx				; bx - handle of mem block
	call	MemFree				; free this block
	cmp	ds:[portOpen], NO_MODEM		; no modem flag set?
	jne	exit				; if not, exit
	mov	ds:[portOpen], PORT_NOT_OPEN	; serial port is not open yet
exit:
	ret
ReadIniFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSerialPart1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads in serial port setting information from geos.ini file

CALLED BY:	ReadIniFile

PASS:		es:0 - points to category string
		ds - segment address of core block

RETURN:		nothing		

DESTROYED:	ax, bx, cx, dx, di, bp, ds, es

PSEUDO CODE/STRATEGY:
	Initialize variables to default settings
	Check for tone type			(boolean)
	If found, assing new tone type		(-1,0)
	Check for serial port string		(string: com1,com2,com3,com4)
	If found, assign new port number	(0,1,2,3)
	Check for baud rate string		(integer)
	If found, assign new baud rate
	Check for parity string			(string:odd,even,none,one)
	If found, assign new parity bit info
	Check for word length string
	If found, assign new word length info
	Check for stop bits string		; if exists, assume it is 2.
	If found, assign new stop bit to 2.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The parity string is not easily localized without rewriting code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSerialPart1	proc	near
	push	es				; exchange ds with es	
	push	ds
	pop	es				; es - seg addr of core block
	pop	ds				; ds - seg addr of data block
	
	; check to see whether touch or pulse tone dialing

	clr	si				; ds:si - category string
	mov	cx, cs
	mov	dx, offset toneString		; cx:dx - key string
	call	InitFileReadBoolean		; get tone type 
	jc	noEntry				; skip if no entry
	
	mov	es:[toneType], ax		; save the result
						; -1 = touch, 0 = pulse tone
noEntry:
	; check for port number

	clr	si				; ds:si - category string
	mov	cx, cs
	mov	dx, offset portString		; cx:dx - key string
	clr	bp				; allocate a buffer for string
	call	InitFileReadString		; find the serial port to use
	jc	getBaud				; if not found, get baud rate
	jcxz	noChange1

	; if found, get the port number

	push	es				; save seg addr of core block
	call	MemLock
	mov	es, ax
if DBCS_PCGEOS
	mov	di, 3*(size wchar)		; es:di - ptr to port number
	mov	dx, {wchar} es:[di]		; dx - port number
else
	mov	di, 3*(size char)		; es:di - ptr to port number
	mov	dl, {char} es:[di]		; dl - port number in ASCII
	clr	dh
endif
	sub	dx, '0'				; dx - port number in integer
	dec	dx				; sub one to adjust
	shl	dx, 1				; dx - com port number
	pop	es				; es - core block
	cmp	es:[serialPort], dx		; store the port number
	je	noChange1
	ornf	es:[changeFlag], mask SSCF_PORT	; port number is changed
	mov	es:[newPortNum], dx		; save the new port number
noChange1:
	call	MemFree				; delete the data block
getBaud:
	; check for baud rate

	mov	cx, cs
	mov	dx, offset baudString		; cx:dx - key string
	call	InitFileReadInteger		; find the baud rate to use
	jc	getParity			; if not found, skip

	; if found, look up the corresponding constants 

	clr	di				; index into BaudToConst table
	mov	cx, Length_BaudToConst		; number of entries in table
EC<	cmp	cx, 7			; check vs original code; witt	>
EC<	ERROR_NE SPECIFIC_CONSTANT_WRONG	; bad, Brian!		>
loop1:
	cmp	ax, cs:BaudToConst[di]		; is there a match?
	je	foundBaud			; if so, skip to handle it
	add	di, 2*(size word)		; if not, 
	loop	loop1				; check the next entry
	jmp	short	getParity		; if not in table, use default
foundBaud:
	mov	cx, cs:BaudToConst[di+2]	; we have a match
	cmp	es:[serialBaud], cx		; save the constant
	je	getParity
	ornf	es:[changeFlag], mask SSCF_BAUD	; baud rate is changed
	mov	es:[serialBaud], cx		; save the constant

getParity:
	; check for the parity 

	mov	al, es:[serialFormat]
	push	ax
	mov	cx, cs
	mov	dx, offset parityString		; cx:dx - key string
	mov	bp, INITFILE_DOWNCASE_CHARS	; allocate a buffer
	call	InitFileReadString		; string buffer handle => BX
	jc	getWordLength			; if not found, skip
	jcxz	noParity

	; if found, get the parity

	call	MemLock				; lock the string buffer
	push	es				; save core block
	mov	es, ax
SBCS <	mov	bp, (size char) 		; ES:BP points to the 2nd char>
DBCS <	mov	bp, (size wchar)		; ES:BP points to the 2nd char>
	mov	al, SP_NONE shl (offset SF_PARITY)

	LocalCmpChar	es:[bp], 'o'		; check for o in "none"
	je	setParity
	mov	al, SP_ODD shl (offset SF_PARITY)

	LocalCmpChar	es:[bp], 'd' 		; check for d in "odd"
	je	setParity
	mov	al, SP_EVEN shl (offset SF_PARITY)

	LocalCmpChar	es:[bp], 'v' 		; check for v in "even"
	je	setParity
	mov	al, SP_ONE shl (offset SF_PARITY)

	LocalCmpChar	es:[bp], 'n' 		; check for n in "one"
	je	setParity
	mov	al, SP_ZERO shl (offset SF_PARITY)
setParity:
	pop	es				; es - core block
noParity:
	call	MemFree				; free the buffer in BX
	and	es:[serialFormat], not mask SF_PARITY	; clear the old parity
	or	es:[serialFormat], al		; set the new parity
getWordLength:
	; check for word length

	mov	cx, cs
	mov	dx, offset wordLenString	; cx:dx - key string
	call	InitFileReadInteger		; integer value => AX
	jc	getStopBits			; if not found, skip

	; if found, get the word length

	sub	al, 5				; 5 =>0, 6=>1, etc...
	and	es:[serialFormat], not mask SF_LENGTH	; clear old word length
	mov	cl, offset SF_LENGTH
	shl	al, cl				; put value into correct pos.
	or	es:[serialFormat], al		; set new word length
getStopBits:
	; check for stop bits

	mov	cx, cs
	mov	dx, offset stopBitsString	; cx:dx - key string
	mov	bp, INITFILE_INTACT_CHARS	; allocate a buffer
	call	InitFileReadString		; string buffer handle => BX
	jc	quit				; if no key, then done

	; if found, get the stop bits

	cmp	cx, 1				; only one character ??
	je	exit				; if so, exit
	or	es:[serialFormat], mask SF_EXTRA_STOP	; else set the stop bit
exit:
	call	MemFree				; free the buffer in BX
quit:
	pop	ax
	cmp	es:[serialFormat], al		
	je	noChange3
	ornf	es:[changeFlag], mask SSCF_FORMAT	; serial format changed
noChange3:
	ret
SetSerialPart1	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSerialPart2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads in more serial port information from geos.ini file

CALLED BY:	ReadIniFile

PASS:		ds:si - category string
		es - segment address of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds

PSEUDO CODE/STRATEGY:
	Check for handshaking string
	If found, assign new handshaking info
	If hardware flow control is set
		Check for stop remote string
		If found, assign new Serial Modem Setting 
		Check for stop local string
		If found, assign new Serial Modem Status Setting

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSerialPart2	proc	near

	; check for handshake infomation

	mov	cx, cs
	mov	dx, offset handShakeString	; cx:dx - key string
	mov	bp, INITFILE_DOWNCASE_CHARS	; allocate a buffer
	call	InitFileReadString		; string buffer handle => BX
	LONG	jc	exit			; if not found, exit
	jcxz	noChange

	; if found, get the handshake info

	call	MemLock				; lock the string buffer
	push	es				; save core block
	mov	es, ax
	clr	di				; ES:DI points to the string
	mov	ah, SM_COOKED			; assume cooked mode

	LocalCmpChar	es:[di], 'n'		; check for n in "none"
	jne	setHandshake			; skip, if not found 
	mov	ah, SM_RAW			; no flow control
setHandshake:
	; check to see if we have to set hardware handshake

	push	cx, di				; save # of chars in buffer

DBCS <	push	ax				; save ah. for scansw	>

	LocalLoadChar	ax, 'h'			; character to search for
	LocalFindChar				; search for h in 'hardware'

DBCS <	pop	ax				; ah <- serialHS	>
	clr	dx
	tst	cx				; is 'h' found?
	je	software			; if no, check for 'software'
	ornf	dx, mask SFF_HARDWARE		; if yes, set hardware flag
software:
	pop	cx, di				; cx - # of chars in buffer

	; check to see if we have to set software handshake

DBCS <	push	ax				; save ah. for scansw	>
	LocalLoadChar	ax, 's'			; character to search for
	LocalFindChar				; search for 's' in 'software'
DBCS <	pop	ax				; ah <- serialHS	>
	tst	cx				; is 's' found?
	je	done				; if no, skip

	ornf	dx, mask SFF_SOFTWARE		; if yes, set software flag
done:
	pop	es				; es - core block
	mov	es:[serialHS], ah		; assign new serial mode flag
	cmp	es:[serialFlow], dx		; assume no hardware flow ctrl
	je	noChange
	ornf	es:[changeFlag], mask SSCF_FLOW	; serial flow changed
	mov	es:[serialFlow], dx		; assume no hardware flow ctrl
noChange:
	call	MemFree				; free the buffer in BX

	; check for Stop Remote

	mov	cx, cs
	mov	dx, offset remoteString		; cx:dx - key string
	mov	bp, INITFILE_DOWNCASE_CHARS	; allocate a buffer
	call	InitFileReadString		; string buffer handle => BX
	jc	getLocal			; if not found, skip
	jcxz	noRemote

	; if found, get which options are set

	call	MemLock				; lock the string buffer
	push	es				; save core block
	mov	es, ax
	clr	di				; ES:DI points to the string
	LocalLoadChar	ax, C_CR		; ax - character to search for
	LocalFindChar				; search for carriage return

	mov	al, mask SMC_RTS or mask SMC_DTR
	tst	cx				; are there two entries?
	jne	setRemote			; if so, skip
	clr	di				; reinitialize offset
	mov	al, mask SMC_RTS		; assume RTS

	LocalCmpChar	es:[di], 'd'		; is DTR enabled?

	jne	setRemote			; if not, skip
	mov	al, mask SMC_DTR		; set DTR
setRemote:
	pop	es				; es - core block
	mov	es:[serialModem], al		; assign new modem setting
noRemote:
	call	MemFree				; free the buffer in BX
getLocal:
	; check for Stop Local

	mov	cx, cs
	mov	dx, offset localString		; cx:dx - key string
	mov	bp, INITFILE_DOWNCASE_CHARS	; allocate a buffer
	call	InitFileReadString		; string buffer handle => BX
	jc	exit				; if not found, exit
	jcxz	noLocal

	; if found, get which options are set

	call	MemLock				; lock the string buffer
	push	es				; save core block
	mov	es, ax			
	clr	di				; ES:DI points to the string
	mov	al, mask SMS_CTS or mask SMS_DCD or mask SMS_DSR
	segmov	ds, cs
	mov	si, offset ctsString		; ds:si - 'cts'
	mov	cx, 3				; cx - # of chars to compare
	call	SearchString2			; search for this string
	jc	checkDCD			; if found, skip 
	andnf	al, not mask SMS_CTS		; if not found, clear this flag
checkDCD:
	mov	si, offset dcdString		; ds:si - 'dcd'
	mov	cx, 3				; cx - # of chars to compare
	call	SearchString2			; search for this string
	jc	checkDSR			; if found, skip
	andnf	al, not mask SMS_DCD		; if not found, clear this flag
checkDSR:
	mov	si, offset dsrString		; ds:si - 'dsr'
	mov	cx, 3				; cx - # of chars to compare
	call	SearchString2			; search for this string
	jc	setLocal			; if found, skip
	andnf	al, not mask SMS_DSR		; if not found, clear this flag
setLocal:
	pop	es				; es - core block
	mov	es:[serialModemStatus], al	; assign new modem status
noLocal:
	call	MemFree				; free the buffer in BX
exit:
	ret
SetSerialPart2	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchString2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches for a word in a string 

CALLED BY:	UTILITY (private to this file)

PASS:		ds:si - word to search for
		es:di - string to search
		cx - length of the search word

RETURN:		carry clear if no match is found
		carry set if a match is found

DESTROYED:

PSEUDO CODE/STRATEGY:
		repeat:
			String compare ds:si to es:si.
			If matches, great, return carry set.
			Advance es:si one character.
		while( es:[di] != C_NULL ).
		return carry clear, ie didn't match.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Doesn't handle words that start with wild card characters.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/8/90		Initial version
	witt	1/21/94 	DBCS-ized, string case exact.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchString2	proc	near
	push	ax
mainLoop:
	call	LocalCmpStringsNoCase 	; compare the strings
	je	match			; exit if they match

	LocalNextChar	esdi		; post-incr
	LocalGetChar	ax, esdi, noAdvace	; if not, check the next string
	LocalIsNull	ax		; are we end of string?

	jne	mainLoop		; if not, continue..
	clc				; no match
	jmp	exit
match:
	stc				; match found
exit:
	pop	ax
	ret
SearchString2	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenComPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the port and set buffer sizes, etc.

CALLED BY:	UTILITY

PASS:		serialPort - usable com port number (default is SERIAL_COM1)
		serialBaud - modem baud rate (default is 2400)

RETURN:		carry set if error openning port

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	Get com port to open up from 'geos.ini' file
	If none defined, use default com port - com one
	Open up this port
	Exit with carry set if error
	Set various modem settings

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenComPort	proc	far
	call	InitFileGetTimeLastModified	; get last modification time
	cmp	ds:[lastModified], cx		; is .ini file modified?
	jne	readIni				; if so, read in .ini file
	cmp	ds:[lastModified+2], dx		; is .ini file modified?
	jne	readIni				; if so, read in .ini file

	; if cx and dx are zeroes, then .ini file has never been read,
	; so go ahead and read it

	tst	cx				
	jne	dontRead
	tst	dx
	jne	dontRead
readIni:
	mov	ds:[lastModified], cx
	mov	ds:[lastModified+2], dx
	call	ReadIniFile			; read in geos.ini file
dontRead:
	cmp	ds:[portOpen], NO_MODEM		; has modem been configured?
	LONG	je	error2			; if not, put up an error box

	cmp	ds:[portOpen], PORT_OPEN	; is serial port already open?
	jne	open				; if not, open

	test	ds:[changeFlag], mask SSCF_PORT	; is port number changed?
	je	checkFormat			; if not, skip

	call	CloseComPort			; close old serial port 
	mov	bx, ds:[newPortNum]		; bx - new serial port number
	mov	ds:[serialPort], bx		; open this serial port
	jmp	short	open2
open:
	test	ds:[changeFlag], mask SSCF_PORT	; is port number changed?
	je	open2				; if not, skip

	mov	bx, ds:[newPortNum]		; bx - new serial port number
	mov	ds:[serialPort], bx		; open this serial port
open2:
	mov	bx, ds:[serialPort]		; bx - port to use 
	mov	ax, mask SOF_NOBLOCK		; don't block if port in use
	mov	cx, SERIAL_IN_SIZE		; size of serial input buffer
	mov	dx, SERIAL_OUT_SIZE		; size of serial output buffer
	CallSer DR_STREAM_OPEN			; open the port - carry updated
	jnc	noError				; exit if error

	cmp	ax, STREAM_DEVICE_IN_USE	; is serial port busy?
	LONG	jne	quit			; if not, put up an error box
	jmp	error				; and put up an error box
noError:
	mov	bx, ds:[serialPort]		; set port to use 
	mov	ax, StreamNotifyType<1, SNE_DATA, SNM_ROUTINE>	
						; ax - set some flags
	mov	dx, offset CheckInput		; call CheckInput every time
	GetResourceSegmentNS	CheckInput, es	;    there is a new character
	mov	cx, es				; cx:dx - notification routine
	mov	bp, ds				; pass dgroup in bp
	CallSer DR_STREAM_SET_NOTIFY		; set the stream read mode
checkFormat:
	cmp	ds:[portOpen], PORT_OPEN	; is serial port already open?
	jne	setFormat			; if not, open

	test	ds:[changeFlag], mask SSCF_BAUD or mask SSCF_FORMAT or \
		mask SSCF_FLOW			; has the baud rate changed?
	je	skip				; if not, skip	
setFormat:
	mov	cx, ds:[serialBaud]		; cx - baud rate to set modem at
	mov	ah, ds:[serialHS]		; ah - serial mode record
	mov	al, ds:[serialFormat]		; al - serial format record
	mov	bx, ds:[serialPort]		; set port to use 
	CallSer	DR_SERIAL_SET_FORMAT		; set these flags
	jc	exit

	cmp	ds:[portOpen], PORT_OPEN	; is serial port already open?
	jne	setModem			; if not, open

	test	ds:[changeFlag], mask SSCF_FLOW	; has flow control changed?
	je	skip				; if not, skip
setModem:
	; Assert DTR and RTS so the modem will talk to us
	
	; DON'T HAVE TO DO THIS ANYMORE, SINCE SERIAL DRIVER
	; DOES IT AUTOMATICALLY WHEN IT OPENS THE COM PORT.

	;mov	bx, ds:[serialPort]		; set port to use 
	;mov	al, ds:[serialModem]		; al - serial modem record
	;CallSer	DR_SERIAL_SET_MODEM		; set modem

	test	ds:[serialFlow], mask SFF_HARDWARE	; hardware flow control?
	je	skip				; if not, skip

	mov	bx, ds:[serialPort]		; set port to use 
	mov	cl, ds:[serialModem]		; cl - stop remote
	mov	ch, ds:[serialModemStatus]	; ch - stop local
	mov	ax, ds:[serialFlow]		; ax - flow control flag
	CallSer	DR_SERIAL_SET_FLOW_CONTROL
skip:
	mov	ds:[portOpen], PORT_OPEN	; clear the flag
	clc					; exit with no error
exit:
	clr	ds:[changeFlag]			; clear change flag
	ret

quit:
	;mov	ds:[serialPort], NO_PORT	; no port is open
error:
	mov	bp, ERROR_PORT_IN_USE		; bp - error message number
	jmp	short	errorBox
error2:
	mov	bp, ERROR_NO_MODEM		; bp - error message number
errorBox:
	call	DisplayErrorBox			; put up a warning box
	stc					; exit with error
	jmp	short	exit
OpenComPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DialUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the routine that actually dials the given number.

CALLED BY:	(GLOBAL) RolodexDial, RolodexQuickButton 	

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, es 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DialUp	proc	far

	class	RolodexClass

	; locate the string to display

	GetResourceHandleNS	DialingText, bx	; bx - handle of object	
	call	MemLock				; lock the resource blk
	push	bx				; save handle of resource blk 
	push	ds				; save seg addr of core blk
	mov	ds, ax				; ds - seg addr of resource blk
	mov	si, offset DialingText		; si - chunk handle of text
	mov	si, ds:[si]			; ds:si - ptr to the string
	mov	dx, ds				 
	mov	bp, si				; dx:bp - ptr to the string
	clr	cx				; the string is null terminated

	mov	si, offset DialingMsg 
	GetResourceHandleNS	DialingMsg, bx	; bx:si - OD of text display obj
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR		
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; add the text to dialogue box
	pop	ds				; restore seg addr of core blk
	pop	bx				; restore handle of resource blk
	call	MemUnlock			; unlock the resource block

	mov	si, offset InstMsg 
	GetResourceHandleNS	InstMsg, bx	; bx:si - OD of text display obj
	call	ClearTextField			; clear this text edit field
		
	mov	si, offset DialSummons		; bx:si - OD of dialog box
	GetResourceHandleNS	DialSummons, bx 
	mov	ax, MSG_GEN_SET_USABLE		; make the summons usable
	mov	dl, VUM_NOW			; VisUpdateMode => DL
	clr	di				; not a call
	call	ObjMessage

	; bring up the dialog box

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; make the dialog box appear
	call	PreparePhoneCall		; prepare modem for a call
	jc	exit				; if error, put up error msg
DBCS <	push	ds							>
	call	DialTheNumber			; dial given number
DBCS <	pop	ds							>
	jnc	done				; if no error, exit
exit:
	; locate the string to display

	GetResourceHandleNS	ModemErrorText, bx ; bx - handle of resource blk
	call	MemLock				; lock the resource block
	push	bx				; save handle of resource block 
	push	ds				; save seg addr of core block
	mov	ds, ax				; ds - seg addr of resource blk 
	mov	si, offset ModemErrorText	; si - chunk handle of text 
	mov	si, ds:[si]			; ds:si - ptr to string
	mov	dx, ds
	mov	bp, si				; dx:bp - ptr to string
	clr	cx				; the string is null terminated

	mov	si, offset DialingMsg 
	GetResourceHandleNS	DialingMsg, bx	; bx:si - OD of text display obj
	mov	ax, MSG_VIS_TEXT_APPEND
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; display the error message
	pop	ds				; restore seg addr of core block
	pop	bx				; restore handle of resource blk
	call	MemUnlock			; unlock the resource block
	clc					; return with no error
done:
	ret
DialUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreparePhoneCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the modem and set it to non-echo, numeric result mode.

CALLED BY:	DialUp

PASS:		serialPort - serial port to talk to

RETURN:		carry set if there was an error
		carry clear otherwise

DESTROYED:	ax, bx, cx, dx, si, di, es 

PSEUDO CODE/STRATEGY:
	Reset the modem
	Turn echoing off
	Numeric result code on

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreparePhoneCall	proc	near
	mov	ax, STREAM_READ			; affect only stream read
	mov	bx, ds:[serialPort]		; bx - serial port to write to
	CallSer	DR_STREAM_FLUSH			; flush the stream buffer

	; is 'reset the modem before dialing option' set?

	mov	si, offset DialingOptions	; bx:si - OD of list entry	
	GetResourceHandleNS	DialingOptions, bx 
	mov	cx, mask DOF_RESET		; cx - identifier
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage			; get the state of check box 
	jnc	exit				; if off, exit

	; reset the modem before dialing

	mov	ds:[offsetInput], offset inputBuffer
						; init. offset into inputBuf
	mov	si, offset resetCommand		; ds:si - string to write 
	mov	cx, 4				; cx - # of bytes in string
	mov	bx, ds:[serialPort]		; bx - serial port to write to
	mov	ax, STREAM_BLOCK
	CallSer	DR_STREAM_WRITE			; reset the modem
	jc	exit				; if error, exit

	mov	ax, 300				; wait 5 seconds
	call	TimerSleep			; for modem to respond

	; DON'T CHECK FOR OK - ted 2/21/93

	clc					; exit with no error
exit:
	ret
PreparePhoneCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DialTheNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the dial command and actual phone numbers to modem.

CALLED BY:	DialUp

PASS:		fieldHandles - handle of data block with phone number
		fieldLengths - length of phone number

RETURN:		carry set if error

DESTROYED:	ax, bx, cx, si, di, bp 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	How should postpended phone number be handled?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DialTheNumber	proc	near
	clr	ds:[inputBuffer]		; clear the input buffer
	mov	ds:[offsetInput], offset inputBuffer
						; init. offset into inputBuf
	mov	si, offset dialCommand		; ds:si - string to write
	tst	ds:[toneType]			; is it a touch phone?
	js	touch				; if so, skip
	mov	si, offset dialCommand2		; if not, send ATDP instead
touch:
	mov	cx, 4				; cx - # of bytes to write
	mov	bx, ds:[serialPort]		; bx - serial port to write to
	mov	ax, STREAM_BLOCK
	CallSer	DR_STREAM_WRITE			; send dial commands
	LONG	jc	exit			; if error, exit

	test	ds:[phoneFlag], mask PF_CONFIRM	; confirm box required? 
	je	noConfirm			; if not, skip

	; if so, get the phone number to display inside the confirm box

	mov	bx, ds:[phoneHandle]
	tst	bx				; is there a number to display?
	LONG	je	exit			; if none, just exit
	call	MemLock				; if so, lock this block
	mov	ds:[phoneNoBlk], ax		; save the seg address
	jmp	common				; jump to display this number
noConfirm:
	; read in the phone number into a memory block

	call	GetPhoneNumber			
common:	
	; write out the phone number to the com port 

	segmov	es, ds
	mov	ax, es:[phoneNoBlk]
	mov	ds, ax				; ds - seg addr of mem block
	clr	si				; ds:si - ptr to phone number
	mov	cx, es:[phoneOffset]		; cx - number of bytes to write

if DBCS_PCGEOS
	; must convert phone # from unicode to ascii
	call	DialPhoneNoGeosToDos		; bx <- handle,  ds <- seg
						; cx <- # of bytes to write
	push	bx				; SBCS converted string handle
endif
	push	si
	mov	ax, STREAM_BLOCK
	mov	di, DR_STREAM_WRITE		; dial the phone number
	mov	bx, es:[serialPort]		; bx - serial port to write to
	push	cx				; cx - number of bytes to write 
	call	es:serialDriver			; make a call to serial driver
	pop	cx				; cx - number of bytes to write
	pop	si
if DBCS_PCGEOS
	lahf					; save error flag from serial
	; do clean up for DialPhoneNoGeosToDos
	pop	bx				; bx - mem handle
	call	MemFree				; free mem
	sahf
endif
	LONG	jc	exit			; exit if serial  error

	; append the phone number to the dialog box

	mov	dx, es:[phoneNoBlk]		; dx - seg addr of string
	clr 	bp				; dx:bp - string to append
	mov	cx, es:[phoneOffset]		; cx - number of bytes to append
DBCS <	shr	cx, 1				; cx - # of chars	>
	mov	si, offset DialingMsg 
	GetResourceHandleNS	DialingMsg, bx	; bx:si - OD of text display obj
	mov	ax, MSG_VIS_TEXT_APPEND
	mov	di, mask MF_CALL 
	call	ObjMessage			; display the phone number

	mov	bx, es:[phoneHandle]		; bx - handle of phone block
	call	MemFree				; free this data block

	; locate the string to display and display it

	GetResourceHandleNS	InstructionText, bx ; bx - handle of resource
	call	MemLock				; lock the resource block
	push	bx				; save handle of resource block
	mov	ds, ax				; ds - seg addr of resource blk
	mov	si, offset InstructionText	; si - chunk handle of text
	mov	si, ds:[si]			; ds:si - ptr to string
	mov	dx, ds
	mov	bp, si				; dx:bp - ptr to string
	clr	cx				; the string is null terminated
	mov	si, offset InstMsg 
	GetResourceHandleNS	InstMsg, bx	; bx:si - OD of text display obj
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL 
	call	ObjMessage			; display the instruction
	pop	bx				; restore handle of resource blk
	call	MemUnlock			; unlock the resource block

	; start the timer

	segmov	ds, es
	mov	ax, TIMER_ROUTINE_ONE_SHOT
	mov	cx, 1800			; wait 30 seconds

	GetResourceHandleNS	DialSummons, dx ; bx - handle of dialog box
	mov	si, offset TimedOut		
	GetResourceSegmentNS	TimedOut, es	
	mov	bx, es				; bx:si - notification routine
	call	TimerStart			; start the timer
	mov	ds:[timerID], ax
	mov	ds:[timerHandle], bx		; save the handle and ID
	clc					; return with no error
exit:
	ret
DialTheNumber	endp


if DBCS_PCGEOS

COMMENT &%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DialPhoneNoGeosToDos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create MemBlock that contains PhoneNO in ASCII

CALLED BY:	(INTERNAL) DialTheNumber (only called in DBCS version)

PASS:		ds - seg addr of memblk which has phone # in unicode
		cx - string size (number of bytes in the block)

RETURN:		ds - seg addr of memblk which has phone # in ascii
		bx - mem handle of memblk which has phone # in ascii

DESTROYED:	ax

KNOWN BUGS/SIDE EFFECTS/IDEAS:

STRATEGY/OUTLINE:
	Since phone # that modems accept should be ASCII all over the world,
	we trim the high byte.  This code blindly send down chars, since
	the user may have embeeded modem commands in them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	owa	12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&
DialPhoneNoGeosToDos	proc	near
	uses	es, si, di
	.enter

	; create a new memory block
SBCS<	push	cx			; return SBCS string size	>
	mov	ax, cx			; ax - size of mem block
	shr	ax			; ax - phone number string length
DBCS<	push	ax			; return SBCS string size	>
	push	ax			; save # for later use
	inc	ax			; ax - size of new mem block
	inc	ax			; ax - size of new mem block

	mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or 0  ; HeapAllocFlags
	call	MemAlloc		; allocate a block
	mov	es, ax

	; copy only low byte to new block
	clr	si, di			; ds:si <- src
					; es:di <- dest
	pop	cx			; # of chars to copy
copyLoop:
	lodsw				; Get a Unicode char
	stosb				;  .. store an ASCII char
	loop	copyLoop
	mov	{char} es:[di], 0	; single byte null terminate

	segmov	ds, es, ax		; ds - seg addr fo new blk
	pop	cx			; return SBCS string size.
	.leave
	ret

DialPhoneNoGeosToDos	endp

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPhoneNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the phone number to display on the phone dial dialog box.

CALLED BY:	DialTheNumber

PASS:		ds - dgroup

RETURN:		phoneNoBlk - seg addr of mem block that contains phone number
		phoneOffset - offset into the mem block 

DESTROYED:	ax, bx, cx, dx, si, di, bp, es 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Under DBCS, the phone number returned is DBCS.  Other code
		converts it to SBCS for transmission to the serial port.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPhoneNumber	proc	far
	mov	ax, STANDARD_MEM_BLOCK_SIZE	; ax - size of mem block
	mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or 0   ; HeapAllocFlags
	call	MemAlloc		; allocate a block
	mov	ds:[phoneNoBlk], ax	; save seg addr of this data block
	mov	ds:[phoneHandle], bx	; save handle of this data block
	clr	ds:[phoneOffset]	; offset to phone number block

	mov	bx, ds:fieldHandles[TEFO_PHONE_NO]  ; bx - handle of phone # block 
	call	MemLock				; lock this data block
	call	GetAreaCode			; grab the area code to display
						; ds:si - phone #
	mov	bp, ds				; bp - seg addr of phone # blk

	;  Plow thru phone number looking for an "E" or "X"; these chars
	;  start an extension.
	;
	push	si				; save phone # ptr
	GetResourceHandleNS	ExtensionString, bx
	call	MemLock				; lock the block
	mov	es, ax				; set up the segment
	mov	di, offset ExtensionString	; handle of error messages 
	mov	di, es:[di]			; dereference the handle
miniLoop:
if DBCS_PCGEOS
	lodsw
	cmp	ax, {word} es:[di]		; check for 'E'
	je	extension
	cmp	ax, {word} es:[di+2]		; check for 'e'
	je	extension
	cmp	ax, {word} es:[di+4]		; check for 'X'
	je	extension
	cmp	ax, {word} es:[di+6]		; check for 'x'
	je	extension
	tst	ax
	jne	miniLoop	
else
	mov	al, ds:[si]
	inc	si
	cmp	al, es:[di]			; check for 'E'
	je	extension
	cmp	al, es:[di+1]			; check for 'e'
	je	extension
	cmp	al, es:[di+2]			; check for 'X'
	je	extension
	cmp	al, es:[di+3]			; check for 'x'
	je	extension
	tst	al
	jne	miniLoop	
endif
extension:
	GetResourceHandleNS	ExtensionString, bx
	call	MemUnlock			; unlock the block

	mov	cx, si
	pop	di				; copy phone number ptr
	push	di

	sub	cx, di				; cx - number of bytes to copy
	LocalPrevChar	dssi			; si - disregard the null term.
SBCS<	mov	{char} ds:[si], C_CR		;add carriage return at the end	>
DBCS<	mov	{wchar} ds:[si], C_CR		;add carriage return at the end	>
	pop	si				; ds:si - ptr to string to write

	GetResourceSegmentNS	dgroup, es	; es - seg address of dgroup
	mov	ax, es:[phoneNoBlk]		; ax - seg addr of phone block
	mov	di, es:[phoneOffset]
	push	es
	mov	es, ax				; es:di - destination block
	rep	movsb				; copy the string
	pop	ds
	mov	ds:[phoneOffset], di		; update the offset
	ret
GetPhoneNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAreaCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a little bit of error checking for the area code.

CALLED BY:	GetPhoneNumber

PASS:		ax - seg addr of mem block with phone number

RETURN:		ds:si - pointer to the phone number with new area code

DESTROYED:	ax, bx, cx, dx, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Assumes that all area codes are placed within '()'
	Assumes that all international phone numbers start with '+'
	Assumes that the phone number string is null terminated.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAreaCode	proc	near		
	uses	es
	.enter

	mov	ds, ax				; ds - seg addr of data block
	push	ds
	clr	si				; ds:si - phone number string
loop1:
	LocalGetChar	ax, dssi		; get a character
	LocalIsNull	ax			; is string end?
	jz	assumed				; get the assumed area code

	call	CheckForNumber			; is it a number?
	jnc	assumed				; if so, no area code	
	LocalCmpChar	ax, '+'			; international phone number?

	LONG	je	done			; if so, just exit
	LocalCmpChar	ax, '('			; phone number w/ area code?

	jne	loop1				; if not, skip
	push	si				; si - beg of area code number
loop2:
	LocalGetChar	ax, dssi		; get a charater
	LocalIsNull	ax			; is string end?

	jz	endString
	LocalCmpChar	ax, ')'			; end of area code?

	jne	loop2				; if not, continue
endString:
	mov	cx, si				; cx - end of area code number
	pop	si
	sub	cx, si				; cx - # of bytes in area code
	LocalPrevChar	dscx

	; read in the area code from the phone option dialog box 

	push	cx, si
	GetResourceHandleNS	CurrentAreaCodeField, bx
	mov	si, offset CurrentAreaCodeField	; bx:di - OD of area code field
	call	GetTextInMemBlockNoFixup	; read in text string 

	tst	cx				; is there any text?
	pop	cx, si				; restore size, start
	je	done				; if not, exit (length = 0)

	mov	bx, ax 				; bx - handle of text block
	call	MemLock				; lock this data block
	mov	es, ax				; es - seg addr of data block
	clr	di				; es:di - ptr to string
DBCS<	shr	cx, 1				; # chars to compare	>
	call	LocalCmpStringsNoSpaceCase	; do area codes match?
	je	free				; if so, just exit

	; Area code is different than current.  We need to dial the
	; the area code in this case.  Prepend the prefix from the
	; phone option dialog box.

	clr	si				; ds:si - ptr to current AC
	call	MemFree				; delete the data block
	GetResourceHandleNS	PrefixField, bx
	mov	si, offset PrefixField		; bx:di - OD of prefix field
	call	GetTextInMemBlockNoFixup	; read in text string 
	tst	cx				; no text in text field?
	je	done				; if none, exit
	call	AddOtherNumbers			; otherwise, add to phone blk
	jmp	done
free:
DBCS<	shl	cx, 1				; cx - string size 	>
	add	si, cx				; point past area code.
	LocalNextChar	dssi			; move pointer past ')'

	call	MemFree				; free the Cur area code block
	jmp	exit

assumed:
	; read in the assumed area code from the phone option dialog box 

	GetResourceHandleNS	AssumedAreaCodeField, bx
	mov	si, offset AssumedAreaCodeField	; bx:si - OD of area code field
	call	GetTextInMemBlockNoFixup	; read in text string 
	tst	cx				; is there any text?
	je	done				; if not, exit

	call	CheckIfAssumedSameAsCurrent	; Assumed == Current?
	jz	done				; If same, then done

	; read in the prefix from the phone option dialog box 

	push	ax, cx				; save block, length
	GetResourceHandleNS	PrefixField, bx
	mov	si, offset PrefixField		; bx:di - OD of prefix field
	call	GetTextInMemBlockNoFixup	; read in text string 
	tst	cx				; is there any text?
	je	skip				; if not, exit
	call	AddOtherNumbers			; otherwise, add it to phone blk
skip:
	pop	ax, cx
	call	AddOtherNumbers			; add the string to phone block
done:
	clr	si
exit:
	pop	ds
	.leave

	ret
GetAreaCode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfAssumedSameAsCurrent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if Assumed Area Code and Current Area Code are
		the same.

CALLED BY:	GetAreaCode()

PASS:		ax - handle to memory block containing Assumed text

RETURN:		flags - same as LocalCmpStrings()

DESTROYED:	bx, dx, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
		Lock the passed block
		Get Current Area Code text into mem block
		Lock the Current block
		Do the compare

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	7/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfAssumedSameAsCurrent	proc	near
	uses	ax,cx,si,ds
	.enter

	mov	dx, ax				; save block handle
	mov	bx, ax				; bx - block handle
	call	MemLock				; lock Assumed text block
	mov	ds, ax				; seg of locked block

	GetResourceHandleNS	CurrentAreaCodeField, bx
	mov	si, offset CurrentAreaCodeField	; bx:di - OD of area code field
	call	GetTextInMemBlockNoFixup	; read in text string 
	mov	bx, ax				; bx - block handle
	call	MemLock				; lock Current text block
	mov	es, ax				; seg of locked block

	clr	si, di				; beginning of strings

	call	LocalCmpStrings			; compare the strings

	pushf					; save flags
	call	MemFree				; free Current block
	mov	bx, dx				; handle of first block
	call	MemUnlock			; unlock Assumed block
	popf					; return flags

	.leave
	ret
CheckIfAssumedSameAsCurrent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a given character is a numeric char or not

CALLED BY:	GetAreaCode

PASS:		al - character to check

RETURN:		carry set if not a numeric character
		carry clear if it is a numeric character

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForNumber	proc	near
	
	LocalCmpChar	ax, '0'
	jb	notNumber

	LocalCmpChar	ax, '9'
	ja	notNumber

	clc			; a numeric character
	jmp	exit
notNumber:
	stc			; not a numeric character
exit:
	ret
CheckForNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddOtherNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the string returned in a memory block by 
		MSG_VIS_TEXT_GET_TEXT_RANGE to phone number block.

CALLED BY:	GetAreaCode

PASS:		ax - handle of mem block returned by 
			MSG_VIS_TEXT_GET_TEXT_RANGE
		cx - string length
		es - dgroup

RETURN:		phoneOffset - updated

DESTROYED:	ax, bx, cx, si, di, ds

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddOtherNumbers	proc	near
	mov	bx, ax 				; bx - handle of text block
	push	bx
	call	MemLock				; lock this data block
	mov	ds, ax				; ds - seg addr of data block
	clr	si				; ds:si - source string

	GetResourceSegmentNS	dgroup, es	; es - seg address of dgroup
	mov	ax, es:[phoneNoBlk]		; ax - seg addr of phone block
	mov	di, es:[phoneOffset]
	push	es
	mov	es, ax				; es:di - destination block
	LocalCopyNString			; copy the string

	pop	es
	mov	es:[phoneOffset], di		; update the offset
	pop	bx				; bx - handle of text block
	call	MemFree				; free this data block
	ret
AddOtherNumbers	endp	

if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the response from modem is OK or not.

CALLED BY:	DialUp

PASS:		inputBuffer - contains the response

RETURN:		zero flag set if OK was the response

DESTROYED:	cx, si, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	1/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForOK	proc	near
	mov	si, offset inputBuffer		; si - offset into inputBuffer 

	; do not skip anything, just check for OK
loop1:
	cmp	si, ds:[offsetInput]		; end of input buffer?
	je	exitError			; if so, exit with error
	LocalCmpChar	ds:[si], 'O'		; is it an 'O'?
	je	match				; if so, exit the loop
noMatch:
	inc	si				; if not, check the next char
	jmp	loop1
match:
	inc	si				; si - points to response 
	LocalCmpChar	ds:[si], 'K'		; is it an 'K'?
	jne	noMatch	
exit:
	ret
exitError:
	mov	cx, 1
	tst	cx				; clear the zero flag
	jmp	short	exit
CheckForOK	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndPhoneCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminate the phone call.

CALLED BY:	UI (= MSG_ROLODEX_END_CALL )

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di, es 

PSEUDO CODE/STRATEGY:
	Switch the modem back to command mode
	Hang up the phone
	Reset the modem

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EndPhoneCall	proc	far
	
	class	RolodexClass

	; stop timer if there was one

	mov	ax, ds:[timerID]
	mov	bx, ds:[timerHandle]
	call	TimerStop			

	; send '+++' to the modem

	mov	ds:[offsetInput], offset inputBuffer
						; init. offset into inputBuf
	mov	si, offset escapeCommand	; ds:si - "+++"
	mov	cx, 3				; cx - # of bytes to write
	mov	bx, ds:[serialPort]		; bx - serial port to write to
	mov	ax, STREAM_BLOCK
	CallSer	DR_STREAM_WRITE			; switch to command mode
	jc	exit

	; wait two seconds for the modem to respond

	mov	ax, 120				; really should be programmable.
	call	TimerSleep			

	; send hang up command to the modem

	mov	ds:[offsetInput], offset inputBuffer
						; init. offset into inputBuf
	mov	si, offset hangupCommand	; ds:si - "ATH0"
	mov	cx, 4				; cx - # of bytes to write to
	mov	bx, ds:[serialPort]		; bx - serial port to write to
	mov	ax, STREAM_BLOCK
	CallSer	DR_STREAM_WRITE			; hang up the phone
	jc	exit				; exit if error

	; wait one second for the modem to respond

	mov	ax, 60				
	call	TimerSleep			

	; DON'T CHECK FOR OK - ted 2/21/93
	;cmp	ds:[inputBuffer], '0'		; is it 'OK'?
	;jne	error				; if not, exit

	; reset the modem

	mov	ds:[offsetInput], offset inputBuffer
						; init. offset into inputBuf
	mov	si, offset resetCommand		; ds:si - string to write
	mov	cx, 4				; ax - # of bytes to write
	mov	bx, ds:[serialPort]		; bx - serial port to write to
	mov	ax, STREAM_BLOCK
	CallSer	DR_STREAM_WRITE			; reset the modem
	jc	exit				; exit if error

	; wait three seconds for the modem to respond

	; DON'T CHECK FOR OK - ted 2/21/93
	;mov	ax, 180				
	;call	TimerSleep			
	;call	CheckForOK			; is it 'OK'?
	;jne	error				; if not, exit

exit:
	call	CloseComPort			; close the com port
	ret
EndPhoneCall	endp

Modem	ends
