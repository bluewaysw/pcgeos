COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		pccomClient.asm

AUTHOR:		Robert Greenwalt, Apr  6, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/ 6/95   	Initial revision


DESCRIPTION:
	Code to do active stuff..  We'll <Esc>XF<0x4> and <Esc>XF<0x1>
	as oft as we dare.
		

	$Id: pccomClient.asm,v 1.1 97/04/05 01:26:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Internal/heapInt.def

Main	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMGET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the PCCom library to request a file from the
		connected machine (server/client terminology doesn't
		really apply..).

		This routine returns immediately, and communicates
		through status messages.

		The transfer is PCCOMABORT-able.

CALLED BY:	GLOBAL
PASS:		on stack:
		hptr - data block.  Contains null terminated geos-char
			dos filename (may contain wildcard chars) to get.
			This must contain a filename.  It may also
			contain a path.  If the path is absolute, it must
			start with a drive letter.  If the path is
			relative it is relative to the servers current
			working directory.  This directory may be
			changed via the PCComCD routine.  Examples:
			"*.*" - get everything from the servers cwd.
			"a:\temp\foo" - get the file foo from a:\temp
			"..\enstrunk\bar*" - get all files satisfing
				"bar*" from the cwd's parent's
				enstrunk directory.
			"\command.com" - this is undefined.  It may be
				relative, absolute, or it may result
				in an error.  Don't try it. 
			After the transfer is complete, this block
			will contain a null terminated list of
			geos-char DOS filenames received.
		word - number of bytes between reports or 0 for no reports
		optr - object to notify of completion/status 
		word - Message to send on completion/status
			method will receive:
				cx - PCComReturnType
				bxsi - bytes of this file transferred
		fptr - geos-char dest DOS path/file name.  This is
			primarily a path specifier.  The path must end
			with a slash char '\\'.  If the path is
			absolute, it must start with a drive letter.
			If the path is relative it is relative to the
			cwd path of the newly-spawned pccom thread.
			This is inherited from whatever thread called
			PCComInit.  If a filename is included 
			only the first file in a multi-file transfer
			will be renamed.  Wildcard characters are not
			allowed.  Examples:
			"" - put all files in the cwd with their normal
				names
			"a:\temp\" - put all files in a:\temp with
				their normal names
			"..\buddy" - put all files in the parent
				directory of the cwd, and rename the
				first file to "buddy"
			If a bad path is specified you will get a
			PCCRT_NO_ERROR back from this call, but you
			will get a PCCRT_COMMAND_ABORTED in your first
			status message.

RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
		ah - PCComAbortType
			PCCAT_DEFAULT_ABORT

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMGET	proc	far	myDataBlock:hptr, myNumStatus:word,
				myStatusDest:optr, myStatusMSG:word,
				myDestPath:fptr
	uses	bx,cx,si,di,ds,es

		ForceRef myDataBlock
		ForceRef myNumStatus
		ForceRef myStatusDest
	.enter
		call	ActiveStartupChecks
		LONG_EC	jc	done

	;
	; Copy the arguments into dgroup variables
	;
		segmov	es, ds, ax
		segmov	ds, ss, ax
		lea	si, ss:[myStatusMSG]
		mov	di, offset statusMSG
		mov	cx, 5
		rep movsw

		movdw	dssi, ss:[myDestPath]
		mov	di, offset destname	
		mov	cx, size pathname
		call	CopyNullTermStringToBuffer

		mov	si, offset destname
		mov	cx, size pathname
		segmov	ds, es, ax
		call	PCComGeosToDos

EC<		push	bx, si						>
EC<		mov	bx, es:[dataBlock]				>
EC<		call	ECCheckMemHandle				>
EC<		movdw	bxsi, es:[statusDest]				>
EC<		call	ECCheckOD					>
EC<		pop	bx, si						>

	;
	; Now send message to do the real work
	;
		mov	ax, MSG_PCCOM_PCGET
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; And signal that we're happy so far..
	;
		mov	al, PCCRT_NO_ERROR
done:
		mov	ah, PCCAT_DEFAULT_ABORT
EC<		Assert_PCComReturnType	al				>
	.leave
	ret
PCCOMGET	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMSEND
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the PCCom library to send a file to the
		connected machine.

		This routine returns immediately and communicates
		either through status messages.

		The transfer is PCCOMABORT-able.

CALLED BY:	GLOBAL
PASS:		on stack:
		fptr - Contains null terminated geos-char DOS filename
			(may contain wildcard chars) to send.  This
			must contain a filename.  It may also contain
			a path.  If the path is absolute, it must
			start with a drive letter.  If the path is
			relative it is relative to the cdw of
			the newly-spawned pccom thread.  This is
			inherited from whatever thread called
			PCComInit.  Examples:
			"*.*" - send everything from pccom's cwd.
			"a:\temp\foo" - send the file foo from a:\temp
			"..\enstrunk\bar*" - send all files satisfing
				"bar*" from the cwd's parent's
				enstrunk directory.
			"\command.com" - this is undefined.  It may be
				relative, absolute, or it may result
				in an error.  Don't try it. 
		word - number of bytes between reports or 0 for no reports
		optr - object to notify of completion/status
		word - Message to send on completion/statuss
			method will receive:
				cx - PCComReturnType
				bxsi - bytes of this file transferred
		fptr - geos-char dest DOS path/file name.  This is
			primarily a path specifier.  The path must end
			with a slash char '\\'.  If the path is
			absolute, it must start with a drive letter.
			If the path is relative it is relative to the
			server's cwd. This directory may be changed by
			using the PCComCD routine If a filename is
			included only the first file in a multi-file
			transfer will be renamed.  Wildcard characters
			are not allowed.  Examples:
			"" - put all files in the cwd with their normal
				names
			"a:\temp\" - put all files in a:\temp with
				their normal names
			"..\buddy" - put all files in the parent
				directory of the cwd, and rename the
				first file to "buddy"

RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_BAD_DEST_PATH
		ah - PCComAbortType
			PCCAT_DEFAULT_ABORT

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMSEND	proc	far	mySourcename:fptr, myNumStatus:word,
				myStatusDest:optr, myStatusMSG:word,
				myDestPath:fptr
	uses	bx,cx,si,di,es,ds

		ForceRef myNumStatus
		ForceRef myStatusDest
	.enter

		call	ActiveStartupChecks
		LONG_EC	jc	done

	;
	; We can set the destination path now, which lets us check the
	; path right away..
	;
		movdw	essi, ss:[myDestPath]
		call	SendSetDestination	; destname <- dest filename
						;             in remote DOS
						;	      code page
		jc	done

	;
	; Copy args into dgroup variables
	;
		segmov	es, ds, ax
		segmov	ds, ss, ax
		lea	si, ss:[myStatusMSG]
		mov	di, offset statusMSG
		mov	cx, 4
		rep movsw
	
		movdw	dssi, ss:[mySourcename]
		mov	di, offset pathname
		mov	cx, size pathname
		call	CopyNullTermStringToBuffer

		call	DoLocalGeosToDosOnPathnameES

EC<		push	bx, si						>
EC<		movdw	bxsi, es:[statusDest]				>
EC<		call	ECCheckOD					>
EC<		pop	bx, si						>

	;
	; Send msg to do the real work
	;
		mov	ax, MSG_PCCOM_PCSEND
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; And let everyone know we're happy thus far
	;
		mov	al, PCCRT_NO_ERROR
done:
		mov	ah, PCCAT_DEFAULT_ABORT
EC<		Assert_PCComReturnType	al				>
	.leave
	ret
PCCOMSEND	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMSTATUS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the last posted status of an active file
		transfer.

CALLED BY:	GLOBAL
PASS:		on stack:
		fptr - buffer for StatusReply struct
		fptr - buffer for current transfers pathname
			(PATH_BUFFER_SIZE long!)
RETURN:		al - PCComReturnType
			PCCRT_FILE_STARTING
			PCCRT_TRANSFER_CONTINUES
			PCCRT_FILE_COMPLETE
			PCCRT_TRANSFER_COMPLETE
			PCCRT_TRANSFER_ABORTED
		ah - PCComAbortType

DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMSTATUS	proc	far	myBuffer:fptr.StatusReply, myFilename:fptr
	uses	cx,si,di,ds,es
	.enter
		LoadDGroup	ds, ax
	;
	; P the sem - to ensure data freshness
	;
		PSem	ds, statusSem, TRASH_AX_BX
	;
	; Copy the data
	;
		mov	cx, size statusName
		mov	si, offset statusName
		movdw	esdi, ss:[myFilename]
	;
	; Check if the resulting pointers would exceed boundaries
	;
EC <		push	si, di						>
EC <		add	di, cx						>
EC <		add	si, cx						>
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
EC <		pop	si, di						>
		rep movsb

		movdw	esdi, ss:[myBuffer]
		mov	cl, 4
	;
	; Check if the resulting pointers would exceed boundaries
	;
EC <		push	si, di						>
EC <		add	di, cx						>
EC <		add	si, cx						>
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
EC <		pop	si, di						>
		rep movsw

		mov	cl, ds:[statusCond]
		mov	ch, ds:[pccomAbortType]
	;
	; V the sem and we're on our way!
	;
		VSem	ds, statusSem, TRASH_AX
		mov	ax, cx
EC<		Assert_PCComReturnType	al				>
	.leave
	ret
PCCOMSTATUS	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMCD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the far end to change the working directory.

CALLED BY:	GLOBAL
PASS:		on stack:
		fptr - buffer (PATH_BUFFER_SIZE) for the null
			terminated geos-char pathname. 
			It can be absolute or relative.  If it is
			absolute it must begin with a drive
			specification.  If it is relative it is
			relative to the servers cwd. Examples:
			"c:\" - goes to the root dir of the C drive
			"" - goes to the servers startup directory.
			"a:" - goes to the root dir of the A drive

RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_COMMAND_ABORTED
			PCCRT_BAD_DEST_PATH
		ah - PCComAbortType

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The argument may be a full or relative path and may
		include a drive specification.  For absolute paths you
		must include a drive letter.  Do not \ terminate.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMCD	proc	far	myDirName:fptr
	uses	cx,dx
	.enter

	mov	ax, MSG_PCCOM_PCCD
	movdw	cxdx, myDirName
	call	PCComDirCommon

	.leave
	ret
PCCOMCD	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMPWD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieves the current path name on the remote machine.

CALLED BY:	GLOBAL
PASS:		on stack:
		fptr - buffer (PATH_BUFFER_SIZE) for the null
			terminated Upper-cased geos-char dos pathname.

RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_COMMAND_ABORTED
			PCCRT_BAD_DEST_PATH
		ah - PCComAbortType

	   	Buffer filled in with the current working path.

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	28 june 95	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMPWD	proc	far	myBuffer:fptr
	uses	cx,dx
	.enter
	mov	ax, MSG_PCCOM_PCPWD
	movdw	cxdx, myBuffer
	call	PCComDirCommon

	.leave
	ret
PCCOMPWD	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMMKDIR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a directory on the remote machine

CALLED BY:	GLOBAL
PASS:		on stack:
		fptr - to a buffer which contains a null terminated
			geos-char pathname.  This must contain a
			dirname.  It may also contain a path.  If the
			path is absolute, it must start with a drive
			letter.  If the path is relative it is
			relative to the servers current working
			directory.  This directory may be changed via
			the PCComCD routine.  Examples:
			"a:\temp\foo" - creates a directory "foo" in
				a:\temp
			"..\enstrunk\bar" - creates a directory "bar"
				in the cwd's parent's enstrunk
				directory.
			"\command.com" - this is undefined.  It may be
				relative, absolute, or it may result
				in an error.  Don't try it. 
			If the directory already exists you will get a
			PCCRT_BAD_DEST_PATH

RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_BAD_DEST_PATH
			PCCRT_COMMAND_ABORTED			
		ah - PCComAbortType

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMMKDIR	proc	far	myDirName:fptr
	uses	cx, dx
	.enter

	mov	ax, MSG_PCCOM_PCMKDIR
	movdw	cxdx, myDirName
	call	PCComDirCommon

	.leave
	ret
PCCOMMKDIR	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDirCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine that CALLS the corresponding method handlers.

CALLED BY:	PCCOMCD, PCCOMPWD, PCCOMMKDIR
PASS:		ax - Method number to call
		cx,dx,bp - parameters to pass to method handler

RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_BAD_DEST_PATH
			PCCRT_COMMAND_ABORTED			
		ah - PCComAbortType

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/23/96    	Header added

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDirCommon	proc	near
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter

		mov_tr	di, ax
		call	ActiveStartupChecks
		jc	done

		sub	sp, size pathname
	;
	; check if we need to copy the buffer.  In CD and MKDIR we
	; need to else the Geos->Dos char translation will change the
	; original data and repeat calls won't work.  With PWD, if
	; we copy the buffer, we will put the incoming path in a temp
	; buffer and not return it..  just use the original buffer.
	;
		cmp	di, MSG_PCCOM_PCPWD
		je	justDoIt
	;
	; OK, now move the pathname of stuff from cxdx to the stack so
	; the translations don't modify the originals
	;
		push	ds, es, si, di
		mov	ds, cx
		mov	si, dx
		segmov	es, ss
		mov	di, sp
		add	di, 8		; to get back to the buffer..
		mov	dx, di
		mov	cx, size pathname
		rep movsb
		mov	cx, es
		pop	ds, es, si, di
justDoIt:
		mov_tr	ax, di
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; reset things
	;
		add	sp, size pathname
		clr	ds:[err]
		call	ActiveShutdownDuties
done:
EC<		Assert_PCComReturnType	al			>
	
	.leave
	ret
PCComDirCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMREMARK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Log a remark on the remote machine

CALLED BY:	GLOBAL
PASS:		on stack:
		fptr - to a buffer which contains a null terminated
		       geos-char remark, up to PATH_BUFFER_SIZE long.
		       Use the '\r' escape code to get a carriage return.

RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_COMMAND_ABORTED
		ah - PCComAbortType

DESTROYED:	nothing

	Name	Date		Description
	----	----		-----------
	jon	26 june 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMREMARK	proc	far	remark:fptr
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter
		call	ActiveStartupChecks
		jc	done

	;
	; Grab the one incoming piece o data and go to work
	;
		movdw	cxdx, remark
		mov	ax, MSG_PCCOM_PCREMARK
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; reset things
	;
		clr	ds:[err]
		call	ActiveShutdownDuties
done:
EC<		Assert_PCComReturnType	al			>
	
	.leave
	ret
PCCOMREMARK	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMGETFILESIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of a remote file.

CALLED BY:	GLOBAL
PASS:		on stack:
		fptr - to a dword buffer to hold the requested file
			size.
		fptr - to a buffer which contains a null terminated
			geos-char DOS pathname.  This must contain a
			filename.  It may also contain a path.  If the
			path is absolute, it must start with a drive
			letter.  If the path is relative it is
			relative to the servers current working
			directory.  This directory may be changed via
			the PCComCD routine.  Examples:
			"a:\temp\foo" - get the size of file foo from
				a:\temp
			"..\enstrunk\bar" - get the size of "bar"
				from the cwd's parent's enstrunk
				directory.
			"\command.com" - this is undefined.  It may be
				relative, absolute, or it may result
				in an error.  Don't try it. 
RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_COMMAND_ABORTED
		ah - PCComAbortType

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	OK..  my idea here is to not write very much :)  We can set an
indicator to force an abort during a normal recieve after we get the
file size.  There's a trade off of speed vs accuracy here, and since the
mechanism is so course the trade off is pretty severe.  We can repeat
the request and check for repeat answers to verify accuracy, but this
would take a while.  We could not do any sort of verification..  hmm

That was for the original method - the new method (FZ command) is
pretty quick.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMGETFILESIZE	proc	far	myBuffer:fptr.dword, myFilename:fptr
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter
		call	ActiveStartupChecks
		LONG	jc	done
	;
	; stuff the given filename into dgroup:pathname
	;
		segmov	es, ds, ax
		movdw	dssi, ss:[myFilename]
		mov	di, offset pathname
		mov	cx, size pathname
		call	CopyNullTermStringToBuffer
	;
	; Translate the pathname
	;
		call	DoLocalGeosToDosOnPathnameES
	;
	; Check if we're in robust mode - if so, just use the new
	; command <ESC>FZ[filename]!  If the other side can't support
	; robust mode, they won't understand FZ either.
	; It returns either an abort packet (file not found) or a
	; dword that is the files size
	;
		cmp	es:[negotiationStatus], PNS_ROBUST
		LONG_EC	jne	normalMethod
	;
	; ok, tack a null onto the end of the pathname
	;
		sub	si, ss:[myFilename].offset	; length of src+1
		mov	cx, si
		add	si, (offset pathname)-1
		clr	ax
		mov	es:[si], ax
	;
	; Send the command
	;
		segmov	ds, es
		mov	si, offset pathname
		mov	ax, 'F' or ('Z' shl 8)
		call	PCComSendCommand
		mov	dl, PCCRT_COMMAND_ABORTED	; failed case
		push	es				; dgroup
		jc	robustCleanUp
		call	ComWriteBlock
		jc	robustCleanUp

	;
	; Await the answer
	;
		movdw	esdi, ss:[myBuffer]
		mov	cx, 4				; #bytes to read
readLoop:
		call	ComRead
		jc	robustCleanUp
		tst	ds:[err]
		jnz	robustCleanUp
		stosb
		loop	readLoop
		mov	dl, PCCRT_NO_ERROR

