COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File
FILE:		fileMain.asm

AUTHOR:		Dennis Chow, December 12, 1989

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      12/12/89        Initial revision.

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: fileMain.asm,v 1.1 97/04/04 16:56:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRecvStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a file

CALLED BY:	TermFileRecvStart

PASS:		ds 		- dgroup

RETURN:		carry set if error

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Clear out values in text object		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileRecvStart	proc	far

	;
	; We need to initialize fileHandle to be BOGUS_VAL because
	; FileRecvEnd checks for this value when determining whether
	; to close an open file or not.  This becomes a problem when
	; the receiver has an error while opening a file and a dialog
	; box is popped-up and awaits for a user response.  While
	; waiting, the sender will timeout and given the option to
	; abort.  If the sender aborts before the receiver can resolve
	; its open file error, then FileRecvEnd will be executed with
	; an uninitialized fileHandle, thus causing a fatal error in
	; FileClose. 
	; 6/2/95 - ptrinh
	;
	mov	ds:[fileHandle], BOGUS_VAL


	cmp	ds:[recvProtocol], NONE
	je	5$
	mov	si, offset RecvFileSelector	;use xmodem file selector
	jmp	short 10$
5$:
	mov	si, offset TextRecvFileSelector	;pass where to get path from 
10$:
	mov	dx, ds:[transferUIHandle]	;
	CallMod	SetFilePath			;if error setting path 
	jnc	12$				;for the file
	jmp	error				;then exit
12$:						;
	cmp	ds:[recvProtocol], NONE	
	je	15$
	mov	si, offset RecvTextEdit
	jmp	short 20$
15$:
	mov	si, offset TextRecvTextEdit
20$:
	mov	dx, ds:[transferUIHandle] 	;	see if it exists
	CallMod	GetFileName			;ds:dx->filename	
	LONG    jc      error			; exit if error

	push	bx				; save filename block handle
	CallMod	CheckFileStatus
	pop	bx				; retrieve filename block handle
	jnc	42$
	call	MemFree				; free filename block
	jmp	error
42$:
	push	bx				; save filename block handle
	GetResourceHandleNS	RecvFileDisp, bx
	mov	si, offset RecvFileDisp
	cmp	es:[recvProtocol], XMODEM	;set the recv display
	je	50$				; with the name of file 
	GetResourceHandleNS	AsciiRecvDisp, bx
	mov	si, offset AsciiRecvDisp
50$:
	call	SetFileName	
	pop	bx				; retrieve filename block handle
	call	MemFree				; free filename block
	segmov	ds, es, ax			;restore dgroup

	mov	ax, FILE_BUF_SIZE		;get block of memory for packet
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	jnc	60$
	jmp	memErr
60$:
	mov	ds:[packetHandle], bx		;save handle to segment	
	clr	ds:[packetHead]			;point to beginning of packet

	mov	cx, FILE_OVERWRITE 		;we're going to overwrite any
	cmp	ds:[recvProtocol], XMODEM	;existing files
	je	62$
	mov	si, offset TextRecvTextEdit	;get file handle
	jmp	short 65$
62$:
	mov	si, offset RecvTextEdit		
65$:
	mov	dx, ds:[transferUIHandle] 
		
	CallMod	GetFileHandle			;open file to download to
	jnc	68$
	;
	; Delete packet from packetHandle
	;
	clr	bx
	xchg	bx, ds:[packetHandle]					
	call	MemFree				; bx destroyed		
	stc					; indicator file open err
	jmp	exit
	
68$:
	mov	ds:[fileHandle], bx
	mov	ds:[termStatus], FILE_RECV	
	mov	ds:[softFlowCtrl], FALSE	; in case text capture
	
if	not _TELNET
	cmp	ds:[recvProtocol], NONE		; don't disable software
	je	69$				;	flow control for
	call	InitSerialForFileTrans		;	text capture
	jnc	69$
	jmp	error
endif	; !_TELNET
		
69$:
;moved here from TermFileRecvStart - brianc 2/15/94
NCCT <	call	SetFileRecvInput					>
	CallMod	DisableFileTransfer		;disable file transfer triggers

if	not _TELNET
	CallMod	DisableScripts
	CallMod	DisableProtocol
	CallMod	DisableModemCmd
