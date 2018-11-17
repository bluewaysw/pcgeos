COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		AnsiC
FILE:		stdio_asm.asm

AUTHOR:		Maryann Simmons, May  7, 1992

ROUTINES:
	Name			Description
	----			-----------
GLOBAL:
    GLB fopen			Open a stream for the passed filename

    GLB fdopen			Open a stream for the passed file handle

    GLB fseek			Seek to a position in a stream

    GLB ftell			Return the current position in a stream

    GLB fwrite			Write data to a stream

    GLB fread		Read data from a stream

    GLB fgetc			Read a single byte from a stream

    GLB fflush			Flush a stream's internal buffer
					- or
				If NULL stream passed, flush all geode's streams

    GLB fclose			Close a stream and associate file

    GLB	fdclose			Close a stream and return associated file handle

    GLB rename			Rename a file

INTERNAL:
    INT	StreamAlloc		Allocate a stream handle

    INT StreamFree		Free a stream handle

    INT StreamRead		Read data from a stream, with buffering

    INT StreamWrite		Write data to a stream, with buffering

    INT StreamFill		Fill a stream buffer with data from a file

    INT StreamFlush		Flush a stream buffer to the file

    INT	StreamFlushAll		Flush all streams for a geode

    INT	StreamGetHead		Get the 1st item in a stream linked list

    INT	StreamSetHead		Set the 1st item in a stream linked list

    INT	StreamPLock		Lock & own a stream handle

    INT	StreamUnlockV		Unlock & release a stream handle


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 7/92		Initial revision
	Schoon	8/ 4/92		Added partial stream support.
	Don	8/ 6/92		Re-wrote stream support

DESCRIPTION:
	This file contains C stubs for C functions included in stdio.h

	** NOT YET FULLY ANSI C COMPATIBLE **		

EXTRA NOTES:

This area explains the logic behind the stream buffering of files.

	* A stream consists of a FILE structure and a buffer of size
	  BUF_SIZE, all stored in a single stream memory block. The
	  handle to this block (stored in the low word of an fptr) is
	  what the caller is returned in fopen() & fdopen(), and must
	  be used in all succeeding stream operations. One MUST NEVER
	  intermix PC/GEOS file & stream operations.

	* A linked list of files opened for each thread is maintained,
	  with the head of each list stored in the private data for the
	  thread in which the stream is created. One *must* free the
	  stream in this same thread, else death will result. All open
	  streams will be destroyed when the thread goes away.

	* The stream handle is used as a sempahore, with the helpful
	  routines of StreamPLock & StreamUnlockV uses to access the data

Other helpful pieces of information:
	* The stream buffer is filled/empty when the _next = _bend
	  and when _bend  = _buf.  All offsets include the administrative
	  data (FILE structure) at the beginning of the stream memory.

	* The buffer size is defined by the BUF_SIZE variable

	* Read/Writes in excess of 64K are not supported.

	* The following features are not yet implemented:
		- binary streams
		- append-only streams, 
		- user specified file protection, 
		- the file error bit.

	$Id: stdio_asm.asm,v 1.1 97/04/04 17:42:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include ansicGeode.def

	SetGeosConvention

;RESIDENT	segment	word	public	'CODE'

;MAINCODE	segment word	public	'CODE'
MAINCODE	segment public	'CODE'

;-----------------------------------------------------------------------
;	Constants and structures
;-----------------------------------------------------------------------

FileMode	record
    FM_DIRTY:1	;set if stream buffer modified but not flushed
    FM_EXCL:1	;set if file is exclusive
    FM_DWRITE:1	;NOT FUNCTIONING set if other writes are denied
    FM_DREAD:1	;NOT FUNCTIONING set if other reads are denied
    FM_WRITE:1	;set if write occured since file-pos. oper.
    FM_READ:1	;set if read occured since file-position operation
    FM_NBF:1	;NOT FUNCTIONING set if no buffering should occur
    FM_LBF:1	;NOT USED set if line buffering in effect
    FM_ERR:1	;NOT USED the error indicator
    FM_EOF:1	;the end-of-file indicator
    FM_BIN:1	;NOT FUNCTIONING set if stream is binary, not set if text
    FM_CREATE:1 ;set if new file can be created on open
    FM_TRUNC:1 	;NOT FUNCTIONING set if existing file was truncated on open
    FM_OPENA:1 	;NOT FUNCTIONING set if all writes append to end of file
    FM_OPENW:1	;set if file is open for writing
    FM_OPENR:1	;set if file is open for reading 
FileMode	end	

FILE		struct
    _mode 	FileMode 	; current mode flags
    _bend	word		; offset to 1st byte beyond end of data
    _next	word		; offset to next byte to be read from/written to
    _nextHandle	word		; next stream handle in linked list
    _fileHandle	word		; file handle for this stream
FILE		ends

BUF_START	equ	(size FILE)		; start of data buffer
BUF_SIZE 	equ	4096			; 0 < BUF_SIZE < 64k
BUF_END		equ	BUF_SIZE + BUF_START	; end of data buffer


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		fopen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The fopen function opens the file whose name is in the
		buffer pointed to by filename. 

CALLED BY:	GLOBAL

PASS:		filename= dword	buffer containing filename
		modeStr	= fptr to moe string (see ParseModeString)
		(For XIP system, filename and modeStr can be in the XIP movable
			code resource.)

RETURN:		DX:AX	= {FILE *} stream pointer, or NULL if error

DESTROYED:	BX, CX

