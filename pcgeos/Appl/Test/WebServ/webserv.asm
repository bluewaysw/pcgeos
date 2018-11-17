COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS Web Server
MODULE:		
FILE:		webserv.asm

AUTHOR:		Allen Yuen, Sep 25, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT WebServProcessRequest

    INT WebServParseRequest

    INT StripCRLFSpaceSlash     Convert any C_CR or C_LF or C_SPACE to
				C_NULL, and C_SLASH to C_BACKSLASH

    INT WebServThreadMain

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/25/95   	Initial revision


DESCRIPTION:
	Code for GEOS Web Server.
		

	$Id: webserv.asm,v 1.1 97/04/04 15:09:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include	assert.def
include	thread.def
include	socket.def
include	timer.def
include	system.def
include	webserv.def

include	webserv.rdef



idata	segment

	replyHeader	char	"HTTP/1.0 200 OK", C_CR, C_LF,
				"Content-length: "

	; 4 spaces for CRLFCRLF
	replyHeaderFileSize	\
		char	(UHTA_NO_NULL_TERM_BUFFER_SIZE+4) dup(?)

		.assert	offset replyHeaderFileSize \
			eq offset replyHeader + size replyHeader

idata	ends



udata	segment

	appQuitting	BooleanByte	; true if app is trying to quit

	httpRequestBuf	char	(PATH_BUFFER_SIZE + 5) dup (?)
					; we only handle file requests

udata	ends



WebServClassStructures	segment	resource

	WebServProcessClass	mask CLASSF_NEVER_SAVED

WebServClassStructures	ends



ErrorPageBlock	segment	resource

;
; WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
; If you add/remove any bytes from the pages below, make sure you update
; the number in the "Content-length:" line.
;

NotFoundPage	char	\
	"HTTP/1.0 404 Not Found", C_CR, C_LF,
	"Server: GEOS Web Server", C_CR, C_LF,	; for advertising purpose :-)
	"Content-length: 106", C_CR, C_LF,
	C_CR, C_LF,			; end of header
	"<TITLE>404 Not Found</TITLE><H1>404 Not Found</H1><P>",
	"The requested object does not exist on this server.", C_CR, C_LF

	; NotFoundPage currently 106 bytes

InvalidRequestPage	char	\
	"HTTP/1.0 400 Bad Request", C_CR, C_LF,
	"Server: GEOS Web Server", C_CR, C_LF,	; for advertising purpose :-)
	"Content-length: 119",
	C_CR, C_LF,			; end of header
	"<TITLE>400 Bad Request</TITLE><H1>400 Bad Request</H1><P>",
	"Your browser sent a request that the server does not handle.",
	C_CR, C_LF

	; InvalidRequestPage currently 119 bytes

;
; WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
;

ErrorPageBlock	ends



CommonCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WSPGenProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a thread to accept connections when app starts.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		*ds:si	= WebServProcessClass object
		ds:di	= WebServProcessClass instance data
		ds:bx	= WebServProcessClass object (same as *ds:si)
		es 	= segment of WebServProcessClass
		ax	= message #
		cx	= AppAttachFlags
		dx	= Handle of AppLaunchBlock
		bp	= Handle of extra state block
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WSPGenProcessOpenApplication	method dynamic WebServProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION

	mov	di, offset WebServProcessClass
	call	ObjCallSuperNoLock

	;
	; Create a thread for listening.
	;
;
; This is a hack to get around a sync bug in Socket lib.  It crashes if the
; thread that calls SocketAccpet has a lower priority than the thread that
; calls SocketConnect.  So we set our thread to the highest priority.
;
PrintMessage <AY: Change thread priority back to PRIORITY_LOW once Socket lib bug is fixed.>
;;;	mov	al, PRIORITY_LOW
clr	al			
	mov	cx, vseg WebServThreadMain
	mov	dx, offset WebServThreadMain
	mov	di, WEBSERV_STACK_SIZE
	mov	bp, handle 0
	call	ThreadCreateVirtual	; bx = thread handle, CF set on error
	jc	quitApp

	ret

quitApp:
	mov	bx, handle WebServApp
	mov	si, offset WebServApp
	mov	ax, MSG_META_QUIT
	clr	di			; it's on a different thread anyway
	GOTO	ObjMessage

WSPGenProcessOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WSPGenProcessCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal the accepting thread to quit.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		*ds:si	= WebServProcessClass object
		ds:di	= WebServProcessClass instance data
		ds:bx	= WebServProcessClass object (same as *ds:si)
		es 	= segment of WebServProcessClass
		ax	= message #
RETURN:		cx	= handle of block to save
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WSPGenProcessCloseApplication	method dynamic WebServProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION

	push	ds
	segmov	ds, dgroup, cx
	mov	ds:[appQuitting], BB_TRUE
	pop	ds

	mov	di, offset WebServProcessClass
	GOTO	ObjCallSuperNoLock

WSPGenProcessCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WebServProcessRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accept a pending connection and handle the request.

CALLED BY:	WebServThreadMain
PASS:		bx	= Socket that has data available
		es	= dgroup
RETURN:		nothing
DESTROYED:	everything except bx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WebServProcessRequest	proc	far
	uses	bx
	.enter

	mov	bp, 5 * 60		; 5-sec timeout for accepting
	call	SocketAccept		; cx = new Socket
	jc	done			; just give up on error 

	;
	; Get the http request
	;
	mov	bx, cx			; bx = new Socket
	mov	di, offset httpRequestBuf	; es:di = buf
	mov	bp, 30 * 60		; 30-sec timeout for recviving

getRequest:
	mov	cx, offset httpRequestBuf + size httpRequestBuf
	sub	cx, di			; cx = size of buffer
	clr	ax			; no SocketRecvFlags
	call	SocketRecv		; CF set on error
	jc	close

	;
	; See if we have the complete request.
	;
	; We only handle the first line of the request header.  So if the
	; buffer is full we just ignore the rest of the request.
	;
	; If the buffer is not full but there is a C_NULL or C_CR or C_LF, we
	; assume the first line is complete, and parse it.
	;
	; Otherwise, loop again to get the rest of the first line.
	;
	mov	ax, cx
	add	ax, di			; es:cx = end of filled buffer
	cmp	ax, offset httpRequestBuf + size httpRequestBuf
	je	parse			; definitely an error, just return the
					;  error page.
	; search for C_NULL
	push	cx, di
	clr	ax
	LocalFindChar
	pop	cx, di
	je	parse

	; search for C_CR
	push	cx, di
	LocalLoadChar	ax, C_CR
	LocalFindChar
	pop	cx, di
	je	parse

	; search for C_LF
	push	cx, di
	LocalLoadChar	ax, C_LF
	LocalFindChar
	pop	cx, di
	je	parse

	;
	; request not complete.  Receive again.
	;
	add	di, cx
	jmp	getRequest

parse:
	call	WebServParseRequest

close:
	call	SocketClose
EC <	WARNING	WEBSERV_SPAWNED_SOCKET_CLOSED				>

done:
	.leave
	ret
WebServProcessRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WebServParseRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the request from the client.

CALLED BY:	WebServProcessRequest
PASS:		es	= dgroup
		bx	= Socket
		httpRequestBuf in dgroup containing the request, ended with
			C_CR or C_LF or C_NULL
RETURN:		nothing
DESTROYED:	everything except bx, bp, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
requestPrefix	char	"GET "		; no null
nullPath	TCHAR	C_NULL

WebServParseRequest	proc	near
sock		local	Socket		push	bx
bufferHptr	local	hptr.char
	uses	bx
	.enter

	call	FilePushDir

	;
	; If the request doesn't start with "GET ", it's invalid.  HA HA!
	;
	mov	di, offset httpRequestBuf	; es:di = httpRequestBuf
	segmov	ds, cs
	mov	si, offset requestPrefix
	mov	cx, length requestPrefix
	call	LocalCmpStrings
	mov	si, offset InvalidRequestPage
	mov	cx, size InvalidRequestPage
	jne	sendFromBlock

	;
	; See if we can find the file
	;
	mov	bx, SP_DOCUMENT
	mov	dx, offset nullPath	; ds:dx = nullPath
	call	FileSetCurrentPath
EC <	ERROR_C	-1							>
	segmov	ds, es
	mov	dx, offset httpRequestBuf + size requestPrefix
					; ds:dx = file path

	;
	; If the first char in the path is a '/', skip it.
	;
	mov	si, dx
	LocalCmpChar	ds:[si], C_SLASH
	jne	noSlash
	LocalNextChar	dsdx

noSlash:
	call	StripCRLFSpaceSlash
	mov	al, FILE_DENY_W or FILE_ACCESS_R
	call	FileOpen		; ax = file hptr, CF set if error
	jnc	sendFromFile

	;
	; Can't open file, assume file is not there.
	;
	mov	si, offset NotFoundPage
	mov	cx, size NotFoundPage
	jmp	sendFromBlock

sendFromFile:
	;
	; First fill the header with file size.
	;
	mov_tr	bx, ax			; bx = file hptr
	call	FileSize		; dxax = size
	mov	di, offset replyHeaderFileSize	; es:di = replyHeaderFileSize
	clr	cx			; no UtilHexToAsciiFlags
	call	UtilHex32ToAscii	; cx = str len
	add	di, cx
	LocalLoadChar	ax, C_CR
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_LF
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_CR
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_LF
	LocalPutChar	esdi, ax
	mov	di, bx			; di = file hptr

	;
	; Send the header
	;
	mov	bx, ss:[sock]
	mov	si, offset replyHeader	; ds:si = replyHeader
	add	cx, size replyHeader + 4	; size of replyHeader plus
						;  CRLFCRLF
	clr	ax			; no SocketSendFlags
	call	SocketSend		; CF set on error
	jc	closeFile

	;
	; Allocate a buffer
	;
	mov	cx, ALLOC_DYNAMIC_LOCK
	mov	ax, WEBSERV_FILEREAD_BUFFER_SIZE
	call	MemAlloc		; bx = hptr, ax = sptr
	jc	closeFile
	mov	ss:[bufferHptr], bx

	mov	ds, ax
	clr	dx, si			; ds:dx = ds:si = buffer
	mov	cx, WEBSERV_FILEREAD_BUFFER_SIZE