endif	; !_TELNET

    	mov     ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	cmp	ds:[recvProtocol], NONE
	je	70$	
	mov	si, offset RecvXmodemBox
	jmp	short 75$
70$:
	mov	si, offset RecvAsciiBox
75$:
	CallTransferUI
	cmp	ds:[recvProtocol], XMODEM
	je	80$

	call	DoAsciiRecv
	jmp	short exit
80$:	 
	GetResourceHandleNS	RecvStatusSummons, bx
	mov	si, offset RecvStatusSummons	;enable recv status box
	mov	ax, MSG_GEN_INTERACTION_INITIATE	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
						;
	call	FileTransInit			;init file transfer variables
if 	not _TELNET
NRSP <	call	GetRecvProto						>
endif
	mov	ds:[sendACK], FALSE		;don't send ACKs during timeouts
	mov	ds:[maxTimeouts], MAX_INIT_TIMEOUTS
	mov	ds:[tranState], TM_GET_HOST 	;wait for host
	cmp	ds:[useChecksum], TRUE
	jne	sendCRC
	mov	di, TEN_SECOND			;set 10 second timer for 128
	call	FileStartTimer			;	byte packet	
	mov	cl, CHAR_NAK
	jmp	short writeChar
sendCRC:
	mov	di, THREE_SECOND
	call	FileStartTimer			;set shorter timer for CRC
	mov	cl, CHAR_CRC
writeChar:
	call	FileWriteChar			;tell host we're here
	clc
	jmp	short exit
memErr:
	mov	bp, ERR_NO_MEM_FTRANS		;display error message
displayErr::
	CallMod	DisplayErrorMessage		;  and set  
error:
	segmov	ds, es, ax			;restore dgroup
	stc					;  error flag
exit:
	ret
FileRecvStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileStopTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	stop a timer

CALLED BY:	FileDoReceive

PASS:		ds		- dgroup

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileStopTimer	proc	far
	mov	bx, ds:[timerHandle]
	cmp	bx, BOGUS_VAL				;is timer on
	je	exit					;nope, exit
	clr	ax		; 0 => continual
	call	TimerStop				;  and flag timer off
	mov	ds:[timerHandle], BOGUS_VAL		;else turn off timer
exit:
	ret
FileStopTimer	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRecvData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a timeout or a buffer of characters sent 
			during a file receive.  
			

CALLED BY:	SerialInThread, Timer event

PASS:		cx		- number of chars in buffer
		dx		- TIMER_EVENT (if called by timer)
		ds		- dgroup
		ds:si		- buffer to read chars from 

RETURN:		cx		- number of unprocessed chars left in auxBuf
				(THIS WILL ALWAYS BE 0, AS FILE XFER IS
				SYNCHRONOUS)

DESTROYED:	

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	I don't restart the timer when I get a timeout, 
	I figure I don't use up that much time processing the timeout and
	want to keep the code simple.

	When I get timeout
		reset transfer state to (wait for start of packet)
		send NAK 
		increment timeout count

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileRecvData	proc	far
	cmp	dx, TIMER_EVENT			;if this a timeout
	jne	charIn				;  
	call	HandleRecvTimeout		;process it
	jmp	exit				;  
charIn:
	cmp	ds:[tranState], TM_IN_PACKET
	jne	notInPack
	jmp	inPacket
notInPack:
	cmp	ds:[tranState], TM_GOT_CAN_1
	je	checkCan
	cmp	ds:[tranState], TM_GET_EOT	;waiting for EOT
	jne	notEOT
	mov	al, {byte} ds:[si]		;
	cmp	al, CHAR_EOT			;if didn't resend EOT
	jne	falseEOT			;then it was bogus
	jmp	fileEnd
checkCan:
	mov	al, {byte} ds:[si]		;
	cmp	al, CHAR_CAN			;if didn't send two CANCELs
	jne	falseEOT			;then ignore it
	jmp	fileCancel
falseEOT:					;
	mov	ds:[tranState], TM_GET_SOH	;bogus EOT, continue with trans
	jmp	short checkStart						
