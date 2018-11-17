COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Stream Drivers -- FileStream driver
FILE:		filestrMain.asm

AUTHOR:		Jim DeFrisco, Jan 12, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/12/93		Initial revision


DESCRIPTION:
	Code to communicate with a file system via a stream interface.
		
	$Id: filestrMain.asm,v 1.1 97/04/18 11:46:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	filestr.def

;------------------------------------------------------------------------------
;	Driver info table
;------------------------------------------------------------------------------

idata		segment

DriverTable	DriverInfoStruct	<
	FilestrStrategy, mask DA_CHARACTER, DRIVER_TYPE_STREAM
>

ForceRef	DriverTable
idata		ends

;------------------------------------------------------------------------------
;		       MISCELLANEOUS VARIABLES
;------------------------------------------------------------------------------
udata		segment

udata		ends

idata		segment

fsdArray	FileStrData NUM_FSD_ENTRIES dup (<>)


slotAllocSem	Semaphore <>			; protects allocation of unit

idata		ends

Resident	segment	resource
DefFunction	macro	funcCode, routine
if ($-filestrFunctions) ne funcCode
	ErrMessage <routine not in proper slot for funcCode>
endif
		nptr	routine
		endm

filestrFunctions	label	nptr
DefFunction	DR_INIT,			FilestrNull
DefFunction	DR_EXIT,			FilestrNull
DefFunction	DR_SUSPEND,			FilestrNull
DefFunction	DR_UNSUSPEND,			FilestrNull
DefFunction	DR_STREAM_GET_DEVICE_MAP,	FilestrCallStreamDriver
DefFunction	DR_STREAM_OPEN,			FilestrOpen
DefFunction	DR_STREAM_CLOSE,		FilestrClose
DefFunction	DR_STREAM_SET_NOTIFY,		FilestrSetNotify
DefFunction	DR_STREAM_GET_ERROR,		FilestrCallStreamDriver
DefFunction	DR_STREAM_SET_ERROR,		FilestrCallStreamDriver
DefFunction	DR_STREAM_FLUSH,		FilestrCallStreamDriver
DefFunction	DR_STREAM_SET_THRESHOLD,	FilestrCallStreamDriver
DefFunction	DR_STREAM_READ,			FilestrRead
DefFunction	DR_STREAM_READ_BYTE,		FilestrReadByte
DefFunction	DR_STREAM_WRITE,		FilestrWrite
DefFunction	DR_STREAM_WRITE_BYTE,		FilestrWriteByte
DefFunction	DR_STREAM_QUERY,		FilestrCallStreamDriver


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all filestr-driver functions

CALLED BY:	GLOBAL
PASS:		di	= routine number
		bx	= open port number (usually)
RETURN:		depends on function, but an ever-present possibility is
		carry set with AX = STREAM_CLOSING or STREAM_CLOSED
DESTROYED:	

PSEUDO CODE/STRATEGY:
p		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

filestrData	sptr	dgroup

FilestrStrategy proc	far	
		uses es, ds
		.enter
EC <		cmp	di, StreamFunction				>
EC <		ERROR_AE	INVALID_FUNCTION			>
		segmov	es, ds		; In case segment passed in DS
		mov	ds, cs:filestrData
		cmp	di, DR_STREAM_OPEN
		jbe	notYetOpen
		cmp	ds:[fsdArray][bx].FSD_stream, -1
		je	portNotOpen
notYetOpen:
		call	cs:filestrFunctions[di]
exit:
		.leave
		ret
portNotOpen:
		mov	ax, STREAM_CLOSED
		stc
		jmp	exit
FilestrStrategy endp

global	FilestrStrategy:far


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init function, does nothing for non-hardware

CALLED BY:	DR_INIT, DR_EXIT (FilestrStrategy)
PASS:		ds	= dgroup
RETURN:		Carry clear if we're happy
DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilestrNull	proc	near
		clc
		ret
FilestrNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open one of the filestr ports

CALLED BY:	DR_STREAM_OPEN (FilestrStrategy)
PASS:		bx	= file handle of created/opened file
		dx	= total size of output buffer
		ds	= dgroup
RETURN:		bx	= unit number, to use with subsequent calls
DESTROYED:	ax, dx, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilestrOpen	proc	near	uses si, cx
		uses	si, bp
		.enter

		; first check to see if we can accomodate a new stream

		PSem	ds, slotAllocSem, TRASH_AX	; avoid collisions
		clr	si				; start at first one
tryNextSlot:
		cmp	ds:[fsdArray][si].FSD_stream, -1 ; check for unalloc'd
		je	haveOne
		add	si, size FileStrData
		cmp	si, NUM_FSD_ENTRIES*(size FileStrData)
		jb	tryNextSlot
		jmp	noMoreRoom

		; OK, there is room at the inn.  Store away the file handle
		; and allocate a new stream using the stream driver.
