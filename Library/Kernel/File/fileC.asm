COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/File
FILE:		fileC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Jenny	9/91		Added ECCheckFileHandle

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: fileC.asm,v 1.1 97/04/05 01:11:50 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_File	segment resource

if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileCreateDir
		FileCreateDirWithNativeShortName

C DECLARATION:	extern word
			_far _pascal FileCreateDir(const char _far *name);
		extern word
			_far _pascal FileCreateDirWithNativeShortName(
			const char _far *name);
			Note: "name" *can* be pointing into the XIP movable
				code segment.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILECREATEDIR	proc	far
	C_GetOneDWordArg	cx, dx,   ax,bx	;cx = seg, dx = offset

	push	ds
	mov	ds, cx				;ds:dx = file name

	call	FileCreateDir

CPopDSStoreError	label	far
	pop	ds
NOFXIP<	FALL_THRU_ECN	CStoreError					>
FXIP<	call	CStoreError						>
FXIP<	ret								>
FILECREATEDIR	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif

if FULL_EXECUTE_IN_PLACE
CStoreError		proc	far
else
CStoreError		proc	ecnear
endif
	jc	storeAX
	clr	ax		; no error => make sure it's 0...
storeAX:
	mov	ss:[TPD_error], ax
	ret
CStoreError		endp

if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif

FILECREATEDIRWITHNATIVESHORTNAME	proc	far
	C_GetOneDWordArg	cx, dx,   ax,bx	;cx = seg, dx = offset

	push	ds
	mov	ds, cx				;ds:dx = file name

	call	FileCreateDirWithNativeShortName
	jmp	CPopDSStoreError

FILECREATEDIRWITHNATIVESHORTNAME	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileDeleteDir

C DECLARATION:	extern word
			_far _pascal FileDeleteDir(const char _far *name);
			Note: "name" *can* be pointing into the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEDELETEDIR	proc	far
	C_GetOneDWordArg	cx, dx,   ax,bx	;cx = seg, dx = offset

	push	ds
	mov	ds, cx				;ds:dx = file name


	call	FileDeleteDir
	jmp	CPopDSStoreError

FILEDELETEDIR	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileGetCurrentPath

C DECLARATION:	extern DiskHandle
			_far _pascal FileGetCurrentPath(char _far *buffer,
							word bufferSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEGETCURRENTPATH	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = seg, ax = off, cx = size

	push	si, ds
	mov	ds, bx
	mov_trash	si, ax
	call	FileGetCurrentPath
	pop	si, ds

	mov	ss:[TPD_error], 0

	mov_trash	ax, bx			;return disk handle
	ret

FILEGETCURRENTPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileGetCurrentPathIDs

C DECLARATION:	extern ChunkHandle
			_pascal FileGetCurrentPathIDs(MemHandle block);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

------------------------------------------------------------------------------@
FILEGETCURRENTPATHIDS	proc	far
	C_GetOneWordArg	bx,  ax, cx
	push	ds
	call	MemLock
	mov	ds, ax
	call	FileGetCurrentPathIDs
	call	MemUnlock
	pop	ds
	jnc	done
	mov	ss:[TPD_error], ax		; record error code
	clr	ax				; ... and return 0 handle on
						;  error
done:
	ret
FILEGETCURRENTPATHIDS endp

if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif
COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileSetCurrentPath

C DECLARATION:	extern DiskHandle
			_far _pascal FileSetCurrentPath(DiskHandle disk,
						const char _far *path);
			Note: "path" *can* be pointing to the XIP moving code
				resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILESETCURRENTPATH	proc	far
	C_GetThreeWordArgs	bx, cx, dx,  ax	;bx = han, cx = seg, dx = off

	push	ds
	mov	ds, cx				;ds:dx = path
	call	FileSetCurrentPath
	pop	ds
	jc	error

	clr	ax				; no error
done:
	mov	ss:[TPD_error], ax
	mov_tr	ax, bx				;return disk handle

	ret

error:
	clr	bx				; null disk handle on error
	jmp	done

FILESETCURRENTPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileSetCurrentPathRaw

C DECLARATION:	extern DiskHandle
			_far _pascal FileSetCurrentPathRaw(DiskHandle disk,
						const char _far *path);
			Note: "path" *can* be pointing to the XIP moving code
				resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	4/27/2000	Initial version

------------------------------------------------------------------------------@
FILESETCURRENTPATHRAW	proc	far
	C_GetThreeWordArgs	bx, cx, dx,  ax	;bx = han, cx = seg, dx = off

	push	ds
	mov	ds, cx				;ds:dx = path
	call	FileSetCurrentPathRaw
	pop	ds
	jc	error

	clr	ax				; no error
done:
	mov	ss:[TPD_error], ax
	mov_tr	ax, bx				;return disk handle

	ret

error:
	clr	bx				; null disk handle on error
	jmp	done

FILESETCURRENTPATHRAW	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileOpen

C DECLARATION:	extern FileHandle
			_far _pascal FileOpen(const char _far *name,
							FileAccessFlags flags);
			Note: "name" *can* be pointing into the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEOPEN	proc	far
	C_GetThreeWordArgs	cx, dx, ax,  bx	;cx = seg, dx = off, ax = flags

	push	ds
	mov	ds, cx
	call	FileOpen

	pop	ds
NOFXIP<	FALL_THRU_ECN	CStoreErrorOrAX					>
FXIP<	call	CStoreErrorOrAX						>
FXIP<	ret								>
FILEOPEN	endp


if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif



if FULL_EXECUTE_IN_PLACE
CStoreErrorOrAX	proc	far
else		
CStoreErrorOrAX	proc	ecnear
endif
	; if error (carry set): ax = 0, TPD_error = error code
	; if no error (carry clear): ax = file handle, TPD_error = 0

	mov	ss:[TPD_error], 0		;assume no error
	jnc	noError
	xchg	ax, ss:[TPD_error]		;ax = 0, TPD_error = err code
noError:
	ret
CStoreErrorOrAX	endp


;
; Called by FILEGETDATEANDTIME, FILEREAD, FILEWRITE, FILEENUM
; 
CStoreErrorOrCX proc	far
	; if error (carry set): ax = -1, TPD_error = error code
	; if no error (carry clear): ax = cx, TPD_error = 0
	mov	ss:[TPD_error], 0
	xchg	ax, cx
	jnc	noError
	cmp	cx, ERROR_SHORT_READ_WRITE
	jz	noError
	mov	ss:[TPD_error], cx	; store error code
	mov	ax, -1			; return -1
noError:
	ret
CStoreErrorOrCX	endp



if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileCreate

C DECLARATION:	extern FileHandle
			_far _pascal FileCreate(const char _far *name,
					FileCreateFlags flagsAndMode, 
					FileAttrs attributes);
			Note: "name" *can* be pointing to the XIP movable 
				code resource.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILECREATE	proc	far	fname:fptr, flagsMode:word, attr:word
							uses ds
	.enter
	lds	dx, fname
	mov	ax, flagsMode
	mov	cx, attr
	call	FileCreate

	call	CStoreErrorOrAX
	.leave
	ret

FILECREATE	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif



COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileClose

C DECLARATION:	extern word
			_far _pascal FileClose(FileHandle fh,
						Boolean noErrorFlag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILECLOSE	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = flag

	call	FileCloseFar
	GOTO_ECN	CStoreError

FILECLOSE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileCommit

C DECLARATION:	extern word
			_far _pascal FileCommit(FileHandle fh,
							Boolean noErrorFlag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILECOMMIT	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = flag

	call	FileCommit
	GOTO_ECN	CStoreError

FILECOMMIT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileCreateTempFile

C DECLARATION:	extern FileHandle
		    _pascal FileCreateTempFile(const char *dir, 
						FileCreateFlags flags,
					       	FileAttrs attributes)
			Note: "name" *cannot* be pointing to the XIP movable 
				code resource.
			
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
------------------------------------------------------------------------------@

FILECREATETEMPFILE	proc	far	dirName:fptr.char,
					flagsMode:word, 
					attr:word
					uses ds
	.enter

	lds	dx, dirName
	mov	ax, flagsMode
	mov	cx, attr

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, dsdx					>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif

	call	FileCreateTempFile
	call	CStoreErrorOrAX
	.leave
	ret

FILECREATETEMPFILE	endp


if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileDelete

C DECLARATION:	extern word
			_far _pascal FileDelete(const char _far *name);
			Note: "name" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEDELETE	proc	far
	C_GetOneDWordArg	cx, dx,   ax,bx	;cx = seg, dx = offset


	push	ds
	mov	ds, cx				;ds:dx = file name

	call	FileDelete
	jmp	CPopDSStoreError

FILEDELETE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileRename

C DECLARATION:	extern word
		    _far _pascal FileRename(const char _far *oldName,
						const char _far *newame);
			Note:The fptrs *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILERENAME	proc	far	oldName:fptr, newName:fptr
				uses di, ds, es
	.enter

	lds	dx, oldName
	les	di, newName

	call	FileRename
	call	CStoreError
	.leave
	ret

FILERENAME	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileRead

C DECLARATION:	extern word
		    _far _pascal FileRead(FileHandle fh, void _far *buf,
					word count, Boolean noErrorFlag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


		file read returns the number of bytes actually read if there
		are no errors, else it returns -1

		in our system if the EOF is reached we return an
		ERROR_SHORT_READ_WRITE but in C it just returns
		the number of bytes read, so this stub treats a short
		read as not being an error 
		(returns means put into ax by the stub)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jimmy	6/91		changed return values
------------------------------------------------------------------------------@
FILEREAD	proc	far	fh:hptr, buf:fptr, count:word, flag:word
				uses ds
	clc
CReadWriteCommon	label	far

	.enter		; won't biff carry b/c no local vars, just params

	lds	dx, buf
	mov	ax, flag
	mov	bx, fh
	mov	cx, count
	jc	write
	call	FileReadFar
	jmp	common
write:
	call	FileWriteFar
common:

	call	CStoreErrorOrCX

	.leave
	ret

FILEREAD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileWrite

C DECLARATION:	extern word
		    _far _pascal FileWrite(FileHandle fh, const void _far *buf,
					word count, Boolean noErrorFlag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEWRITE	proc	far
	stc
	jmp	CReadWriteCommon

FILEWRITE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FilePos

C DECLARATION:	extern dword
		    _far _pascal FilePos(FileHandle fh, dword posOrOffset,
							FilePosMode mode);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEPOS	proc	far	fh:hptr, posOrOffset:dword, mode:word
	.enter

	mov	bx, fh
	mov	ax, mode
	mov	cx, posOrOffset.high
	mov	dx, posOrOffset.low
	call	FilePosFar

	mov	ss:[TPD_error], 0

	.leave
	ret

FILEPOS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileTruncate

C DECLARATION:	extern word
			_far _pascal FileTruncate(FileHandle fh, dword offset,
						 Boolean noErrorFlag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILETRUNCATE	proc	far	fh:hptr,
				off:dword,
				noErr:word
	.enter
		
;	C_GetThreeWordArgs	bx, cx, dx,  ax	;bx = han, cx = hi, dx = low
	mov	ax, noErr
	mov	bx, fh
	mov	cx, off.high
	mov	dx, off.low
	call	FileTruncate
;	GOTO_ECN CStoreError
	call	CStoreError
	.leave
	ret
FILETRUNCATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileSize

C DECLARATION:	extern dword
			_far _pascal FileSize(FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILESIZE	proc	far
	C_GetOneWordArg	bx   cx,dx	;bx = han

	call	FileSize
	ret

FILESIZE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileGetDateAndTimeAndTime

C DECLARATION:	extern dword
		    _far _pascal FileGetDateAndTime(FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEGETDATEANDTIME	proc	far
	C_GetOneWordArg	bx,  cx, dx	;bx = han

	call	FileGetDateAndTime
	xchg	cx, dx		; date goes in low word, time in high word
	GOTO	CStoreErrorOrCX

FILEGETDATEANDTIME	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileSetDateAndTimeAndTime

C DECLARATION:	extern word
		    _far _pascal FileSetDateAndTime(FileHandle fh,
						FileDateAndTime dateAndTime);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILESETDATEANDTIME	proc	far
	C_GetThreeWordArgs	bx, cx, dx,  ax	;bx = han, dx = date, cx = time

	call	FileSetDateAndTime
	GOTO_ECN	CStoreErrorOrAX

FILESETDATEANDTIME	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileDuplicateHandle

C DECLARATION:	extern FileHandle
			_far _pascal FileDuplicateHandle(FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEDUPLICATEHANDLE	proc	far
	C_GetOneWordArg	bx,   cx,dx	;bx = han

	call	FileDuplicateHandle
	GOTO_ECN	CStoreErrorOrAX

FILEDUPLICATEHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileLockRecord

C DECLARATION:	extern word
		    _far _pascal FileLockRecord(FileHandle fh, dword filePos,
							dword regLength);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILELOCKRECORD	proc	far	fh:hptr, filePos:dword, regLength:dword
					uses si, di
	clc
CLockUnlockCommon	label	far

	.enter		; won't biff carry b/c no local vars, just params

	mov	bx, fh
	mov	cx, filePos.high
	mov	dx, filePos.low
	mov	si, regLength.high
	mov	di, regLength.low
	jc	unlock
	call	FileLockRecord
	jmp	common
unlock:
	call	FileUnlockRecord
common:

	call	CStoreError

	.leave
	ret

FILELOCKRECORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileUnlockRecord

C DECLARATION:	extern word
		    _far _pascal FileUnlockRecord(FileHandle fh, dword filePos,
							    dword regLength);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEUNLOCKRECORD	proc	far
	stc
	jmp	CLockUnlockCommon

FILEUNLOCKRECORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileGetDiskHandle

C DECLARATION:	extern DiskHandle
			_far _pascal FileGetDiskHandle(FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEGETDISKHANDLE	proc	far
	C_GetOneWordArg	bx,   cx,dx	;bx = han

	call	FileGetDiskHandle
	mov	ss:[TPD_error], 0
	mov_trash	ax, bx
	ret

FILEGETDISKHANDLE	endp



if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileGetAttributes

C DECLARATION:	extern FileAttrs
			_far _pascal FileGetAttributes(const char _far *path);
			Note: "path" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEGETATTRIBUTES	proc	far
	C_GetOneDWordArg	cx, dx,   ax,bx	;cx = seg, dx = offset

	push	ds
	mov	ds, cx				;ds:dx = file name
	call	FileGetAttributes
	call	CStoreErrorOrCX
	pop	ds
	ret

FILEGETATTRIBUTES	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileSetAttributes

C DECLARATION:	extern word
			_far _pascal FileSetAttributes(const char _far *path,
							FileAttrs attr);
			Note: "path" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILESETATTRIBUTES	proc	far
	C_GetThreeWordArgs	ax, dx, cx,  bx	;ax = seg, dx = off, cx = attr

	push	ds
	mov	ds, ax				;ds:dx = file name
	clr	ch				; FileAttrs only a byte
	call	FileSetAttributes
	jmp	CPopDSStoreError

FILESETATTRIBUTES	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileGetPathExtAttributes

C DECLARATION:	extern word
			FileGetPathExtAttributes(const char *path,
						FileExtendedAttribute attr,
						void *buffer, word bufSize);
			Note: "path" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
FILEGETPATHEXTATTRIBUTES	proc	far	path:fptr.char,
						attr:FileExtendedAttribute,
						buffer:fptr,
						bufSize:word
		uses	es, di, ds
	clc
getSetPathExtAttrs	label	near
	.enter		; won't biff carry b/c no local vars, just params
	lds	dx, ss:[path]
	mov	ax, ss:[attr]
	les	di, ss:[buffer]
	mov	cx, ss:[bufSize]
	jc	setEm
	call	FileGetPathExtAttributes
	jmp	common

setEm:
	call	FileSetPathExtAttributes

common:
	call	CStoreError
	.leave
	ret

FILEGETPATHEXTATTRIBUTES	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileSetPathExtAttributes

C DECLARATION:	extern word
			FileSetPathExtAttributes(const char *path,
						FileExtendedAttribute attr,
						const void *buffer,
						word bufSize);
			Note: "path" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
FILESETPATHEXTATTRIBUTES proc far
	stc
	jmp	getSetPathExtAttrs
FILESETPATHEXTATTRIBUTES endp




COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileGetHandleExtAttributes

C DECLARATION:	extern word
			FileGetHandleExtAttributes(FileHandle fh,
						FileExtendedAttribute attr,
						void *buffer, word bufSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
FILEGETHANDLEEXTATTRIBUTES	proc	far	fh:hptr,
						attr:FileExtendedAttribute,
						buffer:fptr,
						bufSize:word
		uses	es, di, ds
	clc
getSetHandleExtAttrs	label	near
	.enter		; won't biff carry b/c no local vars, just params
	mov	bx, ss:[fh]
	mov	ax, ss:[attr]
	les	di, ss:[buffer]
	mov	cx, ss:[bufSize]
	jc	setEm
	call	FileGetHandleExtAttributes
	jmp	common

setEm:
	call	FileSetHandleExtAttributes

common:
	call	CStoreError
	.leave
	ret

FILEGETHANDLEEXTATTRIBUTES	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileGetHandleAllExtAttributes

C DECLARATION:	extern MemHandle /*XXX*/
			FileGetHandleAllExtAttributes(FileHandle fh,
						     word *numExtAttrs);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
FILEGETHANDLEALLEXTATTRIBUTES	proc	far	fh:hptr,
						numExtAttrs:fptr.word
	uses	ds
	.enter	
	mov	bx, ss:[fh]
	call	FileGetHandleAllExtAttributes	;returns ^hax
	lds	bx, numExtAttrs
	mov	ds:[bx], cx
	call	CStoreErrorOrAX
	.leave
	ret

FILEGETHANDLEALLEXTATTRIBUTES	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileSetHandleExtAttributes

C DECLARATION:	extern word
			FileSetHandleExtAttributes(FileHandle fh,
						FileExtendedAttribute attr,
						const void *buffer,
						word bufSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
FILESETHANDLEEXTATTRIBUTES proc far
	stc
	jmp	getSetHandleExtAttrs
FILESETHANDLEEXTATTRIBUTES endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileSetStandardPath

C DECLARATION:	extern void
			_far _pascal FileSetStandardPath(StandardPath sp);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILESETSTANDARDPATH	proc	far
	C_GetOneWordArg	ax,   cx,dx	;ax = StandardPath

	call	FileSetStandardPath
	ret

FILESETSTANDARDPATH	endp


if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileCopy

C DECLARATION:	extern word
		    _far _pascal FileCopy(const char _far *source,
						const char _far *dest,
						DiskHandle sourceDisk,
						DiskHandle destDisk);
			Note:The fptrs" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	lester	9/25/95  	Modified to use call table so FILECOPYLOCAL 
				and FILEMOVELOCAL can use common code.

------------------------------------------------------------------------------@
FileCopyMoveRoutine		etype	word, 0, (size nptr)
	FCMR_COPY		enum	FileCopyMoveRoutine
	FCMR_COPY_LOCAL		enum	FileCopyMoveRoutine
	FCMR_MOVE		enum	FileCopyMoveRoutine
	FCMR_MOVE_LOCAL		enum	FileCopyMoveRoutine

fileCopyMoveRoutines	nptr.near	FileCopy,
					FileCopyLocal,
					FileMove,
					FileMoveLocal
; Make sure all the routines are in the same segment
.assert segment FileCopy eq segment FileCopyLocal
.assert segment FileCopyLocal eq segment FileMove
.assert segment FileMove eq segment FileMoveLocal

FILECOPY	proc	far	source:fptr, dest:fptr, sDisk:hptr, dDisk:hptr
						uses si, di, ds, es
	mov	bx, FCMR_COPY
fileCopyMoveCommon label near

	.enter

	;
	; load up the registers
	;
	lds	si, source
	les	di, dest
	mov	cx, sDisk
	mov	dx, dDisk

	;
	; call the proper Asm routine by using the virtual segment of 
	; FileCopy and the proper offset from the table
	;
	Assert	etype, bx, FileCopyMoveRoutine
	Assert	bitClear, bx, 1
	mov	ax, cs:fileCopyMoveRoutines[bx]	; ax <- offset of routine
	mov	bx, vseg FileCopy		; bx <- virtual segment
	call	ProcCallFixedOrMovable

	call	CStoreError

	.leave
	ret

FILECOPY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileMove

C DECLARATION:	extern word
		    FileMove(const char _far *source,
						const char _far *dest,
						DiskHandle sourceDisk,
						DiskHandle destDisk);
			Note: The fptrs *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
FILEMOVE	proc	far
		mov	bx, FCMR_MOVE
		jmp	fileCopyMoveCommon
FILEMOVE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileCopyLocal

C DECLARATION:	extern word
		     FileCopyLocal(const char _far *source,
				   const char _far *dest,
			           DiskHandle sourceDisk,
			           DiskHandle destDisk);
			Note:The fptrs" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/14/95		Initial Revision

------------------------------------------------------------------------------@
FILECOPYLOCAL	proc	far	
		mov	bx, FCMR_COPY_LOCAL
		jmp	fileCopyMoveCommon
FILECOPYLOCAL	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileMoveLocal

C DECLARATION:	extern word
		     FileMoveLocal(const char _far *source,
				   const char _far *dest,
			           DiskHandle sourceDisk,
			           DiskHandle destDisk);
			Note:The fptrs" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/14/95		Initial Revision

------------------------------------------------------------------------------@
FILEMOVELOCAL	proc	far
		mov	bx, FCMR_MOVE_LOCAL
		jmp	fileCopyMoveCommon
FILEMOVELOCAL	endp


if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileEnum

C DECLARATION:	extern word
		    FileEnum(FileEnumParams _far *params,
			     MemHandle *bufCreated,
			     word _far *numNoFit);
			Note: "params" *cannot* be pointing to the XIP movable 
				code resource.
				The callback in *params must be vfptr.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	ardeb	3/92		new filesystem

------------------------------------------------------------------------------@
CFileEnumParams	struct
    CFEP_common	FileEnumParams
    CFEP_callback fptr.far	; locked callback routine
    CFEP_callbackHandle word	; virtual segment from which it came
CFileEnumParams ends

FILEENUM	proc	far	params:fptr.FileEnumParams,
				bufCreated:fptr.hptr, numNoFit:fptr.word
	uses si, di, ds, es
	.enter

	mov	dx, ds			;save real DS

	; put parameters on the stack
	lds	si, params
	segmov	es, ss

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	mov	bx, ds						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif

	sub	sp, size CFileEnumParams
	mov	di, sp
	mov	cx, size FileEnumParams
	push	si, di
	rep	movsb			;copy params to stack

	CheckHack <offset CFEP_callback eq size FileEnumParams>
	clr	ax
	stosw
	stosw
	pop	si, di

	;
	; Install our callback if caller has a callback that's not one of
	; the standard ones.
	; 
	test	ss:[di].CFEP_common.FEP_searchFlags, mask FESF_CALLBACK
	jz	doIt
	tst	ss:[di].CFEP_common.FEP_callback.segment
	jz	doIt

	; install our callback

	mov	ss:[di].CFEP_common.FEP_callback.segment, SEGMENT_CS
	mov	ss:[di].CFEP_common.FEP_callback.offset,
			offset callback
	
	mov	bx, ds:[si].FEP_callback.segment
	mov	ss:[di].CFEP_callbackHandle, bx
	call	MemLockFixedOrMovable			; ax = locked segment
	mov	ss:[di].CFEP_callback.segment, ax	;set callback segment
	mov	ax, ds:[si].FEP_callback.offset		;set callback offset
	mov	ss:[di].CFEP_callback.offset, ax

	; use FEP_cbData1 to point to caller's FileEnumParams

	mov	ss:[di].CFEP_common.FEP_cbData1.high, ds
	mov	ss:[di].CFEP_common.FEP_cbData1.low, si

	; use FEP_cbData2.high to hold realDS

	mov	ss:[di].CFEP_common.FEP_cbData2.high, dx

	; call the routine
doIt:
	call	{far}FileEnum			;pops off args

	mov	ss:[TPD_error], 0
	xchg	ax, cx			; ax <- # files, cx <- error code
	jnc	haveRetval		; no error, so ax is right
	mov	ss:[TPD_error], cx	; store error for ThreadGetError
	mov	ax, -1			; and return -1 for # files
haveRetval:

;;; can't use anymore else function can't be published...right?
;;;	call	CStoreErrorOrCX		; ax <- -1 or file count


	lds	si, ss:[bufCreated]
	mov	ds:[si], bx

	;
	; Unlock the callback routine, if any and necessary...
	; 
	pop	bx		; CFEP_callback.offset (discard)
	pop	bx		; CFEP_callback.segment
	tst	bx
	pop	bx		; CFEP_callbackHandle
	jz	storeNoFit
	call	MemUnlockFixedOrMovable

storeNoFit:
	mov	si, numNoFit.segment
	tst	si
	jz	noStoreNumNoFit
	lds	si, numNoFit
	mov	ds:[si], dx
noStoreNumNoFit:

	.leave
	ret

	;--------------------
	; PASS:
	;	es	= FileEnumCallbackData
	;	ss:[bp+6] = CFileEnumParams
	;
	; RETURN:
	; 	carry clear to accept file (real callback returned non-zero)
	; 
	; DESTROYED:
	; 	none
	; 
	; KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	;
	;    word		(_pascal *FEP_callback)
	;				(struct _FileEnumParams *params,
	;				FileEnumCallbackData *fecd,
	;				word frame);
callback:
	push	ax, bx, cx, dx, si, ds, es
	
	pushdw	ss:[bp+6].CFEP_common.FEP_cbData1	; caller's params
	push	es
	clr	ax
	push	ax			; fecd
	push	bp			; frame
	
	mov	ds, ss:[bp+6].CFEP_common.FEP_cbData2.high
	call	ss:[bp+6].CFEP_callback
	; ax non-zero to accept

	tst	ax			;clears carry
	jnz	callbackDone		;non-zero means leave carry clear
	stc
callbackDone:
	pop	ax, bx, cx, dx, si, ds, es
	retf

FILEENUM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileEnumLocateAttr

C DECLARATION:	extern void *
		    FileEnumLocateAttr(FileEnumCallbackData *fecd,
		    			FileExtendedAttribute attr,
					const char *name);
			Note:The fptrs *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
FILEENUMLOCATEATTR	proc far	fecd:fptr.FileEnumCallbackData,
					attr:FileExtendedAttribute,
					customName:fptr.char
	uses	ds, si, es, di
	.enter
	lds	si, ss:[fecd]
	les	di, ss:[customName]

	mov	ax, ss:[attr]
	call	FileEnumLocateAttr
	jc	notFound
	tst	es:[di].FEAD_value.segment
	jz	notFound

	mov	ax, es:[di].FEAD_value.offset
	mov	dx, es
done:
	.leave
	ret
notFound:
	clr	dx, ax
	jmp	done
FILEENUMLOCATEATTR endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileEnumWildcard

C DECLARATION:	extern Boolean
		    FileEnumWildcard(FileEnumCallbackData *fecd,
		    			word frame);
			Note: "fecd" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/92		Initial version

------------------------------------------------------------------------------@
FILEENUMWILDCARD proc far
	C_GetThreeWordArgs ax, bx, cx, 	dx	; ax <- FECD seg, bx <- 0
						;  cx <- frame
	push	ds, bp
	mov	ds, ax
	mov	bp, cx
	call	FileEnumWildcard
	pop	ds, bp
	
	mov	ax, 0		; assume no match
	jnc	done
	dec	ax
done:
	ret
FILEENUMWILDCARD endp


if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif
COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileConstructFullPath

C DECLARATION:	extern DiskHandle  /*XXX*/
		    _far _pascal FileConstructFullPath(char **buffer,
				word bufSize, DiskHandle disk,
				const char _far *tail,
				Boolean addDriveLetter);
			Note: "tail" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILECONSTRUCTFULLPATH	proc	far	buffer:fptr.fptr.char, bufSize:word,
					disk:word, tail:fptr,
					addDriveLetter:word
						uses si, di, ds, es
	.enter

	mov	dx, addDriveLetter
	mov	bx, disk
	lds	si, tail
	les	di, buffer
	les	di, es:[di]
	mov	cx, bufSize

	call	FileConstructFullPath

	lds	si, buffer
	mov	ds:[si].offset, di

	mov_trash	ax, bx

	.leave
	ret

FILECONSTRUCTFULLPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileResolveStandardPath

C DECLARATION:	extern DiskHandle  /*XXX*/
		    FileResolveStandardPath(char **buffer,
		    		word bufSize,
		    		const char *tail,
				FileResolveStandardPathFlags flags,
				FileAttrs *attrsPtr);
			Note: "tail" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILERESOLVESTANDARDPATH	proc	far	buffer:fptr.fptr.char, bufSize:word,
					tail:fptr.char,
					flags:FRSPFlags,
					attrsPtr:fptr.FileAttrs
						uses si, di, ds, es
	.enter

	lds	dx, ss:[tail]		; ds:dx <- tail
	les	di, ss:[buffer]
	les	di, es:[di]		; es:di <- buffer
	mov	cx, ss:[bufSize]	; cx <- bufSize
	mov	ax, ss:[flags]		; ax <- flags
	call	FileResolveStandardPath

	jnc	returnResults
	clr	bx			; return 0 disk handle on error
returnResults:
	lds	si, ss:[attrsPtr]
	mov	ds:[si], al		; return FileAttrs, if any

	lds	si, ss:[buffer]
	mov	ds:[si].offset, di	; point *buffer to null byte

	mov_tr	ax, bx			; return disk handle
	.leave
	ret
FILERESOLVESTANDARDPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileParseStandardPath

C DECLARATION:	extern StandardPath
		    FileParseStandardPath(DiskHandle disk,
		    		const char **path);
			Note: "path" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILEPARSESTANDARDPATH	proc	far
	C_GetThreeWordArgs bx, cx, ax, dx	;cx = seg, ax = offset, bx=disk

	push	di, es
	mov	es, cx
	mov_trash	di, ax			;es:di = ptr to filename
	push	di, es
	les	di, es:[di]
	call	FileParseStandardPath
	pop	bx, es
	mov	es:[bx].offset, di
	pop	di, es

	ret

FILEPARSESTANDARDPATH	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckFileHandle

C DECLARATION:	extern void
		    _far _pascal ECCheckFileHandle(FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jenny	9/91		Initial version

------------------------------------------------------------------------------@
ECCHECKFILEHANDLE	proc	far
EC <	C_GetOneWordArg bx,   ax,cx	;bx = handle			>
EC <	call	ECCheckFileHandle					>
EC <	ret								>
NEC <	ret	2							>

ECCHECKFILEHANDLE	endp


if FULL_EXECUTE_IN_PLACE
C_File	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileCreateLink

C DECLARATION:	extern word
			FileCreateLink(const char *path,
					word targetDiskHandle,
					const char *targetPath
					word targetAttrsFlag);
			Note:The fptrs *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	not tested

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/27/92		Initial version 
------------------------------------------------------------------------------@
FILECREATELINK	proc	far	path:fptr,
				targetDiskHandle:word, 
				targetPath:fptr,
				targetAttrsFlag:word
	uses	si, di, ds, es
	.enter

	lds	dx, ss:[path]
	mov	bx, ss:[targetDiskHandle]
	les	di, ss:[targetPath]
	mov	cx, ss:[targetAttrsFlag]
	call	FileCreateLink
	call	CStoreError
	.leave
	ret

FILECREATELINK	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileReadLink

C DECLARATION:	extern DiskHandle
			FileReadLink(const char *path,
					const char *targetPath);
			Note: The fptrs *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	not tested

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/27/92		Initial version 
------------------------------------------------------------------------------@
FILEREADLINK	proc	far	path:fptr, targetPath:fptr

	uses	si, di, ds, es
	.enter

	lds	dx, ss:[path]
	les	di, ss:[targetPath]
	call	FileReadLink
	call	CStoreError
	mov_tr	ax, bx			; DiskHandle 
	.leave
	ret

FILEREADLINK	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileSetLinkExtraData

C DECLARATION:	extern DiskHandle
			FileSetLinkExtraData(const char *path,
					char *buffer,
					word bufSize);
			Note: "path" *can* be pointing to the XIP movable 
				code resource.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	not tested

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/27/92		Initial version 
------------------------------------------------------------------------------@
FILESETLINKEXTRADATA	proc	far	path:fptr.char, 
					buffer:fptr,
					bufSize:word

	uses	si, di, ds, es
	clc
setGetExtraData label near
	.enter		; won't biff carry b/c no local vars, just params

	lds	dx, ss:[path]
	les	di, ss:[buffer]
	mov	cx, ss:[bufSize]
	jc	getExtraData
	call	FileSetLinkExtraData
	jmp	common
getExtraData:
	call	FileGetLinkExtraData
common:
	call	CStoreError
	.leave
	ret

FILESETLINKEXTRADATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileGetLinkExtraData

C DECLARATION:	extern DiskHandle
			FileGetLinkExtraData(const char *path,
					char *buffer,
					word bufSize);
			Note: "path" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	not tested

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/27/92		Initial version 
------------------------------------------------------------------------------@
FILEGETLINKEXTRADATA	proc	far 
	stc
	jmp	setGetExtraData
FILEGETLINKEXTRADATA	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileConstructActualPath

C DECLARATION:	extern DiskHandle 
		    _far _pascal FileConstructActualPath(char **buffer,
				word bufSize, DiskHandle disk,
				const char _far *tail,
				Boolean addDriveLetter);
			Note: "tail" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
FILECONSTRUCTACTUALPATH	proc	far	buffer:fptr.fptr.char, 
					bufSize:word,
					disk:word, 
					tail:fptr,
					addDriveLetter:word
						uses si, di, ds, es
	.enter

	mov	dx, addDriveLetter
	mov	bx, disk
	lds	si, tail
	les	di, buffer
	les	di, es:[di]
	mov	cx, bufSize

	call	FileConstructActualPath

	lds	si, buffer
	mov	ds:[si].offset, di

	mov_tr	ax, bx

	.leave
	ret

FILECONSTRUCTACTUALPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileComparePaths

C DECLARATION:	extern PathCompareType
		    _far _pascal FileComparePaths(
				const char_far *path1,
				DiskHandle disk1,
				const char _far *path2,
				DiskHandle disk2);
			Note: The fptrs *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	10.92		Initial version

------------------------------------------------------------------------------@
FILECOMPAREPATHS	proc	far	path1:fptr.char,
					disk1:word,
					path2:fptr.char, 
					disk2:word

	uses si, di, ds, es

	.enter

	mov	cx, disk1
	mov	dx, disk2
	lds	si, path1
	les	di, path2

	call	FileComparePaths	; returns value in AL

	.leave
	ret

FILECOMPAREPATHS	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileCopyPathExtAttributes

C DECLARATION:	extern word  /*XXX*/
		    _far _pascal FileCopyPathExtAttributes(
				const char_far *sourcePath,
				DiskHandle sourceDisk,
				const char _far *destPath,
				DiskHandle destDisk);
			Note: The fptrs *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10.92		Initial version

------------------------------------------------------------------------------@
FILECOPYPATHEXTATTRIBUTES	proc	far	sourcePath:fptr.char,
					sourceDisk:word,
					destPath:fptr.char, 
					destDisk:word

	uses si, di, ds, es

	.enter

	mov	cx, sourceDisk
	mov	dx, destDisk
	lds	si, sourcePath
	les	di, destPath

	call	FileCopyPathExtAttributes
	call	CStoreError

	.leave
	ret

FILECOPYPATHEXTATTRIBUTES	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	FileOpenAndRead

C DECLARATION:	extern MemHandle /*XXX*/
		    _far _pascal FileOpenAndRead(
				FileOpenAndReadFlags flags,
				const char_far *filename,
				FileHandle *fh);
			Note: "filename" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/93		Initial version

------------------------------------------------------------------------------@
FILEOPENANDREAD		proc	far	flags:FileOpenAndReadFlags,
					filename:fptr.char,
					fh:fptr.hptr 

		uses si, di, ds, es
	
		.enter

		mov	ax, flags
		lds	dx, filename

		call	FileOpenAndRead
		lds	si, ss:[fh]
		mov	ds:[si], bx

	;
	; Is this legal?
	;
		
		push	ax
		call	CStoreError
		pop	ax
		
		.leave
		ret

FILEOPENANDREAD	endp


if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_File	segment	resource
endif


C_File	ends

	SetDefaultConvention