robustCleanUp:
		mov	al, dl				; al <= return code
		pop	es				; dgroup
		call	ActiveShutdownDuties
		jmp	done

normalMethod:
	;
	; set flag to indicate to the GET code that we don't really
	; want the file's data
	;
		or	es:[sysFlags], mask SF_JUST_GET_SIZE
	;
	; Send msg to do real work, and go to sleep - this will abort
	; right after it gets the filesize and SendStatus will realize
	; it needs to wake us..
	;
		mov	ax, MSG_PCCOM_PCGET
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		PSem	es, pauseSem, TRASH_AX_BX
	;
	; Ok, we have been woken, but we don't know if we found the
	; file or it wasn't there..  so check the statusCond.
	; 	1) File didn't exist (or we couldn't access it)
	;		we'll get a PCCRT_COMMAND_ABORTED
	;	2) File existed, and takes longer than one block to
	;		get - we'll get a PCCRT_NO_ERROR
	;
	;		** AND ** the server will send a NAK_QUIT..
	;			  we'd better eat it!
	;
	;	3) File existed, but was small enough to be fetched in
	;		the first block - we'll get something like a
	;		PCCRT_FILE_COMPLETE (which isn't the first two
	;		cases) 
	;
		clr	dx
		movdw	dssi, ss:[myBuffer]
		PSem	es, statusSem, TRASH_AX_BX
		movdw	dicx, es:[statusFileSize]
		mov	dl, es:[statusCond]
		VSem	es, statusSem, TRASH_AX_BX
		movdw	ds:[si], dicx
		cmp	dl, PCCRT_COMMAND_ABORTED	; check for #1
		jne	fileExists
		mov	ah, PCCAT_REMOTE_FILE_NOT_FOUND
		call	PCComPushAbortTypeES
		jmp	cleanUp
fileExists:
		cmp	dl, PCCRT_NO_ERROR		; check for #2
		mov	dl, PCCRT_NO_ERROR		; else #3
		jne	cleanUp
		call	ComReadWithWait		; eat the resulting
						; NAKQUIT
cleanUp:
		mov	al, dl			; al <= PCComReturnType
		mov	ah, es:[pccomAbortType]
		clr	es:[err]
		test	es:[sysFlags], mask SF_SUSPEND_INPUT
		jz	done			; already clear?
		call	ActiveShutdownDuties	; do it now
done:
EC<		Assert_PCComReturnType	al				>
	.leave
	ret
PCCOMGETFILESIZE	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMDIR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a directory listing from the remote computer.

CALLED BY:	GLOBAL
PASS:		on stack:
			hptr - handle of block to stuff the dos-char
				listings into
			PCComDirDetailLevel - inicates level to request
			fptr - geos-char DOS filespec argument to pass
				with LS
RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_COMMAND_ABORTED
			PCCRT_MEMORY_ALLOC_ERROR
		ah - PCComAbortType

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
es:di - next char
cx - num chars
si - size
bx - handle		
bp - retries
dx - "<ESC>;" - two chars we look for

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	5/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMDIR	proc	far	myDataBlock:hptr, 
				myDetailLevel:PCComDirDetailLevel,
				fileSpec:fptr
	fileSpecLength	local	word	

	ForceRef	myDataBlock
	ForceRef	myDetailLevel
	ForceRef	fileSpec
	ForceRef	fileSpecLength

	uses	bx,cx,dx,si,di,bp, es, ds
	.enter
		call	ActiveStartupChecks
		LONG	jc	noPopDone
	;
	; turn on the echoback and acknowledgement - note that done:
	; is expecting the return value on the stack
	;
		call	SendEchoOn
		mov	al, PCCRT_COMMAND_ABORTED
		push	ax
		LONG	jc	done
		stc
		call	SendAckOn
		LONG	jc	echoOffDone
		pop	ax
	;
	; fetch variables (myDatablock -> bx, myDetailLevel -> stack)
	;
		mov	bx, ss:[myDataBlock]
EC<		call	ECCheckMemHandle		>
		call	MemLock

		call	PCComDirProcessFilespec
	;
	; set initial values.  If robust, no retries
	;
		mov	dx, (1bh shl 8) or ';'
		mov	bx, MAX_TRIES
		cmp	ds:[negotiationStatus], PNS_ROBUST
		jne	retry
		mov	bx, 1
retry:
		call	PCComDirStoreData
		jc	unlockDone
	;
	; found ESC! - Now make sure it's followed by ACK
	;
		stc
		call	WaitForAck
		LONG	jc	retry
	;
	; Null terminate the buffer
	;
		clr	al
EC<		Assert_fptr	esdi				>
		stosb
	;
	; Indicate good results
	;
		mov	al, PCCRT_NO_ERROR
	;
	; Pack up and go home - don't forget to reset the sysFlags
	;
unlockDone:
		push	ax
		push	bx
		mov	bx, ss:[myDataBlock]
		call	MemUnlock
		pop	bx
		stc
		call	SendAckOff
echoOffDone:
		call	SendEchoOff
done:
		pop	ax
		call	ActiveShutdownDuties
noPopDone:
EC<		Assert_PCComReturnType	al				>
	.leave
	ret
PCCOMDIR	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMLISTDRIVES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the list of availible drives from the Remote computer.

CALLED BY:	GLOBAL
PASS:		on stack
		hptr - mem handle to realloc and stuff geos-char data
			into.
RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_COMMAND_ABORTED
			PCCRT_MEMORY_ALLOC_ERROR
		ah - PCComAbortType

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
es:di - next char
cx - num chars
si - size
bx - handle
dx - chars to look for
bp - char pattern to look for (double spaces)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	6/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMLISTDRIVES	proc	far	myDataBlock:hptr
		uses	bx,cx,dx,di,si,bp,es,ds

		.enter
		call	ActiveStartupChecks
		jc	done

		mov	bx, ss:[myDataBlock]
		call	PCComDoListDrives

		call	ActiveShutdownDuties
