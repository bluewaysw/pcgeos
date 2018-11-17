COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		File Data Driver
FILE:		fileddBody.asm

AUTHOR:		Chung Liu, Oct 20, 1994

ROUTINES:
	Name			Description
	----			-----------
	FileDDStoreBody
	FDDCopyAndGenerateMboxRef
	FDDCopyToMailboxDir
	FDDGenerateMboxRef     
	FDDResizeMboxRef       
	FileDDDeleteBody        
	FileDDStealBody     
	FileDDGetBody       
	FileDDDoneWithBody      
	FileDDBodySize  
	FileDDDoneWithBodyAndDelete
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/20/94   	Initial revision


DESCRIPTION:
	Are you of the body?  The body is one.
		

	$Id: fileddBody.asm,v 1.1 97/04/18 11:41:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable		segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDStoreBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a message, returning a mboxRef to the message.
		If MMF_BODY_DATA_VOLATILE, the file in appRef is copied 
		to a storage area (SP_SPOOL:\MAILBOX), and mboxRef refers
		to the copied file.  Otherwise, mboxRef refers to the
		same file as appRef.  

CALLED BY:	DR_MBDD_STORE_BODY
PASS:		cx:dx	= pointer to MBDDBodyRefs.
			  *MBDDBR_appRef should be a FileDDAppRef, and
			  *MBDDBR_mboxRef should be a FileDDMboxRef.
			  NOTE: MBDDBR_mboxRef.offset is actually a *chunk
			  handle*, not an offset. This allows the driver to
			  enlarge or shrink the buffer, as needed.
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			*cx:dx.MBDDBR_mboxRef sized as small as possible
				and filled in.  MBDDBR_mboxRef.segment 
				may have moved.

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDStoreBody	proc	far
		uses 	bx,cx,dx,ds,si,di
		.enter
	;
	; Setup arguments to pass to subfunctions.
	;
		movdw	dssi, cxdx	;ds:si = MBDDBodyRefs
		movdw	cxdx, ds:[si].MBDDBR_appRef	;cx:dx = app-ref
		movdw	bxdi, ds:[si].MBDDBR_mboxRef	;*bx:di = mbox-ref
	;
	; Look at the volatile flag to decide how to generate mboxRef.
	;
		mov	ax, ds:[si].MBDDBR_flags
		test	ax, mask MMF_BODY_DATA_VOLATILE
		jz	noCopy
		call	FDDCopyAndGenerateMboxRef	;*bx:di filled in
							; cx = size of mbox-ref
		jmp	gotMboxRef
noCopy:
		call	FDDGenerateMboxRef		;*bx:di filled in
							; cx = size of mbox-ref
gotMboxRef:
		jc	exit
		mov	ds:[si].MBDDBR_mboxRef.segment, bx   ;may have moved.
		mov	ds:[si].MBDDBR_mboxRefLen, cx
		
exit:
		.leave
		ret
FileDDStoreBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDCopyAndGenerateMboxRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the file in appRef to storage area (SP_SPOOL:\MAILBOX)
		and generate a mboxRef to the copy.

CALLED BY:	FileDDStoreBody
PASS:		cx:dx	= fptr to FileDDAppRef
		*bx:di	= FileDDMboxRef buffer
		ax	= MailboxMessageFlags
RETURN:		carry clear if ok:
			*bx:di	= filled in and resized as small as possible.
				  (segment bx may have moved)
			cx	= new size of FileDDMboxRef chunk.
		carry set if error:
			ax	= MailboxError
				    ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	copy file
	create fake app-ref to the copied file.
	call FDDGenerateMboxRef
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDCopyAndGenerateMboxRef	proc	near
appRef		local	fptr.char		push cx, dx
flags		local	word			push ax
newAppRef	local	FileDDMaxAppRef
		uses	dx,ds,di
		.enter
	ForceRef	appRef		

		call	FDDCopyToMailboxDir	;newAppRef filled in
		jc	exit

		mov	cx, ss
		lea	dx, newAppRef		;cx:dx = fake app-ref
		mov	ax, flags
		call	FDDGenerateMboxRef	;*bx:di = mbox-ref
						;  cx = size of mbox-ref
exit:
		.leave
		ret

FDDCopyAndGenerateMboxRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDCopyToMailboxDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the file in the app-ref to the spool/mailbox directory.

CALLED BY:	FDDCopyAndGenerateMboxRef
PASS:		ss:bp	= inherited frame
				appRef 		= fptr to FileDDAppRef to copy
				newAppRef	= FileDDMaxAppRef buffer