PSEUDO CODE/STRATEGY:
		any binary mode indicators are ignored
		append mode is not supported

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 7/92		Initial version
	Don	8/10/92		Re-wrote
			
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global fopen:far
fopen	proc	far	filename:fptr, modeStr:fptr
	uses	di, si, ds
	.enter

	; Parse the modes, and then open the file
	;
	lds	si, modeStr		; mode string => DS:SI
	call	ParseModeString		; modes => AL, DX
	tst	al			; must be read or write
	jz	error	
	mov	di, dx			; FileMode => DI
	lds	dx, filename		; filename => DS:DX
	test	di, mask FM_CREATE	; if we can create the file, do it
	jz	fileOpen		; else call FileOpen

	mov	cx, FILE_ATTR_NORMAL
	call	FileCreate
	cmp	ax, ERROR_FILE_EXISTS
	je	fileOpen		;use existing, discard contents  
	jmp	checkCarry		;carry set if unsuccessful
fileOpen:
	call	FileOpen
checkCarry:
	jc	error			;FileOpen/Create not successful	

	; We now have a file handle, so now need to allocate a stream
	;
	mov	dx, di			; FileMode => DX
	call	fdopen_local		;stream handle => DX:AX
done:
	.leave
	ret

	; Some sort of error occurred, so return NULL
error:
	clr	ax, dx			;return dx:ax= 0 if error
	jmp	done
fopen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		fdopen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a PC/GEOS file handle into a stream handle

CALLED BY:	GLOBAL

PASS:		fileHan	= {FileHandle} open file handle
		modeStr	= mode sring (see ParseModeString)

RETURN:		DX:AX	= {*FILE} stream pointer

DESTROYED:	BX, CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	fdopen:far
fdopen	proc	far	fileHan:word, modeStr:fptr
	uses	si, ds
	.enter
	
	; Allocate the stream handle & update our bookkeeping
	;
	lds	si, modeStr		; mode string => DS:SI
	call	ParseModeString		; FileMode => DX
	mov	ax, fileHan		; file handle => AX
	call	fdopen_local

	.leave
	ret
fdopen	endp

fdopen_local	proc	near
	call	StreamAlloc		; stream handle (or NULL) => AX
	clr	dx			; high word of fptr is NULL
	ret
fdopen_local	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseModeString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the file mode string 

CALLED BY:	fopen(), fdopen()

PASS:		DS:SI	= Mode string:
			  Read/Write modes - [r, w, a], +, b - (no default)
			  ----------------
			  r:		open for reading
			  w:		open for writing (create/truncate)
			  a:		append mode (currently not supported)
			  b:		binary mode (currently not supported)
			  +:		allow both r/w

			  Deny modes - [E, N, R, W] - (E is default)
			  ----------
			  E		deny everyone (exclusive access)
			  N		deny none
			  R		deny read
			  W		deny write
			  
			  Other modes - V - (PC/GEOS file is default)
			  -----------
			  V		native file

RETURN:		Carry	= Clear (success)
		AL	= FileAccessFlags
		AH	= FileCreateFlags
		DX	= FileMode
			- or -
		Carry	= Set (error)
		AX, DX	= garbage

DESTROYED:	BX, CX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 7/92		Initial version
	Don	8/10/92		Added some additional mode flags

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

modeTable	char	'r','w','a','b','+','E','N','R','W','V'
modeTableLength	equ	10

modeHandlerTable 	nptr.near \
			readMode,
			writeMode,
			appendMode,
			binaryMode,
			readWriteMode,
			denyExclMode,
			denyNoneMode,
			denyReadMode,
			denyWriteMode,
			nativeMode

ParseModeString	proc	near
	uses	es, di
	.enter
	
	; First must determine what open mode to use
	;
	segmov	es, cs, di
	clr	bx			;initialize FileAccess/CreateFlags
	mov	dx, bx			;initialize FileMode flags

	; Loop through each argument
nextArg:
	lodsb				;al = first mode byte
	tst	al			;null terminated string
	jz	done
	mov	di, offset modeTable	;es:di is table to compare char with
	mov	cx, modeTableLength	;table length -> cx
	repne	scasb			;scan for a match
EC <	ERROR_NZ ERROR_ANSIC_ILLEGAL_MODE_CHARACTER			>
	sub	di,(offset modeTable)+1
	shl	di,1			;a word for each jmp label
	jmp	cs:[modeHandlerTable][di]

	; Ensure the FAF_EXCLUDE record is set, else set it to FE_NONE
done:
	mov_tr	ax, bx			; FileAccess/CreateFlags => AX
	test	al, mask FAF_EXCLUDE
	jnz	exit
	or	al, FILE_DENY_RW
	or	dx, mask FM_EXCL
exit:	
	.leave
	ret

readMode	label near
EC <	tst	bl			;can only have 1 r or w		>
EC <	ERROR_NZ ERROR_ANSIC_MAY_ONLY_HAVE_ONE_R_OR_W			>
	or	bl, FILE_ACCESS_R
	or	dx, mask FM_OPENR
	jmp	nextArg

writeMode	label near
EC <	tst	bl			;can only have 1 r or w		>
EC <	ERROR_NZ ERROR_ANSIC_MAY_ONLY_HAVE_ONE_R_OR_W			>
	or	bh, (FILE_CREATE_TRUNCATE shl offset FCF_MODE)
	or	bl, FILE_ACCESS_W	
	or	dx, mask FM_OPENW or mask FM_CREATE
	jmp	nextArg

appendMode	label near
EC <	ERROR	ERROR_ANSCI_APPEND_MODE_NOT_SUPPORTED			>
NEC <	stc								>
NEC <	jmp	exit							>