done:
EC<		Assert_PCComReturnType	al				>
		.leave
		ret
PCCOMLISTDRIVES	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDoListDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the actual work of listing drives

CALLED BY:	PCCOMLISTDRIVES
PASS:		ds 	- dgroup
		bx	- hptr to block we can realloc and stuff with
			  the results
RETURN:		al	- PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIALIZED
			PCCRT_COMMAND_ABORTED
			PCCRT_MEMORY_ALLOC_ERROR

DESTROYED:	everything, ds - preserved
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	9/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDoListDrives	proc	near
	.enter
EC<		call	ECCheckDS_dgroup				>
	;
	; setup initial stuff and send the command
	;
		call	ListDrivesCommandSend
		jc	done
	;
	; read drive leter and colon
	;
	;	first ensure we have space for one more char
	;
startSpace:
		push	ax
		call	MakeSpace	; sets cx to space left in buff
		pop	ax
		jc	memError
	;
	; Now accept that first name char and finish reading the name
	;
driveStart:
		call	ListDrivesStartReading
		jc	done
	;
	; Check on finishing the name - decide if we are done
	;
		call	ListDrivesPostNameProcessing
		jc	translateName
		loop	driveStart
		jmp	startSpace

translateName:
	;
	; Translate the chars in the buffer from Dos to Geos
	;
		push	ax
		segxchg	ds, es
		clr	cx,si
		call	PCComDosToGeos
		segxchg	ds, es
		pop	ax
	;
	; Now Unlock and reset the Echo
	;
done:
		call	MemUnlock
		push	ax
		call	SendEchoOff
		pop	ax
		.leave
		ret
memError:
		mov	al, PCCRT_MEMORY_ALLOC_ERROR
		jmp	done
PCComDoListDrives	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComPCGet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Much like pcget.  Give us a file name (which may
		contain wildcard chars) and we'll get it for you.

CALLED BY:	PCComGet and PCCOMGETFILESIZE
PASS:		nothing
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
SIDE EFFECTS:	
		on abort,
			pccomAbortType <- extended abort information

PSEUDO CODE/STRATEGY:

	send:	<Esc>XF<0x4>filename\0
	receive:sync
fileLoop:
	receive:sync
	receive:filename\0
	send:	sync
