COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Main
FILE:		mainLocal.asm

AUTHOR:		Dennis Chow, November 3, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      11/03/89        Initial revision.

DESCRIPTION:
	Internally callable routines for this module.

	$Id: mainLocal.asm,v 1.2 98/03/11 21:22:31 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitTerm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize structures and varaibles related to terminal types

CALLED BY:	TermAttach

PASS:		ds	- dgroup data	
		es	- dgroup

RETURN:		carry set if couldn't start serial thread

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/08/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitTerm	proc	near
	mov	al, TRUE
	mov	ds:[useChecksum], al		;default to use checksum
	mov	ds:[toneDial], al		;default to use tone dial

	mov	al, FALSE
	mov	ds:[halfDuplex], al		;default to use full duplex
	mov	ds:[systemErr], al		;reset error flag

if _TELNET
	mov	ds:[recvProtocol], NONE
	mov	ds:[sendProtocol], NONE
else
	mov	ds:[recvProtocol], XMODEM	;default file transfers to 
	mov	ds:[sendProtocol], XMODEM	;	xmodem protocl	
endif
	mov	ds:[modemSpeaker], MODEM_SPEAKER_CARRIER
	mov	ds:[modemVolume], MODEM_VOLUME_MED
	mov	ds:[termOptions], mask LAW_WRAP

if	not _TELNET
	mov	ds:[dataBits], (SL_8BITS shl offset SF_LENGTH) or \
				(mask SF_LENGTH shl 8)
	mov	ds:[parity], (SP_NONE shl offset SF_PARITY) or \
				(mask SF_PARITY shl 8) 
	mov	ds:[stopBits], SBO_ONE
	mov	ds:[handshake], mask SFC_SOFTWARE
	mov	ds:[stopRemote], mask SMC_RTS
	mov	ds:[stopLocal], mask SMS_CTS 


	CallMod	InitComUse			;get serial driver info
	jc	exit				; if error starting serial
						;	thread, exit now
endif	; !_TELNET

	call	SetScreenInput			;send input to screen
	mov	ds:[termHandle], DEF_HANDLE	;handle for default buffer
	mov	ds:[termTable.TTS_numEntries],0	;initialize terminal table
	mov	ds:[termTable.TTS_maxEntries],5

if	not _TELNET
	mov     ds:[serialPort], NO_PORT        ;default to no port
endif


	mov	cx, SP_PUBLIC_DATA		;go to macro directory
	push	ds
	segmov	ds, cs
	mov	dx, offset geoCommDir
	call	GotoTermDir			; (CallMod)
	pop	ds
	mov	si, offset pathnameBuf		;ds:si->pathname buffer
	mov	cx, size pathnameBuf
	call	FileGetCurrentPath
	mov	ds:[diskHandle], bx		;save disk handle
	tst	ds:[restoreFromState]		; restore from state file?
	jnz	afterMacroPath			; yes, leave path alone
	mov	bp, bx				;pass disk handle
	mov	ax, MSG_GEN_PATH_SET
	mov	cx, ds				;set file selector path
	mov	dx, si				;cx:dx ->pathname
	GetResourceHandleNS	MacroFiles, bx
	mov	si, offset MacroFiles		;
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
afterMacroPath:
						;initialize send file selector
	mov	dx, ds:[interfaceHandle]
	mov	si, offset ChatText
	call	SelectAllText			; (CallMod)

if	not _TELNET
NRSP <	call	TermSerialReset			; reset line status counters>
endif

	mov	cx, ds:[termProcHandle]		;geoComm want's to be notified
	clr	dx				;  if items get added to the
	call	ClipboardAddToNotificationList		;  clipboard.
RSP <	call	TermSetConnectionCancelDest	; set the connection cancel>
						; trigger's destination
	clc					; indicate success

exit:
	ret
InitTerm	endp

SBCS <geoCommDir	byte	"COMMACRO", 0		;GEOCOMM sub directory>
DBCS <geoCommDir	wchar	"COMMACRO", 0		;GEOCOMM sub directory>

InitHandleVars	proc	near

if	not _TELNET
	clr	ds:[threadHandle]		;
endif

	call	GeodeGetProcessHandle		;get geode process handle
	mov	ds:[termProcHandle], 	bx

	GetResourceHandleNS Interface, 	ax	;get interface resource handle
	mov	ds:[interfaceHandle], 	ax
	GetResourceHandleNS InterfaceAppl, ax	;get interfaceAppl handle
	mov	ds:[applUIHandle], 	ax
	GetResourceHandleNS TransferUI,	ax	;get file transfer resource 
	mov	ds:[transferUIHandle], 	ax				
	GetResourceHandleNS Strings, 	ax	;get string resource handle
	mov	ds:[stringsHandle], 	ax
	GetResourceHandleNS TermUI, 	ax	;get TermUI resource handle
	mov	ds:[termuiHandle], 	ax

	GetResourceHandleNS 	FSM, 	ax
	mov	ds:[fsmResHandle], 	ax
	GetResourceHandleNS 	File, 	ax
	mov	ds:[fileResHandle], 	ax
	GetResourceHandleNS 	Main,	ax
	mov	ds:[mainResHandle], 	ax

	ret
InitHandleVars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateTermTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add current FSM to the table

CALLED BY:	ProcessTermcap