binaryMode	label	near
EC <	ERROR	ERROR_ANSCI_BINARY_MODE_NOT_SUPPORTED			>
NEC <	stc								>
NEC <	jmp	exit							>

readWriteMode	label near
EC <	tst	dl			; must have seen 'r' or 'w'	>
EC <	ERROR_Z	ERROR_ANSCI_R_OR_W_MUST_PRECEDE_PLUS_SYMBOL		>
	andnf	bl, not (mask FAF_MODE)
	or	bl, FILE_ACCESS_RW	
	or	dx, mask FM_OPENW or mask FM_OPENR or mask FM_CREATE
	jmp	nextArg

denyExclMode	label	near
EC <	test	bl, mask FAF_EXCLUDE	; ensure no bits are set	>
EC <	ERROR_NZ ERROR_ANSIC_MAY_ONLY_SET_ONE_DENY_MODE			>
	or	bl, FILE_DENY_RW
	or	dx, mask FM_EXCL
	jmp	nextArg

denyNoneMode	label	near
EC <	test	bl, mask FAF_EXCLUDE	; ensure no bits are set	>
EC <	ERROR_NZ ERROR_ANSIC_MAY_ONLY_SET_ONE_DENY_MODE			>
	or	bl, FILE_DENY_NONE
	jmp	nextArg

denyReadMode	label	near
EC <	test	bl, mask FAF_EXCLUDE	; ensure no bits are set	>
EC <	ERROR_NZ ERROR_ANSIC_MAY_ONLY_SET_ONE_DENY_MODE			>
	or	bl, FILE_DENY_R
	or	dx, mask FM_DREAD
	jmp	nextArg

denyWriteMode	label	near
EC <	test	bl, mask FAF_EXCLUDE	; ensure no bits are set	>
EC <	ERROR_NZ ERROR_ANSIC_MAY_ONLY_SET_ONE_DENY_MODE			>
	or	bl, FILE_DENY_W
	or	dx, mask FM_DWRITE
	jmp	nextArg

nativeMode	label	near
	or	bh, mask FCF_NATIVE
	jmp	nextArg
ParseModeString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		fclose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close specified stream and the associated file.

CALLED BY:	GLOBAL

PASS:		stream	= {*FILE} stream pointer

RETURN:		AX	= Zero (success)
			- or -
		AX	= EOF (error occurred)

DESTROYED:	BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 7/92		Initial version
	Don	8/10/92		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	fclose:far
fclose	proc	far	stream:fptr
	.enter

	CheckHack<EOF eq -1>

	; Flush and delete the stream
	;
	pushdw	stream			; push the stream fptr
	call	fdclose			; close & free the stream
	mov	cx, EOF			; assume the worst
	jc	close
	inc	cx			; else were successful

	; Now close the file
close:
	mov_tr	bx, ax			; file handle => BX
	clr	al			; return any errors
	call	FileClose		; carry = set if error
	jnc	done			; if no error, return status in CX
	mov	cx, EOF			; else there was some sort of error
done:
	mov_tr	ax, cx			; return status => AX

	.leave
	ret
fclose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		fdclose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the stream, returing the PC/GEOS file handle

CALLED BY:	GLOBAL

PASS:		stream	= {*FILE} stream fptr

RETURN:		AX	= file handle
		Carry	= Clear (success) or Set (error)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	fdclose:far
fdclose	proc	far	stream:fptr
	.enter
	
	; Flush and delete the stream
	;
EC <	cmp	stream.high, 0						>
EC <	ERROR_NZ ERROR_ANSIC_HIGH_WORD_OF_STREAM_PTR_IS_NON_NULL	>
	mov	bx, stream.low		; stream handle => BX
	call	StreamFree		; file handle => AX

	.leave
	ret
fdclose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSEEK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the file position of the stream

CALLED BY:	GLOBAL

PASS:		stream	= {*FILE} Stream handle
		bOffset	= {dword} offset from mode (in bytes)
		mode	= {word}  mode of seek (from beginning, end or curPos)

RETURN:		AX	= 0 (always successful)

DESTROYED:	BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	FSEEK:far
FSEEK	proc	far	stream:fptr, bOffset:dword, mode:word
	uses	di, ds
	.enter

	; Some set-up work
	;
EC <	cmp	stream.high, 0						>
EC <	ERROR_NZ ERROR_ANSIC_HIGH_WORD_OF_STREAM_PTR_IS_NON_NULL	>
	mov	bx, stream.low
	call	StreamPLock		; stream => DS:0
	call	StreamFlush		; flush any changes
	mov	ax, -1			; assume the worst
	jc	done			; error occurred, so abort

	; Now perform the FilePos. If we are performing a relative seek
	; and we're reading, the stream buffer may already contain data, so
	; we need to adjust the offset by the amount of data in the buffer.
	;
	mov	ax, mode		; FilePosMode => AL
	movdw	cxdx, bOffset		; offset => CX:DX
	cmp	ax, FILE_POS_RELATIVE
	jne	position		; if not relative, just do it
	test	ds:[_mode], mask FM_READ
	jz	position		; if not reading, just do it
	mov	di, ds:[_bend]		;
	sub	di, ds:[_next]		; bytes in buffer => DI
	clr	bx
	subdw	cxdx, bxdi		; true offset => CX:DX
position:
	mov	bx, ds:[_fileHandle]	; file handle => BX
	call	FilePos			; seek to the requested position
	mov	ax, BUF_START
	mov	ds:[_next], ax
	mov	ds:[_bend], ax
	andnf	ds:[_mode], not (mask FM_READ or mask FM_WRITE or mask FM_EOF)
	clr	ax			; success!