haveOne:
		mov	ds:[fsdArray][si].FSD_file, bx	; save file handle 
		mov	ax, dx				; set ax = buffer size
		call	GeodeGetProcessHandle		; bx = process handle
		clr	cx				; no fixed buffer
		mov	di, DR_STREAM_CREATE
		push	si
		call	StreamStrategy			; bx = stream token
		pop	si
		jc	streamError			; if error, clear out

		; No error from stream driver on creation of new stream.  Cool.
		; store away the unit number and release the semaphore.

		mov	ds:[fsdArray][si].FSD_stream, bx ; store stream handle
		VSem	ds, slotAllocSem

		; Now set up a notification so that we can write out the stream
		; buffer when it gets full.  We are the reader.

		push	si				; save our unit num
		push	dx
		mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
		mov	cx, cs
		mov	dx, offset FilestrCommitData
		mov	bp, si				; pass our unit number
		mov	di, DR_STREAM_SET_NOTIFY
		call	StreamStrategy

		; now that we have setup getting notified, tell the stream 
		; how often to notify us.

		mov	ax, STREAM_READ
		pop	cx				; pass buffer size as
		mov	di, DR_STREAM_SET_THRESHOLD	;  threshold
		call	StreamStrategy

		; we have no error handler.

		mov	ax, StreamNotifyType <1,SNE_ERROR,SNM_NONE>
		mov	bp, si				; pass our unit number
		mov	di, DR_STREAM_SET_NOTIFY
		call	StreamStrategy
		pop	bx				; return our unit #

		clc					; no error here
done:
		.leave
		ret

		; amazing at it may seem, we've allocated four slots.  
noMoreRoom:
		mov	ax, STREAM_CANNOT_ALLOC
streamError:
		VSem	ds, slotAllocSem		; release the semaphore
		stc
		jmp	done

FilestrOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close an open filestr port.

CALLED BY:	DR_STREAM_CLOSE (FilestrStrategy)
PASS:		ds	- dgroup
		bx	- unit number