notEOT:
	cmp	ds:[tranState], TM_GET_HOST	;are we trying to contact host
	je	checkStart
	cmp	ds:[tranState],	TM_GET_PAK_NUM	; 
	je	packetNumber
	cmp	ds:[tranState], TM_GET_PAK_CMPL	;
	je	packetCmpl
	cmp	ds:[tranState], TM_GET_CHECK_1	;if got checksum	
	je	cmpCheck1			;	check its value
	cmp	ds:[tranState], TM_GET_CHECK_2	;if got checksum	
	je	cmpCheck2			;	check its value
	cmp	ds:[tranState], TM_GET_SOH	;are we waiting for start of
	je	checkStart			;	packet
	jmp	exit
checkStart:
	mov	al, {byte} ds:[si]
	cmp	al, CHAR_SOH			;start of 128 char packet
	je	gotStart
	cmp	al, CHAR_STX			;start of 1K packet
	je	gotStart				;
	cmp	al, CHAR_EOT			;is this end of transmission?
	LONG je	checkEOT			;then ACK the EOT
	cmp	al, CHAR_CAN
	je	gotCan
	inc	si				;advance buffer ptr
	loop	checkStart
	jmp	exit				;SOH not found, exit
gotStart:					;remote is alive
	dec	cx				;decrement character count
	inc	si				;update ptr past SOH
	cmp	al, CHAR_SOH
	je	pack128
	cmp	ds:[packetSize], PACKET_1K
	je	stopTimer
	mov	ds:[packetSize], PACKET_1K	;changing packet size	
	jmp	short stopTimer
pack128:
	cmp	ds:[packetSize], PACKET_128	;ignore if same packet size 
	je	stopTimer
	mov	ds:[packetSize], PACKET_128
stopTimer:	
	call	FileStopTimer			;got host
	mov	ds:[timerInterval], TEN_SECOND	;within packet set a ten
	mov	ds:[tranState], TM_GET_PAK_NUM	;	second timer
	mov	bx, ds:[packetSize]		;expecting a packet full
	mov	ds:[expChars], bx		;  of characters
	jcxz	restartTimer			;start up timer
packetNumber:
	call	FileCheckPacketNum
	jcxz	restartTimer			;if buffer empty exit
	jc	checkStart
packetCmpl:
	call	FileCheckPackCompl
	jcxz	restartTimer
	jc	checkStart
inPacket:
	call	FileProcessPacket
	jmp	short exit			
cmpCheck1:
	call	FileCheck1
	jmp	short exit
cmpCheck2:
	call	FileCheck2
	jmp	short exit
restartTimer:
	call	FileRestartTimer
	jmp	short exit
gotCan:
	dec	cx	
	inc	si				;update ptr past CAN	
	jcxz	10$	
	cmp	{byte} ds:[si], CHAR_CAN 
	je	fileCancel
;falseCan:
	mov	ds:[tranState], TM_GET_SOH
	inc	si
	dec	cx
	jcxz	exit
	jmp	checkStart
10$:
	mov	ds:[tranState],TM_GOT_CAN_1
	jmp	short exit
checkEOT:
	mov	cl, CHAR_NAK			;nak the first EOT
	call	FileWriteChar			;	and wait for another 
	mov	ds:[tranState], TM_GET_EOT	;	EOT
	jmp	short exit
fileCancel:
	mov	cl, CHAR_ACK			;else ACK the EOT and
	call	FileWriteChar			;  be done with transfer
	call	FileStopTimer			;stop timer before putting
						;	up blocking dialog
	mov	bp, ERR_REMOTE_CAN
	call	DisplayErrorMessage
	call	FileRecvEnd
	jmp	short exit
fileEnd:
	mov	cl, CHAR_ACK			;else ACK the EOT and
	call	FileWriteChar			;  be done with transfer
	call	FileRecvEnd			;
exit:
	; don't wait for timeout to send NAK -- brianc 2/23/94
	call	FileSendNakNow
	clr	cx			;return "number of unprocessed chars
					;in [auxBuf] = 0".
	ret
FileRecvData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRecvAbort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell remote to abort file send

CALLED BY:	

PASS:		ds	= dgroup
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		File transfer can only be aborted at the beginning
		of a file transfer.

		I'm in the middle of trying to fix it so this isn't true!!
		-mkh 3/30/94

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dennis		12/13/89	Initial version
	hirayama	3/30/94

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileRecvAbort	proc 	far

	ornf	ds:[currentFileFlags], mask FF_RECV_ABORT_TRIGGER_CLICKED
