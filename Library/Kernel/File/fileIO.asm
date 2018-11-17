COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fileIO.asm

AUTHOR:		Adam de Boor, Apr  9, 1990

ROUTINES:
	Name			Description
	----			-----------
  ALIAS	FileReadFar		Read from an open file.

    GLB	FileRead		Read from an open file.

    INT	FileReadNoCheck		Read from an open file.

  ALIAS	FileWriteFar		Write to an open file

    GLB	FileWrite		Write to an open file

    INT	FileWriteNoCheck	Write to an open file

    INT	FileCheckShortReadWrite Common code for read & write to handle
				catching of short reads/writes.

  ALIAS	FilePosFar		Set a file's read/write position.

    GLB	FilePos			Set a file's read/write position.

    GLB	FileTruncate		Truncate the passed file to the indicated
				length.

    GLB	FileCommit		Commit a file (force all changes to be
				written)

    GLB	FileLockRecord		Lock a region of a file.

    GLB	FileUnlockRecord	Unlock a region of a file.

    INT	FileLockUnlockCommon	Common code to lock or unlock a region of a
				file.

    GLB	FileGetDateAndTime	Get an open file's modification date.

    GLB	FileSetDateAndTime	Set an open file's modification date &
				time.

    GLB	FileGetHandleExtAttributes Get one or more extended attribute for a
				file whose handle is given.

    GLB	FileGetHandleAllExtAttributes Get all extended attributes for a
				file whose handle is given.

    GLB	FileSetHandleExtAttributes Set one or more extended attribute for a
				file whose handle is given.

    GLB	FileSize		Return the size of an open file.

    GLB	FileGetDiskHandle	Retrieve the disk handle for an open file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 9/90		Initial revision


DESCRIPTION:
	File functions related to reading and writing an open file.
		

	$Id: fileIO.asm,v 1.1 97/04/05 01:11:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode	segment	resource

;
; Front-end functions to read & position files, for use by the Swat stub when
; accessing geode files.
;

FileReadSwat	proc	far
EC <		call	FileReadNoCheckFar				>
NEC <		call	FileReadFar					>
		ret
FileReadSwat	endp

FilePosSwat	proc	far
		call	FilePosFar
		ret
FilePosSwat	endp

kcode	ends



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileRead

DESCRIPTION:	Read from an open file.

CALLED BY:	GLOBAL

PASS:
	al - flags:
		bit 7 - set to not return errors (FILE_NO_ERRORS)
		bits 6-0 - RESERVED (must be 0)
	bx - file handle
	cx - number of bytes to read
	ds:dx - buffer into which to read

RETURN:
	carry set if error:
		ax	= ERROR_SHORT_READ_WRITE (hit end-of-file)
			  ERROR_ACCESS_DENIED (file not opened for reading)
	carry clear if no error:
		ax	= destroyed
		cx 	= number of bytes read

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added code for PC/GEOS file handles
-------------------------------------------------------------------------------@

FileReadFar	proc	far
		call	FileRead
		ret
FileReadFar	endp

if	ERROR_CHECK
FileReadNoCheckFar proc far
		call	FileReadNoCheck
		ret
FileReadNoCheckFar endp
endif	; ERROR_CHECK

FileRead	proc	near

if	ERROR_CHECK

	call	FarCheckDS_ES
	call	FileReadNoCheck
	ret
FileRead	endp

FileReadNoCheck	proc	near
endif

	call	FileErrorCatchStart
	mov	ah,FSHOF_READ
	call	FileLockHandleOp
	call	FileCheckShortReadWrite
	call	FileErrorCatchEnd
	.inst	byte KS_FILE_READ
	ret
EC <FileReadNoCheck	endp						>
NEC <FileRead	endp							>

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileWrite, FileWriteFar

DESCRIPTION:	Write to an open file

CALLED BY:	GLOBAL