RETURN:		carry clear if okay:
			newAppRef filled in
			ax destroyed			
		carry set if error:
			ax 	= MailboxError
				    ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Use FileCreateTempFile to create a new file in spool/mailbox, but
	really we're only interested in the pathname it generates.
	FileCopy will truncate existing destination file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDCopyToMailboxDir	proc	near
		uses	bx,cx,dx,ds,si,es,di
		.enter inherit FDDCopyAndGenerateMboxRef
	;
	; Create a new file to be the copy.
	;
		segmov	ds, ss
		lea	dx, newAppRef
		add	dx, FMAR_filename	;ds:dx = PathName buffer
		mov	cx, FILE_ATTR_NORMAL
		mov	al, FILE_ACCESS_RW or FILE_DENY_RW
		mov	ah, 0			;no create flags for now.
		call	FDDCreateInMailboxDir	;ds:dx = filled in
						;  ax = file handle
						;  bx = disk handle
		jc	fileCreateError
		movdw	esdi, dsdx		;es:di = dest. file
		mov	newAppRef.FMAR_diskHandle, bx
	;
	; Get rid of the new file. We really just wanted the name and
	; disk handle.
	;
		mov	dx, bx			;dx = dest. disk handle
		mov	bx, ax			;ax = handle of new file
		clr	al	
		call	FileClose
		jc	error

		mov	bx, dx			;bx = disk handle
		mov	si, di			;ds:si = filename
		call	FDDFileDelete
		jc	error
	;
	; Copy file contents
	;
		movdw	dssi, appRef		;app-ref of file to copy.
		mov	cx, ds:[si].FAR_diskHandle ;cx = source disk handle
		add	si, FAR_filename	;ds:si = source file name
		call	FileCopy
		jc	copyError
exit:	
		.leave
		ret
error:
copyError:
fileCreateError:
		mov	ax, ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY
		jmp	exit

FDDCopyToMailboxDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDGenerateMboxRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a mboxRef from an appRef.

CALLED BY:	FileDDStoreBody, FDDCopyAndGenerateMboxRef
PASS:		cx:dx	= fptr to FileDDAppRef
		*bx:di	= FileDDMboxRef buffer
		ax	= MailboxMessageFlags
RETURN:		carry clear if ok:
			*bx:di	= filled in and resized as small as possible.
				  (segment bx may have moved.)
			cx	= new size of FileDDMboxRef chunk.
		carry set if error:
			ax	= MailboxError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDGenerateMboxRef	proc	near
flags		local	word		push ax
filenameStr	local	fptr.char
newMboxRefSize	local	word
mboxRef		local	dword
		uses	dx,ds,si,es,di
		.enter
	;
	; mboxRef size is based on the size of the filename, and the
	; disk handle of the the appRef.
	;
		push	di			;save mbox-ref chunk
		movdw	esdi, cxdx		;es:di = app-ref
		mov	dx, es:[di].FAR_diskHandle
		add	di, FAR_filename	;es:di = filename
		movdw	filenameStr, esdi
		call	LocalStringSize		;cx = size w/o null.
		pop	di			;di = mbox-ref chunk
		inc	cx			;include null
DBCS <		inc	cx						>

		;cx = filenameLen, dx = diskHandle, *bx:di = mboxRef
		call	FDDResizeMboxRef	;ax = new mboxRef size
						;si = disk data size
						;bx may have moved.
		jc	resizeError
		mov	newMboxRefSize, ax

	;
	; start filling in mboxRef.
	;
		movdw	mboxRef, bxdi
		mov	es, bx
		mov	di, es:[di]		;es:di = fptr to mboxRef
		mov	ax, flags
		andnf	ax, mask MMF_DELETE_BODY_AFTER_TRANSMISSION or \
				mask MMF_BODY_DATA_VOLATILE
		mov	es:[di].FMR_deleteAfterTransmit, ax
		mov	es:[di].FMR_filenameLen, cx
		add	cx, offset FMR_filenameAndDiskData
		mov	es:[di].FMR_diskDataOffset, cx
		mov	es:[di].FMR_diskDataLen, si
		add	di, offset FMR_filenameAndDiskData
	
		;es:di = destination for filename
		push	si			;save diskDataLen
		lds	si, filenameStr
		LocalCopyString
		pop	si			;diskDataLen

		;es:di = destination for disk data
		mov	bx, dx			;disk handle
		mov	cx, si			;size of es:di buffer
		call	DiskSave		;cx = bytes actually used.
		jc	diskSaveError
		
	;
	; return values
	; 	
		mov	cx, newMboxRefSize
		movdw	bxdi, mboxRef
		
exit:
		.leave
		ret
resizeError:
		mov	ax, ME_NOT_ENOUGH_MEMORY
		jmp	exit
diskSaveError:
		mov	ax, ME_DATA_DRIVER_CANNOT_STORE_MESSAGE_BODY
		jmp	exit
	
FDDGenerateMboxRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FDDResizeMboxRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize the mboxRef buffer so that it is just right to fit all
		the goodies inside.