NRSP <	cmp	ds:[recvProtocol], XMODEM				>
NRSP <	je	doX							>
	call	EndAsciiRecv

	jmp	short exit
doX:
	cmp	ds:[termStatus], FILE_RECV	;if started file	
	je	stopRecv			;then need to stop it
   	mov     cx, LEN_CAN			;else cancel the transfer
	push	ds
	segmov	ds, cs				; ds:si = cancel string
	mov     si, offset abortStr
	call    FileWriteBuf
	pop	ds
stopRecv:
	;
	; If BEGAN_RECIEVING_PACKETS flag is *not* set (i.e. we haven't
	; received any Xmodem packets yet), just end the session like
	; before.  Otherwise, allow the session to continue, and things
	; will be cleaned up when we're about to send an Ack packet. -mkh
	;
	test	ds:[currentFileFlags], mask FF_BEGAN_RECEIVING_PACKETS
	jnz	exit
		
   	mov     cx, LEN_CAN			;else cancel the transfer
	push	ds
	segmov	ds, cs				; ds:si = cancel string
	mov     si, offset abortStr
	call    FileWriteBuf
	pop	ds

	call	FileRecvEnd
exit:
	ret
FileRecvAbort	endp

					;cancel string
abortStr	db	LEN_CAN dup (CHAR_CAN)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a file

CALLED BY:	TermXModemSend

PASS:		ds, es		- dgroup

RETURN:		---

DESTROYED:	

PSEUDO CODE/STRATEGY:
	If can't find file to send
		display error message
	Else	
		read file into buffer
		wait for NAK

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Some of send variables could be combined with recv variables
		to save bytes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileSendStart	proc	far
	cmp	ds:[sendProtocol], NONE
	je	15$	
	mov	si, offset SendFileSelector		;pass object offset
	jmp	short 20$
15$:
	mov	si, offset TextSendFileSelector		;
20$:
	mov	dx, ds:[transferUIHandle]
	CallMod	GetFileSelection	; return bp = GenFileSelectorEntryFlags
	jc	exit					;exit if filename dorked
	call	SendFile		; pass bp = GenFileSelectorEntryFlags
exit:
	ret
FileSendStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendAbort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quit trying to send the file

CALLED BY:	

PASS:		
		
RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:
	check if doing ascii or xmodem file send
	if ascii
		just stop sending packets 
	if xmodem
		If file transfer hasn't begun
			then send Abortstring
		Else
			send EOF sequence

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSendAbort	proc 	far
	cmp	ds:[fileSendAbortCalled], TRUE
	je	exit
	mov	ds:[fileSendAbortCalled], TRUE
NRSP <	cmp	ds:[sendProtocol], XMODEM				>
NRSP <	je	stopX							>
	cmp	ds:[fileDone], TRUE		;is file send done ?
	je	exit				;
	mov	ds:[fileDone], TRUE		;well now it is
	call	EndAsciiSend
	
	jmp	short exit
stopX:
	mov	ds:[fileDone], TRUE
;*** always send CANs
if 0
	tst	ds:[numPacketSent]	
	jz	10$			
	call    SendEndOfFile                           ;tell remote we're done
	mov     ds:[tranState], TM_ACK_EOT              ;wait for ACK
	jmp	short exit
10$:
endif
   	mov     cx, LEN_CAN
	push	ds
	segmov	ds, cs				; ds:si = cancel string
	mov     si, offset abortStr
	call    FileWriteBuf			;if error sending cancel string
	pop	ds
	jc	30$				;	bail
	cmp	ds:[termStatus], FILE_SEND	;if start button has been
	jne	exit				;	pressed then stop
30$:
	call	FileSendEnd			; 	the send
exit:
	ret
FileSendAbort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle data from remote when sending a file

CALLED BY:	

PASS:		cx		- number of chars in buffer
		dx		- TIMER_EVENT (if called by timer)
		ds		- dgroup
		ds:si		- buffer to read chars from 

RETURN:		cx		- number of unprocessed chars left in auxBuf
				(THIS WILL ALWAYS BE 0, AS FILE XFER IS
				SYNCHRONOUS)

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileSendData	proc 	far
	cmp	ds:[fileTransferCancelled], TRUE	; abort?
	jne	continue			; nope, continue
	call	FileSendAbort			; yes, abort
	jmp	exit