PASS:
	al - flags:
		bit 7 - set to not return errors (FILE_NO_ERRORS)
		bits 6-0 - RESERVED (must be 0)
	bx - file handle
	cx - number of bytes to write
	ds:dx - buffer from which to write
		(vfptr if from XIP'ed resource)

RETURN:
	carry set if error:
		ax	= ERROR_SHORT_READ_WRITE (possible disk full)
			  ERROR_ACCESS_DENIED (file not opened for writing)
	carry clear if no error:
		ax	= destroyed
		cx 	= number of bytes written

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added code for PC/GEOS file handles
	Todd	4/94		XIP'ed
-------------------------------------------------------------------------------@
FileWriteFar	proc	far
		call	FileWrite
		ret
FileWriteFar	endp

if	ERROR_CHECK
FileWriteNoCheckFar	proc far
		call	FileWriteNoCheck
		ret
FileWriteNoCheckFar endp
endif	; ERROR_CHECK

FileWrite		proc	near
if	ERROR_CHECK
	call	FarCheckDS_ES
	call	FileWriteNoCheck
	ret
FileWrite	endp

FileWriteNoCheck	proc	near
endif

	call	FileErrorCatchStart

if	FULL_EXECUTE_IN_PLACE
	push	bx
	mov	bx, ds
	cmp	bh, 0f0h
	jae	virtualPointer
	pop	bx
endif
	
	mov	ah,FSHOF_WRITE
	call	FileLockHandleOp
	call	FileCheckShortReadWrite

done::
	call	FileErrorCatchEnd
	.inst	byte	KS_FILE_WRITE
	ret

if	FULL_EXECUTE_IN_PLACE
virtualPointer:
	push	ds
	push	ax
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	call	MemLock
	mov	ds, ax

	pop	ax
	mov	ah,FSHOF_WRITE
	call	FileLockHandleOp
	call	FileCheckShortReadWrite
	pop	ds
	pop	bx
	jmp	short done
endif
EC <FileWriteNoCheck	endp						>
NEC <FileWrite	endp							>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCheckShortReadWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for read & write to handle catching of short
		reads/writes.

CALLED BY:	FileWrite, FileRead

PASS:		carry	= as returned by FileHandleOp
		ax	= number of bytes read/written
		cx	= number of bytes that should have been read/written
RETURN:		carry set on error (ax = error code)
		cx	= number of bytes actually read/written
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCheckShortReadWrite	proc	near
	jc	done
	cmp	ax,cx
	jz	done			;(carry clear if ==, carry set if short,
					;as ax *must* be < cx if !=)

	xchg	cx,ax			;return # of bytes read/written in cx
	mov	ax,ERROR_SHORT_READ_WRITE
done:
	ret
FileCheckShortReadWrite	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FilePos

DESCRIPTION:	Set a file's read/write position.

CALLED BY:	GLOBAL

PASS:
	al - FilePosMode
	bx - file handle
	cx:dx - offset

RETURN:
	dx:ax - new file position

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added code for PC/GEOS file handles
-------------------------------------------------------------------------------@
FilePosFar	proc	far
		call	FilePos
		ret
FilePosFar	endp

FilePos	proc	near
EC <	cmp	al,FilePosMode						>
EC <	ERROR_AE	POS_BAD_FLAGS					>
	mov	ah,FSHOF_POSITION
		CheckHack <FilePosMode lt FILE_NO_ERRORS>

	; always pass FILE_NO_ERRORS here

	or	al, FILE_NO_ERRORS
	call	FileLockHandleOp
	ret
FilePos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileTruncate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Truncate the passed file to the indicated length.

CALLED BY:	GLOBAL
PASS:		al 	= flags:
			    bit 7 - set to not return errors (FILE_NO_ERRORS)
			    bits 6-0 - RESERVED (must be 0)
		bx	= file handle
		cx:dx	= desired length
RETURN:		file positioned at cx:dx
		carry clear if successful, else
		ax	= error code
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileTruncate	proc	far
		.enter
		call	FileErrorCatchStart
		mov	ah, FSHOF_TRUNCATE
		call	FileLockHandleOp
		call	FileErrorCatchEnd
		.inst	byte	KS_FILE_TRUNCATE

		.leave
		ret
FileTruncate	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileCommit

DESCRIPTION:	Commit a file (force all changes to be written)

CALLED BY:	GLOBAL

PASS:
	al - flags:
		bit 7 - set to not return errors (FILE_NO_ERRORS)
		bits 6-0 - RESERVED (must be 0)
	bx - PC/GEOS file handle

RETURN:		carry - set if error
		ax - error code

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	If using Dos 3.2 or below, duplicate the file handle and close the
	duplicated handle.

	If using Dos 3.3 or above, use the commit file call

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/90		Initial version
-------------------------------------------------------------------------------@

FileCommit	proc	far
	.enter
	call	FileErrorCatchStart

	mov	ah, FSHOF_COMMIT
	call	FileLockHandleOp
	
	call	FileErrorCatchEnd
	.inst	byte KS_FILE_COMMIT
	.leave
	ret
FileCommit	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileLockRecord

DESCRIPTION:	Lock a region of a file.

CALLED BY:	GLOBAL

PASS:
	bx - file handle
	cx - high word of region offset
	dx - low word of region offset
	si - high word of region length
	di - low word of region length

RETURN:
	carry - set if error
		ax - error code (if an error)
			ERROR_ALREADY_LOCKED
	carry clear if ok
		ax - destroyed

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added code for PC/GEOS file handles
-------------------------------------------------------------------------------@

FileLockRecord	proc	far
	mov	ah, FSHOF_LOCK
	call	FileLockUnlockCommon
	ret
FileLockRecord	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileUnlockRecord

DESCRIPTION:	Unlock a region of a file.

CALLED BY:	GLOBAL

PASS:
	bx - file handle
	cx:dx - region offset
	si:di - region length

RETURN:
	carry - set if error
		ax - error code (if an error)
			ERROR_ALREADY_LOCKED
	carry clear if ok
		ax - destroyed

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added code for PC/GEOS file handles
-------------------------------------------------------------------------------@

FileUnlockRecord	proc	far
	mov	ah,FSHOF_UNLOCK
	call	FileLockUnlockCommon
	ret
FileUnlockRecord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLockUnlockCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to lock or unlock a region of a file.

CALLED BY:	FileLockRecord, FileUnlockRecord
PASS:		ah	= FSHandleOpFunction to perform
		cx:dx	= start of region to lock/unlock
		si:di	= length of region to lock/unlock
RETURN:		carry clear if successful
			ax	= destroyed
		carry set if error:
			ax	= error code
				  ERROR_ALREADY_LOCKED
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileLockUnlockCommon	proc	near
regData		local	FSHLockUnlockFrame \
		push	si, di, cx, dx
		CheckHack <FSHLUF_regionLength eq 4 and \
			   FSHLUF_regionStart eq 0>
		.enter
		push	cx, bp		; save original cx and current frame
					;  pointer
		lea	cx, ss:[regData]
		call	FileHandleOp
		pop	cx, bp		; restore original cx and recover
					;  frame pointer destroyed by
					;  FileHandleOp
		.leave
		ret
FileLockUnlockCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the disk handle for an open file.

CALLED BY:	GLOBAL
PASS:		bx	= file handle
RETURN:		bx	= disk handle (0 if file open to a device)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetDiskHandle proc	far
		uses ds
		.enter
		LoadVarSeg	ds
		call	ECCheckFileHandle
		mov	bx, ds:[bx].HF_disk
		.leave
		ret
FileGetDiskHandle endp

;--------------------------------------------------

FileSemiCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the size of an open file.

CALLED BY:	GLOBAL (VM code too)
PASS:		bx	= GEOS file handle
RETURN:		dx:ax	= size of the file
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSize	proc	far
		mov	ah, FSHOF_FILE_SIZE
		GOTO	lockHandleOpCommon
FileSize	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileGetDateAndTime

DESCRIPTION:	Get an open file's modification date.

CALLED BY:	GLOBAL

PASS:
	bx - GEOS file handle

RETURN:
	cx - modification time (FileTime record)
	dx - modification date (FileDate record)

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added code for PC/GEOS file handles
-------------------------------------------------------------------------------@

FileGetDateAndTime	proc	far
	mov	ah, FSHOF_GET_DATE_TIME
	GOTO	lockHandleOpCommon
FileGetDateAndTime	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileSetDateAndTime

DESCRIPTION:	Set an open file's modification date & time.

CALLED BY:	GLOBAL

PASS:
	bx - GEOS file handle
	cx - new time (FileTime record)
	dx - new date (FileDate record)

RETURN:
	carry - set if error
	ax - error code (if an error)
		ERROR_ACCESS_DENIED

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	4/89		Added code for PC/GEOS file handles
-------------------------------------------------------------------------------@

FileSetDateAndTime	proc	far
	mov	ah,FSHOF_SET_DATE_TIME
lockHandleOpCommon	label	far
	clr	al		; disk lock may be aborted
	call	FileLockHandleOpFar
	ret
FileSetDateAndTime	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetHandleExtAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get one or more extended attribute for a file whose
		handle is given.

CALLED BY:	GLOBAL
PASS:		bx	= handle of file whose extended attribute(s) is(are)
			  desired
		ax	= FileExtendedAttribute
		es:di	= buffer into which to fetch the attribute, or
			  array of FileExtAttrDesc structures, if
			  ax is FEA_MULTIPLE. Note that custom attributes
			  can only be fetched by passing FEA_MULTIPLE
			  in ax, and an appropriate FileExtAttrDesc
			  structure in this buffer.
		cx	= size of buffer, or number of entries if
			  FEA_MULTIPLE
RETURN:		carry set if one or more attribute could not be fetched,
		    either because the filesystem doesn't support it,
		    or because the file/dir doesn't have it (them).
		    those attributes that exist/are supported will have
		    been fetched.
			ax	= ERROR_ATTR_NOT_SUPPORTED
				= ERROR_ATTR_SIZE_MISMATCH
				= ERROR_ATTR_NOT_FOUND
				= ERROR_ACCESS_DENIED (file opened for writing
				  only)
		carry clear if everything's fine.
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetHandleExtAttributes proc	far
		uses	dx
		.enter
EC<	push	bx, si						>
EC<	movdw	bxsi, esdi					>
EC<	call	ECAssertValidFarPointerXIP			>
EC<	pop	bx, si						>

		push	es, di, ax
		mov	dx, sp
		mov	ah, FSHOF_GET_EXT_ATTRIBUTES
		call	FileLockHandleOpFar
		xchg	bx, dx
		lea	sp, ss:[bx+6]	; clear stack w/o biffing carry
		mov	bx, dx
		.leave
		ret
FileGetHandleExtAttributes endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetHandleAllExtAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all extended attributes for a file whose handle is
		given.

CALLED BY:	GLOBAL
PASS:		bx	= handle of file whose extended attributes is desired
RETURN:		carry clear if okay:
			^hax	= locked block with array FileExtAttrDesc 
				  for all the file's extended attributes 
				  except those that can never be set.  
				  FEA_NAME is never returned.
			cx	= number of entries in array
		carry set if error:
			ax	= FileError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetHandleAllExtAttributes	proc	far
		.enter
		mov	ah, FSHOF_GET_ALL_EXT_ATTRIBUTES
		call	FileLockHandleOpFar
		.leave
		ret
FileGetHandleAllExtAttributes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSetHandleExtAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set one or more extended attribute for a file whose
		handle is given.

CALLED BY:	GLOBAL
PASS:		bx	= handle of file the setting of whose extended
			  attribute(s) is desired
		ax	= FileExtendedAttribute
		es:di	= buffer from which to set the attribute, or
			  array of FileExtAttrDesc structures, if
			  ax is FEA_MULTIPLE. Note that custom attributes
			  can only be set by passing FEA_MULTIPLE
			  in ax, and an appropriate FileExtAttrDesc
			  structure in this buffer.
		cx	= size of buffer, or number of entries if
			  FEA_MULTIPLE
RETURN:		carry set if one or more attribute could not be set,
		    either because the filesystem doesn't support it,
		    or because the file cannot have them.
		    those attributes are supported will have been set.
			ax	= ERROR_ATTR_NOT_SUPPORTED
				= ERROR_ATTR_SIZE_MISMATCH
				= ERROR_ACCESS_DENIED (file opened for
				  reading only)
		carry clear if everything's fine.
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version
	Todd	04/27/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource
FileSetHandleExtAttributes		proc	far
	cmp	ax, FEA_MULTIPLE
	jne	copyToStack
	
	push	ax,cx,dx
	mov	ax, size FileExtAttrDesc
	mul	cx
EC<	tst	dx							>
EC<	ERROR_NZ GASP_CHOKE_WHEEZE					>

	mov_tr	cx, ax
	call	SysCopyToStackESDI
	pop	ax,cx,dx

	jmp	makeCall

copyToStack:
	call	SysCopyToStackESDI

makeCall:
	call	FileSetHandleExtAttributesReal
	call	SysRemoveFromStack
	ret
FileSetHandleExtAttributes		endp
CopyStackCodeXIP		ends

else

FileSetHandleExtAttributes		proc	far
	FALL_THRU	FileSetHandleExtAttributesReal
FileSetHandleExtAttributes		endp
endif

FileSetHandleExtAttributesReal proc	far
		uses	dx
		.enter
EC<	push	bx, si						>
EC<	movdw	bxsi, esdi					>
EC<	call	ECAssertValidFarPointerXIP			>
EC<	pop	bx, si						>
		push	es, di, ax
		mov	dx, sp
		mov	ah, FSHOF_SET_EXT_ATTRIBUTES
		call	FileLockHandleOpFar
		xchg	bx, dx
		lea	sp, ss:[bx+6]	; clear stack w/o biffing carry
		mov	bx, dx
		.leave
		ret
FileSetHandleExtAttributesReal endp


FileSemiCommon ends

;--------------------------------------------------

Filemisc segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyExtAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy all the extended attributes from an open file to
		a named file.

CALLED BY:	GLOBAL
PASS:		bx	= open file handle
		ds:dx	= name of file to which to copy the attributes
RETURN:		carry set on error:
			ax	= error code
		carry clear if successful
			ax	= destroyed
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 4/92		Initial version
	Todd	04/28/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileCopyExtAttributes		proc	far
	mov	ss:[TPD_dataBX], handle FileCopyExtAttributesReal
	mov	ss:[TPD_dataAX], offset FileCopyExtAttributesReal
	GOTO	SysCallMovableXIPWithDSDX
FileCopyExtAttributes		endp
CopyStackCodeXIP		ends

else

FileCopyExtAttributes		proc	far
	FALL_THRU	FileCopyExtAttributesReal
FileCopyExtAttributes		endp
endif

FileCopyExtAttributesReal proc	far
		uses	es, di, cx
		.enter
	;
	; Contact the FSD for the open file to obtain all the extended
	; attributes for the file.
	; 
		mov	ax, FSHOF_GET_ALL_EXT_ATTRIBUTES shl 8
		call	FileLockHandleOpFar	; ax <- block of attrs,
						; cx <- # of attrs
		jc	done
	;
	; Now call our routine to set them all at once.
	; 
		push	bx			; save file handle
		mov_tr	bx, ax
		call	MemDerefES
		clr	di			; es:di <- array of attrs
		mov	ax, FEA_MULTIPLE
		call	FileSetPathExtAttributes
	;
	; Free the attribute array block.
	; 
		pushf
		call	MemFree
		popf
		pop	bx
done:
		.leave
		ret
FileCopyExtAttributesReal endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyPathExtAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy all the extended attributes from one file to
		another, without opening either file

CALLED BY:	GLOBAL, FileCopyCheckLink, FileCreateLink

PASS:		cx - disk handle of source file
		ds:si - filename of source file
		dx - disk handle of dest file
		es:di - filename of dest file

RETURN:		if error:
			carry set
			ax = FileError
		else
			carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/11/92   	Initial version.
	Todd	04/28/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileCopyPathExtAttributes		proc	far
	mov	ss:[TPD_dataBX], handle FileCopyPathExtAttributesReal
	mov	ss:[TPD_dataAX], offset FileCopyPathExtAttributesReal
	GOTO	SysCallMovableXIPWithDSSIAndESDI
FileCopyPathExtAttributes		endp
CopyStackCodeXIP		ends

else

FileCopyPathExtAttributes		proc	far
	FALL_THRU	FileCopyPathExtAttributesReal
FileCopyPathExtAttributes		endp
endif

FileCopyPathExtAttributesReal	proc far

		uses	bx,cx,dx,es,di

destDisk	local	word	push	dx
destPath	local	fptr	push	es, di


		.enter

	;
	; Get to the source file's disk
	;

		call	PushToRoot
		jc	done

	;
	; Have the FSD give us all the attributes for this file
	; 
		mov	dx, si			; ds:dx - source path
		mov	ax, FSPOF_GET_ALL_EXT_ATTRIBUTES shl 8
		call	FileRPathOpOnPath	; ax <- block of attrs,
						; cx <- # of attrs
		call	FilePopDir

		jc	done

		push	ax, cx			; attrs block, # attrs
		mov	cx, ss:[destDisk]
		call	PushToRoot
		pop	bx, cx			; attrs block, # attrs

		jc	done

		lds	dx, ss:[destPath]
	;
	; Set the dest attributes
	; 
		call	MemDerefES
		clr	di			; es:di <- array of attrs
		mov	ax, FEA_MULTIPLE
		call	FileSetPathExtAttributes
	;
	; Free the attribute array block.
	; 
		pushf
		call	MemFree
		popf

	
	;
	; Restore the CWD
	;
		call	FilePopDir

done:

		.leave
		ret
FileCopyPathExtAttributesReal	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpenAndRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a file and read it into a memory block.

CALLED BY:	GLOBAL

PASS:		ax - FileOpenAndReadFlags
		ds:dx - filename

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear
			ax - memory handle of filled buffer
			bx - file handle
			cx - buffer size

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/15/93   	Initial version.
	Todd	04/27/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource
FileOpenAndRead		proc	far
	mov	ss:[TPD_dataBX], handle FileOpenAndReadReal
	mov	ss:[TPD_dataAX], offset FileOpenAndReadReal
	GOTO	SysCallMovableXIPWithDSDX
FileOpenAndRead		endp
CopyStackCodeXIP		ends

else

FileOpenAndRead		proc	far
	FALL_THRU	FileOpenAndReadReal
FileOpenAndRead		endp
endif

FileOpenAndReadReal	proc far

		uses	dx, di, ds, es
		
flags	local	FileOpenAndReadFlags	push	ax
file	local	hptr		

		.enter
		
EC <		test	ax, not (FileOpenAndReadFlags or FullFileAccessFlags)>
EC <		ERROR_NZ OPEN_BAD_FLAGS					>
		
		call	FileOpen
		LONG jc	done
		mov	ss:[file], ax
		mov_tr	bx, ax
		
	;
	; If the file's more than 64K, we're not likely to read it
	; into a memory buffer.
	;
		
		call	FileSize
		tst	dx
		jz	allocate

		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	errorClose

allocate:
	;
	;  Allocate the buffer
	;

		mov	di, ax			; di <- file size
		mov	dx, bx			; dx <- file handle
		test	ss:[flags], mask FOARF_ADD_CRLF
		jz	afterCRLFAdd
		inc	ax
		inc	ax
afterCRLFAdd:
		test	ss:[flags], mask FOARF_ADD_EOF
		jz	afterEOFAdd
		inc	ax

afterEOFAdd:
		test	ss:[flags], mask FOARF_NULL_TERMINATE
		jz	afterNullTerminateAdd
		inc	ax

afterNullTerminateAdd:
	;
	; In EC, keep MemAlloc from dying if the file is zero bytes.
	;
		
EC <		tst	ax						>
EC <		jnz	alloc						>
EC <		inc	ax						>
EC < alloc:								>
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAllocFar
		jc	errorClose

		push	bx			; buffer handle
		mov	bx, ss:[file] 
		mov	cx, di			; size
		mov	ds, ax
		clr	ax, dx
		call	FileReadFar
		pop	bx			; buffer handle
		jnc	appendStuff

		call	MemFree
		jmp	errorClose
appendStuff:
	;
	; Now, append various extra stuff.  Don't add CR/LF if it
	; already ends that way
	;
		segmov	es, ds
		test	ss:[flags], mask FOARF_ADD_CRLF
		jz	afterCRLF

		mov	di, cx			;di <- # bytes read
		cmp	di, 2
		jb	addCRLF			; => can't possibly
						; end in CR-LF

		cmp	{word}es:[di-2], '\r' or ('\n' shl 8)
		je	afterCRLF
addCRLF:
		mov	ax, '\r' or ('\n' shl 8)
		stosw
afterCRLF:
		test	ss:[flags], mask FOARF_ADD_EOF
		jz	afterEOF
		mov	al, MSDOS_TEXT_FILE_EOF	
		stosb	
		
afterEOF:
		test	ss:[flags], mask FOARF_NULL_TERMINATE
		jz	afterNull
		clr	al
		stosb

afterNull:
		call	MemUnlock
		mov	cx, di			; return buffer size
		mov_tr	ax, bx			; memory handle
		mov	bx, ss:[file]

	;
	; Carry is clear here
	;
		
done:
		
		.leave
		ret

errorClose:
		push	ax
		clr	al
		call	FileCloseFar
		pop	ax
		stc
		jmp	done

FileOpenAndReadReal	endp


Filemisc	ends

