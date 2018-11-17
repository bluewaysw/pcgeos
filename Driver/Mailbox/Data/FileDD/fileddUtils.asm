COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		File Data Driver
FILE:		fileddUtils.asm

AUTHOR:		Chung Liu, Oct 19, 1994

ROUTINES:
	Name			Description
	----			-----------
	FDDCreateInMailboxDir
	FDDFileDelete
	FDDFileOpenWithDiskData
	FDDStateLock
	FDDFileSetExtAttributes
	FDDFixupFileExtAttrDescArray	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/19/94   	Initial revision


DESCRIPTION:
	Public services department
		

	$Id: fileddUtils.asm,v 1.1 97/04/18 11:41:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Movable		segment resource

LocalDefNLString	rootPath, <C_BACKSLASH, C_NULL>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDCreateInMailboxDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a file with a unique filename in the mailbox 
		spool directory.

CALLED BY:	FileDDWriteInitialize, FDDCopyToMailboxDir
PASS:		ah	= FileCreateFlags
		al	= FileAccessFlags
		cx	= FileAttrs
		ds:dx 	= PathName buffer
RETURN:		carry clear if okay:
			ds:dx 	= filled in with filename
			ax	= GEOS file handle
			bx	= disk handle 
		carry set if error:
			ax	= FileError
			bx destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDCreateInMailboxDir	proc	near
	uses	cx,dx,ds,si,es,di
	.enter
	call	MailboxPushToMailboxDir
	push	ax, cx				;save create flags

	mov	si, dx				;ds:si = ds:dx
	mov	cx, length PathName
	call	FileGetCurrentPath		;ds:dx = path, 
						;  bx = disk handle
	;
	; Find the terminating null, and place a separator in between.
	;
	movdw	esdi, dsdx
	clr	ax
	LocalFindChar
	LocalPrevChar	esdi
	mov	ax, C_BACKSLASH
	LocalPutChar	esdi, ax
	clr	ax
	LocalPutChar	esdi, ax
	LocalPrevChar	esdi
	mov	dx, di			;ds:dx = null pathname

	pop	ax, cx
	call	FileCreateTempFile	;ds:dx = filename, ax = file handle
	call	FilePopDir
	.leave
	ret
FDDCreateInMailboxDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDFileDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the file

CALLED BY:	FileDDWriteComplete, FileDDWriteCancel, FDDCopyToMailboxDir,
		FileDDDeleteBody, FileDDDoneWithBodyAndDelete
PASS:		bx	= disk handle
		ds:si	= filename to delete
RETURN:		carry set if error
		ax	= FileError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDFileDelete	proc	near
	uses	si,dx
	.enter
	call	FilePushDir
	push	ds, si
	segmov	ds, cs
	mov	dx, offset cs:[rootPath]	;ds:dx = root path
	call	FileSetCurrentPath
	pop	ds, dx				;ds:dx = filename
	jc	exit

	call	FileDelete
	jnc	ok
	cmp	ax, ERROR_FILE_NOT_FOUND
	je	ok				; since we're trying to delete
						;  it, a FILE_NOT_FOUND error
						;  means our purpose is
						;  accomplished even if we
						;  didn't do it ourselves
	stc
ok:
	call	FilePopDir			;flags preserved
exit:
	.leave
	ret
FDDFileDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDFileOpenWithDiskData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a file in the disk for which the disk data is passed.

CALLED BY:	FileDDReadInitialize, FileDDBodySize
PASS:		es:di 	= disk data
		ds:dx 	= filename
		al	= FileAccessFlags
RETURN:		carry clear if okay:
			ax	= file handle
		carry set if error.
			ax destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDFileOpenWithDiskData	proc	near
fileToOpen	local	fptr			push ds, dx
flags		local	word			push ax
	uses	ds,bx,cx,si
	.enter
	clr	cx
	movdw	dssi, esdi		;ds:si = disk data
	call	DiskRestore		;ax = disk handle
	jc	exit

	mov	bx, ax			;bx = disk handle
	segmov	ds, cs
	mov	dx, offset cs:[rootPath] ;ds:dx = root path
	call	FileSetCurrentPath
	jc	exit

	movdw	dsdx, fileToOpen
	mov	ax, flags
	call	FileOpen		;ax = file handle

exit:
	.leave
	ret
FDDFileOpenWithDiskData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDStateLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the locked state.  Caller must MemUnlockShared
		ds:[LMBH_handle] when done accessing the state.

CALLED BY:	FileDDReadNextBlock, FileDDReadComplete, 
		FileDDWriteNextBlock, FileDDWriteComplete, FileDDWriteCancel
		
PASS:		si	= state chunk
RETURN:		*ds:si  = state
		ds:di	= state

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDStateLock	proc	near
	uses	ax, bx
	.enter
	mov	bx, handle FileDDState
	call	MemLockShared
	mov	ds, ax
	mov	di, ds:[si]
	.leave
	ret
FDDStateLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDFileSetExtAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the file's extended attributes.

CALLED BY:	FileDDWriteComplete
PASS:		ds:dx	= filename
		ax	= disk handle
		^hbx	= array of FileExtAttrDesc
		cx	= array count
RETURN:		carry clear if okay:
			ax	= destroyed
		carry set if error:
			ax	= FileError

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDFileSetExtAttributes	proc	near
	uses	es,di
	.enter
	;
	; Go to the file's disk.
	;
	call	FilePushDir
	push	ds, dx, bx			;save filename, attrs.
	segmov	ds, cs
	mov	dx, offset cs:[rootPath]
	mov	bx, ax				;bx = disk handle.
	call	FileSetCurrentPath
	pop	ds, dx, bx			;ds:dx = filename,
						;  bx = extended attributes
	jc	popDirAndExit
	;
	; Lock down the FileExtAttrDesc array.
	;
	call	MemLock
	mov	es, ax	
	clr	di				;es:di = ext. attrs array
	call	FDDFixupFileExtAttrDescArray
	mov	ax, FEA_MULTIPLE
	call	FileSetPathExtAttributes

	;
	; Cleanup.  Flags preserved throughout.
	;
	call	MemUnlock

popDirAndExit:
	call	FilePopDir
	.leave
	ret
FDDFileSetExtAttributes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDFixupFileExtAttrDescArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup the FEAD_value.segment of each FileExtAttrDesc that
		is in the passed array.

CALLED BY:	FDDFileSetExtAttributes
PASS:		es:di	= array of FileExtAttrDesc
		cx	= number of entries in array
RETURN:		es:di	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDFixupFileExtAttrDescArray	proc	near
	uses	di,ax,cx
	.enter
	mov	ax, es
	jcxz	done

fixupLoop:
	mov	es:[di].FEAD_value.segment, ax
	add	di, size FileExtAttrDesc
	loop	fixupLoop

done:
	.leave
	ret
FDDFixupFileExtAttrDescArray	endp

Movable 	ends