continue:
	cmp	dx, TIMER_EVENT			;if timeout when waiting for
	jne	charIn				;  remote then abort

	call	HandleSendTimeout		;if can't resend packet then
	jc      EOT_ACKed                       ;  abort
	jmp	exit

charIn:
	cmp	ds:[tranState], TM_GOT_CAN_1
	je	checkCAN
	cmp	ds:[tranState], TM_GET_REMOTE
	je	checkRemote
	cmp	ds:[tranState], TM_GET_ACK
	je	checkACK
	cmp	ds:[tranState], TM_ACK_EOT
	je	checkACK_EOT
	jmp	short exit

checkACK_EOT:
	cmp	{byte} ds:[si], CHAR_ACK
	je	EOT_ACKed
	inc	si
	loop	checkACK_EOT
	call	SendEndOfFile
	jnc	exit					;if no error exit

EOT_ACKed:						;EOT acked
	mov	ds:[tranState], TM_FILE_DONE		;we are out of here
	call	FileSendEnd
	jmp	short exit

checkACK:
	cmp	{byte}ds:[si], CHAR_ACK			;remote ACKing packet ?
	je	ackPacket
	cmp	{byte}ds:[si], CHAR_CAN			;remote canceling send?
	je	gotCancel
	cmp	{byte}ds:[si], CHAR_NAK
	je	nakPacket
	inc	si
	loop	checkACK
	jmp	nakPacket				;figure anything, but
							;ACK, CAN, or NAK
							;should nak the packet
ackPacket:
	call	IncSendPacket
	jmp	short exit	

gotCancel:						;check if remote 
	mov	ds:[tranState], TM_GOT_CAN_1		;wants to cancel send
	dec	cx 					;  dec char count
	inc	si					;  adv buf ptr
	jcxz	exit					;  if buf empty exit

checkCAN:
	cmp	{byte}ds:[si], CHAR_CAN			;  if don't get 
	je	cancelSend				;  consecutive CANs

	mov	ds:[tranState], TM_GET_ACK		;  consider it a NAK

nakPacket:
	call	IncSendErrors
	jc	cancelSend				;if error resending

	jmp	short exit				;  packet cancel send

cancelSend:
	call	FileSendEnd
	jmp	short exit

checkRemote:
	;also allow CHAR_CAN? - brianc 9/21/90
	cmp	{byte}ds:[si], CHAR_NAK			;use checksum
	je	gotNAK
	cmp	{byte}ds:[si], CHAR_CRC			
	je	gotCRC
	inc	si					; else ignore
	loop	checkRemote
	jcxz	exit

gotCRC:
	mov	ds:[useChecksum], FALSE			;use CRC

gotNAK:							;  and send da packet
	call	FileStopTimer
	call	ReadInPacket
	call	SendPacket				;

exit:
	cmp	ds:[fileTransferCancelled], TRUE	; cancelled?
	jne	noCancel
	call	FileSendAbort				; if so, abort
							; (OK to abort twice)
noCancel:
	clr	cx			;return "number of unprocessed chars
					;in [auxBuf] = 0".
	ret
FileSendData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User double clicked on an entry in send File selector

CALLED BY:	

PASS:		cx		- number of chars in buffer

RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSendSelect	proc 	far
	mov	si, offset SendFileSelector		;pass object offset
	mov	dx, ds:[transferUIHandle]		;exit if a file not	
	CallMod	GetFileSelection			;  selected
	jc	exit					;
exit:
	ret
FileSendSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the file 

CALLED BY:	FileSendStart, TermFileSendSelect	

PASS:		ds	- dgroup	
		ds:dx	- name of file to send
		bp 	- GenFileSelectorEntryFlags
				GFSEF_LONGNAME
RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendFile	proc 	far
	push	bp					; save GFSEF_* flags
	push	dx					;save ptr to filename
	mov	ds:[fileSendHandle], BOGUS_VAL	
	cmp	ds:[sendProtocol], NONE
	je	5$
	mov	si, offset SendFileSelector		;pass object offset
	jmp	short 10$
5$:
	mov	si, offset TextSendFileSelector		;pass object offset
	
10$:
	mov	dx, ds:[transferUIHandle]
	CallMod	SetFilePath				;continue if no error 
	jnc	12$					;  setting path 
	add	sp, 4				; clean up stack
	jmp	exit	