FileReceive Begins
		receive:file size
	blockLoop:
		receive:BLOCK_START block_data BLOCK_END crc
				note - under the new protocol the first block
				is a repeat of the filename (since these
				blocks are crc checked and repeated upto three
				times.
		send:	sync
		loop until all blocks are sent
		receive:checksum
		send:	ack
FileReceive Ends
	loop until all files are sent
	receive:END_COMMAND

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComPCGet	method	dynamic PCComClass, MSG_PCCOM_PCGET
	savedEchoBack	local	byte	; previous echo back state
	uses	ax,cx,dx
	.enter

		LoadDGroup es, ax
		mov	al, es:[echoBack]
		mov	ss:[savedEchoBack], al	; save echoback state
		mov	es:[echoBack], 0
		mov	es:[err], 0
		mov	es:[readCmd], RECV_COMMAND

		PSem	es, statusSem, TRASH_AX_BX
		clrdw	es:[statusFileSize]
		clrdw	es:[fSize]
		VSem	es, statusSem, TRASH_AX_BX
	;
	; set the destination path
	;
		call	GetSetDestination
		jc	toAbort

		call	GetXmitCommand
toAbort:
		LONG	jc	abort

	;
	; Now wait for a sync
	;
		cmp	es:[negotiationStatus], PNS_ROBUST
		je	notTwoSyncs

		call	Sync
		LONG_EC	jc	storeAbortType		; timed-out
notTwoSyncs:
		call	Sync
		LONG_EC	jc	storeAbortType		; timed-out

		cmp	al, SYNC
		je	anotherFile			; got synched

		cmp	al, NAK
		LONG_EC	jne	abort
	;
	; At this point, things are really hosed, because we should
	; never get a NAK at this point.  But if we do, we should wait
	; for the END_COMMAND before aborting.
	;
		mov	al, END_COMMAND
		call	WaitForChar
		jmp	abort

anotherFile:
		cmp	es:[negotiationStatus], PNS_ROBUST
		je	noXFerCommand

		mov	al, RECV_COMMAND
		call	WaitForChar
		LONG_EC	jc	abort
noXFerCommand:
	;
	; we've got to make sure there's space in the dataBlock for
	; the incoming filename
	;
		call	PrepBufferForNextName
		LONG_EC	jc	abort

	;
	; and get the incoming name - put it in dgroup:pathname
	;
		call	ReadIntoPathname
		LONG_EC	jc	abort
		jmp	noError

haveDestname:
	;
	; we have a requested name change..  don't use the filename
	; sent by the server, use our dgroup:destname instead
	;
		mov	di, offset pathname
		mov	si, offset destname
		mov	cx, size pathname
	;
	; Check if the resulting pointers would exceed boundaries
	;
EC <		push	si, di						>
EC <		add	di, cx						>
EC <		add	si, cx						>
EC <		Assert_fptr	dssi					>
EC <		Assert_fptr	esdi					>
EC <		pop	si, di						>
		rep movsb
		andnf	ds:[sysFlags], not (mask SF_BAD_FILENAME)
		jmp	haveName

noError:
		test	ds:[sysFlags], mask SF_USE_DOS_NAME
		jnz	haveDestname
	;
	; Acknowledge transfer start with SYNC character. Makes
	; sure we're all in sync.
	;
haveName:
		cmp	es:[negotiationStatus], PNS_ROBUST
		je	noMoreSync

		mov	al, SYNC
		call	ComWrite
		tst	ds:[err]
		jnz	abort
noMoreSync:
	;
	; Now Actually get all the data, make the file, etc
	;
		call	FileReceive
		tst	ds:[err]
		jnz	abort

	;
	; if there is another file we will get a SYNC..  if there are
	; no more files we will get an END_COMMAND - which is it?
	;
		call	ComReadWithWait
		cmp	al, END_COMMAND
		je	finished
		cmp	al, SYNC
		LONG_EC	je	anotherFile

storeAbortType:
	;
	; We were expecting a SYNC, and didn't get it - we've lost the
	; connection.  Don't set the err though..  we're aborting
	; anyway and it'll confuse a Base mode GetFileSize.
	;
		mov	ah, PCCAT_CONNECTION_LOST
		call	PCComPushAbortType
		clr	ds:[err]
abort:
		mov	cl, PCCRT_COMMAND_ABORTED
		push	cx
if	_DEBUG
		mov	al, 'Z'
		call	DebugDisplayChar
endif
		jmp	done

finished:
	;
	; Send out last status message and then clean out the junk in
	; our dgroup
	;
		mov	cl, PCCRT_TRANSFER_COMPLETE
		push	cx
done:
		mov	al, ss:[savedEchoBack]
		mov	ds:[echoBack],al
		clr	ax
		mov	ds:[dataBlock], ax
		call	ComDrainQueue
		call	FILEPOPDIR
		pop	cx
		call	SendStatus
	.leave
	ret
PCComPCGet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComPCSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a file to the remote computer

CALLED BY:	MSG_PCCOM_PCSEND
PASS:		dgoup:[pathname] - DOS name/pattern to send in remote DOS 
				   code page
		dgroup:[destname] - optional destination filename in the 
				    remote DOS code page.
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComPCSend	method dynamic PCComClass, 
					MSG_PCCOM_PCSEND
	uses	ax, cx, dx, bp
	.enter
		LoadDGroup	es
		segmov	ds, es

		mov	al, FILE_SEND_ACTIVE
		call	FileSend
	.leave
	ret
PCComPCSend	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComPCCD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub to send a CD command

CALLED BY:	MSG_PCCOM_PCCD
PASS:		*ds:si	= PCComClass object
		ds:di	= PCComClass instance data
		ds:bx	= PCComClass object (same as *ds:si)
		es 	= segment of PCComClass
		ax	= message #
		cx:dx	= buffer to read/write

RETURN:		al	= PCComReturnType
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComPCCD	method dynamic PCComClass, 
					MSG_PCCOM_PCCD
		call	PCComDoCD
		push	ax
		call	ComDrainQueue
		pop	ax
		ret
PCComPCCD	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDoCD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a CD command!

CALLED BY:	Internal
PASS:		cx:dx	= buffer containing path to CD to

RETURN:		al 	= PCComReturnType
		ds	= dgroup

DESTROYED:	most everything but cx, dx, and bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	turn on remote Echoback
	turn on remote ackback
	do CD
	record reply
	turn off remote ackback
	turn off remote echoback	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDoCD	proc near
	uses	cx, dx, bp
	.enter
	;
	; Setup some pointers to the buffer
	;
		mov	ds, cx
		mov	si, dx			; ds:si = buffer
		mov	es, cx
		mov	di, dx			; es:di = buffer
		mov	cx, PATH_BUFFER_SIZE
	;
	; first, translate it
	;
		call	PCComGeosToDos
	;
	; Now check for null
	;
		clr	al
		repnz scasb
		mov	al, PCCRT_BAD_DEST_PATH
		LONG_EC jnz	errorNoAckOff
	;
	; we need the size of the pathname excluding the null
	;
		sub	dx, di		; dx = (-str length including null)
		not	dx		; dx = str length excluding null
		mov	cx, dx		; cx = str length excluding null

		LoadDGroup	ds, ax

		clc			; no echo
		call	SendAckOn
		mov	al, PCCRT_COMMAND_ABORTED
		LONG_EC jc	errorNoAckOff
	;
	; check for "X:\0"
	;
		push	es:[si+2]	; will be clobbered if "X:\0"
		cmp	cx, 2
		jne	finished

		mov	di, si
		inc	di
		cmp	{byte}es:[di], ':'
		jne	finished

		inc	di
		mov	{word}es:[di], '\\'
		inc	cx
finished:

	;
	; send CD command
	;
		call	RobustCollectOn
		mov	ax, CHANGE_DIR_COMMAND
		call	PCComSendCommand

		segxchg	ds, es		; ds=buf seg, es=dgroup
		call	ComWriteBlock
		mov	al, es:[delimiter]
		call	ComWrite
		segxchg	ds, es		; ds=dgroup, es=buf seg
		call	RobustCollectOff
	;
	; wait for Ack
	;
		clc
		call	WaitForAck
		mov	al, PCCRT_NO_ERROR
		jnc	done
		mov	al, PCCRT_COMMAND_ABORTED
done:
		pop	es:[si+2]	; restore possibly clobberd word
		clc
		call	SendAckOff
errorNoAckOff:
	.leave
	ret
PCComDoCD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComPCPWD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub to send a PWD command

CALLED BY:	MSG_PCCOM_PCPWD
PASS:		*ds:si	= PCComClass object
		ds:di	= PCComClass instance data
		ds:bx	= PCComClass object (same as *ds:si)
		es 	= segment of PCComClass
		ax	= message #
		cx:dx	= buffer to fill with the current working directory
RETURN:		al	= PCComReturnType

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComPCPWD	method dynamic PCComClass, MSG_PCCOM_PCPWD
		call	PCComDoPWD
		push	ax
		call	ComDrainQueue
		pop	ax
		ret
PCComPCPWD	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDoPWD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieves the current full path.

CALLED BY:	Internal
PASS:		cx:dx	= buffer to fill
RETURN:		al 	= PCComReturnType
		ds	= dgroup

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	turn on remote Echoback
	turn on remote ackback
	do CD
	record reply
	turn off remote ackback
	turn off remote echoback	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDoPWD	proc near
	uses	cx, dx, bp, es, di, si, bx
	.enter
		LoadDGroup	ds, ax
		movdw		essi, cxdx

		call	SendEchoOn
		jc	abort
	
		stc				; tell SendAckOn that
						; echo is on..
		call	SendAckOn
		jc	abortEchoOff

	;
	; send the CD command
	;
		call	RobustCollectOn
		mov	ax, CHANGE_DIR_COMMAND
		call	PCComSendCommand

		mov	al, '.'
		call	ComWrite
		mov	al, ds:[delimiter]
		call	ComWrite

		call	RobustCollectOff
	;
	; expect back 
	; geos:	"\0a\0dDIRNAME;\1bACK"
	; dos: 	";\d\a:\d\aDIRNAME\1bACK"
	;
		mov	di, si

		mov	cx, PATH_BUFFER_SIZE -1
	;
	; we need to strip out any junk characters preceding the
	; dirname.  These include '\0ah', '\0dh', ';' and ':'
	;
readAgain:
		call	ComReadWithWait
		LONG_EC	jc	readFailed
		cmp	al, 0ah
		je	readAgain
		cmp	al, 0dh
		je	readAgain
		cmp	al, ';'
		je	readAgain
		cmp	al, ':'
		je	readAgain
	;
	; get the actual path data
	;
readPathLoop:
EC<		Assert_fptr	esdi				>
		stosb
		cmp	al, 1bh
		je	postRead
		call	ComReadWithWait
		LONG_EC jc	readFailed
		loop	readPathLoop
		call	WaitForChar
		jmp	postRead

abortEchoOff:
		call	ComDrainQueue
		call	SendEchoOff
abort:
		mov	al, PCCRT_COMMAND_ABORTED
		jmp	done
	;
	; This schme is because the dos pccom doesn't put a ';' at the
	; end of some of its replies (like the dirname).  We can't
	; look for '>' because if the dir doesn't exist the string we
	; get back doesn't have one..  the only sure char we can
	; expect is the ESC preceeding the NAK/ACK..  so we must
	; retroactivly nuke any ';' char we had recieved.
	;
postRead:
		clr	al
		sub	di, 3
		cmp	{byte}es:[di], '>'
		jne	checkSemiColon
		mov	es:[di], al		; Strip off the '>'
checkSemiColon:
		inc	di
		cmp	{byte}es:[di], ';'
		jne	dontClearThis
		mov	es:[di],al
dontClearThis:
		inc	di
EC<		Assert_fptr	esdi				>
		stosb
	;
	; now translate the dos trash into nice respectable Geos
	; Characters
	;
		segxchg	es, ds
		clr	cx
		call	PCComDosToGeos
		call	LocalUpcaseString
		segxchg	es, ds
	;
	; Ok, done with all..  get ACK and go home
	;
		stc
		call	WaitForAck
readFailed:
		pushf				; save CF
		stc
		call	SendAckOff
		call	SendEchoOff
		popf				; restore CF

		mov	al, PCCRT_NO_ERROR
		jnc	done
		mov	al, PCCRT_COMMAND_ABORTED
done:
	.leave
	ret

PCComDoPWD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDoMkdir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new directory on the remote computer

CALLED BY:	MSG_PCCOM_MKDIR
PASS:		*ds:si	= PCComClass object
		ds:di	= PCComClass instance data
		ds:bx	= PCComClass object (same as *ds:si)
		es 	= segment of PCComClass
		cx:dx	= buffer with new dirname
		ax	= message #

RETURN:		al	= PCComReturnType

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	turn ack on so we know if it worked or not
	calc size of dirname
	send command
	wait for ack
	turn ack off

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDoMkdir	method dynamic PCComClass, 
					MSG_PCCOM_PCMKDIR
	uses	cx, dx, bp
	.enter
		LoadDGroup	ds, ax

	;
	; determine the length of the given pathname
	;
		mov	es, cx
		mov	di, dx
		mov	cx, size pathname
		clr	ax
		repnz scasb
		mov	al, PCCRT_BAD_DEST_PATH
		jne	errorNoAckOff
		sub	cx, size pathname
		not	cx
		mov	si, dx			; si = beginning
	;
	; translate it to the remote code page
	;
		segxchg	ds,es,ax
		call	PCComGeosToDos
		segxchg	ds,es,ax
	;
	; find the beginning of the new dirname, and make it kosher
	;
		push	cx
		dec	di
		dec	di			; point to before null
		mov	al, '\\'
		std
		repne	scasb
		cld
		pop	cx
		jne	fixName
		inc	di			; we found a backslash.
						; move till after it
						; (in conjunction w/
						; next inc)
fixName:
		inc	di			; b/c repne overshot
						; left end of path
		call	Make83DosName

		clc
		call	SendAckOn
		mov	al, PCCRT_COMMAND_ABORTED
		jc	errorNoAckOff
	;
	; send MD command
	;
		call	RobustCollectOn
		mov	ax, MAKE_DIR_COMMAND
		call	PCComSendCommand
		segxchg	ds, es
		call	ComWriteBlock
		mov	al, es:[delimiter]
		call	ComWrite
		segmov	ds, es, ax
		call	RobustCollectOff
	;
	; wait for Ack
	;
		clc
		call	WaitForAck
		mov	al, PCCRT_NO_ERROR
		jnc	done
		mov	al, PCCRT_COMMAND_ABORTED
done:
		clc
		call	SendAckOff

errorNoAckOff:
	.leave
	ret
PCComDoMkdir	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDoRemark
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a text string to be displayed and logged.

CALLED BY:	MSG_PCCOM_REMARK
PASS:		*ds:si	= PCComClass object
		ds:di	= PCComClass instance data
		ds:bx	= PCComClass object (same as *ds:si)
		es 	= segment of PCComClass
		cx:dx	= buffer with remark
		ax	= message #

RETURN:		al	= PCComReturnType

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	4/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDoRemark	method dynamic PCComClass, 
					MSG_PCCOM_PCREMARK
	uses	cx, dx, bp
	.enter
		LoadDGroup	ds, ax

		clc
		call	SendAckOn
		mov	al, PCCRT_COMMAND_ABORTED
		jc	errorNoAckOff

	;
	; determine the length of the string
	;
		mov	es, cx
		mov	di, dx
		mov	cx, size pathname
		clr	al
		repnz scasb
EC <		ERROR_NE	INVALID_REMARK_STRING		>
NEC <		jne	adjustSize				>
		sub	cx, size pathname
		not	cx
NEC <gotSize:							>
		mov	si, dx

	;
	; send RE command
	;
		call	RobustCollectOn
		mov	ax, REMARK_COMMAND
		call	PCComSendCommand
		segxchg	ds, es
		call	PCComGeosToDos
		call	ComWriteBlock
		clr	ax
		call	ComWrite
		segmov	ds, es, ax
		call	RobustCollectOff
	;
	; wait for Ack
	;
		clc
		call	WaitForAck
		mov	al, PCCRT_NO_ERROR
		jnc	done
		mov	al, PCCRT_COMMAND_ABORTED
done:
		clc
		call	SendAckOff

errorNoAckOff:
	.leave
	ret

if not ERROR_CHECK
adjustSize:
	;
	; We only want to send n-1 since 'n' doesn't include the null.
	;
		mov	cx, size pathname - 1
		jmp	gotSize
endif

PCComDoRemark	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCOMGETFREESPACE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the space free on a given drive (or current drive)

CALLED BY:	GLOBAL
PASS:		on stack:
		fptr - dword buffer for the size in bytes of the free
			space on the designated remote drive.
		word - drive letter of remote drive to query.  High
			byte is ignored. May also just be null..  then
			we'll check the current remote drive.

RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_BUSY
			PCCRT_NOT_INITIATED
			PCCRT_COMMAND_ABORTED
			PCCRT_BAD_DEST_PATH
		ah - PCComAbortType

		dword buffer filled in
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	7/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
PCCOMGETFREESPACE	proc	far	driveSpace:fptr.dword, driveLetter:word
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter
		ForceRef driveLetter

		movdw	disi, ss:[driveSpace]
		pushdw	disi
		clr	di, si
		call	ActiveStartupChecks
		jc	doneNoEchoNoReset

		call	PCComDoGetFreeSpace

		call	ActiveShutdownDuties

doneNoEchoNoReset:
		popdw	esbx
		movdw	es:[bx], disi

EC<		Assert_PCComReturnType	al				>
	.leave
	ret
PCCOMGETFREESPACE	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCComDoGetFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the space free on a given drive (or current drive)

CALLED BY:	Mostly PCCOMGETFREESPACCE
PASS:		ds - dgroup
		on stack:
		word - drive letter of remote drive to query.  High
			byte is ignored. May also just be null..  then
			we'll check the current remote drive.
RETURN:		al - PCComReturnType
			PCCRT_NO_ERROR
			PCCRT_COMMAND_ABORTED
			PCCRT_BAD_DEST_PATH

		dssi - space free
DESTROYED:	bx, cx, dx, si, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	7/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCComDoGetFreeSpace	proc	near
	.enter	inherit	PCCOMGETFREESPACE
		call	SendEchoOn
		mov	al, PCCRT_COMMAND_ABORTED
		LONG_EC	jc	doneNoEcho

		call	RobustCollectOn

		mov	ax, FREESPACE_COMMAND
		call	PCComSendCommand
		mov	ax, ss:[driveLetter]
		tst	al
		jz	sendNothing
		call	ComWrite
		mov	al, ':'
		call	ComWrite
sendNothing:
		mov	al, ds:[delimiter]
		call	ComWrite
		call	RobustCollectOff
	;
	; Now, well either get back an error message ("Invalid
	; Drive;") or a stat line ("x> Free Space: ; zzzzz;"), so
	; we'll search for numbers and semicolons..  Fun
	; fun fun..  
	;  '0' in bl
	;  '9'+1 in bh
	;  ';' in ch
	;  cl is number found indicator
	;  hitting first numbs in number strings)
	;
		mov	bx, '0' or (('9'+1) shl 8)
		mov	cx, 1 or (';' shl 8)
		mov	bp, 10
nextChar:
		call	ComReadWithWait
		jc	error
		cmp	al, bh
		js	numberPossible
		cmp	al, ch
		jne	nextChar
	;
	; done!  We found that terminating ';'.  Default to ax=0 (no
	; error), check cl to see if we actually read a number (the
	; actual number may be zero) and go home.  Set to bad path if
	; we didn't read a number.
	;
		clr	ax
		tst	cl
		jz	done
		mov	al, PCCRT_BAD_DEST_PATH
		jmp	done

error:
		mov	al, PCCRT_COMMAND_ABORTED

done:
		push	ax
		call	SendEchoOff
		pop	ax
doneNoEcho:
	.leave
	ret

numberPossible:
		cmp	al, bl
		js	nextChar
	;
	; Ok, parse this number.  
	;	Current tally is in disi
	;	bp = 10
	;
		clr	cl

		mov	ah, cl		; cheap way to clear ah
		sub	al, bl		; reduce to value (sub al,'0')
		xchg	ax, si
		mul	bp
		add	si, ax
		mov	ax, di
		adc	dl, dh		; adding dl + 0 with carry, we
					; know dh is zero cuz 64k*10
					; could only move less than 10
					; into the high word..
		mov	di, dx
		mul	bp
		add	di, ax
		jc	overflow
		jmp	nextChar
overflow:
	;
	; hmm..  alot o space is free - put big number 
	;
		mov	di, 32767
		mov	si, -1
		jmp	nextChar

nextNumber:
		call	ComReadWithWait
		LONG_EC	jc	error
		cmp	al, bh
		jns	toNextChar
		cmp	al, bl
		jns	nextNumber
toNextChar:
		jmp	nextChar
PCComDoGetFreeSpace	endp
	SetDefaultConvention

Main	ends