done:
	mov	bx, stream.low
	call	StreamUnlockV		; unlock the stream handle

	.leave
	ret
FSEEK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		feof
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the end of the file has been reached

CALLED BY:	GLOBAL

PASS:		strem = {*FILE} stream pointer

RETURN:		AX = non-zero if EOF has been reached

DESTROYED:	BX

PSEUDOCODE/STRATEGY:	if the FM_EOF bit is not set we are not at EOF
			else if _next < _bend we are not at EOF 
			else we are at EOF

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/27/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	feof:far
feof	proc	far	stream:fptr
	uses	ds
	.enter
	
	; Some set-up work
	;
EC <	cmp	stream.high, 0						>
EC <	ERROR_NZ ERROR_ANSIC_HIGH_WORD_OF_STREAM_PTR_IS_NON_NULL	>
	mov	bx, stream.low
	call	StreamPLock		; stream => DS:0

	; if the EOF bit has not been set, then we cannot have reached
	; the end of the file yet
	test	ds:[_mode], mask FM_EOF
	jz	notEOF

	; if the EOF flag is set, we still might not have actually read to
	; the end of the file, but we have buffered out to the end of the
	; file, so lets see if we have actually read to the end.
	; if the next byte we want to read is before the end of our data
	; we have not reached the end yet
	mov	ax, ds:[_next]
	cmp	ax, ds:[_bend]
	jb	notEOF
	mov	ax, 1	; ax = non-zero value to indicate we have hit the end
done:
	call	StreamUnlockV
	.leave
	ret
notEOF:
	clr	ax	; ax = 0 means we have not hit the end
	jmp	done
feof	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ftell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the file position of the stream

CALLED BY:	GLOBAL	

PASS:		stream	= {FILE *} stream

RETURN:		DX:AX	= Current file position
			
DESTROYED:	BX, CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	FTELL:far
FTELL	proc	far	stream:fptr
	uses	ds
	.enter
	
	; Some set-up work
	;
EC <	cmp	stream.high, 0						>
EC <	ERROR_NZ ERROR_ANSIC_HIGH_WORD_OF_STREAM_PTR_IS_NON_NULL	>
	mov	bx, stream.low
	call	StreamPLock		; stream => DS:0

	; Go get the current file position
	;
	mov	bx, ds:[_fileHandle]
	mov	al, FILE_POS_RELATIVE
	clr	cx, dx
	call	FilePos			; file position => DX:AX

	; Now adjust the position, depeding on whether or not we're been
	; reading or writing
	;
	test	ds:[_mode], mask FM_READ	
	jnz	reading			; for bytes that have been read
	test	ds:[_mode], mask FM_WRITE
	jnz	writing			; for bytes that haven't been written
done:
	mov	bx, stream.low
	call	StreamUnlockV

	.leave
	ret

	; Adjust for bytes that either have been written/read  to the buffer
reading:
	mov	bx, ds:[_bend]
	sub	bx, ds:[_next]		; bytes left in buffer => BX	
	subdw	dxax, cxbx		; true position => DX:AX
	jmp	done
writing:
	mov	bx, ds:[_next]
	sub	bx, BUF_START		; bytes left in buffer => BX
	adddw	dxax, cxbx		; true position => DX.AX
	jmp	done
FTELL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		fwrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write 'nItems' stored in 'buffer' to the passed stream.
		Each item is of size 'itSize' bytes.

CALLED BY:	GLOBAL

PASS:		buffer	= {fptr} Source buffer for data
		(For XIP system, buffer ptr can be pointing to the XIP movable
			code resource.)
		itSize	= {word} Size of each item (in bytes)
		nItems	= {word} Number of items to write
		stream	= (*FILE} stream to write to

RETURN:		AX	= Number of elements written (if successful)
			- or -
		AX	= 0 (write error occurred)

DESTROYED:	BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Since PC/GEOS only allows 64K segments, we optimize by
		knowing that the largest buffer one could ever use in 64K.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 7/92		Initial version
	Schoon	6/30/92		Added streams
	Don	8/10/92		Re-wrote
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	fwrite:far
fwrite	proc	far	buffer:fptr, itSize:word, nItems:word, stream:fptr
	uses	si, ds, es
	.enter
	
	; Lock down the stream, and verify that we can write
	;
EC <	cmp	stream.high, 0						>
EC <	ERROR_NZ ERROR_ANSIC_HIGH_WORD_OF_STREAM_PTR_IS_NON_NULL	>
	mov	bx, stream.low
	call	StreamPLock		; stream buffer => AX
	mov	es, ax			; we really want it in ES
	mov	ax, es:[_mode]		; FileMode => AX
	test	ax, mask FM_OPENW	; check for write permission
	jz	error
	test	ax, mask FM_READ 	; if read has occurred, can only...
	jz	doWrite			
	test 	ax, mask FM_EOF		; write if EOF was hit.
	jz	error

	; Go ahead and perform the write
doWrite:
	lds	si, buffer		; source buffer => DS:SI
	mov	ax, itSize		; item size => AX
	mov	cx, nItems		; number of items => CX
	mul	cx			; result => DX:AX
EC <	tst	dx			; this had better be zero	>
EC <	ERROR_NZ ERROR_ANSIC_CANT_WRITE_MORE_THAN_64K_BYTES_AT_ONCE	>
	mov_tr	cx, ax			; # of bytes to write => CX
	call	StreamWrite		; go write that data
	jc	error			; jump if error
	mov	ax, nItems		; # of items written => AX
done:
	call	StreamUnlockV

	.leave
	ret
	
	; Some sort of error occurred.
