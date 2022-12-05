COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        PCCom Library
FILE:		pccomFile.asm

AUTHOR:		Cassie Hartzog, Nov 11, 1993

ROUTINES:
	Name			Description
	----			-----------
	FileStartXfer		Begin the file transfer protocol

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	11/11/93	Initial revision


DESCRIPTION:
	The routines in this file handle the VSFTP (Very Simple File Transfer
	Protocol) established for transfering files over dependable
	serial lines.

	$Id: pccomFile.asm,v 1.1 97/04/05 01:25:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Internal/fileStr.def
include	Internal/fsd.def

idata		segment

geosFileHeader	GeosFileHeader

idata		ends

udata		segment

pathname	char 	PATH_BUFFER_SIZE dup(0)
filename	char	FILE_LONGNAME_BUFFER_SIZE dup(0)
fSize		dword	(0)			; bytes remaining in file
readCmd		byte 	(0)
err		byte	(0)
count		word	(0)
general_buf	byte	BUFFER_SIZE dup(0)	; working buffer
nullPath	char	1 dup(0)

iacpConnection	IACPConnection	IACP_NO_CONNECTION

udata		ends


Main		segment	resource

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileStartXfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the file name and transfer command, then
		do the right thing.

CALLED BY:	ParseSeq

PASS:		ds, es - dgroup

RETURN:		Nothing

DESTROYED:	Everything

PSEUDO CODE/STRATEGY:

    File Transfer protocol starts with this for both send and receive:

	<ESC> XF <file transfer command>
	<pathname>
	SYNC	(sent by target)

    Because the serial port may overrun due to some system level problem
    when PCCom is being loaded into memory, the filename may be garbled.
    To be more robust, the sender should send the filename as the first
    block of data which can be resent if it doesn't arrive correctly the
    first time.  This block will begin with a special BLOCK_FILENAME 
    byte, and end with BLOCK_END.  It will be followed by a CRC word.
    
    If the receiver detects one of these special blocks, it should use
    the filename contained in it rather than the first one sent.  If it
    does not receive this special block, it should use the first filename
    unless the SF_BAD_FILENAME flag is set, in which case it should abort.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/15/88		Initial Revision
	cassie	12/93		Modified to be more robust

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
FileStartXfer	proc	near
		savedEchoBack	local	byte	; previous echo back state
		.enter
		
EC <		call	ECCheckDS_dgroup				>
EC <		call	ECCheckES_dgroup				>

		mov	al, ds:[echoBack]	; save the echo back state
		mov	ss:[savedEchoBack], al
		
		mov	ds:[echoBack], 0	; don't echo back to host
		mov	ds:[err], 0		; clear the error flag
	;
	; Get the file transfer command
	;
		call	ComReadWithWait
		LONG	jc	timedOutError
		mov	cl, al
	;
	; Get the file name 
	;
if _DEBUG
		mov	al, 'f'
		call	DebugDisplayChar
endif
		call	ReadIntoPathname
		LONG	jc	timedOutError
		
	;
	; Acknowledge transfer start with SYNC character. Makes
	; sure we're all in sync.
	;
		cmp	ds:[negotiationStatus], PNS_ROBUST
		je	noSync

		mov	al, SYNC
		call	ComWrite
noSync:
		
		cmp	cl, RECV_COMMAND
		jne	FSX2
read:
		mov	ds:[readCmd], cl
		call	FileReceive
		jmp	short FSXReturn
FSX2:
		cmp	cl, FETCH_COMMAND
		jne	FSX3
		mov	al, FILE_SEND_NORMAL
		call	FileSend
		jmp	short FSXReturn
FSX3:
		cmp	cl, RECV_VARIABLE
		je	read
		cmp	cl, FETCH_RAW_COMMAND
		LONG_EC	jne	abortMessage
		
		mov	al, FILE_SEND_RAW
		call	FileSend
		;
		; What to do. What to do...
		;
FSXReturn:
		tst	ds:[err]
		LONG_EC	jnz	abortMessage
		mov	bx, offset xferComplete
		call	ScrWriteStandardString

done:
		mov	di, PCET_NORMAL
		tst	ds:[err]
		jz	endIt
		mov	di, PCET_ERROR

endIt:
	;
	; Close any open IACP connections.
	;
		call	FileEndCommand
	;
	; restore flags, previous echo back state
	;
		andnf	ds:[sysFlags], not RESET_FILE_TRANSFER_FLAGS_MASK
		mov	al, ss:[savedEchoBack]
		mov	ds:[echoBack], al
	
		.leave
		ret

timedOutError:
		mov	bx, offset timeout
		jmp	printErrorMsg
abortMessage:
		mov	bx, offset abortString
printErrorMsg:
		call	ScrWriteStandardString
		mov	ds:[err], 1
		jmp	done

FileStartXfer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileEndCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A file command has completed, so clean up.

CALLED BY:	INTERNAL
PASS:		ds,es - dgroup
		di = command exit type
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	reset serial mode if necessary

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileEndCommand		proc	near
		.enter

EC <		call	ECCheckDS_dgroup				>
EC <		call	ECCheckES_dgroup				>
EC <		cmp	di, PccomCommandExitType			>
EC <		ERROR_AE INVALID_PCCOM_COMMAND_EXIT_TYPE		>
		
	;
	; Check to see if we opened an IACPConnection while trying to create
	; the file, and if so, give the server a chance to reopen the thing
	; now that the transfer's over.
	;
		call	PCComReleaseFileAccess

		call	RobustCollectOn
		call	ScrWriteNewLine
		call	FileWriteCurrentPath	; write the path name
		mov	al, '>'
		call	ScrWrite

		cmp	ds:[echoBack], 0
		je	noEcho
	;
	; echoBack variable is explicitly set and reset by EB command
	; 					- SJ 5/11/94

	; a semi-colon will indicate an end of data
		mov	al, ';'
		call	ScrWrite
noEcho:
	;
 	; Send acknoweldge if ackBack is set
	;
		tst	ds:[ackBack]
		jz	noAck
		cmp	di, PCET_NORMAL
		je	sendAck
		cmp	di, PCET_ERROR
		je	sendNak
sendNak:
		mov	al, 0x1b
		call	ComWrite
		mov	al, 'N'
		call	ComWrite
		mov	al, 'A'
		call	ComWrite
		mov	al, 'K'
		call	ComWrite
	;
	; If in Robust Mode, send an abort code with a NAK.
	;
		cmp	ds:[negotiationStatus], PNS_ROBUST
		jne	continue
		mov	al, ds:[pccomAbortType]
		call	ComWrite
		jmp	continue	
sendAck:
		mov	al, 0x1b
		call	ComWrite
		mov	al, 'A'
		call	ComWrite
		mov	al, 'C'
		call	ComWrite
		mov	al, 'K'
		call	ComWrite		
continue:
noAck:
		call	RobustCollectOff
		mov	ds:filename, 0
		mov	ds:pathname, 0
		call	ComDrainQueue
		
		.leave
		ret
FileEndCommand		endp

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReceive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a file from The Other Side

CALLED BY:	FileStartXfer

PASS:		ds, es - dgroup
		ds:[pathname] - DOS name of file to receive

RETURN:		ds:[err] - zero if no error

DESTROYED:	Lots of things.

PSEUDO CODE/STRATEGY:

For readCmd = RECV_COMMAND, the protocol is:

	get filesize (dword)
	while (filesize > 0) {
		get next byte
		if (SF_READ_FILENAME && byte = BLOCK_FILENAME) {
		    read bytes until BLOCK_END
		    read CRC
		    if CRC okay {
			send sync
			use filename contained in block to create file
			clear SF_READ_FILENAME
		    } else {
			send NAK
			continue
		    }	
		}
		elif byte = BLOCK_START {
		    read bytes until BLOCK_END
		    read CRC
		    if CRC okay {
			filsize = filesize - blocksize
			send sync
		    } else {
			send NAK
			continue
		    }	
		}
	}
	read file checksum (word = 0)
			

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/16/88		Initial Revision
	cassie	12/93		Modified to check for filename in first block

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileReceive	proc	near
tries	local	byte
		.enter	

EC <		call	ECCheckDS_dgroup				>
EC <		call	ECCheckES_dgroup				>
		call	FilePushDir

	;
	; Don't create the file yet.  Wait to see if the first block
	; contains the filename.  This flag will be cleared after the
	; first block is read, by FileReadBlock.
	;
		clr	bx 			; intialize file handle to 0
		ornf	ds:[sysFlags], mask SF_FIRST_BLOCK
	;
	; Check if want to do the robust transfer protocol
	;
		cmp	es:[negotiationStatus], PNS_ROBUST
		jne	varReadLoop
		call	RobustFileReceive
		LONG	jc	cancel
		jmp	fileOpened
	;
	; Read the file size and initialize loop variables.
	;
varReadLoop:
		lea	di, es:[fSize]		; es:di <- fSize
		mov	cx, size fSize
		call	FileReadNBytes		; fsize <- file size
		LONG jc	FRTError		; time out error?

fixedReadLoop:
if _DEBUG
		mov	ax, ds:[fSize].low
		call	DebugDisplayWord
endif
		mov	ax, ds:[fSize].low
		or	ax, ds:[fSize].high
		LONG	jz	readComplete
	;
	; Figure the number of bytes to read this time.
	; This is the size of our buffer, unless there aren't
	; that many bytes left in the file, in which case we read
	; that many.
	;
		mov	ss:[tries], 0
readBlock:
		mov	di, offset general_buf		; es:di <- data buffer
		call	FileReadBlock			; cx <- # bytes read
		jnc	gotBlock

if _DEBUG
		push	ax
		mov	al, 'T'
		call	DebugDisplayChar
		pop	ax
endif

	; If we didn't get the block for some reason, we should send out
	; a request to resend the whole block and try it again.
	; AFTER MAX_TRIES TRIES WE WILL GIVE UP.
	;
		cmp	al, NAK_QUIT		; this is what pccom does
		je	toCancel		; how it gets NAK_QUIT, dunno
				; this gets a NAK_QUIT by recieving it
				; instead of a BLOCK_BEGIN sorta mark
				; it gets passed up through
				; FileReadBlock and the carry is set.
		cmp	ss:[tries], MAX_TRIES
toCancel:
		LONG_EC	je	cancel
		inc	ss:[tries]

EC<		cmp	ds:[negotiationStatus], PNS_ROBUST		>
EC<		ERROR_Z	SHOULD_NOT_BE_IN_ROBUST_MODE_AT_THIS_POINT	>
		mov	dl, NAK
		mov	ax, STREAM_READ		; flush input buffer
		call	FlushBufferSendNAK
		jmp	readBlock

gotBlock:
		test	ds:[sysFlags], mask SF_EXIT or mask SF_JUST_GET_SIZE
		LONG	jnz	cancel

		tst	bx			; was file created?
		LONG	jz	createFile

continue:
	;
	; Put up the next feedback character for the user to see.
	;
		call	SendFeedbackChar
		mov	ss:[tries], 0
	;
	; Write the bytes out. BX already contains file handle.
	; CX contains number of bytes read.
	;
		clr	al			; return errors
		mov	dx, di			; ds:dx <- buffer
		call	PCComFileWrite
		LONG	jc	FRWError
	;
	; Subtract the number of bytes written from the size of
	; the file. If the result goes negative, we may have had
	; problems reading the file size or file data, so abort.
	; If not negative and non-zero, there's more to read.
	;
		sub	ds:[fSize].low, cx
		sbb	ds:[fSize].high, 0
		LONG	js	cancel		

		mov	al, SYNC
		cmp	ds:[readCmd], RECV_COMMAND
		je	ackBlock

	;
	; Compare checksums
	;
		call	FileCompareChecksum
		jc	FRTError		; timeout?
		jne	FRCSError		; bad checksum?
		
		mov	al, ACK
ackBlock:
		call	ComWrite

		mov	cl, PCCRT_TRANSFER_CONTINUES
		call	SendStatus
	;
	; Jump back to the proper place in the loop, based on whether we
	; know the absolute size of the file, as evidenced by the command
	; we stored in FileStartXfer
	;
		cmp	ds:[readCmd], RECV_COMMAND
		LONG	je 	fixedReadLoop
		jmp	varReadLoop

FRWError:
		push	bx
		mov	bx, offset writeErr
		jmp	FRError
FRCSError:
		push	bx
		mov	bx, offset csErr
		jmp	FRError
FRTError:
		push	bx
		mov	bx, offset timeout
FRError:
		call	ScrWriteStandardString
		pop	bx
cancel:
		tst	bx			; does file need to be closed?
		jz	notOpenDelete		; no, just delete it
		clr	al			; return errors
		call	FileClose
notOpenDelete:
	;
	; now, delete the file (even if we never opened it..  it's the
	; expected behavior..  if you abort you end up with nothing, not
	; the old copy) unless we are just getting the size.
	;
		test	ds:[sysFlags], mask SF_JUST_GET_SIZE
		jnz	noDelete
		mov	dx, offset filename	; ds:dx - filename
		call	FileDelete
noDelete:
if	_DEBUG
		mov	al, 'X'
		call	DebugDisplayChar
endif
	;
	; Flush the output buffer before writing NAK_QUIT,
	; because the other side doesn't always seem to get it.
	;
		mov	ds:[err], 1
		mov	ax, STREAM_WRITE
		mov	dl, NAK_QUIT
		call	FlushBufferSendNAK
if	_DEBUG
		mov	al, 'Z'
		call	DebugDisplayChar
endif
		jmp	done

readComplete:
if	_DEBUG
		mov	al, '0'
		call	DebugDisplayChar
endif
	;
	; File has been completely read. If command was RECV_COMMAND, we've
	; an overall checksum to verify before we can acknowledge the file.
	;
		cmp	ds:[readCmd], RECV_COMMAND
		jne	closeFile

		call	FileCompareChecksum	; (vestigial checksum, = 0)
		jc	FRTError		; timeout reading checksum?
		jne	FRCSError		; bad checksum?

closeFile:
		tst	bx		; if never opened the file (i.e.
		jnz	fileOpened	;  fSize == 0)
		push	dx
		call	FileReceiveStart
		pop	dx
fileOpened:
		test 	ds:[sysFlags], mask SF_GEOS_FILE
		clc
		jz	noAttrs
		call	SetFileExtAttributes
noAttrs:		
		clr	al		; return errors
		call	FileClose	; carry set if error closing it
		mov	bx, 0		; so don't try to close it again...
		LONG_EC jc	FRWError

	;
	; ok.  We're done..  we've received the file.  Now, did the
	; user want to abort?  If so, delete the file and do the abort
	; thang..  else continue and say we're done
	;
		test	ds:[sysFlags], mask SF_EXIT
		LONG_EC	jnz	notOpenDelete

		mov	al, ACK		; success!

		mov	cl, PCCRT_FILE_COMPLETE
		call	SendStatus

		cmp	es:[negotiationStatus], PNS_ROBUST
		je	done
		call	ComWrite	; Send response

done:
		call	FilePopDir
	;
	; We may have grabbed the IACP connection earlier, so release
	; it now.  No need to worry if, we didn't,  because
	; PCComreleaseFileAccess will check; so just call it.
	;
		call	PCComReleaseFileAccess

		.leave
		ret

createFile:

	;
	; If we still haven't read the first data block, continue.
	;
		test	ds:[sysFlags], mask SF_FIRST_BLOCK
		jnz	getDataBlock
	;
	; we should have a valid filename now, so copy the filename
	; into the datablock 
	;
		call	CopyPathnameToDataBlock
	;
	; Change to destination directory and create destination file
	;
		call	FileReceiveStart	; bx <- file handle,
						; es:di <- data buffer
						; cx <- # data bytes
		LONG	jc	cancel
		LONG	jmp	continue

getDataBlock:
	;
	; We need to acknowledge receipt of the first block here,
	; since we will be going to the start of the loop and it
	; it would not be acknowledged there.  
	;
		mov	al, SYNC		; send a SYNC
		call	ComWrite
	;
	; Jump back to the proper loop, based on whether we know the
	; absolute size of the file, as evidenced by the command
	; (net-based xfer uses RECV_VARIABLE)
	;
		cmp	ds:[readCmd], RECV_COMMAND	
		LONG	je 	fixedReadLoop
		LONG	jmp	varReadLoop


FileReceive	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReceiveStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start of file receive, whether for variable or
		known-length file...

CALLED BY:	FileReceive, FileReceiveVariable
PASS:		pathname - pathname of file being sent from other side
		ds, es - dgroup