readLoop:
	;
	; Read one buffer-ful from file
	;
	clr	al			; return errors
	mov	bx, di			; bx = file hptr
	call	FileRead		; cx = # bytes read, CF set if error
	jnc	send
	cmp	ax, ERROR_SHORT_READ_WRITE
	jne	freeBuffer

	jcxz	freeBuffer		; don't try to call SocketSend with
					;  cx = 0, because I don't trust the
					;  socket lib to do the right thing.

send:
	;
	; Send to socket
	;
	mov	bx, ss:[sock]
	clr	ax			; no SocketSendFlags
	call	SocketSend		; CF set on error
	jc	freeBuffer

	;
	; If we have read a buffer-ful of data, read again.  Else we've reached
	; the end of file.
	;
	cmp	cx, WEBSERV_FILEREAD_BUFFER_SIZE
	je	readLoop

freeBuffer:
	mov	bx, ss:[bufferHptr]
	call	MemFree

closeFile:
	mov	bx, di			; bx = file hptr
	clr	al			; return error
	call	FileClose		; but then we ignore it
	jmp	done

sendFromBlock:
	;
	; Send some html from a block.
	;	si	= offset of page
	;	cx	= size
	;
	mov	bx, handle ErrorPageBlock
	call	MemLock
	mov	ds, ax			; ds:si = error page
	mov	bx, ss:[sock]
	clr	ax			; no SocketSendFlags
	call	SocketSend		; ignore error, just return
	mov	bx, handle ErrorPageBlock
	call	MemUnlock

done:
	call	FilePopDir

	.leave
	ret
WebServParseRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StripCRLFSpaceSlash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert any C_CR or C_LF or C_SPACE to C_NULL, and C_SLASH to
		C_BACKSLASH

CALLED BY:	WebServParseRequest
PASS:		ds:dx	= string to strip, ended with C_CR, C_LF, C_SPACE or
			  C_NULL
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StripCRLFSpaceSlash	proc	near
	uses	ax, si
	.enter

	mov	si, dx			; ds:si = string

	;
	; Loop till we find a C_CR, C_LF, C_SPACE or C_NULL
	;
charLoop:
		Assert	fptr, dssi
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	je	done
	LocalCmpChar	ax, C_CR
	je	writeNull
	LocalCmpChar	ax, C_LF
	je	writeNull
	LocalCmpChar	ax, C_SPACE
	je	writeNull

	;
	; It's none of the terminators.  See if it's C_SLASH
	;
	LocalCmpChar	ax, C_SLASH
	jne	charLoop
	mov	{TCHAR} ds:[si - size TCHAR], C_BACKSLASH
	jmp	charLoop

writeNull:
	LocalClrChar	<ds:[si - size TCHAR]>

done:
	.leave
	ret
StripCRLFSpaceSlash	endp

CommonCode	ends



FixedCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WebServThreadMain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Top procedure for the accepting thread

CALLED BY:	ThreadCreateVirtual
PASS:		ds, es	= dgroup
RETURN:		never (jump to ThreadDestroy)
DESTROYED:	n/a
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WebServThreadMain	proc	far

	;
	; Create a socket for listening
	;
	mov	ax, SDT_STREAM
	call	SocketCreate		; bx = Socket
EC <	ERROR_C	-1							>
	mov	cx, MANUFACTURER_ID_SOCKET_16BIT_PORT
	mov	dx, IPPORT_HTTP
	call	SocketBind
EC <	ERROR_C	-1							>

listen:
	tst	es:[appQuitting]
	jnz	quit

	;
	; Listen to the port
	;
	mov	cx, 1
	call	SocketListen
	jnc	accept

	;
	; Try again if error
	;
	mov	ax, 2 * 60
	call	TimerSleep
	jmp	listen

accept:
	;
	; Process the request.
	;
	call	WebServProcessRequest
	tst	es:[appQuitting]
	jz	accept

quit:
	;
	; quit
	;
	call	SocketClose
EC <	WARNING	WEBSERV_MAIN_SOCKET_CLOSED				>
	clr	cx, dx			; exit code = 0, no ack OD
	jmp	ThreadDestroy

WebServThreadMain	endp

FixedCode	ends