CALLED BY:	FDDGenerateMboxRef, FDDCopyAndGenerateMboxRef
PASS:		cx	= filename length
		dx	= disk handle
		*bx:di	= FileDDMboxRef buffer
RETURN:		carry clear if resize was successful.
			ax	= new size of a FileDDMboxRef
			bx	= new segment (may have moved)
			si	= disk data size
		carry set if resize failed.
			ax 	= what new size should be.
			ax, bx destroyed

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FDDResizeMboxRef	proc	near
diskDataSize	local	word
		uses	cx,dx,ds,es,di
		.enter
		push	bx, di			;save mboxRef to resize
						;in the end.
	;
	; Size of FileDDMboxRef will be the size of the header, plus
	; the length of the disk data, plus the filename length.
	;
		;mboxRef header plus filename length.
		add 	cx, offset FMR_filenameAndDiskData
		mov	ax, cx			;ax = running total size

	; add length of disk data to totalSize
		mov	bx, dx
		clr	cx			;ask for size only
		call	DiskSave		;cx = size needed for disk data
EC <		ERROR_NC ERROR_FILE_MBDD_UNEXPECTED_ERROR	>
		mov	diskDataSize, cx
		add	cx, ax			;cx = total size
	;
	; Resize it, now that we know how big it should be.
	;	
		pop	ds, ax			;ds = segment, ax = chunk
		call	LMemReAlloc		;ds may have moved!
		mov	bx, ds			;return new(?) segment
		mov	ax, cx			;return the size
		mov	si, diskDataSize
		.leave
		ret
FDDResizeMboxRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDDeleteBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the message body whose mbox-ref is passed

CALLED BY:	DR_MBDD_DELETE_BODY
PASS:		cx:dx	= pointer to mbox-ref returned by DR_MBDD_STORE_BODY
RETURN:		carry set if unable to delete the message. 

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDDeleteBody	proc	far
		uses	ds,si,cx,dx,ax,bx
		.enter
		movdw	dssi, cxdx		;ds:si = ds:dx = mbox-ref
		tst	ds:[si].FMR_deleteAfterTransmit
EC <		ERROR_Z		-1				>
		stc
		jz	exit

		add	si, ds:[si].FMR_diskDataOffset	;ds:si = disk data
		clr	cx
		call	DiskRestore		;ax = disk handle
		jc	exit
		mov	bx, ax			;bx = disk handle	
		mov	si, dx			;ds:si = mbox-ref
		add	si, offset FMR_filenameAndDiskData ;ds:si = filename
		call	FDDFileDelete	
exit:
		.leave
		ret
FileDDDeleteBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDStealBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the body of a message, returning an app-ref to it. The
		only difference between this and DR_MBDD_GET_BODY is the
		driver will *not* receive a DR_MBDD_DONE_WITH_BODY call: the
		caller is taking complete possession of the message body.

CALLED BY:	DR_MBDD_STEAL_BODY
PASS:		cx:dx	= pointer to MBDDBodyRefs. MBDDBR_flags is undefined
			  MBDDBR_mboxRef is an actual far pointer
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if successful:
			cx:dx.MBDDBR_appRef filled in
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDStealBody	proc	far
		.enter
		call	FileDDGetBody
		.leave
		ret
FileDDStealBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDGetBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the body of a message, returning an app-ref to it.

CALLED BY:	DR_MBDD_GET_BODY
PASS:		cx:dx	= pointer to MBDDBodyRefs. MBDDBR_flags is undefined
			  MBDDBR_mboxRef is an actual far pointer
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if successful:
			cx:dx.MBDDBR_appRef filled in
			cx:dx.MBDDBR_appRefLen filled in

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Generate an app-ref from the mbox-ref.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDGetBody	proc	far
		uses	bx,cx,dx,ds,si,es,di
		.enter
		movdw	dssi, cxdx			;ds:si = body-ref
		pushdw	dssi
		mov	es, ds:[si].MBDDBR_appRef.segment
		push	ds:[si].MBDDBR_appRef.offset
		lds	si, ds:[si].MBDDBR_mboxRef	;ds:si = mbox-ref

		; Check integrity of message body.
		movdw	cxdx, dssi
		call	FileDDCheckIntegrity
		pop	di				;es:di = app-ref
		jc	error

		mov	dx, si				;save mbox-ref offset
		add	si, ds:[si].FMR_diskDataOffset	;ds:si = disk data
		clr	cx
		call	DiskRestore			;ax = disk handle (must
							; work, b/c we called
							; FileDDCheckIntegrity
							; above.)
		mov	es:[di].FAR_diskHandle, ax

		add	di, offset FAR_filename		;es:di = dest.
		mov	si, dx				;si = mbox-ref offset
		add	si, FMR_filenameAndDiskData	;ds:si = filename
		mov	dx, si				;save start for
							; computing app-ref len
		LocalCopyString
		popdw	dssi
		sub	di, ds:[si].MBDDBR_appRef.offset
		mov	ds:[si].MBDDBR_appRefLen, di
		clc