12$:
    	mov     ax, MSG_GEN_GUP_INTERACTION_COMMAND	;bring down the file
	mov	cx, IC_DISMISS
	cmp	ds:[sendProtocol], NONE	
	je	15$
	mov	si, offset MenuInterface:SendXmodemBox	;  selector box
	jmp	short 20$
15$:
	mov	si, offset MenuInterface:SendAsciiBox	
20$:
	GetResourceHandleNS	MenuInterface, bx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx					;restore ptr to filname
	GetResourceHandleNS	SendFileDisp, bx
	mov     si, offset SendFileDisp
	call	SetFileName				;set name of send file
	pop	bp				; retrieve GFSEF_* flags
	call	FileOpenForSend
	LONG jc	noFile

	mov	ds:[fileTransferCancelled], FALSE
	mov	ds:[fileSendAbortCalled], FALSE

	mov	ds:[softFlowCtrl], FALSE	; in case text send

if	not _TELNET
	cmp	ds:[sendProtocol], NONE		; don't disable software
	je	30$				;	flow control for
	call	InitSerialForFileTrans		;	text send
	jnc	30$
	jmp	exit
endif	; !_TELNET

30$:
	CallMod	DisableFileTransfer			

if	not _TELNET
	CallMod	DisableScripts
	CallMod	DisableProtocol
	CallMod	DisableModemCmd
endif	; !_TELNET

NRSP <	cmp	ds:[sendProtocol], XMODEM		;	triggers>
NRSP <	je	doXModem						>
	call	DoAsciiSend
	
	jmp	short exit
doXModem:
	CallMod	SetFileSendInput			;redirect input to
							;  send module
	GetResourceHandleNS	SendStatusSummons, bx
	mov	si, offset SendStatusSummons		;enable send status box
	mov	ax, MSG_GEN_INTERACTION_INITIATE	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	call	FileTransInit				;init file trans var
if	not _TELNET
	call	GetSendPacketSize
endif
	mov	ds:[tranState], TM_GET_REMOTE		;waiting for remote
	mov	ds:[maxTimeouts], MAX_INIT_TIMEOUTS
	mov	ds:[fileDone], FALSE			;reset last packet flag
	clr	ax	
	mov	ds:[packetHead], ax			;ptr to start of file	
	mov	ds:[numEOTsent], al			

	mov	di, ONE_MINUTE/2
	call	FileStartTimer
	clc						;flag okay	
	jmp	short exit
	
noFile:
;;error reported in FileOpenForSend - brianc 9/19/90
;;	mov	bp, ERR_FILE_NOT_FOUND			;display error message
;;	CallMod	DisplayErrorMessage
exit:
	ret
SendFile	endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendAsciiPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the next ascii packet

CALLED BY:	TermSendAsciiPacket	

PASS:		ds	- dgroup	

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileSendAsciiPacket	proc 	far
	tst	ds:[fileDone]			;if file done forget this	
	jz	send
	cmp	ds:[inMiddleOfPacket], TRUE
	jne	exit
send:
	call	SendAsciiPacket
exit:
	ret
FileSendAsciiPacket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AsciiRecvData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	receive a bunch of chars during an ascii transfer

CALLED BY:	SerialInThread, Timer event

PASS:		cx		- number of chars in buffer
		ds		- dgroup (non _CAPTURE_CLEAN_TEXT)
		es		- dgroup (_CAPTURE_CLEAN_TEXT)
		ds:si		- buffer to read chars from 
					(auxBuf in udata)

		(characters are in BBS code page)

RETURN:		cx 		- # of unprocessed chars	
	
DESTROYED:	ax, bx, dx, bp, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	should I just write the characters that come out to disk or
	should I display them on the screen too?.  For now I'll display
	them and write them out.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AsciiRecvData	proc 	far

	call	WriteAsciiPacket		;(pass in BBS code page)
	
	;
	; After the operation, we don't always want to call
	; FoamWarnSpaceAfterOperation because it will put dialog if disk
	; space goes below Warning Level. Since we allow capture until
	; Critical level, this dialog can be very very annoying.
	;