error:
	clr	ax			; return error indication
	jmp	done			; we're outta here
fwrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		fread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function reads, into the buffer pointed to by
		'buf' up to 'nmemb' elements of size 'size' bytes, from the
		stream specified by 'stream'

CALLED BY:	GLOBAL

PASS:		buf:fptr	buffer to read into
		size:word	size of elements to read
		nmemb:word	num elements to read
		stream:fptr	open file to read from

RETURN:		ax:number of elements successfully read		
			if size or nmemb are zero- returns zero
			buffer and file unchanged

DESTROYED:	BX,CX,DX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 7/92		Initial version
	Don	8/10/92		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	fread:far
fread	proc	far	buffer:fptr, itSize:word, nItems:word, stream:fptr
	uses	ds,es,di
	.enter

	; Lock down the stream, and verify that we can read
	;
EC <	cmp	stream.high, 0						>
EC <	ERROR_NZ ERROR_ANSIC_HIGH_WORD_OF_STREAM_PTR_IS_NON_NULL	>
	mov	bx, stream.low
	call	StreamPLock		; stream => DS:0
	clr	cx			; assume no bytes will be read
	mov	ax, ds:[_mode]		
	test	ax, mask FM_OPENR 	; ensure file is open for reading
	jz	done			
	test	ax, mask FM_WRITE	; ensure a file write operation has not
	jnz	done			; occurred since last file position
	ornf	ds:[_mode], mask FM_READ

	; Go ahead and perform the read
	;
	les	di, buffer		; destination buffer => ES:DI
	mov	ax, itSize		; item size => AX
	mov	cx, nItems		; number of items => CX
	mul	cx			; result => DX:AX
EC <	tst	dx			; this had better be zero	>
EC <	ERROR_NZ ERROR_ANSIC_CANT_READ_MORE_THAN_64K_BYTES_AT_ONCE	>
	mov_tr	cx, ax			; # of bytes to write => CX
	call	StreamRead		; read the data!
	; Compute the number of elements that were read
done:
	call	StreamUnlockV
	mov	ax, itSize		; item size => AX
	xchg	ax, cx			; bytes read => AX, item size => CX
	clr	dx
	div	cx			; # of items read => AX

	.leave
	ret
fread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		fgets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get a string from stream

CALLED BY:	GLOBAL

PASS:		char *buffer - buffer to store data in
		int buflength - length of buffer in bytes
		FILE *stream - stream pointer from which to read

RETURN:		DX:AX = buffer passed in

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	read bytes in from the stream until we hit a
			newline, an EOF of we fill up the buffer
			then NULL terminate the string

KNOWN BUGS/SIDEFFECTS/IDEAS:
			let fgetc do the error checking on the stream
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/27/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	FGETS:far
FGETS	proc	far	buffer:fptr, buflength:word, stream:fptr
	uses	es, di, cx
	.enter

	mov	cx, buflength	
EC <	tst	cx							>
EC <	ERROR_Z	ERROR_BUFFER_SIZE_ZERO					>
	jcxz	retnNull	; Buffer size is 0.
	dec	cx		; save one space for the NULL
	les	di, buffer
	jcxz	addNull		; There's only room for a NULL.
getLoop:
	pushdw	stream		; put stream on stack for fgetc
	call	fgetc		; ax = next characeter
	stosb			; write out byte to buffer
	cmp	al, '\n'	; routine ends when we hit a new line or
	je	addNull		; EOF (end-of-file)
	cmp	al, EOF
	je	addNull
	loop	getLoop
addNull:
	clr	al
	stosb			; NULL terminate the string
	movdw	dxax, buffer	; put buffer into dxax as return value
done:
	.leave
	ret

retnNull:
	clrdw	dxax
	jmp	done
FGETS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		fgetc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads a single byte from a stream.

CALLED BY:	GLOBAL

PASS:		stream:FILE *	stream to read from

RETURN:		ax - single byte returned as an int
		   - EOF in case of error
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	7/16/92		Initial version
	Don	8/10/92		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	fgetc:far
fgetc	proc	far	stream:fptr
	uses	ds, si
	.enter
	
	; Lock down the stream, and see if we can read
	;
EC <	cmp	stream.high, 0						>
EC <	ERROR_NZ ERROR_ANSIC_HIGH_WORD_OF_STREAM_PTR_IS_NON_NULL	>
	mov	bx, stream.low		; stream handle => BX
	call	StreamPLock		; stream => DS
	test	ds:[_mode], mask FM_OPENR 
	jz	error			; if file not open for reading, done

	ornf	ds:[_mode], mask FM_READ ; set flag so ftell knows where we are
	; Get a byte from the stream buffer
	;
	mov	si, ds:[_next]		; next byte => DS:SI
	cmp	si, ds:[_bend]		; compare with end of buffer data
	je	fillStream		; if equal, we need to read more
getChar:
	lodsb				; get the next byte
	clr	ah
	mov	ds:[_next], si		; increment the _next pointer
done:
	call	StreamUnlockV		; unlock & release the stream

	.leave
	ret	

	; We need to fill our stream buffer
fillStream:
	call	StreamFill		; fill that stream buffer up
	jc	error
	mov	si, ds:[_next]		; update si to reflect new next
	; if the new next is the same as bent, we were unable to
	; read anything, so return an EOF
	cmp	si, ds:[_bend]
	jne	getChar
error:
	mov	ax, EOF			; assume the worst
	jmp	done
fgetc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		fflush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flushes the stream's buffer to the associated file.  If 
		NULL is passed, it flushes all buffers associated with
		current Geode.