PASS:		es:[termType]		- terminal to add
		es:[fsmBlockSeg]	- fsm values to add
		es:[fsmBlockHandle	-

RETURN:		
		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateTermTable	proc	near
	mov	bp, offset dgroup:termTable	
	mov	cl, es:[bp].TTS_numEntries	;
	cmp	cl, MAX_TERM_ENTRIES		;is table full ?
	jl	UTT_addTerm			;nope, add the new FSM
	call	ShiftTermEntries		;yep, make room first
UTT_addTerm:
	mov	ax, TERM_TABLE_ENTRY_SIZE	;calculate place in table
	mul	cl				;to store fsm segment
	add	ax, TERM_TABLE_HEADER_SIZE
	add	bp, ax				;es:[bp]->place to store token
	mov	cl, es:[termType]
	mov	es:[bp].TTE_termType, cl 	;store terminal type
	mov	cx, es:[fsmBlockSeg]
	mov	es:[bp].TTE_termSeg, cx 	;store terminal fsm segment
	mov	cx, es:[fsmBlockHandle]
	mov	es:[bp].TTE_termHandle, cx 	;store terminal fsm handle
	inc	es:[termTable.TTS_numEntries]	;increment terminal count
CTT_ret:
	ret	
UpdateTermTable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShiftTermEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make room in the term table  

CALLED BY:	CheckTermTable

PASS:		ds:[termTable]	- table to make room in
		ds:[bp]		- pts to start of term Table
		es, ds		- dgroup

RETURN:		cl		- #entris in table	
	
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Shift all the terminal entries up one
		decrement terminal count

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/08/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShiftTermEntries	proc	near
	mov	di, offset dgroup:termTable.TTS_terminals
	mov	si, di				;ds:[di]->top of term list
	add	si, TERM_TABLE_ENTRY_SIZE	;es:[si]->2nd entry in list
						;pass #bytes to shift
	mov	cx, (MAX_TERM_ENTRIES - 1) * TERM_TABLE_ENTRY_SIZE
	rep	movsb
	dec	ds:[termTable.TTS_numEntries]	;decrement terminal count	
	mov	cl, ds:[termTable.TTS_numEntries]
	ret
ShiftTermEntries	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchTermTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if term type already in the table

CALLED BY:	CheckTermTable, UpdateTermTable

PASS:		ds:[termTable]	- table to make room in

RETURN:		C	- clear if term type not in table
			- set if term type in table
		ds:[fsmBlockSeg]	- block segment of FSM to use
		ds:[fsmBlockHandle]	- block handle of FSM
	
DESTROYED:	bp, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SearchTermTable	proc	near
	mov	dh, ds:[termType]		;get term type to check for
	mov	dl, ds:[termTable.TTS_numEntries]	;get #of entries
	tst	dl				;if empty table 
	jz	STT_notFound
STT_search:
	mov	bp, offset dgroup:termTable	;point to term table struct
	add	bp, TERM_TABLE_HEADER_SIZE	;  and offset to terminal part
	clr	ch
	mov	cl, dl				;get #of entries 	
STT_loop:	
	cmp	ds:[bp], dh			;does term type match
	je	STT_found
	add	bp, TERM_TABLE_ENTRY_SIZE
	loop	STT_loop
STT_notFound:
	clc
	jmp	short 99$
STT_found:
	mov	ax, ds:[bp].TTE_termSeg		;get fsm segment to use
	mov	bx, ds:[bp].TTE_termHandle
	mov	ds:[fsmBlockSeg], ax		;update current FSM segment
	mov	ds:[fsmBlockHandle], bx		;update current FSM handle
	stc
99$:
	ret
SearchTermTable	endp

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncReadErr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the number of read errors
	
CALLED BY:	TermStreamErr, TermResetVar

PASS:		

RETURN:		

DESTROYED:	ax, bx, dx, si, bp, di	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayReadErr	proc	near
	clr	dh					;
	mov	dl, ds:[numReadErr]			;pass value to display
	GetResourceHandleNS	ReadErr, bp	; bp:si = counter
	mov	si, offset ReadErr
	mov	di, offset dgroup:readErrBuf
	CallMod	UpdateDisplayCounter
	ret
DisplayReadErr	endp

DisplayWriteErr	proc	near
	clr	dh
	mov	dl, ds:[numWriteErr]			;pass value to display
	GetResourceHandleNS	WriteErr, bp	; bp:si = counter
	mov	si, offset WriteErr
	mov	di, offset dgroup:writeErrBuf
	CallMod	UpdateDisplayCounter
	ret
DisplayWriteErr	endp

DisplayFrameErr	proc	near
	clr	dh
	mov	dl, ds:[numFrameErr]			;pass value to display
	GetResourceHandleNS	FrameErr, bp	; bp:si = counter
	mov	si, offset FrameErr
	mov	di, offset dgroup:frameErrBuf
	CallMod	UpdateDisplayCounter
	ret
DisplayFrameErr	endp

DisplayParityErr	proc	near
	clr	dh					;pass value to display
	mov	dl, ds:[numParityErr]	
	GetResourceHandleNS	ParityErr, bp	; bp:si = counter
	mov	si, offset ParityErr
	mov	di, offset dgroup:parityErrBuf
	CallMod	UpdateDisplayCounter
	ret
DisplayParityErr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendModemCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send command string to the modem
	
CALLED BY:	TermVol[Low, Med, Hi], TermSpeaker[On, Off, Dial, Carrier]

PASS:		cs:si	- string to send
		cx	- length of string

RETURN:		C	- set if couldn't send the modem command	
			  clear if ok	

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Could save bytes by trying to construct the modem command.		
	Most of the commands are prefixed by "AT" and ended with a CR.
	Instead of passing the complete string, could just pass the
	relevant command chars and we could prepend the AT and append
	the CR.  Could save three bytes for every command.  A total of
	twenty bytes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendModemCommand	proc	near
	segmov	es, cs, ax
	CallMod	SendBuffer
	ret
SendModemCommand	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunScriptFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do tasks associated with running a script file
	
CALLED BY:	TermMacroOpen, TermMacroSelect

PASS:		cx:dx	- filename of macro file to run

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RunScriptFile	proc	near
	GetResourceHandleNS	ScriptDisplay, bx	; bx:bp = display
	mov	bp, offset ScriptDisplay
	call	ScriptRunFile	
	ret
RunScriptFile	endp
endif	; !_TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check state of UI objects
	
CALLED BY:	

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
	Check the following items		
		Com port
		baud rate
		data bits
		parity
		stop bits
		flow control
		term type
		duplex

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	04/24/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetListExcl	proc	near	
					;check if any com ports are
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	cx, ax			;cx = selection
					;carry set if no selection
	ret
GetListExcl	endp

RestoreState	proc	near
	call	InitFileSelectPath
	
if	not _TELNET
NRSP <	call	RestoreTonePulse					>
endif	; !_TELNET
	
	call	RestoreTermType		;
NRSP <	call	RestoreDuplex		;				>
	
if	not _TELNET
	call	RestoreComPort		;if opening a com port then
	jcxz	exit			;	
endif	; !_TELNET
	
	call	EnablePortStuff		;  enable geoComm port stuff
	
if	not _TELNET
	call	RestoreBaudRate		;if baud rate not set
	jcxz	exit			;then
NRSP <	call	RestoreDataFormat	; 	skip remaining serial	>
NRSP <	call	RestoreFlowControl	;	options			>

	; need to do restore some more modem related settings
	; - ted 1/19/93

	call    RestoreModemSpeaker
	call    RestoreModemVolume
endif	; !_TELNET
	
	call	RestoreTermOptions
	
if	not _TELNET
NRSP <	call	RestoreDataBits						>
NRSP <	call	RestoreParity						>
NRSP <	call	RestoreStopBits						>
	call	RestoreHandshake
	call	RestoreStopRemote
	call	RestoreStopLocal
	
	; if software flow control is enabled then send an XON
	; when we open the port.  Just in case an XOFF was sent
	; by another port some time.
	;
	; need to do now because baud rate, etc. is needed to send stuff
	; out the line - brianc 8/21/90
	;
	test    ds:[serialFlowCtrl], mask SFC_SOFTWARE
	jz      exit
	mov     bx, ds:[serialPort]             ;set  port #
	mov     cl,  CHAR_XON			;send an xoff
	mov     ax, STREAM_BLOCK
	CallSer DR_STREAM_WRITE_BYTE
endif	; !_TELNET
		
exit:
	ret
RestoreState	endp

if	not _TELNET
RestoreModemSpeaker	proc	near
	GetResourceHandleNS	ModemSpeaker, bx
	mov	si, offset ModemSpeaker		;
	mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov     di, mask MF_CALL
	call    ObjMessage
	mov	ds:[modemSpeaker], ax
	ret
RestoreModemSpeaker	endp

RestoreModemVolume	proc	near
	GetResourceHandleNS	ModemVolume, bx
	mov	si, offset ModemVolume		;
	mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov     di, mask MF_CALL
	call    ObjMessage
	mov	ds:[modemVolume], ax
	ret
RestoreModemVolume	endp
endif	; !_TELNET

RestoreTermOptions	proc	near
	GetResourceHandleNS	VideoList, bx
	mov	si, offset VideoList		;
	mov     ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage              ; ax = selected booleans
	mov	ds:[termOptions], ax
	ret
RestoreTermOptions	endp

if	not _TELNET
RestoreDataBits		proc	near
	GetResourceHandleNS	DataList, bx
	mov	si, offset DataList		;
	mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov     di, mask MF_CALL
	call    ObjMessage
	mov	ds:[dataBits], ax
	ret
RestoreDataBits		endp

RestoreParity		proc	near
	GetResourceHandleNS	ParityList, bx
	mov	si, offset ParityList		;
	mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov     di, mask MF_CALL
	call    ObjMessage
	mov	ds:[parity], ax
	ret
RestoreParity	endp

RestoreStopBits		proc	near
	GetResourceHandleNS	StopList, bx
	mov	si, offset StopList		;
	mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov     di, mask MF_CALL
	call    ObjMessage
	mov	ds:[stopBits], ax
	ret
RestoreStopBits		endp

RestoreHandshake	proc	near
	GetResourceHandleNS	FlowList, bx
	mov	si, offset FlowList		;
	mov     ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage              ; ax = selected booleans
	mov	ds:[handshake], ax
	ret
RestoreHandshake	endp

RestoreStopRemote	proc	near
	GetResourceHandleNS	StopRemoteList, bx
	mov	si, offset StopRemoteList		;
	mov     ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage              ; ax = selected booleans
	mov	ds:[stopRemote], ax
	ret
RestoreStopRemote	endp

RestoreStopLocal	proc	near
	GetResourceHandleNS	StopLocalList, bx
	mov	si, offset StopLocalList		;
	mov     ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage              ; ax = selected booleans
	mov	ds:[stopLocal], ax
	ret
RestoreStopLocal	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreComPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restore the state of the com port
	
CALLED BY:	

PASS:		ds	- dgroup

RETURN:		cx	- 0 	if no com port opened 

DESTROYED:	

PSEUDO CODE/STRATEGY:
	if the state file has com port set
		then open that port
	else if geos.ini file has a default setting for com port
		then open that port
	else 
		bring up the com port box


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	04/24/90	Initial version
	eric	08/19/96	Added in dove modifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
modemStr	db	"modem",0
modemKeyStr	db	"modems",0
portStr		db	"port",0
baudStr		db	"baudRate",0

RestoreComPort	proc	near
	GetResourceHandleNS	ComList, bx				
	mov	si, offset ComList		;			
	call	GetListExcl			;			
	jc	noComSet			;			

	tst	ds:[termLazarusing]		; if in Lazarus state, pretend
	jz	openCom				;  we are starting normally
noComSet:
	call	FetchModemFromIni
	jc	noModem
	mov	si, di				;ds:si category string
	mov	cx, cs
	mov	dx, offset portStr
SBCS <	mov	bp, DISP_BUF_SIZE 		;pass size of buffer	>
DBCS <	mov	bp, DISP_BUF_SIZE*(size wchar)				>
	mov	di, offset frameErrBuf		;es:di->buffer to put entry in
	call	InitFileReadString		;okay look for 'port' value
	jc	noModem				;exit if none found

						;okay we'll assume here that
						;the buffer contains COM[1234]
						;so we'll just offset to the
						;number part
if DBCS_PCGEOS
	add	di, 6
	mov	ax, es:[di]
	sub	ax, '0'
else
	add	di, 3				
	mov	al, es:[di]
	sub	al, '0'	
	clr	ah		
endif
	dec	ax				;adjust com numbers (com1 = 0)
	mov	cx, ax				;convert com port # to
	shl	cx, 1				;  serial constant
	cmp	cx,SERIAL_COM4			;check that com port is legal
;
; if we find an invalid com port, we should put up the protocol box
;- brianc 2/7/94
;
if 0
	jbe	setList

	clr	cx
	jmp	short exit
else
	ja	noModem
endif
setList:
	push	cx				;save serial port
	CallMod	SetPortList			;set port list entry
	pop	cx				;  and open the port
	jmp	short openPort			;	
openCom:					;
	dec	cx				;convert to serial port
openPort:
	call	OpenPort			;list entry already set just
	jmp	short exit			;	open the port.
noModem:

	GetResourceHandleNS	ProtocolBox, bx	;			
	mov	si, offset ProtocolBox		;			
	mov     ax, MSG_GEN_INTERACTION_INITIATE			
	mov     di, mask MF_CALL					
	call    ObjMessage					
	
	clr	cx				;flag no baud rate set
exit:
	ret
RestoreComPort	endp

FetchModemFromIni	proc	near
	push	ds				
	segmov	ds, cs, si
	mov	si, offset modemStr		;ds:si ->categroy string
	mov	cx, cs				;
	mov	dx, offset modemKeyStr		;cx:dx ->key string
	mov	bp, MODEM_CAT_SIZE 		;pass size of buffer
	mov	di, offset modemNameBuf		;es:di ->buffer to put entry in
	call	InitFileReadString
	jc	done				; not found
	stc					; assume null buffer returned
	jcxz	done				; yes, not found
if DBCS_PCGEOS
	push	di
	;
	; convert DBCS to SBCS in-place
	inc	cx				; include null
	segmov	ds, es
	mov	si, offset modemNameBuf		; ds:si = DBCS string
	mov	di, si				; es:di = SBCS buffer
copyLoop:
	lodsw
EC <	tst	ah							>
EC <	ERROR_NZ	-1						>
	stosb
	loop	copyLoop
	pop	di
endif
	clc					; else, found
done:
	pop	ds				;restore ds to dgroup
	ret
FetchModemFromIni	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreBaud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	attempt to restore baud rate
	
CALLED BY:	

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
	if the state file has baud set
		then use set the serial driver to that baud rate 
	else if geos.ini file has a default setting for baud rate
		then use that baud by
		setting the list entry and having the list send out a 
			SET_BAUD method 
	else 
		bring up the com port box

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	04/24/90	Initial version

	eric	08/19/96	Added in dove modifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RateAndConst	struct
	RAC_rate	sword
	RAC_const	SerialBaud
RateAndConst	ends

BaudToConst	RateAndConst \
	<300, SB_300>,
	<600, SB_600>,
	<1200, SB_1200>,
	<2400, SB_2400>,
	<4800, SB_4800>,
	<9600, SB_9600>,
	<14400, SB_14400>,
	<19200, SB_19200>,
	<38400, SB_38400>,
	<57600, SB_57600>,
	<115200, SB_115200>

RestoreBaudRate	proc	near
	tst	ds:[restoreFromState]		; restore from state file?
	jz	noBaudSet			; nope, use geos.ini file
	GetResourceHandleNS	BaudList, bx
	mov	si, offset BaudList		;
	call	GetListExcl			;
	jc	noBaudSet			;
	jmp	setBaud
noBaudSet:
	push	ds			
	mov	si, offset modemNameBuf		;ds:si ->category string

SBCS <EC <	cmp	{char} ds:[si], 0		; null category string ?>>
DBCS <EC <	cmp	{wchar} ds:[si], 0		; null category string ?>>
EC <	ERROR_Z	TERM_ERROR_NO_MODEM_NAME				>

	mov	cx, cs				;
	mov	dx, offset baudStr		;cx:dx ->key string
	call	InitFileReadInteger		;
	pop	ds				;restore dgroup
	jc	noBaud				;
	clr	di				;check baud rate value
	mov	cx, length BaudToConst		;cx <- number of baud values
loop1:	
	cmp     ax, cs:BaudToConst[di].RAC_rate ; is there a match?
	je      found2                          ; if so, skip to handle it
	add     di, size RateAndConst		; if not,
	loop    loop1                           ; check the next entry
	jmp     noBaud		               	; if not in table, use default
found2:
	mov     cx, cs:BaudToConst[di].RAC_const ; we have a match
	jmp	setList
noBaud:	
	; NOTE: We will not have to worry about no default settings, as
	; there will be default settings (once NEC decides on them).

	GetResourceHandleNS	ProtocolBox, bx	;make the user select a baud
	mov	si, offset ProtocolBox		;
	mov     ax, MSG_GEN_INTERACTION_INITIATE
	mov     di, mask MF_CALL
	call    ObjMessage

	clr	cx				;flag no baud rate set
	jmp	short exit			;
setList:
	push	cx				;save baud rate
	CallMod	SetBaudList			;set the baud list entry
	pop	cx				;  and set the baud rate
setBaud:
	call	TermSetBaud			;set serial driver to this
exit:						;	baud rate
	ret
RestoreBaudRate	endp

RestoreDataFormat	proc	near
	tst	ds:[restoreFromState]		; restore from state?
	jz	useIniData			; nope, use .ini file
	GetResourceHandleNS	DataList, bx
	mov	si, offset DataList		;
	call	GetListExcl			; cx = data bits to set
	mov	ds:[dataBits], cx
	jnc	gotData				; have them
useIniData:
	call	UseIniDataSetting		; cx = data bits
gotData:
	mov	dx, cx				; dx = data bits
	tst	ds:[restoreFromState]		; restore from state?
	jz	useIniStop			; nope, use .ini file
	GetResourceHandleNS	StopList, bx
	mov	si, offset StopList		;
	push	dx				;save serial format
	call	GetListExcl			;cx = stop bits flags
	mov	ds:[stopBits], cx
	call	ConvertStopBitsFlags		;cx = stop bits to set
	pop	dx				;restore serial format
	jnc	gotStop
useIniStop:
	call	UseIniStopSetting		; cx = stop bits
gotStop:
	or	dx, cx				; dx = data/stop bits
	tst	ds:[restoreFromState]		; restore from state?
	jz	useIniParity			; nope, use .ini file
	GetResourceHandleNS	ParityList, bx
	mov	si, offset ParityList		;
	push	dx				;save serial format
	call	GetListExcl			;get parity to set
	mov	ds:[parity], cx
	pop	dx				;restore serial format
	jnc	gotParity
useIniParity:
	call	UseIniParitySetting		; cx = parity bits
gotParity:
	or	cx, dx				; cx = data/stop/parity bits
	CallMod	AdjustSerialFormat		;
	ret
RestoreDataFormat	endp

ConvertStopBitsFlags	proc	near
	uses	ax
	.enter
	cmp	cx, SBO_ONE
						; assume one stop bit
	mov	cx, (0 shl offset SF_EXTRA_STOP) or (mask SF_EXTRA_STOP shl 8)
	je	done
						; else, same for 1.5 and 2
	mov	cx, (1 shl offset SF_EXTRA_STOP) or (mask SF_EXTRA_STOP shl 8)
done:
	.leave
	ret
ConvertStopBitsFlags	endp

;----- start of new data format geos.ini routines


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UseIni{Data,Stop,Parity}Setting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	grab modem setting from geos.ini and set Protocol box
		list to reflect that setting

CALLED BY:	RestoreDataFormat

PASS:		ds - dgroup

RETURN:		cx - relevant bits of SerialFormat

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	08/27/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

dataStr	byte	"wordLength",0

UseIniDataSetting	proc	near
	uses	ax, bx, dx, si, di, bp, es
	.enter
	mov	si, offset modemNameBuf		; ds:si = category string
	mov	cx, cs
	mov	dx, offset dataStr		; cx:dx = key string
	call	InitFileReadInteger		; ax = word length
	jc	useDefaultData			; if not found, use default
	mov	cx, (SL_5BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8)
	cmp	ax, 5
	je	sendData
	mov	cx, (SL_6BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8)
	cmp	ax, 6
	je	sendData
	mov	cx, (SL_7BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8)
	cmp	ax, 7
	je	sendData
useDefaultData:
						; else, use 8 bits
	mov	cx, (SL_8BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8)
sendData:
	push	cx				; save for return
	GetResourceHandleNS	DataList, bx
	mov	si, offset DataList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjMessage
	pop	cx
	push	cx				; cx = SerialFormat flags
	call	TermAdjustUserFormat
	pop	cx				; return SerialFormat flags
	.leave
	ret
UseIniDataSetting	endp



stopStr	byte	"stopBits",0

UseIniStopSetting	proc	near
	uses	ax, bx, dx, si, di, bp, es
	.enter
	mov	si, offset modemNameBuf		; ds:si = category string
	mov	cx, cs
	mov	dx, offset stopStr		; cx:dx = key string
	mov	bp, INITFILE_INTACT_CHARS or 0	; return buffer
	call	InitFileReadString		; bx = buffer
						; cx = length
	jc	useDefaultStop
	call	MemLock
	mov	es, ax
	mov	si, SBO_ONEANDHALF
	clr	di
	mov	al, '.'
	push	cx
SBCS <	repne scasb							>
DBCS <	repne scasw							>
	pop	cx
	je	freeBufAndSendStop		; 1.5
	mov	si, SBO_TWO
	clr	di
	mov	al, '2'
SBCS <	repne scasb							>
DBCS <	repne scasw							>
	je	freeBufAndSendStop		; 2
	call	MemFree				; free .ini string buffer
useDefaultStop:
						; else, use 1 stop bit
	mov	si, SBO_ONE
	jmp	short sendStop

freeBufAndSendStop:
	call	MemFree
sendStop:
	push	si				; save for return
	mov	cx, si				; pass to SET_EXCL
	GetResourceHandleNS	StopList, bx
	mov	si, offset StopList
	clr	dx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessage
	pop	cx
	call	ConvertStopBitsFlags		; return SerialFormat flags (cx)
	.leave
	ret
UseIniStopSetting	endp



parityStr	byte	"parity",0

UseIniParitySetting	proc	near
	uses	ax, bx, dx, si, di, bp, es
	.enter
	mov	si, offset modemNameBuf		; ds:si = category string
	mov	cx, cs
	mov	dx, offset parityStr		; cx:dx = key string
	mov	bp, INITFILE_DOWNCASE_CHARS or 0	; return buffer lowered
	call	InitFileReadString		; bx = buffer
						; cx = length
	jc	useDefaultParity
	call	MemLock
	mov	es, ax

	mov	si, (SP_ODD shl offset SF_PARITY) or (mask SF_PARITY shl 8)
	clr	di
	LocalLoadChar	ax, 'd'
	push	cx
	LocalFindChar
	pop	cx
	je	freeBufAndSendParity		; odd

	mov	si, (SP_EVEN shl offset SF_PARITY) or (mask SF_PARITY shl 8)
	clr	di
	LocalLoadChar	ax, 'v'
	push	cx
	LocalFindChar
	pop	cx
	je	freeBufAndSendParity		; even

	mov	si, (SP_SPACE shl offset SF_PARITY) or (mask SF_PARITY shl 8)
	clr	di
	LocalLoadChar	ax, 's'
	push	cx
	LocalFindChar
	pop	cx
	je	freeBufAndSendParity		; space

	mov	si, (SP_MARK shl offset SF_PARITY) or (mask SF_PARITY shl 8)
	clr	di
	LocalLoadChar	ax, 'm'
	LocalFindChar
	je	freeBufAndSendParity		; mark

	call	MemFree				; free .ini string buffer
useDefaultParity:
						; else, use no parity
	mov	si, (SP_NONE shl offset SF_PARITY) or (mask SF_PARITY shl 8)
	jmp	short sendParity

freeBufAndSendParity:
	call	MemFree
sendParity:
	push	si				; save for return
	mov	cx, si				; pass to SET_EXCL
	GetResourceHandleNS	ParityList, bx
	mov	si, offset ParityList
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx				; return SerialFormat flags
	.leave
	ret
UseIniParitySetting	endp



flowStr	byte	"handshake",0

UseIniFlowSetting	proc	near
	uses	ax, bx, cx, si, di, bp, es
	.enter
	mov	si, offset modemNameBuf		; ds:si = category string
	mov	cx, cs
	mov	dx, offset flowStr		; cx:dx = key string
	mov	bp, INITFILE_DOWNCASE_CHARS or 0	; return buffer lowered
	call	InitFileReadString		; bx = buffer
						; cx = length
	mov	si, mask SFC_SOFTWARE		; assume default flow control
	jc	sendFlow			; yes, use default
	mov	si, 0				; start with no flow control
	call	MemLock
	mov	es, ax

	clr	di
	LocalLoadChar	ax, 'n'
	push	cx
	LocalFindChar
	pop	cx
	je	freeBufAndSendFlow		; none

	clr	di
	LocalLoadChar	ax, 'h'
	push	cx
	LocalFindChar
	pop	cx
	jne	noHardware			; no hardware
	ornf	si, mask SFC_HARDWARE		; else, set it
noHardware:
	clr	di
	LocalLoadChar	ax, 's'
	LocalFindChar
	jne	freeBufAndSendFlow		; no software
	ornf	si, mask SFC_SOFTWARE		; else, set it
	jmp	short freeBufAndSendFlow

freeBufAndSendFlow:
	call	MemFree
sendFlow:
	push	si				; save for return
	xchg	ax, si				; (1-byte inst.)
	tst	ax
	jnz	notNone
	mov	cx, mask FFB_NONE
	call	SetFlowListState
	mov	cx, mask FFB_NONE
	mov	bp, mask FFB_NONE		; turned on "none"
	call	TermSetUserFlow			; update flow-dependent things
	jmp	short afterFlowNone

notNone:
	push	ax
	mov	cx, mask FFB_NONE
	mov	bp, mask FFB_NONE		; pretend to turn on "none"
	call	TermSetUserFlow			; disable both "h" and "s"
						; (will turn on as needed)
	pop	ax
	test	ax, mask SFC_SOFTWARE
	jz	notSoftware
	mov	cx, mask SFC_SOFTWARE
	call	SetFlowListState
	mov	cx, mask SFC_SOFTWARE
	push	ax
	mov	bp, mask SFC_SOFTWARE		; turn on software
	call	TermSetUserFlow			; update flow-dependent things
	pop	ax
notSoftware:
	test	ax, mask SFC_HARDWARE
	jz	notHardware
	mov	cx, mask SFC_HARDWARE
	call	SetFlowListState
	mov	cx, mask SFC_HARDWARE
	mov	bp, mask SFC_HARDWARE		; turn on hardware
	call	TermSetUserFlow			; update flow-dependent things
notHardware:
afterFlowNone:
	pop	dx				; return dx = flow settings
	.leave
	ret
UseIniFlowSetting	endp

SetFlowListState	proc	near
	push	ax, bp
	GetResourceHandleNS	FlowList, bx
	mov	si, offset FlowList
	mov	dx, -1				; turn on bit
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	call	ObjMessage
	pop	ax, bp
	ret
SetFlowListState	endp



stopRemoteStr	byte	"stopRemote",0
stopLocalStr	byte	"stopLocal",0

UseIniHardwareFlowSetting	proc	near
	uses	ax, bx, cx, dx, si, di, bp, es
	.enter
	call	ClearHardwareSettings
	mov	si, offset modemNameBuf		; ds:si = category string
	mov	cx, cs
	mov	dx, offset stopRemoteStr	; cx:dx = key string
	mov	bp, INITFILE_DOWNCASE_CHARS or 0	; return buffer lowered
	call	InitFileReadString		; bx = buffer
						; cx = length
	jc	useDefaultStopRemote
	call	MemLock
	push	bx
	mov	es, ax
	clr	di
	LocalLoadChar	ax, 'd'			; "dtr"
	push	cx
	LocalFindChar
	pop	cx
	mov	bp, 0				; flag no "dtr"
	jne	noDTR
	push	cx
	mov	cx, mask SMC_DTR
	call	SetStopRemoteListEntry
	pop	cx
	mov	bp, -1				; flag have "dtr"
noDTR:
	clr	di
	LocalLoadChar	ax, 's'			; "rts"
	push	cx
	LocalFindChar
	pop	cx
	pop	bx				; retrieve .ini string buffer
	pushf
	call	MemFree				; free it
	popf
	je	haveRTS
	tst	bp				; also no "dtr"?
	jnz	afterStopRemote			; no, had "dtr"
haveRTS:
useDefaultStopRemote:
	push	cx
	mov	cx, mask SMC_RTS
	call	SetStopRemoteListEntry
	pop	cx
	;
	; futz with stop-local
	;
afterStopRemote:
	mov	si, offset modemNameBuf		; ds:si = category string
	mov	cx, cs
	mov	dx, offset stopLocalStr		; cx:dx = key string
	mov	bp, INITFILE_DOWNCASE_CHARS or 0	; return buffer lowered
	call	InitFileReadString		; bx = buffer
						; cx = length
	jc	useDefaultStopLocal
	call	MemLock
	push	bx
	mov	es, ax
	clr	di
	LocalLoadChar	ax, 'r'			; "dsr"
	push	cx
	LocalFindChar
	pop	cx
	jne	noDSR
	push	cx
	mov	cx, mask SMS_DSR
	call	SetStopLocalListEntry
	pop	cx
noDSR:
	clr	di
	LocalLoadChar	ax, 'd'			; "dcd"
	LocalFindChar
	jne	noDCD
	cmp	{byte} es:[di], 'c'
	jne	noDCD
	push	cx
	mov	cx, mask SMS_DCD
	call	SetStopLocalListEntry
	pop	cx
noDCD:
	clr	di
	LocalLoadChar	ax, 't'			; "cts"
	push	cx
	LocalFindChar
	pop	cx
	pop	bx
	pushf
	call	MemFree
	popf
	jne	noCTS
useDefaultStopLocal:
	push	cx
	mov	cx, mask SMS_CTS
	call	SetStopLocalListEntry
	pop	cx
noCTS:
	.leave
	ret
UseIniHardwareFlowSetting	endp

SetStopLocalListEntry	proc	near
	push	ax, cx, bp
	GetResourceHandleNS	StopLocalList, bx
	mov	si, offset StopLocalList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	dx, -1			; select
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, cx, bp
	ret
SetStopLocalListEntry	endp

ClearHardwareSettings	proc	near
	GetResourceHandleNS	StopRemoteList, bx
	mov	si, offset StopRemoteList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	cx
	clr	dx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	GetResourceHandleNS	StopLocalList, bx
	mov	si, offset StopLocalList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	cx
	clr	dx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
ClearHardwareSettings	endp

;----- end of new data format geos.ini routines

RestoreFlowControl	proc	near		;
	tst	ds:[restoreFromState]		; restore from state?
	jz	useIniFlow			; nope, use .ini file
	call	GetFlowSettings			; dx = actual flow setting
	jmp	short gotFlow

useIniFlow:
	call	UseIniHardwareFlowSetting	; return nothing
						; (hardware flow settings used
						;  from SerialSetFlowControl)
	call	UseIniFlowSetting		; dx = flow setting
gotFlow:
	mov	cx, dx				; cx = flow setting
	CallMod	SerialSetFlowControl		;
	ret
RestoreFlowControl	endp

GetFlowSettings	proc	near
	clr	dx				; start with no flow cntrl
	mov	cx, mask FFB_NONE
	call	GetFlowListState		; "none" set?
	jc	gotFlow				; yes, use "none"
	mov	cx, mask SFC_HARDWARE
	call	GetFlowListState		; "hardware" set?
	jnc	afterHardware			; nope
	mov	dx, mask SFC_HARDWARE		; else, set "hardware"
afterHardware:
	mov	cx, mask SFC_SOFTWARE
	call	GetFlowListState		; "software" set?
	jnc	gotFlow				; nope, done
	ornf	dx, mask SFC_SOFTWARE		; else, set "software"
gotFlow:
	ret
GetFlowSettings	endp

GetFlowListState	proc	near
	push	ax, dx
	GetResourceHandleNS	FlowList, bx
	mov	si, offset FlowList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; carry set if selected
	pop	ax, dx
	ret
GetFlowListState	endp
endif	; !_TELNET

commCategory	byte	'geoComm',0
termTypeKey	byte	'terminal',0

RestoreTermType	proc	near
	cmp	ds:[restoreFromState], TRUE	; restoring from state file?
	je	useState			; yes, use state file setting
	;
	; get terminal setting from geos.ini file
	;
	push	ds
	segmov	ds, cs
	mov	si, offset commCategory
	mov	cx, cs
	mov	dx, offset termTypeKey
	call	InitFileReadInteger		; ax = terminal type (if C clr)
	pop	ds
	mov	cl, VT100			; assume default of VT100
	jc	useThisTermType			; if none, use default
	cmp	al, Terminals			; valid term type?
	jae	useThisTermType			; nope, use default
	mov	cl, al				; cl = term type
	jmp	short useThisTermType

useState:
	GetResourceHandleNS	TermList, bx
	mov	si, offset TermList		;
	call	GetListExcl			;set terminal emulation
	jnc	useThisTermType
	mov	cl, VT100			; in case no exclusive
useThisTermType:
	call	TermSetTerminal			;
	ret
RestoreTermType	endp

if	not _TELNET
tonePulseKey	byte	"toneDial",0

RestoreTonePulse	proc	near
	cmp	ds:[restoreFromState], TRUE	; restoring from state file?
	je	useState			; yes, use state file setting
	;
	; get tone/pulse setting from geos.ini file
	;
	call	FetchModemFromIni		; modemNameBuf = modem cat.
	jc	useState			; no modem in geos.ini
	mov	si, offset modemNameBuf		; (buffer in dgroup)
	mov	cx, cs
	mov	dx, offset tonePulseKey
	call	InitFileReadBoolean		; ax = TRUE/FALSE
	mov	cx, ax				; cx = TRUE/FALSE
	jnc	useThisTonePulse		; if found entry, use it
	jmp	useDefaultTonePulse		; if none, use default

useState:
	GetResourceHandleNS	ModemDial, bx
	mov	si, offset ModemDial
	call	GetListExcl			; cx = TRUE/FALSE
	jnc	useThisTonePulse
useDefaultTonePulse:
	mov	cx, TRUE			; assume TONE if none
useThisTonePulse:
	mov	ds:[toneDial], cl
	GetResourceHandleNS	ModemUI, bx
	mov	si, offset ModemUI:ModemDial
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
RestoreTonePulse	endp

RestoreDuplex	proc	near
	GetResourceHandleNS	EchoList, bx
	mov	si, offset EchoList		;
	call	GetListExcl			;
	call	TermSetDuplex
	ret
RestoreDuplex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	attempt to open com port
	
CALLED BY:	TermSetPort, RestoreComPort

PASS:		ds	- dgroup	
		cx	- port to open

RETURN:		cx	- 0 if no port opened

DESTROYED:	cx, dx, bp, ax si

PSEUDO CODE/STRATEGY:
	if can't open com port then reset the genlist of available ports

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	04/24/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenPort	proc	near

	mov     ds:[serialPort], cx             ;
	push	cx				;save requested port
	CallMod OpenComPort                     ;  and open this one
	pop	dx				;get requested port
	mov	cx, 1				;flag that open  port
	jnc     50$				;exit if port was opened okay

	push	ax, dx				;save requested port & error
						;reset port list so no
						; port is selected
	mov     ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	clr	dx				;not indetermminate
	GetResourceHandleNS	ComList, bx
	mov     si, offset ComList              ;
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	dx				;restore requested port
	pop	ax				;restore StreamError
	
	shr	dl, 1
	add	dx, '1'
DBCS <	clr	cx				;null-terminator	>
DBCS <	push	cx							>
	push	dx	
	mov	cx, ss
	mov	dx, sp

	mov	bp, ERR_COM_MISSING
	cmp	ax, STREAM_NO_DEVICE
	je	displayError
	mov     bp, ERR_COM_OPEN               	;
displayError:
	CallMod DisplayErrorMessage             ;
	pop	dx
DBCS <	pop	cx							>
	mov     ds:[serialPort], NO_PORT        ;flag no ports are opened

	call	DisablePortStuff		;	

	clr	cx				;flag no port opened
50$:
	jcxz	exit
	push	cx				;don't mess up return flag
	call	EnablePortStuff
		
if 0
;do this after correct baud rate, etc. is set - brianc 8/21/90
	; if software flow control is enabled then send an XON
	; when we open the port.  Just in case an XOFF was sent
	; by another port some time.
	;
	test    ds:[serialFlowCtrl], mask SFC_SOFTWARE
	jz      90$
	mov     bx, ds:[serialPort]             ;set  port #
	mov     cl,  CHAR_XON			;send an xoff
	mov     ax, STREAM_BLOCK
	CallSer DR_STREAM_WRITE_BYTE
90$:
endif
	pop	cx
exit:
	ret
OpenPort	endp

endif	; !_TELNET
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFileSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check that a file was selected from the file selector
	
CALLED BY:	TermMacroSelect, TermSendSelect

PASS:		ds	- dgroup	
		bx:si	- file selector
		bp      - GenFileSelectorEntryFlags


RETURN:		C	- clear if file selected	
		ds:dx	  contains name of selected file
		bp	- GenFileSelectorEntryFlags
				GFSEF_LONGNAME

		C	- set if file not selected

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFileSelect	proc	near
	push	bp				; save GFSEF_* flags for return
	test	bp, mask GFSEF_OPEN             ;checking for opening
	je      noFile
	and     bp, mask GFSEF_TYPE
	cmp     bp, GFSET_FILE                  ;  a file
	jne     noFile

	mov     ax, MSG_GEN_PATH_GET
	mov     di, mask MF_CALL		;now change to path of file
	mov     dx, ds
	mov     bp, offset pathnameBuf          ;dx:bp-> buffer to hold path
	mov	cx, size pathnameBuf
	call    ObjMessage			;dx:bp filled, cx = disk handle
	jc	noFile				;error -> treat as no-file
	push	bx				;save resource of file selctor
	mov     bx, cx                          ;pass disk handle of path
	mov	dx, bp				;ds:dx = path
	call    FileSetCurrentPath              ;
	pop	bx

	mov     ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov     cx, ds                          ;get name of selected file
	mov     dx, offset pathnameBuf          ;cx:dx->path buffer
	mov	di, mask MF_CALL
	call	ObjMessage
	clc					;flag file selected
	jmp	short exit
noFile:
	stc					;flag no file selected
exit:
	pop	bp				; return GFSEF_* flags in CX
	ret
CheckFileSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileSelectPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize path of geoComm file selectors
	
CALLED BY:	ProcessTermcap

PASS:		ds	- dgroup	

RETURN:		


DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileSelectPath	proc	near
	cmp	ds:[restoreFromState], TRUE	; restore from state file?
	je	exit				; yes, don't futz with paths
						;	saved in state file
	mov	ax, SP_DOCUMENT
	call	FileSetStandardPath 		;go to Term's document directory

	mov	si, offset pathnameBuf		;ds:si->pathname buffer
	mov	cx, size pathnameBuf
	call	FileGetCurrentPath
	mov	ds:[diskHandle], bx		;save disk handle
	mov	bp, bx				;pass disk handle

	mov	cx, ds				;set file selector path
	mov	dx, si				;cx:dx ->pathname
	GetResourceHandleNS	SendFileSelector, bx
	mov	si, offset SendFileSelector	;	to Document\Term dir
	call	SaveDataAndSetFileSelPath

	GetResourceHandleNS	RecvFileSelector, bx
	mov	si, offset RecvFileSelector
	call	SaveDataAndSetFileSelPath

	GetResourceHandleNS	SaveAsFileSelector, bx
	mov	si, offset SaveAsFileSelector
	call	SaveDataAndSetFileSelPath

	GetResourceHandleNS	TextRecvFileSelector, bx
	mov	si, offset TextRecvFileSelector
	call	SaveDataAndSetFileSelPath

	GetResourceHandleNS	TextSendFileSelector, bx
	mov	si, offset TextSendFileSelector
	call	SaveDataAndSetFileSelPath
exit:
	ret
InitFileSelectPath	endp


SaveDataAndSetFileSelPath	proc	near
	mov	ax, MSG_GEN_PATH_SET
	push	cx, dx, bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp
	ret
SaveDataAndSetFileSelPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermFileRecvStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a file using Xmodem

CALLED BY:	TermAsciiRecvStart, TermXmodemRecvStart

PASS:		ds	= dgroup

RETURN:		carry set if error (ignored by caller if not Responder)

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 12/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermFileRecvStart 	proc	near
	cmp	ds:[termStatus], ON_LINE	
	jne	error

;;any use to flush input stream before starting file transfer? - brianc 9/25/90
;;	mov	ax, STREAM_READ
;;	mov	bx, ds:[serialPort]
;;	CallSer	DR_STREAM_FLUSH

;do this in FileRecvStart, after opening recv file - brianc 2/15/94
;	call	SetFileRecvInput		;send input to file receive
	CallMod	FileRecvStart			;	routine
	jnc	exit

	call	SetScreenInput		
error:
	stc					; indicate error
exit:
	ret
TermFileRecvStart endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnablePortStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable geoComm options that depend on a port being opened

CALLED BY:	

PASS:		

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnablePortStuff 	proc	near
	CallMod	EnableFileTransfer
if	not _TELNET
	CallMod	EnableModemCmd
	CallMod	EnableEditAndDial
endif
	ret
EnablePortStuff 	endp

DisablePortStuff 	proc	near
	CallMod	DisableFileTransfer
if	not _TELNET
	CallMod	DisableModemCmd
	CallMod	DisableEditAndDial
endif
	ret
DisablePortStuff 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkActive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	tell UI that the application wants to be notified before exiting

CALLED BY:	

PASS:		ds	- dgroup	

RETURN:		Z	- clear if can't mark active/inactive
			  set otherwise

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/03/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MarkActive 	proc	near
;this is handled completely - brianc 7/20/92
if 0
	mov     ax, MSG_APP_MARK_ACTIVE
	call	MarkCommon
else
	cmp	ax, ax		; set Z
endif
	ret
MarkActive 	endp

MarkInActive 	proc	near
;this is handled completely - brianc 7/20/92
if 0
	mov     ax, MSG_APP_MARK_NOT_ACTIVE
	call	MarkCommon
else
	cmp	ax, ax		; set Z
endif
	ret
MarkInActive 	endp

MarkCommon 	proc	near
;this is handled completely - brianc 7/20/92
if 0
	mov	bx, ds:[applUIHandle]
	mov	si, offset MyApp
	mov	di, mask MF_CALL
	call	ObjMessage				;was the MARK_ACTIVE
	cmp	cx, TRUE				;	sucessful
endif
	ret
MarkCommon 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckPhoneNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if phone number is legit

CALLED BY:	

PASS:		bx:si	- chunk:offset of text edit box containing phone number	

RETURN:		zero flag set if there is no phone number to dial

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		Check if a phone number is there
		(later can check if this is a legit # or not)

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/23/90	Initial version
	ted	12/1/92		zero flag to indicate no phone number

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckPhoneNumber 	proc	near
	clr     dx                              ;flag give me a buffer
	mov     ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov     di, mask MF_CALL
	call    ObjMessage
	mov	bx, cx
	call	MemFree
	tst	ax				; zero flag set if empty
	ret
CheckPhoneNumber 	endp