RETURN:		nothing
DESTROYED:	ax, bx
		ds, es (preserved by FilestrStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilestrClose	proc	near	
		uses di, si, ax, bx, cx, dx
		.enter

		mov	si, bx
		mov	bx, ds:[fsdArray][si].FSD_stream
		mov	di, DR_STREAM_DESTROY
		call	StreamStrategy
		
		mov	ds:[fsdArray][si].FSD_stream, -1	; mark free

		.leave
		ret
FilestrClose	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrSetNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a notifier for the caller. Caller may only set the
		notifier for the writing side of the stream.

CALLED BY:	DR_STREAM_SET_NOTIFY
PASS:		ax	= StreamNotifyType
		bx	= unit number (transformed to FilestrPortData offset by
			  FilestrStrategy).
		cx:dx	= address of handling routine, if SNM_ROUTINE;
			  destination of output if SNM_MESSAGE
		bp	= AX to pass if SNM_ROUTINE (except for SNE_DATA with
			  threshold of 1, in which case value is passed in CX);
			  method to send if SNM_MESSAGE.
RETURN:		nothing
DESTROYED:	bx (saved by FilestrStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilestrSetNotify proc	near
		.enter

		; we don't do no stinkin' reads

		and	ax, not mask SNT_READER
		mov	bx, ds:[fsdArray][bx].FSD_stream
		call	StreamStrategy

		.leave
		ret
FilestrSetNotify endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrCallStreamDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass a call on to the stream driver as the writer of the
		stream.

CALLED BY:	DR_STREAM_GET_ERROR, DR_STREAM_SET_ERROR, DR_STREAM_FLUSH,
       		DR_STREAM_SET_THRESHOLD, DR_STREAM_QUERY
PASS:		bx	= unit number (transformed to FilestrPortData by 
			  FilestrStrategy)
		di	= function code
RETURN:		?
DESTROYED:	bx (saved by FilestrStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilestrCallStreamDriver proc	near
		.enter

		mov	ax, STREAM_WRITE
		mov	bx, ds:[fsdArray][bx].FSD_stream
		call	StreamStrategy

		.leave
		ret
FilestrCallStreamDriver endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read data from a port (ILLEGAL)

CALLED BY:	DR_STREAM_READ
PASS:		bx	= unit number (transformed to FilestrPortData by 
			  FilestrStrategy)
		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		cx	= number of bytes to read
		ds:si	= buffer to which to read
RETURN:		cx	= number of bytes read
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilestrRead	proc	near
EC <		ERROR	CANNOT_READ_FROM_FILESTR_STREAM			>
NEC <		stc							>
NEC <		clr	cx						>
NEC <		ret							>
FilestrRead	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrReadByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a single byte from a port (ILLEGAL)

CALLED BY:	DR_STREAM_READ_BYTE
PASS:		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		bx	= unit number (transformed to FilestrPortData by 
			  FilestrStrategy)
RETURN:		al	= byte read
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilestrReadByte proc	near
EC <		ERROR	CANNOT_READ_FROM_FILESTR_STREAM			>
NEC <		stc							>
NEC <		ret							>
FilestrReadByte endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a buffer to the filestr port.

CALLED BY:	DR_STREAM_WRITE
PASS:		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		bx	= unit number 
		cx	= number of bytes to write
		ds:si	= buffer from which to write (ds moved to es by
			  FilestrStrategy)
		di	= DR_STREAM_WRITE
RETURN:		cx	= number of bytes written
DESTROYED:	bx (preserved by FilestrStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilestrWrite	proc	near
		.enter
		mov	bx, ds:[fsdArray][bx].FSD_stream
		segmov	ds, es		; ds <- buff segment for stream driver
		call	StreamStrategy

		.leave
		ret
FilestrWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrWriteByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a byte to the filestr port.

CALLED BY:	DR_STREAM_WRITE_BYTE
PASS:		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		bx	= unit number
		cl	= byte to write
		di	= DR_STREAM_WRITE_BYTE
RETURN:		carry set if byte could not be written and STREAM_NOBLOCK
		was specified
DESTROYED:	bx (preserved by FilestrStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilestrWriteByte proc	near
		.enter
		mov	bx, ds:[fsdArray][bx].FSD_stream
		call	StreamStrategy
		.leave
		ret
FilestrWriteByte endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilestrCommitData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The stream driver is calling to empty the buffer

CALLED BY:	EXTERNAL
		StreamDriver via a write operation
PASS:		ax	- our unit number
		dx	- virtual segment of moveable StreamData
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilestrCommitData		proc	far
		uses	ds, es, si, di, ax, bx, cx, dx
		.enter

		; lock down the stream

		push	dx				; save virtual seg

		push	ax				; save our unit number
		mov	bx, dx				; bx = virtual seg
		call	MemLockFixedOrMovable
		mov	ds, ax				; ds -> StreamData
		pop	si				; si = our unit number
		
		; gain access to our own data area

		mov	es, cs:[filestrData]		; es -> dgroup

		; setup params for FileWrite.  Need pointer into data stream
		; and size of data to write.  This info is available in the
		; StreamData structure that ds points to.  We need to properly
		; update the semaphores used to keep track of how much data 
		; is in the buffer.

		; Since our threshold is set to the number of bytes in the
		; buffer, we should get the whole stream buffer here, so there
		; is no need to handle a wrap of the data around the buffer.

		mov	dx, ds:[SD_reader].SSD_ptr	; ds:dx -> data to read
		mov	cx, ds:[SD_reader].SSD_sem.Sem_value ; 

		; just to be safe, put in some EC code to check to make sure
		; the data doesn't wrap around

EC <		add	dx, cx				; shouldn't pass max >
EC <		dec 	dx						>
EC <		cmp	dx, ds:[SD_max]			; 		>
EC <		ERROR_A	FILESTR_DATA_BUFFER_WRAPPED	; shouldn't happen >
EC <		inc	dx				; restore pointer >
EC <		sub	dx, cx				;		>

		clr	al				; handle errors
		mov	bx, es:[fsdArray][si].FSD_file	; get file handle
		call	FileWrite
		jc	errorWriting			; need to set error

		; the write was a success.  Deal with updating all the buffer
		; pointers and variables and such.
clearData:
		INT_OFF
		clr	ds:[SD_reader].SSD_sem.Sem_value ; wrote everything
		clr	ds:[SD_reader].SSD_data.SN_ack	; signal read
		add 	ds:[SD_writer].SSD_sem.Sem_value, cx	
	;
	; If anyone lingering to close the thing, wake that person up.
	; XXX: in theory, this could be anyone, and the MemUnlockFixedOrMovable
	; could choke b/c the stream is gone. In reality, we will always be
	; called before StreamDestroy even blocks on SD_closing, so we're ok.
	; 
		test	ds:[SD_state], mask SS_LINGERING
		jz	allDataGone
		
		mov	ax, ds
		mov	bx, offset SD_closing
		call	ThreadWakeUpQueue
allDataGone:
		INT_ON
done:
		pop	bx				; restore virtual seg
		call	MemUnlockFixedOrMovable		; release buffer 
		.leave
		ret

		; set the error in the stream on the writers side.
		; If we're closing the stream, don't bother with the
		; notification, as there will be no one there to hear us.
errorWriting:
		test	ds:[SD_state], mask SS_LINGERING
		jnz	clearData

		mov	bx, es:[fsdArray][si].FSD_stream ; pass unit number
		mov_tr	cx, ax
		mov	ax, STREAM_READ
		mov	di, DR_STREAM_SET_ERROR
		call	StreamStrategy
		jmp	done
FilestrCommitData		endp


Resident	ends