RETURN:		carry set if destination file couldn't be created
			bx = 0
		carry clear if file was created
			^bx	= destination file
			pathname = destination file's path,
				current directory set to this path
			filename = name of destination file
		ds, es - dgroup
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	(See called routines for side-effects.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/90		Initial version
	PT	5/01/96		Moved IACP code to PCComFileDelete and
					FileReceiveStartCreateFile

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileReceiveStart proc	near
		uses	cx,di,bp
		.enter

		mov	cl, PCCRT_FILE_STARTING
		call	SendStatus
	;
	; If we know the filename is bad because we detected problems
	; while recieving it, and the first block did not contain the
	; filename, just abort.
	;
		mov	cx, offset filenameError
		test	ds:[sysFlags], mask SF_BAD_FILENAME
		LONG	jnz	writeError

		call	FindTail	

	;
	; change to path of file
	;
		clr	bx			; absolute path
		clr	al
		mov	dx, offset pathname
		call	PCComFileSetCurrentPath
		mov	cx, offset createError
		LONG_EC	jc	error		; XXX: create missing dirs
	;
	; If it is a geos file, use the file longname for all subsequent
	; operations.  
	;
		mov	dx, offset filename
		test	ds:[sysFlags], mask SF_GEOS_FILE
		jz	haveFileName
		test	ds:[sysFlags], mask SF_USE_DOS_NAME
		jnz	haveFileName
		mov	dx, offset GFH_longName + GFH_OFFSET
haveFileName:
	;
	; Tell the user what file we're receiving
	;	ds:dx - filename
	;
		mov	bx, offset receiving
		call	ScrWriteStandardString
		mov	si, dx
		call	ScrWriteString

	;
	; Create the file. We'll delete the thing first, because the
	; caveat in the header of FileCreate about ERROR_FILE_FORMAT_MISMATCH
	; keeps happening here, and this seems a reasonable thing to do, since
	; we're opening FILE_CREATE_TRUNCATE, anyways, so...
	;	ds:dx - filename
	;
		mov	bp, TRUE		; gain file access
		call	PCComFileDelete
		mov	cx, offset createError
		jc	deleteError

continueCreatingFile:
		call	FileReceiveStartCreateFile
		mov	cx, offset createError
		jc	error

		mov_tr	bx, ax			; ^hbx <- file 
done:
	;
	; our work here is done..
	;
		lahf				; preserve CF
		BitClr	ds:[sysFlags], SF_USE_DOS_NAME
		sahf				; restore CF

		.leave
		ret

deleteError:
	;
	; If ERROR_FILE_NOT_FOUND, then it's acceptable, because the
	; file has yet been created yet.
	;
		cmp	ax, ERROR_FILE_NOT_FOUND
		je	continueCreatingFile

error:
	;
	; Print the error code and an error message, then send a NAK back
	; to the host (to signal the failure) before returning carry set.
	; 
		call	ScrWriteNewLine
		call	ScrPrintByte
writeError:
		BitSet	ds:[sysFlags], SF_EXIT

		mov	bx, cx 				; bx <- error
		call	ScrWriteStandardString
		clr	bx
		stc
		jmp	done

FileReceiveStart endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReceiveStartCreateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a file

CALLED BY:	FileReceiveStart
PASS:		ds:dx - file name:
			if SF_GEOS_FILE clear, DOS name (in dgroup::filename)
			if SF_GEOS_FILE set, GEOS longname
RETURN:		carry clear if no error,
			ax = file handle
		carry set if error
			ax = FileError
DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/ 5/95		Initial version
	PT	4/29/96		Re-try file creation on sharing violation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileReceiveStartCreateFile		proc	near
		uses	bp
		.enter

		mov	si, dx			; ds:si <- passed name
	;
	; If it is a DOS file, use the DOS filename passed in the
	; file get command.
	;
		mov	dx, offset filename
		mov     ah, mask FCF_NATIVE or \
			    	(FILE_CREATE_TRUNCATE shl offset FCF_MODE)
		test	ds:[sysFlags], mask SF_GEOS_FILE
		jz	create
	;
	; It's a geos file. If not a data file (no numeric extension),
	; use the DOS name, but create the file with extended attrs.
	;	ds:dx = DOS name
	;
		call	CheckForNumericExtension
		mov     ah, mask FCF_NATIVE_WITH_EXT_ATTRS or \
			    	(FILE_CREATE_TRUNCATE shl offset FCF_MODE)
		jc	create			; no numeric extension
	;
	; If we really, really want to use a dos name, we should say
	; so..
	;
		test	ds:[sysFlags], mask SF_USE_DOS_NAME
		jnz	create
	;
	; Else use the longname, which is in ds:si, and don't
	; create in native mode.
	;
		mov	dx, si			; ds:dx <- file longname
		clr	ah			; no native mode
create:
		mov	al, FILE_DENY_RW or FILE_ACCESS_W
		mov	cx, FILE_ATTR_NORMAL
		mov	bp, TRUE		; gain file access
		call	PCComFileCreate

		.leave
		ret
FileReceiveStartCreateFile		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForNumericExtension
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check a DOS filename for a numeric extension

CALLED BY:	FileReceiveStartCreateFile
PASS:		ds:dx - DOS filename (DBCS)
RETURN:		carry clear if filename has numeric extension
DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForNumericExtension		proc	near
		uses	ax, si, es
		.enter
	;
	; If filename is longer than DOS filename length, it can't
	; have a numeric extension.
	;
		segmov	es, ds, ax
		mov	di, dx			; es:di <- filename
SBCS<		call	LocalStringLength	; cx <- number of
						; chars	without the null>
DBCS<		call	PCComDBCSStringLength					>
		cmp	cx, DOS_DOT_FILE_NAME_LENGTH
		ja	setCarry
	;
	; Find the DOS 'dot'
	;
		mov	al, '.'
		repne	scasb			; Search for next one
		jne	setCarry		; No more => done
	;
	; Check for numeric extension
	;
SBCS<		clr	ah						>
DBCS<		mov	ah, '9'						>
		mov	si, di
digitLoop:
		lodsb
SBCS<		call	LocalIsDigit					>
SBCS<		jz	setCarry					>
DBCS<		cmp	ah, al		; if char > '9' not a digit	>
DBCS<		jc	done						>
DBCS<		cmp	al, '0'		; if char < '0' not a digit	>
DBCS<		jc	done						>
		loop	digitLoop
		clc
		jmp	done
setCarry:
		stc
done:
		.leave
		ret
CheckForNumericExtension		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PCComGainFileAccess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to gain file access to the passed file by making
		an IACP connection to the file's server, and asking nicely.

CALLED BY:	FileReceiveStart

PASS:		ds:dx - directory name
		ds:si - file name
		bx - disk handle

RETURN:		Carry set if error
			bp - IACP_NO_CONNECTION
		Carry clear if connection established and file access requested
			bp - IACPConnection

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 feb 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComGainFileAccess	proc	far
		uses	ax, bx, cx, dx, di, si
		.enter

		mov	di, dx
		push 	{word}ds:[di]			; save pathname chars
		push	di
		mov 	{word}ds:[di], 0		; pretend no path
	;
	;  See if there's a server for this file. If there isn't, we're SOL.
	;
		mov	ax, 0				; no passed OD
		call	IACPConnectToDocumentServer
		jc	noConnection
	;
	;  Record the message to ask for file access.
	;
		mov	bx, segment MetaClass
		mov	si, offset MetaClass
		mov	ax, MSG_META_IACP_ALLOW_FILE_ACCESS
		mov	di, mask MF_RECORD
		call	ObjMessage

		mov	bx, di				; bx <- access msg.
		clr	cx				; no completion msg
		mov	dx, TO_APP_MODEL
		mov	ax, IACPS_CLIENT
		call	IACPSendMessageAndWait
		clc					; success!

done:
		pop	di
		pop 	{word}ds:[di]			; restore pathname
		.leave
		ret
noConnection:
		mov	bp, IACP_NO_CONNECTION
		jmp	done
PCComGainFileAccess	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PCComReleaseFileAccess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell an IACP document server that we're done with its file.

Note: It's possible for the server to simply shut down in order to
release its grip on the file, in which case I would expect it to call
IACPShutdown, which I thought would kill the connection, and that the
call to IACPSendMessage below would die because of it. However, I've
never been able to make this happen, so I'm foregoing the work to set
up a queue to receive LOST_CONNECT messages, check for 'em, and zero
out iacpConnection if I find 'em.  -jon 6 feb 95

PASS:		es:[iacpConnection] - contains iacp connection, if any

RETURN:		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 feb 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComReleaseFileAccess	proc	far
		uses	ax, bx, cx, dx, bp, di, si
		.enter

EC <		call	ECCheckES_dgroup				>
		
	;
	;  No connection means we're done.
	;
		mov	bp, es:[iacpConnection]
		cmp	bp, IACP_NO_CONNECTION
		je	done

	;
	;  An IACP connection exists, so send the reopen file message
	;
		mov	bx, segment MetaClass
		mov	si, offset MetaClass
		mov	ax, MSG_META_IACP_NOTIFY_FILE_ACCESS_FINISHED
		mov	di, mask MF_RECORD
		call	ObjMessage

		mov	bx, di
		clr	cx
		mov	dx, TO_APP_MODEL
		mov	ax, IACPS_CLIENT
		call	IACPSendMessage

	;
	;  The connection has served it's purpose... nuke it.
	;
		clr	cx				; we're not only
							; the IACP president,
							; but we're also a
							; client. -jon, 6feb95
		call	IACPShutdown
		mov	es:[iacpConnection], IACP_NO_CONNECTION
done:
		.leave
		ret
PCComReleaseFileAccess	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send one or more files to the remote side.

CALLED BY:	(INTERNAL) FileStartXfer, PCComPCSend

PASS:		ds, es - dgroup
		es:[pathname] - DOS name/pattern to send in remote DOS code page
		es:[destname] - optional destination filename in the 
				remote DOS code page.
		al = FILE_SEND_NORMAL : normal	
		al = FILE_SEND_RAW : raw mode
		al = FILE_SEND_ACTIVE : active send
		sysFlags - SF_BAD_FILENAME set if possible error while 
			   reading filename.
RETURN:		es:[err] - zero if no error

DESTROYED:	Everything except ds
SIDE EFFECTS:	
		dgroup:[pathname] is trashed

PSEUDO CODE/STRATEGY:
	The protocol the remote side expects is as follows:
		After pathname is sent, wait for sync byte
		loop:
			get next byte
			if byte not RECV_COMMAND, transfer complete
			receive pathname
			send sync byte
			receive file size
			receive data in 1K blocks with CRC sending a sync or
				NAK or NAK_QUIT byte after each
			receive checksum (ignored)
			send ACK if ok, NAK if not. NAK aborts transfer.
		:pool
			

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/16/88		Initial Revision
	jimmy	8/92		added raw mode

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
if FULL_EXECUTE_IN_PLACE
FileExtAttrXIP	segment resource
endif

returnAttrs	FileExtAttrDesc \
	<FEA_NAME, FSRA_name, size FSRA_name>,
	<FEA_DOS_NAME, FSRA_dosname, size FSRA_dosname>,
	<FEA_SIZE, FSRA_size, size FSRA_size>,
	<FEA_FILE_TYPE, FSRA_type, size FSRA_type>,
	<FEA_END_OF_LIST>

if FULL_EXECUTE_IN_PLACE
FileExtAttrXIP	ends
endif

SearchFlags	equ	FILE_ENUM_ALL_FILE_TYPES or mask FESF_CALLBACK

if FULL_EXECUTE_IN_PLACE

fep	FileEnumParams <
	SearchFlags,		 			; FEP_searchFlags
	returnAttrs,					; FEP_returnAttrs
	size FileSendReturnAttrs,			; FEP_returnSize
	0,						; FEP_matchAttrs
	FE_BUFSIZE_UNLIMITED,				; FEP_bufSize
	0,						; FEP_skipCount
	PCComFileEnumCallback,				; FEP_callback
	0,						; FEP_callbackAttrs
	0,						; FEP_cbData1
	1,						; FEP_cbData2 
	0						; FEP_headerSize
>

else

fep	FileEnumParams <
	SearchFlags,		 			; FEP_searchFlags
	returnAttrs,					; FEP_returnAttrs
	size FileSendReturnAttrs,			; FEP_returnSize
	0,						; FEP_matchAttrs
	FE_BUFSIZE_UNLIMITED,				; FEP_bufSize
	0,						; FEP_skipCount
	PCComFileEnumCallback,				; FEP_callback
	0,						; FEP_callbackAttrs
	0,						; FEP_cbData1
	1,						; FEP_cbData2 
	0						; FEP_headerSize
>

endif

FileSend	proc	near
rawMode		local	byte
fileCount	local	word
returnBlock	local	hptr.MemHandle
		.enter
		push	ds
		mov	ss:[rawMode], al
		clr	ss:[returnBlock]

EC <		call	ECCheckES_dgroup				>
EC <		call	ECCheckDS_dgroup				>

		call	FilePushDir
		call	FindTail		; pathname <- directory path
						; filename <- source filename

		test	ds:[sysFlags], mask SF_BAD_FILENAME
		mov	bx, offset filenameError
		LONG	jnz 	displayError
		
		tst	{byte}ds:[pathname]	; check for no path
		jz	noPath
	;
	; Change to source directory.
	;
	; First we need to convert the directory path from the remote DOS 
	; code page to the Geos character set since that's what
	; PCComFileSetCurrentPath is expecting.
	;
		mov	si, offset pathname	; ds:si - pathname		
		clr	cx			; null terminated
SBCS<		call	PCComDosToGeos				>
		clr	bx			; relative path
		mov	dx, offset pathname	; ds:dx - pathname
		call	PCComFileSetCurrentPath
		LONG 	jc	matchError
		mov	ds:[pathname], 0	; no pathname needed now
noPath:		
	;
	; Check if we have a wild-name.  If there are no wildcard
	; chars there's no point wasting our time with a fileenum.
	;
		call	CheckForWildCards
		jz	doEnum
	;
	; OK, fake the file-enum.  This is MUCH faster on a flash
	; device with lots of files in the directory
	;
		mov	ax, size FileSendReturnAttrs
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	toMatchError

		mov	ss:[fileCount],1
		mov	ss:[returnBlock], bx
	;
	; copy the filename over
	;
		mov	es, ax
		mov	di, offset FSRA_name
		mov	si, offset filename
		mov	cx, size FSRA_name
		rep movsb

		mov	si, offset filename
		mov	di, offset FSRA_dosname
		mov	cx, size FSRA_dosname
		rep movsb

		clr	di
		mov	si, di
		segxchg	es, ds			; es - dgroup, ds - block
						; ds:di <- FSRA
SBCS<		call	PCComDosToGeos		>; we need it in geos chars..
DBCS<		mov	si, offset FSRA_dosname	>
DBCS<		call	ScrDBCStoSBCS		>
		jmp	FS1

toMatchError:
		jmp	matchError
doEnum:
	;
	; Set up the FileEnumParams and enumerate
	;
NOFXIP <	mov	cs:[fep].FEP_cbData1.high, ds			>
NOFXIP <	mov	cs:[fep].FEP_cbData1.low, offset filename	>
		segmov	ds, cs, ax
		mov	si, offset fep
		call	FileEnumPtr		; cx <- # matches in buffer
						; dx <- # matches wouldn't fit
		mov	ss:[returnBlock], bx
		mov	ss:[fileCount], cx

		jc	toMatchError
		jcxz	toMatchError	; no matches?
EC <		tst	dx						>
EC <		ERROR_NZ TOO_MANY_FILES_IN_FILE_ENUM			>
		
		call	MemLock
		mov	ds, ax
		clr	di			; ds:di <- first FSRA
FS1:
	;
	; Give the user a chance to abort
	;
		test	es:[sysFlags], mask SF_EXIT
		mov	ah, PCCAT_EXTERNAL_ABORT
		jz	readyForFileName

FSAbort:
		call	PCComPushAbortTypeES
FSAbortPushDone:
		mov	cl, PCCRT_COMMAND_ABORTED
		mov	al, NAK_QUIT
		jmp	FSDone

	;
	; Copy the filename onto the tail and tell the user it is being sent
	; 
readyForFileName:
		lea	si, ds:[di].FSRA_dosname; ds:si <- file name
		mov	dx, si			; ds:dx <- filename

		mov	bx, offset sending
		call	ScrWriteStandardString
		call	ScrWriteString

	;
	; Try to open the file
	;
		push	ds, di
		lea	si, ds:[di].FSRA_name	; we used to use the
						; dosname, but that
						; has been translated
						; to DOS.  Fileopen
						; wants geos-chars.
		mov	di, offset filename	; es:di <- filename buffer
SBCS<		LocalCopyString	SAVE_REGS	; copy name to dgroup	>
DBCS<		call	PCComCopyString					>
		segmov	ds, es, ax
		mov	si, di			; ds:si <- filename
		call	FileSendOpenFile	; ax <- file handle or error
		pop	ds, di

	;
	; Get ready to send the file
	; 
		pushf
		mov	bx, ax		; bx <- file handle

		cmp	rawMode, FILE_SEND_ACTIVE
		je	doActiveStuff
		mov	al, SYNC		; Send Sync byte
		call	ComWrite
		jmp	postFileOpen

doActiveStuff:
		call	RobustCollectOnES
		mov	ax, FILE_TRANSFER_COMMAND
		segxchg	ds, es
		call	PCComSendCommand
		segxchg	ds, es
		mov	al, RECV_COMMAND
		call	ComWrite
		call	RobustCollectOffES

postFileOpen:
	;
	; Now handle errors from the file open
	;
		popf
		LONG	jc	openError

		push	di
		lea	si, ds:[di].FSRA_dosname
		mov	di, offset filename
SBCS<		LocalCopyString	SAVE_REGS				>
DBCS<		call	PCComCopyString					>
		pop	di		
FS2::
	;
	; Files that were in use when this request came may not have
	; been flushed to disk until we yelled at the owner in
	; FileSendOpenFile.  This means that the FSRA_size may be
	; wrong.  Now that we've got the file, we can get the correct
	; size.. 
	;
		push	dx
		call	FileSize
		movdw	ds:[di].FSRA_size, dxax
		pop	dx

		cmp	es:[negotiationStatus], PNS_ROBUST
		jne	notRobust
		call	RobustFileSend
		jmp	fileSent
notRobust:
	;
	; Now have open handle in BX. Figure out what type of file
	; it is and its size, send the RECV command, and file name.
	; Wait for sync byte, then send size, and transfer the file
	; using the appropriate function.
	;
		cmp	rawMode, FILE_SEND_NORMAL
		je	getFileType

	;
	; now set up binary routine
	;
		mov	ax, offset FileSendBinary
		jmp	haveFileType
getFileType:
		lea	si, ds:[di].FSRA_size
		call	FileType	; FSRA_size <- # bytes to transfer
		LONG	jc	closeExit

haveFileType:
	;
	; Give the user a chance to abort before pushing ax, bx
	;
		test	es:[sysFlags], mask SF_EXIT
		LONG	jnz	externalAbort

		push	ax		; save transfer function
		push	bx		; and handle

		cmp	rawMode, FILE_SEND_ACTIVE
		je	dontSendRECV

		mov	al, RECV_COMMAND
		call	ComWrite	; Command byte
dontSendRECV:		
	;
	; Send tail of file name w/zero byte.  This will either be
	; stored in FSRA_name, or we could be renaming this file in
	; which case the new name is in destname.  Check and see if
	; anything is in destname, and use it if so.
	; 
		call	RobustCollectOnES
		tst	es:[destname]
		jz	continue
		push	ds
		segmov	ds, es, ax
		mov	si, offset destname
		jmp	FS3
continue:
		lea	si, ds:[di].FSRA_dosname; ds:si <- file name
FS3:
		lodsb
		call	ComWrite
		tst	al
		jnz	FS3

		call	RobustCollectOffES
		tst	es:[destname]
		jz	nofixup
		clr	{byte}es:[destname]
		pop	ds
nofixup:
	;
	; Wait for host's response
	; 
		call	Sync
		jc	syncError		; timed out?
		cmp	al, SYNC		; right char?
		je	FS4
syncError:
	;
	; Due to a timeout
	;
		mov	ah, PCCAT_CONNECTION_LOST
		call	PCComPushAbortTypeES
	;
	; Clear up stack and close the handle before aborting...
	;
		
		pop	bx
		pop	ax
toSendError:
		jmp	sendError

FS4:
if _DEBUG	
		mov	al, 'S'
		call	DebugDisplayChar
		mov	ax, ds:[di].FSRA_size.high
		call	DebugDisplayWord
		mov	ax, ds:[di].FSRA_size.low
		call	DebugDisplayWord
endif
		
		lea	si, ds:[di].FSRA_size
		mov	cx, size FSRA_size
		movdw	bxax, ds:[si]	; grab the filesize and store
		movdw	es:[fSize], bxax; it away!
		call	ComWriteBlock
		
		pop	bx		; Restore handle
		pop	ax		; and transfer function

	;
	; Now that ax, bx have been popped, see if user wants to abort
	;
		test	es:[sysFlags], mask SF_EXIT
		LONG	jnz	externalAbort

		call	ax		; Transfer per file type
fileSent:
		jc	toSendError

	;
	;  Close the file, and if an IACP connection is active,
	;  tell the server we're done
	;
		clr	al			; return errors
		call	FileClose
		call	PCComReleaseFileAccess
	;
	; Go to the next entry and start the whole process again.
	;
		add	di, size FileSendReturnAttrs
		dec	ss:[fileCount]
		LONG	jnz	FS1		; More to come

		mov	al, END_COMMAND
		mov	cl, PCCRT_TRANSFER_COMPLETE
FSDone:
	;
	; Tell the other side we're done sending all the files.
	; 
	; If we are doing an active command, they aren't expecting an
	; END_COMMAND
	;
		cmp	rawMode, FILE_SEND_ACTIVE
		je	dontSendEndThingy
	;
	; We don't want to send an abort in the following cases:
	; 	If we are in robust mode.
	; 	If we have actually aborted, ie. (err != 0 && SF_EXIT set)
	;
		cmp	es:[negotiationStatus], PNS_ROBUST
		jne	sendEndThingy
		tst	es:[err]
		jz	sendEndThingy
		test	es:[sysFlags], mask SF_EXIT
		jnz	dontSendEndThingy
sendEndThingy:
		call	ComWrite
dontSendEndThingy:		
		mov	bx, ss:[returnBlock]
		tst	bx
		jz	noFree
		call	MemFree
noFree:
		call	FilePopDir

		pop	ds
		call	SendStatus
		.leave
		ret

matchError:
	;
	; Either FileEnumPtr didn't find any matches, or when we tried
	; to open a file whose name was returned by FileEnumPtr in the
	; FSRA block, it could not be found.
	;
		mov	bx, offset noSuchFile
displayError:		
		call	ScrWriteStandardString
		mov	es:[err], 1
		mov	ah, PCCAT_FILE_NOT_FOUND
		jmp	FSAbort

openError:
	;
	; Couldn't open -- report error to user and abort transfer.
	; The error must be pretty serious for the match to have
	; succeeded but we can't open it, unless MS-DOS is brain-
	; damaged...hmmm.
	;
	; 	ax - FileError
	;	ds:si - filename
	; 
		call	ScrWriteNewLine
		call	ScrPrintByte		; print FileError code
		mov	bx, offset cantOpen
		call	ScrWriteStandardString
		mov	cl, PCCRT_COMMAND_ABORTED
		mov	al, NAK_QUIT
		call	ComWrite
		mov	es:[err], 1		; so base mode knows
						; of the problem
		jmp	dontSendEndThingy
		
sendError:
		push	bx
		mov	bx, offset transmitError
		call	ScrWriteStandardString
		mov	es:[err], 1
		pop	bx
		jmp	closeExit

externalAbort:
		mov	ah, PCCAT_EXTERNAL_ABORT
		call	PCComPushAbortTypeES
closeExit:
	;
	; Close the file. The IACP will also be closed in
	; FileEndCommand, but in active ops that's never hit..
	; besides, it doesn't hurt to be redunant
	;
		clr	al			; return errors
		call	FileClose
		call	PCComReleaseFileAccess
		jmp	FSAbortPushDone
		
FileSend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendOpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the file that is to be sent

CALLED BY:	FileSend, FileOp2Common
PASS:		ds:si = filename
		dgroup::pathname = relative path of file
		ds = dgroup
RETURN:		carry clear if file was opened
			ax = file handle
		carry set if error opening file
			ax = FileError
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		(See PCComFileOpen.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/17/95		Initial version
	PT	4/26/96		Modify to use PCComFileOpen

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSendOpenFile		proc	near
		uses	dx, bp, es
		.enter

EC <		call	ECCheckDS_dgroup				>
		segmov	es, ds, dx		; es <- pccom dgroup
		mov	dx, si			; ds:dx, <- filename
		mov	al, FILE_DENY_RW or FILE_ACCESS_R or mask FFAF_RAW
		mov	bp, TRUE		; gain file access
		call	PCComFileOpen		; ax <- file handle

		.leave
		ret
FileSendOpenFile		endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendBinary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a file as 8-bit binary data.

CALLED BY:	FileSend
PASS:		bx - handle of file
		es - dgroup
RETURN:		Nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
	Read the file in 1K blocks and write them until we hit EOF, summing
	all the bytes into a single-word checksum. After each block we
	synchronize with the host.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/24/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
FileSendBinary	proc	near
tries	local	word
bSize	local	word
		uses	cx, ds
		.enter

EC <		call	ECCheckES_dgroup				>
		segmov	ds, es, ax

		mov	cl, PCCRT_FILE_STARTING
		call	SendStatus
FSB1:
		mov	ss:[tries], 0
		call	SendFeedbackChar

	;
	; Read the next block
	;
		mov	dx, offset general_buf	; ds:dx <- buffer
		mov	cx, size general_buf
		call	PCComFileRead
		mov	ss:[bSize], cx
if _DEBUG
		pushf
		push	ax
		mov	al, 'R'
		call	DebugDisplayChar
		mov	ax, cx
		call	DebugDisplayWord
		pop	ax
		popf
endif
		LONG_EC jc	FSBRet		; if error, return

sendBlock:
		LONG_EC	jcxz	FSBDone		; 0 => EOF
		mov	si, offset general_buf
		push	bx		; save file handle
		call	WriteDataBlock	; Write the whole block at once
		pop	bx		; restore file handle	
	;
	; Wait for the other side to say the packet got there.
	; 
		test	ds:[sysFlags], mask SF_EXIT
		LONG_EC	jnz	abort

		call	Sync
		jc	tryAgain		; timeout
		cmp	al, NAK
		je	tryAgain		; rejected
		cmp	al, NAK_QUIT
		LONG_EC	je	error		; give up

		sub	{word}ds:[fSize], cx
		sbb	{word}ds:[fSize+2], 0
		mov	cl, PCCRT_TRANSFER_CONTINUES
		call	SendStatus

		jmp	FSB1			; do next block

tryAgain:
	;
	; only try so many times, then give up
	;
		cmp	ss:[tries], MAX_TRIES
		je	error
		inc	ss:[tries]
		mov	cx, ss:[bSize]
		jmp	sendBlock
FSBDone:
	;
	; Always write a 0 checksum as the other side doesn't care about it.
	; 
		call	RobustCollectOn
		clr	al
		call	ComWrite
		call	ComWrite
		call	RobustCollectOff
FSB3:
	; 
	; Wait for the final ACK
	;
		call	ComRead
		jc	FSB3

		cmp	al, ACK			; al <- ACK from other side
		jne	error
		mov	cl, PCCRT_FILE_COMPLETE
		call	SendStatus
		clc
FSBRet:
		.leave
		ret
abort:
		call	Sync			; wait for the right
						; moment to send the
						; NAK_QUIT or the
						; remote won't
						; interpret it properly
		mov	ax, STREAM_WRITE
		mov	dl, NAK_QUIT
		call	FlushBufferSendNAK
error:
		stc
		jmp	FSBRet

FileSendBinary	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a file as text, mapping ^M^J sequences into just ^J

CALLED BY:	FileSend
PASS:		BX	= handle of file
		es	= dgroup
RETURN:		carry set if error
DESTROYED:	AX, CX, DX, block

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/24/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
FileSendText	proc	near
crc		local	word
file		local	word	
tries		local	word
blockPos	local	dword		; position of first byte in current
					;  packet within the file
		uses	bx, ds
		.enter

EC <		call	ECCheckES_dgroup				>
		segmov	ds, es, ax
		mov	file, bx
		clr	cx		; none left from previous block

startBlock:	; send another block
	;------------------------------------------------------------
	;
	;		PACKET LOOP
	;
		call	RobustCollectOn

		mov	crc, 0
		mov	tries, 0
		
	;
	; Record the current position, in case we have to retransmit the
	; block.
	; 
		push	cx
		mov	bx, file
		clr	cx, dx
		mov	al, FILE_POS_RELATIVE
		call	FilePos
		movdw	ss:[blockPos], dxax
		pop	cx

	;
	; first send off the start character
	;
		mov	al, BLOCK_START
		call	ComWrite

	;
	; Start sending a block of characters. 
	;
		mov	ds:[count], BUFFER_SIZE	; Initialize output count
		tst	cx
		jnz	short FSTProcess; Characters left from last block --
					; go process them.
	;------------------------------------------------------------
	;
	;		BUFFER LOOP
	;
FSTNextBuffer:
	; send next chunk of data (not neccessarily a "block")
	;
	; Get the next buffer of data from the the file
	;
		mov	dx, offset general_buf
		mov	si, dx
		mov	cx, size general_buf
		mov	bx, file
		call	PCComFileRead		; cx <- # of bytes read
		LONG jc	error
		LONG_EC	jcxz	FSTDone		; 0 count => EOF
	;
	; Go through the block we just got ignoring carriage returns
	; and summing everything else into the checksum in dx. We
	; stop looping when either we run out of characters or we've
	; completed the current output block (count goes to 0)
	;
FSTProcess:
		clr	ah		; 0-extend the characters
FSTProcLoop:
		lodsb

		cmp	al, cr
		jne	processChar
		loop	FSTProcLoop
		jmp	FSTNextBuffer

processChar:
		mov_tr	bx, ax		; bl <- char
		mov	ax, crc
		call	IncCRC		; update CRC
		mov	crc, ax
		mov_tr	ax, bx		; al <- char again
	;
	; Take care of quoting characters that need quoting.
	; 
		cmp	al, BLOCK_START
		je	specialChar
		cmp	al, BLOCK_END
		je	specialChar
		cmp	al, BLOCK_QUOTE
		jne	sendChar

specialChar:
	;
	; we have a special char, so we must quote it. First comes the
	; quote character, then the quoted form of this character.
	;
		push	ax
		mov	al, BLOCK_QUOTE
		call	ComWrite
		pop	ax
	.assert (BLOCK_END eq BLOCK_START+1) and \
		   (BLOCK_END_DATA eq BLOCK_START_DATA+1)
	.assert (BLOCK_QUOTE eq BLOCK_END+1) and \
		   (BLOCK_QUOTE_DATA eq BLOCK_END_DATA+1)

		add	al, BLOCK_START_DATA - BLOCK_START
sendChar:
		call	ComWrite

		dec	ds:[count]	; another byte used in the *packet*
		loopnz	FSTProcLoop
		LONG_EC	jnz	FSTNextBuffer	; Ran out of characters -- fetch
					; next block.
	;
	; Output block complete -- synchronize with host and jump
	; to the top of our loop to reset count
	;
if _DEBUG
		mov	al, 'D'
		call	DebugDisplayChar
endif
		mov	al, BLOCK_END
		call	ComWrite
	;
	; send out the CRC for the block a byte at a time
	;
		mov	ax, crc
		call	ComWrite
		mov	al, ah
		call	ComWrite

		call	RobustCollectOff
	;
	; Wait for acknowledgement of the packet.
	; 
		call	Sync
		jc	tryAgain		; timeout
		cmp	al, NAK
		je	tryAgain		; rejected
		cmp	al, NAK_QUIT
		LONG_EC	je	error		; cancel transfer
		jmp	startBlock		; do the next block

tryAgain:
		cmp	tries, MAX_TRIES
		LONG_EC	je	FSTRet
		inc	tries
	;
	; Seek back to the start.
	; 
		movdw	cxdx, ss:[blockPos]
		mov	al, FILE_POS_RELATIVE
		mov	bx, file
		call	FilePos

	;
	; And go generate the packet again.
	; 
		jmp	startBlock

FSTDone:
		cmp	ds:[count], BUFFER_SIZE
		je	FST3
		;
		; Got out because we hit EOF but output block wasn't complete,
		; so complete it and wait for a sync byte from the other side.
		;
if _DEBUG
		mov	al, 'd'
		call	DebugDisplayChar
endif
		mov	al, BLOCK_END
		call	ComWrite

	; send out the CRC for the block
		mov	ax, crc
		call	ComWrite
		mov	al, ah
		call	ComWrite

		call	Sync
		jc	error			; timeout
		cmp	al, SYNC
		jne	error
FST3:
	;
	; Put out 0 checksum, always... why not get rid of the thing entirely?
	; I dunno...
	; 
		clr	al
		call	ComWrite
		call	ComWrite
FST2:
	;
	; Wait for the acknowledgement from the host. We allow the
	; user to quit out of it using either Sys-f or Sys-Q.
	;
		test	ds:[sysFlags], mask SF_EXIT
		jnz	FSTRet
		call	ComRead
		jc	FST2
		
		cmp	al, ACK
		clc
		je	FSTRet

		mov	bx, offset transmitError
		call	ScrWriteStandardString
FSTRet:
		.leave
		ret
error:
		stc
		jmp	FSTRet
FileSendText	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out what type of file is referenced by dta

CALLED BY:	FileSend
PASS:		bx	= Handle open to file described by dta
		ds:si	= file size
		ds:dx	= file name
		es	= dgroup

RETURN:		ax	= transfer function
		ds:si	= number of bytes to transfer
		CF	= 1 if error.

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
       Read through the file 1K at a time, counting the number of carriage
       returns. Each byte is or'ed into DL so at the end, bit 7 of DL will
       be set if the file is binary.
       
       If the file is text, we subtract the number of carriage returns 
       from the size of the file passed in ds:si. Note that we assume
       that for each carriage return there's a matching linefeed...
       
       Once we've gone all the way through the file, we rewind the beast and
       use DL to figure the file type, setting AX and decrementing the
       passed file size to account for the carriage returns we'll be nuking
	(if it's text).
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/24/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
FileType	proc	near
returns		local	word		; Count of carriage returns in file
		.enter

		push	ds, si		; save pointer to file size
		
EC <		call	ECCheckES_dgroup				>
		segmov	ds, es, ax

		mov	ss:[returns], 0
		clr	dl

FT1:
		push	dx		; Preserve Binary flag
		mov	dx, offset general_buf
		mov	si, dx		; Load SI at the same time
		mov	cx, size general_buf

		call	PCComFileRead
		pop	dx

		jnc	readOK
		cmp	ax, ERROR_SHORT_READ_WRITE	; EOF reached?
		jne	error				; no, other error.
readOK:		
		jcxz	FTDone		; EOF -- done with read.

FT2:
		lodsb
		or	dl, al		; Merge byte in. When all is done,
					; bit 7 of dl will be set if the
					; file is binary.
		cmp	al, cr		; Carriage return?
		jne	FT3
		inc	ss:[returns]
FT3:
		loop	FT2
		jmp	FT1

FTDone:
	;
	; Figure out transfer function and reposition the file
	; at its beginning.
	; 
		push	dx
		clr	cx, dx
		mov	al, FILE_POS_START
		call	FilePos
		pop	dx

		pop	ds, si		; ds:si <- file size
		
		test	dl, 80h
		jnz	FTBin
		mov	ax, ss:[returns]
		sub	ds:[si].low, ax
		jnc	FT4
		dec	ss:[si].high
FT4: 		mov	ax, offset FileSendText
		jmp	short FT5
FTBin:
		mov	ax, offset FileSendBinary
FT5:
		clc
FTRet:
		.leave
		ret
error:
		pop	ds, si
		stc
		jmp	FTRet
FileType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReadBlockHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	wait for a block header charaater to come

CALLED BY:	GLOBAL

PASS:		es - dgroup

RETURN:		carry set on timeout, otherwise clear

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

	ignore all characters that come in until we get
	a block header, which right now is a single
	character BLOCK_START, and timeout after 10
	seconds if it doesn't come in

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/ 4/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileReadBlockHeader	proc	near
		.enter

if	_DEBUG
		mov	al, 'H'
		call	DebugDisplayChar
endif
		mov	al, BLOCK_START
		call	WaitForChar
		jc	done
		cmp	al, BLOCK_START
		jne	setCF
		clc
done:	
		.leave
		ret
setCF:
		stc
		jmp	done	
FileReadBlockHeader	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReadBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a block of bytes from the serial line

CALLED BY:	FileReceive

PASS: 		es:di - buffer
		ds, es - dgroup

RETURN:		carry set on timeout
		es:di - buffer from which to write
		cx = number of characters actually read
		SF_READ_FILENAME set if first block contained filename,
			which has been copied to the pathname buffer.
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
FileReadBlock	proc	near
bufOffset	local	word	push	di
		uses	bx
		.enter

	;
	; Read the BLOCK_START byte.
	;	
		call	FileReadBlockHeader
		jc	done			; timeout or bogus byte

resetVars:
		clr	cx

FileReadBlock1:
		call	ComReadWithWait
		LONG_EC	jc	timeOut

		cmp	al, BLOCK_QUOTE
		LONG_EC	je	gotQuote
		cmp	al, BLOCK_START
		LONG_EC	je	doResend
		cmp	al, BLOCK_END
		je	getCRC

justData:
	; 
	; Check if buffer is full before trying to write another
	; byte into it.
	;
		cmp	cx, BUFFER_SIZE
		LONG_EC	je	timeOut		
EC<		Assert_fptr	esdi				>
		stosb
		inc	cx		; count # bytes actually written

;		test	ds:[sysFlags], mask SF_EXIT
;		jnz	done
 		jmp	FileReadBlock1
doneOK:
		clc
done:
		.leave
		ret
getCRC:
if	_DEBUG
		mov	al, 'C'
		call	DebugDisplayChar
endif
	;
	; Read the two bytes of the CRC
	; 
		call	ComReadWithWait
		jc	timeOut
		mov	bl, al
		call	ComReadWithWait
		jc	timeOut
		mov	bh, al			; bx <- passed CRC
		mov	ax, 0
		mov	di, ss:[bufOffset]
		call	CalcCRC			; ax <- calc'ed CRC
if _DEBUG
		call	DebugDisplayWord	; display the CRC
endif

	; 
	; The block has been successfully read in.  If it is the first
	; block, we need to check if it contains a filename. If it is the
	; first *data* block (in which case SF_READ_FILENAME is set), check
	; for a GeosFileHeader.
	;
		test	ds:[sysFlags], mask SF_FIRST_BLOCK
		jz	notFirstBlock
		test	ds:[sysFlags], mask SF_READ_FILENAME
		jnz	checkForHeader
		call	CheckBlockForFilename
		jnc	done			; block contains a filename
checkForHeader:
		call	CheckForGeosFileHeader
notFirstBlock:
	;
	; Check the CRC
	;
		cmp	ax, bx
		jne	bogus
		jmp	doneOK


gotQuote:
	;
	; the following character will be a special character that
	; must be translated into data
	;
		call	ComReadWithWait
		jc	timeOut
		sub	al, BLOCK_START_DATA - BLOCK_START
		jb	bogus
		cmp	al, BLOCK_QUOTE
		LONG_EC	jbe	justData
timeOut:
if	_DEBUG
		mov	al, '5'
		call	DebugDisplayChar
endif
bogus:
		mov	ax, NAK
		stc
		jmp	done
doResend:
if	_DEBUG
		mov	al, 'r'		
		call	DebugDisplayChar
endif
	;
	; ok, we got a genuine BLOCK_START so we will drop what we
	; got so far, reset the variables and restart
	;
		mov 	di, ss:[bufOffset]
		jmp	resetVars

FileReadBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckBlockForFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The first block has been read.  Check if it contains
		the filename instead of data.

CALLED BY:	FileReadBlock
PASS:		es, ds - dgroup
		es:di - buffer containing the block just read
		ax - calculated CRC
		bx - CRC passed by sender
		cx - block size
RETURN:		carry clear if valid filename block
DESTROYED:	si

PSEUDO CODE/STRATEGY:
	If this first block starts with the filenameBlock below, the
	sender is using the new protocol, and filename which follows this
	string should be used instead of the first filename sent.
	The CRC in this case will actually be the CRC + 1.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/29/93	Initial version
	cassie	 3/14/95	block may also contain file size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
filenameBlock	db	"!PCCom File Transfer Filename Block! "
CheckBlockForFilename		proc	near
		uses	ax,bx,cx,di,ds
		.enter

	;
	; Is the block large enough to hold the filenameBlock?
	;
		cmp	cx, size filenameBlock 
		LONG_EC	jbe	setCF
	
	;
	; Is the filename string the first thing in the block?
	;
		push	cx
		segmov	ds, cs, cx
		mov	cx, size filenameBlock
		mov	si, offset filenameBlock
		repe	cmpsb
		pop	cx
		LONG_EC	jne	setCF

		inc	ax				; CRC <- CRC + 1
		cmp	ax, bx
		LONG_EC	jne	setCF

	;
	; Sender must be using new protocol, because this is a special
	; block which contains the filename.  Save the filename in pathname.
	; It may or may not contain a dword file size following the filename.
	;
		sub	cx, size filenameBlock		
		cmp	cx, size pathname + size fSize 
		LONG_EC	ja	setCF

		segmov	ds, es, ax
		mov	si, di				; ds:si <- source
		mov	di, offset pathname		; es:di <- destination
charLoop:
SBCS<		cmp	di, offset pathname + size pathname	>
DBCS<		cmp	di, offset pathname +((size pathname)/2)>
		LONG_EC	je	setCF
EC<		Assert_fptr	dssi				>
EC<		Assert_fptr	esdi				>
		lodsb
		stosb
		tst	al		
		jnz	charLoop

	;
	; Subtract from cx the number of chars copied to pathname.
	; If the number of chars remaining is exactly large enough to 
	; hold the file size value, copy it to fSize.
	;

		sub	cx, di				;cx = cx + end offset 
		add	cx, offset pathname		;cx = cx - (end - start)
		cmp	cx, size fSize			;cx = # chars remaining
		jne	noFileSize
		movdw	es:[fSize], ds:[si], ax

noFileSize:
DBCS<		mov	di, offset pathname			>
DBCS<		call	ScrSBCStoDBCS				>
		ornf	es:[sysFlags], mask SF_READ_FILENAME
		andnf	es:[sysFlags], not (mask SF_BAD_FILENAME)
		clc	
done:
		.leave
		ret

setCF:
	;
	; This block contains data, not filename. Turn off the first block
	; flag.
	;
		andnf	es:[sysFlags], not (mask SF_FIRST_BLOCK)
		stc
		jmp	done
CheckBlockForFilename		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForGeosFileHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks first data block for GeosFileHeader

CALLED BY:	FileReadBlock
PASS:		ds - dgroup
		es:di - buffer containing the block just read
		cx - block size
RETURN:		SF_GEOS_FILE set if block contained a GeosFileHeader,
		if not in PNS_ROBUST mode then:
			di - updated to point to first byte after header,
			cx - updated to be # bytes less file header size,
			fileSize - updated to not count file header size
DESTROYED:	si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForGeosFileHeader		proc	near
		uses	ax, bx
		.enter

	;
	; We have now read the first block, so turn off this flag.
	;
		andnf	ds:[sysFlags], not mask SF_FIRST_BLOCK

	;
	; To be a geos file, the block must be at least big enough to
	; hold the GeosFileHeader.  (I.E., block size must be >=
	; size of GeosFileHeader, at least for the first block. As the
	; GeosFileHeader is 256 bytes last I checked, this is not an
	; undue burden.)
	;
		cmp	cx, size GeosFileHeader
		LONG_EC jl	done
	;
	; Check for a GeosFileHeader
	;
		cmp	{word}es:[di].GFH_signature, GFH_SIG_1_2
		LONG_EC	jne	done
		cmp	{word}es:[di].GFH_signature[2], GFH_SIG_3_4
		jne	done
		cmp	es:[di].GFH_type, GeosFileType
		jae	done
		mov	ax, es:[di].GFH_flags
		and	ax, not (mask GeosFileHeaderFlags)
		jnz	done
	;
	; This is a Geos file. Copy the header to a buffer which
	; we'll use later to set the file's extended attributes.
	;
		push	cx
		mov	cx, size GeosFileHeader / 2
CheckHack <((size GeosFileHeader) and 1) eq 0>
		mov	si, offset geosFileHeader
		xchg	si, di			; es:di <- dest buffer
		rep	movsw
		mov	di, si			; es:di <- pts past gfh
		pop	cx
	;
	; Subtract file header size from total file size, as we 
	; won't write the header to file, so its size would never
	; get subtracted from fSize in FileReadBlock.
	;
		ornf	ds:[sysFlags], mask SF_GEOS_FILE
		mov	ax, size GeosFileHeader
		sub	ds:[fSize].low, ax
		sbb	ds:[fSize].high, 0
		sub	cx, ax			; cx <- # bytes read less gfh
done:
		.leave
		ret

CheckForGeosFileHeader		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFileExtAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the file attributes for the newly created Geos file

CALLED BY:	FileReceiveStart
PASS:		^hbx 		- file to set attrs for
		ds:geosFileHeader - contains attrs
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if FULL_EXECUTE_IN_PLACE
GFH_OFFSET	=	(offset geosFileHeader)

	;
	; note that this is FileExtAttrDescLIKE - it has less picky
	; type checking (it seems that with that middle element
	; defined as an fptr, somebody stuffs our dgroup segment in
	; there (note the non-xip version below..  it works mysteriously))
	;
extAttrsTable	FileExtAttrDescLike \
	<FEA_NAME, offset GFH_longName + GFH_OFFSET, size FileLongName>,
	<FEA_FILE_TYPE, offset GFH_type + GFH_OFFSET, size GeosFileType>,
	<FEA_FLAGS, offset GFH_flags + GFH_OFFSET, size GeosFileHeaderFlags>,
	<FEA_RELEASE, offset GFH_release + GFH_OFFSET, size ReleaseNumber>,
	<FEA_PROTOCOL, offset GFH_protocol + GFH_OFFSET, size ProtocolNumber>,
	<FEA_TOKEN, offset GFH_token + GFH_OFFSET, size GeodeToken>,
	<FEA_CREATOR, offset GFH_creator + GFH_OFFSET, size GeodeToken>,
	<FEA_USER_NOTES, offset GFH_userNotes + GFH_OFFSET, size FileUserNotes>,
	<FEA_NOTICE, offset GFH_notice + GFH_OFFSET, size FileCopyrightNotice>,
	<FEA_CREATION, offset GFH_created + GFH_OFFSET, size FileDateAndTime>,
	<FEA_PASSWORD, offset GFH_password + GFH_OFFSET, size FilePassword>,
	<FEA_DESKTOP_INFO, offset GFH_desktop + GFH_OFFSET,size FileDesktopInfo>,
	<FEA_END_OF_LIST>

SetFileExtAttributes		proc	near
		uses	es, ds, si, cx, dx
		.enter

	;
	; we've got to move the above structure to the stack so that
	; we can finish off the table (it doesn't have any segments,
	; just the offsets) at run time..
	;
		mov	cx, size extAttrsTable
		sub	sp, cx
		segmov	es, ss
		segmov	ds, cs
		mov	si, offset extAttrsTable
		mov	di, sp
		rep	movsb

		LoadDGroup	ds
		mov	ax, ds

		mov	di, sp
		add	di, offset FEAD_value.segment
		mov	si, (size FileExtAttrDescLike) - (size word)
		mov	cx, length extAttrsTable -1
stuffLoop:
		stosw
		add	di, si
		loop	stuffLoop

		mov	di, sp
		mov	ax, FEA_MULTIPLE
		mov	cx, length extAttrsTable - 1
		call	FileSetHandleExtAttributes
		add	sp, size extAttrsTable

		.leave
		ret
SetFileExtAttributes		endp

else	;FULL_XIP...

GFH_OFFSET	=	offset geosFileHeader

extAttrsTable	FileExtAttrDesc \
	<FEA_NAME, offset GFH_longName + GFH_OFFSET, size FileLongName>,
	<FEA_FILE_TYPE, offset GFH_type + GFH_OFFSET, size GeosFileType>,
	<FEA_FLAGS, offset GFH_flags + GFH_OFFSET, size GeosFileHeaderFlags>,
	<FEA_RELEASE, offset GFH_release + GFH_OFFSET, size ReleaseNumber>,
	<FEA_PROTOCOL, offset GFH_protocol + GFH_OFFSET, size ProtocolNumber>,
	<FEA_TOKEN, offset GFH_token + GFH_OFFSET, size GeodeToken>,
	<FEA_CREATOR, offset GFH_creator + GFH_OFFSET, size GeodeToken>,
	<FEA_USER_NOTES, offset GFH_userNotes +GFH_OFFSET, size FileUserNotes>,
	<FEA_NOTICE, offset GFH_notice + GFH_OFFSET, size FileCopyrightNotice>,
	<FEA_CREATION, offset GFH_created + GFH_OFFSET, size FileDateAndTime>,
	<FEA_PASSWORD, offset GFH_password + GFH_OFFSET, size FilePassword>,
	<FEA_DESKTOP_INFO, offset GFH_desktop+GFH_OFFSET,size FileDesktopInfo>,
	<FEA_END_OF_LIST>

SetFileExtAttributes		proc	near
		uses	es
		.enter

		segmov	es, cs, ax
		mov	di, offset extAttrsTable
		mov	ax, FEA_MULTIPLE
		mov	cx, length extAttrsTable - 1
		call	FileSetHandleExtAttributes

		.leave
		ret
SetFileExtAttributes		endp
endif	;FULL_XIP...


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write a block of data adding quotes where neccessary

CALLED BY:	GLOBAL

PASS:		ds:si = start of buffer
		cx = # of bytes to send
		es - dgroup	

RETURN:		nothing

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/ 6/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDataBlock	proc	near
		uses	cx, di, bx, dx, bp
		.enter

		mov	di, si	; save start of buffer for CRC at end
		mov	bx, cx	; save number of bytes, also for CRC
		jcxz	done
if _DEBUG
		mov	al, 'W'
		call	DebugDisplayChar
endif

		call	RobustCollectOnES

		mov	al, BLOCK_START
		call	ComWrite

writeLoop:
		lodsb	; al <- next bytes in buffer
		
		cmp	al, BLOCK_START
		je	writeSpecial
		cmp	al, BLOCK_END
		je	writeSpecial
		cmp	al, BLOCK_QUOTE
		jne	writeChar

writeSpecial:
		mov	ah, al
		mov	al, BLOCK_QUOTE
		call	ComWrite
		mov	al, ah
		.assert (BLOCK_END eq BLOCK_START+1) and \
			   (BLOCK_END_DATA eq BLOCK_START_DATA+1)
		.assert (BLOCK_QUOTE eq BLOCK_END+1) and \
			   (BLOCK_QUOTE_DATA eq BLOCK_END_DATA+1)

		add	al, BLOCK_START_DATA - BLOCK_START
writeChar:
		call	ComWrite
		loop	writeLoop

if _DEBUG
		tst	cx
		jz	$10
		mov	al, 'Y'
		call	DebugDisplayChar
		mov	ax, cx
		call	DebugDisplayWord
$10:
endif

	; send the END token
		mov	al, BLOCK_END
		call	ComWrite

	; send the block CRC
		mov	cx, bx
		clr	ax
		call	CalcCRC
if _DEBUG
	call	DebugDisplayWord
endif
		call	ComWrite
		mov	al, ah
		call	ComWrite
done:

		call	RobustCollectOffES

		.leave
		ret
WriteDataBlock	endp

;---------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReadNBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get N bytes, ignore special chars

CALLED BY:	GLOBAL

PASS:		ds - dgroup
		es:di - buffer
		cx - number of bytes to read

RETURN:		carry set if timed out
		es:di - adjusted to point at the byte beyond the last read

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/ 5/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileReadNBytes	proc	near
	.enter

		jcxz	done
if	_DEBUG
		mov	al, 'N'
		call	DebugDisplayChar
endif
readBytes:
		call	ComReadWithWait
		jc	done
EC<		Assert_fptr	esdi				>
		stosb
		test	ds:[sysFlags], mask SF_EXIT
		loope	readBytes
		clc
done:
	.leave
	ret
FileReadNBytes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlushBufferSendNAK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush a buffer and send NAK or NAK_QUIT to other
		side.

CALLED BY:	FileReceive, FileReadBlock
PASS:		ax - STREAM to flush
		dl - ack type
RETURN:		carry set
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlushBufferSendNAK	proc	near
		uses	bx,ds
		.enter

	;
	; If PCCom has been exited before we got here, don't try to
	; do anything with the stream, as that will cause a crash.
	;
		cmp	ds:[serialPort], NO_PORT
		je	done

		cmp	ds:[negotiationStatus], PNS_ROBUST
		je	done

		LoadDGroup	ds, bx
		mov	bx, ds:[serialPort]
		CallSer	DR_STREAM_FLUSH, ds

		mov	al, dl
		call	ComWrite
done:
		stc
		.leave
		ret
FlushBufferSendNAK	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindTail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Separate pathname into path and file name components,
		copying the file name into filename.

CALLED BY:	FileSend
PASS:		ds, es - dgroup
		pathname - null-terminated (DBCS) pathname argument
			read from host 
RETURN:		di - points to last byte of pathname (NULL)
		pathname - terminated before tail
		filename - tail of pathname
DESTROYED:	ax,cx,si,di

PSEUDO CODE/STRATEGY:

	ALL PATHNAMES ARE SBCS.  On a SBCS device we'll do
	translations to try for misc codepages, but on DBCS we're
	sticking with the geos SBCS code page.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindTail	proc	near

	;
	; Find the last backslash in the passed filename so we can
	; copy the tail into the buffer in the right place.
	;
		mov	di, offset pathname
		mov	si, di			; ds:si <- pathname
		mov	al, '\\'
SBCS<		call	LocalStringLength				>
DBCS<		call	PCComDBCSStringLength					>
		push	cx			; save string length
		
findLoop:	repne	scasb			; Search for next one
		jne	noMore			; No more => done
		mov	si, di			; Save position after it...
		or	sp, sp			; Clr zf, in case \ found
						; at path's *end* (oo loop)
		jmp	findLoop
noMore:
		pop	cx			; cx <- string length
		cmp	si, offset pathname	
		je	findColon
		mov	di, si

replaceChar:
	;
	; di = offset of the char in pathname after the last backslash/colon,
	; or if the path is only a file name, the first byte in pathname.
	;
		dec	di	
DBCS<		inc	si						>
	;
	; This assertion is to ensure that no drive name like "AA" or
	; "BB" will be used. Only alphabetical letters can be used.
	;
		.assert	(MSDOS_MAX_DRIVES eq 26)
SBCS<		cmp	di, offset pathname + MSDOS_DRIVE_REF_LENGTH	>
DBCS<		cmp	di, offset pathname + (MSDOS_DRIVE_REF_LENGTH*2)>
						; pointing at char
						; after drive spec? (C:\)?  
		jne	copyFileName		; no, forget it
	;
	; The path returned must be absolute. pathname cannot be "C:"
	; since FileSetCurrentPath will fail. So we have to append
	; backslash in this case.
	;
		mov	{byte}ds:[di], '\\'	; put backslash after drive
SBCS<		inc	di						>
DBCS<		add	di, 2						>
copyFileName:
		push	di			; save end of pathname offset
SBCS<		mov	cx, size filename				>
DBCS<		mov	cx, (size filename / 2)				>
		mov	di, offset filename	; es:di <- destination buffer
	;
	;	ds:si = offset within pathname of file name (source buffer)
	;	
copyLoop:
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
SBCS<		lodsb							>
SBCS<		stosb							>
SBCS<		tst	al						>
DBCS<		lodsw							>
DBCS<		stosw							>
DBCS<		tst	ax						>
		loopnz	copyLoop

	;
	; Null terminate the pathname - actually clear out everything
	; after the last char else a later call to findtail could
	; produce bad results due to garbage '\\' later in the buffer
	;
		pop	di
		mov	cx, offset pathname
		add	cx, size pathname
		sub	cx, di
		clr	al
EC <		push	di						>
EC <		add	di, cx						>
EC <		Assert_fptr	esdi					>
EC <		pop	di						>
		rep stosb
		ret

findColon:
	;
	; No backslash -- see if there's a colon after which we
	; should place the beast.
	; 	ds:si points to pathname
	;	cx = string length
	;
		mov	di, offset pathname
		mov	al, ':'
		repne	scasb
		mov	si, di			
		je	replaceChar		; es:si points after colon
		mov	si, offset pathname
		mov	di, offset pathname	
		jmp	copyFileName	
		
FindTail	endp

;---------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileWriteCurrentPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL - FileLs, FileCd
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileWriteCurrentPath		proc	near
	uses	bx,cx,dx,si,di
	.enter
		mov	dx, 1			; add drive name
		clr	bx			; path is relative to CWD
		mov	di, offset general_buf	; es:di <- buffer to hold full path
		mov	si, offset nullPath	; ds:si <- tail of path (none)
		mov	cx, size general_buf
		call	FileConstructFullPath
	;
	; now print the current directory
	;
		mov	si, offset general_buf
DBCS<		call	ScrDBCStoSBCS					>
		call	ScrWriteString
	.leave
	ret
FileWriteCurrentPath		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindDirComponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next component of pathname

CALLED BY:	FileLs
PASS:		ds:di - remaining part of pathname
		cx - number of chars remaining in pathname buffer
RETURN:		carry clear:
		ds:dx - next component of pathname, NULL-terminated
		ds:di - points to NULL after next component in ds:dx
	
		carry set	= next component contains a drive specifier
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindDirComponent		proc	near
		.enter
	;
	; Find the first backslash in the passed pathname 
	;
		mov	dx, di			; ds:dx <- pathname
	;
	; Check if the component contains any drive specifier
	;
		mov	al, ':'
		repne	scasb
		je	foundDriveSpec
	;
	; Search for first backslash
	;
		mov	di, dx			; ds:di <- path to search
		mov	al, '\\'
		repne	scasb			; Search for next one
		jne	noMore			; No more => done
	;
	; Replace the backslash with a null
	;
		dec	di
		mov	al, 0
EC <		Assert_fptr	esdi					>
		stosb				; ds:di <- path tail
done:
		.leave
		ret
noMore:
		clr	cx
		jmp	done

foundDriveSpec:
	;
	; If the drive spec is followed by a backslash, step over
	; the backslash. Trying to LS F:\ENSDEMO.EC didn't work when
	; the backslash was the first character in the next component.
	;
		cmp	{byte}es:[di], '\\'
		stc
		jne	done
		inc	di
		jmp	done
FindDirComponent		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	List a (DOS) directory.

CALLED BY:	INTERNAL - ParseSeq, FileLongLs, FileMedLs
PASS:		ds, es - dgroup
		ds:[currentLsOption] = short/medium/long
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Expects not the DOS name, but the GEOS pathname.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if FULL_EXECUTE_IN_PLACE
FileExtAttrXIP	segment	resource
endif

lsReturnAttrs	FileExtAttrDesc \
	<FEA_DOS_NAME, LSRA_name, size LSRA_name>,
	<FEA_FILE_ATTR, LSRA_attrs, size LSRA_attrs>,
	<FEA_SIZE, LSRA_size, size LSRA_size>,
	<FEA_MODIFICATION, LSRA_modified, size LSRA_modified>,
	<FEA_FILE_TYPE, LSRA_geosFileType, size LSRA_geosFileType>,
	<FEA_NAME, LSRA_longName, size LSRA_longName>,
	<FEA_RELEASE, LSRA_release, size LSRA_release>,
	<FEA_PROTOCOL, LSRA_protocol, size LSRA_protocol>,
	<FEA_TOKEN, LSRA_token, size LSRA_token>,
	<FEA_CREATOR, LSRA_creator, size LSRA_creator>,
	<FEA_END_OF_LIST>

if FULL_EXECUTE_IN_PLACE
FileExtAttrXIP	ends
endif

LSSearchFlags	equ	FILE_ENUM_ALL_FILE_TYPES or mask FESF_DIRS or mask FESF_CALLBACK

fepLS	FileEnumParams <
	LSSearchFlags,		 			; FEP_searchFlags
	lsReturnAttrs,					; FEP_returnAttrs
	size LSReturnAttrs,				; FEP_returnSize
	0,						; FEP_matchAttrs
	FE_BUFSIZE_UNLIMITED,				; FEP_bufSize
	0,						; FEP_skipCount
	PCComFileEnumCallback,				; FEP_callback
	0,						; FEP_callbackAttrs
	0,						; FEP_cbData1
							; - this'll be
							; filled in by
							; the callback
	1,						; FEP_cbData2 
	0						; FEP_headerSize
>

FileLs		proc	near

memHandle	local	hptr.MemHandle
		uses	ds
		.enter

		clr	ss:[memHandle]		; initialize
		call	FilePushDir
	;
	; get the pathname to LS
	;
		clr	{byte}ds:[filename]	; assume no filename
		mov	di, offset pathname
		mov	cx, size pathname
		call	FileGetArg
		LONG_EC	jc	noArg
		tst	{byte}ds:[pathname]
		LONG_EC	jz	noArg

		mov	di, offset pathname
		mov	cx, size pathname
dirLoop:
	;
	; If pathname has no tail, just LS the current directory
	;
		LONG_EC	jcxz	noArg
	;
	; Find the next path component in pathname
	;
		call	FindDirComponent	; ds:dx <- next component
						; ds:di <- tail
						; carry set if pathname
						;   contains drive specifier 
		jnc	changePath
	;
	; The next component is a drive specifier and it is not NULL
	; terminated. Create a custom drive specifier with '\' to set the
	; directory on the stack
	;
		.assert	(MSDOS_DRIVE_REF_LENGTH eq 2)
		push	ds, es, di
		sub	sp, MSDOS_DRIVE_REF_LENGTH+2
		segmov	es, ss, ax
		mov	di, dx			; dsdi<-next component
		mov	al, ds:[di]		; copy the drive specifier
		mov	di, sp			; esdi<-stack buffer for path
		mov	es:[di], al		; copy "<drive>:\<NULL>"
		mov	{byte}es:[di][1], ':'
		mov	{byte}es:[di][2], '\\'
		clr	{byte}es:[di][3]	; NULL terminated
		mov	dx, di
		segmov	ds, es, ax		; ds:dx <- new drive spec path
		clr	bx
		call	PCComFileSetCurrentPath
		lahf				; save flag before adding
		add	sp, MSDOS_DRIVE_REF_LENGTH+2
						; restore stack
		sahf
		pop	ds, es, di
		LONG_EC	jnc	dirLoop
		jmp	lsFilename
	
changePath:
	;
	; change to the requested path
	;
		clr	bx			; absolute path
		call	PCComFileSetCurrentPath
		LONG_EC	jnc	dirLoop
lsFilename:
	;
	; Could not change to last component, maybe it was actually
	; a filename or file match pattern.  Copy the remainder of
	; the path into filename and try to FileEnum it.
	;
		mov	si, dx			; ds:si <- tail of path
		mov	di, offset filename
copyLoop:
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
SBCS<		lodsb							>
SBCS<		stosb							>
DBCS<		lodsw							>
DBCS<		stosw							>
		tst	al
		jnz	copyLoop

noArg:
	;
	; If no pattern was passed, use the '*' pattern to match all files
	;
		tst	{byte}ds:[filename]
		jnz	havePattern
		mov	di, offset filename
SBCS<		mov	al, '*'						>
DBCS<		mov	ax, '*'						>
EC <		Assert_fptr	esdi					>
SBCS<		stosb							>
DBCS<		stosw							>
SBCS<		mov	al, 0						>
DBCS<		clr	ax						>
EC <		Assert_fptr	esdi					>
SBCS<		stosb							>
DBCS<		stosw							>

havePattern:
	;
	; We're going to start outputing results now, setup output
	; modes
	;
		call	RobustCollectOn
	;
	; Print the name of the directory that is going to be LS'ed
	;
		call	ScrWriteNewLine
	;
	; Start writing to StringBlock instead of writing directly to
	; screen
	;
		call	StringBlockStart
		
		mov	bx, offset DirectoryOfString
		call	ScrWriteStandardString	; write "Dir. of"
		call	FileWriteCurrentPath	; write the path name
	;
	; Do a FileEnum to get all files that match the pattern in filename
	;
DBCS<		mov	si, offset filename				>
DBCS<		call	ScrDBCStoSBCS					>
NOFXIP <	mov	cs:[fepLS].FEP_cbData1.high, ds			>
NOFXIP <	mov	cs:[fepLS].FEP_cbData1.low, offset filename	>
		segmov	ds, cs, ax
		mov	si, offset fepLS
		clr	ss:[memHandle]
		call	FileEnumPtr
	LONG	jc	error
	LONG	jcxz	noFiles
		mov	ss:[memHandle], bx
		call	MemLock
		mov	ds, ax
		clr	di

findFileLoop:
	;
	; Toggle the collection mechanism to force one block per line
	; so that slow devices (like floppies) don't cause timeouts on
	; long listings.
	;
		call	RobustCollectOffES
		call	RobustCollectOnES

		push	cx				; save loop counter
	;
	; first do a carriage return
	;
		call	ScrWriteNewLine
	;
	; get the length of the filename
	;
		mov	cx, size DosDotFileName
		lea	bx, ds:[di].LSRA_name
		mov	al, ' '				; pad character
		call	ScrWritePaddedStringLJ
		mov	al, ds:[di].LSRA_attrs
		test	al, mask FA_SUBDIR
		LONG	jnz	doDirectory
	;
	; For Geos files, FileEnumPtr returns actual file size -
	; GeosFileHeader size. We need to add that back in.
	;
		movdw	dxax, ds:[di].LSRA_size
		cmp	ds:[di].LSRA_geosFileType, GFT_NOT_GEOS_FILE
		je	notGeosFile
		.assert (size GeosFileHeader) eq 256
		adddw	dxax, 256
	;
	; write out the file size
	;
notGeosFile:
		mov	bx, offset general_buf
		call	ScrDumpDecimal
		mov	cx, 9
		mov	al, ' '
		call	ScrWritePaddedStringRJ
		mov	al, ' '
		call	ScrWrite
doDate:
	;
	; date:  printed as MM-DD-YY
	;
		mov	ax, ds:[di].LSRA_modified.FDAT_date
;month
		push	ax
		and	ax, mask FD_MONTH
		mov	cl, offset FD_MONTH
monthLoop:
		shr	ax
		loop	monthLoop
		clr	dx
		mov	bx, offset general_buf
		call	ScrDumpDecimal
		mov	cx, 2
		mov	al, '0'
		call	ScrWritePaddedStringRJ
		mov	al, '-'
		call	ScrWrite
		pop	ax
;day
		push	ax
		and	ax, mask FD_DAY
		clr	dx
		mov	bx, offset general_buf
		call	ScrDumpDecimal
		mov	cx, 2
		mov	al, '0'
		call	ScrWritePaddedStringRJ
		mov	al, '-'
		call	ScrWrite
		pop	ax
;year
		and	ax, mask FD_YEAR
		mov	cl, offset FD_YEAR
yearLoop:
		shr	ax
		loop	yearLoop
		add	ax, 80		; based on 1980
		clr	dx
		mov	bx, offset general_buf
		call	ScrDumpDecimal
		mov	al, '0'
		mov	cx, 2
		call	ScrWritePaddedStringRJ
		mov	al, ' '
		call	ScrWrite

	;
	; time: printed as HH:MMx, where x = a or p
	;
		mov	ax, ds:[di].LSRA_modified.FDAT_time
;hours
		and	ax, mask FT_HOUR
		mov	cl, offset FT_HOUR
hourLoop:
		shr	ax
		loop	hourLoop
		mov	bx, 'a'
		cmp	ax, 12
		jl	printHour
		sub	ax, 12
		mov	bx, 'p'
printHour:
		tst	ax
		jnz	printHour2
		mov	ax, 12
printHour2:
		push	bx		; save am/pm marker 
		clr	dx
		mov	bx, offset general_buf
		call	ScrDumpDecimal
		mov	al, ' '
		mov	cx, 2
		call	ScrWritePaddedStringRJ
		mov	al, ':'
		call	ScrWrite
;minutes
		mov	ax, ds:[di].LSRA_modified.FDAT_time
		and	ax, mask FT_MIN
		mov	cl, offset FT_MIN
minuteLoop:
		shr	ax
		loop	minuteLoop
		mov	bx, offset general_buf
		clr	dx
		call	ScrDumpDecimal
		mov	al, '0'
		mov	cx, 2
		call	ScrWritePaddedStringRJ
		pop	ax			; get am/pm char
		call	ScrWrite

	;
	; Check for Ls options		PERR
	;
		mov	ax, es:[currentLsOption]
		cmp	ax, LO_short
		je	findNext

	;
	; LO_medium or LO_long
	;
		call	PrintExtraLsInfo

findNext::
		pop	cx
		add	di, size LSReturnAttrs
		test	es:[sysFlags], mask SF_EXIT
		jnz	exitError
		dec	cx
		LONG	jnz	findFileLoop
		mov	di, PCET_NORMAL
done:
	;
	; Send whatever is in StringBlock and finish writing to String Block
	;
		call	StringBlockSend
		
		mov	bx, ss:[memHandle]
		tst	bx
		jz	noHandle
		call	MemFree
noHandle:
		segmov	ds, es, bx
		call	FilePopDir
		call	RobustCollectOff
		call	FileEndCommand

		.leave
		ret

doDirectory:
		mov	bx, offset dirString
		call	ScrWriteStandardString
		mov	bx, offset spaceString
		call	ScrWriteStandardString
		jmp	doDate

error:	
		mov	bx, offset PathNotFoundString
		call	ScrWriteStandardString
exitError:
		mov	di, PCET_ERROR
		jmp	done

noFiles:
	;
	; first do a carriage return
	;
		call	ScrWriteNewLine
		mov	ax, ERROR_FILE_NOT_FOUND
		call	FileFileError
		mov	di, PCET_ERROR
		jmp	done
FileLs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintExtraLsInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prints out additional Ls info for options LO_medium and
		LO_long

CALLED BY:	FileLs
PASS:		ds:di = LSReturnAttrs structure
		ds:[currentLsOption] = current ls option
		es = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nonGeosFileStr		char	'*NON-GEOS*', 0
geosAttrOffChar		char	'-', 0
geosAttrStr		char	'advshr', 0
geosAttrStrLen		equ	6
FileAttributeTbl byte \
	mask FA_ARCHIVE,
	mask FA_SUBDIR,
	mask FA_VOLUME,
	mask FA_SYSTEM,
	mask FA_HIDDEN,
	mask FA_RDONLY

PrintExtraLsInfo	proc	near
		uses	ax,bx,cx,dx,di,si
		.enter
	;
	; First, print out attributes
	; a = archive, d = directory, v = volume, s = system, h = hidden,
	; r = read-only.
	; (ex) "---shr" = read-only hidden system file
	;
		mov	al, ' '
		call	ScrWrite
		
		mov	bl, {byte} ds:[di].LSRA_attrs
		clr	si
fileAttrLoop:
		test	bl, cs:[FileAttributeTbl][si]	; test attribute bit
		jz	notSet				;
		mov	al, {byte}cs:[geosAttrStr][si]	; print attrb letter
		jmp	printAttr
notSet:
		mov	al, cs:geosAttrOffChar		; print '-'
printAttr:
		call	ScrWrite
		inc	si
		cmp	si, geosAttrStrLen
		jb	fileAttrLoop
		
		mov	al, ' '
		call	ScrWrite
	;
	; If this is a directory, we are done
	;
		test	bl, mask FA_SUBDIR
		LONG_EC	jnz	done
	;
	; If this is not a geos file, say so and done
	;
		mov	bx, ds:[di].LSRA_geosFileType
		cmp	bx, GFT_NOT_GEOS_FILE
		LONG_EC	je	nonGeosFile
	;
	; Geos Long Name
	;
		mov	si, di
		add	si, offset LSRA_longName
		call	ScrWriteString
		mov	al, ' '
		call	ScrWrite
	;
	; Release Number
	;
		mov	si, offset general_buf
		mov	bx, si			; es:bx = buffer to write chars
		
		mov	ax, ds:[di].LSRA_release.RN_major
		clr	dx
		call	ScrDumpDecimal		;
		push	ds			; save block from FileEnum 
		push	es			;
		pop	ds			; ds:si = general_buf
		call	ScrWriteString		;
		pop	ds			; recover file info

		mov	al, '.'
		call	ScrWrite
		
		mov	ax, ds:[di].LSRA_release.RN_minor
		call	ScrDumpDecimal		;
		push	ds			; save block from FileEnum 
		push	es			;
		pop	ds			; ds:si = general_buf
		call	ScrWriteString		;
		pop	ds			;

		mov	al, '.'
		call	ScrWrite
		
		mov	ax, ds:[di].LSRA_release.RN_change
		call	ScrDumpDecimal		;
		push	ds			; save block from FileEnum 
		push	es			;
		pop	ds			; ds:si = general_buf
		call	ScrWriteString		;
		pop	ds			;

		mov	al, '.'
		call	ScrWrite
		
		mov	ax, ds:[di].LSRA_release.RN_engineering
		call	ScrDumpDecimal		;
		push	ds			; save block from FileEnum 
		push	es			;
		pop	ds			; ds:si = general_buf
		call	ScrWriteString		;
		pop	ds			;

		cmp	es:[currentLsOption], LO_long
		jne	done
	;
	; Long LS information
	;
		call	ScrPrintLongLsInfo
done:	
		.leave
		ret
nonGeosFile:
	;
	; None Geos File
	;
		push	ds
		segmov	ds, cs, ax
		mov	si, offset nonGeosFileStr
FXIP <		clr	cx						>
FXIP <		call	SysCopyToStackDSSI				>
		call	ScrWriteString
FXIP <		call	SysRemoveFromStack				>
		pop	ds
		jmp	done
		
PrintExtraLsInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrPrintLongLsInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print out the second line for LO_long option

CALLED BY:	PrintExtraLsInfo
PASS:		ds:[di] = current file info returned by FileEnum in FileLs
		es = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrPrintLongLsInfo	proc	near
		uses	ax,bx,cx,dx,di,si,ds
		.enter
	;
	; Line feed
	;
		call	ScrWriteNewLine
	;
	; tab loop (put in arbitrary number of spaces)
	;
		mov	cx, 75
tabLoop:
		mov	al, ' '
		call	ScrWrite
		loop	tabLoop
	;
	; creator
	;
		mov	si, di
		add	di, offset LSRA_creator		; ds:di = LSRA_creator
		call	ScrPrintGeodeToken
		mov	al, ' '
		call	ScrWrite
	;
	; token
	;
		mov	di, si
		add	di, offset LSRA_token		; ds:di = LSRA_creator
		call	ScrPrintGeodeToken
		mov	al, ' '
		call	ScrWrite
	;
	; Protocol Number
	;
		mov	di, si
		mov	si, offset general_buf		; 
		mov	bx, si				; es:bx = buff for num

		mov	ax, ds:[di].LSRA_protocol.PN_major
		clr	dx
		call	ScrDumpDecimal
		push	ds
		segmov	ds, es, ax			; ds:si = buff for num
		call	ScrWriteString			;		
		pop	ds

		mov	al, '.'
		call	ScrWrite
		
		mov	ax, ds:[di].LSRA_protocol.PN_minor
		clr	dx
		call	ScrDumpDecimal
		segmov	ds, es, ax			; ds:si = buff for num
		call	ScrWriteString			;		

		.leave
		ret
ScrPrintLongLsInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGeodeToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	prints out a geode token

CALLED BY:	ScrPrintLongLsInfo
PASS:		ds:di = geode token to print
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; MANUFACTURER ID TABLE ( 3 CHARACTERS )
;
KNOWN_MANUFACTURER_ID	= 9
ManufacturerTable	dword \
	'GEO', 0,		; GEOWORKS 		0
	'APP', 0,		; APP_LOCAK		1
	'PLM', 0,		; PALM_COMPUTING	2
	'WIZ', 0,		; WIZARD		3
	'CLB', 0,		; CREATIVE_LABS		4
	'DSL', 0,		; DOS_LAUNCHER		5
	'AOL', 0,		; AMERICA_ONLINE	6
	'ITU', 0,		; INTUIT		7
	'SDK', 0,		; SDK			8
	'AGD', 0		; AGD			9

ScrPrintGeodeToken	proc	near
		uses	ax,bx,dx,ds,di,si
		.enter
	;
	; print out token characters
	;
		mov	dx, di
		add	dx, TOKEN_CHARS_LENGTH
		tstdw	ds:[di]
		jnz	tokenCharLoop
		mov	al, '0'
		call	ScrWrite
		jmp	manufID
		
tokenCharLoop:
		mov	al, {byte}ds:[di]
		call 	ScrWrite
		inc	di
		cmp	di, dx
		jl	tokenCharLoop
manufID:		
	;
	; print out manufacturer's id
	;
		mov	al, '['
		call	ScrWrite
		mov	ax, {word}ds:[di]
		cmp	ax, KNOWN_MANUFACTURER_ID
		ja	printUnknownID
	;
	; look up in the table
	;
		mov	si, ax
		shl	si, 1
		shl	si, 1
		add	si, offset ManufacturerTable
		
		push	cs			;
		pop	ds			; ds:si = manufacturer's name
FXIP <		push	cx						>
FXIP <		clr	cx						>
FXIP <		call	SysCopyToStackDSSI				>
FXIP <		pop	cx						>
		call	ScrWriteString		;
FXIP <		call	SysRemoveFromStack				>
		
finish:
		mov	al, ']'
		call	ScrWrite
		.leave
		ret

printUnknownID:
		clr	dx			; dx:ax = manufacturer's ID
		mov	bx, offset general_buf	; es:bx = general_buf
		call	ScrDumpDecimal
		segmov	ds, es, ax		;
		mov	si, bx			; ds:si = ID in decimal
		call	ScrWriteString		;
		jmp	finish
ScrPrintGeodeToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change directories.

CALLED BY:	INTERNAL - ParseSeq
PASS:		ds,es - dgroup
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCd		proc	near
	.enter

		mov	di, offset general_buf
		mov	cx, size general_buf
		call	FileGetArg
		mov	ax, ERROR_BAD_ARGUMENT
		jc	fileError

SBCS<		dec	di							>
DBCS<		sub	di, 2							>
		cmp	di, offset general_buf
		je	getCurrentDir
	;
	; Check if the directory only has the drive. If so, add a backslash
	; to the end so that the path can be set in FileSetCurrentPath.
	;
SBCS<		cmp	{byte}ds:[di-1], ':'	; last char is colon?		>
DBCS<		cmp	{byte}ds:[di-2], ':'					>
		jne	setPath
EC <		cmp	di, offset general_buf + size general_buf - 2		>
EC <		jl	withinBuf						>
EC <		ERROR	-1			; ds:di beyond general_buf	>
EC < withinBuf:									>
SBCS<		mov	{byte}ds:[di], 0x005c	; `\\`				>
SBCS<		clr	{byte}ds:[di+1]		; general_buf is NULL terminated!>
DBCS<		mov	{word}ds:[di], 0x5c5c					>
DBCS<		clr	{word}ds:[di+2]						>
	
setPath:
		mov	dx, offset general_buf	; ds:dx <- pathname
		clr	bx			; relative to current
						; path or absolute 
		call	PCComFileSetCurrentPath
		jc	fileError

getCurrentDir:
		mov	di, PCET_NORMAL
done:
		call	FileEndCommand

	.leave	
	ret

fileError:
		call	FileFileError
		mov	di, PCET_ERROR	
		jmp	done

FileCd		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMkDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a directory under the current directory.

CALLED BY:	INTERNAL - ParseSeq
PASS:		ds, es - dgroup
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
	FileCreateDir returns:
		if error
			carry set
			ax - FileError
		else
			carry clear

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileMkDir		proc	near
		mov	bx, vseg FileCreateDir
		mov	ax, offset FileCreateDir
		mov	bp, offset DirectoryMadeString
		call	FileOpCommon
	ret
FileMkDir		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRmDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a directory

CALLED BY:	INTERNAL - ParseSeq
PASS:		ds, es - dgroup
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
    FileDeleteDir returns:
	carry - set if error
	ax - FileError (if an error)
		ERROR_PATH_NOT_FOUND
		ERROR_IS_CURRENT_DIRECTORY
		ERROR_ACCESS_DENIED
		ERROR_DIRECTORY_NOT_EMPTY
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileRmDir		proc	near
		mov	bx, vseg FileDeleteDir
		mov	ax, offset FileDeleteDir
		mov	bp, offset DirectoryRemovedString
		call	FileOpCommon
		ret
FileRmDir		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRmFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a file.

CALLED BY:	INTERNAL - ParseSeq
PASS:		ds, es - dgroup
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
    FileDelete returns:
	carry - set if error
	ax - error code
		ERROR_FILE_NOT_FOUND
		ERROR_ACCESS_DENIED
		ERROR_FILE_IN_USE

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/93	Initial version
	PT	5/01/96		Use PCComFileDelete

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileRmFile		proc	near

EC <		call	ECCheckDS_dgroup				>
		mov	di, offset general_buf
		mov	cx, size general_buf
		call	FileGetArg
		mov	ax, ERROR_BAD_ARGUMENT
		jc	error
	
		mov	ds:[pathname], 0	; filename is relative path
		mov	si, offset general_buf	; ds:si <- filename
		call	FileSendOpenFile
		jc	error
		mov	bx, ax
		call	FileClose

		mov	dx, offset general_buf	; ds:dx <- pathname
		mov	bp, TRUE		; gain file access
		call	PCComFileDelete
		jc	error
	
		mov	bx, offset FileRemovedString
		call	ScrWriteStandardString
		mov	di, PCET_NORMAL

exit:
		call	FileEndCommand
	.leave
	ret

error:
		call	FileFileError
		stc
		mov	di, PCET_ERROR	
		jmp	exit
FileRmFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRenameFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move a file.

CALLED BY:	INTERNAL - ParseSeq
PASS:		ds, es - dgroup
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Pathnames must be relative to current path.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileRenameFile		proc	near
	mov	bx, vseg FileMove
	mov	dx, offset FileMove
	mov	bp, offset FileRenamedString
	mov	ax, mask IACP_RT_DESTINATION or mask IACP_RT_SOURCE
	call	FileOp2Common
	ret
FileRenameFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a copy of a file.

CALLED BY:	INTERNAL - ParseSeq
PASS:		ds, es - dgroup
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCopyFile		proc	near
	mov	bx, vseg FileCopy
	mov	dx, offset FileCopy
	mov	bp, offset FileCopiedString
	mov	ax, mask IACP_RT_DESTINATION	
	call	FileOp2Common
	ret
FileCopyFile		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLongLs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call	FileLs with LO_long option

CALLED BY:	ParseSeq
PASS:		ds = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileLongLs	proc	near
		.enter
	;
	; Set LS option
	;
		mov	ax, LO_long
		xchg	ax, ds:[currentLsOption]
		call	FileLs
	;
	; Set LS option to previous option
	;
		xchg	ax, ds:[currentLsOption]
		
		.leave
		ret
FileLongLs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMedLs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call FileLs with LO_medium option

CALLED BY:	ParseSeq
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileMedLs	proc	near
		.enter
	;
	; Set LS option
	;
		mov	ax, LO_medium
		xchg	ax, ds:[currentLsOption]
		call	FileLs
	;
	; Set LS option to previous option
	;
		xchg	ax, ds:[currentLsOption]
		
		.leave
		ret
FileMedLs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileShortLs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call FileLs with LO_short option

CALLED BY:	ParseSeq
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	2/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileShortLs	proc	near
		.enter
	;
	; Set LS option
	;
		mov	ax, LO_short
		xchg	ax, ds:[currentLsOption]
		call	FileLs
	;
	; Set LS option to previous option
	;
		xchg	ax, ds:[currentLsOption]
			
		.leave
		ret
FileShortLs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAvailableDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays available drives on the system.

CALLED BY:	ParseSeq
PASS:		es,ds = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileAvailableDrives	proc	near
		uses	ds
		.enter
		call	RobustCollectOn
	;
	; Line feed
	;
		call	ScrWriteNewLine
	;
	; Loop through all possible drives to find out what of them are
	; available
	;
	; es:di = buffer for drive name
	; dx 	= drive number (ax trashed at the end)
	; cx    = number of drives left to check
	;
		mov	di, offset general_buf		; es:di = general buff
		clr	dx				; al = drive number
		mov	cx, DRIVE_MAX_DRIVES		; cx = counter
driveLoop:
		push	cx				; save counter
		mov	ax, dx				; al = drive number
		mov	cx, DRIVE_NAME_MAX_LENGTH	; buffer is never too
		call	DriveGetName			; small
		jc	nextDrive			; invalid drive
	;
	; Print out drive letter or label
	;
		add	ax, 'A'				; al = drive letter
		cmp	ax, 'Z'				;
		ja	specialLetter			;
		call	ScrWrite			;
		
printVolumeLabel:
	;
	; Volume label
	;
		mov	al, ':'
		call	ScrWrite
		mov	al, '['
		call	ScrWrite

		mov	ax, dx				; ax = drive number
		call	DiskRegisterDiskSilently	;-> bx = disk handle
		jc	noDisk
	;
	; bx    = disk handle
	; es:di = general_buf
	;
		call	DiskGetVolumeName		;-> es:di = ASCIIZ
		segmov	ds, es, ax			;
		mov	si, di				; ds:si = ASCIIZ name
DBCS<		call	ScrDBCStoSBCS					>
		call	ScrWriteString			;
noDisk:		
		mov	al, ']'
		call	ScrWrite
		call	ScrWriteNewLine
		
nextDrive:
		pop	cx				; restore counter
		inc	dx				; next drive number
		loop	driveLoop

		mov	di, PCET_NORMAL
		call	RobustCollectOff
		call	FileEndCommand
		
		.leave
		ret
specialLetter:
	;
	; Special letter: print drive name instead of volume label
	;
	; es:di = name
	;
		segmov	ds, es, ax
		mov	si, di
DBCS<		call	ScrDBCStoSBCS					>
		call	ScrWriteString
		jmp	printVolumeLabel
		
FileAvailableDrives	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDriveFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns free space on a given drive

CALLED BY:	ParseSeq
PASS:		ds, es	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDriveFreeSpace	proc	near
		.enter
		push	ds
	;
	; Get argument
	;
		mov	di, offset general_buf
		mov	cx, size general_buf
		call	FileGetArg
	;
	; Next line
	;
		call	RobustCollectOn
		call	ScrWriteNewLine
	;
	; Check for empty argument
	;
		dec	di			; get rid of null
		cmp	di, offset general_buf
		je	defaultDrive
	;
	; Get rid of the colon after drive name
	;
		dec	di			;
		mov	dx, ds:[di]		; this should be ':'
		cmp	dx, ':'			;
		jne	invalidArg		;
		clr	dx			;
		mov	ds:[di], dx		; make it a null terminator
	;
	; Find a match for it in the list of avaiable drives:
	; now we must have a null terminated string in general
	; buffer which is supposed to be drive name
	; (will rewrite with DriveFindByName later)
	;					- SJ
	; Setup a buffer on the stack for the name compare
	;
		sub	sp, DRIVE_NAME_MAX_LENGTH
		segmov	es, ss
driveFindLoop:
		mov	di, sp			; es:di = stack buffer
		mov	ax, dx			; al = drive number
		mov	cx, DRIVE_NAME_MAX_LENGTH
		call	DriveGetName		; internal_buf = ASCIIZ name
		jc 	nextDrive
	;
	; Now compare the found drive name and the argument the user gave us
	;
		mov	si, offset general_buf	; beginning of general buffer
DBCS<		call	ScrDBCStoSBCS					>
		mov	di, sp			; beginning of stack buffer
		clr	cx			; strings are null-terminated
SBCS<		call	LocalCmpStringsNoCase				>
DBCS<		call	PCComCmpStrings					>
		je	driveFound
nextDrive:
		inc	dx
		cmp	dx, DRIVE_MAX_DRIVES
		jb	driveFindLoop
		jmp	noMatch
driveFound:
	;
	; dx	= drive number
	;
		mov	ax, dx
		call	DiskRegisterDiskSilently ; bx = disk handle
		jc	noDiskette
		mov	si, offset general_buf
		call	ScrWriteString		 ; print  drive letter
		add	sp, DRIVE_NAME_MAX_LENGTH; remove the stack buffer
		segmov	es, ds
		jmp	getFreeSpace
defaultDrive:
	;
	; Examine the default drive
	;
		clr	cx
		call	FileGetCurrentPath	; bx = disk handle

getFreeSpace:
	;
	; Get the free space on disk whose handle is in bx
	;
		call	DiskGetVolumeFreeSpace	; dx:ax = bytes free on vol.
		mov	bx, offset general_buf	; es:bx = general_buf
		call	ScrDumpDecimal

		mov	bx, offset FreeSpaceStr
		call	ScrWriteStandardString
		
		mov	di, offset general_buf
		call	ScrWriteString

		mov	di, PCET_NORMAL
done:
		pop	ds
		call	RobustCollectOff
		call	FileEndCommand
		.leave
		ret
invalidArg:
		mov	bx, offset InvalidArgStr
		call	ScrWriteStandardString
		mov	di, PCET_ERROR
		jmp	done
noMatch:
		mov	bx, offset InvalidDrvStr
		call	ScrWriteStandardString
		mov	di, PCET_ERROR
		jmp	done
noDiskette:
		mov	bx, offset NoDiskStr
		call	ScrWriteStandardString
		mov	di, PCET_ERROR
		jmp	done
		
FileDriveFreeSpace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareToStandardString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two strings disregarding case(upper/lower)

CALLED BY:	GLOBAL
PASS:		ds:si = ASCIIZ 1 (str1)
		es:di = ASCIIZ 2 (str2)
RETURN:		ZF = 1 if equal, ZF = 0 if different
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareToStandardString		proc	near
		uses	bx, cx, ds
		.enter

		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]		; ds:si <- standard string

		clr	cx
SBCS<		call	LocalCmpStringsNoCase					>
DBCS<		call	PCComCmpStrings		; is case sensitive - sorry	>
		call	MemUnlock
		
		.leave
		ret
CompareToStandardString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileEchoBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turns on/off echo-back option

CALLED BY:	ParseSeq
PASS:		es = dgroup
RETURN:		echoBack variable is set according to the argument
DESTROYED:	ax, bx, cx, dx, si, di, bp, ds
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileEchoBack	proc	near
		.enter

		segmov	ds, es, bx
	;
	; Get Argument
	;
		mov	di, offset general_buf
		mov	cx, size general_buf
		call	FileGetArg		; es:di = one char past arg
DBCS<		call	ScrDBCStoSBCS					>
		dec	di			; remove nul char
		call	RobustCollectOn		; do output in bursts
		cmp	di, offset general_buf	; empty arg
		je	displayEcho
	;
	; Check for echo back ON
	;
		mov	di, offset general_buf	; es:di = argument
		mov	si, offset onStr
		call	CompareToStandardString	;-> ZF = 1 if same else ZF = 0
		je	echoOn
	;
	; Check for echo back OFF
	;
		mov	si, offset offStr
		call	CompareToStandardString	;-> ZF = 1 if same else ZF = 0
		je	echoOff
	;
	; Invalid arg
	;
		mov	bx, offset InvalidArgStr
		call	ScrWriteStandardString
		mov	di, PCET_ERROR
done:
		call	RobustCollectOff
		call	FileEndCommand
		.leave
		ret
echoOn:
		mov	es:[echoBack], 1
		jmp	displayEcho
echoOff:
		clr	es:[echoBack]
displayEcho:
	;
	; Feed new line
	;
		call	ScrWriteNewLine
	;
	; Display contents of echoBack variable
	;
		mov	bx, offset EchoBackStr
		call	ScrWriteStandardString

		mov	bx, offset offStr		; assume it is off
		cmp	es:[echoBack], 0
		jz	displayState
		mov	bx, offset onStr		; no, it is on

displayState:
		call	ScrWriteStandardString
		mov	di, PCET_NORMAL
		jmp	done
		
FileEchoBack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAcknowledgement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turns on/off echo-back option

CALLED BY:	ParseSeq
PASS:		ds, es = dgroup
RETURN:		ackBack variable in dgroup is set according to the argument
DESTROYED:	ax, bx, cx, dx, si, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileAcknowledgement	proc	near
		.enter

	;
	; Get Argument
	;
		mov	di, offset general_buf
		mov	cx, size general_buf
		call	FileGetArg		; es:di = one char past arg
DBCS<		call	ScrDBCStoSBCS					>
		dec	di			; remove nul char
		call	RobustCollectOn		; turn on burst mode
		cmp	di, offset general_buf	; empty arg
		je	displayAckBack
	;
	; Check for ackBack ON
	;
		mov	di, offset general_buf	; es:di = argument
		mov	si, offset onStr
		call	CompareToStandardString	;-> ZF = 1 if same else ZF = 0
		je	ackBackOn
	;
	; Check for echo back OFF
	;
		mov	si, offset offStr
		call	CompareToStandardString	;-> ZF = 1 if same else ZF = 0
		je	ackBackOff
	;
	; Invalid arg
	;
		mov	bx, offset InvalidArgStr
		call	ScrWriteStandardString
		mov	di, PCET_ERROR
done:
		segmov	ds, es, bx
		call	RobustCollectOff
		call	FileEndCommand
		.leave
		ret
ackBackOn:
		mov	es:[ackBack], 1
		jmp	displayAckBack
ackBackOff:
		clr	es:[ackBack]
displayAckBack:
	;
	; Display contents of ackBack variable
	;
		call	ScrWriteNewLine
		mov	bx, offset AckBackStr
		call	ScrWriteStandardString

		mov	bx, offset offStr	; assume it is off
		cmp	es:[ackBack], 0
		jz	displayState
		mov	bx, offset onStr

displayState:
		call	ScrWriteStandardString
		mov	di, PCET_NORMAL
		jmp	done
		
FileAcknowledgement	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDisplayDelimiter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the current delimiter char

CALLED BY:	ParseSeq
PASS:		ds, es - dgroup	
RETURN:		nothing	
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDisplayDelimiter		proc	near
		.enter

		call	ScrWriteNewLine
		mov	bx, offset ArgDelimiterStr
		call	ScrWriteStandardString
		mov	al, es:[delimiter]
		call	ScrWrite
		mov	di, PCET_NORMAL
		call	FileEndCommand
	
		.leave
		ret
FileDisplayDelimiter		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                FileChangeDelimiter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Change argument delimiter to passed character, or if
                none, display current delimiter.  Delimiter must be
		a printiable (non-control, non-space) character.

CALLED BY:      GLOBAL
PASS:           dx, es - dgroup
RETURN:         nothing
DESTROYED:      ax, bx, di
SIDE EFFECTS:   none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        cassie  4/22/94         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileChangeDelimiter    proc    near
		.enter

		mov	di, offset general_buf
		mov	cx, size general_buf
		call	FileGetArg
	;
	; If no arg, display the current delimiter
	;
		dec	di
		cmp	di, offset general_buf
		jbe	error
	;
	; IF arg is more than 1 char, bail.
	;
		dec	di
		cmp	di, offset general_buf
		jne	error
		mov	al, es:[di]
	;
	; The delimiter must lie between '!' and '~' inclusive
	;
		cmp	al, LAST_DELIMITER
		ja	error
		cmp	al, FIRST_DELIMITER
		jb	error
	;
	; Save and display the new delimiter
	;
		mov	es:[delimiter], al
		call	FileDisplayDelimiter
		ret

error:
		call	ScrWriteNewLine
		mov	bx, offset DelimiterErrStr	; assume error
		call	ScrWriteStandardString
		mov	di, PCET_ERROR
		call	FileEndCommand

		.leave
		ret
		
FileChangeDelimiter    endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOp2Common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the common stuff necessary for a file operation which
		takes 2 arguments.

CALLED BY:	INTERNAL - FileCopyFile, FileRenameFile
PASS:		ds, es - dgroup
		bx:dx - File routine
		bp - offset of string to print if successful
		ax - IACPRegisterType

RETURN:		carry flag set if error
DESTROYED:	

PSEUDO CODE/STRATEGY:
	read 2 pathname arguments
	call the File routine, which expects
		ds:si - source pathname
		es:di - destination pathname

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOp2Common		proc	near

EC <		call	ECCheckDS_dgroup				>

	push	ax, bx
	mov	di, offset general_buf		; es:di <- buffer
	mov	cx, ((size general_buf)/2)
	call	FileGetArg
	mov	ax, ERROR_BAD_ARGUMENT
	jc	toErrorPop

	;
	; Now, use the rest of the buffer to store the second arg.
	; This gives you and average of 512 bytes per arg.  Live with
	; it.
	;

	mov	cx, ((size general_buf)/2)
	mov	di, offset general_buf
	add	di, cx
	call	FileGetArg
	mov	ax, ERROR_BAD_ARGUMENT
	jc	toErrorPop
	pop	ax, bx

	mov	ds:[pathname], 0		; use relative paths
	;
	; Try to open the source file.  If it is open in another
	; app which has registered with IACP, the app will be asked
	; to close the file.
	;
	test	ax, mask IACP_RT_SOURCE
	jz	checkDestination
	push	ax, bx
	mov	di, (offset general_buf) + ((size general_buf)/2)
	mov	si, offset general_buf		; ds:si <- source file
						; ds:di <- dest
	call	FileSendOpenFile		
toErrorPop:
	LONG	jc	errorPop		; couldn't open file...maybe
						;  it doesn't exist!
	mov	bx, ax				; We were able to open the
	call	FileClose			;  file, now close it
	pop	ax, bx

checkDestination:
	;
	; Try to open the destination file.  If it is open in another
	; app which has registered with IACP, the app will be asked
	; to close the file.
	;
	test	ax, mask IACP_RT_DESTINATION
	jz	filesNotInUse
	mov	cx, IACP_NO_CONNECTION
	xchg	cx, ds:[iacpConnection]		; cx = src file iacpConnection 
	mov	si, di				; ds:si <- dest filename
	call	FileSendOpenFile
	jc	filesNotInUse			; couldn't open file...maybe
	push    bx				;  it doesn't exist!
	mov	bx, ax				; We were able to open the
	call	FileClose			;  file, now close it
	pop	bx

filesNotInUse:
	push	cx				; save source file iacp connect
	mov	si, offset general_buf		; ds:si <- source file
						; ds:di <- destination file
	mov	ax, dx				; bx:ax <- routine to call
	clr	cx, dx				; no disk handles
	call	ProcCallFixedOrMovable
	pop	cx				; source file iacp connection
	jc	error

	mov	bx, bp
	call	ScrWriteStandardString
	mov	di, PCET_NORMAL	

done:
	call	FileEndCommand			; will release iacpConnection
	;
	; The destination file's iacp connection was released in
	; FileEndCommand. Release the source file's connection now.
	;
EC <	cmp	es:[iacpConnection], IACP_NO_CONNECTION		>
EC <	ERROR_NE -1						>
	mov	es:[iacpConnection], cx
	call	PCComReleaseFileAccess
		
	ret

errorPop:
	;
	; We've not gotten as far as opening an IACP connection.
	; Set cx such that PCComReleaseFileAccess will do the right thing.
	;
	mov	cx, IACP_NO_CONNECTION		; no connection was opened
	add	sp, 4				; clear the stack
error:
	call	FileFileError
	mov	di, PCET_ERROR	
	jmp	done
FileOp2Common		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the common stuff necessary for a file operation which
		takes only 1 argument.

CALLED BY:	INTERNAL - FileLs, FileCd, FileMkDir, FileRmDir, FileRmFile
PASS:		ds, es - dgroup
		bx:ax - File routine
		bp - offset of string to print if successful

RETURN:		carry flag set if error,
			ax - error code
DESTROYED:	

PSEUDO CODE/STRATEGY:
	read 1 pathname argument
	call the File routine, which expects the pathname argument in ds:dx
	if error, print error string
	else print success string

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpCommon		proc	near

	.enter

		push	ax
EC <		call	ECCheckDS_dgroup				>
		mov	di, offset general_buf
		mov	cx, size general_buf
		call	FileGetArg
		mov	ax, ERROR_BAD_ARGUMENT
		pop	cx
		jc	error

		mov	dx, offset general_buf		; ds:dx <- pathname
		mov	ax, cx
		call	ProcCallFixedOrMovable
		jc	error
		mov	bx, bp
		call	ScrWriteStandardString
		mov	di, PCET_NORMAL
exit:
		call	FileEndCommand
	.leave
	ret

error:
		call	FileFileError
		stc
		mov	di, PCET_ERROR	
		jmp	exit

FileOpCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get an arument from the com port

CALLED BY:	GLOBAL

PASS:		es:di = destination for argument
		cx = max size of argument

RETURN:		carry set on error
		else es:di = one character past end of arg

DESTROYED:	ax, si

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/12/93		Initial version.
	cassie	2/24/95		use ds:[delimiter], instead of '!'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetArg	proc	far
		uses	bx, ds
		.enter
	;
	; we can only handle half as much if DBCS'd
	;
DBCS<		shr	cx						>
	; get the current delimiter
		
		LoadDGroup	ds, ax
		mov	bl, ds:[delimiter]

	; get pointer to end of buffer
		
		mov	si, di
		add	si, cx
readLoop:

	; read the argument char by char, until argument delimiter is
	; found, buffer is full, or a timeout occurs
		
		cmp	si, di
		je	translate
		call	ComReadWithWait
		jc	done
		cmp	al, bl
		je	gotit
EC <		Assert_fptr	esdi					>
		stosb
		jmp	readLoop
gotit:
		clr	al		; store a zero for the end-of-arg 
EC <		Assert_fptr	esdi					>
		stosb
translate:
SBCS<		segmov	ds,es,ax					>
		sub	si, cx
SBCS<		call	PCComDosToGeos					>
DBCS<		mov	di, si						>
DBCS<		call	ScrSBCStoDBCS					>
		clc
done:
		.leave
		ret
FileGetArg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileFileError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A file error occurred.  print a string describing it.

CALLED BY:	GLOBAL

PASS:		ax = FileError
		if the writeOnly flag is set us that string rather than
		the value in ax

RETURN:		Void.

DESTROYED:	bx

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/16/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileFileError	proc	far
		mov	bx, offset FileInUseString
		cmp	ax, ERROR_FILE_IN_USE
		je	printError
		mov	bx, offset FileNotFoundString
		cmp	ax, ERROR_FILE_NOT_FOUND
		je	printError
		mov	bx, offset FileExistsString
		cmp	ax, ERROR_FILE_EXISTS
		je	printError
		mov	bx, offset PathNotFoundString
		cmp	ax, ERROR_PATH_NOT_FOUND
		je	printError
		cmp	ax, ERROR_ACCESS_DENIED
		mov	bx, offset AccessDeniedString
		je	printError
		cmp	ax, ERROR_IS_CURRENT_DIRECTORY
		mov	bx, offset CurrentDirectoryString
		je	printError
		cmp	ax, ERROR_DIRECTORY_NOT_EMPTY
		mov	bx, offset DirectoryNotEmptyString
		je	printError
		cmp	ax, ERROR_SHORT_READ_WRITE
		mov	bx, offset InsufficientSpace
		je	printError
		cmp	ax, ERROR_INSUFFICIENT_MEMORY
		mov	bx, offset InsufficientMemory
		je	printError
		cmp	ax, ERROR_BAD_ARGUMENT
		mov	bx, offset BadArgumentString
		je	printError
		mov	bx, offset UnknownFileError
printError:
		call	ScrWriteStandardString
	.leave
	ret
FileFileError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrWritePaddedStringLJ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write a string with padding (left justifeid)

CALLED BY:	GLOBAL

PASS:		cx = total length of space
		ds:[bx] = string
		es - dgroup
		al = pad character

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/15/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrWritePaddedStringLJ	proc	near
	uses	si, bx, ds
	.enter
		mov	si, bx
		push	ax			; save the padding char
findLength:
		lodsb
		cmp	al, ' '
		je	gotLength
		cmp	al, '\0'
		je	gotLength
		loop	findLength
gotLength:
	; now write out the string
		push	cx			; save # of padding chars needed
		mov	si, bx			; ds:si <- string
		call	ScrWriteString
		pop	cx
		pop	bx			; restore the padding char
		jcxz	done
padLoop:
		mov	al, bl			; get padding character
		push	cx
		call	ScrWrite
		pop	cx
		loop	padLoop
done:
	.leave
	ret
ScrWritePaddedStringLJ	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrWritePaddedStringRJ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write a string with padding (right justifeid)

CALLED BY:	GLOBAL

PASS:		cx = total length of space
		es:[bx] = string (es is dgroup)
		al = pad character

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/15/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrWritePaddedStringRJ	proc	near
	uses	si, bx, ds
	.enter
		mov	si, bx
		push	ax
		segmov	ds, es, ax
findLength:
		lodsb
		cmp	al, ' '
		je	gotLength
		cmp	al, '\0'
		je	gotLength
		loop	findLength
gotLength:
		pop	ax
		push	bx
		mov	bl, al
		jcxz	writeString
padLoop:
		mov	al, bl			; get padding character
		push	cx
		call	ScrWrite
		pop	cx
		loop	padLoop
writeString:
		pop	si
	; now write out the string
		call	ScrWriteString
	.leave
	ret
ScrWritePaddedStringRJ	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrDivide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code to do an unsigned divide of two 32 bit numbers

CALLED BY:	GLOBAL

PASS:		dx:cx = dividend	
		bx:ax = divisor

RETURN:		dx:ax = quotient
		si:bx = remainder

DESTROYED:	Nada.

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/11/92		Initial version.
	ardeb	6/15/92		Changed to do everything in registers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrDivide	proc	near
		uses	cx, di, bp
		.enter
		clrdw	dibp		; clear partial dividend
		mov	si, 32		; bit counter (loop count)

		; loop through all bits, doing that funky divide thing
GUD_loop:
	;	shift another bit from the dividend into the partial

		saldw	dxcx
		rcl	bp
		rcl	di
	;
	; if partial dividend is >= divisor, must do some work.
	; 
		cmp	di, bx		; pdiv.high > divisor.high
		ja	GUD_work	; yes
		jne	GUD_next	; no
		cmp	bp, ax		; is equal; pdiv.low >= divisor.high?
		jb	GUD_next	; no

		; divisor <= partial dividend, do some work
GUD_work:
		inc	cx			; can only be in there once,
						;  and b0 must be 0 (it was
						;  shifted into b0 by the
						;  SALDW up there...)

		subdw	dibp, bxax		; partial dividend -= divisor
GUD_next:
		dec	si
		jg	GUD_loop		; continue with next iteration

		; set up results

		xchg	ax, cx		; dx:ax = quotient
		movdw	sibx, dibp	; si:bx = remainder (partial dividend)

		.leave
		ret			; all done
ScrDivide	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrDumpDecimal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	dump a hex value to the screen using DOS bios int 10h

CALLED BY:	GLOBAL

PASS:		dx:ax = dword
		es:bx = buffer to put charaters
		
RETURN:		buffer filled with string

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/23/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrDumpDecimal	proc	near
		uses	ax, bx, cx, dx, si, di
divisor	local	dword
num_buf	local	fptr	
		.enter
		clr	di			; leading zero flag
		mov	num_buf.high, es
		mov	num_buf.low, bx
		mov	divisor.high, 3b9ah
		mov	divisor.low, 0ca00h	; divisor = 10^9
		mov	cx, ax		; dx:cx = dividend
divLoop:
		mov	bx, divisor.high
		mov	ax, divisor.low
		call	ScrDivide	; dx:ax = quot, si:bx = remainder
		push	si		
		push	bx
		tst	di
		jz	leadingZero
doDigit:
		; ok, al = digit to display
		add	al, '0'
EC <		Assert_fptr	esdi					>
		stosb
		jmp	loopEnd
leadingZero:
		tst	ax
		jz	loopEnd
		mov	di, num_buf.low
		jmp	doDigit
loopEnd:
		; now divide the divisor by 10
		mov	dx, divisor.high
		mov	cx, divisor.low
		clr	bx
		mov	ax, 10
		call	ScrDivide
		mov	divisor.high, dx
		mov	divisor.low, ax
		pop	cx
		pop	dx	; old remainder becomes dividend dx:cx
		test	ax, 1	; divisors are 10^x so if low bit is lit
				; we must be at 10^0 so we are done
		LONG_EC	jz	divLoop
		tst	di
		jnz	lastDigit
		mov	di, num_buf.low
lastDigit:
		mov	al, cl	; last digit
		add	al, '0'
EC <		Assert_fptr	esdi					>
		stosb
		clr	al
EC <		Assert_fptr	esdi					>
		stosb
		.leave
		ret
ScrDumpDecimal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendFeedbackChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send a feedback char to let user know file transfer
		is still underway

CALLED BY:	INTERNAL
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendFeedbackChar		proc	near
		uses	ax,bx
		ForceRef feedback
		.enter

		mov	al, '.'
		call	ScrWrite

		.leave
		ret
SendFeedbackChar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSendSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the real physical file size.

CALLED BY:	ParseSeq
PASS:		ds, es - dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	get the argument and find the file.
	on any file error, set SF_Exit and send junk - goto done
	get actual physical size (add back in geosfileheader if approp)
	send size (dword) back.
	done - send no more

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	1/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSendSize	proc	near
	uses	si,es,ds
	.enter
EC <		call	ECCheckDS_dgroup				>
EC <		call	ECCheckES_dgroup				>
	;
	; get the argument
	;
		call	ReadIntoPathname
		jc	done			; timeout?
		test	ds:[sysFlags], mask SF_BAD_FILENAME
		jnz	fileError
	;
	; find the file.  Open it raw so that we get it's actually
	; physical space (no GeosFileHeader problems)
	;
		mov	dx, offset pathname	; ds:dx = filename
		mov	al, FILE_DENY_NONE or FILE_ACCESS_R or mask FFAF_RAW
		mov	bp, TRUE		; gain file access
		call	PCComFileOpen
		jc	fileError
	;
	; return the size
	;
		mov	bx, ax
		call	FileSize
		mov	si, ax		; dxsi <=size

		clr	al
		call	FileClose
		jc	fileError
	;
	; Want on the stack LO MEM <- si.low si.hi dl dh -> HI MEM
	;
		push	dx		; MSW fist
		push	si		; LSW next
		segmov	ds, ss, si
		mov	si, sp		; ds:si <- buffer to write
		mov	cx, size dword
		call	ComWriteBlock
		add	sp, size dword
done:
	.leave
	ret
fileError:
	;
	; We had problems accessing the file - send and abort to let
	; them know
	;
		BitSet	es:[sysFlags], SF_EXIT
		call	ComWrite
		jmp	done
FileSendSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a FileWrite and handles the error for pccom.

CALLED BY:	Internal

PASS:		bx - file handle
		cx - number of bytes to write
		ds:dx - buffer from which to write
		ds - dgroup

RETURN:		CF - SET on 
			FileWrite error 
			Bytes written < bytes to write
		if error
			ax = ERROR_SHORT_READ_WRITE
			     ERROR_ACCESS_DENIED
		else
			ax = destroyed
			cx = number of bytes written

DESTROYED:	nothing

SIDE EFFECTS:	on error:
		pccomAbortType <-
			= PCCAT_VOLUME_OUT_OF_SPACE if
				ERROR_SHORT_READ_WRITE
					or
				bytes written < bytes to write 
			= PCCAT_FILE_READ_ONLY if
				ERROR_SHORT_READ_WRITE or
		sysFlags <- SF_EXIT

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileWrite	proc	near
	uses	dx, bp
	.enter

EC <		call	ECCheckDS_dgroup				>

		mov	bp, cx			; bytes to write
		clr	al			; accept errors
		call	FileWrite
		jc	error

		mov	ax, ERROR_SHORT_READ_WRITE
		cmp	bp, cx			; bytes to write ?=
						; byte written
		jne	error

EC <		Destroy	ax						>
		clc				; all's well
done:
	.leave
	ret

error:
		mov	dh, PCCAT_VOLUME_OUT_OF_SPACE
		cmp	ax, ERROR_SHORT_READ_WRITE
		je	gotAbortType

		mov	dh, PCCAT_FILE_READ_ONLY
		Assert	e ax, ERROR_ACCESS_DENIED

gotAbortType:
		xchg	ax, dx			; ah <- PCComAbortType
						; dx <- FileError 
		call	PCComPushAbortType
		mov_tr	ax, dx			; ax <- FileError
		stc
		jmp	done

PCComFileWrite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a FileRead and handles the error for pccom.

CALLED BY:	Internal
PASS:		bx - file handle
		cx - number of bytes to read
		ds:dx - buffer into which to read
		ds - dgroup

RETURN:		CF - SET on
			FileRead error, except ERROR_SHORT_READ_WRITE

		if error
			ax = ERROR_ACCESS_DENIED
		else
			ax = destroyed
			cx = number of bytes read

DESTROYED:	nothing
SIDE EFFECTS:	on error:
		pccomAbortType <- 
			= PCCAT_ACCESS_DENIED if
				ERROR_ACCESS_DENIED
		sysFlags <- SF_EXIT

PSEUDO CODE/STRATEGY:
		ERROR_SHORT_READ_WRITE is interpreted as EOF, not an
		error.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileRead	proc	near
	uses	dx,bp
	.enter

EC <		call	ECCheckDS_dgroup				>

		mov_tr	bp, cx			; bytes to read

		clr	al			; accept errors
		call	FileRead
		jc	error

		Assert	e bp, cx

allsWell:
EC <		Destroy	ax			; CF - preserved	>
	;
	; CF - CLEAR coming out of here
	;
done:
	.leave
	ret

error:
		cmp	ax, ERROR_SHORT_READ_WRITE
		je	allsWell		; CF <- CLEAR

		mov	dh, PCCAT_ACCESS_DENIED
		xchg	ax, dx			; ah <- PCComAbortType
						; dx <- FileError
		call	PCComPushAbortType
		mov_tr	ax, dx			; ax <- FileError
		stc
		jmp	done

PCComFileRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a FileOpen and stuff any required abort type

CALLED BY:	(INTERNAL)	FileSendOpenFile
				FileSendSize

PASS:		al - open mode (FileAccessFlags)
		ds:dx - filename
		es - pccom dgroup
		bp - TRUE if want to gain file access on sharing violation.

RETURN:		
	IF file opened successfully:
		carry clear
		ax - PC/GEOS file handle

		The HF_otherInfo field of the returned handle contains
		the youngest handle open to the same file, or 0 if it
		is the only handle

	ELSE
		carry set
		ax - error code (FileError)
			ERROR_FILE_NOT_FOUND
			ERROR_PATH_NOT_FOUND
			ERROR_TOO_MANY_OPEN_FILES
			ERROR_SHARING_VIOLATION
			ERROR_WRITE_PROTECTED
			ERROR_INVALID_DRIVE
	
DESTROYED:	nothing
SIDE EFFECTS:	on error:
		pccomAbortType <- PCComAbortType
			(See ResolveFileErrorToPCCAT for listing.)

PSEUDO CODE/STRATEGY:
	open file
	ResolveFileErrorToPCCAT
	if (PCCAT_FILE_IN_USE and bp == TRUE )
		try opening file again
	else
		PushAbortType and return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	3/28/96    	Initial version
	PT	4/15/96		Used generic abort-handling code.
	PT	4/29/96		Allowance for gaining file access via IACP.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileOpen	proc	near

grabFile	local	word	push	bp
openFlags	local	word	push	ax	; al <- FileOpenAccessFlags

	uses	cx,bx,si
	.enter

EC <		call	ECCheckES_dgroup				>

openFile:
		call	FileOpen
		jc	error
done:
	.leave
	ret

error:
	;
	; There are only 6 documented error values:
	;   ERROR_FILE_NOT_FOUND
	;   ERROR_PATH_NOT_FOUND
	;   ERROR_TOO_MANY_OPEN_FILES 	- PCCAT_DEFAULT_ABORT
	;   ERROR_SHARING_VIOLATION	- PCCAT_FILE_IN_USE
	;   ERROR_WRITE_PROTECTED	- PCCAT_VOLUME_WRITE_PROTECTED
	;   ERROR_INVALID_DRIVE		- PCCAT_INVALID_DRIVE
	;
		mov	cx, ax			; FileError

		cmp	cx, ERROR_TOO_MANY_OPEN_FILES
		je	errorDone		; no mapping

		call	ResolveFileErrorToPCCAT	; ah <- PCComAbortType

		cmp	ah, PCCAT_FILE_IN_USE
		je	askForFileAccess

pushAbortType:
		call	PCComPushAbortTypeES
		mov	ax, cx			; FileError
errorDone:
		stc
		jmp	done

askForFileAccess:
	;
	; Should we gain file access for FILE_IN_USE error?
	;
		cmp	ss:[grabFile], TRUE
		jne	pushAbortType
	;
	; Now gain file access via IACP
	;
EC <		Assert e	es:[iacpConnection], IACP_NO_CONNECTION	>
NEC <		call	PCComReleaseFileAccess				>

		mov	si, dx			; filename
		mov	dx, offset pathname	; pathname
		clr	bx			; relative path
		push	bp			; locals
		call	PCComGainFileAccess	; bp <- IACPConnection
		mov	ds:[iacpConnection], bp
		pop	bp			; locals
		mov	dx, si			; filename
		jc	pushAbortType		; failed to connect
	;
	; Restore registers and attempt the file creation once again.
	;
		mov	ax, ss:[openFlags]	; al <- FileOpenFlags
		mov	ss:[grabFile], FALSE	; loop terminator
		jmp	openFile

PCComFileOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a FileCreate and push necessary PCComAbortType.

CALLED BY:	(INTERNAL)	FileReceiveStartCreateFile

PASSED:
	ah - FileCreateFlags
		FCF_NATIVE	set to force the format of the file to be
				the one native to the filesystem on which
				it's created, meaning primarily that DOS
				applications will be able to manipulate the
				file without doing anything special. There
				is no real reason for doing this for a file
				that will only be manipulated by PC/GEOS
				applications
				
				If FCF_MODE isn't FILE_CREATE_ONLY and the
				file already exists, but in a different
				state than that implied by this bit, then
				ERROR_FILE_FORMAT_MISMATCH will be returned
				and the file will be neither opened nor
				truncated.
				
		FCF_MODE 	one of three things:
			FILE_CREATE_TRUNCATE to truncate any existing file,
				creating the file if it doesn't exist.
	     		FILE_CREATE_NO_TRUNCATE to not truncate an existing 
				file, but create it if it doesn't exist
	     		FILE_CREATE_ONLY to fail if file of same name exists,
	     			but create it if it doesn't exist
	al - modes (FileAccessFlags). Must at least request write access
	     (FileAccessFlags <FE_NONE,FA_WRITE_ONLY>) if not read/write
	     access.
	cl - file attribute (FileAttrs) for file if it must be created.
	ds:dx - file name
	es - pccom dgroup
	bp - TRUE if want to gain file access on sharing violation.

RETURN:		CF SET if error:
			ax	= FileError
		CF CLEAR if success:
			ax 	= file handle

DESTROYED:	cx

SIDE EFFECTS:	
	pccomAbortType <- PCComAbortType
	(see ResolveFileErrorToPCCAT for list)

	if bp == TRUE
		iacpConnection <- IACPConnection

PSEUDO CODE/STRATEGY:
	create file
	ResolveFileErrorToPCCAT
	if (PCCAT_FILE_IN_USE and bp == TRUE )
		try creating file again
	else
		PushAbortType and return
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/17/96    	Initial version
	PT	4/29/96		Allowance for gaining file access via IACP.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileCreate	proc	near

grabFile	local	word	push	bp
creationFlags	local	word	push	ax	; ah <- FileCreateFlags
						; al <- FileAccessFlags
fileAttrs	local	word	push	cx	; cl <- FileAttrs

	uses	bx,si
	.enter

EC <		call	ECCheckES_dgroup				>

createFile:
		call	FileCreate
		jc	error

done:
	.leave
	ret

error:
	;
	; Got an error (ax), now map that into PCComAbortType. If
	; mapped to PCCAT_FILE_IN_USE, see if we want to gain file
	; access.
	;
		mov	cx, ax			; FileError
		call	ResolveFileErrorToPCCAT	; ah <- PCComAbortType

		cmp	ah, PCCAT_FILE_IN_USE
		je	askForFileAccess

pushAbortType:
		call	PCComPushAbortType
		mov_tr	ax, cx			; FileError
		stc
		jmp	done

askForFileAccess:
	;
	; Should we gain file access for FILE_IN_USE error?
	;
		cmp	ss:[grabFile], TRUE
		jne	pushAbortType
	;
	; Now gain file acess via IACP
	;
EC <		Assert e	es:[iacpConnection], IACP_NO_CONNECTION	>
NEC <		call	PCComReleaseFileAccess				>

		mov	si, dx			; filename
		mov	dx, offset pathname	; pathname
		clr	bx			; relative path
		push	bp			; locals
		call	PCComGainFileAccess	; bp <- IACPConnection
		mov	ds:[iacpConnection], bp
		pop	bp			; locals
		mov	dx, si			; filename
		jc	pushAbortType		; failed to connect
	;
	; Restore registers and attempt the file creation once again.
	;
		mov	ax, ss:[creationFlags]
		mov	cx, ss:[fileAttrs]
		mov	ss:[grabFile], FALSE	; loop terminator
		jmp	createFile

PCComFileCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a FileDelete but also handles sharing violation
		and other PCComAbortTypes.

CALLED BY:	(INTERNAL)	FileReceiveStart

PASS:		ds:dx	- filename to delete
		ds	- pccom dgroup
		bp	- TRUE, if want to gain file access for
				ERROR_FILE_IN_USE 

RETURN:		CF	- SET on error
		ax	- FileError
			ERROR_FILE_NOT_FOUND
			ERROR_ACCESS_DENIED
			ERROR_FILE_IN_USE

DESTROYED:	nothing
SIDE EFFECTS:	on error:
			pccomAbortType <- PCComAbortType
				PCCAT_ACCESS_DENIED
				PCCAT_FILE_IN_USE
			(See PCComAccessDenied for more.)

		iacpConnection <- IACPConnection
			IACP_NO_CONNECTION if didn't gain file access

PSEUDO CODE/STRATEGY:
	delete file
	if ERROR_FILE_NOT_FOUND
		return
	ResolveFileErrorToPCCAT
	if PCCAT_FILE_IN_USE and bp == TRUE
		try deleting file once again
	else
		push abort type and return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileDelete	proc	near

grabFile	local	word	push	bp

	uses	bx,cx,si,es
	.enter

deleteFile:
		call	FileDelete		; ax <- FileError
		jc	error

done:
	.leave
	ret

error:
	;
	; Ignore FILE_NOT_FOUND error, but map the others.
	;
		cmp	ax, ERROR_FILE_NOT_FOUND
		je	errorDone

		mov	cx, ax			; FileError
		call	ResolveFileErrorToPCCAT	; ah <- PCComAbortType

		cmp	ah, PCCAT_FILE_IN_USE
		je	askForFileAccess

pushAbortType:
		call	PCComPushAbortType
		mov_tr	ax, cx			; FileError
errorDone:
		stc
		jmp	done

askForFileAccess:
	;
	; Should we gain file access for FILE_IN_USE error?
	;
		cmp	ss:[grabFile], TRUE
		jne	pushAbortType
	;
	; Now gain file acess via IACP
	;
EC <		Assert e	ds:[iacpConnection], IACP_NO_CONNECTION	>
NEC <		call	PCComReleaseFileAccess				>

		mov	si, dx			; filename
		mov	dx, offset pathname	; pathname
		segmov	es, ds, bx		; dgroup
		clr	bx			; relative path
		push	bp			; locals
		call	PCComGainFileAccess	; bp <- IACPConnection
		mov	ds:[iacpConnection], bp
		pop	bp			; locals
		mov	dx, si			; filename
		jc	pushAbortType		; failed to connect

		mov	ss:[grabFile], FALSE	; loop terminator
		jmp	deleteFile

PCComFileDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileSetCurrentPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as FileSetCurrentPath, but handles PCComAbortType.

CALLED BY:	(INTERNAL)	FileReceiveStart
				FileSend
				FileLs
				FileCd

PASS:		bx - disk handle OR StandardPath
			If BX is 0, then the passed path is either
			relative to the thread's current path, or is
			absolute (with a drive specifier).

		ds:dx - Path specification.  The path MAY contain a
			drive spec, in which case, BX should be passed
			in as zero.
		es - pccom dgroup

RETURN:		carry - set if error
		ax - FileError (on errors)
		bx - disk handle if bx was passed as 0

DESTROYED:	nothing
SIDE EFFECTS:	on error:
			pccomAbortType <- PCComAborType
				(See PCComPathNotFound for listing.)

PSEUDO CODE/STRATEGY:
	call FileSetCurrentPath to do work

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileSetCurrentPath	proc	near
	.enter

EC <		call	ECCheckES_dgroup				>

		call	FileSetCurrentPath
		jc	error

done:
	.leave
	ret

error:
		push	ax			; FileError
		call	ResolveFileErrorToPCCAT
		call	PCComPushAbortTypeES
		pop	ax			; FileError
		stc
		jmp	done

PCComFileSetCurrentPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComFileNotFound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return correct mapping of ERROR_FILE_NOT_FOUND.

CALLED BY:	(INTERNAL)	ResolveFileErrorToPCCAT

PASS:		ds:dx	- null-terminated filename
		es	- pccom dgroup
		es:[sysFlags]	- SF_GEOS_FILE, SF_USE_DOS_NAME
			if SF_USE_DOS_NAME -> 
				filename is DOS 8.3 name
			else if SF_GEOS_FILE ->
				filename is Geos long name
			else
				filename is DOS 8.3 name

RETURN:		ah - PCComAbortType
			PCCAT_FILE_NOT_FOUND (default)
			PCCAT_INVALID_FILE_NAME

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Presently, we're not going to lexically analyze the filename,
	so we won't return PCCAT_INVALID_FILE_NAME. (4/14/96)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComFileNotFound	proc	near
	.enter

EC <		call	ECCheckES_dgroup				>


defaultError::
		mov	ah, PCCAT_FILE_NOT_FOUND

	.leave
	ret
PCComFileNotFound	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComPathNotFound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return correct mapping of ERROR_PATH_NOT_FOUND.

CALLED BY:	(INTERNAL)	PCComFileSetCurrentPath
				ResolveFileErrorToPCCAT

PASS:		ds:dx	- null-terminated pathname

RETURN:		ah - PCComAbortType
			PCCAT_PATH_NOT_FOUND (default)
			PCCAT_INVALID_PATH_NAME
			PCCAT_INVALID_DRIVE

DESTROYED:	al
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	PATH functions will return ERROR_PATH_NOT_FOUND when really
	it's a drive or disk problem, so that's why we have non-path
	errors.

	Presently, will NOT return PCCAT_INVALID_PATH_NAME. 4/14/96

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComPathNotFound	proc	near
	uses	cx
	.enter

EC <		call	ECCheckES_dgroup				>

	;
	; See if we're trying to access a non-existent drive.
	;
		call	PCComGetDrive		; al <- drive number
		jc	done
	;
	; Defualt error
	;
		mov	ah, PCCAT_PATH_NOT_FOUND
done:
	.leave
	ret
PCComPathNotFound	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComGetDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will retrieve the drive number from given path.

CALLED BY:	(EXTERNAL)	PCComPathNotFound

PASS:		ds:dx	- null-terminated pathname

RETURN:		CF	- SET if invalid drive name
			ah - PCCAT_INVALID_DRIVE
		al	- based drive number

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	If path doesn't contain drive specifier, will return the drive
	number of current working path.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComGetDrive	proc	near
	uses	cx,dx,si,es,ds
	.enter

		call	FSDLockInfoShared
		mov	es, ax			; locked FSInfoResource
		call	DriveLocateByName	; dx <- offset to file
						;  path w/o drive specifier
						; si <- DriveStatusEntry or 0
		jc	invalidDrive

		tst	si
		jz	relativePath		; no drive specifier

		mov	al, es:[si].DSE_number		
gotDriveNumber:
		clc

done:
		call	FSDUnlockInfoShared
	.leave
	ret

invalidDrive:
		mov	ah, PCCAT_INVALID_DRIVE
		jmp	done		
		
relativePath:
	;
	; Retrieve the drive of the current working path.
	;
		sub	sp, PATH_BUFFER_SIZE
		mov	si, sp
		segmov	ds, ss, cx		; ds:si - buffer for path
		mov	cx, PATH_BUFFER_SIZE
		call	FileGetCurrentPath	; bx <- disk handle
		add	sp, PATH_BUFFER_SIZE

		call	DiskGetDrive
		jmp	gotDriveNumber

PCComGetDrive	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComAccessDenied
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles ERROR_ACCESS_DENIED errors.

CALLED BY:	(INTERNAL)	ResolveFileErrorToPCCAT

PASS:		ds:dx	- null-terminated filename
		es	- dgroup
		es:[sysFlags]	- SF_GEOS_FILE, SF_USE_DOS_NAME
			if SF_USE_DOS_NAME -> 
				filename is DOS 8.3 name
			else if SF_GEOS_FILE ->
				filename is Geos long name
			else
				filename is DOS 8.3 name

RETURN:		ah - PCComAbortType
			PCCAT_ACCESS_DENIED (default)
			PCCAT_FILE_READ_ONLY
			PCCAT_FILE_IS_VOLUME
			PCCAT_FILE_IS_DIRECTORY

DESTROYED:	nothing
SIDE EFFECTS:	none
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComAccessDenied	proc	near
	uses	cx
	.enter

EC <		call	ECCheckES_dgroup				>

	;
	; Get file attributes
	;
		call	FileGetAttributes
		jc	defaultError
	;
	; Is file read-only?
	;
		mov	ah, PCCAT_FILE_READ_ONLY
		test	cx, mask FA_RDONLY
		jnz	done			; yep
	;
	; Is file actually a volume label?
	;
		mov	ah, PCCAT_FILE_IS_VOLUME
		test	cx, mask FA_VOLUME
		jnz	done			; yep
	;
	; Is file actually a directory name?
	;
		mov	ah, PCCAT_FILE_IS_DIRECTORY
		test	cx, mask FA_SUBDIR
		jnz	done			; yep

defaultError::
		mov	ah, PCCAT_ACCESS_DENIED
done:
	.leave
	ret
PCComAccessDenied	endp



Main		ends