CALLED BY:	GLOBAL

PASS:		stream	= *FILE

RETURN:		AX	= 0 (successful flush)
			- or -
		AX	= EOF (error during flush)

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	fflush:far	
fflush	proc	far	stream:fptr
	uses	ds
	.enter

	; Lock down the stream buffer
	;
EC <	cmp	stream.high, 0						>
EC <	ERROR_NZ ERROR_ANSIC_HIGH_WORD_OF_STREAM_PTR_IS_NON_NULL	>
	mov 	bx, stream.low
	tst	bx			; check for NULL handle
	jz	flushAll		; if NULL, flush all streams for geode
	call	StreamPLock
	mov	ds, ax
	call	StreamFlush		; flush the buffer
	call	StreamUnlockV		; unlock & release the stream
done:
	mov	ax, EOF			; assume the worst
	jc	exit			; if error, return EOF
	clr	ax			; we were successful!
exit:
	.leave
	ret

	; The geode is going away, so flush all of its streams
flushAll:
	call	StreamFlushAll		; write out all of the streams
	jmp 	done
fflush	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		rename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function causes the file whose name is the string
		pointed to by oldName 	to be referred to by newName.
		The file is no longer accessible by oldName

CALLED BY:	GLOBAL
PASS:		oldName:fptr	:existing name
		newName:fptr	:name to change to
RETURN:		ax: zero if successful, nonzero if fails
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	rename:far
rename	proc	far	oldName:fptr,newName:fptr
	uses	di, ds, es
	.enter

	lds	dx,oldName	;current filename: ds:dx
	les	di,newName	;new filename: es:di
	call	FileRename
	jc	done		;if error ax will be nonzero
	clr	ax		;ax = zero indicates successful
done:
	.leave
	ret

rename	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Stream code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates memory block to contain stream administrative
 		data and buffer.

CALLED BY:	fdopen()

PASS:		AX	= File handle
		DX	= FileMode
		
RETURN: 	AX	= Stream handle
			- or -
		AX	= NULL

DESTROYED:	BX, CX, DX, DS

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	7/27/92		Initial version
	Don	8/06/92		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamAlloc	proc	near
	.enter

	; Allocate the FILE block
	;
	push	ax			; save the file handle
	mov	ax, BUF_END		; # of bytes to allocate => AX
	mov	cx, ((mask HF_SWAPABLE) or \
		    ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8))
	call	MemAlloc
	pop	cx			; file handle => CX
	jc	error			; if error, return carry set

	; Initialize the FILE structure
	;
	mov	ds, ax			; FILE => DS:0
	mov	ds:[_next], size FILE	; Initialize stream with 0 length buffer
	mov	ds:[_bend], size FILE
	mov	ds:[_fileHandle], cx	; Save file handle
	mov	ds:[_mode], dx		; Save mode bits

	; Add the stream to the stream linked-list
	;
	mov_tr	ax, bx			; new stream handle => AX
	call	StreamGetHead		; get head of list => BX
	xchg	ax, bx			; old head => AX, new head => BX
	call	StreamSetHead		; reset the head of the list
	mov	ds:[_nextHandle], ax	; store the next handle
	call	MemUnlock		; unlock the stream handle
	mov_tr	ax, bx			; stream handle => AX
done:
	.leave
	ret

	; Handle any possible errors
error:
	clr	ax			; return a NULL handle
	jmp	done			; we're outta here
StreamAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a stream structurefrom the linked list

CALLED BY:	fdclose()

PASS:		BX	= Stream handle

RETURN:		AX	= File handle

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	7/29/92		Initial version
	Don	8/ 6/92		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamFree	proc	near
	uses	cx, dx, ds
	.enter
	
	; Get this stream's next handle
	;
	call	StreamPLock		; stream => DS:0
	call	StreamFlush		; flush the stream
	pushf				; save the carry result
	mov	dx, ds:[_nextHandle]	; next stream handle (or NULL) => DX
	push	ds:[_fileHandle]	; save the file handle away
	call	StreamUnlockV

	; Get the 1st stream handle, and check for easy case
	;
	mov	cx, bx			; current stream handle => CX
	call	StreamGetHead		; head stream handle => BX
	cmp	bx, cx
	jne	checkNext
	mov	bx, dx			; new 1st stream handle => BX
	call	StreamSetHead
	jmp	done			; we're outta here

	; Loop through the stream list, looking for the passed stream handle
checkNext:
	call	StreamPLock		; stream => DS:0
	mov	ax, ds:[_nextHandle]	; next stream => AX
EC <	tst	ax			; NULL next ??			>
EC <	ERROR_Z	ERROR_ANSIC_STREAM_HANDLE_NOT_IN_LIST			>
	cmp	ax, cx			; is the next the one to be deleted ??
	je	unlink
	call	StreamUnlockV
	mov_tr	bx, ax			; next handle => BX
	jmp	checkNext

	; Unlink the deleted stream from the list
unlink:
	mov	ds:[_nextHandle], dx	; link in the deleted's next handle
	call	StreamUnlockV		; unlock the current stream

	; Flush the stream buffer, and delete the stream
done:
	mov	bx, cx			; stream handle => BX
	call	MemFree			; free the stream handle
	pop	ax			; file handle => AX
	popf				; flush result => carry

	.leave
	ret
StreamFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write data to a stream.

CALLED BY:	fwrite()

PASS:		DS:SI	= Data buffer to write from
		ES	= Stream buffer to write to
		CX	= Number of bytes to write
		BX	= Stream handle

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (error in writing)

DESTROYED:	AX, CX, DX, SI, DS