NRSP <	jc	exit							>
RSP <	jnc	writePacketOK						>
RSP <	;								>
RSP <	; Since we can't write packet to disk, that may imply a problem with>
RSP <	; disk space. Put up a warning note if necessary and stop catpure>
RSP <	;								>
RSP <	mov	ax, MSG_FILE_RECV_STOP_CHECK_DISKSPACE			>
RSP <	jmp	stopCapture						>
RSP < writePacketOK:							>
	
if	not _CAPTURE_CLEAN_TEXT
	mov	bp, si				;pass buffer in dx:bp
	mov	dx, ds				;
	;
	; it is okay to send this method, passing a fptr as this is run
	; under the serial thread (called from SerialReadData) so this
	; will be a direct call
	;
	mov     ax, MSG_READ_BUFFER		;(pass in BBS code page)
	CallSerialThread	
endif	; !_CAPTURE_CLEAN_TEXT

exit:
	ret

AsciiRecvData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset file transfer UI objects to starting state

CALLED BY:	RestoreState

PASS:		

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	08/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileReset	proc 	far
	call	FileSendReset
	call	FileRecvReset
	ret
FileReset	endp


if	_CAPTURE_CLEAN_TEXT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                FileCaptureText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Capture text to a file "Text capture" has been started

CALLED BY:	(EXTERNAL) ScreenData
PASS:           es:bp   = fptr to buffer of characters
                dx      = number of characters to capture
		ds:si	= Screen Class object instance data
RETURN:         nothing
DESTROYED:      nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        simon   9/28/95         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCaptureText proc    far
		class	ScreenClass
                uses    ds, es, si, cx
                .enter
        ;
        ; Skip if we are not capturing text
        ;
		mov	cx, es			; cx <- sptr of buf
                GetResourceSegmentNS    dgroup, es
                cmp     es:[fileHandle], BOGUS_VAL
		je      done
EC <		tstdw	es:[fileXferTextObj]				>
EC <		ERROR_Z TERM_INVALID_FILE_CAPTURE_STATUS		>
	;
	; Also make sure if we are displaying international char. If so,
	; don't write it to file.
	;
		BitTest	ds:[si][SI_intFlags], SIF_FILE_CAPTURE
		jz	done
        ;
        ; Make a copy of characters to the file
        ;
                push    ax, bx, dx, bp, di
		movdw	dssi, cxbp
                mov     cx, dx
	;
	; FSMParseString has converted characters to code page. This will
	; screw up CodePage -> Geos used by FoamDocConvertFromDosAppend since
	; this foam lib routine will do CodePage -> Geos again. Therefore, we
	; convert the characters from Geos -> CodePage here before passing to
	; FoamDocConvertFromDosAppend. A better solution will be to not do
	; code page conversion for data coming from remote, but this will
	; complicate the existing code structure.
	;
	; Since this routine returns to update screen, the characters after
	; logging to file have to be converted back to Geos charset.
	;
		mov	ax, MAPPING_DEFAULT_CHAR
		mov	bx, es:[bbsCP]
		call	LocalGeosToCodePage	; carry if def char used
EC <            Assert_buffer   dssi, cx                                >
		push	cx
                call    AsciiRecvData           ; cx <- #unprocessed data
		pop	cx			;  but we don't care
		mov	ax, MAPPING_DEFAULT_CHAR
EC <		Assert_dgroup	es					>
		mov	bx, es:[bbsCP]
EC <            Assert_buffer   dssi, cx                                >
		call	LocalCodePageToGeos	; carry if def char used
                pop     ax, bx, dx, bp, di

done:
                .leave
                ret
FileCaptureText endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCaptureTextChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Capture character to file

CALLED BY:	(EXTERNAL) ScreenCR
PASS:		al	= character to write to file (SBCS)
		ax	= character to write to file (DBCS)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	9/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCaptureTextChar	proc	far
	charToWrite	local	TCHAR
		uses	ax, bx, cx, dx, si, di
		.enter
	
SBCS <		mov	ss:[charToWrite], al				>
DBCS <		mov	ss:[charToWrite], ax				>
		segmov	ds, ss, ax
		lea	si, ss:[charToWrite]	; dssi <- char
		GetResourceSegmentNS	dgroup, es
		mov	cx, 1			; just 1 char
		push	bp
		call	AsciiRecvData
		pop	bp
		
		.leave
		ret
FileCaptureTextChar	endp

endif	; _CAPTURE_CLEAN_TEXT