exit:
		.leave
		ret
error:
		add	sp, 4		; clear saved MBDDBR pointer
		mov	ax, ME_DATA_DRIVER_CANNOT_ACCESS_MESSAGE_BODY
		stc
		jmp	exit
FileDDGetBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDDoneWithBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The recipient of the message is done with the app-ref that
		was returned by a previous DR_MBDD_GET_BODY or DR_MBDD_
		WRITE_COMPLETE. The driver may do whatever cleanup or 
		other work it deems appropriate.

CALLED BY:	DR_MBDD_DONE_WITH_BODY
PASS:		cx:dx	= pointer to app-ref returned by DR_MBDD_GET_BODY
			  or DR_MBDD_WRITE_COMPLETE (not necessarily at the 
			  same address; just the contents are the same)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDDoneWithBody	proc	far
		.enter
		clc
		.leave
		ret
FileDDDoneWithBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDBodySize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the number of bytes in a message body, for use
		in control panels and information dialogs and the like.

CALLED BY:	DR_MBDD_BODY_SIZE
PASS:		cx:dx	= pointer to mbox-ref for the body
RETURN:		carry clear if okay:
			dxax	= number of bytes in the body (-1 if info not
				  available)
		carry set if error:
			ax	= MailboxError
				ME_DATA_DRIVER_CANNOT_ACCESS_MESSAGE_BODY
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDBodySize	proc	far
fileSize	local	dword
fileType	local	GeosFileType
	uses	es,di,ds,bx
	.enter
	; get the disk data and the filename so we can open the file.
	mov 	es, cx
	mov	di, dx
	add	di, es:[di].FMR_diskDataOffset	;es:di = disk data

	mov	ds, cx
	add	dx, FMR_filenameAndDiskData	;ds:dx = filename

	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
	call	FDDFileOpenWithDiskData		;ax = file handle
	jc	fileOpenError

	mov	bx, ax				;bx = GEOS file handle
	call	FileSize			;dx:ax = size of file.
	movdw	fileSize, dxax
	;
	; Find out if this is a GEOS file.  If so, we need to add 256 bytes
	; to the file size, to account for the GEOS file header.
	;
	segmov	es, ss
	lea	di, fileType			;es:di = GeosFileType buffer
	mov	ax, FEA_FILE_TYPE		
	mov	cx, size GeosFileType
	call	FileGetHandleExtAttributes	;es:di filled in
	jc	closeFile			;assume not GEOS file if can't
						; get attributes

	cmp	fileType, GFT_NOT_GEOS_FILE
	je	closeFile
	;
	; File is a GEOS file.  Add 256 bytes to the size.
	;
	adddw	fileSize, 256

closeFile:
	clr	ax			;accept errors
	call	FileClose

	clc
	movdw	dxax, fileSize		;return dxax = file size

exit:
	.leave
	ret
fileOpenError:
	mov	ax, ME_DATA_DRIVER_CANNOT_ACCESS_MESSAGE_BODY
	jmp	exit
FileDDBodySize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDDoneWithBodyAndDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as DR_MBDD_DONE_WITH_BODY, except also delete the body.

CALLED BY:	DR_MBDD_DONE_WITH_BODY_AND_DELETE
PASS:		cx:dx	= FileDDAppRef
RETURN:		carry set if unable to delete
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDDoneWithBodyAndDelete	proc	far
	uses	ds,si,bx,ax
	.enter
	movdw	dssi, cxdx
	mov	bx, ds:[si].FAR_diskHandle
	add	si, offset FAR_filename
	call	FDDFileDelete
	.leave
	ret
FileDDDoneWithBodyAndDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDDCheckIntegrity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the integrity of the message body.

CALLED BY:	DR_MBDD_CHECK_INTEGRITY
PASS:		cx:dx	= pointer to mbox-ref for the body
RETURN:		carry set if the message body is invalid
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Message body is valid if disk can be restored and file can be opened
	for reading.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDDCheckIntegrity	proc	far
	uses	ax,bx,dx,ds,es
	.enter

	movdw	esdi, cxdx
	add	di, es:[di].FMR_diskDataOffset	; es:di = disk data
	mov	ds, cx
	add	dx, offset FMR_filenameAndDiskData	; ds:dx = filename
	mov	al, FILE_DENY_NONE or FILE_ACCESS_R
	call	FDDFileOpenWithDiskData	; ax = file handle
	jc	done

	mov_tr	bx, ax
	clr	al
	call	FileClose		; CF set on error

done:
	.leave
	ret
FileDDCheckIntegrity	endp

Movable		ends		