PSEUDO CODE/STRATEGY:
		* Try to write just to the stream buffer
		* If too much data, flush the buffer & write directly
		  to the disk.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	7/29/92		Initial version
	Don	8/ 6/92		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamWrite	proc	near
	uses	di
	.enter

	; See if the data will fit in the stream buffer
	;
	mov	ax, BUF_END
	sub	ax, es:[_next]		; bytes left in buffer => AX
	cmp	cx, ax			; compare against bytes to write
	jae	flushAndWrite

	; The data will fit, so copy it into the stream buffer
doWrite:
	ornf	es:[_mode], mask FM_DIRTY or mask FM_WRITE
	mov	di, es:[_next]		; destination => ES:DI
	shr	cx, 1			; # of words => CX
	jnc	evenWrite		; if even, jump
	movsb	
	clc				; clear carry so will not be 
					; detected as an error
evenWrite:
	rep	movsw			; else write all of the words
	mov	es:[_next], di		; update next offset &
	mov	es:[_bend], di		; end of data offset
done:
	.leave
	ret

	; We're writing out more data than the buffer can hold. Flush the
	; buffer, and then determine if we should write to the buffer to
	; to the file directly.
flushAndWrite:
	push	ds
	segmov	ds, es			; stream => DS:0
	call	StreamFlush		; flush the stream buffer to the file
	pop	ds
	jc	done			; if error, return now
	cmp	cx, (BUF_SIZE / 2)	; is data less than the 1/2 the buffer??
	jb	doWrite			; if so, then write it into the buffer

	push	bx			; else save the stream handle
	clr	al			; return errors
	mov	bx, es:[_fileHandle]	; file handle => BX
	mov	dx, si			; data to write => DS:DX
	call	FileWrite		; write out the data
	pop	bx			; restore the file handle
	jmp	done			; we're outta here
StreamWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read data from a stream

CALLED BY:	fread()

PASS:		DS	= Stream buffer to read from
		ES:DI	= Destination buffer
		CX	= # of bytes to be read

RETURN: 	CX	= # of bytes actually read

DESTROYED:	AX, DX, DI,ES, DS

PSEUDO CODE/STRATEGY:
		* Try to read from the stream buffer
		* If too much data is requested, read in all of the
		  buffer & get the rest from the disk.
		* Else, re-fill the buffer and read from there

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	7/31/92		Initial version
	Don	8/10/92		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamRead	proc	near
	uses	si
	.enter

	; Perform some byte calculations
	;
	mov	ax, ds:[_bend]
	mov	si, ds:[_next]		; next data => DS:SI
	sub	ax, si			; bytes available => AX
	clr	dx			; assume no additional reading
	cmp	cx, ax			; bytes desired vs. available
	jbe	doneSetup
	mov	dx, cx			; num bytes desired => DX
	sub	dx, ax			; remaining bytes to read => DX
	mov_tr	cx, ax			; bytes to read => CX
doneSetup:
	clr	ax			; no btes have been read

	; Copy the data from the stream buffer to the destination
	; 	AX = bytes that have been read
	;	CX = bytes to read this time (copy)
	;	DX = bytes we'll need to read after the copy is done
doRead:
	mov	si, ds:[_next]		; start of data => DS:SI
	push	cx
	jcxz	doneRead		; if no data in buffer, skip read
	shr	cx, 1			; # of words => CX
	jnc	evenRead		; if even, jump
	movsb
evenRead:
	rep	movsw
	mov	ds:[_next], si		; update _next offset

	; We've done the read. See if we need to do any more
doneRead:
	mov	cx, dx			; # of bytes to read => CX
	pop	dx
	add	dx, ax			; # of bytes read => DX
	jcxz	done			; we're done reading

	; Now see if we should read directly from the file, or read into
	; the buffer and then copy from it into the destination.
	;	CX = bytes we still need to read
	;	DX = bytes that have been read
	;
	cmp	cx, (BUF_SIZE / 2)	; need more than 1/2 the buffer size ??
	jae	readFile		; then read from the file
	test	ds:[_mode], mask FM_EOF
	jnz	atEOF
	call	StreamFill		; else fill the stream buffer
	jc	error			; if error, abort
	
	mov	ax, ds:[_bend]
	sub	ax, ds:[_next]
	cmp	cx, ax			; see if short read
	jbe	cont
	mov	cx,ax			; short read, adjust number of bytes
cont:					; actually read
	clr	ax			
	xchg	ax, dx			; bytes read => AX; bytes to read => DX
	jmp	doRead

	; Else we need to read directly from the file
readFile:
	push	dx			; # of bytes read
	push	bx			; save the stream handle
	mov	bx, ds:[_fileHandle]	; file handle => BX
	segxchg	es, ds, ax
	mov	dx, di			; read buffer => DS:DX
	clr	al			; return errors
	call	FileRead		; read in the data
	pop	bx			; restore the file handle
	pop	dx			; # of bytes read
	jnc	done			; success, so bytes read => CX
	ornf	es:[_mode], mask FM_EOF	; assume we hit EOF
	cmp	al, ERROR_SHORT_READ_WRITE
	je	done			; if short read, return OK
	andnf	es:[_mode], not (mask FM_EOF)
atEOF:
	clr	cx			; else no bytes were read
done:
	add	cx, dx			; # of bytes read => CX
exit:
	.leave
	ret
error:
	clr	cx
	jmp	exit
StreamRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamFill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill the stream buffer, after flushing it if necessary

CALLED BY:	INTERNAL

PASS:		DS	= Stream segment

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (error)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Schoon	7/21/92		initial version
	Don	8/10/92		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamFill	proc	near
	uses	ax, bx, cx, dx
	.enter	

	; A little set-up work
	;
	test	ds:[_mode], mask FM_EOF	; if we've already hit the EOF
	jnz 	error			; then don't bother trying again
	call	StreamFlush		; flush any changes, in case we're R/W
	jc	done			; if error, we're done

	; Now read in the data from the file
	;
	clr	al			; return errors
	mov	bx, ds:[_fileHandle]	; file handle => BX
	mov	cx, BUF_SIZE		; bytes to read in => CX
	mov	dx, BUF_START		; destination buffer => DS:DX
	call	FileRead		; bytes read => CX
	jnc 	updateStream		; if no errors, update stream data

	; Either the file access was denied, or we hit the end of the file
	;
	cmp	al, ERROR_ACCESS_DENIED	
	jz	error			; if access denied, return error
	ornf	ds:[_mode], mask FM_EOF	; else set the EOF flag
updateStream:
	mov	ax, BUF_START
	mov	ds:[_next], ax		; update the _next offset
	add	ax, cx			; end of bytes => CX
	mov	ds:[_bend], ax		; ...so update the offset
done:	
	.leave
	ret
error:	
	stc
	jmp 	done
StreamFill	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamFlushAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flushes all streams associated with the current geode.
		Systematically moves through the linked list of streams, 
		flushing each when required.

CALLED BY:	fflush()

PASS:		Nothing

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (one or more flush errors)

DESTROYED:	AX, BX, CX, DX, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	7/28/92		Initial version
	Don	8/10/92		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamFlushAll	proc	near
	.enter

	; Loop through all of the stream buffers
	;
	clr	cx			; assume no errors
	call	StreamGetHead		; stream buffer => BX
nextLoop:
	call	StreamPLock		; stream buffer => DS:0
	call	StreamFlush		; flush the buffer
	jnc	getNext
	inc	cx			; increment error count
getNext:
	mov	ax, ds:[_nextHandle]
	call	StreamUnlockV
	mov_tr	bx, ax			; next handle => BX
	tst	bx			; if it's non-zero...
	jnz	nextLoop		; then keep on looping

	; We're done, except for returning the carry status. The
	; carry is currently clear, becuase of the 'tst' above
	;
	jcxz	done			; if no errors jump
	stc				; else set the carry
done:	
	.leave
	ret
StreamFlushAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flushes the current stream's buffer to the associated file,
		when required.

CALLED BY:	INTERNAL

PASS:		DS	= Stream segment

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (error)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamFlush	proc	near
	uses	ax, cx, dx
	.enter

	; See if there is any reason to do any work
	;
	mov	ax, ds:[_mode]
	test	ax, mask FM_DIRTY	; is the buffer dirty ??
	jz	done			; nope, so get out of here
	mov	dx, BUF_START		; dx <- start of buffer
	test	ax, mask FM_OPENW	; do we have write permission ??
	jz 	clear			; nope, so just initialize buffer

	; Else we need to write some data out
	;
	push	bx
	clr	al			; return errors
	mov	bx, ds:[_fileHandle]	; file handle => BX
	mov	cx, ds:[_bend]
	sub	cx, dx			; # of bytes to write => CX
	call	FileWrite
	pop	bx
	jc	done
clear:
	mov	ds:[_next], dx		; buffer start => _next
	mov	ds:[_bend], dx		; buffer end => _bend
	andnf	ds:[_mode], not (mask FM_DIRTY or mask FM_WRITE)
done:
	.leave
	ret
StreamFlush	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Stream utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamPLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock & own a stream handle

CALLED BY:	INTERNAL

PASS:		BX	= Stream handle

RETURN:		DS	= Stream segment
		AX	= Stream segment

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamPLock	proc	near
	.enter
	
	call	MemPLock
	mov	ds, ax

	.leave
	ret
StreamPLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamUnlockV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock & release a stream handle

CALLED BY:	INTERNAL

PASS:		BX	= Stream handle

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamUnlockV	equ	MemUnlockV


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamGetHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the head of the stream list

CALLED BY:	INTERNAL

PASS:		Nothing

RETURN:		BX	= Stream handle

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamGetHead	proc	near
	uses	ax, cx, di, si, ds
	.enter
NOFXIP< segmov	ds, dgroup, ax					>
FXIP <	mov	bx , handle dgroup				>
FXIP <	call	MemDerefDS		; ds = dgroup		>
	mov	di, ds:[streamOffset]	; read location => DI
	clr	bx			; use the current geode
	mov	cx, 1			; read one word
	segmov	ds, ss
	push	ax
	mov	si, sp			; 1 word buffer => DS:SI
	call	GeodePrivRead		; fill the buffer
	pop	bx			; stream handle (or NULL) => BX

	.leave
	ret
StreamGetHead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamSetHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write (change) the head of the stream list

CALLED BY:	INTERNAL

PASS:		BX	= Stream handle (or NULL)

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (error in writing)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamSetHead	proc	near
	uses	ax, cx, di, si, ds
	.enter
	push	bx
NOFXIP<	segmov	ds, dgroup, cx						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS		; ds = dgroup			>
	mov	di, ds:[streamOffset]	; read location => DI
	clr	bx			; use the current geode
	mov	cx, 1			; read one word
	segmov	ds, ss
	mov	si, sp			; 1 word buffer => DS:SI
	call	GeodePrivWrite		; fill the buffer
	pop	bx			; clean up the stack

	.leave
	ret
StreamSetHead	endp

SetDefaultConvention

; RESIDENT	ends
MAINCODE	ends
